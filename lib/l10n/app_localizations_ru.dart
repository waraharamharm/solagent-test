// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'SolAgent';

  @override
  String get commonServer => 'Сервер';

  @override
  String get commonAi => 'ИИ';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonPassword => 'Пароль';

  @override
  String get commonDecisionNeeded => 'Нужно ваше решение';

  @override
  String get commonWorking => 'Идёт работа';

  @override
  String get commonSelfHealing => 'Самоисправление';

  @override
  String get shellTabOverview => 'Обзор';

  @override
  String get shellTabDeploy => 'Развёртывание';

  @override
  String get shellJobRun => 'Запуск';

  @override
  String get homeServerNotConnected => 'Не подключён';

  @override
  String get homeServerSaved => 'сохранён';

  @override
  String get homeAiNoKey => 'Нет ключа';

  @override
  String get homeAiReady => 'готов';

  @override
  String get homeRunWaiting => 'Ждёт вашего решения';

  @override
  String get homeRunLastSucceeded => 'Последний запуск прошёл';

  @override
  String get homeRunDemo => 'Демо на вашем сервере';

  @override
  String get homeRunLastFailed => 'Последний запуск не прошёл';

  @override
  String get homeHeroReviewCommand => 'Посмотреть команду';

  @override
  String get homeHeroServerBusy => 'Сервер выполняет задачу';

  @override
  String get homeHeroOpen => 'Открыть';

  @override
  String get homeHeroConnectServerTitle => 'Подключите сервер';

  @override
  String get homeHeroConnectServerBody =>
      'Адрес VDS и пароль или ключ. Проверим систему и запомним отпечаток сервера.';

  @override
  String get homeHeroAddServer => 'Добавить сервер';

  @override
  String get homeHeroConnectAiTitle => 'Подключите ИИ';

  @override
  String get homeHeroConnectAiBody =>
      'Нужен ваш API-ключ: DeepSeek, Grok, OpenRouter, OpenAI или свой адрес.';

  @override
  String get homeHeroAddKey => 'Добавить ключ';

  @override
  String get homeHeroAllSetTitle => 'Всё подключено';

  @override
  String get homeHeroAllSetBody =>
      'Сервер и ИИ на месте. Проверьте самоисправление на демо-скрипте.';

  @override
  String get homeHeroOpenDemo => 'Открыть демо';

  @override
  String get homeThemeTooltip => 'Тема';

  @override
  String get homeThemeSystem => 'Как в системе';

  @override
  String get homeThemeLight => 'Светлая';

  @override
  String get homeThemeDark => 'Тёмная';

  @override
  String get homeLanguageTooltip => 'Язык';

  @override
  String get homeLanguageAuto => 'Как на устройстве';

  @override
  String get homeSupportTitle => 'Поддержать проект';

  @override
  String get homeSupportSubtitle => 'Пожертвование на развитие';

  @override
  String get supportTitle => 'Поддержать проект';

  @override
  String get supportIntro =>
      'SolAgent бесплатный. Пожертвование — добровольный подарок на развитие проекта, а не оплата доступа или функций.';

  @override
  String get supportGroupOnline => 'Онлайн';

  @override
  String get supportGroupTransfer => 'Прямой перевод';

  @override
  String get supportOpensInBrowser => 'Откроется в браузере';

  @override
  String get supportTapToCopy => 'Нажмите, чтобы скопировать';

  @override
  String get supportCopied => 'Скопировано';

  @override
  String get supportOpenFailed => 'Не удалось открыть ссылку';

  @override
  String get serverNewTitle => 'Новый сервер';

  @override
  String serverFingerprintPrompt(String command) {
    return 'Сверьте отпечаток с серверным. На сервере выполните:\n$command';
  }

  @override
  String get serverFingerprintMatches => 'Совпадает';

  @override
  String get serverForgetTitle => 'Удалить сервер?';

  @override
  String get serverForgetBody =>
      'Адрес и пароль или ключ будут удалены с устройства.';

  @override
  String get serverForgetTooltip => 'Удалить сервер';

  @override
  String get serverLoadFailed => 'Не удалось загрузить сервер';

  @override
  String get serverSecretKeyLabel => 'Приватный ключ (PEM / OpenSSH)';

  @override
  String get serverSectionAddress => 'Адрес';

  @override
  String get serverHostLabel => 'IP или домен';

  @override
  String get serverUserLabel => 'Логин';

  @override
  String get serverPortLabel => 'Порт';

  @override
  String get serverPortNotNumber => 'Число';

  @override
  String get serverSectionLogin => 'Вход';

  @override
  String get serverAuthKey => 'Ключ';

  @override
  String get serverFieldRequired => 'Заполните поле';

  @override
  String serverProfileSubtitle(String username, int port, String auth) {
    return '$username · порт $port · $auth';
  }

  @override
  String get serverAuthByKey => 'по ключу';

  @override
  String get serverAuthByPassword => 'по паролю';

  @override
  String get serverCheck => 'Проверить сервер';

  @override
  String serverOsUnsupported(String os) {
    return '$os: поддерживаются только Ubuntu и Debian';
  }

  @override
  String get serverLoginRoot => 'Вход под root';

  @override
  String get serverLoginNotRoot => 'Вход не под root: установке нужен sudo';

  @override
  String get serverFingerprintPinned => 'Отпечаток закреплён';

  @override
  String get serverErrHostKeyMismatch =>
      'Отпечаток сервера изменился. Это переустановка сервера или перехват соединения. Подключение отклонено.';

  @override
  String get serverErrRejected => 'Подключение отменено';

  @override
  String get serverErrAuth => 'Сервер отклонил пароль или ключ';

  @override
  String get serverErrInvalidKey =>
      'Ключ не читается или нужна парольная фраза';

  @override
  String get serverErrNetwork => 'Сервер недоступен: проверьте адрес и порт';

  @override
  String get serverErrTimeout => 'Сервер не ответил вовремя';

  @override
  String get serverErrSsh => 'Ошибка SSH';

  @override
  String get serverErrCheckFailed => 'Не удалось проверить сервер';

  @override
  String get fixDemoStop => 'Остановить';

  @override
  String get fixDemoStart => 'Запустить демо';

  @override
  String get fixDemoProposalSubtitle => 'ИИ предлагает одну команду';

  @override
  String get fixDemoWorkingTitle => 'Работаем';

  @override
  String get fixDemoConnecting => 'Подключаюсь…';

  @override
  String get fixDemoDoneTitle => 'Готово';

  @override
  String get fixDemoDoneSubtitle => 'Скрипт прошёл после исправления';

  @override
  String get fixDemoStoppedTitle => 'Остановлено';

  @override
  String get fixDemoDeclinedSubtitle => 'Вы отклонили команду';

  @override
  String get fixDemoCancelledSubtitle => 'Запуск прерван';

  @override
  String get fixDemoNotFixedTitle => 'Не исправлено';

  @override
  String fixDemoNoFixSubtitle(String message) {
    return 'ИИ не нашёл безопасной команды: $message';
  }

  @override
  String get fixDemoGaveUpSubtitle => 'Не получилось за несколько попыток';

  @override
  String get fixDemoLostTitle => 'Задача прервалась';

  @override
  String get fixDemoLostSubtitle =>
      'Сервер перезагрузился или не хватило памяти';

  @override
  String get fixDemoErrorTitle => 'Ошибка';

  @override
  String get fixDemoErrorFallback => 'Что-то пошло не так';

  @override
  String fixDemoIdleSubtitle(String path) {
    return 'Демо-скрипт падает без файла $path. ИИ найдёт причину и предложит команду.';
  }

  @override
  String get fixDemoErrHostNotChecked =>
      'Сервер ещё не проверен. Откройте вкладку «Сервер» и нажмите «Проверить сервер».';

  @override
  String fixDemoErrStartFailed(String error) {
    return 'Не удалось запустить\n$error';
  }

  @override
  String get fixDemoDecline => 'Отклонить';

  @override
  String get fixDemoApprove => 'Выполнить';

  @override
  String get fixDemoLogTitle => 'Лог сервера';

  @override
  String get fixDemoLogCollapse => 'Свернуть';

  @override
  String get fixDemoLogShowAll => 'Весь лог';

  @override
  String get llmLoadFailed => 'Не удалось загрузить настройки';

  @override
  String get llmSettingsSaved => 'Настройки сохранены';

  @override
  String get llmClearKeyTitle => 'Удалить ключ?';

  @override
  String get llmClearKeyBody => 'Ключ будет удалён с этого устройства.';

  @override
  String get llmSectionProvider => 'Провайдер';

  @override
  String get llmSectionEndpoint => 'Адрес и модель';

  @override
  String get llmModelLabel => 'Модель';

  @override
  String get llmApiKey => 'API-ключ';

  @override
  String get llmKeySaved => 'Ключ сохранён';

  @override
  String get llmKeyDeleteTooltip => 'Удалить ключ';

  @override
  String get llmSaveKey => 'Сохранить ключ';

  @override
  String get llmSectionCheck => 'Проверка';

  @override
  String get llmCheckConnection => 'Проверить подключение';

  @override
  String get llmCheckFailed => 'Не удалось выполнить проверку';

  @override
  String llmModelReply(String reply) {
    return 'Ответ модели: $reply';
  }

  @override
  String get problemServerNotConfigured => 'Сервер не настроен';

  @override
  String get problemServerOsUnknown => 'Не удалось определить ОС сервера';

  @override
  String get problemAiNotConfigured => 'Сначала настройте ИИ и ключ';

  @override
  String get problemEmptyKey => 'Пустой ключ';

  @override
  String get problemEmptyPassword => 'Пустой пароль';

  @override
  String get problemBaseUrlNotAbsolute =>
      'Нужен полный адрес, например https://api.example.com/v1';

  @override
  String get problemBaseUrlInsecureHttp =>
      'Без https ключ уйдёт открытым текстом. http только для локальной сети';

  @override
  String get problemBaseUrlUnsupportedScheme => 'Поддерживаются только http(s)';

  @override
  String get problemServerBadHost => 'Некорректный адрес сервера';

  @override
  String get problemServerBadPort => 'Порт от 1 до 65535';

  @override
  String get problemServerBadLogin => 'Некорректный логин';

  @override
  String get llmPresetCustom => 'Свой эндпоинт';

  @override
  String get llmCheckNeedSettings => 'Сначала заполните настройки и ключ';

  @override
  String llmCheckFailedWithError(String error) {
    return 'Не удалось выполнить проверку\n$error';
  }

  @override
  String get llmErrForbidden =>
      'Доступ запрещён. Частая причина — регион: включите VPN';

  @override
  String get llmErrUnauthorized =>
      'Ключ не принят: проверьте, что он вставлен целиком';

  @override
  String get llmErrRateLimited => 'Лимит запросов или закончился баланс';

  @override
  String get llmErrNetwork => 'Нет связи с провайдером';

  @override
  String get llmErrServer => 'Ошибка провайдера';

  @override
  String get llmErrBadResponse => 'Провайдер вернул непонятный ответ';

  @override
  String get fixStatusConnecting => 'Подключаюсь к серверу…';

  @override
  String get fixStatusWaitingDecision => 'Ждёт вашего решения';

  @override
  String get fixStepYourDecision => 'Ваше решение';

  @override
  String get fixStepRunScript => 'Запуск скрипта';

  @override
  String fixStepRerun(int round) {
    return 'Повторный запуск $round';
  }

  @override
  String fixStepFix(int round) {
    return 'Исправление $round';
  }

  @override
  String fixLogExitCode(int code) {
    return '── код $code ──';
  }

  @override
  String get fixDetailJobInterrupted => 'Задача прервалась';

  @override
  String fixDetailJobFailedCode(int code) {
    return 'Ошибка, код $code';
  }

  @override
  String fixStatusDiagnosing(int round) {
    return 'ИИ разбирает ошибку (попытка $round)…';
  }

  @override
  String get fixStepDiagnosing => 'ИИ ищет причину';

  @override
  String fixLogBlockedCommand(String reason) {
    return '── ИИ предложил запрещённую команду, отклонено: $reason ──';
  }

  @override
  String get fixDetailCommandForbidden =>
      'Команда запрещена правилами, ИИ попросили другую';

  @override
  String get fixDetailAllowed => 'Разрешено';

  @override
  String get fixDetailDeclined => 'Отклонено';

  @override
  String fixErrAi(String detail) {
    return 'ИИ: $detail';
  }

  @override
  String fixErrAiFormat(String detail) {
    return 'ИИ ответил не по формату\n$detail';
  }

  @override
  String fixErrConnection(String detail) {
    return 'Связь с сервером потеряна\n$detail';
  }

  @override
  String fixErrServer(String detail) {
    return 'Сервер: $detail';
  }

  @override
  String get blockCurlPipeShell =>
      'Скачивание и запуск скрипта из сети (curl | bash)';

  @override
  String get blockPipeToShell =>
      'Передача текста на выполнение в shell через конвейер';

  @override
  String get blockPipeToInterpreter =>
      'Передача текста на выполнение интерпретатору';

  @override
  String get blockRunDownloaded => 'Выполнение того, что скачано из сети';

  @override
  String get blockProcessSubstitution =>
      'Запуск скрипта через подстановку процесса';

  @override
  String get blockEval => 'eval скрывает, что будет выполнено';

  @override
  String get blockDecodeHidden => 'Декодирование скрытого содержимого';

  @override
  String get blockEscapedBytes => 'Экранированные байты в команде';

  @override
  String get blockNoPreserveRoot => 'Удаление корня файловой системы';

  @override
  String get blockFindDelete => 'Массовое удаление через find';

  @override
  String get blockDiskPartitioning => 'Работа с разделами диска';

  @override
  String get blockWriteToDevice => 'Запись прямо на устройство';

  @override
  String get blockForkBomb => 'Fork-бомба';

  @override
  String get blockRebootShutdown => 'Перезагрузка или выключение сервера';

  @override
  String get blockAccountChanges => 'Изменение учётных записей';

  @override
  String get blockCredentialsAccess =>
      'Доступ к ключам, паролям или настройкам входа';

  @override
  String get blockStopSsh => 'Остановка SSH: доступ к серверу пропадёт';

  @override
  String get blockFirewallReset => 'Сброс сетевого экрана';

  @override
  String get blockRawNetwork =>
      'Сырое сетевое соединение (возможна утечка данных)';

  @override
  String get blockKillAll => 'Завершение всех процессов';

  @override
  String get blockCronRemoval => 'Удаление всех заданий cron';

  @override
  String get blockHistoryHiding => 'Сокрытие истории команд';

  @override
  String get blockInteractiveSu =>
      'Интерактивный вход под другим пользователем';

  @override
  String get blockSolagentDir => 'Служебный каталог SolAgent';

  @override
  String get blockDownloadAndRun => 'Скачивание и запуск файла из сети';

  @override
  String get blockXargsExec => 'Выполнение текста через xargs';

  @override
  String get blockEmpty => 'Пустая команда';

  @override
  String get blockTooLong => 'Слишком длинная команда';

  @override
  String get blockControlChars => 'Невидимые управляющие символы';

  @override
  String get blockRecursiveDelete =>
      'Рекурсивное удаление корня, домашнего или системного каталога';

  @override
  String get blockRecursiveChmod =>
      'Рекурсивная смена прав на системном каталоге';

  @override
  String get warnRoot => 'Выполняется с правами root';

  @override
  String get warnRm => 'Удаляет файлы без вопросов';

  @override
  String get warnPackages => 'Удаляет пакеты';

  @override
  String get warnService => 'Останавливает или перезапускает службу';

  @override
  String get warnDocker => 'Удаляет контейнеры или данные Docker';

  @override
  String get warnChmod777 => 'Открывает файл всем на запись';

  @override
  String get warnEtcOverwrite => 'Перезаписывает системный файл';

  @override
  String get warnKill => 'Завершает процессы';

  @override
  String get warnDownload => 'Скачивает из сети';

  @override
  String get warnFirewall => 'Меняет сетевой экран';

  @override
  String get guardReason => 'Подтвердите личность для доступа к серверу';

  @override
  String get guardUnavailable =>
      'На устройстве не настроена блокировка экрана или отпечаток. Включите её в настройках телефона: без неё доступ к серверу закрыт.';

  @override
  String get guardDenied => 'Доступ закрыт';

  @override
  String get guardChecking => 'Проверка…';

  @override
  String get guardUnlock => 'Разблокировать';

  @override
  String get ragSectionTitle => 'База знаний';

  @override
  String get ragHint =>
      'Документация и проверенные решения помогают ИИ с типовыми ошибками. Отправляется только очищенный фрагмент ошибки.';

  @override
  String get ragAddressLabel => 'Адрес сервера';

  @override
  String get ragKeyLabel => 'Ключ доступа';

  @override
  String get ragSaveKey => 'Сохранить ключ доступа';

  @override
  String get ragKeySaved => 'Ключ доступа сохранён';

  @override
  String get ragKeyDeleteTooltip => 'Удалить ключ доступа';

  @override
  String get ragClearKeyTitle => 'Удалить ключ доступа?';

  @override
  String get ragClearKeyBody => 'ИИ будет чинить без базы знаний.';

  @override
  String get ragCheck => 'Проверить базу знаний';

  @override
  String ragCheckOk(int count) {
    return 'Подключено. Найдено фрагментов: $count';
  }

  @override
  String get ragErrUnauthorized => 'Сервер отклонил ключ.';

  @override
  String ragErrRateLimited(int seconds) {
    return 'Слишком много запросов. Повторите через $seconds с.';
  }

  @override
  String get ragErrNetwork => 'Не удалось связаться с базой знаний.';

  @override
  String ragErrServer(int status) {
    return 'База знаний вернула ошибку (HTTP $status).';
  }

  @override
  String get ragErrBadResponse => 'Неожиданный ответ базы знаний.';

  @override
  String get ragNoKey => 'Сначала сохраните ключ доступа.';

  @override
  String get monitorChannelName => 'Ход установки';

  @override
  String get monitorTitle => 'SolAgent: идёт установка';

  @override
  String get monitorStarting => 'Запускаю…';

  @override
  String monitorStep(String step) {
    return 'Шаг: $step';
  }

  @override
  String get monitorWaiting =>
      'Нет связи с сервером, повторяю. Установка продолжается.';

  @override
  String get monitorFinishedOk => 'Установка завершена';

  @override
  String get monitorFinishedFailed => 'Установка завершилась с ошибкой';

  @override
  String get monitorLost => 'Процесс установки остановлен на сервере';
}
