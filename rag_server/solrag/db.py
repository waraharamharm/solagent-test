import sqlite3
from pathlib import Path

import sqlite_vec

EMBED_DIM = 384

SCHEMA = f"""
create table if not exists documents(
    id integer primary key,
    source text not null check(source in ('repo', 'doc', 'solution')),
    path text not null,
    os text,
    sha256 text not null,
    updated_at text not null default (datetime('now')),
    unique(source, path)
);

create table if not exists chunks(
    id integer primary key,
    document_id integer not null references documents(id) on delete cascade,
    ord integer not null,
    text text not null
);
create index if not exists chunks_document on chunks(document_id);

create virtual table if not exists chunks_fts using fts5(
    text, content='chunks', content_rowid='id', tokenize='unicode61 remove_diacritics 2'
);
create trigger if not exists chunks_ai after insert on chunks begin
    insert into chunks_fts(rowid, text) values (new.id, new.text);
end;
create trigger if not exists chunks_ad after delete on chunks begin
    insert into chunks_fts(chunks_fts, rowid, text) values ('delete', old.id, old.text);
end;

create virtual table if not exists chunks_vec using vec0(
    embedding float[{EMBED_DIM}] distance_metric=cosine,
    os text
);

create table if not exists solutions(
    id integer primary key,
    error text not null,
    solution text not null,
    os text,
    status text not null default 'pending' check(status in ('pending', 'approved', 'rejected')),
    created_at text not null default (datetime('now'))
);

create table if not exists api_keys(
    id integer primary key,
    label text not null,
    key_hash text not null unique,
    created_at text not null default (datetime('now')),
    last_used_at text,
    revoked_at text
);

"""


def connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path, timeout=5.0)
    conn.row_factory = sqlite3.Row
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    conn.execute("pragma foreign_keys = on")
    conn.execute("pragma busy_timeout = 5000")
    return conn


def _migrate(conn: sqlite3.Connection) -> None:
    """Columns added after the first release; `create table if not exists` never alters."""
    have = {r["name"] for r in conn.execute("pragma table_info(solutions)")}
    for column, ddl in (("key_id", "integer"), ("moderated_at", "text")):
        if column not in have:
            conn.execute(f"alter table solutions add column {column} {ddl}")


def init_db(db_path: Path) -> None:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = connect(db_path)
    try:
        conn.execute("pragma journal_mode = wal")
        conn.executescript(SCHEMA)
        _migrate(conn)
        conn.commit()
    finally:
        conn.close()
