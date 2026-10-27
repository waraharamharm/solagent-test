import '../../deploy/data/deploy_engine.dart';
import '../../deploy/domain/deploy_models.dart';
import '../../journal/domain/journal_entry.dart';
import '../../llm/domain/llm_failure.dart';
import '../../server/domain/server_profile.dart';
import '../../ssh/domain/ssh_failure.dart';
import '../domain/fix_models.dart';
import 'fix_advisor.dart';

/// Shows [proposal] to the user. Only true runs the command.
typedef ConfirmFix = Future<bool> Function(FixProposal proposal);

enum FixJobKind { deploy, fix }

sealed class FixEvent {
  const FixEvent();
}

final class FixJobStarted extends FixEvent {
  const FixJobStarted(this.jobId, this.kind, this.round);

  final String jobId;
  final FixJobKind kind;

  /// 0 for the first deploy run, then 1..maxRounds.
  final int round;
}

final class FixLogLines extends FixEvent {
  const FixLogLines(this.jobId, this.lines);

  final String jobId;
  final List<String> lines;
}

final class FixJobEnded extends FixEvent {
  const FixJobEnded(this.jobId, this.kind, this.progress);

  final String jobId;
  final FixJobKind kind;
  final DeployProgress progress;
}

final class FixDiagnosing extends FixEvent {
  const FixDiagnosing(this.round);

  final int round;
}

/// Emitted for every proposal, runnable or not, before asking the user.
final class FixProposed extends FixEvent {
  const FixProposed(this.round, this.proposal);

  final int round;
  final FixProposal proposal;
}

enum FixOutcome {
  /// The deploy script finished with exit code 0.
  succeeded,

  /// The user declined the proposed command.
  declined,

  /// The AI could not suggest a safe command.
  noFix,

  /// [FixLoop.maxRounds] reached without success.
  gaveUp,

  /// Stopped by [FixLoop.cancel].
  cancelled,

  /// The job was lost or vanished on the server (reboot, OOM, cleanup).
  lost,

  /// SSH or AI error; see [FixFinished.message].
  error,
}

/// What kind of failure ended the run with [FixOutcome.error].
enum FixErrorKind { ai, aiFormat, connection, server }

final class FixFinished extends FixEvent {
  const FixFinished(this.outcome, [this.message])
    : errorKind = null,
      llmFailure = null;

  const FixFinished.error(
    FixErrorKind this.errorKind,
    String this.message, {
    this.llmFailure,
  }) : outcome = FixOutcome.error;

  final FixOutcome outcome;

  /// Technical detail, not translated: the AI's diagnosis for
  /// [FixOutcome.noFix], the underlying error text for [FixOutcome.error].
  /// The UI puts a localized sentence around it.
  final String? message;

  final FixErrorKind? errorKind;

  /// Set for [FixErrorKind.ai]; the UI describes it in the user's language.
  final LlmFailure? llmFailure;
}

/// Runs a deploy script and, while it fails, asks the AI for a fix, gets the
/// user's approval, runs the fix as its own job and re-runs the script.
///
/// Job ids: the script's id for the first run, `<id>-fN` for fix N and
/// `<id>-rN` for re-run N. Jobs are left on the server for inspection.
class FixLoop {
  FixLoop({
    required this._engine,
    required this._advisor,
    required this._server,
    this.maxRounds = 3,
    this.pollInterval = const Duration(seconds: 2),
    this.history = const [],
  });

  final DeployEngine _engine;
  final FixAdvisor _advisor;
  final ServerInfo _server;
  final int maxRounds;
  final Duration pollInterval;

  /// Earlier actions on this server, read from its journal before the run.
  final List<JournalEntry> history;

  static const _tailLines = 200;
  static const _maxBaseIdLength = 36;

  String? _currentJob;
  bool _cancelled = false;

  /// Stops the job that is running now and ends the loop.
  Future<void> cancel() async {
    _cancelled = true;
    final job = _currentJob;
    if (job != null) await _engine.cancel(job);
  }

  /// Single-use per instance. [script.jobId] must be at most 36 characters
  /// to leave room for suffixes, and must not exist on the server yet.
  Stream<FixEvent> run(
    DeployScript script, {
    required ConfirmFix confirm,
  }) async* {
    if (script.jobId.length > _maxBaseIdLength) {
      throw ArgumentError.value(script.jobId, 'jobId', 'at most 36 chars');
    }
    final attempts = <FixAttempt>[];
    try {
      var deployTail = <String>[];
      DeployProgress? deployEnd;
      await for (final e in _runJob(script, FixJobKind.deploy, 0, deployTail)) {
        yield e;
        if (e is FixJobEnded) deployEnd = e.progress;
      }

      for (var round = 1; ; round++) {
        final end = deployEnd!;
        if (_cancelled || end.state == DeployState.cancelled) {
          yield const FixFinished(FixOutcome.cancelled);
          return;
        }
        if (end.succeeded) {
          yield const FixFinished(FixOutcome.succeeded);
          return;
        }
        if (end.state != DeployState.finished) {
          yield const FixFinished(FixOutcome.lost);
          return;
        }
        if (round > maxRounds) {
          yield const FixFinished(FixOutcome.gaveUp);
          return;
        }

        yield FixDiagnosing(round);
        final proposal = await _advisor.propose(
          server: _server,
          scriptBody: script.body,
          exitCode: end.exitCode,
          logTail: deployTail,
          attempts: attempts,
          history: history,
        );
        yield FixProposed(round, proposal);
        final command = proposal.command;
        if (command == null) {
          yield FixFinished(FixOutcome.noFix, proposal.diagnosis);
          return;
        }
        if (!proposal.canRun) {
          attempts.add(
            FixAttempt(
              command: command,
              outcome:
                  'rejected by the app safety policy, not executed. '
                  'Propose a different approach.',
            ),
          );
          continue;
        }
        if (_cancelled) {
          yield const FixFinished(FixOutcome.cancelled);
          return;
        }
        final approved = await confirm(proposal);
        if (_cancelled) {
          yield const FixFinished(FixOutcome.cancelled);
          return;
        }
        if (!approved) {
          yield const FixFinished(FixOutcome.declined);
          return;
        }

        final fixTail = <String>[];
        DeployProgress? fixEnd;
        final fixScript = DeployScript(
          jobId: '${script.jobId}-f$round',
          body: 'set -e\n$command\n',
        );
        await for (final e in _runJob(
          fixScript,
          FixJobKind.fix,
          round,
          fixTail,
        )) {
          yield e;
          if (e is FixJobEnded) fixEnd = e.progress;
        }
        if (_cancelled || fixEnd!.state == DeployState.cancelled) {
          yield const FixFinished(FixOutcome.cancelled);
          return;
        }
        if (!fixEnd.succeeded) {
          attempts.add(
            FixAttempt(
              command: command,
              outcome: fixEnd.state == DeployState.finished
                  ? 'fix command failed with exit code ${fixEnd.exitCode}'
                  : 'fix command was interrupted (${fixEnd.state.name})',
              outputTail: fixTail,
            ),
          );
          continue;
        }
        attempts.add(
          FixAttempt(
            command: command,
            outcome: 'fix command succeeded, but the script still failed',
            outputTail: fixTail,
          ),
        );

        deployTail = <String>[];
        deployEnd = null;
        final rerun = DeployScript(
          jobId: '${script.jobId}-r$round',
          body: script.body,
        );
        await for (final e in _runJob(
          rerun,
          FixJobKind.deploy,
          round,
          deployTail,
        )) {
          yield e;
          if (e is FixJobEnded) deployEnd = e.progress;
        }
      }
    } on LlmFailure catch (e) {
      yield FixFinished.error(FixErrorKind.ai, e.message, llmFailure: e);
    } on FixAdvisorFailure catch (e) {
      yield FixFinished.error(FixErrorKind.aiFormat, e.message);
    } on SshFailure catch (e) {
      yield FixFinished.error(FixErrorKind.connection, e.message);
    } on DeployFailure catch (e) {
      yield FixFinished.error(FixErrorKind.server, e.message);
    } finally {
      _currentJob = null;
    }
  }

  Stream<FixEvent> _runJob(
    DeployScript script,
    FixJobKind kind,
    int round,
    List<String> tail,
  ) async* {
    _currentJob = script.jobId;
    await _engine.start(script);
    yield FixJobStarted(script.jobId, kind, round);
    var from = 0;
    while (true) {
      final p = await _engine.poll(script.jobId, fromLine: from);
      from = p.nextLine;
      if (p.newLines.isNotEmpty) {
        tail.addAll(p.newLines);
        if (tail.length > _tailLines) {
          tail.removeRange(0, tail.length - _tailLines);
        }
        yield FixLogLines(script.jobId, p.newLines);
      }
      if (p.isTerminal && p.newLines.length < DeployEngine.maxLinesPerPoll) {
        _currentJob = null;
        yield FixJobEnded(script.jobId, kind, p);
        return;
      }
      if (!p.isTerminal) await Future<void>.delayed(pollInterval);
    }
  }
}
