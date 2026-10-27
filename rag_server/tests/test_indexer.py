import json
import tarfile

import pytest

from solrag import store
from solrag.indexer import LeakError, SourcePolicy, build_knowledge
from solrag.scrub import Scrubber
from solrag.search import hybrid_search

SECRET = "Xm!bc792726729decef?aA"


@pytest.fixture
def src(tmp_path):
    root = tmp_path / "src"
    (root / "deploy-xdexboard" / "etc-secrets").mkdir(parents=True)
    (root / "deploy-xdexboard" / "vendor").mkdir()
    (root / "docs").mkdir()
    (root / "other").mkdir()
    (root / "deploy-xdexboard" / "flexisip.conf").write_text(
        f"soci-connection-string=db=x user=f password='{SECRET}' host=95.27.113.59\r\n", encoding="utf-8"
    )
    (root / "deploy-xdexboard" / "install-on-mybox.sh").write_text("echo mybox up\n", encoding="utf-8")
    (root / "deploy-xdexboard" / "etc-secrets" / "a.env").write_text("TOKEN=abc123def456\n", encoding="utf-8")
    (root / "deploy-xdexboard" / "vendor" / "lib.php").write_text("<?php // third party", encoding="utf-8")
    (root / "docs" / "PUSH.md").write_text("Push goes through FCM on mybox.\n", encoding="utf-8")
    (root / "docs" / "CREDENTIALS_STORAGE.md").write_text("root password is hunter2x\n", encoding="utf-8")
    (root / "other" / "notes.md").write_text("not in the allowlist", encoding="utf-8")
    (root / "docs" / "blob.bin").write_bytes(b"\xff\xfe\x00\x01")
    return root


@pytest.fixture
def scrubber():
    return Scrubber(literals={"mybox": "node1"})


def _build(src, tmp_path, conn, embedder, scrubber):
    return build_knowledge(src, tmp_path / "out", conn, embedder, scrubber, tmp_path / "bundle")


def test_only_allowlisted_scrubbed_files_are_published(src, tmp_path, conn, embedder, scrubber):
    report = _build(src, tmp_path, conn, embedder, scrubber)

    assert sorted(report.indexed) == [
        "deploy-xdexboard/flexisip.conf",
        "deploy-xdexboard/install-on-node1.sh",
        "docs/PUSH.md",
    ]
    assert report.skipped == [("docs/blob.bin", "not utf-8 text")]

    out = tmp_path / "out"
    conf = (out / "deploy-xdexboard" / "flexisip.conf").read_text(encoding="utf-8")
    assert SECRET not in conf and "95.27.113.59" not in conf and "\r" not in conf
    assert "password='REDACTED'" in conf
    assert (out / "docs" / "PUSH.md").read_text(encoding="utf-8") == "Push goes through FCM on node1.\n"


def test_nothing_secret_reaches_database_or_bundle(src, tmp_path, conn, embedder, scrubber):
    report = _build(src, tmp_path, conn, embedder, scrubber)

    blob = " ".join(r[0] for r in conn.execute("select text from chunks")) + " ".join(
        r[0] for r in conn.execute("select path from documents")
    )
    for needle in (SECRET, "95.27.113.59", "mybox", "hunter2x", "abc123def456"):
        assert needle not in blob

    archive = next((tmp_path / "bundle").glob("*.tar.gz"))
    with tarfile.open(archive) as tar:
        names = tar.getnames()
        content = b"".join(tar.extractfile(n).read() for n in names)
    assert not any("mybox" in n or "etc-secrets" in n for n in names)
    assert SECRET.encode() not in content and b"mybox" not in content
    assert json.loads((tmp_path / "bundle" / "manifest.json").read_text())["version"] == report.version


def test_search_finds_scrubbed_content(src, tmp_path, conn, embedder, scrubber):
    _build(src, tmp_path, conn, embedder, scrubber)
    hits = hybrid_search(conn, embedder, "FCM push", os=None, k=3)
    assert hits[0].path == "docs/PUSH.md"
    assert hits[0].source == "doc"


def test_rebuild_is_idempotent_and_removes_deleted_files(src, tmp_path, conn, embedder, scrubber):
    first = _build(src, tmp_path, conn, embedder, scrubber)
    calls = embedder.passage_calls
    again = _build(src, tmp_path, conn, embedder, scrubber)
    assert again.version == first.version
    assert embedder.passage_calls == calls

    (src / "docs" / "PUSH.md").unlink()
    third = _build(src, tmp_path, conn, embedder, scrubber)
    assert third.removed == ["docs/PUSH.md"]
    assert store.counts(conn)["documents"] == 2
    assert not (tmp_path / "out" / "docs" / "PUSH.md").exists()


def test_leak_aborts_before_anything_is_written(src, tmp_path, conn, embedder, scrubber, monkeypatch):
    monkeypatch.setattr(Scrubber, "find_leaks", lambda self, text, rel="": ["content: planted"])
    with pytest.raises(LeakError):
        _build(src, tmp_path, conn, embedder, scrubber)
    assert store.counts(conn)["documents"] == 0
    assert not (tmp_path / "out").exists()
    assert not (tmp_path / "bundle").exists()


def test_two_files_colliding_after_scrub_abort(src, tmp_path, conn, embedder):
    (src / "docs" / "a-mybox.md").write_text("one", encoding="utf-8")
    (src / "docs" / "a-other.md").write_text("two", encoding="utf-8")
    colliding = Scrubber(literals={"mybox": "x", "other": "x"})
    with pytest.raises(LeakError):
        _build(src, tmp_path, conn, embedder, colliding)


def test_output_keeps_git_dir_and_refuses_overlap(src, tmp_path, conn, embedder, scrubber):
    out = tmp_path / "out"
    (out / ".git").mkdir(parents=True)
    (out / ".git" / "HEAD").write_text("ref", encoding="utf-8")
    (out / "stale.txt").write_text("old", encoding="utf-8")
    _build(src, tmp_path, conn, embedder, scrubber)
    assert (out / ".git" / "HEAD").exists() and not (out / "stale.txt").exists()

    for bad in (src, src / "docs", tmp_path):
        with pytest.raises(ValueError):
            build_knowledge(src, bad, conn, embedder, scrubber, tmp_path / "bundle")


def test_policy_allows():
    p = SourcePolicy()
    assert p.allows("docs/FLEXISIP.md")
    assert p.allows("deploy-xdexboard/xdexboard-chat.env.example")
    assert not p.allows("deploy-xdexboard/xdexboard-chat.env")
    assert not p.allows("deploy-xdexboard/vendor/lime-server/src/lime.php")
    assert not p.allows("deploy-xdexboard/secrets/firebase-service-account.json")
    assert not p.allows("deploy/flexisip.conf")
    assert not p.allows("docs/CREDENTIALS_STORAGE.md")
    assert not p.allows("docsx/a.md")
