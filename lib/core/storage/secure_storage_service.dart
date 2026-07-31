import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted local storage for anything sensitive (section 15.3).
///
/// Backed by the Android Keystore. This is where session tokens and trusted
/// contact references live. It must never hold a WhatsApp verification code, a
/// two-step PIN or a mobile-money PIN — the app never collects those at all.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  /// Android storage is backed by the Keystore with the plugin's current
  /// default cipher; no deprecated options are pinned here.
  factory SecureStorageService.create() =>
      const SecureStorageService(FlutterSecureStorage());

  static const String keySessionToken = 'auth.session';
  static const String keyDeviceSalt = 'crypto.device_salt';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  /// Used by "delete all local data" in Settings.
  Future<void> deleteAll() => _storage.deleteAll();
}
