# solagent

Flutter-приложение + RAG-сервер: Flexisip на собственном VDS пользователя, с телефона, ИИ чинит ошибки установки.

| | |
|---|---|
| App | Flutter, Android (основная цель), Windows для разработки |
| RAG server | `rag_server/` → `https://rag.mtoper.ru` (Python/FastAPI, SQLite + sqlite-vec) |
| Knowledge | приватный репо [solagent-knowledge](https://github.com/waraharamharm/solagent-knowledge) (очищенные скрипты и доки для RAG) |
| Releases | [GitHub Releases](../../releases), `releases/` |
| Status | этапы 1–8 из 11 готовы, см. [docs/STATUS.md](docs/STATUS.md) |

## Quick start

```powershell
cd D:\CursorAI\solagent
$env:Path = "D:\dev\flutter\bin;" + $env:Path
flutter pub get
flutter run -d windows                      # окно на ПК, r / R / q
flutter run --release -d <id устройства>    # телефон
flutter analyze; flutter test -j 1
```

> **Windows-сборка.** Нужны Visual Studio Build Tools с C++ **и ATL**
> (`atlstr.h` для `flutter_secure_storage`) и включённый «Режим разработчика».
> Без PIN-кода Windows Hello приложение покажет «блокировка экрана не настроена».
>
> **Релизный APK** подписан debug-ключом: только для тестов. Для магазина
> нужен свой keystore. Подробности: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Docs

Карта: [docs/README.md](docs/README.md).

| Doc | Topic |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Слои, движок развёртывания, цикл самоисправления, ИИ, знания в промпте |
| [docs/SECURITY.md](docs/SECURITY.md) | Секреты, биометрия, TOFU, очистка, политика команд, недоверенные данные |
| [docs/RAG_SERVER.md](docs/RAG_SERVER.md) | API, ключи и лимиты, модерация, индексация и очистка знаний |
| [docs/RAG_DEPLOY.md](docs/RAG_DEPLOY.md) | `rag.mtoper.ru`: systemd, nginx, TLS, выдача ключей, обновление |
| [docs/JOURNAL.md](docs/JOURNAL.md) | Журнал действий на сервере пользователя (`~/.solagent/journal.jsonl`) |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Запуск, сборка, тесты, релиз, ловушки |
| [docs/STATUS.md](docs/STATUS.md) | Этапы, что не сделано, отличия от ТЗ |

## Layout

См. [LAYOUT.md](LAYOUT.md).
