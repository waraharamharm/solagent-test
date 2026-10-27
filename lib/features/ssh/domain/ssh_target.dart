import 'dart:typed_data';

class SshTarget {
  const SshTarget({required this.host, required this.username, this.port = 22});

  final String host;
  final int port;
  final String username;

  /// Known-hosts key. The host key belongs to the machine, not the user.
  String get hostId => '$host:$port';

  @override
  String toString() => '$username@$host:$port';
}

/// Secret material for one login. Consumed by the connector: buffers are
/// zeroed right after authentication, success or not.
///
/// Zeroing is best effort. dartssh2 takes the password and PEM as Dart
/// strings, which are immutable and cannot be wiped; we only keep that copy
/// alive for the duration of the handshake.
sealed class SshCredential {
  void wipe();
}

final class SshPasswordCredential extends SshCredential {
  SshPasswordCredential(this.bytes);

  /// UTF-8 password.
  final Uint8List bytes;

  @override
  void wipe() => bytes.fillRange(0, bytes.length, 0);
}

final class SshKeyCredential extends SshCredential {
  SshKeyCredential(this.pem, {this.passphrase});

  /// OpenSSH or PEM private key, UTF-8.
  final Uint8List pem;
  final Uint8List? passphrase;

  @override
  void wipe() {
    pem.fillRange(0, pem.length, 0);
    passphrase?.fillRange(0, passphrase!.length, 0);
  }
}

class HostKeyInfo {
  const HostKeyInfo({
    required this.hostId,
    required this.type,
    required this.fingerprint,
  });

  final String hostId;
  final String type;

  /// OpenSSH format, `SHA256:<base64>`; comparable with
  /// `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on the server.
  final String fingerprint;
}

/// Asks the user whether to trust a host seen for the first time.
typedef ConfirmNewHostKey = Future<bool> Function(HostKeyInfo info);

class SshCommandResult {
  const SshCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// Null when the server did not report one (e.g. killed by a signal).
  final int? exitCode;
  final String stdout;
  final String stderr;

  bool get succeeded => exitCode == 0;
}
