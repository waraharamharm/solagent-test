# Development

## Requirements

- Flutter 3.47 (Dart 3.13), Android SDK.
- Windows-сборка: Visual Studio Build Tools с «Разработка классических
  приложений на C++» и **C++ ATL**, «Режим разработчика» Windows (симлинки).

```powershell
cd D:\CursorAI\solagent
$env:Path = "D:\dev\flutter\bin;" + $env:Path
flutter pub get
```

## Commands

| Task | Command |
|---|---|
| Run on PC (hot reload) | `flutter run -d windows` (`r` / `R` / `q`) |
| Install release on phone | `flutter run --release -d <id> --no-resident` |
| Release APK | `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk` |
| Codegen | `dart run build_runner build -d` |
| Localization | `flutter gen-l10n` |
| Analyze | `flutter analyze` |
| Tests | `flutter test -j 1` |

На ПК биометрия идёт через Windows Hello: без PIN-кода Windows приложение
покажет «блокировка экрана не настроена» (Параметры → Учётные записи →
Варианты входа).

## Tests

Общие фейки в `test/support/`: `MemoryStore`, `FakeSshSession`, `FakeEngine`,
`FakeLlm`, `FakeJournal`. Анализатор строгий (`strict-casts`,
`strict-inference`, `strict-raw-types` + правила в `analysis_options.yaml`).

Тесты с реальным сервером запускаются через `SOLAGENT_VDS_HOST`,
`SOLAGENT_VDS_USER`, `SOLAGENT_VDS_KEY`, `SOLAGENT_VDS_FP` и
`SOLAGENT_LLM_URL`, `SOLAGENT_LLM_MODEL`, `SOLAGENT_LLM_KEY`; без них
пропускаются.

## Release

```powershell
gh release create vX.Y.Z путь\к\app-release.apk --repo waraharamharm/solagent-test --title "vX.Y.Z" --notes "..."
```

APK подписан debug-ключом, для магазина нужен свой keystore. Репозиторий
приватный: релиз видят только добавленные коллабораторы.

## Pitfalls

- **Тесты на Windows** иногда падают с «did not complete» на случайном файле,
  поодиночке проходят. Помогает остановка демонов Gradle/Java и `-j 1`.
- **Меню с `null`-значением** не вызывает `onSelected`: для «как на
  устройстве» используется `''`.
- **`kotlin.incremental=false`** в `android/gradle.properties`: pub-кэш на `C:`,
  проект на `D:`.
- **PowerShell и кириллица:** `Set-Content` без `-Encoding` портит русский
  текст. Править через редактор или `WriteAllText` в UTF-8.
- **nginx 1.24** не знает `http2 on;`.
- **Не вставлять `\n` в строки Dart через шелл-замены.**
- **Алиасы PowerShell** (`Ren`, `Rn`...) перекрывают функции в скриптах:
  называть функции не как стандартные команды.
