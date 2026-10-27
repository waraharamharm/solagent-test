import 'package:solagent/features/journal/domain/i_journal.dart';
import 'package:solagent/features/journal/domain/journal_entry.dart';

/// Keeps entries in memory; `failWrites` makes every append throw.
class FakeJournal implements IJournal {
  FakeJournal({this.failWrites = false});

  final bool failWrites;
  final entries = <JournalEntry>[];

  List<JournalKind> get kinds => [for (final e in entries) e.kind];

  @override
  Future<void> append(JournalEntry entry) async {
    if (failWrites) throw StateError('disk full');
    entries.add(entry);
  }

  @override
  Future<List<JournalEntry>> readRecent({int limit = 30}) async => entries;
}
