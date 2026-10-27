import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    data_dir: Path
    model_cache: Path
    embed_model: str = "intfloat/multilingual-e5-small"
    host: str = "127.0.0.1"
    port: int = 8795
    scrub_literals: Path | None = None
    search_per_minute: int = 30
    solutions_per_hour: int = 10
    bundle_per_hour: int = 30
    max_pending_per_key: int = 20
    auth_failures_per_minute: int = 10
    max_body_bytes: int = 32768

    @property
    def db_path(self) -> Path:
        return self.data_dir / "rag.sqlite3"

    @property
    def bundle_dir(self) -> Path:
        return self.data_dir / "bundle"

    @classmethod
    def from_env(cls) -> "Settings":
        data_dir = Path(os.environ.get("SOLRAG_DATA_DIR", "data")).resolve()
        model_cache = Path(os.environ.get("SOLRAG_MODEL_CACHE", data_dir / "models")).resolve()
        literals = os.environ.get("SOLRAG_SCRUB_LITERALS")
        return cls(
            data_dir=data_dir,
            model_cache=model_cache,
            host=os.environ.get("SOLRAG_HOST", "127.0.0.1"),
            port=int(os.environ.get("SOLRAG_PORT", "8795")),
            scrub_literals=Path(literals).resolve() if literals else None,
        )
