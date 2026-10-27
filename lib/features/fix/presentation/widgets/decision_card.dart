import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/cookie_shape.dart';
import '../../domain/command_policy.dart';
import '../../domain/fix_models.dart';
import '../../l10n/command_texts.dart';

/// The AI's proposal: what broke in words, the exact command, what it will
/// change, and two explicit buttons. Nothing runs before "Выполнить".
class DecisionCard extends StatelessWidget {
  const DecisionCard({
    super.key,
    required this.proposal,
    required this.onDecide,
  });

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

class FixNotice extends StatelessWidget {
  const FixNotice({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

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
