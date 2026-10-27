"""Server-side administration: API keys and moderation. There is no HTTP admin interface.

    python -m solrag.admin key-create --label tim-phone
    python -m solrag.admin key-list
    python -m solrag.admin key-revoke ID
    python -m solrag.admin pending
    python -m solrag.admin show ID
    python -m solrag.admin approve ID
    python -m solrag.admin reject ID
    python -m solrag.admin withdraw ID
"""

import argparse
import sys
from collections.abc import Callable, Sequence
from typing import TextIO

from . import auth, moderation
from .config import Settings
from .db import connect, init_db
from .embedder import E5Embedder, Embedder
from .scrub import Scrubber


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="solrag.admin")
    sub = parser.add_subparsers(dest="command", required=True)
    create = sub.add_parser("key-create")
    create.add_argument("--label", required=True)
    sub.add_parser("key-list")
    sub.add_parser("pending")
    for name in ("key-revoke", "show", "approve", "reject", "withdraw"):
        sub.add_parser(name).add_argument("id", type=int)
    return parser


def run(
    argv: Sequence[str],
    settings: Settings,
    out: TextIO,
    embedder_factory: Callable[[], Embedder] | None = None,
) -> int:
    args = _parser().parse_args(argv)
    init_db(settings.db_path)
    conn = connect(settings.db_path)
    try:
        return _dispatch(args, conn, settings, out, embedder_factory)
    except moderation.ModerationError as exc:
        print(f"error: {exc}", file=out)
        return 1
    finally:
        conn.close()


def _dispatch(args, conn, settings: Settings, out: TextIO, embedder_factory) -> int:
    match args.command:
        case "key-create":
            key_id, key = auth.create_key(conn, args.label)
            print(f"key id {key_id} ({args.label}). Shown once, store it now:", file=out)
            print(key, file=out)
        case "key-list":
            for row in auth.list_keys(conn):
                state = f"revoked {row['revoked_at']}" if row["revoked_at"] else "active"
                print(
                    f"{row['id']}\t{row['label']}\t{state}\tcreated {row['created_at']}"
                    f"\tlast used {row['last_used_at'] or '-'}",
                    file=out,
                )
        case "key-revoke":
            if not auth.revoke_key(conn, args.id):
                print(f"error: key {args.id} not found or already revoked", file=out)
                return 1
            print(f"key {args.id} revoked", file=out)
        case "pending":
            rows = moderation.list_pending(conn)
            for row in rows:
                print(
                    f"{row['id']}\tos={row['os'] or '-'}\tkey={row['key_id']}\t{row['created_at']}"
                    f"\t{row['error']!r}",
                    file=out,
                )
            print(f"{len(rows)} pending", file=out)
        case "show":
            row = moderation.get_solution(conn, args.id)
            print(f"id {row['id']}  status {row['status']}  os {row['os'] or '-'}  key {row['key_id']}", file=out)
            print(moderation.solution_text(row["error"], row["solution"]), file=out)
        case "approve":
            scrubber = Scrubber.from_file(settings.scrub_literals) if settings.scrub_literals else Scrubber()
            factory = embedder_factory or (lambda: E5Embedder(settings.embed_model, settings.model_cache))
            moderation.approve(conn, factory(), scrubber, args.id)
            print(f"solution {args.id} approved and searchable", file=out)
        case "reject":
            moderation.reject(conn, args.id)
            print(f"solution {args.id} rejected", file=out)
        case "withdraw":
            moderation.withdraw(conn, args.id)
            print(f"solution {args.id} withdrawn from search", file=out)
    return 0


def main() -> None:
    sys.exit(run(sys.argv[1:], Settings.from_env(), sys.stdout))


if __name__ == "__main__":
    main()
