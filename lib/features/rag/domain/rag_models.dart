/// One passage returned by the knowledge server.
class RagHit {
  const RagHit({
    required this.source,
    required this.path,
    required this.text,
    required this.score,
  });

  /// `repo`, `doc` or `solution` (a user-submitted fix approved by moderation).
  final String source;
  final String path;
  final String text;
  final double score;
}

class RagConfig {
  const RagConfig({required this.baseUrl, required this.apiKey});

  final String baseUrl;
  final String apiKey;
}

abstract interface class IRagService {
  /// [query] must already be free of secrets and private addresses: it leaves
  /// the phone. Throws only [RagFailure].
  Future<List<RagHit>> search(String query, {String? os, int k = 4});
}

sealed class RagFailure implements Exception {
  const RagFailure(this.message, {this.code});

  /// Technical text from the server or the client, not translated.
  final String message;

  /// The server's `code` field when it sent one.
  final String? code;

  @override
  String toString() => '$runtimeType: $message';
}

/// 401: no key, wrong key or revoked key.
final class RagUnauthorized extends RagFailure {
  const RagUnauthorized(super.message, {super.code});
}

/// 429 from the server or from nginx in front of it.
final class RagRateLimited extends RagFailure {
  const RagRateLimited(super.message, {super.code, this.retryAfterSeconds});

  final int? retryAfterSeconds;
}

final class RagNetworkFailure extends RagFailure {
  const RagNetworkFailure(super.message);
}

final class RagServerFailure extends RagFailure {
  const RagServerFailure(this.statusCode, super.message, {super.code});

  final int? statusCode;
}

final class RagBadResponse extends RagFailure {
  const RagBadResponse(super.message);
}
