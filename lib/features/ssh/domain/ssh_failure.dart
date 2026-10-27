sealed class SshFailure implements Exception {
  const SshFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The pinned key differs from the one presented. Either the server was
/// reinstalled or someone is intercepting the connection. Never auto-accept.
final class SshHostKeyMismatch extends SshFailure {
  const SshHostKeyMismatch({required this.expected, required this.actual})
    : super('Host key changed');

  final String expected;
  final String actual;
}

/// The user declined a host seen for the first time.
final class SshHostKeyRejected extends SshFailure {
  const SshHostKeyRejected() : super('Host key rejected by user');
}

final class SshAuthFailed extends SshFailure {
  const SshAuthFailed(super.message);
}

/// The private key could not be parsed or the passphrase is wrong.
final class SshInvalidKey extends SshFailure {
  const SshInvalidKey(super.message);
}

/// DNS, refused connection, dropped link.
final class SshNetworkFailure extends SshFailure {
  const SshNetworkFailure(super.message);
}

final class SshTimeout extends SshFailure {
  const SshTimeout(super.message);
}

/// Anything else from the SSH layer.
final class SshProtocolFailure extends SshFailure {
  const SshProtocolFailure(super.message);
}
