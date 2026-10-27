/// What the relay returns for a new run. [token] goes only to the install
/// script on the user's VDS; it lets that script report checkpoints for this
/// one run and nothing else.
class RunRegistration {
  const RunRegistration({required this.runId, required this.token});

  final String runId;
  final String token;
}

abstract interface class IRunRelay {
  /// Registers a run so the relay can push checkpoints to [fcmToken].
  /// Throws only `RagFailure`.
  Future<RunRegistration> register({
    required String fcmToken,
    required String language,
  });
}
