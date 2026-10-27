import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/errors/app_problem.dart';
import 'package:solagent/core/security/secure_store.dart';
import 'package:solagent/features/rag/data/http_rag_service.dart';
import 'package:solagent/features/rag/data/rag_settings_repository.dart';
import 'package:solagent/features/rag/domain/rag_models.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body, {Map<String, String>? headers}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        for (final e in (headers ?? const <String, String>{}).entries)
          e.key: [e.value],
      },
    );

const _secret = 'sol_supersecretkeysupersecretkeysupersecretkey0';

HttpRagService _service(_Adapter adapter) => HttpRagService(
  config: const RagConfig(baseUrl: 'https://rag.example/', apiKey: _secret),
  dio: Dio()..httpClientAdapter = adapter,
);

class _MemoryStore implements SecureStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  group('HttpRagService', () {
    test(
      'sends the key and query, parses hits, skips malformed ones',
      () async {
        final adapter = _Adapter(
          (_) => _json(200, {
            'results': [
              {
                'chunk_id': 1,
                'source': 'doc',
                'path': 'docs/A.md',
                'text': 'hello',
                'score': 0.5,
              },
              {'source': 'doc'},
              'junk',
            ],
          }),
        );
        final hits = await _service(adapter)
            .search('port busy', os: 'ubuntu-24.04', k: 3);

        expect(hits, hasLength(1));
        expect(hits.single.path, 'docs/A.md');
        expect(hits.single.score, 0.5);
        final req = adapter.last!;
        expect(req.uri.toString(), 'https://rag.example/v1/search');
        expect(req.headers['Authorization'], 'Bearer $_secret');
        expect(req.data, {'query': 'port busy', 'os': 'ubuntu-24.04', 'k': 3});
      },
    );

    test('the query is cut to the server limit', () async {
      final adapter = _Adapter((_) => _json(200, {'results': []}));
      await _service(adapter).search('x' * 9000);
      expect(
        ((adapter.last!.data as Map)['query'] as String).length,
        HttpRagService.maxQueryChars,
      );
    });

    test('401 maps to RagUnauthorized with the server code', () async {
      final service = _service(
        _Adapter(
          (_) => _json(401, {
            'status': 401,
            'code': 'unauthorized',
            'message': 'Missing or invalid API key',
          }),
        ),
      );
      await expectLater(
        service.search('x'),
        throwsA(
          isA<RagUnauthorized>().having((e) => e.code, 'code', 'unauthorized'),
        ),
      );
    });

    test('429 carries Retry-After', () async {
      final service = _service(
        _Adapter(
          (_) => _json(
            429,
            {'status': 429, 'code': 'rate_limited', 'message': 'slow down'},
            headers: {'retry-after': '7'},
          ),
        ),
      );
      await expectLater(
        service.search('x'),
        throwsA(
          isA<RagRateLimited>().having(
            (e) => e.retryAfterSeconds,
            'retryAfter',
            7,
          ),
        ),
      );
    });

    test('other statuses and html bodies become RagServerFailure', () async {
      final json500 = _service(
        _Adapter((_) => _json(500, {'code': 'internal_error', 'message': 'x'})),
      );
      await expectLater(
        json500.search('x'),
        throwsA(
          isA<RagServerFailure>().having((e) => e.statusCode, 'status', 500),
        ),
      );
      final html = _service(
        _Adapter(
          (_) => ResponseBody.fromString(
            '<html>oops</html>',
            502,
            headers: {
              Headers.contentTypeHeader: ['text/html'],
            },
          ),
        ),
      );
      await expectLater(
        html.search('x'),
        throwsA(
          isA<RagServerFailure>().having(
            (e) => e.message,
            'message',
            'HTTP 502',
          ),
        ),
      );
    });

    test('a 200 with the wrong shape is RagBadResponse', () async {
      final service = _service(_Adapter((_) => _json(200, {'oops': 1})));
      await expectLater(service.search('x'), throwsA(isA<RagBadResponse>()));
    });

    test('no failure text ever contains the key', () async {
      final adapters = [
        _Adapter(
          (_) => _json(401, {'message': 'bad $_secret'.substring(0, 8)}),
        ),
        _Adapter(
          (_) => throw DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
          ),
        ),
      ];
      for (final a in adapters) {
        try {
          await _service(a).search('x');
          fail('expected a failure');
        } on RagFailure catch (e) {
          expect(e.toString(), isNot(contains(_secret)));
        }
      }
    });

    test('network errors map to RagNetworkFailure', () async {
      final service = _service(
        _Adapter(
          (_) => throw DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      );
      await expectLater(service.search('x'), throwsA(isA<RagNetworkFailure>()));
    });
  });

  group('RagSettingsRepository', () {
    test('defaults to the project server and has no key', () async {
      final repo = RagSettingsRepository(_MemoryStore());
      final s = await repo.load();
      expect(s.baseUrl, defaultRagUrl);
      expect(s.hasApiKey, isFalse);
      expect(await repo.loadConfig(), isNull);
    });

    test('key is stored trimmed and exposed only through the config', () async {
      final store = _MemoryStore();
      final repo = RagSettingsRepository(store);
      await repo.saveApiKey('  $_secret \n');
      expect((await repo.load()).hasApiKey, isTrue);
      final config = (await repo.loadConfig())!;
      expect(config.apiKey, _secret);
      expect(config.baseUrl, defaultRagUrl);
      await repo.deleteApiKey();
      expect(await repo.loadConfig(), isNull);
    });

    test('an empty key and an insecure address are refused', () async {
      final store = _MemoryStore();
      final repo = RagSettingsRepository(store);
      await expectLater(
        repo.saveApiKey('   '),
        throwsA(
          isA<AppProblemError>().having(
            (e) => e.problem,
            'problem',
            AppProblem.emptyKey,
          ),
        ),
      );
      await expectLater(
        repo.saveBaseUrl('http://rag.example.com'),
        throwsA(isA<AppProblemError>()),
      );
      expect(store.values, isEmpty);
      await repo.saveBaseUrl('https://rag2.example.com');
      expect((await repo.load()).baseUrl, 'https://rag2.example.com');
    });
  });
}
