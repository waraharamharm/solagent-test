import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/i_ssh_client.dart';
import '../domain/ssh_failure.dart';
import '../domain/ssh_target.dart';
import 'known_hosts_store.dart';

part 'dartssh2_connector.g.dart';

typedef SshSocketFactory = Future<SSHSocket> Function(
  String host,
  int port,
  Duration timeout,
);

Future<SSHSocket> _defaultSocket(String host, int port, Duration timeout) =>
    SSHSocket.connect(host, port, timeout: timeout);

class DartSsh2Connector implements ISshConnector {
  DartSsh2Connector(
    this._knownHosts, {
    this._socketFactory = _defaultSocket,
    this.connectTimeout = const Duration(seconds: 15),
    this.authTimeout = const Duration(seconds: 30),
  });

  final KnownHostsStore _knownHosts;
  final SshSocketFactory _socketFactory;
  final Duration connectTimeout;

  /// Starts after key exchange, so the user's host-key decision is not
  /// counted against it.
  final Duration authTimeout;

  @override
  Future<ISshSession> connect(
    SshTarget target,
    SshCredential credential, {
    required ConfirmNewHostKey confirmNewHostKey,
  }) async {
    SSHClient? client;
    SshFailure? hostKeyFailure;
    HostKeyInfo? toPin;
    try {
      final identities = switch (credential) {
        SshKeyCredential() => _parseKey(credential),
        SshPasswordCredential() => null,
      };
      final pinned = await _knownHosts.find(target.hostId);
      final socket = await _socketFactory(
        target.host,
        target.port,
        connectTimeout,
      );

      var passwordSent = false;
      client = SSHClient(
        socket,
        username: target.username,
        identities: identities,
        authTimeout: authTimeout,
        onPasswordRequest: switch (credential) {
          SshPasswordCredential(:final bytes) => () {
            if (passwordSent) return null;
            passwordSent = true;
            return utf8.decode(bytes);
          },
          SshKeyCredential() => null,
        },
        onVerifyHostKey: (type, fingerprint) async {
          final presented = HostKeyInfo(
            hostId: target.hostId,
            type: type,
            fingerprint: utf8.decode(fingerprint),
          );
          if (pinned != null) {
            if (pinned.fingerprint == presented.fingerprint) return true;
            hostKeyFailure = SshHostKeyMismatch(
              expected: pinned.fingerprint,
              actual: presented.fingerprint,
            );
            return false;
          }
          if (!await confirmNewHostKey(presented)) {
            hostKeyFailure = const SshHostKeyRejected();
            return false;
          }
          toPin = presented;
          return true;
        },
      );

      await client.authenticated;
      if (toPin != null) await _knownHosts.pin(toPin!);
      return _DartSsh2Session(target, client);
    } catch (e) {
      client?.close();
      throw hostKeyFailure ?? mapSshError(e);
    } finally {
      credential.wipe();
    }
  }

  List<SSHKeyPair> _parseKey(SshKeyCredential credential) {
    try {
      final passphrase = credential.passphrase;
      return SSHKeyPair.fromPem(
        utf8.decode(credential.pem),
        passphrase == null ? null : utf8.decode(passphrase),
      );
    } on SSHKeyDecryptError {
      throw const SshInvalidKey('Wrong passphrase');
    } catch (_) {
      throw const SshInvalidKey('Unsupported or corrupted private key');
    }
  }
}

class _DartSsh2Session implements ISshSession {
  _DartSsh2Session(this.target, this._client);

  @override
  final SshTarget target;
  final SSHClient _client;

  @override
  bool get isClosed => _client.isClosed;

  @override
  Future<SshCommandResult> run(
    String command, {
    Duration timeout = const Duration(minutes: 1),
  }) async {
    try {
      final result = await _client.runWithResult(command).timeout(timeout);
      return SshCommandResult(
        exitCode: result.exitCode,
        stdout: utf8.decode(result.stdout, allowMalformed: true),
        stderr: utf8.decode(result.stderr, allowMalformed: true),
      );
    } on TimeoutException {
      throw SshTimeout('Command did not finish in ${timeout.inSeconds}s');
    } catch (e) {
      throw mapSshError(e);
    }
  }

  @override
  Future<void> close() async {
    _client.close();
    try {
      await _client.done;
    } catch (_) {
      // Already closed or torn down by the server; nothing to recover.
    }
  }
}

SshFailure mapSshError(Object e) => switch (e) {
  SshFailure() => e,
  SSHAuthError() => const SshAuthFailed('Server rejected the credentials'),
  SSHKeyDecodeError() => const SshInvalidKey('Unsupported private key'),
  SSHSocketError() ||
  SocketException() ||
  SSHDisconnectError() => const SshNetworkFailure('Connection lost or refused'),
  TimeoutException() => const SshTimeout('Server did not respond in time'),
  _ => SshProtocolFailure(e.runtimeType.toString()),
};

@Riverpod(keepAlive: true)
ISshConnector sshConnector(Ref ref) =>
    DartSsh2Connector(ref.watch(knownHostsStoreProvider));
