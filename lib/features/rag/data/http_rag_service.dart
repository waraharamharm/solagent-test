import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/knowledge_bundle.dart';
import '../domain/rag_models.dart';
import 'bundle_reader.dart';
import 'rag_errors.dart';

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

  String _endpoint(String path) {
    final base = _config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/v1/$path';
  }

  Map<String, String> get _auth => {
    'Authorization': 'Bearer ${_config.apiKey}',
  };

  @override
  Future<List<RagHit>> search(String query, {String? os, int k = 4}) async {
    final text = query.length > maxQueryChars
        ? query.substring(0, maxQueryChars)
        : query;
    try {
      final response = await _dio.post<Object?>(
        _endpoint('search'),
        data: {'query': text, 'os': ?os, 'k': k},
        options: Options(
          responseType: ResponseType.json,
          headers: {..._auth, 'Content-Type': 'application/json'},
        ),
      );
      return _parse(response.data);
    } on RagFailure {
      rethrow;
    } on DioException catch (e) {
      throw ragFailureFromDio(e);
    } catch (_) {
      throw const RagBadResponse('Unexpected error while calling the server');
    }
  }

  @override
  Future<KnowledgeBundle> fetchBundle() async {
    final cancel = CancelToken();
    try {
      final manifestResponse = await _dio.get<Object?>(
        _endpoint('bundle'),
        options: Options(responseType: ResponseType.json, headers: _auth),
      );
      final manifest = parseBundleManifest(manifestResponse.data);
      final archive = await _dio.get<List<int>>(
        _endpoint('bundle/archive/${manifest.archiveSha256}'),
        cancelToken: cancel,
        onReceiveProgress: (received, _) {
          if (received > manifest.archiveSize) cancel.cancel('too large');
        },
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
          headers: _auth,
        ),
      );
      return readBundle(manifest, Uint8List.fromList(archive.data ?? const []));
    } on RagFailure {
      rethrow;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw const RagBadResponse('Archive is larger than announced');
      }
      throw ragFailureFromDio(e);
    } catch (_) {
      throw const RagBadResponse('Unexpected error while downloading');
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
}
