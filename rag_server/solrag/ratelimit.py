"""In-memory sliding-window limiter.

State lives in the process, so run the server as a single worker (the default). A restart
resets the counters; that is acceptable for abuse control on a small private service.
"""

import threading
import time
from collections import deque
from collections.abc import Callable, Hashable


class SlidingWindowLimiter:
    def __init__(self, clock: Callable[[], float] = time.monotonic) -> None:
        self._clock = clock
        self._hits: dict[Hashable, deque[float]] = {}
        self._lock = threading.Lock()
        self._calls = 0

    def check(self, key: Hashable, limit: int, window: float) -> float | None:
        """Records a hit and returns None, or returns seconds to wait when over the limit."""
        with self._lock:
            now = self._clock()
            hits = self._fresh(key, window, now)
            if len(hits) >= limit:
                return max(0.0, hits[0] + window - now)
            hits.append(now)
            self._maybe_prune(window, now)
            return None

    def blocked(self, key: Hashable, limit: int, window: float) -> float | None:
        """Like `check` but records nothing."""
        with self._lock:
            now = self._clock()
            hits = self._fresh(key, window, now)
            if len(hits) >= limit:
                return max(0.0, hits[0] + window - now)
            return None

    def record(self, key: Hashable, window: float) -> None:
        with self._lock:
            now = self._clock()
            self._fresh(key, window, now).append(now)
            self._maybe_prune(window, now)

    def _fresh(self, key: Hashable, window: float, now: float) -> deque[float]:
        hits = self._hits.setdefault(key, deque())
        while hits and hits[0] <= now - window:
            hits.popleft()
        return hits

    def _maybe_prune(self, window: float, now: float) -> None:
        self._calls += 1
        if self._calls % 1000:
            return
        for key in [k for k, h in self._hits.items() if not h or h[-1] <= now - window]:
            del self._hits[key]
