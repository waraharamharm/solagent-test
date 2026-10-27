import 'ssh_target.dart';

/// Opens authenticated SSH sessions. Implementations throw only SshFailure.
abstract interface class ISshConnector {
  /// Pins the host key on first successful login (after [confirmNewHostKey]
  /// returned true) and refuses any later mismatch. [credential] is wiped
  /// before this returns or throws.
  Future<ISshSession> connect(
    SshTarget target,
    SshCredential credential, {
    required ConfirmNewHostKey confirmNewHostKey,
  });
}

abstract interface class ISshSession {
  SshTarget get target;
  bool get isClosed;

  /// Runs [command] non-interactively. Low level: callers are responsible
  /// for the command having been approved (AI-generated commands go through
  /// the confirmation flow first).
  Future<SshCommandResult> run(
    String command, {
    Duration timeout = const Duration(minutes: 1),
  });

  Future<void> close();
}
