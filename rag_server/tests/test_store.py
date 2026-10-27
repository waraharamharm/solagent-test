from solrag import store


def _rows(conn, table):
    return conn.execute(f"select count(*) from {table}").fetchone()[0]


def _fts_ids(conn, word):
    return [r[0] for r in conn.execute("select rowid from chunks_fts where chunks_fts match ?", (f'"{word}"',))]


def _add(conn, embedder, path="a.md", text="hello world", os=None, source="doc"):
    return store.upsert_document(conn, embedder, source=source, path=path, text=text, os=os)


def test_upsert_creates_document_and_chunks(conn, embedder):
    doc_id = _add(conn, embedder, text="alpha beta")
    assert isinstance(doc_id, int)
    rows = conn.execute("select document_id, ord, text from chunks").fetchall()
    assert [(r["document_id"], r["ord"], r["text"]) for r in rows] == [(doc_id, 0, "alpha beta")]
    assert _rows(conn, "chunks_vec") == 1


def test_reupsert_identical_does_not_reembed(conn, embedder):
    first = _add(conn, embedder, text="same text", os="ubuntu")
    calls = embedder.passage_calls
    second = _add(conn, embedder, text="same text", os="ubuntu")
    assert second == first
    assert embedder.passage_calls == calls
    assert _rows(conn, "chunks") == 1


def test_changed_text_replaces_chunks(conn, embedder):
    doc_id = _add(conn, embedder, text="oldwordzzz first version")
    assert len(_fts_ids(conn, "oldwordzzz")) == 1

    again = _add(conn, embedder, text="newwordyyy second version")
    assert again == doc_id
    assert _rows(conn, "documents") == 1
    assert _rows(conn, "chunks") == 1
    assert _rows(conn, "chunks_vec") == 1
    assert _fts_ids(conn, "oldwordzzz") == []
    assert len(_fts_ids(conn, "newwordyyy")) == 1


def test_changed_os_reindexes(conn, embedder):
    doc_id = _add(conn, embedder, text="same", os=None)
    calls = embedder.passage_calls
    _add(conn, embedder, text="same", os="debian")
    assert embedder.passage_calls == calls + 1
    assert conn.execute("select os from documents where id = ?", (doc_id,)).fetchone()[0] == "debian"
    assert _rows(conn, "chunks") == 1
    assert _rows(conn, "chunks_vec") == 1


def test_shrinking_document_leaves_no_orphan_vectors(conn, embedder):
    _add(conn, embedder, text="\n".join(f"line {i} " + "y" * 60 for i in range(100)))
    assert _rows(conn, "chunks") > 1
    _add(conn, embedder, text="tiny")
    assert _rows(conn, "chunks") == 1
    assert _rows(conn, "chunks_vec") == 1


def test_delete_document(conn, embedder):
    _add(conn, embedder, text="deleteme uniqueterm")
    assert store.delete_document(conn, "doc", "a.md") is True
    assert store.delete_document(conn, "doc", "a.md") is False
    assert _rows(conn, "documents") == 0
    assert _rows(conn, "chunks") == 0
    assert _rows(conn, "chunks_vec") == 0
    assert _fts_ids(conn, "uniqueterm") == []


def test_delete_keeps_other_documents(conn, embedder):
    _add(conn, embedder, path="a.md", text="first doc")
    _add(conn, embedder, path="b.md", text="second doc")
    store.delete_document(conn, "doc", "a.md")
    assert _rows(conn, "documents") == 1
    assert _rows(conn, "chunks") == 1
    assert _rows(conn, "chunks_vec") == 1


def test_same_path_different_source_are_separate_documents(conn, embedder):
    a = _add(conn, embedder, source="repo", text="one")
    b = _add(conn, embedder, source="doc", text="two")
    assert a != b


def test_counts_and_add_solution(conn, embedder):
    assert store.counts(conn) == {"documents": 0, "chunks": 0, "pending_solutions": 0}
    _add(conn, embedder, text="x y z")
    solution_id, _ = store.add_solution(conn, error="boom", solution="fix it", os="ubuntu")
    assert store.counts(conn) == {"documents": 1, "chunks": 1, "pending_solutions": 1}
    row = conn.execute("select status, error, solution, os from solutions where id = ?", (solution_id,)).fetchone()
    assert tuple(row) == ("pending", "boom", "fix it", "ubuntu")


def test_solution_is_not_indexed(conn):
    store.add_solution(conn, error="boom", solution="secretfixword", os=None)
    assert _rows(conn, "chunks") == 0
    assert _rows(conn, "documents") == 0
