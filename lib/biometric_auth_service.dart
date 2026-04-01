import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  static const _enabledKey = 'biometric_login_enabled';
  static const _credKey = 'biometric_login_cred';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  static Future<String?> getUnavailableReason() async {
    final isSupported = await _localAuth.isDeviceSupported();
    if (!isSupported) {
      return 'Thiet bi khong ho tro sinh trac hoc';
    }

    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) {
      return 'Ban chua cai dat van tay/khuon mat trong cai dat may';
    }

    final available = await _localAuth.getAvailableBiometrics();
    if (available.isEmpty) {
      return 'Khong tim thay du lieu van tay/khuon mat da dang ky';
    }

    return null;
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  static Future<void> saveCredential({
    required String email,
    required String password,
  }) async {
    final payload = jsonEncode(<String, String>{
      'email': email,
      'password': password,
    });
    await _secureStorage.write(key: _credKey, value: payload);
  }

  static Future<Map<String, String>?> readCredential() async {
    final raw = await _secureStorage.read(key: _credKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final email = map['email']?.toString() ?? '';
      final password = map['password']?.toString() ?? '';
      if (email.isEmpty || password.isEmpty) return null;
      return <String, String>{'email': email, 'password': password};
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCredential() async {
    await _secureStorage.delete(key: _credKey);
  }

  static Future<bool> authenticate() async {
    return _localAuth.authenticate(
      localizedReason: 'Xac thuc de dang nhap nhanh',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }
}
