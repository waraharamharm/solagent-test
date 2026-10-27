import io
import json

import pytest
from fastapi.testclient import TestClient

import solrag.auth
import solrag.db
from solrag import admin, moderation, store
from solrag.api import create_app
from solrag.config import Settings
from solrag.ratelimit import SlidingWindowLimiter
from solrag.scrub import Scrubber

PROTECTED = [
    ("post", "/v1/search", {"json": {"query": "x"}}),
    ("get", "/v1/bundle", {}),
    ("get", f"/v1/bundle/archive/{'0' * 64}", {}),
    ("post", "/v1/solutions", {"json": {"error": "e", "solution": "s"}}),
]


def _assert_error(response, status, code):
    body = response.json()
    assert response.status_code == status
    assert set(body) == {"status", "code", "message"}
    assert body["code"] == code


class FakeClock:
    def __init__(self) -> None:
        self.now = 1000.0

    def __call__(self) -> float:
        return self.now


def _app_client(settings, embedder, clock=None):
    return TestClient(create_app(settings, embedder, clock))


def _issue_key(settings, label="t") -> tuple[int, str]:
    conn = solrag.db.connect(settings.db_path)
    try:
        return solrag.auth.create_key(conn, label)
    finally:
        conn.close()


# ---- authentication

@pytest.mark.parametrize(("method", "path", "kwargs"), PROTECTED)
def test_protected_endpoints_need_a_key(anon_client, method, path, kwargs):
    _assert_error(getattr(anon_client, method)(path, **kwargs), 401, "unauthorized")


@pytest.mark.parametrize(
    "header",
    ["Bearer", "Bearer ", "Basic abc", "sol_x", "Bearer sol_" + "a" * 43, "Bearer " + "a" * 47],
)
def test_bad_keys_are_rejected(anon_client, header):
    r = anon_client.post("/v1/search", json={"query": "x"}, headers={"Authorization": header})
    _assert_error(r, 401, "unauthorized")
    assert r.headers["www-authenticate"] == "Bearer"


def test_valid_key_works_and_is_stored_hashed(client, api_key, conn):
    assert client.post("/v1/search", json={"query": "x"}).status_code == 200
    row = conn.execute("select key_hash from api_keys").fetchone()
    assert row["key_hash"] == solrag.auth.hash_key(api_key)
    assert api_key not in row["key_hash"]


def test_revoked_key_stops_working(client, conn):
    key_id = conn.execute("select id from api_keys").fetchone()["id"]
    assert solrag.auth.revoke_key(conn, key_id)
    _assert_error(client.post("/v1/search", json={"query": "x"}), 401, "unauthorized")
    assert not solrag.auth.revoke_key(conn, key_id)


def test_unauthenticated_request_does_not_get_validation_details(anon_client):
    _assert_error(anon_client.post("/v1/search", json={"nope": 1}), 401, "unauthorized")


def test_failed_attempts_lock_the_ip_out(settings, embedder):
    clock = FakeClock()
    with _app_client(settings, embedder, clock) as c:
        key = _issue_key(settings)[1]
        for _ in range(settings.auth_failures_per_minute):
            _assert_error(c.post("/v1/search", json={"query": "x"}), 401, "unauthorized")
        locked = c.post(
            "/v1/search", json={"query": "x"}, headers={"Authorization": f"Bearer {key}"}
        )
        _assert_error(locked, 429, "too_many_failures")
        assert int(locked.headers["retry-after"]) >= 1
        clock.now += 61
        ok = c.post("/v1/search", json={"query": "x"}, headers={"Authorization": f"Bearer {key}"})
        assert ok.status_code == 200


# ---- rate limits

def test_search_rate_limit_is_per_key(settings, embedder):
    limited = Settings(settings.data_dir, settings.model_cache, search_per_minute=3)
    clock = FakeClock()
    with _app_client(limited, embedder, clock) as c:
        a, b = _issue_key(limited, "a")[1], _issue_key(limited, "b")[1]
        ha, hb = {"Authorization": f"Bearer {a}"}, {"Authorization": f"Bearer {b}"}
        for _ in range(3):
            assert c.post("/v1/search", json={"query": "x"}, headers=ha).status_code == 200
        over = c.post("/v1/search", json={"query": "x"}, headers=ha)
        _assert_error(over, 429, "rate_limited")
        assert int(over.headers["retry-after"]) >= 1
        assert c.post("/v1/search", json={"query": "x"}, headers=hb).status_code == 200
        clock.now += 61
        assert c.post("/v1/search", json={"query": "x"}, headers=ha).status_code == 200


def test_solution_rate_limit(settings, embedder):
    limited = Settings(settings.data_dir, settings.model_cache, solutions_per_hour=2)
    with _app_client(limited, embedder, FakeClock()) as c:
        h = {"Authorization": f"Bearer {_issue_key(limited)[1]}"}
        for i in range(2):
            assert c.post("/v1/solutions", json={"error": f"e{i}", "solution": "s"}, headers=h).status_code == 202
        _assert_error(
            c.post("/v1/solutions", json={"error": "e9", "solution": "s"}, headers=h), 429, "rate_limited"
        )


def test_limiter_window_and_retry_after():
    clock = FakeClock()
    lim = SlidingWindowLimiter(clock)
    assert lim.check("k", 2, 10) is None
    clock.now += 4
    assert lim.check("k", 2, 10) is None
    wait = lim.check("k", 2, 10)
    assert wait == pytest.approx(6.0)
    clock.now += 6.1
    assert lim.check("k", 2, 10) is None


# ---- request size

def test_oversized_body_is_rejected_with_json_error(client):
    r = client.post("/v1/search", content=b"x" * 40000, headers={"Content-Type": "application/json"})
    _assert_error(r, 413, "payload_too_large")


def test_oversized_chunked_body_is_rejected(client):
    def chunks():
        for _ in range(10):
            yield b"x" * 4000

    r = client.post("/v1/search", content=chunks(), headers={"Content-Type": "application/json"})
    _assert_error(r, 413, "payload_too_large")


# ---- submissions

def test_submission_is_scrubbed_before_storage(client, conn):
    r = client.post(
        "/v1/solutions",
        json={"error": "login failed password=hunter2hunter2 at 8.8.8.8", "solution": "set token=abcdefgh12345678"},
    )
    assert r.status_code == 202
    row = conn.execute("select error, solution from solutions").fetchone()
    assert "hunter2hunter2" not in row["error"] and "8.8.8.8" not in row["error"]
    assert "abcdefgh12345678" not in row["solution"]


def test_submission_with_private_key_is_refused_or_cleaned(client, conn):
    pem = "-----BEGIN OPENSSH PRIVATE KEY-----\nabc\n-----END OPENSSH PRIVATE KEY-----"
    r = client.post("/v1/solutions", json={"error": "e", "solution": pem})
    stored = [row["solution"] for row in conn.execute("select solution from solutions")]
    assert all("PRIVATE KEY-----\nabc" not in s for s in stored)
    assert r.status_code in (202, 422)


def test_identical_submission_does_not_grow_the_queue(client, conn):
    body = {"error": "same error", "solution": "same fix"}
    first = client.post("/v1/solutions", json=body).json()
    second = client.post("/v1/solutions", json=body).json()
    assert first == second
    assert conn.execute("select count(*) from solutions").fetchone()[0] == 1


def test_pending_queue_cap_per_key(settings, embedder):
    capped = Settings(settings.data_dir, settings.model_cache, max_pending_per_key=2)
    with _app_client(capped, embedder) as c:
        h = {"Authorization": f"Bearer {_issue_key(capped)[1]}"}
        for i in range(2):
            assert c.post("/v1/solutions", json={"error": f"e{i}", "solution": "s"}, headers=h).status_code == 202
        _assert_error(
            c.post("/v1/solutions", json={"error": "e9", "solution": "s"}, headers=h), 429, "queue_full"
        )


def test_submission_records_the_key(client, conn):
    client.post("/v1/solutions", json={"error": "e", "solution": "s"})
    key_id = conn.execute("select id from api_keys").fetchone()["id"]
    assert conn.execute("select key_id from solutions").fetchone()["key_id"] == key_id


# ---- moderation

def _pending(conn, error="port busy", solution="stop the other service", os="ubuntu"):
    return store.add_solution(conn, error=error, solution=solution, os=os)[0]


def test_approve_makes_it_searchable_with_os_filter(client, conn, embedder):
    solution_id = _pending(conn, error="uniqueerrorzzz", solution="uniquefixqqq")
    assert client.post("/v1/search", json={"query": "uniquefixqqq"}).json()["results"] == []

    moderation.approve(conn, embedder, Scrubber(), solution_id)

    hits = client.post("/v1/search", json={"query": "uniquefixqqq", "os": "ubuntu"}).json()["results"]
    assert hits and hits[0]["source"] == "solution" and "uniquefixqqq" in hits[0]["text"]
    assert client.post("/v1/search", json={"query": "uniquefixqqq", "os": "debian"}).json()["results"] == []
    assert moderation.get_solution(conn, solution_id)["status"] == "approved"


def test_reject_keeps_it_out_and_cannot_be_approved(client, conn, embedder):
    solution_id = _pending(conn, error="rejectedtopic", solution="rejectedfix")
    moderation.reject(conn, solution_id)
    assert client.post("/v1/search", json={"query": "rejectedfix"}).json()["results"] == []
    with pytest.raises(moderation.ModerationError):
        moderation.approve(conn, embedder, Scrubber(), solution_id)


def test_withdraw_removes_an_approved_solution(client, conn, embedder):
    solution_id = _pending(conn, error="withdrawtopic", solution="withdrawfix")
    moderation.approve(conn, embedder, Scrubber(), solution_id)
    moderation.withdraw(conn, solution_id)
    assert client.post("/v1/search", json={"query": "withdrawfix"}).json()["results"] == []
    assert store.counts(conn)["chunks"] == 0


def test_approve_rechecks_secrets_with_current_literals(conn, embedder):
    solution_id = _pending(conn, error="deploy to acmecorp-internal", solution="restart it")
    leaky = Scrubber(literals={"acmecorp-internal": "HOST"})
    with pytest.raises(moderation.ModerationError, match="secrets"):
        moderation.approve(conn, embedder, leaky, solution_id)
    assert moderation.get_solution(conn, solution_id)["status"] == "pending"
    assert store.counts(conn)["chunks"] == 0


def test_unknown_solution_id(conn, embedder):
    with pytest.raises(moderation.ModerationError):
        moderation.approve(conn, embedder, Scrubber(), 999)


# ---- admin CLI

def _cli(settings, embedder, *argv):
    out = io.StringIO()
    code = admin.run(list(argv), settings, out, lambda: embedder)
    return code, out.getvalue()


def test_cli_key_lifecycle(settings, embedder):
    code, text = _cli(settings, embedder, "key-create", "--label", "phone")
    key = text.strip().splitlines()[-1]
    assert code == 0 and key.startswith("sol_")
    _, listing = _cli(settings, embedder, "key-list")
    assert "phone" in listing and "active" in listing and key not in listing
    code, _ = _cli(settings, embedder, "key-revoke", "1")
    assert code == 0
    assert "revoked" in _cli(settings, embedder, "key-list")[1]
    assert _cli(settings, embedder, "key-revoke", "1")[0] == 1


def test_cli_moderation_flow(settings, embedder):
    with _app_client(settings, embedder) as c:
        h = {"Authorization": f"Bearer {_issue_key(settings)[1]}"}
        solution_id = c.post(
            "/v1/solutions", json={"error": "cliproblemzzz", "solution": "clifixqqq"}, headers=h
        ).json()["id"]

        code, text = _cli(settings, embedder, "pending")
        assert code == 0 and "cliproblemzzz" in text and "1 pending" in text
        assert "clifixqqq" in _cli(settings, embedder, "show", str(solution_id))[1]

        assert _cli(settings, embedder, "approve", str(solution_id))[0] == 0
        assert c.post("/v1/search", json={"query": "clifixqqq"}, headers=h).json()["results"]
        assert _cli(settings, embedder, "approve", str(solution_id))[0] == 1
        assert _cli(settings, embedder, "withdraw", str(solution_id))[0] == 0
        assert c.post("/v1/search", json={"query": "clifixqqq"}, headers=h).json()["results"] == []


def test_literals_file_is_used_for_submissions(tmp_path, settings, embedder):
    literals = tmp_path / "lit.json"
    literals.write_text(json.dumps({"acmecorp-internal": "HOST"}))
    configured = Settings(settings.data_dir, settings.model_cache, scrub_literals=literals)
    with _app_client(configured, embedder) as c:
        h = {"Authorization": f"Bearer {_issue_key(configured)[1]}"}
        c.post("/v1/solutions", json={"error": "down at acmecorp-internal", "solution": "restart"}, headers=h)
        conn = solrag.db.connect(configured.db_path)
        try:
            assert "acmecorp-internal" not in conn.execute("select error from solutions").fetchone()["error"]
        finally:
            conn.close()
