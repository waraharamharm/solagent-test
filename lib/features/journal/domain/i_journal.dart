import 'journal_entry.dart';

/// The app's record of what it did on a server, kept on that server.
abstract interface class IJournal {
  /// Throws when the entry could not be stored.
  Future<void> append(JournalEntry entry);

  /// The newest [limit] entries, oldest first. Never throws for a missing or
  /// partly unreadable journal.
  Future<List<JournalEntry>> readRecent({int limit = 30});
}
