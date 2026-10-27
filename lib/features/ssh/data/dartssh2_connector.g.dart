// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dartssh2_connector.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sshConnector)
final sshConnectorProvider = SshConnectorProvider._();

final class SshConnectorProvider
    extends $FunctionalProvider<ISshConnector, ISshConnector, ISshConnector>
    with $Provider<ISshConnector> {
  SshConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshConnectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshConnectorHash();

  @$internal
  @override
  $ProviderElement<ISshConnector> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ISshConnector create(Ref ref) {
    return sshConnector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ISshConnector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ISshConnector>(value),
    );
  }
}

String _$sshConnectorHash() => r'462315720db61253a0336662f14522e73fe80ee6';
