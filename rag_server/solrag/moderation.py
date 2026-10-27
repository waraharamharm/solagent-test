"""Moderation of user-submitted solutions.

A submission is cleaned of secrets and stored as `pending`; it is not searchable. Only a
human decision (`approve`, run on the server) indexes it. Approved text is served to every
client, so it is checked for leaks again at that moment.
"""

import sqlite3

from .embedder import Embedder
from .scrub import Scrubber
from .store import delete_document, upsert_document


class ModerationError(Exception):
    pass


def solution_text(error: str, solution: str) -> str:
    return f"Error:\n{error}\n\nFix:\n{solution}"


def solution_path(solution_id: int) -> str:
    return f"solution/{solution_id}"


def list_pending(conn: sqlite3.Connection) -> list[sqlite3.Row]:
    return conn.execute(
        "select id, os, created_at, key_id, substr(error, 1, 80) as error "
        "from solutions where status = 'pending' order by id"
    ).fetchall()


def get_solution(conn: sqlite3.Connection, solution_id: int) -> sqlite3.Row:
    row = conn.execute("select * from solutions where id = ?", (solution_id,)).fetchone()
    if row is None:
        raise ModerationError(f"solution {solution_id} not found")
    return row


def approve(conn: sqlite3.Connection, embedder: Embedder, scrubber: Scrubber, solution_id: int) -> None:
    row = get_solution(conn, solution_id)
    if row["status"] != "pending":
        raise ModerationError(f"solution {solution_id} is {row['status']}, not pending")
    text = solution_text(row["error"], row["solution"])
    if scrubber.find_leaks(text) or scrubber.scrub(text) != text:
        raise ModerationError(f"solution {solution_id} still looks like it contains secrets; reject it")
    upsert_document(
        conn, embedder, source="solution", path=solution_path(solution_id), text=text, os=row["os"]
    )
    _set_status(conn, solution_id, "approved")


def reject(conn: sqlite3.Connection, solution_id: int) -> None:
    row = get_solution(conn, solution_id)
    if row["status"] != "pending":
        raise ModerationError(f"solution {solution_id} is {row['status']}, not pending")
    _set_status(conn, solution_id, "rejected")


def withdraw(conn: sqlite3.Connection, solution_id: int) -> None:
    """Takes an approved solution out of search again."""
    row = get_solution(conn, solution_id)
    if row["status"] != "approved":
        raise ModerationError(f"solution {solution_id} is {row['status']}, not approved")
    delete_document(conn, "solution", solution_path(solution_id))
    _set_status(conn, solution_id, "rejected")


def _set_status(conn: sqlite3.Connection, solution_id: int, status: str) -> None:
    with conn:
        conn.execute(
            "update solutions set status = ?, moderated_at = datetime('now') where id = ?",
            (status, solution_id),
        )
