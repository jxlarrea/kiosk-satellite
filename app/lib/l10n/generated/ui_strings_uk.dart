// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class UiStringsUk extends UiStrings {
  UiStringsUk([String locale = 'uk']) : super(locale);

  @override
  String get aboutApp => 'Застосунок';

  @override
  String get aboutVersion => 'Версія застосунку';

  @override
  String get aboutBuild => 'Збірка';

  @override
  String get aboutPackage => 'Пакет';

  @override
  String get aboutAttribution => 'Подяки та ліцензії';

  @override
  String get aboutAuthor => 'Автор';

  @override
  String get aboutWebsite => 'Вебсайт';

  @override
  String get aboutSourceCode => 'Вихідний код';

  @override
  String get aboutLicense => 'Ліцензія';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite безкоштовний для особистого, некомерційного використання. Він ліцензований за CC BY-NC-ND 4.0: ви можете використовувати та ділитися ним, але комерційне використання програми та розповсюдження змінених збірок заборонені. Незалежні плагіни мають додатковий дозвіл відповідно до PLUGIN-EXCEPTION.md.';

  @override
  String get aboutLocalizationCredits => 'Автори перекладу';

  @override
  String get aboutLocalizationCreditsHint => 'Контрибутори за мовами';

  @override
  String get aboutCheckNow => 'Перевірити оновлення зараз';

  @override
  String get aboutChecking => 'Перевірка…';

  @override
  String get aboutCheckFailed =>
      'Помилка перевірки оновлення. Чи має пристрій доступ до GitHub?';

  @override
  String get aboutOverlayMissing =>
      'Відсутній дозвіл «Показ поверх інших додатків»';

  @override
  String get aboutOverlayHelp =>
      'Без нього застосунок не зможе знову відкритися після оновлення. Вікно надання дозволу з’явиться на планшеті.';

  @override
  String aboutDownloadProgress(String percent) {
    return 'Завантаження… $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return 'Не вдалося завантажити оновлення: $error';
  }

  @override
  String get aboutAlreadyCurrent => 'Встановлено актуальну версію.';

  @override
  String get aboutInstallHelp =>
      'Завантаження виконується на планшеті; встановлення має бути підтверджено на екрані планшета.';

  @override
  String get androidAccessibilityHelp =>
      'Закриває панель сповіщень та екран нещодавніх програм щоразу, коли вони відкриваються, доки режим кіоска або захищений режим блокує екран. Kiosk Satellite не зчитує вміст екрана.';

  @override
  String get androidServiceChannelHelp =>
      'Відображається, коли служба Kiosk Satellite підтримує роботу програми з вимкненим екраном або у фоновому режимі.';

  @override
  String get androidServiceListening => 'очікування слова активації';

  @override
  String get androidServiceRtspAudio => 'RTSP-аудіо мікрофона ввімкнено';

  @override
  String get androidServiceEsphome => 'робота сервера ESPHome';

  @override
  String get androidServiceBluetooth => 'ретрансляція Bluetooth-пристроїв';

  @override
  String get androidServiceCamera => 'спостереження через камеру';

  @override
  String get androidServiceLocation => 'передача місцезнаходження';

  @override
  String get androidServiceRemote => 'робота віддаленого адміністрування';

  @override
  String get androidServiceKiosk => 'захист режиму кіоска';

  @override
  String get androidServiceSessions => 'підтримка з\'єднання з Home Assistant';

  @override
  String get launcherErrorAndroidOnly =>
      'перелік програм доступний лише на Android';

  @override
  String launcherErrorListDetail(String error) {
    return 'не вдалося отримати список програм: $error';
  }

  @override
  String launcherOpenFailed(String name) {
    return 'Не вдалося відкрити $name';
  }

  @override
  String get launcherUninstalled => 'Можливо, її було видалено.';

  @override
  String get launcherNoneHelp =>
      'Поки що немає. Виберіть програми, які пропонує лаунчер.';

  @override
  String get launcherNone => 'Поки що немає';

  @override
  String get launcherListFailed => 'Не вдалося отримати список програм';

  @override
  String launcherListError(String error) {
    return 'Не вдалося отримати список програм: $error';
  }

  @override
  String get launcherListingFailed => 'помилка отримання списку';

  @override
  String get launcherEmpty => 'Програм для запуску не знайдено.';

  @override
  String get cameraViewerTitle => 'Перегляд камери';

  @override
  String get cameraViewerConnecting => 'З\'єднання...';

  @override
  String get cameraViewerReconnecting => 'Повторне з\'єднання...';

  @override
  String cameraViewerTrying(String transport) {
    return 'Спроба $transport...';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return 'Цей пристрій не може декодувати $codec';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return 'Цей пристрій не підтримує відтворення потоків $transport';
  }

  @override
  String get cameraViewerCannotDecodeStream =>
      'Цей пристрій не може декодувати цей потік';

  @override
  String cameraViewerHaRetry(String seconds) {
    return 'Немає зв\'язку з Home Assistant. Повторна спроба через $seconds с';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return 'Немає зв\'язку з сервером камери. Повторна спроба через $seconds с';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return 'Збій з\'єднання. Повторна спроба через $seconds с';
  }

  @override
  String get cameraViewerStartRetry =>
      'Сервер камери не зміг запустити цей потік. Повторна спроба...';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return 'Сервер камери не зміг запустити цей потік. Повторна спроба через $seconds с';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return 'Потік не знайдено на сервері камери. Повторна спроба через $seconds с';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return 'Сервер камери відхилив вхід. Повторна спроба через $seconds с';
  }

  @override
  String get cameraViewerMissing => 'Потік відсутній у Go2RTC';

  @override
  String get commonImport => 'Імпорт';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonNext => 'Далі';

  @override
  String get commonFinish => 'Завершити';

  @override
  String get commonWorking => 'Обробка…';

  @override
  String get commonSettings => 'Налаштування';

  @override
  String get commonCancel => 'Скасувати';

  @override
  String get commonOk => 'OK';

  @override
  String get commonGrant => 'Надати';

  @override
  String get commonEnable => 'Увімкнути';

  @override
  String get commonRefresh => 'Оновити';

  @override
  String get commonTest => 'Тест';

  @override
  String get commonInstall => 'Встановити';

  @override
  String get commonSave => 'Зберегти';

  @override
  String get commonRetry => 'Повторити';

  @override
  String get commonCopy => 'Копіювати';

  @override
  String get commonAdd => 'Додати';

  @override
  String get commonRemove => 'Вилучити';

  @override
  String get commonClose => 'Закрити';

  @override
  String get commonClear => 'Очистити';

  @override
  String get commonBrowse => 'Огляд';

  @override
  String get commonSet => 'Встановити';

  @override
  String get commonHour => 'Година';

  @override
  String get commonMinute => 'Хвилина';

  @override
  String get commonUp => 'Вгору';

  @override
  String get commonDown => 'Вниз';

  @override
  String get commonDelete => 'Видалити';

  @override
  String get commonSaveFailed => 'Не вдалося зберегти зміни';

  @override
  String get commonColorWhite => 'Білий';

  @override
  String get commonColorWarm => 'Теплий білий';

  @override
  String get commonColorAmber => 'Бурштиновий';

  @override
  String get commonColorRed => 'Червоний';

  @override
  String get commonColorGreen => 'Зелений';

  @override
  String get commonColorBlue => 'Синій';

  @override
  String get commonColorCyan => 'Блакитний';

  @override
  String get commonColorDim => 'Тьмяний';

  @override
  String get commonEdit => 'Редагувати';

  @override
  String get commonMoveUp => 'Перемістити вгору';

  @override
  String get commonMoveDown => 'Перемістити вниз';

  @override
  String get commonPreviousMonth => 'Попередній місяць';

  @override
  String get commonNextMonth => 'Наступний місяць';

  @override
  String get commonLoading => 'Завантаження…';

  @override
  String get commonChoose => 'Вибрати';

  @override
  String get dlnaPortInvalid =>
      'Введіть порт від 1024 до 65535 або залиште поле порожнім';

  @override
  String get commonSelectAll => 'Вибрати все';

  @override
  String get dlnaCannotDecode => 'Цей пристрій не може декодувати це відео.';

  @override
  String get dlnaCannotRead => 'Не вдалося прочитати цей файл.';

  @override
  String get dlnaCannotPlay => 'Не вдалося відтворити це медіа.';

  @override
  String get dlnaSeeLogs => 'Докладніше дивіться в журналі програми';

  @override
  String get dlnaLoading => 'Завантаження медіа';

  @override
  String get dlnaImageFailed => 'Не вдалося відобразити це зображення.';

  @override
  String get dlnaStop => 'Зупинити відтворення';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName: $actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => 'Дія плагіна';

  @override
  String get drawerPluginActionError => 'Не вдалося виконати цю дію.';

  @override
  String get drawerDashboard => 'Панель керування';

  @override
  String get drawerHaKiosk => 'Режим кіоска HA';

  @override
  String get drawerCameraView => 'Перегляд камери';

  @override
  String get drawerIntercom => 'Інтерком';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => 'Сховати плеєр';

  @override
  String get drawerShowPlayer => 'Показати плеєр';

  @override
  String get drawerNowPlaying => 'Зараз грає';

  @override
  String get drawerScreensaver => 'Заставка';

  @override
  String get drawerLockdown => 'Блокування';

  @override
  String get drawerHoldOff => 'Вимкнути утримання';

  @override
  String get drawerHoldOn => 'Увімкнути утримання';

  @override
  String get drawerApps => 'Застосунки';

  @override
  String get drawerClearCache => 'Очистити кеш';

  @override
  String get drawerRestartDevice => 'Перезавантажити пристрій';

  @override
  String get drawerRestartConfirm =>
      'Перезавантажити цей пристрій? Kiosk Satellite повернеться після завантаження системи.';

  @override
  String get drawerRestart => 'Перезавантажити';

  @override
  String get drawerExitApplication => 'Вийти з Kiosk Satellite';

  @override
  String get drawerExitConfirm => 'Закрити Kiosk Satellite?';

  @override
  String get drawerExit => 'Вийти';

  @override
  String get drawerHoldActive => 'Утримання екрана активне';

  @override
  String get drawerHoldHelp =>
      'Заставку й таймери призупинено · торкніться, щоб вимкнути';

  @override
  String get drawerThemeDark => 'Темна тема';

  @override
  String get drawerThemeLight => 'Світла тема';

  @override
  String get drawerThemeAndroid => 'Системна тема';

  @override
  String drawerVersion(String version) {
    return 'Версія $version';
  }

  @override
  String get drawerUpdateAvailable => 'Доступне оновлення';

  @override
  String drawerUpdateInstall(String version) {
    return 'Версія $version · торкніться для встановлення';
  }

  @override
  String get drawerUpdateChecking => 'Перевірка оновлень…';

  @override
  String get drawerUpdateCurrent => 'Остання версія';

  @override
  String get drawerUpdateCurrentHelp => 'Ви використовуєте найновішу версію.';

  @override
  String get drawerUpdateCheckFailed => 'Помилка перевірки оновлення';

  @override
  String get drawerUpdateOffline => 'Чи пристрій підключений до мережі?';

  @override
  String drawerUpdateTo(String version) {
    return 'Оновити до версії $version';
  }

  @override
  String get drawerUpdateInstructions =>
      'Завантаження починається після натискання «Оновити». Android попросить вас підтвердити встановлення.';

  @override
  String get drawerUpdateRelaunch =>
      'Без дозволу \"Показ поверх інших додатків\" застосунок не зможе відкритися знову після оновлення.';

  @override
  String get drawerUpdate => 'Оновити';

  @override
  String get drawerUpdateDownloading => 'Завантаження оновлення…';

  @override
  String get drawerUpdateStarting => 'Запуск встановлення…';

  @override
  String get drawerUpdateFailed => 'Помилка оновлення';

  @override
  String get drawerUpdates => 'Оновлення';

  @override
  String get drawerNoReleaseNotes => 'Примітки до випуску відсутні.';

  @override
  String get esphomeAllExposed => 'Усі доступні сутності надано';

  @override
  String esphomeExcludedCount(String count) {
    return '$count виключено';
  }

  @override
  String get esphomeEntitySearch => 'Пошук сутностей';

  @override
  String get esphomeEntityLoading => 'Завантаження сутностей…';

  @override
  String get esphomeEntityUnavailable => 'Наразі недоступно';

  @override
  String get esphomeEntityNoMatch => 'Немає відповідних сутностей';

  @override
  String get esphomeEntityLoadFailed =>
      'Не вдалося завантажити сутності. Закрийте вікно вибору та спробуйте знову.';

  @override
  String get esphomeEntitySaveFailed =>
      'Не вдалося зберегти виключення. Спробуйте знову.';

  @override
  String get esphomeTypeConfig => 'Конфігурація';

  @override
  String get esphomeTypeDiagnostics => 'Діагностика';

  @override
  String get esphomeTypeSensorGroup => 'Датчик';

  @override
  String get esphomeTypeControl => 'Керування';

  @override
  String get esphomeTypeSensor => 'датчик';

  @override
  String get esphomeTypeTextSensor => 'текстовий датчик';

  @override
  String get esphomeTypeBinarySensor => 'бінарний датчик';

  @override
  String get esphomeTypeCamera => 'камера';

  @override
  String get esphomeTypeSwitch => 'перемикач';

  @override
  String get esphomeTypeButton => 'кнопка';

  @override
  String get esphomeTypeNumber => 'число';

  @override
  String get esphomeTypeSelect => 'вибір';

  @override
  String get esphomeTypeLight => 'світло';

  @override
  String get esphomeTypeUpdate => 'оновлення';

  @override
  String get esphomeTypeText => 'текст';

  @override
  String get filesUpload => 'Завантажити файл';

  @override
  String get filesUploading => 'Завантаження…';

  @override
  String get filesUploadFailed => 'Помилка завантаження';

  @override
  String get filesUploaded => 'Завантажено';

  @override
  String get filesPermissionMissing =>
      'Відсутній дозвіл \"Доступ до всіх файлів\"';

  @override
  String get filesPermissionHelp =>
      'Без нього можна переглядати лише теку програми. Екран надання дозволу відкриється на планшеті.';

  @override
  String get filesGrant => 'Надати на пристрої';

  @override
  String get filesUp => 'На рівень вгору';

  @override
  String get filesShared => 'Спільне сховище';

  @override
  String get filesApp => 'Тека програми';

  @override
  String get filesReadFailed => 'Не вдалося прочитати теку';

  @override
  String get filesEmpty => 'Порожня тека';

  @override
  String get filesEmptyHelp => 'Тут поки що нічого немає.';

  @override
  String get filesFolder => 'Тека';

  @override
  String get filesDownload => 'Завантажити';

  @override
  String get filesDownloadFailed => 'Помилка завантаження';

  @override
  String filesDeleteTitle(String name) {
    return 'Видалити $name?';
  }

  @override
  String get filesDeleteHelp => 'Файл буде видалено з пристрою.';

  @override
  String get filesInvalidPath => 'Недійсний шлях';

  @override
  String get filesNoFolder => 'Такої теки не існує';

  @override
  String get filesNoFile => 'Такого файлу не існує';

  @override
  String filesReadError(String error) {
    return 'Не вдалося прочитати теку: $error';
  }

  @override
  String filesWriteError(String error) {
    return 'Помилка запису: $error';
  }

  @override
  String get filesDeleteFailed => 'Не вдалося видалити файл';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin =>
      'Для керування групою потрібне віддалене адміністрування';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Кіоски знаходять один одного через нього. Увімкніть \"Віддалене керування\" та \"Пошук інших кіосків\" у розділі \"Пристрій\", а потім поверніться.';

  @override
  String get fleetLeadThisFleet => 'Керувати цією групою';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      'Синхронізувати налаштування цього кіоска з підпорядкованими. Вимагає однакової версії програми на всіх кіосках.';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead =>
      'Підпорядкований кіоск не може бути головним.';

  @override
  String get fleetFollowers => 'Підпорядковані кіоски';

  @override
  String get fleetProfiles => 'Профілі';

  @override
  String get fleetLeader => 'Головний пристрій';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      'Дізнайтеся, які налаштування синхронізуються, а які ні, у ';

  @override
  String get fleetFleetManagementDocumentation =>
      'документації з керування групою';

  @override
  String get fleetMore => 'Більше';

  @override
  String get fleetSearchFollowers =>
      'Кіоски під керуванням цього пристрою, їх стан та можливість додавання.';

  @override
  String get fleetAddAKiosk => 'Додати кіоск';

  @override
  String get fleetKiosksMemberOfTheFleetAFollowerMustConfirm =>
      'Додайте виявлений кіоск або введіть його IP-адресу. Підпорядкований кіоск повинен підтвердити запрошення на своєму екрані.';

  @override
  String get fleetSendInvitation => 'Надіслати запрошення';

  @override
  String get fleetInviteAgain => 'Запросити знову';

  @override
  String fleetRemoveName(String name) {
    return 'Вилучити $name?';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      'Він перестане слідувати за цим кіоском і збереже власні налаштування.';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name хоче керувати цим кіоском';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      'Його налаштування замінять поточні у вибраних категоріях синхронізації відтепер. Цей кіоск збереже своє ім\'я та ідентифікатор.';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      'Його налаштування замінять поточні у вибраних категоріях синхронізації відтепер. Цей кіоск збереже своє ім\'я, інтеграції Home Assistant, Music Assistant, ESPHome та вибір апаратних засобів. Ви можете вийти з групи в будь-який час у розділі Налаштування > Керування групою.';

  @override
  String get fleetConfirmOnTheKioskItselfTheInvitationIsWaiting =>
      'Підтвердіть дію на самому кіоску. Запрошення очікує на його екрані та у розділі Налаштування > Керування групою.';

  @override
  String get fleetAccept => 'Прийняти';

  @override
  String get fleetLookingForOtherKiosks => 'Пошук інших кіосків…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      'Кіосків не знайдено. Скористайтеся пунктом \"Додати за IP\", щоб знайти за відомою адресою.';

  @override
  String fleetFollowsName(String name) {
    return 'Слідує за $name';
  }

  @override
  String get fleetLeadsAFleet => 'Керує групою';

  @override
  String get fleetNoFleetManagement => 'Без керування групою';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      'Кіоски в цій мережі, які не підпорядковані цьому пристрою. Виберіть потрібний, щоб налаштувати синхронізацію та надіслати запрошення. Кіоск на збірці без керування групою приєднається після її встановлення.';

  @override
  String get fleetJoinedTheFleet => 'Приєднано до групи';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly =>
      'Налаштування від головного пристрою незабаром надійдуть.';

  @override
  String get fleetAddByIp => 'Додати за IP';

  @override
  String get fleetFindKiosk => 'Знайти кіоск';

  @override
  String get fleetFindingKiosk => 'Пошук кіоска…';

  @override
  String get fleetIpAddress => 'IP-адреса';

  @override
  String get fleetRemoteAdminPort => 'Порт віддаленого адміністрування';

  @override
  String get fleetAddressHelp =>
      'Введіть IP-адресу кіоска та порт віддаленого адміністрування.';

  @override
  String get fleetAddAProfile => 'Додати профіль';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      'Набір налаштувань, облікових даних та виключень для синхронізації.';

  @override
  String get fleetNewProfile => 'Новий профіль';

  @override
  String get fleetProfile => 'Профіль';

  @override
  String get fleetUpdatesOnly => 'Лише оновлення';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed =>
      'Нічого не синхронізується. Надсилаються лише оновлення.';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return 'Категорії: $selected з $total. Облікові дані: $credentials з $credentialTotal. Виключено: $excluded.';
  }

  @override
  String get fleetThisProfileIsGone => 'Цей профіль зник';

  @override
  String get fleetItWasDeletedFromAnotherPage =>
      'Його було видалено з іншої сторінки.';

  @override
  String get fleetName => 'Назва';

  @override
  String get fleetRename => 'Перейменувати';

  @override
  String get fleetRenameProfile => 'Перейменувати профіль';

  @override
  String get fleetWhatItSyncs => 'Що синхронізується';

  @override
  String get fleetNothing => 'Нічого';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      'Кіоски з цим профілем зберігають усі власні налаштування. Головний пристрій лише надсилає їм оновлення.';

  @override
  String get fleetCategories => 'Категорії';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected з $total: $names';
  }

  @override
  String get fleetCredentials => 'Облікові дані';

  @override
  String get fleetNoneTravel => 'Не передаються';

  @override
  String get fleetIncludeTheDashboard => 'Включити інформаційну панель';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard =>
      'Початкова сторінка та типова інформаційна панель.';

  @override
  String get fleetExcludedSettings => 'Виключені налаштування';

  @override
  String get fleetOneSettingLeftOut => 'Одне налаштування пропущено';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return 'Пропущено налаштувань: $count';
  }

  @override
  String get fleetNoKiosksAssigned => 'Кіоски не призначено';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      'Призначте цей профіль кіоску на сторінці керування групою.';

  @override
  String get fleetDuplicate => 'Дублювати';

  @override
  String get fleetCloneThisProfileIntoANewOne =>
      'Клонувати цей профіль у новий.';

  @override
  String get fleetDuplicateProfile => 'Дублювати профіль';

  @override
  String fleetNameCopy(String name) {
    return 'Копія $name';
  }

  @override
  String get fleetDeleteProfile => 'Видалити профіль';

  @override
  String get fleetNoKioskIsOnIt => 'Немає призначених кіосків.';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile =>
      'Кіоски з цим профілем отримають типовий профіль.';

  @override
  String fleetDeleteName(String name) {
    return 'Видалити $name?';
  }

  @override
  String get fleetBlackScreens => 'Чорні екрани';

  @override
  String fleetSyncToName(String name) {
    return 'Синхронізувати з $name';
  }

  @override
  String get fleetDefault => 'Типовий';

  @override
  String get fleetNone => 'Немає';

  @override
  String get fleetSearchProfiles =>
      'Іменовані списки для підпорядкованих пристроїв: категорії, облікові дані, панель та виключені налаштування.';

  @override
  String get fleetSyncNow => 'Синхронізувати зараз';

  @override
  String get fleetChangedHereWaitingForTheLeader =>
      'Змінено тут, очікування головного пристрою';

  @override
  String fleetSyncedTime(String time) {
    return 'Синхронізовано $time';
  }

  @override
  String get fleetWaitingForTheFirstSync => 'Очікування першої синхронізації';

  @override
  String get fleetNothingYet => 'Поки що нічого';

  @override
  String get fleetNoCredentials => 'Немає облікових даних';

  @override
  String fleetWithTheNames(String names) {
    return 'З $names';
  }

  @override
  String get fleetTheDashboard => 'інформаційна панель';

  @override
  String get fleetNoDashboard => 'без інформаційної панелі';

  @override
  String get fleetTheDashboardDetail => 'Інформаційна панель';

  @override
  String get fleetNoDashboardDetail => 'Без інформаційної панелі';

  @override
  String get fleetSyncedFromTheLeader => 'Синхронізовано з головного пристрою';

  @override
  String get fleetLeaveTheFleet => 'Залишити групу';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre =>
      'Зупиняє синхронізацію. Налаштування залишаються без змін.';

  @override
  String get fleetLeaveTheFleetDetail => 'Залишити групу?';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name припиняє надсилати налаштування сюди. Усе залишається так, як є зараз.';
  }

  @override
  String get fleetLeave => 'Залишити';

  @override
  String get fleetJustNow => 'щойно';

  @override
  String fleetCountMinAgo(String count) {
    return '$count хв тому';
  }

  @override
  String fleetCountHAgo(String count) {
    return '$count год тому';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return '$count дн. тому';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return '$name керує цими налаштуваннями. Зміна тут буде замінена під час наступної синхронізації.';
  }

  @override
  String get fleetDeclinedOnTheKiosk => 'Відхилено на кіоску';

  @override
  String get fleetWaitingForItsOk => 'Очікування підтвердження';

  @override
  String get fleetLeftTheFleet => 'Залишив групу';

  @override
  String fleetSendingPercent(String percent) {
    return 'Надсилання $percent%';
  }

  @override
  String get fleetInstalling => 'Встановлення';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return 'Версія $version, цей кіоск потребує оновлення';
  }

  @override
  String fleetNeedsVersion(String version) {
    return 'Потрібна $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return 'Завантаження $percent%';
  }

  @override
  String get fleetSyncing => 'Синхронізація…';

  @override
  String get fleetErrorUnreachable => 'Недоступний';

  @override
  String get fleetErrorBadAnswer => 'Некоректна відповідь';

  @override
  String get fleetErrorThePushFailed => 'Помилка надсилання';

  @override
  String get fleetErrorLeadThisFleetIsOff => 'Керування цією групою вимкнено';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      'Віддалене керування та пошук інших кіосків мають бути увімкнені';

  @override
  String get fleetErrorPickAnotherKiosk => 'Виберіть інший кіоск';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      'Цей кіоск зараз відсутній у мережі';

  @override
  String get fleetErrorThatKioskDidNotAnswer => 'Цей кіоск не відповів';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation =>
      'Цей кіоск відхилив запрошення';

  @override
  String get fleetErrorTheDefaultProfileStays => 'Типовий профіль залишається';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays =>
      'Профіль \"Лише оновлення\" залишається';

  @override
  String get fleetErrorNoSuchProfile => 'Немає такого профілю';

  @override
  String get fleetErrorNoSuchFollower =>
      'Немає такого підпорядкованого пристрою';

  @override
  String get fleetErrorNoInvitationIsWaiting => 'Немає очікуваних запрошень';

  @override
  String get fleetErrorMalformedInvitation => 'Пошкоджене запрошення';

  @override
  String get fleetErrorCouldNotMintAToken => 'Не вдалося згенерувати токен';

  @override
  String get fleetErrorNotAFollowerYet => 'ще не підпорядкований';

  @override
  String get fleetErrorOffline => 'офлайн';

  @override
  String get fleetErrorUpToDate => 'актуально';

  @override
  String get fleetErrorAlreadyDownloading => 'вже завантажується';

  @override
  String get fleetErrorDidNotAnswer => 'не відповів';

  @override
  String get fleetErrorDidNotTakeTheUpload => 'не прийняв завантаження';

  @override
  String fleetProfileNameExists(String name) {
    return 'Профіль з назвою $name вже існує';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return 'вже на версії $version';
  }

  @override
  String get fleetUnsupportedBuild =>
      'На цьому кіоску встановлено версію без підтримки керування групою. Він приєднається, коли отримає оновлення.';

  @override
  String get fleetErrorAddressMismatch =>
      'Адреса належить іншому кіоску або групі';

  @override
  String get fleetErrorInvalidIp => 'Введіть дійсну IP-адресу.';

  @override
  String get fleetErrorInvalidPort => 'Введіть порт від 1 до 65535.';

  @override
  String get fleetErrorIdentityNotReady =>
      'Ідентифікатор цього кіоска ще не готовий. Спробуйте знову.';

  @override
  String get fleetErrorInvalidIdentity =>
      'За цією адресою не отримано дійсного ідентифікатора кіоска.';

  @override
  String get fleetErrorAlreadyMember => 'Цей кіоск уже належить до цієї групи.';

  @override
  String get fleetErrorIsLeader => 'Цей кіоск уже керує групою.';

  @override
  String get fleetErrorOtherLeader =>
      'Цей кіоск уже підпорядкований іншому головному пристрою.';

  @override
  String get fleetSwitchKiosk => 'Перемкнути кіоск';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      'Виявлені кіоски та збережені учасники групи. Вибір одного з них відкриє його віддалене адміністрування тут, на цій самій сторінці.';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      'Інших кіосків не знайдено. Кіоски з\'являються за допомогою мережевого виявлення або через членство у групі.';

  @override
  String get fleetSyncedCredentials => 'Синхронізовані облікові дані';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced =>
      'Налаштування з цього списку не будуть синхронізуватися з підпорядкованими кіосками.';

  @override
  String get fleetNothingLeftOut => 'Нічого не пропущено';

  @override
  String get fleetSyncItAgain => 'Синхронізувати знову';

  @override
  String get fleetAddASetting => 'Додати налаштування';

  @override
  String get fleetExcludeASetting => 'Виключити налаштування';

  @override
  String get fleetSearchSettings => 'Пошук налаштувань';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return 'Ще $count. Введіть текст, щоб звузити список.';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return 'Не синхронізується: $note';
  }

  @override
  String get fleetTheAssignedSatellite => 'призначений голосовий сателіт';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain =>
      'пристрої мікрофона та динаміка, підсилення мікрофона';

  @override
  String get fleetTheDeviceCamera => 'камера пристрою';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      'відстежуваний плеєр, ідентифікатор плеєра Sendspin';

  @override
  String get fleetNodeNameMacEncryptionKey =>
      'назва вузла, MAC, ключ шифрування';

  @override
  String get fleetThePinIsAlsoSynced => 'PIN-код також синхронізується';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential =>
      'ключ, якщо він не синхронізується як облікові дані';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'ім\'я, віддалене керування, виправлення рендерера, масштаб';

  @override
  String get fleetHomeAssistantToken => 'Токен Home Assistant';

  @override
  String get fleetMusicAssistantToken => 'Токен Music Assistant';

  @override
  String get fleetImmichApiKey => 'Ключ API Immich';

  @override
  String get fleetUpdateTheFleet => 'Оновити групу';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      'Оновити всю групу до версії Kiosk Satellite, встановленої на головному пристрої.';

  @override
  String get fleetKeepFollowersOnThisVersion =>
      'Залишати підпорядковані кіоски на цій версії';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      'Автоматично оновлювати всі підпорядковані кіоски до версії Kiosk Satellite, що працює на головному пристрої.';

  @override
  String get fleetNothingToUpdate => 'Нічого оновлювати';

  @override
  String get fleetUpdating => 'Оновлення';

  @override
  String fleetNamesInstalling(String names) {
    return 'Встановлення $names.';
  }

  @override
  String get fleetSearchUpdates =>
      'Встановіть реліз спочатку на кожен підпорядкований кіоск, а потім тут.';

  @override
  String get gestureAction => 'Дія';

  @override
  String get gestureNavigate => 'Перейти до вигляду панелі керування';

  @override
  String get gestureUrl => 'Відкрити веб-сторінку';

  @override
  String get gestureCameraView => 'Показати перегляд камери';

  @override
  String get gestureLauncher => 'Відкрити панель запуску програм';

  @override
  String get gestureIntercomOpen => 'Відкрити \"Виклик кіоска\"';

  @override
  String get gestureIntercomCall => 'Викликати кіоск';

  @override
  String get gestureScreensaver => 'Запустити заставку';

  @override
  String get gestureScreensaverStop => 'Зупинити заставку';

  @override
  String get gestureHoldMode => 'Перемкнути режим блокування';

  @override
  String get gestureHaKiosk => 'Перемкнути режим кіоска HA';

  @override
  String get gesturePluginRun => 'Виконати дію плагіна';

  @override
  String get gestureLaunchApp => 'Відкрити іншу програму';

  @override
  String get gestureDeepLink => 'Відкрити deep link';

  @override
  String get gestureAndroidSettings => 'Відкрити налаштування Android';

  @override
  String get gestureService => 'Викликати службу';

  @override
  String get gestureScript => 'Запустити скрипт';

  @override
  String get gestureAutomation => 'Запустити автоматизацію';

  @override
  String get gestureEvent => 'Надіслати подію';

  @override
  String get gesturePluginAction => 'Дія плагіна';

  @override
  String get gesturePluginActions => 'Дії плагіна';

  @override
  String get gesturePluginHelp =>
      'Спочатку ввімкніть плагін із діями у менеджері плагінів.';

  @override
  String get gesturePluginFailed => 'Не вдалося завантажити дії плагіна.';

  @override
  String get gestureUrlError => 'Введіть повну URL-адресу http(s).';

  @override
  String get gesturePackage => 'Назва пакета';

  @override
  String get gesturePackageError => 'Введіть назву пакета.';

  @override
  String get gestureUriError => 'Введіть повний URI.';

  @override
  String get gestureNoDashboards => 'Немає панелей керування';

  @override
  String get gestureDashboardsFailed => 'Не вдалося отримати список панелей';

  @override
  String get gestureHaConnected => 'Чи підключено Home Assistant?';

  @override
  String get gestureDashboardsHelp =>
      'Не вдалося отримати список панелей керування. Чи підключено Home Assistant?';

  @override
  String get gestureCameraTitle => 'Перегляд камери';

  @override
  String gestureCameraShow(String name) {
    return 'Показати $name';
  }

  @override
  String get gestureCameraClose => 'Закрити перегляд камери';

  @override
  String get gestureCameraEmpty => 'Перегляди камер ще не налаштовані.';

  @override
  String get gestureIntercomEmpty => 'У мережі ще не знайдено жодного кіоска.';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '$count дотиків у кут $corner';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return 'Утримуйте кут $corner протягом $seconds с';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return 'Подвійний дотик $count пальцями';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return 'Дотик $count пальцями';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return 'Утримання $count пальцями протягом $seconds с';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return 'Послідовність кутів: $sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '$count оплесків';
  }

  @override
  String get gestureDescribeOpenHand => 'Показати відкриту долоню';

  @override
  String gestureDescribeOneFinger(String count) {
    return 'Показати $count палець';
  }

  @override
  String gestureDescribeFingers(String count) {
    return 'Показати $count пальців';
  }

  @override
  String get gestureTopLeft => 'верхній лівий';

  @override
  String get gestureTopRight => 'верхній правий';

  @override
  String get gestureBottomLeft => 'нижній лівий';

  @override
  String get gestureBottomRight => 'нижній правий';

  @override
  String gestureGoTo(String value) {
    return 'Перейти до $value';
  }

  @override
  String gestureOpen(String value) {
    return 'Відкрити $value';
  }

  @override
  String get gestureCameraToggle => 'Перемкнути перегляд камери';

  @override
  String gestureCameraToggleName(String name) {
    return 'Перемкнути перегляд камери $name';
  }

  @override
  String gestureCall(String value) {
    return 'Викликати $value';
  }

  @override
  String gestureOpenApp(String package) {
    return 'Відкрити програму $package';
  }

  @override
  String gestureRun(String value) {
    return 'Запустити $value';
  }

  @override
  String gestureTriggerAction(String value) {
    return 'Запустити $value';
  }

  @override
  String gestureFireEvent(String value) {
    return 'Надіслати подію $value';
  }

  @override
  String get gestureValid => 'Виглядає добре.';

  @override
  String get gestureValidationFailed => 'Не вдалося перевірити.';

  @override
  String gestureDomainMissing(String value) {
    return 'Домен $value не знайдено.';
  }

  @override
  String gestureServiceMissing(String value) {
    return 'Службу $value не знайдено.';
  }

  @override
  String gestureEntityMissing(String value) {
    return 'Сутність $value не знайдено.';
  }

  @override
  String gestureEntityRequired(String domain) {
    return 'Введіть сутність $domain.*';
  }

  @override
  String get gestureScriptEntity => 'Сутність скрипту';

  @override
  String get gestureAutomationEntity => 'Сутність автоматизації';

  @override
  String get gestureDomain => 'Домен';

  @override
  String get gestureEntityOptional => 'Сутність (необов\'язково)';

  @override
  String get gestureServiceData => 'Дані служби (необов\'язково)';

  @override
  String get gestureServiceTitle => 'Викликати службу Home Assistant';

  @override
  String get gestureServiceRequired => 'Домен та служба є обов\'язковими.';

  @override
  String get gestureServiceJson => 'Дані служби мають бути об\'єктом JSON.';

  @override
  String get gestureEventType => 'Тип події';

  @override
  String get gestureEventData => 'Дані події (необов\'язково)';

  @override
  String get gestureEventTitle => 'Надіслати подію Home Assistant';

  @override
  String get gestureEventRequired => 'Тип події є обов\'язковим.';

  @override
  String get gestureEventJson => 'Дані події мають бути об\'єктом JSON.';

  @override
  String get gestureTester => 'Тестер жестів руками';

  @override
  String get gestureOpenTester => 'Відкрити тестер';

  @override
  String get gestureCameraFirst =>
      'Спочатку ввімкніть камеру в налаштуваннях камери.';

  @override
  String get gestureTesterHelp =>
      'Подивіться, які пальці розпізнає камера, щоб навчитися правильно тримати руку.';

  @override
  String get gestureHandHelp =>
      'Підніміть руку на рівень плеча, долонею до камери, розставивши пальці. Зігніть палець до кінця, щоб прибрати його з підрахунку. Притисніть великий палець до долоні, щоб показати чотири: великий палець враховується лише на повністю відкритій долоні.';

  @override
  String get gestureTesterPaused =>
      'Жести не спрацьовують, поки відкрито тестер.';

  @override
  String get gestureShowHand => 'Покажіть руку в камеру.';

  @override
  String gestureTesterTrigger(String action) {
    return 'Запускає: $action';
  }

  @override
  String get gestureNoCount => 'Жоден жест не використовує таку кількість.';

  @override
  String get gestureNoHand => 'У кадрі немає руки';

  @override
  String get gestureReadingHand => 'Розпізнавання руки';

  @override
  String get gestureNoFingers => 'Немає піднятих пальців';

  @override
  String gestureHandsCount(String count) {
    return 'У кадрі $count рук, розпізнається більша з них.';
  }

  @override
  String get gestureTesterSearch =>
      'Перегляд пальців, які зчитує камера, у реальному часі.';

  @override
  String get gestureHoldConfirmed => 'Утримання підтверджено';

  @override
  String gestureHoldProgress(String progress) {
    return 'Прогрес утримання: $progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return 'Тривалість утримання: $duration';
  }

  @override
  String get gestureHaServiceKind => 'Служба Home Assistant';

  @override
  String get gestureHaScriptKind => 'Скрипт Home Assistant';

  @override
  String get gestureHaAutomationKind => 'Автоматизація Home Assistant';

  @override
  String get gestureHaEventKind => 'Подія Home Assistant';

  @override
  String gestureRan(String value) {
    return 'Виконано $value';
  }

  @override
  String gestureRunFailed(String value) {
    return 'Не вдалося виконати $value';
  }

  @override
  String gestureCalled(String value) {
    return 'Викликано $value';
  }

  @override
  String gestureCallFailed(String value) {
    return 'Не вдалося викликати $value';
  }

  @override
  String gestureTriggered(String value) {
    return 'Запущено $value';
  }

  @override
  String gestureTriggerFailed(String value) {
    return 'Не вдалося запустити $value';
  }

  @override
  String gestureFired(String value) {
    return 'Надіслано подію $value';
  }

  @override
  String gestureFireFailed(String value) {
    return 'Не вдалося надіслати подію $value';
  }

  @override
  String get gestureDone => 'Готово';

  @override
  String get gestureFailed => 'Не вдалося';

  @override
  String get gestureEdit => 'Редагувати жест';

  @override
  String get gestureTrigger => 'Жест';

  @override
  String get gestureCornerTaps => 'Дотики у кут';

  @override
  String get gestureCornerHold => 'Утримання кута';

  @override
  String get gestureFingerTaps => 'Дотик кількома пальцями';

  @override
  String get gestureFingerHold => 'Утримання кількома пальцями';

  @override
  String get gestureSequence => 'Послідовність кутів';

  @override
  String get gestureClaps => 'Оплески';

  @override
  String get gestureShowFingers => 'Показати пальці';

  @override
  String get gestureCorner => 'Кут';

  @override
  String get gestureCornerTl => 'Верхній лівий кут';

  @override
  String get gestureCornerTr => 'Верхній правий кут';

  @override
  String get gestureCornerBl => 'Нижній лівий кут';

  @override
  String get gestureCornerBr => 'Нижній правий кут';

  @override
  String get gestureTaps => 'Дотики';

  @override
  String get gestureTaps2 => '2 дотики';

  @override
  String get gestureTaps3 => '3 дотики';

  @override
  String get gestureTaps4 => '4 дотики';

  @override
  String get gestureFingers => 'Пальці';

  @override
  String get gestureFinger1 => '1 палець';

  @override
  String get gestureFinger2 => '2 пальці';

  @override
  String get gestureFinger3 => '3 пальці';

  @override
  String get gestureFinger4 => '4 пальці';

  @override
  String get gestureOpenHand5 => 'Відкрита долоня (5)';

  @override
  String get gestureSingleTap => 'Одинарний дотик';

  @override
  String get gestureDoubleTap => 'Подвійний дотик';

  @override
  String gestureHoldDuration(String seconds) {
    return 'Утримувати протягом $seconds с';
  }

  @override
  String get gestureCameraHelp =>
      'Потрібна увімкнена камера та добре освітлене середовище.';

  @override
  String get gestureUnavailable => 'Недоступно на цьому пристрої.';

  @override
  String get gestureClaps2 => '2 оплески';

  @override
  String get gestureClaps3 => '3 оплески';

  @override
  String get gestureClaps4 => '4 оплески';

  @override
  String get gestureClapHelp =>
      'Оплески розпізнаються через мікрофон, незалежно від активаційного слова.';

  @override
  String get gestureSequenceHelp =>
      'Торкніться кутів по порядку (від 2 до 8 кроків).';

  @override
  String get gestureRemoveStep => 'Видалити останній крок';

  @override
  String get gestureUndo => 'Скасувати';

  @override
  String get gestureChooseAction => 'Виберіть дію';

  @override
  String get gestureActionHelp => 'Що саме активує цей жест.';

  @override
  String get gestureChangeHelp => 'Торкніться, щоб змінити.';

  @override
  String get gestureChooseError => 'Виберіть дію.';

  @override
  String get gestureSequenceError => 'Додайте щонайменше два кути.';

  @override
  String get intercomCall => 'Виклик';

  @override
  String get intercomNoReady => 'Жоден кіоск не готовий.';

  @override
  String get intercomOneReady => '1 кіоск готовий.';

  @override
  String intercomManyReady(String count) {
    return '$count кіосків готові.';
  }

  @override
  String get intercomCallKiosk => 'Викликати кіоск';

  @override
  String get intercomAnnounceAll => 'Оголосити всім';

  @override
  String get intercomAnnounceHelp =>
      'Звернутися до всіх кіосків. Лише в один бік.';

  @override
  String intercomMissedFrom(String name) {
    return 'Пропущений виклик від $name';
  }

  @override
  String intercomRangFor(String seconds) {
    return 'Дзвінок тривав $seconds секунд.';
  }

  @override
  String get intercomCallBack => 'Перетелефонувати';

  @override
  String get intercomDeclined => 'Відхилено';

  @override
  String get intercomBusy => 'Зайнято';

  @override
  String get intercomPeerOff => 'Інтерком вимкнено';

  @override
  String get intercomPeerKey => 'Інший ключ інтеркому';

  @override
  String get intercomNoAnswer => 'Немає відповіді';

  @override
  String get intercomDidNotAnswer => 'Не відповів';

  @override
  String get intercomVoiceFailed => 'Помилка голосового зв\'язку';

  @override
  String get intercomCancelled => 'Скасовано';

  @override
  String get intercomPageMic => 'Сторінка зайняла мікрофон';

  @override
  String get intercomNobody => 'Ніхто не зміг відповісти';

  @override
  String get intercomDone => 'Готово';

  @override
  String get intercomEnded => 'Виклик завершено';

  @override
  String get intercomAnnouncement => 'Оголошення';

  @override
  String get intercomAnnouncingOne => 'Оголошення для 1 кіоска';

  @override
  String intercomAnnouncingMany(String count) {
    return 'Оголошення для $count кіосків';
  }

  @override
  String get intercomIsCalling => 'телефонує';

  @override
  String get intercomIsAnnouncing => 'оголошує';

  @override
  String get intercomCalling => 'Виклик…';

  @override
  String intercomAnswersIn(String seconds) {
    return 'Відповідь через $seconds с';
  }

  @override
  String get intercomRinging => 'Дзвінок';

  @override
  String get intercomConnecting => 'З\'єднання…';

  @override
  String intercomDoneDuration(String duration) {
    return 'Завершено, $duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return 'Виклик завершено, $duration';
  }

  @override
  String get intercomDecline => 'Відхилити';

  @override
  String get intercomAnswer => 'Відповісти';

  @override
  String get intercomEveryKiosk => 'Кожен кіоск';

  @override
  String get intercomStop => 'Зупинити';

  @override
  String intercomHearsYou(String name) {
    return '$name чує вас';
  }

  @override
  String get intercomAllHearYou => 'Кожен кіоск чує вас';

  @override
  String get intercomHoldHelp =>
      'Утримуйте, щоб говорити, відпустіть, щоб слухати';

  @override
  String get intercomMuted => 'Звук вимкнено';

  @override
  String get intercomMute => 'Вимкнути звук';

  @override
  String get intercomEnd => 'Завершити';

  @override
  String get intercomReply => 'Відповісти';

  @override
  String get intercomDismiss => 'Закрити';

  @override
  String get intercomCallAgain => 'Зателефонувати знову';

  @override
  String get intercomDashboardMic =>
      'Панель керування утримує мікрофон, лише прослуховування.';

  @override
  String get intercomMicDenied =>
      'Дозвіл на мікрофон не надано, лише прослуховування.';

  @override
  String get intercomHoldTalk => 'Утримуйте для розмови';

  @override
  String get intercomPlaying => 'Відтворення';

  @override
  String get intercomAKiosk => 'кіоск';

  @override
  String intercomCallingName(String name) {
    return 'Виклик $name';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name телефонує';
  }

  @override
  String intercomInCallName(String name) {
    return 'Розмова з $name';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name оголошує';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant: $message';
  }

  @override
  String get intercomEndCall => 'Завершити виклик';

  @override
  String get intercomCallFailed => 'Не вдалося здійснити виклик';

  @override
  String get intercomKeyFailed => 'Не вдалося змінити ключ';

  @override
  String get intercomBroadcastFailed => 'Не вдалося передати повідомлення всім';

  @override
  String get intercomDeviceNoAnswer => 'Пристрій не відповів.';

  @override
  String get intercomUnknownKiosk => 'невідомий кіоск';

  @override
  String get intercomNothingRinging => 'немає активного дзвінка';

  @override
  String get intercomNoCall => 'немає виклику';

  @override
  String get intercomDisabled => 'інтерком вимкнено';

  @override
  String get intercomNeedsRemote => 'потрібне віддалене керування';

  @override
  String get intercomNeedsDiscovery =>
      'для інтеркому потрібні віддалене керування та пошук інших кіосків';

  @override
  String get intercomAlreadyCalling => 'вже триває виклик';

  @override
  String get intercomNoReadyError => 'жоден кіоск не готовий';

  @override
  String get intercomKeyLength => 'ключ має містити щонайменше 16 символів';

  @override
  String get intercomMicHeld => 'сторінка утримує мікрофон';

  @override
  String get intercomMicPermission => 'дозвіл на мікрофон не надано';

  @override
  String get intercomCallerNoAnswer => 'той, хто телефонував, не відповів';

  @override
  String get intercomMissedcall => 'Пропущений виклик';

  @override
  String get intercomListening => 'Прослуховування';

  @override
  String get intercomAnnouncementsoff => 'Оголошення вимкнено';

  @override
  String get intercomEncryptionMismatch => 'Невідповідність шифрування';

  @override
  String get intercomEncryptionMismatchHelp =>
      'Невідповідність шифрування. Увімкніть шифрування зв\'язку на всіх кіосках у виклику.';

  @override
  String get kioskBackClose =>
      'Натисніть «Назад» ще раз, щоб закрити застосунок';

  @override
  String get kioskBackAgain => 'Натисніть «Назад» ще раз, щоб повернутися';

  @override
  String get kioskHoldOn => 'Режим утримання увімкнено';

  @override
  String get kioskHoldOff => 'Режим утримання вимкнено';

  @override
  String get kioskHoldNotice =>
      'Поточний екран залишатиметься активним, доки ви його не вимкнете.';

  @override
  String get kioskDownloadComplete => 'Завантаження завершено';

  @override
  String get kioskDownloadFailed => 'Завантаження не вдалося';

  @override
  String get kioskDownload => 'Завантажити';

  @override
  String get kioskDownloading => 'Завантаження…';

  @override
  String get kioskOpen => 'Відкрити';

  @override
  String get kioskTip => 'Підказка';

  @override
  String get kioskMenuHint => 'Проведіть від лівого краю, щоб відкрити меню.';

  @override
  String get kioskUnknownLink => 'Невідоме посилання кіоска';

  @override
  String get kioskOpenAppFailed => 'Не вдалося відкрити застосунок';

  @override
  String get kioskWebViewMissing =>
      'Android System WebView відсутній або вимкнений';

  @override
  String get kioskWebViewMissingHelp =>
      'На цьому пристрої немає провайдера WebView, тому неможливо відобразити Home Assistant. Встановіть Android System WebView або Chrome, а потім перезапустіть Kiosk Satellite.';

  @override
  String get kioskPinTitle => 'PIN-код кіоска';

  @override
  String get kioskPinHint => 'PIN-код';

  @override
  String get kioskWrongPin => 'Невірний PIN-код';

  @override
  String get kioskUnlock => 'Розблокувати';

  @override
  String get lockdownScreenLocked => 'Екран заблоковано';

  @override
  String get logsWebConsole => 'Веб-консоль';

  @override
  String get logsDock => 'Закріпити над поточною сторінкою';

  @override
  String get logsNoOutput => 'Виводу консолі ще немає';

  @override
  String get logsShareSubject => 'Журнал консолі Kiosk Satellite';

  @override
  String get logsInput => 'Виконати JavaScript на сторінці';

  @override
  String get logsInputHistory =>
      'Виконати JavaScript на сторінці (Enter для запуску, Вгору/Вниз для історії)';

  @override
  String get logsRun => 'Запустити';

  @override
  String get logsEvaluationFailed => 'помилка обчислення';

  @override
  String get logsDeviceUnreachable => 'пристрій недоступний';

  @override
  String logsEntries(String count) {
    return 'Записів: $count';
  }

  @override
  String get logsCopyLog => 'Копіювати журнал';

  @override
  String get logsShareLog => 'Поділитися журналом';

  @override
  String get logsCopied => 'Скопійовано';

  @override
  String get logsCopyFailed => 'Не вдалося скопіювати';

  @override
  String get logsOnClipboard => 'Журнал скопійовано до буфера обміну.';

  @override
  String get logsConsoleOnClipboard =>
      'Журнал консолі скопійовано до буфера обміну.';

  @override
  String get logsSystemLog =>
      'Системний журнал Android для цієї програми (сюди записуються збої)';

  @override
  String get logsErrors => 'Помилки та збої';

  @override
  String get logsWarnings => 'Попередження';

  @override
  String get logsInfo => 'Інформація та налагодження';

  @override
  String get logsNoMatches =>
      'Немає відповідних рядків. Увімкніть більше типів вище, щоб побачити повний журнал.';

  @override
  String get logsUnavailable => 'logcat недоступний';

  @override
  String logsReadFailed(String error) {
    return 'Не вдалося прочитати logcat: $error';
  }

  @override
  String get logsUnknown => 'невідомо';

  @override
  String get offlineDashboard => 'Панель керування недоступна';

  @override
  String get offlineNetwork => 'Немає підключення до мережі';

  @override
  String get offlinePageHelp => 'Не вдалося завантажити сторінку.';

  @override
  String get offlineNetworkHelp =>
      'Панель керування відновиться автоматично після підключення до мережі.';

  @override
  String get offlineLost => 'Зв’язок із мережею втрачено';

  @override
  String get offlineRestored => 'Мережеве підключення відновлено';

  @override
  String get mediaPlay => 'Відтворити';

  @override
  String get mediaPause => 'Пауза';

  @override
  String get mediaPreviousTrack => 'Попередній трек';

  @override
  String get mediaNextTrack => 'Наступний трек';

  @override
  String get mediaPlaying => 'Відтворюється';

  @override
  String get mediaPaused => 'Призупинено';

  @override
  String get mediaIdle => 'Очікування';

  @override
  String get mediaStatusUnavailable => 'Статус недоступний';

  @override
  String get mediaUnknownTrack => 'Невідомий трек';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => 'Показати гучність';

  @override
  String get mediaHideVolume => 'Приховати гучність';

  @override
  String get mediaMute => 'Вимкнути звук';

  @override
  String get mediaUnmute => 'Увімкнути звук';

  @override
  String get mediaFavoriteAdd => 'Додати до улюблених';

  @override
  String get mediaFavoriteRemove => 'Вилучити з улюблених';

  @override
  String get mediaShuffleOn => 'Увімкнути перемішування';

  @override
  String get mediaShuffleOff => 'Вимкнути перемішування';

  @override
  String get mediaRepeatAll => 'Повторювати все';

  @override
  String get mediaRepeatOne => 'Повторювати один трек';

  @override
  String get mediaRepeatOff => 'Вимкнути повтор';

  @override
  String get mediaShowLyrics => 'Показати текст пісні';

  @override
  String get mediaHideLyrics => 'Приховати текст пісні';

  @override
  String get mediaShowQueue => 'Показати чергу';

  @override
  String get mediaHideQueue => 'Приховати чергу';

  @override
  String get mediaVolume => 'Гучність';

  @override
  String get mediaPlaybackPosition => 'Позиція відтворення';

  @override
  String get mediaShowNowPlaying => 'Показати \"Зараз грає\"';

  @override
  String get mediaShowFloatingPlayer => 'Показати плаваючий плеєр';

  @override
  String get mediaOpenMusicAssistant => 'Відкрити Music Assistant';

  @override
  String get mediaCannotControl => 'команда не підтримується або не надіслана';

  @override
  String get mediaNothingQueued => 'У черзі нічого немає';

  @override
  String get mediaChapters => 'Розділи';

  @override
  String get mediaNowPlaying => 'Зараз відтворюється';

  @override
  String get mediaUpNext => 'Далі';

  @override
  String mediaUnnamedChapter(String number) {
    return 'Розділ $number';
  }

  @override
  String get mediaGroupLead => 'Очолює групу';

  @override
  String get mediaGroupReadFailed => 'Не вдалося прочитати групу.';

  @override
  String get mediaGroupEmpty => 'Немає інших плеєрів для групування.';

  @override
  String get mediaSpeakerSelection => 'Вибір динаміків';

  @override
  String pluginCloseWindow(String name) {
    return 'Закрити $name';
  }

  @override
  String get pluginActions => 'Дії';

  @override
  String get pluginKioskDrawer => 'Бічна панель кіоска';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      'Щоб призначити жест, відкрийте \"Жести\" та виберіть \"Виконати дію плагіна\".';

  @override
  String get pluginShowInKioskDrawer => 'Показувати в бічній панелі кіоска';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      'Також доступно при заблокованому екрані, якщо дозволено бічну панель кіоска.';

  @override
  String get pluginExposeToHomeAssistant => 'Експортувати до Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      'Додає кнопку до пристрою ESPHome кіоска. Потрібні ESPHome та нативні сутності.';

  @override
  String get pluginSelectAnEntity => 'Виберіть сутність';

  @override
  String pluginChooseName(String name) {
    return 'Вибрати $name';
  }

  @override
  String pluginConfigureName(String name) {
    return 'Налаштувати $name';
  }

  @override
  String get pluginPlugin => 'Плагін';

  @override
  String get pluginEnablePlugins => 'Увімкнути плагіни';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      'Плагіни додають додаткові функції від спільноти до Kiosk Satellite.';

  @override
  String get pluginInstalledPlugins => 'Встановлені плагіни';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      'Плагіни не встановлені. Додайте репозиторій, щоб розпочати.';

  @override
  String get pluginDeveloperTools => 'Інструменти розробника';

  @override
  String get pluginCreateAPlugin => 'Створити плагін';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      'Дізнайтеся, як створювати плагіни, за допомогою шаблону Hello World та документації.';

  @override
  String get pluginThisPluginIsNoLongerInstalled =>
      'Цей плагін більше не встановлено.';

  @override
  String get pluginEnablePluginsToRunThisPlugin =>
      'Увімкніть плагіни, щоб запустити цей плагін.';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      'Увімкніть цей плагін у його рядку, щоб запустити його.';

  @override
  String pluginUninstallName(String name) {
    return 'Видалити $name?';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return 'Видалити $name';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return 'Перевірити оновлення для $name';
  }

  @override
  String pluginAboutName(String name) {
    return 'Про $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings =>
      'Це призведе до видалення плагіна та його налаштувань.';

  @override
  String get pluginUninstall => 'Видалити';

  @override
  String get pluginNoUpdatesAvailable => 'Немає доступних оновлень.';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      'Цей плагін було встановлено з архіву ZIP, він не має опису README з репозиторію.';

  @override
  String get pluginImageUnavailable => 'Зображення недоступне';

  @override
  String get pluginCouldNotOpenThisLink => 'Не вдалося відкрити це посилання.';

  @override
  String pluginEnableName(String name) {
    return 'Увімкнути $name';
  }

  @override
  String get pluginAddPlugin => 'Додати плагін';

  @override
  String get pluginInstallFromAGithubRepository =>
      'Встановити з репозиторію GitHub';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd =>
      'Переконайтеся, що ви довіряєте автору плагіна та його коду перед встановленням.';

  @override
  String get pluginPreview => 'Попередній перегляд';

  @override
  String get pluginInstalledVersion => 'Встановлена версія';

  @override
  String get pluginAuthor => 'Автор';

  @override
  String get pluginLicense => 'Ліцензія';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      'Плагіни виконують код всередині Kiosk Satellite і можуть мати доступ до даних програми та наданих дозволів Android. Несправний або зловмисний плагін може розкрити конфіденційні дані або порушити роботу програми. Встановлюйте плагіни лише від перевірених авторів.';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      'Нові плагіни спочатку вимкнені. Оновлення зберігають стан увімкнення та автоматично перезапускають активні плагіни.';

  @override
  String get pluginTrustAndUpdate => 'Довіряти та оновити';

  @override
  String get pluginTrustAndInstall => 'Довіряти та встановити';

  @override
  String get pluginInstallFromZip => 'Встановити з ZIP';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild =>
      'Лише для розробників: тестування локальної збірки';

  @override
  String get pluginPluginZip => 'ZIP-архів плагіна';

  @override
  String get pluginPluginZipMustBeAtMost4Mb =>
      'Розмір ZIP-архіву плагіна не повинен перевищувати 4 МБ';

  @override
  String get pluginCouldNotReadTheSelectedZip =>
      'Не вдалося прочитати вибраний ZIP-архів';

  @override
  String get pluginCharts => 'Графіки';

  @override
  String get pluginReadings => 'Показники';

  @override
  String get pluginWaitingForSamples => 'Очікування даних';

  @override
  String get pluginLatest => 'Останній';

  @override
  String get pluginSelected => 'Вибрано';

  @override
  String get pluginNoDataYet => 'Даних ще немає';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      'Торкніться або проведіть, щоб оглянути вибірки. Торкніться двічі, щоб стежити за останніми.';

  @override
  String get pluginNoData => 'Немає даних';

  @override
  String get pluginOn => 'Увімкнено';

  @override
  String get pluginEmpty => 'Порожньо';

  @override
  String get pluginChartKeyboardHelp =>
      'Використовуйте клавіші зі стрілками для перегляду даних, End для найновіших.';

  @override
  String get pluginErrorAssetPath => 'Недійсний шлях до ресурсу';

  @override
  String get pluginErrorAssetMissing =>
      'Ресурс відсутній або виходить за межі свого пакета';

  @override
  String get pluginErrorAssetSymlink =>
      'Каталог ресурсу не може бути символічним посиланням';

  @override
  String get pluginErrorAssetSymlinks =>
      'Каталоги ресурсів не можуть бути символічними посиланнями';

  @override
  String get pluginErrorAssetsIntegrity =>
      'Встановлені ресурси не пройшли перевірку цілісності';

  @override
  String get pluginErrorAssetIntegrity =>
      'Встановлений ресурс не пройшов перевірку цілісності';

  @override
  String get pluginErrorManifestMismatch =>
      'Маніфест пакета не відповідає перевіреному маніфесту релізу';

  @override
  String get pluginErrorStagingExists => 'Каталог підготовки вже існує';

  @override
  String get pluginErrorCreateDirectory =>
      'Не вдалося створити каталог плагіна';

  @override
  String get pluginErrorFileCount =>
      'Підтримується щонайбільше 512 файлів у пакеті';

  @override
  String get pluginErrorProtectFile => 'Не вдалося захистити файл плагіна';

  @override
  String get pluginErrorExpandedSize => 'Розпакований плагін перевищує 4 МБ';

  @override
  String get pluginErrorManifestSize => 'Маніфест перевищує 32 КБ';

  @override
  String get pluginErrorRequiredFiles =>
      'Пакет потребує kiosk-satellite-plugin.json, plugin.jar та LICENSE';

  @override
  String get pluginErrorNativeCapability =>
      'Нативні бібліотеки потребують можливість native';

  @override
  String get pluginErrorNativeElf => 'Недійсна нативна ELF-бібліотека';

  @override
  String get pluginErrorNativeAbi =>
      'ABI нативної бібліотеки не відповідає її каталогу';

  @override
  String get pluginErrorDexOnly => 'plugin.jar має містити лише DEX-файли';

  @override
  String get pluginErrorDexHeader => 'Недійсний заголовок DEX';

  @override
  String get pluginErrorDexSize => 'Розпакований DEX перевищує 4 МБ';

  @override
  String get pluginErrorDexEmpty => 'Порожній DEX-файл';

  @override
  String get pluginErrorDexMissing => 'plugin.jar не містить classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'Неочікуваний або дубльований запис ZIP: $name';
  }

  @override
  String get pluginErrorRepositoryMismatch =>
      'Реліз репозиторію належить іншому плагіну.';

  @override
  String get pluginErrorRepositoryUrl =>
      'Введіть публічну URL-адресу https://github.com/owner/repository';

  @override
  String get pluginErrorRepositoryPath =>
      'Використовуйте URL репозиторію без шляху до файлу чи гілки';

  @override
  String get pluginErrorDownloadOutsideGithub =>
      'Завантаження плагіну перенаправлено за межі GitHub';

  @override
  String get pluginErrorInvalidRedirect => 'Недійсне перенаправлення GitHub';

  @override
  String get pluginErrorRepositoryNotFound =>
      'Не знайдено публічного репозиторію, стабільного релізу, kiosk-satellite-plugin.json, README.md або ресурсу релізу.';

  @override
  String get pluginErrorGithubLimited =>
      'GitHub відхилив запит або вичерпано ліміт запитів. Спробуйте пізніше.';

  @override
  String get pluginErrorRepositorySize =>
      'Файл репозиторію перевищує обмеження розміру';

  @override
  String get pluginErrorTooManyRedirects =>
      'Занадто багато перенаправлень GitHub';

  @override
  String get pluginErrorStableRelease =>
      'GitHub не повернув опублікований стабільний реліз';

  @override
  String get pluginErrorReleaseTag => 'Недійсний тег релізу';

  @override
  String get pluginErrorManifestFile =>
      'Недійсний маніфест kiosk-satellite-plugin.json';

  @override
  String get pluginErrorIdVersion =>
      'Недійсний ідентифікатор або версія плагіна';

  @override
  String get pluginErrorChecksumFilename =>
      'Недійсна контрольна сума релізу або назва файлу пакета';

  @override
  String get pluginErrorGithubDigest =>
      'Контрольна сума релізу має відповідати SHA-256 дайджесту ресурсу GitHub';

  @override
  String get pluginErrorTagRevision => 'GitHub не повернув ревізію тега релізу';

  @override
  String get pluginErrorTrustAuthor =>
      'Підтвердіть, що ви довіряєте автору плагіна';

  @override
  String get pluginErrorPreviewExpired =>
      'Строк дії цього перегляду минув. Виконайте перегляд репозиторію знову перед встановленням.';

  @override
  String get pluginErrorReviewedChecksum =>
      'SHA-256 пакета не відповідає перевіреному релізу';

  @override
  String get pluginErrorNotInstalled => 'Плагін не встановлено';

  @override
  String get pluginErrorUpdateZip =>
      'Цей плагін було встановлено з архіву ZIP. Для оновлення використовуйте \"Встановити з ZIP\".';

  @override
  String get pluginErrorAndroidOnly => 'Плагіни доступні лише на Android.';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'Помилка запиту до GitHub ($status)';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return 'Реліз потребує рівно один завантажений ресурс $name';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return 'Ресурс релізу $name має бути опублікований через GitHub Actions. Вручну завантажені файли не підтримуються.';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return 'Ресурс релізу $name перевищує обмеження розміру або є порожнім';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return 'Недійсна URL-адреса релізу для $name';
  }

  @override
  String get pluginErrorNativeLibrary =>
      'Плагін не має нативної бібліотеки для ABI цього пристрою';

  @override
  String get pluginErrorCallbackTimeout =>
      'Час очікування зворотного виклику плагіна минув. Перезапустіть Kiosk, якщо плагін лишив активні завдання.';

  @override
  String get pluginErrorEnableFirst => 'Спочатку увімкніть плагін';

  @override
  String get pluginErrorSaveState => 'Не вдалося зберегти стан плагіна';

  @override
  String get pluginErrorPackageHash => 'Недійсний хеш встановленого пакета';

  @override
  String get pluginErrorChecksum => 'SHA-256 пакета не збігається';

  @override
  String get pluginErrorDifferentRepository =>
      'Цей ідентифікатор плагіна належить іншому репозиторію. Видаліть його перед зміною джерел.';

  @override
  String get pluginErrorRestartReplace =>
      'Цей плагін не зупинився коректно. Перезапустіть Kiosk Satellite перед його заміною.';

  @override
  String get pluginErrorPluginLimit =>
      'Можна встановити щонайбільше 8 плагінів';

  @override
  String get pluginErrorAlreadyInstalled => 'Цей пакет уже встановлено';

  @override
  String get pluginErrorLoadedIntegrity =>
      'Раніше завантажений пакет не пройшов перевірку цілісності. Перезапустіть Kiosk Satellite перед повторним встановленням.';

  @override
  String get pluginErrorRemovePackage =>
      'Не вдалося вилучити невикористаний пакет';

  @override
  String get pluginErrorInstallPackage => 'Не вдалося встановити пакет плагіна';

  @override
  String get pluginErrorUpdateCanceled =>
      'Оновлення скасовано, оскільки плагін не зупинився коректно. Перезапустіть Kiosk Satellite перед повторною спробою.';

  @override
  String get pluginErrorVersionRetained => 'Попередню версію збережено.';

  @override
  String get pluginErrorRetainedDisabled =>
      'Попередню версію збережено, але вона вимкнена. Перезапустіть Kiosk Satellite перед її увімкненням.';

  @override
  String get pluginErrorVersionRunning => 'Попередня версія знову запущена.';

  @override
  String get pluginErrorEnablePlugins => 'Спочатку увімкніть плагіни';

  @override
  String get pluginErrorRestartEnable =>
      'Цей плагін не зупинився коректно. Перезапустіть Kiosk Satellite перед його увімкненням.';

  @override
  String get pluginErrorInstalledIntegrity =>
      'Встановлений плагін не пройшов перевірку цілісності. Перевстановіть його.';

  @override
  String get pluginErrorAndroidOld => 'Версія Android надто стара';

  @override
  String get pluginErrorNativeIntegrity =>
      'Встановлені нативні бібліотеки не пройшли перевірку цілісності';

  @override
  String get pluginErrorNativeFileIntegrity =>
      'Встановлена нативна бібліотека не пройшла перевірку цілісності';

  @override
  String pluginErrorReadInstalled(String error) {
    return 'Не вдалося прочитати встановлений плагін: $error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return 'Не вдалося перезапустити попередню версію: $error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return 'Помилка оновлення плагіна: $error. $recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      'Потрібен Shizuku 13 або новіший. Торкніться для інструкцій з налаштування.';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      'Запустіть Shizuku на цьому пристрої. Торкніться для інструкцій з налаштування.';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku надає Kiosk Satellite доступ shell або root. Встановлені плагіни працюють всередині KS, тому надавайте доступ лише тим, кому довіряєте.';

  @override
  String get pluginSetUp => 'Налаштувати';

  @override
  String get pluginGrantAccess => 'Надати доступ';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      'Підтвердьте запит дозволів на кіоску.';

  @override
  String get pluginErrorInvalidId => 'Недійсний ідентифікатор плагіна';

  @override
  String get pluginErrorInvalidVersion => 'Недійсна версія';

  @override
  String get pluginErrorEntryClass => 'Недійсний клас входу';

  @override
  String get pluginErrorManifestSchema => 'Непідтримувана схема маніфесту';

  @override
  String get pluginErrorSdkVersion => 'Цей плагін потребує іншу версію SDK';

  @override
  String get pluginErrorMinimumSdk =>
      'Мінімальний Android SDK має бути щонайменше 24';

  @override
  String get pluginErrorCapability => 'Непідтримувана можливість плагіна';

  @override
  String get pluginErrorTooManySettings =>
      'Занадто багато налаштувань або команд';

  @override
  String get pluginErrorSettingKey =>
      'Недійсний або дубльований ключ налаштування';

  @override
  String get pluginErrorGroupsArray => 'Групи відображення мають бути масивом';

  @override
  String get pluginErrorTooManyGroups => 'Занадто багато груп відображення';

  @override
  String get pluginErrorUniqueGroups =>
      'Групи відображення мають посилатися на унікальні групи налаштувань';

  @override
  String get pluginErrorGroupReferences => 'Занадто багато посилань на групи';

  @override
  String get pluginErrorDuplicateReference =>
      'Недійсне або дубльоване посилання на групу';

  @override
  String get pluginErrorCommandId =>
      'Недійсний або дубльований ідентифікатор команди';

  @override
  String get pluginErrorUnknownSetting => 'Невідоме налаштування плагіна';

  @override
  String get pluginErrorTextLength =>
      'Текстові налаштування мають містити щонайбільше 512 символів';

  @override
  String get pluginErrorEntityId =>
      'Очікується ідентифікатор сутності Home Assistant';

  @override
  String get pluginErrorBoolean => 'Очікується логічне значення';

  @override
  String get pluginErrorColor =>
      'Очікується колір RGB у шістнадцятковому форматі';

  @override
  String get pluginErrorNumber => 'Очікується числове налаштування';

  @override
  String get pluginErrorRange =>
      'Числове налаштування виходить за межі свого діапазону';

  @override
  String get pluginErrorStep =>
      'Числове налаштування не відповідає своєму кроку';

  @override
  String get pluginErrorSelection => 'Недійсне налаштування вибору';

  @override
  String get pluginErrorSelectionOption => 'Невідомий варіант вибору';

  @override
  String get pluginErrorSettingType => 'Непідтримуваний тип налаштування';

  @override
  String get pluginErrorInvalidManifest => 'Недійсний маніфест плагіна';

  @override
  String pluginErrorAndroidApi(String version) {
    return 'Плагін потребує Android API $version';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return 'Недійсне поле $field';
  }

  @override
  String get remoteDisableTitle => 'Вимкнути віддалене керування?';

  @override
  String get remoteDisableHelp =>
      'УВАГА: Ви більше не зможете відкрити цю сторінку. Щоб увімкнути його знову, скористайтеся пристроєм або перемикачем віддаленого керування в Home Assistant.';

  @override
  String get remoteDisableConfirm => 'Вимкнути';

  @override
  String get remoteCopyHelp => 'Виділіть ключ і скопіюйте його вручну.';

  @override
  String get remoteSaveSettingFailed =>
      'Не вдалося зберегти це налаштування. Спробуйте ще раз.';

  @override
  String get remoteReconnecting => 'Повторне підключення…';

  @override
  String remoteConnectionLost(String name) {
    return 'Зв\'язок із $name втрачено. Ця сторінка відновиться автоматично, коли пристрій повернеться.';
  }

  @override
  String get remoteConnectionLostUnnamed =>
      'Зв\'язок із кіоском втрачено. Ця сторінка відновиться автоматично, коли пристрій повернеться.';

  @override
  String get remoteReloadPage => 'Оновити сторінку';

  @override
  String get remoteUpdated => 'Kiosk Satellite оновлено';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return 'Пристрій тепер працює на версії $version$build. Ця сторінка належить до попередньої версії та перезавантажиться через $seconds с.';
  }

  @override
  String remoteBuild(String build) {
    return ' (збірка $build)';
  }

  @override
  String get remoteReloadNow => 'Оновити зараз';

  @override
  String get remoteLogin => 'Увійти';

  @override
  String get remoteInvalidPassword => 'Невірний пароль';

  @override
  String get remoteLoginThrottled =>
      'Забагато спроб. Зачекайте 5 хвилин і спробуйте знову.';

  @override
  String get deviceScreenOffPermission =>
      'Вимкнення екрана вимагає одноразового дозволу. На планшеті зараз відкрито екран надання прав \"device admin\". Підтвердьте його там, а потім повторіть спробу.';

  @override
  String get deviceAdminInactive =>
      'Дозвіл адміністратора пристрою не активний.';

  @override
  String get deviceRestartOverlay =>
      'Для перезапуску потрібен дозвіл \"Показувати поверх інших додатків\", інакше застосунок не зможе повернутися на екран. На пристрої відкривається екран запиту; надайте дозвіл і спробуйте знову.';

  @override
  String get deviceRebootPermission =>
      'Для перезавантаження пристрою Kiosk Satellite має бути налаштований як власник пристрою або мати дозволене підключення Shizuku.';

  @override
  String get deviceRestartAndroidOnly =>
      'Перезапуск доступний лише на Android.';

  @override
  String get deviceRestartShizukuRefused =>
      'Shizuku відхилив запит на перезапуск';

  @override
  String deviceRestartFailed(String error) {
    return 'Помилка перезапуску: $error';
  }

  @override
  String get overviewAttention => 'Потребує уваги';

  @override
  String get overviewOpen => 'Відкрити';

  @override
  String get overviewUpdate => 'Оновити';

  @override
  String overviewInvitation(String name) {
    return '$name пропонує керувати цим кіоском';
  }

  @override
  String get overviewInvitationHelp =>
      'Підтвердьте на екрані кіоска або у розділі керування парком.';

  @override
  String get overviewOutdatedOne =>
      '1 керований пристрій працює на іншій версії';

  @override
  String overviewOutdatedMany(String count) {
    return '$count керованих пристроїв працюють на іншій версії';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names. Синхронізація очікує на версію $version.';
  }

  @override
  String get overviewThisRelease => 'цей випуск';

  @override
  String get overviewUpdateAvailable => 'Доступне оновлення';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version готовий до встановлення. Встановлення підтверджується на екрані планшета.';
  }

  @override
  String get overviewHaSetup => 'Home Assistant не налаштовано';

  @override
  String get overviewHaSetupHelp =>
      'Підключіть кіоск до Home Assistant, щоб завантажити панель керування.';

  @override
  String get overviewSetUp => 'Налаштувати';

  @override
  String get overviewHaNotValidated => 'Home Assistant не перевірено';

  @override
  String get overviewHaNotValidatedHelp =>
      'URL-адреса та токен не пройшли перевірку підключення під час цього запуску. Кіоск повторює спробу кожні 30 секунд.';

  @override
  String get overviewOpenSetup => 'Відкрити налаштування';

  @override
  String get overviewWakeStopped => 'Розпізнавання слова активації зупинено';

  @override
  String get overviewWakeReleased => 'Рушій розпізнавання вивільнено.';

  @override
  String get overviewOpenVoice => 'Відкрити Voice Satellite';

  @override
  String get overviewOpenService => 'Відкрити службу';

  @override
  String overviewPermissionMissing(String permission) {
    return 'Відсутній дозвіл: $permission';
  }

  @override
  String get overviewQuick => 'Швидкі дії';

  @override
  String get overviewReload => 'Оновити сторінку';

  @override
  String get overviewScreenOn => 'Увімкнути екран';

  @override
  String get overviewScreenOff => 'Вимкнути екран';

  @override
  String get overviewSaverStart => 'Запустити заставку';

  @override
  String get overviewSaverStop => 'Закрити заставку';

  @override
  String get overviewCameraShow => 'Показати камеру';

  @override
  String get overviewCameraHide => 'Приховати камеру';

  @override
  String get overviewSaverPostpone => 'Відкласти заставку';

  @override
  String get overviewDnd => 'Не турбувати';

  @override
  String get overviewDndOn => 'Режим \"Не турбувати\" увімкнено';

  @override
  String get overviewSnapshot => 'Зробити знімок';

  @override
  String get overviewCheckUpdates => 'Перевірити оновлення';

  @override
  String get overviewRestartApp => 'Перезапустити застосунок';

  @override
  String get overviewRestartDevice => 'Перезавантажити пристрій';

  @override
  String get overviewExit => 'Вийти із застосунку';

  @override
  String get overviewBrightness => 'Яскравість';

  @override
  String get overviewVolume => 'Загальна гучність';

  @override
  String get overviewBrightnessGrant =>
      'Яскравість використовує резервний рівень застосунку. Надайте дозвіл \"Змінення системних налаштувань\", щоб повзунок регулював фактичну яскравість панелі.';

  @override
  String get overviewRestartQuestion =>
      'Перезавантажити цей пристрій? Kiosk Satellite відновиться після запуску.';

  @override
  String get overviewRestart => 'Перезавантажити';

  @override
  String get overviewNoSnapshot => 'Знімок не отримано.';

  @override
  String get overviewSnapshotTitle => 'Знімок з камери';

  @override
  String get overviewUpdateCheckFailed =>
      'Не вдалося перевірити оновлення. Чи є у пристрою доступ до GitHub?';

  @override
  String get overviewLatest => 'Ви використовуєте найновішу версію.';

  @override
  String overviewVersionAvailable(String version) {
    return 'Доступна версія $version';
  }

  @override
  String get overviewInstallAttention =>
      'Встановіть її з розділу \"Потребує уваги\".';

  @override
  String get overviewNoViewsWithCameras =>
      'Жоден вигляд камер ще не містить камер. Спочатку додайте камери до вигляду в розділі \"Камери\".';

  @override
  String get overviewShowViewFailed => 'Не вдалося показати вигляд';

  @override
  String get overviewAppVersion => 'Версія застосунку';

  @override
  String get overviewNotSetup => 'Не налаштовано';

  @override
  String get overviewNotValidated => 'Не перевірено';

  @override
  String get overviewCheckingFilter => 'Перевірка фільтра...';

  @override
  String get overviewValidated => 'Перевірено';

  @override
  String get overviewFilterUnavailable => 'Статус фільтра недоступний';

  @override
  String get overviewUnfiltered => 'Оновлення без фільтрації';

  @override
  String get overviewWatchingOne => 'Відстежується 1 сутність';

  @override
  String overviewWatchingMany(String count) {
    return 'Відстежується $count сутностей';
  }

  @override
  String overviewFilterDisabled(String count) {
    return 'Фільтрацію вимкнено, вигляд використовує $count сутностей';
  }

  @override
  String get overviewWakeOff => 'Розпізнавання слова активації вимкнено';

  @override
  String overviewListeningFor(String words) {
    return 'Очікування фрази: $words';
  }

  @override
  String get overviewListening => 'Прослуховування';

  @override
  String get overviewNotListening => 'Не слухає';

  @override
  String get overviewEntitiesProxy => 'Сутності та BT-проксі';

  @override
  String get overviewEntitiesOnly => 'Лише сутності';

  @override
  String get overviewProxyOnly => 'Лише BT-проксі';

  @override
  String get overviewWaitingHA => 'Очікування Home Assistant';

  @override
  String get overviewNotRunning => 'Не запущено';

  @override
  String get overviewRunningOne => 'Працює - 1 функція';

  @override
  String overviewRunningMany(String count) {
    return 'Працює - $count функцій';
  }

  @override
  String overviewDownloading(String version) {
    return 'Завантаження: $version';
  }

  @override
  String overviewNewVersion(String version) {
    return 'Нова версія: $version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return 'Актуальна: $version';
  }

  @override
  String get overviewCurrent => 'Актуальна версія';

  @override
  String overviewPluginAttribution(String name) {
    return 'Плагін $name';
  }

  @override
  String get overviewMuted => 'без звуку';

  @override
  String get overviewBrowser => 'браузер';

  @override
  String get overviewWakeWaiting =>
      'Очікування Voice Satellite. Рушій і слова активації налаштовуються інтеграцією, щойно цей пристрій відкриє свою панель.';

  @override
  String get overviewWakeDisabled =>
      'Розпізнавання слова активації вимкнено. Увімкніть його, щоб успадкувати моделі від Voice Satellite.';

  @override
  String get overviewMicBlocked =>
      'Мікрофон заблоковано. Android більше не запитуватиме дозвіл, тому надайте його в налаштуваннях застосунку та повторіть спробу.';

  @override
  String get overviewMicDeclined =>
      'У доступі до мікрофона відмовлено. Для розпізнавання слова активації потрібен мікрофон; спробуйте знову, щоб повторити запит.';

  @override
  String get overviewMicLost =>
      'Мікрофон припинив роботу. Спробуйте ще раз або оновіть сторінку.';

  @override
  String get overviewModelsUnavailable =>
      'Не вдалося завантажити моделі з Home Assistant. Повторіть спробу, коли він буде доступний.';

  @override
  String get overviewCrashed =>
      'Модуль розпізнавання постійно збоїв на цьому пристрої, тому його було зупинено. Voice Satellite натомість веде прослуховування у браузері. Спробуйте ще раз або перезапустіть застосунок.';

  @override
  String get overviewWakeFailed =>
      'Не вдалося запустити рушій розпізнавання слова активації. Спробуйте ще раз або оновіть сторінку.';

  @override
  String overviewNativeUnavailable(String engine) {
    return 'Немає нативного середовища для $engine. Voice Satellite продовжує розпізнавання у браузері.';
  }

  @override
  String get overviewNativeListening => 'Нативне прослуховування';

  @override
  String get overviewSuspended =>
      'Готовий (призупинено під час голосового сеансу)';

  @override
  String get overviewCpu => 'ЦП';

  @override
  String get overviewMemory => 'ОЗП';

  @override
  String get overviewTemperature => 'Темп.';

  @override
  String overviewMemoryFree(String amount) {
    return '$amount ГБ вільно';
  }

  @override
  String overviewMetricPercent(String value) {
    return '$value%';
  }

  @override
  String overviewMetricDegrees(String value) {
    return '$value°C';
  }

  @override
  String get overviewNoScreenshot => 'Немає знімка екрана';

  @override
  String get overviewStill => 'Статичний';

  @override
  String get overviewLive => 'Наживо';

  @override
  String get overviewFullSize => 'Повний розмір';

  @override
  String get overviewLiveInterval => 'Наживо, кожні 5 секунд';

  @override
  String overviewTaken(String age) {
    return 'Зроблено $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return 'Вигляд камери: $name';
  }

  @override
  String get overviewCameraView => 'Вигляд камери';

  @override
  String get overviewScreenOffState => 'Екран вимкнено';

  @override
  String get overviewGoView => 'Перейти до вигляду';

  @override
  String get overviewLoadingViews => 'Завантаження виглядів…';

  @override
  String get overviewPickView => 'Оберіть вигляд панелі…';

  @override
  String get overviewDefaultView => 'Стандартний вигляд';

  @override
  String get overviewNoDashboards => 'Панелей керування не знайдено';

  @override
  String get overviewViewsUnavailable => 'Вигляди недоступні';

  @override
  String get screensaverNoPhotos =>
      'Фотографії не вибрано. Оберіть їх у Налаштуваннях.';

  @override
  String get screensaverNoFolder =>
      'Папку не вибрано. Оберіть її у Налаштуваннях.';

  @override
  String screensaverFolderEmpty(String folder) {
    return 'У папці $folder немає фото чи відео';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return 'Не вдалося прочитати $folder. Чи надано дозвіл на доступ до медіафайлів?';
  }

  @override
  String get screensaverReadPhotosFailed => 'Не вдалося прочитати фотографії.';

  @override
  String get screensaverImmichNotReady =>
      'Immich не підключено. Перевірте його в Налаштуваннях.';

  @override
  String get screensaverNoMediaMatch =>
      'Жоден медіафайл не відповідає джерелу та фільтрам.';

  @override
  String get screensaverNoMediaSource =>
      'Немає медіафайлів у вибраному джерелі.';

  @override
  String get screensaverImmichUnreachable =>
      'Не вдалося з\'єднатися із сервером Immich.';

  @override
  String screensaverRetryNotice(String error) {
    return '$error Автоматичний повтор спроби.';
  }

  @override
  String get screensaverVideosTooLarge =>
      'Усі відео в цьому списку завеликі для відтворення на цьому пристрої.';

  @override
  String get settingLauncherEnabledTitle => 'Увімкнути запуск застосунків';

  @override
  String get settingLauncherEnabledDescription =>
      'Відкривати вибраний набір встановлених застосунків із кіоска.';

  @override
  String get settingLauncherAppsDescription =>
      'Застосунки, які пропонує запуск.';

  @override
  String get settingLauncherAutoReturnTitle => 'Повертатися автоматично';

  @override
  String get settingLauncherAutoReturnDescription =>
      'Повертатися до кіоска, якщо інший застосунок певний час не використовується.';

  @override
  String get settingLauncherAutoReturnSecondsTitle =>
      'Повертатися через (секунд)';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      'Час без взаємодії в іншому застосунку до повернення кіоска.';

  @override
  String get launcherOverlayHeld =>
      'Kiosk Satellite може повертатися на передній план і помічати дотики в іншому застосунку.';

  @override
  String get launcherOverlayMissing =>
      'Без цього кіоск не зможе повернутися самостійно, а дотики в іншому застосунку залишаться непоміченими.';

  @override
  String get launcherOverlayRemote =>
      'Без цього кіоск не зможе повернутися самостійно, а дотики в іншому застосунку залишаться непоміченими. Екран надання дозволу зʼявиться на планшеті.';

  @override
  String get launcherBatteryMissing =>
      'Android може призупинити застосунок у фоні, і призупинений таймер ніколи не поверне кіоск.';

  @override
  String get launcherBatteryRemote =>
      'Android може призупинити застосунок у фоні, і призупинений таймер ніколи не поверне кіоск. Діалог дозволу зʼявиться на планшеті.';

  @override
  String get launcherPermissionsSearch =>
      'Дозволи, на які спирається функція автоматичного повернення.';

  @override
  String get settingCameraEnabledTitle => 'Увімкнути камеру';

  @override
  String get settingCameraEnabledDescription =>
      'Використання камери збільшує навантаження на процесор і нагрівання, що може скоротити термін служби батареї та пристрою.';

  @override
  String get settingCameraDeviceTitle => 'Камера';

  @override
  String get settingCameraDeviceDescription => 'Яку камеру використовувати.';

  @override
  String get settingCameraSnapshotResolutionTitle => 'Роздільність знімка';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      'Вища роздільність виглядає чіткіше, але споживає більше ресурсів процесора та мережі.';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle =>
      'Вимкнути знімки під час виявлення';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      'Запобігати автоматичним знімкам, викликаним виявленням. Виявлення руху, обличчя, присутності та жестів продовжує працювати. Ручні запити та безперервні знімки все ще можуть робити зображення.';

  @override
  String get settingCameraSnapshotsTitle => 'Безперервні знімки';

  @override
  String get settingCameraSnapshotsDescription =>
      'Публікувати свіжі знімки камери в Home Assistant із фіксованим інтервалом.';

  @override
  String get settingCameraSnapshotIntervalTitle => 'Інтервал знімків';

  @override
  String get settingCameraSnapshotIntervalDescription =>
      'Секунди між знімками.';

  @override
  String get cameraFront => 'Передня';

  @override
  String get cameraBack => 'Задня';

  @override
  String get cameraOnlyCamera => 'Єдина камера на цьому пристрої.';

  @override
  String get settingMotionSensorTitle => 'Датчик руху';

  @override
  String get settingMotionSensorDescription =>
      'Надавати датчик руху в Home Assistant. ПОПЕРЕДЖЕННЯ: Камера працює постійно, навіть із вимкненим екраном.';

  @override
  String get settingMotionSensorOffDelayTitle => 'Скидати через';

  @override
  String get settingMotionSensorOffDelayDescription =>
      'Секунди без руху до скидання датчика.';

  @override
  String get settingMotionFpsTitle => 'Частота кадрів руху';

  @override
  String get settingMotionFpsDescription =>
      'Кадри за секунду, які камера перевіряє на наявність руху. Менше значення знижує навантаження на процесор; 2 цілком достатньо, щоб помітити наближення людини.';

  @override
  String get settingMotionStartDelayTitle => 'Затримка під час запуску';

  @override
  String get settingMotionStartDelayDescription =>
      'Ігнорувати рух протягом цього часу після запуску камери, корисно для пристроїв, чия камера фізично рухається під час відкриття.';

  @override
  String get settingMotionSensitivityTitle => 'Чутливість до руху';

  @override
  String get settingMotionSensitivityDescription =>
      'Більше значення реагує на менші рухи. 1 вимагає значних змін у кадрі; 100 реагує на найменший рух.';

  @override
  String get cameraMotionPage => 'Датчик руху';

  @override
  String get cameraMotionHint =>
      'Датчик руху Home Assistant і спільні налаштування виявлення';

  @override
  String get cameraNoCamera => 'Камеру не виявлено';

  @override
  String get cameraNoCameraHelp =>
      'Цей пристрій не повідомляє про наявність доступної камери.';

  @override
  String get cameraCameraPermission => 'Відсутній дозвіл на камеру';

  @override
  String get cameraCameraPermissionHelp =>
      'Без нього камеру неможливо використовувати. Діалог дозволу зʼявиться на екрані планшета.';

  @override
  String get cameraGrantOnDevice => 'Надати на пристрої';

  @override
  String get cameraCameraBlocked =>
      'Заблоковано. Android більше не запитуватиме, тому дозвольте це в налаштуваннях застосунку.';

  @override
  String get cameraCameraNeeded =>
      'Без цього камеру неможливо використовувати.';

  @override
  String get cameraAppSettings => 'Налаштування застосунку';

  @override
  String get cameraLatest => 'Останній знімок';

  @override
  String get cameraNoSnapshot => 'Знімків ще немає.';

  @override
  String get cameraImageAlt => 'Останній знімок камери';

  @override
  String get cameraTakeSnapshot => 'Зробити знімок';

  @override
  String get cameraSnapshotFailed => 'Не вдалося зробити знімок.';

  @override
  String cameraSnapshotError(String error) {
    return 'Не вдалося зробити знімок: $error';
  }

  @override
  String get cameraCameraDisabled => 'Камеру вимкнено в налаштуваннях камери.';

  @override
  String get cameraSnapshotBusy => 'Знімок уже створюється.';

  @override
  String get cameraPermissionDenied => 'Дозвіл на камеру не надано.';

  @override
  String get cameraDetectionDisabled => 'Знімки під час виявлення вимкнено.';

  @override
  String get cameraNoImage => 'Камера не повернула зображення.';

  @override
  String get cameraTimedOut => 'Час очікування камери вичерпано.';

  @override
  String get cameraBackground =>
      'Камера недоступна, поки застосунок у фоновому режимі.';

  @override
  String get cameraJustNow => 'щойно';

  @override
  String cameraSecondsAgo(String count) {
    return '$count сек тому';
  }

  @override
  String get cameraMinuteAgo => '1 хвилину тому';

  @override
  String cameraMinutesAgo(String count) {
    return '$count хв тому';
  }

  @override
  String get cameraHourAgo => '1 годину тому';

  @override
  String cameraHoursAgo(String count) {
    return '$count год тому';
  }

  @override
  String get cameraDayAgo => '1 день тому';

  @override
  String cameraDaysAgo(String count) {
    return '$count дн тому';
  }

  @override
  String get cameraStatusHeading => 'Стан потоку';

  @override
  String get cameraClientsHeading => 'Підключені клієнти';

  @override
  String get cameraUnavailable => 'Недоступно';

  @override
  String get cameraStopped => 'Зупинено';

  @override
  String get cameraStreaming => 'Трансляція';

  @override
  String get cameraIdle => 'Очікування';

  @override
  String get cameraConnected => 'Підключено';

  @override
  String get cameraChecking => 'Перевірка…';

  @override
  String get cameraCheckingStatus => 'Перевірка стану потоку…';

  @override
  String get cameraStatusUnavailable => 'Стан потоку недоступний.';

  @override
  String get cameraListenerStopped => 'Слухач зупинено.';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count підключений глядач. Фактичне відео: $resolution.';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return '$count підключених глядачів. Фактичне відео: $resolution.';
  }

  @override
  String get cameraReady =>
      'Готово. Кодер запуститься, коли підключиться глядач.';

  @override
  String cameraFallback(String requested, String actual) {
    return 'Запитано $requested, камера надала $actual.';
  }

  @override
  String cameraAudioError(String error) {
    return 'Аудіо: $error';
  }

  @override
  String get cameraAudioPaused =>
      'Аудіо призупинено, поки браузер використовує мікрофон.';

  @override
  String get cameraAudioStreaming => 'Трансляція аудіо з мікрофона.';

  @override
  String get cameraAudioIdle => 'Аудіо з мікрофона в режимі очікування.';

  @override
  String cameraDiscoveryError(String error) {
    return 'Виявлення ONVIF: $error';
  }

  @override
  String get cameraOnvifUrl => 'URL ONVIF';

  @override
  String get cameraStreamUrl => 'URL потоку';

  @override
  String get cameraWaitingAddress => 'Очікування мережевої адреси';

  @override
  String get cameraClientsUnavailable => 'Інформація про клієнтів недоступна.';

  @override
  String get cameraNoClients => 'Немає підключених клієнтів.';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · Порт $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return 'Підключено $duration';
  }

  @override
  String cameraDurationSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String cameraDurationMinutes(String minutes, String seconds) {
    return '$minutes хв $seconds с';
  }

  @override
  String cameraDurationHours(String hours, String minutes) {
    return '$hours год $minutes хв';
  }

  @override
  String get cameraCredentialsMissing =>
      'Вкажіть імʼя користувача та пароль трансляції для увімкнення автентифікації.';

  @override
  String get cameraPortWaiting => 'Очікування звільнення порту RTSP.';

  @override
  String get cameraListenerFailed => 'Не вдалося запустити слухач RTSP.';

  @override
  String get settingCameraRtspEnabledTitle => 'Увімкнути трансляцію з камери';

  @override
  String get settingCameraRtspEnabledDescription =>
      'Транслювати відео H.264 для клієнтів RTSP або ONVIF. Кодування відео виконується лише тоді, коли підключений глядач. Бажаним є апаратне кодування з резервним програмним за потреби. Використовує камеру, вибрану в налаштуваннях камери.';

  @override
  String get settingCameraStreamingProtocolTitle => 'Протокол трансляції';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF дозволяє сумісним клієнтам виявляти камеру та підключатися до її потоку.';

  @override
  String get settingCameraRtspPortTitle => 'Порт';

  @override
  String get settingCameraRtspPortDescription => 'Порт сервера RTSP.';

  @override
  String get settingCameraOnvifPortTitle => 'Порт';

  @override
  String get settingCameraOnvifPortDescription => 'Порт сервера ONVIF.';

  @override
  String get settingCameraRtspResolutionTitle => 'Роздільність';

  @override
  String get settingCameraRtspResolutionDescription =>
      'Підтримувані розміри трансляції для вибраної камери та кодера. Відео відповідає орієнтації пристрою.';

  @override
  String get settingCameraRtspAnalysisTitle => 'Аналіз руху під час трансляції';

  @override
  String get settingCameraRtspAnalysisDescription =>
      'Залишати виявлення руху, обличчя та жестів рук активними під час підключення глядачів. Вимкнення цієї опції дозволяє використовувати вищу роздільність. Знімки тоді використовують кадри відео з роздільністю трансляції.';

  @override
  String get settingCameraRtspFpsTitle => 'Частота кадрів';

  @override
  String get settingCameraRtspFpsDescription =>
      'Цільова кількість кадрів відео за секунду. Аналіз руху зберігає власну окрему частоту. Фактична частота залежить від камери.';

  @override
  String get settingCameraRtspBitrateTitle => 'Бітрейт';

  @override
  String get settingCameraRtspBitrateDescription =>
      'Цільовий бітрейт відео. Вищий бітрейт покращує деталізацію та споживає більше пропускної здатності мережі.';

  @override
  String get settingCameraRtspAudioTitle => 'Включати звук із мікрофона';

  @override
  String get settingCameraRtspAudioDescription =>
      'Включати звук із мікрофона в потік камери. Використовує ваші налаштування мікрофона. ПОПЕРЕДЖЕННЯ: Збільшене навантаження на процесор.';

  @override
  String get settingCameraRtspAuthTitle => 'Вимагати автентифікацію';

  @override
  String get settingCameraRtspAuthDescription =>
      'Вимагати ім\'я користувача та пароль для перегляду потоку. Автентифікація сама по собі не вмикає шифрування.';

  @override
  String get settingCameraRtspUsernameTitle => 'Імʼя користувача';

  @override
  String get settingCameraRtspUsernameDescription =>
      'Імʼя користувача для клієнтів трансляції.';

  @override
  String get settingCameraRtspPasswordTitle => 'Пароль';

  @override
  String get settingCameraRtspPasswordDescription =>
      'Встановіть пароль для запуску захищеного потоку.';

  @override
  String get cameraStreamingPage => 'Трансляція RTSP та ONVIF';

  @override
  String get cameraStreamingHint =>
      'Транслювати камеру пристрою через RTSP або ONVIF';

  @override
  String get cameraPortError => 'Введіть ціле число порту від 1024 до 65535.';

  @override
  String get cameraUsernameError =>
      'Використовуйте від 1 до 64 символів без пробілів, лапок, двокрапок або зворотних слешів.';

  @override
  String get cameraNoSizes => 'Немає підтримуваних розмірів';

  @override
  String get cameraNoSizesHelp =>
      'Немає підтримуваних розмірів. Перевірте підключення камери.';

  @override
  String get cameraResolutionSupport => 'Підтримка роздільності';

  @override
  String get cameraCheckingSizes =>
      'Перевірка підтримки камери та кодера H.264…';

  @override
  String get cameraSupportedSizes =>
      'Перелічено лише розміри, які підтримуються камерою та кодером H.264 за поточних налаштувань трансляції.';

  @override
  String cameraExtraSizes(String sizes) {
    return 'Вимкніть «Аналіз руху під час трансляції», щоб також використовувати $sizes.';
  }

  @override
  String get cameraAnalysisOff =>
      'Виявлення руху, обличчя та жестів рук призупиняється, поки підключені глядачі. Знімки використовують кадри відео з роздільністю трансляції.';

  @override
  String cameraRejectedSizes(String sizes) {
    return 'Кодер не може використовувати $sizes за цих налаштувань.';
  }

  @override
  String cameraRejectedCount(String count) {
    return '$count розмірів камери виключено, оскільки кодер не може використовувати їх за цих налаштувань.';
  }

  @override
  String get cameraCaptureRejected =>
      'Інші розміри камери недоступні в поточній конфігурації захоплення.';

  @override
  String get cameraOverlaysHeading => 'Накладання';

  @override
  String get settingCameraRtspDateTimeTitle => 'Показувати дату й час';

  @override
  String get settingCameraRtspDateTimeDescription =>
      'Показувати дату й час пристрою у верхньому лівому куті відео, використовуючи його формат дати та налаштування 12/24-годинного формату.';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => 'Чорний фон';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      'Додати чорний фон за датою й часом для кращої видимості.';

  @override
  String get settingCameraRtspTlsTitle => 'Шифрувати потік';

  @override
  String get settingCameraRtspTlsDescription =>
      'Використовувати TLS для шифрування відео та аудіо. Потрібен сумісний плеєр.';

  @override
  String get cameraStreamsNameRequired => 'потрібно вказати назву';

  @override
  String get cameraStreamsBaseUrlRequired =>
      'потрібно вказати дійсний HTTP або HTTPS baseUrl';

  @override
  String get cameraStreamsServerNotFound => 'сервер не знайдено';

  @override
  String get cameraStreamsInvalidStreamList =>
      'Go2RTC повернув недійсний список потоків';

  @override
  String get cameraStreamsKindRequired => 'тип має бути go2rtc, whep або ha';

  @override
  String get cameraStreamsProtocolRequired =>
      'preferredProtocol має бути auto, webrtc, hls або mjpeg';

  @override
  String get cameraStreamsServerRequired => 'потрібно вказати дійсний serverId';

  @override
  String get cameraStreamsStreamRequired => 'потрібно вказати streamName';

  @override
  String get cameraStreamsEntityRequired =>
      'потрібно вказати entityId виду camera.*';

  @override
  String get cameraStreamsWhepRequired => 'потрібно вказати дійсний URL WHEP';

  @override
  String get cameraStreamsCameraNotFound => 'камеру не знайдено';

  @override
  String get cameraStreamsListRequired => 'cameraIds має бути списком';

  @override
  String get cameraStreamsViewCount => 'вигляд має містити від 1 до 12 камер';

  @override
  String get cameraStreamsRepeatedCamera =>
      'камера може зʼявлятися лише один раз на вигляд';

  @override
  String get cameraStreamsUnknownViewCamera => 'вигляд містить невідому камеру';

  @override
  String get cameraStreamsUniqueViewName => 'назва вигляду має бути унікальною';

  @override
  String get cameraStreamsGridRange => 'сітка має бути від 1 до 12';

  @override
  String get cameraStreamsGridTooSmall => 'сітка менша за кількість камер';

  @override
  String get cameraStreamsViewNotFound => 'вигляд не знайдено';

  @override
  String get cameraStreamsDefaultViewDelete =>
      'стандартний вигляд не можна видалити; натомість очистіть його';

  @override
  String get cameraStreamsViewEmpty => 'вигляд не містить камер';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return 'не вдалося прочитати Home Assistant: $error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return 'не вдалося підключитися до $server: $error';
  }

  @override
  String get cameraStreamsHaUnavailable =>
      'Home Assistant не налаштовано або він недоступний';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC повернув HTTP $status';
  }

  @override
  String get cameraStreamsImportHa => 'Імпортувати камери з Home Assistant';

  @override
  String get cameraStreamsImportHaHelp =>
      'Додати кожну камеру з підключеного Home Assistant, що відтворюється через WebRTC, HLS або MJPEG. Повторний імпорт додає нові камери.';

  @override
  String get cameraStreamsImportFailed => 'Імпорт не вдався';

  @override
  String get cameraStreamsImportComplete => 'Імпорт завершено';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return '$added додано, $missing відсутньо.';
  }

  @override
  String get settingCameraAllowH265Title => 'Дозволити потоки H.265';

  @override
  String get settingCameraAllowH265Description =>
      'Відтворювати потоки камер H.265 як є. Пристрій, який не підтримує декодування H.265, показуватиме порожнє зображення.';

  @override
  String get settingCameraPreferMseTitle => 'Надавати перевагу MSE над WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      'Транслювати камери Go2RTC спочатку через MSE. Для пристроїв, які не підтримують WebRTC; додає 1-2 секунди затримки.';

  @override
  String get settingCameraPreferHlsTitle => 'Надавати перевагу HLS над WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      'Транслювати камери Home Assistant спочатку через HLS. Для пристроїв, які не підтримують WebRTC; додає кілька секунд затримки.';

  @override
  String get settingCameraSingleAudioTitle =>
      'Відтворювати звук для однієї камери';

  @override
  String get settingCameraSingleAudioDescription =>
      'Відтворювати звук камери, коли на екрані лише одна камера. Сітки з кількома камерами залишаються без звуку.';

  @override
  String get settingCameraPinchZoomTitle =>
      'Масштабування однієї камери щипком';

  @override
  String get settingCameraPinchZoomDescription =>
      'Збільшувати зображення двома пальцями, коли на екрані лише одна камера. Перетягуйте для переміщення, двічі торкніться для скидання.';

  @override
  String get settingCameraAutoDismissSecondsTitle =>
      'Автоматично закривати через';

  @override
  String get settingCameraAutoDismissSecondsDescription =>
      'Самостійно закривати відкритий перегляд камери; 0 залишає його відкритим. Заставка камери не змінюється.';

  @override
  String get cameraStreamsPlayback => 'Відтворення';

  @override
  String get cameraStreamsOff => 'Вимкнено';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String get cameraStreamsGridHelp =>
      'Сітки з кількома камерами призначені лише для відео. Для малопотужних пристроїв використовуйте потоки Go2RTC нижчої роздільності у виглядах і за потреби налаштуйте окремий повноекранний потік.';

  @override
  String get cameraStreamsServers => 'Сервери Go2RTC';

  @override
  String get cameraStreamsImportStreams => 'Імпортувати потоки';

  @override
  String get cameraStreamsDeleteServer => 'Видалити сервер';

  @override
  String get cameraStreamsAddServer => 'Додати сервер Go2RTC';

  @override
  String get cameraStreamsAddServerHelp =>
      'Підключитися до сервера та імпортувати його потоки.';

  @override
  String get cameraStreamsEditServer => 'Редагувати сервер';

  @override
  String get cameraStreamsName => 'Назва';

  @override
  String get cameraStreamsBaseUrl => 'Базовий URL';

  @override
  String get cameraStreamsUsername => 'Імʼя користувача (необовʼязково)';

  @override
  String get cameraStreamsNewPassword =>
      'Новий пароль (залиште порожнім, щоб зберегти)';

  @override
  String get cameraStreamsPassword => 'Пароль (необовʼязково)';

  @override
  String get cameraStreamsInvalidCertificate =>
      'Дозволити недійсний сертифікат TLS';

  @override
  String get cameraStreamsSaveServerFailed => 'Не вдалося зберегти сервер';

  @override
  String get cameraStreamsDeleteServerHelp =>
      'Його камери буде видалено з усіх виглядів.';

  @override
  String get cameraStreamsCameras => 'Камери';

  @override
  String get cameraStreamsNoCameras => 'Камери не налаштовано';

  @override
  String get cameraStreamsNoCamerasHelp =>
      'Імпортуйте камери з Home Assistant чи Go2RTC або додайте камеру вручну.';

  @override
  String get cameraStreamsDeleteCamera => 'Видалити камеру';

  @override
  String get cameraStreamsAddManually => 'Додати камеру вручну';

  @override
  String get cameraStreamsAddManuallyHelp =>
      'Використовуйте назву потоку Go2RTC, URL WHEP або сутність камери Home Assistant.';

  @override
  String get cameraStreamsUnknownCamera => 'Невідома камера';

  @override
  String get cameraStreamsUnknownServer => 'Невідомий сервер';

  @override
  String get cameraStreamsMissing => ' (відсутня)';

  @override
  String get cameraStreamsAddCamera => 'Додати камеру';

  @override
  String get cameraStreamsEditCamera => 'Редагувати камеру';

  @override
  String get cameraStreamsType => 'Тип';

  @override
  String get cameraStreamsGo2RtcStream => 'Потік Go2RTC';

  @override
  String get cameraStreamsDirectWhep => 'Прямий URL WHEP';

  @override
  String get cameraStreamsHaCamera => 'Камера Home Assistant';

  @override
  String get cameraStreamsEntity => 'Сутність камери';

  @override
  String get cameraStreamsProtocol => 'Бажаний протокол';

  @override
  String get cameraStreamsAuto => 'Авто';

  @override
  String get cameraStreamsServer => 'Сервер';

  @override
  String get cameraStreamsStreamName => 'Назва потоку';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Назва потоку Go2RTC';

  @override
  String get cameraStreamsFullscreen => 'Повноекранний потік (необовʼязково)';

  @override
  String get cameraStreamsWhep => 'URL WHEP';

  @override
  String get cameraStreamsSaveCameraFailed => 'Не вдалося зберегти камеру';

  @override
  String get cameraStreamsDeleteCameraHelp =>
      'Її буде видалено з усіх виглядів.';

  @override
  String get cameraStreamsLoadFailed => 'Не вдалося завантажити камери.';

  @override
  String get cameraStreamsViews => 'Вигляди';

  @override
  String get cameraStreamsEmptyView => 'Камер ще немає';

  @override
  String get cameraStreamsNamesShown => 'Назви показано';

  @override
  String get cameraStreamsNamesHidden => 'Назви приховано';

  @override
  String get cameraStreamsShowView => 'Показати вигляд';

  @override
  String get cameraStreamsDeleteView => 'Видалити вигляд';

  @override
  String get cameraStreamsCreateView => 'Створити вигляд камер';

  @override
  String get cameraStreamsAddFirst => 'Спочатку додайте камеру.';

  @override
  String get cameraStreamsChooseCameras =>
      'Виберіть і впорядкуйте до 12 камер.';

  @override
  String get cameraStreamsShowFailed => 'Не вдалося показати вигляд';

  @override
  String get cameraStreamsShowFailedRemote => 'Не вдалося показати вигляд';

  @override
  String get cameraStreamsEditView => 'Редагувати вигляд';

  @override
  String get cameraStreamsShowNames => 'Показувати назви камер';

  @override
  String get cameraStreamsShowNamesHelp =>
      'Відображати мітку над кожною камерою.';

  @override
  String get cameraStreamsGrid => 'Сітка';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count камера';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return '$count камер';
  }

  @override
  String get cameraStreamsInView => 'У цьому вигляді';

  @override
  String get cameraStreamsAvailable => 'Доступно';

  @override
  String cameraStreamsPosition(String position) {
    return 'Позиція $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'Відсутня в Go2RTC';

  @override
  String get cameraStreamsSaveViewFailed => 'Не вдалося зберегти вигляд';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return 'Видалити $name?';
  }

  @override
  String get cameraStreamsCannotUndo => 'Цю дію не можна скасувати.';

  @override
  String get cameraStreamsShow => 'Показати';

  @override
  String get cameraStreamsStop => 'Зупинити';

  @override
  String get settingAnalyticsBasicTitle => 'Базова аналітика';

  @override
  String get settingAnalyticsBasicDescription =>
      'Інформація про ваш пристрій, як-от модель, версія Android, версія застосунку, розмір екрана та мова.';

  @override
  String get settingAnalyticsUsageTitle => 'Використання';

  @override
  String get settingAnalyticsUsageDescription =>
      'Деталі того, що ви використовуєте в Kiosk Satellite.';

  @override
  String get settingAnalyticsDiagnosticsTitle => 'Діагностика';

  @override
  String get settingAnalyticsDiagnosticsDescription =>
      'Надсилати звіти про збої в разі виникнення несподіваних помилок.';

  @override
  String get deviceAnalyticsPage => 'Аналітика Kiosk Satellite';

  @override
  String get deviceAnalyticsIntro =>
      'Діліться анонімізованою інформацією вашого встановлення, щоб допомогти зробити Kiosk Satellite кращим і визначити, які пристрої та функції потребують уваги.';

  @override
  String get deviceAnalyticsLearn => 'Дізнайтеся, як ми обробляємо ваші дані';

  @override
  String get deviceAnalyticsLearnHelp =>
      'Що надсилає аналітика Kiosk Satellite і що вона ніколи не передає.';

  @override
  String get deviceExportConfig => 'Експорт конфігурації';

  @override
  String get deviceExportConfigHelp =>
      'Зберегти всі налаштування та локальне сховище сторінки у файл.';

  @override
  String get deviceExportConfigRemoteHelp =>
      'Завантажити всі налаштування та локальне сховище сторінки.';

  @override
  String get deviceImportConfig => 'Імпорт конфігурації';

  @override
  String get deviceImportConfigHelp =>
      'Замінити налаштування цього пристрою з експортованого файлу.';

  @override
  String get deviceExportFailed => 'Експорт не вдався';

  @override
  String get deviceExported => 'Конфігурацію експортовано';

  @override
  String get deviceImportFailed => 'Імпорт не вдався';

  @override
  String get deviceInvalidJson => 'Цей файл не є дійсним JSON.';

  @override
  String get deviceImportComplete => 'Імпорт завершено';

  @override
  String deviceAppliedSettings(String count) {
    return 'Застосовано $count налаштувань.';
  }

  @override
  String deviceAppliedReload(String count) {
    return 'Застосовано $count налаштувань. Сторінка може перезавантажитися.';
  }

  @override
  String get deviceReplaceOriginal => 'Замінити оригінальний пристрій';

  @override
  String get deviceReplaceQuestion =>
      'Замінити налаштування цього пристрою на налаштування з файлу? Сторінка може перезавантажитися.';

  @override
  String get deviceNewDevice => 'Налаштувати як новий пристрій';

  @override
  String get deviceReplaceIdentity =>
      'Зберігає назву та ідентифікатор ESPHome резервної копії; оригінальний пристрій має залишатися офлайн.';

  @override
  String get deviceNewIdentity =>
      'Призначити власну назву та ідентифікатор ESPHome, щоб обидва пристрої були унікальними.';

  @override
  String get deviceRestoreStorage => 'Відновити локальне сховище Webview';

  @override
  String get deviceRestoreStorageHelp =>
      'Включає сеанс входу в Home Assistant та вибір assist_satellite у Voice Satellite - два пристрої не повинні спільно використовувати один супутник.';

  @override
  String get deviceDownload => 'Завантажити';

  @override
  String get deviceChooseFile => 'Вибрати файл…';

  @override
  String get deviceImportFailedSentence => 'Імпорт не вдався.';

  @override
  String deviceReplaceNamed(String name) {
    return 'Замінити «$name»';
  }

  @override
  String get settingDeviceNameTitle => 'Назва пристрою';

  @override
  String get settingDeviceNameDescription =>
      'Зрозуміла назва, яка відображається у віддаленому керуванні та передається до Home Assistant як назва пристрою.';

  @override
  String get settingDeviceHostnameTitle => 'Назва mDNS';

  @override
  String get settingDeviceHostnameDescription =>
      'Доступ до віддаленого адміністрування за цією назвою та налаштованим портом у локальній мережі. Очистіть, щоб знову використовувати назву пристрою.';

  @override
  String get settingDisableImpellerTitle => 'Застарілий рендерер';

  @override
  String get settingDisableImpellerDescription =>
      'Використовувати старіший рендерер Skia для старих GPU, які завершують роботу аварійно під час запуску. Вмикається автоматично після двох таких збоїв; набуває чинності під час наступного запуску застосунку.';

  @override
  String get settingLegacyWebViewTitle => 'Застарілий рендерер WebView';

  @override
  String get settingLegacyWebViewDescription =>
      'Малювати панель керування в текстуру для старих GPU, які завершують роботу аварійно під час її появи. Вмикається автоматично за потреби; набуває чинності під час наступного запуску застосунку.';

  @override
  String get deviceHostnamePlaceholder => 'Встановлюється з назви пристрою';

  @override
  String get deviceConfiguration => 'Конфігурація';

  @override
  String get devicePermissionsManager => 'Менеджер дозволів';

  @override
  String get deviceOptions => 'Параметри';

  @override
  String get deviceStatus => 'Стан';

  @override
  String get deviceConnection => 'Підключення';

  @override
  String get devicePermissions => 'Дозволи';

  @override
  String get deviceHelp => 'Довідка';

  @override
  String get deviceAccess => 'Доступ';

  @override
  String get deviceReading => 'Зчитування…';

  @override
  String get deviceChecking => 'Перевірка…';

  @override
  String get deviceUnavailable => 'Стан недоступний.';

  @override
  String get deviceGrantOnDevice => 'Надати на пристрої';

  @override
  String get deviceAppSettings => 'Налаштування застосунку';

  @override
  String get deviceCopyCommand => 'Копіювати команду';

  @override
  String get deviceOpenGuide => 'Відкрити посібник';

  @override
  String get deviceNotSet => 'Не встановлено';

  @override
  String get deviceGranted => 'Надано';

  @override
  String get deviceNotGranted => 'Не надано';

  @override
  String get deviceMissing => 'Відсутній';

  @override
  String get deviceNotOffered => 'Не пропонується';

  @override
  String get deviceOn => 'увімкнено';

  @override
  String get deviceOff => 'вимкнено';

  @override
  String get deviceServiceHint => 'Стан, фонова робота, необхідні дозволи';

  @override
  String get deviceRemoteHintActual =>
      'Керуйте цим кіоском із браузера у вашій мережі';

  @override
  String get deviceUpdatesHint => 'Де застосунок шукає нові випуски';

  @override
  String get deviceShizukuHint =>
      'Підключення, дозволи Android та налаштування';

  @override
  String get deviceHelperHint =>
      'Стан тихого оновлення, налаштування ADB та інструкції';

  @override
  String get deviceAnalyticsHint =>
      'Діліться анонімізованою інформацією для покращення Kiosk Satellite';

  @override
  String get deviceHardwareHint =>
      'Модель, версія Android, адреси, памʼять, час роботи';

  @override
  String get deviceHaHint => 'Підключення, версія та відображення кіоска';

  @override
  String get deviceWebViewHint =>
      'Версія рушія, рендерер та рядок агента користувача';

  @override
  String get devicePasswordSet => '•••••• (встановлено)';

  @override
  String get deviceSaveFailed =>
      'Не вдалося зберегти це налаштування. Спробуйте ще раз.';

  @override
  String get deviceOpenSettingsDevice => 'Відкрити налаштування на пристрої';

  @override
  String get deviceHardwarePage => 'Апаратне забезпечення';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => 'Модель пристрою';

  @override
  String get deviceAndroidVersion => 'Версія Android';

  @override
  String get deviceAndroidBuild => 'Збірка Android';

  @override
  String get deviceIpv4 => 'Адреса IPv4';

  @override
  String get deviceIpv6 => 'Адреси IPv6';

  @override
  String get deviceAppUptime => 'Час роботи застосунку';

  @override
  String get deviceNetworkUptime => 'Час роботи мережі';

  @override
  String get deviceCpuUsage => 'Використання процесора';

  @override
  String get deviceCpuTemp => 'Температура процесора';

  @override
  String get deviceBatteryLevel => 'Рівень заряду акумулятора';

  @override
  String get deviceScreenBrightness => 'Яскравість екрана';

  @override
  String get deviceScreenStatus => 'Стан екрана';

  @override
  String get deviceScreenSize => 'Розмір екрана';

  @override
  String get deviceRam => 'Оперативна памʼять (вільно/всього)';

  @override
  String get deviceStorage => 'Внутрішня памʼять (вільно/всього)';

  @override
  String get deviceHaUrl => 'URL Home Assistant';

  @override
  String get deviceWakeDetection => 'Розпізнавання слова активації';

  @override
  String get deviceWakeStatus => 'Стан слова активації';

  @override
  String get deviceEngine => 'Рушій';

  @override
  String get deviceWakeWords => 'Слова активації';

  @override
  String get deviceStopWord => 'Стоп-слово';

  @override
  String get deviceMotionDetection => 'Виявлення руху';

  @override
  String get deviceFaceDetection => 'Виявлення обличчя';

  @override
  String get deviceProvider => 'Постачальник';

  @override
  String get deviceVersion => 'Версія';

  @override
  String get deviceUserAgent => 'Агент користувача';

  @override
  String get devicePlugged => 'підключено до живлення';

  @override
  String get deviceLowMemory => 'мало';

  @override
  String get deviceRequiredPermissions => 'Обовʼязкові системні дозволи';

  @override
  String get devicePermissionIntro =>
      'Дозволи надаються на цьому пристрої, тому кожна кнопка відкриває діалогове вікно або екран налаштувань Android тут. Деякі виробники додають власні менеджери батареї чи автозапуску, про які Android не може повідомити.';

  @override
  String get devicePermissionIntroRemote =>
      'Дозволи надаються на пристрої, тому кожна кнопка відкриває діалогове вікно або екран налаштувань Android там. Деякі виробники додають власні менеджери батареї чи автозапуску, про які Android не може повідомити.';

  @override
  String get deviceMicrophone => 'Мікрофон';

  @override
  String get deviceMicrophoneHeld =>
      'Дозволяє використання мікрофона для виявлення слова активації, перетворення мовлення на текст і викликів інтеркому.';

  @override
  String get deviceBattery => 'Необмежений заряд батареї';

  @override
  String get deviceBatteryHeld =>
      'Дозволяє процесу працювати у фоновому режимі без призупинення чи завершення.';

  @override
  String get deviceCamera => 'Камера';

  @override
  String get deviceCameraHeld =>
      'Виявлення руху та знімки можуть використовувати камеру.';

  @override
  String get deviceBluetooth => 'Пристрої поблизу';

  @override
  String get deviceBluetoothHeld =>
      'Проксі Bluetooth може шукати пристрої поблизу.';

  @override
  String get deviceNotifications => 'Сповіщення';

  @override
  String get deviceNotificationsHeld =>
      'Дозволяє постійне сповіщення служби Kiosk Satellite Service, яке показує, що саме вона підтримує активним.';

  @override
  String get deviceOverlay => 'Показ поверх інших застосунків';

  @override
  String get deviceOverlayHeld =>
      'Kiosk Satellite може повертатися на передній план.';

  @override
  String get deviceWriteSettings => 'Зміна системних налаштувань';

  @override
  String get deviceWriteSettingsHeld =>
      'Зміна яскравості змінює реальну яскравість панелі.';

  @override
  String get deviceUiGuard => 'Захист системного інтерфейсу';

  @override
  String get deviceUiGuardHeld =>
      'Шторка сповіщень і список нещодавніх застосунків закриваються самостійно, поки екран захищено.';

  @override
  String get deviceDeviceAdmin => 'Адміністратор пристрою';

  @override
  String get deviceDeviceAdminHeld => 'Дозволяє застосунку вимикати екран.';

  @override
  String get deviceAllFiles => 'Доступ до всіх файлів';

  @override
  String get deviceAllFilesHeld =>
      'Файловий менеджер може переглядати спільне сховище.';

  @override
  String get deviceUsageAccess => 'Доступ до даних про використання';

  @override
  String get deviceUsageAccessHeld =>
      'Датчик активного застосунку може визначати назву застосунку на екрані.';

  @override
  String get deviceLocation => 'Місцезнаходження';

  @override
  String get deviceLocationHeld =>
      'Сторінки, сканування Bluetooth та датчики місцезнаходження можуть використовувати координати пристрою.';

  @override
  String get deviceMicBlocked =>
      'Заблоковано. Android більше не запитуватиме, тому дозвольте це в налаштуваннях застосунку.';

  @override
  String get deviceMicMissing =>
      'Розпізнавання слова активації ввімкнено, але нічого не слухає.';

  @override
  String get deviceMicIdle =>
      'Потрібно для розпізнавання слова активації, інтеркому та сторінок, які запитують мікрофон.';

  @override
  String get deviceBatteryMissing =>
      'Android може призупинити застосунок із вимкненим екраном, втрачаючи зʼєднання з Home Assistant і сутності ESPHome.';

  @override
  String get deviceCameraMissing =>
      'Камеру ввімкнено, але її неможливо відкрити.';

  @override
  String get deviceCameraIdle =>
      'Потрібно для виявлення руху, знімків камери та сторінок, які запитують камеру.';

  @override
  String get deviceBluetoothMissing =>
      'Проксі Bluetooth увімкнено, але сканування неможливе.';

  @override
  String get deviceBluetoothLocation =>
      'Для сканування Bluetooth потрібен дозвіл на місцезнаходження.';

  @override
  String get deviceBluetoothLocationOff =>
      'Місцезнаходження вимкнено в налаштуваннях пристрою, тому сканування Bluetooth нічого не знаходить.';

  @override
  String get deviceBluetoothIdle =>
      'Потрібно для проксі Bluetooth для сканування пристроїв.';

  @override
  String get deviceNotificationMissing =>
      'Потрібно для показу постійного сповіщення служби Kiosk Satellite Service.';

  @override
  String get deviceOverlayMissing =>
      'Без цього застосунок не може перезапуститися після збою, оновлення або почутого слова активації за іншим застосунком.';

  @override
  String get deviceOverlayIdle =>
      'Дозволяє застосунку повертатися на передній план, а екрану блокування - покривати весь екран.';

  @override
  String get deviceBrightnessMissing =>
      'Яскравість лише затемнює вікно застосунку, тому екран і Home Assistant не бачать змін.';

  @override
  String get deviceBrightnessIdle =>
      'Потрібно для встановлення реальної яскравості панелі замість затемнення вікна застосунку.';

  @override
  String get deviceGuardMissing =>
      'Шторка сповіщень і список нещодавніх застосунків залишаються доступними. Увімкніть Kiosk Satellite у розділі «Спеціальні можливості».';

  @override
  String get deviceGuardIdle =>
      'Закриває шторку сповіщень і нещодавні застосунки, поки режим кіоска захищає екран.';

  @override
  String get deviceAdminIdle =>
      'Дозволяє вимкненню екрана знеструмлювати панель замість простого затемнення.';

  @override
  String get deviceFilesIdle =>
      'Дозволяє файловому менеджеру переглядати спільне сховище замість лише папки застосунку.';

  @override
  String get deviceUsageIdle =>
      'Дозволяє датчику активного застосунку визначати інші застосунки, крім Kiosk Satellite.';

  @override
  String get deviceLocationMissing =>
      'Android не надаватиме результатів сканування Bluetooth без дозволу на місцезнаходження, а датчики не зможуть зчитувати дані GPS.';

  @override
  String get deviceLocationIdle =>
      'Використовується сторінками, які запитують ваше місцезнаходження, скануванням Bluetooth і датчиками місцезнаходження ESPHome.';

  @override
  String get deviceServiceOverlayMissing =>
      'Без цього служба не може перезапустити кіоск після збою або закриття з нещодавніх.';

  @override
  String get deviceServiceOverlayIdle =>
      'Потрібно для перезапуску кіоска після збою.';

  @override
  String get deviceListeningMissing =>
      'Фонове прослуховування ввімкнено, але нічого не слухає.';

  @override
  String get deviceListeningIdle => 'Потрібно для фонового прослуховування.';

  @override
  String get deviceMotionIdle => 'Потрібно для виявлення руху.';

  @override
  String get deviceBatteryAdb =>
      'Цей пристрій не має відповідного екрана налаштувань. Надайте його через adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      'Цей пристрій не має відповідного екрана налаштувань. Надайте його через adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get settingRemoteEnabledTitle => 'Віддалене керування';

  @override
  String get settingRemoteEnabledDescription =>
      'Запустити вбудований вебсервер адміністрування.';

  @override
  String get settingRemotePortTitle => 'Порт сервера';

  @override
  String get settingRemotePortDescription =>
      'Порт інтерфейсу віддаленого адміністратора.';

  @override
  String get settingRemotePasswordTitle => 'Пароль адміністратора';

  @override
  String get settingRemotePasswordDescription =>
      'Необхідний для входу у віддалений інтерфейс.';

  @override
  String get settingRemoteFleetDiscoveryTitle => 'Пошук інших кіосків';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      'Оголошувати цей пристрій у мережі та відображати інші кіоски у віддаленому адмініструванні для перемикання між ними.';

  @override
  String get deviceRemotePage => 'Віддалене адміністрування';

  @override
  String get deviceAdminAddress => 'Адреса адміністратора';

  @override
  String get deviceAdminAddressHelp =>
      'Відкрийте цю адресу в браузері на вашому компʼютері.';

  @override
  String get deviceByName => 'За назвою';

  @override
  String get deviceByNameHelp =>
      'Та сама адреса за назвою хоста в мережах, що підтримують домен .local.';

  @override
  String get devicePasswordNeeded =>
      'Встановіть пароль адміністратора нижче, щоб запустити сервер.';

  @override
  String get deviceServerStopped => 'Сервер не запущено.';

  @override
  String devicePortError(String port, String error) {
    return 'Не вдалося прослуховувати порт $port: $error';
  }

  @override
  String get settingRemoteTlsTitle => 'Використовувати HTTPS';

  @override
  String get settingRemoteTlsDescription =>
      'Шифрувати віддалене адміністрування, API та WebSocket. Ваш браузер може запропонувати прийняти сертифікат пристрою.';

  @override
  String get settingServiceCpuAwakeTitle =>
      'Утримувати процесор активним, коли екран вимкнено';

  @override
  String get settingServiceCpuAwakeDescription =>
      'Утримує блокування сну під час вимкненого екрана, щоб підключення та таймери працювали вчасно. Витрачає заряд батареї на непідключеному планшеті.';

  @override
  String get deviceServicePage => 'Служба Kiosk Satellite Service';

  @override
  String get deviceKeepingRunning => 'Підтримання роботи';

  @override
  String get deviceService => 'Служба';

  @override
  String get deviceStopped => 'Зупинено';

  @override
  String get deviceStoppedSentence => 'Зупинено.';

  @override
  String get deviceRunning => 'Працює';

  @override
  String get deviceRunningSentence => 'Працює.';

  @override
  String get deviceRunningBackground =>
      'Працює без виключення для переднього плану.';

  @override
  String get deviceServiceTypes => 'Типи фонової служби';

  @override
  String get deviceServiceTypesHelp =>
      'Що служба декларує для Android для підтримуваних функцій.';

  @override
  String get deviceNoneDeclared => 'Не задекларовано.';

  @override
  String get deviceNone => 'немає';

  @override
  String get deviceCpuLock => 'Блокування сну процесора';

  @override
  String get deviceCpuOff => 'Вимкнено: налаштування нижче вимкнено.';

  @override
  String get deviceCpuHeld => 'Утримується: екран вимкнено.';

  @override
  String get deviceCpuReleased => 'Звільнено, поки екран увімкнено.';

  @override
  String get deviceNotHeld => 'Не утримується.';

  @override
  String get deviceHeld => 'Утримується';

  @override
  String get deviceReleased => 'Звільнено';

  @override
  String get deviceWifiLock => 'Блокування Wi-Fi';

  @override
  String get deviceWifiHeld =>
      'Утримується: радіомодуль не переходить у режим енергозбереження.';

  @override
  String get deviceWifiHelp =>
      'Запобігає переходу Wi-Fi в енергозбереження під час вимкненого екрана.';

  @override
  String get deviceNotification => 'Сповіщення';

  @override
  String get deviceNotificationHidden =>
      'Приховано: сповіщення вимкнено для застосунку. Служба працює незалежно від цього.';

  @override
  String get deviceNotificationShown =>
      'Відображається в шторці сповіщень під час роботи служби.';

  @override
  String get deviceHidden => 'Приховано';

  @override
  String get deviceShown => 'Відображається';

  @override
  String get deviceReasonHa => 'Підключення Home Assistant';

  @override
  String get deviceReasonHaHelp =>
      'Підтримує сеанс панелі керування та websocket відкритими, коли екран вимкнено.';

  @override
  String get deviceReasonListening => 'Фонове прослуховування';

  @override
  String get deviceReasonListeningHelp =>
      'Підтримує роботу рушія слова активації та мікрофона за іншими застосунками.';

  @override
  String get deviceReasonRtsp => 'Аудіо мікрофона RTSP';

  @override
  String get deviceReasonRtspHelp =>
      'Підтримує доступність трансляції мікрофона для підключених глядачів RTSP.';

  @override
  String get deviceReasonEspHome => 'Сервер ESPHome';

  @override
  String get deviceReasonEspHomeHelp =>
      'Підтримує відповіді сервера API ESPHome для Home Assistant.';

  @override
  String get deviceReasonRemote => 'Віддалене адміністрування';

  @override
  String get deviceReasonRemoteHelp =>
      'Підтримує відповіді вебсервера адміністрування.';

  @override
  String get deviceReasonProtections => 'Захисти кіоска';

  @override
  String get deviceReasonProtectionsHelp =>
      'Перезапускає кіоск у разі його закриття з нещодавніх або збою.';

  @override
  String get deviceReasonBluetooth => 'Проксі Bluetooth';

  @override
  String get deviceReasonBluetoothHelp =>
      'Підтримує сканування Bluetooth, поки застосунок не на екрані.';

  @override
  String get deviceReasonLocation => 'Датчики місцезнаходження';

  @override
  String get deviceReasonLocationHelp =>
      'Забезпечує надходження даних GPS, коли екран вимкнено або активний інший застосунок.';

  @override
  String get deviceReasonPerson => 'Виявлення присутності людей';

  @override
  String get deviceReasonPersonHelp =>
      'Продовжує зчитувати датчик присутності пристрою, поки інший застосунок на передньому плані.';

  @override
  String get deviceReasonCameraHelp =>
      'Підтримує камеру доступною після вимкнення екрана для виявлення руху та обличчя.';

  @override
  String deviceServiceStopped(String error) {
    return 'Зупинено: $error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return 'Працює протягом $uptime.';
  }

  @override
  String get settingShizukuInstallUpdatesTitle =>
      'Встановлювати оновлення через Shizuku';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      'Встановлювати оновлення Kiosk Satellite без підтвердження на пристрої. Shizuku має бути запущено та авторизовано.';

  @override
  String get deviceShizukuAccess => 'Доступ Shizuku';

  @override
  String get deviceShizukuCheck => 'Перевірка доступності';

  @override
  String get deviceShizukuRoot => 'Підключено з правами root';

  @override
  String get deviceShizukuShell => 'Підключено з доступом shell';

  @override
  String get deviceShizukuGrant =>
      'Торкніться для надання доступу. Підтвердьте запит на цьому кіоску.';

  @override
  String get deviceShizukuGrantRemote =>
      'Надайте доступ і підтвердьте запит на цьому кіоску.';

  @override
  String get deviceShizukuDenied =>
      'Дозвольте Kiosk Satellite у застосунку Shizuku.';

  @override
  String get deviceShizukuUnsupported =>
      'Потрібна версія Shizuku 13 або новіша.';

  @override
  String get deviceShizukuStart => 'Запустіть Shizuku на цьому пристрої.';

  @override
  String get deviceShizukuTest => 'Тестувати підключення';

  @override
  String get deviceShizukuTestHelp =>
      'Зчитати ідентифікатор процесу без внесення змін на пристрої.';

  @override
  String get deviceShizukuTestTitle => 'Тест підключення';

  @override
  String get deviceShizukuTestFailed =>
      'Shizuku не вдалося завершити тест підключення.';

  @override
  String get deviceShizukuAlreadyGranted => 'Усі дозволи вже надано.';

  @override
  String get deviceShizukuConfirmed => 'Android підтвердив запитані дозволи.';

  @override
  String get deviceShizukuResults => 'Результати дозволів';

  @override
  String get deviceShizukuGrantAll => 'Надати всі дозволи';

  @override
  String get deviceShizukuGrantAllHelp =>
      'Надати всі дозволи, які використовує KS, включно з функціями, які зараз вимкнені.';

  @override
  String get deviceShizukuSetup => 'Налаштувати Shizuku';

  @override
  String get deviceShizukuSetupHelp =>
      'Прочитати інструкції щодо встановлення та запуску.';

  @override
  String get deviceShizukuLifetime =>
      'Shizuku, запущений через ADB, необхідно запускати знову після перезавантаження пристрою. Доступ shell не надає прав root.';

  @override
  String get deviceShizukuFailed => 'Запит Shizuku не вдався';

  @override
  String get deviceShizukuApprove => 'Підтвердьте запит на кіоску.';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku успішно виконав команду з доступом $access.';
  }

  @override
  String get shizukuPermissionUnconfirmed =>
      'Android не підтвердив цей дозвіл. Перевірте менеджер дозволів на пристрої.';

  @override
  String get shizukuPermissionReadFailed =>
      'Не вдалося прочитати поточні дозволи. Спробуйте ще раз.';

  @override
  String get shizukuRestartTimedOut =>
      'Час очікування команди перезапуску вичерпано';

  @override
  String get shizukuRestartRefused => 'Android відхилив перезапуск';

  @override
  String get shizukuCommandTimedOut => 'Час очікування команди вичерпано';

  @override
  String get shizukuRequestRejected => 'Android відхилив запит';

  @override
  String get deviceDisconnectedError => 'Пристрій відключено';

  @override
  String get deviceResponseTimedOut =>
      'Час очікування відповіді пристрою вичерпано';

  @override
  String get deviceRequestAborted => 'Запит перервано';

  @override
  String get shizukuActionBusy => 'Дія Shizuku на пристрої вже виконується';

  @override
  String get shizukuGrantFirst => 'Спочатку надайте доступ Shizuku';

  @override
  String get shizukuNoResponse => 'Команда Shizuku не відповіла';

  @override
  String get shizukuCommandFailed => 'Команда Shizuku не вдалася';

  @override
  String get shizukuStartRequired =>
      'Запустіть Shizuku 13 або новішої версії та надайте дозвіл Kiosk Satellite у Shizuku';

  @override
  String get shizukuConnectionFailed => 'Підключення Shizuku не вдалося';

  @override
  String get shizukuHelperNotConnected => 'Помічник Shizuku не підключився';

  @override
  String get shizukuHelperUnavailable => 'Помічник Shizuku недоступний';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates =>
      'Шифрування з\'єднання та сертифікати';

  @override
  String get tlsCertificateType => 'Тип сертифіката';

  @override
  String get tlsImported => 'Імпортовано';

  @override
  String get tlsSelfSigned => 'Самопідписаний';

  @override
  String get tlsExpires => 'Діє до';

  @override
  String get tlsSHA256Fingerprint => 'Відбиток SHA-256';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      'Термін дії сертифіката закінчився. Оновіть або імпортуйте заміну.';

  @override
  String get tlsCopyPublicCertificate => 'Копіювати публічний сертифікат';

  @override
  String get tlsDownloadPublicCertificate => 'Завантажити публічний сертифікат';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      'Використовуйте цей сертифікат у браузерах та клієнтах потокового передавання.';

  @override
  String get tlsRenewCertificate => 'Оновити сертифікат';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      'Зберегти поточний приватний ключ та оновити дати дії сертифіката.';

  @override
  String get tlsImportCertificate => 'Імпортувати сертифікат';

  @override
  String get tlsUseACertificateIssuedForThisDevice =>
      'Використовуйте сертифікат, виданий для цього пристрою.';

  @override
  String get tlsReplaceCertificate => 'Замінити сертифікат';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      'Згенерувати новий приватний ключ та самопідписаний сертифікат.';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      'Згенерувати новий приватний ключ і сертифікат? Активні зашифровані з\'єднання буде закрито. Браузери можуть запропонувати прийняти новий сертифікат.';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      'Вставте ланцюжок сертифікатів PEM та його незашифрований приватний ключ. Вони перевіряються перед заміною поточного сертифіката.';

  @override
  String get tlsCertificateChainPEM => 'Ланцюжок сертифікатів (PEM)';

  @override
  String get tlsPrivateKeyPEM => 'Приватний ключ (PEM)';

  @override
  String get tlsThisFieldIsRequired => 'Це поле обов\'язкове.';

  @override
  String get tlsReplace => 'Замінити';

  @override
  String get tlsRenew => 'Оновити';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      'Увімкніть HTTPS перед віддаленим імпортом приватного ключа.';

  @override
  String get tlsCertificateOperationFailed =>
      'Помилка операції з сертифікатом.';

  @override
  String get tlsChangeConnectionProtocol => 'Змінити протокол з\'єднання';

  @override
  String get tlsConnectionProtocolHelp =>
      'Поточне віддалене з\'єднання буде закрито. Підключіться знову за вказаною нижче адресою. Можливо, доведеться увійти повторно.';

  @override
  String get tlsConfirm => 'Підтвердити';

  @override
  String get tlsCertificateManagement => 'Керування сертифікатами';

  @override
  String get tlsServerCertificateRequired =>
      'Використовуйте сертифікат сервера, а не сертифікат CA.';

  @override
  String get tlsServerAuthenticationRequired =>
      'Сертифікат не дозволяє автентифікацію сервера.';

  @override
  String get tlsKeyAlgorithmRequired =>
      'Використовуйте приватний ключ EC або RSA.';

  @override
  String get tlsKeyMismatch => 'Сертифікат і приватний ключ не збігаються.';

  @override
  String get tlsMaterialTooLarge => 'Сертифікат або ключ занадто великий.';

  @override
  String get tlsPemCertificatesRequired => 'Очікуються сертифікати PEM.';

  @override
  String get tlsCertificateMissing => 'Сертифікат не знайдено.';

  @override
  String get tlsUnencryptedKeyRequired =>
      'Використовуйте незашифрований приватний ключ PEM.';

  @override
  String get tlsHostnameRequired =>
      'Потрібно вказати ім\'я хоста або IP-адресу.';

  @override
  String get tlsIssuerRenewalRequired =>
      'Імпортуйте оновлений сертифікат від його видавця.';

  @override
  String get tlsStoredIdentityDamaged =>
      'Збережені дані ідентифікації TLS пошкоджено.';

  @override
  String get tlsExpiredCertificate =>
      'Термін дії сертифіката TLS закінчився. Оновіть або імпортуйте заміну.';

  @override
  String get deviceHelperPage => 'Додатковий помічник оновлення';

  @override
  String get deviceHelperStatus => 'Стан помічника';

  @override
  String get deviceHelperError => 'Не вдалося перевірити помічник оновлення.';

  @override
  String get deviceHelperUnneeded =>
      'Android тепер може встановлювати оновлення без сповіщень. Помічник не потрібен.';

  @override
  String get deviceHelperIntro =>
      'Цей пристрій зараз вимагає підтвердження на екрані для встановлення оновлень через Android. Додатковий помічник дозволяє Kiosk Satellite встановлювати оновлення без дотиків.';

  @override
  String get deviceHelperBusy => 'Встановлення оновлення.';

  @override
  String get deviceHelperReady =>
      'Готово. Оновлення встановлюються без підтвердження.';

  @override
  String get deviceHelperUnavailable =>
      'Недоступно. Запустіть помічник через ADB, щоб увімкнути оновлення без підтвердження.';

  @override
  String get deviceHelperLifetime =>
      'Помічник зберігає роботу після перезапусків застосунку та оновлень, але зупиняється після перезавантаження пристрою. Запустіть команду з компʼютера через ADB знову. Після цього компʼютер можна відключити.';

  @override
  String get deviceHelperStart => 'Запустити через ADB';

  @override
  String get deviceHelperGuide => 'Посібник із налаштування';

  @override
  String get deviceHelperGuideHelp =>
      'Прочитати інструкції та вимоги до помічника оновлень.';

  @override
  String get settingUpdateSourceTitle => 'Джерело оновлення';

  @override
  String get settingUpdateSourceDescription =>
      'Де застосунок шукає нові випуски.';

  @override
  String get settingUpdateSourceUrlTitle => 'URL репозиторію';

  @override
  String get settingUpdateSourceUrlDescription =>
      'Папка на вебсервері, доступна для кіоска, що містить releases.json та файли APK випусків.';

  @override
  String get deviceUpdatesPage => 'Оновлення';

  @override
  String get deviceUpdateGithub => 'Репозиторій GitHub';

  @override
  String get deviceUpdateCustom => 'Власний репозиторій';

  @override
  String get deviceUpdateGuide => 'Посібник із власного репозиторію';

  @override
  String get deviceUpdateGuideHelp =>
      'Як розмістити файл випусків та APK у власній мережі.';

  @override
  String get deviceInstallFile => 'Встановити з файлу';

  @override
  String get deviceInstallFileHelp =>
      'Завантажити APK Kiosk Satellite з компʼютера через віддалене адміністрування на цій же сторінці. Для кіоска, який не має доступу до GitHub чи власного репозиторію.';

  @override
  String get deviceInstallFileRemoteHelp =>
      'Завантажити APK Kiosk Satellite з цього компʼютера та встановити його. Для кіоска, який не має доступу до GitHub чи власного репозиторію.';

  @override
  String get deviceUploadedApk => 'Завантажений APK';

  @override
  String get deviceInstalling => 'Встановлення…';

  @override
  String get deviceDeviceNoAnswer => 'Пристрій не відповів.';

  @override
  String get deviceInstallFailed =>
      'Оновлення не вдалося. Перевірте журнал пристрою.';

  @override
  String get deviceConfirmTablet => 'Підтвердьте на екрані планшета';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return 'Версія $version (збірка $build, $size МБ) знаходиться на пристрої й очікує на встановлення.';
  }

  @override
  String deviceInstallVersion(String version) {
    return 'Встановити версію $version';
  }

  @override
  String deviceHttpError(String code) {
    return 'Пристрій повернув код HTTP $code.';
  }

  @override
  String get deviceUploadFailed => 'Завантаження не вдалося.';

  @override
  String get deviceInstallFleet => 'Встановити на парк пристроїв';

  @override
  String get deviceSendingFleet => 'Надсилання на пристрої…';

  @override
  String get deviceSameBuild => 'На кіоску вже встановлено цю збірку.';

  @override
  String get deviceInstallConfirmation =>
      'Встановлення потрібно підтвердити на екрані планшета, якщо не налаштовано тихе встановлення.';

  @override
  String get deviceSelfLast => 'Цей кіоск оновлюється останнім.';

  @override
  String get deviceUpdatingFleet => 'Оновлення парку пристроїв';

  @override
  String deviceUploading(String percent) {
    return 'Завантаження… $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return 'Завантажений APK: версія $version (збірка $build, $size МБ).';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'На кіоску встановлено $version (збірка $build).';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return 'Надсилання на $name… $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return 'Встановлення на $name…';
  }

  @override
  String deviceInstallingNames(String names) {
    return 'Встановлення на: $names.';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      'Введіть URL папки, наприклад http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      'Введіть лише URL папки без додаткових шляхів після нього. Приклад: http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy =>
      'Завантаження вже триває. Зачекайте на його завершення.';

  @override
  String get updateInstallBusy =>
      'Встановлення вже триває. Зачекайте на його завершення.';

  @override
  String get updateNoAvailable => 'Немає доступних оновлень.';

  @override
  String get updateNoUploaded => 'Немає очікуючих завантажених APK.';

  @override
  String get updateUploadEmpty => 'Завантаження було порожнім.';

  @override
  String get updateInvalidApk => 'Файл не є Android APK.';

  @override
  String get updateUploadedGone =>
      'Завантажений APK відсутній. Завантажте його знову.';

  @override
  String get updateShizukuInstallerFailed =>
      'Shizuku не вдалося встановити оновлення. Програму встановлення без підтвердження не відкрито.';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return 'Недостатньо вільного місця: розмір APK $size МБ, для встановлення потрібно приблизно $required МБ, але доступно лише $free МБ.';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return 'Завантаження було перервано після $size МБ: $error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return 'Завантаження завершилося передчасно: отримано $received з $expected МБ.';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return 'Цей APK належить до $package, а не до Kiosk Satellite ($expected).';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'APK версії $version (збірка $build) старіший за поточну $currentVersion (збірка $currentBuild). Повернення до старішої версії відхилено: Android також не дозволить це встановити.';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return 'Не вдалося завантажити (HTTP $status).';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return 'Завантаження зупинилося: дані не надходили протягом $seconds с.';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return 'Оновлення не вдалося: $error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return 'Встановлення не вдалося: $error';
  }

  @override
  String get updateAnotherPackage => 'інший пакет';

  @override
  String get settingUiLanguageTitle => 'Мова';

  @override
  String get settingUiLanguageDescription =>
      'Мова для Kiosk Satellite та віддаленого адміністрування. Home Assistant зберігає власну мову.';

  @override
  String get settingUiThemeTitle => 'Тема застосунку';

  @override
  String get settingUiThemeDescription =>
      'Світла чи темна для власних екранів застосунку: меню, налаштування, діалогові вікна. Варіант «Системна» відповідає налаштуванням Android.';

  @override
  String get settingUiScaleTitle => 'Масштаб інтерфейсу';

  @override
  String get settingUiScaleDescription =>
      'Розмір власних екранів застосунку: меню, налаштування, діалогові вікна. Для екранів із високою щільністю пікселів. Вебвміст зберігає свій розмір.';

  @override
  String get deviceUserInterface => 'Інтерфейс користувача';

  @override
  String get deviceThemeDark => 'Темна';

  @override
  String get deviceThemeLight => 'Світла';

  @override
  String get deviceThemeSystem => 'Системна';

  @override
  String get settingDlnaEnabledTitle => 'Увімкнути рендерер DLNA';

  @override
  String get settingDlnaEnabledDescription =>
      'Показувати зображення та відтворювати медіафайли, надіслані з Home Assistant або будь-якого застосунку DLNA. Пристрій з\'явиться як медіаплеєр із назвою пристрою.';

  @override
  String get settingDlnaAudioBackgroundTitle => 'Фонове відтворення аудіо';

  @override
  String get settingDlnaAudioBackgroundDescription =>
      'Надіслане аудіо відтворюється у фоні, не перекриваючи екран.';

  @override
  String get settingDlnaPortTitle => 'Порт сервера';

  @override
  String get settingDlnaPortDescription =>
      'Порт, на якому працює рендерер, заповнюється під час його запуску. Змініть його, щоб перенести рендерер, або очистьте, щоб дозволити вибрати його знову.';

  @override
  String get settingDlnaPortPlaceholder =>
      'Встановлюється під час запуску рендерера';

  @override
  String get settingEsphomeRealMacTitle =>
      'Використовувати справжню MAC-адресу Wi-Fi';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant пов\'язує цей кіоск із тим самим пристроєм, який уже відстежують ваші мережеві інтеграції. Зміна цього параметра створює новий пристрій ESPHome у Home Assistant.';

  @override
  String get settingEsphomeMacOverrideTitle => 'Підмінити MAC-адресу Wi-Fi';

  @override
  String get settingEsphomeMacOverrideDescription =>
      'Оскільки MAC-адресу не вдалося визначити, ви можете ввести власну у цьому полі. Зміна цього параметра створює новий пристрій ESPHome у Home Assistant.';

  @override
  String get esphomeAdvanced => 'Розширені налаштування';

  @override
  String get esphomeAdvancedHelp => 'Справжня або підмінена MAC-адреса Wi-Fi';

  @override
  String get esphomeMacInvalid => 'Введіть дійсну MAC-адресу.';

  @override
  String esphomeMacHardware(String mac) {
    return 'Повідомляється $mac.';
  }

  @override
  String esphomeMacManual(String mac) {
    return 'Повідомляється $mac, введена нижче.';
  }

  @override
  String get esphomeMacUnavailable =>
      'Android не надає апаратну адресу цього пристрою.';

  @override
  String get settingAnnouncementsEnabledTitle => 'Увімкнути оголошення';

  @override
  String get settingAnnouncementsEnabledDescription =>
      'Відтворювати оголошення, які Home Assistant надсилає дією announce.';

  @override
  String get settingAnnouncementsTtsEngineTitle => 'Рушій синтезу мовлення';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'Сутність синтезу мовлення Home Assistant, яка озвучує оголошення.';

  @override
  String get esphomeTtsFirst => 'Перший доступний';

  @override
  String get settingAnnouncementsChimeTitle =>
      'Звуковий сигнал перед оголошенням';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Відтворювати звуковий сигнал перед оголошенням.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Звук сигналу';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Відтворюється з гучністю сповіщень.';

  @override
  String get esphomeAnnouncements => 'Оголошення';

  @override
  String get esphomeAnnouncementsHelp =>
      'Голосові оголошення від Home Assistant';

  @override
  String get esphomeChime => 'Звуковий сигнал';

  @override
  String get esphomeTtsUnavailable => 'Не вдалося зв\'язатися з Home Assistant';

  @override
  String get settingBtproxyEnabledTitle => 'Увімкнути проксі Bluetooth';

  @override
  String get settingBtproxyEnabledDescription =>
      'Транслювати сусідні пристрої Bluetooth до Home Assistant.';

  @override
  String get settingBtproxyScanDutyTitle => 'Інтенсивність сканування';

  @override
  String get settingBtproxyScanDutyDescription =>
      'Частка часу, протягом якої радіомодуль прослуховує ефір. Менше значення знижує навантаження на процесор; пристрої, які рідко передають сигнали, з\'являтимуться довше.';

  @override
  String get settingBtproxyConnectionsTitle =>
      'Дозволити підключення пристроїв';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant може підключатися до пристроїв Bluetooth через цей проксі.';

  @override
  String get settingBtproxyMacLookupTitle =>
      'Шукати виробників пристроїв в інтернеті';

  @override
  String get settingBtproxyMacLookupDescription =>
      'Визначає назви невідомих сусідніх пристроїв за префіксом апаратної адреси через api.macvendors.com. Надсилається лише 3-байтний префікс виробника, один раз для кожного виробника; нічого іншого не залишає пристрій.';

  @override
  String get settingBtproxyNearbySortTitle => 'Сортувати за';

  @override
  String get settingBtproxyNearbySortDescription =>
      'Порядок списку сусідніх пристроїв нижче.';

  @override
  String get settingBtproxyMinConnectRssiTitle =>
      'Мінімальний рівень сигналу для підключення';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      'Відхиляти підключення пристроїв із рівнем сигналу слабшим за цей, щоб ближчий проксі прийняв їх замість цього.';

  @override
  String get esphomeOptionContinuous => 'Постійне';

  @override
  String get esphomeOptionBalanced => 'Збалансоване';

  @override
  String get esphomeOptionLowPower => 'Енергоощадне';

  @override
  String get esphomeOptionLastSeen => 'За часом останнього виявлення';

  @override
  String get esphomeOptionName => 'За назвою';

  @override
  String get esphomeOptionMacAddress => 'За MAC-адресою';

  @override
  String get esphomeOptionSignalStrength => 'За силою сигналу';

  @override
  String get esphomeOptionNoLimit => 'Без обмежень';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm (в одній кімнаті)';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm (на межі дії)';

  @override
  String get esphomeBluetooth => 'Проксі Bluetooth';

  @override
  String get esphomeBluetoothHelp =>
      'Трансляція сусідніх пристроїв Bluetooth до Home Assistant';

  @override
  String get esphomeBluetoothOff =>
      'Bluetooth вимкнено. Увімкніть його, щоб використовувати проксі.';

  @override
  String get esphomeBluetoothUnsupported =>
      'Недоступно на цьому пристрої: відсутній модуль Bluetooth.';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      'Недоступно на цьому пристрої: у збірці Android відсутня підтримка Bluetooth LE.';

  @override
  String get esphomeIdentityBthome => 'Датчик BTHome';

  @override
  String get esphomeIdentityXiaomi => 'Датчик Xiaomi';

  @override
  String get esphomeIdentityQingping => 'Датчик Qingping';

  @override
  String get esphomeIdentityGoogleNest => 'Пристрій Google/Nest';

  @override
  String get esphomeIdentityEddystone => 'Маячок Eddystone';

  @override
  String get esphomeIdentityGoogleFastPair => 'Пристрій Google Fast Pair';

  @override
  String get esphomeIdentityAppleFindMy => 'Пристрій Apple Find My';

  @override
  String get esphomeIdentityExposure => 'Сповіщення про контакт (телефон)';

  @override
  String get esphomeIdentityAugustYale => 'Замок August/Yale';

  @override
  String get esphomeIdentityAmazon => 'Пристрій Amazon';

  @override
  String get esphomeIdentityTile => 'Трекер Tile';

  @override
  String get esphomeIdentityInput => 'Пристрій введення (пульт/клавіатура)';

  @override
  String get esphomeIdentityHeartRate => 'Датчик серцевого ритму';

  @override
  String get esphomeIdentityEnvironmental => 'Датчик навколишнього середовища';

  @override
  String get esphomeIdentityApple => 'Пристрій Apple';

  @override
  String get esphomeIdentityWindows => 'ПК з Windows';

  @override
  String get esphomeIdentitySamsung => 'Пристрій Samsung';

  @override
  String get esphomeIdentityGoogle => 'Пристрій Google';

  @override
  String get esphomeIdentityUnknown => 'Невідомий пристрій';

  @override
  String esphomeIdentityVendor(String vendor) {
    return 'Пристрій $vendor';
  }

  @override
  String get esphomeNearby => 'Сусідні пристрої';

  @override
  String get esphomeNearbySearch =>
      'Пристрої Bluetooth, які фіксує цей кіоск, із відомими назвами.';

  @override
  String get esphomeNearbyEmpty => 'Поки нічого не виявлено.';

  @override
  String get esphomeNearbyWaiting =>
      'Поки нічого не виявлено. Пристрої з\'являться тут, коли проксі розпочне сканування.';

  @override
  String get esphomeRotating => '(змінна адреса)';

  @override
  String esphomeNearbyCount(String count, String total) {
    return 'Показано перші $count з $total.';
  }

  @override
  String esphomeSlots(String count) {
    return 'Через цей проксі можна одночасно підключити до $count пристроїв. Home Assistant спрямовує інші пристрої через інші проксі.';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return '$count с тому';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return '$count хв тому';
  }

  @override
  String esphomeHoursAgo(String count) {
    return '$count год тому';
  }

  @override
  String get settingLocationEnabledTitle => 'Передавати місцезнаходження';

  @override
  String get settingLocationEnabledDescription =>
      'Зчитувати GPS-координати та передавати їх до Home Assistant як датчики широти, довготи, точності, висоти й швидкості. Увімкнення або вимкнення перереєстровує пристрій ESPHome.';

  @override
  String get settingLocationIntervalTitle => 'Інтервал оновлення';

  @override
  String get settingLocationIntervalDescription =>
      'Секунди між зчитуваннями положення.';

  @override
  String get esphomeGps => 'Датчик GPS';

  @override
  String get esphomeGpsHelp => 'Передача даних датчика GPS до Home Assistant';

  @override
  String get esphomeLocationOff => 'Вимкнено.';

  @override
  String get esphomeLocationWaiting =>
      'Очікування першого визначення координат. Холодний старт під відкритим небом може зайняти кілька хвилин.';

  @override
  String get esphomeCoordinates => 'Останні координати';

  @override
  String get esphomeLocationDenied => 'Дозвіл на доступ до геоданих не надано.';

  @override
  String get esphomeLocationAbsent => 'GPS-приймач відсутній.';

  @override
  String esphomeLocationError(String error) {
    return 'GPS недоступний: $error';
  }

  @override
  String get esphomeLocationUnsupported =>
      'Недоступно на цьому пристрої: відсутній GPS-приймач.';

  @override
  String get settingNotificationsTransparencyTitle => 'Прозорість';

  @override
  String get settingNotificationsTransparencyDescription =>
      'Дозволяє екрану позаду просвічувати крізь картки сповіщень. Текст та іконки залишаються непрозорими.';

  @override
  String get settingNotificationsBlurTitle => 'Розмиття фону';

  @override
  String get settingNotificationsBlurDescription =>
      'Розмиває те, що просвічує крізь прозору картку сповіщення. Примітка: розмиття не можна застосувати над панеллю керування Home Assistant.';

  @override
  String get settingNotificationsChimeFileTitle => 'Звук сповіщення';

  @override
  String get settingNotificationsChimeFileDescription =>
      'Звукові файли зчитуються з Android/data/me.jxl.kiosk_satellite/files/sounds на пристрої, також доступні через файловий менеджер.';

  @override
  String get settingNotificationsVolumeTitle => 'Гучність сповіщень';

  @override
  String get settingNotificationsVolumeDescription =>
      'Гучність відтворення звуку сповіщень окремо від гучності медіа та асистента.';

  @override
  String get esphomeNotifications => 'Сповіщення';

  @override
  String get esphomeNotificationsHelp =>
      'Прозорість, розмиття, звук сповіщення, тестове сповіщення';

  @override
  String get esphomeAppearance => 'Зовнішній вигляд';

  @override
  String get esphomeSound => 'Звук';

  @override
  String get esphomeNotificationTest => 'Тестове сповіщення';

  @override
  String esphomeNotificationHelp(String action) {
    return 'Сповіщення надсилаються з Home Assistant дією $action. Тест показує одне поверх панелі керування.';
  }

  @override
  String get esphomeNotificationBody =>
      'Ось так виглядає і звучить сповіщення від Home Assistant.';

  @override
  String get esphomeNotificationSearch =>
      'Дія Home Assistant для надсилання сповіщень і кнопка для тестового показу.';

  @override
  String get esphomeLocation => 'Місцезнаходження';

  @override
  String get esphomeLocationSearch =>
      'Дозвіл на доступ до місцезнаходження, необхідний датчикам положення.';

  @override
  String get esphomeBluetoothSearch =>
      'Дозвіл на пошук пристроїв поблизу, необхідний проксі Bluetooth для сканування.';

  @override
  String get esphomeLocationMissing =>
      'Без цього неможливо зчитати GPS-приймач, і датчики положення залишатимуться в невідомому стані.';

  @override
  String get esphomeLocationServicesOff =>
      'Геолокацію вимкнено в налаштуваннях пристрою, тому приймач не передає даних.';

  @override
  String get esphomeLocationGranted =>
      'Датчики місцезнаходження можуть зчитувати дані GPS-приймача.';

  @override
  String get esphomeBluetoothGranted =>
      'Проксі може сканувати сусідні пристрої Bluetooth.';

  @override
  String get esphomeBluetoothMissing =>
      'Без цього проксі не може сканувати пристрої.';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android надає результати сканування Bluetooth, включно з маячками, лише якщо надано дозвіл на доступ до місцезнаходження. Проксі ніколи не зчитує координати пристрою.';

  @override
  String get esphomeBluetoothLocationOff =>
      'Геолокацію вимкнено в налаштуваннях пристрою, тому сканування Bluetooth нічого не знаходить.';

  @override
  String get esphomeBluetoothBeacons =>
      'Сканування Bluetooth може виявляти маячки.';

  @override
  String get esphomeSent => 'Надіслано';

  @override
  String get esphomeNotsaved => 'Не збережено';

  @override
  String get settingEsphomeEnabledTitle => 'Увімкнути ESPHome';

  @override
  String get settingEsphomeEnabledDescription =>
      'Надавати цей кіоск для Home Assistant як пристрій ESPHome: його датчики та елементи керування як нативні сутності. Виявляється автоматично.';

  @override
  String get settingEsphomeEntitiesTitle => 'Експортувати сутності кіоска';

  @override
  String get settingEsphomeEntitiesDescription =>
      'Надавати датчики та елементи керування цього пристрою як сутності ESPHome.';

  @override
  String get settingEsphomeExcludedEntitiesTitle => 'Виключені сутності';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      'Виберіть сутності, які слід виключити з Home Assistant. Усі інші доступні сутності будуть надані. Збереження перепідключає ESPHome.';

  @override
  String get settingEsphomeNodeNameTitle => 'Назва вузла';

  @override
  String get settingEsphomeNodeNameDescription =>
      'Називає цей кіоск у мережі, а Home Assistant формує назви дій на її основі. Перейменування перейменовує ці дії.';

  @override
  String get settingEsphomeNodeNamePlaceholder =>
      'Встановлюється під час першого запуску';

  @override
  String get settingBtproxyKeyTitle => 'Ключ шифрування';

  @override
  String get settingBtproxyKeyDescription =>
      'Вставте цей ключ у Home Assistant, коли він запитає ключ шифрування. Генерується автоматично під час першого запуску.';

  @override
  String get settingBtproxyKeyPlaceholder =>
      'Генерується під час першого запуску';

  @override
  String get settingBtproxyPortTitle => 'Порт API';

  @override
  String get settingBtproxyPortDescription =>
      'Порт, до якого підключається Home Assistant. Залиште порожнім для стандарту ESPHome: 6053.';

  @override
  String esphomeStartFailed(String error) {
    return 'Не вдалося запустити сервер ESPHome: $error';
  }

  @override
  String get esphomeExcludedInvalid =>
      'Виберіть список ідентифікаторів сутностей.';

  @override
  String settingsMadeBy(String heart, String author) {
    return 'Створено з $heart автором $author';
  }

  @override
  String get settingsBuyCoffee => 'Купити мені каву';

  @override
  String get settingClapStrictnessTitle => 'Розпізнавання оплесків';

  @override
  String get settingClapStrictnessDescription =>
      'Суворий режим вимагає гучніших і рівномірніших оплесків; спробуйте його, якщо побутовий шум викликає хибні спрацьовування.';

  @override
  String get gestureStrictnessStandard => 'Стандартне';

  @override
  String get gestureStrictnessStrict => 'Суворе';

  @override
  String get gestureOff => 'Жести вимкнено';

  @override
  String get gestureOffHelp =>
      'Параметр «Вимкнути жести» увімкнено в налаштуваннях режиму кіоска.';

  @override
  String get gestureEmpty => 'Жодних жестів не налаштовано';

  @override
  String get gestureEmptyHelp =>
      'Жест запускає свою дію без жодних видимих елементів керування.';

  @override
  String get gestureDeleteTooltip => 'Видалити жест';

  @override
  String get gestureDeleteTitle => 'Видалити жест?';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return 'Вилучити цей жест? Тригер: $trigger. Дія: $action.';
  }

  @override
  String get gestureAdd => 'Додати жест';

  @override
  String get gestureAddHelp => 'Виберіть жест і дію, яку він запускає.';

  @override
  String get gestureTouchHelp =>
      'Жести відстежуються, а не блокуються: дотики також доходять до панелі керування, тому кути та форми з кількох пальців захищають від випадкового натискання там.';

  @override
  String get gestureClapper => 'Хлопавка';

  @override
  String get gestureReadFailed => 'Не вдалося прочитати налаштування.';

  @override
  String get gestureHandGestures => 'Жести руками';

  @override
  String get settingHandGestureHoldSecondsTitle => 'Тривалість утримання';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      'Утримуйте той самий жест пальцями протягом цього часу перед виконанням дії. Збільште для зменшення випадкових спрацьовувань.';

  @override
  String get gestureHoldInstant => 'Миттєво';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String get settingHaHoldModeTitle => 'Режим утримання';

  @override
  String get settingHaHoldModeDescription =>
      'Залишає поточний вигляд на екрані: заставка, ротація виглядів панелі керування та таймер повернення на головний екран призупиняються, доки режим не вимкнено.';

  @override
  String get settingHaHoldReleaseMinutesTitle =>
      'Автоматично завершувати утримання через';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      'Вимикає режим утримання самостійно через заданий час. Встановіть 0, щоб утримувати до ручного вимкнення.';

  @override
  String get settingHaHoldMenuTitle => 'Показувати в меню кіоска';

  @override
  String get settingHaHoldMenuDescription =>
      'Додає пункт меню, що вмикає та вимикає режим утримання.';

  @override
  String get haHoldHint =>
      'Закріпити поточний вигляд, автоматичне звільнення, пункт меню';

  @override
  String get haNever => 'Ніколи';

  @override
  String haMinutes(String minutes) {
    return '$minutes хв';
  }

  @override
  String haHours(String hours) {
    return '$hours год';
  }

  @override
  String haHoursMinutes(String hours, String minutes) {
    return '$hours год $minutes хв';
  }

  @override
  String get settingDisableSuspendTitle =>
      'Залишатися підключеним у фоновому режимі';

  @override
  String get settingDisableSuspendDescription =>
      'Вимикає налаштування Home Assistant \"Призупиняти фонові з\'єднання\", яке інакше розірве з\'єднання через кілька хвилин після вимкнення екрана.';

  @override
  String get settingFreezeOnScreensaverTitle =>
      'Призупиняти панель керування під час роботи заставки';

  @override
  String get settingFreezeOnScreensaverDescription =>
      'Припиняє відмальовування панелі керування, доки заставка її перекриває, зменшуючи використання CPU та GPU. З\'єднання залишається активним. Не застосовується до заставки «Затемнення».';

  @override
  String get settingWsFilterTitle => 'Фільтрувати оновлення панелі керування';

  @override
  String get settingWsFilterDescription =>
      'Обробляти лише оновлення сутностей на поточному виді, зменшуючи затримки на малопотужних планшетах. Види, які неможливо визначити, залишаються без фільтрації.';

  @override
  String get settingPauseDashboardCamerasTitle =>
      'Призупиняти потоки камер панелі HA під час роботи заставки';

  @override
  String get settingPauseDashboardCamerasDescription =>
      'Призупиняє підтримувані заглушені потоки камер на панелі керування Home Assistant, доки заставка її перекриває. Потоки відновлюються після закриття. Не впливає на камеру пристрою чи функцію «Відеопотоки камер».';

  @override
  String get haOptimizations => 'Оптимізації';

  @override
  String get haOptimizationsHint =>
      'Фонове з\'єднання, призупинення панелі та камер, фільтр оновлень';

  @override
  String get haScanUnavailable =>
      'Деталі сканування недоступні для поточного виду.';

  @override
  String get haScanDetails => 'Деталі сканування панелі керування';

  @override
  String haWatchedTitle(String count) {
    return 'Відстежувані сутності ($count)';
  }

  @override
  String get haWatched => 'Відстежувані сутності';

  @override
  String get haEntityListUnavailable => 'Список сутностей наразі недоступний.';

  @override
  String haWatching(String count) {
    return 'Відстеження $count сутностей на цьому виді.';
  }

  @override
  String get haNoUpdates => 'Немає оновлень за останню хвилину.';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return 'Відфільтровано $percent% оновлень за останню хвилину ($dropped з $total).';
  }

  @override
  String get haRawUpdates =>
      'Щось на цій сторінці все одно отримує кожне оновлення сутності, тому фільтрація тут менш ефективна.';

  @override
  String get haAllStates =>
      'Цей вид зчитує всі стани сутностей, тому його оновлення не фільтруються.';

  @override
  String get haUnknownEntities =>
      'Сутності цього виду неможливо визначити, тому його оновлення не фільтруються.';

  @override
  String get haWaiting => 'Очікування завантаження панелі керування…';

  @override
  String get haShowScan => 'Показати деталі сканування.';

  @override
  String haThreshold(String count) {
    return 'Цей вид використовує $count сутностей, що перевищує поріг фільтрації. Фільтрацію вимкнено.';
  }

  @override
  String get settingHaReturnHomeEnabledTitle =>
      'Повернення на головний вигляд панелі керування';

  @override
  String get settingHaReturnHomeEnabledDescription =>
      'Повертатися до панелі керування, налаштованої вище, після періоду бездіяльності.';

  @override
  String get settingHaReturnHomeSecondsTitle => 'Повернення через (секунди)';

  @override
  String get settingHaReturnHomeSecondsDescription =>
      'Період бездіяльності перед поверненням кіоска.';

  @override
  String get haReturnHint => 'Повертатися на головний вигляд при бездіяльності';

  @override
  String get haReturnDisabled =>
      'Вимкнено, доки увімкнено Ротацію видів панелі керування.';

  @override
  String get haReturnNoPath =>
      'У налаштованій панелі керування немає шляху виду для повернення.';

  @override
  String haReturnPath(String path) {
    return 'Повертається до \"$path\" після завершення тайм-ауту.';
  }

  @override
  String get settingHaRotationEnabledTitle =>
      'Увімкнути ротацію видів панелі керування';

  @override
  String get settingHaRotationEnabledDescription =>
      'Циклічно перемикати вибрані види панелі керування у нескінченному циклі, показуючи кожен протягом обраної кількості секунд.';

  @override
  String get settingHaRotationSecondsTitle => 'Секунд на вид';

  @override
  String get settingHaRotationSecondsDescription =>
      'Як довго кожен вид залишається на екрані.';

  @override
  String get settingHaRotationPauseSecondsTitle =>
      'Призупиняти ротацію при взаємодії (секунди)';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      'Дотик до екрана призупиняє ротацію на цей час, і кожен дотик перезапускає відлік. Голосові взаємодії призупиняють ротацію до їх завершення. 0 продовжує ротацію попри дотики.';

  @override
  String get settingHaRotationCrossfadeTitle => 'Плавний перехід між видами';

  @override
  String get settingHaRotationCrossfadeDescription =>
      'Плавно згасати до фону та з\'являтися у наступному виді замість миттєвого перемикання. Перехід на іншу панель керування чи зовнішню сторінку все одно відбувається миттєво.';

  @override
  String get settingHaRotationFadeSecondsTitle =>
      'Тривалість переходу (секунди)';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      'Сумарний час згасання та появи. Завантаження наступного виду може додати часу, особливо під час першого відвідування.';

  @override
  String get haRotation => 'Ротація видів панелі керування';

  @override
  String get haRotationHint =>
      'Циклічне перемикання видів, час показу, плавний перехід';

  @override
  String get haDefaultView => 'Вид за замовчуванням';

  @override
  String get haExternalPages => 'Зовнішні сторінки';

  @override
  String get haFadeError => 'Виберіть тривалість переходу від 0,2 до 5 секунд.';

  @override
  String get haPauseRemoteHelp =>
      'Дотик призупиняє ротацію на цей час; кожен дотик перезапускає її. Голосові взаємодії завжди призупиняють до завершення. 0 продовжує ротацію.';

  @override
  String get settingHaUrlTitle => 'Базова URL-адреса Home Assistant';

  @override
  String get settingHaUrlDescription =>
      'наприклад, https://homeassistant.local:8123, без шляху до панелі керування.';

  @override
  String get settingHaTokenTitle => 'Довгостроковий токен доступу';

  @override
  String get settingHaTokenDescription => 'Створюється у профілі HA → Безпека.';

  @override
  String get settingHaAutoLoginTitle => 'Входити автоматично';

  @override
  String get settingHaAutoLoginDescription =>
      'Входити на панель керування за допомогою токена доступу вище замість показу сторінки входу Home Assistant.';

  @override
  String get haValidate => 'Перевірити';

  @override
  String get haValidateConnection => 'Перевірити з\'єднання';

  @override
  String get haChecking => 'Перевірка…';

  @override
  String get haConnected => 'Підключено';

  @override
  String get haConnectedRemote => 'Підключено.';

  @override
  String get haNotValidated =>
      'Ще не перевірено. Налаштування нижче розблокуються після успішної перевірки з\'єднання.';

  @override
  String get haConnectFailed => 'Не вдалося підключитися.';

  @override
  String get haNotConfigured =>
      'URL-адресу та токен Home Assistant не налаштовано';

  @override
  String get haInvalidToken => 'недійсний токен';

  @override
  String haUnreachable(String error) {
    return 'Не вдалося з\'єднатися з Home Assistant: $error';
  }

  @override
  String get haProxy => 'Проксі безпечного контексту';

  @override
  String get haProxyHelp =>
      'Направляє звичайний http Home Assistant через вбудований проксі, щоб браузер розблокував мікрофон та інші функції, доступні лише для https. Тільки для http-адрес.';

  @override
  String get haProxyRemoteHelp =>
      'Направляє звичайний http Home Assistant через проксі всередині застосунку, щоб браузер розблокував мікрофон та інші функції, доступні лише для https. Доступно лише для http-адрес.';

  @override
  String get haProxyNotice =>
      'Ця URL-адреса Home Assistant використовує звичайний http, а браузери блокують мікрофон та інші функції на http-сторінках. Kiosk Satellite спрямує панель керування через безпечний проксі всередині застосунку, щоб усе працювало. Можливо, вам знадобиться повторно увійти в Home Assistant.';

  @override
  String get haProxyRemoteNotice =>
      'Ця URL-адреса Home Assistant використовує звичайний http, а браузери блокують мікрофон та інші функції на http-сторінках. Kiosk Satellite спрямує панель керування через безпечний проксі всередині застосунку, щоб усе працювало. Можливо, вам знадобиться повторно увійти в Home Assistant на планшеті.';

  @override
  String get haDashboard => 'Панель керування';

  @override
  String get haChooseView => 'Виберіть вид';

  @override
  String get haLoadingDashboards => 'Завантаження панелей керування…';

  @override
  String get haListFailed => 'Не вдалося отримати список панелей керування';

  @override
  String get haRetryHint => 'Торкніться, щоб повторити спробу.';

  @override
  String get haChangeView => 'Змінити вид';

  @override
  String get haNoViews => 'Немає вкладених видів';

  @override
  String get haNoViewsHelp =>
      'У цій панелі керування немає вкладених видів для вибору.';

  @override
  String get haNoDashboards => 'Панелей керування не знайдено';

  @override
  String get settingHaThemeTitle => 'Тема';

  @override
  String get settingHaThemeDescription =>
      'Світла чи темна для панелі керування Home Assistant, також встановлюється через сутність теми в Home Assistant. Авто слідує налаштуванням нижче.';

  @override
  String get settingThemeMatchAppTitle =>
      'Синхронізувати теми Home Assistant з Kiosk Satellite';

  @override
  String get settingThemeMatchAppDescription =>
      'Автоматично узгоджувати вашу тему Home Assistant з інтерфейсом Kiosk Satellite.';

  @override
  String get settingThemeAutoTitle => 'Узгоджувати тему з часом доби';

  @override
  String get settingThemeAutoDescription =>
      'Перемикати Home Assistant між світлою та темною темою за розкладом. Зберігає обрану тему, змінюючи лише її світлий/темний варіант.';

  @override
  String get settingThemeDarkAtTitle => 'Темна тема о';

  @override
  String get settingThemeDarkAtDescription =>
      'Локальний час для перемикання на темну тему.';

  @override
  String get settingThemeLightAtTitle => 'Світла тема о';

  @override
  String get settingThemeLightAtDescription =>
      'Локальний час для повернення до світлої теми.';

  @override
  String get settingThemeAutoAppTitle => 'Також перемикати тему застосунку';

  @override
  String get settingThemeAutoAppDescription =>
      'Перемикати власну тему Kiosk Satellite (меню, налаштування) разом із запланованою зміною теми Home Assistant.';

  @override
  String get haThemeHint =>
      'Узгодити з застосунком або перемикати темну і світлу за розкладом';

  @override
  String get haThemeAuto => 'Авто';

  @override
  String get settingHaKioskModeTitle => 'Режим кіоска HA';

  @override
  String get settingHaKioskModeDescription =>
      'Приховати заголовок та бічну панель Home Assistant. Застосовується негайно.';

  @override
  String get settingHaKioskHideHeaderTitle => 'Приховати заголовок';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'Приховувати панель інструментів панелі керування та вкладки видів, доки увімкнено режим кіоска HA. Залиште вимкненим, якщо ви перемикаєте види із заголовка.';

  @override
  String get settingHaKioskHideSidebarTitle => 'Приховати бічну панель';

  @override
  String get settingHaKioskHideSidebarDescription =>
      'Приховувати навігаційну бічну панель, доки увімкнено режим кіоска HA.';

  @override
  String get settingHaKioskMenuTitle => 'Показувати в меню кіоска';

  @override
  String get settingHaKioskMenuDescription =>
      'Додати до меню кіоска пункт HA Kiosk Mode, що вмикає та вимикає його.';

  @override
  String get settingHaDashboardCarouselTitle =>
      'Увімкнути карусель панелі керування';

  @override
  String get settingHaDashboardCarouselDescription =>
      'Проведіть пальцем ліворуч або праворуч по панелі керування, щоб перемикатися між її видами. Проведення пальцем по повзунках, картах і прокручуваних картках не зачіпається.';

  @override
  String get settingHaCarouselOverCardsTitle =>
      'Перехоплювати жести проведення над картками';

  @override
  String get settingHaCarouselOverCardsDescription =>
      'Перемикати види, навіть якщо проведення пальцем починається на картці, яка реагує на такі жести. Повзунки все одно працюють нормально.';

  @override
  String get settingHaHapticsTitle => 'Увімкнути тактильний відгук';

  @override
  String get settingHaHapticsDescription =>
      'Вібрувати при використанні кнопок, перемикачів, карток, повзунків та регуляторів термостата. Потребує вібромотора.';

  @override
  String get settingHaHapticsStrengthTitle => 'Сила вібрації';

  @override
  String get settingHaHapticsStrengthDescription =>
      'Наскільки відчутною є вібрація.';

  @override
  String get settingHaTapSoundTitle => 'Відтворювати звуки дотику';

  @override
  String get settingHaTapSoundDescription =>
      'Відтворювати стандартний звук дотику при використанні кнопок, перемикачів, карток, повзунків та регуляторів термостата.';

  @override
  String get settingHaTapSoundVolumeTitle => 'Гучність звуку дотику';

  @override
  String get settingHaTapSoundVolumeDescription =>
      'Наскільки гучно відтворюється звук дотику.';

  @override
  String get haUserInterface => 'Інтерфейс користувача';

  @override
  String get haInterfaceHint =>
      'Режим кіоска, карусель панелі керування, тактильний відгук, звуки дотику';

  @override
  String get haHaptics => 'Тактильний відгук';

  @override
  String get haVibrationLight => 'Легка';

  @override
  String get haVibrationMedium => 'Середня';

  @override
  String get haVibrationStrong => 'Сильна';

  @override
  String get settingHomeLauncherEnabledTitle => 'Працювати як головний екран';

  @override
  String get settingHomeLauncherEnabledDescription =>
      'Зареєструвати Kiosk Satellite як головний екран пристрою: кіоск запускається під час завантаження системи, а кожне натискання «Додому» повертає до нього. Автоматично вимикається та відновлює попередній лаунчер у разі повторних збоїв запуску застосунку.';

  @override
  String get settingHomeKeepPinningTitle => 'Зберігати закріплення екрана';

  @override
  String get settingHomeKeepPinningDescription =>
      'Закріплювати екран навіть тоді, коли Kiosk Satellite є головним екраном. Блокує екран останніх застосунків та кнопку «Назад» на рівні системи, але повертає діалогове вікно підтвердження закріплення на пристроях без прав власника пристрою.';

  @override
  String get kioskHomeScreen => 'Головний екран';

  @override
  String get kioskCheckingDevice => 'Перевірка пристрою...';

  @override
  String get kioskFireOs => 'Fire OS не дозволяє замінювати свій лаунчер.';

  @override
  String get kioskUnsupported =>
      'Цей пристрій не дозволяє змінювати головний екран.';

  @override
  String get kioskRecovered =>
      'Вимкнено автоматично після повторних невдалих запусків; попередній лаунчер відновлено. Увімкніть перемикач знову для повторної спроби.';

  @override
  String get kioskHeld =>
      'Kiosk Satellite встановлено як головний екран. Кіоск запускається під час завантаження системи, і кожне натискання «Додому» повертає до нього.';

  @override
  String get kioskDisabled =>
      'Не є головним екраном. Увімкніть параметр «Працювати як головний екран» вище.';

  @override
  String get kioskWaiting =>
      'Ще не є поточним головним екраном: пристрій очікує на підтвердження.';

  @override
  String get kioskOpenHomeSettings => 'Відкрити налаштування головного екрана';

  @override
  String get kioskSetDefault => 'Встановити за замовчуванням';

  @override
  String get kioskActive => 'Активно';

  @override
  String get kioskNotHome => 'Не є головним екраном.';

  @override
  String get kioskWaitingRemote =>
      'Очікування підтвердження на пристрої: відкрийте системний діалог або налаштування головного екрана на ньому.';

  @override
  String get kioskSetDevice => 'Встановити на пристрої';

  @override
  String get settingIntercomAnswerModeTitle => 'Режим відповіді';

  @override
  String get settingIntercomAnswerModeDescription =>
      '«Дзвінок» запитує на екрані. «Відповідати автоматично» відкриває виклик після звукового сигналу.';

  @override
  String get settingIntercomRingSecondsTitle => 'Тривалість дзвінка';

  @override
  String get settingIntercomRingSecondsDescription =>
      'Скільки часу триває виклик, перш ніж він вважатиметься пропущеним.';

  @override
  String get settingIntercomRingSoundTitle => 'Звук дзвінка';

  @override
  String get settingIntercomRingSoundDescription =>
      'Відтворюється з гучністю сповіщень.';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => 'Приймати оголошення';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      'Відтворювати оголошення для всіх з інших кіосків.';

  @override
  String get intercomOptionAnswerRing => 'Дзвінок';

  @override
  String get intercomOptionAnswerAuto => 'Відповідати автоматично';

  @override
  String get intercomOptionAnswerDnd => 'Не турбувати';

  @override
  String get intercomOptionAnswer15 => '15 секунд';

  @override
  String get intercomOptionAnswer30 => '30 секунд';

  @override
  String get intercomOptionAnswer45 => '45 секунд';

  @override
  String get intercomOptionAnswer60 => '60 секунд';

  @override
  String get intercomAnswerSection => 'Відповідь';

  @override
  String get settingIntercomEnabledTitle => 'Увімкнути інтерком';

  @override
  String get settingIntercomEnabledDescription =>
      'Викликати інші кіоски в цій мережі та приймати їхні дзвінки.';

  @override
  String get settingIntercomKeyTitle => 'Ключ інтеркому';

  @override
  String get settingIntercomKeyDescription =>
      'Кіоски з однаковим ключем можуть викликати один одного. Fleet Management може синхронізувати його.';

  @override
  String get settingIntercomKeyPlaceholder =>
      'Створюється під час увімкнення інтеркому';

  @override
  String get settingIntercomMenuTitle => 'Показувати в меню кіоска';

  @override
  String get settingIntercomMenuDescription =>
      'Додати пункт «Інтерком» до меню кіоска.';

  @override
  String get intercomNeedsAdmin =>
      'Інтеркому потрібне віддалене адміністрування';

  @override
  String get intercomAdminHelp =>
      'Кіоски знаходять і зв\'язуються один з одним через нього. Увімкніть «Віддалене керування» та «Знаходити інші кіоски» в розділі «Пристрій», а потім поверніться сюди.';

  @override
  String get intercomChangeKey => 'Змінити ключ';

  @override
  String get intercomChangeKeyHelp =>
      'Вставте ключ з іншого кіоска або створіть новий.';

  @override
  String get intercomChange => 'Змінити';

  @override
  String get intercomKeyWarning =>
      'Кіоски з цим ключем можуть викликати один одного. Новий ключ від\'єднає цей кіоск від інших, доки вони також його не отримають.';

  @override
  String get intercomRegenerate => 'Згенерувати заново';

  @override
  String get intercomKeyChanged => 'Ключ змінено';

  @override
  String get intercomNotSet => 'Не встановлено';

  @override
  String get intercomOpen => 'Відкрити';

  @override
  String get settingIntercomTlsTitle => 'Шифрувати зв\'язок';

  @override
  String get settingIntercomTlsDescription =>
      'Використовувати TLS для шифрування викликів інтеркому між кіосками. Це має бути увімкнено на всіх кіосках у виклику.';

  @override
  String get intercomKiosks => 'Кіоски';

  @override
  String get intercomRosterHelp =>
      'Виявлені кіоски та збережені учасники групи. Кіоск готовий, коли він доступний з увімкненим інтеркомом, тим самим ключем і однаковими налаштуваннями шифрування.';

  @override
  String get intercomNoOther => 'Інших кіосків не знайдено';

  @override
  String get intercomRosterDeviceHelp =>
      'Тут з\'являються кіоски з увімкненими функціями «Віддалене керування» та «Знаходити інші кіоски».';

  @override
  String get intercomNoneHeard => 'Кіосків не знайдено';

  @override
  String get intercomRosterRemoteHelp =>
      'Кіоски з\'являються через виявлення в мережі або збережене членство у групі. Повинні бути увімкнені «Віддалене керування» та «Знаходити інші кіоски».';

  @override
  String get intercomReady => 'Готово';

  @override
  String get intercomOff => 'Інтерком вимкнено';

  @override
  String get intercomDifferentKey => 'Інший ключ';

  @override
  String get intercomUnreachable => 'Недоступний';

  @override
  String get intercomOffline => 'Офлайн';

  @override
  String get intercomChecking => 'Перевірка…';

  @override
  String get settingIntercomTalkModeTitle => 'Режим розмови';

  @override
  String get settingIntercomTalkModeDescription =>
      '«Натисніть і говоріть» (Push to talk) передає звук, доки утримується кнопка. «Вільні руки» тримає мікрофон відкритим протягом усього виклику.';

  @override
  String get intercomOptionTalkPtt => 'Натисніть і говоріть (PTT)';

  @override
  String get intercomOptionTalkHandsfree => 'Вільні руки';

  @override
  String get intercomTalkSection => 'Розмова';

  @override
  String get settingKioskAllowDrawerTitle => 'Дозволити меню зі швидкими діями';

  @override
  String get settingKioskAllowDrawerDescription =>
      'Свайп від краю відкриває меню без жесту виходу чи PIN-коду, обмежене вибраними нижче діями.';

  @override
  String get settingKioskAllowDashboardTitle => 'Панель керування';

  @override
  String get settingKioskAllowDashboardDescription =>
      'Перезавантажити початкову сторінку.';

  @override
  String get settingKioskAllowHaKioskTitle => 'Режим кіоска HA';

  @override
  String get settingKioskAllowHaKioskDescription =>
      'Показувати або приховувати заголовок і бічну панель Home Assistant.';

  @override
  String get settingKioskAllowCameraTitle => 'Перегляд камери';

  @override
  String get settingKioskAllowCameraDescription =>
      'Відкрити стандартний перегляд камери.';

  @override
  String get settingKioskAllowIntercomTitle => 'Інтерком';

  @override
  String get settingKioskAllowIntercomDescription =>
      'Телефонувати на інші кіоски з меню кіоска.';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription =>
      'Відкрити веб-інтерфейс Music Assistant.';

  @override
  String get settingKioskAllowSendspinPlayerTitle => 'Плаваючий плеєр';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      'Показувати або приховувати плаваючий плеєр і відкривати «Зараз відтворюється».';

  @override
  String get settingKioskAllowScreensaverTitle => 'Запустити заставку';

  @override
  String get settingKioskAllowScreensaverDescription =>
      'Запустити заставку зараз.';

  @override
  String get settingKioskAllowHoldTitle => 'Режим утримання';

  @override
  String get settingKioskAllowHoldDescription =>
      'Увімкнути або вимкнути режим утримання.';

  @override
  String get settingKioskAllowLockdownTitle => 'Режим блокування';

  @override
  String get settingKioskAllowLockdownDescription =>
      'Блокувати екран до жесту виходу або дистанційного розблокування.';

  @override
  String get settingKioskAllowThemeTitle => 'Вибір теми';

  @override
  String get settingKioskAllowThemeDescription =>
      'Перемикання між світлою та темною темами.';

  @override
  String get settingKioskAllowAppsTitle => 'Застосунки';

  @override
  String get settingKioskAllowAppsDescription =>
      'Відкрити лаунчер застосунків. Якщо увімкнено вимкнення кнопки «Додому», запуск застосунку скасовує закріплення кіоска до повернення.';

  @override
  String get kioskAllowedActions => 'Дозволені дії';

  @override
  String get kioskAllowedHelp => 'Які швидкі дії пропонує меню кіоска';

  @override
  String get settingKioskEnabledTitle => 'Увімкнути режим кіоска';

  @override
  String get settingKioskEnabledDescription =>
      'Заблокувати планшет у Kiosk Satellite. Свайп меню замінюється жестом виходу, кнопка «Назад» залишається всередині кіоска, а наведені нижче захисти активуються.';

  @override
  String get settingKioskStartOnBootTitle => 'Запуск під час завантаження';

  @override
  String get settingKioskStartOnBootDescription =>
      'Запускати Kiosk Satellite під час увімкнення пристрою. На Android 10+ для цього потрібен дозвіл показу поверх інших застосунків; Android запитає під час першого увімкнення.';

  @override
  String get settingKioskExitGestureTitle => 'Жест виходу з кіоска';

  @override
  String get settingKioskExitGestureDescription =>
      'Швидкі дотики в будь-якому місці відкривають меню після введення PIN-коду, якщо його встановлено. Варіанти з утриманням вимагають затискання останнього дотику. Якщо вимкнено, дістатися налаштувань можна лише через віддалене адміністрування.';

  @override
  String get settingKioskPinTitle => 'PIN-код режиму кіоска';

  @override
  String get settingKioskPinDescription =>
      'Запитується після жесту виходу перед відкриттям меню. Залиште порожнім, якщо PIN-код не потрібен.';

  @override
  String get settingKioskDisableStatusBarTitle => 'Вимкнути панель сповіщень';

  @override
  String get settingKioskDisableStatusBarDescription =>
      'Блокувати висування панелі сповіщень захисним шаром уздовж верхнього краю. Потрібен дозвіл показу поверх інших застосунків; Android запитає під час першого увімкнення.';

  @override
  String get settingKioskDisableVolumeTitle => 'Вимкнути кнопки гучності';

  @override
  String get settingKioskDisableVolumeDescription =>
      'Перехоплювати апаратні клавіші гучності.';

  @override
  String get settingKioskDisablePowerTitle => 'Вимкнути кнопку живлення';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android не може блокувати кнопку живлення, тому екран одразу вмикається знову під час її натискання. Дистанційне вимкнення екрана все одно працює.';

  @override
  String get settingKioskDisableHomeTitle => 'Вимкнути кнопку «Додому»';

  @override
  String get settingKioskDisableHomeDescription =>
      'Закріпити застосунок за допомогою блокування в додатку Android, що блокує кнопки «Додому» та нещодавніх застосунків. Android запитає підтвердження першого разу.';

  @override
  String get settingKioskDisableContextMenusTitle => 'Вимкнути контекстні меню';

  @override
  String get settingKioskDisableContextMenusDescription =>
      'Блокувати меню тривалого натискання та виділення тексту у веб-перегляді.';

  @override
  String get settingKioskDisablePullRefreshTitle =>
      'Вимкнути оновлення потягуванням';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Ігнорувати жест оновлення потягуванням вниз, коли режим кіоска активний.';

  @override
  String get settingKioskDisableGesturesTitle => 'Вимкнути жести';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Ігнорувати жести зі сторінки «Жести», коли режим кіоска активний.';

  @override
  String get kioskGestureTaps5 => '5 швидких дотиків';

  @override
  String get kioskGestureTaps7 => '7 швидких дотиків';

  @override
  String get kioskGestureTaps5Hold =>
      '5 швидких дотиків з утриманням останнього';

  @override
  String get kioskGestureTaps7Hold =>
      '7 швидких дотиків з утриманням останнього';

  @override
  String get kioskGestureNone => 'Вимкнено (лише віддалений адміністратор)';

  @override
  String get kioskForeground =>
      'Kiosk Satellite може самостійно повертатися на передній план.';

  @override
  String get kioskOverlayMissing =>
      'Без цього кіоск не зможе повернутися, а захисний екран блокування покриватиме лише застосунок.';

  @override
  String get kioskGuardHeld =>
      'Шторка сповіщень і список нещодавніх застосунків закриваються самостійно, поки екран захищено.';

  @override
  String get kioskGuardMissing =>
      'Без цього шторка сповіщень і нещодавні застосунки залишаються доступними. Увімкніть Kiosk Satellite у розділі «Спеціальні можливості».';

  @override
  String get kioskOverlayRemote =>
      'Без цього кіоск не зможе повернутися. Запит дозволу зʼявиться на планшеті.';

  @override
  String get kioskGuardRemote =>
      'Без цього шторка сповіщень і нещодавні застосунки залишаються доступними. Увімкніть Kiosk Satellite у розділі «Спеціальні можливості» на планшеті.';

  @override
  String get kioskGrantDevice => 'Надати на пристрої';

  @override
  String get kioskOpenSettingsDevice => 'Відкрити налаштування на пристрої';

  @override
  String get settingLockdownEnabledTitle => 'Увімкнути режим блокування';

  @override
  String get settingLockdownEnabledDescription =>
      'Вимикає взаємодію з екраном, доки його не буде вимкнено через Home Assistant або за допомогою жесту виходу.';

  @override
  String get settingLockdownMenuTitle => 'Показувати в меню кіоска';

  @override
  String get settingLockdownMenuDescription =>
      'Додати пункт режиму блокування до меню кіоска, який блокує екран. Використовуйте жест виходу, віддалене адміністрування або Home Assistant для розблокування.';

  @override
  String get settingLockdownBlackoutTitle => 'Затемнення екрана';

  @override
  String get settingLockdownBlackoutDescription =>
      'Робить екран чорним під час блокування.';

  @override
  String get settingLockdownAllowScreensaverTitle => 'Дозволити заставку';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      'Дозволяє заставці працювати під час блокування. Вимкнення за рухом залишається деактивованим, доки діє блокування.';

  @override
  String get settingLockdownExitGestureTitle => 'Жест виходу з блокування';

  @override
  String get settingLockdownExitGestureDescription =>
      'Швидкі дотики в будь-якому місці вимикають режим блокування після введення PIN-коду кіоска, якщо його встановлено. Варіанти з утриманням вимагають затискання останнього дотику. Якщо вимкнено, вимкнути його можна лише через віддалений адміністратор або Home Assistant.';

  @override
  String get lockdownGestureNone => 'Вимкнено (лише дистанційно)';

  @override
  String get lockdownExplanation =>
      'Режим блокування робить панель керування неінтерактивною, активує кожен захист режиму кіоска без зміни ваших налаштувань режиму кіоска та вимикає розпізнавання слова активації, поки він увімкнений. Якщо захист системного інтерфейсу ввімкнено (вище), шторка сповіщень і список нещодавніх застосунків також блокуються. Home Assistant отримує перемикач режиму блокування через ESPHome.';

  @override
  String get lockdownSearch =>
      'Дистанційний сенсорний щит. Налаштуйте його у вебінтерфейсі віддаленого адміністратора; його дозволи знаходяться в обовʼязкових системних дозволах.';

  @override
  String get lockdownOverlayHeld =>
      'Захисний екран блокування може покривати весь екран.';

  @override
  String get lockdownOverlayMissing =>
      'Без цього захисний екран покриває лише застосунок. Екран надання дозволу зʼявиться на планшеті.';

  @override
  String get lockdownPermissionsSearch =>
      'Дозволи, на які спирається захист блокування.';

  @override
  String get mediaCacheTitle => 'Кеш обкладинок альбомів';

  @override
  String get mediaCacheReadFailed => 'Не вдалося прочитати розмір кешу.';

  @override
  String get mediaCacheClearFailed => 'Не вдалося очистити кеш.';

  @override
  String get mediaCacheChecking => 'Перевірка розміру кешу...';

  @override
  String get mediaCacheClearing => 'Очищення...';

  @override
  String mediaCacheUsage(String used, String limit) {
    return 'Використано $used з $limit. Мініатюри черги кешуються автоматично.';
  }

  @override
  String get settingSendspinShowPlayerTitle => 'Показувати плаваючий плеєр';

  @override
  String get settingSendspinShowPlayerDescription =>
      'Поки грає музика, показувати невелике вікно відтворення поверх панелі керування з обкладинкою, відомостями про трек і прогресом. Перетягніть його будь-куди; положення запам\'ятовується.';

  @override
  String get settingSendspinPlayerSizeTitle => 'Розмір плеєра';

  @override
  String get settingSendspinPlayerSizeDescription =>
      '«Компактний» - це маленьке непомітне вікно відтворення. «Великий з елементами керування» додає кнопки «Попередній», «Відтворити/Пауза» та «Наступний», розмірені під дотик, які керують усією групою відтворення.';

  @override
  String get settingSendspinPausedHideMinutesTitle =>
      'Ховати призупинений плеєр за';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      'Як довго призупинений плеєр залишається на екрані. Стосується як плаваючого плеєра, так і режиму «Зараз грає».';

  @override
  String get settingSendspinDismissKeepsPlayingTitle =>
      'Продовжувати відтворення після згортання';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      'Зсув плаваючого плеєра жестом ховає його, не зупиняючи музику.';

  @override
  String get settingSendspinPlayerShortcutTitle => 'Показувати в меню кіоска';

  @override
  String get settingSendspinPlayerShortcutDescription =>
      'Додати пункт до меню кіоска, який показує або ховає плаваючий плеєр. УВАГА: якщо нічого не відтворюється або в цього плеєра немає черги, він не з\'явиться.';

  @override
  String get mediaFloatingPage => 'Плаваючий плеєр';

  @override
  String get mediaFloatingHint => 'Невелика картка поверх панелі керування';

  @override
  String get mediaCompact => 'Компактний';

  @override
  String get mediaLargeControls => 'Великий з елементами керування';

  @override
  String get settingSendspinPlayerSourceTitle => 'Джерело плеєра';

  @override
  String get settingSendspinPlayerSourceDescription =>
      'Що показує та керує плаваючий плеєр і режим «Зараз грає»: цей пристрій або плеєр деінде.';

  @override
  String get settingSendspinPlayerTitle => 'Плеєр';

  @override
  String get settingSendspinPlayerDescription =>
      'Плеєр цього джерела для показу та керування.';

  @override
  String get settingSendspinDuckPercentTitle =>
      'Зменшувати гучність під час голосових взаємодій';

  @override
  String get settingSendspinDuckPercentDescription =>
      'Музика знижується до цієї частки своєї гучності під час голосових взаємодій і викликів інтеркому, а потім повертається.';

  @override
  String get settingSendspinVolumeKeysTitle =>
      'Кнопки гучності керують плеєром';

  @override
  String get settingSendspinVolumeKeysDescription =>
      'Кнопки гучності цього пристрою змінюють гучність плеєра, за яким слідують, замість власної. Лише поки на екрані режим «Зараз грає», або завжди, коли плеєр відтворює.';

  @override
  String get settingSendspinVolumeKeyStepTitle => 'Крок кнопки гучності';

  @override
  String get settingSendspinVolumeKeyStepDescription =>
      'Наскільки одне натискання кнопки гучності зсуває гучність плеєра.';

  @override
  String get mediaIntro =>
      'Плаваючий плеєр і режим «Зараз грає» з\'являються, лише коли у вибраного плеєра грає трек або завантажена черга. Якщо нічого не відтворюється і черга порожня, жоден із них не з\'явиться.';

  @override
  String get mediaThisDevice => 'Цей пристрій';

  @override
  String get mediaOff => 'Вимкнено';

  @override
  String get mediaKeysNowPlaying => 'Поки показано «Зараз грає»';

  @override
  String get mediaKeysPlaying => 'Поки плеєр відтворює';

  @override
  String get mediaAnotherPlayer => 'інший плеєр';

  @override
  String mediaLocalOffline(String player) {
    return 'Власний плеєр Sendspin цього пристрою залишається офлайн, доки керується $player.';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => 'Увімкнути тексти пісень';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      'Синхронізовані тексти у режимі «Зараз грає», для кожного джерела плеєра.';

  @override
  String get settingSendspinLyricsSourceTitle => 'Джерело текстів';

  @override
  String get settingSendspinLyricsSourceDescription =>
      'Звідки беруться тексти. Music Assistant потребує адресу сервера та токен на своїй сторінці.';

  @override
  String get settingSendspinLyricsFallbackTitle =>
      'Резервне джерело Music Assistant';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      'Якщо LRCLIB недоступний, замість нього запитується Music Assistant. Потребує з\'єднання з Music Assistant.';

  @override
  String get settingSendspinLyricsOffsetTitle => 'Синхронізація тексту';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      'Зсувати текст відносно музики. Додатне значення показує кожен рядок раніше, від\'ємне - пізніше. Варто трохи підкоригувати для треків, де текст стабільно розбігається.';

  @override
  String get mediaLyricsPage => 'Тексти пісень';

  @override
  String get mediaLyricsHint =>
      'Синхронізовані тексти, їхнє джерело й синхронізація';

  @override
  String get settingSendspinMaUrlTitle => 'Адреса сервера';

  @override
  String get settingSendspinMaUrlDescription =>
      'Адреса сервера Music Assistant, як її показує його вебінтерфейс. Зазвичай https і порт 8095.';

  @override
  String get settingSendspinMaTokenTitle => 'Токен автентифікації';

  @override
  String get settingSendspinMaTokenDescription =>
      'Довговічний токен із Music Assistant (Налаштування, потім Користувачі). Для текстів пісень достатньо доступу на читання; ярлик меню кіоска відкриває вебінтерфейс від імені власника токена.';

  @override
  String get settingSendspinMaShortcutTitle => 'Показувати в меню кіоска';

  @override
  String get settingSendspinMaShortcutDescription =>
      'Додати пункт Music Assistant до меню кіоска, який відкриває вебінтерфейс сервера поверх панелі керування. Потребує адресу сервера вище.';

  @override
  String get settingSendspinMaOpenFullscreenTitle =>
      'Відкривати одразу «Зараз грає»';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      'Відкривати повноекранний плеєр Music Assistant з меню кіоска або жестом «Відкрити Music Assistant».';

  @override
  String get settingSendspinMaAutoCloseTitle => 'Закривати після бездіяльності';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Повернутися до панелі керування, якщо сторінку Music Assistant ніхто не торкався цей час. Нуль залишає її відкритою, доки її не закриють.';

  @override
  String get settingSendspinMaHideCloseTitle => 'Ховати кнопку закриття';

  @override
  String get settingSendspinMaHideCloseDescription =>
      'Плаваюча кнопка закриття може розміщуватися поверх власних елементів керування Music Assistant, як-от меню «Зараз грає». Без неї закривайте кнопкою «Назад» або через меню кіоска, що висувається.';

  @override
  String get mediaMaHint => 'Сервер, токен, ярлик меню кіоска';

  @override
  String get mediaKioskMenu => 'Меню кіоска';

  @override
  String get mediaValidateConnection => 'Перевірити з\'єднання';

  @override
  String get mediaValidate => 'Перевірити';

  @override
  String get mediaChecking => 'Перевірка…';

  @override
  String get mediaConnected => 'З\'єднано';

  @override
  String mediaConnectedVersion(String version) {
    return 'З\'єднано з Music Assistant $version';
  }

  @override
  String get mediaValidateHint =>
      'Перевірте адресу та токен перед увімкненням ярлика або текстів пісень.';

  @override
  String get mediaDeviceNoAnswer => 'Пристрій не відповів.';

  @override
  String get mediaValidationFailed => 'Перевірка не вдалася.';

  @override
  String get mediaNoAddress => 'Адресу сервера не встановлено.';

  @override
  String get mediaNoToken => 'Токен автентифікації не встановлено.';

  @override
  String get mediaTimeout => 'Music Assistant не відповів вчасно.';

  @override
  String mediaUnreachable(String host, String error) {
    return 'Не вдалося зв\'язатися з $host: $error';
  }

  @override
  String get mediaServerClosed => 'сервер закрив з\'єднання';

  @override
  String get settingSendspinFullscreenControlsTitle =>
      'Показувати елементи керування медіа';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      'Кнопки «Попередній», «Відтворити/Пауза» та «Наступний» і смуга прогресу у режимі «Зараз грає». З увімкненим керуванням натомість закриває кнопка, а не дотик будь-де.';

  @override
  String get settingSendspinFullscreenTextScaleTitle => 'Масштаб тексту';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      'Розмір назви треку, виконавця, альбому, тексту пісні й черги. Стосується обох розкладок і режиму разом із заставкою. Обкладинка підлаштовується, щоб лишити місце для тексту.';

  @override
  String get settingSendspinFullscreenButtonScaleTitle => 'Масштаб кнопок';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      'Розмір кнопок відтворення і смуги прогресу, незалежно від розміру тексту. Стосується обох розкладок і режиму разом із заставкою. Елементи керування заповнюють доступний у плеєрі простір.';

  @override
  String get settingSendspinFullscreenHorizontalTitle => 'Горизонтальний режим';

  @override
  String get settingSendspinFullscreenHorizontalDescription =>
      'Розділити обкладинку та елементи керування на рівні ліву й праву половини. З відкритим текстом пісні або чергою відомості про трек переміщуються під обкладинку. Ігнорується, коли «Зараз грає» показано поруч із заставкою.';

  @override
  String get settingSendspinFullscreenDoubleTapTitle =>
      'Подвійний дотик для закриття';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'Подвійний дотик будь-де у режимі «Зараз грає» закриває його. Кнопка закриття не показуватиметься. Ігнорується, коли «Зараз грає» показано поруч із заставкою.';

  @override
  String get settingSendspinFullscreenOnPlayTitle =>
      'Відкривати «Зараз грає» при початку музики';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      'Відкривати режим «Зараз грає» щойно починається відтворення, замість очікування часу спрацювання заставки.';

  @override
  String get settingSendspinFullscreenMotionTitle =>
      'Закривати «Зараз грає» при русі';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      'Дозволити руху закривати «Зараз грає», як звичайну заставку. Якщо вимкнено, закриває лише дотик, тож проходження повз не перериває показ музики. Ігнорується, коли «Зараз грає» показано поруч із заставкою.';

  @override
  String get settingSendspinFullscreenShortcutTitle =>
      'Показувати в меню кіоска';

  @override
  String get settingSendspinFullscreenShortcutDescription =>
      'Додати пункт до меню кіоска, який показує режим «Зараз грає». УВАГА: якщо нічого не відтворюється або в цього плеєра немає черги, він не з\'явиться.';

  @override
  String get settingSendspinSpeakerPillTitle =>
      'Показувати панель вибору гучномовців';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Показує вибір гучномовців протягом 5 секунд після взаємодії з екраном. Дозволяє додати або вилучити гучномовці з поточної групи.';

  @override
  String get settingSendspinQueueArtTitle => 'Показувати обкладинки у черзі';

  @override
  String get settingSendspinQueueArtDescription =>
      'Обкладинка у кожному рядку панелі черги.';

  @override
  String get mediaNowPlayingHint =>
      'Повноекранний режим під час відтворення музики';

  @override
  String get mediaInterfaceHeading => 'Інтерфейс користувача';

  @override
  String get settingSendspinFullscreenTitle => '«Зараз грає» замість заставки';

  @override
  String get settingSendspinFullscreenDescription =>
      'Поки грає музика, заставка стає повноекранним режимом «Зараз грає» з обкладинкою альбому. Коли нічого не грає, працює звичайна заставка.';

  @override
  String get settingSendspinFullscreenSplitTitle =>
      'Показувати поруч із заставкою';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      'Залишати заставку видимою поруч із «Зараз грає». На вертикальних екранах заставка розташовується над плеєром. Малі екрани залишають повноекранний плеєр.';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => 'Заповнювати екран';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      'Перевизначає заповнення фото, поки заставка поділяє екран із «Зараз грає». «За замовчуванням» використовує власне налаштування кожної заставки. «Вимкнено» залишає ціле фото між чорними смугами. «Розумно» збільшує фото, за формою близькі до екрана, а решту рамкою над розмитим тлом. «Завжди» збільшує кожне фото, обрізаючи те, що не вміщується.';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle =>
      'Перевизначати яскравість заставки';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      'Використовувати звичайну яскравість екрана замість яскравості заставки, поки «Зараз грає» показано поруч із заставкою. Це також перевизначає заплановану яскравість заставки.';

  @override
  String get mediaScreensaverHeading => 'Заставка';

  @override
  String get mediaDefaultFill => 'За замовчуванням';

  @override
  String get mediaFillOff => 'Вимкнено';

  @override
  String get mediaFillSmart => 'Розумно';

  @override
  String get mediaFillAlways => 'Завжди';

  @override
  String get mediaPickPlayer => 'Виберіть плеєр';

  @override
  String get mediaMaPlayer => 'Плеєр Music Assistant';

  @override
  String get mediaHaPlayer => 'Медіаплеєр Home Assistant';

  @override
  String get mediaSonosRoom => 'Кімната Sonos';

  @override
  String get mediaSearchPlayers => 'Пошук плеєрів';

  @override
  String get mediaOffline => 'Офлайн';

  @override
  String mediaOfflineName(String name) {
    return '$name (офлайн)';
  }

  @override
  String get mediaSetUpMa =>
      'Налаштуйте Music Assistant, щоб перелічити його плеєри.';

  @override
  String get mediaSetUpHa =>
      'Під\'єднайте Home Assistant, щоб перелічити його медіаплеєри.';

  @override
  String get mediaSetUpSonos =>
      'Відомих гучномовців Sonos ще немає. Знайдіть або додайте один на сторінці Sonos.';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant не відповів: $error';
  }

  @override
  String get mediaSaveFailed => 'Не вдалося зберегти плеєр.';

  @override
  String get mediaSelectFailed => 'Не вдалося вибрати плеєр';

  @override
  String get settingSendspinEnabledTitle => 'Увімкнути плеєр Sendspin';

  @override
  String get settingSendspinEnabledDescription =>
      'Перетворити цей пристрій на синхронізований плеєр Sendspin. Він з\'явиться у Music Assistant під назвою пристрою, синхронізовано з кожним іншим гучномовцем Sendspin.';

  @override
  String get settingSendspinServerTitle => 'Сервер';

  @override
  String get settingSendspinServerDescription =>
      'Адреса сервера Sendspin, наприклад 192.168.1.10:8927. Залиште порожнім, щоб знайти сервер у мережі автоматично.';

  @override
  String get settingSendspinCodecTitle => 'Бажаний аудіокодек';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC - без втрат, ідеально для Wi-Fi або Ethernet. Сервер робить остаточний вибір з того, що пропонує цей пристрій.';

  @override
  String get settingSendspinSyncOffsetTitle => 'Зсув синхронізації аудіо (мс)';

  @override
  String get settingSendspinSyncOffsetDescription =>
      'Від\'ємне значення відтворює на цьому пристрої раніше, для гучномовців, що відстають від групи (Bluetooth). Підлаштовуйте на слух; застосовується негайно.';

  @override
  String get mediaSendspinPage => 'Плеєр Sendspin';

  @override
  String get mediaSendspinHint =>
      'Зробити цей пристрій синхронізованим плеєром Music Assistant';

  @override
  String get mediaFlac => 'FLAC (без втрат)';

  @override
  String get mediaOpus => 'Opus (економний)';

  @override
  String get mediaPcm => 'PCM (без стиснення)';

  @override
  String get settingSendspinSonosGroupVolumeTitle =>
      'Регулювати гучність групи';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      'Поки кімната, за якою слідують, грає у групі, повзунок гучності встановлює гучність усієї групи. Якщо вимкнено - лише цієї кімнати.';

  @override
  String get settingSendspinSonosInputsTitle =>
      'Показувати телевізор та лінійний вхід';

  @override
  String get settingSendspinSonosInputsDescription =>
      'Показувати активність у медіаплеєрі, коли активні входи eARC або лінійний вхід.';

  @override
  String get mediaSonosHint => 'Гучномовці в мережі, додайте один за адресою';

  @override
  String get mediaSonosSpeakers => 'Гучномовці';

  @override
  String get mediaSonosNoneFound => 'Sonos не знайдено';

  @override
  String get mediaSonosDiscoveryEmpty =>
      'Ніхто не відповів у цій мережі. Додайте пристрій за адресою.';

  @override
  String get mediaSonosAddTitle => 'Додати Sonos за адресою';

  @override
  String get mediaSonosLooking => 'Пошук…';

  @override
  String get mediaSonosEmpty => 'Гучномовців ще немає';

  @override
  String get mediaSonosEmptyHelp =>
      'Знайдіть у цій мережі або додайте гучномовець за його адресою.';

  @override
  String get mediaSonosForget => 'Забути';

  @override
  String get mediaSonosSearchTitle => 'Пошук у мережі';

  @override
  String get mediaSonosSearchHelp =>
      'Знаходить гучномовці Sonos у цій мережі. Щоб їх було виявлено автоматично, вони мають бути в тому самому VLAN, що й цей пристрій.';

  @override
  String get mediaSonosSearch => 'Пошук';

  @override
  String get mediaSonosSearching => 'Пошук…';

  @override
  String get mediaSonosAddAddress => 'Додати за адресою';

  @override
  String get mediaSonosAddressHelp =>
      'Адреса гучномовця в мережі. З неї додається вся домогосподарство.';

  @override
  String get mediaSonosPickRoom =>
      'Виберіть кімнату в розділі «Джерело плеєра», Sonos.';

  @override
  String get mediaSonosAdded => 'Sonos додано';

  @override
  String get mediaSonosNoRooms => 'Гучномовець не перелічив жодної кімнати.';

  @override
  String get mediaSonosNoAddress => 'без адреси';

  @override
  String mediaSonosUnreachable(String host) {
    return 'Жоден Sonos не відповів на $host.';
  }

  @override
  String get settingsMenuHomeAssistant => 'Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary =>
      'Підключення, панель керування, режим кіоска';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary =>
      'Активаційне слово, фонове прослуховування';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary =>
      'Нативні сутності та Bluetooth-проксі';

  @override
  String get settingsMenuScreenAudio => 'Екран та звук';

  @override
  String get settingsMenuScreenAudioSummary => 'Яскравість, гучність, мікрофон';

  @override
  String get settingsMenuScreensaver => 'Заставка';

  @override
  String get settingsMenuScreensaverSummary =>
      'Годинник, фото, датчики, стан погоди';

  @override
  String get settingsMenuBrowser => 'Веб-переглядач';

  @override
  String get settingsMenuBrowserSummary => 'Кеш, SSL, масштаб';

  @override
  String get settingsMenuMediaPlayer => 'Медіаплеєр';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant, Sendspin, Sonos';

  @override
  String get settingsMenuDlna => 'DLNA-плеєр';

  @override
  String get settingsMenuDlnaSummary => 'Приймач медіапотоків DLNA/UPnP';

  @override
  String get settingsMenuIntercom => 'Інтерком';

  @override
  String get settingsMenuIntercomSummary => 'Дзвінки між кіосками, автоприйом';

  @override
  String get settingsMenuCamera => 'Камера планшета';

  @override
  String get settingsMenuCameraSummary =>
      'Потокове відео, знімки, виявлення руху';

  @override
  String get settingsMenuCameraStreams => 'Відеопотоки камер';

  @override
  String get settingsMenuCameraStreamsSummary =>
      'Камери Go2RTC та Home Assistant';

  @override
  String get settingsMenuKiosk => 'Режим кіоска';

  @override
  String get settingsMenuKioskSummary =>
      'Жест виходу, PIN-код, апаратні кнопки';

  @override
  String get settingsMenuHomeLauncher => 'Домашній лаунчер';

  @override
  String get settingsMenuHomeLauncherSummary =>
      'Вибір Kiosk Satellite головним лаунчером';

  @override
  String get settingsMenuAppLauncher => 'Лаунчер застосунків';

  @override
  String get settingsMenuAppLauncherSummary =>
      'Запуск сторонніх Android-додатків';

  @override
  String get settingsMenuGestures => 'Жести';

  @override
  String get settingsMenuGesturesSummary =>
      'Сенсорні жести, жести долонею та плесканням';

  @override
  String get settingsMenuDevice => 'Пристрій';

  @override
  String get settingsMenuDeviceSummary =>
      'Назва, тема застосунку, віддалений доступ';

  @override
  String get settingsMenuFleet => 'Керування групою';

  @override
  String get settingsMenuFleetSummary =>
      'Синхронізація налаштувань між кількома планшетами';

  @override
  String get settingsMenuPlugins => 'Плагіни';

  @override
  String get settingsMenuPluginsSummary =>
      'Розширення функціональності та пакети';

  @override
  String get settingsMenuLogs => 'Журнал подій';

  @override
  String get settingsMenuLogsSummary => 'Журнал застосунку та веб-консоль';

  @override
  String get settingsMenuAbout => 'Про застосунок';

  @override
  String get settingsMenuAboutSummary => 'Версія, автор, ліцензія';

  @override
  String get settingsMenuOverview => 'Огляд';

  @override
  String get settingsMenuOverviewSummary => 'Швидкий стан компонентів кіоска';

  @override
  String get settingsMenuLockdown => 'Повне блокування';

  @override
  String get settingsMenuLockdownSummary => 'Вимкнення взаємодії з екраном';

  @override
  String get settingsMenuFiles => 'Файли';

  @override
  String get settingsMenuFilesSummary =>
      'Перегляд, завантаження та вивантаження файлів';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => 'Дисплей та звук';

  @override
  String get settingsGroupMediaCameras => 'Медіа та камери';

  @override
  String get settingsGroupKiosk => 'Кіоск та захист';

  @override
  String get settingsGroupSystem => 'Система';

  @override
  String get settingsMenuMenu => 'Меню налаштувань';

  @override
  String get settingsMenuTheme => 'Тема оформлення';

  @override
  String get settingsMenuLogout => 'Вийти';

  @override
  String get settingsMenuSwitchKiosk => 'Змінити кіоск';

  @override
  String settingsMenuThemeState(String theme) {
    return 'Тема: $theme';
  }

  @override
  String get settingsMenuThemeAuto => 'Авто';

  @override
  String get settingAdaptiveBrightnessTitle => 'Адаптивна яскравість';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Зменшує яскравість екрана, коли в кімнаті темнішає, використовуючи датчик освітленості.';

  @override
  String get settingAdaptiveMinBrightnessTitle => 'Мінімальна яскравість';

  @override
  String get settingAdaptiveMinBrightnessDescription =>
      'Яскравість екрана в темній кімнаті.';

  @override
  String get settingAdaptiveMaxBrightnessTitle => 'Максимальна яскравість';

  @override
  String get settingAdaptiveMaxBrightnessDescription =>
      'Яскравість екрана в світлій кімнаті.';

  @override
  String get settingAdaptiveDarkLuxTitle => 'Темна кімната (лк)';

  @override
  String get settingAdaptiveDarkLuxDescription =>
      'Рівень освітленості, на якому або нижче якого екран залишається на мінімальній яскравості.';

  @override
  String get settingAdaptiveBrightLuxTitle => 'Світла кімната (лк)';

  @override
  String get settingAdaptiveBrightLuxDescription =>
      'Рівень освітленості, на якому або вище якого екран залишається на максимальній яскравості.';

  @override
  String get screenAudioAdaptiveHint =>
      'Слідувати за освітленням кімнати за допомогою датчика';

  @override
  String get screenAudioAdaptiveNote =>
      'Рівень у світлій кімнаті. Адаптивна яскравість зменшуватиме його від цього значення.';

  @override
  String get screenAudioAdaptiveOwns => 'Адаптивна яскравість увімкнена.';

  @override
  String get screenAudioNoSensor =>
      'На цьому пристрої немає датчика освітленості.';

  @override
  String get screenAudioAmbientLight => 'Освітленість середовища';

  @override
  String get screenAudioAmbientHelp =>
      'Поточні показники датчика освітленості.';

  @override
  String get screenAudioNoReading => 'Показників ще немає';

  @override
  String screenAudioLux(String lux) {
    return '$lux лк';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux лк (останнє відоме)';
  }

  @override
  String get screenAudioSetsMaximum =>
      'Встановлює максимальну яскравість: адаптивна яскравість увімкнена.';

  @override
  String get screenAudioSetsDefault =>
      'Встановлює яскравість за замовчуванням.';

  @override
  String get settingAudioMicDeviceTitle => 'Мікрофон';

  @override
  String get settingAudioMicDeviceDescription =>
      'Мікрофон, з якого здійснюється розпізнавання слова активації та запис голосових команд.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Динамік';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Вихід для звуків Voice Satellite; відтворення медіа слідує системному маршруту. Ехопоглинання працює лише тоді, коли мікрофон і динамік на одному пристрої.';

  @override
  String get screenAudioDevices => 'Аудіопристрої';

  @override
  String get screenAudioSelectedDevice => 'Вибраний пристрій';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (не підключено)';
  }

  @override
  String get settingMicAudioSourceTitle => 'Режим захоплення';

  @override
  String get settingMicAudioSourceDescription =>
      'Голосовий зв\'язок - єдиний режим із придушенням ехо, тому залиште його, якщо тільки мікрофон не звучить значно тихіше, ніж у диктофоні.';

  @override
  String get settingMicEchoCancellationTitle => 'Ехопоглинання';

  @override
  String get settingMicEchoCancellationDescription =>
      'Запобігає потраплянню звуку власного динаміка кіоска в мікрофон, щоб команда зупинки працювала під час відтворення. Вимикайте лише якщо мікрофон тут звучить набагато тихіше, ніж у диктофоні.';

  @override
  String get settingMicChannelTitle => 'Канал мікрофона';

  @override
  String get settingMicChannelDescription =>
      'Багатоканальні мікрофони часто резервують один канал для розпізнавання мови; вибір цього каналу може покращити розпізнавання.';

  @override
  String get settingMicAgcTitle => 'Автоматичне регулювання підсилення';

  @override
  String get settingMicAgcDescription =>
      'Дозволити Android вирівнювати рівень мікрофона замість фіксованого підсилення. Це також підсилює шум кімнати, а на деяких пристроях не діє взагалі.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Шумозаглушення';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Зменшує фоновий шум мікрофона за допомогою обробки Android. Це може як допомогти, так і завадити розпізнаванню слова активації залежно від пристрою.';

  @override
  String get settingMicGainDbTitle => 'Підсилення мікрофона';

  @override
  String get settingMicGainDbDescription =>
      'Підсилює або послаблює звук мікрофона перед його розпізнаванням. Орієнтуйтеся на рівень біля 0.05 у тестері активації; завелике підсилення спотворює мову та погіршує розпізнавання.';

  @override
  String get settingMicCaptureFormatTitle => 'Формат захоплення';

  @override
  String get settingMicCaptureFormatDescription =>
      'Виберіть 48 кГц стерео, якщо мікрофон працює в інших програмах, але не тут: деякі звукові карти записують лише в цьому форматі, і програма перетворює його самостійно.';

  @override
  String get screenAudioMicrophoneSettings => 'Налаштування мікрофона';

  @override
  String get screenAudioMicrophoneHint =>
      'Режим захоплення, канал, підсилення, поточний рівень';

  @override
  String get screenAudioMicrophoneNote =>
      'Налаштуйте запис звуку для вашого мікрофона та кімнати. Перевірте роботу слова активації та голосової взаємодії після зміни цих налаштувань.';

  @override
  String get screenAudioVoiceCommunication =>
      'Голосовий зв\'язок (за замовчуванням)';

  @override
  String get screenAudioVoiceRecognition => 'Розпізнавання голосу';

  @override
  String get screenAudioRawMicrophone => 'Необроблений сигнал мікрофона';

  @override
  String get screenAudioAutomaticDefault => 'Автоматично (за замовчуванням)';

  @override
  String get screenAudioStereo => '48 кГц стерео';

  @override
  String get screenAudioDownmix => 'Зведення доріжок (за замовчуванням)';

  @override
  String screenAudioChannel(String channel) {
    return 'Канал $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return 'Канал $channel (немає на цьому мікрофоні)';
  }

  @override
  String get screenAudioMicrophoneLevel => 'Рівень мікрофона';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      'Говоріть з місця, звідки ви зазвичай використовуєте пристрій; налаштуйте підсилення так, щоб звичайна мова доходила до краю зеленої зони.';

  @override
  String get settingBrowserCutoutModeTitle => 'Виріз екрана';

  @override
  String get settingBrowserCutoutModeDescription =>
      'Що робити з областю екрана навколо вирізу камери. Виберіть \"Уникати вирізу\", якщо камера перекриває кнопки у верхній частині панелі.';

  @override
  String get settingScreenOrientationTitle => 'Орієнтація екрана';

  @override
  String get settingScreenOrientationDescription =>
      'Примусово встановити одну орієнтацію екрана. Використовуйте на пристроях без датчика повороту або коли пристрій закріплено так, що датчик визначає положення некоректно.';

  @override
  String get settingKeepScreenOnTitle => 'Не вимикати екран';

  @override
  String get settingKeepScreenOnDescription =>
      'Заборонити операційній системі вимикати екран.';

  @override
  String get settingSetBrightnessOnLaunchTitle =>
      'Встановлювати яскравість під час запуску';

  @override
  String get settingSetBrightnessOnLaunchDescription =>
      'Застосовувати яскравість за замовчуванням щоразу, коли програма запускається.';

  @override
  String get settingDefaultBrightnessTitle => 'Яскравість за замовчуванням';

  @override
  String get settingDefaultBrightnessDescription =>
      'Яскравість екрана, що застосовується під час запуску програми. Переміщення повзунка застосовує значення миттєво.';

  @override
  String get screenAudioScreen => 'Екран';

  @override
  String get screenAudioCutoutAlways => 'Використовувати область вирізу';

  @override
  String get screenAudioCutoutShort => 'Лише короткі краї';

  @override
  String get screenAudioCutoutDefault => 'Системне значення';

  @override
  String get screenAudioCutoutNever => 'Уникати вирізу';

  @override
  String get screenAudioAutomatic => 'Автоматично';

  @override
  String get screenAudioLandscape => 'Альбомна';

  @override
  String get screenAudioReverseLandscape => 'Зворотна альбомна';

  @override
  String get screenAudioPortrait => 'Книжкова';

  @override
  String get screenAudioReversePortrait => 'Зворотна книжкова';

  @override
  String get screenAudioPermission => 'Дозвіл';

  @override
  String get screenAudioBrightnessFallback =>
      'Яскравість використовує резервний режим';

  @override
  String get screenAudioBrightnessPermission =>
      'Без дозволу \"Змінювати системні налаштування\" регулювання яскравості лише затемнює цю програму замість налаштування фактичної яскравості панелі.';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      'Без дозволу \"Змінювати системні налаштування\" регулювання яскравості лише затемнює програму замість налаштування фактичної яскравості панелі.';

  @override
  String get screenAudioAlwaysOn => 'Завжди увімкнений дисплей';

  @override
  String get screenAudioAlwaysOnClock =>
      'Цей пристрій залишає тьмяний годинник увімкненим';

  @override
  String get screenAudioAlwaysOnHelp =>
      'Вимкнення екрана переводить пристрій у режим сну, але завжди увімкнений дисплей знову підсвічує екран блокування, і жодна програма не може цьому завадити. Вимкніть опцію \"Завжди показувати час та інформацію\" в налаштуваннях Android у розділі \"Екран\" біля параметрів екрана блокування (в деяких прошивках вона називається Always-on display). Об\'єкт екрана Home Assistant залишатиметься недоступним, доки ви цього не зробите.';

  @override
  String get settingMediaVolumeTitle => 'Гучність медіа';

  @override
  String get settingMediaVolumeDescription =>
      'Музика та відео відтворюються на цій частці головної гучності. Гучність програвача Sendspin у Music Assistant переміщує цей повзунок.';

  @override
  String get settingAssistantVolumeTitle => 'Гучність асистента';

  @override
  String get settingAssistantVolumeDescription =>
      'Голосові відповіді та сигнали відтворюються на цій частці головної гучності, незалежно від гучності медіа.';

  @override
  String get settingAssistantFullVolumeRangeTitle =>
      'Повний діапазон гучності асистента';

  @override
  String get settingAssistantFullVolumeRangeDescription =>
      'Ініціалізувати гучність виклику вбудованого динаміка на 100%, коли аудіо асистента запускається вперше. Головна гучність та гучність асистента все одно застосовуються. Інші програми спільно використовують цю гучність виклику, і вона не відновлюється згодом.';

  @override
  String get settingIntercomVolumeTitle => 'Гучність домофона';

  @override
  String get settingIntercomVolumeDescription =>
      'Голос та сповіщення іншого кіоска відтворюються на цій частці головної гучності.';

  @override
  String get screenAudioVolume => 'Гучність звуку';

  @override
  String get screenAudioMasterVolume => 'Головна гучність';

  @override
  String get screenAudioMasterHelp =>
      'Гучність пристрою. Гучність медіа, домофона та асистента масштабується відносно неї.';

  @override
  String get settingScreensaverBlackHideExtrasTitle =>
      'Приховати всі додаткові елементи';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      'Залишає екран повністю чорним: без малого годинника, сутностей \"Короткий огляд\" чи інших накладень.';

  @override
  String get screensaverBlackSection => 'Чорна заставка';

  @override
  String get settingScreensaverClockStyleTitle => 'Стиль';

  @override
  String get settingScreensaverClockStyleDescription =>
      'Спосіб відображення годинника.';

  @override
  String get settingScreensaverClockFontTitle => 'Шрифт';

  @override
  String get settingScreensaverClockFontDescription =>
      'Гарнітура шрифту для відображення годинника.';

  @override
  String get settingScreensaverClockFontWeightTitle => 'Товщина шрифту';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      'Товщина ліній цифр годинника. За замовчуванням використовується власна товщина кожного стилю.';

  @override
  String get settingScreensaverClock24hTitle => '24-годинний формат';

  @override
  String get settingScreensaverClock24hDescription =>
      'Показувати 24-годинний час замість AM/PM.';

  @override
  String get settingScreensaverClockSecondsTitle => 'Показувати секунди';

  @override
  String get settingScreensaverClockSecondsDescription =>
      'Відображати секунди на годиннику.';

  @override
  String get settingScreensaverClockDateTitle => 'Показувати дату';

  @override
  String get settingScreensaverClockDateDescription =>
      'Показувати день тижня та дату під годинником.';

  @override
  String get settingScreensaverClockScaleTitle => 'Розмір годинника';

  @override
  String get settingScreensaverClockScaleDescription =>
      'Масштабування годинника від 50 до 300 відсотків для цього екрана.';

  @override
  String get settingScreensaverClockColorTitle => 'Колір годинника';

  @override
  String get settingScreensaverClockColorDescription =>
      'Колір тексту годинника.';

  @override
  String get settingScreensaverClockBgColorTitle => 'Колір фону';

  @override
  String get settingScreensaverClockBgColorDescription =>
      'Колір фону за годинником.';

  @override
  String get settingScreensaverClockBackgroundTitle => 'Фонове фото';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      'Показувати фотографію замість суцільного кольору фону. Шлях до зображення на пристрої або URL-адреса зображення.';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle =>
      'Оновлення фону за URL';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      'Інтервал у хвилинах між завантаженнями фонового зображення за URL. Значення 0 завантажує його лише під час збереження налаштування.';

  @override
  String get settingScreensaverFlipDigitColorTitle => 'Колір цифр';

  @override
  String get settingScreensaverFlipDigitColorDescription =>
      'Колір цифр перекидного годинника.';

  @override
  String get settingScreensaverFlipBgColorTitle => 'Колір карток';

  @override
  String get settingScreensaverFlipBgColorDescription =>
      'Колір карток перекидного годинника.';

  @override
  String get settingScreensaverFlipBackdropColorTitle => 'Колір фону';

  @override
  String get settingScreensaverFlipBackdropColorDescription =>
      'Колір фону позаду карток.';

  @override
  String get settingScreensaverRollerDigitColorTitle => 'Колір цифр';

  @override
  String get settingScreensaverRollerDigitColorDescription =>
      'Колір цифр барабанного годинника.';

  @override
  String get settingScreensaverRollerBgColorTitle => 'Колір фону';

  @override
  String get settingScreensaverRollerBgColorDescription =>
      'Колір фону позаду цифр.';

  @override
  String get settingScreensaverClockNightTitle => 'Нічний режим';

  @override
  String get settingScreensaverClockNightDescription =>
      'Зміна кольорів годинника, коли в кімнаті темно.';

  @override
  String get settingScreensaverClockNightLuxTitle => 'Рівень освітлення';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      'При цьому або нижчому рівні освітлення годинник переходить у нічні кольори.';

  @override
  String get settingScreensaverClockNightColorTitle => 'Нічний колір';

  @override
  String get settingScreensaverClockNightColorDescription =>
      'Колір годинника та віджетів у темряві.';

  @override
  String get settingScreensaverClockNightBgColorTitle => 'Нічний фон';

  @override
  String get settingScreensaverClockNightBgColorDescription =>
      'Колір фону позаду годинника в темряві.';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle =>
      'Приховати фонове фото';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      'Використовувати нічний колір фону замість фотографії під час дії нічного режиму.';

  @override
  String get settingScreensaverClockNightCardColorTitle =>
      'Нічний колір карток';

  @override
  String get settingScreensaverClockNightCardColorDescription =>
      'Колір перекидних карток у темряві.';

  @override
  String get screensaverClockSection => 'Годинник-заставка';

  @override
  String get screensaverClockHint =>
      'Стиль, шрифт, розмір, кольори, нічний режим, фонове фото';

  @override
  String get screensaverStyleDigital => 'Цифровий годинник';

  @override
  String get screensaverStyleFlip => 'Перекидний годинник';

  @override
  String get screensaverStyleRoller => 'Барабанний годинник';

  @override
  String get screensaverFontDefault => 'За замовчуванням';

  @override
  String get screensaverFontLight => 'Світлий';

  @override
  String get screensaverFontRegular => 'Звичайний';

  @override
  String get screensaverFontMedium => 'Середній';

  @override
  String get screensaverFontBold => 'Жирний';

  @override
  String get screensaverFontBlack => 'Наджирний';

  @override
  String get screensaverNoPhoto => 'Фотографію не вибрано';

  @override
  String get screensaverBackgroundHint =>
      'Шлях до файлу зображення або URL-адреса';

  @override
  String get screensaverImageUrlError => 'Введіть повну URL-адресу зображення';

  @override
  String get screensaverRefreshError =>
      'Введіть ціле число хвилин від 0 до 1440';

  @override
  String screensaverMaxCharacters(String count) {
    return 'Використовуйте щонайбільше $count символів';
  }

  @override
  String get screensaverOverlayEntity => 'Сутність';

  @override
  String get screensaverOverlayNotSet => 'Не налаштовано';

  @override
  String get screensaverOverlayName => 'Назва';

  @override
  String get screensaverOverlayNameHelp =>
      'Залиште порожнім, щоб використовувати назву з Home Assistant.';

  @override
  String get screensaverOverlayValue => 'Відображуване значення';

  @override
  String get screensaverOverlayState => 'Стан';

  @override
  String get screensaverOverlayEntityRequired => 'Оберіть сутність.';

  @override
  String get screensaverOverlaySearchHint => 'Назва або entity id';

  @override
  String get screensaverOverlaySearchHintRemote =>
      'Пошук за назвою або entity id';

  @override
  String get screensaverOverlaySearchEmpty =>
      'Почніть вводити для пошуку сутностей.';

  @override
  String get screensaverOverlayNoMatches => 'Нічого не знайдено.';

  @override
  String get screensaverOverlaySearching => 'Пошук…';

  @override
  String get screensaverOverlayUnreachable =>
      'Не вдалося зв\'язатися з Home Assistant';

  @override
  String get screensaverOverlayNoAnswer => 'Пристрій не відповідає.';

  @override
  String screensaverOverlaySearchError(String error) {
    return 'Не вдалося виконати пошук сутностей: $error';
  }

  @override
  String get settingScreensaverDismissOnFaceTitle =>
      'Вимикати під час виявлення обличчя';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      'Пробуджувати екран, коли хтось дивиться на кіоск, а не просто при будь-якому русі. Камера активна лише під час заставки. ПОПЕРЕДЖЕННЯ: Потребує освітленого обличчя; у темряві налаштуйте виявлення руху за розкладом.';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle =>
      'Лише коли екран вимкнено';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      'Залишати заставку видимою при виявленні обличчя, якщо екран світиться. Після вимкнення екрана розпізнавання повертає панель керування. Дотик до екрана все одно закриває заставку.';

  @override
  String get settingScreensaverPostponeOnFaceTitle =>
      'Відкладати заставку при виявленні обличчя';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      'Відкладати запуск заставки, поки перед кіоском перебуває людина. ПОПЕРЕДЖЕННЯ: Камера працюватиме постійно, що спричиняє додаткове навантаження на процесор через розпізнавання облич.';

  @override
  String get settingFaceSensitivityTitle => 'Чутливість до обличчя';

  @override
  String get settingFaceSensitivityDescription =>
      'Більше значення дозволяє розпізнавати менші та віддаленіші обличчя. 1 вимагає перебування близько до екрана; 100 реагує на будь-яке обличчя, яке бачить камера.';

  @override
  String get screensaverDetectionFacePage => 'Розпізнавання обличчя';

  @override
  String get screensaverDetectionFaceHint =>
      'Закривати заставку, коли хтось дивиться на екран';

  @override
  String get screensaverDetectionMotionPrecedence =>
      'Вимикання під час руху активне та має пріоритет, тому розпізнавання облич не діятиме, доки виявлення руху не вимкнено.';

  @override
  String get screensaverDetectionFaceTuning =>
      'Частота кадрів, вибір камери та затримка запуску налаштовуються у параметрах камери.';

  @override
  String get screensaverDetectionAndroidUnsupported =>
      'Не підтримується на цій версії Android.';

  @override
  String get screensaverDetectionX86Unsupported =>
      'Не підтримується на пристроях з архітектурою x86.';

  @override
  String get settingFacePreviewTitle => 'Показувати попередній перегляд камери';

  @override
  String get settingFacePreviewDescription =>
      'Показувати невелике кругле зображення з камери в кутку екрана на кілька секунд після пробудження кіоска розпізнаванням обличчя.';

  @override
  String get settingFacePreviewSecondsTitle => 'Тривалість перегляду';

  @override
  String get settingFacePreviewSecondsDescription =>
      'Скільки часу перегляд залишається на екрані.';

  @override
  String get settingFacePreviewScaleTitle => 'Масштаб перегляду';

  @override
  String get settingFacePreviewScaleDescription =>
      'Масштабуйте розмір вікна перегляду відповідно до екрана.';

  @override
  String get settingFacePreviewPositionTitle => 'Розташування перегляду';

  @override
  String get settingFacePreviewPositionDescription =>
      'У якому кутку показувати вікно перегляду.';

  @override
  String get screensaverDetectionPreviewSection => 'Попередній перегляд камери';

  @override
  String get settingScreensaverEnabledTitle => 'Заставка';

  @override
  String get settingScreensaverEnabledDescription =>
      'Затемнення або вимкнення екрана після певного часу бездіяльності.';

  @override
  String get settingScreensaverTimeoutSecondsTitle =>
      'Час до заставки (секунди)';

  @override
  String get settingScreensaverTimeoutSecondsDescription =>
      'Час бездіяльності до вмикання заставки.';

  @override
  String get settingScreensaverModeTitle => 'Режим заставки';

  @override
  String get settingScreensaverModeDescription =>
      'Що показувати після закінчення часу бездіяльності. Режим \"Затемнення\" лише зменшує яскравість підсвічування, залишаючи панель на екрані.';

  @override
  String get settingScreensaverPixelShiftTitle => 'Зсув пікселів';

  @override
  String get settingScreensaverPixelShiftDescription =>
      'Зсувати зображення щохвилини для захисту матриць OLED. Не застосовується до чорної заставки, де пікселі вже вимкнено.';

  @override
  String get settingScreensaverMenuTitle => 'Показувати в меню кіоска';

  @override
  String get settingScreensaverMenuDescription =>
      'Додати пункт \"Запустити заставку\" до меню кіоска.';

  @override
  String get settingScreensaverDimLevelTitle => 'Рівень затемнення';

  @override
  String get settingScreensaverDimLevelDescription =>
      'Яскравість екрана в режимі затемнення.';

  @override
  String get settingScreensaverBrightnessEnabledTitle => 'Яскравість заставки';

  @override
  String get settingScreensaverBrightnessEnabledDescription =>
      'Використовувати окрему яскравість під час показу заставки.';

  @override
  String get settingScreensaverBrightnessLevelTitle => 'Рівень яскравості';

  @override
  String get settingScreensaverBrightnessLevelDescription =>
      'Застосовується до всіх режимів заставки, крім Затемнення та Чорного.';

  @override
  String get settingScreensaverNotificationBrightnessTitle =>
      'Підвищувати яскравість для сповіщень';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      'Знімати затемнення заставки під час відображення сповіщення.';

  @override
  String get settingScreensaverScreenOffMinutesTitle => 'Вимкнути екран через';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Повністю вимикає дисплей після зазначеного часу роботи заставки. Встановіть 0, щоб екран ніколи не згасав. Вимагає дозволу адміністратора пристрою.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Пробудження до заставки';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescription =>
      'Розпізнавання руху, обличчя чи наближення після вимкнення екрана відновлює заставку, а не панель, із новим відліком вимкнення екрана. Дотик все одно відкриває панель керування.';

  @override
  String get screensaverModeDim => 'Затемнення';

  @override
  String get screensaverModeBlack => 'Чорний';

  @override
  String get screensaverModeClock => 'Годинник';

  @override
  String get screensaverModeMedia => 'Медіа Home Assistant';

  @override
  String get screensaverModeLocal => 'Локальні медіа';

  @override
  String get screensaverModeGallery => 'Фотогалерея';

  @override
  String get screensaverModeImmich => 'Медіа Immich';

  @override
  String get screensaverModeWebsite => 'Вебсайт';

  @override
  String get screensaverModeCamera => 'Потоки камер';

  @override
  String get screensaverDimSection => 'Заставка із затемненням';

  @override
  String get screensaverWarningTitle => 'ПОПЕРЕДЖЕННЯ: Будь ласка, прочитайте!';

  @override
  String get screensaverScreenOffProceed => 'Все одно вимкнути екран';

  @override
  String get screensaverAdminMissing =>
      'Не надано дозвіл, тому екран не можна вимкнути.';

  @override
  String get screensaverAdminMissingRemote =>
      'Відсутній дозвіл адміністратора пристрою';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      'Без нього неможливо вимкнути екран. Діалог надання дозволу з\'явиться на екрані планшета.';

  @override
  String get screensaverDimWarning =>
      'ПОПЕРЕДЖЕННЯ: Затемнення залишає панель видимою, тому оптимізація \"Призупиняти панель під час заставки\" не застосовуватиметься, і вона продовжуватиме використовувати ресурси процесора та акумулятора.';

  @override
  String get screensaverUnavailablePlugin => 'Недоступний плагін заставки';

  @override
  String get screensaverScreenOffWarning =>
      'Коли дисплей повністю вимикається, керування переходить до системи енергозбереження планшета, і багато моделей Android можуть працювати нестабільно: Wi-Fi може відключатися, сутності Home Assistant ставати недоступними, доступ до камери може скасовуватися, а деякі пристрої можуть закривати фонові програми.\n\nНадійною альтернативою є Чорна заставка з цим параметром на 0: екран виглядає так само темно, а застосунок зберігає повний контроль.';

  @override
  String get settingScreensaverScreenOffBlackTitle =>
      'Використовувати чорний екран замість вимкнення';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      'Показувати чорний екран при нульовій яскравості замість повного вимкнення дисплея. Приховує віджети та \"Зараз грає\". Дозвіл адміністратора пристрою не потрібен.';

  @override
  String get settingScreensaverGlanceScaleTitle => 'Масштаб рядка';

  @override
  String get settingScreensaverGlanceScaleDescription =>
      'Масштабуйте рядок відповідно до розміру вашого екрана.';

  @override
  String get settingScreensaverGlanceFontTitle => 'Шрифт';

  @override
  String get settingScreensaverGlanceFontDescription =>
      'Гарнітура шрифту для відображення рядка.';

  @override
  String get settingScreensaverGlanceFontWeightTitle => 'Товщина шрифту';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      'Товщина тексту рядка. За замовчуванням використовуються звичайні назви та напівжирні значення.';

  @override
  String get settingScreensaverGlanceHideNamesTitle => 'Приховати назви';

  @override
  String get settingScreensaverGlanceHideNamesDescription =>
      'Показувати лише піктограму та значення збільшеним розміром.';

  @override
  String get settingScreensaverGlanceBwIconsTitle => 'Монохромні піктограми';

  @override
  String get settingScreensaverGlanceBwIconsDescription =>
      'Відображати всі піктограми нейтральним сірим кольором замість кольору їхнього стану.';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => 'Стиль плаваючого тексту';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      'Показувати сутності простим текстом замість плашок.';

  @override
  String get screensaverOverlayAppearance => 'Зовнішній вигляд';

  @override
  String get settingScreensaverGlanceEnabledTitle => 'Короткий огляд';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      'Показувати рядок зі станом сутностей Home Assistant на заставці.';

  @override
  String get settingScreensaverGlanceEntitiesTitle => 'Сутності';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      'До чотирьох сутностей для показу, кожна з можливістю власної назви.';

  @override
  String get settingScreensaverGlanceNowPlayingTitle =>
      'Показувати у \"Зараз грає\"';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      'Показувати рядок на повноекранному вигляді \"Зараз грає\". Він залишається прихованим під час показу тексту пісні.';

  @override
  String get screensaverOverlayShowing => 'Відображається';

  @override
  String get screensaverOverlayReorder =>
      'Відображається (перетягніть для зміни порядку)';

  @override
  String get screensaverOverlayFull =>
      'Це максимальна кількість сутностей у рядку. Видаліть одну, щоб додати іншу.';

  @override
  String get screensaverOverlayPickerTitle => 'Сутності короткого огляду';

  @override
  String screensaverOverlayGlanceEmpty(String count) {
    return 'Ще немає. Щонайбільше $count сутностей.';
  }

  @override
  String get screensaverOverlayNone => 'Ще немає';

  @override
  String screensaverOverlayLimit(String count) {
    return 'До $count сутностей.';
  }

  @override
  String get screensaverOverlayGlancePage => 'Короткий огляд';

  @override
  String get screensaverOverlayGlanceHint =>
      'Сутності, що показуються поверх заставки';

  @override
  String get glanceUnavailable => 'Недоступно';

  @override
  String get glanceUnknown => 'Невідомо';

  @override
  String get settingScreensaverImmichUrlTitle => 'Адреса сервера';

  @override
  String get settingScreensaverImmichUrlDescription =>
      'Адреса вашого сервера Immich разом із портом.';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'Ключ API';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      'Створюється в Immich у розділі Account Settings → API Keys.';

  @override
  String get screensaverMediaImmichPage => 'Заставка медіа Immich';

  @override
  String get screensaverMediaImmichHint =>
      'Сервер, медіа, слайд-шоу, метадані, фільтри';

  @override
  String get screensaverMediaServerConnection => 'Підключення до сервера';

  @override
  String get screensaverMediaValidateFailedLog =>
      'Помилка перевірки. Дивіться журнал програми щодо невдалого виклику.';

  @override
  String get screensaverMediaValidateFailed => 'Помилка перевірки.';

  @override
  String get screensaverMediaNoAnswer => 'Пристрій не відповів.';

  @override
  String get screensaverMediaAddressFirst => 'Спочатку введіть адресу сервера.';

  @override
  String get screensaverMediaKeyFirst => 'Спочатку введіть ключ API.';

  @override
  String get screensaverMediaBadAddress =>
      'Адреса сервера не є дійсною URL-адресою.';

  @override
  String get screensaverMediaKeyRejected => 'Ключ API відхилено.';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'У ключі API відсутній дозвіл $scope.';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'У ключі API відсутній дозвіл: $error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return 'Сервер відповів $status: $error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return 'Не вдалося зв\'язатися з $url.';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return 'Не вдалося зв\'язатися з сервером: $error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => 'Люди';

  @override
  String get settingScreensaverImmichPeopleDescription =>
      'Показувати лише медіа з будь-ким із цих людей.';

  @override
  String get settingScreensaverImmichExcludePeopleTitle => 'Виключити людей';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      'Пропускати медіа з будь-ким із цих людей.';

  @override
  String get settingScreensaverImmichTagsTitle => 'Теги';

  @override
  String get settingScreensaverImmichTagsDescription =>
      'Показувати лише медіа з будь-яким із цих тегів.';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => 'Виключити теги';

  @override
  String get settingScreensaverImmichExcludeTagsDescription =>
      'Пропускати медіа з будь-яким із цих тегів.';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => 'Лише улюблені';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      'Показувати лише медіа, позначені як улюблені.';

  @override
  String get settingScreensaverImmichTakenWithinTitle => 'Знято протягом';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      'Показувати лише медіа, зняті в цей період.';

  @override
  String get settingScreensaverImmichTakenFromTitle => 'Від';

  @override
  String get settingScreensaverImmichTakenFromDescription =>
      'Пропускати медіа, зняті раніше цієї дати.';

  @override
  String get settingScreensaverImmichTakenToTitle => 'До';

  @override
  String get settingScreensaverImmichTakenToDescription =>
      'Пропускати медіа, зняті після цієї дати. Сам день враховується.';

  @override
  String get screensaverMediaFilters => 'Фільтри';

  @override
  String get screensaverMediaAnyone => 'Будь-хто';

  @override
  String get screensaverMediaAnyoneDevice => 'Будь-хто.';

  @override
  String get screensaverMediaNoOne => 'Ніхто';

  @override
  String get screensaverMediaNoOneDevice => 'Ніхто.';

  @override
  String get screensaverMediaAny => 'Будь-які';

  @override
  String get screensaverMediaAnyDevice => 'Будь-які.';

  @override
  String get screensaverMediaNoTagsChosen => 'Без тегів';

  @override
  String get screensaverMediaNoTagsChosenDevice => 'Без тегів.';

  @override
  String get screensaverMediaNoPeople =>
      'Ще немає людей з іменами. Спочатку вкажіть їхні імена в Immich.';

  @override
  String get screensaverMediaNoTags =>
      'Ще немає тегів. Спочатку створіть їх в Immich.';

  @override
  String get screensaverMediaPeopleFailed => 'Не вдалося отримати список людей';

  @override
  String get screensaverMediaTagsFailed => 'Не вдалося отримати список тегів';

  @override
  String get screensaverMediaHidden => 'Приховано';

  @override
  String get screensaverMediaAnyTime => 'Будь-коли';

  @override
  String get screensaverMediaPastMonth => 'За останній місяць';

  @override
  String get screensaverMediaPast3Months => 'За останні 3 місяці';

  @override
  String get screensaverMediaPastYear => 'За останній рік';

  @override
  String get screensaverMediaPast2Years => 'За останні 2 роки';

  @override
  String get screensaverMediaPast5Years => 'За останні 5 років';

  @override
  String get screensaverMediaPast10Years => 'За останні 10 років';

  @override
  String get screensaverMediaSince => 'Починаючи з';

  @override
  String get screensaverMediaTimeframe => 'Часовий проміжок';

  @override
  String get screensaverMediaToday => 'Сьогодні';

  @override
  String get screensaverMediaDateFormat => 'Використовуйте РРРР-ММ-ДД.';

  @override
  String get screensaverMediaNotDate => 'Це не є датою.';

  @override
  String get settingScreensaverImmichMetadataTitle => 'Показувати метадані';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      'Альбом, дата, камера та місце поверх медіа.';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => 'Назва альбому';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription =>
      'Показувати, з якого альбому походить фото.';

  @override
  String get settingScreensaverImmichMetadataDateTitle => 'Дата зйомки';

  @override
  String get settingScreensaverImmichMetadataDateDescription =>
      'Показувати, коли було зроблено фото.';

  @override
  String get settingScreensaverImmichMetadataCameraTitle => 'Параметри камери';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      'Показувати фокусну відстань, діафрагму та ISO.';

  @override
  String get settingScreensaverImmichMetadataLocationTitle =>
      'Місцезнаходження';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      'Показувати місце, де було зроблено фото.';

  @override
  String get settingScreensaverImmichMetadataPositionTitle =>
      'Розташування метаданих';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      'У якому кутку показувати відомості.';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle => 'Тінь тексту';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      'Додати тінь до тексту метаданих для кращої читабельності на фотографіях.';

  @override
  String get settingScreensaverImmichMetadataScaleTitle => 'Масштаб тексту';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      'Масштабувати відомості фото відповідно до розміру екрана.';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle =>
      'Інтенсивність віньєтування';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      'Затемнення фону за відомостями для читабельності на яскравих фото. 0 вимикає його.';

  @override
  String get screensaverMediaMetadata => 'Метадані';

  @override
  String get screensaverMediaTopLeft => 'Зверху ліворуч';

  @override
  String get screensaverMediaTopRight => 'Зверху праворуч';

  @override
  String get screensaverMediaBottomLeft => 'Знизу ліворуч';

  @override
  String get screensaverMediaBottomRight => 'Знизу праворуч';

  @override
  String get settingScreensaverImmichIntervalTitle => 'Секунд на зображення';

  @override
  String get settingScreensaverImmichIntervalDescription =>
      'Скільки часу кожне зображення показується перед наступним. Відео відтворюються повністю.';

  @override
  String get settingScreensaverImmichShuffleTitle => 'Випадковий порядок';

  @override
  String get settingScreensaverImmichShuffleDescription =>
      'Показувати медіа у випадковому порядку.';

  @override
  String get settingScreensaverImmichTransitionTitle => 'Перехід';

  @override
  String get settingScreensaverImmichTransitionDescription =>
      'Як один елемент змінює інший.';

  @override
  String get settingScreensaverImmichFillTitle => 'Заповнювати екран';

  @override
  String get settingScreensaverImmichFillDescription =>
      'Вимкнено залишає фото повністю між чорними смугами. Розумне збільшує фото, близькі за пропорціями до екрана, розміщуючи решту на розмитому фоні. Завжди масштабує кожне фото, обрізаючи зайве.';

  @override
  String get settingScreensaverImmichPairPortraitTitle =>
      'Об\'єднувати портретні фото';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      'Показувати два портретні фото поруч, щоб заповнити екран.';

  @override
  String get settingScreensaverImmichPairLandscapeTitle =>
      'Об\'єднувати альбомні фото';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      'Показувати два альбомні фото одне над іншим, щоб заповнити вертикальний екран.';

  @override
  String get settingScreensaverImmichEdgeTapsTitle =>
      'Торкання країв для зміни слайдів';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      'Торкання лівої або правої п\'ятої частини екрана показує попередній або наступний слайд замість закриття заставки.';

  @override
  String get screensaverMediaSlideshow => 'Слайд-шоу';

  @override
  String get settingScreensaverImmichAlbumTitle => 'Джерело медіа';

  @override
  String get settingScreensaverImmichAlbumDescription =>
      'Уся бібліотека або вибрані вами альбоми.';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => 'Лише фото';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription =>
      'Пропускати відео в слайд-шоу.';

  @override
  String get settingScreensaverImmichCacheTitle => 'Кешувати медіа локально';

  @override
  String get settingScreensaverImmichCacheDescription =>
      'Зберігати копії на пристрої для миттєвого завантаження зображень.';

  @override
  String get settingScreensaverImmichCacheMaxTitle => 'Розмір кешу (елементів)';

  @override
  String get settingScreensaverImmichCacheMaxDescription =>
      'Найстаріші елементи видаляються після заповнення кешу.';

  @override
  String get screensaverMediaAll => 'Усі медіа';

  @override
  String get screensaverMediaAllDevice => 'Усі медіа.';

  @override
  String get screensaverMediaNoAlbums =>
      'Ще немає альбомів. Спочатку створіть альбом в Immich.';

  @override
  String get screensaverMediaAlbumsFailed =>
      'Не вдалося отримати список альбомів';

  @override
  String screensaverMediaListError(String error) {
    return 'Не вдалося отримати список: $error';
  }

  @override
  String get screensaverMediaListingFailed => 'не вдалося отримати список';

  @override
  String screensaverMediaItems(String count) {
    return '$count елементів';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return '$count у кеші, $size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => 'Вигляди камер';

  @override
  String get settingScreensaverCameraViewsDescription =>
      'Вигляди камер, які показує заставка, у цьому порядку.';

  @override
  String get settingScreensaverCameraViewSecondsTitle =>
      'Секунд на вигляд камери';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      'Скільки часу кожен вигляд залишається на екрані перед наступним. Якщо вибрано один вигляд, ротація не відбувається.';

  @override
  String get settingScreensaverCameraMuteTitle => 'Вимкнути звук для всіх';

  @override
  String get settingScreensaverCameraMuteDescription =>
      'Вимикає звук для всіх виглядів, навіть для однієї камери.';

  @override
  String get screensaverMediaCameraPage => 'Заставка трансляцій камер';

  @override
  String get screensaverMediaCameraHint =>
      'Вигляди для показу, секунд на вигляд, звук';

  @override
  String get screensaverMediaNoCameras =>
      'Жоден вигляд ще не містить камер. Додайте камеру в меню Потоки камер.';

  @override
  String get screensaverMediaNoCamerasRemote =>
      'Жоден вигляд ще не містить камер';

  @override
  String get screensaverMediaAddCameras =>
      'Додайте камеру в меню Потоки камер.';

  @override
  String get screensaverMediaNoViews =>
      'Ще немає. Виберіть вигляди, які циклічно змінюватиме заставка.';

  @override
  String get screensaverMediaRotation =>
      'У ротації (перетягніть для зміни порядку)';

  @override
  String get screensaverMediaAvailable => 'Доступні';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count камера';
  }

  @override
  String screensaverMediaCameras(String count) {
    return '$count камер';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return 'Позиція $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => 'Немає';

  @override
  String get screensaverMediaTransitionFade => 'Плавне згасання';

  @override
  String get screensaverMediaTransitionSlide => 'Зсув';

  @override
  String get screensaverMediaTransitionZoom => 'Масштабування';

  @override
  String get screensaverMediaTransitionKenBurns => 'Ефект Кена Бернса';

  @override
  String get screensaverMediaTransitionRandom => 'Випадковий';

  @override
  String get screensaverMediaFillOff => 'Вимкнено';

  @override
  String get screensaverMediaFillSmart => 'Розумне';

  @override
  String get screensaverMediaFillAlways => 'Завжди';

  @override
  String get settingScreensaverGalleryItemsTitle => 'Фотографії';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'Фотографії та відео для показу в цій заставці. Вибираються з галереї на пристрої; повторний вибір замінює вибране.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Секунд на фото';

  @override
  String get settingScreensaverGalleryIntervalDescription =>
      'Скільки часу кожне фото показується перед наступним. Відео відтворюються повністю.';

  @override
  String get settingScreensaverGalleryShuffleTitle => 'Випадковий порядок';

  @override
  String get settingScreensaverGalleryShuffleDescription =>
      'Показувати вибране у випадковому порядку.';

  @override
  String get settingScreensaverGalleryTransitionTitle => 'Перехід';

  @override
  String get settingScreensaverGalleryTransitionDescription =>
      'Як одне фото змінює інше.';

  @override
  String get settingScreensaverGalleryFillTitle => 'Заповнювати екран';

  @override
  String get settingScreensaverGalleryFillDescription =>
      'Вимкнено залишає фото повністю між чорними смугами. Розумне збільшує фото, близькі за пропорціями до екрана, розміщуючи решту на розмитому фоні. Завжди масштабує кожне фото, обрізаючи зайве.';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle =>
      'Торкання країв для зміни слайдів';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      'Торкання лівої або правої п\'ятої частини екрана показує попередній або наступний слайд замість закриття заставки.';

  @override
  String get screensaverMediaGalleryPage => 'Заставка галереї фото';

  @override
  String get screensaverMediaGalleryHint =>
      'Фотографії, тривалість, випадковий порядок, перехід';

  @override
  String get screensaverMediaLoadingPhotos => 'Завантаження фото...';

  @override
  String screensaverMediaCopying(String index, String total) {
    return 'Копіювання фото $index з $total...';
  }

  @override
  String get screensaverMediaCopyFailed => 'Не вдалося скопіювати фото';

  @override
  String get screensaverMediaSmallerSelection =>
      'Спробуйте вибрати меншу кількість.';

  @override
  String get screensaverMediaNoPhotos => 'Фотографії не вибрано';

  @override
  String screensaverMediaSelected(String count) {
    return 'Вибрано $count';
  }

  @override
  String get screensaverMediaPickOnDevice =>
      'Нічого не вибрано. Виберіть на пристрої.';

  @override
  String get settingScreensaverMediaIdTitle => 'Джерело медіа';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Медіаелемент Home Assistant, папка або камера. Натисніть Огляд, щоб вибрати.';

  @override
  String get settingScreensaverMediaIntervalTitle => 'Секунд на зображення';

  @override
  String get settingScreensaverMediaIntervalDescription =>
      'Скільки часу кожне зображення показується перед наступним. Відео відтворюються повністю.';

  @override
  String get settingScreensaverMediaShuffleTitle => 'Випадковий порядок';

  @override
  String get settingScreensaverMediaShuffleDescription =>
      'Відтворювати папку у випадковому порядку.';

  @override
  String get settingScreensaverMediaRecursiveTitle => 'Включати вкладені папки';

  @override
  String get settingScreensaverMediaRecursiveDescription =>
      'Переходити у вкладені папки, коли вибрано папку.';

  @override
  String get settingScreensaverMediaTransitionTitle => 'Перехід';

  @override
  String get settingScreensaverMediaTransitionDescription =>
      'Як один елемент змінює інший.';

  @override
  String get settingScreensaverMediaFillTitle => 'Заповнювати екран';

  @override
  String get settingScreensaverMediaFillDescription =>
      'Вимкнено залишає фото повністю між чорними смугами. Розумне збільшує фото, близькі за пропорціями до екрана, розміщуючи решту на розмитому фоні. Завжди масштабує кожне фото, обрізаючи зайве.';

  @override
  String get settingScreensaverMediaEdgeTapsTitle =>
      'Торкання країв для зміни слайдів';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      'Торкання лівої або правої п\'ятої частини екрана показує попередній або наступний слайд замість закриття заставки.';

  @override
  String get screensaverMediaHaPage => 'Заставка медіа Home Assistant';

  @override
  String get screensaverMediaHaHint =>
      'Джерело медіа, тривалість, випадковий порядок, заповнення';

  @override
  String get screensaverMediaChoose => 'Вибрати медіа';

  @override
  String get screensaverMediaRoot => 'Медіа';

  @override
  String get screensaverMediaHaUnavailable =>
      'Не вдалося зв\'язатися з Home Assistant, або відсутній токен.';

  @override
  String get screensaverMediaEmpty => 'Тут нічого немає.';

  @override
  String get screensaverMediaUseFolder => 'Використовувати цю папку';

  @override
  String get screensaverMediaFolder => 'папка';

  @override
  String get screensaverMediaCamera => 'камера';

  @override
  String get screensaverMediaItem => 'елемент';

  @override
  String get screensaverMediaBrowseFailed => 'не вдалося відкрити';

  @override
  String screensaverMediaBrowseError(String error) {
    return 'Не вдалося переглянути: $error';
  }

  @override
  String get screensaverMediaNotSet => 'Не налаштовано';

  @override
  String get settingScreensaverLocalFolderTitle => 'Локальна папка';

  @override
  String get settingScreensaverLocalFolderDescription =>
      'Папка на цьому пристрої, фотографії та відео з якої циклічно показує заставка. Вибирається на пристрої; шлях також можна ввести тут віддалено.';

  @override
  String get settingScreensaverLocalIntervalTitle => 'Секунд на фото';

  @override
  String get settingScreensaverLocalIntervalDescription =>
      'Скільки часу кожне фото показується перед наступним. Відео відтворюються повністю.';

  @override
  String get settingScreensaverLocalShuffleTitle => 'Випадковий порядок';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      'Показувати вміст папки у випадковому порядку замість сортування за назвою.';

  @override
  String get settingScreensaverLocalRecursiveTitle => 'Включати вкладені папки';

  @override
  String get settingScreensaverLocalRecursiveDescription =>
      'Також показувати фотографії та відео у вкладених папках.';

  @override
  String get settingScreensaverLocalTransitionTitle => 'Перехід';

  @override
  String get settingScreensaverLocalTransitionDescription =>
      'Як одне фото змінює інше.';

  @override
  String get settingScreensaverLocalFillTitle => 'Заповнювати екран';

  @override
  String get settingScreensaverLocalFillDescription =>
      'Вимкнено залишає фото повністю між чорними смугами. Розумне збільшує фото, близькі за пропорціями до екрана, розміщуючи решту на розмитому фоні. Завжди масштабує кожне фото, обрізаючи зайве.';

  @override
  String get settingScreensaverLocalEdgeTapsTitle =>
      'Торкання країв для зміни слайдів';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      'Торкання лівої або правої п\'ятої частини екрана показує попередній або наступний слайд замість закриття заставки.';

  @override
  String get screensaverMediaLocalPage => 'Заставка локальних медіа';

  @override
  String get screensaverMediaLocalHint =>
      'Папка, тривалість, випадковий порядок, перехід';

  @override
  String get settingScreensaverDismissOnMotionTitle => 'Вихід за рухом';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      'Відстежувати камеру під час заставки та вмикати екран при наближенні людини. Камера працює лише під час заставки.';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle =>
      'Лише коли екран вимкнено';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      'Залишати заставку видимою, коли виявлено рух при увімкненому екрані. Після вимкнення екрана виявлення активує панель. Дотик все одно закриває заставку.';

  @override
  String get settingScreensaverPostponeOnMotionTitle =>
      'Відкладати заставку при русі';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      'Відкладати запуск заставки при виявленні руху. ПОПЕРЕДЖЕННЯ: камера працюватиме постійно.';

  @override
  String get screensaverDetectionMotionPage => 'Виявлення руху';

  @override
  String get screensaverDetectionMotionHint =>
      'Закриття або відкладання заставки за рухом';

  @override
  String get screensaverDetectionMotionTuning =>
      'Чутливість виявлення руху налаштовується в параметрах Камери.';

  @override
  String get settingScreensaverDismissOnPersonTitle =>
      'Вихід при виявленні людини';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      'Зчитувати дані датчика присутності пристрою під час заставки та активувати екран, коли перед ним з\'являється людина. Потрібен дозвіл на доступ до журналів нижче.';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle =>
      'Лише коли екран вимкнено';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      'Залишати заставку видимою, коли хтось підходить при увімкненому екрані. Після вимкнення екрана виявлення активує панель. Дотик все одно закриває заставку.';

  @override
  String get settingScreensaverPostponeOnPersonTitle =>
      'Відкладати заставку при виявленні людини';

  @override
  String get settingScreensaverPostponeOnPersonDescription =>
      'Відкладати запуск заставки, доки перед пристроєм хтось є.';

  @override
  String get screensaverDetectionPersonPage => 'Виявлення людей';

  @override
  String get screensaverDetectionPersonHint =>
      'Закриття або відкладання заставки за датчиком присутності';

  @override
  String get screensaverDetectionOccupancy => 'Присутність';

  @override
  String get screensaverDetectionStatusUnavailable => 'Статус недоступний.';

  @override
  String get screensaverDetectionOff => 'Вимкнено.';

  @override
  String get screensaverDetectionStarting => 'Запуск...';

  @override
  String get screensaverDetectionWaiting =>
      'Очікування першого сигналу. Датчик повідомляє кожні 30 секунд, поки хтось перебуває в полі зору.';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return 'Останній сигнал $ago.';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return '$count с тому';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return '$count хв тому';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return '$count год тому';
  }

  @override
  String get screensaverDetectionDetected => 'Виявлено';

  @override
  String get screensaverDetectionClear => 'Вільно';

  @override
  String get screensaverDetectionPermissions => 'Необхідні системні дозволи';

  @override
  String get screensaverDetectionLogAccess => 'Доступ до журналів';

  @override
  String get screensaverDetectionChecking => 'Перевірка...';

  @override
  String get screensaverDetectionReadable =>
      'Датчик присутності пристрою можна зчитувати.';

  @override
  String get screensaverDetectionRestartRequired =>
      'Надано. Перезапустіть Kiosk Satellite, щоб застосувати.';

  @override
  String get screensaverDetectionGrantHelp =>
      'Цей дозвіл можна надати лише через ADB. Повна команда наведена в документації Meta Portal. Після цього перезапустіть Kiosk Satellite.';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      'Цей дозвіл можна надати лише через ADB. Нижче наведено готову для копіювання команду. Після цього перезапустіть Kiosk Satellite.';

  @override
  String get screensaverDetectionGranted => 'Надано';

  @override
  String get screensaverDetectionMissing => 'Відсутній';

  @override
  String get screensaverDetectionRestart => 'Перезапустити';

  @override
  String get screensaverDetectionRestartRemote => 'Перезапустити на пристрої';

  @override
  String get screensaverDetectionLogRestart =>
      'Доступ до журналів надано, але він набуде чинності після перезапуску Kiosk Satellite.';

  @override
  String get screensaverDetectionLogMissing => 'Доступ до журналів не надано.';

  @override
  String get settingScreensaverDismissOnProximityTitle =>
      'Вихід за наближенням';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      'Відстежувати датчик наближення під час заставки та активувати екран при наближенні об\'єкта. Пристрої лише з датчиками для дзвінків (\"palm\", \"touch\") не підтримуються.';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle =>
      'Лише коли екран вимкнено';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      'Залишати заставку видимою, коли щось наближається при увімкненому екрані. Після вимкнення екрана виявлення активує панель. Дотик все одно закриває заставку.';

  @override
  String get settingScreensaverPostponeOnProximityTitle =>
      'Відкладати заставку при наближенні';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      'Відкладати запуск заставки, доки щось перебуває поруч із датчиком.';

  @override
  String get screensaverDetectionProximityPage => 'Виявлення наближення';

  @override
  String get screensaverDetectionProximityHint =>
      'Закриття або відкладання заставки за датчиком наближення';

  @override
  String get screensaverDetectionNoProximity =>
      'Недоступно на цьому пристрої: відсутній датчик наближення.';

  @override
  String get screensaverDetectionSensor => 'Датчик';

  @override
  String get screensaverDetectionSensorHelp =>
      'Тип датчика, про який повідомляє пристрій. Датчик для дзвінків з назвою \"palm\" або \"touch\" не працюватиме.';

  @override
  String get settingScreensaverScheduleEnabledTitle =>
      'Увімкнути заставки за розкладом';

  @override
  String get settingScreensaverScheduleEnabledDescription =>
      'Змінювати заставку у визначений час доби.';

  @override
  String get settingScreensaverScheduleTitle => 'Час';

  @override
  String get settingScreensaverScheduleDescription =>
      'Кожен запис часу визначає подальшу заставку.';

  @override
  String get screensaverScheduleSection => 'Заставки за розкладом';

  @override
  String get screensaverTime => 'Час';

  @override
  String get screensaverAddTime => 'Додати час';

  @override
  String get screensaverRemoveTime => 'Видалити час';

  @override
  String get screensaverNoTimes => 'Час ще не налаштовано';

  @override
  String get screensaverTimeHelp => 'Заставка, яка діятиме з цього моменту.';

  @override
  String get screensaverPickTime => 'Виберіть час.';

  @override
  String get screensaverDefault => 'За замовчуванням';

  @override
  String get screensaverOn => 'Увімкнено';

  @override
  String get screensaverOff => 'Вимкнено';

  @override
  String get screensaverBrightness => 'Яскравість';

  @override
  String get screensaverBrightnessFollow =>
      'Відповідає загальному налаштуванню яскравості заставки.';

  @override
  String get screensaverBrightnessExceptBlack =>
      'Застосовується до всіх режимів, крім чорного екрана.';

  @override
  String get screensaverScreenOffFollow =>
      'Відповідає налаштуванню вимкнення екрана.';

  @override
  String get screensaverScreenOnHours =>
      'Залишає екран увімкненим у ці години.';

  @override
  String get screensaverScreenOffHelp =>
      'Вимикає живлення дисплея після зазначеного часу роботи заставки. Потрібен дозвіл адміністратора пристрою.';

  @override
  String get screensaverScreenOffNever => 'Ніколи не вимикати екран';

  @override
  String get screensaverMotion => 'Вихід за рухом';

  @override
  String get screensaverFace => 'Вихід за обличчям';

  @override
  String get screensaverProximity => 'Вихід за наближенням';

  @override
  String get screensaverPerson => 'Вихід за людиною';

  @override
  String get screensaverWidgets => 'Віджети';

  @override
  String get screensaverGlance => 'Короткий огляд';

  @override
  String get screensaverNowPlaying =>
      'Показувати Зараз грає поруч із заставкою';

  @override
  String get screensaverNowPlayingHelp =>
      'За замовчуванням використовує загальний макет. Увімкнено застосовує спільний макет, якщо функцію увімкнено. Вимкнено приховує Зараз грає у ці години.';

  @override
  String get screensaverCameraRequired =>
      'Потрібна камера. Спочатку увімкніть її в налаштуваннях камери.';

  @override
  String get screensaverNotAvailable => 'Недоступно на цьому пристрої.';

  @override
  String get screensaverSummaryMotionOn => 'Рух увімкнено';

  @override
  String get screensaverSummaryMotionOff => 'Рух вимкнено';

  @override
  String get screensaverSummaryFaceOn => 'Обличчя увімкнено';

  @override
  String get screensaverSummaryFaceOff => 'Обличчя вимкнено';

  @override
  String get screensaverSummaryProximityOn => 'Наближення увімкнено';

  @override
  String get screensaverSummaryProximityOff => 'Наближення вимкнено';

  @override
  String get screensaverSummaryPersonOn => 'Людина увімкнено';

  @override
  String get screensaverSummaryPersonOff => 'Людина вимкнено';

  @override
  String get screensaverSummaryWidgetsOn => 'Віджети увімкнено';

  @override
  String get screensaverSummaryWidgetsOff => 'Віджети вимкнено';

  @override
  String get screensaverSummaryGlanceOn => 'Короткий огляд увімкнено';

  @override
  String get screensaverSummaryGlanceOff => 'Короткий огляд вимкнено';

  @override
  String get screensaverSummaryNowPlayingOn => 'Зараз грає увімкнено';

  @override
  String get screensaverSummaryNowPlayingOff => 'Зараз грає вимкнено';

  @override
  String screensaverBrightnessPercent(String percent) {
    return '$percent% яскравості';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return 'Вимкнення екрана через $minutes хв';
  }

  @override
  String get screensaverWeatherMood => 'Настрій погоди';

  @override
  String get screensaverWeatherMoodPage => 'Заставка настрою погоди';

  @override
  String get screensaverWeatherMoodSummary =>
      'Об\'єкт погоди, блискавка, попередній перегляд';

  @override
  String get settingScreensaverWeatherEntityTitle => 'Об\'єкт погоди';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      'Об\'єкт погоди Home Assistant, який керує анімованою сценою. День, світанок/сутінки та ніч визначаються за sun.sun, з локальним часом як резервним варіантом.';

  @override
  String get settingScreensaverWeatherLightningTitle => 'Спалахи блискавки';

  @override
  String get settingScreensaverWeatherLightningDescription =>
      'Показувати удари та спалахи блискавки під час грози.';

  @override
  String get screensaverWeatherMoodSelectEntity =>
      'Виберіть об\'єкт погоди в меню Налаштування > Заставка > Настрій погоди.';

  @override
  String get screensaverWeatherPreviewGroup => 'Попередній перегляд погоди';

  @override
  String get settingScreensaverWeatherPreviewTitle =>
      'Увімкнути попередній перегляд';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      'Показувати вибрану сцену замість поточної погоди. Вимкніть для синхронізації з Home Assistant.';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => 'Тип погоди';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      'Анімована сцена погоди для попереднього перегляду.';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle => 'Час доби';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      'Виберіть версію сцени для дня, світанку/сутінків або ночі.';

  @override
  String get screensaverWeatherPreviewSunny => 'Ясно';

  @override
  String get screensaverWeatherPreviewPartlycloudy => 'Мінлива хмарність';

  @override
  String get screensaverWeatherPreviewCloudy => 'Хмарно';

  @override
  String get screensaverWeatherPreviewRainy => 'Дощ';

  @override
  String get screensaverWeatherPreviewPouring => 'Злива';

  @override
  String get screensaverWeatherPreviewSnowy => 'Сніг';

  @override
  String get screensaverWeatherPreviewSnowyRainy => 'Сніг з дощем';

  @override
  String get screensaverWeatherPreviewFog => 'Туман';

  @override
  String get screensaverWeatherPreviewHail => 'Град';

  @override
  String get screensaverWeatherPreviewLightning => 'Блискавка';

  @override
  String get screensaverWeatherPreviewLightningRainy => 'Гроза з дощем';

  @override
  String get screensaverWeatherPreviewWindy => 'Вітер';

  @override
  String get screensaverWeatherPreviewWindyVariant => 'Вітер і хмари';

  @override
  String get screensaverWeatherPreviewExceptional => 'Незвичні погодні умови';

  @override
  String get screensaverWeatherPreviewDay => 'День';

  @override
  String get screensaverWeatherPreviewNight => 'Ніч';

  @override
  String get settingScreensaverWeatherClockTitle => 'Увімкнути годинник';

  @override
  String get settingScreensaverWeatherClockDescription =>
      'Показувати цифровий годинник поверх погодної сцени.';

  @override
  String get screensaverWeatherTextShadowDescription =>
      'Додати тінь до тексту для кращої читабельності поверх погодної сцени.';

  @override
  String get screensaverWeatherBarGroup => 'Погодна інформація';

  @override
  String get settingScreensaverWeatherBarTitle => 'Увімкнути панель погоди';

  @override
  String get settingScreensaverWeatherBarDescription =>
      'Показувати актуальну інформацію про погоду внизу екрана.';

  @override
  String get settingScreensaverWeatherBarScaleTitle => 'Масштаб тексту';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      'Масштабувати інформацію про погоду від 50 до 200 відсотків.';

  @override
  String get settingScreensaverWeatherBarColorTitle => 'Колір тексту';

  @override
  String get settingScreensaverWeatherBarColorDescription =>
      'Колір погодної інформації.';

  @override
  String get settingScreensaverWeatherBarOpacityTitle => 'Непрозорість фону';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      'Затемнювати нижню панель, щоб погодна інформація залишалася розбірливою.';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => 'Показувати заголовки';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      'Підписувати кожен показник над його значенням. Без заголовків значення мають розмір температури.';

  @override
  String get screensaverWeatherBarHumidityDescription =>
      'Показувати вологість, коли погодний об\'єкт повідомляє її.';

  @override
  String get screensaverWeatherBarWindDescription =>
      'Показувати швидкість вітру, коли погодний об\'єкт повідомляє її.';

  @override
  String get screensaverWeatherBarVisibilityDescription =>
      'Показувати видимість, коли погодний об\'єкт повідомляє її.';

  @override
  String get settingScreensaverWeatherBlurTitle => 'Розмиття сцени';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      'Пом\'якшити анімовану погодну сцену, зберігаючи годинник, панель погоди та віджети чіткими.';

  @override
  String get screensaverWeatherPreviewTwilight => 'Світанок/Сутінки';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      'Показувати відчутну температуру замість фактичної, коли вона доступна.';

  @override
  String get settingScreensaverWebsiteUrlTitle => 'URL-адреса вебсайту';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      'Сторінка для повноекранного показу. Вона має підтримувати вбудовування.';

  @override
  String get settingScreensaverWebsiteZoomTitle => 'Рівень масштабування';

  @override
  String get settingScreensaverWebsiteZoomDescription =>
      'Масштабує всю зовнішню вебсторінку заставки.';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle =>
      'Подвійний дотик для закриття';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription =>
      'Одинарні дотики взаємодіють із сайтом замість закриття заставки.';

  @override
  String get screensaverWebsiteSection => 'Заставка вебсайту';

  @override
  String get screensaverOverlaySmallClock => 'Маленький годинник';

  @override
  String get screensaverOverlayWeather => 'Погода';

  @override
  String get screensaverOverlayBattery => 'Акумулятор';

  @override
  String get screensaverOverlayClockNote =>
      'Приховано в режимах заставки Цифровий годинник та Потоки камер.';

  @override
  String get screensaverOverlayCameraNote =>
      'Приховано в режимі заставки Потоки камер.';

  @override
  String get screensaverOverlayScale => 'Масштаб';

  @override
  String get screensaverOverlayScaleHelp =>
      'Масштабувати розмір цього віджета відповідно до розміру екрана.';

  @override
  String get screensaverOverlayFont => 'Шрифт';

  @override
  String get screensaverOverlayCorner => 'Кут';

  @override
  String get screensaverOverlayWidget => 'Віджет';

  @override
  String get screensaverOverlayClock24 => '24-годинний формат';

  @override
  String get screensaverOverlayClock24Help =>
      'Показувати час у 24-годинному форматі замість AM/PM.';

  @override
  String get screensaverOverlayShowDate => 'Показувати дату';

  @override
  String get screensaverOverlayShowDateHelp =>
      'Додати коротку дату під годинником.';

  @override
  String get screensaverOverlayPercentage => 'Показувати відсотки';

  @override
  String get screensaverOverlayPercentageHelp =>
      'Рівень заряду поруч із піктограмою.';

  @override
  String get screensaverOverlayLow => 'Лише за низького заряду';

  @override
  String get screensaverOverlayLowHelp =>
      'Залишатися прихованим, доки заряд не знизиться до 20 відсотків.';

  @override
  String get screensaverOverlayShowName => 'Показувати назву';

  @override
  String get screensaverOverlayShowNameHelp => 'Назва під значенням.';

  @override
  String get screensaverOverlayFontSystem => 'Системний';

  @override
  String get screensaverOverlayFontSerif => 'Із зарубками';

  @override
  String get screensaverOverlayFontCondensed => 'Вузький';

  @override
  String get screensaverOverlayFontMonospace => 'Моноширинний';

  @override
  String get screensaverOverlayFontCasual => 'Рукописний';

  @override
  String get screensaverOverlayFontCursive => 'Курсив';

  @override
  String get screensaverOverlayColor => 'Колір';

  @override
  String get screensaverOverlayWeatherEntity => 'Об\'єкт погоди';

  @override
  String get screensaverOverlayNoWeather => 'Немає об\'єктів погоди';

  @override
  String get screensaverOverlayNoWeatherHelp =>
      'Home Assistant не повідомив про жоден об\'єкт.';

  @override
  String get screensaverOverlayPickWeather => 'Виберіть об\'єкт погоди...';

  @override
  String get screensaverOverlayWeatherRequired => 'Виберіть об\'єкт погоди.';

  @override
  String get screensaverOverlayLocationName => 'Назва місця';

  @override
  String get screensaverOverlayLocationHelp =>
      'Залиште порожнім, щоб приховати рядок розташування.';

  @override
  String get screensaverOverlayLocation => 'Місце';

  @override
  String get screensaverOverlayLocationDetail =>
      'Назва місця над температурою.';

  @override
  String get screensaverOverlayFeelsLike => 'Відчувається як';

  @override
  String get screensaverOverlayFeelsLikeHelp =>
      'Показувати відчутну температуру окремим підписаним рядком під фактичною температурою.';

  @override
  String get screensaverOverlayFeelsLikeOnly => 'Лише відчувається як';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp =>
      'Показувати відчутну температуру з підписом «Відчувається як» замість фактичної температури.';

  @override
  String get screensaverOverlayForecast => 'Прогноз';

  @override
  String get screensaverOverlayForecastHelp =>
      'Погодні умови з відповідною піктограмою.';

  @override
  String get screensaverOverlayHumidity => 'Вологість';

  @override
  String get screensaverOverlayWind => 'Швидкість вітру';

  @override
  String get screensaverOverlayVisibility => 'Видимість';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return 'Відчувається як $temperature';
  }

  @override
  String get settingScreensaverWidgetsTitle => 'Віджети';

  @override
  String get settingScreensaverWidgetsDescription =>
      'Невеликі накладення в кутах заставки.';

  @override
  String get settingScreensaverWidgetScaleTitle =>
      'Загальне масштабування віджетів';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      'Масштабувати всі віджети разом відповідно до розміру екрана. Кожен віджет зберігає свій власний відносний масштаб.';

  @override
  String get settingScreensaverWidgetFontTitle => 'Загальний шрифт';

  @override
  String get settingScreensaverWidgetFontDescription =>
      'Гарнітура для всіх віджетів. Віджет може використовувати власний шрифт.';

  @override
  String get settingScreensaverWidgetFontWeightTitle =>
      'Загальна товщина шрифту';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      'Товщина тексту для всіх віджетів. За замовчуванням визначається кожним рядком окремо. Віджет може задавати власну товщину.';

  @override
  String get settingScreensaverWidgetTextShadowTitle => 'Тінь тексту';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      'Додати тінь до тексту віджетів для читабельності на фотографіях.';

  @override
  String get settingScreensaverVignetteStrengthTitle =>
      'Інтенсивність віньєтування';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      'Затемнення фону за віджетами для читабельності на яскравих фото. 0 вимикає його.';

  @override
  String get screensaverOverlayWidgetsEmpty => 'Віджетів ще немає';

  @override
  String get screensaverOverlayRemove => 'Видалити віджет';

  @override
  String get screensaverOverlayAdd => 'Додати віджет';

  @override
  String get screensaverOverlayAddHelp =>
      'Маленький годинник, погода, акумулятор або об\'єкт у кутку.';

  @override
  String get screensaverOverlayWidgetsHint =>
      'Накладення в кутах та їх масштаб';

  @override
  String get settingsSearchHint => 'Пошук у налаштуваннях';

  @override
  String get settingsSearchClear => 'Очистити пошук';

  @override
  String get settingsSearchResults => 'Результати пошуку';

  @override
  String settingsSearchEmpty(String query) {
    return 'Немає налаштувань, що відповідають \"$query\".';
  }

  @override
  String get searchInstallApk =>
      'Завантажити APK Kiosk Satellite через віддалене адміністрування та встановити його.';

  @override
  String get searchPermissionsHelp =>
      'Усі дозволи Android, які може використовувати програма, та їхній стан: мікрофон, камера, сповіщення, необмежена робота від батареї, показ поверх інших програм, зміна системних налаштувань, захист системного інтерфейсу, адміністратор пристрою, доступ до всіх файлів, доступ до статистики використання та місцезнаходження.';

  @override
  String get searchServiceStatus => 'Стан служби';

  @override
  String get searchServiceHelp =>
      'Чи працює служба Kiosk Satellite та що саме вона підтримує активним.';

  @override
  String get searchServicePermissions =>
      'Дозволи, необхідні для роботи служби Kiosk Satellite.';

  @override
  String get searchIntercomKiosks =>
      'Відомі кіоски та можливість кожного з них приймати виклики.';

  @override
  String get searchHaValidate =>
      'Перевірити URL-адресу та токен для підключення до Home Assistant.';

  @override
  String get searchHaProxy =>
      'Транслювати Home Assistant через звичайний HTTP за допомогою захищеного проксі всередині програми.';

  @override
  String get searchHaDashboard =>
      'Вибрати панель керування та вигляд для показу на кіоску.';

  @override
  String get searchKioskPermissions =>
      'Дозволи, на які спираються засоби захисту кіоска та блокування.';

  @override
  String get searchHomeStatus => 'Стан головного екрана';

  @override
  String get searchHomeHelp =>
      'Чи є Kiosk Satellite головним екраном пристрою, та де завершити його вибір за замовчуванням.';

  @override
  String get searchMasterVolume =>
      'Гучність пристрою, відносно якої регулюються повзунки медіа та асистента.';

  @override
  String get searchSmallClock => 'Віджет годинника в кутку заставки.';

  @override
  String get searchBattery =>
      'Віджет акумулятора в кутку заставки: рівень заряду цього пристрою.';

  @override
  String get searchPersonPermission =>
      'Дозвіл на доступ до журналів, необхідний для датчика присутності пристрою.';

  @override
  String get searchSonosSpeakers =>
      'Відомі пристрою колонки Sonos, пошук у мережі та поле введення адреси.';

  @override
  String get voiceAppearanceHint =>
      'Оформлення накладення, тема, смуга активності, розмір тексту';

  @override
  String get voiceSkin => 'Оформлення';

  @override
  String get voiceSkinHelp => 'Вигляд накладення голосового асистента.';

  @override
  String get voiceTheme => 'Тема';

  @override
  String get voiceThemeHelp => 'Світле або темне відображення накладення.';

  @override
  String get voiceReactive => 'Реактивна смуга активності';

  @override
  String get voiceReactiveHelp =>
      'Смуга активності реагує на звук. НЕ РЕКОМЕНДУЄТЬСЯ для малопотужних пристроїв, таких як Echo Show.';

  @override
  String get voiceRate => 'Частота оновлення смуги активності';

  @override
  String get voiceRateHelp =>
      'Як часто перемальовується смуга активності. Більше значення забезпечує плавність, але споживає більше ресурсів процесора.';

  @override
  String get voiceScaleHelp => 'Розмір тексту накладення.';

  @override
  String get voiceUpdateIntegration =>
      'Оновіть інтеграцію Voice Satellite у Home Assistant, щоб керувати цими налаштуваннями з кіоска.';

  @override
  String get voiceDashboardRequired =>
      'Доступно, коли кіоск показує панель керування Home Assistant.';

  @override
  String get voiceChimesPage => 'Звукові сигнали';

  @override
  String get voiceChimesHint =>
      'Звуки активації, завершення, помилки, таймера та оголошень';

  @override
  String get voiceChimesPreview => 'Прослухати на кіоску';

  @override
  String get voiceChimesPreviewFailed => 'Не вдалося відтворити звук.';

  @override
  String get voiceChimesHelp =>
      'Виберіть звуки для цього кіоска. Тут можна завантажити власні файли. Звуки, збережені в Home Assistant, не використовуються для локальних сигналів.';

  @override
  String get voiceChimeWakeTitle => 'Звук активації';

  @override
  String get voiceChimeWakeDescription =>
      'Відтворюється, коли Voice Satellite починає слухати.';

  @override
  String get voiceChimeDoneTitle => 'Звук завершення';

  @override
  String get voiceChimeDoneDescription =>
      'Відтворюється після завершення голосової взаємодії.';

  @override
  String get voiceChimeErrorTitle => 'Звук помилки';

  @override
  String get voiceChimeErrorDescription =>
      'Відтворюється при збої голосової взаємодії.';

  @override
  String get voiceChimeTimerTitle => 'Звук таймера';

  @override
  String get voiceChimeTimerDescription =>
      'Повторюється після завершення таймера, доки ви його не вимкнете.';

  @override
  String get voiceChimeAnnounceTitle => 'Звук оголошення';

  @override
  String get voiceChimeAnnounceDescription =>
      'Відтворюється перед оголошенням Voice Satellite, якщо воно не містить власного звуку.';

  @override
  String get voiceEngine => 'Рушій';

  @override
  String get voiceEngineHelp => 'Запустити або зупинити рушій Voice Satellite.';

  @override
  String get voiceAssigned => 'Призначений сателіт';

  @override
  String get voiceAssignedHelp =>
      'Об\'єкт assist_satellite, яким цей кіоск ідентифікує себе в Home Assistant. Його зміна перезавантажує панель керування.';

  @override
  String get voiceAssignedSearch =>
      'Об\'єкт assist_satellite, яким цей кіоск ідентифікує себе в Home Assistant.';

  @override
  String get voiceNoneAssigned => 'Не призначено';

  @override
  String get voiceAutoStart => 'Автозапуск';

  @override
  String get voiceAutoStartHelp =>
      'Автоматично запускати Voice Satellite під час завантаження панелі керування.';

  @override
  String get voiceMuteHelp => 'Припинити прослуховування слів активації.';

  @override
  String get voicePipeline1 => 'Голосовий конвеєр 1';

  @override
  String get voicePipeline1Help =>
      'Конвеєр Assist, через який обробляються голосові команди.';

  @override
  String get voicePipeline2 => 'Голосовий конвеєр 2';

  @override
  String get voicePipeline2Help =>
      'Конвеєр, який використовується при спрацьовуванні другого слова активації.';

  @override
  String get voiceVad => 'Виявлення завершення мовлення';

  @override
  String get voiceVadHelp => 'Тривалість паузи, яка завершує голосову команду.';

  @override
  String get voiceMutedWarning =>
      'Вимкнути попередження про вимкнений мікрофон';

  @override
  String get voiceMutedWarningHelp =>
      'Приховати попередження про вимкнений мікрофон під час запуску та щоразу, коли мікрофон сателіта вимкнено.';

  @override
  String get voiceDebug => 'Журнал налагодження';

  @override
  String get voiceDebugHelp =>
      'Показувати інформацію налагодження Voice Satellite у консолі браузера.';

  @override
  String get voiceVersion => 'Версія Voice Satellite';

  @override
  String get voiceVersionHelp =>
      'Версія інтеграції, встановлена в Home Assistant.';

  @override
  String get voiceVadDefault => 'За замовчуванням';

  @override
  String get voiceVadRelaxed => 'Повільне';

  @override
  String get voiceVadAggressive => 'Швидке';

  @override
  String get voiceGeneral => 'Загальні';

  @override
  String get voiceStart => 'Запустити';

  @override
  String get voiceNotavailable => 'Недоступно';

  @override
  String get voiceDisabled => 'Вимкнено';

  @override
  String get settingWakeWordBackgroundTitle =>
      'Продовжувати слухати у фоновому режимі';

  @override
  String get settingWakeWordBackgroundDescription =>
      'Продовжувати розпізнавати слово активації, коли на передньому плані інша програма, та повертатися при виявленні. Потрібне постійне сповіщення та дозвіл показу поверх інших програм.';

  @override
  String get settingWakeWordReturnToBackgroundTitle =>
      'Повертатися до попередньої програми';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      'Повертатися до попередньої програми або головного екрана після того, як голосова взаємодія вивела Kiosk Satellite на передній план і завершилася.';

  @override
  String get voiceMicHeld => 'Виявлення слова активації може чути вас.';

  @override
  String get voiceMicBlocked =>
      'Заблоковано. Android більше не запитуватиме цей дозвіл, тому надайте його в налаштуваннях програми.';

  @override
  String get voiceMicMissing =>
      'Без цього дозволу слово активації не прослуховується.';

  @override
  String get voiceForegroundHeld =>
      'Kiosk Satellite може з\'являтися на передньому плані, коли чує вас.';

  @override
  String get voiceForegroundMissing =>
      'Без цього дозволу слово активації розпізнається, але нічого не відбувається.';

  @override
  String get voiceNotificationHeld =>
      'Постійне сповіщення, яке забезпечує фонове прослуховування.';

  @override
  String get voiceNotificationMissing =>
      'Необхідно для стабільної роботи фонового прослуховування.';

  @override
  String get voiceBatteryHeld =>
      'Android не зупинятиме фонове прослуховування.';

  @override
  String get voiceBatteryMissing =>
      'Без цього дозволу прослуховування буде зупинено через кілька годин.';

  @override
  String get voicePermissionDirections =>
      'Надайте ці дозволи безпосередньо на пристрої: проведіть пальцем від лівого краю → Налаштування → Voice Satellite → Необхідні системні дозволи.';

  @override
  String get voicePermissionsSearch =>
      'Мікрофон та інші дозволи, необхідні для виявлення слова активації.';

  @override
  String get voiceDisconnected => 'Home Assistant не підключено';

  @override
  String get voiceValidate =>
      'Спочатку перевірте підключення в меню Налаштування Home Assistant.';

  @override
  String get voiceChecking => 'Перевірка наявності Voice Satellite…';

  @override
  String get voiceMissing => 'Voice Satellite не встановлено в Home Assistant';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite перетворює цей кіоск на повноцінний голосовий асистент для Home Assistant: виявлення слова активації, бесіди, таймери та оголошення прямо на панелі керування.\n\nІнтеграція доступна в стандартному репозиторії HACS. Встановіть її на ваш сервер Home Assistant, а потім поверніться сюди.';

  @override
  String get voiceLearnMore => 'Дізнатися більше про ';

  @override
  String get voiceGithub => 'Voice Satellite на GitHub';

  @override
  String get voiceHacs => 'Відкрити репозиторій HACS';

  @override
  String get voiceLoading =>
      'Завантаження елементів керування Voice Satellite…';

  @override
  String get voiceTester => 'Тестер слова активації';

  @override
  String get voiceTesterHelp =>
      'Відстежуйте в реальному часі, що чує рушій та як він оцінює звук, щоб з\'ясувати причини спрацьовування або неспрацьовування слова активації.';

  @override
  String get voiceTesterSearch =>
      'Перегляд у реальному часі того, що чує та оцінює рушій.';

  @override
  String get voiceTesterWaiting => 'Очікування Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word (стоп-слово)';
  }

  @override
  String get voiceScore => 'Оцінка';

  @override
  String get voiceThreshold => 'Поріг';

  @override
  String get voiceHits => 'Спрацьовування';

  @override
  String get voiceNearMisses => 'Близькі збіги';

  @override
  String get voicePeak => 'Пік';

  @override
  String get voiceMicLevel => 'Рівень мікрофона';

  @override
  String get voiceChunkProcessing => 'Обробка фрагментів (мін / сер / макс)';

  @override
  String get voiceLog => 'Журнал';

  @override
  String get voiceLogEmpty =>
      'Спрацьовування та близькі збіги з\'являтимуться тут.';

  @override
  String get voiceLogHit => 'ТОЧНО';

  @override
  String get voiceLogNear => 'близько';

  @override
  String get voiceLogScore => 'оцінка';

  @override
  String get voiceLogDecoded => 'розпізнано';

  @override
  String get voiceLogDistance => 'відстань';

  @override
  String get voiceLogConfidence => 'впевненість';

  @override
  String get voiceTesterPlayRecent => 'Відтворити останні 10 секунд';

  @override
  String get voiceWakePage => 'Слово активації';

  @override
  String get voiceWakeHint =>
      'Рушій, слова активації, чутливість, кешовані моделі';

  @override
  String get voiceWakeLabel => 'Слово активації';

  @override
  String get voiceWakeEngine => 'Рушій слова активації';

  @override
  String get voiceWakeEngineHelp =>
      'Де виконується виявлення та який рушій прослуховує.';

  @override
  String get voiceWake1 => 'Слово активації 1';

  @override
  String get voiceWake1Help => 'Слово, яке запускає голосову команду.';

  @override
  String get voiceWake2 => 'Слово активації 2';

  @override
  String get voiceWake2Help =>
      'Друге слово активації, яке запускає голосовий конвеєр 2.';

  @override
  String get voiceSensitivity => 'Чутливість слова активації';

  @override
  String get voiceSensitivityHelp =>
      'Наскільки легко спрацьовує слово активації.';

  @override
  String get voiceNoiseGate => 'Шумовий поріг слова активації';

  @override
  String get voiceNoiseGateHelp =>
      'Пропускати локальну обробку слова активації в тихій кімнаті для економії ресурсів процесора.';

  @override
  String get voiceStopInterruption => 'Переривання стоп-словом';

  @override
  String get voiceStopInterruptionHelp =>
      'Вимовте стоп-слово, щоб перервати відповідь.';

  @override
  String get voiceAssignFirst =>
      'Призначте сателіт для керування цими налаштуваннями.';

  @override
  String get voiceCachedModels => 'Кешовані моделі';

  @override
  String get voiceCachedModelsHelp =>
      'Повторно завантажити з Home Assistant. Використовуйте після повторної публікації моделі.';

  @override
  String get voiceClearCache => 'Очистити кеш';

  @override
  String get voiceClearing => 'Очищення…';

  @override
  String voiceCacheCleared(String count) {
    return 'Файлів очищено: $count. Завантажуємо знову.';
  }

  @override
  String voiceCacheCount(String count) {
    return 'Очищено: $count';
  }

  @override
  String get voiceVerySensitive => 'Дуже чутливо';

  @override
  String get voiceWakeWordPreferFp32Title =>
      'Надавати перевагу моделям fp32 vsWakeWord';

  @override
  String get voiceWakeWordPreferFp32Description =>
      'Використовує моделі fp32 замість менших версій int8. Збільшує навантаження на процесор на 10-30% під час прослуховування для уникнення втрати точності близько 2%.';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle =>
      'Таймаут відновлення (секунди)';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      'Самовідновлення: відновлює прослуховування, якщо сторінка не викликає setWakeWordActive(true) після передачі керування. Очікує, поки триває потокова передача звуку, щоб не обривати довгі репліки.';

  @override
  String get voiceSlightlySensitive => 'Низька чутливість';

  @override
  String get voiceModeratelySensitive => 'Помірна чутливість';

  @override
  String get voiceOnDevice => 'На пристрої';

  @override
  String voiceOnDeviceEngine(String engine) {
    return 'На пристрої ($engine)';
  }

  @override
  String get voiceDiagnosticsPage => 'Діагностика слова активації';

  @override
  String get voiceDiagnosticsHint =>
      'Останні активації та близькі збіги з аудіокліпами';

  @override
  String get voiceDiagnosticsTitle => 'Увімкнути діагностику слова активації';

  @override
  String get voiceDiagnosticsDescription =>
      'Записує останні 10 активацій і близьких збігів слова активації з їхніми оцінками та 3-секундним аудіокліпом кожного. Вимкнення видаляє їх.';

  @override
  String get voiceDiagnosticsEmpty =>
      'Активацій слова активації ще не записано.';

  @override
  String get voiceDiagnosticsActivations => 'Активації';

  @override
  String get voiceDiagnosticsNoNearMisses => 'Близьких збігів ще не записано.';

  @override
  String get voiceDiagnosticsPeakLevel => 'Піковий рівень';

  @override
  String get voiceDiagnosticsAverageLevel => 'Середній рівень';

  @override
  String get voiceDiagnosticsClipped => 'Перевантаження';

  @override
  String get voiceDiagnosticsHeard => 'Почуто';

  @override
  String get settingDisableCacheTitle => 'Вимкнути кеш';

  @override
  String get settingDisableCacheDescription =>
      'Завжди завантажувати дані з мережі та скидати кеш сторінки під час завантаження, щоб оновлена панель керування завжди показувалася актуальною. Працює повільніше; призначено для розробки.';

  @override
  String get settingAllowMixedContentTitle => 'Дозволити змішаний вміст';

  @override
  String get settingAllowMixedContentDescription =>
      'Дозволити сторінкам HTTPS завантажувати незахищені ресурси HTTP. Корисно, коли Home Assistant включає вміст з http:// у панель керування через https:// для підключення.';

  @override
  String get settingIgnoreSslErrorsTitle => 'Ігнорувати помилки SSL';

  @override
  String get settingIgnoreSslErrorsDescription =>
      'Приймати ненадійні або самопідписані сертифікати. Використовуйте лише у власній мережі, оскільки це вимикає перевірку сертифікатів.';

  @override
  String get settingAutoReloadOnErrorTitle =>
      'Автоматичне перезавантаження при помилці';

  @override
  String get settingAutoReloadOnErrorDescription =>
      'Автоматично відновлювати роботу при збоях сторінки або аварійному завершенні програми.';

  @override
  String get settingPullToRefreshTitle =>
      'Увімкнути оновлення потягуванням вниз';

  @override
  String get settingPullToRefreshDescription =>
      'Потягніть зверху сторінки вниз для перезавантаження. За замовчуванням вимкнено, оскільки на панелі з прокручуванням легко потягнути випадково.';

  @override
  String get settingPullToRefreshClearCacheTitle =>
      'Очищати кеш під час оновлення потягуванням';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      'Потягування вниз також очищає вебкеш і моделі слів активації перед перезавантаженням. Дані входу та збережені дані сторінки зберігаються.';

  @override
  String get settingBrowserZoomTitle => 'Рівень масштабування';

  @override
  String get settingBrowserZoomDescription =>
      'Масштабує всю сторінку. Значення понад 1x підходять для настінних планшетів, на які дивляться здалеку; значення менше 1x вміщують більше вмісту на невеликому екрані.';

  @override
  String get settingPinchToZoomTitle =>
      'Увімкнути масштабування двома пальцями';

  @override
  String get settingPinchToZoomDescription =>
      'Масштабувати сторінку жестом зведення або розведення двох пальців. За замовчуванням вимкнено, щоб панель керування не зміщувалася при випадкових дотиках.';

  @override
  String get settingDisableScrollingTitle => 'Вимкнути прокручування';

  @override
  String get settingDisableScrollingDescription =>
      'Зафіксувати сторінку, щоб її не можна було прокручувати в жодному напрямку. Дотики та кнопки продовжують працювати.';

  @override
  String get browserCrashPermissionHelp =>
      'Без цього дозволу кіоск не зможе автоматично відновитися після збою.';

  @override
  String get browserCrashPermissionMissing =>
      'Відсутній дозвіл \"Показ поверх інших програм\"';

  @override
  String get browserCrashPermissionRemoteHelp =>
      'Без цього дозволу кіоск не зможе повернутися на екран після збою. Екран надання дозволу відкриється на планшеті.';

  @override
  String get settingBrowserInjectJsTitle =>
      'Впровадження JavaScript на панелі керування HA';

  @override
  String get settingBrowserInjectJsDescription =>
      'Виконувати цей код JavaScript після кожного завантаження сторінки панелі керування. Корисно для приховування зайвих елементів або налаштування чужої панелі.';

  @override
  String get settingBrowserInjectJsExternalTitle =>
      'Впровадження JavaScript на зовнішніх сторінках';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      'Виконувати цей код JavaScript після завантаження кожної зовнішньої сторінки: сторінок за посиланнями з панелі, сторінок ротації та заставки вебсайту. Сторінка Music Assistant залишається без змін.';

  @override
  String get browserInjectJsPlaceholder =>
      '// Приклад: приховати зайвий елемент\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// Приклад: масштабувати сайт, який ігнорує масштаб панелі керування\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get setupConnectHeading => 'Підключення до Home Assistant';

  @override
  String get setupConnectLead =>
      'Базова URL-адреса вашого екземпляра та довгостроковий токен доступу, створений у профілі HA → Безпека → Довгострокові токени доступу.';

  @override
  String get setupBaseUrl => 'Базова URL-адреса Home Assistant';

  @override
  String get setupToken => 'Довгостроковий токен доступу';

  @override
  String get setupScanQr => 'Сканувати QR-код';

  @override
  String get setupInvalidToken => 'Недійсний токен доступу';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant відхилив цей токен. У Home Assistant відкрийте свій профіль → Безпека → Довгострокові токени доступу, створіть новий токен і скопіюйте його повне значення.';

  @override
  String get setupUnreachable => 'Не вдається з\'єднатися з Home Assistant';

  @override
  String get setupUnreachableHelp =>
      'Немає відповіді за цією адресою. Перевірте правильність URL-адреси та переконайтеся, що цей пристрій знаходиться в одній мережі із сервером Home Assistant.';

  @override
  String get setupUnexpectedResponseHelp =>
      'Сервер відповів, але схоже, що це не Home Assistant. Перевірте, чи є ця URL-адреса базовою адресою вашого Home Assistant, наприклад https://homeassistant.local:8123.';

  @override
  String get setupCannotConnect => 'Не вдалося підключитися';

  @override
  String get setupCameraPermission => 'Потрібен дозвіл на камеру';

  @override
  String get setupCameraBlocked =>
      'Надайте Kiosk Satellite дозвіл на доступ до камери в налаштуваннях Android, щоб сканувати QR-код.';

  @override
  String get setupCameraAllow =>
      'Надайте дозвіл на доступ до камери, щоб сканувати QR-код.';

  @override
  String get setupEnterBaseUrl => 'Введіть базову URL-адресу Home Assistant';

  @override
  String get setupInvalidBaseUrl => 'Недійсна базова URL-адреса';

  @override
  String get setupBaseUrlHelp =>
      'Це адреса, яку ви використовуєте для відкриття Home Assistant, наприклад https://homeassistant.local:8123.';

  @override
  String get setupEnterToken => 'Введіть довгостроковий токен доступу';

  @override
  String get setupEnterTokenHelp =>
      'У Home Assistant відкрийте профіль → Безпека → Довгострокові токени доступу, щоб створити його.';

  @override
  String get setupValidateContinue => 'Перевірити та продовжити';

  @override
  String setupUnexpectedResponse(String error) {
    return 'Неочікувана відповідь ($error)';
  }

  @override
  String get baseUrlInvalid =>
      'Введіть дійсну URL-адресу, наприклад https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      'Введіть лише базову URL-адресу, без шляху до панелі керування. Приклад: https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      'Введіть лише базову URL-адресу, без будь-яких параметрів після порту. Приклад: https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => 'Виберіть панель керування';

  @override
  String get setupDashboardHelp =>
      'Це те, що кіоск показуватиме під час запуску.';

  @override
  String get setupSelectDashboard => 'Виберіть панель керування';

  @override
  String get setupSelectDashboardHelp =>
      'Виберіть панель керування, яку відображатиме кіоск. Ви зможете змінити її пізніше в Налаштуваннях.';

  @override
  String get setupWelcome => 'Вітаємо';

  @override
  String get setupConnect => 'Підключення';

  @override
  String get setupConnectSummary => 'URL та токен Home Assistant';

  @override
  String get setupDashboard => 'Панель керування';

  @override
  String get setupDashboardSummary => 'Що показує кіоск';

  @override
  String get setupRecommendedSummary => 'Рекомендовані налаштування';

  @override
  String get setupPermissions => 'Дозволи';

  @override
  String get setupPermissionsSummary => 'Системні доступи планшета';

  @override
  String get setupPermissionLead =>
      'Android запитає ці дозволи. Усі запити здійснюються заздалегідь, щоб кіоск не відволікав вас надалі.';

  @override
  String get setupRemotePermissionLead =>
      'Android запитує їх безпосередньо на планшеті. Підійдіть до пристрою та підтвердьте запити, а потім поверніться сюди для завершення.';

  @override
  String get setupMicrophoneHelp =>
      'Для Voice Satellite та інтеркому потрібен доступ до мікрофона';

  @override
  String get setupNotificationListening =>
      'Дозволяє постійне сповіщення служби Kiosk Satellite Service, яке вказує на її активність та коли кіоск веде прослуховування.';

  @override
  String get setupBatteryService =>
      'Дозволяє службі Kiosk Satellite Service працювати у фоновому режимі без призупинення чи примусового закриття.';

  @override
  String get setupOverlayBoot =>
      'Дозволяє Kiosk Satellite відновлювати роботу після збоїв та запускатися під час завантаження пристрою.';

  @override
  String get setupOverlayCrash =>
      'Дозволяє Kiosk Satellite повертатися на екран після збою.';

  @override
  String get setupBrightnessHelp =>
      'Дозволяє Kiosk Satellite регулювати фактичну яскравість екрана (зміна системних налаштувань).';

  @override
  String get setupScreenControl => 'Керування екраном';

  @override
  String get setupScreenControlHelp =>
      'Дозволяє Kiosk Satellite вимикати екран за запитом (адміністратор пристрою).';

  @override
  String get setupGrantPermissions => 'Надати дозволи на пристрої';

  @override
  String get setupRequestingPermissions => 'Запит на пристрої…';

  @override
  String get setupPermissionsRequested => 'Дозволи запитано на пристрої';

  @override
  String get setupQrFlipCamera => 'Перемкнути камеру';

  @override
  String get setupQrCameraFailed => 'Не вдалося запустити камеру.';

  @override
  String get setupQrTitle => 'Скануйте QR-код токена';

  @override
  String get setupQrHelp =>
      'Він відображається поруч із щойно створеним токеном у вашому профілі Home Assistant.';

  @override
  String get setupQrFlashOff => 'Вимкнути ліхтарик';

  @override
  String get setupQrFlashOn => 'Увімкнути ліхтарик';

  @override
  String get setupPasswordFirst => 'Спочатку встановіть пароль адміністратора';

  @override
  String get setupPasswordBeforeImport =>
      'Введіть пароль адміністратора вище (щонайменше 4 символи), а потім імпортуйте резервну копію.';

  @override
  String get setupPasswordFailed => 'Не вдалося встановити пароль';

  @override
  String get setupPasswordExists => 'Пароль уже встановлено';

  @override
  String get setupPasswordExistsHelp =>
      'Увійдіть із паролем, встановленим на планшеті, щоб продовжити тут. Перезавантаження…';

  @override
  String get setupNotBackup => 'Не є файлом резервної копії';

  @override
  String get setupInvalidBackupHelp =>
      'Цей файл не є коректним JSON. Експортуйте конфігурацію з Налаштувань налаштованого Kiosk Satellite або з його віддаленого адміністрування.';

  @override
  String get setupWrongBackupKind =>
      'Експортуйте конфігурацію на вкладці Налаштування вже налаштованого Kiosk Satellite.';

  @override
  String get setupImportFailedHelp => 'Не вдалося застосувати файл.';

  @override
  String get setupBackupNoDashboard =>
      'У резервній копії відсутня панель керування';

  @override
  String get setupBackupNoDashboardHelp =>
      'Налаштування застосовано, але цю резервну копію було зроблено до налаштування пристрою, тому панель керування для відображення відсутня. Продовжте роботу з майстром, щоб вибрати її.';

  @override
  String get setupImporting => 'Імпортування…';

  @override
  String get setupRemoteRestoreHelp =>
      'Імпортуйте конфігурацію, експортовану з Kiosk Satellite, та пропустіть решту кроків цього майстра.';

  @override
  String get setupFinishOnDevice => 'Завершіть на пристрої';

  @override
  String get setupFinishOnDeviceHelp =>
      'Конфігурацію імпортовано. Дайте відповіді на запити дозволів на екрані планшета - ця сторінка продовжить роботу автоматично після завантаження панелі керування.';

  @override
  String get setupBackupObject =>
      'Резервна копія повинна містити об\'єкт JSON.';

  @override
  String get setupBackupKind => 'Це не файл конфігурації Kiosk Satellite.';

  @override
  String get setupBackupSettings => 'Резервна копія не містить налаштувань.';

  @override
  String get setupServiceHelp =>
      'Підтримує роботу застосунку, коли екран вимкнено або поверх відкрито інший застосунок, щоб з\'єднання з Home Assistant та інші функції, як-от виявлення руху та Bluetooth-проксі, залишалися активними. Нижче наведено необов\'язкові, але рекомендовані дозволи: кожен із них допомагає продовжити роботу при вимкненому екрані.';

  @override
  String get setupBatteryMissing =>
      'Android може призупинити роботу застосунку при вимкненому екрані, через що з\'єднання з Home Assistant буде розірвано.';

  @override
  String get setupOverlayMissing =>
      'Без цього служба не зможе повторно запустити кіоск після збою.';

  @override
  String get setupVoiceDetected => 'Виявлено Voice Satellite';

  @override
  String get setupVoiceHelp =>
      'У цьому екземплярі Home Assistant працює інтеграція Voice Satellite. Виберіть, яким сателітом є цей кіоск, та перевірте його налаштування. Усе це можна змінити пізніше.';

  @override
  String get setupNoSatellites => 'Сателітів не знайдено';

  @override
  String get setupNoSatellitesHelp =>
      'Додайте асистент-сателіт в інтеграції Voice Satellite або продовжте без нього та виберіть його на панелі керування пізніше.';

  @override
  String get setupNewSatelliteHelp =>
      'Якщо це новий пристрій, спочатку створіть нову сутність сателіта в Home Assistant. Налаштування → Пристрої та служби → Voice Satellite → Додати запис. ВАЖЛИВО: два пристрої не можуть використовувати одну й ту саму сутність.';

  @override
  String get setupApplyRecommended =>
      'Застосувати всі рекомендовані налаштування';

  @override
  String get setupRecommendedHelp =>
      'Оптимальні налаштування для повної інтеграції та функціональності Voice Satellite.';

  @override
  String get setupVoiceRequired => 'Потрібно для Voice Satellite';

  @override
  String get setupMicrophoneAccess => 'Доступ до мікрофона';

  @override
  String get setupNativeWakeWord => 'Вбудоване розпізнавання слова активації';

  @override
  String get setupPullRefresh => 'Потягніть для оновлення';

  @override
  String get setupAutoplay => 'Автовідтворення аудіо та відео';

  @override
  String get setupVoiceSkipped => 'Не встановлено, пропущено';

  @override
  String get setupRemoteHeading => 'Віддалене адміністрування';

  @override
  String get setupTitle => 'Налаштування\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      'Перетворіть цей планшет на кіоск Home Assistant. Налаштування займе пару хвилин, і цей майстер проведе вас крок за кроком.';

  @override
  String get setupDeviceName => 'Назва пристрою';

  @override
  String get setupDeviceNameHelp =>
      'Як цей кіоск називатиметься в Home Assistant, у віддаленому адмініструванні та в мережі. Можна змінити в будь-який час у Налаштуваннях, розділ «Пристрій».';

  @override
  String get setupEnableRemote => 'Увімкнути віддалене адміністрування';

  @override
  String get setupEnableRemoteHelp =>
      'Продовжуйте керувати цим кіоском із веб-браузера після налаштування, де вставити токен доступу Home Assistant значно простіше.';

  @override
  String get setupRemotePassword => 'Пароль віддаленого доступу';

  @override
  String get setupRestoreHeading => 'Відновлення';

  @override
  String get setupRestore => 'Відновити з файлу конфігурації';

  @override
  String get setupRestoreHelp =>
      'Імпортуйте конфігурацію, експортовану з Kiosk Satellite, та пропустіть решту цього майстра. Налаштування, панель керування та вхід перенесуться разом.';

  @override
  String get setupServicePermissions => 'Системні дозволи';

  @override
  String get setupPasswordShort => 'Пароль занадто короткий';

  @override
  String get setupPasswordMinimum => 'Використовуйте щонайменше 4 символи.';

  @override
  String setupRemoteAddress(String address) {
    return 'Ви можете продовжити це налаштування віддалено з веб-браузера за адресою $address, незалежно від того, чи ввімкнено перемикач вище.';
  }

  @override
  String get remoteWelcomeTitle => 'Ласкаво просимо до Kiosk Satellite';

  @override
  String get remoteWelcomePassword =>
      'Цей планшет очікує на налаштування. Спершу захистіть це віддалене адміністрування паролем.';

  @override
  String get remoteWelcomeReady =>
      'Цей планшет очікує на налаштування. Пароль віддаленого адміністратора вже встановлено; введіть новий тут, щоб змінити його.';

  @override
  String get remoteInitialPassword => 'Пароль адміністратора (мін. 4 символи)';

  @override
  String get remoteNewPassword =>
      'Новий пароль адміністратора (залиште порожнім, щоб зберегти поточний)';

  @override
  String get intercomBuiltinRing => 'Вбудований дзвінок';

  @override
  String get intercomBuiltinChime => 'Вбудований сигнал';

  @override
  String intercomMissingFile(String file) {
    return '$file (відсутній)';
  }

  @override
  String get intercomAddSound => 'Додати звук';

  @override
  String get intercomCopySoundHelp =>
      'Скопіювати звуковий файл із цього пристрою в папку звуків.';

  @override
  String get intercomUploadSoundHelp =>
      'Завантажити звуковий файл із цього комп\'ютера в папку звуків.';

  @override
  String get intercomUpload => 'Завантажити';

  @override
  String get intercomUploading => 'Завантаження…';

  @override
  String get intercomUnsupportedSound => 'Непідтримуваний формат звуку';

  @override
  String get intercomChooseSound =>
      'Непідтримуваний формат звуку: виберіть файл MP3, OGG, WAV, FLAC, M4A або AAC.';

  @override
  String get intercomCopyFailed => 'Не вдалося скопіювати файл';

  @override
  String intercomUploadFailed(String error) {
    return 'Помилка завантаження: $error';
  }

  @override
  String intercomSaveFailed(String error) {
    return 'Не збережено: $error';
  }

  @override
  String get intercomSoundFilename => 'Введіть назву файлу, а не шлях.';

  @override
  String get intercomSoundFormats =>
      'Виберіть файл MP3, OGG, WAV, FLAC, M4A або AAC.';

  @override
  String get voiceTimerDefaultName => 'Таймер';

  @override
  String get voiceTimerDrag => 'Перетягніть для переміщення таймерів';

  @override
  String get voiceTimerPauseHint =>
      'Торкніться для паузи. Подвійний дотик для скасування. Перетягніть для переміщення.';

  @override
  String get voiceTimerResumeHint =>
      'Торкніться для відновлення. Подвійний дотик для скасування. Перетягніть для переміщення.';

  @override
  String get voiceTimerCancel => 'Скасувати таймер';

  @override
  String get voiceTimerActionError =>
      'Не вдалося змінити таймер. Перевірте підключення та за потреби оновіть Voice Satellite.';

  @override
  String get voiceTimerFinished => 'Таймер завершено';

  @override
  String get voiceTimerDismissHint =>
      'Торкніться, щоб закрити сповіщення таймера.';
}
