import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solagent/core/errors/app_problem.dart';
import 'package:solagent/core/security/biometric_gate.dart';
import 'package:solagent/features/server/data/server_repository.dart';
import 'package:solagent/features/server/domain/server_profile.dart';
import 'package:solagent/features/ssh/domain/ssh_target.dart';

import '../../support/memory_store.dart';

class _MockAuth extends Mock implements LocalAuthentication {}

void main() {
  group('validateServerProfile', () {
    AppProblem? v({
      String host = '1.2.3.4',
      int port = 22,
      String user = 'root',
    }) => validateServerProfile(
      ServerProfile(host: host, port: port, username: user),
    );

    test('accepts ip, domain, ipv6', () {
      expect(v(), isNull);
      expect(v(host: 'vds.example.com'), isNull);
      expect(v(host: '2001:db8::1'), isNull);
    });

    test('rejects shell-ish and bad values', () {
      expect(v(host: 'a b'), isNotNull);
      expect(v(host: 'a;rm'), isNotNull);
      expect(v(host: ''), isNotNull);
      expect(v(port: 0), isNotNull);
      expect(v(port: 70000), isNotNull);
      expect(v(user: 'Root User'), isNotNull);
      expect(v(user: r'$(x)'), isNotNull);
    });
  });

  group('ServerRepository', () {
    late MemoryStore store;
    late ServerRepository repo;
    const profile = ServerProfile(host: '10.0.0.1', username: 'root');

    setUp(() {
      store = MemoryStore();
      repo = ServerRepository(store);
    });

    test('round trip; credential is fresh and wipeable', () async {
      await repo.save(profile, 'p@ss word');
      expect((await repo.load())!.host, '10.0.0.1');
      expect(await repo.hasSecret(), isTrue);

      final first = await repo.loadCredential() as SshPasswordCredential;
      first.wipe();
      final second = await repo.loadCredential() as SshPasswordCredential;
      expect(second.bytes.any((b) => b != 0), isTrue);
    });

    test('key kind yields SshKeyCredential with trailing newline', () async {
      await repo.save(
        const ServerProfile(
          host: 'h',
          username: 'root',
          authKind: ServerAuthKind.key,
        ),
        '  -----BEGIN KEY-----  ',
      );
      final c = await repo.loadCredential();
      expect(c, isA<SshKeyCredential>());
      expect(
        String.fromCharCodes((c! as SshKeyCredential).pem),
        endsWith('\n'),
      );
    });

    test('key pasted with spaces instead of newlines is rewrapped', () {
      const collapsed =
          '-----BEGIN OPENSSH PRIVATE KEY----- AAAA BBBB\tCCCC '
          '-----END OPENSSH PRIVATE KEY-----';
      expect(
        normalizePrivateKey(collapsed),
        '-----BEGIN OPENSSH PRIVATE KEY-----\nAAAABBBBCCCC\n'
        '-----END OPENSSH PRIVATE KEY-----\n',
      );
      expect(normalizePrivateKey('junk'), 'junk\n');
    });

    test('invalid input is refused and nothing is stored', () async {
      expect(
        () =>
            repo.save(const ServerProfile(host: 'a b', username: 'root'), 'x'),
        throwsA(isA<AppProblemError>()),
      );
      expect(() => repo.save(profile, '  '), throwsA(isA<AppProblemError>()));
      expect(store.values, isEmpty);
    });

    test('corrupted stored profile reads as absent', () async {
      store.values['server.profile'] = '{not json';
      expect(await repo.load(), isNull);
      store.values['server.profile'] = '{"host":"a b","port":22}';
      expect(await repo.load(), isNull);
    });

    test('delete removes secret and profile', () async {
      await repo.save(profile, 'x');
      await repo.delete();
      expect(store.values, isEmpty);
      expect(await repo.loadCredential(), isNull);
    });
  });

  group('ServerInfo.parse', () {
    test('Ubuntu as root', () {
      final i = ServerInfo.parse(
        'ubuntu|24.04|Ubuntu 24.04.1 LTS\nx86_64\n0\n',
        fingerprint: 'SHA256:x',
      )!;
      expect(i.isSupportedOs, isTrue);
      expect(i.isRoot, isTrue);
      expect(i.arch, 'x86_64');
    });

    test('non-root and unsupported OS; garbage gives null', () {
      final i = ServerInfo.parse(
        'alpine|3.20|Alpine\naarch64\n1000\n',
        fingerprint: '',
      )!;
      expect(i.isSupportedOs, isFalse);
      expect(i.isRoot, isFalse);
      expect(ServerInfo.parse('bash: error', fingerprint: ''), isNull);
    });
  });

  group('LocalAuthGate', () {
    late _MockAuth auth;
    setUp(() => auth = _MockAuth());

    test('granted / denied', () async {
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
      when(
        () => auth.authenticate(localizedReason: any(named: 'localizedReason')),
      ).thenAnswer((_) async => true);
      expect(await LocalAuthGate(auth).authenticate('r'), GateResult.granted);

      when(
        () => auth.authenticate(localizedReason: any(named: 'localizedReason')),
      ).thenAnswer((_) async => false);
      expect(await LocalAuthGate(auth).authenticate('r'), GateResult.denied);
    });

    test('no lock screen -> unavailable, never granted', () async {
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => false);
      expect(
        await LocalAuthGate(auth).authenticate('r'),
        GateResult.unavailable,
      );
    });

    test('platform error fails closed', () async {
      when(() => auth.isDeviceSupported()).thenThrow(Exception('boom'));
      expect(
        await LocalAuthGate(auth).authenticate('r'),
        GateResult.unavailable,
      );
    });
  });
}
