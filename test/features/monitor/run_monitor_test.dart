import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/features/deploy/data/deploy_engine.dart';
import 'package:solagent/features/deploy/domain/deploy_models.dart';
import 'package:solagent/features/monitor/application/run_monitor.dart';
import 'package:solagent/features/monitor/domain/checkpoint.dart';
import 'package:solagent/features/ssh/domain/i_ssh_client.dart';
import 'package:solagent/features/ssh/domain/ssh_failure.dart';
import 'package:solagent/features/ssh/domain/ssh_target.dart';

/// Answers each poll with the next scripted reply; a [SshFailure] entry
/// simulates a dropped connection.
class _Script implements ISshSession {
  _Script(this.replies);

  final List<Object> replies;
  var calls = 0;

  @override
  SshTarget get target => const SshTarget(host: '203.0.113.7', username: 'u');

  @override
  bool get isClosed => false;

  @override
  Future<SshCommandResult> run(
    String command, {
    Duration timeout = const Duration(minutes: 1),
  }) async {
    final reply = replies[calls < replies.length ? calls : replies.length - 1];
    calls++;
    if (reply is Exception) throw reply;
    return SshCommandResult(exitCode: 0, stdout: reply as String, stderr: '');
  }

  @override
  Future<void> close() async {}
}

String _poll(String state, String lines, {String exit = ''}) =>
    'STATE=$state\nEXIT=$exit\n---\n$lines';

RunMonitor _monitor(_Script session, {int maxFailures = 30}) {
  return RunMonitor(
    jobId: 'job-1',
    openEngine: () async {
      return DeployEngine(session);
    },
    maxFailures: maxFailures,
    delay: (_) async {},
  );
}

void main() {
  group('parseCheckpoints', () {
    test(
      'reads valid markers and skips junk, unknown states and bad names',
      () {
        final found = parseCheckpoints([
          'plain output',
          '@@SOLAGENT {"step":"build","state":"started"}',
          '@@SOLAGENT not json',
          '@@SOLAGENT {"step":"Bad Step!","state":"done"}',
          '@@SOLAGENT {"step":"build","state":"exploded"}',
          '@@SOLAGENT {"step":"build","state":"done"}',
          '@@SOLAGENT [1]',
          ' @@SOLAGENT {"step":"x","state":"done"}',
        ]);
        expect(found, const [
          Checkpoint(step: 'build', state: CheckpointState.started),
          Checkpoint(step: 'build', state: CheckpointState.done),
        ]);
      },
    );
  });

  group('RunMonitor', () {
    test('collects checkpoints across polls and stops at the end', () async {
      final session = _Script([
        _poll('running', '@@SOLAGENT {"step":"deps","state":"started"}\n'),
        _poll('running', '@@SOLAGENT {"step":"deps","state":"done"}\n'),
        _poll(
          'finished',
          '@@SOLAGENT {"step":"all","state":"finished"}\n',
          exit: '0',
        ),
      ]);
      final snapshots = await _monitor(session).watch().toList();

      expect(snapshots, hasLength(3));
      expect(snapshots.last.isTerminal, isTrue);
      expect(snapshots.last.exitCode, 0);
      expect(snapshots.last.checkpoints, hasLength(3));
      expect(
        snapshots.last.latest,
        const Checkpoint(step: 'all', state: CheckpointState.finished),
      );
    });

    test('a dropped connection is reported and the watch resumes', () async {
      final session = _Script([
        _poll('running', '@@SOLAGENT {"step":"deps","state":"started"}\n'),
        const SshNetworkFailure('timeout'),
        _poll('finished', '', exit: '0'),
      ]);
      final snapshots = await _monitor(session).watch().toList();

      expect(snapshots.map((s) => s.connectionLost), [false, true, false]);
      expect(snapshots[1].checkpoints, hasLength(1));
      expect(snapshots.last.isTerminal, isTrue);
    });

    test('gives up after maxFailures in a row', () async {
      final session = _Script([const SshNetworkFailure('down')]);
      final snapshots = await _monitor(
        session,
        maxFailures: 3,
      ).watch().toList();

      expect(snapshots, hasLength(3));
      expect(snapshots.every((s) => s.connectionLost), isTrue);
      expect(snapshots.last.isTerminal, isFalse);
    });

    test('a lost job ends the watch', () async {
      final session = _Script([_poll('lost', '')]);
      final snapshots = await _monitor(session).watch().toList();
      expect(snapshots.single.state, DeployState.lost);
      expect(snapshots.single.isTerminal, isTrue);
    });
  });
}
