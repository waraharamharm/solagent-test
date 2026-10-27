// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssh_fix_session_factory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fixSessionFactory)
final fixSessionFactoryProvider = FixSessionFactoryProvider._();

final class FixSessionFactoryProvider
    extends
        $FunctionalProvider<
          FixSessionFactory,
          FixSessionFactory,
          FixSessionFactory
        >
    with $Provider<FixSessionFactory> {
  FixSessionFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fixSessionFactoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fixSessionFactoryHash();

  @$internal
  @override
  $ProviderElement<FixSessionFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FixSessionFactory create(Ref ref) {
    return fixSessionFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FixSessionFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FixSessionFactory>(value),
    );
  }
}

String _$fixSessionFactoryHash() => r'f1aa244566f2462c3b1884d6690beff409d77090';
