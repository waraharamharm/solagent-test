import re
import sqlite3
from dataclasses import dataclass

import sqlite_vec

from .embedder import Embedder

CANDIDATES = 50
RRF_K = 60
MAX_FTS_TERMS = 64


@dataclass(frozen=True)
class Hit:
    chunk_id: int
    source: str
    path: str
    text: str
    score: float


def hybrid_search(
    conn: sqlite3.Connection, embedder: Embedder, query: str, *, os: str | None, k: int
) -> list[Hit]:
    """BM25 catches exact log tokens (ports, package names, error codes); e5 catches meaning
    across Russian and English. Ranks are merged with reciprocal rank fusion."""
    allowed = _allowed_os(os)
    marks = ",".join("?" * len(allowed))

    lexical: list[int] = []
    fts_query = _fts_query(query)
    if fts_query:
        os_filter = f"coalesce(d.os, '') in ({marks})" if allowed else "1"
        lexical = [
            r[0]
            for r in conn.execute(
                f"""
                select c.id from chunks_fts f
                join chunks c on c.id = f.rowid
                join documents d on d.id = c.document_id
                where chunks_fts match ? and {os_filter}
                order by bm25(chunks_fts) limit {CANDIDATES}
                """,
                [fts_query, *allowed],
            )
        ]

    # The OS filter must run inside the KNN scan: filtering after it lets
    # neighbours from other systems crowd out every match.
    os_filter = f"and os in ({marks})" if allowed else ""
    vector = sqlite_vec.serialize_float32(embedder.embed_query(query))
    semantic = [
        r[0]
        for r in conn.execute(
            f"""
            select rowid from chunks_vec
            where embedding match ? and k = {CANDIDATES} {os_filter}
            order by distance
            """,
            [vector, *allowed],
        )
    ]

    scores: dict[int, float] = {}
    for ranking in (lexical, semantic):
        for rank, chunk_id in enumerate(ranking):
            scores[chunk_id] = scores.get(chunk_id, 0.0) + 1.0 / (RRF_K + rank + 1)
    top = sorted(scores.items(), key=lambda item: item[1], reverse=True)[:k]
    if not top:
        return []

    ids = [chunk_id for chunk_id, _ in top]
    rows = {
        r["id"]: r
        for r in conn.execute(
            f"""
            select c.id, c.text, d.source, d.path from chunks c
            join documents d on d.id = c.document_id
            where c.id in ({",".join("?" * len(ids))})
            """,
            ids,
        )
    }
    return [
        Hit(chunk_id, rows[chunk_id]["source"], rows[chunk_id]["path"], rows[chunk_id]["text"], score)
        for chunk_id, score in top
    ]


def _allowed_os(os: str | None) -> list[str]:
    """"ubuntu-24.04" sees documents for any OS (""), "ubuntu" and "ubuntu-24.04"."""
    if not os:
        return []
    parts = os.split("-")
    return ["", *("-".join(parts[: i + 1]) for i in range(len(parts)))]


def _fts_query(query: str) -> str:
    terms: list[str] = []
    for term in re.findall(r"\w+", query.lower()):
        if len(term) >= 2 and term not in terms:
            terms.append(term)
        if len(terms) == MAX_FTS_TERMS:
            break
    return " OR ".join(f'"{t}"' for t in terms)
