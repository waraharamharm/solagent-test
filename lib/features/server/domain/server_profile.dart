import '../../../core/errors/app_problem.dart';

enum ServerAuthKind { password, key }

/// Non-secret part of a saved server. The password/key lives separately.
class ServerProfile {
  const ServerProfile({
    required this.host,
    required this.username,
    this.port = 22,
    this.authKind = ServerAuthKind.password,
  });

  final String host;
  final int port;
  final String username;
  final ServerAuthKind authKind;

  Map<String, Object?> toJson() => {
    'host': host,
    'port': port,
    'username': username,
    'authKind': authKind.name,
  };

  static ServerProfile? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final host = json['host'];
    final port = json['port'];
    final username = json['username'];
    final kind = ServerAuthKind.values.asNameMap()[json['authKind']];
    if (host is! String ||
        port is! int ||
        username is! String ||
        kind == null) {
      return null;
    }
    final profile = ServerProfile(
      host: host,
      port: port,
      username: username,
      authKind: kind,
    );
    return validateServerProfile(profile) == null ? profile : null;
  }
}

final _hostPattern = RegExp(r'^[A-Za-z0-9]([A-Za-z0-9.:-]*[A-Za-z0-9])?$');
final _userPattern = RegExp(r'^[a-z_][a-z0-9_-]{0,31}$');

/// Null when valid, otherwise what is wrong.
AppProblem? validateServerProfile(ServerProfile p) {
  if (!_hostPattern.hasMatch(p.host)) return AppProblem.serverBadHost;
  if (p.port < 1 || p.port > 65535) return AppProblem.serverBadPort;
  if (!_userPattern.hasMatch(p.username)) return AppProblem.serverBadLogin;
  return null;
}

/// What the app learned about the VDS; later fed to the AI as the OS spec.
class ServerInfo {
  const ServerInfo({
    required this.osId,
    required this.osVersion,
    required this.prettyName,
    required this.arch,
    required this.isRoot,
    required this.fingerprint,
  });

  final String osId;
  final String osVersion;
  final String prettyName;
  final String arch;
  final bool isRoot;
  final String fingerprint;

  bool get isSupportedOs => osId == 'ubuntu' || osId == 'debian';

  /// Output of [probeCommand]. Null if it does not look like what we asked.
  static ServerInfo? parse(String stdout, {required String fingerprint}) {
    final lines = stdout.trim().split('\n');
    if (lines.length < 3) return null;
    final os = lines[0].split('|');
    if (os.length < 3) return null;
    return ServerInfo(
      osId: os[0],
      osVersion: os[1],
      prettyName: os.sublist(2).join('|'),
      arch: lines[1].trim(),
      isRoot: lines[2].trim() == '0',
      fingerprint: fingerprint,
    );
  }

  /// Fixed, read-only. Never built from user input.
  static const probeCommand =
      r'. /etc/os-release && echo "$ID|$VERSION_ID|$PRETTY_NAME" '
      r'&& uname -m && id -u';
}
