import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/fix/presentation/fix_demo_screen.dart';
import '../features/llm/presentation/llm_settings_screen.dart';
import '../features/server/presentation/server_screen.dart';
import '../features/support/presentation/support_screen.dart';
import 'app_shell.dart';
import 'home_screen.dart';

part 'router.g.dart';

abstract final class Routes {
  static const home = '/';
  static const deploy = '/deploy';
  static const server = '/server';
  static const ai = '/ai';
  static const support = '/support';
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  GoRoute page(String path, GoRouterWidgetBuilder builder) =>
      GoRoute(path: path, builder: builder);

  final router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [page(Routes.home, (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [page(Routes.deploy, (_, _) => const FixDemoScreen())],
          ),
          StatefulShellBranch(
            routes: [page(Routes.server, (_, _) => const ServerScreen())],
          ),
          StatefulShellBranch(
            routes: [page(Routes.ai, (_, _) => const LlmSettingsScreen())],
          ),
        ],
      ),
      page(Routes.support, (_, _) => const SupportScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
