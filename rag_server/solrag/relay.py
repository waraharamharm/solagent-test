"""Push relay: the phone registers a run, the user's VDS reports checkpoints, the relay sends the push.

The FCM service account exists only on this host. A push carries the step name and state, never
log text, addresses or host names. A run token is random, stored hashed, valid for one run, and
only lets its holder send checkpoints for that run.
"""

import hashlib
import json
import logging
import re
import secrets
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol

log = logging.getLogger("solrag")

RUN_TOKEN_PREFIX = "run_"
RUN_TOKEN_LENGTH = len(RUN_TOKEN_PREFIX) + 43
RUN_TTL_HOURS = 24
STEP_PATTERN = r"^[a-z0-9][a-z0-9_.-]{0,39}$"
PUSHED_STATES = ("done", "failed", "finished")
LANGUAGES = ("en", "ru")

_TEXTS = {
    "en": {
        "done": ("Step done", "{step}"),
        "failed": ("Install failed", "Step: {step}"),
        "finished": ("Install finished", "SolAgent finished the install."),
    },
    "ru": {
        "done": ("Шаг выполнен", "{step}"),
        "failed": ("Установка не удалась", "Шаг: {step}"),
        "finished": ("Установка завершена", "SolAgent закончил установку."),
    },
}


def push_text(lang: str, step: str, state: str) -> tuple[str, str]:
    title, body = _TEXTS.get(lang, _TEXTS["en"])[state]
    return title, body.format(step=step)


def _hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


@dataclass(frozen=True)
class Run:
    id: str
    key_id: int
    fcm_token: str
    lang: str


def create_run(conn: sqlite3.Connection, key_id: int, fcm_token: str, lang: str) -> tuple[str, str]:
    """Returns (run_id, run_token). The token is shown once."""
    run_id = secrets.token_hex(8)
    token = RUN_TOKEN_PREFIX + secrets.token_urlsafe(32)
    with conn:
        conn.execute("delete from runs where expires_at < datetime('now')")
        conn.execute(
            "insert into runs(id, token_hash, key_id, fcm_token, lang, expires_at) "
            f"values (?, ?, ?, ?, ?, datetime('now', '+{RUN_TTL_HOURS} hours'))",
            (run_id, _hash(token), key_id, fcm_token, lang),
        )
    return run_id, token


def find_run(conn: sqlite3.Connection, run_id: str, token: str) -> Run | None:
    if not (token.startswith(RUN_TOKEN_PREFIX) and len(token) == RUN_TOKEN_LENGTH and token.isascii()):
        return None
    row = conn.execute(
        "select id, key_id, fcm_token, lang, token_hash from runs "
        "where id = ? and expires_at >= datetime('now')",
        (run_id,),
    ).fetchone()
    if row is None or not secrets.compare_digest(row["token_hash"], _hash(token)):
        return None
    return Run(row["id"], row["key_id"], row["fcm_token"], row["lang"])


def delete_run(conn: sqlite3.Connection, run_id: str) -> None:
    with conn:
        conn.execute("delete from runs where id = ?", (run_id,))


class PushSender(Protocol):
    available: bool

    def send(self, fcm_token: str, title: str, body: str, tag: str) -> bool:
        """False when FCM says the device token is no longer valid.

        A push with the same [tag] replaces the previous one on the phone."""


class NullSender:
    available = False

    def send(self, fcm_token: str, title: str, body: str, tag: str) -> bool:
        return True


class FcmSender:
    """FCM HTTP v1 with a service account. Needs `pip install solrag[push]`."""

    available = True
    _SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

    def __init__(self, credentials_file: Path) -> None:
        from google.auth.transport.requests import AuthorizedSession
        from google.oauth2 import service_account

        credentials = service_account.Credentials.from_service_account_file(
            str(credentials_file), scopes=[self._SCOPE]
        )
        self._project = json.loads(credentials_file.read_text(encoding="utf-8"))["project_id"]
        self._session = AuthorizedSession(credentials)

    def send(self, fcm_token: str, title: str, body: str, tag: str) -> bool:
        response = self._session.post(
            f"https://fcm.googleapis.com/v1/projects/{self._project}/messages:send",
            json={
                "message": {
                    "token": fcm_token,
                    "notification": {"title": title, "body": body},
                    "android": {"priority": "HIGH", "notification": {"tag": tag}},
                }
            },
            timeout=10,
        )
        if response.status_code in (400, 404) and "UNREGISTERED" in response.text:
            return False
        if response.status_code >= 400:
            log.warning("FCM send failed with HTTP %s", response.status_code)
        return True


def build_sender(credentials_file: Path | None) -> PushSender:
    if credentials_file is None:
        return NullSender()
    return FcmSender(credentials_file)
