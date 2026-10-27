import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/features/fix/domain/log_redactor.dart';

void main() {
  final r = LogRedactor(
    knownSecrets: ['hunter2pass'],
    host: 'vps.example.org',
    user: 'deployer',
  );

  test('server address, login and home path', () {
    final out = r.redact(
      'ssh deployer@vps.example.org failed in /home/deployer/app',
    );
    expect(out, isNot(contains('vps.example.org')));
    expect(out, isNot(contains('deployer')));
    expect(out, contains('/home/<user>/app'));
  });

  test('login inside a file name is kept', () {
    final out = r.redact(
      'grep: /home/deployer/deployer-demo/app.conf: no file. user deployer.',
    );
    expect(out, contains('/home/<user>/deployer-demo/app.conf'));
    expect(out, contains('user <user>.'));
  });

  test('IPs, keeping loopback; times survive', () {
    final out = r.redact(
      'connect 203.0.113.7:5060 and 2001:db8::1 from 127.0.0.1 at 12:34:56',
    );
    expect(out, isNot(contains('203.0.113.7')));
    expect(out, isNot(contains('2001:db8::1')));
    expect(out, contains('127.0.0.1'));
    expect(out, contains('12:34:56'));
  });

  test('credentials in key=value, CLI flags, URLs and headers', () {
    final out = r.redact(
      'DB_PASSWORD=s3cr3t\n'
      'mysql --password=topsecret\n'
      'git clone https://bob:pa55@git.example.com/x.git\n'
      'Authorization: Bearer abc.def\n'
      'api_key: "zzz"',
    );
    for (final leak in ['s3cr3t', 'topsecret', 'pa55', 'abc.def', 'zzz']) {
      expect(out, isNot(contains(leak)), reason: leak);
    }
  });

  test('known secrets, tokens, keys and emails', () {
    final out = r.redact(
      'pass hunter2pass\n'
      'key sk-proj-AbCdEfGhIjKlMnOpQrSt12\n'
      'gh ghp_abcdefghijklmnopqrstuvwxyz0123\n'
      'mail admin@corp.io\n'
      '-----BEGIN OPENSSH PRIVATE KEY-----\nAAAA\n-----END OPENSSH PRIVATE KEY-----',
    );
    for (final leak in [
      'hunter2pass',
      'sk-proj-',
      'ghp_',
      'admin@corp.io',
      'AAAA',
    ]) {
      expect(out, isNot(contains(leak)), reason: leak);
    }
  });

  test('ordinary error text is left readable', () {
    const line =
        'E: Unable to locate package flexisip\n'
        'Authentication failed: permission denied (publickey)\n'
        'port 5060 already in use';
    expect(r.redact(line), line);
  });

  test('background isolate gives the same result', () async {
    const text = 'user deployer at 10.0.0.5 token=abc';
    expect(await r.redactInBackground(text), r.redact(text));
  });
}
