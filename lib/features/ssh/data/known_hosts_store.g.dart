// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'known_hosts_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(knownHostsStore)
final knownHostsStoreProvider = KnownHostsStoreProvider._();

final class KnownHostsStoreProvider
    extends
        $FunctionalProvider<KnownHostsStore, KnownHostsStore, KnownHostsStore>
    with $Provider<KnownHostsStore> {
  KnownHostsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knownHostsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knownHostsStoreHash();

  @$internal
  @override
  $ProviderElement<KnownHostsStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KnownHostsStore create(Ref ref) {
    return knownHostsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KnownHostsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KnownHostsStore>(value),
    );
  }
}

String _$knownHostsStoreHash() => r'7ef310ce63505aa4a79c7a5d77dd5f18ae500db5';
