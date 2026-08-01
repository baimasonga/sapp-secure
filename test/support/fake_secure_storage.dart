import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:salone_shield/app/providers.dart';
import 'package:salone_shield/core/storage/secure_storage_service.dart';

/// In-memory stand-in for the Android Keystore.
///
/// [values] is exposed so tests can assert on what was actually written —
/// which is how the "no message content in storage" guarantees are checked.
class FakeSecureStorage {
  FakeSecureStorage() {
    FlutterSecureStoragePlatform.instance = _FakeSecureStoragePlatform(values);
  }

  final Map<String, String> values = {};

  SecureStorageService get service =>
      const SecureStorageService(FlutterSecureStorage());

  /// Points every repository at this in-memory keystore.
  Override get override => secureStorageProvider.overrideWithValue(service);
}

/// Installs an in-memory keystore unless one is already in place.
///
/// Every widget test needs this: the app reads trusted contacts during
/// analysis, and the real plugin has no implementation under `flutter test`.
/// Tests that want to inspect what was written create their own
/// [FakeSecureStorage] in `setUp`, and this leaves it alone.
void ensureFakeSecureStorage() {
  if (FlutterSecureStoragePlatform.instance is _FakeSecureStoragePlatform) {
    return;
  }
  FlutterSecureStoragePlatform.instance = _FakeSecureStoragePlatform({});
}

class _FakeSecureStoragePlatform extends FlutterSecureStoragePlatform {
  _FakeSecureStoragePlatform(this._values);

  final Map<String, String> _values;

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async => _values.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async => _values.remove(key);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async =>
      _values.clear();

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async => _values[key];

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async => Map.of(_values);

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async => _values[key] = value;
}
