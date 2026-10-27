// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fix_run_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs [FixLoop] against the saved server. The host key must already be
/// pinned (done on the server screen); a new key is refused here.

@ProviderFor(FixRun)
final fixRunProvider = FixRunProvider._();

/// Runs [FixLoop] against the saved server. The host key must already be
/// pinned (done on the server screen); a new key is refused here.
final class FixRunProvider extends $NotifierProvider<FixRun, FixRunState> {
  /// Runs [FixLoop] against the saved server. The host key must already be
  /// pinned (done on the server screen); a new key is refused here.
  FixRunProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fixRunProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fixRunHash();

  @$internal
  @override
  FixRun create() => FixRun();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FixRunState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FixRunState>(value),
    );
  }
}

String _$fixRunHash() => r'ebe854fc3be4aaa5b860663fa27d4a83fa252ae0';

/// Runs [FixLoop] against the saved server. The host key must already be
/// pinned (done on the server screen); a new key is refused here.

abstract class _$FixRun extends $Notifier<FixRunState> {
  FixRunState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FixRunState, FixRunState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FixRunState, FixRunState>,
              FixRunState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
