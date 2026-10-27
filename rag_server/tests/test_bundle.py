import hashlib
import os
import tarfile

import pytest

from solrag import bundle


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


@pytest.fixture
def src(tmp_path):
    root = tmp_path / "src"
    (root / "sub" / "deep").mkdir(parents=True)
    (root / "b.txt").write_bytes(b"bbb")
    (root / "a.txt").write_bytes(b"a")
    (root / "sub" / "c.md").write_bytes("привет".encode("utf-8"))
    (root / "sub" / "deep" / "d.bin").write_bytes(b"\x00\x01\x02")
    return root


@pytest.fixture
def bundle_dir(tmp_path):
    return tmp_path / "bundle"


def test_manifest_contents(src, bundle_dir):
    manifest = bundle.publish_bundle(src, bundle_dir, "v1")
    assert manifest["version"] == "v1"
    paths = [f["path"] for f in manifest["files"]]
    assert paths == sorted(paths)
    assert paths == ["a.txt", "b.txt", "sub/c.md", "sub/deep/d.bin"]
    for entry in manifest["files"]:
        data = (src / entry["path"]).read_bytes()
        assert entry["sha256"] == _sha(data)
        assert entry["size"] == len(data)


def test_archive_sha_and_size_match_file(src, bundle_dir):
    manifest = bundle.publish_bundle(src, bundle_dir, "v1")
    archive = bundle.archive_path(bundle_dir, manifest["archive_sha256"])
    assert archive is not None
    assert _sha(archive.read_bytes()) == manifest["archive_sha256"]
    assert archive.stat().st_size == manifest["archive_size"]


def test_read_manifest_returns_published_manifest(src, bundle_dir):
    manifest = bundle.publish_bundle(src, bundle_dir, "v1")
    assert bundle.read_manifest(bundle_dir) == manifest


def test_read_manifest_none_when_unpublished(bundle_dir):
    assert bundle.read_manifest(bundle_dir) is None


def test_archive_path_unknown_sha(src, bundle_dir):
    bundle.publish_bundle(src, bundle_dir, "v1")
    assert bundle.archive_path(bundle_dir, "0" * 64) is None


def test_tar_members_match_manifest_and_are_anonymous(src, bundle_dir):
    manifest = bundle.publish_bundle(src, bundle_dir, "v1")
    archive = bundle.archive_path(bundle_dir, manifest["archive_sha256"])
    with tarfile.open(archive, "r:gz") as tar:
        members = tar.getmembers()
        assert [m.name for m in members] == [f["path"] for f in manifest["files"]]
        for m in members:
            assert m.uname == ""
            assert m.gname == ""
            assert m.uid == 0
            assert m.gid == 0
            assert m.mode in (0o644, 0o755)
        extracted = tar.extractfile("sub/c.md").read()
    assert extracted == "привет".encode("utf-8")


def test_symlinks_are_skipped(src, bundle_dir):
    try:
        os.symlink(src / "a.txt", src / "link.txt")
    except (OSError, NotImplementedError):
        pytest.skip("symlinks not available")
    manifest = bundle.publish_bundle(src, bundle_dir, "v1")
    assert "link.txt" not in [f["path"] for f in manifest["files"]]
    with tarfile.open(bundle.archive_path(bundle_dir, manifest["archive_sha256"]), "r:gz") as tar:
        assert "link.txt" not in tar.getnames()


def test_republish_same_content_keeps_single_archive(src, bundle_dir):
    first = bundle.publish_bundle(src, bundle_dir, "v1")
    second = bundle.publish_bundle(src, bundle_dir, "v1")
    assert first["archive_sha256"] == second["archive_sha256"]
    assert len(list(bundle_dir.glob("*.tar.gz"))) == 1


def test_republish_changed_content_creates_new_archive(src, bundle_dir):
    first = bundle.publish_bundle(src, bundle_dir, "v1")
    (src / "a.txt").write_bytes(b"changed")
    second = bundle.publish_bundle(src, bundle_dir, "v2")
    assert first["archive_sha256"] != second["archive_sha256"]
    assert bundle.archive_path(bundle_dir, first["archive_sha256"]) is not None
    assert bundle.archive_path(bundle_dir, second["archive_sha256"]) is not None
    assert bundle.read_manifest(bundle_dir)["version"] == "v2"


def test_keeps_at_most_two_archives(src, bundle_dir):
    shas = []
    for i in range(3):
        (src / "a.txt").write_bytes(f"version {i}".encode())
        shas.append(bundle.publish_bundle(src, bundle_dir, f"v{i}")["archive_sha256"])
    assert len(list(bundle_dir.glob("*.tar.gz"))) == 2
    assert bundle.archive_path(bundle_dir, shas[2]) is not None
    assert bundle.archive_path(bundle_dir, shas[0]) is None
