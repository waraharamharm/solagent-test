import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/cookie_shape.dart';
import '../../application/fix_run_state.dart';

/// The run as a route: settled steps as filled or failed stops joined by a
/// line, the live one as the turning cookie.
class RunRoute extends StatelessWidget {
  const RunRoute({super.key, required this.steps, this.shownAbove});

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
