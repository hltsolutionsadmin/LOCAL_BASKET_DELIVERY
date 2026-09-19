import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Central place for the auth session tokens.
///
/// The backend issues a short-lived access token (`expiresIn` seconds, ~15 min)
/// together with a long-lived refresh token (~30 days). We persist the access
/// token, the refresh token and the moment the access token stops being valid,
/// so the network layer can silently swap an expired access token for a fresh
/// one using the refresh token.
class TokenStorage {
  static const _accessTokenKey = 'TOKEN';
  static const _refreshTokenKey = 'REFRESH_TOKEN';
  static const _expiryKey = 'TOKEN_EXPIRY'; // epoch millis
  static const _deviceIdKey = 'DEVICE_ID';

  /// Refresh a little before the real expiry to absorb clock skew / latency.
  static const _expiryLeeway = Duration(seconds: 30);

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveTokens({
    required String? accessToken,
    required String? refreshToken,
    int? expiresIn,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_accessTokenKey, accessToken ?? '');
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    if (expiresIn != null && expiresIn > 0) {
      final expiryMs = DateTime.now()
          .add(Duration(seconds: expiresIn))
          .millisecondsSinceEpoch;
      await prefs.setInt(_expiryKey, expiryMs);
    }
  }

  Future<String?> getAccessToken() async => (await _prefs).getString(_accessTokenKey);

  Future<String?> getRefreshToken() async =>
      (await _prefs).getString(_refreshTokenKey);

  /// `true` when there is no access token or it is at/near its expiry.
  Future<bool> isAccessTokenExpired() async {
    final prefs = await _prefs;
    final token = prefs.getString(_accessTokenKey);
    if (token == null || token.isEmpty) return true;

    final expiryMs = prefs.getInt(_expiryKey);
    if (expiryMs == null) return false; // no expiry recorded -> assume valid

    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    return DateTime.now().add(_expiryLeeway).isAfter(expiry);
  }

  /// Stable per-install id sent alongside the refresh token. Mirrors the id
  /// created during sign-in; generates one if it is somehow missing.
  Future<String> getDeviceId() async {
    final prefs = await _prefs;
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId =
          'device-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiryKey);
  }
}
