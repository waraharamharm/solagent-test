// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foreground_run_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(runNotifications)
final runNotificationsProvider = RunNotificationsProvider._();

final class RunNotificationsProvider
    extends $FunctionalProvider<IRunNotifier, IRunNotifier, IRunNotifier>
    with $Provider<IRunNotifier> {
  RunNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runNotificationsHash();

  @$internal
  @override
  $ProviderElement<IRunNotifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IRunNotifier create(Ref ref) {
    return runNotifications(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IRunNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IRunNotifier>(value),
    );
  }
}

String _$runNotificationsHash() => r'b60e12bf63c84fe2ec492e5b24dba05e88bf0755';
