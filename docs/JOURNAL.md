# Server journal

Чтобы в новом сеансе ИИ знал, что уже делали, а не анализировал сервер с нуля,
приложение ведёт журнал на сервере пользователя.

| | |
|---|---|
| File | `~/.solagent/journal.jsonl` (+ `journal.jsonl.1` после ротации) |
| Mode | файл `600`, папка `700` |
| Rotation | при 1 МиБ файл уходит в `journal.jsonl.1`, всего до ~2 МиБ |
| Code | `lib/features/journal/`, события: `fix/application/fix_journal_events.dart` |

## Format

Одна JSON-строка на событие:

```json
{"t":"2026-10-27T12:00:00Z","k":"fixProposed","job":"demo","s":"No directory","d":"command: mkdir -p ~/conf"}
```

| Key | Meaning |
|---|---|
| `t` | время UTC |
| `k` | вид: `deployStarted`, `deployFinished`, `diagnosis`, `fixProposed`, `fixDecision`, `fixStarted`, `fixFinished`, `runFinished`, `note` (неизвестный вид читается как `note`) |
| `job` | id задачи (`^[A-Za-z0-9_-]{1,64}$`, иначе отбрасывается) |
| `s` | кратко, до 300 символов |
| `d` | подробности, до 1500 символов (хвост лога упавшей задачи, команда) |

## Rules

- Всё проходит через `LogRedactor` до записи.
- Запись: base64 по SSH, `{ echo B64 | base64 -d; echo; } >> файл`, `umask 077`.
- Чтение: `tail -n 400 | tail -c 200000`, разбор терпимый: битые и слишком
  длинные (> 8000) строки пропускаются.
- В промпт попадают до 20 последних записей и не более 6000 символов, блоком
  `<history>` как недоверенные данные (файл могли править руками).
- Сбой записи или чтения никогда не останавливает починку.
