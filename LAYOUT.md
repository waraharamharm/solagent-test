# Layout

```
solagent/
  lib/                      приложение (Flutter)
    app/                    оболочка, роутер, домашний экран
    core/
      errors/               AppProblem: типизированные ошибки, текст в UI
      l10n/                 язык (ручной выбор или язык устройства)
      security/             биометрия, SecureStore (flutter_secure_storage)
      theme/, ui/           тема и общие виджеты
      validation/           проверки, общие для фич (адрес https)
      diagnostics.dart      отладочный лог проглоченных ошибок
    features/
      ssh/                  dartssh2, закрепление отпечатка хоста (TOFU)
      server/               профиль сервера, проверка ОС/arch/root
      deploy/               движок развёртывания: start/poll/cancel/remove
      fix/                  очистка лога, политика команд, советник ИИ, цикл починки
        application/        FixRun (состояние), FixSessionFactory (открывает сервер)
        presentation/       экран запуска + widgets/
      llm/                  клиент OpenAI-совместимого API, пресеты, настройки
      rag/                  клиент RAG, настройки (адрес, ключ), проверка
      journal/              журнал действий на сервере пользователя
      support/              экран поддержки (ссылки)
    l10n/                   app_en.arb, app_ru.arb
  test/                     тесты; test/support/ — общие фейки
  android/, windows/, ios/  платформенные проекты
  rag_server/               RAG-сервер (Python)
    solrag/                 пакет: api, auth, ratelimit, moderation, scrub, indexer, search...
    tests/
    deploy/                 solrag.service, nginx-solrag.conf, root-setup.sh
    data/                   НЕ в git: база, модели, сырой источник, очищенная копия
  releases/                 собранные APK
  docs/                     документация (см. docs/README.md)
  PRODUCT.md                продукт: пользователи, принципы
```

Внутри каждой фичи слои `domain` (модели, интерфейсы), `data` (реализации),
`application` (провайдеры, контроллеры), `presentation` (экраны), при
необходимости `l10n` (тексты ошибок). Фичи не импортируют `presentation` друг
друга; общее живёт в `core/`.
