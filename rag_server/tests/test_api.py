import hashlib

import pytest

from solrag import store
from solrag.bundle import publish_bundle


def _add(conn, embedder, path, text, os=None):
    store.upsert_document(conn, embedder, source="doc", path=path, text=text, os=os)


@pytest.fixture
def src(tmp_path):
    root = tmp_path / "src"
    root.mkdir()
    (root / "a.txt").write_text("hello")
    return root


def test_health_is_public_and_minimal(anon_client):
    r = anon_client.get("/v1/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


@pytest.mark.parametrize(
    "body",
    [
        {"query": ""},
        {"query": "x" * 4001},
        {"query": "x", "k": 0},
        {"query": "x", "k": 21},
        {"query": "x", "os": "Ubuntu"},
        {"query": "x", "os": "../etc"},
        {"query": "x", "os": "a" * 40},
        {"query": "x", "os": ""},
        {},
    ],
)
def test_search_validation(client, body):
    assert client.post("/v1/search", json=body).status_code == 422


def test_search_accepts_boundaries(client):
    assert client.post("/v1/search", json={"query": "x" * 4000, "k": 20, "os": "a" * 32}).status_code == 200
    assert client.post("/v1/search", json={"query": "x", "k": 1, "os": "ubuntu-24.04"}).status_code == 200


def test_search_result_shape(client, conn, embedder):
    _add(conn, embedder, "sip.md", "port 5060 already in use")
    r = client.post("/v1/search", json={"query": "port 5060"})
    assert r.status_code == 200
    results = r.json()["results"]
    assert len(results) == 1
    assert set(results[0]) == {"chunk_id", "source", "path", "text", "score"}
    assert results[0]["path"] == "sip.md"
    assert results[0]["source"] == "doc"


def test_search_respects_os_filter(client, conn, embedder):
    _add(conn, embedder, "u.md", "common topic", os="ubuntu")
    assert client.post("/v1/search", json={"query": "common topic", "os": "debian-12"}).json()["results"] == []
    assert len(client.post("/v1/search", json={"query": "common topic", "os": "ubuntu-24.04"}).json()["results"]) == 1


def test_submit_solution(client):
    r = client.post("/v1/solutions", json={"error": "boom", "solution": "fix", "os": "ubuntu"})
    assert r.status_code == 202
    body = r.json()
    assert body["status"] == "pending"
    assert isinstance(body["id"], int)


@pytest.mark.parametrize(
    "body",
    [
        {"error": "", "solution": "fix"},
        {"error": "boom", "solution": ""},
        {"error": "boom", "solution": "x" * 2001},
        {"error": "x" * 4001, "solution": "fix"},
        {"error": "boom", "solution": "fix", "os": "Bad OS"},
        {"error": "boom"},
    ],
)
def test_submit_solution_validation(client, body):
    assert client.post("/v1/solutions", json=body).status_code == 422


def test_submitted_solution_is_moderated_not_searchable(client, conn):
    client.post("/v1/solutions", json={"error": "weirderrorzzz", "solution": "uniquefixqqq"})
    assert store.counts(conn)["pending_solutions"] == 1
    for word in ("uniquefixqqq", "weirderrorzzz"):
        assert client.post("/v1/search", json={"query": word}).json()["results"] == []
    client.post("/v1/solutions", json={"error": "e", "solution": "s"})
    assert store.counts(conn)["pending_solutions"] == 2


def test_bundle_manifest_404_before_publish(client):
    assert client.get("/v1/bundle").status_code == 404


def test_bundle_flow(client, settings, src):
    manifest = publish_bundle(src, settings.bundle_dir, "v1")

    r = client.get("/v1/bundle")
    assert r.status_code == 200
    assert r.json() == manifest
    sha = manifest["archive_sha256"]
    r = client.get(f"/v1/bundle/archive/{sha}")
    assert r.status_code == 200
    assert hashlib.sha256(r.content).hexdigest() == sha
    assert "immutable" in r.headers["cache-control"]


@pytest.mark.parametrize("sha", ["zz", "A" * 64, "a" * 63, "a" * 65])
def test_archive_invalid_sha_is_422(client, sha):
    assert client.get(f"/v1/bundle/archive/{sha}").status_code == 422


def test_archive_path_traversal_rejected(client):
    assert client.get("/v1/bundle/archive/../x").status_code in (404, 422)


def test_archive_unknown_sha_is_404(client, settings, src):
    publish_bundle(src, settings.bundle_dir, "v1")
    assert client.get(f"/v1/bundle/archive/{'0' * 64}").status_code == 404
