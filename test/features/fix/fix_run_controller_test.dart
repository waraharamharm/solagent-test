import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/errors/app_problem.dart';
import 'package:solagent/core/security/secure_store.dart';
import 'package:solagent/features/deploy/domain/deploy_models.dart';
import 'package:solagent/features/fix/application/fix_advisor.dart';
import 'package:solagent/features/fix/application/fix_loop.dart';
import 'package:solagent/features/fix/application/fix_run_controller.dart';
import 'package:solagent/features/fix/application/fix_run_state.dart';
import 'package:solagent/features/fix/application/fix_session.dart';
import 'package:solagent/features/fix/application/ssh_fix_session_factory.dart';
import 'package:solagent/features/fix/domain/log_redactor.dart';
import 'package:solagent/features/journal/domain/journal_entry.dart';
import 'package:solagent/features/monitor/application/relay_setup.dart';
import 'package:solagent/features/monitor/application/run_follower.dart';
import 'package:solagent/features/monitor/application/run_monitor.dart';
import 'package:solagent/features/monitor/data/foreground_run_notifier.dart';
import 'package:solagent/features/server/domain/server_profile.dart';

import '../../support/fake_deploy_engine.dart';
import '../../support/fake_journal.dart';
import '../../support/fake_llm.dart';
import '../../support/memory_store.dart';

const _server = ServerInfo(
  osId: 'ubuntu',
  osVersion: '24.04',
  prettyName: 'Ubuntu 24.04 LTS',
  arch: 'x86_64',
  isRoot: false,
  fingerprint: '',
);

String _reply(String? command) =>
    '{"diagnosis": "No directory", "command": ${command == null ? 'null' : '"$command"'}, "explanation": "Creates it"}';

class _Factory implements FixSessionFactory {
  _Factory(this.build);

  final FixSession Function() build;
  int opened = 0;

  @override
  Future<FixSession> open() async {
    opened++;
    return build();
  }
}

class _Notifier implements IRunNotifier {
  _Notifier({this.canStart = true});

  final bool canStart;
  final events = <String>[];

  @override
  Future<bool> start() async {
    events.add('start');
    return canStart;
  }

  @override
  Future<void> update(RunSnapshot snapshot) async {}

  @override
  Future<void> showText(String text) async => events.add('text:$text');

  @override
  Future<void> stop() async => events.add('stop');
}

class _Prelude implements CheckpointPreludeSource {
  @override
  Future<String> create() async => '# prelude';
}

class _FailingFactory implements FixSessionFactory {
  @override
  Future<FixSession> open() async =>
      throw const AppProblemError(AppProblem.serverNotConfigured);
}

class _Harness {
  _Harness({
    Map<String, (int, List<String>)> results = const {},
    List<Object> aiReplies = const [],
    bool failJournal = false,
    bool canNotify = true,
  }) : notifier = _Notifier(canStart: canNotify),
       journal = FakeJournal(failWrites: failJournal),
       engine = FakeEngine(results),
       llm = FakeLlm([...aiReplies]) {
    factory = _Factory(
      () => FixSession(
        loop: FixLoop(
          engine: engine,
          advisor: FixAdvisor(
            llm,
            LogRedactor(host: '203.0.113.7', user: 'deployer'),
          ),
          server: _server,
          pollInterval: Duration.zero,
        ),
        journal: journal,
        close: () async => closed++,
      ),
    );
    container = ProviderContainer(
      overrides: [
        secureStoreProvider.overrideWithValue(MemoryStore()),
        fixSessionFactoryProvider.overrideWithValue(factory),
        runNotificationsProvider.overrideWithValue(notifier),
        checkpointPreludeSourceProvider.overrideWithValue(_Prelude()),
      ],
    );
    addTearDown(container.dispose);
  }

  final FakeJournal journal;
  final _Notifier notifier;
  final FakeEngine engine;
  final FakeLlm llm;
  late final _Factory factory;
  late final ProviderContainer container;
  int closed = 0;

  FixRunState get state => container.read(fixRunProvider);
  FixRun get run => container.read(fixRunProvider.notifier);

  Future<void> untilPending() async {
    while (state.pending == null && state.running) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

final _script = DeployScript(jobId: 'demo', body: 'true\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('success: result, journal and the session is closed', () async {
    final h = _Harness();
    h.container.listen(fixRunProvider, (_, _) {});
    await h.run.start(_script);

    expect(h.state.running, isFalse);
    expect(h.state.error, isNull);
    expect(h.state.result?.outcome, FixOutcome.succeeded);
    expect(h.journal.kinds, [
      JournalKind.deployStarted,
      JournalKind.deployFinished,
      JournalKind.runFinished,
    ]);
    expect(h.closed, 1);
    expect(h.llm.requests, isEmpty);
  });

  test('approved fix runs, journal tells the whole story', () async {
    final h = _Harness(
      results: {
        'demo': (1, ['cat: conf: No such file']),
      },
      aiReplies: [_reply('mkdir -p ~/conf')],
    );
    h.container.listen(fixRunProvider, (_, _) {});

    final running = h.run.start(_script);
    await h.untilPending();
    expect(h.state.pending?.command, 'mkdir -p ~/conf');
    h.run.decide(approve: true);
    await running;

    expect(h.state.result?.outcome, FixOutcome.succeeded);
    expect(h.state.pending, isNull);
    expect(h.journal.kinds, [
      JournalKind.deployStarted,
      JournalKind.deployFinished,
      JournalKind.fixProposed,
      JournalKind.fixDecision,
      JournalKind.fixStarted,
      JournalKind.fixFinished,
      JournalKind.deployStarted,
      JournalKind.deployFinished,
      JournalKind.runFinished,
    ]);
    final failed = h.journal.entries[1];
    expect(failed.detail, contains('No such file'));
    expect(h.journal.entries[3].summary, 'User approved the fix');
    expect(h.journal.entries[3].detail, 'command: mkdir -p ~/conf');
    expect(h.closed, 1);
  });

  test('declined fix runs nothing and says so in the journal', () async {
    final h = _Harness(
      results: {
        'demo': (1, ['boom']),
      },
      aiReplies: [_reply('mkdir -p ~/x')],
    );
    h.container.listen(fixRunProvider, (_, _) {});

    final running = h.run.start(_script);
    await h.untilPending();
    h.run.decide(approve: false);
    await running;

    expect(h.state.result?.outcome, FixOutcome.declined);
    expect(h.engine.started.map((s) => s.jobId), ['demo']);
    expect(
      h.journal.entries.map((e) => e.summary),
      contains('User declined the fix'),
    );
  });

  test('a journal that cannot be written does not stop the run', () async {
    final h = _Harness(failJournal: true);
    h.container.listen(fixRunProvider, (_, _) {});
    await h.run.start(_script);

    expect(h.state.result?.outcome, FixOutcome.succeeded);
    expect(h.state.error, isNull);
    expect(h.closed, 1);
  });

  test('a server that cannot be opened becomes the run error', () async {
    final container = ProviderContainer(
      overrides: [
        secureStoreProvider.overrideWithValue(MemoryStore()),
        fixSessionFactoryProvider.overrideWithValue(_FailingFactory()),
      ],
    )..listen(fixRunProvider, (_, _) {});
    addTearDown(container.dispose);

    await container.read(fixRunProvider.notifier).start(_script);
    final state = container.read(fixRunProvider);
    expect(state.running, isFalse);
    expect(
      state.error,
      isA<AppProblemError>().having(
        (e) => e.problem,
        'problem',
        AppProblem.serverNotConfigured,
      ),
    );
    expect(state.result, isNull);
  });

  test('a second start while running is ignored', () async {
    final h = _Harness(
      results: {
        'demo': (1, ['boom']),
      },
      aiReplies: [_reply('mkdir -p ~/x')],
    );
    h.container.listen(fixRunProvider, (_, _) {});

    final running = h.run.start(_script);
    await h.untilPending();
    await h.run.start(_script);
    expect(h.factory.opened, 1);
    h.run.decide(approve: false);
    await running;
  });
  test(
    'the script gets the checkpoint helper and the notification follows',
    () async {
      final h = _Harness();
      h.container.listen(fixRunProvider, (_, _) {});
      await h.run.start(_script);

      expect(h.engine.started.first.body, startsWith('# prelude\n'));
      expect(h.engine.started.first.body, endsWith('true\n'));
      expect(h.notifier.events.first, 'start');
      expect(h.notifier.events.last, 'stop');
      expect(h.notifier.events.where((e) => e.startsWith('text:')), isNotEmpty);
    },
  );

  test('a notification that cannot start does not stop the run', () async {
    final h = _Harness(canNotify: false);
    h.container.listen(fixRunProvider, (_, _) {});
    await h.run.start(_script);

    expect(h.state.result?.outcome, FixOutcome.succeeded);
    expect(h.notifier.events, ['start']);
  });
  test('stop shows "stopping" at once and clears it at the end', () async {
    final h = _Harness(
      results: {
        'demo': (1, ['boom']),
      },
      aiReplies: [_reply('mkdir -p ~/conf')],
    );
    h.container.listen(fixRunProvider, (_, _) {});

    final running = h.run.start(_script);
    await h.untilPending();
    final stopping = h.run.cancel();

    expect(h.state.stopping, isTrue);
    expect(h.state.status, isNotNull);
    await stopping;
    await running;
    expect(h.state.running, isFalse);
    expect(h.state.stopping, isFalse);
    expect(h.state.result?.outcome, FixOutcome.cancelled);
  });
}
