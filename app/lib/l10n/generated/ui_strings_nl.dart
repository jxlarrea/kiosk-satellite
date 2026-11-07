// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class UiStringsNl extends UiStrings {
  UiStringsNl([String locale = 'nl']) : super(locale);

  @override
  String get aboutApp => 'App';

  @override
  String get aboutVersion => 'Appversie';

  @override
  String get aboutBuild => 'Build';

  @override
  String get aboutPackage => 'Pakket-ID';

  @override
  String get aboutAttribution => 'Naamsvermelding';

  @override
  String get aboutAuthor => 'Auteur';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutSourceCode => 'Broncode';

  @override
  String get aboutLicense => 'Licentie';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite is gratis voor persoonlijk, niet-commercieel gebruik. De app valt onder de licentie CC BY-NC-ND 4.0: je mag de app gebruiken en delen, maar commercieel gebruik en de verspreiding van aangepaste builds zijn niet toegestaan. Voor onafhankelijke plug-ins geldt aanvullende toestemming volgens PLUGIN-EXCEPTION.md.';

  @override
  String get aboutLocalizationCredits => 'Vertalers';

  @override
  String get aboutLocalizationCreditsHint => 'Bijdragers per taal';

  @override
  String get aboutCheckNow => 'Controleer nu op updates';

  @override
  String get aboutChecking => 'Controleren…';

  @override
  String get aboutCheckFailed =>
      'Updatecontrole mislukt. Kan het apparaat GitHub bereiken?';

  @override
  String get aboutOverlayMissing =>
      'Toestemming voor weergave over andere apps ontbreekt';

  @override
  String get aboutOverlayHelp =>
      'Zonder deze toestemming kan de app zichzelf na een update niet opnieuw openen. Het toestemmingsscherm verschijnt op de tablet.';

  @override
  String aboutDownloadProgress(String percent) {
    return 'Downloaden… $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return 'Update mislukt: $error';
  }

  @override
  String get aboutAlreadyCurrent => 'De app is al bijgewerkt';

  @override
  String get aboutInstallHelp =>
      'De download draait op de tablet; de installatie moet op het tabletscherm worden bevestigd.';

  @override
  String get aboutSystem => 'Systeem';

  @override
  String get aboutSystemVersion => 'ROM-versie';

  @override
  String get aboutSystemVerifying => 'Verifiëren…';

  @override
  String get aboutSystemInstalling => 'Installeren…';

  @override
  String get aboutSystemRestartHelp =>
      'Het apparaat start twee keer opnieuw op om de update te installeren en is een paar minuten offline.';

  @override
  String get aboutSystemManual => 'Nieuwe image beschikbaar';

  @override
  String aboutSystemManualHelp(String version) {
    return 'Versie $version van de nieuwe Echo Dot-image installeer je met de hand, niet als update.';
  }

  @override
  String get alarmsTitle => 'Alarmen';

  @override
  String get alarmsSetAnAlarm => 'Een alarm instellen';

  @override
  String get alarmsNone => 'Geen alarmen';

  @override
  String get alarmsDone => 'Klaar';

  @override
  String get alarmsRepeat => 'Herhalen';

  @override
  String get alarmsLabel => 'Label';

  @override
  String get alarmsAddLabel => 'Label toevoegen';

  @override
  String get alarmsTone => 'Alarmtoon';

  @override
  String get alarmsSunrise => 'Zonsopgang';

  @override
  String get alarmsDefaultTone => 'Standaard';

  @override
  String get alarmsBuiltInTone => 'Ingebouwd alarm';

  @override
  String get alarmsSoundsFolder => 'Geluidenmap';

  @override
  String get alarmsToday => 'Vandaag';

  @override
  String get alarmsTomorrow => 'Morgen';

  @override
  String get alarmsOnce => 'Eenmalig';

  @override
  String get alarmsEveryDay => 'Elke dag';

  @override
  String get alarmsWeekdays => 'Weekdagen';

  @override
  String get alarmsWeekends => 'Weekenden';

  @override
  String alarmsSnoozedUntil(String time) {
    return 'Uitgesteld tot $time';
  }

  @override
  String get alarmsSnooze => 'Sluimeren';

  @override
  String get alarmsStop => 'Stoppen';

  @override
  String get alarmsDefaultLabel => 'Alarm';

  @override
  String get alarmsSetToast => 'Alarm ingesteld';

  @override
  String alarmsRingsIn(String duration) {
    return 'Gaat over $duration';
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
    return 'Alarm om $time';
  }

  @override
  String get alarmsNextWidget => 'Volgend alarm';

  @override
  String get alarmsManage => 'Alarmen beheren';

  @override
  String alarmsNextAt(String day, String time) {
    return 'Volgende: $day om $time';
  }

  @override
  String get alarmsNoneSet => 'Geen alarmen ingesteld';

  @override
  String get alarmsDefaultsSection => 'Standaardinstellingen';

  @override
  String get alarmsTtsSection => 'Tekst-naar-spraak';

  @override
  String get alarmsEditAlarm => 'Alarm bewerken';

  @override
  String get alarmsTime => 'Tijd';

  @override
  String get alarmsRinging => 'Alarm gaat af';

  @override
  String get alarmsSnoozed => 'Alarm uitgesteld';

  @override
  String get alarmsSunriseRunning => 'Zonsopgang voor een alarm';

  @override
  String alarmsSunriseHint(String minutes) {
    return 'Het scherm wordt gedurende $minutes minuten steeds helderder voordat het alarm afgaat.';
  }

  @override
  String get alarmsDeleteFailed => 'Kon het alarm niet verwijderen.';

  @override
  String alarmsDuplicate(String time) {
    return 'Er is al een alarm ingesteld om $time';
  }

  @override
  String get alarmsEaseIn => 'Volume geleidelijk verhogen';

  @override
  String alarmsEaseHint(String seconds) {
    return 'Verhoogt het volume in $seconds seconden tot het ingestelde alarmvolume.';
  }

  @override
  String get alarmsSpeak => 'Uitspreken wanneer het alarm afgaat';

  @override
  String get alarmsPhrase => 'Tekst';

  @override
  String alarmsPhraseVariables(String variables) {
    return 'Beschikbare variabelen: $variables';
  }

  @override
  String get alarmsVoiceSection => 'Spraakalarmen';

  @override
  String get alarmsVoiceManage => 'Alarmen beheren met Voice Satellite';

  @override
  String get alarmsVoiceHint =>
      'Vereist de alarmblauwdruk van Kiosk Satellite en een LLM-gespreksagent in Home Assistant.';

  @override
  String get alarmsMusic => 'Muziek';

  @override
  String get alarmsMusicNone => 'Geen';

  @override
  String get alarmsMusicRemove => 'Muziek verwijderen';

  @override
  String get alarmsMusicHint =>
      'Speelt in plaats van de toon. Als de muziek niet kan spelen, klinkt de toon.';

  @override
  String get androidAccessibilityHelp =>
      'Sluit het meldingenpaneel en het scherm met recente apps zodra deze worden geopend terwijl de kioskmodus of vergrendelingsmodus het scherm beschermt. Kiosk Satellite leest geen inhoud van het scherm.';

  @override
  String get androidServiceChannelHelp =>
      'Wordt getoond wanneer de Kiosk Satellite Service de app actief houdt terwijl het scherm uitstaat of een andere app op de voorgrond staat.';

  @override
  String get androidServiceListening => 'luisteren naar een wekwoord';

  @override
  String get androidServiceRtspAudio => 'RTSP-microfoonaudio ingeschakeld';

  @override
  String get androidServiceEsphome => 'ESPHome beschikbaar stellen';

  @override
  String get androidServiceBluetooth => 'Bluetooth-apparaten doorgeven';

  @override
  String get androidServiceCamera => 'camera bewaken';

  @override
  String get androidServiceLocation => 'locatie doorgeven';

  @override
  String get androidServiceRemote => 'beheer op afstand beschikbaar stellen';

  @override
  String get androidServiceKiosk => 'kioskmodus bewaken';

  @override
  String get androidServiceSessions => 'Home Assistant verbonden houden';

  @override
  String get launcherErrorAndroidOnly =>
      'apps weergeven wordt alleen op Android ondersteund';

  @override
  String launcherErrorListDetail(String error) {
    return 'kon apps niet ophalen: $error';
  }

  @override
  String launcherOpenFailed(String name) {
    return 'Kon $name niet openen';
  }

  @override
  String get launcherUninstalled => 'De app is mogelijk verwijderd.';

  @override
  String get launcherNoneHelp =>
      'Nog geen apps geselecteerd. Kies welke apps de appstarter moet aanbieden.';

  @override
  String get launcherNone => 'Nog geen apps';

  @override
  String get launcherListFailed => 'Kon de apps niet ophalen';

  @override
  String launcherListError(String error) {
    return 'Kon de apps niet ophalen: $error';
  }

  @override
  String get launcherListingFailed => 'ophalen mislukt';

  @override
  String get launcherEmpty => 'Geen apps gevonden die kunnen worden gestart.';

  @override
  String get launcherSearchApps => 'Apps zoeken';

  @override
  String get calendarTitle => 'Agenda';

  @override
  String get calendarViewDay => 'Dag';

  @override
  String get calendarViewWeek => 'Week';

  @override
  String get calendarViewMonth => 'Maand';

  @override
  String get calendarViewSchedule => 'Overzicht';

  @override
  String get calendarToday => 'Vandaag';

  @override
  String get calendarTomorrow => 'Morgen';

  @override
  String get calendarPrevious => 'Vorige';

  @override
  String get calendarNext => 'Volgende';

  @override
  String get calendarAllDay => 'Hele dag';

  @override
  String calendarMore(String count) {
    return '+$count meer';
  }

  @override
  String get calendarUpNext => 'Hierna';

  @override
  String calendarStartsIn(String duration) {
    return 'over $duration';
  }

  @override
  String get calendarHappeningNow => 'Nu';

  @override
  String get calendarLaterToday => 'Later vandaag';

  @override
  String get calendarNothingElseToday => 'Verder niets vandaag';

  @override
  String get calendarNothingPlanned => 'Niets gepland';

  @override
  String get calendarNothingThisWeek => 'Niets gepland deze week';

  @override
  String get calendarEmptyTitle => 'Nog geen agenda\'s';

  @override
  String get calendarEmptyHint =>
      'Voeg in Instellingen > Agenda de Home Assistant-agenda\'s toe die je wilt tonen.';

  @override
  String calendarOffline(String time) {
    return 'Home Assistant is niet bereikbaar. Dit zijn de afspraken van $time.';
  }

  @override
  String calendarTimeRange(String start, String end) {
    return '$start tot $end';
  }

  @override
  String calendarPeopleTwo(String first, String second) {
    return '$first en $second';
  }

  @override
  String get calendarRepeatsDaily => 'Elke dag';

  @override
  String get calendarRepeatsWeekly => 'Elke week';

  @override
  String get calendarRepeatsMonthly => 'Elke maand';

  @override
  String get calendarRepeatsYearly => 'Elk jaar';

  @override
  String get calendarRepeats => 'Herhaalt';

  @override
  String get calendarDone => 'Klaar';

  @override
  String get calendarCalendarsSection => 'Agenda\'s';

  @override
  String get calendarAdd => 'Agenda toevoegen';

  @override
  String get calendarAlreadyAdded => 'Die agenda staat al in de lijst.';

  @override
  String get calendarOpen => 'Agenda openen';

  @override
  String get calendarOpenHint => 'Toon de agenda op deze kiosk.';

  @override
  String get calendarEditName => 'Naam';

  @override
  String get calendarEditColor => 'Kleur';

  @override
  String get calendarEditPerson => 'Persoon';

  @override
  String get calendarEditPersonHint => 'Toont hun foto op de agendalabels.';

  @override
  String get calendarEditPersonNone => 'Geen';

  @override
  String get calendarPickCalendar => 'Kies een agenda';

  @override
  String get calendarPickPerson => 'Kies een persoon';

  @override
  String get calendarColorTeal => 'Petrol';

  @override
  String get calendarColorRust => 'Roest';

  @override
  String get calendarColorBlue => 'Blauw';

  @override
  String get calendarColorPlum => 'Pruim';

  @override
  String get calendarColorOchre => 'Oker';

  @override
  String get calendarColorSage => 'Salie';

  @override
  String get calendarColorRose => 'Roze';

  @override
  String get calendarColorSlate => 'Leisteen';

  @override
  String get calendarColorCustom => 'Aangepast';

  @override
  String get calendarWidgetEvents => 'Getoonde afspraken';

  @override
  String get calendarWidgetDays => 'Getoonde dagen';

  @override
  String get calendarWidgetTomorrow => 'Vandaag en morgen';

  @override
  String get calendarWidgetWeek => 'Komende 7 dagen';

  @override
  String get calendarWidgetAllDay => 'Afspraken voor de hele dag tonen';

  @override
  String get calendarWidgetDots => 'Gekleurde stippen';

  @override
  String get calendarWidgetDotsHint =>
      'Markeer afspraken met de kleur van hun agenda in plaats van de foto van de persoon.';

  @override
  String get calendarVoiceSection => 'Agenda via spraak';

  @override
  String get calendarVoiceManage => 'Agenda beheren met Voice Satellite';

  @override
  String get calendarVoiceHint =>
      'Vereist de agendablauwdruk van Kiosk Satellite en een LLM-gespreksagent in Home Assistant.';

  @override
  String get calendarNewEvent => 'Nieuwe afspraak';

  @override
  String get calendarEditEvent => 'Afspraak bewerken';

  @override
  String get calendarFieldTitle => 'Titel';

  @override
  String get calendarFieldTitleHint => 'Titel toevoegen';

  @override
  String get calendarFieldCalendars => 'Agenda\'s';

  @override
  String get calendarFieldSharedHint =>
      'Wordt één keer getoond, verdeeld over hun kleuren.';

  @override
  String get calendarFieldStarts => 'Begint';

  @override
  String get calendarFieldEnds => 'Eindigt';

  @override
  String get calendarFieldStartTime => 'Begintijd';

  @override
  String get calendarFieldEndTime => 'Eindtijd';

  @override
  String get calendarFieldEndsBeforeStart => 'Eindigt voordat het begint.';

  @override
  String get calendarFieldRepeat => 'Herhalen';

  @override
  String get calendarRepeatNever => 'Herhaalt niet';

  @override
  String get calendarRepeatWeekdays => 'Elke werkdag';

  @override
  String calendarRepeatWeeklyOn(String weekday) {
    return 'Elke week op $weekday';
  }

  @override
  String calendarRepeatMonthlyOn(String day) {
    return 'Elke maand op dag $day';
  }

  @override
  String calendarRepeatYearlyOn(String date) {
    return 'Elk jaar op $date';
  }

  @override
  String get calendarFieldLocation => 'Locatie';

  @override
  String get calendarFieldLocationHint => 'Plaats toevoegen';

  @override
  String get calendarFieldNotes => 'Notities';

  @override
  String get calendarFieldNotesHint => 'Notities toevoegen';

  @override
  String get calendarEventAdded => 'Afspraak toegevoegd';

  @override
  String get calendarEventSaved => 'Wijzigingen opgeslagen';

  @override
  String get calendarEventDeleted => 'Afspraak verwijderd';

  @override
  String get calendarSaveFailed => 'Kan de afspraak niet opslaan';

  @override
  String get calendarDeleteFailed => 'Kan de afspraak niet verwijderen';

  @override
  String calendarEditReadOnly(String calendar) {
    return '$calendar is alleen-lezen.';
  }

  @override
  String calendarEditGone(String calendar) {
    return 'De afspraak staat niet meer in $calendar.';
  }

  @override
  String calendarEditNotAllowed(String calendar) {
    return 'De Home Assistant-gebruiker van de kiosk mag $calendar niet wijzigen.';
  }

  @override
  String calendarDeleteTitle(String title) {
    return '$title verwijderen?';
  }

  @override
  String calendarDeleteShared(String names) {
    return 'Hij verdwijnt uit elke agenda waarin hij staat: $names.';
  }

  @override
  String calendarSaveRepeatTitle(String title) {
    return 'Wijzigingen in $title opslaan?';
  }

  @override
  String get calendarSaveRepeatFollowing =>
      'De nieuwe herhaling begint op deze dag.';

  @override
  String get calendarScopeThis => 'Deze afspraak';

  @override
  String get calendarScopeFollowing => 'Deze en volgende afspraken';

  @override
  String get calendarScopeAll => 'Alle afspraken';

  @override
  String get calendarEditingSection => 'Bewerken';

  @override
  String get cameraViewerTitle => 'Cameraweergave';

  @override
  String get cameraViewerConnecting => 'Verbinden...';

  @override
  String get cameraViewerReconnecting => 'Opnieuw verbinden...';

  @override
  String cameraViewerTrying(String transport) {
    return '$transport wordt geprobeerd...';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return 'Dit apparaat kan $codec niet decoderen';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return 'Dit apparaat kan geen $transport-streams afspelen';
  }

  @override
  String get cameraViewerCannotDecodeStream =>
      'Dit apparaat kan deze stream niet decoderen';

  @override
  String cameraViewerHaRetry(String seconds) {
    return 'Kan Home Assistant niet bereiken. Opnieuw proberen in ${seconds}s';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return 'Kan de cameraserver niet bereiken. Opnieuw proberen in ${seconds}s';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return 'Verbinding mislukt. Opnieuw proberen in ${seconds}s';
  }

  @override
  String get cameraViewerStartRetry =>
      'De cameraserver kon deze stream niet starten. Opnieuw proberen...';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return 'De cameraserver kon deze stream niet starten. Opnieuw proberen in ${seconds}s';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return 'Stream niet gevonden op de cameraserver. Opnieuw proberen in ${seconds}s';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return 'De cameraserver heeft de login geweigerd. Opnieuw proberen in ${seconds}s';
  }

  @override
  String get cameraViewerMissing => 'Stream ontbreekt in Go2RTC';

  @override
  String get commonImport => 'Importeren';

  @override
  String get commonBack => 'Terug';

  @override
  String get commonNext => 'Volgende';

  @override
  String get commonFinish => 'Voltooien';

  @override
  String get commonWorking => 'Bezig…';

  @override
  String get commonSettings => 'Instellingen';

  @override
  String get commonCancel => 'Annuleren';

  @override
  String get commonOk => 'OK';

  @override
  String get commonGrant => 'Toestaan';

  @override
  String get commonEnable => 'Inschakelen';

  @override
  String get commonRefresh => 'Vernieuwen';

  @override
  String get commonTest => 'Testen';

  @override
  String get commonInstall => 'Installeren';

  @override
  String get commonSave => 'Opslaan';

  @override
  String get commonRetry => 'Opnieuw proberen';

  @override
  String get commonCopy => 'Kopiëren';

  @override
  String get commonAdd => 'Toevoegen';

  @override
  String get commonRemove => 'Verwijderen';

  @override
  String get commonClose => 'Sluiten';

  @override
  String get commonClear => 'Wissen';

  @override
  String get commonBrowse => 'Bladeren';

  @override
  String get commonSet => 'Instellen';

  @override
  String get commonHour => 'Uur';

  @override
  String get commonMinute => 'Minuut';

  @override
  String get commonUp => 'Omhoog';

  @override
  String get commonDown => 'Omlaag';

  @override
  String get commonDelete => 'Verwijderen';

  @override
  String get commonSaveFailed => 'Kon niet opslaan';

  @override
  String get commonColorWhite => 'Wit';

  @override
  String get commonColorWarm => 'Warm';

  @override
  String get commonColorAmber => 'Amber';

  @override
  String get commonColorRed => 'Rood';

  @override
  String get commonColorGreen => 'Groen';

  @override
  String get commonColorBlue => 'Blauw';

  @override
  String get commonColorCyan => 'Cyaan';

  @override
  String get commonColorDim => 'Gedimd';

  @override
  String get commonEdit => 'Bewerken';

  @override
  String get commonMoveUp => 'Omhoog verplaatsen';

  @override
  String get commonMoveDown => 'Omlaag verplaatsen';

  @override
  String get commonPreviousMonth => 'Vorige maand';

  @override
  String get commonNextMonth => 'Volgende maand';

  @override
  String get commonLoading => 'Laden…';

  @override
  String get commonChoose => 'Kiezen';

  @override
  String get dlnaPortInvalid =>
      'Voer een poort tussen 1024 en 65535 in of laat het veld leeg';

  @override
  String get commonSelectAll => 'Alles selecteren';

  @override
  String get dashboardPickerSearch => 'Weergaven zoeken';

  @override
  String get dashboardPickerSearchAll => 'Dashboards en weergaven zoeken';

  @override
  String get dashboardPickerCurrent => 'Huidig';

  @override
  String get dashboardPickerDashboards => 'Dashboards';

  @override
  String get dashboardPickerSubviews => 'Subweergaven';

  @override
  String get dashboardPickerSubview => 'Subweergave';

  @override
  String get dashboardPickerWhole => 'Volledig dashboard';

  @override
  String get dashboardPickerBuildsOwn => 'Maakt eigen weergaven';

  @override
  String get dashboardPickerIngressPage => 'Ingress-pagina';

  @override
  String get dashboardPickerBuiltInPage => 'Home Assistant-pagina';

  @override
  String get dashboardPickerWholeHelp =>
      'Dit dashboard maakt zijn eigen weergaven, dus de kiosk opent het in zijn geheel.';

  @override
  String dashboardPickerViewCount(String count) {
    return '$count weergaven';
  }

  @override
  String get dashboardPickerOneView => '1 weergave';

  @override
  String get dashboardPickerOffline => 'Kan Home Assistant niet bereiken';

  @override
  String get dashboardPickerOfflineHelp =>
      'De dashboards laden zodra de verbinding terug is.';

  @override
  String get dashboardPickerTryAgain => 'Probeer opnieuw';

  @override
  String get dashboardPickerEmpty => 'Nog geen dashboards';

  @override
  String get dashboardPickerEmptyHelp =>
      'Dashboards die je in Home Assistant toevoegt, verschijnen hier.';

  @override
  String get dashboardPickerNoMatch => 'Geen weergaven gevonden';

  @override
  String dashboardPickerSelected(String count) {
    return '$count geselecteerd';
  }

  @override
  String get dashboardPickerDone => 'Klaar';

  @override
  String get dashboardPickerShowing => 'Wordt getoond';

  @override
  String get dashboardPickerMissing =>
      'Deze weergave bestaat niet meer in Home Assistant. Kies een andere.';

  @override
  String get dashboardPickerAddViews => 'Weergaven toevoegen';

  @override
  String get dashboardPickerDefault => 'Standaarddashboard';

  @override
  String get dashboardPickerDefaultHelp =>
      'De weergave die de kiosk toont bij het starten.';

  @override
  String get dashboardPickerOnePage => '1 pagina';

  @override
  String dashboardPickerPageCount(String count) {
    return '$count pagina\'s';
  }

  @override
  String get dlnaCannotDecode => 'Dit apparaat kan deze video niet decoderen.';

  @override
  String get dlnaCannotRead => 'Dit bestand kon niet worden gelezen.';

  @override
  String get dlnaCannotPlay => 'Dit mediabestand kon niet worden afgespeeld.';

  @override
  String get dlnaSeeLogs => 'Bekijk de app-logboeken voor meer informatie';

  @override
  String get dlnaLoading => 'Media laden';

  @override
  String get dlnaImageFailed => 'Deze afbeelding kon niet worden weergegeven.';

  @override
  String get dlnaStop => 'Afspelen stoppen';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName: $actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => 'Plug-inactie';

  @override
  String get drawerPluginActionError => 'Kon deze actie niet uitvoeren.';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerHaKiosk => 'HA Kioskmodus';

  @override
  String get drawerCameraView => 'Cameraweergave';

  @override
  String get drawerIntercom => 'Intercom';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => 'Zwevende speler verbergen';

  @override
  String get drawerShowPlayer => 'Zwevende speler tonen';

  @override
  String get drawerNowPlaying => 'Speelt nu';

  @override
  String get drawerScreensaver => 'Schermbeveiliging starten';

  @override
  String get drawerLockdown => 'Vergrendelingsmodus';

  @override
  String get drawerHoldOff => 'Wachtstand uitschakelen';

  @override
  String get drawerHoldOn => 'Wachtstand inschakelen';

  @override
  String get drawerApps => 'Apps';

  @override
  String get drawerClearCache => 'Webcache wissen';

  @override
  String get drawerRestartDevice => 'Apparaat herstarten';

  @override
  String get drawerRestartConfirm =>
      'Herstart dit apparaat? Kiosk Satellite komt terug als het opstart.';

  @override
  String get drawerRestart => 'Herstarten';

  @override
  String get drawerExitApplication => 'App afsluiten';

  @override
  String get drawerExitConfirm => 'Kiosk Satellite sluiten?';

  @override
  String get drawerExit => 'Afsluiten';

  @override
  String get drawerHoldActive => 'Wachtstand staat aan';

  @override
  String get drawerHoldHelp =>
      'Schermbeveiliging en timers worden gepauzeerd · tik om uit te schakelen';

  @override
  String get drawerThemeDark => 'Donker';

  @override
  String get drawerThemeLight => 'Licht';

  @override
  String get drawerThemeAndroid => 'Android volgen';

  @override
  String get drawerItemsSearch => 'Menu-items zoeken';

  @override
  String get drawerItemsSettingsKept =>
      'Altijd zichtbaar zolang beheer op afstand uit staat.';

  @override
  String drawerVersion(String version) {
    return 'Versie $version';
  }

  @override
  String get drawerUpdateAvailable => 'Update beschikbaar';

  @override
  String drawerUpdateInstall(String version) {
    return 'Versie $version · tik om te installeren';
  }

  @override
  String get drawerUpdateChecking => 'Controleren op updates…';

  @override
  String get drawerUpdateCurrent => 'Up-to-date';

  @override
  String get drawerUpdateCurrentHelp => 'Je gebruikt de nieuwste versie.';

  @override
  String get drawerUpdateCheckFailed => 'Controle op updates mislukt';

  @override
  String get drawerUpdateOffline => 'Is het apparaat online?';

  @override
  String drawerUpdateTo(String version) {
    return 'Bijwerken naar $version';
  }

  @override
  String get drawerUpdateInstructions =>
      'De download begint wanneer je op Bijwerken tikt. Android vraagt om de installatie te bevestigen.';

  @override
  String get drawerUpdateRelaunch =>
      'Zonder toestemming voor weergave over andere apps kan de app zichzelf na de update niet opnieuw openen.';

  @override
  String get drawerUpdate => 'Bijwerken';

  @override
  String get drawerUpdateDownloading => 'Update wordt gedownload';

  @override
  String get drawerUpdateStarting => 'Starten…';

  @override
  String get drawerUpdateFailed => 'Update mislukt';

  @override
  String get drawerUpdates => 'Updates';

  @override
  String get drawerNoReleaseNotes => 'Geen releaseopmerkingen.';

  @override
  String get entityPickerNoArea => 'Geen ruimte';

  @override
  String get entityPickerAll => 'Alle';

  @override
  String get entityPickerChoose => 'Kies een entiteit';

  @override
  String get entityPickerNoMatch => 'Niets gevonden';

  @override
  String get entityPickerOfflineHelp =>
      'De entiteiten laden zodra de verbinding terug is.';

  @override
  String get entityPickerMissing =>
      'Deze entiteit bestaat niet meer in Home Assistant. Kies een andere.';

  @override
  String get entityPickerOrderHint =>
      'Sleep of gebruik de pijlen om de volgorde te wijzigen.';

  @override
  String get entityPickerFull =>
      'Verwijder er een om een andere toe te voegen.';

  @override
  String get entityPickerAdd => 'Entiteiten toevoegen';

  @override
  String entityPickerShowing(String count, String max) {
    return '$count van $max getoond';
  }

  @override
  String get esphomeAllExposed => 'Alle beschikbare entiteiten worden getoond';

  @override
  String esphomeExcludedCount(String count) {
    return '$count uitgesloten';
  }

  @override
  String get esphomeEntitySearch => 'Entiteiten zoeken';

  @override
  String get esphomeEntityLoading => 'Entiteiten laden…';

  @override
  String get esphomeEntityUnavailable => 'Momenteel niet beschikbaar';

  @override
  String get esphomeEntityNoMatch => 'Geen overeenkomende entiteiten';

  @override
  String get esphomeEntityLoadFailed =>
      'De entiteiten konden niet worden geladen. Sluit de kiezer en probeer het opnieuw.';

  @override
  String get esphomeEntitySaveFailed =>
      'De uitsluitingen konden niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get esphomeTypeConfig => 'Instellingen';

  @override
  String get esphomeTypeDiagnostics => 'Diagnostica';

  @override
  String get esphomeTypeSensorGroup => 'Sensor';

  @override
  String get esphomeTypeControl => 'Bediening';

  @override
  String get esphomeTypeSensor => 'sensor';

  @override
  String get esphomeTypeTextSensor => 'tekstsensor';

  @override
  String get esphomeTypeBinarySensor => 'binaire sensor';

  @override
  String get esphomeTypeCamera => 'camera';

  @override
  String get esphomeTypeSwitch => 'schakelaar';

  @override
  String get esphomeTypeButton => 'knop';

  @override
  String get esphomeTypeNumber => 'getal';

  @override
  String get esphomeTypeSelect => 'keuzelijst';

  @override
  String get esphomeTypeLight => 'licht';

  @override
  String get esphomeTypeUpdate => 'update';

  @override
  String get esphomeTypeText => 'tekst';

  @override
  String get filesUpload => 'Bestand uploaden';

  @override
  String get filesUploading => 'Uploaden…';

  @override
  String get filesUploadFailed => 'Uploaden mislukt';

  @override
  String get filesUploaded => 'Geüpload';

  @override
  String filesUploadingProgress(String current, String total) {
    return 'Uploaden $current van $total…';
  }

  @override
  String filesUploadedCount(String count) {
    return '$count bestanden geüpload';
  }

  @override
  String get filesPermissionMissing =>
      'Toestemming voor toegang tot alle bestanden ontbreekt';

  @override
  String get filesPermissionHelp =>
      'Zonder deze toestemming kan alleen door de appmap worden gebladerd. Het toestemmingsscherm wordt op de tablet geopend.';

  @override
  String get filesGrant => 'Toestaan op apparaat';

  @override
  String get filesUp => 'Eén map omhoog';

  @override
  String get filesShared => 'Gedeelde opslag';

  @override
  String get filesApp => 'Appmap';

  @override
  String get filesReadFailed => 'Kon de map niet lezen';

  @override
  String get filesEmpty => 'Lege map';

  @override
  String get filesEmptyHelp => 'Deze map bevat nog niets.';

  @override
  String get filesFolder => 'Map';

  @override
  String get filesDownload => 'Downloaden';

  @override
  String get filesDownloadFailed => 'Downloaden is mislukt';

  @override
  String filesDeleteTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get filesDeleteHelp =>
      'Het bestand wordt verwijderd van het apparaat.';

  @override
  String get filesInvalidPath => 'Ongeldig pad';

  @override
  String get filesNoFolder => 'Map bestaat niet';

  @override
  String get filesNoFile => 'Bestand bestaat niet';

  @override
  String filesReadError(String error) {
    return 'Kan map niet lezen: $error';
  }

  @override
  String filesWriteError(String error) {
    return 'Schrijven mislukt: $error';
  }

  @override
  String get filesDeleteFailed => 'Kon het bestand niet verwijderen';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin =>
      'Voor vlootbeheer is beheer op afstand nodig';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Kiosken vinden elkaar via deze functie. Schakel onder Apparaat \'Beheer op afstand\' en \'Andere kiosken zoeken\' in en kom daarna hier terug.';

  @override
  String get fleetLeadThisFleet => 'Deze vloot leiden';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      'Synchroniseer de instellingen van deze kiosk met de volgers. Alle kiosken moeten dezelfde versie gebruiken.';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead =>
      'Een kiosk die een leider volgt, kan zelf geen vloot leiden.';

  @override
  String get fleetFollowers => 'Volgers';

  @override
  String get fleetProfiles => 'Profielen';

  @override
  String get fleetLeader => 'Leider';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      'Lees welke instellingen wel en niet worden gesynchroniseerd in de ';

  @override
  String get fleetFleetManagementDocumentation =>
      'documentatie over vlootbeheer';

  @override
  String get fleetMore => 'Meer';

  @override
  String get fleetSearchFollowers =>
      'De kiosken die door deze kiosk worden geleid, hun status en een optie om een kiosk toe te voegen.';

  @override
  String get fleetAddAKiosk => 'Een kiosk toevoegen';

  @override
  String get fleetAddAKioskFollowerAcceptsOnScreenOrRemoteAdmin =>
      'Voeg een ontdekte kiosk toe of voer het IP-adres in. De volger accepteert de uitnodiging op het scherm of via beheer op afstand.';

  @override
  String get fleetSendInvitation => 'Uitnodiging verzenden';

  @override
  String get fleetInviteAgain => 'Opnieuw uitnodigen';

  @override
  String fleetRemoveName(String name) {
    return '$name verwijderen?';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      'De kiosk volgt deze leider niet meer en behoudt zijn instellingen.';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name wil deze kiosk leiden';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      'Vanaf nu vervangen de instellingen van de leider de instellingen van deze kiosk in de categorieën die worden gesynchroniseerd. Deze kiosk behoudt zijn naam en identiteit.';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      'Vanaf nu vervangen de instellingen van de leider de instellingen van deze kiosk in de categorieën die worden gesynchroniseerd. Deze kiosk behoudt zijn naam, de eigen Home Assistant-, Music Assistant- en ESPHome-identiteit en de hardwarekeuzes. Je kunt de vloot op elk moment verlaten via Instellingen → Vlootbeheer.';

  @override
  String get fleetAccept => 'Accepteren';

  @override
  String get fleetLookingForOtherKiosks => 'Andere kiosken zoeken…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      'Geen kiosken ontdekt. Gebruik \'Toevoegen via IP\' om een kiosk op een bekend adres te vinden.';

  @override
  String fleetFollowsName(String name) {
    return 'Volgt $name';
  }

  @override
  String get fleetLeadsAFleet => 'Leidt een vloot';

  @override
  String get fleetNoFleetManagement => 'Geen vlootbeheer actief';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      'Kiosken op dit netwerk die deze leider nog niet volgen. Kies een kiosk en bepaal welke instellingen deze ontvangt. Daarna wordt de uitnodiging verzonden. Een kiosk met een build zonder vlootbeheer wordt lid zodra daarop een geschikte build draait.';

  @override
  String get fleetJoinedTheFleet => 'Aan de vloot toegevoegd';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly =>
      'De instellingen van de leider worden binnenkort ontvangen.';

  @override
  String get fleetAddByIp => 'Toevoegen via IP';

  @override
  String get fleetFindKiosk => 'Kiosk zoeken';

  @override
  String get fleetFindingKiosk => 'Kiosk zoeken…';

  @override
  String get fleetIpAddress => 'IP-adres';

  @override
  String get fleetRemoteAdminPort => 'Poort voor beheer op afstand';

  @override
  String get fleetAddressHelp =>
      'Voer het IP-adres van de kiosk en de poort voor beheer op afstand in.';

  @override
  String get fleetAddAProfile => 'Een profiel toevoegen';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      'De verzameling instellingen, toegangsgegevens en uitzonderingen die wordt gesynchroniseerd.';

  @override
  String get fleetNewProfile => 'Nieuw profiel';

  @override
  String get fleetProfile => 'Profiel';

  @override
  String get fleetUpdatesOnly => 'Alleen updates';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed =>
      'Er worden geen instellingen gesynchroniseerd. Alleen updates worden verstuurd.';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return 'Categorieën: $selected van $total. Toegangsgegevens: $credentials van $credentialTotal. Uitgesloten: $excluded.';
  }

  @override
  String get fleetThisProfileIsGone => 'Dit profiel bestaat niet meer';

  @override
  String get fleetItWasDeletedFromAnotherPage =>
      'Het profiel is op een andere pagina verwijderd.';

  @override
  String get fleetName => 'Naam';

  @override
  String get fleetRename => 'Hernoemen';

  @override
  String get fleetRenameProfile => 'Profiel hernoemen';

  @override
  String get fleetWhatItSyncs => 'Wat het synchroniseert';

  @override
  String get fleetNothing => 'Niets';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      'Kiosken met dit profiel behouden al hun eigen instellingen. De leider verstuurt alleen updates naar deze kiosken.';

  @override
  String get fleetCategories => 'Categorieën';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected van $total: $names';
  }

  @override
  String get fleetCredentials => 'Toegangsgegevens';

  @override
  String get fleetNoneTravel => 'Geen toegangsgegevens meesturen';

  @override
  String get fleetIncludeTheDashboard => 'Het dashboard opnemen';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard =>
      'De startpagina en het standaarddashboard.';

  @override
  String get fleetExcludedSettings => 'Uitgesloten instellingen';

  @override
  String get fleetOneSettingLeftOut => 'Eén instelling is weggelaten';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return '$count instellingen zijn weggelaten';
  }

  @override
  String get fleetNoKiosksAssigned => 'Geen kiosken toegewezen';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      'Wijs dit profiel op de pagina Vlootbeheer aan een kiosk toe.';

  @override
  String get fleetDuplicate => 'Dupliceren';

  @override
  String get fleetCloneThisProfileIntoANewOne =>
      'Maak op basis van dit profiel een nieuw profiel.';

  @override
  String get fleetDuplicateProfile => 'Profiel dupliceren';

  @override
  String fleetNameCopy(String name) {
    return '$name-kopie';
  }

  @override
  String get fleetDeleteProfile => 'Profiel verwijderen';

  @override
  String get fleetNoKioskIsOnIt =>
      'Dit profiel is niet aan een kiosk toegewezen.';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile =>
      'Kiosken met dit profiel krijgen het standaardprofiel.';

  @override
  String fleetDeleteName(String name) {
    return '$name verwijderen?';
  }

  @override
  String get fleetBlackScreens => 'Zwarte schermen';

  @override
  String fleetSyncToName(String name) {
    return 'Synchroniseren met $name';
  }

  @override
  String get fleetDefault => 'Standaard';

  @override
  String get fleetNone => 'Geen';

  @override
  String get fleetSearchProfiles =>
      'Profielen die aan een volger kunnen worden toegewezen, met categorieën, toegangsgegevens, het dashboard en uitgesloten instellingen.';

  @override
  String get fleetSyncNow => 'Nu synchroniseren';

  @override
  String get fleetChangedHereWaitingForTheLeader =>
      'Hier gewijzigd, wacht op de leider';

  @override
  String fleetSyncedTime(String time) {
    return 'Gesynchroniseerd $time';
  }

  @override
  String get fleetWaitingForTheFirstSync =>
      'Wachten op de eerste synchronisatie';

  @override
  String get fleetNothingYet => 'Nog niets';

  @override
  String get fleetNoCredentials => 'Geen toegangsgegevens';

  @override
  String fleetWithTheNames(String names) {
    return 'Met de $names';
  }

  @override
  String get fleetTheDashboard => 'het dashboard';

  @override
  String get fleetNoDashboard => 'geen dashboard';

  @override
  String get fleetTheDashboardDetail => 'Het dashboard';

  @override
  String get fleetNoDashboardDetail => 'Geen dashboard';

  @override
  String get fleetSyncedFromTheLeader => 'Gesynchroniseerd van de leider';

  @override
  String get fleetLeaveTheFleet => 'Vloot verlaten';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre =>
      'Stopt de synchronisatie. Instellingen blijven zoals ze zijn.';

  @override
  String get fleetLeaveTheFleetDetail => 'De vloot verlaten?';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name stuurt geen instellingen meer naar deze kiosk. Alles blijft zoals het nu is.';
  }

  @override
  String get fleetLeave => 'Verlaten';

  @override
  String get fleetJustNow => 'zojuist';

  @override
  String fleetCountMinAgo(String count) {
    return '$count min geleden';
  }

  @override
  String fleetCountHAgo(String count) {
    return '$count h geleden';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return '$count dagen geleden';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return '$name beheert deze instellingen. Een lokale wijziging wordt bij de volgende synchronisatie vervangen.';
  }

  @override
  String get fleetDeclinedOnTheKiosk => 'Geweigerd op de kiosk';

  @override
  String get fleetWaitingForItsOk => 'Wachten op bevestiging';

  @override
  String get fleetLeftTheFleet => 'Heeft de vloot verlaten';

  @override
  String fleetSendingPercent(String percent) {
    return 'Verzenden $percent%';
  }

  @override
  String get fleetInstalling => 'Installeren';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return 'Gebruikt $version; deze kiosk moet worden bijgewerkt';
  }

  @override
  String fleetNeedsVersion(String version) {
    return 'Heeft $version nodig';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return 'Downloaden $percent%';
  }

  @override
  String get fleetSyncing => 'Synchroniseren…';

  @override
  String get fleetErrorUnreachable => 'Onbereikbaar';

  @override
  String get fleetErrorBadAnswer => 'Ongeldig antwoord';

  @override
  String get fleetErrorThePushFailed => 'Verzenden is mislukt';

  @override
  String get fleetErrorLeadThisFleetIsOff => '\'Deze vloot leiden\' staat uit';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      '\'Beheer op afstand\' en \'Andere kiosken zoeken\' moeten zijn ingeschakeld';

  @override
  String get fleetErrorPickAnotherKiosk => 'Kies een andere kiosk';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      'Die kiosk is nu niet op het netwerk.';

  @override
  String get fleetErrorThatKioskDidNotAnswer => 'Die kiosk antwoordde niet.';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation =>
      'Die kiosk weigerde de uitnodiging.';

  @override
  String get fleetErrorTheDefaultProfileStays =>
      'Het standaardprofiel blijft behouden';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays =>
      'Het profiel \'Alleen updates\' blijft behouden';

  @override
  String get fleetErrorNoSuchProfile => 'Profiel bestaat niet';

  @override
  String get fleetErrorNoSuchFollower => 'Volger bestaat niet';

  @override
  String get fleetErrorNoInvitationIsWaiting => 'Er wacht geen uitnodiging';

  @override
  String get fleetErrorMalformedInvitation => 'Ongeldige uitnodiging';

  @override
  String get fleetErrorCouldNotMintAToken =>
      'Er kon geen token worden aangemaakt';

  @override
  String get fleetErrorNotAFollowerYet => 'nog geen volger';

  @override
  String get fleetErrorOffline => 'offline';

  @override
  String get fleetErrorUpToDate => 'bijgewerkt';

  @override
  String get fleetErrorAlreadyDownloading => 'wordt al gedownload';

  @override
  String get fleetErrorDidNotAnswer => 'reageerde niet';

  @override
  String get fleetErrorDidNotTakeTheUpload =>
      'heeft de upload niet geaccepteerd';

  @override
  String fleetProfileNameExists(String name) {
    return 'Er bestaat al een profiel met de naam $name';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return 'gebruikt $version al';
  }

  @override
  String get fleetUnsupportedBuild =>
      'Op die kiosk draait een build zonder vlootbeheer. De kiosk wordt lid zodra daarop een geschikte build draait.';

  @override
  String get fleetErrorAddressMismatch =>
      'Het adres behoort tot een andere kiosk of vloot';

  @override
  String get fleetErrorInvalidIp => 'Geef een geldig IP-adres op.';

  @override
  String get fleetErrorInvalidPort => 'Voer een poort in van 1 tot 65535.';

  @override
  String get fleetErrorIdentityNotReady =>
      'De identiteit van deze kiosk is nog niet gereed. Probeer het opnieuw.';

  @override
  String get fleetErrorInvalidIdentity =>
      'Dat adres gaf geen geldige kiosk-identiteit terug.';

  @override
  String get fleetErrorAlreadyMember =>
      'Deze kiosk maakt al deel uit van deze vloot.';

  @override
  String get fleetErrorIsLeader => 'Die kiosk leidt een vloot.';

  @override
  String get fleetErrorOtherLeader => 'Die kiosk volgt al een andere leider.';

  @override
  String fleetPluginsNames(String names) {
    return 'Plug-ins: $names';
  }

  @override
  String fleetCouldNotInstallNameReason(String name, String reason) {
    return 'Kan $name niet installeren: $reason';
  }

  @override
  String fleetReinstallNameOnThisKioskToSyncIt(String name) {
    return 'Installeer $name opnieuw op deze kiosk om het te synchroniseren';
  }

  @override
  String get fleetSwitchKiosk => 'Kiosk wisselen';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      'Ontdekte kiosken en opgeslagen vlootleden. Als je een kiosk kiest, wordt het beheer op afstand ervan op deze pagina geopend.';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      'Geen andere kiosken gevonden. Kiosken verschijnen via netwerkdetectie of een opgeslagen vlootlidmaatschap.';

  @override
  String get fleetSyncedCredentials => 'Gesynchroniseerde toegangsgegevens';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced =>
      'De instellingen in deze lijst worden niet met de volgers gesynchroniseerd.';

  @override
  String get fleetNothingLeftOut => 'Geen instellingen uitgesloten';

  @override
  String get fleetSyncItAgain => 'Opnieuw synchroniseren';

  @override
  String get fleetAddASetting => 'Een instelling toevoegen';

  @override
  String get fleetExcludeASetting => 'Een instelling uitsluiten';

  @override
  String get fleetSearchSettings => 'Instellingen zoeken';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return '$count meer. Typ om de lijst te verkleinen.';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return 'Niet gesynchroniseerd: $note';
  }

  @override
  String get fleetTheAssignedSatellite => 'de toegewezen satelliet';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain =>
      'microfoon- en luidsprekerapparaten, microfoonversterking';

  @override
  String get fleetTheDeviceCamera => 'de apparaatcamera';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      'de gevolgde speler, de Sendspin-speler-ID';

  @override
  String get fleetNodeNameMacEncryptionKey =>
      'nodenaam, MAC-adres, versleutelingssleutel';

  @override
  String get fleetThePinIsAlsoSynced => 'de pincode wordt ook gesynchroniseerd';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential =>
      'de sleutel, tenzij deze als toegangsgegeven wordt gesynchroniseerd';

  @override
  String get fleetTheAlarmsThemselves => 'de alarmen zelf';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'naam, beheer op afstand, rendereroplossingen, schaal';

  @override
  String get fleetHomeAssistantToken => 'Home Assistant-token';

  @override
  String get fleetMusicAssistantToken => 'Music Assistant-token';

  @override
  String get fleetImmichApiKey => 'Immich-API-sleutel';

  @override
  String get fleetOpenAiApiKey => 'OpenAI-API-sleutel';

  @override
  String get fleetXaiApiKey => 'xAI-API-sleutel';

  @override
  String get fleetGeminiApiKey => 'Gemini-API-sleutel';

  @override
  String get fleetMcpServerToken => 'MCP-servertoken';

  @override
  String get fleetPlugins => 'Plug-ins';

  @override
  String get fleetPluginSecrets => 'Geheimen van plug-ins';

  @override
  String get fleetNoPluginsInstalledOnThisKiosk =>
      'Geen plug-ins geïnstalleerd op deze kiosk';

  @override
  String get fleetKiosksOnThisProfileInstallTheseAndTakeTheir =>
      'Kiosken met dit profiel installeren deze en nemen hun instellingen over van deze kiosk.';

  @override
  String get fleetUpdateTheFleet => 'De vloot bijwerken';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      'Werk de hele vloot bij naar de Kiosk Satellite-versie die op de leider draait.';

  @override
  String get fleetKeepFollowersOnThisVersion => 'Volgers op deze versie houden';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      'Alle volgers automatisch bijwerken naar de Kiosk Satellite-versie die op de leider draait.';

  @override
  String get fleetNothingToUpdate => 'Niets om bij te werken';

  @override
  String get fleetUpdating => 'Bijwerken';

  @override
  String fleetNamesInstalling(String names) {
    return 'Installatie op $names is bezig.';
  }

  @override
  String get fleetSearchUpdates =>
      'Installeer de release die aan elke volger wordt aangeboden en daarna op deze kiosk.';

  @override
  String get gestureAction => 'Actie';

  @override
  String get gestureNavigate => 'Ga naar een dashboardweergave';

  @override
  String get gestureUrl => 'Een webpagina openen';

  @override
  String get gestureCameraView => 'Een cameraweergave tonen';

  @override
  String get gestureLauncher => 'De appstarter openen';

  @override
  String get gestureIntercomOpen => 'Een kiosk bellen openen';

  @override
  String get gestureIntercomCall => 'Bel een kiosk';

  @override
  String get gestureIntercomHangup => 'Intercomgesprek beëindigen';

  @override
  String get gestureIntercomAnswer => 'Intercomgesprek aannemen';

  @override
  String get gestureIntercomDecline => 'Intercomgesprek afwijzen';

  @override
  String get gestureAlarmStop => 'Stop het alarm';

  @override
  String get gestureAlarmSnooze => 'Laat het alarm sluimeren';

  @override
  String get gestureScreensaver => 'Start de schermbeveiliging';

  @override
  String get gestureScreensaverStop => 'Stop de schermbeveiliging';

  @override
  String get gestureHoldMode => 'Wachtstand aan/uit';

  @override
  String get gestureRefresh => 'Dashboard vernieuwen';

  @override
  String get gestureMediaPlayPause => 'Media afspelen of pauzeren';

  @override
  String get gestureHaKiosk => 'HA-kioskmodus in- of uitschakelen';

  @override
  String get gesturePluginRun => 'Een plug-inactie uitvoeren';

  @override
  String get gestureLaunchApp => 'Een andere app openen';

  @override
  String get gestureDeepLink => 'Een deep link openen';

  @override
  String get gestureAndroidSettings => 'Android-instellingen openen';

  @override
  String get gestureOpenCalendar => 'Agenda openen';

  @override
  String get gestureOpenMusicLibrary => 'Muziekbibliotheek openen';

  @override
  String get gestureService => 'Een service aanroepen';

  @override
  String get gestureScript => 'Een script uitvoeren';

  @override
  String get gestureAutomation => 'Automatisering activeren';

  @override
  String get gestureEvent => 'Een gebeurtenis activeren';

  @override
  String get gesturePluginAction => 'Plug-inactie';

  @override
  String get gesturePluginActions => 'Plug-inacties';

  @override
  String get gesturePluginHelp =>
      'Schakel eerst een plug-in met acties in via Plug-inbeheer.';

  @override
  String get gesturePluginFailed => 'Kon plug-inacties niet laden.';

  @override
  String get gestureUrlError => 'Voer een volledige http(s)-URL in.';

  @override
  String get gesturePackage => 'Pakketnaam';

  @override
  String get gesturePackageError => 'Vul een pakketnaam in.';

  @override
  String get gestureUriError => 'Voer een volledige URI in.';

  @override
  String get gestureCameraTitle => 'Cameraweergave';

  @override
  String gestureCameraShow(String name) {
    return '$name tonen';
  }

  @override
  String get gestureCameraClose => 'Cameraweergave sluiten';

  @override
  String get gestureCameraEmpty => 'Nog geen cameraweergave ingesteld.';

  @override
  String get gestureIntercomEmpty =>
      'Er is nog geen kiosk op het netwerk gevonden.';

  @override
  String get gestureVoiceWake => 'Een spraakopdracht starten';

  @override
  String get gestureVoiceStop => 'De spraakassistent stoppen';

  @override
  String get gestureVoiceMute =>
      'Voice Satellite dempen of het dempen opheffen';

  @override
  String get gestureOpenAlarmList => 'Alarmlijst openen';

  @override
  String get gestureOpenNextAlarm => 'Volgende alarm openen';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '$count tikken in de hoek $corner';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return 'Hoek $corner $seconds s vasthouden';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return 'Dubbeltik met $count vingers';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return 'Tik met $count vingers';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return 'Met $count vingers $seconds s vasthouden';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return 'Hoekvolgorde: $sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '$count keer klappen';
  }

  @override
  String get gestureDescribeOpenHand => 'Toon een open hand';

  @override
  String gestureDescribeOneFinger(String count) {
    return '$count vinger tonen';
  }

  @override
  String gestureDescribeFingers(String count) {
    return '$count vingers tonen';
  }

  @override
  String get gestureTopLeft => 'linksboven';

  @override
  String get gestureTopRight => 'rechtsboven';

  @override
  String get gestureBottomLeft => 'linksonder';

  @override
  String get gestureBottomRight => 'rechtsonder';

  @override
  String gestureGoTo(String value) {
    return 'Ga naar $value';
  }

  @override
  String gestureOpen(String value) {
    return '$value openen';
  }

  @override
  String get gestureCameraToggle => 'Cameraweergave aan/uit';

  @override
  String gestureCameraToggleName(String name) {
    return 'Cameraweergave aan/uit $name';
  }

  @override
  String gestureCall(String value) {
    return 'Bel $value';
  }

  @override
  String gestureOpenApp(String package) {
    return 'App $package openen';
  }

  @override
  String gestureRun(String value) {
    return '$value uitvoeren';
  }

  @override
  String gestureTriggerAction(String value) {
    return '$value activeren';
  }

  @override
  String gestureFireEvent(String value) {
    return 'Gebeurtenis $value activeren';
  }

  @override
  String gestureDescribeButtonPress(String button) {
    return 'Op de knop $button drukken';
  }

  @override
  String gestureDescribeButtonDouble(String button) {
    return 'Twee keer op de knop $button drukken';
  }

  @override
  String gestureDescribeButtonHold(String button) {
    return 'De knop $button ingedrukt houden';
  }

  @override
  String get gestureValid => 'Ziet er goed uit.';

  @override
  String get gestureValidationFailed => 'Kon niet controleren.';

  @override
  String gestureDomainMissing(String value) {
    return 'Domein $value niet gevonden.';
  }

  @override
  String gestureServiceMissing(String value) {
    return 'Service $value niet gevonden.';
  }

  @override
  String gestureEntityMissing(String value) {
    return 'Entiteit $value niet gevonden.';
  }

  @override
  String gestureEntityRequired(String domain) {
    return 'Voer een $domain.* entiteit in.';
  }

  @override
  String get gestureScriptEntity => 'Script-entiteit';

  @override
  String get gestureAutomationEntity => 'Automatiseringsentiteit';

  @override
  String get gestureEntityOptional => 'Entiteit (optioneel)';

  @override
  String get gestureServiceData => 'Servicegegevens (optioneel)';

  @override
  String get gestureServiceTitle => 'Een Home Assistant-service aanroepen';

  @override
  String get gestureServiceJson =>
      'Servicegegevens moeten een JSON-object zijn.';

  @override
  String get gestureEventType => 'Gebeurtenistype';

  @override
  String get gestureEventData => 'Gebeurtenisgegevens (optioneel)';

  @override
  String get gestureEventTitle => 'Een Home Assistant-gebeurtenis activeren';

  @override
  String get gestureEventRequired => 'Gebeurtenistype is vereist.';

  @override
  String get gestureEventJson =>
      'Gebeurtenisgegevens moeten een JSON-object zijn.';

  @override
  String get gestureServiceSearch => 'Services zoeken';

  @override
  String get gestureServiceChoose => 'Kies een service';

  @override
  String get gestureServiceNoEntity => 'Niet gebruikt door deze service';

  @override
  String get gestureTester => 'Handgebarentester';

  @override
  String get gestureOpenTester => 'Tester openen';

  @override
  String get gestureCameraFirst =>
      'Schakel eerst de camera in via de camera-instellingen.';

  @override
  String get gestureTesterHelp =>
      'Bekijk welke vingers de camera herkent om te leren hoe je je hand moet houden.';

  @override
  String get gestureHandHelp =>
      'Houd je hand op schouderhoogte met de handpalm naar de camera en de vingers gespreid. Buig een vinger volledig om deze niet mee te laten tellen. Leg de duim over de handpalm om vier vingers te tonen: de duim telt alleen mee bij een open hand.';

  @override
  String get gestureTesterPaused =>
      'Gebaren worden niet geactiveerd zolang de tester geopend is.';

  @override
  String get gestureShowHand => 'Toon een hand aan de camera.';

  @override
  String gestureTesterTrigger(String action) {
    return 'Activeert: $action';
  }

  @override
  String get gestureNoCount => 'Geen enkel gebaar gebruikt dit aantal.';

  @override
  String get gestureNoHand => 'Geen hand in zicht';

  @override
  String get gestureReadingHand => 'Hand herkennen';

  @override
  String get gestureNoFingers => 'Geen opgestoken vingers';

  @override
  String gestureHandsCount(String count) {
    return '$count handen in beeld; de grootste wordt herkend.';
  }

  @override
  String get gestureTesterSearch =>
      'Liveweergave van de vingers die de camera herkent.';

  @override
  String get gestureHoldConfirmed => 'Vasthouden bevestigd';

  @override
  String gestureHoldProgress(String progress) {
    return 'Voortgang vasthouden: $progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return 'Duur van vasthouden: $duration';
  }

  @override
  String get gestureHaServiceKind => 'Home Assistant-service';

  @override
  String get gestureHaScriptKind => 'Home Assistant-script';

  @override
  String get gestureHaAutomationKind => 'Home Assistant-automatisering';

  @override
  String get gestureHaEventKind => 'Home Assistant-gebeurtenis';

  @override
  String gestureRan(String value) {
    return '$value uitgevoerd';
  }

  @override
  String gestureRunFailed(String value) {
    return 'Kon $value niet uitvoeren';
  }

  @override
  String gestureCalled(String value) {
    return '$value aangeroepen';
  }

  @override
  String gestureCallFailed(String value) {
    return 'Kon $value niet aanroepen';
  }

  @override
  String gestureTriggered(String value) {
    return '$value geactiveerd';
  }

  @override
  String gestureTriggerFailed(String value) {
    return 'Kon $value niet activeren';
  }

  @override
  String gestureFired(String value) {
    return 'Gebeurtenis $value geactiveerd';
  }

  @override
  String gestureFireFailed(String value) {
    return 'Kon gebeurtenis $value niet activeren';
  }

  @override
  String get gestureDone => 'Klaar';

  @override
  String get gestureFailed => 'Mislukt';

  @override
  String get gestureEdit => 'Gebaar bewerken';

  @override
  String get gestureTrigger => 'Gebaar';

  @override
  String get gestureCornerTaps => 'Tikken in een hoek';

  @override
  String get gestureCornerHold => 'Een hoek vasthouden';

  @override
  String get gestureFingerTaps => 'Meervingertap';

  @override
  String get gestureFingerHold => 'Vasthouden met meerdere vingers';

  @override
  String get gestureSequence => 'Hoekvolgorde';

  @override
  String get gestureClaps => 'Handgeklap';

  @override
  String get gestureShowFingers => 'Vingers tonen';

  @override
  String get gestureCorner => 'Hoek';

  @override
  String get gestureCornerTl => 'Linkerbovenhoek';

  @override
  String get gestureCornerTr => 'Rechterbovenhoek';

  @override
  String get gestureCornerBl => 'Linkeronderhoek';

  @override
  String get gestureCornerBr => 'Rechtsonderhoek';

  @override
  String get gestureTaps => 'Tikken';

  @override
  String get gestureTaps2 => '2 tikken';

  @override
  String get gestureTaps3 => '3 tikken';

  @override
  String get gestureTaps4 => '4 tikken';

  @override
  String get gestureFingers => 'Vingers';

  @override
  String get gestureFinger1 => '1 vinger';

  @override
  String get gestureFinger2 => '2 vingers';

  @override
  String get gestureFinger3 => '3 vingers';

  @override
  String get gestureFinger4 => '4 vingers';

  @override
  String get gestureOpenHand5 => 'Open hand (5)';

  @override
  String get gestureSingleTap => 'Enkele tik';

  @override
  String get gestureDoubleTap => 'Dubbele tik';

  @override
  String gestureHoldDuration(String seconds) {
    return '$seconds s vasthouden';
  }

  @override
  String get gestureCameraHelp =>
      'Vereist een ingeschakelde camera en een goed verlichte omgeving.';

  @override
  String get gestureUnavailable => 'Niet beschikbaar op dit apparaat.';

  @override
  String get gestureClaps2 => '2 klappen';

  @override
  String get gestureClaps3 => '3 klappen';

  @override
  String get gestureClaps4 => '4 klappen';

  @override
  String get gestureClapHelp =>
      'Handgeklap wordt via de microfoon herkend, met of zonder wekwoorddetectie.';

  @override
  String get gestureSequenceHelp =>
      'Tik op de hoeken in volgorde (2 tot 8 stappen).';

  @override
  String get gestureRemoveStep => 'Laatste stap verwijderen';

  @override
  String get gestureUndo => 'Ongedaan maken';

  @override
  String get gestureChooseAction => 'Een actie kiezen';

  @override
  String get gestureActionHelp => 'De actie die dit gebaar activeert.';

  @override
  String get gestureChangeHelp => 'Tik om te wijzigen.';

  @override
  String get gestureChooseError => 'Kies een actie.';

  @override
  String get gestureSequenceError => 'Voeg minstens twee hoeken toe.';

  @override
  String get gesturePluginTrigger => 'Plug-intrigger';

  @override
  String get gesturePluginTriggerField => 'Trigger';

  @override
  String get gesturePluginTriggerHelp =>
      'Schakel eerst een plug-in met triggers in via Plug-inbeheer.';

  @override
  String get gestureButton => 'Knop';

  @override
  String get gesturePress => 'Drukken';

  @override
  String get gestureDoublePress => 'Dubbel drukken';

  @override
  String get gestureHoldPress => 'Ingedrukt houden';

  @override
  String get gestureButtonDefaults =>
      'Een druk die geen gebaar gebruikt, houdt zijn eigen taak: Actie neemt op, stopt of negeert wat er overgaat en start anders een spraakopdracht, Microfoon dempt Voice Satellite en de volumeknoppen wijzigen het volume.';

  @override
  String get intercomCall => 'Oproep';

  @override
  String get intercomNoReady => 'Geen kiosk is beschikbaar.';

  @override
  String get intercomOneReady => '1 kiosk is beschikbaar.';

  @override
  String intercomManyReady(String count) {
    return '$count kiosken zijn beschikbaar.';
  }

  @override
  String get intercomCallKiosk => 'Bel een kiosk';

  @override
  String get intercomAnnounceAll => 'Omroepen naar alle kiosken';

  @override
  String get intercomAnnounceHelp =>
      'Praat tegen alle kiosken. Communicatie werkt alleen in één richting.';

  @override
  String intercomMissedFrom(String name) {
    return 'Gemiste oproep van $name';
  }

  @override
  String intercomRangFor(String seconds) {
    return 'Ging $seconds seconden over.';
  }

  @override
  String get intercomCallBack => 'Terugbellen';

  @override
  String get intercomDeclined => 'Afgewezen';

  @override
  String get intercomBusy => 'Bezet';

  @override
  String get intercomPeerOff => 'De intercom staat uit.';

  @override
  String get intercomPeerKey => 'Andere intercomsleutel';

  @override
  String get intercomNoAnswer => 'Geen antwoord';

  @override
  String get intercomDidNotAnswer => 'Niet opgenomen';

  @override
  String get intercomVoiceFailed => 'De spraakverbinding is mislukt';

  @override
  String get intercomCancelled => 'Geannuleerd';

  @override
  String get intercomPageMic => 'De pagina gebruikt de microfoon';

  @override
  String get intercomNobody => 'Geen enkele kiosk kon de oproep aannemen.';

  @override
  String get intercomDone => 'Klaar';

  @override
  String get intercomEnded => 'Oproep beëindigd';

  @override
  String get intercomMaxDurationReached => 'Maximale gespreksduur bereikt';

  @override
  String get intercomAnnouncement => 'Omroepbericht';

  @override
  String get intercomAnnouncingOne => 'Omroepen naar 1 kiosk';

  @override
  String intercomAnnouncingMany(String count) {
    return 'Omroepen naar $count kiosken';
  }

  @override
  String get intercomIsCalling => 'belt';

  @override
  String get intercomIsAnnouncing => 'doet een aankondiging';

  @override
  String get intercomCalling => 'Bellen…';

  @override
  String intercomAnswersWithCameraIn(String seconds) {
    return 'Camera aan over $seconds s';
  }

  @override
  String intercomAnswersIn(String seconds) {
    return 'Neemt op over $seconds s';
  }

  @override
  String get intercomRinging => 'Gaat over';

  @override
  String get intercomConnecting => 'Verbinden…';

  @override
  String intercomDoneDuration(String duration) {
    return 'Klaar, $duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return 'Oproep beëindigd, $duration';
  }

  @override
  String get intercomDecline => 'Afwijzen';

  @override
  String get intercomAnswer => 'Opnemen';

  @override
  String get intercomEveryKiosk => 'Elke kiosk';

  @override
  String get intercomStop => 'Stoppen';

  @override
  String intercomHearsYou(String name) {
    return '$name hoort je';
  }

  @override
  String get intercomAllHearYou => 'Alle kiosken horen je';

  @override
  String get intercomHoldHelp =>
      'Ingedrukt houden om te praten, loslaten om te luisteren';

  @override
  String get intercomMuted => 'Gedempt';

  @override
  String get intercomMute => 'Dempen';

  @override
  String get intercomEnd => 'Beëindigen';

  @override
  String get intercomReply => 'Beantwoorden';

  @override
  String get intercomDismiss => 'Sluiten';

  @override
  String get intercomCallAgain => 'Opnieuw bellen';

  @override
  String get intercomDashboardMic =>
      'Het dashboard gebruikt de microfoon. Je kunt alleen luisteren.';

  @override
  String get intercomMicDenied =>
      'Geen microfoontoestemming. Je kunt alleen luisteren.';

  @override
  String get intercomHoldTalk => 'Ingedrukt houden om te praten';

  @override
  String get intercomPlaying => 'Wordt afgespeeld';

  @override
  String get intercomAKiosk => 'een kiosk';

  @override
  String intercomCallingName(String name) {
    return '$name bellen';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name belt';
  }

  @override
  String intercomInCallName(String name) {
    return 'In een gesprek met $name';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name kondigt aan';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant: $message';
  }

  @override
  String get intercomEndCall => 'Gesprek beëindigen';

  @override
  String get intercomVoiceCall => 'Spraakoproep';

  @override
  String get intercomVideoCall => 'Video-oproep';

  @override
  String get intercomVoiceOnly => 'Alleen spraak';

  @override
  String get intercomVideoAnswer => 'Video';

  @override
  String get intercomSwitchCamera => 'Camera wisselen';

  @override
  String get intercomCameraButton => 'Camera';

  @override
  String get intercomCameraOff => 'Camera uit';

  @override
  String get intercomYourCameraOff => 'Je camera staat uit';

  @override
  String get intercomVideoReconnecting => 'Video maakt opnieuw verbinding…';

  @override
  String get intercomCameraOffNotice =>
      'De camera staat uit. Deze kiosk kan video tonen, maar niet verzenden.';

  @override
  String get intercomCallFailed => 'Kon niet bellen';

  @override
  String get intercomKeyFailed => 'Kon de sleutel niet wijzigen';

  @override
  String get intercomBroadcastFailed => 'Kon niet met iedereen praten';

  @override
  String get intercomDeviceNoAnswer => 'Het apparaat nam niet op.';

  @override
  String get intercomUnknownKiosk => 'onbekende kiosk';

  @override
  String get intercomNothingRinging => 'er is geen inkomende oproep';

  @override
  String get intercomNoCall => 'geen oproep';

  @override
  String get intercomDisabled => 'intercom is uitgeschakeld';

  @override
  String get intercomNeedsRemote => 'vereist beheer op afstand';

  @override
  String get intercomNeedsDiscovery =>
      'de intercom vereist beheer op afstand en Andere kiosken zoeken';

  @override
  String get intercomAlreadyCalling => 'al in gesprek';

  @override
  String get intercomNoReadyError => 'geen kiosk is beschikbaar';

  @override
  String get intercomKeyLength => 'een sleutel is ten minste 16 tekens';

  @override
  String get intercomMicHeld => 'de pagina gebruikt de microfoon';

  @override
  String get intercomMicPermission => 'microfoontoestemming ontbreekt';

  @override
  String get intercomCallerNoAnswer => 'de beller antwoordde niet';

  @override
  String get intercomMissedcall => 'Gemiste oproep';

  @override
  String get intercomListening => 'Luisteren';

  @override
  String get intercomAnnouncementsoff => 'Omroepberichten uitgeschakeld';

  @override
  String get intercomEncryptionMismatch => 'Versleuteling komt niet overeen';

  @override
  String get intercomEncryptionMismatchHelp =>
      'De versleutelingsinstellingen komen niet overeen. Schakel Communicatie versleutelen in op alle kiosken in het gesprek.';

  @override
  String get kioskBackClose => 'Druk opnieuw op terug om de app te sluiten';

  @override
  String get kioskBackAgain => 'Druk weer op terug om terug te gaan';

  @override
  String get kioskHoldOn => 'Wachtstand ingeschakeld';

  @override
  String get kioskHoldOff => 'Wachtstand uitgeschakeld';

  @override
  String get kioskHoldNotice =>
      'De huidige weergave blijft staan totdat je de wachtstand uitschakelt.';

  @override
  String get kioskDownloadComplete => 'Download voltooid';

  @override
  String get kioskDownloadFailed => 'Downloaden is mislukt';

  @override
  String get kioskDownload => 'Downloaden';

  @override
  String get kioskDownloading => 'Downloaden';

  @override
  String get kioskOpen => 'Openen';

  @override
  String get kioskTip => 'Tip';

  @override
  String get kioskMenuHint => 'Veeg vanaf de linkerkant om het menu te openen.';

  @override
  String get kioskUnknownLink => 'Onbekende kiosk-link';

  @override
  String get kioskOpenAppFailed => 'Kon de app niet openen';

  @override
  String get kioskWebViewMissing =>
      'Android System WebView is niet geïnstalleerd';

  @override
  String get kioskWebViewMissingHelp =>
      'Dit apparaat heeft geen WebView-provider, waardoor Home Assistant niet kan worden weergegeven. Installeer Android System WebView of Chrome en start Kiosk Satellite opnieuw.';

  @override
  String get kioskDuraSpeedBlocking => 'DuraSpeed blokkeert het dashboard';

  @override
  String get kioskDuraSpeedBlockingHelp =>
      'DuraSpeed op deze tablet voorkomt dat de dashboardrenderer wordt gestart. Op sommige tablets is hiervoor geen instellingenpagina beschikbaar. Schakel DuraSpeed eenmalig uit via ADB en start Kiosk Satellite daarna opnieuw:';

  @override
  String get kioskPinTitle => 'Kiosk-pincode';

  @override
  String get kioskPinHint => 'PIN';

  @override
  String get kioskWrongPin => 'Verkeerde pincode';

  @override
  String get kioskUnlock => 'Ontgrendelen';

  @override
  String get lockdownScreenLocked => 'Scherm is vergrendeld';

  @override
  String get logsWebConsole => 'Webconsole';

  @override
  String get logsDock => 'Vastzetten boven de livepagina';

  @override
  String get logsNoOutput => 'Nog geen console-uitvoer';

  @override
  String get logsShareSubject => 'Consolelogboek van Kiosk Satellite';

  @override
  String get logsInput => 'JavaScript uitvoeren op de pagina';

  @override
  String get logsInputHistory =>
      'JavaScript uitvoeren op de pagina (Enter om uit te voeren, Omhoog/Omlaag voor geschiedenis)';

  @override
  String get logsRun => 'Uitvoeren';

  @override
  String get logsEvaluationFailed => 'evaluatie mislukt';

  @override
  String get logsDeviceUnreachable => 'apparaat onbereikbaar';

  @override
  String logsEntries(String count) {
    return '$count vermeldingen';
  }

  @override
  String get logsCopyLog => 'Logboek kopiëren';

  @override
  String get logsShareLog => 'Logboek delen';

  @override
  String get logsCopied => 'Gekopieerd';

  @override
  String get logsCopyFailed => 'Kon niet kopiëren';

  @override
  String get logsOnClipboard => 'Het logboek staat op het klembord.';

  @override
  String get logsConsoleOnClipboard =>
      'Het consolelogboek staat op het klembord.';

  @override
  String get logsSystemLog =>
      'Android-systeemlogboek voor deze app (hier staan crashes)';

  @override
  String get logsErrors => 'Fouten en crashes';

  @override
  String get logsWarnings => 'Waarschuwingen';

  @override
  String get logsInfo => 'Informatie en foutopsporing';

  @override
  String get logsNoMatches =>
      'Geen overeenkomende regels. Schakel hierboven meer typen in om het volledige logboek te bekijken.';

  @override
  String get logsUnavailable => 'logcat niet beschikbaar';

  @override
  String logsReadFailed(String error) {
    return 'Kon logcat niet lezen: $error';
  }

  @override
  String get logsUnknown => 'onbekend';

  @override
  String get libraryTitle => 'Muziekbibliotheek';

  @override
  String get librarySource => 'Bron';

  @override
  String get librarySourceMa => 'Music Assistant';

  @override
  String get librarySourceHa => 'Home Assistant';

  @override
  String get librarySourceSonos => 'Sonos';

  @override
  String get librarySourceMaHint => 'Bibliotheek, zoeken en radio';

  @override
  String get librarySourceHaHint => 'Media van elke luidspreker';

  @override
  String get librarySourceSonosHint => 'Favorieten en afspeellijsten';

  @override
  String get libraryDiscover => 'Ontdekken';

  @override
  String get librarySearch => 'Zoeken';

  @override
  String get libraryBrowse => 'Bladeren';

  @override
  String get libraryLibrary => 'Bibliotheek';

  @override
  String get libraryArtists => 'Artiesten';

  @override
  String get libraryAlbums => 'Albums';

  @override
  String get libraryTracks => 'Nummers';

  @override
  String get libraryPlaylists => 'Afspeellijsten';

  @override
  String get libraryRadio => 'Radio';

  @override
  String get libraryPodcasts => 'Podcasts';

  @override
  String get libraryAudiobooks => 'Luisterboeken';

  @override
  String get libraryFavorites => 'Favorieten';

  @override
  String get librarySonosPlaylists => 'Sonos-afspeellijsten';

  @override
  String get libraryRecentlyPlayed => 'Recent afgespeeld';

  @override
  String get libraryRecentlyAdded => 'Recent toegevoegd';

  @override
  String get librarySort => 'Sorteren';

  @override
  String get librarySortAToZ => 'A tot Z';

  @override
  String get librarySortZToA => 'Z tot A';

  @override
  String get librarySortMostPlayed => 'Meest afgespeeld';

  @override
  String get libraryAlbumArtistsOnly => 'Alleen albumartiesten';

  @override
  String get libraryKindGenre => 'Genre';

  @override
  String get libraryBrowseByGenre => 'Bladeren op genre';

  @override
  String get settingLibraryTextScaleDescription =>
      'Grootte van titels, namen en labels in de bibliotheek.';

  @override
  String get settingLibrarySquareArtworkTitle => 'Vierkante afbeeldingen';

  @override
  String get settingLibrarySquareArtworkDescription =>
      'Toont artiesten als vierkante tegels, zoals albums en afspeellijsten.';

  @override
  String get settingLibraryGridDensityTitle => 'Rasterdichtheid';

  @override
  String get settingLibraryGridDensityDescription =>
      'Grootte van de tegels in de bibliotheek. Compact toont meer per rij.';

  @override
  String get settingLibrarySourcePickerTitle => 'Bronkeuze tonen';

  @override
  String get settingLibrarySourcePickerDescription =>
      'Toont de bronkeuze in de bibliotheek. Zet uit om de bibliotheek op de hierboven gekozen bron te houden.';

  @override
  String get settingLibrarySpeakerPillDescription =>
      'Toont de luidsprekerkeuze bovenaan de bibliotheek.';

  @override
  String get libraryDensityComfortable => 'Ruim';

  @override
  String get libraryDensityStandard => 'Standaard';

  @override
  String get libraryDensityCompact => 'Compact';

  @override
  String get libraryMoreResults => 'Meer resultaten';

  @override
  String get libraryTopTracks => 'Populaire nummers';

  @override
  String get libraryKindArtist => 'Artiest';

  @override
  String get libraryKindAlbum => 'Album';

  @override
  String get libraryKindTrack => 'Nummer';

  @override
  String get libraryKindPlaylist => 'Afspeellijst';

  @override
  String get libraryKindRadio => 'Radio';

  @override
  String get libraryKindPodcast => 'Podcast';

  @override
  String get libraryKindEpisode => 'Aflevering';

  @override
  String get libraryKindAudiobook => 'Luisterboek';

  @override
  String get libraryOneTrack => '1 nummer';

  @override
  String libraryTrackCount(String count) {
    return '$count nummers';
  }

  @override
  String libraryMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String libraryHoursMinutes(String hours, String minutes) {
    return '$hours u $minutes min';
  }

  @override
  String get librarySearchHint => 'Artiesten, albums, nummers';

  @override
  String get librarySearchClear => 'Zoekopdracht wissen';

  @override
  String get librarySearchAll => 'Alles';

  @override
  String get librarySearchPrompt =>
      'Zoek naar artiesten, albums, nummers en meer.';

  @override
  String get libraryEmpty => 'Hier staat nog niets.';

  @override
  String get libraryLoadFailed => 'Kon niet worden geladen.';

  @override
  String get libraryNoSource =>
      'Stel Music Assistant, Home Assistant of een Sonos-luidspreker in om muziek te bladeren.';

  @override
  String get libraryHaPickSpeaker =>
      'Kies een luidspreker om de media te zien die hij kan afspelen.';

  @override
  String get libraryChooseSpeaker => 'Kies een luidspreker';

  @override
  String get libraryPickSpeakerHint =>
      'Kies de luidspreker om op af te spelen.';

  @override
  String get libraryPlay => 'Afspelen';

  @override
  String get libraryOpenNowPlaying => 'Nu aan het afspelen openen';

  @override
  String get libraryNothingPlaying => 'Er wordt niets afgespeeld';

  @override
  String get libraryMore => 'Meer opties';

  @override
  String get libraryPlayNow => 'Nu afspelen';

  @override
  String get libraryPlayNext => 'Hierna afspelen';

  @override
  String get libraryAddToQueue => 'Aan wachtrij toevoegen';

  @override
  String get libraryStartRadio => 'Radio starten';

  @override
  String get libraryGoToArtist => 'Naar artiest';

  @override
  String get libraryAddFavorite => 'Aan favorieten toevoegen';

  @override
  String get libraryRemoveFavorite => 'Uit favorieten verwijderen';

  @override
  String get libraryAddedFavorite => 'Aan favorieten toegevoegd';

  @override
  String get libraryRemovedFavorite => 'Uit favorieten verwijderd';

  @override
  String get libraryFavoriteFailed => 'Favorieten konden niet worden gewijzigd';

  @override
  String get libraryPlaysNext => 'Wordt hierna afgespeeld';

  @override
  String get libraryAddedToQueue => 'Aan wachtrij toegevoegd';

  @override
  String get libraryView => 'Bekijken';

  @override
  String get libraryPlayFailed => 'Kon niet worden afgespeeld';

  @override
  String get librarySpeakers => 'Luidsprekers';

  @override
  String get libraryPlayingOn => 'Speelt af op';

  @override
  String get libraryOtherSpeakers => 'Andere luidsprekers';

  @override
  String get libraryNoOtherSpeakers => 'Geen andere luidsprekers.';

  @override
  String get libraryThisDevice => 'Dit apparaat';

  @override
  String get libraryUnavailable => 'Niet beschikbaar';

  @override
  String get libraryGroup => 'Groeperen';

  @override
  String get libraryGroupAll => 'Groep';

  @override
  String libraryGroupWith(String speaker) {
    return 'Groeperen met $speaker';
  }

  @override
  String get libraryGroupHint =>
      'Gegroepeerde luidsprekers spelen dezelfde muziek synchroon af.';

  @override
  String libraryGroupName(String speaker, String count) {
    return '$speaker + $count';
  }

  @override
  String get settingKioskAllowMusicLibraryDescription =>
      'Muziek bladeren en afspelen op een luidspreker.';

  @override
  String get libraryPageHint =>
      'Muziek bladeren en afspelen op een luidspreker';

  @override
  String get settingLibrarySourceDescription =>
      'Waar de bibliotheek muziek vandaan haalt. Automatisch begint met de bron van de luidspreker die Nu aan het afspelen volgt.';

  @override
  String get settingLibraryNowPlayingButtonTitle =>
      'Tonen in Nu aan het afspelen';

  @override
  String get settingLibraryNowPlayingButtonDescription =>
      'Voeg een knop Muziekbibliotheek toe naast de sluitknop.';

  @override
  String get libraryQueueTitle => 'Wachtrij';

  @override
  String get libraryCloseQueue => 'Wachtrij sluiten';

  @override
  String get libraryClear => 'Wissen';

  @override
  String get libraryClearQueueTitle => 'Wachtrij wissen?';

  @override
  String get libraryClearQueueMessage =>
      'De muziek stopt en alle nummers verdwijnen uit de wachtrij.';

  @override
  String get libraryRemoveFromQueue => 'Uit wachtrij verwijderen';

  @override
  String get libraryReorder => 'Sleep om de volgorde te wijzigen';

  @override
  String get libraryQueueFailed => 'De wachtrij kon niet worden gewijzigd';

  @override
  String get libraryVoiceSection => 'Spraakbediening';

  @override
  String get libraryVoiceManage => 'Muziek beheren met Voice Satellite';

  @override
  String get libraryVoiceHint =>
      'Vereist de muziekblauwdruk van Kiosk Satellite en een LLM-gespreksagent in Home Assistant.';

  @override
  String get musicPickerTitle => 'Muziek kiezen';

  @override
  String get musicPickerSearchHint => 'Muziek zoeken';

  @override
  String get musicPickerMusicFrom => 'Muziek van';

  @override
  String get musicPickerPlaysOn => 'Speelt af op';

  @override
  String musicPickerSourceLabel(String name) {
    return 'Bron: $name';
  }

  @override
  String musicPickerSpeakerLabel(String name) {
    return 'Speelt af op: $name';
  }

  @override
  String get musicPickerRandom => 'Willekeurig';

  @override
  String get musicPickerRandomHint => 'Elke keer een nieuwe keuze';

  @override
  String get musicPickerAnyTrack => 'Elk nummer';

  @override
  String get musicPickerAnyFavorite => 'Elke favoriet';

  @override
  String get musicPickerAnyPlaylist => 'Elke afspeellijst';

  @override
  String get musicPickerAnyAlbum => 'Elk album';

  @override
  String get musicPickerAnyStation => 'Elk radiostation';

  @override
  String get musicPickerRandomEach => 'Elke keer een andere';

  @override
  String get musicPickerWholeAlbum => 'Heel album';

  @override
  String get musicPickerWholePlaylist => 'Hele afspeellijst';

  @override
  String musicPickerWholeArtist(String name) {
    return 'Alles van $name';
  }

  @override
  String get musicPickerWholeFolder => 'Hele map';

  @override
  String get musicPickerAllTracks => 'Alle nummers';

  @override
  String get musicPickerShuffle => 'Willekeurige volgorde';

  @override
  String get musicPickerPreview => 'Voorbeluisteren';

  @override
  String get musicPickerStopPreview => 'Voorbeluisteren stoppen';

  @override
  String get musicPickerPreviewFailed => 'De muziek kon niet worden afgespeeld';

  @override
  String get musicPickerNothing => 'Niets gekozen';

  @override
  String get musicPickerNothingHint =>
      'Kies een nummer, album, afspeellijst, artiest of station';

  @override
  String get musicPickerFollowsNote =>
      'Speelt nu schakelt naar deze speaker zolang de muziek speelt.';

  @override
  String get musicPickerSonosNote =>
      'Sonos-muziek speelt alleen op Sonos-speakers.';

  @override
  String get musicPickerNoSpeakers => 'Geen speakers om op af te spelen';

  @override
  String musicPickerOpen(String title) {
    return '$title openen';
  }

  @override
  String get musicPickerKindFolder => 'Map';

  @override
  String get offlineDashboard => 'Dashboard is niet beschikbaar';

  @override
  String get offlineNetwork => 'Geen netwerkverbinding';

  @override
  String get offlinePageHelp => 'De pagina kon niet geladen worden.';

  @override
  String get offlineNetworkHelp =>
      'Het dashboard wordt hersteld zodra de netwerkverbinding terug is.';

  @override
  String get offlineLost => 'Netwerkverbinding verloren';

  @override
  String get offlineRestored => 'Netwerkverbinding hersteld';

  @override
  String get mediaPlay => 'Afspelen';

  @override
  String get mediaPause => 'Pauze';

  @override
  String get mediaPreviousTrack => 'Vorig nummer';

  @override
  String get mediaNextTrack => 'Volgend nummer';

  @override
  String get mediaPlaying => 'Wordt afgespeeld';

  @override
  String get mediaPaused => 'Gepauzeerd';

  @override
  String get mediaIdle => 'Inactief';

  @override
  String get mediaStatusUnavailable => 'Status niet beschikbaar';

  @override
  String get mediaUnknownTrack => 'Onbekend nummer';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => 'Volume tonen';

  @override
  String get mediaHideVolume => 'Volume verbergen';

  @override
  String get mediaMute => 'Dempen';

  @override
  String get mediaUnmute => 'Dempen opheffen';

  @override
  String get mediaFavoriteAdd => 'Aan favorieten toevoegen';

  @override
  String get mediaFavoriteRemove => 'Uit favorieten verwijderen';

  @override
  String get mediaShuffleOn => 'Willekeurige volgorde inschakelen';

  @override
  String get mediaShuffleOff => 'Willekeurige volgorde uitschakelen';

  @override
  String get mediaRepeatAll => 'Alles herhalen';

  @override
  String get mediaRepeatOne => 'Eén nummer herhalen';

  @override
  String get mediaRepeatOff => 'Herhalen uitschakelen';

  @override
  String get mediaShowLyrics => 'Songtekst tonen';

  @override
  String get mediaHideLyrics => 'Songtekst verbergen';

  @override
  String get mediaShowQueue => 'Wachtrij tonen';

  @override
  String get mediaHideQueue => 'Wachtrij verbergen';

  @override
  String get mediaVolume => 'Volume';

  @override
  String get mediaPlaybackPosition => 'Afspeelpositie';

  @override
  String get mediaShowNowPlaying => 'Speelt nu tonen';

  @override
  String get mediaShowFloatingPlayer => 'De zwevende speler tonen';

  @override
  String get mediaOpenMusicAssistant => 'Music Assistant openen';

  @override
  String get mediaCannotControl =>
      'opdracht niet ondersteund of niet verzonden';

  @override
  String get mediaAudioHiRes => 'Hi-Res';

  @override
  String get mediaAudioCdQuality => 'Cd-kwaliteit';

  @override
  String get mediaAudioLossy => 'Met verlies';

  @override
  String mediaAudioBitDepth(String bits) {
    return '$bits-bit';
  }

  @override
  String mediaAudioSampleRate(String rate) {
    return '$rate kHz';
  }

  @override
  String mediaAudioBitRate(String rate) {
    return '$rate kbps';
  }

  @override
  String get mediaNothingQueued => 'Niets in de wachtrij';

  @override
  String get mediaChapters => 'Hoofdstukken';

  @override
  String get mediaNowPlaying => 'Speelt nu';

  @override
  String get mediaUpNext => 'Hierna';

  @override
  String mediaUnnamedChapter(String number) {
    return 'Hoofdstuk $number';
  }

  @override
  String get mediaGroupLead => 'Leidt de groep';

  @override
  String get mediaGroupReadFailed => 'De groep kon niet worden gelezen.';

  @override
  String get mediaGroupEmpty =>
      'Geen andere spelers beschikbaar om te groeperen.';

  @override
  String get mediaSpeakerSelection => 'Luidsprekerkeuze';

  @override
  String pluginCloseWindow(String name) {
    return '$name sluiten';
  }

  @override
  String get pluginScanTitle => 'Scan een code';

  @override
  String get pluginScanHelp => 'Houd de code binnen het kader.';

  @override
  String pluginScanSource(String name) {
    return 'Aangevraagd door $name';
  }

  @override
  String get pluginActions => 'Acties';

  @override
  String get pluginKioskDrawer => 'Kioskmenu';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      'Als je een gebaar wilt toewijzen, open je Gebaren en kies je \'Een plug-inactie uitvoeren\'.';

  @override
  String get pluginShowInKioskDrawer => 'Weergeven in kioskmenu';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      'Ook beschikbaar wanneer het apparaat is vergrendeld, mits het kioskmenu is toegestaan.';

  @override
  String get pluginExposeToHomeAssistant =>
      'Beschikbaar stellen aan Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      'Voegt een knop toe aan het ESPHome-apparaat van de kiosk. Hiervoor zijn ESPHome en systeemeigen entiteiten vereist.';

  @override
  String pluginConfigureName(String name) {
    return '$name instellen';
  }

  @override
  String get pluginThePluginDidNotAnswerInTime =>
      'De plug-in heeft niet op tijd geantwoord.';

  @override
  String get pluginNoChoicesYetRefreshToLookForThem =>
      'Nog geen keuzes. Vernieuw om ernaar te zoeken.';

  @override
  String get pluginThisChoiceIsNoLongerListed =>
      'Deze keuze staat niet meer in de lijst.';

  @override
  String get pluginPlugin => 'Plug-in';

  @override
  String get pluginEnablePlugins => 'Plug-ins inschakelen';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      'Plug-ins voegen extra functies aan Kiosk Satellite toe die door de community zijn ontwikkeld.';

  @override
  String get pluginInstalledPlugins => 'Geïnstalleerde plug-ins';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      'Er zijn geen plug-ins geïnstalleerd. Voeg een repository toe om te beginnen.';

  @override
  String get pluginDeveloperTools => 'Ontwikkelaarstools';

  @override
  String get pluginCreateAPlugin => 'Een plug-in maken';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      'Leer met de Hello World-sjabloon en documentatie hoe je plug-ins maakt.';

  @override
  String get pluginThisPluginIsNoLongerInstalled =>
      'Deze plug-in is niet meer geïnstalleerd.';

  @override
  String get pluginEnablePluginsToRunThisPlugin =>
      'Schakel plug-ins in om deze plug-in uit te voeren.';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      'Schakel deze plug-in in via de bijbehorende rij om hem uit te voeren.';

  @override
  String pluginUninstallName(String name) {
    return '$name verwijderen?';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return '$name verwijderen';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return 'Controleren op updates voor $name';
  }

  @override
  String pluginAboutName(String name) {
    return 'Over $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings =>
      'Hiermee worden de plug-in en de bijbehorende instellingen verwijderd.';

  @override
  String get pluginUninstall => 'Verwijderen';

  @override
  String get pluginNoUpdatesAvailable => 'Geen updates beschikbaar.';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      'Deze plug-in is vanuit een ZIP-bestand geïnstalleerd en heeft geen README uit een repository.';

  @override
  String get pluginImageUnavailable => 'Afbeelding niet beschikbaar';

  @override
  String get pluginCouldNotOpenThisLink => 'Kon deze link niet openen.';

  @override
  String pluginEnableName(String name) {
    return '$name inschakelen';
  }

  @override
  String get pluginShowPassword => 'Wachtwoord tonen';

  @override
  String get pluginHidePassword => 'Wachtwoord verbergen';

  @override
  String get pluginUntitled => 'Naamloos';

  @override
  String get pluginSearchIcons => 'Pictogrammen zoeken';

  @override
  String get pluginChooseIcon => 'Kies een pictogram';

  @override
  String get pluginSearchCameraViews => 'Cameraweergaven zoeken';

  @override
  String get pluginChooseCameraView => 'Kies een cameraweergave';

  @override
  String get pluginCameraViewGone =>
      'Deze cameraweergave bestaat niet meer. Kies een andere.';

  @override
  String get pluginDragToReorder => 'Sleep om de volgorde te wijzigen';

  @override
  String get pluginDone => 'Klaar';

  @override
  String get pluginRequired => 'Verplicht';

  @override
  String get pluginAddPlugin => 'Plug-in toevoegen';

  @override
  String get pluginInstallFromAGithubRepository =>
      'Installeren vanuit een GitHub-repository';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd =>
      'Controleer voordat je de plug-in installeert of je de auteur en de code vertrouwt.';

  @override
  String get pluginPreview => 'Voorbeeldweergave';

  @override
  String get pluginInstalledVersion => 'Geïnstalleerde versie';

  @override
  String get pluginAuthor => 'Auteur';

  @override
  String get pluginLicense => 'Licentie';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      'Plug-ins voeren code uit binnen Kiosk Satellite en hebben toegang tot appgegevens en verleende Android-toestemmingen. Een defecte of schadelijke plug-in kan privégegevens openbaar maken of voorkomen dat de app werkt. Installeer alleen plug-ins van auteurs die je vertrouwt.';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      'Nieuwe plug-ins zijn aanvankelijk uitgeschakeld. Bij updates blijft de ingeschakelde status behouden en worden actieve plug-ins automatisch opnieuw gestart.';

  @override
  String get pluginTrustAndUpdate => 'Vertrouwen en bijwerken';

  @override
  String get pluginTrustAndInstall => 'Vertrouwen en installeren';

  @override
  String get pluginInstallFromZip => 'Installeren vanuit ZIP';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild =>
      'Alleen voor ontwikkelaars: een lokale build testen';

  @override
  String get pluginPluginZip => 'ZIP-bestand van plug-in';

  @override
  String get pluginPluginZipMustBeAtMost4Mb =>
      'Het ZIP-bestand van de plug-in mag maximaal 4 MB groot zijn';

  @override
  String get pluginCouldNotReadTheSelectedZip =>
      'Kon de geselecteerde ZIP niet lezen';

  @override
  String get pluginBrowsePlugins => 'Plug-ins bekijken';

  @override
  String get pluginFindPluginsMadeByTheCommunity =>
      'Vind plug-ins die de community heeft gemaakt';

  @override
  String get pluginSearchPlugins => 'Plug-ins zoeken';

  @override
  String get pluginUpdate => 'Bijwerken';

  @override
  String get pluginInstalled => 'Geïnstalleerd';

  @override
  String pluginNeedsAppVersion(String version) {
    return 'Vereist Kiosk Satellite $version of nieuwer';
  }

  @override
  String get pluginStars => 'Sterren';

  @override
  String get pluginDownloads => 'Downloads';

  @override
  String get pluginActiveInstalls => 'Actieve installaties';

  @override
  String get pluginNoPluginsMatchYourSearch =>
      'Geen plug-ins gevonden voor je zoekopdracht.';

  @override
  String get pluginCommunityPluginsHasNoPluginsYet =>
      'Communityplug-ins heeft nog geen plug-ins.';

  @override
  String get pluginSubmitYourPlugin => 'Je plug-in indienen';

  @override
  String get pluginListYourPluginInCommunityPlugins =>
      'Zet je plug-in in Communityplug-ins.';

  @override
  String get pluginCouldNotReachCommunityPlugins =>
      'Kan Communityplug-ins niet bereiken. Controleer de internetverbinding.';

  @override
  String get pluginCouldNotLoadCommunityPlugins =>
      'Kan Communityplug-ins niet laden. Probeer het later opnieuw.';

  @override
  String get pluginTurnOn => 'Inschakelen';

  @override
  String get pluginTurnOnEnablePluginsToInstall =>
      'Schakel ‘Plug-ins inschakelen’ in om deze plug-in te installeren.';

  @override
  String get pluginPreviousPage => 'Vorige pagina';

  @override
  String get pluginNextPage => 'Volgende pagina';

  @override
  String pluginPageOfPages(String page, String pages) {
    return 'Pagina $page van $pages';
  }

  @override
  String get pluginSortBy => 'Sorteren op';

  @override
  String get pluginSortMostStars => 'Meeste sterren';

  @override
  String get pluginSortRecentlyUpdated => 'Onlangs bijgewerkt';

  @override
  String get pluginSortNewest => 'Nieuwste';

  @override
  String get pluginSortName => 'Naam';

  @override
  String get pluginSortMostDownloads => 'Meeste downloads';

  @override
  String get pluginPluginsPerPage => 'Plug-ins per pagina';

  @override
  String pluginCountPerPage(String count) {
    return '$count per pagina';
  }

  @override
  String pluginByAuthor(String author) {
    return 'door $author';
  }

  @override
  String get pluginListedChip => 'Staat in Communityplug-ins';

  @override
  String get pluginNotListedChip => 'Staat niet in Communityplug-ins';

  @override
  String get pluginCharts => 'Grafieken';

  @override
  String get pluginReadings => 'Metingen';

  @override
  String get pluginWaitingForSamples => 'Wachten op meetwaarden';

  @override
  String get pluginLatest => 'Nieuwste';

  @override
  String get pluginSelected => 'Geselecteerd';

  @override
  String get pluginNoDataYet => 'Nog geen gegevens';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      'Tik of sleep om meetwaarden te bekijken. Dubbeltik om de nieuwste waarden te volgen.';

  @override
  String get pluginNoData => 'Geen gegevens';

  @override
  String get pluginOn => 'Aan';

  @override
  String get pluginEmpty => 'Leeg';

  @override
  String get pluginChartKeyboardHelp =>
      'Gebruik de pijltjestoetsen om meetwaarden te bekijken en End om naar de nieuwste waarde te gaan.';

  @override
  String get pluginErrorAssetPath => 'Ongeldig pad naar bronbestand';

  @override
  String get pluginErrorAssetMissing =>
      'Bronbestand ontbreekt of bevindt zich buiten het pakket';

  @override
  String get pluginErrorAssetSymlink =>
      'De map met bronbestanden mag geen symbolische koppeling zijn';

  @override
  String get pluginErrorAssetSymlinks =>
      'Mappen met bronbestanden mogen geen symbolische koppelingen zijn';

  @override
  String get pluginErrorAssetsIntegrity =>
      'De integriteitscontrole van de geïnstalleerde bronbestanden is mislukt';

  @override
  String get pluginErrorAssetIntegrity =>
      'De integriteitscontrole van het geïnstalleerde bronbestand is mislukt';

  @override
  String get pluginErrorManifestMismatch =>
      'Het pakketmanifest komt niet overeen met het beoordeelde releasemanifest';

  @override
  String get pluginErrorStagingExists =>
      'De tijdelijke installatiemap bestaat al';

  @override
  String get pluginErrorCreateDirectory =>
      'De plug-inmap kan niet worden aangemaakt';

  @override
  String get pluginErrorFileCount =>
      'Maximaal 512 pakketbestanden worden ondersteund';

  @override
  String get pluginErrorProtectFile =>
      'Het plug-inbestand kan niet worden beveiligd';

  @override
  String get pluginErrorExpandedSize =>
      'De uitgepakte plug-in is groter dan 4 MB';

  @override
  String get pluginErrorManifestSize => 'Het manifest is groter dan 32 KB';

  @override
  String get pluginErrorRequiredFiles =>
      'Het pakket moet kiosk-satellite-plugin.json, plugin.jar en LICENSE bevatten';

  @override
  String get pluginErrorNativeCapability =>
      'Systeemeigen bibliotheken vereisen de bijbehorende capaciteit';

  @override
  String get pluginErrorNativeElf => 'Ongeldige systeemeigen ELF-bibliotheek';

  @override
  String get pluginErrorNativeAbi =>
      'De ABI van de systeemeigen bibliotheek komt niet overeen met de map';

  @override
  String get pluginErrorDexOnly =>
      'plugin.jar mag alleen DEX-bestanden bevatten';

  @override
  String get pluginErrorDexHeader => 'Ongeldige DEX-header';

  @override
  String get pluginErrorDexSize =>
      'Het uitgepakte DEX-bestand is groter dan 4 MB';

  @override
  String get pluginErrorDexEmpty => 'Leeg DEX-bestand';

  @override
  String get pluginErrorDexMissing => 'plugin.jar bevat geen classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'Onverwacht of dubbel item in ZIP-bestand: $name';
  }

  @override
  String get pluginErrorRepositoryMismatch =>
      'De release in de repository hoort bij een andere plug-in.';

  @override
  String get pluginErrorRepositoryUrl =>
      'Voer een openbare repository-URL in, bijvoorbeeld https://github.com/owner/repository';

  @override
  String get pluginErrorRepositoryPath =>
      'Gebruik de repository-URL zonder pad naar een bestand of branch';

  @override
  String get pluginErrorDownloadOutsideGithub =>
      'De download van de plug-in is doorgestuurd naar een locatie buiten GitHub';

  @override
  String get pluginErrorInvalidRedirect => 'Ongeldige GitHub-redirect';

  @override
  String get pluginErrorRepositoryNotFound =>
      'De openbare repository, stabiele release, kiosk-satellite-plugin.json, README.md of het releasebestand is niet gevonden.';

  @override
  String get pluginErrorGithubLimited =>
      'GitHub heeft het verzoek geweigerd of de verzoeklimiet is bereikt. Probeer het later opnieuw.';

  @override
  String get pluginErrorRepositorySize =>
      'Het repositorybestand overschrijdt de maximale grootte';

  @override
  String get pluginErrorTooManyRedirects => 'Te veel omleidingen door GitHub';

  @override
  String get pluginErrorStableRelease =>
      'GitHub gaf geen gepubliceerde stabiele release terug';

  @override
  String get pluginErrorReleaseTag => 'Ongeldige release-tag';

  @override
  String get pluginErrorManifestFile =>
      'Ongeldig kiosk-satellite-plugin.json-manifest';

  @override
  String get pluginErrorIdVersion => 'Ongeldige plug-in-ID of versie';

  @override
  String get pluginErrorChecksumFilename =>
      'Ongeldige releasecontrolesom of pakketbestandsnaam';

  @override
  String get pluginErrorGithubDigest =>
      'De releasecontrolesom moet overeenkomen met de SHA-256-digest van het GitHub-releasebestand';

  @override
  String get pluginErrorTrustAuthor =>
      'Bevestig dat je de auteur van de plug-in vertrouwt';

  @override
  String get pluginErrorPreviewExpired =>
      'Deze voorbeeldweergave is verlopen. Bekijk de repository opnieuw voordat je de plug-in installeert.';

  @override
  String get pluginErrorReviewedChecksum =>
      'De SHA-256 van het pakket komt niet overeen met de beoordeelde release';

  @override
  String get pluginErrorNotInstalled => 'De plug-in is niet geïnstalleerd';

  @override
  String get pluginErrorUpdateZip =>
      'Deze plug-in is vanuit een ZIP-bestand geïnstalleerd. Gebruik \'Installeren vanuit ZIP\' om hem bij te werken.';

  @override
  String get pluginErrorAndroidOnly => 'Plug-ins zijn beschikbaar op Android.';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'GitHub-verzoek mislukt ($status)';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return 'De release moet precies één geüpload bestand met de naam $name bevatten';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return 'Het releasebestand $name moet door GitHub Actions zijn gepubliceerd. Handmatig geüploade bestanden worden niet ondersteund.';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return 'Het releasebestand $name overschrijdt de maximale grootte of is leeg';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return 'Ongeldige release-URL voor $name';
  }

  @override
  String get pluginErrorNativeLibrary =>
      'De plug-in bevat geen systeemeigen bibliotheek voor de ABI van dit apparaat';

  @override
  String get pluginErrorCallbackTimeout =>
      'Time-out bij een callback van de plug-in. Start Kiosk Satellite opnieuw als de plug-in een taak actief heeft achtergelaten.';

  @override
  String get pluginErrorEnableFirst => 'Schakel de plug-in eerst in';

  @override
  String get pluginErrorSaveState =>
      'De status van de plug-in kan niet worden opgeslagen';

  @override
  String get pluginErrorPackageHash =>
      'Ongeldige hash van het geïnstalleerde pakket';

  @override
  String get pluginErrorChecksum =>
      'De SHA-256 van het pakket komt niet overeen';

  @override
  String get pluginErrorDifferentRepository =>
      'Deze plug-in-ID hoort bij een andere repository. Verwijder de plug-in voordat je van bron wisselt.';

  @override
  String get pluginErrorRestartReplace =>
      'Deze plug-in is niet correct gestopt. Start Kiosk Satellite opnieuw voordat je hem vervangt.';

  @override
  String get pluginErrorAlreadyInstalled => 'Dit pakket is al geïnstalleerd';

  @override
  String get pluginErrorLoadedIntegrity =>
      'De integriteitscontrole van een eerder geladen pakket is mislukt. Start Kiosk Satellite opnieuw voordat je het pakket opnieuw installeert.';

  @override
  String get pluginErrorRemovePackage =>
      'Het ongebruikte pakket kan niet worden verwijderd';

  @override
  String get pluginErrorInstallPackage =>
      'Het plug-inpakket kan niet worden geïnstalleerd';

  @override
  String get pluginErrorUpdateCanceled =>
      'De update is geannuleerd omdat de plug-in niet correct is gestopt. Start Kiosk Satellite opnieuw en probeer het daarna nogmaals.';

  @override
  String get pluginErrorVersionRetained => 'De vorige versie is behouden.';

  @override
  String get pluginErrorRetainedDisabled =>
      'De vorige versie is behouden, maar is uitgeschakeld. Start Kiosk Satellite opnieuw voordat je deze versie inschakelt.';

  @override
  String get pluginErrorVersionRunning => 'De vorige versie draait weer.';

  @override
  String get pluginErrorEnablePlugins => 'Schakel plug-ins eerst in';

  @override
  String get pluginErrorRestartEnable =>
      'Deze plug-in is niet correct gestopt. Start Kiosk Satellite opnieuw voordat je hem inschakelt.';

  @override
  String get pluginErrorInstalledIntegrity =>
      'De integriteitscontrole van de geïnstalleerde plug-in is mislukt. Installeer hem opnieuw.';

  @override
  String get pluginErrorAndroidOld => 'De Android-versie is te oud';

  @override
  String get pluginErrorNeedsScreen => 'Deze plugin heeft een scherm nodig';

  @override
  String get pluginErrorNativeIntegrity =>
      'De integriteitscontrole van de geïnstalleerde systeemeigen bibliotheken is mislukt';

  @override
  String get pluginErrorNativeFileIntegrity =>
      'De integriteitscontrole van de geïnstalleerde systeemeigen bibliotheek is mislukt';

  @override
  String pluginErrorReadInstalled(String error) {
    return 'De geïnstalleerde plug-in kan niet worden gelezen: $error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return 'De vorige versie kon niet opnieuw worden gestart: $error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return 'Update van plug-in mislukt: $error. $recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      'Shizuku 13 of hoger is vereist. Tik voor installatie-instructies.';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      'Start Shizuku op dit apparaat. Tik voor installatie-instructies.';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku verleent Kiosk Satellite shell- of roottoegang. Geïnstalleerde plug-ins worden binnen Kiosk Satellite uitgevoerd. Verleen daarom alleen toegang als je ze vertrouwt.';

  @override
  String get pluginSetUp => 'Instellen';

  @override
  String get pluginGrantAccess => 'Toegang verlenen';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      'Keur het toestemmingsverzoek op de kiosk goed.';

  @override
  String get pluginErrorInvalidId => 'Ongeldige plug-in-ID';

  @override
  String get pluginErrorInvalidVersion => 'Ongeldige versie';

  @override
  String get pluginErrorEntryClass => 'Ongeldige invoerklasse';

  @override
  String get pluginErrorManifestSchema => 'Niet-ondersteund manifestschema';

  @override
  String get pluginErrorSdkVersion =>
      'Deze plug-in vereist een andere SDK-versie';

  @override
  String get pluginErrorMinimumSdk =>
      'De minimale Android-SDK moet versie 24 of hoger zijn';

  @override
  String get pluginErrorCapability => 'Niet-ondersteunde plug-inmogelijkheid';

  @override
  String get pluginErrorTooManySettings => 'Te veel instellingen of opdrachten';

  @override
  String get pluginErrorSettingKey => 'Ongeldige of dubbele instellingssleutel';

  @override
  String get pluginErrorGroupsArray =>
      'Weergavegroepen moeten een array vormen';

  @override
  String get pluginErrorTooManyGroups => 'Te veel weergavegroepen';

  @override
  String get pluginErrorUniqueGroups =>
      'Weergavegroepen moeten naar unieke instellingengroepen verwijzen';

  @override
  String get pluginErrorGroupReferences => 'Te veel groepsverwijzingen';

  @override
  String get pluginErrorDuplicateReference =>
      'Ongeldige of dubbele groepsverwijzing';

  @override
  String get pluginErrorCommandId => 'Ongeldige of dubbele opdracht-ID';

  @override
  String get pluginErrorUnknownSetting => 'Onbekende plug-ininstelling';

  @override
  String get pluginErrorTextLength =>
      'Tekstinstellingen moeten maximaal 512 tekens zijn';

  @override
  String get pluginErrorEntityId =>
      'Er werd een Home Assistant-entiteit-ID verwacht';

  @override
  String get pluginErrorBoolean => 'Er werd een booleaanse instelling verwacht';

  @override
  String get pluginErrorColor => 'Er werd een hexadecimale RGB-kleur verwacht';

  @override
  String get pluginErrorNumber => 'Er werd een numerieke instelling verwacht';

  @override
  String get pluginErrorRange => 'Numerieke instelling valt buiten het bereik';

  @override
  String get pluginErrorStep =>
      'De numerieke instelling komt niet overeen met de stapgrootte';

  @override
  String get pluginErrorSelection => 'Ongeldige selectie-instelling';

  @override
  String get pluginErrorSelectionOption => 'Onbekende selectieoptie';

  @override
  String get pluginErrorSettingType => 'Niet ondersteund instellingstype';

  @override
  String get pluginErrorInvalidManifest => 'Ongeldig plug-inmanifest';

  @override
  String pluginErrorAndroidApi(String version) {
    return 'De plug-in vereist Android-API $version';
  }

  @override
  String pluginErrorAppVersion(String required, String current) {
    return 'De plug-in vereist Kiosk Satellite $required of nieuwer. Deze kiosk draait $current.';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return 'Ongeldige $field';
  }

  @override
  String get pluginErrorTooManyTriggers => 'Te veel triggers';

  @override
  String get pluginErrorTriggerId => 'Ongeldige of dubbele trigger-ID';

  @override
  String get pluginErrorListSetting => 'Ongeldige lijstinstelling';

  @override
  String get pluginErrorSettingCondition =>
      'Ongeldige voorwaarde voor instelling';

  @override
  String get pluginErrorIcon => 'Er werd een MDI-pictogramnaam verwacht';

  @override
  String get pluginErrorDashboard => 'Er werd een dashboardpad verwacht';

  @override
  String get pluginErrorCameraView => 'Er werd een cameraweergave-ID verwacht';

  @override
  String get pluginErrorListValue => 'Er werd een lijstinstelling verwacht';

  @override
  String get pluginErrorListCount =>
      'De lijst heeft te veel of te weinig items';

  @override
  String get pluginErrorRequiredField => 'Vul alle verplichte velden in';

  @override
  String get pluginErrorListSize =>
      'Lijstinstellingen mogen maximaal 32 KB groot zijn';

  @override
  String get remoteDisableTitle => 'Beheer op afstand uitschakelen?';

  @override
  String get remoteDisableHelp =>
      'WAARSCHUWING: je hebt daarna geen toegang meer tot deze pagina. Schakel beheer op afstand weer in op het apparaat of met de schakelaar Beheer op afstand in Home Assistant.';

  @override
  String get remoteDisableConfirm => 'Uitschakelen';

  @override
  String get remoteCopyHelp =>
      'Selecteer de sleutel en kopieer deze handmatig.';

  @override
  String get remoteSaveSettingFailed =>
      'Kon deze instelling niet opslaan. Probeer het nog eens.';

  @override
  String get remoteReconnecting => 'Opnieuw verbinden…';

  @override
  String remoteConnectionLost(String name) {
    return 'De verbinding met $name is verbroken. Deze pagina gaat automatisch verder zodra de verbinding is hersteld.';
  }

  @override
  String get remoteConnectionLostUnnamed =>
      'De verbinding met de kiosk is verbroken. Deze pagina gaat automatisch verder zodra de verbinding is hersteld.';

  @override
  String get remoteReloadPage => 'Pagina herladen';

  @override
  String get remoteUpdated => 'Kiosk Satellite is bijgewerkt';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return 'Op het apparaat draait nu versie $version$build. Deze pagina hoort bij de vorige versie en wordt over $seconds s opnieuw geladen.';
  }

  @override
  String remoteBuild(String build) {
    return ' (build $build)';
  }

  @override
  String get remoteReloadNow => 'Nu herladen';

  @override
  String get remoteLogin => 'Aanmelden';

  @override
  String get remoteInvalidPassword => 'Ongeldig wachtwoord';

  @override
  String get remoteLoginThrottled =>
      'Te veel pogingen. Wacht 5 minuten en probeer het opnieuw.';

  @override
  String get deviceScreenOffPermission =>
      'Voor het uitschakelen van het scherm is eenmalig toestemming nodig. De tablet toont nu het toestemmingsscherm voor apparaatbeheer. Verleen daar toestemming en probeer het opnieuw.';

  @override
  String get deviceAdminInactive =>
      'De toestemming voor apparaatbeheer is niet actief.';

  @override
  String get deviceRestartOverlay =>
      'Voor opnieuw starten is toestemming nodig om over andere apps weer te geven, anders kan de app zichzelf niet opnieuw openen. Het toestemmingsscherm wordt op het apparaat geopend. Verleen daar toestemming en probeer het opnieuw.';

  @override
  String get deviceRebootPermission =>
      'Om het apparaat opnieuw te starten, moet Kiosk Satellite als apparaateigenaar zijn ingesteld of moet er een Shizuku-verbinding met toestemming zijn.';

  @override
  String get deviceRestartAndroidOnly =>
      'Opnieuw starten is alleen beschikbaar op Android.';

  @override
  String get deviceRestartShizukuRefused =>
      'Shizuku heeft de herstart geweigerd';

  @override
  String deviceRestartFailed(String error) {
    return 'Opnieuw starten mislukt: $error';
  }

  @override
  String get overviewAttention => 'Heeft aandacht nodig';

  @override
  String get overviewUpdate => 'Bijwerken';

  @override
  String overviewInvitation(String name) {
    return '$name wil deze kiosk leiden';
  }

  @override
  String get overviewOutdatedOne => '1 volger draait een andere release';

  @override
  String overviewOutdatedMany(String count) {
    return '$count volgers draaien een andere release';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names. Synchronisatie wacht op versie $version.';
  }

  @override
  String get overviewThisRelease => 'deze release';

  @override
  String get overviewUpdateAvailable => 'Update beschikbaar';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version kan worden geïnstalleerd. Bevestig de installatie op het tabletscherm.';
  }

  @override
  String overviewInstallSilentHelp(String version) {
    return 'Kiosk Satellite $version is klaar om te installeren. Het wordt zonder bevestiging op het apparaat geïnstalleerd.';
  }

  @override
  String overviewInstallHeadlessHelp(String version) {
    return 'Kiosk Satellite $version is klaar om te installeren. Dit apparaat heeft geen scherm om dit te bevestigen. Maak Kiosk Satellite daarom apparaateigenaar, gebruik Shizuku of installeer het via adb.';
  }

  @override
  String get overviewHaSetup => 'Home Assistant is niet ingesteld';

  @override
  String get overviewHaSetupHelp =>
      'Sluit de kiosk aan op Home Assistant om een dashboard te laden.';

  @override
  String get overviewSetUp => 'Instellen';

  @override
  String get overviewHaNotValidated => 'Home Assistant niet gevalideerd';

  @override
  String get overviewHaNotValidatedHelp =>
      'De URL en het token zijn tijdens deze sessie nog niet op de verbinding gecontroleerd. De kiosk probeert het elke 30 seconden opnieuw.';

  @override
  String get overviewOpenSetup => 'Instellingen openen';

  @override
  String get overviewWakeStopped => 'Wekwoorddetectie gestopt';

  @override
  String get overviewWakeReleased => 'De engine is vrijgegeven.';

  @override
  String get overviewOpenVoice => 'Voice Satellite openen';

  @override
  String get overviewOpenService => 'Service openen';

  @override
  String overviewPermissionMissing(String permission) {
    return 'Toestemming ontbreekt: $permission';
  }

  @override
  String get overviewSystemUpdate => 'Systeemupdate beschikbaar';

  @override
  String overviewPluginUpdate(String name) {
    return 'Update voor $name beschikbaar';
  }

  @override
  String overviewPluginUpdateHelp(String version) {
    return 'Versie $version staat klaar om te controleren en te installeren.';
  }

  @override
  String overviewSystemImageUpdateHelp(String version) {
    return 'Versie $version van de systeemimage staat klaar om te installeren. Het apparaat start daarvoor twee keer opnieuw op.';
  }

  @override
  String get overviewQuick => 'Snelle bediening';

  @override
  String get overviewReload => 'Pagina herladen';

  @override
  String get overviewScreenOn => 'Scherm inschakelen';

  @override
  String get overviewScreenOff => 'Scherm uit';

  @override
  String get overviewSaverStart => 'Schermbeveiliging starten';

  @override
  String get overviewSaverStop => 'Schermbeveiliging sluiten';

  @override
  String get overviewCameraShow => 'Cameraweergave tonen';

  @override
  String get overviewCameraHide => 'Cameraweergave sluiten';

  @override
  String get overviewSaverPostpone => 'Schermbeveiliging uitstellen';

  @override
  String get overviewDnd => 'Niet storen';

  @override
  String get overviewDndOn => 'Niet storen inschakelen';

  @override
  String get overviewSnapshot => 'Snapshot maken';

  @override
  String get overviewCheckUpdates => 'Controleren op updates';

  @override
  String get overviewRestartApp => 'App opnieuw opstarten';

  @override
  String get overviewRestartDevice => 'Apparaat opnieuw starten';

  @override
  String get overviewExit => 'App afsluiten';

  @override
  String get overviewBrightness => 'Helderheid';

  @override
  String get overviewVolume => 'Hoofdvolume';

  @override
  String get overviewBrightnessGrant =>
      'De helderheidsregeling gebruikt een alternatief dat alleen voor de app geldt. Verleen de toestemming \'Systeeminstellingen wijzigen\' zodat de schuifregelaar de werkelijke schermhelderheid regelt.';

  @override
  String get overviewRestartQuestion =>
      'Apparaat opnieuw starten? Kiosk Satellite wordt na het opstarten weer gestart.';

  @override
  String get overviewRestart => 'Opnieuw starten';

  @override
  String get overviewNoSnapshot => 'Er is geen momentopname ontvangen.';

  @override
  String get overviewSnapshotTitle => 'Cameramomentopname';

  @override
  String get overviewUpdateCheckFailed =>
      'Updatecontrole mislukt. Kan het apparaat GitHub bereiken?';

  @override
  String get overviewLatest => 'Je gebruikt de nieuwste versie.';

  @override
  String overviewVersionAvailable(String version) {
    return 'Versie $version is beschikbaar';
  }

  @override
  String get overviewInstallAttention =>
      'Installeer deze via \'Aandacht vereist\'.';

  @override
  String get overviewNoViewsWithCameras =>
      'Nog geen enkele cameraweergave bevat camera\'s. Voeg eerst camera\'s toe aan een weergave bij Camera\'s.';

  @override
  String get overviewShowViewFailed => 'De weergave kon niet worden getoond';

  @override
  String get overviewAppVersion => 'App-versie';

  @override
  String get overviewNotSetup => 'Niet ingesteld';

  @override
  String get overviewNotValidated => 'Niet gevalideerd';

  @override
  String get overviewCheckingFilter => 'Filter wordt gecontroleerd...';

  @override
  String get overviewValidated => 'Gevalideerd';

  @override
  String get overviewFilterUnavailable => 'Filterstatus niet beschikbaar';

  @override
  String get overviewUnfiltered => 'Updates ongefilterd';

  @override
  String get overviewWatchingOne => 'Volgt 1 entiteit';

  @override
  String overviewWatchingMany(String count) {
    return 'Volgt $count entiteiten';
  }

  @override
  String overviewFilterDisabled(String count) {
    return 'Filteren uitgeschakeld. De weergave gebruikt $count entiteiten.';
  }

  @override
  String get overviewWakeOff => 'Wekwoorddetectie uit';

  @override
  String overviewListeningFor(String words) {
    return 'Luisteren naar $words';
  }

  @override
  String get overviewListening => 'Luisteren';

  @override
  String get overviewNotListening => 'Luistert niet';

  @override
  String get overviewEntitiesProxy => 'Entiteiten en BT-proxy';

  @override
  String get overviewEntitiesOnly => 'Uitsluitend entiteiten';

  @override
  String get overviewProxyOnly => 'Alleen BT-proxy';

  @override
  String get overviewWaitingHA => 'Wachten op Home Assistant';

  @override
  String get overviewNotRunning => 'Niet actief';

  @override
  String get overviewRunningOne => 'Actief, 1 functie';

  @override
  String overviewRunningMany(String count) {
    return 'Actief, $count functies';
  }

  @override
  String overviewDownloading(String version) {
    return 'Downloaden: $version';
  }

  @override
  String overviewNewVersion(String version) {
    return 'Nieuwe versie: $version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return 'Actueel: $version';
  }

  @override
  String get overviewCurrent => 'Up-to-date';

  @override
  String overviewPluginAttribution(String name) {
    return '$name-plugin';
  }

  @override
  String get overviewMuted => 'gedempt';

  @override
  String get overviewBrowser => 'browser';

  @override
  String get overviewWakeWaiting =>
      'Wachten op Voice Satellite. De engine en wekwoorden worden geconfigureerd door de integratie zodra dit apparaat zijn dashboard opent.';

  @override
  String get overviewWakeDisabled =>
      'Wekwoorddetectie staat uit. Schakel deze in om de modellen van Voice Satellite te gebruiken.';

  @override
  String get overviewMicBlocked =>
      'Microfoon geblokkeerd. Android zal er niet opnieuw om vragen. Sta de toestemming toe via de appinstellingen en probeer het opnieuw.';

  @override
  String get overviewMicDeclined =>
      'Microfoontoegang geweigerd. Wekwoorddetectie heeft deze nodig. Probeer het opnieuw om de toestemming nogmaals te laten vragen.';

  @override
  String get overviewMicLost =>
      'De microfoon werkt niet meer. Probeer het opnieuw of laad de pagina opnieuw.';

  @override
  String get overviewModelsUnavailable =>
      'Kon de modellen niet downloaden van Home Assistant. Probeer het opnieuw zodra het bereikbaar is.';

  @override
  String get overviewCrashed =>
      'De detector crashte herhaaldelijk op dit apparaat en is daarom gestopt. Voice Satellite luistert nu via de browser. Probeer het opnieuw of start de app opnieuw.';

  @override
  String get overviewWakeFailed =>
      'De wekwoordengine kon niet starten. Probeer het opnieuw of laad de pagina opnieuw.';

  @override
  String overviewNativeUnavailable(String engine) {
    return 'Geen systeemeigen uitvoerder voor $engine. Voice Satellite blijft wekwoorden via de browser detecteren.';
  }

  @override
  String get overviewNativeListening => 'Luistert via de systeemeigen engine';

  @override
  String get overviewSuspended =>
      'Gereed (opgeschort tijdens een spraaksessie)';

  @override
  String get overviewCpu => 'CPU';

  @override
  String get overviewMemory => 'RAM';

  @override
  String get overviewTemperature => 'Temp';

  @override
  String overviewMemoryFree(String amount) {
    return '$amount GB vrij';
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
  String get overviewShowingCustomPages => 'Toont eigen pagina\'s';

  @override
  String get overviewHeadlessMode => 'Modus zonder scherm';

  @override
  String get overviewNoScreenshot => 'Geen schermafdruk';

  @override
  String get overviewStill => 'Stilstaand beeld';

  @override
  String get overviewLive => 'Live';

  @override
  String get overviewFullSize => 'Volledige grootte';

  @override
  String get overviewLiveInterval => 'Live, elke 5 seconden';

  @override
  String overviewTaken(String age) {
    return 'Vastgelegd: $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return 'Cameraweergave: $name';
  }

  @override
  String get overviewCameraView => 'Cameraweergave';

  @override
  String get overviewScreenOffState => 'Scherm is uit';

  @override
  String get overviewGoView => 'Ga naar weergave';

  @override
  String get screensaverNoPhotos =>
      'Geen foto\'s geselecteerd. Kies wat in Instellingen.';

  @override
  String get screensaverNoFolder =>
      'Geen map geselecteerd. Kies er een in Instellingen.';

  @override
  String screensaverFolderEmpty(String folder) {
    return 'Geen foto\'s of video\'s in $folder';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return 'Kon $folder niet lezen. Is de mediatoestemming verleend?';
  }

  @override
  String get screensaverReadPhotosFailed => 'Kon foto\'s niet lezen.';

  @override
  String get screensaverImmichNotReady =>
      'Immich is niet verbonden. Valideren in Instellingen.';

  @override
  String get screensaverNoMediaMatch =>
      'Geen media komt overeen met de bron en filters.';

  @override
  String get screensaverNoMediaSource => 'Geen media in de geselecteerde bron.';

  @override
  String get screensaverImmichUnreachable =>
      'Kon de Immich-server niet bereiken.';

  @override
  String screensaverRetryNotice(String error) {
    return '$error Er wordt automatisch opnieuw geprobeerd.';
  }

  @override
  String get screensaverVideosTooLarge =>
      'Elke video in deze afspeellijst is te groot voor dit apparaat om af te spelen.';

  @override
  String get screensaverUrlNotSet =>
      'Geen afbeeldings-URL ingesteld. Voeg er een toe in Instellingen.';

  @override
  String get screensaverUrlLoadFailed => 'Kon de afbeelding niet laden.';

  @override
  String get settingKioskAllowAlarmsTitle => 'Alarmen';

  @override
  String get settingKioskAllowAlarmsDescription =>
      'Alarmen uit het kioskmenu instellen en beheren.';

  @override
  String get settingScreensaverClockAlarmTakeoverTitle =>
      'Alarmen op schermbeveiliging tonen';

  @override
  String get settingScreensaverClockAlarmTakeoverDescription =>
      'Als een alarm afgaat, wordt het in de stijl van deze schermbeveiliging getoond in plaats van op een apart scherm.';

  @override
  String get settingScreensaverWeatherAlarmTakeoverTitle =>
      'Alarmen op schermbeveiliging tonen';

  @override
  String get settingScreensaverWeatherAlarmTakeoverDescription =>
      'Als een alarm afgaat, wordt het in de stijl van deze schermbeveiliging getoond in plaats van op een apart scherm.';

  @override
  String get settingAlarmsVolumeTitle => 'Alarmvolume';

  @override
  String get settingAlarmsVolumeDescription =>
      'Het volume waarmee alarmen afgaan, los van het mediavolume.';

  @override
  String get settingAlarmsToneTitle => 'Alarmtoon';

  @override
  String get settingAlarmsToneDescription => 'Speelt af bij het alarmvolume.';

  @override
  String get settingAlarmsMusicTitle => 'Alarmmuziek';

  @override
  String get settingAlarmsMusicDescription =>
      'Speelt in plaats van de toon. Als de muziek niet kan spelen, klinkt de toon.';

  @override
  String get settingAlarmsSnoozeMinutesTitle => 'Sluimerduur';

  @override
  String get settingAlarmsSnoozeMinutesDescription =>
      'Hoelang een alarm wordt uitgesteld met Sluimeren.';

  @override
  String get settingAlarmsSilenceAfterMinutesTitle => 'Dempen na';

  @override
  String get settingAlarmsSilenceAfterMinutesDescription =>
      'Een alarm dat niet wordt gestopt, wordt na deze tijd automatisch stil.';

  @override
  String get settingAlarmsSunriseMinutesTitle => 'Duur van zonsopgang';

  @override
  String get settingAlarmsSunriseMinutesDescription =>
      'Hoelang het scherm vóór een zonsopgangsalarm nodig heeft om volledig helder te worden.';

  @override
  String get alarmsOption5Minutes => '5 minuten';

  @override
  String get alarmsOption10Minutes => '10 minuten';

  @override
  String get alarmsOption15Minutes => '15 minuten';

  @override
  String get alarmsOption20Minutes => '20 minuten';

  @override
  String get alarmsOption25Minutes => '25 minuten';

  @override
  String get alarmsOption30Minutes => '30 minuten';

  @override
  String get settingsMenuAlarms => 'Alarmen';

  @override
  String get settingsMenuAlarmsSummary =>
      'Alarmen, toon, sluimeren en zonsopgang';

  @override
  String get settingAlarmsEaseInTitle => 'Volume geleidelijk verhogen';

  @override
  String get settingAlarmsEaseInDescription =>
      'Begin zacht en verhoog het geluid geleidelijk tot het alarmvolume.';

  @override
  String get settingAlarmsEaseInSecondsTitle => 'Volume verhogen gedurende';

  @override
  String get settingAlarmsEaseInSecondsDescription =>
      'Hoelang een alarm nodig heeft om het volledige volume te bereiken.';

  @override
  String get settingAlarmsTtsEngineTitle => 'Tekst-naar-spraakengine';

  @override
  String get settingAlarmsTtsEngineDescription =>
      'De tekst-naar-spraakentiteit van Home Assistant die alarmen uitspreekt.';

  @override
  String get settingAlarmsTtsLanguageTitle => 'Taal';

  @override
  String get settingAlarmsTtsLanguageDescription =>
      'De taal waarin alarmen worden uitgesproken.';

  @override
  String get settingAlarmsTtsVoiceTitle => 'Stem';

  @override
  String get settingAlarmsTtsVoiceDescription =>
      'De stem waarmee alarmen worden uitgesproken.';

  @override
  String get settingLauncherEnabledTitle => 'Appstarter inschakelen';

  @override
  String get settingLauncherEnabledDescription =>
      'Open vanuit de kiosk een geselecteerde groep geïnstalleerde apps.';

  @override
  String get settingLauncherAppsDescription =>
      'De apps die de appstarter aanbiedt.';

  @override
  String get settingLauncherAutoReturnTitle => 'Automatisch terugkeren';

  @override
  String get settingLauncherAutoReturnDescription =>
      'Keer terug naar de kiosk wanneer de andere app enige tijd niet is aangeraakt.';

  @override
  String get settingLauncherAutoReturnSecondsTitle => 'Terugkeer na (seconden)';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      'Tijd zonder aanraking in de andere app voordat de kiosk terugkeert.';

  @override
  String get settingLauncherAutoReturnHoldTitle =>
      'Wachten tijdens afspelen en gesprekken';

  @override
  String get settingLauncherAutoReturnHoldDescription =>
      'Niet terugkeren tijdens video, muziek of gesprekken.';

  @override
  String get launcherOverlayHeld =>
      'Kiosk Satellite kan zichzelf weer naar de voorgrond brengen en aanrakingen in de andere app detecteren.';

  @override
  String get launcherOverlayMissing =>
      'Zonder deze toestemming kan de kiosk niet automatisch terugkeren en worden aanrakingen in de andere app niet gedetecteerd.';

  @override
  String get launcherOverlayRemote =>
      'Zonder deze toestemming kan de kiosk niet automatisch terugkeren en worden aanrakingen in de andere app niet gedetecteerd. Het toestemmingsscherm verschijnt op de tablet.';

  @override
  String get launcherBatteryMissing =>
      'Android kan Kiosk Satellite achter de andere app pauzeren. Een gepauzeerde timer kan de kiosk niet terugbrengen.';

  @override
  String get launcherBatteryRemote =>
      'Android kan Kiosk Satellite achter de andere app pauzeren. Een gepauzeerde timer kan de kiosk niet terugbrengen. Het toestemmingsvenster verschijnt op de tablet.';

  @override
  String get launcherNotificationAccessHeld =>
      'De kiosk keert niet terug zolang een andere app video of muziek afspeelt.';

  @override
  String get launcherNotificationAccessMissing =>
      'Zonder dit weet de kiosk niet wanneer er video of muziek speelt en keert hij toch terug.';

  @override
  String get launcherNotificationAccessRemote =>
      'Zonder dit weet de kiosk niet wanneer er video of muziek speelt en keert hij toch terug. Het toestemmingsscherm verschijnt op de tablet.';

  @override
  String get launcherPermissionsSearch =>
      'De toestemmingen die nodig zijn om automatisch terug te keren.';

  @override
  String get settingCalendarDefaultViewTitle => 'Standaardweergave';

  @override
  String get settingCalendarDefaultViewDescription =>
      'De weergave waarmee de agenda opent.';

  @override
  String get settingCalendarWeekStartTitle => 'Week begint op';

  @override
  String get settingCalendarWeekStartAppLanguageDescription =>
      'Volgt de taal van de app, tenzij ingesteld.';

  @override
  String get settingCalendarWeatherEntityTitle => 'Weer';

  @override
  String get settingCalendarWeatherEntityDescription =>
      'Voegt de weersverwachting aan elke dag toe.';

  @override
  String get settingCalendarAllowEditTitle =>
      'Afspraken toevoegen en bewerken toestaan';

  @override
  String get settingCalendarAllowEditDescription =>
      'Voegt Nieuwe afspraak en Bewerken toe aan de agenda.';

  @override
  String get settingCalendarAllowDeleteTitle =>
      'Afspraken verwijderen toestaan';

  @override
  String get settingCalendarAllowDeleteDescription =>
      'Voegt Verwijderen toe aan elke afspraak.';

  @override
  String get settingCalendarIdleCloseMinutesTitle => 'Sluiten bij inactiviteit';

  @override
  String get settingCalendarIdleCloseMinutesDescription =>
      'Keert na zo lang zonder aanraking terug naar het dashboard.';

  @override
  String get settingKioskAllowCalendarTitle => 'Agenda';

  @override
  String get settingKioskAllowCalendarDescription =>
      'Open de gezinsagenda vanuit het kioskmenu.';

  @override
  String get calendarWeekStartLocale => 'Volgens de taal';

  @override
  String get calendarWeekStartSunday => 'Zondag';

  @override
  String get calendarWeekStartMonday => 'Maandag';

  @override
  String get calendarWeekStartSaturday => 'Zaterdag';

  @override
  String get calendarIdleNever => 'Nooit';

  @override
  String get calendarIdle1Minute => '1 minuut';

  @override
  String get calendarIdle2Minutes => '2 minuten';

  @override
  String get settingsMenuCalendar => 'Agenda';

  @override
  String get settingsMenuCalendarSummary =>
      'Gezinsagenda\'s uit Home Assistant';

  @override
  String get fleetTheCalendarsHiddenWithTheirChips =>
      'de agenda\'s die met hun labels zijn verborgen';

  @override
  String get settingCameraEnabledTitle => 'Camera inschakelen';

  @override
  String get settingCameraEnabledDescription =>
      'Het gebruik van de camera verhoogt de CPU-belasting en warmteontwikkeling. Hierdoor kan de levensduur van de batterij en het apparaat afnemen.';

  @override
  String get settingCameraDeviceTitle => 'Camera';

  @override
  String get settingCameraDeviceDescription =>
      'De camera die moet worden gebruikt.';

  @override
  String get settingCameraSnapshotResolutionTitle =>
      'Resolutie van momentopnamen';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      'Een hogere resolutie is scherper, maar gebruikt meer CPU-capaciteit en bandbreedte.';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle =>
      'Momentopnamen bij detectie uitschakelen';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      'Voorkom automatische momentopnamen bij detectie. Bewegings-, gezichts-, aanwezigheids- en gebarendetectie blijven werken. Handmatige verzoeken en doorlopende momentopnamen kunnen nog steeds beelden vastleggen.';

  @override
  String get settingCameraSnapshotsTitle => 'Doorlopende momentopnamen';

  @override
  String get settingCameraSnapshotsDescription =>
      'Publiceer met een vast interval een nieuwe momentopname van de camera in Home Assistant.';

  @override
  String get settingCameraSnapshotIntervalTitle =>
      'Interval voor momentopnamen';

  @override
  String get settingCameraSnapshotIntervalDescription =>
      'Aantal seconden tussen momentopnamen.';

  @override
  String get cameraFront => 'Voorzijde';

  @override
  String get cameraBack => 'Achterzijde';

  @override
  String get cameraExternal => 'Extern';

  @override
  String get cameraOnlyCamera => 'De enige camera die dit apparaat heeft.';

  @override
  String get settingMotionSensorTitle => 'Bewegingssensor';

  @override
  String get settingMotionSensorDescription =>
      'Stel beweging beschikbaar als sensor in Home Assistant. WAARSCHUWING: hierdoor blijft de camera voortdurend actief, ook wanneer het scherm uitstaat.';

  @override
  String get settingMotionSensorOffDelayTitle => 'Weer vrij na';

  @override
  String get settingMotionSensorOffDelayDescription =>
      'Aantal seconden zonder beweging voordat de sensor weer vrij aangeeft.';

  @override
  String get settingMotionFpsTitle => 'Bewegingsframesnelheid';

  @override
  String get settingMotionFpsDescription =>
      'Aantal beelden per seconde dat de camera op beweging controleert. Een lagere waarde belast de CPU minder; 2 is voldoende om iemand te zien naderen.';

  @override
  String get settingMotionStartDelayTitle => 'Opstartvertraging';

  @override
  String get settingMotionStartDelayDescription =>
      'Negeer beweging gedurende deze tijd nadat de camera is gestart. Dit is bedoeld voor apparaten waarvan de camera bij het openen fysiek beweegt.';

  @override
  String get settingMotionSensitivityTitle => 'Bewegingsgevoeligheid';

  @override
  String get settingMotionSensitivityDescription =>
      'Een hogere waarde reageert op kleinere bewegingen. Bij 1 is een grote verandering in het beeld nodig; 100 reageert op de kleinste beweging.';

  @override
  String get cameraMotionPage => 'Bewegingssensor';

  @override
  String get cameraMotionHint =>
      'Home Assistant-bewegingssensor en gedeelde detectieinstellingen';

  @override
  String get cameraNoCamera => 'Geen camera gedetecteerd';

  @override
  String get cameraNoCameraHelp =>
      'Dit apparaat rapporteert geen bruikbare camera.';

  @override
  String get cameraCameraPermission => 'Toestemming voor camera ontbreekt';

  @override
  String get cameraCameraPermissionHelp =>
      'Zonder deze toestemming kan de camera niet worden gebruikt. Het toestemmingsvenster verschijnt op de tablet.';

  @override
  String get cameraGrantOnDevice => 'Toestaan op apparaat';

  @override
  String get cameraCameraBlocked =>
      'Geblokkeerd. Android vraagt niet opnieuw om toestemming. Sta cameratoegang toe via de app-instellingen.';

  @override
  String get cameraCameraNeeded =>
      'Zonder deze toestemming kan de camera niet worden gebruikt.';

  @override
  String get cameraAppSettings => 'App-instellingen';

  @override
  String get settingPersonSensorTitle => 'Persoonssensor inschakelen';

  @override
  String get settingPersonSensorDescription =>
      'Stel de persoonssensor van het apparaat beschikbaar aan Home Assistant als aanwezigheidssensor. Hiervoor is de onderstaande toestemming voor logtoegang vereist.';

  @override
  String get cameraPersonPage => 'Persoonssensor';

  @override
  String get cameraPersonHint =>
      'Aanwezigheidssensor in Home Assistant op basis van de persoonssensor van het apparaat';

  @override
  String get cameraLatest => 'Laatste momentopname';

  @override
  String get cameraNoSnapshot => 'Nog geen momentopname.';

  @override
  String get cameraImageAlt => 'Nieuwste momentopname van camera';

  @override
  String get cameraTakeSnapshot => 'Momentopname maken';

  @override
  String get cameraSnapshotFailed => 'Momentopname mislukt.';

  @override
  String cameraSnapshotError(String error) {
    return 'Momentopname mislukt: $error';
  }

  @override
  String get cameraCameraDisabled =>
      'De camera is uitgeschakeld in de camera-instellingen.';

  @override
  String get cameraSnapshotBusy => 'Er wordt al een momentopname gemaakt.';

  @override
  String get cameraPermissionDenied => 'Cameratoestemming is niet verleend.';

  @override
  String get cameraDetectionDisabled =>
      'Momentopnamen bij detectie zijn uitgeschakeld.';

  @override
  String get cameraNoImage => 'De camera gaf geen beeld terug.';

  @override
  String get cameraTimedOut => 'De camera heeft niet op tijd gereageerd.';

  @override
  String get cameraBackground =>
      'De camera is niet beschikbaar terwijl de app op de achtergrond staat.';

  @override
  String get cameraJustNow => 'zojuist';

  @override
  String cameraSecondsAgo(String count) {
    return '$count seconden geleden';
  }

  @override
  String get cameraMinuteAgo => '1 minuut geleden';

  @override
  String cameraMinutesAgo(String count) {
    return '$count minuten geleden';
  }

  @override
  String get cameraHourAgo => '1 uur geleden';

  @override
  String cameraHoursAgo(String count) {
    return '$count uur geleden';
  }

  @override
  String get cameraDayAgo => '1 dag geleden';

  @override
  String cameraDaysAgo(String count) {
    return '$count dagen geleden';
  }

  @override
  String get cameraStatusHeading => 'Streamstatus';

  @override
  String get cameraClientsHeading => 'Verbonden clients';

  @override
  String get cameraUnavailable => 'Niet beschikbaar';

  @override
  String get cameraStopped => 'Gestopt';

  @override
  String get cameraStreaming => 'Streaming';

  @override
  String get cameraIdle => 'Inactief';

  @override
  String get cameraConnected => 'Verbonden';

  @override
  String get cameraChecking => 'Controleren...';

  @override
  String get cameraCheckingStatus => 'Streamstatus controleren...';

  @override
  String get cameraStatusUnavailable => 'Streamstatus is niet beschikbaar.';

  @override
  String get cameraListenerStopped => 'Listener is gestopt.';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count verbonden kijker. Werkelijke videoresolutie: $resolution.';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return '$count verbonden kijkers. Werkelijke videoresolutie: $resolution.';
  }

  @override
  String get cameraReady =>
      'Klaar. De encoder start wanneer een kijker verbinding maakt.';

  @override
  String cameraFallback(String requested, String actual) {
    return '$requested aangevraagd, maar de camera levert $actual.';
  }

  @override
  String cameraAudioError(String error) {
    return 'Audio: $error';
  }

  @override
  String get cameraAudioPaused =>
      'Audio is gepauzeerd terwijl de browser de microfoon gebruikt.';

  @override
  String get cameraAudioStreaming => 'Microfoonaudio wordt gestreamd.';

  @override
  String get cameraAudioIdle => 'Microfoongeluid inactief.';

  @override
  String cameraDiscoveryError(String error) {
    return 'ONVIF-detectie: $error';
  }

  @override
  String get cameraOnvifUrl => 'ONVIF-URL';

  @override
  String get cameraStreamUrl => 'Stream-URL';

  @override
  String get cameraWaitingAddress => 'Wachten op een netwerkadres';

  @override
  String get cameraClientsUnavailable =>
      'Clientgegevens zijn niet beschikbaar.';

  @override
  String get cameraNoClients => 'Geen verbonden clients.';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · poort $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return 'Al $duration verbonden';
  }

  @override
  String cameraDurationSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String cameraDurationMinutes(String minutes, String seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String cameraDurationHours(String hours, String minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get cameraCredentialsMissing =>
      'Stel een gebruikersnaam en wachtwoord voor streaming in om verificatie in te schakelen.';

  @override
  String get cameraPortWaiting =>
      'Wachten tot de RTSP-poort wordt vrijgegeven.';

  @override
  String get cameraListenerFailed => 'Kon de RTSP-listener niet starten.';

  @override
  String get settingCameraRtspEnabledTitle => 'Camerastreaming inschakelen';

  @override
  String get settingCameraRtspEnabledDescription =>
      'Deel H.264-video met RTSP- of ONVIF-clients. Video wordt alleen gecodeerd terwijl er een kijker is verbonden. Hardwarecodering heeft de voorkeur, met software als terugvaloptie. Gebruikt de camera die in de camera-instellingen is geselecteerd.';

  @override
  String get settingCameraStreamingProtocolTitle => 'Streamingprotocol';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'Met ONVIF kunnen compatibele clients de camera vinden en verbinding maken met de stream.';

  @override
  String get settingCameraRtspPortTitle => 'Poort';

  @override
  String get settingCameraRtspPortDescription => 'RTSP-serverpoort.';

  @override
  String get settingCameraOnvifPortTitle => 'Poort';

  @override
  String get settingCameraOnvifPortDescription => 'ONVIF-serverpoort.';

  @override
  String get settingCameraRtspResolutionTitle => 'Resolutie';

  @override
  String get settingCameraRtspResolutionDescription =>
      'Ondersteunde streamresoluties voor de geselecteerde camera en encoder. De video volgt de schermstand van het apparaat.';

  @override
  String get settingCameraRtspAnalysisTitle =>
      'Bewegingsanalyse tijdens streaming';

  @override
  String get settingCameraRtspAnalysisDescription =>
      'Houd bewegingsdetectie, gezichtsdetectie en handgebaren beschikbaar terwijl er kijkers zijn verbonden. Uitschakelen kan hogere resoluties mogelijk maken. Momentopnamen gebruiken dan videoframes met de streamresolutie.';

  @override
  String get settingCameraRtspFpsTitle => 'Framesnelheid';

  @override
  String get settingCameraRtspFpsDescription =>
      'Gewenst aantal videobeelden per seconde. Bewegingsdetectie behoudt een eigen analysesnelheid. De werkelijke beeldsnelheid is afhankelijk van de camera.';

  @override
  String get settingCameraRtspBitrateTitle => 'Bitsnelheid';

  @override
  String get settingCameraRtspBitrateDescription =>
      'Gewenste videobitsnelheid. Een hogere waarde geeft meer detail, maar gebruikt meer netwerkbandbreedte.';

  @override
  String get settingCameraRtspAudioTitle => 'Microfoonaudio opnemen';

  @override
  String get settingCameraRtspAudioDescription =>
      'Voeg microfoonaudio toe aan de camerastream. Gebruikt de gedeelde microfooninstellingen. WAARSCHUWING: verhoogt het CPU-gebruik.';

  @override
  String get settingCameraRtspAuthTitle => 'Verificatie vereisen';

  @override
  String get settingCameraRtspAuthDescription =>
      'Vereis een gebruikersnaam en wachtwoord om de stream te bekijken. Verificatie zorgt niet voor versleuteling.';

  @override
  String get settingCameraRtspUsernameTitle => 'Gebruikersnaam';

  @override
  String get settingCameraRtspUsernameDescription =>
      'Gebruikersnaam voor streamingclients.';

  @override
  String get settingCameraRtspPasswordTitle => 'Wachtwoord';

  @override
  String get settingCameraRtspPasswordDescription =>
      'Stel een wachtwoord in om de beveiligde stream te starten.';

  @override
  String get cameraStreamingPage => 'RTSP- en ONVIF-streaming';

  @override
  String get cameraStreamingHint => 'De camera delen via RTSP of ONVIF';

  @override
  String get cameraPortError =>
      'Voer een heel poortnummer in van 1024 tot 65535.';

  @override
  String get cameraUsernameError =>
      'Gebruik 1 tot 64 tekens zonder spaties, aanhalingstekens, dubbele punten of backslashes.';

  @override
  String get cameraNoSizes => 'Geen ondersteunde resoluties beschikbaar';

  @override
  String get cameraNoSizesHelp =>
      'Geen ondersteunde resoluties beschikbaar. Controleer de cameraverbinding.';

  @override
  String get cameraResolutionSupport => 'Resolutieondersteuning';

  @override
  String get cameraCheckingSizes =>
      'Ondersteuning van camera en H.264-encoder controleren...';

  @override
  String get cameraSupportedSizes =>
      'Alleen resoluties die de camera en H.264-encoder met de huidige streaminginstellingen ondersteunen, worden getoond.';

  @override
  String cameraExtraSizes(String sizes) {
    return 'Zet bewegingsanalyse uit tijdens het streamen om ook $sizes te gebruiken.';
  }

  @override
  String get cameraAnalysisOff =>
      'Bewegingsdetectie, gezichtsdetectie en handgebaren worden gepauzeerd terwijl er kijkers zijn verbonden. Momentopnamen gebruiken videoframes met de streamresolutie.';

  @override
  String cameraRejectedSizes(String sizes) {
    return 'De encoder kan $sizes bij deze instellingen niet gebruiken.';
  }

  @override
  String cameraRejectedCount(String count) {
    return '$count cameraresoluties zijn uitgesloten omdat de encoder ze met deze instellingen niet kan gebruiken.';
  }

  @override
  String get cameraCaptureRejected =>
      'Andere cameraresoluties zijn niet beschikbaar met de huidige opnameconfiguratie.';

  @override
  String get cameraMotionEventsHeading => 'Bewegingsgebeurtenissen';

  @override
  String get settingCameraOnvifEventsTitle =>
      'Bewegingsgebeurtenissen versturen';

  @override
  String get settingCameraOnvifEventsDescription =>
      'Laat ONVIF-clients zoals NVR\'s weten wanneer er beweging wordt gedetecteerd.';

  @override
  String get settingCameraOnvifEventsSourceTitle => 'Bewegingsbron';

  @override
  String get settingCameraOnvifEventsSourceDescription =>
      'De sensor die de bewegingsgebeurtenissen verstuurt.';

  @override
  String get cameraOnvifEventsSourceCamera => 'Bewegingssensor van de camera';

  @override
  String get cameraOnvifEventsSourcePerson => 'Persoonssensor';

  @override
  String get cameraOnvifEventsSourceEntity => 'Home Assistant-sensor';

  @override
  String get cameraOnvifEventsMotionSensorOff =>
      'De bewegingssensor van de camera staat uit. Schakel deze in bij Camera > Bewegingssensor.';

  @override
  String get cameraOnvifEventsAnalysisOff =>
      'Bewegingsanalyse tijdens streaming staat uit, dus de camera kan geen beweging detecteren zolang er een kijker verbonden is.';

  @override
  String get cameraOnvifEventsPersonSensorOff =>
      'De persoonssensor staat uit. Schakel deze in bij Camera > Persoonssensor.';

  @override
  String get cameraOverlaysHeading => 'Beeldlagen';

  @override
  String get settingCameraRtspDateTimeTitle => 'Datum en tijd tonen';

  @override
  String get settingCameraRtspDateTimeDescription =>
      'Toon de datum en tijd van het apparaat linksboven in de video volgens de ingestelde datumnotatie en 12- of 24-uursweergave.';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => 'Zwarte achtergrond';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      'Plaats een zwarte achtergrond achter de datum en tijd om deze beter leesbaar te maken.';

  @override
  String get settingCameraRtspTlsTitle => 'Stream versleutelen';

  @override
  String get settingCameraRtspTlsDescription =>
      'Gebruik TLS om video en audio te versleutelen. Vereist een compatibele kijker.';

  @override
  String get cameraStreamsNameRequired => 'naam vereist';

  @override
  String get cameraStreamsBaseUrlRequired =>
      'geldige HTTP of HTTPS baseUrl vereist';

  @override
  String get cameraStreamsServerNotFound => 'server niet gevonden';

  @override
  String get cameraStreamsInvalidStreamList =>
      'Go2RTC heeft een ongeldige streamlijst geretourneerd';

  @override
  String get cameraStreamsKindRequired => 'kind moet go2rtc, whep of ha zijn';

  @override
  String get cameraStreamsProtocolRequired =>
      'preferredProtocol moet auto, webrtc, hls of mjpeg zijn';

  @override
  String get cameraStreamsServerRequired => 'geldig serverId vereist';

  @override
  String get cameraStreamsStreamRequired => 'streamName vereist';

  @override
  String get cameraStreamsEntityRequired =>
      'een camera.*-entiteits-ID is vereist';

  @override
  String get cameraStreamsWhepRequired => 'geldige WHEP URL vereist';

  @override
  String get cameraStreamsCameraNotFound => 'camera niet gevonden';

  @override
  String get cameraStreamsListRequired => 'cameraIds moet een lijst zijn';

  @override
  String get cameraStreamsViewCount =>
      'een weergave moet 1 tot 12 camera\'s bevatten';

  @override
  String get cameraStreamsRepeatedCamera =>
      'een camera kan slechts één keer per weergave verschijnen';

  @override
  String get cameraStreamsUnknownViewCamera =>
      'weergave bevat een onbekende camera';

  @override
  String get cameraStreamsUniqueViewName => 'weergavenaam moet uniek zijn';

  @override
  String get cameraStreamsGridRange => 'raster moet tussen 1 en 12 liggen';

  @override
  String get cameraStreamsGridTooSmall =>
      'het raster is kleiner dan het aantal camera\'s';

  @override
  String get cameraStreamsViewNotFound => 'weergave niet gevonden';

  @override
  String get cameraStreamsDefaultViewDelete =>
      'de standaardweergave kan niet worden verwijderd; in plaats daarvan leegmaken';

  @override
  String get cameraStreamsViewEmpty => 'weergave heeft geen camera\'s';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return 'kon gegevens van Home Assistant niet ophalen: $error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return 'kon geen verbinding maken met $server: $error';
  }

  @override
  String get cameraStreamsHaUnavailable =>
      'Home Assistant is niet geconfigureerd of onbereikbaar';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC gaf HTTP $status terug';
  }

  @override
  String get cameraStreamsImportHa => 'Camera\'s importeren van Home Assistant';

  @override
  String get cameraStreamsImportHaHelp =>
      'Voeg alle camera\'s van de verbonden Home Assistant-instantie toe en speel ze af via WebRTC, HLS of MJPEG. Bij opnieuw importeren worden nieuwe camera\'s toegevoegd.';

  @override
  String get cameraStreamsImportFailed => 'Importeren mislukt';

  @override
  String get cameraStreamsImportComplete => 'Importeren voltooid';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return '$added toegevoegd, $missing ontbreken.';
  }

  @override
  String get settingCameraAllowH265Title => 'H.265-streams toestaan';

  @override
  String get settingCameraAllowH265Description =>
      'Speel H.265-camerastreams ongewijzigd af. Een apparaat dat H.265 niet kan decoderen, toont in plaats daarvan een leeg beeld.';

  @override
  String get settingCameraPreferMseTitle => 'MSE verkiezen boven WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      'Stream Go2RTC-camera\'s bij voorkeur via MSE. Bedoeld voor apparaten die WebRTC niet kunnen afspelen; dit voegt één of twee seconden vertraging toe.';

  @override
  String get settingCameraPreferHlsTitle => 'HLS verkiezen boven WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      'Stream Home Assistant-camera\'s bij voorkeur via HLS. Bedoeld voor apparaten die WebRTC niet kunnen afspelen; dit voegt enkele seconden vertraging toe.';

  @override
  String get settingCameraSingleAudioTitle =>
      'Geluid afspelen voor een enkele camera';

  @override
  String get settingCameraSingleAudioDescription =>
      'Speel het geluid van de camera af als er maar één camera op het scherm staat. Rasters met meerdere camera\'s blijven stil.';

  @override
  String get settingCameraPinchZoomTitle =>
      'Knijpen om op één camera in te zoomen';

  @override
  String get settingCameraPinchZoomDescription =>
      'Zoom met twee vingers in wanneer er één camera in beeld is. Sleep om het beeld te verplaatsen en dubbeltik om de zoom te herstellen.';

  @override
  String get settingCameraAutoDismissSecondsTitle => 'Automatisch sluiten na';

  @override
  String get settingCameraAutoDismissSecondsDescription =>
      'Sluit een geopende cameraweergave automatisch. Bij 0 blijft deze geopend. Dit heeft geen invloed op de cameraschermbeveiliging.';

  @override
  String get cameraStreamsPlayback => 'Afspelen';

  @override
  String get cameraStreamsOff => 'Uit';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get cameraStreamsGridHelp =>
      'Rasters met meerdere camera\'s bevatten alleen video. Gebruik op minder krachtige apparaten Go2RTC-streams met een lagere resolutie en stel eventueel een afzonderlijke stream voor volledig scherm in.';

  @override
  String get cameraStreamsServers => 'Go2RTC-servers';

  @override
  String get cameraStreamsImportStreams => 'Streams importeren';

  @override
  String get cameraStreamsDeleteServer => 'Server verwijderen';

  @override
  String get cameraStreamsAddServer => 'Go2RTC-server toevoegen';

  @override
  String get cameraStreamsAddServerHelp =>
      'Maak verbinding met een server en importeer de streams.';

  @override
  String get cameraStreamsEditServer => 'Server bewerken';

  @override
  String get cameraStreamsName => 'Naam';

  @override
  String get cameraStreamsBaseUrl => 'Basis-URL';

  @override
  String get cameraStreamsUsername => 'Gebruikersnaam (optioneel)';

  @override
  String get cameraStreamsNewPassword =>
      'Nieuw wachtwoord (leeg laten om het huidige te behouden)';

  @override
  String get cameraStreamsPassword => 'Wachtwoord (optioneel)';

  @override
  String get cameraStreamsInvalidCertificate =>
      'Ongeldig TLS-certificaat toestaan';

  @override
  String get cameraStreamsSaveServerFailed => 'Kon de server niet opslaan';

  @override
  String get cameraStreamsDeleteServerHelp =>
      'De camera\'s worden uit elke weergave verwijderd.';

  @override
  String get cameraStreamsCameras => 'Camera\'s';

  @override
  String get cameraStreamsNoCameras => 'Geen camera\'s ingesteld';

  @override
  String get cameraStreamsNoCamerasHelp =>
      'Importeer camera\'s van Home Assistant of Go2RTC, of voeg er handmatig een toe.';

  @override
  String get cameraStreamsDeleteCamera => 'Camera verwijderen';

  @override
  String get cameraStreamsAddManually => 'Camera handmatig toevoegen';

  @override
  String get cameraStreamsAddManuallyHelp =>
      'Gebruik een Go2RTC-streamnaam, een WHEP-URL of een camera-entiteit van Home Assistant.';

  @override
  String get cameraStreamsUnknownCamera => 'Onbekende camera';

  @override
  String get cameraStreamsUnknownServer => 'Onbekende server';

  @override
  String get cameraStreamsMissing => ' (ontbreekt)';

  @override
  String get cameraStreamsAddCamera => 'Camera toevoegen';

  @override
  String get cameraStreamsEditCamera => 'Camera bewerken';

  @override
  String get cameraStreamsType => 'Type';

  @override
  String get cameraStreamsGo2RtcStream => 'Go2RTC-stream';

  @override
  String get cameraStreamsDirectWhep => 'Directe WHEP-URL';

  @override
  String get cameraStreamsHaCamera => 'Home Assistant-camera';

  @override
  String get cameraStreamsEntity => 'Camera-entiteit';

  @override
  String get cameraStreamsProtocol => 'Voorkeursprotocol';

  @override
  String get cameraStreamsAuto => 'Automatisch';

  @override
  String get cameraStreamsServer => 'Server';

  @override
  String get cameraStreamsStreamName => 'Streamnaam';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Go2RTC-streamnaam';

  @override
  String get cameraStreamsFullscreen =>
      'Stream voor volledig scherm (optioneel)';

  @override
  String get cameraStreamsWhep => 'WHEP-URL';

  @override
  String get cameraStreamsSaveCameraFailed => 'Kon de camera niet opslaan';

  @override
  String get cameraStreamsDeleteCameraHelp =>
      'De camera wordt uit elke weergave verwijderd.';

  @override
  String get cameraStreamsLoadFailed => 'Kon geen camera\'s laden.';

  @override
  String get cameraStreamsViews => 'Weergaven';

  @override
  String get cameraStreamsEmptyView => 'Nog geen camera\'s';

  @override
  String get cameraStreamsNamesShown => 'Namen zichtbaar';

  @override
  String get cameraStreamsNamesHidden => 'Namen verborgen';

  @override
  String get cameraStreamsShowView => 'Weergave tonen';

  @override
  String get cameraStreamsDeleteView => 'Weergave verwijderen';

  @override
  String get cameraStreamsCreateView => 'Cameraweergave aanmaken';

  @override
  String get cameraStreamsAddFirst => 'Voeg eerst een camera toe.';

  @override
  String get cameraStreamsChooseCameras =>
      'Kies en rangschik maximaal 12 camera\'s.';

  @override
  String get cameraStreamsShowFailed => 'Kon de weergave niet tonen';

  @override
  String get cameraStreamsShowFailedRemote => 'Kon weergave niet tonen';

  @override
  String get cameraStreamsEditView => 'Weergave bewerken';

  @override
  String get cameraStreamsViewId => 'Weergave-ID';

  @override
  String get cameraStreamsShowNames => 'Cameranamen tonen';

  @override
  String get cameraStreamsShowNamesHelp => 'Toon een label over elke camera.';

  @override
  String get cameraStreamsGrid => 'Raster';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count camera';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return '$count camera\'s';
  }

  @override
  String get cameraStreamsInView => 'In deze weergave';

  @override
  String get cameraStreamsAvailable => 'Beschikbaar';

  @override
  String cameraStreamsPosition(String position) {
    return 'Positie $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'Ontbreekt in Go2RTC';

  @override
  String get cameraStreamsSaveViewFailed => 'Kon de weergave niet opslaan';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return '$name verwijderen?';
  }

  @override
  String get cameraStreamsCannotUndo => 'Dit kan niet ongedaan worden gemaakt.';

  @override
  String get cameraStreamsShow => 'Tonen';

  @override
  String get cameraStreamsStop => 'Stoppen';

  @override
  String get settingAnalyticsBasicTitle => 'Basisanalyse';

  @override
  String get settingAnalyticsBasicDescription =>
      'Informatie over je apparaat, zoals het model, de Android-versie, appversie, schermgrootte en taal.';

  @override
  String get settingAnalyticsUsageTitle => 'Gebruik';

  @override
  String get settingAnalyticsUsageDescription =>
      'Informatie over de functies die je in Kiosk Satellite gebruikt.';

  @override
  String get settingAnalyticsDiagnosticsTitle => 'Diagnostiek';

  @override
  String get settingAnalyticsDiagnosticsDescription =>
      'Crashmeldingen delen wanneer zich onverwachte fouten voordoen.';

  @override
  String get deviceAnalyticsPage => 'Kiosk Satellite Analytics';

  @override
  String get deviceAnalyticsIntro =>
      'Deel geanonimiseerde informatie over je installatie om Kiosk Satellite te verbeteren en te bepalen welke apparaten en functies extra aandacht nodig hebben.';

  @override
  String get deviceAnalyticsLearn => 'Lees hoe we je gegevens verwerken';

  @override
  String get deviceAnalyticsLearnHelp =>
      'Welke gegevens Kiosk Satellite Analytics wel en nooit verzendt.';

  @override
  String get deviceExportConfig => 'Configuratie exporteren';

  @override
  String get deviceExportConfigHelp =>
      'Sla elke instelling en de lokale opslag van de pagina op in een bestand.';

  @override
  String get deviceExportConfigRemoteHelp =>
      'Download elke instelling en de lokale opslag van de pagina.';

  @override
  String get deviceImportConfig => 'Configuratie importeren';

  @override
  String get deviceImportConfigHelp =>
      'De instellingen van dit apparaat vervangen door een geëxporteerd bestand.';

  @override
  String get deviceExportFailed => 'Exporteren mislukt';

  @override
  String get deviceExported => 'Configuratie geëxporteerd';

  @override
  String get deviceImportFailed => 'Importeren mislukt';

  @override
  String get deviceInvalidJson => 'Dat bestand bevat geen geldige JSON.';

  @override
  String get deviceImportComplete => 'Importeren voltooid';

  @override
  String deviceAppliedSettings(String count) {
    return '$count instellingen toegepast.';
  }

  @override
  String deviceAppliedReload(String count) {
    return '$count instellingen toegepast. De pagina wordt mogelijk opnieuw geladen.';
  }

  @override
  String get deviceReplaceOriginal => 'Het oorspronkelijke apparaat vervangen';

  @override
  String get deviceReplaceQuestion =>
      'De instellingen van dit apparaat vervangen door de instellingen uit het bestand? De pagina wordt mogelijk opnieuw geladen.';

  @override
  String get deviceNewDevice => 'Instellen als nieuw apparaat';

  @override
  String get deviceReplaceIdentity =>
      'Behoudt de naam en ESPHome-identiteit uit de back-up. Het oorspronkelijke apparaat moet offline blijven.';

  @override
  String get deviceNewIdentity =>
      'Wijst een eigen naam en ESPHome-identiteit toe, zodat beide apparaten uniek zijn.';

  @override
  String get deviceRestoreStorage => 'Lokale opslag van WebView herstellen';

  @override
  String get deviceRestoreStorageHelp =>
      'Bevat de aangemelde Home Assistant-sessie en de selectie van de assist_satellite voor Voice Satellite. Twee apparaten mogen niet dezelfde satelliet delen.';

  @override
  String get deviceDownload => 'Download';

  @override
  String get deviceChooseFile => 'Bestand kiezen…';

  @override
  String get deviceImportFailedSentence => 'Importeren mislukt.';

  @override
  String deviceReplaceNamed(String name) {
    return 'Vervang \"$name\"';
  }

  @override
  String get settingDeviceNameTitle => 'Apparaatnaam';

  @override
  String get settingDeviceNameDescription =>
      'Herkenbare naam voor beheer op afstand en voor het apparaat dat in Home Assistant wordt gepubliceerd.';

  @override
  String get settingDeviceHostnameTitle => 'mDNS-naam';

  @override
  String get settingDeviceHostnameDescription =>
      'Gebruik deze naam en de ingestelde poort om beheer op afstand via het lokale netwerk te openen. Wis het veld om de apparaatnaam opnieuw te gebruiken.';

  @override
  String get settingDisableImpellerTitle => 'Verouderde renderer';

  @override
  String get settingDisableImpellerDescription =>
      'Gebruik de oudere Skia-renderer voor oude GPU\'s die tijdens het opstarten vastlopen. Deze optie wordt na twee van zulke crashes automatisch ingeschakeld en geldt vanaf de volgende start van de app.';

  @override
  String get settingLegacyWebViewTitle => 'Verouderde WebView-renderer';

  @override
  String get settingLegacyWebViewDescription =>
      'Teken het dashboard in een texture voor oude GPU\'s die vastlopen zodra het dashboard verschijnt. De optie wordt automatisch ingeschakeld op apparaten die dit nodig hebben en geldt vanaf de volgende start van de app.';

  @override
  String get deviceHostnamePlaceholder => 'Vanaf de apparaatnaam instellen';

  @override
  String get deviceConfiguration => 'Instellingen';

  @override
  String get devicePermissionsManager => 'Toestemmingsbeheer';

  @override
  String get deviceOptions => 'Opties';

  @override
  String get deviceStatus => 'Status';

  @override
  String get deviceConnection => 'Verbinding';

  @override
  String get devicePermissions => 'Toestemmingen';

  @override
  String get deviceHelp => 'Hulp';

  @override
  String get deviceAccess => 'Toegang';

  @override
  String get deviceReading => 'Lezen…';

  @override
  String get deviceChecking => 'Controleren...';

  @override
  String get deviceUnavailable => 'Status niet beschikbaar.';

  @override
  String get deviceGrantOnDevice => 'Toestaan op apparaat';

  @override
  String get deviceAppSettings => 'App-instellingen';

  @override
  String get deviceCopyCommand => 'Opdracht kopiëren';

  @override
  String get deviceOpenGuide => 'Handleiding openen';

  @override
  String get deviceNotSet => 'Niet ingesteld';

  @override
  String get deviceGranted => 'Toegestaan';

  @override
  String get deviceNotGranted => 'Niet toegestaan';

  @override
  String get deviceMissing => 'Ontbrekend';

  @override
  String get deviceNotOffered => 'Niet aangeboden';

  @override
  String get deviceOn => 'aan';

  @override
  String get deviceOff => 'uit';

  @override
  String get deviceServiceHint =>
      'Status, redenen om actief te blijven en vereiste toestemmingen';

  @override
  String get deviceRemoteHintActual =>
      'Deze kiosk beheren vanuit een browser op je netwerk';

  @override
  String get deviceUpdatesHint => 'Waar de app zoekt naar nieuwe releases';

  @override
  String get deviceShizukuHint =>
      'Verbinding, Android-toestemmingen en configuratie';

  @override
  String get deviceHelperHint =>
      'Status van stille updates, ADB-configuratie en instructies';

  @override
  String get deviceAnalyticsHint =>
      'Geanonimiseerde informatie delen om Kiosk Satellite te helpen verbeteren';

  @override
  String get deviceHardwareHint =>
      'Model, Android-versie, adressen, geheugen en actieve tijd';

  @override
  String get deviceHaHint => 'Verbinding, versie en wat de kiosk laat zien';

  @override
  String get deviceWebViewHint => 'Engineversie, renderer en useragent';

  @override
  String get devicePasswordSet => '•••••• (ingesteld)';

  @override
  String get deviceSaveFailed =>
      'Kon deze instelling niet opslaan. Probeer het nog eens.';

  @override
  String get deviceOpenSettingsDevice => 'Instellingen openen op apparaat';

  @override
  String get deviceHardwareButtons => 'Hardwareknoppen';

  @override
  String get deviceHardwareButtonsHeld =>
      'De knoppen van het apparaat bereiken gebaren en Voice Satellite.';

  @override
  String get deviceHardwareButtonsMissing =>
      'De knoppen van het apparaat doen niets tot de knoppendienst is ingeschakeld.';

  @override
  String get deviceHeadlessAdbMicrophone =>
      'Dit apparaat heeft geen scherm. Verleen het via adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO';

  @override
  String get deviceHeadlessAdbNotifications =>
      'Dit apparaat heeft geen scherm. Verleen het via adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS';

  @override
  String get deviceHeadlessAdbLocation =>
      'Dit apparaat heeft geen scherm. Verleen het via adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION';

  @override
  String get deviceHeadlessAdbBluetooth =>
      'Dit apparaat heeft geen scherm. Verleen het via adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN, en daarna hetzelfde voor BLUETOOTH_CONNECT';

  @override
  String get deviceHeadlessAdbBattery =>
      'Dit apparaat heeft geen scherm. Verleen het via adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceHeadlessAdbStorage =>
      'Dit apparaat heeft geen scherm. Verleen het via adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE, en daarna hetzelfde voor WRITE_EXTERNAL_STORAGE';

  @override
  String get deviceHeadlessAdbButtons =>
      'Dit apparaat heeft geen scherm. Schakel het in via adb: adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/.HeadlessKeyService, en daarna adb shell settings put secure accessibility_enabled 1';

  @override
  String get deviceHeadlessAdbButtonsRestart =>
      'De knoppendienst staat aan maar is niet gestart. Start het apparaat opnieuw op om de dienst te starten: adb reboot';

  @override
  String get deviceHardwarePage => 'Hardware';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => 'Apparaatmodel';

  @override
  String get deviceAndroidVersion => 'Android-versie';

  @override
  String get deviceAndroidBuild => 'Android-build';

  @override
  String get deviceIpv4 => 'IPv4-adres';

  @override
  String get deviceIpv6 => 'IPv6-adressen';

  @override
  String get deviceAppUptime => 'Actieve tijd van app';

  @override
  String get deviceNetworkUptime => 'Actieve tijd van netwerk';

  @override
  String get deviceCpuUsage => 'CPU-gebruik';

  @override
  String get deviceCpuClock => 'CPU-kloksnelheid';

  @override
  String get deviceCpuTemp => 'CPU-temperatuur';

  @override
  String get deviceBatteryLevel => 'Batterijniveau';

  @override
  String get deviceBatteryTemp => 'Batterijtemperatuur';

  @override
  String get deviceScreenBrightness => 'Schermhelderheid';

  @override
  String get deviceScreenStatus => 'Schermstatus';

  @override
  String get deviceScreenSize => 'Schermgrootte';

  @override
  String get deviceRam => 'RAM (vrij/totaal)';

  @override
  String get deviceStorage => 'Interne opslag (vrij/totaal)';

  @override
  String get deviceHaUrl => 'Home Assistant-URL';

  @override
  String get deviceWakeDetection => 'Wekwoorddetectie';

  @override
  String get deviceWakeStatus => 'Wekwoordstatus';

  @override
  String get deviceEngine => 'Engine';

  @override
  String get deviceWakeWords => 'Wekwoorden';

  @override
  String get deviceStopWord => 'Stopwoord';

  @override
  String get deviceMotionDetection => 'Bewegingsdetectie';

  @override
  String get deviceFaceDetection => 'Gezichtsdetectie';

  @override
  String get deviceProvider => 'Aanbieder';

  @override
  String get deviceVersion => 'Versie';

  @override
  String get deviceUserAgent => 'Useragent';

  @override
  String get devicePlugged => 'aangesloten';

  @override
  String get deviceLowMemory => 'laag';

  @override
  String get deviceRequiredPermissions => 'Vereiste systeemtoestemmingen';

  @override
  String get devicePermissionIntro =>
      'Toestemmingen worden op dit apparaat verleend. Elke knop opent daarom hier een Android-dialoogvenster of instellingenscherm. Sommige merken voegen een eigen beheerfunctie voor batterijgebruik of automatisch opstarten toe. Android kan de status daarvan niet melden.';

  @override
  String get devicePermissionIntroRemote =>
      'Toestemmingen worden op het apparaat verleend. Elke knop opent daarom daar een Android-dialoogvenster of instellingenscherm. Sommige merken voegen een eigen beheerfunctie voor batterijgebruik of automatisch opstarten toe. Android kan de status daarvan niet melden.';

  @override
  String get deviceMicrophone => 'Microfoon';

  @override
  String get deviceMicrophoneHeld =>
      'Maakt gebruik van de microfoon mogelijk voor wekwoorddetectie, spraak-naar-tekst en intercomgesprekken.';

  @override
  String get deviceBattery => 'Onbeperkte batterij';

  @override
  String get deviceBatteryHeld =>
      'Hiermee kan het proces op de achtergrond blijven draaien zonder te worden gepauzeerd of beëindigd.';

  @override
  String get deviceCamera => 'Camera';

  @override
  String get deviceCameraHeld =>
      'Bewegingsdetectie en snapshots kunnen de camera gebruiken.';

  @override
  String get deviceBluetooth => 'Apparaten in de buurt';

  @override
  String get deviceBluetoothHeld =>
      'De Bluetooth-proxy kan naar apparaten in de buurt scannen.';

  @override
  String get deviceNotifications => 'Meldingen';

  @override
  String get deviceNotificationsHeld =>
      'Maakt de permanente melding van de Kiosk Satellite Service mogelijk. Daarin staat welke functies actief worden gehouden.';

  @override
  String get deviceOverlay => 'Over andere apps weergeven';

  @override
  String get deviceOverlayHeld =>
      'Kiosk Satellite kan zichzelf weer naar de voorgrond brengen.';

  @override
  String get deviceWriteSettings => 'Systeeminstellingen wijzigen';

  @override
  String get deviceWriteSettingsHeld =>
      'Wijzigingen in de helderheid passen de werkelijke helderheid van het scherm aan.';

  @override
  String get deviceUiGuard => 'Systeem-UI-beschermer';

  @override
  String get deviceUiGuardHeld =>
      'Het meldingenpaneel en het overzicht met recente apps worden automatisch gesloten wanneer het scherm wordt beveiligd.';

  @override
  String get deviceDeviceAdmin => 'Apparaatbeheerder';

  @override
  String get deviceDeviceAdminHeld =>
      'Hiermee kan de app het scherm uitschakelen.';

  @override
  String get deviceAllFiles => 'Toegang tot alle bestanden';

  @override
  String get deviceAllFilesHeld =>
      'Bestandsbeheer kan door de gedeelde opslag bladeren.';

  @override
  String get deviceUsageAccess => 'Gebruikstoegang';

  @override
  String get deviceUsageAccessHeld =>
      'De sensor voor de voorgrondapp kan bepalen welke app op het scherm staat.';

  @override
  String get deviceLocation => 'Locatie';

  @override
  String get deviceLocationHeld =>
      'Pagina\'s, Bluetooth-scans en de locatiesensoren kunnen de locatie van het apparaat gebruiken.';

  @override
  String get deviceMicBlocked =>
      'Geblokkeerd. Android zal er niet opnieuw om vragen. Sta de toestemming toe via de appinstellingen.';

  @override
  String get deviceMicMissing =>
      'Wekwoorddetectie staat aan, maar er wordt niet geluisterd.';

  @override
  String get deviceMicIdle =>
      'Nodig voor wekwoorddetectie, de intercom en pagina\'s die om toegang tot de microfoon vragen.';

  @override
  String get deviceBatteryMissing =>
      'Android kan de app pauzeren wanneer het scherm uit staat, waardoor de Home Assistant-verbinding en de ESPHome-entiteiten ermee vallen.';

  @override
  String get deviceCameraMissing =>
      'De camera is ingeschakeld en kan niet worden geopend.';

  @override
  String get deviceCameraIdle =>
      'Nodig voor bewegingsdetectie, camera-opnamen en pagina\'s die om toegang tot de camera vragen.';

  @override
  String get deviceBluetoothMissing =>
      'De Bluetooth-proxy is ingeschakeld en kan niet scannen.';

  @override
  String get deviceBluetoothLocation =>
      'Voor Bluetooth-scans is de locatietoestemming nodig.';

  @override
  String get deviceBluetoothLocationOff =>
      'Locatie is uitgeschakeld in de apparaatinstellingen. Bluetooth-scans leveren daardoor geen resultaten op.';

  @override
  String get deviceBluetoothIdle =>
      'Nodig zodat de Bluetooth-proxy naar apparaten kan scannen.';

  @override
  String get deviceNotificationMissing =>
      'Nodig om de permanente melding van de Kiosk Satellite Service weer te geven.';

  @override
  String get deviceOverlayMissing =>
      'Zonder deze toestemming kan de app zichzelf niet opnieuw openen na een crash, een update of wanneer achter een andere app een wekwoord wordt gehoord.';

  @override
  String get deviceOverlayIdle =>
      'Hiermee kan de app zichzelf weer naar de voorgrond brengen en kan het vergrendelingsschild het hele scherm bedekken.';

  @override
  String get deviceBrightnessMissing =>
      'De helderheidsregeling dimt alleen het appvenster. Het scherm en Home Assistant nemen de wijziging daardoor niet waar.';

  @override
  String get deviceBrightnessIdle =>
      'Nodig om de werkelijke helderheid van het scherm in te stellen in plaats van alleen het appvenster te dimmen.';

  @override
  String get deviceGuardMissing =>
      'Het meldingenpaneel en het overzicht met recente apps blijven toegankelijk. Schakel Kiosk Satellite in bij Toegankelijkheid.';

  @override
  String get deviceGuardIdle =>
      'Sluit het meldingenpaneel en het overzicht met recente apps wanneer de kioskmodus het scherm beveiligt.';

  @override
  String get deviceAdminIdle =>
      'Hiermee schakelt \'Scherm uitschakelen\' het scherm echt uit in plaats van het alleen zwart te maken.';

  @override
  String get deviceFilesIdle =>
      'Hiermee kan Bestandsbeheer door de gedeelde opslag bladeren in plaats van alleen door de appmap.';

  @override
  String get deviceUsageIdle =>
      'Hiermee kan de sensor voor de voorgrondapp ook andere apps dan Kiosk Satellite herkennen.';

  @override
  String get deviceLocationMissing =>
      'Android levert geen Bluetooth-scanresultaten zonder locatie, en de locatiesensoren kunnen de GPS-ontvanger niet lezen.';

  @override
  String get deviceLocationIdle =>
      'Wordt gebruikt door pagina\'s die om je locatie vragen, door Bluetooth-scans en door de ESPHome-locatiesensoren.';

  @override
  String get deviceServiceOverlayMissing =>
      'Zonder deze toestemming kan de service de kiosk niet opnieuw starten na een crash of nadat deze via recente apps is gesloten.';

  @override
  String get deviceServiceOverlayIdle =>
      'Nodig om de kiosk na een crash opnieuw te starten.';

  @override
  String get deviceListeningMissing =>
      'Luisteren op de achtergrond staat aan, maar er wordt niet geluisterd.';

  @override
  String get deviceListeningIdle => 'Nodig om op de achtergrond te luisteren.';

  @override
  String get deviceMotionIdle => 'Nodig voor bewegingsdetectie.';

  @override
  String get deviceBatteryAdb =>
      'Dit apparaat heeft hiervoor geen instellingenscherm. Verleen de toestemming via adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      'Dit apparaat heeft hiervoor geen instellingenscherm. Verleen de toestemming via adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get deviceNotificationAccess => 'Meldingentoegang';

  @override
  String get deviceNotificationAccessHeld =>
      'Speelt nu kan de apps volgen die media afspelen op dit apparaat.';

  @override
  String get deviceNotificationAccessMissing =>
      'Zonder deze toestemming toont Android geen mediasessies. Speelt nu kan de apps die media afspelen op dit apparaat dan niet volgen.';

  @override
  String get deviceNotificationAccessIdle =>
      'Hiermee kan Speelt nu de apps volgen die media afspelen op dit apparaat.';

  @override
  String get settingRemoteEnabledTitle => 'Beheer op afstand';

  @override
  String get settingRemoteEnabledDescription =>
      'Start de ingebouwde webserver voor beheer.';

  @override
  String get settingRemotePortTitle => 'Serverpoort';

  @override
  String get settingRemotePortDescription =>
      'Poort voor de interface voor beheer op afstand.';

  @override
  String get settingRemotePasswordTitle => 'Beheerderswachtwoord';

  @override
  String get settingRemotePasswordDescription =>
      'Vereist om in te loggen op de externe interface.';

  @override
  String get settingRemoteFleetDiscoveryTitle => 'Andere kiosken zoeken';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      'Maak dit apparaat vindbaar op het netwerk en toon andere kiosken in beheer op afstand, zodat je ertussen kunt wisselen.';

  @override
  String get settingRemoteAdminUrlTitle => 'Beheer-URL';

  @override
  String get settingRemoteAdminUrlDescription =>
      'Adres dat andere kiosken openen via Kiosk wisselen om deze te bereiken, zoals de naam van een reverse proxy. Laat leeg om het netwerkadres te gebruiken.';

  @override
  String get deviceAdminUrlInvalid =>
      'Voer een geldig adres in, bijvoorbeeld https://kiosk.example.com';

  @override
  String get deviceAdminUrlPath =>
      'Voer alleen het adres in, zonder pad. Voorbeeld: https://kiosk.example.com';

  @override
  String get deviceRemotePage => 'Beheer op afstand';

  @override
  String get deviceAdminAddress => 'Beheeradres';

  @override
  String get deviceAdminAddressHelp =>
      'Open dit adres in een browser op je computer.';

  @override
  String get deviceByName => 'Op naam';

  @override
  String get deviceByNameHelp =>
      'Hetzelfde adres met de hostnaam, op netwerken die .local-namen ondersteunen.';

  @override
  String get deviceByCertificateNameHelp =>
      'Hetzelfde adres met de naam uit het certificaat.';

  @override
  String get devicePasswordNeeded =>
      'Stel hieronder een beheerderswachtwoord in om de server te starten.';

  @override
  String get deviceServerStopped => 'De server draait niet.';

  @override
  String devicePortError(String port, String error) {
    return 'Kon niet luisteren op poort $port: $error';
  }

  @override
  String get settingRemoteTlsTitle => 'HTTPS gebruiken';

  @override
  String get settingRemoteTlsDescription =>
      'Versleutel beheer op afstand, de API en WebSocket. Je browser kan vragen om het apparaatcertificaat te accepteren.';

  @override
  String get settingServiceCpuAwakeTitle =>
      'Houd de CPU wakker terwijl het scherm uit staat';

  @override
  String get settingServiceCpuAwakeDescription =>
      'Houdt een wakelock vast wanneer het scherm uit staat, zodat verbindingen en timers op tijd blijven werken. Dit kost batterijvermogen wanneer een tablet niet op de stroom is aangesloten.';

  @override
  String get deviceServicePage => 'Kiosk Satellite Service';

  @override
  String get deviceKeepingRunning => 'Actief houden';

  @override
  String get deviceService => 'Service';

  @override
  String get deviceStopped => 'Gestopt';

  @override
  String get deviceStoppedSentence => 'Gestopt.';

  @override
  String get deviceRunning => 'Actief';

  @override
  String get deviceRunningSentence => 'Actief.';

  @override
  String get deviceRunningBackground =>
      'Actief zonder vrijstelling voor een voorgrondservice.';

  @override
  String get deviceServiceTypes => 'Typen voorgrondservice';

  @override
  String get deviceServiceTypesHelp =>
      'De servicetypen die bij Android zijn aangegeven voor de functies die actief worden gehouden.';

  @override
  String get deviceNoneDeclared => 'Niets opgegeven.';

  @override
  String get deviceNone => 'geen';

  @override
  String get deviceCpuLock => 'CPU wake lock';

  @override
  String get deviceCpuOff => 'Uit: de instelling hieronder is uitgeschakeld.';

  @override
  String get deviceCpuHeld => 'Vastgehouden: het scherm staat uit.';

  @override
  String get deviceCpuReleased => 'Vrijgegeven terwijl het scherm aan staat.';

  @override
  String get deviceNotHeld => 'Niet vastgehouden.';

  @override
  String get deviceHeld => 'Vastgehouden';

  @override
  String get deviceReleased => 'Vrijgegeven';

  @override
  String get deviceWifiLock => 'Wifi-lock';

  @override
  String get deviceWifiHeld =>
      'Vastgehouden: de wifi blijft buiten de energiebesparingsstand.';

  @override
  String get deviceWifiHelp =>
      'Voorkomt dat wifi naar de energiebesparingsstand gaat wanneer het scherm uit staat.';

  @override
  String get deviceNotification => 'Melding';

  @override
  String get deviceNotificationHidden =>
      'Verborgen: meldingen voor de app zijn uitgeschakeld. De service blijft gewoon actief.';

  @override
  String get deviceNotificationShown =>
      'Getoond in het meldingenpaneel terwijl de service actief is.';

  @override
  String get deviceHidden => 'Verborgen';

  @override
  String get deviceShown => 'Getoond';

  @override
  String get deviceReasonHa => 'Home Assistant-verbinding';

  @override
  String get deviceReasonHaHelp =>
      'Houdt de dashboardsessie en de websocketverbinding open wanneer het scherm uit staat.';

  @override
  String get deviceReasonListening => 'Luisteren op de achtergrond';

  @override
  String get deviceReasonListeningHelp =>
      'Houdt de wekwoordengine en de microfoon actief achter andere apps.';

  @override
  String get deviceReasonRtsp => 'RTSP-microfoonaudio';

  @override
  String get deviceReasonRtspHelp =>
      'Houdt microfoonstreaming beschikbaar voor aangesloten RTSP-kijkers.';

  @override
  String get deviceReasonEspHome => 'ESPHome-server';

  @override
  String get deviceReasonEspHomeHelp =>
      'Houdt de ESPHome API-server bereikbaar voor Home Assistant.';

  @override
  String get deviceReasonRemote => 'Beheer op afstand';

  @override
  String get deviceReasonRemoteHelp =>
      'Houdt de webserver voor beheer bereikbaar.';

  @override
  String get deviceReasonProtections => 'Kioskbeveiliging';

  @override
  String get deviceReasonProtectionsHelp =>
      'Start de kiosk opnieuw wanneer deze via recente apps wordt gesloten of crasht.';

  @override
  String get deviceReasonBluetooth => 'Bluetooth-proxy';

  @override
  String get deviceReasonBluetoothHelp =>
      'Houdt Bluetooth-scans actief wanneer de app niet op het scherm staat.';

  @override
  String get deviceReasonLocation => 'Locatiesensoren';

  @override
  String get deviceReasonLocationHelp =>
      'Zorgt dat GPS-locaties blijven binnenkomen wanneer het scherm uit staat of een andere app op de voorgrond staat.';

  @override
  String get deviceReasonPerson => 'Persoonsdetectie';

  @override
  String get deviceReasonPersonHelp =>
      'Blijft de persoonssensor van het apparaat lezen terwijl een andere app vooraan staat.';

  @override
  String get deviceReasonCameraHelp =>
      'Houdt de camera bruikbaar nadat het paneel is uitgeschakeld, voor beweging en gezichtsdetectie.';

  @override
  String deviceServiceStopped(String error) {
    return 'Gestopt: $error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return 'Al $uptime actief.';
  }

  @override
  String get settingShizukuInstallUpdatesTitle =>
      'Updates installeren via Shizuku';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      'Installeer updates voor Kiosk Satellite zonder bevestiging op het apparaat. Shizuku moet actief en geautoriseerd zijn.';

  @override
  String get deviceShizukuAccess => 'Toegang tot Shizuku';

  @override
  String get deviceShizukuCheck => 'Beschikbaarheid controleren';

  @override
  String get deviceShizukuRoot => 'Verbonden met roottoegang';

  @override
  String get deviceShizukuShell => 'Verbonden met shelltoegang';

  @override
  String get deviceShizukuGrant =>
      'Tik om toegang te verlenen. Keur het verzoek op deze kiosk goed.';

  @override
  String get deviceShizukuGrantRemote =>
      'Geef toegang en keur het verzoek goed op deze kiosk.';

  @override
  String get deviceShizukuDenied =>
      'Kiosk Satellite toestaan in de Shizuku-app.';

  @override
  String get deviceShizukuUnsupported => 'Shizuku 13 of hoger is vereist.';

  @override
  String get deviceShizukuStart => 'Start Shizuku op dit apparaat.';

  @override
  String get deviceShizukuTest => 'Verbinding testen';

  @override
  String get deviceShizukuTestHelp =>
      'Lees de procesidentiteit zonder het apparaat te veranderen.';

  @override
  String get deviceShizukuTestTitle => 'Verbindingstest';

  @override
  String get deviceShizukuTestFailed =>
      'Shizuku kon de verbindingstest niet voltooien.';

  @override
  String get deviceShizukuAlreadyGranted =>
      'Alle toestemmingen zijn al verleend.';

  @override
  String get deviceShizukuConfirmed =>
      'Android heeft de gevraagde toestemmingen bevestigd.';

  @override
  String get deviceShizukuResults => 'Resultaten van toestemmingsaanvraag';

  @override
  String get deviceShizukuGrantAll => 'Alle toestemmingen verlenen';

  @override
  String get deviceShizukuGrantAllHelp =>
      'Verleen alle toestemmingen die Kiosk Satellite gebruikt, ook voor functies die momenteel uitgeschakeld zijn.';

  @override
  String get deviceShizukuSetup => 'Shizuku instellen';

  @override
  String get deviceShizukuSetupHelp =>
      'Lees installatie- en opstartinstructies.';

  @override
  String get deviceShizukuLifetime =>
      'Shizuku moet na elke herstart van het apparaat opnieuw via ADB worden gestart. Shelltoegang verleent geen rootrechten.';

  @override
  String get deviceShizukuFailed => 'Shizuku-verzoek mislukt';

  @override
  String get deviceShizukuApprove => 'Keur het verzoek op de kiosk goed.';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku heeft een opdracht uitgevoerd met $access-toegang.';
  }

  @override
  String get shizukuPermissionUnconfirmed =>
      'Android heeft deze toestemming niet bevestigd. Controleer Toestemmingsbeheer op het apparaat.';

  @override
  String get shizukuPermissionReadFailed =>
      'De huidige toestemmingen konden niet worden uitgelezen. Probeer het opnieuw.';

  @override
  String get shizukuRestartTimedOut => 'Time-out bij de herstartopdracht';

  @override
  String get shizukuRestartRefused => 'Android heeft de herstart geweigerd';

  @override
  String get shizukuCommandTimedOut => 'Time-out bij de opdracht';

  @override
  String get shizukuRequestRejected => 'Android heeft het verzoek afgewezen';

  @override
  String get deviceDisconnectedError => 'Verbinding met apparaat verbroken';

  @override
  String get deviceResponseTimedOut => 'Time-out bij reactie van apparaat';

  @override
  String get deviceRequestAborted => 'Verzoek afgebroken';

  @override
  String get shizukuActionBusy => 'Er is al een Shizuku-apparaatactie actief';

  @override
  String get shizukuGrantFirst => 'Verleen eerst toegang tot Shizuku';

  @override
  String get shizukuNoResponse => 'Shizuku-opdracht reageerde niet';

  @override
  String get shizukuCommandFailed => 'Shizuku-opdracht mislukt';

  @override
  String get shizukuStartRequired =>
      'Start Shizuku 13 of hoger en geef Kiosk Satellite toegang in Shizuku';

  @override
  String get shizukuConnectionFailed => 'Shizuku-verbinding mislukt';

  @override
  String get shizukuHelperNotConnected =>
      'Shizuku-helper heeft geen verbinding gemaakt';

  @override
  String get shizukuHelperUnavailable => 'Shizuku-helper is niet beschikbaar';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates =>
      'Verbindingsversleuteling en certificaten';

  @override
  String get tlsCertificateType => 'Certificaattype';

  @override
  String get tlsImported => 'Geïmporteerd';

  @override
  String get tlsSelfSigned => 'Zelfondertekend';

  @override
  String get tlsExpires => 'Verloopt';

  @override
  String get tlsSHA256Fingerprint => 'SHA-256-vingerafdruk';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      'Het certificaat is verlopen. Vernieuw het of importeer een vervangend certificaat.';

  @override
  String get tlsCopyPublicCertificate => 'Openbaar certificaat kopiëren';

  @override
  String get tlsDownloadPublicCertificate => 'Openbaar certificaat downloaden';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      'Gebruik dit certificaat in browsers en streamingclients.';

  @override
  String get tlsRenewCertificate => 'Certificaat vernieuwen';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      'Behoud de huidige privésleutel en werk de geldigheidsdatums van het certificaat bij.';

  @override
  String get tlsImportCertificate => 'Certificaat importeren';

  @override
  String get tlsUseACertificateIssuedForThisDevice =>
      'Gebruik een certificaat dat voor dit apparaat is afgegeven.';

  @override
  String get tlsReplaceCertificate => 'Certificaat vervangen';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      'Genereer een nieuwe privésleutel en een zelfondertekend certificaat.';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      'Een nieuwe privésleutel en een nieuw certificaat genereren? Actieve versleutelde verbindingen worden verbroken. Browsers kunnen je vragen het nieuwe certificaat te accepteren.';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      'Plak de PEM-certificaatketen en de bijbehorende onversleutelde privésleutel. Deze worden gevalideerd voordat het huidige certificaat wordt vervangen.';

  @override
  String get tlsCertificateChainPEM => 'Certificaatketen (PEM)';

  @override
  String get tlsPrivateKeyPEM => 'Privésleutel (PEM)';

  @override
  String get tlsThisFieldIsRequired => 'Dit veld is vereist.';

  @override
  String get tlsReplace => 'Vervangen';

  @override
  String get tlsRenew => 'Vernieuwen';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      'Schakel HTTPS in voordat je op afstand een privésleutel importeert.';

  @override
  String get tlsCertificateOperationFailed => 'Certificaatbewerking mislukt.';

  @override
  String get tlsChangeConnectionProtocol => 'Verbindingsprotocol wijzigen';

  @override
  String get tlsConnectionProtocolHelp =>
      'De huidige externe verbinding wordt verbroken. Maak opnieuw verbinding via het onderstaande adres. Mogelijk moet je je opnieuw aanmelden.';

  @override
  String get tlsConfirm => 'Bevestigen';

  @override
  String get tlsCertificateManagement => 'Certificaatbeheer';

  @override
  String get tlsServerCertificateRequired =>
      'Gebruik een servercertificaat, geen CA-certificaat.';

  @override
  String get tlsServerAuthenticationRequired =>
      'Certificaat staat serverauthenticatie niet toe.';

  @override
  String get tlsKeyAlgorithmRequired => 'Gebruik een EC- of RSA-privésleutel.';

  @override
  String get tlsKeyMismatch =>
      'Certificaat en privésleutel komen niet overeen.';

  @override
  String get tlsMaterialTooLarge => 'Certificaat of sleutel is te groot.';

  @override
  String get tlsPemCertificatesRequired =>
      'Er werden PEM-certificaten verwacht.';

  @override
  String get tlsCertificateMissing => 'Geen certificaat gevonden.';

  @override
  String get tlsUnencryptedKeyRequired =>
      'Gebruik een onversleutelde PEM-privésleutel.';

  @override
  String get tlsHostnameRequired => 'Een hostnaam of IP-adres is vereist.';

  @override
  String get tlsIssuerRenewalRequired =>
      'Importeer een door de uitgever vernieuwd certificaat.';

  @override
  String get tlsStoredIdentityDamaged =>
      'De opgeslagen TLS-identiteit is beschadigd.';

  @override
  String get tlsExpiredCertificate =>
      'Het TLS-certificaat is verlopen. Vernieuw het of importeer een vervangend certificaat.';

  @override
  String get deviceHelperPage => 'Optionele update-helper';

  @override
  String get deviceHelperStatus => 'Status van helper';

  @override
  String get deviceHelperError => 'Kon de update-helper niet controleren.';

  @override
  String get deviceHelperUnneeded =>
      'Android kan updates nu zonder bevestiging installeren. De helper is niet nodig.';

  @override
  String get deviceHelperIntro =>
      'Op dit apparaat moet de installatie van updates via Android momenteel op het scherm worden bevestigd. Met de optionele helper kan Kiosk Satellite updates zonder aanraking installeren.';

  @override
  String get deviceHelperBusy => 'Update wordt geïnstalleerd.';

  @override
  String get deviceHelperReady =>
      'Klaar. Updates installeren zonder bevestiging.';

  @override
  String get deviceHelperUnavailable =>
      'Niet beschikbaar. Start de helper via ADB om updates zonder bevestiging in te schakelen.';

  @override
  String get deviceHelperLifetime =>
      'De helper blijft actief na het opnieuw starten of bijwerken van de app, maar stopt wanneer het apparaat opnieuw wordt opgestart. Voer de opdracht opnieuw uit vanaf een computer met ADB. De computer kan daarna worden losgekoppeld.';

  @override
  String get deviceHelperStart => 'Starten via ADB';

  @override
  String get deviceHelperGuide => 'Configuratiehandleiding';

  @override
  String get deviceHelperGuideHelp =>
      'Lees de instructies en vereisten voor de update-helper.';

  @override
  String get settingUpdateSourceTitle => 'Updatebron';

  @override
  String get settingUpdateSourceDescription =>
      'Waar de app zoekt naar nieuwe releases.';

  @override
  String get settingUpdateSourceUrlTitle => 'Repository-URL';

  @override
  String get settingUpdateSourceUrlDescription =>
      'Een bereikbare map op een webserver met releases.json en de APK-bestanden van de releases.';

  @override
  String get deviceUpdatesPage => 'Updates';

  @override
  String get deviceUpdateGithub => 'GitHub-repository';

  @override
  String get deviceUpdateCustom => 'Aangepaste repository';

  @override
  String get deviceUpdateGuide => 'Handleiding voor aangepaste repository';

  @override
  String get deviceUpdateGuideHelp =>
      'Zo host je het releasebestand en de APK-bestanden op je eigen netwerk.';

  @override
  String get deviceInstallFile => 'Installeren vanuit bestand';

  @override
  String get deviceInstallFileHelp =>
      'Upload op deze pagina via beheer op afstand een Kiosk Satellite-APK vanaf een computer. Bedoeld voor een kiosk die GitHub of een aangepaste repository niet kan bereiken.';

  @override
  String get deviceInstallFileRemoteHelp =>
      'Upload vanaf deze computer een Kiosk Satellite-APK en installeer deze. Bedoeld voor een kiosk die GitHub of een aangepaste repository niet kan bereiken.';

  @override
  String get deviceUploadedApk => 'Geüploade APK';

  @override
  String get deviceInstalling => 'Installeren…';

  @override
  String get deviceDeviceNoAnswer => 'Het apparaat reageerde niet.';

  @override
  String get deviceInstallFailed =>
      'De update is mislukt. Controleer de apparaatlogboeken.';

  @override
  String get deviceConfirmTablet => 'Bevestig op het tabletscherm';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return 'Versie $version (build $build, $size MB) staat op het apparaat en wacht op installatie.';
  }

  @override
  String deviceInstallVersion(String version) {
    return 'Versie $version installeren';
  }

  @override
  String deviceHttpError(String code) {
    return 'Het apparaat reageerde met HTTP $code.';
  }

  @override
  String get deviceUploadFailed => 'De upload is mislukt.';

  @override
  String get deviceInstallFleet => 'Installeren op de vloot';

  @override
  String get deviceSendingFleet => 'Verzenden naar de vloot…';

  @override
  String get deviceSameBuild => 'Deze build is al op de kiosk geïnstalleerd.';

  @override
  String get deviceInstallConfirmation =>
      'De installatie moet op het tabletscherm worden bevestigd, tenzij de kiosk updates stil installeert.';

  @override
  String get deviceSelfLast => 'Deze kiosk installeert als laatste.';

  @override
  String get deviceUpdatingFleet => 'De vloot bijwerken';

  @override
  String deviceUploading(String percent) {
    return 'Uploaden… $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return 'De geüploade APK is versie $version (build $build, $size MB).';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'Op de kiosk draait $version (build $build).';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return 'Verzenden naar $name… $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return 'Installeren op $name…';
  }

  @override
  String deviceInstallingNames(String names) {
    return 'Installatie op $names is bezig.';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      'Voer de map-URL in, bijvoorbeeld http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      'Voer alleen de map-URL in, zonder iets na het pad. Voorbeeld: http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy =>
      'Er wordt gedownload. Wacht tot het klaar is.';

  @override
  String get updateInstallBusy =>
      'Er wordt een installatie uitgevoerd. Wacht totdat deze klaar is.';

  @override
  String get updateNoAvailable => 'Er is geen update beschikbaar.';

  @override
  String get updateNoUploaded => 'Er staat geen geüploade APK klaar.';

  @override
  String get updateUploadEmpty => 'De upload was leeg.';

  @override
  String get updateInvalidApk => 'Het bestand is geen Android-APK.';

  @override
  String get updateUploadedGone =>
      'De geüploade APK is niet meer beschikbaar. Upload deze opnieuw.';

  @override
  String get updateShizukuInstallerFailed =>
      'Shizuku kon de update niet installeren. Het installatieprogramma met bevestiging is niet geopend.';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return 'Onvoldoende vrije ruimte: de APK is $size MB en voor de installatie is ongeveer $required MB nodig, maar het apparaat heeft slechts $free MB vrij.';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return 'De upload werd onderbroken na $size MB: $error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return 'De upload is voortijdig beëindigd: $received van de $expected MB is ontvangen.';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return 'De APK is $package, niet Kiosk Satellite ($expected).';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'De APK bevat versie $version (build $build), die ouder is dan de actieve versie $currentVersion (build $currentBuild). Downgrades worden geweigerd, omdat Android deze ook niet zou installeren.';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return 'Downloaden mislukt (HTTP $status).';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return 'De download is vastgelopen: er zijn $seconds seconden lang geen gegevens ontvangen.';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return 'Update mislukt: $error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return 'Installatie mislukt: $error';
  }

  @override
  String get updateAnotherPackage => 'een ander pakket';

  @override
  String get deviceKioskSatelliteUpdates => 'Kiosk Satellite-updates';

  @override
  String get deviceAndroidSystemUpdates => 'Android-systeemupdates';

  @override
  String get settingAndroidUpdatePolicyTitle => 'Android-updates installeren';

  @override
  String get settingAndroidUpdatePolicyDescription =>
      'Updates van Android zelf van de fabrikant van het apparaat, zoals Google of Samsung. De kioskmodus verbergt de melding om te herstarten en ze te installeren.';

  @override
  String get deviceAndroidUpdateAsk => 'Vragen op het apparaat';

  @override
  String get deviceAndroidUpdateAutomatic => 'Meteen';

  @override
  String get deviceAndroidUpdateWindowed => 'Binnen een tijdvenster';

  @override
  String get settingAndroidUpdateWindowStartTitle => 'Installeren vanaf';

  @override
  String get settingAndroidUpdateWindowStartDescription =>
      'Lokale tijd waarop het dagelijkse venster voor installeren en herstarten begint.';

  @override
  String get settingAndroidUpdateWindowEndTitle => 'Installeren tot';

  @override
  String get settingAndroidUpdateWindowEndDescription =>
      'Lokale tijd waarop het venster sluit. Een venster over middernacht eindigt de volgende dag.';

  @override
  String get settingUiLanguageTitle => 'Taal';

  @override
  String get settingUiLanguageDescription =>
      'Taal voor Kiosk Satellite en beheer op afstand. Home Assistant gebruikt een eigen taalinstelling.';

  @override
  String get settingUiThemeTitle => 'App-thema';

  @override
  String get settingUiThemeDescription =>
      'Licht of donker voor de eigen schermen van de app, zoals het menu, de instellingen en dialoogvensters. Systeem volgt de Android-instelling.';

  @override
  String get settingUiScaleTitle => 'UI schalen';

  @override
  String get settingUiScaleDescription =>
      'Grootte van de eigen schermen van de app, zoals het menu, de instellingen en dialoogvensters. Bedoeld voor beeldschermen met een hoge pixeldichtheid. Webinhoud behoudt dezelfde grootte.';

  @override
  String get deviceUserInterface => 'Gebruikersinterface';

  @override
  String get deviceThemeDark => 'Donker';

  @override
  String get deviceThemeLight => 'Licht';

  @override
  String get deviceThemeSystem => 'Systeem';

  @override
  String get settingUiToastsHiddenTitle =>
      'Pop-upmeldingen van het systeem tonen';

  @override
  String get settingUiToastsHiddenDescription =>
      'Kies welke pop-upmeldingen over het dashboard verschijnen. Meldingen in Instellingen verschijnen altijd.';

  @override
  String get deviceToastsAll => 'Alle';

  @override
  String get deviceToastsNone => 'Geen';

  @override
  String get deviceToastBack => 'Hints voor de terugknop';

  @override
  String get deviceToastGestures => 'Gebaaracties';

  @override
  String get deviceToastHoldMode => 'Wachtstand';

  @override
  String get deviceToastLinks => 'Dashboardlinks';

  @override
  String get deviceToastDownloads => 'Downloads';

  @override
  String get deviceToastNetwork => 'Netwerkstatus';

  @override
  String get deviceToastUpdates => 'Updatecontroles';

  @override
  String get deviceToastVoice => 'Voice Satellite-meldingen';

  @override
  String get deviceToastTimers => 'Timers';

  @override
  String get deviceToastAlarms => 'Alarmen';

  @override
  String get deviceToastMusicLibrary => 'Muziekbibliotheek';

  @override
  String get deviceToastIntercom => 'Intercom';

  @override
  String get deviceToastAppLauncher => 'Appstarter';

  @override
  String get deviceToastPlugins => 'Plug-inacties';

  @override
  String get settingUiDrawerItemsTitle => 'Items in het zijmenu';

  @override
  String get settingUiDrawerItemsDescription =>
      'Kies welke items het zijmenu toont en in welke volgorde.';

  @override
  String get settingShowInKioskMenuTitle => 'Toon in het kioskmenu';

  @override
  String get settingDlnaEnabledTitle => 'DLNA-renderer inschakelen';

  @override
  String get settingDlnaEnabledDescription =>
      'Toon afbeeldingen en speel media af die vanuit Home Assistant of een DLNA-app naar het apparaat worden gestuurd. Het apparaat verschijnt als mediaspeler met de apparaatnaam.';

  @override
  String get settingDlnaAudioBackgroundTitle =>
      'Audio op de achtergrond houden';

  @override
  String get settingDlnaAudioBackgroundDescription =>
      'Verzonden audio wordt afgespeeld zonder het scherm over te nemen.';

  @override
  String get settingDlnaPortTitle => 'Serverpoort';

  @override
  String get settingDlnaPortDescription =>
      'De poort waarop de renderer actief is. Deze wordt ingevuld wanneer de renderer start. Wijzig de poort om de renderer te verplaatsen of wis het veld om automatisch opnieuw een poort te kiezen.';

  @override
  String get settingDlnaPortPlaceholder =>
      'Wordt ingesteld wanneer de renderer start';

  @override
  String get settingEsphomeRealMacTitle => 'Echt wifi-MAC-adres gebruiken';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant koppelt deze kiosk aan hetzelfde apparaat dat al door je netwerkintegraties wordt gevolgd. Als je dit wijzigt, wordt in Home Assistant een nieuw ESPHome-apparaat aangemaakt.';

  @override
  String get settingEsphomeMacOverrideTitle => 'Wifi-MAC-adres nabootsen';

  @override
  String get settingEsphomeMacOverrideDescription =>
      'Omdat het MAC-adres niet kan worden achterhaald, kun je hier zelf een adres invoeren. Als je dit wijzigt, wordt in Home Assistant een nieuw ESPHome-apparaat aangemaakt.';

  @override
  String get esphomeAdvanced => 'Geavanceerde instellingen';

  @override
  String get esphomeAdvancedHelp => 'Werkelijk of nagebootst wifi-MAC-adres';

  @override
  String get esphomeMacInvalid => 'Vul een geldig MAC-adres in.';

  @override
  String esphomeMacHardware(String mac) {
    return 'Rapporteert $mac.';
  }

  @override
  String esphomeMacManual(String mac) {
    return 'Rapporteert het hieronder ingevoerde adres $mac.';
  }

  @override
  String get esphomeMacUnavailable =>
      'Android geeft het hardwareadres van dit apparaat niet vrij.';

  @override
  String get settingAnnouncementsEnabledTitle => 'Aankondigingen inschakelen';

  @override
  String get settingAnnouncementsEnabledDescription =>
      'Speel aankondigingen af die Home Assistant met de actie \'announce\' verstuurt.';

  @override
  String get esphomeTtsSection => 'Tekst-naar-spraak';

  @override
  String get settingAnnouncementsTtsEngineTitle => 'Tekst-naar-spraakengine';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'De tekst-naar-spraakentiteit van Home Assistant die de aankondigingen uitspreekt.';

  @override
  String get settingAnnouncementsTtsLanguageTitle => 'Taal';

  @override
  String get settingAnnouncementsTtsLanguageDescription =>
      'De taal waarin de aankondigingen worden uitgesproken.';

  @override
  String get settingAnnouncementsTtsVoiceTitle => 'Stem';

  @override
  String get settingAnnouncementsTtsVoiceDescription =>
      'De stem die aankondigingen spreekt.';

  @override
  String get esphomeTtsFirst => 'Eerste beschikbare';

  @override
  String get esphomeTtsDefault => 'Standaard';

  @override
  String get settingAnnouncementsChimeTitle => 'Eerst een meldingsgeluid';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Speel vóór de aankondiging een meldingsgeluid af.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Meldingsgeluid';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Wordt op hetzelfde volume als de aankondiging afgespeeld.';

  @override
  String get esphomeAnnouncements => 'Aankondigingen';

  @override
  String get esphomeAnnouncementsHelp =>
      'Gesproken aankondigingen van Home Assistant';

  @override
  String get esphomeChime => 'Meldingsgeluid';

  @override
  String get esphomeTtsUnavailable => 'Kon Home Assistant niet bereiken';

  @override
  String get esphomeTtsNoVoices => 'Geen stemmen beschikbaar';

  @override
  String get settingBtproxyEnabledTitle => 'Bluetooth-proxy inschakelen';

  @override
  String get settingBtproxyEnabledDescription =>
      'Geef Bluetooth-apparaten in de buurt door aan Home Assistant.';

  @override
  String get settingBtproxyScanDutyTitle => 'Scanintensiteit';

  @override
  String get settingBtproxyScanDutyDescription =>
      'Bepaalt hoeveel tijd de Bluetooth-radio luistert. Een lagere waarde belast de CPU minder, maar apparaten die niet vaak uitzenden verschijnen dan later.';

  @override
  String get settingBtproxyScreenOffScanTitle =>
      'Blijven scannen met het scherm uit';

  @override
  String get settingBtproxyScreenOffScanDescription =>
      'Schakel in als de proxy niets meer doorgeeft terwijl het scherm uit is. Belast de CPU meer.';

  @override
  String get settingBtproxyConnectionsTitle => 'Apparaatverbindingen toestaan';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant kan via deze proxy verbinding maken met Bluetooth-apparaten.';

  @override
  String get settingBtproxyMacLookupTitle =>
      'Fabrikanten van apparaten online opzoeken';

  @override
  String get settingBtproxyMacLookupDescription =>
      'Geeft onbekende apparaten in de buurt een fabrikantnaam op basis van het begin van hun hardwareadres via api.macvendors.com. Alleen het drie bytes lange fabrikantgedeelte wordt eenmaal per fabrikant verzonden. Er verlaten geen andere gegevens het apparaat.';

  @override
  String get settingBtproxyNearbySortTitle => 'Sorteren op';

  @override
  String get settingBtproxyNearbySortDescription =>
      'De sorteervolgorde van de onderstaande lijst met apparaten in de buurt.';

  @override
  String get settingBtproxyMinConnectRssiTitle =>
      'Minimumsignaal voor verbindingen';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      'Weiger verbindingen met apparaten waarvan het signaal zwakker is dan deze waarde, zodat een proxy dichterbij de verbinding kan overnemen.';

  @override
  String get esphomeOptionContinuous => 'Continu';

  @override
  String get esphomeOptionBalanced => 'Gebalanceerd';

  @override
  String get esphomeOptionLowPower => 'Laag vermogen';

  @override
  String get esphomeOptionLastSeen => 'Laatst gezien';

  @override
  String get esphomeOptionName => 'Naam';

  @override
  String get esphomeOptionMacAddress => 'MAC-adres';

  @override
  String get esphomeOptionSignalStrength => 'Signaalsterkte';

  @override
  String get esphomeOptionNoLimit => 'Geen limiet';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm (zelfde ruimte)';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm (rand van bereik)';

  @override
  String get esphomeBluetooth => 'Bluetooth-proxy';

  @override
  String get esphomeBluetoothHelp =>
      'Geef Bluetooth-apparaten in de buurt door aan Home Assistant';

  @override
  String get esphomeBluetoothOff =>
      'Bluetooth is uit. Zet het aan om de proxy te gebruiken.';

  @override
  String get esphomeBluetoothUnsupported =>
      'Niet beschikbaar op dit apparaat: het heeft geen Bluetooth.';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      'Niet beschikbaar op dit apparaat: deze Android-build ondersteunt Bluetooth LE niet.';

  @override
  String get esphomeIdentityBthome => 'BTHome-sensor';

  @override
  String get esphomeIdentityXiaomi => 'Xiaomi-sensor';

  @override
  String get esphomeIdentityQingping => 'Qingping-sensor';

  @override
  String get esphomeIdentityGoogleNest => 'Google/Nest-apparaat';

  @override
  String get esphomeIdentityEddystone => 'Eddystone-baken';

  @override
  String get esphomeIdentityGoogleFastPair => 'Google Fast Pair-apparaat';

  @override
  String get esphomeIdentityAppleFindMy => 'Apple Zoek mijn-apparaat';

  @override
  String get esphomeIdentityExposure => 'Blootstellingsmelding (telefoon)';

  @override
  String get esphomeIdentityAugustYale => 'August/Yale-slot';

  @override
  String get esphomeIdentityAmazon => 'Amazon-apparaat';

  @override
  String get esphomeIdentityTile => 'Tile-tracker';

  @override
  String get esphomeIdentityInput =>
      'Invoerapparaat (afstandsbediening/toetsenbord)';

  @override
  String get esphomeIdentityHeartRate => 'Hartslagsensor';

  @override
  String get esphomeIdentityEnvironmental => 'Omgevingssensor';

  @override
  String get esphomeIdentityApple => 'Apple-apparaat';

  @override
  String get esphomeIdentityWindows => 'Windows-pc';

  @override
  String get esphomeIdentitySamsung => 'Samsung-apparaat';

  @override
  String get esphomeIdentityGoogle => 'Google-apparaat';

  @override
  String get esphomeIdentityUnknown => 'Onbekend apparaat';

  @override
  String esphomeIdentityVendor(String vendor) {
    return '$vendor-apparaat';
  }

  @override
  String get esphomeNearby => 'Apparaten in de buurt';

  @override
  String get esphomeNearbySearch =>
      'De Bluetooth-apparaten die deze kiosk detecteert, waar mogelijk met naam.';

  @override
  String get esphomeNearbyEmpty => 'Nog niets gehoord.';

  @override
  String get esphomeNearbyWaiting =>
      'Nog niets gedetecteerd. Apparaten verschijnen hier zodra de proxy begint met scannen.';

  @override
  String get esphomeRotating => '(wisselend adres)';

  @override
  String esphomeNearbyCount(String count, String total) {
    return 'De eerste $count van $total worden weergegeven.';
  }

  @override
  String esphomeSlots(String count) {
    return 'Via deze proxy kunnen maximaal $count apparaten tegelijk worden verbonden. Home Assistant leidt overige apparaten via andere proxy\'s.';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return '${count}s geleden';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return '$count min geleden';
  }

  @override
  String esphomeHoursAgo(String count) {
    return '$count h geleden';
  }

  @override
  String get settingLocationEnabledTitle => 'Locatie doorgeven';

  @override
  String get settingLocationEnabledDescription =>
      'Lees de GPS-positie uit en stel deze in Home Assistant beschikbaar als sensoren voor breedtegraad, lengtegraad, nauwkeurigheid, hoogte en snelheid. Als je dit in- of uitschakelt, wordt het ESPHome-apparaat opnieuw geregistreerd.';

  @override
  String get settingLocationIntervalTitle => 'Update-interval';

  @override
  String get settingLocationIntervalDescription =>
      'Seconden tussen positiemetingen.';

  @override
  String get esphomeGps => 'GPS-sensor';

  @override
  String get esphomeGpsHelp =>
      'GPS-sensorgegevens beschikbaar stellen aan Home Assistant';

  @override
  String get esphomeLocationOff => 'Uit.';

  @override
  String get esphomeLocationWaiting =>
      'Wachten op de eerste positiebepaling. Een koude start in de open lucht kan enkele minuten duren.';

  @override
  String get esphomeCoordinates => 'Laatste coördinaten';

  @override
  String get esphomeLocationDenied => 'Locatietoestemming niet verleend.';

  @override
  String get esphomeLocationAbsent => 'Geen GPS-ontvanger.';

  @override
  String esphomeLocationError(String error) {
    return 'GPS niet beschikbaar: $error';
  }

  @override
  String get esphomeLocationUnsupported =>
      'Niet beschikbaar op dit apparaat: het heeft geen GPS-ontvanger.';

  @override
  String get settingNotificationsTransparencyTitle => 'Transparantie';

  @override
  String get settingNotificationsTransparencyDescription =>
      'Laat het onderliggende scherm door de meldingskaarten heen schijnen. Tekst en pictogrammen blijven ondoorzichtig.';

  @override
  String get settingNotificationsBlurTitle => 'Achtergrondvervaging';

  @override
  String get settingNotificationsBlurDescription =>
      'Vervaagt wat door een transparante meldingskaart heen zichtbaar is. Let op: vervaging kan niet over het Home Assistant-dashboard worden toegepast.';

  @override
  String get settingNotificationsChimeFileTitle => 'Meldingsgeluid';

  @override
  String get settingNotificationsChimeFileDescription =>
      'Geluidsbestanden worden op het apparaat gelezen uit Android/data/me.jxl.kiosk_satellite/files/sounds. Deze map is ook bereikbaar via Bestandsbeheer.';

  @override
  String get settingNotificationsVolumeTitle => 'Meldingsvolume';

  @override
  String get settingNotificationsVolumeDescription =>
      'Bepaalt hoe luid het meldingsgeluid wordt afgespeeld, onafhankelijk van het media- en assistentvolume.';

  @override
  String get esphomeNotifications => 'Meldingen';

  @override
  String get esphomeNotificationsHelp =>
      'Transparantie, vervaging, meldingsgeluid, testmelding';

  @override
  String get esphomeAppearance => 'Uiterlijk';

  @override
  String get esphomeSound => 'Geluid';

  @override
  String get esphomeNotificationTest => 'Testmelding';

  @override
  String esphomeNotificationHelp(String action) {
    return 'Meldingen worden vanuit Home Assistant verzonden met de actie $action. Met de testknop toon je een melding over het dashboard.';
  }

  @override
  String get esphomeNotificationBody =>
      'Dit is hoe een melding van Home Assistant eruitziet en klinkt.';

  @override
  String get esphomeNotificationSearch =>
      'De Home Assistant-actie waarmee je meldingen verstuurt en een knop om een testmelding te tonen.';

  @override
  String get esphomeLocation => 'Locatie';

  @override
  String get esphomeLocationSearch =>
      'De locatietoestemming die de locatiesensoren nodig hebben.';

  @override
  String get esphomeBluetoothSearch =>
      'De toestemming voor apparaten in de buurt die de Bluetooth-proxy nodig heeft om te scannen.';

  @override
  String get esphomeLocationMissing =>
      'Zonder dit kan de GPS-ontvanger niet worden gelezen en blijven de locatiesensoren onbekend.';

  @override
  String get esphomeLocationServicesOff =>
      'Locatie is uitgeschakeld in de apparaatinstellingen, waardoor de ontvanger geen gegevens levert.';

  @override
  String get esphomeLocationApproximate =>
      'Alleen de geschatte locatie is toegestaan en de GPS-ontvanger heeft de precieze locatie nodig.';

  @override
  String get esphomeLocationGranted =>
      'De locatiesensoren kunnen de GPS-ontvanger lezen.';

  @override
  String get esphomeBluetoothGranted =>
      'De proxy kan naar Bluetooth-apparaten in de buurt scannen.';

  @override
  String get esphomeBluetoothMissing =>
      'Zonder dit kan de proxy niet naar apparaten scannen.';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android levert alleen Bluetooth-scanresultaten, waaronder bakens, wanneer locatietoegang is verleend. De proxy leest de locatie van het apparaat zelf nooit uit.';

  @override
  String get esphomeBluetoothLocationOff =>
      'Locatie is uitgeschakeld in de apparaatinstellingen. Bluetooth-scans leveren daardoor geen resultaten op.';

  @override
  String get esphomeBluetoothBeacons =>
      'Bluetooth-scans kunnen bakens detecteren.';

  @override
  String get esphomeSent => 'Verzonden';

  @override
  String get esphomeNotsaved => 'Niet opgeslagen';

  @override
  String get settingEsphomeEnabledTitle => 'ESPHome inschakelen';

  @override
  String get settingEsphomeEnabledDescription =>
      'Stel deze kiosk als ESPHome-apparaat beschikbaar aan Home Assistant, met de sensoren en bedieningselementen als systeemeigen entiteiten. De kiosk wordt automatisch ontdekt.';

  @override
  String get settingEsphomeEntitiesTitle =>
      'Kiosk-entiteiten beschikbaar stellen';

  @override
  String get settingEsphomeEntitiesDescription =>
      'Stel de sensoren en bedieningselementen van dit apparaat beschikbaar als ESPHome-entiteiten.';

  @override
  String get settingEsphomeExcludedEntitiesTitle => 'Uitgesloten entiteiten';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      'Kies welke entiteiten je niet aan Home Assistant beschikbaar wilt stellen. Alle overige beschikbare entiteiten worden wel getoond. Na het opslaan maakt ESPHome opnieuw verbinding.';

  @override
  String get settingEsphomeNodeNameTitle => 'Nodenaam';

  @override
  String get settingEsphomeNodeNameDescription =>
      'Geeft deze kiosk een naam op het netwerk. Home Assistant leidt de namen van acties hiervan af. Als je de node hernoemt, worden die acties ook hernoemd.';

  @override
  String get settingEsphomeNodeNamePlaceholder => 'Instellen bij eerste start';

  @override
  String get settingBtproxyKeyTitle => 'Versleutelingssleutel';

  @override
  String get settingBtproxyKeyDescription =>
      'Plak deze sleutel in Home Assistant wanneer om de versleutelingssleutel wordt gevraagd. De sleutel wordt bij de eerste start automatisch gegenereerd.';

  @override
  String get settingBtproxyKeyPlaceholder => 'Gegenereerd bij eerste start';

  @override
  String get settingBtproxyPortTitle => 'API-poort';

  @override
  String get settingBtproxyPortDescription =>
      'De poort waarmee Home Assistant verbinding maakt. Laat dit veld leeg om de ESPHome-standaardpoort 6053 te gebruiken.';

  @override
  String esphomeStartFailed(String error) {
    return 'De ESPHome-server kon niet worden gestart: $error';
  }

  @override
  String get esphomeExcludedInvalid => 'Kies een lijst van entiteits-ID\'s.';

  @override
  String settingsMadeBy(String heart, String author) {
    return 'Gemaakt met $heart door $author';
  }

  @override
  String get settingsBuyCoffee => 'Trakteer me op een koffie';

  @override
  String get settingClapStrictnessTitle => 'Klapdetectie';

  @override
  String get settingClapDetectionDescription =>
      'Strikt vereist luider en gelijkmatiger handgeklap. Grote ruimte geeft handgeklap de tijd om weg te sterven in een galmende ruimte.';

  @override
  String get gestureStrictnessStandard => 'Standaard';

  @override
  String get gestureStrictnessStrict => 'Strikt';

  @override
  String get gestureStrictnessLargeRoom => 'Grote ruimte';

  @override
  String get gestureOff => 'Gebaren zijn uitgeschakeld';

  @override
  String get gestureOffHelp =>
      'Gebaren uitschakelen is actief in de instellingen voor de kioskmodus.';

  @override
  String get gestureEmpty => 'Geen gebaren ingesteld';

  @override
  String get gestureEmptyHelp =>
      'Een gebaar activeert de bijbehorende actie zonder zichtbare bediening.';

  @override
  String get gestureDeleteTooltip => 'Gebaar verwijderen';

  @override
  String get gestureDeleteTitle => 'Gebaar verwijderen?';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return 'Dit gebaar verwijderen? Gebaar: $trigger. Actie: $action.';
  }

  @override
  String get gestureAdd => 'Gebaar toevoegen';

  @override
  String get gestureAddHelp => 'Kies een gebaar en de actie die het activeert.';

  @override
  String get gestureTouchHelp =>
      'Gebaren worden waargenomen, niet geblokkeerd: tikken bereiken ook het dashboard. Hoeken en vormen met meerdere vingers voorkomen dat daar per ongeluk iets wordt geactiveerd.';

  @override
  String get gestureClapper => 'Handgeklap';

  @override
  String get gestureReadFailed => 'Kon de instellingen niet lezen.';

  @override
  String get gestureHandGestures => 'Handgebaren';

  @override
  String get settingHandGestureHoldSecondsTitle => 'Duur van vasthouden';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      'Houd hetzelfde vingergebaar gedurende deze tijd vast voordat de actie wordt uitgevoerd. Verhoog de duur om onbedoelde activering te beperken.';

  @override
  String get gestureHoldInstant => 'Direct';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get haCustomPages => 'Eigen pagina\'s';

  @override
  String get haCustomPagesHintDashboard =>
      'Je eigen HTML-pagina\'s als dashboard';

  @override
  String get settingHaCustomPagesSocketTitle =>
      'Home Assistant-verbinding delen';

  @override
  String get settingHaCustomPagesSocketDescription =>
      'Eigen pagina\'s praten met Home Assistant via de verbinding van de kiosk, zonder token in de pagina.';

  @override
  String get haCustomPagesAdd => 'Pagina toevoegen';

  @override
  String get haCustomPagesEmptyAnyServer =>
      'Voeg HTML-pagina\'s uit de www-map van Home Assistant of van een andere server toe om ze als een dashboard te kiezen.';

  @override
  String get haCustomPagesGuide => 'Handleiding voor eigen pagina\'s';

  @override
  String get haCustomPagesGuideHint =>
      'Zo bouw je een pagina die met Home Assistant praat.';

  @override
  String get haCustomPageAddTitle => 'Eigen pagina toevoegen';

  @override
  String get haCustomPageEditTitle => 'Eigen pagina bewerken';

  @override
  String get haCustomPageName => 'Naam';

  @override
  String get haCustomPageLocation => 'Pad of URL';

  @override
  String get haCustomPageLocationHint =>
      'Een bestand in de www-map van Home Assistant, zoals /local/dashboard.html, of de URL van een pagina op een andere server.';

  @override
  String get haCustomPageNameMissing => 'Voer een naam in.';

  @override
  String get haCustomPageLocationInvalid =>
      'Voer een pad onder /local/ of een http- of https-URL in.';

  @override
  String get haCustomPageDuplicate => 'Een andere pagina gebruikt dit pad al.';

  @override
  String get haCustomPageNotFound =>
      'Home Assistant heeft geen bestand op dit pad.';

  @override
  String get haCustomPageUrlNotFound =>
      'De server heeft geen pagina op deze URL.';

  @override
  String get haCustomPageUnreachable => 'Kan Home Assistant niet bereiken.';

  @override
  String get haCustomPageUrlUnreachable => 'Kan de server niet bereiken.';

  @override
  String haCustomPageStatus(String code) {
    return 'Home Assistant antwoordde met HTTP $code.';
  }

  @override
  String haCustomPageUrlStatus(String code) {
    return 'De server antwoordde met HTTP $code.';
  }

  @override
  String get settingHaHoldModeTitle => 'Wachtstand';

  @override
  String get settingHaHoldModeDescription =>
      'Houd de huidige weergave op het scherm. De schermbeveiliging, dashboardrotatie en timer voor terugkeer naar de startpagina worden gepauzeerd totdat je de wachtstand uitschakelt.';

  @override
  String get settingHaHoldReleaseMinutesTitle =>
      'Wachtstand automatisch beëindigen na';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      'Schakelt de wachtstand automatisch uit na de ingestelde tijd. Stel 0 in om de wachtstand handmatig uit te schakelen.';

  @override
  String get haHoldHint =>
      'Huidige weergave vasthouden, automatisch uitschakelen en menuoptie';

  @override
  String get haNever => 'Nooit';

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
  String get settingDisableSuspendTitle =>
      'Verbinding houden op de achtergrond';

  @override
  String get settingDisableSuspendDescription =>
      'Schakelt de Home Assistant-instelling \"Achtergrondverbindingen onderbreken\" uit. Anders wordt de verbinding enkele minuten nadat het scherm is uitgeschakeld verbroken.';

  @override
  String get settingFreezeOnScreensaverTitle =>
      'Dashboard pauzeren tijdens de schermbeveiliging';

  @override
  String get settingFreezeOnScreensaverDescription =>
      'Stopt met het tekenen van het dashboard zolang de schermbeveiliging ervoor staat, waardoor het CPU- en GPU-gebruik afneemt. De verbinding blijft actief. Geldt niet voor de gedimde schermbeveiliging.';

  @override
  String get settingWsFilterTitle => 'Dashboardupdates filteren';

  @override
  String get settingWsFilterDescription =>
      'Verwerk alleen updates voor entiteiten in de huidige weergave om haperingen op minder krachtige tablets te beperken. Weergaven die niet kunnen worden bepaald, blijven ongefilterd.';

  @override
  String get settingPauseDashboardCamerasTitle =>
      'HA-camerastreams pauzeren tijdens de schermbeveiliging';

  @override
  String get settingPauseDashboardCamerasDescription =>
      'Pauzeert ondersteunde, gedempte camerastreams op het Home Assistant-dashboard zolang de schermbeveiliging actief is. De streams maken daarna opnieuw verbinding. Dit heeft geen invloed op de apparaatcamera of de functie Camerastreams.';

  @override
  String get haOptimizations => 'Optimalisaties';

  @override
  String get haOptimizationsHint =>
      'Achtergrondverbinding, dashboard en camerapauze, updatefilter';

  @override
  String get haScanUnavailable =>
      'Scangegevens zijn niet beschikbaar voor de huidige weergave.';

  @override
  String get haScanDetails => 'Scangegevens van dashboard';

  @override
  String haWatchedTitle(String count) {
    return 'Gevolgde entiteiten ($count)';
  }

  @override
  String get haWatched => 'Gevolgde entiteiten';

  @override
  String get haEntityListUnavailable =>
      'De lijst met entiteiten is nu niet beschikbaar.';

  @override
  String haWatching(String count) {
    return 'Er worden $count entiteiten in deze weergave gevolgd.';
  }

  @override
  String get haNoUpdates => 'Geen updates in de afgelopen minuut.';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return '$percent% van de updates in de afgelopen minuut gefilterd ($dropped van $total).';
  }

  @override
  String get haRawUpdates =>
      'Een onderdeel op deze pagina ontvangt toch elke entiteitsupdate, waardoor filteren hier minder bespaart.';

  @override
  String get haAllStates =>
      'Deze weergave leest de status van alle entiteiten. Updates worden daarom niet gefilterd.';

  @override
  String get haUnknownEntities =>
      'De entiteiten in deze weergave kunnen niet worden bepaald. Updates worden daarom niet gefilterd.';

  @override
  String get haWaiting => 'Wachten tot het dashboard is geladen…';

  @override
  String get haShowScan => 'Scangegevens tonen.';

  @override
  String haThreshold(String count) {
    return 'Deze weergave gebruikt $count entiteiten en overschrijdt daarmee de filterdrempel. Filteren is uitgeschakeld.';
  }

  @override
  String get haCustomPageFilter => 'Niet gebruikt op eigen pagina\'s.';

  @override
  String get settingHaReturnHomeEnabledTitle =>
      'Terugkeren naar de startweergave van het dashboard';

  @override
  String get settingHaReturnHomeEnabledDescription =>
      'Keer na een periode van inactiviteit terug naar het hierboven ingestelde dashboard.';

  @override
  String get settingHaReturnHomeSecondsTitle => 'Terugkeer na (seconden)';

  @override
  String get settingHaReturnHomeSecondsDescription =>
      'Inactiviteitsperiode voordat de kiosk teruggaat.';

  @override
  String get haReturnHint => 'Na inactiviteit terugkeren naar de startweergave';

  @override
  String get haReturnDisabled =>
      'Uitgeschakeld zolang dashboardrotatie actief is.';

  @override
  String get haReturnNoPath =>
      'Het ingestelde dashboard heeft geen weergavepad om naar terug te keren.';

  @override
  String haReturnPath(String path) {
    return 'Keert na de time-out terug naar \"$path\".';
  }

  @override
  String get settingHaRotationEnabledTitle => 'Dashboardrotatie inschakelen';

  @override
  String get settingHaRotationEnabledDescription =>
      'Doorloop de geselecteerde dashboardweergaven voortdurend en toon elke weergave gedurende het gekozen aantal seconden.';

  @override
  String get settingHaRotationSecondsTitle => 'Seconden per weergave';

  @override
  String get settingHaRotationSecondsDescription =>
      'Hoelang elke weergave in beeld blijft.';

  @override
  String get settingHaRotationPauseSecondsTitle =>
      'Rotatie pauzeren na interactie (seconden)';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      'Een aanraking pauzeert de rotatie gedurende deze tijd en start het aftellen opnieuw. Spraakinteracties pauzeren de rotatie totdat ze zijn afgelopen. Bij 0 blijft de rotatie actief tijdens aanrakingen.';

  @override
  String get settingHaRotationCrossfadeTitle => 'Overgang tussen weergaven';

  @override
  String get settingHaRotationCrossfadeDescription =>
      'Laat de huidige weergave via de achtergrond overvloeien in de volgende, in plaats van direct te wisselen. Bij een ander dashboard of een externe pagina wordt nog steeds direct gewisseld.';

  @override
  String get settingHaRotationFadeSecondsTitle =>
      'Duur van overgang (seconden)';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      'Totale duur van het uit- en infaden. Het laden van de volgende weergave kan extra tijd kosten, vooral de eerste keer.';

  @override
  String get haRotation => 'Dashboardrotatie';

  @override
  String get haRotationHint => 'Weergaven doorlopen, weergaveduur en overgang';

  @override
  String get haExternalPages => 'Externe pagina\'s';

  @override
  String get haFadeError => 'Kies een vervagingsduur van 0,2 tot 5 seconden.';

  @override
  String get haPauseRemoteHelp =>
      'Een aanraking pauzeert de rotatie gedurende deze tijd en start de timer opnieuw. Spraakinteracties pauzeren altijd totdat ze zijn afgelopen. Bij 0 blijft de rotatie actief.';

  @override
  String get settingHaUrlTitle => 'Basis-URL van Home Assistant';

  @override
  String get settingHaUrlDescription =>
      'Bijvoorbeeld https://homeassistant.local:8123, zonder dashboardpad.';

  @override
  String get settingHaTokenTitle => 'Langdurig toegangstoken';

  @override
  String get settingHaTokenDescription =>
      'Aangemaakt via je HA-profiel > Beveiliging.';

  @override
  String get settingHaAutoLoginTitle => 'Automatisch aanmelden';

  @override
  String get settingHaAutoLoginDescription =>
      'Meld je met het bovenstaande toegangstoken aan bij het dashboard, zonder de aanmeldpagina van Home Assistant te tonen.';

  @override
  String get haValidate => 'Controleren';

  @override
  String get haValidateConnection => 'Verbinding controleren';

  @override
  String get haChecking => 'Controleren…';

  @override
  String get haConnected => 'Verbonden';

  @override
  String get haConnectedRemote => 'Verbonden.';

  @override
  String get haNotValidated =>
      'Nog niet gecontroleerd. De onderstaande instellingen worden beschikbaar zodra de verbinding werkt.';

  @override
  String get haConnectFailed => 'Kon geen verbinding maken.';

  @override
  String get haNotConfigured =>
      'Home Assistant-URL en token zijn niet ingesteld';

  @override
  String get haInvalidToken => 'ongeldig token';

  @override
  String haUnreachable(String error) {
    return 'Kon Home Assistant niet bereiken: $error';
  }

  @override
  String get haProxy => 'Beveiligde contextproxy';

  @override
  String get haProxyHelp =>
      'Leidt een Home Assistant-verbinding via http door een proxy in de app, zodat de browser de microfoon en andere functies die https vereisen beschikbaar maakt. Alleen voor http-URL\'s.';

  @override
  String get haProxyRemoteHelp =>
      'Leidt een Home Assistant op gewone http via een proxy in de app, zodat de browser de microfoon en andere functies die https vereisen vrijgeeft. Alleen beschikbaar voor http-URL\'s.';

  @override
  String get haProxyNotice =>
      'Deze Home Assistant-URL gebruikt gewone http, en browsers blokkeren de microfoon en andere functies op http-pagina\'s. Kiosk Satellite leidt het dashboard via een beveiligde proxy in de app zodat alles werkt. Mogelijk moet je je opnieuw aanmelden bij Home Assistant.';

  @override
  String get haProxyRemoteNotice =>
      'Deze Home Assistant-URL gebruikt gewone http, en browsers blokkeren de microfoon en andere functies op http-pagina\'s. Kiosk Satellite leidt het dashboard via een beveiligde proxy in de app zodat alles werkt. Mogelijk moet je je op de tablet opnieuw aanmelden bij Home Assistant.';

  @override
  String get haDashboard => 'Dashboard';

  @override
  String get haChooseView => 'Een weergave kiezen';

  @override
  String get settingHaThemeTitle => 'Thema';

  @override
  String get settingHaThemeDescription =>
      'Kies een licht of donker thema voor het Home Assistant-dashboard. Je kunt dit ook instellen via de thema-entiteit in Home Assistant. Bij \'Automatisch\' worden de onderstaande instellingen gevolgd.';

  @override
  String get settingThemeMatchAppTitle =>
      'Home Assistant-thema afstemmen op Kiosk Satellite';

  @override
  String get settingThemeMatchAppDescription =>
      'Stem het Home Assistant-thema automatisch af op het thema van Kiosk Satellite.';

  @override
  String get settingThemeAutoTitle => 'Thema aanpassen aan het tijdstip';

  @override
  String get settingThemeAutoDescription =>
      'Schakel Home Assistant volgens een schema tussen licht en donker. Het gekozen thema blijft behouden; alleen de lichte of donkere variant verandert.';

  @override
  String get settingThemeDarkAtTitle => 'Donker thema vanaf';

  @override
  String get settingThemeDarkAtDescription =>
      'Lokale tijd om over te stappen op het donkere thema.';

  @override
  String get settingThemeLightAtTitle => 'Licht thema vanaf';

  @override
  String get settingThemeLightAtDescription =>
      'Lokale tijd om terug te schakelen naar het lichte thema.';

  @override
  String get settingThemeAutoAppTitle => 'Ook het app-thema wijzigen';

  @override
  String get settingThemeAutoAppDescription =>
      'Wijzig tegelijk met Home Assistant ook het thema van Kiosk Satellite, inclusief het menu en de instellingen.';

  @override
  String get haThemeHint =>
      'Afstemmen op de app of volgens een schema wisselen tussen een licht en donker thema';

  @override
  String get haThemeAuto => 'Automatisch';

  @override
  String get settingHaKioskModeTitle => 'HA kioskmodus';

  @override
  String get settingHaKioskModeDescription =>
      'Verberg de kopbalk en zijbalk van Home Assistant. Dit wordt direct toegepast.';

  @override
  String get settingHaKioskHideHeaderTitle => 'Kopbalk verbergen';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'Verberg de dashboardwerkbalk en tabbladen met weergaven zolang de HA-kioskmodus actief is. Schakel dit niet in als je via de kopbalk tussen weergaven wisselt.';

  @override
  String get settingHaKioskHideSidebarTitle => 'Zijbalk verbergen';

  @override
  String get settingHaKioskHideSidebarDescription =>
      'Verberg de navigatiezijbalk zolang de HA-kioskmodus actief is.';

  @override
  String get settingHaDashboardCarouselTitle =>
      'Dashboardcarrousel inschakelen';

  @override
  String get settingHaDashboardCarouselDescription =>
      'Veeg op het dashboard naar links of rechts om tussen de weergaven te wisselen. Veegbewegingen op schuifregelaars, plattegronden en kaarten waarin je kunt scrollen blijven ongemoeid.';

  @override
  String get settingHaCarouselOverCardsTitle =>
      'Veegbewegingen boven kaarten opvangen';

  @override
  String get settingHaCarouselOverCardsDescription =>
      'Wissel ook van weergave als je begint te vegen op een kaart die zelf op veegbewegingen reageert. Schuifregelaars blijven normaal werken.';

  @override
  String get settingHaHapticsTitle => 'Haptische feedback inschakelen';

  @override
  String get settingHaHapticsDescription =>
      'Geef een trilsignaal bij het gebruik van knoppen, schakelaars, kaarten, schuifregelaars en thermostaatregelaars. Hiervoor is een trilmechanisme vereist.';

  @override
  String get settingHaHapticsStrengthTitle => 'Trillingssterkte';

  @override
  String get settingHaHapticsStrengthDescription =>
      'Hoe sterk de trilling aanvoelt.';

  @override
  String get settingHaTapSoundTitle => 'Tikgeluiden afspelen';

  @override
  String get settingHaTapSoundDescription =>
      'Speel het standaard tikgeluid af bij het gebruik van knoppen, schakelaars, kaarten, schuifregelaars en thermostaatknoppen.';

  @override
  String get settingHaTapSoundVolumeTitle => 'Volume van tikgeluid';

  @override
  String get settingHaTapSoundVolumeDescription =>
      'Hoe luid het tikgeluid wordt afgespeeld.';

  @override
  String get haUserInterface => 'Gebruikersinterface';

  @override
  String get haInterfaceHint =>
      'Kioskmodus, dashboardcarrousel, haptiek en tikgeluiden';

  @override
  String get haHaptics => 'Haptische feedback';

  @override
  String get haVibrationLight => 'Zwak';

  @override
  String get haVibrationMedium => 'Gemiddeld';

  @override
  String get haVibrationStrong => 'Krachtig';

  @override
  String get settingHomeLauncherEnabledTitle => 'Als startscherm gebruiken';

  @override
  String get settingHomeLauncherEnabledDescription =>
      'Registreer Kiosk Satellite als startscherm van het apparaat. De kiosk start tijdens het opstarten en iedere druk op de startknop keert ernaar terug. Als de app herhaaldelijk niet kan starten, wordt deze optie automatisch uitgeschakeld en het vorige startscherm hersteld.';

  @override
  String get settingHomeKeepPinningTitle => 'Schermvastzetting behouden';

  @override
  String get settingHomeKeepPinningDescription =>
      'Zet het scherm ook vast wanneer Kiosk Satellite het startscherm is. Dit blokkeert de recente apps en terugknop via Android, maar toont op apparaten zonder apparaateigenaarschap opnieuw het bevestigingsvenster voor schermvastzetting.';

  @override
  String get kioskHomeScreen => 'Startscherm';

  @override
  String get kioskCheckingDevice => 'Apparaat controleren...';

  @override
  String get kioskFireOs =>
      'Fire OS staat niet toe dat het startscherm wordt vervangen.';

  @override
  String get kioskUnsupported =>
      'Dit apparaat staat het wijzigen van het startscherm niet toe.';

  @override
  String get kioskRecovered =>
      'Automatisch uitgeschakeld na meerdere mislukte starts. Het vorige startscherm is hersteld. Schakel de optie opnieuw in om het nogmaals te proberen.';

  @override
  String get kioskHeld =>
      'Kiosk Satellite is het startscherm. De kiosk wordt tijdens het opstarten geopend en iedere druk op de startknop keert ernaar terug.';

  @override
  String get kioskDisabled =>
      'Niet ingesteld als startscherm. Schakel hierboven Als startscherm gebruiken in.';

  @override
  String get kioskWaiting =>
      'Nog niet het huidige startscherm: het apparaat wacht op een bevestiging.';

  @override
  String get kioskOpenHomeSettings => 'Startscherminstellingen openen';

  @override
  String get kioskSetDefault => 'Standaard instellen';

  @override
  String get kioskActive => 'Actief';

  @override
  String get kioskNotHome => 'Niet ingesteld als startscherm.';

  @override
  String get kioskWaitingRemote =>
      'Wachten op bevestiging op het apparaat. Daar wordt het systeemvenster of de startscherminstelling geopend.';

  @override
  String get kioskSetDevice => 'Instellen op apparaat';

  @override
  String get settingIntercomAnswerModeTitle => 'Antwoordmodus';

  @override
  String get settingIntercomAnswerModeDescription =>
      'Overgaan toont een vraag op het scherm. Automatisch opnemen opent het gesprek na een beltoon.';

  @override
  String get settingIntercomRingSecondsTitle => 'Overgaan gedurende';

  @override
  String get settingIntercomRingSecondsDescription =>
      'Hoelang een oproep overgaat voordat deze als gemist wordt beschouwd.';

  @override
  String get settingIntercomRingSoundTitle => 'Beltoon';

  @override
  String get settingIntercomRingSoundDescription =>
      'Speelt af bij het meldingsvolume.';

  @override
  String get settingIntercomAcceptAnnouncementsTitle =>
      'Omroepberichten toestaan';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      'Speel berichten af die vanaf andere kiosken naar alle kiosken worden omgeroepen.';

  @override
  String get intercomOptionAnswerRing => 'Overgaan';

  @override
  String get intercomOptionAnswerAuto => 'Automatisch opnemen';

  @override
  String get intercomOptionAnswerDnd => 'Niet storen';

  @override
  String get intercomOptionAnswer15 => '15 seconden';

  @override
  String get intercomOptionAnswer30 => '30 seconden';

  @override
  String get intercomOptionAnswer45 => '45 seconden';

  @override
  String get intercomOptionAnswer60 => '60 seconden';

  @override
  String get intercomAnswerSection => 'Opnemen';

  @override
  String get settingIntercomEnabledTitle => 'Intercom inschakelen';

  @override
  String get settingIntercomEnabledDescription =>
      'Bel andere kiosken op dit netwerk en neem hun oproepen aan.';

  @override
  String get settingIntercomKeyTitle => 'Intercomsleutel';

  @override
  String get settingIntercomKeyDescription =>
      'Kiosken met dezelfde sleutel kunnen elkaar bellen. Vlootbeheer kan de sleutel synchroniseren.';

  @override
  String get settingIntercomKeyPlaceholder =>
      'Gemaakt wanneer de intercom is ingeschakeld';

  @override
  String get intercomNeedsAdmin => 'De intercom vereist beheer op afstand';

  @override
  String get intercomAdminHelp =>
      'Kiosken vinden en bereiken elkaar via beheer op afstand. Schakel onder Apparaat de opties Beheer op afstand en Andere kiosken zoeken in en kom daarna terug.';

  @override
  String get intercomChangeKey => 'Sleutel wijzigen';

  @override
  String get intercomChangeKeyHelp =>
      'Plak de sleutel van een andere kiosk, of maak een nieuwe.';

  @override
  String get intercomChange => 'Wijzigen';

  @override
  String get intercomKeyWarning =>
      'Kiosken met deze sleutel kunnen elkaar bellen. Een nieuwe sleutel snijdt deze kiosk af van de anderen totdat ze het ook krijgen.';

  @override
  String get intercomRegenerate => 'Opnieuw genereren';

  @override
  String get intercomKeyChanged => 'Sleutel gewijzigd';

  @override
  String get intercomNotSet => 'Niet ingesteld';

  @override
  String get intercomOpen => 'Openen';

  @override
  String get settingIntercomTlsTitle => 'Communicatie versleutelen';

  @override
  String get settingIntercomTlsDescription =>
      'Gebruik TLS om intercomgesprekken tussen kiosken te versleutelen. Dit moet zijn ingeschakeld op alle kiosken in het gesprek.';

  @override
  String get intercomKiosks => 'Kiosken';

  @override
  String get intercomRosterHelp =>
      'Gevonden kiosken en opgeslagen vlootleden. Een kiosk is beschikbaar wanneer deze bereikbaar is, de intercom is ingeschakeld en de sleutel en versleutelingsinstellingen overeenkomen.';

  @override
  String get intercomNoOther => 'Geen andere kiosken gevonden';

  @override
  String get intercomRosterDeviceHelp =>
      'Kiosken waarop Beheer op afstand en Andere kiosken zoeken zijn ingeschakeld, verschijnen hier.';

  @override
  String get intercomNoneHeard => 'Geen kiosken gevonden';

  @override
  String get intercomRosterRemoteHelp =>
      'Kiosken verschijnen via netwerkdetectie of een opgeslagen vlootlidmaatschap. Beheer op afstand en Andere kiosken zoeken moeten zijn ingeschakeld.';

  @override
  String get intercomReady => 'Beschikbaar';

  @override
  String get intercomOff => 'Intercom uit';

  @override
  String get intercomDifferentKey => 'Andere intercomsleutel';

  @override
  String get intercomUnreachable => 'Onbereikbaar';

  @override
  String get intercomOffline => 'Offline';

  @override
  String get intercomChecking => 'Controleren…';

  @override
  String get settingIntercomTalkModeTitle => 'Spreekmodus';

  @override
  String get settingIntercomTalkModeDescription =>
      'Bij Indrukken om te praten wordt audio verzonden zolang je de knop vasthoudt. Handsfree houdt de microfoon tijdens het hele gesprek open.';

  @override
  String get intercomOptionTalkPtt => 'Indrukken om te praten';

  @override
  String get intercomOptionTalkHandsfree => 'Handsfree';

  @override
  String get settingIntercomMaxCallMinutesTitle => 'Maximale gespreksduur';

  @override
  String get settingIntercomMaxCallMinutesDescription =>
      'Gesprekken stoppen vanzelf na deze tijd.';

  @override
  String get intercomOptionCallUnlimited => 'Onbeperkt';

  @override
  String get intercomOptionCall1 => '1 minuut';

  @override
  String get intercomOptionCall2 => '2 minuten';

  @override
  String get intercomOptionCall5 => '5 minuten';

  @override
  String get intercomOptionCall10 => '10 minuten';

  @override
  String get intercomOptionCall15 => '15 minuten';

  @override
  String get intercomOptionCall20 => '20 minuten';

  @override
  String get intercomOptionCall30 => '30 minuten';

  @override
  String get intercomOptionCall45 => '45 minuten';

  @override
  String get intercomOptionCall60 => '60 minuten';

  @override
  String get settingIntercomHangupKeyTitle =>
      'Gesprek beëindigen met deze knop';

  @override
  String get settingIntercomHangupKeyDescription =>
      'Tijdens een gesprek beëindigt de knop het gesprek in plaats van zijn gewone functie.';

  @override
  String get intercomOptionHangupOff => 'Uitgeschakeld';

  @override
  String get intercomOptionHangupVolumeUp => 'Volume omhoog';

  @override
  String get intercomOptionHangupVolumeDown => 'Volume omlaag';

  @override
  String get intercomOptionHangupMute => 'Dempen';

  @override
  String get intercomOptionHangupHelp => 'Hulp';

  @override
  String get settingIntercomHangupKeyRingingTitle =>
      'Ophangknop tijdens overgaan';

  @override
  String get settingIntercomHangupKeyRingingDescription =>
      'Wat de knop doet als hier een gesprek binnenkomt.';

  @override
  String get intercomOptionHangupRingingAnswer => 'Aannemen';

  @override
  String get intercomOptionHangupRingingDecline => 'Afwijzen';

  @override
  String get intercomOptionHangupRingingIgnore => 'Negeren';

  @override
  String get intercomTalkSection => 'Praten';

  @override
  String get settingIntercomVideoTitle => 'Video-oproepen';

  @override
  String get settingIntercomVideoDescription =>
      'Verzendt en toont video tijdens gesprekken.';

  @override
  String get settingIntercomVideoQualityTitle => 'Videokwaliteit';

  @override
  String get settingIntercomVideoQualityDescription =>
      'Hogere kwaliteit gebruikt meer CPU.';

  @override
  String get intercomOptionVideoLow => 'Laag';

  @override
  String get intercomOptionVideoMedium => 'Gemiddeld';

  @override
  String get intercomOptionVideoHigh => 'Hoog';

  @override
  String get intercomVideoSection => 'Video';

  @override
  String get settingIntercomAutoAnswerCameraTitle => 'Opnemen met camera aan';

  @override
  String get settingIntercomAutoAnswerCameraDescription =>
      'Automatisch opgenomen video-oproepen starten met de camera aan.';

  @override
  String get settingKioskAllowDrawerTitle => 'Menu toestaan met snelle acties';

  @override
  String get settingKioskAllowDrawerDescription =>
      'Een veegbeweging vanaf de rand opent het menu zonder afsluitgebaar of pincode. Alleen de hieronder geselecteerde acties zijn beschikbaar.';

  @override
  String get settingKioskAllowDashboardTitle => 'Dashboard';

  @override
  String get settingKioskAllowDashboardDescription => 'Herlaad de startpagina.';

  @override
  String get settingKioskAllowHaKioskTitle => 'HA Kioskmodus';

  @override
  String get settingKioskAllowHaKioskDescription =>
      'De kop- en zijbalk van Home Assistant tonen of verbergen.';

  @override
  String get settingKioskAllowCameraTitle => 'Cameraweergave';

  @override
  String get settingKioskAllowCameraDescription =>
      'Open de standaard cameraweergave.';

  @override
  String get settingKioskAllowIntercomTitle => 'Intercom';

  @override
  String get settingKioskAllowIntercomDescription =>
      'Bel andere kiosken vanuit het kioskmenu.';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription =>
      'Open de webinterface van Music Assistant.';

  @override
  String get settingKioskAllowSendspinPlayerTitle => 'Zwevende speler';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      'Toon of verberg de zwevende speler en open Speelt nu.';

  @override
  String get settingKioskAllowScreensaverTitle => 'Schermbeveiliging starten';

  @override
  String get settingKioskAllowScreensaverDescription =>
      'Start de schermbeveiliging nu.';

  @override
  String get settingKioskAllowHoldTitle => 'Wachtstand';

  @override
  String get settingKioskAllowHoldDescription =>
      'Zet de wachtstand aan of uit.';

  @override
  String get settingKioskAllowLockdownTitle => 'Vergrendelingsmodus';

  @override
  String get settingKioskAllowLockdownDescription =>
      'Vergrendel het scherm totdat het afsluitgebaar wordt gebruikt of het scherm op afstand wordt ontgrendeld.';

  @override
  String get settingKioskAllowThemeTitle => 'Themakiezer';

  @override
  String get settingKioskAllowThemeDescription =>
      'Schakelen tussen de lichte en donkere thema\'s.';

  @override
  String get settingKioskAllowAppsTitle => 'Apps';

  @override
  String get settingKioskAllowAppsDescription =>
      'Open de appstarter. Als Thuisknop uitschakelen actief is, wordt de kiosk bij het openen van een app losgemaakt totdat de app terugkeert.';

  @override
  String get kioskAllowedActions => 'Toegestane acties';

  @override
  String get kioskAllowedHelp =>
      'De snelle acties die in het kioskmenu beschikbaar zijn';

  @override
  String get settingKioskAllowedAppsTitle => 'Toegestane apps';

  @override
  String get settingKioskAllowedAppsDescription =>
      'De apps van de appstarter die beschikbaar zijn terwijl de kioskmodus aan staat.';

  @override
  String get kioskAllowedAppsEmpty =>
      'Voeg eerst apps toe in Instellingen > Appstarter.';

  @override
  String get settingKioskEnabledTitle => 'Kioskmodus inschakelen';

  @override
  String get settingKioskEnabledDescription =>
      'Vergrendel de tablet in Kiosk Satellite. De veegbeweging voor het menu wordt vervangen door het afsluitgebaar, de terugknop blijft binnen de kiosk en de onderstaande beveiligingen worden actief.';

  @override
  String get settingKioskStartOnBootTitle => 'Starten bij opstarten';

  @override
  String get settingKioskStartOnBootDescription =>
      'Start Kiosk Satellite wanneer het apparaat wordt ingeschakeld. Op Android 10 of hoger is hiervoor toestemming voor weergave over andere apps vereist. Android vraagt hierom wanneer je de optie voor het eerst inschakelt.';

  @override
  String get settingKioskExitGestureTitle => 'Afsluitgebaar voor kioskmodus';

  @override
  String get settingKioskExitGestureDescription =>
      'Tik snel ergens op het scherm om het menu te openen, zo nodig na het invoeren van de pincode. Bij varianten met vasthouden moet de laatste tik ingedrukt blijven. Als dit is uitgeschakeld, zijn de instellingen alleen via beheer op afstand bereikbaar.';

  @override
  String get settingKioskPinTitle => 'Pincode voor kioskmodus';

  @override
  String get settingKioskPinDescription =>
      'Wordt na het afsluitgebaar gevraagd voordat het menu opent. Laat het veld leeg om geen pincode te gebruiken.';

  @override
  String get settingKioskDisableStatusBarTitle => 'Statusbalk uitschakelen';

  @override
  String get settingKioskDisableStatusBarDescription =>
      'Blokkeer het omlaagtrekken van de statusbalk met een afscherming langs de bovenrand. Hiervoor is toestemming voor weergave over andere apps vereist. Android vraagt hierom wanneer je de optie voor het eerst inschakelt.';

  @override
  String get settingKioskDisableVolumeTitle => 'Volumeknoppen uitschakelen';

  @override
  String get settingKioskDisableVolumeDescription =>
      'Negeer de fysieke volumeknoppen.';

  @override
  String get settingKioskDisablePowerTitle => 'Aan-uitknop uitschakelen';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android kan de aan-uitknop niet blokkeren, dus het scherm wordt direct weer ingeschakeld wanneer je die indrukt. Het scherm op afstand uitschakelen werkt nog wel.';

  @override
  String get settingKioskDisableHomeTitle => 'Thuisknop uitschakelen';

  @override
  String get settingKioskDisableHomeDescription =>
      'Zet de app vast met Android-schermvastzetting, waardoor de startknop en recente apps worden geblokkeerd. Android vraagt de eerste keer om bevestiging.';

  @override
  String get settingKioskDisableContextMenusTitle =>
      'Contextmenu\'s uitschakelen';

  @override
  String get settingKioskDisableContextMenusDescription =>
      'Onderdruk menu\'s bij lang indrukken en tekstselectie binnen de webweergave.';

  @override
  String get settingKioskDisablePullRefreshTitle =>
      'Trekken om te vernieuwen uitschakelen';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Negeer het gebaar om te vernieuwen zolang de kioskmodus actief is.';

  @override
  String get settingKioskDisableGesturesTitle => 'Gebaren uitschakelen';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Negeer de gebaren van de pagina Gebaren zolang de kioskmodus aanstaat.';

  @override
  String get kioskGestureTaps5 => '5 snelle tikken';

  @override
  String get kioskGestureTaps7 => '7 snelle tikken';

  @override
  String get kioskGestureTaps5Hold => '5 snelle tikken, laatste vasthouden';

  @override
  String get kioskGestureTaps7Hold => '7 snelle tikken, laatste vasthouden';

  @override
  String get kioskGestureNone => 'Uitgeschakeld (alleen beheer op afstand)';

  @override
  String get kioskForeground =>
      'Kiosk Satellite kan zichzelf weer naar de voorgrond brengen.';

  @override
  String get kioskOverlayMissing =>
      'Zonder dit kan de kiosk zichzelf niet terugbrengen en dekt het vergrendelingsschild alleen de app.';

  @override
  String get kioskGuardHeld =>
      'Het meldingenpaneel en de recente apps sluiten automatisch zolang het scherm wordt beveiligd.';

  @override
  String get kioskGuardMissing =>
      'Zonder deze toestemming blijven het meldingenpaneel en de recente apps bereikbaar. Schakel Kiosk Satellite in onder Toegankelijkheid.';

  @override
  String get kioskOverlayRemote =>
      'Zonder dit kan de kiosk zichzelf niet terugbrengen. Het toestemmingsscherm verschijnt op de tablet.';

  @override
  String get kioskGuardRemote =>
      'Zonder deze toestemming blijven het meldingenpaneel en de recente apps bereikbaar. Schakel Kiosk Satellite op de tablet in onder Toegankelijkheid.';

  @override
  String get kioskGrantDevice => 'Toestaan op apparaat';

  @override
  String get kioskOpenSettingsDevice => 'Instellingen openen op apparaat';

  @override
  String get settingLedEnabledTitle => 'LED-bediening inschakelen';

  @override
  String get settingLedEnabledDescription =>
      'Laat Kiosk Satellite de lampjes bedienen.';

  @override
  String get settingLedAnimationsTitle => 'Effecten animeren';

  @override
  String get settingLedAnimationsDescription =>
      'Laat de bogen draaien en de pulsen vervagen. Zet dit uit om alle effecten stil te zetten.';

  @override
  String get settingLedIdleEnabledTitle => 'Branden bij inactiviteit';

  @override
  String get settingLedIdleEnabledDescription =>
      'Blijft branden zolang er niets anders wordt getoond.';

  @override
  String get settingLedIdleBrightnessTitle => 'Helderheid';

  @override
  String get settingLedIdleBrightnessDescription =>
      'Hoe fel de lampjes hiervoor branden.';

  @override
  String get settingLedIdleLightColorTitle => 'Kleur';

  @override
  String get settingLedIdleLightColorDescription =>
      'De kleur van de lampjes hiervoor.';

  @override
  String get settingLedIdleStyleTitle => 'Effect';

  @override
  String get settingLedIdleStyleDescription =>
      'Hoe de lampjes er bij inactiviteit uitzien.';

  @override
  String get settingLedIdleStyleOptionSolid => 'Vast';

  @override
  String get settingLedIdleStyleOptionBreathe => 'Ademend';

  @override
  String get settingLedVoiceEnabledTitle => 'Spraakactiviteit tonen';

  @override
  String get settingLedVoiceEnabledDescription =>
      'Licht op terwijl Voice Satellite luistert, nadenkt en antwoordt.';

  @override
  String get settingLedVoiceBrightnessTitle => 'Helderheid';

  @override
  String get settingLedVoiceBrightnessDescription =>
      'Hoe fel de lampjes hiervoor branden.';

  @override
  String get settingLedVoiceLightColorTitle => 'Kleur';

  @override
  String get settingLedVoiceLightColorDescription =>
      'Onder een boog die draait tijdens het luisteren, wisselt tijdens het nadenken en vervaagt tijdens het antwoorden.';

  @override
  String get settingLedVoiceAccentColorTitle => 'Accentkleur';

  @override
  String get settingLedVoiceAccentColorDescription =>
      'De boog die rond de lampjes beweegt.';

  @override
  String get settingLedVoiceMutedTitle => 'Tonen als gedempt';

  @override
  String get settingLedVoiceMutedDescription =>
      'Blijft branden zolang Voice Satellite gedempt is.';

  @override
  String get settingLedVoiceMutedColorTitle => 'Kleur bij dempen';

  @override
  String get settingLedVoiceMutedColorDescription =>
      'De kleur van de lampjes als gedempt.';

  @override
  String get settingLedTimersEnabledTitle => 'Timers tonen';

  @override
  String get settingLedTimersEnabledDescription =>
      'Pulseert terwijl een timer afgaat.';

  @override
  String get settingLedTimersBrightnessTitle => 'Helderheid';

  @override
  String get settingLedTimersBrightnessDescription =>
      'Hoe fel de lampjes hiervoor branden.';

  @override
  String get settingLedTimersLightColorTitle => 'Kleur';

  @override
  String get settingLedTimersLightColorDescription =>
      'De kleur van de lampjes hiervoor.';

  @override
  String get settingLedTimersCountdownTitle => 'Aftellen tonen';

  @override
  String get settingLedTimersCountdownDescription =>
      'De lampjes gaan een voor een uit terwijl de volgende timer afloopt.';

  @override
  String get settingLedAlarmsEnabledTitle => 'Alarmen tonen';

  @override
  String get settingLedAlarmsEnabledDescription =>
      'Pulseert terwijl een alarm afgaat.';

  @override
  String get settingLedAlarmsBrightnessTitle => 'Helderheid';

  @override
  String get settingLedAlarmsBrightnessDescription =>
      'Hoe fel de lampjes hiervoor branden.';

  @override
  String get settingLedAlarmsLightColorTitle => 'Kleur';

  @override
  String get settingLedAlarmsLightColorDescription =>
      'De kleur van de lampjes hiervoor.';

  @override
  String get settingLedIntercomEnabledTitle => 'Intercomgesprekken tonen';

  @override
  String get settingLedIntercomEnabledDescription =>
      'Pulseert terwijl een gesprek overgaat en draait zolang het loopt.';

  @override
  String get settingLedIntercomBrightnessTitle => 'Helderheid';

  @override
  String get settingLedIntercomBrightnessDescription =>
      'Hoe fel de lampjes hiervoor branden.';

  @override
  String get settingLedIntercomLightColorTitle => 'Kleur';

  @override
  String get settingLedIntercomLightColorDescription =>
      'De kleur van de lampjes hiervoor.';

  @override
  String get settingLedNotificationsEnabledTitle => 'Meldingen tonen';

  @override
  String get settingLedNotificationsEnabledDescription =>
      'Pulseert langzaam zolang er een melding wacht.';

  @override
  String get settingLedNotificationsBrightnessTitle => 'Helderheid';

  @override
  String get settingLedNotificationsBrightnessDescription =>
      'Hoe fel de lampjes hiervoor branden.';

  @override
  String get settingLedNotificationsLightColorTitle => 'Kleur';

  @override
  String get settingLedNotificationsLightColorDescription =>
      'De kleur van de lampjes hiervoor.';

  @override
  String get settingLedMediaEnabledTitle => 'Muziek tonen';

  @override
  String get settingLedMediaEnabledDescription =>
      'Licht op terwijl er muziek speelt op dit apparaat.';

  @override
  String get settingLedMediaBrightnessTitle => 'Helderheid';

  @override
  String get settingLedMediaBrightnessDescription =>
      'Hoe fel de lampjes hiervoor branden.';

  @override
  String get settingLedMediaLightColorTitle => 'Kleur';

  @override
  String get settingLedMediaLightColorDescription =>
      'De kleur van de lampjes hiervoor.';

  @override
  String get settingLedMediaStyleTitle => 'Effect';

  @override
  String get settingLedMediaStyleDescription => 'Hoe de lampjes muziek tonen.';

  @override
  String get settingLedMediaStyleOptionSolid => 'Vast';

  @override
  String get settingLedMediaStyleOptionBreathe => 'Ademend';

  @override
  String get settingLockdownEnabledTitle => 'Vergrendelingsmodus inschakelen';

  @override
  String get settingLockdownEnabledDescription =>
      'Blokkeer interacties met het scherm totdat de modus via Home Assistant of met het afsluitgebaar wordt uitgeschakeld.';

  @override
  String get settingLockdownBlackoutTitle => 'Scherm zwart maken';

  @override
  String get settingLockdownBlackoutDescription =>
      'Maakt het scherm zwart zolang het is vergrendeld.';

  @override
  String get settingLockdownAllowScreensaverTitle =>
      'Schermbeveiliging toestaan';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      'Laat de schermbeveiliging actief zijn terwijl het scherm is vergrendeld. Sluiten bij beweging blijft uitgeschakeld totdat de vergrendeling wordt opgeheven.';

  @override
  String get settingLockdownExitGestureTitle =>
      'Afsluitgebaar voor vergrendelingsmodus';

  @override
  String get settingLockdownExitGestureDescription =>
      'Tik snel ergens op het scherm om de vergrendelingsmodus uit te schakelen, zo nodig na het invoeren van de kiosk-pincode. Bij varianten met vasthouden moet de laatste tik ingedrukt blijven. Als dit is uitgeschakeld, kan de modus alleen via beheer op afstand of Home Assistant worden beëindigd.';

  @override
  String get lockdownGestureNone => 'Uitgeschakeld (alleen op afstand)';

  @override
  String get lockdownExplanation =>
      'De vergrendelingsmodus maakt het dashboard niet-interactief, activeert alle beveiligingen van de kioskmodus zonder de kioskmodusinstellingen te wijzigen en dempt de wekwoorddetectie. Als de System UI-beveiliging hierboven is ingeschakeld, worden ook het meldingenpaneel en de recente apps geblokkeerd. Home Assistant krijgt via ESPHome een schakelaar voor de vergrendelingsmodus.';

  @override
  String get lockdownSearch =>
      'Aanraakbeveiliging die alleen op afstand kan worden ingesteld. Configureer deze via beheer op afstand. De benodigde toestemmingen staan onder Vereiste systeemtoestemmingen.';

  @override
  String get lockdownOverlayHeld =>
      'Het vergrendelingsschild kan het hele scherm bedekken.';

  @override
  String get lockdownOverlayMissing =>
      'Zonder dit dekt het schild alleen de app. Het toestemmingsscherm verschijnt op de tablet.';

  @override
  String get lockdownPermissionsSearch =>
      'De toestemmingen waarop de beveiliging van de vergrendelingsmodus steunt.';

  @override
  String get settingAirplayEnabledTitle => 'AirPlay-ontvanger inschakelen';

  @override
  String get settingAirplayEnabledDescription =>
      'Het apparaat verschijnt als AirPlay-luidspreker in het AirPlay-menu van een iPhone, iPad of Mac.';

  @override
  String get settingAirplayNameTitle => 'Naam van de luidspreker';

  @override
  String get settingAirplayNameDescription =>
      'De naam in het AirPlay-menu. Leeg gebruikt de apparaatnaam.';

  @override
  String get settingAirplaySenderVolumeTitle => 'Volume van de afzender volgen';

  @override
  String get settingAirplaySenderVolumeDescription =>
      'De volumeregeling van de iPhone, iPad of Mac verandert hoe luid dit apparaat speelt. Als dit uitstaat, telt alleen het volume van dit apparaat.';

  @override
  String get settingAirplaySyncOffsetDescription =>
      'Een negatieve waarde laat dit apparaat eerder spelen, zodat het geluid gelijkloopt met video op de afzender. Wordt direct toegepast.';

  @override
  String get settingAirplayTakeoverTitle =>
      'Een andere afzender laten overnemen';

  @override
  String get settingAirplayTakeoverDescription =>
      'Een tweede iPhone, iPad of Mac kan overnemen terwijl er een speelt. Als dit uitstaat, moet die wachten tot de eerste de verbinding verbreekt.';

  @override
  String get mediaAirplayHint => 'Audio afspelen vanaf een iPhone, iPad of Mac';

  @override
  String get mediaCacheTitle => 'Cache voor albumhoezen';

  @override
  String get mediaCacheReadFailed => 'Kon cachegrootte niet lezen.';

  @override
  String get mediaCacheClearFailed => 'Kon de cache niet wissen.';

  @override
  String get mediaCacheChecking => 'Cachegrootte controleren...';

  @override
  String get mediaCacheClearing => 'Wissen...';

  @override
  String mediaCacheUsage(String used, String limit) {
    return '$used van $limit gebruikt. Miniaturen in de wachtrij worden automatisch in de cache opgeslagen.';
  }

  @override
  String get settingSendspinShowPlayerTitle => 'De zwevende speler tonen';

  @override
  String get settingSendspinShowPlayerDescription =>
      'Toon tijdens het afspelen van muziek een klein venster boven het dashboard met albumhoes, nummerinformatie en voortgang. Sleep het naar een willekeurige plek; de positie wordt onthouden.';

  @override
  String get settingSendspinPlayerSizeTitle => 'Spelergrootte';

  @override
  String get settingSendspinPlayerSizeDescription =>
      'Compact toont een klein, onopvallend venster voor Speelt nu. Groot voegt aanraakvriendelijke knoppen voor vorige, afspelen/pauzeren en volgende toe waarmee de hele afspeelgroep wordt bediend.';

  @override
  String get settingSendspinPausedHideMinutesTitle =>
      'Gepauzeerde speler verbergen na';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      'Hoelang een gepauzeerde speler zichtbaar blijft. Dit geldt voor zowel de zwevende speler als de weergave Speelt nu.';

  @override
  String get settingSendspinDismissKeepsPlayingTitle =>
      'Blijven afspelen na sluiten';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      'Veeg de zwevende speler van het scherm om deze te verbergen zonder de muziek te stoppen.';

  @override
  String get mediaFloatingPage => 'Zwevende speler';

  @override
  String get mediaFloatingHint => 'De kleine kaart over het dashboard';

  @override
  String get mediaCompact => 'Compact';

  @override
  String get mediaLargeControls => 'Groot met bediening';

  @override
  String get settingSendspinPlayerSourceTitle => 'Spelerbron';

  @override
  String get settingSendspinPlayerSourceDescription =>
      'De bron die de zwevende speler en Speelt nu tonen en bedienen: dit apparaat of een andere speler.';

  @override
  String get settingSendspinPlayerTitle => 'Speler';

  @override
  String get settingSendspinPlayerDescription =>
      'De speler van die bron die moet worden getoond en bediend.';

  @override
  String get settingSendspinDuckPercentTitle =>
      'Volume verlagen tijdens spraakinteracties';

  @override
  String get settingSendspinDuckPercentDescription =>
      'Verlaagt muziek tijdens spraakinteracties en intercomgesprekken tot dit percentage en herstelt het volume daarna.';

  @override
  String get settingSendspinEsphomeEntitiesTitle =>
      'ESPHome-entiteiten beschikbaar maken';

  @override
  String get settingSendspinEsphomeEntitiesDescription =>
      'Knoppen voor afspelen, pauzeren, volgende en vorige voor de gevolgde speler in Home Assistant, met de status, titel, artiest en bron als sensoren.';

  @override
  String get settingSendspinVolumeKeysTitle =>
      'Volumeknoppen bedienen de speler';

  @override
  String get settingSendspinVolumeKeysGroupDescription =>
      'De volumeknoppen van dit apparaat wijzigen het volume van de gevolgde speler in plaats van het eigen apparaatvolume. Wanneer dit apparaat in een groep afspeelt, wijzigen ze het volume van de groep. Dit gebeurt alleen wanneer Speelt nu zichtbaar is of wanneer de speler muziek afspeelt.';

  @override
  String get settingSendspinVolumeKeyStepTitle => 'Stapgrootte van volumeknop';

  @override
  String get settingSendspinVolumeKeyStepDescription =>
      'De volumewijziging bij één druk op een volumeknop.';

  @override
  String get mediaIntro =>
      'De zwevende speler en Speelt nu verschijnen alleen wanneer de geselecteerde speler een nummer afspeelt of een gevulde wachtrij heeft. Als er niets wordt afgespeeld en de wachtrij leeg is, worden beide verborgen.';

  @override
  String get mediaThisDevice => 'Dit apparaat';

  @override
  String get mediaOff => 'Uit';

  @override
  String get mediaKeysNowPlaying => 'Terwijl Speelt nu wordt getoond';

  @override
  String get mediaKeysPlaying => 'Terwijl de speler speelt';

  @override
  String get mediaAnotherPlayer => 'een andere speler';

  @override
  String mediaOfflineSendspin(String player) {
    return 'De Sendspin-speler blijft offline zolang $player is gekozen.';
  }

  @override
  String mediaOfflineAirplay(String player) {
    return 'De AirPlay-ontvanger blijft uit zolang $player is gekozen.';
  }

  @override
  String mediaOfflineBoth(String player) {
    return 'De Sendspin-speler en de AirPlay-ontvanger blijven offline zolang $player is gekozen.';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => 'Songteksten inschakelen';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      'Gesynchroniseerde songteksten in de weergave Speelt nu, voor iedere spelerbron.';

  @override
  String get settingSendspinLyricsSourceTitle => 'Bron van songteksten';

  @override
  String get settingSendspinLyricsSourceDescription =>
      'De bron waaruit songteksten worden opgehaald. Voor Music Assistant zijn het serveradres en token op de bijbehorende pagina vereist.';

  @override
  String get settingSendspinLyricsFallbackTitle =>
      'Music Assistant als terugvaloptie';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      'Vraag Music Assistant om songteksten wanneer LRCLIB onbereikbaar is. Hiervoor is een verbinding met Music Assistant vereist.';

  @override
  String get settingSendspinLyricsOffsetTitle => 'Timing van songtekst';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      'Verschuif de songtekst ten opzichte van de muziek. Een positieve waarde toont iedere regel eerder, een negatieve waarde later. Pas dit aan voor nummers waarvan de tekst steeds niet gelijkloopt.';

  @override
  String get mediaLyricsPage => 'Songteksten';

  @override
  String get mediaLyricsHint => 'Gesynchroniseerde songteksten, bron en timing';

  @override
  String get settingSendspinMaUrlTitle => 'Serveradres';

  @override
  String get settingSendspinMaUrlDescription =>
      'Het adres van de Music Assistant-server zoals het in de webinterface wordt getoond. Meestal https met poort 8095.';

  @override
  String get settingSendspinMaTokenTitle => 'Verificatietoken';

  @override
  String get settingSendspinMaTokenDescription =>
      'Een langdurig token uit Music Assistant (Instellingen > Gebruikers). Leestoegang is voldoende voor songteksten. De snelkoppeling in het kioskmenu opent de webinterface onder het account waaraan het token is gekoppeld.';

  @override
  String get settingSendspinMaOpenFullscreenTitle =>
      'Direct openen in Speelt nu';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      'Open de speler van Music Assistant op volledig scherm vanuit het kioskmenu of met het gebaar Music Assistant openen.';

  @override
  String get settingSendspinMaAutoCloseTitle => 'Sluiten na inactiviteit';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Keer terug naar het dashboard wanneer de Music Assistant-pagina gedurende deze tijd niet is aangeraakt. Bij 0 blijft de pagina geopend totdat deze handmatig wordt gesloten.';

  @override
  String get settingSendspinMaHideCloseTitle => 'Sluitknop verbergen';

  @override
  String get settingSendspinMaHideCloseDescription =>
      'De zwevende sluitknop kan bedieningselementen van Music Assistant bedekken, zoals het menu van Speelt nu. Zonder deze knop sluit je de pagina met de terugknop of via het kioskmenu.';

  @override
  String get settingSendspinMaZoomDescription =>
      'Past de schaal aan van de volledige Music Assistant-pagina.';

  @override
  String get mediaMaHint => 'Server, token en snelkoppeling in het kioskmenu';

  @override
  String get mediaKioskMenu => 'Kioskmenu';

  @override
  String get mediaValidateConnection => 'Verbinding controleren';

  @override
  String get mediaValidate => 'Controleren';

  @override
  String get mediaChecking => 'Controleren…';

  @override
  String get mediaConnected => 'Verbonden';

  @override
  String mediaConnectedVersion(String version) {
    return 'Verbonden met Music Assistant $version';
  }

  @override
  String get mediaValidateHint =>
      'Controleer het adres en token voordat je de snelkoppeling of songteksten inschakelt.';

  @override
  String get mediaDeviceNoAnswer => 'Het apparaat reageerde niet.';

  @override
  String get mediaValidationFailed => 'Controle mislukt.';

  @override
  String get mediaNoAddress => 'Geen serveradres ingesteld.';

  @override
  String get mediaNoToken => 'Geen verificatietoken ingesteld.';

  @override
  String get mediaTimeout => 'Music Assistant antwoordde niet op tijd.';

  @override
  String mediaUnreachable(String host, String error) {
    return 'Kon $host niet bereiken: $error';
  }

  @override
  String get mediaServerClosed => 'de server heeft de verbinding gesloten';

  @override
  String get settingSendspinFullscreenControlsTitle => 'Mediaknoppen tonen';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      'Toon knoppen voor vorige, afspelen/pauzeren en volgende, plus een voortgangsbalk in Speelt nu. Als bediening zichtbaar is, sluit je de weergave met een sluitknop in plaats van met een tik op een willekeurige plek.';

  @override
  String get settingSendspinFullscreenTextScaleTitle => 'Tekstschaal';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      'Grootte van de titel, artiest, albumnaam, songtekst en wachtrijtekst. Geldt voor beide indelingen en naast de schermbeveiliging. De albumhoes wordt aangepast om ruimte voor de tekst te maken.';

  @override
  String get settingSendspinFullscreenButtonScaleTitle => 'Knoppenschaal';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      'Grootte van de afspeelknoppen en voortgangsbalk, onafhankelijk van de tekstgrootte. Geldt voor beide indelingen en naast de schermbeveiliging. De bediening past zich aan de beschikbare ruimte aan.';

  @override
  String get settingSendspinFullscreenLayoutTitle => 'Indelingsmodus';

  @override
  String get settingSendspinFullscreenLayoutDescription =>
      'Hoe Speelt nu de albumhoes, nummergegevens en bediening indeelt. Horizontaal verdeelt ze over een linker- en rechterhelft. Alleen albumhoes vult het scherm met de albumhoes en toont de nummergegevens en bediening een paar seconden na een tik, en schakelt naar Verticaal zolang de songtekst of wachtrij geopend is. Wordt genegeerd als Speelt nu naast een schermbeveiliging staat.';

  @override
  String get mediaLayoutVertical => 'Verticaal';

  @override
  String get mediaLayoutHorizontal => 'Horizontaal';

  @override
  String get mediaLayoutArtOnly => 'Alleen albumhoes';

  @override
  String get settingSendspinFullscreenDoubleTapTitle =>
      'Dubbele tik om af te sluiten';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'Dubbeltik op een willekeurige plek in Speelt nu om de weergave te sluiten. De sluitknop wordt dan niet getoond. Wordt genegeerd als Speelt nu naast een schermbeveiliging staat.';

  @override
  String get settingSendspinFullscreenCloseButtonTitle =>
      'Sluitknop altijd tonen';

  @override
  String get settingSendspinFullscreenCloseButtonDescription =>
      'Toont de sluitknop ook als Dubbele tik om af te sluiten aan staat.';

  @override
  String get settingSendspinFullscreenOnPlayTitle =>
      'Speelt nu openen wanneer muziek begint';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      'Open Speelt nu zodra het afspelen begint, zonder op de time-out van de schermbeveiliging te wachten.';

  @override
  String get settingSendspinFullscreenMotionTitle =>
      'Speelt nu sluiten bij beweging';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      'Laat beweging Speelt nu sluiten zoals bij een gewone schermbeveiliging. Als dit uitstaat, sluit alleen een aanraking de weergave en onderbreekt voorbijlopen de muziekweergave niet. Wordt genegeerd als Speelt nu naast een schermbeveiliging staat.';

  @override
  String get settingSendspinFullscreenReturnTitle => 'Na het sluiten';

  @override
  String get settingSendspinFullscreenReturnDescription =>
      'De dashboardweergave die verschijnt nadat Speelt nu is gesloten. Standaard volgt Terugkeren naar de startweergave van het dashboard.';

  @override
  String get mediaReturnLastView => 'Laatste weergave';

  @override
  String get mediaReturnChosenView => 'Gekozen weergave';

  @override
  String get settingSendspinFullscreenReturnViewTitle => 'Dashboardweergave';

  @override
  String get settingSendspinFullscreenReturnViewDescription =>
      'De weergave die verschijnt nadat Speelt nu is gesloten.';

  @override
  String get settingSendspinSpeakerPillTitle => 'Luidsprekerkeuze tonen';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Toon de luidsprekerkeuze 5 seconden nadat het scherm is aangeraakt. Voeg luidsprekers toe aan de huidige groep of verwijder ze eruit.';

  @override
  String get settingSendspinSpeakerPillPlayersTitle =>
      'Luidsprekerkeuze filteren';

  @override
  String get settingSendspinSpeakerPillPlayersDescription =>
      'Alleen deze luidsprekers verschijnen in de luidsprekerkeuze. Luidsprekers die al in de groep zitten, verschijnen altijd.';

  @override
  String get settingSendspinAudioQualityTitle => 'Audiokwaliteit tonen';

  @override
  String get settingSendspinAudioQualityDescription =>
      'Toont het formaat, de bitdiepte, de samplefrequentie, de bitrate en de bron van het huidige nummer onderaan Speelt nu. Vereist Music Assistant.';

  @override
  String get mediaAllSpeakers => 'Alle luidsprekers';

  @override
  String get settingSendspinQueueArtTitle => 'Albumhoezen in de wachtrij tonen';

  @override
  String get settingSendspinQueueArtDescription =>
      'Toon een albumhoes bij iedere rij van het wachtrijpaneel.';

  @override
  String get mediaNowPlayingHint =>
      'Volledig scherm tijdens het afspelen van muziek';

  @override
  String get mediaInterfaceHeading => 'Gebruikersinterface';

  @override
  String get settingSendspinFullscreenTitle =>
      'Speelt nu in plaats van de schermbeveiliging';

  @override
  String get settingSendspinFullscreenDescription =>
      'Tijdens het afspelen van muziek verandert de schermbeveiliging in een schermvullende weergave Speelt nu met albumhoes. Als er niets wordt afgespeeld, blijft de gewone schermbeveiliging actief.';

  @override
  String get settingSendspinFullscreenSplitTitle =>
      'Toon naast schermbeveiliging';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      'Houd de schermbeveiliging zichtbaar naast Speelt nu. Op staande schermen staat de schermbeveiliging boven de speler. Kleine schermen behouden de speler op volledig scherm.';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => 'Het scherm vullen';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      'Overschrijf hoe foto\'s worden gevuld wanneer de schermbeveiliging het scherm deelt met Speelt nu. Standaard gebruikt de instelling van iedere schermbeveiliging. Uit toont de hele foto tussen zwarte balken. Slim vergroot foto\'s die ongeveer dezelfde verhouding als het scherm hebben en toont de rest tegen een vervaagde achtergrond. Altijd vergroot iedere foto en snijdt weg wat niet past.';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle =>
      'Helderheid van schermbeveiliging overschrijven';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      'Gebruik de normale schermhelderheid in plaats van de helderheid van de schermbeveiliging wanneer Speelt nu ernaast wordt getoond. Dit overschrijft ook de geplande helderheid van de schermbeveiliging.';

  @override
  String get mediaScreensaverHeading => 'Schermbeveiliging';

  @override
  String get mediaDefaultFill => 'Standaard';

  @override
  String get mediaFillOff => 'Uit';

  @override
  String get mediaFillSmart => 'Slim';

  @override
  String get mediaFillAlways => 'Altijd';

  @override
  String get mediaPickPlayer => 'Kies een speler';

  @override
  String get mediaMaPlayer => 'Music Assistant-speler';

  @override
  String get mediaHaPlayer => 'Home Assistant-mediaspeler';

  @override
  String get mediaSonosRoom => 'Sonos-ruimte';

  @override
  String get mediaSearchPlayers => 'Spelers zoeken';

  @override
  String get mediaOffline => 'Offline';

  @override
  String mediaOfflineName(String name) {
    return '$name (offline)';
  }

  @override
  String get mediaSetUpMa => 'Stel Music Assistant in om de spelers te tonen.';

  @override
  String get mediaSetUpHa =>
      'Maak verbinding met Home Assistant om de mediaspelers te tonen.';

  @override
  String get mediaSetUpSonos =>
      'Er zijn nog geen Sonos-luidsprekers bekend. Zoek of voeg een luidspreker toe op de Sonos-pagina.';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant antwoordde niet: $error';
  }

  @override
  String get mediaSaveFailed => 'Kon de speler niet opslaan.';

  @override
  String get mediaSelectFailed => 'Kon speler niet selecteren';

  @override
  String get mediaNotificationAccessRemote =>
      'Zonder deze toestemming vermeldt Android geen mediasessies en kan Speelt nu de apps die media op dit apparaat afspelen niet volgen. Het toestemmingsscherm verschijnt op de tablet.';

  @override
  String get mediaLocalMediaSession => 'Lokale mediasessie';

  @override
  String get settingSendspinEnabledTitle => 'Sendspin-speler inschakelen';

  @override
  String get settingSendspinEnabledDescription =>
      'Maak van dit apparaat een gesynchroniseerde Sendspin-speler. Het verschijnt in Music Assistant onder de apparaatnaam en speelt synchroon met andere Sendspin-luidsprekers.';

  @override
  String get settingSendspinServerTitle => 'Server';

  @override
  String get settingSendspinServerDescription =>
      'Adres van de Sendspin-server, bijvoorbeeld 192.168.1.10:8927. Laat het veld leeg om de server automatisch op het netwerk te zoeken.';

  @override
  String get settingSendspinCodecTitle => 'Voorkeurscodec voor audio';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC is verliesloos en ideaal op WiFi of ethernet. De server maakt de uiteindelijke keuze uit wat dit apparaat biedt.';

  @override
  String get settingSendspinSyncOffsetTitle =>
      'Correctie voor audiosynchronisatie (ms)';

  @override
  String get settingSendspinSyncOffsetDescription =>
      'Een negatieve waarde laat dit apparaat eerder afspelen, voor luidsprekers die achterlopen op de groep, bijvoorbeeld via Bluetooth. Stel dit op gehoor af; wijzigingen worden direct toegepast.';

  @override
  String get settingSendspinGroupVolumeDescription =>
      'Wanneer dit apparaat in een groep afspeelt, regelt de volumeschuif het volume van de hele groep. Als dit uitstaat, wordt alleen het volume van dit apparaat aangepast. Vereist de verbinding met Music Assistant.';

  @override
  String get settingSendspinMasterVolumeTitle => 'Apparaatvolume regelen';

  @override
  String get settingSendspinMasterVolumeDescription =>
      'Music Assistant stelt het volume in dat de volumeknoppen wijzigen, in plaats van het mediavolume. Geluiden van de assistent volgen het ook.';

  @override
  String get mediaSendspinPage => 'Sendspin-speler';

  @override
  String get mediaSendspinHint =>
      'Maak van dit apparaat een gesynchroniseerde Music Assistant-speler';

  @override
  String get mediaFlac => 'FLAC (verliesloos)';

  @override
  String get mediaOpus => 'Opus (efficiënt)';

  @override
  String get mediaPcm => 'PCM (niet gecomprimeerd)';

  @override
  String get settingSendspinSonosGroupVolumeTitle =>
      'Het groepsvolume aanpassen';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      'Wanneer de gevolgde ruimte in een groep afspeelt, regelt de volumeschuif het volume van de hele groep. Als dit uitstaat, wordt alleen het volume van die ruimte aangepast.';

  @override
  String get settingSendspinSonosInputsTitle => 'Tv en line-in tonen';

  @override
  String get settingSendspinSonosInputsDescription =>
      'Toon activiteit in de mediaspeler wanneer eARC- of line-in-ingangen actief zijn.';

  @override
  String get mediaSonosHint =>
      'Luidsprekers op het netwerk zoeken of via een adres toevoegen';

  @override
  String get mediaSonosSpeakers => 'Luidsprekers';

  @override
  String get mediaSonosNoneFound => 'Geen Sonos gevonden';

  @override
  String get mediaSonosDiscoveryEmpty =>
      'Geen Sonos-apparaat heeft op dit netwerk gereageerd. Voeg een luidspreker toe via het adres.';

  @override
  String get mediaSonosAddTitle => 'Sonos toevoegen via adres';

  @override
  String get mediaSonosLooking => 'Zoeken…';

  @override
  String get mediaSonosEmpty => 'Nog geen luidsprekers';

  @override
  String get mediaSonosEmptyHelp =>
      'Doorzoek dit netwerk of voeg een luidspreker toe via het adres.';

  @override
  String get mediaSonosForget => 'Verwijderen';

  @override
  String get mediaSonosSearchTitle => 'Het netwerk doorzoeken';

  @override
  String get mediaSonosSearchHelp =>
      'Zoekt Sonos-luidsprekers op dit netwerk. Voor automatische detectie moeten de luidsprekers zich in hetzelfde VLAN als dit apparaat bevinden.';

  @override
  String get mediaSonosSearch => 'Zoeken';

  @override
  String get mediaSonosSearching => 'Zoeken…';

  @override
  String get mediaSonosAddAddress => 'Toevoegen via adres';

  @override
  String get mediaSonosAddressHelp =>
      'Het netwerkadres van een Sonos-luidspreker. Hiermee wordt het hele Sonos-systeem toegevoegd.';

  @override
  String get mediaSonosPickRoom => 'Kies een ruimte onder Spelerbron > Sonos.';

  @override
  String get mediaSonosAdded => 'Sonos toegevoegd';

  @override
  String get mediaSonosNoRooms =>
      'De luidspreker heeft geen ruimtes opgegeven.';

  @override
  String get mediaSonosNoAddress => 'geen adres';

  @override
  String mediaSonosUnreachable(String host) {
    return 'Geen Sonos-apparaat reageerde op $host.';
  }

  @override
  String get settingsMenuHomeAssistant => 'Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary =>
      'Verbinding, dashboard, kioskmodus';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary =>
      'Wekwoord, luisteren op de achtergrond';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary =>
      'Eigen entiteiten en Bluetooth-proxy';

  @override
  String get settingsMenuScreenAudio => 'Scherm & audio';

  @override
  String get settingsMenuScreenAudioSummary => 'Helderheid, volume, microfoon';

  @override
  String get settingsMenuScreensaver => 'Schermbeveiliging';

  @override
  String get settingsMenuScreensaverSummary =>
      'Time-out, modi en activeren bij beweging';

  @override
  String get settingsMenuBrowser => 'Webbrowsen';

  @override
  String get settingsMenuBrowserSummary => 'Cache, SSL en zoomniveau';

  @override
  String get settingsMenuMediaPlayer => 'Mediaspeler';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant, Sendspin, Sonos';

  @override
  String get settingsMenuDlna => 'DLNA Renderer';

  @override
  String get settingsMenuDlnaSummary =>
      'Beelden, video\'s en audio op afstand afspelen';

  @override
  String get settingsMenuIntercom => 'Intercom';

  @override
  String get settingsMenuIntercomSummary => 'Praten tussen kiosken';

  @override
  String get settingsMenuCamera => 'Camera';

  @override
  String get settingsMenuCameraSummary => 'Apparaatcamera, beweging, streaming';

  @override
  String get settingsMenuCameraStreams => 'Camerastreams';

  @override
  String get settingsMenuCameraStreamsSummary =>
      'Go2RTC- en Home Assistant-camera\'s';

  @override
  String get settingsMenuKiosk => 'Kioskmodus';

  @override
  String get settingsMenuKioskSummary =>
      'Afsluitgebaar, pincode, hardwareknoppen';

  @override
  String get settingsMenuHomeLauncher => 'Startscherm';

  @override
  String get settingsMenuHomeLauncherSummary =>
      'Startscherm van het apparaat vervangen';

  @override
  String get settingsMenuAppLauncher => 'Appstarter';

  @override
  String get settingsMenuAppLauncherSummary => 'Open andere apps van de kiosk';

  @override
  String get settingsMenuGestures => 'Gebaren';

  @override
  String get settingsMenuGesturesSummary => 'Aanraken, palm- en klapgebaren';

  @override
  String get settingsMenuDevice => 'Apparaat';

  @override
  String get settingsMenuDeviceSummary =>
      'Naam, app-thema en toegang op afstand';

  @override
  String get settingsMenuFleet => 'Vlootbeheer';

  @override
  String get settingsMenuFleetSummary => 'Andere kiosken leiden of volgen';

  @override
  String get settingsMenuPlugins => 'Plug-inbeheer';

  @override
  String get settingsMenuPluginsSummary => 'Plug-ins installeren en beheren';

  @override
  String get settingsMenuLogs => 'Logboeken';

  @override
  String get settingsMenuLogsSummary => 'App-logboek en webconsole';

  @override
  String get settingsMenuAbout => 'Info';

  @override
  String get settingsMenuAboutSummary => 'Versie, auteur, licentie';

  @override
  String get settingsMenuOverview => 'Overzicht';

  @override
  String get settingsMenuOverviewSummary => 'Scherm en snelle bediening';

  @override
  String get settingsMenuLockdown => 'Vergrendelingsmodus';

  @override
  String get settingsMenuLockdownSummary => 'Scherminteracties uitschakelen';

  @override
  String get settingsMenuFiles => 'Bestandsbeheer';

  @override
  String get settingsMenuFilesSummary =>
      'Bestanden doorbladeren, downloaden en uploaden';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => 'Beeldscherm';

  @override
  String get settingsGroupMediaCameras => 'Media en camera\'s';

  @override
  String get settingsGroupHousehold => 'Huishouden';

  @override
  String get settingsGroupKiosk => 'Kiosk';

  @override
  String get settingsGroupSystem => 'Systeem';

  @override
  String get settingsMenuMenu => 'Menu';

  @override
  String get settingsMenuTheme => 'Thema';

  @override
  String get settingsMenuLogout => 'Afmelden';

  @override
  String get settingsMenuSwitchKiosk => 'Kiosk wisselen';

  @override
  String settingsMenuThemeState(String theme) {
    return 'Thema: $theme';
  }

  @override
  String get settingsMenuThemeAuto => 'Automatisch';

  @override
  String get settingsMenuOverviewHeadlessSummary =>
      'Status en snelle bediening';

  @override
  String get settingsMenuHomeAssistantHeadlessSummary => 'Verbinding';

  @override
  String get settingsMenuAudio => 'Audio';

  @override
  String get settingsMenuAudioSummary => 'Volume, microfoon';

  @override
  String get settingsGroupMedia => 'Media';

  @override
  String get settingsMenuDlnaHeadlessSummary => 'Audio op afstand afspelen';

  @override
  String get settingsMenuGesturesHeadlessSummary => 'Knop- en klapgebaren';

  @override
  String get settingsMenuLeds => 'LED-bediening';

  @override
  String get settingsMenuLedsSummary =>
      'Kleuren en effecten van de statuslampjes';

  @override
  String get settingsLedTimers => 'Timers';

  @override
  String get settingsLedNotifications => 'Meldingen';

  @override
  String get settingsLedIdle => 'Inactief';

  @override
  String get settingsLedEffects => 'Effecten';

  @override
  String get settingAdaptiveBrightnessTitle => 'Adaptieve helderheid';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Dim het scherm als de kamer donkerder wordt, met behulp van de omgevingslichtsensor.';

  @override
  String get settingAdaptiveUseEntityTitle =>
      'Home Assistant-entiteit gebruiken';

  @override
  String get settingAdaptiveUseEntityDescription =>
      'Lees het lichtniveau van de kamer uit een Home Assistant-sensor.';

  @override
  String get settingAdaptiveLightEntityTitle => 'Lichtsensor-entiteit';

  @override
  String get settingAdaptiveLightEntityDescription =>
      'De Home Assistant-sensor die het lichtniveau in lux meldt.';

  @override
  String get settingAdaptiveMinBrightnessTitle => 'Minimale helderheid';

  @override
  String get settingAdaptiveMinBrightnessDescription =>
      'Schermhelderheid in een donkere kamer.';

  @override
  String get settingAdaptiveMaxBrightnessTitle => 'Maximale helderheid';

  @override
  String get settingAdaptiveMaxBrightnessDescription =>
      'Schermhelderheid in een heldere kamer.';

  @override
  String get settingAdaptiveDarkLuxTitle => 'Donkere kamer (lx)';

  @override
  String get settingAdaptiveDarkLuxDescription =>
      'Bij dit lichtniveau of lager gebruikt het scherm de minimale helderheid.';

  @override
  String get settingAdaptiveBrightLuxTitle => 'Lichte kamer (lx)';

  @override
  String get settingAdaptiveBrightLuxDescription =>
      'Bij dit lichtniveau of hoger gebruikt het scherm de maximale helderheid.';

  @override
  String get screenAudioAdaptiveHint =>
      'Volg het kamerlicht met de omgevingslichtsensor';

  @override
  String get screenAudioAdaptiveNote =>
      'Niveau in een lichte kamer. Adaptieve helderheid dimt het scherm vanaf dit niveau.';

  @override
  String get screenAudioAdaptiveOwns => 'Adaptieve helderheid is ingeschakeld.';

  @override
  String get screenAudioNoSensor =>
      'Geen omgevingslichtsensor op dit apparaat.';

  @override
  String get screenAudioAmbientLight => 'Omgevingslicht';

  @override
  String get screenAudioAmbientHelp =>
      'De huidige waarde van de omgevingslichtsensor.';

  @override
  String get screenAudioNoReading => 'Nog geen meting';

  @override
  String screenAudioLux(String lux) {
    return '$lux lx';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux lx (laatst gemeten)';
  }

  @override
  String get screenAudioSetsMaximum =>
      'Stelt maximale helderheid in: adaptieve helderheid is ingeschakeld.';

  @override
  String get screenAudioSetsDefault => 'Stelt de standaardhelderheid in.';

  @override
  String get screenAudioBrightnessCurve => 'Helderheidscurve';

  @override
  String get screenAudioCurveHint =>
      'Versleep een punt of tik erop om exacte waarden in te voeren. De schermverlichting in Home Assistant verplaatst het bovenste punt; de rest van de curve beweegt mee.';

  @override
  String screenAudioCurvePoint(String number) {
    return 'Punt $number';
  }

  @override
  String get screenAudioCurveLightLevel => 'Lichtniveau (lx)';

  @override
  String get screenAudioCurveBrightness => 'Helderheid (%)';

  @override
  String screenAudioCurveLuxRange(String low, String high) {
    return 'Voer een lichtniveau in tussen $low en $high lx';
  }

  @override
  String screenAudioCurveLevelRange(String low, String high) {
    return 'Voer een helderheid tussen $low% en $high% in';
  }

  @override
  String get settingAudioMicDeviceTitle => 'Microfoon';

  @override
  String get settingAudioMicDeviceDescription =>
      'De microfoon waarmee wekwoorddetectie en spraakinteracties audio opnemen.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Luidspreker';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Uitvoerapparaat voor Voice Satellite-geluiden. Mediaweergave volgt het audioapparaat van het systeem.';

  @override
  String get screenAudioDevices => 'Audioapparaten';

  @override
  String get screenAudioSelectedDevice => 'Geselecteerd apparaat';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (niet verbonden)';
  }

  @override
  String get settingMicCaptureModeTitle => 'Opnamemodus';

  @override
  String get settingMicCaptureModeDescription =>
      'Kies Spraakcommunicatie als de microfoon hier stil blijft of stopt nadat de kiosk een geluid heeft afgespeeld. Sommige apparaten nemen alleen goed op via hun audiopad voor gesprekken.';

  @override
  String get settingMicSoftwareEchoCancellationTitle => 'Echo-onderdrukking';

  @override
  String get settingMicSoftwareEchoCancellationDescription =>
      'Filtert de eigen geluiden van de kiosk uit het microfoonsignaal, zodat de wekwoorddetectie en assistent ze niet horen. Laat dit ingeschakeld, tenzij een microfoon met eigen echo-onderdrukking hierdoor slechter klinkt.';

  @override
  String get settingMicEchoCancellationMethodTitle =>
      'Methode voor echo-onderdrukking';

  @override
  String get settingMicEchoCancellationMethodDescription =>
      'Automatisch test GTCRN terwijl de kiosk geluid afspeelt en schakelt over naar AEC3 als er te veel echo overblijft. Kies Automatisch om opnieuw te testen.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Geluidsonderdrukking';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Vermindert ruis in het microfoonsignaal. Dit verandert wat de wekwoorddetectie hoort; schakel het in voor een microfoon die ruist.';

  @override
  String get settingMicChannelTitle => 'Microfoonkanaal';

  @override
  String get settingMicChannelDescription =>
      'Microfoons met meerdere kanalen reserveren vaak één kanaal voor spraakherkenning. Het selecteren daarvan kan de detectie verbeteren.';

  @override
  String get settingMicGainDbTitle => 'Microfoonversterking';

  @override
  String get settingMicGainDbDescription =>
      'Versterk of verzwak het microfoonsignaal voordat het wordt verwerkt. Streef in de wekwoordtester naar een niveau rond 0,05. Te veel versterking vervormt spraak en verslechtert de detectie.';

  @override
  String get settingMicCaptureFormatTitle => 'Opnameformaat';

  @override
  String get settingMicCaptureFormatDescription =>
      'Kies 48 kHz-stereo als de microfoon wel in andere apps werkt, maar niet hier. Sommige geluidskaarten nemen alleen in dat formaat op; de app converteert het vervolgens zelf.';

  @override
  String get screenAudioMicrophoneSettings => 'Microfooninstellingen';

  @override
  String get screenAudioMicrophoneHint =>
      'Echo- en ruisonderdrukking, versterking, formaat en liveniveau';

  @override
  String get screenAudioMicrophoneNote =>
      'Stem de opname af op je microfoon en ruimte. Test na wijzigingen de wekwoorden en spraakinteracties.';

  @override
  String get screenAudioAutomaticDefault => 'Automatisch (standaard)';

  @override
  String get screenAudioStereo => '48 kHz stereo';

  @override
  String get screenAudioCaptureRawMicrophone =>
      'Onbewerkte microfoon (standaard)';

  @override
  String get screenAudioCaptureVoiceCommunication => 'Spraakcommunicatie';

  @override
  String get screenAudioEchoMethodGtcrnDetected => 'GTCRN (gedetecteerd)';

  @override
  String get screenAudioEchoMethodAec3Detected => 'AEC3 (gedetecteerd)';

  @override
  String get screenAudioDownmix => 'Downmix (standaard)';

  @override
  String screenAudioChannel(String channel) {
    return 'Kanaal $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return 'Kanaal $channel (niet op deze microfoon)';
  }

  @override
  String get screenAudioMicrophoneLevel => 'Microfoonniveau';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      'Spreek vanaf de plek waar je het apparaat gebruikt. Pas de versterking aan totdat normale spraak ongeveer aan het einde van het groene bereik piekt.';

  @override
  String get settingBrowserCutoutModeTitle => 'Schermuitsparing';

  @override
  String get settingBrowserCutoutModeDescription =>
      'Bepaalt hoe het schermgebied rond een camera-uitsparing of cameragat wordt gebruikt. Kies Vermijd de uitsparing als de camera knoppen bovenaan het dashboard bedekt.';

  @override
  String get settingScreenOrientationTitle => 'Schermoriëntatie';

  @override
  String get settingScreenOrientationDescription =>
      'Dwing het scherm in één stand. Gebruik dit op een apparaat zonder rotatiesensor of op een apparaat dat zo is gemonteerd dat de sensor de stand verkeerd bepaalt.';

  @override
  String get settingScreenHideStatusBarTitle => 'Statusbalk verbergen';

  @override
  String get settingScreenHideStatusBarDescription =>
      'Schakel dit uit om de klok en meldingspictogrammen boven aan het scherm te houden. De kioskmodus verbergt de statusbalk altijd.';

  @override
  String get settingScreenHideNavigationBarTitle => 'Navigatiebalk verbergen';

  @override
  String get settingScreenHideNavigationBarDescription =>
      'Schakel dit uit om de navigatieknoppen op het scherm te houden, samen met de taakbalk op tablets. De kioskmodus verbergt de navigatiebalk altijd.';

  @override
  String get settingScreenShowOnLockScreenTitle =>
      'Over vergrendelscherm tonen';

  @override
  String get settingScreenShowOnLockScreenDescription =>
      'Toont het dashboard boven een vergrendelscherm met pincode, patroon of wachtwoord. De rest van het apparaat blijft vergrendeld.';

  @override
  String get settingKeepScreenOnTitle => 'Scherm ingeschakeld houden';

  @override
  String get settingKeepScreenOnDescription =>
      'Voorkom dat het besturingssysteem het scherm uitzet.';

  @override
  String get settingSetBrightnessOnLaunchTitle =>
      'Helderheid instellen bij opstarten';

  @override
  String get settingSetBrightnessOnLaunchDescription =>
      'Pas de standaard helderheid toe wanneer de app start.';

  @override
  String get settingDefaultBrightnessTitle => 'Standaard helderheid';

  @override
  String get settingDefaultBrightnessDescription =>
      'Schermhelderheid die wordt toegepast wanneer de app start. Een wijziging met de schuifregelaar wordt direct toegepast.';

  @override
  String get screenAudioScreen => 'Scherm';

  @override
  String get screenAudioCutoutAlways => 'Gebied rond uitsparing gebruiken';

  @override
  String get screenAudioCutoutShort => 'Alleen korte randen';

  @override
  String get screenAudioCutoutDefault => 'Systeemstandaard';

  @override
  String get screenAudioCutoutNever => 'Vermijd de uitsparing';

  @override
  String get screenAudioAutomatic => 'Automatisch';

  @override
  String get screenAudioLandscape => 'Liggend';

  @override
  String get screenAudioReverseLandscape => 'Omgekeerd liggend';

  @override
  String get screenAudioPortrait => 'Staand';

  @override
  String get screenAudioReversePortrait => 'Omgekeerd staand';

  @override
  String get screenAudioPermission => 'Toestemming';

  @override
  String get screenAudioBrightnessFallback =>
      'Terugvalmethode voor helderheid actief';

  @override
  String get screenAudioBrightnessPermission =>
      'Zonder toestemming voor \"Systeeminstellingen wijzigen\" wordt alleen de app gedimd en verandert de werkelijke helderheid van het schermpaneel niet.';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      'Zonder toestemming voor \"Systeeminstellingen wijzigen\" wordt alleen de app gedimd en verandert de werkelijke helderheid van het schermpaneel niet.';

  @override
  String get screenAudioAlwaysOn => 'Always-on-display';

  @override
  String get screenAudioAlwaysOnClock =>
      'Dit apparaat houdt een gedimde klok zichtbaar';

  @override
  String get screenAudioAlwaysOnHelp =>
      'Wanneer het scherm wordt uitgeschakeld, gaat het apparaat in de slaapstand. Het always-on-display activeert het vergrendelingsscherm echter opnieuw en geen enkele app kan dat voorkomen. Schakel in de Android-instellingen onder Scherm, bij de opties voor het vergrendelingsscherm, \"Altijd tijd en informatie weergeven\" uit. Sommige ROM\'s noemen dit het always-on-display. Tot die tijd blijft de schermentiteit van Home Assistant niet beschikbaar.';

  @override
  String get settingMediaVolumeTitle => 'Mediavolume';

  @override
  String get settingMediaVolumeDescription =>
      'Muziek en video worden met dit aandeel van het hoofdvolume afgespeeld. Het Sendspin-spelervolume in Music Assistant past deze schuifregelaar aan.';

  @override
  String get settingAssistantVolumeTitle => 'Assistentvolume';

  @override
  String get settingAssistantVolumeDescription =>
      'Spraakreacties en geluidssignalen worden met dit aandeel van het hoofdvolume afgespeeld, onafhankelijk van het mediavolume.';

  @override
  String get settingIntercomVolumeTitle => 'Intercomvolume';

  @override
  String get settingIntercomVolumeDescription =>
      'De stem en omroepberichten van de andere kiosk worden met dit aandeel van het hoofdvolume afgespeeld.';

  @override
  String get screenAudioVolume => 'Audiovolume';

  @override
  String get screenAudioMasterVolume => 'Hoofdvolume';

  @override
  String get screenAudioMasterHelp =>
      'Het apparaatvolume. De volumes voor media, intercom en assistent schalen hieronder.';

  @override
  String get settingScreensaverBlackHideExtrasTitle =>
      'Alle extra\'s verbergen';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      'Houdt het scherm volledig zwart: geen kleine klok, \'In één oogopslag\'-entiteiten of andere overlays.';

  @override
  String get screensaverBlackSection => 'Zwarte schermbeveiliging';

  @override
  String get settingScreensaverCelestialLocationTitle => 'Locatie';

  @override
  String get settingScreensaverCelestialLocationDescription =>
      'Waarvandaan de hemel wordt bekeken.';

  @override
  String get settingScreensaverCelestialEntityTitle => 'Entiteit';

  @override
  String get settingScreensaverCelestialEntityDescription =>
      'Een persoon, apparaattracker of zone met een locatie.';

  @override
  String get settingScreensaverCelestialCoordinatesTitle => 'Coördinaten';

  @override
  String get settingScreensaverCelestialCoordinatesDescription =>
      'Breedte- en lengtegraad, zoals 40.71, -74.01.';

  @override
  String get settingScreensaverCelestialTerrainTitle => 'Landschap';

  @override
  String get settingScreensaverCelestialTerrainDescription =>
      'Het terrein langs de horizon.';

  @override
  String get settingScreensaverCelestialFollowDeviceTitle =>
      'Richt op de hemel';

  @override
  String get settingScreensaverCelestialFollowDeviceDescription =>
      'Houd het apparaat omhoog en de hemel op het scherm draait mee, zodat je kunt zien waar je naar kijkt. Vereist een kompassensor.';

  @override
  String get settingScreensaverCelestialDaytimeTitle => 'Daghemel';

  @override
  String get settingScreensaverCelestialDaytimeDescription =>
      'Maak de hemel lichter en laat de sterren vervagen zolang de zon op is. Zet uit om de hele dag de nachthemel te tonen.';

  @override
  String get settingScreensaverCelestialMilkyWayTitle => 'Melkweg';

  @override
  String get settingScreensaverCelestialMilkyWayDescription =>
      'Toon de gloed van ons sterrenstelsel aan de nachthemel.';

  @override
  String get settingScreensaverCelestialPlanetsTitle => 'Planeten';

  @override
  String get settingScreensaverCelestialPlanetsDescription =>
      'Toon de planeten waar ze vannacht staan.';

  @override
  String get settingScreensaverCelestialDeepSkyTitle =>
      'Sterrenstelsels en nevels';

  @override
  String get settingScreensaverCelestialDeepSkyDescription =>
      'Toon het Andromedastelsel, de Orionnevel en andere objecten die je zonder telescoop kunt zien.';

  @override
  String get settingScreensaverCelestialLightPollutionTitle =>
      'Lichtvervuiling';

  @override
  String get settingScreensaverCelestialLightPollutionDescription =>
      'Simuleer de gloed van stadslichten. Hogere waarden verbergen de zwakkere sterren en de Melkweg.';

  @override
  String get settingScreensaverCelestialTwinkleTitle => 'Fonkelende sterren';

  @override
  String get settingScreensaverCelestialTwinkleDescription =>
      'Laat de sterren fonkelen, het sterkst bij de horizon. Zet uit om energie te besparen.';

  @override
  String get settingScreensaverCelestialLargeMoonTitle => 'Grotere maan';

  @override
  String get settingScreensaverCelestialLargeMoonDescription =>
      'Teken de maan drie keer en de zon twee keer zo groot als in werkelijkheid, zodat de schijngestalte goed te zien is.';

  @override
  String get settingScreensaverCelestialLinesTitle => 'Sterrenbeeldlijnen';

  @override
  String get settingScreensaverCelestialLinesDescription =>
      'Verbind de sterren van elk sterrenbeeld.';

  @override
  String get settingScreensaverCelestialConstellationNamesTitle =>
      'Namen van sterrenbeelden';

  @override
  String get settingScreensaverCelestialConstellationNamesDescription =>
      'Benoem de sterrenbeelden. Er verschijnen er meer als je inzoomt.';

  @override
  String get settingScreensaverCelestialNamesTitle =>
      'Namen van sterren en planeten';

  @override
  String get settingScreensaverCelestialNamesDescription =>
      'Benoem de zon, de maan, de planeten, de helderste sterren en de sterrenstelsels. Meer sterren krijgen een naam als je inzoomt.';

  @override
  String get settingScreensaverCelestialCompassTitle => 'Windrichtingen';

  @override
  String get settingScreensaverCelestialCompassDescription =>
      'Markeer noord, oost, zuid en west op de horizon.';

  @override
  String get settingScreensaverCelestialLabelScaleTitle => 'Labelgrootte';

  @override
  String get settingScreensaverCelestialLabelScaleDescription =>
      'Schaal de labels aan de hemel van 50 tot 200 procent.';

  @override
  String get settingScreensaverCelestialControlCoordinatesTitle => 'Positie';

  @override
  String get settingScreensaverCelestialControlCoordinatesDescription =>
      'Toon de breedte- en lengtegraad van waaruit de hemel wordt gezien.';

  @override
  String get settingScreensaverCelestialControlAzimuthTitle => 'Azimut';

  @override
  String get settingScreensaverCelestialControlAzimuthDescription =>
      'Toon de kompasrichting waar het midden van het scherm naar wijst.';

  @override
  String get settingScreensaverCelestialControlAltitudeTitle => 'Hoogte';

  @override
  String get settingScreensaverCelestialControlAltitudeDescription =>
      'Toon hoe hoog boven de horizon het midden van het scherm is.';

  @override
  String get settingScreensaverCelestialControlFovTitle => 'Gezichtsveld';

  @override
  String get settingScreensaverCelestialControlFovDescription =>
      'Toon hoeveel van de hemel het scherm beslaat, in graden.';

  @override
  String get settingScreensaverCelestialControlTimeTitle => 'Tijd';

  @override
  String get settingScreensaverCelestialControlTimeDescription =>
      'Toon de tijd van de hemel, met een knop Nu na een timelapse.';

  @override
  String get settingScreensaverCelestialControlTimelapseTitle => 'Timelapse';

  @override
  String get settingScreensaverCelestialControlTimelapseDescription =>
      'Versnel de tijd om de hemel te zien draaien. Tik om de snelheid te wijzigen.';

  @override
  String get settingScreensaverCelestialControlPointAtSkyTitle =>
      'Schakelaar Richt op de hemel';

  @override
  String get settingScreensaverCelestialControlPointAtSkyDescription =>
      'Zet Richt op de hemel aan en uit. Alleen zichtbaar op apparaten met een kompas.';

  @override
  String get settingScreensaverCelestialControlMoonPhaseTitle => 'Maanfase';

  @override
  String get settingScreensaverCelestialControlMoonPhaseDescription =>
      'Toon de fase van de maan en hoeveel ervan verlicht is.';

  @override
  String get settingScreensaverCelestialControlScaleTitle =>
      'Grootte van de bediening';

  @override
  String get settingScreensaverCelestialControlScaleDescription =>
      'Schaal de bediening van 50 tot 200 procent.';

  @override
  String get screensaverModeCelestial => 'Sterrenhemel';

  @override
  String get screensaverCelestialTerrainHills => 'Heuvels';

  @override
  String get screensaverCelestialTerrainMountains => 'Bergen';

  @override
  String get screensaverCelestialTerrainPlains => 'Vlakte';

  @override
  String get screensaverCelestialTerrainNone => 'Geen';

  @override
  String get screensaverCelestialLocationGps => 'GPS';

  @override
  String get screensaverCelestialLocationHaHome => 'Thuis in Home Assistant';

  @override
  String get screensaverCelestialLocationHaEntity => 'Home Assistant-entiteit';

  @override
  String get screensaverCelestialLocationManual => 'Handmatig';

  @override
  String get screensaverCelestialCurrentLocation => 'Huidige locatie';

  @override
  String get screensaverCelestialNoGpsReceiver =>
      'Dit apparaat heeft geen gps-ontvanger.';

  @override
  String get screensaverCelestialLocationPermission =>
      'Locatietoestemming niet verleend.';

  @override
  String get screensaverCelestialNoGpsFix => 'Nog geen gps-positie.';

  @override
  String get screensaverCelestialNoHomeZone =>
      'Home Assistant heeft geen thuiszone.';

  @override
  String get screensaverCelestialHaNotConnected =>
      'Home Assistant is niet verbonden.';

  @override
  String get screensaverCelestialPickEntity =>
      'Kies een entiteit met een locatie.';

  @override
  String get screensaverCelestialEntityNoLocation =>
      'Deze entiteit heeft geen locatie.';

  @override
  String get screensaverCelestialPage => 'Sterrenhemel als schermbeveiliging';

  @override
  String get screensaverCelestialSummary =>
      'Locatie, landschap, hemel, labels, bediening';

  @override
  String get screensaverCelestialSkyGroup => 'Hemel';

  @override
  String get screensaverCelestialLabelsGroup => 'Labels';

  @override
  String get screensaverCelestialControlsGroup => 'Bediening';

  @override
  String get screensaverCelestialLocationGrantMissing =>
      'Zonder dit kan de GPS-ontvanger niet worden gelezen en heeft de hemel geen locatie.';

  @override
  String get screensaverCelestialLocationGrantReady =>
      'De hemel kan de GPS-ontvanger volgen.';

  @override
  String get screensaverCelestialCoordinatesInvalid =>
      'Voer een breedte- en lengtegraad in, zoals 40.71, -74.01';

  @override
  String get screensaverCelestialNoLocation =>
      'Kies een locatie via Instellingen > Schermbeveiliging > Sterrenhemel.';

  @override
  String get screensaverCelestialWaitingForGps =>
      'Wachten op een GPS-positie...';

  @override
  String get screensaverCelestialDoubleTapHint => 'Tik twee keer om te sluiten';

  @override
  String get screensaverCelestialCalibrate =>
      'Beweeg het apparaat in een achtvorm om het kompas te kalibreren.';

  @override
  String get celestialSun => 'Zon';

  @override
  String get celestialMoon => 'Maan';

  @override
  String get celestialMercury => 'Mercurius';

  @override
  String get celestialVenus => 'Venus';

  @override
  String get celestialMars => 'Mars';

  @override
  String get celestialJupiter => 'Jupiter';

  @override
  String get celestialSaturn => 'Saturnus';

  @override
  String get celestialUranus => 'Uranus';

  @override
  String get celestialNeptune => 'Neptunus';

  @override
  String get celestialAndromedaGalaxy => 'Andromedastelsel';

  @override
  String get celestialTriangulumGalaxy => 'Driehoeknevel';

  @override
  String get celestialLargeMagellanicCloud => 'Grote Magelhaense Wolk';

  @override
  String get celestialSmallMagellanicCloud => 'Kleine Magelhaense Wolk';

  @override
  String get celestialOrionNebula => 'Orionnevel';

  @override
  String get celestialLagoonNebula => 'Lagunenevel';

  @override
  String get celestialCarinaNebula => 'Carinanevel';

  @override
  String get celestialPleiades => 'Plejaden';

  @override
  String get celestialBeehiveCluster => 'Kribbe';

  @override
  String get celestialDoubleCluster => 'Dubbele Sterrenhoop';

  @override
  String get celestialOmegaCentauri => 'Omega Centauri';

  @override
  String get celestialTucanae47 => '47 Tucanae';

  @override
  String get celestialCompassNorth => 'N';

  @override
  String get celestialCompassEast => 'O';

  @override
  String get celestialCompassSouth => 'Z';

  @override
  String get celestialCompassWest => 'W';

  @override
  String get celestialCompassNorthEast => 'NO';

  @override
  String get celestialCompassSouthEast => 'ZO';

  @override
  String get celestialCompassSouthWest => 'ZW';

  @override
  String get celestialCompassNorthWest => 'NW';

  @override
  String get celestialAzimuthShort => 'Az';

  @override
  String get celestialAltitudeShort => 'Hoogte';

  @override
  String get celestialFovShort => 'FOV';

  @override
  String get celestialNow => 'Nu';

  @override
  String get celestialMoonNew => 'Nieuwe maan';

  @override
  String get celestialMoonWaxingCrescent => 'Wassende sikkel';

  @override
  String get celestialMoonFirstQuarter => 'Eerste kwartier';

  @override
  String get celestialMoonWaxingGibbous => 'Wassende maan';

  @override
  String get celestialMoonFull => 'Volle maan';

  @override
  String get celestialMoonWaningGibbous => 'Afnemende maan';

  @override
  String get celestialMoonLastQuarter => 'Laatste kwartier';

  @override
  String get celestialMoonWaningCrescent => 'Afnemende sikkel';

  @override
  String get settingScreensaverClockStyleTitle => 'Stijl';

  @override
  String get settingScreensaverClockStyleDescription =>
      'Hoe de klok wordt weergegeven.';

  @override
  String get settingScreensaverClockVerticalTitle => 'Verticale modus';

  @override
  String get settingScreensaverClockVerticalDescription =>
      'Stapel de uren boven de minuten, voor portretschermen.';

  @override
  String get settingScreensaverClockFontTitle => 'Lettertypefamilie';

  @override
  String get settingScreensaverClockFontDescription =>
      'Het lettertype waarin de klok wordt weergegeven.';

  @override
  String get settingScreensaverClockFontWeightTitle => 'Tekstdikte';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      'Bepaalt hoe vet de cijfers van de klok worden weergegeven. Standaard gebruikt elke stijl zijn eigen tekstdikte.';

  @override
  String get settingScreensaverClock24hTitle => '24-uursklok';

  @override
  String get settingScreensaverClock24hDescription =>
      'Toon een 24-uurstijd in plaats van AM/PM.';

  @override
  String get settingScreensaverClockSecondsTitle => 'Seconden tonen';

  @override
  String get settingScreensaverClockSecondsDescription =>
      'Toon ook de seconden op de klok.';

  @override
  String get settingScreensaverClockDateTitle => 'Datum tonen';

  @override
  String get settingScreensaverClockDateDescription =>
      'Toon de weekdag en datum onder de tijd.';

  @override
  String get settingScreensaverClockScaleTitle => 'Klokgrootte';

  @override
  String get settingScreensaverClockScaleDescription =>
      'Pas de klokgrootte voor dit scherm aan van 50 tot 300 procent.';

  @override
  String get settingScreensaverClockColorTitle => 'Klokkleur';

  @override
  String get settingScreensaverClockColorDescription =>
      'De kleur van de kloktekst.';

  @override
  String get settingScreensaverClockBgColorTitle => 'Achtergrondkleur';

  @override
  String get settingScreensaverClockBgColorDescription =>
      'De kleur achter de klok.';

  @override
  String get settingScreensaverClockBackgroundTitle => 'Achtergrondfoto';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      'Toon een foto achter de klok in plaats van een effen achtergrondkleur. Geef een pad naar een afbeelding op het apparaat op of een afbeeldings-URL die het apparaat ophaalt.';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle =>
      'URL-achtergrond vernieuwen';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      'Aantal minuten tussen het ophalen van een URL-achtergrond. Bij 0 wordt de afbeelding alleen opgehaald wanneer deze instelling wordt opgeslagen.';

  @override
  String get settingScreensaverFlipDigitColorTitle => 'Cijferkleur';

  @override
  String get settingScreensaverFlipDigitColorDescription =>
      'De kleur van de cijfers op de klapkaarten.';

  @override
  String get settingScreensaverFlipBgColorTitle => 'Kaartkleur';

  @override
  String get settingScreensaverFlipBgColorDescription =>
      'De kleur van de klapkaarten.';

  @override
  String get settingScreensaverFlipBackdropColorTitle => 'Achtergrondkleur';

  @override
  String get settingScreensaverFlipBackdropColorDescription =>
      'De kleur achter de kaarten.';

  @override
  String get settingScreensaverRollerDigitColorTitle => 'Cijferkleur';

  @override
  String get settingScreensaverRollerDigitColorDescription =>
      'De kleur van de rollende cijfers.';

  @override
  String get settingScreensaverRollerBgColorTitle => 'Achtergrondkleur';

  @override
  String get settingScreensaverRollerBgColorDescription =>
      'De kleur achter de cijfers.';

  @override
  String get settingScreensaverHandNumbersTitle => 'Cijfers';

  @override
  String get settingScreensaverHandNumbersDescription =>
      'Welke uren de wijzerplaat als cijfer toont.';

  @override
  String get settingScreensaverHandSecondsTitle => 'Secondewijzer tonen';

  @override
  String get settingScreensaverHandSecondsDescription =>
      'Teken een secondewijzer op de wijzerplaat.';

  @override
  String get settingScreensaverHandColorTitle => 'Klokkleur';

  @override
  String get settingScreensaverHandColorDescription =>
      'De kleur van de wijzers, cijfers en streepjes.';

  @override
  String get settingScreensaverHandBgColorTitle => 'Achtergrondkleur';

  @override
  String get settingScreensaverHandBgColorDescription =>
      'De kleur achter de klok.';

  @override
  String get settingScreensaverClockNightTitle => 'Nachtmodus';

  @override
  String get settingScreensaverClockNightDescription =>
      'Verander de kleur van de klok wanneer de kamer donker is.';

  @override
  String get settingScreensaverClockNightLuxTitle => 'Lichtniveau';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      'Bij of onder dit lichtniveau krijgt de klok de nachtkleur.';

  @override
  String get settingScreensaverClockNightColorTitle => 'Nachtkleur';

  @override
  String get settingScreensaverClockNightColorDescription =>
      'De kleur van de klok en widgets wanneer het donker is.';

  @override
  String get settingScreensaverClockNightBgColorTitle => 'Nachtachtergrond';

  @override
  String get settingScreensaverClockNightBgColorDescription =>
      'De kleur achter de klok in het donker.';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle =>
      'Achtergrondfoto verbergen';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      'Gebruik de achtergrondkleur van de nacht in plaats van de foto terwijl de nachtmodus actief is.';

  @override
  String get settingScreensaverClockNightHideWidgetsTitle =>
      'Widgets en \'In één oogopslag\' verbergen';

  @override
  String get settingScreensaverClockNightHideWidgetsDescription =>
      'Toon alleen de klok wanneer de nachtmodus actief is.';

  @override
  String get settingScreensaverClockNightCardColorTitle => 'Kleur nachtkaart';

  @override
  String get settingScreensaverClockNightCardColorDescription =>
      'De kleur van de klapkaarten in het donker.';

  @override
  String get screensaverClockSection => 'Klokschermbeveiliging';

  @override
  String get screensaverClockHint =>
      'Stijl, lettertype, grootte, kleuren, nachtmodus en achtergrondfoto';

  @override
  String get screensaverStyleDigital => 'Digitale klok';

  @override
  String get screensaverStyleFlip => 'Klapklok';

  @override
  String get screensaverStyleRoller => 'Rolklok';

  @override
  String get screensaverStyleHand => 'Wijzerklok';

  @override
  String get screensaverHandNumbersQuarters => '12, 3, 6 en 9';

  @override
  String get screensaverHandNumbersAll => 'Alle uren';

  @override
  String get screensaverFontDefault => 'Standaard';

  @override
  String get screensaverFontLight => 'Dun';

  @override
  String get screensaverFontRegular => 'Normaal';

  @override
  String get screensaverFontMedium => 'Halfvet';

  @override
  String get screensaverFontBold => 'Vet';

  @override
  String get screensaverFontBlack => 'Extra vet';

  @override
  String get screensaverNoPhoto => 'Geen foto geselecteerd';

  @override
  String get screensaverBackgroundHint =>
      'Pad naar een afbeelding op het apparaat of een afbeeldings-URL';

  @override
  String get screensaverImageUrlError =>
      'Voer een volledige URL naar een afbeelding in';

  @override
  String get screensaverRefreshError =>
      'Voer een geheel aantal minuten van 0 tot en met 1440 in';

  @override
  String screensaverMaxCharacters(String count) {
    return 'Gebruik maximaal $count tekens';
  }

  @override
  String get settingScreensaverClockAmPmTitle => 'AM/PM tonen';

  @override
  String get settingScreensaverClockAmPmDescription =>
      'Toon AM of PM na de tijd.';

  @override
  String get settingScreensaverClockNightTurnOffMinutesTitle =>
      'Scherm \'s nachts uitschakelen na';

  @override
  String get settingScreensaverClockNightTurnOffMinutesDescription =>
      'Schakelt het scherm uit zodra de nachtmodus de ingestelde tijd actief is en weer in zodra het lichter wordt in de kamer. Stel 0 in om het scherm aan te laten. Hiervoor is toestemming voor apparaatbeheer vereist.';

  @override
  String get screensaverNightTurnOffWarning =>
      'Zodra het scherm echt wordt uitgeschakeld, neemt het energiebeheer van de tablet het over. Veel Android-modellen gedragen zich dan onvoorspelbaar: wifi kan in de slaapstand gaan of wegvallen, Home Assistant-entiteiten kunnen onbeschikbaar worden, de cameratoegang kan worden ingetrokken en sommige modellen sluiten achtergrondapps af. Sommige lichtsensoren geven ook geen metingen meer door als het scherm uit is, waardoor het scherm misschien niet vanzelf weer aangaat als het lichter wordt in de kamer. Dit verschilt per fabrikant.\n\nEen betrouwbare optie is Een zwart scherm gebruiken. Het scherm ziet er dan net zo donker uit, terwijl de app de volledige controle behoudt.';

  @override
  String get screensaverOverlayEntity => 'Entiteit';

  @override
  String get screensaverOverlayNotSet => 'Niet ingesteld';

  @override
  String get screensaverOverlayName => 'Naam';

  @override
  String get screensaverOverlayNameHelp =>
      'Laat dit leeg om de naam uit Home Assistant te gebruiken.';

  @override
  String get screensaverOverlayValue => 'Weergegeven waarde';

  @override
  String get screensaverOverlayState => 'Status';

  @override
  String get screensaverOverlayEntityRequired => 'Kies een entiteit.';

  @override
  String get screensaverOverlaySearching => 'Zoeken…';

  @override
  String get screensaverOverlayUnreachable =>
      'Kon Home Assistant niet bereiken';

  @override
  String get screensaverOverlayNoAnswer => 'Het apparaat reageerde niet.';

  @override
  String get settingScreensaverDismissOnFaceTitle =>
      'Sluiten bij gezichtsdetectie';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      'Activeer het scherm wanneer iemand naar de kiosk kijkt, niet alleen wanneer er beweging is. De camera werkt alleen terwijl de schermbeveiliging actief is. Waarschuwing: hiervoor moet het gezicht verlicht zijn. Gebruik in het donker bewegingsdetectie met een schema.';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle =>
      'Alleen als het scherm uit staat';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      'Houd de schermbeveiliging zichtbaar als er een gezicht wordt gedetecteerd terwijl het scherm aan staat. Zodra het scherm uitgaat, activeert de detectie het dashboard. Aanraken sluit de schermbeveiliging nog steeds af.';

  @override
  String get settingScreensaverPostponeOnFaceTitle =>
      'Schermbeveiliging uitstellen bij gezichtsdetectie';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      'Stel het activeren van de schermbeveiliging uit zolang iemand naar de kiosk kijkt. Waarschuwing: de camera blijft voortdurend actief, waardoor gezichtsdetectie extra processorkracht gebruikt.';

  @override
  String get settingFaceSensitivityTitle => 'Gezichtsgevoeligheid';

  @override
  String get settingFaceSensitivityDescription =>
      'Bij een hogere gevoeligheid wordt het scherm ook geactiveerd door kleinere gezichten op grotere afstand. Bij 1 moet iemand dicht bij het scherm zijn; bij 100 reageert de camera op elk gezicht dat deze kan onderscheiden.';

  @override
  String get screensaverDetectionFacePage => 'Gezichtsdetectie';

  @override
  String get screensaverDetectionFaceHint =>
      'Sluit de schermbeveiliging wanneer iemand naar het scherm kijkt';

  @override
  String get screensaverDetectionMotionPrecedence =>
      'Sluiten bij beweging staat aan en heeft voorrang. Gezichtsdetectie blijft daarom inactief totdat bewegingsdetectie wordt uitgeschakeld.';

  @override
  String get screensaverDetectionFaceTuning =>
      'Framesnelheid, camerakeuze en opstartvertraging worden ingesteld bij de camera-instellingen.';

  @override
  String get screensaverDetectionAndroidUnsupported =>
      'Niet beschikbaar op deze Android-versie.';

  @override
  String get screensaverDetectionX86Unsupported =>
      'Niet beschikbaar op x86-apparaten.';

  @override
  String get settingFacePreviewTitle => 'Cameravoorbeeld tonen';

  @override
  String get settingFacePreviewDescription =>
      'Toon enkele seconden een kleine ronde liveweergave van de camera in een hoek van het scherm wanneer een gezicht de kiosk activeert.';

  @override
  String get settingFacePreviewSecondsTitle => 'Duur van voorbeeldweergave';

  @override
  String get settingFacePreviewSecondsDescription =>
      'Hoelang de voorbeeldweergave op het scherm blijft.';

  @override
  String get settingFacePreviewScaleTitle => 'Grootte van voorbeeldweergave';

  @override
  String get settingFacePreviewScaleDescription =>
      'Pas de grootte van de voorbeeldweergave aan zodat deze beter op het scherm past.';

  @override
  String get settingFacePreviewPositionTitle => 'Positie van voorbeeldweergave';

  @override
  String get settingFacePreviewPositionDescription =>
      'In welke hoek de voorbeeldweergave verschijnt.';

  @override
  String get screensaverDetectionPreviewSection => 'Cameravoorbeeld';

  @override
  String get settingScreensaverEnabledTitle => 'Schermbeveiliging';

  @override
  String get settingScreensaverEnabledDescription =>
      'Dim het scherm of maak het zwart na een periode van inactiviteit.';

  @override
  String get settingScreensaverTimeoutSecondsTitle =>
      'Time-out voor inactiviteit (seconden)';

  @override
  String get settingScreensaverTimeoutSecondsDescription =>
      'Hoe lang het apparaat inactief moet zijn voordat de schermbeveiliging start.';

  @override
  String get settingScreensaverModeTitle => 'Schermbeveiligingsmodus';

  @override
  String get settingScreensaverModeDescription =>
      'Wat de schermbeveiliging toont na de inactiviteitstime-out. Bij \'Dimmen\' wordt alleen de achtergrondverlichting verlaagd en blijft het dashboard zichtbaar.';

  @override
  String get settingScreensaverPixelShiftTitle => 'Pixelverschuiving';

  @override
  String get settingScreensaverPixelShiftDescription =>
      'Verschuif de afbeelding elke minuut een klein stukje om OLED-schermen te beschermen. Dit geldt niet voor de zwarte schermbeveiliging, waarbij de pixels al uit staan.';

  @override
  String get settingScreensaverFollowAnimationScaleTitle =>
      'Android-animatie-instellingen volgen';

  @override
  String get settingScreensaverFollowAnimationScaleDescription =>
      'Pauzeer geanimeerde schermbeveiligingen wanneer Android-animaties uit staan.';

  @override
  String get settingScreensaverDimLevelTitle => 'Dimniveau';

  @override
  String get settingScreensaverDimLevelDescription =>
      'De helderheid van het scherm wanneer de schermbeveiliging dimt.';

  @override
  String get settingScreensaverBrightnessEnabledTitle =>
      'Helderheid van schermbeveiliging';

  @override
  String get settingScreensaverBrightnessEnabledDescription =>
      'Gebruik een aparte helderheidsinstelling wanneer de schermbeveiliging actief is.';

  @override
  String get settingScreensaverBrightnessLevelTitle => 'Helderheidsniveau';

  @override
  String get settingScreensaverBrightnessLevelDescription =>
      'Geldt voor alle modi behalve Dimmen en Zwart.';

  @override
  String get settingScreensaverNotificationBrightnessTitle =>
      'Oplichten bij meldingen';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      'Verhoog de helderheid van de schermbeveiliging zolang er een melding op het scherm staat.';

  @override
  String get settingScreensaverScreenOffMinutesTitle =>
      'Scherm uitschakelen na';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Schakelt het scherm uit zodra de schermbeveiliging gedurende de ingestelde tijd actief is geweest. Stel 0 in om het scherm onbeperkt aan te laten. Hiervoor is toestemming voor apparaatbeheer vereist.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Schermbeveiliging tonen bij wekken';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescriptionSources =>
      'Kies wat na het uitschakelen van het scherm de schermbeveiliging terugbrengt in plaats van het dashboard. De afteltijd voor \'Scherm uitschakelen na\' begint opnieuw.';

  @override
  String get screensaverWakeSourcesAll => 'Alles';

  @override
  String get screensaverWakeSourceMotion => 'Beweging';

  @override
  String get screensaverWakeSourceFace => 'Gezicht';

  @override
  String get screensaverWakeSourceProximity => 'Nabijheid';

  @override
  String get screensaverWakeSourcePerson => 'Persoon';

  @override
  String get screensaverWakeSourcePower => 'Aan/uit-knop';

  @override
  String get screensaverWakeSourceTouch => 'Aanraken';

  @override
  String get screensaverWakeSourceTouchRequires =>
      'Vereist zowel \'Scherm uitschakelen na\' als \'Een zwart scherm gebruiken\'.';

  @override
  String get screensaverModeDim => 'Dimmen';

  @override
  String get screensaverModeBlack => 'Zwart';

  @override
  String get screensaverModeClock => 'Klok';

  @override
  String get screensaverModeMedia => 'Home Assistant-media';

  @override
  String get screensaverModeLocal => 'Lokale media';

  @override
  String get screensaverModeGallery => 'Fotogalerij';

  @override
  String get screensaverModeImmich => 'Immich-media';

  @override
  String get screensaverModeWebsite => 'Website';

  @override
  String get screensaverModeCamera => 'Camerastreams';

  @override
  String get screensaverDimSection => 'Gedimde schermbeveiliging';

  @override
  String get screensaverWarningTitle => 'Waarschuwing: lees dit eerst';

  @override
  String get screensaverScreenOffProceed => 'Scherm toch uitschakelen';

  @override
  String get screensaverAdminMissing =>
      'Niet verleend. Het scherm kan daarom niet worden uitgeschakeld.';

  @override
  String get screensaverAdminMissingRemote =>
      'Toestemming voor apparaatbeheer ontbreekt';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      'Zonder deze toestemming kan het scherm niet worden uitgeschakeld. Het verzoek verschijnt op het tabletscherm.';

  @override
  String get screensaverDimWarning =>
      'Waarschuwing: bij de modus \'Dimmen\' blijft het dashboard zichtbaar. De optimalisatie \'Dashboard pauzeren tijdens schermbeveiliging\' wordt daarom niet toegepast en het dashboard blijft CPU, GPU en batterij gebruiken.';

  @override
  String get screensaverUnavailablePlugin =>
      'Schermbeveiliging van plug-in niet beschikbaar';

  @override
  String get screensaverScreenOffWarning =>
      'Zodra het scherm echt wordt uitgeschakeld, neemt het energiebeheer van de tablet het over. Veel Android-modellen gedragen zich dan onvoorspelbaar: wifi kan in de slaapstand gaan of wegvallen, Home Assistant-entiteiten kunnen onbeschikbaar worden, de cameratoegang kan worden ingetrokken en sommige modellen sluiten achtergrondapps helemaal af. Dit verschilt per fabrikant.\n\nEen betrouwbare optie is de zwarte schermbeveiliging met deze instelling op 0. Het scherm ziet er dan net zo donker uit, terwijl de app de volledige controle behoudt.';

  @override
  String get settingScreensaverScreenOffBlackTitle =>
      'Een zwart scherm gebruiken';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      'Toon een zwart scherm met nul helderheid in plaats van het scherm uit te schakelen. Widgets en Speelt nu worden verborgen. Hiervoor is geen toestemming voor apparaatbeheer nodig.';

  @override
  String get screensaverModeDashboard => 'Home Assistant-dashboard';

  @override
  String get settingScreensaverDashboardViewTitle => 'Dashboardweergave';

  @override
  String get settingScreensaverDashboardViewDescription =>
      'De Home Assistant-dashboardweergave die de schermbeveiliging toont.';

  @override
  String get settingScreensaverDashboardDoubleTapTitle =>
      'Dubbele tik om af te sluiten';

  @override
  String get settingScreensaverDashboardDoubleTapDescription =>
      'Enkele tikken werken met het dashboard en sluiten de schermbeveiliging niet af.';

  @override
  String get settingScreensaverDashboardKioskTitle =>
      'HA kioskmodus overschrijven';

  @override
  String get settingScreensaverDashboardKioskDescription =>
      'Kies wat de schermbeveiliging verbergt, los van de HA-kioskmodus.';

  @override
  String get settingScreensaverDashboardHideHeaderTitle => 'Kopbalk verbergen';

  @override
  String get settingScreensaverDashboardHideHeaderDescription =>
      'Verberg de dashboardwerkbalk en tabbladen met weergaven op de schermbeveiliging.';

  @override
  String get settingScreensaverDashboardHideSidebarTitle => 'Zijbalk verbergen';

  @override
  String get settingScreensaverDashboardHideSidebarDescription =>
      'Verberg de navigatiezijbalk op de schermbeveiliging.';

  @override
  String get screensaverDashboardSection =>
      'Home Assistant-dashboard als schermbeveiliging';

  @override
  String get screensaverModeUrl => 'Afbeeldings-URL';

  @override
  String get screensaverCalendarSection => 'Agenda als schermbeveiliging';

  @override
  String get settingScreensaverCalendarViewTitle => 'Agendaweergave';

  @override
  String get settingScreensaverCalendarViewDescription =>
      'De agendaweergave waarmee de schermbeveiliging opent.';

  @override
  String get settingScreensaverGlanceScaleTitle => 'Rij schalen';

  @override
  String get settingScreensaverGlanceScaleDescription =>
      'Pas de schaal van de rij aan zodat deze beter op het scherm past.';

  @override
  String get settingScreensaverGlanceFontTitle => 'Lettertypefamilie';

  @override
  String get settingScreensaverGlanceFontDescription =>
      'Het lettertype waarin de rij is getekend.';

  @override
  String get settingScreensaverGlanceFontWeightTitle => 'Tekstdikte';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      'Bepaalt hoe vet de tekst in de rij wordt weergegeven. Standaard heeft elke regel zijn eigen dikte: normale namen en halfvette waarden.';

  @override
  String get settingScreensaverGlanceHideNamesTitle => 'Namen verbergen';

  @override
  String get settingScreensaverGlanceHideNamesDescription =>
      'Alleen het pictogram en de waarde tonen, waarbij de waarde groter is.';

  @override
  String get settingScreensaverGlanceBwIconsTitle =>
      'Pictogrammen in één kleur';

  @override
  String get settingScreensaverGlanceBwIconsDescription =>
      'Toon alle pictogrammen in neutraal grijs in plaats van in de kleur van hun status.';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => 'Zwevende tekst';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      'Toon entiteiten als zwevende tekst in plaats van als labels.';

  @override
  String get screensaverOverlayAppearance => 'Uiterlijk';

  @override
  String get settingScreensaverGlanceEnabledTitle => 'In één oogopslag';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      'Toon een rij met statussen van Home Assistant-entiteiten op de schermbeveiliging.';

  @override
  String get settingScreensaverGlanceEntitiesTitle => 'Entiteiten';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      'Toon maximaal vier entiteiten, elk eventueel met een aangepaste naam.';

  @override
  String get settingScreensaverGlanceNowPlayingTitle => 'Tonen bij Speelt nu';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      'Toon de rij op de schermvullende weergave van Speelt nu. De rij blijft verborgen wanneer songteksten worden getoond.';

  @override
  String get screensaverOverlayShowing => 'Wordt getoond';

  @override
  String get screensaverOverlayNone => 'Nog geen entiteiten';

  @override
  String get screensaverOverlayGlancePage => 'In één oogopslag';

  @override
  String get screensaverOverlayGlanceHint =>
      'Entiteiten die over de schermbeveiliging worden getoond';

  @override
  String get glanceUnavailable => 'Niet beschikbaar';

  @override
  String get glanceUnknown => 'Onbekend';

  @override
  String get settingScreensaverImmichUrlTitle => 'Serveradres';

  @override
  String get settingScreensaverImmichUrlDescription =>
      'Het adres van je Immich-server, inclusief poortnummer.';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'API-sleutel';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      'Aangemaakt in Immich onder Accountinstellingen → API-sleutels.';

  @override
  String get screensaverMediaImmichPage => 'Immich-media als schermbeveiliging';

  @override
  String get screensaverMediaImmichHint =>
      'Server, media, diavoorstelling, metagegevens en filters';

  @override
  String get screensaverMediaServerConnection => 'Verbinding met server';

  @override
  String get screensaverMediaValidateFailedLog =>
      'Validatie is mislukt. Raadpleeg het app-logboek voor de mislukte aanvraag.';

  @override
  String get screensaverMediaValidateFailed => 'Validatie mislukt.';

  @override
  String get screensaverMediaNoAnswer => 'Het apparaat reageerde niet.';

  @override
  String get screensaverMediaAddressFirst => 'Voer eerst het serveradres in.';

  @override
  String get screensaverMediaKeyFirst => 'Voer eerst een API-sleutel in.';

  @override
  String get screensaverMediaBadAddress =>
      'Het serveradres is geen geldige URL.';

  @override
  String get screensaverMediaKeyRejected => 'De API-sleutel is geweigerd.';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'De API-sleutel mist de $scope-toestemming.';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'De API-sleutel mist een toestemming: $error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return 'De server antwoordde $status: $error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return 'Kon $url niet bereiken.';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return 'Kan geen verbinding maken met de server: $error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => 'Mensen';

  @override
  String get settingScreensaverImmichPeopleDescription =>
      'Toon alleen media waarop een of meer van deze personen staan.';

  @override
  String get settingScreensaverImmichExcludePeopleTitle => 'Mensen uitsluiten';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      'Sla media over waarop een of meer van deze personen staan.';

  @override
  String get settingScreensaverImmichTagsTitle => 'Labels';

  @override
  String get settingScreensaverImmichTagsDescription =>
      'Alleen media tonen met een van deze labels.';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => 'Labels uitsluiten';

  @override
  String get settingScreensaverImmichExcludeTagsDescription =>
      'Sla media met een van deze labels over.';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => 'Alleen favorieten';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      'Alleen media tonen die als favoriet zijn gemarkeerd.';

  @override
  String get settingScreensaverImmichTakenWithinTitle => 'Periode';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      'Alleen media in dit venster tonen.';

  @override
  String get settingScreensaverImmichTakenFromTitle => 'Van';

  @override
  String get settingScreensaverImmichTakenFromDescription =>
      'Sla media over die vóór deze datum is gemaakt.';

  @override
  String get settingScreensaverImmichTakenToTitle => 'Tot en met';

  @override
  String get settingScreensaverImmichTakenToDescription =>
      'Sla media over die na deze datum is gemaakt. De gekozen datum telt mee.';

  @override
  String get screensaverMediaFilters => 'Filters';

  @override
  String get screensaverMediaAnyone => 'Iedereen';

  @override
  String get screensaverMediaAnyoneDevice => 'Iedereen.';

  @override
  String get screensaverMediaNoOne => 'Niemand';

  @override
  String get screensaverMediaNoOneDevice => 'Niemand.';

  @override
  String get screensaverMediaAny => 'Alle';

  @override
  String get screensaverMediaAnyDevice => 'Alle.';

  @override
  String get screensaverMediaNoTagsChosen => 'Geen labels';

  @override
  String get screensaverMediaNoTagsChosenDevice => 'Geen labels.';

  @override
  String get screensaverMediaNoPeople =>
      'Er zijn nog geen personen benoemd. Geef ze eerst een naam in Immich.';

  @override
  String get screensaverMediaNoTags =>
      'Er zijn nog geen labels. Maak deze eerst aan in Immich.';

  @override
  String get screensaverMediaPeopleFailed =>
      'De personenlijst kan niet worden opgehaald';

  @override
  String get screensaverMediaTagsFailed =>
      'De labellijst kan niet worden opgehaald';

  @override
  String get screensaverMediaHidden => 'Verborgen';

  @override
  String get screensaverMediaAnyTime => 'Altijd';

  @override
  String get screensaverMediaPastMonth => 'Afgelopen maand';

  @override
  String get screensaverMediaPast3Months => 'Afgelopen 3 maanden';

  @override
  String get screensaverMediaPastYear => 'Afgelopen jaar';

  @override
  String get screensaverMediaPast2Years => 'Afgelopen 2 jaar';

  @override
  String get screensaverMediaPast5Years => 'Afgelopen 5 jaar';

  @override
  String get screensaverMediaPast10Years => 'Afgelopen 10 jaar';

  @override
  String get screensaverMediaSince => 'Sinds';

  @override
  String get screensaverMediaTimeframe => 'Tijdsperiode';

  @override
  String get screensaverMediaToday => 'Vandaag';

  @override
  String get screensaverMediaDateFormat => 'Gebruik JJJJ-MM-DD.';

  @override
  String get screensaverMediaNotDate => 'Dit is geen geldige datum.';

  @override
  String get settingScreensaverImmichMetadataTitle => 'Metadata tonen';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      'Toon het album, de datum, camera en locatie over de media.';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => 'Albumnaam';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription =>
      'Laat zien van welk album de foto komt.';

  @override
  String get settingScreensaverImmichMetadataDateTitle => 'Opnamedatum';

  @override
  String get settingScreensaverImmichMetadataDateDescription =>
      'Laat zien wanneer de foto is genomen.';

  @override
  String get settingScreensaverImmichMetadataCameraTitle => 'Cameragegevens';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      'Toont brandpuntsafstand, diafragma en ISO.';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => 'Locatie';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      'Laat zien waar de foto is genomen.';

  @override
  String get settingScreensaverImmichMetadataDescriptionTitle => 'Beschrijving';

  @override
  String get settingScreensaverImmichMetadataDescriptionDescription =>
      'Laat de beschrijving van de foto onderaan het scherm zien.';

  @override
  String get settingScreensaverImmichMetadataPositionTitle =>
      'Positie van metagegevens';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      'In welke hoek de details worden weergegeven.';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle => 'Tekstschaduw';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      'Voeg een schaduw toe aan de tekst met metagegevens zodat deze op foto\'s beter leesbaar is.';

  @override
  String get settingScreensaverImmichMetadataScaleTitle => 'Tekstgrootte';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      'Pas de grootte van de fotogegevens aan zodat deze beter op het scherm past.';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle => 'Vignettesterkte';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      'Bepaalt hoe donker de schaduw achter de details is, zodat deze op lichte foto\'s leesbaar blijven. Stel 0 in om dit uit te schakelen.';

  @override
  String get screensaverMediaMetadata => 'Metadata';

  @override
  String get screensaverMediaTopLeft => 'Linksboven';

  @override
  String get screensaverMediaTopRight => 'Rechtsboven';

  @override
  String get screensaverMediaBottomLeft => 'Linksonder';

  @override
  String get screensaverMediaBottomRight => 'Rechtsonder';

  @override
  String get settingScreensaverImmichIntervalTitle => 'Seconden per afbeelding';

  @override
  String get settingScreensaverImmichShuffleTitle => 'Willekeurige volgorde';

  @override
  String get settingScreensaverImmichShuffleDescription =>
      'Speel de media in willekeurige volgorde af.';

  @override
  String get settingScreensaverImmichTransitionTitle => 'Overgang';

  @override
  String get settingScreensaverImmichTransitionDescription =>
      'De overgang van het ene item naar het volgende.';

  @override
  String get settingScreensaverImmichFillTitle => 'Het scherm vullen';

  @override
  String get settingScreensaverImmichFillDescription =>
      'Uit toont de volledige foto met zwarte balken ernaast. Slim vergroot foto\'s met een beeldverhouding die dicht bij die van het scherm ligt; de rest wordt tegen een vervaagde achtergrond getoond. Altijd vergroot elke foto en snijdt af wat niet op het scherm past.';

  @override
  String get settingScreensaverImmichPairPortraitTitle =>
      'Portretfoto\'s combineren';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      'Toon twee portretfoto\'s naast elkaar zodat ze het scherm vullen.';

  @override
  String get settingScreensaverImmichPairLandscapeTitle =>
      'Liggende foto\'s combineren';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      'Toon twee landschapsfoto\'s boven elkaar zodat ze een portretscherm vullen.';

  @override
  String get settingScreensaverImmichEdgeTapsTitle =>
      'Tik op randen om dia\'s te wijzigen';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      'Een tik op het linker- of rechtervijfde deel van het scherm toont de vorige of volgende dia in plaats van de schermbeveiliging te sluiten.';

  @override
  String get screensaverMediaSlideshow => 'Diavoorstelling';

  @override
  String get settingScreensaverImmichAlbumTitle => 'Mediabron';

  @override
  String get settingScreensaverImmichAlbumDescription =>
      'De volledige bibliotheek of de albums die je selecteert.';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => 'Alleen foto\'s';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription =>
      'Sla video\'s in de diavoorstelling over.';

  @override
  String get settingScreensaverImmichCacheTitle => 'Media lokaal opslaan';

  @override
  String get settingScreensaverImmichCacheDescription =>
      'Bewaar kopieën op het apparaat zodat afbeeldingen direct worden geladen.';

  @override
  String get settingScreensaverImmichCacheMaxTitle => 'Cachegrootte (items)';

  @override
  String get settingScreensaverImmichCacheMaxDescription =>
      'De oudste items worden verwijderd zodra de cache vol is.';

  @override
  String get screensaverMediaAll => 'Alle media';

  @override
  String get screensaverMediaAllDevice => 'Alle media.';

  @override
  String get screensaverMediaNoAlbums =>
      'Nog geen albums. Maak er eerst een in Immich.';

  @override
  String get screensaverMediaAlbumsFailed =>
      'De albums konden niet worden opgehaald';

  @override
  String screensaverMediaListError(String error) {
    return 'De lijst kon niet worden opgehaald: $error';
  }

  @override
  String get screensaverMediaListingFailed => 'lijst ophalen mislukt';

  @override
  String screensaverMediaItems(String count) {
    return '$count items';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return '$count in cache, $size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => 'Cameraweergaven';

  @override
  String get settingScreensaverCameraViewsDescription =>
      'De cameraweergaven die de schermbeveiliging toont, in deze volgorde.';

  @override
  String get settingScreensaverCameraViewSecondsTitle =>
      'Seconden per cameraweergave';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      'Hoelang elke weergave op het scherm blijft voordat de volgende verschijnt. Als je één weergave selecteert, wordt er niet gewisseld.';

  @override
  String get settingScreensaverCameraMuteTitle => 'Alle weergaven dempen';

  @override
  String get settingScreensaverCameraMuteDescription =>
      'Dempt alle weergaven, ook als er maar één camera is geselecteerd.';

  @override
  String get screensaverMediaCameraPage =>
      'Camerastreams als schermbeveiliging';

  @override
  String get screensaverMediaCameraHint =>
      'Weergaven te tonen, seconden per weergave, geluid';

  @override
  String get screensaverMediaNoCameras =>
      'Er zijn nog geen camera\'s. Voeg er een toe bij Camerastreams.';

  @override
  String get screensaverMediaNoCamerasRemote =>
      'Er zijn nog geen cameraweergaven met camera\'s.';

  @override
  String get screensaverMediaAddCameras =>
      'Voeg een camera toe bij Camerastreams.';

  @override
  String get screensaverMediaNoViews =>
      'Nog geen weergaven. Selecteer welke weergaven de schermbeveiliging afwisselt.';

  @override
  String get screensaverMediaRotation =>
      'In de afspeelvolgorde (sleep om de volgorde te wijzigen)';

  @override
  String get screensaverMediaAvailable => 'Beschikbaar';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count camera';
  }

  @override
  String screensaverMediaCameras(String count) {
    return '$count camera\'s';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return 'Positie $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => 'Geen';

  @override
  String get screensaverMediaTransitionFade => 'Vloeiende overgang';

  @override
  String get screensaverMediaTransitionSlide => 'Schuiven';

  @override
  String get screensaverMediaTransitionZoom => 'Zoomen';

  @override
  String get screensaverMediaTransitionKenBurns => 'Ken Burns';

  @override
  String get screensaverMediaTransitionRandom => 'Willekeurig';

  @override
  String get screensaverMediaFillOff => 'Uit';

  @override
  String get screensaverMediaFillSmart => 'Slim';

  @override
  String get screensaverMediaFillAlways => 'Altijd vullen';

  @override
  String get settingScreensaverVideoLengthTitle => 'Videoduur';

  @override
  String get settingScreensaverVideoLengthDescription =>
      'Hoelang elke video speelt voordat de volgende verschijnt.';

  @override
  String get screensaverMediaVideoLengthFull => 'Hele video';

  @override
  String get screensaverMediaVideoLengthInterval => 'Zoals foto\'s';

  @override
  String get settingScreensaverImageIntervalDescription =>
      'Hoelang elke afbeelding wordt getoond voordat de volgende verschijnt.';

  @override
  String get settingScreensaverPhotoIntervalDescription =>
      'Hoelang elke foto wordt getoond voordat de volgende verschijnt.';

  @override
  String get settingScreensaverGalleryItemsTitle => 'Foto\'s';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'De foto\'s en video\'s die deze schermbeveiliging afspeelt. Selecteer ze in de galerij op het apparaat. Als je opnieuw selecteert, wordt de huidige selectie vervangen.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Seconden per foto';

  @override
  String get settingScreensaverGalleryShuffleTitle => 'Willekeurige volgorde';

  @override
  String get settingScreensaverGalleryShuffleDescription =>
      'Speel de selectie in willekeurige volgorde af.';

  @override
  String get settingScreensaverGalleryTransitionTitle => 'Overgang';

  @override
  String get settingScreensaverGalleryTransitionDescription =>
      'De overgang van de ene foto naar de volgende.';

  @override
  String get settingScreensaverGalleryFillTitle => 'Het scherm vullen';

  @override
  String get settingScreensaverGalleryFillDescription =>
      'Uit toont de volledige foto met zwarte balken ernaast. Slim vergroot foto\'s met een beeldverhouding die dicht bij die van het scherm ligt; de rest wordt tegen een vervaagde achtergrond getoond. Altijd vergroot elke foto en snijdt af wat niet op het scherm past.';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle =>
      'Tik op randen om dia\'s te wijzigen';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      'Een tik op het linker- of rechtervijfde deel van het scherm toont de vorige of volgende foto in plaats van de schermbeveiliging te sluiten.';

  @override
  String get screensaverMediaGalleryPage => 'Fotogalerij als schermbeveiliging';

  @override
  String get screensaverMediaGalleryHint =>
      'Foto\'s, timing, willekeurige volgorde en overgangen';

  @override
  String get screensaverMediaLoadingPhotos => 'Foto\'s laden...';

  @override
  String screensaverMediaCopying(String index, String total) {
    return 'Foto $index van $total kopiëren...';
  }

  @override
  String get screensaverMediaCopyFailed => 'Kon de foto\'s niet kopiëren';

  @override
  String get screensaverMediaSmallerSelection =>
      'Probeer een kleinere selectie.';

  @override
  String get screensaverMediaNoPhotos => 'Geen foto\'s geselecteerd';

  @override
  String screensaverMediaSelected(String count) {
    return '$count geselecteerd';
  }

  @override
  String get screensaverMediaPickOnDevice =>
      'Niets geselecteerd. Selecteer foto\'s op het apparaat.';

  @override
  String get settingScreensaverMediaIdTitle => 'Mediabron';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Een media-item, map of camera uit Home Assistant. Gebruik Bladeren om er een te kiezen.';

  @override
  String get settingScreensaverMediaIntervalTitle => 'Seconden per afbeelding';

  @override
  String get settingScreensaverMediaShuffleTitle => 'Willekeurige volgorde';

  @override
  String get settingScreensaverMediaShuffleDescription =>
      'Een map in willekeurige volgorde afspelen.';

  @override
  String get settingScreensaverMediaRecursiveTitle => 'Submappen toevoegen';

  @override
  String get settingScreensaverMediaRecursiveDescription =>
      'Neem ook bestanden uit onderliggende mappen mee wanneer je een map kiest.';

  @override
  String get settingScreensaverMediaTransitionTitle => 'Overgang';

  @override
  String get settingScreensaverMediaTransitionDescription =>
      'De overgang van het ene item naar het volgende.';

  @override
  String get settingScreensaverMediaFillTitle => 'Het scherm vullen';

  @override
  String get settingScreensaverMediaFillDescription =>
      'Uit toont de volledige foto met zwarte balken ernaast. Slim vergroot foto\'s met een beeldverhouding die dicht bij die van het scherm ligt; de rest wordt tegen een vervaagde achtergrond getoond. Altijd vergroot elke foto en snijdt af wat niet op het scherm past.';

  @override
  String get settingScreensaverMediaEdgeTapsTitle =>
      'Tik op randen om dia\'s te wijzigen';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      'Tik in het linker- of rechtervijfde van het scherm om de vorige of volgende afbeelding te tonen in plaats van de schermbeveiliging af te sluiten.';

  @override
  String get settingScreensaverMediaMetadataTitle => 'Metadata tonen';

  @override
  String get settingScreensaverMediaMetadataDescription =>
      'Toon de datum en cameragegevens over de foto.';

  @override
  String get settingScreensaverMediaMetadataDateTitle => 'Opnamedatum';

  @override
  String get settingScreensaverMediaMetadataDateDescription =>
      'Laat zien wanneer de foto is genomen.';

  @override
  String get settingScreensaverMediaMetadataCameraTitle => 'Cameragegevens';

  @override
  String get settingScreensaverMediaMetadataCameraDescription =>
      'Toont brandpuntsafstand, diafragma en ISO.';

  @override
  String get settingScreensaverMediaMetadataPositionTitle =>
      'Positie van metagegevens';

  @override
  String get settingScreensaverMediaMetadataPositionDescription =>
      'In welke hoek de details worden weergegeven.';

  @override
  String get settingScreensaverMediaMetadataTextShadowTitle => 'Tekstschaduw';

  @override
  String get settingScreensaverMediaMetadataTextShadowDescription =>
      'Voeg een schaduw toe aan de tekst met metagegevens zodat deze op foto\'s beter leesbaar is.';

  @override
  String get settingScreensaverMediaMetadataScaleTitle => 'Tekstgrootte';

  @override
  String get settingScreensaverMediaMetadataScaleDescription =>
      'Pas de grootte van de fotogegevens aan zodat deze beter op het scherm past.';

  @override
  String get settingScreensaverMediaVignetteStrengthTitle => 'Vignettesterkte';

  @override
  String get settingScreensaverMediaVignetteStrengthDescription =>
      'Bepaalt hoe donker de schaduw achter de details is, zodat deze op lichte foto\'s leesbaar blijven. Stel 0 in om dit uit te schakelen.';

  @override
  String get screensaverMediaHaMetadata => 'Metadata van Home Assistant-media';

  @override
  String get screensaverMediaHaPage =>
      'Home Assistant-media als schermbeveiliging';

  @override
  String get screensaverMediaHaPageHint =>
      'Mediabron, timing, willekeurige volgorde, schermvulling en metadata';

  @override
  String get screensaverMediaChoose => 'Media kiezen';

  @override
  String get screensaverMediaRoot => 'Media';

  @override
  String get screensaverMediaHaUnavailable =>
      'Home Assistant is niet bereikbaar of het token ontbreekt.';

  @override
  String get screensaverMediaEmpty => 'Deze map is leeg.';

  @override
  String get screensaverMediaUseFolder => 'Deze map gebruiken';

  @override
  String get screensaverMediaFolder => 'map';

  @override
  String get screensaverMediaCamera => 'camera';

  @override
  String get screensaverMediaItem => 'item';

  @override
  String get screensaverMediaBrowseFailed => 'Bladeren is mislukt';

  @override
  String screensaverMediaBrowseError(String error) {
    return 'Kan niet bladeren: $error';
  }

  @override
  String get screensaverMediaNotSet => 'Niet ingesteld';

  @override
  String get settingScreensaverLocalFolderTitle => 'Lokale map';

  @override
  String get settingScreensaverLocalFolderDescription =>
      'De map op dit apparaat met foto\'s en video\'s die de schermbeveiliging afspeelt. Selecteer de map op het apparaat of voer het pad hier op afstand in.';

  @override
  String get settingScreensaverLocalIntervalTitle => 'Seconden per foto';

  @override
  String get settingScreensaverLocalShuffleTitle => 'Willekeurige volgorde';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      'Speel de inhoud van de map in willekeurige volgorde af in plaats van op naam.';

  @override
  String get settingScreensaverLocalRecursiveTitle => 'Submappen toevoegen';

  @override
  String get settingScreensaverLocalRecursiveDescription =>
      'Speel ook foto\'s en video\'s uit submappen af.';

  @override
  String get settingScreensaverLocalTransitionTitle => 'Overgang';

  @override
  String get settingScreensaverLocalTransitionDescription =>
      'De overgang van de ene foto naar de volgende.';

  @override
  String get settingScreensaverLocalFillTitle => 'Het scherm vullen';

  @override
  String get settingScreensaverLocalFillDescription =>
      'Uit toont de volledige foto met zwarte balken ernaast. Slim vergroot foto\'s met een beeldverhouding die dicht bij die van het scherm ligt; de rest wordt tegen een vervaagde achtergrond getoond. Altijd vergroot elke foto en snijdt af wat niet op het scherm past.';

  @override
  String get settingScreensaverLocalEdgeTapsTitle =>
      'Tik op randen om dia\'s te wijzigen';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      'Tik in het linker- of rechtervijfde van het scherm om de vorige of volgende foto te tonen in plaats van de schermbeveiliging af te sluiten.';

  @override
  String get settingScreensaverLocalMetadataTitle => 'Metadata tonen';

  @override
  String get settingScreensaverLocalMetadataDescription =>
      'Toon de datum en cameragegevens over de foto.';

  @override
  String get settingScreensaverLocalMetadataDateTitle => 'Opnamedatum';

  @override
  String get settingScreensaverLocalMetadataDateDescription =>
      'Laat zien wanneer de foto is genomen.';

  @override
  String get settingScreensaverLocalMetadataCameraTitle => 'Cameragegevens';

  @override
  String get settingScreensaverLocalMetadataCameraDescription =>
      'Toont brandpuntsafstand, diafragma en ISO.';

  @override
  String get settingScreensaverLocalMetadataPositionTitle =>
      'Positie van metagegevens';

  @override
  String get settingScreensaverLocalMetadataPositionDescription =>
      'In welke hoek de details worden weergegeven.';

  @override
  String get settingScreensaverLocalMetadataTextShadowTitle => 'Tekstschaduw';

  @override
  String get settingScreensaverLocalMetadataTextShadowDescription =>
      'Voeg een schaduw toe aan de tekst met metagegevens zodat deze op foto\'s beter leesbaar is.';

  @override
  String get settingScreensaverLocalMetadataScaleTitle => 'Tekstgrootte';

  @override
  String get settingScreensaverLocalMetadataScaleDescription =>
      'Pas de grootte van de fotogegevens aan zodat deze beter op het scherm past.';

  @override
  String get settingScreensaverLocalVignetteStrengthTitle => 'Vignettesterkte';

  @override
  String get settingScreensaverLocalVignetteStrengthDescription =>
      'Bepaalt hoe donker de schaduw achter de details is, zodat deze op lichte foto\'s leesbaar blijven. Stel 0 in om dit uit te schakelen.';

  @override
  String get screensaverMediaLocalMetadata => 'Metadata van lokale media';

  @override
  String get screensaverMediaLocalPage => 'Lokale mediaschermbeveiliging';

  @override
  String get screensaverMediaLocalPageHint =>
      'Map, timing, willekeurige volgorde, overgangen en metadata';

  @override
  String get settingScreensaverUrlImageDescription =>
      'Een afbeeldingsadres dat het apparaat voor elke dia opnieuw ophaalt.';

  @override
  String get settingScreensaverUrlIntervalDescription =>
      'Hoelang elke foto wordt getoond voordat de volgende wordt opgehaald.';

  @override
  String get screensaverMediaUrlPage => 'Afbeeldings-URL-schermbeveiliging';

  @override
  String get screensaverMediaUrlPageHint =>
      'URL, timing, overgangen en metadata';

  @override
  String get screensaverMediaUrlMetadata => 'Metadata van afbeeldings-URL';

  @override
  String get settingScreensaverDismissOnMotionTitle => 'Sluiten bij beweging';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      'Gebruik de camera terwijl de schermbeveiliging actief is en activeer het scherm wanneer iemand dichterbij komt. De camera werkt alleen tijdens de schermbeveiliging.';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle =>
      'Alleen als het scherm uit staat';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      'Houd de schermbeveiliging zichtbaar wanneer beweging wordt gedetecteerd terwijl het scherm aan staat. Zodra het scherm uitgaat, activeert de detectie het dashboard. Aanraken sluit de schermbeveiliging nog steeds af.';

  @override
  String get settingScreensaverPostponeOnMotionTitle =>
      'Schermbeveiliging uitstellen bij beweging';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      'Stel het activeren van de schermbeveiliging uit wanneer beweging wordt gedetecteerd. Waarschuwing: de camera blijft voortdurend actief.';

  @override
  String get screensaverDetectionMotionPage => 'Bewegingsdetectie';

  @override
  String get screensaverDetectionMotionHint =>
      'Sluit de schermbeveiliging bij beweging of stel deze uit';

  @override
  String get screensaverDetectionMotionTuning =>
      'Bewegingsdetectie is ingesteld in de Camera-instellingen.';

  @override
  String get settingMotionUseEntityTitle => 'Home Assistant-entiteit gebruiken';

  @override
  String get settingMotionUseEntityDescription =>
      'Detecteer beweging met een Home Assistant-sensor in plaats van de camera.';

  @override
  String get settingMotionEntityTitle => 'Bewegingssensor-entiteit';

  @override
  String get settingMotionEntityDescription =>
      'De Home Assistant-sensor voor bezetting, beweging of aanwezigheid die gevolgd wordt.';

  @override
  String get screensaverDetectionExternalMotionHeading =>
      'Externe bewegingssensor';

  @override
  String get settingScreensaverDismissOnPersonTitle =>
      'Sluiten bij persoonsdetectie';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      'Lees de persoonssensor terwijl de schermbeveiliging actief is en activeer het scherm wanneer er iemand voor staat. Hiervoor is de onderstaande toestemming voor logtoegang vereist.';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle =>
      'Alleen als het scherm uit staat';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      'Houd de schermbeveiliging zichtbaar wanneer iemand verschijnt terwijl het scherm aan staat. Zodra het scherm uitgaat, activeert de detectie het dashboard. Aanraken sluit de schermbeveiliging nog steeds af.';

  @override
  String get settingScreensaverPostponeOnPersonTitle =>
      'Schermbeveiliging uitstellen bij persoonsdetectie';

  @override
  String get settingScreensaverPostponeOnPersonDescription =>
      'Stel het activeren van de schermbeveiliging uit zolang iemand voor het apparaat staat.';

  @override
  String get screensaverDetectionPersonPage => 'Persoonsdetectie';

  @override
  String get screensaverDetectionPersonHint =>
      'Sluit de schermbeveiliging bij detectie door de persoonssensor of stel deze uit';

  @override
  String get screensaverDetectionOccupancy => 'Bezetting';

  @override
  String get screensaverDetectionStatusUnavailable =>
      'Status niet beschikbaar.';

  @override
  String get screensaverDetectionOff => 'Uit.';

  @override
  String get screensaverDetectionStarting => 'Starten...';

  @override
  String get screensaverDetectionWaiting =>
      'Wachten op het eerste signaal. De sensor rapporteert elke 30 seconden zolang iemand in beeld is.';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return 'Laatste hartslag $ago.';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return '${count}s geleden';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return '$count min geleden';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return '$count h geleden';
  }

  @override
  String get screensaverDetectionDetected => 'Gedetecteerd';

  @override
  String get screensaverDetectionClear => 'Geen persoon gedetecteerd';

  @override
  String get screensaverDetectionPermissions => 'Vereiste systeemtoestemmingen';

  @override
  String get screensaverDetectionLogAccess => 'Logtoegang';

  @override
  String get screensaverDetectionChecking => 'Controleren...';

  @override
  String get screensaverDetectionReadable =>
      'De persoonssensor van het apparaat kan worden gelezen.';

  @override
  String get screensaverDetectionRestartRequired =>
      'Toegestaan. Herstart Kiosk Satellite om het toe te passen.';

  @override
  String get screensaverDetectionGrantHelp =>
      'Deze toestemming kan alleen via ADB worden verleend. De documentatie van Meta Portal bevat de volledige opdracht. Start Kiosk Satellite daarna opnieuw.';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      'Deze toestemming kan alleen via ADB worden verleend. Hieronder staat de volledige opdracht, klaar om te kopiëren. Start Kiosk Satellite daarna opnieuw.';

  @override
  String get screensaverDetectionGranted => 'Toegestaan';

  @override
  String get screensaverDetectionMissing => 'Ontbrekend';

  @override
  String get screensaverDetectionRestart => 'Herstarten';

  @override
  String get screensaverDetectionRestartRemote => 'Op apparaat opnieuw starten';

  @override
  String get screensaverDetectionLogRestart =>
      'Logtoegang is verleend, maar wordt pas actief nadat Kiosk Satellite opnieuw is gestart.';

  @override
  String get screensaverDetectionLogMissing => 'Logtoegang is niet verleend.';

  @override
  String get settingScreensaverDismissOnProximityTitle =>
      'Sluiten bij nabijheid';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      'Gebruik de nabijheidssensor terwijl de schermbeveiliging actief is en activeer het scherm wanneer iets dicht bij het apparaat komt. Een apparaat met alleen sensoren voor telefoongesprekken (\'palm\' of \'touch\') werkt niet.';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle =>
      'Alleen als het scherm uit staat';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      'Houd de schermbeveiliging zichtbaar wanneer iets nadert terwijl het scherm aan staat. Zodra het scherm uitgaat, activeert de detectie het dashboard. Aanraken sluit de schermbeveiliging nog steeds af.';

  @override
  String get settingScreensaverPostponeOnProximityTitle =>
      'Schermbeveiliging uitstellen bij nabijheid';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      'Stel het activeren van de schermbeveiliging uit zolang iets zich dicht bij de sensor bevindt.';

  @override
  String get screensaverDetectionProximityPage => 'Nabijheiddetectie';

  @override
  String get screensaverDetectionProximityHint =>
      'Sluit de schermbeveiliging bij detectie door de nabijheidssensor of stel deze uit';

  @override
  String get screensaverDetectionNoProximity =>
      'Niet beschikbaar op dit apparaat: het heeft geen nabijheidssensor.';

  @override
  String get screensaverDetectionSensor => 'Sensor';

  @override
  String get screensaverDetectionSensorHelp =>
      'Wat het apparaat meldt als de nabijheidssensor. Een sensor voor gesprekken genaamd \"palm\" of \"touch\" zal niet werken.';

  @override
  String get settingScreensaverScheduleEnabledTitle =>
      'Geplande schermbeveiligingen inschakelen';

  @override
  String get settingScreensaverScheduleEnabledDescription =>
      'Schakel op vaste tijdstippen over naar een andere schermbeveiliging.';

  @override
  String get settingScreensaverScheduleTitle => 'Tijden';

  @override
  String get settingScreensaverScheduleDescription =>
      'Elk tijdstip schakelt vanaf dat moment over naar de ingestelde schermbeveiliging.';

  @override
  String get screensaverScheduleSection => 'Schermbeveiliging plannen';

  @override
  String get screensaverTime => 'Tijd';

  @override
  String get screensaverAddTime => 'Tijd toevoegen';

  @override
  String get screensaverRemoveTime => 'Tijd verwijderen';

  @override
  String get screensaverNoTimes => 'Nog geen tijden';

  @override
  String get screensaverTimeHelp => 'Een schermbeveiliging vanaf die tijd.';

  @override
  String get screensaverPickTime => 'Kies een tijd.';

  @override
  String get screensaverDefault => 'Standaard';

  @override
  String get screensaverOn => 'Aan';

  @override
  String get screensaverOff => 'Uit';

  @override
  String get screensaverBrightness => 'Helderheid';

  @override
  String get screensaverBrightnessFollow =>
      'Volgt de helderheidsinstelling van de schermbeveiliging.';

  @override
  String get screensaverBrightnessExceptBlack =>
      'Geldt voor alle modi behalve Zwart.';

  @override
  String get screensaverScreenOffFollow =>
      'Volgt de instelling \'Scherm uitschakelen na\'.';

  @override
  String get screensaverScreenOnHours =>
      'Houdt het scherm aan gedurende deze uren.';

  @override
  String get screensaverScreenOffHelp =>
      'Schakelt het scherm uit zodra de schermbeveiliging zo lang actief is geweest. Hiervoor is toestemming voor apparaatbeheer vereist.';

  @override
  String get screensaverScreenOffNever => 'Scherm nooit uitschakelen';

  @override
  String get screensaverMotion => 'Sluiten bij beweging';

  @override
  String get screensaverFace => 'Sluiten bij gezichtsdetectie';

  @override
  String get screensaverProximity => 'Sluiten bij nabijheid';

  @override
  String get screensaverPerson => 'Sluiten bij persoonsdetectie';

  @override
  String get screensaverWidgets => 'Widgets';

  @override
  String get screensaverGlance => 'In één oogopslag';

  @override
  String get screensaverNowPlaying =>
      'Speelt nu naast de schermbeveiliging tonen';

  @override
  String get screensaverNowPlayingHelp =>
      'Standaard volgt de algemene indeling. Aan gebruikt een gedeelde indeling wanneer Speelt nu is ingeschakeld. Uit verbergt Speelt nu tijdens deze uren.';

  @override
  String get screensaverCameraRequired =>
      'Hiervoor is de camera nodig. Schakel deze eerst in bij Camera-instellingen.';

  @override
  String get screensaverNotAvailable => 'Niet beschikbaar op dit apparaat.';

  @override
  String get screensaverSummaryMotionOn => 'Beweging aan';

  @override
  String get screensaverSummaryMotionOff => 'Beweging uit';

  @override
  String get screensaverSummaryFaceOn => 'Gezicht aan';

  @override
  String get screensaverSummaryFaceOff => 'Gezicht uit';

  @override
  String get screensaverSummaryProximityOn => 'Nabijheid aan';

  @override
  String get screensaverSummaryProximityOff => 'Nabijheid uit';

  @override
  String get screensaverSummaryPersonOn => 'Persoonsdetectie aan';

  @override
  String get screensaverSummaryPersonOff => 'Persoonsdetectie uit';

  @override
  String get screensaverSummaryWidgetsOn => 'Widgets aan';

  @override
  String get screensaverSummaryWidgetsOff => 'Widgets uit';

  @override
  String get screensaverSummaryGlanceOn => 'In één oogopslag aan';

  @override
  String get screensaverSummaryGlanceOff => 'In één oogopslag uit';

  @override
  String get screensaverSummaryNowPlayingOn => 'Speelt nu aan';

  @override
  String get screensaverSummaryNowPlayingOff => 'Speelt nu uit';

  @override
  String screensaverBrightnessPercent(String percent) {
    return '$percent% helderheid';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return 'Scherm uitschakelen na $minutes min';
  }

  @override
  String get screensaverWeatherMood => 'Weerscène';

  @override
  String get screensaverWeatherMoodPage => 'Weerscène als schermbeveiliging';

  @override
  String get screensaverWeatherMoodSummary =>
      'Weerentiteit, onweer en voorbeeldweergave';

  @override
  String get settingScreensaverWeatherEntityTitle => 'Weerentiteit';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      'De Home Assistant-weerentiteit die de animatie aanstuurt. De dag-, dageraad- en nachtweergave volgen sun.sun, met de lokale tijd als terugvaloptie.';

  @override
  String get settingScreensaverWeatherLightningTitle => 'Bliksemflitsen';

  @override
  String get settingScreensaverWeatherLightningDescription =>
      'Toon blikseminslagen en wolkenflitsen tijdens onweer.';

  @override
  String get screensaverWeatherMoodSelectEntity =>
      'Selecteer een weerentiteit via Instellingen > Schermbeveiliging > Weerscène.';

  @override
  String get screensaverWeatherPreviewGroup => 'Voorbeeldweergave van het weer';

  @override
  String get settingScreensaverWeatherPreviewTitle =>
      'Weervoorbeeld inschakelen';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      'Toon de geselecteerde scène in plaats van het actuele weer. Schakel dit uit om weer de gegevens van Home Assistant te volgen.';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => 'Weertype';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      'De geanimeerde weerscène om te bekijken.';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle => 'Tijd van de dag';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      'Kies de dag-, dageraad-/schemerings- of nachtversie van de scène.';

  @override
  String get screensaverWeatherPreviewSunny => 'Helder';

  @override
  String get screensaverWeatherPreviewPartlycloudy => 'Halfbewolkt';

  @override
  String get screensaverWeatherPreviewCloudy => 'Bewolkt';

  @override
  String get screensaverWeatherPreviewRainy => 'Regen';

  @override
  String get screensaverWeatherPreviewPouring => 'Stortregen';

  @override
  String get screensaverWeatherPreviewSnowy => 'Sneeuw';

  @override
  String get screensaverWeatherPreviewSnowyRainy => 'Sneeuw en regen';

  @override
  String get screensaverWeatherPreviewFog => 'Mist';

  @override
  String get screensaverWeatherPreviewHail => 'Hagel';

  @override
  String get screensaverWeatherPreviewLightning => 'Bliksem';

  @override
  String get screensaverWeatherPreviewLightningRainy => 'Bliksem en regen';

  @override
  String get screensaverWeatherPreviewWindy => 'Wind';

  @override
  String get screensaverWeatherPreviewWindyVariant => 'Wind en wolken';

  @override
  String get screensaverWeatherPreviewExceptional => 'Uitzonderlijk weer';

  @override
  String get screensaverWeatherPreviewDay => 'Dag';

  @override
  String get screensaverWeatherPreviewNight => 'Nacht';

  @override
  String get settingScreensaverWeatherClockTitle => 'Klok inschakelen';

  @override
  String get settingScreensaverWeatherClockDescription =>
      'Toon een digitale klok over de weerscène.';

  @override
  String get screensaverWeatherTextShadowDescription =>
      'Voeg een slagschaduw toe aan tekst voor leesbaarheid over de weerscène.';

  @override
  String get screensaverWeatherBarGroup => 'Weerinformatie';

  @override
  String get settingScreensaverWeatherBarTitle => 'Weerbalk inschakelen';

  @override
  String get settingScreensaverWeatherBarDescription =>
      'Toon live weerinformatie langs de onderkant van het scherm.';

  @override
  String get settingScreensaverWeatherBarScaleTitle => 'Tekstschaal';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      'Schaal de weerinformatie van 50 tot 200 procent.';

  @override
  String get settingScreensaverWeatherBarColorTitle => 'Tekstkleur';

  @override
  String get settingScreensaverWeatherBarColorDescription =>
      'De kleur van de weerinformatie.';

  @override
  String get settingScreensaverWeatherBarOpacityTitle => 'Achtergronddekking';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      'Verduister de onderste balk om weerinformatie leesbaar te houden.';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => 'Titels tonen';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      'Toon de naam van elke meting boven de waarde. Als dit uitstaat, worden de waarden even groot als de temperatuur weergegeven.';

  @override
  String get screensaverWeatherBarHumidityDescription =>
      'Toon vochtigheid wanneer de weerentiteit het meldt.';

  @override
  String get screensaverWeatherBarWindDescription =>
      'Toon windsnelheid wanneer de weerentiteit het meldt.';

  @override
  String get screensaverWeatherBarVisibilityDescription =>
      'Zichtbaarheid tonen wanneer de weerentiteit het meldt.';

  @override
  String get settingScreensaverWeatherBlurTitle => 'Vervaging van scène';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      'Vervaag de geanimeerde weerscène, maar houd de klok, weerbalk en widgets scherp.';

  @override
  String get screensaverWeatherPreviewTwilight => 'Dageraad/schemering';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      'Toon de schijnbare temperatuur in plaats van de werkelijke temperatuur wanneer beschikbaar.';

  @override
  String get settingScreensaverWebsiteUrlTitle => 'Website-URL';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      'Een pagina die schermvullend wordt weergegeven. De website moet insluiten toestaan.';

  @override
  String get settingScreensaverWebsiteZoomTitle => 'Zoomniveau';

  @override
  String get settingScreensaverWebsiteZoomDescription =>
      'Past de schaal aan van de volledige webweergave van de externe schermbeveiliging.';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle =>
      'Dubbele tik om af te sluiten';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription =>
      'Enkele tikken werken met de website en sluiten de schermbeveiliging niet af.';

  @override
  String get screensaverWebsiteSection => 'Website als schermbeveiliging';

  @override
  String get screensaverOverlaySmallClock => 'Kleine klok';

  @override
  String get screensaverOverlayWeather => 'Weer';

  @override
  String get screensaverOverlayBattery => 'Batterij';

  @override
  String get screensaverOverlayClockNote =>
      'Verborgen in de modi Digitale klok en Camerastreams.';

  @override
  String get screensaverOverlayCameraNote =>
      'Verborgen in de modus Camerastreams.';

  @override
  String get screensaverOverlayScale => 'Grootte';

  @override
  String get screensaverOverlayScaleHelp =>
      'Pas de grootte van deze widget aan zodat deze beter op het scherm past.';

  @override
  String get screensaverOverlayFont => 'Lettertypefamilie';

  @override
  String get screensaverOverlayCorner => 'Hoek';

  @override
  String get screensaverOverlayWidget => 'Widget';

  @override
  String get screensaverOverlayClock24 => '24-uursklok';

  @override
  String get screensaverOverlayClock24Help =>
      'Toon een 24-uurstijd in plaats van AM/PM.';

  @override
  String get screensaverOverlayShowDate => 'Datum tonen';

  @override
  String get screensaverOverlayShowDateHelp =>
      'Voeg een korte datum onder de klok toe.';

  @override
  String get screensaverOverlayPercentage => 'Percentage tonen';

  @override
  String get screensaverOverlayPercentageHelp =>
      'Toon het laadpercentage naast het pictogram.';

  @override
  String get screensaverOverlayLow => 'Alleen bij bijna lege batterij';

  @override
  String get screensaverOverlayLowHelp =>
      'Blijf verborgen totdat de batterij minder dan 20 procent lading heeft.';

  @override
  String get screensaverOverlayShowName => 'Naam tonen';

  @override
  String get screensaverOverlayShowNameHelp => 'De naam onder de waarde.';

  @override
  String get screensaverOverlayShowIcon => 'Pictogram tonen';

  @override
  String get screensaverOverlayShowIconHelp => 'Het pictogram naast de waarde.';

  @override
  String get screensaverOverlayVisibleStates => 'Zichtbare statussen';

  @override
  String get screensaverOverlayVisibleStatesHelp =>
      'Toon de widget alleen als de waarde een van deze is, gescheiden door komma\'s. Laat leeg om hem altijd te tonen.';

  @override
  String get screensaverOverlayFontSystem => 'Systeemlettertype';

  @override
  String get screensaverOverlayFontSerif => 'Schreefletter';

  @override
  String get screensaverOverlayFontCondensed => 'Gecondenseerd';

  @override
  String get screensaverOverlayFontMonospace => 'Vaste tekenbreedte';

  @override
  String get screensaverOverlayFontCasual => 'Speels';

  @override
  String get screensaverOverlayFontCursive => 'Schrijfletter';

  @override
  String get screensaverOverlayColor => 'Kleur';

  @override
  String get screensaverOverlayWeatherEntity => 'Weerentiteit';

  @override
  String get screensaverOverlayWeatherRequired => 'Kies een weerentiteit.';

  @override
  String get screensaverOverlayLocationName => 'Locatienaam';

  @override
  String get screensaverOverlayLocationHelp =>
      'Laat dit leeg om de locatieregel te verbergen.';

  @override
  String get screensaverOverlayLocation => 'Locatie';

  @override
  String get screensaverOverlayLocationDetail =>
      'De plaatsnaam boven de temperatuur.';

  @override
  String get screensaverOverlayFeelsLike => 'Gevoelstemperatuur';

  @override
  String get screensaverOverlayFeelsLikeHelp =>
      'Toon de gevoelstemperatuur met een label onder de actuele temperatuur.';

  @override
  String get screensaverOverlayFeelsLikeOnly => 'Alleen gevoelstemperatuur';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp =>
      'Toon de gevoelstemperatuur met het label \'Gevoelstemperatuur\' in plaats van de actuele temperatuur.';

  @override
  String get screensaverOverlayForecast => 'Voorspelling';

  @override
  String get screensaverOverlayForecastHelp =>
      'De weersomstandigheden met een bijpassend pictogram.';

  @override
  String get screensaverOverlayHighLow => 'Hoogste en laagste';

  @override
  String get screensaverOverlayHighLowHelp =>
      'De hoogste en laagste temperatuur van vandaag.';

  @override
  String get screensaverOverlayForecastWidget => 'Weersvoorspelling';

  @override
  String get screensaverOverlayForecastDays => 'Getoonde dagen';

  @override
  String get screensaverOverlayForecastToday => 'Vandaag meenemen';

  @override
  String get screensaverOverlayForecastTodayHelp =>
      'Begin de lijst met de voorspelling van vandaag.';

  @override
  String get screensaverOverlayForecastColored => 'Gekleurde pictogrammen';

  @override
  String get screensaverOverlayForecastColoredHelp =>
      'Toon de weerpictogrammen in hun eigen kleuren.';

  @override
  String get screensaverOverlayHumidity => 'Vochtigheid';

  @override
  String get screensaverOverlayWind => 'Windsnelheid';

  @override
  String get screensaverOverlayVisibility => 'Zicht';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return 'Gevoelstemperatuur: $temperature';
  }

  @override
  String get settingScreensaverWidgetsEnabledTitle =>
      'Schermbeveiligingswidgets inschakelen';

  @override
  String get settingScreensaverWidgetsEnabledDescription =>
      'Kleine elementen in de hoeken van de schermbeveiliging.';

  @override
  String get settingScreensaverWidgetsTitle => 'Widgets';

  @override
  String get settingScreensaverWidgetsDescription =>
      'Kleine elementen in de hoeken van de schermbeveiliging.';

  @override
  String get settingScreensaverWidgetScaleTitle => 'Globale widgetschaal';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      'Schaal alle widgets tegelijk zodat ze beter op het scherm passen. De onderlinge grootteverhouding blijft behouden.';

  @override
  String get settingScreensaverWidgetFontTitle => 'Algemene lettertypefamilie';

  @override
  String get settingScreensaverWidgetFontDescription =>
      'Het lettertype voor alle widgets. Per widget kan een ander lettertype worden gekozen.';

  @override
  String get settingScreensaverWidgetFontWeightTitle => 'Algemene tekstdikte';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      'Bepaalt hoe vet de tekst van alle widgets wordt weergegeven. Standaard gebruikt elke regel zijn eigen dikte. Per widget kan hiervan worden afgeweken.';

  @override
  String get settingScreensaverWidgetTextShadowTitle => 'Tekstschaduw';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      'Voeg een schaduw toe aan widgettekst zodat deze op foto\'s beter leesbaar is.';

  @override
  String get settingScreensaverVignetteStrengthTitle => 'Vignettesterkte';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      'Bepaalt hoe donker de schaduw achter de widgets is, zodat ze op lichte foto\'s leesbaar blijven. Stel 0 in om dit uit te schakelen.';

  @override
  String get screensaverOverlayWidgetsEmpty => 'Nog geen widgets';

  @override
  String get screensaverOverlayShow => 'Deze widget tonen';

  @override
  String get screensaverOverlayRemove => 'Widget verwijderen';

  @override
  String get screensaverOverlayAdd => 'Widget toevoegen';

  @override
  String get screensaverOverlayAddHelp =>
      'Voeg in een hoek een kleine klok, het weer, de batterijstatus of een entiteit toe.';

  @override
  String get screensaverOverlayWidgetsHint =>
      'Widgets in de hoeken en hun schaal';

  @override
  String get settingsSearchHint => 'Instellingen zoeken';

  @override
  String get settingsSearchClear => 'Zoekopdracht wissen';

  @override
  String get settingsSearchResults => 'Zoekresultaten';

  @override
  String settingsSearchEmpty(String query) {
    return 'Geen instellingen gevonden voor \"$query\".';
  }

  @override
  String get searchInstallApk =>
      'Upload een APK van Kiosk Satellite via het beheer op afstand en installeer die.';

  @override
  String get searchPermissionsHelp =>
      'Elke Android-toestemming die de app kan gebruiken, met de status ervan: microfoon, camera, meldingen, onbeperkt batterijgebruik, over andere apps weergeven, systeeminstellingen wijzigen, beveiliging van de systeeminterface, apparaatbeheer, toegang tot alle bestanden, toegang tot gebruiksgegevens en locatie.';

  @override
  String get searchServiceStatus => 'Servicestatus';

  @override
  String get searchServiceHelp =>
      'Of de Kiosk Satellite Service actief is en wat die in stand houdt.';

  @override
  String get searchServicePermissions =>
      'De toestemmingen die de Kiosk Satellite Service nodig heeft.';

  @override
  String get searchIntercomKiosks =>
      'Bekende kiosken en of elk daarvan een gesprek kan aannemen.';

  @override
  String get searchHaValidate =>
      'Controleer de URL en het token bij je Home Assistant.';

  @override
  String get searchHaProxy =>
      'Stel een Home Assistant op gewone http beschikbaar via een beveiligde proxy in de app.';

  @override
  String get searchHaDashboard =>
      'Kies het dashboard en de weergave die de kiosk laat zien.';

  @override
  String get searchKioskPermissions =>
      'De toestemmingen waarop de kiosk- en vergrendelingsbeveiligingen steunen.';

  @override
  String get searchHomeStatus => 'Status van het startscherm';

  @override
  String get searchHomeHelp =>
      'Of Kiosk Satellite het startscherm van het apparaat is en waar je dat als standaard instelt.';

  @override
  String get searchMasterVolume =>
      'Het apparaatvolume waaronder de volumeregelaars voor media en assistent schalen.';

  @override
  String get searchSmallClock =>
      'Een klokwidget in een hoek van de schermbeveiliging.';

  @override
  String get searchBattery =>
      'Een batterijwidget in een hoek van de schermbeveiliging: de eigen lading van dit apparaat.';

  @override
  String get searchWeatherForecast =>
      'Een voorspellingswidget in een hoek van de schermbeveiliging: de komende dagen met hun hoogste en laagste temperatuur.';

  @override
  String get searchPersonPermission =>
      'De toestemming voor logtoegang die de persoonssensor van het apparaat nodig heeft.';

  @override
  String get searchSonosSpeakers =>
      'De Sonos-luidsprekers die dit apparaat kent, een zoekopdracht op het netwerk en een adresveld.';

  @override
  String get voiceAppearanceHint =>
      'Vormgeving van de overlay, thema, activiteitsbalk en tekstgrootte';

  @override
  String get voiceSkin => 'Vormgeving';

  @override
  String get voiceSkinHelp => 'Het uiterlijk van de spraakassistent-overlay.';

  @override
  String get voiceSkin1 => 'Vormgeving van Assistent 1';

  @override
  String get voiceSkin1Help =>
      'Het uiterlijk van de overlay wanneer Assistent 1 antwoordt.';

  @override
  String get voiceSkin2 => 'Vormgeving van Assistent 2';

  @override
  String get voiceSkin2Help =>
      'Het uiterlijk van de overlay wanneer Assistent 2 antwoordt.';

  @override
  String get voiceTheme => 'Themamodus';

  @override
  String get voiceThemeHelp => 'Lichte of donkere weergave van de overlay.';

  @override
  String get voiceReactive => 'Reactieve activiteitsbalk';

  @override
  String get voiceReactiveHelp =>
      'De activiteitsbalk reageert op audio. Niet aanbevolen voor apparaten met weinig rekenkracht, zoals de Echo Show.';

  @override
  String get voiceRate => 'Verversingssnelheid van de activiteitsbalk';

  @override
  String get voiceRateHelp =>
      'Hoe vaak de activiteitsbalk opnieuw wordt getekend. Een hogere snelheid geeft vloeiendere animaties en gebruikt meer processorkracht.';

  @override
  String get voiceScaleHelp => 'De grootte van de overlaytekst.';

  @override
  String get voiceUpdateIntegration =>
      'Update de Voice Satellite-integratie in Home Assistant om deze instellingen vanuit de kiosk te bedienen.';

  @override
  String get voiceDashboardRequired =>
      'Beschikbaar terwijl de kiosk je Home Assistant-dashboard toont.';

  @override
  String get voiceSkinUnavailablePlugin =>
      'Vormgeving van plug-in niet beschikbaar';

  @override
  String get voiceSkinDefault => 'Standaardvormgeving';

  @override
  String get voiceBackground => 'Achtergrond';

  @override
  String get voiceBackgroundHelp =>
      'Hoeveel van het dashboard er doorheen komt.';

  @override
  String get voicePreview => 'Voorbeeld';

  @override
  String get voicePreviewHelp =>
      'Toon de overlay op dit scherm gedurende vijf seconden.';

  @override
  String get voicePreviewRemoteHelp =>
      'Toon de overlay vijf seconden op het kioskscherm.';

  @override
  String get settingVoiceThemeTitle => 'Thema';

  @override
  String get settingVoiceThemeDescription =>
      'Auto volgt het Home Assistant-thema.';

  @override
  String get settingVoiceBackgroundDescription =>
      'Hoeveel van het dashboard zichtbaar blijft. Bij -1 geldt de standaardwaarde van de vormgeving.';

  @override
  String get settingVoiceTextScaleTitle => 'Tekstgrootte';

  @override
  String get settingVoiceReactiveBarTitle => 'Reactieve activiteitsbalk';

  @override
  String get settingVoiceReactiveBarDescription =>
      'De balk reageert op je stem en het antwoord.';

  @override
  String get voicePreviewCommand => 'Wat is het weer?';

  @override
  String get voicePreviewAnswer => 'Nu zonnig en 22°, met een lichte bries.';

  @override
  String get settingVoiceOverlayModeTitle => 'Overlaymodus';

  @override
  String get settingVoiceOverlayModeDescription =>
      'In de compacte modus verschijnt een kleine bubbel over het dashboard. Deze toont geen uitgebreide resultaten zoals afbeeldingen, weer of video\'s.';

  @override
  String get voiceOverlayFullScreen => 'Volledig scherm';

  @override
  String get voiceOverlayDocked => 'Compact';

  @override
  String get voiceListeningEllipsis => 'Luisteren…';

  @override
  String get voiceSkinVoiceOnly => 'Alleen spraak';

  @override
  String get voiceAssistant1 => 'Assistent 1';

  @override
  String get voiceAssistant1Help => 'Beantwoordt wekwoord 1.';

  @override
  String get voiceAssistant2 => 'Assistent 2';

  @override
  String get voiceAssistant2Help => 'Beantwoordt wekwoord 2.';

  @override
  String get voicePipelines => 'Pijplijnen';

  @override
  String get voicePreferred => 'Voorkeur';

  @override
  String get voiceNone => 'Geen';

  @override
  String get voiceThisKiosk => 'Deze kiosk';

  @override
  String get voiceSelectFailed =>
      'Dit kon niet worden gewijzigd in Home Assistant.';

  @override
  String get settingVoiceSeamlessWakeTitle => 'Praat direct na het wekwoord';

  @override
  String get settingVoiceSeamlessWakeAssistDescription =>
      'Sla het wekgeluid over en neem op wat je direct na het wekwoord zegt. Alleen voor Assist-pijplijnen, niet voor realtime gesprekken.';

  @override
  String get settingVoiceFollowupDelayTitle => 'Follow-upvertraging';

  @override
  String get settingVoiceFollowupDelayDescription =>
      'De pauze voordat er naar je antwoord op een vervolgvraag wordt geluisterd.';

  @override
  String get settingVoiceFollowupChimeTitle =>
      'Wekgeluid voor een vervolgvraag';

  @override
  String get settingVoiceFollowupChimeDescription =>
      'Speel het wekgeluid af wanneer er opnieuw wordt geluisterd.';

  @override
  String get settingVoiceTtsOutputTitle => 'Geluiden afspelen op';

  @override
  String get settingVoiceTtsOutputDescription =>
      'Wekgeluiden, antwoorden, aankondigingen en timerwaarschuwingen worden via deze luidspreker afgespeeld.';

  @override
  String get settingVoiceTtsOutputModeTitle => 'Afspelen als';

  @override
  String get settingVoiceTtsOutputModeDescription =>
      'Bij een aankondiging kan de luidspreker de muziek pauzeren en daarna hervatten. Bij normaal afspelen start de muziek achteraf opnieuw. Gebruik dit voor luidsprekers die aankondigingen niet ondersteunen.';

  @override
  String get voiceOptionAnnouncement => 'Aankondiging';

  @override
  String get voiceOptionNormalPlayback => 'Normaal afspelen';

  @override
  String get voiceChimesPage => 'Geluiden';

  @override
  String get voiceChimesHint =>
      'Wek-, gereed-, fout-, timer- en aankondigingsgeluiden';

  @override
  String get voiceChimesPreview => 'Voorbeeld op kiosk';

  @override
  String get voiceChimesPreviewFailed => 'Kon het geluid niet afspelen.';

  @override
  String get voiceChimesHelp =>
      'Kies geluiden voor deze kiosk en upload hier aangepaste bestanden. Geluiden die in Home Assistant zijn opgeslagen, worden niet gebruikt voor lokale meldingsgeluiden.';

  @override
  String get voiceChimeWakeTitle => 'Wekgeluid';

  @override
  String get voiceChimeWakeDescription =>
      'Speelt af wanneer Voice Satellite begint te luisteren.';

  @override
  String get voiceChimeDoneTitle => 'Gereedgeluid';

  @override
  String get voiceChimeDoneDescription =>
      'Wordt afgespeeld wanneer een spraakinteractie is voltooid.';

  @override
  String get voiceChimeErrorTitle => 'Foutgeluid';

  @override
  String get voiceChimeErrorDescription =>
      'Wordt afgespeeld wanneer een spraakinteractie mislukt.';

  @override
  String get voiceChimeTimerTitle => 'Timergeluid';

  @override
  String get voiceChimeTimerDescription =>
      'Wordt herhaald wanneer een timer afloopt, totdat je de melding sluit.';

  @override
  String get voiceChimeAnnounceTitle => 'Aankondigingsgeluid';

  @override
  String get voiceChimeAnnounceDescription =>
      'Wordt afgespeeld vóór een Voice Satellite-aankondiging, tenzij die een eigen geluid bevat.';

  @override
  String get settingVoiceWakeSoundTitle => 'Meldingsgeluiden afspelen';

  @override
  String get settingVoiceWakeSoundDescription =>
      'De wek-, gereed- en foutgeluiden.';

  @override
  String get voiceChimeWakeVolumeTitle => 'Volume van het wekgeluid';

  @override
  String get voiceChimeDoneVolumeTitle => 'Volume van het gereedgeluid';

  @override
  String get voiceChimeErrorVolumeTitle => 'Volume van het foutgeluid';

  @override
  String get voiceChimeTimerVolumeTitle => 'Volume van het timergeluid';

  @override
  String get voiceChimeAnnounceVolumeTitle =>
      'Volume van het aankondigingsgeluid';

  @override
  String get voiceChimeVolumeDescription =>
      'Een aandeel van het assistentvolume.';

  @override
  String get settingVoiceShowCommandTitle => 'Tonen wat je hebt gezegd';

  @override
  String get settingVoiceShowCommandDescription =>
      'Toon je opdracht boven het antwoord.';

  @override
  String get settingVoiceShowAnswerTitle => 'Antwoord tonen';

  @override
  String get settingVoiceShowAnswerDescription =>
      'Toon het antwoord terwijl het wordt uitgesproken.';

  @override
  String get settingVoiceShowToolsTitle => 'Toolgebruik tonen';

  @override
  String get settingVoiceShowToolsDescription =>
      'Een regel voor elke actie die de assistent uitvoert.';

  @override
  String get settingVoiceHideSentimentTagsTitle => 'Sentimenttags verbergen';

  @override
  String get settingVoiceHideSentimentTagsDescription =>
      'Verberg labels zoals [happy] die sommige assistenten toevoegen.';

  @override
  String get settingVoiceAnswerLingerTitle =>
      'Het antwoord op het scherm houden';

  @override
  String get settingVoiceAnswerLingerDescription =>
      'Nadat het antwoord is uitgesproken.';

  @override
  String get settingVoiceResultsLingerTitle =>
      'Resultaten op het scherm houden';

  @override
  String get settingVoiceResultsLingerDescription =>
      'Afbeeldingen, weer en andere resultaten. Stel 0 in om ze te tonen totdat je ze sluit.';

  @override
  String get settingVoiceAnnouncementLingerTitle => 'Duur van aankondiging';

  @override
  String get settingVoiceAnnouncementLingerDescription =>
      'Na een aankondiging.';

  @override
  String get voiceEngine => 'Engine';

  @override
  String get voiceEngineHelp => 'Start of stop de Voice Satellite-engine.';

  @override
  String get voiceAssigned => 'Toegewezen satelliet';

  @override
  String get voiceAssignedHelp =>
      'De assist_satellite-entiteit waarmee deze kiosk zich in Home Assistant identificeert. Als je deze wijzigt, wordt het dashboard opnieuw geladen.';

  @override
  String get voiceAssignedSearch =>
      'De assist_satellite-entiteit waarmee deze kiosk zich in Home Assistant identificeert.';

  @override
  String get voiceNoneAssigned => 'Geen toegewezen satelliet';

  @override
  String get voiceAutoStart => 'Automatisch starten';

  @override
  String get voiceAutoStartHelp =>
      'Start Voice Satellite automatisch wanneer het dashboard wordt geladen.';

  @override
  String get voiceMuteHelp => 'Stop met luisteren naar wekwoorden.';

  @override
  String get voicePipeline1 => 'Assist-pijplijn 1';

  @override
  String get voicePipeline1Help =>
      'De Assist-pijplijn die spraakopdrachten verwerkt.';

  @override
  String get voicePipeline2 => 'Assist-pijplijn 2';

  @override
  String get voicePipeline2Help =>
      'De pijplijn die wordt gebruikt wanneer het tweede wekwoord wordt herkend.';

  @override
  String get voiceVad => 'Detectie van einde spraak';

  @override
  String get voiceVadHelp =>
      'Hoe lang de pauze moet duren voordat een spraakopdracht als voltooid geldt.';

  @override
  String get voiceMutedWarning =>
      'Waarschuwing van gedempte microfoon uitschakelen';

  @override
  String get voiceMutedWarningHelp =>
      'Verberg de gedempte microfoonwaarschuwing bij het opstarten en wanneer de satellietmicrofoon gedempt is.';

  @override
  String get voiceDebug => 'Foutopsporingslogboek';

  @override
  String get voiceDebugHelp =>
      'Debug-informatie van Voice Satellite tonen in de browserconsole.';

  @override
  String get voiceVersion => 'Voice Satellite-versie';

  @override
  String get voiceVersionHelp =>
      'De versie van de integratie die in Home Assistant is geïnstalleerd.';

  @override
  String get voiceVadDefault => 'Standaard';

  @override
  String get voiceVadRelaxed => 'Ruim';

  @override
  String get voiceVadAggressive => 'Agressief';

  @override
  String get voiceGeneral => 'Algemeen';

  @override
  String get voiceStart => 'Start';

  @override
  String get voiceNotavailable => 'Niet beschikbaar';

  @override
  String get voiceDisabled => 'Uitgeschakeld';

  @override
  String get settingWakeWordBackgroundTitle =>
      'Blijf luisteren op de achtergrond';

  @override
  String get settingWakeWordBackgroundDescription =>
      'Blijf naar het wekwoord luisteren terwijl een andere app op de voorgrond staat en keer terug zodra het wordt herkend. Hiervoor zijn een permanente melding en toestemming om over andere apps weer te geven nodig.';

  @override
  String get settingWakeWordReturnToBackgroundTitle => 'Terug naar vorige app';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      'Keer terug naar de vorige app of het startscherm wanneer een spraakinteractie Kiosk Satellite naar de voorgrond heeft gebracht en is afgelopen.';

  @override
  String get voiceAssistant => 'Assistent';

  @override
  String get voiceConversation => 'Gesprek';

  @override
  String get voiceTimers => 'Timers';

  @override
  String get voiceAssistantHint => 'Pijplijnen en vervolgvragen';

  @override
  String get voiceConversationHint =>
      'Wat de overlay laat zien en voor hoe lang';

  @override
  String get voiceTimersHint =>
      'Labels, waarschuwingen en gesproken herinneringen';

  @override
  String get voiceSectionFollowUp => 'Vervolgvraag';

  @override
  String get voiceSectionLinger => 'Weergaveduur';

  @override
  String get voiceSectionOnScreen => 'Op het scherm';

  @override
  String get voiceSectionPills => 'Labels';

  @override
  String get voiceSectionSpeaker => 'Luidspreker';

  @override
  String get voiceSectionWakeCommand => 'Wekwoord en spraakopdracht';

  @override
  String get voiceSectionTimerEnds => 'Wanneer een timer eindigt';

  @override
  String get voiceStatusEsphomeOff => 'De ESPHome-server is uitgeschakeld.';

  @override
  String get voiceStatusNotAdded =>
      'Deze kiosk is nog niet toegevoegd aan Home Assistant.';

  @override
  String get voiceStatusMuted => 'De microfoon is gedempt.';

  @override
  String get voiceStatusNotListening =>
      'Er wordt niet naar het wekwoord geluisterd.';

  @override
  String get voiceStatusListening => 'Luisteren naar het wekwoord.';

  @override
  String get voiceWordNotAdded => 'Niet toegevoegd';

  @override
  String get voiceWordMuted => 'Gedempt';

  @override
  String get voiceWordBusy => 'Bezet';

  @override
  String get voiceWordListening => 'Luisteren';

  @override
  String get voiceWordNotListening => 'Niet aan het luisteren';

  @override
  String get voiceWordAdded => 'Toegevoegd';

  @override
  String get voiceHaAddAgainHint =>
      'Voeg deze kiosk toe in Home Assistant via Instellingen → Apparaten en diensten. De kiosk verschijnt daar als ontdekt apparaat. Kende Home Assistant de kiosk al, dan vraagt het daar om de nieuwe Versleutelingssleutel van de ESPHome-pagina.';

  @override
  String get voiceHaEsphomeOff =>
      'Schakel de ESPHome-server in zodat Home Assistant deze kiosk als satelliet kan toevoegen.';

  @override
  String get voiceWordReloadNeeded => 'Herladen nodig';

  @override
  String get voiceHaSelectsReloadHint =>
      'Home Assistant heeft de keuzelijsten Assistent en Wekwoord niet geladen. Laad de ESPHome-vermelding van deze kiosk opnieuw via Instellingen → Apparaten en diensten. Je kunt Home Assistant ook opnieuw starten.';

  @override
  String get voiceTurnOn => 'Aanzetten';

  @override
  String get voiceRollbackTitle => 'Weer via het dashboard uitvoeren';

  @override
  String get voiceRollbackDescription =>
      'Ga terug naar de Voice Satellite-integratie. Niets is verloren gegaan.';

  @override
  String get voiceRollbackConfirm =>
      'Voice Satellite weer via het dashboard uitvoeren?';

  @override
  String get voiceRollbackBody =>
      'Het dashboard voert Voice Satellite weer uit via de integratie, met de eerdere instellingen. De instellingen die je hier hebt gekozen, blijven bewaard voor de volgende keer.';

  @override
  String get voiceRollbackSwitch => 'Terugschakelen';

  @override
  String get voiceMigrateNotice =>
      'Voice Satellite is momenteel als integratie in Home Assistant geïnstalleerd. Migreer voor een ingebouwde ervaring in Kiosk Satellite.';

  @override
  String get voiceMigrate => 'Migreren';

  @override
  String get settingVoiceEnabledTitle => 'Voice Satellite inschakelen';

  @override
  String get settingVoiceEnabledDescription =>
      'Maakt van deze kiosk via de ESPHome-server een spraakassistent voor Home Assistant.';

  @override
  String get settingVoiceMuteTitle => 'Microfoon dempen';

  @override
  String get settingVoiceMuteDescription =>
      'Stop met luisteren naar het wekwoord.';

  @override
  String get voiceMigrationTitle => 'Voice Satellite migreren';

  @override
  String get voiceMigrationPick =>
      'Kies de satelliet uit de Voice Satellite-integratie die deze kiosk overneemt. De instellingen ervan worden naar deze kiosk gekopieerd.';

  @override
  String get voiceMigrationNoSatellites =>
      'De Voice Satellite-integratie heeft geen satellieten.';

  @override
  String get voiceMigrationIntro =>
      'Deze kiosk wordt zelf de spraaksatelliet. Daarna is de Voice Satellite-integratie niet meer nodig.';

  @override
  String get voiceMigrationCheckAgain => 'Opnieuw controleren';

  @override
  String get voiceCheckHaBad =>
      'Niet verbonden. Controleer de Home Assistant-instellingen.';

  @override
  String get voiceCheckEsphome => 'Deze kiosk in Home Assistant';

  @override
  String get voiceCheckEsphomeOk => 'Toegevoegd via ESPHome.';

  @override
  String get voiceCheckEsphomeBad =>
      'Nog niet toegevoegd. Home Assistant toont deze kiosk als ontdekt apparaat via Instellingen → Apparaten en diensten. Voeg de kiosk daar toe en kom daarna terug.';

  @override
  String get voiceCheckEsphomeOff =>
      'De ESPHome-server staat uit. Schakel deze in en voeg daarna de kiosk toe in Home Assistant.';

  @override
  String get voiceCheckAdmin => 'Beheertoken';

  @override
  String get voiceCheckAdminOk =>
      'Het gebruik van tools en de resultaten ervan worden weergegeven.';

  @override
  String get voiceCheckAdminBad =>
      'Het token hoort bij een gewone gebruiker. Voice Satellite werkt, maar toolgebruik en resultaten worden niet weergegeven.';

  @override
  String get voiceCheckAdminUnknown =>
      'Het token kon niet worden gecontroleerd. Voor toolgebruik en resultaten is een beheertoken nodig.';

  @override
  String get voiceCheckMicOk => 'Toegestaan.';

  @override
  String get voiceCheckMicBad =>
      'Niet toegestaan. Verleen de toestemming bij Vereiste systeemtoestemmingen.';

  @override
  String get voiceTurnOnEsphome => 'ESPHome inschakelen';

  @override
  String get voiceMigrationPlan => 'Instellingen die worden overgenomen';

  @override
  String get voiceGroupVoice => 'Spraak';

  @override
  String get voiceMigrationNotCarried =>
      'Worden niet overgenomen: aangepaste CSS, microfoonverwerking in de browser en de lengte van het gespreksgeheugen. Aangepaste microWakeWord-modellen kunnen worden gebruikt vanuit config/custom_wake_words in Home Assistant.';

  @override
  String get voiceMigrationAutomations => 'Automatiseringen en scripts';

  @override
  String get voiceMigrationNoAutomations =>
      'Niets in Home Assistant wijst naar de oude satelliet.';

  @override
  String get voiceKindAutomation => 'Automatisering';

  @override
  String get voiceKindScript => 'Script';

  @override
  String get voiceMigrationReady => 'Klaar om te wisselen';

  @override
  String get voiceMigrationReady1 =>
      'Deze kiosk luistert, antwoordt en toont de overlay.';

  @override
  String get voiceMigrationReadyOnboarding =>
      'De assistent en wekwoorden worden ingesteld zodra Home Assistant deze kiosk toevoegt.';

  @override
  String get voiceMigrationReady2 =>
      'Het dashboard voert Voice Satellite niet langer uit op deze kiosk.';

  @override
  String get voiceMigrationReady3 =>
      'De oude satelliet blijft ongebruikt in Home Assistant staan.';

  @override
  String get voiceMigrationSwitch => 'Nu wisselen';

  @override
  String get voiceMigrationSwitching => 'Schakelen…';

  @override
  String get voiceMigrationDone => 'Voice Satellite draait hier nu';

  @override
  String get voiceCouldNotSwitch => 'Kon niet wisselen';

  @override
  String get voiceMigrationDoneOnboarding =>
      'Voltooi de installatie en voeg deze kiosk toe in Home Assistant. Verwijder de Voice Satellite-integratie via HACS zodra geen ander apparaat deze meer gebruikt.';

  @override
  String get voiceMigrationDoneHelp =>
      'Zeg het wekwoord om het uit te proberen. Verwijder de Voice Satellite-integratie via HACS zodra geen ander apparaat deze meer gebruikt.';

  @override
  String get voiceMigrationRolledBack =>
      'Voice Satellite wordt weer via het dashboard uitgevoerd.';

  @override
  String get voiceDone => 'Klaar';

  @override
  String get voiceTryAgain => 'Probeer opnieuw';

  @override
  String get voiceStepSave => 'Instellingen opslaan';

  @override
  String get voiceStepStop => 'Dashboardengine stoppen';

  @override
  String get voiceStepStart => 'Hier beginnen met luisteren';

  @override
  String get voiceStepTurnOn => 'Zet Voice Satellite aan op deze kiosk';

  @override
  String get voiceStepEntities =>
      'De entiteiten van de kiosk instellen in Home Assistant';

  @override
  String get voiceStepCheck => 'Controleer de satelliet in Home Assistant';

  @override
  String voiceMigrationStep(String n, String total) {
    return 'Stap $n van $total';
  }

  @override
  String voiceMigrationStillPoint(String satellite) {
    return 'Deze verwijzen nog steeds naar $satellite. Pas ze in Home Assistant aan om de satelliet van deze kiosk te gebruiken. De wizard wijzigt ze niet.';
  }

  @override
  String get voiceMigrationNotUp => 'De satelliet is niet op tijd gestart.';

  @override
  String get voiceMigrationNotReported =>
      'Home Assistant heeft de satelliet niet gemeld.';

  @override
  String get voiceMigrationBusy => 'Er loopt al een migratie.';

  @override
  String get voiceMicHeld => 'Wekwoorddetectie kan je horen.';

  @override
  String get voiceMicBlocked =>
      'Geblokkeerd. Android zal er niet opnieuw om vragen. Sta de toestemming toe via de appinstellingen.';

  @override
  String get voiceMicMissing =>
      'Zonder deze toestemming luistert niets naar het wekwoord.';

  @override
  String get voiceForegroundHeld =>
      'Kiosk Satellite kan naar de voorgrond komen wanneer het je hoort.';

  @override
  String get voiceForegroundMissing =>
      'Zonder deze toestemming wordt het wekwoord wel gehoord, maar gebeurt er niets.';

  @override
  String get voiceNotificationHeld =>
      'De permanente melding die luisteren op de achtergrond mogelijk maakt.';

  @override
  String get voiceNotificationMissing =>
      'Nodig om betrouwbaar op de achtergrond te kunnen luisteren.';

  @override
  String get voiceBatteryHeld => 'Android laat het luisterproces actief.';

  @override
  String get voiceBatteryMissing =>
      'Zonder deze toestemming wordt het luisterproces na enkele uren gestopt.';

  @override
  String get voicePermissionDirections =>
      'Verleen deze toestemmingen op het apparaat zelf: veeg vanaf de linkerrand naar binnen → Instellingen → Voice Satellite → Vereiste systeemtoestemmingen.';

  @override
  String get voicePermissionsSearch =>
      'Microfoontoegang en andere toestemmingen die nodig zijn voor wekwoorddetectie.';

  @override
  String get voiceRealtime => 'Realtime';

  @override
  String get voiceRealtimeProvidersHint =>
      'OpenAI, xAI Grok, Gemini, tools en antwoorden onderbreken';

  @override
  String get voiceRealtimeToolsSection => 'Home Assistant-tools';

  @override
  String get voiceRealtimeProviderDefault => 'Standaardprovider';

  @override
  String get voiceRealtimeToolsCustom => 'Eigen MCP-server';

  @override
  String get settingVoiceRealtimeEndpointTitle => 'Eindpunt';

  @override
  String get settingVoiceRealtimeEndpointDescription =>
      'Laat leeg om de provider te gebruiken. Gebruik een relay op je netwerk om deze kiosk offline te houden.';

  @override
  String get settingVoiceRealtimeApiKeyTitle => 'API-sleutel';

  @override
  String get settingVoiceRealtimeApiKeyDescription =>
      'Laat leeg wanneer een relay de sleutel toevoegt.';

  @override
  String get settingVoiceRealtimeModelTitle => 'Model';

  @override
  String get settingVoiceRealtimeVoiceTitle => 'Stem';

  @override
  String get settingVoiceRealtimeInstructionsTitle => 'Instructies';

  @override
  String get settingVoiceRealtimeInstructionsDescription =>
      'Bepaalt hoe de assistent zich gedraagt. Laat leeg om de korte standaardinstructie te gebruiken.';

  @override
  String get settingVoiceRealtimeIdleSecondsTitle => 'Einde na stilte';

  @override
  String get settingVoiceRealtimeIdleSecondsDescription =>
      'Het gesprek wordt beëindigd wanneer er gedurende deze tijd niemand spreekt.';

  @override
  String get settingVoiceRealtimeReasoningTitle => 'Redeneerinspanning';

  @override
  String get settingVoiceRealtimeReasoningDescription =>
      'Meer inspanning beantwoordt moeilijke vragen beter. Vereist een gpt-realtime-2-model.';

  @override
  String get settingVoiceRealtimeGeminiReasoningDescription =>
      'Meer inspanning beantwoordt moeilijke vragen beter. Vereist een model dat nadenkt, zoals gemini-3.8-live-extended-thinking.';

  @override
  String get settingVoiceRealtimeGeminiSearchTitle => 'Google Zoeken';

  @override
  String get settingVoiceRealtimeGeminiSearchBillingDescription =>
      'Laat het model dingen opzoeken op het web. Hiervoor moet facturering voor de API-sleutel aan staan.';

  @override
  String get settingVoiceRealtimeGeminiProactiveTitle =>
      'Negeren wat niet voor het model bedoeld is';

  @override
  String get settingVoiceRealtimeGeminiProactiveDescription =>
      'Het model blijft stil wanneer wat het hoort niet tot het model gericht is. Experimenteel bij Google.';

  @override
  String get settingVoiceRealtimeXaiWebSearchTitle => 'Zoeken op het web';

  @override
  String get settingVoiceRealtimeXaiWebSearchDescription =>
      'Laat het model dingen opzoeken op het web.';

  @override
  String get settingVoiceRealtimeXaiXSearchTitle => 'Zoeken op X';

  @override
  String get settingVoiceRealtimeXaiXSearchDescription =>
      'Laat het model berichten op X doorzoeken.';

  @override
  String get voiceRealtimeReasoningDefault => 'Standaard van het model';

  @override
  String get voiceRealtimeReasoningMinimal => 'Minimaal';

  @override
  String get voiceRealtimeReasoningLow => 'Laag';

  @override
  String get voiceRealtimeReasoningMedium => 'Gemiddeld';

  @override
  String get voiceRealtimeReasoningHigh => 'Hoog';

  @override
  String get voiceRealtimeReasoningExtraHigh => 'Zeer hoog';

  @override
  String get settingVoiceRealtimeSpeedTitle => 'Spreeksnelheid';

  @override
  String get settingVoiceRealtimeSpeedDescription =>
      'Hoe snel de assistent praat.';

  @override
  String get settingVoiceRealtimeHistoryHoursTitle => 'Sessieduur';

  @override
  String get settingVoiceRealtimeHistoryHoursDescription =>
      'Wat binnen deze tijd is gezegd, wordt meegenomen naar het volgende gesprek.';

  @override
  String get settingVoiceRealtimeTalkOverTitle => 'Door antwoorden heen praten';

  @override
  String get settingVoiceRealtimeTalkOverDescription =>
      'Onderbreek een antwoord door te spreken. Zet uit als het zichzelf onderbreekt.';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityTitle =>
      'Gevoeligheid voor onderbreken';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityDescription =>
      'Hoe makkelijk spreken een antwoord onderbreekt. Verhoog dit als onderbreken niet werkt met een zachte microfoon. Hogere waarden kunnen ervoor zorgen dat het zichzelf onderbreekt.';

  @override
  String get settingVoiceRealtimeToolsTitle => 'Tools';

  @override
  String get settingVoiceRealtimeToolsDescription =>
      'Wat de assistent kan bedienen. Home Assistant gebruikt hiervoor de MCP Server-integratie en entiteiten die aan Assist beschikbaar zijn gesteld.';

  @override
  String get settingVoiceRealtimeMcpUrlTitle => 'MCP-server-URL';

  @override
  String get settingVoiceRealtimeMcpUrlDescription =>
      'Het streamable HTTP-adres van de server.';

  @override
  String get settingVoiceRealtimeMcpTokenTitle => 'MCP token';

  @override
  String get settingVoiceRealtimeMcpTokenDescription =>
      'Wordt als bearer-token verzonden. Laat leeg als de server geen token vereist.';

  @override
  String get voiceRealtimeMcpMissing =>
      'Voeg de MCP Server-integratie toe in Home Assistant om je woning te bedienen.';

  @override
  String get voiceRealtimeNotValidated => 'Niet gevalideerd';

  @override
  String voiceRealtimeOption(String provider) {
    return '$provider Realtime';
  }

  @override
  String voiceRealtimeConnectFailed(String error) {
    return 'Kon niet verbinden: $error';
  }

  @override
  String voiceRealtimeToolsUnavailable(String problem) {
    return 'Verbonden, maar de Home Assistant-tools zijn niet beschikbaar: $problem';
  }

  @override
  String get settingVoiceRealtimeModelDescription =>
      'Het spraak-naar-spraakmodel dat antwoord geeft.';

  @override
  String get settingVoiceRealtimeVoiceDescription => 'Hoe de assistent klinkt.';

  @override
  String get voiceRealtimeProviders => 'Providers';

  @override
  String get voiceRealtimeConfigure => 'Instellen';

  @override
  String get voiceRealtimeSaveValidate => 'Opslaan en valideren';

  @override
  String get voiceRealtimeNotConfigured => 'Niet geconfigureerd';

  @override
  String get voiceRealtimeValidated => 'Verbinding gevalideerd';

  @override
  String get voiceDisconnected => 'Home Assistant niet verbonden';

  @override
  String get voiceValidate =>
      'Controleer eerst de verbinding bij Home Assistant-instellingen.';

  @override
  String get voiceChecking => 'Controleren op Voice Satellite…';

  @override
  String get voiceMissing =>
      'Voice Satellite is niet geïnstalleerd in Home Assistant';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite maakt van deze kiosk een volledige handsfree spraakassistent voor Home Assistant, met wekwoorddetectie, gesprekken, timers en aankondigingen rechtstreeks op het dashboard.\n\nJe vindt de integratie in de standaardrepository van HACS. Installeer deze op je Home Assistant-instantie en kom daarna hier terug.';

  @override
  String get voiceLearnMore => 'Meer informatie over ';

  @override
  String get voiceGithub => 'Voice Satellite op GitHub';

  @override
  String get voiceHacs => 'HACS-repository openen';

  @override
  String get voiceLoading => 'Voice Satellite-bediening laden…';

  @override
  String get voiceTester => 'Wekwoordtester';

  @override
  String get voiceTesterHelp =>
      'Bekijk live wat de engine hoort en welke scores daarbij horen. Zo kun je zien waarom het wekwoord wel of niet wordt herkend.';

  @override
  String get voiceTesterSearch =>
      'Live overzicht van wat de engine hoort en welke scores daarbij horen.';

  @override
  String get voiceTesterWaiting => 'Wachten op Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word (stopwoord)';
  }

  @override
  String get voiceScore => 'Score';

  @override
  String get voiceThreshold => 'Drempelwaarde';

  @override
  String get voiceHits => 'Treffers';

  @override
  String get voiceNearMisses => 'Bijna-herkenningen';

  @override
  String get voicePeak => 'Piek';

  @override
  String get voiceMicLevel => 'Mic-niveau';

  @override
  String get voiceChunkProcessing => 'Verwerking per blok (min. / gem. / max.)';

  @override
  String get voiceLog => 'Logboek';

  @override
  String get voiceLogEmpty =>
      'Detecties en bijna-herkenningen verschijnen hier.';

  @override
  String get voiceLogHit => 'TREFFER';

  @override
  String get voiceLogNear => 'bijna';

  @override
  String get voiceLogScore => 'score';

  @override
  String get voiceLogDecoded => 'gedecodeerd';

  @override
  String get voiceLogDistance => 'afstand';

  @override
  String get voiceLogConfidence => 'zekerheid';

  @override
  String get voiceTesterPlayRecent => 'Laatste 10 seconden afspelen';

  @override
  String get settingVoiceTimerPillsTitle => 'Timerlabels tonen';

  @override
  String get settingVoiceTimerPillsDescription =>
      'Actieve timers verschijnen als labels op het scherm. Sleep ze naar de gewenste plek.';

  @override
  String get settingVoiceTimerNameInPillTitle => 'De timernaam tonen';

  @override
  String get settingVoiceTimerNameInPillDescription =>
      'Toon de naam naast de tijd in het timerlabel.';

  @override
  String get settingVoiceTimerPillScaleTitle => 'Grootte van timerlabels';

  @override
  String get settingVoiceTimerPillScaleDescription =>
      'De grootte van de timerlabels.';

  @override
  String get settingVoiceTimerAlertPillTitle =>
      'Labels van afgelopen timers tonen';

  @override
  String get settingVoiceTimerAlertPillDescription =>
      'Tik op het label om de waarschuwing te stoppen.';

  @override
  String get settingVoiceMuteTimersTitle => 'Timerwaarschuwingen dempen';

  @override
  String get settingVoiceMuteTimersDescription =>
      'Toon de waarschuwing zonder geluid.';

  @override
  String get settingVoiceTimerNameOnAlertTitle =>
      'De naam op de waarschuwing tonen';

  @override
  String get settingVoiceTimerNameOnAlertDescription =>
      'Toon de timernaam onder de waarschuwing.';

  @override
  String get settingVoiceTimerSpeakTitle =>
      'Uitspreken wanneer een timer afloopt';

  @override
  String get settingVoiceTimerSpeakDescription =>
      'Spreek een zin uit tussen de waarschuwingsgeluiden.';

  @override
  String get settingVoiceTimerPhraseTitle => 'Tekst';

  @override
  String get settingVoiceTimerPhraseDescription =>
      'Gesproken voor een timer zonder naam.';

  @override
  String get settingVoiceTimerNamedPhraseTitle => 'Zin voor timers met naam';

  @override
  String settingVoiceTimerNamedPhraseDescription(String name) {
    return '$name wordt vervangen door de timernaam.';
  }

  @override
  String get voiceWakePage => 'Wekwoorden';

  @override
  String get voiceWakeHint =>
      'Engine, wekwoorden, gevoeligheid en modellen in cache';

  @override
  String get voiceWakeLabel => 'Wekwoord';

  @override
  String get voiceWakeEngine => 'Wekwoordengine';

  @override
  String get voiceWakeEngineHelp =>
      'Waar de detectie plaatsvindt en welke engine luistert.';

  @override
  String get voiceWake1 => 'Wekwoord 1';

  @override
  String get voiceWake1Help => 'Het woord dat een stemopdracht start.';

  @override
  String get voiceWake2 => 'Wekwoord 2';

  @override
  String get voiceWake2Help =>
      'Een tweede wekwoord dat wordt beantwoord door Assist-pijplijn 2.';

  @override
  String get voiceSensitivity => 'Wekwoordgevoeligheid';

  @override
  String get voiceSensitivityHelp =>
      'Hoe gemakkelijk de detectie op het wekwoord reageert.';

  @override
  String get voiceNoiseGate => 'Ruisfilter voor wekwoord';

  @override
  String get voiceNoiseGateHelp =>
      'Sla lokale wekwoorddetectie over wanneer de kamer stil is om processorkracht te besparen.';

  @override
  String get voiceStopInterruption => 'Onderbreken met stopwoord';

  @override
  String get voiceStopInterruptionHelp =>
      'Zeg het stopwoord om de reacties te onderbreken.';

  @override
  String get voiceAssignFirst =>
      'Wijs eerst een satelliet toe om deze instellingen te beheren.';

  @override
  String get voiceCachedModels => 'Modellen in cache';

  @override
  String get voiceCachedModelsHelp =>
      'Download de modellen opnieuw vanuit Home Assistant. Gebruik dit nadat een model opnieuw is gepubliceerd.';

  @override
  String get voiceClearCache => 'Cache wissen';

  @override
  String get voiceClearing => 'Cache wissen…';

  @override
  String voiceCacheCleared(String count) {
    return 'Bestanden verwijderd: $count. Bezig met opnieuw downloaden.';
  }

  @override
  String voiceCacheCount(String count) {
    return '$count verwijderd';
  }

  @override
  String get voiceVerySensitive => 'Zeer gevoelig';

  @override
  String get voiceWakeWordPreferFp32Title =>
      'fp32 vsWakeWord-modellen verkiezen';

  @override
  String get voiceWakeWordPreferFp32Description =>
      'Gebruikt fp32-modellen in plaats van de kleinere int8-versies. Dit verhoogt het CPU-gebruik tijdens het luisteren met 10 tot 30 procent en voorkomt ongeveer 2 procent afwijking in de betrouwbaarheidsscore.';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle =>
      'Tijdslimiet hervatten (seconden)';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      'Zelfherstel: hervat het luisteren als de pagina na een overdracht nooit setWakeWordActive(true) aanroept. Wacht zolang een spraakbeurt nog audio streamt, zodat een lange beurt nooit voortijdig wordt afgebroken.';

  @override
  String get voiceSlightlySensitive => 'Licht gevoelig';

  @override
  String get voiceModeratelySensitive => 'Matig gevoelig';

  @override
  String get voiceOnDevice => 'Op het apparaat';

  @override
  String voiceOnDeviceEngine(String engine) {
    return 'Op apparaat ($engine)';
  }

  @override
  String get voiceDiagnosticsPage => 'Wekwoorddiagnostiek';

  @override
  String get voiceDiagnosticsHint =>
      'Recente activeringen en bijna-herkenningen met geluidsfragmenten';

  @override
  String get voiceDiagnosticsTitle => 'Wekwoorddiagnostiek inschakelen';

  @override
  String get voiceDiagnosticsDescription =>
      'Slaat de laatste 10 wekwoordactiveringen en bijna-herkenningen op, met hun scores en een geluidsfragment van 3 seconden. Als je dit uitschakelt, worden de opnamen verwijderd.';

  @override
  String get voiceDiagnosticsEmpty =>
      'Er zijn nog geen wekwoordactiveringen opgenomen.';

  @override
  String get voiceDiagnosticsActivations => 'Activeringen';

  @override
  String get voiceDiagnosticsNoNearMisses =>
      'Er zijn nog geen bijna-herkenningen opgenomen.';

  @override
  String get voiceDiagnosticsPeakLevel => 'Piekniveau';

  @override
  String get voiceDiagnosticsAverageLevel => 'Gemiddeld niveau';

  @override
  String get voiceDiagnosticsClipped => 'Overstuurd';

  @override
  String get voiceDiagnosticsHeard => 'Gehoord';

  @override
  String get voiceWake2HelpNative =>
      'Een tweede wekwoord dat wordt beantwoord door Assistent 2.';

  @override
  String get voiceCustomModels => 'Aangepaste modellen';

  @override
  String get voiceCustomNone => 'Nog geen aangepaste modellen.';

  @override
  String get voiceCustomManaged =>
      'De leider van de vloot beheert de aangepaste modellen op deze kiosk.';

  @override
  String get voiceCustomAdd => 'Modellen toevoegen';

  @override
  String get voiceCustomAddHelp =>
      'Selecteer de bestanden voor een of meer modellen. Deze verschijnen hierboven bij Wekwoord 1 en 2.';

  @override
  String get voiceCustomDocs => 'Aangepaste modellen toevoegen';

  @override
  String get voiceCustomDocsHelp =>
      'Welke bestanden elke engine nodig heeft en waar je de modellen kunt vinden.';

  @override
  String get voiceCustomNotAdded => 'De modellen werden niet toegevoegd.';

  @override
  String get voiceCustomSomeNotAdded =>
      'Sommige bestanden zijn niet toegevoegd.';

  @override
  String get voiceCustomAdded => 'Modellen toegevoegd.';

  @override
  String get voiceCustomDeleteConfirm => 'Dit model verwijderen?';

  @override
  String get voiceCustomNotDeleted => 'Het model is niet verwijderd.';

  @override
  String get voiceCustomOtherEngine => 'niet de actieve engine';

  @override
  String get settingVoiceWakeWordEngineDescription =>
      'Welke engine naar het wekwoord luistert. Alle modellen worden met de app meegeleverd.';

  @override
  String get settingVoiceWakeWordSensitivityTitle => 'Wekwoordgevoeligheid';

  @override
  String get settingVoiceWakeWordSensitivityDescription =>
      'Hoe gemakkelijk de detectie op het wekwoord reageert.';

  @override
  String get settingVoiceWakeWordFineTuneTitle => 'Gevoeligheid fijnafstellen';

  @override
  String get settingVoiceWakeWordFineTuneDescription =>
      'Past de wekwoordgevoeligheid in kleinere stappen aan. Verhoog dit als je het wekwoord vaak moet herhalen en verlaag het als het per ongeluk reageert.';

  @override
  String get settingVoiceNoiseGateTitle => 'Ruisfilter voor wekwoord';

  @override
  String get settingVoiceNoiseGateDescription =>
      'Sla wekwoorddetectie over wanneer de kamer stil is om processorkracht te besparen.';

  @override
  String get settingVoiceStopWordTitle => 'Onderbreken met stopwoord';

  @override
  String get settingVoiceStopWordDescription =>
      'Zeg \'stop\' om een antwoord, timerwaarschuwing of aankondiging af te breken.';

  @override
  String get settingVoiceStopWordFineTuneTitle =>
      'Gevoeligheid van stopwoord fijnafstellen';

  @override
  String get settingVoiceStopWordFineTuneDescription =>
      'Past de gevoeligheid van het stopwoord in kleinere stappen aan. Verhoog dit als je \'stop\' vaak moet herhalen en verlaag het als antwoorden per ongeluk stoppen.';

  @override
  String get settingVoiceWakeArbitrationTitle =>
      'Wekwoordarbitrage inschakelen';

  @override
  String get settingVoiceWakeArbitrationDescription =>
      'Als meerdere kiosken het wekwoord horen, antwoordt de dichtstbijzijnde. Verhoogt de detectielatentie.';

  @override
  String get settingVoiceWakeArbitrationWindowTitle => 'Arbitrageperiode';

  @override
  String get settingVoiceWakeArbitrationWindowDescription =>
      'Hoelang er op de andere kiosken wordt gewacht. Verleng deze periode als een tragere kiosk verliest terwijl die dichterbij staat.';

  @override
  String get settingVoiceWakeArbitrationOffsetTitle => 'Arbitragecorrectie';

  @override
  String get settingVoiceWakeArbitrationOffsetDescription =>
      'Wordt opgeteld bij hoe luid deze kiosk het activeringswoord hoorde. Verhoog deze als deze kiosk verliest terwijl die dichterbij staat en verlaag deze als die van te ver weg antwoordt.';

  @override
  String get voiceSectionWakeArbitration => 'Wekwoordarbitrage';

  @override
  String get voiceOptionSlightly => 'Licht gevoelig';

  @override
  String get voiceOptionModerately => 'Matig gevoelig';

  @override
  String get voiceOptionVery => 'Zeer gevoelig';

  @override
  String get voiceModelNotFileName => 'Geen bestandsnaam.';

  @override
  String get voiceModelBadExtension =>
      'Alleen .json, .tflite en .onnx bestanden zijn modellen.';

  @override
  String voiceModelTooLarge(String name) {
    return '$name is groter dan 64 MB.';
  }

  @override
  String voiceModelIncomplete(String name) {
    return '$name kwam incompleet aan.';
  }

  @override
  String voiceModelBadJson(String file) {
    return '$file is geen geldige JSON.';
  }

  @override
  String voiceModelNotManifest(String file) {
    return '$file is geen manifest.';
  }

  @override
  String voiceModelMwwNeedsTflite(String file) {
    return 'Een microWakeWord model heeft ook $file nodig.';
  }

  @override
  String voiceModelMwwBadManifest(String file) {
    return '$file is geen geldig microWakeWord-manifest.';
  }

  @override
  String voiceModelVswwNeedsOnnx(String file) {
    return 'Een vsWakeWord-model heeft ook $file nodig.';
  }

  @override
  String voiceModelVswwBadManifest(String file) {
    return '$file is geen geldig vsWakeWord-manifest.';
  }

  @override
  String voiceModelUnknownManifest(String file) {
    return '$file is noch een microWakeWord-manifest noch een vsWakeWord-manifest.';
  }

  @override
  String voiceModelNoModelFile(String name) {
    return 'Geen modelbestand voor $name.';
  }

  @override
  String voiceModelBothFormats(String onnx, String tflite) {
    return 'Voeg $onnx of $tflite toe, niet beide.';
  }

  @override
  String voiceModelNotOwwTflite(String file, String json) {
    return '$file is geen openWakeWord model. Een microWakeWord model heeft ook zijn $json nodig.';
  }

  @override
  String get voiceModelNotTflite => 'Geen TFLite model.';

  @override
  String get voiceModelNotOnnx => 'Geen ONNX model.';

  @override
  String get voiceModelNotOww => 'Geen openWakeWord-model.';

  @override
  String get voiceModelOwwWindow =>
      'Geen openWakeWord-model: het gebruikt geen embeddingvenster van 16 x 96.';

  @override
  String voiceModelNoLoad(String error) {
    return 'Het model laadt niet: $error';
  }

  @override
  String get settingVoiceAmazonLocaleTitle => 'Taal van het wekwoord';

  @override
  String get settingVoiceAmazonLocaleDescription =>
      'De taal van de wekwoordmodellen van Amazon. De wekwoordkeuzes bieden de wekwoorden van die taal aan.';

  @override
  String get voiceOptionAppLanguage => 'Taal van Kiosk Satellite';

  @override
  String get settingDisableCacheTitle => 'Cache uitschakelen';

  @override
  String get settingDisableCacheDescription =>
      'Haal de pagina altijd op via het netwerk en verwijder tijdens het laden gegevens uit de cache, zodat een opnieuw uitgerold dashboard altijd actueel wordt geladen. Dit is langzaam en alleen bedoeld als hulpmiddel tijdens ontwikkeling.';

  @override
  String get settingAllowMixedContentTitle => 'Gemengde inhoud toestaan';

  @override
  String get settingAllowMixedContentDescription =>
      'Laat HTTPS-pagina\'s onveilige HTTP-bronnen laden. Dit helpt wanneer Home Assistant inhoud via http:// in een dashboard via https:// gebruikt.';

  @override
  String get settingIgnoreSslErrorsTitle => 'SSL-fouten negeren';

  @override
  String get settingIgnoreSslErrorsDescription =>
      'Accepteer niet-vertrouwde of zelfondertekende certificaten. Gebruik dit alleen op je eigen netwerk, omdat certificaatcontrole hiermee wordt uitgeschakeld.';

  @override
  String get settingAutoReloadOnErrorTitle => 'Automatisch herladen bij fout';

  @override
  String get settingAutoReloadOnErrorDescription =>
      'Herstel automatisch na fouten op de pagina of crashes van de app.';

  @override
  String get settingPullToRefreshTitle =>
      'Trekken om te vernieuwen inschakelen';

  @override
  String get settingPullToRefreshDescription =>
      'Sleep vanaf de bovenkant van de pagina omlaag om deze opnieuw te laden. Staat standaard uit, omdat dit gebaar op een scrollbaar dashboard gemakkelijk per ongeluk wordt uitgevoerd.';

  @override
  String get settingPullToRefreshClearCacheTitle =>
      'Cache wissen bij verversen';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      'Het trekgebaar wist ook de webcache en opgeslagen wekwoordmodellen voordat de pagina opnieuw wordt geladen. Aanmeldgegevens en opgeslagen paginagegevens blijven behouden.';

  @override
  String get settingBrowserZoomTitle => 'Zoomniveau';

  @override
  String get settingBrowserZoomDescription =>
      'Schaalt de hele pagina. Boven 1x voor wandtabletten op afstand bekeken; onder 1x past meer dashboard op een klein scherm.';

  @override
  String get settingPinchToZoomTitle => 'Knijpen om te zoomen inschakelen';

  @override
  String get settingPinchToZoomDescription =>
      'Zoom met een knijpbeweging van twee vingers. Staat standaard uit, zodat onbedoelde aanrakingen het kioskdashboard niet verplaatsen.';

  @override
  String get settingDisableScrollingTitle => 'Schuiven uitschakelen';

  @override
  String get settingDisableScrollingDescription =>
      'Zet de pagina vast zodat deze in geen enkele richting kan worden verschoven. Tikken en knoppen blijven werken.';

  @override
  String get browserCrashPermissionHelp =>
      'Zonder dit kan de kiosk niet terugkomen na een crash.';

  @override
  String get browserCrashPermissionMissing =>
      'Toestemming voor weergave over andere apps ontbreekt';

  @override
  String get browserCrashPermissionRemoteHelp =>
      'Zonder deze toestemming kan de kiosk zichzelf na een crash niet herstellen. Het toestemmingsscherm verschijnt op de tablet.';

  @override
  String get settingBrowserInjectJsTitle =>
      'JavaScript uitvoeren op het HA-dashboard';

  @override
  String get settingBrowserInjectJsDescription =>
      'Voer deze JavaScript-code uit telkens nadat de dashboardpagina is geladen. Hiermee kun je bijvoorbeeld afleidende onderdelen verbergen of een dashboard aanpassen dat je niet beheert.';

  @override
  String get settingBrowserInjectJsExternalTitle =>
      'JavaScript uitvoeren op externe pagina\'s';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      'Voer deze JavaScript-code uit nadat een externe pagina is geladen, waaronder pagina\'s uit dashboardlinks, pagina\'s voor dashboardrotatie en de websiteschermbeveiliging. De Music Assistant-pagina wordt niet aangepast.';

  @override
  String get browserInjectJsPlaceholder =>
      '// Voorbeeld: een afleidend element verbergen\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// Voorbeeld: zoom een site die het zoomniveau van het dashboard negeert\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get urlFilterTitle => 'URL-filter';

  @override
  String get urlFilterHint =>
      'Pagina\'s blokkeren of toestaan op adrespatroon of reguliere expressie';

  @override
  String get urlFilterIntroTitle => 'Bepalen welke pagina\'s openen';

  @override
  String get urlFilterIntroSub =>
      'Links of pagina\'s die overeenkomen met een Blokkeren-regel laden niet. Voeg een Alleen toestaan-regel toe om alleen overeenkomende pagina\'s te laden.';

  @override
  String get urlFilterAdd => 'Regel toevoegen';

  @override
  String get urlFilterAddTitle => 'Filterregel toevoegen';

  @override
  String get urlFilterEditTitle => 'Filterregel bewerken';

  @override
  String get urlFilterName => 'Naam';

  @override
  String get urlFilterPattern => 'Patroon';

  @override
  String get urlFilterPatternWildcardHint =>
      'Gebruik * voor willekeurige tekens. Een patroon dat met / begint, komt overeen met het pad op elke server, zoals /history*.';

  @override
  String get urlFilterPatternRegexHint =>
      'Een reguliere expressie die overal in het adres wordt gezocht, ongeacht hoofdletters.';

  @override
  String get urlFilterType => 'Patroontype';

  @override
  String get urlFilterTypeWildcard => 'Jokerteken';

  @override
  String get urlFilterTypeRegex => 'Reguliere expressie';

  @override
  String get urlFilterAction => 'Actie';

  @override
  String get urlFilterActionBlock => 'Blokkeren';

  @override
  String get urlFilterActionAllow => 'Alleen toestaan';

  @override
  String get urlFilterActionAllowHint =>
      'Waar deze regel geldt, laden alleen pagina\'s die overeenkomen met een Alleen toestaan-regel. Aanmelden bij Home Assistant en het startdashboard laden altijd.';

  @override
  String get urlFilterScope => 'Geldt voor';

  @override
  String get urlFilterScopeAll => 'Dashboard en externe pagina\'s';

  @override
  String get urlFilterScopeDashboard => 'Dashboard';

  @override
  String get urlFilterScopeExternal => 'Externe pagina\'s';

  @override
  String get urlFilterScopeHint =>
      'Externe pagina\'s zijn links die vanaf het dashboard worden geopend en pagina\'s voor dashboardrotatie.';

  @override
  String get urlFilterErrorName => 'Voer een naam in.';

  @override
  String get urlFilterErrorPattern => 'Voer een patroon in.';

  @override
  String get urlFilterErrorRegex => 'Deze reguliere expressie is ongeldig.';

  @override
  String get urlFilterBlocked => 'Pagina geblokkeerd';

  @override
  String get urlFilterNotAllowed => 'Niet bij de toegestane pagina\'s';

  @override
  String get settingBrowserUrlFilterNoticeTitle =>
      'Melding bij geblokkeerde pagina tonen';

  @override
  String get settingBrowserUrlFilterNoticeDescription =>
      'Toon een korte melding met de naam van de regel wanneer een pagina wordt geblokkeerd.';

  @override
  String get setupConnectHeading => 'Verbinden met Home Assistant';

  @override
  String get setupConnectLead =>
      'Voer de basis-URL van je instantie in en een langdurig toegangstoken dat je hebt aangemaakt via je HA-profiel > Beveiliging > Langdurige toegangstokens.';

  @override
  String get setupBaseUrl => 'Basis-URL van Home Assistant';

  @override
  String get setupToken => 'Langdurig toegangstoken';

  @override
  String get setupScanQr => 'Scan de QR-code';

  @override
  String get setupInvalidToken => 'Ongeldig toegangstoken';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant heeft dit token geweigerd. Open in Home Assistant je profiel > Beveiliging > Langdurige toegangstokens, maak een nieuw token aan en kopieer de volledige waarde.';

  @override
  String get setupUnreachable => 'Kan Home Assistant niet bereiken';

  @override
  String get setupUnreachableHelp =>
      'Dit adres reageert niet. Controleer of de URL juist is en of dit apparaat op hetzelfde netwerk zit als je Home Assistant-server.';

  @override
  String get setupUnexpectedResponseHelp =>
      'Een server heeft gereageerd, maar dit lijkt geen Home Assistant-server te zijn. Controleer of de URL het basisadres van Home Assistant is, bijvoorbeeld https://homeassistant.local:8123.';

  @override
  String get setupCannotConnect => 'Kan geen verbinding maken';

  @override
  String get setupCameraPermission => 'Cameratoestemming vereist';

  @override
  String get setupCameraBlocked =>
      'Geef Kiosk Satellite cameratoegang via de Android-instellingen om de QR-code te kunnen scannen.';

  @override
  String get setupCameraAllow =>
      'Geef de camera toestemming om de QR-code te scannen.';

  @override
  String get setupEnterBaseUrl => 'Voer de basis-URL van Home Assistant in';

  @override
  String get setupInvalidBaseUrl => 'Ongeldige basis-URL';

  @override
  String get setupBaseUrlHelp =>
      'Dit is het adres waarmee je Home Assistant opent, bijvoorbeeld https://homeassistant.local:8123.';

  @override
  String get setupEnterToken => 'Voer een langdurig toegangstoken in';

  @override
  String get setupEnterTokenHelp =>
      'Open in Home Assistant je profiel > Beveiliging > Langdurige toegangstokens om een token aan te maken.';

  @override
  String get setupValidateContinue => 'Controleren en doorgaan';

  @override
  String setupUnexpectedResponse(String error) {
    return 'Onverwacht antwoord ($error)';
  }

  @override
  String get baseUrlInvalid =>
      'Voer een geldige URL in, bijvoorbeeld https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      'Voer alleen de basis-URL in, zonder dashboardpad. Voorbeeld: https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      'Voer alleen de basis-URL in, zonder iets achter de poort. Voorbeeld: https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => 'Kies een dashboard';

  @override
  String get setupDashboardHelp =>
      'Dit dashboard wordt weergegeven wanneer de kiosk wordt gestart.';

  @override
  String get setupSelectDashboard => 'Een dashboard selecteren';

  @override
  String get setupSelectDashboardHelp =>
      'Kies het dashboard dat de kiosk moet weergeven. Je kunt dit later wijzigen via Instellingen.';

  @override
  String get setupHeadlessGrants =>
      'Dit apparaat heeft geen scherm, dus Android kan er niet om vragen. Verleen ze elk via adb en rond dan hier af.';

  @override
  String get setupWelcome => 'Welkom';

  @override
  String get setupConnect => 'Verbinden';

  @override
  String get setupConnectSummary => 'Home Assistant-URL en token';

  @override
  String get setupDashboard => 'Dashboard';

  @override
  String get setupDashboardSummary => 'Wat de kiosk laat zien';

  @override
  String get setupRecommendedSummary => 'Aanbevolen instellingen';

  @override
  String get setupPermissions => 'Toestemmingen';

  @override
  String get setupPermissionsSummary => 'Benodigd voor de configuratie';

  @override
  String get setupPermissionLead =>
      'Android zal om deze toestemmingen vragen. Alles wordt vooraf gevraagd, zodat de kiosk je later nooit onderbreekt.';

  @override
  String get setupRemotePermissionLead =>
      'Android vraagt op de tablet zelf om deze toestemmingen. Ga naar de tablet, accepteer de verzoeken en rond de installatie daarna hier af.';

  @override
  String get setupMicrophoneHelp =>
      'Voice Satellite en de intercom hebben microfoontoegang nodig';

  @override
  String get setupNotificationListening =>
      'Maakt de permanente melding van de Kiosk Satellite Service mogelijk. Daarin staat welke functies actief worden gehouden en wanneer de kiosk luistert.';

  @override
  String get setupBatteryService =>
      'Hiermee kan de Kiosk Satellite Service op de achtergrond blijven draaien zonder te worden gepauzeerd of beëindigd.';

  @override
  String get setupOverlayBoot =>
      'Hiermee kan Kiosk Satellite na een crash terugkeren en bij het opstarten van je apparaat worden gestart.';

  @override
  String get setupOverlayCrash =>
      'Hiermee kan Kiosk Satellite na een crash weer op het scherm verschijnen.';

  @override
  String get setupBrightnessHelp =>
      'Hiermee kan Kiosk Satellite de werkelijke helderheid van het paneel instellen (systeeminstellingen wijzigen).';

  @override
  String get setupScreenControl => 'Schermbediening';

  @override
  String get setupScreenControlHelp =>
      'Hiermee kan Kiosk Satellite het scherm op verzoek uitschakelen via apparaatbeheer.';

  @override
  String get setupGrantPermissions => 'Toestemmingen verlenen op het apparaat';

  @override
  String get setupRequestingPermissions =>
      'Toestemmingen aanvragen op het apparaat…';

  @override
  String get setupPermissionsRequested =>
      'Toestemmingen zijn aangevraagd op het apparaat';

  @override
  String get setupQrFlipCamera => 'Andere camera gebruiken';

  @override
  String get setupQrCameraFailed => 'De camera kon niet gestart worden.';

  @override
  String get setupQrTitle => 'Scan de token QR-code';

  @override
  String get setupQrHelp =>
      'Deze verschijnt naast een nieuw aangemaakt token in je Home Assistant-profiel.';

  @override
  String get setupQrFlashOff => 'Zaklamp uitschakelen';

  @override
  String get setupQrFlashOn => 'Zaklamp inschakelen';

  @override
  String get setupQrScreenLightOff => 'Schermlicht uitschakelen';

  @override
  String get setupQrScreenLightOn => 'Schermlicht inschakelen';

  @override
  String get setupPasswordFirst =>
      'Stel eerst het wachtwoord van de beheerder in';

  @override
  String get setupPasswordBeforeImport =>
      'Typ hierboven een beheerderswachtwoord (minimaal 4 tekens) en importeer daarna de back-up.';

  @override
  String get setupPasswordFailed => 'Kon het wachtwoord niet instellen';

  @override
  String get setupPasswordExists => 'Er is al een wachtwoord ingesteld';

  @override
  String get setupPasswordExistsHelp =>
      'Meld je hier aan met het wachtwoord dat op de tablet is ingesteld om verder te gaan. Opnieuw laden…';

  @override
  String get setupNotBackup => 'Geen back-upbestand';

  @override
  String get setupInvalidBackupHelp =>
      'Dit bestand bevat geen geldige JSON. Exporteer een configuratie via Instellingen op een geconfigureerde Kiosk Satellite of via beheer op afstand.';

  @override
  String get setupWrongBackupKind =>
      'Exporteer een configuratie van het tabblad Instellingen van een ingestelde Kiosk Satellite.';

  @override
  String get setupImportFailedHelp => 'Het bestand kon niet worden toegepast.';

  @override
  String get setupBackupNoDashboard => 'Back-up bevat geen dashboard';

  @override
  String get setupBackupNoDashboardHelp =>
      'De instellingen zijn toegepast, maar deze back-up is gemaakt voordat het apparaat werd geconfigureerd. Er is daarom nog geen dashboard geselecteerd. Ga verder met de wizard om er een te kiezen.';

  @override
  String get setupImporting => 'Importeren…';

  @override
  String get setupRemoteRestoreHelp =>
      'Importeer een vanuit Kiosk Satellite geëxporteerde configuratie en sla de rest van deze wizard over.';

  @override
  String get setupFinishOnDevice => 'Voltooien op het apparaat';

  @override
  String get setupFinishOnDeviceHelp =>
      'De configuratie is geïmporteerd. Bevestig de toestemmingsverzoeken op de tablet. Deze pagina gaat automatisch verder zodra het dashboard wordt geladen.';

  @override
  String get setupBackupObject => 'De back-up moet een JSON-object bevatten.';

  @override
  String get setupBackupKind =>
      'Dit is geen configuratiebestand van Kiosk Satellite.';

  @override
  String get setupBackupSettings => 'De back-up bevat geen instellingen.';

  @override
  String get setupServiceHelp =>
      'Houdt de app actief wanneer het scherm uit staat of een andere app op de voorgrond staat. Zo blijven de Home Assistant-verbinding en functies zoals bewegingsdetectie en de Bluetooth-proxy werken. De onderstaande toestemmingen zijn optioneel, maar worden aanbevolen omdat ze de app actief helpen houden wanneer het scherm uit staat.';

  @override
  String get setupBatteryMissing =>
      'Android kan de app pauzeren wanneer het scherm uit staat, waardoor ook de verbinding met Home Assistant wordt verbroken.';

  @override
  String get setupOverlayMissing =>
      'Zonder deze toestemming kan de service de kiosk na een crash niet opnieuw starten.';

  @override
  String get setupVoiceDetected => 'Voice Satellite gedetecteerd';

  @override
  String get setupVoiceHelp =>
      'Op deze Home Assistant-instantie is de Voice Satellite-integratie actief. Kies bij welke satelliet deze kiosk hoort en controleer daarna de instellingen. Alles kan later worden gewijzigd.';

  @override
  String get setupNoSatellites => 'Geen satellieten gevonden';

  @override
  String get setupNoSatellitesHelp =>
      'Voeg een Assist-satelliet toe aan de Voice Satellite-integratie, of ga zonder satelliet verder en selecteer er later een via het dashboard.';

  @override
  String get setupNewSatelliteHelp =>
      'Als dit een nieuw apparaat is, maak je eerst een nieuwe satellietentiteit aan in Home Assistant via Instellingen → Apparaten en diensten → Voice Satellite → Integratie toevoegen. Belangrijk: twee apparaten kunnen niet dezelfde entiteit delen.';

  @override
  String get setupApplyRecommended => 'Alle aanbevolen instellingen toepassen';

  @override
  String get setupRecommendedHelp =>
      'De optimale instellingen voor volledige integratie en werking van Voice Satellite.';

  @override
  String get setupVoiceRequired => 'Vereist door Voice Satellite';

  @override
  String get setupMicrophoneAccess => 'Toegang tot microfoon';

  @override
  String get setupNativeWakeWord => 'Ingebouwde wekwoorddetectie';

  @override
  String get setupPullRefresh => 'Trekken om te vernieuwen';

  @override
  String get setupAutoplay => 'Automatisch afspelen van audio en video';

  @override
  String get setupVoiceSkipped => 'Niet geïnstalleerd, overgeslagen';

  @override
  String get setupVoiceLead =>
      'Maak van deze kiosk een spraakassistent voor Home Assistant. Alles kan later worden gewijzigd.';

  @override
  String get setupVoiceAddAgainHint =>
      'Voeg deze kiosk na de installatie toe in Home Assistant via Instellingen → Apparaten en diensten. De kiosk verschijnt daar als ontdekt apparaat. Kende Home Assistant de kiosk al, dan vraagt het daar om de nieuwe Versleutelingssleutel van de ESPHome-pagina.';

  @override
  String get setupRecommendedWall =>
      'Aanbevolen instellingen voor een kiosk aan de muur.';

  @override
  String get setupVoiceFound => 'Voice Satellite-integratie gevonden';

  @override
  String get setupVoiceFoundHelp =>
      'Voice Satellite is nu ingebouwd in Kiosk Satellite. Migreer een satelliet uit de integratie om de wekwoorden, assistent en vormgeving daarvan te behouden in plaats van opnieuw te beginnen.';

  @override
  String get setupVoiceMigrated =>
      'Gemigreerd van de Voice Satellite-integratie';

  @override
  String get setupVoiceMigratedHelp =>
      'Deze kiosk neemt de instellingen van de gekozen satelliet over.';

  @override
  String get setupVoicePipelineHelp =>
      'De Assist-pijplijn die op het wekwoord reageert.';

  @override
  String get setupVoiceEngineHelp =>
      'De engine die luistert naar het wekwoord.';

  @override
  String get setupRemoteHeading => 'Beheer op afstand';

  @override
  String get setupTitle => 'Instellen\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      'Maak van deze tablet een Home Assistant-kiosk. De configuratie duurt maar een paar minuten. Deze wizard begeleidt je stap voor stap.';

  @override
  String get setupDeviceName => 'Apparaatnaam';

  @override
  String get setupDeviceNameHelp =>
      'De naam van deze kiosk in Home Assistant, beheer op afstand en op het netwerk. Je kunt deze later wijzigen via Instellingen > Apparaat.';

  @override
  String get setupEnableRemote => 'Beheer op afstand inschakelen';

  @override
  String get setupEnableRemoteHelp =>
      'Beheer deze kiosk na de configuratie vanuit een webbrowser. Daar kun je het Home Assistant-toegangstoken gemakkelijker plakken.';

  @override
  String get setupRemotePassword => 'Wachtwoord voor beheer op afstand';

  @override
  String get setupRestoreHeading => 'Reservekopie herstellen';

  @override
  String get setupRestore => 'Configuratiebestand herstellen';

  @override
  String get setupRestoreHelp =>
      'Importeer een vanuit Kiosk Satellite geëxporteerde configuratie en sla de rest van deze wizard over. Instellingen, het dashboard en aanmeldgegevens worden allemaal overgenomen.';

  @override
  String get setupServicePermissions => 'Aanbevolen servicetoestemmingen';

  @override
  String get setupPasswordShort => 'Wachtwoord te kort';

  @override
  String get setupPasswordMinimum => 'Gebruik ten minste 4 tekens.';

  @override
  String setupRemoteAddress(String address) {
    return 'Je kunt de configuratie op afstand voortzetten in een webbrowser via $address, ongeacht of de schakelaar hierboven is ingeschakeld.';
  }

  @override
  String get remoteWelcomeTitle => 'Welkom bij Kiosk Satellite';

  @override
  String get remoteWelcomePassword =>
      'Deze tablet moet nog worden geconfigureerd. Beveilig beheer op afstand eerst met een wachtwoord.';

  @override
  String get remoteWelcomeReady =>
      'Deze tablet moet nog worden geconfigureerd. Er is al een wachtwoord voor beheer op afstand ingesteld. Voer hier een nieuw wachtwoord in om het te wijzigen.';

  @override
  String get remoteInitialPassword =>
      'Beheerderswachtwoord (minimaal 4 tekens)';

  @override
  String get remoteNewPassword =>
      'Nieuw beheerderswachtwoord (leeg laten om het huidige te behouden)';

  @override
  String get intercomBuiltinRing => 'Ingebouwde beltoon';

  @override
  String get intercomBuiltinChime => 'Ingebouwd geluidssignaal';

  @override
  String intercomMissingFile(String file) {
    return '$file (ontbrekend)';
  }

  @override
  String get intercomAddSound => 'Een geluid toevoegen';

  @override
  String get intercomCopySoundHelp =>
      'Kopieer een geluidsbestand van dit apparaat naar de geluidsmap.';

  @override
  String get intercomUploadSoundHelp =>
      'Upload een geluidsbestand van deze computer naar de geluidsmap.';

  @override
  String get intercomUpload => 'Uploaden';

  @override
  String get intercomUploading => 'Uploaden…';

  @override
  String get intercomUnsupportedSound => 'Geen ondersteund geluid';

  @override
  String get intercomChooseSound =>
      'Geen ondersteund geluid: kies een MP3-, OGG-, WAV-, FLAC-, M4A- of AAC-bestand.';

  @override
  String get intercomCopyFailed => 'Kon het bestand niet kopiëren';

  @override
  String intercomUploadFailed(String error) {
    return 'Uploaden mislukt: $error';
  }

  @override
  String intercomSaveFailed(String error) {
    return 'Niet opgeslagen: $error';
  }

  @override
  String get intercomSoundFilename => 'Voer een bestandsnaam in, geen pad.';

  @override
  String get intercomSoundFormats =>
      'Kies een MP3-, OGG-, WAV-, FLAC-, M4A- of AAC-bestand.';

  @override
  String get voiceNoticeError => 'Voice Satellite-fout';

  @override
  String get voiceNoticeWarning => 'Voice Satellite-waarschuwing';

  @override
  String get voiceNoticeNotice => 'Voice Satellite-melding';

  @override
  String get voiceNoticeTts => 'Tekst-naar-spraak';

  @override
  String get voiceNoticeAssistPipeline => 'Assist-pijplijn';

  @override
  String voiceNoticePipeline(String name) {
    return 'Pijplijn \"$name\"';
  }

  @override
  String get voiceNoticeMicUnavailable => 'De microfoon is niet beschikbaar.';

  @override
  String get voiceNoticeNotConnected =>
      'Home Assistant is niet verbonden met deze kiosk.';

  @override
  String get voiceNoticeConnectionLost =>
      'De verbinding met Home Assistant is verbroken. Er wordt automatisch opnieuw verbinding gemaakt.';

  @override
  String get voiceNoticePlayback =>
      'Audio kon niet op het apparaat worden afgespeeld.';

  @override
  String get voiceNoticeWatchdog =>
      'Home Assistant reageerde niet nadat je klaar was met spreken. Mogelijk is de pijplijn vastgelopen.';

  @override
  String get voiceNoticeRefused =>
      'Home Assistant kon de assistent niet starten.';

  @override
  String get voiceNoticeUnexpected =>
      'Er is een onverwachte fout in de pijplijn opgetreden.';

  @override
  String get voiceNoticeMicBlocked =>
      'Microfoontoegang is geblokkeerd. Sta deze voor Kiosk Satellite toe in de Android-instellingen.';

  @override
  String get voiceNoticeMicDeclined =>
      'Microfoontoegang is geweigerd, waardoor het wekwoord niet kan worden gehoord.';

  @override
  String get voiceNoticeMicLost => 'De microfoon werkt niet meer.';

  @override
  String get voiceNoticeModels =>
      'De wekwoordmodellen konden niet worden geladen.';

  @override
  String get voiceNoticeCrashed =>
      'De wekwoorddetector crashte herhaaldelijk op dit apparaat en is daarom gestopt.';

  @override
  String voiceFinancialOpen(String value) {
    return 'Openingskoers: $value';
  }

  @override
  String voiceFinancialHigh(String value) {
    return 'Hoog: $value';
  }

  @override
  String voiceFinancialLow(String value) {
    return 'Laag: $value';
  }

  @override
  String voiceFinancialHigh24h(String value) {
    return 'Hoogste in 24 uur: $value';
  }

  @override
  String voiceFinancialLow24h(String value) {
    return 'Laagste in 24 uur: $value';
  }

  @override
  String voiceFinancialMarketCap(String value) {
    return 'Marktkapitalisatie: $value';
  }

  @override
  String get voiceTimerDefaultName => 'Timer';

  @override
  String get voiceTimerDrag => 'Slepen om timers te verplaatsen';

  @override
  String get voiceTimerPauseHint =>
      'Tik om te pauzeren. Dubbeltik om te annuleren. Sleep om te verplaatsen.';

  @override
  String get voiceTimerResumeHint =>
      'Tik om te hervatten. Dubbeltik om te annuleren. Sleep om te verplaatsen.';

  @override
  String get voiceTimerCancel => 'Timer annuleren';

  @override
  String get voiceTimerActionError =>
      'Kon de timer niet wijzigen. Controleer de verbinding en werk Voice Satellite zo nodig bij.';

  @override
  String get voiceTimerFinished => 'Timer afgelopen';

  @override
  String get voiceTimerDismissHint => 'Tik om de timermelding te sluiten.';
}
