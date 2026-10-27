import pytest
from fastapi.testclient import TestClient

import solrag.auth
import solrag.db
from solrag.api import create_app


def _assert_error(response, status, code):
    body = response.json()
    assert response.status_code == status
    assert set(body) == {"status", "code", "message"}
    assert body["status"] == status
    assert body["code"] == code
    assert body["message"].isascii() and body["message"]


def test_unpublished_bundle(client):
    _assert_error(client.get("/v1/bundle"), 404, "bundle_not_published")


def test_unknown_archive(client):
    _assert_error(client.get(f"/v1/bundle/archive/{'0' * 64}"), 404, "archive_not_found")


def test_unknown_route(client):
    _assert_error(client.get("/v1/nope"), 404, "not_found")


def test_wrong_method(client):
    _assert_error(client.get("/v1/search"), 405, "method_not_allowed")


def test_validation_error_names_field_and_hides_input(client):
    secret = "hunter2-" * 600
    response = client.post("/v1/search", json={"query": secret})
    _assert_error(response, 422, "validation_error")
    assert response.json()["message"].startswith("query:")
    assert "hunter2" not in response.text


def test_malformed_json(client):
    response = client.post("/v1/search", content=b"{", headers={"content-type": "application/json"})
    _assert_error(response, 422, "validation_error")


def test_unexpected_error_does_not_leak_details(settings, embedder, monkeypatch):
    def boom(*args, **kwargs):
        raise RuntimeError("secret internal path /root/x")

    monkeypatch.setattr("solrag.api.hybrid_search", boom)
    with TestClient(create_app(settings, embedder), raise_server_exceptions=False) as c:
        connection = solrag.db.connect(settings.db_path)
        key = solrag.auth.create_key(connection, "t")[1]
        connection.close()
        response = c.post(
            "/v1/search", json={"query": "x"}, headers={"Authorization": f"Bearer {key}"}
        )
    _assert_error(response, 500, "internal_error")
    assert "secret" not in response.text
