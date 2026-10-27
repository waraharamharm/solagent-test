// Real-server checks, same env as the SSH integration test. Writes only to
// $HOME/.solagent/jobs/ of the test user and removes its jobs afterwards.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/features/deploy/data/deploy_engine.dart';
import 'package:solagent/features/deploy/domain/deploy_models.dart';
import 'package:solagent/features/ssh/data/dartssh2_connector.dart';
import 'package:solagent/features/ssh/data/known_hosts_store.dart';
import 'package:solagent/features/ssh/domain/i_ssh_client.dart';
import 'package:solagent/features/ssh/domain/ssh_target.dart';

import '../../support/memory_store.dart';

void main() {
  final env = Platform.environment;
  final host = env['SOLAGENT_VDS_HOST'];
  final skip = host == null ? 'SOLAGENT_VDS_* not set' : null;
  final suffix = DateTime.now().millisecondsSinceEpoch % 1000000;

  late DartSsh2Connector connector;
  late SshTarget target;

  Future<ISshSession> open() => connector.connect(
    target,
    SshKeyCredential(File(env['SOLAGENT_VDS_KEY']!).readAsBytesSync()),
    confirmNewHostKey: (_) async => true,
  );

  Future<DeployProgress> waitDone(DeployEngine engine, String id) async {
    for (var i = 0; i < 30; i++) {
      final p = await engine.poll(id);
      if (p.isTerminal) return p;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    fail('job did not finish');
  }

  setUp(() {
    connector = DartSsh2Connector(KnownHostsStore(MemoryStore()));
    target = SshTarget(
      host: host ?? '',
      username: env['SOLAGENT_VDS_USER'] ?? '',
    );
  });

  test(
    'job outlives the SSH session; log and exit code are read back',
    () async {
      final id = 'test-detach-$suffix';
      var session = await open();
      await DeployEngine(session).start(
        DeployScript(
          jobId: id,
          body: 'echo one\nsleep 3\necho "two \$((6*7))"\nexit 7\n',
        ),
      );
      await session.close();

      session = await open();
      addTearDown(session.close);
      final engine = DeployEngine(session);
      addTearDown(() => engine.remove(id));

      final done = await waitDone(engine, id);
      expect(done.state, DeployState.finished);
      expect(done.exitCode, 7);
      expect(done.newLines, ['one', 'two 42']);

      final again = await engine.poll(id, fromLine: 1);
      expect(again.newLines, ['two 42']);
      expect(again.nextLine, 2);
    },
    skip: skip,
  );

  test('duplicate job id is refused', () async {
    final id = 'test-dup-$suffix';
    final session = await open();
    addTearDown(session.close);
    final engine = DeployEngine(session);
    addTearDown(() => engine.remove(id));

    await engine.start(DeployScript(jobId: id, body: 'true\n'));
    await expectLater(
      engine.start(DeployScript(jobId: id, body: 'true\n')),
      throwsA(isA<DeployFailure>()),
    );
  }, skip: skip);

  test('cancel stops the job and its children', () async {
    final id = 'test-cancel-$suffix';
    final session = await open();
    addTearDown(session.close);
    final engine = DeployEngine(session);
    addTearDown(() => engine.remove(id));

    await engine.start(DeployScript(jobId: id, body: 'sleep 120\n'));
    expect((await engine.poll(id)).state, DeployState.running);
    await engine.cancel(id);
    final p = await waitDone(engine, id);
    expect(p.state, DeployState.cancelled);
    expect(
      (await session.run('pgrep -u "\$USER" -f "[s]leep 120" || true')).stdout
          .trim(),
      isEmpty,
    );
  }, skip: skip);

  test('unknown job and running-job removal', () async {
    final session = await open();
    addTearDown(session.close);
    final engine = DeployEngine(session);
    expect((await engine.poll('test-nope-$suffix')).state, DeployState.unknown);
  }, skip: skip);

  test('invalid job id never reaches the shell', () {
    expect(isValidJobId('a; rm -rf ~'), isFalse);
    expect(isValidJobId('../x'), isFalse);
    expect(isValidJobId('ok-1'), isTrue);
    expect(
      () => DeployScript(jobId: r'$(x)', body: 'true'),
      throwsArgumentError,
    );
  });
}
