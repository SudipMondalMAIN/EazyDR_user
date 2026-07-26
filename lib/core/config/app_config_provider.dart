import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import 'app_config_model.dart';

/// Loads app-config from the backend at splash. Falls back to the last
/// cached copy (or a sane hardcoded default) if the network call fails,
/// so the app is never stuck on a blank splash just because config is
/// briefly unreachable — but force-update gating below only applies once
/// a *live* config has actually been fetched.
class AppConfigNotifier extends AsyncNotifier<AppConfig> {
  bool fetchedLive = false;

  @override
  Future<AppConfig> build() async {
    final storage = ref.read(localStorageProvider);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/api/v1/app-config');
      final config = AppConfig.fromJson(response.data as Map<String, dynamic>);
      fetchedLive = true;
      await storage.setCachedAppConfig(config.toCacheString());
      return config;
    } catch (_) {
      final cached = storage.cachedAppConfig;
      if (cached != null) {
        try {
          return AppConfig.fromCache(cached);
        } catch (_) {
          return AppConfig.fallback();
        }
      }
      return AppConfig.fallback();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final appConfigProvider = AsyncNotifierProvider<AppConfigNotifier, AppConfig>(AppConfigNotifier.new);
