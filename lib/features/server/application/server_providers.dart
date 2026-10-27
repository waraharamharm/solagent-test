import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_problem.dart';
import '../../ssh/data/dartssh2_connector.dart';
import '../../ssh/data/known_hosts_store.dart';
import '../../ssh/domain/ssh_target.dart';
import '../data/server_repository.dart';
import '../domain/server_profile.dart';

part 'server_providers.g.dart';

class ServerState {
  const ServerState({this.profile, this.hasSecret = false});

  final ServerProfile? profile;
  final bool hasSecret;

  bool get isConfigured => profile != null && hasSecret;
}

@riverpod
class ServerController extends _$ServerController {
  @override
  Future<ServerState> build() => _read();

  Future<ServerState> _read() async {
    final repo = ref.read(serverRepositoryProvider);
    return ServerState(
      profile: await repo.load(),
      hasSecret: await repo.hasSecret(),
    );
  }

  Future<void> save(ServerProfile profile, String secret) async {
    await ref.read(serverRepositoryProvider).save(profile, secret);
    state = AsyncData(await _read());
  }

  Future<void> forget() async {
    await ref.read(serverRepositoryProvider).delete();
    state = AsyncData(await _read());
  }
}

/// Connects with the saved credentials, reads OS facts, disconnects.
/// A first-seen host key is passed to [ConfirmNewHostKey]; nothing is pinned
/// unless that returns true and the login then succeeds.
@riverpod
class ServerCheck extends _$ServerCheck {
  @override
  FutureOr<ServerInfo?> build() => null;

  Future<void> run(ConfirmNewHostKey confirm) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(serverRepositoryProvider);
      final target = await repo.loadTarget();
      final credential = await repo.loadCredential();
      if (target == null || credential == null) {
        throw const AppProblemError(AppProblem.serverNotConfigured);
      }
      final session = await ref
          .read(sshConnectorProvider)
          .connect(target, credential, confirmNewHostKey: confirm);
      try {
        final result = await session.run(ServerInfo.probeCommand);
        final pinned = await ref
            .read(knownHostsStoreProvider)
            .find(target.hostId);
        final info = ServerInfo.parse(
          result.stdout,
          fingerprint: pinned?.fingerprint ?? '',
        );
        if (!result.succeeded || info == null) {
          throw const AppProblemError(AppProblem.serverOsUnknown);
        }
        return info;
      } finally {
        await session.close();
      }
    });
  }
}
