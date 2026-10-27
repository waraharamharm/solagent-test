sealed class LlmFailure implements Exception {
  const LlmFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 401: wrong or revoked key. 403: key lacks access, or the provider
/// refuses the user's region.
final class LlmUnauthorized extends LlmFailure {
  const LlmUnauthorized(super.message, {this.statusCode = 401});

  final int statusCode;
}

/// 429: provider rate limit or exhausted balance.
final class LlmRateLimited extends LlmFailure {
  const LlmRateLimited(super.message);
}

/// No connection, DNS, TLS, timeouts.
final class LlmNetworkFailure extends LlmFailure {
  const LlmNetworkFailure(super.message);
}

/// Any other non-2xx status.
final class LlmServerFailure extends LlmFailure {
  const LlmServerFailure(this.statusCode, String message) : super(message);

  final int? statusCode;
}

/// 2xx but body is not a valid chat completion.
final class LlmBadResponse extends LlmFailure {
  const LlmBadResponse(super.message);
}
