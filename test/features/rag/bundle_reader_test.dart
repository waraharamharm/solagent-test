import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/features/rag/data/bundle_reader.dart';
import 'package:solagent/features/rag/data/http_rag_service.dart';
import 'package:solagent/features/rag/domain/rag_models.dart';

class _Entry {
  _Entry(this.name, this.data, {this.type = 0x30});
  final String name;
  final List<int> data;
  final int type;
}

Uint8List _header(String name, int size, int type) {
  final h = Uint8List(512);
  h.setRange(0, name.length, ascii.encode(name));
  h.setRange(100, 107, ascii.encode('0000644'));
  h.setRange(124, 135, ascii.encode(size.toRadixString(8).padLeft(11, '0')));
  h[156] = type;
  h.setRange(257, 262, ascii.encode('ustar'));
  for (var i = 148; i < 156; i++) {
    h[i] = 0x20;
  }
  final sum = h.fold<int>(0, (a, b) => a + b);
  h.setRange(148, 154, ascii.encode(sum.toRadixString(8).padLeft(6, '0')));
  h[154] = 0;
  h[155] = 0x20;
  return h;
}

Uint8List _tar(List<_Entry> entries) {
  final out = BytesBuilder();
  for (final e in entries) {
    out.add(_header(e.name, e.data.length, e.type));
    out.add(e.data);
    out.add(Uint8List((512 - e.data.length % 512) % 512));
  }
  out.add(Uint8List(1024));
  return out.toBytes();
}

Uint8List _targz(List<_Entry> entries) =>
    Uint8List.fromList(gzip.encode(_tar(entries)));

String _sha(List<int> data) => sha256.convert(data).toString();

Map<String, Object?> _manifest(
  Uint8List archive,
  List<_Entry> files, {
  String version = 'v1',
}) => {
  'version': version,
  'archive_sha256': _sha(archive),
  'archive_size': archive.length,
  'files': [
    for (final f in files)
      {'path': f.name, 'sha256': _sha(f.data), 'size': f.data.length},
  ],
};

final _files = [
  _Entry('scripts/install.sh', utf8.encode('#!/bin/sh\necho ok\n')),
  _Entry('docs/A.md', utf8.encode('hello')),
];

void main() {
  group('readBundle', () {
    test('unpacks a valid archive in memory', () {
      final archive = _targz(_files);
      final bundle = readBundle(
        parseBundleManifest(_manifest(archive, _files)),
        archive,
      );
      expect(bundle.version, 'v1');
      expect(
        bundle.files.keys,
        unorderedEquals(['scripts/install.sh', 'docs/A.md']),
      );
      expect(utf8.decode(bundle.files['docs/A.md']!), 'hello');
    });

    test('a changed archive fails the hash check', () {
      final archive = _targz(_files);
      final manifest = parseBundleManifest(_manifest(archive, _files));
      final tampered = Uint8List.fromList(archive)..[archive.length ~/ 2] ^= 1;
      expect(
        () => readBundle(manifest, tampered),
        throwsA(isA<RagBadResponse>()),
      );
    });

    test('a file that differs from its manifest hash is refused', () {
      final archive = _targz(_files);
      final json = _manifest(archive, _files);
      ((json['files']! as List).first as Map)['sha256'] = '0' * 64;
      expect(
        () => readBundle(parseBundleManifest(json), archive),
        throwsA(isA<RagBadResponse>()),
      );
    });

    test('a file the manifest does not list is refused', () {
      final withExtra = [..._files, _Entry('evil.sh', utf8.encode('rm -rf /'))];
      final archive = _targz(withExtra);
      expect(
        () => readBundle(
          parseBundleManifest(_manifest(archive, _files)),
          archive,
        ),
        throwsA(isA<RagBadResponse>()),
      );
    });

    test('path traversal and absolute paths in the tar are refused', () {
      for (final name in ['../escape.sh', '/etc/cron.d/x', 'a/../../b']) {
        final entries = [_Entry(name, utf8.encode('x'))];
        final archive = _targz(entries);
        final json = _manifest(archive, [_Entry('ok', utf8.encode('x'))]);
        expect(
          () => readBundle(parseBundleManifest(json), archive),
          throwsA(isA<RagBadResponse>()),
          reason: name,
        );
      }
    });

    test('symlinks and other entry types are refused', () {
      final entries = [_Entry('link', const [], type: 0x32)];
      final archive = _targz(entries);
      expect(
        () => readBundle(
          parseBundleManifest(_manifest(archive, const [])),
          archive,
        ),
        throwsA(isA<RagBadResponse>()),
      );
    });

    test('a decompression bomb is stopped', () {
      final bomb = Uint8List.fromList(
        gzip.encode(Uint8List(BundleLimits.maxUnpackedBytes + 1024 * 1024)),
      );
      final json = {
        'version': 'v1',
        'archive_sha256': _sha(bomb),
        'archive_size': bomb.length,
        'files': <Object?>[],
      };
      expect(
        () => readBundle(parseBundleManifest(json), bomb),
        throwsA(isA<RagBadResponse>()),
      );
    });

    test('garbage that is not gzip is refused', () {
      final junk = Uint8List.fromList(utf8.encode('not an archive at all'));
      final json = {
        'version': 'v1',
        'archive_sha256': _sha(junk),
        'archive_size': junk.length,
        'files': <Object?>[],
      };
      expect(
        () => readBundle(parseBundleManifest(json), junk),
        throwsA(isA<RagBadResponse>()),
      );
    });
  });

  group('parseBundleManifest', () {
    test('rejects unsafe paths, bad hashes and duplicates', () {
      final base = _manifest(_targz(_files), _files);
      Map<String, Object?> with0(Map<String, Object?> patch) => {
        ...base,
        ...patch,
      };
      for (final bad in [
        with0({'archive_sha256': 'xyz'}),
        with0({'archive_size': 0}),
        with0({'files': 'nope'}),
        with0({
          'files': [
            {'path': '../x', 'sha256': '0' * 64, 'size': 1},
          ],
        }),
        with0({
          'files': [
            {'path': 'a', 'sha256': '0' * 64, 'size': 1},
            {'path': 'a', 'sha256': '0' * 64, 'size': 1},
          ],
        }),
      ]) {
        expect(() => parseBundleManifest(bad), throwsA(isA<RagBadResponse>()));
      }
      expect(() => parseBundleManifest('x'), throwsA(isA<RagBadResponse>()));
    });
  });

  group('HttpRagService.fetchBundle', () {
    test('downloads manifest then archive and sends the key', () async {
      final archive = _targz(_files);
      final manifest = _manifest(archive, _files);
      final seen = <RequestOptions>[];
      final dio = Dio()
        ..httpClientAdapter = _Routes((o) {
          seen.add(o);
          if (o.path.endsWith('/v1/bundle')) {
            return ResponseBody.fromString(
              jsonEncode(manifest),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          return ResponseBody.fromBytes(archive, 200);
        });
      final service = HttpRagService(
        config: const RagConfig(
          baseUrl: 'https://rag.example',
          apiKey: 'sol_k',
        ),
        dio: dio,
      );

      final bundle = await service.fetchBundle();

      expect(bundle.files, hasLength(2));
      expect(seen.map((o) => o.uri.path), [
        '/v1/bundle',
        '/v1/bundle/archive/${_sha(archive)}',
      ]);
      expect(
        seen.every((o) => o.headers['Authorization'] == 'Bearer sol_k'),
        isTrue,
      );
    });

    test('404 before publishing is a server failure with the code', () async {
      final dio = Dio()
        ..httpClientAdapter = _Routes(
          (_) => ResponseBody.fromString(
            jsonEncode({'code': 'bundle_not_published', 'message': 'no'}),
            404,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          ),
        );
      final service = HttpRagService(
        config: const RagConfig(
          baseUrl: 'https://rag.example',
          apiKey: 'sol_k',
        ),
        dio: dio,
      );
      await expectLater(
        service.fetchBundle(),
        throwsA(
          isA<RagServerFailure>().having(
            (e) => e.code,
            'code',
            'bundle_not_published',
          ),
        ),
      );
    });
  });
}

class _Routes implements HttpClientAdapter {
  _Routes(this.respond);
  final ResponseBody Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}
