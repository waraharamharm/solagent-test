import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/diagnostics.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/l10n.dart';
import '../../deploy/domain/deploy_models.dart';
import '../../journal/domain/i_journal.dart';
import '../../journal/domain/journal_entry.dart';
import '../../monitor/application/relay_setup.dart';
import '../../monitor/application/run_follower.dart';
import '../../monitor/data/foreground_run_notifier.dart';
import '../domain/fix_models.dart';
import '../l10n/command_texts.dart';
import 'fix_journal_events.dart';
import 'fix_loop.dart';
import 'fix_run_state.dart';
import 'fix_session.dart';
import 'ssh_fix_session_factory.dart';

part 'fix_run_controller.g.dart';

/// Runs [FixLoop] against the saved server and turns its events into what the
/// screens show. Opening the server is [FixSessionFactory]'s job.
@riverpod
class FixRun extends _$FixRun {
  static const _maxLogLines = 1000;
  static const _keep = Object();

  Completer<bool>? _decision;
  FixLoop? _loop;
  IJournal? _journal;
  IRunNotifier? _notifier;
  Future<void> _journalChain = Future.value();

  /// Read at the moment a message is produced, so it is in the language the
  /// user has now.
  AppLocalizations get _l10n => ref.read(appL10nProvider);

  @override
  FixRunState build() {
    ref.onDispose(() => _resolve(false));
    return const FixRunState();
  }

  Future<void> start(DeployScript script) async {
    if (state.running) return;
    final notifier = ref.read(runNotificationsProvider);
    _set(FixRunState(running: true, status: _l10n.fixStatusConnecting));
    FixSession? session;
    try {
      if (await notifier.start()) _notifier = notifier;
      final prelude = await ref.read(checkpointPreludeSourceProvider).create();
      final withMarkers = DeployScript(
        jobId: script.jobId,
        body: '$prelude\n${script.body}',
      );
      session = await ref.read(fixSessionFactoryProvider).open();
      _journal = session.journal;
      final loop = _loop = session.loop;
      await for (final e in loop.run(withMarkers, confirm: _ask)) {
        if (!ref.mounted) return;
        _apply(e);
      }
    } catch (e) {
      _set(
        _copy(status: null, error: e, steps: _closeOpen(FixStepState.failed)),
      );
    } finally {
      _loop = null;
      await _journalChain;
      _journal = null;
      if (_notifier != null) await notifier.stop();
      _notifier = null;
      await session?.close();
      _set(_copy(running: false, pending: null));
    }
  }

  /// Answers the pending proposal. Only an explicit true runs the command.
  void decide({required bool approve}) {
    _record(
      fixDecisionEntry(
        approved: approve,
        proposal: state.pending,
        now: DateTime.now().toUtc(),
      ),
    );
    _set(
      _copy(
        pending: null,
        steps: _closeOpen(
          approve ? FixStepState.done : FixStepState.failed,
          detail: approve ? _l10n.fixDetailAllowed : _l10n.fixDetailDeclined,
        ),
      ),
    );
    _resolve(approve);
  }

  Future<void> cancel() async {
    final stopping = _loop?.cancel();
    _resolve(false);
    await stopping;
  }

  Future<bool> _ask(FixProposal proposal) {
    final c = _decision = Completer<bool>();
    _set(
      _copy(
        pending: proposal,
        status: _l10n.fixStatusWaitingDecision,
        steps: [
          ...state.steps,
          FixStep(_l10n.fixStepYourDecision, FixStepState.waiting),
        ],
      ),
    );
    return c.future;
  }

  void _resolve(bool value) {
    final c = _decision;
    _decision = null;
    if (c != null && !c.isCompleted) c.complete(value);
  }

  /// Appends to the server's journal, in order, without blocking the run. A
  /// failed write is dropped: the journal is a record, not a precondition.
  void _record(JournalEntry entry) {
    final journal = _journal;
    if (journal == null) return;
    _journalChain = _journalChain
        .then((_) => journal.append(entry))
        .catchError((Object e) => debugLogError('journal write', e));
  }

  void _apply(FixEvent e) {
    final entry = journalEntryFor(
      e,
      logTail: _lastLogLines,
      now: DateTime.now().toUtc(),
    );
    if (entry != null) _record(entry);

    switch (e) {
      case FixJobStarted(:final kind, :final round):
        final title = switch ((kind, round)) {
          (FixJobKind.deploy, 0) => _l10n.fixStepRunScript,
          (FixJobKind.deploy, _) => _l10n.fixStepRerun(round),
          (FixJobKind.fix, _) => _l10n.fixStepFix(round),
        };
        _set(
          _copy(
            status: '$title…',
            log: [...state.log, '── $title ──'],
            steps: [
              ..._closeOpen(FixStepState.done),
              FixStep(title, FixStepState.running),
            ],
          ),
        );
      case FixLogLines(:final lines):
        _set(_copy(log: [...state.log, ...lines]));
      case FixJobEnded(:final progress):
        final code = progress.exitCode;
        _set(
          _copy(
            log: [
              ...state.log,
              code == null
                  ? '── ${progress.state.name} ──'
                  : _l10n.fixLogExitCode(code),
            ],
            steps: _closeOpen(
              code == 0 ? FixStepState.done : FixStepState.failed,
              detail: code == null
                  ? _l10n.fixDetailJobInterrupted
                  : code == 0
                  ? null
                  : _l10n.fixDetailJobFailedCode(code),
            ),
          ),
        );
      case FixDiagnosing(:final round):
        _set(
          _copy(
            status: _l10n.fixStatusDiagnosing(round),
            steps: [
              ...state.steps,
              FixStep(_l10n.fixStepDiagnosing, FixStepState.running),
            ],
          ),
        );
      case FixProposed(:final proposal):
        final blocked = !proposal.canRun && proposal.command != null;
        final reason = proposal.verdict?.blockedReason;
        _set(
          _copy(
            log: blocked
                ? [
                    ...state.log,
                    _l10n.fixLogBlockedCommand(
                      reason == null ? '' : blockReasonText(_l10n, reason),
                    ),
                  ]
                : null,
            steps: _closeOpen(
              blocked ? FixStepState.failed : FixStepState.done,
              detail: blocked
                  ? _l10n.fixDetailCommandForbidden
                  : proposal.diagnosis,
            ),
          ),
        );
      case FixFinished(:final outcome):
        _set(
          _copy(
            status: null,
            result: e,
            steps: _closeOpen(
              outcome == FixOutcome.succeeded
                  ? FixStepState.done
                  : FixStepState.failed,
            ),
          ),
        );
    }
  }

  String _lastLogLines(int count) {
    final lines = state.log.where((l) => !l.startsWith('── ')).toList();
    final tail = lines.length > count
        ? lines.sublist(lines.length - count)
        : lines;
    return tail.join('\n');
  }

  /// Settles the last step if it is still running or waiting.
  List<FixStep> _closeOpen(FixStepState to, {String? detail}) {
    final steps = state.steps;
    if (steps.isEmpty) return steps;
    final last = steps.last;
    if (last.state != FixStepState.running &&
        last.state != FixStepState.waiting) {
      return steps;
    }
    return [...steps.sublist(0, steps.length - 1), last.to(to, detail: detail)];
  }

  FixRunState _copy({
    bool? running,
    List<String>? log,
    List<FixStep>? steps,
    Object? status = _keep,
    Object? pending = _keep,
    FixFinished? result,
    Object? error,
  }) {
    final s = state;
    final lines = log ?? s.log;
    return FixRunState(
      running: running ?? s.running,
      log: lines.length > _maxLogLines
          ? lines.sublist(lines.length - _maxLogLines)
          : lines,
      steps: steps ?? s.steps,
      status: identical(status, _keep) ? s.status : status as String?,
      pending: identical(pending, _keep) ? s.pending : pending as FixProposal?,
      result: result ?? s.result,
      error: error ?? s.error,
    );
  }

  void _set(FixRunState next) {
    if (!ref.mounted) return;
    final text = next.status;
    if (text != null && text != state.status) {
      unawaited(_notifier?.showText(text));
    }
    state = next;
  }
}
