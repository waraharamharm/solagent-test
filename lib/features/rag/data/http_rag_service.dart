import 'package:dio/dio.dart';

import '../domain/rag_models.dart';

/// Client for the knowledge server (`rag_server`). Only [RagFailure] escapes;
/// failure messages never contain the API key.
class HttpRagService implements IRagService {
  HttpRagService({required this._config, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
            ),
          );

  final RagConfig _config;
  final Dio _dio;

  /// The server rejects longer queries.
  static const maxQueryChars = 4000;

  String get _url {
    final base = _config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/v1/search';
  }

  @override
  Future<List<RagHit>> search(String query, {String? os, int k = 4}) async {
    final text = query.length > maxQueryChars
        ? query.substring(0, maxQueryChars)
        : query;
    try {
      final response = await _dio.post<Object?>(
        _url,
        data: {'query': text, 'os': ?os, 'k': k},
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Authorization': 'Bearer ${_config.apiKey}',
            'Content-Type': 'application/json',
          },
        ),
      );
      return _parse(response.data);
    } on RagFailure {
      rethrow;
    } on DioException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const RagBadResponse('Unexpected error while calling the server');
    }
  }

  List<RagHit> _parse(Object? data) {
    if (data is! Map || data['results'] is! List) {
      throw const RagBadResponse('Response is not a valid search result');
    }
    final hits = <RagHit>[];
    for (final item in data['results'] as List) {
      if (item is! Map) continue;
      final source = item['source'];
      final path = item['path'];
      final text = item['text'];
      final score = item['score'];
      if (source is! String ||
          path is! String ||
          text is! String ||
          score is! num) {
        continue;
      }
      hits.add(
        RagHit(source: source, path: path, text: text, score: score.toDouble()),
      );
    }
    return hits;
  }

  RagFailure _map(DioException e) {
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

  static String _short(String text) =>
      text.length <= 200 ? text : text.substring(0, 200);
}
