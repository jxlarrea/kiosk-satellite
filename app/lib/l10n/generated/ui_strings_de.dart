// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class UiStringsDe extends UiStrings {
  UiStringsDe([String locale = 'de']) : super(locale);

  @override
  String get aboutApp => 'Anwendung';

  @override
  String get aboutVersion => 'Anwendungsversion';

  @override
  String get aboutBuild => 'Build';

  @override
  String get aboutPackage => 'Paket';

  @override
  String get aboutAttribution => 'Credits';

  @override
  String get aboutAuthor => 'Autor';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutSourceCode => 'Quellcode';

  @override
  String get aboutLicense => 'Lizenz';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite ist für die persönliche und nicht kommerzielle Nutzung kostenlos. Es wird unter der Lizenz CC BY-NC-ND 4.0 vertrieben: Du darfst es verwenden und weitergeben, jedoch ist die kommerzielle Nutzung der Anwendung sowie die Weiterverteilung modifizierter Versionen nicht gestattet. Eigenständige Plugins verfügen gemäß PLUGIN-EXCEPTION.md über zusätzliche Berechtigungen.';

  @override
  String get aboutLocalizationCredits => 'Mitwirkende an der Übersetzung';

  @override
  String get aboutLocalizationCreditsHint => 'Mitwirkende nach Sprache';

  @override
  String get aboutCheckNow => 'Jetzt nach Updates suchen';

  @override
  String get aboutChecking => 'Prüfe ...';

  @override
  String get aboutCheckFailed =>
      'Die Suche nach Updates ist fehlgeschlagen. Kann das Gerät GitHub erreichen?';

  @override
  String get aboutOverlayMissing =>
      'Berechtigung „Über anderen Apps anzeigen“ fehlt';

  @override
  String get aboutOverlayHelp =>
      'Ohne diese Berechtigung kann die Anwendung nach einem Update nicht erneut geöffnet werden. Der Bildschirm zur Erteilung der Berechtigung wird auf dem Tablet angezeigt.';

  @override
  String aboutDownloadProgress(String percent) {
    return 'Wird heruntergeladen ... $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return 'Update fehlgeschlagen: $error';
  }

  @override
  String get aboutAlreadyCurrent =>
      'Die Anwendung ist bereits auf dem neuesten Stand';

  @override
  String get aboutInstallHelp =>
      'Der Download erfolgt auf dem Tablet. Die Installation muss auf dem Tablet bestätigt werden.';

  @override
  String get androidAccessibilityHelp =>
      'Schließt das Benachrichtigungsfeld und den Bildschirm der zuletzt verwendeten Apps, wenn diese geöffnet werden, während der Kioskmodus oder der Sperrmodus den Bildschirm schützt. Kiosk Satellite liest den Inhalt des Bildschirms nicht.';

  @override
  String get androidServiceChannelHelp =>
      'Wird angezeigt, während der Kiosk Satellite-Dienst die Anwendung aktiv hält, wenn der Bildschirm ausgeschaltet ist oder sich die Anwendung hinter einer anderen Anwendung befindet.';

  @override
  String get androidServiceListening => 'wartet auf ein Aktivierungswort';

  @override
  String get androidServiceRtspAudio => 'RTSP-Mikrofon-Audio aktiviert';

  @override
  String get androidServiceEsphome => 'wartet auf Verbindungen von ESPHome';

  @override
  String get androidServiceBluetooth => 'überträgt Daten von Bluetooth-Geräten';

  @override
  String get androidServiceCamera => 'überwacht die Kamera';

  @override
  String get androidServiceLocation => 'übermittelt den Standort';

  @override
  String get androidServiceRemote => 'wartet auf Fernverwaltung';

  @override
  String get androidServiceKiosk => 'schützt den Kioskmodus';

  @override
  String get androidServiceSessions =>
      'hält die Verbindung zu Home Assistant aufrecht';

  @override
  String get launcherErrorAndroidOnly =>
      'Die Anwendungsliste ist nur auf Android verfügbar.';

  @override
  String launcherErrorListDetail(String error) {
    return 'Die Anwendungsliste konnte nicht abgerufen werden: $error';
  }

  @override
  String launcherOpenFailed(String name) {
    return '$name konnte nicht geöffnet werden.';
  }

  @override
  String get launcherUninstalled =>
      'Möglicherweise wurde die App deinstalliert.';

  @override
  String get launcherNoneHelp =>
      'Derzeit sind keine vorhanden. Wähle die Apps aus, die der Launcher anbieten soll.';

  @override
  String get launcherNone => 'Derzeit sind keine vorhanden';

  @override
  String get launcherListFailed => 'Die Apps konnten nicht abgerufen werden';

  @override
  String launcherListError(String error) {
    return 'Die Apps konnten nicht abgerufen werden: $error';
  }

  @override
  String get launcherListingFailed => 'Liste konnte nicht abgerufen werden';

  @override
  String get launcherEmpty => 'Es wurden keine startbaren Apps gefunden.';

  @override
  String get cameraViewerTitle => 'Kameraansicht';

  @override
  String get cameraViewerConnecting => 'Verbindung wird hergestellt...';

  @override
  String get cameraViewerReconnecting => 'Verbindung wird wiederhergestellt...';

  @override
  String cameraViewerTrying(String transport) {
    return '$transport wird versucht...';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return 'Dieses Gerät kann $codec nicht dekodieren';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return 'Dieses Gerät kann keine $transport-Streams wiedergeben';
  }

  @override
  String get cameraViewerCannotDecodeStream =>
      'Dieses Gerät kann diesen Stream nicht dekodieren';

  @override
  String cameraViewerHaRetry(String seconds) {
    return 'Verbindung zu Home Assistant nicht möglich. Neuer Versuch in $seconds Sek.';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return 'Verbindung zum Kameraserver nicht möglich. Neuer Versuch in $seconds Sek.';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return 'Die Verbindung ist fehlgeschlagen. Neuer Versuch in $seconds Sek.';
  }

  @override
  String get cameraViewerStartRetry =>
      'Der Kameraserver konnte diesen Stream nicht starten. Erneuter Versuch...';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return 'Der Kameraserver konnte diesen Stream nicht starten. Neuer Versuch in $seconds Sek.';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return 'Der Stream wurde auf dem Kameraserver nicht gefunden. Neuer Versuch in $seconds Sek.';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return 'Der Kameraserver hat die Anmeldung abgelehnt. Neuer Versuch in $seconds Sek.';
  }

  @override
  String get cameraViewerMissing => 'Stream in Go2RTC nicht verfügbar';

  @override
  String get commonImport => 'Importieren';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonNext => 'Weiter';

  @override
  String get commonFinish => 'Beenden';

  @override
  String get commonWorking => 'In Arbeit…';

  @override
  String get commonSettings => 'Einstellungen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonGrant => 'Berechtigen';

  @override
  String get commonEnable => 'Aktivieren';

  @override
  String get commonRefresh => 'Aktualisieren';

  @override
  String get commonTest => 'Testen';

  @override
  String get commonInstall => 'Installieren';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonRetry => 'Wiederholen';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonClear => 'Löschen';

  @override
  String get commonBrowse => 'Durchsuchen';

  @override
  String get commonSet => 'Einstellen';

  @override
  String get commonHour => 'Stunde';

  @override
  String get commonMinute => 'Minute';

  @override
  String get commonUp => 'Hoch';

  @override
  String get commonDown => 'Runter';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonSaveFailed => 'Konnte nicht speichern';

  @override
  String get commonColorWhite => 'Weiß';

  @override
  String get commonColorWarm => 'Warm';

  @override
  String get commonColorAmber => 'Bernsteinfarben';

  @override
  String get commonColorRed => 'Rot';

  @override
  String get commonColorGreen => 'Grün';

  @override
  String get commonColorBlue => 'Blau';

  @override
  String get commonColorCyan => 'Cyan';

  @override
  String get commonColorDim => 'Gedimmt';

  @override
  String get commonEdit => 'Editieren';

  @override
  String get commonMoveUp => 'Nach oben verschieben';

  @override
  String get commonMoveDown => 'Nach unten verschieben';

  @override
  String get commonPreviousMonth => 'Letzter Monat';

  @override
  String get commonNextMonth => 'Nächster Monat';

  @override
  String get commonLoading => 'Laden...';

  @override
  String get commonChoose => 'Auswählen';

  @override
  String get dlnaPortInvalid =>
      'Wähle einen Port zwischen 1024 und 65535, oder lasse ihn frei';

  @override
  String get commonSelectAll => 'Alles auswählen';

  @override
  String get dlnaCannotDecode =>
      'Dieses Gerät kann dieses Video nicht dekodieren.';

  @override
  String get dlnaCannotRead => 'Diese Datei konnte nicht gelesen werden.';

  @override
  String get dlnaCannotPlay =>
      'Dieser Inhalt konnte nicht wiedergegeben werden.';

  @override
  String get dlnaSeeLogs => 'Details findest du in den Anwendungsprotokollen.';

  @override
  String get dlnaLoading => 'Inhalt wird geladen';

  @override
  String get dlnaImageFailed => 'Dieses Bild konnte nicht angezeigt werden.';

  @override
  String get dlnaStop => 'Wiedergabe stoppen';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName: $actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => 'Plugin-Aktion';

  @override
  String get drawerPluginActionError =>
      'Diese Aktion konnte nicht ausgeführt werden.';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerHaKiosk => 'HA-Kioskmodus';

  @override
  String get drawerCameraView => 'Kameraansicht';

  @override
  String get drawerIntercom => 'Gegensprechanlage';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => 'Schwebenden Player ausblenden';

  @override
  String get drawerShowPlayer => 'Schwebenden Player anzeigen';

  @override
  String get drawerNowPlaying => 'Jetzt läuft';

  @override
  String get drawerScreensaver => 'Bildschirmschoner starten';

  @override
  String get drawerLockdown => 'Sperrmodus';

  @override
  String get drawerHoldOff => 'Pausenmodus deaktivieren';

  @override
  String get drawerHoldOn => 'Pausenmodus aktivieren';

  @override
  String get drawerApps => 'Apps';

  @override
  String get drawerClearCache => 'Web-Cache löschen';

  @override
  String get drawerRestartDevice => 'Gerät neu starten';

  @override
  String get drawerRestartConfirm =>
      'Dieses Gerät neu starten? Kiosk Satellite wird nach dem Start automatisch wieder geöffnet.';

  @override
  String get drawerRestart => 'Neustart';

  @override
  String get drawerExitApplication => 'Anwendung beenden';

  @override
  String get drawerExitConfirm => 'Kiosk Satellite beenden?';

  @override
  String get drawerExit => 'Beenden';

  @override
  String get drawerHoldActive => 'Der Pausenmodus ist aktiviert';

  @override
  String get drawerHoldHelp =>
      'Bildschirmschoner und Timer sind pausiert · Tippen zum Deaktivieren';

  @override
  String get drawerThemeDark => 'Dunkel';

  @override
  String get drawerThemeLight => 'Hell';

  @override
  String get drawerThemeAndroid => 'Android-Einstellung verwenden';

  @override
  String drawerVersion(String version) {
    return 'Version $version';
  }

  @override
  String get drawerUpdateAvailable => 'Update verfügbar';

  @override
  String drawerUpdateInstall(String version) {
    return 'Version $version · Tippen zum Installieren';
  }

  @override
  String get drawerUpdateChecking => 'Suche nach Updates…';

  @override
  String get drawerUpdateCurrent => 'Aktuell';

  @override
  String get drawerUpdateCurrentHelp => 'Du verwendest die neueste Version.';

  @override
  String get drawerUpdateCheckFailed =>
      'Es konnte nicht nach Updates gesucht werden';

  @override
  String get drawerUpdateOffline => 'Hat das Gerät eine Internetverbindung?';

  @override
  String drawerUpdateTo(String version) {
    return 'Auf $version aktualisieren';
  }

  @override
  String get drawerUpdateInstructions =>
      'Der Download beginnt, sobald du auf „Aktualisieren“ tippst. Android wird dich anschließend auffordern, die Installation zu bestätigen.';

  @override
  String get drawerUpdateRelaunch =>
      'Ohne die Berechtigung „Über anderen Apps anzeigen“ kann die Anwendung nach dem Update nicht automatisch neu gestartet werden.';

  @override
  String get drawerUpdate => 'Aktualisieren';

  @override
  String get drawerUpdateDownloading => 'Update wird heruntergeladen';

  @override
  String get drawerUpdateStarting => 'Wird gestartet...';

  @override
  String get drawerUpdateFailed => 'Aktualisierung fehlgeschlagen';

  @override
  String get drawerUpdates => 'Updates';

  @override
  String get drawerNoReleaseNotes => 'Keine Versionshinweise verfügbar.';

  @override
  String get esphomeAllExposed =>
      'Alle verfügbaren Entitäten werden freigegeben';

  @override
  String esphomeExcludedCount(String count) {
    return '$count ausgeschlossen';
  }

  @override
  String get esphomeEntitySearch => 'Entitäten suchen';

  @override
  String get esphomeEntityLoading => 'Entitäten werden geladen...';

  @override
  String get esphomeEntityUnavailable => 'Derzeit nicht verfügbar';

  @override
  String get esphomeEntityNoMatch => 'Keine passenden Entitäten gefunden';

  @override
  String get esphomeEntityLoadFailed =>
      'Die Entitäten konnten nicht geladen werden. Schließe die Auswahl und versuche es erneut.';

  @override
  String get esphomeEntitySaveFailed =>
      'Die Ausschlüsse konnten nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get esphomeTypeConfig => 'Konfiguration';

  @override
  String get esphomeTypeDiagnostics => 'Diagnose';

  @override
  String get esphomeTypeSensorGroup => 'Sensor';

  @override
  String get esphomeTypeControl => 'Steuerung';

  @override
  String get esphomeTypeSensor => 'Sensor';

  @override
  String get esphomeTypeTextSensor => 'Textsensor';

  @override
  String get esphomeTypeBinarySensor => 'Binärsensor';

  @override
  String get esphomeTypeCamera => 'Kamera';

  @override
  String get esphomeTypeSwitch => 'Schalter';

  @override
  String get esphomeTypeButton => 'Taste';

  @override
  String get esphomeTypeNumber => 'Zahl';

  @override
  String get esphomeTypeSelect => 'Auswahl';

  @override
  String get esphomeTypeLight => 'Licht';

  @override
  String get esphomeTypeUpdate => 'Aktualisierung';

  @override
  String get esphomeTypeText => 'Text';

  @override
  String get filesUpload => 'Datei hochladen';

  @override
  String get filesUploading => 'Wird hochgeladen...';

  @override
  String get filesUploadFailed => 'Die Datei konnte nicht hochgeladen werden';

  @override
  String get filesUploaded => 'Datei hochgeladen';

  @override
  String get filesPermissionMissing =>
      'Die Berechtigung zum Zugriff auf alle Dateien fehlt';

  @override
  String get filesPermissionHelp =>
      'Ohne diese Berechtigung kannst du nur den Anwendungsordner durchsuchen. Die Berechtigungsseite wird auf dem Tablet geöffnet.';

  @override
  String get filesGrant => 'Auf dem Gerät erteilen';

  @override
  String get filesUp => 'Eine Ebene nach oben';

  @override
  String get filesShared => 'Gemeinsamer Speicher';

  @override
  String get filesApp => 'Anwendungsordner';

  @override
  String get filesReadFailed => 'Der Ordner konnte nicht gelesen werden';

  @override
  String get filesEmpty => 'Ordner ist leer';

  @override
  String get filesEmptyHelp => 'Hier ist noch nichts vorhanden.';

  @override
  String get filesFolder => 'Ordner';

  @override
  String get filesDownload => 'Herunterladen';

  @override
  String get filesDownloadFailed =>
      'Die Datei konnte nicht heruntergeladen werden';

  @override
  String filesDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get filesDeleteHelp => 'Die Datei wird vom Gerät gelöscht.';

  @override
  String get filesInvalidPath => 'Ungültiger Pfad';

  @override
  String get filesNoFolder => 'Der Ordner existiert nicht';

  @override
  String get filesNoFile => 'Die Datei existiert nicht';

  @override
  String filesReadError(String error) {
    return 'Der Ordner kann nicht gelesen werden: $error';
  }

  @override
  String filesWriteError(String error) {
    return 'Schreiben fehlgeschlagen: $error';
  }

  @override
  String get filesDeleteFailed => 'Die Datei konnte nicht gelöscht werden';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin =>
      'Für die Flottenverwaltung ist die Fernverwaltung erforderlich';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Kiosks finden sich über die Fernverwaltung. Aktiviere unter „Gerät“ die Optionen „Fernverwaltung“ und „Andere Kiosks finden“ und kehre anschließend hierher zurück.';

  @override
  String get fleetLeadThisFleet => 'Diese Flotte anführen';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      'Synchronisiert die Einstellungen dieses Kiosks mit seinen Followern. Alle Kiosks müssen dieselbe Version verwenden.';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead =>
      'Ein Kiosk, der einem Leiter folgt, kann keine Flotte anführen.';

  @override
  String get fleetFollowers => 'Follower';

  @override
  String get fleetProfiles => 'Profile';

  @override
  String get fleetLeader => 'Leiter';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      'Welche Einstellungen synchronisiert werden und welche nicht, erfährst du in der ';

  @override
  String get fleetFleetManagementDocumentation =>
      'Dokumentation zur Flottenverwaltung';

  @override
  String get fleetMore => 'Mehr';

  @override
  String get fleetSearchFollowers =>
      'Die Kiosks, die diesem folgen, ihr Status sowie die Möglichkeit, einen weiteren hinzuzufügen.';

  @override
  String get fleetAddAKiosk => 'Kiosk hinzufügen';

  @override
  String get fleetKiosksMemberOfTheFleetAFollowerMustConfirm =>
      'Füge einen gefundenen Kiosk hinzu oder gib seine IP-Adresse ein. Der Follower muss die Einladung auf seinem Bildschirm annehmen.';

  @override
  String get fleetSendInvitation => 'Einladung senden';

  @override
  String get fleetInviteAgain => 'Erneut einladen';

  @override
  String fleetRemoveName(String name) {
    return '$name entfernen?';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      'Er folgt diesem Kiosk nicht mehr und behält seine aktuellen Einstellungen.';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name möchte diesen Kiosk anführen';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      'Seine Einstellungen ersetzen ab sofort die dieses Kiosks in den synchronisierten Kategorien. Dieser Kiosk behält seinen Namen und seine Identität.';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      'Seine Einstellungen ersetzen ab sofort die dieses Kiosks in den synchronisierten Kategorien. Dieser Kiosk behält seinen Namen, seine Identitäten in Home Assistant, Music Assistant und ESPHome sowie seine ausgewählten Geräte. Du kannst die Flotte jederzeit unter Einstellungen > Flottenverwaltung verlassen.';

  @override
  String get fleetConfirmOnTheKioskItselfTheInvitationIsWaiting =>
      'Bestätige die Einladung direkt auf dem Kiosk. Sie wird auf dem Bildschirm sowie unter Einstellungen > Flottenverwaltung angezeigt.';

  @override
  String get fleetAccept => 'Annehmen';

  @override
  String get fleetLookingForOtherKiosks => 'Suche nach anderen Kiosks...';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      'Keine Kiosks gefunden. Verwende „Per IP hinzufügen“, um einen Kiosk unter einer bekannten Adresse zu finden.';

  @override
  String fleetFollowsName(String name) {
    return 'Folgt $name';
  }

  @override
  String get fleetLeadsAFleet => 'Führt eine Flotte an';

  @override
  String get fleetNoFleetManagement => 'Keine Flottenverwaltung';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      'Kiosks in diesem Netzwerk, die diesem Kiosk nicht folgen. Wähle einen aus und lege fest, welche Daten er erhalten soll, um die Einladung zu senden. Falls seine Version die Flottenverwaltung noch nicht unterstützt, kann er nach einem Update beitreten.';

  @override
  String get fleetJoinedTheFleet => 'Du bist der Flotte beigetreten';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly =>
      'Die Einstellungen des Leiters werden in Kürze übernommen.';

  @override
  String get fleetAddByIp => 'Per IP hinzufügen';

  @override
  String get fleetFindKiosk => 'Kiosk suchen';

  @override
  String get fleetFindingKiosk => 'Kiosk wird gesucht...';

  @override
  String get fleetIpAddress => 'IP-Adresse';

  @override
  String get fleetRemoteAdminPort => 'Fernverwaltungs-Port';

  @override
  String get fleetAddressHelp =>
      'Gib die IP-Adresse des Kiosks und seinen Fernverwaltungs-Port ein.';

  @override
  String get fleetAddAProfile => 'Profil hinzufügen';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      'Die Sammlung von Einstellungen, Anmeldedaten und Ausschlüssen, die synchronisiert werden sollen.';

  @override
  String get fleetNewProfile => 'Neues Profil';

  @override
  String get fleetProfile => 'Profil';

  @override
  String get fleetUpdatesOnly => 'Nur Updates';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed =>
      'Es werden keine Einstellungen synchronisiert. Es werden nur Updates verteilt.';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return 'Kategorien: $selected von $total. Anmeldedaten: $credentials von $credentialTotal. Ausgeschlossen: $excluded.';
  }

  @override
  String get fleetThisProfileIsGone => 'Dieses Profil existiert nicht mehr';

  @override
  String get fleetItWasDeletedFromAnotherPage =>
      'Es wurde auf einer anderen Seite gelöscht.';

  @override
  String get fleetName => 'Name';

  @override
  String get fleetRename => 'Umbenennen';

  @override
  String get fleetRenameProfile => 'Profil umbenennen';

  @override
  String get fleetWhatItSyncs => 'Was synchronisiert wird';

  @override
  String get fleetNothing => 'Nichts';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      'Kiosks mit diesem Profil behalten alle ihre Einstellungen. Der Leiter verteilt lediglich Updates.';

  @override
  String get fleetCategories => 'Kategorien';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected von $total: $names';
  }

  @override
  String get fleetCredentials => 'Anmeldedaten';

  @override
  String get fleetNoneTravel => 'Keine';

  @override
  String get fleetIncludeTheDashboard => 'Dashboard einschließen';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard =>
      'Die Startseite und das Standard-Dashboard.';

  @override
  String get fleetExcludedSettings => 'Ausgeschlossene Einstellungen';

  @override
  String get fleetOneSettingLeftOut => 'Eine Einstellung ausgeschlossen';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return '$count Einstellungen ausgeschlossen';
  }

  @override
  String get fleetNoKiosksAssigned => 'Keine Kiosks zugewiesen';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      'Weise dieses Profil einem Kiosk auf der Seite „Flottenverwaltung“ zu.';

  @override
  String get fleetDuplicate => 'Duplizieren';

  @override
  String get fleetCloneThisProfileIntoANewOne =>
      'Erstellt ein neues Profil auf Basis dieses Profils.';

  @override
  String get fleetDuplicateProfile => 'Profil duplizieren';

  @override
  String fleetNameCopy(String name) {
    return 'Kopie von $name';
  }

  @override
  String get fleetDeleteProfile => 'Profil löschen';

  @override
  String get fleetNoKioskIsOnIt => 'Kein Kiosk verwendet dieses Profil.';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile =>
      'Kiosks, die dieses Profil verwenden, erhalten das Standardprofil.';

  @override
  String fleetDeleteName(String name) {
    return '$name löschen?';
  }

  @override
  String get fleetBlackScreens => 'Schwarze Bildschirme';

  @override
  String fleetSyncToName(String name) {
    return 'Mit $name synchronisieren';
  }

  @override
  String get fleetDefault => 'Standard';

  @override
  String get fleetNone => 'Keine';

  @override
  String get fleetSearchProfiles =>
      'Profile, die einem Follower zugewiesen werden können: Kategorien, Anmeldedaten, Dashboard und ausgeschlossene Einstellungen.';

  @override
  String get fleetSyncNow => 'Jetzt synchronisieren';

  @override
  String get fleetChangedHereWaitingForTheLeader =>
      'Lokale Änderungen, warte auf den Leiter';

  @override
  String fleetSyncedTime(String time) {
    return 'Synchronisiert $time';
  }

  @override
  String get fleetWaitingForTheFirstSync =>
      'Warten auf die erste Synchronisierung';

  @override
  String get fleetNothingYet => 'Noch nichts';

  @override
  String get fleetNoCredentials => 'Keine Anmeldedaten';

  @override
  String fleetWithTheNames(String names) {
    return 'Mit $names';
  }

  @override
  String get fleetTheDashboard => 'das Dashboard';

  @override
  String get fleetNoDashboard => 'kein Dashboard';

  @override
  String get fleetTheDashboardDetail => 'Das Dashboard';

  @override
  String get fleetNoDashboardDetail => 'Kein Dashboard';

  @override
  String get fleetSyncedFromTheLeader => 'Vom Leiter synchronisiert';

  @override
  String get fleetLeaveTheFleet => 'Flotte verlassen';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre =>
      'Beendet die Synchronisierung. Die Einstellungen bleiben unverändert erhalten.';

  @override
  String get fleetLeaveTheFleetDetail => 'Flotte verlassen?';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name überträgt keine Einstellungen mehr auf diesen Kiosk. Alles bleibt unverändert bestehen.';
  }

  @override
  String get fleetLeave => 'Verlassen';

  @override
  String get fleetJustNow => 'gerade eben';

  @override
  String fleetCountMinAgo(String count) {
    return 'vor $count Min.';
  }

  @override
  String fleetCountHAgo(String count) {
    return 'vor $count Std.';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return 'vor $count Tagen';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return '$name verwaltet diese Einstellungen. Lokale Änderungen werden bei der nächsten Synchronisierung überschrieben.';
  }

  @override
  String get fleetDeclinedOnTheKiosk => 'Auf dem Kiosk abgelehnt';

  @override
  String get fleetWaitingForItsOk => 'Warte auf Bestätigung';

  @override
  String get fleetLeftTheFleet => 'Hat die Flotte verlassen';

  @override
  String fleetSendingPercent(String percent) {
    return 'Sende $percent %';
  }

  @override
  String get fleetInstalling => 'Installiere';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return 'Verwendet $version, dieser Kiosk benötigt ein Update';
  }

  @override
  String fleetNeedsVersion(String version) {
    return 'Benötigt $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return 'Lade $percent % herunter';
  }

  @override
  String get fleetSyncing => 'Synchronisierung läuft...';

  @override
  String get fleetErrorUnreachable => 'Nicht erreichbar';

  @override
  String get fleetErrorBadAnswer => 'Ungültige Antwort';

  @override
  String get fleetErrorThePushFailed =>
      'Die Einstellungen konnten nicht übertragen werden';

  @override
  String get fleetErrorLeadThisFleetIsOff =>
      '„Diese Flotte anführen“ ist deaktiviert';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      'Fernverwaltung und „Andere Kiosks finden“ müssen aktiviert sein';

  @override
  String get fleetErrorPickAnotherKiosk => 'Wähle einen anderen Kiosk';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      'Dieser Kiosk ist derzeit nicht im Netzwerk erreichbar';

  @override
  String get fleetErrorThatKioskDidNotAnswer =>
      'Dieser Kiosk hat nicht geantwortet';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation =>
      'Dieser Kiosk hat die Einladung abgelehnt';

  @override
  String get fleetErrorTheDefaultProfileStays =>
      'Das Standardprofil kann nicht gelöscht werden';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays =>
      'Das Profil „Nur Updates“ kann nicht gelöscht werden';

  @override
  String get fleetErrorNoSuchProfile => 'Dieses Profil existiert nicht';

  @override
  String get fleetErrorNoSuchFollower => 'Dieser Follower existiert nicht';

  @override
  String get fleetErrorNoInvitationIsWaiting =>
      'Es liegen keine ausstehenden Einladungen vor';

  @override
  String get fleetErrorMalformedInvitation => 'Ungültige Einladung';

  @override
  String get fleetErrorCouldNotMintAToken =>
      'Token konnte nicht erstellt werden';

  @override
  String get fleetErrorNotAFollowerYet => 'Noch kein Follower';

  @override
  String get fleetErrorOffline => 'Offline';

  @override
  String get fleetErrorUpToDate => 'Aktuell';

  @override
  String get fleetErrorAlreadyDownloading => 'Download läuft bereits';

  @override
  String get fleetErrorDidNotAnswer => 'Keine Antwort';

  @override
  String get fleetErrorDidNotTakeTheUpload =>
      'Die Übertragung wurde nicht akzeptiert';

  @override
  String fleetProfileNameExists(String name) {
    return 'Ein Profil mit dem Namen $name existiert bereits';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return 'Verwendet bereits $version';
  }

  @override
  String get fleetUnsupportedBuild =>
      'Dieser Kiosk verwendet eine Version ohne Flottenverwaltung. Er kann nach einem Update beitreten.';

  @override
  String get fleetErrorAddressMismatch =>
      'Die Adresse gehört zu einem anderen Kiosk oder einer anderen Flotte';

  @override
  String get fleetErrorInvalidIp => 'Bitte eine gültige IP-Adresse eingeben.';

  @override
  String get fleetErrorInvalidPort =>
      'Bitte einen Port zwischen 1 und 65535 eingeben.';

  @override
  String get fleetErrorIdentityNotReady =>
      'Die Identität dieses Kiosks ist noch nicht bereit. Bitte versuche es erneut.';

  @override
  String get fleetErrorInvalidIdentity =>
      'Unter dieser Adresse wurde keine gültige Kiosk-Identität gefunden.';

  @override
  String get fleetErrorAlreadyMember =>
      'Dieser Kiosk gehört bereits zu dieser Flotte.';

  @override
  String get fleetErrorIsLeader => 'Dieser Kiosk führt bereits eine Flotte an.';

  @override
  String get fleetErrorOtherLeader =>
      'Dieser Kiosk folgt bereits einem anderen Leiter.';

  @override
  String get fleetSwitchKiosk => 'Kiosk wechseln';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      'Gefundene Kiosks und gespeicherte Mitglieder der Flotte. Wähle einen aus, um dessen Fernverwaltung auf dieser Seite zu öffnen.';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      'Es wurden keine weiteren Kiosks gefunden. Kiosks werden angezeigt, sobald sie im Netzwerk erkannt wurden oder als Mitglieder der Flotte gespeichert sind.';

  @override
  String get fleetSyncedCredentials => 'Synchronisierte Anmeldedaten';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced =>
      'Die Einstellungen in dieser Liste werden nicht mit den Followern synchronisiert.';

  @override
  String get fleetNothingLeftOut => 'Keine Einstellungen ausgeschlossen';

  @override
  String get fleetSyncItAgain => 'Erneut synchronisieren';

  @override
  String get fleetAddASetting => 'Einstellung hinzufügen';

  @override
  String get fleetExcludeASetting => 'Einstellung ausschließen';

  @override
  String get fleetSearchSettings => 'Einstellungen suchen';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return '$count weitere. Tippe, um die Liste zu filtern.';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return 'Nicht synchronisiert: $note';
  }

  @override
  String get fleetTheAssignedSatellite => 'der zugewiesene Satellit';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain =>
      'die Mikrofon- und Lautsprechergeräte sowie die Mikrofonverstärkung';

  @override
  String get fleetTheDeviceCamera => 'die Gerätekamera';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      'der verfolgte Player und die Sendspin-Player-ID';

  @override
  String get fleetNodeNameMacEncryptionKey =>
      'der Knotenname, die MAC-Adresse und der Verschlüsselungsschlüssel';

  @override
  String get fleetThePinIsAlsoSynced => 'die PIN wird ebenfalls synchronisiert';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential =>
      'der Schlüssel, sofern er nicht als Anmeldedaten synchronisiert wird';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'der Name, die Fernverwaltung, Renderer-Kompatibilitätseinstellungen und die Skalierung';

  @override
  String get fleetHomeAssistantToken => 'Home-Assistant-Token';

  @override
  String get fleetMusicAssistantToken => 'Music-Assistant-Token';

  @override
  String get fleetImmichApiKey => 'Immich-API-Schlüssel';

  @override
  String get fleetUpdateTheFleet => 'Flotte aktualisieren';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      'Aktualisiert die gesamte Flotte auf die Kiosk-Satellite-Version, die vom Leiter verwendet wird.';

  @override
  String get fleetKeepFollowersOnThisVersion =>
      'Follower auf dieser Version belassen';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      'Aktualisiert alle Follower automatisch auf die Kiosk-Satellite-Version, die vom Leiter verwendet wird.';

  @override
  String get fleetNothingToUpdate => 'Keine Updates verfügbar';

  @override
  String get fleetUpdating => 'Aktualisierung läuft';

  @override
  String fleetNamesInstalling(String names) {
    return 'Installation auf $names.';
  }

  @override
  String get fleetSearchUpdates =>
      'Installiere die verfügbare Version auf jedem Follower und anschließend hier.';

  @override
  String get gestureAction => 'Aktion';

  @override
  String get gestureNavigate => 'Zu einer Dashboard-Ansicht wechseln';

  @override
  String get gestureUrl => 'Eine Webseite öffnen';

  @override
  String get gestureCameraView => 'Eine Kameraansicht anzeigen';

  @override
  String get gestureLauncher => 'Den App-Launcher öffnen';

  @override
  String get gestureIntercomOpen => '„Kiosk anrufen“ öffnen';

  @override
  String get gestureIntercomCall => 'Einen Kiosk anrufen';

  @override
  String get gestureScreensaver => 'Bildschirmschoner starten';

  @override
  String get gestureScreensaverStop => 'Bildschirmschoner beenden';

  @override
  String get gestureHoldMode => 'Pausenmodus ein- oder ausschalten';

  @override
  String get gestureHaKiosk => 'HA-Kioskmodus ein- oder ausschalten';

  @override
  String get gesturePluginRun => 'Eine Plugin-Aktion ausführen';

  @override
  String get gestureLaunchApp => 'Eine andere App öffnen';

  @override
  String get gestureDeepLink => 'Einen Deep Link öffnen';

  @override
  String get gestureAndroidSettings => 'Android-Einstellungen öffnen';

  @override
  String get gestureService => 'Einen Dienst aufrufen';

  @override
  String get gestureScript => 'Ein Skript ausführen';

  @override
  String get gestureAutomation => 'Eine Automatisierung auslösen';

  @override
  String get gestureEvent => 'Ein Ereignis auslösen';

  @override
  String get gesturePluginAction => 'Plugin-Aktion';

  @override
  String get gesturePluginActions => 'Plugin-Aktionen';

  @override
  String get gesturePluginHelp =>
      'Aktiviere zuerst ein Plugin mit Aktionen im Plugin-Manager.';

  @override
  String get gesturePluginFailed =>
      'Die Plugin-Aktionen konnten nicht geladen werden.';

  @override
  String get gestureUrlError => 'Bitte gib eine vollständige HTTP(S)-URL ein.';

  @override
  String get gesturePackage => 'Paketname';

  @override
  String get gesturePackageError => 'Bitte gib einen Paketnamen ein.';

  @override
  String get gestureUriError => 'Bitte gib eine vollständige URI ein.';

  @override
  String get gestureNoDashboards => 'Keine Dashboards verfügbar';

  @override
  String get gestureDashboardsFailed =>
      'Die Dashboards konnten nicht abgerufen werden';

  @override
  String get gestureHaConnected => 'Ist Home Assistant verbunden?';

  @override
  String get gestureDashboardsHelp =>
      'Die Dashboards konnten nicht abgerufen werden. Ist Home Assistant verbunden?';

  @override
  String get gestureCameraTitle => 'Kameraansicht';

  @override
  String gestureCameraShow(String name) {
    return '$name anzeigen';
  }

  @override
  String get gestureCameraClose => 'Kameraansicht schließen';

  @override
  String get gestureCameraEmpty =>
      'Es sind noch keine Kameraansichten konfiguriert.';

  @override
  String get gestureIntercomEmpty =>
      'Es wurde noch kein Kiosk im Netzwerk gefunden.';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '$count-mal auf die Ecke $corner tippen';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return 'Ecke $corner ${seconds}s gedrückt halten';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return 'Doppeltippen mit $count Fingern';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return 'Tippen mit $count Fingern';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return 'Mit $count Fingern ${seconds}s gedrückt halten';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return 'Eckensequenz: $sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '$count Klatscher';
  }

  @override
  String get gestureDescribeOpenHand => 'Offene Hand zeigen';

  @override
  String gestureDescribeOneFinger(String count) {
    return '$count Finger zeigen';
  }

  @override
  String gestureDescribeFingers(String count) {
    return '$count Finger zeigen';
  }

  @override
  String get gestureTopLeft => 'oben links';

  @override
  String get gestureTopRight => 'oben rechts';

  @override
  String get gestureBottomLeft => 'unten links';

  @override
  String get gestureBottomRight => 'unten rechts';

  @override
  String gestureGoTo(String value) {
    return 'Zu $value wechseln';
  }

  @override
  String gestureOpen(String value) {
    return '$value öffnen';
  }

  @override
  String get gestureCameraToggle => 'Kameraansicht ein- oder ausblenden';

  @override
  String gestureCameraToggleName(String name) {
    return 'Kameraansicht $name ein- oder ausblenden';
  }

  @override
  String gestureCall(String value) {
    return '$value anrufen';
  }

  @override
  String gestureOpenApp(String package) {
    return 'App $package öffnen';
  }

  @override
  String gestureRun(String value) {
    return '$value ausführen';
  }

  @override
  String gestureTriggerAction(String value) {
    return '$value auslösen';
  }

  @override
  String gestureFireEvent(String value) {
    return 'Ereignis $value auslösen';
  }

  @override
  String get gestureValid => 'Alles in Ordnung.';

  @override
  String get gestureValidationFailed => 'Validierung fehlgeschlagen.';

  @override
  String gestureDomainMissing(String value) {
    return 'Die Domäne $value wurde nicht gefunden.';
  }

  @override
  String gestureServiceMissing(String value) {
    return 'Der Dienst $value wurde nicht gefunden.';
  }

  @override
  String gestureEntityMissing(String value) {
    return 'Die Entität $value wurde nicht gefunden.';
  }

  @override
  String gestureEntityRequired(String domain) {
    return 'Bitte eine Entität vom Typ $domain.* eingeben.';
  }

  @override
  String get gestureScriptEntity => 'Skript-Entität';

  @override
  String get gestureAutomationEntity => 'Automatisierungs-Entität';

  @override
  String get gestureDomain => 'Domäne';

  @override
  String get gestureEntityOptional => 'Entität (optional)';

  @override
  String get gestureServiceData => 'Dienstedaten (optional)';

  @override
  String get gestureServiceTitle => 'Home-Assistant-Dienst aufrufen';

  @override
  String get gestureServiceRequired => 'Domäne und Dienst sind erforderlich.';

  @override
  String get gestureServiceJson =>
      'Die Dienstedaten müssen ein JSON-Objekt sein.';

  @override
  String get gestureEventType => 'Ereignistyp';

  @override
  String get gestureEventData => 'Ereignisdaten (optional)';

  @override
  String get gestureEventTitle => 'Home-Assistant-Ereignis auslösen';

  @override
  String get gestureEventRequired => 'Der Ereignistyp ist erforderlich.';

  @override
  String get gestureEventJson =>
      'Die Ereignisdaten müssen ein JSON-Objekt sein.';

  @override
  String get gestureTester => 'Handgesten-Test';

  @override
  String get gestureOpenTester => 'Test öffnen';

  @override
  String get gestureCameraFirst =>
      'Aktiviere zuerst die Kamera in den Kamera-Einstellungen.';

  @override
  String get gestureTesterHelp =>
      'Beobachte, welche Finger von der Kamera erkannt werden, um zu lernen, wie du deine Hand halten musst.';

  @override
  String get gestureHandHelp =>
      'Halte deine Hand auf Schulterhöhe mit der Handfläche zur Kamera und gespreizten Fingern. Beuge einen Finger vollständig, damit er nicht mehr gezählt wird. Lege den Daumen auf die Handfläche, um vier Finger anzuzeigen. Der Daumen wird nur bei einer offenen Hand gezählt.';

  @override
  String get gestureTesterPaused =>
      'Während der Test geöffnet ist, werden keine Gesten ausgeführt.';

  @override
  String get gestureShowHand => 'Zeige der Kamera eine Hand.';

  @override
  String gestureTesterTrigger(String action) {
    return 'Ausführen: $action';
  }

  @override
  String get gestureNoCount => 'Keine Geste verwendet diese Anzahl an Fingern.';

  @override
  String get gestureNoHand => 'Keine Hand erkannt';

  @override
  String get gestureReadingHand => 'Hand wird erkannt';

  @override
  String get gestureNoFingers => 'Kein Finger ausgestreckt';

  @override
  String gestureHandsCount(String count) {
    return '$count Hände erkannt. Die größte Hand wird ausgewertet.';
  }

  @override
  String get gestureTesterSearch =>
      'Zeigt in Echtzeit die Finger an, die von der Kamera erkannt werden.';

  @override
  String get gestureHoldConfirmed => 'Haltedauer erreicht';

  @override
  String gestureHoldProgress(String progress) {
    return 'Haltefortschritt: $progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return 'Haltedauer: $duration';
  }

  @override
  String get gestureHaServiceKind => 'Home-Assistant-Dienst';

  @override
  String get gestureHaScriptKind => 'Home-Assistant-Skript';

  @override
  String get gestureHaAutomationKind => 'Home-Assistant-Automatisierung';

  @override
  String get gestureHaEventKind => 'Home-Assistant-Ereignis';

  @override
  String gestureRan(String value) {
    return '$value wurde ausgeführt';
  }

  @override
  String gestureRunFailed(String value) {
    return '$value konnte nicht ausgeführt werden';
  }

  @override
  String gestureCalled(String value) {
    return '$value wurde aufgerufen';
  }

  @override
  String gestureCallFailed(String value) {
    return '$value konnte nicht aufgerufen werden';
  }

  @override
  String gestureTriggered(String value) {
    return '$value wurde ausgelöst';
  }

  @override
  String gestureTriggerFailed(String value) {
    return '$value konnte nicht ausgelöst werden';
  }

  @override
  String gestureFired(String value) {
    return 'Ereignis $value wurde ausgelöst';
  }

  @override
  String gestureFireFailed(String value) {
    return 'Ereignis $value konnte nicht ausgelöst werden';
  }

  @override
  String get gestureDone => 'Fertig';

  @override
  String get gestureFailed => 'Fehler';

  @override
  String get gestureEdit => 'Geste bearbeiten';

  @override
  String get gestureTrigger => 'Geste';

  @override
  String get gestureCornerTaps => 'Tippen auf eine Ecke';

  @override
  String get gestureCornerHold => 'Eine Ecke gedrückt halten';

  @override
  String get gestureFingerTaps => 'Tippen mit mehreren Fingern';

  @override
  String get gestureFingerHold => 'Mit mehreren Fingern gedrückt halten';

  @override
  String get gestureSequence => 'Eckensequenz';

  @override
  String get gestureClaps => 'Klatschen';

  @override
  String get gestureShowFingers => 'Finger zeigen';

  @override
  String get gestureCorner => 'Ecke';

  @override
  String get gestureCornerTl => 'Obere linke Ecke';

  @override
  String get gestureCornerTr => 'Obere rechte Ecke';

  @override
  String get gestureCornerBl => 'Untere linke Ecke';

  @override
  String get gestureCornerBr => 'Untere rechte Ecke';

  @override
  String get gestureTaps => 'Tippen';

  @override
  String get gestureTaps2 => '2-mal tippen';

  @override
  String get gestureTaps3 => '3-mal tippen';

  @override
  String get gestureTaps4 => '4-mal tippen';

  @override
  String get gestureFingers => 'Finger';

  @override
  String get gestureFinger1 => '1 Finger';

  @override
  String get gestureFinger2 => '2 Finger';

  @override
  String get gestureFinger3 => '3 Finger';

  @override
  String get gestureFinger4 => '4 Finger';

  @override
  String get gestureOpenHand5 => 'Offene Hand (5)';

  @override
  String get gestureSingleTap => 'Einmal tippen';

  @override
  String get gestureDoubleTap => 'Doppeltippen';

  @override
  String gestureHoldDuration(String seconds) {
    return '$seconds Sek. gedrückt halten';
  }

  @override
  String get gestureCameraHelp =>
      'Erfordert eine aktivierte Kamera und eine gut beleuchtete Umgebung.';

  @override
  String get gestureUnavailable => 'Auf diesem Gerät nicht verfügbar.';

  @override
  String get gestureClaps2 => '2-mal klatschen';

  @override
  String get gestureClaps3 => '3-mal klatschen';

  @override
  String get gestureClaps4 => '4-mal klatschen';

  @override
  String get gestureClapHelp =>
      'Klatschen wird über das Mikrofon erkannt, mit oder ohne Aktivierungswort-Erkennung.';

  @override
  String get gestureSequenceHelp =>
      'Tippe die Ecken in der vorgegebenen Reihenfolge an (2 bis 8 Schritte).';

  @override
  String get gestureRemoveStep => 'Letzten Schritt entfernen';

  @override
  String get gestureUndo => 'Rückgängig';

  @override
  String get gestureChooseAction => 'Aktion auswählen';

  @override
  String get gestureActionHelp => 'Legt fest, was diese Geste ausführt.';

  @override
  String get gestureChangeHelp => 'Tippen zum Ändern.';

  @override
  String get gestureChooseError => 'Bitte eine Aktion auswählen.';

  @override
  String get gestureSequenceError => 'Füge mindestens zwei Ecken hinzu.';

  @override
  String get intercomCall => 'Anrufen';

  @override
  String get intercomNoReady => 'Keine Kiosks bereit.';

  @override
  String get intercomOneReady => '1 Kiosk ist bereit.';

  @override
  String intercomManyReady(String count) {
    return '$count Kiosks sind bereit.';
  }

  @override
  String get intercomCallKiosk => 'Einen Kiosk anrufen';

  @override
  String get intercomAnnounceAll => 'An alle durchsagen';

  @override
  String get intercomAnnounceHelp =>
      'Sprich zu allen Kiosks. Nur du kannst sprechen.';

  @override
  String intercomMissedFrom(String name) {
    return 'Verpasster Anruf von $name';
  }

  @override
  String intercomRangFor(String seconds) {
    return '$seconds Sekunden geklingelt.';
  }

  @override
  String get intercomCallBack => 'Zurückrufen';

  @override
  String get intercomDeclined => 'Abgelehnt';

  @override
  String get intercomBusy => 'Besetzt';

  @override
  String get intercomPeerOff =>
      'Die Gegensprechanlage des anderen Kiosks ist deaktiviert';

  @override
  String get intercomPeerKey => 'Abweichender Intercom-Schlüssel';

  @override
  String get intercomNoAnswer => 'Keine Antwort';

  @override
  String get intercomDidNotAnswer => 'Hat nicht geantwortet';

  @override
  String get intercomVoiceFailed => 'Sprachverbindung fehlgeschlagen';

  @override
  String get intercomCancelled => 'Abgebrochen';

  @override
  String get intercomPageMic => 'Die Seite verwendet das Mikrofon';

  @override
  String get intercomNobody => 'Niemand konnte die Durchsage empfangen';

  @override
  String get intercomDone => 'Abgeschlossen';

  @override
  String get intercomEnded => 'Anruf beendet';

  @override
  String get intercomAnnouncement => 'Durchsage';

  @override
  String get intercomAnnouncingOne => 'Durchsage an 1 Kiosk';

  @override
  String intercomAnnouncingMany(String count) {
    return 'Durchsage an $count Kiosks';
  }

  @override
  String get intercomIsCalling => 'ruft an';

  @override
  String get intercomIsAnnouncing => 'macht eine Durchsage';

  @override
  String get intercomCalling => 'Anruf läuft...';

  @override
  String intercomAnswersIn(String seconds) {
    return 'Antwort in $seconds Sek.';
  }

  @override
  String get intercomRinging => 'Klingelt';

  @override
  String get intercomConnecting => 'Verbindung wird hergestellt...';

  @override
  String intercomDoneDuration(String duration) {
    return 'Abgeschlossen, $duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return 'Anruf beendet, $duration';
  }

  @override
  String get intercomDecline => 'Ablehnen';

  @override
  String get intercomAnswer => 'Annehmen';

  @override
  String get intercomEveryKiosk => 'Alle Kiosks';

  @override
  String get intercomStop => 'Stoppen';

  @override
  String intercomHearsYou(String name) {
    return '$name hört dich';
  }

  @override
  String get intercomAllHearYou => 'Alle Kiosks hören dich';

  @override
  String get intercomHoldHelp =>
      'Zum Sprechen gedrückt halten und zum Zuhören loslassen';

  @override
  String get intercomMuted => 'Stummgeschaltet';

  @override
  String get intercomMute => 'Stummschalten';

  @override
  String get intercomEnd => 'Beenden';

  @override
  String get intercomReply => 'Antworten';

  @override
  String get intercomDismiss => 'Schließen';

  @override
  String get intercomCallAgain => 'Erneut anrufen';

  @override
  String get intercomDashboardMic =>
      'Das Dashboard verwendet das Mikrofon. Du kannst nur zuhören.';

  @override
  String get intercomMicDenied =>
      'Der Mikrofonzugriff wurde nicht gewährt. Du kannst nur zuhören.';

  @override
  String get intercomHoldTalk => 'Zum Sprechen gedrückt halten';

  @override
  String get intercomPlaying => 'Wiedergabe läuft';

  @override
  String get intercomAKiosk => 'ein Kiosk';

  @override
  String intercomCallingName(String name) {
    return '$name wird angerufen';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name ruft an';
  }

  @override
  String intercomInCallName(String name) {
    return 'Im Gespräch mit $name';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name macht eine Durchsage';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant: $message';
  }

  @override
  String get intercomEndCall => 'Anruf beenden';

  @override
  String get intercomCallFailed => 'Anruf konnte nicht gestartet werden';

  @override
  String get intercomKeyFailed => 'Der Schlüssel konnte nicht geändert werden';

  @override
  String get intercomBroadcastFailed => 'Durchsage an alle fehlgeschlagen';

  @override
  String get intercomDeviceNoAnswer => 'Das Gerät hat nicht geantwortet.';

  @override
  String get intercomUnknownKiosk => 'unbekannter Kiosk';

  @override
  String get intercomNothingRinging => 'es klingelt kein Anruf';

  @override
  String get intercomNoCall => 'kein aktiver Anruf';

  @override
  String get intercomDisabled => 'die Gegensprechanlage ist deaktiviert';

  @override
  String get intercomNeedsRemote => 'Fernverwaltung wird benötigt';

  @override
  String get intercomNeedsDiscovery =>
      'die Gegensprechanlage benötigt Fernverwaltung und „Andere Kiosks finden“';

  @override
  String get intercomAlreadyCalling => 'es läuft bereits ein Anruf';

  @override
  String get intercomNoReadyError => 'keine Kiosks bereit';

  @override
  String get intercomKeyLength =>
      'der Schlüssel muss mindestens 16 Zeichen lang sein';

  @override
  String get intercomMicHeld => 'die Seite verwendet das Mikrofon';

  @override
  String get intercomMicPermission => 'Mikrofonzugriff wurde nicht gewährt';

  @override
  String get intercomCallerNoAnswer =>
      'der anrufende Kiosk hat nicht geantwortet';

  @override
  String get intercomMissedcall => 'Verpasster Anruf';

  @override
  String get intercomListening => 'Hört zu';

  @override
  String get intercomAnnouncementsoff => 'Durchsagen deaktiviert';

  @override
  String get intercomEncryptionMismatch =>
      'Verschlüsselung stimmt nicht überein';

  @override
  String get intercomEncryptionMismatchHelp =>
      'Die Verschlüsselungseinstellungen stimmen nicht überein. Aktiviere Kommunikation verschlüsseln auf allen Kiosken im Anruf.';

  @override
  String get kioskBackClose =>
      'Drücke „Zurück“ erneut, um die App zu schließen';

  @override
  String get kioskBackAgain => 'Drücke „Zurück“ erneut, um zurückzugehen';

  @override
  String get kioskHoldOn => 'Pausenmodus aktiviert';

  @override
  String get kioskHoldOff => 'Pausenmodus deaktiviert';

  @override
  String get kioskHoldNotice =>
      'Die aktuelle Ansicht bleibt bestehen, bis du den Modus deaktivierst.';

  @override
  String get kioskDownloadComplete => 'Download abgeschlossen';

  @override
  String get kioskDownloadFailed =>
      'Die Datei konnte nicht heruntergeladen werden';

  @override
  String get kioskDownload => 'Download';

  @override
  String get kioskDownloading => 'Wird heruntergeladen';

  @override
  String get kioskOpen => 'Öffnen';

  @override
  String get kioskTip => 'Tipp';

  @override
  String get kioskMenuHint =>
      'Wische vom linken Bildschirmrand, um das Menü zu öffnen.';

  @override
  String get kioskUnknownLink => 'Unbekannter Kiosk-Link';

  @override
  String get kioskOpenAppFailed => 'Die App konnte nicht geöffnet werden';

  @override
  String get kioskWebViewMissing =>
      'Android System WebView ist nicht installiert';

  @override
  String get kioskWebViewMissingHelp =>
      'Auf diesem Gerät ist kein WebView-Anbieter installiert, daher kann Home Assistant nicht angezeigt werden. Installiere Android System WebView oder Chrome und starte Kiosk Satellite neu.';

  @override
  String get kioskPinTitle => 'Kiosk-PIN';

  @override
  String get kioskPinHint => 'PIN';

  @override
  String get kioskWrongPin => 'Falsche PIN';

  @override
  String get kioskUnlock => 'Entsperren';

  @override
  String get lockdownScreenLocked => 'Der Bildschirm ist gesperrt';

  @override
  String get logsWebConsole => 'Web-Konsole';

  @override
  String get logsDock => 'Über der aktuellen Seite andocken';

  @override
  String get logsNoOutput => 'Die Konsole enthält noch keine Meldungen';

  @override
  String get logsShareSubject => 'Kiosk-Satellite-Konsolenprotokoll';

  @override
  String get logsInput => 'JavaScript auf der Seite ausführen';

  @override
  String get logsInputHistory =>
      'JavaScript auf der Seite ausführen (Eingabe zum Ausführen, Hoch/Runter für den Verlauf)';

  @override
  String get logsRun => 'Ausführen';

  @override
  String get logsEvaluationFailed => 'Ausführung fehlgeschlagen';

  @override
  String get logsDeviceUnreachable => 'Verbindung zum Gerät nicht möglich';

  @override
  String logsEntries(String count) {
    return '$count Einträge';
  }

  @override
  String get logsCopyLog => 'Protokoll kopieren';

  @override
  String get logsShareLog => 'Protokoll teilen';

  @override
  String get logsCopied => 'Kopiert';

  @override
  String get logsCopyFailed => 'Kopieren fehlgeschlagen';

  @override
  String get logsOnClipboard =>
      'Das Protokoll wurde in die Zwischenablage kopiert.';

  @override
  String get logsConsoleOnClipboard =>
      'Das Konsolenprotokoll wurde in die Zwischenablage kopiert.';

  @override
  String get logsSystemLog =>
      'Android-Systemprotokoll für diese Anwendung (einschließlich Abstürzen)';

  @override
  String get logsErrors => 'Fehler und Abstürze';

  @override
  String get logsWarnings => 'Warnungen';

  @override
  String get logsInfo => 'Informationen und Debug-Ausgaben';

  @override
  String get logsNoMatches =>
      'Keine passenden Einträge gefunden. Aktiviere oben weitere Typen, um das vollständige Protokoll anzuzeigen.';

  @override
  String get logsUnavailable => 'Logcat nicht verfügbar';

  @override
  String logsReadFailed(String error) {
    return 'Logcat konnte nicht gelesen werden: $error';
  }

  @override
  String get logsUnknown => 'unbekannt';

  @override
  String get offlineDashboard => 'Dashboard nicht verfügbar';

  @override
  String get offlineNetwork => 'Keine Netzwerkverbindung';

  @override
  String get offlinePageHelp => 'Die Seite konnte nicht geladen werden.';

  @override
  String get offlineNetworkHelp =>
      'Das Dashboard wird wieder angezeigt, sobald die Netzwerkverbindung wiederhergestellt wurde.';

  @override
  String get offlineLost => 'Die Netzwerkverbindung wurde unterbrochen';

  @override
  String get offlineRestored =>
      'Die Netzwerkverbindung wurde wiederhergestellt';

  @override
  String get mediaPlay => 'Wiedergabe';

  @override
  String get mediaPause => 'Pause';

  @override
  String get mediaPreviousTrack => 'Vorheriger Titel';

  @override
  String get mediaNextTrack => 'Nächster Titel';

  @override
  String get mediaPlaying => 'Wird wiedergegeben';

  @override
  String get mediaPaused => 'Pausiert';

  @override
  String get mediaIdle => 'Bereit';

  @override
  String get mediaStatusUnavailable => 'Status nicht verfügbar';

  @override
  String get mediaUnknownTrack => 'Unbekannter Titel';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => 'Lautstärke anzeigen';

  @override
  String get mediaHideVolume => 'Lautstärke ausblenden';

  @override
  String get mediaMute => 'Stummschalten';

  @override
  String get mediaUnmute => 'Ton einschalten';

  @override
  String get mediaFavoriteAdd => 'Zu Favoriten hinzufügen';

  @override
  String get mediaFavoriteRemove => 'Aus Favoriten entfernen';

  @override
  String get mediaShuffleOn => 'Zufallswiedergabe aktivieren';

  @override
  String get mediaShuffleOff => 'Zufallswiedergabe deaktivieren';

  @override
  String get mediaRepeatAll => 'Alles wiederholen';

  @override
  String get mediaRepeatOne => 'Einen Titel wiederholen';

  @override
  String get mediaRepeatOff => 'Wiederholung deaktivieren';

  @override
  String get mediaShowLyrics => 'Songtexte anzeigen';

  @override
  String get mediaHideLyrics => 'Songtexte ausblenden';

  @override
  String get mediaShowQueue => 'Warteschlange anzeigen';

  @override
  String get mediaHideQueue => 'Warteschlange ausblenden';

  @override
  String get mediaVolume => 'Lautstärke';

  @override
  String get mediaPlaybackPosition => 'Wiedergabeposition';

  @override
  String get mediaShowNowPlaying => '„Jetzt läuft“ anzeigen';

  @override
  String get mediaShowFloatingPlayer => 'Schwebenden Player anzeigen';

  @override
  String get mediaOpenMusicAssistant => 'Music Assistant öffnen';

  @override
  String get mediaCannotControl =>
      'Der Befehl wird nicht unterstützt oder konnte nicht gesendet werden.';

  @override
  String get mediaNothingQueued => 'Nichts in der Warteschlange';

  @override
  String get mediaChapters => 'Kapitel';

  @override
  String get mediaNowPlaying => 'Jetzt läuft';

  @override
  String get mediaUpNext => 'Als Nächstes';

  @override
  String mediaUnnamedChapter(String number) {
    return 'Kapitel $number';
  }

  @override
  String get mediaGroupLead => 'Leitet die Gruppe';

  @override
  String get mediaGroupReadFailed =>
      'Die Gruppe konnte nicht abgefragt werden.';

  @override
  String get mediaGroupEmpty =>
      'Es sind keine weiteren Player zum Gruppieren verfügbar.';

  @override
  String get mediaSpeakerSelection => 'Lautsprecherauswahl';

  @override
  String pluginCloseWindow(String name) {
    return '$name schließen';
  }

  @override
  String get pluginActions => 'Aktionen';

  @override
  String get pluginKioskDrawer => 'Kiosk-Menü';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      'Um eine Geste zuzuweisen, öffne „Gesten“ und wähle „Plugin-Aktion ausführen“ aus.';

  @override
  String get pluginShowInKioskDrawer => 'Im Kiosk-Menü anzeigen';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      'Auch im Sperrmodus verfügbar, wenn das Kiosk-Menü erlaubt ist.';

  @override
  String get pluginExposeToHomeAssistant => 'In Home Assistant veröffentlichen';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      'Fügt dem ESPHome-Gerät des Kiosks eine Schaltfläche hinzu. Erfordert ESPHome und native Entitäten.';

  @override
  String get pluginSelectAnEntity => 'Eine Entität auswählen';

  @override
  String pluginChooseName(String name) {
    return '$name auswählen';
  }

  @override
  String pluginConfigureName(String name) {
    return '$name konfigurieren';
  }

  @override
  String get pluginPlugin => 'Plugin';

  @override
  String get pluginEnablePlugins => 'Plugins aktivieren';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      'Plugins erweitern Kiosk Satellite um zusätzliche, von der Community entwickelte Funktionen.';

  @override
  String get pluginInstalledPlugins => 'Installierte Plugins';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      'Keine Plugins installiert. Füge ein Repository hinzu, um loszulegen.';

  @override
  String get pluginDeveloperTools => 'Entwicklerwerkzeuge';

  @override
  String get pluginCreateAPlugin => 'Plugin erstellen';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      'Lerne anhand der Hello-World-Vorlage und der Dokumentation, wie Plugins erstellt werden.';

  @override
  String get pluginThisPluginIsNoLongerInstalled =>
      'Dieses Plugin ist nicht mehr installiert.';

  @override
  String get pluginEnablePluginsToRunThisPlugin =>
      'Aktiviere Plugins, um dieses Plugin auszuführen.';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      'Aktiviere dieses Plugin über seinen Eintrag in der Liste, um es auszuführen.';

  @override
  String pluginUninstallName(String name) {
    return '$name deinstallieren?';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return '$name deinstallieren';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return 'Nach Updates für $name suchen';
  }

  @override
  String pluginAboutName(String name) {
    return 'Über $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings =>
      'Dadurch werden das Plugin und seine Einstellungen entfernt.';

  @override
  String get pluginUninstall => 'Deinstallieren';

  @override
  String get pluginNoUpdatesAvailable => 'Keine Updates verfügbar.';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      'Dieses Plugin wurde aus einer ZIP-Datei installiert und verfügt über keine README-Datei aus einem Repository.';

  @override
  String get pluginImageUnavailable => 'Bild nicht verfügbar';

  @override
  String get pluginCouldNotOpenThisLink =>
      'Dieser Link konnte nicht geöffnet werden.';

  @override
  String pluginEnableName(String name) {
    return '$name aktivieren';
  }

  @override
  String get pluginAddPlugin => 'Plugin hinzufügen';

  @override
  String get pluginInstallFromAGithubRepository =>
      'Aus einem GitHub-Repository installieren';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd =>
      'Stelle sicher, dass du dem Autor des Plugins und seinem Code vertraust, bevor du es installierst.';

  @override
  String get pluginPreview => 'Vorschau';

  @override
  String get pluginInstalledVersion => 'Installierte Version';

  @override
  String get pluginAuthor => 'Autor';

  @override
  String get pluginLicense => 'Lizenz';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      'Plugins führen Code innerhalb von Kiosk Satellite aus und können auf Anwendungsdaten sowie erteilte Android-Berechtigungen zugreifen. Ein fehlerhaftes oder bösartiges Plugin kann private Informationen offenlegen oder die Funktion der Anwendung beeinträchtigen. Installiere daher nur Plugins von Autoren, denen du vertraust.';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      'Neue Plugins werden zunächst deaktiviert installiert. Updates behalten den Aktivierungsstatus bei und starten laufende Plugins automatisch neu.';

  @override
  String get pluginTrustAndUpdate => 'Vertrauen und aktualisieren';

  @override
  String get pluginTrustAndInstall => 'Vertrauen und installieren';

  @override
  String get pluginInstallFromZip => 'Aus ZIP installieren';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild =>
      'Nur für Entwickler: Einen lokalen Build testen';

  @override
  String get pluginPluginZip => 'Plugin-ZIP';

  @override
  String get pluginPluginZipMustBeAtMost4Mb =>
      'Die Plugin-ZIP-Datei darf höchstens 4 MB groß sein';

  @override
  String get pluginCouldNotReadTheSelectedZip =>
      'Die ausgewählte ZIP-Datei konnte nicht gelesen werden';

  @override
  String get pluginCharts => 'Diagramme';

  @override
  String get pluginReadings => 'Messwerte';

  @override
  String get pluginWaitingForSamples => 'Warte auf Messwerte';

  @override
  String get pluginLatest => 'Neueste';

  @override
  String get pluginSelected => 'Ausgewählt';

  @override
  String get pluginNoDataYet => 'Noch keine Daten verfügbar';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      'Tippe oder ziehe, um Messwerte zu prüfen. Doppeltippen, um dem neuesten Messwert zu folgen.';

  @override
  String get pluginNoData => 'Keine Daten';

  @override
  String get pluginOn => 'Ein';

  @override
  String get pluginEmpty => 'Leer';

  @override
  String get pluginChartKeyboardHelp =>
      'Verwende die Pfeiltasten, um Messwerte zu durchsuchen, und die Ende-Taste, um zum neuesten Messwert zu springen.';

  @override
  String get pluginErrorAssetPath => 'Der Dateipfad ist ungültig';

  @override
  String get pluginErrorAssetMissing =>
      'Die Datei existiert nicht oder befindet sich außerhalb ihres Pakets';

  @override
  String get pluginErrorAssetSymlink =>
      'Das Dateiverzeichnis darf kein symbolischer Link sein';

  @override
  String get pluginErrorAssetSymlinks =>
      'Dateiverzeichnisse dürfen keine symbolischen Links sein';

  @override
  String get pluginErrorAssetsIntegrity =>
      'Die installierten Dateien haben die Integritätsprüfung nicht bestanden';

  @override
  String get pluginErrorAssetIntegrity =>
      'Die installierte Datei hat die Integritätsprüfung nicht bestanden';

  @override
  String get pluginErrorManifestMismatch =>
      'Das Paketmanifest stimmt nicht mit dem Manifest der überprüften Version überein';

  @override
  String get pluginErrorStagingExists =>
      'Das Staging-Verzeichnis existiert bereits';

  @override
  String get pluginErrorCreateDirectory =>
      'Das Plugin-Verzeichnis kann nicht erstellt werden';

  @override
  String get pluginErrorFileCount =>
      'Pro Paket werden maximal 512 Dateien unterstützt';

  @override
  String get pluginErrorProtectFile =>
      'Die Plugin-Datei kann nicht geschützt werden';

  @override
  String get pluginErrorExpandedSize =>
      'Das entpackte Plugin überschreitet 4 MB';

  @override
  String get pluginErrorManifestSize => 'Das Manifest überschreitet 32 KB';

  @override
  String get pluginErrorRequiredFiles =>
      'Das Paket benötigt kiosk-satellite-plugin.json, plugin.jar und LICENSE';

  @override
  String get pluginErrorNativeCapability =>
      'Native Bibliotheken erfordern die Fähigkeit „native“';

  @override
  String get pluginErrorNativeElf => 'Die native ELF-Bibliothek ist ungültig';

  @override
  String get pluginErrorNativeAbi =>
      'Die ABI der nativen Bibliothek stimmt nicht mit ihrem Verzeichnis überein';

  @override
  String get pluginErrorDexOnly => 'plugin.jar darf nur DEX-Dateien enthalten';

  @override
  String get pluginErrorDexHeader => 'Der DEX-Header ist ungültig';

  @override
  String get pluginErrorDexSize => 'Die entpackte DEX-Datei überschreitet 4 MB';

  @override
  String get pluginErrorDexEmpty => 'Die DEX-Datei ist leer';

  @override
  String get pluginErrorDexMissing => 'plugin.jar enthält keine classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'Unerwarteter oder doppelter ZIP-Eintrag: $name';
  }

  @override
  String get pluginErrorRepositoryMismatch =>
      'Die veröffentlichte Repository-Version gehört zu einem anderen Plugin.';

  @override
  String get pluginErrorRepositoryUrl =>
      'Gib die URL eines öffentlichen Repositorys im Format https://github.com/owner/repository ein';

  @override
  String get pluginErrorRepositoryPath =>
      'Verwende die Repository-URL ohne den Pfad zu einer Datei oder einem Branch';

  @override
  String get pluginErrorDownloadOutsideGithub =>
      'Der Download des Plugins wurde außerhalb von GitHub umgeleitet';

  @override
  String get pluginErrorInvalidRedirect =>
      'Die GitHub-Weiterleitung ist ungültig';

  @override
  String get pluginErrorRepositoryNotFound =>
      'Das öffentliche Repository, die stabile Version, kiosk-satellite-plugin.json, README.md oder eine Datei der veröffentlichten Version wurde nicht gefunden.';

  @override
  String get pluginErrorGithubLimited =>
      'GitHub hat die Anfrage abgelehnt oder das Anfragelimit wurde erreicht. Bitte versuche es später erneut.';

  @override
  String get pluginErrorRepositorySize =>
      'Die Repository-Datei überschreitet die zulässige Größenbeschränkung';

  @override
  String get pluginErrorTooManyRedirects => 'Zu viele GitHub-Weiterleitungen';

  @override
  String get pluginErrorStableRelease =>
      'GitHub hat keine veröffentlichte stabile Version zurückgegeben';

  @override
  String get pluginErrorReleaseTag => 'Das Release-Tag ist ungültig';

  @override
  String get pluginErrorManifestFile =>
      'Das Manifest kiosk-satellite-plugin.json ist ungültig';

  @override
  String get pluginErrorIdVersion => 'Die Plugin-ID oder Version ist ungültig';

  @override
  String get pluginErrorChecksumFilename =>
      'Die Prüfsumme der Version oder der Paketname ist ungültig';

  @override
  String get pluginErrorGithubDigest =>
      'Die Prüfsumme der Version muss mit dem SHA-256-Hash der Datei auf GitHub übereinstimmen';

  @override
  String get pluginErrorTagRevision =>
      'GitHub hat die Revision des Release-Tags nicht zurückgegeben';

  @override
  String get pluginErrorTrustAuthor =>
      'Bitte bestätige, dass du dem Autor des Plugins vertraust';

  @override
  String get pluginErrorPreviewExpired =>
      'Diese Vorschau ist abgelaufen. Rufe die Repository-Vorschau erneut auf, bevor du installierst.';

  @override
  String get pluginErrorReviewedChecksum =>
      'Der SHA-256-Hash des Pakets stimmt nicht mit der geprüften Version überein';

  @override
  String get pluginErrorNotInstalled => 'Das Plugin ist nicht installiert';

  @override
  String get pluginErrorUpdateZip =>
      'Dieses Plugin wurde aus einer ZIP-Datei installiert. Verwende „Aus ZIP installieren“, um es zu aktualisieren.';

  @override
  String get pluginErrorAndroidOnly =>
      'Plugins sind nur auf Android verfügbar.';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'Die Anfrage an GitHub ist fehlgeschlagen ($status)';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return 'Die Version muss genau eine hochgeladene Datei $name enthalten';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return 'Die Datei $name der Version muss von GitHub Actions veröffentlicht werden. Manuell hochgeladene Dateien werden nicht unterstützt.';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return 'Die Datei $name der Version überschreitet die zulässige Größe oder ist leer';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return 'Die URL der Version für $name ist ungültig';
  }

  @override
  String get pluginErrorNativeLibrary =>
      'Für die ABI dieses Geräts ist keine native Bibliothek im Plugin vorhanden';

  @override
  String get pluginErrorCallbackTimeout =>
      'Die Antwort des Plugins hat zu lange gedauert. Starte den Kiosk neu, falls das Plugin noch laufende Aufgaben hinterlassen hat.';

  @override
  String get pluginErrorEnableFirst => 'Aktiviere zuerst das Plugin';

  @override
  String get pluginErrorSaveState =>
      'Der Plugin-Status kann nicht gespeichert werden';

  @override
  String get pluginErrorPackageHash =>
      'Der Hash des installierten Pakets ist ungültig';

  @override
  String get pluginErrorChecksum =>
      'Der SHA-256-Hash des Pakets stimmt nicht überein';

  @override
  String get pluginErrorDifferentRepository =>
      'Diese Plugin-ID gehört zu einem anderen Repository. Deinstalliere das Plugin, bevor du die Quelle wechselst.';

  @override
  String get pluginErrorRestartReplace =>
      'Dieses Plugin wurde nicht ordnungsgemäß beendet. Starte Kiosk Satellite neu, bevor du es ersetzt.';

  @override
  String get pluginErrorPluginLimit =>
      'Es können maximal 8 Plugins installiert werden';

  @override
  String get pluginErrorAlreadyInstalled =>
      'Dieses Paket ist bereits installiert';

  @override
  String get pluginErrorLoadedIntegrity =>
      'Das zuvor geladene Paket hat die Integritätsprüfung nicht bestanden. Starte Kiosk Satellite neu, bevor du es erneut installierst.';

  @override
  String get pluginErrorRemovePackage =>
      'Das ungenutzte Paket kann nicht entfernt werden';

  @override
  String get pluginErrorInstallPackage =>
      'Das Plugin-Paket kann nicht installiert werden';

  @override
  String get pluginErrorUpdateCanceled =>
      'Das Update wurde abgebrochen, da das Plugin nicht ordnungsgemäß beendet wurde. Starte Kiosk Satellite neu, bevor du es erneut versuchst.';

  @override
  String get pluginErrorVersionRetained =>
      'Die vorherige Version wurde beibehalten.';

  @override
  String get pluginErrorRetainedDisabled =>
      'Die vorherige Version wurde beibehalten, ist jedoch deaktiviert. Starte Kiosk Satellite neu, bevor du sie aktivierst.';

  @override
  String get pluginErrorVersionRunning =>
      'Die vorherige Version wird wieder ausgeführt.';

  @override
  String get pluginErrorEnablePlugins => 'Aktiviere zuerst die Plugins';

  @override
  String get pluginErrorRestartEnable =>
      'Dieses Plugin wurde nicht ordnungsgemäß beendet. Starte Kiosk Satellite neu, bevor du es aktivierst.';

  @override
  String get pluginErrorInstalledIntegrity =>
      'Das installierte Plugin hat die Integritätsprüfung nicht bestanden. Installiere es erneut.';

  @override
  String get pluginErrorAndroidOld => 'Die Android-Version ist zu alt';

  @override
  String get pluginErrorNativeIntegrity =>
      'Die installierten nativen Bibliotheken haben die Integritätsprüfung nicht bestanden';

  @override
  String get pluginErrorNativeFileIntegrity =>
      'Die installierte native Bibliothek hat die Integritätsprüfung nicht bestanden';

  @override
  String pluginErrorReadInstalled(String error) {
    return 'Das installierte Plugin konnte nicht gelesen werden: $error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return 'Die vorherige Version konnte nicht neu gestartet werden: $error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return 'Das Plugin-Update ist fehlgeschlagen: $error. $recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      'Shizuku 13 oder neuer ist erforderlich. Tippe hier, um die Einrichtungsanleitung anzuzeigen.';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      'Starte Shizuku auf diesem Gerät. Tippe hier, um die Einrichtungsanleitung anzuzeigen.';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku gewährt Kiosk Satellite Shell- oder Root-Zugriff. Installierte Plugins werden innerhalb von KS ausgeführt. Gewähre diesen Zugriff daher nur, wenn du den installierten Plugins vertraust.';

  @override
  String get pluginSetUp => 'Einrichten';

  @override
  String get pluginGrantAccess => 'Zugriff gewähren';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      'Bestätige die Berechtigungsanfrage auf dem Kiosk.';

  @override
  String get pluginErrorInvalidId => 'Die Plugin-ID ist ungültig';

  @override
  String get pluginErrorInvalidVersion => 'Die Version ist ungültig';

  @override
  String get pluginErrorEntryClass => 'Die Einstiegsklasse ist ungültig';

  @override
  String get pluginErrorManifestSchema =>
      'Das Manifest-Schema wird nicht unterstützt';

  @override
  String get pluginErrorSdkVersion =>
      'Dieses Plugin benötigt eine andere SDK-Version';

  @override
  String get pluginErrorMinimumSdk =>
      'Das Android-Mindest-SDK muss mindestens Version 24 sein';

  @override
  String get pluginErrorCapability =>
      'Die Plugin-Funktion wird nicht unterstützt';

  @override
  String get pluginErrorTooManySettings =>
      'Zu viele Einstellungen oder Befehle';

  @override
  String get pluginErrorSettingKey =>
      'Der Einstellungsschlüssel ist ungültig oder bereits vorhanden';

  @override
  String get pluginErrorGroupsArray => 'Anzeigegruppen müssen eine Liste sein';

  @override
  String get pluginErrorTooManyGroups => 'Zu viele Anzeigegruppen';

  @override
  String get pluginErrorUniqueGroups =>
      'Anzeigegruppen müssen auf eindeutige Einstellungsgruppen verweisen';

  @override
  String get pluginErrorGroupReferences => 'Zu viele Verweise in der Gruppe';

  @override
  String get pluginErrorDuplicateReference =>
      'Der Gruppenverweis ist ungültig oder doppelt vorhanden';

  @override
  String get pluginErrorCommandId =>
      'Die Befehls-ID ist ungültig oder bereits vorhanden';

  @override
  String get pluginErrorUnknownSetting =>
      'Die Plugin-Einstellung ist unbekannt';

  @override
  String get pluginErrorTextLength =>
      'Texteinstellungen dürfen maximal 512 Zeichen lang sein';

  @override
  String get pluginErrorEntityId =>
      'Es wurde eine Home-Assistant-Entitäts-ID erwartet';

  @override
  String get pluginErrorBoolean =>
      'Es wurde eine boolesche Einstellung erwartet';

  @override
  String get pluginErrorColor =>
      'Es wurde eine hexadezimale RGB-Farbe erwartet';

  @override
  String get pluginErrorNumber =>
      'Es wurde eine numerische Einstellung erwartet';

  @override
  String get pluginErrorRange =>
      'Die numerische Einstellung liegt außerhalb des zulässigen Bereichs';

  @override
  String get pluginErrorStep =>
      'Die numerische Einstellung entspricht nicht der vorgegebenen Schrittweite';

  @override
  String get pluginErrorSelection => 'Die Auswahleinstellung ist ungültig';

  @override
  String get pluginErrorSelectionOption => 'Die Auswahloption ist unbekannt';

  @override
  String get pluginErrorSettingType =>
      'Dieser Einstellungstyp wird nicht unterstützt';

  @override
  String get pluginErrorInvalidManifest => 'Das Plugin-Manifest ist ungültig';

  @override
  String pluginErrorAndroidApi(String version) {
    return 'Das Plugin benötigt Android-API $version';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return 'Das Feld $field ist ungültig';
  }

  @override
  String get remoteDisableTitle => 'Fernverwaltung deaktivieren?';

  @override
  String get remoteDisableHelp =>
      'WARNUNG: Auf diese Seite kann dann nicht mehr zugegriffen werden. Um die Fernverwaltung wieder zu aktivieren, verwende das Gerät selbst oder den Schalter für die Fernverwaltung in Home Assistant.';

  @override
  String get remoteDisableConfirm => 'Deaktivieren';

  @override
  String get remoteCopyHelp =>
      'Wähle den Schlüssel aus und kopiere ihn manuell.';

  @override
  String get remoteSaveSettingFailed =>
      'Diese Einstellung konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get remoteReconnecting => 'Verbindung wird wiederhergestellt…';

  @override
  String remoteConnectionLost(String name) {
    return 'Die Verbindung zu $name wurde unterbrochen. Diese Seite wird automatisch fortgesetzt, sobald die Verbindung wiederhergestellt ist.';
  }

  @override
  String get remoteConnectionLostUnnamed =>
      'Die Verbindung zum Kiosk wurde unterbrochen. Diese Seite wird automatisch fortgesetzt, sobald die Verbindung wiederhergestellt ist.';

  @override
  String get remoteReloadPage => 'Seite neu laden';

  @override
  String get remoteUpdated => 'Kiosk Satellite wurde aktualisiert';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return 'Das Gerät verwendet jetzt Version $version$build. Diese Seite gehört zur vorherigen Version und wird in $seconds Sek. neu geladen.';
  }

  @override
  String remoteBuild(String build) {
    return ' (Build $build)';
  }

  @override
  String get remoteReloadNow => 'Jetzt neu laden';

  @override
  String get remoteLogin => 'Anmelden';

  @override
  String get remoteInvalidPassword => 'Falsches Passwort';

  @override
  String get remoteLoginThrottled =>
      'Zu viele Anmeldeversuche. Warte 5 Minuten und versuche es erneut.';

  @override
  String get deviceScreenOffPermission =>
      'Um den Bildschirm auszuschalten, musst du einmalig eine Berechtigung erteilen. Auf dem Tablet wird aktuell die Seite zum Aktivieren der Geräteadministratorrechte angezeigt. Erteile dort die Berechtigung und versuche es anschließend erneut.';

  @override
  String get deviceAdminInactive =>
      'Die Geräteadministrator-Berechtigung ist nicht aktiv.';

  @override
  String get deviceRestartOverlay =>
      'Für einen Neustart wird die Berechtigung „Über anderen Apps anzeigen“ benötigt, damit die Anwendung anschließend wieder geöffnet werden kann. Die entsprechende Berechtigungsseite wird auf dem Gerät geöffnet. Erteile dort die Berechtigung und versuche es erneut.';

  @override
  String get deviceRebootPermission =>
      'Um das Gerät neu zu starten, muss Kiosk Satellite als Gerätebesitzer eingerichtet sein oder über eine autorisierte Shizuku-Verbindung verfügen.';

  @override
  String get deviceRestartAndroidOnly =>
      'Ein Neustart ist nur auf Android verfügbar.';

  @override
  String get deviceRestartShizukuRefused =>
      'Shizuku hat den Neustart abgelehnt';

  @override
  String deviceRestartFailed(String error) {
    return 'Neustart fehlgeschlagen: $error';
  }

  @override
  String get overviewAttention => 'Aufmerksamkeit erforderlich';

  @override
  String get overviewOpen => 'Öffnen';

  @override
  String get overviewUpdate => 'Aktualisieren';

  @override
  String overviewInvitation(String name) {
    return '$name möchte diesen Kiosk anführen';
  }

  @override
  String get overviewInvitationHelp =>
      'Bestätige die Anfrage auf dem Bildschirm des Kiosks oder unter „Flottenverwaltung“ auf diesem Gerät.';

  @override
  String get overviewOutdatedOne => '1 Follower verwendet eine andere Version';

  @override
  String overviewOutdatedMany(String count) {
    return '$count Follower verwenden andere Versionen';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names. Die Synchronisierung wartet auf Version $version.';
  }

  @override
  String get overviewThisRelease => 'diese Version';

  @override
  String get overviewUpdateAvailable => 'Update verfügbar';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version ist zur Installation bereit. Die Installation muss auf dem Bildschirm des Tablets bestätigt werden.';
  }

  @override
  String get overviewHaSetup => 'Home Assistant nicht eingerichtet';

  @override
  String get overviewHaSetupHelp =>
      'Verbinde den Kiosk mit Home Assistant, um ein Dashboard zu laden.';

  @override
  String get overviewSetUp => 'Einrichten';

  @override
  String get overviewHaNotValidated => 'Home Assistant nicht verifiziert';

  @override
  String get overviewHaNotValidatedHelp =>
      'Die URL und das Token konnten in dieser Sitzung nicht erfolgreich geprüft werden. Der Kiosk versucht die Verbindung alle 30 Sekunden erneut.';

  @override
  String get overviewOpenSetup => 'Einstellungen öffnen';

  @override
  String get overviewWakeStopped => 'Aktivierungswort-Erkennung gestoppt';

  @override
  String get overviewWakeReleased => 'Die Engine wurde beendet.';

  @override
  String get overviewOpenVoice => 'Voice Satellite öffnen';

  @override
  String get overviewOpenService => 'Dienst öffnen';

  @override
  String overviewPermissionMissing(String permission) {
    return 'Berechtigung fehlt: $permission';
  }

  @override
  String get overviewQuick => 'Schnellsteuerung';

  @override
  String get overviewReload => 'Seite neu laden';

  @override
  String get overviewScreenOn => 'Bildschirm einschalten';

  @override
  String get overviewScreenOff => 'Bildschirm ausschalten';

  @override
  String get overviewSaverStart => 'Bildschirmschoner starten';

  @override
  String get overviewSaverStop => 'Bildschirmschoner schließen';

  @override
  String get overviewCameraShow => 'Kameraansicht anzeigen';

  @override
  String get overviewCameraHide => 'Kameraansicht schließen';

  @override
  String get overviewSaverPostpone => 'Bildschirmschoner verschieben';

  @override
  String get overviewDnd => 'Nicht stören';

  @override
  String get overviewDndOn => 'Nicht stören aktiviert';

  @override
  String get overviewSnapshot => 'Schnappschuss aufnehmen';

  @override
  String get overviewCheckUpdates => 'Nach Updates suchen';

  @override
  String get overviewRestartApp => 'Anwendung neu starten';

  @override
  String get overviewRestartDevice => 'Gerät neu starten';

  @override
  String get overviewExit => 'Anwendung beenden';

  @override
  String get overviewBrightness => 'Helligkeit';

  @override
  String get overviewVolume => 'Hauptlautstärke';

  @override
  String get overviewBrightnessGrant =>
      'Die Helligkeit verwendet derzeit eine auf die Anwendung beschränkte Einstellung. Erteile die Berechtigung „Systemeinstellungen ändern“, um die tatsächliche Bildschirmhelligkeit zu steuern.';

  @override
  String get overviewRestartQuestion =>
      'Dieses Gerät neu starten? Kiosk Satellite wird nach dem Start automatisch wieder geöffnet.';

  @override
  String get overviewRestart => 'Neu starten';

  @override
  String get overviewNoSnapshot => 'Es wurde kein Schnappschuss empfangen.';

  @override
  String get overviewSnapshotTitle => 'Kamera-Schnappschuss';

  @override
  String get overviewUpdateCheckFailed =>
      'Nach Updates konnte nicht gesucht werden. Kann das Gerät auf GitHub zugreifen?';

  @override
  String get overviewLatest => 'Du verwendest die neueste Version.';

  @override
  String overviewVersionAvailable(String version) {
    return 'Version $version ist verfügbar';
  }

  @override
  String get overviewInstallAttention =>
      'Installiere sie über „Aufmerksamkeit erforderlich“.';

  @override
  String get overviewNoViewsWithCameras =>
      'Noch keine Ansicht enthält Kameras. Füge zuerst Kameras zu einer Ansicht unter „Kameras“ hinzu.';

  @override
  String get overviewShowViewFailed =>
      'Die Ansicht konnte nicht angezeigt werden';

  @override
  String get overviewAppVersion => 'App-Version';

  @override
  String get overviewNotSetup => 'Nicht eingerichtet';

  @override
  String get overviewNotValidated => 'Nicht verifiziert';

  @override
  String get overviewCheckingFilter => 'Filter wird geprüft...';

  @override
  String get overviewValidated => 'Verifiziert';

  @override
  String get overviewFilterUnavailable => 'Filterstatus nicht verfügbar';

  @override
  String get overviewUnfiltered => 'Ungefilterte Aktualisierungen';

  @override
  String get overviewWatchingOne => 'Überwacht 1 Entität';

  @override
  String overviewWatchingMany(String count) {
    return 'Überwacht $count Entitäten';
  }

  @override
  String overviewFilterDisabled(String count) {
    return 'Filter deaktiviert, die Ansicht verwendet $count Entitäten';
  }

  @override
  String get overviewWakeOff => 'Aktivierungswort-Erkennung deaktiviert';

  @override
  String overviewListeningFor(String words) {
    return 'Hört auf: $words';
  }

  @override
  String get overviewListening => 'Hört zu';

  @override
  String get overviewNotListening => 'Hört nicht zu';

  @override
  String get overviewEntitiesProxy => 'Entitäten und Bluetooth-Proxy';

  @override
  String get overviewEntitiesOnly => 'Nur Entitäten';

  @override
  String get overviewProxyOnly => 'Nur Bluetooth-Proxy';

  @override
  String get overviewWaitingHA => 'Warte auf Home Assistant';

  @override
  String get overviewNotRunning => 'Nicht ausgeführt';

  @override
  String get overviewRunningOne => 'Läuft - 1 Funktion';

  @override
  String overviewRunningMany(String count) {
    return 'Läuft - $count Funktionen';
  }

  @override
  String overviewDownloading(String version) {
    return 'Wird heruntergeladen: $version';
  }

  @override
  String overviewNewVersion(String version) {
    return 'Neue Version: $version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return 'Aktuell: $version';
  }

  @override
  String get overviewCurrent => 'Aktuell';

  @override
  String overviewPluginAttribution(String name) {
    return 'Plugin $name';
  }

  @override
  String get overviewMuted => 'Stummgeschaltet';

  @override
  String get overviewBrowser => 'Erkennung im Browser';

  @override
  String get overviewWakeWaiting =>
      'Warte auf Voice Satellite. Die Integration konfiguriert die Engine und die Aktivierungswörter, sobald dieses Gerät sein Dashboard öffnet.';

  @override
  String get overviewWakeDisabled =>
      'Die Aktivierungswort-Erkennung ist deaktiviert. Aktiviere sie, um die Modelle von Voice Satellite zu erhalten.';

  @override
  String get overviewMicBlocked =>
      'Mikrofon blockiert. Android wird die Berechtigung nicht erneut anfordern. Erteile sie in den App-Einstellungen und versuche es erneut.';

  @override
  String get overviewMicDeclined =>
      'Die Mikrofonberechtigung wurde abgelehnt. Die Aktivierungswort-Erkennung benötigt sie. Versuche es erneut, um die Berechtigung erneut anzufordern.';

  @override
  String get overviewMicLost =>
      'Das Mikrofon funktioniert nicht mehr. Versuche es erneut oder lade die Seite neu.';

  @override
  String get overviewModelsUnavailable =>
      'Die Modelle konnten nicht von Home Assistant heruntergeladen werden. Versuche es erneut, sobald Home Assistant wieder erreichbar ist.';

  @override
  String get overviewCrashed =>
      'Der Detektor ist auf diesem Gerät wiederholt abgestürzt und wurde beendet. Voice Satellite hört weiterhin über den Browser zu. Versuche es erneut oder starte die Anwendung neu.';

  @override
  String get overviewWakeFailed =>
      'Die Aktivierungswort-Engine konnte nicht gestartet werden. Versuche es erneut oder lade die Seite neu.';

  @override
  String overviewNativeUnavailable(String engine) {
    return 'Für $engine ist keine native Engine verfügbar. Voice Satellite verwendet weiterhin die Erkennung im Browser.';
  }

  @override
  String get overviewNativeListening => 'Hört mit der nativen Engine zu';

  @override
  String get overviewSuspended =>
      'Bereit (während einer Sprachinteraktion pausiert)';

  @override
  String get overviewCpu => 'CPU';

  @override
  String get overviewMemory => 'RAM';

  @override
  String get overviewTemperature => 'Temp.';

  @override
  String overviewMemoryFree(String amount) {
    return '$amount GB frei';
  }

  @override
  String overviewMetricPercent(String value) {
    return '$value %';
  }

  @override
  String overviewMetricDegrees(String value) {
    return '$value °C';
  }

  @override
  String get overviewNoScreenshot => 'Kein Bildschirmfoto verfügbar';

  @override
  String get overviewStill => 'Standbild';

  @override
  String get overviewLive => 'Live';

  @override
  String get overviewFullSize => 'Originalgröße';

  @override
  String get overviewLiveInterval => 'Live, alle 5 Sekunden';

  @override
  String overviewTaken(String age) {
    return 'Aufgenommen: $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return 'Kameraansicht: $name';
  }

  @override
  String get overviewCameraView => 'Kameraansicht';

  @override
  String get overviewScreenOffState => 'Bildschirm ausgeschaltet';

  @override
  String get overviewGoView => 'Zu einer Ansicht wechseln';

  @override
  String get overviewLoadingViews => 'Ansichten werden geladen...';

  @override
  String get overviewPickView => 'Wähle eine Dashboard-Ansicht aus...';

  @override
  String get overviewDefaultView => 'Standardansicht';

  @override
  String get overviewNoDashboards => 'Keine Dashboards gefunden';

  @override
  String get overviewViewsUnavailable => 'Ansichten nicht verfügbar';

  @override
  String get screensaverNoPhotos =>
      'Es wurden keine Fotos ausgewählt. Bitte wähle einige in den Einstellungen aus.';

  @override
  String get screensaverNoFolder =>
      'Es wurde kein Ordner ausgewählt. Bitte wähle einen in den Einstellungen aus.';

  @override
  String screensaverFolderEmpty(String folder) {
    return 'In $folder sind keine Fotos oder Videos vorhanden';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return '$folder konnte nicht gelesen werden. Wurde die Berechtigung für den Zugriff auf Medieninhalte erteilt?';
  }

  @override
  String get screensaverReadPhotosFailed =>
      'Die Fotos konnten nicht gelesen werden.';

  @override
  String get screensaverImmichNotReady =>
      'Immich ist nicht verbunden. Bitte überprüfe die Verbindung in den Einstellungen.';

  @override
  String get screensaverNoMediaMatch =>
      'Es wurden keine Medien gefunden, die den ausgewählten Quellen und Filtern entsprechen.';

  @override
  String get screensaverNoMediaSource =>
      'In der ausgewählten Quelle sind keine Medien vorhanden.';

  @override
  String get screensaverImmichUnreachable =>
      'Verbindung zum Immich-Server nicht möglich.';

  @override
  String screensaverRetryNotice(String error) {
    return '$error Es wird automatisch erneut versucht.';
  }

  @override
  String get screensaverVideosTooLarge =>
      'Alle Videos in dieser Liste sind zu groß, um auf diesem Gerät wiedergegeben zu werden.';

  @override
  String get settingLauncherEnabledTitle => 'App-Launcher aktivieren';

  @override
  String get settingLauncherEnabledDescription =>
      'Ermöglicht das Öffnen ausgewählter installierter Apps aus dem Kiosk heraus.';

  @override
  String get settingLauncherAppsDescription =>
      'Die Apps, die im Launcher angeboten werden.';

  @override
  String get settingLauncherAutoReturnTitle => 'Automatisch zurückkehren';

  @override
  String get settingLauncherAutoReturnDescription =>
      'Kehrt zum Kiosk zurück, wenn die andere App für eine gewisse Zeit nicht berührt wurde.';

  @override
  String get settingLauncherAutoReturnSecondsTitle =>
      'Zurückkehren nach (Sekunden)';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      'Zeit ohne Interaktion mit der anderen App, bevor zum Kiosk zurückgekehrt wird.';

  @override
  String get launcherOverlayHeld =>
      'Kiosk Satellite kann wieder in den Vordergrund wechseln und Berührungen in der anderen App erkennen.';

  @override
  String get launcherOverlayMissing =>
      'Ohne diese Berechtigung kann der Kiosk nicht selbstständig zurückkehren oder Berührungen in der anderen App erkennen.';

  @override
  String get launcherOverlayRemote =>
      'Ohne diese Berechtigung kann der Kiosk nicht selbstständig zurückkehren oder Berührungen in der anderen App erkennen. Die Seite zum Erteilen der Berechtigung wird auf dem Tablet angezeigt.';

  @override
  String get launcherBatteryMissing =>
      'Android kann die Anwendung pausieren, während die andere App geöffnet ist. Wenn der Timer pausiert wird, kehrt der Kiosk nicht zurück.';

  @override
  String get launcherBatteryRemote =>
      'Android kann die Anwendung pausieren, während die andere App geöffnet ist. Wenn der Timer pausiert wird, kehrt der Kiosk nicht zurück. Der Dialog zum Erteilen der Berechtigung wird auf dem Tablet angezeigt.';

  @override
  String get launcherPermissionsSearch =>
      'Die Berechtigungen, die für die Funktion „Automatisch zurückkehren“ benötigt werden.';

  @override
  String get settingCameraEnabledTitle => 'Kamera aktivieren';

  @override
  String get settingCameraEnabledDescription =>
      'Die Verwendung der Kamera erhöht die CPU-Auslastung und die Wärmeentwicklung, was die Lebensdauer von Akku und Gerät verkürzen kann.';

  @override
  String get settingCameraDeviceTitle => 'Kamera';

  @override
  String get settingCameraDeviceDescription => 'Die zu verwendende Kamera.';

  @override
  String get settingCameraSnapshotResolutionTitle =>
      'Auflösung der Schnappschüsse';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      'Eine höhere Auflösung verbessert die Bildschärfe, benötigt jedoch mehr CPU-Leistung und Bandbreite.';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle =>
      'Schnappschüsse bei Aktivitätserkennung deaktivieren';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      'Verhindert automatische Schnappschüsse durch die Erkennung. Bewegungs-, Gesichts-, Präsenz- und Gestenerkennung funktionieren weiterhin. Manuelle Anfragen und kontinuierliche Aufnahmen können weiterhin Bilder erfassen.';

  @override
  String get settingCameraSnapshotsTitle => 'Kontinuierliche Schnappschüsse';

  @override
  String get settingCameraSnapshotsDescription =>
      'Veröffentlicht in festen Intervallen einen neuen Kamera-Schnappschuss in Home Assistant.';

  @override
  String get settingCameraSnapshotIntervalTitle =>
      'Intervall zwischen Schnappschüssen';

  @override
  String get settingCameraSnapshotIntervalDescription =>
      'Sekunden zwischen den Schnappschüssen.';

  @override
  String get cameraFront => 'Vorderkamera';

  @override
  String get cameraBack => 'Rückkamera';

  @override
  String get cameraOnlyCamera => 'Die einzige Kamera dieses Geräts.';

  @override
  String get settingMotionSensorTitle => 'Bewegungssensor';

  @override
  String get settingMotionSensorDescription =>
      'Veröffentlicht Bewegungen als Home-Assistant-Sensor. WARNUNG: Die Kamera bleibt dadurch dauerhaft eingeschaltet, auch wenn der Bildschirm ausgeschaltet ist.';

  @override
  String get settingMotionSensorOffDelayTitle =>
      'Bewegungsstatus zurücksetzen nach';

  @override
  String get settingMotionSensorOffDelayDescription =>
      'Sekunden ohne Bewegung, bevor der Sensor keine Bewegung mehr meldet.';

  @override
  String get settingMotionFpsTitle => 'Bildrate für Bewegungserkennung';

  @override
  String get settingMotionFpsDescription =>
      'Bilder pro Sekunde, die von der Kamera zur Bewegungserkennung ausgewertet werden. Niedrigere Werte benötigen weniger CPU-Leistung. Ein Wert von 2 reicht aus, um zu erkennen, dass sich jemand nähert.';

  @override
  String get settingMotionStartDelayTitle => 'Startverzögerung';

  @override
  String get settingMotionStartDelayDescription =>
      'Ignoriert Bewegungen für diese Zeit nach dem Start der Kamera. Nützlich bei Geräten, deren Kamera beim Öffnen mechanisch bewegt wird.';

  @override
  String get settingMotionSensitivityTitle => 'Bewegungsempfindlichkeit';

  @override
  String get settingMotionSensitivityDescription =>
      'Höhere Werte erkennen kleinere Bewegungen. Der Wert 1 erfordert eine große Bildänderung. Der Wert 100 reagiert bereits auf die kleinste Bewegung.';

  @override
  String get cameraMotionPage => 'Bewegungssensor';

  @override
  String get cameraMotionHint =>
      'Home-Assistant-Bewegungssensor und gemeinsame Erkennungseinstellungen';

  @override
  String get cameraNoCamera => 'Keine Kamera erkannt';

  @override
  String get cameraNoCameraHelp =>
      'Dieses Gerät meldet keine verwendbare Kamera.';

  @override
  String get cameraCameraPermission => 'Kameraberechtigung fehlt';

  @override
  String get cameraCameraPermissionHelp =>
      'Ohne diese Berechtigung kann die Kamera nicht verwendet werden. Der Dialog zum Erteilen der Berechtigung wird auf dem Bildschirm des Tablets angezeigt.';

  @override
  String get cameraGrantOnDevice => 'Auf dem Gerät erteilen';

  @override
  String get cameraCameraBlocked =>
      'Blockiert. Android wird nicht erneut nachfragen. Erteile die Berechtigung in den App-Einstellungen.';

  @override
  String get cameraCameraNeeded =>
      'Ohne diese Berechtigung kann die Kamera nicht verwendet werden.';

  @override
  String get cameraAppSettings => 'App-Einstellungen';

  @override
  String get cameraLatest => 'Letzte Aufnahme';

  @override
  String get cameraNoSnapshot => 'Noch keine Aufnahmen vorhanden.';

  @override
  String get cameraImageAlt => 'Letzte Kameraaufnahme';

  @override
  String get cameraTakeSnapshot => 'Aufnahme machen';

  @override
  String get cameraSnapshotFailed =>
      'Die Aufnahme konnte nicht erstellt werden.';

  @override
  String cameraSnapshotError(String error) {
    return 'Die Aufnahme konnte nicht erstellt werden: $error';
  }

  @override
  String get cameraCameraDisabled =>
      'Die Kamera ist in den Kamera-Einstellungen deaktiviert.';

  @override
  String get cameraSnapshotBusy => 'Es läuft bereits eine Aufnahme.';

  @override
  String get cameraPermissionDenied =>
      'Die Kameraberechtigung wurde nicht erteilt.';

  @override
  String get cameraDetectionDisabled =>
      'Durch Erkennung ausgelöste Aufnahmen sind deaktiviert.';

  @override
  String get cameraNoImage => 'Die Kamera hat kein Bild zurückgegeben.';

  @override
  String get cameraTimedOut => 'Die Kamera hat nicht rechtzeitig geantwortet.';

  @override
  String get cameraBackground =>
      'Die Kamera ist nicht verfügbar, solange die Anwendung im Hintergrund läuft.';

  @override
  String get cameraJustNow => 'gerade eben';

  @override
  String cameraSecondsAgo(String count) {
    return 'vor $count Sekunden';
  }

  @override
  String get cameraMinuteAgo => 'vor 1 Minute';

  @override
  String cameraMinutesAgo(String count) {
    return 'vor $count Minuten';
  }

  @override
  String get cameraHourAgo => 'vor 1 Stunde';

  @override
  String cameraHoursAgo(String count) {
    return 'vor $count Stunden';
  }

  @override
  String get cameraDayAgo => 'vor 1 Tag';

  @override
  String cameraDaysAgo(String count) {
    return 'vor $count Tagen';
  }

  @override
  String get cameraStatusHeading => 'Streaming-Status';

  @override
  String get cameraClientsHeading => 'Verbundene Clients';

  @override
  String get cameraUnavailable => 'Nicht verfügbar';

  @override
  String get cameraStopped => 'Gestoppt';

  @override
  String get cameraStreaming => 'Streaming aktiv';

  @override
  String get cameraIdle => 'Bereit';

  @override
  String get cameraConnected => 'Verbunden';

  @override
  String get cameraChecking => 'Wird geprüft...';

  @override
  String get cameraCheckingStatus => 'Streaming-Status wird geprüft...';

  @override
  String get cameraStatusUnavailable => 'Streaming-Status nicht verfügbar.';

  @override
  String get cameraListenerStopped => 'Der Server ist gestoppt.';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count Zuschauer verbunden. Tatsächliches Video: $resolution.';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return '$count Zuschauer verbunden. Tatsächliches Video: $resolution.';
  }

  @override
  String get cameraReady =>
      'Bereit. Der Encoder startet, sobald sich ein Zuschauer verbindet.';

  @override
  String cameraFallback(String requested, String actual) {
    return '$requested wurde angefordert, die Kamera liefert jedoch $actual.';
  }

  @override
  String cameraAudioError(String error) {
    return 'Audio: $error';
  }

  @override
  String get cameraAudioPaused =>
      'Audio pausiert, während der Browser das Mikrofon verwendet.';

  @override
  String get cameraAudioStreaming => 'Mikrofon-Audio wird übertragen.';

  @override
  String get cameraAudioIdle => 'Mikrofon-Audio im Bereitschaftsmodus.';

  @override
  String cameraDiscoveryError(String error) {
    return 'ONVIF-Erkennung: $error';
  }

  @override
  String get cameraOnvifUrl => 'ONVIF-URL';

  @override
  String get cameraStreamUrl => 'Stream-URL';

  @override
  String get cameraWaitingAddress => 'Warte auf eine Netzwerkadresse';

  @override
  String get cameraClientsUnavailable =>
      'Client-Informationen nicht verfügbar.';

  @override
  String get cameraNoClients => 'Keine Clients verbunden.';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · Port $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return 'Verbunden seit $duration';
  }

  @override
  String cameraDurationSeconds(String seconds) {
    return '$seconds Sek.';
  }

  @override
  String cameraDurationMinutes(String minutes, String seconds) {
    return '$minutes Min. $seconds Sek.';
  }

  @override
  String cameraDurationHours(String hours, String minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String get cameraCredentialsMissing =>
      'Lege einen Benutzernamen und ein Passwort für den Stream fest, um die Authentifizierung zu aktivieren.';

  @override
  String get cameraPortWaiting =>
      'Warte darauf, dass der RTSP-Port verfügbar wird.';

  @override
  String get cameraListenerFailed =>
      'Der RTSP-Server konnte nicht gestartet werden.';

  @override
  String get settingCameraRtspEnabledTitle => 'Kamera-Streaming aktivieren';

  @override
  String get settingCameraRtspEnabledDescription =>
      'Teilt H.264-Video mit RTSP- oder ONVIF-Clients. Das Video wird nur kodiert, wenn mindestens ein Zuschauer verbunden ist. Hardware-Kodierung wird bevorzugt und bei Bedarf auf Software-Kodierung zurückgegriffen. Verwendet die in den Kamera-Einstellungen ausgewählte Kamera.';

  @override
  String get settingCameraStreamingProtocolTitle => 'Streaming-Protokoll';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF ermöglicht kompatiblen Clients, die Kamera zu erkennen und sich mit ihrem Stream zu verbinden.';

  @override
  String get settingCameraRtspPortTitle => 'Port';

  @override
  String get settingCameraRtspPortDescription => 'Port des RTSP-Servers.';

  @override
  String get settingCameraOnvifPortTitle => 'Port';

  @override
  String get settingCameraOnvifPortDescription => 'Port des ONVIF-Servers.';

  @override
  String get settingCameraRtspResolutionTitle => 'Auflösung';

  @override
  String get settingCameraRtspResolutionDescription =>
      'Von der ausgewählten Kamera und dem Encoder unterstützte Streaming-Größen. Das Video folgt der Ausrichtung des Geräts.';

  @override
  String get settingCameraRtspAnalysisTitle =>
      'Bewegungsanalyse während des Streamings';

  @override
  String get settingCameraRtspAnalysisDescription =>
      'Hält Bewegungs-, Gesichts- und Handgestenerkennung aktiv, während Zuschauer verbunden sind. Durch Deaktivieren können höhere Auflösungen möglich werden. Schnappschüsse verwenden dann Videobilder in der Streaming-Auflösung.';

  @override
  String get settingCameraRtspFpsTitle => 'Bildrate';

  @override
  String get settingCameraRtspFpsDescription =>
      'Gewünschte Anzahl an Videobildern pro Sekunde. Die Bewegungserkennung behält ihre eigene Analysefrequenz. Die tatsächliche Bildrate hängt von der Kamera ab.';

  @override
  String get settingCameraRtspBitrateTitle => 'Bitrate';

  @override
  String get settingCameraRtspBitrateDescription =>
      'Gewünschte Video-Bitrate. Höhere Werte verbessern die Detailqualität, benötigen jedoch mehr Bandbreite.';

  @override
  String get settingCameraRtspAudioTitle => 'Mikrofon-Audio einschließen';

  @override
  String get settingCameraRtspAudioDescription =>
      'Fügt dem Kamerastream Mikrofon-Audio hinzu. Verwendet die Mikrofoneinstellungen. WARNUNG: Erhöht die CPU-Auslastung.';

  @override
  String get settingCameraRtspAuthTitle => 'Authentifizierung erzwingen';

  @override
  String get settingCameraRtspAuthDescription =>
      'Erfordert einen Benutzernamen und ein Passwort zum Ansehen des Streams. Die Authentifizierung aktiviert keine Verschlüsselung.';

  @override
  String get settingCameraRtspUsernameTitle => 'Benutzername';

  @override
  String get settingCameraRtspUsernameDescription =>
      'Benutzername für Streaming-Clients.';

  @override
  String get settingCameraRtspPasswordTitle => 'Passwort';

  @override
  String get settingCameraRtspPasswordDescription =>
      'Legt ein Passwort für den authentifizierten Zugriff auf den Stream fest.';

  @override
  String get cameraStreamingPage => 'RTSP- und ONVIF-Streaming';

  @override
  String get cameraStreamingHint =>
      'Die Gerätekamera über RTSP oder ONVIF freigeben';

  @override
  String get cameraPortError =>
      'Bitte eine ganze Portnummer zwischen 1024 und 65535 eingeben.';

  @override
  String get cameraUsernameError =>
      'Verwende 1 bis 64 Zeichen ohne Leerzeichen, Anführungszeichen, Doppelpunkte oder Backslashes.';

  @override
  String get cameraNoSizes => 'Keine unterstützten Auflösungen verfügbar';

  @override
  String get cameraNoSizesHelp =>
      'Keine unterstützten Auflösungen verfügbar. Bitte überprüfe die Kameraverbindung.';

  @override
  String get cameraResolutionSupport => 'Unterstützte Auflösungen';

  @override
  String get cameraCheckingSizes =>
      'Kompatibilität von Kamera und H.264-Encoder wird geprüft...';

  @override
  String get cameraSupportedSizes =>
      'Es werden nur Auflösungen angezeigt, die von der Kamera und dem H.264-Encoder mit den aktuellen Streaming-Einstellungen unterstützt werden.';

  @override
  String cameraExtraSizes(String sizes) {
    return 'Deaktiviere „Bewegungsanalyse während des Streamings“, um zusätzlich $sizes verwenden zu können.';
  }

  @override
  String get cameraAnalysisOff =>
      'Bewegungs-, Gesichts- und Handgestenerkennung werden pausiert, solange Zuschauer verbunden sind. Schnappschüsse verwenden Videobilder in der Streaming-Auflösung.';

  @override
  String cameraRejectedSizes(String sizes) {
    return 'Der Encoder kann $sizes mit dieser Konfiguration nicht verwenden.';
  }

  @override
  String cameraRejectedCount(String count) {
    return '$count Kameraauflösungen wurden ausgeschlossen, da der Encoder sie mit dieser Konfiguration nicht verwenden kann.';
  }

  @override
  String get cameraCaptureRejected =>
      'Andere Kameraauflösungen sind mit den aktuellen Aufnahme-Einstellungen nicht verfügbar.';

  @override
  String get cameraOverlaysHeading => 'Einblendungen';

  @override
  String get settingCameraRtspDateTimeTitle => 'Datum und Uhrzeit anzeigen';

  @override
  String get settingCameraRtspDateTimeDescription =>
      'Zeigt Datum und Uhrzeit des Geräts in der oberen linken Ecke des Videos an, unter Verwendung des Geräte-Datumsformats sowie des 12- oder 24-Stunden-Formats.';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle =>
      'Schwarzer Hintergrund';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      'Fügt hinter Datum und Uhrzeit einen schwarzen Hintergrund ein, um die Lesbarkeit zu verbessern.';

  @override
  String get settingCameraRtspTlsTitle => 'Stream verschlüsseln';

  @override
  String get settingCameraRtspTlsDescription =>
      'Verschlüsselt Video und Audio mit TLS. Erfordert einen kompatiblen Player.';

  @override
  String get cameraStreamsNameRequired => 'Bitte einen Namen eingeben.';

  @override
  String get cameraStreamsBaseUrlRequired =>
      'Bitte eine gültige HTTP- oder HTTPS-Basis-URL eingeben.';

  @override
  String get cameraStreamsServerNotFound => 'Server nicht gefunden.';

  @override
  String get cameraStreamsInvalidStreamList =>
      'Go2RTC hat eine ungültige Stream-Liste zurückgegeben.';

  @override
  String get cameraStreamsKindRequired =>
      'Bitte einen Go2RTC-Stream, eine WHEP-URL oder eine Home-Assistant-Kamera auswählen.';

  @override
  String get cameraStreamsProtocolRequired =>
      'Bitte Automatisch, WebRTC, HLS oder MJPEG auswählen.';

  @override
  String get cameraStreamsServerRequired =>
      'Bitte einen gültigen Server auswählen.';

  @override
  String get cameraStreamsStreamRequired =>
      'Bitte den Namen des Streams eingeben.';

  @override
  String get cameraStreamsEntityRequired =>
      'Eine Entitäts-ID im Format camera.* ist erforderlich.';

  @override
  String get cameraStreamsWhepRequired =>
      'Bitte eine gültige WHEP-URL eingeben.';

  @override
  String get cameraStreamsCameraNotFound => 'Kamera nicht gefunden.';

  @override
  String get cameraStreamsListRequired =>
      'Die Kameraauswahl muss eine Liste sein.';

  @override
  String get cameraStreamsViewCount =>
      'Die Ansicht muss zwischen 1 und 12 Kameras enthalten.';

  @override
  String get cameraStreamsRepeatedCamera =>
      'Eine Kamera darf in jeder Ansicht nur einmal vorkommen.';

  @override
  String get cameraStreamsUnknownViewCamera =>
      'Die Ansicht enthält eine unbekannte Kamera.';

  @override
  String get cameraStreamsUniqueViewName =>
      'Bitte einen anderen Namen für die Ansicht verwenden.';

  @override
  String get cameraStreamsGridRange =>
      'Das Raster muss zwischen 1 und 12 Feldern umfassen.';

  @override
  String get cameraStreamsGridTooSmall =>
      'Das Raster enthält weniger Felder als Kameras.';

  @override
  String get cameraStreamsViewNotFound => 'Ansicht nicht gefunden.';

  @override
  String get cameraStreamsDefaultViewDelete =>
      'Die Standardansicht kann nicht gelöscht werden. Entferne stattdessen alle Kameras daraus, damit sie leer wird.';

  @override
  String get cameraStreamsViewEmpty => 'Die Ansicht enthält keine Kameras.';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return 'Home Assistant konnte nicht gelesen werden: $error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return 'Verbindung zu $server fehlgeschlagen: $error';
  }

  @override
  String get cameraStreamsHaUnavailable =>
      'Home Assistant ist nicht eingerichtet oder antwortet nicht.';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC hat HTTP $status zurückgegeben';
  }

  @override
  String get cameraStreamsImportHa => 'Kameras aus Home Assistant importieren';

  @override
  String get cameraStreamsImportHaHelp =>
      'Fügt alle Kameras aus Home Assistant hinzu und gibt sie über WebRTC, HLS oder MJPEG wieder. Bei einem erneuten Import werden neue Kameras ergänzt.';

  @override
  String get cameraStreamsImportFailed => 'Import fehlgeschlagen';

  @override
  String get cameraStreamsImportComplete => 'Import abgeschlossen';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return '$added hinzugefügt, $missing nicht verfügbar.';
  }

  @override
  String get settingCameraAllowH265Title => 'H.265-Streams zulassen';

  @override
  String get settingCameraAllowH265Description =>
      'Gibt H.265-Streams ohne Umwandlung wieder. Wenn das Gerät H.265 nicht dekodieren kann, wird nur ein leeres Bild angezeigt.';

  @override
  String get settingCameraPreferMseTitle => 'MSE gegenüber WebRTC bevorzugen';

  @override
  String get settingCameraPreferMseDescription =>
      'Verwendet für Go2RTC-Kameras bevorzugt MSE. Für Geräte, die WebRTC nicht wiedergeben können. Fügt ein bis zwei Sekunden Verzögerung hinzu.';

  @override
  String get settingCameraPreferHlsTitle => 'HLS gegenüber WebRTC bevorzugen';

  @override
  String get settingCameraPreferHlsDescription =>
      'Verwendet für Home-Assistant-Kameras bevorzugt HLS. Für Geräte, die WebRTC nicht wiedergeben können. Fügt einige Sekunden Verzögerung hinzu.';

  @override
  String get settingCameraSingleAudioTitle =>
      'Ton nur bei einer einzelnen Kamera wiedergeben';

  @override
  String get settingCameraSingleAudioDescription =>
      'Gibt den Kameraton wieder, wenn nur eine Kamera angezeigt wird. Rasteransichten mit mehreren Kameras bleiben stumm.';

  @override
  String get settingCameraPinchZoomTitle => 'Zwei-Finger-Zoom für Einzelkamera';

  @override
  String get settingCameraPinchZoomDescription =>
      'Vergrößert das Bild mit zwei Fingern, wenn nur eine Kamera angezeigt wird. Zum Verschieben ziehen und zum Zurücksetzen doppeltippen.';

  @override
  String get settingCameraAutoDismissSecondsTitle =>
      'Automatisch schließen nach';

  @override
  String get settingCameraAutoDismissSecondsDescription =>
      'Schließt eine geöffnete Kameraansicht automatisch. Bei 0 bleibt sie dauerhaft geöffnet. Hat keinen Einfluss auf den Kamera-Bildschirmschoner.';

  @override
  String get cameraStreamsPlayback => 'Wiedergabe';

  @override
  String get cameraStreamsOff => 'Deaktiviert';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds Sek.';
  }

  @override
  String get cameraStreamsGridHelp =>
      'Rasteransichten mit mehreren Kameras zeigen nur Video an. Auf leistungsschwachen Geräten sollten in den Ansichten Go2RTC-Streams mit niedrigerer Auflösung verwendet werden. Für die Vollbildansicht kann bei Bedarf ein anderer Stream genutzt werden.';

  @override
  String get cameraStreamsServers => 'Go2RTC-Server';

  @override
  String get cameraStreamsImportStreams => 'Streams importieren';

  @override
  String get cameraStreamsDeleteServer => 'Server löschen';

  @override
  String get cameraStreamsAddServer => 'Go2RTC-Server hinzufügen';

  @override
  String get cameraStreamsAddServerHelp =>
      'Mit einem Server verbinden und dessen Streams importieren.';

  @override
  String get cameraStreamsEditServer => 'Server bearbeiten';

  @override
  String get cameraStreamsName => 'Name';

  @override
  String get cameraStreamsBaseUrl => 'Basis-URL';

  @override
  String get cameraStreamsUsername => 'Benutzername (optional)';

  @override
  String get cameraStreamsNewPassword =>
      'Neues Passwort (leer lassen, um das aktuelle beizubehalten)';

  @override
  String get cameraStreamsPassword => 'Passwort (optional)';

  @override
  String get cameraStreamsInvalidCertificate =>
      'Ungültiges TLS-Zertifikat zulassen';

  @override
  String get cameraStreamsSaveServerFailed =>
      'Server konnte nicht gespeichert werden';

  @override
  String get cameraStreamsDeleteServerHelp =>
      'Die zugehörigen Kameras werden aus allen Ansichten entfernt.';

  @override
  String get cameraStreamsCameras => 'Kameras';

  @override
  String get cameraStreamsNoCameras => 'Keine Kameras konfiguriert';

  @override
  String get cameraStreamsNoCamerasHelp =>
      'Importiere Kameras aus Home Assistant oder Go2RTC oder füge eine manuell hinzu.';

  @override
  String get cameraStreamsDeleteCamera => 'Kamera löschen';

  @override
  String get cameraStreamsAddManually => 'Kamera manuell hinzufügen';

  @override
  String get cameraStreamsAddManuallyHelp =>
      'Verwende den Namen eines Go2RTC-Streams, eine WHEP-URL oder eine Home-Assistant-Kameraentität.';

  @override
  String get cameraStreamsUnknownCamera => 'Unbekannte Kamera';

  @override
  String get cameraStreamsUnknownServer => 'Unbekannter Server';

  @override
  String get cameraStreamsMissing => ' (nicht verfügbar)';

  @override
  String get cameraStreamsAddCamera => 'Kamera hinzufügen';

  @override
  String get cameraStreamsEditCamera => 'Kamera bearbeiten';

  @override
  String get cameraStreamsType => 'Typ';

  @override
  String get cameraStreamsGo2RtcStream => 'Go2RTC-Stream';

  @override
  String get cameraStreamsDirectWhep => 'Direkte WHEP-URL';

  @override
  String get cameraStreamsHaCamera => 'Home-Assistant-Kamera';

  @override
  String get cameraStreamsEntity => 'Kameraentität';

  @override
  String get cameraStreamsProtocol => 'Bevorzugtes Protokoll';

  @override
  String get cameraStreamsAuto => 'Automatisch';

  @override
  String get cameraStreamsServer => 'Server';

  @override
  String get cameraStreamsStreamName => 'Streamname';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Go2RTC-Streamname';

  @override
  String get cameraStreamsFullscreen => 'Vollbild-Stream (optional)';

  @override
  String get cameraStreamsWhep => 'WHEP-URL';

  @override
  String get cameraStreamsSaveCameraFailed =>
      'Die Kamera konnte nicht gespeichert werden';

  @override
  String get cameraStreamsDeleteCameraHelp =>
      'Sie wird aus allen Ansichten entfernt.';

  @override
  String get cameraStreamsLoadFailed =>
      'Die Kameras konnten nicht geladen werden.';

  @override
  String get cameraStreamsViews => 'Ansichten';

  @override
  String get cameraStreamsEmptyView => 'Noch keine Kameras vorhanden';

  @override
  String get cameraStreamsNamesShown => 'Namen sichtbar';

  @override
  String get cameraStreamsNamesHidden => 'Namen ausgeblendet';

  @override
  String get cameraStreamsShowView => 'Ansicht anzeigen';

  @override
  String get cameraStreamsDeleteView => 'Ansicht löschen';

  @override
  String get cameraStreamsCreateView => 'Kameraansicht erstellen';

  @override
  String get cameraStreamsAddFirst => 'Füge zuerst eine Kamera hinzu.';

  @override
  String get cameraStreamsChooseCameras =>
      'Wähle und ordne bis zu 12 Kameras an.';

  @override
  String get cameraStreamsShowFailed =>
      'Die Ansicht konnte nicht angezeigt werden';

  @override
  String get cameraStreamsShowFailedRemote =>
      'Die Ansicht konnte nicht angezeigt werden';

  @override
  String get cameraStreamsEditView => 'Ansicht bearbeiten';

  @override
  String get cameraStreamsShowNames => 'Kameranamen anzeigen';

  @override
  String get cameraStreamsShowNamesHelp =>
      'Zeigt eine Beschriftung über jeder Kamera an.';

  @override
  String get cameraStreamsGrid => 'Raster';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count Kamera';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return '$count Kameras';
  }

  @override
  String get cameraStreamsInView => 'In dieser Ansicht';

  @override
  String get cameraStreamsAvailable => 'Verfügbar';

  @override
  String cameraStreamsPosition(String position) {
    return 'Position $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'In Go2RTC nicht verfügbar';

  @override
  String get cameraStreamsSaveViewFailed =>
      'Die Ansicht konnte nicht gespeichert werden';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return '$name löschen?';
  }

  @override
  String get cameraStreamsCannotUndo =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get cameraStreamsShow => 'Anzeigen';

  @override
  String get cameraStreamsStop => 'Stoppen';

  @override
  String get settingAnalyticsBasicTitle => 'Basisstatistiken';

  @override
  String get settingAnalyticsBasicDescription =>
      'Geräteinformationen wie Modell, Android-Version, App-Version, Bildschirmgröße und Sprache.';

  @override
  String get settingAnalyticsUsageTitle => 'Nutzung';

  @override
  String get settingAnalyticsUsageDescription =>
      'Details darüber, wie du Kiosk Satellite verwendest.';

  @override
  String get settingAnalyticsDiagnosticsTitle => 'Diagnosedaten';

  @override
  String get settingAnalyticsDiagnosticsDescription =>
      'Teilt Absturzberichte, wenn unerwartete Fehler auftreten.';

  @override
  String get deviceAnalyticsPage => 'Kiosk-Satellite-Statistiken';

  @override
  String get deviceAnalyticsIntro =>
      'Teile anonyme Informationen über deine Installation, um Kiosk Satellite zu verbessern und dabei zu helfen, zu entscheiden, welche Geräte und Funktionen besondere Aufmerksamkeit benötigen.';

  @override
  String get deviceAnalyticsLearn => 'Wie wir deine Daten verarbeiten';

  @override
  String get deviceAnalyticsLearnHelp =>
      'Welche Daten von den Kiosk-Satellite-Statistiken gesendet werden und welche Informationen niemals übertragen werden.';

  @override
  String get deviceExportConfig => 'Konfiguration exportieren';

  @override
  String get deviceExportConfigHelp =>
      'Speichert die gesamte Konfiguration und den lokalen Seitenspeicher in einer Datei.';

  @override
  String get deviceExportConfigRemoteHelp =>
      'Lädt die gesamte Konfiguration und den lokalen Seitenspeicher herunter.';

  @override
  String get deviceImportConfig => 'Konfiguration importieren';

  @override
  String get deviceImportConfigHelp =>
      'Ersetzt die Konfiguration dieses Geräts durch die aus einer exportierten Datei.';

  @override
  String get deviceExportFailed => 'Export fehlgeschlagen';

  @override
  String get deviceExported => 'Konfiguration exportiert';

  @override
  String get deviceImportFailed => 'Import fehlgeschlagen';

  @override
  String get deviceInvalidJson => 'Die Datei enthält kein gültiges JSON.';

  @override
  String get deviceImportComplete => 'Import abgeschlossen';

  @override
  String deviceAppliedSettings(String count) {
    return '$count Konfigurationseinstellungen wurden übernommen.';
  }

  @override
  String deviceAppliedReload(String count) {
    return '$count Konfigurationseinstellungen wurden übernommen. Die Seite wird möglicherweise neu geladen.';
  }

  @override
  String get deviceReplaceOriginal => 'Ursprüngliches Gerät ersetzen';

  @override
  String get deviceReplaceQuestion =>
      'Die Konfiguration dieses Geräts durch die aus der Datei ersetzen? Die Seite wird möglicherweise neu geladen.';

  @override
  String get deviceNewDevice => 'Als neues Gerät einrichten';

  @override
  String get deviceReplaceIdentity =>
      'Behält den Namen und die ESPHome-Identität aus der Sicherung bei. Das ursprüngliche Gerät muss offline bleiben.';

  @override
  String get deviceNewIdentity =>
      'Vergibt einen eigenen Namen und eine eigene ESPHome-Identität, damit beide Geräte eindeutig sind.';

  @override
  String get deviceRestoreStorage =>
      'Lokalen WebView-Speicher wiederherstellen';

  @override
  String get deviceRestoreStorageHelp =>
      'Beinhaltet die Home-Assistant-Anmeldung und die assist_satellite-Auswahl von Voice Satellite. Zwei Geräte dürfen nicht denselben Satelliten verwenden.';

  @override
  String get deviceDownload => 'Herunterladen';

  @override
  String get deviceChooseFile => 'Datei auswählen...';

  @override
  String get deviceImportFailedSentence => 'Import fehlgeschlagen.';

  @override
  String deviceReplaceNamed(String name) {
    return '\"$name\" ersetzen';
  }

  @override
  String get settingDeviceNameTitle => 'Gerätename';

  @override
  String get settingDeviceNameDescription =>
      'Name, der in der Fernverwaltung angezeigt wird und mit dem sich das Gerät in Home Assistant identifiziert.';

  @override
  String get settingDeviceHostnameTitle => 'mDNS-Name';

  @override
  String get settingDeviceHostnameDescription =>
      'Greife über diesen Namen und den konfigurierten Port im lokalen Netzwerk auf die Fernverwaltung zu. Lass das Feld leer, um wieder den Gerätenamen zu verwenden.';

  @override
  String get settingDisableImpellerTitle => 'Legacy-Renderer';

  @override
  String get settingDisableImpellerDescription =>
      'Verwendet den Skia-Renderer für ältere GPUs, die beim Start abstürzen. Wird nach zwei solchen Fehlern automatisch aktiviert. Wird beim nächsten Start der Anwendung wirksam.';

  @override
  String get settingLegacyWebViewTitle => 'Legacy-WebView-Renderer';

  @override
  String get settingLegacyWebViewDescription =>
      'Zeichnet das Dashboard in eine Textur für ältere GPUs, die beim Anzeigen abstürzen. Wird automatisch aktiviert, wenn das Gerät dies benötigt. Wird beim nächsten Start der Anwendung wirksam.';

  @override
  String get deviceHostnamePlaceholder => 'Wird vom Gerätenamen übernommen';

  @override
  String get deviceConfiguration => 'Konfiguration';

  @override
  String get devicePermissionsManager => 'Berechtigungsverwaltung';

  @override
  String get deviceOptions => 'Optionen';

  @override
  String get deviceStatus => 'Status';

  @override
  String get deviceConnection => 'Verbindung';

  @override
  String get devicePermissions => 'Berechtigungen';

  @override
  String get deviceHelp => 'Hilfe';

  @override
  String get deviceAccess => 'Zugriff';

  @override
  String get deviceReading => 'Wird gelesen...';

  @override
  String get deviceChecking => 'Wird geprüft...';

  @override
  String get deviceUnavailable => 'Status nicht verfügbar.';

  @override
  String get deviceGrantOnDevice => 'Auf dem Gerät erteilen';

  @override
  String get deviceAppSettings => 'App-Einstellungen';

  @override
  String get deviceCopyCommand => 'Befehl kopieren';

  @override
  String get deviceOpenGuide => 'Anleitung öffnen';

  @override
  String get deviceNotSet => 'Nicht festgelegt';

  @override
  String get deviceGranted => 'Erteilt';

  @override
  String get deviceNotGranted => 'Nicht erteilt';

  @override
  String get deviceMissing => 'Fehlt';

  @override
  String get deviceNotOffered => 'Nicht verfügbar';

  @override
  String get deviceOn => 'aktiviert';

  @override
  String get deviceOff => 'deaktiviert';

  @override
  String get deviceServiceHint =>
      'Status, aktiv gehaltene Funktionen und erforderliche Berechtigungen';

  @override
  String get deviceRemoteHintActual =>
      'Diesen Kiosk über einen Browser in deinem Netzwerk verwalten';

  @override
  String get deviceUpdatesHint => 'Wo die Anwendung nach neuen Versionen sucht';

  @override
  String get deviceShizukuHint =>
      'Verbindung, Android-Berechtigungen und Einrichtung';

  @override
  String get deviceHelperHint =>
      'Status von Updates ohne Bestätigung, Einrichtung per ADB und Anleitungen';

  @override
  String get deviceAnalyticsHint =>
      'Anonyme Informationen teilen, um Kiosk Satellite zu verbessern';

  @override
  String get deviceHardwareHint =>
      'Modell, Android-Version, Adressen, Speicher und Betriebszeit';

  @override
  String get deviceHaHint => 'Verbindung, Version und Inhalte des Kiosks';

  @override
  String get deviceWebViewHint => 'Engine-Version, Renderer und User Agent';

  @override
  String get devicePasswordSet => '•••••• (gesetzt)';

  @override
  String get deviceSaveFailed =>
      'Diese Einstellung konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get deviceOpenSettingsDevice => 'Einstellungen auf dem Gerät öffnen';

  @override
  String get deviceHardwarePage => 'Hardware';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => 'Gerätemodell';

  @override
  String get deviceAndroidVersion => 'Android-Version';

  @override
  String get deviceAndroidBuild => 'Android-Build';

  @override
  String get deviceIpv4 => 'IPv4-Adresse';

  @override
  String get deviceIpv6 => 'IPv6-Adressen';

  @override
  String get deviceAppUptime => 'App-Laufzeit';

  @override
  String get deviceNetworkUptime => 'Netzwerk-Laufzeit';

  @override
  String get deviceCpuUsage => 'CPU-Auslastung';

  @override
  String get deviceCpuTemp => 'CPU-Temperatur';

  @override
  String get deviceBatteryLevel => 'Akkustand';

  @override
  String get deviceScreenBrightness => 'Bildschirmhelligkeit';

  @override
  String get deviceScreenStatus => 'Bildschirmstatus';

  @override
  String get deviceScreenSize => 'Bildschirmgröße';

  @override
  String get deviceRam => 'RAM (frei/gesamt)';

  @override
  String get deviceStorage => 'Interner Speicher (frei/gesamt)';

  @override
  String get deviceHaUrl => 'Home-Assistant-URL';

  @override
  String get deviceWakeDetection => 'Aktivierungswort-Erkennung';

  @override
  String get deviceWakeStatus => 'Status der Aktivierungswort-Erkennung';

  @override
  String get deviceEngine => 'Engine';

  @override
  String get deviceWakeWords => 'Aktivierungswörter';

  @override
  String get deviceStopWord => 'Stoppwort';

  @override
  String get deviceMotionDetection => 'Bewegungserkennung';

  @override
  String get deviceFaceDetection => 'Gesichtserkennung';

  @override
  String get deviceProvider => 'Anbieter';

  @override
  String get deviceVersion => 'Version';

  @override
  String get deviceUserAgent => 'User Agent';

  @override
  String get devicePlugged => 'angeschlossen';

  @override
  String get deviceLowMemory => 'niedrig';

  @override
  String get deviceRequiredPermissions => 'Erforderliche Systemberechtigungen';

  @override
  String get devicePermissionIntro =>
      'Berechtigungen werden auf diesem Gerät erteilt. Jede Schaltfläche öffnet hier einen Android-Dialog oder eine Einstellungsseite. Einige Hersteller verwenden eigene Akku- oder Autostart-Verwaltungen, die von Android nicht abgefragt werden können.';

  @override
  String get devicePermissionIntroRemote =>
      'Berechtigungen werden auf dem Gerät erteilt. Jede Schaltfläche öffnet dort einen Android-Dialog oder eine Einstellungsseite. Einige Hersteller verwenden eigene Akku- oder Autostart-Verwaltungen, die von Android nicht abgefragt werden können.';

  @override
  String get deviceMicrophone => 'Mikrofon';

  @override
  String get deviceMicrophoneHeld =>
      'Ermöglicht die Nutzung des Mikrofons für die Aktivierungswort-Erkennung, Sprache-zu-Text und Intercom-Anrufe.';

  @override
  String get deviceBattery => 'Akku ohne Einschränkungen';

  @override
  String get deviceBatteryHeld =>
      'Erlaubt dem Prozess, im Hintergrund zu laufen, ohne pausiert oder beendet zu werden.';

  @override
  String get deviceCamera => 'Kamera';

  @override
  String get deviceCameraHeld =>
      'Bewegungserkennung und Schnappschüsse können die Kamera verwenden.';

  @override
  String get deviceBluetooth => 'Geräte in der Nähe';

  @override
  String get deviceBluetoothHeld =>
      'Der Bluetooth-Proxy kann nach Geräten in der Nähe suchen.';

  @override
  String get deviceNotifications => 'Benachrichtigungen';

  @override
  String get deviceNotificationsHeld =>
      'Erlaubt die permanente Benachrichtigung des Kiosk-Satellite-Dienstes, die anzeigt, welche Funktionen aktiv gehalten werden.';

  @override
  String get deviceOverlay => 'Über anderen Apps anzeigen';

  @override
  String get deviceOverlayHeld =>
      'Kiosk Satellite kann wieder in den Vordergrund wechseln.';

  @override
  String get deviceWriteSettings => 'Systemeinstellungen ändern';

  @override
  String get deviceWriteSettingsHeld =>
      'Helligkeitsänderungen passen die tatsächliche Bildschirmhelligkeit an.';

  @override
  String get deviceUiGuard => 'Schutz der Systemoberfläche';

  @override
  String get deviceUiGuardHeld =>
      'Die Benachrichtigungsleiste und die Übersicht der zuletzt verwendeten Apps werden automatisch geschlossen, während der Bildschirm geschützt ist.';

  @override
  String get deviceDeviceAdmin => 'Geräteadministrator';

  @override
  String get deviceDeviceAdminHeld =>
      'Erlaubt der Anwendung, den Bildschirm auszuschalten.';

  @override
  String get deviceAllFiles => 'Zugriff auf alle Dateien';

  @override
  String get deviceAllFilesHeld =>
      'Der Dateimanager kann auf den gemeinsamen Speicher zugreifen.';

  @override
  String get deviceUsageAccess => 'Nutzungszugriff';

  @override
  String get deviceUsageAccessHeld =>
      'Der Sensor für die Vordergrund-App kann erkennen, welche Anwendung aktuell angezeigt wird.';

  @override
  String get deviceLocation => 'Standort';

  @override
  String get deviceLocationHeld =>
      'Seiten, Bluetooth-Suche und Standortsensoren können den Gerätestandort nutzen.';

  @override
  String get deviceMicBlocked =>
      'Blockiert. Android wird nicht erneut nachfragen. Erteile die Berechtigung in den App-Einstellungen.';

  @override
  String get deviceMicMissing =>
      'Die Aktivierungswort-Erkennung ist aktiviert, aber nichts hört zu.';

  @override
  String get deviceMicIdle =>
      'Erforderlich für die Aktivierungswort-Erkennung, das Intercom und Seiten, die das Mikrofon benötigen.';

  @override
  String get deviceBatteryMissing =>
      'Android kann die Anwendung bei ausgeschaltetem Bildschirm pausieren, wodurch die Verbindung zu Home Assistant und ESPHome-Entitäten unterbrochen werden kann.';

  @override
  String get deviceCameraMissing =>
      'Die Kamera ist aktiviert, kann jedoch nicht geöffnet werden.';

  @override
  String get deviceCameraIdle =>
      'Erforderlich für Bewegungserkennung, Schnappschüsse und Seiten, die die Kamera benötigen.';

  @override
  String get deviceBluetoothMissing =>
      'Der Bluetooth-Proxy ist aktiviert, kann aber nicht nach Geräten suchen.';

  @override
  String get deviceBluetoothLocation =>
      'Die Bluetooth-Suche benötigt die Standortberechtigung.';

  @override
  String get deviceBluetoothLocationOff =>
      'Der Standortdienst ist in den Geräteeinstellungen deaktiviert, daher findet die Bluetooth-Suche keine Geräte.';

  @override
  String get deviceBluetoothIdle =>
      'Erforderlich, damit der Bluetooth-Proxy nach Geräten suchen kann.';

  @override
  String get deviceNotificationMissing =>
      'Erforderlich, um die permanente Benachrichtigung des Kiosk-Satellite-Dienstes anzuzeigen.';

  @override
  String get deviceOverlayMissing =>
      'Ohne diese Berechtigung kann die Anwendung nach einem Absturz, einem Update oder einem erkannten Aktivierungswort nicht wieder geöffnet werden, wenn eine andere App im Vordergrund ist.';

  @override
  String get deviceOverlayIdle =>
      'Erlaubt der Anwendung, wieder in den Vordergrund zu wechseln, und ermöglicht, dass der Sperrschutz den gesamten Bildschirm abdeckt.';

  @override
  String get deviceBrightnessMissing =>
      'Die Helligkeit dimmt nur das Anwendungsfenster. Bildschirm und Home Assistant erhalten die Änderung nicht.';

  @override
  String get deviceBrightnessIdle =>
      'Erforderlich, um die tatsächliche Bildschirmhelligkeit anzupassen, statt nur das App-Fenster zu dimmen.';

  @override
  String get deviceGuardMissing =>
      'Die Benachrichtigungsleiste und die Übersicht der zuletzt verwendeten Apps bleiben zugänglich. Aktiviere Kiosk Satellite unter Bedienungshilfen.';

  @override
  String get deviceGuardIdle =>
      'Schließt die Benachrichtigungsleiste und die Übersicht der zuletzt verwendeten Apps, während der Kioskmodus den Bildschirm schützt.';

  @override
  String get deviceAdminIdle =>
      'Erlaubt der Funktion „Bildschirm ausschalten“, den Bildschirm tatsächlich auszuschalten, statt ihn nur schwarz darzustellen.';

  @override
  String get deviceFilesIdle =>
      'Erlaubt dem Dateimanager den Zugriff auf den gemeinsamen Speicher und nicht nur auf den Anwendungsordner.';

  @override
  String get deviceUsageIdle =>
      'Erlaubt dem Sensor für die Vordergrund-App, auch andere Anwendungen als Kiosk Satellite zu erkennen.';

  @override
  String get deviceLocationMissing =>
      'Android liefert ohne Standortberechtigung keine Bluetooth-Suchergebnisse, und Standortsensoren können den GPS-Empfänger nicht auslesen.';

  @override
  String get deviceLocationIdle =>
      'Wird von Seiten verwendet, die deinen Standort anfordern, von der Bluetooth-Suche und von ESPHome-Standortsensoren.';

  @override
  String get deviceServiceOverlayMissing =>
      'Ohne diese Berechtigung kann der Dienst den Kiosk nach einem Absturz oder dem Schließen über die zuletzt verwendeten Apps nicht erneut starten.';

  @override
  String get deviceServiceOverlayIdle =>
      'Erforderlich, um den Kiosk nach einem Absturz erneut zu öffnen.';

  @override
  String get deviceListeningMissing =>
      'Hintergrundabhören ist aktiviert, aber nichts hört zu.';

  @override
  String get deviceListeningIdle => 'Erforderlich für das Hintergrundabhören.';

  @override
  String get deviceMotionIdle => 'Erforderlich für die Bewegungserkennung.';

  @override
  String get deviceBatteryAdb =>
      'Dieses Gerät bietet keine Einstellungsseite für diese Berechtigung. Erteile sie per ADB: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      'Dieses Gerät bietet keine Einstellungsseite für diese Berechtigung. Erteile sie per ADB: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get settingRemoteEnabledTitle => 'Fernverwaltung';

  @override
  String get settingRemoteEnabledDescription =>
      'Aktiviert den integrierten Webserver zur Verwaltung des Geräts.';

  @override
  String get settingRemotePortTitle => 'Server-Port';

  @override
  String get settingRemotePortDescription =>
      'Port der Fernverwaltungsoberfläche.';

  @override
  String get settingRemotePasswordTitle => 'Administrationspasswort';

  @override
  String get settingRemotePasswordDescription =>
      'Erforderlich für die Anmeldung an der Fernverwaltungsoberfläche.';

  @override
  String get settingRemoteFleetDiscoveryTitle => 'Andere Kiosks finden';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      'Macht dieses Gerät im Netzwerk sichtbar und zeigt andere Kiosks in der Fernverwaltung an, damit zwischen ihnen gewechselt werden kann.';

  @override
  String get deviceRemotePage => 'Fernverwaltung';

  @override
  String get deviceAdminAddress => 'Verwaltungsadresse';

  @override
  String get deviceAdminAddressHelp =>
      'Öffne diese Adresse in einem Browser auf deinem Computer.';

  @override
  String get deviceByName => 'Über Namen';

  @override
  String get deviceByNameHelp =>
      'Dieselbe Adresse über den Gerätenamen in Netzwerken, die .local-Namen auflösen.';

  @override
  String get devicePasswordNeeded =>
      'Lege unten ein Administrationspasswort fest, um den Server zu starten.';

  @override
  String get deviceServerStopped => 'Der Server wird nicht ausgeführt.';

  @override
  String devicePortError(String port, String error) {
    return 'Der Port $port konnte nicht geöffnet werden: $error';
  }

  @override
  String get settingRemoteTlsTitle => 'HTTPS verwenden';

  @override
  String get settingRemoteTlsDescription =>
      'Verschlüsselt die Fernverwaltung, API und WebSocket-Verbindungen. Dein Browser kann dich auffordern, das Gerätezertifikat zu akzeptieren.';

  @override
  String get settingServiceCpuAwakeTitle =>
      'CPU bei ausgeschaltetem Bildschirm aktiv halten';

  @override
  String get settingServiceCpuAwakeDescription =>
      'Verhindert, dass die CPU bei ausgeschaltetem Bildschirm in den Ruhezustand wechselt, damit Verbindungen und Timer weiterhin rechtzeitig funktionieren. Verbraucht Akku, wenn das Tablet nicht an das Stromnetz angeschlossen ist.';

  @override
  String get deviceServicePage => 'Kiosk-Satellite-Dienst';

  @override
  String get deviceKeepingRunning => 'Aktiv gehaltene Funktionen';

  @override
  String get deviceService => 'Dienst';

  @override
  String get deviceStopped => 'Gestoppt';

  @override
  String get deviceStoppedSentence => 'Gestoppt.';

  @override
  String get deviceRunning => 'Wird ausgeführt';

  @override
  String get deviceRunningSentence => 'Wird ausgeführt.';

  @override
  String get deviceRunningBackground =>
      'Wird ohne Ausnahme für Vordergrunddienste ausgeführt.';

  @override
  String get deviceServiceTypes => 'Arten von Vordergrunddiensten';

  @override
  String get deviceServiceTypesHelp =>
      'Was der Dienst Android für die aktiv gehaltenen Funktionen meldet.';

  @override
  String get deviceNoneDeclared => 'Keine deklariert.';

  @override
  String get deviceNone => 'keine';

  @override
  String get deviceCpuLock => 'CPU-Wake-Lock';

  @override
  String get deviceCpuOff =>
      'Deaktiviert: Die untenstehende Option ist ausgeschaltet.';

  @override
  String get deviceCpuHeld => 'Aktiv: Der Bildschirm ist ausgeschaltet.';

  @override
  String get deviceCpuReleased =>
      'Freigegeben, solange der Bildschirm eingeschaltet ist.';

  @override
  String get deviceNotHeld => 'Nicht aktiv.';

  @override
  String get deviceHeld => 'Aktiv';

  @override
  String get deviceReleased => 'Freigegeben';

  @override
  String get deviceWifiLock => 'WLAN-Wake-Lock';

  @override
  String get deviceWifiHeld =>
      'Aktiv: Das Funkmodul wechselt nicht in den Energiesparmodus.';

  @override
  String get deviceWifiHelp =>
      'Verhindert, dass das WLAN-Modul bei ausgeschaltetem Bildschirm in den Energiesparmodus wechselt.';

  @override
  String get deviceNotification => 'Benachrichtigung';

  @override
  String get deviceNotificationHidden =>
      'Ausgeblendet: Die App-Benachrichtigungen sind deaktiviert. Der Dienst läuft weiterhin.';

  @override
  String get deviceNotificationShown =>
      'Wird im Benachrichtigungsbereich angezeigt, solange der Dienst ausgeführt wird.';

  @override
  String get deviceHidden => 'Ausgeblendet';

  @override
  String get deviceShown => 'Sichtbar';

  @override
  String get deviceReasonHa => 'Home-Assistant-Verbindung';

  @override
  String get deviceReasonHaHelp =>
      'Hält die Dashboard-Sitzung und ihre WebSocket-Verbindung auch bei ausgeschaltetem Bildschirm aktiv.';

  @override
  String get deviceReasonListening => 'Hintergrundabhören';

  @override
  String get deviceReasonListeningHelp =>
      'Hält die Aktivierungswort-Engine und ihr Mikrofon aktiv, während andere Apps verwendet werden.';

  @override
  String get deviceReasonRtsp => 'RTSP-Mikrofon-Audio';

  @override
  String get deviceReasonRtspHelp =>
      'Hält die Mikrofonübertragung für verbundene RTSP-Clients verfügbar.';

  @override
  String get deviceReasonEspHome => 'ESPHome-Server';

  @override
  String get deviceReasonEspHomeHelp =>
      'Hält den ESPHome-API-Server für Home Assistant erreichbar.';

  @override
  String get deviceReasonRemote => 'Fernverwaltung';

  @override
  String get deviceReasonRemoteHelp =>
      'Hält den Verwaltungs-Webserver verfügbar.';

  @override
  String get deviceReasonProtections => 'Kiosk-Schutzfunktionen';

  @override
  String get deviceReasonProtectionsHelp =>
      'Öffnet den Kiosk erneut, wenn er über die zuletzt verwendeten Apps geschlossen wird oder abstürzt.';

  @override
  String get deviceReasonBluetooth => 'Bluetooth-Proxy';

  @override
  String get deviceReasonBluetoothHelp =>
      'Hält die Bluetooth-Suche aktiv, wenn die Anwendung nicht im Vordergrund ist.';

  @override
  String get deviceReasonLocation => 'Standortsensoren';

  @override
  String get deviceReasonLocationHelp =>
      'Empfängt weiterhin GPS-Positionen bei ausgeschaltetem Bildschirm oder während eine andere App im Vordergrund läuft.';

  @override
  String get deviceReasonPerson => 'Personenerkennung';

  @override
  String get deviceReasonPersonHelp =>
      'Liest den Personensensor des Geräts weiter aus, während eine andere App im Vordergrund läuft.';

  @override
  String get deviceReasonCameraHelp =>
      'Hält die Kamera nach dem Ausschalten des Bildschirms verfügbar, um Bewegungen und Gesichter zu erkennen.';

  @override
  String deviceServiceStopped(String error) {
    return 'Gestoppt: $error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return 'Wird seit $uptime ausgeführt.';
  }

  @override
  String get settingShizukuInstallUpdatesTitle =>
      'Updates über Shizuku installieren';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      'Installiert Kiosk-Satellite-Updates ohne Bestätigung auf dem Gerät. Shizuku muss laufen und autorisiert sein.';

  @override
  String get deviceShizukuAccess => 'Shizuku-Zugriff';

  @override
  String get deviceShizukuCheck => 'Verfügbarkeit wird geprüft';

  @override
  String get deviceShizukuRoot => 'Mit Root-Zugriff verbunden';

  @override
  String get deviceShizukuShell => 'Mit Shell-Zugriff verbunden';

  @override
  String get deviceShizukuGrant =>
      'Tippen, um Zugriff zu gewähren. Bestätige die Anfrage auf diesem Kiosk.';

  @override
  String get deviceShizukuGrantRemote =>
      'Gewähre Zugriff und bestätige die Anfrage auf diesem Kiosk.';

  @override
  String get deviceShizukuDenied =>
      'Autorisiere Kiosk Satellite in der Shizuku-App.';

  @override
  String get deviceShizukuUnsupported => 'Shizuku 13 oder neuer wird benötigt.';

  @override
  String get deviceShizukuStart => 'Starte Shizuku auf diesem Gerät.';

  @override
  String get deviceShizukuTest => 'Verbindung testen';

  @override
  String get deviceShizukuTestHelp =>
      'Prüft die Prozessidentität, ohne Änderungen am Gerät vorzunehmen.';

  @override
  String get deviceShizukuTestTitle => 'Verbindungstest';

  @override
  String get deviceShizukuTestFailed =>
      'Shizuku konnte den Verbindungstest nicht abschließen.';

  @override
  String get deviceShizukuAlreadyGranted =>
      'Alle Berechtigungen wurden bereits erteilt.';

  @override
  String get deviceShizukuConfirmed =>
      'Android hat die angeforderten Berechtigungen bestätigt.';

  @override
  String get deviceShizukuResults => 'Ergebnisse der Berechtigungen';

  @override
  String get deviceShizukuGrantAll => 'Alle Berechtigungen erteilen';

  @override
  String get deviceShizukuGrantAllHelp =>
      'Erteilt alle von KS verwendeten Berechtigungen, auch für derzeit deaktivierte Funktionen.';

  @override
  String get deviceShizukuSetup => 'Shizuku einrichten';

  @override
  String get deviceShizukuSetupHelp =>
      'Installations- und Startanleitung anzeigen.';

  @override
  String get deviceShizukuLifetime =>
      'Wenn Shizuku über ADB gestartet wird, muss es nach jedem Neustart des Geräts erneut gestartet werden. Shell-Zugriff gewährt keine Root-Rechte.';

  @override
  String get deviceShizukuFailed => 'Shizuku-Anfrage fehlgeschlagen';

  @override
  String get deviceShizukuApprove => 'Bestätige die Anfrage auf dem Kiosk.';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku hat einen Befehl erfolgreich mit $access-Zugriff ausgeführt.';
  }

  @override
  String get shizukuPermissionUnconfirmed =>
      'Android hat diese Berechtigung noch nicht bestätigt. Überprüfe den Berechtigungsmanager auf dem Gerät.';

  @override
  String get shizukuPermissionReadFailed =>
      'Die aktuellen Berechtigungen konnten nicht abgefragt werden. Bitte versuche es erneut.';

  @override
  String get shizukuRestartTimedOut => 'Zeitüberschreitung beim Neustartbefehl';

  @override
  String get shizukuRestartRefused => 'Android hat den Neustart abgelehnt';

  @override
  String get shizukuCommandTimedOut => 'Zeitüberschreitung beim Befehl';

  @override
  String get shizukuRequestRejected => 'Android hat die Anfrage abgelehnt';

  @override
  String get deviceDisconnectedError =>
      'Die Verbindung zum Gerät wurde getrennt';

  @override
  String get deviceResponseTimedOut =>
      'Zeitüberschreitung bei der Antwort des Geräts';

  @override
  String get deviceRequestAborted => 'Anfrage abgebrochen';

  @override
  String get shizukuActionBusy =>
      'Auf dem Gerät wird bereits eine Shizuku-Aktion ausgeführt';

  @override
  String get shizukuGrantFirst => 'Gewähre zuerst den Shizuku-Zugriff';

  @override
  String get shizukuNoResponse => 'Der Shizuku-Befehl hat nicht geantwortet';

  @override
  String get shizukuCommandFailed => 'Der Shizuku-Befehl ist fehlgeschlagen';

  @override
  String get shizukuStartRequired =>
      'Starte Shizuku 13 oder neuer und autorisiere Kiosk Satellite in Shizuku';

  @override
  String get shizukuConnectionFailed =>
      'Die Verbindung zu Shizuku ist fehlgeschlagen';

  @override
  String get shizukuHelperNotConnected =>
      'Der Shizuku-Helfer hat keine Verbindung hergestellt';

  @override
  String get shizukuHelperUnavailable =>
      'Der Shizuku-Helfer ist nicht verfügbar';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates =>
      'Verbindungsverschlüsselung und Zertifikate';

  @override
  String get tlsCertificateType => 'Zertifikatstyp';

  @override
  String get tlsImported => 'Importiert';

  @override
  String get tlsSelfSigned => 'Selbstsigniert';

  @override
  String get tlsExpires => 'Gültig bis';

  @override
  String get tlsSHA256Fingerprint => 'SHA-256-Fingerabdruck';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      'Das Zertifikat ist abgelaufen. Erneuere es oder importiere ein neues.';

  @override
  String get tlsCopyPublicCertificate => 'Öffentliches Zertifikat kopieren';

  @override
  String get tlsDownloadPublicCertificate =>
      'Öffentliches Zertifikat herunterladen';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      'Verwende dieses Zertifikat in Browsern und Streaming-Clients.';

  @override
  String get tlsRenewCertificate => 'Zertifikat erneuern';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      'Behält den aktuellen privaten Schlüssel bei und aktualisiert die Gültigkeitsdauer des Zertifikats.';

  @override
  String get tlsImportCertificate => 'Zertifikat importieren';

  @override
  String get tlsUseACertificateIssuedForThisDevice =>
      'Verwende ein für dieses Gerät ausgestelltes Zertifikat.';

  @override
  String get tlsReplaceCertificate => 'Zertifikat ersetzen';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      'Erstellt einen neuen privaten Schlüssel und ein selbstsigniertes Zertifikat.';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      'Neuen privaten Schlüssel und neues Zertifikat erstellen? Aktive verschlüsselte Verbindungen werden geschlossen. Browser können dich auffordern, das neue Zertifikat zu akzeptieren.';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      'Füge die PEM-Zertifikatskette und den zugehörigen unverschlüsselten privaten Schlüssel ein. Beide werden geprüft, bevor das aktuelle Zertifikat ersetzt wird.';

  @override
  String get tlsCertificateChainPEM => 'Zertifikatskette (PEM)';

  @override
  String get tlsPrivateKeyPEM => 'Privater Schlüssel (PEM)';

  @override
  String get tlsThisFieldIsRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get tlsReplace => 'Ersetzen';

  @override
  String get tlsRenew => 'Erneuern';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      'Aktiviere HTTPS, bevor du einen privaten Schlüssel über die Fernverwaltung importierst.';

  @override
  String get tlsCertificateOperationFailed =>
      'Zertifikatsvorgang fehlgeschlagen.';

  @override
  String get tlsChangeConnectionProtocol => 'Verbindungsprotokoll ändern';

  @override
  String get tlsConnectionProtocolHelp =>
      'Die aktuelle Fernverbindung wird geschlossen. Verbinde dich über die unten angegebene Adresse erneut. Möglicherweise musst du dich erneut anmelden.';

  @override
  String get tlsConfirm => 'Bestätigen';

  @override
  String get tlsCertificateManagement => 'Zertifikatsverwaltung';

  @override
  String get tlsServerCertificateRequired =>
      'Verwende ein Serverzertifikat, kein CA-Zertifikat.';

  @override
  String get tlsServerAuthenticationRequired =>
      'Das Zertifikat erlaubt keine Serverauthentifizierung.';

  @override
  String get tlsKeyAlgorithmRequired =>
      'Verwende einen privaten EC- oder RSA-Schlüssel.';

  @override
  String get tlsKeyMismatch =>
      'Zertifikat und privater Schlüssel passen nicht zusammen.';

  @override
  String get tlsMaterialTooLarge =>
      'Das Zertifikat oder der Schlüssel ist zu groß.';

  @override
  String get tlsPemCertificatesRequired => 'PEM-Zertifikate erwartet.';

  @override
  String get tlsCertificateMissing => 'Kein Zertifikat gefunden.';

  @override
  String get tlsUnencryptedKeyRequired =>
      'Verwende einen unverschlüsselten privaten PEM-Schlüssel.';

  @override
  String get tlsHostnameRequired =>
      'Ein Hostname oder eine IP-Adresse ist erforderlich.';

  @override
  String get tlsIssuerRenewalRequired =>
      'Importiere ein vom Aussteller erneuertes Zertifikat.';

  @override
  String get tlsStoredIdentityDamaged =>
      'Die gespeicherte TLS-Identität ist beschädigt.';

  @override
  String get tlsExpiredCertificate =>
      'Das TLS-Zertifikat ist abgelaufen. Erneuere es oder importiere ein neues.';

  @override
  String get deviceHelperPage => 'Optionaler Update-Assistent';

  @override
  String get deviceHelperStatus => 'Status des Assistenten';

  @override
  String get deviceHelperError =>
      'Der Update-Assistent konnte nicht abgefragt werden.';

  @override
  String get deviceHelperUnneeded =>
      'Android kann Updates bereits ohne Bestätigung installieren. Der Assistent wird nicht benötigt.';

  @override
  String get deviceHelperIntro =>
      'Auf diesem Gerät muss die Installation von Updates auf dem Bildschirm bestätigt werden. Mit dem optionalen Assistenten kann Kiosk Satellite Updates ohne Bildschirminteraktion installieren.';

  @override
  String get deviceHelperBusy => 'Ein Update wird installiert.';

  @override
  String get deviceHelperReady =>
      'Bereit. Updates werden ohne Bestätigung installiert.';

  @override
  String get deviceHelperUnavailable =>
      'Nicht verfügbar. Starte den Assistenten per ADB, um Updates ohne Bestätigung zu ermöglichen.';

  @override
  String get deviceHelperLifetime =>
      'Der Assistent bleibt auch nach einem Neustart oder Update der Anwendung aktiv, wird jedoch beim Neustart des Geräts beendet. Führe den Befehl auf einem Computer mit ADB erneut aus, um ihn wieder zu starten. Danach kann der Computer getrennt werden.';

  @override
  String get deviceHelperStart => 'Über ADB starten';

  @override
  String get deviceHelperGuide => 'Einrichtungsanleitung';

  @override
  String get deviceHelperGuideHelp =>
      'Zeigt die Anweisungen und Voraussetzungen für den Update-Assistenten an.';

  @override
  String get settingUpdateSourceTitle => 'Update-Quelle';

  @override
  String get settingUpdateSourceDescription =>
      'Legt fest, wo die Anwendung nach neuen Versionen sucht.';

  @override
  String get settingUpdateSourceUrlTitle => 'Repository-URL';

  @override
  String get settingUpdateSourceUrlDescription =>
      'Ordner auf einem Webserver, auf den der Kiosk zugreifen kann und der releases.json sowie die APK-Dateien der Versionen enthält.';

  @override
  String get deviceUpdatesPage => 'Updates';

  @override
  String get deviceUpdateGithub => 'GitHub-Repository';

  @override
  String get deviceUpdateCustom => 'Benutzerdefiniertes Repository';

  @override
  String get deviceUpdateGuide =>
      'Anleitung für benutzerdefinierte Repositories';

  @override
  String get deviceUpdateGuideHelp =>
      'So stellst du die Versionsdatei und APKs im eigenen Netzwerk bereit.';

  @override
  String get deviceInstallFile => 'Aus Datei installieren';

  @override
  String get deviceInstallFileHelp =>
      'Lade über die Fernverwaltung auf dieser Seite eine Kiosk-Satellite-APK von einem Computer hoch. Für Kiosks, die weder GitHub noch ein benutzerdefiniertes Repository erreichen können.';

  @override
  String get deviceInstallFileRemoteHelp =>
      'Lade von diesem Computer eine Kiosk-Satellite-APK hoch und installiere sie. Für Kiosks, die weder GitHub noch ein benutzerdefiniertes Repository erreichen können.';

  @override
  String get deviceUploadedApk => 'APK hochgeladen';

  @override
  String get deviceInstalling => 'Installation läuft...';

  @override
  String get deviceDeviceNoAnswer => 'Das Gerät hat nicht geantwortet.';

  @override
  String get deviceInstallFailed =>
      'Update fehlgeschlagen. Überprüfe die Protokolle auf dem Gerät.';

  @override
  String get deviceConfirmTablet =>
      'Bitte auf dem Tablet-Bildschirm bestätigen';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return 'Version $version (Build $build, $size MB) befindet sich auf dem Gerät und wartet auf die Installation.';
  }

  @override
  String deviceInstallVersion(String version) {
    return 'Version $version installieren';
  }

  @override
  String deviceHttpError(String code) {
    return 'Das Gerät antwortete mit HTTP $code.';
  }

  @override
  String get deviceUploadFailed => 'Die Datei konnte nicht hochgeladen werden.';

  @override
  String get deviceInstallFleet => 'In der Flotte installieren';

  @override
  String get deviceSendingFleet => 'Wird an die Flotte gesendet...';

  @override
  String get deviceSameBuild => 'Der Kiosk verwendet bereits diesen Build.';

  @override
  String get deviceInstallConfirmation =>
      'Die Installation muss auf dem Tablet-Bildschirm bestätigt werden, sofern der Kiosk Updates nicht ohne Bestätigung installieren kann.';

  @override
  String get deviceSelfLast => 'Dieser Kiosk wird zuletzt aktualisiert.';

  @override
  String get deviceUpdatingFleet => 'Flotte wird aktualisiert';

  @override
  String deviceUploading(String percent) {
    return 'Wird hochgeladen... $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return 'Die hochgeladene APK ist Version $version (Build $build, $size MB).';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'Der Kiosk verwendet Version $version (Build $build).';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return 'Wird an $name gesendet... $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return 'Installation auf $name...';
  }

  @override
  String deviceInstallingNames(String names) {
    return 'Installation auf $names.';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      'Gib die URL des Ordners ein, z. B. http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      'Gib nur die URL des Ordners an, ohne Abfrageparameter oder Fragment. Beispiel: http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy =>
      'Es läuft bereits ein Download. Warte, bis er abgeschlossen ist.';

  @override
  String get updateInstallBusy =>
      'Es läuft bereits eine Installation. Warte, bis sie abgeschlossen ist.';

  @override
  String get updateNoAvailable => 'Keine Updates verfügbar.';

  @override
  String get updateNoUploaded =>
      'Es wurde keine hochgeladene APK gefunden, die auf die Installation wartet.';

  @override
  String get updateUploadEmpty => 'Die hochgeladene Datei war leer.';

  @override
  String get updateInvalidApk => 'Die Datei ist keine Android-APK.';

  @override
  String get updateUploadedGone =>
      'Die hochgeladene APK ist nicht mehr verfügbar. Bitte lade sie erneut hoch.';

  @override
  String get updateShizukuInstallerFailed =>
      'Shizuku konnte das Update nicht installieren. Das Installationsprogramm, das eine Bestätigung anfordert, wurde nicht geöffnet.';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return 'Nicht genügend freier Speicherplatz: Die APK ist $size MB groß, für die Installation werden etwa $required MB benötigt, es sind jedoch nur $free MB frei.';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return 'Der Upload wurde nach $size MB unterbrochen: $error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return 'Der Upload wurde vorzeitig beendet: Es wurden $received von $expected MB empfangen.';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return 'Die APK gehört zu $package und nicht zu Kiosk Satellite ($expected).';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'Die APK ist Version $version (Build $build) und damit älter als die installierte Version $currentVersion (Build $currentBuild). Downgrades sind nicht erlaubt. Android würde die Installation ebenfalls verweigern.';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return 'Download fehlgeschlagen (HTTP $status).';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return 'Der Download ist stehen geblieben: Es wurden $seconds Sekunden lang keine Daten empfangen.';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return 'Update fehlgeschlagen: $error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return 'Installation fehlgeschlagen: $error';
  }

  @override
  String get updateAnotherPackage => 'anderes Paket';

  @override
  String get settingUiLanguageTitle => 'Sprache';

  @override
  String get settingUiLanguageDescription =>
      'Sprache von Kiosk Satellite und der Fernverwaltung. Home Assistant verwendet weiterhin seine eigene Sprache.';

  @override
  String get settingUiThemeTitle => 'App-Design';

  @override
  String get settingUiThemeDescription =>
      'Hell oder dunkel für die App-Oberflächen: Menü, Einstellungen und Dialoge. „System“ übernimmt die Android-Einstellung.';

  @override
  String get settingUiScaleTitle => 'Skalierung der Benutzeroberfläche';

  @override
  String get settingUiScaleDescription =>
      'Größe der App-Oberflächen: Menü, Einstellungen und Dialoge. Für Displays mit hoher Pixeldichte. Webinhalte behalten ihre eigene Größe.';

  @override
  String get deviceUserInterface => 'Benutzeroberfläche';

  @override
  String get deviceThemeDark => 'Dunkel';

  @override
  String get deviceThemeLight => 'Hell';

  @override
  String get deviceThemeSystem => 'System';

  @override
  String get settingDlnaEnabledTitle => 'DLNA-Empfänger aktivieren';

  @override
  String get settingDlnaEnabledDescription =>
      'Zeigt Bilder an und gibt Inhalte wieder, die von Home Assistant oder einer beliebigen DLNA-Anwendung gesendet werden. Das Gerät wird als Medienplayer unter dem Gerätenamen angezeigt.';

  @override
  String get settingDlnaAudioBackgroundTitle =>
      'Audio im Hintergrund wiedergeben';

  @override
  String get settingDlnaAudioBackgroundDescription =>
      'Empfangenes Audio wird wiedergegeben, ohne den Bildschirm zu belegen.';

  @override
  String get settingDlnaPortTitle => 'Server-Port';

  @override
  String get settingDlnaPortDescription =>
      'Der vom Empfänger verwendete Port wird beim Start automatisch eingetragen. Ändere ihn, um einen anderen Port zu verwenden, oder lasse das Feld leer, damit der Empfänger erneut einen Port auswählt.';

  @override
  String get settingDlnaPortPlaceholder =>
      'Wird beim Start des Empfängers festgelegt';

  @override
  String get settingEsphomeRealMacTitle => 'Reale WLAN-MAC-Adresse verwenden';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant verknüpft diesen Kiosk mit demselben Gerät, das bereits von deinen Netzwerkintegrationen erkannt wird. Wenn du diese Einstellung änderst, wird in Home Assistant ein neues ESPHome-Gerät erstellt.';

  @override
  String get settingEsphomeMacOverrideTitle =>
      'Benutzerdefinierte WLAN-MAC-Adresse verwenden';

  @override
  String get settingEsphomeMacOverrideDescription =>
      'Da die MAC-Adresse nicht ermittelt werden kann, kannst du hier eine manuell eingeben. Wenn du sie änderst, wird in Home Assistant ein neues ESPHome-Gerät erstellt.';

  @override
  String get esphomeAdvanced => 'Erweiterte Einstellungen';

  @override
  String get esphomeAdvancedHelp =>
      'Reale oder benutzerdefinierte WLAN-MAC-Adresse';

  @override
  String get esphomeMacInvalid => 'Bitte eine gültige MAC-Adresse eingeben.';

  @override
  String esphomeMacHardware(String mac) {
    return '$mac wird verwendet.';
  }

  @override
  String esphomeMacManual(String mac) {
    return '$mac wird verwendet und unten manuell eingetragen.';
  }

  @override
  String get esphomeMacUnavailable =>
      'Android erlaubt auf diesem Gerät keinen Zugriff auf die Hardware-MAC-Adresse.';

  @override
  String get settingAnnouncementsEnabledTitle => 'Durchsagen aktivieren';

  @override
  String get settingAnnouncementsEnabledDescription =>
      'Gibt Durchsagen wieder, die Home Assistant über die Aktion „announce“ sendet.';

  @override
  String get settingAnnouncementsTtsEngineTitle => 'Text-zu-Sprache-Engine';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'Die Text-zu-Sprache-Entität von Home Assistant, die die Durchsagen vorliest.';

  @override
  String get esphomeTtsFirst => 'Erste verfügbare';

  @override
  String get settingAnnouncementsChimeTitle =>
      'Vorher einen Signalton abspielen';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Spielt vor der Durchsage einen Signalton ab.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Signalton';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Wird mit der Benachrichtigungslautstärke wiedergegeben.';

  @override
  String get esphomeAnnouncements => 'Durchsagen';

  @override
  String get esphomeAnnouncementsHelp => 'Sprachdurchsagen von Home Assistant';

  @override
  String get esphomeChime => 'Signalton';

  @override
  String get esphomeTtsUnavailable =>
      'Verbindung zu Home Assistant konnte nicht hergestellt werden';

  @override
  String get settingBtproxyEnabledTitle => 'Bluetooth-Proxy aktivieren';

  @override
  String get settingBtproxyEnabledDescription =>
      'Verbindet Bluetooth-Geräte in der Nähe über diesen Kiosk mit Home Assistant.';

  @override
  String get settingBtproxyScanDutyTitle => 'Scan-Intensität';

  @override
  String get settingBtproxyScanDutyDescription =>
      'Legt fest, wie lange das Funkmodul lauscht. Eine geringere Intensität reduziert die CPU-Auslastung. Geräte, die selten senden, benötigen länger, bis sie erscheinen.';

  @override
  String get settingBtproxyConnectionsTitle =>
      'Verbindungen zu Geräten zulassen';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant kann über diesen Proxy Verbindungen zu Bluetooth-Geräten herstellen.';

  @override
  String get settingBtproxyMacLookupTitle =>
      'Gerätehersteller online ermitteln';

  @override
  String get settingBtproxyMacLookupDescription =>
      'Identifiziert unbekannte Geräte in der Nähe anhand des Präfixes ihrer Hardwareadresse über api.macvendors.com. Es wird nur das 3-Byte-Herstellerpräfix übertragen, einmal pro Hersteller. Keine weiteren Daten verlassen das Gerät.';

  @override
  String get settingBtproxyNearbySortTitle => 'Sortieren nach';

  @override
  String get settingBtproxyNearbySortDescription =>
      'Die Sortierreihenfolge der unten angezeigten Liste erkannter Geräte.';

  @override
  String get settingBtproxyMinConnectRssiTitle =>
      'Minimale Signalstärke für Verbindungen';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      'Lehnt Verbindungen zu Geräten ab, deren Signal schwächer als dieser Wert ist, damit ein näher gelegener Proxy die Verbindung übernehmen kann.';

  @override
  String get esphomeOptionContinuous => 'Kontinuierlich';

  @override
  String get esphomeOptionBalanced => 'Ausgewogen';

  @override
  String get esphomeOptionLowPower => 'Energiesparend';

  @override
  String get esphomeOptionLastSeen => 'Zuletzt erkannt';

  @override
  String get esphomeOptionName => 'Name';

  @override
  String get esphomeOptionMacAddress => 'MAC-Adresse';

  @override
  String get esphomeOptionSignalStrength => 'Signalstärke';

  @override
  String get esphomeOptionNoLimit => 'Kein Limit';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm (gleicher Raum)';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm (Reichweitengrenze)';

  @override
  String get esphomeBluetooth => 'Bluetooth-Proxy';

  @override
  String get esphomeBluetoothHelp =>
      'Verbindet Bluetooth-Geräte in der Nähe mit Home Assistant';

  @override
  String get esphomeBluetoothOff =>
      'Bluetooth ist deaktiviert. Aktiviere es, um den Proxy zu verwenden.';

  @override
  String get esphomeBluetoothUnsupported =>
      'Auf diesem Gerät nicht verfügbar: Es verfügt über kein Bluetooth.';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      'Auf diesem Gerät nicht verfügbar: Die Android-Version unterstützt Bluetooth LE nicht.';

  @override
  String get esphomeIdentityBthome => 'BTHome-Sensor';

  @override
  String get esphomeIdentityXiaomi => 'Xiaomi-Sensor';

  @override
  String get esphomeIdentityQingping => 'Qingping-Sensor';

  @override
  String get esphomeIdentityGoogleNest => 'Google-/Nest-Gerät';

  @override
  String get esphomeIdentityEddystone => 'Eddystone-Beacon';

  @override
  String get esphomeIdentityGoogleFastPair => 'Google-Fast-Pair-Gerät';

  @override
  String get esphomeIdentityAppleFindMy => 'Apple-Find-My-Gerät';

  @override
  String get esphomeIdentityExposure => 'Expositionsbenachrichtigung (Telefon)';

  @override
  String get esphomeIdentityAugustYale => 'August-/Yale-Schloss';

  @override
  String get esphomeIdentityAmazon => 'Amazon-Gerät';

  @override
  String get esphomeIdentityTile => 'Tile-Tracker';

  @override
  String get esphomeIdentityInput => 'Eingabegerät (Fernbedienung/Tastatur)';

  @override
  String get esphomeIdentityHeartRate => 'Herzfrequenzsensor';

  @override
  String get esphomeIdentityEnvironmental => 'Umweltsensor';

  @override
  String get esphomeIdentityApple => 'Apple-Gerät';

  @override
  String get esphomeIdentityWindows => 'Windows-PC';

  @override
  String get esphomeIdentitySamsung => 'Samsung-Gerät';

  @override
  String get esphomeIdentityGoogle => 'Google-Gerät';

  @override
  String get esphomeIdentityUnknown => 'Unbekanntes Gerät';

  @override
  String esphomeIdentityVendor(String vendor) {
    return '$vendor-Gerät';
  }

  @override
  String get esphomeNearby => 'Geräte in der Nähe';

  @override
  String get esphomeNearbySearch =>
      'Die Bluetooth-Geräte, die von diesem Kiosk erkannt werden, einschließlich ihrer Namen, sofern bekannt.';

  @override
  String get esphomeNearbyEmpty => 'Es wurden noch keine Geräte erkannt.';

  @override
  String get esphomeNearbyWaiting =>
      'Es wurden noch keine Geräte erkannt. Die Geräte erscheinen hier, sobald der Proxy mit dem Scannen beginnt.';

  @override
  String get esphomeRotating => '(wechselnde Adresse)';

  @override
  String esphomeNearbyCount(String count, String total) {
    return 'Es werden die ersten $count von $total angezeigt.';
  }

  @override
  String esphomeSlots(String count) {
    return 'Über diesen Proxy können gleichzeitig bis zu $count Geräte verbunden werden. Home Assistant verbindet weitere Geräte über andere Proxys.';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return 'vor $count Sek.';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return 'vor $count Min.';
  }

  @override
  String esphomeHoursAgo(String count) {
    return 'vor $count Std.';
  }

  @override
  String get settingLocationEnabledTitle => 'Standort melden';

  @override
  String get settingLocationEnabledDescription =>
      'Liest die GPS-Position aus und stellt sie in Home Assistant als Sensoren für Breiten- und Längengrad, Genauigkeit, Höhe und Geschwindigkeit bereit. Das Aktivieren oder Deaktivieren dieser Option registriert das ESPHome-Gerät erneut.';

  @override
  String get settingLocationIntervalTitle => 'Aktualisierungsintervall';

  @override
  String get settingLocationIntervalDescription =>
      'Sekunden zwischen den Standortabfragen.';

  @override
  String get esphomeGps => 'GPS-Sensor';

  @override
  String get esphomeGpsHelp =>
      'Stellt GPS-Sensordaten in Home Assistant bereit';

  @override
  String get esphomeLocationOff => 'Deaktiviert.';

  @override
  String get esphomeLocationWaiting =>
      'Warte auf die erste Positionsbestimmung. Ein Kaltstart unter freiem Himmel kann einige Minuten dauern.';

  @override
  String get esphomeCoordinates => 'Letzte Koordinaten';

  @override
  String get esphomeLocationDenied =>
      'Die Standortberechtigung wurde nicht erteilt.';

  @override
  String get esphomeLocationAbsent => 'Kein GPS-Empfänger vorhanden.';

  @override
  String esphomeLocationError(String error) {
    return 'GPS nicht verfügbar: $error';
  }

  @override
  String get esphomeLocationUnsupported =>
      'Auf diesem Gerät nicht verfügbar: Es verfügt über keinen GPS-Empfänger.';

  @override
  String get settingNotificationsTransparencyTitle => 'Transparenz';

  @override
  String get settingNotificationsTransparencyDescription =>
      'Ermöglicht es, den Bildschirm durch die Benachrichtigungskarten hindurch zu sehen. Text und Symbole bleiben dabei undurchsichtig.';

  @override
  String get settingNotificationsBlurTitle => 'Hintergrundunschärfe';

  @override
  String get settingNotificationsBlurDescription =>
      'Verwischt den Hintergrund, der durch eine transparente Benachrichtigungskarte sichtbar ist. Hinweis: Die Unschärfe kann nicht über das Home-Assistant-Dashboard angewendet werden.';

  @override
  String get settingNotificationsChimeFileTitle => 'Benachrichtigungston';

  @override
  String get settingNotificationsChimeFileDescription =>
      'Audiodateien werden aus Android/data/me.jxl.kiosk_satellite/files/sounds auf dem Gerät geladen. Auf diesen Ordner kann auch über den Dateimanager zugegriffen werden.';

  @override
  String get settingNotificationsVolumeTitle => 'Benachrichtigungslautstärke';

  @override
  String get settingNotificationsVolumeDescription =>
      'Lautstärke des Benachrichtigungstons, unabhängig von der Medien- und Assistentenlautstärke.';

  @override
  String get esphomeNotifications => 'Benachrichtigungen';

  @override
  String get esphomeNotificationsHelp =>
      'Transparenz, Unschärfe, Ton und Testbenachrichtigung';

  @override
  String get esphomeAppearance => 'Darstellung';

  @override
  String get esphomeSound => 'Ton';

  @override
  String get esphomeNotificationTest => 'Testbenachrichtigung';

  @override
  String esphomeNotificationHelp(String action) {
    return 'Benachrichtigungen werden von Home Assistant über die Aktion $action gesendet. Der Test zeigt eine Benachrichtigung über dem Dashboard an.';
  }

  @override
  String get esphomeNotificationBody =>
      'So sieht eine Benachrichtigung von Home Assistant aus und so klingt sie.';

  @override
  String get esphomeNotificationSearch =>
      'Die Home-Assistant-Aktion zum Senden von Benachrichtigungen sowie eine Schaltfläche zum Anzeigen einer Testbenachrichtigung.';

  @override
  String get esphomeLocation => 'Standort';

  @override
  String get esphomeLocationSearch =>
      'Die Standortberechtigung, die von den Standortsensoren benötigt wird.';

  @override
  String get esphomeBluetoothSearch =>
      'Die Berechtigung „Geräte in der Nähe“, die der Bluetooth-Proxy zum Scannen benötigt.';

  @override
  String get esphomeLocationMissing =>
      'Ohne diese Berechtigung kann der GPS-Empfänger nicht ausgelesen werden und die Standortsensoren erhalten keine Daten.';

  @override
  String get esphomeLocationServicesOff =>
      'Der Standortdienst ist in den Geräteeinstellungen deaktiviert, sodass der Empfänger keine Daten liefert.';

  @override
  String get esphomeLocationGranted =>
      'Die Standortsensoren können den GPS-Empfänger auslesen.';

  @override
  String get esphomeBluetoothGranted =>
      'Der Proxy kann nach Bluetooth-Geräten in der Nähe suchen.';

  @override
  String get esphomeBluetoothMissing =>
      'Ohne diese Berechtigung kann der Proxy keine Geräte suchen.';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android liefert Bluetooth-Scanergebnisse, einschließlich Beacons, nur wenn die Standortberechtigung erteilt wurde. Der Proxy liest dabei niemals den Standort des Geräts aus.';

  @override
  String get esphomeBluetoothLocationOff =>
      'Der Standortdienst ist in den Geräteeinstellungen deaktiviert, daher findet der Bluetooth-Scan keine Geräte.';

  @override
  String get esphomeBluetoothBeacons =>
      'Der Bluetooth-Scan kann Beacons erkennen.';

  @override
  String get esphomeSent => 'Gesendet';

  @override
  String get esphomeNotsaved => 'Nicht gespeichert';

  @override
  String get settingEsphomeEnabledTitle => 'ESPHome aktivieren';

  @override
  String get settingEsphomeEnabledDescription =>
      'Stellt diesen Kiosk Home Assistant als ESPHome-Gerät bereit, einschließlich seiner Sensoren und Steuerungen als native Entitäten. Die Erkennung erfolgt automatisch.';

  @override
  String get settingEsphomeEntitiesTitle => 'Kiosk-Entitäten freigeben';

  @override
  String get settingEsphomeEntitiesDescription =>
      'Stellt die Sensoren und Steuerungen dieses Geräts als ESPHome-Entitäten bereit.';

  @override
  String get settingEsphomeExcludedEntitiesTitle => 'Ausgeschlossene Entitäten';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      'Wähle die Entitäten aus, die in Home Assistant nicht angezeigt werden sollen. Alle anderen verfügbaren Entitäten werden freigegeben. Beim Speichern verbindet sich ESPHome erneut.';

  @override
  String get settingEsphomeNodeNameTitle => 'Knotenname';

  @override
  String get settingEsphomeNodeNameDescription =>
      'Identifiziert diesen Kiosk im Netzwerk. Home Assistant verwendet diesen Namen, um die Namen seiner Aktionen zu erstellen. Wenn du ihn änderst, ändern sich auch die Namen dieser Aktionen.';

  @override
  String get settingEsphomeNodeNamePlaceholder =>
      'Wird beim ersten Start festgelegt';

  @override
  String get settingBtproxyKeyTitle => 'Verschlüsselungsschlüssel';

  @override
  String get settingBtproxyKeyDescription =>
      'Füge diesen Schlüssel in Home Assistant ein, wenn nach dem Verschlüsselungsschlüssel gefragt wird. Er wird beim ersten Start automatisch erzeugt.';

  @override
  String get settingBtproxyKeyPlaceholder => 'Wird beim ersten Start erzeugt';

  @override
  String get settingBtproxyPortTitle => 'API-Port';

  @override
  String get settingBtproxyPortDescription =>
      'Der Port, mit dem sich Home Assistant verbindet. Leer lassen, um den ESPHome-Standardport 6053 zu verwenden.';

  @override
  String esphomeStartFailed(String error) {
    return 'Der ESPHome-Server konnte nicht gestartet werden: $error';
  }

  @override
  String get esphomeExcludedInvalid =>
      'Bitte eine Liste von Entitäts-IDs auswählen.';

  @override
  String settingsMadeBy(String heart, String author) {
    return 'Mit $heart erstellt von $author';
  }

  @override
  String get settingsBuyCoffee => 'Kauf mir einen Kaffee';

  @override
  String get settingClapStrictnessTitle => 'Klatscherkennung';

  @override
  String get settingClapStrictnessDescription =>
      'Der strikte Modus erfordert lautere und gleichmäßiger verteilte Klatscher. Probiere ihn aus, wenn Haushaltsgeräusche die Gesten versehentlich auslösen.';

  @override
  String get gestureStrictnessStandard => 'Standard';

  @override
  String get gestureStrictnessStrict => 'Strikt';

  @override
  String get gestureOff => 'Gesten sind deaktiviert';

  @override
  String get gestureOffHelp =>
      'Die Option „Gesten deaktivieren“ ist in den Kioskmodus-Einstellungen aktiviert.';

  @override
  String get gestureEmpty => 'Keine Gesten konfiguriert';

  @override
  String get gestureEmptyHelp =>
      'Eine Geste führt ihre Aktion ohne sichtbare Bedienelemente aus.';

  @override
  String get gestureDeleteTooltip => 'Geste löschen';

  @override
  String get gestureDeleteTitle => 'Geste löschen?';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return 'Diese Geste löschen? Geste: $trigger. Aktion: $action.';
  }

  @override
  String get gestureAdd => 'Geste hinzufügen';

  @override
  String get gestureAddHelp =>
      'Wähle eine Geste und die Aktion aus, die sie ausführen soll.';

  @override
  String get gestureTouchHelp =>
      'Gesten werden erkannt, ohne Berührungen zu blockieren. Berührungen werden weiterhin an das Dashboard weitergegeben. Die Verwendung von Ecken und mehreren Fingern hilft, Bedienelemente nicht versehentlich auszulösen.';

  @override
  String get gestureClapper => 'Klatschsteuerung';

  @override
  String get gestureReadFailed =>
      'Die Konfiguration konnte nicht gelesen werden.';

  @override
  String get gestureHandGestures => 'Handgesten';

  @override
  String get settingHandGestureHoldSecondsTitle => 'Haltedauer';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      'Halte dieselbe Fingergeste so lange, bevor die Aktion ausgeführt wird. Erhöhe die Dauer, um versehentliches Auslösen zu reduzieren.';

  @override
  String get gestureHoldInstant => 'Sofort';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get settingHaHoldModeTitle => 'Pausenmodus';

  @override
  String get settingHaHoldModeDescription =>
      'Behält die aktuelle Ansicht auf dem Bildschirm. Bildschirmschoner, Ansichtsrotation und der Timer für die Rückkehr zur Startseite bleiben pausiert, bis der Modus deaktiviert wird.';

  @override
  String get settingHaHoldReleaseMinutesTitle =>
      'Pausenmodus automatisch beenden nach';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      'Deaktiviert den Pausenmodus nach der angegebenen Zeit. Bei 0 bleibt er aktiv, bis er manuell beendet wird.';

  @override
  String get settingHaHoldMenuTitle => 'Im Kiosk-Menü anzeigen';

  @override
  String get settingHaHoldMenuDescription =>
      'Fügt dem Menü eine Option zum Aktivieren und Deaktivieren des Pausenmodus hinzu.';

  @override
  String get haHoldHint =>
      'Aktuelle Ansicht beibehalten, automatische Beendigung und Menüoption';

  @override
  String get haNever => 'Nie';

  @override
  String haMinutes(String minutes) {
    return '$minutes Min.';
  }

  @override
  String haHours(String hours) {
    return '$hours Std.';
  }

  @override
  String haHoursMinutes(String hours, String minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String get settingDisableSuspendTitle =>
      'Verbindung im Hintergrund aufrechterhalten';

  @override
  String get settingDisableSuspendDescription =>
      'Deaktiviert die Home-Assistant-Option „Verbindungen im Hintergrund anhalten“, die die Verbindung sonst einige Minuten nach dem Ausschalten des Bildschirms trennt.';

  @override
  String get settingFreezeOnScreensaverTitle =>
      'Dashboard während des Bildschirmschoners pausieren';

  @override
  String get settingFreezeOnScreensaverDescription =>
      'Stoppt das Rendern des Dashboards, solange es vom Bildschirmschoner überdeckt wird, um die CPU- und GPU-Auslastung zu reduzieren. Die Verbindung bleibt aktiv. Gilt nicht für den Dimmmodus.';

  @override
  String get settingWsFilterTitle => 'Dashboard-Aktualisierungen filtern';

  @override
  String get settingWsFilterDescription =>
      'Verarbeitet nur Aktualisierungen von Entitäten der aktuellen Ansicht, um Unterbrechungen auf leistungsschwachen Tablets zu reduzieren. Ansichten, deren Entitäten nicht ermittelt werden können, bleiben ungefiltert.';

  @override
  String get settingPauseDashboardCamerasTitle =>
      'Dashboard-Kameras während des Bildschirmschoners pausieren';

  @override
  String get settingPauseDashboardCamerasDescription =>
      'Pausiert kompatible und stummgeschaltete Kamerastreams des Home-Assistant-Dashboards, solange es vom Bildschirmschoner überdeckt wird. Sie werden nach dem Schließen wieder verbunden. Betrifft weder die Gerätekamera noch die Funktion „Kamerastreams“.';

  @override
  String get haOptimizations => 'Optimierungen';

  @override
  String get haOptimizationsHint =>
      'Hintergrundverbindung, Dashboard- und Kamerapause sowie Aktualisierungsfilter';

  @override
  String get haScanUnavailable =>
      'Analysedetails sind für die aktuelle Ansicht nicht verfügbar.';

  @override
  String get haScanDetails => 'Analyseinformationen zum Dashboard';

  @override
  String haWatchedTitle(String count) {
    return 'Überwachte Entitäten ($count)';
  }

  @override
  String get haWatched => 'Überwachte Entitäten';

  @override
  String get haEntityListUnavailable =>
      'Die Entitätenliste ist derzeit nicht verfügbar.';

  @override
  String haWatching(String count) {
    return 'In dieser Ansicht werden $count Entitäten überwacht.';
  }

  @override
  String get haNoUpdates =>
      'In der letzten Minute gab es keine Aktualisierungen.';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return '$percent% der Aktualisierungen der letzten Minute wurden gefiltert ($dropped von $total).';
  }

  @override
  String get haRawUpdates =>
      'Ein Element auf dieser Seite empfängt weiterhin alle Entitätsaktualisierungen, daher bringt die Filterung hier weniger Vorteile.';

  @override
  String get haAllStates =>
      'Diese Ansicht liest die Zustände aller Entitäten, daher werden deren Aktualisierungen nicht gefiltert.';

  @override
  String get haUnknownEntities =>
      'Die Entitäten dieser Ansicht können nicht ermittelt werden, daher werden ihre Aktualisierungen nicht gefiltert.';

  @override
  String get haWaiting => 'Warte auf das Laden des Dashboards...';

  @override
  String get haShowScan => 'Analysedetails anzeigen.';

  @override
  String haThreshold(String count) {
    return 'Diese Ansicht verwendet $count Entitäten und überschreitet damit den Filter-Schwellenwert. Die Filterung ist deaktiviert.';
  }

  @override
  String get settingHaReturnHomeEnabledTitle =>
      'Zur Startansicht des Dashboards zurückkehren';

  @override
  String get settingHaReturnHomeEnabledDescription =>
      'Kehrt nach einer bestimmten Zeit ohne Aktivität zum oben konfigurierten Dashboard zurück.';

  @override
  String get settingHaReturnHomeSecondsTitle => 'Zurückkehren nach (Sekunden)';

  @override
  String get settingHaReturnHomeSecondsDescription =>
      'Zeit ohne Aktivität, bevor der Kiosk zurückkehrt.';

  @override
  String get haReturnHint =>
      'Kehrt nach einer bestimmten Zeit ohne Aktivität zur Startansicht zurück';

  @override
  String get haReturnDisabled =>
      'Deaktiviert, solange die Dashboard-Ansichtsrotation aktiv ist.';

  @override
  String get haReturnNoPath =>
      'Das konfigurierte Dashboard besitzt keinen Ansichtspfad, zu dem zurückgekehrt werden kann.';

  @override
  String haReturnPath(String path) {
    return 'Kehrt nach Ablauf des Zeitlimits zu „$path“ zurück.';
  }

  @override
  String get settingHaRotationEnabledTitle =>
      'Dashboard-Ansichtsrotation aktivieren';

  @override
  String get settingHaRotationEnabledDescription =>
      'Durchläuft die ausgewählten Dashboard-Ansichten in einer Endlosschleife und zeigt jede Ansicht für die festgelegte Anzahl von Sekunden an.';

  @override
  String get settingHaRotationSecondsTitle => 'Sekunden pro Ansicht';

  @override
  String get settingHaRotationSecondsDescription =>
      'Wie lange jede Ansicht angezeigt wird.';

  @override
  String get settingHaRotationPauseSecondsTitle =>
      'Rotation bei Interaktion pausieren (Sekunden)';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      'Eine Bildschirmberührung pausiert die Rotation für diese Zeit. Jede weitere Berührung startet den Timer neu. Sprachinteraktionen pausieren die Rotation bis zu ihrem Ende. Bei 0 pausieren Berührungen die Rotation nicht.';

  @override
  String get settingHaRotationCrossfadeTitle =>
      'Überblendung zwischen Ansichten';

  @override
  String get settingHaRotationCrossfadeDescription =>
      'Blendet zunächst zum Hintergrund aus und anschließend die nächste Ansicht ein, anstatt sofort umzuschalten. Wechsel zu einem anderen Dashboard oder einer externen Seite erfolgen weiterhin ohne Überblendung.';

  @override
  String get settingHaRotationFadeSecondsTitle =>
      'Dauer der Überblendung (Sekunden)';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      'Gesamtdauer für Aus- und Einblenden. Das Laden der nächsten Ansicht kann zusätzliche Zeit benötigen, insbesondere beim ersten Öffnen.';

  @override
  String get haRotation => 'Dashboard-Ansichtsrotation';

  @override
  String get haRotationHint =>
      'Durchläuft Ansichten, Anzeigedauer je Ansicht und Überblendungseffekt';

  @override
  String get haDefaultView => 'Standardansicht';

  @override
  String get haExternalPages => 'Externe Seiten';

  @override
  String get haFadeError =>
      'Bitte eine Überblendungsdauer zwischen 0,2 und 5 Sekunden wählen.';

  @override
  String get haPauseRemoteHelp =>
      'Eine Bildschirmberührung pausiert die Rotation für diese Zeit. Jede weitere Berührung startet den Timer neu. Sprachinteraktionen pausieren die Rotation bis zu ihrem Ende. Bei 0 pausieren Berührungen die Rotation nicht.';

  @override
  String get settingHaUrlTitle => 'Home-Assistant-Basis-URL';

  @override
  String get settingHaUrlDescription =>
      'Zum Beispiel https://homeassistant.local:8123, ohne den Pfad zu einem Dashboard.';

  @override
  String get settingHaTokenTitle => 'Langzeit-Zugriffstoken';

  @override
  String get settingHaTokenDescription =>
      'Wird in deinem Home-Assistant-Profil unter „Sicherheit“ erstellt.';

  @override
  String get settingHaAutoLoginTitle => 'Automatisch anmelden';

  @override
  String get settingHaAutoLoginDescription =>
      'Meldet dich mit dem oben angegebenen Zugriffstoken automatisch am Dashboard an, anstatt die Home-Assistant-Anmeldeseite anzuzeigen.';

  @override
  String get haValidate => 'Validieren';

  @override
  String get haValidateConnection => 'Verbindung prüfen';

  @override
  String get haChecking => 'Wird geprüft...';

  @override
  String get haConnected => 'Verbunden';

  @override
  String get haConnectedRemote => 'Verbunden.';

  @override
  String get haNotValidated =>
      'Noch nicht validiert. Die untenstehenden Optionen werden aktiviert, sobald die Verbindung bestätigt wurde.';

  @override
  String get haConnectFailed => 'Verbindung fehlgeschlagen.';

  @override
  String get haNotConfigured =>
      'Die Home-Assistant-URL und das Zugriffstoken sind nicht konfiguriert';

  @override
  String get haInvalidToken => 'Ungültiges Token';

  @override
  String haUnreachable(String error) {
    return 'Verbindung zu Home Assistant nicht möglich: $error';
  }

  @override
  String get haProxy => 'Proxy für sicheren Kontext';

  @override
  String get haProxyHelp =>
      'Leitet die HTTP-Verbindung zu Home Assistant über einen Proxy innerhalb der Anwendung, damit der Browser Mikrofonfunktionen und andere HTTPS-exklusive Funktionen aktivieren kann. Nur für HTTP-Adressen.';

  @override
  String get haProxyRemoteHelp =>
      'Leitet die HTTP-Verbindung zu Home Assistant über einen Proxy innerhalb der Anwendung, damit der Browser Mikrofonfunktionen und andere HTTPS-exklusive Funktionen aktivieren kann. Nur für HTTP-Adressen.';

  @override
  String get haProxyNotice =>
      'Diese Home-Assistant-Adresse verwendet HTTP, und Browser blockieren Mikrofonfunktionen sowie andere Features auf HTTP-Seiten. Kiosk Satellite leitet das Dashboard über einen sicheren Proxy innerhalb der Anwendung weiter, um diese Funktionen zu aktivieren. Möglicherweise musst du dich erneut bei Home Assistant anmelden.';

  @override
  String get haProxyRemoteNotice =>
      'Diese Home-Assistant-Adresse verwendet HTTP, und Browser blockieren Mikrofonfunktionen sowie andere Features auf HTTP-Seiten. Kiosk Satellite leitet das Dashboard über einen sicheren Proxy innerhalb der Anwendung weiter, um diese Funktionen zu aktivieren. Möglicherweise musst du dich auf dem Tablet erneut bei Home Assistant anmelden.';

  @override
  String get haDashboard => 'Dashboard';

  @override
  String get haChooseView => 'Ansicht auswählen';

  @override
  String get haLoadingDashboards => 'Dashboards werden geladen...';

  @override
  String get haListFailed => 'Die Dashboards konnten nicht aufgelistet werden';

  @override
  String get haRetryHint => 'Tippen, um es erneut zu versuchen.';

  @override
  String get haChangeView => 'Ansicht wechseln';

  @override
  String get haNoViews => 'Keine Unteransichten';

  @override
  String get haNoViewsHelp =>
      'Dieses Dashboard enthält keine auswählbaren Unteransichten.';

  @override
  String get haNoDashboards => 'Keine Dashboards gefunden';

  @override
  String get settingHaThemeTitle => 'Design';

  @override
  String get settingHaThemeDescription =>
      'Helles oder dunkles Design für das Home-Assistant-Dashboard. Kann auch über die Home-Assistant-Entität „Design“ ausgewählt werden. „Automatisch“ folgt den untenstehenden Einstellungen.';

  @override
  String get settingThemeMatchAppTitle =>
      'Home-Assistant-Design mit Kiosk Satellite synchronisieren';

  @override
  String get settingThemeMatchAppDescription =>
      'Passt das Home-Assistant-Design automatisch an das Design der Kiosk-Satellite-Benutzeroberfläche an.';

  @override
  String get settingThemeAutoTitle => 'Design zeitgesteuert wechseln';

  @override
  String get settingThemeAutoDescription =>
      'Wechselt Home Assistant nach einem Zeitplan zwischen hellem und dunklem Design. Das gewählte Design bleibt erhalten, lediglich die helle bzw. dunkle Variante wird umgeschaltet.';

  @override
  String get settingThemeDarkAtTitle => 'Dunkles Design um';

  @override
  String get settingThemeDarkAtDescription =>
      'Ortszeit für den Wechsel zum dunklen Design.';

  @override
  String get settingThemeLightAtTitle => 'Helles Design um';

  @override
  String get settingThemeLightAtDescription =>
      'Ortszeit für die Rückkehr zum hellen Design.';

  @override
  String get settingThemeAutoAppTitle => 'Auch das App-Design wechseln';

  @override
  String get settingThemeAutoAppDescription =>
      'Wechselt zusätzlich das Design von Kiosk Satellite (Menü und Einstellungen) zusammen mit dem geplanten Home-Assistant-Designwechsel.';

  @override
  String get haThemeHint =>
      'Mit der App synchronisieren oder nach Zeitplan zwischen hellem und dunklem Design wechseln';

  @override
  String get haThemeAuto => 'Automatisch';

  @override
  String get settingHaKioskModeTitle => 'HA-Kioskmodus';

  @override
  String get settingHaKioskModeDescription =>
      'Blendet die Kopfzeile und die Seitenleiste von Home Assistant aus. Wird sofort angewendet.';

  @override
  String get settingHaKioskHideHeaderTitle => 'Kopfzeile ausblenden';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'Blendet die Dashboard-Symbolleiste und die Registerkarten der Ansichten aus, solange der HA-Kioskmodus aktiv ist. Lass diese Option deaktiviert, wenn du Ansichten über die Kopfzeile wechselst.';

  @override
  String get settingHaKioskHideSidebarTitle => 'Seitenleiste ausblenden';

  @override
  String get settingHaKioskHideSidebarDescription =>
      'Blendet die Navigations-Seitenleiste aus, solange der HA-Kioskmodus aktiv ist.';

  @override
  String get settingHaKioskMenuTitle => 'Im Kiosk-Menü anzeigen';

  @override
  String get settingHaKioskMenuDescription =>
      'Fügt dem Kiosk-Menü eine Option zum Aktivieren und Deaktivieren des HA-Kioskmodus hinzu.';

  @override
  String get settingHaDashboardCarouselTitle =>
      'Dashboard-Karussell aktivieren';

  @override
  String get settingHaDashboardCarouselDescription =>
      'Wische auf dem Dashboard nach links oder rechts, um die Ansicht zu wechseln. Gesten auf Schiebereglern, Karten mit Bildlauf und Karten mit Kartenmaterial bleiben davon unberührt.';

  @override
  String get settingHaCarouselOverCardsTitle =>
      'Wischgesten über Karten erfassen';

  @override
  String get settingHaCarouselOverCardsDescription =>
      'Wechselt die Ansicht auch dann, wenn die Wischgeste auf einer Karte beginnt, die selbst auf Wischgesten reagiert. Schieberegler funktionieren weiterhin normal.';

  @override
  String get settingHaHapticsTitle => 'Vibration aktivieren';

  @override
  String get settingHaHapticsDescription =>
      'Vibriert bei der Verwendung von Schaltflächen, Schaltern, Karten, Schiebereglern und Thermostatreglern. Erfordert einen Vibrationsmotor.';

  @override
  String get settingHaHapticsStrengthTitle => 'Vibrationsstärke';

  @override
  String get settingHaHapticsStrengthDescription =>
      'Wie stark die Vibration spürbar ist.';

  @override
  String get settingHaTapSoundTitle => 'Tastentöne abspielen';

  @override
  String get settingHaTapSoundDescription =>
      'Spielt den Android-Tastenton bei der Verwendung von Schaltflächen, Schaltern, Karten, Schiebereglern und Thermostatreglern ab.';

  @override
  String get settingHaTapSoundVolumeTitle => 'Lautstärke der Tastentöne';

  @override
  String get settingHaTapSoundVolumeDescription =>
      'Wie laut jeder Tastenton abgespielt wird.';

  @override
  String get haUserInterface => 'Benutzeroberfläche';

  @override
  String get haInterfaceHint =>
      'Kioskmodus, Dashboard-Karussell, Vibration und Tastentöne';

  @override
  String get haHaptics => 'Vibration und Töne';

  @override
  String get haVibrationLight => 'Leicht';

  @override
  String get haVibrationMedium => 'Mittel';

  @override
  String get haVibrationStrong => 'Stark';

  @override
  String get settingHomeLauncherEnabledTitle => 'Als Startbildschirm verwenden';

  @override
  String get settingHomeLauncherEnabledDescription =>
      'Registriert Kiosk Satellite als Startbildschirm des Geräts. Der Kiosk wird beim Einschalten automatisch geöffnet und jede Betätigung der Home-Taste führt zurück zum Kiosk. Bei wiederholten Startfehlern wird die Funktion deaktiviert und der vorherige Launcher wiederhergestellt.';

  @override
  String get settingHomeKeepPinningTitle => 'Bildschirmfixierung beibehalten';

  @override
  String get settingHomeKeepPinningDescription =>
      'Hält die Bildschirmfixierung aktiv, auch wenn Kiosk Satellite als Startbildschirm verwendet wird. Sperrt die Tasten „Zuletzt verwendete Apps“ und „Zurück“ auf Systemebene, zeigt jedoch auf Geräten, bei denen die Anwendung nicht Gerätebesitzer ist, erneut die Bestätigung für die Bildschirmfixierung an.';

  @override
  String get kioskHomeScreen => 'Startbildschirm';

  @override
  String get kioskCheckingDevice => 'Gerät wird überprüft...';

  @override
  String get kioskFireOs =>
      'Fire OS erlaubt nicht, den Standard-Launcher zu ersetzen.';

  @override
  String get kioskUnsupported =>
      'Auf diesem Gerät kann der Startbildschirm nicht geändert werden.';

  @override
  String get kioskRecovered =>
      'Wurde nach mehreren Startfehlern automatisch deaktiviert und der vorherige Launcher wurde wiederhergestellt. Aktiviere den Schalter erneut, um es noch einmal zu versuchen.';

  @override
  String get kioskHeld =>
      'Kiosk Satellite ist der Startbildschirm. Der Kiosk wird beim Einschalten des Geräts geöffnet und jede Betätigung der Home-Taste führt zu ihm zurück.';

  @override
  String get kioskDisabled =>
      'Nicht als Startbildschirm eingerichtet. Aktiviere oben „Als Startbildschirm verwenden“.';

  @override
  String get kioskWaiting =>
      'Noch nicht als aktueller Startbildschirm festgelegt. Das Gerät wartet auf eine Bestätigung.';

  @override
  String get kioskOpenHomeSettings => 'Startbildschirm-Einstellungen öffnen';

  @override
  String get kioskSetDefault => 'Als Standard festlegen';

  @override
  String get kioskActive => 'Aktiv';

  @override
  String get kioskNotHome => 'Nicht der Startbildschirm.';

  @override
  String get kioskWaitingRemote =>
      'Warte auf Bestätigung am Gerät. Dort wird der Systemdialog oder die Startbildschirm-Einstellung geöffnet.';

  @override
  String get kioskSetDevice => 'Auf dem Gerät einrichten';

  @override
  String get settingIntercomAnswerModeTitle => 'Anrufmodus';

  @override
  String get settingIntercomAnswerModeDescription =>
      'Klingeln erfordert eine Annahme auf dem Bildschirm. Automatisch annehmen öffnet den Anruf nach einem Signalton.';

  @override
  String get settingIntercomRingSecondsTitle => 'Klingeldauer';

  @override
  String get settingIntercomRingSecondsDescription =>
      'Wie lange ein Anruf klingelt, bevor er als verpasst markiert wird.';

  @override
  String get settingIntercomRingSoundTitle => 'Klingelton';

  @override
  String get settingIntercomRingSoundDescription =>
      'Wird mit der Benachrichtigungslautstärke wiedergegeben.';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => 'Durchsagen annehmen';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      'Gibt Durchsagen wieder, die von anderen Kiosks an alle gesendet werden.';

  @override
  String get intercomOptionAnswerRing => 'Klingeln';

  @override
  String get intercomOptionAnswerAuto => 'Automatisch annehmen';

  @override
  String get intercomOptionAnswerDnd => 'Nicht stören';

  @override
  String get intercomOptionAnswer15 => '15 Sekunden';

  @override
  String get intercomOptionAnswer30 => '30 Sekunden';

  @override
  String get intercomOptionAnswer45 => '45 Sekunden';

  @override
  String get intercomOptionAnswer60 => '60 Sekunden';

  @override
  String get intercomAnswerSection => 'Anrufannahme';

  @override
  String get settingIntercomEnabledTitle => 'Gegensprechanlage aktivieren';

  @override
  String get settingIntercomEnabledDescription =>
      'Rufe andere Kiosks in diesem Netzwerk an und empfange deren Anrufe.';

  @override
  String get settingIntercomKeyTitle => 'Intercom-Schlüssel';

  @override
  String get settingIntercomKeyDescription =>
      'Kiosks mit demselben Schlüssel können miteinander kommunizieren. Die Flottenverwaltung kann diesen Schlüssel synchronisieren.';

  @override
  String get settingIntercomKeyPlaceholder =>
      'Wird beim Aktivieren der Gegensprechanlage erstellt';

  @override
  String get settingIntercomMenuTitle => 'Im Kiosk-Menü anzeigen';

  @override
  String get settingIntercomMenuDescription =>
      'Fügt dem Kiosk-Menü den Eintrag „Gegensprechanlage“ hinzu.';

  @override
  String get intercomNeedsAdmin =>
      'Die Gegensprechanlage benötigt die Fernverwaltung';

  @override
  String get intercomAdminHelp =>
      'Kiosks finden und verbinden sich darüber. Aktiviere unter „Gerät“ die Optionen „Fernverwaltung“ und „Andere Kiosks finden“ und kehre anschließend hierher zurück.';

  @override
  String get intercomChangeKey => 'Schlüssel ändern';

  @override
  String get intercomChangeKeyHelp =>
      'Füge den Schlüssel eines anderen Kiosks ein oder erstelle einen neuen.';

  @override
  String get intercomChange => 'Ändern';

  @override
  String get intercomKeyWarning =>
      'Kiosks mit diesem Schlüssel können miteinander kommunizieren. Ein neuer Schlüssel trennt diesen Kiosk von den anderen, bis diese ebenfalls den neuen Schlüssel verwenden.';

  @override
  String get intercomRegenerate => 'Neu generieren';

  @override
  String get intercomKeyChanged => 'Schlüssel geändert';

  @override
  String get intercomNotSet => 'Nicht eingerichtet';

  @override
  String get intercomOpen => 'Öffnen';

  @override
  String get settingIntercomTlsTitle => 'Kommunikation verschlüsseln';

  @override
  String get settingIntercomTlsDescription =>
      'Verschlüsselt Gegensprechanrufe zwischen Kiosken mit TLS. Diese Option muss auf allen Kiosken im Anruf aktiviert sein.';

  @override
  String get intercomKiosks => 'Kiosks';

  @override
  String get intercomRosterHelp =>
      'Erkannte Kioske und gespeicherte Flottenmitglieder. Ein Kiosk ist bereit, wenn er erreichbar ist, die Gegensprechanlage aktiviert ist und Schlüssel sowie Verschlüsselungseinstellungen übereinstimmen.';

  @override
  String get intercomNoOther => 'Keine weiteren Kiosks gefunden';

  @override
  String get intercomRosterDeviceHelp =>
      'Hier werden Kiosks angezeigt, bei denen Fernverwaltung und „Andere Kiosks finden“ aktiviert sind.';

  @override
  String get intercomNoneHeard => 'Keine Kiosks gefunden';

  @override
  String get intercomRosterRemoteHelp =>
      'Kiosks werden angezeigt, sobald sie im Netzwerk erkannt wurden oder als Mitglieder der Flotte gespeichert sind. Fernverwaltung und „Andere Kiosks finden“ müssen aktiviert sein.';

  @override
  String get intercomReady => 'Bereit';

  @override
  String get intercomOff => 'Gegensprechanlage deaktiviert';

  @override
  String get intercomDifferentKey => 'Anderer Schlüssel';

  @override
  String get intercomUnreachable => 'Nicht erreichbar';

  @override
  String get intercomOffline => 'Offline';

  @override
  String get intercomChecking => 'Wird geprüft...';

  @override
  String get settingIntercomTalkModeTitle => 'Gesprächsmodus';

  @override
  String get settingIntercomTalkModeDescription =>
      'Bei „Drücken zum Sprechen“ wird deine Stimme übertragen, solange die Taste gedrückt gehalten wird. Im Freisprechmodus bleibt das Mikrofon während des gesamten Gesprächs geöffnet.';

  @override
  String get intercomOptionTalkPtt => 'Drücken zum Sprechen';

  @override
  String get intercomOptionTalkHandsfree => 'Freisprechen';

  @override
  String get intercomTalkSection => 'Gespräch';

  @override
  String get settingKioskAllowDrawerTitle =>
      'Menü mit Schnellaktionen erlauben';

  @override
  String get settingKioskAllowDrawerDescription =>
      'Ein Wischen vom Bildschirmrand öffnet das Menü ohne Exit-Geste oder PIN, beschränkt auf die unten ausgewählten Aktionen.';

  @override
  String get settingKioskAllowDashboardTitle => 'Dashboard';

  @override
  String get settingKioskAllowDashboardDescription =>
      'Lädt die Startseite neu.';

  @override
  String get settingKioskAllowHaKioskTitle => 'HA-Kioskmodus';

  @override
  String get settingKioskAllowHaKioskDescription =>
      'Blendet die Kopfzeile und die Seitenleiste von Home Assistant ein oder aus.';

  @override
  String get settingKioskAllowCameraTitle => 'Kameraansicht';

  @override
  String get settingKioskAllowCameraDescription =>
      'Öffnet die Standard-Kameraansicht.';

  @override
  String get settingKioskAllowIntercomTitle => 'Gegensprechanlage';

  @override
  String get settingKioskAllowIntercomDescription =>
      'Ruft andere Kiosks über das Kiosk-Menü an.';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription =>
      'Öffnet die Weboberfläche von Music Assistant.';

  @override
  String get settingKioskAllowSendspinPlayerTitle => 'Schwebender Player';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      'Blendet den schwebenden Player ein oder aus und öffnet „Jetzt läuft“.';

  @override
  String get settingKioskAllowScreensaverTitle => 'Bildschirmschoner starten';

  @override
  String get settingKioskAllowScreensaverDescription =>
      'Startet den Bildschirmschoner sofort.';

  @override
  String get settingKioskAllowHoldTitle => 'Pausenmodus';

  @override
  String get settingKioskAllowHoldDescription =>
      'Aktiviert oder deaktiviert den Pausenmodus.';

  @override
  String get settingKioskAllowLockdownTitle => 'Sperrmodus';

  @override
  String get settingKioskAllowLockdownDescription =>
      'Sperrt den Bildschirm, bis die Exit-Geste verwendet oder er remote entsperrt wird.';

  @override
  String get settingKioskAllowThemeTitle => 'Designauswahl';

  @override
  String get settingKioskAllowThemeDescription =>
      'Wechselt zwischen hellem und dunklem Design.';

  @override
  String get settingKioskAllowAppsTitle => 'Apps';

  @override
  String get settingKioskAllowAppsDescription =>
      'Öffnet den App-Launcher. Wenn „Home-Taste deaktivieren“ aktiviert ist, wird beim Öffnen einer App die Kiosk-Fixierung aufgehoben, bis du zum Kiosk zurückkehrst.';

  @override
  String get kioskAllowedActions => 'Erlaubte Aktionen';

  @override
  String get kioskAllowedHelp =>
      'Welche Schnellaktionen das Kiosk-Menü anbietet';

  @override
  String get settingKioskEnabledTitle => 'Kioskmodus aktivieren';

  @override
  String get settingKioskEnabledDescription =>
      'Hält das Tablet in Kiosk Satellite. Die Exit-Geste ersetzt das Wischen zum Öffnen des Menüs, die Zurück-Taste bleibt innerhalb des Kiosks und die unten aufgeführten Schutzfunktionen werden aktiviert.';

  @override
  String get settingKioskStartOnBootTitle => 'Beim Einschalten starten';

  @override
  String get settingKioskStartOnBootDescription =>
      'Öffnet Kiosk Satellite beim Start des Geräts. Unter Android 10 oder neuer wird die Berechtigung „Über anderen Apps anzeigen“ benötigt. Android fordert sie beim ersten Aktivieren dieser Option an.';

  @override
  String get settingKioskExitGestureTitle => 'Kiosk-Exit-Geste';

  @override
  String get settingKioskExitGestureDescription =>
      'Schnelle Tippfolgen an beliebiger Stelle öffnen das Menü, nachdem gegebenenfalls die PIN abgefragt wurde. Varianten mit „letzten Tipp halten“ erfordern, dass der letzte Tipp gedrückt gehalten wird. Wenn diese Funktion deaktiviert ist, kann auf die Einstellungen nur über die Fernverwaltung zugegriffen werden.';

  @override
  String get settingKioskPinTitle => 'Kioskmodus-PIN';

  @override
  String get settingKioskPinDescription =>
      'Wird nach der Exit-Geste und vor dem Öffnen des Menüs abgefragt. Leer lassen, um keine PIN zu verwenden.';

  @override
  String get settingKioskDisableStatusBarTitle => 'Statusleiste deaktivieren';

  @override
  String get settingKioskDisableStatusBarDescription =>
      'Verhindert das Herunterziehen der Statusleiste durch einen Schutzbereich am oberen Bildschirmrand. Benötigt die Berechtigung „Über anderen Apps anzeigen“. Android fordert diese beim ersten Aktivieren der Option an.';

  @override
  String get settingKioskDisableVolumeTitle => 'Lautstärketasten deaktivieren';

  @override
  String get settingKioskDisableVolumeDescription =>
      'Ignoriert die physischen Lautstärketasten.';

  @override
  String get settingKioskDisablePowerTitle => 'Ein-/Aus-Taste deaktivieren';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android erlaubt es nicht, die Ein-/Aus-Taste zu blockieren. Daher wird der Bildschirm sofort wieder eingeschaltet, wenn sie gedrückt wird. Der Bildschirm kann weiterhin aus der Ferne ausgeschaltet werden.';

  @override
  String get settingKioskDisableHomeTitle => 'Home-Taste deaktivieren';

  @override
  String get settingKioskDisableHomeDescription =>
      'Fixiert die Anwendung mit der Android-Bildschirmfixierung, wodurch die Tasten „Home“ und „Zuletzt verwendete Apps“ gesperrt werden. Android verlangt beim ersten Mal eine Bestätigung.';

  @override
  String get settingKioskDisableContextMenusTitle =>
      'Kontextmenüs deaktivieren';

  @override
  String get settingKioskDisableContextMenusDescription =>
      'Verhindert Langdruck-Menüs und Textauswahl in der Webansicht.';

  @override
  String get settingKioskDisablePullRefreshTitle =>
      'Herunterziehen zum Aktualisieren deaktivieren';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Ignoriert die Aktualisierungsgeste durch Herunterziehen, solange der Kioskmodus aktiv ist.';

  @override
  String get settingKioskDisableGesturesTitle => 'Gesten deaktivieren';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Ignoriert die Gesten aus der Seite „Gesten“, solange der Kioskmodus aktiv ist.';

  @override
  String get kioskGestureTaps5 => '5 schnelle Tipper';

  @override
  String get kioskGestureTaps7 => '7 schnelle Tipper';

  @override
  String get kioskGestureTaps5Hold => '5 schnelle Tipper, den letzten halten';

  @override
  String get kioskGestureTaps7Hold => '7 schnelle Tipper, den letzten halten';

  @override
  String get kioskGestureNone => 'Deaktiviert (nur Fernverwaltung)';

  @override
  String get kioskForeground =>
      'Kiosk Satellite kann wieder in den Vordergrund wechseln.';

  @override
  String get kioskOverlayMissing =>
      'Ohne diese Berechtigung kann der Kiosk nicht in den Vordergrund zurückkehren und der Sperrmodus-Schutz deckt nur die Anwendung ab.';

  @override
  String get kioskGuardHeld =>
      'Die Benachrichtigungsleiste und die Übersicht der zuletzt verwendeten Apps werden automatisch geschlossen, solange der Bildschirm geschützt ist.';

  @override
  String get kioskGuardMissing =>
      'Ohne diese Berechtigung bleiben die Benachrichtigungsleiste und die Übersicht der zuletzt verwendeten Apps zugänglich. Aktiviere Kiosk Satellite unter Bedienungshilfen.';

  @override
  String get kioskOverlayRemote =>
      'Ohne diese Berechtigung kann der Kiosk nicht in den Vordergrund zurückkehren. Die Seite zum Erteilen der Berechtigung wird auf dem Tablet angezeigt.';

  @override
  String get kioskGuardRemote =>
      'Ohne diese Berechtigung bleiben die Benachrichtigungsleiste und die Übersicht der zuletzt verwendeten Apps zugänglich. Aktiviere Kiosk Satellite unter Bedienungshilfen auf dem Tablet.';

  @override
  String get kioskGrantDevice => 'Auf dem Gerät erteilen';

  @override
  String get kioskOpenSettingsDevice => 'Einstellungen auf dem Gerät öffnen';

  @override
  String get settingLockdownEnabledTitle => 'Sperrmodus aktivieren';

  @override
  String get settingLockdownEnabledDescription =>
      'Deaktiviert die Interaktion mit dem Bildschirm, bis der Sperrmodus über Home Assistant oder die Exit-Geste deaktiviert wird.';

  @override
  String get settingLockdownMenuTitle => 'Im Kiosk-Menü anzeigen';

  @override
  String get settingLockdownMenuDescription =>
      'Fügt dem Kiosk-Menü eine Sperrmodus-Option hinzu, um den Bildschirm zu sperren. Zum Entsperren die Exit-Geste, die Fernverwaltung oder Home Assistant verwenden.';

  @override
  String get settingLockdownBlackoutTitle => 'Bildschirm schwarz schalten';

  @override
  String get settingLockdownBlackoutDescription =>
      'Schaltet den Bildschirm während der Sperre auf Schwarz.';

  @override
  String get settingLockdownAllowScreensaverTitle =>
      'Bildschirmschoner zulassen';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      'Erlaubt die Nutzung des Bildschirmschoners bei gesperrtem Bildschirm. Das Beenden bei Bewegung bleibt deaktiviert, bis die Sperre aufgehoben wird.';

  @override
  String get settingLockdownExitGestureTitle => 'Exit-Geste für den Sperrmodus';

  @override
  String get settingLockdownExitGestureDescription =>
      'Schnelle Tippfolgen an beliebiger Stelle deaktivieren den Sperrmodus, nachdem gegebenenfalls die Kiosk-PIN eingegeben wurde. Varianten mit Halt-Geste erfordern, dass der letzte Tipp gedrückt gehalten wird. Ist die Geste deaktiviert, kann die Sperre nur über die Fernverwaltung oder Home Assistant aufgehoben werden.';

  @override
  String get lockdownGestureNone => 'Deaktiviert (nur per Fernverwaltung)';

  @override
  String get lockdownExplanation =>
      'Der Sperrmodus deaktiviert die Interaktion mit dem Dashboard, aktiviert alle Schutzfunktionen des Kioskmodus, ohne deren Konfiguration zu ändern, und unterdrückt die Aktivierungswort-Erkennung, solange er aktiv ist. Wenn der Schutz der Systemoberfläche oben aktiviert ist, werden zusätzlich die Benachrichtigungsleiste und die Übersicht der zuletzt verwendeten Apps gesperrt. Home Assistant erhält über ESPHome einen Schalter für den Sperrmodus.';

  @override
  String get lockdownSearch =>
      'Berührungssperre, die über die Fernverwaltung konfiguriert wird. Die erforderlichen Berechtigungen findest du unter „Erforderliche Systemberechtigungen“.';

  @override
  String get lockdownOverlayHeld =>
      'Der Sperrmodus kann den gesamten Bildschirm überdecken.';

  @override
  String get lockdownOverlayMissing =>
      'Ohne diese Berechtigung deckt der Sperrmodus nur die Anwendung ab. Die Seite zum Erteilen der Berechtigung wird auf dem Tablet angezeigt.';

  @override
  String get lockdownPermissionsSearch =>
      'Die Berechtigungen, die für die Schutzfunktionen des Sperrmodus benötigt werden.';

  @override
  String get mediaCacheTitle => 'Cover-Cache';

  @override
  String get mediaCacheReadFailed =>
      'Die Cache-Größe konnte nicht gelesen werden.';

  @override
  String get mediaCacheClearFailed => 'Der Cache konnte nicht gelöscht werden.';

  @override
  String get mediaCacheChecking => 'Cache-Größe wird überprüft...';

  @override
  String get mediaCacheClearing => 'Wird gelöscht...';

  @override
  String mediaCacheUsage(String used, String limit) {
    return '$used von $limit verwendet. Warteschlangen-Miniaturansichten werden automatisch zwischengespeichert.';
  }

  @override
  String get settingSendspinShowPlayerTitle => 'Schwebenden Player anzeigen';

  @override
  String get settingSendspinShowPlayerDescription =>
      'Zeigt während der Musikwiedergabe ein kleines Fenster über dem Dashboard mit Coverbild, Titelinformationen und Fortschrittsanzeige an. Es kann beliebig verschoben werden. Seine Position wird gespeichert.';

  @override
  String get settingSendspinPlayerSizeTitle => 'Player-Größe';

  @override
  String get settingSendspinPlayerSizeDescription =>
      'Kompakt zeigt ein kleines, unauffälliges Fenster an. Groß ergänzt Schaltflächen für vorherigen Titel, Wiedergabe/Pause und nächsten Titel. Diese steuern die gesamte Wiedergabegruppe.';

  @override
  String get settingSendspinPausedHideMinutesTitle =>
      'Pausierten Player ausblenden nach';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      'Legt fest, wie lange ein pausierter Player sichtbar bleibt. Gilt sowohl für den schwebenden Player als auch für die Ansicht „Jetzt läuft“.';

  @override
  String get settingSendspinDismissKeepsPlayingTitle =>
      'Beim Ausblenden weiter abspielen';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      'Wenn der schwebende Player aus dem Bildschirm geschoben wird, wird er ausgeblendet, ohne die Wiedergabe zu stoppen.';

  @override
  String get settingSendspinPlayerShortcutTitle => 'Im Kiosk-Menü anzeigen';

  @override
  String get settingSendspinPlayerShortcutDescription =>
      'Fügt dem Kiosk-Menü einen Eintrag zum Ein- oder Ausblenden des schwebenden Players hinzu. WARNUNG: Wird nicht angezeigt, wenn weder etwas abgespielt wird noch eine Warteschlange für diesen Player vorhanden ist.';

  @override
  String get mediaFloatingPage => 'Schwebender Player';

  @override
  String get mediaFloatingHint => 'Das kleine Fenster über dem Dashboard';

  @override
  String get mediaCompact => 'Kompakt';

  @override
  String get mediaLargeControls => 'Groß mit Bedienelementen';

  @override
  String get settingSendspinPlayerSourceTitle => 'Player-Quelle';

  @override
  String get settingSendspinPlayerSourceDescription =>
      'Legt fest, was der schwebende Player und „Jetzt läuft“ anzeigen und steuern: dieses Gerät oder einen Player an einem anderen Ort.';

  @override
  String get settingSendspinPlayerTitle => 'Player';

  @override
  String get settingSendspinPlayerDescription =>
      'Der Player dieser Quelle, der angezeigt und gesteuert werden soll.';

  @override
  String get settingSendspinDuckPercentTitle =>
      'Lautstärke während Sprachinteraktionen reduzieren';

  @override
  String get settingSendspinDuckPercentDescription =>
      'Während Sprachinteraktionen und Intercom-Anrufen wird die Musik auf diesen Prozentsatz ihrer ursprünglichen Lautstärke abgesenkt. Anschließend wird die vorherige Lautstärke wiederhergestellt.';

  @override
  String get settingSendspinVolumeKeysTitle =>
      'Player mit den Lautstärketasten steuern';

  @override
  String get settingSendspinVolumeKeysDescription =>
      'Die Lautstärketasten dieses Geräts ändern die Lautstärke des gesteuerten Players. Dies gilt entweder nur, solange „Jetzt läuft“ angezeigt wird, oder immer während der Player Musik wiedergibt.';

  @override
  String get settingSendspinVolumeKeyStepTitle =>
      'Schrittweite der Lautstärketasten';

  @override
  String get settingSendspinVolumeKeyStepDescription =>
      'Wie stark sich die Lautstärke des Players pro Tastendruck verändert.';

  @override
  String get mediaIntro =>
      'Der schwebende Player und „Jetzt läuft“ erscheinen nur, wenn der ausgewählte Player aktuell einen Titel wiedergibt oder eine Warteschlange geladen hat. Wenn nichts wiedergegeben wird und keine Warteschlange vorhanden ist, werden sie nicht angezeigt.';

  @override
  String get mediaThisDevice => 'Dieses Gerät';

  @override
  String get mediaOff => 'Deaktiviert';

  @override
  String get mediaKeysNowPlaying => 'Während „Jetzt läuft“ angezeigt wird';

  @override
  String get mediaKeysPlaying => 'Während der Player wiedergibt';

  @override
  String get mediaAnotherPlayer => 'anderer Player';

  @override
  String mediaLocalOffline(String player) {
    return 'Der Sendspin-Player dieses Geräts bleibt getrennt, während $player gesteuert wird.';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => 'Songtexte aktivieren';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      'Synchronisierte Songtexte in „Jetzt läuft“ für alle Player-Quellen.';

  @override
  String get settingSendspinLyricsSourceTitle => 'Quelle der Songtexte';

  @override
  String get settingSendspinLyricsSourceDescription =>
      'Legt fest, woher die Songtexte bezogen werden. Für Music Assistant werden die Serveradresse und das Token auf dessen Einstellungsseite benötigt.';

  @override
  String get settingSendspinLyricsFallbackTitle =>
      'Music Assistant als Alternative verwenden';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      'Falls keine Verbindung zu LRCLIB hergestellt werden kann, wird Music Assistant abgefragt. Erfordert eine Verbindung zu Music Assistant.';

  @override
  String get settingSendspinLyricsOffsetTitle =>
      'Synchronisierung der Songtexte';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      'Passt die Songtexte zeitlich an die Musik an. Ein positiver Wert zeigt jede Zeile früher an, ein negativer Wert später. Nützlich, wenn die Songtexte eines Titels stets zeitlich versetzt erscheinen.';

  @override
  String get mediaLyricsPage => 'Songtexte';

  @override
  String get mediaLyricsHint =>
      'Synchronisierte Songtexte, deren Quelle und zeitliche Abstimmung';

  @override
  String get settingSendspinMaUrlTitle => 'Serveradresse';

  @override
  String get settingSendspinMaUrlDescription =>
      'Die Adresse des Music-Assistant-Servers, wie sie in dessen Weboberfläche angezeigt wird. Üblicherweise wird HTTPS mit Port 8095 verwendet.';

  @override
  String get settingSendspinMaTokenTitle => 'Authentifizierungs-Token';

  @override
  String get settingSendspinMaTokenDescription =>
      'Ein Langzeit-Token aus Music Assistant unter Einstellungen und anschließend Benutzer. Für Songtexte reicht Leserechte-Zugriff aus. Der Menüeintrag im Kiosk-Menü öffnet die Weboberfläche mit dem Benutzer, zu dem das Token gehört.';

  @override
  String get settingSendspinMaShortcutTitle => 'Im Kiosk-Menü anzeigen';

  @override
  String get settingSendspinMaShortcutDescription =>
      'Fügt dem Kiosk-Menü einen Eintrag für Music Assistant hinzu, um die Weboberfläche des Servers über dem Dashboard zu öffnen. Erfordert die oben angegebene Serveradresse.';

  @override
  String get settingSendspinMaOpenFullscreenTitle =>
      'Direkt „Jetzt läuft“ öffnen';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      'Öffnet den Vollbild-Player von Music Assistant über das Kiosk-Menü oder die Geste „Music Assistant öffnen“.';

  @override
  String get settingSendspinMaAutoCloseTitle => 'Nach Inaktivität schließen';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Kehrt zum Dashboard zurück, wenn die Music-Assistant-Seite für diese Zeit nicht berührt wurde. Bei 0 bleibt sie geöffnet, bis sie manuell geschlossen wird.';

  @override
  String get settingSendspinMaHideCloseTitle =>
      'Schließen-Schaltfläche ausblenden';

  @override
  String get settingSendspinMaHideCloseDescription =>
      'Die schwebende Schließen-Schaltfläche kann Bedienelemente von Music Assistant überdecken, beispielsweise das Menü von „Jetzt läuft“. Ohne diese Schaltfläche kann die Seite über die Zurück-Taste oder das seitliche Kiosk-Menü geschlossen werden.';

  @override
  String get mediaMaHint => 'Server, Token und Menüeintrag im Kiosk-Menü';

  @override
  String get mediaKioskMenu => 'Kiosk-Menü';

  @override
  String get mediaValidateConnection => 'Verbindung prüfen';

  @override
  String get mediaValidate => 'Prüfen';

  @override
  String get mediaChecking => 'Wird geprüft...';

  @override
  String get mediaConnected => 'Verbunden';

  @override
  String mediaConnectedVersion(String version) {
    return 'Verbunden mit Music Assistant $version';
  }

  @override
  String get mediaValidateHint =>
      'Prüft Serveradresse und Token, bevor der Menüeintrag oder Songtexte aktiviert werden.';

  @override
  String get mediaDeviceNoAnswer => 'Das Gerät hat nicht geantwortet.';

  @override
  String get mediaValidationFailed => 'Die Prüfung ist fehlgeschlagen.';

  @override
  String get mediaNoAddress => 'Es wurde keine Serveradresse konfiguriert.';

  @override
  String get mediaNoToken =>
      'Es wurde kein Authentifizierungs-Token konfiguriert.';

  @override
  String get mediaTimeout =>
      'Music Assistant hat nicht rechtzeitig geantwortet.';

  @override
  String mediaUnreachable(String host, String error) {
    return 'Verbindung zu $host fehlgeschlagen: $error';
  }

  @override
  String get mediaServerClosed => 'der Server hat die Verbindung geschlossen';

  @override
  String get settingSendspinFullscreenControlsTitle =>
      'Mediensteuerung anzeigen';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      'Schaltflächen für vorherigen Titel, Wiedergabe/Pause und nächsten Titel sowie eine Fortschrittsleiste in „Jetzt läuft“. Wenn die Steuerung aktiviert ist, wird die Ansicht über eine Schaltfläche geschlossen statt durch Tippen auf eine beliebige Stelle des Bildschirms.';

  @override
  String get settingSendspinFullscreenTextScaleTitle => 'Textskalierung';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      'Größe von Titel, Interpret, Album, Songtexten und Warteschlangentext. Gilt für beide Layouts sowie in Kombination mit dem Bildschirmschoner. Das Cover wird angepasst, um Platz für den Text zu schaffen.';

  @override
  String get settingSendspinFullscreenButtonScaleTitle =>
      'Schaltflächenskalierung';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      'Größe der Wiedergabeschaltflächen und der Fortschrittsleiste, unabhängig von der Textgröße. Gilt für beide Layouts sowie in Kombination mit dem Bildschirmschoner. Die Bedienelemente passen sich dem verfügbaren Platz an.';

  @override
  String get settingSendspinFullscreenHorizontalTitle => 'Horizontales Layout';

  @override
  String get settingSendspinFullscreenHorizontalDescription =>
      'Teilt Cover und Bedienelemente in zwei gleich große Bereiche links und rechts auf. Wenn Songtexte oder die Warteschlange geöffnet sind, werden die Titelinformationen unter dem Cover angezeigt. Gilt nicht, wenn „Jetzt läuft“ neben dem Bildschirmschoner angezeigt wird.';

  @override
  String get settingSendspinFullscreenDoubleTapTitle =>
      'Zum Schließen doppeltippen';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'Ein Doppeltipp an einer beliebigen Stelle von „Jetzt läuft“ schließt die Ansicht. Es wird keine Schließen-Schaltfläche angezeigt. Gilt nicht, wenn „Jetzt läuft“ neben dem Bildschirmschoner angezeigt wird.';

  @override
  String get settingSendspinFullscreenOnPlayTitle =>
      '„Jetzt läuft“ beim Start der Wiedergabe öffnen';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      'Öffnet „Jetzt läuft“ sofort, sobald die Wiedergabe beginnt, ohne auf das Timeout des Bildschirmschoners zu warten.';

  @override
  String get settingSendspinFullscreenMotionTitle =>
      '„Jetzt läuft“ bei Bewegungserkennung schließen';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      'Erlaubt das Schließen von „Jetzt läuft“ durch Bewegungserkennung, ähnlich wie bei einem normalen Bildschirmschoner. Wenn diese Option deaktiviert ist, wird die Ansicht nur durch Berührung geschlossen, sodass Vorbeigehen die Musikansicht nicht unterbricht. Gilt nicht, wenn „Jetzt läuft“ neben dem Bildschirmschoner angezeigt wird.';

  @override
  String get settingSendspinFullscreenShortcutTitle => 'Im Kiosk-Menü anzeigen';

  @override
  String get settingSendspinFullscreenShortcutDescription =>
      'Fügt dem Kiosk-Menü einen Eintrag hinzu, um „Jetzt läuft“ anzuzeigen. WARNUNG: Wird nicht angezeigt, wenn für diesen Player weder eine Wiedergabe noch eine Warteschlange vorhanden ist.';

  @override
  String get settingSendspinSpeakerPillTitle => 'Lautsprecherauswahl anzeigen';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Zeigt die Lautsprecherauswahl 5 Sekunden lang nach einer Interaktion mit dem Bildschirm an. Damit können Lautsprecher zur aktuellen Gruppe hinzugefügt oder daraus entfernt werden.';

  @override
  String get settingSendspinQueueArtTitle =>
      'Coverbilder in der Warteschlange anzeigen';

  @override
  String get settingSendspinQueueArtDescription =>
      'Zeigt ein Coverbild in jeder Zeile der Warteschlange an.';

  @override
  String get mediaNowPlayingHint =>
      'Vollbildansicht während der Musikwiedergabe';

  @override
  String get mediaInterfaceHeading => 'Benutzeroberfläche';

  @override
  String get settingSendspinFullscreenTitle =>
      '„Jetzt läuft“ anstelle des Bildschirmschoners';

  @override
  String get settingSendspinFullscreenDescription =>
      'Während Musik wiedergegeben wird, wird der Bildschirmschoner durch die Vollbildansicht „Jetzt läuft“ mit dem Albumcover ersetzt. Wenn nichts wiedergegeben wird, wird der normale Bildschirmschoner verwendet.';

  @override
  String get settingSendspinFullscreenSplitTitle =>
      'Neben dem Bildschirmschoner anzeigen';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      'Lässt den Bildschirmschoner neben „Jetzt läuft“ sichtbar. Auf Hochformat-Bildschirmen wird der Bildschirmschoner über dem Player angezeigt. Auf kleinen Bildschirmen bleibt der Player im Vollbildmodus.';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => 'Bildschirm ausfüllen';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      'Legt fest, wie Fotos angepasst werden, wenn der Bildschirmschoner gemeinsam mit „Jetzt läuft“ angezeigt wird. Standard verwendet die Einstellung des jeweiligen Bildschirmschoners. Deaktiviert zeigt das vollständige Foto mit schwarzen Balken. Intelligent vergrößert Fotos mit ähnlichem Seitenverhältnis wie der Bildschirm und zeigt andere auf einem unscharfen Hintergrund an. Immer vergrößert alle Fotos und schneidet überstehende Bereiche ab.';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle =>
      'Bildschirmschoner-Helligkeit überschreiben';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      'Verwendet die normale Bildschirmhelligkeit anstelle der Bildschirmschoner-Helligkeit, solange „Jetzt läuft“ daneben angezeigt wird. Überschreibt auch die Helligkeit zeitgesteuerter Bildschirmschoner.';

  @override
  String get mediaScreensaverHeading => 'Bildschirmschoner';

  @override
  String get mediaDefaultFill => 'Standard';

  @override
  String get mediaFillOff => 'Deaktiviert';

  @override
  String get mediaFillSmart => 'Intelligent';

  @override
  String get mediaFillAlways => 'Immer';

  @override
  String get mediaPickPlayer => 'Player auswählen';

  @override
  String get mediaMaPlayer => 'Music-Assistant-Player';

  @override
  String get mediaHaPlayer => 'Home-Assistant-Medienplayer';

  @override
  String get mediaSonosRoom => 'Sonos-Raum';

  @override
  String get mediaSearchPlayers => 'Player suchen';

  @override
  String get mediaOffline => 'Offline';

  @override
  String mediaOfflineName(String name) {
    return '$name (offline)';
  }

  @override
  String get mediaSetUpMa =>
      'Richte Music Assistant ein, um dessen Player anzuzeigen.';

  @override
  String get mediaSetUpHa =>
      'Verbinde Home Assistant, um dessen Medienplayer anzuzeigen.';

  @override
  String get mediaSetUpSonos =>
      'Es sind noch keine Sonos-Lautsprecher registriert. Suche oder füge einen auf der Sonos-Seite hinzu.';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant hat nicht geantwortet: $error';
  }

  @override
  String get mediaSaveFailed => 'Der Player konnte nicht gespeichert werden.';

  @override
  String get mediaSelectFailed => 'Der Player konnte nicht ausgewählt werden';

  @override
  String get settingSendspinEnabledTitle => 'Sendspin-Player aktivieren';

  @override
  String get settingSendspinEnabledDescription =>
      'Verwandelt dieses Gerät in einen synchronisierten Sendspin-Player. Er erscheint in Music Assistant unter dem Gerätenamen und wird mit anderen Sendspin-Lautsprechern synchronisiert.';

  @override
  String get settingSendspinServerTitle => 'Server';

  @override
  String get settingSendspinServerDescription =>
      'Adresse des Sendspin-Servers, z. B. 192.168.1.10:8927. Lasse das Feld leer, um den Server automatisch im Netzwerk zu suchen.';

  @override
  String get settingSendspinCodecTitle => 'Bevorzugter Audio-Codec';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC ist verlustfrei und ideal für WLAN oder Ethernet. Der Server wählt den Codec aus den von diesem Gerät unterstützten Codecs aus.';

  @override
  String get settingSendspinSyncOffsetTitle =>
      'Audio-Synchronisationskorrektur (ms)';

  @override
  String get settingSendspinSyncOffsetDescription =>
      'Ein negativer Wert lässt dieses Gerät früher wiedergeben, um Lautsprecher auszugleichen, die gegenüber der Gruppe verzögert sind, beispielsweise Bluetooth-Lautsprecher. Nach Gehör anpassen. Wird sofort angewendet.';

  @override
  String get mediaSendspinPage => 'Sendspin-Player';

  @override
  String get mediaSendspinHint =>
      'Verwandelt dieses Gerät in einen synchronisierten Music-Assistant-Player';

  @override
  String get mediaFlac => 'FLAC (verlustfrei)';

  @override
  String get mediaOpus => 'Opus (effizient)';

  @override
  String get mediaPcm => 'PCM (unkomprimiert)';

  @override
  String get settingSendspinSonosGroupVolumeTitle =>
      'Gruppenlautstärke anpassen';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      'Wenn der gesteuerte Raum in einer Gruppe wiedergibt, steuert die Lautstärkeregelung die gesamte Gruppe. Ist diese Option deaktiviert, wird nur die Lautstärke dieses Raums angepasst.';

  @override
  String get settingSendspinSonosInputsTitle =>
      'TV- und Line-In-Eingänge anzeigen';

  @override
  String get settingSendspinSonosInputsDescription =>
      'Zeigt Aktivitäten im Medienplayer an, wenn eARC- oder Line-In-Eingänge aktiv sind.';

  @override
  String get mediaSonosHint =>
      'Lautsprecher im Netzwerk und Hinzufügen per Adresse';

  @override
  String get mediaSonosSpeakers => 'Lautsprecher';

  @override
  String get mediaSonosNoneFound => 'Keine Sonos-Lautsprecher gefunden';

  @override
  String get mediaSonosDiscoveryEmpty =>
      'Kein Lautsprecher hat in diesem Netzwerk geantwortet. Füge einen über seine Adresse hinzu.';

  @override
  String get mediaSonosAddTitle => 'Sonos-Lautsprecher per Adresse hinzufügen';

  @override
  String get mediaSonosLooking => 'Suche läuft...';

  @override
  String get mediaSonosEmpty => 'Noch keine Lautsprecher vorhanden';

  @override
  String get mediaSonosEmptyHelp =>
      'Suche in diesem Netzwerk oder füge einen Lautsprecher über seine Adresse hinzu.';

  @override
  String get mediaSonosForget => 'Entfernen';

  @override
  String get mediaSonosSearchTitle => 'Im Netzwerk suchen';

  @override
  String get mediaSonosSearchHelp =>
      'Sucht nach Sonos-Lautsprechern in diesem Netzwerk. Die Lautsprecher müssen sich im selben VLAN wie dieses Gerät befinden, damit sie automatisch gefunden werden können.';

  @override
  String get mediaSonosSearch => 'Suchen';

  @override
  String get mediaSonosSearching => 'Suche läuft...';

  @override
  String get mediaSonosAddAddress => 'Per Adresse hinzufügen';

  @override
  String get mediaSonosAddressHelp =>
      'Die Netzwerkadresse des Lautsprechers. Darüber werden alle Lautsprecher desselben Sonos-Systems hinzugefügt.';

  @override
  String get mediaSonosPickRoom =>
      'Wähle unter „Player-Quelle > Sonos“ einen Raum aus.';

  @override
  String get mediaSonosAdded => 'Sonos hinzugefügt';

  @override
  String get mediaSonosNoRooms =>
      'Der Lautsprecher hat keine Räume zurückgegeben.';

  @override
  String get mediaSonosNoAddress => 'keine Adresse';

  @override
  String mediaSonosUnreachable(String host) {
    return 'Kein Sonos-Gerät hat unter $host geantwortet.';
  }

  @override
  String get settingsMenuHomeAssistant => 'Home-Assistant-Einstellungen';

  @override
  String get settingsMenuHomeAssistantSummary =>
      'Verbindung, Dashboard, Kioskmodus';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary =>
      'Aktivierungswort, Hintergrundabhören';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary =>
      'Native Entitäten und Bluetooth-Proxy';

  @override
  String get settingsMenuScreenAudio => 'Bildschirm und Audio';

  @override
  String get settingsMenuScreenAudioSummary =>
      'Helligkeit, Lautstärke, Mikrofon';

  @override
  String get settingsMenuScreensaver => 'Bildschirmschoner';

  @override
  String get settingsMenuScreensaverSummary =>
      'Leerlaufzeit, Modi, Aktivierung durch Bewegung';

  @override
  String get settingsMenuBrowser => 'Webbrowser';

  @override
  String get settingsMenuBrowserSummary => 'Cache, SSL, Zoomstufe';

  @override
  String get settingsMenuMediaPlayer => 'Medienplayer';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant, Sendspin, Sonos';

  @override
  String get settingsMenuDlna => 'DLNA-Empfänger';

  @override
  String get settingsMenuDlnaSummary =>
      'Bilder, Videos und Audio aus der Ferne wiedergeben';

  @override
  String get settingsMenuIntercom => 'Gegensprechanlage';

  @override
  String get settingsMenuIntercomSummary => 'Kommunikation zwischen Kiosks';

  @override
  String get settingsMenuCamera => 'Kamera';

  @override
  String get settingsMenuCameraSummary => 'Gerätekamera, Bewegung, Streaming';

  @override
  String get settingsMenuCameraStreams => 'Kamerastreams';

  @override
  String get settingsMenuCameraStreamsSummary =>
      'Kameras von Go2RTC und Home Assistant';

  @override
  String get settingsMenuKiosk => 'Kioskmodus';

  @override
  String get settingsMenuKioskSummary => 'Exit-Geste, PIN, physische Tasten';

  @override
  String get settingsMenuHomeLauncher => 'Home-Launcher';

  @override
  String get settingsMenuHomeLauncherSummary =>
      'Ersetzt den Startbildschirm des Geräts';

  @override
  String get settingsMenuAppLauncher => 'App-Launcher';

  @override
  String get settingsMenuAppLauncherSummary =>
      'Andere Apps aus dem Kiosk öffnen';

  @override
  String get settingsMenuGestures => 'Gesten';

  @override
  String get settingsMenuGesturesSummary => 'Touch-, Hand- und Klatschgesten';

  @override
  String get settingsMenuDevice => 'Gerät';

  @override
  String get settingsMenuDeviceSummary => 'Name, App-Design, Fernzugriff';

  @override
  String get settingsMenuFleet => 'Flottenverwaltung';

  @override
  String get settingsMenuFleetSummary =>
      'Andere Kiosks verwalten oder einem Kiosk folgen';

  @override
  String get settingsMenuPlugins => 'Plugin-Manager';

  @override
  String get settingsMenuPluginsSummary => 'Plugins installieren und verwalten';

  @override
  String get settingsMenuLogs => 'Protokolle';

  @override
  String get settingsMenuLogsSummary => 'Anwendungsprotokoll und Web-Konsole';

  @override
  String get settingsMenuAbout => 'Info';

  @override
  String get settingsMenuAboutSummary => 'Version, Autor, Lizenz';

  @override
  String get settingsMenuOverview => 'Übersicht';

  @override
  String get settingsMenuOverviewSummary => 'Bildschirm und Schnellaktionen';

  @override
  String get settingsMenuLockdown => 'Sperrmodus';

  @override
  String get settingsMenuLockdownSummary =>
      'Deaktiviert Interaktionen mit dem Bildschirm';

  @override
  String get settingsMenuFiles => 'Dateimanager';

  @override
  String get settingsMenuFilesSummary =>
      'Dateien durchsuchen, herunterladen und hochladen';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => 'Anzeige';

  @override
  String get settingsGroupMediaCameras => 'Medien und Kameras';

  @override
  String get settingsGroupKiosk => 'Kiosk';

  @override
  String get settingsGroupSystem => 'System';

  @override
  String get settingsMenuMenu => 'Menü';

  @override
  String get settingsMenuTheme => 'Design';

  @override
  String get settingsMenuLogout => 'Abmelden';

  @override
  String get settingsMenuSwitchKiosk => 'Kiosk wechseln';

  @override
  String settingsMenuThemeState(String theme) {
    return 'Design: $theme';
  }

  @override
  String get settingsMenuThemeAuto => 'Automatisch';

  @override
  String get settingAdaptiveBrightnessTitle => 'Adaptive Helligkeit';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Passt die Bildschirmhelligkeit mithilfe des Umgebungslichtsensors an die Helligkeit des Raums an.';

  @override
  String get settingAdaptiveMinBrightnessTitle => 'Minimale Helligkeit';

  @override
  String get settingAdaptiveMinBrightnessDescription =>
      'Bildschirmhelligkeit in einem dunklen Raum.';

  @override
  String get settingAdaptiveMaxBrightnessTitle => 'Maximale Helligkeit';

  @override
  String get settingAdaptiveMaxBrightnessDescription =>
      'Bildschirmhelligkeit in einem hell beleuchteten Raum.';

  @override
  String get settingAdaptiveDarkLuxTitle => 'Dunkler Raum (lx)';

  @override
  String get settingAdaptiveDarkLuxDescription =>
      'Lichtstärke, bei der die Bildschirmhelligkeit den Minimalwert erreicht. Unterhalb dieses Werts bleibt sie auf diesem Niveau.';

  @override
  String get settingAdaptiveBrightLuxTitle => 'Heller Raum (lx)';

  @override
  String get settingAdaptiveBrightLuxDescription =>
      'Lichtstärke, bei der die Bildschirmhelligkeit den Maximalwert erreicht. Oberhalb dieses Werts bleibt sie auf diesem Niveau.';

  @override
  String get screenAudioAdaptiveHint =>
      'Passt die Helligkeit mithilfe des Umgebungslichtsensors an die Raumbeleuchtung an';

  @override
  String get screenAudioAdaptiveNote =>
      'Wert für einen hell beleuchteten Raum. Die adaptive Helligkeit reduziert diesen Wert bei geringerer Umgebungsbeleuchtung.';

  @override
  String get screenAudioAdaptiveOwns => 'Adaptive Helligkeit ist aktiviert.';

  @override
  String get screenAudioNoSensor =>
      'Dieses Gerät verfügt über keinen Umgebungslichtsensor.';

  @override
  String get screenAudioAmbientLight => 'Umgebungslicht';

  @override
  String get screenAudioAmbientHelp =>
      'Aktueller Messwert des Umgebungslichtsensors.';

  @override
  String get screenAudioNoReading => 'Noch kein Messwert verfügbar';

  @override
  String screenAudioLux(String lux) {
    return '$lux lx';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux lx (letzter Messwert)';
  }

  @override
  String get screenAudioSetsMaximum =>
      'Legt die maximale Helligkeit fest, da die adaptive Helligkeit aktiviert ist.';

  @override
  String get screenAudioSetsDefault => 'Legt die Standardhelligkeit fest.';

  @override
  String get settingAudioMicDeviceTitle => 'Mikrofon';

  @override
  String get settingAudioMicDeviceDescription =>
      'Das Mikrofon, das für die Aktivierungswort-Erkennung und die Erfassung von Sprachinteraktionen verwendet wird.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Lautsprecher';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Ausgabegerät für die Töne von Voice Satellite. Die Medienwiedergabe folgt weiterhin der Systemausgabe. Die Echounterdrückung funktioniert nur, wenn Mikrofon und Lautsprecher zum selben Gerät gehören.';

  @override
  String get screenAudioDevices => 'Audiogeräte';

  @override
  String get screenAudioSelectedDevice => 'Ausgewähltes Gerät';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (nicht verbunden)';
  }

  @override
  String get settingMicAudioSourceTitle => 'Aufnahmemodus';

  @override
  String get settingMicAudioSourceDescription =>
      'Sprachkommunikation ist der einzige Modus mit Echounterdrückung. Behalte diese Einstellung bei, außer das Mikrofon zeichnet hier deutlich leiser auf als in einer Aufnahme-App.';

  @override
  String get settingMicEchoCancellationTitle => 'Echounterdrückung';

  @override
  String get settingMicEchoCancellationDescription =>
      'Verhindert, dass das Mikrofon den Lautsprecher des Kiosks aufnimmt, damit das Stoppwort auch während der Wiedergabe erkannt werden kann. Deaktiviere diese Funktion nur, wenn das Mikrofon hier deutlich leiser aufnimmt als in einer Aufnahme-App.';

  @override
  String get settingMicChannelTitle => 'Mikrofonkanal';

  @override
  String get settingMicChannelDescription =>
      'Mehrkanal-Mikrofone reservieren oft einen Kanal für die Spracherkennung. Die Auswahl dieses Kanals kann die Erkennung verbessern.';

  @override
  String get settingMicAgcTitle => 'Automatische Verstärkungsregelung';

  @override
  String get settingMicAgcDescription =>
      'Erlaubt Android, den Mikrofonpegel automatisch anzupassen, anstatt eine feste Verstärkung zu verwenden. Kann auch Umgebungsgeräusche verstärken und hat auf manchen Geräten keine Wirkung.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Rauschunterdrückung';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Reduziert Hintergrundgeräusche durch die Audioverarbeitung von Android. Je nach Gerät kann dies die Aktivierungswort-Erkennung verbessern oder verschlechtern.';

  @override
  String get settingMicGainDbTitle => 'Mikrofonverstärkung';

  @override
  String get settingMicGainDbDescription =>
      'Verstärkt oder dämpft das Mikrofonsignal vor der Audioverarbeitung. Strebe im Aktivierungswort-Tester einen Pegel von etwa 0,05 an. Zu hohe Verstärkung verursacht Verzerrungen und verschlechtert die Erkennung.';

  @override
  String get settingMicCaptureFormatTitle => 'Aufnahmeformat';

  @override
  String get settingMicCaptureFormatDescription =>
      'Wähle „Stereo mit 48 kHz“, wenn das Mikrofon in anderen Apps funktioniert, aber nicht hier. Einige Soundkarten unterstützen Aufnahmen nur in diesem Format, das anschließend von der App umgewandelt wird.';

  @override
  String get screenAudioMicrophoneSettings => 'Mikrofoneinstellungen';

  @override
  String get screenAudioMicrophoneHint =>
      'Aufnahmemodus, Kanal, Verstärkung und Echtzeit-Pegel';

  @override
  String get screenAudioMicrophoneNote =>
      'Passe die Aufnahme an Mikrofon und Umgebung an. Teste nach Änderungen die Aktivierungswörter und Sprachinteraktionen.';

  @override
  String get screenAudioVoiceCommunication => 'Sprachkommunikation (Standard)';

  @override
  String get screenAudioVoiceRecognition => 'Spracherkennung';

  @override
  String get screenAudioRawMicrophone => 'Rohes Mikrofon';

  @override
  String get screenAudioAutomaticDefault => 'Automatisch (Standard)';

  @override
  String get screenAudioStereo => 'Stereo mit 48 kHz';

  @override
  String get screenAudioDownmix => 'Kanäle mischen (Standard)';

  @override
  String screenAudioChannel(String channel) {
    return 'Kanal $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return 'Kanal $channel (auf diesem Mikrofon nicht verfügbar)';
  }

  @override
  String get screenAudioMicrophoneLevel => 'Mikrofonpegel';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      'Sprich aus der Entfernung, aus der du das Gerät normalerweise nutzt. Passe die Verstärkung so an, dass normale Sprache ungefähr das Ende des grünen Bereichs erreicht.';

  @override
  String get settingBrowserCutoutModeTitle => 'Bereich der Frontkamera';

  @override
  String get settingBrowserCutoutModeDescription =>
      'Legt fest, wie der Bildschirmbereich um die Frontkamera behandelt wird. Wähle „Kamerabereich vermeiden“, wenn die Kamera Schaltflächen im oberen Bereich des Dashboards verdeckt.';

  @override
  String get settingScreenOrientationTitle => 'Bildschirmausrichtung';

  @override
  String get settingScreenOrientationDescription =>
      'Erzwingt eine bestimmte Bildschirmausrichtung. Nützlich auf Geräten ohne Rotationssensor oder bei Installationen, bei denen der Sensor die Ausrichtung nicht korrekt erkennt.';

  @override
  String get settingKeepScreenOnTitle => 'Bildschirm eingeschaltet lassen';

  @override
  String get settingKeepScreenOnDescription =>
      'Verhindert, dass das Betriebssystem den Bildschirm ausschaltet.';

  @override
  String get settingSetBrightnessOnLaunchTitle =>
      'Helligkeit beim Start festlegen';

  @override
  String get settingSetBrightnessOnLaunchDescription =>
      'Wendet die Standardhelligkeit bei jedem Start der Anwendung an.';

  @override
  String get settingDefaultBrightnessTitle => 'Standardhelligkeit';

  @override
  String get settingDefaultBrightnessDescription =>
      'Bildschirmhelligkeit beim Start der Anwendung. Das Verschieben des Schiebereglers wird sofort angewendet.';

  @override
  String get screenAudioScreen => 'Bildschirm';

  @override
  String get screenAudioCutoutAlways => 'Kamerabereich verwenden';

  @override
  String get screenAudioCutoutShort => 'Nur an den kurzen Seiten';

  @override
  String get screenAudioCutoutDefault => 'Systemstandard';

  @override
  String get screenAudioCutoutNever => 'Kamerabereich vermeiden';

  @override
  String get screenAudioAutomatic => 'Automatisch';

  @override
  String get screenAudioLandscape => 'Querformat';

  @override
  String get screenAudioReverseLandscape => 'Querformat umgekehrt';

  @override
  String get screenAudioPortrait => 'Hochformat';

  @override
  String get screenAudioReversePortrait => 'Hochformat umgekehrt';

  @override
  String get screenAudioPermission => 'Berechtigung';

  @override
  String get screenAudioBrightnessFallback =>
      'Helligkeit verwendet eine alternative Methode';

  @override
  String get screenAudioBrightnessPermission =>
      'Ohne die Berechtigung „Systemeinstellungen ändern“ dimmen Helligkeitsänderungen nur diese Anwendung, anstatt die tatsächliche Bildschirmhelligkeit anzupassen.';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      'Ohne die Berechtigung „Systemeinstellungen ändern“ dimmen Helligkeitsänderungen nur die Anwendung, anstatt die tatsächliche Bildschirmhelligkeit anzupassen.';

  @override
  String get screenAudioAlwaysOn => 'Immer eingeschalteter Bildschirm';

  @override
  String get screenAudioAlwaysOnClock =>
      'Dieses Gerät hält eine gedimmte Uhr dauerhaft eingeblendet';

  @override
  String get screenAudioAlwaysOnHelp =>
      'Das Ausschalten des Bildschirms versetzt das Gerät in den Ruhezustand, jedoch aktiviert die Funktion „Immer eingeschalteter Bildschirm“ den Sperrbildschirm wieder, und keine Anwendung kann dies verhindern. Deaktiviere „Uhrzeit und Informationen immer anzeigen“ in den Android-Einstellungen unter „Anzeige“ bei den Sperrbildschirm-Optionen. Einige Android-Versionen nennen diese Funktion „Always-On Display“. Die Bildschirm-Entität in Home Assistant bleibt nicht verfügbar, bis diese Funktion deaktiviert wurde.';

  @override
  String get settingMediaVolumeTitle => 'Medienlautstärke';

  @override
  String get settingMediaVolumeDescription =>
      'Musik und Videos werden mit diesem Anteil der Hauptlautstärke wiedergegeben. Die Lautstärke des Sendspin-Players in Music Assistant steuert diesen Wert.';

  @override
  String get settingAssistantVolumeTitle => 'Assistentenlautstärke';

  @override
  String get settingAssistantVolumeDescription =>
      'Sprachantworten und Signaltöne werden mit diesem Anteil der Hauptlautstärke wiedergegeben, unabhängig von der Medienlautstärke.';

  @override
  String get settingAssistantFullVolumeRangeTitle =>
      'Voller Lautstärkebereich für den Assistenten';

  @override
  String get settingAssistantFullVolumeRangeDescription =>
      'Setzt die Anruflautstärke des integrierten Lautsprechers beim ersten Start der Assistenten-Audioausgabe auf 100 %. Die Hauptlautstärke und die Assistentenlautstärke wirken weiterhin darauf. Andere Anwendungen verwenden dieselbe Anruflautstärke, die anschließend nicht wiederhergestellt wird.';

  @override
  String get settingIntercomVolumeTitle => 'Intercom-Lautstärke';

  @override
  String get settingIntercomVolumeDescription =>
      'Stimme und Durchsagen des anderen Kiosks werden mit diesem Anteil der Hauptlautstärke wiedergegeben.';

  @override
  String get screenAudioVolume => 'Audiolautstärke';

  @override
  String get screenAudioMasterVolume => 'Hauptlautstärke';

  @override
  String get screenAudioMasterHelp =>
      'Gerätelautstärke. Medien-, Intercom- und Assistentenlautstärke werden proportional zu diesem Wert angepasst.';

  @override
  String get settingScreensaverBlackHideExtrasTitle =>
      'Alle zusätzlichen Elemente ausblenden';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      'Hält den Bildschirm vollständig schwarz, ohne kleine Uhr, „Auf einen Blick“-Entitäten oder andere eingeblendete Elemente.';

  @override
  String get screensaverBlackSection => 'Bildschirmschoner: Schwarz';

  @override
  String get settingScreensaverClockStyleTitle => 'Stil';

  @override
  String get settingScreensaverClockStyleDescription =>
      'Legt fest, wie die Uhr dargestellt wird.';

  @override
  String get settingScreensaverClockFontTitle => 'Schriftart';

  @override
  String get settingScreensaverClockFontDescription => 'Schriftart der Uhr.';

  @override
  String get settingScreensaverClockFontWeightTitle => 'Schriftstärke';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      'Stärke der Ziffern der Uhr. Standard verwendet die ursprüngliche Stärke des jeweiligen Stils.';

  @override
  String get settingScreensaverClock24hTitle => '24-Stunden-Uhr';

  @override
  String get settingScreensaverClock24hDescription =>
      'Zeigt die Uhrzeit im 24-Stunden-Format statt mit AM/PM an.';

  @override
  String get settingScreensaverClockSecondsTitle => 'Sekunden anzeigen';

  @override
  String get settingScreensaverClockSecondsDescription =>
      'Blendet die Sekunden in der Uhr ein.';

  @override
  String get settingScreensaverClockDateTitle => 'Datum anzeigen';

  @override
  String get settingScreensaverClockDateDescription =>
      'Zeigt Wochentag und Datum unter der Uhr an.';

  @override
  String get settingScreensaverClockScaleTitle => 'Uhrgröße';

  @override
  String get settingScreensaverClockScaleDescription =>
      'Passt die Größe der Uhr für diesen Bildschirm zwischen 50 % und 300 % an.';

  @override
  String get settingScreensaverClockColorTitle => 'Uhrfarbe';

  @override
  String get settingScreensaverClockColorDescription => 'Textfarbe der Uhr.';

  @override
  String get settingScreensaverClockBgColorTitle => 'Hintergrundfarbe';

  @override
  String get settingScreensaverClockBgColorDescription =>
      'Farbe hinter der Uhr.';

  @override
  String get settingScreensaverClockBackgroundTitle => 'Hintergrundbild';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      'Zeigt ein Bild hinter der Uhr anstelle einer einfarbigen Fläche an. Dies kann ein Bildpfad auf dem Gerät oder eine URL sein, von der das Gerät das Bild herunterlädt.';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle =>
      'Hintergrundbild von URL aktualisieren';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      'Minuten zwischen den Aktualisierungen eines Hintergrundbilds von einer URL. Bei 0 wird das Bild nur beim Speichern dieser Einstellung heruntergeladen.';

  @override
  String get settingScreensaverFlipDigitColorTitle => 'Ziffernfarbe';

  @override
  String get settingScreensaverFlipDigitColorDescription =>
      'Farbe der Ziffern der Klappuhr.';

  @override
  String get settingScreensaverFlipBgColorTitle => 'Farbe der Klappkarten';

  @override
  String get settingScreensaverFlipBgColorDescription =>
      'Farbe der Klappkarten der Uhr.';

  @override
  String get settingScreensaverFlipBackdropColorTitle => 'Hintergrundfarbe';

  @override
  String get settingScreensaverFlipBackdropColorDescription =>
      'Farbe hinter den Klappkarten.';

  @override
  String get settingScreensaverRollerDigitColorTitle => 'Ziffernfarbe';

  @override
  String get settingScreensaverRollerDigitColorDescription =>
      'Farbe der Ziffern der Rollenuhr.';

  @override
  String get settingScreensaverRollerBgColorTitle => 'Hintergrundfarbe';

  @override
  String get settingScreensaverRollerBgColorDescription =>
      'Farbe hinter den Ziffern.';

  @override
  String get settingScreensaverClockNightTitle => 'Nachtmodus';

  @override
  String get settingScreensaverClockNightDescription =>
      'Ändert die Farben der Uhr, wenn der Raum dunkel ist.';

  @override
  String get settingScreensaverClockNightLuxTitle => 'Helligkeitsschwelle';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      'Bei diesem oder einem niedrigeren Lichtwert verwendet die Uhr die Nachtfarben.';

  @override
  String get settingScreensaverClockNightColorTitle => 'Nachtfarbe';

  @override
  String get settingScreensaverClockNightColorDescription =>
      'Farbe der Uhr und der Widgets in dunkler Umgebung.';

  @override
  String get settingScreensaverClockNightBgColorTitle => 'Nachthintergrund';

  @override
  String get settingScreensaverClockNightBgColorDescription =>
      'Hintergrundfarbe hinter der Uhr im Nachtmodus.';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle =>
      'Hintergrundbild ausblenden';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      'Verwendet im Nachtmodus die Nachthintergrundfarbe anstelle des Hintergrundbilds.';

  @override
  String get settingScreensaverClockNightCardColorTitle =>
      'Nachtfarbe der Klappkarten';

  @override
  String get settingScreensaverClockNightCardColorDescription =>
      'Farbe der Klappkarten der Uhr im Nachtmodus.';

  @override
  String get screensaverClockSection => 'Bildschirmschoner: Uhr';

  @override
  String get screensaverClockHint =>
      'Stil, Schriftart, Größe, Farben, Nachtmodus und Hintergrundbild';

  @override
  String get screensaverStyleDigital => 'Digitale Uhr';

  @override
  String get screensaverStyleFlip => 'Klappuhr';

  @override
  String get screensaverStyleRoller => 'Rollenuhr';

  @override
  String get screensaverFontDefault => 'Standard';

  @override
  String get screensaverFontLight => 'Leicht';

  @override
  String get screensaverFontRegular => 'Normal';

  @override
  String get screensaverFontMedium => 'Mittel';

  @override
  String get screensaverFontBold => 'Fett';

  @override
  String get screensaverFontBlack => 'Sehr fett';

  @override
  String get screensaverNoPhoto => 'Kein Bild ausgewählt';

  @override
  String get screensaverBackgroundHint =>
      'Pfad zu einem Bild auf dem Gerät oder URL eines Bildes';

  @override
  String get screensaverImageUrlError =>
      'Bitte die vollständige URL eines Bildes eingeben';

  @override
  String get screensaverRefreshError =>
      'Bitte eine ganze Zahl zwischen 0 und 1440 Minuten eingeben';

  @override
  String screensaverMaxCharacters(String count) {
    return 'Maximal $count Zeichen verwenden';
  }

  @override
  String get screensaverOverlayEntity => 'Entität';

  @override
  String get screensaverOverlayNotSet => 'Nicht festgelegt';

  @override
  String get screensaverOverlayName => 'Name';

  @override
  String get screensaverOverlayNameHelp =>
      'Leer lassen, um den Namen aus Home Assistant zu verwenden.';

  @override
  String get screensaverOverlayValue => 'Angezeigter Wert';

  @override
  String get screensaverOverlayState => 'Status';

  @override
  String get screensaverOverlayEntityRequired =>
      'Bitte eine Entität auswählen.';

  @override
  String get screensaverOverlaySearchHint => 'Name oder Entitäts-ID';

  @override
  String get screensaverOverlaySearchHintRemote =>
      'Nach Name oder Entitäts-ID suchen';

  @override
  String get screensaverOverlaySearchEmpty =>
      'Zum Suchen von Entitäten tippen.';

  @override
  String get screensaverOverlayNoMatches => 'Keine Treffer gefunden.';

  @override
  String get screensaverOverlaySearching => 'Suche läuft...';

  @override
  String get screensaverOverlayUnreachable =>
      'Verbindung zu Home Assistant nicht möglich';

  @override
  String get screensaverOverlayNoAnswer => 'Das Gerät hat nicht geantwortet.';

  @override
  String screensaverOverlaySearchError(String error) {
    return 'Die Suche nach Entitäten ist fehlgeschlagen: $error';
  }

  @override
  String get settingScreensaverDismissOnFaceTitle =>
      'Bei Gesichtserkennung schließen';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      'Aktiviert den Bildschirm, wenn jemand den Kiosk ansieht, nicht nur bei Bewegung. Die Kamera wird dabei nur während des Bildschirmschoners verwendet. WARNUNG: Erfordert ein ausreichend beleuchtetes Gesicht. In dunklen Umgebungen stattdessen die Bewegungserkennung verwenden.';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle =>
      'Nur bei ausgeschaltetem Bildschirm';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      'Lässt den Bildschirmschoner sichtbar, wenn bei eingeschaltetem Bildschirm ein Gesicht erkannt wird. Ist der Bildschirm ausgeschaltet, öffnet die Erkennung das Dashboard. Durch Berühren des Bildschirms wird der Bildschirmschoner weiterhin geschlossen.';

  @override
  String get settingScreensaverPostponeOnFaceTitle =>
      'Bildschirmschoner bei Gesichtserkennung verschieben';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      'Verzögert die Aktivierung des Bildschirmschoners, solange jemand den Kiosk ansieht. WARNUNG: Die Kamera bleibt dauerhaft aktiv, einschließlich der zusätzlichen CPU-Auslastung durch die Gesichtserkennung.';

  @override
  String get settingFaceSensitivityTitle =>
      'Empfindlichkeit der Gesichtserkennung';

  @override
  String get settingFaceSensitivityDescription =>
      'Höhere Werte erkennen kleinere und weiter entfernte Gesichter. Der Wert 1 erfordert ein Gesicht nahe am Bildschirm. Der Wert 100 reagiert auf jedes Gesicht, das die Kamera erkennen kann.';

  @override
  String get screensaverDetectionFacePage => 'Gesichtserkennung';

  @override
  String get screensaverDetectionFaceHint =>
      'Schließt den Bildschirmschoner, wenn ihn jemand ansieht';

  @override
  String get screensaverDetectionMotionPrecedence =>
      '„Bei Bewegung schließen“ ist aktiviert und hat Vorrang. Die Gesichtserkennung bleibt deaktiviert, bis diese Funktion ausgeschaltet wird.';

  @override
  String get screensaverDetectionFaceTuning =>
      'Bildrate, Kamera und Startverzögerung werden in den Kamera-Einstellungen konfiguriert.';

  @override
  String get screensaverDetectionAndroidUnsupported =>
      'Auf dieser Android-Version nicht verfügbar.';

  @override
  String get screensaverDetectionX86Unsupported =>
      'Auf x86-Geräten nicht verfügbar.';

  @override
  String get settingFacePreviewTitle => 'Kameravorschau anzeigen';

  @override
  String get settingFacePreviewDescription =>
      'Zeigt für einige Sekunden eine kleine, runde Live-Vorschau der Kamera in einer Ecke an, wenn ein Gesicht den Kiosk aktiviert.';

  @override
  String get settingFacePreviewSecondsTitle => 'Dauer der Vorschau';

  @override
  String get settingFacePreviewSecondsDescription =>
      'Wie lange die Vorschau auf dem Bildschirm angezeigt wird.';

  @override
  String get settingFacePreviewScaleTitle => 'Skalierung der Vorschau';

  @override
  String get settingFacePreviewScaleDescription =>
      'Passt die Größe der Vorschau an den Bildschirm an.';

  @override
  String get settingFacePreviewPositionTitle => 'Position der Vorschau';

  @override
  String get settingFacePreviewPositionDescription =>
      'Die Ecke, in der die Vorschau angezeigt wird.';

  @override
  String get screensaverDetectionPreviewSection => 'Kameravorschau';

  @override
  String get settingScreensaverEnabledTitle => 'Bildschirmschoner';

  @override
  String get settingScreensaverEnabledDescription =>
      'Dimmt den Bildschirm oder schaltet ihn nach einer Zeit der Inaktivität schwarz.';

  @override
  String get settingScreensaverTimeoutSecondsTitle => 'Leerlaufzeit (Sekunden)';

  @override
  String get settingScreensaverTimeoutSecondsDescription =>
      'Dauer der Inaktivität, bevor der Bildschirmschoner aktiviert wird.';

  @override
  String get settingScreensaverModeTitle => 'Bildschirmschoner-Modus';

  @override
  String get settingScreensaverModeDescription =>
      'Legt fest, was der Bildschirmschoner nach Ablauf der Leerlaufzeit anzeigt. „Dimmen“ reduziert lediglich die Helligkeit und lässt das Dashboard sichtbar.';

  @override
  String get settingScreensaverPixelShiftTitle => 'Pixelverschiebung';

  @override
  String get settingScreensaverPixelShiftDescription =>
      'Verschiebt das Bild jede Minute leicht, um OLED-Bildschirme zu schützen. Gilt nicht für den Bildschirmschoner „Schwarz“, da dessen Pixel bereits ausgeschaltet sind.';

  @override
  String get settingScreensaverMenuTitle => 'Im Kiosk-Menü anzeigen';

  @override
  String get settingScreensaverMenuDescription =>
      'Fügt dem Kiosk-Menü die Option „Bildschirmschoner starten“ hinzu.';

  @override
  String get settingScreensaverDimLevelTitle => 'Dimmstufe';

  @override
  String get settingScreensaverDimLevelDescription =>
      'Bildschirmhelligkeit, während der Bildschirmschoner den Bildschirm dimmt.';

  @override
  String get settingScreensaverBrightnessEnabledTitle =>
      'Bildschirmschoner-Helligkeit';

  @override
  String get settingScreensaverBrightnessEnabledDescription =>
      'Verwendet eine andere Bildschirmhelligkeit, solange der Bildschirmschoner aktiv ist.';

  @override
  String get settingScreensaverBrightnessLevelTitle => 'Helligkeitsstufe';

  @override
  String get settingScreensaverBrightnessLevelDescription =>
      'Gilt für alle Modi außer „Dimmen“ und „Schwarz“.';

  @override
  String get settingScreensaverNotificationBrightnessTitle =>
      'Helligkeit bei Benachrichtigungen erhöhen';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      'Reduziert die Abdunklung des Bildschirmschoners, solange eine Benachrichtigung angezeigt wird.';

  @override
  String get settingScreensaverScreenOffMinutesTitle =>
      'Bildschirm ausschalten nach';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Schaltet den Bildschirm aus, wenn der Bildschirmschoner die angegebene Zeit aktiv war. Bei 0 bleibt der Bildschirm dauerhaft eingeschaltet. Erfordert die Geräteadministrator-Berechtigung.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Nach dem Aufwecken zum Bildschirmschoner zurückkehren';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescription =>
      'Nachdem der Bildschirm ausgeschaltet wurde, zeigen Bewegungs-, Gesichts-, Näherungs- oder Personenerkennung zunächst den Bildschirmschoner statt des Dashboards an und starten den Ausschalt-Timer neu. Durch Berühren des Bildschirms wird weiterhin das Dashboard geöffnet.';

  @override
  String get screensaverModeDim => 'Dimmen';

  @override
  String get screensaverModeBlack => 'Schwarz';

  @override
  String get screensaverModeClock => 'Uhr';

  @override
  String get screensaverModeMedia => 'Home-Assistant-Medien';

  @override
  String get screensaverModeLocal => 'Lokale Medien';

  @override
  String get screensaverModeGallery => 'Fotogalerie';

  @override
  String get screensaverModeImmich => 'Immich';

  @override
  String get screensaverModeWebsite => 'Website';

  @override
  String get screensaverModeCamera => 'Kamerastreams';

  @override
  String get screensaverDimSection => 'Bildschirmschoner: Dimmen';

  @override
  String get screensaverWarningTitle =>
      'WARNUNG: Bitte lesen, bevor du fortfährst';

  @override
  String get screensaverScreenOffProceed => 'Bildschirm trotzdem ausschalten';

  @override
  String get screensaverAdminMissing =>
      'Die erforderliche Berechtigung wurde nicht erteilt, daher kann der Bildschirm nicht ausgeschaltet werden.';

  @override
  String get screensaverAdminMissingRemote =>
      'Die Geräteadministrator-Berechtigung fehlt';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      'Ohne diese Berechtigung kann der Bildschirm nicht ausgeschaltet werden. Der Dialog zum Erteilen der Berechtigung wird auf dem Tablet angezeigt.';

  @override
  String get screensaverDimWarning =>
      'WARNUNG: Der Modus „Dimmen“ lässt das Dashboard sichtbar, daher wird die Optimierung „Dashboard während des Bildschirmschoners pausieren“ nicht angewendet. Das Dashboard verbraucht weiterhin CPU-, GPU- und Akkuleistung.';

  @override
  String get screensaverUnavailablePlugin =>
      'Bildschirmschoner eines Plugins nicht verfügbar';

  @override
  String get screensaverScreenOffWarning =>
      'Wenn der Bildschirm vollständig ausgeschaltet wird, übernimmt das Energiemanagement des Tablets die Kontrolle. Viele Android-Geräte zeigen in diesem Zustand Probleme: WLAN wird in den Ruhezustand versetzt oder getrennt, Home-Assistant-Entitäten werden nicht verfügbar, der Kamerazugriff kann verloren gehen und manche Geräte beenden Anwendungen im Hintergrund. Das Verhalten hängt vom Hersteller ab.\n\nDie zuverlässige Alternative ist die Verwendung des Bildschirmschoners „Schwarz“ bei einem Wert von 0 für diese Option. Der Bildschirm wirkt genauso dunkel, während die Anwendung die Kontrolle behält.';

  @override
  String get settingScreensaverScreenOffBlackTitle =>
      'Stattdessen einen schwarzen Bildschirm verwenden';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      'Zeigt einen schwarzen Bildschirm mit auf null gesetzter Helligkeit an, anstatt den Bildschirm auszuschalten. Blendet Widgets und „Jetzt läuft“ aus. Erfordert keine Geräteadministrator-Berechtigung.';

  @override
  String get settingScreensaverGlanceScaleTitle => 'Skalierung der Leiste';

  @override
  String get settingScreensaverGlanceScaleDescription =>
      'Passt die Größe der Leiste an den Bildschirm an.';

  @override
  String get settingScreensaverGlanceFontTitle => 'Schriftart';

  @override
  String get settingScreensaverGlanceFontDescription =>
      'Schriftart der Leiste.';

  @override
  String get settingScreensaverGlanceFontWeightTitle => 'Schriftstärke';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      'Schriftstärke des Textes in der Leiste. Standard verwendet die jeweilige Stärke der einzelnen Zeilen: normal für Namen und halbfett für Werte.';

  @override
  String get settingScreensaverGlanceHideNamesTitle => 'Namen ausblenden';

  @override
  String get settingScreensaverGlanceHideNamesDescription =>
      'Zeigt nur Symbol und Wert an, wobei der Wert größer dargestellt wird.';

  @override
  String get settingScreensaverGlanceBwIconsTitle => 'Einfarbige Symbole';

  @override
  String get settingScreensaverGlanceBwIconsDescription =>
      'Zeigt alle Symbole in neutralem Grau statt in ihrer statusabhängigen Farbe an.';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => 'Schwebender Textstil';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      'Zeigt Entitäten als schwebenden Text statt in Karten an.';

  @override
  String get screensaverOverlayAppearance => 'Darstellung';

  @override
  String get settingScreensaverGlanceEnabledTitle => 'Auf einen Blick';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      'Zeigt eine Zeile mit Home-Assistant-Entitätsstatus auf dem Bildschirmschoner an.';

  @override
  String get settingScreensaverGlanceEntitiesTitle => 'Entitäten';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      'Bis zu vier anzuzeigende Entitäten, jeweils mit optionalem benutzerdefiniertem Namen.';

  @override
  String get settingScreensaverGlanceNowPlayingTitle =>
      'In „Jetzt läuft“ anzeigen';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      'Zeigt die Leiste in der Vollbildansicht „Jetzt läuft“ an. Sie wird ausgeblendet, während Songtexte angezeigt werden.';

  @override
  String get screensaverOverlayShowing => 'Angezeigte Entitäten';

  @override
  String get screensaverOverlayReorder =>
      'Angezeigte Entitäten (zum Neuordnen ziehen)';

  @override
  String get screensaverOverlayFull =>
      'Die Leiste enthält bereits die maximale Anzahl an Entitäten. Entferne eine, um eine weitere hinzuzufügen.';

  @override
  String get screensaverOverlayPickerTitle => '„Auf einen Blick“-Entitäten';

  @override
  String screensaverOverlayGlanceEmpty(String count) {
    return 'Noch keine vorhanden. Bis zu $count Entitäten.';
  }

  @override
  String get screensaverOverlayNone => 'Noch keine vorhanden';

  @override
  String screensaverOverlayLimit(String count) {
    return 'Bis zu $count Entitäten.';
  }

  @override
  String get screensaverOverlayGlancePage => 'Auf einen Blick';

  @override
  String get screensaverOverlayGlanceHint =>
      'Entitäten, die über dem Bildschirmschoner angezeigt werden';

  @override
  String get glanceUnavailable => 'Nicht verfügbar';

  @override
  String get glanceUnknown => 'Unbekannt';

  @override
  String get settingScreensaverImmichUrlTitle => 'Serveradresse';

  @override
  String get settingScreensaverImmichUrlDescription =>
      'Adresse des Immich-Servers einschließlich Port.';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'API-Schlüssel';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      'Wird in Immich unter Kontoeinstellungen → API-Schlüssel erstellt.';

  @override
  String get screensaverMediaImmichPage => 'Bildschirmschoner: Immich';

  @override
  String get screensaverMediaImmichHint =>
      'Server, Medieninhalte, Diashow, Metadaten und Filter';

  @override
  String get screensaverMediaServerConnection => 'Serververbindung';

  @override
  String get screensaverMediaValidateFailedLog =>
      'Die Validierung ist fehlgeschlagen. Sieh im Anwendungsprotokoll nach, welcher Aufruf fehlgeschlagen ist.';

  @override
  String get screensaverMediaValidateFailed =>
      'Die Validierung ist fehlgeschlagen.';

  @override
  String get screensaverMediaNoAnswer => 'Das Gerät hat nicht geantwortet.';

  @override
  String get screensaverMediaAddressFirst =>
      'Bitte zuerst die Serveradresse eingeben.';

  @override
  String get screensaverMediaKeyFirst =>
      'Bitte zuerst einen API-Schlüssel eingeben.';

  @override
  String get screensaverMediaBadAddress =>
      'Die Serveradresse ist keine gültige URL.';

  @override
  String get screensaverMediaKeyRejected =>
      'Der API-Schlüssel wurde abgelehnt.';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'Dem API-Schlüssel fehlt die Berechtigung $scope.';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'Dem API-Schlüssel fehlt eine Berechtigung: $error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return 'Der Server antwortete mit $status: $error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return 'Verbindung zu $url nicht möglich.';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return 'Kommunikation mit dem Server fehlgeschlagen: $error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => 'Personen';

  @override
  String get settingScreensaverImmichPeopleDescription =>
      'Zeigt nur Inhalte an, auf denen mindestens eine dieser Personen erscheint.';

  @override
  String get settingScreensaverImmichExcludePeopleTitle =>
      'Personen ausschließen';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      'Überspringt Inhalte, auf denen mindestens eine dieser Personen erscheint.';

  @override
  String get settingScreensaverImmichTagsTitle => 'Tags';

  @override
  String get settingScreensaverImmichTagsDescription =>
      'Zeigt nur Inhalte mit mindestens einem dieser Tags an.';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => 'Tags ausschließen';

  @override
  String get settingScreensaverImmichExcludeTagsDescription =>
      'Überspringt Inhalte mit mindestens einem dieser Tags.';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => 'Nur Favoriten';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      'Zeigt nur als Favorit markierte Inhalte an.';

  @override
  String get settingScreensaverImmichTakenWithinTitle => 'Aufnahmedatum';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      'Zeigt nur Inhalte an, die innerhalb dieses Zeitraums aufgenommen wurden.';

  @override
  String get settingScreensaverImmichTakenFromTitle => 'Ab';

  @override
  String get settingScreensaverImmichTakenFromDescription =>
      'Überspringt Inhalte, die vor diesem Datum aufgenommen wurden.';

  @override
  String get settingScreensaverImmichTakenToTitle => 'Bis';

  @override
  String get settingScreensaverImmichTakenToDescription =>
      'Überspringt Inhalte, die nach diesem Datum aufgenommen wurden. Der angegebene Tag wird eingeschlossen.';

  @override
  String get screensaverMediaFilters => 'Filter';

  @override
  String get screensaverMediaAnyone => 'Beliebige Person';

  @override
  String get screensaverMediaAnyoneDevice => 'Beliebige Person.';

  @override
  String get screensaverMediaNoOne => 'Keine Person';

  @override
  String get screensaverMediaNoOneDevice => 'Keine Person.';

  @override
  String get screensaverMediaAny => 'Beliebig';

  @override
  String get screensaverMediaAnyDevice => 'Beliebig.';

  @override
  String get screensaverMediaNoTagsChosen => 'Keine Tags';

  @override
  String get screensaverMediaNoTagsChosenDevice => 'Keine Tags.';

  @override
  String get screensaverMediaNoPeople =>
      'Es sind noch keine benannten Personen vorhanden. Vergib ihnen zuerst Namen in Immich.';

  @override
  String get screensaverMediaNoTags =>
      'Es sind noch keine Tags vorhanden. Erstelle sie zuerst in Immich.';

  @override
  String get screensaverMediaPeopleFailed =>
      'Die Personen konnten nicht aufgelistet werden';

  @override
  String get screensaverMediaTagsFailed =>
      'Die Tags konnten nicht aufgelistet werden';

  @override
  String get screensaverMediaHidden => 'Ausgeblendet';

  @override
  String get screensaverMediaAnyTime => 'Beliebiges Datum';

  @override
  String get screensaverMediaPastMonth => 'Letzter Monat';

  @override
  String get screensaverMediaPast3Months => 'Letzte 3 Monate';

  @override
  String get screensaverMediaPastYear => 'Letztes Jahr';

  @override
  String get screensaverMediaPast2Years => 'Letzte 2 Jahre';

  @override
  String get screensaverMediaPast5Years => 'Letzte 5 Jahre';

  @override
  String get screensaverMediaPast10Years => 'Letzte 10 Jahre';

  @override
  String get screensaverMediaSince => 'Seit einem Datum';

  @override
  String get screensaverMediaTimeframe => 'Zeitraum';

  @override
  String get screensaverMediaToday => 'Heute';

  @override
  String get screensaverMediaDateFormat => 'Verwende das Format JJJJ-MM-TT.';

  @override
  String get screensaverMediaNotDate => 'Ungültiges Datum.';

  @override
  String get settingScreensaverImmichMetadataTitle => 'Metadaten anzeigen';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      'Zeigt Album, Aufnahmedatum, Kameradaten und Standort über den Medieninhalten an.';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => 'Albumname';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription =>
      'Zeigt an, aus welchem Album das Foto stammt.';

  @override
  String get settingScreensaverImmichMetadataDateTitle => 'Aufnahmedatum';

  @override
  String get settingScreensaverImmichMetadataDateDescription =>
      'Zeigt an, wann das Foto aufgenommen wurde.';

  @override
  String get settingScreensaverImmichMetadataCameraTitle => 'Kameradetails';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      'Zeigt Brennweite, Blende und ISO-Wert an.';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => 'Standort';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      'Zeigt an, wo das Foto aufgenommen wurde.';

  @override
  String get settingScreensaverImmichMetadataPositionTitle =>
      'Position der Metadaten';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      'Die Ecke, in der die Details angezeigt werden.';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle => 'Textschatten';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      'Fügt dem Metadatentext einen Schatten hinzu, um die Lesbarkeit auf Fotos zu verbessern.';

  @override
  String get settingScreensaverImmichMetadataScaleTitle => 'Textgröße';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      'Passt die Größe der Fotodetails an den Bildschirm an.';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle =>
      'Intensität der Abdunklung';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      'Stärke der Abdunklung hinter den Details, um die Lesbarkeit auf hellen Fotos zu verbessern. Bei 0 ist sie deaktiviert.';

  @override
  String get screensaverMediaMetadata => 'Metadaten';

  @override
  String get screensaverMediaTopLeft => 'Oben links';

  @override
  String get screensaverMediaTopRight => 'Oben rechts';

  @override
  String get screensaverMediaBottomLeft => 'Unten links';

  @override
  String get screensaverMediaBottomRight => 'Unten rechts';

  @override
  String get settingScreensaverImmichIntervalTitle => 'Sekunden pro Bild';

  @override
  String get settingScreensaverImmichIntervalDescription =>
      'Wie lange jedes Bild angezeigt wird, bevor zum nächsten gewechselt wird. Videos werden vollständig abgespielt.';

  @override
  String get settingScreensaverImmichShuffleTitle => 'Zufällige Reihenfolge';

  @override
  String get settingScreensaverImmichShuffleDescription =>
      'Durchläuft die Medieninhalte in zufälliger Reihenfolge.';

  @override
  String get settingScreensaverImmichTransitionTitle => 'Übergang';

  @override
  String get settingScreensaverImmichTransitionDescription =>
      'Legt fest, wie von einem Inhalt zum nächsten gewechselt wird.';

  @override
  String get settingScreensaverImmichFillTitle => 'Bildschirm ausfüllen';

  @override
  String get settingScreensaverImmichFillDescription =>
      'Deaktiviert zeigt das vollständige Foto mit schwarzen Balken an. Intelligent vergrößert Fotos mit einem ähnlichen Seitenverhältnis wie der Bildschirm und zeigt andere auf einem unscharfen Hintergrund an. Immer vergrößert alle Fotos und schneidet überstehende Bereiche ab.';

  @override
  String get settingScreensaverImmichPairPortraitTitle =>
      'Hochformatfotos kombinieren';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      'Zeigt zwei Hochformatfotos nebeneinander an, um den Bildschirm besser auszufüllen.';

  @override
  String get settingScreensaverImmichPairLandscapeTitle =>
      'Querformatfotos kombinieren';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      'Zeigt zwei Querformatfotos übereinander an, um einen Bildschirm im Hochformat besser auszufüllen.';

  @override
  String get settingScreensaverImmichEdgeTapsTitle =>
      'Zum Bildwechsel auf die Bildschirmränder tippen';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      'Ein Tippen auf das linke oder rechte Fünftel des Bildschirms zeigt das vorherige bzw. nächste Bild an, anstatt den Bildschirmschoner zu schließen.';

  @override
  String get screensaverMediaSlideshow => 'Diashow';

  @override
  String get settingScreensaverImmichAlbumTitle => 'Medienquelle';

  @override
  String get settingScreensaverImmichAlbumDescription =>
      'Die gesamte Bibliothek oder die von dir ausgewählten Alben.';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => 'Nur Fotos';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription =>
      'Überspringt Videos in der Diashow.';

  @override
  String get settingScreensaverImmichCacheTitle =>
      'Inhalte lokal zwischenspeichern';

  @override
  String get settingScreensaverImmichCacheDescription =>
      'Speichert Kopien auf dem Gerät, damit Bilder sofort geladen werden.';

  @override
  String get settingScreensaverImmichCacheMaxTitle => 'Cache-Größe (Elemente)';

  @override
  String get settingScreensaverImmichCacheMaxDescription =>
      'Entfernt die ältesten Elemente, wenn der Cache voll ist.';

  @override
  String get screensaverMediaAll => 'Alle Inhalte';

  @override
  String get screensaverMediaAllDevice => 'Alle Inhalte.';

  @override
  String get screensaverMediaNoAlbums =>
      'Es sind noch keine Alben vorhanden. Erstelle zuerst ein Album in Immich.';

  @override
  String get screensaverMediaAlbumsFailed =>
      'Die Alben konnten nicht aufgelistet werden';

  @override
  String screensaverMediaListError(String error) {
    return 'Die Elemente konnten nicht aufgelistet werden: $error';
  }

  @override
  String get screensaverMediaListingFailed =>
      'Die Elemente konnten nicht aufgelistet werden';

  @override
  String screensaverMediaItems(String count) {
    return '$count Elemente';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return '$count im Cache, $size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => 'Kameraansichten';

  @override
  String get settingScreensaverCameraViewsDescription =>
      'Kameraansichten, die vom Bildschirmschoner in dieser Reihenfolge angezeigt werden.';

  @override
  String get settingScreensaverCameraViewSecondsTitle =>
      'Sekunden pro Kameraansicht';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      'Wie lange jede Ansicht angezeigt wird, bevor zur nächsten gewechselt wird. Wenn nur eine Ansicht ausgewählt ist, findet keine Rotation statt.';

  @override
  String get settingScreensaverCameraMuteTitle =>
      'Alle Ansichten stummschalten';

  @override
  String get settingScreensaverCameraMuteDescription =>
      'Hält alle Ansichten stumm, auch Einzelkamera-Ansichten.';

  @override
  String get screensaverMediaCameraPage => 'Bildschirmschoner: Kamerastreams';

  @override
  String get screensaverMediaCameraHint =>
      'Angezeigte Ansichten, Anzeigedauer pro Ansicht und Ton';

  @override
  String get screensaverMediaNoCameras =>
      'Noch keine Ansicht enthält Kameras. Füge eine unter „Kamerastreams“ hinzu.';

  @override
  String get screensaverMediaNoCamerasRemote =>
      'Noch keine Ansicht enthält Kameras';

  @override
  String get screensaverMediaAddCameras =>
      'Füge eine unter „Kamerastreams“ hinzu.';

  @override
  String get screensaverMediaNoViews =>
      'Es wurden noch keine Ansichten ausgewählt. Wähle die Ansichten aus, die der Bildschirmschoner durchlaufen soll.';

  @override
  String get screensaverMediaRotation =>
      'In der Rotation (zum Neuordnen ziehen)';

  @override
  String get screensaverMediaAvailable => 'Verfügbar';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count Kamera';
  }

  @override
  String screensaverMediaCameras(String count) {
    return '$count Kameras';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return 'Position $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => 'Keine';

  @override
  String get screensaverMediaTransitionFade => 'Überblendung';

  @override
  String get screensaverMediaTransitionSlide => 'Verschieben';

  @override
  String get screensaverMediaTransitionZoom => 'Zoom';

  @override
  String get screensaverMediaTransitionKenBurns => 'Ken-Burns-Effekt';

  @override
  String get screensaverMediaTransitionRandom => 'Zufällig';

  @override
  String get screensaverMediaFillOff => 'Deaktiviert';

  @override
  String get screensaverMediaFillSmart => 'Intelligent';

  @override
  String get screensaverMediaFillAlways => 'Immer';

  @override
  String get settingScreensaverGalleryItemsTitle => 'Fotos';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'Fotos und Videos, die dieser Bildschirmschoner anzeigt. Sie werden aus der Galerie des Geräts ausgewählt. Eine neue Auswahl ersetzt die bisherige.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Sekunden pro Foto';

  @override
  String get settingScreensaverGalleryIntervalDescription =>
      'Wie lange jedes Foto angezeigt wird, bevor zum nächsten gewechselt wird. Videos werden vollständig abgespielt.';

  @override
  String get settingScreensaverGalleryShuffleTitle => 'Zufällige Reihenfolge';

  @override
  String get settingScreensaverGalleryShuffleDescription =>
      'Durchläuft die Auswahl in zufälliger Reihenfolge.';

  @override
  String get settingScreensaverGalleryTransitionTitle => 'Übergang';

  @override
  String get settingScreensaverGalleryTransitionDescription =>
      'Legt fest, wie von einem Foto zum nächsten gewechselt wird.';

  @override
  String get settingScreensaverGalleryFillTitle => 'Bildschirm ausfüllen';

  @override
  String get settingScreensaverGalleryFillDescription =>
      'Deaktiviert zeigt das vollständige Foto mit schwarzen Balken an. Intelligent vergrößert Fotos mit einem ähnlichen Seitenverhältnis wie der Bildschirm und zeigt andere auf einem unscharfen Hintergrund an. Immer vergrößert alle Fotos und schneidet überstehende Bereiche ab.';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle =>
      'Zum Bildwechsel auf die Bildschirmränder tippen';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      'Ein Tippen auf das linke oder rechte Fünftel des Bildschirms zeigt das vorherige bzw. nächste Bild an, anstatt den Bildschirmschoner zu schließen.';

  @override
  String get screensaverMediaGalleryPage => 'Bildschirmschoner: Fotogalerie';

  @override
  String get screensaverMediaGalleryHint =>
      'Fotos, Anzeigedauer, Zufallswiedergabe und Übergänge';

  @override
  String get screensaverMediaLoadingPhotos => 'Fotos werden geladen...';

  @override
  String screensaverMediaCopying(String index, String total) {
    return 'Foto $index von $total wird kopiert...';
  }

  @override
  String get screensaverMediaCopyFailed =>
      'Die Fotos konnten nicht kopiert werden';

  @override
  String get screensaverMediaSmallerSelection =>
      'Versuche es mit einer kleineren Auswahl.';

  @override
  String get screensaverMediaNoPhotos => 'Es wurden keine Fotos ausgewählt';

  @override
  String screensaverMediaSelected(String count) {
    return '$count ausgewählt';
  }

  @override
  String get screensaverMediaPickOnDevice =>
      'Es wurden keine Elemente ausgewählt. Bitte wähle sie auf dem Gerät aus.';

  @override
  String get settingScreensaverMediaIdTitle => 'Medienquelle';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Medienobjekt, Ordner oder Kamera aus Home Assistant. Verwende „Durchsuchen“, um eine Auswahl zu treffen.';

  @override
  String get settingScreensaverMediaIntervalTitle => 'Sekunden pro Bild';

  @override
  String get settingScreensaverMediaIntervalDescription =>
      'Wie lange jedes Bild angezeigt wird, bevor zum nächsten gewechselt wird. Videos werden vollständig abgespielt.';

  @override
  String get settingScreensaverMediaShuffleTitle => 'Zufällige Reihenfolge';

  @override
  String get settingScreensaverMediaShuffleDescription =>
      'Gibt die Inhalte eines Ordners in zufälliger Reihenfolge wieder.';

  @override
  String get settingScreensaverMediaRecursiveTitle => 'Unterordner einbeziehen';

  @override
  String get settingScreensaverMediaRecursiveDescription =>
      'Bezieht die Unterordner des ausgewählten Ordners mit ein.';

  @override
  String get settingScreensaverMediaTransitionTitle => 'Übergang';

  @override
  String get settingScreensaverMediaTransitionDescription =>
      'Legt fest, wie von einem Element zum nächsten gewechselt wird.';

  @override
  String get settingScreensaverMediaFillTitle => 'Bildschirm ausfüllen';

  @override
  String get settingScreensaverMediaFillDescription =>
      'Deaktiviert zeigt das vollständige Foto mit schwarzen Balken an. Intelligent vergrößert Fotos mit einem ähnlichen Seitenverhältnis wie der Bildschirm und zeigt andere auf einem unscharfen Hintergrund an. Immer vergrößert alle Fotos und schneidet überstehende Bereiche ab.';

  @override
  String get settingScreensaverMediaEdgeTapsTitle =>
      'Zum Bildwechsel auf die Bildschirmränder tippen';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      'Ein Tippen auf das linke oder rechte Fünftel des Bildschirms zeigt das vorherige bzw. nächste Bild an, anstatt den Bildschirmschoner zu schließen.';

  @override
  String get screensaverMediaHaPage =>
      'Bildschirmschoner: Home-Assistant-Medien';

  @override
  String get screensaverMediaHaHint =>
      'Medienquelle, Anzeigedauer, Zufallswiedergabe und Bildanpassung';

  @override
  String get screensaverMediaChoose => 'Medien auswählen';

  @override
  String get screensaverMediaRoot => 'Medien';

  @override
  String get screensaverMediaHaUnavailable =>
      'Verbindung zu Home Assistant nicht möglich oder Token fehlt.';

  @override
  String get screensaverMediaEmpty => 'Hier sind keine Elemente vorhanden.';

  @override
  String get screensaverMediaUseFolder => 'Diesen Ordner verwenden';

  @override
  String get screensaverMediaFolder => 'Ordner';

  @override
  String get screensaverMediaCamera => 'Kamera';

  @override
  String get screensaverMediaItem => 'Element';

  @override
  String get screensaverMediaBrowseFailed =>
      'Die Inhalte konnten nicht durchsucht werden';

  @override
  String screensaverMediaBrowseError(String error) {
    return 'Die Inhalte konnten nicht durchsucht werden: $error';
  }

  @override
  String get screensaverMediaNotSet => 'Nicht festgelegt';

  @override
  String get settingScreensaverLocalFolderTitle => 'Lokaler Ordner';

  @override
  String get settingScreensaverLocalFolderDescription =>
      'Ordner auf diesem Gerät, dessen Fotos und Videos vom Bildschirmschoner angezeigt werden. Die Auswahl erfolgt auf dem Gerät. Über die Fernverwaltung kann auch ein Pfad eingegeben werden.';

  @override
  String get settingScreensaverLocalIntervalTitle => 'Sekunden pro Foto';

  @override
  String get settingScreensaverLocalIntervalDescription =>
      'Wie lange jedes Foto angezeigt wird, bevor zum nächsten gewechselt wird. Videos werden vollständig abgespielt.';

  @override
  String get settingScreensaverLocalShuffleTitle => 'Zufällige Reihenfolge';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      'Durchläuft den Ordner in zufälliger Reihenfolge, anstatt nach Namen zu sortieren.';

  @override
  String get settingScreensaverLocalRecursiveTitle => 'Unterordner einbeziehen';

  @override
  String get settingScreensaverLocalRecursiveDescription =>
      'Bezieht auch Fotos und Videos aus Unterordnern mit ein.';

  @override
  String get settingScreensaverLocalTransitionTitle => 'Übergang';

  @override
  String get settingScreensaverLocalTransitionDescription =>
      'Legt fest, wie von einem Foto zum nächsten gewechselt wird.';

  @override
  String get settingScreensaverLocalFillTitle => 'Bildschirm ausfüllen';

  @override
  String get settingScreensaverLocalFillDescription =>
      'Deaktiviert zeigt das vollständige Foto mit schwarzen Balken an. Intelligent vergrößert Fotos mit einem ähnlichen Seitenverhältnis wie der Bildschirm und zeigt andere auf einem unscharfen Hintergrund an. Immer vergrößert alle Fotos und schneidet überstehende Bereiche ab.';

  @override
  String get settingScreensaverLocalEdgeTapsTitle =>
      'Zum Bildwechsel auf die Bildschirmränder tippen';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      'Ein Tippen auf das linke oder rechte Fünftel des Bildschirms zeigt das vorherige bzw. nächste Bild an, anstatt den Bildschirmschoner zu schließen.';

  @override
  String get screensaverMediaLocalPage => 'Bildschirmschoner: Lokale Medien';

  @override
  String get screensaverMediaLocalHint =>
      'Ordner, Anzeigedauer, Zufallswiedergabe und Übergänge';

  @override
  String get settingScreensaverDismissOnMotionTitle =>
      'Bei Bewegungserkennung schließen';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      'Verwendet die Kamera, während der Bildschirmschoner angezeigt wird, und aktiviert den Bildschirm, wenn sich jemand nähert. Die Kamera ist nur während des Bildschirmschoners aktiv.';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle =>
      'Nur bei ausgeschaltetem Bildschirm';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      'Lässt den Bildschirmschoner sichtbar, wenn bei eingeschaltetem Bildschirm eine Bewegung erkannt wird. Ist der Bildschirm ausgeschaltet, öffnet die Erkennung das Dashboard. Durch Berühren des Bildschirms wird der Bildschirmschoner weiterhin geschlossen.';

  @override
  String get settingScreensaverPostponeOnMotionTitle =>
      'Bildschirmschoner bei Bewegungserkennung verschieben';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      'Verzögert die Aktivierung des Bildschirmschoners, wenn Bewegung erkannt wird. WARNUNG: Die Kamera bleibt dadurch dauerhaft eingeschaltet.';

  @override
  String get screensaverDetectionMotionPage => 'Bewegungserkennung';

  @override
  String get screensaverDetectionMotionHint =>
      'Bildschirmschoner bei Bewegungserkennung schließen oder verzögern';

  @override
  String get screensaverDetectionMotionTuning =>
      'Die Bewegungserkennung wird in den Kamera-Einstellungen konfiguriert.';

  @override
  String get settingScreensaverDismissOnPersonTitle =>
      'Bei Personenerkennung schließen';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      'Verwendet den Anwesenheitssensor des Geräts, während der Bildschirmschoner aktiv ist, und aktiviert den Bildschirm, wenn sich jemand davor befindet. Erfordert die unten aufgeführte Berechtigung „Zugriff auf Protokolle“.';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle =>
      'Nur bei ausgeschaltetem Bildschirm';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      'Lässt den Bildschirmschoner sichtbar, wenn bei eingeschaltetem Bildschirm eine Person erkannt wird. Ist der Bildschirm ausgeschaltet, öffnet die Erkennung das Dashboard. Durch Berühren des Bildschirms wird der Bildschirmschoner weiterhin geschlossen.';

  @override
  String get settingScreensaverPostponeOnPersonTitle =>
      'Bildschirmschoner bei Personenerkennung verschieben';

  @override
  String get settingScreensaverPostponeOnPersonDescription =>
      'Verzögert die Aktivierung des Bildschirmschoners, solange sich jemand vor dem Gerät befindet.';

  @override
  String get screensaverDetectionPersonPage => 'Personenerkennung';

  @override
  String get screensaverDetectionPersonHint =>
      'Schließt oder verzögert den Bildschirmschoner mithilfe des Anwesenheitssensors des Geräts';

  @override
  String get screensaverDetectionOccupancy => 'Anwesenheit';

  @override
  String get screensaverDetectionStatusUnavailable => 'Status nicht verfügbar.';

  @override
  String get screensaverDetectionOff => 'Deaktiviert.';

  @override
  String get screensaverDetectionStarting => 'Wird gestartet...';

  @override
  String get screensaverDetectionWaiting =>
      'Warte auf das erste Signal des Sensors. Der Sensor meldet alle 30 Sekunden, solange sich jemand im Erfassungsbereich befindet.';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return 'Letztes Sensorsignal: $ago.';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return 'vor $count Sek.';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return 'vor $count Min.';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return 'vor $count Std.';
  }

  @override
  String get screensaverDetectionDetected => 'Person erkannt';

  @override
  String get screensaverDetectionClear => 'Keine Person erkannt';

  @override
  String get screensaverDetectionPermissions =>
      'Erforderliche Systemberechtigungen';

  @override
  String get screensaverDetectionLogAccess => 'Zugriff auf Protokolle';

  @override
  String get screensaverDetectionChecking => 'Wird geprüft...';

  @override
  String get screensaverDetectionReadable =>
      'Der Anwesenheitssensor des Geräts kann ausgelesen werden.';

  @override
  String get screensaverDetectionRestartRequired =>
      'Erteilt. Starte Kiosk Satellite neu, damit die Änderung wirksam wird.';

  @override
  String get screensaverDetectionGrantHelp =>
      'Diese Berechtigung kann nur per ADB erteilt werden. Die Meta-Portal-Dokumentation enthält den vollständigen Befehl. Starte anschließend Kiosk Satellite neu.';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      'Diese Berechtigung kann nur per ADB erteilt werden. Unten findest du den vollständigen Befehl zum Kopieren. Starte anschließend Kiosk Satellite neu.';

  @override
  String get screensaverDetectionGranted => 'Erteilt';

  @override
  String get screensaverDetectionMissing => 'Berechtigung fehlt';

  @override
  String get screensaverDetectionRestart => 'Neu starten';

  @override
  String get screensaverDetectionRestartRemote =>
      'Kiosk Satellite auf dem Gerät neu starten';

  @override
  String get screensaverDetectionLogRestart =>
      'Der Protokollzugriff wurde erteilt, wird aber erst nach einem Neustart von Kiosk Satellite wirksam.';

  @override
  String get screensaverDetectionLogMissing =>
      'Der Zugriff auf die Protokolle wurde nicht erteilt.';

  @override
  String get settingScreensaverDismissOnProximityTitle =>
      'Bei Annäherung schließen';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      'Verwendet den Näherungssensor, während der Bildschirmschoner aktiv ist, und aktiviert den Bildschirm, wenn sich etwas dem Gerät nähert. Sensoren, die nur für Anrufe gedacht sind, wie „palm“ oder „touch“, eignen sich nicht für diese Funktion.';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle =>
      'Nur bei ausgeschaltetem Bildschirm';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      'Lässt den Bildschirmschoner sichtbar, wenn sich bei eingeschaltetem Bildschirm etwas nähert. Ist der Bildschirm ausgeschaltet, öffnet die Erkennung das Dashboard. Durch Berühren des Bildschirms wird der Bildschirmschoner weiterhin geschlossen.';

  @override
  String get settingScreensaverPostponeOnProximityTitle =>
      'Bildschirmschoner bei Annäherung verschieben';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      'Verzögert die Aktivierung des Bildschirmschoners, solange sich etwas in der Nähe des Sensors befindet.';

  @override
  String get screensaverDetectionProximityPage => 'Näherungserkennung';

  @override
  String get screensaverDetectionProximityHint =>
      'Schließt oder verzögert den Bildschirmschoner mithilfe des Näherungssensors';

  @override
  String get screensaverDetectionNoProximity =>
      'Auf diesem Gerät nicht verfügbar: Es besitzt keinen Näherungssensor.';

  @override
  String get screensaverDetectionSensor => 'Sensor';

  @override
  String get screensaverDetectionSensorHelp =>
      'Der vom Gerät gemeldete Näherungssensor. Ein für Telefongespräche vorgesehener Sensor mit der Bezeichnung „palm“ oder „touch“ eignet sich nicht für diese Funktion.';

  @override
  String get settingScreensaverScheduleEnabledTitle =>
      'Geplante Bildschirmschoner aktivieren';

  @override
  String get settingScreensaverScheduleEnabledDescription =>
      'Wechselt zu bestimmten Tageszeiten zu einem anderen Bildschirmschoner.';

  @override
  String get settingScreensaverScheduleTitle => 'Zeitpläne';

  @override
  String get settingScreensaverScheduleDescription =>
      'Jede Uhrzeit legt fest, ab wann dieser Bildschirmschoner verwendet wird.';

  @override
  String get screensaverScheduleSection => 'Geplante Bildschirmschoner';

  @override
  String get screensaverTime => 'Uhrzeit';

  @override
  String get screensaverAddTime => 'Uhrzeit hinzufügen';

  @override
  String get screensaverRemoveTime => 'Uhrzeit entfernen';

  @override
  String get screensaverNoTimes => 'Noch keine Zeitpläne vorhanden';

  @override
  String get screensaverTimeHelp =>
      'Bildschirmschoner, der ab dieser Uhrzeit verwendet wird.';

  @override
  String get screensaverPickTime => 'Bitte eine Uhrzeit auswählen.';

  @override
  String get screensaverDefault => 'Standard';

  @override
  String get screensaverOn => 'Aktiviert';

  @override
  String get screensaverOff => 'Deaktiviert';

  @override
  String get screensaverBrightness => 'Helligkeit';

  @override
  String get screensaverBrightnessFollow =>
      'Verwendet die Einstellung „Bildschirmschoner-Helligkeit“.';

  @override
  String get screensaverBrightnessExceptBlack =>
      'Gilt für alle Modi außer „Schwarz“.';

  @override
  String get screensaverScreenOffFollow =>
      'Verwendet die Einstellung „Bildschirm ausschalten nach“.';

  @override
  String get screensaverScreenOnHours =>
      'Hält den Bildschirm während dieser Zeiten eingeschaltet.';

  @override
  String get screensaverScreenOffHelp =>
      'Schaltet den Bildschirm aus, wenn der Bildschirmschoner so lange aktiv war. Erfordert die Geräteadministrator-Berechtigung.';

  @override
  String get screensaverScreenOffNever => 'Bildschirm nicht ausschalten';

  @override
  String get screensaverMotion => 'Bei Bewegungserkennung schließen';

  @override
  String get screensaverFace => 'Bei Gesichtserkennung schließen';

  @override
  String get screensaverProximity => 'Bei Annäherung schließen';

  @override
  String get screensaverPerson => 'Bei Personenerkennung schließen';

  @override
  String get screensaverWidgets => 'Widgets';

  @override
  String get screensaverGlance => 'Auf einen Blick';

  @override
  String get screensaverNowPlaying =>
      '„Jetzt läuft“ neben dem Bildschirmschoner anzeigen';

  @override
  String get screensaverNowPlayingHelp =>
      'Standard folgt dem allgemeinen Layout. Aktiviert teilt den Bildschirm, wenn „Jetzt läuft“ aktiviert ist. Deaktiviert blendet „Jetzt läuft“ während dieser Zeiten aus.';

  @override
  String get screensaverCameraRequired =>
      'Benötigt eine Kamera. Aktiviere sie zuerst in den Kamera-Einstellungen.';

  @override
  String get screensaverNotAvailable => 'Auf diesem Gerät nicht verfügbar.';

  @override
  String get screensaverSummaryMotionOn => 'Bewegung: aktiviert';

  @override
  String get screensaverSummaryMotionOff => 'Bewegung: deaktiviert';

  @override
  String get screensaverSummaryFaceOn => 'Gesichter: aktiviert';

  @override
  String get screensaverSummaryFaceOff => 'Gesichter: deaktiviert';

  @override
  String get screensaverSummaryProximityOn => 'Annäherung: aktiviert';

  @override
  String get screensaverSummaryProximityOff => 'Annäherung: deaktiviert';

  @override
  String get screensaverSummaryPersonOn => 'Personen: aktiviert';

  @override
  String get screensaverSummaryPersonOff => 'Personen: deaktiviert';

  @override
  String get screensaverSummaryWidgetsOn => 'Widgets: aktiviert';

  @override
  String get screensaverSummaryWidgetsOff => 'Widgets: deaktiviert';

  @override
  String get screensaverSummaryGlanceOn => 'Auf einen Blick: aktiviert';

  @override
  String get screensaverSummaryGlanceOff => 'Auf einen Blick: deaktiviert';

  @override
  String get screensaverSummaryNowPlayingOn => 'Jetzt läuft: aktiviert';

  @override
  String get screensaverSummaryNowPlayingOff => 'Jetzt läuft: deaktiviert';

  @override
  String screensaverBrightnessPercent(String percent) {
    return 'Helligkeit $percent %';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return 'Bildschirm ausschalten nach $minutes Min.';
  }

  @override
  String get screensaverWeatherMood => 'Wetterstimmung';

  @override
  String get screensaverWeatherMoodPage => 'Bildschirmschoner Wetterstimmung';

  @override
  String get screensaverWeatherMoodSummary => 'Wetterentität, Blitze, Vorschau';

  @override
  String get settingScreensaverWeatherEntityTitle => 'Wetterentität';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      'Die Home Assistant-Wetterentität, die die animierte Szene steuert. Tag, Morgen-/Abenddämmerung und Nacht richten sich nach sun.sun. Als Ersatz dient die lokale Uhrzeit.';

  @override
  String get settingScreensaverWeatherLightningTitle => 'Blitze';

  @override
  String get settingScreensaverWeatherLightningDescription =>
      'Blitze und aufleuchtende Wolken bei Gewittern anzeigen.';

  @override
  String get screensaverWeatherMoodSelectEntity =>
      'Wähle eine Wetterentität unter Einstellungen > Bildschirmschoner > Wetterstimmung aus.';

  @override
  String get screensaverWeatherPreviewGroup => 'Wettervorschau';

  @override
  String get settingScreensaverWeatherPreviewTitle =>
      'Wettervorschau aktivieren';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      'Zeigt die ausgewählte Szene statt des aktuellen Wetters. Deaktiviere die Vorschau, um wieder Home Assistant zu folgen.';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => 'Wettertyp';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      'Die animierte Wetterszene für die Vorschau.';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle => 'Tageszeit';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      'Die Szene bei Tag, in der Morgen-/Abenddämmerung oder bei Nacht anzeigen.';

  @override
  String get screensaverWeatherPreviewSunny => 'Klar';

  @override
  String get screensaverWeatherPreviewPartlycloudy => 'Teilweise bewölkt';

  @override
  String get screensaverWeatherPreviewCloudy => 'Bewölkt';

  @override
  String get screensaverWeatherPreviewRainy => 'Regen';

  @override
  String get screensaverWeatherPreviewPouring => 'Starkregen';

  @override
  String get screensaverWeatherPreviewSnowy => 'Schnee';

  @override
  String get screensaverWeatherPreviewSnowyRainy => 'Schnee und Regen';

  @override
  String get screensaverWeatherPreviewFog => 'Nebel';

  @override
  String get screensaverWeatherPreviewHail => 'Hagel';

  @override
  String get screensaverWeatherPreviewLightning => 'Blitze';

  @override
  String get screensaverWeatherPreviewLightningRainy => 'Blitze und Regen';

  @override
  String get screensaverWeatherPreviewWindy => 'Wind';

  @override
  String get screensaverWeatherPreviewWindyVariant => 'Wind und Wolken';

  @override
  String get screensaverWeatherPreviewExceptional => 'Außergewöhnliches Wetter';

  @override
  String get screensaverWeatherPreviewDay => 'Tag';

  @override
  String get screensaverWeatherPreviewNight => 'Nacht';

  @override
  String get settingScreensaverWeatherClockTitle => 'Uhr aktivieren';

  @override
  String get settingScreensaverWeatherClockDescription =>
      'Eine digitale Uhr über der Wetterszene anzeigen.';

  @override
  String get screensaverWeatherTextShadowDescription =>
      'Einen Textschatten hinzufügen, damit der Text über der Wetterszene besser lesbar ist.';

  @override
  String get screensaverWeatherBarGroup => 'Wetterinformationen';

  @override
  String get settingScreensaverWeatherBarTitle => 'Wetterleiste aktivieren';

  @override
  String get settingScreensaverWeatherBarDescription =>
      'Aktuelle Wetterinformationen am unteren Bildschirmrand anzeigen.';

  @override
  String get settingScreensaverWeatherBarScaleTitle => 'Textgröße';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      'Die Wetterinformationen auf 50 bis 200 Prozent skalieren.';

  @override
  String get settingScreensaverWeatherBarColorTitle => 'Textfarbe';

  @override
  String get settingScreensaverWeatherBarColorDescription =>
      'Die Farbe der Wetterinformationen.';

  @override
  String get settingScreensaverWeatherBarOpacityTitle =>
      'Deckkraft des Hintergrunds';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      'Die untere Leiste abdunkeln, damit die Wetterinformationen gut lesbar bleiben.';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => 'Titel anzeigen';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      'Jeden Messwert über seinem Wert benennen. Ohne Titel erscheinen die Werte so groß wie die Temperatur.';

  @override
  String get screensaverWeatherBarHumidityDescription =>
      'Die Luftfeuchtigkeit anzeigen, wenn die Wetterentität sie meldet.';

  @override
  String get screensaverWeatherBarWindDescription =>
      'Die Windgeschwindigkeit anzeigen, wenn die Wetterentität sie meldet.';

  @override
  String get screensaverWeatherBarVisibilityDescription =>
      'Die Sichtweite anzeigen, wenn die Wetterentität sie meldet.';

  @override
  String get settingScreensaverWeatherBlurTitle => 'Szenenunschärfe';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      'Die animierte Wetterszene weichzeichnen, während Uhr, Wetterleiste und Widgets scharf bleiben.';

  @override
  String get screensaverWeatherPreviewTwilight => 'Morgen-/Abenddämmerung';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      'Zeigt die gefühlte Temperatur anstelle der tatsächlichen Temperatur, sofern verfügbar.';

  @override
  String get settingScreensaverWebsiteUrlTitle => 'Website-URL';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      'Seite, die im Vollbildmodus angezeigt wird. Sie muss das Einbetten erlauben.';

  @override
  String get settingScreensaverWebsiteZoomTitle => 'Zoomstufe';

  @override
  String get settingScreensaverWebsiteZoomDescription =>
      'Ändert die Skalierung der gesamten Webansicht des Bildschirmschoners.';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle =>
      'Zum Schließen doppeltippen';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription =>
      'Ein einfacher Tipp ermöglicht die Interaktion mit der Website, anstatt den Bildschirmschoner zu schließen.';

  @override
  String get screensaverWebsiteSection => 'Bildschirmschoner: Website';

  @override
  String get screensaverOverlaySmallClock => 'Kleine Uhr';

  @override
  String get screensaverOverlayWeather => 'Wetter';

  @override
  String get screensaverOverlayBattery => 'Akku';

  @override
  String get screensaverOverlayClockNote =>
      'Wird in den Bildschirmschoner-Modi „Digitale Uhr“ und „Kamerastreams“ ausgeblendet.';

  @override
  String get screensaverOverlayCameraNote =>
      'Wird im Bildschirmschoner-Modus „Kamerastreams“ ausgeblendet.';

  @override
  String get screensaverOverlayScale => 'Skalierung';

  @override
  String get screensaverOverlayScaleHelp =>
      'Passt die Größe dieses Widgets an den Bildschirm an.';

  @override
  String get screensaverOverlayFont => 'Schriftart';

  @override
  String get screensaverOverlayCorner => 'Ecke';

  @override
  String get screensaverOverlayWidget => 'Widget';

  @override
  String get screensaverOverlayClock24 => '24-Stunden-Uhr';

  @override
  String get screensaverOverlayClock24Help =>
      'Verwendet das 24-Stunden-Format anstelle von AM/PM.';

  @override
  String get screensaverOverlayShowDate => 'Datum anzeigen';

  @override
  String get screensaverOverlayShowDateHelp =>
      'Fügt unter der Uhr ein kurzes Datum hinzu.';

  @override
  String get screensaverOverlayPercentage => 'Prozentsatz anzeigen';

  @override
  String get screensaverOverlayPercentageHelp =>
      'Zeigt den Ladezustand neben dem Symbol an.';

  @override
  String get screensaverOverlayLow => 'Nur bei niedrigem Akkustand';

  @override
  String get screensaverOverlayLowHelp =>
      'Wird ausgeblendet, bis der Akkustand auf 20 Prozent sinkt.';

  @override
  String get screensaverOverlayShowName => 'Namen anzeigen';

  @override
  String get screensaverOverlayShowNameHelp =>
      'Zeigt den Namen unter dem Wert an.';

  @override
  String get screensaverOverlayFontSystem => 'System';

  @override
  String get screensaverOverlayFontSerif => 'Serifen';

  @override
  String get screensaverOverlayFontCondensed => 'Schmal';

  @override
  String get screensaverOverlayFontMonospace => 'Monospace';

  @override
  String get screensaverOverlayFontCasual => 'Informell';

  @override
  String get screensaverOverlayFontCursive => 'Schreibschrift';

  @override
  String get screensaverOverlayColor => 'Farbe';

  @override
  String get screensaverOverlayWeatherEntity => 'Wetter-Entität';

  @override
  String get screensaverOverlayNoWeather => 'Keine Wetter-Entitäten vorhanden';

  @override
  String get screensaverOverlayNoWeatherHelp =>
      'Home Assistant hat keine Wetter-Entitäten zurückgegeben.';

  @override
  String get screensaverOverlayPickWeather =>
      'Wähle eine Wetter-Entität aus...';

  @override
  String get screensaverOverlayWeatherRequired =>
      'Bitte eine Wetter-Entität auswählen.';

  @override
  String get screensaverOverlayLocationName => 'Standortname';

  @override
  String get screensaverOverlayLocationHelp =>
      'Leer lassen, um die Standortzeile auszublenden.';

  @override
  String get screensaverOverlayLocation => 'Standort';

  @override
  String get screensaverOverlayLocationDetail =>
      'Zeigt den Ortsnamen über der Temperatur an.';

  @override
  String get screensaverOverlayFeelsLike => 'Gefühlte Temperatur';

  @override
  String get screensaverOverlayFeelsLikeHelp =>
      'Zeigt die gefühlte Temperatur mit einer Beschriftung unter der tatsächlichen Temperatur.';

  @override
  String get screensaverOverlayFeelsLikeOnly => 'Nur gefühlte Temperatur';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp =>
      'Zeigt die gefühlte Temperatur mit der Beschriftung „Gefühlte Temperatur“ anstelle der tatsächlichen Temperatur.';

  @override
  String get screensaverOverlayForecast => 'Wetterlage';

  @override
  String get screensaverOverlayForecastHelp =>
      'Zeigt die Wetterbedingungen mit dem entsprechenden Symbol an.';

  @override
  String get screensaverOverlayHumidity => 'Luftfeuchtigkeit';

  @override
  String get screensaverOverlayWind => 'Windgeschwindigkeit';

  @override
  String get screensaverOverlayVisibility => 'Sichtweite';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return 'Gefühlt $temperature';
  }

  @override
  String get settingScreensaverWidgetsTitle => 'Widgets';

  @override
  String get settingScreensaverWidgetsDescription =>
      'Kleine Elemente, die in den Ecken des Bildschirmschoners eingeblendet werden.';

  @override
  String get settingScreensaverWidgetScaleTitle => 'Globale Widget-Skalierung';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      'Passt die Größe aller Widgets an den Bildschirm an. Jedes Widget behält dabei seine Größe im Verhältnis zu den anderen Widgets.';

  @override
  String get settingScreensaverWidgetFontTitle => 'Globale Schriftart';

  @override
  String get settingScreensaverWidgetFontDescription =>
      'Schriftart, die von allen Widgets verwendet wird. Jedes Widget kann jedoch seine eigene Schriftart wählen.';

  @override
  String get settingScreensaverWidgetFontWeightTitle => 'Globale Schriftstärke';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      'Schriftstärke für den Text aller Widgets. Standard verwendet die jeweilige Schriftstärke jeder Zeile. Jedes Widget kann seine eigene Schriftstärke festlegen.';

  @override
  String get settingScreensaverWidgetTextShadowTitle => 'Textschatten';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      'Fügt dem Widget-Text einen Schatten hinzu, damit er auf Fotos besser lesbar ist.';

  @override
  String get settingScreensaverVignetteStrengthTitle =>
      'Intensität der Abdunklung';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      'Stärke der Hintergrundabdunklung hinter den Widgets, um die Lesbarkeit auf hellen Fotos zu verbessern. Der Wert 0 deaktiviert die Funktion.';

  @override
  String get screensaverOverlayWidgetsEmpty => 'Noch keine Widgets vorhanden';

  @override
  String get screensaverOverlayRemove => 'Widget entfernen';

  @override
  String get screensaverOverlayAdd => 'Widget hinzufügen';

  @override
  String get screensaverOverlayAddHelp =>
      'Eine kleine Uhr, Wetterinformationen, Akkustand oder eine Entität in einer Ecke.';

  @override
  String get screensaverOverlayWidgetsHint =>
      'Elemente in den Ecken und deren Skalierung';

  @override
  String get settingsSearchHint => 'Einstellungen durchsuchen';

  @override
  String get settingsSearchClear => 'Suche löschen';

  @override
  String get settingsSearchResults => 'Suchergebnisse';

  @override
  String settingsSearchEmpty(String query) {
    return 'Keine Einstellungen entsprechen „$query“.';
  }

  @override
  String get searchInstallApk =>
      'Lade eine Kiosk-Satellite-APK über die Fernverwaltung hoch und installiere sie.';

  @override
  String get searchPermissionsHelp =>
      'Alle Android-Berechtigungen, die die Anwendung verwenden kann, sowie deren Status: Mikrofon, Kamera, Benachrichtigungen, Akku ohne Einschränkungen, Über anderen Apps anzeigen, Systemeinstellungen ändern, Schutz der Systemoberfläche, Geräteadministrator, Zugriff auf alle Dateien, Nutzungszugriff und Standort.';

  @override
  String get searchServiceStatus => 'Dienststatus';

  @override
  String get searchServiceHelp =>
      'Zeigt an, ob der Kiosk-Satellite-Dienst ausgeführt wird und welche Funktionen er aktiv hält.';

  @override
  String get searchServicePermissions =>
      'Die Berechtigungen, die der Kiosk-Satellite-Dienst benötigt.';

  @override
  String get searchIntercomKiosks =>
      'Bekannte Kiosks und ob jeder von ihnen Anrufe empfangen kann.';

  @override
  String get searchHaValidate =>
      'Prüft die URL und das Token mit deinem Home Assistant.';

  @override
  String get searchHaProxy =>
      'Stellt Home Assistant über einen sicheren Proxy innerhalb der Anwendung bereit, wenn Home Assistant HTTP verwendet.';

  @override
  String get searchHaDashboard =>
      'Wähle das Dashboard und die Ansicht aus, die der Kiosk anzeigen soll.';

  @override
  String get searchKioskPermissions =>
      'Die Berechtigungen, die für die Schutzfunktionen des Kioskmodus und des Sperrmodus benötigt werden.';

  @override
  String get searchHomeStatus => 'Status des Startbildschirms';

  @override
  String get searchHomeHelp =>
      'Zeigt an, ob Kiosk Satellite der Startbildschirm des Geräts ist und wo er als Standard festgelegt werden kann.';

  @override
  String get searchMasterVolume =>
      'Die Gerätelautstärke, die als Grundlage für die Lautstärkeregelung von Medien und Assistent dient.';

  @override
  String get searchSmallClock =>
      'Eine kleine Uhr in einer Ecke des Bildschirmschoners.';

  @override
  String get searchBattery =>
      'Eine Akkuanzeige in einer Ecke des Bildschirmschoners mit dem Ladezustand dieses Geräts.';

  @override
  String get searchPersonPermission =>
      'Die Berechtigung für den Protokollzugriff, die vom Anwesenheitssensor des Geräts benötigt wird.';

  @override
  String get searchSonosSpeakers =>
      'Die Sonos-Lautsprecher, die diesem Gerät bekannt sind, einschließlich Netzwerksuche und Eingabefeld für Adressen.';

  @override
  String get voiceAppearanceHint =>
      'Design, Thema, Aktivitätsleiste und Textgröße des Assistenten';

  @override
  String get voiceSkin => 'Design';

  @override
  String get voiceSkinHelp =>
      'Das Erscheinungsbild des Sprachassistenten auf dem Bildschirm.';

  @override
  String get voiceTheme => 'Designmodus';

  @override
  String get voiceThemeHelp =>
      'Zeigt den Assistenten im hellen oder dunklen Design an.';

  @override
  String get voiceReactive => 'Reaktive Aktivitätsleiste';

  @override
  String get voiceReactiveHelp =>
      'Die Aktivitätsleiste reagiert auf Audiosignale. FÜR LEISTUNGSSCHWACHE GERÄTE wie den Echo Show NICHT EMPFOHLEN.';

  @override
  String get voiceRate => 'Aktualisierungsrate der reaktiven Leiste';

  @override
  String get voiceRateHelp =>
      'Legt fest, wie häufig die Aktivitätsleiste aktualisiert wird. Höhere Werte wirken flüssiger, benötigen aber mehr CPU-Leistung.';

  @override
  String get voiceScaleHelp =>
      'Die Größe des Assistententextes auf dem Bildschirm.';

  @override
  String get voiceUpdateIntegration =>
      'Aktualisiere die Voice-Satellite-Integration in Home Assistant, um diese Einstellungen vom Kiosk aus steuern zu können.';

  @override
  String get voiceDashboardRequired =>
      'Verfügbar, solange der Kiosk dein Home-Assistant-Dashboard anzeigt.';

  @override
  String get voiceChimesPage => 'Töne';

  @override
  String get voiceChimesHint =>
      'Aktivierungs-, Abschluss-, Fehler-, Timer- und Ansagetöne';

  @override
  String get voiceChimesPreview => 'Auf dem Kiosk abspielen';

  @override
  String get voiceChimesPreviewFailed =>
      'Der Ton konnte nicht abgespielt werden.';

  @override
  String get voiceChimesHelp =>
      'Wähle die Töne für diesen Kiosk aus. Lade hier eigene Audiodateien hoch. In Home Assistant gespeicherte Töne werden für lokale Hinweise nicht verwendet.';

  @override
  String get voiceChimeWakeTitle => 'Aktivierungston';

  @override
  String get voiceChimeWakeDescription =>
      'Wird abgespielt, wenn Voice Satellite beginnt zuzuhören.';

  @override
  String get voiceChimeDoneTitle => 'Abschlusston';

  @override
  String get voiceChimeDoneDescription =>
      'Wird abgespielt, wenn eine Sprachinteraktion beendet ist.';

  @override
  String get voiceChimeErrorTitle => 'Fehlerton';

  @override
  String get voiceChimeErrorDescription =>
      'Wird abgespielt, wenn eine Sprachinteraktion fehlschlägt.';

  @override
  String get voiceChimeTimerTitle => 'Timer-Ton';

  @override
  String get voiceChimeTimerDescription =>
      'Wird wiederholt abgespielt, wenn ein Timer abläuft, bis du ihn schließt.';

  @override
  String get voiceChimeAnnounceTitle => 'Ansageton';

  @override
  String get voiceChimeAnnounceDescription =>
      'Wird vor einer Voice-Satellite-Ansage abgespielt, außer die Ansage enthält bereits einen eigenen Ton.';

  @override
  String get voiceEngine => 'Engine';

  @override
  String get voiceEngineHelp =>
      'Startet oder stoppt die Voice-Satellite-Engine.';

  @override
  String get voiceAssigned => 'Zugewiesener Satellit';

  @override
  String get voiceAssignedHelp =>
      'Die assist_satellite-Entität, mit der sich dieser Kiosk in Home Assistant identifiziert. Eine Änderung lädt das Dashboard neu.';

  @override
  String get voiceAssignedSearch =>
      'Die assist_satellite-Entität, mit der sich dieser Kiosk in Home Assistant identifiziert.';

  @override
  String get voiceNoneAssigned => 'Keiner zugewiesen';

  @override
  String get voiceAutoStart => 'Automatisch starten';

  @override
  String get voiceAutoStartHelp =>
      'Startet Voice Satellite automatisch beim Laden des Dashboards.';

  @override
  String get voiceMuteHelp => 'Beendet das Lauschen auf Aktivierungswörter.';

  @override
  String get voicePipeline1 => 'Assist-Pipeline 1';

  @override
  String get voicePipeline1Help =>
      'Die Assist-Pipeline, die Sprachbefehle verarbeitet.';

  @override
  String get voicePipeline2 => 'Assist-Pipeline 2';

  @override
  String get voicePipeline2Help =>
      'Die Pipeline, die verwendet wird, wenn das zweite Aktivierungswort erkannt wird.';

  @override
  String get voiceVad => 'Sprachende-Erkennung';

  @override
  String get voiceVadHelp =>
      'Legt fest, wie lange eine Sprechpause dauern muss, damit ein Sprachbefehl als beendet gilt.';

  @override
  String get voiceMutedWarning =>
      'Warnung bei stummgeschaltetem Mikrofon deaktivieren';

  @override
  String get voiceMutedWarningHelp =>
      'Blendet die Warnung über ein stummgeschaltetes Mikrofon beim Start und beim Stummschalten des Satellitenmikrofons aus.';

  @override
  String get voiceDebug => 'Debug-Protokoll';

  @override
  String get voiceDebugHelp =>
      'Zeigt Debug-Informationen von Voice Satellite in der Browser-Konsole an.';

  @override
  String get voiceVersion => 'Voice-Satellite-Version';

  @override
  String get voiceVersionHelp =>
      'Die Version der in Home Assistant installierten Integration.';

  @override
  String get voiceVadDefault => 'Standard';

  @override
  String get voiceVadRelaxed => 'Entspannt';

  @override
  String get voiceVadAggressive => 'Aggressiv';

  @override
  String get voiceGeneral => 'Allgemein';

  @override
  String get voiceStart => 'Starten';

  @override
  String get voiceNotavailable => 'Nicht verfügbar';

  @override
  String get voiceDisabled => 'Deaktiviert';

  @override
  String get settingWakeWordBackgroundTitle => 'Im Hintergrund weiter zuhören';

  @override
  String get settingWakeWordBackgroundDescription =>
      'Hört auch dann weiter auf das Aktivierungswort, wenn eine andere Anwendung im Vordergrund ist, und kehrt bei Erkennung automatisch zurück. Erfordert eine permanente Benachrichtigung und die Berechtigung „Über anderen Apps anzeigen“.';

  @override
  String get settingWakeWordReturnToBackgroundTitle =>
      'Zur vorherigen Anwendung zurückkehren';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      'Kehrt nach Abschluss der Sprachinteraktion, die Kiosk Satellite in den Vordergrund gebracht hat, zur vorherigen Anwendung oder zum Startbildschirm zurück.';

  @override
  String get voiceMicHeld =>
      'Die Aktivierungswort-Erkennung kann auf deine Stimme hören.';

  @override
  String get voiceMicBlocked =>
      'Blockiert. Android wird die Berechtigung nicht erneut anfordern. Erteile sie in den App-Einstellungen.';

  @override
  String get voiceMicMissing =>
      'Ohne diese Berechtigung kann kein Aktivierungswort erkannt werden.';

  @override
  String get voiceForegroundHeld =>
      'Kiosk Satellite kann in den Vordergrund wechseln, wenn es dich hört.';

  @override
  String get voiceForegroundMissing =>
      'Ohne diese Berechtigung wird das Aktivierungswort erkannt, aber es passiert nichts.';

  @override
  String get voiceNotificationHeld =>
      'Die permanente Benachrichtigung ermöglicht das Zuhören im Hintergrund.';

  @override
  String get voiceNotificationMissing =>
      'Erforderlich, damit das Hintergrundabhören zuverlässig funktioniert.';

  @override
  String get voiceBatteryHeld => 'Android hält die Hintergrundabhörung aktiv.';

  @override
  String get voiceBatteryMissing =>
      'Ohne diese Berechtigung wird das Zuhören nach einigen Stunden beendet.';

  @override
  String get voicePermissionDirections =>
      'Erteile diese Berechtigungen auf dem Gerät: Vom linken Bildschirmrand wischen → Einstellungen → Voice Satellite → Erforderliche Systemberechtigungen.';

  @override
  String get voicePermissionsSearch =>
      'Mikrofon und weitere Berechtigungen, die für die Aktivierungswort-Erkennung benötigt werden.';

  @override
  String get voiceDisconnected => 'Home Assistant ist nicht verbunden';

  @override
  String get voiceValidate =>
      'Bitte zuerst die Verbindung in den Home-Assistant-Einstellungen validieren.';

  @override
  String get voiceChecking => 'Suche nach Voice Satellite...';

  @override
  String get voiceMissing =>
      'Voice Satellite ist nicht in Home Assistant installiert';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite verwandelt diesen Kiosk in einen freihändig nutzbaren Sprachassistenten für Home Assistant: Aktivierungswort-Erkennung, Sprachdialoge, Timer und Durchsagen direkt im Dashboard.\n\nDie Integration ist im Standard-Repository von HACS verfügbar. Installiere sie in deiner Home-Assistant-Instanz und kehre anschließend hierher zurück.';

  @override
  String get voiceLearnMore => 'Mehr erfahren über ';

  @override
  String get voiceGithub => 'Voice Satellite auf GitHub';

  @override
  String get voiceHacs => 'HACS-Repository öffnen';

  @override
  String get voiceLoading => 'Voice-Satellite-Steuerelemente werden geladen...';

  @override
  String get voiceTester => 'Aktivierungswort-Test';

  @override
  String get voiceTesterHelp =>
      'Beobachte in Echtzeit, was die Engine hört und bewertet, um zu verstehen, warum das Aktivierungswort erkannt wird oder nicht.';

  @override
  String get voiceTesterSearch =>
      'Eine Echtzeitansicht dessen, was die Engine hört und bewertet.';

  @override
  String get voiceTesterWaiting => 'Warte auf Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word (Stoppwort)';
  }

  @override
  String get voiceScore => 'Bewertung';

  @override
  String get voiceThreshold => 'Schwellenwert';

  @override
  String get voiceHits => 'Erkennungen';

  @override
  String get voiceNearMisses => 'Beinahe-Erkennungen';

  @override
  String get voicePeak => 'Höchstwert';

  @override
  String get voiceMicLevel => 'Mikrofonpegel';

  @override
  String get voiceChunkProcessing =>
      'Blockverarbeitung (Min. / Durchschnitt / Max.)';

  @override
  String get voiceLog => 'Protokoll';

  @override
  String get voiceLogEmpty =>
      'Erkennungen und Beinahe-Erkennungen werden hier angezeigt.';

  @override
  String get voiceLogHit => 'ERKANNT';

  @override
  String get voiceLogNear => 'beinahe';

  @override
  String get voiceLogScore => 'Bewertung';

  @override
  String get voiceLogDecoded => 'dekodiert';

  @override
  String get voiceLogDistance => 'dist.';

  @override
  String get voiceLogConfidence => 'conf.';

  @override
  String get voiceTesterPlayRecent => 'Letzte 10 Sekunden abspielen';

  @override
  String get voiceWakePage => 'Aktivierungswort';

  @override
  String get voiceWakeHint =>
      'Engine, Aktivierungswörter, Empfindlichkeit, zwischengespeicherte Modelle';

  @override
  String get voiceWakeLabel => 'Aktivierungswort';

  @override
  String get voiceWakeEngine => 'Aktivierungswort-Engine';

  @override
  String get voiceWakeEngineHelp =>
      'Legt fest, wo die Erkennung ausgeführt wird und welche Engine zuhört.';

  @override
  String get voiceWake1 => 'Aktivierungswort 1';

  @override
  String get voiceWake1Help =>
      'Das Aktivierungswort zum Starten eines Sprachbefehls.';

  @override
  String get voiceWake2 => 'Aktivierungswort 2';

  @override
  String get voiceWake2Help =>
      'Ein zweites Aktivierungswort, das über Assist-Pipeline 2 verarbeitet wird.';

  @override
  String get voiceSensitivity => 'Empfindlichkeit des Aktivierungsworts';

  @override
  String get voiceSensitivityHelp =>
      'Legt fest, wie leicht das Aktivierungswort erkannt wird.';

  @override
  String get voiceNoiseGate => 'Rauschschwelle für Aktivierungswörter';

  @override
  String get voiceNoiseGateHelp =>
      'Überspringt die lokale Aktivierungswort-Erkennung bei Stille, um die CPU-Auslastung zu reduzieren.';

  @override
  String get voiceStopInterruption => 'Mit dem Stoppwort unterbrechen';

  @override
  String get voiceStopInterruptionHelp =>
      'Sprich das Stoppwort aus, um Antworten zu unterbrechen.';

  @override
  String get voiceAssignFirst =>
      'Weise zuerst einen Satelliten zu, um diese Einstellungen zu steuern.';

  @override
  String get voiceCachedModels => 'Zwischengespeicherte Modelle';

  @override
  String get voiceCachedModelsHelp =>
      'Lädt die Modelle erneut von Home Assistant herunter. Nützlich nach der Veröffentlichung einer neuen Modellversion.';

  @override
  String get voiceClearCache => 'Cache löschen';

  @override
  String get voiceClearing => 'Wird gelöscht...';

  @override
  String voiceCacheCleared(String count) {
    return 'Dateien gelöscht: $count. Erneuter Download läuft.';
  }

  @override
  String voiceCacheCount(String count) {
    return 'Dateien gelöscht: $count';
  }

  @override
  String get voiceVerySensitive => 'Sehr empfindlich';

  @override
  String get voiceWakeWordPreferFp32Title =>
      'FP32-Modelle von vsWakeWord bevorzugen';

  @override
  String get voiceWakeWordPreferFp32Description =>
      'Verwendet FP32-Modelle anstelle der kleineren Int8-Versionen. Erhöht die CPU-Auslastung während des Zuhörens um etwa 10 bis 30 %, um Abweichungen des Konfidenzwerts von ungefähr 2 % zu vermeiden.';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle =>
      'Zeitüberschreitung für die Wiederaufnahme (Sekunden)';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      'Automatische Wiederherstellung: Setzt das Zuhören fort, wenn die Seite nach der Übergabe nicht setWakeWordActive(true) aufruft. Wartet jedoch, solange eine Sprachinteraktion noch Audio überträgt, um lange Gespräche nicht zu unterbrechen.';

  @override
  String get voiceSlightlySensitive => 'Wenig empfindlich';

  @override
  String get voiceModeratelySensitive => 'Mäßig empfindlich';

  @override
  String get voiceOnDevice => 'Auf dem Gerät';

  @override
  String voiceOnDeviceEngine(String engine) {
    return 'Auf dem Gerät ($engine)';
  }

  @override
  String get voiceDiagnosticsPage => 'Aktivierungswort-Diagnose';

  @override
  String get voiceDiagnosticsHint =>
      'Letzte Aktivierungen und Beinahe-Erkennungen mit Audioclips';

  @override
  String get voiceDiagnosticsTitle => 'Aktivierungswort-Diagnose aktivieren';

  @override
  String get voiceDiagnosticsDescription =>
      'Zeichnet die letzten 10 Aktivierungen und Beinahe-Erkennungen des Aktivierungsworts mit ihren Bewertungen und je einem 3 Sekunden langen Audioclip auf. Beim Ausschalten werden sie gelöscht.';

  @override
  String get voiceDiagnosticsEmpty =>
      'Noch keine Aktivierungen des Aktivierungsworts aufgezeichnet.';

  @override
  String get voiceDiagnosticsActivations => 'Aktivierungen';

  @override
  String get voiceDiagnosticsNoNearMisses =>
      'Noch keine Beinahe-Erkennungen aufgezeichnet.';

  @override
  String get voiceDiagnosticsPeakLevel => 'Spitzenpegel';

  @override
  String get voiceDiagnosticsAverageLevel => 'Durchschnittspegel';

  @override
  String get voiceDiagnosticsClipped => 'Übersteuert';

  @override
  String get voiceDiagnosticsHeard => 'Gehört';

  @override
  String get settingDisableCacheTitle => 'Cache deaktivieren';

  @override
  String get settingDisableCacheDescription =>
      'Lädt Inhalte immer aus dem Netzwerk und verwirft beim Laden zwischengespeicherte Seitendaten, damit stets die aktuellste Version des Dashboards angezeigt wird. Dies verlangsamt den Seitenaufbau. Nützlich als Hilfe während der Entwicklung.';

  @override
  String get settingAllowMixedContentTitle => 'Gemischte Inhalte zulassen';

  @override
  String get settingAllowMixedContentDescription =>
      'Erlaubt HTTPS-Seiten das Laden unsicherer HTTP-Ressourcen. Nützlich, wenn Home Assistant Inhalte mit http:// in einem Dashboard einbindet, das über https:// aufgerufen wird.';

  @override
  String get settingIgnoreSslErrorsTitle => 'SSL-Fehler ignorieren';

  @override
  String get settingIgnoreSslErrorsDescription =>
      'Akzeptiert nicht vertrauenswürdige oder selbst signierte Zertifikate. Nur im eigenen Netzwerk verwenden, da dadurch die Zertifikatsprüfung deaktiviert wird.';

  @override
  String get settingAutoReloadOnErrorTitle =>
      'Bei Fehler automatisch neu laden';

  @override
  String get settingAutoReloadOnErrorDescription =>
      'Stellt die Seite nach einem Ladefehler oder einem unerwarteten Absturz der Anwendung automatisch wieder her.';

  @override
  String get settingPullToRefreshTitle =>
      'Zum Aktualisieren herunterziehen aktivieren';

  @override
  String get settingPullToRefreshDescription =>
      'Ziehe die Seite von oben nach unten, um sie neu zu laden. Standardmäßig deaktiviert, da dies beim Scrollen durch ein Dashboard leicht versehentlich ausgelöst werden kann.';

  @override
  String get settingPullToRefreshClearCacheTitle =>
      'Cache beim Herunterziehen zum Aktualisieren löschen';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      'Beim Herunterziehen werden vor dem Neuladen zusätzlich der Web-Cache und die Aktivierungswort-Modelle gelöscht. Sitzung und gespeicherte Seitendaten bleiben erhalten.';

  @override
  String get settingBrowserZoomTitle => 'Zoomstufe';

  @override
  String get settingBrowserZoomDescription =>
      'Ändert die Skalierung der gesamten Seite. Ein Wert über 1x erleichtert die Lesbarkeit aus größerer Entfernung auf einem Wand-Tablet. Ein Wert unter 1x ermöglicht die Anzeige von mehr Dashboard-Inhalten auf kleinen Bildschirmen.';

  @override
  String get settingPinchToZoomTitle => 'Zwei-Finger-Zoom aktivieren';

  @override
  String get settingPinchToZoomDescription =>
      'Vergrößert oder verkleinert die Seite mit zwei Fingern. Standardmäßig deaktiviert, damit versehentliche Berührungen das Kiosk-Dashboard nicht verändern.';

  @override
  String get settingDisableScrollingTitle => 'Scrollen deaktivieren';

  @override
  String get settingDisableScrollingDescription =>
      'Fixiert die Seite, sodass sie in keine Richtung mehr gescrollt werden kann. Tippen und Schaltflächen funktionieren weiterhin.';

  @override
  String get browserCrashPermissionHelp =>
      'Ohne diese Berechtigung kann der Kiosk nach einem unerwarteten Absturz nicht automatisch erneut geöffnet werden.';

  @override
  String get browserCrashPermissionMissing =>
      'Die Berechtigung „Über anderen Apps anzeigen“ fehlt';

  @override
  String get browserCrashPermissionRemoteHelp =>
      'Ohne diese Berechtigung kann der Kiosk nach einem unerwarteten Absturz nicht automatisch erneut geöffnet werden. Die Seite zum Erteilen der Berechtigung wird auf dem Tablet angezeigt.';

  @override
  String get settingBrowserInjectJsTitle =>
      'JavaScript in das HA-Dashboard einfügen';

  @override
  String get settingBrowserInjectJsDescription =>
      'Führt diesen JavaScript-Code nach jedem Laden des Dashboards aus. Nützlich, um störende Elemente auszublenden oder ein Dashboard anzupassen, das du nicht selbst verwaltest.';

  @override
  String get settingBrowserInjectJsExternalTitle =>
      'JavaScript in externe Seiten einfügen';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      'Führt diesen JavaScript-Code nach dem Laden jeder externen Seite aus: Seiten, die über einen Dashboard-Link geöffnet werden, Seiten der Dashboard-Rotation sowie Website-Bildschirmschoner. Gilt nicht für die Music-Assistant-Seite.';

  @override
  String get browserInjectJsPlaceholder =>
      '// Beispiel: störendes Element ausblenden\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// Beispiel: eine Website vergrößern, die die Zoomstufe des Dashboards ignoriert\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get setupConnectHeading => 'Mit Home Assistant verbinden';

  @override
  String get setupConnectLead =>
      'Die Basis-URL deiner Home-Assistant-Instanz und ein Langzeit-Zugriffstoken, das du in deinem Home-Assistant-Profil unter Sicherheit → Langzeit-Zugriffstokens erstellen kannst.';

  @override
  String get setupBaseUrl => 'Home-Assistant-Basis-URL';

  @override
  String get setupToken => 'Langzeit-Zugriffstoken';

  @override
  String get setupScanQr => 'QR-Code scannen';

  @override
  String get setupInvalidToken => 'Ungültiges Zugriffstoken';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant hat dieses Token abgelehnt. Öffne in Home Assistant dein Profil → Sicherheit → Langzeit-Zugriffstokens, erstelle ein neues Token und kopiere den vollständigen Wert.';

  @override
  String get setupUnreachable => 'Home Assistant antwortet nicht';

  @override
  String get setupUnreachableHelp =>
      'Von dieser Adresse wurde keine Antwort empfangen. Prüfe, ob die URL korrekt ist und ob sich dieses Gerät im selben Netzwerk wie dein Home-Assistant-Server befindet.';

  @override
  String get setupUnexpectedResponseHelp =>
      'Ein Server hat geantwortet, scheint aber kein Home Assistant zu sein. Prüfe, ob die URL die Basisadresse von Home Assistant ist, zum Beispiel https://homeassistant.local:8123.';

  @override
  String get setupCannotConnect => 'Verbindung nicht möglich';

  @override
  String get setupCameraPermission => 'Kameraberechtigung erforderlich';

  @override
  String get setupCameraBlocked =>
      'Erlaube Kiosk Satellite den Kamerazugriff in den Android-Einstellungen, um den QR-Code zu scannen.';

  @override
  String get setupCameraAllow =>
      'Erlaube den Kamerazugriff zum Scannen des QR-Codes.';

  @override
  String get setupEnterBaseUrl => 'Bitte die Home-Assistant-Basis-URL eingeben';

  @override
  String get setupInvalidBaseUrl => 'Ungültige Basis-URL';

  @override
  String get setupBaseUrlHelp =>
      'Dies ist die Adresse, mit der du Home Assistant öffnest, zum Beispiel https://homeassistant.local:8123.';

  @override
  String get setupEnterToken => 'Bitte ein Langzeit-Zugriffstoken eingeben';

  @override
  String get setupEnterTokenHelp =>
      'Öffne in Home Assistant dein Profil → Sicherheit → Langzeit-Zugriffstokens, um eines zu erstellen.';

  @override
  String get setupValidateContinue => 'Validieren und fortfahren';

  @override
  String setupUnexpectedResponse(String error) {
    return 'Unerwartete Antwort ($error)';
  }

  @override
  String get baseUrlInvalid =>
      'Bitte eine gültige URL eingeben, zum Beispiel https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      'Bitte nur die Basis-URL eingeben, ohne den Pfad zu einem Dashboard. Beispiel: https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      'Bitte nur die Basis-URL eingeben, ohne weitere Angaben nach dem Port. Beispiel: https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => 'Dashboard auswählen';

  @override
  String get setupDashboardHelp =>
      'Dies ist das Dashboard, das der Kiosk beim Start anzeigt.';

  @override
  String get setupSelectDashboard => 'Dashboard auswählen';

  @override
  String get setupSelectDashboardHelp =>
      'Wähle das Dashboard aus, das der Kiosk anzeigen soll. Du kannst es später in den Einstellungen ändern.';

  @override
  String get setupWelcome => 'Willkommen';

  @override
  String get setupConnect => 'Verbinden';

  @override
  String get setupConnectSummary => 'Home-Assistant-URL und Token';

  @override
  String get setupDashboard => 'Dashboard';

  @override
  String get setupDashboardSummary => 'Was der Kiosk anzeigt';

  @override
  String get setupRecommendedSummary => 'Empfohlene Einstellungen';

  @override
  String get setupPermissions => 'Berechtigungen';

  @override
  String get setupPermissionsSummary => 'Erforderlich für die Einrichtung';

  @override
  String get setupPermissionLead =>
      'Android wird diese Berechtigungen anfordern. Sie werden alle zu Beginn abgefragt, damit der Kiosk dich später nicht mehr unterbricht.';

  @override
  String get setupRemotePermissionLead =>
      'Android fordert diese Berechtigungen direkt auf dem Tablet an. Gehe zum Gerät und bestätige die Anfragen. Anschließend kannst du hier fortfahren.';

  @override
  String get setupMicrophoneHelp =>
      'Voice Satellite und die Gegensprechanlage benötigen Zugriff auf das Mikrofon.';

  @override
  String get setupNotificationListening =>
      'Erlaubt die permanente Benachrichtigung des Kiosk-Satellite-Dienstes, die anzeigt, welche Funktionen aktiv gehalten werden und wann der Kiosk zuhört.';

  @override
  String get setupBatteryService =>
      'Erlaubt dem Kiosk-Satellite-Dienst, im Hintergrund zu laufen, ohne von Android pausiert oder beendet zu werden.';

  @override
  String get setupOverlayBoot =>
      'Erlaubt Kiosk Satellite, sich nach einem Absturz erneut zu öffnen und beim Einschalten des Geräts zu starten.';

  @override
  String get setupOverlayCrash =>
      'Erlaubt Kiosk Satellite, nach einem Absturz wieder angezeigt zu werden.';

  @override
  String get setupBrightnessHelp =>
      'Erlaubt Kiosk Satellite, die tatsächliche Bildschirmhelligkeit anzupassen (Systemeinstellungen ändern).';

  @override
  String get setupScreenControl => 'Bildschirmsteuerung';

  @override
  String get setupScreenControlHelp =>
      'Erlaubt Kiosk Satellite, den Bildschirm auf Anforderung auszuschalten (Geräteadministrator).';

  @override
  String get setupGrantPermissions => 'Berechtigungen auf dem Gerät erteilen';

  @override
  String get setupRequestingPermissions =>
      'Berechtigungen werden auf dem Gerät angefordert...';

  @override
  String get setupPermissionsRequested =>
      'Berechtigungen wurden auf dem Gerät angefordert';

  @override
  String get setupQrFlipCamera => 'Kamera wechseln';

  @override
  String get setupQrCameraFailed => 'Die Kamera konnte nicht gestartet werden.';

  @override
  String get setupQrTitle => 'QR-Code des Tokens scannen';

  @override
  String get setupQrHelp =>
      'Er wird neben einem neu erstellten Token in deinem Home-Assistant-Profil angezeigt.';

  @override
  String get setupQrFlashOff => 'Taschenlampe ausschalten';

  @override
  String get setupQrFlashOn => 'Taschenlampe einschalten';

  @override
  String get setupPasswordFirst =>
      'Bitte zuerst ein Administrationspasswort festlegen';

  @override
  String get setupPasswordBeforeImport =>
      'Gib oben ein Administrationspasswort mit mindestens 4 Zeichen ein und importiere anschließend die Sicherung.';

  @override
  String get setupPasswordFailed =>
      'Das Passwort konnte nicht festgelegt werden';

  @override
  String get setupPasswordExists => 'Es wurde bereits ein Passwort festgelegt';

  @override
  String get setupPasswordExistsHelp =>
      'Melde dich mit dem auf dem Tablet festgelegten Passwort an, um hier fortzufahren. Die Seite wird neu geladen...';

  @override
  String get setupNotBackup => 'Die Datei ist keine Sicherung';

  @override
  String get setupInvalidBackupHelp =>
      'Die Datei enthält kein gültiges JSON. Exportiere eine Konfiguration aus den Einstellungen eines bereits eingerichteten Kiosk Satellite oder aus dessen Fernverwaltung.';

  @override
  String get setupWrongBackupKind =>
      'Exportiere eine Konfiguration aus den Einstellungen eines bereits eingerichteten Kiosk Satellite.';

  @override
  String get setupImportFailedHelp =>
      'Die Datei konnte nicht angewendet werden.';

  @override
  String get setupBackupNoDashboard => 'Die Sicherung enthält kein Dashboard';

  @override
  String get setupBackupNoDashboardHelp =>
      'Die Einstellungen wurden übernommen, aber die Sicherung wurde erstellt, bevor das Gerät eingerichtet war, und enthält kein Dashboard zur Anzeige. Fahre mit dem Assistenten fort, um eines auszuwählen.';

  @override
  String get setupImporting => 'Importiere...';

  @override
  String get setupRemoteRestoreHelp =>
      'Importiere eine exportierte Kiosk-Satellite-Konfiguration, um den restlichen Assistenten zu überspringen.';

  @override
  String get setupFinishOnDevice => 'Auf dem Gerät abschließen';

  @override
  String get setupFinishOnDeviceHelp =>
      'Die Konfiguration wurde importiert. Bestätige die Berechtigungsanfragen auf dem Bildschirm des Tablets. Diese Seite wird automatisch fortgesetzt, sobald das Dashboard geladen wurde.';

  @override
  String get setupBackupObject =>
      'Die Sicherung muss ein JSON-Objekt enthalten.';

  @override
  String get setupBackupKind =>
      'Diese Datei enthält keine Kiosk-Satellite-Konfiguration.';

  @override
  String get setupBackupSettings =>
      'Die Sicherung enthält keine Einstellungen.';

  @override
  String get setupServiceHelp =>
      'Hält die Anwendung aktiv, wenn der Bildschirm ausgeschaltet ist oder eine andere App im Vordergrund läuft. Dadurch bleiben die Verbindung zu Home Assistant sowie Funktionen wie Bewegungserkennung und Bluetooth-Proxy aktiv. Die folgenden Berechtigungen sind optional, werden jedoch empfohlen: Jede einzelne hilft dabei, den Dienst auch bei ausgeschaltetem Bildschirm aktiv zu halten.';

  @override
  String get setupBatteryMissing =>
      'Android kann die Anwendung bei ausgeschaltetem Bildschirm pausieren und die Verbindung zu Home Assistant trennen.';

  @override
  String get setupOverlayMissing =>
      'Ohne diese Berechtigung kann der Dienst den Kiosk nach einem Absturz nicht erneut öffnen.';

  @override
  String get setupVoiceDetected => 'Voice Satellite erkannt';

  @override
  String get setupVoiceHelp =>
      'In dieser Home-Assistant-Instanz ist die Voice-Satellite-Integration installiert. Wähle aus, welcher Satellit zu diesem Kiosk gehört, und überprüfe seine Einstellungen. Du kannst alles später noch ändern.';

  @override
  String get setupNoSatellites => 'Keine Satelliten gefunden';

  @override
  String get setupNoSatellitesHelp =>
      'Füge in der Voice-Satellite-Integration einen Assist-Satelliten hinzu oder fahre ohne Auswahl fort und wähle ihn später im Dashboard aus.';

  @override
  String get setupNewSatelliteHelp =>
      'Wenn dieses Gerät neu ist, erstelle zuerst eine Satelliten-Entität in Home Assistant. Einstellungen → Geräte und Dienste → Voice Satellite → Eintrag hinzufügen. WICHTIG: Zwei Geräte dürfen nicht dieselbe Entität verwenden.';

  @override
  String get setupApplyRecommended => 'Alle empfohlenen Einstellungen anwenden';

  @override
  String get setupRecommendedHelp =>
      'Die optimalen Einstellungen, um alle Funktionen der Voice-Satellite-Integration zu nutzen.';

  @override
  String get setupVoiceRequired => 'Für Voice Satellite erforderlich';

  @override
  String get setupMicrophoneAccess => 'Mikrofonzugriff';

  @override
  String get setupNativeWakeWord => 'Native Aktivierungswort-Erkennung';

  @override
  String get setupPullRefresh => 'Zum Aktualisieren nach unten ziehen';

  @override
  String get setupAutoplay => 'Audio und Video automatisch wiedergeben';

  @override
  String get setupVoiceSkipped => 'Nicht installiert, übersprungen';

  @override
  String get setupRemoteHeading => 'Fernverwaltung';

  @override
  String get setupTitle => 'Kiosk Satellite\nEinrichten';

  @override
  String get setupWelcomeLead =>
      'Verwandle dieses Tablet in einen Home-Assistant-Kiosk. Die Einrichtung dauert nur wenige Minuten und dieser Assistent führt dich Schritt für Schritt durch den Prozess.';

  @override
  String get setupDeviceName => 'Gerätename';

  @override
  String get setupDeviceNameHelp =>
      'Name, unter dem sich dieser Kiosk in Home Assistant, der Fernverwaltung und im Netzwerk identifiziert. Du kannst ihn jederzeit unter Einstellungen > Gerät ändern.';

  @override
  String get setupEnableRemote => 'Fernverwaltung aktivieren';

  @override
  String get setupEnableRemoteHelp =>
      'Verwalte diesen Kiosk auch nach der Einrichtung über einen Webbrowser. Dort lässt sich das Home-Assistant-Zugriffstoken deutlich einfacher einfügen.';

  @override
  String get setupRemotePassword => 'Passwort für die Fernverwaltung';

  @override
  String get setupRestoreHeading => 'Sicherung wiederherstellen';

  @override
  String get setupRestore => 'Aus Konfigurationsdatei wiederherstellen';

  @override
  String get setupRestoreHelp =>
      'Importiert eine aus Kiosk Satellite exportierte Konfiguration und überspringt den restlichen Assistenten. Einstellungen, Dashboard und Anmeldedaten werden übernommen.';

  @override
  String get setupServicePermissions =>
      'Empfohlene Berechtigungen für den Dienst';

  @override
  String get setupPasswordShort => 'Das Passwort ist zu kurz';

  @override
  String get setupPasswordMinimum => 'Bitte mindestens 4 Zeichen verwenden.';

  @override
  String setupRemoteAddress(String address) {
    return 'Du kannst diese Einrichtung auch über einen Webbrowser unter $address fortsetzen, selbst wenn der obige Schalter deaktiviert ist.';
  }

  @override
  String get remoteWelcomeTitle => 'Willkommen bei Kiosk Satellite';

  @override
  String get remoteWelcomePassword =>
      'Dieses Tablet wartet noch auf die Einrichtung. Schütze zuerst die Fernverwaltung mit einem Passwort.';

  @override
  String get remoteWelcomeReady =>
      'Dieses Tablet wartet noch auf die Einrichtung. Das Passwort für die Fernverwaltung ist bereits festgelegt. Um es zu ändern, gib hier ein neues Passwort ein.';

  @override
  String get remoteInitialPassword =>
      'Administrationspasswort (mindestens 4 Zeichen)';

  @override
  String get remoteNewPassword =>
      'Neues Administrationspasswort (leer lassen, um das aktuelle beizubehalten)';

  @override
  String get intercomBuiltinRing => 'Integrierter Klingelton';

  @override
  String get intercomBuiltinChime => 'Integrierter Signalton';

  @override
  String intercomMissingFile(String file) {
    return '$file (nicht gefunden)';
  }

  @override
  String get intercomAddSound => 'Ton hinzufügen';

  @override
  String get intercomCopySoundHelp =>
      'Kopiert eine Audiodatei von diesem Gerät in den Sound-Ordner.';

  @override
  String get intercomUploadSoundHelp =>
      'Lädt eine Audiodatei von diesem Computer in den Sound-Ordner hoch.';

  @override
  String get intercomUpload => 'Hochladen';

  @override
  String get intercomUploading => 'Wird hochgeladen...';

  @override
  String get intercomUnsupportedSound => 'Nicht unterstützter Ton';

  @override
  String get intercomChooseSound =>
      'Nicht unterstützter Ton: Bitte eine MP3-, OGG-, WAV-, FLAC-, M4A- oder AAC-Datei auswählen.';

  @override
  String get intercomCopyFailed => 'Die Datei konnte nicht kopiert werden';

  @override
  String intercomUploadFailed(String error) {
    return 'Hochladen fehlgeschlagen: $error';
  }

  @override
  String intercomSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get intercomSoundFilename =>
      'Bitte nur einen Dateinamen und keinen Pfad eingeben.';

  @override
  String get intercomSoundFormats =>
      'Bitte eine MP3-, OGG-, WAV-, FLAC-, M4A- oder AAC-Datei auswählen.';

  @override
  String get voiceTimerDefaultName => 'Timer';

  @override
  String get voiceTimerDrag => 'Zum Verschieben der Timer ziehen';

  @override
  String get voiceTimerPauseHint =>
      'Tippen zum Pausieren. Doppeltippen zum Abbrechen. Zum Verschieben ziehen.';

  @override
  String get voiceTimerResumeHint =>
      'Tippen zum Fortsetzen. Doppeltippen zum Abbrechen. Zum Verschieben ziehen.';

  @override
  String get voiceTimerCancel => 'Timer abbrechen';

  @override
  String get voiceTimerActionError =>
      'Der Timer konnte nicht geändert werden. Bitte überprüfe die Verbindung und aktualisiere Voice Satellite bei Bedarf.';

  @override
  String get voiceTimerFinished => 'Timer beendet';

  @override
  String get voiceTimerDismissHint =>
      'Tippen, um den Timer-Alarm zu schließen.';
}
