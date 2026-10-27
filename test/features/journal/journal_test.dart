import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/features/fix/domain/log_redactor.dart';
import 'package:solagent/features/journal/data/journal_store.dart';
import 'package:solagent/features/journal/domain/journal_entry.dart';
import 'package:solagent/features/ssh/domain/i_ssh_client.dart';
import 'package:solagent/features/ssh/domain/ssh_target.dart';

class _FakeSession implements ISshSession {
  final commands = <String>[];
  String stdout = '';
  int exitCode = 0;

  @override
  SshTarget get target => const SshTarget(host: '203.0.113.7', username: 'u');

  @override
  bool get isClosed => false;

  @override
  Future<SshCommandResult> run(
    String command, {
    Duration timeout = const Duration(minutes: 1),
  }) async {
    commands.add(command);
    return SshCommandResult(exitCode: exitCode, stdout: stdout, stderr: '');
  }

  @override
  Future<void> close() async {}
}

Map<String, Object?> _writtenLine(String command) {
  final b64 = RegExp(r'echo ([A-Za-z0-9+/=]+) \| base64 -d')
      .firstMatch(command);
  return jsonDecode(utf8.decode(base64.decode(b64!.group(1)!)))
      as Map<String, Object?>;
}

void main() {
  final redactor = LogRedactor(host: '203.0.113.7', user: 'deployer');

  group('JournalEntry', () {
    test('round trip keeps the fields', () {
      final e = JournalEntry(
        time: DateTime.utc(2026, 10, 27, 12),
        kind: JournalKind.fixFinished,
        jobId: 'demo-f1',
        summary: 'Exit code 0',
        detail: 'ok',
      );
      final back = JournalEntry.tryParse(jsonDecode(jsonEncode(e.toJson())))!;
      expect(back.time, e.time);
      expect(back.kind, JournalKind.fixFinished);
      expect(back.jobId, 'demo-f1');
      expect(back.summary, 'Exit code 0');
      expect(back.detail, 'ok');
    });

    test('long text is cut and control characters are removed', () {
      final e = JournalEntry(
        time: DateTime.utc(2026),
        kind: JournalKind.note,
        summary: 'a\n\u001b[31m${'x' * 1000}',
        detail: 'y' * 5000,
      );
      expect(e.summary.length, JournalEntry.maxSummary);
      expect(e.summary, isNot(contains('\u001b')));
      expect(e.detail!.length, JournalEntry.maxDetail);
      expect(jsonEncode(e.toJson()).length, lessThan(4000));
    });

    test('garbage and edited entries are tolerated or dropped', () {
      expect(JournalEntry.tryParse('text'), isNull);
      expect(JournalEntry.tryParse({'s': 'no time'}), isNull);
      expect(JournalEntry.tryParse({'t': 'not a date', 's': 'x'}), isNull);
      expect(JournalEntry.tryParse({'t': '2026-01-01T00:00:00Z'}), isNull);
      final odd = JournalEntry.tryParse({
        't': '2026-01-01T00:00:00Z',
        'k': 'somethingNew',
        'job': r'../../etc; rm -rf $HOME',
        's': 'x',
      })!;
      expect(odd.kind, JournalKind.note);
      expect(odd.jobId, isNull);
    });
  });

  group('JournalStore.append', () {
    test('writes one redacted line, private, with rotation', () async {
      final session = _FakeSession();
      await JournalStore(session, redactor).append(
        JournalEntry(
          time: DateTime.utc(2026, 10, 27),
          kind: JournalKind.fixProposed,
          jobId: 'demo',
          summary: 'cannot reach 203.0.113.7 as deployer',
          detail: 'command: echo password=hunter2hunter2',
        ),
      );
      final command = session.commands.single;
      expect(command, contains('chmod 700'));
      expect(command, contains('umask 077'));
      expect(command, contains('journal.jsonl.1'));
      expect(command, contains('>>'));

      final line = _writtenLine(command);
      expect(line['k'], 'fixProposed');
      expect(line['job'], 'demo');
      expect(jsonEncode(line), isNot(contains('203.0.113.7')));
      expect(jsonEncode(line), isNot(contains('deployer')));
      expect(jsonEncode(line), isNot(contains('hunter2hunter2')));
    });

    test('a failing write throws JournalFailure', () async {
      final session = _FakeSession()..exitCode = 1;
      expect(
        () => JournalStore(session, redactor).append(
          JournalEntry(
            time: DateTime.utc(2026),
            kind: JournalKind.note,
            summary: 's',
          ),
        ),
        throwsA(isA<JournalFailure>()),
      );
    });
  });

  group('JournalStore.readRecent', () {
    String line(int i, {String kind = 'deployStarted'}) => jsonEncode({
      't': DateTime.utc(2026, 1, 1, 0, i).toIso8601String(),
      'k': kind,
      's': 'entry $i',
    });

    test('returns the newest entries, oldest first, skipping junk', () async {
      final session = _FakeSession()
        ..stdout = [
          'partial line cut by tail -c',
          for (var i = 0; i < 5; i++) line(i),
          '{"broken json',
          '[1,2,3]',
          '',
        ].join('\n');
      final entries = await JournalStore(
        session,
        redactor,
      ).readRecent(limit: 3);
      expect(entries.map((e) => e.summary), ['entry 2', 'entry 3', 'entry 4']);
      expect(session.commands.single, contains('journal.jsonl'));
      expect(session.commands.single, contains('tail'));
    });

    test('a missing file is an empty journal', () async {
      final session = _FakeSession();
      expect(await JournalStore(session, redactor).readRecent(), isEmpty);
    });

    test('oversized lines are ignored', () async {
      final session = _FakeSession()
        ..stdout = '{"t":"2026-01-01T00:00:00Z","s":"${'x' * 9000}"}';
      expect(await JournalStore(session, redactor).readRecent(), isEmpty);
    });
  });
}
