import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// JWT and token persistence using SharedPreferences.
class TokenStorage {
  static const String _keyAccess = AppConstants.accessTokenKey;
  static const String _keyRefresh = AppConstants.refreshTokenKey;

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<void> setAccessToken(String? token) async {
    final prefs = await _prefs;
    if (token == null) {
      await prefs.remove(_keyAccess);
    } else {
      await prefs.setString(_keyAccess, token);
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAccess);
  }

  Future<void> setRefreshToken(String? token) async {
    final prefs = await _prefs;
    if (token == null) {
      await prefs.remove(_keyRefresh);
    } else {
      await prefs.setString(_keyRefresh, token);
    }
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyRefresh);
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
  }
}
