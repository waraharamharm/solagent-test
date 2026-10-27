import '../errors/app_problem.dart';

/// Null when [value] is acceptable, otherwise what is wrong with it.
///
/// Plain http is allowed only for loopback and private networks
/// (local models like Ollama); otherwise the API key would travel unencrypted.
AppProblem? validateBaseUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return AppProblem.baseUrlNotAbsolute;
  }
  if (uri.scheme == 'https') return null;
  if (uri.scheme == 'http' && _isPrivateHost(uri.host)) return null;
  if (uri.scheme == 'http') return AppProblem.baseUrlInsecureHttp;
  return AppProblem.baseUrlUnsupportedScheme;
}

bool _isPrivateHost(String host) {
  if (host == 'localhost') return true;
  final parts = host.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) {
    return false;
  }
  final [a, b, _, _] = parts.cast<int>();
  return a == 127 ||
      a == 10 ||
      (a == 192 && b == 168) ||
      (a == 172 && b >= 16 && b <= 31);
}
