// Real-server checks. Skipped unless these are set:
//   SOLAGENT_VDS_HOST, SOLAGENT_VDS_USER, SOLAGENT_VDS_KEY (private key path),
//   SOLAGENT_VDS_FP (expected SHA256:... host fingerprint).
// Runs read-only commands only.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/security/secure_store.dart';
import 'package:solagent/features/ssh/data/dartssh2_connector.dart';
import 'package:solagent/features/ssh/data/known_hosts_store.dart';
import 'package:solagent/features/ssh/domain/ssh_failure.dart';
import 'package:solagent/features/ssh/domain/ssh_target.dart';

class _MemoryStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  final env = Platform.environment;
  final host = env['SOLAGENT_VDS_HOST'];
  final skip = host == null ? 'SOLAGENT_VDS_* not set' : null;

  late KnownHostsStore knownHosts;
  late DartSsh2Connector connector;
  late SshTarget target;
  late String expectedFp;

  SshKeyCredential key() =>
      SshKeyCredential(File(env['SOLAGENT_VDS_KEY']!).readAsBytesSync());

  setUp(() {
    knownHosts = KnownHostsStore(_MemoryStore());
    connector = DartSsh2Connector(knownHosts);
    target = SshTarget(
      host: host ?? '',
      username: env['SOLAGENT_VDS_USER'] ?? '',
    );
    expectedFp = env['SOLAGENT_VDS_FP'] ?? '';
  });

  test(
    'first login shows the real fingerprint, pins it, runs a command',
    () async {
      HostKeyInfo? shown;
      final credential = key();
      final session = await connector.connect(
        target,
        credential,
        confirmNewHostKey: (info) async {
          shown = info;
          return true;
        },
      );
      addTearDown(session.close);

      expect(shown!.fingerprint, expectedFp);
      expect((await knownHosts.find(target.hostId))!.fingerprint, expectedFp);
      expect(credential.pem.every((b) => b == 0), isTrue, reason: 'key wiped');

      final result = await session.run('uname -s');
      expect(result.succeeded, isTrue);
      expect(result.stdout.trim(), 'Linux');

      final failed = await session.run('false');
      expect(failed.exitCode, 1);
    },
    skip: skip,
  );

  test('second login does not ask again', () async {
    await knownHosts.pin(
      HostKeyInfo(
        hostId: target.hostId,
        type: 'ssh-ed25519',
        fingerprint: expectedFp,
      ),
    );
    final session = await connector.connect(
      target,
      key(),
      confirmNewHostKey: (_) async => fail('must not prompt for a pinned host'),
    );
    await session.close();
  }, skip: skip);

  test('changed host key is refused without asking', () async {
    await knownHosts.pin(
      HostKeyInfo(
        hostId: target.hostId,
        type: 'ssh-ed25519',
        fingerprint:
            'SHA256:${base64.encode(List.filled(32, 7)).replaceAll('=', '')}',
      ),
    );
    await expectLater(
      connector.connect(
        target,
        key(),
        confirmNewHostKey: (_) async => fail('must not prompt on mismatch'),
      ),
      throwsA(
        isA<SshHostKeyMismatch>().having((f) => f.actual, 'actual', expectedFp),
      ),
    );
  }, skip: skip);

  test('declined host is not pinned', () async {
    await expectLater(
      connector.connect(target, key(), confirmNewHostKey: (_) async => false),
      throwsA(isA<SshHostKeyRejected>()),
    );
    expect(await knownHosts.find(target.hostId), isNull);
  }, skip: skip);

  test(
    'wrong password -> SshAuthFailed, buffer wiped, host not pinned',
    () async {
      final credential = SshPasswordCredential(
        Uint8List.fromList(utf8.encode('definitely-wrong')),
      );
      await expectLater(
        connector.connect(
          target,
          credential,
          confirmNewHostKey: (_) async => true,
        ),
        throwsA(isA<SshAuthFailed>()),
      );
      expect(credential.bytes.every((b) => b == 0), isTrue);
      expect(await knownHosts.find(target.hostId), isNull);
    },
    skip: skip,
  );

  test('slow command -> SshTimeout', () async {
    final session = await connector.connect(
      target,
      key(),
      confirmNewHostKey: (_) async => true,
    );
    addTearDown(session.close);
    await expectLater(
      session.run('sleep 5', timeout: const Duration(seconds: 1)),
      throwsA(isA<SshTimeout>()),
    );
  }, skip: skip);

  test('unreachable port -> SshNetworkFailure', () async {
    final closed = DartSsh2Connector(
      knownHosts,
      connectTimeout: const Duration(seconds: 3),
    );
    await expectLater(
      closed.connect(
        SshTarget(host: target.host, username: target.username, port: 1),
        key(),
        confirmNewHostKey: (_) async => true,
      ),
      throwsA(anyOf(isA<SshNetworkFailure>(), isA<SshTimeout>())),
    );
  }, skip: skip);

  test('garbage key -> SshInvalidKey before any network', () async {
    await expectLater(
      connector.connect(
        target,
        SshKeyCredential(Uint8List.fromList(utf8.encode('not a key'))),
        confirmNewHostKey: (_) async => fail('no network expected'),
      ),
      throwsA(isA<SshInvalidKey>()),
    );
  }, skip: skip);
}
