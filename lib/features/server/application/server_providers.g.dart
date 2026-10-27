// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServerController)
final serverControllerProvider = ServerControllerProvider._();

final class ServerControllerProvider
    extends $AsyncNotifierProvider<ServerController, ServerState> {
  ServerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverControllerHash();

  @$internal
  @override
  ServerController create() => ServerController();
}

String _$serverControllerHash() => r'dfec926cc28346e3c2f4809b1f97711c8de2bf36';

abstract class _$ServerController extends $AsyncNotifier<ServerState> {
  FutureOr<ServerState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ServerState>, ServerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ServerState>, ServerState>,
              AsyncValue<ServerState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Connects with the saved credentials, reads OS facts, disconnects.
/// A first-seen host key is passed to [ConfirmNewHostKey]; nothing is pinned
/// unless that returns true and the login then succeeds.

@ProviderFor(ServerCheck)
final serverCheckProvider = ServerCheckProvider._();

/// Connects with the saved credentials, reads OS facts, disconnects.
/// A first-seen host key is passed to [ConfirmNewHostKey]; nothing is pinned
/// unless that returns true and the login then succeeds.
final class ServerCheckProvider
    extends $AsyncNotifierProvider<ServerCheck, ServerInfo?> {
  /// Connects with the saved credentials, reads OS facts, disconnects.
  /// A first-seen host key is passed to [ConfirmNewHostKey]; nothing is pinned
  /// unless that returns true and the login then succeeds.
  ServerCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverCheckProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverCheckHash();

  @$internal
  @override
  ServerCheck create() => ServerCheck();
}

String _$serverCheckHash() => r'be24eb5d6393c0b55051ab4fb50c027a679e71bf';

/// Connects with the saved credentials, reads OS facts, disconnects.
/// A first-seen host key is passed to [ConfirmNewHostKey]; nothing is pinned
/// unless that returns true and the login then succeeds.

abstract class _$ServerCheck extends $AsyncNotifier<ServerInfo?> {
  FutureOr<ServerInfo?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ServerInfo?>, ServerInfo?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ServerInfo?>, ServerInfo?>,
              AsyncValue<ServerInfo?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
