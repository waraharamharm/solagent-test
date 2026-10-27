import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/features/monitor/data/http_run_relay.dart';
import 'package:solagent/features/monitor/domain/checkpoint.dart';
import 'package:solagent/features/monitor/domain/checkpoint_prelude.dart';
import 'package:solagent/features/rag/domain/rag_models.dart';

final _token = 'run_${'A' * 43}';
const _runId = '0123456789abcdef';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
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

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

HttpRunRelay _relay(_Adapter a) => HttpRunRelay(
  config: const RagConfig(baseUrl: 'https://rag.example/', apiKey: 'sol_k'),
  dio: Dio()..httpClientAdapter = a,
);

void main() {
  group('checkpointPrelude', () {
    test('contains the values and the marker format the parser reads', () {
      final text = checkpointPrelude(
        relayUrl: 'https://rag.example/',
        runId: _runId,
        runToken: _token,
      );
      expect(text, contains("SOLAGENT_RELAY='https://rag.example'"));
      expect(text, contains("SOLAGENT_RUN='$_runId'"));
      expect(text, contains(checkpointPrefix.trim()));
      expect(text, isNot(contains('Bearer $_token')));
    });

    test('refuses values that could break out of the quotes', () {
      for (final bad in [
        (r"https://x.example'; rm -rf /; '", _runId, _token),
        ('http://rag.example', _runId, _token),
        ('https://rag.example', "$_runId'", _token),
        ('https://rag.example', _runId, "run_${'A' * 42}'"),
        ('https://rag.example/path', _runId, _token),
      ]) {
        expect(
          () => checkpointPrelude(
            relayUrl: bad.$1,
            runId: bad.$2,
            runToken: bad.$3,
          ),
          throwsArgumentError,
          reason: bad.toString(),
        );
      }
    });
  });

  group('HttpRunRelay', () {
    test('registers a run with the key and returns the token', () async {
      final adapter = _Adapter(
        (_) => _json(201, {
          'run_id': _runId,
          'run_token': _token,
          'expires_in': 86400,
        }),
      );
      final reg = await _relay(adapter)
          .register(fcmToken: 'f' * 40, language: 'ru');

      expect(reg.runId, _runId);
      expect(reg.token, _token);
      final req = adapter.last!;
      expect(req.uri.toString(), 'https://rag.example/v1/runs');
      expect(req.headers['Authorization'], 'Bearer sol_k');
      expect(req.data, {'fcm_token': 'f' * 40, 'lang': 'ru'});
    });

    test('503 means push is not configured on the server', () async {
      final adapter = _Adapter(
        (_) => _json(503, {'code': 'push_unavailable', 'message': 'no'}),
      );
      await expectLater(
        _relay(adapter).register(fcmToken: 'f' * 40, language: 'en'),
        throwsA(
          isA<RagServerFailure>().having(
            (e) => e.code,
            'code',
            'push_unavailable',
          ),
        ),
      );
    });

    test('a reply without a token is a bad response', () async {
      final adapter = _Adapter((_) => _json(201, {'run_id': _runId}));
      await expectLater(
        _relay(adapter).register(fcmToken: 'f' * 40, language: 'en'),
        throwsA(isA<RagBadResponse>()),
      );
    });
  });

  test('the prelude works in a real shell and prints a parsable marker', () async {
    final bash = await Process.run('bash', [
      '--version',
    ]).then((r) => r.exitCode == 0, onError: (_) => false);
    if (!bash) {
      markTestSkipped('bash is not available');
      return;
    }
    final script =
        '${checkpointPrelude(relayUrl: 'https://127.0.0.1:9', runId: _runId, runToken: _token)}\nsolagent_checkpoint build done\n';
    final result = await Process.run('bash', ['-c', script]);
    expect(result.exitCode, 0);
    expect(parseCheckpoints((result.stdout as String).split('\n')), const [
      Checkpoint(step: 'build', state: CheckpointState.done),
    ]);
  });
}
