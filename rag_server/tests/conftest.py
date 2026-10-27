import hashlib
import math
import re

import pytest
from fastapi.testclient import TestClient

import solrag.auth
import solrag.db
from solrag.api import create_app
from solrag.config import Settings


class FakeEmbedder:
    dim = 384

    def __init__(self) -> None:
        self.passage_calls = 0

    def _embed(self, text: str) -> list[float]:
        vector = [0.0] * self.dim
        for token in re.findall(r"\w+", text.lower()):
            index = int(hashlib.md5(token.encode("utf-8")).hexdigest(), 16) % self.dim
            vector[index] += 1.0
        norm = math.sqrt(sum(x * x for x in vector))
        if norm == 0:
            vector[0] = 1.0
            return vector
        return [x / norm for x in vector]

    def embed_passages(self, texts) -> list[list[float]]:
        self.passage_calls += 1
        return [self._embed(t) for t in texts]

    def embed_query(self, text: str) -> list[float]:
        return self._embed(text)


@pytest.fixture
def settings(tmp_path) -> Settings:
    return Settings(data_dir=tmp_path / "data", model_cache=tmp_path / "models")


@pytest.fixture
def embedder() -> FakeEmbedder:
    return FakeEmbedder()


@pytest.fixture
def anon_client(settings, embedder):
    """No API key: for auth and health tests."""
    with TestClient(create_app(settings, embedder)) as c:
        yield c


@pytest.fixture
def api_key(anon_client, settings) -> str:
    connection = solrag.db.connect(settings.db_path)
    try:
        return solrag.auth.create_key(connection, "test")[1]
    finally:
        connection.close()


@pytest.fixture
def client(anon_client, api_key):
    anon_client.headers["Authorization"] = f"Bearer {api_key}"
    return anon_client


@pytest.fixture
def conn(client, settings):
    connection = solrag.db.connect(settings.db_path)
    try:
        yield connection
    finally:
        connection.close()
