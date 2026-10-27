import 'fix_loop.dart';
import '../domain/fix_models.dart';

enum FixStepState { running, waiting, done, failed }

/// One visible stage of a run: a job on the server, the AI's diagnosis, or
/// the user's decision.
class FixStep {
  const FixStep(this.title, this.state, {this.detail});

  final String title;
  final FixStepState state;
  final String? detail;

  FixStep to(FixStepState state, {String? detail}) =>
      FixStep(title, state, detail: detail ?? this.detail);
}

class FixRunState {
  const FixRunState({
    this.running = false,
    this.log = const [],
    this.steps = const [],
    this.status,
    this.pending,
    this.result,
    this.error,
  });

  final bool running;
  final List<String> log;
  final List<FixStep> steps;
  final String? status;

  /// Waiting for the user's decision via `FixRun.decide`.
  final FixProposal? pending;
  final FixFinished? result;

  /// Failure before or outside the loop (SSH, missing settings).
  final Object? error;
}
