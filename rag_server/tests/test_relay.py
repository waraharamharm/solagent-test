import pytest
from fastapi.testclient import TestClient

from solrag import relay
from solrag.api import create_app

FCM_TOKEN = "d" * 60


class FakeSender:
    available = True

    def __init__(self) -> None:
        self.sent: list[tuple[str, str, str]] = []
        self.tags: list[str] = []
        self.valid = True

    def send(self, fcm_token: str, title: str, body: str, tag: str) -> bool:
        self.sent.append((fcm_token, title, body))
        self.tags.append(tag)
        return self.valid


@pytest.fixture
def sender() -> FakeSender:
    return FakeSender()


@pytest.fixture
def relay_client(settings, embedder, sender, api_key):
    with TestClient(create_app(settings, embedder, push_sender=sender)) as c:
        c.headers["Authorization"] = f"Bearer {api_key}"
        yield c


def _start(client, lang="en") -> tuple[str, str]:
    r = client.post("/v1/runs", json={"fcm_token": FCM_TOKEN, "lang": lang})
    assert r.status_code == 201, r.text
    body = r.json()
    return body["run_id"], body["run_token"]


def _report(client, run_id, token, step="build", state="done"):
    return client.post(
        f"/v1/runs/{run_id}/checkpoints",
        json={"step": step, "state": state},
        headers={"Authorization": f"Bearer {token}"},
    )


def test_run_needs_the_api_key(anon_client):
    r = anon_client.post("/v1/runs", json={"fcm_token": FCM_TOKEN})
    assert r.status_code == 401


def test_checkpoint_sends_a_push_with_only_step_and_state(relay_client, sender):
    run_id, token = _start(relay_client)
    r = _report(relay_client, run_id, token, step="deps", state="done")
    assert r.status_code == 200 and r.json() == {"pushed": True}
    assert sender.sent == [(FCM_TOKEN, "Step done", "deps")]


def test_pushes_of_one_run_share_a_tag_so_they_replace_each_other(relay_client, sender):
    run_id, token = _start(relay_client)
    _report(relay_client, run_id, token, step="a", state="done")
    _report(relay_client, run_id, token, step="b", state="done")
    other_id, other_token = _start(relay_client)
    _report(relay_client, other_id, other_token, step="c", state="done")
    assert sender.tags == [run_id, run_id, other_id]


def test_push_uses_the_registered_language(relay_client, sender):
    run_id, token = _start(relay_client, lang="ru")
    _report(relay_client, run_id, token, state="failed", step="build")
    assert sender.sent[0][1:] == ("Установка не удалась", "Шаг: build")


def test_started_is_accepted_but_not_pushed(relay_client, sender):
    run_id, token = _start(relay_client)
    r = _report(relay_client, run_id, token, state="started")
    assert r.status_code == 200 and r.json() == {"pushed": False}
    assert sender.sent == []


def test_finished_ends_the_run(relay_client, sender):
    run_id, token = _start(relay_client)
    assert _report(relay_client, run_id, token, state="finished").json() == {"pushed": True}
    assert _report(relay_client, run_id, token, state="done").status_code == 401


def test_wrong_token_or_run_is_rejected_without_a_push(relay_client, sender):
    run_id, token = _start(relay_client)
    other_id, other_token = _start(relay_client)
    assert _report(relay_client, run_id, other_token).status_code == 401
    assert _report(relay_client, "0" * 16, token).status_code == 401
    assert _report(relay_client, run_id, "run_" + "x" * 43).status_code == 401
    assert sender.sent == []


def test_the_api_key_cannot_report_checkpoints(relay_client, api_key, sender):
    run_id, _ = _start(relay_client)
    assert _report(relay_client, run_id, api_key).status_code == 401


def test_step_and_state_are_validated(relay_client, sender):
    run_id, token = _start(relay_client)
    for step, state in [("Bad Step", "done"), ("../x", "done"), ("build", "exploded"), ("a" * 41, "done")]:
        assert _report(relay_client, run_id, token, step=step, state=state).status_code == 422
    assert sender.sent == []


def test_a_failed_step_keeps_the_run_so_a_fix_can_continue(relay_client, sender):
    run_id, token = _start(relay_client)
    assert _report(relay_client, run_id, token, state="failed").json() == {"pushed": True}
    assert _report(relay_client, run_id, token, state="finished").json() == {"pushed": True}
    assert len(sender.sent) == 2


def test_run_is_dropped_when_fcm_says_the_device_is_gone(relay_client, sender):
    run_id, token = _start(relay_client)
    sender.valid = False
    assert _report(relay_client, run_id, token).json() == {"pushed": False}
    assert _report(relay_client, run_id, token).status_code == 401


def test_expired_run_is_rejected(relay_client, settings, sender):
    import solrag.db

    run_id, token = _start(relay_client)
    conn = solrag.db.connect(settings.db_path)
    with conn:
        conn.execute("update runs set expires_at = datetime('now', '-1 minute')")
    conn.close()
    assert _report(relay_client, run_id, token).status_code == 401


def test_token_is_stored_hashed(relay_client, settings):
    import solrag.db

    _, token = _start(relay_client)
    conn = solrag.db.connect(settings.db_path)
    try:
        stored = conn.execute("select token_hash from runs").fetchone()[0]
    finally:
        conn.close()
    assert token not in stored and len(stored) == 64


def test_without_fcm_credentials_runs_are_unavailable(settings, embedder, api_key):
    with TestClient(create_app(settings, embedder)) as c:
        c.headers["Authorization"] = f"Bearer {api_key}"
        r = c.post("/v1/runs", json={"fcm_token": FCM_TOKEN})
    assert r.status_code == 503 and r.json()["code"] == "push_unavailable"


def test_checkpoint_rate_limit(settings, embedder, sender, api_key):
    limited = type(settings)(
        data_dir=settings.data_dir, model_cache=settings.model_cache, checkpoints_per_hour=2
    )
    with TestClient(create_app(limited, embedder, push_sender=sender)) as c:
        c.headers["Authorization"] = f"Bearer {api_key}"
        run_id, token = _start(c)
        codes = [_report(c, run_id, token, state="started").status_code for _ in range(3)]
    assert codes == [200, 200, 429]


def test_push_text_falls_back_to_english():
    assert relay.push_text("xx", "build", "done") == ("Step done", "build")
