import hashlib
import sqlite3

import sqlite_vec

from .chunking import chunk_text
from .embedder import Embedder


def upsert_document(
    conn: sqlite3.Connection,
    embedder: Embedder,
    *,
    source: str,
    path: str,
    text: str,
    os: str | None = None,
) -> int:
    """Index a document. Text must already be scrubbed of secrets: it is served to every client."""
    sha = hashlib.sha256(text.encode("utf-8")).hexdigest()
    row = conn.execute(
        "select id, sha256, os from documents where source = ? and path = ?", (source, path)
    ).fetchone()
    if row is not None and row["sha256"] == sha and row["os"] == os:
        return row["id"]

    pieces = chunk_text(text)
    vectors = embedder.embed_passages(pieces) if pieces else []

    with conn:
        if row is None:
            doc_id = conn.execute(
                "insert into documents(source, path, os, sha256) values (?, ?, ?, ?)",
                (source, path, os, sha),
            ).lastrowid
        else:
            doc_id = row["id"]
            _delete_chunks(conn, doc_id)
            conn.execute(
                "update documents set os = ?, sha256 = ?, updated_at = datetime('now') where id = ?",
                (os, sha, doc_id),
            )
        for ord_, (piece, vector) in enumerate(zip(pieces, vectors)):
            chunk_id = conn.execute(
                "insert into chunks(document_id, ord, text) values (?, ?, ?)", (doc_id, ord_, piece)
            ).lastrowid
            conn.execute(
                "insert into chunks_vec(rowid, embedding, os) values (?, ?, ?)",
                (chunk_id, sqlite_vec.serialize_float32(vector), os or ""),
            )
    return doc_id


def delete_document(conn: sqlite3.Connection, source: str, path: str) -> bool:
    row = conn.execute(
        "select id from documents where source = ? and path = ?", (source, path)
    ).fetchone()
    if row is None:
        return False
    with conn:
        _delete_chunks(conn, row["id"])
        conn.execute("delete from documents where id = ?", (row["id"],))
    return True


def _delete_chunks(conn: sqlite3.Connection, doc_id: int) -> None:
    conn.execute(
        "delete from chunks_vec where rowid in (select id from chunks where document_id = ?)", (doc_id,)
    )
    conn.execute("delete from chunks where document_id = ?", (doc_id,))


def counts(conn: sqlite3.Connection) -> dict[str, int]:
    return {
        "documents": conn.execute("select count(*) from documents").fetchone()[0],
        "chunks": conn.execute("select count(*) from chunks").fetchone()[0],
        "pending_solutions": conn.execute(
            "select count(*) from solutions where status = 'pending'"
        ).fetchone()[0],
    }


def pending_count(conn: sqlite3.Connection, key_id: int) -> int:
    return conn.execute(
        "select count(*) from solutions where status = 'pending' and key_id = ?", (key_id,)
    ).fetchone()[0]


def add_solution(
    conn: sqlite3.Connection, *, error: str, solution: str, os: str | None, key_id: int | None = None
) -> tuple[int, str]:
    """Solutions land in the moderation queue; nothing here makes them searchable.

    Text must already be scrubbed. An identical submission returns the existing row, so
    resubmitting cannot flood the queue."""
    existing = conn.execute(
        "select id, status from solutions "
        "where error = ? and solution = ? and os is ? and status != 'rejected'",
        (error, solution, os),
    ).fetchone()
    if existing is not None:
        return existing["id"], existing["status"]
    with conn:
        solution_id = conn.execute(
            "insert into solutions(error, solution, os, key_id) values (?, ?, ?, ?)",
            (error, solution, os, key_id),
        ).lastrowid
    return solution_id, "pending"