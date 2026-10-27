// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_locale.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The language the user picked by hand, or null to follow the device.
/// Kept on the device.

@ProviderFor(LanguagePreference)
final languagePreferenceProvider = LanguagePreferenceProvider._();

/// The language the user picked by hand, or null to follow the device.
/// Kept on the device.
final class LanguagePreferenceProvider
    extends $NotifierProvider<LanguagePreference, String?> {
  /// The language the user picked by hand, or null to follow the device.
  /// Kept on the device.
  LanguagePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languagePreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languagePreferenceHash();

  @$internal
  @override
  LanguagePreference create() => LanguagePreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$languagePreferenceHash() =>
    r'b7ae5f4e937dae6989d335c8fd044fdd5dc57b30';

/// The language the user picked by hand, or null to follow the device.
/// Kept on the device.

abstract class _$LanguagePreference extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The language the app shows: the manual choice if there is one, otherwise
/// the device language list (re-read when the user changes it in system
/// settings).

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

/// The language the app shows: the manual choice if there is one, otherwise
/// the device language list (re-read when the user changes it in system
/// settings).
final class AppLocaleProvider extends $NotifierProvider<AppLocale, Locale> {
  /// The language the app shows: the manual choice if there is one, otherwise
  /// the device language list (re-read when the user changes it in system
  /// settings).
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  AppLocale create() => AppLocale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$appLocaleHash() => r'ebd2eede1af0b616d2ef21d48a932c7acb351d91';

/// The language the app shows: the manual choice if there is one, otherwise
/// the device language list (re-read when the user changes it in system
/// settings).

abstract class _$AppLocale extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Strings for code that has no BuildContext (controllers, services).
/// Widgets use `context.l10n`.

@ProviderFor(appL10n)
final appL10nProvider = AppL10nProvider._();

/// Strings for code that has no BuildContext (controllers, services).
/// Widgets use `context.l10n`.

final class AppL10nProvider
    extends
        $FunctionalProvider<
          AppLocalizations,
          AppLocalizations,
          AppLocalizations
        >
    with $Provider<AppLocalizations> {
  /// Strings for code that has no BuildContext (controllers, services).
  /// Widgets use `context.l10n`.
  AppL10nProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appL10nProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appL10nHash();

  @$internal
  @override
  $ProviderElement<AppLocalizations> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLocalizations create(Ref ref) {
    return appL10n(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLocalizations value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLocalizations>(value),
    );
  }
}

String _$appL10nHash() => r'da8278856a0c2fca3002e54fad2ede08c9444b99';
