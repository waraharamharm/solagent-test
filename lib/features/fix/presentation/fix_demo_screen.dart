import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_problem.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/problem_text.dart';
import '../../../core/security/biometric_guard.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/cookie_shape.dart';
import '../../../core/ui/wavy_progress.dart';
import '../../server/application/server_providers.dart';
import '../../server/presentation/server_screen.dart';
import '../../ssh/domain/ssh_failure.dart';
import '../application/fix_loop.dart';
import '../application/fix_run_controller.dart';
import '../domain/command_policy.dart';
import '../domain/fix_models.dart';
import '../l10n/command_texts.dart';
import '../l10n/fix_texts.dart';

class FixDemoScreen extends StatelessWidget {
  const FixDemoScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const BiometricGuard(child: _FixDemoView());
}

class _FixDemoView extends ConsumerWidget {
  const _FixDemoView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(fixRunProvider);
    final run = ref.read(fixRunProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final host = ref.watch(serverControllerProvider).value?.profile?.host;
    final pending = s.pending;
    final error = s.error;
    final l10n = context.l10n;

    final (title, subtitle) = _headline(l10n, s);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.lg,
            AppSpace.xl,
            kDockClearance + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            if (host != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(Icons.dns_rounded, color: scheme.primary),
                  label: Text(host),
                ),
              ),
            const SizedBox(height: AppSpace.md),
            Text(title, style: theme.textTheme.displaySmall),
            const SizedBox(height: AppSpace.sm),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (s.running && pending == null) ...[
              const SizedBox(height: AppSpace.lg),
              const WavyProgress(),
            ],
            const SizedBox(height: AppSpace.lg),
            if (pending != null)
              _DecisionCard(
                proposal: pending,
                onDecide: (approve) => run.decide(approve: approve),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: s.running
                    ? OutlinedButton.icon(
                        onPressed: run.cancel,
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(l10n.fixDemoStop),
                      )
                    : FilledButton.icon(
                        onPressed: () => run.start(fixDemoScript()),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l10n.fixDemoStart),
                      ),
              ),
            if (error != null) ...[
              const SizedBox(height: AppSpace.lg),
              _Notice(
                icon: Icons.error_rounded,
                color: scheme.error,
                text: _errorText(l10n, error),
              ),
            ],
            if (s.steps.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xl),
              _Route(steps: s.steps, shownAbove: pending?.diagnosis),
            ],
            if (s.log.isNotEmpty) ...[
              const SizedBox(height: AppSpace.lg),
              _LogCard(lines: s.log),
            ],
          ],
        ),
      ),
    );
  }

  static (String, String) _headline(AppLocalizations l10n, FixRunState s) {
    if (s.pending != null) {
      return (l10n.commonDecisionNeeded, l10n.fixDemoProposalSubtitle);
    }
    if (s.running) {
      return (l10n.fixDemoWorkingTitle, s.status ?? l10n.fixDemoConnecting);
    }
    final r = s.result;
    if (r != null) {
      return switch (r.outcome) {
        FixOutcome.succeeded => (
          l10n.fixDemoDoneTitle,
          l10n.fixDemoDoneSubtitle,
        ),
        FixOutcome.declined => (
          l10n.fixDemoStoppedTitle,
          l10n.fixDemoDeclinedSubtitle,
        ),
        FixOutcome.cancelled => (
          l10n.fixDemoStoppedTitle,
          l10n.fixDemoCancelledSubtitle,
        ),
        FixOutcome.noFix => (
          l10n.fixDemoNotFixedTitle,
          l10n.fixDemoNoFixSubtitle(r.message ?? ''),
        ),
        FixOutcome.gaveUp => (
          l10n.fixDemoNotFixedTitle,
          l10n.fixDemoGaveUpSubtitle,
        ),
        FixOutcome.lost => (l10n.fixDemoLostTitle, l10n.fixDemoLostSubtitle),
        FixOutcome.error => (
          l10n.fixDemoErrorTitle,
          fixFinishedErrorText(l10n, r),
        ),
      };
    }
    return (
      l10n.commonSelfHealing,
      l10n.fixDemoIdleSubtitle('~/solagent-fixdemo/app.conf'),
    );
  }

  static String _errorText(AppLocalizations l10n, Object e) => switch (e) {
    SshHostKeyRejected() => l10n.fixDemoErrHostNotChecked,
    SshFailure() => serverErrorText(l10n, e),
    AppProblemError(:final problem) => appProblemText(l10n, problem),
    _ => l10n.fixDemoErrStartFailed('$e'),
  };
}

/// The AI's proposal: what broke in words, the exact command, what it will
/// change, and two explicit buttons. Nothing runs before "Выполнить".
class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.proposal, required this.onDecide});

  final FixProposal proposal;
  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    final l10n = context.l10n;
    final warnings = proposal.verdict?.warnings ?? const <CommandWarning>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CookieShape(size: 28, color: scheme.primary),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                proposal.diagnosis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppSpace.md),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    proposal.command ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (proposal.explanation.isNotEmpty)
                _Effect(
                  icon: Icons.info_outline_rounded,
                  color: scheme.onSurfaceVariant,
                  text: proposal.explanation,
                ),
              for (final w in warnings)
                _Effect(
                  icon: Icons.warning_rounded,
                  color: status.warn,
                  text: commandWarningText(l10n, w),
                ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 52),
                      ),
                      onPressed: () => onDecide(false),
                      child: Text(context.l10n.fixDemoDecline),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 52),
                      ),
                      onPressed: () => onDecide(true),
                      child: Text(context.l10n.fixDemoApprove),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Effect extends StatelessWidget {
  const _Effect({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Text(text, style: TextStyle(color: color, height: 1.35)),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color),
      const SizedBox(width: AppSpace.md),
      Expanded(
        child: Text(text, style: TextStyle(color: color)),
      ),
    ],
  );
}

/// The run as a route: settled steps as filled or failed stops joined by a
/// line, the live one as the turning cookie.
class _Route extends StatelessWidget {
  const _Route({required this.steps, this.shownAbove});

  final List<FixStep> steps;

  /// Text already on screen in the decision card; not repeated in a step.
  final String? shownAbove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      _marker(steps[i].state, scheme, status),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 3,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: steps[i].state == FixStepState.done
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (steps[i].detail case final d? when d != shownAbove)
                          Text(
                            d,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: steps[i].state == FixStepState.failed
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _marker(FixStepState s, ColorScheme scheme, StatusColors status) {
    Widget dot(Color bg, IconData icon, Color fg) => Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: fg),
    );
    return switch (s) {
      FixStepState.done => dot(
        scheme.primary,
        Icons.check_rounded,
        scheme.onPrimary,
      ),
      FixStepState.failed => dot(
        scheme.error,
        Icons.close_rounded,
        scheme.onError,
      ),
      FixStepState.running => CookieShape(
        size: 36,
        color: scheme.primary,
        spinning: true,
      ),
      FixStepState.waiting => CookieShape(
        size: 36,
        color: status.warn,
        child: Icon(
          Icons.priority_high_rounded,
          size: 18,
          color: scheme.surface,
        ),
      ),
    };
  }
}

class _LogCard extends StatefulWidget {
  const _LogCard({required this.lines});

  final List<String> lines;

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = widget.lines;
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.5,
      color: scheme.onSurfaceVariant,
    );
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.xs,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.fixDemoLogTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _open = !_open),
                child: Text(
                  _open
                      ? context.l10n.fixDemoLogCollapse
                      : context.l10n.fixDemoLogShowAll,
                ),
              ),
            ],
          ),
          if (_open)
            SizedBox(
              height: 320,
              child: ListView.builder(
                reverse: true,
                itemCount: lines.length,
                itemBuilder: (context, i) =>
                    _line(lines[lines.length - 1 - i], style, scheme),
              ),
            )
          else
            Text(
              _tail(lines),
              style: style,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  /// Lines like `── Запуск скрипта ──` that the controller puts between jobs.
  static String? _marker(String line) =>
      line.startsWith('── ') && line.endsWith(' ──') && line.length > 6
      ? line.substring(3, line.length - 3)
      : null;

  static String _tail(List<String> lines) {
    final output = [
      for (final l in lines)
        if (_marker(l) == null) l,
    ];
    return output.skip(output.length > 4 ? output.length - 4 : 0).join('\n');
  }

  static Widget _line(String line, TextStyle style, ColorScheme scheme) {
    final marker = _marker(line);
    if (marker == null) return Text(line, style: style);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.xs),
      child: Text(
        marker,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}
