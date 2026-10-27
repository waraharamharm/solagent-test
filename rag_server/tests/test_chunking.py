import pytest

from solrag.chunking import chunk_text


@pytest.mark.parametrize("text", ["", "   ", "\n\t \n"])
def test_blank_text_gives_no_chunks(text):
    assert chunk_text(text) == []


def test_short_text_is_single_stripped_chunk():
    assert chunk_text("  hello world \n") == ["hello world"]


def _long_text() -> str:
    lines = [f"line {i:04d} " + "x" * 30 for i in range(130)]
    return "\n".join(lines)[:5000]


def test_long_text_chunks_fit_size():
    chunks = chunk_text(_long_text(), size=1200, overlap=200)
    assert len(chunks) > 1
    assert all(len(c) <= 1200 for c in chunks)


def test_consecutive_chunks_overlap():
    chunks = chunk_text(_long_text(), size=1200, overlap=200)
    for prev, nxt in zip(chunks, chunks[1:]):
        assert nxt[:50] in prev


def test_long_text_is_fully_covered():
    text = _long_text()
    chunks = chunk_text(text, size=1200, overlap=200)
    covered = "".join(chunks)
    for line in text.split("\n"):
        assert line.strip() in covered


def test_prefers_cutting_at_newline_in_second_half():
    text = "a" * 700 + "\n" + "b" * 1000
    chunks = chunk_text(text, size=1000, overlap=100)
    assert chunks[0] == "a" * 700


def test_ignores_newline_in_first_half():
    text = "a" * 100 + "\n" + "b" * 1500
    chunks = chunk_text(text, size=1000, overlap=100)
    assert len(chunks[0]) > 500


def test_text_without_newlines_terminates_and_covers_everything():
    text = "".join(chr(ord("a") + i % 26) for i in range(5000))
    chunks = chunk_text(text, size=1200, overlap=200)
    assert all(len(c) <= 1200 for c in chunks)
    assert chunks[0] == text[:1200]
    assert chunks[-1] == text[-len(chunks[-1]) :]
    step = 1200 - 200
    for i, chunk in enumerate(chunks):
        assert chunk == text[i * step : i * step + 1200]
