import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_problem.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/l10n.dart';
import '../../deploy/data/deploy_engine.dart';
import '../../deploy/domain/deploy_models.dart';
import '../../journal/data/journal_store.dart';
import '../../journal/domain/journal_entry.dart';
import '../../llm/application/llm_providers.dart';
import '../../rag/application/rag_providers.dart';
import '../../rag/domain/rag_models.dart';
import '../../server/data/server_repository.dart';
import '../../server/domain/server_profile.dart';
import '../../ssh/data/dartssh2_connector.dart';
import '../../ssh/domain/i_ssh_client.dart';
import '../domain/fix_models.dart';
import '../domain/log_redactor.dart';
import '../l10n/command_texts.dart';
import 'fix_advisor.dart';
import 'fix_loop.dart';

part 'fix_run_controller.g.dart';

enum FixStepState { running, waiting, done, failed }

/// One visible stage of a run: a job on the server, the AI's diagnosis, or
/// the user's decision.
class FixStep {
  const FixStep(this.title, this.state, {this.detail});

  final String title;
  final FixStepState state;
  final String? detail;

  FixStep to(FixStepState state, {String? detail}) =>
      FixStep(title, state, detail: detail ?? this.detail);
}

class FixRunState {
  const FixRunState({
    this.running = false,
    this.log = const [],
    this.steps = const [],
    this.status,
    this.pending,
    this.result,
    this.error,
  });

  final bool running;
  final List<String> log;
  final List<FixStep> steps;
  final String? status;

  /// Waiting for the user's decision via [FixRun.decide].
  final FixProposal? pending;
  final FixFinished? result;

  /// Failure before or outside the loop (SSH, missing settings).
  final Object? error;
}

/// Script for trying the repair loop without a real deployment: it fails
/// until `~/solagent-fixdemo/app.conf` has a `port=` line, and removes that
/// directory once it passes, so the demo can be repeated.
DeployScript fixDemoScript() => DeployScript(
  jobId: 'fixdemo-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
  body: r'''
set -e
echo "Checking the config"
grep -q '^port=' "$HOME/solagent-fixdemo/app.conf"
echo "Config is fine, demo passed"
rm -rf "$HOME/solagent-fixdemo"
''',
);

/// Runs [FixLoop] against the saved server. The host key must already be
/// pinned (done on the server screen); a new key is refused here.
@riverpod
class FixRun extends _$FixRun {
  static const _maxLogLines = 1000;

  Completer<bool>? _decision;
  FixLoop? _loop;
  JournalStore? _journal;
  Future<void> _journalChain = Future.value();

  /// Read at the moment a message is produced, so it is in the language the
  /// user has now.
  AppLocalizations get _l10n => ref.read(appL10nProvider);

  /// English name of the language the AI answers in. Add a case with each new
  /// app language; unknown codes fall back to English like the UI does.
  static String _aiLanguage(String code) => switch (code) {
    'ru' => 'Russian',
    _ => 'English',
  };

  @override
  FixRunState build() {
    ref.onDispose(() => _resolve(false));
    return const FixRunState();
  }

  Future<void> start(DeployScript script) async {
    if (state.running) return;
    _set(FixRunState(running: true, status: _l10n.fixStatusConnecting));
    ISshSession? session;
    try {
      final llm = await ref.read(llmServiceProvider.future);
      if (llm == null) throw const AppProblemError(AppProblem.aiNotConfigured);
      final repo = ref.read(serverRepositoryProvider);
      final target = await repo.loadTarget();
      final credential = await repo.loadCredential();
      if (target == null || credential == null) {
        throw const AppProblemError(AppProblem.serverNotConfigured);
      }
      session = await ref
          .read(sshConnectorProvider)
          .connect(target, credential, confirmNewHostKey: (_) async => false);
      final probe = await session.run(ServerInfo.probeCommand);
      final server = ServerInfo.parse(probe.stdout, fingerprint: '');
      if (!probe.succeeded || server == null) {
        throw const AppProblemError(AppProblem.serverOsUnknown);
      }

      final redactor = LogRedactor(host: target.host, user: target.username);
      final journal = _journal = JournalStore(session, redactor);
      final history = await _readHistory(journal);
      final rag = await _ragOrNull();

      final loop = _loop = FixLoop(
        engine: DeployEngine(session),
        advisor: FixAdvisor(
          llm,
          redactor,
          language: _aiLanguage(ref.read(appLocaleProvider).languageCode),
          rag: rag,
        ),
        server: server,
        history: history,
      );
      await for (final e in loop.run(script, confirm: _ask)) {
        if (!ref.mounted) return;
        _apply(e);
      }
    } catch (e) {
      if (ref.mounted) {
        _set(
          _copy(status: null, error: e, steps: _closeOpen(FixStepState.failed)),
        );
      }
    } finally {
      _loop = null;
      await _journalChain;
      _journal = null;
      await session?.close();
      if (ref.mounted) _set(_copy(running: false, pending: null));
    }
  }

  /// Answers the pending proposal. Only an explicit true runs the command.
  void decide({required bool approve}) {
    _log(
      JournalKind.fixDecision,
      approve ? 'User approved the fix' : 'User declined the fix',
      detail: 'command: ${state.pending?.command}',
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

  /// Earlier actions on this server. A missing or unreadable journal must not
  /// stop a run, so any failure means "no history".
  Future<List<JournalEntry>> _readHistory(JournalStore journal) async {
    try {
      return await journal.readRecent();
    } catch (_) {
      return const [];
    }
  }

  Future<IRagService?> _ragOrNull() async {
    try {
      return await ref.read(ragServiceProvider.future);
    } catch (_) {
      return null;
    }
  }

  /// Appends to the server's journal, in order, without blocking the run. A
  /// failed write is dropped: the journal is a record, not a precondition.
  void _log(JournalKind kind, String summary, {String? jobId, String? detail}) {
    final store = _journal;
    if (store == null) return;
    final entry = JournalEntry(
      time: DateTime.now().toUtc(),
      kind: kind,
      jobId: jobId,
      summary: summary,
      detail: detail,
    );
    _journalChain = _journalChain
        .then((_) => store.append(entry))
        .catchError((Object _) {});
  }

  String _lastLogLines(int count) {
    final lines = state.log.where((l) => !l.startsWith('── ')).toList();
    final tail = lines.length > count
        ? lines.sublist(lines.length - count)
        : lines;
    return tail.join('\n');
  }

  void _resolve(bool value) {
    final c = _decision;
    _decision = null;
    if (c != null && !c.isCompleted) c.complete(value);
  }

  void _apply(FixEvent e) {
    switch (e) {
      case FixJobStarted(:final jobId, :final kind, :final round):
        _log(
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
      case FixJobEnded(:final jobId, :final kind, :final progress):
        final code = progress.exitCode;
        _log(
          kind == FixJobKind.deploy
              ? JournalKind.deployFinished
              : JournalKind.fixFinished,
          code == null ? 'Ended: ${progress.state.name}' : 'Exit code $code',
          jobId: jobId,
          detail: code == 0 ? null : _lastLogLines(12),
        );
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
        _log(
          JournalKind.fixProposed,
          proposal.diagnosis,
          detail: proposal.command == null
              ? 'no command proposed'
              : 'command: ${proposal.command}'
                    '${blocked ? ' (blocked by the safety policy, not offered)' : ''}',
        );
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
      case FixFinished(:final outcome, :final message):
        _log(
          JournalKind.runFinished,
          'Run ended: ${outcome.name}',
          detail: message,
        );
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
    if (ref.mounted) state = next;
  }

  static const _keep = Object();
}
