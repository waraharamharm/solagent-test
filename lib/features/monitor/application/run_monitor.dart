import 'dart:async';

import '../../deploy/data/deploy_engine.dart';
import '../../deploy/domain/deploy_models.dart';
import '../domain/checkpoint.dart';

/// What the monitor knows about a run at one moment.
class RunSnapshot {
  const RunSnapshot({
    required this.state,
    this.exitCode,
    this.checkpoints = const [],
    this.connectionLost = false,
  });

  final DeployState state;
  final int? exitCode;
  final List<Checkpoint> checkpoints;

  /// The phone cannot reach the VDS right now; the install itself keeps going.
  final bool connectionLost;

  Checkpoint? get latest => checkpoints.isEmpty ? null : checkpoints.last;

  /// The run ended: the monitor stops after emitting this.
  bool get isTerminal => !connectionLost && state != DeployState.running;
}

/// Watches one detached job by polling. Opens a fresh session whenever the
/// previous one broke, so a dropped connection never stops the watch.
class RunMonitor {
  RunMonitor({
    required this.jobId,
    required this._openEngine,
    this._closeEngine,
    this.interval = const Duration(seconds: 5),
    this.maxInterval = const Duration(minutes: 1),
    this.maxFailures = 30,
    Future<void> Function(Duration)? delay,
  }) : _delay = delay ?? Future<void>.delayed;

  final String jobId;
  final Duration interval;
  final Duration maxInterval;

  /// Consecutive failed polls before the stream gives up.
  final int maxFailures;
  final Future<DeployEngine> Function() _openEngine;
  final Future<void> Function()? _closeEngine;
  final Future<void> Function(Duration) _delay;

  Stream<RunSnapshot> watch() async* {
    DeployEngine? engine;
    var fromLine = 0;
    var failures = 0;
    final seen = <Checkpoint>[];
    var last = const RunSnapshot(state: DeployState.running);
    while (true) {
      try {
        engine ??= await _openEngine();
        final progress = await engine.poll(jobId, fromLine: fromLine);
        failures = 0;
        fromLine = progress.nextLine;
        seen.addAll(parseCheckpoints(progress.newLines));
        last = RunSnapshot(
          state: progress.state,
          exitCode: progress.exitCode,
          checkpoints: List.unmodifiable(seen),
        );
        yield last;
        if (last.isTerminal) return;
      } on Exception {
        failures++;
        engine = null;
        await _closeEngine?.call();
        yield RunSnapshot(
          state: last.state,
          exitCode: last.exitCode,
          checkpoints: last.checkpoints,
          connectionLost: true,
        );
        if (failures >= maxFailures) return;
      }
      final factor = failures == 0 ? 1 : 1 << (failures.clamp(0, 5));
      final wait = interval * factor;
      await _delay(wait > maxInterval ? maxInterval : wait);
    }
  }
}
