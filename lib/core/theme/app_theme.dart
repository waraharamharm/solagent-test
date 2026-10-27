import 'package:flutter/material.dart';

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const field = 16.0;
  static const card = 28.0;
  static const hero = 32.0;
}

/// Brand colour when the wallpaper gives none (Android < 12, tests).
const kSeedColor = Color(0xFF006A63);

/// Room the floating dock takes at the bottom of every tab.
const kDockClearance = 104.0;

/// State colours that Material roles do not cover: success and "waits for
/// you". Errors use [ColorScheme.error].
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.ok,
    required this.warn,
    required this.warnContainer,
    required this.onWarnContainer,
  });

  final Color ok;
  final Color warn;
  final Color warnContainer;
  final Color onWarnContainer;

  static const light = StatusColors(
    ok: Color(0xFF1E7A4C),
    warn: Color(0xFF8A5A00),
    warnContainer: Color(0xFFFFDEA6),
    onWarnContainer: Color(0xFF261900),
  );

  static const dark = StatusColors(
    ok: Color(0xFF6FD99B),
    warn: Color(0xFFF5BD52),
    warnContainer: Color(0xFF5C4200),
    onWarnContainer: Color(0xFFFFDEA6),
  );

  static StatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StatusColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  StatusColors copyWith({
    Color? ok,
    Color? warn,
    Color? warnContainer,
    Color? onWarnContainer,
  }) => StatusColors(
    ok: ok ?? this.ok,
    warn: warn ?? this.warn,
    warnContainer: warnContainer ?? this.warnContainer,
    onWarnContainer: onWarnContainer ?? this.onWarnContainer,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      ok: Color.lerp(ok, other.ok, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnContainer: Color.lerp(warnContainer, other.warnContainer, t)!,
      onWarnContainer: Color.lerp(onWarnContainer, other.onWarnContainer, t)!,
    );
  }
}

abstract final class AppTheme {
  /// [seed] is the wallpaper colour on Android 12+, else [kSeedColor].
  static ThemeData build(Brightness brightness, {Color? seed}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed ?? kSeedColor,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme;
    const pill = StadiumBorder();
    const buttonSize = Size(64, 48);
    const buttonText = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [
        brightness == Brightness.dark ? StatusColors.dark : StatusColors.light,
      ],
      textTheme: text.copyWith(
        displaySmall: text.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          height: 1.05,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          height: 1.1,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: pill,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: pill,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: buttonSize, shape: pill),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide.none,
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide.none,
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: EdgeInsets.fromLTRB(16, 0, 16, kDockClearance),
      ),
    );
  }
}
