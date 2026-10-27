import 'dart:convert';

/// Progress marker an install script prints on its own line:
/// `@@SOLAGENT {"step":"build","state":"started"}`. Everything else in the
/// log is ordinary output.
const checkpointPrefix = '@@SOLAGENT ';

enum CheckpointState { started, done, failed, finished }

class Checkpoint {
  const Checkpoint({required this.step, required this.state});

  final String step;
  final CheckpointState state;

  @override
  bool operator ==(Object other) =>
      other is Checkpoint && other.step == step && other.state == state;

  @override
  int get hashCode => Object.hash(step, state);

  @override
  String toString() => 'Checkpoint($step, ${state.name})';
}

/// Step names end up in notifications and relay requests, so they are held
/// to a small alphabet. Log text is untrusted: a package may print anything.
final _stepPattern = RegExp(r'^[a-z0-9][a-z0-9_.-]{0,39}$');

bool isValidStepName(String step) => _stepPattern.hasMatch(step);

/// Picks checkpoints out of log lines. Malformed or unknown lines are skipped.
List<Checkpoint> parseCheckpoints(Iterable<String> lines) {
  final result = <Checkpoint>[];
  for (final line in lines) {
    if (!line.startsWith(checkpointPrefix)) continue;
    final Object? json;
    try {
      json = jsonDecode(line.substring(checkpointPrefix.length));
    } on FormatException {
      continue;
    }
    if (json is! Map) continue;
    final step = json['step'];
    final stateName = json['state'];
    if (step is! String || !isValidStepName(step)) continue;
    final state = CheckpointState.values
        .where((s) => s.name == stateName)
        .firstOrNull;
    if (state == null) continue;
    result.add(Checkpoint(step: step, state: state));
  }
  return result;
}
