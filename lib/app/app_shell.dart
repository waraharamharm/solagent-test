import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/fix/application/fix_run_controller.dart';

/// Tabs plus a floating frosted dock: four destinations in a pill and a
/// separate round button for the job that may be waiting on the user.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static List<(IconData, IconData, String)> _tabs(AppLocalizations l10n) => [
    (
      Icons.space_dashboard_outlined,
      Icons.space_dashboard,
      l10n.shellTabOverview,
    ),
    (Icons.rocket_launch_outlined, Icons.rocket_launch, l10n.shellTabDeploy),
    (Icons.dns_outlined, Icons.dns, l10n.commonServer),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, l10n.commonAi),
  ];

  static const deployTab = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Stack(
      children: [
        shell,
        if (!keyboard)
          Positioned(
            left: AppSpace.lg,
            right: AppSpace.lg,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 20,
            child: Row(
              children: [
                Expanded(child: _pill(context)),
                const SizedBox(width: 10),
                _JobButton(onTap: () => _go(deployTab)),
              ],
            ),
          ),
      ],
    );
  }

  void _go(int i) =>
      shell.goBranch(i, initialLocation: i == shell.currentIndex);

  Widget _pill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = _tabs(context.l10n);
    return _Glass(
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _Tab(
                icon: tabs[i].$1,
                selectedIcon: tabs[i].$2,
                label: tabs[i].$3,
                selected: i == shell.currentIndex,
                onTap: () => _go(i),
                scheme: scheme,
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          width: selected ? 68 : 56,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            selected ? selectedIcon : icon,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    ),
  );
}

class _JobButton extends ConsumerWidget {
  const _JobButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(fixRunProvider);
    final scheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final waiting = run.pending != null;
    final l10n = context.l10n;
    final (icon, bg, fg, label) = waiting
        ? (
            Icons.gavel_rounded,
            status.warnContainer,
            status.onWarnContainer,
            l10n.commonDecisionNeeded,
          )
        : run.running
        ? (
            Icons.sync_rounded,
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
            l10n.commonWorking,
          )
        : (
            Icons.play_arrow_rounded,
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
            l10n.shellJobRun,
          );
    return Tooltip(
      message: label,
      child: _Glass(
        tint: bg,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: fg, size: 28),
                if (waiting)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: scheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted material of the dock.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.tint});

  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(32);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color:
                tint ??
                scheme.surfaceContainerHigh.withValues(
                  alpha: dark ? 0.78 : 0.74,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
