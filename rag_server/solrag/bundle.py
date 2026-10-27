import hashlib
import json
import os
import tarfile
from datetime import datetime, timezone
from pathlib import Path

MANIFEST = "manifest.json"
KEEP_ARCHIVES = 2


def publish_bundle(src_dir: Path, bundle_dir: Path, version: str) -> dict:
    """Pack src_dir as the snapshot clients download. src_dir must already be scrubbed of secrets.

    Archives are named by their hash and never overwritten, so a client holding an older
    manifest still downloads a consistent archive."""
    bundle_dir.mkdir(parents=True, exist_ok=True)
    files = []
    for path in sorted(p for p in src_dir.rglob("*") if p.is_file() and not p.is_symlink()):
        data = path.read_bytes()
        files.append(
            {
                "path": path.relative_to(src_dir).as_posix(),
                "sha256": hashlib.sha256(data).hexdigest(),
                "size": len(data),
            }
        )

    tmp_archive = bundle_dir / "archive.tmp"
    with tarfile.open(tmp_archive, "w:gz") as tar:
        for entry in files:
            tar.add(src_dir / entry["path"], arcname=entry["path"], recursive=False, filter=_anonymous)
    archive_sha = _sha256_file(tmp_archive)
    os.replace(tmp_archive, bundle_dir / f"{archive_sha}.tar.gz")

    manifest = {
        "version": version,
        "created_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "archive_sha256": archive_sha,
        "archive_size": (bundle_dir / f"{archive_sha}.tar.gz").stat().st_size,
        "files": files,
    }
    tmp_manifest = bundle_dir / "manifest.tmp"
    tmp_manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
    os.replace(tmp_manifest, bundle_dir / MANIFEST)
    _prune(bundle_dir, archive_sha)
    return manifest


def read_manifest(bundle_dir: Path) -> dict | None:
    path = bundle_dir / MANIFEST
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def archive_path(bundle_dir: Path, archive_sha: str) -> Path | None:
    path = bundle_dir / f"{archive_sha}.tar.gz"
    return path if path.is_file() else None


def _anonymous(info: tarfile.TarInfo) -> tarfile.TarInfo:
    # Tar headers carry the packer's user and group names.
    info.uid = info.gid = 0
    info.uname = info.gname = ""
    info.mode = 0o755 if info.mode & 0o111 else 0o644
    return info


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 16), b""):
            digest.update(block)
    return digest.hexdigest()


def _prune(bundle_dir: Path, current_sha: str) -> None:
    archives = sorted(bundle_dir.glob("*.tar.gz"), key=lambda p: p.stat().st_mtime, reverse=True)
    keep = {current_sha}
    for path in archives:
        if len(keep) >= KEEP_ARCHIVES:
            break
        keep.add(path.name.removesuffix(".tar.gz"))
    for path in archives:
        if path.name.removesuffix(".tar.gz") not in keep:
            path.unlink(missing_ok=True)
