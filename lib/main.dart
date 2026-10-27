import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/l10n/app_locale.dart';
import 'core/l10n/l10n.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';

void main() {
  runApp(const ProviderScope(child: SolAgentApp()));
}

class SolAgentApp extends ConsumerWidget {
  const SolAgentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(
      builder: (light, dark) => MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        locale: ref.watch(appLocaleProvider),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: ref.watch(routerProvider),
        themeMode: ref.watch(appThemeModeProvider),
        theme: AppTheme.build(Brightness.light, seed: light?.primary),
        darkTheme: AppTheme.build(Brightness.dark, seed: dark?.primary),
      ),
    );
  }
}
