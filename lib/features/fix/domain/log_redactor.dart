import 'dart:isolate';

/// Strips data that must not leave the phone before a log is sent to the AI:
/// the server's address and login, any IPs, credentials, keys, tokens,
/// emails and home directory names.
///
/// Best effort: it catches the common shapes, not every possible secret.
/// The AI only ever sees redacted text; the user sees the raw log locally.
class LogRedactor {
  LogRedactor({Iterable<String> knownSecrets = const [], this.host, this.user})
    : _known = [
        for (final s in knownSecrets)
          if (s.trim().length >= 4) s.trim(),
      ]..sort((a, b) => b.length.compareTo(a.length));

  final List<String> _known;

  /// Server address as typed by the user (IP or domain).
  final String? host;

  /// SSH login on the server.
  final String? user;

  static final _pemBlock = RegExp(
    r'-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----[\s\S]*?(-----END [A-Z0-9 ]*PRIVATE KEY-----|$)',
  );
  static final _urlCreds = RegExp(
    r'([a-zA-Z][a-zA-Z0-9+.-]*://)[^\s/@:]+:[^\s/@]+@',
  );
  static final _authHeader = RegExp(
    r'(authorization|proxy-authorization)(\s*[:=]\s*)(bearer|basic|token)?\s*\S+',
    caseSensitive: false,
  );
  static final _keyValue = RegExp(
    r'''((?:[A-Za-z0-9_.-]*)(?:password|passwd|pwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|credential)[A-Za-z0-9_.-]*)(["']?\s*[:=]\s*["']?)([^\s"',;]+)''',
    caseSensitive: false,
  );
  static final _cliPassword = RegExp(
    r'''(--?(?:password|passwd|pass|token|api-key|secret)(?:=|\s+))(["']?)[^\s"']+''',
    caseSensitive: false,
  );
  static final _knownTokens = RegExp(
    r'\b(sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'
    r'|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}'
    r'|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,})',
  );

  /// Long mixed-alphabet runs: base64 secrets, hex keys. Also hits hashes
  /// in apt output, which is an acceptable loss.
  static final _longToken = RegExp(r'[A-Za-z0-9+/_=-]{32,}');
  static final _email = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );
  static final _ipv4 = RegExp(
    r'\b(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\b',
  );

  /// Full 8-group form or a form with `::`, so times like 12:34:56 survive.
  static final _ipv6 = RegExp(
    r'(?<![A-Za-z0-9:])(?:'
    r'(?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}'
    r'|(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4}){0,6})?::(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4}){0,6})?'
    r')(?![A-Za-z0-9:])',
  );
  static final _homeDir = RegExp(r'/home/[^/\s:]+');
  static const _keptIps = {'127.0.0.1', '0.0.0.0', '255.255.255.255'};

  String redact(String text) {
    var out = text;
    for (final s in _known) {
      out = out.replaceAll(s, '<secret>');
    }
    out = out.replaceAll(_pemBlock, '<private-key>');
    out = out.replaceAllMapped(_urlCreds, (m) => '${m[1]}<redacted>@');
    out = out.replaceAllMapped(_authHeader, (m) => '${m[1]}${m[2]}<redacted>');
    out = out.replaceAllMapped(_cliPassword, (m) => '${m[1]}<redacted>');
    out = out.replaceAllMapped(_keyValue, (m) => '${m[1]}${m[2]}<redacted>');
    out = out.replaceAll(_knownTokens, '<token>');
    out = out.replaceAllMapped(_longToken, (m) {
      final t = m[0]!;
      final hasLetter = t.contains(RegExp('[A-Za-z]'));
      final hasDigit = t.contains(RegExp('[0-9]'));
      return hasLetter && hasDigit ? '<token>' : t;
    });
    out = out.replaceAll(_email, '<email>');
    final h = host;
    if (h != null && h.isNotEmpty) out = out.replaceAll(h, '<server>');
    out = out.replaceAllMapped(
      _ipv4,
      (m) => _keptIps.contains(m[0]) ? m[0]! : '<ip>',
    );
    out = out.replaceAllMapped(
      _ipv6,
      (m) => m[0] == '::' || m[0] == '::1' ? m[0]! : '<ip>',
    );
    out = out.replaceAll(_homeDir, '/home/<user>');
    final u = user;
    if (u != null && u.length >= 3 && u != 'root') {
      // Whole word only: a file like `solagent-fixdemo` must stay intact,
      // or the AI proposes fixes for paths that do not exist.
      out = out.replaceAll(
        RegExp('(?<![\\w.-])${RegExp.escape(u)}(?![\\w-]|\\.\\w)'),
        '<user>',
      );
    }
    return out;
  }

  /// Runs [redact] off the UI isolate; meant for one batch, not per line.
  Future<String> redactInBackground(String text) {
    final known = List<String>.of(_known);
    final h = host;
    final u = user;
    return Isolate.run(
      () => LogRedactor(knownSecrets: known, host: h, user: u).redact(text),
    );
  }
}
