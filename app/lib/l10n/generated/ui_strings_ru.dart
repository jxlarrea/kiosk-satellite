// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class UiStringsRu extends UiStrings {
  UiStringsRu([String locale = 'ru']) : super(locale);

  @override
  String get aboutApp => 'Приложение';

  @override
  String get aboutVersion => 'Версия приложения';

  @override
  String get aboutBuild => 'Сборка';

  @override
  String get aboutPackage => 'Пакет';

  @override
  String get aboutAttribution => 'Авторство';

  @override
  String get aboutAuthor => 'Автор';

  @override
  String get aboutWebsite => 'Сайт';

  @override
  String get aboutSourceCode => 'Исходный код';

  @override
  String get aboutLicense => 'Лицензия';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite бесплатен для личного некоммерческого использования. Он распространяется по лицензии CC BY-NC-ND 4.0: вы можете использовать его и делиться им, но коммерческое использование приложения и распространение изменённых сборок не разрешены. Независимые плагины имеют дополнительное разрешение согласно PLUGIN-EXCEPTION.md.';

  @override
  String get aboutLocalizationCredits => 'Авторы локализации';

  @override
  String get aboutLocalizationCreditsHint => 'Участники по языкам';

  @override
  String get aboutCheckNow => 'Проверить обновления сейчас';

  @override
  String get aboutChecking => 'Проверка…';

  @override
  String get aboutCheckFailed =>
      'Не удалось проверить обновления. Устройство имеет доступ к GitHub?';

  @override
  String get aboutOverlayMissing => 'Нет разрешения «Поверх других приложений»';

  @override
  String get aboutOverlayHelp =>
      'Без него приложение не сможет снова открыться после обновления. Экран выдачи разрешения откроется на планшете.';

  @override
  String aboutDownloadProgress(String percent) {
    return 'Загрузка… $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return 'Обновление не удалось: $error';
  }

  @override
  String get aboutAlreadyCurrent => 'Уже установлена последняя версия';

  @override
  String get aboutInstallHelp =>
      'Загрузка выполняется на планшете; установку нужно подтвердить на экране планшета.';

  @override
  String get aboutSystem => 'Система';

  @override
  String get aboutSystemVersion => 'Версия ROM';

  @override
  String get aboutSystemVerifying => 'Проверка…';

  @override
  String get aboutSystemInstalling => 'Установка…';

  @override
  String get aboutSystemRestartHelp =>
      'Устройство дважды перезагружается для установки обновления и несколько минут не в сети.';

  @override
  String get aboutSystemManual => 'Доступен новый образ';

  @override
  String aboutSystemManualHelp(String version) {
    return 'Версия $version нового образа Echo Dot устанавливается вручную, а не как обновление.';
  }

  @override
  String get alarmsTitle => 'Будильники';

  @override
  String get alarmsSetAnAlarm => 'Создать будильник';

  @override
  String get alarmsNone => 'Нет будильников';

  @override
  String get alarmsDone => 'Готово';

  @override
  String get alarmsRepeat => 'Повтор';

  @override
  String get alarmsLabel => 'Название';

  @override
  String get alarmsAddLabel => 'Добавить название';

  @override
  String get alarmsTone => 'Звук будильника';

  @override
  String get alarmsSunrise => 'Рассвет';

  @override
  String get alarmsDefaultTone => 'По умолчанию';

  @override
  String get alarmsBuiltInTone => 'Встроенный звук';

  @override
  String get alarmsSoundsFolder => 'Папка звуков';

  @override
  String get alarmsToday => 'Сегодня';

  @override
  String get alarmsTomorrow => 'Завтра';

  @override
  String get alarmsOnce => 'Один раз';

  @override
  String get alarmsEveryDay => 'Каждый день';

  @override
  String get alarmsWeekdays => 'По будням';

  @override
  String get alarmsWeekends => 'По выходным';

  @override
  String alarmsSnoozedUntil(String time) {
    return 'Отложено до $time';
  }

  @override
  String get alarmsSnooze => 'Отложить';

  @override
  String get alarmsStop => 'Остановить';

  @override
  String get alarmsDefaultLabel => 'Будильник';

  @override
  String get alarmsSetToast => 'Будильник установлен';

  @override
  String alarmsRingsIn(String duration) {
    return 'Прозвенит через $duration';
  }

  @override
  String alarmsDurationHoursMinutes(String hours, String minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String alarmsDurationHours(String hours) {
    return '$hours ч';
  }

  @override
  String alarmsDurationMinutes(String minutes) {
    return '$minutes мин';
  }

  @override
  String alarmsAt(String time) {
    return 'Будильник на $time';
  }

  @override
  String get alarmsNextWidget => 'Следующий будильник';

  @override
  String get alarmsManage => 'Управлять будильниками';

  @override
  String alarmsNextAt(String day, String time) {
    return 'Следующий: $day в $time';
  }

  @override
  String get alarmsNoneSet => 'Будильники не установлены';

  @override
  String get alarmsDefaultsSection => 'Значения по умолчанию';

  @override
  String get alarmsTtsSection => 'Синтез речи';

  @override
  String get alarmsEditAlarm => 'Изменить будильник';

  @override
  String get alarmsTime => 'Время';

  @override
  String get alarmsRinging => 'Будильник звонит';

  @override
  String get alarmsSnoozed => 'Будильник отложен';

  @override
  String get alarmsSunriseRunning => 'Рассвет перед будильником';

  @override
  String alarmsSunriseHint(String minutes) {
    return 'Экран плавно светлеет в течение $minutes мин перед звонком.';
  }

  @override
  String get alarmsDeleteFailed => 'Не удалось удалить будильник.';

  @override
  String alarmsDuplicate(String time) {
    return 'У вас уже есть будильник на $time';
  }

  @override
  String get alarmsEaseIn => 'Плавное нарастание громкости';

  @override
  String alarmsEaseHint(String seconds) {
    return 'Громкость растёт до уровня будильника в течение $seconds с.';
  }

  @override
  String get alarmsSpeak => 'Произносить фразу при звонке';

  @override
  String get alarmsPhrase => 'Фраза';

  @override
  String alarmsPhraseVariables(String variables) {
    return 'Доступные переменные: $variables';
  }

  @override
  String get alarmsVoiceSection => 'Голосовые будильники';

  @override
  String get alarmsVoiceManage =>
      'Управление будильниками через Voice Satellite';

  @override
  String get alarmsVoiceHint =>
      'Требуются Blueprint будильников Kiosk Satellite и диалоговый LLM-агент в Home Assistant.';

  @override
  String get alarmsMusic => 'Музыка';

  @override
  String get alarmsMusicNone => 'Нет';

  @override
  String get alarmsMusicRemove => 'Убрать музыку';

  @override
  String get alarmsMusicHint =>
      'Звучит вместо звука будильника. Если музыку не удастся воспроизвести, прозвучит звук будильника.';

  @override
  String get androidAccessibilityHelp =>
      'Закрывает шторку уведомлений и экран недавних приложений, когда они открываются, пока экран защищает режим киоска или режим блокировки. Kiosk Satellite не читает содержимое экрана.';

  @override
  String get androidServiceChannelHelp =>
      'Показывается, пока служба Kiosk Satellite удерживает приложение запущенным при выключенном экране или позади другого приложения.';

  @override
  String get androidServiceListening => 'слушает слово пробуждения';

  @override
  String get androidServiceRtspAudio => 'включён звук микрофона RTSP';

  @override
  String get androidServiceEsphome => 'обслуживает ESPHome';

  @override
  String get androidServiceBluetooth => 'ретранслирует Bluetooth-устройства';

  @override
  String get androidServiceCamera => 'следит за камерой';

  @override
  String get androidServiceLocation => 'сообщает местоположение';

  @override
  String get androidServiceRemote => 'обслуживает удалённое администрирование';

  @override
  String get androidServiceKiosk => 'защищает режим киоска';

  @override
  String get androidServiceSessions =>
      'поддерживает соединение с Home Assistant';

  @override
  String get launcherErrorAndroidOnly =>
      'список приложений доступен только на Android';

  @override
  String launcherErrorListDetail(String error) {
    return 'не удалось получить список приложений: $error';
  }

  @override
  String launcherOpenFailed(String name) {
    return 'Не удалось открыть $name';
  }

  @override
  String get launcherUninstalled => 'Возможно, приложение было удалено.';

  @override
  String get launcherNoneHelp =>
      'Пока пусто. Выберите приложения, которые предложит лаунчер.';

  @override
  String get launcherNone => 'Пока пусто';

  @override
  String get launcherListFailed => 'Не удалось получить список приложений';

  @override
  String launcherListError(String error) {
    return 'Не удалось получить список приложений: $error';
  }

  @override
  String get launcherListingFailed => 'не удалось получить список';

  @override
  String get launcherEmpty => 'Запускаемые приложения не найдены.';

  @override
  String get launcherSearchApps => 'Поиск приложений';

  @override
  String get calendarTitle => 'Календарь';

  @override
  String get calendarViewDay => 'День';

  @override
  String get calendarViewWeek => 'Неделя';

  @override
  String get calendarViewMonth => 'Месяц';

  @override
  String get calendarViewSchedule => 'Расписание';

  @override
  String get calendarToday => 'Сегодня';

  @override
  String get calendarTomorrow => 'Завтра';

  @override
  String get calendarPrevious => 'Назад';

  @override
  String get calendarNext => 'Далее';

  @override
  String get calendarAllDay => 'Весь день';

  @override
  String calendarMore(String count) {
    return 'Ещё $count';
  }

  @override
  String get calendarUpNext => 'Дальше по плану';

  @override
  String calendarStartsIn(String duration) {
    return 'через $duration';
  }

  @override
  String get calendarHappeningNow => 'Сейчас';

  @override
  String get calendarLaterToday => 'Позже сегодня';

  @override
  String get calendarNothingElseToday => 'Сегодня больше ничего';

  @override
  String get calendarNothingPlanned => 'Ничего не запланировано';

  @override
  String get calendarNothingThisWeek =>
      'На этой неделе ничего не запланировано';

  @override
  String get calendarEmptyTitle => 'Календарей пока нет';

  @override
  String get calendarEmptyHint =>
      'Добавьте в Настройки > Календарь календари Home Assistant, которые нужно показывать.';

  @override
  String calendarOffline(String time) {
    return 'Home Assistant недоступен. Показаны события на $time.';
  }

  @override
  String calendarTimeRange(String start, String end) {
    return 'с $start до $end';
  }

  @override
  String calendarPeopleTwo(String first, String second) {
    return '$first и $second';
  }

  @override
  String get calendarRepeatsDaily => 'Каждый день';

  @override
  String get calendarRepeatsWeekly => 'Каждую неделю';

  @override
  String get calendarRepeatsMonthly => 'Каждый месяц';

  @override
  String get calendarRepeatsYearly => 'Каждый год';

  @override
  String get calendarRepeats => 'Повторяется';

  @override
  String get calendarDone => 'Готово';

  @override
  String get calendarCalendarsSection => 'Календари';

  @override
  String get calendarAdd => 'Добавить календарь';

  @override
  String get calendarAlreadyAdded => 'Этот календарь уже в списке.';

  @override
  String get calendarOpen => 'Открыть календарь';

  @override
  String get calendarOpenHint => 'Показать календарь на этом киоске.';

  @override
  String get calendarEditName => 'Название';

  @override
  String get calendarEditColor => 'Цвет';

  @override
  String get calendarEditPerson => 'Человек';

  @override
  String get calendarEditPersonHint =>
      'Показывает его фото на метках календаря.';

  @override
  String get calendarEditPersonNone => 'Нет';

  @override
  String get calendarPickCalendar => 'Выберите календарь';

  @override
  String get calendarPickPerson => 'Выберите человека';

  @override
  String get calendarColorTeal => 'Бирюзовый';

  @override
  String get calendarColorRust => 'Ржавый';

  @override
  String get calendarColorBlue => 'Синий';

  @override
  String get calendarColorPlum => 'Сливовый';

  @override
  String get calendarColorOchre => 'Охра';

  @override
  String get calendarColorSage => 'Шалфейный';

  @override
  String get calendarColorRose => 'Розовый';

  @override
  String get calendarColorSlate => 'Сланцевый';

  @override
  String get calendarColorCustom => 'Свой';

  @override
  String get calendarWidgetEvents => 'Показано событий';

  @override
  String get calendarWidgetDays => 'Показано дней';

  @override
  String get calendarWidgetTomorrow => 'Сегодня и завтра';

  @override
  String get calendarWidgetWeek => 'Следующие 7 дней';

  @override
  String get calendarWidgetAllDay => 'Показывать события на весь день';

  @override
  String get calendarWidgetDots => 'Цветные точки';

  @override
  String get calendarWidgetDotsHint =>
      'Отмечать события цветом их календаря вместо фото человека.';

  @override
  String get calendarVoiceSection => 'Голосовой календарь';

  @override
  String get calendarVoiceManage =>
      'Управление календарём через Voice Satellite';

  @override
  String get calendarVoiceHint =>
      'Требуются Blueprint календаря Kiosk Satellite и диалоговый LLM-агент в Home Assistant.';

  @override
  String get calendarNewEvent => 'Новое событие';

  @override
  String get calendarEditEvent => 'Изменить событие';

  @override
  String get calendarFieldTitle => 'Название';

  @override
  String get calendarFieldTitleHint => 'Добавьте название';

  @override
  String get calendarFieldCalendars => 'Календари';

  @override
  String get calendarFieldSharedHint =>
      'Показывается один раз, разделено между их цветами.';

  @override
  String get calendarFieldStarts => 'Начало';

  @override
  String get calendarFieldEnds => 'Конец';

  @override
  String get calendarFieldStartTime => 'Время начала';

  @override
  String get calendarFieldEndTime => 'Время окончания';

  @override
  String get calendarFieldEndsBeforeStart => 'Конец раньше начала.';

  @override
  String get calendarFieldRepeat => 'Повтор';

  @override
  String get calendarRepeatNever => 'Не повторяется';

  @override
  String get calendarRepeatWeekdays => 'По будням';

  @override
  String calendarRepeatWeeklyOn(String weekday) {
    return 'Каждую неделю ($weekday)';
  }

  @override
  String calendarRepeatMonthlyOn(String day) {
    return 'Каждый месяц $day числа';
  }

  @override
  String calendarRepeatYearlyOn(String date) {
    return 'Каждый год $date';
  }

  @override
  String get calendarFieldLocation => 'Место';

  @override
  String get calendarFieldLocationHint => 'Добавьте место';

  @override
  String get calendarFieldNotes => 'Заметки';

  @override
  String get calendarFieldNotesHint => 'Добавьте заметки';

  @override
  String get calendarEventAdded => 'Событие добавлено';

  @override
  String get calendarEventSaved => 'Изменения сохранены';

  @override
  String get calendarEventDeleted => 'Событие удалено';

  @override
  String get calendarSaveFailed => 'Не удалось сохранить событие';

  @override
  String get calendarDeleteFailed => 'Не удалось удалить событие';

  @override
  String calendarEditReadOnly(String calendar) {
    return '$calendar только для чтения.';
  }

  @override
  String calendarEditGone(String calendar) {
    return 'События больше нет в $calendar.';
  }

  @override
  String calendarEditNotAllowed(String calendar) {
    return 'Пользователю Home Assistant этого киоска нельзя изменять $calendar.';
  }

  @override
  String calendarDeleteTitle(String title) {
    return 'Удалить $title?';
  }

  @override
  String calendarDeleteShared(String names) {
    return 'Событие будет удалено из всех календарей, где оно есть: $names.';
  }

  @override
  String calendarSaveRepeatTitle(String title) {
    return 'Сохранить изменения в $title?';
  }

  @override
  String get calendarSaveRepeatFollowing =>
      'Новый повтор начинается с этого дня.';

  @override
  String get calendarScopeThis => 'Это событие';

  @override
  String get calendarScopeFollowing => 'Это и следующие события';

  @override
  String get calendarScopeAll => 'Все события';

  @override
  String get calendarEditingSection => 'Редактирование';

  @override
  String get cameraViewerTitle => 'Вид камер';

  @override
  String get cameraViewerConnecting => 'Подключение…';

  @override
  String get cameraViewerReconnecting => 'Переподключение…';

  @override
  String cameraViewerTrying(String transport) {
    return 'Пробую $transport…';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return 'Это устройство не может декодировать $codec';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return 'Это устройство не может воспроизводить потоки $transport';
  }

  @override
  String get cameraViewerCannotDecodeStream =>
      'Это устройство не может декодировать этот поток';

  @override
  String cameraViewerHaRetry(String seconds) {
    return 'Home Assistant недоступен. Повтор через $seconds с';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return 'Сервер камеры недоступен. Повтор через $seconds с';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return 'Не удалось подключиться. Повтор через $seconds с';
  }

  @override
  String get cameraViewerStartRetry =>
      'Серверу камеры не удалось запустить этот поток. Повтор…';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return 'Серверу камеры не удалось запустить этот поток. Повтор через $seconds с';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return 'Поток не найден на сервере камеры. Повтор через $seconds с';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return 'Сервер камеры отклонил вход. Повтор через $seconds с';
  }

  @override
  String get cameraViewerMissing => 'Поток отсутствует в Go2RTC';

  @override
  String get commonImport => 'Импорт';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonNext => 'Далее';

  @override
  String get commonFinish => 'Завершить';

  @override
  String get commonWorking => 'Обработка…';

  @override
  String get commonSettings => 'Настройки';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonOk => 'OK';

  @override
  String get commonGrant => 'Предоставить';

  @override
  String get commonEnable => 'Включить';

  @override
  String get commonRefresh => 'Обновить';

  @override
  String get commonTest => 'Тест';

  @override
  String get commonInstall => 'Установить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get commonRemove => 'Убрать';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonClear => 'Очистить';

  @override
  String get commonBrowse => 'Обзор';

  @override
  String get commonSet => 'Задать';

  @override
  String get commonHour => 'Час';

  @override
  String get commonMinute => 'Минута';

  @override
  String get commonUp => 'Вверх';

  @override
  String get commonDown => 'Вниз';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonSaveFailed => 'Не удалось сохранить';

  @override
  String get commonColorWhite => 'Белый';

  @override
  String get commonColorWarm => 'Тёплый';

  @override
  String get commonColorAmber => 'Янтарный';

  @override
  String get commonColorRed => 'Красный';

  @override
  String get commonColorGreen => 'Зелёный';

  @override
  String get commonColorBlue => 'Синий';

  @override
  String get commonColorCyan => 'Бирюзовый';

  @override
  String get commonColorDim => 'Тусклый';

  @override
  String get commonEdit => 'Изменить';

  @override
  String get commonMoveUp => 'Переместить вверх';

  @override
  String get commonMoveDown => 'Переместить вниз';

  @override
  String get commonPreviousMonth => 'Предыдущий месяц';

  @override
  String get commonNextMonth => 'Следующий месяц';

  @override
  String get commonLoading => 'Загрузка…';

  @override
  String get commonChoose => 'Выбрать';

  @override
  String get dlnaPortInvalid =>
      'Введите порт от 1024 до 65535 или оставьте поле пустым';

  @override
  String get commonSelectAll => 'Выбрать всё';

  @override
  String get dashboardPickerSearch => 'Поиск видов';

  @override
  String get dashboardPickerSearchAll => 'Поиск панелей и видов';

  @override
  String get dashboardPickerCurrent => 'Текущий';

  @override
  String get dashboardPickerDashboards => 'Панели';

  @override
  String get dashboardPickerSubviews => 'Вложенные виды';

  @override
  String get dashboardPickerSubview => 'Вложенный вид';

  @override
  String get dashboardPickerWhole => 'Вся панель';

  @override
  String get dashboardPickerBuildsOwn => 'Создаёт виды сама';

  @override
  String get dashboardPickerIngressPage => 'Страница Ingress';

  @override
  String get dashboardPickerBuiltInPage => 'Страница Home Assistant';

  @override
  String get dashboardPickerWholeHelp =>
      'Эта панель создаёт виды сама, поэтому киоск открывает её целиком.';

  @override
  String dashboardPickerViewCount(String count) {
    return 'Видов: $count';
  }

  @override
  String get dashboardPickerOneView => '1 вид';

  @override
  String get dashboardPickerOffline =>
      'Не удалось подключиться к Home Assistant';

  @override
  String get dashboardPickerOfflineHelp =>
      'Панели загрузятся, когда соединение восстановится.';

  @override
  String get dashboardPickerTryAgain => 'Повторить';

  @override
  String get dashboardPickerEmpty => 'Панелей пока нет';

  @override
  String get dashboardPickerEmptyHelp =>
      'Панели, которые вы добавите в Home Assistant, появятся здесь.';

  @override
  String get dashboardPickerNoMatch => 'Нет подходящих видов';

  @override
  String dashboardPickerSelected(String count) {
    return 'Выбрано: $count';
  }

  @override
  String get dashboardPickerDone => 'Готово';

  @override
  String get dashboardPickerShowing => 'На экране';

  @override
  String get dashboardPickerMissing =>
      'Этого вида больше нет в Home Assistant. Выберите другой.';

  @override
  String get dashboardPickerAddViews => 'Добавить виды';

  @override
  String get dashboardPickerDefault => 'Панель по умолчанию';

  @override
  String get dashboardPickerDefaultHelp =>
      'Вид, который киоск показывает при запуске.';

  @override
  String get dashboardPickerOnePage => '1 страница';

  @override
  String dashboardPickerPageCount(String count) {
    return 'Страниц: $count';
  }

  @override
  String get dlnaCannotDecode =>
      'Это устройство не может декодировать это видео.';

  @override
  String get dlnaCannotRead => 'Не удалось прочитать этот файл.';

  @override
  String get dlnaCannotPlay => 'Не удалось воспроизвести этот медиафайл.';

  @override
  String get dlnaSeeLogs => 'Подробности в журналах приложения';

  @override
  String get dlnaLoading => 'Загрузка медиафайла';

  @override
  String get dlnaImageFailed => 'Не удалось показать это изображение.';

  @override
  String get dlnaStop => 'Остановить воспроизведение';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName: $actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => 'Действие плагина';

  @override
  String get drawerPluginActionError => 'Не удалось выполнить это действие.';

  @override
  String get drawerDashboard => 'Панель';

  @override
  String get drawerHaKiosk => 'Режим киоска HA';

  @override
  String get drawerCameraView => 'Вид камер';

  @override
  String get drawerIntercom => 'Интерком';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => 'Скрыть плавающий плеер';

  @override
  String get drawerShowPlayer => 'Показать плавающий плеер';

  @override
  String get drawerNowPlaying => 'Сейчас играет';

  @override
  String get drawerScreensaver => 'Запустить заставку';

  @override
  String get drawerLockdown => 'Режим блокировки';

  @override
  String get drawerHoldOff => 'Выключить режим удержания';

  @override
  String get drawerHoldOn => 'Включить режим удержания';

  @override
  String get drawerApps => 'Приложения';

  @override
  String get drawerClearCache => 'Очистить веб-кэш';

  @override
  String get drawerRestartDevice => 'Перезапустить устройство';

  @override
  String get drawerRestartConfirm =>
      'Перезапустить это устройство? Kiosk Satellite вернётся после загрузки.';

  @override
  String get drawerRestart => 'Перезапустить';

  @override
  String get drawerExitApplication => 'Выйти из приложения';

  @override
  String get drawerExitConfirm => 'Закрыть Kiosk Satellite?';

  @override
  String get drawerExit => 'Выйти';

  @override
  String get drawerHoldActive => 'Режим удержания включён';

  @override
  String get drawerHoldHelp =>
      'Заставка и таймеры приостановлены · нажмите, чтобы выключить';

  @override
  String get drawerThemeDark => 'Тёмная';

  @override
  String get drawerThemeLight => 'Светлая';

  @override
  String get drawerThemeAndroid => 'Как в Android';

  @override
  String get drawerItemsSearch => 'Поиск пунктов меню';

  @override
  String get drawerItemsSettingsKept =>
      'Всегда показывается, пока удалённое администрирование выключено.';

  @override
  String drawerVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get drawerUpdateAvailable => 'Доступно обновление';

  @override
  String drawerUpdateInstall(String version) {
    return 'Версия $version · нажмите, чтобы установить';
  }

  @override
  String get drawerUpdateChecking => 'Проверка обновлений…';

  @override
  String get drawerUpdateCurrent => 'Актуальная версия';

  @override
  String get drawerUpdateCurrentHelp => 'У вас установлена последняя версия.';

  @override
  String get drawerUpdateCheckFailed => 'Не удалось проверить обновления';

  @override
  String get drawerUpdateOffline => 'Устройство подключено к сети?';

  @override
  String drawerUpdateTo(String version) {
    return 'Обновить до $version';
  }

  @override
  String get drawerUpdateInstructions =>
      'Загрузка начнётся после нажатия «Обновить». Android попросит подтвердить установку.';

  @override
  String get drawerUpdateRelaunch =>
      'Без разрешения «Поверх других приложений» приложение не сможет снова открыться после обновления.';

  @override
  String get drawerUpdate => 'Обновить';

  @override
  String get drawerUpdateDownloading => 'Загрузка обновления';

  @override
  String get drawerUpdateStarting => 'Запуск…';

  @override
  String get drawerUpdateFailed => 'Не удалось обновить';

  @override
  String get drawerUpdates => 'Обновления';

  @override
  String get drawerNoReleaseNotes => 'Примечаний к выпуску нет.';

  @override
  String get entityPickerNoArea => 'Без пространства';

  @override
  String get entityPickerAll => 'Все';

  @override
  String get entityPickerChoose => 'Выберите сущность';

  @override
  String get entityPickerNoMatch => 'Ничего не найдено';

  @override
  String get entityPickerOfflineHelp =>
      'Сущности загрузятся, когда соединение восстановится.';

  @override
  String get entityPickerMissing =>
      'Этой сущности больше нет в Home Assistant. Выберите другую.';

  @override
  String get entityPickerOrderHint =>
      'Перетащите или используйте стрелки, чтобы изменить порядок.';

  @override
  String get entityPickerFull => 'Уберите одну, чтобы добавить другую.';

  @override
  String get entityPickerAdd => 'Добавить сущности';

  @override
  String entityPickerShowing(String count, String max) {
    return 'Показано: $count из $max';
  }

  @override
  String get esphomeAllExposed => 'Предоставлены все доступные сущности';

  @override
  String esphomeExcludedCount(String count) {
    return 'Исключено: $count';
  }

  @override
  String get esphomeEntitySearch => 'Поиск сущностей';

  @override
  String get esphomeEntityLoading => 'Загрузка сущностей…';

  @override
  String get esphomeEntityUnavailable => 'Сейчас недоступна';

  @override
  String get esphomeEntityNoMatch => 'Подходящих сущностей нет';

  @override
  String get esphomeEntityLoadFailed =>
      'Не удалось загрузить сущности. Закройте окно выбора и попробуйте снова.';

  @override
  String get esphomeEntitySaveFailed =>
      'Не удалось сохранить исключения. Попробуйте снова.';

  @override
  String get esphomeTypeConfig => 'Конфигурация';

  @override
  String get esphomeTypeDiagnostics => 'Диагностика';

  @override
  String get esphomeTypeSensorGroup => 'Датчик';

  @override
  String get esphomeTypeControl => 'Управление';

  @override
  String get esphomeTypeSensor => 'датчик';

  @override
  String get esphomeTypeTextSensor => 'текстовый датчик';

  @override
  String get esphomeTypeBinarySensor => 'бинарный датчик';

  @override
  String get esphomeTypeCamera => 'камера';

  @override
  String get esphomeTypeSwitch => 'переключатель';

  @override
  String get esphomeTypeButton => 'кнопка';

  @override
  String get esphomeTypeNumber => 'число';

  @override
  String get esphomeTypeSelect => 'выбор';

  @override
  String get esphomeTypeLight => 'свет';

  @override
  String get esphomeTypeUpdate => 'обновление';

  @override
  String get esphomeTypeText => 'текст';

  @override
  String get filesUpload => 'Загрузить файл';

  @override
  String get filesUploading => 'Загрузка…';

  @override
  String get filesUploadFailed => 'Не удалось загрузить';

  @override
  String get filesUploaded => 'Загружено';

  @override
  String filesUploadingProgress(String current, String total) {
    return 'Загрузка $current из $total…';
  }

  @override
  String filesUploadedCount(String count) {
    return 'Загружено файлов: $count';
  }

  @override
  String get filesPermissionMissing => 'Нет разрешения «Доступ ко всем файлам»';

  @override
  String get filesPermissionHelp =>
      'Без него доступна только папка приложения. Экран выдачи разрешения откроется на планшете.';

  @override
  String get filesGrant => 'Предоставить на устройстве';

  @override
  String get filesUp => 'На уровень вверх';

  @override
  String get filesShared => 'Общее хранилище';

  @override
  String get filesApp => 'Папка приложения';

  @override
  String get filesReadFailed => 'Не удалось прочитать папку';

  @override
  String get filesEmpty => 'Пустая папка';

  @override
  String get filesEmptyHelp => 'Здесь пока ничего нет.';

  @override
  String get filesFolder => 'Папка';

  @override
  String get filesDownload => 'Скачать';

  @override
  String get filesDownloadFailed => 'Не удалось скачать';

  @override
  String filesDeleteTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String get filesDeleteHelp => 'Файл будет удалён с устройства.';

  @override
  String get filesInvalidPath => 'Недопустимый путь';

  @override
  String get filesNoFolder => 'Папка не найдена';

  @override
  String get filesNoFile => 'Файл не найден';

  @override
  String filesReadError(String error) {
    return 'Не удалось прочитать папку: $error';
  }

  @override
  String filesWriteError(String error) {
    return 'Ошибка записи: $error';
  }

  @override
  String get filesDeleteFailed => 'Не удалось удалить файл';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin =>
      'Для управления группой киосков нужно удалённое администрирование';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Через него киоски находят друг друга. Включите «Удалённое управление» и «Поиск других киосков» в разделе «Устройство», затем вернитесь.';

  @override
  String get fleetLeadThisFleet => 'Вести эту группу';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      'Синхронизировать настройки этого киоска с его ведомыми. Все киоски должны работать на одной версии.';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead =>
      'Киоск, который следует за ведущим, не может вести группу сам.';

  @override
  String get fleetFollowers => 'Ведомые';

  @override
  String get fleetProfiles => 'Профили';

  @override
  String get fleetLeader => 'Ведущий';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      'Узнайте, какие настройки синхронизируются, а какие нет, в ';

  @override
  String get fleetFleetManagementDocumentation =>
      'документации по управлению группой киосков';

  @override
  String get fleetMore => 'Ещё';

  @override
  String get fleetSearchFollowers =>
      'Киоски, которыми управляет этот, их состояние и способ добавить новый.';

  @override
  String get fleetAddAKiosk => 'Добавить киоск';

  @override
  String get fleetAddAKioskFollowerAcceptsOnScreenOrRemoteAdmin =>
      'Добавьте найденный киоск или введите его IP-адрес. Ведомый примет приглашение на своём экране или в своём удалённом администрировании.';

  @override
  String get fleetSendInvitation => 'Отправить приглашение';

  @override
  String get fleetInviteAgain => 'Пригласить снова';

  @override
  String fleetRemoveName(String name) {
    return 'Убрать $name?';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      'Он перестанет следовать за этим киоском и сохранит свои настройки.';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name хочет вести этот киоск';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      'С этого момента его настройки заменяют настройки этого киоска в синхронизируемых категориях. Имя и идентификационные данные киоска сохраняются.';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      'С этого момента его настройки заменяют настройки этого киоска в синхронизируемых категориях. Киоск сохраняет своё имя, собственные идентификационные данные в Home Assistant, Music Assistant и ESPHome и выбор оборудования. Выйти из группы можно в любой момент: Настройки, «Управление группой киосков».';

  @override
  String get fleetAccept => 'Принять';

  @override
  String get fleetLookingForOtherKiosks => 'Поиск других киосков…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      'Киоски не найдены. Используйте «Добавить по IP», чтобы найти киоск по известному адресу.';

  @override
  String fleetFollowsName(String name) {
    return 'Ведущий: $name';
  }

  @override
  String get fleetLeadsAFleet => 'Ведёт группу';

  @override
  String get fleetNoFleetManagement => 'Без управления группой киосков';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      'Киоски в этой сети, которые не следуют за этим. Выберите один, укажите, что он получит, и приглашение уйдёт. Киоск на сборке без управления группой киосков присоединится, когда получит её.';

  @override
  String get fleetJoinedTheFleet => 'Присоединился к группе';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly =>
      'Настройки от ведущего скоро прибудут.';

  @override
  String get fleetAddByIp => 'Добавить по IP';

  @override
  String get fleetFindKiosk => 'Найти киоск';

  @override
  String get fleetFindingKiosk => 'Поиск киоска…';

  @override
  String get fleetIpAddress => 'IP-адрес';

  @override
  String get fleetRemoteAdminPort => 'Порт удалённого администрирования';

  @override
  String get fleetAddressHelp =>
      'Введите IP-адрес киоска и порт удалённого администрирования.';

  @override
  String get fleetAddAProfile => 'Добавить профиль';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      'Набор настроек, учётных данных и исключений для синхронизации.';

  @override
  String get fleetNewProfile => 'Новый профиль';

  @override
  String get fleetProfile => 'Профиль';

  @override
  String get fleetUpdatesOnly => 'Только обновления';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed =>
      'Ничего не синхронизируется. Передаются только обновления.';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return 'Категории: $selected из $total. Учётные данные: $credentials из $credentialTotal. Исключено: $excluded.';
  }

  @override
  String get fleetThisProfileIsGone => 'Этого профиля больше нет';

  @override
  String get fleetItWasDeletedFromAnotherPage =>
      'Он был удалён на другой странице.';

  @override
  String get fleetName => 'Название';

  @override
  String get fleetRename => 'Переименовать';

  @override
  String get fleetRenameProfile => 'Переименование профиля';

  @override
  String get fleetWhatItSyncs => 'Что синхронизируется';

  @override
  String get fleetNothing => 'Ничего';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      'Киоски с этим профилем сохраняют все собственные настройки. Ведущий лишь передаёт им обновления.';

  @override
  String get fleetCategories => 'Категории';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected из $total: $names';
  }

  @override
  String get fleetCredentials => 'Учётные данные';

  @override
  String get fleetNoneTravel => 'Не переносятся';

  @override
  String get fleetIncludeTheDashboard => 'Синхронизировать панель';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard =>
      'Стартовая страница и панель по умолчанию.';

  @override
  String get fleetExcludedSettings => 'Исключённые настройки';

  @override
  String get fleetOneSettingLeftOut => 'Исключена одна настройка';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return 'Исключено настроек: $count';
  }

  @override
  String get fleetNoKiosksAssigned => 'Киоски не назначены';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      'Назначьте этот профиль киоску на странице «Управление группой киосков».';

  @override
  String get fleetDuplicate => 'Дублировать';

  @override
  String get fleetCloneThisProfileIntoANewOne => 'Создать копию этого профиля.';

  @override
  String get fleetDuplicateProfile => 'Копия профиля';

  @override
  String fleetNameCopy(String name) {
    return '$name (копия)';
  }

  @override
  String get fleetDeleteProfile => 'Удалить профиль';

  @override
  String get fleetNoKioskIsOnIt => 'Ни один киоск его не использует.';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile =>
      'Киоски с ним получат профиль «По умолчанию».';

  @override
  String fleetDeleteName(String name) {
    return 'Удалить $name?';
  }

  @override
  String get fleetBlackScreens => 'Чёрные экраны';

  @override
  String fleetSyncToName(String name) {
    return 'Синхронизировать с $name';
  }

  @override
  String get fleetDefault => 'По умолчанию';

  @override
  String get fleetNone => 'Нет';

  @override
  String get fleetSearchProfiles =>
      'Именованные списки для ведомого: категории, учётные данные, панель и исключённые настройки.';

  @override
  String get fleetSyncNow => 'Синхронизировать сейчас';

  @override
  String get fleetChangedHereWaitingForTheLeader =>
      'Изменено здесь, ожидание ведущего';

  @override
  String fleetSyncedTime(String time) {
    return 'Синхронизировано $time';
  }

  @override
  String get fleetWaitingForTheFirstSync => 'Ожидание первой синхронизации';

  @override
  String get fleetNothingYet => 'Пока ничего';

  @override
  String get fleetNoCredentials => 'Без учётных данных';

  @override
  String fleetWithTheNames(String names) {
    return 'Учётные данные: $names';
  }

  @override
  String get fleetTheDashboard => 'панель';

  @override
  String get fleetNoDashboard => 'без панели';

  @override
  String get fleetTheDashboardDetail => 'Панель';

  @override
  String get fleetNoDashboardDetail => 'Без панели';

  @override
  String get fleetSyncedFromTheLeader => 'Синхронизировано от ведущего';

  @override
  String get fleetLeaveTheFleet => 'Покинуть группу';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre =>
      'Останавливает синхронизацию. Настройки остаются как есть.';

  @override
  String get fleetLeaveTheFleetDetail => 'Покинуть группу?';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name перестанет присылать настройки сюда. Всё останется как есть сейчас.';
  }

  @override
  String get fleetLeave => 'Покинуть';

  @override
  String get fleetJustNow => 'только что';

  @override
  String fleetCountMinAgo(String count) {
    return '$count мин назад';
  }

  @override
  String fleetCountHAgo(String count) {
    return '$count ч назад';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return '$count дн назад';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return 'Этими настройками управляет $name. Изменение здесь будет заменено при следующей синхронизации.';
  }

  @override
  String get fleetDeclinedOnTheKiosk => 'Отклонено на киоске';

  @override
  String get fleetWaitingForItsOk => 'Ожидание его подтверждения';

  @override
  String get fleetLeftTheFleet => 'Покинул группу';

  @override
  String fleetSendingPercent(String percent) {
    return 'Отправка $percent%';
  }

  @override
  String get fleetInstalling => 'Установка';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return 'Работает на $version, этому киоску нужно обновление';
  }

  @override
  String fleetNeedsVersion(String version) {
    return 'Нужна версия $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return 'Загрузка $percent%';
  }

  @override
  String get fleetSyncing => 'Синхронизация…';

  @override
  String get fleetErrorUnreachable => 'Недоступен';

  @override
  String get fleetErrorBadAnswer => 'Неверный ответ';

  @override
  String get fleetErrorThePushFailed => 'Не удалось передать';

  @override
  String get fleetErrorLeadThisFleetIsOff => '«Вести эту группу» выключено';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      'Удалённое администрирование и «Поиск других киосков» должны быть включены';

  @override
  String get fleetErrorPickAnotherKiosk => 'Выберите другой киоск';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      'Этот киоск сейчас не в сети';

  @override
  String get fleetErrorThatKioskDidNotAnswer => 'Киоск не ответил';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation =>
      'Киоск отклонил приглашение';

  @override
  String get fleetErrorTheDefaultProfileStays =>
      'Профиль «По умолчанию» остаётся';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays =>
      'Профиль «Только обновления» остаётся';

  @override
  String get fleetErrorNoSuchProfile => 'Профиль не найден';

  @override
  String get fleetErrorNoSuchFollower => 'Ведомый не найден';

  @override
  String get fleetErrorNoInvitationIsWaiting => 'Приглашений нет';

  @override
  String get fleetErrorMalformedInvitation => 'Повреждённое приглашение';

  @override
  String get fleetErrorCouldNotMintAToken => 'Не удалось создать токен';

  @override
  String get fleetErrorNotAFollowerYet => 'ещё не ведомый';

  @override
  String get fleetErrorOffline => 'не в сети';

  @override
  String get fleetErrorUpToDate => 'уже актуальная версия';

  @override
  String get fleetErrorAlreadyDownloading => 'уже загружается';

  @override
  String get fleetErrorDidNotAnswer => 'не ответил';

  @override
  String get fleetErrorDidNotTakeTheUpload => 'не принял передачу';

  @override
  String fleetProfileNameExists(String name) {
    return 'Профиль с названием $name уже существует';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return 'уже на версии $version';
  }

  @override
  String get fleetUnsupportedBuild =>
      'Киоск работает на сборке без управления группой киосков. Он присоединится, когда получит её.';

  @override
  String get fleetErrorAddressMismatch =>
      'Адрес принадлежит другому киоску или группе';

  @override
  String get fleetErrorInvalidIp => 'Введите корректный IP-адрес.';

  @override
  String get fleetErrorInvalidPort => 'Введите порт от 1 до 65535.';

  @override
  String get fleetErrorIdentityNotReady =>
      'Идентификационные данные этого киоска ещё не готовы. Попробуйте позже.';

  @override
  String get fleetErrorInvalidIdentity =>
      'По этому адресу не вернулись корректные идентификационные данные киоска.';

  @override
  String get fleetErrorAlreadyMember => 'Этот киоск уже входит в группу.';

  @override
  String get fleetErrorIsLeader => 'Этот киоск ведёт группу.';

  @override
  String get fleetErrorOtherLeader =>
      'Этот киоск уже следует за другим ведущим.';

  @override
  String fleetPluginsNames(String names) {
    return 'Плагины: $names';
  }

  @override
  String fleetCouldNotInstallNameReason(String name, String reason) {
    return 'Не удалось установить $name: $reason';
  }

  @override
  String fleetReinstallNameOnThisKioskToSyncIt(String name) {
    return 'Переустановите $name на этом киоске, чтобы синхронизировать его';
  }

  @override
  String get fleetSwitchKiosk => 'Сменить киоск';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      'Найденные киоски и сохранённые участники группы. При выборе киоска его удалённое администрирование откроется здесь, на этой же странице.';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      'Другие киоски не найдены. Киоски появляются через обнаружение в сети или сохранённое участие в группе.';

  @override
  String get fleetSyncedCredentials => 'Синхронизируемые учётные данные';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced =>
      'Настройки из этого списка не будут синхронизироваться с ведомыми.';

  @override
  String get fleetNothingLeftOut => 'Ничего не исключено';

  @override
  String get fleetSyncItAgain => 'Синхронизировать снова';

  @override
  String get fleetAddASetting => 'Добавить настройку';

  @override
  String get fleetExcludeASetting => 'Исключить настройку';

  @override
  String get fleetSearchSettings => 'Поиск настроек';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return 'Ещё $count. Введите текст, чтобы сузить список.';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return 'Не синхронизируется: $note';
  }

  @override
  String get fleetTheAssignedSatellite => 'назначенный спутник';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain =>
      'устройства микрофона и динамика, усиление микрофона';

  @override
  String get fleetTheDeviceCamera => 'камера устройства';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      'отслеживаемый плеер, идентификатор плеера Sendspin';

  @override
  String get fleetNodeNameMacEncryptionKey =>
      'имя узла, MAC-адрес, ключ шифрования';

  @override
  String get fleetThePinIsAlsoSynced => 'PIN-код также синхронизируется';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential =>
      'ключ, кроме случая, когда он синхронизируется как учётные данные';

  @override
  String get fleetTheAlarmsThemselves => 'сами будильники';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'имя, удалённое администрирование, обходные пути рендерера, масштаб';

  @override
  String get fleetHomeAssistantToken => 'токен Home Assistant';

  @override
  String get fleetMusicAssistantToken => 'токен Music Assistant';

  @override
  String get fleetImmichApiKey => 'API-ключ Immich';

  @override
  String get fleetOpenAiApiKey => 'API-ключ OpenAI';

  @override
  String get fleetXaiApiKey => 'API-ключ xAI';

  @override
  String get fleetGeminiApiKey => 'API-ключ Gemini';

  @override
  String get fleetMcpServerToken => 'токен сервера MCP';

  @override
  String get fleetPlugins => 'Плагины';

  @override
  String get fleetPluginSecrets => 'Секреты плагинов';

  @override
  String get fleetNoPluginsInstalledOnThisKiosk =>
      'На этом киоске нет плагинов';

  @override
  String get fleetKiosksOnThisProfileInstallTheseAndTakeTheir =>
      'Киоски с этим профилем устанавливают их и берут их настройки с этого киоска.';

  @override
  String get fleetUpdateTheFleet => 'Обновить группу';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      'Обновить всю группу до версии Kiosk Satellite, работающей на ведущем.';

  @override
  String get fleetKeepFollowersOnThisVersion =>
      'Держать ведомых на этой версии';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      'Автоматически обновлять всех ведомых до версии Kiosk Satellite, работающей на ведущем.';

  @override
  String get fleetNothingToUpdate => 'Обновлять нечего';

  @override
  String get fleetUpdating => 'Обновление';

  @override
  String fleetNamesInstalling(String names) {
    return '$names: установка.';
  }

  @override
  String get fleetSearchUpdates =>
      'Установите выпуск, предложенный каждому ведомому, затем здесь.';

  @override
  String get gestureAction => 'Действие';

  @override
  String get gestureNavigate => 'Перейти к виду панели';

  @override
  String get gestureUrl => 'Открыть веб-страницу';

  @override
  String get gestureCameraView => 'Показать вид камер';

  @override
  String get gestureLauncher => 'Открыть лаунчер приложений';

  @override
  String get gestureIntercomOpen => 'Открыть «Позвонить киоску»';

  @override
  String get gestureIntercomCall => 'Позвонить киоску';

  @override
  String get gestureIntercomHangup => 'Завершить звонок интеркома';

  @override
  String get gestureIntercomAnswer => 'Принять звонок интеркома';

  @override
  String get gestureIntercomDecline => 'Отклонить звонок интеркома';

  @override
  String get gestureAlarmStop => 'Остановить будильник';

  @override
  String get gestureAlarmSnooze => 'Отложить будильник';

  @override
  String get gestureScreensaver => 'Запустить заставку';

  @override
  String get gestureScreensaverStop => 'Остановить заставку';

  @override
  String get gestureHoldMode => 'Переключить режим удержания';

  @override
  String get gestureRefresh => 'Обновить панель';

  @override
  String get gestureMediaPlayPause => 'Воспроизвести или приостановить медиа';

  @override
  String get gestureHaKiosk => 'Переключить режим киоска HA';

  @override
  String get gesturePluginRun => 'Запустить действие плагина';

  @override
  String get gestureLaunchApp => 'Открыть другое приложение';

  @override
  String get gestureDeepLink => 'Открыть диплинк';

  @override
  String get gestureAndroidSettings => 'Открыть настройки Android';

  @override
  String get gestureOpenCalendar => 'Открыть календарь';

  @override
  String get gestureOpenMusicLibrary => 'Открыть музыкальную библиотеку';

  @override
  String get gestureService => 'Вызвать службу';

  @override
  String get gestureScript => 'Запустить сценарий';

  @override
  String get gestureAutomation => 'Запустить автоматизацию';

  @override
  String get gestureEvent => 'Вызвать событие';

  @override
  String get gesturePluginAction => 'Действие плагина';

  @override
  String get gesturePluginActions => 'Действия плагинов';

  @override
  String get gesturePluginHelp =>
      'Сначала включите плагин с действиями в менеджере плагинов.';

  @override
  String get gesturePluginFailed => 'Не удалось загрузить действия плагина.';

  @override
  String get gestureUrlError => 'Введите полный URL http(s).';

  @override
  String get gesturePackage => 'Имя пакета';

  @override
  String get gesturePackageError => 'Введите имя пакета.';

  @override
  String get gestureUriError => 'Введите полный URI.';

  @override
  String get gestureCameraTitle => 'Вид камер';

  @override
  String gestureCameraShow(String name) {
    return 'Показать $name';
  }

  @override
  String get gestureCameraClose => 'Закрыть вид камер';

  @override
  String get gestureCameraEmpty => 'Виды камер пока не настроены.';

  @override
  String get gestureIntercomEmpty => 'Киоски в сети пока не найдены.';

  @override
  String get gestureVoiceWake => 'Начать голосовую команду';

  @override
  String get gestureVoiceStop => 'Остановить голосового ассистента';

  @override
  String get gestureVoiceMute => 'Выключить или включить звук Voice Satellite';

  @override
  String get gestureOpenAlarmList => 'Открыть список будильников';

  @override
  String get gestureOpenTimers => 'Открыть таймеры';

  @override
  String get gestureOpenNextAlarm => 'Открыть следующий будильник';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '$count нажатий в $corner углу';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return 'Удержание в $corner углу $seconds с';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return 'Двойное касание $count пальцами';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return 'Касание $count пальцами';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return 'Удержание $count пальцами в течение $seconds с';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return 'Последовательность углов: $sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '$count хлопка';
  }

  @override
  String get gestureDescribeOpenHand => 'Показать открытую ладонь';

  @override
  String gestureDescribeOneFinger(String count) {
    return 'Показать $count палец';
  }

  @override
  String gestureDescribeFingers(String count) {
    return 'Показать $count пальца';
  }

  @override
  String get gestureTopLeft => 'верхнем левом';

  @override
  String get gestureTopRight => 'верхнем правом';

  @override
  String get gestureBottomLeft => 'нижнем левом';

  @override
  String get gestureBottomRight => 'нижнем правом';

  @override
  String gestureGoTo(String value) {
    return 'Переход: $value';
  }

  @override
  String gestureOpen(String value) {
    return 'Открыть $value';
  }

  @override
  String get gestureCameraToggle => 'Переключить вид камер';

  @override
  String gestureCameraToggleName(String name) {
    return 'Переключить вид камер $name';
  }

  @override
  String gestureCall(String value) {
    return 'Звонок: $value';
  }

  @override
  String gestureOpenApp(String package) {
    return 'Открыть приложение $package';
  }

  @override
  String gestureRun(String value) {
    return 'Запустить $value';
  }

  @override
  String gestureTriggerAction(String value) {
    return 'Запустить $value';
  }

  @override
  String gestureFireEvent(String value) {
    return 'Вызвать событие $value';
  }

  @override
  String gestureDescribeButtonPress(String button) {
    return 'Нажать кнопку $button';
  }

  @override
  String gestureDescribeButtonDouble(String button) {
    return 'Дважды нажать кнопку $button';
  }

  @override
  String gestureDescribeButtonHold(String button) {
    return 'Удерживать кнопку $button';
  }

  @override
  String get gestureValid => 'Всё в порядке.';

  @override
  String get gestureValidationFailed => 'Не удалось проверить.';

  @override
  String gestureDomainMissing(String value) {
    return 'Домен $value не найден.';
  }

  @override
  String gestureServiceMissing(String value) {
    return 'Служба $value не найдена.';
  }

  @override
  String gestureEntityMissing(String value) {
    return 'Сущность $value не найдена.';
  }

  @override
  String gestureEntityRequired(String domain) {
    return 'Введите сущность вида $domain.*';
  }

  @override
  String get gestureScriptEntity => 'Сущность сценария';

  @override
  String get gestureAutomationEntity => 'Сущность автоматизации';

  @override
  String get gestureEntityOptional => 'Сущность (необязательно)';

  @override
  String get gestureServiceData => 'Данные службы (необязательно)';

  @override
  String get gestureServiceTitle => 'Вызвать службу Home Assistant';

  @override
  String get gestureServiceJson => 'Данные службы должны быть JSON-объектом.';

  @override
  String get gestureEventType => 'Тип события';

  @override
  String get gestureEventData => 'Данные события (необязательно)';

  @override
  String get gestureEventTitle => 'Вызвать событие Home Assistant';

  @override
  String get gestureEventRequired => 'Тип события обязателен.';

  @override
  String get gestureEventJson => 'Данные события должны быть JSON-объектом.';

  @override
  String get gestureServiceSearch => 'Поиск служб';

  @override
  String get gestureServiceChoose => 'Выберите службу';

  @override
  String get gestureServiceNoEntity => 'Эта служба его не использует';

  @override
  String get gestureTester => 'Тестер жестов рукой';

  @override
  String get gestureOpenTester => 'Открыть тестер';

  @override
  String get gestureCameraFirst =>
      'Сначала включите камеру в настройках камеры.';

  @override
  String get gestureTesterHelp =>
      'Смотрите, какие пальцы считывает камера, чтобы понять, как держать руку.';

  @override
  String get gestureHandHelp =>
      'Держите руку на высоте плеча ладонью к камере, пальцы расставлены. Полностью согните палец, чтобы он не считался. Прижмите большой палец к ладони, чтобы показать четыре: большой палец считается только на открытой ладони.';

  @override
  String get gestureTesterPaused => 'Жесты не срабатывают, пока открыт тестер.';

  @override
  String get gestureShowHand => 'Покажите руку камере.';

  @override
  String gestureTesterTrigger(String action) {
    return 'Срабатывает: $action';
  }

  @override
  String get gestureNoCount => 'Ни один жест не использует это количество.';

  @override
  String get gestureNoHand => 'Руки в кадре нет';

  @override
  String get gestureReadingHand => 'Распознавание руки';

  @override
  String get gestureNoFingers => 'Пальцы не подняты';

  @override
  String gestureHandsCount(String count) {
    return 'Рук в кадре: $count, читается большая.';
  }

  @override
  String get gestureTesterSearch =>
      'Пальцы, которые распознаёт камера, в реальном времени.';

  @override
  String get gestureHoldConfirmed => 'Удержание подтверждено';

  @override
  String gestureHoldProgress(String progress) {
    return 'Прогресс удержания: $progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return 'Длительность удержания: $duration';
  }

  @override
  String get gestureHaServiceKind => 'Служба Home Assistant';

  @override
  String get gestureHaScriptKind => 'Сценарий Home Assistant';

  @override
  String get gestureHaAutomationKind => 'Автоматизация Home Assistant';

  @override
  String get gestureHaEventKind => 'Событие Home Assistant';

  @override
  String gestureRan(String value) {
    return 'Запущено: $value';
  }

  @override
  String gestureRunFailed(String value) {
    return 'Не удалось запустить $value';
  }

  @override
  String gestureCalled(String value) {
    return 'Вызвано: $value';
  }

  @override
  String gestureCallFailed(String value) {
    return 'Не удалось вызвать $value';
  }

  @override
  String gestureTriggered(String value) {
    return 'Запущено: $value';
  }

  @override
  String gestureTriggerFailed(String value) {
    return 'Не удалось запустить $value';
  }

  @override
  String gestureFired(String value) {
    return 'Вызвано событие $value';
  }

  @override
  String gestureFireFailed(String value) {
    return 'Не удалось вызвать событие $value';
  }

  @override
  String get gestureDone => 'Готово';

  @override
  String get gestureFailed => 'Не удалось';

  @override
  String get gestureEdit => 'Изменить жест';

  @override
  String get gestureTrigger => 'Жест';

  @override
  String get gestureCornerTaps => 'Нажатия в углу';

  @override
  String get gestureCornerHold => 'Удержание угла';

  @override
  String get gestureFingerTaps => 'Касание несколькими пальцами';

  @override
  String get gestureFingerHold => 'Удержание несколькими пальцами';

  @override
  String get gestureSequence => 'Последовательность углов';

  @override
  String get gestureClaps => 'Хлопки';

  @override
  String get gestureShowFingers => 'Показ пальцев';

  @override
  String get gestureCorner => 'Угол';

  @override
  String get gestureCornerTl => 'Верхний левый угол';

  @override
  String get gestureCornerTr => 'Верхний правый угол';

  @override
  String get gestureCornerBl => 'Нижний левый угол';

  @override
  String get gestureCornerBr => 'Нижний правый угол';

  @override
  String get gestureTaps => 'Нажатия';

  @override
  String get gestureTaps2 => '2 нажатия';

  @override
  String get gestureTaps3 => '3 нажатия';

  @override
  String get gestureTaps4 => '4 нажатия';

  @override
  String get gestureFingers => 'Пальцы';

  @override
  String get gestureFinger1 => '1 палец';

  @override
  String get gestureFinger2 => '2 пальца';

  @override
  String get gestureFinger3 => '3 пальца';

  @override
  String get gestureFinger4 => '4 пальца';

  @override
  String get gestureOpenHand5 => 'Открытая ладонь (5)';

  @override
  String get gestureSingleTap => 'Одинарное касание';

  @override
  String get gestureDoubleTap => 'Двойное касание';

  @override
  String gestureHoldDuration(String seconds) {
    return 'Удержание $seconds с';
  }

  @override
  String get gestureCameraHelp =>
      'Требуется включённая камера и хорошее освещение.';

  @override
  String get gestureUnavailable => 'Недоступно на этом устройстве.';

  @override
  String get gestureClaps2 => '2 хлопка';

  @override
  String get gestureClaps3 => '3 хлопка';

  @override
  String get gestureClaps4 => '4 хлопка';

  @override
  String get gestureClapHelp =>
      'Хлопки распознаются через микрофон, с определением слова пробуждения или без него.';

  @override
  String get gestureSequenceHelp =>
      'Нажимайте углы по порядку (от 2 до 8 шагов).';

  @override
  String get gestureRemoveStep => 'Убрать последний шаг';

  @override
  String get gestureUndo => 'Отменить';

  @override
  String get gestureChooseAction => 'Выберите действие';

  @override
  String get gestureActionHelp => 'Что запускает этот жест.';

  @override
  String get gestureChangeHelp => 'Нажмите, чтобы изменить.';

  @override
  String get gestureChooseError => 'Выберите действие.';

  @override
  String get gestureSequenceError => 'Добавьте минимум два угла.';

  @override
  String get gesturePluginTrigger => 'Триггер плагина';

  @override
  String get gesturePluginTriggerField => 'Триггер';

  @override
  String get gesturePluginTriggerHelp =>
      'Сначала включите плагин с триггерами в менеджере плагинов.';

  @override
  String get gestureButton => 'Кнопка';

  @override
  String get gesturePress => 'Нажатие';

  @override
  String get gestureDoublePress => 'Двойное нажатие';

  @override
  String get gestureHoldPress => 'Удержание';

  @override
  String get gestureButtonDefaults =>
      'Нажатие, которое не использует ни один жест, сохраняет свою роль: Действие отвечает, останавливает или отклоняет то, что звонит, а иначе начинает голосовую команду, Микрофон выключает Voice Satellite, а кнопки громкости меняют громкость.';

  @override
  String get intercomCall => 'Позвонить';

  @override
  String get intercomNoReady => 'Нет готовых киосков.';

  @override
  String get intercomOneReady => 'Один киоск готов.';

  @override
  String intercomManyReady(String count) {
    return 'Готово киосков: $count.';
  }

  @override
  String get intercomCallKiosk => 'Позвонить киоску';

  @override
  String get intercomAnnounceAll => 'Объявить всем';

  @override
  String get intercomAnnounceHelp =>
      'Говорить со всеми киосками. Только в одну сторону.';

  @override
  String intercomMissedFrom(String name) {
    return 'Пропущенный звонок: $name';
  }

  @override
  String intercomRangFor(String seconds) {
    return 'Звонил $seconds с.';
  }

  @override
  String get intercomCallBack => 'Позвонить обратно';

  @override
  String get intercomDeclined => 'Отклонено';

  @override
  String get intercomBusy => 'Занято';

  @override
  String get intercomPeerOff => 'Его интерком выключен';

  @override
  String get intercomPeerKey => 'Другой ключ интеркома';

  @override
  String get intercomNoAnswer => 'Нет ответа';

  @override
  String get intercomDidNotAnswer => 'Не ответил';

  @override
  String get intercomVoiceFailed => 'Не удалось установить голосовую связь';

  @override
  String get intercomCancelled => 'Отменено';

  @override
  String get intercomPageMic => 'Страница заняла микрофон';

  @override
  String get intercomNobody => 'Никто не мог принять';

  @override
  String get intercomDone => 'Завершено';

  @override
  String get intercomEnded => 'Звонок завершён';

  @override
  String get intercomMaxDurationReached =>
      'Достигнута максимальная длительность звонка';

  @override
  String get intercomAnnouncement => 'Объявление';

  @override
  String get intercomAnnouncingOne => 'Объявление для одного киоска';

  @override
  String intercomAnnouncingMany(String count) {
    return 'Объявление для киосков: $count';
  }

  @override
  String get intercomIsCalling => 'звонит';

  @override
  String get intercomIsAnnouncing => 'объявляет';

  @override
  String get intercomCalling => 'Вызов…';

  @override
  String intercomAnswersWithCameraIn(String seconds) {
    return 'Камера включится через $seconds с';
  }

  @override
  String intercomAnswersIn(String seconds) {
    return 'Ответит через $seconds с';
  }

  @override
  String get intercomRinging => 'Звонок';

  @override
  String get intercomConnecting => 'Подключение…';

  @override
  String intercomDoneDuration(String duration) {
    return 'Завершено, $duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return 'Звонок завершён, $duration';
  }

  @override
  String get intercomDecline => 'Отклонить';

  @override
  String get intercomAnswer => 'Ответить';

  @override
  String get intercomEveryKiosk => 'Все киоски';

  @override
  String get intercomStop => 'Остановить';

  @override
  String intercomHearsYou(String name) {
    return '$name вас слышит';
  }

  @override
  String get intercomAllHearYou => 'Все киоски вас слышат';

  @override
  String get intercomHoldHelp =>
      'Удерживайте, чтобы говорить; отпустите, чтобы слушать';

  @override
  String get intercomMuted => 'Микрофон выключен';

  @override
  String get intercomMute => 'Выключить микрофон';

  @override
  String get intercomEnd => 'Завершить';

  @override
  String get intercomReply => 'Ответить';

  @override
  String get intercomDismiss => 'Скрыть';

  @override
  String get intercomCallAgain => 'Позвонить снова';

  @override
  String get intercomDashboardMic =>
      'Панель удерживает микрофон, только прослушивание.';

  @override
  String get intercomMicDenied =>
      'Микрофон не предоставлен, только прослушивание.';

  @override
  String get intercomHoldTalk => 'Удерживайте, чтобы говорить';

  @override
  String get intercomPlaying => 'Воспроизведение';

  @override
  String get intercomAKiosk => 'киоск';

  @override
  String intercomCallingName(String name) {
    return 'Вызов: $name';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name звонит';
  }

  @override
  String intercomInCallName(String name) {
    return 'Разговор: $name';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name объявляет';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant: $message';
  }

  @override
  String get intercomEndCall => 'Завершить звонок';

  @override
  String get intercomVoiceCall => 'Голосовой звонок';

  @override
  String get intercomVideoCall => 'Видеозвонок';

  @override
  String get intercomVoiceOnly => 'Только голос';

  @override
  String get intercomVideoAnswer => 'Видео';

  @override
  String get intercomSwitchCamera => 'Переключить камеру';

  @override
  String get intercomCameraButton => 'Камера';

  @override
  String get intercomCameraOff => 'Камера выключена';

  @override
  String get intercomYourCameraOff => 'Ваша камера выключена';

  @override
  String get intercomVideoReconnecting => 'Восстановление видео…';

  @override
  String get intercomCameraOffNotice =>
      'Камера выключена. Этот киоск может показывать видео, но не отправлять его.';

  @override
  String get intercomCallFailed => 'Не удалось позвонить';

  @override
  String get intercomKeyFailed => 'Не удалось изменить ключ';

  @override
  String get intercomBroadcastFailed => 'Не удалось связаться со всеми';

  @override
  String get intercomDeviceNoAnswer => 'Устройство не ответило.';

  @override
  String get intercomUnknownKiosk => 'неизвестный киоск';

  @override
  String get intercomNothingRinging => 'ничего не звонит';

  @override
  String get intercomNoCall => 'нет звонка';

  @override
  String get intercomDisabled => 'интерком выключен';

  @override
  String get intercomNeedsRemote => 'нужно удалённое администрирование';

  @override
  String get intercomNeedsDiscovery =>
      'интеркому нужны удалённое администрирование и «Поиск других киосков»';

  @override
  String get intercomAlreadyCalling => 'уже идёт звонок';

  @override
  String get intercomNoReadyError => 'нет готовых киосков';

  @override
  String get intercomKeyLength => 'ключ должен содержать не менее 16 символов';

  @override
  String get intercomMicHeld => 'страница удерживает микрофон';

  @override
  String get intercomMicPermission => 'микрофон не предоставлен';

  @override
  String get intercomCallerNoAnswer => 'звонящий не ответил';

  @override
  String get intercomMissedcall => 'Пропущенный звонок';

  @override
  String get intercomListening => 'Прослушивание';

  @override
  String get intercomAnnouncementsoff => 'Объявления выключены';

  @override
  String get intercomEncryptionMismatch => 'Несовпадение шифрования';

  @override
  String get intercomEncryptionMismatchHelp =>
      'Несовпадение шифрования. Включите «Шифровать связь» на всех киосках в звонке.';

  @override
  String get kioskBackClose =>
      'Нажмите «Назад» ещё раз, чтобы закрыть приложение';

  @override
  String get kioskBackAgain => 'Нажмите «Назад» ещё раз, чтобы вернуться';

  @override
  String get kioskHoldOn => 'Режим удержания включён';

  @override
  String get kioskHoldOff => 'Режим удержания выключен';

  @override
  String get kioskHoldNotice =>
      'Текущий экран останется, пока вы не выключите режим удержания.';

  @override
  String get kioskDownloadComplete => 'Загрузка завершена';

  @override
  String get kioskDownloadFailed => 'Не удалось загрузить';

  @override
  String get kioskDownload => 'Скачать';

  @override
  String get kioskDownloading => 'Загрузка';

  @override
  String get kioskOpen => 'Открыть';

  @override
  String get kioskTip => 'Подсказка';

  @override
  String get kioskMenuHint => 'Проведите от левого края, чтобы открыть меню.';

  @override
  String get kioskUnknownLink => 'Неизвестная ссылка киоска';

  @override
  String get kioskOpenAppFailed => 'Не удалось открыть приложение';

  @override
  String get kioskWebViewMissing => 'Android System WebView не установлен';

  @override
  String get kioskWebViewMissingHelp =>
      'На устройстве нет провайдера WebView, поэтому Home Assistant не может быть показан. Установите Android System WebView или Chrome, затем перезапустите Kiosk Satellite.';

  @override
  String get kioskDuraSpeedBlocking => 'DuraSpeed блокирует панель';

  @override
  String get kioskDuraSpeedBlockingHelp =>
      'DuraSpeed этого планшета не даёт запуститься рендереру панели, а на некоторых планшетах у него нет страницы настроек. Выключите его один раз через adb, затем перезапустите Kiosk Satellite:';

  @override
  String get kioskPinTitle => 'PIN-код киоска';

  @override
  String get kioskPinHint => 'PIN';

  @override
  String get kioskWrongPin => 'Неверный PIN';

  @override
  String get kioskUnlock => 'Разблокировать';

  @override
  String get lockdownScreenLocked => 'Экран заблокирован';

  @override
  String get logsWebConsole => 'Веб-консоль';

  @override
  String get logsDock => 'Закрепить над текущей страницей';

  @override
  String get logsNoOutput => 'Вывода в консоль пока нет';

  @override
  String get logsShareSubject => 'Журнал консоли Kiosk Satellite';

  @override
  String get logsInput => 'Выполнить JavaScript на странице';

  @override
  String get logsInputHistory =>
      'Выполнить JavaScript на странице (Enter: выполнить, стрелки вверх/вниз: история)';

  @override
  String get logsRun => 'Выполнить';

  @override
  String get logsEvaluationFailed => 'ошибка вычисления';

  @override
  String get logsDeviceUnreachable => 'устройство недоступно';

  @override
  String logsEntries(String count) {
    return 'Записей: $count';
  }

  @override
  String get logsCopyLog => 'Копировать журнал';

  @override
  String get logsShareLog => 'Поделиться журналом';

  @override
  String get logsCopied => 'Скопировано';

  @override
  String get logsCopyFailed => 'Не удалось скопировать';

  @override
  String get logsOnClipboard => 'Журнал в буфере обмена.';

  @override
  String get logsConsoleOnClipboard => 'Журнал консоли в буфере обмена.';

  @override
  String get logsSystemLog =>
      'Системный журнал Android для этого приложения (сбои появляются здесь)';

  @override
  String get logsErrors => 'Ошибки и сбои';

  @override
  String get logsWarnings => 'Предупреждения';

  @override
  String get logsInfo => 'Информация и отладка';

  @override
  String get logsNoMatches =>
      'Подходящих строк нет. Включите больше типов выше, чтобы увидеть полный журнал.';

  @override
  String get logsUnavailable => 'logcat недоступен';

  @override
  String logsReadFailed(String error) {
    return 'Не удалось прочитать logcat: $error';
  }

  @override
  String get logsUnknown => 'неизвестно';

  @override
  String get libraryTitle => 'Музыкальная библиотека';

  @override
  String get librarySource => 'Источник';

  @override
  String get librarySourceMa => 'Music Assistant';

  @override
  String get librarySourceHa => 'Home Assistant';

  @override
  String get librarySourceSonos => 'Sonos';

  @override
  String get librarySourceMaHint => 'Библиотека, поиск и радио';

  @override
  String get librarySourceHaHint => 'Медиа каждого динамика';

  @override
  String get librarySourceSonosHint => 'Избранное и плейлисты';

  @override
  String get libraryDiscover => 'Обзор';

  @override
  String get librarySearch => 'Поиск';

  @override
  String get libraryBrowse => 'Обзор папок';

  @override
  String get libraryLibrary => 'Библиотека';

  @override
  String get libraryArtists => 'Исполнители';

  @override
  String get libraryAlbums => 'Альбомы';

  @override
  String get libraryTracks => 'Треки';

  @override
  String get libraryPlaylists => 'Плейлисты';

  @override
  String get libraryRadio => 'Радио';

  @override
  String get libraryPodcasts => 'Подкасты';

  @override
  String get libraryAudiobooks => 'Аудиокниги';

  @override
  String get libraryFavorites => 'Избранное';

  @override
  String get librarySonosPlaylists => 'Плейлисты Sonos';

  @override
  String get libraryRecentlyPlayed => 'Недавно прослушанное';

  @override
  String get libraryRecentlyAdded => 'Недавно добавленное';

  @override
  String get librarySort => 'Сортировка';

  @override
  String get librarySortAToZ => 'От А до Я';

  @override
  String get librarySortZToA => 'От Я до А';

  @override
  String get librarySortMostPlayed => 'Самое прослушиваемое';

  @override
  String get libraryAlbumArtistsOnly => 'Только исполнители альбомов';

  @override
  String get libraryKindGenre => 'Жанр';

  @override
  String get libraryBrowseByGenre => 'Обзор по жанрам';

  @override
  String get settingLibraryTextScaleDescription =>
      'Размер заголовков, имён и подписей в библиотеке.';

  @override
  String get settingLibrarySquareArtworkTitle => 'Квадратные обложки';

  @override
  String get settingLibrarySquareArtworkDescription =>
      'Показывает исполнителей квадратными плитками, как альбомы и плейлисты.';

  @override
  String get settingLibraryGridDensityTitle => 'Плотность сетки';

  @override
  String get settingLibraryGridDensityDescription =>
      'Размер плиток в библиотеке. Компактная вмещает больше в ряд.';

  @override
  String get settingLibrarySourcePickerTitle => 'Показывать выбор источника';

  @override
  String get settingLibrarySourcePickerDescription =>
      'Показывает выбор источника в библиотеке. Отключите, чтобы библиотека оставалась на источнике, выбранном выше.';

  @override
  String get settingLibrarySpeakerPillDescription =>
      'Показывает выбор динамика вверху библиотеки.';

  @override
  String get libraryDensityComfortable => 'Просторная';

  @override
  String get libraryDensityStandard => 'Стандартная';

  @override
  String get libraryDensityCompact => 'Компактная';

  @override
  String get libraryMoreResults => 'Другие результаты';

  @override
  String get libraryTopTracks => 'Популярные треки';

  @override
  String get libraryKindArtist => 'Исполнитель';

  @override
  String get libraryKindAlbum => 'Альбом';

  @override
  String get libraryKindTrack => 'Трек';

  @override
  String get libraryKindPlaylist => 'Плейлист';

  @override
  String get libraryKindRadio => 'Радио';

  @override
  String get libraryKindPodcast => 'Подкаст';

  @override
  String get libraryKindEpisode => 'Эпизод';

  @override
  String get libraryKindAudiobook => 'Аудиокнига';

  @override
  String get libraryOneTrack => '1 трек';

  @override
  String libraryTrackCount(String count) {
    return 'Треков: $count';
  }

  @override
  String libraryMinutes(String minutes) {
    return '$minutes мин';
  }

  @override
  String libraryHoursMinutes(String hours, String minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get librarySearchHint => 'Исполнители, альбомы, треки';

  @override
  String get librarySearchClear => 'Очистить поиск';

  @override
  String get librarySearchAll => 'Все';

  @override
  String get librarySearchPrompt =>
      'Ищите исполнителей, альбомы, треки и многое другое.';

  @override
  String get libraryEmpty => 'Здесь пока ничего нет.';

  @override
  String get libraryLoadFailed => 'Не удалось загрузить.';

  @override
  String get libraryNoSource =>
      'Настройте Music Assistant, Home Assistant или динамик Sonos, чтобы просматривать музыку.';

  @override
  String get libraryHaPickSpeaker =>
      'Выберите динамик, чтобы увидеть медиа, которые он может воспроизвести.';

  @override
  String get libraryChooseSpeaker => 'Выберите динамик';

  @override
  String get libraryPickSpeakerHint => 'Выберите динамик для воспроизведения.';

  @override
  String get libraryPlay => 'Воспроизвести';

  @override
  String get libraryOpenNowPlaying => 'Открыть «Сейчас играет»';

  @override
  String get libraryNothingPlaying => 'Ничего не воспроизводится';

  @override
  String get libraryMore => 'Другие действия';

  @override
  String get libraryPlayNow => 'Воспроизвести сейчас';

  @override
  String get libraryPlayNext => 'Воспроизвести следующим';

  @override
  String get libraryAddToQueue => 'Добавить в очередь';

  @override
  String get libraryStartRadio => 'Запустить радио';

  @override
  String get libraryGoToArtist => 'Перейти к исполнителю';

  @override
  String get libraryAddFavorite => 'Добавить в избранное';

  @override
  String get libraryRemoveFavorite => 'Удалить из избранного';

  @override
  String get libraryAddedFavorite => 'Добавлено в избранное';

  @override
  String get libraryRemovedFavorite => 'Удалено из избранного';

  @override
  String get libraryFavoriteFailed => 'Не удалось изменить избранное';

  @override
  String get libraryPlaysNext => 'Воспроизведётся следующим';

  @override
  String get libraryAddedToQueue => 'Добавлено в очередь';

  @override
  String get libraryView => 'Показать';

  @override
  String get libraryPlayFailed => 'Не удалось воспроизвести';

  @override
  String get librarySpeakers => 'Динамики';

  @override
  String get libraryPlayingOn => 'Воспроизводится на';

  @override
  String get libraryOtherSpeakers => 'Другие динамики';

  @override
  String get libraryNoOtherSpeakers => 'Других динамиков нет.';

  @override
  String get libraryThisDevice => 'Это устройство';

  @override
  String get libraryUnavailable => 'Недоступен';

  @override
  String get libraryGroup => 'Группировать';

  @override
  String get libraryGroupAll => 'Группа';

  @override
  String libraryGroupWith(String speaker) {
    return 'Группировать с $speaker';
  }

  @override
  String get libraryGroupHint =>
      'Сгруппированные динамики синхронно воспроизводят одну и ту же музыку.';

  @override
  String libraryGroupName(String speaker, String count) {
    return '$speaker + $count';
  }

  @override
  String get settingKioskAllowMusicLibraryDescription =>
      'Просматривать музыку и воспроизводить её на динамике.';

  @override
  String get libraryPageHint => 'Просмотр музыки и воспроизведение на динамике';

  @override
  String get settingLibrarySourceDescription =>
      'Откуда библиотека берёт музыку. «Автоматически» начинает с источника динамика, за которым следит «Сейчас играет».';

  @override
  String get settingLibraryNowPlayingButtonTitle =>
      'Показывать в «Сейчас играет»';

  @override
  String get settingLibraryNowPlayingButtonDescription =>
      'Добавить кнопку «Музыкальная библиотека» рядом с кнопкой закрытия.';

  @override
  String get libraryQueueTitle => 'Очередь';

  @override
  String get libraryCloseQueue => 'Закрыть очередь';

  @override
  String get libraryClear => 'Очистить';

  @override
  String get libraryClearQueueTitle => 'Очистить очередь?';

  @override
  String get libraryClearQueueMessage =>
      'Музыка остановится, а все треки будут удалены из очереди.';

  @override
  String get libraryRemoveFromQueue => 'Удалить из очереди';

  @override
  String get libraryReorder => 'Перетащите, чтобы изменить порядок';

  @override
  String get libraryQueueFailed => 'Не удалось изменить очередь';

  @override
  String get libraryVoiceSection => 'Голосовое управление';

  @override
  String get libraryVoiceManage => 'Управление музыкой через Voice Satellite';

  @override
  String get libraryVoiceHint =>
      'Требуются Blueprint музыки Kiosk Satellite и диалоговый LLM-агент в Home Assistant.';

  @override
  String get musicPickerTitle => 'Выбор музыки';

  @override
  String get musicPickerSearchHint => 'Поиск музыки';

  @override
  String get musicPickerMusicFrom => 'Музыка из';

  @override
  String get musicPickerPlaysOn => 'Играет на';

  @override
  String musicPickerSourceLabel(String name) {
    return 'Источник: $name';
  }

  @override
  String musicPickerSpeakerLabel(String name) {
    return 'Играет на: $name';
  }

  @override
  String get musicPickerRandom => 'Случайно';

  @override
  String get musicPickerRandomHint => 'Каждый раз новый выбор';

  @override
  String get musicPickerAnyTrack => 'Любой трек';

  @override
  String get musicPickerAnyFavorite => 'Любое из избранного';

  @override
  String get musicPickerAnyPlaylist => 'Любой плейлист';

  @override
  String get musicPickerAnyAlbum => 'Любой альбом';

  @override
  String get musicPickerAnyStation => 'Любая радиостанция';

  @override
  String get musicPickerRandomEach => 'Каждый раз другое';

  @override
  String get musicPickerWholeAlbum => 'Весь альбом';

  @override
  String get musicPickerWholePlaylist => 'Весь плейлист';

  @override
  String musicPickerWholeArtist(String name) {
    return 'Всё от $name';
  }

  @override
  String get musicPickerWholeFolder => 'Вся папка';

  @override
  String get musicPickerAllTracks => 'Все треки';

  @override
  String get musicPickerShuffle => 'Перемешивание';

  @override
  String get musicPickerPreview => 'Прослушать';

  @override
  String get musicPickerStopPreview => 'Остановить прослушивание';

  @override
  String get musicPickerPreviewFailed => 'Не удалось воспроизвести музыку';

  @override
  String get musicPickerNothing => 'Ничего не выбрано';

  @override
  String get musicPickerNothingHint =>
      'Выберите трек, альбом, плейлист, исполнителя или станцию';

  @override
  String get musicPickerFollowsNote =>
      '«Сейчас играет» переключается на этот динамик, пока играет музыка.';

  @override
  String get musicPickerSonosNote =>
      'Музыка Sonos играет только на динамиках Sonos.';

  @override
  String get musicPickerNoSpeakers => 'Нет динамиков для воспроизведения';

  @override
  String musicPickerOpen(String title) {
    return 'Открыть $title';
  }

  @override
  String get musicPickerKindFolder => 'Папка';

  @override
  String get offlineDashboard => 'Панель недоступна';

  @override
  String get offlineNetwork => 'Нет сетевого соединения';

  @override
  String get offlinePageHelp => 'Не удалось загрузить страницу.';

  @override
  String get offlineNetworkHelp => 'Панель вернётся вместе с сетью.';

  @override
  String get offlineLost => 'Сетевое соединение потеряно';

  @override
  String get offlineRestored => 'Сетевое соединение восстановлено';

  @override
  String get mediaPlay => 'Воспроизвести';

  @override
  String get mediaPause => 'Пауза';

  @override
  String get mediaPreviousTrack => 'Предыдущий трек';

  @override
  String get mediaNextTrack => 'Следующий трек';

  @override
  String get mediaPlaying => 'Воспроизводится';

  @override
  String get mediaPaused => 'Приостановлено';

  @override
  String get mediaIdle => 'Ожидание';

  @override
  String get mediaStatusUnavailable => 'Статус недоступен';

  @override
  String get mediaUnknownTrack => 'Неизвестный трек';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => 'Показать громкость';

  @override
  String get mediaHideVolume => 'Скрыть громкость';

  @override
  String get mediaMute => 'Выключить звук';

  @override
  String get mediaUnmute => 'Включить звук';

  @override
  String get mediaFavoriteAdd => 'Добавить в избранное';

  @override
  String get mediaFavoriteRemove => 'Удалить из избранного';

  @override
  String get mediaShuffleOn => 'Включить перемешивание';

  @override
  String get mediaShuffleOff => 'Выключить перемешивание';

  @override
  String get mediaRepeatAll => 'Повторять все';

  @override
  String get mediaRepeatOne => 'Повторять одну';

  @override
  String get mediaRepeatOff => 'Выключить повтор';

  @override
  String get mediaShowLyrics => 'Показать текст песни';

  @override
  String get mediaHideLyrics => 'Скрыть текст песни';

  @override
  String get mediaShowQueue => 'Показать очередь';

  @override
  String get mediaHideQueue => 'Скрыть очередь';

  @override
  String get mediaVolume => 'Громкость';

  @override
  String get mediaPlaybackPosition => 'Позиция воспроизведения';

  @override
  String get mediaShowNowPlaying => 'Показать «Сейчас играет»';

  @override
  String get mediaShowFloatingPlayer => 'Показать плавающий плеер';

  @override
  String get mediaOpenMusicAssistant => 'Открыть Music Assistant';

  @override
  String get mediaCannotControl =>
      'команда не поддерживается или не отправлена';

  @override
  String get mediaAudioHiRes => 'Hi-Res';

  @override
  String get mediaAudioCdQuality => 'CD-качество';

  @override
  String get mediaAudioLossy => 'С потерями';

  @override
  String mediaAudioBitDepth(String bits) {
    return '$bits бит';
  }

  @override
  String mediaAudioSampleRate(String rate) {
    return '$rate кГц';
  }

  @override
  String mediaAudioBitRate(String rate) {
    return '$rate кбит/с';
  }

  @override
  String get mediaNothingQueued => 'Очередь пуста';

  @override
  String get mediaChapters => 'Главы';

  @override
  String get mediaNowPlaying => 'Сейчас играет';

  @override
  String get mediaUpNext => 'Далее';

  @override
  String mediaUnnamedChapter(String number) {
    return 'Глава $number';
  }

  @override
  String get mediaGroupLead => 'Ведёт группу';

  @override
  String get mediaGroupReadFailed => 'Не удалось прочитать группу.';

  @override
  String get mediaGroupEmpty => 'Нет других плееров для объединения.';

  @override
  String get mediaSpeakerSelection => 'Выбор динамиков';

  @override
  String pluginCloseWindow(String name) {
    return 'Закрыть $name';
  }

  @override
  String get pluginScanTitle => 'Сканируйте код';

  @override
  String get pluginScanHelp => 'Держите код в рамке.';

  @override
  String pluginScanSource(String name) {
    return 'Запрос от $name';
  }

  @override
  String get pluginActions => 'Действия';

  @override
  String get pluginKioskDrawer => 'Меню киоска';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      'Чтобы назначить жест, откройте «Жесты» и выберите «Запустить действие плагина».';

  @override
  String get pluginShowInKioskDrawer => 'Показывать в меню киоска';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      'Также доступно при блокировке, если меню киоска разрешено.';

  @override
  String get pluginExposeToHomeAssistant =>
      'Предоставить доступ Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      'Добавляет кнопку на ESPHome-устройство киоска. Требуются ESPHome и нативные сущности.';

  @override
  String pluginConfigureName(String name) {
    return 'Настройка: $name';
  }

  @override
  String get pluginThePluginDidNotAnswerInTime => 'Плагин не ответил вовремя.';

  @override
  String get pluginNoChoicesYetRefreshToLookForThem =>
      'Вариантов пока нет. Обновите, чтобы найти их.';

  @override
  String get pluginThisChoiceIsNoLongerListed =>
      'Этого варианта больше нет в списке.';

  @override
  String get pluginDashboardLink => 'Ссылка на панели';

  @override
  String get pluginDashboardLinkHint =>
      'Укажите эту ссылку в действии нажатия кнопки на панели.';

  @override
  String get pluginPlugin => 'Плагин';

  @override
  String get pluginEnablePlugins => 'Включить плагины';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      'Плагины добавляют в Kiosk Satellite функции, созданные сообществом.';

  @override
  String get pluginInstalledPlugins => 'Установленные плагины';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      'Плагины не установлены. Добавьте репозиторий, чтобы начать.';

  @override
  String get pluginDeveloperTools => 'Инструменты разработчика';

  @override
  String get pluginCreateAPlugin => 'Создать плагин';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      'Узнайте, как создавать плагины, из шаблона Hello World и документации.';

  @override
  String get pluginThisPluginIsNoLongerInstalled =>
      'Этот плагин больше не установлен.';

  @override
  String get pluginEnablePluginsToRunThisPlugin =>
      'Включите плагины, чтобы запускать этот плагин.';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      'Включите этот плагин в его строке, чтобы запускать его.';

  @override
  String pluginUninstallName(String name) {
    return 'Удалить $name?';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return 'Удаление $name';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return 'Проверить обновления для $name';
  }

  @override
  String pluginAboutName(String name) {
    return 'О плагине $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings =>
      'Плагин и его настройки будут удалены.';

  @override
  String get pluginUninstall => 'Удалить';

  @override
  String get pluginNoUpdatesAvailable => 'Обновлений нет.';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      'Плагин установлен из ZIP и не имеет README репозитория.';

  @override
  String get pluginImageUnavailable => 'Изображение недоступно';

  @override
  String get pluginCouldNotOpenThisLink => 'Не удалось открыть эту ссылку.';

  @override
  String pluginEnableName(String name) {
    return 'Включить $name';
  }

  @override
  String get pluginShowPassword => 'Показать пароль';

  @override
  String get pluginHidePassword => 'Скрыть пароль';

  @override
  String get pluginUntitled => 'Без названия';

  @override
  String get pluginSearchIcons => 'Поиск значков';

  @override
  String get pluginChooseIcon => 'Выберите значок';

  @override
  String get pluginSearchCameraViews => 'Поиск видов камер';

  @override
  String get pluginChooseCameraView => 'Выберите вид камер';

  @override
  String get pluginCameraViewGone =>
      'Этого вида камер больше нет. Выберите другой.';

  @override
  String get pluginDragToReorder => 'Перетащите для изменения порядка';

  @override
  String get pluginDuplicate => 'Дублировать';

  @override
  String get pluginDone => 'Готово';

  @override
  String get pluginRequired => 'Обязательно';

  @override
  String get pluginAddPlugin => 'Добавить плагин';

  @override
  String get pluginInstallFromAGithubRepository =>
      'Установка из репозитория GitHub';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd =>
      'Перед установкой убедитесь, что вы доверяете автору плагина и его коду.';

  @override
  String get pluginPreview => 'Предпросмотр';

  @override
  String get pluginInstalledVersion => 'Установленная версия';

  @override
  String get pluginAuthor => 'Автор';

  @override
  String get pluginLicense => 'Лицензия';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      'Плагины выполняют код внутри Kiosk Satellite и имеют доступ к данным приложения и выданным разрешениям Android. Неисправный или вредоносный плагин может раскрыть личную информацию или нарушить работу приложения. Устанавливайте плагины только от авторов, которым доверяете.';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      'Новые плагины изначально выключены. Обновления сохраняют состояние включения и автоматически перезапускают работающие плагины.';

  @override
  String get pluginTrustAndUpdate => 'Доверять и обновить';

  @override
  String get pluginTrustAndInstall => 'Доверять и установить';

  @override
  String get pluginInstallFromZip => 'Установить из ZIP';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild =>
      'Только для разработчиков: тест локальной сборки';

  @override
  String get pluginPluginZip => 'ZIP плагина';

  @override
  String get pluginPluginZipMustBeAtMost4Mb =>
      'ZIP плагина должен быть не больше 4 МБ';

  @override
  String get pluginCouldNotReadTheSelectedZip =>
      'Не удалось прочитать выбранный ZIP';

  @override
  String get pluginBrowsePlugins => 'Обзор плагинов';

  @override
  String get pluginFindPluginsMadeByTheCommunity =>
      'Найдите плагины, созданные сообществом';

  @override
  String get pluginSearchPlugins => 'Поиск плагинов';

  @override
  String get pluginUpdate => 'Обновить';

  @override
  String get pluginInstalled => 'Установлен';

  @override
  String pluginNeedsAppVersion(String version) {
    return 'Нужен Kiosk Satellite $version или новее';
  }

  @override
  String get pluginStars => 'Звёзды';

  @override
  String get pluginDownloads => 'Загрузки';

  @override
  String get pluginActiveInstalls => 'Активные установки';

  @override
  String get pluginNoPluginsMatchYourSearch =>
      'Нет плагинов, подходящих под запрос.';

  @override
  String get pluginCommunityPluginsHasNoPluginsYet =>
      'В Плагинах сообщества пока нет плагинов.';

  @override
  String get pluginSubmitYourPlugin => 'Отправить свой плагин';

  @override
  String get pluginListYourPluginInCommunityPlugins =>
      'Добавьте свой плагин в Плагины сообщества.';

  @override
  String get pluginCouldNotReachCommunityPlugins =>
      'Не удалось связаться с Плагинами сообщества. Проверьте подключение к интернету.';

  @override
  String get pluginCouldNotLoadCommunityPlugins =>
      'Не удалось загрузить Плагины сообщества. Попробуйте позже.';

  @override
  String get pluginTurnOn => 'Включить';

  @override
  String get pluginTurnOnEnablePluginsToInstall =>
      'Включите «Включить плагины», чтобы установить этот плагин.';

  @override
  String get pluginPreviousPage => 'Предыдущая страница';

  @override
  String get pluginNextPage => 'Следующая страница';

  @override
  String pluginPageOfPages(String page, String pages) {
    return 'Страница $page из $pages';
  }

  @override
  String get pluginSortBy => 'Сортировать по';

  @override
  String get pluginSortMostStars => 'Больше всего звёзд';

  @override
  String get pluginSortRecentlyUpdated => 'Недавно обновлённые';

  @override
  String get pluginSortNewest => 'Новые';

  @override
  String get pluginSortName => 'Название';

  @override
  String get pluginSortMostDownloads => 'Больше всего загрузок';

  @override
  String get pluginPluginsPerPage => 'Плагинов на странице';

  @override
  String pluginCountPerPage(String count) {
    return '$count на странице';
  }

  @override
  String pluginByAuthor(String author) {
    return 'от $author';
  }

  @override
  String get pluginListedChip => 'Есть в Плагинах сообщества';

  @override
  String get pluginNotListedChip => 'Нет в Плагинах сообщества';

  @override
  String get pluginCharts => 'Графики';

  @override
  String get pluginReadings => 'Показания';

  @override
  String get pluginWaitingForSamples => 'Ожидание замеров';

  @override
  String get pluginLatest => 'Последнее';

  @override
  String get pluginSelected => 'Выбранное';

  @override
  String get pluginNoDataYet => 'Данных пока нет';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      'Коснитесь или потяните, чтобы рассмотреть замеры. Двойное касание: следить за последним.';

  @override
  String get pluginNoData => 'Нет данных';

  @override
  String get pluginOn => 'Включено';

  @override
  String get pluginEmpty => 'Пусто';

  @override
  String get pluginChartKeyboardHelp =>
      'Используйте стрелки для просмотра замеров и End для перехода к последнему.';

  @override
  String get pluginErrorAssetPath => 'Недопустимый путь к ресурсу';

  @override
  String get pluginErrorAssetMissing => 'Ресурс отсутствует или вне пакета';

  @override
  String get pluginErrorAssetSymlink =>
      'Каталог ресурсов не может быть символьной ссылкой';

  @override
  String get pluginErrorAssetSymlinks =>
      'Каталоги ресурсов не могут быть символьными ссылками';

  @override
  String get pluginErrorAssetsIntegrity =>
      'Установленные ресурсы не прошли проверку целостности';

  @override
  String get pluginErrorAssetIntegrity =>
      'Установленный ресурс не прошёл проверку целостности';

  @override
  String get pluginErrorManifestMismatch =>
      'Манифест пакета не совпадает с проверенным манифестом выпуска';

  @override
  String get pluginErrorStagingExists => 'Временный каталог уже существует';

  @override
  String get pluginErrorCreateDirectory => 'Не удалось создать каталог плагина';

  @override
  String get pluginErrorFileCount =>
      'Поддерживается не более 512 файлов пакета';

  @override
  String get pluginErrorProtectFile => 'Не удалось защитить файл плагина';

  @override
  String get pluginErrorExpandedSize => 'Распакованный плагин превышает 4 МБ';

  @override
  String get pluginErrorManifestSize => 'Манифест превышает 32 КБ';

  @override
  String get pluginErrorRequiredFiles =>
      'Пакету нужны kiosk-satellite-plugin.json, plugin.jar и LICENSE';

  @override
  String get pluginErrorNativeCapability =>
      'Нативные библиотеки требуют возможности native';

  @override
  String get pluginErrorNativeElf => 'Недопустимая нативная библиотека ELF';

  @override
  String get pluginErrorNativeAbi =>
      'ABI нативной библиотеки не соответствует её каталогу';

  @override
  String get pluginErrorDexOnly =>
      'plugin.jar должен содержать только файлы DEX';

  @override
  String get pluginErrorDexHeader => 'Недопустимый заголовок DEX';

  @override
  String get pluginErrorDexSize => 'Распакованный DEX превышает 4 МБ';

  @override
  String get pluginErrorDexEmpty => 'Пустой файл DEX';

  @override
  String get pluginErrorDexMissing => 'В plugin.jar нет classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'Неожиданная или повторяющаяся запись ZIP: $name';
  }

  @override
  String get pluginErrorRepositoryMismatch =>
      'Выпуск репозитория принадлежит другому плагину.';

  @override
  String get pluginErrorRepositoryUrl =>
      'Введите публичный URL вида https://github.com/owner/repository';

  @override
  String get pluginErrorRepositoryPath =>
      'Используйте URL репозитория без пути к файлу или ветке';

  @override
  String get pluginErrorDownloadOutsideGithub =>
      'Загрузка плагина перенаправлена за пределы GitHub';

  @override
  String get pluginErrorInvalidRedirect =>
      'Недопустимое перенаправление GitHub';

  @override
  String get pluginErrorRepositoryNotFound =>
      'Публичный репозиторий, стабильный выпуск, kiosk-satellite-plugin.json, README.md или ресурс выпуска не найден.';

  @override
  String get pluginErrorGithubLimited =>
      'GitHub отклонил запрос или достигнут лимит запросов. Попробуйте позже.';

  @override
  String get pluginErrorRepositorySize =>
      'Файл репозитория превышает лимит размера';

  @override
  String get pluginErrorTooManyRedirects =>
      'Слишком много перенаправлений GitHub';

  @override
  String get pluginErrorStableRelease =>
      'GitHub не вернул опубликованный стабильный выпуск';

  @override
  String get pluginErrorReleaseTag => 'Недопустимый тег выпуска';

  @override
  String get pluginErrorManifestFile =>
      'Недопустимый манифест kiosk-satellite-plugin.json';

  @override
  String get pluginErrorIdVersion => 'Недопустимый ID или версия плагина';

  @override
  String get pluginErrorChecksumFilename =>
      'Недопустимая контрольная сумма выпуска или имя файла пакета';

  @override
  String get pluginErrorGithubDigest =>
      'Контрольная сумма выпуска должна совпадать с дайджестом SHA-256 ресурса GitHub';

  @override
  String get pluginErrorTrustAuthor =>
      'Подтвердите, что вы доверяете автору плагина';

  @override
  String get pluginErrorPreviewExpired =>
      'Предпросмотр истёк. Выполните предпросмотр репозитория снова перед установкой.';

  @override
  String get pluginErrorReviewedChecksum =>
      'SHA-256 пакета не совпадает с проверенным выпуском';

  @override
  String get pluginErrorNotInstalled => 'Плагин не установлен';

  @override
  String get pluginErrorUpdateZip =>
      'Плагин установлен из ZIP. Для обновления используйте «Установить из ZIP».';

  @override
  String get pluginErrorAndroidOnly => 'Плагины доступны на Android.';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'Запрос к GitHub не удался ($status)';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return 'Для выпуска нужен ровно один загруженный ресурс $name';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return 'Ресурс выпуска $name должен публиковаться через GitHub Actions. Загруженные вручную файлы не поддерживаются.';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return 'Ресурс выпуска $name превышает лимит размера или пуст';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return 'Недопустимый URL выпуска для $name';
  }

  @override
  String get pluginErrorNativeLibrary =>
      'У плагина нет нативной библиотеки для ABI этого устройства';

  @override
  String get pluginErrorCallbackTimeout =>
      'Тайм-аут обратного вызова плагина. Перезапустите Kiosk, если у плагина остались незавершённые задачи.';

  @override
  String get pluginErrorEnableFirst => 'Сначала включите плагин';

  @override
  String get pluginErrorSaveState => 'Не удалось сохранить состояние плагина';

  @override
  String get pluginErrorPackageHash => 'Недопустимый хеш установленного пакета';

  @override
  String get pluginErrorChecksum => 'SHA-256 пакета не совпадает';

  @override
  String get pluginErrorDifferentRepository =>
      'Этот ID плагина принадлежит другому репозиторию. Удалите его перед сменой источника.';

  @override
  String get pluginErrorRestartReplace =>
      'Плагин не остановился корректно. Перезапустите Kiosk Satellite перед заменой.';

  @override
  String get pluginErrorAlreadyInstalled => 'Этот пакет уже установлен';

  @override
  String get pluginErrorLoadedIntegrity =>
      'Ранее загруженный пакет не прошёл проверку целостности. Перезапустите Kiosk Satellite перед повторной установкой.';

  @override
  String get pluginErrorRemovePackage =>
      'Не удалось удалить неиспользуемый пакет';

  @override
  String get pluginErrorInstallPackage => 'Не удалось установить пакет плагина';

  @override
  String get pluginErrorUpdateCanceled =>
      'Обновление отменено: плагин не остановился корректно. Перезапустите Kiosk Satellite и попробуйте снова.';

  @override
  String get pluginErrorVersionRetained => 'Сохранена предыдущая версия.';

  @override
  String get pluginErrorRetainedDisabled =>
      'Предыдущая версия сохранена, но выключена. Перезапустите Kiosk Satellite перед включением.';

  @override
  String get pluginErrorVersionRunning => 'Предыдущая версия снова работает.';

  @override
  String get pluginErrorEnablePlugins => 'Сначала включите плагины';

  @override
  String get pluginErrorRestartEnable =>
      'Плагин не остановился корректно. Перезапустите Kiosk Satellite перед включением.';

  @override
  String get pluginErrorInstalledIntegrity =>
      'Установленный плагин не прошёл проверку целостности. Переустановите его.';

  @override
  String get pluginErrorAndroidOld => 'Версия Android слишком старая';

  @override
  String get pluginErrorNeedsScreen => 'Этому плагину нужен экран';

  @override
  String get pluginErrorNativeIntegrity =>
      'Установленные нативные библиотеки не прошли проверку целостности';

  @override
  String get pluginErrorNativeFileIntegrity =>
      'Установленная нативная библиотека не прошла проверку целостности';

  @override
  String pluginErrorReadInstalled(String error) {
    return 'Не удалось прочитать установленный плагин: $error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return 'Не удалось перезапустить предыдущую версию: $error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return 'Обновление плагина не удалось: $error. $recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      'Требуется Shizuku 13 или новее. Нажмите для инструкций по настройке.';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      'Запустите Shizuku на этом устройстве. Нажмите для инструкций по настройке.';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku даёт Kiosk Satellite доступ shell или root. Установленные плагины работают внутри KS, поэтому предоставляйте доступ, только если доверяете им.';

  @override
  String get pluginSetUp => 'Настроить';

  @override
  String get pluginGrantAccess => 'Предоставить доступ';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      'Одобрите запрос разрешения на киоске.';

  @override
  String get pluginErrorInvalidId => 'Недопустимый ID плагина';

  @override
  String get pluginErrorInvalidVersion => 'Недопустимая версия';

  @override
  String get pluginErrorEntryClass => 'Недопустимый класс точки входа';

  @override
  String get pluginErrorManifestSchema => 'Неподдерживаемая схема манифеста';

  @override
  String get pluginErrorSdkVersion => 'Этому плагину нужна другая версия SDK';

  @override
  String get pluginErrorMinimumSdk =>
      'Минимальный Android SDK должен быть не ниже 24';

  @override
  String get pluginErrorCapability => 'Неподдерживаемая возможность плагина';

  @override
  String get pluginErrorTooManySettings => 'Слишком много настроек или команд';

  @override
  String get pluginErrorSettingKey =>
      'Недопустимый или повторяющийся ключ настройки';

  @override
  String get pluginErrorGroupsArray =>
      'Группы отображения должны быть массивом';

  @override
  String get pluginErrorTooManyGroups => 'Слишком много групп отображения';

  @override
  String get pluginErrorUniqueGroups =>
      'Группы отображения должны называть уникальные группы настроек';

  @override
  String get pluginErrorGroupReferences => 'Слишком много ссылок на группы';

  @override
  String get pluginErrorDuplicateReference =>
      'Недопустимая или повторяющаяся ссылка на группу';

  @override
  String get pluginErrorCommandId =>
      'Недопустимый или повторяющийся ID команды';

  @override
  String get pluginErrorUnknownSetting => 'Неизвестная настройка плагина';

  @override
  String get pluginErrorTextLength =>
      'Текстовые настройки должны содержать не более 512 символов';

  @override
  String get pluginErrorEntityId => 'Ожидался ID сущности Home Assistant';

  @override
  String get pluginErrorBoolean => 'Ожидалась логическая настройка';

  @override
  String get pluginErrorColor => 'Ожидался цвет в RGB-hex';

  @override
  String get pluginErrorNumber => 'Ожидалась числовая настройка';

  @override
  String get pluginErrorRange => 'Числовая настройка вне диапазона';

  @override
  String get pluginErrorStep => 'Числовая настройка не соответствует шагу';

  @override
  String get pluginErrorSelection => 'Недопустимая настройка выбора';

  @override
  String get pluginErrorSelectionOption => 'Неизвестный вариант выбора';

  @override
  String get pluginErrorSettingType => 'Неподдерживаемый тип настройки';

  @override
  String get pluginErrorInvalidManifest => 'Недопустимый манифест плагина';

  @override
  String pluginErrorAndroidApi(String version) {
    return 'Плагину нужен Android API $version';
  }

  @override
  String pluginErrorAppVersion(String required, String current) {
    return 'Плагину нужен Kiosk Satellite $required или новее. На этом киоске установлен $current.';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return 'Недопустимое поле $field';
  }

  @override
  String get pluginErrorTooManyTriggers => 'Слишком много триггеров';

  @override
  String get pluginErrorTriggerId =>
      'Недопустимый или повторяющийся ID триггера';

  @override
  String get pluginErrorListSetting => 'Недопустимая настройка списка';

  @override
  String get pluginErrorSettingCondition => 'Недопустимое условие настройки';

  @override
  String get pluginErrorIcon => 'Ожидалось имя значка MDI';

  @override
  String get pluginErrorDashboard => 'Ожидался путь к панели';

  @override
  String get pluginErrorCameraView => 'Ожидался ID вида камер';

  @override
  String get pluginErrorListValue => 'Ожидалась настройка списка';

  @override
  String get pluginErrorListCount =>
      'В списке слишком много или слишком мало элементов';

  @override
  String get pluginErrorRequiredField => 'Заполните все обязательные поля';

  @override
  String get pluginErrorListSize =>
      'Настройки списка могут занимать не более 32 КБ';

  @override
  String get remoteDisableTitle => 'Выключить удалённое управление?';

  @override
  String get remoteDisableHelp =>
      'ВНИМАНИЕ: доступ к этой странице будет потерян. Чтобы включить снова, используйте устройство или переключатель Remote management в Home Assistant.';

  @override
  String get remoteDisableConfirm => 'Выключить';

  @override
  String get remoteCopyHelp => 'Выделите ключ и скопируйте его вручную.';

  @override
  String get remoteSaveSettingFailed =>
      'Не удалось сохранить эту настройку. Попробуйте снова.';

  @override
  String get remoteReconnecting => 'Переподключение…';

  @override
  String remoteConnectionLost(String name) {
    return 'Соединение с $name потеряно. Страница возобновится сама, когда оно вернётся.';
  }

  @override
  String get remoteConnectionLostUnnamed =>
      'Соединение с киоском потеряно. Страница возобновится сама, когда оно вернётся.';

  @override
  String get remoteReloadPage => 'Перезагрузить страницу';

  @override
  String get remoteUpdated => 'Kiosk Satellite обновлён';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return 'Устройство теперь работает на версии $version$build. Страница принадлежит предыдущей версии и перезагрузится через $seconds с.';
  }

  @override
  String remoteBuild(String build) {
    return ' (сборка $build)';
  }

  @override
  String get remoteReloadNow => 'Перезагрузить сейчас';

  @override
  String get remoteLogin => 'Войти';

  @override
  String get remoteInvalidPassword => 'Неверный пароль';

  @override
  String get remoteLoginThrottled =>
      'Слишком много попыток. Подождите 5 мин и попробуйте снова.';

  @override
  String get deviceScreenOffPermission =>
      'Для выключения экрана нужно одноразовое разрешение. На планшете открыт экран выдачи разрешения «администратор устройства». Одобрите его там и попробуйте снова.';

  @override
  String get deviceAdminInactive =>
      'Разрешение администратора устройства не активно.';

  @override
  String get deviceRestartOverlay =>
      'Для перезапуска нужно разрешение «Поверх других приложений», иначе приложение не сможет вернуться. Экран выдачи разрешения открывается на устройстве; разрешите там и повторите.';

  @override
  String get deviceRebootPermission =>
      'Для перезапуска устройства Kiosk Satellite должен быть владельцем устройства или подключён через Shizuku.';

  @override
  String get deviceRestartAndroidOnly =>
      'Перезапуск доступен только на Android.';

  @override
  String get deviceRestartShizukuRefused => 'Shizuku отклонил перезапуск';

  @override
  String deviceRestartFailed(String error) {
    return 'Не удалось перезапустить: $error';
  }

  @override
  String get overviewAttention => 'Требует внимания';

  @override
  String get overviewUpdate => 'Обновление';

  @override
  String overviewInvitation(String name) {
    return '$name хочет вести этот киоск';
  }

  @override
  String get overviewOutdatedOne => 'Один ведомый работает на другом выпуске';

  @override
  String overviewOutdatedMany(String count) {
    return 'Ведомых на другом выпуске: $count';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names. Синхронизация ждёт версию $version.';
  }

  @override
  String get overviewThisRelease => 'этот выпуск';

  @override
  String get overviewUpdateAvailable => 'Доступно обновление';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version готов к установке. Установка подтверждается на экране планшета.';
  }

  @override
  String overviewInstallSilentHelp(String version) {
    return 'Kiosk Satellite $version готов к установке. Он устанавливается без подтверждения на устройстве.';
  }

  @override
  String overviewInstallHeadlessHelp(String version) {
    return 'Kiosk Satellite $version готов к установке. У этого устройства нет экрана для подтверждения, поэтому сделайте Kiosk Satellite владельцем устройства, используйте Shizuku или установите через adb.';
  }

  @override
  String get overviewHaSetup => 'Home Assistant не настроен';

  @override
  String get overviewHaSetupHelp =>
      'Подключите киоск к Home Assistant, чтобы загрузить панель.';

  @override
  String get overviewSetUp => 'Настроить';

  @override
  String get overviewHaNotValidated => 'Home Assistant не проверен';

  @override
  String get overviewHaNotValidatedHelp =>
      'URL и токен не прошли проверку соединения в этом запуске. Киоск повторяет попытку каждые 30 с.';

  @override
  String get overviewOpenSetup => 'Открыть настройку';

  @override
  String get overviewWakeStopped => 'Определение слова пробуждения остановлено';

  @override
  String get overviewWakeReleased => 'Движок был освобождён.';

  @override
  String get overviewOpenVoice => 'Открыть Voice Satellite';

  @override
  String get overviewOpenService => 'Открыть службу';

  @override
  String overviewPermissionMissing(String permission) {
    return 'Нет разрешения: $permission';
  }

  @override
  String get overviewSystemUpdate => 'Доступно обновление системы';

  @override
  String overviewPluginUpdate(String name) {
    return 'Доступно обновление $name';
  }

  @override
  String overviewPluginUpdateHelp(String version) {
    return 'Версия $version готова к просмотру и установке.';
  }

  @override
  String overviewSystemImageUpdateHelp(String version) {
    return 'Версия $version образа системы готова к установке. Для этого устройство дважды перезагрузится.';
  }

  @override
  String get overviewQuick => 'Быстрые действия';

  @override
  String get overviewReload => 'Перезагрузить страницу';

  @override
  String get overviewScreenOn => 'Включить экран';

  @override
  String get overviewScreenOff => 'Выключить экран';

  @override
  String get overviewSaverStart => 'Запустить заставку';

  @override
  String get overviewSaverStop => 'Убрать заставку';

  @override
  String get overviewCameraShow => 'Показать вид камер';

  @override
  String get overviewCameraHide => 'Убрать вид камер';

  @override
  String get overviewSaverPostpone => 'Отложить заставку';

  @override
  String get overviewDnd => 'Не беспокоить';

  @override
  String get overviewDndOn => '«Не беспокоить» включён';

  @override
  String get overviewSnapshot => 'Сделать снимок';

  @override
  String get overviewCheckUpdates => 'Проверить обновления';

  @override
  String get overviewRestartApp => 'Перезапустить приложение';

  @override
  String get overviewRestartDevice => 'Перезапустить устройство';

  @override
  String get overviewExit => 'Выйти из приложения';

  @override
  String get overviewBrightness => 'Яркость';

  @override
  String get overviewVolume => 'Общая громкость';

  @override
  String get overviewBrightnessGrant =>
      'Яркость использует резервный режим приложения. Выдайте разрешение «Изменение системных настроек», чтобы ползунок управлял реальной яркостью панели.';

  @override
  String get overviewRestartQuestion =>
      'Перезапустить это устройство? Kiosk Satellite вернётся после загрузки.';

  @override
  String get overviewRestart => 'Перезапустить';

  @override
  String get overviewNoSnapshot => 'Снимок не получен.';

  @override
  String get overviewSnapshotTitle => 'Снимок камеры';

  @override
  String get overviewUpdateCheckFailed =>
      'Не удалось проверить обновления. Устройство имеет доступ к GitHub?';

  @override
  String get overviewLatest => 'У вас последняя версия.';

  @override
  String overviewVersionAvailable(String version) {
    return 'Доступна версия $version';
  }

  @override
  String get overviewInstallAttention =>
      'Установите её из блока «Требует внимания».';

  @override
  String get overviewNoViewsWithCameras =>
      'Ни в одном виде камер пока нет камер. Сначала добавьте камеры в вид в разделе «Потоки камер».';

  @override
  String get overviewShowViewFailed => 'Не удалось показать вид';

  @override
  String get overviewAppVersion => 'Версия приложения';

  @override
  String get overviewNotSetup => 'Не настроено';

  @override
  String get overviewNotValidated => 'Не проверено';

  @override
  String get overviewCheckingFilter => 'Проверка фильтра…';

  @override
  String get overviewValidated => 'Проверено';

  @override
  String get overviewFilterUnavailable => 'Статус фильтра недоступен';

  @override
  String get overviewUnfiltered => 'Обновления не фильтруются';

  @override
  String get overviewWatchingOne => 'Отслеживается одна сущность';

  @override
  String overviewWatchingMany(String count) {
    return 'Отслеживается сущностей: $count';
  }

  @override
  String overviewFilterDisabled(String count) {
    return 'Фильтрация выключена, вид использует сущностей: $count';
  }

  @override
  String get overviewWakeOff => 'Определение слова пробуждения выключено';

  @override
  String overviewListeningFor(String words) {
    return 'Слушает: $words';
  }

  @override
  String get overviewListening => 'Слушает';

  @override
  String get overviewNotListening => 'Не слушает';

  @override
  String get overviewEntitiesProxy => 'Сущности и BT-прокси';

  @override
  String get overviewEntitiesOnly => 'Только сущности';

  @override
  String get overviewProxyOnly => 'Только BT-прокси';

  @override
  String get overviewWaitingHA => 'Ожидание Home Assistant';

  @override
  String get overviewNotRunning => 'Не работает';

  @override
  String get overviewRunningOne => 'Работает - одна функция';

  @override
  String overviewRunningMany(String count) {
    return 'Работает - функций: $count';
  }

  @override
  String overviewDownloading(String version) {
    return 'Загрузка: $version';
  }

  @override
  String overviewNewVersion(String version) {
    return 'Новая версия: $version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return 'Актуальная: $version';
  }

  @override
  String get overviewCurrent => 'Актуальная версия';

  @override
  String overviewPluginAttribution(String name) {
    return 'Плагин $name';
  }

  @override
  String get overviewMuted => 'микрофон выключен';

  @override
  String get overviewBrowser => 'браузер';

  @override
  String get overviewWakeWaiting =>
      'Ожидание Voice Satellite. Движок и слова пробуждения настраиваются интеграцией, когда устройство откроет свою панель.';

  @override
  String get overviewWakeDisabled =>
      'Определение слова пробуждения выключено. Включите его, чтобы наследовать модели из Voice Satellite.';

  @override
  String get overviewMicBlocked =>
      'Микрофон заблокирован. Android больше не спросит: разрешите его в настройках приложения и повторите.';

  @override
  String get overviewMicDeclined =>
      'Микрофон отклонён. Определению слова пробуждения он нужен; повторите, чтобы спросили снова.';

  @override
  String get overviewMicLost =>
      'Микрофон перестал работать. Повторите или перезагрузите страницу.';

  @override
  String get overviewModelsUnavailable =>
      'Не удалось загрузить модели из Home Assistant. Повторите, когда он станет доступен.';

  @override
  String get overviewCrashed =>
      'Детектор постоянно падал на этом устройстве и был остановлен. Voice Satellite слушает в браузере. Повторите или перезапустите приложение.';

  @override
  String get overviewWakeFailed =>
      'Не удалось запустить движок слова пробуждения. Повторите или перезагрузите страницу.';

  @override
  String overviewNativeUnavailable(String engine) {
    return 'Нет нативного раннера для $engine. Voice Satellite продолжает определение в браузере.';
  }

  @override
  String get overviewNativeListening => 'Слушает нативно';

  @override
  String get overviewSuspended =>
      'Готово (приостановлено на время голосового сеанса)';

  @override
  String get overviewCpu => 'ЦП';

  @override
  String get overviewMemory => 'ОЗУ';

  @override
  String get overviewTemperature => 'Темп.';

  @override
  String overviewMemoryFree(String amount) {
    return 'Свободно $amount ГБ';
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
  String get overviewShowingCustomPages => 'Показ своих страниц';

  @override
  String get overviewHeadlessMode => 'Режим без экрана';

  @override
  String get overviewNoScreenshot => 'Нет скриншота';

  @override
  String get overviewStill => 'Стоп-кадр';

  @override
  String get overviewLive => 'Вживую';

  @override
  String get overviewFullSize => 'Полный размер';

  @override
  String get overviewLiveInterval => 'Вживую, каждые 5 с';

  @override
  String overviewTaken(String age) {
    return 'Снято $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return 'Вид камер: $name';
  }

  @override
  String get overviewCameraView => 'Вид камер';

  @override
  String get overviewScreenOffState => 'Экран выключен';

  @override
  String get overviewGoView => 'Перейти к виду';

  @override
  String get screensaverNoPhotos =>
      'Фотографии не выбраны. Выберите их в настройках.';

  @override
  String get screensaverNoFolder =>
      'Папка не выбрана. Выберите её в настройках.';

  @override
  String screensaverFolderEmpty(String folder) {
    return 'В $folder нет фотографий или видео';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return 'Не удалось прочитать $folder. Выдано ли разрешение на медиа?';
  }

  @override
  String get screensaverReadPhotosFailed => 'Не удалось прочитать фотографии.';

  @override
  String get screensaverImmichNotReady =>
      'Immich не подключён. Проверьте его в настройках.';

  @override
  String get screensaverNoMediaMatch =>
      'Нет медиа, подходящих под источник и фильтры.';

  @override
  String get screensaverNoMediaSource => 'В выбранном источнике нет медиа.';

  @override
  String get screensaverImmichUnreachable => 'Сервер Immich недоступен.';

  @override
  String screensaverRetryNotice(String error) {
    return '$error Повтор выполняется автоматически.';
  }

  @override
  String get screensaverVideosTooLarge =>
      'Каждое видео в этом плейлисте слишком велико для воспроизведения на этом устройстве.';

  @override
  String get screensaverUrlNotSet =>
      'URL изображения не задан. Добавьте его в настройках.';

  @override
  String get screensaverUrlLoadFailed => 'Не удалось загрузить изображение.';

  @override
  String get settingKioskAllowAlarmsTitle => 'Будильники';

  @override
  String get settingKioskAllowAlarmsDescription =>
      'Установка и управление будильниками из меню киоска.';

  @override
  String get settingScreensaverClockAlarmTakeoverTitle =>
      'Разрешить будильникам перехватывать экран';

  @override
  String get settingScreensaverClockAlarmTakeoverDescription =>
      'Звонящий будильник показывается на этой заставке в её стиле, а не на отдельном экране.';

  @override
  String get settingScreensaverWeatherAlarmTakeoverTitle =>
      'Разрешить будильникам перехватывать экран';

  @override
  String get settingScreensaverWeatherAlarmTakeoverDescription =>
      'Звонящий будильник показывается на этой заставке в её стиле, а не на отдельном экране.';

  @override
  String get settingAlarmsVolumeTitle => 'Громкость будильника';

  @override
  String get settingAlarmsVolumeDescription =>
      'Насколько громко звонят будильники, отдельно от громкости медиа.';

  @override
  String get settingAlarmsToneTitle => 'Звук будильника';

  @override
  String get settingAlarmsToneDescription =>
      'Проигрывается на громкости будильника.';

  @override
  String get settingAlarmsMusicTitle => 'Музыка будильника';

  @override
  String get settingAlarmsMusicDescription =>
      'Звучит вместо звука будильника. Если музыку не удастся воспроизвести, прозвучит звук будильника.';

  @override
  String get settingAlarmsSnoozeMinutesTitle => 'Длительность откладывания';

  @override
  String get settingAlarmsSnoozeMinutesDescription =>
      'На сколько «Отложить» откладывает будильник.';

  @override
  String get settingAlarmsSilenceAfterMinutesTitle => 'Замолкание через';

  @override
  String get settingAlarmsSilenceAfterMinutesDescription =>
      'Будильник, который никто не остановил, замолкает по прошествии этого времени.';

  @override
  String get settingAlarmsSunriseMinutesTitle => 'Длительность рассвета';

  @override
  String get settingAlarmsSunriseMinutesDescription =>
      'За сколько времени экран светлеет перед будильником-рассветом.';

  @override
  String get alarmsOption5Minutes => '5 минут';

  @override
  String get alarmsOption10Minutes => '10 минут';

  @override
  String get alarmsOption15Minutes => '15 минут';

  @override
  String get alarmsOption20Minutes => '20 минут';

  @override
  String get alarmsOption25Minutes => '25 минут';

  @override
  String get alarmsOption30Minutes => '30 минут';

  @override
  String get settingsMenuAlarms => 'Будильники';

  @override
  String get settingsMenuAlarmsSummary =>
      'Будильники, звук, откладывание, рассвет';

  @override
  String get settingAlarmsEaseInTitle => 'Плавное нарастание громкости';

  @override
  String get settingAlarmsEaseInDescription =>
      'Начинать тихо и плавно повышать до громкости будильника.';

  @override
  String get settingAlarmsEaseInSecondsTitle => 'Нарастание за';

  @override
  String get settingAlarmsEaseInSecondsDescription =>
      'За сколько времени будильник достигает полной громкости.';

  @override
  String get settingAlarmsTtsEngineTitle => 'Движок синтеза речи';

  @override
  String get settingAlarmsTtsEngineDescription =>
      'Сущность синтеза речи Home Assistant, которая произносит будильники.';

  @override
  String get settingAlarmsTtsLanguageTitle => 'Язык';

  @override
  String get settingAlarmsTtsLanguageDescription =>
      'Язык, на котором произносятся будильники.';

  @override
  String get settingAlarmsTtsVoiceTitle => 'Голос';

  @override
  String get settingAlarmsTtsVoiceDescription =>
      'Голос, которым произносятся будильники.';

  @override
  String get settingLauncherEnabledTitle => 'Включить лаунчер приложений';

  @override
  String get settingLauncherEnabledDescription =>
      'Открывайте выбранный набор установленных приложений из киоска.';

  @override
  String get settingLauncherAppsDescription =>
      'Приложения, которые предлагает лаунчер.';

  @override
  String get settingLauncherAutoReturnTitle => 'Возвращаться автоматически';

  @override
  String get settingLauncherAutoReturnDescription =>
      'Вернуться в киоск, когда другое приложение какое-то время остаётся без касаний.';

  @override
  String get settingLauncherAutoReturnSecondsTitle => 'Возврат через (с)';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      'Время без касаний в другом приложении до возврата в киоск.';

  @override
  String get settingLauncherAutoReturnHoldTitle =>
      'Ждать во время воспроизведения и звонков';

  @override
  String get settingLauncherAutoReturnHoldDescription =>
      'Не возвращаться во время видео, музыки или звонков.';

  @override
  String get launcherOverlayHeld =>
      'Kiosk Satellite может вернуться на передний план и замечать касания в другом приложении.';

  @override
  String get launcherOverlayMissing =>
      'Без этого киоск не вернётся сам, а касания в другом приложении не замечаются.';

  @override
  String get launcherOverlayRemote =>
      'Без этого киоск не вернётся сам, а касания в другом приложении не замечаются. Экран выдачи разрешения появится на планшете.';

  @override
  String get launcherBatteryMissing =>
      'Android может приостановить приложение за другим, а приостановленный таймер никогда не вернёт киоск.';

  @override
  String get launcherBatteryRemote =>
      'Android может приостановить приложение за другим, а приостановленный таймер никогда не вернёт киоск. Диалог выдачи разрешения появится на планшете.';

  @override
  String get launcherNotificationAccessHeld =>
      'Киоск не возвращается, пока другое приложение воспроизводит видео или музыку.';

  @override
  String get launcherNotificationAccessMissing =>
      'Без этого киоск не знает, когда играет видео или музыка, и всё равно возвращается.';

  @override
  String get launcherNotificationAccessRemote =>
      'Без этого киоск не знает, когда играет видео или музыка, и всё равно возвращается. Экран выдачи разрешения появится на планшете.';

  @override
  String get launcherPermissionsSearch =>
      'Разрешения, на которые опирается «Возвращаться автоматически».';

  @override
  String get settingCalendarDefaultViewTitle => 'Вид по умолчанию';

  @override
  String get settingCalendarDefaultViewDescription =>
      'Вид, с которым открывается календарь.';

  @override
  String get settingCalendarWeekStartTitle => 'Неделя начинается с';

  @override
  String get settingCalendarWeekStartAppLanguageDescription =>
      'Как в языке приложения, если не задано иное.';

  @override
  String get settingCalendarWeatherEntityTitle => 'Погода';

  @override
  String get settingCalendarWeatherEntityDescription =>
      'Добавляет прогноз к каждому дню.';

  @override
  String get settingCalendarAllowEditTitle =>
      'Разрешить добавлять и изменять события';

  @override
  String get settingCalendarAllowEditDescription =>
      'Добавляет в календарь кнопки Новое событие и Изменить.';

  @override
  String get settingCalendarAllowDeleteTitle => 'Разрешить удалять события';

  @override
  String get settingCalendarAllowDeleteDescription =>
      'Добавляет к каждому событию кнопку Удалить.';

  @override
  String get settingCalendarIdleCloseMinutesTitle =>
      'Закрывать при бездействии';

  @override
  String get settingIdleCloseCompassDescription =>
      'Возвращаться к панели после этого времени без касаний. В раскладке Compass вместо этого действует «Возвращаться в центр».';

  @override
  String get settingKioskAllowCalendarTitle => 'Календарь';

  @override
  String get settingKioskAllowCalendarDescription =>
      'Открывать семейный календарь из меню киоска.';

  @override
  String get calendarWeekStartLocale => 'Как в языке';

  @override
  String get calendarWeekStartSunday => 'Воскресенье';

  @override
  String get calendarWeekStartMonday => 'Понедельник';

  @override
  String get calendarWeekStartSaturday => 'Суббота';

  @override
  String get calendarIdleNever => 'Никогда';

  @override
  String get calendarIdle1Minute => '1 минута';

  @override
  String get calendarIdle2Minutes => '2 минуты';

  @override
  String get settingsMenuCalendar => 'Календарь';

  @override
  String get settingsMenuCalendarSummary =>
      'Семейные календари из Home Assistant';

  @override
  String get fleetTheCalendarsHiddenWithTheirChips =>
      'календари, скрытые их метками';

  @override
  String get settingCameraEnabledTitle => 'Включить камеру';

  @override
  String get settingCameraEnabledDescription =>
      'Использование камеры добавляет нагрузку на ЦП и нагрев, что может сократить срок службы батареи и устройства.';

  @override
  String get settingCameraDeviceTitle => 'Камера';

  @override
  String get settingCameraDeviceDescription => 'Какую камеру использовать.';

  @override
  String get settingCameraSnapshotResolutionTitle => 'Разрешение снимков';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      'Выше: резче, но больше нагрузки на ЦП и трафика.';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle =>
      'Отключить снимки при обнаружении';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      'Не делать автоматические снимки по срабатыванию обнаружения. Определение движения, лиц, присутствия и жестов продолжает работать. Ручные запросы и «Непрерывные снимки» продолжают снимать.';

  @override
  String get settingCameraSnapshotsTitle => 'Непрерывные снимки';

  @override
  String get settingCameraSnapshotsDescription =>
      'Публиковать свежий снимок камеры в Home Assistant с фиксированным интервалом.';

  @override
  String get settingCameraSnapshotIntervalTitle => 'Интервал снимков';

  @override
  String get settingCameraSnapshotIntervalDescription =>
      'Секунды между снимками.';

  @override
  String get cameraFront => 'Фронтальная';

  @override
  String get cameraBack => 'Задняя';

  @override
  String get cameraExternal => 'Внешняя';

  @override
  String get cameraOnlyCamera => 'Единственная камера этого устройства.';

  @override
  String get settingMotionSensorTitle => 'Датчик движения';

  @override
  String get settingMotionSensorDescription =>
      'Предоставлять движение как датчик Home Assistant. ВНИМАНИЕ: камера работает постоянно, даже при выключенном экране.';

  @override
  String get settingMotionSensorOffDelayTitle => 'Сбрасывать через';

  @override
  String get settingMotionSensorOffDelayDescription =>
      'Секунды без движения до показания «чисто».';

  @override
  String get settingMotionFpsTitle => 'Частота кадров движения';

  @override
  String get settingMotionFpsDescription =>
      'Сколько кадров в секунду камера проверяет движение. Ниже: легче для ЦП; 2 достаточно, чтобы заметить приближение.';

  @override
  String get settingMotionStartDelayTitle => 'Задержка запуска';

  @override
  String get settingMotionStartDelayDescription =>
      'Игнорировать движение это время после старта камеры, для устройств, чья камера физически двигается при открытии.';

  @override
  String get settingMotionSensitivityTitle => 'Чувствительность к движению';

  @override
  String get settingMotionSensitivityDescription =>
      'Выше: срабатывает от меньших движений. 1 требует большого изменения по кадру; 100 реагирует на малейшее движение.';

  @override
  String get cameraMotionPage => 'Датчик движения';

  @override
  String get cameraMotionHint =>
      'Датчик движения Home Assistant и общие настройки обнаружения';

  @override
  String get cameraNoCamera => 'Камера не обнаружена';

  @override
  String get cameraNoCameraHelp =>
      'Устройство не сообщает ни об одной пригодной камере.';

  @override
  String get cameraCameraPermission => 'Нет разрешения на камеру';

  @override
  String get cameraCameraPermissionHelp =>
      'Без него камера недоступна. Диалог выдачи разрешения появится на экране планшета.';

  @override
  String get cameraGrantOnDevice => 'Предоставить на устройстве';

  @override
  String get cameraCameraBlocked =>
      'Заблокировано. Android больше не спросит: разрешите в настройках приложения.';

  @override
  String get cameraCameraNeeded => 'Без этого камера недоступна.';

  @override
  String get cameraAppSettings => 'Настройки приложения';

  @override
  String get settingPersonSensorTitle => 'Включить датчик присутствия';

  @override
  String get settingPersonSensorDescription =>
      'Предоставить датчик присутствия устройства Home Assistant как датчик занятости. Нужно разрешение на доступ к журналам ниже.';

  @override
  String get cameraPersonPage => 'Датчик присутствия';

  @override
  String get cameraPersonHint =>
      'Датчик занятости Home Assistant из датчика присутствия устройства';

  @override
  String get cameraLatest => 'Последний снимок';

  @override
  String get cameraNoSnapshot => 'Снимков пока нет.';

  @override
  String get cameraImageAlt => 'Последний снимок камеры';

  @override
  String get cameraTakeSnapshot => 'Сделать снимок';

  @override
  String get cameraSnapshotFailed => 'Снимок не удался.';

  @override
  String cameraSnapshotError(String error) {
    return 'Снимок не удался: $error';
  }

  @override
  String get cameraCameraDisabled => 'Камера выключена в настройках камеры.';

  @override
  String get cameraSnapshotBusy => 'Снимок уже выполняется.';

  @override
  String get cameraPermissionDenied => 'Разрешение на камеру не предоставлено.';

  @override
  String get cameraDetectionDisabled => 'Снимки при обнаружении отключены.';

  @override
  String get cameraNoImage => 'Камера не вернула изображение.';

  @override
  String get cameraTimedOut => 'Камера не ответила вовремя.';

  @override
  String get cameraBackground => 'Камера недоступна, пока приложение в фоне.';

  @override
  String get cameraJustNow => 'только что';

  @override
  String cameraSecondsAgo(String count) {
    return '$count с назад';
  }

  @override
  String get cameraMinuteAgo => 'Минуту назад';

  @override
  String cameraMinutesAgo(String count) {
    return '$count мин назад';
  }

  @override
  String get cameraHourAgo => 'Час назад';

  @override
  String cameraHoursAgo(String count) {
    return '$count ч назад';
  }

  @override
  String get cameraDayAgo => 'День назад';

  @override
  String cameraDaysAgo(String count) {
    return '$count дн. назад';
  }

  @override
  String get cameraStatusHeading => 'Статус потока';

  @override
  String get cameraClientsHeading => 'Подключённые клиенты';

  @override
  String get cameraUnavailable => 'Недоступно';

  @override
  String get cameraStopped => 'Остановлено';

  @override
  String get cameraStreaming => 'Стриминг';

  @override
  String get cameraIdle => 'Ожидание';

  @override
  String get cameraConnected => 'Подключено';

  @override
  String get cameraChecking => 'Проверка…';

  @override
  String get cameraCheckingStatus => 'Проверка статуса потока…';

  @override
  String get cameraStatusUnavailable => 'Статус потока недоступен.';

  @override
  String get cameraListenerStopped => 'Слушатель остановлен.';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count подключённый зритель. Фактическое видео: $resolution.';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return 'Зрителей подключено: $count. Фактическое видео: $resolution.';
  }

  @override
  String get cameraReady =>
      'Готово. Кодировщик стартует при подключении зрителя.';

  @override
  String cameraFallback(String requested, String actual) {
    return 'Запрошено $requested, камера дала $actual.';
  }

  @override
  String cameraAudioError(String error) {
    return 'Звук: $error';
  }

  @override
  String get cameraAudioPaused =>
      'Звук на паузе, пока браузер использует микрофон.';

  @override
  String get cameraAudioStreaming => 'Стримится звук с микрофона.';

  @override
  String get cameraAudioIdle => 'Звук микрофона в простое.';

  @override
  String cameraDiscoveryError(String error) {
    return 'Обнаружение ONVIF: $error';
  }

  @override
  String get cameraOnvifUrl => 'URL ONVIF';

  @override
  String get cameraStreamUrl => 'URL потока';

  @override
  String get cameraWaitingAddress => 'Ожидание сетевого адреса';

  @override
  String get cameraClientsUnavailable => 'Информация о клиентах недоступна.';

  @override
  String get cameraNoClients => 'Подключённых клиентов нет.';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · Порт $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return 'Подключён $duration';
  }

  @override
  String cameraDurationSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String cameraDurationMinutes(String minutes, String seconds) {
    return '$minutes мин $seconds с';
  }

  @override
  String cameraDurationHours(String hours, String minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get cameraCredentialsMissing =>
      'Задайте имя пользователя и пароль стриминга, чтобы включить аутентификацию.';

  @override
  String get cameraPortWaiting => 'Ожидание освобождения порта RTSP.';

  @override
  String get cameraListenerFailed => 'Не удалось запустить слушатель RTSP.';

  @override
  String get settingCameraRtspEnabledTitle => 'Включить стриминг с камеры';

  @override
  String get settingCameraRtspEnabledDescription =>
      'Отдавать видео H.264 клиентам RTSP или ONVIF. Кодирование видео работает только при подключённом зрителе. Предпочитается аппаратное кодирование с программным запасным вариантом. Использует камеру, выбранную в настройках камеры.';

  @override
  String get settingCameraStreamingProtocolTitle => 'Протокол стриминга';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF позволяет совместимым клиентам находить камеру и подключаться к её потоку.';

  @override
  String get settingCameraRtspPortTitle => 'Порт';

  @override
  String get settingCameraRtspPortDescription => 'Порт сервера RTSP.';

  @override
  String get settingCameraOnvifPortTitle => 'Порт';

  @override
  String get settingCameraOnvifPortDescription => 'Порт сервера ONVIF.';

  @override
  String get settingCameraRtspResolutionTitle => 'Разрешение';

  @override
  String get settingCameraRtspResolutionDescription =>
      'Поддерживаемые размеры стриминга для выбранной камеры и кодировщика. Видео следует ориентации устройства.';

  @override
  String get settingCameraRtspAnalysisTitle => 'Анализ движения при стриминге';

  @override
  String get settingCameraRtspAnalysisDescription =>
      'Держать определение движения, лиц и жесты рукой доступными при подключённых зрителях. Выключение может позволить большие разрешения. Снимки тогда берутся из кадров видео в разрешении стриминга.';

  @override
  String get settingCameraRtspFpsTitle => 'Частота кадров';

  @override
  String get settingCameraRtspFpsDescription =>
      'Целевые кадры видео в секунду. У движения своя частота анализа. Фактическая отдача зависит от камеры.';

  @override
  String get settingCameraRtspBitrateTitle => 'Битрейт';

  @override
  String get settingCameraRtspBitrateDescription =>
      'Целевой битрейт видео. Выше: лучше детализация, больше сетевого трафика.';

  @override
  String get settingCameraRtspAudioTitle => 'Включать звук микрофона';

  @override
  String get settingCameraRtspAudioDescription =>
      'Включать звук микрофона в поток камеры. Использует ваши настройки микрофона. ВНИМАНИЕ: повышенная нагрузка на ЦП.';

  @override
  String get settingCameraRtspAuthTitle => 'Требовать аутентификацию';

  @override
  String get settingCameraRtspAuthDescription =>
      'Требовать имя пользователя и пароль для просмотра потока. Аутентификация не включает шифрование.';

  @override
  String get settingCameraRtspUsernameTitle => 'Имя пользователя';

  @override
  String get settingCameraRtspUsernameDescription =>
      'Имя пользователя для клиентов стриминга.';

  @override
  String get settingCameraRtspPasswordTitle => 'Пароль';

  @override
  String get settingCameraRtspPasswordDescription =>
      'Задайте пароль, чтобы запустить поток с аутентификацией.';

  @override
  String get cameraStreamingPage => 'Стриминг RTSP и ONVIF';

  @override
  String get cameraStreamingHint =>
      'Отдать камеру устройства через RTSP или ONVIF';

  @override
  String get cameraPortError => 'Введите целый номер порта от 1024 до 65535.';

  @override
  String get cameraUsernameError =>
      'Используйте от 1 до 64 символов без пробелов, кавычек, двоеточий и обратных слэшей.';

  @override
  String get cameraNoSizes => 'Поддерживаемые размеры недоступны';

  @override
  String get cameraNoSizesHelp =>
      'Поддерживаемых размеров нет. Проверьте соединение с камерой.';

  @override
  String get cameraResolutionSupport => 'Поддержка разрешений';

  @override
  String get cameraCheckingSizes =>
      'Проверка поддержки камеры и кодировщика H.264…';

  @override
  String get cameraSupportedSizes =>
      'Перечислены только размеры, поддерживаемые камерой и кодировщиком H.264 при текущих настройках стриминга.';

  @override
  String cameraExtraSizes(String sizes) {
    return 'Выключите «Анализ движения при стриминге», чтобы использовать также $sizes.';
  }

  @override
  String get cameraAnalysisOff =>
      'Определение движения, лиц и жесты рукой приостанавливаются при подключённых зрителях. Снимки берутся из кадров видео в разрешении стриминга.';

  @override
  String cameraRejectedSizes(String sizes) {
    return 'Кодировщик не может использовать $sizes при этих настройках.';
  }

  @override
  String cameraRejectedCount(String count) {
    return 'Исключено размеров камеры: $count. Кодировщик не может использовать их при этих настройках.';
  }

  @override
  String get cameraCaptureRejected =>
      'Другие размеры камеры недоступны в текущей настройке захвата.';

  @override
  String get cameraMotionEventsHeading => 'События движения';

  @override
  String get settingCameraOnvifEventsTitle => 'Отправлять события движения';

  @override
  String get settingCameraOnvifEventsDescription =>
      'Сообщать клиентам ONVIF, например NVR, об обнаруженном движении.';

  @override
  String get settingCameraOnvifEventsSourceTitle => 'Источник движения';

  @override
  String get settingCameraOnvifEventsSourceDescription =>
      'Датчик, который отправляет события движения.';

  @override
  String get cameraOnvifEventsSourceCamera => 'Датчик движения камеры';

  @override
  String get cameraOnvifEventsSourcePerson => 'Датчик присутствия';

  @override
  String get cameraOnvifEventsSourceEntity => 'Датчик Home Assistant';

  @override
  String get cameraOnvifEventsMotionSensorOff =>
      'Датчик движения камеры выключен. Включите его в разделе Камера > Датчик движения.';

  @override
  String get cameraOnvifEventsAnalysisOff =>
      'Анализ движения при стриминге выключен, поэтому камера не может обнаруживать движение, пока подключён зритель.';

  @override
  String get cameraOnvifEventsPersonSensorOff =>
      'Датчик присутствия выключен. Включите его в разделе Камера > Датчик присутствия.';

  @override
  String get cameraOverlaysHeading => 'Наложения';

  @override
  String get settingCameraRtspDateTimeTitle => 'Показывать дату и время';

  @override
  String get settingCameraRtspDateTimeDescription =>
      'Показывать дату и время устройства в левом верхнем углу видео в его формате даты и настройке 12/24 часов.';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => 'Чёрный фон';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      'Добавить чёрный фон за датой и временем для видимости.';

  @override
  String get settingCameraRtspTlsTitle => 'Шифровать поток';

  @override
  String get settingCameraRtspTlsDescription =>
      'Использовать TLS для шифрования видео и звука. Требуется совместимый плеер.';

  @override
  String get cameraStreamsNameRequired => 'нужно название';

  @override
  String get cameraStreamsBaseUrlRequired =>
      'нужен корректный baseUrl HTTP или HTTPS';

  @override
  String get cameraStreamsServerNotFound => 'сервер не найден';

  @override
  String get cameraStreamsInvalidStreamList =>
      'Go2RTC вернул некорректный список потоков';

  @override
  String get cameraStreamsKindRequired =>
      'kind должен быть go2rtc, whep или ha';

  @override
  String get cameraStreamsProtocolRequired =>
      'preferredProtocol должен быть auto, webrtc, hls или mjpeg';

  @override
  String get cameraStreamsServerRequired => 'нужен корректный serverId';

  @override
  String get cameraStreamsStreamRequired => 'нужен streamName';

  @override
  String get cameraStreamsEntityRequired => 'нужен entityId вида camera.*';

  @override
  String get cameraStreamsWhepRequired => 'нужен корректный URL WHEP';

  @override
  String get cameraStreamsCameraNotFound => 'камера не найдена';

  @override
  String get cameraStreamsListRequired => 'cameraIds должен быть списком';

  @override
  String get cameraStreamsViewCount => 'вид может содержать от 1 до 12 камер';

  @override
  String get cameraStreamsRepeatedCamera =>
      'камера может встречаться в виде лишь раз';

  @override
  String get cameraStreamsUnknownViewCamera =>
      'вид содержит неизвестную камеру';

  @override
  String get cameraStreamsUniqueViewName =>
      'название вида должно быть уникальным';

  @override
  String get cameraStreamsGridRange => 'сетка должна быть от 1 до 12';

  @override
  String get cameraStreamsGridTooSmall => 'сетка меньше числа камер';

  @override
  String get cameraStreamsViewNotFound => 'вид не найден';

  @override
  String get cameraStreamsDefaultViewDelete =>
      'вид по умолчанию нельзя удалить; вместо этого очистите его';

  @override
  String get cameraStreamsViewEmpty => 'в виде нет камер';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return 'не удалось прочитать Home Assistant: $error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return 'не удалось подключиться к $server: $error';
  }

  @override
  String get cameraStreamsHaUnavailable =>
      'Home Assistant не настроен или недоступен';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC вернул HTTP $status';
  }

  @override
  String get cameraStreamsImportHa => 'Импортировать камеры из Home Assistant';

  @override
  String get cameraStreamsImportHaHelp =>
      'Добавить каждую камеру подключённого Home Assistant, играющую через WebRTC, HLS или MJPEG. Повторный импорт добавляет новые камеры.';

  @override
  String get cameraStreamsImportFailed => 'Импорт не удался';

  @override
  String get cameraStreamsImportComplete => 'Импорт завершён';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return 'Добавлено: $added, отсутствует: $missing.';
  }

  @override
  String get settingCameraAllowH265Title => 'Разрешить потоки H.265';

  @override
  String get settingCameraAllowH265Description =>
      'Проигрывать потоки камер H.265 как есть. Устройство без декодирования H.265 покажет пустое изображение.';

  @override
  String get settingCameraPreferMseTitle => 'Предпочитать MSE, а не WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      'Стримить камеры Go2RTC сначала через MSE. Для устройств, не играющих WebRTC; добавляет секунду-две задержки.';

  @override
  String get settingCameraPreferHlsTitle => 'Предпочитать HLS, а не WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      'Стримить камеры Home Assistant сначала через HLS. Для устройств, не играющих WebRTC; добавляет несколько секунд задержки.';

  @override
  String get settingCameraSingleAudioTitle => 'Звук для одиночной камеры';

  @override
  String get settingCameraSingleAudioDescription =>
      'Проигрывать звук камеры, когда на экране одна камера. Сетки из нескольких камер беззвучны.';

  @override
  String get settingCameraPinchZoomTitle =>
      'Масштабирование щипком (одна камера)';

  @override
  String get settingCameraPinchZoomDescription =>
      'Приближать картинку двумя пальцами, когда на экране одна камера. Перетаскивайте для перемещения, двойное касание для сброса.';

  @override
  String get settingCameraAutoDismissSecondsTitle => 'Автозакрытие через';

  @override
  String get settingCameraAutoDismissCompassDescription =>
      'Закрывает открытый вид камер через это время. 0 оставляет его открытым. Заставка с камерами не затрагивается. В раскладке Compass вместо этого действует «Возвращаться в центр».';

  @override
  String get cameraStreamsPlayback => 'Воспроизведение';

  @override
  String get cameraStreamsOff => 'Выкл';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String get cameraStreamsGridHelp =>
      'Сетки из нескольких камер содержат только видео. Для слабых устройств используйте потоки Go2RTC меньшего разрешения и при желании отдельный полноэкранный поток.';

  @override
  String get cameraStreamsServers => 'Серверы Go2RTC';

  @override
  String get cameraStreamsImportStreams => 'Импортировать потоки';

  @override
  String get cameraStreamsDeleteServer => 'Удалить сервер';

  @override
  String get cameraStreamsAddServer => 'Добавить сервер Go2RTC';

  @override
  String get cameraStreamsAddServerHelp =>
      'Подключитесь к серверу и импортируйте его потоки.';

  @override
  String get cameraStreamsEditServer => 'Изменение сервера';

  @override
  String get cameraStreamsName => 'Название';

  @override
  String get cameraStreamsBaseUrl => 'Базовый URL';

  @override
  String get cameraStreamsUsername => 'Имя пользователя (необязательно)';

  @override
  String get cameraStreamsNewPassword =>
      'Новый пароль (оставьте пустым, чтобы сохранить текущий)';

  @override
  String get cameraStreamsPassword => 'Пароль (необязательно)';

  @override
  String get cameraStreamsInvalidCertificate =>
      'Разрешить недействительный сертификат TLS';

  @override
  String get cameraStreamsSaveServerFailed => 'Не удалось сохранить сервер';

  @override
  String get cameraStreamsDeleteServerHelp =>
      'Его камеры будут убраны из каждого вида.';

  @override
  String get cameraStreamsCameras => 'Камеры';

  @override
  String get cameraStreamsNoCameras => 'Камеры не настроены';

  @override
  String get cameraStreamsNoCamerasHelp =>
      'Импортируйте камеры из Home Assistant или Go2RTC либо добавьте вручную.';

  @override
  String get cameraStreamsDeleteCamera => 'Удалить камеру';

  @override
  String get cameraStreamsAddManually => 'Добавить камеру вручную';

  @override
  String get cameraStreamsAddManuallyHelp =>
      'Используйте имя потока Go2RTC, URL WHEP или сущность камеры Home Assistant.';

  @override
  String get cameraStreamsUnknownCamera => 'Неизвестная камера';

  @override
  String get cameraStreamsUnknownServer => 'Неизвестный сервер';

  @override
  String get cameraStreamsMissing => ' (отсутствует)';

  @override
  String get cameraStreamsAddCamera => 'Добавить камеру';

  @override
  String get cameraStreamsEditCamera => 'Изменение камеры';

  @override
  String get cameraStreamsType => 'Тип';

  @override
  String get cameraStreamsGo2RtcStream => 'Поток Go2RTC';

  @override
  String get cameraStreamsDirectWhep => 'Прямой URL WHEP';

  @override
  String get cameraStreamsHaCamera => 'Камера Home Assistant';

  @override
  String get cameraStreamsEntity => 'Сущность камеры';

  @override
  String get cameraStreamsProtocol => 'Предпочтительный протокол';

  @override
  String get cameraStreamsAuto => 'Авто';

  @override
  String get cameraStreamsServer => 'Сервер';

  @override
  String get cameraStreamsStreamName => 'Имя потока';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Имя потока Go2RTC';

  @override
  String get cameraStreamsFullscreen => 'Полноэкранный поток (необязательно)';

  @override
  String get cameraStreamsWhep => 'URL WHEP';

  @override
  String get cameraStreamsSaveCameraFailed => 'Не удалось сохранить камеру';

  @override
  String get cameraStreamsDeleteCameraHelp =>
      'Она будет убрана из каждого вида.';

  @override
  String get cameraStreamsLoadFailed => 'Не удалось загрузить камеры.';

  @override
  String get cameraStreamsViews => 'Виды';

  @override
  String get cameraStreamsEmptyView => 'Камер пока нет';

  @override
  String get cameraStreamsNamesShown => 'Названия показаны';

  @override
  String get cameraStreamsNamesHidden => 'Названия скрыты';

  @override
  String get cameraStreamsShowView => 'Показать вид';

  @override
  String get cameraStreamsDeleteView => 'Удалить вид';

  @override
  String get cameraStreamsCreateView => 'Создать вид камер';

  @override
  String get cameraStreamsAddFirst => 'Сначала добавьте камеру.';

  @override
  String get cameraStreamsChooseCameras =>
      'Выберите и упорядочьте до 12 камер.';

  @override
  String get cameraStreamsShowFailed => 'Не удалось показать вид';

  @override
  String get cameraStreamsShowFailedRemote => 'Не удалось показать вид';

  @override
  String get cameraStreamsEditView => 'Изменение вида';

  @override
  String get cameraStreamsViewId => 'ID вида';

  @override
  String get cameraStreamsShowNames => 'Показывать названия камер';

  @override
  String get cameraStreamsShowNamesHelp =>
      'Показывать подпись поверх каждой камеры.';

  @override
  String get cameraStreamsGrid => 'Сетка';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count камера';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return 'Камер: $count';
  }

  @override
  String get cameraStreamsInView => 'В этом виде';

  @override
  String get cameraStreamsAvailable => 'Доступные';

  @override
  String cameraStreamsPosition(String position) {
    return 'Позиция $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'Нет в Go2RTC';

  @override
  String get cameraStreamsSaveViewFailed => 'Не удалось сохранить вид';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return 'Удалить $name?';
  }

  @override
  String get cameraStreamsCannotUndo => 'Это нельзя отменить.';

  @override
  String get cameraStreamsShow => 'Показать';

  @override
  String get cameraStreamsStop => 'Остановить';

  @override
  String get settingAnalyticsBasicTitle => 'Базовая аналитика';

  @override
  String get settingAnalyticsBasicDescription =>
      'Информация об устройстве: модель, версия Android, версия приложения, размер экрана и язык.';

  @override
  String get settingAnalyticsUsageTitle => 'Использование';

  @override
  String get settingAnalyticsUsageDescription =>
      'Подробности того, что вы используете в Kiosk Satellite.';

  @override
  String get settingAnalyticsDiagnosticsTitle => 'Диагностика';

  @override
  String get settingAnalyticsDiagnosticsDescription =>
      'Отправлять отчёты о сбоях при неожиданных ошибках.';

  @override
  String get deviceAnalyticsPage => 'Аналитика Kiosk Satellite';

  @override
  String get deviceAnalyticsIntro =>
      'Делитесь обезличенной информацией о вашей установке, чтобы помочь сделать Kiosk Satellite лучше и определить, каким устройствам и функциям уделять внимание.';

  @override
  String get deviceAnalyticsLearn => 'Узнайте, как мы обрабатываем ваши данные';

  @override
  String get deviceAnalyticsLearnHelp =>
      'Что отправляет аналитика Kiosk Satellite, а что не отправляет никогда.';

  @override
  String get deviceExportConfig => 'Экспортировать конфигурацию';

  @override
  String get deviceExportConfigHelp =>
      'Сохранить все настройки и локальное хранилище страницы в файл.';

  @override
  String get deviceExportConfigRemoteHelp =>
      'Скачать все настройки и локальное хранилище страницы.';

  @override
  String get deviceImportConfig => 'Импортировать конфигурацию';

  @override
  String get deviceImportConfigHelp =>
      'Заменить настройки этого устройства из экспортированного файла.';

  @override
  String get deviceExportFailed => 'Не удалось экспортировать';

  @override
  String get deviceExported => 'Конфигурация экспортирована';

  @override
  String get deviceImportFailed => 'Не удалось импортировать';

  @override
  String get deviceInvalidJson => 'Этот файл не является корректным JSON.';

  @override
  String get deviceImportComplete => 'Импорт завершён';

  @override
  String deviceAppliedSettings(String count) {
    return 'Применено настроек: $count.';
  }

  @override
  String deviceAppliedReload(String count) {
    return 'Применено настроек: $count. Страница может перезагрузиться.';
  }

  @override
  String get deviceReplaceOriginal => 'Заменить исходное устройство';

  @override
  String get deviceReplaceQuestion =>
      'Заменить настройки этого устройства настройками из файла? Страница может перезагрузиться.';

  @override
  String get deviceNewDevice => 'Настроить как новое устройство';

  @override
  String get deviceReplaceIdentity =>
      'Сохраняет имя из резервной копии и идентификационные данные ESPHome; исходное устройство должно оставаться не в сети.';

  @override
  String get deviceNewIdentity =>
      'Назначить собственное имя и идентификационные данные ESPHome, так что оба устройства будут уникальны.';

  @override
  String get deviceRestoreStorage => 'Восстановить локальное хранилище WebView';

  @override
  String get deviceRestoreStorageHelp =>
      'Включает сеанс входа в Home Assistant и выбор assist_satellite для Voice Satellite: два устройства не должны использовать один спутник.';

  @override
  String get deviceDownload => 'Скачать';

  @override
  String get deviceChooseFile => 'Выбрать файл…';

  @override
  String get deviceImportFailedSentence => 'Импорт не удался.';

  @override
  String deviceReplaceNamed(String name) {
    return 'Заменить «$name»';
  }

  @override
  String get settingDeviceNameTitle => 'Имя устройства';

  @override
  String get settingDeviceNameDescription =>
      'Понятное имя в удалённом управлении и имя устройства, публикуемое в Home Assistant.';

  @override
  String get settingDeviceHostnameTitle => 'Имя mDNS';

  @override
  String get settingDeviceHostnameDescription =>
      'Доступ к удалённому администрированию по этому имени и настроенному порту в локальной сети. Очистите, чтобы снова взять имя устройства.';

  @override
  String get settingDisableImpellerTitle => 'Устаревший рендерер';

  @override
  String get settingDisableImpellerDescription =>
      'Использовать старый рендерер Skia для старых GPU, падающих при запуске. Включается сам после двух таких падений; вступает в силу при следующем старте приложения.';

  @override
  String get settingLegacyWebViewTitle => 'Устаревший рендерер WebView';

  @override
  String get settingLegacyWebViewDescription =>
      'Рисовать панель в текстуру для старых GPU, падающих при её появлении. Включается сам там, где устройству это нужно; вступает в силу при следующем старте приложения.';

  @override
  String get deviceHostnamePlaceholder => 'Из имени устройства';

  @override
  String get deviceConfiguration => 'Конфигурация';

  @override
  String get devicePermissionsManager => 'Менеджер разрешений';

  @override
  String get deviceOptions => 'Параметры';

  @override
  String get deviceStatus => 'Статус';

  @override
  String get deviceConnection => 'Соединение';

  @override
  String get devicePermissions => 'Разрешения';

  @override
  String get deviceHelp => 'Справка';

  @override
  String get deviceAccess => 'Доступ';

  @override
  String get deviceReading => 'Чтение…';

  @override
  String get deviceChecking => 'Проверка…';

  @override
  String get deviceUnavailable => 'Статус недоступен.';

  @override
  String get deviceGrantOnDevice => 'Предоставить на устройстве';

  @override
  String get deviceAppSettings => 'Настройки приложения';

  @override
  String get deviceCopyCommand => 'Копировать команду';

  @override
  String get deviceOpenGuide => 'Открыть руководство';

  @override
  String get deviceNotSet => 'Не задано';

  @override
  String get deviceGranted => 'Предоставлено';

  @override
  String get deviceNotGranted => 'Не предоставлено';

  @override
  String get deviceMissing => 'Отсутствует';

  @override
  String get deviceNotOffered => 'Не предлагается';

  @override
  String get deviceOn => 'вкл';

  @override
  String get deviceOff => 'выкл';

  @override
  String get deviceServiceHint =>
      'Статус, что поддерживает её работу, нужные разрешения';

  @override
  String get deviceRemoteHintActual =>
      'Управляйте этим киоском из браузера в вашей сети';

  @override
  String get deviceUpdatesHint => 'Где приложение ищет новые выпуски';

  @override
  String get deviceShizukuHint => 'Соединение, разрешения Android и настройка';

  @override
  String get deviceHelperHint =>
      'Статус тихого обновления, настройка ADB и инструкции';

  @override
  String get deviceAnalyticsHint =>
      'Делиться обезличенной информацией, чтобы помочь улучшить Kiosk Satellite';

  @override
  String get deviceHardwareHint =>
      'Модель, версия Android, адреса, память, аптайм';

  @override
  String get deviceHaHint => 'Соединение, версия и что показывает киоск';

  @override
  String get deviceWebViewHint => 'Версия движка, рендерер и user agent';

  @override
  String get devicePasswordSet => '•••••• (задан)';

  @override
  String get deviceSaveFailed =>
      'Не удалось сохранить эту настройку. Попробуйте снова.';

  @override
  String get deviceOpenSettingsDevice => 'Открыть настройки на устройстве';

  @override
  String get deviceHardwareButtons => 'Аппаратные кнопки';

  @override
  String get deviceHardwareButtonsHeld =>
      'Кнопки устройства доходят до жестов и Voice Satellite.';

  @override
  String get deviceHardwareButtonsMissing =>
      'Кнопки устройства ничего не делают, пока не включена служба кнопок.';

  @override
  String get deviceHeadlessAdbMicrophone =>
      'У этого устройства нет экрана. Выдайте через adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO';

  @override
  String get deviceHeadlessAdbNotifications =>
      'У этого устройства нет экрана. Выдайте через adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS';

  @override
  String get deviceHeadlessAdbLocation =>
      'У этого устройства нет экрана. Выдайте через adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION';

  @override
  String get deviceHeadlessAdbBluetooth =>
      'У этого устройства нет экрана. Выдайте через adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN, затем то же для BLUETOOTH_CONNECT';

  @override
  String get deviceHeadlessAdbBattery =>
      'У этого устройства нет экрана. Выдайте через adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceHeadlessAdbStorage =>
      'У этого устройства нет экрана. Выдайте через adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE, затем то же для WRITE_EXTERNAL_STORAGE';

  @override
  String get deviceHeadlessAdbButtons =>
      'У этого устройства нет экрана. Включите через adb: adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/.HeadlessKeyService, затем adb shell settings put secure accessibility_enabled 1';

  @override
  String get deviceHeadlessAdbButtonsRestart =>
      'Служба кнопок включена, но не запущена. Перезагрузите устройство, чтобы запустить её: adb reboot';

  @override
  String get deviceHardwarePage => 'Оборудование';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => 'Модель устройства';

  @override
  String get deviceAndroidVersion => 'Версия Android';

  @override
  String get deviceAndroidBuild => 'Сборка Android';

  @override
  String get deviceIpv4 => 'Адрес IPv4';

  @override
  String get deviceIpv6 => 'Адреса IPv6';

  @override
  String get deviceAppUptime => 'Аптайм приложения';

  @override
  String get deviceNetworkUptime => 'Аптайм сети';

  @override
  String get deviceCpuUsage => 'Загрузка ЦП';

  @override
  String get deviceCpuClock => 'Частота ЦП';

  @override
  String get deviceCpuTemp => 'Температура ЦП';

  @override
  String get deviceBatteryLevel => 'Уровень заряда';

  @override
  String get deviceBatteryTemp => 'Температура аккумулятора';

  @override
  String get deviceScreenBrightness => 'Яркость экрана';

  @override
  String get deviceScreenStatus => 'Состояние экрана';

  @override
  String get deviceScreenSize => 'Размер экрана';

  @override
  String get deviceRam => 'ОЗУ (свободно/всего)';

  @override
  String get deviceStorage => 'Внутреннее хранилище (свободно/всего)';

  @override
  String get deviceHaUrl => 'URL Home Assistant';

  @override
  String get deviceWakeDetection => 'Определение слова пробуждения';

  @override
  String get deviceWakeStatus => 'Статус слова пробуждения';

  @override
  String get deviceEngine => 'Движок';

  @override
  String get deviceWakeWords => 'Слова пробуждения';

  @override
  String get deviceStopWord => 'Стоп-слово';

  @override
  String get deviceMotionDetection => 'Определение движения';

  @override
  String get deviceFaceDetection => 'Определение лица';

  @override
  String get deviceProvider => 'Провайдер';

  @override
  String get deviceVersion => 'Версия';

  @override
  String get deviceUserAgent => 'User agent';

  @override
  String get devicePlugged => 'от сети';

  @override
  String get deviceLowMemory => 'мало';

  @override
  String get deviceRequiredPermissions => 'Необходимые системные разрешения';

  @override
  String get devicePermissionIntro =>
      'Разрешения выдаются на этом устройстве: каждая кнопка открывает диалог Android или экран настроек здесь. Некоторые производители добавляют собственные менеджеры батареи или автозапуска, о которых Android не сообщает.';

  @override
  String get devicePermissionIntroRemote =>
      'Разрешения выдаются на устройстве: каждая кнопка открывает диалог Android или экран настроек там. Некоторые производители добавляют собственные менеджеры батареи или автозапуска, о которых Android не сообщает.';

  @override
  String get deviceMicrophone => 'Микрофон';

  @override
  String get deviceMicrophoneHeld =>
      'Позволяет использовать микрофон для определения слова пробуждения, распознавания речи и звонков интеркома.';

  @override
  String get deviceBattery => 'Батарея без ограничений';

  @override
  String get deviceBatteryHeld =>
      'Позволяет процессу работать в фоне без приостановки или завершения.';

  @override
  String get deviceCamera => 'Камера';

  @override
  String get deviceCameraHeld =>
      'Определение движения и снимки могут использовать камеру.';

  @override
  String get deviceBluetooth => 'Устройства поблизости';

  @override
  String get deviceBluetoothHeld =>
      'Bluetooth-прокси может искать устройства поблизости.';

  @override
  String get deviceNotifications => 'Уведомления';

  @override
  String get deviceNotificationsHeld =>
      'Разрешает постоянное уведомление службы Kiosk Satellite, показывающее, что она удерживает.';

  @override
  String get deviceOverlay => 'Поверх других приложений';

  @override
  String get deviceOverlayHeld =>
      'Kiosk Satellite может возвращаться на передний план.';

  @override
  String get deviceWriteSettings => 'Изменение системных настроек';

  @override
  String get deviceWriteSettingsHeld =>
      'Изменения яркости меняют реальную яркость панели.';

  @override
  String get deviceUiGuard => 'Защита системного интерфейса';

  @override
  String get deviceUiGuardHeld =>
      'Шторка уведомлений и список недавних приложений закрываются сами, пока экран защищён.';

  @override
  String get deviceDeviceAdmin => 'Администратор устройства';

  @override
  String get deviceDeviceAdminHeld => 'Позволяет приложению выключать экран.';

  @override
  String get deviceAllFiles => 'Доступ ко всем файлам';

  @override
  String get deviceAllFilesHeld =>
      'Менеджер файлов может просматривать общее хранилище.';

  @override
  String get deviceUsageAccess => 'Доступ к статистике использования';

  @override
  String get deviceUsageAccessHeld =>
      'Датчик «Приложение на переднем плане» может называть приложение на экране.';

  @override
  String get deviceLocation => 'Местоположение';

  @override
  String get deviceLocationHeld =>
      'Страницы, сканирование Bluetooth и датчики местоположения могут использовать позицию устройства.';

  @override
  String get deviceMicBlocked =>
      'Заблокировано. Android больше не спросит: разрешите в настройках приложения.';

  @override
  String get deviceMicMissing =>
      'Определение слова пробуждения включено, но ничего не слушает.';

  @override
  String get deviceMicIdle =>
      'Нужно для определения слова пробуждения, интеркома и страниц, запрашивающих микрофон.';

  @override
  String get deviceBatteryMissing =>
      'Android может приостановить приложение при выключенном экране: соединение с Home Assistant разорвётся, а сущности ESPHome станут недоступны.';

  @override
  String get deviceCameraMissing => 'Камера включена, но не открывается.';

  @override
  String get deviceCameraIdle =>
      'Нужно для определения движения, снимков камеры и страниц, запрашивающих камеру.';

  @override
  String get deviceBluetoothMissing =>
      'Bluetooth-прокси включён, но не может сканировать.';

  @override
  String get deviceBluetoothLocation =>
      'Сканированию Bluetooth нужно разрешение «Местоположение».';

  @override
  String get deviceBluetoothLocationOff =>
      'Местоположение выключено в настройках устройства, поэтому сканирование Bluetooth ничего не находит.';

  @override
  String get deviceBluetoothIdle =>
      'Нужно Bluetooth-прокси для поиска устройств.';

  @override
  String get deviceNotificationMissing =>
      'Нужно для показа постоянного уведомления службы Kiosk Satellite.';

  @override
  String get deviceOverlayMissing =>
      'Без этого приложение не сможет открыться снова после сбоя, обновления или слова пробуждения, услышанного за другим приложением.';

  @override
  String get deviceOverlayIdle =>
      'Позволяет приложению возвращаться на передний план, а щиту блокировки покрывать весь экран.';

  @override
  String get deviceBrightnessMissing =>
      'Яркость затемняет только окно приложения: панель и Home Assistant не видят изменения.';

  @override
  String get deviceBrightnessIdle =>
      'Нужно, чтобы задавать реальную яркость панели, а не затемнять окно приложения.';

  @override
  String get deviceGuardMissing =>
      'Шторка уведомлений и список недавних приложений остаются доступными. Включите Kiosk Satellite в разделе «Специальные возможности».';

  @override
  String get deviceGuardIdle =>
      'Закрывает шторку уведомлений и список недавних приложений, пока режим киоска защищает экран.';

  @override
  String get deviceAdminIdle =>
      'Позволяет «Выключить экран» погасить панель, а не только затемнить её.';

  @override
  String get deviceFilesIdle =>
      'Позволяет менеджеру файлов просматривать общее хранилище, а не только папку приложения.';

  @override
  String get deviceUsageIdle =>
      'Позволяет датчику приложения на переднем плане называть приложения, кроме Kiosk Satellite.';

  @override
  String get deviceLocationMissing =>
      'Android не выдаст результаты сканирования Bluetooth без местоположения, а датчики местоположения не смогут читать GPS-приёмник.';

  @override
  String get deviceLocationIdle =>
      'Используется страницами, запрашивающими местоположение, сканированием Bluetooth и датчиками местоположения ESPHome.';

  @override
  String get deviceServiceOverlayMissing =>
      'Без этого служба не сможет перезапустить киоск после сбоя или закрытия из списка недавних приложений.';

  @override
  String get deviceServiceOverlayIdle =>
      'Нужно для перезапуска киоска после сбоя.';

  @override
  String get deviceListeningMissing =>
      'Фоновое прослушивание включено, но ничего не слушает.';

  @override
  String get deviceListeningIdle => 'Нужно для фонового прослушивания.';

  @override
  String get deviceMotionIdle => 'Нужно для определения движения.';

  @override
  String get deviceBatteryAdb =>
      'У этого устройства нет экрана настроек для этого. Выдайте через adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      'У этого устройства нет экрана настроек для этого. Выдайте через adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get deviceNotificationAccess => 'Доступ к уведомлениям';

  @override
  String get deviceNotificationAccessHeld =>
      '«Сейчас играет» может отслеживать приложения, которые воспроизводят медиа на этом устройстве.';

  @override
  String get deviceNotificationAccessMissing =>
      'Без этого Android не показывает медиасеансы, поэтому «Сейчас играет» не может отслеживать приложения на этом устройстве.';

  @override
  String get deviceNotificationAccessIdle =>
      'Позволяет «Сейчас играет» отслеживать приложения, которые воспроизводят медиа на этом устройстве.';

  @override
  String get settingRemoteEnabledTitle => 'Удалённое управление';

  @override
  String get settingRemoteEnabledDescription =>
      'Запустить встроенный веб-сервер администрирования.';

  @override
  String get settingRemotePortTitle => 'Порт сервера';

  @override
  String get settingRemotePortDescription =>
      'Порт интерфейса удалённого администрирования.';

  @override
  String get settingRemotePasswordTitle => 'Пароль администратора';

  @override
  String get settingRemotePasswordDescription =>
      'Нужен для входа в удалённый интерфейс.';

  @override
  String get settingRemoteFleetDiscoveryTitle => 'Поиск других киосков';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      'Объявлять это устройство в сети и показывать другие киоски в удалённом администрировании для переключения между ними.';

  @override
  String get settingRemoteAdminUrlTitle => 'URL администрирования';

  @override
  String get settingRemoteAdminUrlDescription =>
      'Адрес, который другие киоски открывают в «Сменить киоск», чтобы перейти к этому, например имя обратного прокси. Оставьте пустым, чтобы использовать его сетевой адрес.';

  @override
  String get deviceAdminUrlInvalid =>
      'Введите корректный адрес, например https://kiosk.example.com';

  @override
  String get deviceAdminUrlPath =>
      'Введите только адрес, без пути. Пример: https://kiosk.example.com';

  @override
  String get deviceRemotePage => 'Удалённое администрирование';

  @override
  String get deviceAdminAddress => 'Адрес администрирования';

  @override
  String get deviceAdminAddressHelp =>
      'Откройте этот адрес в браузере на компьютере.';

  @override
  String get deviceByName => 'По имени';

  @override
  String get deviceByNameHelp =>
      'Тот же адрес по имени хоста, в сетях, разрешающих имена .local.';

  @override
  String get deviceByCertificateNameHelp =>
      'Тот же адрес по имени из сертификата устройства.';

  @override
  String get devicePasswordNeeded =>
      'Задайте пароль администратора ниже, чтобы запустить сервер.';

  @override
  String get deviceServerStopped => 'Сервер не работает.';

  @override
  String devicePortError(String port, String error) {
    return 'Не удалось слушать порт $port: $error';
  }

  @override
  String get settingRemoteTlsTitle => 'Использовать HTTPS';

  @override
  String get settingRemoteTlsDescription =>
      'Шифрует удалённое администрирование, API и WebSocket. Браузер может попросить принять сертификат устройства.';

  @override
  String get settingServiceCpuAwakeTitle =>
      'Не давать ЦП засыпать при выключенном экране';

  @override
  String get settingServiceCpuAwakeDescription =>
      'Держит wake lock в тёмные периоды, чтобы соединения и таймеры работали вовремя. Расходует батарею на планшете не от сети.';

  @override
  String get deviceServicePage => 'Служба Kiosk Satellite';

  @override
  String get deviceKeepingRunning => 'Удержание в работе';

  @override
  String get deviceService => 'Служба';

  @override
  String get deviceStopped => 'Остановлена';

  @override
  String get deviceStoppedSentence => 'Остановлена.';

  @override
  String get deviceRunning => 'Работает';

  @override
  String get deviceRunningSentence => 'Работает.';

  @override
  String get deviceRunningBackground =>
      'Работает без исключения для переднего плана.';

  @override
  String get deviceServiceTypes => 'Типы службы переднего плана';

  @override
  String get deviceServiceTypesHelp =>
      'Что служба объявляет Android ради функций, которые удерживает.';

  @override
  String get deviceNoneDeclared => 'Не объявлено.';

  @override
  String get deviceNone => 'нет';

  @override
  String get deviceCpuLock => 'Wake lock ЦП';

  @override
  String get deviceCpuOff => 'Выключен: настройка ниже выключена.';

  @override
  String get deviceCpuHeld => 'Удерживается: экран выключен.';

  @override
  String get deviceCpuReleased => 'Освобождён, пока экран включён.';

  @override
  String get deviceNotHeld => 'Не удерживается.';

  @override
  String get deviceHeld => 'Удерживается';

  @override
  String get deviceReleased => 'Освобождён';

  @override
  String get deviceWifiLock => 'Удержание Wi-Fi';

  @override
  String get deviceWifiHeld =>
      'Удерживается: радио не уходит в энергосбережение.';

  @override
  String get deviceWifiHelp =>
      'Не даёт радио уйти в энергосбережение при выключенном экране.';

  @override
  String get deviceNotification => 'Уведомление';

  @override
  String get deviceNotificationHidden =>
      'Скрыто: уведомления приложения выключены. Служба работает независимо.';

  @override
  String get deviceNotificationShown =>
      'Показывается в шторке уведомлений, пока служба работает.';

  @override
  String get deviceHidden => 'Скрыто';

  @override
  String get deviceShown => 'Показано';

  @override
  String get deviceReasonHa => 'Соединение с Home Assistant';

  @override
  String get deviceReasonHaHelp =>
      'Держит сеанс панели и его websocket открытыми при выключенном экране.';

  @override
  String get deviceReasonListening => 'Фоновое прослушивание';

  @override
  String get deviceReasonListeningHelp =>
      'Держит движок слова пробуждения и его микрофон работающими за другими приложениями.';

  @override
  String get deviceReasonRtsp => 'Звук микрофона RTSP';

  @override
  String get deviceReasonRtspHelp =>
      'Держит поток с микрофона доступным подключённым RTSP-клиентам.';

  @override
  String get deviceReasonEspHome => 'Сервер ESPHome';

  @override
  String get deviceReasonEspHomeHelp =>
      'Держит API-сервер ESPHome отвечающим Home Assistant.';

  @override
  String get deviceReasonRemote => 'Удалённое администрирование';

  @override
  String get deviceReasonRemoteHelp =>
      'Держит веб-сервер администрирования отвечающим.';

  @override
  String get deviceReasonProtections => 'Защита киоска';

  @override
  String get deviceReasonProtectionsHelp =>
      'Перезапускает киоск, когда его закрыли из списка недавних приложений или он упал.';

  @override
  String get deviceReasonBluetooth => 'Bluetooth-прокси';

  @override
  String get deviceReasonBluetoothHelp =>
      'Держит сканирование Bluetooth работающим, пока приложение не на экране.';

  @override
  String get deviceReasonLocation => 'Датчики местоположения';

  @override
  String get deviceReasonLocationHelp =>
      'Обеспечивает поступление GPS-фиксов при выключенном экране или другом приложении на экране.';

  @override
  String get deviceReasonPerson => 'Определение присутствия';

  @override
  String get deviceReasonPersonHelp =>
      'Продолжает читать датчик присутствия устройства, когда другое приложение на экране.';

  @override
  String get deviceReasonCameraHelp =>
      'Держит камеру доступной после выключения панели для определения движения и лиц.';

  @override
  String deviceServiceStopped(String error) {
    return 'Остановлена: $error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return 'Работает $uptime.';
  }

  @override
  String get settingShizukuInstallUpdatesTitle =>
      'Устанавливать обновления через Shizuku';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      'Устанавливать обновления Kiosk Satellite без подтверждения на устройстве. Shizuku должен быть запущен и авторизован.';

  @override
  String get deviceShizukuAccess => 'Доступ через Shizuku';

  @override
  String get deviceShizukuCheck => 'Проверка доступности';

  @override
  String get deviceShizukuRoot => 'Подключено с доступом root';

  @override
  String get deviceShizukuShell => 'Подключено с доступом shell';

  @override
  String get deviceShizukuGrant =>
      'Нажмите, чтобы предоставить доступ. Одобрите запрос на этом киоске.';

  @override
  String get deviceShizukuGrantRemote =>
      'Предоставьте доступ и одобрите запрос на этом киоске.';

  @override
  String get deviceShizukuDenied =>
      'Разрешите Kiosk Satellite в приложении Shizuku.';

  @override
  String get deviceShizukuUnsupported => 'Требуется Shizuku 13 или новее.';

  @override
  String get deviceShizukuStart => 'Запустите Shizuku на этом устройстве.';

  @override
  String get deviceShizukuTest => 'Проверить соединение';

  @override
  String get deviceShizukuTestHelp =>
      'Читает идентификатор процесса, не меняя устройство.';

  @override
  String get deviceShizukuTestTitle => 'Проверка соединения';

  @override
  String get deviceShizukuTestFailed =>
      'Shizuku не смог завершить проверку соединения.';

  @override
  String get deviceShizukuAlreadyGranted => 'Все разрешения уже предоставлены.';

  @override
  String get deviceShizukuConfirmed =>
      'Android подтвердил запрошенные разрешения.';

  @override
  String get deviceShizukuResults => 'Результаты разрешений';

  @override
  String get deviceShizukuGrantAll => 'Выдать все разрешения';

  @override
  String get deviceShizukuGrantAllHelp =>
      'Выдать все разрешения, используемые KS, включая выключенные функции.';

  @override
  String get deviceShizukuSetup => 'Настроить Shizuku';

  @override
  String get deviceShizukuSetupHelp =>
      'Прочитайте инструкции по установке и запуску.';

  @override
  String get deviceShizukuLifetime =>
      'Shizuku, запущенный через ADB, нужно запустить снова после перезагрузки устройства. Доступ shell не даёт прав root.';

  @override
  String get deviceShizukuFailed => 'Запрос к Shizuku не удался';

  @override
  String get deviceShizukuApprove => 'Одобрите запрос на киоске.';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku успешно выполнил команду с доступом $access.';
  }

  @override
  String get shizukuPermissionUnconfirmed =>
      'Android не подтвердил это разрешение. Проверьте менеджер разрешений на устройстве.';

  @override
  String get shizukuPermissionReadFailed =>
      'Не удалось прочитать текущие разрешения. Попробуйте снова.';

  @override
  String get shizukuRestartTimedOut => 'Истёк тайм-аут команды перезапуска';

  @override
  String get shizukuRestartRefused => 'Android отказал в перезапуске';

  @override
  String get shizukuCommandTimedOut => 'Истёк тайм-аут команды';

  @override
  String get shizukuRequestRejected => 'Android отклонил запрос';

  @override
  String get deviceDisconnectedError => 'Устройство отключено';

  @override
  String get deviceResponseTimedOut => 'Истёк тайм-аут ответа устройства';

  @override
  String get deviceRequestAborted => 'Запрос прерван';

  @override
  String get shizukuActionBusy =>
      'Действие с устройством через Shizuku уже выполняется';

  @override
  String get shizukuGrantFirst => 'Сначала предоставьте доступ Shizuku';

  @override
  String get shizukuNoResponse => 'Команда Shizuku не ответила';

  @override
  String get shizukuCommandFailed => 'Команда Shizuku не удалась';

  @override
  String get shizukuStartRequired =>
      'Запустите Shizuku 13 или новее и разрешите Kiosk Satellite в Shizuku';

  @override
  String get shizukuConnectionFailed => 'Не удалось подключиться к Shizuku';

  @override
  String get shizukuHelperNotConnected => 'Помощник Shizuku не подключился';

  @override
  String get shizukuHelperUnavailable => 'Помощник Shizuku недоступен';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates =>
      'Шифрование соединения и сертификаты';

  @override
  String get tlsCertificateType => 'Тип сертификата';

  @override
  String get tlsImported => 'Импортированный';

  @override
  String get tlsSelfSigned => 'Самоподписанный';

  @override
  String get tlsExpires => 'Истекает';

  @override
  String get tlsSHA256Fingerprint => 'Отпечаток SHA-256';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      'Сертификат истёк. Обновите его или импортируйте замену.';

  @override
  String get tlsCopyPublicCertificate => 'Копировать публичный сертификат';

  @override
  String get tlsDownloadPublicCertificate => 'Скачать публичный сертификат';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      'Используйте этот сертификат в браузерах и стриминговых клиентах.';

  @override
  String get tlsRenewCertificate => 'Обновить сертификат';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      'Сохранить текущий приватный ключ и обновить сроки сертификата.';

  @override
  String get tlsImportCertificate => 'Импортировать сертификат';

  @override
  String get tlsUseACertificateIssuedForThisDevice =>
      'Использовать сертификат, выданный этому устройству.';

  @override
  String get tlsReplaceCertificate => 'Заменить сертификат';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      'Создать новый приватный ключ и самоподписанный сертификат.';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      'Создать новый приватный ключ и сертификат? Активные шифрованные соединения закроются. Браузер может попросить принять новый сертификат.';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      'Вставьте цепочку PEM-сертификатов и её незашифрованный приватный ключ. Они проверяются перед заменой текущего сертификата.';

  @override
  String get tlsCertificateChainPEM => 'Цепочка сертификатов (PEM)';

  @override
  String get tlsPrivateKeyPEM => 'Приватный ключ (PEM)';

  @override
  String get tlsThisFieldIsRequired => 'Это поле обязательно.';

  @override
  String get tlsReplace => 'Заменить';

  @override
  String get tlsRenew => 'Обновить';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      'Включите HTTPS перед импортом приватного ключа удалённо.';

  @override
  String get tlsCertificateOperationFailed =>
      'Операция с сертификатом не удалась.';

  @override
  String get tlsChangeConnectionProtocol => 'Сменить протокол соединения';

  @override
  String get tlsConnectionProtocolHelp =>
      'Текущее удалённое соединение закроется. Переподключитесь по адресу ниже. Возможно, придётся войти снова.';

  @override
  String get tlsConfirm => 'Подтвердить';

  @override
  String get tlsCertificateManagement => 'Управление сертификатами';

  @override
  String get tlsServerCertificateRequired =>
      'Используйте сертификат сервера, а не сертификат CA.';

  @override
  String get tlsServerAuthenticationRequired =>
      'Сертификат не разрешает аутентификацию сервера.';

  @override
  String get tlsKeyAlgorithmRequired =>
      'Используйте приватный ключ EC или RSA.';

  @override
  String get tlsKeyMismatch => 'Сертификат и приватный ключ не совпадают.';

  @override
  String get tlsMaterialTooLarge => 'Сертификат или ключ слишком велики.';

  @override
  String get tlsPemCertificatesRequired => 'Ожидались сертификаты PEM.';

  @override
  String get tlsCertificateMissing => 'Сертификат не найден.';

  @override
  String get tlsUnencryptedKeyRequired =>
      'Используйте незашифрованный приватный ключ PEM.';

  @override
  String get tlsHostnameRequired => 'Требуется имя хоста или IP-адрес.';

  @override
  String get tlsIssuerRenewalRequired =>
      'Импортируйте обновлённый сертификат от его издателя.';

  @override
  String get tlsStoredIdentityDamaged =>
      'Сохранённые идентификационные данные TLS повреждены.';

  @override
  String get tlsExpiredCertificate =>
      'Сертификат TLS истёк. Обновите его или импортируйте замену.';

  @override
  String get deviceHelperPage => 'Необязательный помощник обновлений';

  @override
  String get deviceHelperStatus => 'Статус помощника';

  @override
  String get deviceHelperError => 'Не удалось проверить помощника обновлений.';

  @override
  String get deviceHelperUnneeded =>
      'Android теперь может устанавливать обновления тихо. Помощник не нужен.';

  @override
  String get deviceHelperIntro =>
      'Этому устройству сейчас нужно подтверждение на экране для установки обновлений через Android. Необязательный помощник позволяет Kiosk Satellite устанавливать обновления без нажатия.';

  @override
  String get deviceHelperBusy => 'Идёт установка обновления.';

  @override
  String get deviceHelperReady =>
      'Готов. Обновления устанавливаются без подтверждения.';

  @override
  String get deviceHelperUnavailable =>
      'Недоступен. Запустите помощник через ADB, чтобы включить обновления без подтверждения.';

  @override
  String get deviceHelperLifetime =>
      'Помощник переживает перезапуски приложения и обновления, но останавливается после перезагрузки устройства. Запустите его снова командой с компьютера с ADB. После этого компьютер можно отключить.';

  @override
  String get deviceHelperStart => 'Запустить через ADB';

  @override
  String get deviceHelperGuide => 'Руководство по настройке';

  @override
  String get deviceHelperGuideHelp =>
      'Прочитайте инструкции и требования к помощнику обновлений.';

  @override
  String get settingUpdateSourceTitle => 'Источник обновлений';

  @override
  String get settingUpdateSourceDescription =>
      'Где приложение ищет новые выпуски.';

  @override
  String get settingUpdateSourceUrlTitle => 'URL репозитория';

  @override
  String get settingUpdateSourceUrlDescription =>
      'Папка на веб-сервере, доступная киоску, с releases.json и APK выпусков.';

  @override
  String get deviceUpdatesPage => 'Обновления';

  @override
  String get deviceUpdateGithub => 'Репозиторий GitHub';

  @override
  String get deviceUpdateCustom => 'Свой репозиторий';

  @override
  String get deviceUpdateGuide => 'Руководство по своему репозиторию';

  @override
  String get deviceUpdateGuideHelp =>
      'Как разместить файл releases и APK в собственной сети.';

  @override
  String get deviceInstallFile => 'Установить из файла';

  @override
  String get deviceInstallFileHelp =>
      'Загрузите APK Kiosk Satellite с компьютера через удалённое администрирование на этой же странице. Для киоска без доступа к GitHub или своему репозиторию.';

  @override
  String get deviceInstallFileRemoteHelp =>
      'Загрузите APK Kiosk Satellite с этого компьютера и установите его. Для киоска без доступа к GitHub или своему репозиторию.';

  @override
  String get deviceUploadedApk => 'Загруженный APK';

  @override
  String get deviceInstalling => 'Установка…';

  @override
  String get deviceDeviceNoAnswer => 'Устройство не ответило.';

  @override
  String get deviceInstallFailed =>
      'Обновление не удалось. Проверьте журналы устройства.';

  @override
  String get deviceConfirmTablet => 'Подтвердите на экране планшета';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return 'Версия $version (сборка $build, $size МБ) на устройстве и ждёт установки.';
  }

  @override
  String deviceInstallVersion(String version) {
    return 'Установить версию $version';
  }

  @override
  String deviceHttpError(String code) {
    return 'Устройство ответило HTTP $code.';
  }

  @override
  String get deviceUploadFailed => 'Не удалось загрузить.';

  @override
  String get deviceInstallFleet => 'Установить на группу';

  @override
  String get deviceSendingFleet => 'Отправка в группу…';

  @override
  String get deviceSameBuild => 'Киоск уже работает на этой сборке.';

  @override
  String get deviceInstallConfirmation =>
      'Установку нужно подтвердить на экране планшета, если киоск не устанавливает обновления тихо.';

  @override
  String get deviceSelfLast => 'Этот киоск обновляется последним.';

  @override
  String get deviceUpdatingFleet => 'Обновление группы';

  @override
  String deviceUploading(String percent) {
    return 'Загрузка… $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return 'Загруженный APK: версия $version (сборка $build, $size МБ).';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'Киоск работает на $version (сборка $build).';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return 'Отправка на $name… $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return 'Установка на $name…';
  }

  @override
  String deviceInstallingNames(String names) {
    return '$names: установка.';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      'Введите URL папки, например http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      'Введите только URL папки, ничего не добавляя после пути. Пример: http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy =>
      'Загрузка уже идёт. Дождитесь её завершения.';

  @override
  String get updateInstallBusy =>
      'Установка уже идёт. Дождитесь её завершения.';

  @override
  String get updateNoAvailable => 'Обновлений нет.';

  @override
  String get updateNoUploaded => 'Нет загруженного APK в ожидании.';

  @override
  String get updateUploadEmpty => 'Загрузка была пустой.';

  @override
  String get updateInvalidApk => 'Файл не является APK Android.';

  @override
  String get updateUploadedGone =>
      'Загруженный APK исчез. Загрузите его снова.';

  @override
  String get updateShizukuInstallerFailed =>
      'Shizuku не смог установить обновление. Установщик с подтверждением не открылся.';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return 'Недостаточно места: APK весит $size МБ, установке нужно около $required МБ, а на устройстве свободно $free МБ.';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return 'Загрузка прервана после $size МБ: $error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return 'Загрузка завершилась рано: пришло $received из $expected МБ.';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return 'APK: $package, а не Kiosk Satellite ($expected).';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'Версия APK $version (сборка $build) ниже установленной $currentVersion (сборка $currentBuild). Откат на старую версию запрещён: Android тоже не установил бы такой APK.';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return 'Не удалось скачать (HTTP $status).';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return 'Загрузка застыла: данных не было $seconds с.';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return 'Обновление не удалось: $error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return 'Установка не удалась: $error';
  }

  @override
  String get updateAnotherPackage => 'другой пакет';

  @override
  String get deviceKioskSatelliteUpdates => 'Обновления Kiosk Satellite';

  @override
  String get deviceAndroidSystemUpdates => 'Системные обновления Android';

  @override
  String get settingAndroidUpdatePolicyTitle =>
      'Устанавливать обновления Android';

  @override
  String get settingAndroidUpdatePolicyDescription =>
      'Обновления самого Android от производителя устройства, например Google или Samsung. Режим киоска скрывает запрос на перезапуск для их установки.';

  @override
  String get deviceAndroidUpdateAsk => 'Спрашивать на устройстве';

  @override
  String get deviceAndroidUpdateAutomatic => 'Сразу';

  @override
  String get deviceAndroidUpdateWindowed => 'В окне времени';

  @override
  String get settingAndroidUpdateWindowStartTitle => 'Устанавливать с';

  @override
  String get settingAndroidUpdateWindowStartDescription =>
      'Местное время начала ежедневного окна для установки и перезапуска.';

  @override
  String get settingAndroidUpdateWindowEndTitle => 'Устанавливать до';

  @override
  String get settingAndroidUpdateWindowEndDescription =>
      'Местное время окончания окна. Окно, переходящее через полночь, заканчивается на следующий день.';

  @override
  String get settingUiLanguageTitle => 'Язык';

  @override
  String get settingUiLanguageDescription =>
      'Язык Kiosk Satellite и удалённого администрирования. Home Assistant использует свой язык.';

  @override
  String get settingUiThemeTitle => 'Тема приложения';

  @override
  String get settingUiThemeDescription =>
      'Светлая или тёмная для собственных экранов приложения: меню, настройки, диалоги. «Системная» следует настройке Android.';

  @override
  String get settingUiScaleTitle => 'Масштаб интерфейса';

  @override
  String get settingUiScaleDescription =>
      'Размер собственных экранов приложения: меню, настройки, диалоги. Для дисплеев высокой плотности. Веб-контент сохраняет размер.';

  @override
  String get deviceUserInterface => 'Интерфейс';

  @override
  String get deviceThemeDark => 'Тёмная';

  @override
  String get deviceThemeLight => 'Светлая';

  @override
  String get deviceThemeSystem => 'Системная';

  @override
  String get settingUiToastsHiddenTitle =>
      'Показывать всплывающие системные уведомления';

  @override
  String get settingUiToastsHiddenDescription =>
      'Выберите, какие всплывающие сообщения появляются поверх панели. Сообщения в настройках показываются всегда.';

  @override
  String get deviceToastsAll => 'Все';

  @override
  String get deviceToastsNone => 'Нет';

  @override
  String get deviceToastBack => 'Подсказки кнопки «Назад»';

  @override
  String get deviceToastGestures => 'Действия жестов';

  @override
  String get deviceToastHoldMode => 'Режим удержания';

  @override
  String get deviceToastLinks => 'Ссылки на панели';

  @override
  String get deviceToastDownloads => 'Загрузки';

  @override
  String get deviceToastNetwork => 'Состояние сети';

  @override
  String get deviceToastUpdates => 'Проверка обновлений';

  @override
  String get deviceToastVoice => 'Уведомления Voice Satellite';

  @override
  String get deviceToastTimers => 'Таймеры';

  @override
  String get deviceToastAlarms => 'Будильники';

  @override
  String get deviceToastMusicLibrary => 'Музыкальная библиотека';

  @override
  String get deviceToastIntercom => 'Интерком';

  @override
  String get deviceToastAppLauncher => 'Лаунчер приложений';

  @override
  String get deviceToastPlugins => 'Действия плагинов';

  @override
  String get settingUiDrawerItemsTitle => 'Пункты бокового меню';

  @override
  String get settingUiDrawerItemsDescription =>
      'Выберите, какие пункты показывает боковое меню и в каком порядке.';

  @override
  String get settingShowInKioskMenuTitle => 'Показывать в меню киоска';

  @override
  String get settingDlnaEnabledTitle => 'Включить рендерер DLNA';

  @override
  String get settingDlnaEnabledDescription =>
      'Показывать изображения и воспроизводить медиа, отправленные из Home Assistant или любого приложения DLNA. Устройство появляется как медиаплеер с именем устройства.';

  @override
  String get settingDlnaAudioBackgroundTitle => 'Держать звук в фоне';

  @override
  String get settingDlnaAudioBackgroundDescription =>
      'Отправленный звук воспроизводится, не захватывая экран.';

  @override
  String get settingDlnaPortTitle => 'Порт сервера';

  @override
  String get settingDlnaPortDescription =>
      'Порт рендерера, заполняется при запуске. Измените, чтобы переместить рендерер, или очистите, чтобы он выбрал сам.';

  @override
  String get settingDlnaPortPlaceholder => 'Задаётся при запуске рендерера';

  @override
  String get settingEsphomeRealMacTitle =>
      'Использовать реальный MAC-адрес Wi-Fi';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant свяжет этот киоск с тем же устройством, которое уже отслеживают ваши сетевые интеграции. Изменение создаст новое устройство ESPHome в Home Assistant.';

  @override
  String get settingEsphomeMacOverrideTitle => 'Подменить MAC-адрес Wi-Fi';

  @override
  String get settingEsphomeMacOverrideDescription =>
      'Поскольку MAC-адрес не удаётся определить, введите свой в этом поле. Изменение создаст новое устройство ESPHome в Home Assistant.';

  @override
  String get esphomeAdvanced => 'Дополнительные настройки';

  @override
  String get esphomeAdvancedHelp => 'Реальный или подменённый MAC-адрес Wi-Fi';

  @override
  String get esphomeMacInvalid => 'Введите корректный MAC-адрес.';

  @override
  String esphomeMacHardware(String mac) {
    return 'Сообщается $mac.';
  }

  @override
  String esphomeMacManual(String mac) {
    return 'Сообщается $mac, введён ниже.';
  }

  @override
  String get esphomeMacUnavailable =>
      'Android не раскрывает аппаратный адрес этого устройства.';

  @override
  String get settingAnnouncementsEnabledTitle => 'Включить объявления';

  @override
  String get settingAnnouncementsEnabledDescription =>
      'Проигрывать объявления, которые Home Assistant отправляет действием announce.';

  @override
  String get esphomeTtsSection => 'Синтез речи';

  @override
  String get settingAnnouncementsTtsEngineTitle => 'Движок синтеза речи';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'Сущность синтеза речи Home Assistant, которая произносит объявления.';

  @override
  String get settingAnnouncementsTtsLanguageTitle => 'Язык';

  @override
  String get settingAnnouncementsTtsLanguageDescription =>
      'Язык, на котором произносятся объявления.';

  @override
  String get settingAnnouncementsTtsVoiceTitle => 'Голос';

  @override
  String get settingAnnouncementsTtsVoiceDescription =>
      'Голос, которым произносятся объявления.';

  @override
  String get esphomeTtsFirst => 'Первый доступный';

  @override
  String get esphomeTtsDefault => 'По умолчанию';

  @override
  String get settingAnnouncementsChimeTitle => 'Сначала сигнал';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Проигрывать сигнал перед объявлением.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Звук сигнала';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Проигрывается так же громко, как объявление.';

  @override
  String get esphomeAnnouncements => 'Объявления';

  @override
  String get esphomeAnnouncementsHelp =>
      'Голосовые объявления из Home Assistant';

  @override
  String get esphomeChime => 'Сигнал';

  @override
  String get esphomeTtsUnavailable => 'Home Assistant недоступен';

  @override
  String get esphomeTtsNoVoices => 'Нет голосов для выбора';

  @override
  String get settingBtproxyEnabledTitle => 'Включить Bluetooth-прокси';

  @override
  String get settingBtproxyEnabledDescription =>
      'Передавать устройства Bluetooth поблизости в Home Assistant.';

  @override
  String get settingBtproxyScanDutyTitle => 'Интенсивность сканирования';

  @override
  String get settingBtproxyScanDutyDescription =>
      'Какую долю времени радио слушает. Ниже: меньше нагрузки на ЦП; редко вещающие устройства появляются дольше.';

  @override
  String get settingBtproxyScreenOffScanTitle =>
      'Сканировать при выключенном экране';

  @override
  String get settingBtproxyScreenOffScanDescription =>
      'Включите, если прокси перестаёт передавать при выключенном экране. Больше нагрузки на ЦП.';

  @override
  String get settingBtproxyConnectionsTitle =>
      'Разрешить подключения устройств';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant может подключаться к устройствам Bluetooth через этот прокси.';

  @override
  String get settingBtproxyMacLookupTitle => 'Искать производителей онлайн';

  @override
  String get settingBtproxyMacLookupDescription =>
      'Даёт имена неизвестным устройствам поблизости по префиксу их аппаратного адреса через api.macvendors.com. Отправляется только 3-байтовый префикс производителя, по разу на каждого; больше ничего не покидает устройство.';

  @override
  String get settingBtproxyNearbySortTitle => 'Сортировка';

  @override
  String get settingBtproxyNearbySortDescription =>
      'Порядок списка устройств поблизости ниже.';

  @override
  String get settingBtproxyMinConnectRssiTitle =>
      'Минимальный сигнал для подключений';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      'Отклонять подключения устройств, слышимых слабее этого, чтобы их взял более близкий прокси.';

  @override
  String get esphomeOptionContinuous => 'Постоянно';

  @override
  String get esphomeOptionBalanced => 'Сбалансированно';

  @override
  String get esphomeOptionLowPower => 'Энергосбережение';

  @override
  String get esphomeOptionLastSeen => 'Последнее появление';

  @override
  String get esphomeOptionName => 'Имя';

  @override
  String get esphomeOptionMacAddress => 'MAC-адрес';

  @override
  String get esphomeOptionSignalStrength => 'Сила сигнала';

  @override
  String get esphomeOptionNoLimit => 'Без лимита';

  @override
  String get esphomeOption70DbmSameRoom => '-70 дБм (та же комната)';

  @override
  String get esphomeOption80Dbm => '-80 дБм';

  @override
  String get esphomeOption85Dbm => '-85 дБм';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 дБм (край зоны)';

  @override
  String get esphomeBluetooth => 'Bluetooth-прокси';

  @override
  String get esphomeBluetoothHelp =>
      'Передавать устройства Bluetooth поблизости в Home Assistant';

  @override
  String get esphomeBluetoothOff =>
      'Bluetooth выключен. Включите его, чтобы использовать прокси.';

  @override
  String get esphomeBluetoothUnsupported =>
      'Недоступно на этом устройстве: нет Bluetooth.';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      'Недоступно на этом устройстве: его сборка Android не поддерживает Bluetooth LE.';

  @override
  String get esphomeIdentityBthome => 'Датчик BTHome';

  @override
  String get esphomeIdentityXiaomi => 'Датчик Xiaomi';

  @override
  String get esphomeIdentityQingping => 'Датчик Qingping';

  @override
  String get esphomeIdentityGoogleNest => 'Устройство Google/Nest';

  @override
  String get esphomeIdentityEddystone => 'Маячок Eddystone';

  @override
  String get esphomeIdentityGoogleFastPair => 'Устройство Google Fast Pair';

  @override
  String get esphomeIdentityAppleFindMy => 'Устройство Apple Find My';

  @override
  String get esphomeIdentityExposure => 'Уведомление о контактах (телефон)';

  @override
  String get esphomeIdentityAugustYale => 'Замок August/Yale';

  @override
  String get esphomeIdentityAmazon => 'Устройство Amazon';

  @override
  String get esphomeIdentityTile => 'Трекер Tile';

  @override
  String get esphomeIdentityInput => 'Устройство ввода (пульт/клавиатура)';

  @override
  String get esphomeIdentityHeartRate => 'Датчик пульса';

  @override
  String get esphomeIdentityEnvironmental => 'Датчик среды';

  @override
  String get esphomeIdentityApple => 'Устройство Apple';

  @override
  String get esphomeIdentityWindows => 'ПК с Windows';

  @override
  String get esphomeIdentitySamsung => 'Устройство Samsung';

  @override
  String get esphomeIdentityGoogle => 'Устройство Google';

  @override
  String get esphomeIdentityUnknown => 'Неизвестное устройство';

  @override
  String esphomeIdentityVendor(String vendor) {
    return 'Устройство $vendor';
  }

  @override
  String get esphomeNearby => 'Устройства поблизости';

  @override
  String get esphomeNearbySearch =>
      'Устройства Bluetooth, которые слышит этот киоск, с именами, где известны.';

  @override
  String get esphomeNearbyEmpty => 'Пока ничего не слышно.';

  @override
  String get esphomeNearbyWaiting =>
      'Пока ничего не слышно. Устройства появятся здесь, когда прокси начнёт сканировать.';

  @override
  String get esphomeRotating => '(меняющийся адрес)';

  @override
  String esphomeNearbyCount(String count, String total) {
    return 'Показаны первые $count из $total.';
  }

  @override
  String esphomeSlots(String count) {
    return 'Через этот прокси можно подключить одновременно до $count устройств. Home Assistant направит остальные через другие прокси.';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return '$count с назад';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return '$count мин назад';
  }

  @override
  String esphomeHoursAgo(String count) {
    return '$count ч назад';
  }

  @override
  String get settingLocationEnabledTitle => 'Сообщать местоположение';

  @override
  String get settingLocationEnabledDescription =>
      'Читать позицию GPS и отдавать её в Home Assistant как датчики широты, долготы, точности, высоты и скорости. Включение или выключение перерегистрирует устройство ESPHome.';

  @override
  String get settingLocationIntervalTitle => 'Интервал обновления';

  @override
  String get settingLocationIntervalDescription =>
      'Секунды между чтениями позиции.';

  @override
  String get esphomeGps => 'Датчик GPS';

  @override
  String get esphomeGpsHelp =>
      'Предоставлять данные датчика GPS в Home Assistant';

  @override
  String get esphomeLocationOff => 'Выключено.';

  @override
  String get esphomeLocationWaiting =>
      'Ожидание первого фикса. Холодный старт под открытым небом может занять несколько минут.';

  @override
  String get esphomeCoordinates => 'Последние координаты';

  @override
  String get esphomeLocationDenied =>
      'Разрешение на местоположение не предоставлено.';

  @override
  String get esphomeLocationAbsent => 'Нет GPS-приёмника.';

  @override
  String esphomeLocationError(String error) {
    return 'GPS недоступен: $error';
  }

  @override
  String get esphomeLocationUnsupported =>
      'Недоступно на этом устройстве: нет GPS-приёмника.';

  @override
  String get settingNotificationsTransparencyTitle => 'Прозрачность';

  @override
  String get settingNotificationsTransparencyDescription =>
      'Позволяет экрану за карточками уведомлений просвечивать. Текст и значки остаются плотными.';

  @override
  String get settingNotificationsBlurTitle => 'Размытие фона';

  @override
  String get settingNotificationsBlurDescription =>
      'Размывает то, что просвечивает через прозрачную карточку уведомления. Примечание: размытие нельзя применить поверх поверхности панели Home Assistant.';

  @override
  String get settingNotificationsChimeFileTitle => 'Звук уведомления';

  @override
  String get settingNotificationsChimeFileDescription =>
      'Звуковые файлы читаются из Android/data/me.jxl.kiosk_satellite/files/sounds на устройстве; папка также доступна в менеджере файлов.';

  @override
  String get settingNotificationsVolumeTitle => 'Громкость уведомлений';

  @override
  String get settingNotificationsVolumeDescription =>
      'Насколько громко играет звук уведомления, отдельно от громкости медиа и ассистента.';

  @override
  String get esphomeNotifications => 'Уведомления';

  @override
  String get esphomeNotificationsHelp =>
      'Прозрачность, размытие, звук уведомления, тестовое уведомление';

  @override
  String get esphomeAppearance => 'Внешний вид';

  @override
  String get esphomeSound => 'Звук';

  @override
  String get esphomeNotificationTest => 'Тестовое уведомление';

  @override
  String esphomeNotificationHelp(String action) {
    return 'Уведомления отправляются из Home Assistant действием $action. Тест показывает одно поверх панели.';
  }

  @override
  String get esphomeNotificationBody =>
      'Так выглядит и звучит уведомление из Home Assistant.';

  @override
  String get esphomeNotificationSearch =>
      'Действие Home Assistant, отправляющее уведомления, и кнопка для показа тестового уведомления.';

  @override
  String get esphomeLocation => 'Местоположение';

  @override
  String get esphomeLocationSearch =>
      'Разрешение «Местоположение», нужное датчикам местоположения.';

  @override
  String get esphomeBluetoothSearch =>
      'Разрешение «Устройства поблизости», нужное Bluetooth-прокси для сканирования.';

  @override
  String get esphomeLocationMissing =>
      'Без этого GPS-приёмник не читается, и датчики местоположения остаются неизвестными.';

  @override
  String get esphomeLocationServicesOff =>
      'Местоположение выключено в настройках устройства, поэтому приёмник ничего не выдаёт.';

  @override
  String get esphomeLocationApproximate =>
      'Разрешено только приблизительное местоположение, а GPS-приёмнику нужно точное.';

  @override
  String get esphomeLocationGranted =>
      'Датчики местоположения могут читать GPS-приёмник.';

  @override
  String get esphomeBluetoothGranted =>
      'Прокси может искать устройства Bluetooth поблизости.';

  @override
  String get esphomeBluetoothMissing =>
      'Без этого прокси не может искать устройства.';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android выдаёт результаты сканирования Bluetooth, включая маячки, только с разрешением «Местоположение». Прокси никогда не читает позицию устройства.';

  @override
  String get esphomeBluetoothLocationOff =>
      'Местоположение выключено в настройках устройства, поэтому сканирование Bluetooth ничего не находит.';

  @override
  String get esphomeBluetoothBeacons =>
      'Сканирование Bluetooth может слышать маячки.';

  @override
  String get esphomeSent => 'Отправлено';

  @override
  String get esphomeNotsaved => 'Не сохранено';

  @override
  String get settingEsphomeEnabledTitle => 'Включить ESPHome';

  @override
  String get settingEsphomeEnabledDescription =>
      'Отдавать этот киоск в Home Assistant как устройство ESPHome: его датчики и элементы управления как нативные сущности. Обнаруживается автоматически.';

  @override
  String get settingEsphomeEntitiesTitle => 'Предоставить сущности киоска';

  @override
  String get settingEsphomeEntitiesDescription =>
      'Отдавать датчики и элементы управления этого устройства как сущности ESPHome.';

  @override
  String get settingEsphomeExcludedEntitiesTitle => 'Исключённые сущности';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      'Выберите сущности, исключаемые из Home Assistant. Все остальные доступные сущности предоставляются. Сохранение переподключает ESPHome.';

  @override
  String get settingEsphomeNodeNameTitle => 'Имя узла';

  @override
  String get settingEsphomeNodeNameDescription =>
      'Именует этот киоск в сети; Home Assistant строит из него имена действий. Переименование переименовывает и их.';

  @override
  String get settingEsphomeNodeNamePlaceholder => 'Задаётся при первом старте';

  @override
  String get settingBtproxyKeyTitle => 'Ключ шифрования';

  @override
  String get settingBtproxyKeyDescription =>
      'Вставьте этот ключ в Home Assistant, когда он спросит ключ шифрования. Генерируется автоматически при первом старте.';

  @override
  String get settingBtproxyKeyPlaceholder => 'Генерируется при первом старте';

  @override
  String get settingBtproxyPortTitle => 'Порт API';

  @override
  String get settingBtproxyPortDescription =>
      'Порт, к которому подключается Home Assistant. Оставьте пустым для стандарта ESPHome, 6053.';

  @override
  String esphomeStartFailed(String error) {
    return 'Серверу ESPHome не удалось запуститься: $error';
  }

  @override
  String get esphomeExcludedInvalid => 'Выберите список ID сущностей.';

  @override
  String settingsMadeBy(String heart, String author) {
    return 'Сделано с $heart. Автор: $author';
  }

  @override
  String get settingsBuyCoffee => 'Купить автору кофе';

  @override
  String get settingClapStrictnessTitle => 'Определение хлопков';

  @override
  String get settingClapDetectionDescription =>
      '«Строго» требует более громких и равномерно распределённых хлопков. «Большая комната» даёт хлопкам время затихнуть в помещении с эхом.';

  @override
  String get gestureStrictnessStandard => 'Стандартно';

  @override
  String get gestureStrictnessStrict => 'Строго';

  @override
  String get gestureStrictnessLargeRoom => 'Большая комната';

  @override
  String get gestureOff => 'Жесты выключены';

  @override
  String get gestureOffHelp =>
      'В настройках режима киоска включено «Отключить жесты».';

  @override
  String get gestureEmpty => 'Жесты не настроены';

  @override
  String get gestureEmptyHelp =>
      'Жест запускает своё действие без видимого элемента управления.';

  @override
  String get gestureDeleteTooltip => 'Удалить жест';

  @override
  String get gestureDeleteTitle => 'Удалить жест?';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return 'Убрать этот жест? Триггер: $trigger. Действие: $action.';
  }

  @override
  String get gestureAdd => 'Добавить жест';

  @override
  String get gestureAddHelp =>
      'Выберите жест и действие, которое он запускает.';

  @override
  String get gestureTouchHelp =>
      'Жесты наблюдаются, а не блокируются: касания также доходят до панели, поэтому углы и формы несколькими пальцами не дают на ней ничего срабатывать.';

  @override
  String get gestureClapper => 'Хлопки';

  @override
  String get gestureReadFailed => 'Не удалось прочитать настройки.';

  @override
  String get gestureHandGestures => 'Жесты рукой';

  @override
  String get settingHandGestureHoldSecondsTitle => 'Длительность удержания';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      'Удерживайте один и тот же жест пальцами столько времени до запуска действия. Увеличьте, чтобы сократить случайные срабатывания.';

  @override
  String get gestureHoldInstant => 'Мгновенно';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String get haCustomPages => 'Свои страницы';

  @override
  String get haCustomPagesHintDashboard =>
      'Ваши HTML-страницы в качестве панели';

  @override
  String get settingHaCustomPagesSocketTitle =>
      'Общее подключение к Home Assistant';

  @override
  String get settingHaCustomPagesSocketDescription =>
      'Свои страницы работают с Home Assistant через подключение киоска, без токена на странице.';

  @override
  String get haCustomPagesAdd => 'Добавить страницу';

  @override
  String get haCustomPagesEmptyAnyServer =>
      'Добавьте HTML-страницы из папки www Home Assistant или с другого сервера, чтобы выбирать их как панель.';

  @override
  String get haCustomPagesGuide => 'Руководство по своим страницам';

  @override
  String get haCustomPagesGuideHint =>
      'Как создать страницу, которая работает с Home Assistant.';

  @override
  String get haCustomPageAddTitle => 'Добавить свою страницу';

  @override
  String get haCustomPageEditTitle => 'Изменить свою страницу';

  @override
  String get haCustomPageName => 'Название';

  @override
  String get haCustomPageLocation => 'Путь или URL';

  @override
  String get haCustomPageLocationHint =>
      'Файл в папке www Home Assistant, например /local/dashboard.html, или URL страницы на другом сервере.';

  @override
  String get haCustomPageNameMissing => 'Введите название.';

  @override
  String get haCustomPageLocationInvalid =>
      'Введите путь в /local/ или URL с http или https.';

  @override
  String get haCustomPageDuplicate =>
      'Этот путь уже использует другая страница.';

  @override
  String get haCustomPageNotFound =>
      'В Home Assistant нет файла по этому пути.';

  @override
  String get haCustomPageUrlNotFound => 'На сервере нет страницы по этому URL.';

  @override
  String get haCustomPageUnreachable =>
      'Не удалось подключиться к Home Assistant.';

  @override
  String get haCustomPageUrlUnreachable => 'Не удалось подключиться к серверу.';

  @override
  String haCustomPageStatus(String code) {
    return 'Home Assistant ответил кодом HTTP $code.';
  }

  @override
  String haCustomPageUrlStatus(String code) {
    return 'Сервер ответил кодом HTTP $code.';
  }

  @override
  String get settingHaHoldModeTitle => 'Режим удержания';

  @override
  String get settingHaHoldModeDescription =>
      'Держать текущий вид на экране: заставка, ротация видов панели и таймер возврата домой приостановлены до выключения.';

  @override
  String get settingHaHoldReleaseMinutesTitle =>
      'Закончить удержание автоматически через';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      'Автоматически выключает режим удержания по прошествии заданного времени. 0: удерживать до выключения вручную.';

  @override
  String get haHoldHint => 'Закрепить текущий вид, автовыключение, пункт меню';

  @override
  String get haNever => 'Никогда';

  @override
  String haMinutes(String minutes) {
    return '$minutes мин';
  }

  @override
  String haHours(String hours) {
    return '$hours ч';
  }

  @override
  String haHoursMinutes(String hours, String minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get settingDisableSuspendTitle => 'Держать соединение в фоне';

  @override
  String get settingDisableSuspendDescription =>
      'Выключает настройку Home Assistant «Приостанавливать фоновые соединения», которая иначе разорвала бы соединение через несколько минут после выключения экрана.';

  @override
  String get settingFreezeOnScreensaverTitle =>
      'Приостанавливать панель во время заставки';

  @override
  String get settingFreezeOnScreensaverDescription =>
      'Прекращает отрисовку панели, пока заставка её закрывает, снижая нагрузку на ЦП и GPU; соединение остаётся живым. Не для заставки «Затемнение».';

  @override
  String get settingWsFilterTitle => 'Фильтровать обновления панели';

  @override
  String get settingWsFilterDescription =>
      'Обрабатывать обновления только для сущностей текущего вида, снижая подёргивания на слабых планшетах. Виды, которые не удаётся разобрать, остаются без фильтра.';

  @override
  String get settingPauseDashboardCamerasTitle =>
      'Приостанавливать потоки камер на панели HA во время заставки';

  @override
  String get settingPauseDashboardCamerasDescription =>
      'Приостанавливает поддерживаемые беззвучные потоки камер на панели Home Assistant, пока заставка её закрывает. Потоки переподключаются при её закрытии. Не влияет на камеру устройства и функцию «Потоки камер».';

  @override
  String get haOptimizations => 'Оптимизации';

  @override
  String get haOptimizationsHint =>
      'Фоновое соединение, пауза панели и камер, фильтр обновлений';

  @override
  String get haScanUnavailable =>
      'Подробности сканирования недоступны для текущего вида.';

  @override
  String get haScanDetails => 'Подробности сканирования панели';

  @override
  String haWatchedTitle(String count) {
    return 'Отслеживаемые сущности ($count)';
  }

  @override
  String get haWatched => 'Отслеживаемые сущности';

  @override
  String get haEntityListUnavailable => 'Список сущностей сейчас недоступен.';

  @override
  String haWatching(String count) {
    return 'Отслеживается сущностей на этом виде: $count.';
  }

  @override
  String get haNoUpdates => 'Обновлений за последнюю минуту нет.';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return 'Отфильтровано $percent% обновлений за последнюю минуту ($dropped из $total).';
  }

  @override
  String get haRawUpdates =>
      'Что-то на этой странице и так получает каждое обновление сущностей, поэтому фильтрация здесь экономит меньше.';

  @override
  String get haAllStates =>
      'Этот вид читает все состояния сущностей, поэтому его обновления не фильтруются.';

  @override
  String get haUnknownEntities =>
      'Сущности этого вида не удаётся определить, поэтому его обновления не фильтруются.';

  @override
  String get haWaiting => 'Ожидание загрузки панели…';

  @override
  String get haShowScan => 'Показать подробности сканирования.';

  @override
  String haThreshold(String count) {
    return 'Этот вид использует сущностей: $count, что превышает порог фильтрации. Фильтрация выключена.';
  }

  @override
  String get haCustomPageFilter => 'Не используется на своих страницах.';

  @override
  String get settingHaReturnHomeEnabledTitle =>
      'Возвращаться к домашнему виду панели';

  @override
  String get settingHaReturnHomeEnabledDescription =>
      'Возвращаться к настроенной выше панели после периода бездействия.';

  @override
  String get settingHaReturnHomeSecondsTitle => 'Возврат через (с)';

  @override
  String get settingHaReturnHomeSecondsDescription =>
      'Период бездействия до возврата киоска.';

  @override
  String get haReturnHint => 'Возвращаться к домашнему виду при простое';

  @override
  String get haReturnDisabled =>
      'Выключено, пока включена ротация видов панели.';

  @override
  String get haReturnNoPath =>
      'У настроенной панели нет пути вида для возврата.';

  @override
  String haReturnPath(String path) {
    return 'Возвращается к «$path» по тайм-ауту.';
  }

  @override
  String get haReturnCompass =>
      'При навигации Compass каждый вид панели в раскладке по тайм-ауту возвращается к выбранному для него виду.';

  @override
  String get settingHaRotationEnabledTitle => 'Включить ротацию видов панели';

  @override
  String get settingHaRotationEnabledDescription =>
      'Бесконечно переключать выбранные виды панели по кругу, показывая каждый заданное число секунд.';

  @override
  String get settingHaRotationSecondsTitle => 'Секунд на вид';

  @override
  String get settingHaRotationSecondsDescription =>
      'Как долго каждый вид остаётся на экране.';

  @override
  String get settingHaRotationPauseSecondsTitle =>
      'Пауза ротации при взаимодействии (с)';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      'Касание экрана приостанавливает ротацию на это время, и каждое касание перезапускает отсчёт. Голосовое взаимодействие приостанавливает до его конца. 0: не останавливаться при касаниях.';

  @override
  String get settingHaRotationCrossfadeTitle => 'Наплыв между видами';

  @override
  String get settingHaRotationCrossfadeDescription =>
      'Затухание в фон и появление следующего вида вместо мгновенного переключения. Переход на другую панель или внешнюю страницу всё равно мгновенный.';

  @override
  String get settingHaRotationFadeSecondsTitle => 'Длительность наплыва (с)';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      'Суммарное время затухания и появления. Загрузка следующего вида может добавить времени, особенно при первом визите.';

  @override
  String get haRotation => 'Ротация видов панели';

  @override
  String get haRotationHint => 'Смена видов, время показа, наплыв';

  @override
  String get haExternalPages => 'Внешние страницы';

  @override
  String get haFadeError => 'Выберите длительность наплыва от 0,2 до 5 с.';

  @override
  String get haPauseRemoteHelp =>
      'Касание приостанавливает ротацию на это время; каждое касание перезапускает отсчёт. Голосовое взаимодействие всегда приостанавливает до конца. 0: не останавливаться.';

  @override
  String get settingHaUrlTitle => 'Базовый URL Home Assistant';

  @override
  String get settingHaUrlDescription =>
      'напр. https://homeassistant.local:8123, без пути к панели.';

  @override
  String get settingHaTokenTitle => 'Долгоживущий токен доступа';

  @override
  String get settingHaTokenDescription =>
      'Создаётся в профиле HA: Безопасность.';

  @override
  String get settingHaAutoLoginTitle => 'Входить автоматически';

  @override
  String get settingHaAutoLoginDescription =>
      'Входить в панель с токеном доступа выше вместо показа страницы входа Home Assistant.';

  @override
  String get haValidate => 'Проверить';

  @override
  String get haValidateConnection => 'Проверить соединение';

  @override
  String get haChecking => 'Проверка…';

  @override
  String get haConnected => 'Подключено';

  @override
  String get haConnectedRemote => 'Подключено.';

  @override
  String get haNotValidated =>
      'Ещё не проверено. Настройки ниже откроются после успешной проверки соединения.';

  @override
  String get haConnectFailed => 'Не удалось подключиться.';

  @override
  String get haNotConfigured => 'URL и токен Home Assistant не настроены';

  @override
  String get haInvalidToken => 'неверный токен';

  @override
  String haUnreachable(String error) {
    return 'Home Assistant недоступен: $error';
  }

  @override
  String get haProxy => 'Прокси безопасного контекста';

  @override
  String get haProxyHelp =>
      'Проводит Home Assistant с обычным http через прокси внутри приложения, чтобы браузер открыл микрофон и другие функции, доступные только по https. Только для URL http.';

  @override
  String get haProxyRemoteHelp =>
      'Проводит Home Assistant с обычным http через прокси внутри приложения, чтобы браузер открыл микрофон и другие функции, доступные только по https. Доступно только для URL http.';

  @override
  String get haProxyNotice =>
      'Этот URL Home Assistant использует обычный http, и браузеры блокируют микрофон и другие функции на страницах http. Kiosk Satellite проведёт панель через безопасный прокси внутри приложения, чтобы всё работало. Возможно, придётся снова войти в Home Assistant.';

  @override
  String get haProxyRemoteNotice =>
      'Этот URL Home Assistant использует обычный http, и браузеры блокируют микрофон и другие функции на страницах http. Kiosk Satellite проведёт панель через безопасный прокси внутри приложения, чтобы всё работало. Возможно, придётся снова войти в Home Assistant на планшете.';

  @override
  String get haDashboard => 'Панель';

  @override
  String get haChooseView => 'Выберите вид';

  @override
  String get settingHaThemeTitle => 'Тема';

  @override
  String get settingHaThemeDescription =>
      'Светлая или тёмная для панели Home Assistant; также задаётся сущностью Theme в Home Assistant. «Авто» следует настройкам ниже.';

  @override
  String get settingThemeMatchAppTitle =>
      'Синхронизировать темы Home Assistant с Kiosk Satellite';

  @override
  String get settingThemeMatchAppDescription =>
      'Автоматически подгонять тему Home Assistant под интерфейс Kiosk Satellite.';

  @override
  String get settingThemeAutoTitle => 'Менять тему по времени суток';

  @override
  String get settingThemeAutoDescription =>
      'Переключать Home Assistant между светлой и тёмной темой по расписанию. Выбранная тема сохраняется, меняется только её светлая/тёмная вариация.';

  @override
  String get settingThemeDarkAtTitle => 'Тёмная тема в';

  @override
  String get settingThemeDarkAtDescription =>
      'Местное время перехода на тёмную тему.';

  @override
  String get settingThemeLightAtTitle => 'Светлая тема в';

  @override
  String get settingThemeLightAtDescription =>
      'Местное время возврата к светлой теме.';

  @override
  String get settingThemeAutoAppTitle => 'Также менять тему приложения';

  @override
  String get settingThemeAutoAppDescription =>
      'Переключать и собственную тему Kiosk Satellite (меню, настройки) вместе с запланированным изменением Home Assistant.';

  @override
  String get haThemeHint =>
      'Синхронизация с приложением или переключение по расписанию';

  @override
  String get haThemeAuto => 'Авто';

  @override
  String get settingHaKioskModeTitle => 'Режим киоска HA';

  @override
  String get settingHaKioskModeDescription =>
      'Скрыть заголовок и боковую панель Home Assistant. Применяется сразу.';

  @override
  String get settingHaKioskHideHeaderTitle => 'Скрыть заголовок';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'Скрыть панель инструментов и вкладки видов, пока режим киоска HA включён. Оставьте выключенным, если переключаете виды из заголовка.';

  @override
  String get settingHaKioskHideSidebarTitle => 'Скрыть боковую панель';

  @override
  String get settingHaKioskHideSidebarDescription =>
      'Скрыть боковую панель навигации, пока режим киоска HA включён.';

  @override
  String get settingHaDashboardCarouselTitle => 'Включить карусель панели';

  @override
  String get settingHaDashboardCarouselDescription =>
      'Свайп влево или вправо по панели перемещает между её видами. Свайпы по ползункам, картам и прокручиваемым карточкам не трогаются.';

  @override
  String get settingHaCarouselOverCardsTitle =>
      'Перехватывать свайпы над карточками';

  @override
  String get settingHaCarouselOverCardsDescription =>
      'Переключать виды, даже когда свайп начинается на карточке, реагирующей на свайпы. Ползунки продолжают работать как обычно.';

  @override
  String get settingHaHapticsTitle => 'Включить виброотклик';

  @override
  String get settingHaHapticsDescription =>
      'Вибрировать при использовании кнопок, переключателей, карточек, ползунков и термостатных регуляторов. Требуется мотор вибрации.';

  @override
  String get settingHaHapticsStrengthTitle => 'Сила вибрации';

  @override
  String get settingHaHapticsStrengthDescription =>
      'Насколько сильной ощущается вибрация.';

  @override
  String get settingHaTapSoundTitle => 'Проигрывать звук касаний';

  @override
  String get settingHaTapSoundDescription =>
      'Проигрывать стандартный звук касания при использовании кнопок, переключателей, карточек, ползунков и термостатных регуляторов.';

  @override
  String get settingHaTapSoundVolumeTitle => 'Громкость звука касаний';

  @override
  String get settingHaTapSoundVolumeDescription =>
      'Насколько громко играет звук касания.';

  @override
  String get haUserInterface => 'Интерфейс';

  @override
  String get haInterfaceHint =>
      'Режим киоска, карусель панели, виброотклик, звук касаний';

  @override
  String get haHaptics => 'Виброотклик';

  @override
  String get haVibrationLight => 'Слабая';

  @override
  String get haVibrationMedium => 'Средняя';

  @override
  String get haVibrationStrong => 'Сильная';

  @override
  String get settingHomeLauncherEnabledTitle => 'Быть домашним экраном';

  @override
  String get settingHomeLauncherEnabledDescription =>
      'Зарегистрировать Kiosk Satellite как домашний экран устройства: киоск запускается при загрузке, и каждое нажатие «Домой» возвращает к нему. Отключается автоматически и восстанавливает прежний лаунчер, если приложение несколько раз не смогло запуститься.';

  @override
  String get settingHomeKeepPinningTitle => 'Сохранять закрепление экрана';

  @override
  String get settingHomeKeepPinningDescription =>
      'Закреплять экран, даже пока Kiosk Satellite является домашним экраном. Блокирует кнопки «Недавние» и «Назад» на уровне системы, но возвращает диалог подтверждения закрепления на устройствах без прав владельца устройства.';

  @override
  String get kioskHomeScreen => 'Домашний экран';

  @override
  String get kioskCheckingDevice => 'Проверка устройства…';

  @override
  String get kioskFireOs => 'Fire OS не позволяет заменить свой лаунчер.';

  @override
  String get kioskUnsupported =>
      'Это устройство не позволяет менять домашний экран.';

  @override
  String get kioskRecovered =>
      'Выключено автоматически после повторных неудачных запусков; прежний лаунчер восстановлен. Включите переключатель снова, чтобы попробовать ещё раз.';

  @override
  String get kioskHeld =>
      'Kiosk Satellite является домашним экраном. Киоск запускается при загрузке, и каждое нажатие «Домой» возвращает к нему.';

  @override
  String get kioskDisabled =>
      'Не домашний экран. Включите «Быть домашним экраном» выше.';

  @override
  String get kioskWaiting =>
      'Ещё не текущий домашний экран: устройство ждёт подтверждения.';

  @override
  String get kioskOpenHomeSettings => 'Открыть настройки домашнего экрана';

  @override
  String get kioskSetDefault => 'Сделать по умолчанию';

  @override
  String get kioskActive => 'Активно';

  @override
  String get kioskNotHome => 'Не домашний экран.';

  @override
  String get kioskWaitingRemote =>
      'Ожидание подтверждения на устройстве: системный диалог или настройки домашнего экрана открываются там.';

  @override
  String get kioskSetDevice => 'Задать на устройстве';

  @override
  String get settingIntercomAnswerModeTitle => 'Режим ответа';

  @override
  String get settingIntercomAnswerModeDescription =>
      '«Звонок» спрашивает на экране. «Отвечать автоматически» открывает звонок после сигнала.';

  @override
  String get settingIntercomRingSecondsTitle => 'Звонить в течение';

  @override
  String get settingIntercomRingSecondsDescription =>
      'Как долго звонит вызов, прежде чем считается пропущенным.';

  @override
  String get settingIntercomRingSoundTitle => 'Звук звонка';

  @override
  String get settingIntercomRingSoundVolumeDescription =>
      'Проигрывается на громкости звонка.';

  @override
  String get settingIntercomRingVolumeTitle => 'Громкость звонка';

  @override
  String get settingIntercomRingVolumeDescription =>
      'Насколько громко звонит вызов, отдельно от громкости медиа.';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => 'Принимать объявления';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      'Проигрывать «Объявить всем» с других киосков.';

  @override
  String get intercomOptionAnswerRing => 'Звонок';

  @override
  String get intercomOptionAnswerAuto => 'Отвечать автоматически';

  @override
  String get intercomOptionAnswerDnd => 'Не беспокоить';

  @override
  String get intercomOptionAnswer15 => '15 секунд';

  @override
  String get intercomOptionAnswer30 => '30 секунд';

  @override
  String get intercomOptionAnswer45 => '45 секунд';

  @override
  String get intercomOptionAnswer60 => '60 секунд';

  @override
  String get intercomAnswerSection => 'Ответ';

  @override
  String get settingIntercomEnabledTitle => 'Включить интерком';

  @override
  String get settingIntercomEnabledDescription =>
      'Звоните другим киоскам в этой сети и принимайте их звонки.';

  @override
  String get settingIntercomKeyTitle => 'Ключ интеркома';

  @override
  String get settingIntercomKeyDescription =>
      'Киоски с одним ключом могут звонить друг другу. Управление группой киосков может его синхронизировать.';

  @override
  String get settingIntercomKeyPlaceholder =>
      'Создаётся при включении интеркома';

  @override
  String get intercomNeedsAdmin =>
      'Интеркому нужно удалённое администрирование';

  @override
  String get intercomAdminHelp =>
      'Через него киоски находят друг друга и связываются. Включите «Удалённое управление» и «Поиск других киосков» в разделе «Устройство», затем вернитесь.';

  @override
  String get intercomChangeKey => 'Изменить ключ';

  @override
  String get intercomChangeKeyHelp =>
      'Вставьте ключ с другого киоска или создайте новый.';

  @override
  String get intercomChange => 'Изменить';

  @override
  String get intercomKeyWarning =>
      'Киоски с этим ключом могут звонить друг другу. Новый ключ отключает этот киоск от остальных, пока он не появится и у них.';

  @override
  String get intercomRegenerate => 'Пересоздать';

  @override
  String get intercomKeyChanged => 'Ключ изменён';

  @override
  String get intercomNotSet => 'Не задан';

  @override
  String get intercomOpen => 'Открыть';

  @override
  String get settingIntercomTlsTitle => 'Шифровать связь';

  @override
  String get settingIntercomTlsDescription =>
      'Использовать TLS для шифрования звонков интеркома между киосками. У всех киосков в звонке это должно быть включено.';

  @override
  String get intercomKiosks => 'Киоски';

  @override
  String get intercomRosterHelp =>
      'Найденные киоски и сохранённые участники группы. Киоск готов, когда он доступен, с включённым интеркомом, тем же ключом и совпадающими настройками шифрования.';

  @override
  String get intercomNoOther => 'Другие киоски не найдены';

  @override
  String get intercomRosterDeviceHelp =>
      'Здесь появляются киоски с включёнными «Удалённым управлением» и «Поиском других киосков».';

  @override
  String get intercomNoneHeard => 'Киоски не найдены';

  @override
  String get intercomRosterRemoteHelp =>
      'Киоски появляются через обнаружение в сети или сохранённое участие в группе. «Удалённое управление» и «Поиск других киосков» должны быть включены.';

  @override
  String get intercomReady => 'Готов';

  @override
  String get intercomOff => 'Интерком выключен';

  @override
  String get intercomDifferentKey => 'Другой ключ';

  @override
  String get intercomUnreachable => 'Недоступен';

  @override
  String get intercomOffline => 'Не в сети';

  @override
  String get intercomChecking => 'Проверка…';

  @override
  String get settingIntercomTalkModeTitle => 'Режим разговора';

  @override
  String get settingIntercomTalkModeDescription =>
      '«Нажать и говорить» передаёт звук, пока кнопка удерживается. «Громкая связь» держит микрофон открытым весь звонок.';

  @override
  String get intercomOptionTalkPtt => 'Нажать и говорить';

  @override
  String get intercomOptionTalkHandsfree => 'Громкая связь';

  @override
  String get settingIntercomMaxCallMinutesTitle =>
      'Максимальная длительность звонка';

  @override
  String get settingIntercomMaxCallMinutesDescription =>
      'Звонки завершаются сами по прошествии этого времени.';

  @override
  String get intercomOptionCallUnlimited => 'Без ограничения';

  @override
  String get intercomOptionCall1 => '1 минута';

  @override
  String get intercomOptionCall2 => '2 минуты';

  @override
  String get intercomOptionCall5 => '5 минут';

  @override
  String get intercomOptionCall10 => '10 минут';

  @override
  String get intercomOptionCall15 => '15 минут';

  @override
  String get intercomOptionCall20 => '20 минут';

  @override
  String get intercomOptionCall30 => '30 минут';

  @override
  String get intercomOptionCall45 => '45 минут';

  @override
  String get intercomOptionCall60 => '60 минут';

  @override
  String get settingIntercomHangupKeyTitle => 'Завершать звонок этой кнопкой';

  @override
  String get settingIntercomHangupKeyDescription =>
      'Во время звонка кнопка завершает его вместо обычного действия.';

  @override
  String get intercomOptionHangupOff => 'Выключено';

  @override
  String get intercomOptionHangupVolumeUp => 'Громче';

  @override
  String get intercomOptionHangupVolumeDown => 'Тише';

  @override
  String get intercomOptionHangupMute => 'Выключение звука';

  @override
  String get intercomOptionHangupHelp => 'Справка';

  @override
  String get settingIntercomHangupKeyRingingTitle =>
      'Кнопка завершения при входящем звонке';

  @override
  String get settingIntercomHangupKeyRingingDescription =>
      'Что делает кнопка, когда сюда поступает звонок.';

  @override
  String get intercomOptionHangupRingingAnswer => 'Принять';

  @override
  String get intercomOptionHangupRingingDecline => 'Отклонить';

  @override
  String get intercomOptionHangupRingingIgnore => 'Игнорировать';

  @override
  String get intercomTalkSection => 'Разговор';

  @override
  String get settingIntercomVideoTitle => 'Видеозвонки';

  @override
  String get settingIntercomVideoDescription =>
      'Отправляет и показывает видео во время звонков.';

  @override
  String get settingIntercomVideoQualityTitle => 'Качество видео';

  @override
  String get settingIntercomVideoQualityDescription =>
      'Более высокое качество сильнее нагружает процессор.';

  @override
  String get intercomOptionVideoLow => 'Низкое';

  @override
  String get intercomOptionVideoMedium => 'Среднее';

  @override
  String get intercomOptionVideoHigh => 'Высокое';

  @override
  String get intercomVideoSection => 'Видео';

  @override
  String get settingIntercomAutoAnswerCameraTitle =>
      'Отвечать с включенной камерой';

  @override
  String get settingIntercomAutoAnswerCameraDescription =>
      'Видеозвонки с автоответом открываются с включенной камерой.';

  @override
  String get settingKioskAllowDrawerTitle => 'Разрешить меню быстрых действий';

  @override
  String get settingKioskAllowQuickControlsDescription =>
      'Показывает меню без жеста выхода или PIN, ограниченное действиями, выбранными ниже. В классической навигации его открывает свайп от края. В Compass это вид «Быстрые действия».';

  @override
  String get settingKioskAllowDashboardTitle => 'Панель';

  @override
  String get settingKioskAllowDashboardDescription =>
      'Перезагрузить стартовую страницу.';

  @override
  String get settingKioskAllowHaKioskTitle => 'Режим киоска HA';

  @override
  String get settingKioskAllowHaKioskDescription =>
      'Показать или скрыть заголовок и боковую панель Home Assistant.';

  @override
  String get settingKioskAllowCameraTitle => 'Вид камер';

  @override
  String get settingKioskAllowCameraDescription =>
      'Открыть вид камер по умолчанию.';

  @override
  String get settingKioskAllowIntercomTitle => 'Интерком';

  @override
  String get settingKioskAllowIntercomDescription =>
      'Позвонить другим киоскам из меню киоска.';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription =>
      'Открыть веб-интерфейс Music Assistant.';

  @override
  String get settingKioskAllowSendspinPlayerTitle => 'Плавающий плеер';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      'Показать или скрыть плавающий плеер и открыть «Сейчас играет».';

  @override
  String get settingKioskAllowScreensaverTitle => 'Запустить заставку';

  @override
  String get settingKioskAllowScreensaverDescription =>
      'Запустить заставку сейчас.';

  @override
  String get settingKioskAllowHoldTitle => 'Режим удержания';

  @override
  String get settingKioskAllowHoldDescription =>
      'Включить или выключить режим удержания.';

  @override
  String get settingKioskAllowLockdownTitle => 'Режим блокировки';

  @override
  String get settingKioskAllowLockdownDescription =>
      'Заблокировать экран до жеста выхода или удалённой разблокировки.';

  @override
  String get settingKioskAllowThemeTitle => 'Выбор темы';

  @override
  String get settingKioskAllowThemeDescription =>
      'Переключать светлую и тёмную темы.';

  @override
  String get settingKioskAllowAppsTitle => 'Приложения';

  @override
  String get settingKioskAllowAppsDescription =>
      'Открыть лаунчер приложений. При включённом «Отключить кнопку Домой» запуск приложения снимает закрепление киоска до его возврата.';

  @override
  String get kioskAllowedActions => 'Разрешённые действия';

  @override
  String get kioskAllowedHelp =>
      'Какие быстрые действия предлагает меню киоска';

  @override
  String get settingKioskAllowedAppsTitle => 'Разрешённые приложения';

  @override
  String get settingKioskAllowedAppsDescription =>
      'Приложения лаунчера, доступные при включённом режиме киоска.';

  @override
  String get kioskAllowedAppsEmpty =>
      'Сначала добавьте приложения в «Настройки > Лаунчер приложений».';

  @override
  String get settingKioskEnabledTitle => 'Включить режим киоска';

  @override
  String get settingKioskEnabledDescription =>
      'Заблокировать планшет в Kiosk Satellite. Свайп меню заменяется жестом выхода, кнопка «Назад» остаётся внутри киоска, защиты ниже активируются.';

  @override
  String get settingKioskStartOnBootTitle => 'Запускать при загрузке';

  @override
  String get settingKioskStartOnBootDescription =>
      'Запускать Kiosk Satellite при включении устройства. На Android 10+ нужно разрешение «Поверх других приложений»; Android спросит при первом включении.';

  @override
  String get settingKioskExitGestureTitle => 'Жест выхода из киоска';

  @override
  String get settingKioskExitGestureDescription =>
      'Быстрые нажатия где угодно открывают меню, после PIN, если он задан. Варианты с удержанием требуют удержания последнего нажатия. Если выключено, до настроек доберётся только удалённое администрирование.';

  @override
  String get settingKioskPinTitle => 'PIN режима киоска';

  @override
  String get settingKioskPinDescription =>
      'Запрашивается после жеста выхода перед открытием меню. Оставьте пустым, чтобы обойтись без PIN.';

  @override
  String get settingKioskDisableStatusBarTitle => 'Отключить строку состояния';

  @override
  String get settingKioskDisableStatusBarDescription =>
      'Блокировать выдвижение строки состояния щитом над верхним краем. Нужно разрешение «Поверх других приложений»; Android спросит при первом включении.';

  @override
  String get settingKioskDisableVolumeTitle => 'Отключить кнопки громкости';

  @override
  String get settingKioskDisableVolumeDescription =>
      'Поглощать аппаратные кнопки громкости.';

  @override
  String get settingKioskDisablePowerTitle => 'Отключить кнопку питания';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android не может заблокировать кнопку питания, поэтому экран сразу включается снова при нажатии. Удалённое выключение экрана продолжает работать.';

  @override
  String get settingKioskDisableHomeTitle => 'Отключить кнопку «Домой»';

  @override
  String get settingKioskDisableHomeDescription =>
      'Закрепить приложение закреплением экрана Android, блокирующим кнопки «Домой» и «Недавние». Android спросит подтверждение в первый раз.';

  @override
  String get settingKioskDisableContextMenusTitle =>
      'Отключить контекстные меню';

  @override
  String get settingKioskDisableContextMenusDescription =>
      'Подавлять меню долгого нажатия и выделение текста внутри веб-просмотра.';

  @override
  String get settingKioskDisablePullRefreshTitle =>
      'Отключить «Потяните для обновления»';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Игнорировать жест «Потяните для обновления», пока режим киоска включён.';

  @override
  String get settingKioskDisableGesturesTitle => 'Отключить жесты';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Игнорировать жесты со страницы «Жесты», пока режим киоска включён.';

  @override
  String get kioskGestureTaps5 => '5 быстрых нажатий';

  @override
  String get kioskGestureTaps7 => '7 быстрых нажатий';

  @override
  String get kioskGestureTaps5Hold =>
      '5 быстрых нажатий с удержанием последнего';

  @override
  String get kioskGestureTaps7Hold =>
      '7 быстрых нажатий с удержанием последнего';

  @override
  String get kioskGestureNone =>
      'Выключено (только удалённое администрирование)';

  @override
  String get kioskForeground =>
      'Kiosk Satellite может возвращаться на передний план.';

  @override
  String get kioskOverlayMissing =>
      'Без этого киоск не может вернуться сам, а щит блокировки покрывает только приложение.';

  @override
  String get kioskGuardHeld =>
      'Шторка уведомлений и список недавних приложений закрываются сами, пока экран защищён.';

  @override
  String get kioskGuardMissing =>
      'Без этого шторка уведомлений и список недавних приложений остаются доступными. Включите Kiosk Satellite в разделе «Специальные возможности».';

  @override
  String get kioskOverlayRemote =>
      'Без этого киоск не может вернуться сам. Экран выдачи разрешения появится на планшете.';

  @override
  String get kioskGuardRemote =>
      'Без этого шторка уведомлений и список недавних приложений остаются доступными. Включите Kiosk Satellite в разделе «Специальные возможности» на планшете.';

  @override
  String get kioskGrantDevice => 'Предоставить на устройстве';

  @override
  String get kioskOpenSettingsDevice => 'Открыть настройки на устройстве';

  @override
  String get settingLedEnabledTitle => 'Включить управление LED';

  @override
  String get settingLedEnabledDescription =>
      'Позволяет Kiosk Satellite управлять индикаторами.';

  @override
  String get settingLedAnimationsTitle => 'Анимировать эффекты';

  @override
  String get settingLedAnimationsDescription =>
      'Вращает дуги и плавно меняет пульсации. Выключите, чтобы все эффекты стали статичными.';

  @override
  String get settingLedIdleEnabledTitle => 'Светиться в покое';

  @override
  String get settingLedIdleEnabledDescription =>
      'Светится, пока ничего другого не показано.';

  @override
  String get settingLedIdleBrightnessTitle => 'Яркость';

  @override
  String get settingLedIdleBrightnessDescription =>
      'Насколько ярко светятся индикаторы для этого.';

  @override
  String get settingLedIdleLightColorTitle => 'Цвет';

  @override
  String get settingLedIdleLightColorDescription =>
      'Цвет индикаторов для этого.';

  @override
  String get settingLedIdleStyleTitle => 'Эффект';

  @override
  String get settingLedIdleStyleDescription =>
      'Как выглядят индикаторы в покое.';

  @override
  String get settingLedIdleStyleOptionSolid => 'Постоянно';

  @override
  String get settingLedIdleStyleOptionBreathe => 'Дыхание';

  @override
  String get settingLedVoiceEnabledTitle => 'Показывать голосовую активность';

  @override
  String get settingLedVoiceEnabledDescription =>
      'Светится, пока Voice Satellite слушает, думает и отвечает.';

  @override
  String get settingLedVoiceBrightnessTitle => 'Яркость';

  @override
  String get settingLedVoiceBrightnessDescription =>
      'Насколько ярко светятся индикаторы для этого.';

  @override
  String get settingLedVoiceLightColorTitle => 'Цвет';

  @override
  String get settingLedVoiceLightColorDescription =>
      'Под дугой, которая вращается при прослушивании, чередуется при обдумывании и переливается при ответе.';

  @override
  String get settingLedVoiceAccentColorTitle => 'Акцентный цвет';

  @override
  String get settingLedVoiceAccentColorDescription =>
      'Дуга, которая движется вокруг индикаторов.';

  @override
  String get settingLedVoiceMutedTitle => 'Показывать при выключенном звуке';

  @override
  String get settingLedVoiceMutedDescription =>
      'Светится, пока звук Voice Satellite выключен.';

  @override
  String get settingLedVoiceMutedColorTitle => 'Цвет при выключенном звуке';

  @override
  String get settingLedVoiceMutedColorDescription =>
      'Цвет индикаторов при выключенном звуке.';

  @override
  String get settingLedTimersEnabledTitle => 'Показывать таймеры';

  @override
  String get settingLedTimersEnabledDescription =>
      'Пульсирует, пока звонит таймер.';

  @override
  String get settingLedTimersBrightnessTitle => 'Яркость';

  @override
  String get settingLedTimersBrightnessDescription =>
      'Насколько ярко светятся индикаторы для этого.';

  @override
  String get settingLedTimersLightColorTitle => 'Цвет';

  @override
  String get settingLedTimersLightColorDescription =>
      'Цвет индикаторов для этого.';

  @override
  String get settingLedTimersCountdownTitle => 'Показывать обратный отсчёт';

  @override
  String get settingLedTimersCountdownDescription =>
      'Индикаторы гаснут один за другим, пока истекает ближайший таймер.';

  @override
  String get settingLedAlarmsEnabledTitle => 'Показывать будильники';

  @override
  String get settingLedAlarmsEnabledDescription =>
      'Пульсирует, пока звонит будильник.';

  @override
  String get settingLedAlarmsBrightnessTitle => 'Яркость';

  @override
  String get settingLedAlarmsBrightnessDescription =>
      'Насколько ярко светятся индикаторы для этого.';

  @override
  String get settingLedAlarmsLightColorTitle => 'Цвет';

  @override
  String get settingLedAlarmsLightColorDescription =>
      'Цвет индикаторов для этого.';

  @override
  String get settingLedIntercomEnabledTitle => 'Показывать звонки интеркома';

  @override
  String get settingLedIntercomEnabledDescription =>
      'Пульсирует, пока звонит вызов, и вращается, пока он идёт.';

  @override
  String get settingLedIntercomBrightnessTitle => 'Яркость';

  @override
  String get settingLedIntercomBrightnessDescription =>
      'Насколько ярко светятся индикаторы для этого.';

  @override
  String get settingLedIntercomLightColorTitle => 'Цвет';

  @override
  String get settingLedIntercomLightColorDescription =>
      'Цвет индикаторов для этого.';

  @override
  String get settingLedNotificationsEnabledTitle => 'Показывать уведомления';

  @override
  String get settingLedNotificationsEnabledDescription =>
      'Медленно пульсирует, пока ждёт уведомление.';

  @override
  String get settingLedNotificationsBrightnessTitle => 'Яркость';

  @override
  String get settingLedNotificationsBrightnessDescription =>
      'Насколько ярко светятся индикаторы для этого.';

  @override
  String get settingLedNotificationsLightColorTitle => 'Цвет';

  @override
  String get settingLedNotificationsLightColorDescription =>
      'Цвет индикаторов для этого.';

  @override
  String get settingLedMediaEnabledTitle => 'Показывать музыку';

  @override
  String get settingLedMediaEnabledDescription =>
      'Светится, пока на этом устройстве играет музыка.';

  @override
  String get settingLedMediaBrightnessTitle => 'Яркость';

  @override
  String get settingLedMediaBrightnessDescription =>
      'Насколько ярко светятся индикаторы для этого.';

  @override
  String get settingLedMediaLightColorTitle => 'Цвет';

  @override
  String get settingLedMediaLightColorDescription =>
      'Цвет индикаторов для этого.';

  @override
  String get settingLedMediaStyleTitle => 'Эффект';

  @override
  String get settingLedMediaStyleDescription =>
      'Как индикаторы показывают музыку.';

  @override
  String get settingLedMediaStyleOptionSolid => 'Постоянно';

  @override
  String get settingLedMediaStyleOptionBreathe => 'Дыхание';

  @override
  String get settingLockdownEnabledTitle => 'Включить режим блокировки';

  @override
  String get settingLockdownEnabledDescription =>
      'Отключает взаимодействие с экраном до выключения из Home Assistant или жестом выхода.';

  @override
  String get settingLockdownAutoUnlockMinutesTitle =>
      'Автоматически разблокировать через';

  @override
  String get settingLockdownAutoUnlockMinutesDescription =>
      'Выключает режим блокировки через это время, если он включён из меню киоска. Установите 0, чтобы блокировка сохранялась.';

  @override
  String get settingLockdownBlackoutTitle => 'Гасить экран';

  @override
  String get settingLockdownBlackoutDescription =>
      'Делает экран чёрным во время блокировки.';

  @override
  String get settingLockdownAllowScreensaverTitle => 'Разрешить заставку';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      'Позволяет заставке работать во время блокировки. «Прятать при движении» остаётся выключенным до снятия блокировки.';

  @override
  String get settingLockdownExitGestureTitle => 'Жест выхода из блокировки';

  @override
  String get settingLockdownExitGestureDescription =>
      'Быстрые нажатия где угодно выключают режим блокировки, после PIN киоска, если он задан. Варианты с удержанием требуют удержания последнего нажатия. Если выключено, выключить сможет только удалённое администрирование или Home Assistant.';

  @override
  String get lockdownGestureNone => 'Выключено (только удалённо)';

  @override
  String get lockdownExplanation =>
      'Режим блокировки делает панель неинтерактивной, активирует все защиты режима киоска, не меняя его настройки, и отключает определение слова пробуждения, пока он включён. С включённой защитой системного интерфейса (выше) блокируются и шторка уведомлений, и список недавних приложений. Home Assistant получает переключатель Lockdown mode через ESPHome.';

  @override
  String get lockdownSearch =>
      'Щит от касаний, настраиваемый только удалённо. Настраивается из интерфейса удалённого администрирования; его разрешения находятся в разделе «Необходимые системные разрешения».';

  @override
  String get lockdownOverlayHeld => 'Щит блокировки может покрыть весь экран.';

  @override
  String get lockdownOverlayMissing =>
      'Без этого щит покрывает только приложение. Экран выдачи разрешения появится на планшете.';

  @override
  String get lockdownPermissionsSearch =>
      'Разрешения, на которые опираются защиты блокировки.';

  @override
  String get settingAirplayEnabledTitle => 'Включить приёмник AirPlay';

  @override
  String get settingAirplayEnabledDescription =>
      'Устройство появляется как колонка AirPlay в меню AirPlay на iPhone, iPad или Mac.';

  @override
  String get settingAirplayNameTitle => 'Имя колонки';

  @override
  String get settingAirplayNameDescription =>
      'Имя в меню AirPlay. Если пусто, используется имя устройства.';

  @override
  String get settingAirplaySenderVolumeTitle =>
      'Следовать громкости отправителя';

  @override
  String get settingAirplaySenderVolumeDescription =>
      'Регулятор громкости на iPhone, iPad или Mac меняет громкость этого устройства. Если выключено, действует только громкость этого устройства.';

  @override
  String get settingAirplaySyncOffsetDescription =>
      'Отрицательное значение заставляет это устройство играть раньше, чтобы звук совпадал с видео на отправителе. Применяется сразу.';

  @override
  String get settingAirplayTakeoverTitle =>
      'Разрешить другому отправителю перехват';

  @override
  String get settingAirplayTakeoverDescription =>
      'Другой iPhone, iPad или Mac может перехватить воспроизведение, пока играет первый. Если выключено, ему придётся ждать, пока первый не отключится.';

  @override
  String get mediaAirplayHint => 'Воспроизведение звука с iPhone, iPad или Mac';

  @override
  String get mediaCacheTitle => 'Кэш обложек';

  @override
  String get mediaCacheReadFailed => 'Не удалось прочитать размер кэша.';

  @override
  String get mediaCacheClearFailed => 'Не удалось очистить кэш.';

  @override
  String get mediaCacheChecking => 'Проверка размера кэша…';

  @override
  String get mediaCacheClearing => 'Очистка…';

  @override
  String mediaCacheUsage(String used, String limit) {
    return 'Использовано $used из $limit. Миниатюры очереди кэшируются автоматически.';
  }

  @override
  String get settingSendspinShowPlayerTitle => 'Показывать плавающий плеер';

  @override
  String get settingSendspinShowPlayerDescription =>
      'Пока играет музыка, показывать маленькое окно «сейчас играет» поверх панели с обложкой, треком и прогрессом. Перетащите его куда угодно; позиция запоминается.';

  @override
  String get settingSendspinPlayerSizeTitle => 'Размер плеера';

  @override
  String get settingSendspinPlayerSizeDescription =>
      '«Компактный»: маленькое ненавязчивое окно. «Большой с кнопками» добавляет кнопки «предыдущий», «воспроизведение/пауза» и «следующий» крупного, удобного для касания размера, управляя всей группой воспроизведения.';

  @override
  String get settingSendspinPausedHideMinutesTitle =>
      'Скрывать приостановленный плеер через';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      'Как долго приостановленный плеер остаётся на экране. Относится и к плавающему плееру, и к виду «Сейчас играет».';

  @override
  String get settingSendspinDismissKeepsPlayingTitle =>
      'Продолжать воспроизведение при скрытии';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      'Если смахнуть плавающий плеер, он скроется, а музыка продолжит играть.';

  @override
  String get mediaFloatingPage => 'Плавающий плеер';

  @override
  String get mediaFloatingHint => 'Маленькая карточка поверх панели';

  @override
  String get mediaCompact => 'Компактный';

  @override
  String get mediaLargeControls => 'Большой с кнопками';

  @override
  String get settingSendspinPlayerSourceTitle => 'Источник плеера';

  @override
  String get settingSendspinPlayerSourceDescription =>
      'Что показывают и чем управляют плавающий плеер и «Сейчас играет»: это устройство или плеер в другом месте.';

  @override
  String get settingSendspinPlayerTitle => 'Плеер';

  @override
  String get settingSendspinPlayerDescription =>
      'Плеер этого источника для показа и управления.';

  @override
  String get settingSendspinDuckPercentTitle =>
      'Приглушать при голосовом взаимодействии';

  @override
  String get settingSendspinDuckPercentDescription =>
      'Музыка опускается до этой доли громкости при голосовом взаимодействии и звонках интеркома, затем возвращается.';

  @override
  String get settingSendspinEsphomeEntitiesTitle =>
      'Предоставить сущности ESPHome';

  @override
  String get settingSendspinEsphomeEntitiesDescription =>
      'Кнопки «воспроизвести», «пауза», «следующий» и «предыдущий» для отслеживаемого плеера в Home Assistant, с его состоянием, названием, исполнителем и источником как датчиками.';

  @override
  String get settingSendspinVolumeKeysTitle =>
      'Кнопки громкости управляют плеером';

  @override
  String get settingSendspinVolumeKeysGroupDescription =>
      'Кнопки громкости этого устройства меняют громкость отслеживаемого плеера вместо собственной. Пока это устройство играет в группе, они меняют громкость группы. Только пока вид «Сейчас играет» на экране или пока плеер воспроизводит.';

  @override
  String get settingSendspinVolumeKeyStepTitle => 'Шаг кнопки громкости';

  @override
  String get settingSendspinVolumeKeyStepDescription =>
      'Насколько одно нажатие кнопки громкости меняет громкость плеера.';

  @override
  String get mediaIntro =>
      'Плавающий плеер и «Сейчас играет» показываются, только пока у выбранного плеера идёт трек или загружена очередь. Без воспроизведения и очереди их нет.';

  @override
  String get mediaThisDevice => 'Это устройство';

  @override
  String get mediaOff => 'Выключено';

  @override
  String get mediaKeysNowPlaying => 'Пока показан «Сейчас играет»';

  @override
  String get mediaKeysPlaying => 'Пока плеер воспроизводит';

  @override
  String get mediaAnotherPlayer => 'другой плеер';

  @override
  String mediaOfflineSendspin(String player) {
    return 'Плеер Sendspin остаётся не в сети, пока выбран $player.';
  }

  @override
  String mediaOfflineAirplay(String player) {
    return 'Приёмник AirPlay остаётся выключенным, пока выбран $player.';
  }

  @override
  String mediaOfflineBoth(String player) {
    return 'Плеер Sendspin и приёмник AirPlay остаются не в сети, пока выбран $player.';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => 'Включить текст песни';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      'Синхронизированный текст на виде «Сейчас играет» для любого источника плеера.';

  @override
  String get settingSendspinLyricsSourceTitle => 'Источник текста';

  @override
  String get settingSendspinLyricsSourceDescription =>
      'Откуда берётся текст. Для Music Assistant нужны адрес сервера и токен на его странице.';

  @override
  String get settingSendspinLyricsFallbackTitle =>
      'Запасной вариант: Music Assistant';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      'Если LRCLIB недоступен, спрашивается Music Assistant. Нужно соединение с Music Assistant.';

  @override
  String get settingSendspinLyricsOffsetTitle => 'Тайминг текста';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      'Сдвигает текст относительно музыки. Положительный сдвиг показывает каждую строку раньше, отрицательный позже. Стоит подправить на треках, где текст стабильно сбит.';

  @override
  String get mediaLyricsPage => 'Текст песни';

  @override
  String get mediaLyricsHint =>
      'Синхронизированный текст, его источник и тайминг';

  @override
  String get settingSendspinMaUrlTitle => 'Адрес сервера';

  @override
  String get settingSendspinMaUrlDescription =>
      'Адрес сервера Music Assistant, как его показывает веб-интерфейс. Обычно https и порт 8095.';

  @override
  String get settingSendspinMaTokenTitle => 'Токен авторизации';

  @override
  String get settingSendspinMaTokenDescription =>
      'Долгоживущий токен из Music Assistant (Настройки, затем Пользователи). Для текста песни достаточно чтения; пункт меню киоска открывает веб-интерфейс от имени владельца токена.';

  @override
  String get settingSendspinMaOpenFullscreenTitle =>
      'Открывать сразу «Сейчас играет»';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      'Открывать полноэкранный плеер Music Assistant из меню киоска или жестом «Открыть Music Assistant».';

  @override
  String get settingSendspinMaAutoCloseTitle => 'Закрывать после бездействия';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Возвращаться к панели, когда страницу Music Assistant никто не трогает это время. Ноль: держать открытой до закрытия.';

  @override
  String get settingSendspinMaHideCloseTitle => 'Скрыть кнопку закрытия';

  @override
  String get settingSendspinMaHideCloseDescription =>
      'Плавающая кнопка закрытия может попадать на собственные элементы Music Assistant, например меню «Сейчас играет». Без неё закрывайте кнопкой «Назад» или через меню киоска.';

  @override
  String get settingSendspinMaZoomDescription =>
      'Масштабирует всю страницу Music Assistant.';

  @override
  String get mediaMaHint => 'Сервер, токен, пункт меню киоска';

  @override
  String get mediaKioskMenu => 'Меню киоска';

  @override
  String get mediaValidateConnection => 'Проверить соединение';

  @override
  String get mediaValidate => 'Проверить';

  @override
  String get mediaChecking => 'Проверка…';

  @override
  String get mediaConnected => 'Подключено';

  @override
  String mediaConnectedVersion(String version) {
    return 'Подключено к Music Assistant $version';
  }

  @override
  String get mediaValidateHint =>
      'Проверьте адрес и токен перед включением пункта меню или текста песни.';

  @override
  String get mediaDeviceNoAnswer => 'Устройство не ответило.';

  @override
  String get mediaValidationFailed => 'Проверка не удалась.';

  @override
  String get mediaNoAddress => 'Адрес сервера не задан.';

  @override
  String get mediaNoToken => 'Токен авторизации не задан.';

  @override
  String get mediaTimeout => 'Music Assistant не ответил вовремя.';

  @override
  String mediaUnreachable(String host, String error) {
    return 'Не удалось достучаться до $host: $error';
  }

  @override
  String get mediaServerClosed => 'сервер закрыл соединение';

  @override
  String get settingSendspinFullscreenControlsTitle =>
      'Показывать кнопки управления';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      'Кнопки «предыдущий», «воспроизведение/пауза», «следующий» и полоса прогресса на виде «Сейчас играет». С ними кнопка закрытия убирает вид вместо касания где угодно.';

  @override
  String get settingSendspinFullscreenTextScaleTitle => 'Масштаб текста';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      'Размер названия трека, исполнителя, альбома, текста песни и очереди. Применяется в обеих раскладках и рядом с заставкой. Обложка подстраивается, оставляя место тексту.';

  @override
  String get settingSendspinFullscreenButtonScaleTitle => 'Масштаб кнопок';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      'Размер кнопок воспроизведения и полосы прогресса, независимо от текста. Применяется в обеих раскладках и рядом с заставкой. Кнопки вписываются в доступное место плеера.';

  @override
  String get settingSendspinFullscreenLayoutTitle => 'Режим макета';

  @override
  String get settingSendspinFullscreenLayoutDescription =>
      'Как «Сейчас играет» располагает обложку, детали трека и управление. Горизонтальный делит их на левую и правую половины. Только обложка заполняет экран обложкой и показывает детали трека и управление на несколько секунд после касания, а с открытым текстом песни или очередью переключается на Вертикальный. Игнорируется, пока «Сейчас играет» показан рядом с заставкой.';

  @override
  String get mediaLayoutVertical => 'Вертикальный';

  @override
  String get mediaLayoutHorizontal => 'Горизонтальный';

  @override
  String get mediaLayoutArtOnly => 'Только обложка';

  @override
  String get settingSendspinFullscreenDoubleTapTitle =>
      'Двойное касание для закрытия';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'Двойное касание где угодно на виде «Сейчас играет» закрывает его. Кнопка закрытия не показывается. Игнорируется, пока «Сейчас играет» показан рядом с заставкой.';

  @override
  String get settingSendspinFullscreenCloseButtonTitle =>
      'Всегда показывать кнопку закрытия';

  @override
  String get settingSendspinFullscreenCloseButtonDescription =>
      'Показывает кнопку закрытия, даже когда «Двойное касание для закрытия» включено.';

  @override
  String get settingSendspinFullscreenOnPlayTitle =>
      'Открывать «Сейчас играет» при старте музыки';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      'Открывать вид «Сейчас играет» сразу при старте воспроизведения, не дожидаясь тайм-аута заставки.';

  @override
  String get settingSendspinFullscreenMotionTitle =>
      'Прятать «Сейчас играет» при движении';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      'Позволить движению закрыть «Сейчас играет» как обычную заставку. Выключено: закрывает только касание, и проход мимо не прерывает показ музыки. Игнорируется рядом с заставкой.';

  @override
  String get settingSendspinFullscreenReturnTitle => 'После закрытия';

  @override
  String get settingSendspinFullscreenReturnDescription =>
      'Вид панели, который откроется после закрытия «Сейчас играет». «По умолчанию» следует настройке «Возвращаться к домашнему виду панели».';

  @override
  String get mediaReturnLastView => 'Последний вид';

  @override
  String get mediaReturnChosenView => 'Выбранный вид';

  @override
  String get settingSendspinFullscreenReturnViewTitle => 'Вид панели';

  @override
  String get settingSendspinFullscreenReturnViewDescription =>
      'Вид, который откроется после закрытия «Сейчас играет».';

  @override
  String get settingSendspinSpeakerPillTitle =>
      'Показывать бейдж выбора динамиков';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Показывает выбор динамиков на 5 секунд после касания экрана. Добавляйте или убирайте динамики из текущей группы.';

  @override
  String get settingSendspinSpeakerPillPlayersTitle =>
      'Фильтр бейджа выбора динамиков';

  @override
  String get settingSendspinSpeakerPillPlayersDescription =>
      'В бейдже показываются только эти динамики. Динамики, которые уже в группе, показываются всегда.';

  @override
  String get settingSendspinAudioQualityTitle => 'Показывать качество звука';

  @override
  String get settingSendspinAudioQualityDescription =>
      'Показывает формат, разрядность, частоту дискретизации, битрейт и источник текущего трека внизу вида «Сейчас играет». Требуется Music Assistant.';

  @override
  String get mediaAllSpeakers => 'Все динамики';

  @override
  String get settingSendspinQueueArtTitle => 'Показывать обложки в очереди';

  @override
  String get settingSendspinQueueArtDescription =>
      'Обложка в каждой строке панели очереди.';

  @override
  String get mediaNowPlayingHint => 'Полноэкранный вид во время музыки';

  @override
  String get mediaInterfaceHeading => 'Интерфейс';

  @override
  String get settingSendspinFullscreenTitle =>
      '«Сейчас играет» вместо заставки';

  @override
  String get settingSendspinFullscreenDescription =>
      'Пока играет музыка, заставка становится полноэкранным видом «Сейчас играет» с обложкой. Без воспроизведения работает обычная заставка.';

  @override
  String get settingSendspinFullscreenSplitTitle =>
      'Показывать рядом с заставкой';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      'Держать заставку видимой рядом с «Сейчас играет». Портретные экраны ставят заставку над плеером. Маленькие экраны оставляют полноэкранный плеер.';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => 'Заполнить экран';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      'Переопределяет заполнение фото, пока заставка делит экран с «Сейчас играет». «По умолчанию» использует настройку каждой заставки. «Выкл» держит всё фото между чёрными полосами. «Умно» увеличивает фото, близкие по форме к экрану, оформляя остальные поверх размытого фона. «Всегда» увеличивает каждое фото, обрезая не влезающее.';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle =>
      'Игнорировать яркость заставки';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      'Использовать обычную яркость экрана вместо яркости заставки, пока «Сейчас играет» показан рядом с заставкой. Также перекрывает запланированную яркость заставки.';

  @override
  String get mediaScreensaverHeading => 'Заставка';

  @override
  String get mediaDefaultFill => 'По умолчанию';

  @override
  String get mediaFillOff => 'Выкл';

  @override
  String get mediaFillSmart => 'Умно';

  @override
  String get mediaFillAlways => 'Всегда';

  @override
  String get mediaPickPlayer => 'Выберите плеер';

  @override
  String get mediaMaPlayer => 'Плеер Music Assistant';

  @override
  String get mediaHaPlayer => 'Медиаплеер Home Assistant';

  @override
  String get mediaSonosRoom => 'Комната Sonos';

  @override
  String get mediaSearchPlayers => 'Поиск плееров';

  @override
  String get mediaOffline => 'Не в сети';

  @override
  String mediaOfflineName(String name) {
    return '$name (не в сети)';
  }

  @override
  String get mediaSetUpMa =>
      'Настройте Music Assistant, чтобы увидеть его плееры.';

  @override
  String get mediaSetUpHa =>
      'Подключите Home Assistant, чтобы увидеть его медиаплееры.';

  @override
  String get mediaSetUpSonos =>
      'Колонки Sonos пока не известны. Найдите или добавьте одну на странице Sonos.';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant не ответил: $error';
  }

  @override
  String get mediaSaveFailed => 'Не удалось сохранить плеер.';

  @override
  String get mediaSelectFailed => 'Не удалось выбрать плеер';

  @override
  String get mediaNotificationAccessRemote =>
      'Без этого Android не показывает медиасеансы, поэтому «Сейчас играет» не может отслеживать приложения на этом устройстве. Экран выдачи разрешения появится на планшете.';

  @override
  String get mediaLocalMediaSession => 'Локальный медиасеанс';

  @override
  String get settingSendspinEnabledTitle => 'Включить плеер Sendspin';

  @override
  String get settingSendspinEnabledDescription =>
      'Превратить это устройство в синхронизированный плеер Sendspin. Оно появляется в Music Assistant под именем устройства, синхронно со всеми остальными колонками Sendspin.';

  @override
  String get settingSendspinServerTitle => 'Сервер';

  @override
  String get settingSendspinServerDescription =>
      'Адрес сервера Sendspin, например 192.168.1.10:8927. Оставьте пустым для автопоиска сервера в сети.';

  @override
  String get settingSendspinCodecTitle => 'Предпочтительный кодек';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC без потерь и идеален на Wi-Fi или ethernet. Окончательный выбор делает сервер из того, что предлагает устройство.';

  @override
  String get settingSendspinSyncOffsetTitle =>
      'Смещение синхронизации звука (мс)';

  @override
  String get settingSendspinSyncOffsetDescription =>
      'При отрицательном значении это устройство играет раньше, для колонок, отстающих от группы (Bluetooth). Настраивайте на слух; применяется на лету.';

  @override
  String get settingSendspinGroupVolumeDescription =>
      'Пока это устройство играет в группе, ползунок громкости задаёт громкость всей группы. Выключено: только этого устройства. Нужно соединение с Music Assistant.';

  @override
  String get settingSendspinMasterVolumeTitle =>
      'Управлять громкостью устройства';

  @override
  String get settingSendspinMasterVolumeDescription =>
      'Music Assistant задаёт громкость, которую меняют кнопки громкости, вместо громкости медиа. Звуки ассистента тоже следуют за ней.';

  @override
  String get mediaSendspinPage => 'Плеер Sendspin';

  @override
  String get mediaSendspinHint =>
      'Сделать это устройство синхронизированным плеером Music Assistant';

  @override
  String get mediaFlac => 'FLAC (без потерь)';

  @override
  String get mediaOpus => 'Opus (экономичный)';

  @override
  String get mediaPcm => 'PCM (без сжатия)';

  @override
  String get settingSendspinSonosGroupVolumeTitle =>
      'Регулировать громкость группы';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      'Пока отслеживаемая комната играет в группе, ползунок громкости задаёт громкость всей группы. Выключено: только этой комнаты.';

  @override
  String get settingSendspinSonosInputsTitle => 'Показывать ТВ и линейный вход';

  @override
  String get settingSendspinSonosInputsDescription =>
      'Показывать активность в медиаплеере, когда активны входы eARC или линейный.';

  @override
  String get mediaSonosHint => 'Колонки в сети, добавление по адресу';

  @override
  String get mediaSonosSpeakers => 'Колонки';

  @override
  String get mediaSonosNoneFound => 'Sonos не найден';

  @override
  String get mediaSonosDiscoveryEmpty =>
      'В этой сети никто не ответил. Добавьте по адресу.';

  @override
  String get mediaSonosAddTitle => 'Добавить Sonos по адресу';

  @override
  String get mediaSonosLooking => 'Поиск…';

  @override
  String get mediaSonosEmpty => 'Колонок пока нет';

  @override
  String get mediaSonosEmptyHelp =>
      'Выполните поиск в этой сети или добавьте колонку по адресу.';

  @override
  String get mediaSonosForget => 'Забыть';

  @override
  String get mediaSonosSearchTitle => 'Поиск в сети';

  @override
  String get mediaSonosSearchHelp =>
      'Находит колонки Sonos в этой сети. Для автообнаружения колонки должны быть в том же VLAN, что и это устройство.';

  @override
  String get mediaSonosSearch => 'Найти';

  @override
  String get mediaSonosSearching => 'Поиск…';

  @override
  String get mediaSonosAddAddress => 'Добавить по адресу';

  @override
  String get mediaSonosAddressHelp =>
      'Адрес колонки в сети. По нему добавляется вся система Sonos.';

  @override
  String get mediaSonosPickRoom =>
      'Выберите комнату в «Источник плеера», Sonos.';

  @override
  String get mediaSonosAdded => 'Sonos добавлен';

  @override
  String get mediaSonosNoRooms => 'Колонка не вернула ни одной комнаты.';

  @override
  String get mediaSonosNoAddress => 'нет адреса';

  @override
  String mediaSonosUnreachable(String host) {
    return 'По адресу $host Sonos не ответил.';
  }

  @override
  String get settingsMenuHomeAssistant => 'Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary =>
      'Соединение, панель, режим киоска';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary =>
      'Слово пробуждения, фоновое прослушивание';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary =>
      'Нативные сущности и Bluetooth-прокси';

  @override
  String get settingsMenuScreenAudio => 'Экран и звук';

  @override
  String get settingsMenuScreenAudioSummary => 'Яркость, громкость, микрофон';

  @override
  String get settingsMenuScreensaver => 'Заставка';

  @override
  String get settingsMenuScreensaverSummary =>
      'Тайм-аут простоя, режимы, пробуждение по движению';

  @override
  String get settingsMenuBrowser => 'Веб-просмотр';

  @override
  String get settingsMenuBrowserSummary => 'Кэш, SSL, масштаб';

  @override
  String get settingsMenuMediaPlayer => 'Медиаплеер';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant, Sendspin, Sonos';

  @override
  String get settingsMenuDlna => 'Рендерер DLNA';

  @override
  String get settingsMenuDlnaSummary =>
      'Дистанционный показ изображений, видео и звука';

  @override
  String get settingsMenuIntercom => 'Интерком';

  @override
  String get settingsMenuIntercomSummary => 'Разговоры между киосками';

  @override
  String get settingsMenuCamera => 'Камера';

  @override
  String get settingsMenuCameraSummary =>
      'Камера устройства, движение, стриминг';

  @override
  String get settingsMenuCameraStreams => 'Потоки камер';

  @override
  String get settingsMenuCameraStreamsSummary =>
      'Go2RTC и камеры Home Assistant';

  @override
  String get settingsMenuKiosk => 'Режим киоска';

  @override
  String get settingsMenuKioskSummary => 'Жест выхода, PIN, аппаратные кнопки';

  @override
  String get settingsMenuHomeLauncher => 'Домашний лаунчер';

  @override
  String get settingsMenuHomeLauncherSummary =>
      'Заменить домашний экран устройства';

  @override
  String get settingsMenuAppLauncher => 'Лаунчер приложений';

  @override
  String get settingsMenuAppLauncherSummary =>
      'Открывать другие приложения из киоска';

  @override
  String get settingsMenuGestures => 'Жесты';

  @override
  String get settingsMenuGesturesSummary => 'Касания, ладонь и хлопки';

  @override
  String get settingsMenuDevice => 'Устройство';

  @override
  String get settingsMenuDeviceSummary =>
      'Имя, тема приложения, удалённый доступ';

  @override
  String get settingsMenuFleet => 'Управление группой киосков';

  @override
  String get settingsMenuFleetSummary =>
      'Вести за собой другие киоски или следовать за ними';

  @override
  String get settingsMenuPlugins => 'Менеджер плагинов';

  @override
  String get settingsMenuPluginsSummary => 'Установка и управление плагинами';

  @override
  String get settingsMenuLogs => 'Журналы';

  @override
  String get settingsMenuLogsSummary => 'Журнал приложения и веб-консоль';

  @override
  String get settingsMenuAbout => 'О приложении';

  @override
  String get settingsMenuAboutSummary => 'Версия, автор, лицензия';

  @override
  String get settingsMenuOverview => 'Обзор';

  @override
  String get settingsMenuOverviewSummary => 'Экран и быстрые действия';

  @override
  String get settingsMenuLockdown => 'Режим блокировки';

  @override
  String get settingsMenuLockdownSummary =>
      'Отключить взаимодействие с экраном';

  @override
  String get settingsMenuFiles => 'Менеджер файлов';

  @override
  String get settingsMenuFilesSummary =>
      'Просмотр, скачивание и загрузка файлов';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => 'Дисплей';

  @override
  String get settingsGroupMediaCameras => 'Медиа и камеры';

  @override
  String get settingsGroupHousehold => 'Дом';

  @override
  String get settingsGroupKiosk => 'Киоск';

  @override
  String get settingsGroupSystem => 'Система';

  @override
  String get settingsMenuMenu => 'Меню';

  @override
  String get settingsMenuTheme => 'Тема';

  @override
  String get settingsMenuLogout => 'Выйти';

  @override
  String get settingsMenuSwitchKiosk => 'Сменить киоск';

  @override
  String settingsMenuThemeState(String theme) {
    return 'Тема: $theme';
  }

  @override
  String get settingsMenuThemeAuto => 'Автоматическая';

  @override
  String get settingsMenuOverviewHeadlessSummary =>
      'Состояние и быстрое управление';

  @override
  String get settingsMenuHomeAssistantHeadlessSummary => 'Подключение';

  @override
  String get settingsMenuAudio => 'Аудио';

  @override
  String get settingsMenuAudioSummary => 'Громкость, микрофон';

  @override
  String get settingsGroupMedia => 'Медиа';

  @override
  String get settingsMenuDlnaHeadlessSummary =>
      'Удалённое воспроизведение аудио';

  @override
  String get settingsMenuGesturesHeadlessSummary => 'Жесты кнопками и хлопками';

  @override
  String get settingsMenuLeds => 'Управление LED';

  @override
  String get settingsMenuLedsSummary => 'Цвета и эффекты индикаторов состояния';

  @override
  String get settingsLedTimers => 'Таймеры';

  @override
  String get settingsLedNotifications => 'Уведомления';

  @override
  String get settingsLedIdle => 'В покое';

  @override
  String get settingsLedEffects => 'Эффекты';

  @override
  String get settingsGroupKioskSatellite => 'Kiosk Satellite';

  @override
  String get settingsMenuNavigation => 'Навигация';

  @override
  String get settingsMenuNavigationSummary => 'Классическая или Compass';

  @override
  String get navigationStyleSection => 'Стиль навигации';

  @override
  String get navigationLayoutSection => 'Раскладка Compass';

  @override
  String get navigationOptionsSection => 'Параметры Compass';

  @override
  String get settingNavStyleTitle => 'Стиль навигации';

  @override
  String get settingNavStyleDescription =>
      'Классическая сохраняет боковое меню, «Потяните для обновления» и карусель панели. Compass переключает виды, расположенные крестом, свайпом.';

  @override
  String get settingNavCompassLayoutTitle => 'Раскладка Compass';

  @override
  String get settingNavCompassLayoutViewsDescription =>
      'До двух видов с каждой стороны. Добавьте несколько видов панелей Home Assistant и по одному каждого другого типа.';

  @override
  String get settingNavCompassAnimationTitle => 'Анимация свайпа';

  @override
  String get settingNavCompassAnimationDescription =>
      'Отдалить, чтобы показать соседние виды, или просто пролистнуть.';

  @override
  String get settingNavCompassPositionTitle =>
      'Показывать положение при свайпе';

  @override
  String get settingNavCompassPositionDescription =>
      'Небольшая карта того, где вы сейчас.';

  @override
  String get settingNavCompassReturnMinutesTitle => 'Возвращаться в центр';

  @override
  String get settingNavCompassReturnMinutesDescription =>
      'Возвращаться к центральному виду, если столько времени никто не касается экрана. Установите 0, чтобы оставаться на виде.';

  @override
  String get settingNavCompassMenuItemsTitle => 'Пункты меню';

  @override
  String get settingNavQuickControlsItemsDescription =>
      'Что показывает вид «Быстрые действия». Общее с боковым меню.';

  @override
  String get navigationClassic => 'Классическая';

  @override
  String get navigationCompass => 'Compass';

  @override
  String get navigationZoom => 'Масштаб';

  @override
  String get navigationSlide => 'Сдвиг';

  @override
  String get compassClassicViewHint => 'Вид Home Assistant с боковым меню.';

  @override
  String get compassCompassHint =>
      'Свайп между видами, расположенными крестом.';

  @override
  String get compassLayoutViewsHint =>
      'До двух видов с каждой стороны. Добавьте несколько видов панелей Home Assistant и по одному каждого другого типа. Коснитесь вида, чтобы изменить его, в том числе центральный.';

  @override
  String get compassOffNote =>
      '«Потяните для обновления», карусель панели и свайп от края, открывающий боковое меню, отключены, пока включён Compass.';

  @override
  String get settingOffUnderCompass =>
      'Отключено, пока включена навигация Compass.';

  @override
  String get compassQuickControlsView => 'Быстрые действия';

  @override
  String get compassHomeDashboard => 'Home Assistant';

  @override
  String get compassAppLauncher => 'Лаунчер приложений';

  @override
  String get compassCenter => 'Центр';

  @override
  String get compassAddTile => 'Добавить';

  @override
  String get compassAddView => 'Добавить вид';

  @override
  String get compassMoveIn => 'Ближе';

  @override
  String get compassMoveOut => 'Дальше';

  @override
  String get compassReplace => 'Заменить';

  @override
  String get compassRemove => 'Убрать';

  @override
  String get compassChange => 'Изменить';

  @override
  String get compassSideUp => 'Сверху';

  @override
  String get compassSideRight => 'Справа';

  @override
  String get compassSideDown => 'Снизу';

  @override
  String get compassSideLeft => 'Слева';

  @override
  String compassFirstView(String side) {
    return '$side, первый вид';
  }

  @override
  String compassSecondView(String side) {
    return '$side, второй вид';
  }

  @override
  String get compassAddAbove => 'Добавить вид сверху';

  @override
  String get compassAddBelow => 'Добавить вид снизу';

  @override
  String get compassAddLeft => 'Добавить вид слева';

  @override
  String get compassAddRight => 'Добавить вид справа';

  @override
  String get compassChangeCenter => 'Изменить центральный вид';

  @override
  String compassReplaceTitle(String name) {
    return 'Заменить: $name';
  }

  @override
  String get compassKindDashboard => 'Панель Home Assistant';

  @override
  String get compassKindDashboardHint =>
      'Любой вид, свои страницы и страницы приложений';

  @override
  String get compassKindTaken => 'Уже размещено';

  @override
  String get compassKindUnavailable => 'Не настроено на этом киоске';

  @override
  String get compassKioskLocked => 'Киоск заблокирован';

  @override
  String get compassQuickControls => 'Быстрые действия';

  @override
  String get compassOpen => 'Открыть';

  @override
  String get compassStateOn => 'Вкл.';

  @override
  String get compassStateOff => 'Выкл.';

  @override
  String get compassHoldMode => 'Режим удержания';

  @override
  String get settingAdaptiveBrightnessTitle => 'Адаптивная яркость';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Затемнять экран по мере потемнения комнаты, используя датчик освещённости.';

  @override
  String get settingAdaptiveUseEntityTitle =>
      'Использовать сущность Home Assistant';

  @override
  String get settingAdaptiveUseEntityDescription =>
      'Получать освещённость комнаты от датчика Home Assistant.';

  @override
  String get settingAdaptiveLightEntityTitle => 'Сущность датчика освещённости';

  @override
  String get settingAdaptiveLightEntityDescription =>
      'Датчик Home Assistant, сообщающий освещённость в люксах.';

  @override
  String get settingAdaptiveMinBrightnessTitle => 'Минимальная яркость';

  @override
  String get settingAdaptiveMinBrightnessDescription =>
      'Яркость экрана в тёмной комнате.';

  @override
  String get settingAdaptiveMaxBrightnessTitle => 'Максимальная яркость';

  @override
  String get settingAdaptiveMaxBrightnessDescription =>
      'Яркость экрана в светлой комнате.';

  @override
  String get settingAdaptiveDarkLuxTitle => 'Тёмная комната (лк)';

  @override
  String get settingAdaptiveDarkLuxDescription =>
      'Освещённость, при которой и ниже экран работает на минимальной яркости.';

  @override
  String get settingAdaptiveBrightLuxTitle => 'Светлая комната (лк)';

  @override
  String get settingAdaptiveBrightLuxDescription =>
      'Освещённость, при которой и выше экран работает на максимальной яркости.';

  @override
  String get screenAudioAdaptiveHint =>
      'Следовать свету комнаты через датчик освещённости';

  @override
  String get screenAudioAdaptiveNote =>
      'Уровень в светлой комнате. Адаптивная яркость затемняет его от этой точки.';

  @override
  String get screenAudioAdaptiveOwns => 'Адаптивная яркость включена.';

  @override
  String get screenAudioNoSensor =>
      'На этом устройстве нет датчика освещённости.';

  @override
  String get screenAudioAmbientLight => 'Освещённость';

  @override
  String get screenAudioAmbientHelp => 'Что сейчас читает датчик освещённости.';

  @override
  String get screenAudioNoReading => 'Показаний пока нет';

  @override
  String screenAudioLux(String lux) {
    return '$lux лк';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux лк (последнее известное)';
  }

  @override
  String get screenAudioSetsMaximum =>
      'Задаёт максимальную яркость: адаптивная яркость включена.';

  @override
  String get screenAudioSetsDefault => 'Задаёт яркость по умолчанию.';

  @override
  String get screenAudioBrightnessCurve => 'Кривая яркости';

  @override
  String get screenAudioCurveHint =>
      'Потяните точку или нажмите её, чтобы ввести точные значения. «Свет экрана» в Home Assistant двигает верхнюю точку, и кривая следует за ней.';

  @override
  String screenAudioCurvePoint(String number) {
    return 'Точка $number';
  }

  @override
  String get screenAudioCurveLightLevel => 'Уровень света (лк)';

  @override
  String get screenAudioCurveBrightness => 'Яркость (%)';

  @override
  String screenAudioCurveLuxRange(String low, String high) {
    return 'Введите уровень света от $low до $high лк';
  }

  @override
  String screenAudioCurveLevelRange(String low, String high) {
    return 'Введите яркость от $low% до $high%';
  }

  @override
  String get settingAudioMicDeviceTitle => 'Микрофон';

  @override
  String get settingAudioMicDeviceDescription =>
      'Микрофон, с которого определение слова пробуждения и голосовые реплики пишут звук.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Динамик';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Выход для звуков Voice Satellite; воспроизведение медиа следует системному маршруту.';

  @override
  String get screenAudioDevices => 'Звуковые устройства';

  @override
  String get screenAudioSelectedDevice => 'Выбранное устройство';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (не подключено)';
  }

  @override
  String get settingEqualizerEnabledTitle => 'Включить эквалайзер';

  @override
  String get settingEqualizerEnabledDescription =>
      'Настраивает звучание музыки, ассистента, сигналов и интеркома. Звук видео и панелей не обрабатывается.';

  @override
  String get settingEqualizerBand1Title => '100 Гц';

  @override
  String get settingEqualizerBand1Description =>
      'Низкие частоты. Маленькие динамики быстро начинают искажать звук при их усилении.';

  @override
  String get settingEqualizerBand2Title => '300 Гц';

  @override
  String get settingEqualizerBand2Description =>
      'Нижняя середина. Ослабление убирает гулкое или бубнящее звучание.';

  @override
  String get settingEqualizerBand3Title => '1 кГц';

  @override
  String get settingEqualizerBand3Description =>
      'Середина, где находится большая часть голоса.';

  @override
  String get settingEqualizerBand4Title => '3 кГц';

  @override
  String get settingEqualizerBand4Description =>
      'Верхняя середина. Усиление делает речь разборчивее.';

  @override
  String get settingEqualizerBand5Title => '10 кГц';

  @override
  String get settingEqualizerBand5Description => 'Высокие частоты.';

  @override
  String get settingEqualizerPreampTitle => 'Автоматический предусилитель';

  @override
  String get settingEqualizerPreampDescription =>
      'Снижает уровень на величину наибольшего усиления, чтобы динамик не искажал звук и подавление эха продолжало работать.';

  @override
  String get screenAudioEqualizer => 'Эквалайзер';

  @override
  String get screenAudioEqualizerHint =>
      'Низкие, средние, высокие частоты, предусилитель';

  @override
  String get settingMicCaptureModeTitle => 'Режим захвата';

  @override
  String get settingMicCaptureModeDescription =>
      'Выберите «Голосовая связь», если микрофон замолкает здесь или после звука киоска. Некоторые устройства пишут корректно только через аудиотракт звонков.';

  @override
  String get settingMicSoftwareEchoCancellationTitle => 'Подавление эха';

  @override
  String get settingMicSoftwareEchoCancellationDescription =>
      'Убирает собственные звуки киоска из микрофона, чтобы слово пробуждения и ассистент их не слышали. Оставьте включённым, если микрофон с собственным подавлением эха не звучит с ним хуже.';

  @override
  String get settingMicEchoCancellationMethodTitle => 'Метод подавления эха';

  @override
  String get settingMicEchoCancellationMethodDescription =>
      'Автоматически проверяет GTCRN, пока киоск воспроизводит звуки, и переключается на AEC3, если остаётся слишком много эха. Выберите «Автоматически», чтобы повторить проверку.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Подавление шума';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Убирает шипение из микрофона. Это меняет то, что слышит слово пробуждения; включайте для шипящего микрофона.';

  @override
  String get settingMicChannelTitle => 'Канал микрофона';

  @override
  String get settingMicChannelDescription =>
      'Многоканальные микрофоны часто резервируют канал под распознавание речи; его выбор может улучшить определение.';

  @override
  String get settingMicGainDbTitle => 'Усиление микрофона';

  @override
  String get settingMicGainDbDescription =>
      'Усиливает или ослабляет сигнал микрофона до любой обработки. Цель: уровень около 0.05 в тестере слова пробуждения; излишнее усиление искажает речь и мешает определению.';

  @override
  String get settingMicCaptureFormatTitle => 'Формат захвата';

  @override
  String get settingMicCaptureFormatDescription =>
      'Выберите «48 кГц стерео», если микрофон работает в других приложениях, но не здесь: некоторые звуковые карты пишут только в этом формате, и приложение конвертирует само.';

  @override
  String get screenAudioMicrophoneSettings => 'Настройки микрофона';

  @override
  String get screenAudioMicrophoneHint =>
      'Эхо, шум, усиление, формат, текущий уровень';

  @override
  String get screenAudioMicrophoneNote =>
      'Подстройте захват под ваш микрофон и комнату. После изменения проверьте слова пробуждения и голосовое взаимодействие.';

  @override
  String get screenAudioAutomaticDefault => 'Автоматически (по умолчанию)';

  @override
  String get screenAudioStereo => '48 кГц стерео';

  @override
  String get screenAudioCaptureRawMicrophone =>
      'Необработанный сигнал (по умолчанию)';

  @override
  String get screenAudioCaptureVoiceCommunication => 'Голосовая связь';

  @override
  String get screenAudioEchoMethodGtcrnDetected => 'GTCRN (определено)';

  @override
  String get screenAudioEchoMethodAec3Detected => 'AEC3 (определено)';

  @override
  String get screenAudioDownmix => 'Сведение (по умолчанию)';

  @override
  String screenAudioChannel(String channel) {
    return 'Канал $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return 'Канал $channel (нет на этом микрофоне)';
  }

  @override
  String get screenAudioMicrophoneLevel => 'Уровень микрофона';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      'Говорите оттуда, где пользуетесь устройством; подстройте усиление так, чтобы обычная речь доходила примерно до конца зелёной зоны.';

  @override
  String get settingBrowserCutoutModeTitle => 'Вырез экрана';

  @override
  String get settingBrowserCutoutModeDescription =>
      'Что делать с областью экрана вокруг выреза или отверстия камеры. Выберите «Обходить вырез», если камера наезжает на кнопки вверху панели.';

  @override
  String get settingScreenOrientationTitle => 'Ориентация экрана';

  @override
  String get settingScreenOrientationDescription =>
      'Принудительно держать экран в одной ориентации. Для устройства без датчика поворота или смонтированного так, что датчик ошибается.';

  @override
  String get settingScreenHideStatusBarTitle => 'Скрывать строку состояния';

  @override
  String get settingScreenHideStatusBarDescription =>
      'Выключите, чтобы часы и значки уведомлений оставались вверху экрана. Режим киоска всегда её скрывает.';

  @override
  String get settingScreenHideNavigationBarTitle => 'Скрывать панель навигации';

  @override
  String get settingScreenHideNavigationBarDescription =>
      'Выключите, чтобы кнопки навигации оставались на экране вместе с панелью задач на планшетах. Режим киоска всегда её скрывает.';

  @override
  String get settingScreenShowOnLockScreenTitle =>
      'Показывать поверх экрана блокировки';

  @override
  String get settingScreenShowOnLockScreenDescription =>
      'Показывает панель поверх экрана блокировки с PIN-кодом, графическим ключом или паролем. Остальное устройство остаётся заблокированным.';

  @override
  String get settingKeepScreenOnTitle => 'Не выключать экран';

  @override
  String get settingKeepScreenOnDescription => 'Не давать ОС выключать экран.';

  @override
  String get settingSetBrightnessOnLaunchTitle =>
      'Задавать яркость при запуске';

  @override
  String get settingSetBrightnessOnLaunchDescription =>
      'Применять яркость по умолчанию при каждом старте приложения.';

  @override
  String get settingDefaultBrightnessTitle => 'Яркость по умолчанию';

  @override
  String get settingDefaultBrightnessDescription =>
      'Яркость экрана при старте приложения. Движение ползунка применяет её сразу.';

  @override
  String get screenAudioScreen => 'Экран';

  @override
  String get screenAudioCutoutAlways => 'Использовать область выреза';

  @override
  String get screenAudioCutoutShort => 'Только короткие края';

  @override
  String get screenAudioCutoutDefault => 'Системная';

  @override
  String get screenAudioCutoutNever => 'Обходить вырез';

  @override
  String get screenAudioAutomatic => 'Автоматически';

  @override
  String get screenAudioLandscape => 'Альбомная';

  @override
  String get screenAudioReverseLandscape => 'Обратная альбомная';

  @override
  String get screenAudioPortrait => 'Портретная';

  @override
  String get screenAudioReversePortrait => 'Обратная портретная';

  @override
  String get screenAudioPermission => 'Разрешение';

  @override
  String get screenAudioBrightnessFallback =>
      'Яркость использует резервный режим';

  @override
  String get screenAudioBrightnessPermission =>
      'Без разрешения «Изменение системных настроек» яркость затемняет только это приложение, а не реальную яркость панели.';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      'Без разрешения «Изменение системных настроек» яркость затемняет только приложение, а не реальную яркость панели.';

  @override
  String get screenAudioAlwaysOn => 'Всегда включённый экран';

  @override
  String get screenAudioAlwaysOnClock =>
      'Это устройство держит тусклые часы включёнными';

  @override
  String get screenAudioAlwaysOnHelp =>
      'Выключение экрана усыпляет устройство, но always-on display снова подсвечивает экран блокировки, и ни одно приложение не может это остановить. Выключите «Всегда показывать время и информацию» в настройках Android в разделе «Экран» рядом с опциями экрана блокировки; некоторые прошивки называют это always-on display. Сущность экрана Home Assistant останется недоступной, пока вы это не сделаете.';

  @override
  String get settingMediaVolumeTitle => 'Громкость медиа';

  @override
  String get settingMediaVolumeDescription =>
      'Музыка и видео играют на этой доле общей громкости. Громкость плеера Sendspin в Music Assistant двигает этот ползунок.';

  @override
  String get settingAssistantVolumeTitle => 'Громкость ассистента';

  @override
  String get settingAssistantVolumeDescription =>
      'Голосовые ответы и сигналы играют на этой доле общей громкости, независимо от медиа.';

  @override
  String get settingIntercomVolumeTitle => 'Громкость интеркома';

  @override
  String get settingIntercomVolumeDescription =>
      'Голос другого киоска и объявления играют на этой доле общей громкости.';

  @override
  String get screenAudioVolume => 'Громкость';

  @override
  String get screenAudioMasterVolume => 'Общая громкость';

  @override
  String get screenAudioMasterHelp =>
      'Громкость устройства. Громкости медиа, интеркома и ассистента задаются как доля от неё.';

  @override
  String get settingScreensaverBlackHideExtrasTitle =>
      'Скрыть всё дополнительное';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      'Держит экран полностью чёрным: без маленьких часов, сущностей «Сводки» и других наложений.';

  @override
  String get screensaverBlackSection => 'Чёрная заставка';

  @override
  String get settingScreensaverCelestialLocationTitle => 'Местоположение';

  @override
  String get settingScreensaverCelestialLocationDescription =>
      'Откуда видно небо.';

  @override
  String get settingScreensaverCelestialEntityTitle => 'Сущность';

  @override
  String get settingScreensaverCelestialEntityDescription =>
      'Человек, трекер устройства или зона с местоположением.';

  @override
  String get settingScreensaverCelestialCoordinatesTitle => 'Координаты';

  @override
  String get settingScreensaverCelestialCoordinatesDescription =>
      'Широта и долгота, например 40.71, -74.01.';

  @override
  String get settingScreensaverCelestialTerrainTitle => 'Пейзаж';

  @override
  String get settingScreensaverCelestialTerrainDescription =>
      'Рельеф вдоль горизонта.';

  @override
  String get settingScreensaverCelestialFollowDeviceTitle => 'Наведите на небо';

  @override
  String get settingScreensaverCelestialFollowDeviceDescription =>
      'Поднимите устройство, и небо на экране будет поворачиваться вместе с ним, чтобы вы могли узнать, на что смотрите. Нужен датчик компаса.';

  @override
  String get settingScreensaverCelestialDaytimeTitle => 'Дневное небо';

  @override
  String get settingScreensaverCelestialDaytimeDescription =>
      'Осветлять небо и приглушать звёзды, пока Солнце над горизонтом. Выключите, чтобы показывать ночное небо весь день.';

  @override
  String get settingScreensaverCelestialMilkyWayTitle => 'Млечный Путь';

  @override
  String get settingScreensaverCelestialMilkyWayDescription =>
      'Показывать свечение нашей галактики на ночном небе.';

  @override
  String get settingScreensaverCelestialPlanetsTitle => 'Планеты';

  @override
  String get settingScreensaverCelestialPlanetsDescription =>
      'Показывать планеты там, где они находятся этой ночью.';

  @override
  String get settingScreensaverCelestialDeepSkyTitle =>
      'Галактики и туманности';

  @override
  String get settingScreensaverCelestialDeepSkyDescription =>
      'Показывать галактику Андромеды, туманность Ориона и другие объекты, видимые без телескопа.';

  @override
  String get settingScreensaverCelestialLightPollutionTitle =>
      'Световое загрязнение';

  @override
  String get settingScreensaverCelestialLightPollutionDescription =>
      'Имитировать свечение городских огней. Чем выше значение, тем меньше видно тусклых звёзд и Млечного Пути.';

  @override
  String get settingScreensaverCelestialTwinkleTitle => 'Мерцание звёзд';

  @override
  String get settingScreensaverCelestialTwinkleDescription =>
      'Звёзды мерцают, сильнее всего у горизонта. Выключите для экономии энергии.';

  @override
  String get settingScreensaverCelestialLargeMoonTitle => 'Крупная Луна';

  @override
  String get settingScreensaverCelestialLargeMoonDescription =>
      'Рисовать Луну втрое, а Солнце вдвое больше настоящего размера, чтобы фазу было легко разглядеть.';

  @override
  String get settingScreensaverCelestialLinesTitle => 'Линии созвездий';

  @override
  String get settingScreensaverCelestialLinesDescription =>
      'Соединять звёзды каждого созвездия.';

  @override
  String get settingScreensaverCelestialConstellationNamesTitle =>
      'Названия созвездий';

  @override
  String get settingScreensaverCelestialConstellationNamesDescription =>
      'Подписывать созвездия. При увеличении их становится больше.';

  @override
  String get settingScreensaverCelestialNamesTitle => 'Названия звёзд и планет';

  @override
  String get settingScreensaverCelestialNamesDescription =>
      'Подписывать Солнце, Луну, планеты, самые яркие звёзды и галактики. При увеличении подписей звёзд становится больше.';

  @override
  String get settingScreensaverCelestialCompassTitle => 'Стороны света';

  @override
  String get settingScreensaverCelestialCompassDescription =>
      'Отмечать север, восток, юг и запад на горизонте.';

  @override
  String get settingScreensaverCelestialLabelScaleTitle => 'Размер подписей';

  @override
  String get settingScreensaverCelestialLabelScaleDescription =>
      'Масштабирует подписи на небе от 50 до 200 процентов.';

  @override
  String get settingScreensaverCelestialControlCoordinatesTitle => 'Положение';

  @override
  String get settingScreensaverCelestialControlCoordinatesDescription =>
      'Показывает широту и долготу, откуда видно небо.';

  @override
  String get settingScreensaverCelestialControlAzimuthTitle => 'Азимут';

  @override
  String get settingScreensaverCelestialControlAzimuthDescription =>
      'Показывает сторону света, куда смотрит центр экрана.';

  @override
  String get settingScreensaverCelestialControlAltitudeTitle => 'Высота';

  @override
  String get settingScreensaverCelestialControlAltitudeDescription =>
      'Показывает, насколько высоко над горизонтом центр экрана.';

  @override
  String get settingScreensaverCelestialControlFovTitle => 'Поле зрения';

  @override
  String get settingScreensaverCelestialControlFovDescription =>
      'Показывает, какую часть неба охватывает экран, в градусах.';

  @override
  String get settingScreensaverCelestialControlTimeTitle => 'Время';

  @override
  String get settingScreensaverCelestialControlTimeDescription =>
      'Показывает время неба с кнопкой «Сейчас» после ускорения.';

  @override
  String get settingScreensaverCelestialControlTimelapseTitle =>
      'Ускорение времени';

  @override
  String get settingScreensaverCelestialControlTimelapseDescription =>
      'Ускоряет время, чтобы увидеть, как вращается небо. Коснитесь, чтобы изменить скорость.';

  @override
  String get settingScreensaverCelestialControlPointAtSkyTitle =>
      'Переключатель «Наведите на небо»';

  @override
  String get settingScreensaverCelestialControlPointAtSkyDescription =>
      'Включает и выключает режим «Наведите на небо». Показывается только на устройствах с компасом.';

  @override
  String get settingScreensaverCelestialControlMoonPhaseTitle => 'Фаза Луны';

  @override
  String get settingScreensaverCelestialControlMoonPhaseDescription =>
      'Показывает фазу Луны и долю освещённого диска.';

  @override
  String get settingScreensaverCelestialControlScaleTitle =>
      'Размер элементов управления';

  @override
  String get settingScreensaverCelestialControlScaleDescription =>
      'Масштабирует элементы управления от 50 до 200 процентов.';

  @override
  String get screensaverModeCelestial => 'Звёздное небо';

  @override
  String get screensaverCelestialTerrainHills => 'Холмы';

  @override
  String get screensaverCelestialTerrainMountains => 'Горы';

  @override
  String get screensaverCelestialTerrainPlains => 'Равнина';

  @override
  String get screensaverCelestialTerrainNone => 'Нет';

  @override
  String get screensaverCelestialLocationGps => 'GPS';

  @override
  String get screensaverCelestialLocationHaHome => 'Дом в Home Assistant';

  @override
  String get screensaverCelestialLocationHaEntity => 'Сущность Home Assistant';

  @override
  String get screensaverCelestialLocationManual => 'Вручную';

  @override
  String get screensaverCelestialCurrentLocation => 'Текущее местоположение';

  @override
  String get screensaverCelestialNoGpsReceiver =>
      'На этом устройстве нет GPS-приёмника.';

  @override
  String get screensaverCelestialLocationPermission =>
      'Разрешение на доступ к местоположению не предоставлено.';

  @override
  String get screensaverCelestialNoGpsFix => 'GPS-координат пока нет.';

  @override
  String get screensaverCelestialNoHomeZone =>
      'В Home Assistant нет домашней зоны.';

  @override
  String get screensaverCelestialHaNotConnected =>
      'Home Assistant не подключён.';

  @override
  String get screensaverCelestialPickEntity =>
      'Выберите сущность с местоположением.';

  @override
  String get screensaverCelestialEntityNoLocation =>
      'У этой сущности нет местоположения.';

  @override
  String get screensaverCelestialPage => 'Заставка «Звёздное небо»';

  @override
  String get screensaverCelestialSummary =>
      'Место, пейзаж, небо, подписи, элементы управления';

  @override
  String get screensaverCelestialSkyGroup => 'Небо';

  @override
  String get screensaverCelestialLabelsGroup => 'Подписи';

  @override
  String get screensaverCelestialControlsGroup => 'Элементы управления';

  @override
  String get screensaverCelestialLocationGrantMissing =>
      'Без этого GPS-приёмник не читается, и у неба не будет местоположения.';

  @override
  String get screensaverCelestialLocationGrantReady =>
      'Небо может следовать за GPS-приёмником.';

  @override
  String get screensaverCelestialCoordinatesInvalid =>
      'Введите широту и долготу, например 40.71, -74.01';

  @override
  String get screensaverCelestialNoLocation =>
      'Выберите местоположение в «Настройки > Заставка > Звёздное небо».';

  @override
  String get screensaverCelestialWaitingForGps => 'Ожидание GPS-позиции...';

  @override
  String get screensaverCelestialDoubleTapHint =>
      'Коснитесь дважды, чтобы закрыть';

  @override
  String get screensaverCelestialCalibrate =>
      'Двигайте устройство восьмёркой, чтобы откалибровать компас.';

  @override
  String get celestialSun => 'Солнце';

  @override
  String get celestialMoon => 'Луна';

  @override
  String get celestialMercury => 'Меркурий';

  @override
  String get celestialVenus => 'Венера';

  @override
  String get celestialMars => 'Марс';

  @override
  String get celestialJupiter => 'Юпитер';

  @override
  String get celestialSaturn => 'Сатурн';

  @override
  String get celestialUranus => 'Уран';

  @override
  String get celestialNeptune => 'Нептун';

  @override
  String get celestialAndromedaGalaxy => 'Галактика Андромеды';

  @override
  String get celestialTriangulumGalaxy => 'Галактика Треугольника';

  @override
  String get celestialLargeMagellanicCloud => 'Большое Магелланово Облако';

  @override
  String get celestialSmallMagellanicCloud => 'Малое Магелланово Облако';

  @override
  String get celestialOrionNebula => 'Туманность Ориона';

  @override
  String get celestialLagoonNebula => 'Туманность Лагуна';

  @override
  String get celestialCarinaNebula => 'Туманность Киля';

  @override
  String get celestialPleiades => 'Плеяды';

  @override
  String get celestialBeehiveCluster => 'Ясли';

  @override
  String get celestialDoubleCluster => 'Двойное скопление Персея';

  @override
  String get celestialOmegaCentauri => 'Омега Центавра';

  @override
  String get celestialTucanae47 => '47 Тукана';

  @override
  String get celestialCompassNorth => 'С';

  @override
  String get celestialCompassEast => 'В';

  @override
  String get celestialCompassSouth => 'Ю';

  @override
  String get celestialCompassWest => 'З';

  @override
  String get celestialCompassNorthEast => 'СВ';

  @override
  String get celestialCompassSouthEast => 'ЮВ';

  @override
  String get celestialCompassSouthWest => 'ЮЗ';

  @override
  String get celestialCompassNorthWest => 'СЗ';

  @override
  String get celestialAzimuthShort => 'Аз';

  @override
  String get celestialAltitudeShort => 'Выс';

  @override
  String get celestialFovShort => 'ПЗ';

  @override
  String get celestialNow => 'Сейчас';

  @override
  String get celestialMoonNew => 'Новолуние';

  @override
  String get celestialMoonWaxingCrescent => 'Растущий серп';

  @override
  String get celestialMoonFirstQuarter => 'Первая четверть';

  @override
  String get celestialMoonWaxingGibbous => 'Растущая Луна';

  @override
  String get celestialMoonFull => 'Полнолуние';

  @override
  String get celestialMoonWaningGibbous => 'Убывающая Луна';

  @override
  String get celestialMoonLastQuarter => 'Последняя четверть';

  @override
  String get celestialMoonWaningCrescent => 'Убывающий серп';

  @override
  String get settingScreensaverClockStyleTitle => 'Стиль';

  @override
  String get settingScreensaverClockStyleDescription => 'Как рисуются часы.';

  @override
  String get settingScreensaverClockVerticalTitle => 'Вертикальный режим';

  @override
  String get settingScreensaverClockVerticalDescription =>
      'Ставить часы над минутами столбиком, для портретных экранов.';

  @override
  String get settingScreensaverClockFontTitle => 'Гарнитура';

  @override
  String get settingScreensaverClockFontDescription =>
      'Шрифт, которым рисуются часы.';

  @override
  String get settingScreensaverClockFontWeightTitle => 'Насыщенность шрифта';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      'Насколько жирно рисуются цифры. По умолчанию: собственная насыщенность гарнитуры.';

  @override
  String get settingScreensaverClock24hTitle => '24-часовой формат';

  @override
  String get settingScreensaverClock24hDescription =>
      'Показывать 24-часовое время вместо AM/PM.';

  @override
  String get settingScreensaverClockSecondsTitle => 'Показывать секунды';

  @override
  String get settingScreensaverClockSecondsDescription =>
      'Включать секунды в часы.';

  @override
  String get settingScreensaverClockDateTitle => 'Показывать дату';

  @override
  String get settingScreensaverClockDateDescription =>
      'Показывать день недели и дату под часами.';

  @override
  String get settingScreensaverClockScaleTitle => 'Размер часов';

  @override
  String get settingScreensaverClockScaleDescription =>
      'Масштаб часов от 50 до 300 процентов для этого экрана.';

  @override
  String get settingScreensaverClockColorTitle => 'Цвет часов';

  @override
  String get settingScreensaverClockColorDescription => 'Цвет текста часов.';

  @override
  String get settingScreensaverClockBgColorTitle => 'Цвет фона';

  @override
  String get settingScreensaverClockBgColorDescription => 'Цвет позади часов.';

  @override
  String get settingScreensaverClockBackgroundTitle => 'Фоновое фото';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      'Показывать фото за часами вместо сплошного цвета. Путь к изображению на устройстве или URL изображения, которое устройство скачает.';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle =>
      'Обновлять URL-фон';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      'Минуты между загрузками URL-фона. 0: загружать только при записи настройки.';

  @override
  String get settingScreensaverFlipDigitColorTitle => 'Цвет цифр';

  @override
  String get settingScreensaverFlipDigitColorDescription =>
      'Цвет перекидных цифр.';

  @override
  String get settingScreensaverFlipBgColorTitle => 'Цвет карточек';

  @override
  String get settingScreensaverFlipBgColorDescription => 'Цвет карточек.';

  @override
  String get settingScreensaverFlipBackdropColorTitle => 'Цвет фона';

  @override
  String get settingScreensaverFlipBackdropColorDescription =>
      'Цвет позади карточек.';

  @override
  String get settingScreensaverRollerDigitColorTitle => 'Цвет цифр';

  @override
  String get settingScreensaverRollerDigitColorDescription =>
      'Цвет цифр с прокруткой.';

  @override
  String get settingScreensaverRollerBgColorTitle => 'Цвет фона';

  @override
  String get settingScreensaverRollerBgColorDescription => 'Цвет позади цифр.';

  @override
  String get settingScreensaverHandNumbersTitle => 'Цифры';

  @override
  String get settingScreensaverHandNumbersDescription =>
      'Какие часы циферблат показывает цифрами.';

  @override
  String get settingScreensaverHandSecondsTitle =>
      'Показывать секундную стрелку';

  @override
  String get settingScreensaverHandSecondsDescription =>
      'Рисовать секундную стрелку на циферблате.';

  @override
  String get settingScreensaverHandColorTitle => 'Цвет часов';

  @override
  String get settingScreensaverHandColorDescription =>
      'Цвет стрелок, цифр и делений.';

  @override
  String get settingScreensaverHandBgColorTitle => 'Цвет фона';

  @override
  String get settingScreensaverHandBgColorDescription => 'Цвет позади часов.';

  @override
  String get settingScreensaverClockNightTitle => 'Ночной режим';

  @override
  String get settingScreensaverClockNightDescription =>
      'Перекрашивать часы, когда в комнате темно.';

  @override
  String get settingScreensaverClockNightLuxTitle => 'Уровень света';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      'При этом уровне света и ниже часы берут ночной цвет.';

  @override
  String get settingScreensaverClockNightColorTitle => 'Ночной цвет';

  @override
  String get settingScreensaverClockNightColorDescription =>
      'Цвет часов и виджетов в темноте.';

  @override
  String get settingScreensaverClockNightBgColorTitle => 'Ночной фон';

  @override
  String get settingScreensaverClockNightBgColorDescription =>
      'Цвет позади часов в темноте.';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle =>
      'Скрыть фоновое фото';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      'Использовать ночной цвет фона вместо фото, пока ночной режим активен.';

  @override
  String get settingScreensaverClockNightHideWidgetsTitle =>
      'Скрыть виджеты и «Сводку»';

  @override
  String get settingScreensaverClockNightHideWidgetsDescription =>
      'Показывать только часы, пока ночной режим активен.';

  @override
  String get settingScreensaverClockNightCardColorTitle =>
      'Ночной цвет карточек';

  @override
  String get settingScreensaverClockNightCardColorDescription =>
      'Цвет перекидных карточек в темноте.';

  @override
  String get screensaverClockSection => 'Заставка «Часы»';

  @override
  String get screensaverClockHint =>
      'Стиль, шрифт, размер, цвета, ночной режим, фоновое фото';

  @override
  String get screensaverStyleDigital => 'Цифровые часы';

  @override
  String get screensaverStyleFlip => 'Перекидные часы';

  @override
  String get screensaverStyleRoller => 'Часы с прокруткой';

  @override
  String get screensaverStyleHand => 'Стрелочные часы';

  @override
  String get screensaverHandNumbersQuarters => '12, 3, 6 и 9';

  @override
  String get screensaverHandNumbersAll => 'Все часы';

  @override
  String get screensaverFontDefault => 'По умолчанию';

  @override
  String get screensaverFontLight => 'Светлый';

  @override
  String get screensaverFontRegular => 'Обычный';

  @override
  String get screensaverFontMedium => 'Средний';

  @override
  String get screensaverFontBold => 'Жирный';

  @override
  String get screensaverFontBlack => 'Очень жирный';

  @override
  String get screensaverNoPhoto => 'Фото не выбрано';

  @override
  String get screensaverBackgroundHint =>
      'Путь к изображению на устройстве или URL изображения';

  @override
  String get screensaverImageUrlError => 'Введите полный URL изображения';

  @override
  String get screensaverRefreshError => 'Введите целые минуты от 0 до 1440';

  @override
  String screensaverMaxCharacters(String count) {
    return 'Используйте не более $count символов';
  }

  @override
  String get settingScreensaverClockAmPmTitle => 'Показывать AM/PM';

  @override
  String get settingScreensaverClockAmPmDescription =>
      'Добавлять AM или PM после времени.';

  @override
  String get settingScreensaverClockNightTurnOffMinutesTitle =>
      'Выключать экран ночью через';

  @override
  String get settingScreensaverClockNightTurnOffMinutesDescription =>
      'Выключает экран, когда ночной режим длится заданное время, и снова включает, когда в комнате становится светлее. 0: не выключать экран. Требуется разрешение администратора устройства.';

  @override
  String get screensaverNightTurnOffWarning =>
      'Когда дисплей действительно выключится, управление возьмёт собственное энергосбережение планшета. Многие модели Android ведут себя в этом состоянии плохо: Wi-Fi засыпает или отключается, сущности Home Assistant становятся недоступными, камера может быть отозвана, а некоторые модели убивают фоновые приложения. Некоторые датчики освещённости также перестают передавать данные при выключенном дисплее, поэтому экран может не включиться сам, когда в комнате станет светлее. Поведение зависит от производителя.\n\nНадёжная альтернатива: параметр «Использовать чёрный экран вместо этого». Панель выглядит столь же тёмной, а приложение сохраняет полный контроль.';

  @override
  String get screensaverOverlayEntity => 'Сущность';

  @override
  String get screensaverOverlayNotSet => 'Не задано';

  @override
  String get screensaverOverlayName => 'Название';

  @override
  String get screensaverOverlayNameHelp =>
      'Оставьте пустым, чтобы использовать имя из Home Assistant.';

  @override
  String get screensaverOverlayValue => 'Показываемое значение';

  @override
  String get screensaverOverlayState => 'Состояние';

  @override
  String get screensaverOverlayEntityRequired => 'Выберите сущность.';

  @override
  String get screensaverOverlaySearching => 'Поиск…';

  @override
  String get screensaverOverlayUnreachable => 'Home Assistant недоступен';

  @override
  String get screensaverOverlayNoAnswer => 'Устройство не ответило.';

  @override
  String get settingScreensaverDismissOnFaceTitle =>
      'Прятать при обнаружении лица';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      'Пробуждать экран, когда кто-то смотрит на киоск, а не только при движении. Камера работает только во время заставки. ВНИМАНИЕ: нужно освещённое лицо; в темноте настройте определение движения по расписанию.';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle =>
      'Только при выключенном экране';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      'Держать заставку видимой, когда лицо обнаружено при включённом экране. После выключения экрана определение будит панель. Касание всё равно прячет заставку.';

  @override
  String get settingScreensaverPostponeOnFaceTitle =>
      'Откладывать заставку при обнаружении лица';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      'Откладывать включение заставки, пока кто-то смотрит на киоск. ВНИМАНИЕ: камера работает постоянно, плюс определение лиц и его нагрузка на ЦП.';

  @override
  String get settingFaceSensitivityTitle => 'Чувствительность к лицу';

  @override
  String get settingFaceSensitivityDescription =>
      'Выше: пробуждает от меньших и более дальних лиц. 1 требует лицо близко к экрану; 100 реагирует на любое лицо, различимое камерой.';

  @override
  String get screensaverDetectionFacePage => 'Определение лица';

  @override
  String get screensaverDetectionFaceHint =>
      'Прятать заставку, когда кто-то смотрит';

  @override
  String get screensaverDetectionMotionPrecedence =>
      '«Прятать при движении» включено и имеет приоритет, поэтому определение лица бездействует, пока его не выключат.';

  @override
  String get screensaverDetectionFaceTuning =>
      'Частота кадров, выбор камеры и задержка запуска настраиваются в настройках камеры.';

  @override
  String get screensaverDetectionAndroidUnsupported =>
      'Недоступно на этой версии Android.';

  @override
  String get screensaverDetectionX86Unsupported =>
      'Недоступно на устройствах x86.';

  @override
  String get settingFacePreviewTitle => 'Показывать превью камеры';

  @override
  String get settingFacePreviewDescription =>
      'Показывать маленькое круглое живое превью камеры в углу экрана на несколько секунд, когда лицо будит киоск.';

  @override
  String get settingFacePreviewSecondsTitle => 'Длительность превью';

  @override
  String get settingFacePreviewSecondsDescription =>
      'Как долго превью остаётся на экране.';

  @override
  String get settingFacePreviewScaleTitle => 'Масштаб превью';

  @override
  String get settingFacePreviewScaleDescription =>
      'Масштабируйте превью под размер экрана.';

  @override
  String get settingFacePreviewPositionTitle => 'Позиция превью';

  @override
  String get settingFacePreviewPositionDescription =>
      'В каком углу находится превью.';

  @override
  String get screensaverDetectionPreviewSection => 'Превью камеры';

  @override
  String get settingScreensaverEnabledTitle => 'Заставка';

  @override
  String get settingScreensaverEnabledDescription =>
      'Затемнять или гасить экран после периода бездействия.';

  @override
  String get settingScreensaverTimeoutSecondsTitle => 'Тайм-аут простоя (с)';

  @override
  String get settingScreensaverTimeoutSecondsDescription =>
      'Период бездействия до старта заставки.';

  @override
  String get settingScreensaverFadeTitle => 'Плавное появление и исчезновение';

  @override
  String get settingScreensaverFadeDescription =>
      'Заставка плавно появляется поверх панели и плавно исчезает при закрытии. Не действует для заставок «Медиа Home Assistant», «Веб-сайт» и «Потоки камер».';

  @override
  String get settingScreensaverModeTitle => 'Режим заставки';

  @override
  String get settingScreensaverModeDescription =>
      'Что показывает заставка после тайм-аута. «Затемнение» лишь снижает подсветку, оставляя панель на экране.';

  @override
  String get settingScreensaverPixelShiftTitle => 'Сдвиг пикселей';

  @override
  String get settingScreensaverPixelShiftDescription =>
      'Сдвигать изображение каждую минуту для защиты OLED-панелей. Не для чёрной заставки, у которой пиксели уже выключены.';

  @override
  String get settingScreensaverFollowAnimationScaleTitle =>
      'Следовать настройкам анимации Android';

  @override
  String get settingScreensaverFollowAnimationScaleDescription =>
      'Приостанавливать анимированные заставки, когда анимация Android выключена.';

  @override
  String get settingScreensaverDimLevelTitle => 'Уровень затемнения';

  @override
  String get settingScreensaverDimLevelDescription =>
      'Яркость экрана, пока заставка затемняет.';

  @override
  String get settingScreensaverBrightnessEnabledTitle => 'Яркость заставки';

  @override
  String get settingScreensaverBrightnessEnabledDescription =>
      'Отдельная яркость, пока показывается заставка.';

  @override
  String get settingScreensaverBrightnessLevelTitle => 'Уровень яркости';

  @override
  String get settingScreensaverBrightnessLevelDescription =>
      'Применяется ко всем режимам, кроме «Затемнение» и «Чёрная».';

  @override
  String get settingScreensaverNotificationBrightnessTitle =>
      'Ярче для уведомлений';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      'Снимать затемнение заставки, пока на экране уведомление.';

  @override
  String get settingScreensaverTouchBrightnessSecondsTitle =>
      'Ярче при касании';

  @override
  String get settingScreensaverTouchBrightnessSecondsDescription =>
      'Снимать затемнение заставки на это время после касания, которое её не закрывает. 0: выключено.';

  @override
  String get settingScreensaverScreenOffMinutesTitle => 'Выключать экран через';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Гасит панель дисплея, когда заставка отработала заданное время. 0: держать экран включённым неограниченно. Требуется разрешение администратора устройства.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Пробуждать в заставку';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescriptionSources =>
      'Выберите, что возвращает заставку вместо панели после выключения экрана. Отсчёт «Выключать экран через» начинается заново.';

  @override
  String get screensaverWakeSourcesAll => 'Все';

  @override
  String get screensaverWakeSourceMotion => 'Движение';

  @override
  String get screensaverWakeSourceFace => 'Лицо';

  @override
  String get screensaverWakeSourceProximity => 'Близость';

  @override
  String get screensaverWakeSourcePerson => 'Присутствие';

  @override
  String get screensaverWakeSourcePower => 'Кнопка питания';

  @override
  String get screensaverWakeSourceTouch => 'Касание';

  @override
  String get screensaverWakeSourceTouchRequires =>
      'Требует и «Выключать экран через», и «Использовать чёрный экран вместо этого».';

  @override
  String get screensaverModeDim => 'Затемнение';

  @override
  String get screensaverModeBlack => 'Чёрная';

  @override
  String get screensaverModeClock => 'Часы';

  @override
  String get screensaverModeMedia => 'Медиа Home Assistant';

  @override
  String get screensaverModeLocal => 'Локальные медиа';

  @override
  String get screensaverModeGallery => 'Фотогалерея';

  @override
  String get screensaverModeImmich => 'Медиа Immich';

  @override
  String get screensaverModeWebsite => 'Веб-сайт';

  @override
  String get screensaverModeCamera => 'Потоки камер';

  @override
  String get screensaverDimSection => 'Затемнение';

  @override
  String get screensaverWarningTitle => 'ВНИМАНИЕ: прочитайте!';

  @override
  String get screensaverScreenOffProceed => 'Всё равно выключать экран';

  @override
  String get screensaverAdminMissing =>
      'Не предоставлено, поэтому экран не может выключиться.';

  @override
  String get screensaverAdminMissingRemote =>
      'Нет разрешения администратора устройства';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      'Без него экран не выключить. Диалог выдачи появится на экране планшета.';

  @override
  String get screensaverDimWarning =>
      'ВНИМАНИЕ: «Затемнение» держит панель видимой, поэтому оптимизация «Приостанавливать панель во время заставки» не применяется, и панель продолжает расходовать ЦП, GPU и батарею.';

  @override
  String get screensaverUnavailablePlugin => 'Недоступная заставка плагина';

  @override
  String get screensaverScreenOffWarning =>
      'Когда дисплей действительно выключится, управление возьмёт собственное энергосбережение планшета, и многие модели Android ведут себя в этом состоянии плохо: Wi-Fi засыпает или отключается, сущности Home Assistant становятся недоступными, камера может быть отозвана, а некоторые модели убивают фоновые приложения целиком. Поведение зависит от производителя.\n\nНадёжнее использовать чёрную заставку, оставив эту настройку на 0. Панель выглядит столь же тёмной, а приложение сохраняет полный контроль.';

  @override
  String get settingScreensaverScreenOffBlackTitle =>
      'Использовать чёрный экран вместо этого';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      'Показывать чистый чёрный экран с нулевой яркостью вместо выключения дисплея. Скрывает виджеты и «Сейчас играет». Разрешение администратора устройства не нужно.';

  @override
  String get screensaverModeDashboard => 'Панель Home Assistant';

  @override
  String get settingScreensaverDashboardViewTitle => 'Вид панели';

  @override
  String get settingScreensaverDashboardViewDescription =>
      'Вид панели Home Assistant, который показывает заставка.';

  @override
  String get settingScreensaverDashboardDoubleTapTitle =>
      'Двойное касание для закрытия';

  @override
  String get settingScreensaverDashboardDoubleTapDescription =>
      'Одиночные касания взаимодействуют с панелью вместо закрытия.';

  @override
  String get settingScreensaverDashboardKioskTitle =>
      'Переопределить режим киоска HA';

  @override
  String get settingScreensaverDashboardKioskDescription =>
      'Выберите, что скрывает заставка, отдельно от режима киоска HA.';

  @override
  String get settingScreensaverDashboardHideHeaderTitle => 'Скрыть заголовок';

  @override
  String get settingScreensaverDashboardHideHeaderDescription =>
      'Скрыть панель инструментов и вкладки видов на заставке.';

  @override
  String get settingScreensaverDashboardHideSidebarTitle =>
      'Скрыть боковую панель';

  @override
  String get settingScreensaverDashboardHideSidebarDescription =>
      'Скрыть боковую панель навигации на заставке.';

  @override
  String get screensaverDashboardSection => 'Заставка «Панель Home Assistant»';

  @override
  String get screensaverModeUrl => 'URL изображения';

  @override
  String get screensaverCalendarSection => 'Заставка «Календарь»';

  @override
  String get settingScreensaverCalendarViewTitle => 'Вид календаря';

  @override
  String get settingScreensaverCalendarViewDescription =>
      'Вид календаря, с которым открывается заставка.';

  @override
  String get settingScreensaverGlanceScaleTitle => 'Масштаб ряда';

  @override
  String get settingScreensaverGlanceScaleDescription =>
      'Масштабируйте ряд под размер экрана.';

  @override
  String get settingScreensaverGlanceFontTitle => 'Гарнитура';

  @override
  String get settingScreensaverGlanceFontDescription =>
      'Шрифт, которым рисуется ряд.';

  @override
  String get settingScreensaverGlanceFontWeightTitle => 'Насыщенность шрифта';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      'Насколько жирно рисуется текст ряда. По умолчанию собственная насыщенность строк: обычные названия, полужирные значения.';

  @override
  String get settingScreensaverGlanceHideNamesTitle => 'Скрыть названия';

  @override
  String get settingScreensaverGlanceHideNamesDescription =>
      'Показывать только значок и значение, значение крупнее.';

  @override
  String get settingScreensaverGlanceBwIconsTitle => 'Монохромные значки';

  @override
  String get settingScreensaverGlanceBwIconsDescription =>
      'Держать каждый значок в нейтральном сером вместо цвета состояния.';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => 'Плавающий текст';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      'Показывать сущности плавающим текстом вместо чипов.';

  @override
  String get screensaverOverlayAppearance => 'Внешний вид';

  @override
  String get settingScreensaverGlanceEnabledTitle => 'Сводка';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      'Показывать ряд состояний сущностей Home Assistant на заставке.';

  @override
  String get settingScreensaverGlanceEntitiesTitle => 'Сущности';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      'До четырёх сущностей, каждая с необязательным собственным названием.';

  @override
  String get settingScreensaverGlanceNowPlayingTitle =>
      'Показывать на «Сейчас играет»';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      'Показывать ряд на полноэкранном виде «Сейчас играет». Скрывается, пока показан текст песни.';

  @override
  String get screensaverOverlayShowing => 'Показываются';

  @override
  String get screensaverOverlayNone => 'Пока пусто';

  @override
  String get screensaverOverlayGlancePage => 'Сводка';

  @override
  String get screensaverOverlayGlanceHint => 'Сущности поверх заставки';

  @override
  String get glanceUnavailable => 'Недоступно';

  @override
  String get glanceUnknown => 'Неизвестно';

  @override
  String get settingScreensaverImmichUrlTitle => 'Адрес сервера';

  @override
  String get settingScreensaverImmichUrlDescription =>
      'Адрес вашего сервера Immich с его портом.';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'API-ключ';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      'Создаётся в Immich: Настройки аккаунта, затем API Keys.';

  @override
  String get screensaverMediaImmichPage => 'Заставка «Медиа Immich»';

  @override
  String get screensaverMediaImmichHint =>
      'Сервер, медиа, слайд-шоу, метаданные, фильтры';

  @override
  String get screensaverMediaServerConnection => 'Соединение с сервером';

  @override
  String get screensaverMediaValidateFailedLog =>
      'Проверка не удалась. Подробности о сбойном вызове смотрите в журнале приложения.';

  @override
  String get screensaverMediaValidateFailed => 'Проверка не удалась.';

  @override
  String get screensaverMediaNoAnswer => 'Устройство не ответило.';

  @override
  String get screensaverMediaAddressFirst => 'Сначала введите адрес сервера.';

  @override
  String get screensaverMediaKeyFirst => 'Сначала введите API-ключ.';

  @override
  String get screensaverMediaBadAddress =>
      'Адрес сервера не является корректным URL.';

  @override
  String get screensaverMediaKeyRejected => 'API-ключ отклонён.';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'У API-ключа нет разрешения $scope.';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'У API-ключа нет разрешения: $error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return 'Сервер ответил $status: $error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return 'Не удалось достучаться до $url.';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return 'Не удалось связаться с сервером: $error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => 'Люди';

  @override
  String get settingScreensaverImmichPeopleDescription =>
      'Показывать только медиа с любым из этих людей.';

  @override
  String get settingScreensaverImmichExcludePeopleTitle => 'Исключить людей';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      'Пропускать медиа с любым из этих людей.';

  @override
  String get settingScreensaverImmichTagsTitle => 'Метки';

  @override
  String get settingScreensaverImmichTagsDescription =>
      'Показывать только медиа с любой из этих меток.';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => 'Исключить метки';

  @override
  String get settingScreensaverImmichExcludeTagsDescription =>
      'Пропускать медиа с любой из этих меток.';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => 'Только избранное';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      'Показывать только медиа, отмеченные избранным.';

  @override
  String get settingScreensaverImmichTakenWithinTitle => 'Снято за период';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      'Показывать только медиа, снятые за этот период.';

  @override
  String get settingScreensaverImmichTakenFromTitle => 'От';

  @override
  String get settingScreensaverImmichTakenFromDescription =>
      'Пропускать медиа, снятые до этой даты.';

  @override
  String get settingScreensaverImmichTakenToTitle => 'До';

  @override
  String get settingScreensaverImmichTakenToDescription =>
      'Пропускать медиа, снятые после этой даты. Сама эта дата включается.';

  @override
  String get screensaverMediaFilters => 'Фильтры';

  @override
  String get screensaverMediaAnyone => 'Кто угодно';

  @override
  String get screensaverMediaAnyoneDevice => 'Кто угодно.';

  @override
  String get screensaverMediaNoOne => 'Никто';

  @override
  String get screensaverMediaNoOneDevice => 'Никто.';

  @override
  String get screensaverMediaAny => 'Любые';

  @override
  String get screensaverMediaAnyDevice => 'Любые.';

  @override
  String get screensaverMediaNoTagsChosen => 'Без меток';

  @override
  String get screensaverMediaNoTagsChosenDevice => 'Без меток.';

  @override
  String get screensaverMediaNoPeople =>
      'Именованных людей пока нет. Сначала назовите их в Immich.';

  @override
  String get screensaverMediaNoTags =>
      'Меток пока нет. Сначала создайте их в Immich.';

  @override
  String get screensaverMediaPeopleFailed => 'Не удалось получить список людей';

  @override
  String get screensaverMediaTagsFailed => 'Не удалось получить список меток';

  @override
  String get screensaverMediaHidden => 'Скрыто';

  @override
  String get screensaverMediaAnyTime => 'В любое время';

  @override
  String get screensaverMediaPastMonth => 'За месяц';

  @override
  String get screensaverMediaPast3Months => 'За 3 месяца';

  @override
  String get screensaverMediaPastYear => 'За год';

  @override
  String get screensaverMediaPast2Years => 'За 2 года';

  @override
  String get screensaverMediaPast5Years => 'За 5 лет';

  @override
  String get screensaverMediaPast10Years => 'За 10 лет';

  @override
  String get screensaverMediaSince => 'Начиная с';

  @override
  String get screensaverMediaTimeframe => 'Период';

  @override
  String get screensaverMediaToday => 'Сегодня';

  @override
  String get screensaverMediaDateFormat => 'Используйте формат ГГГГ-ММ-ДД.';

  @override
  String get screensaverMediaNotDate => 'Это не дата.';

  @override
  String get settingScreensaverImmichMetadataTitle => 'Показывать метаданные';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      'Альбом, дата, камера и место поверх медиа.';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => 'Название альбома';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription =>
      'Показывать, из какого альбома фото.';

  @override
  String get settingScreensaverImmichMetadataDateTitle => 'Дата съёмки';

  @override
  String get settingScreensaverImmichMetadataDateDescription =>
      'Показывать, когда снято фото.';

  @override
  String get settingScreensaverImmichMetadataCameraTitle => 'Детали камеры';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      'Показывать фокусное расстояние, диафрагму и ISO.';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => 'Место';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      'Показывать, где снято фото.';

  @override
  String get settingScreensaverImmichMetadataDescriptionTitle => 'Описание';

  @override
  String get settingScreensaverImmichMetadataDescriptionDescription =>
      'Показывать описание фото внизу экрана.';

  @override
  String get settingScreensaverImmichMetadataPositionTitle =>
      'Позиция метаданных';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      'В каком углу находятся детали.';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle => 'Тень текста';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      'Добавить тень тексту метаданных для читаемости на фото.';

  @override
  String get settingScreensaverImmichMetadataScaleTitle => 'Масштаб текста';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      'Масштабируйте детали фото под размер экрана.';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle => 'Сила виньетки';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      'Затемнение позади деталей для читаемости на светлых фото. 0 выключает.';

  @override
  String get screensaverMediaMetadata => 'Метаданные';

  @override
  String get screensaverMediaTopLeft => 'Верхний левый';

  @override
  String get screensaverMediaTopRight => 'Верхний правый';

  @override
  String get screensaverMediaBottomLeft => 'Нижний левый';

  @override
  String get screensaverMediaBottomRight => 'Нижний правый';

  @override
  String get settingScreensaverImmichIntervalTitle => 'Секунд на изображение';

  @override
  String get settingScreensaverImmichShuffleTitle => 'Перемешивание';

  @override
  String get settingScreensaverImmichShuffleDescription =>
      'Циклически показывать медиа в случайном порядке.';

  @override
  String get settingScreensaverImmichTransitionTitle => 'Переход';

  @override
  String get settingScreensaverImmichTransitionDescription =>
      'Как один элемент сменяется следующим.';

  @override
  String get settingScreensaverImmichFillTitle => 'Заполнить экран';

  @override
  String get settingScreensaverImmichFillDescription =>
      '«Выкл» держит всё фото между чёрными полосами. «Умно» увеличивает фото, близкие по форме к экрану, оформляя остальные поверх размытого фона. «Всегда» увеличивает каждое фото, обрезая не влезающее.';

  @override
  String get settingScreensaverImmichPairPortraitTitle =>
      'Парные портретные фото';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      'Показывать два портретных фото бок о бок, чтобы заполнить экран.';

  @override
  String get settingScreensaverImmichPairLandscapeTitle =>
      'Парные альбомные фото';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      'Показывать два альбомных фото одно над другим, чтобы заполнить портретный экран.';

  @override
  String get settingScreensaverImmichEdgeTapsTitle =>
      'Касание краёв для смены слайдов';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      'Касание левой или правой пятой части экрана показывает предыдущий или следующий слайд вместо закрытия.';

  @override
  String get screensaverMediaSlideshow => 'Слайд-шоу';

  @override
  String get settingScreensaverImmichAlbumTitle => 'Источник медиа';

  @override
  String get settingScreensaverImmichAlbumDescription =>
      'Вся библиотека или выбранные вами альбомы.';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => 'Только фото';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription =>
      'Пропускать видео в слайд-шоу.';

  @override
  String get settingScreensaverImmichCacheTitle => 'Кэшировать медиа локально';

  @override
  String get settingScreensaverImmichCacheDescription =>
      'Держать копии на устройстве, чтобы изображения грузились мгновенно.';

  @override
  String get settingScreensaverImmichCacheMaxTitle => 'Размер кэша (элементов)';

  @override
  String get settingScreensaverImmichCacheMaxDescription =>
      'Самые старые элементы удаляются при заполнении кэша.';

  @override
  String get screensaverMediaAll => 'Все медиа';

  @override
  String get screensaverMediaAllDevice => 'Все медиа.';

  @override
  String get screensaverMediaNoAlbums =>
      'Альбомов пока нет. Сначала создайте в Immich.';

  @override
  String get screensaverMediaAlbumsFailed =>
      'Не удалось получить список альбомов';

  @override
  String screensaverMediaListError(String error) {
    return 'Не удалось получить список: $error';
  }

  @override
  String get screensaverMediaListingFailed => 'не удалось получить список';

  @override
  String screensaverMediaItems(String count) {
    return 'Элементов: $count';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return 'В кэше: $count, $size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => 'Виды камер';

  @override
  String get settingScreensaverCameraViewsDescription =>
      'Виды камер, которые показывает заставка, в этом порядке.';

  @override
  String get settingScreensaverCameraViewSecondsTitle => 'Секунд на вид камер';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      'Как долго каждый вид остаётся на экране до следующего. С одним видом ничего не меняется.';

  @override
  String get settingScreensaverCameraMuteTitle => 'Заглушить все виды';

  @override
  String get settingScreensaverCameraMuteDescription =>
      'Держит каждый вид беззвучным, даже одиночную камеру.';

  @override
  String get screensaverMediaCameraPage => 'Заставка «Потоки камер»';

  @override
  String get screensaverMediaCameraHint =>
      'Виды для показа, секунд на вид, звук';

  @override
  String get screensaverMediaNoCameras =>
      'Ни в одном виде камер пока нет камер. Добавьте в разделе «Потоки камер».';

  @override
  String get screensaverMediaNoCamerasRemote =>
      'Ни в одном виде камер пока нет камер';

  @override
  String get screensaverMediaAddCameras => 'Добавьте в разделе «Потоки камер».';

  @override
  String get screensaverMediaNoViews =>
      'Пока пусто. Выберите виды камер, по которым ходит заставка.';

  @override
  String get screensaverMediaRotation => 'В ротации (перетащите для порядка)';

  @override
  String get screensaverMediaAvailable => 'Доступные';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count камера';
  }

  @override
  String screensaverMediaCameras(String count) {
    return 'Камер: $count';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return 'Позиция $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => 'Без перехода';

  @override
  String get screensaverMediaTransitionFade => 'Кроссфейд';

  @override
  String get screensaverMediaTransitionSlide => 'Сдвиг';

  @override
  String get screensaverMediaTransitionZoom => 'Наезд';

  @override
  String get screensaverMediaTransitionKenBurns => 'Ken Burns';

  @override
  String get screensaverMediaTransitionRandom => 'Случайный';

  @override
  String get screensaverMediaFillOff => 'Выкл';

  @override
  String get screensaverMediaFillSmart => 'Умно';

  @override
  String get screensaverMediaFillAlways => 'Всегда';

  @override
  String get settingScreensaverVideoLengthTitle => 'Длительность видео';

  @override
  String get settingScreensaverVideoLengthDescription =>
      'Как долго проигрывается каждое видео до следующего.';

  @override
  String get screensaverMediaVideoLengthFull => 'Видео целиком';

  @override
  String get screensaverMediaVideoLengthInterval => 'Как у фото';

  @override
  String get settingScreensaverImageIntervalDescription =>
      'Как долго показывается каждое изображение до следующего.';

  @override
  String get settingScreensaverPhotoIntervalDescription =>
      'Как долго показывается каждое фото до следующего.';

  @override
  String get settingScreensaverGalleryItemsTitle => 'Фотографии';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'Фото и видео, по которым ходит заставка. Выбираются из галереи на устройстве; повторный выбор заменяет подборку.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Секунд на фото';

  @override
  String get settingScreensaverGalleryShuffleTitle => 'Перемешивание';

  @override
  String get settingScreensaverGalleryShuffleDescription =>
      'Циклически показывать подборку в случайном порядке.';

  @override
  String get settingScreensaverGalleryTransitionTitle => 'Переход';

  @override
  String get settingScreensaverGalleryTransitionDescription =>
      'Как одно фото сменяется следующим.';

  @override
  String get settingScreensaverGalleryFillTitle => 'Заполнить экран';

  @override
  String get settingScreensaverGalleryFillDescription =>
      '«Выкл» держит всё фото между чёрными полосами. «Умно» увеличивает фото, близкие по форме к экрану, оформляя остальные поверх размытого фона. «Всегда» увеличивает каждое фото, обрезая не влезающее.';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle =>
      'Касание краёв для смены слайдов';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      'Касание левой или правой пятой части экрана показывает предыдущий или следующий слайд вместо закрытия.';

  @override
  String get screensaverMediaGalleryPage => 'Заставка «Фотогалерея»';

  @override
  String get screensaverMediaGalleryHint =>
      'Фото, тайминг, перемешивание, переход';

  @override
  String get screensaverMediaLoadingPhotos => 'Загрузка фото…';

  @override
  String screensaverMediaCopying(String index, String total) {
    return 'Копирование фото $index из $total…';
  }

  @override
  String get screensaverMediaCopyFailed => 'Не удалось скопировать фото';

  @override
  String get screensaverMediaSmallerSelection => 'Попробуйте меньшую подборку.';

  @override
  String get screensaverMediaNoPhotos => 'Фото не выбраны';

  @override
  String screensaverMediaSelected(String count) {
    return 'Выбрано: $count';
  }

  @override
  String get screensaverMediaPickOnDevice =>
      'Ничего не выбрано. Выберите на устройстве.';

  @override
  String get settingScreensaverMediaIdTitle => 'Источник медиа';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Медиаэлемент, папка или камера Home Assistant. Используйте «Обзор» для выбора.';

  @override
  String get settingScreensaverMediaIntervalTitle => 'Секунд на изображение';

  @override
  String get settingScreensaverMediaShuffleTitle => 'Перемешивание';

  @override
  String get settingScreensaverMediaShuffleDescription =>
      'Проигрывать папку в случайном порядке.';

  @override
  String get settingScreensaverMediaRecursiveTitle => 'Включая подпапки';

  @override
  String get settingScreensaverMediaRecursiveDescription =>
      'Спускаться в подпапки при выборе папки.';

  @override
  String get settingScreensaverMediaTransitionTitle => 'Переход';

  @override
  String get settingScreensaverMediaTransitionDescription =>
      'Как один элемент сменяется следующим.';

  @override
  String get settingScreensaverMediaFillTitle => 'Заполнить экран';

  @override
  String get settingScreensaverMediaFillDescription =>
      '«Выкл» держит всё фото между чёрными полосами. «Умно» увеличивает фото, близкие по форме к экрану, оформляя остальные поверх размытого фона. «Всегда» увеличивает каждое фото, обрезая не влезающее.';

  @override
  String get settingScreensaverMediaEdgeTapsTitle =>
      'Касание краёв для смены слайдов';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      'Касание левой или правой пятой части экрана показывает предыдущий или следующий слайд вместо закрытия.';

  @override
  String get settingScreensaverMediaMetadataTitle => 'Показывать метаданные';

  @override
  String get settingScreensaverMediaMetadataDescription =>
      'Дата и детали камеры поверх фото.';

  @override
  String get settingScreensaverMediaMetadataDateTitle => 'Дата съёмки';

  @override
  String get settingScreensaverMediaMetadataDateDescription =>
      'Показывать, когда снято фото.';

  @override
  String get settingScreensaverMediaMetadataCameraTitle => 'Детали камеры';

  @override
  String get settingScreensaverMediaMetadataCameraDescription =>
      'Показывать фокусное расстояние, диафрагму и ISO.';

  @override
  String get settingScreensaverMediaMetadataPositionTitle =>
      'Позиция метаданных';

  @override
  String get settingScreensaverMediaMetadataPositionDescription =>
      'В каком углу находятся детали.';

  @override
  String get settingScreensaverMediaMetadataTextShadowTitle => 'Тень текста';

  @override
  String get settingScreensaverMediaMetadataTextShadowDescription =>
      'Добавить тень тексту метаданных для читаемости на фото.';

  @override
  String get settingScreensaverMediaMetadataScaleTitle => 'Масштаб текста';

  @override
  String get settingScreensaverMediaMetadataScaleDescription =>
      'Масштабируйте детали фото под размер экрана.';

  @override
  String get settingScreensaverMediaVignetteStrengthTitle => 'Сила виньетки';

  @override
  String get settingScreensaverMediaVignetteStrengthDescription =>
      'Затемнение позади деталей для читаемости на светлых фото. 0 выключает.';

  @override
  String get screensaverMediaHaMetadata => 'Метаданные «Медиа Home Assistant»';

  @override
  String get screensaverMediaHaPage => 'Заставка «Медиа Home Assistant»';

  @override
  String get screensaverMediaHaPageHint =>
      'Источник медиа, тайминг, перемешивание, заполнение, метаданные';

  @override
  String get screensaverMediaChoose => 'Выберите медиа';

  @override
  String get screensaverMediaRoot => 'Медиа';

  @override
  String get screensaverMediaHaUnavailable =>
      'Home Assistant недоступен или токен отсутствует.';

  @override
  String get screensaverMediaEmpty => 'Здесь пусто.';

  @override
  String get screensaverMediaUseFolder => 'Использовать эту папку';

  @override
  String get screensaverMediaFolder => 'папка';

  @override
  String get screensaverMediaCamera => 'камера';

  @override
  String get screensaverMediaItem => 'элемент';

  @override
  String get screensaverMediaBrowseFailed => 'не удалось выполнить обзор';

  @override
  String screensaverMediaBrowseError(String error) {
    return 'Не удалось выполнить обзор: $error';
  }

  @override
  String get screensaverMediaNotSet => 'Не задано';

  @override
  String get settingScreensaverLocalFolderTitle => 'Локальная папка';

  @override
  String get settingScreensaverLocalFolderDescription =>
      'Папка на этом устройстве, чьи фото и видео прокручивает заставка. Выбирается на устройстве; путь можно ввести здесь и удалённо.';

  @override
  String get settingScreensaverLocalIntervalTitle => 'Секунд на фото';

  @override
  String get settingScreensaverLocalShuffleTitle => 'Перемешивание';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      'Прокручивать папку в случайном порядке вместо порядка по имени.';

  @override
  String get settingScreensaverLocalRecursiveTitle => 'Включая подпапки';

  @override
  String get settingScreensaverLocalRecursiveDescription =>
      'Также прокручивать фото и видео внутри подпапок.';

  @override
  String get settingScreensaverLocalTransitionTitle => 'Переход';

  @override
  String get settingScreensaverLocalTransitionDescription =>
      'Как одно фото сменяется следующим.';

  @override
  String get settingScreensaverLocalFillTitle => 'Заполнить экран';

  @override
  String get settingScreensaverLocalFillDescription =>
      '«Выкл» держит всё фото между чёрными полосами. «Умно» увеличивает фото, близкие по форме к экрану, оформляя остальные поверх размытого фона. «Всегда» увеличивает каждое фото, обрезая не влезающее.';

  @override
  String get settingScreensaverLocalEdgeTapsTitle =>
      'Касание краёв для смены слайдов';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      'Касание левой или правой пятой части экрана показывает предыдущий или следующий слайд вместо закрытия.';

  @override
  String get settingScreensaverLocalMetadataTitle => 'Показывать метаданные';

  @override
  String get settingScreensaverLocalMetadataDescription =>
      'Дата и детали камеры поверх фото.';

  @override
  String get settingScreensaverLocalMetadataDateTitle => 'Дата съёмки';

  @override
  String get settingScreensaverLocalMetadataDateDescription =>
      'Показывать, когда снято фото.';

  @override
  String get settingScreensaverLocalMetadataCameraTitle => 'Детали камеры';

  @override
  String get settingScreensaverLocalMetadataCameraDescription =>
      'Показывать фокусное расстояние, диафрагму и ISO.';

  @override
  String get settingScreensaverLocalMetadataPositionTitle =>
      'Позиция метаданных';

  @override
  String get settingScreensaverLocalMetadataPositionDescription =>
      'В каком углу находятся детали.';

  @override
  String get settingScreensaverLocalMetadataTextShadowTitle => 'Тень текста';

  @override
  String get settingScreensaverLocalMetadataTextShadowDescription =>
      'Добавить тень тексту метаданных для читаемости на фото.';

  @override
  String get settingScreensaverLocalMetadataScaleTitle => 'Масштаб текста';

  @override
  String get settingScreensaverLocalMetadataScaleDescription =>
      'Масштабируйте детали фото под размер экрана.';

  @override
  String get settingScreensaverLocalVignetteStrengthTitle => 'Сила виньетки';

  @override
  String get settingScreensaverLocalVignetteStrengthDescription =>
      'Затемнение позади деталей для читаемости на светлых фото. 0 выключает.';

  @override
  String get screensaverMediaLocalMetadata => 'Метаданные «Локальные медиа»';

  @override
  String get screensaverMediaLocalPage => 'Заставка «Локальные медиа»';

  @override
  String get screensaverMediaLocalPageHint =>
      'Папка, тайминг, перемешивание, переход, метаданные';

  @override
  String get settingScreensaverUrlImageDescription =>
      'Адрес изображения, которое устройство заново скачивает для каждого слайда.';

  @override
  String get settingScreensaverUrlIntervalDescription =>
      'Как долго показывается каждое фото до загрузки следующего.';

  @override
  String get screensaverMediaUrlPage => 'Заставка «URL изображения»';

  @override
  String get screensaverMediaUrlPageHint => 'URL, тайминг, переход, метаданные';

  @override
  String get screensaverMediaUrlMetadata => 'Метаданные «URL изображения»';

  @override
  String get settingScreensaverDismissOnMotionTitle => 'Прятать при движении';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      'Следить за камерой, пока заставка активна, и пробуждать экран, когда кто-то приближается. Камера работает только во время заставки.';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle =>
      'Только при выключенном экране';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      'Держать заставку видимой, когда движение обнаружено при включённом экране. После выключения экрана определение будит панель. Касание всё равно прячет заставку.';

  @override
  String get settingScreensaverPostponeOnMotionTitle =>
      'Откладывать заставку при движении';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      'Откладывать включение заставки при обнаружении движения. ВНИМАНИЕ: камера работает постоянно.';

  @override
  String get screensaverDetectionMotionPage => 'Определение движения';

  @override
  String get screensaverDetectionMotionHint =>
      'Прятать или откладывать заставку при движении';

  @override
  String get screensaverDetectionMotionTuning =>
      'Определение движения настраивается в настройках камеры.';

  @override
  String get settingMotionUseEntityTitle =>
      'Использовать сущность Home Assistant';

  @override
  String get settingMotionUseEntityDescription =>
      'Определять движение по датчику Home Assistant вместо камеры.';

  @override
  String get settingMotionEntityTitle => 'Сущность датчика движения';

  @override
  String get settingMotionEntityDescription =>
      'Датчик занятости, движения или присутствия Home Assistant, за которым нужно следить.';

  @override
  String get screensaverDetectionExternalMotionHeading =>
      'Внешний датчик движения';

  @override
  String get settingScreensaverDismissOnPersonTitle =>
      'Прятать при присутствии';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      'Читать датчик присутствия устройства, пока заставка активна, и пробуждать экран, когда кто-то перед ним. Нужно разрешение на доступ к журналам ниже.';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle =>
      'Только при выключенном экране';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      'Держать заставку видимой, когда кто-то появился при включённом экране. После выключения экрана определение будит панель. Касание всё равно прячет заставку.';

  @override
  String get settingScreensaverPostponeOnPersonTitle =>
      'Откладывать заставку при присутствии';

  @override
  String get settingScreensaverPostponeOnPersonDescription =>
      'Откладывать включение заставки, пока кто-то перед устройством.';

  @override
  String get screensaverDetectionPersonPage => 'Определение присутствия';

  @override
  String get screensaverDetectionPersonHint =>
      'Прятать или откладывать заставку по датчику присутствия устройства';

  @override
  String get screensaverDetectionOccupancy => 'Присутствие';

  @override
  String get screensaverDetectionStatusUnavailable => 'Статус недоступен.';

  @override
  String get screensaverDetectionOff => 'Выключено.';

  @override
  String get screensaverDetectionStarting => 'Запуск…';

  @override
  String get screensaverDetectionWaiting =>
      'Ожидание первого сигнала. Датчик сообщает каждые 30 с, пока кто-то в поле зрения.';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return 'Последний сигнал $ago.';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return '$count с назад';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return '$count мин назад';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return '$count ч назад';
  }

  @override
  String get screensaverDetectionDetected => 'Обнаружено';

  @override
  String get screensaverDetectionClear => 'Не обнаружено';

  @override
  String get screensaverDetectionPermissions =>
      'Необходимые системные разрешения';

  @override
  String get screensaverDetectionLogAccess => 'Доступ к журналам';

  @override
  String get screensaverDetectionChecking => 'Проверка…';

  @override
  String get screensaverDetectionReadable =>
      'Датчик присутствия устройства доступен для чтения.';

  @override
  String get screensaverDetectionRestartRequired =>
      'Предоставлено. Перезапустите Kiosk Satellite, чтобы применить.';

  @override
  String get screensaverDetectionGrantHelp =>
      'Это разрешение выдаётся только через ADB. Полная команда в документе Meta Portal. Затем перезапустите Kiosk Satellite.';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      'Это разрешение выдаётся только через ADB. Ниже полная команда, готовая к копированию. Затем перезапустите Kiosk Satellite.';

  @override
  String get screensaverDetectionGranted => 'Предоставлено';

  @override
  String get screensaverDetectionMissing => 'Отсутствует';

  @override
  String get screensaverDetectionRestart => 'Перезапустить';

  @override
  String get screensaverDetectionRestartRemote => 'Перезапустить на устройстве';

  @override
  String get screensaverDetectionLogRestart =>
      'Доступ к журналам предоставлен, но вступает в силу после перезапуска Kiosk Satellite.';

  @override
  String get screensaverDetectionLogMissing =>
      'Доступ к журналам не предоставлен.';

  @override
  String get settingScreensaverDismissOnProximityTitle =>
      'Прятать при близости';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      'Следить за датчиком близости, пока заставка активна, и пробуждать экран, когда что-то приближается к устройству. Устройство только с сенсорами для звонков («palm», «touch») не подойдёт.';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle =>
      'Только при выключенном экране';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      'Держать заставку видимой, когда что-то приближается при включённом экране. После выключения экрана определение будит панель. Касание всё равно прячет заставку.';

  @override
  String get settingScreensaverPostponeOnProximityTitle =>
      'Откладывать заставку при близости';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      'Откладывать включение заставки, пока что-то близко к датчику.';

  @override
  String get screensaverDetectionProximityPage => 'Определение близости';

  @override
  String get screensaverDetectionProximityHint =>
      'Прятать или откладывать заставку по датчику близости';

  @override
  String get screensaverDetectionNoProximity =>
      'Недоступно на этом устройстве: нет датчика близости.';

  @override
  String get screensaverDetectionSensor => 'Датчик';

  @override
  String get screensaverDetectionSensorHelp =>
      'Что устройство сообщает как датчик близости. Сенсор для звонков с именем «palm» или «touch» не подойдёт.';

  @override
  String get settingScreensaverScheduleEnabledTitle =>
      'Включить заставки по расписанию';

  @override
  String get settingScreensaverScheduleEnabledDescription =>
      'Переключаться на другую заставку в заданное время суток.';

  @override
  String get settingScreensaverScheduleTitle => 'Время переключения';

  @override
  String get settingScreensaverScheduleDescription =>
      'Каждая отметка времени переключает заставку с этого момента.';

  @override
  String get screensaverScheduleSection => 'Заставки по расписанию';

  @override
  String get screensaverTime => 'Время';

  @override
  String get screensaverAddTime => 'Добавить время';

  @override
  String get screensaverRemoveTime => 'Убрать время';

  @override
  String get screensaverNoTimes => 'Время пока не задано';

  @override
  String get screensaverTimeHelp => 'Заставка с этого времени и далее.';

  @override
  String get screensaverPickTime => 'Выберите время.';

  @override
  String get screensaverDefault => 'По умолчанию';

  @override
  String get screensaverOn => 'Вкл';

  @override
  String get screensaverOff => 'Выкл';

  @override
  String get screensaverBrightness => 'Яркость';

  @override
  String get screensaverBrightnessFollow =>
      'Следует настройке «Яркость заставки».';

  @override
  String get screensaverBrightnessExceptBlack =>
      'Применяется ко всем режимам, кроме «Чёрная».';

  @override
  String get screensaverScreenOffFollow =>
      'Следует настройке «Выключать экран через».';

  @override
  String get screensaverScreenOnHours => 'Держит экран включённым в эти часы.';

  @override
  String get screensaverScreenOffHelp =>
      'Гасит дисплей, когда заставка отработала это время. Требуется разрешение администратора устройства.';

  @override
  String get screensaverScreenOffNever => 'Экран не выключается';

  @override
  String get screensaverMotion => 'Прятать при движении';

  @override
  String get screensaverFace => 'Прятать при обнаружении лица';

  @override
  String get screensaverProximity => 'Прятать при близости';

  @override
  String get screensaverPerson => 'Прятать при присутствии';

  @override
  String get screensaverWidgets => 'Виджеты';

  @override
  String get screensaverGlance => 'Сводка';

  @override
  String get screensaverNowPlaying =>
      'Показывать «Сейчас играет» рядом с заставкой';

  @override
  String get screensaverNowPlayingHelp =>
      '«По умолчанию» следует глобальной раскладке. «Вкл» использует общую раскладку, когда «Сейчас играет» включён. «Выкл» скрывает «Сейчас играет» в эти часы.';

  @override
  String get screensaverCameraRequired =>
      'Требуется камера. Сначала включите её в настройках камеры.';

  @override
  String get screensaverNotAvailable => 'Недоступно на этом устройстве.';

  @override
  String get screensaverSummaryMotionOn => 'Движение вкл';

  @override
  String get screensaverSummaryMotionOff => 'Движение выкл';

  @override
  String get screensaverSummaryFaceOn => 'Лицо вкл';

  @override
  String get screensaverSummaryFaceOff => 'Лицо выкл';

  @override
  String get screensaverSummaryProximityOn => 'Близость вкл';

  @override
  String get screensaverSummaryProximityOff => 'Близость выкл';

  @override
  String get screensaverSummaryPersonOn => 'Присутствие вкл';

  @override
  String get screensaverSummaryPersonOff => 'Присутствие выкл';

  @override
  String get screensaverSummaryWidgetsOn => 'Виджеты вкл';

  @override
  String get screensaverSummaryWidgetsOff => 'Виджеты выкл';

  @override
  String get screensaverSummaryGlanceOn => '«Сводка» вкл';

  @override
  String get screensaverSummaryGlanceOff => '«Сводка» выкл';

  @override
  String get screensaverSummaryNowPlayingOn => '«Сейчас играет» вкл';

  @override
  String get screensaverSummaryNowPlayingOff => '«Сейчас играет» выкл';

  @override
  String screensaverBrightnessPercent(String percent) {
    return 'Яркость $percent%';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return 'Экран выключится через $minutes мин';
  }

  @override
  String get screensaverWeatherMood => 'Погода';

  @override
  String get screensaverWeatherMoodPage => 'Заставка «Погода»';

  @override
  String get screensaverWeatherMoodSummary =>
      'Сущность погоды, молнии, предпросмотр';

  @override
  String get settingScreensaverWeatherEntityTitle => 'Сущность погоды';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      'Сущность погоды Home Assistant, управляющая анимированной сценой. День, рассвет/закат и ночь следуют sun.sun, с местным временем как запасным вариантом.';

  @override
  String get settingScreensaverWeatherLightningTitle => 'Вспышки молний';

  @override
  String get settingScreensaverWeatherLightningDescription =>
      'Показывать удары молний и вспышки облаков во время грозы.';

  @override
  String get screensaverWeatherMoodSelectEntity =>
      'Выберите сущность погоды в «Настройки > Заставка > Погода».';

  @override
  String get screensaverWeatherPreviewGroup => 'Предпросмотр погоды';

  @override
  String get settingScreensaverWeatherPreviewTitle =>
      'Включить предпросмотр погоды';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      'Показывать выбранную сцену вместо живой погоды. Выключите, чтобы снова следовать Home Assistant.';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => 'Тип погоды';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      'Анимированная сцена погоды для предпросмотра.';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle => 'Время суток';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      'Выберите дневную, рассветную/закатную или ночную версию сцены.';

  @override
  String get screensaverWeatherPreviewSunny => 'Ясно';

  @override
  String get screensaverWeatherPreviewPartlycloudy => 'Переменная облачность';

  @override
  String get screensaverWeatherPreviewCloudy => 'Облачно';

  @override
  String get screensaverWeatherPreviewRainy => 'Дождь';

  @override
  String get screensaverWeatherPreviewPouring => 'Ливень';

  @override
  String get screensaverWeatherPreviewSnowy => 'Снег';

  @override
  String get screensaverWeatherPreviewSnowyRainy => 'Снег с дождём';

  @override
  String get screensaverWeatherPreviewFog => 'Туман';

  @override
  String get screensaverWeatherPreviewHail => 'Град';

  @override
  String get screensaverWeatherPreviewLightning => 'Молния';

  @override
  String get screensaverWeatherPreviewLightningRainy => 'Молния с дождём';

  @override
  String get screensaverWeatherPreviewWindy => 'Ветер';

  @override
  String get screensaverWeatherPreviewWindyVariant => 'Ветер с облаками';

  @override
  String get screensaverWeatherPreviewExceptional => 'Исключительная погода';

  @override
  String get screensaverWeatherPreviewDay => 'День';

  @override
  String get screensaverWeatherPreviewNight => 'Ночь';

  @override
  String get settingScreensaverWeatherClockTitle => 'Включить часы';

  @override
  String get settingScreensaverWeatherClockDescription =>
      'Показывать цифровые часы поверх сцены погоды.';

  @override
  String get screensaverWeatherTextShadowDescription =>
      'Добавить тень тексту для читаемости поверх сцены погоды.';

  @override
  String get screensaverWeatherBarGroup => 'Погодная информация';

  @override
  String get settingScreensaverWeatherBarTitle => 'Включить панель погоды';

  @override
  String get settingScreensaverWeatherBarDescription =>
      'Показывать живую погоду вдоль нижнего края экрана.';

  @override
  String get settingScreensaverWeatherBarScaleTitle => 'Масштаб текста';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      'Масштаб погодной информации от 50 до 200 процентов.';

  @override
  String get settingScreensaverWeatherBarColorTitle => 'Цвет текста';

  @override
  String get settingScreensaverWeatherBarColorDescription =>
      'Цвет погодной информации.';

  @override
  String get settingScreensaverWeatherBarOpacityTitle => 'Непрозрачность фона';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      'Затемнять нижнюю панель, чтобы погодная информация читалась.';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => 'Показывать заголовки';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      'Называть каждое показание над его значением. Выключено: значения размером с температуру.';

  @override
  String get screensaverWeatherBarHighLowDescription =>
      'Показывать сегодняшний максимум и минимум, когда у сущности погоды есть ежедневный прогноз.';

  @override
  String get screensaverWeatherBarHumidityDescription =>
      'Показывать влажность, когда сущность погоды её сообщает.';

  @override
  String get screensaverWeatherBarWindDescription =>
      'Показывать скорость ветра, когда сущность погоды её сообщает.';

  @override
  String get screensaverWeatherBarVisibilityDescription =>
      'Показывать видимость, когда сущность погоды её сообщает.';

  @override
  String get settingScreensaverWeatherBlurTitle => 'Размытие сцены';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      'Смягчать анимированную сцену погоды, сохраняя чёткость часов, панели погоды и виджетов.';

  @override
  String get screensaverWeatherPreviewTwilight => 'Рассвет/Закат';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      'Показывать ощущаемую температуру вместо фактической, когда доступна.';

  @override
  String get settingScreensaverWebsiteUrlTitle => 'URL веб-сайта';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      'Страница для показа на весь экран. Она должна разрешать встраивание.';

  @override
  String get settingScreensaverWebsiteZoomTitle => 'Масштаб';

  @override
  String get settingScreensaverWebsiteZoomDescription =>
      'Масштабирует всю веб-страницу внешней заставки.';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle =>
      'Двойное касание для закрытия';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription =>
      'Одиночные касания взаимодействуют с сайтом вместо закрытия.';

  @override
  String get screensaverWebsiteSection => 'Заставка «Веб-сайт»';

  @override
  String get screensaverOverlaySmallClock => 'Маленькие часы';

  @override
  String get screensaverOverlayWeather => 'Погода';

  @override
  String get screensaverOverlayBattery => 'Батарея';

  @override
  String get screensaverOverlayClockNote =>
      'Скрыто в режимах «Цифровые часы» и «Потоки камер».';

  @override
  String get screensaverOverlayCameraNote => 'Скрыто в режиме «Потоки камер».';

  @override
  String get screensaverOverlayScale => 'Масштаб';

  @override
  String get screensaverOverlayScaleHelp =>
      'Масштабируйте виджет под размер экрана.';

  @override
  String get screensaverOverlayFont => 'Гарнитура';

  @override
  String get screensaverOverlayCorner => 'Угол';

  @override
  String get screensaverOverlayWidget => 'Виджет';

  @override
  String get screensaverOverlayClock24 => '24-часовой формат';

  @override
  String get screensaverOverlayClock24Help =>
      'Показывать 24-часовое время вместо AM/PM.';

  @override
  String get screensaverOverlayShowDate => 'Показывать дату';

  @override
  String get screensaverOverlayShowDateHelp =>
      'Добавить короткую дату под часами.';

  @override
  String get screensaverOverlayPercentage => 'Показывать процент';

  @override
  String get screensaverOverlayPercentageHelp => 'Заряд рядом со значком.';

  @override
  String get screensaverOverlayLow => 'Только при низком заряде';

  @override
  String get screensaverOverlayLowHelp =>
      'Скрываться, пока заряд не упадёт до 20 процентов.';

  @override
  String get screensaverOverlayShowName => 'Показывать название';

  @override
  String get screensaverOverlayShowNameHelp => 'Название под значением.';

  @override
  String get screensaverOverlayShowIcon => 'Показывать значок';

  @override
  String get screensaverOverlayShowIconHelp => 'Значок рядом со значением.';

  @override
  String get screensaverOverlayVisibleStates => 'Видимые состояния';

  @override
  String get screensaverOverlayVisibleStatesHelp =>
      'Показывать виджет, только когда его значение совпадает с одним из этих, через запятую. Оставьте пустым, чтобы показывать всегда.';

  @override
  String get screensaverOverlayFontSystem => 'Системный';

  @override
  String get screensaverOverlayFontSerif => 'С засечками';

  @override
  String get screensaverOverlayFontCondensed => 'Узкий';

  @override
  String get screensaverOverlayFontMonospace => 'Моноширинный';

  @override
  String get screensaverOverlayFontCasual => 'Небрежный';

  @override
  String get screensaverOverlayFontCursive => 'Рукописный';

  @override
  String get screensaverOverlayColor => 'Цвет';

  @override
  String get screensaverOverlayWeatherEntity => 'Сущность погоды';

  @override
  String get screensaverOverlayWeatherRequired => 'Выберите сущность погоды.';

  @override
  String get screensaverOverlayLocationName => 'Название места';

  @override
  String get screensaverOverlayLocationHelp =>
      'Оставьте пустым, чтобы скрыть строку места.';

  @override
  String get screensaverOverlayLocation => 'Место';

  @override
  String get screensaverOverlayLocationDetail =>
      'Название места над температурой.';

  @override
  String get screensaverOverlayFeelsLike => 'Ощущается как';

  @override
  String get screensaverOverlayFeelsLikeHelp =>
      'Показывать ощущаемую температуру отдельной строкой с меткой под фактической.';

  @override
  String get screensaverOverlayFeelsLikeOnly => 'Только «ощущается как»';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp =>
      'Показывать ощущаемую температуру с меткой «Ощущается как» вместо фактической.';

  @override
  String get screensaverOverlayForecast => 'Прогноз';

  @override
  String get screensaverOverlayForecastHelp => 'Условия с подходящим значком.';

  @override
  String get screensaverOverlayHighLow => 'Максимум и минимум';

  @override
  String get screensaverOverlayHighLowHelp =>
      'Максимальная и минимальная температура сегодня.';

  @override
  String get screensaverOverlayForecastWidget => 'Прогноз погоды';

  @override
  String get screensaverOverlayForecastDays => 'Показано дней';

  @override
  String get screensaverOverlayForecastToday => 'Включать сегодня';

  @override
  String get screensaverOverlayForecastTodayHelp =>
      'Начинать список с прогноза на сегодня.';

  @override
  String get screensaverOverlayForecastColored => 'Цветные значки';

  @override
  String get screensaverOverlayForecastColoredHelp =>
      'Показывать значки погоды в их собственных цветах.';

  @override
  String get screensaverOverlayHumidity => 'Влажность';

  @override
  String get screensaverOverlayWind => 'Скорость ветра';

  @override
  String get screensaverOverlayVisibility => 'Видимость';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return 'Ощущается как $temperature';
  }

  @override
  String get settingScreensaverWidgetsEnabledTitle =>
      'Включить виджеты заставки';

  @override
  String get settingScreensaverWidgetsEnabledDescription =>
      'Маленькие наложения в углах заставки.';

  @override
  String get settingScreensaverWidgetsTitle => 'Виджеты';

  @override
  String get settingScreensaverWidgetsDescription =>
      'Маленькие наложения в углах заставки.';

  @override
  String get settingScreensaverWidgetScaleTitle => 'Общий масштаб виджетов';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      'Масштабировать все виджеты вместе под размер экрана. Каждый виджет сохраняет свой масштаб относительно остальных.';

  @override
  String get settingScreensaverWidgetFontTitle => 'Общая гарнитура';

  @override
  String get settingScreensaverWidgetFontDescription =>
      'Шрифт, которым рисуется каждый виджет. Виджет может выбрать свой.';

  @override
  String get settingScreensaverWidgetFontWeightTitle =>
      'Общая насыщенность шрифта';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      'Насколько жирно рисуется текст каждого виджета. По умолчанию собственная насыщенность строк. Виджет может выбрать свою.';

  @override
  String get settingScreensaverWidgetTextShadowTitle => 'Тень текста';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      'Добавить тень тексту виджетов для читаемости на фото.';

  @override
  String get settingScreensaverVignetteStrengthTitle => 'Сила виньетки';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      'Затемнение позади виджетов для читаемости на светлых фото. 0 выключает.';

  @override
  String get screensaverOverlayWidgetsEmpty => 'Виджетов пока нет';

  @override
  String get screensaverOverlayShow => 'Показывать этот виджет';

  @override
  String get screensaverOverlayRemove => 'Убрать виджет';

  @override
  String get screensaverOverlayAdd => 'Добавить виджет';

  @override
  String get screensaverOverlayAddHelp =>
      'Маленькие часы, погода, батарея или сущность в углу.';

  @override
  String get screensaverOverlayWidgetsHint => 'Наложения в углах и их масштаб';

  @override
  String get settingsSearchHint => 'Поиск настроек';

  @override
  String get settingsSearchClear => 'Очистить поиск';

  @override
  String get settingsSearchResults => 'Результаты поиска';

  @override
  String settingsSearchEmpty(String query) {
    return 'Нет настроек, соответствующих «$query».';
  }

  @override
  String get searchInstallApk =>
      'Загрузите APK Kiosk Satellite через удалённое администрирование и установите его.';

  @override
  String get searchPermissionsHelp =>
      'Каждое доступное приложению разрешение Android с его статусом: микрофон, камера, уведомления, батарея без ограничений, поверх других приложений, изменение системных настроек, защита системного интерфейса, администратор устройства, доступ ко всем файлам, статистика использования и местоположение.';

  @override
  String get searchServiceStatus => 'Статус службы';

  @override
  String get searchServiceHelp =>
      'Работает ли служба Kiosk Satellite и что она удерживает.';

  @override
  String get searchServicePermissions =>
      'Разрешения, нужные службе Kiosk Satellite.';

  @override
  String get searchIntercomKiosks =>
      'Известные киоски и возможность каждого принять звонок.';

  @override
  String get searchHaValidate => 'Проверить URL и токен вашего Home Assistant.';

  @override
  String get searchHaProxy =>
      'Обслуживать Home Assistant с обычным http через безопасный прокси внутри приложения.';

  @override
  String get searchHaDashboard =>
      'Выбрать панель и вид, которые показывает киоск.';

  @override
  String get searchKioskPermissions =>
      'Разрешения, на которые опираются защиты киоска и блокировки.';

  @override
  String get searchHomeStatus => 'Статус домашнего экрана';

  @override
  String get searchHomeHelp =>
      'Является ли Kiosk Satellite домашним экраном устройства и где завершить назначение его по умолчанию.';

  @override
  String get searchMasterVolume =>
      'Громкость устройства, под которой масштабируются ползунки медиа и ассистента.';

  @override
  String get searchSmallClock => 'Виджет часов в углу заставки.';

  @override
  String get searchBattery =>
      'Виджет батареи в углу заставки: заряд самого устройства.';

  @override
  String get searchWeatherForecast =>
      'Виджет прогноза в углу заставки: ближайшие дни с максимальной и минимальной температурой.';

  @override
  String get searchPersonPermission =>
      'Разрешение на доступ к журналам, нужное датчику присутствия устройства.';

  @override
  String get searchSonosSpeakers =>
      'Известные устройству колонки Sonos, поиск по сети и поле адреса.';

  @override
  String get voiceAppearanceHint =>
      'Облик наложения, тема, полоса активности, размер текста';

  @override
  String get voiceSkin => 'Облик';

  @override
  String get voiceSkinHelp => 'Вид наложения голосового ассистента.';

  @override
  String get voiceSkin1 => 'Облик Ассистента 1';

  @override
  String get voiceSkin1Help => 'Вид наложения, когда отвечает Ассистент 1.';

  @override
  String get voiceSkin2 => 'Облик Ассистента 2';

  @override
  String get voiceSkin2Help => 'Вид наложения, когда отвечает Ассистент 2.';

  @override
  String get voiceTheme => 'Режим темы';

  @override
  String get voiceThemeHelp => 'Светлое или тёмное отображение наложения.';

  @override
  String get voiceReactive => 'Реактивная полоса активности';

  @override
  String get voiceReactiveHelp =>
      'Полоса активности реагирует на звук. НЕ РЕКОМЕНДУЕТСЯ для слабых устройств вроде Echo Show.';

  @override
  String get voiceRate => 'Частота обновления реактивной полосы';

  @override
  String get voiceRateHelp =>
      'Как часто перерисовывается полоса активности. Выше: плавнее и больше нагрузки на ЦП.';

  @override
  String get voiceScaleHelp => 'Размер текста наложения.';

  @override
  String get voiceUpdateIntegration =>
      'Обновите интеграцию Voice Satellite в Home Assistant, чтобы управлять этими настройками с киоска.';

  @override
  String get voiceDashboardRequired =>
      'Доступно, пока киоск показывает панель Home Assistant.';

  @override
  String get voiceSkinUnavailablePlugin => 'Недоступный облик плагина';

  @override
  String get voiceSkinDefault => 'Как у облика';

  @override
  String get voiceBackground => 'Фон';

  @override
  String get voiceBackgroundHelp => 'Сколько панели просвечивает.';

  @override
  String get voicePreview => 'Предпросмотр';

  @override
  String get voicePreviewHelp =>
      'Показать наложение на этом экране на пять секунд.';

  @override
  String get voicePreviewRemoteHelp =>
      'Показать наложение на экране киоска на пять секунд.';

  @override
  String get settingVoiceThemeTitle => 'Тема';

  @override
  String get settingVoiceThemeDescription =>
      '«Авто» следует теме Home Assistant.';

  @override
  String get settingVoiceBackgroundDescription =>
      'Сколько панели просвечивает. Как у облика: -1.';

  @override
  String get settingVoiceTextScaleTitle => 'Размер текста';

  @override
  String get settingVoiceReactiveBarTitle => 'Реактивная полоса активности';

  @override
  String get settingVoiceReactiveBarDescription =>
      'Полоса следует за вашим голосом и ответом.';

  @override
  String get voicePreviewCommand => 'Какая погода?';

  @override
  String get voicePreviewAnswer => 'Сейчас солнечно и 22°, лёгкий ветерок.';

  @override
  String get settingVoiceOverlayModeTitle => 'Режим наложения';

  @override
  String get settingVoiceOverlayModeDescription =>
      '«Прикреплённое» показывает маленький пузырь поверх панели. Он не показывает богатые результаты вроде изображений, погоды или видео.';

  @override
  String get voiceOverlayFullScreen => 'Полный экран';

  @override
  String get voiceOverlayDocked => 'Прикреплённое';

  @override
  String get voiceListeningEllipsis => 'Слушаю…';

  @override
  String get voiceSkinVoiceOnly => 'Только голос';

  @override
  String get voiceAssistant1 => 'Ассистент 1';

  @override
  String get voiceAssistant1Help => 'Отвечает на слово пробуждения 1.';

  @override
  String get voiceAssistant2 => 'Ассистент 2';

  @override
  String get voiceAssistant2Help => 'Отвечает на слово пробуждения 2.';

  @override
  String get voicePipelines => 'Конвейеры';

  @override
  String get voicePreferred => 'Предпочтительный';

  @override
  String get voiceNone => 'Нет';

  @override
  String get voiceThisKiosk => 'Этот киоск';

  @override
  String get voiceSelectFailed => 'Не удалось изменить это в Home Assistant.';

  @override
  String get settingVoiceSeamlessWakeTitle =>
      'Говорить сразу после слова пробуждения';

  @override
  String get settingVoiceSeamlessWakeAssistDescription =>
      'Пропускать звук пробуждения и ловить сказанное сразу после слова пробуждения. Только для конвейеров Assist, не для разговоров в реальном времени.';

  @override
  String get settingVoiceFollowupDelayTitle => 'Задержка уточнения';

  @override
  String get settingVoiceFollowupDelayDescription =>
      'Пауза перед слушанием ответа на вопрос.';

  @override
  String get settingVoiceFollowupChimeTitle => 'Сигнал перед уточнением';

  @override
  String get settingVoiceFollowupChimeDescription =>
      'Проигрывать звук пробуждения, когда слушание начинается снова.';

  @override
  String get settingVoiceTtsOutputTitle => 'Проигрывать звуки на';

  @override
  String get settingVoiceTtsOutputDescription =>
      'Сигналы, ответы, объявления и оповещения таймеров играют на этой колонке.';

  @override
  String get settingVoiceTtsOutputModeTitle => 'Проигрывать как';

  @override
  String get settingVoiceTtsOutputModeDescription =>
      '«Объявление» позволяет колонке приостановить музыку и продолжить её. «Обычное воспроизведение» затем снова запускает музыку, для колонок, игнорирующих объявления.';

  @override
  String get voiceOptionAnnouncement => 'Объявление';

  @override
  String get voiceOptionNormalPlayback => 'Обычное воспроизведение';

  @override
  String get voiceChimesPage => 'Сигналы';

  @override
  String get voiceChimesPreview => 'Предпросмотр на киоске';

  @override
  String get voiceChimesPreviewFailed => 'Не удалось проиграть звук.';

  @override
  String get voiceChimesHelp =>
      'Выберите звуки для этого киоска. Загрузите свои файлы здесь. Звуки из Home Assistant не используются для локальных сигналов.';

  @override
  String get voiceChimeWakeTitle => 'Звук пробуждения';

  @override
  String get voiceChimeWakeDescription =>
      'Играет, когда Voice Satellite начинает слушать.';

  @override
  String get voiceChimeDoneTitle => 'Звук готовности';

  @override
  String get voiceChimeDoneDescription =>
      'Играет, когда голосовое взаимодействие завершается.';

  @override
  String get voiceChimeErrorTitle => 'Звук ошибки';

  @override
  String get voiceChimeErrorDescription =>
      'Играет, когда голосовое взаимодействие не удаётся.';

  @override
  String get voiceChimeTimerTitle => 'Звук таймера';

  @override
  String get voiceChimeTimerDescription =>
      'Повторяется, когда таймер завершается, пока вы его не уберёте.';

  @override
  String get voiceChimeAnnounceTitle => 'Звук объявления';

  @override
  String get voiceChimeAnnounceDescription =>
      'Играет перед объявлением Voice Satellite, если у него нет своего звука.';

  @override
  String get settingVoiceWakeSoundTitle => 'Проигрывать сигналы';

  @override
  String get settingVoiceWakeSoundDescription =>
      'Звуки пробуждения, готовности и ошибки.';

  @override
  String get voiceChimeWakeVolumeTitle => 'Громкость звука пробуждения';

  @override
  String get voiceChimeDoneVolumeTitle => 'Громкость звука готовности';

  @override
  String get voiceChimeErrorVolumeTitle => 'Громкость звука ошибки';

  @override
  String get voiceChimeTimerVolumeTitle => 'Громкость звука таймера';

  @override
  String get voiceChimeAnnounceVolumeTitle => 'Громкость звука объявления';

  @override
  String get voiceChimeVolumeDescription => 'Доля громкости ассистента.';

  @override
  String get voiceChimesSoundsHint =>
      'Звуки пробуждения, готовности, ошибки и объявлений';

  @override
  String get settingVoiceShowCommandTitle => 'Показывать сказанное';

  @override
  String get settingVoiceShowCommandDescription => 'Ваша команда над ответом.';

  @override
  String get settingVoiceShowAnswerTitle => 'Показывать ответ';

  @override
  String get settingVoiceShowAnswerDescription => 'Ответ по мере произнесения.';

  @override
  String get settingVoiceShowToolsTitle => 'Показывать вызовы инструментов';

  @override
  String get settingVoiceShowToolsDescription =>
      'Строка на каждое действие ассистента.';

  @override
  String get settingVoiceHideSentimentTagsTitle => 'Скрывать метки настроения';

  @override
  String get settingVoiceHideSentimentTagsDescription =>
      'Убирать метки вроде [happy], добавляемые некоторыми ассистентами.';

  @override
  String get settingVoiceAnswerLingerTitle => 'Держать ответ на экране';

  @override
  String get settingVoiceAnswerLingerDescription =>
      'После произнесения ответа.';

  @override
  String get settingVoiceResultsLingerTitle => 'Держать результаты на экране';

  @override
  String get settingVoiceResultsLingerDescription =>
      'Изображения, погода и другие результаты. 0 держит их до закрытия.';

  @override
  String get settingVoiceAnnouncementLingerTitle => 'Время объявления';

  @override
  String get settingVoiceAnnouncementLingerDescription =>
      'После произнесения объявления.';

  @override
  String get voiceEngine => 'Движок';

  @override
  String get voiceEngineHelp =>
      'Запустить или остановить движок Voice Satellite.';

  @override
  String get voiceAssigned => 'Назначенный спутник';

  @override
  String get voiceAssignedHelp =>
      'Сущность assist_satellite, которой этот киоск является в Home Assistant. Смена перезагружает панель.';

  @override
  String get voiceAssignedSearch =>
      'Сущность assist_satellite, которой этот киоск является в Home Assistant.';

  @override
  String get voiceNoneAssigned => 'Не назначен';

  @override
  String get voiceAutoStart => 'Автостарт';

  @override
  String get voiceAutoStartHelp =>
      'Автозапуск Voice Satellite при загрузке панели.';

  @override
  String get voiceMuteHelp => 'Не слушать слова пробуждения.';

  @override
  String get voicePipeline1 => 'Конвейер Assist 1';

  @override
  String get voicePipeline1Help =>
      'Конвейер Assist, через который идут голосовые команды.';

  @override
  String get voicePipeline2 => 'Конвейер Assist 2';

  @override
  String get voicePipeline2Help =>
      'Конвейер, используемый при срабатывании второго слова пробуждения.';

  @override
  String get voiceVad => 'Определение конца речи';

  @override
  String get voiceVadHelp => 'Какая пауза завершает голосовую команду.';

  @override
  String get voiceMutedWarning =>
      'Скрывать предупреждение о выключенном микрофоне';

  @override
  String get voiceMutedWarningHelp =>
      'Скрывать предупреждение о выключенном микрофоне при старте и всегда, когда микрофон спутника выключен.';

  @override
  String get voiceDebug => 'Отладочный журнал';

  @override
  String get voiceDebugHelp =>
      'Показывать отладочную информацию Voice Satellite в консоли браузера.';

  @override
  String get voiceVersion => 'Версия Voice Satellite';

  @override
  String get voiceVersionHelp =>
      'Версия интеграции, установленной в Home Assistant.';

  @override
  String get voiceVadDefault => 'По умолчанию';

  @override
  String get voiceVadRelaxed => 'Мягкое';

  @override
  String get voiceVadAggressive => 'Агрессивное';

  @override
  String get voiceGeneral => 'Общее';

  @override
  String get voiceStart => 'Запустить';

  @override
  String get voiceNotavailable => 'Недоступно';

  @override
  String get voiceDisabled => 'Выключено';

  @override
  String get settingWakeWordBackgroundTitle => 'Слушать в фоне';

  @override
  String get settingWakeWordBackgroundDescription =>
      'Продолжать слышать слово пробуждения при другом приложении на экране и возвращаться при срабатывании. Нужны постоянное уведомление и «Поверх других приложений».';

  @override
  String get settingWakeWordReturnToBackgroundTitle =>
      'Возвращаться к прежнему приложению';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      'Возвращаться к прежнему приложению или домашнему экрану после того, как голосовое взаимодействие вывело Kiosk Satellite на передний план и завершилось.';

  @override
  String get voiceAssistant => 'Ассистент';

  @override
  String get voiceConversation => 'Диалог';

  @override
  String get voiceTimers => 'Таймеры';

  @override
  String get voiceAssistantHint => 'Конвейеры, уточнения';

  @override
  String get voiceConversationHint => 'Что показывает наложение и как долго';

  @override
  String get voiceSectionFollowUp => 'Уточнение';

  @override
  String get voiceSectionLinger => 'Сколько остаётся на экране';

  @override
  String get voiceSectionOnScreen => 'На экране';

  @override
  String get voiceSectionPills => 'Плашки';

  @override
  String get voiceSectionSpeaker => 'Колонка';

  @override
  String get voiceSectionWakeCommand => 'Слово пробуждения и команда';

  @override
  String get voiceSectionTimerEnds => 'Когда таймер завершается';

  @override
  String get voiceSectionSharedTimers => 'Общие таймеры';

  @override
  String get voiceStatusEsphomeOff => 'Сервер ESPHome выключен.';

  @override
  String get voiceStatusNotAdded =>
      'Этот киоск ещё не добавлен в Home Assistant.';

  @override
  String get voiceStatusMuted => 'Микрофон выключен.';

  @override
  String get voiceStatusNotListening => 'Слово пробуждения не отслеживается.';

  @override
  String get voiceStatusListening => 'Слушает слово пробуждения.';

  @override
  String get voiceWordNotAdded => 'Не добавлен';

  @override
  String get voiceWordMuted => 'Выключен';

  @override
  String get voiceWordBusy => 'Занят';

  @override
  String get voiceWordListening => 'Слушает';

  @override
  String get voiceWordNotListening => 'Не слушает';

  @override
  String get voiceWordAdded => 'Добавлен';

  @override
  String get voiceHaAddAgainHint =>
      'Добавьте этот киоск в Home Assistant в разделе Настройки, Устройства и службы, где он появится как обнаруженный. Если Home Assistant уже знал его, там он запросит новый Ключ шифрования со страницы ESPHome.';

  @override
  String get voiceHaEsphomeOff =>
      'Включите сервер ESPHome, чтобы Home Assistant мог добавить этот киоск как спутник.';

  @override
  String get voiceWordReloadNeeded => 'Нужна перезагрузка';

  @override
  String get voiceHaSelectsReloadHint =>
      'Home Assistant не загрузил списки Assistant и Wake word. Перезагрузите запись ESPHome этого киоска в разделе «Настройки», «Устройства и службы». Помогает и перезапуск Home Assistant.';

  @override
  String get voiceTurnOn => 'Включить';

  @override
  String get voiceRollbackTitle => 'Снова запускать с панели';

  @override
  String get voiceRollbackDescription =>
      'Вернуться к интеграции Voice Satellite. Ничего из заданного здесь не теряется.';

  @override
  String get voiceRollbackConfirm => 'Снова запускать с панели?';

  @override
  String get voiceRollbackBody =>
      'Панель снова запускает Voice Satellite через интеграцию с прежними настройками. Заданное здесь сохранится на следующий раз.';

  @override
  String get voiceRollbackSwitch => 'Переключиться обратно';

  @override
  String get voiceMigrateNotice =>
      'Voice Satellite сейчас установлен как интеграция в Home Assistant. Выполните миграцию к нативной работе внутри Kiosk Satellite.';

  @override
  String get voiceMigrate => 'Выполнить миграцию';

  @override
  String get settingVoiceEnabledTitle => 'Включить Voice Satellite';

  @override
  String get settingVoiceEnabledDescription =>
      'Превращает этот киоск в голосового ассистента Home Assistant через его сервер ESPHome.';

  @override
  String get settingVoiceMuteTitle => 'Выключить микрофон';

  @override
  String get settingVoiceMuteDescription => 'Не слушать слово пробуждения.';

  @override
  String get voiceMigrationTitle => 'Миграция Voice Satellite';

  @override
  String get voiceMigrationPick =>
      'Выберите спутник интеграции Voice Satellite, роль которого возьмёт на себя этот киоск. Его настройки перейдут на этот киоск.';

  @override
  String get voiceMigrationNoSatellites =>
      'У интеграции Voice Satellite нет спутников.';

  @override
  String get voiceMigrationIntro =>
      'Этот киоск сам становится голосовым спутником. Интеграция Voice Satellite после этого не нужна.';

  @override
  String get voiceMigrationCheckAgain => 'Проверить снова';

  @override
  String get voiceCheckHaBad =>
      'Не подключено. Проверьте настройку Home Assistant.';

  @override
  String get voiceCheckEsphome => 'Этот киоск в Home Assistant';

  @override
  String get voiceCheckEsphomeOk => 'Добавлен через ESPHome.';

  @override
  String get voiceCheckEsphomeBad =>
      'Ещё не добавлен. Home Assistant перечисляет этот киоск как обнаруженный в разделе «Настройки», «Устройства и службы». Добавьте его там, затем вернитесь.';

  @override
  String get voiceCheckEsphomeOff =>
      'Сервер ESPHome выключен. Включите его, затем добавьте этот киоск в Home Assistant.';

  @override
  String get voiceCheckAdmin => 'Токен администратора';

  @override
  String get voiceCheckAdminOk =>
      'Вызовы инструментов и результаты будут показываться.';

  @override
  String get voiceCheckAdminBad =>
      'Токен обычного пользователя. Voice Satellite работает, но вызовы инструментов и результаты показываться не будут.';

  @override
  String get voiceCheckAdminUnknown =>
      'Не удалось проверить токен. Вызовам инструментов и результатам нужен администраторский.';

  @override
  String get voiceCheckMicOk => 'Разрешено.';

  @override
  String get voiceCheckMicBad =>
      'Не разрешено. Выдайте в разделе «Необходимые системные разрешения».';

  @override
  String get voiceTurnOnEsphome => 'Включить ESPHome';

  @override
  String get voiceMigrationPlan => 'Переносимые настройки';

  @override
  String get voiceGroupVoice => 'Голос';

  @override
  String get voiceMigrationNotCarried =>
      'Не переносятся: пользовательский CSS, обработка микрофона браузером и длина памяти диалога. Пользовательские модели microWakeWord работают из config/custom_wake_words в Home Assistant.';

  @override
  String get voiceMigrationAutomations => 'Автоматизации и сценарии';

  @override
  String get voiceMigrationNoAutomations =>
      'Ничто в Home Assistant не указывает на прежний спутник.';

  @override
  String get voiceKindAutomation => 'Автоматизация';

  @override
  String get voiceKindScript => 'Сценарий';

  @override
  String get voiceMigrationReady => 'Готово к переключению';

  @override
  String get voiceMigrationReady1 =>
      'Этот киоск слушает, отвечает и рисует наложение.';

  @override
  String get voiceMigrationReadyOnboarding =>
      'Его Ассистент и слова пробуждения зададутся, когда Home Assistant добавит этот киоск.';

  @override
  String get voiceMigrationReady2 =>
      'Панель перестаёт запускать Voice Satellite на этом киоске.';

  @override
  String get voiceMigrationReady3 =>
      'Прежний спутник остаётся в Home Assistant без использования.';

  @override
  String get voiceMigrationSwitch => 'Переключить сейчас';

  @override
  String get voiceMigrationSwitching => 'Переключение…';

  @override
  String get voiceMigrationDone => 'Voice Satellite теперь работает здесь';

  @override
  String get voiceCouldNotSwitch => 'Не удалось переключиться';

  @override
  String get voiceMigrationDoneOnboarding =>
      'Завершите настройку, затем добавьте этот киоск в Home Assistant. Когда интеграцию Voice Satellite не использует ни одно другое устройство, удалите её из HACS.';

  @override
  String get voiceMigrationDoneHelp =>
      'Скажите слово пробуждения, чтобы попробовать. Когда интеграцию Voice Satellite не использует ни одно другое устройство, удалите её из HACS.';

  @override
  String get voiceMigrationRolledBack =>
      'Voice Satellite снова запускается с панели.';

  @override
  String get voiceDone => 'Готово';

  @override
  String get voiceTryAgain => 'Повторить';

  @override
  String get voiceStepSave => 'Сохранить настройки';

  @override
  String get voiceStepStop => 'Остановить движок панели';

  @override
  String get voiceStepStart => 'Начать слушать здесь';

  @override
  String get voiceStepTurnOn => 'Включить Voice Satellite на этом киоске';

  @override
  String get voiceStepEntities => 'Задать сущности киоска в Home Assistant';

  @override
  String get voiceStepCheck => 'Проверить спутник в Home Assistant';

  @override
  String voiceMigrationStep(String n, String total) {
    return 'Шаг $n из $total';
  }

  @override
  String voiceMigrationStillPoint(String satellite) {
    return 'Они всё ещё указывают на $satellite. Измените их в Home Assistant на спутник этого киоска. Мастер их не трогает.';
  }

  @override
  String get voiceMigrationNotUp => 'Спутник не запустился вовремя.';

  @override
  String get voiceMigrationNotReported =>
      'Home Assistant не сообщил о спутнике.';

  @override
  String get voiceMigrationBusy => 'Миграция уже выполняется.';

  @override
  String get voiceMicHeld => 'Определение слова пробуждения вас слышит.';

  @override
  String get voiceMicBlocked =>
      'Заблокировано. Android больше не спросит: разрешите в настройках приложения.';

  @override
  String get voiceMicMissing => 'Без этого слово пробуждения никто не слушает.';

  @override
  String get voiceForegroundHeld =>
      'Kiosk Satellite может выйти на передний план, услышав вас.';

  @override
  String get voiceForegroundMissing =>
      'Без этого слово пробуждения слышно, но ничего не происходит.';

  @override
  String get voiceNotificationHeld =>
      'Постоянное уведомление, включающее фоновое прослушивание.';

  @override
  String get voiceNotificationMissing =>
      'Нужно для надёжной работы фонового прослушивания.';

  @override
  String get voiceBatteryHeld => 'Android оставит слушателя работать.';

  @override
  String get voiceBatteryMissing =>
      'Без этого слушатель останавливается через несколько часов.';

  @override
  String get voicePermissionDirections =>
      'Выдайте их на самом устройстве: свайп от левого края → Настройки → Voice Satellite → Необходимые системные разрешения.';

  @override
  String get voicePermissionsSearch =>
      'Микрофон и остальные разрешения, нужные определению слова пробуждения.';

  @override
  String get voiceRealtime => 'Реальное время';

  @override
  String get voiceRealtimeProvidersHint =>
      'OpenAI, xAI Grok, Gemini, инструменты, перебивание ответов';

  @override
  String get voiceRealtimeToolsSection => 'Инструменты Home Assistant';

  @override
  String get voiceRealtimeProviderDefault => 'Как у провайдера';

  @override
  String get voiceRealtimeToolsCustom => 'Свой сервер MCP';

  @override
  String get settingVoiceRealtimeEndpointTitle => 'Эндпоинт';

  @override
  String get settingVoiceRealtimeEndpointDescription =>
      'Оставьте пустым, чтобы использовать провайдера. Используйте ретранслятор в вашей сети, чтобы держать киоск офлайн.';

  @override
  String get settingVoiceRealtimeApiKeyTitle => 'API-ключ';

  @override
  String get settingVoiceRealtimeApiKeyDescription =>
      'Оставьте пустым, если ключ добавляет ретранслятор.';

  @override
  String get settingVoiceRealtimeModelTitle => 'Модель';

  @override
  String get settingVoiceRealtimeVoiceTitle => 'Голос';

  @override
  String get settingVoiceRealtimeInstructionsTitle => 'Инструкции';

  @override
  String get settingVoiceRealtimeInstructionsDescription =>
      'Как ведёт себя ассистент. Оставьте пустым для короткой стандартной.';

  @override
  String get settingVoiceRealtimeIdleSecondsTitle => 'Завершать после тишины';

  @override
  String get settingVoiceRealtimeIdleSecondsDescription =>
      'Разговор завершается после этого времени молчания.';

  @override
  String get settingVoiceRealtimeReasoningTitle => 'Глубина размышлений';

  @override
  String get settingVoiceRealtimeReasoningDescription =>
      'Больше усилий: лучше отвечает на сложные вопросы. Нужна модель gpt-realtime-2.';

  @override
  String get settingVoiceRealtimeGeminiReasoningDescription =>
      'Больше усилий: лучше отвечает на сложные вопросы. Нужна думающая модель, например gemini-3.8-live-extended-thinking.';

  @override
  String get settingVoiceRealtimeGeminiSearchTitle => 'Google Поиск';

  @override
  String get settingVoiceRealtimeGeminiSearchBillingDescription =>
      'Позволяет модели искать в интернете. Нужен включённый биллинг у API-ключа.';

  @override
  String get settingVoiceRealtimeGeminiProactiveTitle =>
      'Игнорировать речь, обращённую не к ассистенту';

  @override
  String get settingVoiceRealtimeGeminiProactiveDescription =>
      'Модель молчит, когда слышит обращение не к ней. Экспериментально у Google.';

  @override
  String get settingVoiceRealtimeXaiWebSearchTitle => 'Поиск в интернете';

  @override
  String get settingVoiceRealtimeXaiWebSearchDescription =>
      'Позволяет модели искать в интернете.';

  @override
  String get settingVoiceRealtimeXaiXSearchTitle => 'Поиск по X';

  @override
  String get settingVoiceRealtimeXaiXSearchDescription =>
      'Позволяет модели искать посты в X.';

  @override
  String get voiceRealtimeReasoningDefault => 'Как у модели';

  @override
  String get voiceRealtimeReasoningMinimal => 'Минимальная';

  @override
  String get voiceRealtimeReasoningLow => 'Низкая';

  @override
  String get voiceRealtimeReasoningMedium => 'Средняя';

  @override
  String get voiceRealtimeReasoningHigh => 'Высокая';

  @override
  String get voiceRealtimeReasoningExtraHigh => 'Очень высокая';

  @override
  String get settingVoiceRealtimeSpeedTitle => 'Скорость речи';

  @override
  String get settingVoiceRealtimeSpeedDescription =>
      'Как быстро говорит ассистент.';

  @override
  String get settingVoiceRealtimeHistoryHoursTitle => 'Длительность сеанса';

  @override
  String get settingVoiceRealtimeHistoryHoursDescription =>
      'Сказанное в это время переносится в следующий разговор.';

  @override
  String get settingVoiceRealtimeTalkOverTitle => 'Перебивать ответы';

  @override
  String get settingVoiceRealtimeTalkOverDescription =>
      'Прерывать ответ, начав говорить. Выключите, если ассистент перебивает сам себя.';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityTitle =>
      'Чувствительность перебивания';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityDescription =>
      'Насколько легко голос прерывает ответ. Повысьте, если перебить не получается из-за тихого микрофона. Высокие значения могут заставить ассистента перебивать самого себя.';

  @override
  String get settingVoiceRealtimeToolsTitle => 'Инструменты';

  @override
  String get settingVoiceRealtimeToolsDescription =>
      'Чем ассистент может управлять. Home Assistant использует свою интеграцию MCP Server и сущности, предоставленные Assist.';

  @override
  String get settingVoiceRealtimeMcpUrlTitle => 'URL сервера MCP';

  @override
  String get settingVoiceRealtimeMcpUrlDescription =>
      'Адрес сервера Streamable HTTP.';

  @override
  String get settingVoiceRealtimeMcpTokenTitle => 'Токен MCP';

  @override
  String get settingVoiceRealtimeMcpTokenDescription =>
      'Отправляется как bearer-токен. Оставьте пустым, если серверу он не нужен.';

  @override
  String get voiceRealtimeMcpMissing =>
      'Добавьте интеграцию MCP Server в Home Assistant, чтобы управлять домом.';

  @override
  String get voiceRealtimeNotValidated => 'Не проверено';

  @override
  String voiceRealtimeOption(String provider) {
    return '$provider Realtime';
  }

  @override
  String voiceRealtimeConnectFailed(String error) {
    return 'Не удалось подключиться: $error';
  }

  @override
  String voiceRealtimeToolsUnavailable(String problem) {
    return 'Подключено, но инструменты Home Assistant недоступны: $problem';
  }

  @override
  String get settingVoiceRealtimeModelDescription =>
      'Модель «речь к речи», которая отвечает.';

  @override
  String get settingVoiceRealtimeVoiceDescription => 'Как звучит ассистент.';

  @override
  String get voiceRealtimeProviders => 'Провайдеры';

  @override
  String get voiceRealtimeConfigure => 'Настроить';

  @override
  String get voiceRealtimeSaveValidate => 'Сохранить и проверить';

  @override
  String get voiceRealtimeNotConfigured => 'Не настроено';

  @override
  String get voiceRealtimeValidated => 'Соединение проверено';

  @override
  String get voiceDisconnected => 'Home Assistant не подключён';

  @override
  String get voiceValidate =>
      'Сначала проверьте соединение в настройке Home Assistant.';

  @override
  String get voiceChecking => 'Проверка Voice Satellite…';

  @override
  String get voiceMissing => 'Voice Satellite не установлен в Home Assistant';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite превращает этот киоск в полноценного голосового ассистента Home Assistant без рук: слово пробуждения, диалоги, таймеры и объявления прямо на панели.\n\nОн доступен в стандартном репозитории HACS. Установите его на свой экземпляр Home Assistant, затем вернитесь сюда.';

  @override
  String get voiceLearnMore => 'Узнать больше о ';

  @override
  String get voiceGithub => 'Voice Satellite на Github';

  @override
  String get voiceHacs => 'Открыть репозиторий HACS';

  @override
  String get voiceLoading => 'Загрузка элементов управления Voice Satellite…';

  @override
  String get voiceTester => 'Тестер слова пробуждения';

  @override
  String get voiceTesterHelp =>
      'Смотрите в реальном времени, что слышит и как оценивает движок, чтобы понять, почему слово пробуждения срабатывает или нет.';

  @override
  String get voiceTesterSearch =>
      'Живой взгляд на то, что слышит и оценивает движок.';

  @override
  String get voiceTesterWaiting => 'Ожидание Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word (стоп-слово)';
  }

  @override
  String get voiceScore => 'Оценка';

  @override
  String get voiceThreshold => 'Порог';

  @override
  String get voiceHits => 'Попадания';

  @override
  String get voiceNearMisses => 'Почти-срабатывания';

  @override
  String get voicePeak => 'Пик';

  @override
  String get voiceMicLevel => 'Уровень микрофона';

  @override
  String get voiceChunkProcessing => 'Обработка чанков (мин / сред / макс)';

  @override
  String get voiceLog => 'Журнал';

  @override
  String get voiceLogEmpty =>
      'Здесь появятся срабатывания и почти-срабатывания.';

  @override
  String get voiceLogHit => 'ПОПАДАНИЕ';

  @override
  String get voiceLogNear => 'почти';

  @override
  String get voiceLogScore => 'оценка';

  @override
  String get voiceLogDecoded => 'распознано';

  @override
  String get voiceLogDistance => 'ред';

  @override
  String get voiceLogConfidence => 'увер.';

  @override
  String get voiceTesterPlayRecent => 'Проиграть последние 10 с';

  @override
  String get settingVoiceTimerPillsViewTitle => 'Показывать таймеры плашками';

  @override
  String get settingVoiceTimerPillsViewDescription =>
      'Таймеры плавают по экрану вместо открытия полноэкранного вида.';

  @override
  String get settingVoiceTimerNameInPillTitle => 'Показывать название таймера';

  @override
  String get settingVoiceTimerNameInPillDescription =>
      'Название рядом со временем на плашке.';

  @override
  String get settingVoiceTimerPillScaleTitle => 'Масштаб плашек таймеров';

  @override
  String get settingVoiceTimerPillScaleDescription => 'Размер плашек таймеров.';

  @override
  String get settingVoiceTimerAlertPillTitle =>
      'Показывать плашки завершённых таймеров';

  @override
  String get settingVoiceTimerAlertPillDescription =>
      'Коснитесь плашки, чтобы остановить оповещение.';

  @override
  String get settingVoiceMuteTimersTitle => 'Заглушить оповещения таймеров';

  @override
  String get settingVoiceMuteTimersDescription =>
      'Показывать оповещение без звука.';

  @override
  String get settingVoiceTimerNameOnAlertTitle =>
      'Показывать название в оповещении';

  @override
  String get settingVoiceTimerNameOnAlertDescription =>
      'Название таймера под оповещением.';

  @override
  String get settingVoiceTimerSpeakTitle =>
      'Произносить при завершении таймера';

  @override
  String get settingVoiceTimerSpeakDescription =>
      'Произносить фразу между звуками оповещения.';

  @override
  String get settingVoiceTimerPhraseTitle => 'Фраза';

  @override
  String get settingVoiceTimerPhraseDescription =>
      'Произносится для таймера без названия.';

  @override
  String get settingVoiceTimerNamedPhraseTitle =>
      'Фраза для именованных таймеров';

  @override
  String settingVoiceTimerNamedPhraseDescription(String name) {
    return '$name заменяется названием таймера.';
  }

  @override
  String get settingVoiceTimersShareTitle => 'Общие таймеры';

  @override
  String get settingVoiceTimersShareDescription =>
      'Таймеры, запущенные на этом киоске, также работают на выбранных вами киосках.';

  @override
  String get settingVoiceTimersShareWithTitle => 'Делиться с';

  @override
  String get settingVoiceTimersShareWithDescription =>
      'Киоски, которые показывают таймеры этого киоска и звонят вместе с ним.';

  @override
  String get settingVoiceTimersReceiveTitle => 'Показывать общие таймеры';

  @override
  String get settingVoiceTimersReceiveDescription =>
      'Таймеры, которыми делятся другие киоски, показываются и звонят здесь.';

  @override
  String get settingKioskAllowTimersTitle => 'Таймеры';

  @override
  String get settingKioskAllowTimersDescription =>
      'Открывать вид таймеров из меню киоска.';

  @override
  String get settingsMenuTimersSummary =>
      'Полноэкранный вид, плашки, общие таймеры';

  @override
  String get fleetTheKiosksPickedInShareWithTheTimerSound =>
      'киоски, выбранные в «Делиться с», звук таймера';

  @override
  String get settingTimersTtsEngineDescription =>
      'Сущность синтеза речи Home Assistant, которая произносит таймеры.';

  @override
  String get settingTimersTtsLanguageDescription =>
      'Язык, на котором произносятся таймеры.';

  @override
  String get settingTimersTtsVoiceDescription =>
      'Голос, которым произносятся таймеры.';

  @override
  String get settingTimersShowBeforeEndTitle =>
      'Показывать вид таймеров перед завершением';

  @override
  String get settingTimersShowBeforeEndDescription =>
      'За сколько до завершения таймера открывается вид таймеров.';

  @override
  String get settingTimersShowOnStartTitle =>
      'Показывать вид таймеров при запуске таймера';

  @override
  String get settingTimersShowOnStartDescription =>
      'Открывает вид таймеров при каждом запуске таймера.';

  @override
  String get settingTimersPauseScreensaverTitle =>
      'Приостанавливать заставку, пока идёт таймер';

  @override
  String get settingTimersPauseScreensaverDescription =>
      'Заставка не запускается, пока вид таймеров показывает идущий таймер.';

  @override
  String get voiceWakePage => 'Слово пробуждения';

  @override
  String get voiceWakeHint =>
      'Движок, слова пробуждения, чувствительность, кэш моделей';

  @override
  String get voiceWakeLabel => 'Слово пробуждения';

  @override
  String get voiceWakeEngine => 'Движок слова пробуждения';

  @override
  String get voiceWakeEngineHelp =>
      'Где работает определение и какой движок слушает.';

  @override
  String get voiceWake1 => 'Слово пробуждения 1';

  @override
  String get voiceWake1Help => 'Слово, начинающее голосовую команду.';

  @override
  String get voiceWake2 => 'Слово пробуждения 2';

  @override
  String get voiceWake2Help =>
      'Второе слово пробуждения, на которое отвечает конвейер Assist 2.';

  @override
  String get voiceSensitivity => 'Чувствительность слова пробуждения';

  @override
  String get voiceSensitivityHelp =>
      'Насколько легко срабатывает слово пробуждения.';

  @override
  String get voiceNoiseGate => 'Шумовой порог слова пробуждения';

  @override
  String get voiceNoiseGateHelp =>
      'Пропускать локальное распознавание слова пробуждения в тишине, экономя ЦП.';

  @override
  String get voiceStopInterruption => 'Перебивание стоп-словом';

  @override
  String get voiceStopInterruptionHelp =>
      'Скажите стоп-слово, чтобы перебить ответы.';

  @override
  String get voiceAssignFirst =>
      'Назначьте спутник, чтобы управлять этими настройками.';

  @override
  String get voiceCachedModels => 'Кэш моделей';

  @override
  String get voiceCachedModelsHelp =>
      'Скачать заново из Home Assistant. Используйте после повторной публикации модели.';

  @override
  String get voiceClearCache => 'Очистить кэш';

  @override
  String get voiceClearing => 'Очистка…';

  @override
  String voiceCacheCleared(String count) {
    return 'Файлов очищено: $count. Скачивается заново.';
  }

  @override
  String voiceCacheCount(String count) {
    return 'Очищено: $count';
  }

  @override
  String get voiceVerySensitive => 'Очень чувствительно';

  @override
  String get voiceWakeWordPreferFp32Title =>
      'Предпочитать модели vsWakeWord fp32';

  @override
  String get voiceWakeWordPreferFp32Description =>
      'Использовать модели fp32 вместо меньших версий int8. Добавляет 10-30% нагрузки на ЦП при слушании, избегая около 2% дрейфа уверенности.';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle =>
      'Тайм-аут возобновления (с)';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      'Самовосстановление: возобновить слушание, если страница не вызвала setWakeWordActive(true) после передачи. Ждёт, пока голосовая реплика ещё стримит звук, так что долгая реплика не обрезается.';

  @override
  String get voiceSlightlySensitive => 'Слегка чувствительно';

  @override
  String get voiceModeratelySensitive => 'Умеренно чувствительно';

  @override
  String get voiceOnDevice => 'На устройстве';

  @override
  String voiceOnDeviceEngine(String engine) {
    return 'На устройстве ($engine)';
  }

  @override
  String get voiceDiagnosticsPage => 'Диагностика слова пробуждения';

  @override
  String get voiceDiagnosticsHint =>
      'Недавние срабатывания и почти-срабатывания со звуковыми клипами';

  @override
  String get voiceDiagnosticsTitle => 'Включить диагностику слова пробуждения';

  @override
  String get voiceDiagnosticsDescription =>
      'Записывает последние 10 срабатываний слова пробуждения и почти-срабатываний с их оценками и 3-секундным звуковым клипом каждого. Выключение удаляет их.';

  @override
  String get voiceDiagnosticsEmpty =>
      'Срабатываний слова пробуждения пока не записано.';

  @override
  String get voiceDiagnosticsActivations => 'Срабатывания';

  @override
  String get voiceDiagnosticsNoNearMisses =>
      'Почти-срабатываний пока не записано.';

  @override
  String get voiceDiagnosticsPeakLevel => 'Пиковый уровень';

  @override
  String get voiceDiagnosticsAverageLevel => 'Средний уровень';

  @override
  String get voiceDiagnosticsClipped => 'Клиппинг';

  @override
  String get voiceDiagnosticsHeard => 'Услышано';

  @override
  String get voiceWake2HelpNative =>
      'Второе слово пробуждения, на которое отвечает Ассистент 2.';

  @override
  String get voiceCustomModels => 'Свои модели';

  @override
  String get voiceCustomNone => 'Своих моделей пока нет.';

  @override
  String get voiceCustomManaged =>
      'Своими моделями на этом киоске управляет ведущий группы.';

  @override
  String get voiceCustomAdd => 'Добавить модели';

  @override
  String get voiceCustomAddHelp =>
      'Выберите файлы одной или нескольких моделей. Они появятся в «Слове пробуждения 1» и «2» выше.';

  @override
  String get voiceCustomDocs => 'Как добавить свои модели';

  @override
  String get voiceCustomDocsHelp =>
      'Какие файлы нужны каждому движку и откуда берутся модели.';

  @override
  String get voiceCustomNotAdded => 'Модели не добавлены.';

  @override
  String get voiceCustomSomeNotAdded => 'Некоторые файлы не добавлены.';

  @override
  String get voiceCustomAdded => 'Модели добавлены.';

  @override
  String get voiceCustomDeleteConfirm => 'Удалить эту модель?';

  @override
  String get voiceCustomNotDeleted => 'Модель не удалена.';

  @override
  String get voiceCustomOtherEngine => 'для другого движка';

  @override
  String get settingVoiceWakeWordEngineDescription =>
      'Какой движок слушает. Все модели поставляются с приложением.';

  @override
  String get settingVoiceWakeWordSensitivityTitle =>
      'Чувствительность слова пробуждения';

  @override
  String get settingVoiceWakeWordSensitivityDescription =>
      'Насколько легко срабатывает слово пробуждения.';

  @override
  String get settingVoiceWakeWordFineTuneTitle =>
      'Точная настройка чувствительности';

  @override
  String get settingVoiceWakeWordFineTuneDescription =>
      'Меняет чувствительность слова пробуждения более мелкими шагами. Повысьте, если слово пробуждения часто приходится повторять, и понизьте, если оно срабатывает по ошибке.';

  @override
  String get settingVoiceNoiseGateTitle => 'Шумовой порог слова пробуждения';

  @override
  String get settingVoiceNoiseGateDescription =>
      'Пропускать распознавание слова пробуждения в тишине, экономя ЦП.';

  @override
  String get settingVoiceStopWordTitle => 'Перебивание стоп-словом';

  @override
  String get settingVoiceStopWordDescription =>
      'Скажите «стоп», чтобы оборвать ответ, оповещение таймера или объявление.';

  @override
  String get settingVoiceStopWordFineTuneTitle =>
      'Точная настройка чувствительности стоп-слова';

  @override
  String get settingVoiceStopWordFineTuneDescription =>
      'Меняет чувствительность стоп-слова более мелкими шагами. Повысьте, если «стоп» часто приходится повторять, и понизьте, если ответы обрываются по ошибке.';

  @override
  String get settingVoiceWakeArbitrationTitle =>
      'Включить арбитраж слова пробуждения';

  @override
  String get settingVoiceWakeArbitrationDescription =>
      'Когда несколько киосков слышат слово пробуждения, отвечает ближайший. Увеличивает задержку определения.';

  @override
  String get settingVoiceWakeArbitrationWindowTitle => 'Окно арбитража';

  @override
  String get settingVoiceWakeArbitrationWindowDescription =>
      'Сколько ждать другие киоски. Поднимите, если более медленный киоск проигрывает, находясь ближе.';

  @override
  String get settingVoiceWakeArbitrationOffsetTitle => 'Поправка арбитража';

  @override
  String get settingVoiceWakeArbitrationOffsetDescription =>
      'Прибавляется к тому, насколько громко этот киоск услышал слово активации. Поднимите, если этот киоск проигрывает, находясь ближе, и опустите, если он отвечает издалека.';

  @override
  String get voiceSectionWakeArbitration => 'Арбитраж слова пробуждения';

  @override
  String get voiceOptionSlightly => 'Слегка чувствительно';

  @override
  String get voiceOptionModerately => 'Умеренно чувствительно';

  @override
  String get voiceOptionVery => 'Очень чувствительно';

  @override
  String get voiceModelNotFileName => 'Это не имя файла.';

  @override
  String get voiceModelBadExtension =>
      'Моделями являются только файлы .json, .tflite и .onnx.';

  @override
  String voiceModelTooLarge(String name) {
    return '$name больше 64 МБ.';
  }

  @override
  String voiceModelIncomplete(String name) {
    return '$name пришёл неполным.';
  }

  @override
  String voiceModelBadJson(String file) {
    return '$file не является корректным JSON.';
  }

  @override
  String voiceModelNotManifest(String file) {
    return '$file не является манифестом.';
  }

  @override
  String voiceModelMwwNeedsTflite(String file) {
    return 'Модели microWakeWord нужен также $file.';
  }

  @override
  String voiceModelMwwBadManifest(String file) {
    return '$file не является корректным манифестом microWakeWord.';
  }

  @override
  String voiceModelVswwNeedsOnnx(String file) {
    return 'Модели vsWakeWord нужен также $file.';
  }

  @override
  String voiceModelVswwBadManifest(String file) {
    return '$file не является корректным манифестом vsWakeWord.';
  }

  @override
  String voiceModelUnknownManifest(String file) {
    return '$file не манифест ни microWakeWord, ни vsWakeWord.';
  }

  @override
  String voiceModelNoModelFile(String name) {
    return 'Нет файла модели для $name.';
  }

  @override
  String voiceModelBothFormats(String onnx, String tflite) {
    return 'Добавьте либо $onnx, либо $tflite, не оба.';
  }

  @override
  String voiceModelNotOwwTflite(String file, String json) {
    return '$file не модель openWakeWord. Модели microWakeWord нужен также её $json.';
  }

  @override
  String get voiceModelNotTflite => 'Не модель TFLite.';

  @override
  String get voiceModelNotOnnx => 'Не модель ONNX.';

  @override
  String get voiceModelNotOww => 'Не модель openWakeWord.';

  @override
  String get voiceModelOwwWindow =>
      'Не модель openWakeWord: не принимает окно эмбеддингов 16 x 96.';

  @override
  String voiceModelNoLoad(String error) {
    return 'Модель не загружается: $error';
  }

  @override
  String get settingVoiceAmazonLocaleTitle => 'Язык слова пробуждения';

  @override
  String get settingVoiceAmazonLocaleDescription =>
      'Язык моделей слов пробуждения Amazon. В списках слов пробуждения доступны слова пробуждения этого языка.';

  @override
  String get settingDisableCacheTitle => 'Отключить кэш';

  @override
  String get settingDisableCacheDescription =>
      'Всегда брать из сети и отбрасывать кэш страницы при загрузке, чтобы обновлённая панель всегда возвращалась свежей. Медленно; считайте помощью для разработки.';

  @override
  String get settingAllowMixedContentTitle => 'Разрешить смешанный контент';

  @override
  String get settingAllowMixedContentDescription =>
      'Позволить HTTPS-страницам грузить небезопасные HTTP-ресурсы. Помогает, когда Home Assistant подмешивает http:// контент в https:// панель.';

  @override
  String get settingIgnoreSslErrorsTitle => 'Игнорировать ошибки SSL';

  @override
  String get settingIgnoreSslErrorsDescription =>
      'Принимать недоверенные или самоподписанные сертификаты. Используйте только в собственной сети: это отключает проверку сертификатов.';

  @override
  String get webGeolocationSection => 'Геолокация HTML5';

  @override
  String get settingWebGeolocationTitle => 'Включить доступ к геолокации';

  @override
  String get settingWebGeolocationDescription =>
      'Позволяет страницам читать местоположение устройства, например для погодного радара или карты. Запрашивать его могут только страницы, загруженные по HTTPS.';

  @override
  String get webGeolocationPermissionHeld =>
      'Страницы могут читать местоположение устройства.';

  @override
  String get webGeolocationPermissionMissing =>
      'Без этого разрешения страницы не могут читать местоположение устройства.';

  @override
  String get settingAutoReloadOnErrorTitle => 'Автоперезагрузка при ошибке';

  @override
  String get settingAutoReloadOnErrorDescription =>
      'Восстанавливаться автоматически после сбоев страницы и падений приложения.';

  @override
  String get settingPullToRefreshTitle => 'Включить «Потяните для обновления»';

  @override
  String get settingPullToRefreshDescription =>
      'Потяните вниз от верха страницы, чтобы перезагрузить её. По умолчанию выключено: на прокручиваемой панели легко потянуть случайно.';

  @override
  String get settingPullToRefreshClearCacheTitle =>
      'Очищать кэш при обновлении свайпом вниз';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      'Потягивание также очищает веб-кэш и модели слова пробуждения перед перезагрузкой, чтобы всё вернулось свежим. Вход и сохранённые данные страницы остаются.';

  @override
  String get settingBrowserZoomTitle => 'Масштаб';

  @override
  String get settingBrowserZoomDescription =>
      'Масштабирует всю страницу. Выше 1x для настенных планшетов, на которые смотрят издалека; ниже 1x вмещает больше панели на маленький экран.';

  @override
  String get settingPinchToZoomTitle => 'Включить масштабирование щипком';

  @override
  String get settingPinchToZoomDescription =>
      'Масштабировать страницу щипком двумя пальцами. По умолчанию выключено, чтобы панель киоска не смещалась от случайных касаний.';

  @override
  String get settingDisableScrollingTitle => 'Отключить прокрутку';

  @override
  String get settingDisableScrollingDescription =>
      'Заморозить страницу, чтобы её нельзя было прокрутить ни в каком направлении. Касания и кнопки продолжают работать.';

  @override
  String get browserCrashPermissionHelp =>
      'Без этого киоск не может вернуться после сбоя.';

  @override
  String get browserCrashPermissionMissing =>
      'Нет разрешения «Поверх других приложений»';

  @override
  String get browserCrashPermissionRemoteHelp =>
      'Без этого киоск не может вернуться после сбоя. Экран выдачи разрешения появится на планшете.';

  @override
  String get settingBrowserInjectJsTitle => 'Внедрять JavaScript на панель HA';

  @override
  String get settingBrowserInjectJsDescription =>
      'Выполнять этот код JavaScript после каждой загрузки страницы панели. Полезно, чтобы спрятать мешающие элементы или подправить панель, которой вы не управляете.';

  @override
  String get settingBrowserInjectJsExternalTitle =>
      'Внедрять JavaScript на внешние страницы';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      'Выполнять этот код JavaScript после загрузки каждой внешней страницы: открытых ссылкой с панели, страниц ротации панели и заставки «Веб-сайт». Страница Music Assistant не трогается.';

  @override
  String get browserInjectJsPlaceholder =>
      '// Пример: скрыть мешающий элемент\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// Пример: приблизить сайт, игнорирующий масштаб панели\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get urlFilterTitle => 'Фильтр URL';

  @override
  String get urlFilterHint =>
      'Блокировка или разрешение страниц по шаблону адреса или регулярному выражению';

  @override
  String get urlFilterIntroTitle => 'Какие страницы открываются';

  @override
  String get urlFilterIntroSub =>
      'Ссылки или страницы, подходящие под правило «Блокировать», не загружаются. Добавьте правило «Только разрешить», чтобы загружались только подходящие под него страницы.';

  @override
  String get urlFilterAdd => 'Добавить правило';

  @override
  String get urlFilterAddTitle => 'Добавить правило фильтра';

  @override
  String get urlFilterEditTitle => 'Изменить правило фильтра';

  @override
  String get urlFilterName => 'Название';

  @override
  String get urlFilterPattern => 'Шаблон';

  @override
  String get urlFilterPatternWildcardHint =>
      'Используйте * для совпадения с чем угодно. Шаблон, начинающийся с /, совпадает с путём на любом сервере, например /history*.';

  @override
  String get urlFilterPatternRegexHint =>
      'Регулярное выражение, которое ищется в любом месте адреса без учёта регистра.';

  @override
  String get urlFilterType => 'Тип шаблона';

  @override
  String get urlFilterTypeWildcard => 'Подстановочный знак';

  @override
  String get urlFilterTypeRegex => 'Регулярное выражение';

  @override
  String get urlFilterAction => 'Действие';

  @override
  String get urlFilterActionBlock => 'Блокировать';

  @override
  String get urlFilterActionAllow => 'Только разрешить';

  @override
  String get urlFilterActionAllowHint =>
      'Там, где действует это правило, загружаются только страницы, подходящие под правило «Только разрешить». Вход в Home Assistant и стартовая панель загружаются всегда.';

  @override
  String get urlFilterScope => 'Применяется к';

  @override
  String get urlFilterScopeAll => 'Панель и внешние страницы';

  @override
  String get urlFilterScopeDashboard => 'Панель';

  @override
  String get urlFilterScopeExternal => 'Внешние страницы';

  @override
  String get urlFilterScopeHint =>
      'Внешние страницы: ссылки, открытые с панели, и страницы ротации панели.';

  @override
  String get urlFilterErrorName => 'Введите название.';

  @override
  String get urlFilterErrorPattern => 'Введите шаблон.';

  @override
  String get urlFilterErrorRegex => 'Это регулярное выражение недопустимо.';

  @override
  String get urlFilterBlocked => 'Страница заблокирована';

  @override
  String get urlFilterNotAllowed => 'Нет среди разрешённых страниц';

  @override
  String get settingBrowserUrlFilterNoticeTitle =>
      'Показывать уведомление о блокировке';

  @override
  String get settingBrowserUrlFilterNoticeDescription =>
      'Показывать короткое уведомление с названием правила, когда страница заблокирована.';

  @override
  String get setupConnectHeading => 'Подключение к Home Assistant';

  @override
  String get setupConnectLead =>
      'Базовый URL вашего экземпляра и долгоживущий токен доступа, созданный в профиле HA: Безопасность, Долгоживущие токены доступа.';

  @override
  String get setupBaseUrl => 'Базовый URL Home Assistant';

  @override
  String get setupToken => 'Долгоживущий токен доступа';

  @override
  String get setupScanQr => 'Сканировать QR-код';

  @override
  String get setupInvalidToken => 'Недействительный токен доступа';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant отклонил этот токен. В Home Assistant откройте свой профиль, затем Безопасность, затем Долгоживущие токены доступа, создайте новый токен и скопируйте значение целиком.';

  @override
  String get setupUnreachable => 'Home Assistant недоступен';

  @override
  String get setupUnreachableHelp =>
      'По этому адресу нет ответа. Проверьте правильность URL и что устройство в одной сети с сервером Home Assistant.';

  @override
  String get setupUnexpectedResponseHelp =>
      'Сервер ответил, но это, похоже, не Home Assistant. Проверьте, что URL является базовым адресом вашего Home Assistant, например https://homeassistant.local:8123.';

  @override
  String get setupCannotConnect => 'Не удаётся подключиться';

  @override
  String get setupCameraPermission => 'Нужно разрешение на камеру';

  @override
  String get setupCameraBlocked =>
      'Разрешите камеру для Kiosk Satellite в настройках Android, чтобы отсканировать QR-код.';

  @override
  String get setupCameraAllow =>
      'Разрешите камеру, чтобы отсканировать QR-код.';

  @override
  String get setupEnterBaseUrl => 'Введите базовый URL Home Assistant';

  @override
  String get setupInvalidBaseUrl => 'Недействительный базовый URL';

  @override
  String get setupBaseUrlHelp =>
      'Это адрес, по которому вы открываете Home Assistant, например https://homeassistant.local:8123.';

  @override
  String get setupEnterToken => 'Введите долгоживущий токен доступа';

  @override
  String get setupEnterTokenHelp =>
      'В Home Assistant откройте свой профиль, затем Безопасность, затем Долгоживущие токены доступа, чтобы создать его.';

  @override
  String get setupValidateContinue => 'Проверить и продолжить';

  @override
  String setupUnexpectedResponse(String error) {
    return 'Неожиданный ответ ($error)';
  }

  @override
  String get baseUrlInvalid =>
      'Введите корректный URL, например https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      'Введите только базовый URL, без пути к панели. Пример: https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      'Введите только базовый URL, ничего не добавляя после порта. Пример: https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => 'Выберите панель';

  @override
  String get setupDashboardHelp => 'Это киоск будет показывать при запуске.';

  @override
  String get setupSelectDashboard => 'Выбор панели';

  @override
  String get setupSelectDashboardHelp =>
      'Выберите панель, которую покажет киоск. Позже её можно сменить в настройках.';

  @override
  String get setupHeadlessGrants =>
      'У этого устройства нет экрана, поэтому Android не может запросить их на нём. Выдайте каждое через adb, а затем завершите здесь.';

  @override
  String get setupWelcome => 'Добро пожаловать';

  @override
  String get setupConnect => 'Подключение';

  @override
  String get setupConnectSummary => 'URL и токен Home Assistant';

  @override
  String get setupDashboard => 'Панель';

  @override
  String get setupDashboardSummary => 'Что показывает киоск';

  @override
  String get setupRecommendedSummary => 'Рекомендуемые настройки';

  @override
  String get setupPermissions => 'Разрешения';

  @override
  String get setupPermissionsSummary => 'Что нужно настройке';

  @override
  String get setupPermissionLead =>
      'Android запросит эти разрешения. Всё запрашивается сразу, чтобы киоск потом вас не прерывал.';

  @override
  String get setupRemotePermissionLead =>
      'Android запросит их на самом планшете. Подойдите и примите запросы, затем завершите здесь.';

  @override
  String get setupMicrophoneHelp =>
      'Voice Satellite и интеркому нужен доступ к микрофону';

  @override
  String get setupNotificationListening =>
      'Разрешает постоянное уведомление службы Kiosk Satellite, показывающее, что она удерживает и когда киоск слушает.';

  @override
  String get setupBatteryService =>
      'Позволяет службе Kiosk Satellite работать в фоне без приостановки или завершения.';

  @override
  String get setupOverlayBoot =>
      'Позволяет Kiosk Satellite возвращаться после сбоя и стартовать при загрузке устройства.';

  @override
  String get setupOverlayCrash =>
      'Позволяет Kiosk Satellite возвращаться на экран после сбоя.';

  @override
  String get setupBrightnessHelp =>
      'Позволяет Kiosk Satellite задавать реальную яркость экрана (изменение системных настроек).';

  @override
  String get setupScreenControl => 'Управление экраном';

  @override
  String get setupScreenControlHelp =>
      'Позволяет Kiosk Satellite выключать экран по запросу (администратор устройства).';

  @override
  String get setupGrantPermissions => 'Выдать разрешения на устройстве';

  @override
  String get setupRequestingPermissions => 'Запрос на устройстве…';

  @override
  String get setupPermissionsRequested => 'Разрешения запрошены на устройстве';

  @override
  String get setupQrFlipCamera => 'Сменить камеру';

  @override
  String get setupQrCameraFailed => 'Не удалось запустить камеру.';

  @override
  String get setupQrTitle => 'Сканируйте QR-код токена';

  @override
  String get setupQrHelp =>
      'Он появляется рядом с только что созданным токеном в вашем профиле Home Assistant.';

  @override
  String get setupQrFlashOff => 'Выключить фонарик';

  @override
  String get setupQrFlashOn => 'Включить фонарик';

  @override
  String get setupQrScreenLightOff => 'Выключить подсветку экраном';

  @override
  String get setupQrScreenLightOn => 'Включить подсветку экраном';

  @override
  String get setupPasswordFirst => 'Сначала задайте пароль администратора';

  @override
  String get setupPasswordBeforeImport =>
      'Введите пароль администратора выше (минимум 4 символа), затем импортируйте резервную копию.';

  @override
  String get setupPasswordFailed => 'Не удалось задать пароль';

  @override
  String get setupPasswordExists => 'Пароль уже задан';

  @override
  String get setupPasswordExistsHelp =>
      'Войдите с паролем, заданным на планшете, чтобы продолжить здесь. Перезагрузка…';

  @override
  String get setupNotBackup => 'Это не файл резервной копии';

  @override
  String get setupInvalidBackupHelp =>
      'Файл не является корректным JSON. Экспортируйте конфигурацию из настроек настроенного Kiosk Satellite или из его удалённого администрирования.';

  @override
  String get setupWrongBackupKind =>
      'Экспортируйте конфигурацию из вкладки настроек настроенного Kiosk Satellite.';

  @override
  String get setupImportFailedHelp => 'Не удалось применить файл.';

  @override
  String get setupBackupNoDashboard => 'В копии нет панели';

  @override
  String get setupBackupNoDashboardHelp =>
      'Настройки применены, но копия снята до настройки устройства, поэтому показывать панель нечего. Продолжите мастер, чтобы выбрать её.';

  @override
  String get setupImporting => 'Импорт…';

  @override
  String get setupRemoteRestoreHelp =>
      'Импортируйте конфигурацию, экспортированную из Kiosk Satellite, и пропустите остальную часть мастера.';

  @override
  String get setupFinishOnDevice => 'Завершите на устройстве';

  @override
  String get setupFinishOnDeviceHelp =>
      'Конфигурация импортирована. Ответьте на запросы разрешений на экране планшета: эта страница продолжится сама, когда панель загрузится.';

  @override
  String get setupBackupObject =>
      'Резервная копия должна содержать JSON-объект.';

  @override
  String get setupBackupKind => 'Это не файл конфигурации Kiosk Satellite.';

  @override
  String get setupBackupSettings => 'В резервной копии нет настроек.';

  @override
  String get setupServiceHelp =>
      'Поддерживает работу приложения при выключенном экране или когда на экране другое приложение, чтобы соединение с Home Assistant и другие функции вроде определения движения и Bluetooth-прокси продолжали работать. Разрешения ниже необязательны, но рекомендованы: каждое помогает приложению работать при выключенном экране.';

  @override
  String get setupBatteryMissing =>
      'Android может приостановить приложение при выключенном экране, разорвав соединение с Home Assistant.';

  @override
  String get setupOverlayMissing =>
      'Без этого служба не сможет перезапустить киоск после сбоя.';

  @override
  String get setupVoiceDetected => 'Voice Satellite обнаружен';

  @override
  String get setupVoiceHelp =>
      'Этот экземпляр Home Assistant работает с интеграцией Voice Satellite. Выберите, каким спутником является этот киоск, затем просмотрите его настройки. Всё можно изменить позже.';

  @override
  String get setupNoSatellites => 'Спутники не найдены';

  @override
  String get setupNoSatellitesHelp =>
      'Добавьте assist-спутник в интеграцию Voice Satellite или продолжите без него и выберите на панели позже.';

  @override
  String get setupNewSatelliteHelp =>
      'Если это новое устройство, сначала создайте новую сущность спутника в Home Assistant. Настройки → Устройства и службы → Voice Satellite → Добавить запись. ВАЖНО: два устройства не могут использовать одну сущность.';

  @override
  String get setupApplyRecommended => 'Применить все рекомендуемые настройки';

  @override
  String get setupRecommendedHelp =>
      'Оптимальные настройки для полной интеграции и работы Voice Satellite.';

  @override
  String get setupVoiceRequired => 'Требуется для Voice Satellite';

  @override
  String get setupMicrophoneAccess => 'Доступ к микрофону';

  @override
  String get setupNativeWakeWord => 'Нативное определение слова пробуждения';

  @override
  String get setupPullRefresh => 'Потяните для обновления';

  @override
  String get setupAutoplay => 'Автовоспроизведение звука и видео';

  @override
  String get setupVoiceSkipped => 'Не установлено, пропущено';

  @override
  String get setupVoiceLead =>
      'Превратить этот киоск в голосового ассистента Home Assistant. Всё можно изменить позже.';

  @override
  String get setupVoiceAddAgainHint =>
      'После настройки добавьте этот киоск в Home Assistant в разделе Настройки, Устройства и службы, где он появится как обнаруженный. Если Home Assistant уже знал его, там он запросит новый Ключ шифрования со страницы ESPHome.';

  @override
  String get setupRecommendedWall => 'Настройки, подходящие киоску на стене.';

  @override
  String get setupVoiceFound => 'Интеграция Voice Satellite найдена';

  @override
  String get setupVoiceFoundHelp =>
      'Voice Satellite теперь работает внутри Kiosk Satellite. Выполните миграцию, чтобы сохранить слова пробуждения, ассистента и облик одного из спутников интеграции вместо старта с нуля.';

  @override
  String get setupVoiceMigrated =>
      'Миграция из интеграции Voice Satellite выполнена';

  @override
  String get setupVoiceMigratedHelp =>
      'Этот киоск принимает настройки своего спутника.';

  @override
  String get setupVoicePipelineHelp =>
      'Конвейер Assist, отвечающий на слово пробуждения.';

  @override
  String get setupVoiceEngineHelp => 'Движок, слушающий слово пробуждения.';

  @override
  String get setupRemoteHeading => 'Удалённое администрирование';

  @override
  String get setupTitle => 'Настройка\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      'Превратите этот планшет в киоск Home Assistant. Настройка занимает пару минут, и этот мастер проведёт вас через неё.';

  @override
  String get setupDeviceName => 'Имя устройства';

  @override
  String get setupDeviceNameHelp =>
      'Как этот киоск называется в Home Assistant, в удалённом администрировании и в сети. Меняйте в любой момент: Настройки, Устройство.';

  @override
  String get setupEnableRemote => 'Включить удалённое администрирование';

  @override
  String get setupEnableRemoteHelp =>
      'Продолжайте управлять этим киоском из веб-браузера после настройки: вставить токен доступа Home Assistant там гораздо проще.';

  @override
  String get setupRemotePassword => 'Пароль удалённого администрирования';

  @override
  String get setupRestoreHeading => 'Восстановление из копии';

  @override
  String get setupRestore => 'Восстановить из файла конфигурации';

  @override
  String get setupRestoreHelp =>
      'Импортируйте конфигурацию, экспортированную из Kiosk Satellite, и пропустите остальную часть мастера. Настройки, панель и вход переносятся вместе.';

  @override
  String get setupServicePermissions => 'Рекомендуемые разрешения службы';

  @override
  String get setupPasswordShort => 'Пароль слишком короткий';

  @override
  String get setupPasswordMinimum => 'Используйте минимум 4 символа.';

  @override
  String setupRemoteAddress(String address) {
    return 'Эту настройку можно продолжить удалённо из веб-браузера по адресу $address, включён переключатель выше или нет.';
  }

  @override
  String get remoteWelcomeTitle => 'Добро пожаловать в Kiosk Satellite';

  @override
  String get remoteWelcomePassword =>
      'Планшет ждёт настройки. Сначала защитите это удалённое администрирование паролем.';

  @override
  String get remoteWelcomeReady =>
      'Планшет ждёт настройки. Пароль удалённого администрирования уже задан; введите новый здесь, чтобы сменить его.';

  @override
  String get remoteInitialPassword => 'Пароль администратора (мин. 4 символа)';

  @override
  String get remoteNewPassword =>
      'Новый пароль администратора (оставьте пустым, чтобы сохранить текущий)';

  @override
  String get intercomBuiltinRing => 'Встроенный звонок';

  @override
  String get intercomBuiltinChime => 'Встроенный сигнал';

  @override
  String intercomMissingFile(String file) {
    return '$file (отсутствует)';
  }

  @override
  String get intercomAddSound => 'Добавить звук';

  @override
  String get intercomCopySoundHelp =>
      'Скопировать звуковой файл с этого устройства в папку звуков.';

  @override
  String get intercomUploadSoundHelp =>
      'Загрузить звуковой файл с этого компьютера в папку звуков.';

  @override
  String get intercomUpload => 'Загрузить';

  @override
  String get intercomUploading => 'Загрузка…';

  @override
  String get intercomUnsupportedSound => 'Неподдерживаемый звук';

  @override
  String get intercomChooseSound =>
      'Неподдерживаемый звук: выберите файл MP3, OGG, WAV, FLAC, M4A или AAC.';

  @override
  String get intercomCopyFailed => 'Не удалось скопировать файл';

  @override
  String intercomUploadFailed(String error) {
    return 'Не удалось загрузить: $error';
  }

  @override
  String intercomSaveFailed(String error) {
    return 'Не сохранено: $error';
  }

  @override
  String get intercomSoundFilename => 'Введите имя файла, а не путь.';

  @override
  String get intercomSoundFormats =>
      'Выберите файл MP3, OGG, WAV, FLAC, M4A или AAC.';

  @override
  String get voiceNoticeError => 'Ошибка Voice Satellite';

  @override
  String get voiceNoticeWarning => 'Предупреждение Voice Satellite';

  @override
  String get voiceNoticeNotice => 'Уведомление Voice Satellite';

  @override
  String get voiceNoticeTts => 'Синтез речи';

  @override
  String get voiceNoticeAssistPipeline => 'Конвейер Assist';

  @override
  String voiceNoticePipeline(String name) {
    return 'Конвейер «$name»';
  }

  @override
  String get voiceNoticeMicUnavailable => 'Микрофон недоступен.';

  @override
  String get voiceNoticeNotConnected =>
      'Home Assistant не подключён к этому киоску.';

  @override
  String get voiceNoticeConnectionLost =>
      'Соединение с Home Assistant потеряно. Переподключение выполняется автоматически.';

  @override
  String get voiceNoticePlayback =>
      'Не удалось воспроизвести звук на устройстве.';

  @override
  String get voiceNoticeWatchdog =>
      'Home Assistant не ответил после того, как вы закончили говорить. Конвейер мог зависнуть.';

  @override
  String get voiceNoticeRefused =>
      'Home Assistant не смог запустить ассистента.';

  @override
  String get voiceNoticeUnexpected => 'Произошла неожиданная ошибка конвейера.';

  @override
  String get voiceNoticeMicBlocked =>
      'Доступ к микрофону заблокирован. Разрешите его для Kiosk Satellite в настройках Android.';

  @override
  String get voiceNoticeMicDeclined =>
      'Доступ к микрофону отклонён, поэтому слово пробуждения не слышно.';

  @override
  String get voiceNoticeMicLost => 'Микрофон перестал работать.';

  @override
  String get voiceNoticeModels =>
      'Не удалось загрузить модели слова пробуждения.';

  @override
  String get voiceNoticeCrashed =>
      'Детектор слова пробуждения постоянно падал на этом устройстве и был остановлен.';

  @override
  String voiceFinancialOpen(String value) {
    return 'Открытие: $value';
  }

  @override
  String voiceFinancialHigh(String value) {
    return 'Максимум: $value';
  }

  @override
  String voiceFinancialLow(String value) {
    return 'Минимум: $value';
  }

  @override
  String voiceFinancialHigh24h(String value) {
    return 'Максимум за 24 ч: $value';
  }

  @override
  String voiceFinancialLow24h(String value) {
    return 'Минимум за 24 ч: $value';
  }

  @override
  String voiceFinancialMarketCap(String value) {
    return 'Капитализация: $value';
  }

  @override
  String get voiceTimerDefaultName => 'Таймер';

  @override
  String get voiceTimerDrag => 'Перетащите, чтобы переместить таймеры';

  @override
  String get voiceTimerPauseHint =>
      'Коснитесь для паузы. Двойное касание: отмена. Перетащите, чтобы переместить.';

  @override
  String get voiceTimerResumeHint =>
      'Коснитесь для возобновления. Двойное касание: отмена. Перетащите, чтобы переместить.';

  @override
  String get voiceTimerCancel => 'Отменить таймер';

  @override
  String get voiceTimerActionError =>
      'Не удалось изменить таймер. Проверьте соединение и при необходимости обновите Voice Satellite.';

  @override
  String get voiceTimerFinished => 'Таймер завершён';

  @override
  String get voiceTimerDismissHint =>
      'Коснитесь, чтобы скрыть оповещение таймера.';

  @override
  String get voiceTimersViewTitle => 'Таймеры';

  @override
  String get voiceTimersEmpty => 'Нет таймеров';

  @override
  String get voiceTimerPause => 'Пауза';

  @override
  String get voiceTimerResume => 'Продолжить';

  @override
  String get voiceTimerDismiss => 'Скрыть';

  @override
  String get voiceTimerTimesUp => 'Время вышло';

  @override
  String get voiceTimerPaused => 'Приостановлено';

  @override
  String get voiceTimersShareNone => 'Киоски не выбраны';

  @override
  String get voiceTimersShareEmpty =>
      'Другие киоски не найдены. Включите на каждом «Удалённое управление» и «Поиск других киосков».';

  @override
  String get voiceTimersShareOffline => 'Не в сети';

  @override
  String get timersVoiceSection => 'Голосовые таймеры';

  @override
  String get timersVoiceManage => 'Управление таймерами через Voice Satellite';

  @override
  String get timersVoiceHint =>
      'Работает без Blueprint и диалогового LLM-агента.';

  @override
  String get voiceTimersShareSearch => 'Поиск киосков';

  @override
  String get voiceTimerSetATimer => 'Установить таймер';

  @override
  String get voiceTimerEditTimer => 'Изменить таймер';

  @override
  String get voiceTimerName => 'Название';

  @override
  String get voiceTimerHours => 'Часы';

  @override
  String get voiceTimerMinutes => 'Минуты';

  @override
  String get voiceTimerSeconds => 'Секунды';

  @override
  String get voiceTimerStartFailed => 'Не удалось запустить таймер.';

  @override
  String get timersManage => 'Управление таймерами';

  @override
  String get voiceTimerStartUnavailable =>
      'Включите Voice Satellite на этом киоске, чтобы устанавливать таймеры здесь.';
}
