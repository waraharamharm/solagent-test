import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_locale.dart';
import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import '../core/ui/cookie_shape.dart';
import '../core/ui/grouped_list.dart';
import '../core/ui/wavy_progress.dart';
import '../features/fix/application/fix_loop.dart';
import '../features/fix/application/fix_run_controller.dart';
import '../features/llm/application/llm_providers.dart';
import '../features/llm/presentation/llm_texts.dart';
import '../features/server/application/server_providers.dart';
import '../features/support/application/donate_providers.dart';
import 'router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final server = ref.watch(serverControllerProvider).value;
    final llm = ref.watch(llmSettingsControllerProvider).value;
    final os = ref.watch(serverCheckProvider).value;
    final run = ref.watch(fixRunProvider);
    final profile = server?.profile;
    final serverReady = server?.isConfigured ?? false;
    final llmReady = llm?.isComplete ?? false;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            kDockClearance + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            const PageTitle(
              'SolAgent',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_LanguageButton(), _ThemeButton()],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            _Hero(serverReady: serverReady, llmReady: llmReady, run: run),
            const SizedBox(height: AppSpace.lg),
            GroupedList(
              children: [
                GroupedTile(
                  leading: const TileIcon(Icons.dns_rounded),
                  title: l10n.commonServer,
                  subtitle: serverReady && profile != null
                      ? [
                          '${profile.username}@${profile.host}',
                          ?os?.prettyName,
                        ].join(' · ')
                      : l10n.homeServerNotConnected,
                  trailing: serverReady
                      ? StatusLabel(l10n.homeServerSaved, color: status.ok)
                      : null,
                  onTap: () => context.go(Routes.server),
                ),
                GroupedTile(
                  leading: const TileIcon(Icons.auto_awesome_rounded),
                  title: l10n.commonAi,
                  subtitle: llmReady
                      ? '${llmPresetLabel(l10n, llm!.preset)} · ${llm.model}'
                      : l10n.homeAiNoKey,
                  trailing: llmReady
                      ? StatusLabel(l10n.homeAiReady, color: status.ok)
                      : null,
                  onTap: () => context.go(Routes.ai),
                ),
                GroupedTile(
                  leading: run.pending != null
                      ? TileIcon(
                          Icons.rocket_launch_rounded,
                          background: status.warnContainer,
                          foreground: status.onWarnContainer,
                        )
                      : const TileIcon(Icons.rocket_launch_rounded),
                  title: l10n.commonSelfHealing,
                  subtitle: _runLine(l10n, run),
                  below: run.running && run.pending == null
                      ? WavyProgress(
                          color: scheme.primary,
                          trackColor: scheme.surfaceContainerHighest,
                        )
                      : null,
                  onTap: () => context.go(Routes.deploy),
                ),
              ],
            ),
            if (ref.watch(donateOptionsProvider).isNotEmpty) ...[
              const SizedBox(height: AppSpace.lg),
              GroupedList(
                children: [
                  GroupedTile(
                    leading: const TileIcon(Icons.favorite_rounded),
                    title: l10n.homeSupportTitle,
                    subtitle: l10n.homeSupportSubtitle,
                    onTap: () => context.push(Routes.support),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _runLine(AppLocalizations l10n, FixRunState run) {
    if (run.pending != null) return l10n.homeRunWaiting;
    if (run.running) return run.status ?? l10n.commonWorking;
    return switch (run.result?.outcome) {
      FixOutcome.succeeded => l10n.homeRunLastSucceeded,
      null => l10n.homeRunDemo,
      _ => l10n.homeRunLastFailed,
    };
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.serverReady,
    required this.llmReady,
    required this.run,
  });

  final bool serverReady;
  final bool llmReady;
  final FixRunState run;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    final pending = run.pending;
    final l10n = context.l10n;

    final (title, body, action, route, bg, fg, shape) = switch (()) {
      _ when pending != null => (
        l10n.commonDecisionNeeded,
        pending.diagnosis,
        l10n.homeHeroReviewCommand,
        Routes.deploy,
        status.warnContainer,
        status.onWarnContainer,
        status.warn.withValues(alpha: 0.28),
      ),
      _ when run.running => (
        l10n.commonWorking,
        run.status ?? l10n.homeHeroServerBusy,
        l10n.homeHeroOpen,
        Routes.deploy,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        scheme.primary.withValues(alpha: 0.22),
      ),
      _ when !serverReady => (
        l10n.homeHeroConnectServerTitle,
        l10n.homeHeroConnectServerBody,
        l10n.homeHeroAddServer,
        Routes.server,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        scheme.primary.withValues(alpha: 0.22),
      ),
      _ when !llmReady => (
        l10n.homeHeroConnectAiTitle,
        l10n.homeHeroConnectAiBody,
        l10n.homeHeroAddKey,
        Routes.ai,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        scheme.tertiary.withValues(alpha: 0.22),
      ),
      _ => (
        l10n.homeHeroAllSetTitle,
        l10n.homeHeroAllSetBody,
        l10n.homeHeroOpenDemo,
        Routes.deploy,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        scheme.secondary.withValues(alpha: 0.2),
      ),
    };

    return Material(
      color: bg,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -34,
            child: CookieShape(
              size: 168,
              color: shape,
              lobes: 12,
              depth: 0.07,
              spinning: run.running && pending == null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 64),
                  child: Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: fg,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: fg.withValues(alpha: 0.86),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: fg,
                    foregroundColor: bg,
                  ),
                  onPressed: () => context.go(route),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(action),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu value for "follow the device"; a null value would read as a dismissed menu.
const _auto = '';

class _LanguageButton extends ConsumerWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(languagePreferenceProvider);
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.homeLanguageTooltip,
      icon: const Icon(Icons.language_rounded),
      initialValue: chosen ?? _auto,
      onSelected: (code) => ref
          .read(languagePreferenceProvider.notifier)
          .set(code == _auto ? null : code),
      itemBuilder: (_) => [
        CheckedPopupMenuItem<String>(
          value: _auto,
          checked: chosen == null,
          child: Text(l10n.homeLanguageAuto),
        ),
        for (final l in AppLocalizations.supportedLocales)
          CheckedPopupMenuItem<String>(
            value: l.languageCode,
            checked: l.languageCode == chosen,
            child: Text(languageEndonyms[l.languageCode] ?? l.languageCode),
          ),
      ],
    );
  }
}

class _ThemeButton extends ConsumerWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    final l10n = context.l10n;
    return PopupMenuButton<ThemeMode>(
      tooltip: l10n.homeThemeTooltip,
      icon: const Icon(Icons.contrast_rounded),
      initialValue: mode,
      onSelected: ref.read(appThemeModeProvider.notifier).set,
      itemBuilder: (_) => [
        for (final (m, label) in [
          (ThemeMode.system, l10n.homeThemeSystem),
          (ThemeMode.light, l10n.homeThemeLight),
          (ThemeMode.dark, l10n.homeThemeDark),
        ])
          CheckedPopupMenuItem(
            value: m,
            checked: m == mode,
            child: Text(label),
          ),
      ],
    );
  }
}
