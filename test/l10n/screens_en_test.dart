import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:solagent/app/app_shell.dart';
import 'package:solagent/app/home_screen.dart';
import 'package:solagent/core/l10n/l10n.dart';
import 'package:solagent/core/security/biometric_gate.dart';
import 'package:solagent/core/security/secure_store.dart';
import 'package:solagent/features/fix/application/fix_run_controller.dart';
import 'package:solagent/features/fix/domain/fix_models.dart';
import 'package:solagent/features/fix/presentation/fix_demo_screen.dart';
import 'package:solagent/features/llm/presentation/llm_settings_screen.dart';
import 'package:solagent/features/server/data/server_repository.dart';
import 'package:solagent/features/server/domain/server_profile.dart';
import 'package:solagent/features/server/presentation/server_screen.dart';

class _MemoryStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _OpenGate implements IBiometricGate {
  @override
  Future<GateResult> authenticate(String reason) async => GateResult.granted;
}

class _FakeRun extends FixRun {
  _FakeRun(this.initial);

  final FixRunState initial;

  @override
  FixRunState build() => initial;
}

final _cyrillic = RegExp('[А-яЁё]');

/// Every string the user could read: Text, RichText, tooltips.
List<String> _visibleStrings(WidgetTester tester) => [
  for (final w in tester.widgetList<Text>(find.byType(Text)))
    w.data ?? w.textSpan?.toPlainText() ?? '',
  for (final w in tester.widgetList<RichText>(find.byType(RichText)))
    w.text.toPlainText(),
  for (final w in tester.widgetList<Tooltip>(find.byType(Tooltip)))
    w.message ?? '',
];

/// Russian text that still comes from layers outside the widget files
/// (LlmPreset.label in lib/features/llm/domain/llm_preset.dart).
const _fromOtherLayers = {'Свой эндпоинт'};

void _expectNoCyrillic(WidgetTester tester) {
  final offenders = _visibleStrings(tester)
      .where((s) => _cyrillic.hasMatch(s) && !_fromOtherLayers.contains(s))
      .toList();
  expect(offenders, isEmpty, reason: 'Cyrillic left in the English UI');
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  _MemoryStore? store,
  FixRunState run = const FixRunState(),
  bool animated = false,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        secureStoreProvider.overrideWithValue(store ?? _MemoryStore()),
        biometricGateProvider.overrideWithValue(_OpenGate()),
        fixRunProvider.overrideWith(() => _FakeRun(run)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: home,
      ),
    ),
  );
  // The wavy progress line animates forever, so it never "settles".
  if (animated) {
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('HomeScreen: no server yet', (tester) async {
    await _pump(tester, const HomeScreen());
    expect(find.text('Connect a server'), findsOneWidget);
    expect(find.text('Add server'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('No key'), findsOneWidget);
    expect(find.text('Self-healing'), findsOneWidget);
    expect(find.text('Demo on your server'), findsOneWidget);
    _expectNoCyrillic(tester);
  });

  testWidgets('HomeScreen: theme menu', (tester) async {
    await _pump(tester, const HomeScreen());
    await tester.tap(find.byTooltip('Theme'));
    await tester.pumpAndSettle();
    expect(find.text('Match system'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    _expectNoCyrillic(tester);
  });

  testWidgets('AppShell: tab and job tooltips', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            for (final path in ['/', '/deploy', '/server', '/ai'])
              StatefulShellBranch(
                routes: [
                  GoRoute(path: path, builder: (_, _) => const SizedBox()),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fixRunProvider.overrideWith(() => _FakeRun(const FixRunState())),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Overview'), findsOneWidget);
    expect(find.byTooltip('Deployment'), findsOneWidget);
    expect(find.byTooltip('Server'), findsOneWidget);
    expect(find.byTooltip('AI'), findsOneWidget);
    expect(find.byTooltip('Run'), findsOneWidget);
    _expectNoCyrillic(tester);
  });

  testWidgets('ServerScreen: form', (tester) async {
    await _pump(tester, const ServerScreen());
    expect(find.text('Server'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('IP or domain'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Sign-in'), findsOneWidget);
    expect(find.text('Key'), findsOneWidget);
    _expectNoCyrillic(tester);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Fill in this field'), findsOneWidget);
  });

  testWidgets('ServerScreen: saved server', (tester) async {
    final store = _MemoryStore();
    await ServerRepository(
      store,
    ).save(const ServerProfile(host: '10.0.0.1', username: 'root'), 'secret');
    await _pump(tester, const ServerScreen(), store: store);
    expect(find.text('10.0.0.1'), findsOneWidget);
    expect(find.text('root · port 22 · password'), findsOneWidget);
    expect(find.text('Check server'), findsOneWidget);
    expect(find.byTooltip('Remove server'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove server'));
    await tester.pumpAndSettle();
    expect(find.text('Remove the server?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    _expectNoCyrillic(tester);
  });

  testWidgets('FixDemoScreen: idle', (tester) async {
    await _pump(tester, const FixDemoScreen());
    expect(find.text('Self-healing'), findsOneWidget);
    expect(find.text('Run demo'), findsOneWidget);
    expect(find.textContaining('~/solagent-fixdemo/app.conf'), findsOneWidget);
    _expectNoCyrillic(tester);
  });

  testWidgets('FixDemoScreen: AI proposal waits for a decision', (
    tester,
  ) async {
    await _pump(
      tester,
      const FixDemoScreen(),
      run: FixRunState(
        running: true,
        pending: FixProposal(
          diagnosis: 'The config file is missing',
          explanation: 'Creates the config',
          command: 'mkdir -p /opt/app',
        ),
      ),
    );
    expect(find.text('Your decision needed'), findsOneWidget);
    expect(find.text('The AI suggests one command'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    _expectNoCyrillic(tester);
  });

  testWidgets('FixDemoScreen: running and log card', (tester) async {
    await _pump(
      tester,
      const FixDemoScreen(),
      run: const FixRunState(running: true, log: ['line one']),
      animated: true,
    );
    expect(find.text('Working on it'), findsOneWidget);
    expect(find.text('Connecting…'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Server log'), findsOneWidget);
    expect(find.text('Full log'), findsOneWidget);
    await tester.tap(find.text('Full log'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Collapse'), findsOneWidget);
    _expectNoCyrillic(tester);
  });

  testWidgets('LlmSettingsScreen: form and key flow', (tester) async {
    await _pump(tester, const LlmSettingsScreen());
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Address and model'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Save key'), findsOneWidget);
    expect(find.text('Test connection'), findsOneWidget);
    _expectNoCyrillic(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'API key'),
      'sk-test-123',
    );
    await tester.tap(find.text('Save key'));
    await tester.pumpAndSettle();
    expect(find.text('Key saved'), findsOneWidget);
    expect(find.byTooltip('Delete key'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete key'));
    await tester.pumpAndSettle();
    expect(find.text('Delete the key?'), findsOneWidget);
    _expectNoCyrillic(tester);
  });
}
