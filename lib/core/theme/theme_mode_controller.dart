import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../security/secure_store.dart';

part 'theme_mode_controller.g.dart';

/// Light, dark or follow the system; kept on the device.
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  static const _key = 'ui.theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final saved = await ref.read(secureStoreProvider).read(_key);
      final mode = ThemeMode.values.asNameMap()[saved];
      if (mode != null && ref.mounted) state = mode;
    } catch (_) {
      // A lost preference falls back to the system theme.
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      await ref.read(secureStoreProvider).write(_key, mode.name);
    } catch (_) {
      // Applied for this session even if it could not be stored.
    }
  }
}
