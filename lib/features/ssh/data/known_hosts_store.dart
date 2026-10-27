import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/security/secure_store.dart';
import '../domain/ssh_target.dart';

part 'known_hosts_store.g.dart';

/// Pinned host keys (trust on first use). Kept in [SecureStore] for
/// integrity: an attacker able to rewrite this map could pin their own key.
class KnownHostsStore {
  KnownHostsStore(this._store);

  static const _key = 'ssh.knownHosts';

  final SecureStore _store;

  Future<HostKeyInfo?> find(String hostId) async {
    final entry = (await _readAll())[hostId];
    if (entry == null) return null;
    return HostKeyInfo(
      hostId: hostId,
      type: entry['type']!,
      fingerprint: entry['fingerprint']!,
    );
  }

  Future<void> pin(HostKeyInfo info) async {
    final all = await _readAll();
    all[info.hostId] = {'type': info.type, 'fingerprint': info.fingerprint};
    await _store.write(_key, jsonEncode(all));
  }

  /// Explicit user action only, e.g. after reinstalling the server.
  Future<void> forget(String hostId) async {
    final all = await _readAll();
    if (all.remove(hostId) == null) return;
    await _store.write(_key, jsonEncode(all));
  }

  Future<Map<String, Map<String, String>>> _readAll() async {
    final raw = await _store.read(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    return {
      for (final MapEntry(:key, :value) in decoded.entries)
        key: Map<String, String>.from(value! as Map),
    };
  }
}

@Riverpod(keepAlive: true)
KnownHostsStore knownHostsStore(Ref ref) =>
    KnownHostsStore(ref.watch(secureStoreProvider));
