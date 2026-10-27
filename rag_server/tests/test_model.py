import math
from pathlib import Path

import pytest

import solrag.db
from solrag import store
from solrag.embedder import E5Embedder
from solrag.search import hybrid_search

pytestmark = pytest.mark.model

MODEL_CACHE = Path(r"D:\CursorAI\solagent\rag_server\data\models")

DOCS = {
    "sip.md": (
        "Конфликт портов SIP: Asterisk не стартует, потому что порт 5060 уже занят другим "
        "процессом. Найдите процесс через ss -lntup и остановите его."
    ),
    "apt.md": (
        "apt install fails with: E: Unable to locate package libsrtp2-dev. "
        "Run apt update and enable the universe repository."
    ),
    "cake.md": "Рецепт шоколадного торта: смешайте муку, сахар и яйца, выпекайте сорок минут.",
}


@pytest.fixture(scope="module")
def embedder():
    return E5Embedder("intfloat/multilingual-e5-small", MODEL_CACHE)


@pytest.fixture(scope="module")
def indexed(embedder, tmp_path_factory):
    db_path = tmp_path_factory.mktemp("model") / "rag.sqlite3"
    solrag.db.init_db(db_path)
    conn = solrag.db.connect(db_path)
    for path, text in DOCS.items():
        store.upsert_document(conn, embedder, source="doc", path=path, text=text)
    yield conn
    conn.close()


def _ranked(conn, embedder, query):
    return [h.path for h in hybrid_search(conn, embedder, query, os=None, k=3)]


def test_embed_query_shape_and_norm(embedder):
    vector = embedder.embed_query("hello world")
    assert len(vector) == 384
    assert math.sqrt(sum(x * x for x in vector)) == pytest.approx(1.0, abs=1e-3)


def test_english_docker_log_finds_port_doc(indexed, embedder):
    ranked = _ranked(indexed, embedder, "bind: address already in use 0.0.0.0:5060")
    assert ranked[0] == "sip.md"


def test_russian_query_finds_apt_doc(indexed, embedder):
    ranked = _ranked(indexed, embedder, "не найден пакет libsrtp2-dev")
    assert ranked[0] == "apt.md"


@pytest.mark.parametrize(
    "query",
    ["bind: address already in use 0.0.0.0:5060", "не найден пакет libsrtp2-dev", "порт занят"],
)
def test_cake_doc_is_never_first(indexed, embedder, query):
    assert _ranked(indexed, embedder, query)[0] != "cake.md"
