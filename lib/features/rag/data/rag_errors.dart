import 'package:dio/dio.dart';

import '../domain/rag_models.dart';

/// Turns a failed request to the knowledge server into a [RagFailure]. The
/// message never contains request headers, so it cannot leak the key.
RagFailure ragFailureFromDio(DioException e) {
  final response = e.response;
  if (response == null) {
    return RagNetworkFailure(switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => 'Connection timed out',
      DioExceptionType.badCertificate => 'Untrusted server certificate',
      _ => 'Could not reach the server',
    });
  }
  final status = response.statusCode ?? 0;
  final body = response.data;
  final code = body is Map && body['code'] is String
      ? body['code'] as String
      : null;
  final message = body is Map && body['message'] is String
      ? _short(body['message'] as String)
      : 'HTTP $status';
  return switch (status) {
    401 => RagUnauthorized(message, code: code),
    429 => RagRateLimited(
      message,
      code: code,
      retryAfterSeconds: int.tryParse(
        response.headers.value('retry-after') ?? '',
      ),
    ),
    _ => RagServerFailure(status, message, code: code),
  };
}

String _short(String text) =>
    text.length <= 200 ? text : text.substring(0, 200);
