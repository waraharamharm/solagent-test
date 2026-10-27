from pathlib import Path
from typing import Protocol, Sequence

from .db import EMBED_DIM


class Embedder(Protocol):
    dim: int

    def embed_passages(self, texts: Sequence[str]) -> list[list[float]]: ...

    def embed_query(self, text: str) -> list[float]: ...


class E5Embedder:
    """multilingual-e5-small on ONNX. e5 is trained with "query: " / "passage: " prefixes."""

    dim = EMBED_DIM
    _registered = False

    def __init__(self, model_name: str, cache_dir: Path, threads: int | None = None) -> None:
        from fastembed import TextEmbedding

        self._register(model_name)
        self._model = TextEmbedding(model_name, cache_dir=str(cache_dir), threads=threads)

    @classmethod
    def _register(cls, model_name: str) -> None:
        if cls._registered:
            return
        from fastembed import TextEmbedding
        from fastembed.common.model_description import ModelSource, PoolingType

        TextEmbedding.add_custom_model(
            model=model_name,
            pooling=PoolingType.MEAN,
            normalization=True,
            sources=ModelSource(hf=model_name),
            dim=EMBED_DIM,
            model_file="onnx/model.onnx",
        )
        cls._registered = True

    def embed_passages(self, texts: Sequence[str]) -> list[list[float]]:
        return [v.tolist() for v in self._model.embed([f"passage: {t}" for t in texts])]

    def embed_query(self, text: str) -> list[float]:
        return next(iter(self._model.embed([f"query: {text}"]))).tolist()
