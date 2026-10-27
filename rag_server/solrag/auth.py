"""Client API keys. Only SHA-256 hashes are stored, so a leaked database does not leak keys.

Keys are 256-bit random strings, which is why a plain hash is enough (no salt or stretching).
Keys are issued and revoked on the server with `python -m solrag.admin`; there is no
self-registration endpoint.
"""

import hashlib
import secrets
import sqlite3
from dataclasses import dataclass

KEY_PREFIX = "sol_"
_KEY_LENGTH = len(KEY_PREFIX) + 43
_TOUCH_AFTER_SECONDS = 300


@dataclass(frozen=True)
class KeyInfo:
    id: int
    label: str


def hash_key(key: str) -> str:
    return hashlib.sha256(key.encode("utf-8")).hexdigest()


def create_key(conn: sqlite3.Connection, label: str) -> tuple[int, str]:
    """Returns (id, key). The key is shown once and cannot be recovered."""
    key = KEY_PREFIX + secrets.token_urlsafe(32)
    with conn:
        key_id = conn.execute(
            "insert into api_keys(label, key_hash) values (?, ?)", (label, hash_key(key))
        ).lastrowid
    return key_id, key


def revoke_key(conn: sqlite3.Connection, key_id: int) -> bool:
    with conn:
        cur = conn.execute(
            "update api_keys set revoked_at = datetime('now') where id = ? and revoked_at is null",
            (key_id,),
        )
    return cur.rowcount == 1


def list_keys(conn: sqlite3.Connection) -> list[sqlite3.Row]:
    return conn.execute(
        "select id, label, created_at, last_used_at, revoked_at from api_keys order by id"
    ).fetchall()


def verify_key(conn: sqlite3.Connection, key: str) -> KeyInfo | None:
    if not (key.startswith(KEY_PREFIX) and len(key) == _KEY_LENGTH and key.isascii()):
        return None
    row = conn.execute(
        "select id, label, last_used_at, "
        f"(last_used_at is null or last_used_at < datetime('now', '-{_TOUCH_AFTER_SECONDS} seconds')) as stale "
        "from api_keys where key_hash = ? and revoked_at is null",
        (hash_key(key),),
    ).fetchone()
    if row is None:
        return None
    if row["stale"]:
        with conn:
            conn.execute("update api_keys set last_used_at = datetime('now') where id = ?", (row["id"],))
    return KeyInfo(id=row["id"], label=row["label"])
