import '../../journal/domain/journal_entry.dart';
import 'fix_loop.dart';
import '../domain/fix_models.dart';

/// How many log lines a failed job leaves in the journal.
const journalLogTailLines = 12;

/// What the server's journal should say about [event], or null when the
/// event is not worth recording (log lines, diagnosis progress).
///
/// [logTail] returns the last log lines of the current run; it is asked only
/// when a failed job ends. The text is English on purpose: the journal is read
/// back by the AI, not shown to the user.
JournalEntry? journalEntryFor(
  FixEvent event, {
  required String Function(int count) logTail,
  required DateTime now,
}) {
  JournalEntry entry(
    JournalKind kind,
    String summary, {
    String? jobId,
    String? detail,
  }) => JournalEntry(
    time: now,
    kind: kind,
    summary: summary,
    jobId: jobId,
    detail: detail,
  );

  switch (event) {
    case FixJobStarted(:final jobId, :final kind, :final round):
      return entry(
        kind == FixJobKind.deploy
            ? JournalKind.deployStarted
            : JournalKind.fixStarted,
        switch ((kind, round)) {
          (FixJobKind.deploy, 0) => 'Deploy script started',
          (FixJobKind.deploy, _) => 'Deploy script re-run $round',
          (FixJobKind.fix, _) => 'Fix command started (round $round)',
        },
        jobId: jobId,
      );
    case FixJobEnded(:final jobId, :final kind, :final progress):
      final code = progress.exitCode;
      return entry(
        kind == FixJobKind.deploy
            ? JournalKind.deployFinished
            : JournalKind.fixFinished,
        code == null ? 'Ended: ${progress.state.name}' : 'Exit code $code',
        jobId: jobId,
        detail: code == 0 ? null : logTail(journalLogTailLines),
      );
    case FixProposed(:final proposal):
      final blocked = !proposal.canRun && proposal.command != null;
      return entry(
        JournalKind.fixProposed,
        proposal.diagnosis,
        detail: proposal.command == null
            ? 'no command proposed'
            : 'command: ${proposal.command}'
                  '${blocked ? ' (blocked by the safety policy, not offered)' : ''}',
      );
    case FixFinished(:final outcome, :final message):
      return entry(
        JournalKind.runFinished,
        'Run ended: ${outcome.name}',
        detail: message,
      );
    case FixLogLines():
    case FixDiagnosing():
      return null;
  }
}

/// The user's answer to a proposed command.
JournalEntry fixDecisionEntry({
  required bool approved,
  required FixProposal? proposal,
  required DateTime now,
}) => JournalEntry(
  time: now,
  kind: JournalKind.fixDecision,
  summary: approved ? 'User approved the fix' : 'User declined the fix',
  detail: 'command: ${proposal?.command}',
);
