import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config_provider.dart';
import '../core_providers.dart';
import 'app_theme.dart';

class ThemeModeNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(localStorageProvider).themeModeOverride;

  Future<void> setOverride(String? mode) async {
    await ref.read(localStorageProvider).setThemeModeOverride(mode);
    state = mode;
  }
}

/// null means "follow the superadmin-configured theme_mode from app-config".
final themeModeOverrideProvider = NotifierProvider<ThemeModeNotifier, String?>(ThemeModeNotifier.new);

final effectiveThemeProvider = Provider<ThemeData>((ref) {
  final config = ref.watch(appConfigProvider).valueOrNull;
  final override = ref.watch(themeModeOverrideProvider);
  final mode = override ?? config?.themeMode ?? 'light';
  return buildAppTheme(
    isDark: mode == 'dark',
    primaryHex: config?.primaryColor ?? '#0f766e',
    secondaryHex: config?.secondaryColor ?? '#d97706',
  );
});
