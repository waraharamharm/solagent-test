import argparse
import hashlib
import shutil
import sqlite3
from dataclasses import dataclass, field
from fnmatch import fnmatch
from pathlib import Path

from . import bundle, store
from .config import Settings
from .db import connect, init_db
from .embedder import E5Embedder, Embedder
from .scrub import Scrubber

MAX_FILE_BYTES = 200_000
INDEXED_SOURCES = ("repo", "doc")


class LeakError(Exception):
    """A scrubbed file still looks sensitive. Nothing has been written."""


@dataclass(frozen=True)
class SourcePolicy:
    """Allowlist: a file is indexed only if it lives under a root and matches no exclude."""

    roots: tuple[str, ...] = ("deploy-xdexboard", "docs", "scripts", "docker", "README.md", "LAYOUT.md")
    excludes: tuple[str, ...] = (
        "*/vendor/*",
        "*/ca/*",
        "*/logs/*",
        "*/certs/*",
        "*/secrets/*",
        "*/etc-secrets/*",
        "*users.db*",
        "*.runtime",
        "*.env",
        "*.pem",
        "*.key",
        "*.p12",
        "*.jks",
        "*.db",
        "*.sqlite*",
        "docs/CREDENTIALS_STORAGE.md",
        "docs/ADB_LAB_CALLS.md",
        "docs/BEELINE_*",
        "docs/KEENETIC_*",
        "docs/LAB_*",
        "docs/XRP2_*",
        "docs/HOSTING_POLICY.md",
        "scripts/adb-*",
    )

    def allows(self, rel: str) -> bool:
        in_root = any(rel == r or rel.startswith(r.rstrip("/") + "/") for r in self.roots)
        return in_root and not any(fnmatch(rel, pat) for pat in self.excludes)


@dataclass
class BuildReport:
    version: str = ""
    indexed: list[str] = field(default_factory=list)
    skipped: list[tuple[str, str]] = field(default_factory=list)
    removed: list[str] = field(default_factory=list)


def _source_kind(rel: str) -> str:
    return "doc" if rel.endswith(".md") else "repo"


def _collect(src: Path, policy: SourcePolicy, scrubber: Scrubber, report: BuildReport) -> dict[str, str]:
    """Return {scrubbed relative path: scrubbed text}; raise LeakError before anything is written."""
    files: dict[str, str] = {}
    for path in sorted(p for p in src.rglob("*") if p.is_file() and not p.is_symlink()):
        rel = path.relative_to(src).as_posix()
        if ".git/" in f"{rel}/" or not policy.allows(rel):
            continue
        if path.stat().st_size > MAX_FILE_BYTES:
            report.skipped.append((scrubber.scrub_path(rel), "too large"))
            continue
        try:
            text = path.read_bytes().decode("utf-8-sig")
        except UnicodeDecodeError:
            report.skipped.append((scrubber.scrub_path(rel), "not utf-8 text"))
            continue
        if "\x00" in text:
            report.skipped.append((scrubber.scrub_path(rel), "binary"))
            continue

        clean_rel = scrubber.scrub_path(rel)
        clean = scrubber.scrub(text.replace("\r\n", "\n"))
        leaks = scrubber.find_leaks(clean, clean_rel)
        if leaks:
            raise LeakError(f"{clean_rel}: {'; '.join(leaks)}")
        if clean_rel in files:
            raise LeakError(f"{clean_rel}: two source files map to the same published path")
        files[clean_rel] = clean
    return files


def _clear_output(out_dir: Path, src: Path) -> None:
    """Empty out_dir but keep a `.git` inside it: out_dir may be a clone of the publishing repo."""
    out, source = out_dir.resolve(), src.resolve()
    if out == source or out.is_relative_to(source) or source.is_relative_to(out):
        raise ValueError("output directory must not overlap the source directory")
    out.mkdir(parents=True, exist_ok=True)
    for child in out.iterdir():
        if child.name == ".git":
            continue
        shutil.rmtree(child) if child.is_dir() else child.unlink()


def _version(files: dict[str, str]) -> str:
    digest = hashlib.sha256()
    for rel in sorted(files):
        digest.update(rel.encode())
        digest.update(hashlib.sha256(files[rel].encode()).digest())
    return digest.hexdigest()[:12]


def build_knowledge(
    src: Path,
    out_dir: Path,
    conn: sqlite3.Connection,
    embedder: Embedder,
    scrubber: Scrubber,
    bundle_dir: Path,
    policy: SourcePolicy | None = None,
) -> BuildReport:
    report = BuildReport()
    files = _collect(src, policy or SourcePolicy(), scrubber, report)
    report.version = _version(files)

    _clear_output(out_dir, src)
    for rel, text in files.items():
        target = out_dir / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8", newline="\n")

    for rel, text in files.items():
        store.upsert_document(conn, embedder, source=_source_kind(rel), path=rel, text=text)
        report.indexed.append(rel)

    stale = conn.execute(
        "select source, path from documents where source in (?, ?)", INDEXED_SOURCES
    ).fetchall()
    for row in stale:
        if row["path"] not in files and store.delete_document(conn, row["source"], row["path"]):
            report.removed.append(row["path"])

    bundle.publish_bundle(out_dir, bundle_dir, report.version)
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description="Scrub a source repo and index it for the RAG server")
    parser.add_argument("--src", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True, help="scrubbed copy, safe to commit")
    parser.add_argument("--literals", type=Path, required=True, help="JSON {real: placeholder}")
    args = parser.parse_args()

    settings = Settings.from_env()
    init_db(settings.db_path)
    scrubber = Scrubber.from_file(args.literals)
    conn = connect(settings.db_path)
    try:
        report = build_knowledge(
            args.src.resolve(),
            args.out.resolve(),
            conn,
            E5Embedder(settings.embed_model, settings.model_cache),
            scrubber,
            settings.bundle_dir,
        )
    except LeakError as exc:
        raise SystemExit(f"BUILD REFUSED, nothing written to the database: {exc}")
    finally:
        conn.close()

    print(f"version {report.version}: indexed {len(report.indexed)}, removed {len(report.removed)}")
    for path, reason in report.skipped:
        print(f"  skipped {path}: {reason}")


if __name__ == "__main__":
    main()
