# RAG deploy (production)

| | |
|---|---|
| URL | `https://rag.mtoper.ru` |
| Host | VDS, пользователь `solagent` без sudo |
| Dir | `~/solrag/{app,venv,data}` |
| Service | `~/.config/systemd/user/solrag.service` (`127.0.0.1:8795`, `MemoryMax` 1500M, `linger` включён) |
| nginx | `sites-enabled/solrag` (чужие сайты не затрагиваются), nginx 1.24 → без `http2 on` |
| Push relay | `~/solrag/solrag.env` (`SOLRAG_FCM_CREDENTIALS`) -> `~/solrag/secrets/fcm-service-account.json` (600); `pip install ./app[push]` |
| TLS | certbot, сертификат до 2027-01-25, автопродление |
| nginx limits | тело 64 КБ, 10 запросов/с на IP, ответы 413/429/503 тоже JSON |

База (`rag.sqlite3`), бандл и модель копируются готовыми; пересборки на
сервере нет.

## Files for root

`rag_server/deploy/`: `solrag.service`, `nginx-solrag.conf`, `root-setup.sh`.

```bash
# файлы в /tmp/solrag-deploy, от root; повторный запуск безопасен
DOMAIN=rag.mtoper.ru bash root-setup.sh
```

## Update code

```bash
# с рабочей машины: tar solrag + pyproject.toml -> scp на сервер
~/solrag/venv/bin/pip install ./app
systemctl --user restart solrag
```

## Issue a key

```bash
SOLRAG_DATA_DIR=~/solrag/data ~/solrag/venv/bin/python -m solrag.admin key-create --label имя
```

Ключ показывается один раз. Отозвать: `... key-revoke ID`. В приложении ключ
вводится на вкладке «ИИ» → «База знаний».

## Check

```bash
curl -s https://rag.mtoper.ru/v1/health                       # {"status":"ok"}
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://rag.mtoper.ru/v1/search   # 401 без ключа
systemctl --user status solrag
```
