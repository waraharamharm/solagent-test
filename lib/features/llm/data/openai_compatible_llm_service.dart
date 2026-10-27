import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/chat_message.dart';
import '../domain/i_llm_service.dart';
import '../domain/llm_config.dart';
import '../domain/llm_failure.dart';

/// Chat adapter for any OpenAI v1 compatible `/chat/completions` endpoint.
///
/// Only [LlmFailure] escapes. Failure messages never contain the API key.
class OpenAiCompatibleLlmService implements ILLMService {
  OpenAiCompatibleLlmService({required this._config, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 120),
            ),
          );

  final LlmConfig _config;
  final Dio _dio;

  String get _url {
    final base = _config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/chat/completions';
  }

  Map<String, Object?> _body(
    List<ChatMessage> messages,
    double temperature, {
    required bool stream,
  }) => {
    'model': _config.model,
    'messages': [
      for (final m in messages) {'role': m.role.name, 'content': m.content},
    ],
    'temperature': temperature,
    'stream': stream,
  };

  Options _options({required ResponseType responseType}) => Options(
    method: 'POST',
    responseType: responseType,
    headers: {
      'Authorization': 'Bearer ${_config.apiKey}',
      'Content-Type': 'application/json',
    },
  );

  @override
  Future<LlmResponse> complete(
    List<ChatMessage> messages, {
    double temperature = 0.2,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        _url,
        data: _body(messages, temperature, stream: false),
        options: _options(responseType: ResponseType.json),
      );
      return _parseCompletion(response.data);
    } on LlmFailure {
      rethrow;
    } on DioException catch (e) {
      throw await _mapDioException(e);
    } catch (_) {
      throw const LlmBadResponse('Unexpected error while calling the model');
    }
  }

  @override
  Stream<String> stream(
    List<ChatMessage> messages, {
    double temperature = 0.2,
  }) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        _url,
        data: _body(messages, temperature, stream: true),
        options: _options(responseType: ResponseType.stream),
      );
      final body = response.data;
      if (body == null) {
        throw const LlmBadResponse('Empty response body');
      }

      final lines = const LineSplitter().bind(
        utf8.decoder.bind(body.stream.cast<List<int>>()),
      );
      await for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith(':')) continue;
        if (!line.startsWith('data:')) continue;

        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;
        if (payload == '[DONE]') return;

        final delta = _parseDelta(payload);
        if (delta != null && delta.isNotEmpty) yield delta;
      }
    } on LlmFailure {
      rethrow;
    } on DioException catch (e) {
      throw await _mapDioException(e);
    } catch (_) {
      throw const LlmNetworkFailure('Connection interrupted');
    }
  }

  LlmResponse _parseCompletion(Object? data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is! Map) throw const FormatException();
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) throw const FormatException();
      final first = choices.first;
      if (first is! Map) throw const FormatException();
      final message = first['message'];
      if (message is! Map) throw const FormatException();
      final content = message['content'];
      if (content is! String) throw const FormatException();

      LlmUsage? usage;
      final rawUsage = decoded['usage'];
      if (rawUsage is Map) {
        final prompt = rawUsage['prompt_tokens'];
        final completion = rawUsage['completion_tokens'];
        if (prompt is int && completion is int) {
          usage = LlmUsage(promptTokens: prompt, completionTokens: completion);
        }
      }
      return LlmResponse(content: content, usage: usage);
    } on FormatException {
      throw const LlmBadResponse('Response is not a valid chat completion');
    }
  }

  String? _parseDelta(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) throw const FormatException();
      final choices = decoded['choices'];
      if (choices is! List) throw const FormatException();
      if (choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) throw const FormatException();
      final delta = first['delta'];
      if (delta is! Map) return null;
      final content = delta['content'];
      return content is String ? content : null;
    } on FormatException {
      throw const LlmBadResponse('Malformed stream chunk');
    }
  }

  Future<LlmFailure> _mapDioException(DioException e) async {
    final response = e.response;
    if (response == null) {
      return LlmNetworkFailure(_networkMessage(e.type));
    }

    final status = response.statusCode;
    final providerMessage = await _providerMessage(response.data);
    final suffix = providerMessage == null ? '' : ': $providerMessage';

    switch (status) {
      case 401:
      case 403:
        return LlmUnauthorized(
          'Authorization failed (HTTP $status)$suffix',
          statusCode: status!,
        );
      case 429:
        return LlmRateLimited(
          'Rate limited or out of balance (HTTP 429)$suffix',
        );
      default:
        return LlmServerFailure(status, 'Provider error (HTTP $status)$suffix');
    }
  }

  String _networkMessage(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout => 'Connection timed out',
    DioExceptionType.sendTimeout => 'Sending the request timed out',
    DioExceptionType.receiveTimeout => 'Waiting for the response timed out',
    DioExceptionType.connectionError => 'Could not connect to the provider',
    DioExceptionType.badCertificate => 'Invalid TLS certificate',
    DioExceptionType.cancel => 'Request was cancelled',
    _ => 'Network error',
  };

  /// Extracts `error.message` from a provider error body, if present.
  Future<String?> _providerMessage(Object? data) async {
    try {
      Object? decoded = data;
      if (decoded is ResponseBody) {
        final bytes = await decoded.stream.fold<List<int>>(
          <int>[],
          (acc, chunk) => acc..addAll(chunk),
        );
        decoded = utf8.decode(bytes, allowMalformed: true);
      } else if (decoded is List<int>) {
        decoded = utf8.decode(decoded, allowMalformed: true);
      }
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is! Map) return null;
      final error = decoded['error'];
      final message = error is Map ? error['message'] : decoded['message'];
      if (message is! String || message.trim().isEmpty) return null;
      return _redact(message.trim());
    } catch (_) {
      return null;
    }
  }

  String _redact(String text) {
    final key = _config.apiKey;
    if (key.isEmpty) return text;
    return text.replaceAll(key, '***');
  }
}
