import math
import sqlite3
from collections.abc import Callable, Iterator
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI, Path, Request, status
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from . import bundle, relay, store
from .auth import KeyInfo, verify_key
from .bodylimit import BodyLimitMiddleware
from .config import Settings
from .db import connect, init_db
from .embedder import E5Embedder, Embedder
from .errors import ApiError, install_error_handlers
from .ratelimit import SlidingWindowLimiter
from .scrub import Scrubber
from .search import hybrid_search

OsName = Annotated[str | None, Field(default=None, pattern=r"^[a-z0-9][a-z0-9.\-]{0,31}$")]

_MINUTE = 60.0
_HOUR = 3600.0


class SearchRequest(BaseModel):
    query: str = Field(min_length=1, max_length=4000)
    os: OsName = None
    k: int = Field(default=5, ge=1, le=20)


class SearchHit(BaseModel):
    chunk_id: int
    source: str
    path: str
    text: str
    score: float


class SearchResponse(BaseModel):
    results: list[SearchHit]


class SolutionRequest(BaseModel):
    error: str = Field(min_length=1, max_length=4000)
    solution: str = Field(min_length=1, max_length=2000)
    os: OsName = None


class SolutionAccepted(BaseModel):
    id: int
    status: str


class RunRequest(BaseModel):
    fcm_token: str = Field(pattern=r"^[A-Za-z0-9_:.\-]{20,4096}$")
    lang: str = Field(default="en", pattern=r"^[a-z]{2}$")


class RunCreated(BaseModel):
    run_id: str
    run_token: str
    expires_in: int


class CheckpointRequest(BaseModel):
    step: str = Field(pattern=relay.STEP_PATTERN)
    state: str = Field(pattern=r"^(started|done|failed|finished)$")


class CheckpointAccepted(BaseModel):
    pushed: bool


class Health(BaseModel):
    status: str


def _retry_after(seconds: float) -> dict[str, str]:
    return {"Retry-After": str(max(1, math.ceil(seconds)))}


def create_app(
    settings: Settings,
    embedder: Embedder | None = None,
    clock: Callable[[], float] | None = None,
    push_sender: relay.PushSender | None = None,
) -> FastAPI:
    limiter = SlidingWindowLimiter(clock) if clock else SlidingWindowLimiter()

    sender = push_sender or relay.build_sender(settings.fcm_credentials)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        init_db(settings.db_path)
        app.state.embedder = embedder or E5Embedder(settings.embed_model, settings.model_cache)
        app.state.scrubber = (
            Scrubber.from_file(settings.scrub_literals) if settings.scrub_literals else Scrubber()
        )
        yield

    app = FastAPI(title="SolAgent RAG", version="0.2.0", lifespan=lifespan)
    app.add_middleware(BodyLimitMiddleware, max_bytes=settings.max_body_bytes)
    install_error_handlers(app)

    def get_conn() -> Iterator[sqlite3.Connection]:
        conn = connect(settings.db_path)
        try:
            yield conn
        finally:
            conn.close()

    Conn = Annotated[sqlite3.Connection, Depends(get_conn)]

    def bearer_token(request: Request) -> str:
        scheme, _, token = request.headers.get("authorization", "").partition(" ")
        return token.strip() if scheme.lower() == "bearer" else ""

    def guard_failures(request: Request) -> str:
        ip = request.client.host if request.client else "unknown"
        wait = limiter.blocked(("auth-fail", ip), settings.auth_failures_per_minute, _MINUTE)
        if wait is not None:
            raise ApiError(
                429, "too_many_failures", "Too many failed authentication attempts; retry later",
                _retry_after(wait),
            )
        return ip

    def reject(ip: str, message: str) -> ApiError:
        limiter.record(("auth-fail", ip), _MINUTE)
        return ApiError(401, "unauthorized", message, {"WWW-Authenticate": "Bearer"})

    def authenticate(request: Request, conn: Conn) -> KeyInfo:
        ip = guard_failures(request)
        info = verify_key(conn, bearer_token(request))
        if info is None:
            raise reject(ip, "Missing or invalid API key")
        return info

    Client = Annotated[KeyInfo, Depends(authenticate)]

    def enforce(client: KeyInfo, kind: str, limit: int, window: float) -> None:
        wait = limiter.check((kind, client.id), limit, window)
        if wait is not None:
            raise ApiError(429, "rate_limited", f"Rate limit exceeded for {kind}", _retry_after(wait))

    @app.get("/v1/health", response_model=Health)
    def health() -> Health:
        return Health(status="ok")

    @app.post("/v1/search", response_model=SearchResponse)
    def search(req: SearchRequest, conn: Conn, client: Client) -> SearchResponse:
        enforce(client, "search", settings.search_per_minute, _MINUTE)
        hits = hybrid_search(conn, app.state.embedder, req.query, os=req.os, k=req.k)
        return SearchResponse(results=[SearchHit(**h.__dict__) for h in hits])

    @app.get("/v1/bundle")
    def bundle_manifest(client: Client) -> dict:
        enforce(client, "bundle", settings.bundle_per_hour, _HOUR)
        manifest = bundle.read_manifest(settings.bundle_dir)
        if manifest is None:
            raise ApiError(404, "bundle_not_published", "Bundle has not been published yet")
        return manifest

    @app.get("/v1/bundle/archive/{archive_sha}")
    def bundle_archive(
        archive_sha: Annotated[str, Path(pattern=r"^[0-9a-f]{64}$")],
        client: Client,
    ) -> FileResponse:
        enforce(client, "bundle", settings.bundle_per_hour, _HOUR)
        path = bundle.archive_path(settings.bundle_dir, archive_sha)
        if path is None:
            raise ApiError(404, "archive_not_found", "Bundle archive not found")
        return FileResponse(
            path,
            media_type="application/gzip",
            filename=f"solagent-bundle-{archive_sha[:12]}.tar.gz",
            headers={"Cache-Control": "private, max-age=31536000, immutable"},
        )

    @app.post("/v1/solutions", response_model=SolutionAccepted, status_code=status.HTTP_202_ACCEPTED)
    def submit_solution(req: SolutionRequest, conn: Conn, client: Client) -> SolutionAccepted:
        enforce(client, "solutions", settings.solutions_per_hour, _HOUR)
        scrubber: Scrubber = app.state.scrubber
        error, solution = scrubber.scrub(req.error), scrubber.scrub(req.solution)
        if scrubber.find_leaks(error) or scrubber.find_leaks(solution):
            raise ApiError(
                422, "secrets_detected",
                "Submission still looks like it contains secrets after cleaning; remove them and retry",
            )
        if store.pending_count(conn, client.id) >= settings.max_pending_per_key:
            raise ApiError(
                429, "queue_full", "Too many of your solutions are awaiting moderation; try again later"
            )
        solution_id, state = store.add_solution(
            conn, error=error, solution=solution, os=req.os, key_id=client.id
        )
        return SolutionAccepted(id=solution_id, status=state)

    @app.post("/v1/runs", response_model=RunCreated, status_code=status.HTTP_201_CREATED)
    def create_run(req: RunRequest, conn: Conn, client: Client) -> RunCreated:
        enforce(client, "runs", settings.runs_per_hour, _HOUR)
        if not sender.available:
            raise ApiError(503, "push_unavailable", "Push notifications are not configured on this server")
        lang = req.lang if req.lang in relay.LANGUAGES else "en"
        run_id, token = relay.create_run(conn, client.id, req.fcm_token, lang)
        return RunCreated(run_id=run_id, run_token=token, expires_in=relay.RUN_TTL_HOURS * 3600)

    @app.post("/v1/runs/{run_id}/checkpoints", response_model=CheckpointAccepted)
    def checkpoint(
        run_id: Annotated[str, Path(pattern=r"^[0-9a-f]{16}$")],
        req: CheckpointRequest,
        request: Request,
        conn: Conn,
    ) -> CheckpointAccepted:
        ip = guard_failures(request)
        run = relay.find_run(conn, run_id, bearer_token(request))
        if run is None:
            raise reject(ip, "Missing, invalid or expired run token")
        wait = limiter.check(("checkpoint", run.id), settings.checkpoints_per_hour, _HOUR)
        if wait is not None:
            raise ApiError(429, "rate_limited", "Rate limit exceeded for checkpoints", _retry_after(wait))
        if req.state not in relay.PUSHED_STATES:
            return CheckpointAccepted(pushed=False)
        title, body = relay.push_text(run.lang, req.step, req.state)
        if not sender.send(run.fcm_token, title, body, run.id):
            relay.delete_run(conn, run.id)
            return CheckpointAccepted(pushed=False)
        if req.state == "finished":
            relay.delete_run(conn, run.id)
        return CheckpointAccepted(pushed=True)

    return app
