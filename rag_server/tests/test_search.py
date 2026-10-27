import random
import string

import pytest

from solrag import store
from solrag.search import hybrid_search


def _add(conn, embedder, path, text, os=None):
    store.upsert_document(conn, embedder, source="doc", path=path, text=text, os=os)


def _paths(conn, embedder, query, os=None, k=20):
    return {h.path for h in hybrid_search(conn, embedder, query, os=os, k=k)}


def test_empty_db_returns_nothing(conn, embedder):
    assert hybrid_search(conn, embedder, "anything", os=None, k=5) == []


def test_exact_log_token_ranks_matching_doc_first(conn, embedder):
    _add(conn, embedder, "sip.md", "asterisk failed: port 5060 already in use by another process")
    _add(conn, embedder, "cake.md", "mix flour sugar eggs and bake the cake for forty minutes")
    _add(conn, embedder, "nginx.md", "configure nginx reverse proxy with tls certificates")
    hits = hybrid_search(conn, embedder, "bind port 5060 already in use", os=None, k=5)
    assert hits[0].path == "sip.md"
    assert hits[0].source == "doc"
    assert "5060" in hits[0].text


def test_k_limits_results(conn, embedder):
    for i in range(6):
        _add(conn, embedder, f"d{i}.md", f"shared word number{i}")
    assert len(hybrid_search(conn, embedder, "shared word", os=None, k=3)) == 3
    assert len(hybrid_search(conn, embedder, "shared word", os=None, k=1)) == 1


def test_scores_are_descending(conn, embedder):
    for i in range(5):
        _add(conn, embedder, f"d{i}.md", f"shared word number{i}")
    scores = [h.score for h in hybrid_search(conn, embedder, "shared word number2", os=None, k=5)]
    assert scores == sorted(scores, reverse=True)


@pytest.fixture
def os_docs(conn, embedder):
    _add(conn, embedder, "any.md", "common topic text", os=None)
    _add(conn, embedder, "ubuntu.md", "common topic text", os="ubuntu")
    _add(conn, embedder, "u2404.md", "common topic text", os="ubuntu-24.04")


@pytest.mark.parametrize(
    ("os_name", "expected"),
    [
        (None, {"any.md", "ubuntu.md", "u2404.md"}),
        ("ubuntu", {"any.md", "ubuntu.md"}),
        ("ubuntu-24.04", {"any.md", "ubuntu.md", "u2404.md"}),
        ("ubuntu-22.04", {"any.md", "ubuntu.md"}),
        ("debian-12", {"any.md"}),
    ],
)
def test_os_filter(conn, embedder, os_docs, os_name, expected):
    assert _paths(conn, embedder, "common topic text", os=os_name) == expected


def test_os_prefix_must_end_at_dash(conn, embedder):
    _add(conn, embedder, "ubuntu.md", "common topic text", os="ubuntu")
    assert _paths(conn, embedder, "common topic text", os="ubuntustudio") == set()


@pytest.mark.parametrize(
    "query",
    ['"', "a AND (b", "NEAR(x y)", "*", "-foo", "col:val", "^start", "OR", "a OR", "'; drop table chunks; --"],
)
def test_fts_special_syntax_does_not_raise(conn, embedder, query):
    _add(conn, embedder, "a.md", "foo b start val x y col text")
    hybrid_search(conn, embedder, query, os=None, k=5)


def test_long_random_log_does_not_raise(conn, embedder):
    _add(conn, embedder, "a.md", "some text")
    rng = random.Random(1)
    alphabet = string.ascii_letters + string.digits + string.punctuation + " \n"
    query = "".join(rng.choice(alphabet) for _ in range(4000))
    hybrid_search(conn, embedder, query, os=None, k=5)


def test_punctuation_only_query_still_returns_semantic_results(conn, embedder):
    _add(conn, embedder, "a.md", "some text")
    hits = hybrid_search(conn, embedder, "!!! ??? ---", os=None, k=5)
    assert [h.path for h in hits] == ["a.md"]


def test_cyrillic_token_match(conn, embedder):
    _add(conn, embedder, "ru.md", "Ошибка сертификата при подключении к серверу")
    _add(conn, embedder, "en.md", "certificate verify failed on connect")
    hits = hybrid_search(conn, embedder, "ошибка сертификата", os=None, k=5)
    assert hits[0].path == "ru.md"


def test_os_filter_not_starved_by_other_os_neighbours(conn, embedder):
    for i in range(60):
        _add(conn, embedder, f"u{i}.md", f"x u{i}", os="ubuntu")
    _add(conn, embedder, "deb.md", "x debian only", os="debian-12")
    assert _paths(conn, embedder, "x", os="debian-12") == {"deb.md"}
