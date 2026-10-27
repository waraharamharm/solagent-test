import 'package:dio/dio.dart';

import '../../rag/data/rag_errors.dart';
import '../../rag/domain/rag_models.dart';
import '../domain/run_relay.dart';

/// Talks to `/v1/runs` on the knowledge server, authenticated with the
/// user's access key.
class HttpRunRelay implements IRunRelay {
  HttpRunRelay({required this._config, Dio? dio})
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

  @override
  Future<RunRegistration> register({
    required String fcmToken,
    required String language,
  }) async {
    final base = _config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    try {
      final response = await _dio.post<Object?>(
        '$base/v1/runs',
        data: {'fcm_token': fcmToken, 'lang': language},
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Authorization': 'Bearer ${_config.apiKey}',
            'Content-Type': 'application/json',
          },
        ),
      );
      final data = response.data;
      if (data is Map &&
          data['run_id'] is String &&
          data['run_token'] is String) {
        return RunRegistration(
          runId: data['run_id'] as String,
          token: data['run_token'] as String,
        );
      }
      throw const RagBadResponse('Response is not a valid run registration');
    } on RagFailure {
      rethrow;
    } on DioException catch (e) {
      throw ragFailureFromDio(e);
    } on Object {
      throw const RagBadResponse('Unexpected error while registering the run');
    }
  }
}
