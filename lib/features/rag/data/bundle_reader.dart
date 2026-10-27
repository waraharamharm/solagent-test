import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../domain/knowledge_bundle.dart';
import '../domain/rag_models.dart';

/// Hard limits. The archive comes from a server we do not fully trust, and
/// its scripts may later run on the user's VDS.
abstract final class BundleLimits {
  static const maxArchiveBytes = 20 * 1024 * 1024;
  static const maxUnpackedBytes = 64 * 1024 * 1024;
  static const maxFiles = 2000;
  static const maxPathChars = 300;
}

final _hex64 = RegExp(r'^[0-9a-f]{64}$');

/// Validates the manifest JSON. Throws [RagBadResponse].
BundleManifest parseBundleManifest(Object? json) {
  if (json is! Map) throw const RagBadResponse('Manifest is not an object');
  final version = json['version'];
  final sha = json['archive_sha256'];
  final size = json['archive_size'];
  final files = json['files'];
  if (version is! String || version.isEmpty || version.length > 100) {
    throw const RagBadResponse('Manifest has no valid version');
  }
  if (sha is! String || !_hex64.hasMatch(sha)) {
    throw const RagBadResponse('Manifest has no valid archive hash');
  }
  if (size is! int || size <= 0 || size > BundleLimits.maxArchiveBytes) {
    throw const RagBadResponse('Archive size is missing or too large');
  }
  if (files is! List || files.length > BundleLimits.maxFiles) {
    throw const RagBadResponse('Manifest file list is missing or too long');
  }
  final seen = <String>{};
  final infos = <BundleFileInfo>[];
  for (final item in files) {
    if (item is! Map) throw const RagBadResponse('Bad manifest entry');
    final path = item['path'];
    final fileSha = item['sha256'];
    final fileSize = item['size'];
    if (path is! String || !isSafeBundlePath(path)) {
      throw const RagBadResponse('Manifest contains an unsafe path');
    }
    if (fileSha is! String || !_hex64.hasMatch(fileSha)) {
      throw const RagBadResponse('Manifest entry has no valid hash');
    }
    if (fileSize is! int ||
        fileSize < 0 ||
        fileSize > BundleLimits.maxUnpackedBytes) {
      throw const RagBadResponse('Manifest entry has no valid size');
    }
    if (!seen.add(path)) {
      throw const RagBadResponse('Manifest lists a path twice');
    }
    infos.add(BundleFileInfo(path: path, sha256: fileSha, size: fileSize));
  }
  return BundleManifest(
    version: version,
    archiveSha256: sha,
    archiveSize: size,
    files: infos,
  );
}

/// A relative POSIX path that stays inside the bundle.
bool isSafeBundlePath(String path) {
  if (path.isEmpty || path.length > BundleLimits.maxPathChars) return false;
  if (path.contains('\\') || path.contains('\u0000')) return false;
  if (path.startsWith('/')) return false;
  for (final part in path.split('/')) {
    if (part.isEmpty || part == '.' || part == '..') return false;
  }
  return true;
}

/// Checks [archive] against [manifest] and unpacks it in memory. The archive
/// must contain exactly the files the manifest lists, with matching sizes and
/// hashes. Throws [RagBadResponse].
KnowledgeBundle readBundle(BundleManifest manifest, Uint8List archive) {
  if (archive.length != manifest.archiveSize) {
    throw const RagBadResponse('Archive size differs from the manifest');
  }
  if (sha256.convert(archive).toString() != manifest.archiveSha256) {
    throw const RagBadResponse('Archive hash differs from the manifest');
  }
  final Map<String, Uint8List> unpacked;
  try {
    unpacked = _untar(_gunzip(archive));
  } on RagBadResponse {
    rethrow;
  } on Object {
    throw const RagBadResponse('Archive is damaged');
  }
  if (unpacked.length != manifest.files.length) {
    throw const RagBadResponse('Archive files differ from the manifest');
  }
  for (final info in manifest.files) {
    final data = unpacked[info.path];
    if (data == null ||
        data.length != info.size ||
        sha256.convert(data).toString() != info.sha256) {
      throw const RagBadResponse('Archive files differ from the manifest');
    }
  }
  return KnowledgeBundle(version: manifest.version, files: unpacked);
}

Uint8List _gunzip(Uint8List data) {
  final sink = _LimitedSink(BundleLimits.maxUnpackedBytes);
  final conversion = gzip.decoder.startChunkedConversion(sink);
  conversion
    ..add(data)
    ..close();
  return sink.takeBytes();
}

/// Stops a decompression bomb as soon as the output passes the limit.
class _LimitedSink extends ByteConversionSink {
  _LimitedSink(this._limit);

  final int _limit;
  final _out = BytesBuilder(copy: false);

  @override
  void add(List<int> chunk) {
    if (_out.length + chunk.length > _limit) {
      throw const RagBadResponse('Archive unpacks to too much data');
    }
    _out.add(chunk);
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    add(chunk.sublist(start, end));
  }

  @override
  void close() {}

  Uint8List takeBytes() => _out.takeBytes();
}

const _block = 512;
const _typeFile = 0x30; // '0'
const _typeFileOld = 0;
const _typeDir = 0x35; // '5'
const _typePax = 0x78; // 'x'
const _typePaxGlobal = 0x67; // 'g'

/// Minimal tar reader: regular files, directories and PAX path/size headers.
/// Links, devices and everything else reject the whole archive.
Map<String, Uint8List> _untar(Uint8List tar) {
  final files = <String, Uint8List>{};
  String? paxPath;
  int? paxSize;
  var pos = 0;
  while (pos + _block <= tar.length) {
    final header = Uint8List.sublistView(tar, pos, pos + _block);
    if (header.every((b) => b == 0)) break;
    _checkChecksum(header);
    final type = header[156];
    final size = paxSize ?? _octal(header, 124, 12);
    pos += _block;
    if (size < 0 || pos + size > tar.length) {
      throw const RagBadResponse('Archive is truncated');
    }
    final body = Uint8List.sublistView(tar, pos, pos + size);
    pos += (size + _block - 1) ~/ _block * _block;

    switch (type) {
      case _typePax:
        final pax = _parsePax(body);
        paxPath = pax.path ?? paxPath;
        paxSize = pax.size ?? paxSize;
        continue;
      case _typePaxGlobal:
        continue;
      case _typeDir:
        paxPath = null;
        paxSize = null;
      case _typeFile || _typeFileOld:
        final name = paxPath ?? _name(header);
        paxPath = null;
        paxSize = null;
        if (!isSafeBundlePath(name)) {
          throw const RagBadResponse('Archive contains an unsafe path');
        }
        if (files.length >= BundleLimits.maxFiles || files.containsKey(name)) {
          throw const RagBadResponse('Archive has too many or duplicate files');
        }
        files[name] = Uint8List.fromList(body);
      default:
        throw const RagBadResponse('Archive contains an unsupported entry');
    }
  }
  return files;
}

void _checkChecksum(Uint8List header) {
  var sum = 0;
  for (var i = 0; i < _block; i++) {
    sum += (i >= 148 && i < 156) ? 0x20 : header[i];
  }
  if (sum != _octal(header, 148, 8)) {
    throw const RagBadResponse('Archive header is damaged');
  }
}

int _octal(Uint8List header, int offset, int length) {
  if (header[offset] & 0x80 != 0) {
    throw const RagBadResponse('Archive uses an unsupported number format');
  }
  final text = ascii
      .decode(header.sublist(offset, offset + length), allowInvalid: true)
      .replaceAll('\u0000', ' ')
      .trim();
  if (text.isEmpty) return 0;
  return int.tryParse(text, radix: 8) ??
      (throw const RagBadResponse('Archive header is damaged'));
}

String _name(Uint8List header) {
  final name = _cString(header, 0, 100);
  final prefix = _cString(header, 345, 155);
  return prefix.isEmpty ? name : '$prefix/$name';
}

String _cString(Uint8List header, int offset, int length) {
  var end = offset;
  while (end < offset + length && header[end] != 0) {
    end++;
  }
  return utf8.decode(header.sublist(offset, end));
}

({String? path, int? size}) _parsePax(Uint8List body) {
  String? path;
  int? size;
  var pos = 0;
  while (pos < body.length) {
    final space = body.indexOf(0x20, pos);
    if (space < 0) throw const RagBadResponse('Archive header is damaged');
    final length = int.tryParse(ascii.decode(body.sublist(pos, space)));
    if (length == null || length <= space - pos || pos + length > body.length) {
      throw const RagBadResponse('Archive header is damaged');
    }
    final record = utf8.decode(body.sublist(space + 1, pos + length - 1));
    final eq = record.indexOf('=');
    if (eq > 0) {
      final key = record.substring(0, eq);
      final value = record.substring(eq + 1);
      if (key == 'path') path = value;
      if (key == 'size') size = int.tryParse(value);
    }
    pos += length;
  }
  return (path: path, size: size);
}
