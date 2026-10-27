// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(biometricGate)
final biometricGateProvider = BiometricGateProvider._();

final class BiometricGateProvider
    extends $FunctionalProvider<IBiometricGate, IBiometricGate, IBiometricGate>
    with $Provider<IBiometricGate> {
  BiometricGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricGateHash();

  @$internal
  @override
  $ProviderElement<IBiometricGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IBiometricGate create(Ref ref) {
    return biometricGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBiometricGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBiometricGate>(value),
    );
  }
}

String _$biometricGateHash() => r'658e7f7b75d2b7eb5f3d3c2edcd90cbb9b0f392a';
