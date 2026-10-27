import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/l10n/l10n.dart';
import 'package:solagent/core/security/biometric_gate.dart';
import 'package:solagent/features/fix/application/fix_run_controller.dart';
import 'package:solagent/features/fix/application/fix_run_state.dart';
import 'package:solagent/features/fix/domain/fix_models.dart';
import 'package:solagent/features/fix/presentation/fix_demo_screen.dart';

class _OpenGate implements IBiometricGate {
  @override
  Future<GateResult> authenticate(String reason) async => GateResult.granted;
}

class _FakeRun extends FixRun {
  _FakeRun(this.initial);

  final FixRunState initial;
  final decisions = <bool>[];

  @override
  FixRunState build() => initial;

  @override
  void decide({required bool approve}) {
    decisions.add(approve);
    state = FixRunState(running: true, log: state.log);
  }
}

void main() {
  Future<_FakeRun> pump(WidgetTester tester, FixRunState s) async {
    final fake = _FakeRun(s);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometricGateProvider.overrideWithValue(_OpenGate()),
          fixRunProvider.overrideWith(() => fake),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('ru'),
          home: FixDemoScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  final proposal = FixProposal(
    diagnosis: 'Нет файла конфига',
    explanation: 'Создаёт конфиг',
    command: 'sudo -n mkdir -p /opt/app',
  );

  testWidgets('proposal shows command and warnings; approve is explicit', (
    tester,
  ) async {
    final fake = await pump(
      tester,
      FixRunState(running: true, pending: proposal, log: const ['boom']),
    );
    expect(find.text('Нет файла конфига'), findsOneWidget);
    expect(find.text('sudo -n mkdir -p /opt/app'), findsOneWidget);
    expect(find.textContaining('root'), findsOneWidget);
    expect(fake.decisions, isEmpty);

    await tester.tap(find.text('Выполнить'));
    await tester.pump();
    expect(fake.decisions, [true]);
    expect(find.text('Выполнить'), findsNothing);
  });

  testWidgets('reject sends false', (tester) async {
    final fake = await pump(
      tester,
      FixRunState(running: true, pending: proposal),
    );
    await tester.tap(find.text('Отклонить'));
    await tester.pump();
    expect(fake.decisions, [false]);
  });

  testWidgets('idle screen offers the demo run', (tester) async {
    await pump(tester, const FixRunState());
    expect(find.text('Запустить демо'), findsOneWidget);
    expect(find.text('Остановить'), findsNothing);
  });
}
