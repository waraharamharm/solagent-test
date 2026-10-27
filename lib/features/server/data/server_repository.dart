import 'dart:convert';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_problem.dart';
import '../../../core/security/secure_store.dart';
import '../../ssh/domain/ssh_target.dart';
import '../domain/server_profile.dart';

part 'server_repository.g.dart';

/// One saved server. Profile and secret both live in [SecureStore]. The
/// secret goes in through [save] and comes out only as a single-use
/// [SshCredential] from [loadCredential]; the UI never gets it back.
class ServerRepository {
  ServerRepository(this._store);

  static const _profileKey = 'server.profile';
  static const _secretKey = 'server.secret';

  final SecureStore _store;

  Future<ServerProfile?> load() async {
    final raw = await _store.read(_profileKey);
    if (raw == null) return null;
    try {
      return ServerProfile.tryFromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  Future<bool> hasSecret() async =>
      (await _store.read(_secretKey))?.isNotEmpty ?? false;

  /// Throws [AppProblemError] on invalid input.
  Future<void> save(ServerProfile profile, String secret) async {
    final error = validateServerProfile(profile);
    if (error != null) throw AppProblemError(error);
    if (secret.trim().isEmpty) {
      throw AppProblemError(
        profile.authKind == ServerAuthKind.key
            ? AppProblem.emptyKey
            : AppProblem.emptyPassword,
      );
    }
    // Passwords may have meaningful spaces; keys are re-wrapped because a
    // phone clipboard often turns line breaks into spaces.
    final value = profile.authKind == ServerAuthKind.key
        ? normalizePrivateKey(secret)
        : secret;
    await _store.write(_secretKey, value);
    await _store.write(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<SshTarget?> loadTarget() async {
    final p = await load();
    if (p == null) return null;
    return SshTarget(host: p.host, port: p.port, username: p.username);
  }

  /// A fresh credential each call; the connector wipes it. Null if absent.
  Future<SshCredential?> loadCredential() async {
    final profile = await load();
    final secret = await _store.read(_secretKey);
    if (profile == null || secret == null || secret.isEmpty) return null;
    final bytes = Uint8List.fromList(utf8.encode(secret));
    return switch (profile.authKind) {
      ServerAuthKind.password => SshPasswordCredential(bytes),
      ServerAuthKind.key => SshKeyCredential(bytes),
    };
  }

  Future<void> delete() async {
    await _store.delete(_secretKey);
    await _store.delete(_profileKey);
  }
}

final _pemPattern = RegExp(
  r'-----BEGIN ([A-Z ]+)-----([\s\S]*?)-----END \1-----',
);

/// Rebuilds a PEM/OpenSSH key as header + 70-char lines + footer, whatever
/// whitespace the paste produced. Unparseable input is returned trimmed and
/// left for the SSH layer to reject.
String normalizePrivateKey(String input) {
  final match = _pemPattern.firstMatch(input.trim());
  if (match == null) return '${input.trim()}\n';
  final body = match.group(2)!.replaceAll(RegExp(r'\s+'), '');
  final lines = [
    for (var i = 0; i < body.length; i += 70)
      body.substring(i, i + 70 > body.length ? body.length : i + 70),
  ];
  final label = match.group(1);
  return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----\n';
}

@Riverpod(keepAlive: true)
ServerRepository serverRepository(Ref ref) =>
    ServerRepository(ref.watch(secureStoreProvider));
