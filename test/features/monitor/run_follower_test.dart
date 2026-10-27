import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/features/deploy/data/deploy_engine.dart';
import 'package:solagent/features/deploy/domain/deploy_models.dart';
import 'package:solagent/features/monitor/application/run_follower.dart';
import 'package:solagent/features/monitor/application/run_monitor.dart';

import '../../support/fake_ssh_session.dart';

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
  Future<void> update(RunSnapshot snapshot) async =>
      events.add('update:${snapshot.state.name}');

  @override
  Future<void> showText(String text) async => events.add('text:$text');

  @override
  Future<void> stop() async => events.add('stop');
}

RunMonitor _monitor(FakeSshSession session) => RunMonitor(
  jobId: 'job-1',
  openEngine: () async => DeployEngine(session),
  delay: (_) async {},
);

void main() {
  test(
    'mirrors snapshots into the notification and stops it at the end',
    () async {
      final session = FakeSshSession()
        ..stdout = 'STATE=finished\nEXIT=0\n---\n';
      final notifier = _Notifier();

      final last = await followRun(_monitor(session), notifier);

      expect(notifier.events, ['start', 'update:finished', 'stop']);
      expect(last.state, DeployState.finished);
    },
  );

  test('without the notification the run is still followed', () async {
    final session = FakeSshSession()..stdout = 'STATE=finished\nEXIT=0\n---\n';
    final notifier = _Notifier(canStart: false);

    final last = await followRun(_monitor(session), notifier);

    expect(notifier.events, ['start']);
    expect(last.isTerminal, isTrue);
  });
}
