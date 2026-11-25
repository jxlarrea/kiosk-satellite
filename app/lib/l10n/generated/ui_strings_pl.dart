// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class UiStringsPl extends UiStrings {
  UiStringsPl([String locale = 'pl']) : super(locale);

  @override
  String get aboutApp => 'Aplikacja';

  @override
  String get aboutVersion => 'Wersja aplikacji';

  @override
  String get aboutBuild => 'Typ kompilacji';

  @override
  String get aboutPackage => 'Pakiet';

  @override
  String get aboutAttribution => 'Autorstwo';

  @override
  String get aboutAuthor => 'Autor';

  @override
  String get aboutWebsite => 'Strona internetowa';

  @override
  String get aboutSourceCode => 'Kod źródłowy';

  @override
  String get aboutLicense => 'Licencja';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite jest bezpłatny do użytku osobistego i niekomercyjnego. Jest udostępniany na licencji CC BY-NC-ND 4.0: wolno go używać i udostępniać, ale komercyjne wykorzystanie aplikacji oraz rozpowszechnianie zmodyfikowanych kompilacji aplikacji są niedozwolone. Niezależne wtyczki mają dodatkowe zezwolenie określone w PLUGIN-EXCEPTION.md.';

  @override
  String get aboutLocalizationCredits => 'Autorzy tłumaczeń';

  @override
  String get aboutLocalizationCreditsHint => 'Współtwórcy według języków';

  @override
  String get aboutCheckNow => 'Sprawdź aktualizacje teraz';

  @override
  String get aboutChecking => 'Sprawdzanie…';

  @override
  String get aboutCheckFailed =>
      'Nie udało się sprawdzić aktualizacji. Czy urządzenie ma dostęp do serwisu GitHub?';

  @override
  String get aboutOverlayMissing =>
      'Brak uprawnienia „Wyświetlanie nad innymi aplikacjami”';

  @override
  String get aboutOverlayHelp =>
      'Bez niego aplikacja nie może sama uruchomić się ponownie po aktualizacji. Ekran przyznawania uprawnienia pojawi się na tablecie.';

  @override
  String aboutDownloadProgress(String percent) {
    return 'Pobieranie… $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return 'Aktualizacja nie powiodła się: $error';
  }

  @override
  String get aboutAlreadyCurrent => 'Wersja jest już aktualna';

  @override
  String get aboutInstallHelp =>
      'Pobieranie odbywa się na tablecie; instalację trzeba potwierdzić na ekranie tabletu.';

  @override
  String get aboutSystem => 'System';

  @override
  String get aboutSystemVersion => 'Wersja ROM';

  @override
  String get aboutSystemVerifying => 'Weryfikowanie…';

  @override
  String get aboutSystemInstalling => 'Instalowanie…';

  @override
  String get aboutSystemRestartHelp =>
      'Urządzenie uruchomi się ponownie dwa razy, aby zainstalować aktualizację, i przez kilka minut będzie niedostępne.';

  @override
  String get aboutSystemManual => 'Dostępny jest nowy obraz';

  @override
  String aboutSystemManualHelp(String version) {
    return 'Wersję $version nowego obrazu dla Echo Dot instaluje się ręcznie, nie jako aktualizację.';
  }

  @override
  String get alarmsTitle => 'Budziki';

  @override
  String get alarmsSetAnAlarm => 'Ustaw budzik';

  @override
  String get alarmsNone => 'Brak budzików';

  @override
  String get alarmsDone => 'Gotowe';

  @override
  String get alarmsRepeat => 'Powtarzanie';

  @override
  String get alarmsLabel => 'Etykieta';

  @override
  String get alarmsAddLabel => 'Dodaj etykietę';

  @override
  String get alarmsTone => 'Dźwięk budzika';

  @override
  String get alarmsSunrise => 'Wschód słońca';

  @override
  String get alarmsDefaultTone => 'Domyślny';

  @override
  String get alarmsBuiltInTone => 'Wbudowany dźwięk';

  @override
  String get alarmsSoundsFolder => 'Folder dźwięków';

  @override
  String get alarmsToday => 'Dzisiaj';

  @override
  String get alarmsTomorrow => 'Jutro';

  @override
  String get alarmsOnce => 'Jednorazowo';

  @override
  String get alarmsEveryDay => 'Codziennie';

  @override
  String get alarmsWeekdays => 'Dni robocze';

  @override
  String get alarmsWeekends => 'Weekendy';

  @override
  String alarmsSnoozedUntil(String time) {
    return 'Drzemka do $time';
  }

  @override
  String get alarmsSnooze => 'Drzemka';

  @override
  String get alarmsStop => 'Zatrzymaj';

  @override
  String get alarmsDefaultLabel => 'Budzik';

  @override
  String get alarmsSetToast => 'Ustawiono budzik';

  @override
  String alarmsRingsIn(String duration) {
    return 'Zadzwoni za $duration';
  }

  @override
  String alarmsDurationHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String alarmsDurationHours(String hours) {
    return '$hours h';
  }

  @override
  String alarmsDurationMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String alarmsAt(String time) {
    return 'Budzik o $time';
  }

  @override
  String alarmsSkipAlarm(String time) {
    return 'Pomiń budzik o $time';
  }

  @override
  String get alarmsNextWidget => 'Następny budzik';

  @override
  String get alarmsManage => 'Zarządzaj budzikami';

  @override
  String alarmsNextAt(String day, String time) {
    return 'Następny: $day o $time';
  }

  @override
  String get alarmsNoneSet => 'Brak ustawionych budzików';

  @override
  String get alarmsDefaultsSection => 'Ustawienia domyślne';

  @override
  String get alarmsTtsSection => 'Zamiana tekstu na mowę';

  @override
  String get alarmsEditAlarm => 'Edytuj budzik';

  @override
  String get alarmsTime => 'Godzina';

  @override
  String get alarmsRinging => 'Budzik dzwoni';

  @override
  String get alarmsSnoozed => 'Drzemka budzika';

  @override
  String get alarmsSunriseRunning => 'Wschód słońca przed budzikiem';

  @override
  String alarmsSunriseHint(String minutes) {
    return 'Przez $minutes min przed dzwonieniem ekran stopniowo się rozjaśnia.';
  }

  @override
  String get alarmsDeleteFailed => 'Nie udało się usunąć budzika.';

  @override
  String alarmsDuplicate(String time) {
    return 'Budzik o $time już istnieje';
  }

  @override
  String get alarmsEaseIn => 'Stopniowo zwiększaj głośność';

  @override
  String alarmsEaseHint(String seconds) {
    return 'Głośność narasta do poziomu budzika przez $seconds s.';
  }

  @override
  String get alarmsSpeak => 'Mów podczas dzwonienia';

  @override
  String get alarmsPhrase => 'Fraza';

  @override
  String alarmsPhraseVariables(String variables) {
    return 'Dostępne zmienne: $variables';
  }

  @override
  String get alarmsVoiceSection => 'Budziki głosowe';

  @override
  String get alarmsVoiceManage => 'Zarządzaj budzikami przez Voice Satellite';

  @override
  String get alarmsVoiceHint =>
      'Wymaga blueprintu budzików Kiosk Satellite i agenta konwersacji LLM w Home Assistant.';

  @override
  String get alarmsMusic => 'Muzyka';

  @override
  String get alarmsMusicNone => 'Brak';

  @override
  String get alarmsMusicRemove => 'Usuń muzykę';

  @override
  String get alarmsMusicHint =>
      'Gra zamiast dźwięku budzika. Jeśli muzyki nie da się odtworzyć, zabrzmi dźwięk budzika.';

  @override
  String get androidAccessibilityHelp =>
      'Zamyka obszar powiadomień i ekran ostatnich aplikacji za każdym razem, gdy się otworzą, a tryb kiosku lub tryb blokady chroni ekran. Kiosk Satellite nie odczytuje żadnej zawartości ekranu.';

  @override
  String get androidServiceChannelHelp =>
      'Widoczne, gdy Kiosk Satellite Service utrzymuje działanie aplikacji przy wyłączonym ekranie lub w tle za inną aplikacją.';

  @override
  String get androidServiceListening => 'nasłuchiwanie słowa wybudzającego';

  @override
  String get androidServiceRtspAudio => 'włączony dźwięk mikrofonu przez RTSP';

  @override
  String get androidServiceEsphome => 'udostępnianie ESPHome';

  @override
  String get androidServiceBluetooth => 'przekazywanie urządzeń Bluetooth';

  @override
  String get androidServiceCamera => 'monitorowanie kamery';

  @override
  String get androidServiceLocation => 'zgłaszanie lokalizacji';

  @override
  String get androidServiceRemote => 'udostępnianie zdalnej administracji';

  @override
  String get androidServiceKiosk => 'ochrona trybu kiosku';

  @override
  String get androidServiceSessions =>
      'utrzymywanie połączenia z Home Assistant';

  @override
  String get launcherErrorAndroidOnly =>
      'wyświetlanie listy aplikacji działa tylko w systemie Android';

  @override
  String launcherErrorListDetail(String error) {
    return 'nie udało się wyświetlić listy aplikacji: $error';
  }

  @override
  String launcherOpenFailed(String name) {
    return 'Nie udało się otworzyć aplikacji „$name”';
  }

  @override
  String get launcherUninstalled => 'Możliwe, że została odinstalowana.';

  @override
  String get launcherNoneHelp =>
      'Na razie brak. Wybierz aplikacje, które oferuje launcher.';

  @override
  String get launcherNone => 'Na razie brak';

  @override
  String get launcherListFailed => 'Nie udało się wyświetlić listy aplikacji';

  @override
  String launcherListError(String error) {
    return 'Nie udało się wyświetlić listy aplikacji: $error';
  }

  @override
  String get launcherListingFailed => 'błąd pobierania listy';

  @override
  String get launcherEmpty => 'Nie znaleziono aplikacji do uruchomienia.';

  @override
  String get launcherSearchApps => 'Szukaj aplikacji';

  @override
  String get calendarTitle => 'Kalendarz';

  @override
  String get calendarViewDay => 'Dzień';

  @override
  String get calendarViewWeek => 'Tydzień';

  @override
  String get calendarViewMonth => 'Miesiąc';

  @override
  String get calendarViewSchedule => 'Harmonogram';

  @override
  String get calendarToday => 'Dzisiaj';

  @override
  String get calendarTomorrow => 'Jutro';

  @override
  String get calendarPrevious => 'Wstecz';

  @override
  String get calendarNext => 'Dalej';

  @override
  String get calendarAllDay => 'Cały dzień';

  @override
  String calendarMore(String count) {
    return '+$count więcej';
  }

  @override
  String get calendarUpNext => 'Następne';

  @override
  String calendarStartsIn(String duration) {
    return 'za $duration';
  }

  @override
  String get calendarHappeningNow => 'Teraz';

  @override
  String get calendarLaterToday => 'Później dzisiaj';

  @override
  String get calendarNothingElseToday => 'Nic więcej na dziś';

  @override
  String get calendarNothingPlanned => 'Nic nie zaplanowano';

  @override
  String get calendarNothingThisWeek => 'W tym tygodniu nic nie zaplanowano';

  @override
  String get calendarEmptyTitle => 'Brak kalendarzy';

  @override
  String get calendarEmptyHint =>
      'Dodaj kalendarze Home Assistant do wyświetlania w menu „Ustawienia” > „Kalendarz”.';

  @override
  String calendarOffline(String time) {
    return 'Brak połączenia z Home Assistant. Wyświetlane są wydarzenia z godziny $time.';
  }

  @override
  String calendarTimeRange(String start, String end) {
    return '$start-$end';
  }

  @override
  String calendarPeopleTwo(String first, String second) {
    return '$first i $second';
  }

  @override
  String get calendarRepeatsDaily => 'Codziennie';

  @override
  String get calendarRepeatsWeekly => 'Co tydzień';

  @override
  String get calendarRepeatsMonthly => 'Co miesiąc';

  @override
  String get calendarRepeatsYearly => 'Co rok';

  @override
  String get calendarRepeats => 'Powtarzane';

  @override
  String get calendarDone => 'Gotowe';

  @override
  String get calendarCalendarsSection => 'Kalendarze';

  @override
  String get calendarAdd => 'Dodaj kalendarz';

  @override
  String get calendarAlreadyAdded => 'Ten kalendarz jest już na liście.';

  @override
  String get calendarOpen => 'Otwórz kalendarz';

  @override
  String get calendarOpenHint => 'Pokaż kalendarz na tym kiosku.';

  @override
  String get calendarEditName => 'Nazwa';

  @override
  String get calendarEditColor => 'Kolor';

  @override
  String get calendarEditPerson => 'Osoba';

  @override
  String get calendarEditPersonHint =>
      'Wyświetla zdjęcie tej osoby na etykietach kalendarza.';

  @override
  String get calendarEditPersonNone => 'Brak';

  @override
  String get calendarPickCalendar => 'Wybierz kalendarz';

  @override
  String get calendarPickPerson => 'Wybierz osobę';

  @override
  String get calendarColorTeal => 'Morski';

  @override
  String get calendarColorRust => 'Rdzawy';

  @override
  String get calendarColorBlue => 'Niebieski';

  @override
  String get calendarColorPlum => 'Śliwkowy';

  @override
  String get calendarColorOchre => 'Ochrowy';

  @override
  String get calendarColorSage => 'Szałwiowy';

  @override
  String get calendarColorRose => 'Różany';

  @override
  String get calendarColorSlate => 'Łupkowy';

  @override
  String get calendarColorCustom => 'Własny';

  @override
  String get calendarWidgetEvents => 'Liczba wydarzeń';

  @override
  String get calendarWidgetDays => 'Zakres dni';

  @override
  String get calendarWidgetTomorrow => 'Dziś i jutro';

  @override
  String get calendarWidgetWeek => 'Najbliższe 7 dni';

  @override
  String get calendarWidgetAllDay => 'Pokazuj wydarzenia całodniowe';

  @override
  String get calendarWidgetDots => 'Kolorowe kropki';

  @override
  String get calendarWidgetDotsHint =>
      'Oznaczaj wydarzenia kolorem kalendarza zamiast zdjęcia osoby.';

  @override
  String get calendarVoiceSection => 'Kalendarz głosowy';

  @override
  String get calendarVoiceManage =>
      'Zarządzaj kalendarzem za pomocą Voice Satellite';

  @override
  String get calendarVoiceHint =>
      'Wymaga blueprintu kalendarza Kiosk Satellite i agenta konwersacji LLM w Home Assistant.';

  @override
  String get calendarNewEvent => 'Nowe wydarzenie';

  @override
  String get calendarEditEvent => 'Edytuj wydarzenie';

  @override
  String get calendarFieldTitle => 'Tytuł';

  @override
  String get calendarFieldTitleHint => 'Dodaj tytuł';

  @override
  String get calendarFieldCalendars => 'Kalendarze';

  @override
  String get calendarFieldSharedHint =>
      'Wydarzenie pojawi się raz, w kolorach wszystkich wybranych kalendarzy.';

  @override
  String get calendarFieldStarts => 'Początek';

  @override
  String get calendarFieldEnds => 'Koniec';

  @override
  String get calendarFieldStartTime => 'Godzina rozpoczęcia';

  @override
  String get calendarFieldEndTime => 'Godzina zakończenia';

  @override
  String get calendarFieldEndsBeforeStart =>
      'Koniec przypada przed początkiem.';

  @override
  String get calendarFieldRepeat => 'Powtarzanie';

  @override
  String get calendarRepeatNever => 'Nie powtarza się';

  @override
  String get calendarRepeatWeekdays => 'W każdy dzień roboczy';

  @override
  String calendarRepeatWeeklyOn(String weekday) {
    return 'Co tydzień: $weekday';
  }

  @override
  String calendarRepeatMonthlyOn(String day) {
    return 'Co miesiąc w dniu $day';
  }

  @override
  String calendarRepeatYearlyOn(String date) {
    return 'Co roku w dniu $date';
  }

  @override
  String get calendarFieldLocation => 'Miejsce';

  @override
  String get calendarFieldLocationHint => 'Dodaj miejsce';

  @override
  String get calendarFieldNotes => 'Notatki';

  @override
  String get calendarFieldNotesHint => 'Dodaj notatki';

  @override
  String get calendarEventAdded => 'Dodano wydarzenie';

  @override
  String get calendarEventSaved => 'Zapisano zmiany';

  @override
  String get calendarEventDeleted => 'Usunięto wydarzenie';

  @override
  String get calendarSaveFailed => 'Nie udało się zapisać wydarzenia';

  @override
  String get calendarDeleteFailed => 'Nie udało się usunąć wydarzenia';

  @override
  String calendarEditReadOnly(String calendar) {
    return 'Kalendarz „$calendar” jest tylko do odczytu.';
  }

  @override
  String calendarEditGone(String calendar) {
    return 'Wydarzenia nie ma już w kalendarzu „$calendar”.';
  }

  @override
  String calendarEditNotAllowed(String calendar) {
    return 'Użytkownik Home Assistant, którego używa kiosk, nie może zmieniać kalendarza „$calendar”.';
  }

  @override
  String calendarDeleteTitle(String title) {
    return 'Usunąć „$title”?';
  }

  @override
  String calendarDeleteShared(String names) {
    return 'Zostanie usunięte ze wszystkich kalendarzy, w których się znajduje: $names.';
  }

  @override
  String calendarSaveRepeatTitle(String title) {
    return 'Zapisać zmiany wydarzenia „$title”?';
  }

  @override
  String get calendarSaveRepeatFollowing =>
      'Nowe powtarzanie zaczyna się od tego dnia.';

  @override
  String get calendarScopeThis => 'To wydarzenie';

  @override
  String get calendarScopeFollowing => 'To i następne wydarzenia';

  @override
  String get calendarScopeAll => 'Wszystkie wydarzenia';

  @override
  String get calendarEditingSection => 'Edytowanie';

  @override
  String calendarUpNextFor(String name) {
    return 'Następne: $name';
  }

  @override
  String get cameraViewerTitle => 'Widok kamery';

  @override
  String get cameraViewerConnecting => 'Łączenie…';

  @override
  String get cameraViewerReconnecting => 'Ponowne łączenie…';

  @override
  String cameraViewerTrying(String transport) {
    return 'Próba połączenia: $transport…';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return 'To urządzenie nie obsługuje dekodowania $codec';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return 'To urządzenie nie może odtwarzać strumieni $transport';
  }

  @override
  String get cameraViewerCannotDecodeStream =>
      'To urządzenie nie może zdekodować tego strumienia';

  @override
  String cameraViewerHaRetry(String seconds) {
    return 'Brak połączenia z Home Assistant. Ponowna próba za $seconds s';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return 'Brak połączenia z serwerem kamer. Ponowna próba za $seconds s';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return 'Połączenie nie powiodło się. Ponowna próba za $seconds s';
  }

  @override
  String get cameraViewerStartRetry =>
      'Serwer kamer nie mógł uruchomić tego strumienia. Ponowna próba…';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return 'Serwer kamer nie mógł uruchomić tego strumienia. Ponowna próba za $seconds s';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return 'Nie znaleziono strumienia na serwerze kamer. Ponowna próba za $seconds s';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return 'Serwer kamer odrzucił logowanie. Ponowna próba za $seconds s';
  }

  @override
  String get cameraViewerMissing => 'Brak strumienia w Go2RTC';

  @override
  String get commonImport => 'Importuj';

  @override
  String get commonBack => 'Wstecz';

  @override
  String get commonNext => 'Dalej';

  @override
  String get commonFinish => 'Zakończ';

  @override
  String get commonWorking => 'Przetwarzanie…';

  @override
  String get commonSettings => 'Ustawienia';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonOk => 'OK';

  @override
  String get commonGrant => 'Przyznaj';

  @override
  String get commonEnable => 'Włącz';

  @override
  String get commonRefresh => 'Odśwież';

  @override
  String get commonTest => 'Testuj';

  @override
  String get commonInstall => 'Zainstaluj';

  @override
  String get commonSave => 'Zapisz';

  @override
  String get commonRetry => 'Ponów';

  @override
  String get commonCopy => 'Kopiuj';

  @override
  String get commonAdd => 'Dodaj';

  @override
  String get commonRemove => 'Usuń';

  @override
  String get commonClose => 'Zamknij';

  @override
  String get commonClear => 'Wyczyść';

  @override
  String get commonBrowse => 'Przeglądaj';

  @override
  String get commonSet => 'Ustaw';

  @override
  String get commonHour => 'Godzina';

  @override
  String get commonMinute => 'Minuta';

  @override
  String get commonUp => 'W górę';

  @override
  String get commonDown => 'W dół';

  @override
  String get commonDelete => 'Usuń';

  @override
  String get commonSaveFailed => 'Nie udało się zapisać';

  @override
  String get commonColorWhite => 'Biały';

  @override
  String get commonColorWarm => 'Ciepły';

  @override
  String get commonColorAmber => 'Bursztynowy';

  @override
  String get commonColorRed => 'Czerwony';

  @override
  String get commonColorGreen => 'Zielony';

  @override
  String get commonColorBlue => 'Niebieski';

  @override
  String get commonColorCyan => 'Cyjan';

  @override
  String get commonColorDim => 'Przyciemniony';

  @override
  String get commonEdit => 'Edytuj';

  @override
  String get commonMoveUp => 'Przenieś w górę';

  @override
  String get commonMoveDown => 'Przenieś w dół';

  @override
  String get commonPreviousMonth => 'Poprzedni miesiąc';

  @override
  String get commonNextMonth => 'Następny miesiąc';

  @override
  String get commonLoading => 'Wczytywanie…';

  @override
  String get commonChoose => 'Wybierz';

  @override
  String get dlnaPortInvalid =>
      'Wpisz port od 1024 do 65535 lub pozostaw pole puste';

  @override
  String get commonSelectAll => 'Zaznacz wszystko';

  @override
  String get dashboardPickerSearch => 'Szukaj widoków';

  @override
  String get dashboardPickerSearchAll => 'Szukaj pulpitów i widoków';

  @override
  String get dashboardPickerCurrent => 'Bieżący';

  @override
  String get dashboardPickerDashboards => 'Pulpity';

  @override
  String get dashboardPickerSubviews => 'Widoki podrzędne';

  @override
  String get dashboardPickerSubview => 'Widok podrzędny';

  @override
  String get dashboardPickerWhole => 'Cały pulpit';

  @override
  String get dashboardPickerBuildsOwn => 'Tworzy własne widoki';

  @override
  String get dashboardPickerIngressPage => 'Strona ingress';

  @override
  String get dashboardPickerBuiltInPage => 'Strona Home Assistant';

  @override
  String get dashboardPickerWholeHelp =>
      'Ten pulpit tworzy własne widoki, więc kiosk otwiera go w całości.';

  @override
  String dashboardPickerViewCount(String count) {
    return 'Widoki: $count';
  }

  @override
  String get dashboardPickerOneView => '1 widok';

  @override
  String get dashboardPickerOffline =>
      'Nie udało się połączyć z Home Assistant';

  @override
  String get dashboardPickerOfflineHelp =>
      'Pulpity wczytają się po przywróceniu połączenia.';

  @override
  String get dashboardPickerTryAgain => 'Spróbuj ponownie';

  @override
  String get dashboardPickerEmpty => 'Brak pulpitów';

  @override
  String get dashboardPickerEmptyHelp =>
      'Tutaj pojawią się pulpity dodane w Home Assistant.';

  @override
  String get dashboardPickerNoMatch => 'Brak pasujących widoków';

  @override
  String dashboardPickerSelected(String count) {
    return 'Wybrane: $count';
  }

  @override
  String get dashboardPickerDone => 'Gotowe';

  @override
  String get dashboardPickerShowing => 'Wyświetlany';

  @override
  String get dashboardPickerMissing =>
      'Tego widoku nie ma już w Home Assistant. Wybierz inny.';

  @override
  String get dashboardPickerAddViews => 'Dodaj widoki';

  @override
  String get dashboardPickerDefault => 'Domyślny pulpit';

  @override
  String get dashboardPickerDefaultHelp =>
      'Widok wyświetlany przez kiosk po uruchomieniu.';

  @override
  String get dashboardPickerOnePage => '1 strona';

  @override
  String dashboardPickerPageCount(String count) {
    return 'Strony: $count';
  }

  @override
  String get dlnaCannotDecode =>
      'To urządzenie nie może zdekodować tego wideo.';

  @override
  String get dlnaCannotRead => 'Nie udało się odczytać tego pliku.';

  @override
  String get dlnaCannotPlay => 'Nie udało się odtworzyć tych multimediów.';

  @override
  String get dlnaSeeLogs => 'Szczegóły sprawdź w logach aplikacji';

  @override
  String get dlnaLoading => 'Wczytywanie multimediów';

  @override
  String get dlnaImageFailed => 'Nie udało się wyświetlić tego obrazu.';

  @override
  String get dlnaStop => 'Zatrzymaj odtwarzanie';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName: $actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => 'Akcja wtyczki';

  @override
  String get drawerPluginActionError => 'Nie udało się uruchomić tej akcji.';

  @override
  String get drawerDashboard => 'Pulpit';

  @override
  String get drawerHaKiosk => 'Tryb kiosku HA';

  @override
  String get drawerCameraView => 'Widok kamery';

  @override
  String get drawerIntercom => 'Interkom';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => 'Ukryj pływający odtwarzacz';

  @override
  String get drawerShowPlayer => 'Pokaż pływający odtwarzacz';

  @override
  String get drawerNowPlaying => 'Teraz odtwarzane';

  @override
  String get drawerScreensaver => 'Uruchom wygaszacz ekranu';

  @override
  String get drawerLockdown => 'Tryb blokady';

  @override
  String get drawerHoldOff => 'Wyłącz tryb wstrzymania';

  @override
  String get drawerHoldOn => 'Włącz tryb wstrzymania';

  @override
  String get drawerApps => 'Aplikacje';

  @override
  String get drawerClearCache => 'Wyczyść pamięć podręczną przeglądarki';

  @override
  String get drawerRestartDevice => 'Uruchom ponownie urządzenie';

  @override
  String get drawerRestartConfirm =>
      'Uruchomić ponownie to urządzenie? Kiosk Satellite uruchomi się ponownie po starcie systemu.';

  @override
  String get drawerRestart => 'Uruchom ponownie';

  @override
  String get drawerExitApplication => 'Zamknij aplikację';

  @override
  String get drawerExitConfirm => 'Zamknąć Kiosk Satellite?';

  @override
  String get drawerExit => 'Zamknij';

  @override
  String get drawerHoldActive => 'Tryb wstrzymania włączony';

  @override
  String get drawerHoldHelp =>
      'Wygaszacz ekranu i timery są wstrzymane · dotknij, aby wyłączyć';

  @override
  String get drawerThemeDark => 'Ciemny';

  @override
  String get drawerThemeLight => 'Jasny';

  @override
  String get drawerThemeAndroid => 'Zgodnie z Androidem';

  @override
  String get drawerItemsSearch => 'Szukaj pozycji menu';

  @override
  String get drawerItemsSettingsKept =>
      'Zawsze widoczne, gdy zdalna administracja jest wyłączona.';

  @override
  String drawerVersion(String version) {
    return 'Wersja $version';
  }

  @override
  String get drawerUpdateAvailable => 'Dostępna aktualizacja';

  @override
  String drawerUpdateInstall(String version) {
    return 'Wersja $version · dotknij, aby zainstalować';
  }

  @override
  String get drawerUpdateChecking => 'Sprawdzanie aktualizacji…';

  @override
  String get drawerUpdateCurrent => 'Aktualna wersja';

  @override
  String get drawerUpdateCurrentHelp => 'Zainstalowana jest najnowsza wersja.';

  @override
  String get drawerUpdateCheckFailed => 'Nie udało się sprawdzić aktualizacji';

  @override
  String get drawerUpdateOffline =>
      'Czy urządzenie ma połączenie z internetem?';

  @override
  String drawerUpdateTo(String version) {
    return 'Aktualizacja do wersji $version';
  }

  @override
  String get drawerUpdateInstructions =>
      'Pobieranie rozpocznie się po dotknięciu „Aktualizuj”. Android poprosi o potwierdzenie instalacji.';

  @override
  String get drawerUpdateRelaunch =>
      'Bez uprawnienia „Wyświetlanie nad innymi aplikacjami” aplikacja nie może ponownie uruchomić się po aktualizacji.';

  @override
  String get drawerUpdate => 'Aktualizuj';

  @override
  String get drawerUpdateDownloading => 'Pobieranie aktualizacji';

  @override
  String get drawerUpdateStarting => 'Rozpoczynanie…';

  @override
  String get drawerUpdateFailed => 'Aktualizacja nie powiodła się';

  @override
  String get drawerUpdates => 'Aktualizacje';

  @override
  String get drawerNoReleaseNotes => 'Brak informacji o zmianach.';

  @override
  String get entityPickerNoArea => 'Bez obszaru';

  @override
  String get entityPickerAll => 'Wszystkie';

  @override
  String get entityPickerChoose => 'Wybierz encję';

  @override
  String get entityPickerNoMatch => 'Brak wyników';

  @override
  String get entityPickerOfflineHelp =>
      'Encje zostaną wczytane po przywróceniu połączenia.';

  @override
  String get entityPickerMissing =>
      'Tej encji nie ma już w Home Assistant. Wybierz inną.';

  @override
  String get entityPickerOrderHint =>
      'Przeciągnij lub użyj strzałek, aby zmienić kolejność.';

  @override
  String get entityPickerFull => 'Usuń jedną, aby dodać kolejną.';

  @override
  String get entityPickerAdd => 'Dodaj encje';

  @override
  String entityPickerShowing(String count, String max) {
    return 'Wyświetlane: $count z $max';
  }

  @override
  String get esphomeAllExposed => 'Udostępniono wszystkie dostępne encje';

  @override
  String esphomeExcludedCount(String count) {
    return 'Wykluczone: $count';
  }

  @override
  String get esphomeEntitySearch => 'Szukaj encji';

  @override
  String get esphomeEntityLoading => 'Wczytywanie encji…';

  @override
  String get esphomeEntityUnavailable => 'Obecnie niedostępna';

  @override
  String get esphomeEntityNoMatch => 'Brak pasujących encji';

  @override
  String get esphomeEntityLoadFailed =>
      'Nie udało się wczytać encji. Zamknij okno wyboru i spróbuj ponownie.';

  @override
  String get esphomeEntitySaveFailed =>
      'Nie udało się zapisać wykluczeń. Spróbuj ponownie.';

  @override
  String get esphomeTypeConfig => 'Konfiguracja';

  @override
  String get esphomeTypeDiagnostics => 'Diagnostyka';

  @override
  String get esphomeTypeSensorGroup => 'Czujnik';

  @override
  String get esphomeTypeControl => 'Sterowanie';

  @override
  String get esphomeTypeSensor => 'czujnik';

  @override
  String get esphomeTypeTextSensor => 'czujnik tekstowy';

  @override
  String get esphomeTypeBinarySensor => 'czujnik binarny';

  @override
  String get esphomeTypeCamera => 'kamera';

  @override
  String get esphomeTypeSwitch => 'przełącznik';

  @override
  String get esphomeTypeButton => 'przycisk';

  @override
  String get esphomeTypeNumber => 'liczba';

  @override
  String get esphomeTypeSelect => 'lista wyboru';

  @override
  String get esphomeTypeLight => 'światło';

  @override
  String get esphomeTypeUpdate => 'aktualizacja';

  @override
  String get esphomeTypeText => 'tekst';

  @override
  String faceEnrollTitle(String name) {
    return 'Rejestrowanie twarzy: $name';
  }

  @override
  String faceEnrollStepOf(String step, String total) {
    return 'Krok $step z $total';
  }

  @override
  String get faceEnrollStepLook => 'Spójrz na ekran';

  @override
  String get faceEnrollStepSideA => 'Obróć lekko głowę w jedną stronę';

  @override
  String get faceEnrollStepSideB => 'Teraz lekko w drugą stronę';

  @override
  String get faceEnrollStepFar => 'Zrób krok do tyłu';

  @override
  String get faceEnrollHintNoFace => 'Nie widać twarzy';

  @override
  String get faceEnrollHintSeveral => 'W kadrze powinna być tylko jedna osoba';

  @override
  String get faceEnrollHintCloser => 'Podejdź trochę bliżej';

  @override
  String get faceEnrollHintFarther => 'Cofnij się jeszcze trochę';

  @override
  String get faceEnrollHintTurnMore => 'Obróć się trochę bardziej';

  @override
  String get faceEnrollHintTurnLess => 'Obróć się trochę z powrotem';

  @override
  String get faceEnrollHintOtherSide => 'Teraz w drugą stronę';

  @override
  String get faceEnrollHintDark => 'Za ciemno, by zobaczyć twarz';

  @override
  String get faceEnrollHintOtherFace => 'To inna twarz';

  @override
  String faceEnrollSaved(String name) {
    return 'Twarz zarejestrowana dla: $name';
  }

  @override
  String get faceEnrollSavedPartly =>
      'Zarejestrowano część twarzy. Zarejestruj ją ponownie, aby dokończyć.';

  @override
  String get faceEnrollTooShort =>
      'Twarz była widoczna zbyt krótko. Nic nie zapisano.';

  @override
  String get faceEnrollUnavailable =>
      'Rozpoznawanie twarzy wymaga Ground Control z włączonymi Vision Match i rozpoznawaniem twarzy.';

  @override
  String get faceEnrollLost =>
      'Utracono połączenie z Ground Control. Nic nie zapisano.';

  @override
  String get filesUpload => 'Prześlij plik';

  @override
  String get filesUploading => 'Przesyłanie…';

  @override
  String get filesUploadFailed => 'Przesyłanie nie powiodło się';

  @override
  String get filesUploaded => 'Przesłano';

  @override
  String filesUploadingProgress(String current, String total) {
    return 'Przesyłanie $current z $total…';
  }

  @override
  String filesUploadedCount(String count) {
    return 'Przesłane pliki: $count';
  }

  @override
  String get filesPermissionMissing =>
      'Brak uprawnienia „Dostęp do wszystkich plików”';

  @override
  String get filesPermissionHelp =>
      'Bez tego uprawnienia można przeglądać tylko folder aplikacji. Ekran nadawania uprawnienia otworzy się na tablecie.';

  @override
  String get filesGrant => 'Przyznaj na urządzeniu';

  @override
  String get filesUp => 'Przejdź folder wyżej';

  @override
  String get filesShared => 'Pamięć współdzielona';

  @override
  String get filesApp => 'Folder aplikacji';

  @override
  String get filesReadFailed => 'Nie udało się odczytać folderu';

  @override
  String get filesEmpty => 'Pusty folder';

  @override
  String get filesEmptyHelp => 'Nic tu jeszcze nie ma.';

  @override
  String get filesFolder => 'Folder';

  @override
  String get filesDownload => 'Pobierz';

  @override
  String get filesDownloadFailed => 'Pobieranie nie powiodło się';

  @override
  String filesDeleteTitle(String name) {
    return 'Usunąć „$name”?';
  }

  @override
  String get filesDeleteHelp => 'Plik zostanie usunięty z urządzenia.';

  @override
  String get filesInvalidPath => 'Nieprawidłowa ścieżka';

  @override
  String get filesNoFolder => 'Folder nie istnieje';

  @override
  String get filesNoFile => 'Plik nie istnieje';

  @override
  String filesReadError(String error) {
    return 'Nie można odczytać folderu: $error';
  }

  @override
  String filesWriteError(String error) {
    return 'Zapis nie powiódł się: $error';
  }

  @override
  String get filesDeleteFailed => 'Nie udało się usunąć pliku';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin =>
      'Zarządzanie flotą wymaga zdalnej administracji';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Kioski odnajdują się nawzajem za jej pośrednictwem. Włącz „Zdalne zarządzanie” i „Znajdź inne kioski” w sekcji „Urządzenie”, a potem wróć.';

  @override
  String get fleetLeadThisFleet => 'Zostań liderem tej floty';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      'Synchronizuj ustawienia tego kiosku z podlegającymi mu członkami floty. Wymaga, aby wszystkie kioski działały w tej samej wersji.';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead =>
      'Członek floty podlegający liderowi nie może zostać liderem.';

  @override
  String get fleetFollowers => 'Członkowie floty';

  @override
  String get fleetProfiles => 'Profile';

  @override
  String get fleetLeader => 'Lider floty';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      'Dowiedz się, które ustawienia są synchronizowane, a które nie, w ';

  @override
  String get fleetFleetManagementDocumentation =>
      'dokumentacji zarządzania flotą';

  @override
  String get fleetMore => 'Więcej';

  @override
  String get fleetSearchFollowers =>
      'Kioski, dla których ten kiosk jest liderem, ich stan i sposób dodania kolejnego.';

  @override
  String get fleetAddAKiosk => 'Dodaj kiosk';

  @override
  String get fleetAddAKioskFollowerAcceptsOnScreenOrRemoteAdmin =>
      'Dodaj wykryty kiosk lub wpisz jego adres IP. Członek floty przyjmuje zaproszenie na swoim ekranie lub w swojej zdalnej administracji.';

  @override
  String get fleetSendInvitation => 'Wyślij zaproszenie';

  @override
  String get fleetInviteAgain => 'Zaproś ponownie';

  @override
  String fleetRemoveName(String name) {
    return 'Usunąć „$name”?';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      'Przestaje być członkiem floty tego kiosku i zachowuje swoje ustawienia.';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name chce zostać liderem tego kiosku';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      'Od teraz jego ustawienia zastąpią ustawienia tego kiosku w kategoriach, które synchronizuje. Ten kiosk zachowa swoją nazwę i tożsamość.';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      'Od teraz jego ustawienia zastąpią ustawienia tego kiosku w kategoriach, które synchronizuje. Ten kiosk zachowa swoją nazwę, własne tożsamości w Home Assistant, Music Assistant i ESPHome oraz wybrane ustawienia sprzętu. Flotę można opuścić w dowolnym momencie w Ustawieniach, w sekcji „Zarządzanie flotą”.';

  @override
  String get fleetAccept => 'Akceptuj';

  @override
  String get fleetLookingForOtherKiosks => 'Wyszukiwanie innych kiosków…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      'Nie wykryto kiosków. Użyj opcji „Dodaj przez IP”, aby znaleźć kiosk pod znanym adresem.';

  @override
  String fleetFollowsName(String name) {
    return 'Członek floty „$name”';
  }

  @override
  String get fleetLeadsAFleet => 'Jest liderem floty';

  @override
  String get fleetNoFleetManagement => 'Brak zarządzania flotą';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      'Kioski w tej sieci, które nie są członkami floty tego kiosku. Wybierz jeden, aby określić, co otrzyma, a następnie zostanie wysłane zaproszenie. Kiosk z kompilacją bez zarządzania flotą dołączy, gdy zacznie działać na kompilacji z tą funkcją.';

  @override
  String get fleetJoinedTheFleet => 'Dołączono do floty';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly =>
      'Ustawienia od lidera floty wkrótce dotrą.';

  @override
  String get fleetAddByIp => 'Dodaj przez IP';

  @override
  String get fleetFindKiosk => 'Znajdź kiosk';

  @override
  String get fleetFindingKiosk => 'Wyszukiwanie kiosku…';

  @override
  String get fleetIpAddress => 'Adres IP';

  @override
  String get fleetRemoteAdminPort => 'Port zdalnej administracji';

  @override
  String get fleetAddressHelp =>
      'Wpisz adres IP kiosku i port zdalnej administracji.';

  @override
  String get fleetAddAProfile => 'Dodaj profil';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      'Zestaw ustawień, danych logowania i wykluczeń do synchronizacji.';

  @override
  String get fleetNewProfile => 'Nowy profil';

  @override
  String get fleetProfile => 'Profil';

  @override
  String get fleetUpdatesOnly => 'Tylko aktualizacje';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed =>
      'Nic nie jest synchronizowane. Wysyłane są tylko aktualizacje.';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return 'Kategorie: $selected z $total. Dane logowania: $credentials z $credentialTotal. Wykluczone: $excluded.';
  }

  @override
  String get fleetThisProfileIsGone => 'Ten profil już nie istnieje';

  @override
  String get fleetItWasDeletedFromAnotherPage =>
      'Usunięto go na innej stronie.';

  @override
  String get fleetName => 'Nazwa';

  @override
  String get fleetRename => 'Zmień nazwę';

  @override
  String get fleetRenameProfile => 'Zmień nazwę profilu';

  @override
  String get fleetWhatItSyncs => 'Co synchronizuje';

  @override
  String get fleetNothing => 'Nic';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      'Kioski z tym profilem zachowują wszystkie własne ustawienia. Lider floty przesyła im tylko aktualizacje.';

  @override
  String get fleetCategories => 'Kategorie';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected z $total: $names';
  }

  @override
  String get fleetCredentials => 'Dane logowania';

  @override
  String get fleetNoneTravel => 'Nie są przesyłane';

  @override
  String get fleetIncludeTheDashboard => 'Uwzględnij pulpit';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard =>
      'Strona startowa i domyślny pulpit.';

  @override
  String get fleetExcludedSettings => 'Wykluczone ustawienia';

  @override
  String get fleetOneSettingLeftOut => 'Pominięto jedno ustawienie';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return 'Pominięte ustawienia: $count';
  }

  @override
  String get fleetNoKiosksAssigned => 'Brak przypisanych kiosków';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      'Przypisz ten profil do kiosku na stronie „Zarządzanie flotą”.';

  @override
  String get fleetDuplicate => 'Duplikuj';

  @override
  String get fleetCloneThisProfileIntoANewOne =>
      'Skopiuj ten profil jako nowy.';

  @override
  String get fleetDuplicateProfile => 'Duplikuj profil';

  @override
  String fleetNameCopy(String name) {
    return '$name (kopia)';
  }

  @override
  String get fleetDeleteProfile => 'Usuń profil';

  @override
  String get fleetNoKioskIsOnIt => 'Nie przypisano do niego żadnego kiosku.';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile =>
      'Kioski z tym profilem otrzymają profil „Domyślny”.';

  @override
  String fleetDeleteName(String name) {
    return 'Usunąć „$name”?';
  }

  @override
  String get fleetBlackScreens => 'Czarne ekrany';

  @override
  String fleetSyncToName(String name) {
    return 'Synchronizuj z „$name”';
  }

  @override
  String get fleetDefault => 'Domyślny';

  @override
  String get fleetNone => 'Brak';

  @override
  String get fleetSearchProfiles =>
      'Nazwane listy, które można przypisać członkowi floty: kategorie, dane logowania, pulpit i pominięte ustawienia.';

  @override
  String get fleetSyncNow => 'Synchronizuj teraz';

  @override
  String get fleetChangedHereWaitingForTheLeader =>
      'Zmieniono tutaj, oczekiwanie na lidera floty';

  @override
  String fleetSyncedTime(String time) {
    return 'Zsynchronizowano $time';
  }

  @override
  String get fleetWaitingForTheFirstSync =>
      'Oczekiwanie na pierwszą synchronizację';

  @override
  String get fleetNothingYet => 'Jeszcze nic';

  @override
  String get fleetNoCredentials => 'Bez danych logowania';

  @override
  String fleetWithTheNames(String names) {
    return 'Obejmuje: $names';
  }

  @override
  String get fleetTheDashboard => 'pulpit';

  @override
  String get fleetNoDashboard => 'bez pulpitu';

  @override
  String get fleetTheDashboardDetail => 'Pulpit';

  @override
  String get fleetNoDashboardDetail => 'Bez pulpitu';

  @override
  String get fleetSyncedFromTheLeader => 'Zsynchronizowano z liderem floty';

  @override
  String get fleetLeaveTheFleet => 'Opuść flotę';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre =>
      'Zatrzymuje synchronizację. Ustawienia pozostają bez zmian.';

  @override
  String get fleetLeaveTheFleetDetail => 'Opuścić flotę?';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '„$name” przestanie wysyłać tutaj ustawienia. Wszystko pozostanie tak jak teraz.';
  }

  @override
  String get fleetLeave => 'Opuść';

  @override
  String get fleetJustNow => 'przed chwilą';

  @override
  String fleetCountMinAgo(String count) {
    return '$count min temu';
  }

  @override
  String fleetCountHAgo(String count) {
    return '$count h temu';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return '$count d temu';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return 'Tymi ustawieniami zarządza lider $name. Zmiana wprowadzona tutaj zostanie zastąpiona przy następnej synchronizacji.';
  }

  @override
  String get fleetDeclinedOnTheKiosk => 'Odrzucono na kiosku';

  @override
  String get fleetWaitingForItsOk => 'Oczekiwanie na zgodę kiosku';

  @override
  String get fleetLeftTheFleet => 'Opuścił flotę';

  @override
  String fleetSendingPercent(String percent) {
    return 'Wysyłanie $percent%';
  }

  @override
  String get fleetInstalling => 'Instalowanie';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return 'Ma wersję $version, ten kiosk wymaga aktualizacji';
  }

  @override
  String fleetNeedsVersion(String version) {
    return 'Wymaga wersji $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return 'Pobieranie $percent%';
  }

  @override
  String get fleetSyncing => 'Synchronizowanie…';

  @override
  String get fleetErrorUnreachable => 'Brak połączenia';

  @override
  String get fleetErrorBadAnswer => 'Nieprawidłowa odpowiedź';

  @override
  String get fleetErrorThePushFailed => 'Wysyłanie nie powiodło się';

  @override
  String get fleetErrorLeadThisFleetIsOff =>
      'Opcja „Zostań liderem tej floty” jest wyłączona';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      'Zdalna administracja i „Znajdź inne kioski” muszą być włączone';

  @override
  String get fleetErrorPickAnotherKiosk => 'Wybierz inny kiosk';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      'Tego kiosku nie ma teraz w sieci';

  @override
  String get fleetErrorThatKioskDidNotAnswer =>
      'Brak odpowiedzi od tego kiosku';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation =>
      'Ten kiosk odrzucił zaproszenie';

  @override
  String get fleetErrorTheDefaultProfileStays =>
      'Profil domyślny musi pozostać';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays =>
      'Profil „Tylko aktualizacje” musi pozostać';

  @override
  String get fleetErrorNoSuchProfile => 'Nie ma takiego profilu';

  @override
  String get fleetErrorNoSuchFollower => 'Brak takiego członka floty';

  @override
  String get fleetErrorNoInvitationIsWaiting => 'Brak oczekującego zaproszenia';

  @override
  String get fleetErrorMalformedInvitation => 'Nieprawidłowe zaproszenie';

  @override
  String get fleetErrorCouldNotMintAToken => 'Nie udało się wygenerować tokenu';

  @override
  String get fleetErrorNotAFollowerYet => 'jeszcze nie jest członkiem floty';

  @override
  String get fleetErrorOffline => 'poza siecią';

  @override
  String get fleetErrorUpToDate => 'aktualna wersja';

  @override
  String get fleetErrorAlreadyDownloading => 'pobieranie już trwa';

  @override
  String get fleetErrorDidNotAnswer => 'brak odpowiedzi';

  @override
  String get fleetErrorDidNotTakeTheUpload =>
      'przesłany plik nie został przyjęty';

  @override
  String fleetProfileNameExists(String name) {
    return 'Profil „$name” już istnieje';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return 'już w wersji $version';
  }

  @override
  String get fleetUnsupportedBuild =>
      'Ten kiosk działa na kompilacji bez zarządzania flotą. Dołączy, gdy zacznie działać na kompilacji z tą funkcją.';

  @override
  String get fleetErrorAddressMismatch =>
      'Adres należy do innego kiosku lub innej floty';

  @override
  String get fleetErrorInvalidIp => 'Wpisz prawidłowy adres IP.';

  @override
  String get fleetErrorInvalidPort => 'Wpisz port od 1 do 65535.';

  @override
  String get fleetErrorIdentityNotReady =>
      'Tożsamość tego kiosku nie jest jeszcze gotowa. Spróbuj ponownie.';

  @override
  String get fleetErrorInvalidIdentity =>
      'Ten adres nie zwrócił prawidłowej tożsamości kiosku.';

  @override
  String get fleetErrorAlreadyMember => 'Ten kiosk już należy do tej floty.';

  @override
  String get fleetErrorIsLeader => 'Ten kiosk jest liderem floty.';

  @override
  String get fleetErrorOtherLeader =>
      'Ten kiosk podlega już innemu liderowi floty.';

  @override
  String fleetPluginsNames(String names) {
    return 'Wtyczki: $names';
  }

  @override
  String fleetCouldNotInstallNameReason(String name, String reason) {
    return 'Nie udało się zainstalować „$name”: $reason';
  }

  @override
  String fleetReinstallNameOnThisKioskToSyncIt(String name) {
    return 'Zainstaluj ponownie „$name” na tym kiosku, aby włączyć synchronizację';
  }

  @override
  String get fleetSwitchKiosk => 'Przełącz kiosk';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      'Wykryte kioski i zapisani członkowie floty. Wybranie kiosku otwiera jego zdalną administrację tutaj, na tej samej stronie.';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      'Nie znaleziono innych kiosków. Kioski pojawiają się dzięki wykrywaniu w sieci lub zapisanemu członkostwu we flocie.';

  @override
  String get fleetSyncedCredentials => 'Synchronizowane dane logowania';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced =>
      'Ustawienia z tej listy nie będą synchronizowane z członkami floty.';

  @override
  String get fleetNothingLeftOut => 'Niczego nie wykluczono';

  @override
  String get fleetSyncItAgain => 'Synchronizuj ponownie';

  @override
  String get fleetAddASetting => 'Dodaj ustawienie';

  @override
  String get fleetExcludeASetting => 'Wyklucz ustawienie';

  @override
  String get fleetSearchSettings => 'Szukaj ustawień';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return 'Więcej: $count. Wpisz tekst, aby zawęzić listę.';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return 'Niesynchronizowane: $note';
  }

  @override
  String get fleetTheAssignedSatellite => 'przypisany satelita';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain =>
      'urządzenia mikrofonu i głośnika, wzmocnienie mikrofonu';

  @override
  String get fleetTheDeviceCamera => 'kamera urządzenia';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      'śledzony odtwarzacz, identyfikator odtwarzacza Sendspin';

  @override
  String get fleetNodeNameMacEncryptionKey =>
      'nazwa węzła, MAC, klucz szyfrowania';

  @override
  String get fleetThePinIsAlsoSynced => 'PIN też jest synchronizowany';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential =>
      'klucz, chyba że jest synchronizowany jako dane logowania';

  @override
  String get fleetTheAlarmsThemselves => 'same budziki';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'nazwa, zdalna administracja, obejścia renderowania, skala';

  @override
  String get fleetHomeAssistantToken => 'Token Home Assistant';

  @override
  String get fleetMusicAssistantToken => 'Token Music Assistant';

  @override
  String get fleetImmichApiKey => 'Klucz API Immich';

  @override
  String get fleetOpenAiApiKey => 'Klucz API OpenAI';

  @override
  String get fleetXaiApiKey => 'Klucz API xAI';

  @override
  String get fleetGeminiApiKey => 'Klucz API Gemini';

  @override
  String get fleetMcpServerToken => 'Token serwera MCP';

  @override
  String get fleetPlugins => 'Wtyczki';

  @override
  String get fleetPluginSecrets => 'Sekrety wtyczek';

  @override
  String get fleetNoPluginsInstalledOnThisKiosk =>
      'Na tym kiosku nie ma zainstalowanych wtyczek';

  @override
  String get fleetKiosksOnThisProfileInstallTheseAndTakeTheir =>
      'Kioski z tym profilem instalują te wtyczki i przejmują ich ustawienia z tego kiosku.';

  @override
  String get fleetUpdateTheFleet => 'Aktualizuj flotę';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      'Zaktualizuj całą flotę do wersji Kiosk Satellite używanej przez lidera.';

  @override
  String get fleetKeepFollowersOnThisVersion =>
      'Utrzymuj członków floty przy tej wersji';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      'Automatycznie aktualizuj wszystkich członków floty do wersji Kiosk Satellite używanej przez lidera.';

  @override
  String get fleetNothingToUpdate => 'Nie ma czego aktualizować';

  @override
  String get fleetUpdating => 'Aktualizowanie';

  @override
  String fleetNamesInstalling(String names) {
    return 'Trwa instalacja: $names.';
  }

  @override
  String get fleetSearchUpdates =>
      'Zainstaluj uaktualnienie dostępne dla każdego członka floty, a następnie na tym kiosku.';

  @override
  String get gestureAction => 'Akcja';

  @override
  String get gestureNavigate => 'Przejdź do widoku pulpitu';

  @override
  String get gestureUrl => 'Otwórz stronę internetową';

  @override
  String get gestureCameraView => 'Pokaż widok kamery';

  @override
  String get gestureLauncher => 'Otwórz launcher aplikacji';

  @override
  String get gestureIntercomOpen => 'Otwórz „Zadzwoń do kiosku”';

  @override
  String get gestureIntercomCall => 'Zadzwoń do kiosku';

  @override
  String get gestureIntercomHangup => 'Zakończ połączenie interkomu';

  @override
  String get gestureIntercomAnswer => 'Odbierz połączenie interkomu';

  @override
  String get gestureIntercomDecline => 'Odrzuć połączenie interkomu';

  @override
  String get gestureAlarmStop => 'Wyłącz budzik';

  @override
  String get gestureAlarmSnooze => 'Włącz drzemkę budzika';

  @override
  String get gestureScreensaver => 'Uruchom wygaszacz ekranu';

  @override
  String get gestureScreensaverStop => 'Zatrzymaj wygaszacz ekranu';

  @override
  String get gestureHoldMode => 'Przełącz tryb wstrzymania';

  @override
  String get gestureRefresh => 'Odśwież pulpit';

  @override
  String get gestureMediaPlayPause => 'Odtwórz lub wstrzymaj multimedia';

  @override
  String get gestureHaKiosk => 'Przełącz tryb kiosku HA';

  @override
  String get gesturePluginRun => 'Uruchom akcję wtyczki';

  @override
  String get gestureLaunchApp => 'Otwórz inną aplikację';

  @override
  String get gestureDeepLink => 'Otwórz precyzyjny link';

  @override
  String get gestureAndroidSettings => 'Otwórz ustawienia systemu Android';

  @override
  String get gestureOpenCalendar => 'Otwórz kalendarz';

  @override
  String get gestureOpenMusicLibrary => 'Otwórz bibliotekę muzyki';

  @override
  String get gestureService => 'Wywołaj usługę';

  @override
  String get gestureScript => 'Uruchom skrypt';

  @override
  String get gestureAutomation => 'Uruchom automatyzację';

  @override
  String get gestureEvent => 'Wyślij zdarzenie';

  @override
  String get gesturePluginAction => 'Akcja wtyczki';

  @override
  String get gesturePluginActions => 'Akcje wtyczek';

  @override
  String get gesturePluginHelp =>
      'Najpierw włącz wtyczkę z akcjami w menedżerze wtyczek.';

  @override
  String get gesturePluginFailed => 'Nie udało się wczytać akcji wtyczek.';

  @override
  String get gestureUrlError => 'Wpisz pełny adres URL http(s).';

  @override
  String get gesturePackage => 'Nazwa pakietu';

  @override
  String get gesturePackageError => 'Wpisz nazwę pakietu.';

  @override
  String get gestureUriError => 'Wpisz pełny identyfikator URI.';

  @override
  String get gestureCameraTitle => 'Widok kamery';

  @override
  String gestureCameraShow(String name) {
    return 'Pokaż „$name”';
  }

  @override
  String get gestureCameraClose => 'Zamknij widok kamery';

  @override
  String get gestureCameraEmpty => 'Nie skonfigurowano jeszcze widoków kamery.';

  @override
  String get gestureIntercomEmpty =>
      'Nie znaleziono jeszcze żadnego kiosku w sieci.';

  @override
  String get gestureVoiceWake => 'Rozpocznij polecenie głosowe';

  @override
  String get gestureVoiceStop => 'Zatrzymaj asystenta głosowego';

  @override
  String get gestureVoiceMute => 'Wycisz lub wyłącz wyciszenie Voice Satellite';

  @override
  String get gestureOpenAlarmList => 'Otwórz listę budzików';

  @override
  String get gestureOpenTimers => 'Otwórz minutniki';

  @override
  String get gestureOpenNextAlarm => 'Otwórz następny budzik';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return 'Dotknięcia: $count (róg $corner)';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return 'Przytrzymaj róg $corner przez $seconds s';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return 'Podwójne dotknięcie, palce: $count';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return 'Dotknięcie, palce: $count';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return 'Przytrzymanie, palce: $count, $seconds s';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return 'Sekwencja rogów: $sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return 'Klaśnięcia: $count';
  }

  @override
  String get gestureDescribeOpenHand => 'Pokaż otwartą dłoń';

  @override
  String gestureDescribeOneFinger(String count) {
    return 'Pokaż palce: $count';
  }

  @override
  String gestureDescribeFingers(String count) {
    return 'Pokaż palce: $count';
  }

  @override
  String get gestureTopLeft => 'lewy górny';

  @override
  String get gestureTopRight => 'prawy górny';

  @override
  String get gestureBottomLeft => 'lewy dolny';

  @override
  String get gestureBottomRight => 'prawy dolny';

  @override
  String gestureGoTo(String value) {
    return 'Przejdź do $value';
  }

  @override
  String gestureOpen(String value) {
    return 'Otwórz $value';
  }

  @override
  String get gestureCameraToggle => 'Przełącz widok kamery';

  @override
  String gestureCameraToggleName(String name) {
    return 'Przełącz widok kamery „$name”';
  }

  @override
  String gestureCall(String value) {
    return 'Zadzwoń do „$value”';
  }

  @override
  String gestureOpenApp(String package) {
    return 'Otwórz aplikację $package';
  }

  @override
  String gestureRun(String value) {
    return 'Uruchom $value';
  }

  @override
  String gestureTriggerAction(String value) {
    return 'Wyzwalacz: $value';
  }

  @override
  String gestureFireEvent(String value) {
    return 'Wyślij zdarzenie $value';
  }

  @override
  String gestureDescribeButtonPress(String button) {
    return 'Naciśnij przycisk „$button”';
  }

  @override
  String gestureDescribeButtonDouble(String button) {
    return 'Naciśnij dwukrotnie przycisk „$button”';
  }

  @override
  String gestureDescribeButtonHold(String button) {
    return 'Przytrzymaj przycisk „$button”';
  }

  @override
  String get gestureValid => 'Wszystko w porządku.';

  @override
  String get gestureValidationFailed => 'Nie udało się sprawdzić poprawności.';

  @override
  String gestureDomainMissing(String value) {
    return 'Nie znaleziono domeny „$value”.';
  }

  @override
  String gestureServiceMissing(String value) {
    return 'Nie znaleziono usługi „$value”.';
  }

  @override
  String gestureEntityMissing(String value) {
    return 'Nie znaleziono encji „$value”.';
  }

  @override
  String gestureEntityRequired(String domain) {
    return 'Wpisz encję typu $domain.*.';
  }

  @override
  String get gestureScriptEntity => 'Encja skryptu';

  @override
  String get gestureAutomationEntity => 'Encja automatyzacji';

  @override
  String get gestureEntityOptional => 'Encja (opcjonalnie)';

  @override
  String get gestureServiceData => 'Dane usługi (opcjonalnie)';

  @override
  String get gestureServiceTitle => 'Wywołaj usługę Home Assistant';

  @override
  String get gestureServiceJson => 'Dane usługi muszą być obiektem JSON.';

  @override
  String get gestureEventType => 'Typ zdarzenia';

  @override
  String get gestureEventData => 'Dane zdarzenia (opcjonalnie)';

  @override
  String get gestureEventTitle => 'Wyślij zdarzenie Home Assistant';

  @override
  String get gestureEventRequired => 'Typ zdarzenia jest wymagany.';

  @override
  String get gestureEventJson => 'Dane zdarzenia muszą być obiektem JSON.';

  @override
  String get gestureServiceSearch => 'Szukaj usług';

  @override
  String get gestureServiceChoose => 'Wybierz usługę';

  @override
  String get gestureServiceNoEntity => 'Ta usługa nie używa encji';

  @override
  String get gestureTester => 'Tester gestów dłoni';

  @override
  String get gestureOpenTester => 'Otwórz tester';

  @override
  String get gestureCameraFirst =>
      'Najpierw włącz kamerę w ustawieniach kamery.';

  @override
  String get gestureTesterHelp =>
      'Obserwuj, które palce odczytuje kamera, aby nauczyć się, jak trzymać dłoń.';

  @override
  String get gestureHandHelp =>
      'Trzymaj dłoń uniesioną na wysokości barku, wnętrzem do kamery, z rozstawionymi palcami. Zegnij palec całkowicie, aby nie był liczony. Aby pokazać cztery, przyłóż kciuk do wnętrza dłoni: kciuk jest liczony tylko przy otwartej dłoni.';

  @override
  String get gestureTesterPaused =>
      'Gesty nie działają, gdy tester jest otwarty.';

  @override
  String get gestureShowHand => 'Pokaż dłoń kamerze.';

  @override
  String gestureTesterTrigger(String action) {
    return 'Wyzwala: $action';
  }

  @override
  String get gestureNoCount => 'Żaden gest nie używa tej liczby palców.';

  @override
  String get gestureNoHand => 'Brak dłoni w kadrze';

  @override
  String get gestureReadingHand => 'Odczytywanie dłoni';

  @override
  String get gestureNoFingers => 'Brak uniesionych palców';

  @override
  String gestureHandsCount(String count) {
    return 'Dłonie w kadrze: $count, odczytywana jest większa.';
  }

  @override
  String get gestureTesterSearch =>
      'Podgląd na żywo palców odczytywanych przez kamerę.';

  @override
  String get gestureHoldConfirmed => 'Przytrzymanie potwierdzone';

  @override
  String gestureHoldProgress(String progress) {
    return 'Postęp przytrzymania: $progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return 'Czas przytrzymania: $duration';
  }

  @override
  String get gestureHaServiceKind => 'Usługa Home Assistant';

  @override
  String get gestureHaScriptKind => 'Skrypt Home Assistant';

  @override
  String get gestureHaAutomationKind => 'Automatyzacja Home Assistant';

  @override
  String get gestureHaEventKind => 'Zdarzenie Home Assistant';

  @override
  String gestureRan(String value) {
    return 'Uruchomiono „$value”';
  }

  @override
  String gestureRunFailed(String value) {
    return 'Nie udało się uruchomić „$value”';
  }

  @override
  String gestureCalled(String value) {
    return 'Wywołano „$value”';
  }

  @override
  String gestureCallFailed(String value) {
    return 'Nie udało się wywołać „$value”';
  }

  @override
  String gestureTriggered(String value) {
    return 'Wyzwolono „$value”';
  }

  @override
  String gestureTriggerFailed(String value) {
    return 'Nie udało się wyzwolić „$value”';
  }

  @override
  String gestureFired(String value) {
    return 'Wysłano zdarzenie „$value”';
  }

  @override
  String gestureFireFailed(String value) {
    return 'Nie udało się wysłać zdarzenia „$value”';
  }

  @override
  String get gestureDone => 'Gotowe';

  @override
  String get gestureFailed => 'Niepowodzenie';

  @override
  String get gestureEdit => 'Edytuj gest';

  @override
  String get gestureTrigger => 'Gest';

  @override
  String get gestureCornerTaps => 'Dotknięcia w rogu';

  @override
  String get gestureCornerHold => 'Przytrzymanie rogu';

  @override
  String get gestureFingerTaps => 'Dotknięcie wieloma palcami';

  @override
  String get gestureFingerHold => 'Przytrzymanie wieloma palcami';

  @override
  String get gestureSequence => 'Sekwencja rogów';

  @override
  String get gestureClaps => 'Klaśnięcia';

  @override
  String get gestureShowFingers => 'Pokaż palce';

  @override
  String get gestureCorner => 'Róg';

  @override
  String get gestureCornerTl => 'Lewy górny róg';

  @override
  String get gestureCornerTr => 'Prawy górny róg';

  @override
  String get gestureCornerBl => 'Lewy dolny róg';

  @override
  String get gestureCornerBr => 'Prawy dolny róg';

  @override
  String get gestureTaps => 'Dotknięcia';

  @override
  String get gestureTaps2 => '2 dotknięcia';

  @override
  String get gestureTaps3 => '3 dotknięcia';

  @override
  String get gestureTaps4 => '4 dotknięcia';

  @override
  String get gestureFingers => 'Palce';

  @override
  String get gestureFinger1 => '1 palec';

  @override
  String get gestureFinger2 => '2 palce';

  @override
  String get gestureFinger3 => '3 palce';

  @override
  String get gestureFinger4 => '4 palce';

  @override
  String get gestureOpenHand5 => 'Otwarta dłoń (5)';

  @override
  String get gestureSingleTap => 'Pojedyncze dotknięcie';

  @override
  String get gestureDoubleTap => 'Podwójne dotknięcie';

  @override
  String gestureHoldDuration(String seconds) {
    return 'Przytrzymaj przez $seconds s';
  }

  @override
  String get gestureCameraHelp =>
      'Wymaga włączonej kamery i dobrze oświetlonego otoczenia.';

  @override
  String get gestureUnavailable => 'Niedostępne na tym urządzeniu.';

  @override
  String get gestureClaps2 => '2 klaśnięcia';

  @override
  String get gestureClaps3 => '3 klaśnięcia';

  @override
  String get gestureClaps4 => '4 klaśnięcia';

  @override
  String get gestureClapHelp =>
      'Klaśnięcia są wykrywane przez mikrofon, z wykrywaniem słowa wybudzającego lub bez niego.';

  @override
  String get gestureSequenceHelp =>
      'Dotykaj rogów po kolei (od 2 do 8 kroków).';

  @override
  String get gestureRemoveStep => 'Usuń ostatni krok';

  @override
  String get gestureUndo => 'Cofnij';

  @override
  String get gestureChooseAction => 'Wybierz akcję';

  @override
  String get gestureActionHelp => 'Akcja wywoływana przez ten gest.';

  @override
  String get gestureChangeHelp => 'Dotknij, aby zmienić.';

  @override
  String get gestureChooseError => 'Wybierz akcję.';

  @override
  String get gestureSequenceError => 'Dodaj co najmniej dwa rogi.';

  @override
  String get gesturePluginTrigger => 'Wyzwalacz wtyczki';

  @override
  String get gesturePluginTriggerField => 'Wyzwalacz';

  @override
  String get gesturePluginTriggerHelp =>
      'Najpierw włącz wtyczkę z wyzwalaczami w menedżerze wtyczek.';

  @override
  String get gestureButton => 'Przycisk';

  @override
  String get gesturePress => 'Naciśnięcie';

  @override
  String get gestureDoublePress => 'Podwójne naciśnięcie';

  @override
  String get gestureHoldPress => 'Przytrzymanie';

  @override
  String get gestureButtonDefaults =>
      'Naciśnięcie przycisku, którego nie obsługuje żaden gest, działa jak zwykle: przycisk akcji odbiera, zatrzymuje lub odrzuca to, co dzwoni, a poza tym uruchamia polecenie głosowe, przycisk mikrofonu wycisza Voice Satellite, a przyciski głośności zmieniają głośność.';

  @override
  String get intercomCall => 'Zadzwoń';

  @override
  String get intercomNoReady => 'Żaden kiosk nie jest gotowy.';

  @override
  String get intercomOneReady => 'Gotowy jest 1 kiosk.';

  @override
  String intercomManyReady(String count) {
    return 'Gotowe kioski: $count.';
  }

  @override
  String get intercomCallKiosk => 'Zadzwoń do kiosku';

  @override
  String get intercomAnnounceAll => 'Ogłoś wszystkim';

  @override
  String get intercomAnnounceHelp =>
      'Mów do wszystkich kiosków. Tylko w jedną stronę.';

  @override
  String intercomMissedFrom(String name) {
    return 'Nieodebrane połączenie od „$name”';
  }

  @override
  String intercomRangFor(String seconds) {
    return 'Dzwoniło przez $seconds s.';
  }

  @override
  String get intercomCallBack => 'Oddzwoń';

  @override
  String get intercomDeclined => 'Odrzucono';

  @override
  String get intercomBusy => 'Zajęte';

  @override
  String get intercomPeerOff => 'Interkom kiosku jest wyłączony';

  @override
  String get intercomPeerKey => 'Inny klucz interkomu';

  @override
  String get intercomNoAnswer => 'Brak odpowiedzi';

  @override
  String get intercomDidNotAnswer => 'Nie odebrano';

  @override
  String get intercomVoiceFailed => 'Błąd łącza głosowego';

  @override
  String get intercomCancelled => 'Anulowano';

  @override
  String get intercomPageMic => 'Strona przejęła mikrofon';

  @override
  String get intercomNobody => 'Nikt nie mógł odebrać';

  @override
  String get intercomDone => 'Gotowe';

  @override
  String get intercomEnded => 'Połączenie zakończone';

  @override
  String get intercomMaxDurationReached =>
      'Osiągnięto maksymalny czas połączenia';

  @override
  String get intercomAnnouncement => 'Ogłoszenie';

  @override
  String get intercomAnnouncingOne => 'Ogłoszenie do 1 kiosku';

  @override
  String intercomAnnouncingMany(String count) {
    return 'Ogłoszenie (kioski: $count)';
  }

  @override
  String get intercomIsCalling => 'dzwoni';

  @override
  String get intercomIsAnnouncing => 'nadaje ogłoszenie';

  @override
  String get intercomCalling => 'Dzwonienie…';

  @override
  String intercomAnswersWithCameraIn(String seconds) {
    return 'Kamera włączy się za $seconds s';
  }

  @override
  String intercomAnswersIn(String seconds) {
    return 'Odbiór za $seconds s';
  }

  @override
  String get intercomRinging => 'Dzwoni';

  @override
  String get intercomConnecting => 'Łączenie…';

  @override
  String intercomDoneDuration(String duration) {
    return 'Gotowe, $duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return 'Połączenie zakończone, $duration';
  }

  @override
  String get intercomDecline => 'Odrzuć';

  @override
  String get intercomAnswer => 'Odbierz';

  @override
  String get intercomEveryKiosk => 'Wszystkie kioski';

  @override
  String get intercomStop => 'Zatrzymaj';

  @override
  String intercomHearsYou(String name) {
    return '„$name” cię słyszy';
  }

  @override
  String get intercomAllHearYou => 'Wszystkie kioski cię słyszą';

  @override
  String get intercomHoldHelp => 'Przytrzymaj, aby mówić, puść, aby słuchać';

  @override
  String get intercomMuted => 'Wyciszono';

  @override
  String get intercomMute => 'Wycisz';

  @override
  String get intercomEnd => 'Zakończ';

  @override
  String get intercomReply => 'Odpowiedz';

  @override
  String get intercomDismiss => 'Zamknij';

  @override
  String get intercomCallAgain => 'Zadzwoń ponownie';

  @override
  String get intercomDashboardMic => 'Pulpit używa mikrofonu, tylko słuchanie.';

  @override
  String get intercomMicDenied =>
      'Brak uprawnienia do mikrofonu, tylko słuchanie.';

  @override
  String get intercomHoldTalk => 'Przytrzymaj, aby mówić';

  @override
  String get intercomPlaying => 'Odtwarzanie';

  @override
  String get intercomAKiosk => 'kiosk';

  @override
  String intercomCallingName(String name) {
    return 'Połączenie wychodzące: $name';
  }

  @override
  String intercomNameCalling(String name) {
    return 'Połączenie przychodzące: $name';
  }

  @override
  String intercomInCallName(String name) {
    return 'Trwa połączenie: $name';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return 'Ogłoszenie od: $name';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant: $message';
  }

  @override
  String get intercomEndCall => 'Zakończ połączenie';

  @override
  String get intercomVoiceCall => 'Połączenie głosowe';

  @override
  String get intercomVideoCall => 'Połączenie wideo';

  @override
  String get intercomVoiceOnly => 'Tylko głos';

  @override
  String get intercomVideoAnswer => 'Wideo';

  @override
  String get intercomSwitchCamera => 'Przełącz kamerę';

  @override
  String get intercomCameraButton => 'Kamera';

  @override
  String get intercomCameraOff => 'Kamera wyłączona';

  @override
  String get intercomYourCameraOff => 'Twoja kamera jest wyłączona';

  @override
  String get intercomVideoReconnecting => 'Ponowne łączenie wideo…';

  @override
  String get intercomCameraOffNotice =>
      'Kamera jest wyłączona. Ten kiosk może wyświetlać obraz, ale nie może go wysyłać.';

  @override
  String get intercomCallFailed => 'Nie udało się zadzwonić';

  @override
  String get intercomKeyFailed => 'Nie udało się zmienić klucza';

  @override
  String get intercomBroadcastFailed => 'Nie udało się nadać do wszystkich';

  @override
  String get intercomDeviceNoAnswer => 'Urządzenie nie odpowiedziało.';

  @override
  String get intercomUnknownKiosk => 'nieznany kiosk';

  @override
  String get intercomNothingRinging => 'nic nie dzwoni';

  @override
  String get intercomNoCall => 'brak połączenia';

  @override
  String get intercomDisabled => 'interkom jest wyłączony';

  @override
  String get intercomNeedsRemote => 'wymaga zdalnej administracji';

  @override
  String get intercomNeedsDiscovery =>
      'interkom wymaga zdalnej administracji i opcji „Znajdź inne kioski”';

  @override
  String get intercomAlreadyCalling => 'połączenie już trwa';

  @override
  String get intercomNoReadyError => 'żaden kiosk nie jest gotowy';

  @override
  String get intercomKeyLength => 'klucz musi mieć co najmniej 16 znaków';

  @override
  String get intercomMicHeld => 'strona zajmuje mikrofon';

  @override
  String get intercomMicPermission => 'nie przyznano uprawnienia do mikrofonu';

  @override
  String get intercomCallerNoAnswer => 'brak odpowiedzi od dzwoniącego';

  @override
  String get intercomMissedcall => 'Nieodebrane połączenie';

  @override
  String get intercomListening => 'Nasłuchiwanie';

  @override
  String get intercomAnnouncementsoff => 'Ogłoszenia wyłączone';

  @override
  String get intercomEncryptionMismatch => 'Niezgodność szyfrowania';

  @override
  String get intercomEncryptionMismatchHelp =>
      'Niezgodność szyfrowania. Włącz opcję „Szyfruj komunikację” na wszystkich kioskach biorących udział w połączeniu.';

  @override
  String get kioskBackClose =>
      'Naciśnij Wstecz ponownie, aby zamknąć aplikację';

  @override
  String get kioskBackAgain => 'Naciśnij Wstecz ponownie, aby wrócić';

  @override
  String get kioskHoldOn => 'Tryb wstrzymania włączony';

  @override
  String get kioskHoldOff => 'Tryb wstrzymania wyłączony';

  @override
  String get kioskHoldNotice =>
      'Bieżący widok pozostanie, dopóki nie wyłączysz tego trybu.';

  @override
  String get kioskDownloadComplete => 'Pobieranie zakończone';

  @override
  String get kioskDownloadFailed => 'Pobieranie nie powiodło się';

  @override
  String get kioskDownload => 'Pobierz';

  @override
  String get kioskDownloading => 'Pobieranie';

  @override
  String get kioskOpen => 'Otwórz';

  @override
  String get kioskTip => 'Wskazówka';

  @override
  String get kioskMenuHint =>
      'Przesuń palcem od lewej krawędzi, aby otworzyć menu.';

  @override
  String get kioskUnknownLink => 'Nieznany link kiosku';

  @override
  String get kioskOpenAppFailed => 'Nie udało się otworzyć aplikacji';

  @override
  String get kioskWebViewMissing =>
      'Android System WebView nie jest zainstalowany';

  @override
  String get kioskWebViewMissingHelp =>
      'To urządzenie nie ma dostawcy WebView, więc nie można wyświetlić Home Assistant. Zainstaluj Android System WebView lub Chrome, a następnie uruchom ponownie Kiosk Satellite.';

  @override
  String get kioskDuraSpeedBlocking => 'DuraSpeed blokuje pulpit';

  @override
  String get kioskDuraSpeedBlockingHelp =>
      'DuraSpeed na tym tablecie nie pozwala uruchomić procesu renderującego pulpitu, a niektóre tablety nie mają strony jego ustawień. Wyłącz go jednorazowo przez adb, a następnie uruchom ponownie Kiosk Satellite:';

  @override
  String get kioskPinTitle => 'PIN kiosku';

  @override
  String get kioskPinHint => 'PIN';

  @override
  String get kioskWrongPin => 'Nieprawidłowy PIN';

  @override
  String get kioskUnlock => 'Odblokuj';

  @override
  String get lockdownScreenLocked => 'Ekran jest zablokowany';

  @override
  String get logsWebConsole => 'Konsola Web';

  @override
  String get logsDock => 'Zadokuj nad bieżącą stroną';

  @override
  String get logsNoOutput => 'Brak danych w konsoli';

  @override
  String get logsShareSubject => 'Log konsoli Kiosk Satellite';

  @override
  String get logsInput => 'Uruchom JavaScript na stronie';

  @override
  String get logsInputHistory =>
      'Uruchom JavaScript na stronie (Enter: uruchom, strzałki w górę/w dół: historia)';

  @override
  String get logsRun => 'Uruchom';

  @override
  String get logsEvaluationFailed => 'wykonanie nie powiodło się';

  @override
  String get logsDeviceUnreachable => 'urządzenie nieosiągalne';

  @override
  String logsEntries(String count) {
    return 'Wpisy: $count';
  }

  @override
  String get logsCopyLog => 'Kopiuj log';

  @override
  String get logsShareLog => 'Udostępnij log';

  @override
  String get logsCopied => 'Skopiowano';

  @override
  String get logsCopyFailed => 'Nie udało się skopiować';

  @override
  String get logsOnClipboard => 'Log jest w schowku.';

  @override
  String get logsConsoleOnClipboard => 'Log konsoli jest w schowku.';

  @override
  String get logsSystemLog =>
      'Log systemu Android dla tej aplikacji (tu trafiają awarie)';

  @override
  String get logsErrors => 'Błędy i awarie';

  @override
  String get logsWarnings => 'Ostrzeżenia';

  @override
  String get logsInfo => 'Informacje i debugowanie';

  @override
  String get logsNoMatches =>
      'Brak pasujących wierszy. Włącz więcej typów powyżej, aby zobaczyć cały log.';

  @override
  String get logsUnavailable => 'logcat jest niedostępny';

  @override
  String logsReadFailed(String error) {
    return 'Nie udało się odczytać logcat: $error';
  }

  @override
  String get logsUnknown => 'nieznany błąd';

  @override
  String get libraryTitle => 'Biblioteka muzyczna';

  @override
  String get librarySource => 'Źródło';

  @override
  String get librarySourceMa => 'Music Assistant';

  @override
  String get librarySourceHa => 'Home Assistant';

  @override
  String get librarySourceSonos => 'Sonos';

  @override
  String get librarySourceMaHint => 'Biblioteka, wyszukiwanie i radio';

  @override
  String get librarySourceHaHint => 'Multimedia z każdego głośnika';

  @override
  String get librarySourceSonosHint => 'Ulubione i playlisty';

  @override
  String get libraryDiscover => 'Odkrywaj';

  @override
  String get librarySearch => 'Szukaj';

  @override
  String get libraryBrowse => 'Przeglądaj';

  @override
  String get libraryLibrary => 'Biblioteka';

  @override
  String get libraryArtists => 'Wykonawcy';

  @override
  String get libraryAlbums => 'Albumy';

  @override
  String get libraryTracks => 'Utwory';

  @override
  String get libraryGenres => 'Gatunki';

  @override
  String get libraryPlaylists => 'Playlisty';

  @override
  String get libraryRadio => 'Radio';

  @override
  String get libraryPodcasts => 'Podcasty';

  @override
  String get libraryAudiobooks => 'Audiobooki';

  @override
  String get libraryFavorites => 'Ulubione';

  @override
  String get librarySonosPlaylists => 'Playlisty Sonos';

  @override
  String get libraryRecentlyPlayed => 'Ostatnio odtwarzane';

  @override
  String get libraryRecentlyAdded => 'Ostatnio dodane';

  @override
  String get librarySort => 'Sortuj';

  @override
  String get librarySortAToZ => 'Od A do Z';

  @override
  String get librarySortZToA => 'Od Z do A';

  @override
  String get librarySortMostPlayed => 'Najczęściej odtwarzane';

  @override
  String get libraryAlbumArtistsOnly => 'Tylko wykonawcy albumów';

  @override
  String get libraryKindGenre => 'Gatunek';

  @override
  String get libraryBrowseByGenre => 'Przeglądaj według gatunku';

  @override
  String get settingLibraryTextScaleDescription =>
      'Rozmiar tytułów, nazw i etykiet w bibliotece.';

  @override
  String get settingLibrarySquareArtworkTitle => 'Kwadratowe grafiki';

  @override
  String get settingLibrarySquareArtworkDescription =>
      'Pokazuj wykonawców na kwadratowych kafelkach, tak jak albumy i playlisty.';

  @override
  String get settingLibraryGridDensityTitle => 'Gęstość siatki';

  @override
  String get settingLibraryGridDensityDescription =>
      'Rozmiar kafelków w bibliotece. Opcja „Kompaktowa” mieści więcej kafelków w rzędzie.';

  @override
  String get settingLibrarySourcePickerTitle => 'Pokazuj wybór źródła';

  @override
  String get settingLibrarySourcePickerDescription =>
      'Pokazuj wybór źródła w bibliotece. Wyłącz, aby biblioteka zawsze korzystała ze źródła ustawionego powyżej.';

  @override
  String get settingLibrarySpeakerPillDescription =>
      'Pokazuj wybór głośnika u góry biblioteki.';

  @override
  String get libraryDensityComfortable => 'Komfortowa';

  @override
  String get libraryDensityStandard => 'Standardowa';

  @override
  String get libraryDensityCompact => 'Kompaktowa';

  @override
  String get libraryMoreResults => 'Więcej wyników';

  @override
  String get libraryTopTracks => 'Najpopularniejsze utwory';

  @override
  String get libraryKindArtist => 'Wykonawca';

  @override
  String get libraryKindAlbum => 'Album';

  @override
  String get libraryKindTrack => 'Utwór';

  @override
  String get libraryKindPlaylist => 'Playlista';

  @override
  String get libraryKindRadio => 'Radio';

  @override
  String get libraryKindPodcast => 'Podcast';

  @override
  String get libraryKindEpisode => 'Odcinek';

  @override
  String get libraryKindAudiobook => 'Audiobook';

  @override
  String get libraryOneTrack => '1 utwór';

  @override
  String libraryTrackCount(String count) {
    return 'Utwory: $count';
  }

  @override
  String libraryMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String libraryHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get librarySearchHint => 'Wykonawcy, albumy, utwory';

  @override
  String get librarySearchClear => 'Wyczyść wyszukiwanie';

  @override
  String get librarySearchAll => 'Wszystko';

  @override
  String get librarySearchPrompt =>
      'Wyszukaj wykonawców, albumy, utwory i nie tylko.';

  @override
  String get libraryEmpty => 'Nic tu jeszcze nie ma.';

  @override
  String get libraryLoadFailed => 'Nie udało się tego wczytać.';

  @override
  String get libraryNoSource =>
      'Skonfiguruj Music Assistant, Home Assistant lub głośnik Sonos, aby przeglądać muzykę.';

  @override
  String get libraryHaPickSpeaker =>
      'Wybierz głośnik, aby zobaczyć multimedia, które może odtwarzać.';

  @override
  String get libraryChooseSpeaker => 'Wybierz głośnik';

  @override
  String get libraryPickSpeakerHint => 'Wybierz głośnik do odtwarzania.';

  @override
  String get libraryPlay => 'Odtwórz';

  @override
  String get libraryOpenNowPlaying => 'Otwórz „Teraz odtwarzane”';

  @override
  String get libraryNothingPlaying => 'Nic nie jest odtwarzane';

  @override
  String get libraryMore => 'Więcej opcji';

  @override
  String get libraryPlayNow => 'Odtwórz teraz';

  @override
  String get libraryPlayNext => 'Odtwórz jako następne';

  @override
  String get libraryAddToQueue => 'Dodaj do kolejki';

  @override
  String get libraryStartRadio => 'Uruchom radio';

  @override
  String get libraryGoToArtist => 'Przejdź do wykonawcy';

  @override
  String get libraryAddFavorite => 'Dodaj do ulubionych';

  @override
  String get libraryRemoveFavorite => 'Usuń z ulubionych';

  @override
  String get libraryAddedFavorite => 'Dodano do ulubionych';

  @override
  String get libraryRemovedFavorite => 'Usunięto z ulubionych';

  @override
  String get libraryFavoriteFailed => 'Nie udało się zmienić ulubionych';

  @override
  String get libraryPlaysNext => 'Odtwarzane jako następne';

  @override
  String get libraryAddedToQueue => 'Dodano do kolejki';

  @override
  String get libraryView => 'Pokaż';

  @override
  String get libraryPlayFailed => 'Nie udało się tego odtworzyć';

  @override
  String get librarySpeakers => 'Głośniki';

  @override
  String get libraryPlayingOn => 'Odtwarzanie na';

  @override
  String get libraryOtherSpeakers => 'Inne głośniki';

  @override
  String get libraryNoOtherSpeakers => 'Brak innych głośników.';

  @override
  String get libraryThisDevice => 'To urządzenie';

  @override
  String get libraryUnavailable => 'Niedostępny';

  @override
  String get libraryGroup => 'Grupuj';

  @override
  String get libraryGroupAll => 'Grupa';

  @override
  String libraryGroupWith(String speaker) {
    return 'Grupuj z głośnikiem „$speaker”';
  }

  @override
  String get libraryGroupHint =>
      'Zgrupowane głośniki odtwarzają tę samą muzykę synchronicznie.';

  @override
  String libraryGroupName(String speaker, String count) {
    return '$speaker + $count';
  }

  @override
  String get settingKioskAllowMusicLibraryDescription =>
      'Przeglądaj muzykę i odtwarzaj ją na głośniku.';

  @override
  String get libraryPageHint => 'Przeglądaj muzykę i odtwarzaj ją na głośniku';

  @override
  String get settingLibrarySourceDescription =>
      'Skąd biblioteka pobiera listę muzyki. Opcja Automatycznie zaczyna od źródła głośnika, za którym podąża ekran „Teraz odtwarzane”.';

  @override
  String get settingLibraryNowPlayingButtonTitle =>
      'Pokazuj na ekranie „Teraz odtwarzane”';

  @override
  String get settingLibraryNowPlayingButtonDescription =>
      'Dodaj przycisk Biblioteki muzyki obok przycisku zamykania.';

  @override
  String get libraryQueueTitle => 'Kolejka';

  @override
  String get libraryCloseQueue => 'Zamknij kolejkę';

  @override
  String get libraryClear => 'Wyczyść';

  @override
  String get libraryClearQueueTitle => 'Wyczyścić kolejkę?';

  @override
  String get libraryClearQueueMessage =>
      'Muzyka zostanie zatrzymana, a wszystkie utwory znikną z kolejki.';

  @override
  String get libraryRemoveFromQueue => 'Usuń z kolejki';

  @override
  String get libraryReorder => 'Przeciągnij, aby zmienić kolejność';

  @override
  String get libraryQueueFailed => 'Nie udało się zmienić kolejki';

  @override
  String get libraryVoiceSection => 'Sterowanie głosowe';

  @override
  String get libraryVoiceManage => 'Zarządzaj muzyką za pomocą Voice Satellite';

  @override
  String get libraryVoiceHint =>
      'Wymaga blueprintu muzycznego Kiosk Satellite i agenta konwersacji LLM w Home Assistant.';

  @override
  String get musicPickerTitle => 'Wybierz muzykę';

  @override
  String get musicPickerSearchHint => 'Szukaj muzyki';

  @override
  String get musicPickerMusicFrom => 'Muzyka z';

  @override
  String get musicPickerPlaysOn => 'Odtwarzanie na';

  @override
  String musicPickerSourceLabel(String name) {
    return 'Źródło: $name';
  }

  @override
  String musicPickerSpeakerLabel(String name) {
    return 'Odtwarzanie na: $name';
  }

  @override
  String get musicPickerRandom => 'Losowo';

  @override
  String get musicPickerRandomHint => 'Nowy wybór przy każdym odtworzeniu';

  @override
  String get musicPickerAnyTrack => 'Dowolny utwór';

  @override
  String get musicPickerAnyFavorite => 'Dowolny ulubiony';

  @override
  String get musicPickerAnyPlaylist => 'Dowolna playlista';

  @override
  String get musicPickerAnyAlbum => 'Dowolny album';

  @override
  String get musicPickerAnyStation => 'Dowolna stacja radiowa';

  @override
  String get musicPickerRandomEach => 'Za każdym razem coś innego';

  @override
  String get musicPickerWholeAlbum => 'Cały album';

  @override
  String get musicPickerWholePlaylist => 'Cała playlista';

  @override
  String musicPickerWholeArtist(String name) {
    return 'Wszystko wykonawcy $name';
  }

  @override
  String get musicPickerWholeFolder => 'Cały folder';

  @override
  String get musicPickerAllTracks => 'Wszystkie utwory';

  @override
  String get musicPickerShuffle => 'Losowo';

  @override
  String get musicPickerPreview => 'Odsłuchaj';

  @override
  String get musicPickerStopPreview => 'Zatrzymaj odsłuch';

  @override
  String get musicPickerPreviewFailed => 'Nie udało się odtworzyć muzyki';

  @override
  String get musicPickerNothing => 'Nic nie wybrano';

  @override
  String get musicPickerNothingHint =>
      'Wybierz utwór, album, playlistę, wykonawcę lub stację';

  @override
  String get musicPickerFollowsNote =>
      'Podczas odtwarzania muzyki ekran „Teraz odtwarzane” przełącza się na ten głośnik.';

  @override
  String get musicPickerSonosNote =>
      'Muzyka z Sonos jest odtwarzana tylko na głośnikach Sonos.';

  @override
  String get musicPickerNoSpeakers => 'Brak głośników do odtwarzania';

  @override
  String musicPickerOpen(String title) {
    return 'Otwórz „$title”';
  }

  @override
  String get musicPickerKindFolder => 'Folder';

  @override
  String get offlineDashboard => 'Pulpit niedostępny';

  @override
  String get offlineNetwork => 'Brak połączenia z siecią';

  @override
  String get offlinePageHelp => 'Nie udało się wczytać strony.';

  @override
  String get offlineNetworkHelp =>
      'Pulpit wróci, gdy sieć znów będzie dostępna.';

  @override
  String get offlineLost => 'Utracono połączenie z siecią';

  @override
  String get offlineRestored => 'Przywrócono połączenie z siecią';

  @override
  String get mediaPlay => 'Odtwórz';

  @override
  String get mediaPause => 'Wstrzymaj';

  @override
  String get mediaPreviousTrack => 'Poprzedni utwór';

  @override
  String get mediaNextTrack => 'Następny utwór';

  @override
  String get mediaPlaying => 'Odtwarzanie';

  @override
  String get mediaPaused => 'Wstrzymano';

  @override
  String get mediaIdle => 'Bezczynny';

  @override
  String get mediaStatusUnavailable => 'Status niedostępny';

  @override
  String get mediaUnknownTrack => 'Nieznany utwór';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => 'Pokaż głośność';

  @override
  String get mediaHideVolume => 'Ukryj głośność';

  @override
  String get mediaMute => 'Wycisz';

  @override
  String get mediaUnmute => 'Wyłącz wyciszenie';

  @override
  String get mediaFavoriteAdd => 'Dodaj do ulubionych';

  @override
  String get mediaFavoriteRemove => 'Usuń z ulubionych';

  @override
  String get mediaShuffleOn => 'Włącz losowe odtwarzanie';

  @override
  String get mediaShuffleOff => 'Wyłącz losowe odtwarzanie';

  @override
  String get mediaRepeatAll => 'Powtarzaj wszystko';

  @override
  String get mediaRepeatOne => 'Powtarzaj jeden utwór';

  @override
  String get mediaRepeatOff => 'Wyłącz powtarzanie';

  @override
  String get mediaShowLyrics => 'Pokaż tekst utworu';

  @override
  String get mediaHideLyrics => 'Ukryj tekst utworu';

  @override
  String get mediaShowQueue => 'Pokaż kolejkę';

  @override
  String get mediaHideQueue => 'Ukryj kolejkę';

  @override
  String get mediaVolume => 'Głośność';

  @override
  String get mediaPlaybackPosition => 'Pozycja odtwarzania';

  @override
  String get mediaShowNowPlaying => 'Pokaż ekran „Teraz odtwarzane”';

  @override
  String get mediaShowFloatingPlayer => 'Pokaż pływający odtwarzacz';

  @override
  String get mediaOpenMusicAssistant => 'Otwórz Music Assistant';

  @override
  String get mediaCannotControl => 'polecenie nieobsługiwane lub niewysłane';

  @override
  String get mediaAudioHiRes => 'Hi-Res';

  @override
  String get mediaAudioCdQuality => 'Jakość CD';

  @override
  String get mediaAudioLossy => 'Stratny';

  @override
  String mediaAudioBitDepth(String bits) {
    return '$bits-bitowy';
  }

  @override
  String mediaAudioSampleRate(String rate) {
    return '$rate kHz';
  }

  @override
  String mediaAudioBitRate(String rate) {
    return '$rate kb/s';
  }

  @override
  String get mediaNothingQueued => 'Kolejka jest pusta';

  @override
  String get mediaChapters => 'Rozdziały';

  @override
  String get mediaNowPlaying => 'Teraz odtwarzane';

  @override
  String get mediaUpNext => 'Następne w kolejce';

  @override
  String mediaUnnamedChapter(String number) {
    return 'Rozdział $number';
  }

  @override
  String get mediaGroupLead => 'Lider grupy';

  @override
  String get mediaGroupReadFailed => 'Nie udało się odczytać grupy.';

  @override
  String get mediaGroupEmpty => 'Brak innych odtwarzaczy do zgrupowania.';

  @override
  String get mediaSpeakerSelection => 'Wybór głośników';

  @override
  String pluginCloseWindow(String name) {
    return 'Zamknij „$name”';
  }

  @override
  String get pluginScanTitle => 'Zeskanuj kod';

  @override
  String get pluginScanHelp => 'Umieść kod w ramce.';

  @override
  String pluginScanSource(String name) {
    return 'Na żądanie wtyczki „$name”';
  }

  @override
  String get pluginActions => 'Akcje';

  @override
  String get pluginKioskDrawer => 'Menu boczne kiosku';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      'Aby przypisać gest, otwórz „Gesty” i wybierz „Uruchom akcję wtyczki”.';

  @override
  String get pluginShowInKioskDrawer => 'Pokaż w menu bocznym kiosku';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      'Dostępne także przy zablokowanym kiosku, jeśli menu boczne kiosku jest dozwolone.';

  @override
  String get pluginExposeToHomeAssistant => 'Udostępnij w Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      'Dodaje przycisk do urządzenia ESPHome kiosku. Wymaga ESPHome i natywnych encji.';

  @override
  String pluginConfigureName(String name) {
    return 'Skonfiguruj „$name”';
  }

  @override
  String get pluginThePluginDidNotAnswerInTime =>
      'Wtyczka nie odpowiedziała na czas.';

  @override
  String get pluginNoChoicesYetRefreshToLookForThem =>
      'Brak opcji. Odśwież, aby je wyszukać.';

  @override
  String get pluginThisChoiceIsNoLongerListed =>
      'Tej opcji nie ma już na liście.';

  @override
  String get pluginDashboardLink => 'Link dla pulpitu';

  @override
  String get pluginDashboardLinkHint =>
      'Ustaw ten link jako akcję dotknięcia przycisku na pulpicie.';

  @override
  String get pluginPlugin => 'Wtyczka';

  @override
  String get pluginEnablePlugins => 'Włącz wtyczki';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      'Wtyczki dodają do Kiosk Satellite dodatkowe funkcje tworzone przez społeczność.';

  @override
  String get pluginInstalledPlugins => 'Zainstalowane wtyczki';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      'Brak zainstalowanych wtyczek. Dodaj repozytorium, aby zacząć.';

  @override
  String get pluginDeveloperTools => 'Narzędzia programisty';

  @override
  String get pluginCreateAPlugin => 'Utwórz wtyczkę';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      'Dowiedz się, jak tworzyć wtyczki, korzystając z szablonu Hello World i dokumentacji.';

  @override
  String get pluginThisPluginIsNoLongerInstalled =>
      'Ta wtyczka nie jest już zainstalowana.';

  @override
  String get pluginEnablePluginsToRunThisPlugin =>
      'Aby uruchomić tę wtyczkę, włącz opcję „Włącz wtyczki”.';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      'Aby uruchomić tę wtyczkę, włącz ją w jej wierszu na liście.';

  @override
  String pluginUninstallName(String name) {
    return 'Odinstalować wtyczkę „$name”?';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return 'Odinstaluj wtyczkę „$name”';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return 'Sprawdź aktualizacje wtyczki „$name”';
  }

  @override
  String pluginAboutName(String name) {
    return 'O wtyczce „$name”';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings =>
      'Spowoduje to usunięcie wtyczki i jej ustawień.';

  @override
  String get pluginUninstall => 'Odinstaluj';

  @override
  String get pluginNoUpdatesAvailable => 'Brak dostępnych aktualizacji.';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      'Ta wtyczka została zainstalowana z pliku ZIP i nie ma pliku README z repozytorium.';

  @override
  String get pluginImageUnavailable => 'Obraz niedostępny';

  @override
  String get pluginCouldNotOpenThisLink => 'Nie udało się otworzyć tego linku.';

  @override
  String pluginEnableName(String name) {
    return 'Włącz wtyczkę „$name”';
  }

  @override
  String get pluginShowPassword => 'Pokaż hasło';

  @override
  String get pluginHidePassword => 'Ukryj hasło';

  @override
  String get pluginUntitled => 'Bez nazwy';

  @override
  String get pluginSearchIcons => 'Szukaj ikon';

  @override
  String get pluginChooseIcon => 'Wybierz ikonę';

  @override
  String get pluginSearchCameraViews => 'Szukaj widoków kamer';

  @override
  String get pluginChooseCameraView => 'Wybierz widok kamery';

  @override
  String get pluginCameraViewGone =>
      'Ten widok kamery już nie istnieje. Wybierz inny.';

  @override
  String get pluginDragToReorder => 'Przeciągnij, aby zmienić kolejność';

  @override
  String get pluginDuplicate => 'Duplikuj';

  @override
  String get pluginDone => 'Gotowe';

  @override
  String get pluginRequired => 'Wymagane';

  @override
  String get pluginAddPlugin => 'Dodaj wtyczkę';

  @override
  String get pluginInstallFromAGithubRepository =>
      'Zainstaluj z repozytorium GitHub';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd =>
      'Przed instalacją upewnij się, że ufasz autorowi wtyczki i jej kodowi.';

  @override
  String get pluginPreview => 'Podgląd';

  @override
  String get pluginInstalledVersion => 'Zainstalowana wersja';

  @override
  String get pluginAuthor => 'Autor';

  @override
  String get pluginLicense => 'Licencja';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      'Wtyczki uruchamiają kod wewnątrz Kiosk Satellite i mają dostęp do danych aplikacji oraz przyznanych uprawnień systemu Android. Wadliwa lub złośliwa wtyczka może ujawnić prywatne informacje lub sprawić, że aplikacja przestanie działać. Instaluj tylko wtyczki od autorów, którym ufasz.';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      'Nowe wtyczki są początkowo wyłączone. Aktualizacje zachowują stan włączenia i automatycznie uruchamiają ponownie działające wtyczki.';

  @override
  String get pluginTrustAndUpdate => 'Zaufaj i zaktualizuj';

  @override
  String get pluginTrustAndInstall => 'Zaufaj i zainstaluj';

  @override
  String get pluginInstallFromZip => 'Zainstaluj z pliku ZIP';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild =>
      'Tylko dla programistów: przetestuj lokalną kompilację';

  @override
  String get pluginPluginZip => 'Plik ZIP wtyczki';

  @override
  String get pluginPluginZipMustBeAtMost4Mb =>
      'Plik ZIP wtyczki może mieć maksymalnie 4 MB';

  @override
  String get pluginCouldNotReadTheSelectedZip =>
      'Nie udało się odczytać wybranego pliku ZIP';

  @override
  String get pluginBrowsePlugins => 'Przeglądaj wtyczki';

  @override
  String get pluginFindPluginsMadeByTheCommunity =>
      'Znajdź wtyczki tworzone przez społeczność';

  @override
  String get pluginSearchPlugins => 'Szukaj wtyczek';

  @override
  String get pluginUpdate => 'Aktualizuj';

  @override
  String get pluginInstalled => 'Zainstalowana';

  @override
  String pluginNeedsAppVersion(String version) {
    return 'Wymaga Kiosk Satellite w wersji $version lub nowszej';
  }

  @override
  String get pluginStars => 'Gwiazdki';

  @override
  String get pluginDownloads => 'Pobrania';

  @override
  String get pluginActiveInstalls => 'Aktywne instalacje';

  @override
  String get pluginNoPluginsMatchYourSearch =>
      'Brak wtyczek pasujących do wyszukiwania.';

  @override
  String get pluginCommunityPluginsHasNoPluginsYet =>
      'Katalog „Wtyczki społeczności” nie zawiera jeszcze wtyczek.';

  @override
  String get pluginSubmitYourPlugin => 'Zgłoś swoją wtyczkę';

  @override
  String get pluginListYourPluginInCommunityPlugins =>
      'Dodaj swoją wtyczkę do katalogu „Wtyczki społeczności”.';

  @override
  String get pluginCouldNotReachCommunityPlugins =>
      'Nie udało się połączyć z katalogiem „Wtyczki społeczności”. Sprawdź połączenie z internetem.';

  @override
  String get pluginCouldNotLoadCommunityPlugins =>
      'Nie udało się wczytać katalogu „Wtyczki społeczności”. Spróbuj ponownie później.';

  @override
  String get pluginTurnOn => 'Włącz';

  @override
  String get pluginTurnOnEnablePluginsToInstall =>
      'Aby zainstalować tę wtyczkę, włącz opcję „Włącz wtyczki”.';

  @override
  String get pluginPreviousPage => 'Poprzednia strona';

  @override
  String get pluginNextPage => 'Następna strona';

  @override
  String pluginPageOfPages(String page, String pages) {
    return 'Strona $page z $pages';
  }

  @override
  String get pluginSortBy => 'Sortuj według';

  @override
  String get pluginSortMostStars => 'Najwięcej gwiazdek';

  @override
  String get pluginSortRecentlyUpdated => 'Ostatnio zaktualizowane';

  @override
  String get pluginSortNewest => 'Najnowsze';

  @override
  String get pluginSortName => 'Nazwa';

  @override
  String get pluginSortMostDownloads => 'Najwięcej pobrań';

  @override
  String get pluginPluginsPerPage => 'Wtyczki na stronie';

  @override
  String pluginCountPerPage(String count) {
    return '$count na stronie';
  }

  @override
  String pluginByAuthor(String author) {
    return 'Autor: $author';
  }

  @override
  String get pluginListedChip => 'W katalogu „Wtyczki społeczności”';

  @override
  String get pluginNotListedChip => 'Brak w katalogu „Wtyczki społeczności”';

  @override
  String get pluginReleaseNotes => 'Informacje o zmianach';

  @override
  String get pluginCharts => 'Wykresy';

  @override
  String get pluginReadings => 'Odczyty';

  @override
  String get pluginWaitingForSamples => 'Oczekiwanie na próbki';

  @override
  String get pluginLatest => 'Najnowsze';

  @override
  String get pluginSelected => 'Wybrane';

  @override
  String get pluginNoDataYet => 'Na razie brak danych';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      'Dotknij lub przeciągnij, aby sprawdzić próbki. Dotknij dwukrotnie, aby śledzić najnowsze.';

  @override
  String get pluginNoData => 'Brak danych';

  @override
  String get pluginOn => 'Włączone';

  @override
  String get pluginEmpty => 'Puste';

  @override
  String get pluginChartKeyboardHelp =>
      'Używaj strzałek, aby przeglądać próbki, a klawisza End, aby przejść do najnowszej.';

  @override
  String get pluginErrorAssetPath => 'Nieprawidłowa ścieżka pliku wydania';

  @override
  String get pluginErrorAssetMissing =>
      'Brak pliku wydania lub plik znajduje się poza pakietem';

  @override
  String get pluginErrorAssetSymlink =>
      'Katalog plików wydania nie może być dowiązaniem symbolicznym';

  @override
  String get pluginErrorAssetSymlinks =>
      'Katalogi plików wydania nie mogą być dowiązaniami symbolicznymi';

  @override
  String get pluginErrorAssetsIntegrity =>
      'Zainstalowane pliki wydania nie przeszły kontroli integralności';

  @override
  String get pluginErrorAssetIntegrity =>
      'Zainstalowany plik wydania nie przeszedł kontroli integralności';

  @override
  String get pluginErrorManifestMismatch =>
      'Manifest pakietu nie zgadza się z manifestem sprawdzonej wersji wydania';

  @override
  String get pluginErrorStagingExists => 'Katalog tymczasowy już istnieje';

  @override
  String get pluginErrorCreateDirectory =>
      'Nie można utworzyć katalogu wtyczki';

  @override
  String get pluginErrorFileCount =>
      'Obsługiwane jest maksymalnie 512 plików pakietu';

  @override
  String get pluginErrorProtectFile => 'Nie można zabezpieczyć pliku wtyczki';

  @override
  String get pluginErrorExpandedSize => 'Rozpakowana wtyczka przekracza 4 MB';

  @override
  String get pluginErrorManifestSize => 'Manifest przekracza 32 KB';

  @override
  String get pluginErrorRequiredFiles =>
      'Pakiet musi zawierać pliki kiosk-satellite-plugin.json, plugin.jar i LICENSE';

  @override
  String get pluginErrorNativeCapability =>
      'Biblioteki natywne wymagają możliwości „native”';

  @override
  String get pluginErrorNativeElf => 'Nieprawidłowa natywna biblioteka ELF';

  @override
  String get pluginErrorNativeAbi =>
      'ABI biblioteki natywnej nie pasuje do jej katalogu';

  @override
  String get pluginErrorDexOnly => 'plugin.jar może zawierać tylko pliki DEX';

  @override
  String get pluginErrorDexHeader => 'Nieprawidłowy nagłówek DEX';

  @override
  String get pluginErrorDexSize => 'Rozpakowany plik DEX przekracza 4 MB';

  @override
  String get pluginErrorDexEmpty => 'Pusty plik DEX';

  @override
  String get pluginErrorDexMissing =>
      'plugin.jar nie zawiera pliku classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'Nieoczekiwany lub zduplikowany wpis ZIP: $name';
  }

  @override
  String get pluginErrorRepositoryMismatch =>
      'Wersja wydania z repozytorium należy do innej wtyczki.';

  @override
  String get pluginErrorRepositoryUrl =>
      'Wpisz publiczny adres URL w formacie https://github.com/owner/repository';

  @override
  String get pluginErrorRepositoryPath =>
      'Użyj adresu URL repozytorium bez ścieżki do pliku lub gałęzi';

  @override
  String get pluginErrorDownloadOutsideGithub =>
      'Pobieranie wtyczki przekierowano poza GitHub';

  @override
  String get pluginErrorInvalidRedirect =>
      'Nieprawidłowe przekierowanie GitHub';

  @override
  String get pluginErrorRepositoryNotFound =>
      'Nie znaleziono publicznego repozytorium, stabilnej wersji wydania, pliku kiosk-satellite-plugin.json, pliku README.md lub pliku wydania.';

  @override
  String get pluginErrorGithubLimited =>
      'GitHub odrzucił żądanie lub osiągnięto limit żądań. Spróbuj ponownie później.';

  @override
  String get pluginErrorRepositorySize =>
      'Plik repozytorium przekracza limit rozmiaru';

  @override
  String get pluginErrorTooManyRedirects => 'Zbyt wiele przekierowań GitHub';

  @override
  String get pluginErrorStableRelease =>
      'GitHub nie zwrócił opublikowanej stabilnej wersji wydania';

  @override
  String get pluginErrorReleaseTag => 'Nieprawidłowy tag wersji wydania';

  @override
  String get pluginErrorManifestFile =>
      'Nieprawidłowy manifest kiosk-satellite-plugin.json';

  @override
  String get pluginErrorIdVersion =>
      'Nieprawidłowy identyfikator lub wersja wtyczki';

  @override
  String get pluginErrorChecksumFilename =>
      'Nieprawidłowa suma kontrolna wersji wydania lub nazwa pliku pakietu';

  @override
  String get pluginErrorGithubDigest =>
      'Sumy kontrolne SHA-256 wersji wydania oraz pliku wydania w serwisie GitHub muszą być zgodne';

  @override
  String get pluginErrorTrustAuthor => 'Potwierdź, że ufasz autorowi wtyczki';

  @override
  String get pluginErrorPreviewExpired =>
      'Podgląd wygasł. Przed instalacją ponownie wyświetl podgląd repozytorium.';

  @override
  String get pluginErrorReviewedChecksum =>
      'Suma kontrolna SHA-256 pakietu nie zgadza się ze sprawdzoną wersją wydania';

  @override
  String get pluginErrorNotInstalled => 'Wtyczka nie jest zainstalowana';

  @override
  String get pluginErrorUpdateZip =>
      'Ta wtyczka została zainstalowana z pliku ZIP. Aby ją zaktualizować, użyj opcji „Zainstaluj z pliku ZIP”.';

  @override
  String get pluginErrorAndroidOnly =>
      'Wtyczki są dostępne w systemie Android.';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'Żądanie do GitHub nie powiodło się ($status)';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return 'Wersja wydania wymaga dokładnie jednego przesłanego pliku wydania $name';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return 'Plik wydania $name musi zostać opublikowany przez GitHub Actions. Pliki przesłane ręcznie nie są obsługiwane.';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return 'Plik wydania $name przekracza limit rozmiaru lub jest pusty';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return 'Nieprawidłowy adres URL wersji wydania dla $name';
  }

  @override
  String get pluginErrorNativeLibrary =>
      'Wtyczka nie zawiera biblioteki natywnej dla ABI tego urządzenia';

  @override
  String get pluginErrorCallbackTimeout =>
      'Przekroczono limit czasu wywołania zwrotnego wtyczki. Uruchom ponownie Kiosk, jeśli wtyczka pozostawiła uruchomione zadania.';

  @override
  String get pluginErrorEnableFirst => 'Najpierw włącz wtyczkę';

  @override
  String get pluginErrorSaveState => 'Nie można zapisać stanu wtyczki';

  @override
  String get pluginErrorPackageHash =>
      'Nieprawidłowy skrót zainstalowanego pakietu';

  @override
  String get pluginErrorChecksum => 'Suma SHA-256 pakietu nie zgadza się';

  @override
  String get pluginErrorDifferentRepository =>
      'Ten identyfikator wtyczki należy do innego repozytorium. Przed zmianą źródła odinstaluj wtyczkę.';

  @override
  String get pluginErrorRestartReplace =>
      'Ta wtyczka nie zatrzymała się prawidłowo. Przed jej zastąpieniem uruchom ponownie Kiosk Satellite.';

  @override
  String get pluginErrorAlreadyInstalled => 'Ten pakiet jest już zainstalowany';

  @override
  String get pluginErrorLoadedIntegrity =>
      'Wcześniej wczytany pakiet nie przeszedł kontroli integralności. Przed ponowną instalacją uruchom ponownie Kiosk Satellite.';

  @override
  String get pluginErrorRemovePackage =>
      'Nie można usunąć nieużywanego pakietu';

  @override
  String get pluginErrorInstallPackage =>
      'Nie można zainstalować pakietu wtyczki';

  @override
  String get pluginErrorUpdateCanceled =>
      'Anulowano aktualizację, ponieważ wtyczka nie zatrzymała się prawidłowo. Przed ponowną próbą uruchom ponownie Kiosk Satellite.';

  @override
  String get pluginErrorVersionRetained => 'Zachowano poprzednią wersję.';

  @override
  String get pluginErrorRetainedDisabled =>
      'Zachowano poprzednią wersję, ale jest wyłączona. Przed jej włączeniem uruchom ponownie Kiosk Satellite.';

  @override
  String get pluginErrorVersionRunning => 'Poprzednia wersja znowu działa.';

  @override
  String get pluginErrorEnablePlugins => 'Najpierw włącz obsługę wtyczek';

  @override
  String get pluginErrorRestartEnable =>
      'Ta wtyczka nie zatrzymała się prawidłowo. Przed jej włączeniem uruchom ponownie Kiosk Satellite.';

  @override
  String get pluginErrorInstalledIntegrity =>
      'Zainstalowana wtyczka nie przeszła kontroli integralności. Zainstaluj ją ponownie.';

  @override
  String get pluginErrorAndroidOld => 'Wersja systemu Android jest zbyt stara';

  @override
  String get pluginErrorNeedsScreen => 'Ta wtyczka wymaga ekranu';

  @override
  String get pluginErrorNativeIntegrity =>
      'Zainstalowane biblioteki natywne nie przeszły kontroli integralności';

  @override
  String get pluginErrorNativeFileIntegrity =>
      'Zainstalowana biblioteka natywna nie przeszła kontroli integralności';

  @override
  String pluginErrorReadInstalled(String error) {
    return 'Nie można odczytać zainstalowanej wtyczki: $error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return 'Nie udało się ponownie uruchomić poprzedniej wersji: $error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return 'Aktualizacja wtyczki nie powiodła się: $error. $recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      'Wymagana jest aplikacja Shizuku w wersji 13 lub nowszej. Dotknij, aby wyświetlić instrukcje konfiguracji.';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      'Uruchom Shizuku na tym urządzeniu. Dotknij, aby wyświetlić instrukcje konfiguracji.';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku przyznaje aplikacji Kiosk Satellite dostęp do powłoki lub uprawnienia roota. Zainstalowane wtyczki działają wewnątrz KS, więc przyznaj dostęp tylko wtedy, gdy im ufasz.';

  @override
  String get pluginSetUp => 'Skonfiguruj';

  @override
  String get pluginGrantAccess => 'Przyznaj dostęp';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      'Zatwierdź prośbę o uprawnienie na kiosku.';

  @override
  String get pluginErrorInvalidId => 'Nieprawidłowy identyfikator wtyczki';

  @override
  String get pluginErrorInvalidVersion => 'Nieprawidłowa wersja';

  @override
  String get pluginErrorEntryClass => 'Nieprawidłowa klasa wejściowa';

  @override
  String get pluginErrorManifestSchema => 'Nieobsługiwany schemat manifestu';

  @override
  String get pluginErrorSdkVersion => 'Ta wtyczka wymaga innej wersji SDK';

  @override
  String get pluginErrorMinimumSdk =>
      'Minimalna wersja Android SDK musi wynosić co najmniej 24';

  @override
  String get pluginErrorCapability => 'Nieobsługiwana funkcja wtyczki';

  @override
  String get pluginErrorTooManySettings => 'Zbyt wiele ustawień lub poleceń';

  @override
  String get pluginErrorSettingKey =>
      'Nieprawidłowy lub zduplikowany klucz ustawienia';

  @override
  String get pluginErrorGroupsArray => 'Grupy wyświetlania muszą być tablicą';

  @override
  String get pluginErrorTooManyGroups => 'Zbyt wiele grup wyświetlania';

  @override
  String get pluginErrorUniqueGroups =>
      'Grupy wyświetlania muszą wskazywać unikalne grupy ustawień';

  @override
  String get pluginErrorGroupReferences => 'Zbyt wiele odwołań do grup';

  @override
  String get pluginErrorDuplicateReference =>
      'Nieprawidłowe lub zduplikowane odwołanie do grupy';

  @override
  String get pluginErrorCommandId =>
      'Nieprawidłowy lub zduplikowany identyfikator polecenia';

  @override
  String get pluginErrorUnknownSetting => 'Nieznane ustawienie wtyczki';

  @override
  String get pluginErrorTextLength =>
      'Ustawienia tekstowe mogą mieć maksymalnie 512 znaków';

  @override
  String get pluginErrorEntityId =>
      'Oczekiwano identyfikatora encji Home Assistant';

  @override
  String get pluginErrorBoolean => 'Oczekiwano ustawienia logicznego';

  @override
  String get pluginErrorColor =>
      'Oczekiwano koloru RGB w zapisie szesnastkowym';

  @override
  String get pluginErrorNumber => 'Oczekiwano ustawienia liczbowego';

  @override
  String get pluginErrorRange => 'Ustawienie liczbowe jest poza zakresem';

  @override
  String get pluginErrorStep => 'Ustawienie liczbowe nie pasuje do kroku';

  @override
  String get pluginErrorSelection => 'Nieprawidłowe ustawienie wyboru';

  @override
  String get pluginErrorSelectionOption => 'Nieznana opcja wyboru';

  @override
  String get pluginErrorSettingType => 'Nieobsługiwany typ ustawienia';

  @override
  String get pluginErrorInvalidManifest => 'Nieprawidłowy manifest wtyczki';

  @override
  String pluginErrorAndroidApi(String version) {
    return 'Wtyczka wymaga Android API w wersji $version';
  }

  @override
  String pluginErrorAppVersion(String required, String current) {
    return 'Wtyczka wymaga Kiosk Satellite w wersji $required lub nowszej. Ten kiosk ma wersję $current.';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return 'Nieprawidłowe pole: $field';
  }

  @override
  String get pluginErrorTooManyTriggers => 'Zbyt wiele wyzwalaczy';

  @override
  String get pluginErrorTriggerId =>
      'Nieprawidłowy lub zduplikowany identyfikator wyzwalacza';

  @override
  String get pluginErrorListSetting => 'Nieprawidłowe ustawienie listy';

  @override
  String get pluginErrorSettingCondition => 'Nieprawidłowy warunek ustawienia';

  @override
  String get pluginErrorIcon => 'Oczekiwano nazwy ikony MDI';

  @override
  String get pluginErrorDashboard => 'Oczekiwano ścieżki pulpitu';

  @override
  String get pluginErrorCameraView => 'Oczekiwano identyfikatora widoku kamery';

  @override
  String get pluginErrorListValue => 'Oczekiwano ustawienia listy';

  @override
  String get pluginErrorListCount => 'Zbyt wiele lub zbyt mało elementów listy';

  @override
  String get pluginErrorRequiredField => 'Wypełnij wszystkie wymagane pola';

  @override
  String get pluginErrorListSize =>
      'Ustawienia listy mogą mieć maksymalnie 32 KB';

  @override
  String get remoteDisableTitle => 'Wyłączyć zdalne zarządzanie?';

  @override
  String get remoteDisableHelp =>
      'OSTRZEŻENIE: dostęp do tej strony nie będzie już możliwy. Aby ponownie włączyć zdalne zarządzanie, użyj urządzenia lub przełącznika „Zdalne zarządzanie” w Home Assistant.';

  @override
  String get remoteDisableConfirm => 'Wyłącz';

  @override
  String get remoteCopyHelp => 'Zaznacz klucz i skopiuj go ręcznie.';

  @override
  String get remoteSaveSettingFailed =>
      'Nie udało się zapisać tego ustawienia. Spróbuj ponownie.';

  @override
  String get remoteReconnecting => 'Ponowne łączenie…';

  @override
  String remoteConnectionLost(String name) {
    return 'Utracono połączenie z urządzeniem „$name”. Ta strona wznowi działanie automatycznie, gdy połączenie wróci.';
  }

  @override
  String get remoteConnectionLostUnnamed =>
      'Utracono połączenie z kioskiem. Ta strona wznowi działanie automatycznie, gdy połączenie wróci.';

  @override
  String get remoteReloadPage => 'Przeładuj stronę';

  @override
  String get remoteUpdated => 'Zaktualizowano Kiosk Satellite';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return 'Urządzenie działa teraz w wersji $version$build. Ta strona należy do poprzedniej wersji i zostanie przeładowana za $seconds s.';
  }

  @override
  String remoteBuild(String build) {
    return ' (kompilacja $build)';
  }

  @override
  String get remoteReloadNow => 'Przeładuj teraz';

  @override
  String get remoteLogin => 'Zaloguj się';

  @override
  String get remoteInvalidPassword => 'Nieprawidłowe hasło';

  @override
  String get remoteLoginThrottled =>
      'Zbyt wiele prób. Odczekaj 5 minut i spróbuj ponownie.';

  @override
  String get deviceScreenOffPermission =>
      'Wyłączenie ekranu wymaga jednorazowego uprawnienia. Na tablecie wyświetla się teraz ekran przyznawania uprawnienia „Administrator urządzenia”. Zatwierdź je tam i spróbuj ponownie.';

  @override
  String get deviceAdminInactive =>
      'Uprawnienie administratora urządzenia jest nieaktywne.';

  @override
  String get deviceRestartOverlay =>
      'Ponowne uruchomienie wymaga uprawnienia „Wyświetlanie nad innymi aplikacjami”, bez niego aplikacja nie może sama wrócić na ekran. Na urządzeniu otwiera się ekran przyznawania uprawnienia, zezwól na nie tam i ponów próbę.';

  @override
  String get deviceRebootPermission =>
      'Ponowne uruchomienie urządzenia wymaga skonfigurowania Kiosk Satellite jako właściciela urządzenia lub przyznanego połączenia z Shizuku.';

  @override
  String get deviceRestartAndroidOnly =>
      'Ponowne uruchomienie jest dostępne tylko w systemie Android.';

  @override
  String get deviceRestartShizukuRefused =>
      'Ponowne uruchomienie zostało odrzucone przez Shizuku';

  @override
  String deviceRestartFailed(String error) {
    return 'Ponowne uruchomienie nie powiodło się: $error';
  }

  @override
  String get overviewAttention => 'Wymaga uwagi';

  @override
  String get overviewUpdate => 'Aktualizuj';

  @override
  String overviewInvitation(String name) {
    return '$name chce zostać liderem tego kiosku';
  }

  @override
  String get overviewOutdatedOne =>
      '1 członek floty działa w innej wersji wydania';

  @override
  String overviewOutdatedMany(String count) {
    return 'Członkowie floty w innej wersji wydania: $count';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names. Synchronizacja czeka na wersję $version.';
  }

  @override
  String get overviewThisRelease => 'ta wersja wydania';

  @override
  String get overviewUpdateAvailable => 'Dostępna aktualizacja';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version jest gotowy do instalacji. Instalację potwierdza się na ekranie tabletu.';
  }

  @override
  String overviewInstallSilentHelp(String version) {
    return 'Kiosk Satellite $version jest gotowy do instalacji. Instaluje się bez potwierdzania na urządzeniu.';
  }

  @override
  String overviewInstallHeadlessHelp(String version) {
    return 'Kiosk Satellite $version jest gotowy do instalacji. To urządzenie nie ma ekranu, na którym można ją potwierdzić, więc ustaw Kiosk Satellite jako właściciela urządzenia, użyj Shizuku lub zainstaluj aplikację przez adb.';
  }

  @override
  String get overviewHaSetup => 'Nie skonfigurowano Home Assistant';

  @override
  String get overviewHaSetupHelp =>
      'Połącz kiosk z Home Assistant, aby wczytać pulpit.';

  @override
  String get overviewSetUp => 'Skonfiguruj';

  @override
  String get overviewHaNotValidated => 'Nie zweryfikowano Home Assistant';

  @override
  String get overviewHaNotValidatedHelp =>
      'Adres URL i token nie przeszły sprawdzenia połączenia podczas tego uruchomienia. Kiosk ponawia próbę co 30 sekund.';

  @override
  String get overviewOpenSetup => 'Otwórz konfigurację';

  @override
  String get overviewWakeStopped => 'Zatrzymano wykrywanie słowa wybudzającego';

  @override
  String get overviewWakeReleased =>
      'Silnik wykrywania słowa wybudzającego został zatrzymany.';

  @override
  String get overviewOpenVoice => 'Otwórz Voice Satellite';

  @override
  String get overviewOpenService => 'Otwórz usługę';

  @override
  String overviewPermissionMissing(String permission) {
    return 'Brak uprawnienia: $permission';
  }

  @override
  String get overviewSystemUpdate => 'Dostępna aktualizacja systemu';

  @override
  String overviewPluginUpdate(String name) {
    return 'Dostępna aktualizacja: $name';
  }

  @override
  String overviewPluginUpdateHelp(String version) {
    return 'Wersja $version czeka na przejrzenie i instalację.';
  }

  @override
  String overviewSystemImageUpdateHelp(String version) {
    return 'Wersja $version obrazu systemu jest gotowa do instalacji. Podczas instalacji urządzenie uruchomi się ponownie dwa razy.';
  }

  @override
  String get overviewQuick => 'Opcje szybkiego sterowania';

  @override
  String get overviewReload => 'Przeładuj stronę';

  @override
  String get overviewScreenOn => 'Włącz ekran';

  @override
  String get overviewScreenOff => 'Wyłącz ekran';

  @override
  String get overviewSaverStart => 'Uruchom wygaszacz ekranu';

  @override
  String get overviewSaverStop => 'Zamknij wygaszacz ekranu';

  @override
  String get overviewCameraShow => 'Pokaż widok kamery';

  @override
  String get overviewCameraHide => 'Zamknij widok kamery';

  @override
  String get overviewSaverPostpone => 'Odłóż wygaszacz ekranu';

  @override
  String get overviewDnd => 'Nie przeszkadzać';

  @override
  String get overviewDndOn => 'Nie przeszkadzać: włączone';

  @override
  String get overviewSnapshot => 'Zrób zdjęcie';

  @override
  String get overviewCheckUpdates => 'Sprawdź aktualizacje';

  @override
  String get overviewRestartApp => 'Uruchom ponownie aplikację';

  @override
  String get overviewRestartDevice => 'Uruchom ponownie urządzenie';

  @override
  String get overviewExit => 'Zamknij aplikację';

  @override
  String get overviewBrightness => 'Jasność';

  @override
  String get overviewVolume => 'Głośność główna';

  @override
  String get overviewBrightnessGrant =>
      'Jasność działa w trybie zastępczym na poziomie aplikacji. Przyznaj uprawnienie „Modyfikowanie ustawień systemu”, aby suwak sterował rzeczywistą jasnością panelu.';

  @override
  String get overviewRestartQuestion =>
      'Uruchomić ponownie to urządzenie? Kiosk Satellite uruchomi się ponownie po starcie systemu.';

  @override
  String get overviewRestart => 'Uruchom ponownie';

  @override
  String get overviewNoSnapshot => 'Nie otrzymano zdjęcia.';

  @override
  String get overviewSnapshotTitle => 'Zdjęcie z kamery';

  @override
  String get overviewUpdateCheckFailed =>
      'Nie udało się sprawdzić aktualizacji. Czy urządzenie ma dostęp do serwisu GitHub?';

  @override
  String get overviewLatest => 'Zainstalowana jest najnowsza wersja.';

  @override
  String overviewVersionAvailable(String version) {
    return 'Dostępna jest wersja $version';
  }

  @override
  String get overviewInstallAttention =>
      'Zainstaluj ją w sekcji „Wymaga uwagi”.';

  @override
  String get overviewNoViewsWithCameras =>
      'Żaden widok kamery nie ma jeszcze kamer. Najpierw dodaj kamery do widoku w sekcji „Kamery”.';

  @override
  String get overviewShowViewFailed => 'Nie udało się pokazać widoku';

  @override
  String get overviewAppVersion => 'Wersja aplikacji';

  @override
  String get overviewNotSetup => 'Nie skonfigurowano';

  @override
  String get overviewNotValidated => 'Nie zweryfikowano';

  @override
  String get overviewCheckingFilter => 'Sprawdzanie filtra…';

  @override
  String get overviewValidated => 'Zweryfikowano';

  @override
  String get overviewFilterUnavailable => 'Stan filtra niedostępny';

  @override
  String get overviewUnfiltered => 'Aktualizacje niefiltrowane';

  @override
  String get overviewWatchingOne => 'Obserwowana 1 encja';

  @override
  String overviewWatchingMany(String count) {
    return 'Obserwowane encje: $count';
  }

  @override
  String overviewFilterDisabled(String count) {
    return 'Filtrowanie wyłączone, encje używane przez widok: $count';
  }

  @override
  String get overviewWakeOff => 'Wykrywanie słowa wybudzającego wyłączone';

  @override
  String overviewListeningFor(String words) {
    return 'Nasłuchiwanie: $words';
  }

  @override
  String get overviewListening => 'Nasłuchiwanie';

  @override
  String get overviewNotListening => 'Brak nasłuchiwania';

  @override
  String get overviewEntitiesProxy => 'Encje i proxy Bluetooth';

  @override
  String get overviewEntitiesOnly => 'Tylko encje';

  @override
  String get overviewProxyOnly => 'Tylko proxy Bluetooth';

  @override
  String get overviewWaitingHA => 'Oczekiwanie na Home Assistant';

  @override
  String get overviewNotRunning => 'Nie działa';

  @override
  String get overviewRunningOne => 'Działa: 1 funkcja';

  @override
  String overviewRunningMany(String count) {
    return 'Działa (funkcje: $count)';
  }

  @override
  String overviewDownloading(String version) {
    return 'Pobieranie: $version';
  }

  @override
  String overviewNewVersion(String version) {
    return 'Nowa wersja: $version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return 'Aktualna wersja: $version';
  }

  @override
  String get overviewCurrent => 'Aktualne';

  @override
  String overviewPluginAttribution(String name) {
    return 'Wtyczka $name';
  }

  @override
  String get overviewMuted => 'wyciszone';

  @override
  String get overviewBrowser => 'przeglądarka';

  @override
  String get overviewWakeWaiting =>
      'Oczekiwanie na Voice Satellite. Silnik i słowa wybudzające skonfiguruje integracja, gdy to urządzenie otworzy swój pulpit.';

  @override
  String get overviewWakeDisabled =>
      'Wykrywanie słowa wybudzającego jest wyłączone. Włącz je, aby przejąć modele z Voice Satellite.';

  @override
  String get overviewMicBlocked =>
      'Mikrofon zablokowany. Android nie zapyta ponownie, więc zezwól na dostęp w ustawieniach aplikacji, a potem ponów.';

  @override
  String get overviewMicDeclined =>
      'Odmówiono dostępu do mikrofonu. Jest on potrzebny do wykrywania słowa wybudzającego; ponów, aby system zapytał ponownie.';

  @override
  String get overviewMicLost =>
      'Mikrofon przestał działać. Ponów lub przeładuj stronę.';

  @override
  String get overviewModelsUnavailable =>
      'Nie udało się pobrać modeli z Home Assistant. Ponów, gdy będzie dostępny.';

  @override
  String get overviewCrashed =>
      'Detektor na tym urządzeniu wielokrotnie ulegał awarii, więc został zatrzymany. Voice Satellite nasłuchuje zamiast tego w przeglądarce. Ponów lub uruchom ponownie aplikację.';

  @override
  String get overviewWakeFailed =>
      'Nie udało się uruchomić silnika słowa wybudzającego. Ponów lub przeładuj stronę.';

  @override
  String overviewNativeUnavailable(String engine) {
    return 'Brak natywnego modułu dla $engine. Voice Satellite pozostaje przy wykrywaniu w przeglądarce.';
  }

  @override
  String get overviewNativeListening => 'Nasłuchiwanie natywne';

  @override
  String get overviewSuspended => 'Gotowe (wstrzymane podczas sesji głosowej)';

  @override
  String get overviewCpu => 'CPU';

  @override
  String get overviewMemory => 'RAM';

  @override
  String get overviewTemperature => 'Temp.';

  @override
  String overviewMemoryFree(String amount) {
    return 'Wolne: $amount GB';
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
  String get overviewShowingCustomPages => 'Wyświetlanie własnych stron';

  @override
  String get overviewHeadlessMode => 'Tryb bez ekranu';

  @override
  String get overviewNoScreenshot => 'Brak zrzutu ekranu';

  @override
  String get overviewStill => 'Statyczny';

  @override
  String get overviewLive => 'Na żywo';

  @override
  String get overviewFullSize => 'Pełny rozmiar';

  @override
  String get overviewLiveInterval => 'Na żywo, co 5 s';

  @override
  String overviewTaken(String age) {
    return 'Wykonano $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return 'Widok kamery: $name';
  }

  @override
  String get overviewCameraView => 'Widok kamery';

  @override
  String get overviewScreenOffState => 'Ekran jest wyłączony';

  @override
  String get overviewGoView => 'Przejdź do widoku';

  @override
  String get screensaverNoPhotos =>
      'Nie wybrano zdjęć. Wybierz je w ustawieniach.';

  @override
  String get screensaverNoFolder =>
      'Nie wybrano folderu. Wybierz go w ustawieniach.';

  @override
  String screensaverFolderEmpty(String folder) {
    return 'Brak zdjęć i filmów w folderze $folder';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return 'Nie udało się odczytać folderu $folder. Czy przyznano uprawnienie do multimediów?';
  }

  @override
  String get screensaverReadPhotosFailed => 'Nie udało się odczytać zdjęć.';

  @override
  String get screensaverImmichNotReady =>
      'Brak połączenia z Immich. Sprawdź połączenie w ustawieniach.';

  @override
  String get screensaverNoMediaMatch =>
      'Żadne multimedia nie pasują do źródła i filtrów.';

  @override
  String get screensaverNoMediaSource => 'Brak multimediów w wybranym źródle.';

  @override
  String get screensaverImmichUnreachable =>
      'Nie udało się połączyć z serwerem Immich.';

  @override
  String screensaverRetryNotice(String error) {
    return '$error Ponowna próba nastąpi automatycznie.';
  }

  @override
  String get screensaverVideosTooLarge =>
      'Wszystkie filmy na tej playliście są za duże, aby to urządzenie mogło je odtworzyć.';

  @override
  String get screensaverUrlNotSet =>
      'Nie ustawiono adresu URL obrazu. Dodaj go w ustawieniach.';

  @override
  String get screensaverUrlLoadFailed => 'Nie udało się wczytać obrazu.';

  @override
  String get settingKioskAllowAlarmsTitle => 'Budziki';

  @override
  String get settingKioskAllowAlarmsDescription =>
      'Ustawianie budzików i zarządzanie nimi z menu kiosku.';

  @override
  String get settingScreensaverClockAlarmTakeoverTitle =>
      'Pozwól budzikom przejąć wygaszacz';

  @override
  String get settingScreensaverClockAlarmTakeoverDescription =>
      'Dzwoniący budzik pojawia się na tym wygaszaczu, w jego stylu, zamiast na osobnym ekranie.';

  @override
  String get settingScreensaverWeatherAlarmTakeoverTitle =>
      'Pozwól budzikom przejąć wygaszacz';

  @override
  String get settingScreensaverWeatherAlarmTakeoverDescription =>
      'Dzwoniący budzik pojawia się na tym wygaszaczu, w jego stylu, zamiast na osobnym ekranie.';

  @override
  String get settingAlarmsVolumeTitle => 'Głośność budzika';

  @override
  String get settingAlarmsVolumeDescription =>
      'Jak głośno dzwonią budziki, niezależnie od głośności multimediów.';

  @override
  String get settingAlarmsToneTitle => 'Dźwięk budzika';

  @override
  String get settingAlarmsToneDescription => 'Odtwarzany z głośnością budzika.';

  @override
  String get settingAlarmsMusicTitle => 'Muzyka budzika';

  @override
  String get settingAlarmsMusicDescription =>
      'Gra zamiast dźwięku budzika. Jeśli muzyki nie da się odtworzyć, zabrzmi dźwięk budzika.';

  @override
  String get settingAlarmsSnoozeMinutesTitle => 'Długość drzemki';

  @override
  String get settingAlarmsSnoozeMinutesDescription =>
      'Na jak długo „Drzemka” odsuwa budzik.';

  @override
  String get settingAlarmsSilenceAfterMinutesTitle => 'Wyciszenie po';

  @override
  String get settingAlarmsSilenceAfterMinutesDescription =>
      'Budzik, którego nikt nie wyłączy, ucichnie po tym czasie.';

  @override
  String get settingAlarmsSunriseMinutesTitle => 'Długość wschodu słońca';

  @override
  String get settingAlarmsSunriseMinutesDescription =>
      'Jak długo ekran rozjaśnia się przed budzikiem ze wschodem słońca.';

  @override
  String get settingAlarmsSkipMinutesTitle => 'Przycisk pomijania';

  @override
  String get settingAlarmsSkipMinutesDescription =>
      'Na jak długo przed budzikiem wygaszacze „Zegar” i „Nastrój pogody” pokazują przycisk do jego pominięcia.';

  @override
  String get alarmsOption5Minutes => '5 minut';

  @override
  String get alarmsOption10Minutes => '10 minut';

  @override
  String get alarmsOption15Minutes => '15 minut';

  @override
  String get alarmsOption20Minutes => '20 minut';

  @override
  String get alarmsOption25Minutes => '25 minut';

  @override
  String get alarmsOption30Minutes => '30 minut';

  @override
  String get alarmsOption60Minutes => '60 minut';

  @override
  String get alarmsOptionOff => 'Wyłączone';

  @override
  String get settingsMenuAlarms => 'Budziki';

  @override
  String get settingsMenuAlarmsSummary =>
      'Ustaw budziki, dźwięk, drzemkę i wschód słońca';

  @override
  String get settingAlarmsEaseInTitle => 'Stopniowo zwiększaj głośność';

  @override
  String get settingAlarmsEaseInDescription =>
      'Budzik zaczyna cicho i stopniowo osiąga ustawioną głośność.';

  @override
  String get settingAlarmsEaseInSecondsTitle => 'Czas narastania głośności';

  @override
  String get settingAlarmsEaseInSecondsDescription =>
      'Czas, w jakim budzik osiąga pełną głośność.';

  @override
  String get settingAlarmsTtsEngineTitle => 'Silnik zamiany tekstu na mowę';

  @override
  String get settingAlarmsTtsEngineDescription =>
      'Encja zamiany tekstu na mowę w Home Assistant, która odczytuje budziki na głos.';

  @override
  String get settingAlarmsTtsLanguageTitle => 'Język';

  @override
  String get settingAlarmsTtsLanguageDescription =>
      'Język, w którym budziki są odczytywane.';

  @override
  String get settingAlarmsTtsVoiceTitle => 'Głos';

  @override
  String get settingAlarmsTtsVoiceDescription =>
      'Głos, który odczytuje budziki.';

  @override
  String get settingLauncherEnabledTitle => 'Włącz launcher aplikacji';

  @override
  String get settingLauncherEnabledDescription =>
      'Otwieraj wybrane zainstalowane aplikacje z poziomu kiosku.';

  @override
  String get settingLauncherAppsDescription =>
      'Aplikacje oferowane przez launcher.';

  @override
  String get settingLauncherAutoReturnTitle => 'Wracaj automatycznie';

  @override
  String get settingLauncherAutoReturnDescription =>
      'Wracaj do widoku kiosku automatycznie, gdy inna aplikacja przez jakiś czas nie była używana.';

  @override
  String get settingLauncherAutoReturnSecondsTitle => 'Powrót po (s)';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      'Czas bez dotknięcia ekranu w innej aplikacji, po którym wraca widok kiosku.';

  @override
  String get settingLauncherAutoReturnHoldTitle =>
      'Czekaj podczas multimediów i połączeń';

  @override
  String get settingLauncherAutoReturnHoldDescription =>
      'Nie wracaj do widoku kiosku, gdy trwa wideo, muzyka lub połączenie.';

  @override
  String get launcherOverlayHeld =>
      'Kiosk Satellite może sam wrócić na pierwszy plan i rejestrować dotknięcia w innej aplikacji.';

  @override
  String get launcherOverlayMissing =>
      'Bez tego kiosk nie może sam wrócić na pierwszy plan, a dotknięcia ekranu w innej aplikacji pozostają niezarejestrowane.';

  @override
  String get launcherOverlayRemote =>
      'Bez tego kiosk nie może sam wrócić na pierwszy plan, a dotknięcia ekranu w innej aplikacji pozostają niezarejestrowane. Ekran nadania uprawnienia pojawi się na tablecie.';

  @override
  String get launcherBatteryMissing =>
      'Android może wstrzymać aplikację działającą w tle za inną aplikacją, a wstrzymany zegar nigdy nie przywróci kiosku na pierwszy plan.';

  @override
  String get launcherBatteryRemote =>
      'Android może wstrzymać aplikację działającą w tle za inną aplikacją, a wstrzymany zegar nigdy nie przywróci kiosku na pierwszy plan. Okno nadania uprawnienia pojawi się na tablecie.';

  @override
  String get launcherNotificationAccessHeld =>
      'Kiosk nie wraca na pierwszy plan, gdy w innej aplikacji odtwarzane jest wideo lub muzyka.';

  @override
  String get launcherNotificationAccessMissing =>
      'Bez tego kiosk nie rozpozna, że odtwarzane jest wideo lub muzyka, i mimo to wróci na pierwszy plan.';

  @override
  String get launcherNotificationAccessRemote =>
      'Bez tego kiosk nie rozpozna, że odtwarzane jest wideo lub muzyka, i mimo to wróci na pierwszy plan. Ekran nadania uprawnienia pojawi się na tablecie.';

  @override
  String get launcherPermissionsSearch =>
      'Uprawnienia, których wymaga funkcja „Wracaj automatycznie”.';

  @override
  String get settingCalendarDefaultViewTitle => 'Widok domyślny';

  @override
  String get settingCalendarDefaultViewDescription =>
      'Widok, w którym otwiera się Kalendarz.';

  @override
  String get settingCalendarWeekStartTitle => 'Początek tygodnia';

  @override
  String get settingCalendarWeekStartAppLanguageDescription =>
      'Zgodnie z językiem aplikacji, jeśli nie ustawiono inaczej.';

  @override
  String get settingCalendarWeatherEntityTitle => 'Pogoda';

  @override
  String get settingCalendarWeatherEntityDescription =>
      'Dodaje prognozę do każdego dnia.';

  @override
  String get settingCalendarAllowEditTitle =>
      'Zezwalaj na dodawanie i edytowanie wydarzeń';

  @override
  String get settingCalendarAllowEditDescription =>
      'Dodaje do kalendarza przyciski „Nowe wydarzenie” i „Edytuj”.';

  @override
  String get settingCalendarAllowDeleteTitle => 'Zezwalaj na usuwanie wydarzeń';

  @override
  String get settingCalendarAllowDeleteDescription =>
      'Dodaje przycisk „Usuń” do każdego wydarzenia.';

  @override
  String get settingCalendarIdleCloseMinutesTitle =>
      'Zamykaj przy bezczynności';

  @override
  String get settingIdleCloseCompassDescription =>
      'Wraca do pulpitu po takim czasie bez dotknięcia. W układzie Compass zamiast tego działa ustawienie „Powrót do środka”.';

  @override
  String get settingKioskAllowCalendarTitle => 'Kalendarz';

  @override
  String get settingKioskAllowCalendarDescription =>
      'Otwieraj kalendarz rodzinny z menu kiosku.';

  @override
  String get calendarWeekStartLocale => 'Domyślny dla języka';

  @override
  String get calendarWeekStartSunday => 'Niedziela';

  @override
  String get calendarWeekStartMonday => 'Poniedziałek';

  @override
  String get calendarWeekStartSaturday => 'Sobota';

  @override
  String get calendarIdleNever => 'Nigdy';

  @override
  String get calendarIdle1Minute => '1 minuta';

  @override
  String get calendarIdle2Minutes => '2 minuty';

  @override
  String get settingsMenuCalendar => 'Kalendarz';

  @override
  String get settingsMenuCalendarSummary =>
      'Kalendarze rodzinne z Home Assistant';

  @override
  String get fleetTheCalendarsHiddenWithTheirChips =>
      'kalendarze ukryte za pomocą ich etykiet';

  @override
  String get settingCalendarFaceFocusTitle => 'Wyróżniaj osobę przy kiosku';

  @override
  String get settingCalendarFaceFocusDescription =>
      'Obrysowuje znacznik osoby przy kiosku, ustawia jej kolumnę jako pierwszą w widoku Dzień i wybiera jej kalendarz dla nowych wydarzeń.';

  @override
  String get settingCameraEnabledTitle => 'Włącz kamerę';

  @override
  String get settingCameraEnabledDescription =>
      'Korzystanie z kamery zwiększa obciążenie procesora i nagrzewanie, co może skrócić żywotność baterii i urządzenia.';

  @override
  String get settingCameraDeviceTitle => 'Kamera';

  @override
  String get settingCameraDeviceDescription => 'Kamera, której używać.';

  @override
  String get settingCameraSnapshotResolutionTitle => 'Rozdzielczość zdjęć';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      'Wyższa daje ostrzejszy obraz, ale bardziej obciąża procesor i łącze.';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle =>
      'Wyłącz zdjęcia przy wykryciu';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      'Zapobiega automatycznym zdjęciom wyzwalanym przez wykrywanie. Wykrywanie ruchu, twarzy, obecności i gestów nadal działa. Ręczne żądania i „Ciągłe zdjęcia” nadal mogą rejestrować obrazy.';

  @override
  String get settingCameraSnapshotsTitle => 'Ciągłe zdjęcia';

  @override
  String get settingCameraSnapshotsDescription =>
      'Publikuje nowe zdjęcie z kamery w Home Assistant w stałych odstępach czasu.';

  @override
  String get settingCameraSnapshotIntervalTitle => 'Odstęp między zdjęciami';

  @override
  String get settingCameraSnapshotIntervalDescription =>
      'Liczba sekund między zdjęciami.';

  @override
  String get cameraFront => 'Przednia';

  @override
  String get cameraBack => 'Tylna';

  @override
  String get cameraExternal => 'Zewnętrzna';

  @override
  String get cameraOnlyCamera => 'Jedyna kamera tego urządzenia.';

  @override
  String get cameraFlashlightHeading => 'Latarka';

  @override
  String get settingCameraFlashlightTitle => 'Włącz latarkę';

  @override
  String get settingCameraFlashlightDescription =>
      'Użyj lampy błyskowej kamery jako stałego światła.';

  @override
  String get settingMotionSensorTitle => 'Czujnik ruchu';

  @override
  String get settingMotionSensorDescription =>
      'Udostępnia ruch w Home Assistant jako czujnik. UWAGA: kamera pozostaje stale włączona, nawet przy wyłączonym ekranie.';

  @override
  String get settingMotionSensorOffDelayTitle => 'Brak ruchu po';

  @override
  String get settingMotionSensorOffDelayDescription =>
      'Liczba sekund bez ruchu, po której czujnik zgłasza brak ruchu.';

  @override
  String get settingMotionFpsTitle => 'Liczba klatek wykrywania ruchu';

  @override
  String get settingMotionFpsDescription =>
      'Liczba klatek na sekundę, w których kamera sprawdza ruch. Mniejsza wartość mniej obciąża procesor; 2 wystarczy, by zauważyć zbliżającą się osobę.';

  @override
  String get settingMotionStartDelayTitle => 'Opóźnienie startu';

  @override
  String get settingMotionStartDelayDescription =>
      'Ruch jest ignorowany przez ten czas po uruchomieniu kamery. Przydatne w urządzeniach, których kamera fizycznie porusza się podczas otwierania.';

  @override
  String get settingMotionSensitivityTitle => 'Czułość wykrywania ruchu';

  @override
  String get settingMotionSensitivityDescription =>
      'Wyższa wartość reaguje na mniejsze ruchy. 1 wymaga dużej zmiany w całym kadrze; 100 reaguje na najmniejszy ruch.';

  @override
  String get cameraMotionPage => 'Czujnik ruchu';

  @override
  String get cameraMotionHint =>
      'Czujnik ruchu w Home Assistant i wspólne ustawienia wykrywania';

  @override
  String get cameraNoCamera => 'Nie wykryto kamery';

  @override
  String get cameraNoCameraHelp =>
      'To urządzenie nie zgłasza żadnej kamery, której można użyć.';

  @override
  String get cameraCameraPermission => 'Brak uprawnienia do kamery';

  @override
  String get cameraCameraPermissionHelp =>
      'Bez niego nie można używać kamery. Okno przyznania uprawnienia pojawia się na ekranie tabletu.';

  @override
  String get cameraGrantOnDevice => 'Przyznaj na urządzeniu';

  @override
  String get cameraCameraBlocked =>
      'Zablokowano. Android nie zapyta ponownie, więc przyznaj uprawnienie w ustawieniach aplikacji.';

  @override
  String get cameraCameraNeeded =>
      'Bez tego uprawnienia nie można używać kamery.';

  @override
  String get cameraAppSettings => 'Ustawienia aplikacji';

  @override
  String get settingPersonSensorTitle => 'Włącz czujnik osób';

  @override
  String get settingPersonSensorDescription =>
      'Udostępnia czujnik osób urządzenia w Home Assistant jako czujnik obecności. Wymaga poniższego uprawnienia dostępu do logów.';

  @override
  String get cameraPersonPage => 'Czujnik osób';

  @override
  String get cameraPersonHint =>
      'Czujnik obecności w Home Assistant oparty na czujniku osób urządzenia';

  @override
  String get cameraLatest => 'Ostatnie zdjęcie';

  @override
  String get cameraNoSnapshot => 'Brak zdjęć.';

  @override
  String get cameraImageAlt => 'Ostatnie zdjęcie z kamery';

  @override
  String get cameraTakeSnapshot => 'Zrób zdjęcie';

  @override
  String get cameraSnapshotFailed => 'Nie udało się zrobić zdjęcia.';

  @override
  String cameraSnapshotError(String error) {
    return 'Nie udało się zrobić zdjęcia: $error';
  }

  @override
  String get cameraCameraDisabled =>
      'Kamera jest wyłączona w ustawieniach kamery.';

  @override
  String get cameraSnapshotBusy => 'Trwa już robienie zdjęcia.';

  @override
  String get cameraPermissionDenied => 'Nie przyznano uprawnienia do kamery.';

  @override
  String get cameraDetectionDisabled => 'Zdjęcia z wykrywania są wyłączone.';

  @override
  String get cameraNoImage => 'Kamera nie zwróciła obrazu.';

  @override
  String get cameraTimedOut => 'Kamera nie odpowiedziała na czas.';

  @override
  String get cameraBackground =>
      'Kamera jest niedostępna, gdy aplikacja działa w tle.';

  @override
  String get cameraJustNow => 'przed chwilą';

  @override
  String cameraSecondsAgo(String count) {
    return '$count s temu';
  }

  @override
  String get cameraMinuteAgo => 'minutę temu';

  @override
  String cameraMinutesAgo(String count) {
    return '$count min temu';
  }

  @override
  String get cameraHourAgo => 'godzinę temu';

  @override
  String cameraHoursAgo(String count) {
    return '$count h temu';
  }

  @override
  String get cameraDayAgo => 'dzień temu';

  @override
  String cameraDaysAgo(String count) {
    return '$count dni temu';
  }

  @override
  String get cameraStatusHeading => 'Stan strumienia';

  @override
  String get cameraClientsHeading => 'Połączeni klienci';

  @override
  String get cameraUnavailable => 'Niedostępne';

  @override
  String get cameraStopped => 'Zatrzymane';

  @override
  String get cameraStreaming => 'Strumieniowanie';

  @override
  String get cameraIdle => 'Bezczynne';

  @override
  String get cameraConnected => 'Połączono';

  @override
  String get cameraChecking => 'Sprawdzanie…';

  @override
  String get cameraCheckingStatus => 'Sprawdzanie stanu strumienia…';

  @override
  String get cameraStatusUnavailable => 'Stan strumienia niedostępny.';

  @override
  String get cameraListenerStopped => 'Nasłuchiwanie zatrzymane.';

  @override
  String cameraViewer(String count, String resolution) {
    return 'Połączeni klienci: $count. Rzeczywisty obraz: $resolution.';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return 'Połączeni klienci: $count. Rzeczywisty obraz: $resolution.';
  }

  @override
  String get cameraReady =>
      'Gotowe. Enkoder wideo uruchamia się, gdy połączy się klient.';

  @override
  String cameraFallback(String requested, String actual) {
    return 'Zażądano $requested, kamera dostarczyła $actual.';
  }

  @override
  String cameraAudioError(String error) {
    return 'Dźwięk: $error';
  }

  @override
  String get cameraAudioPaused =>
      'Dźwięk wstrzymany, gdy przeglądarka używa mikrofonu.';

  @override
  String get cameraAudioStreaming => 'Dźwięk z mikrofonu: przesyłany.';

  @override
  String get cameraAudioIdle => 'Dźwięk z mikrofonu: nieaktywny.';

  @override
  String cameraDiscoveryError(String error) {
    return 'Wykrywanie ONVIF: $error';
  }

  @override
  String get cameraOnvifUrl => 'Adres URL ONVIF';

  @override
  String get cameraStreamUrl => 'Adres URL strumienia';

  @override
  String get cameraWaitingAddress => 'Oczekiwanie na adres sieciowy';

  @override
  String get cameraClientsUnavailable =>
      'Informacje o klientach są niedostępne.';

  @override
  String get cameraNoClients => 'Brak połączonych klientów.';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · Port $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return 'Czas połączenia: $duration';
  }

  @override
  String cameraDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String cameraDurationMinutes(String minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String cameraDurationHours(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get cameraCredentialsMissing =>
      'Ustaw nazwę użytkownika i hasło do strumieniowania, aby włączyć uwierzytelnianie.';

  @override
  String get cameraPortWaiting => 'Oczekiwanie na zwolnienie portu RTSP.';

  @override
  String get cameraListenerFailed =>
      'Nie udało się uruchomić nasłuchiwania RTSP.';

  @override
  String get settingCameraRtspEnabledTitle => 'Włącz strumieniowanie z kamery';

  @override
  String get settingCameraRtspEnabledDescription =>
      'Udostępnij wideo H.264 klientom RTSP lub ONVIF. Kodowanie wideo działa tylko wtedy, gdy połączony jest klient. Preferowane jest kodowanie sprzętowe, a w razie potrzeby używane jest kodowanie programowe. Używana jest kamera wybrana w ustawieniach kamery.';

  @override
  String get settingCameraStreamingProtocolTitle => 'Protokół strumieniowania';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF pozwala zgodnym klientom wykryć kamerę i połączyć się z jej strumieniem.';

  @override
  String get settingCameraRtspPortTitle => 'Port';

  @override
  String get settingCameraRtspPortDescription => 'Port serwera RTSP.';

  @override
  String get settingCameraOnvifPortTitle => 'Port';

  @override
  String get settingCameraOnvifPortDescription => 'Port serwera ONVIF.';

  @override
  String get settingCameraRtspResolutionTitle => 'Rozdzielczość';

  @override
  String get settingCameraRtspResolutionDescription =>
      'Rozdzielczości strumienia obsługiwane przez wybraną kamerę i koder. Obraz dopasowuje się do orientacji urządzenia.';

  @override
  String get settingCameraRtspAnalysisTitle =>
      'Analiza ruchu podczas strumieniowania';

  @override
  String get settingCameraRtspAnalysisDescription =>
      'Zachowaj dostępność wykrywania ruchu, wykrywania twarzy i gestów dłoni, gdy połączeni są klienci. Wyłączenie tej opcji może umożliwić wyższe rozdzielczości. Zdjęcia są wtedy wykonywane z klatek wideo w rozdzielczości strumienia.';

  @override
  String get settingCameraRtspFpsTitle => 'Liczba klatek na sekundę';

  @override
  String get settingCameraRtspFpsDescription =>
      'Docelowa liczba klatek wideo na sekundę. Wykrywanie ruchu ma osobną częstotliwość analizy. Faktyczna liczba dostarczanych klatek zależy od kamery.';

  @override
  String get settingCameraRtspBitrateTitle => 'Szybkość transmisji wideo';

  @override
  String get settingCameraRtspBitrateDescription =>
      'Docelowa szybkość transmisji wideo. Wyższa wartość poprawia szczegółowość i zużywa więcej przepustowości sieci.';

  @override
  String get settingCameraRtspAudioTitle => 'Dołącz dźwięk z mikrofonu';

  @override
  String get settingCameraRtspAudioDescription =>
      'Dołącz dźwięk z mikrofonu do strumienia z kamery. Korzysta z ustawień mikrofonu. OSTRZEŻENIE: zwiększone użycie procesora.';

  @override
  String get settingCameraRtspAuthTitle => 'Wymagaj uwierzytelniania';

  @override
  String get settingCameraRtspAuthDescription =>
      'Wymagaj nazwy użytkownika i hasła do oglądania strumienia. Uwierzytelnianie nie włącza szyfrowania.';

  @override
  String get settingCameraRtspUsernameTitle => 'Nazwa użytkownika';

  @override
  String get settingCameraRtspUsernameDescription =>
      'Nazwa użytkownika dla klientów strumieniowania.';

  @override
  String get settingCameraRtspPasswordTitle => 'Hasło';

  @override
  String get settingCameraRtspPasswordDescription =>
      'Ustaw hasło, aby uruchomić strumień z uwierzytelnianiem.';

  @override
  String get cameraStreamingPage => 'Strumieniowanie RTSP i ONVIF';

  @override
  String get cameraStreamingHint =>
      'Udostępnij kamerę urządzenia przez RTSP lub ONVIF';

  @override
  String get cameraPortError =>
      'Wpisz port jako liczbę całkowitą od 1024 do 65535.';

  @override
  String get cameraUsernameError =>
      'Użyj od 1 do 64 znaków bez spacji, cudzysłowów, dwukropków i ukośników odwrotnych.';

  @override
  String get cameraNoSizes => 'Brak obsługiwanych rozmiarów';

  @override
  String get cameraNoSizesHelp =>
      'Brak obsługiwanych rozmiarów. Sprawdź połączenie z kamerą.';

  @override
  String get cameraResolutionSupport => 'Obsługa rozdzielczości';

  @override
  String get cameraCheckingSizes =>
      'Sprawdzanie obsługi przez kamerę i koder H.264…';

  @override
  String get cameraSupportedSizes =>
      'Wyświetlane są tylko rozmiary obsługiwane przez kamerę i koder H.264 przy bieżących ustawieniach strumieniowania.';

  @override
  String cameraExtraSizes(String sizes) {
    return 'Wyłącz opcję „Analiza ruchu podczas strumieniowania”, aby używać także rozmiarów: $sizes.';
  }

  @override
  String get cameraAnalysisOff =>
      'Wykrywanie ruchu, wykrywanie twarzy i gesty dłoni są wstrzymywane, gdy połączeni są klienci. Zdjęcia są wykonywane z klatek wideo w rozdzielczości strumienia.';

  @override
  String cameraRejectedSizes(String sizes) {
    return 'Koder nie może użyć tych rozmiarów przy bieżących ustawieniach: $sizes.';
  }

  @override
  String cameraRejectedCount(String count) {
    return 'Rozmiary kamery wykluczone, bo koder nie może ich użyć przy bieżących ustawieniach: $count.';
  }

  @override
  String get cameraCaptureRejected =>
      'Inne rozmiary kamery są niedostępne w bieżącej konfiguracji przechwytywania.';

  @override
  String get cameraMotionEventsHeading => 'Zdarzenia ruchu';

  @override
  String get settingCameraOnvifEventsTitle => 'Wysyłaj zdarzenia ruchu';

  @override
  String get settingCameraOnvifEventsDescription =>
      'Powiadamiaj klientów ONVIF, takich jak rejestratory NVR, o wykryciu ruchu.';

  @override
  String get settingCameraOnvifEventsSourceTitle => 'Źródło ruchu';

  @override
  String get settingCameraOnvifEventsSourceDescription =>
      'Czujnik wysyłający zdarzenia ruchu.';

  @override
  String get cameraOnvifEventsSourceCamera => 'Czujnik ruchu kamery';

  @override
  String get cameraOnvifEventsSourcePerson => 'Czujnik osób';

  @override
  String get cameraOnvifEventsSourceEntity => 'Czujnik Home Assistant';

  @override
  String get cameraOnvifEventsMotionSensorOff =>
      'Czujnik ruchu kamery jest wyłączony. Włącz go w sekcji „Kamera” > „Czujnik ruchu”.';

  @override
  String get cameraOnvifEventsAnalysisOff =>
      'Opcja „Analiza ruchu podczas strumieniowania” jest wyłączona, więc kamera nie może wykrywać ruchu, gdy połączony jest klient.';

  @override
  String get cameraOnvifEventsPersonSensorOff =>
      'Czujnik osób jest wyłączony. Włącz go w sekcji „Kamera” > „Czujnik osób”.';

  @override
  String get cameraOverlaysHeading => 'Nakładki';

  @override
  String get settingCameraRtspDateTimeTitle => 'Pokazuj datę i godzinę';

  @override
  String get settingCameraRtspDateTimeDescription =>
      'Pokazuj datę i godzinę urządzenia w lewym górnym rogu obrazu, zgodnie z jego formatem daty i ustawieniem zegara 12/24-godzinnego.';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => 'Czarne tło';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      'Dodaj czarne tło pod datą i godziną, aby poprawić czytelność.';

  @override
  String get settingCameraRtspTlsTitle => 'Szyfruj strumień';

  @override
  String get settingCameraRtspTlsDescription =>
      'Używaj TLS do szyfrowania obrazu i dźwięku. Wymaga zgodnego klienta.';

  @override
  String get cameraStreamsNameRequired => 'wymagana nazwa';

  @override
  String get cameraStreamsBaseUrlRequired =>
      'wymagany prawidłowy baseUrl HTTP lub HTTPS';

  @override
  String get cameraStreamsServerNotFound => 'nie znaleziono serwera';

  @override
  String get cameraStreamsInvalidStreamList =>
      'Go2RTC zwrócił nieprawidłową listę strumieni';

  @override
  String get cameraStreamsKindRequired =>
      'pole kind musi mieć wartość go2rtc, whep lub ha';

  @override
  String get cameraStreamsProtocolRequired =>
      'preferredProtocol musi mieć wartość auto, webrtc, hls lub mjpeg';

  @override
  String get cameraStreamsServerRequired => 'wymagany prawidłowy serverId';

  @override
  String get cameraStreamsStreamRequired => 'wymagany streamName';

  @override
  String get cameraStreamsEntityRequired => 'wymagane entityId encji camera.*';

  @override
  String get cameraStreamsWhepRequired => 'wymagany prawidłowy adres URL WHEP';

  @override
  String get cameraStreamsCameraNotFound => 'nie znaleziono kamery';

  @override
  String get cameraStreamsListRequired => 'cameraIds musi być listą';

  @override
  String get cameraStreamsViewCount => 'widok musi zawierać od 1 do 12 kamer';

  @override
  String get cameraStreamsRepeatedCamera =>
      'kamera może wystąpić w widoku tylko raz';

  @override
  String get cameraStreamsUnknownViewCamera => 'widok zawiera nieznaną kamerę';

  @override
  String get cameraStreamsUniqueViewName => 'nazwa widoku musi być unikalna';

  @override
  String get cameraStreamsGridRange => 'rozmiar siatki musi wynosić od 1 do 12';

  @override
  String get cameraStreamsGridTooSmall =>
      'siatka jest mniejsza niż liczba kamer';

  @override
  String get cameraStreamsViewNotFound => 'nie znaleziono widoku';

  @override
  String get cameraStreamsDefaultViewDelete =>
      'nie można usunąć widoku domyślnego; zamiast tego usuń z niego wszystkie kamery';

  @override
  String get cameraStreamsViewEmpty => 'widok nie zawiera kamer';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return 'nie udało się odczytać danych z Home Assistant: $error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return 'nie udało się połączyć z serwerem $server: $error';
  }

  @override
  String get cameraStreamsHaUnavailable =>
      'Home Assistant nie jest skonfigurowany lub jest nieosiągalny';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Serwer Go2RTC zwrócił kod HTTP $status';
  }

  @override
  String get cameraStreamsImportHa => 'Importuj kamery z Home Assistant';

  @override
  String get cameraStreamsImportHaHelp =>
      'Dodaj wszystkie kamery z połączonego serwera Home Assistant (odtwarzanie przez WebRTC, HLS lub MJPEG). Ponowny import dołącza nowe kamery do istniejących.';

  @override
  String get cameraStreamsImportFailed => 'Import nie powiódł się';

  @override
  String get cameraStreamsImportComplete => 'Import zakończony';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return 'Dodane: $added, brakujące: $missing.';
  }

  @override
  String get settingCameraAllowH265Title => 'Zezwalaj na strumienie H.265';

  @override
  String get settingCameraAllowH265Description =>
      'Strumienie z kamer w standardzie kompresji H.265 są odtwarzane bez konwersji. Urządzenie, które nie potrafi dekodować H.265, pokazuje zamiast nich pusty obraz.';

  @override
  String get settingCameraPreferMseTitle => 'Preferuj MSE zamiast WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      'Strumienie kamer Go2RTC są najpierw przesyłane przez MSE. Dla urządzeń, które nie odtwarzają WebRTC; opóźnienie wzrasta o sekundę lub dwie.';

  @override
  String get settingCameraPreferHlsTitle => 'Preferuj HLS zamiast WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      'Strumienie kamer Home Assistant są najpierw przesyłane przez HLS. Dla urządzeń, które nie odtwarzają WebRTC; opóźnienie wzrasta o kilka sekund.';

  @override
  String get settingCameraSingleAudioTitle =>
      'Odtwarzaj dźwięk pojedynczej kamery';

  @override
  String get settingCameraSingleAudioDescription =>
      'Dźwięk kamery jest odtwarzany, gdy na ekranie jest tylko jedna kamera. Siatki z kilkoma kamerami pozostają wyciszone.';

  @override
  String get settingCameraPinchZoomTitle =>
      'Wykonaj gest zsuwania palców, aby powiększyć obraz pojedynczej kamery';

  @override
  String get settingCameraPinchZoomDescription =>
      'Powiększaj obraz dwoma palcami, gdy na ekranie jest tylko jedna kamera. Przeciągnij, aby go przesunąć, dotknij dwukrotnie, aby zresetować.';

  @override
  String get settingCameraAutoDismissSecondsTitle => 'Zamknij automatycznie po';

  @override
  String get settingCameraAutoDismissCompassDescription =>
      'Zamyka otwarty widok kamery po tym czasie. 0 pozostawia go otwartym. Nie dotyczy wygaszacza ekranu z kamerą. W układzie Compass obowiązuje zamiast tego ustawienie „Powrót do środka”.';

  @override
  String get cameraStreamsPlayback => 'Odtwarzanie';

  @override
  String get cameraStreamsOff => 'Wyłączone';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get cameraStreamsGridHelp =>
      'Siatki z kilkoma kamerami odtwarzają tylko obraz. Na słabszych urządzeniach używaj w widokach strumieni Go2RTC o niższej rozdzielczości i opcjonalnie ustaw osobny strumień pełnoekranowy.';

  @override
  String get cameraStreamsServers => 'Serwery Go2RTC';

  @override
  String get cameraStreamsImportStreams => 'Importuj strumienie';

  @override
  String get cameraStreamsDeleteServer => 'Usuń serwer';

  @override
  String get cameraStreamsAddServer => 'Dodaj serwer Go2RTC';

  @override
  String get cameraStreamsAddServerHelp =>
      'Połącz się z serwerem i zaimportuj jego strumienie.';

  @override
  String get cameraStreamsEditServer => 'Edytuj serwer';

  @override
  String get cameraStreamsName => 'Nazwa';

  @override
  String get cameraStreamsBaseUrl => 'Bazowy adres URL';

  @override
  String get cameraStreamsUsername => 'Nazwa użytkownika (opcjonalnie)';

  @override
  String get cameraStreamsNewPassword =>
      'Nowe hasło (pozostaw puste, aby nie zmieniać)';

  @override
  String get cameraStreamsPassword => 'Hasło (opcjonalnie)';

  @override
  String get cameraStreamsInvalidCertificate =>
      'Zezwalaj na nieprawidłowy certyfikat TLS';

  @override
  String get cameraStreamsSaveServerFailed => 'Nie udało się zapisać serwera';

  @override
  String get cameraStreamsDeleteServerHelp =>
      'Jego kamery zostaną usunięte ze wszystkich widoków.';

  @override
  String get cameraStreamsCameras => 'Kamery';

  @override
  String get cameraStreamsNoCameras => 'Brak skonfigurowanych kamer';

  @override
  String get cameraStreamsNoCamerasHelp =>
      'Zaimportuj kamery z Home Assistant lub Go2RTC albo dodaj kamerę ręcznie.';

  @override
  String get cameraStreamsDeleteCamera => 'Usuń kamerę';

  @override
  String get cameraStreamsAddManually => 'Dodaj kamerę ręcznie';

  @override
  String get cameraStreamsAddManuallyHelp =>
      'Użyj nazwy strumienia Go2RTC, adresu URL WHEP lub encji kamery Home Assistant.';

  @override
  String get cameraStreamsUnknownCamera => 'Nieznana kamera';

  @override
  String get cameraStreamsUnknownServer => 'Nieznany serwer';

  @override
  String get cameraStreamsMissing => ' (brak)';

  @override
  String get cameraStreamsAddCamera => 'Dodaj kamerę';

  @override
  String get cameraStreamsEditCamera => 'Edytuj kamerę';

  @override
  String get cameraStreamsType => 'Typ';

  @override
  String get cameraStreamsGo2RtcStream => 'Strumień Go2RTC';

  @override
  String get cameraStreamsDirectWhep => 'Bezpośredni URL WHEP';

  @override
  String get cameraStreamsHaCamera => 'Kamera Home Assistant';

  @override
  String get cameraStreamsEntity => 'Encja kamery';

  @override
  String get cameraStreamsProtocol => 'Preferowany protokół';

  @override
  String get cameraStreamsAuto => 'Automatycznie';

  @override
  String get cameraStreamsServer => 'Serwer';

  @override
  String get cameraStreamsStreamName => 'Nazwa strumienia';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Nazwa strumienia Go2RTC';

  @override
  String get cameraStreamsFullscreen => 'Strumień pełnoekranowy (opcjonalnie)';

  @override
  String get cameraStreamsWhep => 'URL WHEP';

  @override
  String get cameraStreamsSaveCameraFailed => 'Nie udało się zapisać kamery';

  @override
  String get cameraStreamsDeleteCameraHelp =>
      'Zostanie usunięta ze wszystkich widoków.';

  @override
  String get cameraStreamsLoadFailed => 'Nie udało się wczytać kamer.';

  @override
  String get cameraStreamsDeleteUnused => 'Usuń nieużywane kamery';

  @override
  String get cameraStreamsDeleteUnusedConfirm => 'Usunąć nieużywane kamery?';

  @override
  String cameraStreamsOneUnusedCamera(String count) {
    return 'Kamera nieprzypisana do żadnego widoku: $count';
  }

  @override
  String cameraStreamsManyUnusedCameras(String count) {
    return 'Kamery spoza wszystkich widoków: $count';
  }

  @override
  String get cameraStreamsViews => 'Widoki';

  @override
  String get cameraStreamsEmptyView => 'Brak kamer';

  @override
  String get cameraStreamsNamesShown => 'Nazwy widoczne';

  @override
  String get cameraStreamsNamesHidden => 'Nazwy ukryte';

  @override
  String get cameraStreamsShowView => 'Pokaż widok';

  @override
  String get cameraStreamsDeleteView => 'Usuń widok';

  @override
  String get cameraStreamsCreateView => 'Utwórz widok kamer';

  @override
  String get cameraStreamsAddFirst => 'Najpierw dodaj kamerę.';

  @override
  String get cameraStreamsChooseCameras =>
      'Wybierz maksymalnie 12 kamer i ustal ich kolejność.';

  @override
  String get cameraStreamsShowFailed => 'Nie udało się pokazać widoku';

  @override
  String get cameraStreamsShowFailedRemote => 'Nie udało się pokazać widoku';

  @override
  String get cameraStreamsEditView => 'Edytuj widok';

  @override
  String get cameraStreamsViewId => 'ID widoku';

  @override
  String get cameraStreamsShowNames => 'Pokazuj nazwy kamer';

  @override
  String get cameraStreamsShowNamesHelp =>
      'Wyświetla etykietę na obrazie z każdej kamery.';

  @override
  String get cameraStreamsGrid => 'Siatka';

  @override
  String cameraStreamsOneCamera(String count) {
    return 'Kamera: $count';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return 'Kamery: $count';
  }

  @override
  String get cameraStreamsInView => 'W tym widoku';

  @override
  String get cameraStreamsAvailable => 'Dostępne';

  @override
  String cameraStreamsPosition(String position) {
    return 'Pozycja $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'Brak w Go2RTC';

  @override
  String get cameraStreamsSaveViewFailed => 'Nie udało się zapisać widoku';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return 'Usunąć „$name”?';
  }

  @override
  String get cameraStreamsCannotUndo => 'Tej operacji nie można cofnąć.';

  @override
  String get cameraStreamsShow => 'Pokaż';

  @override
  String get cameraStreamsStop => 'Zatrzymaj';

  @override
  String get settingAnalyticsBasicTitle => 'Podstawowa analityka';

  @override
  String get settingAnalyticsBasicDescription =>
      'Informacje o urządzeniu, takie jak model, wersja systemu Android, wersja aplikacji, rozmiar ekranu i język.';

  @override
  String get settingAnalyticsUsageTitle => 'Użytkowanie';

  @override
  String get settingAnalyticsUsageDescription =>
      'Szczegóły dotyczące używanych funkcji Kiosk Satellite.';

  @override
  String get settingAnalyticsDiagnosticsTitle => 'Diagnostyka';

  @override
  String get settingAnalyticsDiagnosticsDescription =>
      'Udostępniaj raporty o awariach, gdy wystąpią nieoczekiwane błędy.';

  @override
  String get deviceAnalyticsPage => 'Analityka Kiosk Satellite';

  @override
  String get deviceAnalyticsIntro =>
      'Udostępniaj zanonimizowane informacje o swojej instalacji, aby pomóc ulepszać Kiosk Satellite i wskazać, którym urządzeniom i funkcjom warto poświęcić uwagę.';

  @override
  String get deviceAnalyticsLearn => 'Dowiedz się, jak przetwarzamy dane';

  @override
  String get deviceAnalyticsLearnHelp =>
      'Jakie dane wysyła Analityka Kiosk Satellite, a jakich nigdy nie wysyła.';

  @override
  String get deviceExportConfig => 'Eksportuj konfigurację';

  @override
  String get deviceExportConfigHelp =>
      'Zapisz wszystkie ustawienia i lokalną pamięć strony w pliku.';

  @override
  String get deviceExportConfigRemoteHelp =>
      'Pobierz wszystkie ustawienia i lokalną pamięć strony.';

  @override
  String get deviceImportConfig => 'Importuj konfigurację';

  @override
  String get deviceImportConfigHelp =>
      'Zastąp ustawienia tego urządzenia danymi z wyeksportowanego pliku.';

  @override
  String get deviceExportFailed => 'Eksport nie powiódł się';

  @override
  String get deviceExported => 'Wyeksportowano konfigurację';

  @override
  String get deviceImportFailed => 'Import nie powiódł się';

  @override
  String get deviceInvalidJson => 'To nie jest prawidłowy plik JSON.';

  @override
  String get deviceImportComplete => 'Import zakończony';

  @override
  String deviceAppliedSettings(String count) {
    return 'Zastosowane ustawienia: $count.';
  }

  @override
  String deviceAppliedReload(String count) {
    return 'Zastosowane ustawienia: $count. Strona może się przeładować.';
  }

  @override
  String get deviceReplaceOriginal => 'Zastąp pierwotne urządzenie';

  @override
  String get deviceReplaceQuestion =>
      'Zastąpić ustawienia tego urządzenia ustawieniami z pliku? Strona może się przeładować.';

  @override
  String get deviceNewDevice => 'Skonfiguruj jako nowe urządzenie';

  @override
  String get deviceReplaceIdentity =>
      'Zachowuje nazwę i tożsamość ESPHome z kopii zapasowej; pierwotne urządzenie musi pozostać odłączone od sieci.';

  @override
  String get deviceNewIdentity =>
      'Nadaje własną nazwę i tożsamość ESPHome, dzięki czemu oba urządzenia są unikalne.';

  @override
  String get deviceRestoreStorage => 'Przywróć lokalną pamięć WebView';

  @override
  String get deviceRestoreStorageHelp =>
      'Obejmuje zalogowaną sesję Home Assistant i wybór assist_satellite w Voice Satellite. Dwa urządzenia nie mogą współdzielić jednego satelity.';

  @override
  String get deviceDownload => 'Pobierz';

  @override
  String get deviceChooseFile => 'Wybierz plik…';

  @override
  String get deviceImportFailedSentence => 'Import nie powiódł się.';

  @override
  String deviceReplaceNamed(String name) {
    return 'Zastąp „$name”';
  }

  @override
  String get settingDeviceNameTitle => 'Nazwa urządzenia';

  @override
  String get settingDeviceNameDescription =>
      'Przyjazna nazwa wyświetlana w zdalnej administracji i publikowana w Home Assistant jako nazwa urządzenia.';

  @override
  String get settingDeviceHostnameTitle => 'Nazwa mDNS';

  @override
  String get settingDeviceHostnameDescription =>
      'Używaj tej nazwy i skonfigurowanego portu, aby połączyć się ze zdalną administracją w sieci lokalnej. Wyczyść pole, aby ponownie użyć nazwy urządzenia.';

  @override
  String get settingDisableImpellerTitle => 'Starszy silnik renderujący';

  @override
  String get settingDisableImpellerDescription =>
      'Użyj starszej wersji silnika renderującego Skia na starych procesorach graficznych, które ulegają awarii przy uruchamianiu. Włącza się automatycznie po dwóch takich awariach i działa od następnego uruchomienia aplikacji.';

  @override
  String get settingLegacyWebViewTitle => 'Starszy silnik renderujący WebView';

  @override
  String get settingLegacyWebViewDescription =>
      'Renderuj pulpit do tekstury na starych procesorach graficznych, które ulegają awarii, gdy pulpit się pojawia. Włącza się automatycznie, gdy urządzenie tego wymaga, i działa od następnego uruchomienia aplikacji.';

  @override
  String get deviceHostnamePlaceholder =>
      'Ustawiana na podstawie nazwy urządzenia';

  @override
  String get deviceConfiguration => 'Konfiguracja';

  @override
  String get devicePermissionsManager => 'Menedżer uprawnień';

  @override
  String get deviceOptions => 'Opcje';

  @override
  String get deviceStatus => 'Stan';

  @override
  String get deviceConnection => 'Połączenie';

  @override
  String get devicePermissions => 'Uprawnienia';

  @override
  String get deviceHelp => 'Pomoc';

  @override
  String get deviceAccess => 'Dostęp';

  @override
  String get deviceReading => 'Odczytywanie…';

  @override
  String get deviceChecking => 'Sprawdzanie…';

  @override
  String get deviceUnavailable => 'Stan niedostępny.';

  @override
  String get deviceGrantOnDevice => 'Przyznaj na urządzeniu';

  @override
  String get deviceAppSettings => 'Ustawienia aplikacji';

  @override
  String get deviceCopyCommand => 'Kopiuj polecenie';

  @override
  String get deviceOpenGuide => 'Otwórz przewodnik';

  @override
  String get deviceNotSet => 'Nie ustawiono';

  @override
  String get deviceGranted => 'Przyznano';

  @override
  String get deviceNotGranted => 'Nie przyznano';

  @override
  String get deviceMissing => 'Brak';

  @override
  String get deviceNotOffered => 'Nieoferowane';

  @override
  String get deviceOn => 'włączone';

  @override
  String get deviceOff => 'wyłączone';

  @override
  String get deviceServiceHint =>
      'Stan, co podtrzymuje działanie usługi, wymagane uprawnienia';

  @override
  String get deviceRemoteHintActual =>
      'Zarządzaj tym kioskiem z przeglądarki w swojej sieci';

  @override
  String get deviceUpdatesHint => 'Gdzie aplikacja szuka nowych uaktualnień';

  @override
  String get deviceShizukuHint =>
      'Połączenie, uprawnienia Androida i konfiguracja';

  @override
  String get deviceHelperHint =>
      'Stan aktualizacji w tle, konfiguracja ADB i instrukcje';

  @override
  String get deviceAnalyticsHint =>
      'Udostępniaj zanonimizowane informacje, aby pomóc ulepszać Kiosk Satellite';

  @override
  String get deviceHardwareHint =>
      'Model, wersja Androida, adresy, pamięć, czas działania';

  @override
  String get deviceHaHint => 'Połączenie, wersja i to, co wyświetla kiosk';

  @override
  String get deviceWebViewHint => 'Wersja silnika, renderer i ciąg User-Agent';

  @override
  String get devicePasswordSet => '•••••• (ustawione)';

  @override
  String get deviceSaveFailed =>
      'Nie udało się zapisać tego ustawienia. Spróbuj ponownie.';

  @override
  String get deviceOpenSettingsDevice => 'Otwórz ustawienia na urządzeniu';

  @override
  String get deviceHardwareButtons => 'Przyciski fizyczne';

  @override
  String get deviceHardwareButtonsHeld =>
      'Naciśnięcia przycisków urządzenia docierają do gestów i Voice Satellite.';

  @override
  String get deviceHardwareButtonsMissing =>
      'Przyciski urządzenia nie działają, dopóki usługa przycisków nie zostanie włączona.';

  @override
  String get deviceHeadlessAdbMicrophone =>
      'To urządzenie nie ma ekranu. Przyznaj uprawnienie przez adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO';

  @override
  String get deviceHeadlessAdbNotifications =>
      'To urządzenie nie ma ekranu. Przyznaj uprawnienie przez adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS';

  @override
  String get deviceHeadlessAdbLocation =>
      'To urządzenie nie ma ekranu. Przyznaj uprawnienie przez adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION';

  @override
  String get deviceHeadlessAdbBluetooth =>
      'To urządzenie nie ma ekranu. Przyznaj uprawnienie przez adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN, a potem to samo dla BLUETOOTH_CONNECT';

  @override
  String get deviceHeadlessAdbBattery =>
      'To urządzenie nie ma ekranu. Przyznaj uprawnienie przez adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceHeadlessAdbStorage =>
      'To urządzenie nie ma ekranu. Przyznaj uprawnienie przez adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE, a potem to samo dla WRITE_EXTERNAL_STORAGE';

  @override
  String get deviceHeadlessAdbButtons =>
      'To urządzenie nie ma ekranu. Włącz usługę przez adb: adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/.HeadlessKeyService, a potem adb shell settings put secure accessibility_enabled 1';

  @override
  String get deviceHeadlessAdbButtonsRestart =>
      'Usługa przycisków jest włączona, ale się nie uruchomiła. Zrestartuj urządzenie, aby ją uruchomić: adb reboot';

  @override
  String get deviceHardwarePage => 'Sprzęt';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => 'Model urządzenia';

  @override
  String get deviceAndroidVersion => 'Wersja Androida';

  @override
  String get deviceAndroidBuild => 'Kompilacja systemu Android';

  @override
  String get deviceIpv4 => 'Adres IPv4';

  @override
  String get deviceIpv6 => 'Adresy IPv6';

  @override
  String get deviceAppUptime => 'Czas działania aplikacji';

  @override
  String get deviceNetworkUptime => 'Czas połączenia z siecią';

  @override
  String get deviceCpuUsage => 'Użycie procesora';

  @override
  String get deviceCpuClock => 'Taktowanie procesora';

  @override
  String get deviceCpuTemp => 'Temperatura procesora';

  @override
  String get deviceBatteryLevel => 'Poziom baterii';

  @override
  String get deviceBatteryTemp => 'Temperatura baterii';

  @override
  String get deviceScreenBrightness => 'Jasność ekranu';

  @override
  String get deviceScreenStatus => 'Stan ekranu';

  @override
  String get deviceScreenSize => 'Rozmiar ekranu';

  @override
  String get deviceRam => 'Pamięć RAM (wolna/całkowita)';

  @override
  String get deviceStorage => 'Pamięć wewnętrzna (wolna/całkowita)';

  @override
  String get deviceHaUrl => 'Adres URL Home Assistant';

  @override
  String get deviceWakeDetection => 'Wykrywanie słowa wybudzającego';

  @override
  String get deviceWakeStatus => 'Status słowa wybudzającego';

  @override
  String get deviceEngine => 'Silnik';

  @override
  String get deviceWakeWords => 'Słowa wybudzające';

  @override
  String get deviceStopWord => 'Słowo zatrzymujące';

  @override
  String get deviceMotionDetection => 'Wykrywanie ruchu';

  @override
  String get deviceFaceDetection => 'Wykrywanie twarzy';

  @override
  String get deviceProvider => 'Dostawca';

  @override
  String get deviceVersion => 'Wersja';

  @override
  String get deviceUserAgent => 'Klient użytkownika';

  @override
  String get devicePlugged => 'podłączone';

  @override
  String get deviceLowMemory => 'niski';

  @override
  String get deviceRequiredPermissions => 'Wymagane uprawnienia systemowe';

  @override
  String get devicePermissionIntro =>
      'Uprawnienia przyznaje się na tym urządzeniu, więc każdy przycisk otwiera tutaj okno dialogowe lub ekran ustawień systemu Android. Niektórzy producenci dodają własny menedżer baterii lub autostartu, o którym Android nie może poinformować.';

  @override
  String get devicePermissionIntroRemote =>
      'Uprawnienia przyznaje się na urządzeniu, więc każdy przycisk otwiera na nim okno dialogowe lub ekran ustawień systemu Android. Niektórzy producenci dodają własny menedżer baterii lub autostartu, o którym Android nie może poinformować.';

  @override
  String get deviceMicrophone => 'Mikrofon';

  @override
  String get deviceMicrophoneHeld =>
      'Umożliwia korzystanie z mikrofonu do wykrywania słowa wybudzającego, zamiany mowy na tekst i połączeń przez interkom.';

  @override
  String get deviceBattery => 'Bateria bez ograniczeń';

  @override
  String get deviceBatteryHeld =>
      'Pozwala procesowi działać w tle bez wstrzymywania ani zamykania.';

  @override
  String get deviceCamera => 'Kamera';

  @override
  String get deviceCameraHeld =>
      'Wykrywanie ruchu i zdjęcia mogą korzystać z kamery.';

  @override
  String get deviceBluetooth => 'Urządzenia w pobliżu';

  @override
  String get deviceBluetoothHeld =>
      'Proxy Bluetooth może wyszukiwać urządzenia w pobliżu.';

  @override
  String get deviceNotifications => 'Powiadomienia';

  @override
  String get deviceNotificationsHeld =>
      'Umożliwia wyświetlanie stałego powiadomienia usługi Kiosk Satellite, które informuje, co usługa utrzymuje w działaniu.';

  @override
  String get deviceOverlay => 'Wyświetlanie nad innymi aplikacjami';

  @override
  String get deviceOverlayHeld =>
      'Kiosk Satellite może samodzielnie wrócić na pierwszy plan.';

  @override
  String get deviceWriteSettings => 'Modyfikowanie ustawień systemu';

  @override
  String get deviceWriteSettingsHeld =>
      'Zmiany jasności ustawiają rzeczywistą jasność panelu.';

  @override
  String get deviceUiGuard => 'Ochrona interfejsu systemu';

  @override
  String get deviceUiGuardHeld =>
      'Pasek powiadomień i lista ostatnich aplikacji zamykają się same, gdy ekran jest chroniony.';

  @override
  String get deviceDeviceAdmin => 'Administrator urządzenia';

  @override
  String get deviceDeviceAdminHeld => 'Umożliwia aplikacji wyłączanie ekranu.';

  @override
  String get deviceAllFiles => 'Dostęp do wszystkich plików';

  @override
  String get deviceAllFilesHeld =>
      'Menedżer plików może przeglądać pamięć współdzieloną.';

  @override
  String get deviceUsageAccess => 'Dostęp do danych o użytkowaniu';

  @override
  String get deviceUsageAccessHeld =>
      'Czujnik aplikacji na pierwszym planie może podać nazwę dowolnej aplikacji widocznej na ekranie.';

  @override
  String get deviceLocation => 'Lokalizacja';

  @override
  String get deviceLocationHeld =>
      'Strony, skanowanie Bluetooth i czujniki lokalizacji mogą korzystać z położenia urządzenia.';

  @override
  String get deviceMicBlocked =>
      'Zablokowano. Android nie zapyta ponownie, więc przyznaj uprawnienie w ustawieniach aplikacji.';

  @override
  String get deviceMicMissing =>
      'Wykrywanie słowa wybudzającego jest włączone, ale nic nie nasłuchuje.';

  @override
  String get deviceMicIdle =>
      'Wymagane do wykrywania słowa wybudzającego, interkomu i stron, które proszą o dostęp do mikrofonu.';

  @override
  String get deviceBatteryMissing =>
      'Android może wstrzymać aplikację, gdy ekran jest wyłączony, zrywając połączenie z Home Assistant, a wraz z nim encje ESPHome.';

  @override
  String get deviceCameraMissing =>
      'Kamera jest włączona, ale nie można jej otworzyć.';

  @override
  String get deviceCameraIdle =>
      'Wymagane do wykrywania ruchu, zdjęć z kamery i stron, które proszą o dostęp do kamery.';

  @override
  String get deviceBluetoothMissing =>
      'Proxy Bluetooth jest włączone, ale nie może skanować.';

  @override
  String get deviceBluetoothLocation =>
      'Skanowanie Bluetooth wymaga uprawnienia do lokalizacji.';

  @override
  String get deviceBluetoothLocationOff =>
      'Lokalizacja jest wyłączona w ustawieniach urządzenia, więc skanowanie Bluetooth niczego nie znajduje.';

  @override
  String get deviceBluetoothIdle =>
      'Wymagane, aby proxy Bluetooth mogło wyszukiwać urządzenia.';

  @override
  String get deviceNotificationMissing =>
      'Wymagane do wyświetlania stałego powiadomienia usługi Kiosk Satellite.';

  @override
  String get deviceOverlayMissing =>
      'Bez tego uprawnienia aplikacja nie otworzy się ponownie po awarii, aktualizacji ani po usłyszeniu słowa wybudzającego, gdy jest za inną aplikacją.';

  @override
  String get deviceOverlayIdle =>
      'Pozwala aplikacji wrócić na pierwszy plan, a osłonie trybu blokady zakryć cały ekran.';

  @override
  String get deviceBrightnessMissing =>
      'Zmiana jasności tylko przyciemnia okno aplikacji, więc panel i Home Assistant jej nie widzą.';

  @override
  String get deviceBrightnessIdle =>
      'Wymagane do ustawiania rzeczywistej jasności panelu zamiast przyciemniania okna aplikacji.';

  @override
  String get deviceGuardMissing =>
      'Obszar powiadomień i lista ostatnich aplikacji pozostają dostępne. Włącz Kiosk Satellite w sekcji Ułatwienia dostępu.';

  @override
  String get deviceGuardIdle =>
      'Zamyka obszar powiadomień i listę ostatnich aplikacji, gdy tryb kiosku chroni ekran.';

  @override
  String get deviceAdminIdle =>
      'Pozwala funkcji „Wyłączenie ekranu” wyłączać panel, zamiast tylko go zaciemniać.';

  @override
  String get deviceFilesIdle =>
      'Pozwala menedżerowi plików przeglądać pamięć współdzieloną, a nie tylko folder aplikacji.';

  @override
  String get deviceUsageIdle =>
      'Pozwala czujnikowi aplikacji na pierwszym planie rozpoznawać aplikacje inne niż Kiosk Satellite.';

  @override
  String get deviceLocationMissing =>
      'Bez lokalizacji Android nie przekazuje wyników skanowania Bluetooth, a czujniki lokalizacji nie mogą odczytać odbiornika GPS.';

  @override
  String get deviceLocationIdle =>
      'Używane przez strony, które proszą o lokalizację, przez skanowanie Bluetooth i przez czujniki lokalizacji ESPHome.';

  @override
  String get deviceServiceOverlayMissing =>
      'Bez tego uprawnienia usługa nie może ponownie uruchomić kiosku po awarii lub zamknięciu z listy ostatnich aplikacji.';

  @override
  String get deviceServiceOverlayIdle =>
      'Wymagane do ponownego uruchomienia kiosku po awarii.';

  @override
  String get deviceListeningMissing =>
      'Nasłuchiwanie w tle jest włączone, ale nic nie nasłuchuje.';

  @override
  String get deviceListeningIdle => 'Wymagane do nasłuchiwania w tle.';

  @override
  String get deviceMotionIdle => 'Wymagane do wykrywania ruchu.';

  @override
  String get deviceBatteryAdb =>
      'To urządzenie nie ma ekranu ustawień dla tego uprawnienia. Przyznaj je przez adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      'To urządzenie nie ma ekranu ustawień dla tego uprawnienia. Przyznaj je przez adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get deviceNotificationAccess => 'Dostęp do powiadomień';

  @override
  String get deviceNotificationAccessHeld =>
      'Ekran „Teraz odtwarzane” może śledzić aplikacje odtwarzające na tym urządzeniu.';

  @override
  String get deviceNotificationAccessMissing =>
      'Bez tego uprawnienia Android nie udostępnia żadnych sesji multimediów, więc ekran „Teraz odtwarzane” nie może śledzić aplikacji odtwarzających na tym urządzeniu.';

  @override
  String get deviceNotificationAccessIdle =>
      'Pozwala ekranowi „Teraz odtwarzane” śledzić aplikacje odtwarzające na tym urządzeniu.';

  @override
  String get settingRemoteEnabledTitle => 'Zdalne zarządzanie';

  @override
  String get settingRemoteEnabledDescription =>
      'Uruchom wbudowany serwer WWW zdalnej administracji.';

  @override
  String get settingRemotePortTitle => 'Port serwera';

  @override
  String get settingRemotePortDescription =>
      'Port interfejsu zdalnej administracji.';

  @override
  String get settingRemotePasswordTitle => 'Hasło administratora';

  @override
  String get settingRemotePasswordDescription =>
      'Wymagane do zalogowania się w interfejsie zdalnej administracji.';

  @override
  String get settingRemoteFleetDiscoveryTitle => 'Znajdź inne kioski';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      'Ogłaszaj to urządzenie w sieci i wyświetlaj inne kioski w zdalnej administracji, aby przełączać się między nimi.';

  @override
  String get settingRemoteAdminUrlTitle => 'Adres URL administracji';

  @override
  String get settingRemoteAdminUrlDescription =>
      'Adres, który inne kioski otwierają w oknie „Przełącz kiosk”, aby połączyć się z tym kioskiem, na przykład nazwa odwrotnego proxy. Zostaw puste, aby użyć jego adresu sieciowego.';

  @override
  String get deviceAdminUrlInvalid =>
      'Wpisz prawidłowy adres, na przykład https://kiosk.example.com';

  @override
  String get deviceAdminUrlPath =>
      'Wpisz sam adres, bez ścieżki. Przykład: https://kiosk.example.com';

  @override
  String get deviceRemotePage => 'Zdalna administracja';

  @override
  String get deviceAdminAddress => 'Adres administracyjny';

  @override
  String get deviceAdminAddressHelp =>
      'Otwórz ten adres w przeglądarce na komputerze.';

  @override
  String get deviceByName => 'Według nazwy';

  @override
  String get deviceByNameHelp =>
      'Ten sam adres w postaci nazwy hosta, w sieciach rozpoznających nazwy .local.';

  @override
  String get deviceByCertificateNameHelp =>
      'Ten sam adres w postaci nazwy z certyfikatu.';

  @override
  String get devicePasswordNeeded =>
      'Ustaw poniżej hasło administratora, aby uruchomić serwer.';

  @override
  String get deviceServerStopped => 'Serwer nie działa.';

  @override
  String devicePortError(String port, String error) {
    return 'Nie można nasłuchiwać na porcie $port: $error';
  }

  @override
  String get settingRemoteTlsTitle => 'Używaj HTTPS';

  @override
  String get settingRemoteTlsDescription =>
      'Szyfruj zdalną administrację, API i WebSocket. Przeglądarka może poprosić o zaakceptowanie certyfikatu urządzenia.';

  @override
  String get settingServiceCpuAwakeTitle =>
      'Nie usypiaj procesora przy wyłączonym ekranie';

  @override
  String get settingServiceCpuAwakeDescription =>
      'Utrzymuje blokadę wybudzenia, gdy ekran jest wyłączony, dzięki czemu połączenia i timery działają punktualnie. Zużywa baterię tabletu niepodłączonego do zasilania.';

  @override
  String get deviceServicePage => 'Usługa Kiosk Satellite';

  @override
  String get deviceKeepingRunning => 'Utrzymywanie działania';

  @override
  String get deviceService => 'Usługa';

  @override
  String get deviceStopped => 'Zatrzymana';

  @override
  String get deviceStoppedSentence => 'Zatrzymana.';

  @override
  String get deviceRunning => 'Działa';

  @override
  String get deviceRunningSentence => 'Działa.';

  @override
  String get deviceRunningBackground =>
      'Działa bez wyjątku dla usług pierwszoplanowych.';

  @override
  String get deviceServiceTypes => 'Typy usługi pierwszoplanowej';

  @override
  String get deviceServiceTypesHelp =>
      'Co usługa deklaruje systemowi Android dla funkcji, które podtrzymuje.';

  @override
  String get deviceNoneDeclared => 'Nie zadeklarowano żadnych.';

  @override
  String get deviceNone => 'brak';

  @override
  String get deviceCpuLock => 'Blokada wybudzenia procesora';

  @override
  String get deviceCpuOff => 'Wyłączona: ustawienie poniżej jest wyłączone.';

  @override
  String get deviceCpuHeld => 'Aktywna: ekran jest wyłączony.';

  @override
  String get deviceCpuReleased => 'Zwalniane, gdy ekran jest włączony.';

  @override
  String get deviceNotHeld => 'Nieaktywna.';

  @override
  String get deviceHeld => 'Aktywna';

  @override
  String get deviceReleased => 'Zwolnione';

  @override
  String get deviceWifiLock => 'Blokada Wi-Fi';

  @override
  String get deviceWifiHeld =>
      'Aktywna: radio nie przechodzi w tryb oszczędzania energii.';

  @override
  String get deviceWifiHelp =>
      'Nie pozwala radiu przejść w tryb oszczędzania energii po wyłączeniu ekranu.';

  @override
  String get deviceNotification => 'Powiadomienie';

  @override
  String get deviceNotificationHidden =>
      'Ukryte: powiadomienia aplikacji są wyłączone. Usługa i tak działa.';

  @override
  String get deviceNotificationShown =>
      'Widoczne w obszarze powiadomień, gdy usługa działa.';

  @override
  String get deviceHidden => 'Ukryte';

  @override
  String get deviceShown => 'Widoczne';

  @override
  String get deviceReasonHa => 'Połączenie z Home Assistant';

  @override
  String get deviceReasonHaHelp =>
      'Utrzymuje otwartą sesję pulpitu i jej połączenie WebSocket przy wyłączonym ekranie.';

  @override
  String get deviceReasonListening => 'Nasłuchiwanie w tle';

  @override
  String get deviceReasonListeningHelp =>
      'Utrzymuje działanie mechanizmu słowa wybudzającego i mikrofonu, gdy na wierzchu są inne aplikacje.';

  @override
  String get deviceReasonRtsp => 'Dźwięk z mikrofonu przez RTSP';

  @override
  String get deviceReasonRtspHelp =>
      'Utrzymuje dostępność strumienia z mikrofonu dla podłączonych klientów RTSP.';

  @override
  String get deviceReasonEspHome => 'Serwer ESPHome';

  @override
  String get deviceReasonEspHomeHelp =>
      'Utrzymuje serwer API ESPHome w gotowości do odpowiadania Home Assistant.';

  @override
  String get deviceReasonRemote => 'Zdalna administracja';

  @override
  String get deviceReasonRemoteHelp =>
      'Utrzymuje działanie serwera WWW administracji.';

  @override
  String get deviceReasonProtections => 'Zabezpieczenia kiosku';

  @override
  String get deviceReasonProtectionsHelp =>
      'Ponownie uruchamia kiosk, gdy zostanie zamknięty z listy ostatnich aplikacji lub ulegnie awarii.';

  @override
  String get deviceReasonBluetooth => 'Proxy Bluetooth';

  @override
  String get deviceReasonBluetoothHelp =>
      'Utrzymuje skanowanie Bluetooth, gdy aplikacja nie jest na ekranie.';

  @override
  String get deviceReasonLocation => 'Czujniki lokalizacji';

  @override
  String get deviceReasonLocationHelp =>
      'Zapewnia odbiór pozycji GPS przy wyłączonym ekranie lub gdy na wierzchu jest inna aplikacja.';

  @override
  String get deviceReasonPerson => 'Wykrywanie osób';

  @override
  String get deviceReasonPersonHelp =>
      'Odczytuje czujnik obecności osób w urządzeniu, gdy na wierzchu jest inna aplikacja.';

  @override
  String get deviceReasonCameraHelp =>
      'Utrzymuje dostęp do kamery po wyłączeniu ekranu, na potrzeby wykrywania ruchu i wykrywania twarzy.';

  @override
  String deviceServiceStopped(String error) {
    return 'Zatrzymana: $error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return 'Czas działania: $uptime.';
  }

  @override
  String get settingShizukuInstallUpdatesTitle =>
      'Instaluj aktualizacje przez Shizuku';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      'Instaluj aktualizacje Kiosk Satellite bez potwierdzania na urządzeniu. Shizuku musi być uruchomione i autoryzowane.';

  @override
  String get deviceShizukuAccess => 'Dostęp do Shizuku';

  @override
  String get deviceShizukuCheck => 'Sprawdzanie dostępności';

  @override
  String get deviceShizukuRoot => 'Połączono z dostępem root';

  @override
  String get deviceShizukuShell => 'Połączono z dostępem do powłoki';

  @override
  String get deviceShizukuGrant =>
      'Dotknij, aby przyznać dostęp. Zatwierdź prośbę na tym kiosku.';

  @override
  String get deviceShizukuGrantRemote =>
      'Przyznaj dostęp i zatwierdź prośbę na tym kiosku.';

  @override
  String get deviceShizukuDenied =>
      'Zezwól na dostęp dla Kiosk Satellite w aplikacji Shizuku.';

  @override
  String get deviceShizukuUnsupported =>
      'Wymagana jest aplikacja Shizuku w wersji 13 lub nowszej.';

  @override
  String get deviceShizukuStart => 'Uruchom Shizuku na tym urządzeniu.';

  @override
  String get deviceShizukuTest => 'Przetestuj połączenie';

  @override
  String get deviceShizukuTestHelp =>
      'Odczytaj tożsamość procesu bez wprowadzania zmian na urządzeniu.';

  @override
  String get deviceShizukuTestTitle => 'Test połączenia';

  @override
  String get deviceShizukuTestFailed =>
      'Nie udało się ukończyć testu połączenia z Shizuku.';

  @override
  String get deviceShizukuAlreadyGranted =>
      'Wszystkie uprawnienia są już przyznane.';

  @override
  String get deviceShizukuConfirmed =>
      'Android potwierdził żądane uprawnienia.';

  @override
  String get deviceShizukuResults => 'Wyniki uprawnień';

  @override
  String get deviceShizukuGrantAll => 'Przyznaj wszystkie uprawnienia';

  @override
  String get deviceShizukuGrantAllHelp =>
      'Przyznaj wszystkie uprawnienia używane przez KS, także dla funkcji, które są obecnie wyłączone.';

  @override
  String get deviceShizukuSetup => 'Skonfiguruj Shizuku';

  @override
  String get deviceShizukuSetupHelp =>
      'Przeczytaj instrukcje instalacji i uruchamiania.';

  @override
  String get deviceShizukuLifetime =>
      'Jeśli Shizuku uruchomiono przez ADB, po ponownym uruchomieniu urządzenia trzeba uruchomić Shizuku jeszcze raz. Dostęp do powłoki nie daje uprawnień roota.';

  @override
  String get deviceShizukuFailed => 'Żądanie Shizuku nie powiodło się';

  @override
  String get deviceShizukuApprove => 'Zatwierdź żądanie na kiosku.';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Pomyślnie wykonano polecenie przez Shizuku z dostępem $access.';
  }

  @override
  String get shizukuPermissionUnconfirmed =>
      'Android nie potwierdził tego uprawnienia. Sprawdź to w Menedżerze uprawnień na urządzeniu.';

  @override
  String get shizukuPermissionReadFailed =>
      'Nie udało się odczytać bieżących uprawnień. Spróbuj ponownie.';

  @override
  String get shizukuRestartTimedOut =>
      'Upłynął limit czasu polecenia ponownego uruchomienia';

  @override
  String get shizukuRestartRefused => 'Android odmówił ponownego uruchomienia';

  @override
  String get shizukuCommandTimedOut => 'Upłynął limit czasu polecenia';

  @override
  String get shizukuRequestRejected => 'Android odrzucił żądanie';

  @override
  String get deviceDisconnectedError => 'Urządzenie rozłączone';

  @override
  String get deviceResponseTimedOut =>
      'Upłynął limit czasu odpowiedzi urządzenia';

  @override
  String get deviceRequestAborted => 'Przerwano żądanie';

  @override
  String get shizukuActionBusy =>
      'Inna akcja Shizuku na urządzeniu jest już w toku';

  @override
  String get shizukuGrantFirst => 'Najpierw przyznaj dostęp do Shizuku';

  @override
  String get shizukuNoResponse => 'Brak odpowiedzi na polecenie Shizuku';

  @override
  String get shizukuCommandFailed => 'Polecenie Shizuku nie powiodło się';

  @override
  String get shizukuStartRequired =>
      'Uruchom Shizuku w wersji 13 lub nowszej i przyznaj w Shizuku dostęp aplikacji Kiosk Satellite';

  @override
  String get shizukuConnectionFailed => 'Nie udało się połączyć z Shizuku';

  @override
  String get shizukuHelperNotConnected =>
      'Proces pomocniczy Shizuku nie nawiązał połączenia';

  @override
  String get shizukuHelperUnavailable =>
      'Proces pomocniczy Shizuku jest niedostępny';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates =>
      'Szyfrowanie połączenia i certyfikaty';

  @override
  String get tlsCertificateType => 'Typ certyfikatu';

  @override
  String get tlsImported => 'Zaimportowany';

  @override
  String get tlsSelfSigned => 'Samopodpisany';

  @override
  String get tlsExpires => 'Wygasa';

  @override
  String get tlsSHA256Fingerprint => 'Odcisk SHA-256';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      'Certyfikat wygasł. Odnów go lub zaimportuj nowy.';

  @override
  String get tlsCopyPublicCertificate => 'Kopiuj certyfikat publiczny';

  @override
  String get tlsDownloadPublicCertificate => 'Pobierz certyfikat publiczny';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      'Użyj tego certyfikatu w przeglądarkach i klientach strumieniowania.';

  @override
  String get tlsRenewCertificate => 'Odnów certyfikat';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      'Zachowaj bieżący klucz prywatny i zaktualizuj daty certyfikatu.';

  @override
  String get tlsImportCertificate => 'Importuj certyfikat';

  @override
  String get tlsUseACertificateIssuedForThisDevice =>
      'Użyj certyfikatu wystawionego dla tego urządzenia.';

  @override
  String get tlsReplaceCertificate => 'Zastąp certyfikat';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      'Wygeneruj nowy klucz prywatny i certyfikat samopodpisany.';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      'Wygenerować nowy klucz prywatny i certyfikat? Aktywne szyfrowane połączenia zostaną zamknięte. Przeglądarki mogą poprosić o zaakceptowanie nowego certyfikatu.';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      'Wklej łańcuch certyfikatów PEM i odpowiadający mu niezaszyfrowany klucz prywatny. Zostaną sprawdzone przed zastąpieniem bieżącego certyfikatu.';

  @override
  String get tlsCertificateChainPEM => 'Łańcuch certyfikatów (PEM)';

  @override
  String get tlsPrivateKeyPEM => 'Klucz prywatny (PEM)';

  @override
  String get tlsThisFieldIsRequired => 'To pole jest wymagane.';

  @override
  String get tlsReplace => 'Zastąp';

  @override
  String get tlsRenew => 'Odnów';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      'Włącz HTTPS, zanim zdalnie zaimportujesz klucz prywatny.';

  @override
  String get tlsCertificateOperationFailed =>
      'Operacja na certyfikacie nie powiodła się.';

  @override
  String get tlsChangeConnectionProtocol => 'Zmień protokół połączenia';

  @override
  String get tlsConnectionProtocolHelp =>
      'Bieżące połączenie zdalne zostanie zamknięte. Połącz się ponownie, używając poniższego adresu. Może być konieczne ponowne zalogowanie.';

  @override
  String get tlsConfirm => 'Potwierdź';

  @override
  String get tlsCertificateManagement => 'Zarządzanie certyfikatami';

  @override
  String get tlsServerCertificateRequired =>
      'Użyj certyfikatu serwera, a nie certyfikatu CA.';

  @override
  String get tlsServerAuthenticationRequired =>
      'Certyfikat nie zezwala na uwierzytelnianie serwera.';

  @override
  String get tlsKeyAlgorithmRequired => 'Użyj klucza prywatnego EC lub RSA.';

  @override
  String get tlsKeyMismatch =>
      'Certyfikat i klucz prywatny nie pasują do siebie.';

  @override
  String get tlsMaterialTooLarge => 'Certyfikat lub klucz jest za duży.';

  @override
  String get tlsPemCertificatesRequired => 'Oczekiwano certyfikatów PEM.';

  @override
  String get tlsCertificateMissing => 'Nie znaleziono certyfikatu.';

  @override
  String get tlsUnencryptedKeyRequired =>
      'Użyj niezaszyfrowanego klucza prywatnego PEM.';

  @override
  String get tlsHostnameRequired => 'Wymagana jest nazwa hosta lub adres IP.';

  @override
  String get tlsIssuerRenewalRequired =>
      'Zaimportuj odnowiony certyfikat od jego wystawcy.';

  @override
  String get tlsStoredIdentityDamaged =>
      'Zapisana tożsamość TLS jest uszkodzona.';

  @override
  String get tlsExpiredCertificate =>
      'Certyfikat TLS wygasł. Odnów go lub zaimportuj certyfikat zastępczy.';

  @override
  String get deviceHelperPage => 'Opcjonalny pomocnik aktualizacji';

  @override
  String get deviceHelperStatus => 'Stan pomocnika';

  @override
  String get deviceHelperError =>
      'Nie udało się sprawdzić pomocnika aktualizacji.';

  @override
  String get deviceHelperUnneeded =>
      'Android może teraz instalować aktualizacje bez udziału użytkownika. Pomocnik nie jest potrzebny.';

  @override
  String get deviceHelperIntro =>
      'To urządzenie wymaga obecnie potwierdzenia na ekranie, aby zainstalować aktualizacje przez system Android. Opcjonalny pomocnik pozwala Kiosk Satellite instalować aktualizacje bez dotknięcia.';

  @override
  String get deviceHelperBusy => 'Instalowanie aktualizacji.';

  @override
  String get deviceHelperReady =>
      'Gotowy. Aktualizacje instalują się bez potwierdzenia.';

  @override
  String get deviceHelperUnavailable =>
      'Niedostępny. Uruchom pomocnika przez ADB, aby włączyć aktualizacje bez potwierdzenia.';

  @override
  String get deviceHelperLifetime =>
      'Pomocnik działa nadal po ponownym uruchomieniu i aktualizacji aplikacji, ale zatrzymuje się po ponownym uruchomieniu urządzenia. Uruchom polecenie z komputera z ADB, aby go ponownie włączyć. Komputer można potem odłączyć.';

  @override
  String get deviceHelperStart => 'Uruchom przez ADB';

  @override
  String get deviceHelperGuide => 'Przewodnik konfiguracji';

  @override
  String get deviceHelperGuideHelp =>
      'Przeczytaj instrukcje i wymagania pomocnika aktualizacji.';

  @override
  String get settingUpdateSourceTitle => 'Źródło aktualizacji';

  @override
  String get settingUpdateSourceDescription =>
      'Gdzie aplikacja szuka nowych uaktualnień.';

  @override
  String get settingUpdateSourceUrlTitle => 'Adres URL repozytorium';

  @override
  String get settingUpdateSourceUrlDescription =>
      'Folder na serwerze WWW dostępnym dla kiosku, zawierający plik releases.json i uaktualnione pliki APK.';

  @override
  String get deviceUpdatesPage => 'Aktualizacje';

  @override
  String get deviceUpdateGithub => 'Repozytorium GitHub';

  @override
  String get deviceUpdateCustom => 'Własne repozytorium';

  @override
  String get deviceUpdateGuide => 'Przewodnik po własnym repozytorium';

  @override
  String get deviceUpdateGuideHelp =>
      'Jak udostępnić plik z uaktualnieniami i pliki APK we własnej sieci.';

  @override
  String get deviceInstallFile => 'Zainstaluj z pliku';

  @override
  String get deviceInstallFileHelp =>
      'Prześlij plik APK Kiosk Satellite z komputera przez zdalną administrację, na tej samej stronie. Dla kiosku, który nie ma dostępu do serwisu GitHub ani własnego repozytorium.';

  @override
  String get deviceInstallFileRemoteHelp =>
      'Prześlij plik APK Kiosk Satellite z tego komputera i zainstaluj go. Dla kiosku, który nie ma dostępu do serwisu GitHub ani własnego repozytorium.';

  @override
  String get deviceUploadedApk => 'Przesłany plik APK';

  @override
  String get deviceInstalling => 'Instalowanie…';

  @override
  String get deviceDeviceNoAnswer => 'Urządzenie nie odpowiedziało.';

  @override
  String get deviceInstallFailed =>
      'Aktualizacja nie powiodła się. Sprawdź logi urządzenia.';

  @override
  String get deviceConfirmTablet => 'Potwierdź na ekranie tabletu';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return 'Wersja $version (kompilacja $build, $size MB) jest na urządzeniu i czeka na instalację.';
  }

  @override
  String deviceInstallVersion(String version) {
    return 'Zainstaluj wersję $version';
  }

  @override
  String deviceHttpError(String code) {
    return 'Urządzenie odpowiedziało kodem HTTP $code.';
  }

  @override
  String get deviceUploadFailed => 'Przesyłanie nie powiodło się.';

  @override
  String get deviceInstallFleet => 'Zainstaluj we flocie';

  @override
  String get deviceSendingFleet => 'Wysyłanie do floty…';

  @override
  String get deviceSameBuild => 'Na kiosku działa już ta kompilacja.';

  @override
  String get deviceInstallConfirmation =>
      'Instalację trzeba potwierdzić na ekranie tabletu, chyba że kiosk instaluje aktualizacje bez potwierdzenia.';

  @override
  String get deviceSelfLast =>
      'Ten kiosk zainstaluje aktualizację jako ostatni.';

  @override
  String get deviceUpdatingFleet => 'Aktualizowanie floty';

  @override
  String deviceUploading(String percent) {
    return 'Przesyłanie… $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return 'Przesłany plik APK to wersja $version (kompilacja $build, $size MB).';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'Na kiosku działa wersja $version (kompilacja $build).';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return 'Wysyłanie do kiosku „$name”… $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return 'Instalowanie na kiosku „$name”…';
  }

  @override
  String deviceInstallingNames(String names) {
    return 'Trwa instalacja: $names.';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      'Wpisz adres URL folderu, na przykład http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      'Wpisz tylko adres URL folderu, bez niczego po ścieżce. Przykład: http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy =>
      'Trwa pobieranie. Poczekaj na jego zakończenie.';

  @override
  String get updateInstallBusy =>
      'Trwa instalacja. Poczekaj na jej zakończenie.';

  @override
  String get updateNoAvailable => 'Brak dostępnej aktualizacji.';

  @override
  String get updateNoUploaded =>
      'Brak przesłanego pliku APK oczekującego na instalację.';

  @override
  String get updateUploadEmpty => 'Przesłany plik był pusty.';

  @override
  String get updateInvalidApk => 'Plik nie jest plikiem APK systemu Android.';

  @override
  String get updateUploadedGone =>
      'Przesłany plik APK zniknął. Prześlij go ponownie.';

  @override
  String get updateShizukuInstallerFailed =>
      'Nie udało się zainstalować aktualizacji przez Shizuku. Nie otwarto instalatora wymagającego potwierdzenia.';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return 'Za mało wolnego miejsca: plik APK ma $size MB, instalacja wymaga około $required MB, a wolne miejsce na urządzeniu to $free MB.';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return 'Przesyłanie zostało przerwane po $size MB: $error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return 'Przesyłanie zakończyło się przedwcześnie: odebrano $received z $expected MB.';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return 'Plik APK to $package, a nie Kiosk Satellite ($expected).';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'Plik APK to wersja $version (kompilacja $build), starsza niż uruchomiona $currentVersion (kompilacja $currentBuild). Instalacja starszej wersji jest odrzucana: Android też by jej nie zainstalował.';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return 'Pobieranie nie powiodło się (HTTP $status).';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return 'Pobieranie zatrzymało się: brak danych przez $seconds s.';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return 'Aktualizacja nie powiodła się: $error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return 'Instalacja nie powiodła się: $error';
  }

  @override
  String get updateAnotherPackage => 'inny pakiet';

  @override
  String get deviceKioskSatelliteUpdates => 'Aktualizacje Kiosk Satellite';

  @override
  String get deviceAndroidSystemUpdates => 'Aktualizacje systemu Android';

  @override
  String get settingAndroidUpdatePolicyTitle =>
      'Instalowanie aktualizacji systemu Android';

  @override
  String get settingAndroidUpdatePolicyDescription =>
      'Aktualizacje samego systemu Android od producenta urządzenia, np. Google lub Samsung. Tryb kiosku ukrywa prośbę o ponowne uruchomienie i ich zainstalowanie.';

  @override
  String get deviceAndroidUpdateAsk => 'Pytaj na urządzeniu';

  @override
  String get deviceAndroidUpdateAutomatic => 'Od razu';

  @override
  String get deviceAndroidUpdateWindowed => 'W oknie czasowym';

  @override
  String get settingAndroidUpdateWindowStartTitle => 'Instaluj od';

  @override
  String get settingAndroidUpdateWindowStartDescription =>
      'Godzina (czas lokalny) otwarcia codziennego okna instalacji i ponownego uruchomienia.';

  @override
  String get settingAndroidUpdateWindowEndTitle => 'Instaluj do';

  @override
  String get settingAndroidUpdateWindowEndDescription =>
      'Godzina (czas lokalny) zamknięcia okna. Okno obejmujące północ kończy się następnego dnia.';

  @override
  String get settingUiLanguageTitle => 'Język';

  @override
  String get settingUiLanguageDescription =>
      'Język aplikacji Kiosk Satellite i zdalnej administracji. Home Assistant zachowuje własny język.';

  @override
  String get settingUiThemeTitle => 'Motyw aplikacji';

  @override
  String get settingUiThemeDescription =>
      'Jasny lub ciemny motyw własnych ekranów aplikacji: menu, ustawień i okien dialogowych. „Systemowy” stosuje ustawienie z Androida.';

  @override
  String get settingUiScaleTitle => 'Skalowanie interfejsu';

  @override
  String get settingUiScaleDescription =>
      'Rozmiar własnych ekranów aplikacji: menu, ustawień i okien dialogowych. Dla ekranów o dużej gęstości pikseli. Treści internetowe zachowują swój rozmiar.';

  @override
  String get deviceUserInterface => 'Interfejs użytkownika';

  @override
  String get deviceThemeDark => 'Ciemny';

  @override
  String get deviceThemeLight => 'Jasny';

  @override
  String get deviceThemeSystem => 'Systemowy';

  @override
  String get settingUiToastsHiddenTitle =>
      'Pokazuj systemowe powiadomienia toast';

  @override
  String get settingUiToastsHiddenDescription =>
      'Wybierz wyskakujące komunikaty wyświetlane nad pulpitem. Komunikaty w ustawieniach są zawsze widoczne.';

  @override
  String get deviceToastsAll => 'Wszystkie';

  @override
  String get deviceToastsNone => 'Żadne';

  @override
  String get deviceToastBack => 'Wskazówki przycisku Wstecz';

  @override
  String get deviceToastGestures => 'Akcje gestów';

  @override
  String get deviceToastHoldMode => 'Tryb wstrzymania';

  @override
  String get deviceToastLinks => 'Linki na pulpicie';

  @override
  String get deviceToastDownloads => 'Pobieranie plików';

  @override
  String get deviceToastNetwork => 'Stan sieci';

  @override
  String get deviceToastUpdates => 'Sprawdzanie aktualizacji';

  @override
  String get deviceToastVoice => 'Komunikaty Voice Satellite';

  @override
  String get deviceToastTimers => 'Minutniki';

  @override
  String get deviceToastAlarms => 'Budziki';

  @override
  String get deviceToastMusicLibrary => 'Biblioteka muzyczna';

  @override
  String get deviceToastIntercom => 'Interkom';

  @override
  String get deviceToastAppLauncher => 'Launcher aplikacji';

  @override
  String get deviceToastPlugins => 'Akcje wtyczek';

  @override
  String get settingUiDrawerItemsTitle => 'Pozycje menu bocznego';

  @override
  String get settingUiDrawerItemsDescription =>
      'Wybierz pozycje wyświetlane w menu bocznym i ich kolejność.';

  @override
  String get settingShowInKioskMenuTitle => 'Pokazuj w menu kiosku';

  @override
  String get settingDlnaEnabledTitle => 'Włącz renderer DLNA';

  @override
  String get settingDlnaEnabledDescription =>
      'Wyświetlaj obrazy i odtwarzaj multimedia przesyłane z Home Assistant lub dowolnej aplikacji DLNA. Urządzenie pojawia się jako odtwarzacz multimediów o nazwie urządzenia.';

  @override
  String get settingDlnaAudioBackgroundTitle => 'Odtwarzaj dźwięk w tle';

  @override
  String get settingDlnaAudioBackgroundDescription =>
      'Przesłany dźwięk jest odtwarzany bez przejmowania ekranu.';

  @override
  String get settingDlnaPortTitle => 'Port serwera';

  @override
  String get settingDlnaPortDescription =>
      'Port, na którym działa renderer, wpisywany przy jego uruchomieniu. Zmień go, aby przenieść renderer, lub wyczyść, aby renderer ponownie wybrał port.';

  @override
  String get settingDlnaPortPlaceholder =>
      'Ustawiany przy uruchomieniu renderera';

  @override
  String get settingEsphomeRealMacTitle =>
      'Używaj prawdziwego adresu MAC Wi-Fi';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant łączy ten kiosk z tym samym urządzeniem, które jest już monitorowane przez integracje sieciowe. Zmiana tego ustawienia tworzy nowe urządzenie ESPHome w Home Assistant.';

  @override
  String get settingEsphomeMacOverrideTitle => 'Podmień adres MAC Wi-Fi';

  @override
  String get settingEsphomeMacOverrideDescription =>
      'Adresu MAC nie można ustalić, więc w tym polu możesz wpisać własny. Zmiana tego ustawienia tworzy nowe urządzenie ESPHome w Home Assistant.';

  @override
  String get esphomeAdvanced => 'Ustawienia zaawansowane';

  @override
  String get esphomeAdvancedHelp => 'Prawdziwy lub podmieniony adres MAC Wi-Fi';

  @override
  String get esphomeMacInvalid => 'Wpisz prawidłowy adres MAC.';

  @override
  String esphomeMacHardware(String mac) {
    return 'Zgłaszany adres: $mac.';
  }

  @override
  String esphomeMacManual(String mac) {
    return 'Zgłaszany adres: $mac, wpisany poniżej.';
  }

  @override
  String get esphomeMacUnavailable =>
      'Android nie udostępnia adresu sprzętowego tego urządzenia.';

  @override
  String get settingAnnouncementsEnabledTitle => 'Włącz ogłoszenia';

  @override
  String get settingAnnouncementsEnabledDescription =>
      'Odtwarzaj ogłoszenia wysyłane przez Home Assistant za pomocą akcji „announce”.';

  @override
  String get esphomeTtsSection => 'Zamiana tekstu na mowę';

  @override
  String get settingAnnouncementsTtsEngineTitle =>
      'Silnik zamiany tekstu na mowę';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'Encja zamiany tekstu na mowę w Home Assistant, która odczytuje ogłoszenia.';

  @override
  String get settingAnnouncementsTtsLanguageTitle => 'Język';

  @override
  String get settingAnnouncementsTtsLanguageDescription =>
      'Język, w którym odczytywane są ogłoszenia.';

  @override
  String get settingAnnouncementsTtsVoiceTitle => 'Głos';

  @override
  String get settingAnnouncementsTtsVoiceDescription =>
      'Głos, który odczytuje ogłoszenia.';

  @override
  String get esphomeTtsFirst => 'Pierwszy dostępny';

  @override
  String get esphomeTtsDefault => 'Domyślny';

  @override
  String get settingAnnouncementsChimeTitle => 'Najpierw sygnał';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Odtwarzaj sygnał przed ogłoszeniem.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Dźwięk sygnału';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Odtwarzany z tą samą głośnością co ogłoszenie.';

  @override
  String get esphomeAnnouncements => 'Ogłoszenia';

  @override
  String get esphomeAnnouncementsHelp => 'Ogłoszenia głosowe z Home Assistant';

  @override
  String get esphomeChime => 'Sygnał';

  @override
  String get esphomeTtsUnavailable => 'Nie udało się połączyć z Home Assistant';

  @override
  String get esphomeTtsNoVoices => 'Brak głosów do wyboru';

  @override
  String get settingBtproxyEnabledTitle => 'Włącz proxy Bluetooth';

  @override
  String get settingBtproxyEnabledDescription =>
      'Przekazuj dane z pobliskich urządzeń Bluetooth do Home Assistant.';

  @override
  String get settingBtproxyScanDutyTitle => 'Intensywność skanowania';

  @override
  String get settingBtproxyScanDutyDescription =>
      'Jaką część czasu radio nasłuchuje. Niższa wartość zmniejsza obciążenie procesora; urządzenia, które rzadko nadają, pojawiają się później.';

  @override
  String get settingBtproxyScreenOffScanTitle =>
      'Skanuj także przy wyłączonym ekranie';

  @override
  String get settingBtproxyScreenOffScanDescription =>
      'Włącz, jeśli proxy przestaje przekazywać dane przy wyłączonym ekranie. Zwiększa obciążenie procesora.';

  @override
  String get settingBtproxyDeviceMacTitle =>
      'Używaj adresu MAC urządzenia dla Bluetooth';

  @override
  String get settingBtproxyDeviceMacDescription =>
      'Pozwala integracjom takim jak Bermuda powiązać to proxy z jego urządzeniem. Zmienia adres proxy w Home Assistant.';

  @override
  String get settingBtproxyConnectionsTitle =>
      'Zezwalaj na połączenia z urządzeniami';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant może łączyć się z urządzeniami Bluetooth przez to proxy.';

  @override
  String get settingBtproxyMacLookupTitle =>
      'Wyszukuj producentów urządzeń online';

  @override
  String get settingBtproxyMacLookupDescription =>
      'Nazywa nieznane pobliskie urządzenia na podstawie prefiksu adresu sprzętowego, korzystając z api.macvendors.com. Wysyłany jest tylko 3-bajtowy prefiks producenta, raz dla każdego producenta; nic innego nie opuszcza urządzenia.';

  @override
  String get settingBtproxyNearbySortTitle => 'Sortuj według';

  @override
  String get settingBtproxyNearbySortDescription =>
      'Kolejność listy pobliskich urządzeń poniżej.';

  @override
  String get settingBtproxyMinConnectRssiTitle =>
      'Minimalny sygnał dla połączeń';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      'Odrzuca połączenia z urządzeniami słyszanymi słabiej niż ten próg, aby przejęło je bliższe proxy.';

  @override
  String get esphomeOptionContinuous => 'Ciągła';

  @override
  String get esphomeOptionBalanced => 'Zrównoważona';

  @override
  String get esphomeOptionLowPower => 'Niskie zużycie energii';

  @override
  String get esphomeOptionLastSeen => 'Ostatnio wykryte';

  @override
  String get esphomeOptionName => 'Nazwa';

  @override
  String get esphomeOptionMacAddress => 'Adres MAC';

  @override
  String get esphomeOptionSignalStrength => 'Siła sygnału';

  @override
  String get esphomeOptionNoLimit => 'Bez limitu';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm (ten sam pokój)';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm (granica zasięgu)';

  @override
  String get esphomeBluetooth => 'Proxy Bluetooth';

  @override
  String get esphomeBluetoothHelp =>
      'Przekazywanie danych z pobliskich urządzeń Bluetooth do Home Assistant';

  @override
  String get esphomeBluetoothOff =>
      'Bluetooth jest wyłączony. Włącz go, aby używać proxy.';

  @override
  String get esphomeBluetoothUnsupported =>
      'Niedostępne na tym urządzeniu: brak Bluetooth.';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      'Niedostępne na tym urządzeniu: jego kompilacja systemu Android nie obsługuje Bluetooth LE.';

  @override
  String get esphomeIdentityBthome => 'Czujnik BTHome';

  @override
  String get esphomeIdentityXiaomi => 'Czujnik Xiaomi';

  @override
  String get esphomeIdentityQingping => 'Czujnik Qingping';

  @override
  String get esphomeIdentityGoogleNest => 'Urządzenie Google/Nest';

  @override
  String get esphomeIdentityEddystone => 'Nadajnik Eddystone';

  @override
  String get esphomeIdentityGoogleFastPair => 'Urządzenie Google Fast Pair';

  @override
  String get esphomeIdentityAppleFindMy => 'Urządzenie Apple Find My';

  @override
  String get esphomeIdentityExposure => 'Exposure notification (na telefonie)';

  @override
  String get esphomeIdentityAugustYale => 'Zamek August/Yale';

  @override
  String get esphomeIdentityAmazon => 'Urządzenie Amazon';

  @override
  String get esphomeIdentityTile => 'Lokalizator Tile';

  @override
  String get esphomeIdentityInput => 'Urządzenie wejściowe (pilot/klawiatura)';

  @override
  String get esphomeIdentityHeartRate => 'Czujnik tętna';

  @override
  String get esphomeIdentityEnvironmental => 'Czujnik środowiskowy';

  @override
  String get esphomeIdentityApple => 'Urządzenie Apple';

  @override
  String get esphomeIdentityWindows => 'Komputer z Windows';

  @override
  String get esphomeIdentitySamsung => 'Urządzenie Samsung';

  @override
  String get esphomeIdentityGoogle => 'Urządzenie Google';

  @override
  String get esphomeIdentityUnknown => 'Nieznane urządzenie';

  @override
  String esphomeIdentityVendor(String vendor) {
    return 'Urządzenie $vendor';
  }

  @override
  String get esphomeNearby => 'Urządzenia w pobliżu';

  @override
  String get esphomeNearbySearch =>
      'Urządzenia Bluetooth odbierane przez ten kiosk, z nazwami, jeśli są znane.';

  @override
  String get esphomeNearbyEmpty => 'Jeszcze nic nie wykryto.';

  @override
  String get esphomeNearbyWaiting =>
      'Jeszcze nic nie wykryto. Urządzenia pojawią się tutaj, gdy proxy zacznie skanować.';

  @override
  String get esphomeRotating => '(zmienny adres)';

  @override
  String esphomeNearbyCount(String count, String total) {
    return 'Wyświetlane: $count z $total.';
  }

  @override
  String esphomeSlots(String count) {
    return 'Maksymalna liczba urządzeń połączonych jednocześnie przez to proxy: $count. Home Assistant kieruje kolejne urządzenia przez inne proxy.';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return '$count s temu';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return '$count min temu';
  }

  @override
  String esphomeHoursAgo(String count) {
    return '$count h temu';
  }

  @override
  String get settingLocationEnabledTitle => 'Udostępniaj lokalizację';

  @override
  String get settingLocationEnabledDescription =>
      'Odczytuje pozycję GPS i udostępnia ją w Home Assistant jako czujniki szerokości i długości geograficznej, dokładności, wysokości i prędkości. Włączenie lub wyłączenie tej opcji powoduje ponowną rejestrację urządzenia ESPHome.';

  @override
  String get settingLocationIntervalTitle => 'Interwał aktualizacji';

  @override
  String get settingLocationIntervalDescription =>
      'Liczba sekund między odczytami pozycji.';

  @override
  String get esphomeGps => 'Czujnik GPS';

  @override
  String get esphomeGpsHelp =>
      'Udostępnianie danych czujnika GPS w Home Assistant';

  @override
  String get esphomeLocationOff => 'Wyłączone.';

  @override
  String get esphomeLocationWaiting =>
      'Oczekiwanie na pierwsze ustalenie pozycji. Zimny start pod otwartym niebem może potrwać kilka minut.';

  @override
  String get esphomeCoordinates => 'Ostatnie współrzędne';

  @override
  String get esphomeLocationDenied =>
      'Nie przyznano uprawnienia do lokalizacji.';

  @override
  String get esphomeLocationAbsent => 'Brak odbiornika GPS.';

  @override
  String esphomeLocationError(String error) {
    return 'GPS niedostępny: $error';
  }

  @override
  String get esphomeLocationUnsupported =>
      'Niedostępne na tym urządzeniu: brak odbiornika GPS.';

  @override
  String get settingNotificationsTransparencyTitle => 'Przezroczystość';

  @override
  String get settingNotificationsTransparencyDescription =>
      'Ekran pod spodem prześwituje przez karty powiadomień. Tekst i ikony pozostają nieprzezroczyste.';

  @override
  String get settingNotificationsBlurTitle => 'Rozmycie tła';

  @override
  String get settingNotificationsBlurDescription =>
      'Rozmywa to, co prześwituje przez przezroczystą kartę powiadomienia. Uwaga: rozmycia nie można zastosować nad powierzchnią pulpitu Home Assistant.';

  @override
  String get settingNotificationsChimeFileTitle => 'Dźwięk powiadomienia';

  @override
  String get settingNotificationsChimeFileDescription =>
      'Pliki dźwiękowe są odczytywane z katalogu Android/data/me.jxl.kiosk_satellite/files/sounds na urządzeniu, dostępnego też z menedżera plików.';

  @override
  String get settingNotificationsVolumeTitle => 'Głośność powiadomień';

  @override
  String get settingNotificationsVolumeDescription =>
      'Głośność dźwięku powiadomienia, niezależna od głośności multimediów i asystenta.';

  @override
  String get esphomeNotifications => 'Powiadomienia';

  @override
  String get esphomeNotificationsHelp =>
      'Przezroczystość, rozmycie, dźwięk powiadomienia, powiadomienie testowe';

  @override
  String get esphomeAppearance => 'Wygląd';

  @override
  String get esphomeSound => 'Dźwięk';

  @override
  String get esphomeNotificationTest => 'Powiadomienie testowe';

  @override
  String esphomeNotificationHelp(String action) {
    return 'Powiadomienia są wysyłane z Home Assistant za pomocą akcji $action. Test wyświetla przykładowe powiadomienie nad pulpitem.';
  }

  @override
  String get esphomeNotificationBody =>
      'Tak wygląda i brzmi powiadomienie z Home Assistant.';

  @override
  String get esphomeNotificationSearch =>
      'Akcja Home Assistant wysyłająca powiadomienia oraz przycisk wyświetlający przykładowe powiadomienie.';

  @override
  String get esphomeLocation => 'Lokalizacja';

  @override
  String get esphomeLocationSearch =>
      'Uprawnienie „Lokalizacja” potrzebne czujnikom lokalizacji.';

  @override
  String get esphomeBluetoothSearch =>
      'Uprawnienie „Urządzenia w pobliżu” potrzebne proxy Bluetooth do skanowania.';

  @override
  String get esphomeLocationMissing =>
      'Bez tego uprawnienia nie można odczytać odbiornika GPS, a czujniki lokalizacji mają stan nieznany.';

  @override
  String get esphomeLocationServicesOff =>
      'Lokalizacja jest wyłączona w ustawieniach urządzenia, więc odbiornik nie dostarcza danych.';

  @override
  String get esphomeLocationApproximate =>
      'Dozwolona jest tylko przybliżona lokalizacja, a odbiornik GPS wymaga dokładnej lokalizacji.';

  @override
  String get esphomeLocationGranted =>
      'Czujniki lokalizacji mogą odczytywać odbiornik GPS.';

  @override
  String get esphomeBluetoothGranted =>
      'Proxy może wyszukiwać urządzenia Bluetooth w pobliżu.';

  @override
  String get esphomeBluetoothMissing =>
      'Bez tego uprawnienia proxy nie może wyszukiwać urządzeń.';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android dostarcza wyniki skanowania Bluetooth, w tym beacony, tylko po przyznaniu uprawnienia „Lokalizacja”. Proxy nigdy nie odczytuje położenia urządzenia.';

  @override
  String get esphomeBluetoothLocationOff =>
      'Lokalizacja jest wyłączona w ustawieniach urządzenia, więc skanowanie Bluetooth niczego nie znajduje.';

  @override
  String get esphomeBluetoothBeacons =>
      'Skanowanie Bluetooth może wykrywać beacony.';

  @override
  String get esphomeSent => 'Wysłano';

  @override
  String get esphomeNotsaved => 'Nie zapisano';

  @override
  String get settingEsphomeEnabledTitle => 'Włącz ESPHome';

  @override
  String get settingEsphomeEnabledDescription =>
      'Udostępnia ten kiosk w Home Assistant jako urządzenie ESPHome: jego czujniki i elementy sterujące jako natywne encje. Wykrywany automatycznie.';

  @override
  String get settingEsphomeEntitiesTitle => 'Udostępniaj encje kiosku';

  @override
  String get settingEsphomeEntitiesDescription =>
      'Udostępnia czujniki i elementy sterujące tego urządzenia jako encje ESPHome.';

  @override
  String get settingEsphomeExcludedEntitiesTitle => 'Wykluczone encje';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      'Wybierz encje do wykluczenia z Home Assistant. Wszystkie pozostałe dostępne encje są udostępniane. Zapisanie powoduje ponowne połączenie ESPHome.';

  @override
  String get settingEsphomeNodeNameTitle => 'Nazwa węzła';

  @override
  String get settingEsphomeNodeNameDescription =>
      'Nazwa tego kiosku w sieci, z której Home Assistant tworzy nazwy akcji. Zmiana tej nazwy zmienia też nazwy akcji.';

  @override
  String get settingEsphomeNodeNamePlaceholder =>
      'Ustawiana przy pierwszym uruchomieniu';

  @override
  String get settingBtproxyKeyTitle => 'Klucz szyfrowania';

  @override
  String get settingBtproxyKeyDescription =>
      'Wklej ten klucz w Home Assistant, gdy pojawi się prośba o klucz szyfrowania. Generowany automatycznie przy pierwszym uruchomieniu.';

  @override
  String get settingBtproxyKeyPlaceholder =>
      'Generowany przy pierwszym uruchomieniu';

  @override
  String get settingBtproxyPortTitle => 'Port API';

  @override
  String get settingBtproxyPortDescription =>
      'Port, z którym łączy się Home Assistant. Pozostaw pole puste, aby użyć standardowego portu ESPHome: 6053.';

  @override
  String esphomeStartFailed(String error) {
    return 'Nie udało się uruchomić serwera ESPHome: $error';
  }

  @override
  String get esphomeExcludedInvalid => 'Wybierz listę identyfikatorów encji.';

  @override
  String settingsMadeBy(String heart, String author) {
    return 'Stworzone z $heart przez $author';
  }

  @override
  String get settingsBuyCoffee => 'Postaw mi kawę';

  @override
  String get settingClapStrictnessTitle => 'Wykrywanie klaśnięć';

  @override
  String get settingClapDetectionDescription =>
      'Opcja „Ścisłe” wymaga głośniejszych klaśnięć w równych odstępach. Opcja „Duże pomieszczenie” daje klaśnięciom czas na wybrzmienie w pomieszczeniu z pogłosem.';

  @override
  String get gestureStrictnessStandard => 'Standardowe';

  @override
  String get gestureStrictnessStrict => 'Ścisłe';

  @override
  String get gestureStrictnessLargeRoom => 'Duże pomieszczenie';

  @override
  String get gestureOff => 'Gesty są wyłączone';

  @override
  String get gestureOffHelp =>
      'W ustawieniach trybu kiosku włączono opcję „Wyłącz gesty”.';

  @override
  String get gestureEmpty => 'Brak skonfigurowanych gestów';

  @override
  String get gestureEmptyHelp =>
      'Gest wyzwala swoją akcję bez żadnego widocznego elementu sterującego.';

  @override
  String get gestureDeleteTooltip => 'Usuń gest';

  @override
  String get gestureDeleteTitle => 'Usunąć gest?';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return 'Usunąć ten gest? Wyzwalacz: $trigger. Akcja: $action.';
  }

  @override
  String get gestureAdd => 'Dodaj gest';

  @override
  String get gestureAddHelp => 'Wybierz gest i akcję, którą ma wyzwalać.';

  @override
  String get gestureTouchHelp =>
      'Gesty są wykrywane, a nie blokowane: dotknięcia docierają również do pulpitu nawigacyjnego, więc gesty w narożnikach ekranu oraz gesty wielopalcowe zapobiegają przypadkowemu uruchomieniu czegoś na pulpicie.';

  @override
  String get gestureClapper => 'Klaskacz';

  @override
  String get gestureReadFailed => 'Nie udało się odczytać ustawień.';

  @override
  String get gestureHandGestures => 'Gesty dłonią';

  @override
  String get settingHandGestureHoldSecondsTitle => 'Czas przytrzymania';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      'Przytrzymaj ten sam gest palców przez ten czas, aby uruchomić jego akcję. Zwiększ tę wartość, aby ograniczyć przypadkowe uruchomienia.';

  @override
  String get gestureHoldInstant => 'Natychmiast';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get gestureGroundControlVisionMatch => 'Ground Control Vision Match';

  @override
  String get settingGesturesFaceWhoTitle => 'Gesty palcami dla';

  @override
  String get settingGesturesFaceWhoDescription =>
      'Przy opcji Wybrane osoby gesty Pokaż palce działają tylko wtedy, gdy przy kiosku rozpoznana jest jedna z osób wybranych poniżej.';

  @override
  String get gesturesFaceWhoOptionAnyone => 'Każdy';

  @override
  String get gesturesFaceWhoOptionPeople => 'Wybrane osoby';

  @override
  String get settingGesturesFacePeopleTitle => 'Osoby';

  @override
  String get settingGesturesFacePeopleDescription =>
      'Wybierz, kto może używać gestów palcami. Jeśli nikt nie jest wybrany, może to zrobić każda rozpoznana osoba.';

  @override
  String get settingGroundControlEnabledTitle => 'Włącz Ground Control';

  @override
  String get settingGroundControlEnabledDescriptionVisionMatch =>
      'Połącz z Kiosk Satellite Ground Control, aby uruchamiać Voice Match i Vision Match na wydajnym komputerze.';

  @override
  String get settingGroundControlAddressTitle => 'Adres';

  @override
  String get settingGroundControlAddressDescription =>
      'Pozostaw puste, aby wyszukać Ground Control w sieci. Wpisz adres, jeśli Ground Control działa w innej sieci.';

  @override
  String get groundControlLooking => 'Wyszukiwanie Ground Control w sieci.';

  @override
  String get groundControlWaitingApproval => 'Oczekiwanie na zatwierdzenie';

  @override
  String get groundControlApproveHint =>
      'Zatwierdź ten kiosk na stronie „Kiosks” w aplikacji Ground Control.';

  @override
  String get groundControlDeclined => 'Odrzucono';

  @override
  String get groundControlDeclinedHint =>
      'Ten kiosk został odrzucony w aplikacji Ground Control. Zatwierdź go na stronie „Kiosks”.';

  @override
  String get groundControlNotAccepted => 'Nie zaakceptowano';

  @override
  String get groundControlUnsignedBuild =>
      'Ta kompilacja Kiosk Satellite nie może połączyć się z Ground Control.';

  @override
  String get groundControlApp => 'Aplikacja Ground Control';

  @override
  String get groundControlArchitecture => 'Architektura';

  @override
  String get groundControlRunsOn => 'Działa na';

  @override
  String get groundControlFeatures => 'Funkcje';

  @override
  String get settingGroundControlVoiceMatchTitle => 'Voice Match';

  @override
  String get settingVisionMatchEnabledTitle => 'Vision Match';

  @override
  String get settingVisionMatchEnableTitle => 'Włącz Vision Match';

  @override
  String get settingVisionMatchFaceDetectionTitle => 'Włącz wykrywanie twarzy';

  @override
  String get settingVisionMatchHandGesturesTitle => 'Włącz gesty dłonią';

  @override
  String get visionMatchFeaturesHint =>
      'Rozpoznawanie i wykrywanie twarzy, gesty dłonią i wykrywanie obecności';

  @override
  String get settingVisionMatchEnabledDescriptionGroundControl =>
      'Wykrywanie twarzy, gesty dłonią i rozpoznawanie twarzy. Wymaga Ground Control.';

  @override
  String get settingVisionMatchFaceDetectionDescriptionGroundControl =>
      'Uruchamiaj wykrywanie twarzy na Ground Control. Wyłącz, aby uruchamiać na urządzeniu.';

  @override
  String get settingVisionMatchHandGesturesDescriptionGroundControl =>
      'Uruchamiaj wykrywanie gestów dłoni i palców na Ground Control. Wyłącz, aby uruchamiać na urządzeniu.';

  @override
  String get settingVisionMatchFaceRecognitionTitle =>
      'Włącz rozpoznawanie twarzy';

  @override
  String get settingVisionMatchFaceRecognitionDescriptionGroundControl =>
      'Rozpoznaje, kto patrzy na kiosk, i pokazuje to w czujniku Face. Wymaga wykrywania twarzy na Ground Control.';

  @override
  String get groundControlFaceRecognition => 'Rozpoznawanie twarzy';

  @override
  String get faceEnrollRowTitle => 'Zarejestruj twarz';

  @override
  String get faceEnrollRowDescription =>
      'Wybierz osobę i wykonaj kroki na ekranie. Trwa to około pół minuty.';

  @override
  String get faceEnrollPickTitle => 'Czyja twarz?';

  @override
  String get faceEnrollNewPerson => 'Nowa osoba';

  @override
  String get faceEnrollEnrolled => 'Twarz zarejestrowana';

  @override
  String get faceEnrollNameLabel => 'Imię';

  @override
  String get faceEnrollStart => 'Rozpocznij';

  @override
  String get settingVisionMatchFaceConfirmsVoiceTitle =>
      'Potwierdzaj głosy twarzami';

  @override
  String get settingVisionMatchFaceConfirmsVoiceDescription =>
      'Przyjmuj podobny głos, gdy przed kioskiem rozpoznano twarz tej samej osoby. W ten sposób można dopasować tylko osobę z najbardziej podobnym odciskiem głosu.';

  @override
  String get groundControlUsedElsewhere => 'Używane w innych ustawieniach';

  @override
  String get settingVisionMatchLinkFaceWhoDescription =>
      'Wygaszacz ekranu > Wykrywanie twarzy > Ground Control Vision Match';

  @override
  String get groundControlValueOn => 'Włączone';

  @override
  String get groundControlValueOff => 'Wyłączone';

  @override
  String groundControlValuePeople(String option, String names) {
    return '$option: $names';
  }

  @override
  String get groundControlTagHint =>
      'Ustawienie Ground Control. Więcej informacji';

  @override
  String get groundControlTagTitle => 'Ustawienie Ground Control';

  @override
  String get groundControlTagVision =>
      'To ustawienie wymaga Kiosk Satellite Ground Control. Ground Control to osobna aplikacja działająca na komputerze w Twoim domu. Ustawienie korzysta z rozpoznawania twarzy i jest widoczne tylko wtedy, gdy rozpoznawanie twarzy jest włączone w Ustawienia > Ground Control > Vision Match.';

  @override
  String get groundControlTagVoice =>
      'To ustawienie wymaga Kiosk Satellite Ground Control. Ground Control to osobna aplikacja działająca na komputerze w Twoim domu. Ustawienie korzysta z Voice Match i jest widoczne tylko wtedy, gdy Voice Match jest włączony w Ustawienia > Ground Control > Voice Match.';

  @override
  String get settingVisionMatchLinkKioskPinDescription =>
      'Tryb kiosku > Ground Control Vision Match';

  @override
  String get settingVisionMatchLinkLockdownDescription =>
      'Tryb blokady > Ground Control Vision Match';

  @override
  String get groundControlRecognitionCards => 'Karty rozpoznawania';

  @override
  String get settingVisionMatchShowArrivalsTitle => 'Pokazuj przybycia';

  @override
  String get settingVisionMatchShowArrivalsDescription =>
      'Pokazuje kartę ze zdjęciem i imieniem osoby, gdy zostanie rozpoznana przed kioskiem. Dla tej samej osoby pojawia się ponownie dopiero, gdy nie było jej przez minutę.';

  @override
  String get settingVisionMatchShowActionsTitle => 'Pokazuj działania twarzą';

  @override
  String get settingVisionMatchShowActionsDescription =>
      'Pokazuje małą kartę za każdym razem, gdy PIN zostanie pominięty, tryb blokady wyłączony lub głos potwierdzony, ponieważ rozpoznano twarz.';

  @override
  String get settingVisionMatchCardPositionTitle => 'Pozycja kart';

  @override
  String get settingVisionMatchCardPositionDescription =>
      'Róg ekranu, w którym pojawiają się obie karty. Gdy widoczny jest podgląd z kamery, pojawiają się obok niego.';

  @override
  String get recognitionCardPinSkipped => 'PIN pominięty';

  @override
  String get recognitionCardLockdownOff => 'Tryb blokady wyłączony';

  @override
  String get recognitionCardVoiceConfirmed => 'Głos potwierdzony';

  @override
  String get settingVisionMatchPresenceSensorsTitle => 'Czujniki obecności';

  @override
  String get settingVisionMatchPresenceSensorsDescription =>
      'Dodaje do Home Assistant czujniki Presence i Looking at the kiosk. Kamera pozostaje włączona, a twarze są wyszukiwane przy każdym ruchu, nawet przy wyłączonym ekranie.';

  @override
  String get settingVisionMatchLinkGestureWhoDescription =>
      'Gesty > Ground Control Vision Match';

  @override
  String get settingVisionMatchLinkCalendarFocusDescription =>
      'Kalendarz > Ground Control Vision Match';

  @override
  String get haCustomPages => 'Własne strony';

  @override
  String get haCustomPagesHintDashboard =>
      'Twoje własne strony HTML wyświetlane jako pulpit';

  @override
  String get settingHaCustomPagesSocketTitle =>
      'Udostępnij połączenie z Home Assistant';

  @override
  String get settingHaCustomPagesSocketDescription =>
      'Własne strony komunikują się z Home Assistant przez połączenie kiosku, bez tokenu zapisanego na stronie.';

  @override
  String get haCustomPagesAdd => 'Dodaj stronę';

  @override
  String get haCustomPagesEmptyAnyServer =>
      'Dodaj strony HTML z folderu www Home Assistant lub z innego serwera, aby wybierać je jak pulpit.';

  @override
  String get haCustomPagesGuide => 'Przewodnik po własnych stronach';

  @override
  String get haCustomPagesGuideHint =>
      'Jak utworzyć stronę, która komunikuje się z Home Assistant.';

  @override
  String get haCustomPageAddTitle => 'Dodaj własną stronę';

  @override
  String get haCustomPageEditTitle => 'Edytuj własną stronę';

  @override
  String get haCustomPageName => 'Nazwa';

  @override
  String get haCustomPageLocation => 'Ścieżka lub adres URL';

  @override
  String get haCustomPageLocationHint =>
      'Plik w folderze www Home Assistant, np. /local/dashboard.html, lub adres URL strony na innym serwerze.';

  @override
  String get haCustomPageNameMissing => 'Wpisz nazwę.';

  @override
  String get haCustomPageLocationInvalid =>
      'Wpisz ścieżkę w /local/ albo adres URL http lub https.';

  @override
  String get haCustomPageDuplicate =>
      'Ta ścieżka jest już używana przez inną stronę.';

  @override
  String get haCustomPageNotFound =>
      'W Home Assistant nie ma pliku pod tą ścieżką.';

  @override
  String get haCustomPageUrlNotFound =>
      'Na serwerze nie ma strony pod tym adresem URL.';

  @override
  String get haCustomPageUnreachable =>
      'Nie udało się połączyć z Home Assistant.';

  @override
  String get haCustomPageUrlUnreachable => 'Nie udało się połączyć z serwerem.';

  @override
  String haCustomPageStatus(String code) {
    return 'Odpowiedź Home Assistant: HTTP $code.';
  }

  @override
  String haCustomPageUrlStatus(String code) {
    return 'Odpowiedź serwera: HTTP $code.';
  }

  @override
  String get settingHaHoldModeTitle => 'Tryb wstrzymania';

  @override
  String get settingHaHoldModeDescription =>
      'Zachowuje bieżący widok na ekranie: wygaszacz ekranu, rotacja widoków pulpitu i timer powrotu do widoku głównego są wstrzymane do wyłączenia trybu.';

  @override
  String get settingHaHoldReleaseMinutesTitle =>
      'Automatycznie kończ wstrzymanie po';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      'Samoczynnie wyłącza tryb wstrzymania po ustawionym czasie. Ustaw 0, aby wstrzymanie trwało do ręcznego wyłączenia.';

  @override
  String get haHoldHint =>
      'Przypięcie bieżącego widoku, automatyczne zakończenie, pozycja w menu';

  @override
  String get haNever => 'Nigdy';

  @override
  String haMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String haHours(String hours) {
    return '$hours h';
  }

  @override
  String haHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get settingDisableSuspendTitle => 'Utrzymuj połączenie w tle';

  @override
  String get settingDisableSuspendDescription =>
      'Wyłącza ustawienie „Wstrzymaj połączenia w tle” w Home Assistant, które w przeciwnym razie zrywa połączenie kilka minut po wyłączeniu ekranu.';

  @override
  String get settingFreezeOnScreensaverTitle =>
      'Wstrzymaj pulpit podczas wygaszacza ekranu';

  @override
  String get settingFreezeOnScreensaverDescription =>
      'Przestaje rysować pulpit, gdy zasłania go wygaszacz ekranu, co zmniejsza obciążenie CPU i GPU; połączenie pozostaje aktywne. Nie działa z wygaszaczem „Przygaszenie”.';

  @override
  String get settingWsFilterTitle => 'Filtruj aktualizacje pulpitu';

  @override
  String get settingWsFilterDescription =>
      'Przetwarzaj tylko aktualizacje encji z bieżącego widoku, co ogranicza przycinanie na słabszych tabletach. Widoki, których encji nie da się ustalić, pozostają niefiltrowane.';

  @override
  String get settingPauseDashboardCamerasTitle =>
      'Wstrzymaj strumienie kamer na pulpicie HA podczas wygaszacza ekranu';

  @override
  String get settingPauseDashboardCamerasDescription =>
      'Wstrzymuje obsługiwane wyciszone strumienie kamer na pulpicie Home Assistant, gdy zasłania go wygaszacz ekranu. Strumienie łączą się ponownie po jego zamknięciu. Nie dotyczy kamery urządzenia ani funkcji „Obraz z kamer”.';

  @override
  String get haOptimizations => 'Optymalizacje';

  @override
  String get haOptimizationsHint =>
      'Połączenie w tle, wstrzymanie pulpitu i kamer, filtr aktualizacji';

  @override
  String get haScanUnavailable =>
      'Szczegóły skanowania są niedostępne dla bieżącego widoku.';

  @override
  String get haScanDetails => 'Szczegóły skanowania pulpitu';

  @override
  String haWatchedTitle(String count) {
    return 'Obserwowane encje ($count)';
  }

  @override
  String get haWatched => 'Obserwowane encje';

  @override
  String get haEntityListUnavailable => 'Lista encji jest teraz niedostępna.';

  @override
  String haWatching(String count) {
    return 'Obserwowane encje w tym widoku: $count.';
  }

  @override
  String get haNoUpdates => 'Brak aktualizacji w ostatniej minucie.';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return 'Odfiltrowane aktualizacje w ostatniej minucie: $percent% ($dropped z $total).';
  }

  @override
  String get haRawUpdates =>
      'Jakiś element tej strony i tak odbiera wszystkie aktualizacje encji, więc filtrowanie daje tu mniej.';

  @override
  String get haAllStates =>
      'Ten widok odczytuje stany wszystkich encji, więc jego aktualizacje nie są filtrowane.';

  @override
  String get haUnknownEntities =>
      'Nie można ustalić encji tego widoku, więc jego aktualizacje nie są filtrowane.';

  @override
  String get haWaiting => 'Oczekiwanie na wczytanie pulpitu…';

  @override
  String get haShowScan => 'Pokaż szczegóły skanowania.';

  @override
  String haThreshold(String count) {
    return 'Liczba encji w tym widoku ($count) przekracza próg filtrowania. Filtrowanie jest wyłączone.';
  }

  @override
  String get haCustomPageFilter => 'Nie dotyczy własnych stron.';

  @override
  String get settingHaReturnHomeEnabledTitle =>
      'Powrót do widoku głównego pulpitu';

  @override
  String get settingHaReturnHomeEnabledDescription =>
      'Po okresie bezczynności wraca do pulpitu skonfigurowanego powyżej.';

  @override
  String get settingHaReturnHomeSecondsTitle => 'Powrót po (s)';

  @override
  String get settingHaReturnHomeSecondsDescription =>
      'Czas bezczynności, po którym kiosk wraca.';

  @override
  String get haReturnHint =>
      'Powrót do widoku głównego po okresie bezczynności';

  @override
  String get haReturnDisabled =>
      'Wyłączone, gdy włączona jest rotacja widoków pulpitu.';

  @override
  String get haReturnNoPath =>
      'Skonfigurowany pulpit nie ma ścieżki widoku, do której można wrócić.';

  @override
  String haReturnPath(String path) {
    return 'Po upływie limitu czasu następuje powrót do „$path”.';
  }

  @override
  String get haReturnCompass =>
      'W nawigacji Compass każdy widok pulpitu w układzie po upływie limitu czasu wraca do wybranego dla niego widoku.';

  @override
  String get settingHaRotationEnabledTitle => 'Włącz rotację widoków pulpitu';

  @override
  String get settingHaRotationEnabledDescription =>
      'Wybrane widoki pulpitu są wyświetlane po kolei w nieskończonej pętli, każdy przez wybraną liczbę sekund.';

  @override
  String get settingHaRotationSecondsTitle => 'Czas wyświetlania widoku (s)';

  @override
  String get settingHaRotationSecondsDescription =>
      'Jak długo każdy widok pozostaje na ekranie.';

  @override
  String get settingHaRotationPauseSecondsTitle =>
      'Wstrzymanie rotacji przy interakcji (s)';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      'Dotknięcie ekranu wstrzymuje rotację na ten czas, a każde kolejne dotknięcie odlicza go od nowa. Interakcje głosowe wstrzymują rotację do ich zakończenia. 0 oznacza rotację mimo dotknięć.';

  @override
  String get settingHaRotationCrossfadeTitle =>
      'Płynne przejścia między widokami';

  @override
  String get settingHaRotationCrossfadeDescription =>
      'Zamiast natychmiastowego przełączenia widok wygasa do tła, a następnie pojawia się kolejny. Przejście na inny pulpit lub stronę zewnętrzną nadal następuje natychmiast.';

  @override
  String get settingHaRotationFadeSecondsTitle => 'Czas przejścia (s)';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      'Łączny czas wygaszania i pojawiania się. Wczytywanie następnego widoku może go wydłużyć, zwłaszcza przy pierwszym wyświetleniu.';

  @override
  String get haRotation => 'Rotacja widoków pulpitu';

  @override
  String get haRotationHint =>
      'Przełączanie widoków, czas wyświetlania, przejście';

  @override
  String get haExternalPages => 'Strony zewnętrzne';

  @override
  String get haFadeError => 'Wybierz czas przejścia od 0,2 do 5 s.';

  @override
  String get haPauseRemoteHelp =>
      'Dotknięcie wstrzymuje rotację na ten czas; każde kolejne dotknięcie odlicza go od nowa. Interakcje głosowe zawsze wstrzymują rotację do ich zakończenia. 0 oznacza ciągłą rotację.';

  @override
  String get settingHaUrlTitle => 'Bazowy adres URL Home Assistant';

  @override
  String get settingHaUrlDescription =>
      'np. https://homeassistant.local:8123, bez ścieżki pulpitu.';

  @override
  String get settingHaTokenTitle => 'Długotrwały token dostępu';

  @override
  String get settingHaTokenDescription =>
      'Tworzony w Twoim „profilu HA” → „Bezpieczeństwo”.';

  @override
  String get settingHaAutoLoginTitle => 'Loguj automatycznie';

  @override
  String get settingHaAutoLoginDescription =>
      'Loguj do pulpitu za pomocą powyższego tokenu dostępu zamiast wyświetlać stronę logowania Home Assistant.';

  @override
  String get haValidate => 'Sprawdź';

  @override
  String get haValidateConnection => 'Sprawdź połączenie';

  @override
  String get haChecking => 'Sprawdzanie…';

  @override
  String get haConnected => 'Połączono';

  @override
  String get haConnectedRemote => 'Połączono.';

  @override
  String get haNotValidated =>
      'Jeszcze nie sprawdzono. Ustawienia poniżej zostaną odblokowane po pomyślnym sprawdzeniu połączenia.';

  @override
  String get haConnectFailed => 'Nie udało się połączyć.';

  @override
  String get haNotConfigured =>
      'Nie skonfigurowano adresu URL ani tokenu Home Assistant';

  @override
  String get haInvalidToken => 'nieprawidłowy token';

  @override
  String haUnreachable(String error) {
    return 'Nie udało się połączyć z Home Assistant: $error';
  }

  @override
  String get haProxy => 'Proxy bezpiecznego kontekstu';

  @override
  String get haProxyHelp =>
      'Home Assistant działający przez zwykłe http zostaje przekierowany przez proxy w aplikacji, dzięki czemu przeglądarka odblokowuje mikrofon i inne funkcje dostępne tylko przez https. Tylko dla adresów http.';

  @override
  String get haProxyRemoteHelp =>
      'Home Assistant działający przez zwykłe http zostaje przekierowany przez proxy wewnątrz aplikacji, dzięki czemu przeglądarka odblokowuje mikrofon i inne funkcje dostępne tylko przez https. Dostępne tylko dla adresów URL http.';

  @override
  String get haProxyNotice =>
      'Ten adres URL Home Assistant używa zwykłego http, a przeglądarki blokują mikrofon i inne funkcje na stronach http. Kiosk Satellite przekieruje pulpit przez bezpieczne proxy wewnątrz aplikacji, aby wszystko działało. Może być konieczne ponowne zalogowanie się do Home Assistant.';

  @override
  String get haProxyRemoteNotice =>
      'Ten adres URL Home Assistant używa zwykłego http, a przeglądarki blokują mikrofon i inne funkcje na stronach http. Kiosk Satellite przekieruje pulpit przez bezpieczne proxy wewnątrz aplikacji, aby wszystko działało. Może być konieczne ponowne zalogowanie się do Home Assistant na tablecie.';

  @override
  String get haDashboard => 'Pulpit';

  @override
  String get haChooseView => 'Wybierz widok';

  @override
  String get settingHaThemeTitle => 'Motyw';

  @override
  String get settingHaThemeDescription =>
      'Jasny lub ciemny motyw pulpitu Home Assistant, ustawiany też przez encję motywu w Home Assistant. Opcja „Automatyczny” działa według ustawień poniżej.';

  @override
  String get settingThemeMatchAppTitle =>
      'Synchronizuj motywy Home Assistant z Kiosk Satellite';

  @override
  String get settingThemeMatchAppDescription =>
      'Automatycznie dopasowuj motyw Home Assistant do interfejsu Kiosk Satellite.';

  @override
  String get settingThemeAutoTitle => 'Dopasuj motyw do pory dnia';

  @override
  String get settingThemeAutoDescription =>
      'Przełączaj Home Assistant między trybem jasnym a ciemnym według harmonogramu. Wybrany motyw pozostaje bez zmian, zmienia się tylko jego wariant jasny/ciemny.';

  @override
  String get settingThemeDarkAtTitle => 'Ciemny motyw o';

  @override
  String get settingThemeDarkAtDescription =>
      'Czas lokalny przełączenia na ciemny motyw.';

  @override
  String get settingThemeLightAtTitle => 'Jasny motyw o';

  @override
  String get settingThemeLightAtDescription =>
      'Czas lokalny powrotu do jasnego motywu.';

  @override
  String get settingThemeAutoAppTitle => 'Przełączaj też motyw aplikacji';

  @override
  String get settingThemeAutoAppDescription =>
      'Zmieniaj motyw samego Kiosk Satellite (menu, ustawienia) razem z zaplanowaną zmianą w Home Assistant.';

  @override
  String get haThemeHint =>
      'Dopasuj do aplikacji lub przełączaj jasny i ciemny motyw według harmonogramu';

  @override
  String get haThemeAuto => 'Automatyczny';

  @override
  String get settingHaKioskModeTitle => 'Tryb kiosku HA';

  @override
  String get settingHaKioskModeDescription =>
      'Ukryj nagłówek i pasek boczny Home Assistant. Działa natychmiast.';

  @override
  String get settingHaKioskHideHeaderTitle => 'Ukryj nagłówek';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'Ukryj pasek narzędzi pulpitu i karty widoków, gdy tryb kiosku HA jest włączony. Pozostaw wyłączone, jeśli przełączasz widoki z nagłówka.';

  @override
  String get settingHaKioskHideSidebarTitle => 'Ukryj pasek boczny';

  @override
  String get settingHaKioskHideSidebarDescription =>
      'Ukryj boczny pasek nawigacji, gdy tryb kiosku HA jest włączony.';

  @override
  String get settingHaDashboardCarouselTitle => 'Włącz karuzelę pulpitów';

  @override
  String get settingHaDashboardCarouselDescription =>
      'Przesuń palcem w lewo lub w prawo na pulpicie, aby przechodzić między jego widokami. Przesunięcia na suwakach, mapach i przewijanych kartach są ignorowane.';

  @override
  String get settingHaCarouselOverCardsTitle =>
      'Przechwytuj gesty przesuwania nad kartami';

  @override
  String get settingHaCarouselOverCardsDescription =>
      'Przełączaj widoki nawet wtedy, gdy przesunięcie zaczyna się na karcie reagującej na przesunięcia. Suwaki nadal działają normalnie.';

  @override
  String get settingHaHapticsTitle => 'Włącz haptykę';

  @override
  String get settingHaHapticsDescription =>
      'Wibruj przy używaniu przycisków, przełączników, kart, suwaków i pokręteł termostatu. Wymaga silniczka wibracyjnego.';

  @override
  String get settingHaHapticsStrengthTitle => 'Siła wibracji';

  @override
  String get settingHaHapticsStrengthDescription =>
      'Jak mocno odczuwalna jest wibracja.';

  @override
  String get settingHaTapSoundTitle => 'Odtwarzaj dźwięki dotknięcia';

  @override
  String get settingHaTapSoundDescription =>
      'Odtwarzaj standardowy dźwięk dotknięcia przy używaniu przycisków, przełączników, kart, suwaków i pokręteł termostatu.';

  @override
  String get settingHaTapSoundVolumeTitle => 'Głośność dźwięku dotknięcia';

  @override
  String get settingHaTapSoundVolumeDescription =>
      'Jak głośno odtwarzany jest dźwięk dotknięcia.';

  @override
  String get haUserInterface => 'Interfejs użytkownika';

  @override
  String get haInterfaceHint =>
      'Tryb kiosku, karuzela pulpitów, haptyka, dźwięki dotknięcia';

  @override
  String get haHaptics => 'Haptyka';

  @override
  String get haVibrationLight => 'Słaba';

  @override
  String get haVibrationMedium => 'Średnia';

  @override
  String get haVibrationStrong => 'Silna';

  @override
  String get settingHomeLauncherEnabledTitle => 'Działaj jako ekran główny';

  @override
  String get settingHomeLauncherEnabledDescription =>
      'Zarejestruj Kiosk Satellite jako ekran główny urządzenia: kiosk uruchamia się przy starcie systemu, a każde naciśnięcie przycisku ekranu głównego wraca do niego. Wyłącza się samoczynnie i przywraca poprzedni launcher, jeśli aplikacja kilka razy z rzędu nie zdoła się uruchomić.';

  @override
  String get settingHomeKeepPinningTitle => 'Zachowaj przypinanie ekranu';

  @override
  String get settingHomeKeepPinningDescription =>
      'Przypinaj ekran nawet wtedy, gdy Kiosk Satellite jest ekranem głównym. Natywnie blokuje ostatnie aplikacje i przycisk Wstecz, ale przywraca okno potwierdzenia przypięcia na urządzeniach bez trybu właściciela urządzenia.';

  @override
  String get kioskHomeScreen => 'Ekran główny';

  @override
  String get kioskCheckingDevice => 'Sprawdzanie urządzenia…';

  @override
  String get kioskFireOs => 'Fire OS nie pozwala zastąpić swojego launchera.';

  @override
  String get kioskUnsupported =>
      'To urządzenie nie pozwala na zmianę ekranu głównego.';

  @override
  String get kioskRecovered =>
      'Wyłączono automatycznie po wielokrotnych nieudanych uruchomieniach; przywrócono poprzedni launcher. Włącz przełącznik ponownie, aby spróbować jeszcze raz.';

  @override
  String get kioskHeld =>
      'Kiosk Satellite jest ekranem głównym. Kiosk uruchamia się przy starcie urządzenia, a każde naciśnięcie przycisku ekranu głównego do niego wraca.';

  @override
  String get kioskDisabled =>
      'Nie jest ekranem głównym. Włącz powyżej opcję „Działaj jako ekran główny”.';

  @override
  String get kioskWaiting =>
      'To jeszcze nie jest bieżący ekran główny: urządzenie czeka na potwierdzenie.';

  @override
  String get kioskOpenHomeSettings => 'Otwórz ustawienia ekranu głównego';

  @override
  String get kioskSetDefault => 'Ustaw jako domyślny';

  @override
  String get kioskActive => 'Aktywny';

  @override
  String get kioskNotHome => 'Nie jest ekranem głównym.';

  @override
  String get kioskWaitingRemote =>
      'Oczekiwanie na potwierdzenie na urządzeniu: jest tam otwarte okno systemowe lub ustawienia ekranu głównego.';

  @override
  String get kioskSetDevice => 'Ustaw na urządzeniu';

  @override
  String get settingIntercomAnswerModeTitle => 'Tryb odbierania';

  @override
  String get settingIntercomAnswerModeDescription =>
      '„Dzwonek” wyświetla pytanie na ekranie. „Odbieraj automatycznie” nawiązuje połączenie po sygnale dźwiękowym.';

  @override
  String get settingIntercomRingSecondsTitle => 'Czas dzwonienia';

  @override
  String get settingIntercomRingSecondsDescription =>
      'Jak długo połączenie dzwoni, zanim zostanie uznane za nieodebrane.';

  @override
  String get settingIntercomRingSoundTitle => 'Dźwięk dzwonka';

  @override
  String get settingIntercomRingSoundVolumeDescription =>
      'Odtwarzany z głośnością dzwonka.';

  @override
  String get settingIntercomRingVolumeTitle => 'Głośność dzwonka';

  @override
  String get settingIntercomRingVolumeDescription =>
      'Jak głośno dzwoni połączenie, niezależnie od głośności multimediów.';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => 'Przyjmuj ogłoszenia';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      'Odtwarzaj ogłoszenia „Ogłoś wszystkim” z innych kiosków.';

  @override
  String get intercomOptionAnswerRing => 'Dzwonek';

  @override
  String get intercomOptionAnswerAuto => 'Odbieraj automatycznie';

  @override
  String get intercomOptionAnswerDnd => 'Nie przeszkadzać';

  @override
  String get intercomOptionAnswer15 => '15 sekund';

  @override
  String get intercomOptionAnswer30 => '30 sekund';

  @override
  String get intercomOptionAnswer45 => '45 sekund';

  @override
  String get intercomOptionAnswer60 => '60 sekund';

  @override
  String get intercomAnswerSection => 'Odbieranie';

  @override
  String get settingIntercomEnabledTitle => 'Włącz interkom';

  @override
  String get settingIntercomEnabledDescription =>
      'Dzwoń do innych kiosków w tej sieci i odbieraj ich połączenia.';

  @override
  String get settingIntercomKeyTitle => 'Klucz interkomu';

  @override
  String get settingIntercomKeyDescription =>
      'Kioski z tym samym kluczem mogą się ze sobą łączyć. Klucz można synchronizować w sekcji „Zarządzanie flotą”.';

  @override
  String get settingIntercomKeyPlaceholder => 'Tworzony po włączeniu interkomu';

  @override
  String get intercomNeedsAdmin => 'Interkom wymaga zdalnej administracji';

  @override
  String get intercomAdminHelp =>
      'Za jej pośrednictwem kioski znajdują się i łączą ze sobą. Włącz opcje „Zdalne zarządzanie” i „Znajdź inne kioski” w sekcji „Urządzenie”, a potem wróć tutaj.';

  @override
  String get intercomChangeKey => 'Zmień klucz';

  @override
  String get intercomChangeKeyHelp =>
      'Wklej klucz z innego kiosku lub utwórz nowy.';

  @override
  String get intercomChange => 'Zmień';

  @override
  String get intercomKeyWarning =>
      'Kioski z tym kluczem mogą się ze sobą łączyć. Nowy klucz odetnie ten kiosk od pozostałych, dopóki one też go nie otrzymają.';

  @override
  String get intercomRegenerate => 'Wygeneruj ponownie';

  @override
  String get intercomKeyChanged => 'Zmieniono klucz';

  @override
  String get intercomNotSet => 'Nie ustawiono';

  @override
  String get intercomOpen => 'Otwórz';

  @override
  String get settingIntercomTlsTitle => 'Szyfruj komunikację';

  @override
  String get settingIntercomTlsDescription =>
      'Używaj TLS do szyfrowania połączeń interkomu między kioskami. Wszystkie kioski w połączeniu muszą mieć tę opcję włączoną.';

  @override
  String get intercomKiosks => 'Kioski';

  @override
  String get intercomRosterHelp =>
      'Wykryte kioski i zapisani członkowie floty. Kiosk jest gotowy, gdy jest osiągalny, ma włączony interkom, ten sam klucz i zgodne ustawienia szyfrowania.';

  @override
  String get intercomNoOther => 'Nie znaleziono innych kiosków';

  @override
  String get intercomRosterDeviceHelp =>
      'Pojawiają się tu kioski z włączonymi opcjami „Zdalne zarządzanie” i „Znajdź inne kioski”.';

  @override
  String get intercomNoneHeard => 'Nie znaleziono kiosków';

  @override
  String get intercomRosterRemoteHelp =>
      'Kioski pojawiają się dzięki wykrywaniu w sieci lub zapisanemu członkostwu we flocie. Opcje „Zdalne zarządzanie” i „Znajdź inne kioski” muszą być włączone.';

  @override
  String get intercomReady => 'Gotowy';

  @override
  String get intercomOff => 'Interkom wyłączony';

  @override
  String get intercomDifferentKey => 'Inny klucz';

  @override
  String get intercomUnreachable => 'Nieosiągalny';

  @override
  String get intercomOffline => 'Offline';

  @override
  String get intercomChecking => 'Sprawdzanie…';

  @override
  String get settingIntercomTalkModeTitle => 'Tryb mówienia';

  @override
  String get settingIntercomTalkModeDescription =>
      '„Naciśnij i mów” rejestruje, dopóki przycisk jest przytrzymywany. „Bez użycia rąk” pozwala mikrofonowi nasłuchiwać przez całe połączenie.';

  @override
  String get intercomOptionTalkPtt => 'Naciśnij i mów';

  @override
  String get intercomOptionTalkHandsfree => 'Bez użycia rąk';

  @override
  String get settingIntercomMaxCallMinutesTitle => 'Maksymalny czas połączenia';

  @override
  String get settingIntercomMaxCallMinutesDescription =>
      'Połączenia kończą się samoczynnie po tym czasie.';

  @override
  String get intercomOptionCallUnlimited => 'Bez limitu';

  @override
  String get intercomOptionCall1 => '1 minuta';

  @override
  String get intercomOptionCall2 => '2 minuty';

  @override
  String get intercomOptionCall5 => '5 minut';

  @override
  String get intercomOptionCall10 => '10 minut';

  @override
  String get intercomOptionCall15 => '15 minut';

  @override
  String get intercomOptionCall20 => '20 minut';

  @override
  String get intercomOptionCall30 => '30 minut';

  @override
  String get intercomOptionCall45 => '45 minut';

  @override
  String get intercomOptionCall60 => '60 minut';

  @override
  String get settingIntercomHangupKeyTitle =>
      'Zakończ połączenie po naciśnięciu tego przycisku';

  @override
  String get settingIntercomHangupKeyDescription =>
      'Podczas połączenia przycisk kończy je zamiast wykonywać swoją zwykłą akcję.';

  @override
  String get intercomOptionHangupOff => 'Wyłączone';

  @override
  String get intercomOptionHangupVolumeUp => 'Głośniej';

  @override
  String get intercomOptionHangupVolumeDown => 'Ciszej';

  @override
  String get intercomOptionHangupMute => 'Wycisz';

  @override
  String get intercomOptionHangupHelp => 'Pomoc';

  @override
  String get settingIntercomHangupKeyRingingTitle =>
      'Przycisk rozłączania podczas dzwonienia';

  @override
  String get settingIntercomHangupKeyRingingDescription =>
      'Co robi przycisk, gdy na tym urządzeniu dzwoni połączenie.';

  @override
  String get intercomOptionHangupRingingAnswer => 'Odbierz';

  @override
  String get intercomOptionHangupRingingDecline => 'Odrzuć';

  @override
  String get intercomOptionHangupRingingIgnore => 'Ignoruj';

  @override
  String get settingIntercomCallButtonsTitle => 'Przyciski połączenia';

  @override
  String get settingIntercomCallButtonsDescription =>
      'Przyciski na ekranie kiosku, do którego dzwonisz. Jedno dotknięcie uruchamia daną akcję na tym kiosku.';

  @override
  String get intercomCallButtonsAdd => 'Dodaj przycisk';

  @override
  String get intercomCallButtonIcon => 'Ikona';

  @override
  String get intercomTalkSection => 'Rozmowa';

  @override
  String get settingIntercomVideoTitle => 'Połączenia wideo';

  @override
  String get settingIntercomVideoDescription =>
      'Wysyłaj i wyświetlaj obraz wideo podczas połączeń.';

  @override
  String get settingIntercomVideoQualityTitle => 'Jakość wideo';

  @override
  String get settingIntercomVideoQualityDescription =>
      'Wyższa jakość bardziej obciąża procesor.';

  @override
  String get intercomOptionVideoLow => 'Niska';

  @override
  String get intercomOptionVideoMedium => 'Średnia';

  @override
  String get intercomOptionVideoHigh => 'Wysoka';

  @override
  String get intercomVideoSection => 'Wideo';

  @override
  String get settingIntercomAutoAnswerCameraTitle =>
      'Odbieraj z włączoną kamerą';

  @override
  String get settingIntercomAutoAnswerCameraDescription =>
      'Automatycznie odbierane połączenia wideo zaczynają się z włączoną kamerą.';

  @override
  String get settingKioskAllowDrawerTitle =>
      'Zezwalaj na menu z szybkimi akcjami';

  @override
  String get settingKioskAllowQuickControlsDescription =>
      'Pokazuje menu bez gestu wyjścia i PIN-u, ograniczone do akcji wybranych poniżej. W nawigacji „Classic” otwiera je przesunięcie od krawędzi. W „Compass” jest to widok „Quick Controls”.';

  @override
  String get settingKioskAllowDashboardTitle => 'Pulpit';

  @override
  String get settingKioskAllowDashboardDescription =>
      'Przeładuj stronę startową.';

  @override
  String get settingKioskAllowHaKioskTitle => 'Tryb kiosku HA';

  @override
  String get settingKioskAllowHaKioskDescription =>
      'Pokaż lub ukryj nagłówek i pasek boczny Home Assistant.';

  @override
  String get settingKioskAllowCameraTitle => 'Widok kamery';

  @override
  String get settingKioskAllowCameraDescription =>
      'Otwórz domyślny widok kamery.';

  @override
  String get settingKioskAllowIntercomTitle => 'Interkom';

  @override
  String get settingKioskAllowIntercomDescription =>
      'Dzwoń do innych kiosków z menu kiosku.';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription =>
      'Otwórz interfejs internetowy Music Assistant.';

  @override
  String get settingKioskAllowSendspinPlayerTitle => 'Pływający odtwarzacz';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      'Pokaż lub ukryj pływający odtwarzacz i otwórz ekran „Teraz odtwarzane”.';

  @override
  String get settingKioskAllowScreensaverTitle => 'Uruchom wygaszacz ekranu';

  @override
  String get settingKioskAllowScreensaverDescription =>
      'Uruchom od razu wygaszacz ekranu.';

  @override
  String get settingKioskAllowHoldTitle => 'Tryb wstrzymania';

  @override
  String get settingKioskAllowHoldDescription =>
      'Włącz lub wyłącz tryb wstrzymania.';

  @override
  String get settingKioskAllowLockdownTitle => 'Tryb blokady';

  @override
  String get settingKioskAllowLockdownDescription =>
      'Zablokuj ekran do czasu wykonania gestu wyjścia lub zdalnego odblokowania.';

  @override
  String get settingKioskAllowThemeTitle => 'Wybór motywu';

  @override
  String get settingKioskAllowThemeDescription =>
      'Przełączaj między jasnym a ciemnym motywem.';

  @override
  String get settingKioskAllowAppsTitle => 'Aplikacje';

  @override
  String get settingKioskAllowAppsDescription =>
      'Otwórz launcher aplikacji. Gdy opcja „Wyłącz przycisk ekranu głównego” jest włączona, uruchomienie aplikacji odpina kiosk do czasu powrotu.';

  @override
  String get kioskAllowedActions => 'Dozwolone akcje';

  @override
  String get kioskAllowedHelp => 'Szybkie akcje dostępne w menu kiosku';

  @override
  String get settingKioskAllowedAppsTitle => 'Dozwolone aplikacje';

  @override
  String get settingKioskAllowedAppsDescription =>
      'Aplikacje z launchera dostępne, gdy tryb kiosku jest włączony.';

  @override
  String get kioskAllowedAppsEmpty =>
      'Najpierw dodaj aplikacje w „Ustawienia” > „Launcher aplikacji”.';

  @override
  String get settingKioskEnabledTitle => 'Włącz tryb kiosku';

  @override
  String get settingKioskEnabledDescription =>
      'Zablokuj tablet w aplikacji Kiosk Satellite. Przesunięcie otwierające menu zostaje zastąpione gestem wyjścia, przycisk Wstecz nie opuszcza kiosku, a poniższe zabezpieczenia zaczynają działać.';

  @override
  String get settingKioskStartOnBootTitle => 'Uruchamiaj przy starcie';

  @override
  String get settingKioskStartOnBootDescription =>
      'Uruchamiaj Kiosk Satellite po włączeniu urządzenia. W systemie Android 10+ wymaga to uprawnienia do wyświetlania nad innymi aplikacjami; Android poprosi o nie przy pierwszym włączeniu.';

  @override
  String get settingKioskExitGestureTitle => 'Gest wyjścia z kiosku';

  @override
  String get settingKioskExitGestureDescription =>
      'Szybkie dotknięcia w dowolnym miejscu otwierają menu, po podaniu PIN-u, jeśli jest ustawiony. W przypadku opcji wymagających przytrzymania należy przytrzymać ostatnie dotknięcie. Gdy gest jest wyłączony, do ustawień można dotrzeć tylko przez zdalną administrację.';

  @override
  String get settingKioskPinTitle => 'PIN trybu kiosku';

  @override
  String get settingKioskPinDescription =>
      'Wymagany po geście wyjścia, przed otwarciem menu. Pozostaw puste, aby nie używać PIN-u.';

  @override
  String get settingKioskDisableStatusBarTitle => 'Wyłącz pasek stanu';

  @override
  String get settingKioskDisableStatusBarDescription =>
      'Blokuj rozwijanie paska stanu osłoną na górnej krawędzi ekranu. Wymaga uprawnienia do wyświetlania nad innymi aplikacjami; Android poprosi o nie przy pierwszym włączeniu.';

  @override
  String get settingKioskDisableVolumeTitle => 'Wyłącz przyciski głośności';

  @override
  String get settingKioskDisableVolumeDescription =>
      'Ignoruj naciśnięcia sprzętowych przycisków głośności.';

  @override
  String get settingKioskDisablePowerTitle => 'Wyłącz przycisk zasilania';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android nie pozwala zablokować przycisku zasilania, więc po jego naciśnięciu ekran od razu włącza się ponownie. Zdalne wyłączanie ekranu nadal działa.';

  @override
  String get settingKioskDisableHomeTitle => 'Wyłącz przycisk ekranu głównego';

  @override
  String get settingKioskDisableHomeDescription =>
      'Przypnij aplikację funkcją przypinania ekranu systemu Android, która blokuje przyciski ekranu głównego i ostatnich aplikacji. Android poprosi o potwierdzenie za pierwszym razem.';

  @override
  String get settingKioskDisableContextMenusTitle => 'Wyłącz menu kontekstowe';

  @override
  String get settingKioskDisableContextMenusDescription =>
      'Blokuj menu otwierane przytrzymaniem i zaznaczanie tekstu na wyświetlanej stronie.';

  @override
  String get settingKioskDisablePullRefreshTitle =>
      'Wyłącz odświeżanie przeciągnięciem';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Ignoruj gest odświeżania przeciągnięciem, gdy tryb kiosku jest włączony.';

  @override
  String get settingKioskDisableGesturesTitle => 'Wyłącz gesty';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Ignoruj gesty ze strony „Gesty”, gdy tryb kiosku jest włączony.';

  @override
  String get kioskGestureTaps5 => '5 szybkich dotknięć';

  @override
  String get kioskGestureTaps7 => '7 szybkich dotknięć';

  @override
  String get kioskGestureTaps5Hold =>
      '5 szybkich dotknięć z przytrzymaniem ostatniego';

  @override
  String get kioskGestureTaps7Hold =>
      '7 szybkich dotknięć z przytrzymaniem ostatniego';

  @override
  String get kioskGestureNone => 'Wyłączony (tylko zdalna administracja)';

  @override
  String get kioskGroundControlVisionMatch => 'Ground Control Vision Match';

  @override
  String get settingKioskFaceSkipPinTitle => 'Pomijaj PIN dla';

  @override
  String get settingKioskFaceSkipPinDescription =>
      'Przy opcji Wybrane osoby menu otwiera się po geście wyjścia bez PIN-u, gdy przed kioskiem rozpoznana jest jedna z osób wybranych poniżej.';

  @override
  String get kioskFaceSkipPinNobody => 'Nikt';

  @override
  String get kioskFaceSkipPinPeople => 'Wybrane osoby';

  @override
  String get settingKioskFacePeopleTitle => 'Osoby';

  @override
  String get settingKioskFacePeopleDescription =>
      'Wybierz, kto może pomijać PIN. Jeśli nikt nie jest wybrany, może to zrobić każda rozpoznana osoba.';

  @override
  String get kioskForeground =>
      'Kiosk Satellite może samodzielnie wrócić na pierwszy plan.';

  @override
  String get kioskOverlayMissing =>
      'Bez tego kiosk nie może sam wrócić na pierwszy plan, a osłona trybu blokady zakrywa tylko aplikację.';

  @override
  String get kioskGuardHeld =>
      'Pasek powiadomień i lista ostatnich aplikacji zamykają się same, gdy ekran jest chroniony.';

  @override
  String get kioskGuardMissing =>
      'Bez tego pasek powiadomień i lista ostatnich aplikacji pozostają dostępne. Włącz Kiosk Satellite w sekcji „Ułatwienia dostępu”.';

  @override
  String get kioskOverlayRemote =>
      'Bez tego kiosk nie może sam wrócić na pierwszy plan. Ekran przyznawania uprawnienia wyświetla się na tablecie.';

  @override
  String get kioskGuardRemote =>
      'Bez tego pasek powiadomień i lista ostatnich aplikacji pozostają dostępne. Włącz Kiosk Satellite w sekcji „Ułatwienia dostępu” na tablecie.';

  @override
  String get kioskGrantDevice => 'Przyznaj na urządzeniu';

  @override
  String get kioskOpenSettingsDevice => 'Otwórz ustawienia na urządzeniu';

  @override
  String get settingLedEnabledTitle => 'Włącz sterowanie LED';

  @override
  String get settingLedEnabledDescription =>
      'Pozwól aplikacji Kiosk Satellite sterować diodami.';

  @override
  String get settingLedAnimationsTitle => 'Animuj efekty';

  @override
  String get settingLedAnimationsDescription =>
      'Poruszaj łukami i płynnie przygaszaj pulsowanie. Wyłącz, aby każdy efekt był statyczny.';

  @override
  String get settingLedIdleEnabledTitle => 'Świeć w spoczynku';

  @override
  String get settingLedIdleEnabledDescription =>
      'Świeć, gdy nic innego nie jest wyświetlane.';

  @override
  String get settingLedIdleBrightnessTitle => 'Jasność';

  @override
  String get settingLedIdleBrightnessDescription =>
      'Jak jasno świecą diody w tej sytuacji.';

  @override
  String get settingLedIdleLightColorTitle => 'Kolor';

  @override
  String get settingLedIdleLightColorDescription =>
      'Kolor diod w tej sytuacji.';

  @override
  String get settingLedIdleStyleTitle => 'Efekt';

  @override
  String get settingLedIdleStyleDescription =>
      'Sposób świecenia diod w spoczynku.';

  @override
  String get settingLedIdleStyleOptionSolid => 'Stałe światło';

  @override
  String get settingLedIdleStyleOptionBreathe => 'Oddychanie';

  @override
  String get settingLedVoiceEnabledTitle => 'Pokazuj aktywność głosową';

  @override
  String get settingLedVoiceEnabledDescription =>
      'Świeć, gdy Voice Satellite słucha, myśli i odpowiada.';

  @override
  String get settingLedVoiceBrightnessTitle => 'Jasność';

  @override
  String get settingLedVoiceBrightnessDescription =>
      'Jak jasno świecą diody w tej sytuacji.';

  @override
  String get settingLedVoiceLightColorTitle => 'Kolor';

  @override
  String get settingLedVoiceLightColorDescription =>
      'Kolor pod łukiem, który krąży podczas słuchania, zmienia się naprzemiennie podczas myślenia i przygasa podczas odpowiadania.';

  @override
  String get settingLedVoiceAccentColorTitle => 'Kolor akcentu';

  @override
  String get settingLedVoiceAccentColorDescription =>
      'Kolor łuku krążącego wokół diod.';

  @override
  String get settingLedVoiceMutedTitle => 'Pokazuj wyciszenie';

  @override
  String get settingLedVoiceMutedDescription =>
      'Świeć, gdy Voice Satellite jest wyciszony.';

  @override
  String get settingLedVoiceMutedColorTitle => 'Kolor wyciszenia';

  @override
  String get settingLedVoiceMutedColorDescription =>
      'Kolor diod podczas wyciszenia.';

  @override
  String get settingLedTimersEnabledTitle => 'Pokazuj minutniki';

  @override
  String get settingLedTimersEnabledDescription =>
      'Pulsuj, gdy dzwoni minutnik.';

  @override
  String get settingLedTimersBrightnessTitle => 'Jasność';

  @override
  String get settingLedTimersBrightnessDescription =>
      'Jak jasno świecą diody w tej sytuacji.';

  @override
  String get settingLedTimersLightColorTitle => 'Kolor';

  @override
  String get settingLedTimersLightColorDescription =>
      'Kolor diod w tej sytuacji.';

  @override
  String get settingLedTimersCountdownTitle => 'Pokazuj odliczanie';

  @override
  String get settingLedTimersCountdownDescription =>
      'Diody gasną jedna po drugiej w miarę odliczania najbliższego minutnika.';

  @override
  String get settingLedAlarmsEnabledTitle => 'Pokazuj budziki';

  @override
  String get settingLedAlarmsEnabledDescription => 'Pulsuj, gdy dzwoni budzik.';

  @override
  String get settingLedAlarmsBrightnessTitle => 'Jasność';

  @override
  String get settingLedAlarmsBrightnessDescription =>
      'Jak jasno świecą diody w tej sytuacji.';

  @override
  String get settingLedAlarmsLightColorTitle => 'Kolor';

  @override
  String get settingLedAlarmsLightColorDescription =>
      'Kolor diod w tej sytuacji.';

  @override
  String get settingLedIntercomEnabledTitle => 'Pokazuj połączenia interkomu';

  @override
  String get settingLedIntercomEnabledDescription =>
      'Pulsuj podczas dzwonienia i krąż podczas trwającego połączenia.';

  @override
  String get settingLedIntercomBrightnessTitle => 'Jasność';

  @override
  String get settingLedIntercomBrightnessDescription =>
      'Jak jasno świecą diody w tej sytuacji.';

  @override
  String get settingLedIntercomLightColorTitle => 'Kolor';

  @override
  String get settingLedIntercomLightColorDescription =>
      'Kolor diod w tej sytuacji.';

  @override
  String get settingLedNotificationsEnabledTitle => 'Pokazuj powiadomienia';

  @override
  String get settingLedNotificationsEnabledDescription =>
      'Pulsuj powoli, gdy czeka powiadomienie.';

  @override
  String get settingLedNotificationsBrightnessTitle => 'Jasność';

  @override
  String get settingLedNotificationsBrightnessDescription =>
      'Jak jasno świecą diody w tej sytuacji.';

  @override
  String get settingLedNotificationsLightColorTitle => 'Kolor';

  @override
  String get settingLedNotificationsLightColorDescription =>
      'Kolor diod w tej sytuacji.';

  @override
  String get settingLedMediaEnabledTitle => 'Pokazuj muzykę';

  @override
  String get settingLedMediaEnabledDescription =>
      'Światła świecą, gdy na tym urządzeniu odtwarzana jest muzyka.';

  @override
  String get settingLedMediaBrightnessTitle => 'Jasność';

  @override
  String get settingLedMediaBrightnessDescription =>
      'Jak jasno świecą diody w tej sytuacji.';

  @override
  String get settingLedMediaLightColorTitle => 'Kolor';

  @override
  String get settingLedMediaLightColorDescription =>
      'Kolor diod w tej sytuacji.';

  @override
  String get settingLedMediaStyleTitle => 'Efekt';

  @override
  String get settingLedMediaStyleDescription =>
      'Sposób, w jaki światła pokazują muzykę.';

  @override
  String get settingLedMediaStyleOptionSolid => 'Stałe światło';

  @override
  String get settingLedMediaStyleOptionBreathe => 'Oddychanie';

  @override
  String get settingLockdownEnabledTitle => 'Włącz tryb blokady';

  @override
  String get settingLockdownEnabledDescription =>
      'Wyłącza interakcje z ekranem, dopóki tryb nie zostanie wyłączony z Home Assistant lub gestem wyjścia.';

  @override
  String get settingLockdownAutoUnlockMinutesTitle =>
      'Odblokuj automatycznie po';

  @override
  String get settingLockdownAutoUnlockMinutesDescription =>
      'Wyłącza tryb blokady po tym czasie, jeśli został włączony z menu kiosku. Ustaw 0, aby blokada pozostała aktywna.';

  @override
  String get settingLockdownBlackoutTitle => 'Zaciemnij ekran';

  @override
  String get settingLockdownBlackoutDescription =>
      'Podczas blokady ekran jest czarny.';

  @override
  String get settingLockdownAllowScreensaverTitle =>
      'Zezwalaj na wygaszacz ekranu';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      'Wygaszacz ekranu może działać podczas blokady. Zamykanie wygaszacza po wykryciu ruchu pozostaje wyłączone do czasu zdjęcia blokady.';

  @override
  String get settingLockdownExitGestureTitle => 'Gest wyjścia z trybu blokady';

  @override
  String get settingLockdownExitGestureDescription =>
      'Szybkie dotknięcia w dowolnym miejscu wyłączają tryb blokady, po podaniu PIN-u kiosku, jeśli został ustawiony. Warianty z przytrzymaniem wymagają przytrzymania ostatniego dotknięcia. Gdy gest jest wyłączony, tryb mogą wyłączyć tylko zdalna administracja lub Home Assistant.';

  @override
  String get lockdownGestureNone => 'Wyłączony (tylko zdalnie)';

  @override
  String get lockdownExplanation =>
      'Tryb blokady sprawia, że pulpit nie reaguje na interakcje, włącza wszystkie zabezpieczenia trybu kiosku bez zmiany jego ustawień i wycisza wykrywanie słowa wybudzającego na czas swojego działania. Przy włączonej ochronie interfejsu systemu (powyżej) blokowane są też obszar powiadomień i ostatnie aplikacje. Home Assistant otrzymuje przez ESPHome przełącznik trybu blokady.';

  @override
  String get lockdownSearch =>
      'Osłona przed dotykiem sterowana tylko zdalnie. Skonfiguruj ją w interfejsie zdalnej administracji; jej uprawnienia znajdują się w sekcji „Wymagane uprawnienia systemowe”.';

  @override
  String get settingLockdownFaceDisableTitle => 'Wyłączaj tryb blokady dla';

  @override
  String get settingLockdownFaceDisableDescription =>
      'Przy opcji Wybrane osoby tryb blokady wyłącza się, gdy przed kioskiem zostanie rozpoznana jedna z osób wybranych poniżej. Zostaw Nikt, jeśli blokujesz ekran, aby go wyczyścić.';

  @override
  String get settingLockdownFacePeopleDescription =>
      'Wybierz, dla kogo tryb blokady jest wyłączany. Jeśli nikt nie jest wybrany, wyłącza się dla każdej rozpoznanej osoby.';

  @override
  String get settingLockdownFaceRelockTitle => 'Ponownie włączaj tryb blokady';

  @override
  String get settingLockdownFaceRelockDescription =>
      'Ponownie włącza tryb blokady 10 sekund po tym, jak żadna z wybranych osób nie jest widoczna.';

  @override
  String get lockdownOverlayHeld => 'Osłona blokady może zakryć cały ekran.';

  @override
  String get lockdownOverlayMissing =>
      'Bez tego uprawnienia osłona zakrywa tylko aplikację. Ekran przyznawania uprawnienia pojawi się na tablecie.';

  @override
  String get lockdownPermissionsSearch =>
      'Uprawnienia, na których opierają się zabezpieczenia trybu blokady.';

  @override
  String get settingAirplayEnabledTitle => 'Włącz odbiornik AirPlay';

  @override
  String get settingAirplayEnabledDescription =>
      'Urządzenie pojawia się jako głośnik AirPlay w menu AirPlay na urządzeniu iPhone, iPad lub Mac.';

  @override
  String get settingAirplayNameTitle => 'Nazwa głośnika';

  @override
  String get settingAirplayNameDescription =>
      'Nazwa w menu AirPlay. Jeśli pole jest puste, używana jest nazwa urządzenia.';

  @override
  String get settingAirplaySenderVolumeTitle => 'Używaj głośności nadawcy';

  @override
  String get settingAirplaySenderVolumeDescription =>
      'Regulacja głośności na urządzeniu iPhone, iPad lub Mac zmienia głośność odtwarzania na tym urządzeniu. Po wyłączeniu działa tylko regulacja głośności tego urządzenia.';

  @override
  String get settingAirplaySyncOffsetDescription =>
      'Wartość ujemna sprawia, że to urządzenie odtwarza dźwięk wcześniej, aby zsynchronizować go z obrazem na urządzeniu nadawcy. Zmiana działa od razu.';

  @override
  String get settingAirplayTakeoverTitle =>
      'Pozwól innemu nadawcy przejąć odtwarzanie';

  @override
  String get settingAirplayTakeoverDescription =>
      'Drugi iPhone, iPad lub Mac może przejąć odtwarzanie, gdy odtwarza pierwszy. Po wyłączeniu musi poczekać, aż pierwszy się rozłączy.';

  @override
  String get mediaAirplayHint =>
      'Odtwarzaj dźwięk z urządzenia iPhone, iPad lub Mac';

  @override
  String get mediaCacheTitle => 'Pamięć podręczna okładek albumów';

  @override
  String get mediaCacheReadFailed =>
      'Nie udało się odczytać rozmiaru pamięci podręcznej.';

  @override
  String get mediaCacheClearFailed =>
      'Nie udało się wyczyścić pamięci podręcznej.';

  @override
  String get mediaCacheChecking => 'Sprawdzanie rozmiaru pamięci podręcznej…';

  @override
  String get mediaCacheClearing => 'Usuwanie…';

  @override
  String mediaCacheUsage(String used, String limit) {
    return 'Wykorzystano $used z $limit. Miniatury z kolejki są automatycznie zapisywane w pamięci podręcznej.';
  }

  @override
  String get settingSendspinShowPlayerTitle => 'Pokazuj pływający odtwarzacz';

  @override
  String get settingSendspinShowPlayerDescription =>
      'Podczas odtwarzania muzyki pokazuj nad pulpitem małe okno z bieżącym utworem, okładką, informacjami o utworze i postępem. Przeciągnij je w dowolne miejsce; pozycja zostanie zapamiętana.';

  @override
  String get settingSendspinPlayerSizeTitle => 'Rozmiar odtwarzacza';

  @override
  String get settingSendspinPlayerSizeDescription =>
      'Kompaktowy to małe, dyskretne okienko wyświetlające aktualnie odtwarzany utwór. Duży wyświetla przyciski „Poprzedni”, „Odtwarzaj/Wstrzymaj” i „Następny”, dopasowane do obsługi dotykiem i sterujące całą grupą odtwarzania.';

  @override
  String get settingSendspinPausedHideMinutesTitle =>
      'Ukryj wstrzymany odtwarzacz po';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      'Jak długo wstrzymany odtwarzacz pozostaje na ekranie. Dotyczy zarówno pływającego odtwarzacza, jak i ekranu „Teraz odtwarzane”.';

  @override
  String get settingSendspinDismissKeepsPlayingTitle =>
      'Odtwarzaj dalej po odrzuceniu';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      'Odrzucenie pływającego odtwarzacza szybkim ruchem palca ukrywa go, ale nie zatrzymuje muzyki.';

  @override
  String get mediaFloatingPage => 'Pływający odtwarzacz';

  @override
  String get mediaFloatingHint => 'Mała karta nad pulpitem';

  @override
  String get mediaCompact => 'Kompaktowy';

  @override
  String get mediaLargeControls => 'Duży z przyciskami';

  @override
  String get settingSendspinPlayerSourceTitle => 'Źródło odtwarzacza';

  @override
  String get settingSendspinPlayerSourceDescription =>
      'Co pokazują i czym sterują pływający odtwarzacz i ekran „Teraz odtwarzane”: to urządzenie lub odtwarzacz w innym miejscu.';

  @override
  String get settingSendspinPlayerTitle => 'Odtwarzacz';

  @override
  String get settingSendspinPlayerDescription =>
      'Odtwarzacz z wybranego źródła, który ma być pokazywany i sterowany.';

  @override
  String get settingSendspinDuckPercentTitle =>
      'Ściszanie muzyki podczas interakcji głosowych';

  @override
  String get settingSendspinDuckPercentDescription =>
      'Podczas interakcji głosowych i połączeń interkomu głośność muzyki zmniejsza się do tego poziomu, a następnie wraca do poprzedniego.';

  @override
  String get settingSendspinEsphomeEntitiesTitle => 'Udostępniaj encje ESPHome';

  @override
  String get settingSendspinEsphomeEntitiesDescription =>
      'Przyciski odtwarzania, wstrzymania, następnego i poprzedniego utworu dla śledzonego odtwarzacza w Home Assistant oraz jego stan, tytuł, wykonawca i źródło jako czujniki.';

  @override
  String get settingSendspinVolumeKeysTitle =>
      'Przyciski głośności sterują odtwarzaczem';

  @override
  String get settingSendspinVolumeKeysGroupDescription =>
      'Przyciski głośności tego urządzenia zmieniają głośność śledzonego odtwarzacza zamiast własnej. Gdy to urządzenie odtwarza w grupie, zmieniają głośność grupy. Działa tylko wtedy, gdy widoczny jest ekran „Teraz odtwarzane”, albo zawsze, gdy odtwarzacz gra.';

  @override
  String get settingSendspinVolumeKeyStepTitle => 'Krok przycisku głośności';

  @override
  String get settingSendspinVolumeKeyStepDescription =>
      'O ile jedno naciśnięcie przycisku głośności zmienia głośność odtwarzacza.';

  @override
  String get mediaIntro =>
      'Pływający odtwarzacz i ekran „Teraz odtwarzane” pojawiają się tylko wtedy, gdy wybrany odtwarzacz odtwarza utwór lub ma wczytaną kolejkę. Gdy nic nie jest odtwarzane ani nie ma kolejki, żadne z nich się nie pojawia.';

  @override
  String get mediaThisDevice => 'To urządzenie';

  @override
  String get mediaOff => 'Wyłączone';

  @override
  String get mediaKeysNowPlaying =>
      'Gdy widoczny jest ekran „Teraz odtwarzane”';

  @override
  String get mediaKeysPlaying => 'Gdy odtwarzacz gra';

  @override
  String get mediaAnotherPlayer => 'inny odtwarzacz';

  @override
  String mediaOfflineSendspin(String player) {
    return 'Odtwarzacz Sendspin pozostaje niedostępny, gdy wybrano $player.';
  }

  @override
  String mediaOfflineAirplay(String player) {
    return 'Odbiornik AirPlay pozostaje wyłączony, gdy wybrano $player.';
  }

  @override
  String mediaOfflineBoth(String player) {
    return 'Odtwarzacz Sendspin i odbiornik AirPlay pozostają niedostępne, gdy wybrano $player.';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => 'Włącz tekst utworu';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      'Synchronizowany tekst utworu na ekranie „Teraz odtwarzane”, dla każdego źródła odtwarzacza.';

  @override
  String get settingSendspinLyricsSourceTitle => 'Źródło tekstu utworu';

  @override
  String get settingSendspinLyricsSourceDescription =>
      'Skąd pochodzi tekst utworu. Music Assistant wymaga podania adresu serwera i tokenu na stronie Music Assistant.';

  @override
  String get settingSendspinLyricsFallbackTitle =>
      'Zapasowe źródło: Music Assistant';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      'Gdy LRCLIB jest nieosiągalny, zapytanie trafia do Music Assistant. Wymaga połączenia z Music Assistant.';

  @override
  String get settingSendspinLyricsOffsetTitle => 'Przesunięcie tekstu utworu';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      'Przesuń tekst utworu względem muzyki. Wartość dodatnia pokazuje każdy wiersz wcześniej, ujemna później. Warto to skorygować przy utworach, w których tekst stale się rozjeżdża.';

  @override
  String get mediaLyricsPage => 'Tekst utworu';

  @override
  String get mediaLyricsHint =>
      'Synchronizowany tekst utworu, jego źródło i przesunięcie';

  @override
  String get settingSendspinMaUrlTitle => 'Adres serwera';

  @override
  String get settingSendspinMaUrlDescription =>
      'Adres serwera Music Assistant, taki jak w jego interfejsie webowym. Zwykle https i port 8095.';

  @override
  String get settingSendspinMaTokenTitle => 'Token uwierzytelniania';

  @override
  String get settingSendspinMaTokenDescription =>
      'Token o długim okresie ważności z Music Assistant (Ustawienia, a potem Użytkownicy). Do tekstu utworu wystarczy dostęp do odczytu; skrót w menu kiosku otwiera interfejs webowy jako właściciel tokenu.';

  @override
  String get settingSendspinMaOpenFullscreenTitle =>
      'Otwieraj od razu „Teraz odtwarzane”';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      'Otwieraj pełnoekranowy odtwarzacz Music Assistant z menu kiosku lub gestem „Otwórz Music Assistant”.';

  @override
  String get settingSendspinMaAutoCloseTitle => 'Zamknij po bezczynności';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Kiosk wraca do pulpitu, gdy przez ten czas nikt nie dotknie strony Music Assistant. Wartość 0 pozostawia ją otwartą, dopóki nie zostanie zamknięta.';

  @override
  String get settingSendspinMaHideCloseTitle => 'Ukryj przycisk zamykania';

  @override
  String get settingSendspinMaHideCloseDescription =>
      'Pływający przycisk zamykania może zasłaniać elementy sterujące Music Assistant, na przykład menu ekranu „Teraz odtwarzane”. Jeśli go nie ma, można zamknąć Music Assistant za pomocą przycisku „Wstecz” lub menu bocznego kiosku.';

  @override
  String get settingSendspinMaZoomDescription =>
      'Skaluje całą stronę Music Assistant.';

  @override
  String get mediaMaHint => 'Serwer, token, skrót w menu kiosku';

  @override
  String get mediaKioskMenu => 'Menu kiosku';

  @override
  String get mediaValidateConnection => 'Sprawdź połączenie';

  @override
  String get mediaValidate => 'Sprawdź';

  @override
  String get mediaChecking => 'Sprawdzanie…';

  @override
  String get mediaConnected => 'Połączono';

  @override
  String mediaConnectedVersion(String version) {
    return 'Połączono z Music Assistant $version';
  }

  @override
  String get mediaValidateHint =>
      'Sprawdź adres i token przed włączeniem skrótu lub tekstu utworu.';

  @override
  String get mediaDeviceNoAnswer => 'Urządzenie nie odpowiedziało.';

  @override
  String get mediaValidationFailed => 'Weryfikacja nie powiodła się.';

  @override
  String get mediaNoAddress => 'Nie ustawiono adresu serwera.';

  @override
  String get mediaNoToken => 'Nie ustawiono tokenu uwierzytelniania.';

  @override
  String get mediaTimeout =>
      'Brak odpowiedzi od Music Assistant w wyznaczonym czasie.';

  @override
  String mediaUnreachable(String host, String error) {
    return 'Nie udało się połączyć z $host: $error';
  }

  @override
  String get mediaServerClosed => 'serwer zamknął połączenie';

  @override
  String get settingSendspinFullscreenControlsTitle =>
      'Pokaż sterowanie odtwarzaniem';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      'Przyciski poprzedni, odtwórz/wstrzymaj i następny oraz pasek postępu na ekranie „Teraz odtwarzane”. Przy włączonym sterowaniu ekran zamyka się przyciskiem zamknięcia zamiast dotknięciem w dowolnym miejscu.';

  @override
  String get settingSendspinFullscreenTextScaleTitle => 'Skala tekstu';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      'Rozmiar tytułu utworu, wykonawcy, albumu, tekstu utworu i kolejki. Dotyczy obu układów oraz wyświetlania obok wygaszacza ekranu. Okładka albumu dopasowuje się, aby zostawić miejsce na tekst.';

  @override
  String get settingSendspinFullscreenButtonScaleTitle => 'Skala przycisków';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      'Rozmiar przycisków odtwarzania i paska postępu, niezależnie od rozmiaru tekstu. Dotyczy obu układów oraz wyświetlania obok wygaszacza ekranu. Elementy sterujące dopasowują się do miejsca dostępnego w odtwarzaczu.';

  @override
  String get settingSendspinFullscreenLayoutTitle => 'Tryb układu';

  @override
  String get settingSendspinFullscreenLayoutDescription =>
      'Sposób rozmieszczenia okładki albumu, informacji o utworze i sterowania na ekranie „Teraz odtwarzane”. „Poziomy” dzieli je na lewą i prawą połowę. „Tylko okładka albumu” wypełnia ekran okładką, a informacje o utworze i sterowanie pokazuje przez kilka sekund po dotknięciu; gdy otwarty jest tekst utworu lub kolejka, przełącza się na układ „Pionowy”. Ignorowane, gdy ekran „Teraz odtwarzane” jest wyświetlany obok wygaszacza ekranu.';

  @override
  String get mediaLayoutVertical => 'Pionowy';

  @override
  String get mediaLayoutHorizontal => 'Poziomy';

  @override
  String get mediaLayoutArtOnly => 'Tylko okładka albumu';

  @override
  String get settingSendspinFullscreenDoubleTapTitle =>
      'Zamykanie dwukrotnym dotknięciem';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'Dwukrotne dotknięcie w dowolnym miejscu ekranu „Teraz odtwarzane” zamyka go. Przycisk zamknięcia nie będzie wyświetlany. Ignorowane, gdy ekran „Teraz odtwarzane” jest wyświetlany obok wygaszacza ekranu.';

  @override
  String get settingSendspinFullscreenCloseButtonTitle =>
      'Zawsze pokazuj przycisk zamknięcia';

  @override
  String get settingSendspinFullscreenCloseButtonDescription =>
      'Pokazuj przycisk zamknięcia, gdy włączona jest opcja „Zamykanie dwukrotnym dotknięciem”.';

  @override
  String get settingSendspinFullscreenOnPlayTitle =>
      'Otwieraj ekran „Teraz odtwarzane” po rozpoczęciu odtwarzania muzyki';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      'Otwieraj ekran „Teraz odtwarzane” od razu po rozpoczęciu odtwarzania, zamiast czekać na limit czasu wygaszacza ekranu.';

  @override
  String get settingSendspinFullscreenMotionTitle =>
      'Zamykaj ekran „Teraz odtwarzane” po wykryciu ruchu';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      'Ruch zamyka ekran „Teraz odtwarzane” tak jak zwykły wygaszacz ekranu. Po wyłączeniu zamyka go tylko dotknięcie, więc przejście obok nie przerywa wyświetlania muzyki. Ignorowane, gdy ekran „Teraz odtwarzane” jest wyświetlany obok wygaszacza ekranu.';

  @override
  String get settingSendspinFullscreenReturnTitle => 'Po zamknięciu';

  @override
  String get settingSendspinFullscreenReturnDescription =>
      'Widok pulpitu wyświetlany po zamknięciu ekranu „Teraz odtwarzane”. „Domyślnie” stosuje ustawienie „Powrót do widoku głównego pulpitu”.';

  @override
  String get mediaReturnLastView => 'Ostatni widok';

  @override
  String get mediaReturnChosenView => 'Wybrany widok';

  @override
  String get settingSendspinFullscreenReturnViewTitle => 'Widok pulpitu';

  @override
  String get settingSendspinFullscreenReturnViewDescription =>
      'Widok wyświetlany po zamknięciu ekranu „Teraz odtwarzane”.';

  @override
  String get settingSendspinSpeakerPillTitle =>
      'Pokaż etykietę wyboru głośników';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Pokazuje wybór głośników przez 5 sekund po interakcji z ekranem. Dodawaj głośniki do bieżącej grupy lub usuwaj je z niej.';

  @override
  String get settingSendspinSpeakerPillPlayersTitle =>
      'Filtruj etykietę wyboru głośników';

  @override
  String get settingSendspinSpeakerPillPlayersDescription =>
      'Na etykiecie widoczne są tylko te głośniki. Głośniki należące już do grupy są widoczne zawsze.';

  @override
  String get settingSendspinAudioQualityTitle => 'Pokaż jakość dźwięku';

  @override
  String get settingSendspinAudioQualityDescription =>
      'Pokazuje format, głębię bitową, częstotliwość próbkowania, przepływność i źródło bieżącego utworu u dołu ekranu „Teraz odtwarzane”. Wymaga Music Assistant.';

  @override
  String get mediaAllSpeakers => 'Wszystkie głośniki';

  @override
  String get settingSendspinQueueArtTitle => 'Pokaż okładki albumów w kolejce';

  @override
  String get settingSendspinQueueArtDescription =>
      'Okładka w każdym wierszu kolejki.';

  @override
  String get mediaNowPlayingHint =>
      'Tryb pełnoekranowy podczas odtwarzania muzyki';

  @override
  String get mediaInterfaceHeading => 'Interfejs użytkownika';

  @override
  String get settingSendspinFullscreenTitle =>
      '„Teraz odtwarzane” zamiast wygaszacza ekranu';

  @override
  String get settingSendspinFullscreenDescription =>
      'Podczas odtwarzania muzyki wygaszacz ekranu zmienia się w pełnoekranowy ekran „Teraz odtwarzane” z okładką albumu. Gdy nic nie jest odtwarzane, działa zwykły wygaszacz ekranu.';

  @override
  String get settingSendspinFullscreenSplitTitle =>
      'Pokaż obok wygaszacza ekranu';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      'Wygaszacz ekranu pozostaje widoczny obok ekranu „Teraz odtwarzane”. Na ekranach pionowych wygaszacz jest wyświetlany nad odtwarzaczem. Na małych ekranach odtwarzacz nadal zajmuje cały ekran.';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => 'Wypełnij ekran';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      'Zastępuje ustawienie wypełniania ekranu zdjęciem, gdy wygaszacz ekranu dzieli ekran z ekranem „Teraz odtwarzane”. „Domyślne” używa własnego ustawienia każdego wygaszacza. „Wyłączone” pokazuje całe zdjęcie z czarnymi pasami. „Inteligentne” powiększa zdjęcia o proporcjach zbliżonych do ekranu, a pozostałe umieszcza na rozmytym tle. „Zawsze” powiększa każde zdjęcie, obcinając to, co się nie mieści.';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle =>
      'Zastąp jasność wygaszacza ekranu';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      'Używaj zwykłej jasności ekranu zamiast jasności wygaszacza, gdy ekran „Teraz odtwarzane” jest wyświetlany obok wygaszacza ekranu. Zastępuje to też zaplanowaną jasność wygaszacza.';

  @override
  String get mediaScreensaverHeading => 'Wygaszacz ekranu';

  @override
  String get mediaDefaultFill => 'Domyślne';

  @override
  String get mediaFillOff => 'Wyłączone';

  @override
  String get mediaFillSmart => 'Inteligentne';

  @override
  String get mediaFillAlways => 'Zawsze';

  @override
  String get mediaPickPlayer => 'Wybierz odtwarzacz';

  @override
  String get mediaMaPlayer => 'Odtwarzacz Music Assistant';

  @override
  String get mediaHaPlayer => 'Odtwarzacz multimediów Home Assistant';

  @override
  String get mediaSonosRoom => 'Pomieszczenie Sonos';

  @override
  String get mediaSearchPlayers => 'Szukaj odtwarzaczy';

  @override
  String get mediaOffline => 'Offline';

  @override
  String mediaOfflineName(String name) {
    return '$name (offline)';
  }

  @override
  String get mediaSetUpMa =>
      'Skonfiguruj Music Assistant, aby wyświetlić listę jego odtwarzaczy.';

  @override
  String get mediaSetUpHa =>
      'Połącz z Home Assistant, aby wyświetlić listę odtwarzaczy multimediów.';

  @override
  String get mediaSetUpSonos =>
      'Nie znaleziono jeszcze głośników Sonos. Znajdź lub dodaj głośnik na stronie Sonos.';

  @override
  String mediaHaFailed(String error) {
    return 'Brak odpowiedzi od Home Assistant: $error';
  }

  @override
  String get mediaSaveFailed => 'Nie udało się zapisać odtwarzacza.';

  @override
  String get mediaSelectFailed => 'Nie udało się wybrać odtwarzacza';

  @override
  String get mediaNotificationAccessRemote =>
      'Bez tego Android nie wyświetla żadnych sesji multimediów, więc ekran „Teraz odtwarzane” nie może śledzić aplikacji odtwarzających na tym urządzeniu. Ekran przyznawania uprawnienia pojawi się na tablecie.';

  @override
  String get mediaLocalMediaSession => 'Lokalna sesja multimediów';

  @override
  String get settingSendspinEnabledTitle => 'Włącz odtwarzacz Sendspin';

  @override
  String get settingSendspinEnabledDescription =>
      'Zmień to urządzenie w zsynchronizowany odtwarzacz Sendspin. Pojawia się w Music Assistant pod nazwą urządzenia, zsynchronizowany ze wszystkimi innymi głośnikami Sendspin.';

  @override
  String get settingSendspinServerTitle => 'Serwer';

  @override
  String get settingSendspinServerDescription =>
      'Adres serwera Sendspin, na przykład 192.168.1.10:8927. Zostaw puste, aby automatycznie wyszukać serwer w sieci.';

  @override
  String get settingSendspinCodecTitle => 'Preferowany kodek audio';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC jest bezstratny i idealny w sieci Wi-Fi lub Ethernet. Ostateczny wybór spośród kodeków oferowanych przez to urządzenie należy do serwera.';

  @override
  String get settingSendspinSyncOffsetTitle =>
      'Przesunięcie synchronizacji dźwięku (ms)';

  @override
  String get settingSendspinSyncOffsetDescription =>
      'Wartość ujemna przyspiesza odtwarzanie na tym urządzeniu, dla głośników opóźnionych względem grupy (Bluetooth). Dostrój na słuch, zmiana działa na bieżąco.';

  @override
  String get settingSendspinGroupVolumeDescription =>
      'Gdy to urządzenie gra w grupie, suwak głośności ustawia głośność całej grupy. Po wyłączeniu tylko tego urządzenia. Wymaga połączenia z Music Assistant.';

  @override
  String get settingSendspinMasterVolumeTitle => 'Steruj głośnością urządzenia';

  @override
  String get settingSendspinMasterVolumeDescription =>
      'Music Assistant ustawia głośność zmienianą przyciskami głośności zamiast głośności multimediów. Dźwięki asystenta również się do niej dostosowują.';

  @override
  String get mediaSendspinPage => 'Odtwarzacz Sendspin';

  @override
  String get mediaSendspinHint =>
      'Zmień to urządzenie w zsynchronizowany odtwarzacz Music Assistant';

  @override
  String get mediaFlac => 'FLAC (bezstratny)';

  @override
  String get mediaOpus => 'Opus (wydajny)';

  @override
  String get mediaPcm => 'PCM (bez kompresji)';

  @override
  String get settingSendspinSonosGroupVolumeTitle => 'Dostosuj głośność grupy';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      'Gdy monitorowane pomieszczenie odtwarza dźwięk w ramach grupy, suwak głośności ustawia głośność całej grupy. Gdy opcja jest wyłączona, suwak reguluje tylko głośność tego pomieszczenia.';

  @override
  String get settingSendspinSonosInputsTitle =>
      'Pokaż telewizor i wejście liniowe';

  @override
  String get settingSendspinSonosInputsDescription =>
      'Pokazuj aktywność w odtwarzaczu multimediów, gdy aktywne są wejścia eARC lub liniowe.';

  @override
  String get mediaSonosHint => 'Głośniki w sieci, dodaj głośnik po adresie';

  @override
  String get mediaSonosSpeakers => 'Głośniki';

  @override
  String get mediaSonosNoneFound => 'Nie znaleziono głośników Sonos';

  @override
  String get mediaSonosDiscoveryEmpty =>
      'W tej sieci nic nie odpowiedziało. Dodaj głośnik po adresie.';

  @override
  String get mediaSonosAddTitle => 'Dodaj głośnik Sonos po adresie';

  @override
  String get mediaSonosLooking => 'Wyszukiwanie…';

  @override
  String get mediaSonosEmpty => 'Brak głośników';

  @override
  String get mediaSonosEmptyHelp =>
      'Przeszukaj tę sieć lub dodaj głośnik po jego adresie.';

  @override
  String get mediaSonosForget => 'Zapomnij';

  @override
  String get mediaSonosSearchTitle => 'Przeszukaj sieć';

  @override
  String get mediaSonosSearchHelp =>
      'Wyszukuje głośniki Sonos w tej sieci. Aby zostały wykryte automatycznie, głośniki muszą być w tej samej sieci VLAN co to urządzenie.';

  @override
  String get mediaSonosSearch => 'Szukaj';

  @override
  String get mediaSonosSearching => 'Wyszukiwanie…';

  @override
  String get mediaSonosAddAddress => 'Dodaj po adresie';

  @override
  String get mediaSonosAddressHelp =>
      'Adres głośnika w sieci. Na jego podstawie dodawane jest całe gospodarstwo domowe Sonos.';

  @override
  String get mediaSonosPickRoom =>
      'Wybierz pokój w ustawieniu „Źródło odtwarzacza”, Sonos.';

  @override
  String get mediaSonosAdded => 'Dodano głośnik Sonos';

  @override
  String get mediaSonosNoRooms => 'Głośnik nie zwrócił żadnych pokoi.';

  @override
  String get mediaSonosNoAddress => 'brak adresu';

  @override
  String mediaSonosUnreachable(String host) {
    return 'Pod adresem $host nie odpowiedział żaden głośnik Sonos.';
  }

  @override
  String get settingsMenuHomeAssistant => 'Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary =>
      'Połączenie, pulpit, tryb kiosku';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary =>
      'Słowo wybudzające, nasłuchiwanie w tle';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary => 'Natywne encje i proxy Bluetooth';

  @override
  String get settingsMenuScreenAudio => 'Ekran i dźwięk';

  @override
  String get settingsMenuScreenAudioSummary => 'Jasność, głośność, mikrofon';

  @override
  String get settingsMenuScreensaver => 'Wygaszacz ekranu';

  @override
  String get settingsMenuScreensaverSummary =>
      'Bezczynność, tryby, wybudzanie ruchem';

  @override
  String get settingsMenuBrowser => 'Przeglądanie stron';

  @override
  String get settingsMenuBrowserSummary =>
      'Pamięć podręczna, SSL, powiększenie';

  @override
  String get settingsMenuMediaPlayer => 'Odtwarzacz multimediów';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant, Sendspin, Sonos';

  @override
  String get settingsMenuDlna => 'Renderer DLNA';

  @override
  String get settingsMenuDlnaSummary =>
      'Zdalne odtwarzanie obrazów, filmów i dźwięku';

  @override
  String get settingsMenuIntercom => 'Interkom';

  @override
  String get settingsMenuIntercomSummary => 'Rozmowy między kioskami';

  @override
  String get settingsMenuCamera => 'Kamera';

  @override
  String get settingsMenuCameraSummary =>
      'Kamera urządzenia, ruch, strumieniowanie';

  @override
  String get settingsMenuCameraStreams => 'Strumienie kamer';

  @override
  String get settingsMenuCameraStreamsSummary =>
      'Kamery Go2RTC i Home Assistant';

  @override
  String get settingsMenuKiosk => 'Tryb kiosku';

  @override
  String get settingsMenuKioskSummary =>
      'Gest wyjścia, PIN, przyciski sprzętowe';

  @override
  String get settingsMenuHomeLauncher => 'Launcher ekranu głównego';

  @override
  String get settingsMenuHomeLauncherSummary =>
      'Zastąp ekran główny urządzenia';

  @override
  String get settingsMenuAppLauncher => 'Launcher aplikacji';

  @override
  String get settingsMenuAppLauncherSummary =>
      'Otwieraj inne aplikacje z kiosku';

  @override
  String get settingsMenuGestures => 'Gesty';

  @override
  String get settingsMenuGesturesSummary => 'Gesty dotyku, dłoni i klaśnięcia';

  @override
  String get settingsMenuDevice => 'Urządzenie';

  @override
  String get settingsMenuDeviceSummary =>
      'Nazwa, motyw aplikacji, dostęp zdalny';

  @override
  String get settingsMenuFleet => 'Zarządzanie flotą';

  @override
  String get settingsMenuFleetSummary => 'Zostań liderem lub członkiem floty';

  @override
  String get settingsMenuPlugins => 'Menedżer wtyczek';

  @override
  String get settingsMenuPluginsSummary => 'Instaluj wtyczki i zarządzaj nimi';

  @override
  String get settingsMenuLogs => 'Logi';

  @override
  String get settingsMenuLogsSummary => 'Logi aplikacji i konsola Web';

  @override
  String get settingsMenuAbout => 'Informacje';

  @override
  String get settingsMenuAboutSummary => 'Wersja, autor, licencja';

  @override
  String get settingsMenuOverview => 'Przegląd';

  @override
  String get settingsMenuOverviewSummary => 'Ekran i szybkie sterowanie';

  @override
  String get settingsMenuLockdown => 'Tryb blokady';

  @override
  String get settingsMenuLockdownSummary => 'Wyłącz interakcje z ekranem';

  @override
  String get settingsMenuFiles => 'Menedżer plików';

  @override
  String get settingsMenuFilesSummary =>
      'Przeglądaj, pobieraj i przesyłaj pliki';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => 'Ekran';

  @override
  String get settingsGroupMediaCameras => 'Multimedia i kamery';

  @override
  String get settingsGroupHousehold => 'Dom';

  @override
  String get settingsGroupKiosk => 'Kiosk';

  @override
  String get settingsGroupSystem => 'System';

  @override
  String get settingsMenuMenu => 'Menu';

  @override
  String get settingsMenuTheme => 'Motyw';

  @override
  String get settingsMenuLogout => 'Wyloguj';

  @override
  String get settingsMenuSwitchKiosk => 'Przełącz kiosk';

  @override
  String settingsMenuThemeState(String theme) {
    return 'Motyw: $theme';
  }

  @override
  String get settingsMenuThemeAuto => 'Automatyczny';

  @override
  String get settingsMenuOverviewHeadlessSummary => 'Stan i szybkie sterowanie';

  @override
  String get settingsMenuHomeAssistantHeadlessSummary => 'Połączenie';

  @override
  String get settingsMenuAudio => 'Dźwięk';

  @override
  String get settingsMenuAudioSummary => 'Głośność, mikrofon';

  @override
  String get settingsGroupMedia => 'Multimedia';

  @override
  String get settingsMenuDlnaHeadlessSummary => 'Zdalne odtwarzanie dźwięku';

  @override
  String get settingsMenuGesturesHeadlessSummary =>
      'Gesty przycisku i klaśnięcia';

  @override
  String get settingsMenuLeds => 'Sterowanie LED';

  @override
  String get settingsMenuLedsSummary => 'Kolory i efekty diod stanu';

  @override
  String get settingsLedTimers => 'Minutniki';

  @override
  String get settingsLedNotifications => 'Powiadomienia';

  @override
  String get settingsLedIdle => 'Bezczynność';

  @override
  String get settingsLedEffects => 'Efekty';

  @override
  String get settingsGroupKioskSatellite => 'Kiosk Satellite';

  @override
  String get settingsMenuNavigation => 'Nawigacja';

  @override
  String get settingsMenuNavigationSummary => 'Klasyczna lub Kompas';

  @override
  String get navigationStyleSection => 'Styl nawigacji';

  @override
  String get navigationLayoutSection => 'Układ Kompasu';

  @override
  String get navigationOptionsSection => 'Opcje Kompasu';

  @override
  String get settingNavStyleTitle => 'Styl nawigacji';

  @override
  String get settingNavStyleDescription =>
      'Nawigacja klasyczna zachowuje menu boczne, odświeżanie przeciągnięciem i karuzelę pulpitów. Nawigacja Kompas pozwala przesuwać między widokami ułożonymi w krzyż.';

  @override
  String get settingNavCompassLayoutTitle => 'Układ Kompasu';

  @override
  String get settingNavCompassLayoutViewsDescription =>
      'Maksymalnie dwa widoki z każdej strony. Dodaj kilka widoków pulpitu Home Assistant i po jednym widoku każdego innego rodzaju.';

  @override
  String get settingNavCompassAnimationTitle => 'Animacja przesuwania';

  @override
  String get settingNavCompassAnimationDescription =>
      'Oddalenie pokazujące sąsiednie widoki lub proste przesunięcie w bok.';

  @override
  String get settingNavCompassPositionTitle =>
      'Pokazuj położenie podczas przesuwania';

  @override
  String get settingNavCompassPositionDescription =>
      'Mała mapa bieżącego położenia.';

  @override
  String get settingNavCompassReturnMinutesTitle => 'Powrót do środka';

  @override
  String get settingNavCompassReturnMinutesDescription =>
      'Po takim czasie braku dotyku następuje powrót do widoku głównego. Ustaw 0, aby pozostać w bieżącym widoku.';

  @override
  String get settingNavCompassMenuItemsTitle => 'Elementy menu';

  @override
  String get settingNavQuickControlsItemsDescription =>
      'Zawartość widoku Szybkie sterowanie. Wspólna z menu bocznym.';

  @override
  String get navigationClassic => 'Klasyczna';

  @override
  String get navigationCompass => 'Kompas';

  @override
  String get navigationZoom => 'Powiększenie';

  @override
  String get navigationSlide => 'Przesunięcie';

  @override
  String get compassClassicViewHint => 'Widok Home Assistant z menu bocznym.';

  @override
  String get compassCompassHint =>
      'Przesuwaj między widokami ułożonymi w krzyż.';

  @override
  String get compassLayoutViewsHint =>
      'Maksymalnie dwa widoki z każdej strony. Dodaj kilka widoków pulpitu Home Assistant i po jednym widoku każdego innego rodzaju. Dotknij widoku, aby go zmienić, także środkowego.';

  @override
  String get compassOffNote =>
      'Gdy Kompas jest włączony, odświeżanie przeciągnięciem, karuzela pulpitów i przesunięcie od krawędzi otwierające menu boczne są wyłączone.';

  @override
  String get settingOffUnderCompass =>
      'Wyłączone, gdy włączona jest nawigacja Kompas.';

  @override
  String get compassQuickControlsView => 'Szybkie sterowanie';

  @override
  String get compassHomeDashboard => 'Home Assistant';

  @override
  String get compassAppLauncher => 'Launcher aplikacji';

  @override
  String get compassCenter => 'Środek';

  @override
  String get compassAddTile => 'Dodaj';

  @override
  String get compassAddView => 'Dodaj widok';

  @override
  String get compassMoveIn => 'Przesuń bliżej';

  @override
  String get compassMoveOut => 'Przesuń dalej';

  @override
  String get compassReplace => 'Zamień';

  @override
  String get compassRemove => 'Usuń';

  @override
  String get compassChange => 'Zmień';

  @override
  String get compassSideUp => 'U góry';

  @override
  String get compassSideRight => 'Po prawej';

  @override
  String get compassSideDown => 'Na dole';

  @override
  String get compassSideLeft => 'Po lewej';

  @override
  String compassFirstView(String side) {
    return '$side, pierwszy widok';
  }

  @override
  String compassSecondView(String side) {
    return '$side, drugi widok';
  }

  @override
  String get compassAddAbove => 'Dodaj widok powyżej';

  @override
  String get compassAddBelow => 'Dodaj widok poniżej';

  @override
  String get compassAddLeft => 'Dodaj widok po lewej';

  @override
  String get compassAddRight => 'Dodaj widok po prawej';

  @override
  String get compassChangeCenter => 'Zmień widok środkowy';

  @override
  String compassReplaceTitle(String name) {
    return 'Zamień „$name”';
  }

  @override
  String get compassKindDashboard => 'Pulpit Home Assistant';

  @override
  String get compassKindDashboardHint =>
      'Dowolny widok, własne strony i strony aplikacji';

  @override
  String get compassKindTaken => 'Już umieszczono';

  @override
  String get compassKindUnavailable => 'Nie skonfigurowano w tym kiosku';

  @override
  String get compassKioskLocked => 'Kiosk zablokowany';

  @override
  String get compassQuickControls => 'Opcje szybkiego sterowania';

  @override
  String get compassOpen => 'Otwórz';

  @override
  String get compassStateOn => 'Włączone';

  @override
  String get compassStateOff => 'Wyłączone';

  @override
  String get compassHoldMode => 'Tryb wstrzymania';

  @override
  String get settingsMenuGroundControl => 'Ground Control';

  @override
  String get settingsMenuGroundControlFeatures => 'Voice Match i Vision Match';

  @override
  String get settingAdaptiveBrightnessTitle => 'Jasność adaptacyjna';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Przyciemnia ekran, gdy w pomieszczeniu robi się ciemniej, korzystając z czujnika oświetlenia otoczenia.';

  @override
  String get settingAdaptiveUseEntityTitle => 'Użyj encji Home Assistant';

  @override
  String get settingAdaptiveUseEntityDescription =>
      'Odczytuje poziom światła w pomieszczeniu z czujnika Home Assistant.';

  @override
  String get settingAdaptiveLightEntityTitle => 'Encja czujnika światła';

  @override
  String get settingAdaptiveLightEntityDescription =>
      'Czujnik Home Assistant, który podaje poziom światła w luksach.';

  @override
  String get settingAdaptiveMinBrightnessTitle => 'Minimalna jasność';

  @override
  String get settingAdaptiveMinBrightnessDescription =>
      'Jasność ekranu w ciemnym pomieszczeniu.';

  @override
  String get settingAdaptiveMaxBrightnessTitle => 'Maksymalna jasność';

  @override
  String get settingAdaptiveMaxBrightnessDescription =>
      'Jasność ekranu w jasnym pomieszczeniu.';

  @override
  String get settingAdaptiveDarkLuxTitle => 'Ciemne pomieszczenie (lx)';

  @override
  String get settingAdaptiveDarkLuxDescription =>
      'Przy tym poziomie światła lub niższym ekran ma jasność z ustawienia „Minimalna jasność”.';

  @override
  String get settingAdaptiveBrightLuxTitle => 'Jasne pomieszczenie (lx)';

  @override
  String get settingAdaptiveBrightLuxDescription =>
      'Przy tym poziomie światła lub wyższym ekran ma jasność z ustawienia „Maksymalna jasność”.';

  @override
  String get screenAudioAdaptiveHint =>
      'Śledzi światło w pomieszczeniu za pomocą czujnika oświetlenia otoczenia';

  @override
  String get screenAudioAdaptiveNote =>
      'Poziom w jasnym pomieszczeniu. Jasność adaptacyjna przyciemnia ekran od tego poziomu.';

  @override
  String get screenAudioAdaptiveOwns => 'Jasność adaptacyjna jest włączona.';

  @override
  String get screenAudioNoSensor =>
      'To urządzenie nie ma czujnika oświetlenia otoczenia.';

  @override
  String get screenAudioAmbientLight => 'Światło otoczenia';

  @override
  String get screenAudioAmbientHelp =>
      'Bieżący odczyt czujnika oświetlenia otoczenia.';

  @override
  String get screenAudioNoReading => 'Brak odczytu';

  @override
  String screenAudioLux(String lux) {
    return '$lux lx';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux lx (ostatni odczyt)';
  }

  @override
  String get screenAudioSetsMaximum =>
      'Ustawia wartość „Maksymalna jasność”: jasność adaptacyjna jest włączona.';

  @override
  String get screenAudioSetsDefault => 'Ustawia wartość „Domyślna jasność”.';

  @override
  String get screenAudioBrightnessCurve => 'Krzywa jasności';

  @override
  String get screenAudioCurveHint =>
      'Przeciągnij punkt lub dotknij go, aby wpisać dokładne wartości. Encja „Screen light” w Home Assistant przesuwa najwyższy punkt, a krzywa podąża za nim.';

  @override
  String screenAudioCurvePoint(String number) {
    return 'Punkt $number';
  }

  @override
  String get screenAudioCurveLightLevel => 'Poziom światła (lx)';

  @override
  String get screenAudioCurveBrightness => 'Jasność (%)';

  @override
  String screenAudioCurveLuxRange(String low, String high) {
    return 'Wpisz poziom światła od $low do $high lx';
  }

  @override
  String screenAudioCurveLevelRange(String low, String high) {
    return 'Wpisz jasność od $low% do $high%';
  }

  @override
  String get settingAdaptiveVolumeTitle => 'Włącz głośność adaptacyjną';

  @override
  String get settingAdaptiveVolumeDescription =>
      'Ścisza dźwięk, gdy w pomieszczeniu robi się ciszej, korzystając z mikrofonu.';

  @override
  String get settingAdaptiveVolumeAssistantTitle => 'Asystent';

  @override
  String get settingAdaptiveVolumeAssistantDescription =>
      'Odpowiedzi głosowe i sygnały dźwiękowe.';

  @override
  String get settingAdaptiveVolumeMediaTitle => 'Multimedia';

  @override
  String get settingAdaptiveVolumeMediaDescription =>
      'Muzyka i wideo. Ustawiana na początku odtwarzania.';

  @override
  String get settingAdaptiveVolumeIntercomTitle => 'Interkom';

  @override
  String get settingAdaptiveVolumeIntercomDescription =>
      'Połączenia. Ustawiana na początku połączenia.';

  @override
  String get settingAdaptiveVolumeCurveTitle => 'Krzywa głośności';

  @override
  String get settingAdaptiveVolumeCurveSliderDescription =>
      'Głośność przy każdym poziomie hałasu w pomieszczeniu wyrażona jako procent suwaka tej głośności w sekcji „Ekran i dźwięk”.';

  @override
  String get screenAudioAdaptiveVolume => 'Głośność adaptacyjna';

  @override
  String get screenAudioAdaptiveVolumeHint =>
      'Śledzi hałas w pomieszczeniu za pomocą mikrofonu';

  @override
  String get screenAudioAdaptiveVolumes => 'Głośności';

  @override
  String get screenAudioRoomNoise => 'Hałas w pomieszczeniu';

  @override
  String get screenAudioRoomNoiseNote =>
      'Odczyt mikrofonu, gdy to urządzenie nie odtwarza dźwięku.';

  @override
  String get screenAudioRoomNoiseHolds =>
      'Odczyt jest wstrzymany, gdy to urządzenie odtwarza dźwięk. Zmiany w pomieszczeniu podczas odtwarzania nie są uwzględniane.';

  @override
  String get screenAudioRoomNoiseNoReading =>
      'Jeśli nie ma odczytu, włącz głośność adaptacyjną lub wykrywanie słowa wybudzającego i sprawdź, czy mikrofon nie jest wyciszony.';

  @override
  String screenAudioDbfs(String level) {
    return '$level dBFS';
  }

  @override
  String get screenAudioVolumeCurveSliderHint =>
      'Przeciągnij punkt lub dotknij go, aby wpisać dokładne wartości. Wartości procentowe odnoszą się do suwaków głośności asystenta, multimediów i interkomu w sekcji „Ekran i dźwięk”: 100% oznacza odtwarzanie na poziomie ustawionym przez suwak, a 50% odtwarzanie tak, jakby suwak był ustawiony na połowę.';

  @override
  String get screenAudioVolumeCurveNoise => 'Hałas w pomieszczeniu (dBFS)';

  @override
  String get screenAudioVolumeCurveAssistant => 'Asystent (%)';

  @override
  String get screenAudioVolumeCurveMedia => 'Multimedia (%)';

  @override
  String get screenAudioVolumeCurveIntercom => 'Interkom (%)';

  @override
  String screenAudioVolumeCurveNoiseRange(String low, String high) {
    return 'Wpisz poziom hałasu od $low do $high dBFS';
  }

  @override
  String screenAudioVolumeCurveLevelRange(String low, String high) {
    return 'Wpisz głośność od $low% do $high%';
  }

  @override
  String get screenAudioVolumeTest => 'Test głośności';

  @override
  String get screenAudioVolumeTestAssistant => 'Sprawdź głośność asystenta';

  @override
  String get screenAudioVolumeTestAssistantHint =>
      'Odtwarza ogłoszenie Voice Satellite z głośnością asystenta. Wymaga skonfigurowania Voice Satellite w Home Assistant.';

  @override
  String get screenAudioVolumeTestMedia => 'Sprawdź głośność multimediów';

  @override
  String get screenAudioVolumeTestMediaHint =>
      'Odtwarza ogłoszenie ESPHome z głośnością multimediów. Wymaga włączenia opcji „Ogłoszenia” w sekcji ESPHome.';

  @override
  String get screenAudioVolumeTestMessage =>
      'Z taką głośnością jest teraz odtwarzane ogłoszenie.';

  @override
  String get settingAudioMicDeviceTitle => 'Mikrofon';

  @override
  String get settingAudioMicDeviceDescription =>
      'Mikrofon, z którego korzystają wykrywanie słowa wybudzającego i polecenia głosowe.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Głośnik';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Wyjście dźwięków Voice Satellite; multimedia są odtwarzane przez wyjście wybrane w systemie.';

  @override
  String get screenAudioDevices => 'Urządzenia audio';

  @override
  String get screenAudioSelectedDevice => 'Wybrane urządzenie';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (nie połączono)';
  }

  @override
  String get settingEqualizerEnabledTitle => 'Włącz korektor';

  @override
  String get settingEqualizerEnabledDescription =>
      'Kształtuje brzmienie muzyki, asystenta, sygnałów dźwiękowych i interkomu. Dźwięki filmów i pulpitu nie przechodzą przez korektor.';

  @override
  String get settingEqualizerBand1Title => '100 Hz';

  @override
  String get settingEqualizerBand1Description =>
      'Bas. Małe głośniki szybko zniekształcają dźwięk przy podbiciu tego pasma.';

  @override
  String get settingEqualizerBand2Title => '300 Hz';

  @override
  String get settingEqualizerBand2Description =>
      'Niskie średnie tony. Obniżenie usuwa brzmienie jak z pudełka lub dudnienie.';

  @override
  String get settingEqualizerBand3Title => '1 kHz';

  @override
  String get settingEqualizerBand3Description =>
      'Średnie tony, w których mieści się większość głosu.';

  @override
  String get settingEqualizerBand4Title => '3 kHz';

  @override
  String get settingEqualizerBand4Description =>
      'Wysokie średnie tony. Podbicie poprawia zrozumiałość mowy.';

  @override
  String get settingEqualizerBand5Title => '10 kHz';

  @override
  String get settingEqualizerBand5Description => 'Wysokie tony.';

  @override
  String get settingEqualizerPreampTitle => 'Automatyczny przedwzmacniacz';

  @override
  String get settingEqualizerPreampDescription =>
      'Obniża poziom o wartość największego podbicia, aby głośnik nie zniekształcał dźwięku, a funkcja eliminacji echa nadal działała.';

  @override
  String get screenAudioEqualizer => 'Korektor';

  @override
  String get screenAudioEqualizerHint =>
      'Bas, średnie i wysokie tony, przedwzmacniacz';

  @override
  String get settingMicCaptureModeTitle => 'Tryb przechwytywania';

  @override
  String get settingMicCaptureModeDescription =>
      'Wybierz „Komunikacja głosowa”, kiedy mikrofon przestanie działać w tym miejscu lub gdy przestanie działać po odtworzeniu dźwięku przez kiosk. Niektóre urządzenia nagrywają poprawnie tylko przez ścieżkę audio połączenia.';

  @override
  String get settingMicSoftwareEchoCancellationTitle => 'Usuwanie echa';

  @override
  String get settingMicSoftwareEchoCancellationDescription =>
      'Usuwa z mikrofonu dźwięki odtwarzane przez kiosk, aby nie słyszało ich wykrywanie słowa wybudzającego ani asystent. Pozostaw włączone, chyba że mikrofon z własnym usuwaniem echa brzmi z tą funkcją gorzej.';

  @override
  String get settingMicEchoCancellationMethodTitle => 'Metoda usuwania echa';

  @override
  String get settingMicEchoCancellationMethodDescription =>
      'Opcja „Automatycznie” testuje GTCRN podczas odtwarzania dźwięków przez kiosk i przełącza się na AEC3, jeśli GTCRN pozostawia zbyt silne echo. Wybierz „Automatycznie”, aby przeprowadzić test ponownie.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Tłumienie szumów';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Usuwa szum z mikrofonu. Zmienia to, co słyszy wykrywanie słowa wybudzającego, więc włącz tę opcję tylko dla mikrofonu, który szumi.';

  @override
  String get settingMicChannelTitle => 'Kanał mikrofonu';

  @override
  String get settingMicChannelDescription =>
      'Mikrofony wielokanałowe często rezerwują jeden kanał na rozpoznawanie mowy; wybranie go może poprawić wykrywanie.';

  @override
  String get settingMicGainDbTitle => 'Wzmocnienie mikrofonu';

  @override
  String get settingMicGainDbDescription =>
      'Zwiększ lub zmniejsz wzmocnienie mikrofonu, zanim sygnał zostanie dalej przetworzony. Celuj w poziom około 0.05 w testerze słowa wybudzającego; zbyt duże wzmocnienie zniekształca mowę i pogarsza wykrywanie.';

  @override
  String get settingMicCaptureFormatTitle => 'Format przechwytywania';

  @override
  String get settingMicCaptureFormatDescription =>
      'Wybierz „48 kHz stereo”, gdy mikrofon działa w innych aplikacjach, ale nie tutaj: niektóre karty dźwiękowe nagrywają tylko w tym formacie, a aplikacja sama go konwertuje.';

  @override
  String get screenAudioMicrophoneSettings => 'Ustawienia mikrofonu';

  @override
  String get screenAudioMicrophoneHint =>
      'Usuwanie echa, szumy, wzmocnienie, format, poziom na żywo';

  @override
  String get screenAudioMicrophoneNote =>
      'Dostosuj przechwytywanie do mikrofonu i pomieszczenia. Po zmianie tych ustawień przetestuj słowa wybudzające i interakcje głosowe.';

  @override
  String get screenAudioAutomaticDefault => 'Automatycznie (domyślnie)';

  @override
  String get screenAudioStereo => '48 kHz stereo';

  @override
  String get screenAudioCaptureRawMicrophone =>
      'Surowy sygnał mikrofonu (domyślnie)';

  @override
  String get screenAudioCaptureVoiceCommunication => 'Komunikacja głosowa';

  @override
  String get screenAudioEchoMethodGtcrnDetected => 'GTCRN (wykryto)';

  @override
  String get screenAudioEchoMethodAec3Detected => 'AEC3 (wykryto)';

  @override
  String get screenAudioDownmix => 'Miksowanie kanałów (domyślnie)';

  @override
  String screenAudioChannel(String channel) {
    return 'Kanał $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return 'Kanał $channel (brak w tym mikrofonie)';
  }

  @override
  String get screenAudioMicrophoneLevel => 'Poziom mikrofonu';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      'Mów z miejsca, z którego korzystasz z urządzenia; ustaw wzmocnienie tak, aby normalna mowa sięgała mniej więcej końca zielonego zakresu.';

  @override
  String get settingBrowserCutoutModeTitle => 'Wycięcie ekranu';

  @override
  String get settingBrowserCutoutModeDescription =>
      'Co zrobić z obszarem ekranu wokół wycięcia lub otworu na aparat. Wybierz „Unikaj wycięcia”, jeśli aparat zasłania przyciski u góry pulpitu.';

  @override
  String get settingScreenOrientationTitle => 'Orientacja ekranu';

  @override
  String get settingScreenOrientationDescription =>
      'Wymuś jedną orientację ekranu. Użyj tej opcji na urządzeniu bez czujnika obrotu lub zamontowanym tak, że czujnik źle ją rozpoznaje.';

  @override
  String get settingScreenHideStatusBarTitle => 'Ukryj pasek stanu';

  @override
  String get settingScreenHideStatusBarDescription =>
      'Wyłącz, aby zachować zegar i ikony powiadomień u góry ekranu. Tryb kiosku zawsze go ukrywa.';

  @override
  String get settingScreenHideNavigationBarTitle => 'Ukryj pasek nawigacji';

  @override
  String get settingScreenHideNavigationBarDescription =>
      'Wyłącz, aby zachować przyciski nawigacji na ekranie, a na tabletach także pasek zadań. Tryb kiosku zawsze go ukrywa.';

  @override
  String get settingScreenShowOnLockScreenTitle => 'Pokazuj na ekranie blokady';

  @override
  String get settingScreenShowOnLockScreenDescription =>
      'Wyświetlaj pulpit nad ekranem blokady z PIN-em, wzorem lub hasłem. Reszta urządzenia pozostaje zablokowana.';

  @override
  String get settingKeepScreenOnTitle => 'Nie wyłączaj ekranu';

  @override
  String get settingKeepScreenOnDescription =>
      'Nie pozwalaj systemowi wyłączać ekranu.';

  @override
  String get settingSetBrightnessOnLaunchTitle =>
      'Ustaw jasność przy uruchomieniu';

  @override
  String get settingSetBrightnessOnLaunchDescription =>
      'Stosuj domyślną jasność przy każdym uruchomieniu aplikacji.';

  @override
  String get settingDefaultBrightnessTitle => 'Domyślna jasność';

  @override
  String get settingDefaultBrightnessDescription =>
      'Jasność ekranu ustawiana po uruchomieniu aplikacji. Przesunięcie suwaka od razu ją zmienia.';

  @override
  String get screenAudioScreen => 'Ekran';

  @override
  String get screenAudioCutoutAlways => 'Użyj obszaru wycięcia';

  @override
  String get screenAudioCutoutShort => 'Tylko krótkie krawędzie';

  @override
  String get screenAudioCutoutDefault => 'Ustawienie systemowe';

  @override
  String get screenAudioCutoutNever => 'Unikaj wycięcia';

  @override
  String get screenAudioAutomatic => 'Automatyczna';

  @override
  String get screenAudioLandscape => 'Pozioma';

  @override
  String get screenAudioReverseLandscape => 'Pozioma odwrócona';

  @override
  String get screenAudioPortrait => 'Pionowa';

  @override
  String get screenAudioReversePortrait => 'Pionowa odwrócona';

  @override
  String get screenAudioPermission => 'Uprawnienie';

  @override
  String get screenAudioBrightnessFallback =>
      'Jasność działa w trybie zastępczym';

  @override
  String get screenAudioBrightnessPermission =>
      'Bez uprawnienia „Modyfikowanie ustawień systemu” zmiana jasności tylko przyciemnia tę aplikację zamiast ustawiać rzeczywistą jasność panelu.';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      'Bez uprawnienia „Modyfikowanie ustawień systemu” zmiana jasności tylko przyciemnia aplikację zamiast ustawiać rzeczywistą jasność panelu.';

  @override
  String get screenAudioAlwaysOn => 'Wyświetlacz zawsze włączony';

  @override
  String get screenAudioAlwaysOnClock =>
      'Urządzenie stale wyświetla przygaszony zegar';

  @override
  String get screenAudioAlwaysOnHelp =>
      'Wyłączenie ekranu usypia urządzenie, ale wyświetlacz zawsze włączony ponownie podświetla ekran blokady i żadna aplikacja nie może temu zapobiec. Wyłącz „Zawsze pokazuj godzinę i informacje” w ustawieniach Androida w sekcji „Wyświetlacz”, obok opcji ekranu blokady. W niektórych ROM-ach ta opcja nazywa się „Wyświetlacz zawsze włączony”. Encja ekranu w Home Assistant pozostaje niedostępna, dopóki tego nie zrobisz.';

  @override
  String get settingMediaVolumeTitle => 'Głośność multimediów';

  @override
  String get settingMediaVolumeDescription =>
      'Muzyka i filmy są odtwarzane z takim procentem głośności głównej. Głośność odtwarzacza Sendspin w Music Assistant przesuwa ten suwak.';

  @override
  String get settingAssistantVolumeTitle => 'Głośność asystenta';

  @override
  String get settingAssistantVolumeDescription =>
      'Odpowiedzi głosowe i sygnały dźwiękowe są odtwarzane z takim procentem głośności głównej, niezależnie od głośności multimediów.';

  @override
  String get settingIntercomVolumeTitle => 'Głośność interkomu';

  @override
  String get settingIntercomVolumeDescription =>
      'Głos z drugiego kiosku i ogłoszenia są odtwarzane z takim procentem głośności głównej.';

  @override
  String get screenAudioVolume => 'Głośność dźwięku';

  @override
  String get screenAudioMasterVolume => 'Głośność główna';

  @override
  String get screenAudioMasterHelp =>
      'Głośność urządzenia. Głośność multimediów, interkomu i asystenta jest skalowana względem niej.';

  @override
  String get settingScreensaverBlackHideExtrasTitle =>
      'Ukryj wszystkie dodatki';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      'Ekran pozostaje całkowicie czarny: bez małego zegara, encji „W skrócie” ani innych nakładek.';

  @override
  String get screensaverBlackSection => 'Wygaszacz „Czarny ekran”';

  @override
  String get settingScreensaverCelestialLocationTitle => 'Lokalizacja';

  @override
  String get settingScreensaverCelestialLocationDescription =>
      'Miejsce, z którego widać niebo.';

  @override
  String get settingScreensaverCelestialEntityTitle => 'Encja';

  @override
  String get settingScreensaverCelestialEntityDescription =>
      'Osoba, urządzenie śledzące lub strefa z lokalizacją.';

  @override
  String get settingScreensaverCelestialCoordinatesTitle => 'Współrzędne';

  @override
  String get settingScreensaverCelestialCoordinatesDescription =>
      'Szerokość i długość geograficzna, np. 40.71, -74.01.';

  @override
  String get settingScreensaverCelestialTerrainTitle => 'Krajobraz';

  @override
  String get settingScreensaverCelestialTerrainDescription =>
      'Teren wzdłuż horyzontu.';

  @override
  String get settingScreensaverCelestialFollowDeviceTitle => 'Skieruj na niebo';

  @override
  String get settingScreensaverCelestialFollowDeviceDescription =>
      'Unieś urządzenie, a niebo na ekranie obróci się razem z nim, dzięki czemu rozpoznasz, na co patrzysz. Wymaga czujnika kompasu.';

  @override
  String get settingScreensaverCelestialDaytimeTitle => 'Niebo w ciągu dnia';

  @override
  String get settingScreensaverCelestialDaytimeDescription =>
      'Rozjaśnij niebo i przygaś gwiazdy, gdy Słońce jest nad horyzontem. Wyłącz, aby przez cały dzień pokazywać nocne niebo.';

  @override
  String get settingScreensaverCelestialMilkyWayTitle => 'Droga Mleczna';

  @override
  String get settingScreensaverCelestialMilkyWayDescription =>
      'Pokaż poświatę naszej galaktyki na nocnym niebie.';

  @override
  String get settingScreensaverCelestialPlanetsTitle => 'Planety';

  @override
  String get settingScreensaverCelestialPlanetsDescription =>
      'Pokaż planety w miejscach, w których są dziś w nocy.';

  @override
  String get settingScreensaverCelestialDeepSkyTitle => 'Galaktyki i mgławice';

  @override
  String get settingScreensaverCelestialDeepSkyDescription =>
      'Pokaż Galaktykę Andromedy, Mgławicę Oriona i inne obiekty widoczne bez teleskopu.';

  @override
  String get settingScreensaverCelestialLightPollutionTitle =>
      'Zanieczyszczenie światłem';

  @override
  String get settingScreensaverCelestialLightPollutionDescription =>
      'Symuluj łunę świateł miasta. Wyższe wartości powodują, że słabiej świecące gwiazdy i Droga Mleczna stają się niewidoczne.';

  @override
  String get settingScreensaverCelestialTwinkleTitle => 'Migoczące gwiazdy';

  @override
  String get settingScreensaverCelestialTwinkleDescription =>
      'Pozwól gwiazdom migotać, najbardziej przy horyzoncie. Wyłącz, aby oszczędzać energię.';

  @override
  String get settingScreensaverCelestialLargeMoonTitle => 'Większy Księżyc';

  @override
  String get settingScreensaverCelestialLargeMoonDescription =>
      'Pokazuj Księżyc trzy razy większy niż w rzeczywistości, a Słońce dwa razy większe, tak aby łatwo było dostrzec fazę.';

  @override
  String get settingScreensaverCelestialLinesTitle => 'Linie gwiazdozbiorów';

  @override
  String get settingScreensaverCelestialLinesDescription =>
      'Połącz gwiazdy każdego gwiazdozbioru.';

  @override
  String get settingScreensaverCelestialConstellationNamesTitle =>
      'Nazwy gwiazdozbiorów';

  @override
  String get settingScreensaverCelestialConstellationNamesDescription =>
      'Podpisz gwiazdozbiory. Im bardziej powiększasz obraz, tym więcej gwiazdozbiorów otrzymuje nazwy.';

  @override
  String get settingScreensaverCelestialNamesTitle => 'Nazwy gwiazd i planet';

  @override
  String get settingScreensaverCelestialNamesDescription =>
      'Podpisz Słońce, Księżyc, planety, najjaśniejsze gwiazdy i galaktyki. Im bardziej powiększasz obraz, tym więcej gwiazd otrzymuje nazwy.';

  @override
  String get settingScreensaverCelestialCompassTitle => 'Kierunki świata';

  @override
  String get settingScreensaverCelestialCompassDescription =>
      'Zaznacz północ, wschód, południe i zachód na horyzoncie.';

  @override
  String get settingScreensaverCelestialLabelScaleTitle => 'Rozmiar etykiet';

  @override
  String get settingScreensaverCelestialLabelScaleDescription =>
      'Skaluj etykiety na niebie w zakresie od 50 do 200 procent.';

  @override
  String get settingScreensaverCelestialControlCoordinatesTitle => 'Położenie';

  @override
  String get settingScreensaverCelestialControlCoordinatesDescription =>
      'Pokaż szerokość i długość geograficzną miejsca, z którego widać niebo.';

  @override
  String get settingScreensaverCelestialControlAzimuthTitle => 'Azymut';

  @override
  String get settingScreensaverCelestialControlAzimuthDescription =>
      'Pokaż kierunek świata, w którym zwrócony jest środek ekranu.';

  @override
  String get settingScreensaverCelestialControlAltitudeTitle => 'Wysokość';

  @override
  String get settingScreensaverCelestialControlAltitudeDescription =>
      'Pokaż, jak wysoko nad horyzontem jest środek ekranu.';

  @override
  String get settingScreensaverCelestialControlFovTitle => 'Pole widzenia';

  @override
  String get settingScreensaverCelestialControlFovDescription =>
      'Pokaż w stopniach, jaką część nieba obejmuje ekran.';

  @override
  String get settingScreensaverCelestialControlTimeTitle => 'Czas';

  @override
  String get settingScreensaverCelestialControlTimeDescription =>
      'Pokaż czas wyświetlanego nieba oraz przycisk „Teraz” po przyspieszeniu czasu.';

  @override
  String get settingScreensaverCelestialControlTimelapseTitle =>
      'Przyspieszony czas';

  @override
  String get settingScreensaverCelestialControlTimelapseDescription =>
      'Przyspiesz czas, aby zobaczyć, jak obraca się niebo. Dotknij, aby zmienić prędkość.';

  @override
  String get settingScreensaverCelestialControlPointAtSkyTitle =>
      'Przełącznik „Skieruj na niebo”';

  @override
  String get settingScreensaverCelestialControlPointAtSkyDescription =>
      'Włączaj i wyłączaj „Skieruj na niebo”. Widoczny tylko na urządzeniach z kompasem.';

  @override
  String get settingScreensaverCelestialControlMoonPhaseTitle =>
      'Faza Księżyca';

  @override
  String get settingScreensaverCelestialControlMoonPhaseDescription =>
      'Pokaż fazę Księżyca oraz to, jaka część jego powierzchni jest oświetlona.';

  @override
  String get settingScreensaverCelestialControlScaleTitle =>
      'Rozmiar elementów sterujących';

  @override
  String get settingScreensaverCelestialControlScaleDescription =>
      'Skaluj elementy sterujące od 50 do 200 procent.';

  @override
  String get screensaverModeCelestial => 'Niebo';

  @override
  String get screensaverCelestialTerrainHills => 'Wzgórza';

  @override
  String get screensaverCelestialTerrainMountains => 'Góry';

  @override
  String get screensaverCelestialTerrainPlains => 'Równiny';

  @override
  String get screensaverCelestialTerrainNone => 'Brak';

  @override
  String get screensaverCelestialLocationGps => 'GPS';

  @override
  String get screensaverCelestialLocationHaHome => 'Dom w Home Assistant';

  @override
  String get screensaverCelestialLocationHaEntity => 'Encja Home Assistant';

  @override
  String get screensaverCelestialLocationManual => 'Ręcznie';

  @override
  String get screensaverCelestialCurrentLocation => 'Bieżąca lokalizacja';

  @override
  String get screensaverCelestialNoGpsReceiver =>
      'To urządzenie nie ma odbiornika GPS.';

  @override
  String get screensaverCelestialLocationPermission =>
      'Nie przyznano uprawnienia do lokalizacji.';

  @override
  String get screensaverCelestialNoGpsFix =>
      'Nie ustalono jeszcze pozycji GPS.';

  @override
  String get screensaverCelestialNoHomeZone =>
      'W Home Assistant brak strefy domowej.';

  @override
  String get screensaverCelestialHaNotConnected =>
      'Brak połączenia z Home Assistant.';

  @override
  String get screensaverCelestialPickEntity => 'Wybierz encję z lokalizacją.';

  @override
  String get screensaverCelestialEntityNoLocation =>
      'Ta encja nie ma lokalizacji.';

  @override
  String get screensaverCelestialPage => 'Wygaszacz ekranu „Niebo”';

  @override
  String get screensaverCelestialSummary =>
      'Lokalizacja, krajobraz, niebo, etykiety, elementy sterujące';

  @override
  String get screensaverCelestialSkyGroup => 'Niebo';

  @override
  String get screensaverCelestialLabelsGroup => 'Etykiety';

  @override
  String get screensaverCelestialControlsGroup => 'Elementy sterujące';

  @override
  String get screensaverCelestialLocationGrantMissing =>
      'Bez tego uprawnienia nie można odczytać odbiornika GPS, a niebo nie ma lokalizacji.';

  @override
  String get screensaverCelestialLocationGrantReady =>
      'Niebo może podążać za pozycją z odbiornika GPS.';

  @override
  String get screensaverCelestialCoordinatesInvalid =>
      'Wpisz szerokość i długość geograficzną, np. 40.71, -74.01';

  @override
  String get screensaverCelestialNoLocation =>
      'Wybierz lokalizację w: „Ustawienia” > „Wygaszacz ekranu” > „Niebo”.';

  @override
  String get screensaverCelestialWaitingForGps => 'Oczekiwanie na pozycję GPS…';

  @override
  String get screensaverCelestialDoubleTapHint =>
      'Dotknij dwukrotnie, aby zamknąć';

  @override
  String get screensaverCelestialCalibrate =>
      'Aby skalibrować kompas, poruszaj urządzeniem ruchem w kształcie ósemki.';

  @override
  String get celestialSun => 'Słońce';

  @override
  String get celestialMoon => 'Księżyc';

  @override
  String get celestialMercury => 'Merkury';

  @override
  String get celestialVenus => 'Wenus';

  @override
  String get celestialMars => 'Mars';

  @override
  String get celestialJupiter => 'Jowisz';

  @override
  String get celestialSaturn => 'Saturn';

  @override
  String get celestialUranus => 'Uran';

  @override
  String get celestialNeptune => 'Neptun';

  @override
  String get celestialAndromedaGalaxy => 'Galaktyka Andromedy';

  @override
  String get celestialTriangulumGalaxy => 'Galaktyka Trójkąta';

  @override
  String get celestialLargeMagellanicCloud => 'Wielki Obłok Magellana';

  @override
  String get celestialSmallMagellanicCloud => 'Mały Obłok Magellana';

  @override
  String get celestialOrionNebula => 'Mgławica Oriona';

  @override
  String get celestialLagoonNebula => 'Mgławica Laguna';

  @override
  String get celestialCarinaNebula => 'Mgławica Carina';

  @override
  String get celestialPleiades => 'Plejady';

  @override
  String get celestialBeehiveCluster => 'Gromada Żłóbek';

  @override
  String get celestialDoubleCluster => 'Podwójna Gromada';

  @override
  String get celestialOmegaCentauri => 'Omega Centauri';

  @override
  String get celestialTucanae47 => '47 Tucanae';

  @override
  String get celestialCompassNorth => 'N';

  @override
  String get celestialCompassEast => 'E';

  @override
  String get celestialCompassSouth => 'S';

  @override
  String get celestialCompassWest => 'W';

  @override
  String get celestialCompassNorthEast => 'NE';

  @override
  String get celestialCompassSouthEast => 'SE';

  @override
  String get celestialCompassSouthWest => 'SW';

  @override
  String get celestialCompassNorthWest => 'NW';

  @override
  String get celestialAzimuthShort => 'Az';

  @override
  String get celestialAltitudeShort => 'Wys';

  @override
  String get celestialFovShort => 'FOV';

  @override
  String get celestialNow => 'Teraz';

  @override
  String get celestialMoonNew => 'Nów';

  @override
  String get celestialMoonWaxingCrescent => 'Przybywający sierp';

  @override
  String get celestialMoonFirstQuarter => 'Pierwsza kwadra';

  @override
  String get celestialMoonWaxingGibbous => 'Przybywający garb';

  @override
  String get celestialMoonFull => 'Pełnia';

  @override
  String get celestialMoonWaningGibbous => 'Ubywający garb';

  @override
  String get celestialMoonLastQuarter => 'Ostatnia kwadra';

  @override
  String get celestialMoonWaningCrescent => 'Ubywający sierp';

  @override
  String get settingScreensaverClockStyleTitle => 'Styl';

  @override
  String get settingScreensaverClockStyleDescription =>
      'Sposób rysowania zegara.';

  @override
  String get settingScreensaverClockVerticalTitle => 'Tryb pionowy';

  @override
  String get settingScreensaverClockVerticalDescription =>
      'Godziny nad minutami, dla ekranów w orientacji pionowej.';

  @override
  String get settingScreensaverClockFontTitle => 'Rodzina czcionek';

  @override
  String get settingScreensaverClockFontDescription =>
      'Krój czcionki, w którym rysowany jest zegar.';

  @override
  String get settingScreensaverClockFontWeightTitle => 'Grubość czcionki';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      'Grubość cyfr zegara. Opcja „Domyślna” zachowuje własną grubość każdego stylu zegara.';

  @override
  String get settingScreensaverClock24hTitle => 'Zegar 24-godzinny';

  @override
  String get settingScreensaverClock24hDescription =>
      'Pokazuj godzinę w formacie 24-godzinnym zamiast AM/PM.';

  @override
  String get settingScreensaverClockSecondsTitle => 'Pokazuj sekundy';

  @override
  String get settingScreensaverClockSecondsDescription =>
      'Wyświetlaj sekundy na zegarze.';

  @override
  String get settingScreensaverClockDateTitle => 'Pokazuj datę';

  @override
  String get settingScreensaverClockDateDescription =>
      'Wyświetlaj dzień tygodnia i datę pod zegarem.';

  @override
  String get settingScreensaverClockScaleTitle => 'Rozmiar zegara';

  @override
  String get settingScreensaverClockScaleDescription =>
      'Skaluj zegar w zakresie 50-300% na tym ekranie.';

  @override
  String get settingScreensaverClockColorTitle => 'Kolor zegara';

  @override
  String get settingScreensaverClockColorDescription => 'Kolor tekstu zegara.';

  @override
  String get settingScreensaverClockBgColorTitle => 'Kolor tła';

  @override
  String get settingScreensaverClockBgColorDescription =>
      'Kolor tła za zegarem.';

  @override
  String get settingScreensaverClockBackgroundTitle => 'Zdjęcie w tle';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      'Pokazuj zdjęcie za zegarem zamiast jednolitego koloru. Ścieżka do obrazu na urządzeniu lub adres URL obrazu, który pobierze urządzenie.';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle =>
      'Ponowne pobieranie tła z URL';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      'Odstęp w minutach między pobraniami tła z adresu URL. 0 oznacza pobranie tylko przy zapisie ustawienia.';

  @override
  String get settingScreensaverFlipDigitColorTitle => 'Kolor cyfr';

  @override
  String get settingScreensaverFlipDigitColorDescription =>
      'Kolor cyfr na klapkach.';

  @override
  String get settingScreensaverFlipBgColorTitle => 'Kolor klapek';

  @override
  String get settingScreensaverFlipBgColorDescription => 'Kolor klapek.';

  @override
  String get settingScreensaverFlipBackdropColorTitle => 'Kolor tła';

  @override
  String get settingScreensaverFlipBackdropColorDescription =>
      'Kolor tła za klapkami.';

  @override
  String get settingScreensaverRollerDigitColorTitle => 'Kolor cyfr';

  @override
  String get settingScreensaverRollerDigitColorDescription =>
      'Kolor przewijanych cyfr.';

  @override
  String get settingScreensaverRollerBgColorTitle => 'Kolor tła';

  @override
  String get settingScreensaverRollerBgColorDescription =>
      'Kolor tła za cyframi.';

  @override
  String get settingScreensaverHandNumbersTitle => 'Liczby';

  @override
  String get settingScreensaverHandNumbersDescription =>
      'Które godziny są oznaczone liczbami na tarczy.';

  @override
  String get settingScreensaverHandSecondsTitle => 'Pokazuj sekundnik';

  @override
  String get settingScreensaverHandSecondsDescription =>
      'Wyświetlaj wskazówkę sekundową na tarczy.';

  @override
  String get settingScreensaverHandColorTitle => 'Kolor zegara';

  @override
  String get settingScreensaverHandColorDescription =>
      'Kolor wskazówek, liczb i znaczników.';

  @override
  String get settingScreensaverHandBgColorTitle => 'Kolor tła';

  @override
  String get settingScreensaverHandBgColorDescription =>
      'Kolor tła za zegarem.';

  @override
  String get settingScreensaverClockNightTitle => 'Tryb nocny';

  @override
  String get settingScreensaverClockNightDescription =>
      'Zmieniaj kolory zegara, gdy w pomieszczeniu jest ciemno.';

  @override
  String get settingScreensaverClockNightLuxTitle => 'Poziom światła';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      'Przy tym lub niższym poziomie światła zegar przyjmuje kolor nocny.';

  @override
  String get settingScreensaverClockNightColorTitle => 'Kolor nocny';

  @override
  String get settingScreensaverClockNightColorDescription =>
      'Kolor zegara i widżetów w ciemności.';

  @override
  String get settingScreensaverClockNightBgColorTitle => 'Tło nocne';

  @override
  String get settingScreensaverClockNightBgColorDescription =>
      'Kolor tła za zegarem w ciemności.';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle =>
      'Ukryj zdjęcie w tle';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      'Używaj nocnego koloru tła zamiast zdjęcia, gdy tryb nocny jest aktywny.';

  @override
  String get settingScreensaverClockNightHideWidgetsTitle =>
      'Ukryj widżety i „W skrócie”';

  @override
  String get settingScreensaverClockNightHideWidgetsDescription =>
      'Pokazuj tylko zegar, gdy tryb nocny jest aktywny.';

  @override
  String get settingScreensaverClockNightCardColorTitle => 'Nocny kolor klapek';

  @override
  String get settingScreensaverClockNightCardColorDescription =>
      'Kolor klapek w ciemności.';

  @override
  String get screensaverClockSection => 'Wygaszacz ekranu „Zegar”';

  @override
  String get screensaverClockHint =>
      'Styl, czcionka, rozmiar, kolory, tryb nocny, zdjęcie w tle';

  @override
  String get screensaverStyleDigital => 'Zegar cyfrowy';

  @override
  String get screensaverStyleFlip => 'Zegar klapkowy';

  @override
  String get screensaverStyleRoller => 'Zegar bębnowy';

  @override
  String get screensaverStyleHand => 'Zegar wskazówkowy';

  @override
  String get screensaverHandNumbersQuarters => '12, 3, 6 i 9';

  @override
  String get screensaverHandNumbersAll => 'Wszystkie godziny';

  @override
  String get screensaverFontDefault => 'Domyślna';

  @override
  String get screensaverFontLight => 'Cienka';

  @override
  String get screensaverFontRegular => 'Normalna';

  @override
  String get screensaverFontMedium => 'Średnia';

  @override
  String get screensaverFontBold => 'Pogrubiona';

  @override
  String get screensaverFontBlack => 'Bardzo gruba';

  @override
  String get screensaverNoPhoto => 'Nie wybrano zdjęcia';

  @override
  String get screensaverBackgroundHint =>
      'Ścieżka do obrazu na urządzeniu lub adres URL obrazu';

  @override
  String get screensaverImageUrlError => 'Wpisz pełny adres URL obrazu';

  @override
  String get screensaverRefreshError =>
      'Wpisz całkowitą liczbę minut od 0 do 1440';

  @override
  String screensaverMaxCharacters(String count) {
    return 'Maksymalna liczba znaków: $count';
  }

  @override
  String get settingScreensaverClockAmPmTitle => 'Pokazuj AM/PM';

  @override
  String get settingScreensaverClockAmPmDescription =>
      'Dodaje oznaczenie AM lub PM po godzinie.';

  @override
  String get settingScreensaverClockNightTurnOffMinutesTitle =>
      'Wyłączaj ekran w nocy po';

  @override
  String get settingScreensaverClockNightTurnOffMinutesDescription =>
      'Wyłącza ekran, gdy tryb nocny trwa przez ustawiony czas, i włącza go ponownie, gdy w pomieszczeniu zrobi się jaśniej. Ustaw 0, aby ekran pozostał włączony. Wymaga uprawnienia administratora urządzenia.';

  @override
  String get screensaverNightTurnOffWarning =>
      'Gdy wyświetlacz całkowicie się wyłącza, kontrolę przejmuje wbudowany system zarządzania energią tabletu. Wiele modeli z Androidem działa wtedy nieprawidłowo: Wi-Fi przechodzi w uśpienie lub się rozłącza, encje Home Assistant stają się niedostępne, dostęp do kamery może zostać odebrany, a niektóre modele zamykają aplikacje działające w tle. Niektóre czujniki światła przestają też przekazywać odczyty przy wyłączonym wyświetlaczu, więc ekran może nie włączyć się sam, gdy w pomieszczeniu zrobi się jaśniej. Co się stanie, zależy od producenta.\n\nNiezawodną alternatywą jest opcja „Użyj czarnego ekranu”. Panel wygląda równie ciemno, a aplikacja zachowuje pełną kontrolę.';

  @override
  String get screensaverOverlayEntity => 'Encja';

  @override
  String get screensaverOverlayNotSet => 'Nie ustawiono';

  @override
  String get screensaverOverlayName => 'Nazwa';

  @override
  String get screensaverOverlayNameHelp =>
      'Pozostaw puste, aby użyć nazwy z Home Assistant.';

  @override
  String get screensaverOverlayValue => 'Wyświetlana wartość';

  @override
  String get screensaverOverlayState => 'Stan';

  @override
  String get screensaverOverlayEntityRequired => 'Wybierz encję.';

  @override
  String get screensaverOverlaySearching => 'Wyszukiwanie…';

  @override
  String get screensaverOverlayUnreachable =>
      'Nie udało się połączyć z Home Assistant';

  @override
  String get screensaverOverlayNoAnswer => 'Urządzenie nie odpowiedziało.';

  @override
  String get settingScreensaverDismissOnFaceTitle =>
      'Zamykaj po wykryciu twarzy';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      'Wybudza ekran, gdy ktoś patrzy na kiosk, a nie wyłącznie na podstawie wykrycia ruchu. Kamera działa tylko podczas wygaszacza ekranu. UWAGA: wymaga oświetlonej twarzy; w ciemności należy zamiast tego ustawić wykrywanie ruchu.';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle =>
      'Tylko przy wyłączonym ekranie';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      'Wygaszacz ekranu pozostaje widoczny, gdy twarz zostanie wykryta przy włączonym ekranie. Po wyłączeniu ekranu wykrycie twarzy wybudza pulpit. Dotknięcie nadal zamyka wygaszacz.';

  @override
  String get settingScreensaverPostponeOnFaceTitle =>
      'Odraczaj wygaszacz po wykryciu twarzy';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      'Opóźnia włączenie wygaszacza ekranu, gdy ktoś patrzy na kiosk. UWAGA: kamera działa bez przerwy, a wykrywanie twarzy dodatkowo obciąża procesor.';

  @override
  String get settingFaceSensitivityTitle => 'Czułość wykrywania twarzy';

  @override
  String get settingFaceSensitivityDescription =>
      'Wyższa wartość wybudza przy mniejszych, bardziej oddalonych twarzach. 1 wymaga twarzy blisko ekranu; 100 reaguje na każdą twarz, którą kamera rozpozna.';

  @override
  String get screensaverDetectionFacePage => 'Wykrywanie twarzy';

  @override
  String get screensaverDetectionFaceHint =>
      'Zamykaj wygaszacz ekranu, gdy ktoś na niego patrzy';

  @override
  String get screensaverDetectionMotionPrecedence =>
      'Opcja „Zamykaj po wykryciu ruchu” jest włączona i ma pierwszeństwo, więc wykrywanie twarzy pozostaje nieaktywne do czasu jej wyłączenia.';

  @override
  String get screensaverDetectionFaceTuning =>
      'Liczbę klatek na sekundę, wybór kamery i opóźnienie uruchomienia ustawia się w ustawieniach kamery.';

  @override
  String get screensaverDetectionAndroidUnsupported =>
      'Niedostępne w tej wersji Androida.';

  @override
  String get screensaverDetectionX86Unsupported =>
      'Niedostępne na urządzeniach x86.';

  @override
  String get settingScreensaverFaceWhoTitle => 'Wykrywaj twarze';

  @override
  String get settingScreensaverFaceWhoDescription =>
      'Przy opcji Wybrane osoby wygaszacz ekranu zamykają lub odkładają tylko osoby wybrane poniżej.';

  @override
  String get screensaverFaceWhoOptionAnyone => 'Każdy';

  @override
  String get screensaverFaceWhoOptionPeople => 'Wybrane osoby';

  @override
  String get settingScreensaverFacePeopleTitle => 'Osoby';

  @override
  String get settingScreensaverFacePeopleDescription =>
      'Wybierz, kto może zamknąć lub odłożyć wygaszacz ekranu, patrząc na kiosk. Jeśli nikt nie jest wybrany, może to zrobić każda rozpoznana osoba.';

  @override
  String get screensaverFacePeopleNone => 'Każda rozpoznana osoba';

  @override
  String get screensaverGroundControlVisionMatch =>
      'Ground Control Vision Match';

  @override
  String get settingFacePreviewTitle => 'Pokazuj podgląd z kamery';

  @override
  String get settingFacePreviewDescription =>
      'Po wykryciu twarzy, która aktywuje kiosk, w rogu ekranu przez kilka sekund wyświetla się mały, okrągły podgląd na żywo z kamery.';

  @override
  String get settingFacePreviewSecondsTitle => 'Czas podglądu';

  @override
  String get settingFacePreviewSecondsDescription =>
      'Jak długo podgląd pozostaje na ekranie.';

  @override
  String get settingFacePreviewScaleTitle => 'Skalowanie podglądu';

  @override
  String get settingFacePreviewScaleDescription =>
      'Skaluj podgląd, aby lepiej pasował do rozmiaru ekranu.';

  @override
  String get settingFacePreviewPositionTitle => 'Pozycja podglądu';

  @override
  String get settingFacePreviewPositionDescription =>
      'W którym rogu wyświetla się podgląd.';

  @override
  String get screensaverDetectionPreviewSection => 'Podgląd z kamery';

  @override
  String get facePreviewRecognized => 'Rozpoznano';

  @override
  String get settingScreensaverEnabledTitle => 'Wygaszacz ekranu';

  @override
  String get settingScreensaverEnabledDescription =>
      'Przyciemnia lub wygasza ekran po okresie bezczynności.';

  @override
  String get settingScreensaverTimeoutSecondsTitle => 'Czas bezczynności (s)';

  @override
  String get settingScreensaverTimeoutSecondsDescription =>
      'Okres bezczynności, po którym uruchamia się wygaszacz ekranu.';

  @override
  String get settingScreensaverFadeTitle => 'Płynne pojawianie i znikanie';

  @override
  String get settingScreensaverFadeDescription =>
      'Wygaszacz ekranu płynnie pojawia się nad pulpitem i znika po zamknięciu. Nie dotyczy wygaszaczy „Multimedia z Home Assistant”, „Strona internetowa” ani „Obraz z kamer”.';

  @override
  String get settingScreensaverModeTitle => 'Tryb wygaszacza ekranu';

  @override
  String get settingScreensaverModeDescription =>
      'Co pokazuje wygaszacz ekranu po upływie czasu bezczynności. „Przygaszenie” tylko zmniejsza podświetlenie i pozostawia pulpit na ekranie.';

  @override
  String get settingScreensaverPixelShiftTitle => 'Przesuwanie pikseli';

  @override
  String get settingScreensaverPixelShiftDescription =>
      'Co minutę lekko przesuwa obraz, aby chronić panele OLED. Nie dotyczy wygaszacza „Czarny ekran”, którego piksele są już wyłączone.';

  @override
  String get settingScreensaverFollowAnimationScaleTitle =>
      'Stosuj ustawienia animacji Androida';

  @override
  String get settingScreensaverFollowAnimationScaleDescription =>
      'Wstrzymuje animowane wygaszacze ekranu, gdy animacje w Androidzie są wyłączone.';

  @override
  String get settingScreensaverDimLevelTitle => 'Poziom przygaszenia';

  @override
  String get settingScreensaverDimLevelDescription =>
      'Jasność ekranu podczas przygaszania przez wygaszacz.';

  @override
  String get settingScreensaverBrightnessEnabledTitle =>
      'Jasność wygaszacza ekranu';

  @override
  String get settingScreensaverBrightnessEnabledDescription =>
      'Podczas wyświetlania wygaszacza ekranu użyj osobnego ustawienia jasności.';

  @override
  String get settingScreensaverBrightnessLevelTitle => 'Poziom jasności';

  @override
  String get settingScreensaverBrightnessLevelDescription =>
      'Dotyczy wszystkich trybów oprócz „Przygaszenie” i „Czarny ekran”.';

  @override
  String get settingScreensaverNotificationBrightnessTitle =>
      'Rozjaśniaj dla powiadomień';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      'Wyłącza przyciemnianie wygaszacza ekranu, gdy na ekranie wyświetlane jest powiadomienie.';

  @override
  String get settingScreensaverTouchBrightnessSecondsTitle =>
      'Rozjaśniaj po dotknięciu';

  @override
  String get settingScreensaverTouchBrightnessSecondsDescription =>
      'Wyłącza przyciemnienie wygaszacza ekranu na określony czas po dotknięciu, które nie powoduje jego wyłączenia. Ustaw 0, aby wyłączyć.';

  @override
  String get settingScreensaverScreenOffMinutesTitle => 'Wyłączaj ekran po';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Wyłącza panel wyświetlacza, gdy wygaszacz ekranu działa przez ustawiony czas. Ustaw 0, aby ekran pozostawał włączony bez ograniczeń. Wymaga uprawnienia administratora urządzenia.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Wybudzaj do wygaszacza';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescriptionSources =>
      'Wybierz, co po wyłączeniu ekranu przywraca wygaszacz ekranu zamiast pulpitu. Odliczanie „Wyłączaj ekran po” zaczyna się od nowa.';

  @override
  String get screensaverWakeSourcesAll => 'Wszystkie';

  @override
  String get screensaverWakeSourceMotion => 'Ruch';

  @override
  String get screensaverWakeSourceFace => 'Twarz';

  @override
  String get screensaverWakeSourceProximity => 'Zbliżenie';

  @override
  String get screensaverWakeSourcePerson => 'Osoba';

  @override
  String get screensaverWakeSourcePower => 'Przycisk zasilania';

  @override
  String get screensaverWakeSourceTouch => 'Dotyk';

  @override
  String get screensaverWakeSourceTouchRequires =>
      'Wymaga włączenia ustawień „Wyłącz ekran po” i „Użyj czarnego ekranu”.';

  @override
  String get screensaverModeDim => 'Przygaszenie';

  @override
  String get screensaverModeBlack => 'Czarny ekran';

  @override
  String get screensaverModeClock => 'Zegar';

  @override
  String get screensaverModeMedia => 'Multimedia z Home Assistant';

  @override
  String get screensaverModeLocal => 'Lokalne multimedia';

  @override
  String get screensaverModeGallery => 'Galeria zdjęć';

  @override
  String get screensaverModeImmich => 'Multimedia z Immich';

  @override
  String get screensaverModeWebsite => 'Strona internetowa';

  @override
  String get screensaverModeCamera => 'Obraz z kamer';

  @override
  String get screensaverDimSection => 'Wygaszacz ekranu „Przygaszenie”';

  @override
  String get screensaverWarningTitle => 'OSTRZEŻENIE: Przeczytaj uważnie!';

  @override
  String get screensaverScreenOffProceed => 'Mimo to wyłącz ekran';

  @override
  String get screensaverAdminMissing =>
      'Nie przyznano, więc nie można wyłączyć ekranu.';

  @override
  String get screensaverAdminMissingRemote =>
      'Brak uprawnienia administratora urządzenia';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      'Bez niego nie można wyłączyć ekranu. Okno przyznawania uprawnienia pojawi się na ekranie tabletu.';

  @override
  String get screensaverDimWarning =>
      'OSTRZEŻENIE: tryb „Przygaszenie” pozostawia widoczny pulpit, dlatego optymalizacja „Wstrzymaj pulpit podczas wygaszacza ekranu” nie zostanie zastosowana, a pulpit nadal będzie obciążać CPU i GPU oraz zużywać baterię.';

  @override
  String get screensaverUnavailablePlugin =>
      'Niedostępny wygaszacz ekranu z wtyczki';

  @override
  String get screensaverScreenOffWarning =>
      'Gdy wyświetlacz całkowicie się wyłącza, kontrolę przejmuje wbudowany system zarządzania energią tabletu. Wiele modeli z Androidem działa wtedy nieprawidłowo: Wi-Fi przechodzi w uśpienie lub się rozłącza, encje Home Assistant stają się niedostępne, dostęp do kamery może zostać odebrany, a niektóre modele zamykają aplikacje działające w tle. Co się stanie, zależy od producenta.\n\nNiezawodną alternatywą jest wygaszacz „Czarny ekran” z tym ustawieniem pozostawionym na 0. Panel wygląda równie ciemno, a aplikacja zachowuje pełną kontrolę.';

  @override
  String get settingScreensaverScreenOffBlackTitle => 'Użyj czarnego ekranu';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      'Pokazuj zwykły czarny ekran przy zerowej jasności zamiast wyłączać wyświetlacz. Ukrywa widżety i ekran „Teraz odtwarzane”. Nie wymaga uprawnienia administratora urządzenia.';

  @override
  String get screensaverModeDashboard => 'Pulpit Home Assistant';

  @override
  String get settingScreensaverDashboardViewTitle => 'Widok pulpitu';

  @override
  String get settingScreensaverDashboardViewDescription =>
      'Widok pulpitu Home Assistant wyświetlany przez wygaszacz ekranu.';

  @override
  String get settingScreensaverDashboardDoubleTapTitle =>
      'Zamykanie dwukrotnym dotknięciem';

  @override
  String get settingScreensaverDashboardDoubleTapDescription =>
      'Pojedyncze dotknięcia obsługują pulpit, zamiast zamykać wygaszacz.';

  @override
  String get settingScreensaverDashboardKioskTitle =>
      'Zastąpienie trybu kiosku HA';

  @override
  String get settingScreensaverDashboardKioskDescription =>
      'Wybierz, co ukrywa wygaszacz ekranu, niezależnie od trybu kiosku HA.';

  @override
  String get settingScreensaverDashboardHideHeaderTitle => 'Ukryj nagłówek';

  @override
  String get settingScreensaverDashboardHideHeaderDescription =>
      'Ukryj pasek narzędzi pulpitu i karty widoków na wygaszaczu ekranu.';

  @override
  String get settingScreensaverDashboardHideSidebarTitle =>
      'Ukryj pasek boczny';

  @override
  String get settingScreensaverDashboardHideSidebarDescription =>
      'Ukryj boczny pasek nawigacji na wygaszaczu ekranu.';

  @override
  String get screensaverDashboardSection =>
      'Wygaszacz ekranu „Pulpit Home Assistant”';

  @override
  String get screensaverModeUrl => 'Adres URL obrazu';

  @override
  String get screensaverCalendarSection => 'Wygaszacz ekranu „Kalendarz”';

  @override
  String get settingScreensaverCalendarViewTitle => 'Widok kalendarza';

  @override
  String get settingScreensaverCalendarViewDescription =>
      'Widok kalendarza otwierany przez wygaszacz ekranu.';

  @override
  String get settingScreensaverGlanceScaleTitle => 'Skalowanie wierszy';

  @override
  String get settingScreensaverGlanceScaleDescription =>
      'Przeskaluj wiersz, aby lepiej pasował do rozmiaru ekranu.';

  @override
  String get settingScreensaverGlanceFontTitle => 'Rodzina czcionek';

  @override
  String get settingScreensaverGlanceFontDescription =>
      'Krój czcionki użyty w wierszu.';

  @override
  String get settingScreensaverGlanceFontWeightTitle => 'Grubość czcionki';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      'Grubość tekstu w wierszu. Domyślnie każda linia ma własną grubość: nazwy zwykłą, a wartości półgrubą.';

  @override
  String get settingScreensaverGlanceHideNamesTitle => 'Ukryj nazwy';

  @override
  String get settingScreensaverGlanceHideNamesDescription =>
      'Pokazuj tylko ikonę i wartość, przy czym wartość jest większa.';

  @override
  String get settingScreensaverGlanceBwIconsTitle => 'Ikony monochromatyczne';

  @override
  String get settingScreensaverGlanceBwIconsDescription =>
      'Wyświetlaj wszystkie ikony w neutralnej szarości zamiast w kolorze odpowiadającym ich stanowi.';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => 'Styl pływającego tekstu';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      'Pokazuj encje jako pływający tekst zamiast etykiet.';

  @override
  String get screensaverOverlayAppearance => 'Wygląd';

  @override
  String get settingScreensaverGlanceEnabledTitle => 'W skrócie';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      'Pokazuj na wygaszaczu ekranu wiersz ze stanami encji Home Assistant.';

  @override
  String get settingScreensaverGlanceEntitiesTitle => 'Encje';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      'Maksymalnie cztery encje do wyświetlenia, każda z opcjonalną własną nazwą.';

  @override
  String get settingScreensaverGlanceNowPlayingTitle =>
      'Pokazuj na ekranie „Teraz odtwarzane”';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      'Pokazuj wiersz w pełnoekranowym widoku „Teraz odtwarzane”. Jest ukryty, gdy wyświetlany jest tekst utworu.';

  @override
  String get screensaverOverlayShowing => 'Wyświetlane';

  @override
  String get screensaverOverlayNone => 'Na razie brak';

  @override
  String get screensaverOverlayGlancePage => 'W skrócie';

  @override
  String get screensaverOverlayGlanceHint =>
      'Encje wyświetlane na wygaszaczu ekranu';

  @override
  String get glanceUnavailable => 'Niedostępne';

  @override
  String get glanceUnknown => 'Nieznane';

  @override
  String get settingScreensaverImmichUrlTitle => 'Adres serwera';

  @override
  String get settingScreensaverImmichUrlDescription =>
      'Adres serwera Immich wraz z portem.';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'Klucz API';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      'Utworzony w Immich w sekcji „Account Settings” → „API Keys”.';

  @override
  String get screensaverMediaImmichPage =>
      'Wygaszacz ekranu „Multimedia z Immich”';

  @override
  String get screensaverMediaImmichHint =>
      'Serwer, multimedia, pokaz slajdów, metadane, filtry';

  @override
  String get screensaverMediaServerConnection => 'Połączenie z serwerem';

  @override
  String get screensaverMediaValidateFailedLog =>
      'Weryfikacja nie powiodła się. Sprawdź nieudane wywołanie w logach aplikacji.';

  @override
  String get screensaverMediaValidateFailed => 'Weryfikacja nie powiodła się.';

  @override
  String get screensaverMediaNoAnswer => 'Urządzenie nie odpowiedziało.';

  @override
  String get screensaverMediaAddressFirst => 'Najpierw wpisz adres serwera.';

  @override
  String get screensaverMediaKeyFirst => 'Najpierw wpisz klucz API.';

  @override
  String get screensaverMediaBadAddress =>
      'Adres serwera nie jest prawidłowym adresem URL.';

  @override
  String get screensaverMediaKeyRejected => 'Klucz API został odrzucony.';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'Klucz API nie ma uprawnienia $scope.';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'Klucz API nie ma jednego z uprawnień: $error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return 'Serwer odpowiedział kodem $status: $error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return 'Nie udało się połączyć z $url.';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return 'Nie udało się skomunikować z serwerem: $error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => 'Osoby';

  @override
  String get settingScreensaverImmichPeopleDescription =>
      'Pokazuj tylko multimedia, na których jest dowolna z tych osób.';

  @override
  String get settingScreensaverImmichExcludePeopleTitle => 'Wyklucz osoby';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      'Pomijaj multimedia, na których jest dowolna z tych osób.';

  @override
  String get settingScreensaverImmichTagsTitle => 'Tagi';

  @override
  String get settingScreensaverImmichTagsDescription =>
      'Pokazuj tylko multimedia z dowolnym z tych tagów.';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => 'Wyklucz tagi';

  @override
  String get settingScreensaverImmichExcludeTagsDescription =>
      'Pomijaj multimedia z dowolnym z tych tagów.';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => 'Tylko ulubione';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      'Pokazuj tylko multimedia oznaczone jako ulubione.';

  @override
  String get settingScreensaverImmichTakenWithinTitle => 'Wykonane w ciągu';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      'Pokazuj tylko multimedia wykonane w tym okresie.';

  @override
  String get settingScreensaverImmichTakenFromTitle => 'Od';

  @override
  String get settingScreensaverImmichTakenFromDescription =>
      'Pomijaj multimedia wykonane przed tą datą.';

  @override
  String get settingScreensaverImmichTakenToTitle => 'Do';

  @override
  String get settingScreensaverImmichTakenToDescription =>
      'Pomijaj multimedia wykonane po tej dacie. Ten dzień jest uwzględniany.';

  @override
  String get screensaverMediaFilters => 'Filtry';

  @override
  String get screensaverMediaAnyone => 'Dowolna osoba';

  @override
  String get screensaverMediaAnyoneDevice => 'Dowolna osoba.';

  @override
  String get screensaverMediaNoOne => 'Nikt';

  @override
  String get screensaverMediaNoOneDevice => 'Nikt.';

  @override
  String get screensaverMediaAny => 'Dowolne';

  @override
  String get screensaverMediaAnyDevice => 'Dowolne.';

  @override
  String get screensaverMediaNoTagsChosen => 'Brak tagów';

  @override
  String get screensaverMediaNoTagsChosenDevice => 'Brak tagów.';

  @override
  String get screensaverMediaNoPeople =>
      'Brak nazwanych osób. Najpierw nadaj im imiona w Immich.';

  @override
  String get screensaverMediaNoTags =>
      'Brak tagów. Najpierw utwórz je w Immich.';

  @override
  String get screensaverMediaPeopleFailed => 'Nie udało się pobrać listy osób';

  @override
  String get screensaverMediaTagsFailed => 'Nie udało się pobrać listy tagów';

  @override
  String get screensaverMediaHidden => 'Ukryte';

  @override
  String get screensaverMediaAnyTime => 'Dowolny okres';

  @override
  String get screensaverMediaPastMonth => 'Ostatni miesiąc';

  @override
  String get screensaverMediaPast3Months => 'Ostatnie 3 miesiące';

  @override
  String get screensaverMediaPastYear => 'Ostatni rok';

  @override
  String get screensaverMediaPast2Years => 'Ostatnie 2 lata';

  @override
  String get screensaverMediaPast5Years => 'Ostatnie 5 lat';

  @override
  String get screensaverMediaPast10Years => 'Ostatnie 10 lat';

  @override
  String get screensaverMediaSince => 'Od';

  @override
  String get screensaverMediaTimeframe => 'Przedział czasu';

  @override
  String get screensaverMediaToday => 'Dzisiaj';

  @override
  String get screensaverMediaDateFormat => 'Użyj formatu RRRR-MM-DD.';

  @override
  String get screensaverMediaNotDate => 'To nie jest data.';

  @override
  String get settingScreensaverImmichMetadataTitle => 'Pokazuj metadane';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      'Album, data, aparat i lokalizacja wyświetlane na multimediach.';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => 'Nazwa albumu';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription =>
      'Pokazuj, z którego albumu pochodzi zdjęcie.';

  @override
  String get settingScreensaverImmichMetadataDateTitle => 'Data wykonania';

  @override
  String get settingScreensaverImmichMetadataDateDescription =>
      'Pokazuj, kiedy zrobiono zdjęcie.';

  @override
  String get settingScreensaverImmichMetadataCameraTitle => 'Dane aparatu';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      'Pokazuj ogniskową, przysłonę i ISO.';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => 'Lokalizacja';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      'Pokazuj miejsce, w którym zrobiono zdjęcie.';

  @override
  String get settingScreensaverImmichMetadataDescriptionTitle => 'Opis';

  @override
  String get settingScreensaverImmichMetadataDescriptionDescription =>
      'Pokazuj opis zdjęcia u dołu ekranu.';

  @override
  String get settingScreensaverImmichMetadataPositionTitle =>
      'Położenie metadanych';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      'W którym rogu wyświetlać szczegóły.';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle => 'Cień tekstu';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      'Dodaj cień do tekstu metadanych, aby był czytelny na zdjęciach.';

  @override
  String get settingScreensaverImmichMetadataScaleTitle => 'Skalowanie tekstu';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      'Skaluj szczegóły zdjęcia, aby lepiej pasowały do rozmiaru ekranu.';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle =>
      'Intensywność winiety';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      'Stopień przyciemnienia pod szczegółami, poprawiający czytelność na jasnych zdjęciach. 0 wyłącza efekt.';

  @override
  String get screensaverMediaMetadata => 'Metadane';

  @override
  String get screensaverMediaTopLeft => 'Lewy górny róg';

  @override
  String get screensaverMediaTopRight => 'Prawy górny róg';

  @override
  String get screensaverMediaBottomLeft => 'Lewy dolny róg';

  @override
  String get screensaverMediaBottomRight => 'Prawy dolny róg';

  @override
  String get settingScreensaverImmichIntervalTitle =>
      'Czas wyświetlania obrazu (s)';

  @override
  String get settingScreensaverImmichShuffleTitle => 'Losowa kolejność';

  @override
  String get settingScreensaverImmichShuffleDescription =>
      'Wyświetla multimedia w losowej kolejności.';

  @override
  String get settingScreensaverImmichTransitionTitle => 'Przejście';

  @override
  String get settingScreensaverImmichTransitionDescription =>
      'Sposób przejścia od jednego elementu do następnego.';

  @override
  String get settingScreensaverImmichFillTitle => 'Wypełnij ekran';

  @override
  String get settingScreensaverImmichFillDescription =>
      '„Wyłączone” pokazuje całe zdjęcie między czarnymi pasami. „Inteligentne” powiększa zdjęcia o proporcjach zbliżonych do ekranu, a pozostałe umieszcza na rozmytym tle. „Zawsze” powiększa każde zdjęcie, przycinając to, co się nie mieści.';

  @override
  String get settingScreensaverImmichCropFacesTitle => 'Przycinaj wokół twarzy';

  @override
  String get settingScreensaverImmichCropFacesDescription =>
      'Zdjęcia przycinane do wypełnienia ekranu zachowują w kadrze twarze wykryte przez Immich. Wymaga uprawnienia face.read.';

  @override
  String get settingScreensaverImmichCropVideosTitle => 'Przycinaj filmy';

  @override
  String get settingScreensaverImmichCropVideosDescription =>
      'Filmy są przycinane do wypełnienia ekranu tak jak zdjęcia. Wyłącz, aby pokazywać każdy film w całości.';

  @override
  String get settingScreensaverImmichPairPortraitTitle =>
      'Łącz zdjęcia pionowe w pary';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      'Pokazuje dwa zdjęcia pionowe obok siebie, aby wypełniły ekran.';

  @override
  String get settingScreensaverImmichPairLandscapeTitle =>
      'Łącz zdjęcia poziome w pary';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      'Pokazuje dwa zdjęcia poziome jedno nad drugim, aby wypełniły pionowy ekran.';

  @override
  String get settingScreensaverImmichEdgeTapsTitle =>
      'Zmieniaj slajdy dotknięciem krawędzi';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      'Dotknięcie lewej lub prawej połowy ekranu pokazuje poprzedni lub następny slajd zamiast zamykać wygaszacz.';

  @override
  String get settingScreensaverImmichProgressBarTitle => 'Pokaż pasek postępu';

  @override
  String get settingScreensaverImmichProgressBarDescription =>
      'Cienki pasek pokazuje czas pozostały do następnego slajdu.';

  @override
  String get settingScreensaverImmichProgressBarPositionTitle =>
      'Położenie paska postępu';

  @override
  String get settingScreensaverImmichProgressBarPositionDescription =>
      'Krawędź ekranu, wzdłuż której biegnie pasek postępu.';

  @override
  String get screensaverImmichProgressBarTop => 'Góra';

  @override
  String get screensaverImmichProgressBarBottom => 'Dół';

  @override
  String get settingScreensaverImmichProgressBarColorTitle =>
      'Kolor paska postępu';

  @override
  String get settingScreensaverImmichProgressBarColorDescription =>
      'Kolor paska postępu.';

  @override
  String get settingScreensaverImmichProgressBarTransparencyTitle =>
      'Przezroczystość paska postępu';

  @override
  String get settingScreensaverImmichProgressBarTransparencyDescription =>
      'Jak bardzo zdjęcie przebija się przez pasek postępu.';

  @override
  String get screensaverMediaSlideshow => 'Pokaz slajdów';

  @override
  String get settingScreensaverImmichAlbumTitle => 'Źródło multimediów';

  @override
  String get settingScreensaverImmichAlbumDescription =>
      'Cała biblioteka lub wybrane albumy.';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => 'Tylko zdjęcia';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription =>
      'Pomijaj filmy w pokazie slajdów.';

  @override
  String get settingScreensaverImmichCacheTitle =>
      'Zapisuj multimedia w pamięci podręcznej';

  @override
  String get settingScreensaverImmichCacheDescription =>
      'Przechowuj kopie na urządzeniu, aby obrazy wczytywały się od razu.';

  @override
  String get settingScreensaverImmichCacheMaxTitle =>
      'Rozmiar pamięci podręcznej (elementy)';

  @override
  String get settingScreensaverImmichCacheMaxDescription =>
      'Po zapełnieniu pamięci podręcznej najstarsze elementy są usuwane.';

  @override
  String get screensaverMediaAll => 'Wszystkie multimedia';

  @override
  String get screensaverMediaAllDevice => 'Wszystkie multimedia.';

  @override
  String get screensaverMediaNoAlbums =>
      'Brak albumów. Najpierw utwórz album w Immich.';

  @override
  String get screensaverMediaAlbumsFailed =>
      'Nie udało się pobrać listy albumów';

  @override
  String screensaverMediaListError(String error) {
    return 'Nie udało się pobrać listy: $error';
  }

  @override
  String get screensaverMediaListingFailed => 'błąd pobierania listy';

  @override
  String screensaverMediaItems(String count) {
    return 'Elementy: $count';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return 'W pamięci podręcznej: $count, $size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => 'Podglądy z kamer';

  @override
  String get settingScreensaverCameraViewsDescription =>
      'Podglądy z kamer pokazywane przez wygaszacz, w tej kolejności.';

  @override
  String get settingScreensaverCameraViewSecondsTitle =>
      'Sekundy na podgląd z kamery';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      'Jak długo każdy podgląd z kamery jest na ekranie przed następnym. Przy jednym wybranym podglądzie z kamery nic się nie zmienia.';

  @override
  String get settingScreensaverCameraMuteTitle => 'Wycisz wszystkie podglądy';

  @override
  String get settingScreensaverCameraMuteDescription =>
      'Wszystkie podglądy z kamer pozostają bez dźwięku, nawet przy jednej kamerze.';

  @override
  String get screensaverMediaCameraPage => 'Wygaszacz „Obraz z kamer”';

  @override
  String get screensaverMediaCameraHint =>
      'Podglądy z kamer, sekundy przypadające na podgląd z kamery, dźwięk';

  @override
  String get screensaverMediaNoCameras =>
      'Żaden podgląd z kamery nie ma jeszcze kamer. Dodaj kamerę w sekcji „Obraz z kamer”.';

  @override
  String get screensaverMediaNoCamerasRemote =>
      'Żaden podgląd z kamery nie ma jeszcze kamer';

  @override
  String get screensaverMediaAddCameras =>
      'Dodaj kamerę w sekcji „Obraz z kamer”.';

  @override
  String get screensaverMediaNoViews =>
      'Brak podglądów z kamer. Wybierz podglądy z kamer, które wygaszacz ma wyświetlać po kolei.';

  @override
  String get screensaverMediaRotation =>
      'W rotacji (przeciągnij, aby zmienić kolejność)';

  @override
  String get screensaverMediaAvailable => 'Dostępne';

  @override
  String screensaverMediaOneCamera(String count) {
    return 'Kamery: $count';
  }

  @override
  String screensaverMediaCameras(String count) {
    return 'Kamery: $count';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return 'Pozycja $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => 'Brak';

  @override
  String get screensaverMediaTransitionFade => 'Przenikanie';

  @override
  String get screensaverMediaTransitionSlide => 'Przesunięcie';

  @override
  String get screensaverMediaTransitionZoom => 'Powiększenie';

  @override
  String get screensaverMediaTransitionKenBurns => 'Efekt Kena Burnsa';

  @override
  String get screensaverMediaTransitionRandom => 'Losowo';

  @override
  String get screensaverMediaFillOff => 'Wyłączone';

  @override
  String get screensaverMediaFillSmart => 'Inteligentne';

  @override
  String get screensaverMediaFillAlways => 'Zawsze';

  @override
  String get settingScreensaverVideoLengthTitle => 'Długość filmu';

  @override
  String get settingScreensaverVideoLengthDescription =>
      'Jak długo odtwarzany jest każdy film przed następnym.';

  @override
  String get screensaverMediaVideoLengthFull => 'Cały film';

  @override
  String get screensaverMediaVideoLengthInterval => 'Jak zdjęcia';

  @override
  String get settingScreensaverImageIntervalDescription =>
      'Jak długo wyświetlany jest każdy obraz przed następnym.';

  @override
  String get settingScreensaverPhotoIntervalDescription =>
      'Jak długo wyświetlane jest każde zdjęcie przed następnym.';

  @override
  String get settingScreensaverGalleryItemsTitle => 'Zdjęcia';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'Zdjęcia i filmy wyświetlane przez ten wygaszacz. Wybierane z galerii na urządzeniu; ponowny wybór zastępuje poprzedni.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Sekundy na zdjęcie';

  @override
  String get settingScreensaverGalleryShuffleTitle => 'Losowa kolejność';

  @override
  String get settingScreensaverGalleryShuffleDescription =>
      'Wyświetlaj wybrane elementy w losowej kolejności.';

  @override
  String get settingScreensaverGalleryTransitionTitle => 'Przejście';

  @override
  String get settingScreensaverGalleryTransitionDescription =>
      'Sposób przejścia z jednego zdjęcia do następnego.';

  @override
  String get settingScreensaverGalleryFillTitle => 'Wypełnij ekran';

  @override
  String get settingScreensaverGalleryFillDescription =>
      '„Wyłączone” pokazuje całe zdjęcie między czarnymi pasami. „Inteligentne” powiększa zdjęcia o proporcjach zbliżonych do ekranu, a pozostałe umieszcza na rozmytym tle. „Zawsze” powiększa każde zdjęcie, przycinając to, co się nie mieści.';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle =>
      'Zmieniaj slajdy dotknięciem krawędzi';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      'Dotknięcie lewej lub prawej połowy ekranu pokazuje poprzedni lub następny slajd zamiast zamykać wygaszacz.';

  @override
  String get screensaverMediaGalleryPage => 'Wygaszacz „Galeria zdjęć”';

  @override
  String get screensaverMediaGalleryHint =>
      'Zdjęcia, czas, losowa kolejność, przejście';

  @override
  String get screensaverMediaLoadingPhotos => 'Wczytywanie zdjęć…';

  @override
  String screensaverMediaCopying(String index, String total) {
    return 'Kopiowanie zdjęcia $index z $total…';
  }

  @override
  String get screensaverMediaCopyFailed => 'Nie udało się skopiować zdjęć';

  @override
  String get screensaverMediaSmallerSelection => 'Wybierz mniej zdjęć.';

  @override
  String get screensaverMediaNoPhotos => 'Nie wybrano zdjęć';

  @override
  String screensaverMediaSelected(String count) {
    return 'Wybrane: $count';
  }

  @override
  String get screensaverMediaPickOnDevice =>
      'Nic nie wybrano. Wybierz na urządzeniu.';

  @override
  String get settingScreensaverMediaIdTitle => 'Źródło multimediów';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Element multimedialny, folder lub kamera z Home Assistant. Użyj „Przeglądaj”, aby wybrać.';

  @override
  String get settingScreensaverMediaIntervalTitle =>
      'Czas wyświetlania obrazu (s)';

  @override
  String get settingScreensaverMediaShuffleTitle => 'Losowa kolejność';

  @override
  String get settingScreensaverMediaShuffleDescription =>
      'Odtwarzaj folder w losowej kolejności.';

  @override
  String get settingScreensaverMediaRecursiveTitle => 'Uwzględniaj podfoldery';

  @override
  String get settingScreensaverMediaRecursiveDescription =>
      'Po wybraniu folderu przeglądaj też jego podfoldery.';

  @override
  String get settingScreensaverMediaTransitionTitle => 'Przejście';

  @override
  String get settingScreensaverMediaTransitionDescription =>
      'Sposób przejścia od jednego elementu do następnego.';

  @override
  String get settingScreensaverMediaFillTitle => 'Wypełnij ekran';

  @override
  String get settingScreensaverMediaFillDescription =>
      '„Wyłączone” pokazuje całe zdjęcie między czarnymi pasami. „Inteligentne” powiększa zdjęcia o proporcjach zbliżonych do ekranu, a pozostałe umieszcza na rozmytym tle. „Zawsze” powiększa każde zdjęcie, przycinając to, co się nie mieści.';

  @override
  String get settingScreensaverMediaEdgeTapsTitle =>
      'Zmieniaj slajdy dotknięciem krawędzi';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      'Dotknięcie lewej lub prawej połowy ekranu pokazuje poprzedni lub następny slajd zamiast zamykać wygaszacz.';

  @override
  String get settingScreensaverMediaMetadataTitle => 'Pokazuj metadane';

  @override
  String get settingScreensaverMediaMetadataDescription =>
      'Data i dane aparatu wyświetlane na zdjęciu.';

  @override
  String get settingScreensaverMediaMetadataDateTitle => 'Data wykonania';

  @override
  String get settingScreensaverMediaMetadataDateDescription =>
      'Pokazuj, kiedy zrobiono zdjęcie.';

  @override
  String get settingScreensaverMediaMetadataCameraTitle => 'Dane aparatu';

  @override
  String get settingScreensaverMediaMetadataCameraDescription =>
      'Pokazuj ogniskową, przysłonę i ISO.';

  @override
  String get settingScreensaverMediaMetadataPositionTitle =>
      'Położenie metadanych';

  @override
  String get settingScreensaverMediaMetadataPositionDescription =>
      'W którym rogu wyświetlać szczegóły.';

  @override
  String get settingScreensaverMediaMetadataTextShadowTitle => 'Cień tekstu';

  @override
  String get settingScreensaverMediaMetadataTextShadowDescription =>
      'Dodaj cień do tekstu metadanych, aby był czytelny na zdjęciach.';

  @override
  String get settingScreensaverMediaMetadataScaleTitle => 'Skalowanie tekstu';

  @override
  String get settingScreensaverMediaMetadataScaleDescription =>
      'Skaluj szczegóły zdjęcia, aby lepiej pasowały do rozmiaru ekranu.';

  @override
  String get settingScreensaverMediaVignetteStrengthTitle =>
      'Intensywność winiety';

  @override
  String get settingScreensaverMediaVignetteStrengthDescription =>
      'Stopień przyciemnienia pod szczegółami, poprawiający czytelność na jasnych zdjęciach. 0 wyłącza efekt.';

  @override
  String get screensaverMediaHaMetadata =>
      'Metadane wygaszacza „Multimedia z Home Assistant”';

  @override
  String get screensaverMediaHaPage =>
      'Wygaszacz „Multimedia z Home Assistant”';

  @override
  String get screensaverMediaHaPageHint =>
      'Źródło multimediów, czas, losowa kolejność, wypełnienie, metadane';

  @override
  String get screensaverMediaChoose => 'Wybierz multimedia';

  @override
  String get screensaverMediaRoot => 'Multimedia';

  @override
  String get screensaverMediaHaUnavailable =>
      'Nie udało się połączyć z Home Assistant lub brakuje tokenu.';

  @override
  String get screensaverMediaEmpty => 'Nic tu nie ma.';

  @override
  String get screensaverMediaUseFolder => 'Użyj tego folderu';

  @override
  String get screensaverMediaFolder => 'folder';

  @override
  String get screensaverMediaCamera => 'kamera';

  @override
  String get screensaverMediaItem => 'element';

  @override
  String get screensaverMediaBrowseFailed => 'przeglądanie nie powiodło się';

  @override
  String screensaverMediaBrowseError(String error) {
    return 'Przeglądanie nie powiodło się: $error';
  }

  @override
  String get screensaverMediaNotSet => 'Nie ustawiono';

  @override
  String get settingScreensaverLocalFolderTitle => 'Folder lokalny';

  @override
  String get settingScreensaverLocalFolderDescription =>
      'Folder na tym urządzeniu, z którego wygaszacz wyświetla po kolei zdjęcia i filmy. Wybierany na urządzeniu; ścieżkę można też wpisać tutaj zdalnie.';

  @override
  String get settingScreensaverLocalIntervalTitle => 'Sekundy na zdjęcie';

  @override
  String get settingScreensaverLocalShuffleTitle => 'Losowa kolejność';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      'Wyświetlaj zawartość folderu w losowej kolejności zamiast według nazwy.';

  @override
  String get settingScreensaverLocalRecursiveTitle => 'Uwzględniaj podfoldery';

  @override
  String get settingScreensaverLocalRecursiveDescription =>
      'Wyświetlaj też zdjęcia i filmy z podfolderów.';

  @override
  String get settingScreensaverLocalTransitionTitle => 'Przejście';

  @override
  String get settingScreensaverLocalTransitionDescription =>
      'Sposób przejścia z jednego zdjęcia do następnego.';

  @override
  String get settingScreensaverLocalFillTitle => 'Wypełnij ekran';

  @override
  String get settingScreensaverLocalFillDescription =>
      '„Wyłączone” pokazuje całe zdjęcie między czarnymi pasami. „Inteligentne” powiększa zdjęcia o proporcjach zbliżonych do ekranu, a pozostałe umieszcza na rozmytym tle. „Zawsze” powiększa każde zdjęcie, przycinając to, co się nie mieści.';

  @override
  String get settingScreensaverLocalEdgeTapsTitle =>
      'Zmieniaj slajdy dotknięciem krawędzi';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      'Dotknięcie lewej lub prawej połowy ekranu pokazuje poprzedni lub następny slajd zamiast zamykać wygaszacz.';

  @override
  String get settingScreensaverLocalMetadataTitle => 'Pokazuj metadane';

  @override
  String get settingScreensaverLocalMetadataDescription =>
      'Data i dane aparatu wyświetlane na zdjęciu.';

  @override
  String get settingScreensaverLocalMetadataDateTitle => 'Data wykonania';

  @override
  String get settingScreensaverLocalMetadataDateDescription =>
      'Pokazuj, kiedy zrobiono zdjęcie.';

  @override
  String get settingScreensaverLocalMetadataCameraTitle => 'Dane aparatu';

  @override
  String get settingScreensaverLocalMetadataCameraDescription =>
      'Pokazuj ogniskową, przysłonę i ISO.';

  @override
  String get settingScreensaverLocalMetadataPositionTitle =>
      'Położenie metadanych';

  @override
  String get settingScreensaverLocalMetadataPositionDescription =>
      'W którym rogu wyświetlać szczegóły.';

  @override
  String get settingScreensaverLocalMetadataTextShadowTitle => 'Cień tekstu';

  @override
  String get settingScreensaverLocalMetadataTextShadowDescription =>
      'Dodaj cień do tekstu metadanych, aby był czytelny na zdjęciach.';

  @override
  String get settingScreensaverLocalMetadataScaleTitle => 'Skalowanie tekstu';

  @override
  String get settingScreensaverLocalMetadataScaleDescription =>
      'Skaluj szczegóły zdjęcia, aby lepiej pasowały do rozmiaru ekranu.';

  @override
  String get settingScreensaverLocalVignetteStrengthTitle =>
      'Intensywność winiety';

  @override
  String get settingScreensaverLocalVignetteStrengthDescription =>
      'Stopień przyciemnienia pod szczegółami, poprawiający czytelność na jasnych zdjęciach. 0 wyłącza efekt.';

  @override
  String get screensaverMediaLocalMetadata =>
      'Metadane wygaszacza „Lokalne multimedia”';

  @override
  String get screensaverMediaLocalPage => 'Wygaszacz „Lokalne multimedia”';

  @override
  String get screensaverMediaLocalPageHint =>
      'Folder, czas, losowa kolejność, przejście, metadane';

  @override
  String get settingScreensaverUrlImageDescription =>
      'Adres obrazu, który urządzenie pobiera ponownie przy każdym slajdzie.';

  @override
  String get settingScreensaverUrlIntervalDescription =>
      'Jak długo wyświetlane jest każde zdjęcie przed pobraniem następnego.';

  @override
  String get screensaverMediaUrlPage => 'Wygaszacz „Adres URL obrazu”';

  @override
  String get screensaverMediaUrlPageHint =>
      'Adres URL, czas, przejście, metadane';

  @override
  String get screensaverMediaUrlMetadata => 'Metadane trybu „Adres URL obrazu”';

  @override
  String get settingScreensaverDismissOnMotionTitle =>
      'Zamykaj po wykryciu ruchu';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      'Monitoruje obraz z kamery podczas wyświetlania wygaszacza ekranu, i wybudza ekran, gdy ktoś się zbliża. Kamera działa tylko podczas wyświetlania wygaszacza.';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle =>
      'Tylko przy wyłączonym ekranie';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      'Wygaszacz ekranu pozostaje aktywny, gdy ruch zostanie wykryty przy włączonym ekranie. Po wyłączeniu ekranu wykrycie wybudza pulpit. Dotknięcie nadal zamyka wygaszacz.';

  @override
  String get settingScreensaverPostponeOnMotionTitle =>
      'Opóźnij uruchomienie wygaszacza ekranu po wykryciu ruchu';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      'Opóźnia uruchomienie wygaszacza ekranu po wykryciu ruchu. UWAGA: kamera działa wtedy bez przerwy.';

  @override
  String get screensaverDetectionMotionPage => 'Wykrywanie ruchu';

  @override
  String get screensaverDetectionMotionHint =>
      'Zamykanie lub opóźnianie uruchomienia wygaszacza ekranu po wykryciu ruchu';

  @override
  String get screensaverDetectionMotionTuning =>
      'Wykrywanie ruchu można dostroić w ustawieniach kamery.';

  @override
  String get settingMotionUseEntityTitle => 'Użyj encji Home Assistant';

  @override
  String get settingMotionUseEntityDescription =>
      'Wykrywanie ruchu przez czujnik z Home Assistant zamiast kamery.';

  @override
  String get settingMotionEntityTitle => 'Encja czujnika ruchu';

  @override
  String get settingMotionEntityDescription =>
      'Obserwowany czujnik obecności lub ruchu z Home Assistant.';

  @override
  String get screensaverDetectionExternalMotionHeading =>
      'Zewnętrzny czujnik ruchu';

  @override
  String get settingScreensaverDismissOnPersonTitle =>
      'Zamykaj po wykryciu osoby';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      'Odczytuje dane z czujnika osób urządzenia podczas działania wygaszacza ekranu i wybudza ekran, gdy ktoś jest przed urządzeniem. Wymaga uprawnienia „Dostęp do logów” opisanego poniżej.';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle =>
      'Tylko przy wyłączonym ekranie';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      'Wygaszacz ekranu pozostaje aktywny, gdy ktoś podejdzie przy włączonym ekranie. Po wyłączeniu ekranu wykrycie wybudza pulpit. Dotknięcie nadal zamyka wygaszacz.';

  @override
  String get settingScreensaverPostponeOnPersonTitle =>
      'Opóźnij uruchomienie wygaszacza ekranu po wykryciu osoby';

  @override
  String get settingScreensaverPostponeOnPersonDescription =>
      'Opóźnia uruchomienie wygaszacza ekranu, gdy ktoś jest przed urządzeniem.';

  @override
  String get screensaverDetectionPersonPage => 'Wykrywanie osób';

  @override
  String get screensaverDetectionPersonHint =>
      'Zamykanie lub opóźnianie uruchomienia wygaszacza ekranu przez czujnik osób w urządzeniu';

  @override
  String get screensaverDetectionOccupancy => 'Obecność';

  @override
  String get screensaverDetectionStatusUnavailable => 'Stan niedostępny.';

  @override
  String get screensaverDetectionOff => 'Wyłączone.';

  @override
  String get screensaverDetectionStarting => 'Uruchamianie…';

  @override
  String get screensaverDetectionWaiting =>
      'Oczekiwanie na pierwszy sygnał kontrolny. Czujnik wysyła go co 30 s, gdy ktoś jest w polu widzenia.';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return 'Ostatni sygnał kontrolny: $ago.';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return '$count s temu';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return '$count min temu';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return '$count h temu';
  }

  @override
  String get screensaverDetectionDetected => 'Wykryto';

  @override
  String get screensaverDetectionClear => 'Brak';

  @override
  String get screensaverDetectionPermissions =>
      'Wymagane uprawnienia systemowe';

  @override
  String get screensaverDetectionLogAccess => 'Dostęp do logów';

  @override
  String get screensaverDetectionChecking => 'Sprawdzanie…';

  @override
  String get screensaverDetectionReadable =>
      'Czujnik osób w urządzeniu jest dostępny do odczytu.';

  @override
  String get screensaverDetectionRestartRequired =>
      'Przyznano. Uruchom ponownie Kiosk Satellite, aby je zastosować.';

  @override
  String get screensaverDetectionGrantHelp =>
      'To uprawnienie można przyznać tylko przez ADB. Pełne polecenie znajduje się w dokumentacji Meta Portal. Następnie uruchom ponownie Kiosk Satellite.';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      'To uprawnienie można przyznać tylko przez ADB. Poniżej znajduje się pełne polecenie gotowe do skopiowania. Następnie uruchom ponownie Kiosk Satellite.';

  @override
  String get screensaverDetectionGranted => 'Przyznano';

  @override
  String get screensaverDetectionMissing => 'Brak';

  @override
  String get screensaverDetectionRestart => 'Uruchom ponownie';

  @override
  String get screensaverDetectionRestartRemote =>
      'Uruchom ponownie na urządzeniu';

  @override
  String get screensaverDetectionLogRestart =>
      'Dostęp do logów został przyznany, ale zacznie działać po ponownym uruchomieniu Kiosk Satellite.';

  @override
  String get screensaverDetectionLogMissing =>
      'Nie przyznano dostępu do logów.';

  @override
  String get settingScreensaverDismissOnProximityTitle =>
      'Zamykaj po wykryciu zbliżenia';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      'Obserwuje czujnik zbliżeniowy, gdy wyświetlany jest wygaszacz ekranu, i wybudza ekran, gdy coś zbliży się do urządzenia. Nie zadziała w urządzeniu, które ma tylko czujniki przeznaczone do rozmów („palm”, „touch”).';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle =>
      'Tylko przy wyłączonym ekranie';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      'Wygaszacz ekranu pozostaje aktywny, gdy coś się zbliży przy włączonym ekranie. Po wyłączeniu ekranu wykrycie wybudza pulpit. Dotknięcie nadal zamyka wygaszacz.';

  @override
  String get settingScreensaverPostponeOnProximityTitle =>
      'Opóźnij uruchomienie wygaszacza ekranu po wykryciu zbliżenia';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      'Opóźnia uruchomienie wygaszacza ekranu, gdy coś znajduje się blisko czujnika.';

  @override
  String get screensaverDetectionProximityPage => 'Wykrywanie zbliżenia';

  @override
  String get screensaverDetectionProximityHint =>
      'Zamykanie lub opóźnianie uruchomienia wygaszacza ekranu przez czujnik zbliżeniowy';

  @override
  String get screensaverDetectionNoProximity =>
      'Niedostępne na tym urządzeniu: brak czujnika zbliżeniowego.';

  @override
  String get screensaverDetectionSensor => 'Czujnik';

  @override
  String get screensaverDetectionSensorHelp =>
      'Czujnik, który urządzenie zgłasza jako czujnik zbliżeniowy. Czujnik przeznaczony do rozmów o nazwie „palm” lub „touch” nie zadziała.';

  @override
  String get settingScreensaverScheduleEnabledTitle =>
      'Włącz wygaszacze według harmonogramu';

  @override
  String get settingScreensaverScheduleEnabledDescription =>
      'Zmiana wygaszacza ekranu o ustalonych porach dnia.';

  @override
  String get settingScreensaverScheduleTitle => 'Godziny';

  @override
  String get settingScreensaverScheduleDescription =>
      'Od każdej ustawionej godziny obowiązuje wybrany wygaszacz ekranu.';

  @override
  String get screensaverScheduleSection => 'Wygaszacze według harmonogramu';

  @override
  String get screensaverTime => 'Godzina';

  @override
  String get screensaverAddTime => 'Dodaj godzinę';

  @override
  String get screensaverRemoveTime => 'Usuń godzinę';

  @override
  String get screensaverNoTimes => 'Brak ustawionych godzin';

  @override
  String get screensaverTimeHelp =>
      'Wygaszacz ekranu obowiązujący od tej godziny.';

  @override
  String get screensaverPickTime => 'Wybierz godzinę.';

  @override
  String get screensaverDefault => 'Domyślnie';

  @override
  String get screensaverOn => 'Włączone';

  @override
  String get screensaverOff => 'Wyłączone';

  @override
  String get screensaverBrightness => 'Jasność';

  @override
  String get screensaverBrightnessFollow =>
      'Używa ustawienia jasności wygaszacza ekranu.';

  @override
  String get screensaverBrightnessExceptBlack =>
      'Dotyczy wszystkich trybów oprócz „Czarny ekran”.';

  @override
  String get screensaverScreenOffFollow =>
      'Używa ustawienia „Wyłącz ekran po”.';

  @override
  String get screensaverScreenOnHours =>
      'Ekran pozostaje włączony w tych godzinach.';

  @override
  String get screensaverScreenOffHelp =>
      'Wyłącza wyświetlacz, gdy wygaszacz ekranu działa przez ten czas. Wymaga uprawnienia administratora urządzenia.';

  @override
  String get screensaverScreenOffNever => 'Wyłączanie ekranu: nigdy';

  @override
  String get screensaverMotion => 'Zamykaj po wykryciu ruchu';

  @override
  String get screensaverFace => 'Zamykaj po wykryciu twarzy';

  @override
  String get screensaverProximity => 'Zamykaj po wykryciu zbliżenia';

  @override
  String get screensaverPerson => 'Zamykaj po wykryciu osoby';

  @override
  String get screensaverWidgets => 'Widżety';

  @override
  String get screensaverGlance => 'W skrócie';

  @override
  String get screensaverNowPlaying =>
      'Pokazuj „Teraz odtwarzane” obok wygaszacza ekranu';

  @override
  String get screensaverNowPlayingHelp =>
      '„Domyślnie” stosuje układ globalny. „Włączone” stosuje wspólny układ, gdy „Teraz odtwarzane” jest włączone. „Wyłączone” ukrywa „Teraz odtwarzane” w tych godzinach.';

  @override
  String get screensaverCameraRequired =>
      'Wymaga kamery. Najpierw włącz ją w ustawieniach kamery.';

  @override
  String get screensaverNotAvailable => 'Niedostępne na tym urządzeniu.';

  @override
  String get screensaverSummaryMotionOn => 'Wykrywanie ruchu: włączone';

  @override
  String get screensaverSummaryMotionOff => 'Wykrywanie ruchu: wyłączone';

  @override
  String get screensaverSummaryFaceOn => 'Wykrywanie twarzy: włączone';

  @override
  String get screensaverSummaryFaceOff => 'Wykrywanie twarzy: wyłączone';

  @override
  String get screensaverSummaryProximityOn => 'Zbliżenie: włączone';

  @override
  String get screensaverSummaryProximityOff => 'Zbliżenie: wyłączone';

  @override
  String get screensaverSummaryPersonOn => 'Wykrywanie osób: włączone';

  @override
  String get screensaverSummaryPersonOff => 'Wykrywanie osób: wyłączone';

  @override
  String get screensaverSummaryWidgetsOn => 'Widżety: włączone';

  @override
  String get screensaverSummaryWidgetsOff => 'Widżety: wyłączone';

  @override
  String get screensaverSummaryGlanceOn => 'W skrócie: włączone';

  @override
  String get screensaverSummaryGlanceOff => 'W skrócie: wyłączone';

  @override
  String get screensaverSummaryNowPlayingOn => '„Teraz odtwarzane”: włączone';

  @override
  String get screensaverSummaryNowPlayingOff => '„Teraz odtwarzane”: wyłączone';

  @override
  String screensaverBrightnessPercent(String percent) {
    return 'Jasność: $percent%';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return 'Wyłączenie ekranu po $minutes min';
  }

  @override
  String get screensaverWeatherMood => 'Nastrój pogody';

  @override
  String get screensaverWeatherMoodPage => 'Wygaszacz ekranu „Nastrój pogody”';

  @override
  String get screensaverWeatherMoodSummary =>
      'Encja pogody, błyskawice, podgląd';

  @override
  String get settingScreensaverWeatherEntityTitle => 'Encja pogody';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      'Encja pogody w Home Assistant, która steruje animowaną sceną. Dzień, świt/zmierzch i noc zależą od sun.sun, a zapasowo od czasu lokalnego.';

  @override
  String get settingScreensaverWeatherLightningTitle => 'Błyskawice';

  @override
  String get settingScreensaverWeatherLightningDescription =>
      'Pokazuj uderzenia piorunów i rozbłyski w chmurach podczas burz.';

  @override
  String get screensaverWeatherMoodSelectEntity =>
      'Wybierz encję pogody: „Ustawienia” > „Wygaszacz ekranu” > „Nastrój pogody”.';

  @override
  String get screensaverWeatherPreviewGroup => 'Podgląd pogody';

  @override
  String get settingScreensaverWeatherPreviewTitle => 'Włącz podgląd pogody';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      'Pokazuj wybraną scenę zamiast bieżącej pogody. Wyłącz, aby ponownie korzystać z danych Home Assistant.';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => 'Rodzaj pogody';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      'Animowana scena pogodowa do podglądu.';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle => 'Pora dnia';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      'Wybierz wersję sceny: dzień, świt/zmierzch lub noc.';

  @override
  String get screensaverWeatherPreviewSunny => 'Bezchmurnie';

  @override
  String get screensaverWeatherPreviewPartlycloudy => 'Częściowe zachmurzenie';

  @override
  String get screensaverWeatherPreviewCloudy => 'Pochmurno';

  @override
  String get screensaverWeatherPreviewRainy => 'Deszcz';

  @override
  String get screensaverWeatherPreviewPouring => 'Ulewa';

  @override
  String get screensaverWeatherPreviewSnowy => 'Śnieg';

  @override
  String get screensaverWeatherPreviewSnowyRainy => 'Śnieg z deszczem';

  @override
  String get screensaverWeatherPreviewFog => 'Mgła';

  @override
  String get screensaverWeatherPreviewHail => 'Grad';

  @override
  String get screensaverWeatherPreviewLightning => 'Błyskawice';

  @override
  String get screensaverWeatherPreviewLightningRainy => 'Błyskawice i deszcz';

  @override
  String get screensaverWeatherPreviewWindy => 'Wiatr';

  @override
  String get screensaverWeatherPreviewWindyVariant => 'Wiatr i chmury';

  @override
  String get screensaverWeatherPreviewExceptional => 'Wyjątkowa pogoda';

  @override
  String get screensaverWeatherPreviewDay => 'Dzień';

  @override
  String get screensaverWeatherPreviewNight => 'Noc';

  @override
  String get settingScreensaverWeatherClockTitle => 'Włącz zegar';

  @override
  String get settingScreensaverWeatherClockDescription =>
      'Pokazuj zegar cyfrowy nad sceną pogodową.';

  @override
  String get screensaverWeatherTextShadowDescription =>
      'Dodaje cień pod tekstem, aby był czytelny na tle sceny pogodowej.';

  @override
  String get screensaverWeatherBarGroup => 'Informacje o pogodzie';

  @override
  String get settingScreensaverWeatherBarTitle => 'Włącz pasek pogody';

  @override
  String get settingScreensaverWeatherBarDescription =>
      'Wyświetla bieżące informacje o pogodzie u dołu ekranu.';

  @override
  String get settingScreensaverWeatherBarScaleTitle => 'Skala tekstu';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      'Skaluje informacje o pogodzie w zakresie 50-200%.';

  @override
  String get settingScreensaverWeatherBarColorTitle => 'Kolor tekstu';

  @override
  String get settingScreensaverWeatherBarColorDescription =>
      'Kolor informacji o pogodzie.';

  @override
  String get settingScreensaverWeatherBarOpacityTitle => 'Krycie tła';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      'Przyciemnia dolny pasek, aby informacje o pogodzie były czytelne.';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => 'Pokaż nazwy';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      'Wyświetla nazwę każdego odczytu nad jego wartością. Po wyłączeniu wartości mają rozmiar taki jak wartości temperatury.';

  @override
  String get screensaverWeatherBarHighLowDescription =>
      'Pokazuje dzisiejszą najwyższą i najniższą temperaturę, gdy encja pogody ma prognozę dzienną.';

  @override
  String get screensaverWeatherBarHumidityDescription =>
      'Pokazuje wilgotność, gdy encja pogody ją podaje.';

  @override
  String get screensaverWeatherBarWindDescription =>
      'Pokazuje prędkość wiatru, gdy encja pogody ją podaje.';

  @override
  String get screensaverWeatherBarVisibilityDescription =>
      'Pokazuje widoczność, gdy encja pogody ją podaje.';

  @override
  String get settingScreensaverWeatherBlurTitle => 'Rozmycie sceny';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      'Rozmyj animowaną scenę pogodową, zachowując ostrość zegara, paska pogody i widżetów.';

  @override
  String get screensaverWeatherPreviewTwilight => 'Świt/zmierzch';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      'Pokazuje temperaturę odczuwalną zamiast rzeczywistej, gdy jest dostępna.';

  @override
  String get settingScreensaverWebsiteUrlTitle => 'Adres URL strony';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      'Strona wyświetlana na pełnym ekranie. Musi zezwalać na osadzanie.';

  @override
  String get settingScreensaverWebsiteZoomTitle => 'Poziom powiększenia';

  @override
  String get settingScreensaverWebsiteZoomDescription =>
      'Skaluje cały WebView zewnętrznego wygaszacza ekranu.';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle =>
      'Zamykanie dwukrotnym dotknięciem';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription =>
      'Pojedyncze dotknięcia obsługują stronę zamiast zamykać wygaszacz.';

  @override
  String get screensaverWebsiteSection =>
      'Wygaszacz ekranu „Strona internetowa”';

  @override
  String get screensaverOverlaySmallClock => 'Mały zegar';

  @override
  String get screensaverOverlayWeather => 'Pogoda';

  @override
  String get screensaverOverlayBattery => 'Bateria';

  @override
  String get screensaverOverlayClockNote =>
      'Niewidoczny w trybach wygaszacza ekranu „Zegar cyfrowy” i „Obraz z kamer”.';

  @override
  String get screensaverOverlayCameraNote =>
      'Niewidoczny w trybie wygaszacza ekranu „Obraz z kamer”.';

  @override
  String get screensaverOverlayScale => 'Skala';

  @override
  String get screensaverOverlayScaleHelp =>
      'Przeskaluj ten widżet, aby lepiej pasował do ekranu.';

  @override
  String get screensaverOverlayFont => 'Rodzina czcionek';

  @override
  String get screensaverOverlayCorner => 'Róg';

  @override
  String get screensaverOverlayWidget => 'Widżet';

  @override
  String get screensaverOverlayClock24 => 'Zegar 24-godzinny';

  @override
  String get screensaverOverlayClock24Help =>
      'Pokazuj godzinę w formacie 24-godzinnym zamiast AM/PM.';

  @override
  String get screensaverOverlayShowDate => 'Pokazuj datę';

  @override
  String get screensaverOverlayShowDateHelp => 'Dodaj krótką datę pod zegarem.';

  @override
  String get screensaverOverlayPercentage => 'Pokaż wartość procentową';

  @override
  String get screensaverOverlayPercentageHelp =>
      'Poziom naładowania obok ikony.';

  @override
  String get screensaverOverlayLow => 'Tylko przy niskim poziomie';

  @override
  String get screensaverOverlayLowHelp =>
      'Widżet pozostaje ukryty, dopóki poziom naładowania nie spadnie do 20 procent.';

  @override
  String get screensaverOverlayShowName => 'Pokaż nazwę';

  @override
  String get screensaverOverlayShowNameHelp => 'Nazwa pod wartością.';

  @override
  String get screensaverOverlayShowIcon => 'Pokaż ikonę';

  @override
  String get screensaverOverlayShowIconHelp => 'Ikona obok wartości.';

  @override
  String get screensaverOverlayVisibleStates => 'Widoczne stany';

  @override
  String get screensaverOverlayVisibleStatesHelp =>
      'Pokazuj widżet tylko wtedy, gdy jego wartość jest jedną z podanych, oddzielonych przecinkami. Pozostaw puste, aby był zawsze widoczny.';

  @override
  String get screensaverOverlayFontSystem => 'Systemowa';

  @override
  String get screensaverOverlayFontSerif => 'Szeryfowa';

  @override
  String get screensaverOverlayFontCondensed => 'Zwężona';

  @override
  String get screensaverOverlayFontMonospace => 'Stałej szerokości';

  @override
  String get screensaverOverlayFontCasual => 'Swobodna';

  @override
  String get screensaverOverlayFontCursive => 'Odręczna';

  @override
  String get screensaverOverlayColor => 'Kolor';

  @override
  String get screensaverOverlayWeatherEntity => 'Encja pogody';

  @override
  String get screensaverOverlayWeatherRequired => 'Wybierz encję pogody.';

  @override
  String get screensaverOverlayLocationName => 'Nazwa lokalizacji';

  @override
  String get screensaverOverlayLocationHelp =>
      'Pozostaw puste, aby ukryć wiersz lokalizacji.';

  @override
  String get screensaverOverlayLocation => 'Lokalizacja';

  @override
  String get screensaverOverlayLocationDetail =>
      'Nazwa miejsca nad wskaźnikiem temperatury.';

  @override
  String get screensaverOverlayFeelsLike => 'Temperatura odczuwalna';

  @override
  String get screensaverOverlayFeelsLikeHelp =>
      'Pokazuj temperaturę odczuwalną w osobnym wierszu z etykietą pod temperaturą rzeczywistą.';

  @override
  String get screensaverOverlayFeelsLikeOnly => 'Tylko odczuwalna';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp =>
      'Pokazuj temperaturę odczuwalną z etykietą „Odczuwalna” zamiast temperatury rzeczywistej.';

  @override
  String get screensaverOverlayForecast => 'Prognoza';

  @override
  String get screensaverOverlayForecastHelp =>
      'Warunki pogodowe z pasującą ikoną.';

  @override
  String get screensaverOverlayHighLow => 'Najwyższa i najniższa';

  @override
  String get screensaverOverlayHighLowHelp =>
      'Dzisiejsza najwyższa i najniższa temperatura.';

  @override
  String get screensaverOverlayForecastWidget => 'Prognoza pogody';

  @override
  String get screensaverOverlayForecastDays => 'Liczba dni';

  @override
  String get screensaverOverlayForecastToday => 'Uwzględnij dzisiaj';

  @override
  String get screensaverOverlayForecastTodayHelp =>
      'Rozpocznij listę od dzisiejszej prognozy.';

  @override
  String get screensaverOverlayForecastColored => 'Kolorowe ikony';

  @override
  String get screensaverOverlayForecastColoredHelp =>
      'Pokazuj ikony pogody w ich własnych kolorach.';

  @override
  String get screensaverOverlayHumidity => 'Wilgotność';

  @override
  String get screensaverOverlayWind => 'Prędkość wiatru';

  @override
  String get screensaverOverlayVisibility => 'Widoczność';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return 'Odczuwalna: $temperature';
  }

  @override
  String get settingScreensaverWidgetsEnabledTitle =>
      'Włącz widżety wygaszacza ekranu';

  @override
  String get settingScreensaverWidgetsEnabledDescription =>
      'Małe nakładki w rogach wygaszacza ekranu.';

  @override
  String get settingScreensaverWidgetsTitle => 'Widżety';

  @override
  String get settingScreensaverWidgetsDescription =>
      'Małe nakładki w rogach wygaszacza ekranu.';

  @override
  String get settingScreensaverWidgetScaleTitle =>
      'Globalne skalowanie widżetów';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      'Skaluj wszystkie widżety jednocześnie, aby lepiej pasowały do rozmiaru ekranu. Każdy widżet zachowuje własną skalę względem pozostałych.';

  @override
  String get settingScreensaverWidgetFontTitle => 'Globalna rodzina czcionek';

  @override
  String get settingScreensaverWidgetFontDescription =>
      'Krój czcionki, którym rysowane są wszystkie widżety. Każdy widżet może wybrać własny.';

  @override
  String get settingScreensaverWidgetFontWeightTitle =>
      'Globalna grubość czcionki';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      'Grubość tekstu wszystkich widżetów. Domyślnie każdy wiersz ma własną grubość. Każdy widżet może wybrać własną.';

  @override
  String get settingScreensaverWidgetTextShadowTitle => 'Cień tekstu';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      'Dodaj cień do tekstu widżetów, aby poprawić czytelność na zdjęciach.';

  @override
  String get settingScreensaverVignetteStrengthTitle => 'Intensywność winiety';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      'Intensywność przyciemnienia za widżetami, poprawiająca czytelność na jasnych zdjęciach. 0 wyłącza efekt.';

  @override
  String get screensaverOverlayWidgetsEmpty => 'Brak widżetów';

  @override
  String get screensaverOverlayShow => 'Pokaż ten widżet';

  @override
  String get screensaverOverlayRemove => 'Usuń widżet';

  @override
  String get screensaverOverlayAdd => 'Dodaj widżet';

  @override
  String get screensaverOverlayAddHelp =>
      'Mały zegar, pogoda, poziom baterii lub encja w rogu ekranu.';

  @override
  String get screensaverOverlayWidgetsHint => 'Nakładki w rogach i ich skala';

  @override
  String get settingsSearchHint => 'Szukaj ustawień';

  @override
  String get settingsSearchClear => 'Wyczyść wyszukiwanie';

  @override
  String get settingsSearchResults => 'Wyniki wyszukiwania';

  @override
  String settingsSearchEmpty(String query) {
    return 'Brak ustawień pasujących do „$query”.';
  }

  @override
  String get searchInstallApk =>
      'Prześlij plik APK Kiosk Satellite przez zdalną administrację i zainstaluj go.';

  @override
  String get searchPermissionsHelp =>
      'Wszystkie uprawnienia systemu Android, z których może korzystać aplikacja, wraz z ich stanem: mikrofon, kamera, powiadomienia, nieograniczone zużycie baterii, wyświetlanie nad innymi aplikacjami, modyfikowanie ustawień systemu, ochrona interfejsu systemu, administrator urządzenia, dostęp do wszystkich plików, dostęp do danych o użyciu i lokalizacja.';

  @override
  String get searchServiceStatus => 'Stan usługi';

  @override
  String get searchServiceHelp =>
      'Czy usługa Kiosk Satellite działa i co utrzymuje w działaniu.';

  @override
  String get searchServicePermissions =>
      'Uprawnienia potrzebne usłudze Kiosk Satellite.';

  @override
  String get searchIntercomKiosks =>
      'Znane kioski i informacja, czy każdy z nich może odebrać połączenie.';

  @override
  String get searchHaValidate =>
      'Sprawdź adres URL i token w swoim Home Assistant.';

  @override
  String get searchHaProxy =>
      'Udostępnij Home Assistant działający przez zwykłe HTTP za pomocą bezpiecznego proxy w aplikacji.';

  @override
  String get searchHaDashboard =>
      'Wybierz pulpit i widok wyświetlany przez kiosk.';

  @override
  String get searchKioskPermissions =>
      'Uprawnienia, na których opierają się zabezpieczenia trybu kiosku i trybu blokady.';

  @override
  String get searchHomeStatus => 'Stan ekranu głównego';

  @override
  String get searchHomeHelp =>
      'Czy Kiosk Satellite jest ekranem głównym urządzenia i gdzie dokończyć ustawianie go jako domyślnego.';

  @override
  String get searchMasterVolume =>
      'Głośność urządzenia, względem której skalowane są suwaki głośności multimediów i asystenta.';

  @override
  String get searchSmallClock => 'Widżet zegara w rogu wygaszacza ekranu.';

  @override
  String get searchBattery =>
      'Widżet baterii w rogu wygaszacza ekranu: poziom naładowania tego urządzenia.';

  @override
  String get searchWeatherForecast =>
      'Widżet prognozy w rogu wygaszacza ekranu: nadchodzące dni z temperaturami maksymalnymi i minimalnymi.';

  @override
  String get searchPersonPermission =>
      'Uprawnienie dostępu do logów, którego wymaga czujnik wykrywania osób w urządzeniu.';

  @override
  String get searchSonosSpeakers =>
      'Głośniki Sonos znane temu urządzeniu, wyszukiwanie w sieci i pole adresu.';

  @override
  String get voiceAppearanceHint =>
      'Skórka nakładki, motyw, pasek aktywności, rozmiar tekstu';

  @override
  String get voiceSkin => 'Skórka';

  @override
  String get voiceSkinHelp => 'Wygląd nakładki asystenta głosowego.';

  @override
  String get voiceSkin1 => 'Skórka Asystenta 1';

  @override
  String get voiceSkin1Help => 'Wygląd nakładki, gdy odpowiada Asystent 1.';

  @override
  String get voiceSkin2 => 'Skórka Asystenta 2';

  @override
  String get voiceSkin2Help => 'Wygląd nakładki, gdy odpowiada Asystent 2.';

  @override
  String get voiceTheme => 'Tryb motywu';

  @override
  String get voiceThemeHelp => 'Jasny lub ciemny wygląd nakładki.';

  @override
  String get voiceReactive => 'Reaktywny pasek aktywności';

  @override
  String get voiceReactiveHelp =>
      'Pasek aktywności reaguje na dźwięk. NIEZALECANE na urządzeniach o niskiej wydajności, takich jak Echo Show.';

  @override
  String get voiceRate => 'Częstotliwość aktualizacji reaktywnego paska';

  @override
  String get voiceRateHelp =>
      'Jak często pasek aktywności jest przerysowywany. Wyższa wartość daje płynniejszy obraz, ale bardziej obciąża procesor.';

  @override
  String get voiceScaleHelp => 'Rozmiar tekstu nakładki.';

  @override
  String get voiceUpdateIntegration =>
      'Zaktualizuj integrację Voice Satellite w Home Assistant, aby sterować tymi ustawieniami z kiosku.';

  @override
  String get voiceDashboardRequired =>
      'Dostępne, gdy kiosk wyświetla pulpit Home Assistant.';

  @override
  String get voiceSkinUnavailablePlugin => 'Niedostępna skórka z wtyczki';

  @override
  String get voiceSkinDefault => 'Domyślne dla skórki';

  @override
  String get voiceBackground => 'Tło';

  @override
  String get voiceBackgroundHelp => 'Jak bardzo prześwituje pulpit.';

  @override
  String get voicePreview => 'Podgląd';

  @override
  String get voicePreviewHelp =>
      'Pokaż nakładkę na tym ekranie przez pięć sekund.';

  @override
  String get voicePreviewRemoteHelp =>
      'Pokaż nakładkę na ekranie kiosku przez pięć sekund.';

  @override
  String get settingVoiceThemeTitle => 'Motyw';

  @override
  String get settingVoiceThemeDescription =>
      'Ustawienie automatyczne dopasowuje się do motywu Home Assistant.';

  @override
  String get settingVoiceBackgroundDescription =>
      'Jak bardzo prześwituje pulpit. Wartość -1 oznacza ustawienie domyślne skórki.';

  @override
  String get settingVoiceTextScaleTitle => 'Rozmiar tekstu';

  @override
  String get settingVoiceReactiveBarTitle => 'Reaktywny pasek aktywności';

  @override
  String get settingVoiceReactiveBarDescription =>
      'Pasek reaguje na głos i odpowiedź.';

  @override
  String get voicePreviewCommand => 'Jaka jest pogoda?';

  @override
  String get voicePreviewAnswer =>
      'Teraz jest słonecznie i 22°, wieje lekki wiatr.';

  @override
  String get settingVoiceOverlayModeTitle => 'Tryb nakładki';

  @override
  String get settingVoiceOverlayModeDescription =>
      'Tryb zadokowany pokazuje mały dymek nad pulpitem. Nie wyświetla rozbudowanych wyników, takich jak obrazy, pogoda czy filmy.';

  @override
  String get voiceOverlayFullScreen => 'Pełny ekran';

  @override
  String get voiceOverlayDocked => 'Zadokowany';

  @override
  String get voiceListeningEllipsis => 'Słucham…';

  @override
  String get voiceSkinVoiceOnly => 'Tylko głos';

  @override
  String get voiceAssistant1 => 'Asystent 1';

  @override
  String get voiceAssistant1Help => 'Odpowiada na słowo wybudzające 1.';

  @override
  String get voiceAssistant2 => 'Asystent 2';

  @override
  String get voiceAssistant2Help => 'Odpowiada na słowo wybudzające 2.';

  @override
  String get voicePipelines => 'Kanały przetwarzania mowy';

  @override
  String get voicePreferred => 'Preferowany';

  @override
  String get voiceNone => 'Brak';

  @override
  String get voiceThisKiosk => 'Ten kiosk';

  @override
  String get voiceSelectFailed =>
      'Nie udało się zmienić tego w Home Assistant.';

  @override
  String get settingVoiceSeamlessWakeTitle =>
      'Mów od razu po słowie wybudzającym';

  @override
  String get settingVoiceSeamlessWakeAssistDescription =>
      'Pomiń dźwięk wybudzenia i zachowaj to, co powiesz zaraz po słowie wybudzającym. Tylko dla kanałów przetwarzania mowy Assist, nie dla rozmów w czasie rzeczywistym.';

  @override
  String get settingVoiceFollowupDelayTitle => 'Opóźnienie kontynuacji rozmowy';

  @override
  String get settingVoiceFollowupDelayDescription =>
      'Przerwa przed nasłuchiwaniem odpowiedzi na pytanie.';

  @override
  String get settingVoiceFollowupChimeTitle =>
      'Sygnał dźwiękowy przed kontynuacją rozmowy';

  @override
  String get settingVoiceFollowupChimeDescription =>
      'Odtwórz dźwięk wybudzenia, gdy urządzenie ponownie zacznie nasłuchiwać.';

  @override
  String get settingVoiceTtsOutputTitle => 'Odtwarzaj dźwięki na';

  @override
  String get settingVoiceTtsOutputDescription =>
      'Sygnały dźwiękowe, odpowiedzi, ogłoszenia i alerty minutników są odtwarzane na tym głośniku.';

  @override
  String get settingVoiceTtsOutputModeTitle => 'Odtwarzaj jako';

  @override
  String get settingVoiceTtsOutputModeDescription =>
      'Ogłoszenie pozwala głośnikowi wstrzymać muzykę i ją wznowić. Zwykłe odtwarzanie jest dla głośników, które ignorują ogłoszenia: muzyka jest potem uruchamiana ponownie.';

  @override
  String get voiceOptionAnnouncement => 'Ogłoszenie';

  @override
  String get voiceOptionNormalPlayback => 'Zwykłe odtwarzanie';

  @override
  String get voiceChimesPage => 'Sygnały dźwiękowe';

  @override
  String get voiceChimesPreview => 'Odsłuchaj na kiosku';

  @override
  String get voiceChimesPreviewFailed => 'Nie udało się odtworzyć dźwięku.';

  @override
  String get voiceChimesHelp =>
      'Wybierz dźwięki dla tego kiosku. Prześlij tutaj własne pliki. Dźwięki zapisane w Home Assistant nie są używane jako lokalne sygnały dźwiękowe.';

  @override
  String get voiceChimeWakeTitle => 'Dźwięk wybudzenia';

  @override
  String get voiceChimeWakeDescription =>
      'Odtwarzany, gdy Voice Satellite zaczyna nasłuchiwać.';

  @override
  String get voiceChimeDoneTitle => 'Dźwięk zakończenia';

  @override
  String get voiceChimeDoneDescription =>
      'Odtwarzany po zakończeniu interakcji głosowej.';

  @override
  String get voiceChimeErrorTitle => 'Dźwięk błędu';

  @override
  String get voiceChimeErrorDescription =>
      'Odtwarzany, gdy interakcja głosowa się nie powiedzie.';

  @override
  String get voiceChimeTimerTitle => 'Dźwięk minutnika';

  @override
  String get voiceChimeTimerDescription =>
      'Powtarzany po zakończeniu odliczania minutnika, dopóki go nie wyłączysz.';

  @override
  String get voiceChimeAnnounceTitle => 'Dźwięk ogłoszenia';

  @override
  String get voiceChimeAnnounceDescription =>
      'Odtwarzany przed ogłoszeniem Voice Satellite, chyba że ma ono własny dźwięk.';

  @override
  String get settingVoiceWakeSoundTitle => 'Odtwarzaj sygnały dźwiękowe';

  @override
  String get settingVoiceWakeSoundDescription =>
      'Dźwięki wybudzenia, zakończenia i błędu.';

  @override
  String get voiceChimeWakeVolumeTitle => 'Głośność dźwięku wybudzenia';

  @override
  String get voiceChimeDoneVolumeTitle => 'Głośność dźwięku zakończenia';

  @override
  String get voiceChimeErrorVolumeTitle => 'Głośność dźwięku błędu';

  @override
  String get voiceChimeTimerVolumeTitle => 'Głośność dźwięku minutnika';

  @override
  String get voiceChimeAnnounceVolumeTitle => 'Głośność dźwięku ogłoszenia';

  @override
  String get voiceChimeVolumeDescription => 'Część głośności asystenta.';

  @override
  String get voiceChimesSoundsHint =>
      'Dźwięki wybudzenia, zakończenia, błędu i ogłoszenia';

  @override
  String get settingVoiceShowCommandTitle => 'Pokazuj, co mówisz';

  @override
  String get settingVoiceShowCommandDescription =>
      'Twoje polecenie nad odpowiedzią.';

  @override
  String get settingVoiceShowAnswerTitle => 'Pokazuj odpowiedź';

  @override
  String get settingVoiceShowAnswerDescription =>
      'Pokaż odpowiedź w trakcie jej wypowiadania.';

  @override
  String get settingVoiceShowToolsTitle => 'Pokazuj użycie narzędzi';

  @override
  String get settingVoiceShowToolsDescription =>
      'Wiersz dla każdej akcji wykonanej przez asystenta.';

  @override
  String get settingVoiceHideSentimentTagsTitle => 'Ukryj tagi emocji';

  @override
  String get settingVoiceHideSentimentTagsDescription =>
      'Pomiń tagi takie jak [happy], które dodają niektórzy asystenci.';

  @override
  String get settingVoiceAnswerLingerTitle => 'Pozostaw odpowiedź na ekranie';

  @override
  String get settingVoiceAnswerLingerDescription =>
      'Po wypowiedzeniu odpowiedzi.';

  @override
  String get settingVoiceResultsLingerTitle => 'Pozostaw wyniki na ekranie';

  @override
  String get settingVoiceResultsLingerDescription =>
      'Obrazy, pogoda i inne wyniki. Wartość 0 powoduje, że pozostają one widoczne do momentu ich zamknięcia.';

  @override
  String get settingVoiceAnnouncementLingerTitle => 'Czas ogłoszenia';

  @override
  String get settingVoiceAnnouncementLingerDescription =>
      'Po wypowiedzeniu ogłoszenia.';

  @override
  String get voiceEngine => 'Silnik';

  @override
  String get voiceEngineHelp => 'Uruchom lub zatrzymaj silnik Voice Satellite.';

  @override
  String get voiceAssigned => 'Przypisany satelita';

  @override
  String get voiceAssignedHelp =>
      'Encja assist_satellite, pod którą ten kiosk występuje w Home Assistant. Zmiana powoduje przeładowanie pulpitu.';

  @override
  String get voiceAssignedSearch =>
      'Encja assist_satellite, pod którą ten kiosk występuje w Home Assistant.';

  @override
  String get voiceNoneAssigned => 'Nie przypisano';

  @override
  String get voiceAutoStart => 'Automatyczne uruchamianie';

  @override
  String get voiceAutoStartHelp =>
      'Uruchamiaj Voice Satellite automatycznie po wczytaniu pulpitu.';

  @override
  String get voiceMuteHelp => 'Zatrzymaj nasłuchiwanie słów wybudzających.';

  @override
  String get voicePipeline1 => 'Kanał przetwarzania mowy Assist 1';

  @override
  String get voicePipeline1Help =>
      'Kanał przetwarzania mowy Assist, przez który przechodzą polecenia głosowe.';

  @override
  String get voicePipeline2 => 'Kanał przetwarzania mowy Assist 2';

  @override
  String get voicePipeline2Help =>
      'Kanał przetwarzania mowy używany, gdy zadziała drugie słowo wybudzające.';

  @override
  String get voiceVad => 'Wykrywanie zakończenia wypowiedzi';

  @override
  String get voiceVadHelp => 'Jak długa przerwa kończy polecenie głosowe.';

  @override
  String get voiceMutedWarning => 'Wyłącz ostrzeżenie o wyciszonym mikrofonie';

  @override
  String get voiceMutedWarningHelp =>
      'Ukryj ostrzeżenie o wyciszonym mikrofonie przy uruchomieniu i za każdym razem, gdy mikrofon satelity jest wyciszony.';

  @override
  String get voiceDebug => 'Logi debugowania';

  @override
  String get voiceDebugHelp =>
      'Pokazuj informacje debugowania Voice Satellite w konsoli przeglądarki.';

  @override
  String get voiceVersion => 'Wersja Voice Satellite';

  @override
  String get voiceVersionHelp =>
      'Wersja integracji zainstalowana w Home Assistant.';

  @override
  String get voiceVadDefault => 'Domyślne';

  @override
  String get voiceVadRelaxed => 'Łagodne';

  @override
  String get voiceVadAggressive => 'Agresywne';

  @override
  String get voiceGeneral => 'Ogólne';

  @override
  String get voiceStart => 'Uruchom';

  @override
  String get voiceNotavailable => 'Niedostępne';

  @override
  String get voiceDisabled => 'Wyłączone';

  @override
  String get settingWakeWordBackgroundTitle => 'Nasłuchuj w tle';

  @override
  String get settingWakeWordBackgroundDescription =>
      'Wykrywa słowo wybudzające, gdy na pierwszym planie jest inna aplikacja, i wraca po jego wykryciu. Wymaga stałego powiadomienia i wyświetlania nad innymi aplikacjami.';

  @override
  String get settingWakeWordReturnToBackgroundTitle =>
      'Wróć do poprzedniej aplikacji';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      'Po zakończeniu interakcji głosowej, która przeniosła Kiosk Satellite na pierwszy plan, wraca do poprzedniej aplikacji lub ekranu głównego.';

  @override
  String get voiceAssistant => 'Asystent';

  @override
  String get voiceConversation => 'Rozmowa';

  @override
  String get voiceTimers => 'Minutniki';

  @override
  String get voiceAssistantHint =>
      'Kanały przetwarzania mowy, kontynuacja rozmowy';

  @override
  String get voiceConversationHint => 'Co pokazuje nakładka i jak długo';

  @override
  String get voiceSectionFollowUp => 'Kontynuacja rozmowy';

  @override
  String get voiceSectionLinger => 'Jak długo pozostaje';

  @override
  String get voiceSectionOnScreen => 'Na ekranie';

  @override
  String get voiceSectionPills => 'Etykiety';

  @override
  String get voiceSectionSpeaker => 'Głośnik';

  @override
  String get voiceSectionRecognition => 'Recognition';

  @override
  String get voiceSectionTrimming => 'Trimming';

  @override
  String get voiceSectionIsolation => 'Isolation';

  @override
  String get voiceSectionWakeCommand => 'Słowo wybudzające i polecenie';

  @override
  String get voiceSectionTimerEnds => 'Gdy upłynie czas';

  @override
  String get voiceSectionSharedTimers => 'Wspólne minutniki';

  @override
  String get voiceStatusEsphomeOff => 'Serwer ESPHome jest wyłączony.';

  @override
  String get voiceStatusNotAdded =>
      'Ten kiosk nie został jeszcze dodany do Home Assistant.';

  @override
  String get voiceStatusMuted => 'Mikrofon jest wyciszony.';

  @override
  String get voiceStatusNotListening =>
      'Brak nasłuchiwania słowa wybudzającego.';

  @override
  String get voiceStatusListening => 'Nasłuchiwanie słowa wybudzającego.';

  @override
  String get voiceWordNotAdded => 'Nie dodano';

  @override
  String get voiceWordMuted => 'Wyciszony';

  @override
  String get voiceWordBusy => 'Zajęty';

  @override
  String get voiceWordListening => 'Nasłuchiwanie';

  @override
  String get voiceWordNotListening => 'Brak nasłuchiwania';

  @override
  String get voiceWordAdded => 'Dodano';

  @override
  String get voiceHaAddAgainHint =>
      'Dodaj ten kiosk w Home Assistant w sekcji Ustawienia, Urządzenia i usługi, gdzie jest widoczny jako wykryty. Jeśli Home Assistant miał go już wcześniej, poprosi tam o nowy „Klucz szyfrowania” ze strony ESPHome.';

  @override
  String get voiceHaEsphomeOff =>
      'Włącz serwer ESPHome, aby Home Assistant mógł dodać ten kiosk jako satelitę.';

  @override
  String get voiceWordReloadNeeded => 'Wymagane przeładowanie';

  @override
  String get voiceHaSelectsReloadHint =>
      'Home Assistant nie wczytał encji wyboru „Asystent” i „Słowo wybudzające”. Przeładuj wpis ESPHome tego kiosku w sekcji Ustawienia, Urządzenia i usługi. Pomoże też ponowne uruchomienie Home Assistant.';

  @override
  String get voiceTurnOn => 'Włącz';

  @override
  String get voiceRollbackTitle => 'Wróć do działania z pulpitu';

  @override
  String get voiceRollbackDescription =>
      'Wróć do integracji Voice Satellite. Nic, co tu ustawiono, nie zostanie utracone.';

  @override
  String get voiceRollbackConfirm => 'Wrócić do działania z pulpitu?';

  @override
  String get voiceRollbackBody =>
      'Pulpit znów uruchomi Voice Satellite przez integrację, z wcześniejszymi ustawieniami. Ustawienia wprowadzone w tym miejscu zostaną zachowane na następny raz.';

  @override
  String get voiceRollbackSwitch => 'Przełącz z powrotem';

  @override
  String get voiceMigrateNotice =>
      'Voice Satellite jest obecnie zainstalowany jako integracja w Home Assistant. Przejdź na natywną obsługę w Kiosk Satellite.';

  @override
  String get voiceMigrate => 'Migruj';

  @override
  String get settingVoiceEnabledTitle => 'Włącz Voice Satellite';

  @override
  String get settingVoiceEnabledDescription =>
      'Zmienia ten kiosk w asystenta głosowego dla Home Assistant za pośrednictwem jego serwera ESPHome.';

  @override
  String get settingVoiceMuteTitle => 'Wycisz mikrofon';

  @override
  String get settingVoiceMuteDescription =>
      'Wstrzymuje nasłuchiwanie słowa wybudzającego.';

  @override
  String get voiceMigrationTitle => 'Migracja Voice Satellite';

  @override
  String get voiceMigrationPick =>
      'Wybierz satelitę integracji Voice Satellite, którego przejmie ten kiosk. Jego ustawienia zostaną przeniesione na ten kiosk.';

  @override
  String get voiceMigrationNoSatellites =>
      'Integracja Voice Satellite nie ma żadnych satelitów.';

  @override
  String get voiceMigrationIntro =>
      'Ten kiosk sam stanie się satelitą głosowym. Integracja Voice Satellite nie będzie potem potrzebna.';

  @override
  String get voiceMigrationCheckAgain => 'Sprawdź ponownie';

  @override
  String get voiceCheckHaBad =>
      'Brak połączenia. Sprawdź sekcję „Konfiguracja Home Assistant”.';

  @override
  String get voiceCheckEsphome => 'Ten kiosk w Home Assistant';

  @override
  String get voiceCheckEsphomeOk => 'Dodano przez ESPHome.';

  @override
  String get voiceCheckEsphomeBad =>
      'Jeszcze nie dodano. Home Assistant pokazuje ten kiosk jako wykryty w sekcji Ustawienia, Urządzenia i usługi. Dodaj go tam, a potem wróć tutaj.';

  @override
  String get voiceCheckEsphomeOff =>
      'Serwer ESPHome jest wyłączony. Włącz go, a potem dodaj ten kiosk w Home Assistant.';

  @override
  String get voiceCheckAdmin => 'Token administratora';

  @override
  String get voiceCheckAdminOk =>
      'Wykorzystanie narzędzi i wyniki będą widoczne.';

  @override
  String get voiceCheckAdminBad =>
      'To token zwykłego użytkownika. Voice Satellite działa, ale wykorzystanie narzędzi i wyniki nie będą widoczne.';

  @override
  String get voiceCheckAdminUnknown =>
      'Nie udało się sprawdzić tokenu. Wykorzystanie narzędzi i wyniki wymagają tokenu administratora.';

  @override
  String get voiceCheckMicOk => 'Dozwolone.';

  @override
  String get voiceCheckMicBad =>
      'Niedozwolone. Przyznaj uprawnienie w sekcji „Wymagane uprawnienia systemowe”.';

  @override
  String get voiceTurnOnEsphome => 'Włącz ESPHome';

  @override
  String get voiceMigrationPlan => 'Ustawienia do przeniesienia';

  @override
  String get voiceGroupVoice => 'Głos';

  @override
  String get voiceMigrationNotCarried =>
      'Nie zostaną przeniesione: własny CSS, przetwarzanie mikrofonu w przeglądarce i długość pamięci rozmowy. Własne modele microWakeWord działają z folderu config/custom_wake_words w Home Assistant.';

  @override
  String get voiceMigrationAutomations => 'Automatyzacje i skrypty';

  @override
  String get voiceMigrationNoAutomations =>
      'Nic w Home Assistant nie odwołuje się do starego satelity.';

  @override
  String get voiceKindAutomation => 'Automatyzacja';

  @override
  String get voiceKindScript => 'Skrypt';

  @override
  String get voiceMigrationReady => 'Gotowe do przełączenia';

  @override
  String get voiceMigrationReady1 =>
      'Ten kiosk nasłuchuje, odpowiada i wyświetla nakładkę.';

  @override
  String get voiceMigrationReadyOnboarding =>
      'Asystent i słowa wybudzające zostaną ustawione, gdy Home Assistant doda ten kiosk.';

  @override
  String get voiceMigrationReady2 =>
      'Pulpit przestanie uruchamiać Voice Satellite na tym kiosku.';

  @override
  String get voiceMigrationReady3 =>
      'Stary satelita pozostanie w Home Assistant, nieużywany.';

  @override
  String get voiceMigrationSwitch => 'Przełącz teraz';

  @override
  String get voiceMigrationSwitching => 'Przełączanie…';

  @override
  String get voiceMigrationDone => 'Voice Satellite działa teraz tutaj';

  @override
  String get voiceCouldNotSwitch => 'Nie udało się przełączyć';

  @override
  String get voiceMigrationDoneOnboarding =>
      'Dokończ konfigurację, a potem dodaj ten kiosk w Home Assistant. Gdy żadne inne urządzenie nie będzie używać integracji Voice Satellite, odinstaluj ją z HACS.';

  @override
  String get voiceMigrationDoneHelp =>
      'Wypowiedz słowo wybudzające, aby to przetestować. Gdy żadne inne urządzenie nie będzie używać integracji Voice Satellite, odinstaluj ją z HACS.';

  @override
  String get voiceMigrationRolledBack =>
      'Voice Satellite znów działa z pulpitu.';

  @override
  String get voiceDone => 'Gotowe';

  @override
  String get voiceTryAgain => 'Spróbuj ponownie';

  @override
  String get voiceStepSave => 'Zapisz ustawienia';

  @override
  String get voiceStepStop => 'Zatrzymaj silnik pulpitu';

  @override
  String get voiceStepStart => 'Zacznij nasłuchiwać tutaj';

  @override
  String get voiceStepTurnOn => 'Włącz Voice Satellite na tym kiosku';

  @override
  String get voiceStepEntities => 'Ustaw encje kiosku w Home Assistant';

  @override
  String get voiceStepCheck => 'Sprawdź satelitę w Home Assistant';

  @override
  String voiceMigrationStep(String n, String total) {
    return 'Krok $n z $total';
  }

  @override
  String voiceMigrationStillPoint(String satellite) {
    return 'Te elementy nadal wskazują na $satellite. Zmień je w Home Assistant, aby używały satelity tego kiosku. Kreator ich nie zmienia.';
  }

  @override
  String get voiceMigrationNotUp => 'Satelita nie uruchomił się na czas.';

  @override
  String get voiceMigrationNotReported =>
      'Home Assistant nie zgłosił satelity.';

  @override
  String get voiceMigrationBusy => 'Migracja jest już w toku.';

  @override
  String get voiceMicHeld =>
      'Funkcja wykrywania słowa wybudzającego może cię usłyszeć.';

  @override
  String get voiceMicBlocked =>
      'Zablokowano. Android nie zapyta ponownie, więc przyznaj uprawnienie w ustawieniach aplikacji.';

  @override
  String get voiceMicMissing =>
      'Bez tego nic nie nasłuchuje słowa wybudzającego.';

  @override
  String get voiceForegroundHeld =>
      'Kiosk Satellite może przejść na pierwszy plan, gdy cię usłyszy.';

  @override
  String get voiceForegroundMissing =>
      'Bez tego słowo wybudzające zostaje zarejestrowane, ale nic się nie dzieje.';

  @override
  String get voiceNotificationHeld =>
      'Stałe powiadomienie, które umożliwia nasłuchiwanie w tle.';

  @override
  String get voiceNotificationMissing =>
      'Potrzebne, aby nasłuchiwanie w tle działało niezawodnie.';

  @override
  String get voiceBatteryHeld => 'Android nie zatrzyma nasłuchiwania.';

  @override
  String get voiceBatteryMissing =>
      'Bez tego nasłuchiwanie zostanie zatrzymane po kilku godzinach.';

  @override
  String get voicePermissionDirections =>
      'Przyznaj je na samym urządzeniu: przesuń palcem od lewej krawędzi → „Ustawienia” → „Voice Satellite” → „Wymagane uprawnienia systemowe”.';

  @override
  String get voicePermissionsSearch =>
      'Mikrofon i inne uprawnienia potrzebne do wykrywania słowa wybudzającego.';

  @override
  String get voiceRealtime => 'Czas rzeczywisty';

  @override
  String get voiceRealtimeProvidersHint =>
      'OpenAI, xAI Grok, Gemini, narzędzia, przerywanie w trakcie odpowiedzi';

  @override
  String get voiceRealtimeToolsSection => 'Narzędzia Home Assistant';

  @override
  String get voiceRealtimeProviderDefault => 'Domyślne ustawienie dostawcy';

  @override
  String get voiceRealtimeToolsCustom => 'Własny serwer MCP';

  @override
  String get settingVoiceRealtimeEndpointTitle => 'Adres';

  @override
  String get settingVoiceRealtimeEndpointDescription =>
      'Pozostaw puste, aby łączyć się bezpośrednio z dostawcą. Użyj serwera pośredniczącego w swojej sieci, aby ten kiosk nie łączył się z internetem.';

  @override
  String get settingVoiceRealtimeApiKeyTitle => 'Klucz API';

  @override
  String get settingVoiceRealtimeApiKeyDescription =>
      'Pozostaw puste, jeśli dodaje go serwer pośredniczący.';

  @override
  String get settingVoiceRealtimeModelTitle => 'Model';

  @override
  String get settingVoiceRealtimeVoiceTitle => 'Głos';

  @override
  String get settingVoiceRealtimeInstructionsTitle => 'Instrukcje';

  @override
  String get settingVoiceRealtimeInstructionsDescription =>
      'Jak zachowuje się asystent. Pozostaw puste, aby użyć krótkich instrukcji domyślnych.';

  @override
  String get settingVoiceRealtimeIdleSecondsTitle => 'Zakończ po ciszy';

  @override
  String get settingVoiceRealtimeIdleSecondsDescription =>
      'Kończy rozmowę po takim czasie, gdy nikt już nie mówi.';

  @override
  String get settingVoiceRealtimeReasoningTitle => 'Poziom rozumowania';

  @override
  String get settingVoiceRealtimeReasoningDescription =>
      'Wyższy poziom pozwala lepiej odpowiadać na trudniejsze pytania. Wymaga modelu gpt-realtime-2.';

  @override
  String get settingVoiceRealtimeGeminiReasoningDescription =>
      'Wyższy poziom pozwala lepiej odpowiadać na trudniejsze pytania. Wymaga modelu z funkcją myślenia, takiego jak gemini-3.8-live-extended-thinking.';

  @override
  String get settingVoiceRealtimeGeminiSearchTitle => 'Wyszukiwanie Google';

  @override
  String get settingVoiceRealtimeGeminiSearchBillingDescription =>
      'Pozwala modelowi wyszukiwać informacje w internecie. Wymaga włączonych płatności dla klucza API.';

  @override
  String get settingVoiceRealtimeGeminiProactiveTitle =>
      'Ignoruj wypowiedzi skierowane do innych';

  @override
  String get settingVoiceRealtimeGeminiProactiveDescription =>
      'Model milczy, gdy to, co słyszy, nie jest skierowane do niego. Funkcja eksperymentalna Google.';

  @override
  String get settingVoiceRealtimeXaiWebSearchTitle =>
      'Wyszukiwanie w internecie';

  @override
  String get settingVoiceRealtimeXaiWebSearchDescription =>
      'Pozwala modelowi wyszukiwać informacje w internecie.';

  @override
  String get settingVoiceRealtimeXaiXSearchTitle => 'Wyszukiwanie w X';

  @override
  String get settingVoiceRealtimeXaiXSearchDescription =>
      'Pozwala modelowi przeszukiwać posty w X.';

  @override
  String get voiceRealtimeReasoningDefault => 'Domyślny dla modelu';

  @override
  String get voiceRealtimeReasoningMinimal => 'Minimalny';

  @override
  String get voiceRealtimeReasoningLow => 'Niski';

  @override
  String get voiceRealtimeReasoningMedium => 'Średni';

  @override
  String get voiceRealtimeReasoningHigh => 'Wysoki';

  @override
  String get voiceRealtimeReasoningExtraHigh => 'Bardzo wysoki';

  @override
  String get settingVoiceRealtimeSpeedTitle => 'Tempo wypowiedzi';

  @override
  String get settingVoiceRealtimeSpeedDescription =>
      'Jak szybko mówi asystent.';

  @override
  String get settingVoiceRealtimeHistoryHoursTitle => 'Czas trwania sesji';

  @override
  String get settingVoiceRealtimeHistoryHoursDescription =>
      'To, co zostało powiedziane w tym czasie, ma wpływ na kolejną rozmowę.';

  @override
  String get settingVoiceRealtimeTalkOverTitle =>
      'Przerywanie w trakcie odpowiedzi';

  @override
  String get settingVoiceRealtimeTalkOverDescription =>
      'Przerwij odpowiedź, zaczynając mówić. Wyłącz, jeśli asystent przerywa sam sobie.';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityTitle =>
      'Czułość przerywania';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityDescription =>
      'Jak łatwo wypowiedź przerywa odpowiedź. Zwiększ, jeśli przerywanie nie działa przy ściszonym mikrofonie. Wyższe wartości mogą sprawić, że asystent będzie przerywał sam sobie.';

  @override
  String get settingVoiceRealtimeToolsTitle => 'Narzędzia';

  @override
  String get settingVoiceRealtimeToolsDescription =>
      'Czym asystent może sterować. Home Assistant korzysta z integracji MCP Server oraz encji udostępnionych w Assist.';

  @override
  String get settingVoiceRealtimeMcpUrlTitle => 'Adres URL serwera MCP';

  @override
  String get settingVoiceRealtimeMcpUrlDescription =>
      'Adres Streamable HTTP serwera.';

  @override
  String get settingVoiceRealtimeMcpTokenTitle => 'Token MCP';

  @override
  String get settingVoiceRealtimeMcpTokenDescription =>
      'Wysyłany jako token typu bearer. Pozostaw puste, jeśli serwer go nie wymaga.';

  @override
  String get voiceRealtimeMcpMissing =>
      'Dodaj integrację MCP Server w Home Assistant, aby sterować domem.';

  @override
  String get voiceRealtimeNotValidated => 'Nie zweryfikowano';

  @override
  String voiceRealtimeOption(String provider) {
    return '$provider w czasie rzeczywistym';
  }

  @override
  String voiceRealtimeConnectFailed(String error) {
    return 'Nie udało się połączyć: $error';
  }

  @override
  String voiceRealtimeToolsUnavailable(String problem) {
    return 'Połączono, ale narzędzia Home Assistant są niedostępne: $problem';
  }

  @override
  String get settingVoiceRealtimeModelDescription =>
      'Model speech-to-speech, który udziela odpowiedzi.';

  @override
  String get settingVoiceRealtimeVoiceDescription => 'Jak brzmi asystent.';

  @override
  String get voiceRealtimeProviders => 'Dostawcy';

  @override
  String get voiceRealtimeConfigure => 'Konfiguruj';

  @override
  String get voiceRealtimeSaveValidate => 'Zapisz i zweryfikuj';

  @override
  String get voiceRealtimeNotConfigured => 'Nieskonfigurowane';

  @override
  String get voiceRealtimeValidated => 'Zweryfikowano połączenie';

  @override
  String get voiceDisconnected => 'Brak połączenia z Home Assistant';

  @override
  String get voiceValidate =>
      'Najpierw sprawdź połączenie w sekcji „Konfiguracja Home Assistant”.';

  @override
  String get voiceChecking => 'Sprawdzanie obecności Voice Satellite…';

  @override
  String get voiceMissing =>
      'Voice Satellite nie jest zainstalowany w Home Assistant';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite zmienia ten kiosk w pełnego asystenta głosowego Home Assistant obsługiwanego bez użycia rąk: wykrywanie słowa wybudzającego, rozmowy, minutniki i ogłoszenia, bezpośrednio na pulpicie.\n\nJest dostępny w domyślnym repozytorium HACS. Zainstaluj go w swojej instancji Home Assistant, a następnie wróć tutaj.';

  @override
  String get voiceLearnMore => 'Dowiedz się więcej o ';

  @override
  String get voiceGithub => 'Voice Satellite w serwisie Github';

  @override
  String get voiceHacs => 'Otwórz repozytorium HACS';

  @override
  String get voiceLoading =>
      'Wczytywanie elementów sterujących Voice Satellite…';

  @override
  String get voiceTester => 'Tester słowa wybudzającego';

  @override
  String get voiceTesterHelp =>
      'Obserwuj na żywo, co wykrywa silnik i jak to ocenia, aby sprawdzić, dlaczego słowo wybudzające działa lub nie działa.';

  @override
  String get voiceTesterSearch =>
      'Podgląd na żywo tego, co silnik wykrywa i jak to ocenia.';

  @override
  String get voiceTesterWaiting => 'Oczekiwanie na Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word (słowo zatrzymujące)';
  }

  @override
  String get voiceScore => 'Wynik';

  @override
  String get voiceThreshold => 'Próg';

  @override
  String get voiceHits => 'Trafienia';

  @override
  String get voiceNearMisses => 'Bliskie trafienia';

  @override
  String get voicePeak => 'Szczyt';

  @override
  String get voiceMicLevel => 'Poziom mikrofonu';

  @override
  String get voiceChunkProcessing =>
      'Przetwarzanie fragmentu (min / śr. / maks.)';

  @override
  String get voiceLog => 'Logi';

  @override
  String get voiceLogEmpty => 'Tutaj pojawią się wykrycia i bliskie trafienia.';

  @override
  String get voiceLogHit => 'TRAFIENIE';

  @override
  String get voiceLogNear => 'blisko';

  @override
  String get voiceLogScore => 'wynik';

  @override
  String get voiceLogDecoded => 'zdekodowano';

  @override
  String get voiceLogDistance => 'odl.';

  @override
  String get voiceLogConfidence => 'pewn.';

  @override
  String get voiceTesterPlayRecent => 'Odtwórz ostatnie 10 s';

  @override
  String get settingVoiceTimerPillsViewTitle =>
      'Pokazuj minutniki jako zaokrąglone etykiety';

  @override
  String get settingVoiceTimerPillsViewDescription =>
      'Minutniki unoszą się nad ekranem zamiast otwierać widok pełnoekranowy.';

  @override
  String get settingVoiceTimerNameInPillTitle => 'Pokazuj nazwę minutnika';

  @override
  String get settingVoiceTimerNameInPillDescription =>
      'Nazwa obok czasu na zaokrąglonej etykiecie.';

  @override
  String get settingVoiceTimerPillScaleTitle =>
      'Skala zaokrąglonych etykiet minutników';

  @override
  String get settingVoiceTimerPillScaleDescription =>
      'Rozmiar zaokrąglonych etykiet minutników.';

  @override
  String get settingVoiceTimerAlertPillTitle =>
      'Pokazuj zaokrąglone etykiety zakończonych minutników';

  @override
  String get settingVoiceTimerAlertPillDescription =>
      'Dotknij zaokrąglonej etykiety, aby zatrzymać alert.';

  @override
  String get settingVoiceMuteTimersTitle => 'Wycisz alerty minutników';

  @override
  String get settingVoiceMuteTimersDescription => 'Pokazuj alert bez dźwięku.';

  @override
  String get settingVoiceTimerNameOnAlertTitle => 'Pokazuj nazwę w alercie';

  @override
  String get settingVoiceTimerNameOnAlertDescription =>
      'Nazwa minutnika pod alertem.';

  @override
  String get settingVoiceTimerSpeakTitle =>
      'Odczytuj komunikat po zakończeniu minutnika';

  @override
  String get settingVoiceTimerSpeakDescription =>
      'Wypowiadaj frazę między dźwiękami alertu.';

  @override
  String get settingVoiceTimerPhraseTitle => 'Fraza';

  @override
  String get settingVoiceTimerPhraseDescription =>
      'Wypowiadana dla minutnika bez nazwy.';

  @override
  String get settingVoiceTimerNamedPhraseTitle =>
      'Fraza dla nazwanych minutników';

  @override
  String settingVoiceTimerNamedPhraseDescription(String name) {
    return '$name zostanie zastąpione nazwą minutnika.';
  }

  @override
  String get settingVoiceTimersShareTitle => 'Udostępniaj minutniki';

  @override
  String get settingVoiceTimersShareDescription =>
      'Minutniki uruchomione w tym kiosku działają też w wybranych kioskach.';

  @override
  String get settingVoiceTimersShareWithTitle => 'Udostępnij dla';

  @override
  String get settingVoiceTimersShareWithDescription =>
      'Kioski, które pokazują minutniki tego kiosku i sygnalizują dźwiękiem ich zakończenie.';

  @override
  String get settingVoiceTimersReceiveTitle => 'Pokazuj udostępnione minutniki';

  @override
  String get settingVoiceTimersReceiveDescription =>
      'Minutniki udostępnione przez inne kioski są tu wyświetlane i sygnalizowane dźwiękiem.';

  @override
  String get settingKioskAllowTimersTitle => 'Minutniki';

  @override
  String get settingKioskAllowTimersDescription =>
      'Otwieranie widoku minutników z menu kiosku.';

  @override
  String get settingsMenuTimersSummary =>
      'Widok pełnoekranowy, pigułki, udostępnione minutniki';

  @override
  String get fleetTheKiosksPickedInShareWithTheTimerSound =>
      'kioski wybrane w „Udostępnij dla”, dźwięk minutnika';

  @override
  String get settingTimersTtsEngineDescription =>
      'Encja zamiany tekstu na mowę w Home Assistant, która odczytuje minutniki.';

  @override
  String get settingTimersTtsLanguageDescription =>
      'Język, w którym odczytywane są minutniki.';

  @override
  String get settingTimersTtsVoiceDescription =>
      'Głos, który odczytuje minutniki.';

  @override
  String get settingTimersShowBeforeEndTitle =>
      'Pokazuj widok minutników przed zakończeniem';

  @override
  String get settingTimersShowBeforeEndDescription =>
      'Jak długo przed zakończeniem minutnika otwiera się widok minutników.';

  @override
  String get settingTimersEnabledTitle => 'Włącz minutniki';

  @override
  String get settingTimersEnabledDescription =>
      'Ustawiaj minutniki w tym kiosku za pomocą poleceń głosowych lub ręcznie.';

  @override
  String get settingTimersShowOnStartTitle =>
      'Pokazuj widok minutników po uruchomieniu minutnika';

  @override
  String get settingTimersShowOnStartDescription =>
      'Otwieraj widok minutników przy każdym uruchomieniu minutnika.';

  @override
  String get settingTimersPauseScreensaverTitle =>
      'Wstrzymaj wygaszacz ekranu podczas działania minutnika';

  @override
  String get settingTimersPauseScreensaverDescription =>
      'Wygaszacz ekranu nie włącza się, gdy widok minutników pokazuje działający minutnik.';

  @override
  String get settingTimersViewScaleTitle => 'Skala widoku minutników';

  @override
  String get settingTimersViewScaleDescription =>
      'Rozmiar nazw minutników i przycisków w widoku minutników.';

  @override
  String get settingTimersSilenceAfterTitle => 'Wyciszenie po';

  @override
  String get settingTimersSilenceAfterDescription =>
      'Zakończony minutnik pozostaje na ekranie, dopóki nie zostanie zamknięty.';

  @override
  String get settingTimersDismissAfterTitle => 'Zamknij po';

  @override
  String get settingTimersDismissAfterDescription =>
      'Usuwa zakończony minutnik tak, jakby dotknięto przycisku „Zamknij”.';

  @override
  String get settingVoiceMatchPolicyDescriptionChosen =>
      'Opcja „Wybrane osoby” ignoruje telewizor, gości i wszystkie inne osoby.';

  @override
  String get voiceMatchOptionPeople => 'Wybrane osoby';

  @override
  String get settingVoiceMatchPeopleTitle => 'Osoby';

  @override
  String get settingVoiceMatchPeopleDescription =>
      'Komu odpowiada ten kiosk. Jeśli nikogo nie wybrano, odpowiada każdej zarejestrowanej osobie.';

  @override
  String get voiceMatchPeopleNone => 'Każda zarejestrowana osoba';

  @override
  String get voiceMatchPeopleSearch => 'Szukaj osób';

  @override
  String get voiceMatchPeopleEmpty =>
      'Nikt nie jest jeszcze zarejestrowany w Ground Control.';

  @override
  String get voiceMatchPeopleGone => 'Nie ma już w Ground Control';

  @override
  String voiceMatchPeopleMissing(String names) {
    return 'Brak w aktualnie używanym Ground Control: $names. Wybierz ponownie.';
  }

  @override
  String get settingVoiceMatchRejectedTitleChosen => 'Niewybrany głos';

  @override
  String get voiceMatchFeaturesHint => 'Recognition, Trimming i Isolation';

  @override
  String get settingVoiceMatchEnabledTitle => 'Włącz Voice Match';

  @override
  String get settingVoiceMatchPolicyTitle => 'Komu odpowiadać';

  @override
  String get settingVoiceMatchRejectedDescription =>
      'Co się dzieje, gdy słowo wybudzające wypowie ktoś inny.';

  @override
  String get settingVoiceMatchSpeakerSensorTitle => 'Czujnik osoby mówiącej';

  @override
  String get settingVoiceMatchSpeakerSensorDescription =>
      'Dodaje do tego kiosku w Home Assistant czujnik osoby mówiącej, do automatyzacji i instrukcji agenta.';

  @override
  String get voiceMatchOptionAnyone => 'Każdy';

  @override
  String get voiceMatchOptionQuiet => 'Zachowaj ciszę';

  @override
  String get voiceMatchOptionChime => 'Odtwórz dźwięk błędu';

  @override
  String get voiceMatchConnecting => 'Łączenie';

  @override
  String get voiceMatchSearching => 'Wyszukiwanie';

  @override
  String get voiceMatchNotReachable => 'Nieosiągalne';

  @override
  String get voiceMatchSignInRefused => 'Odmowa logowania';

  @override
  String get voiceMatchNobodyEnrolled =>
      'Nikt nie jest jeszcze zarejestrowany.';

  @override
  String get voiceMatchTokenRefused =>
      'Home Assistant odrzucił token tego kiosku.';

  @override
  String get settingVoiceMatchShowSpeakerTitle => 'Pokazuj, kto mówi';

  @override
  String get settingVoiceMatchShowSpeakerDescription =>
      'Imię osoby mówiącej przed poleceniem na nakładce głosowej, w jej kolorze. Na urządzeniu z pierścieniem świetlnym ten kolor przyjmuje łuk nasłuchiwania.';

  @override
  String get settingVoiceMatchAllowEnrollTitle => 'Zezwól na rejestrację tutaj';

  @override
  String get voiceMatchAppHint => 'Osoby, rejestracja, sesje i ustawienia.';

  @override
  String get voiceMatchOpen => 'Otwórz';

  @override
  String get settingVoiceMatchEnabledDescriptionCommand =>
      'Rozpoznaje, kto mówi, i pozostawia tylko głos rozpoznanej osoby w poleceniu. Wymaga Ground Control.';

  @override
  String get settingVoiceMatchAllowEnrollDescriptionGroundControl =>
      'Pozwala aplikacji Ground Control nagrać głos osoby mikrofonem tego kiosku. Kiosk wyświetla tekst do przeczytania albo pierścień świetlny pokazuje postęp.';

  @override
  String get settingVoiceMatchTrimmingTitle => 'Włącz Trimming';

  @override
  String get settingVoiceMatchTrimmingDescription =>
      'Inne dźwięki, takie jak telewizor lub głosy innych osób, są wyciszane w przerwach między słowami osoby, która wypowiedziała słowo wybudzające, a polecenie kończy się, gdy ta osoba przestanie mówić.';

  @override
  String get settingVoiceMatchIsolationTitle => 'Włącz Isolation';

  @override
  String get settingVoiceMatchIsolationDescription =>
      'Inne głosy zagłuszające słowa osoby, która wypowiedziała słowo wybudzające, są również usuwane. Gdy ta osoba przestanie mówić, polecenie czeka na zakończenie tego procesu. Wymaga włączenia Isolation w Ground Control.';

  @override
  String get voiceWakePage => 'Słowo wybudzające';

  @override
  String get voiceWakeHint =>
      'Silnik, słowa wybudzające, czułość, modele w pamięci podręcznej';

  @override
  String get voiceWakeLabel => 'Słowo wybudzające';

  @override
  String get voiceWakeEngine => 'Silnik słowa wybudzającego';

  @override
  String get voiceWakeEngineHelp =>
      'Gdzie działa wykrywanie i który silnik nasłuchuje.';

  @override
  String get voiceWake1 => 'Słowo wybudzające 1';

  @override
  String get voiceWake1Help => 'Słowo, które rozpoczyna polecenie głosowe.';

  @override
  String get voiceWake2 => 'Słowo wybudzające 2';

  @override
  String get voiceWake2Help =>
      'Drugie słowo wybudzające, na które odpowiada kanał przetwarzania mowy Assist 2.';

  @override
  String get voiceSensitivity => 'Czułość słowa wybudzającego';

  @override
  String get voiceSensitivityHelp =>
      'Jak łatwo aktywuje się słowo wybudzające.';

  @override
  String get voiceNoiseGate => 'Bramka szumów słowa wybudzającego';

  @override
  String get voiceNoiseGateHelp =>
      'Pomija lokalne rozpoznawanie słowa wybudzającego, gdy w pomieszczeniu jest cicho, co oszczędza procesor.';

  @override
  String get voiceStopInterruption => 'Przerywanie słowem zatrzymującym';

  @override
  String get voiceStopInterruptionHelp =>
      'Wypowiedz słowo zatrzymujące, aby przerwać odpowiedź.';

  @override
  String get voiceAssignFirst =>
      'Przypisz satelitę, aby sterować tymi ustawieniami.';

  @override
  String get voiceCachedModels => 'Modele w pamięci podręcznej';

  @override
  String get voiceCachedModelsHelp =>
      'Pobierz ponownie z Home Assistant. Użyj po ponownym opublikowaniu modelu.';

  @override
  String get voiceClearCache => 'Wyczyść pamięć podręczną';

  @override
  String get voiceClearing => 'Czyszczenie…';

  @override
  String voiceCacheCleared(String count) {
    return 'Usunięte pliki: $count. Ponowne pobieranie.';
  }

  @override
  String voiceCacheCount(String count) {
    return 'Wyczyszczono: $count';
  }

  @override
  String get voiceVerySensitive => 'Bardzo czułe';

  @override
  String get voiceWakeWordPreferFp32Title => 'Preferuj modele vsWakeWord fp32';

  @override
  String get voiceWakeWordPreferFp32Description =>
      'Używa modeli fp32 zamiast mniejszych wersji int8. Zwiększa użycie procesora podczas nasłuchiwania o 10-30%, aby uniknąć odchylenia poziomu ufności rzędu 2%.';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle =>
      'Limit czasu wznowienia (s)';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      'Samonaprawa: wznawia nasłuchiwanie, jeśli strona nie wywoła setWakeWordActive(true) po przekazaniu. Czeka, dopóki tura głosowa nadal przesyła strumień audio, dzięki czemu długa tura nigdy nie zostaje przerwana.';

  @override
  String get voiceSlightlySensitive => 'Mało czułe';

  @override
  String get voiceModeratelySensitive => 'Średnio czułe';

  @override
  String get voiceOnDevice => 'Na urządzeniu';

  @override
  String voiceOnDeviceEngine(String engine) {
    return 'Na urządzeniu ($engine)';
  }

  @override
  String get voiceDiagnosticsPage => 'Diagnostyka słowa wybudzającego';

  @override
  String get voiceDiagnosticsHint =>
      'Ostatnie aktywacje i niedoszłe aktywacje z klipami audio';

  @override
  String get voiceDiagnosticsTitle => 'Włącz diagnostykę słowa wybudzającego';

  @override
  String get voiceDiagnosticsDescription =>
      'Zapisuje 10 ostatnich aktywacji słowa wybudzającego i niedoszłych aktywacji wraz z wynikami oraz 3-sekundowym klipem audio każdej z nich. Wyłączenie tej opcji je usuwa.';

  @override
  String get voiceDiagnosticsEmpty =>
      'Nie zarejestrowano jeszcze żadnych aktywacji słowa wybudzającego.';

  @override
  String get voiceDiagnosticsActivations => 'Aktywacje';

  @override
  String get voiceDiagnosticsNoNearMisses =>
      'Nie zarejestrowano jeszcze bliskich trafień.';

  @override
  String get voiceDiagnosticsPeakLevel => 'Poziom szczytowy';

  @override
  String get voiceDiagnosticsAverageLevel => 'Poziom średni';

  @override
  String get voiceDiagnosticsClipped => 'Przesterowanie';

  @override
  String get voiceDiagnosticsHeard => 'Usłyszane';

  @override
  String get voiceWake2HelpNative =>
      'Drugie słowo wybudzające, na które odpowiada Asystent 2.';

  @override
  String get voiceCustomModels => 'Własne modele';

  @override
  String get voiceCustomNone => 'Brak własnych modeli.';

  @override
  String get voiceCustomManaged =>
      'Lider floty zarządza modelami niestandardowymi w tym kiosku.';

  @override
  String get voiceCustomAdd => 'Dodaj modele';

  @override
  String get voiceCustomAddHelp =>
      'Wybierz pliki jednego lub kilku modeli. Pojawią się powyżej, w polach „Słowo wybudzające 1” i „Słowo wybudzające 2”.';

  @override
  String get voiceCustomDocs => 'Jak dodać własne modele';

  @override
  String get voiceCustomDocsHelp =>
      'Jakie pliki są potrzebne dla każdego silnika i skąd pochodzą modele.';

  @override
  String get voiceCustomNotAdded => 'Nie dodano modeli.';

  @override
  String get voiceCustomSomeNotAdded => 'Nie dodano niektórych plików.';

  @override
  String get voiceCustomAdded => 'Dodano modele.';

  @override
  String get voiceCustomDeleteConfirm => 'Usunąć ten model?';

  @override
  String get voiceCustomNotDeleted => 'Nie usunięto modelu.';

  @override
  String get voiceCustomOtherEngine => 'nie dla używanego silnika';

  @override
  String get settingVoiceWakeWordEngineDescription =>
      'Silnik, który nasłuchuje. Wszystkie modele są dołączone do aplikacji.';

  @override
  String get settingVoiceWakeWordSensitivityTitle =>
      'Czułość słowa wybudzającego';

  @override
  String get settingVoiceWakeWordSensitivityDescription =>
      'Jak łatwo aktywuje się słowo wybudzające.';

  @override
  String get settingVoiceWakeWordFineTuneTitle =>
      'Dokładne dostrajanie czułości';

  @override
  String get settingVoiceWakeWordFineTuneDescription =>
      'Dostosowuje czułość słowa wybudzającego w mniejszych krokach. Zwiększ ją, jeśli często musisz powtarzać słowo wybudzające, zmniejsz, jeśli urządzenie wybudza się przez pomyłkę.';

  @override
  String get settingVoiceNoiseGateTitle => 'Bramka szumów słowa wybudzającego';

  @override
  String get settingVoiceNoiseGateDescription =>
      'Pomijaj rozpoznawanie słowa wybudzającego, gdy w pomieszczeniu jest cicho, aby oszczędzać procesor.';

  @override
  String get settingVoiceStopWordTitle => 'Przerywanie słowem zatrzymującym';

  @override
  String get settingVoiceStopWordDescription =>
      'Powiedz „stop”, aby przerwać odpowiedź, alarm minutnika lub ogłoszenie.';

  @override
  String get settingVoiceStopWordFineTuneTitle =>
      'Dokładne dostrajanie czułości słowa zatrzymującego';

  @override
  String get settingVoiceStopWordFineTuneDescription =>
      'Dostosowuje czułość słowa zatrzymującego w mniejszych krokach. Zwiększ ją, jeśli często musisz powtarzać „stop”, zmniejsz, jeśli odpowiedzi przerywają się przez pomyłkę.';

  @override
  String get settingVoiceWakeArbitrationTitle =>
      'Włącz arbitraż słowa wybudzającego';

  @override
  String get settingVoiceWakeArbitrationDescription =>
      'Gdy kilka kiosków usłyszy słowo wybudzające, odpowiada najbliższy. Zwiększa opóźnienie wykrywania.';

  @override
  String get settingVoiceWakeArbitrationWindowTitle => 'Okno arbitrażu';

  @override
  String get settingVoiceWakeArbitrationWindowDescription =>
      'Jak długo czekać na pozostałe kioski. Zwiększ, jeśli wolniej działający kiosk nie nadąża reagować, mimo że jest bliżej.';

  @override
  String get settingVoiceWakeArbitrationOffsetTitle => 'Przesunięcie arbitrażu';

  @override
  String get settingVoiceWakeArbitrationOffsetDescription =>
      'Dodatkowo wzmacnia głośność, z jaką ten kiosk zarejestrował słowo wybudzające. Zwiększ, jeśli ten kiosk nie nadąża reagować, mimo że jest bliżej, zmniejsz, jeśli odpowiada ze zbyt dużej odległości.';

  @override
  String get voiceSectionWakeArbitration => 'Arbitraż słowa wybudzającego';

  @override
  String get voiceOptionSlightly => 'Mało czułe';

  @override
  String get voiceOptionModerately => 'Średnio czułe';

  @override
  String get voiceOptionVery => 'Bardzo czułe';

  @override
  String get voiceModelNotFileName => 'To nie jest nazwa pliku.';

  @override
  String get voiceModelBadExtension =>
      'Modelami są tylko pliki .json, .tflite i .onnx.';

  @override
  String voiceModelTooLarge(String name) {
    return 'Plik $name jest większy niż 64 MB.';
  }

  @override
  String voiceModelIncomplete(String name) {
    return 'Plik $name dotarł niekompletny.';
  }

  @override
  String voiceModelBadJson(String file) {
    return 'Plik $file nie jest prawidłowym plikiem JSON.';
  }

  @override
  String voiceModelNotManifest(String file) {
    return 'Plik $file nie jest manifestem.';
  }

  @override
  String voiceModelMwwNeedsTflite(String file) {
    return 'Model microWakeWord wymaga również pliku $file.';
  }

  @override
  String voiceModelMwwBadManifest(String file) {
    return 'Plik $file nie jest prawidłowym manifestem microWakeWord.';
  }

  @override
  String voiceModelVswwNeedsOnnx(String file) {
    return 'Model vsWakeWord wymaga również pliku $file.';
  }

  @override
  String voiceModelVswwBadManifest(String file) {
    return 'Plik $file nie jest prawidłowym manifestem vsWakeWord.';
  }

  @override
  String voiceModelUnknownManifest(String file) {
    return 'Plik $file nie jest manifestem ani microWakeWord, ani vsWakeWord.';
  }

  @override
  String voiceModelNoModelFile(String name) {
    return 'Brak pliku modelu dla $name.';
  }

  @override
  String voiceModelBothFormats(String onnx, String tflite) {
    return 'Dodaj plik $onnx albo $tflite, nie oba.';
  }

  @override
  String voiceModelNotOwwTflite(String file, String json) {
    return 'Plik $file nie jest modelem openWakeWord. Model microWakeWord wymaga również swojego pliku $json.';
  }

  @override
  String get voiceModelNotTflite => 'To nie jest model TFLite.';

  @override
  String get voiceModelNotOnnx => 'To nie jest model ONNX.';

  @override
  String get voiceModelNotOww => 'To nie jest model openWakeWord.';

  @override
  String get voiceModelOwwWindow =>
      'To nie jest model openWakeWord: nie przyjmuje okna osadzeń 16 x 96.';

  @override
  String voiceModelNoLoad(String error) {
    return 'Nie można wczytać modelu: $error';
  }

  @override
  String get settingVoiceAmazonLocaleTitle => 'Język słowa wybudzającego';

  @override
  String get settingVoiceAmazonLocaleDescription =>
      'Język modeli słów wybudzających Amazon. Listy wyboru słowa wybudzającego zawierają słowa dostępne w tym języku.';

  @override
  String get settingDisableCacheTitle => 'Wyłącz pamięć podręczną';

  @override
  String get settingDisableCacheDescription =>
      'Zawsze pobiera dane z sieci i usuwa dane strony z pamięci podręcznej podczas ładowania, aby ponownie wdrożony pulpit wyświetlał się w najnowszej wersji. Spowalnia działanie; traktuj to jako pomoc przy programowaniu.';

  @override
  String get settingAllowMixedContentTitle => 'Zezwalaj na treści mieszane';

  @override
  String get settingAllowMixedContentDescription =>
      'Pozwala stronom HTTPS wczytywać niezabezpieczone zasoby HTTP. Pomaga, gdy pulpit https:// zawiera treści http:// umieszczone przez Home Assistant.';

  @override
  String get settingIgnoreSslErrorsTitle => 'Ignoruj błędy SSL';

  @override
  String get settingIgnoreSslErrorsDescription =>
      'Akceptuj niezaufane lub samopodpisane certyfikaty. Używaj tylko we własnej sieci, ponieważ wyłącza to weryfikację certyfikatów.';

  @override
  String get settingBrowserUserAgentTitle =>
      'Własny identyfikator przeglądarki';

  @override
  String get settingBrowserUserAgentDescription =>
      'Wysyłany do stron internetowych zamiast domyślnego identyfikatora przeglądarki. Pozostaw puste, aby użyć domyślnego.';

  @override
  String get webGeolocationSection => 'Geolokalizacja HTML5';

  @override
  String get settingWebGeolocationTitle => 'Włącz dostęp do geolokalizacji';

  @override
  String get settingWebGeolocationDescription =>
      'Pozwala stronom, takim jak radar pogodowy czy mapa, odczytywać lokalizację urządzenia. Prosić o nią mogą tylko strony wczytane przez HTTPS.';

  @override
  String get webGeolocationPermissionHeld =>
      'Strony mogą odczytywać lokalizację urządzenia.';

  @override
  String get webGeolocationPermissionMissing =>
      'Bez tego uprawnienia strony nie mogą odczytywać lokalizacji urządzenia.';

  @override
  String get settingAutoReloadOnErrorTitle =>
      'Automatyczne przeładowanie po błędzie';

  @override
  String get settingAutoReloadOnErrorDescription =>
      'Automatycznie przywraca działanie po błędach stron i awariach aplikacji.';

  @override
  String get settingPullToRefreshTitle => 'Włącz odświeżanie przeciągnięciem';

  @override
  String get settingPullToRefreshDescription =>
      'Przeciągnij w dół od góry strony, aby ją odświeżyć. Domyślnie wyłączone: na przewijanym pulpicie łatwo o przypadkowe przeciągnięcie.';

  @override
  String get settingPullToRefreshClearCacheTitle =>
      'Wyczyść pamięć podręczną przy odświeżaniu przeciągnięciem';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      'Przeciągnięcie przed przeładowaniem strony czyści też pamięć podręczną stron i modele słów wybudzających, więc wszystko wczytuje się od nowa. Sesja logowania i zapisane dane stron zostają zachowane.';

  @override
  String get settingBrowserZoomTitle => 'Poziom powiększenia';

  @override
  String get settingBrowserZoomDescription =>
      'Skaluje całą stronę. Wartość powyżej 1x przydaje się na tabletach ściennych oglądanych z odległości; poniżej 1x na małym ekranie zmieści się więcej pulpitu.';

  @override
  String get settingPinchToZoomTitle => 'Włącz powiększanie dwoma palcami';

  @override
  String get settingPinchToZoomDescription =>
      'Powiększaj stronę, rozsuwając lub zsuwając dwa palce. Domyślnie wyłączone, aby pulpit kiosku nie przesuwał się od przypadkowych dotknięć.';

  @override
  String get settingDisableScrollingTitle => 'Wyłącz przewijanie';

  @override
  String get settingDisableScrollingDescription =>
      'Blokuje stronę w miejscu, tak że nie można jej przewijać w żadnym kierunku. Dotknięcia i przyciski nadal działają.';

  @override
  String get browserCrashPermissionHelp =>
      'Bez tego uprawnienia kiosk nie może wrócić po awarii.';

  @override
  String get browserCrashPermissionMissing =>
      'Brak uprawnienia „Wyświetlanie nad innymi aplikacjami”';

  @override
  String get browserCrashPermissionRemoteHelp =>
      'Bez niego kiosk nie może sam wrócić po awarii. Ekran przyznawania uprawnienia wyświetli się na tablecie.';

  @override
  String get settingBrowserInjectJsTitle =>
      'Wstrzyknij JavaScript do pulpitu HA';

  @override
  String get settingBrowserInjectJsDescription =>
      'Uruchamiaj ten kod JavaScript po każdym wczytaniu strony pulpitu. Przydaje się do ukrycia rozpraszających elementów lub dostosowania pulpitu, którego nie można samodzielnie zmieniać.';

  @override
  String get settingBrowserInjectJsExternalTitle =>
      'Wstrzyknij JavaScript do stron zewnętrznych';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      'Uruchamiaj ten kod JavaScript po wczytaniu każdej strony zewnętrznej: stron otwartych z linku na pulpicie, stron w rotacji pulpitów i wygaszacza ekranu „Strona internetowa”. Strona Music Assistant pozostaje bez zmian.';

  @override
  String get browserInjectJsPlaceholder =>
      '// Przykład: ukryj rozpraszający element\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// Przykład: powiększ stronę, która ignoruje poziom powiększenia pulpitu\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get urlFilterTitle => 'Filtr adresów URL';

  @override
  String get urlFilterHint =>
      'Blokuj lub dopuszczaj strony według wzorca adresu albo wyrażenia regularnego';

  @override
  String get urlFilterIntroTitle => 'Określ, które strony mogą zostać otwarte';

  @override
  String get urlFilterIntroSub =>
      'Linki i strony pasujące do reguły „Blokuj” nie wczytują się. Dodaj regułę „Tylko dozwolone”, aby wczytywać tylko pasujące do niej strony.';

  @override
  String get urlFilterAdd => 'Dodaj regułę';

  @override
  String get urlFilterAddTitle => 'Dodaj regułę filtra';

  @override
  String get urlFilterEditTitle => 'Edytuj regułę filtra';

  @override
  String get urlFilterName => 'Nazwa';

  @override
  String get urlFilterPattern => 'Wzorzec';

  @override
  String get urlFilterPatternWildcardHint =>
      'Użyj *, aby dopasować dowolny ciąg znaków. Wzorzec zaczynający się od / pasuje do ścieżki na dowolnym serwerze, np. /history*.';

  @override
  String get urlFilterPatternRegexHint =>
      'Wyrażenie regularne dopasowywane w dowolnym miejscu adresu, bez rozróżniania wielkości liter.';

  @override
  String get urlFilterType => 'Typ wzorca';

  @override
  String get urlFilterTypeWildcard => 'Znak wieloznaczny';

  @override
  String get urlFilterTypeRegex => 'Wyrażenie regularne';

  @override
  String get urlFilterAction => 'Akcja';

  @override
  String get urlFilterActionBlock => 'Blokuj';

  @override
  String get urlFilterActionAllow => 'Tylko dozwolone';

  @override
  String get urlFilterActionAllowHint =>
      'Tam, gdzie obowiązuje ta reguła, wczytują się tylko strony pasujące do reguły „Tylko dozwolone”. Logowanie do Home Assistant i pulpit startowy wczytują się zawsze.';

  @override
  String get urlFilterScope => 'Dotyczy';

  @override
  String get urlFilterScopeAll => 'Pulpit i strony zewnętrzne';

  @override
  String get urlFilterScopeDashboard => 'Pulpit';

  @override
  String get urlFilterScopeExternal => 'Strony zewnętrzne';

  @override
  String get urlFilterScopeHint =>
      'Strony zewnętrzne to linki otwierane z pulpitu oraz strony z rotacji pulpitu.';

  @override
  String get urlFilterErrorName => 'Wpisz nazwę.';

  @override
  String get urlFilterErrorPattern => 'Wpisz wzorzec.';

  @override
  String get urlFilterErrorRegex =>
      'To wyrażenie regularne jest nieprawidłowe.';

  @override
  String get urlFilterBlocked => 'Strona zablokowana';

  @override
  String get urlFilterNotAllowed => 'Spoza dozwolonych stron';

  @override
  String get settingBrowserUrlFilterNoticeTitle =>
      'Pokazuj komunikat o zablokowanej stronie';

  @override
  String get settingBrowserUrlFilterNoticeDescription =>
      'Pokazuj krótki komunikat z nazwą reguły, gdy strona zostanie zablokowana.';

  @override
  String get setupConnectHeading => 'Połącz z Home Assistant';

  @override
  String get setupConnectLead =>
      'Bazowy adres URL twojej instancji i długoterminowy token dostępu, utworzony w twoim „profilu HA” → „Bezpieczeństwo” → „Długotrwałe tokeny dostępu”.';

  @override
  String get setupBaseUrl => 'Bazowy adres URL Home Assistant';

  @override
  String get setupToken => 'Długotrwały token dostępu';

  @override
  String get setupScanQr => 'Zeskanuj kod QR';

  @override
  String get setupInvalidToken => 'Nieprawidłowy token dostępu';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant odrzucił ten token. W Home Assistant otwórz swój „profil” → „Bezpieczeństwo” → „Długotrwałe tokeny dostępu”, utwórz nowy token i skopiuj całą jego wartość.';

  @override
  String get setupUnreachable => 'Brak dostępu do Home Assistant';

  @override
  String get setupUnreachableHelp =>
      'Brak odpowiedzi z tego adresu. Sprawdź, czy adres URL jest poprawny i czy to urządzenie jest w tej samej sieci co serwer Home Assistant.';

  @override
  String get setupUnexpectedResponseHelp =>
      'Serwer odpowiedział, ale nie wygląda na Home Assistant. Sprawdź, czy adres URL to bazowy adres Home Assistant, na przykład https://homeassistant.local:8123.';

  @override
  String get setupCannotConnect => 'Nie można się połączyć';

  @override
  String get setupCameraPermission => 'Wymagane uprawnienie do kamery';

  @override
  String get setupCameraBlocked =>
      'Zezwól aplikacji Kiosk Satellite na dostęp do kamery w ustawieniach systemu Android, aby zeskanować kod QR.';

  @override
  String get setupCameraAllow =>
      'Zezwól na dostęp do kamery, aby zeskanować kod QR.';

  @override
  String get setupEnterBaseUrl => 'Wpisz bazowy adres URL Home Assistant';

  @override
  String get setupInvalidBaseUrl => 'Nieprawidłowy bazowy adres URL';

  @override
  String get setupBaseUrlHelp =>
      'To adres, pod którym otwierasz Home Assistant, na przykład https://homeassistant.local:8123.';

  @override
  String get setupEnterToken => 'Wpisz Długotrwały token dostępu';

  @override
  String get setupEnterTokenHelp =>
      'W Home Assistant otwórz swój „profil” → „Bezpieczeństwo” → „Długotrwałe tokeny dostępu”, aby go utworzyć.';

  @override
  String get setupValidateContinue => 'Sprawdź i kontynuuj';

  @override
  String setupUnexpectedResponse(String error) {
    return 'Nieoczekiwana odpowiedź ($error)';
  }

  @override
  String get baseUrlInvalid =>
      'Wpisz prawidłowy adres URL, na przykład https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      'Wpisz tylko bazowy adres URL, bez ścieżki pulpitu. Przykład: https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      'Wpisz tylko bazowy adres URL, bez żadnych znaków po numerze portu. Przykład: https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => 'Wybierz pulpit';

  @override
  String get setupDashboardHelp =>
      'To właśnie kiosk wyświetli po uruchomieniu.';

  @override
  String get setupSelectDashboard => 'Wybierz pulpit';

  @override
  String get setupSelectDashboardHelp =>
      'Wybierz pulpit, który będzie wyświetlany w kiosku. Pulpit można później zmienić w ustawieniach.';

  @override
  String get setupHeadlessGrants =>
      'To urządzenie nie ma ekranu, więc Android nie może na nim poprosić o te uprawnienia. Nadaj każde z nich przez adb, a następnie dokończ tutaj.';

  @override
  String get setupWelcome => 'Witaj';

  @override
  String get setupConnect => 'Połączenie';

  @override
  String get setupConnectSummary => 'Adres URL i token Home Assistant';

  @override
  String get setupDashboard => 'Pulpit';

  @override
  String get setupDashboardSummary => 'Co wyświetla kiosk';

  @override
  String get setupRecommendedSummary => 'Zalecane ustawienia';

  @override
  String get setupPermissions => 'Uprawnienia';

  @override
  String get setupPermissionsSummary => 'Czego potrzebuje konfiguracja';

  @override
  String get setupPermissionLead =>
      'Android poprosi o te uprawnienia. Wszystkie prośby pojawiają się na początku, dzięki czemu kiosk nie będzie później przeszkadzać.';

  @override
  String get setupRemotePermissionLead =>
      'Android prosi o te uprawnienia na samym tablecie. Podejdź do niego i zaakceptuj wyświetlone prośby, a następnie dokończ tutaj.';

  @override
  String get setupMicrophoneHelp =>
      'Voice Satellite i interkom wymagają dostępu do mikrofonu';

  @override
  String get setupNotificationListening =>
      'Umożliwia wyświetlanie stałego powiadomienia usługi Kiosk Satellite, które informuje, co usługa utrzymuje w działaniu i kiedy kiosk nasłuchuje.';

  @override
  String get setupBatteryService =>
      'Pozwala usłudze Kiosk Satellite działać w tle bez wstrzymywania ani wymuszonego zamykania.';

  @override
  String get setupOverlayBoot =>
      'Pozwala aplikacji Kiosk Satellite wrócić po awarii i uruchomić się przy starcie urządzenia.';

  @override
  String get setupOverlayCrash =>
      'Pozwala aplikacji Kiosk Satellite wrócić na ekran po awarii.';

  @override
  String get setupBrightnessHelp =>
      'Pozwala aplikacji Kiosk Satellite ustawiać rzeczywistą jasność panelu (modyfikowanie ustawień systemu).';

  @override
  String get setupScreenControl => 'Sterowanie ekranem';

  @override
  String get setupScreenControlHelp =>
      'Pozwala aplikacji Kiosk Satellite wyłączać ekran na żądanie (administrator urządzenia).';

  @override
  String get setupGrantPermissions => 'Nadaj uprawnienia na urządzeniu';

  @override
  String get setupRequestingPermissions => 'Wysyłanie próśb do urządzenia…';

  @override
  String get setupPermissionsRequested =>
      'Poproszono o uprawnienia na urządzeniu';

  @override
  String get setupQrFlipCamera => 'Przełącz kamerę';

  @override
  String get setupQrCameraFailed => 'Nie udało się uruchomić kamery.';

  @override
  String get setupQrTitle => 'Zeskanuj kod QR tokenu';

  @override
  String get setupQrHelp =>
      'Pojawia się obok nowo utworzonego tokenu w profilu użytkownika Home Assistant.';

  @override
  String get setupQrFlashOff => 'Wyłącz latarkę';

  @override
  String get setupQrFlashOn => 'Włącz latarkę';

  @override
  String get setupQrScreenLightOff => 'Wyłącz oświetlenie ekranem';

  @override
  String get setupQrScreenLightOn => 'Włącz oświetlenie ekranem';

  @override
  String get setupPasswordFirst => 'Najpierw ustaw hasło administratora';

  @override
  String get setupPasswordBeforeImport =>
      'Wpisz hasło administratora w polu powyżej (co najmniej 4 znaki), a następnie zaimportuj kopię zapasową.';

  @override
  String get setupPasswordFailed => 'Nie udało się ustawić hasła';

  @override
  String get setupPasswordExists => 'Hasło jest już ustawione';

  @override
  String get setupPasswordExistsHelp =>
      'Zaloguj się hasłem ustawionym na tablecie, aby kontynuować tutaj. Przeładowywanie…';

  @override
  String get setupNotBackup => 'To nie jest plik kopii zapasowej';

  @override
  String get setupInvalidBackupHelp =>
      'Ten plik nie jest prawidłowym plikiem JSON. Wyeksportuj konfigurację z ustawień skonfigurowanej aplikacji Kiosk Satellite albo z jej zdalnej administracji.';

  @override
  String get setupWrongBackupKind =>
      'Wyeksportuj konfigurację z karty ustawień skonfigurowanej aplikacji Kiosk Satellite.';

  @override
  String get setupImportFailedHelp => 'Nie udało się zastosować pliku.';

  @override
  String get setupBackupNoDashboard => 'Kopia zapasowa nie zawiera pulpitu';

  @override
  String get setupBackupNoDashboardHelp =>
      'Zastosowano ustawienia, ale tę kopię zapasową utworzono przed konfiguracją jej urządzenia, więc nie ma pulpitu do wyświetlenia. Przejdź dalej w kreatorze, aby wybrać pulpit.';

  @override
  String get setupImporting => 'Importowanie…';

  @override
  String get setupRemoteRestoreHelp =>
      'Zaimportuj konfigurację wyeksportowaną z Kiosk Satellite i pomiń resztę kreatora.';

  @override
  String get setupFinishOnDevice => 'Dokończ na urządzeniu';

  @override
  String get setupFinishOnDeviceHelp =>
      'Zaimportowano konfigurację. Odpowiedz na prośby o uprawnienia na ekranie tabletu. Ta strona przejdzie dalej automatycznie po wczytaniu pulpitu.';

  @override
  String get setupBackupObject => 'Kopia zapasowa musi zawierać obiekt JSON.';

  @override
  String get setupBackupKind =>
      'To nie jest plik konfiguracji Kiosk Satellite.';

  @override
  String get setupBackupSettings => 'Kopia zapasowa nie zawiera ustawień.';

  @override
  String get setupServiceHelp =>
      'Utrzymuje aplikację w działaniu, gdy ekran jest wyłączony lub na pierwszym planie jest inna aplikacja, dzięki czemu połączenie z Home Assistant oraz inne funkcje, takie jak wykrywanie ruchu i proxy Bluetooth, pozostają aktywne. Poniższe uprawnienia są opcjonalne, ale zalecane: każde z nich pomaga usłudze przetrwać wyłączenie ekranu.';

  @override
  String get setupBatteryMissing =>
      'Android może wstrzymywać aplikację przy wyłączonym ekranie, zrywając przy tym połączenie z Home Assistant.';

  @override
  String get setupOverlayMissing =>
      'Bez tego uprawnienia usługa nie może ponownie uruchomić kiosku po awarii.';

  @override
  String get setupVoiceDetected => 'Wykryto Voice Satellite';

  @override
  String get setupVoiceHelp =>
      'Ta instancja Home Assistant korzysta z integracji Voice Satellite. Wybierz, którym satelitą jest ten kiosk, a następnie przejrzyj jego ustawienia. Wszystko można później zmienić.';

  @override
  String get setupNoSatellites => 'Nie znaleziono satelitów';

  @override
  String get setupNoSatellitesHelp =>
      'Dodaj satelitę asystenta w integracji Voice Satellite lub kontynuuj bez niego i wybierz go później na pulpicie.';

  @override
  String get setupNewSatelliteHelp =>
      'Jeśli to nowe urządzenie, najpierw utwórz nową encję satelity w Home Assistant. „Ustawienia” → „Urządzenia oraz usługi” → „Voice Satellite” → „Dodaj wpis”. WAŻNE: dwa urządzenia nie mogą współdzielić tej samej encji.';

  @override
  String get setupApplyRecommended => 'Zastosuj wszystkie zalecane ustawienia';

  @override
  String get setupRecommendedHelp =>
      'Optymalne ustawienia zapewniające pełną integrację i funkcjonalność Voice Satellite.';

  @override
  String get setupVoiceRequired => 'Wymagane przez Voice Satellite';

  @override
  String get setupMicrophoneAccess => 'Dostęp do mikrofonu';

  @override
  String get setupNativeWakeWord => 'Natywne wykrywanie słowa wybudzającego';

  @override
  String get setupPullRefresh => 'Przeciągnij, aby odświeżyć';

  @override
  String get setupAutoplay => 'Automatyczne odtwarzanie dźwięku i wideo';

  @override
  String get setupVoiceSkipped => 'Nie zainstalowano, pominięto';

  @override
  String get setupVoiceLead =>
      'Zmień ten kiosk w asystenta głosowego dla Home Assistant. Wszystko można później zmienić.';

  @override
  String get setupVoiceAddAgainHint =>
      'Po zakończeniu konfiguracji dodaj ten kiosk w Home Assistant w sekcji „Ustawienia”, „Urządzenia oraz usługi”, gdzie będzie widoczny w sekcji „Wykryte”. Jeśli Home Assistant znał go wcześniej, poprosi tam o nowy klucz szyfrowania („Encryption key”) ze strony ESPHome.';

  @override
  String get setupRecommendedWall =>
      'Ustawienia odpowiednie dla kiosku zawieszonego na ścianie.';

  @override
  String get setupVoiceFound => 'Znaleziono integrację Voice Satellite';

  @override
  String get setupVoiceFoundHelp =>
      'Voice Satellite działa teraz w Kiosk Satellite. Przeprowadź migrację, aby zachować słowa wybudzające, asystenta i wygląd jednego z satelitów integracji zamiast zaczynać od zera.';

  @override
  String get setupVoiceMigrated => 'Przeniesiono z integracji Voice Satellite';

  @override
  String get setupVoiceMigratedHelp =>
      'Ten kiosk przejmuje ustawienia satelity z integracji.';

  @override
  String get setupVoicePipelineHelp =>
      'Kanał przetwarzania mowy Assist, który odpowiada na słowo wybudzające.';

  @override
  String get setupVoiceEngineHelp =>
      'Silnik, który nasłuchuje słowa wybudzającego.';

  @override
  String get setupRemoteHeading => 'Zdalna administracja';

  @override
  String get setupTitle => 'Skonfiguruj\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      'Zamień ten tablet w kiosk Home Assistant. Konfiguracja zajmuje kilka minut i przebiega krok po kroku w tym kreatorze.';

  @override
  String get setupDeviceName => 'Nazwa urządzenia';

  @override
  String get setupDeviceNameHelp =>
      'Nazwa tego kiosku w Home Assistant, w zdalnej administracji i w sieci. Zmień ją w dowolnej chwili w sekcji Ustawienia, Urządzenie.';

  @override
  String get setupEnableRemote => 'Włącz zdalną administrację';

  @override
  String get setupEnableRemoteHelp =>
      'Zarządzaj tym kioskiem z przeglądarki internetowej także po konfiguracji. Tam znacznie łatwiej wkleić token dostępu Home Assistant.';

  @override
  String get setupRemotePassword => 'Hasło zdalnej administracji';

  @override
  String get setupRestoreHeading => 'Przywracanie kopii zapasowej';

  @override
  String get setupRestore => 'Przywróć z pliku konfiguracji';

  @override
  String get setupRestoreHelp =>
      'Zaimportuj konfigurację wyeksportowaną z Kiosk Satellite i pomiń resztę kreatora. Przenoszone są ustawienia, pulpit i dane logowania.';

  @override
  String get setupServicePermissions => 'Zalecane uprawnienia usług';

  @override
  String get setupPasswordShort => 'Za krótkie hasło';

  @override
  String get setupPasswordMinimum => 'Hasło musi mieć co najmniej 4 znaki.';

  @override
  String setupRemoteAddress(String address) {
    return 'Tę konfigurację można kontynuować zdalnie w przeglądarce pod adresem $address, niezależnie od tego, czy powyższy przełącznik jest włączony.';
  }

  @override
  String get remoteWelcomeTitle => 'Witamy w Kiosk Satellite';

  @override
  String get remoteWelcomePassword =>
      'Ten tablet czeka na konfigurację. Najpierw zabezpiecz zdalną administrację hasłem.';

  @override
  String get remoteWelcomeReady =>
      'Ten tablet czeka na konfigurację. Hasło zdalnej administracji jest już ustawione; wpisz tutaj nowe, aby je zmienić.';

  @override
  String get remoteInitialPassword => 'Hasło administratora (min. 4 znaki)';

  @override
  String get remoteNewPassword =>
      'Nowe hasło administratora (pozostaw puste, aby zachować obecne)';

  @override
  String get intercomBuiltinRing => 'Wbudowany krótki dzwonek';

  @override
  String get intercomBuiltinChime => 'Wbudowany dzwonek';

  @override
  String intercomMissingFile(String file) {
    return '$file (brak pliku)';
  }

  @override
  String get intercomAddSound => 'Dodaj dźwięk';

  @override
  String get intercomCopySoundHelp =>
      'Skopiuj plik dźwiękowy z tego urządzenia do folderu z dźwiękami.';

  @override
  String get intercomUploadSoundHelp =>
      'Prześlij plik dźwiękowy z tego komputera do folderu z dźwiękami.';

  @override
  String get intercomUpload => 'Prześlij';

  @override
  String get intercomUploading => 'Przesyłanie…';

  @override
  String get intercomUnsupportedSound => 'Nieobsługiwany plik dźwiękowy';

  @override
  String get intercomChooseSound =>
      'Nieobsługiwany plik dźwiękowy: wybierz plik MP3, OGG, WAV, FLAC, M4A lub AAC.';

  @override
  String get intercomCopyFailed => 'Nie udało się skopiować pliku';

  @override
  String intercomUploadFailed(String error) {
    return 'Przesyłanie nie powiodło się: $error';
  }

  @override
  String intercomSaveFailed(String error) {
    return 'Nie zapisano: $error';
  }

  @override
  String get intercomSoundFilename => 'Wpisz nazwę pliku, a nie ścieżkę.';

  @override
  String get intercomSoundFormats =>
      'Wybierz plik MP3, OGG, WAV, FLAC, M4A lub AAC.';

  @override
  String voiceMatchEnrollTitle(String name) {
    return 'Rejestrowanie głosu: $name';
  }

  @override
  String get voiceMatchEnrollStarting => 'Przygotowywanie…';

  @override
  String get voiceMatchEnrollReading => 'Przeczytaj na głos';

  @override
  String voiceMatchEnrollSeconds(String seconds, String target) {
    return '$seconds z $target s';
  }

  @override
  String get voiceMatchEnrollOtherVoice =>
      'Słychać inny głos. Ten fragment jest pomijany.';

  @override
  String get voiceMatchEnrollSaving => 'Zapisywanie…';

  @override
  String get voiceMatchEnrollStop => 'Zatrzymaj';

  @override
  String get voiceMatchEnrollTipWalk => 'Chodź powoli po pokoju';

  @override
  String get voiceMatchEnrollTipTurn =>
      'Od czasu do czasu odwróć się od kiosku';

  @override
  String get voiceMatchEnrollTipTalk => 'Mów tak, jak wydajesz polecenia';

  @override
  String voiceMatchEnrollDone(String name) {
    return 'Zarejestrowano głos: $name';
  }

  @override
  String voiceMatchEnrollDoneDetail(String seconds) {
    return 'Dodano mowę: $seconds s.';
  }

  @override
  String get voiceMatchEnrollFailed => 'Nic nie zapisano';

  @override
  String get voiceMatchEnrollTooShort =>
      'Za krótka próbka mowy do zapisania. Czytaj przez co najmniej 10 sekund.';

  @override
  String get voiceMatchEnrollLost => 'Utracono połączenie z Voice Match.';

  @override
  String get voiceMatchEnrollNoMic => 'Mikrofon jest niedostępny.';

  @override
  String get voiceMatchEnrollStopped =>
      'Zatrzymano przed nagraniem czegokolwiek.';

  @override
  String get voiceMatchEnrollPassage1 => 'Włącz światło w kuchni.';

  @override
  String get voiceMatchEnrollPassage2 => 'Ustaw minutnik na dziesięć minut.';

  @override
  String get voiceMatchEnrollPassage3 => 'Jaka będzie jutro pogoda?';

  @override
  String get voiceMatchEnrollPassage4 =>
      'Dodaj mleko i jajka do listy zakupów.';

  @override
  String get voiceMatchEnrollPassage5 => 'Włącz cichą muzykę w salonie.';

  @override
  String get voiceMatchEnrollPassage6 =>
      'Rano było zimno, więc zostaliśmy w domu i usmażyliśmy naleśniki.';

  @override
  String get voiceMatchEnrollPassage7 =>
      'Później poszliśmy do parku i patrzyliśmy, jak psy gonią się na trawie.';

  @override
  String get voiceMatchEnrollPassage8 =>
      'Wieczorem zerwał się wiatr i rozpaliliśmy w kominku.';

  @override
  String get voiceMatchEnrollPassage9 => 'Wyłącz wszystkie światła na dole.';

  @override
  String get voiceMatchEnrollPassage10 => 'Która jest godzina w Tokio?';

  @override
  String get voiceMatchEnrollPassage11 =>
      'Przypomnij mi o telefonie do dentysty w poniedziałek.';

  @override
  String get voiceMatchEnrollPassage12 =>
      'Ile zajmie dojazd samochodem na lotnisko?';

  @override
  String get voiceMatchEnrollPassage13 => 'Wstrzymaj muzykę.';

  @override
  String get voiceMatchEnrollPassage14 => 'Dobranoc.';

  @override
  String get voiceNoticeError => 'Błąd Voice Satellite';

  @override
  String get voiceNoticeWarning => 'Ostrzeżenie Voice Satellite';

  @override
  String get voiceNoticeNotice => 'Komunikat Voice Satellite';

  @override
  String get voiceNoticeTts => 'Zamiana tekstu na mowę';

  @override
  String get voiceNoticeAssistPipeline => 'Kanał przetwarzania mowy Assist';

  @override
  String voiceNoticePipeline(String name) {
    return 'Kanał przetwarzania mowy „$name”';
  }

  @override
  String get voiceNoticeMicUnavailable => 'Mikrofon jest niedostępny.';

  @override
  String get voiceNoticeNotConnected =>
      'Home Assistant nie jest połączony z tym kioskiem.';

  @override
  String get voiceNoticeConnectionLost =>
      'Utracono połączenie z Home Assistant. Trwa ponowne łączenie.';

  @override
  String get voiceNoticePlayback =>
      'Nie udało się odtworzyć dźwięku na urządzeniu.';

  @override
  String get voiceNoticeWatchdog =>
      'Brak odpowiedzi z Home Assistant po zakończeniu mówienia. Kanał przetwarzania mowy mógł się zawiesić.';

  @override
  String get voiceNoticeRefused =>
      'Home Assistant nie mógł uruchomić asystenta.';

  @override
  String get voiceNoticeUnexpected =>
      'Wystąpił nieoczekiwany błąd kanału przetwarzania mowy.';

  @override
  String get voiceNoticeMicBlocked =>
      'Dostęp do mikrofonu jest zablokowany. Zezwól na niego dla Kiosk Satellite w ustawieniach systemu Android.';

  @override
  String get voiceNoticeMicDeclined =>
      'Odmówiono dostępu do mikrofonu, więc słowo wybudzające nie może zostać wykryte.';

  @override
  String get voiceNoticeMicLost => 'Mikrofon przestał działać.';

  @override
  String get voiceNoticeModels =>
      'Nie udało się wczytać modeli słów wybudzających.';

  @override
  String get voiceNoticeCrashed =>
      'Detektor słowa wybudzającego wielokrotnie ulegał awarii na tym urządzeniu, dlatego został zatrzymany.';

  @override
  String voiceFinancialOpen(String value) {
    return 'Otwarcie: $value';
  }

  @override
  String voiceFinancialHigh(String value) {
    return 'Maksimum: $value';
  }

  @override
  String voiceFinancialLow(String value) {
    return 'Minimum: $value';
  }

  @override
  String voiceFinancialHigh24h(String value) {
    return 'Maksimum z ostatnich 24 h: $value';
  }

  @override
  String voiceFinancialLow24h(String value) {
    return 'Minimum z ostatnich 24 h: $value';
  }

  @override
  String voiceFinancialMarketCap(String value) {
    return 'Kapitalizacja: $value';
  }

  @override
  String get voiceTimerDefaultName => 'Minutnik';

  @override
  String get voiceTimerDrag => 'Przeciągnij, aby przenieść minutniki';

  @override
  String get voiceTimerPauseHint =>
      'Dotknij, aby wstrzymać. Dotknij dwukrotnie, aby anulować. Przeciągnij, aby przenieść.';

  @override
  String get voiceTimerResumeHint =>
      'Dotknij, aby wznowić. Dotknij dwukrotnie, aby anulować. Przeciągnij, aby przenieść.';

  @override
  String get voiceTimerCancel => 'Anuluj minutnik';

  @override
  String get voiceTimerActionError =>
      'Nie udało się zmienić minutnika. Sprawdź połączenie i w razie potrzeby zaktualizuj Voice Satellite.';

  @override
  String get voiceTimerFinished => 'Minutnik zakończony';

  @override
  String get voiceTimerDismissHint => 'Dotknij, aby wyłączyć sygnał minutnika.';

  @override
  String get voiceTimersViewTitle => 'Minutniki';

  @override
  String get voiceTimersEmpty => 'Brak minutników';

  @override
  String get voiceTimerPause => 'Wstrzymaj';

  @override
  String get voiceTimerResume => 'Wznów';

  @override
  String get voiceTimerDismiss => 'Wyłącz';

  @override
  String get voiceTimerTimesUp => 'Czas minął';

  @override
  String get voiceTimerPaused => 'Wstrzymany';

  @override
  String get voiceTimersShareNone => 'Nie wybrano kiosków';

  @override
  String get voiceTimersShareEmpty =>
      'Nie znaleziono innych kiosków. Włącz zdalną administrację i opcję „Znajdź inne kioski” w każdym z nich.';

  @override
  String get voiceTimersShareOffline => 'Offline';

  @override
  String get timersVoiceSection => 'Minutniki głosowe';

  @override
  String get timersVoiceManage =>
      'Zarządzaj minutnikami za pomocą Voice Satellite';

  @override
  String get timersVoiceHint =>
      'Działa bez blueprintu i bez agenta konwersacji LLM.';

  @override
  String get voiceTimersShareSearch => 'Szukaj kiosków';

  @override
  String get voiceTimerSetATimer => 'Ustaw minutnik';

  @override
  String get voiceTimerEditTimer => 'Edytuj minutnik';

  @override
  String get voiceTimerName => 'Nazwa';

  @override
  String get voiceTimerHours => 'Godziny';

  @override
  String get voiceTimerMinutes => 'Minuty';

  @override
  String get voiceTimerSeconds => 'Sekundy';

  @override
  String get voiceTimerStartFailed => 'Nie udało się uruchomić minutnika.';

  @override
  String get timersManage => 'Zarządzaj minutnikami';

  @override
  String get voiceTimerStartUnavailable =>
      'Włącz Voice Satellite w tym kiosku, aby ustawiać tu minutniki.';
}
