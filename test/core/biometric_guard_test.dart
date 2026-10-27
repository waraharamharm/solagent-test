import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/security/biometric_gate.dart';
import 'package:solagent/core/security/biometric_guard.dart';
import 'package:solagent/l10n/app_localizations.dart';

class _Gate implements IBiometricGate {
  int calls = 0;

  @override
  Future<GateResult> authenticate(String reason) async {
    calls++;
    return GateResult.granted;
  }
}

Future<_Gate> _pump(
  WidgetTester tester, {
  required Duration relockAfter,
}) async {
  final gate = _Gate();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [biometricGateProvider.overrideWithValue(gate)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BiometricGuard(
          relockAfter: relockAfter,
          child: const Text('secret screen'),
        ),
      ),
    ),
  );
  await tester.pumpAndWait();
  return gate;
}

extension on WidgetTester {
  Future<void> pumpAndWait() async {
    await pump();
    await pump();
  }

  Future<void> background() async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await pump();
  }

  Future<void> foreground() async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpAndWait();
  }
}

void main() {
  testWidgets('opens after one successful check', (tester) async {
    final gate = await _pump(tester, relockAfter: const Duration(seconds: 3));
    expect(find.text('secret screen'), findsOneWidget);
    expect(gate.calls, 1);
  });

  testWidgets('a short pause (the system prompt) does not ask again', (
    tester,
  ) async {
    final gate = await _pump(tester, relockAfter: const Duration(seconds: 3));
    await tester.background();
    await tester.foreground();
    expect(find.text('secret screen'), findsOneWidget);
    expect(gate.calls, 1);
  });

  testWidgets('being away longer locks again and asks once', (tester) async {
    final gate = await _pump(tester, relockAfter: Duration.zero);
    await tester.background();
    await tester.foreground();
    expect(gate.calls, 2);
    expect(find.text('secret screen'), findsOneWidget);
  });
}
