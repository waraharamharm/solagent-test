// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_setup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkpointPreludeSource)
final checkpointPreludeSourceProvider = CheckpointPreludeSourceProvider._();

final class CheckpointPreludeSourceProvider
    extends
        $FunctionalProvider<
          CheckpointPreludeSource,
          CheckpointPreludeSource,
          CheckpointPreludeSource
        >
    with $Provider<CheckpointPreludeSource> {
  CheckpointPreludeSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkpointPreludeSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkpointPreludeSourceHash();

  @$internal
  @override
  $ProviderElement<CheckpointPreludeSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckpointPreludeSource create(Ref ref) {
    return checkpointPreludeSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckpointPreludeSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckpointPreludeSource>(value),
    );
  }
}

String _$checkpointPreludeSourceHash() =>
    r'0203e322bf2f28860d8dba23c42111da1d25aed4';
