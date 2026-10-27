import '../../journal/domain/i_journal.dart';
import 'fix_loop.dart';

/// One open run: the loop, the server's journal and whatever must be closed
/// afterwards (the SSH session).
class FixSession {
  FixSession({required this.loop, required this.journal, required this._close});

  final FixLoop loop;
  final IJournal journal;
  final Future<void> Function() _close;

  Future<void> close() => _close();
}

/// Builds a [FixSession] from the saved settings. Throws `AppProblemError`
/// when the AI or the server is not configured, and SSH failures as they are.
/// Tests replace it, so the run controller never touches SSH directly.
abstract interface class FixSessionFactory {
  Future<FixSession> open();
}
