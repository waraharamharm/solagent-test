import 'dart:convert';

import '../../fix/domain/log_redactor.dart';
import '../../ssh/domain/i_ssh_client.dart';
import '../domain/i_journal.dart';
import '../domain/journal_entry.dart';

/// The app's own log on the user's server: `$HOME/.solagent/journal.jsonl`,
/// one JSON object per line, mode 600. A later session reads it back so the AI
/// knows what was already tried instead of inspecting the server from scratch.
///
/// Everything written passes through [LogRedactor]. The file rotates to
/// `journal.jsonl.1` at 1 MiB, so at most about 2 MiB is kept.
class JournalStore implements IJournal {
  JournalStore(this._session, this._redactor);

  final ISshSession _session;
  final LogRedactor _redactor;

  static const maxBytes = 1048576;
  static const _readTailLines = 400;
  static const _readTailBytes = 200000;

  static const _file = r'"$HOME"/.solagent/journal.jsonl';

  @override
  Future<void> append(JournalEntry entry) async {
    final safe = JournalEntry(
      time: entry.time,
      kind: entry.kind,
      jobId: entry.jobId,
      summary: _redactor.redact(entry.summary),
      detail: entry.detail == null ? null : _redactor.redact(entry.detail!),
    );
    final line = base64.encode(utf8.encode(jsonEncode(safe.toJson())));
    final result = await _session.run(
      'mkdir -p "\$HOME"/.solagent && chmod 700 "\$HOME"/.solagent '
      '&& umask 077 '
      '&& { [ ! -f $_file ] || [ "\$(stat -c%s $_file)" -lt $maxBytes ] '
      '|| mv -f $_file $_file.1; } '
      '&& { echo $line | base64 -d; echo; } >> $_file',
      timeout: const Duration(seconds: 15),
    );
    if (!result.succeeded) {
      throw const JournalFailure('Could not write journal');
    }
  }

  /// The newest [limit] entries, oldest first. Lines that are not valid
  /// entries are skipped; a missing file is an empty journal.
  @override
  Future<List<JournalEntry>> readRecent({int limit = 30}) async {
    final result = await _session.run(
      'tail -n $_readTailLines $_file 2>/dev/null | tail -c $_readTailBytes; true',
      timeout: const Duration(seconds: 15),
    );
    final entries = <JournalEntry>[];
    for (final line in const LineSplitter().convert(result.stdout)) {
      if (line.length > 8000) continue;
      try {
        final entry = JournalEntry.tryParse(jsonDecode(line));
        if (entry != null) entries.add(entry);
      } on FormatException {
        continue;
      }
    }
    return entries.length <= limit
        ? entries
        : entries.sublist(entries.length - limit);
  }
}

class JournalFailure implements Exception {
  const JournalFailure(this.message);

  final String message;

  @override
  String toString() => 'JournalFailure: $message';
}
