import 'package:solagent/core/security/secure_store.dart';

/// In-memory [SecureStore]; alues is readable so tests can check what was
/// (not) persisted.
class MemoryStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
