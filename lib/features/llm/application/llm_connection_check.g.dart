// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_connection_check.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State: null = not run yet, data = trimmed model reply.

@ProviderFor(LlmConnectionCheck)
final llmConnectionCheckProvider = LlmConnectionCheckProvider._();

/// State: null = not run yet, data = trimmed model reply.
final class LlmConnectionCheckProvider
    extends $NotifierProvider<LlmConnectionCheck, AsyncValue<String?>> {
  /// State: null = not run yet, data = trimmed model reply.
  LlmConnectionCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'llmConnectionCheckProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$llmConnectionCheckHash();

  @$internal
  @override
  LlmConnectionCheck create() => LlmConnectionCheck();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<String?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<String?>>(value),
    );
  }
}

String _$llmConnectionCheckHash() =>
    r'b3435a7a79f171aed33b878a4c65735f52a43374';

/// State: null = not run yet, data = trimmed model reply.

abstract class _$LlmConnectionCheck extends $Notifier<AsyncValue<String?>> {
  AsyncValue<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, AsyncValue<String?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, AsyncValue<String?>>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
