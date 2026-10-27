import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/features/llm/data/openai_compatible_llm_service.dart';
import 'package:solagent/features/llm/domain/chat_message.dart';
import 'package:solagent/features/llm/domain/llm_config.dart';
import 'package:solagent/features/llm/domain/llm_failure.dart';

const _apiKey = 'sk-super-secret-key-123';

typedef _Handler = FutureOr<ResponseBody> Function(
  RequestOptions options,
  String body,
);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final _Handler _handler;
  RequestOptions? lastOptions;
  Map<String, dynamic>? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    var raw = '';
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      raw = utf8.decode(bytes);
    }
    if (raw.isNotEmpty) {
      lastBody = jsonDecode(raw) as Map<String, dynamic>;
    }
    return _handler(options, raw);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _sse(List<String> chunks, {int status = 200}) => ResponseBody(
  Stream.fromIterable(chunks.map((c) => Uint8List.fromList(utf8.encode(c)))),
  status,
  headers: {
    Headers.contentTypeHeader: ['text/event-stream'],
  },
);

String _delta(String content) =>
    'data: ${jsonEncode({
      'choices': [
        {
          'delta': {'content': content},
        },
      ],
    })}\n\n';

({OpenAiCompatibleLlmService service, _FakeAdapter adapter}) _build(
  _Handler handler, {
  String baseUrl = 'https://api.example.com/v1',
}) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = adapter;
  final service = OpenAiCompatibleLlmService(
    config: LlmConfig(baseUrl: baseUrl, model: 'test-model', apiKey: _apiKey),
    dio: dio,
  );
  return (service: service, adapter: adapter);
}

const _okBody = {
  'choices': [
    {
      'message': {'role': 'assistant', 'content': 'hello'},
    },
  ],
};

const _messages = [ChatMessage.system('be brief'), ChatMessage.user('hi')];

void main() {
  group('request shape', () {
    test('URL without trailing slash', () async {
      final t = _build((_, _) => _json(_okBody));
      await t.service.complete(_messages);
      expect(
        t.adapter.lastOptions!.uri.toString(),
        'https://api.example.com/v1/chat/completions',
      );
    });

    test('URL with trailing slashes is normalized', () async {
      final t = _build(
        (_, _) => _json(_okBody),
        baseUrl: 'https://api.example.com/v1//',
      );
      await t.service.complete(_messages);
      expect(
        t.adapter.lastOptions!.uri.toString(),
        'https://api.example.com/v1/chat/completions',
      );
    });

    test('headers and body', () async {
      final t = _build((_, _) => _json(_okBody));
      await t.service.complete(_messages, temperature: 0.7);

      final headers = t.adapter.lastOptions!.headers;
      expect(headers['Authorization'], 'Bearer $_apiKey');
      expect(
        headers['Content-Type'].toString(),
        startsWith('application/json'),
      );
      expect(t.adapter.lastOptions!.method, 'POST');
      expect(t.adapter.lastBody, {
        'model': 'test-model',
        'messages': [
          {'role': 'system', 'content': 'be brief'},
          {'role': 'user', 'content': 'hi'},
        ],
        'temperature': 0.7,
        'stream': false,
      });
    });

    test('stream request sets stream: true', () async {
      final t = _build((_, _) => _sse(['data: [DONE]\n\n']));
      await t.service.stream(_messages).toList();
      expect(t.adapter.lastBody!['stream'], true);
      expect(t.adapter.lastOptions!.responseType, ResponseType.stream);
    });
  });

  group('complete()', () {
    test('happy path with usage', () async {
      final t = _build(
        (_, _) => _json({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'hello'},
            },
          ],
          'usage': {'prompt_tokens': 11, 'completion_tokens': 5},
        }),
      );
      final res = await t.service.complete(_messages);
      expect(res.content, 'hello');
      expect(res.usage?.promptTokens, 11);
      expect(res.usage?.completionTokens, 5);
    });

    test('happy path without usage', () async {
      final t = _build((_, _) => _json(_okBody));
      final res = await t.service.complete(_messages);
      expect(res.content, 'hello');
      expect(res.usage, isNull);
    });

    for (final entry in <String, Object>{
      'not an object': ['x'],
      'no choices': {'id': '1'},
      'empty choices': {'choices': <Object?>[]},
      'content not string': {
        'choices': [
          {
            'message': {'content': 42},
          },
        ],
      },
    }.entries) {
      test('bad body (${entry.key}) -> LlmBadResponse', () async {
        final t = _build((_, _) => _json(entry.value));
        await expectLater(
          t.service.complete(_messages),
          throwsA(isA<LlmBadResponse>()),
        );
      });
    }

    test('non-JSON body -> LlmBadResponse', () async {
      final t = _build(
        (_, _) => ResponseBody.fromString(
          '<html>oops</html>',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
          },
        ),
      );
      await expectLater(
        t.service.complete(_messages),
        throwsA(isA<LlmBadResponse>()),
      );
    });
  });

  group('error mapping', () {
    test('401 -> LlmUnauthorized with provider message', () async {
      final t = _build(
        (_, _) => _json({
          'error': {'message': 'Invalid API key'},
        }, status: 401),
      );
      await expectLater(
        t.service.complete(_messages),
        throwsA(
          isA<LlmUnauthorized>().having(
            (e) => e.message,
            'message',
            contains('Invalid API key'),
          ),
        ),
      );
    });

    test('403 -> LlmUnauthorized', () async {
      final t = _build((_, _) => _json({'x': 1}, status: 403));
      await expectLater(
        t.service.complete(_messages),
        throwsA(isA<LlmUnauthorized>()),
      );
    });

    test('429 -> LlmRateLimited', () async {
      final t = _build((_, _) => _json({'x': 1}, status: 429));
      await expectLater(
        t.service.complete(_messages),
        throwsA(isA<LlmRateLimited>()),
      );
    });

    test('500 -> LlmServerFailure with statusCode', () async {
      final t = _build(
        (_, _) => _json({
          'error': {'message': 'boom'},
        }, status: 500),
      );
      await expectLater(
        t.service.complete(_messages),
        throwsA(
          isA<LlmServerFailure>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('boom')),
        ),
      );
    });

    test('connection error -> LlmNetworkFailure', () async {
      final t = _build(
        (options, _) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'no route',
        ),
      );
      await expectLater(
        t.service.complete(_messages),
        throwsA(isA<LlmNetworkFailure>()),
      );
    });

    test('timeout -> LlmNetworkFailure', () async {
      final t = _build(
        (options, _) => throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 15),
          requestOptions: options,
        ),
      );
      await expectLater(
        t.service.complete(_messages),
        throwsA(isA<LlmNetworkFailure>()),
      );
    });

    test('unexpected exception is mapped to LlmFailure', () async {
      final t = _build((_, _) => throw StateError('weird'));
      await expectLater(
        t.service.complete(_messages),
        throwsA(isA<LlmFailure>()),
      );
    });

    test('failure messages never contain the api key', () async {
      final cases = <_Handler>[
        (_, _) => _json({
          'error': {'message': 'bad key $_apiKey'},
        }, status: 401),
        (_, _) => _json({
          'error': {'message': 'limit for $_apiKey'},
        }, status: 429),
        (_, _) => _json({
          'error': {'message': 'fail $_apiKey'},
        }, status: 500),
        (options, _) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'Bearer $_apiKey',
        ),
        (_, _) => _json({'choices': <Object?>[]}),
      ];
      for (final handler in cases) {
        final t = _build(handler);
        try {
          await t.service.complete(_messages);
          fail('expected a failure');
        } on LlmFailure catch (e) {
          expect(e.message, isNot(contains(_apiKey)));
          expect(e.toString(), isNot(contains(_apiKey)));
        }
      }
    });
  });

  group('stream()', () {
    test(
      'SSE line split across chunks, comments ignored, [DONE] ends',
      () async {
        final line = _delta('Hello');
        final cut = line.indexOf('"content"') + 5;
        final t = _build(
          (_, _) => _sse([
            ': OPENROUTER PROCESSING\n\n',
            line.substring(0, cut),
            line.substring(cut),
            ': keep-alive\n',
            _delta(' world'),
            'data: {"choices":[{"delta":{"role":"assistant"}}]}\n\n',
            'data: {"choices":[{"delta":{"content":""}}]}\n\n',
            'data: [DONE]\n\n',
            _delta('AFTER DONE'),
          ]),
        );
        final parts = await t.service.stream(_messages).toList();
        expect(parts, ['Hello', ' world']);
      },
    );

    test('handles CRLF line endings and multi-byte characters', () async {
      final bytes = utf8.encode(_delta('Привет').replaceAll('\n', '\r\n'));
      final split = bytes.length ~/ 2;
      final t = _build(
        (_, _) => ResponseBody(
          Stream.fromIterable([
            Uint8List.fromList(bytes.sublist(0, split)),
            Uint8List.fromList(bytes.sublist(split)),
            Uint8List.fromList(utf8.encode('data: [DONE]\r\n\r\n')),
          ]),
          200,
        ),
      );
      final parts = await t.service.stream(_messages).toList();
      expect(parts.join(), 'Привет');
    });

    test('malformed JSON -> LlmBadResponse', () async {
      final t = _build((_, _) => _sse(['data: {not json\n\n']));
      await expectLater(
        t.service.stream(_messages).toList(),
        throwsA(isA<LlmBadResponse>()),
      );
    });

    test('401 on stream reads error body -> LlmUnauthorized', () async {
      final t = _build(
        (_, _) => _sse([
          jsonEncode({
            'error': {'message': 'Invalid key $_apiKey'},
          }),
        ], status: 401),
      );
      await expectLater(
        t.service.stream(_messages).toList(),
        throwsA(
          isA<LlmUnauthorized>()
              .having((e) => e.message, 'message', contains('Invalid key'))
              .having((e) => e.message, 'message', isNot(contains(_apiKey))),
        ),
      );
    });

    test('500 on stream -> LlmServerFailure', () async {
      final t = _build((_, _) => _sse(['oops'], status: 500));
      await expectLater(
        t.service.stream(_messages).toList(),
        throwsA(
          isA<LlmServerFailure>().having((e) => e.statusCode, 'code', 500),
        ),
      );
    });

    test('connection error on stream -> LlmNetworkFailure', () async {
      final t = _build(
        (options, _) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'no route',
        ),
      );
      await expectLater(
        t.service.stream(_messages).toList(),
        throwsA(isA<LlmNetworkFailure>()),
      );
    });
  });
}
