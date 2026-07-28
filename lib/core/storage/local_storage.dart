import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for everything the app needs to
/// persist locally: auth tokens, cached app-config, last picked city and
/// the configurable backend base URL (Settings screen).
class LocalStorage {
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kThemeMode = 'theme_mode_override';
  static const _kLastCity = 'last_picked_city';
  static const _kBaseUrl = 'backend_base_url';
  static const _kAppConfigCache = 'app_config_cache';
  static const _kSupportSessionId = 'support_session_id';

  final SharedPreferences _prefs;
  LocalStorage(this._prefs);

  static Future<LocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  // ---- Auth tokens ----
  Future<void> saveTokens(
      {required String access, required String refresh}) async {
    await _prefs.setString(_kAccessToken, access);
    await _prefs.setString(_kRefreshToken, refresh);
  }

  String? get accessToken => _prefs.getString(_kAccessToken);
  String? get refreshToken => _prefs.getString(_kRefreshToken);

  Future<void> clearTokens() async {
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
  }

  // ---- Theme override (user-picked in Settings; null = follow app-config) ----
  String? get themeModeOverride => _prefs.getString(_kThemeMode);
  Future<void> setThemeModeOverride(String? mode) async {
    if (mode == null) {
      await _prefs.remove(_kThemeMode);
    } else {
      await _prefs.setString(_kThemeMode, mode);
    }
  }

  // ---- Last manually-picked city (location fallback) ----
  String? get lastCity => _prefs.getString(_kLastCity);
  Future<void> setLastCity(String city) async =>
      _prefs.setString(_kLastCity, city);

  // ---- Backend base URL — hardcoded, not user-editable ----
  String get baseUrl => kDefaultBaseUrl;

  // ---- Cached app-config JSON (used before first network fetch completes) ----
  String? get cachedAppConfig => _prefs.getString(_kAppConfigCache);
  Future<void> setCachedAppConfig(String json) async =>
      _prefs.setString(_kAppConfigCache, json);

  // ---- Support chat session (so re-opening the screen resumes the same
  // conversation instead of starting a brand-new one each time) ----
  String? get supportSessionId => _prefs.getString(_kSupportSessionId);
  Future<void> setSupportSessionId(String id) async =>
      _prefs.setString(_kSupportSessionId, id);
  Future<void> clearSupportSessionId() async =>
      _prefs.remove(_kSupportSessionId);

  Future<void> clearAll() async {
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
    await _prefs.remove(_kAppConfigCache);
    await _prefs.remove(_kSupportSessionId);
    // last city / theme / base url intentionally survive a "clear cache".
  }
}

const kDefaultBaseUrl = 'https://eazydoctor.onrender.com';
