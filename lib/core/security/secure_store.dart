import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_store.g.dart';

class SecureStoreFailure implements Exception {
  const SecureStoreFailure(this.message);

  final String message;

  @override
  String toString() => 'SecureStoreFailure: $message';
}

/// The only place in the app that touches platform secure storage.
///
/// Android: AES-GCM data key wrapped by an Android Keystore RSA key.
/// iOS: Keychain, readable only while unlocked, never synced or migrated
/// to another device.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      throw SecureStoreFailure('read failed (${e.code})');
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      throw SecureStoreFailure('write failed (${e.code})');
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e) {
      throw SecureStoreFailure('delete failed (${e.code})');
    }
  }
}

@Riverpod(keepAlive: true)
SecureStore secureStore(Ref ref) => SecureStore();
