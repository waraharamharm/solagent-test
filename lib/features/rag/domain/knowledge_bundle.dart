import 'dart:typed_data';

/// One file listed in the bundle manifest.
class BundleFileInfo {
  const BundleFileInfo({
    required this.path,
    required this.sha256,
    required this.size,
  });

  /// Relative POSIX path, already checked: no `..`, no leading `/`.
  final String path;
  final String sha256;
  final int size;
}

/// What `GET /v1/bundle` announces. The archive is addressed by its hash.
class BundleManifest {
  const BundleManifest({
    required this.version,
    required this.archiveSha256,
    required this.archiveSize,
    required this.files,
  });

  final String version;
  final String archiveSha256;
  final int archiveSize;
  final List<BundleFileInfo> files;
}

/// The knowledge snapshot with every file verified against the manifest.
/// Kept in memory only: nothing from the archive is ever written to disk by
/// the reader, so a hostile archive cannot choose where its files land.
class KnowledgeBundle {
  const KnowledgeBundle({required this.version, required this.files});

  final String version;

  /// Relative path -> content.
  final Map<String, Uint8List> files;
}
