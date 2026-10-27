# RAG server

`rag_server/`, пакет `solrag`: Python 3.12, FastAPI, SQLite (WAL) + `sqlite-vec`
+ FTS5, эмбеддинги `fastembed` (`multilingual-e5-small`, ONNX). RAG = поиск и
хранение; своего LLM у сервера нет.

## Search

Гибрид: BM25 (FTS5) + векторный KNN, слияние RRF. Фильтр по ОС внутри KNN:
`ubuntu-24.04` видит записи для `ubuntu-24.04`, `ubuntu` и общие. Порога
релевантности нет, поиск всегда отдаёт ближайшее.

## API

Ошибки всегда в одном формате, `message` по-английски:

```json
{"status": 401, "code": "unauthorized", "message": "Missing or invalid API key"}
```

| Method | Path | Notes |
|---|---|---|
| GET | `/v1/health` | `{"status":"ok"}`, без ключа |
| POST | `/v1/search` | `{query ≤ 4000, os?, k ≤ 20}` → `results` |
| GET | `/v1/bundle` | манифест (приложение пока не использует) |
| GET | `/v1/bundle/archive/{sha256}` | неизменяемый архив, хранятся 2 |
| POST | `/v1/solutions` | решение клиента → `202 pending`, в поиск не попадает до модерации |

## Auth and limits

- `Authorization: Bearer sol_…`, в базе sha256.
- Ключи на сервере: `python -m solrag.admin key-create --label X`, `key-list`, `key-revoke ID`.

| Limit | Value |
|---|---|
| search | 30 / мин на ключ |
| solutions | 10 / час на ключ |
| bundle | 30 / час на ключ |
| неудачная авторизация | 10 / мин на IP → `429` + `Retry-After` |
| тело запроса | 32 КБ → `413` |
| очередь модерации | ≤ 20 `pending` на ключ |

> Лимиты в памяти, один воркер; рестарт их обнуляет. За nginx включён
> `proxy_headers`, доверять только `127.0.0.1`.

## Moderation

Только CLI на сервере, HTTP-админки нет:
`pending`, `show ID`, `approve ID` (повторная проверка на утечки, потом в
поиск), `reject ID`, `withdraw ID`.

## Indexing and scrubbing

`solrag/scrub.py` вычищает пароли, токены, PEM, ssh-логины, MD5,
`IDENTIFIED BY`, IP (→ TEST-NET), домашние пути, e-mail и локальные литералы из
`rag_server/data/scrub_literals.json` (не в git). `solrag/indexer.py` работает
по белому списку корней: сначала всё чистится и проверяется, при любой утечке
сборка отказывает до записи. Пересборка идемпотентна.

```powershell
cd rag_server
.\.venv\Scripts\python -m solrag.indexer --src data\source\xmobile-flexisip --out data\knowledge-out --literals data\scrub_literals.json
```

Результат (27.10): 89 файлов, 345 кусков, независимая проверка = 0 утечек.
`data/knowledge-out` — git-клон приватного `solagent-knowledge`, заливка по
команде. Скрипты обезличены, но под произвольный VDS не параметризованы
(этап 10).

## Local run

```powershell
cd rag_server
.\.venv\Scripts\python -m solrag                # 127.0.0.1:8795
.\.venv\Scripts\python -m pytest -q             # быстрые тесты
.\.venv\Scripts\python -m pytest -q -m model    # с реальной моделью
```
