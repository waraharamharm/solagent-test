import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_problem.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/problem_text.dart';
import '../../../core/security/biometric_guard.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/wavy_progress.dart';
import '../../server/application/server_providers.dart';
import '../../server/l10n/server_texts.dart';
import '../../ssh/domain/ssh_failure.dart';
import '../application/fix_loop.dart';
import '../application/fix_run_controller.dart';
import '../application/fix_run_state.dart';
import '../domain/fix_demo_script.dart';
import '../l10n/fix_texts.dart';
import 'widgets/decision_card.dart';
import 'widgets/log_card.dart';
import 'widgets/run_route.dart';

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
              DecisionCard(
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
              FixNotice(
                icon: Icons.error_rounded,
                color: scheme.error,
                text: _errorText(l10n, error),
              ),
            ],
            if (s.steps.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xl),
              RunRoute(steps: s.steps, shownAbove: pending?.diagnosis),
            ],
            if (s.log.isNotEmpty) ...[
              const SizedBox(height: AppSpace.lg),
              LogCard(lines: s.log),
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
