/// Job ids end up inside shell commands and paths, so they are restricted
/// to a character set that needs no quoting.
final _jobIdPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,39}$');

bool isValidJobId(String id) => _jobIdPattern.hasMatch(id);

/// A shell script to run on the VDS. The caller must have shown it to the
/// user and got approval (or authored it from a bundled template).
class DeployScript {
  DeployScript({required this.jobId, required this.body}) {
    if (!isValidJobId(jobId)) {
      throw ArgumentError.value(jobId, 'jobId', 'must match [a-z0-9-]{1,40}');
    }
    if (body.trim().isEmpty) throw ArgumentError('Empty script');
  }

  final String jobId;
  final String body;

  static const maxBytes = 64 * 1024;
}

enum DeployState {
  running,

  /// Finished; see [DeployProgress.exitCode].
  finished,

  /// Stopped by [DeployEngine.cancel].
  cancelled,

  /// Neither running nor finished: the process was killed (reboot, OOM,
  /// `kill -9`) before it could record an exit code.
  lost,

  /// No such job on the server.
  unknown,
}

class DeployProgress {
  const DeployProgress({
    required this.state,
    required this.newLines,
    required this.nextLine,
    this.exitCode,
  });

  final DeployState state;

  /// Log lines after the requested offset. Pass [nextLine] to the next poll.
  final List<String> newLines;
  final int nextLine;
  final int? exitCode;

  bool get succeeded => state == DeployState.finished && exitCode == 0;
  bool get isTerminal => state != DeployState.running;
}

class DeployFailure implements Exception {
  const DeployFailure(this.message);

  final String message;

  @override
  String toString() => 'DeployFailure: $message';
}
