// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class UiStringsIt extends UiStrings {
  UiStringsIt([String locale = 'it']) : super(locale);

  @override
  String get aboutApp => 'App';

  @override
  String get aboutVersion => 'Versione dell\'app';

  @override
  String get aboutBuild => 'Build';

  @override
  String get aboutPackage => 'Pacchetto';

  @override
  String get aboutAttribution => 'Crediti';

  @override
  String get aboutAuthor => 'Autore';

  @override
  String get aboutWebsite => 'Sito web';

  @override
  String get aboutSourceCode => 'Codice sorgente';

  @override
  String get aboutLicense => 'Licenza';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite è gratuito per uso personale e non commerciale. È distribuito con licenza CC BY-NC-ND 4.0: puoi usarlo e condividerlo, ma non sono consentiti l\'uso commerciale dell\'app né la ridistribuzione di sue versioni modificate. I plugin indipendenti hanno un\'autorizzazione aggiuntiva ai sensi di PLUGIN-EXCEPTION.md.';

  @override
  String get aboutLocalizationCredits => 'Crediti della traduzione';

  @override
  String get aboutLocalizationCreditsHint => 'Collaboratori per lingua';

  @override
  String get aboutCheckNow => 'Cerca aggiornamenti ora';

  @override
  String get aboutChecking => 'Ricerca…';

  @override
  String get aboutCheckFailed =>
      'Ricerca aggiornamenti non riuscita. Il dispositivo riesce a raggiungere GitHub?';

  @override
  String get aboutOverlayMissing =>
      'Autorizzazione \"Mostra sopra altre app\" mancante';

  @override
  String get aboutOverlayHelp =>
      'Senza questa autorizzazione l\'app non può riaprirsi dopo l\'aggiornamento. La schermata per concederla compare sul tablet.';

  @override
  String aboutDownloadProgress(String percent) {
    return 'Download… $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return 'Aggiornamento non riuscito: $error';
  }

  @override
  String get aboutAlreadyCurrent => 'Già aggiornato';

  @override
  String get aboutInstallHelp =>
      'Il download avviene sul tablet; l\'installazione va confermata sullo schermo del tablet.';

  @override
  String get aboutSystem => 'Sistema';

  @override
  String get aboutSystemVersion => 'Versione della ROM';

  @override
  String get aboutSystemVerifying => 'Verifica…';

  @override
  String get aboutSystemInstalling => 'Installazione…';

  @override
  String get aboutSystemRestartHelp =>
      'Il dispositivo si riavvia due volte per installare l\'aggiornamento e resta offline per qualche minuto.';

  @override
  String get aboutSystemManual => 'Nuova immagine disponibile';

  @override
  String aboutSystemManualHelp(String version) {
    return 'La versione $version della nuova immagine per Echo Dot si installa a mano, non come aggiornamento.';
  }

  @override
  String get alarmsTitle => 'Sveglie';

  @override
  String get alarmsSetAnAlarm => 'Imposta una sveglia';

  @override
  String get alarmsNone => 'Nessuna sveglia';

  @override
  String get alarmsDone => 'Fine';

  @override
  String get alarmsRepeat => 'Ripeti';

  @override
  String get alarmsLabel => 'Etichetta';

  @override
  String get alarmsAddLabel => 'Aggiungi etichetta';

  @override
  String get alarmsTone => 'Suoneria della sveglia';

  @override
  String get alarmsSunrise => 'Alba';

  @override
  String get alarmsDefaultTone => 'Predefinita';

  @override
  String get alarmsBuiltInTone => 'Sveglia integrata';

  @override
  String get alarmsSoundsFolder => 'Cartella dei suoni';

  @override
  String get alarmsToday => 'Oggi';

  @override
  String get alarmsTomorrow => 'Domani';

  @override
  String get alarmsOnce => 'Una volta';

  @override
  String get alarmsEveryDay => 'Ogni giorno';

  @override
  String get alarmsWeekdays => 'Giorni feriali';

  @override
  String get alarmsWeekends => 'Fine settimana';

  @override
  String alarmsSnoozedUntil(String time) {
    return 'Posticipata fino alle $time';
  }

  @override
  String get alarmsSnooze => 'Posticipa';

  @override
  String get alarmsStop => 'Ferma';

  @override
  String get alarmsDefaultLabel => 'Sveglia';

  @override
  String get alarmsSetToast => 'Sveglia impostata';

  @override
  String alarmsRingsIn(String duration) {
    return 'Suonerà tra $duration';
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
    return 'Sveglia alle $time';
  }

  @override
  String alarmsSkipAlarm(String time) {
    return 'Salta la sveglia delle $time';
  }

  @override
  String get alarmsNextWidget => 'Prossima sveglia';

  @override
  String get alarmsManage => 'Gestisci sveglie';

  @override
  String alarmsNextAt(String day, String time) {
    return 'Prossima: $day alle $time';
  }

  @override
  String get alarmsNoneSet => 'Nessuna sveglia impostata';

  @override
  String get alarmsDefaultsSection => 'Valori predefiniti';

  @override
  String get alarmsTtsSection => 'Sintesi vocale';

  @override
  String get alarmsEditAlarm => 'Modifica sveglia';

  @override
  String get alarmsTime => 'Ora';

  @override
  String get alarmsRinging => 'La sveglia sta suonando';

  @override
  String get alarmsSnoozed => 'Sveglia posticipata';

  @override
  String get alarmsSunriseRunning => 'Alba prima di una sveglia';

  @override
  String alarmsSunriseHint(String minutes) {
    return 'Lo schermo si illumina gradualmente per $minutes minuti prima che suoni.';
  }

  @override
  String get alarmsDeleteFailed => 'Impossibile eliminare la sveglia.';

  @override
  String alarmsDuplicate(String time) {
    return 'Hai già una sveglia alle $time';
  }

  @override
  String get alarmsEaseIn => 'Aumenta gradualmente il volume';

  @override
  String alarmsEaseHint(String seconds) {
    return 'Raggiunge il volume della sveglia in $seconds secondi.';
  }

  @override
  String get alarmsSpeak => 'Parla quando suona';

  @override
  String get alarmsPhrase => 'Frase';

  @override
  String alarmsPhraseVariables(String variables) {
    return 'Variabili disponibili: $variables';
  }

  @override
  String get alarmsVoiceSection => 'Sveglie vocali';

  @override
  String get alarmsVoiceManage => 'Gestisci le sveglie con Voice Satellite';

  @override
  String get alarmsVoiceHint =>
      'Richiede il blueprint delle sveglie di Kiosk Satellite e un agente di conversazione LLM in Home Assistant.';

  @override
  String get alarmsMusic => 'Musica';

  @override
  String get alarmsMusicNone => 'Nessuna';

  @override
  String get alarmsMusicRemove => 'Rimuovi la musica';

  @override
  String get alarmsMusicHint =>
      'Suona al posto della suoneria. Se la musica non può essere riprodotta, suona la suoneria.';

  @override
  String get androidAccessibilityHelp =>
      'Chiude l\'area notifiche e la schermata delle app recenti ogni volta che si aprono mentre la modalità kiosk o la modalità blocco protegge lo schermo. Kiosk Satellite non legge alcun contenuto dello schermo.';

  @override
  String get androidServiceChannelHelp =>
      'Compare mentre il Servizio Kiosk Satellite mantiene l\'app in esecuzione con lo schermo spento o dietro un\'altra app.';

  @override
  String get androidServiceListening =>
      'in ascolto di una parola di attivazione';

  @override
  String get androidServiceRtspAudio => 'audio del microfono RTSP abilitato';

  @override
  String get androidServiceEsphome => 'server ESPHome attivo';

  @override
  String get androidServiceBluetooth => 'inoltro dei dispositivi Bluetooth';

  @override
  String get androidServiceCamera => 'monitoraggio della fotocamera';

  @override
  String get androidServiceLocation => 'invio della posizione';

  @override
  String get androidServiceRemote => 'amministrazione remota attiva';

  @override
  String get androidServiceKiosk => 'protezione della modalità kiosk';

  @override
  String get androidServiceSessions => 'connessione a Home Assistant attiva';

  @override
  String get launcherErrorAndroidOnly =>
      'l\'elenco delle app è disponibile solo su Android';

  @override
  String launcherErrorListDetail(String error) {
    return 'impossibile elencare le app: $error';
  }

  @override
  String launcherOpenFailed(String name) {
    return 'Impossibile aprire $name';
  }

  @override
  String get launcherUninstalled => 'Potrebbe essere stata disinstallata.';

  @override
  String get launcherNoneHelp =>
      'Ancora nessuna. Scegli le app da proporre nel launcher.';

  @override
  String get launcherNone => 'Ancora nessuna';

  @override
  String get launcherListFailed => 'Impossibile elencare le app';

  @override
  String launcherListError(String error) {
    return 'Impossibile elencare le app: $error';
  }

  @override
  String get launcherListingFailed => 'elenco non riuscito';

  @override
  String get launcherEmpty => 'Nessuna app avviabile trovata.';

  @override
  String get launcherSearchApps => 'Cerca app';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get calendarViewDay => 'Giorno';

  @override
  String get calendarViewWeek => 'Settimana';

  @override
  String get calendarViewMonth => 'Mese';

  @override
  String get calendarViewSchedule => 'Agenda';

  @override
  String get calendarToday => 'Oggi';

  @override
  String get calendarTomorrow => 'Domani';

  @override
  String get calendarPrevious => 'Precedente';

  @override
  String get calendarNext => 'Successivo';

  @override
  String get calendarAllDay => 'Tutto il giorno';

  @override
  String calendarMore(String count) {
    return '+$count altri';
  }

  @override
  String get calendarUpNext => 'A seguire';

  @override
  String calendarStartsIn(String duration) {
    return 'tra $duration';
  }

  @override
  String get calendarHappeningNow => 'Ora';

  @override
  String get calendarLaterToday => 'Più tardi oggi';

  @override
  String get calendarNothingElseToday => 'Nient\'altro per oggi';

  @override
  String get calendarNothingPlanned => 'Niente in programma';

  @override
  String get calendarNothingThisWeek => 'Niente in programma questa settimana';

  @override
  String get calendarEmptyTitle => 'Ancora nessun calendario';

  @override
  String get calendarEmptyHint =>
      'Aggiungi i calendari di Home Assistant da mostrare in Impostazioni > Calendario.';

  @override
  String calendarOffline(String time) {
    return 'Home Assistant non è raggiungibile. Vengono mostrati gli eventi aggiornati alle $time.';
  }

  @override
  String calendarTimeRange(String start, String end) {
    return 'Dalle $start alle $end';
  }

  @override
  String calendarPeopleTwo(String first, String second) {
    return '$first e $second';
  }

  @override
  String get calendarRepeatsDaily => 'Ogni giorno';

  @override
  String get calendarRepeatsWeekly => 'Ogni settimana';

  @override
  String get calendarRepeatsMonthly => 'Ogni mese';

  @override
  String get calendarRepeatsYearly => 'Ogni anno';

  @override
  String get calendarRepeats => 'Si ripete';

  @override
  String get calendarDone => 'Fine';

  @override
  String get calendarCalendarsSection => 'Calendari';

  @override
  String get calendarAdd => 'Aggiungi un calendario';

  @override
  String get calendarAlreadyAdded => 'Questo calendario è già nell\'elenco.';

  @override
  String get calendarOpen => 'Apri il calendario';

  @override
  String get calendarOpenHint => 'Mostra il calendario su questo kiosk.';

  @override
  String get calendarEditName => 'Nome';

  @override
  String get calendarEditColor => 'Colore';

  @override
  String get calendarEditPerson => 'Persona';

  @override
  String get calendarEditPersonHint =>
      'Mostra la sua foto sulle etichette del calendario.';

  @override
  String get calendarEditPersonNone => 'Nessuna';

  @override
  String get calendarPickCalendar => 'Scegli un calendario';

  @override
  String get calendarPickPerson => 'Scegli una persona';

  @override
  String get calendarColorTeal => 'Verde acqua';

  @override
  String get calendarColorRust => 'Ruggine';

  @override
  String get calendarColorBlue => 'Blu';

  @override
  String get calendarColorPlum => 'Prugna';

  @override
  String get calendarColorOchre => 'Ocra';

  @override
  String get calendarColorSage => 'Salvia';

  @override
  String get calendarColorRose => 'Rosa';

  @override
  String get calendarColorSlate => 'Ardesia';

  @override
  String get calendarColorCustom => 'Personalizzato';

  @override
  String get calendarWidgetEvents => 'Eventi mostrati';

  @override
  String get calendarWidgetDays => 'Giorni mostrati';

  @override
  String get calendarWidgetTomorrow => 'Oggi e domani';

  @override
  String get calendarWidgetWeek => 'Prossimi 7 giorni';

  @override
  String get calendarWidgetAllDay => 'Mostra gli eventi di tutto il giorno';

  @override
  String get calendarWidgetDots => 'Punti colorati';

  @override
  String get calendarWidgetDotsHint =>
      'Contrassegna gli eventi con il colore del loro calendario invece che con la foto della persona.';

  @override
  String get calendarVoiceSection => 'Calendario vocale';

  @override
  String get calendarVoiceManage =>
      'Gestisci il calendario con Voice Satellite';

  @override
  String get calendarVoiceHint =>
      'Richiede il blueprint del calendario di Kiosk Satellite e un agente di conversazione LLM in Home Assistant.';

  @override
  String get calendarNewEvent => 'Nuovo evento';

  @override
  String get calendarEditEvent => 'Modifica evento';

  @override
  String get calendarFieldTitle => 'Titolo';

  @override
  String get calendarFieldTitleHint => 'Aggiungi un titolo';

  @override
  String get calendarFieldCalendars => 'Calendari';

  @override
  String get calendarFieldSharedHint =>
      'Compare una sola volta, diviso tra i loro colori.';

  @override
  String get calendarFieldStarts => 'Inizio';

  @override
  String get calendarFieldEnds => 'Fine';

  @override
  String get calendarFieldStartTime => 'Ora di inizio';

  @override
  String get calendarFieldEndTime => 'Ora di fine';

  @override
  String get calendarFieldEndsBeforeStart => 'La fine è prima dell\'inizio.';

  @override
  String get calendarFieldRepeat => 'Ripeti';

  @override
  String get calendarRepeatNever => 'Non si ripete';

  @override
  String get calendarRepeatWeekdays => 'Ogni giorno feriale';

  @override
  String calendarRepeatWeeklyOn(String weekday) {
    return 'Ogni settimana di $weekday';
  }

  @override
  String calendarRepeatMonthlyOn(String day) {
    return 'Ogni mese il giorno $day';
  }

  @override
  String calendarRepeatYearlyOn(String date) {
    return 'Ogni anno il $date';
  }

  @override
  String get calendarFieldLocation => 'Luogo';

  @override
  String get calendarFieldLocationHint => 'Aggiungi un luogo';

  @override
  String get calendarFieldNotes => 'Note';

  @override
  String get calendarFieldNotesHint => 'Aggiungi note';

  @override
  String get calendarEventAdded => 'Evento aggiunto';

  @override
  String get calendarEventSaved => 'Modifiche salvate';

  @override
  String get calendarEventDeleted => 'Evento eliminato';

  @override
  String get calendarSaveFailed => 'Impossibile salvare l\'evento';

  @override
  String get calendarDeleteFailed => 'Impossibile eliminare l\'evento';

  @override
  String calendarEditReadOnly(String calendar) {
    return '$calendar è di sola lettura.';
  }

  @override
  String calendarEditGone(String calendar) {
    return 'L\'evento non è più presente in $calendar.';
  }

  @override
  String calendarEditNotAllowed(String calendar) {
    return 'L\'utente Home Assistant del kiosk non può modificare $calendar.';
  }

  @override
  String calendarDeleteTitle(String title) {
    return 'Eliminare $title?';
  }

  @override
  String calendarDeleteShared(String names) {
    return 'Viene rimosso da tutti i calendari in cui si trova: $names.';
  }

  @override
  String calendarSaveRepeatTitle(String title) {
    return 'Salvare le modifiche a $title?';
  }

  @override
  String get calendarSaveRepeatFollowing =>
      'La nuova ripetizione inizia da questo giorno.';

  @override
  String get calendarScopeThis => 'Questo evento';

  @override
  String get calendarScopeFollowing => 'Questo e gli eventi successivi';

  @override
  String get calendarScopeAll => 'Tutti gli eventi';

  @override
  String get calendarEditingSection => 'Modifica';

  @override
  String get cameraViewerTitle => 'Vista telecamere';

  @override
  String get cameraViewerConnecting => 'Connessione...';

  @override
  String get cameraViewerReconnecting => 'Riconnessione...';

  @override
  String cameraViewerTrying(String transport) {
    return 'Tentativo con $transport...';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return 'Questo dispositivo non può decodificare $codec';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return 'Questo dispositivo non può riprodurre flussi $transport';
  }

  @override
  String get cameraViewerCannotDecodeStream =>
      'Questo dispositivo non può decodificare questo flusso';

  @override
  String cameraViewerHaRetry(String seconds) {
    return 'Impossibile raggiungere Home Assistant. Nuovo tentativo tra $seconds s';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return 'Impossibile raggiungere il server delle telecamere. Nuovo tentativo tra $seconds s';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return 'Connessione non riuscita. Nuovo tentativo tra $seconds s';
  }

  @override
  String get cameraViewerStartRetry =>
      'Il server delle telecamere non è riuscito ad avviare questo flusso. Nuovo tentativo...';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return 'Il server delle telecamere non è riuscito ad avviare questo flusso. Nuovo tentativo tra $seconds s';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return 'Flusso non trovato sul server delle telecamere. Nuovo tentativo tra $seconds s';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return 'Il server delle telecamere ha rifiutato l\'accesso. Nuovo tentativo tra $seconds s';
  }

  @override
  String get cameraViewerMissing => 'Flusso mancante in Go2RTC';

  @override
  String get commonImport => 'Importa';

  @override
  String get commonBack => 'Indietro';

  @override
  String get commonNext => 'Avanti';

  @override
  String get commonFinish => 'Fine';

  @override
  String get commonWorking => 'Elaborazione…';

  @override
  String get commonSettings => 'Impostazioni';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonOk => 'OK';

  @override
  String get commonGrant => 'Concedi';

  @override
  String get commonEnable => 'Abilita';

  @override
  String get commonRefresh => 'Aggiorna';

  @override
  String get commonTest => 'Prova';

  @override
  String get commonInstall => 'Installa';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonCopy => 'Copia';

  @override
  String get commonAdd => 'Aggiungi';

  @override
  String get commonRemove => 'Rimuovi';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonClear => 'Cancella';

  @override
  String get commonBrowse => 'Sfoglia';

  @override
  String get commonSet => 'Imposta';

  @override
  String get commonHour => 'Ora';

  @override
  String get commonMinute => 'Minuto';

  @override
  String get commonUp => 'Aumenta';

  @override
  String get commonDown => 'Diminuisci';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonSaveFailed => 'Impossibile salvare';

  @override
  String get commonColorWhite => 'Bianco';

  @override
  String get commonColorWarm => 'Caldo';

  @override
  String get commonColorAmber => 'Ambra';

  @override
  String get commonColorRed => 'Rosso';

  @override
  String get commonColorGreen => 'Verde';

  @override
  String get commonColorBlue => 'Blu';

  @override
  String get commonColorCyan => 'Ciano';

  @override
  String get commonColorDim => 'Attenuato';

  @override
  String get commonEdit => 'Modifica';

  @override
  String get commonMoveUp => 'Sposta su';

  @override
  String get commonMoveDown => 'Sposta giù';

  @override
  String get commonPreviousMonth => 'Mese precedente';

  @override
  String get commonNextMonth => 'Mese successivo';

  @override
  String get commonLoading => 'Caricamento…';

  @override
  String get commonChoose => 'Scegli';

  @override
  String get dlnaPortInvalid =>
      'Inserisci una porta tra 1024 e 65535 o lascia il campo vuoto';

  @override
  String get commonSelectAll => 'Seleziona tutto';

  @override
  String get dashboardPickerSearch => 'Cerca viste';

  @override
  String get dashboardPickerSearchAll => 'Cerca plance e viste';

  @override
  String get dashboardPickerCurrent => 'Attuale';

  @override
  String get dashboardPickerDashboards => 'Plance';

  @override
  String get dashboardPickerSubviews => 'Sottoviste';

  @override
  String get dashboardPickerSubview => 'Sottovista';

  @override
  String get dashboardPickerWhole => 'Plancia intera';

  @override
  String get dashboardPickerBuildsOwn => 'Crea le proprie viste';

  @override
  String get dashboardPickerIngressPage => 'Pagina ingress';

  @override
  String get dashboardPickerBuiltInPage => 'Pagina di Home Assistant';

  @override
  String get dashboardPickerWholeHelp =>
      'Questa plancia crea le proprie viste, quindi il kiosk la apre per intero.';

  @override
  String dashboardPickerViewCount(String count) {
    return '$count viste';
  }

  @override
  String get dashboardPickerOneView => '1 vista';

  @override
  String get dashboardPickerOffline => 'Impossibile raggiungere Home Assistant';

  @override
  String get dashboardPickerOfflineHelp =>
      'Le plance verranno caricate quando la connessione tornerà disponibile.';

  @override
  String get dashboardPickerTryAgain => 'Riprova';

  @override
  String get dashboardPickerEmpty => 'Ancora nessuna plancia';

  @override
  String get dashboardPickerEmptyHelp =>
      'Le plance che aggiungi in Home Assistant compaiono qui.';

  @override
  String get dashboardPickerNoMatch => 'Nessuna vista corrispondente';

  @override
  String dashboardPickerSelected(String count) {
    return '$count selezionate';
  }

  @override
  String get dashboardPickerDone => 'Fine';

  @override
  String get dashboardPickerShowing => 'Visualizzata';

  @override
  String get dashboardPickerMissing =>
      'Questa vista non esiste più in Home Assistant. Scegline un\'altra.';

  @override
  String get dashboardPickerAddViews => 'Aggiungi viste';

  @override
  String get dashboardPickerDefault => 'Plancia predefinita';

  @override
  String get dashboardPickerDefaultHelp =>
      'La vista che il kiosk mostra all\'avvio.';

  @override
  String get dashboardPickerOnePage => '1 pagina';

  @override
  String dashboardPickerPageCount(String count) {
    return '$count pagine';
  }

  @override
  String get dlnaCannotDecode =>
      'Questo dispositivo non può decodificare questo video.';

  @override
  String get dlnaCannotRead => 'Impossibile leggere questo file.';

  @override
  String get dlnaCannotPlay => 'Impossibile riprodurre questo contenuto.';

  @override
  String get dlnaSeeLogs => 'Consulta i registri dell\'app per i dettagli';

  @override
  String get dlnaLoading => 'Caricamento del contenuto';

  @override
  String get dlnaImageFailed => 'Impossibile visualizzare questa immagine.';

  @override
  String get dlnaStop => 'Interrompi la riproduzione';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName: $actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => 'Azione del plugin';

  @override
  String get drawerPluginActionError => 'Impossibile eseguire questa azione.';

  @override
  String get drawerDashboard => 'Plancia';

  @override
  String get drawerHaKiosk => 'Modalità kiosk di HA';

  @override
  String get drawerCameraView => 'Vista telecamere';

  @override
  String get drawerIntercom => 'Interfono';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => 'Nascondi lettore mobile';

  @override
  String get drawerShowPlayer => 'Mostra lettore mobile';

  @override
  String get drawerNowPlaying => 'In riproduzione';

  @override
  String get drawerScreensaver => 'Avvia salvaschermo';

  @override
  String get drawerLockdown => 'Modalità blocco';

  @override
  String get drawerHoldOff => 'Disattiva modalità pausa';

  @override
  String get drawerHoldOn => 'Attiva modalità pausa';

  @override
  String get drawerApps => 'App';

  @override
  String get drawerClearCache => 'Svuota cache web';

  @override
  String get drawerRestartDevice => 'Riavvia dispositivo';

  @override
  String get drawerRestartConfirm =>
      'Riavviare questo dispositivo? Kiosk Satellite si riapre all\'avvio.';

  @override
  String get drawerRestart => 'Riavvia';

  @override
  String get drawerExitApplication => 'Esci dall\'app';

  @override
  String get drawerExitConfirm => 'Chiudere Kiosk Satellite?';

  @override
  String get drawerExit => 'Esci';

  @override
  String get drawerHoldActive => 'La modalità pausa è attiva';

  @override
  String get drawerHoldHelp =>
      'Salvaschermo e timer in pausa · tocca per disattivare';

  @override
  String get drawerThemeDark => 'Scuro';

  @override
  String get drawerThemeLight => 'Chiaro';

  @override
  String get drawerThemeAndroid => 'Segui Android';

  @override
  String get drawerItemsSearch => 'Cerca voci del menu';

  @override
  String get drawerItemsSettingsKept =>
      'Sempre visibile mentre l\'amministrazione remota è disattivata.';

  @override
  String drawerVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get drawerUpdateAvailable => 'Aggiornamento disponibile';

  @override
  String drawerUpdateInstall(String version) {
    return 'Versione $version · tocca per installare';
  }

  @override
  String get drawerUpdateChecking => 'Ricerca aggiornamenti…';

  @override
  String get drawerUpdateCurrent => 'App aggiornata';

  @override
  String get drawerUpdateCurrentHelp => 'Hai la versione più recente.';

  @override
  String get drawerUpdateCheckFailed => 'Ricerca aggiornamenti non riuscita';

  @override
  String get drawerUpdateOffline => 'Il dispositivo è connesso a Internet?';

  @override
  String drawerUpdateTo(String version) {
    return 'Aggiorna alla $version';
  }

  @override
  String get drawerUpdateInstructions =>
      'Il download inizia quando tocchi Aggiorna. Android ti chiederà di confermare l\'installazione.';

  @override
  String get drawerUpdateRelaunch =>
      'Senza l\'autorizzazione \"Mostra sopra altre app\" l\'app non può riaprirsi dopo l\'aggiornamento.';

  @override
  String get drawerUpdate => 'Aggiorna';

  @override
  String get drawerUpdateDownloading => 'Download dell\'aggiornamento';

  @override
  String get drawerUpdateStarting => 'Avvio…';

  @override
  String get drawerUpdateFailed => 'Aggiornamento non riuscito';

  @override
  String get drawerUpdates => 'Aggiornamenti';

  @override
  String get drawerNoReleaseNotes => 'Nessuna nota di rilascio.';

  @override
  String get entityPickerNoArea => 'Nessuna area';

  @override
  String get entityPickerAll => 'Tutte';

  @override
  String get entityPickerChoose => 'Scegli un\'entità';

  @override
  String get entityPickerNoMatch => 'Nessun risultato';

  @override
  String get entityPickerOfflineHelp =>
      'Le entità verranno caricate quando la connessione tornerà disponibile.';

  @override
  String get entityPickerMissing =>
      'Questa entità non esiste più in Home Assistant. Scegline un\'altra.';

  @override
  String get entityPickerOrderHint =>
      'Trascina o usa le frecce per cambiare l\'ordine.';

  @override
  String get entityPickerFull => 'Rimuovine una per aggiungerne un\'altra.';

  @override
  String get entityPickerAdd => 'Aggiungi entità';

  @override
  String entityPickerShowing(String count, String max) {
    return '$count di $max mostrate';
  }

  @override
  String get esphomeAllExposed => 'Tutte le entità disponibili esposte';

  @override
  String esphomeExcludedCount(String count) {
    return '$count escluse';
  }

  @override
  String get esphomeEntitySearch => 'Cerca entità';

  @override
  String get esphomeEntityLoading => 'Caricamento entità…';

  @override
  String get esphomeEntityUnavailable => 'Al momento non disponibile';

  @override
  String get esphomeEntityNoMatch => 'Nessuna entità corrispondente';

  @override
  String get esphomeEntityLoadFailed =>
      'Impossibile caricare le entità. Chiudi il selettore e riprova.';

  @override
  String get esphomeEntitySaveFailed =>
      'Impossibile salvare le esclusioni. Riprova.';

  @override
  String get esphomeTypeConfig => 'Configurazione';

  @override
  String get esphomeTypeDiagnostics => 'Diagnostica';

  @override
  String get esphomeTypeSensorGroup => 'Sensore';

  @override
  String get esphomeTypeControl => 'Controllo';

  @override
  String get esphomeTypeSensor => 'sensore';

  @override
  String get esphomeTypeTextSensor => 'sensore di testo';

  @override
  String get esphomeTypeBinarySensor => 'sensore binario';

  @override
  String get esphomeTypeCamera => 'telecamera';

  @override
  String get esphomeTypeSwitch => 'interruttore';

  @override
  String get esphomeTypeButton => 'pulsante';

  @override
  String get esphomeTypeNumber => 'numero';

  @override
  String get esphomeTypeSelect => 'selezione';

  @override
  String get esphomeTypeLight => 'luce';

  @override
  String get esphomeTypeUpdate => 'aggiornamento';

  @override
  String get esphomeTypeText => 'testo';

  @override
  String faceEnrollTitle(String name) {
    return 'Registrazione di $name';
  }

  @override
  String faceEnrollStepOf(String step, String total) {
    return 'Passo $step di $total';
  }

  @override
  String get faceEnrollStepLook => 'Guarda lo schermo';

  @override
  String get faceEnrollStepSideA => 'Gira un po\' la testa da un lato';

  @override
  String get faceEnrollStepSideB => 'Ora un po\' dall\'altro lato';

  @override
  String get faceEnrollStepFar => 'Fai un passo indietro';

  @override
  String get faceEnrollHintNoFace => 'Nessun volto inquadrato';

  @override
  String get faceEnrollHintSeveral => 'Deve essere inquadrata una sola persona';

  @override
  String get faceEnrollHintCloser => 'Avvicinati un po\'';

  @override
  String get faceEnrollHintFarther => 'Allontanati ancora un po\'';

  @override
  String get faceEnrollHintTurnMore => 'Gira ancora un po\'';

  @override
  String get faceEnrollHintTurnLess => 'Gira un po\' meno';

  @override
  String get faceEnrollHintOtherSide => 'Ora dall\'altro lato';

  @override
  String get faceEnrollHintDark => 'Troppo buio per vedere il tuo volto';

  @override
  String get faceEnrollHintOtherFace => 'Questo è un volto diverso';

  @override
  String faceEnrollSaved(String name) {
    return 'Volto registrato per $name';
  }

  @override
  String get faceEnrollSavedPartly =>
      'Il volto è stato registrato solo in parte. Ripeti la registrazione per completarla.';

  @override
  String get faceEnrollTooShort =>
      'Il volto non è stato visto abbastanza a lungo. Non è stato salvato nulla.';

  @override
  String get faceEnrollUnavailable =>
      'Il riconoscimento facciale richiede Ground Control con Vision Match e il riconoscimento facciale attivi.';

  @override
  String get faceEnrollLost =>
      'La connessione a Ground Control si è interrotta. Non è stato salvato nulla.';

  @override
  String get filesUpload => 'Carica file';

  @override
  String get filesUploading => 'Caricamento…';

  @override
  String get filesUploadFailed => 'Caricamento non riuscito';

  @override
  String get filesUploaded => 'Caricato';

  @override
  String filesUploadingProgress(String current, String total) {
    return 'Caricamento di $current di $total…';
  }

  @override
  String filesUploadedCount(String count) {
    return '$count file caricati';
  }

  @override
  String get filesPermissionMissing =>
      'Autorizzazione \"Accesso a tutti i file\" mancante';

  @override
  String get filesPermissionHelp =>
      'Senza questa autorizzazione puoi sfogliare solo la cartella dell\'app. La schermata per concederla si apre sul tablet.';

  @override
  String get filesGrant => 'Concedi sul dispositivo';

  @override
  String get filesUp => 'Cartella superiore';

  @override
  String get filesShared => 'Memoria condivisa';

  @override
  String get filesApp => 'Cartella dell\'app';

  @override
  String get filesReadFailed => 'Impossibile leggere la cartella';

  @override
  String get filesEmpty => 'Cartella vuota';

  @override
  String get filesEmptyHelp => 'Qui non c\'è ancora niente.';

  @override
  String get filesFolder => 'Cartella';

  @override
  String get filesDownload => 'Scarica';

  @override
  String get filesDownloadFailed => 'Download non riuscito';

  @override
  String filesDeleteTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get filesDeleteHelp => 'Il file viene rimosso dal dispositivo.';

  @override
  String get filesInvalidPath => 'Percorso non valido';

  @override
  String get filesNoFolder => 'La cartella non esiste';

  @override
  String get filesNoFile => 'Il file non esiste';

  @override
  String filesReadError(String error) {
    return 'Impossibile leggere la cartella: $error';
  }

  @override
  String filesWriteError(String error) {
    return 'Scrittura non riuscita: $error';
  }

  @override
  String get filesDeleteFailed => 'Impossibile eliminare il file';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin =>
      'Gestione flotta richiede l\'amministrazione remota';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'I kiosk si trovano a vicenda tramite l\'amministrazione remota. Attiva Amministrazione remota e Trova altri kiosk in Dispositivo, poi torna qui.';

  @override
  String get fleetLeadThisFleet => 'Guida questa flotta';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      'Sincronizza le impostazioni di questo kiosk con i suoi follower. Tutti i kiosk devono avere la stessa versione.';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead =>
      'Un kiosk che segue un leader non può guidare una flotta.';

  @override
  String get fleetFollowers => 'Follower';

  @override
  String get fleetProfiles => 'Profili';

  @override
  String get fleetLeader => 'Leader';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      'Scopri quali impostazioni vengono sincronizzate e quali no nella ';

  @override
  String get fleetFleetManagementDocumentation =>
      'documentazione di Gestione flotta';

  @override
  String get fleetMore => 'Altro';

  @override
  String get fleetSearchFollowers =>
      'I kiosk guidati da questo, il loro stato e un modo per aggiungerne uno.';

  @override
  String get fleetAddAKiosk => 'Aggiungi un kiosk';

  @override
  String get fleetAddAKioskFollowerAcceptsOnScreenOrRemoteAdmin =>
      'Aggiungi un kiosk rilevato o inserisci il suo indirizzo IP. Il follower accetta l\'invito sul proprio schermo o nella propria amministrazione remota.';

  @override
  String get fleetSendInvitation => 'Invia invito';

  @override
  String get fleetInviteAgain => 'Invita di nuovo';

  @override
  String fleetRemoveName(String name) {
    return 'Rimuovere $name?';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      'Smette di seguire questo kiosk e mantiene le proprie impostazioni.';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name vuole guidare questo kiosk';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      'Da ora in poi le sue impostazioni sostituiscono quelle di questo kiosk nelle categorie che sincronizza. Questo kiosk mantiene il proprio nome e la propria identità.';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      'Da ora in poi le sue impostazioni sostituiscono quelle di questo kiosk nelle categorie che sincronizza. Questo kiosk mantiene il proprio nome, le proprie identità in Home Assistant, Music Assistant ed ESPHome e i dispositivi hardware scelti. Puoi lasciare la flotta in qualsiasi momento in Impostazioni, Gestione flotta.';

  @override
  String get fleetAccept => 'Accetta';

  @override
  String get fleetLookingForOtherKiosks => 'Ricerca di altri kiosk…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      'Nessun kiosk rilevato. Usa Aggiungi tramite IP per trovarne uno a un indirizzo noto.';

  @override
  String fleetFollowsName(String name) {
    return 'Segue $name';
  }

  @override
  String get fleetLeadsAFleet => 'Guida una flotta';

  @override
  String get fleetNoFleetManagement => 'Senza Gestione flotta';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      'Kiosk in questa rete che non seguono questo. Selezionane uno per scegliere cosa riceve, poi l\'invito viene inviato. Un kiosk con una build priva di Gestione flotta si unirà quando ne userà una che la include.';

  @override
  String get fleetJoinedTheFleet => 'Ora fa parte della flotta';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly =>
      'Le impostazioni del leader arriveranno a breve.';

  @override
  String get fleetAddByIp => 'Aggiungi tramite IP';

  @override
  String get fleetFindKiosk => 'Trova kiosk';

  @override
  String get fleetFindingKiosk => 'Ricerca del kiosk…';

  @override
  String get fleetIpAddress => 'Indirizzo IP';

  @override
  String get fleetRemoteAdminPort => 'Porta dell\'amministrazione remota';

  @override
  String get fleetAddressHelp =>
      'Inserisci l\'indirizzo IP del kiosk e la porta dell\'amministrazione remota.';

  @override
  String get fleetAddAProfile => 'Aggiungi un profilo';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      'L\'insieme di impostazioni, credenziali ed esclusioni da sincronizzare.';

  @override
  String get fleetNewProfile => 'Nuovo profilo';

  @override
  String get fleetProfile => 'Profilo';

  @override
  String get fleetUpdatesOnly => 'Solo aggiornamenti';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed =>
      'Non viene sincronizzato nulla. Vengono inviati solo gli aggiornamenti.';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return 'Categorie: $selected di $total. Credenziali: $credentials di $credentialTotal. Escluse: $excluded.';
  }

  @override
  String get fleetThisProfileIsGone => 'Questo profilo non esiste più';

  @override
  String get fleetItWasDeletedFromAnotherPage =>
      'È stato eliminato da un\'altra pagina.';

  @override
  String get fleetName => 'Nome';

  @override
  String get fleetRename => 'Rinomina';

  @override
  String get fleetRenameProfile => 'Rinomina profilo';

  @override
  String get fleetWhatItSyncs => 'Cosa sincronizza';

  @override
  String get fleetNothing => 'Niente';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      'I kiosk con questo profilo mantengono tutte le proprie impostazioni. Il leader invia loro solo gli aggiornamenti.';

  @override
  String get fleetCategories => 'Categorie';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected di $total: $names';
  }

  @override
  String get fleetCredentials => 'Credenziali';

  @override
  String get fleetNoneTravel => 'Nessuna inviata';

  @override
  String get fleetIncludeTheDashboard => 'Includi la plancia';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard =>
      'La pagina iniziale e la plancia predefinita.';

  @override
  String get fleetExcludedSettings => 'Impostazioni escluse';

  @override
  String get fleetOneSettingLeftOut => 'Un\'impostazione esclusa';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return '$count impostazioni escluse';
  }

  @override
  String get fleetNoKiosksAssigned => 'Nessun kiosk assegnato';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      'Assegna questo profilo a un kiosk nella pagina Gestione flotta.';

  @override
  String get fleetDuplicate => 'Duplica';

  @override
  String get fleetCloneThisProfileIntoANewOne =>
      'Crea un nuovo profilo copiando questo.';

  @override
  String get fleetDuplicateProfile => 'Duplica profilo';

  @override
  String fleetNameCopy(String name) {
    return 'Copia di $name';
  }

  @override
  String get fleetDeleteProfile => 'Elimina profilo';

  @override
  String get fleetNoKioskIsOnIt => 'Nessun kiosk lo usa.';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile =>
      'I kiosk che lo usano ricevono il profilo Predefinito.';

  @override
  String fleetDeleteName(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get fleetBlackScreens => 'Schermi neri';

  @override
  String fleetSyncToName(String name) {
    return 'Sincronizza con $name';
  }

  @override
  String get fleetDefault => 'Predefinito';

  @override
  String get fleetNone => 'Nessuna';

  @override
  String get fleetSearchProfiles =>
      'Gli elenchi con nome che si possono assegnare a un follower: categorie, credenziali, la plancia e le impostazioni escluse.';

  @override
  String get fleetSyncNow => 'Sincronizza ora';

  @override
  String get fleetChangedHereWaitingForTheLeader =>
      'Modificato qui, in attesa del leader';

  @override
  String fleetSyncedTime(String time) {
    return 'Sincronizzato $time';
  }

  @override
  String get fleetWaitingForTheFirstSync =>
      'In attesa della prima sincronizzazione';

  @override
  String get fleetNothingYet => 'Ancora niente';

  @override
  String get fleetNoCredentials => 'Nessuna credenziale';

  @override
  String fleetWithTheNames(String names) {
    return 'Con $names';
  }

  @override
  String get fleetTheDashboard => 'la plancia';

  @override
  String get fleetNoDashboard => 'nessuna plancia';

  @override
  String get fleetTheDashboardDetail => 'La plancia';

  @override
  String get fleetNoDashboardDetail => 'Nessuna plancia';

  @override
  String get fleetSyncedFromTheLeader => 'Sincronizzato dal leader';

  @override
  String get fleetLeaveTheFleet => 'Lascia la flotta';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre =>
      'Interrompe la sincronizzazione. Le impostazioni restano come sono.';

  @override
  String get fleetLeaveTheFleetDetail => 'Lasciare la flotta?';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name smette di inviare impostazioni a questo kiosk. Tutto resta com\'è ora.';
  }

  @override
  String get fleetLeave => 'Lascia';

  @override
  String get fleetJustNow => 'poco fa';

  @override
  String fleetCountMinAgo(String count) {
    return '$count min fa';
  }

  @override
  String fleetCountHAgo(String count) {
    return '$count h fa';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return '$count giorni fa';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return '$name gestisce queste impostazioni. Una modifica fatta qui viene sostituita alla prossima sincronizzazione.';
  }

  @override
  String get fleetDeclinedOnTheKiosk => 'Rifiutato sul kiosk';

  @override
  String get fleetWaitingForItsOk => 'In attesa della conferma';

  @override
  String get fleetLeftTheFleet => 'Ha lasciato la flotta';

  @override
  String fleetSendingPercent(String percent) {
    return 'Invio $percent%';
  }

  @override
  String get fleetInstalling => 'Installazione in corso';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return 'Usa la $version, questo kiosk deve essere aggiornato';
  }

  @override
  String fleetNeedsVersion(String version) {
    return 'Richiede la $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return 'Download $percent%';
  }

  @override
  String get fleetSyncing => 'Sincronizzazione…';

  @override
  String get fleetErrorUnreachable => 'Non raggiungibile';

  @override
  String get fleetErrorBadAnswer => 'Risposta non valida';

  @override
  String get fleetErrorThePushFailed => 'Invio non riuscito';

  @override
  String get fleetErrorLeadThisFleetIsOff =>
      'L\'opzione Guida questa flotta è disattivata';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      'L\'amministrazione remota e Trova altri kiosk devono essere attivi';

  @override
  String get fleetErrorPickAnotherKiosk => 'Scegli un altro kiosk';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      'Quel kiosk al momento non è in rete';

  @override
  String get fleetErrorThatKioskDidNotAnswer => 'Quel kiosk non ha risposto';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation =>
      'Quel kiosk ha rifiutato l\'invito';

  @override
  String get fleetErrorTheDefaultProfileStays =>
      'Il profilo Predefinito non si può eliminare';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays =>
      'Il profilo Solo aggiornamenti non si può eliminare';

  @override
  String get fleetErrorNoSuchProfile => 'Il profilo non esiste';

  @override
  String get fleetErrorNoSuchFollower => 'Il follower non esiste';

  @override
  String get fleetErrorNoInvitationIsWaiting => 'Nessun invito in attesa';

  @override
  String get fleetErrorMalformedInvitation => 'Invito non valido';

  @override
  String get fleetErrorCouldNotMintAToken => 'Impossibile generare un token';

  @override
  String get fleetErrorNotAFollowerYet => 'non è ancora un follower';

  @override
  String get fleetErrorOffline => 'offline';

  @override
  String get fleetErrorUpToDate => 'aggiornato';

  @override
  String get fleetErrorAlreadyDownloading => 'download già in corso';

  @override
  String get fleetErrorDidNotAnswer => 'non ha risposto';

  @override
  String get fleetErrorDidNotTakeTheUpload => 'non ha accettato il caricamento';

  @override
  String fleetProfileNameExists(String name) {
    return 'Esiste già un profilo chiamato $name';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return 'ha già la $version';
  }

  @override
  String get fleetUnsupportedBuild =>
      'Quel kiosk usa una build priva di Gestione flotta. Si unirà quando ne userà una che la include.';

  @override
  String get fleetErrorAddressMismatch =>
      'L\'indirizzo appartiene a un altro kiosk o a un\'altra flotta';

  @override
  String get fleetErrorInvalidIp => 'Inserisci un indirizzo IP valido.';

  @override
  String get fleetErrorInvalidPort => 'Inserisci una porta da 1 a 65535.';

  @override
  String get fleetErrorIdentityNotReady =>
      'L\'identità di questo kiosk non è ancora pronta. Riprova.';

  @override
  String get fleetErrorInvalidIdentity =>
      'Quell\'indirizzo non ha restituito un\'identità di kiosk valida.';

  @override
  String get fleetErrorAlreadyMember =>
      'Questo kiosk fa già parte di questa flotta.';

  @override
  String get fleetErrorIsLeader => 'Quel kiosk guida una flotta.';

  @override
  String get fleetErrorOtherLeader => 'Quel kiosk segue già un altro leader.';

  @override
  String fleetPluginsNames(String names) {
    return 'Plugin: $names';
  }

  @override
  String fleetCouldNotInstallNameReason(String name, String reason) {
    return 'Impossibile installare $name: $reason';
  }

  @override
  String fleetReinstallNameOnThisKioskToSyncIt(String name) {
    return 'Reinstalla $name su questo kiosk per sincronizzarlo';
  }

  @override
  String get fleetSwitchKiosk => 'Cambia kiosk';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      'Kiosk rilevati e membri salvati della flotta. Selezionandone uno, la sua amministrazione remota si apre qui, in questa stessa pagina.';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      'Nessun altro kiosk trovato. I kiosk compaiono tramite il rilevamento in rete o perché salvati come membri della flotta.';

  @override
  String get fleetSyncedCredentials => 'Credenziali sincronizzate';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced =>
      'Le impostazioni in questo elenco non verranno sincronizzate con i follower.';

  @override
  String get fleetNothingLeftOut => 'Nessuna esclusione';

  @override
  String get fleetSyncItAgain => 'Sincronizza di nuovo';

  @override
  String get fleetAddASetting => 'Aggiungi un\'impostazione';

  @override
  String get fleetExcludeASetting => 'Escludi un\'impostazione';

  @override
  String get fleetSearchSettings => 'Cerca impostazioni';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return 'Altre $count. Digita per restringere l\'elenco.';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return 'Non sincronizzato: $note';
  }

  @override
  String get fleetTheAssignedSatellite => 'il satellite assegnato';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain =>
      'dispositivi di microfono e altoparlante, guadagno del microfono';

  @override
  String get fleetTheDeviceCamera => 'la fotocamera del dispositivo';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      'il lettore seguito, l\'ID del lettore Sendspin';

  @override
  String get fleetNodeNameMacEncryptionKey =>
      'nome del nodo, MAC, chiave di crittografia';

  @override
  String get fleetThePinIsAlsoSynced => 'viene sincronizzato anche il PIN';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential =>
      'la chiave, se non sincronizzata come credenziale';

  @override
  String get fleetTheAlarmsThemselves => 'le sveglie stesse';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'nome, amministrazione remota, soluzioni alternative del renderer, scala';

  @override
  String get fleetHomeAssistantToken => 'Token di Home Assistant';

  @override
  String get fleetMusicAssistantToken => 'Token di Music Assistant';

  @override
  String get fleetImmichApiKey => 'Chiave API di Immich';

  @override
  String get fleetOpenAiApiKey => 'Chiave API di OpenAI';

  @override
  String get fleetXaiApiKey => 'Chiave API di xAI';

  @override
  String get fleetGeminiApiKey => 'Chiave API di Gemini';

  @override
  String get fleetMcpServerToken => 'Token del server MCP';

  @override
  String get fleetPlugins => 'Plugin';

  @override
  String get fleetPluginSecrets => 'Segreti dei plugin';

  @override
  String get fleetNoPluginsInstalledOnThisKiosk =>
      'Nessun plugin installato su questo kiosk';

  @override
  String get fleetKiosksOnThisProfileInstallTheseAndTakeTheir =>
      'I kiosk con questo profilo li installano e ricevono le relative impostazioni da questo kiosk.';

  @override
  String get fleetUpdateTheFleet => 'Aggiorna la flotta';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      'Aggiorna l\'intera flotta alla versione di Kiosk Satellite in uso sul leader.';

  @override
  String get fleetKeepFollowersOnThisVersion =>
      'Mantieni i follower su questa versione';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      'Aggiorna automaticamente tutti i follower alla versione di Kiosk Satellite in uso sul leader.';

  @override
  String get fleetNothingToUpdate => 'Niente da aggiornare';

  @override
  String get fleetUpdating => 'Aggiornamento in corso';

  @override
  String fleetNamesInstalling(String names) {
    return 'Installazione in corso su $names.';
  }

  @override
  String get fleetSearchUpdates =>
      'Installa la versione proposta su ogni follower, poi qui.';

  @override
  String get gestureAction => 'Azione';

  @override
  String get gestureNavigate => 'Vai a una vista della plancia';

  @override
  String get gestureUrl => 'Apri una pagina web';

  @override
  String get gestureCameraView => 'Mostra una vista telecamere';

  @override
  String get gestureLauncher => 'Apri il launcher app';

  @override
  String get gestureIntercomOpen => 'Apri Chiama un kiosk';

  @override
  String get gestureIntercomCall => 'Chiama un kiosk';

  @override
  String get gestureIntercomHangup => 'Termina la chiamata dell\'interfono';

  @override
  String get gestureIntercomAnswer => 'Accetta la chiamata dell\'interfono';

  @override
  String get gestureIntercomDecline => 'Rifiuta la chiamata dell\'interfono';

  @override
  String get gestureAlarmStop => 'Ferma la sveglia';

  @override
  String get gestureAlarmSnooze => 'Posticipa la sveglia';

  @override
  String get gestureScreensaver => 'Avvia il salvaschermo';

  @override
  String get gestureScreensaverStop => 'Ferma il salvaschermo';

  @override
  String get gestureHoldMode => 'Attiva o disattiva la modalità pausa';

  @override
  String get gestureRefresh => 'Aggiorna la plancia';

  @override
  String get gestureMediaPlayPause =>
      'Riproduci o metti in pausa i contenuti multimediali';

  @override
  String get gestureHaKiosk => 'Attiva o disattiva la modalità kiosk di HA';

  @override
  String get gesturePluginRun => 'Esegui un\'azione di un plugin';

  @override
  String get gestureLaunchApp => 'Apri un\'altra app';

  @override
  String get gestureDeepLink => 'Apri un deep link';

  @override
  String get gestureAndroidSettings => 'Apri le impostazioni di Android';

  @override
  String get gestureOpenCalendar => 'Apri il calendario';

  @override
  String get gestureOpenMusicLibrary => 'Apri la Libreria musicale';

  @override
  String get gestureService => 'Chiama un servizio';

  @override
  String get gestureScript => 'Esegui uno script';

  @override
  String get gestureAutomation => 'Attiva un\'automazione';

  @override
  String get gestureEvent => 'Genera un evento';

  @override
  String get gesturePluginAction => 'Azione del plugin';

  @override
  String get gesturePluginActions => 'Azioni dei plugin';

  @override
  String get gesturePluginHelp =>
      'Prima abilita in Gestione plugin un plugin che offre azioni.';

  @override
  String get gesturePluginFailed =>
      'Impossibile caricare le azioni dei plugin.';

  @override
  String get gestureUrlError => 'Inserisci un URL http(s) completo.';

  @override
  String get gesturePackage => 'Nome del pacchetto';

  @override
  String get gesturePackageError => 'Inserisci il nome di un pacchetto.';

  @override
  String get gestureUriError => 'Inserisci un URI completo.';

  @override
  String get gestureCameraTitle => 'Vista telecamere';

  @override
  String gestureCameraShow(String name) {
    return 'Mostra $name';
  }

  @override
  String get gestureCameraClose => 'Chiudi la vista telecamere';

  @override
  String get gestureCameraEmpty =>
      'Nessuna vista telecamere ancora configurata.';

  @override
  String get gestureIntercomEmpty => 'Nessun kiosk ancora trovato sulla rete.';

  @override
  String get gestureVoiceWake => 'Avvia un comando vocale';

  @override
  String get gestureVoiceStop => 'Ferma l\'assistente vocale';

  @override
  String get gestureVoiceMute =>
      'Disattiva o riattiva il microfono di Voice Satellite';

  @override
  String get gestureOpenAlarmList => 'Apri l\'elenco delle sveglie';

  @override
  String get gestureOpenTimers => 'Apri i timer';

  @override
  String get gestureOpenNextAlarm => 'Apri la prossima sveglia';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '$count tocchi nell\'angolo $corner';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return 'Tieni premuto l\'angolo $corner per ${seconds}s';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return 'Doppio tocco con $count dita';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return 'Tocco con $count dita';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return 'Pressione prolungata con $count dita per ${seconds}s';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return 'Sequenza di angoli: $sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '$count battiti di mani';
  }

  @override
  String get gestureDescribeOpenHand => 'Mostra una mano aperta';

  @override
  String gestureDescribeOneFinger(String count) {
    return 'Mostra $count dito';
  }

  @override
  String gestureDescribeFingers(String count) {
    return 'Mostra $count dita';
  }

  @override
  String get gestureTopLeft => 'in alto a sinistra';

  @override
  String get gestureTopRight => 'in alto a destra';

  @override
  String get gestureBottomLeft => 'in basso a sinistra';

  @override
  String get gestureBottomRight => 'in basso a destra';

  @override
  String gestureGoTo(String value) {
    return 'Vai a $value';
  }

  @override
  String gestureOpen(String value) {
    return 'Apri $value';
  }

  @override
  String get gestureCameraToggle => 'Mostra o nascondi la vista telecamere';

  @override
  String gestureCameraToggleName(String name) {
    return 'Mostra o nascondi la vista telecamere $name';
  }

  @override
  String gestureCall(String value) {
    return 'Chiama $value';
  }

  @override
  String gestureOpenApp(String package) {
    return 'Apri l\'app $package';
  }

  @override
  String gestureRun(String value) {
    return 'Esegui $value';
  }

  @override
  String gestureTriggerAction(String value) {
    return 'Attiva $value';
  }

  @override
  String gestureFireEvent(String value) {
    return 'Genera l\'evento $value';
  }

  @override
  String gestureDescribeButtonPress(String button) {
    return 'Premi il tasto $button';
  }

  @override
  String gestureDescribeButtonDouble(String button) {
    return 'Premi due volte il tasto $button';
  }

  @override
  String gestureDescribeButtonHold(String button) {
    return 'Tieni premuto il tasto $button';
  }

  @override
  String get gestureValid => 'Tutto a posto.';

  @override
  String get gestureValidationFailed => 'Impossibile convalidare.';

  @override
  String gestureDomainMissing(String value) {
    return 'Dominio $value non trovato.';
  }

  @override
  String gestureServiceMissing(String value) {
    return 'Servizio $value non trovato.';
  }

  @override
  String gestureEntityMissing(String value) {
    return 'Entità $value non trovata.';
  }

  @override
  String gestureEntityRequired(String domain) {
    return 'Inserisci un\'entità $domain.*.';
  }

  @override
  String get gestureScriptEntity => 'Entità dello script';

  @override
  String get gestureAutomationEntity => 'Entità dell\'automazione';

  @override
  String get gestureEntityOptional => 'Entità (facoltativa)';

  @override
  String get gestureServiceData => 'Dati del servizio (facoltativi)';

  @override
  String get gestureServiceTitle => 'Chiama un servizio di Home Assistant';

  @override
  String get gestureServiceJson =>
      'I dati del servizio devono essere un oggetto JSON.';

  @override
  String get gestureEventType => 'Tipo di evento';

  @override
  String get gestureEventData => 'Dati dell\'evento (facoltativi)';

  @override
  String get gestureEventTitle => 'Genera un evento di Home Assistant';

  @override
  String get gestureEventRequired => 'Il tipo di evento è obbligatorio.';

  @override
  String get gestureEventJson =>
      'I dati dell\'evento devono essere un oggetto JSON.';

  @override
  String get gestureServiceSearch => 'Cerca servizi';

  @override
  String get gestureServiceChoose => 'Scegli un servizio';

  @override
  String get gestureServiceNoEntity => 'Non usata da questo servizio';

  @override
  String get gestureTester => 'Test dei gesti della mano';

  @override
  String get gestureOpenTester => 'Apri il test';

  @override
  String get gestureCameraFirst =>
      'Prima attiva la fotocamera nelle impostazioni Fotocamera.';

  @override
  String get gestureTesterHelp =>
      'Osserva quali dita rileva la fotocamera, per capire come tenere la mano.';

  @override
  String get gestureHandHelp =>
      'Tieni la mano sollevata all\'altezza della spalla, con il palmo verso la fotocamera e le dita aperte. Piega del tutto un dito per escluderlo dal conteggio. Piega il pollice sul palmo per mostrare quattro: il pollice conta solo con la mano aperta.';

  @override
  String get gestureTesterPaused =>
      'I gesti non si attivano mentre il test è aperto.';

  @override
  String get gestureShowHand => 'Mostra una mano alla fotocamera.';

  @override
  String gestureTesterTrigger(String action) {
    return 'Attiva: $action';
  }

  @override
  String get gestureNoCount => 'Nessun gesto usa questo numero di dita.';

  @override
  String get gestureNoHand => 'Nessuna mano inquadrata';

  @override
  String get gestureReadingHand => 'Lettura della mano';

  @override
  String get gestureNoFingers => 'Nessun dito alzato';

  @override
  String gestureHandsCount(String count) {
    return '$count mani inquadrate, viene letta la più grande.';
  }

  @override
  String get gestureTesterSearch =>
      'Mostra in tempo reale le dita rilevate dalla fotocamera.';

  @override
  String get gestureHoldConfirmed => 'Mantenimento confermato';

  @override
  String gestureHoldProgress(String progress) {
    return 'Avanzamento del mantenimento: $progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return 'Durata del mantenimento: $duration';
  }

  @override
  String get gestureHaServiceKind => 'Servizio di Home Assistant';

  @override
  String get gestureHaScriptKind => 'Script di Home Assistant';

  @override
  String get gestureHaAutomationKind => 'Automazione di Home Assistant';

  @override
  String get gestureHaEventKind => 'Evento di Home Assistant';

  @override
  String gestureRan(String value) {
    return '$value eseguito';
  }

  @override
  String gestureRunFailed(String value) {
    return 'Impossibile eseguire $value';
  }

  @override
  String gestureCalled(String value) {
    return '$value chiamato';
  }

  @override
  String gestureCallFailed(String value) {
    return 'Impossibile chiamare $value';
  }

  @override
  String gestureTriggered(String value) {
    return '$value attivato';
  }

  @override
  String gestureTriggerFailed(String value) {
    return 'Impossibile attivare $value';
  }

  @override
  String gestureFired(String value) {
    return 'Evento $value generato';
  }

  @override
  String gestureFireFailed(String value) {
    return 'Impossibile generare l\'evento $value';
  }

  @override
  String get gestureDone => 'Fatto';

  @override
  String get gestureFailed => 'Non riuscito';

  @override
  String get gestureEdit => 'Modifica gesto';

  @override
  String get gestureTrigger => 'Gesto';

  @override
  String get gestureCornerTaps => 'Tocchi in un angolo';

  @override
  String get gestureCornerHold => 'Tieni premuto un angolo';

  @override
  String get gestureFingerTaps => 'Tocco con più dita';

  @override
  String get gestureFingerHold => 'Pressione prolungata con più dita';

  @override
  String get gestureSequence => 'Sequenza di angoli';

  @override
  String get gestureClaps => 'Battiti di mani';

  @override
  String get gestureShowFingers => 'Mostra le dita';

  @override
  String get gestureCorner => 'Angolo';

  @override
  String get gestureCornerTl => 'Angolo in alto a sinistra';

  @override
  String get gestureCornerTr => 'Angolo in alto a destra';

  @override
  String get gestureCornerBl => 'Angolo in basso a sinistra';

  @override
  String get gestureCornerBr => 'Angolo in basso a destra';

  @override
  String get gestureTaps => 'Tocchi';

  @override
  String get gestureTaps2 => '2 tocchi';

  @override
  String get gestureTaps3 => '3 tocchi';

  @override
  String get gestureTaps4 => '4 tocchi';

  @override
  String get gestureFingers => 'Dita';

  @override
  String get gestureFinger1 => '1 dito';

  @override
  String get gestureFinger2 => '2 dita';

  @override
  String get gestureFinger3 => '3 dita';

  @override
  String get gestureFinger4 => '4 dita';

  @override
  String get gestureOpenHand5 => 'Mano aperta (5)';

  @override
  String get gestureSingleTap => 'Tocco singolo';

  @override
  String get gestureDoubleTap => 'Doppio tocco';

  @override
  String gestureHoldDuration(String seconds) {
    return 'Mantieni per $seconds s';
  }

  @override
  String get gestureCameraHelp =>
      'Richiede la fotocamera abilitata e un ambiente ben illuminato.';

  @override
  String get gestureUnavailable => 'Non disponibile su questo dispositivo.';

  @override
  String get gestureClaps2 => '2 battiti di mani';

  @override
  String get gestureClaps3 => '3 battiti di mani';

  @override
  String get gestureClaps4 => '4 battiti di mani';

  @override
  String get gestureClapHelp =>
      'I battiti di mani vengono rilevati dal microfono, con o senza il rilevamento della parola di attivazione.';

  @override
  String get gestureSequenceHelp =>
      'Tocca gli angoli in ordine (da 2 a 8 passaggi).';

  @override
  String get gestureRemoveStep => 'Rimuovi l\'ultimo passaggio';

  @override
  String get gestureUndo => 'Annulla';

  @override
  String get gestureChooseAction => 'Scegli un\'azione';

  @override
  String get gestureActionHelp => 'Cosa attiva questo gesto.';

  @override
  String get gestureChangeHelp => 'Tocca per cambiare.';

  @override
  String get gestureChooseError => 'Scegli un\'azione.';

  @override
  String get gestureSequenceError => 'Aggiungi almeno due angoli.';

  @override
  String get gesturePluginTrigger => 'Attivatore del plugin';

  @override
  String get gesturePluginTriggerField => 'Attivatore';

  @override
  String get gesturePluginTriggerHelp =>
      'Prima abilita in Gestione plugin un plugin che offre attivatori.';

  @override
  String get gestureButton => 'Tasto';

  @override
  String get gesturePress => 'Pressione';

  @override
  String get gestureDoublePress => 'Doppia pressione';

  @override
  String get gestureHoldPress => 'Pressione prolungata';

  @override
  String get gestureButtonDefaults =>
      'Una pressione di un tasto non assegnata a nessun gesto mantiene la sua funzione: Azione risponde, ferma o ignora ciò che sta squillando, altrimenti avvia un comando vocale; Microfono disattiva il microfono di Voice Satellite e i tasti del volume regolano il volume.';

  @override
  String get intercomCall => 'Chiama';

  @override
  String get intercomNoReady => 'Nessun kiosk è pronto.';

  @override
  String get intercomOneReady => '1 kiosk è pronto.';

  @override
  String intercomManyReady(String count) {
    return '$count kiosk sono pronti.';
  }

  @override
  String get intercomCallKiosk => 'Chiama un kiosk';

  @override
  String get intercomAnnounceAll => 'Annuncia a tutti';

  @override
  String get intercomAnnounceHelp =>
      'Parla a tutti i kiosk. Comunicazione a senso unico.';

  @override
  String intercomMissedFrom(String name) {
    return 'Chiamata persa da $name';
  }

  @override
  String intercomRangFor(String seconds) {
    return 'Ha squillato per $seconds secondi.';
  }

  @override
  String get intercomCallBack => 'Richiama';

  @override
  String get intercomDeclined => 'Rifiutata';

  @override
  String get intercomBusy => 'Occupato';

  @override
  String get intercomPeerOff => 'Il suo interfono è disattivato';

  @override
  String get intercomPeerKey => 'Chiave dell\'interfono diversa';

  @override
  String get intercomNoAnswer => 'Nessuna risposta';

  @override
  String get intercomDidNotAnswer => 'Non ha risposto';

  @override
  String get intercomVoiceFailed => 'Collegamento vocale non riuscito';

  @override
  String get intercomCancelled => 'Annullata';

  @override
  String get intercomPageMic => 'La pagina ha preso il controllo del microfono';

  @override
  String get intercomNobody => 'Nessuno ha potuto riceverlo';

  @override
  String get intercomDone => 'Terminato';

  @override
  String get intercomEnded => 'Chiamata terminata';

  @override
  String get intercomMaxDurationReached =>
      'Durata massima della chiamata raggiunta';

  @override
  String get intercomAnnouncement => 'Annuncio';

  @override
  String get intercomAnnouncingOne => 'Annuncio a 1 kiosk';

  @override
  String intercomAnnouncingMany(String count) {
    return 'Annuncio a $count kiosk';
  }

  @override
  String get intercomIsCalling => 'sta chiamando';

  @override
  String get intercomIsAnnouncing => 'sta facendo un annuncio';

  @override
  String get intercomCalling => 'Chiamata in corso…';

  @override
  String intercomAnswersWithCameraIn(String seconds) {
    return 'Fotocamera attiva tra $seconds s';
  }

  @override
  String intercomAnswersIn(String seconds) {
    return 'Risposta tra $seconds s';
  }

  @override
  String get intercomRinging => 'Squillo in corso';

  @override
  String get intercomConnecting => 'Connessione…';

  @override
  String intercomDoneDuration(String duration) {
    return 'Terminato, $duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return 'Chiamata terminata, $duration';
  }

  @override
  String get intercomDecline => 'Rifiuta';

  @override
  String get intercomAnswer => 'Rispondi';

  @override
  String get intercomEveryKiosk => 'Tutti i kiosk';

  @override
  String get intercomStop => 'Interrompi';

  @override
  String intercomHearsYou(String name) {
    return '$name ti sente';
  }

  @override
  String get intercomAllHearYou => 'Tutti i kiosk ti sentono';

  @override
  String get intercomHoldHelp =>
      'Tieni premuto per parlare, rilascia per ascoltare';

  @override
  String get intercomMuted => 'Microfono disattivato';

  @override
  String get intercomMute => 'Disattiva microfono';

  @override
  String get intercomEnd => 'Termina';

  @override
  String get intercomReply => 'Rispondi';

  @override
  String get intercomDismiss => 'Ignora';

  @override
  String get intercomCallAgain => 'Chiama di nuovo';

  @override
  String get intercomDashboardMic =>
      'La plancia sta usando il microfono, solo ascolto.';

  @override
  String get intercomMicDenied =>
      'Accesso al microfono non concesso, solo ascolto.';

  @override
  String get intercomHoldTalk => 'Tieni premuto per parlare';

  @override
  String get intercomPlaying => 'In riproduzione';

  @override
  String get intercomAKiosk => 'un kiosk';

  @override
  String intercomCallingName(String name) {
    return 'Chiamata a $name';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name sta chiamando';
  }

  @override
  String intercomInCallName(String name) {
    return 'In chiamata con $name';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name sta facendo un annuncio';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant: $message';
  }

  @override
  String get intercomEndCall => 'Termina chiamata';

  @override
  String get intercomVoiceCall => 'Chiamata vocale';

  @override
  String get intercomVideoCall => 'Videochiamata';

  @override
  String get intercomVoiceOnly => 'Solo voce';

  @override
  String get intercomVideoAnswer => 'Video';

  @override
  String get intercomSwitchCamera => 'Cambia fotocamera';

  @override
  String get intercomCameraButton => 'Fotocamera';

  @override
  String get intercomCameraOff => 'Fotocamera disattivata';

  @override
  String get intercomYourCameraOff => 'La tua fotocamera è disattivata';

  @override
  String get intercomVideoReconnecting => 'Riconnessione del video…';

  @override
  String get intercomCameraOffNotice =>
      'La fotocamera è disattivata. Questo kiosk può mostrare il video ma non inviarlo.';

  @override
  String get intercomCallFailed => 'Impossibile chiamare';

  @override
  String get intercomKeyFailed => 'Impossibile cambiare la chiave';

  @override
  String get intercomBroadcastFailed => 'Impossibile parlare a tutti';

  @override
  String get intercomDeviceNoAnswer => 'Il dispositivo non ha risposto.';

  @override
  String get intercomUnknownKiosk => 'kiosk sconosciuto';

  @override
  String get intercomNothingRinging => 'niente sta squillando';

  @override
  String get intercomNoCall => 'nessuna chiamata';

  @override
  String get intercomDisabled => 'l\'interfono è disattivato';

  @override
  String get intercomNeedsRemote => 'richiede l\'amministrazione remota';

  @override
  String get intercomNeedsDiscovery =>
      'l\'interfono richiede l\'amministrazione remota e Trova altri kiosk';

  @override
  String get intercomAlreadyCalling => 'già in una chiamata';

  @override
  String get intercomNoReadyError => 'nessun kiosk è pronto';

  @override
  String get intercomKeyLength => 'una chiave deve avere almeno 16 caratteri';

  @override
  String get intercomMicHeld => 'la pagina sta usando il microfono';

  @override
  String get intercomMicPermission => 'accesso al microfono non concesso';

  @override
  String get intercomCallerNoAnswer => 'il chiamante non ha risposto';

  @override
  String get intercomMissedcall => 'Chiamata persa';

  @override
  String get intercomListening => 'In ascolto';

  @override
  String get intercomAnnouncementsoff => 'Annunci disattivati';

  @override
  String get intercomEncryptionMismatch => 'Crittografia non corrispondente';

  @override
  String get intercomEncryptionMismatchHelp =>
      'Crittografia non corrispondente. Attiva Crittografa le comunicazioni su tutti i kiosk della chiamata.';

  @override
  String get kioskBackClose => 'Premi di nuovo Indietro per chiudere l\'app';

  @override
  String get kioskBackAgain => 'Premi di nuovo Indietro per tornare indietro';

  @override
  String get kioskHoldOn => 'Modalità pausa attivata';

  @override
  String get kioskHoldOff => 'Modalità pausa disattivata';

  @override
  String get kioskHoldNotice =>
      'La vista corrente resta visualizzata finché non disattivi la modalità.';

  @override
  String get kioskDownloadComplete => 'Download completato';

  @override
  String get kioskDownloadFailed => 'Download non riuscito';

  @override
  String get kioskDownload => 'Download';

  @override
  String get kioskDownloading => 'Download in corso';

  @override
  String get kioskOpen => 'Apri';

  @override
  String get kioskTip => 'Suggerimento';

  @override
  String get kioskMenuHint => 'Scorri dal bordo sinistro per aprire il menu.';

  @override
  String get kioskUnknownLink => 'Link del kiosk sconosciuto';

  @override
  String get kioskOpenAppFailed => 'Impossibile aprire l\'app';

  @override
  String get kioskWebViewMissing => 'Android System WebView non è installato';

  @override
  String get kioskWebViewMissingHelp =>
      'Questo dispositivo non ha un fornitore WebView, quindi Home Assistant non può essere mostrato. Installa Android System WebView o Chrome, poi riavvia Kiosk Satellite.';

  @override
  String get kioskDuraSpeedBlocking => 'DuraSpeed sta bloccando la plancia';

  @override
  String get kioskDuraSpeedBlockingHelp =>
      'Il DuraSpeed di questo tablet impedisce l\'avvio del motore di rendering della plancia e alcuni tablet non offrono una pagina di impostazioni per gestirlo. Disattivalo una volta tramite adb, poi riavvia Kiosk Satellite:';

  @override
  String get kioskPinTitle => 'PIN del kiosk';

  @override
  String get kioskPinHint => 'PIN';

  @override
  String get kioskWrongPin => 'PIN errato';

  @override
  String get kioskUnlock => 'Sblocca';

  @override
  String get lockdownScreenLocked => 'Lo schermo è bloccato';

  @override
  String get logsWebConsole => 'Console web';

  @override
  String get logsDock => 'Aggancia sopra la pagina attiva';

  @override
  String get logsNoOutput => 'Ancora nessun output nella console';

  @override
  String get logsShareSubject => 'Registro della console di Kiosk Satellite';

  @override
  String get logsInput => 'Esegui JavaScript nella pagina';

  @override
  String get logsInputHistory =>
      'Esegui JavaScript nella pagina (Invio per eseguire, Su/Giù per la cronologia)';

  @override
  String get logsRun => 'Esegui';

  @override
  String get logsEvaluationFailed => 'esecuzione non riuscita';

  @override
  String get logsDeviceUnreachable => 'dispositivo non raggiungibile';

  @override
  String logsEntries(String count) {
    return '$count voci';
  }

  @override
  String get logsCopyLog => 'Copia registro';

  @override
  String get logsShareLog => 'Condividi registro';

  @override
  String get logsCopied => 'Copiato';

  @override
  String get logsCopyFailed => 'Impossibile copiare';

  @override
  String get logsOnClipboard => 'Il registro è stato copiato negli appunti.';

  @override
  String get logsConsoleOnClipboard =>
      'Il registro della console è stato copiato negli appunti.';

  @override
  String get logsSystemLog =>
      'Registro di sistema Android per questa app (qui compaiono gli arresti anomali)';

  @override
  String get logsErrors => 'Errori e arresti anomali';

  @override
  String get logsWarnings => 'Avvisi';

  @override
  String get logsInfo => 'Info e debug';

  @override
  String get logsNoMatches =>
      'Nessuna riga corrispondente. Abilita altri tipi qui sopra per vedere il registro completo.';

  @override
  String get logsUnavailable => 'logcat non disponibile';

  @override
  String logsReadFailed(String error) {
    return 'Impossibile leggere logcat: $error';
  }

  @override
  String get logsUnknown => 'sconosciuto';

  @override
  String get libraryTitle => 'Libreria musicale';

  @override
  String get librarySource => 'Sorgente';

  @override
  String get librarySourceMa => 'Music Assistant';

  @override
  String get librarySourceHa => 'Home Assistant';

  @override
  String get librarySourceSonos => 'Sonos';

  @override
  String get librarySourceMaHint => 'Libreria, ricerca e radio';

  @override
  String get librarySourceHaHint => 'Contenuti di ogni altoparlante';

  @override
  String get librarySourceSonosHint => 'Preferiti e playlist';

  @override
  String get libraryDiscover => 'Scopri';

  @override
  String get librarySearch => 'Cerca';

  @override
  String get libraryBrowse => 'Sfoglia';

  @override
  String get libraryLibrary => 'Libreria';

  @override
  String get libraryArtists => 'Artisti';

  @override
  String get libraryAlbums => 'Album';

  @override
  String get libraryTracks => 'Brani';

  @override
  String get libraryGenres => 'Generi';

  @override
  String get libraryPlaylists => 'Playlist';

  @override
  String get libraryRadio => 'Radio';

  @override
  String get libraryPodcasts => 'Podcast';

  @override
  String get libraryAudiobooks => 'Audiolibri';

  @override
  String get libraryFavorites => 'Preferiti';

  @override
  String get librarySonosPlaylists => 'Playlist Sonos';

  @override
  String get libraryRecentlyPlayed => 'Ascoltati di recente';

  @override
  String get libraryRecentlyAdded => 'Aggiunti di recente';

  @override
  String get librarySort => 'Ordina';

  @override
  String get librarySortAToZ => 'Dalla A alla Z';

  @override
  String get librarySortZToA => 'Dalla Z alla A';

  @override
  String get librarySortMostPlayed => 'Più ascoltati';

  @override
  String get libraryAlbumArtistsOnly => 'Solo artisti degli album';

  @override
  String get libraryKindGenre => 'Genere';

  @override
  String get libraryBrowseByGenre => 'Sfoglia per genere';

  @override
  String get settingLibraryTextScaleDescription =>
      'Dimensione di titoli, nomi ed etichette nella libreria.';

  @override
  String get settingLibrarySquareArtworkTitle => 'Immagini quadrate';

  @override
  String get settingLibrarySquareArtworkDescription =>
      'Mostra gli artisti in riquadri quadrati, come album e playlist.';

  @override
  String get settingLibraryGridDensityTitle => 'Densità della griglia';

  @override
  String get settingLibraryGridDensityDescription =>
      'Dimensione dei riquadri nella libreria. Compatta ne mostra di più per riga.';

  @override
  String get settingLibrarySourcePickerTitle =>
      'Mostra la selezione della sorgente';

  @override
  String get settingLibrarySourcePickerDescription =>
      'Mostra il selettore della sorgente nella libreria. Disattivalo per mantenere la libreria sulla sorgente impostata sopra.';

  @override
  String get settingLibrarySpeakerPillDescription =>
      'Mostra il selettore degli altoparlanti in cima alla libreria.';

  @override
  String get libraryDensityComfortable => 'Ampia';

  @override
  String get libraryDensityStandard => 'Standard';

  @override
  String get libraryDensityCompact => 'Compatta';

  @override
  String get libraryMoreResults => 'Altri risultati';

  @override
  String get libraryTopTracks => 'Brani più ascoltati';

  @override
  String get libraryKindArtist => 'Artista';

  @override
  String get libraryKindAlbum => 'Album';

  @override
  String get libraryKindTrack => 'Brano';

  @override
  String get libraryKindPlaylist => 'Playlist';

  @override
  String get libraryKindRadio => 'Radio';

  @override
  String get libraryKindPodcast => 'Podcast';

  @override
  String get libraryKindEpisode => 'Episodio';

  @override
  String get libraryKindAudiobook => 'Audiolibro';

  @override
  String get libraryOneTrack => '1 brano';

  @override
  String libraryTrackCount(String count) {
    return '$count brani';
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
  String get librarySearchHint => 'Artisti, album, brani';

  @override
  String get librarySearchClear => 'Cancella la ricerca';

  @override
  String get librarySearchAll => 'Tutti';

  @override
  String get librarySearchPrompt => 'Cerca artisti, album, brani e altro.';

  @override
  String get libraryEmpty => 'Qui non c\'è ancora niente.';

  @override
  String get libraryLoadFailed => 'Impossibile caricare questo contenuto.';

  @override
  String get libraryNoSource =>
      'Configura Music Assistant, Home Assistant o un altoparlante Sonos per sfogliare la musica.';

  @override
  String get libraryHaPickSpeaker =>
      'Scegli un altoparlante per vedere i contenuti che può riprodurre.';

  @override
  String get libraryChooseSpeaker => 'Scegli un altoparlante';

  @override
  String get libraryPickSpeakerHint =>
      'Scegli l\'altoparlante su cui riprodurre.';

  @override
  String get libraryPlay => 'Riproduci';

  @override
  String get libraryOpenNowPlaying => 'Apri In riproduzione';

  @override
  String get libraryNothingPlaying => 'Nessuna riproduzione in corso';

  @override
  String get libraryMore => 'Altre opzioni';

  @override
  String get libraryPlayNow => 'Riproduci ora';

  @override
  String get libraryPlayNext => 'Riproduci dopo';

  @override
  String get libraryAddToQueue => 'Aggiungi alla coda';

  @override
  String get libraryStartRadio => 'Avvia radio';

  @override
  String get libraryGoToArtist => 'Vai all\'artista';

  @override
  String get libraryAddFavorite => 'Aggiungi ai preferiti';

  @override
  String get libraryRemoveFavorite => 'Rimuovi dai preferiti';

  @override
  String get libraryAddedFavorite => 'Aggiunto ai preferiti';

  @override
  String get libraryRemovedFavorite => 'Rimosso dai preferiti';

  @override
  String get libraryFavoriteFailed => 'Impossibile modificare i preferiti';

  @override
  String get libraryPlaysNext => 'Verrà riprodotto subito dopo';

  @override
  String get libraryAddedToQueue => 'Aggiunto alla coda';

  @override
  String get libraryView => 'Mostra';

  @override
  String get libraryPlayFailed => 'Impossibile riprodurre questo contenuto';

  @override
  String get librarySpeakers => 'Altoparlanti';

  @override
  String get libraryPlayingOn => 'In riproduzione su';

  @override
  String get libraryOtherSpeakers => 'Altri altoparlanti';

  @override
  String get libraryNoOtherSpeakers => 'Nessun altro altoparlante.';

  @override
  String get libraryThisDevice => 'Questo dispositivo';

  @override
  String get libraryUnavailable => 'Non disponibile';

  @override
  String get libraryGroup => 'Raggruppa';

  @override
  String get libraryGroupAll => 'Gruppo';

  @override
  String libraryGroupWith(String speaker) {
    return 'Raggruppa con $speaker';
  }

  @override
  String get libraryGroupHint =>
      'Gli altoparlanti raggruppati riproducono la stessa musica in sincronia.';

  @override
  String libraryGroupName(String speaker, String count) {
    return '$speaker + $count';
  }

  @override
  String get settingKioskAllowMusicLibraryDescription =>
      'Sfoglia la musica e la riproduce su un altoparlante.';

  @override
  String get libraryPageHint =>
      'Sfoglia la musica e riproducila su un altoparlante';

  @override
  String get settingLibrarySourceDescription =>
      'Da dove la libreria elenca la musica. Automatico parte dalla sorgente dell\'altoparlante seguito da In riproduzione.';

  @override
  String get settingLibraryNowPlayingButtonTitle =>
      'Mostra nella schermata In riproduzione';

  @override
  String get settingLibraryNowPlayingButtonDescription =>
      'Aggiunge un pulsante Libreria musicale accanto al pulsante di chiusura.';

  @override
  String get libraryQueueTitle => 'Coda';

  @override
  String get libraryCloseQueue => 'Chiudi la coda';

  @override
  String get libraryClear => 'Svuota';

  @override
  String get libraryClearQueueTitle => 'Svuotare la coda?';

  @override
  String get libraryClearQueueMessage =>
      'La musica si interrompe e tutti i brani vengono rimossi dalla coda.';

  @override
  String get libraryRemoveFromQueue => 'Rimuovi dalla coda';

  @override
  String get libraryReorder => 'Trascina per riordinare';

  @override
  String get libraryQueueFailed => 'Impossibile modificare la coda';

  @override
  String get libraryVoiceSection => 'Controllo vocale';

  @override
  String get libraryVoiceManage => 'Gestisci la musica con Voice Satellite';

  @override
  String get libraryVoiceHint =>
      'Richiede il blueprint musicale di Kiosk Satellite e un agente di conversazione LLM in Home Assistant.';

  @override
  String get musicPickerTitle => 'Scegli la musica';

  @override
  String get musicPickerSearchHint => 'Cerca musica';

  @override
  String get musicPickerMusicFrom => 'Musica da';

  @override
  String get musicPickerPlaysOn => 'Riproduzione su';

  @override
  String musicPickerSourceLabel(String name) {
    return 'Sorgente: $name';
  }

  @override
  String musicPickerSpeakerLabel(String name) {
    return 'Riproduzione su: $name';
  }

  @override
  String get musicPickerRandom => 'Casuale';

  @override
  String get musicPickerRandomHint => 'Una scelta nuova a ogni riproduzione';

  @override
  String get musicPickerAnyTrack => 'Qualsiasi brano';

  @override
  String get musicPickerAnyFavorite => 'Qualsiasi preferito';

  @override
  String get musicPickerAnyPlaylist => 'Qualsiasi playlist';

  @override
  String get musicPickerAnyAlbum => 'Qualsiasi album';

  @override
  String get musicPickerAnyStation => 'Qualsiasi stazione radio';

  @override
  String get musicPickerRandomEach => 'Cambia ogni volta';

  @override
  String get musicPickerWholeAlbum => 'Album intero';

  @override
  String get musicPickerWholePlaylist => 'Playlist intera';

  @override
  String musicPickerWholeArtist(String name) {
    return 'Tutto di $name';
  }

  @override
  String get musicPickerWholeFolder => 'Cartella intera';

  @override
  String get musicPickerAllTracks => 'Tutti i brani';

  @override
  String get musicPickerShuffle => 'Riproduzione casuale';

  @override
  String get musicPickerPreview => 'Ascolta';

  @override
  String get musicPickerStopPreview => 'Interrompi l\'ascolto';

  @override
  String get musicPickerPreviewFailed => 'Impossibile riprodurre la musica';

  @override
  String get musicPickerNothing => 'Nessuna scelta';

  @override
  String get musicPickerNothingHint =>
      'Scegli un brano, un album, una playlist, un artista o una stazione';

  @override
  String get musicPickerFollowsNote =>
      'In riproduzione passa a questo altoparlante mentre suona la musica.';

  @override
  String get musicPickerSonosNote =>
      'La musica Sonos viene riprodotta solo su altoparlanti Sonos.';

  @override
  String get musicPickerNoSpeakers => 'Nessun altoparlante su cui riprodurre';

  @override
  String musicPickerOpen(String title) {
    return 'Apri $title';
  }

  @override
  String get musicPickerKindFolder => 'Cartella';

  @override
  String get offlineDashboard => 'Plancia non disponibile';

  @override
  String get offlineNetwork => 'Nessuna connessione di rete';

  @override
  String get offlinePageHelp => 'Impossibile caricare la pagina.';

  @override
  String get offlineNetworkHelp =>
      'La plancia tornerà disponibile non appena la rete sarà di nuovo attiva.';

  @override
  String get offlineLost => 'Connessione di rete persa';

  @override
  String get offlineRestored => 'Connessione di rete ripristinata';

  @override
  String get mediaPlay => 'Riproduci';

  @override
  String get mediaPause => 'Pausa';

  @override
  String get mediaPreviousTrack => 'Brano precedente';

  @override
  String get mediaNextTrack => 'Brano successivo';

  @override
  String get mediaPlaying => 'In riproduzione';

  @override
  String get mediaPaused => 'In pausa';

  @override
  String get mediaIdle => 'Inattivo';

  @override
  String get mediaStatusUnavailable => 'Stato non disponibile';

  @override
  String get mediaUnknownTrack => 'Brano sconosciuto';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => 'Mostra il volume';

  @override
  String get mediaHideVolume => 'Nascondi il volume';

  @override
  String get mediaMute => 'Disattiva l\'audio';

  @override
  String get mediaUnmute => 'Riattiva l\'audio';

  @override
  String get mediaFavoriteAdd => 'Aggiungi ai preferiti';

  @override
  String get mediaFavoriteRemove => 'Rimuovi dai preferiti';

  @override
  String get mediaShuffleOn => 'Attiva la riproduzione casuale';

  @override
  String get mediaShuffleOff => 'Disattiva la riproduzione casuale';

  @override
  String get mediaRepeatAll => 'Ripeti tutto';

  @override
  String get mediaRepeatOne => 'Ripeti un brano';

  @override
  String get mediaRepeatOff => 'Disattiva la ripetizione';

  @override
  String get mediaShowLyrics => 'Mostra i testi';

  @override
  String get mediaHideLyrics => 'Nascondi i testi';

  @override
  String get mediaShowQueue => 'Mostra la coda';

  @override
  String get mediaHideQueue => 'Nascondi la coda';

  @override
  String get mediaVolume => 'Volume';

  @override
  String get mediaPlaybackPosition => 'Posizione di riproduzione';

  @override
  String get mediaShowNowPlaying => 'Mostra In riproduzione';

  @override
  String get mediaShowFloatingPlayer => 'Mostra il lettore mobile';

  @override
  String get mediaOpenMusicAssistant => 'Apri Music Assistant';

  @override
  String get mediaCannotControl => 'comando non supportato o non inviato';

  @override
  String get mediaAudioHiRes => 'Hi-Res';

  @override
  String get mediaAudioCdQuality => 'Qualità CD';

  @override
  String get mediaAudioLossy => 'Con perdita';

  @override
  String mediaAudioBitDepth(String bits) {
    return '$bits bit';
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
  String get mediaNothingQueued => 'Niente in coda';

  @override
  String get mediaChapters => 'Capitoli';

  @override
  String get mediaNowPlaying => 'In riproduzione';

  @override
  String get mediaUpNext => 'A seguire';

  @override
  String mediaUnnamedChapter(String number) {
    return 'Capitolo $number';
  }

  @override
  String get mediaGroupLead => 'Guida il gruppo';

  @override
  String get mediaGroupReadFailed => 'Impossibile leggere il gruppo.';

  @override
  String get mediaGroupEmpty => 'Nessun altro lettore con cui raggruppare.';

  @override
  String get mediaSpeakerSelection => 'Selezione degli altoparlanti';

  @override
  String pluginCloseWindow(String name) {
    return 'Chiudi $name';
  }

  @override
  String get pluginScanTitle => 'Scansiona un codice';

  @override
  String get pluginScanHelp => 'Tieni il codice all\'interno della cornice.';

  @override
  String pluginScanSource(String name) {
    return 'Richiesto da $name';
  }

  @override
  String get pluginActions => 'Azioni';

  @override
  String get pluginKioskDrawer => 'Menu del kiosk';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      'Per assegnare un gesto, apri Gesti e scegli Esegui un\'azione di un plugin.';

  @override
  String get pluginShowInKioskDrawer => 'Mostra nel menu del kiosk';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      'Disponibile anche durante il blocco, se il menu del kiosk è consentito.';

  @override
  String get pluginExposeToHomeAssistant => 'Esponi a Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      'Aggiunge un pulsante al dispositivo ESPHome del kiosk. Richiede ESPHome e le entità native.';

  @override
  String pluginConfigureName(String name) {
    return 'Configura $name';
  }

  @override
  String get pluginThePluginDidNotAnswerInTime =>
      'Il plugin non ha risposto in tempo.';

  @override
  String get pluginNoChoicesYetRefreshToLookForThem =>
      'Ancora nessuna scelta. Aggiorna per cercarle.';

  @override
  String get pluginThisChoiceIsNoLongerListed =>
      'Questa scelta non è più nell\'elenco.';

  @override
  String get pluginDashboardLink => 'Link della plancia';

  @override
  String get pluginDashboardLinkHint =>
      'Usa questo link come azione al tocco di un pulsante della plancia.';

  @override
  String get pluginPlugin => 'Plugin';

  @override
  String get pluginEnablePlugins => 'Abilita i plugin';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      'I plugin aggiungono a Kiosk Satellite funzionalità extra sviluppate dalla community.';

  @override
  String get pluginInstalledPlugins => 'Plugin installati';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      'Nessun plugin installato. Aggiungi un repository per iniziare.';

  @override
  String get pluginDeveloperTools => 'Strumenti per sviluppatori';

  @override
  String get pluginCreateAPlugin => 'Crea un plugin';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      'Scopri come creare plugin con il modello Hello World e la documentazione.';

  @override
  String get pluginThisPluginIsNoLongerInstalled =>
      'Questo plugin non è più installato.';

  @override
  String get pluginEnablePluginsToRunThisPlugin =>
      'Attiva Abilita i plugin per eseguire questo plugin.';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      'Abilita questo plugin dalla sua riga nell\'elenco per eseguirlo.';

  @override
  String pluginUninstallName(String name) {
    return 'Disinstallare $name?';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return 'Disinstalla $name';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return 'Cerca aggiornamenti per $name';
  }

  @override
  String pluginAboutName(String name) {
    return 'Informazioni su $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings =>
      'Questa operazione rimuove il plugin e le sue impostazioni.';

  @override
  String get pluginUninstall => 'Disinstalla';

  @override
  String get pluginNoUpdatesAvailable => 'Nessun aggiornamento disponibile.';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      'Questo plugin è stato installato da un file ZIP e non ha un README del repository.';

  @override
  String get pluginImageUnavailable => 'Immagine non disponibile';

  @override
  String get pluginCouldNotOpenThisLink => 'Impossibile aprire questo link.';

  @override
  String pluginEnableName(String name) {
    return 'Abilita $name';
  }

  @override
  String get pluginShowPassword => 'Mostra la password';

  @override
  String get pluginHidePassword => 'Nascondi la password';

  @override
  String get pluginUntitled => 'Senza nome';

  @override
  String get pluginSearchIcons => 'Cerca icone';

  @override
  String get pluginChooseIcon => 'Scegli un\'icona';

  @override
  String get pluginSearchCameraViews => 'Cerca viste telecamere';

  @override
  String get pluginChooseCameraView => 'Scegli una vista telecamere';

  @override
  String get pluginCameraViewGone =>
      'Questa vista telecamere non esiste più. Scegline un\'altra.';

  @override
  String get pluginDragToReorder => 'Trascina per riordinare';

  @override
  String get pluginDuplicate => 'Duplica';

  @override
  String get pluginDone => 'Fine';

  @override
  String get pluginRequired => 'Obbligatorio';

  @override
  String get pluginAddPlugin => 'Aggiungi plugin';

  @override
  String get pluginInstallFromAGithubRepository =>
      'Installa da un repository GitHub';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd =>
      'Prima di installarlo, assicurati di fidarti dell\'autore del plugin e del suo codice.';

  @override
  String get pluginPreview => 'Anteprima';

  @override
  String get pluginInstalledVersion => 'Versione installata';

  @override
  String get pluginAuthor => 'Autore';

  @override
  String get pluginLicense => 'Licenza';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      'I plugin eseguono codice all\'interno di Kiosk Satellite e possono accedere ai dati dell\'app e alle autorizzazioni Android concesse. Un plugin difettoso o dannoso può esporre informazioni private o impedire il funzionamento dell\'app. Installa solo plugin di autori di cui ti fidi.';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      'I nuovi plugin partono disabilitati. Gli aggiornamenti mantengono lo stato di abilitazione e riavviano automaticamente i plugin in esecuzione.';

  @override
  String get pluginTrustAndUpdate => 'Fidati e aggiorna';

  @override
  String get pluginTrustAndInstall => 'Fidati e installa';

  @override
  String get pluginInstallFromZip => 'Installa da ZIP';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild =>
      'Solo per sviluppatori: prova una build locale';

  @override
  String get pluginPluginZip => 'ZIP del plugin';

  @override
  String get pluginPluginZipMustBeAtMost4Mb =>
      'Lo ZIP del plugin non deve superare 4 MB';

  @override
  String get pluginCouldNotReadTheSelectedZip =>
      'Impossibile leggere lo ZIP selezionato';

  @override
  String get pluginBrowsePlugins => 'Sfoglia i plugin';

  @override
  String get pluginFindPluginsMadeByTheCommunity =>
      'Trova plugin creati dalla community';

  @override
  String get pluginSearchPlugins => 'Cerca plugin';

  @override
  String get pluginUpdate => 'Aggiorna';

  @override
  String get pluginInstalled => 'Installato';

  @override
  String pluginNeedsAppVersion(String version) {
    return 'Richiede Kiosk Satellite $version o successiva';
  }

  @override
  String get pluginStars => 'Stelle';

  @override
  String get pluginDownloads => 'Download';

  @override
  String get pluginActiveInstalls => 'Installazioni attive';

  @override
  String get pluginNoPluginsMatchYourSearch =>
      'Nessun plugin corrisponde alla ricerca.';

  @override
  String get pluginCommunityPluginsHasNoPluginsYet =>
      'Plugin della community non contiene ancora plugin.';

  @override
  String get pluginSubmitYourPlugin => 'Proponi il tuo plugin';

  @override
  String get pluginListYourPluginInCommunityPlugins =>
      'Pubblica il tuo plugin in Plugin della community.';

  @override
  String get pluginCouldNotReachCommunityPlugins =>
      'Impossibile raggiungere Plugin della community. Controlla la connessione a Internet.';

  @override
  String get pluginCouldNotLoadCommunityPlugins =>
      'Impossibile caricare Plugin della community. Riprova più tardi.';

  @override
  String get pluginTurnOn => 'Attiva';

  @override
  String get pluginTurnOnEnablePluginsToInstall =>
      'Attiva Abilita i plugin per installare questo plugin.';

  @override
  String get pluginPreviousPage => 'Pagina precedente';

  @override
  String get pluginNextPage => 'Pagina successiva';

  @override
  String pluginPageOfPages(String page, String pages) {
    return 'Pagina $page di $pages';
  }

  @override
  String get pluginSortBy => 'Ordina per';

  @override
  String get pluginSortMostStars => 'Più stelle';

  @override
  String get pluginSortRecentlyUpdated => 'Aggiornati di recente';

  @override
  String get pluginSortNewest => 'Più recenti';

  @override
  String get pluginSortName => 'Nome';

  @override
  String get pluginSortMostDownloads => 'Più scaricati';

  @override
  String get pluginPluginsPerPage => 'Plugin per pagina';

  @override
  String pluginCountPerPage(String count) {
    return '$count per pagina';
  }

  @override
  String pluginByAuthor(String author) {
    return 'di $author';
  }

  @override
  String get pluginListedChip => 'Presente in Plugin della community';

  @override
  String get pluginNotListedChip => 'Non presente in Plugin della community';

  @override
  String get pluginReleaseNotes => 'Note di rilascio';

  @override
  String get pluginCharts => 'Grafici';

  @override
  String get pluginReadings => 'Letture';

  @override
  String get pluginWaitingForSamples => 'In attesa di campioni';

  @override
  String get pluginLatest => 'Più recente';

  @override
  String get pluginSelected => 'Selezionato';

  @override
  String get pluginNoDataYet => 'Ancora nessun dato';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      'Tocca o trascina per esaminare i campioni. Tocca due volte per seguire il più recente.';

  @override
  String get pluginNoData => 'Nessun dato';

  @override
  String get pluginOn => 'Attivo';

  @override
  String get pluginEmpty => 'Vuoto';

  @override
  String get pluginChartKeyboardHelp =>
      'Usa i tasti freccia per esaminare i campioni e Fine per il più recente.';

  @override
  String get pluginErrorAssetPath => 'Percorso del file non valido';

  @override
  String get pluginErrorAssetMissing =>
      'Il file manca o si trova fuori dal suo pacchetto';

  @override
  String get pluginErrorAssetSymlink =>
      'La cartella dei file non può essere un collegamento simbolico';

  @override
  String get pluginErrorAssetSymlinks =>
      'Le cartelle dei file non possono essere collegamenti simbolici';

  @override
  String get pluginErrorAssetsIntegrity =>
      'I file installati non hanno superato il controllo di integrità';

  @override
  String get pluginErrorAssetIntegrity =>
      'Il file installato non ha superato il controllo di integrità';

  @override
  String get pluginErrorManifestMismatch =>
      'Il manifest del pacchetto non corrisponde a quello della versione verificata';

  @override
  String get pluginErrorStagingExists =>
      'La cartella temporanea di installazione esiste già';

  @override
  String get pluginErrorCreateDirectory =>
      'Impossibile creare la cartella del plugin';

  @override
  String get pluginErrorFileCount =>
      'Sono supportati al massimo 512 file per pacchetto';

  @override
  String get pluginErrorProtectFile =>
      'Impossibile proteggere il file del plugin';

  @override
  String get pluginErrorExpandedSize => 'Il plugin decompresso supera 4 MB';

  @override
  String get pluginErrorManifestSize => 'Il manifest supera 32 KB';

  @override
  String get pluginErrorRequiredFiles =>
      'Il pacchetto deve contenere kiosk-satellite-plugin.json, plugin.jar e LICENSE';

  @override
  String get pluginErrorNativeCapability =>
      'Le librerie native richiedono la capacità native';

  @override
  String get pluginErrorNativeElf => 'Libreria ELF nativa non valida';

  @override
  String get pluginErrorNativeAbi =>
      'L\'ABI della libreria nativa non corrisponde alla sua cartella';

  @override
  String get pluginErrorDexOnly => 'plugin.jar deve contenere solo file DEX';

  @override
  String get pluginErrorDexHeader => 'Intestazione DEX non valida';

  @override
  String get pluginErrorDexSize => 'Il DEX decompresso supera 4 MB';

  @override
  String get pluginErrorDexEmpty => 'File DEX vuoto';

  @override
  String get pluginErrorDexMissing => 'plugin.jar non contiene classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'Voce ZIP inattesa o duplicata: $name';
  }

  @override
  String get pluginErrorRepositoryMismatch =>
      'La versione pubblicata nel repository appartiene a un altro plugin.';

  @override
  String get pluginErrorRepositoryUrl =>
      'Inserisci l\'URL di un repository pubblico nel formato https://github.com/owner/repository';

  @override
  String get pluginErrorRepositoryPath =>
      'Usa l\'URL del repository senza il percorso di un file o di un ramo';

  @override
  String get pluginErrorDownloadOutsideGithub =>
      'Il download del plugin è stato reindirizzato fuori da GitHub';

  @override
  String get pluginErrorInvalidRedirect => 'Reindirizzamento GitHub non valido';

  @override
  String get pluginErrorRepositoryNotFound =>
      'Impossibile trovare il repository pubblico, la versione stabile, kiosk-satellite-plugin.json, README.md o il file della versione.';

  @override
  String get pluginErrorGithubLimited =>
      'GitHub ha rifiutato la richiesta o è stato raggiunto il suo limite di richieste. Riprova più tardi.';

  @override
  String get pluginErrorRepositorySize =>
      'Il file del repository supera il limite di dimensione';

  @override
  String get pluginErrorTooManyRedirects => 'Troppi reindirizzamenti GitHub';

  @override
  String get pluginErrorStableRelease =>
      'GitHub non ha restituito una versione stabile pubblicata';

  @override
  String get pluginErrorReleaseTag => 'Tag della versione non valido';

  @override
  String get pluginErrorManifestFile =>
      'Manifest kiosk-satellite-plugin.json non valido';

  @override
  String get pluginErrorIdVersion => 'ID o versione del plugin non validi';

  @override
  String get pluginErrorChecksumFilename =>
      'Checksum della versione o nome file del pacchetto non validi';

  @override
  String get pluginErrorGithubDigest =>
      'Il checksum della versione deve corrispondere all\'hash SHA-256 del file su GitHub';

  @override
  String get pluginErrorTrustAuthor =>
      'Conferma di fidarti dell\'autore del plugin';

  @override
  String get pluginErrorPreviewExpired =>
      'Questa anteprima è scaduta. Visualizza di nuovo l\'anteprima del repository prima di installare.';

  @override
  String get pluginErrorReviewedChecksum =>
      'L\'hash SHA-256 del pacchetto non corrisponde a quello della versione verificata';

  @override
  String get pluginErrorNotInstalled => 'Il plugin non è installato';

  @override
  String get pluginErrorUpdateZip =>
      'Questo plugin è stato installato da ZIP. Usa Installa da ZIP per aggiornarlo.';

  @override
  String get pluginErrorAndroidOnly =>
      'I plugin sono disponibili solo su Android.';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'Richiesta a GitHub non riuscita ($status)';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return 'La versione deve avere esattamente un file $name caricato';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return 'Il file $name della versione deve essere pubblicato da GitHub Actions. I file caricati manualmente non sono supportati.';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return 'Il file $name della versione supera il limite di dimensione o è vuoto';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return 'URL della versione non valida per $name';
  }

  @override
  String get pluginErrorNativeLibrary =>
      'Il plugin non ha una libreria nativa per l\'ABI di questo dispositivo';

  @override
  String get pluginErrorCallbackTimeout =>
      'La risposta del plugin ha impiegato troppo tempo. Riavvia il kiosk se il plugin ha lasciato attività in esecuzione.';

  @override
  String get pluginErrorEnableFirst => 'Abilita prima il plugin';

  @override
  String get pluginErrorSaveState => 'Impossibile salvare lo stato del plugin';

  @override
  String get pluginErrorPackageHash =>
      'Hash del pacchetto installato non valido';

  @override
  String get pluginErrorChecksum =>
      'L\'hash SHA-256 del pacchetto non corrisponde';

  @override
  String get pluginErrorDifferentRepository =>
      'Questo ID plugin appartiene a un altro repository. Disinstallalo prima di cambiare origine.';

  @override
  String get pluginErrorRestartReplace =>
      'Questo plugin non si è arrestato correttamente. Riavvia Kiosk Satellite prima di sostituirlo.';

  @override
  String get pluginErrorAlreadyInstalled => 'Questo pacchetto è già installato';

  @override
  String get pluginErrorLoadedIntegrity =>
      'Il pacchetto caricato in precedenza non ha superato il controllo di integrità. Riavvia Kiosk Satellite prima di reinstallarlo.';

  @override
  String get pluginErrorRemovePackage =>
      'Impossibile rimuovere il pacchetto inutilizzato';

  @override
  String get pluginErrorInstallPackage =>
      'Impossibile installare il pacchetto del plugin';

  @override
  String get pluginErrorUpdateCanceled =>
      'Aggiornamento annullato perché il plugin non si è arrestato correttamente. Riavvia Kiosk Satellite prima di riprovare.';

  @override
  String get pluginErrorVersionRetained =>
      'La versione precedente è stata mantenuta.';

  @override
  String get pluginErrorRetainedDisabled =>
      'La versione precedente è stata mantenuta ma è disabilitata. Riavvia Kiosk Satellite prima di abilitarla.';

  @override
  String get pluginErrorVersionRunning =>
      'La versione precedente è di nuovo in esecuzione.';

  @override
  String get pluginErrorEnablePlugins => 'Abilita prima i plugin';

  @override
  String get pluginErrorRestartEnable =>
      'Questo plugin non si è arrestato correttamente. Riavvia Kiosk Satellite prima di abilitarlo.';

  @override
  String get pluginErrorInstalledIntegrity =>
      'Il plugin installato non ha superato il controllo di integrità. Reinstallalo.';

  @override
  String get pluginErrorAndroidOld => 'La versione di Android è troppo vecchia';

  @override
  String get pluginErrorNeedsScreen => 'Questo plugin richiede uno schermo';

  @override
  String get pluginErrorNativeIntegrity =>
      'Le librerie native installate non hanno superato il controllo di integrità';

  @override
  String get pluginErrorNativeFileIntegrity =>
      'La libreria nativa installata non ha superato il controllo di integrità';

  @override
  String pluginErrorReadInstalled(String error) {
    return 'Impossibile leggere il plugin installato: $error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return 'Impossibile riavviare la versione precedente: $error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return 'Aggiornamento del plugin non riuscito: $error. $recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      'È richiesto Shizuku 13 o versione successiva. Tocca per le istruzioni di configurazione.';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      'Avvia Shizuku su questo dispositivo. Tocca per le istruzioni di configurazione.';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku concede a Kiosk Satellite l\'accesso shell o root. I plugin installati vengono eseguiti all\'interno di KS, quindi concedi l\'accesso solo se ti fidi di loro.';

  @override
  String get pluginSetUp => 'Configura';

  @override
  String get pluginGrantAccess => 'Concedi l\'accesso';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      'Approva la richiesta di autorizzazione sul kiosk.';

  @override
  String get pluginErrorInvalidId => 'ID plugin non valido';

  @override
  String get pluginErrorInvalidVersion => 'Versione non valida';

  @override
  String get pluginErrorEntryClass => 'Classe di ingresso non valida';

  @override
  String get pluginErrorManifestSchema => 'Schema del manifest non supportato';

  @override
  String get pluginErrorSdkVersion =>
      'Questo plugin richiede un\'altra versione dell\'SDK';

  @override
  String get pluginErrorMinimumSdk =>
      'L\'SDK minimo di Android deve essere almeno 24';

  @override
  String get pluginErrorCapability => 'Capacità del plugin non supportata';

  @override
  String get pluginErrorTooManySettings => 'Troppe impostazioni o comandi';

  @override
  String get pluginErrorSettingKey =>
      'Chiave di impostazione non valida o duplicata';

  @override
  String get pluginErrorGroupsArray =>
      'I gruppi di visualizzazione devono essere un array';

  @override
  String get pluginErrorTooManyGroups => 'Troppi gruppi di visualizzazione';

  @override
  String get pluginErrorUniqueGroups =>
      'I gruppi di visualizzazione devono indicare gruppi di impostazioni univoci';

  @override
  String get pluginErrorGroupReferences => 'Troppi riferimenti nel gruppo';

  @override
  String get pluginErrorDuplicateReference =>
      'Riferimento al gruppo non valido o duplicato';

  @override
  String get pluginErrorCommandId => 'ID comando non valido o duplicato';

  @override
  String get pluginErrorUnknownSetting => 'Impostazione del plugin sconosciuta';

  @override
  String get pluginErrorTextLength =>
      'Le impostazioni di testo possono avere al massimo 512 caratteri';

  @override
  String get pluginErrorEntityId =>
      'Era previsto un ID entità di Home Assistant';

  @override
  String get pluginErrorBoolean => 'Era prevista un\'impostazione booleana';

  @override
  String get pluginErrorColor => 'Era previsto un colore RGB esadecimale';

  @override
  String get pluginErrorNumber => 'Era prevista un\'impostazione numerica';

  @override
  String get pluginErrorRange =>
      'L\'impostazione numerica è fuori dal suo intervallo';

  @override
  String get pluginErrorStep =>
      'L\'impostazione numerica non corrisponde al suo incremento';

  @override
  String get pluginErrorSelection => 'Impostazione di selezione non valida';

  @override
  String get pluginErrorSelectionOption => 'Opzione di selezione sconosciuta';

  @override
  String get pluginErrorSettingType => 'Tipo di impostazione non supportato';

  @override
  String get pluginErrorInvalidManifest => 'Manifest del plugin non valido';

  @override
  String pluginErrorAndroidApi(String version) {
    return 'Il plugin richiede l\'API Android $version';
  }

  @override
  String pluginErrorAppVersion(String required, String current) {
    return 'Il plugin richiede Kiosk Satellite $required o versione successiva. Questo kiosk usa la $current.';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return 'Campo $field non valido';
  }

  @override
  String get pluginErrorTooManyTriggers => 'Troppi attivatori';

  @override
  String get pluginErrorTriggerId => 'ID attivatore non valido o duplicato';

  @override
  String get pluginErrorListSetting => 'Impostazione di tipo elenco non valida';

  @override
  String get pluginErrorSettingCondition =>
      'Condizione dell\'impostazione non valida';

  @override
  String get pluginErrorIcon => 'Era previsto il nome di un\'icona MDI';

  @override
  String get pluginErrorDashboard => 'Era previsto il percorso di una plancia';

  @override
  String get pluginErrorCameraView =>
      'Era previsto l\'ID di una vista telecamere';

  @override
  String get pluginErrorListValue =>
      'Era prevista un\'impostazione di tipo elenco';

  @override
  String get pluginErrorListCount =>
      'L\'elenco ha troppi o troppo pochi elementi';

  @override
  String get pluginErrorRequiredField => 'Compila tutti i campi obbligatori';

  @override
  String get pluginErrorListSize =>
      'Le impostazioni di tipo elenco non possono superare 32 KB';

  @override
  String get remoteDisableTitle => 'Disattivare l\'amministrazione remota?';

  @override
  String get remoteDisableHelp =>
      'ATTENZIONE: non potrai più accedere a questa pagina. Per riattivarla, usa il dispositivo o l\'interruttore Amministrazione remota in Home Assistant.';

  @override
  String get remoteDisableConfirm => 'Disattiva';

  @override
  String get remoteCopyHelp => 'Seleziona la chiave e copiala manualmente.';

  @override
  String get remoteSaveSettingFailed =>
      'Impossibile salvare questa impostazione. Riprova.';

  @override
  String get remoteReconnecting => 'Riconnessione…';

  @override
  String remoteConnectionLost(String name) {
    return 'La connessione con $name si è interrotta. Questa pagina riprenderà da sola quando la connessione sarà ripristinata.';
  }

  @override
  String get remoteConnectionLostUnnamed =>
      'La connessione con il kiosk si è interrotta. Questa pagina riprenderà da sola quando la connessione sarà ripristinata.';

  @override
  String get remoteReloadPage => 'Ricarica la pagina';

  @override
  String get remoteUpdated => 'Kiosk Satellite è stato aggiornato';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return 'Il dispositivo ora usa la versione $version$build. Questa pagina appartiene alla versione precedente e verrà ricaricata tra $seconds s.';
  }

  @override
  String remoteBuild(String build) {
    return ' (build $build)';
  }

  @override
  String get remoteReloadNow => 'Ricarica ora';

  @override
  String get remoteLogin => 'Accedi';

  @override
  String get remoteInvalidPassword => 'Password errata';

  @override
  String get remoteLoginThrottled =>
      'Troppi tentativi. Attendi 5 minuti e riprova.';

  @override
  String get deviceScreenOffPermission =>
      'Per spegnere lo schermo serve un\'autorizzazione da concedere una sola volta. Il tablet sta mostrando la schermata di autorizzazione \"amministratore del dispositivo\". Approvala lì, poi riprova.';

  @override
  String get deviceAdminInactive =>
      'L\'autorizzazione di amministratore del dispositivo non è attiva.';

  @override
  String get deviceRestartOverlay =>
      'Per riavviare serve l\'autorizzazione \"Mostra sopra altre app\", altrimenti l\'app non può riaprirsi da sola. La schermata di autorizzazione si sta aprendo sul dispositivo: concedila lì e riprova.';

  @override
  String get deviceRebootPermission =>
      'Per riavviare il dispositivo, Kiosk Satellite deve essere configurato come proprietario del dispositivo oppure serve una connessione Shizuku autorizzata.';

  @override
  String get deviceRestartAndroidOnly =>
      'Il riavvio è disponibile solo su Android.';

  @override
  String get deviceRestartShizukuRefused => 'Shizuku ha rifiutato il riavvio';

  @override
  String deviceRestartFailed(String error) {
    return 'Riavvio non riuscito: $error';
  }

  @override
  String get overviewAttention => 'Richiede attenzione';

  @override
  String get overviewUpdate => 'Aggiorna';

  @override
  String overviewInvitation(String name) {
    return '$name vuole guidare questo kiosk';
  }

  @override
  String get overviewOutdatedOne => '1 follower usa un\'altra versione';

  @override
  String overviewOutdatedMany(String count) {
    return '$count follower usano un\'altra versione';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names. La sincronizzazione attende la versione $version.';
  }

  @override
  String get overviewThisRelease => 'questa versione';

  @override
  String get overviewUpdateAvailable => 'Aggiornamento disponibile';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version è pronto per l\'installazione. L\'installazione va confermata sullo schermo del tablet.';
  }

  @override
  String overviewInstallSilentHelp(String version) {
    return 'Kiosk Satellite $version è pronto per l\'installazione. Verrà installato senza richiedere conferma sul dispositivo.';
  }

  @override
  String overviewInstallHeadlessHelp(String version) {
    return 'Kiosk Satellite $version è pronto per l\'installazione. Questo dispositivo non ha uno schermo su cui confermarla, quindi rendi Kiosk Satellite proprietario del dispositivo, usa Shizuku o installalo tramite adb.';
  }

  @override
  String get overviewHaSetup => 'Home Assistant non configurato';

  @override
  String get overviewHaSetupHelp =>
      'Connetti il kiosk a Home Assistant per caricare una plancia.';

  @override
  String get overviewSetUp => 'Configura';

  @override
  String get overviewHaNotValidated => 'Home Assistant non verificato';

  @override
  String get overviewHaNotValidatedHelp =>
      'L\'URL e il token non hanno ancora superato un controllo della connessione dall\'avvio. Il kiosk riprova ogni 30 secondi.';

  @override
  String get overviewOpenSetup => 'Apri la configurazione';

  @override
  String get overviewWakeStopped =>
      'Rilevamento della parola di attivazione interrotto';

  @override
  String get overviewWakeReleased =>
      'Il motore di rilevamento è stato rilasciato.';

  @override
  String get overviewOpenVoice => 'Apri Voice Satellite';

  @override
  String get overviewOpenService => 'Apri il servizio';

  @override
  String overviewPermissionMissing(String permission) {
    return 'Autorizzazione mancante: $permission';
  }

  @override
  String get overviewSystemUpdate => 'Aggiornamento di sistema disponibile';

  @override
  String overviewPluginUpdate(String name) {
    return 'Aggiornamento di $name disponibile';
  }

  @override
  String overviewPluginUpdateHelp(String version) {
    return 'La versione $version è pronta per essere verificata e installata.';
  }

  @override
  String overviewSystemImageUpdateHelp(String version) {
    return 'La versione $version dell\'immagine di sistema è pronta per l\'installazione. Il dispositivo si riavvia due volte per installarla.';
  }

  @override
  String get overviewQuick => 'Controlli rapidi';

  @override
  String get overviewReload => 'Ricarica la pagina';

  @override
  String get overviewScreenOn => 'Accendi schermo';

  @override
  String get overviewScreenOff => 'Spegni schermo';

  @override
  String get overviewSaverStart => 'Avvia salvaschermo';

  @override
  String get overviewSaverStop => 'Chiudi salvaschermo';

  @override
  String get overviewCameraShow => 'Mostra vista telecamere';

  @override
  String get overviewCameraHide => 'Chiudi vista telecamere';

  @override
  String get overviewSaverPostpone => 'Posticipa salvaschermo';

  @override
  String get overviewDnd => 'Non disturbare';

  @override
  String get overviewDndOn => 'Non disturbare attivo';

  @override
  String get overviewSnapshot => 'Scatta istantanea';

  @override
  String get overviewCheckUpdates => 'Cerca aggiornamenti';

  @override
  String get overviewRestartApp => 'Riavvia app';

  @override
  String get overviewRestartDevice => 'Riavvia dispositivo';

  @override
  String get overviewExit => 'Esci dall\'app';

  @override
  String get overviewBrightness => 'Luminosità';

  @override
  String get overviewVolume => 'Volume principale';

  @override
  String get overviewBrightnessGrant =>
      'La luminosità usa una soluzione di riserva a livello di app. Concedi \"Modifica impostazioni di sistema\" affinché il cursore controlli la luminosità reale dello schermo.';

  @override
  String get overviewRestartQuestion =>
      'Riavviare questo dispositivo? Kiosk Satellite si riapre all\'avvio.';

  @override
  String get overviewRestart => 'Riavvia';

  @override
  String get overviewNoSnapshot => 'Nessuna istantanea ricevuta.';

  @override
  String get overviewSnapshotTitle => 'Istantanea della fotocamera';

  @override
  String get overviewUpdateCheckFailed =>
      'Ricerca aggiornamenti non riuscita. Il dispositivo riesce a raggiungere GitHub?';

  @override
  String get overviewLatest => 'Hai la versione più recente.';

  @override
  String overviewVersionAvailable(String version) {
    return 'È disponibile la versione $version';
  }

  @override
  String get overviewInstallAttention => 'Installala da Richiede attenzione.';

  @override
  String get overviewNoViewsWithCameras =>
      'Nessuna vista telecamere contiene ancora telecamere. Aggiungi prima le telecamere a una vista in Telecamere.';

  @override
  String get overviewShowViewFailed => 'Impossibile mostrare la vista';

  @override
  String get overviewAppVersion => 'Versione dell\'app';

  @override
  String get overviewNotSetup => 'Non configurato';

  @override
  String get overviewNotValidated => 'Non verificato';

  @override
  String get overviewCheckingFilter => 'Controllo del filtro...';

  @override
  String get overviewValidated => 'Verificato';

  @override
  String get overviewFilterUnavailable => 'Stato del filtro non disponibile';

  @override
  String get overviewUnfiltered => 'Aggiornamenti non filtrati';

  @override
  String get overviewWatchingOne => 'Monitora 1 entità';

  @override
  String overviewWatchingMany(String count) {
    return 'Monitora $count entità';
  }

  @override
  String overviewFilterDisabled(String count) {
    return 'Filtro disattivato, la vista usa $count entità';
  }

  @override
  String get overviewWakeOff =>
      'Rilevamento della parola di attivazione disattivato';

  @override
  String overviewListeningFor(String words) {
    return 'In ascolto di $words';
  }

  @override
  String get overviewListening => 'In ascolto';

  @override
  String get overviewNotListening => 'Non in ascolto';

  @override
  String get overviewEntitiesProxy => 'Entità e proxy BT';

  @override
  String get overviewEntitiesOnly => 'Solo entità';

  @override
  String get overviewProxyOnly => 'Solo proxy BT';

  @override
  String get overviewWaitingHA => 'In attesa di Home Assistant';

  @override
  String get overviewNotRunning => 'Non in esecuzione';

  @override
  String get overviewRunningOne => 'In esecuzione - 1 funzionalità';

  @override
  String overviewRunningMany(String count) {
    return 'In esecuzione - $count funzionalità';
  }

  @override
  String overviewDownloading(String version) {
    return 'Download in corso: $version';
  }

  @override
  String overviewNewVersion(String version) {
    return 'Nuova versione: $version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return 'Aggiornato: $version';
  }

  @override
  String get overviewCurrent => 'Aggiornato';

  @override
  String overviewPluginAttribution(String name) {
    return 'Plugin $name';
  }

  @override
  String get overviewMuted => 'silenziato';

  @override
  String get overviewBrowser => 'nel browser';

  @override
  String get overviewWakeWaiting =>
      'In attesa dell\'integrazione Voice Satellite. Il motore e le parole di attivazione vengono configurati dall\'integrazione quando questo dispositivo apre la sua plancia.';

  @override
  String get overviewWakeDisabled =>
      'Il rilevamento della parola di attivazione è disattivato. Attivalo per ereditare i modelli dall\'integrazione Voice Satellite.';

  @override
  String get overviewMicBlocked =>
      'Microfono bloccato. Android non lo chiederà più, quindi consentilo nelle impostazioni dell\'app, poi riprova.';

  @override
  String get overviewMicDeclined =>
      'Accesso al microfono negato. Serve per il rilevamento della parola di attivazione: riprova per ricevere di nuovo la richiesta.';

  @override
  String get overviewMicLost =>
      'Il microfono ha smesso di funzionare. Riprova o ricarica la pagina.';

  @override
  String get overviewModelsUnavailable =>
      'Impossibile scaricare i modelli da Home Assistant. Riprova quando sarà raggiungibile.';

  @override
  String get overviewCrashed =>
      'Il rilevatore continuava ad arrestarsi in modo anomalo su questo dispositivo, quindi è stato fermato. Voice Satellite è invece in ascolto nel browser. Riprova o riavvia l\'app.';

  @override
  String get overviewWakeFailed =>
      'Impossibile avviare il motore della parola di attivazione. Riprova o ricarica la pagina.';

  @override
  String overviewNativeUnavailable(String engine) {
    return 'Nessun motore nativo per $engine. Voice Satellite mantiene il rilevamento nel browser.';
  }

  @override
  String get overviewNativeListening => 'In ascolto con il motore nativo';

  @override
  String get overviewSuspended =>
      'Pronto (sospeso durante una sessione vocale)';

  @override
  String get overviewCpu => 'CPU';

  @override
  String get overviewMemory => 'RAM';

  @override
  String get overviewTemperature => 'Temp.';

  @override
  String overviewMemoryFree(String amount) {
    return '$amount GB liberi';
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
  String get overviewShowingCustomPages =>
      'Visualizzazione di pagine personalizzate';

  @override
  String get overviewHeadlessMode => 'Modalità senza schermo';

  @override
  String get overviewNoScreenshot => 'Nessuno screenshot';

  @override
  String get overviewStill => 'Fermo immagine';

  @override
  String get overviewLive => 'In diretta';

  @override
  String get overviewFullSize => 'Dimensione originale';

  @override
  String get overviewLiveInterval => 'In diretta, ogni 5 secondi';

  @override
  String overviewTaken(String age) {
    return 'Acquisito $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return 'Vista telecamere: $name';
  }

  @override
  String get overviewCameraView => 'Vista telecamere';

  @override
  String get overviewScreenOffState => 'Schermo spento';

  @override
  String get overviewGoView => 'Vai alla vista';

  @override
  String get screensaverNoPhotos =>
      'Nessuna foto selezionata. Scegline alcune in Impostazioni.';

  @override
  String get screensaverNoFolder =>
      'Nessuna cartella selezionata. Scegline una in Impostazioni.';

  @override
  String screensaverFolderEmpty(String folder) {
    return 'Nessuna foto o video in $folder';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return 'Impossibile leggere $folder. Hai concesso l\'autorizzazione per i contenuti multimediali?';
  }

  @override
  String get screensaverReadPhotosFailed => 'Impossibile leggere le foto.';

  @override
  String get screensaverImmichNotReady =>
      'Immich non è connesso. Verificalo in Impostazioni.';

  @override
  String get screensaverNoMediaMatch =>
      'Nessun contenuto multimediale corrisponde all\'origine e ai filtri.';

  @override
  String get screensaverNoMediaSource =>
      'Nessun contenuto multimediale nell\'origine selezionata.';

  @override
  String get screensaverImmichUnreachable =>
      'Impossibile raggiungere il server Immich.';

  @override
  String screensaverRetryNotice(String error) {
    return '$error Nuovo tentativo automatico in corso.';
  }

  @override
  String get screensaverVideosTooLarge =>
      'Tutti i video di questa playlist sono troppo grandi per essere riprodotti su questo dispositivo.';

  @override
  String get screensaverUrlNotSet =>
      'Nessuna URL dell\'immagine impostata. Aggiungine una in Impostazioni.';

  @override
  String get screensaverUrlLoadFailed => 'Impossibile caricare l\'immagine.';

  @override
  String get settingKioskAllowAlarmsTitle => 'Sveglie';

  @override
  String get settingKioskAllowAlarmsDescription =>
      'Imposta e gestisce le sveglie dal menu del kiosk.';

  @override
  String get settingScreensaverClockAlarmTakeoverTitle =>
      'Lascia subentrare le sveglie';

  @override
  String get settingScreensaverClockAlarmTakeoverDescription =>
      'Una sveglia che suona viene mostrata su questo salvaschermo, nel suo stile, anziché sulla propria schermata.';

  @override
  String get settingScreensaverWeatherAlarmTakeoverTitle =>
      'Lascia subentrare le sveglie';

  @override
  String get settingScreensaverWeatherAlarmTakeoverDescription =>
      'Una sveglia che suona viene mostrata su questo salvaschermo, nel suo stile, anziché sulla propria schermata.';

  @override
  String get settingAlarmsVolumeTitle => 'Volume della sveglia';

  @override
  String get settingAlarmsVolumeDescription =>
      'Il volume a cui suonano le sveglie, indipendente dal volume multimediale.';

  @override
  String get settingAlarmsToneTitle => 'Suoneria della sveglia';

  @override
  String get settingAlarmsToneDescription => 'Suona al volume della sveglia.';

  @override
  String get settingAlarmsMusicTitle => 'Musica della sveglia';

  @override
  String get settingAlarmsMusicDescription =>
      'Suona al posto della suoneria. Se la musica non può essere riprodotta, suona la suoneria.';

  @override
  String get settingAlarmsSnoozeMinutesTitle => 'Durata del posticipo';

  @override
  String get settingAlarmsSnoozeMinutesDescription =>
      'Per quanto tempo Posticipa rimanda una sveglia.';

  @override
  String get settingAlarmsSilenceAfterMinutesTitle => 'Silenzia dopo';

  @override
  String get settingAlarmsSilenceAfterMinutesDescription =>
      'Una sveglia che nessuno ferma si silenzia dopo questo tempo.';

  @override
  String get settingAlarmsSunriseMinutesTitle => 'Durata dell\'alba';

  @override
  String get settingAlarmsSunriseMinutesDescription =>
      'Quanto tempo impiega lo schermo a schiarirsi prima di una sveglia con alba.';

  @override
  String get settingAlarmsSkipMinutesTitle => 'Pulsante Salta';

  @override
  String get settingAlarmsSkipMinutesDescription =>
      'Quanto tempo prima di una sveglia i salvaschermo Orologio e Atmosfera meteo mostrano un pulsante per saltarla.';

  @override
  String get alarmsOption5Minutes => '5 minuti';

  @override
  String get alarmsOption10Minutes => '10 minuti';

  @override
  String get alarmsOption15Minutes => '15 minuti';

  @override
  String get alarmsOption20Minutes => '20 minuti';

  @override
  String get alarmsOption25Minutes => '25 minuti';

  @override
  String get alarmsOption30Minutes => '30 minuti';

  @override
  String get alarmsOption60Minutes => '60 minuti';

  @override
  String get alarmsOptionOff => 'Disattivato';

  @override
  String get settingsMenuAlarms => 'Sveglie';

  @override
  String get settingsMenuAlarmsSummary => 'Sveglie, tono, posticipo, alba';

  @override
  String get settingAlarmsEaseInTitle => 'Aumenta gradualmente il volume';

  @override
  String get settingAlarmsEaseInDescription =>
      'Inizia piano e sale fino al volume della sveglia.';

  @override
  String get settingAlarmsEaseInSecondsTitle => 'Durata dell\'aumento';

  @override
  String get settingAlarmsEaseInSecondsDescription =>
      'Quanto tempo impiega una sveglia a raggiungere il volume pieno.';

  @override
  String get settingAlarmsTtsEngineTitle => 'Motore di sintesi vocale';

  @override
  String get settingAlarmsTtsEngineDescription =>
      'L\'entità di sintesi vocale di Home Assistant che annuncia le sveglie.';

  @override
  String get settingAlarmsTtsLanguageTitle => 'Lingua';

  @override
  String get settingAlarmsTtsLanguageDescription =>
      'La lingua in cui vengono annunciate le sveglie.';

  @override
  String get settingAlarmsTtsVoiceTitle => 'Voce';

  @override
  String get settingAlarmsTtsVoiceDescription =>
      'La voce che annuncia le sveglie.';

  @override
  String get settingLauncherEnabledTitle => 'Abilita Launcher app';

  @override
  String get settingLauncherEnabledDescription =>
      'Apre dal kiosk una selezione di app installate.';

  @override
  String get settingLauncherAppsDescription => 'Le app offerte dal launcher.';

  @override
  String get settingLauncherAutoReturnTitle => 'Torna automaticamente';

  @override
  String get settingLauncherAutoReturnDescription =>
      'Torna al kiosk quando l\'altra app resta inutilizzata per un po\'.';

  @override
  String get settingLauncherAutoReturnSecondsTitle => 'Torna dopo (secondi)';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      'Tempo senza tocchi nell\'altra app prima che il kiosk ritorni.';

  @override
  String get settingLauncherAutoReturnHoldTitle =>
      'Attendi durante riproduzioni e chiamate';

  @override
  String get settingLauncherAutoReturnHoldDescription =>
      'Non torna durante video, musica o chiamate.';

  @override
  String get launcherOverlayHeld =>
      'Kiosk Satellite può tornare da solo in primo piano e rilevare i tocchi nell\'altra app.';

  @override
  String get launcherOverlayMissing =>
      'Senza questa autorizzazione il kiosk non può tornare da solo e i tocchi nell\'altra app non vengono rilevati.';

  @override
  String get launcherOverlayRemote =>
      'Senza questa autorizzazione il kiosk non può tornare da solo e i tocchi nell\'altra app non vengono rilevati. La schermata di autorizzazione compare sul tablet.';

  @override
  String get launcherBatteryMissing =>
      'Android può sospendere l\'app mentre l\'altra è in primo piano e, con il timer sospeso, il kiosk non torna mai.';

  @override
  String get launcherBatteryRemote =>
      'Android può sospendere l\'app mentre l\'altra è in primo piano e, con il timer sospeso, il kiosk non torna mai. La finestra di autorizzazione compare sul tablet.';

  @override
  String get launcherNotificationAccessHeld =>
      'Il kiosk non torna mentre un\'altra app riproduce video o musica.';

  @override
  String get launcherNotificationAccessMissing =>
      'Senza questa autorizzazione il kiosk non può sapere quando sono in riproduzione video o musica e torna comunque.';

  @override
  String get launcherNotificationAccessRemote =>
      'Senza questa autorizzazione il kiosk non può sapere quando sono in riproduzione video o musica e torna comunque. La schermata di autorizzazione compare sul tablet.';

  @override
  String get launcherPermissionsSearch =>
      'Le autorizzazioni su cui si basa Torna automaticamente.';

  @override
  String get settingCalendarDefaultViewTitle => 'Vista predefinita';

  @override
  String get settingCalendarDefaultViewDescription =>
      'La vista con cui si apre il calendario.';

  @override
  String get settingCalendarWeekStartTitle => 'Primo giorno della settimana';

  @override
  String get settingCalendarWeekStartAppLanguageDescription =>
      'Segue la lingua dell\'app, salvo diversa impostazione.';

  @override
  String get settingCalendarWeatherEntityTitle => 'Meteo';

  @override
  String get settingCalendarWeatherEntityDescription =>
      'Aggiunge le previsioni a ogni giorno.';

  @override
  String get settingCalendarAllowEditTitle =>
      'Consenti di aggiungere e modificare eventi';

  @override
  String get settingCalendarAllowEditDescription =>
      'Aggiunge Nuovo evento e Modifica al calendario.';

  @override
  String get settingCalendarAllowDeleteTitle => 'Consenti di eliminare eventi';

  @override
  String get settingCalendarAllowDeleteDescription =>
      'Aggiunge Elimina a ogni evento.';

  @override
  String get settingCalendarIdleCloseMinutesTitle =>
      'Chiudi in caso di inattività';

  @override
  String get settingIdleCloseCompassDescription =>
      'Torna alla plancia dopo questo tempo senza tocchi. Nella disposizione Compass si applica invece Torna al centro.';

  @override
  String get settingKioskAllowCalendarTitle => 'Calendario';

  @override
  String get settingKioskAllowCalendarDescription =>
      'Apre il calendario di famiglia dal menu del kiosk.';

  @override
  String get calendarWeekStartLocale => 'In base alla lingua';

  @override
  String get calendarWeekStartSunday => 'Domenica';

  @override
  String get calendarWeekStartMonday => 'Lunedì';

  @override
  String get calendarWeekStartSaturday => 'Sabato';

  @override
  String get calendarIdleNever => 'Mai';

  @override
  String get calendarIdle1Minute => '1 minuto';

  @override
  String get calendarIdle2Minutes => '2 minuti';

  @override
  String get settingsMenuCalendar => 'Calendario';

  @override
  String get settingsMenuCalendarSummary =>
      'Calendari di famiglia da Home Assistant';

  @override
  String get fleetTheCalendarsHiddenWithTheirChips =>
      'i calendari nascosti con le rispettive etichette';

  @override
  String get settingCameraEnabledTitle => 'Abilita la fotocamera';

  @override
  String get settingCameraEnabledDescription =>
      'L\'uso della fotocamera aumenta il carico della CPU e il calore, il che può ridurre la durata della batteria e del dispositivo.';

  @override
  String get settingCameraDeviceTitle => 'Fotocamera';

  @override
  String get settingCameraDeviceDescription => 'La fotocamera da usare.';

  @override
  String get settingCameraSnapshotResolutionTitle =>
      'Risoluzione delle istantanee';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      'Una risoluzione più alta offre immagini più nitide ma richiede più CPU e larghezza di banda.';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle =>
      'Disabilita le istantanee al rilevamento';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      'Impedisce le istantanee automatiche attivate dal rilevamento. Il rilevamento di movimento, volti, presenza e gesti continua a funzionare. Le richieste manuali e le Istantanee continue possono comunque acquisire immagini.';

  @override
  String get settingCameraSnapshotsTitle => 'Istantanee continue';

  @override
  String get settingCameraSnapshotsDescription =>
      'Pubblica una nuova istantanea della fotocamera in Home Assistant a intervalli regolari.';

  @override
  String get settingCameraSnapshotIntervalTitle =>
      'Intervallo delle istantanee';

  @override
  String get settingCameraSnapshotIntervalDescription =>
      'Secondi tra un\'istantanea e l\'altra.';

  @override
  String get cameraFront => 'Anteriore';

  @override
  String get cameraBack => 'Posteriore';

  @override
  String get cameraExternal => 'Esterna';

  @override
  String get cameraOnlyCamera => 'L\'unica fotocamera di questo dispositivo.';

  @override
  String get cameraFlashlightHeading => 'Torcia';

  @override
  String get settingCameraFlashlightTitle => 'Accendi la torcia';

  @override
  String get settingCameraFlashlightDescription =>
      'Usa il flash della fotocamera come luce fissa.';

  @override
  String get settingMotionSensorTitle => 'Sensore di movimento';

  @override
  String get settingMotionSensorDescription =>
      'Espone il movimento come sensore di Home Assistant. ATTENZIONE: mantiene la fotocamera sempre attiva, anche a schermo spento.';

  @override
  String get settingMotionSensorOffDelayTitle => 'Azzera dopo';

  @override
  String get settingMotionSensorOffDelayDescription =>
      'Secondi senza movimento prima che il sensore smetta di segnalare movimento.';

  @override
  String get settingMotionFpsTitle => 'Frequenza fotogrammi per il movimento';

  @override
  String get settingMotionFpsDescription =>
      'Fotogrammi al secondo in cui la fotocamera controlla il movimento. Valori più bassi pesano meno sulla CPU; 2 basta per notare qualcuno che si avvicina.';

  @override
  String get settingMotionStartDelayTitle => 'Ritardo all\'avvio';

  @override
  String get settingMotionStartDelayDescription =>
      'Ignora il movimento per questo tempo dopo l\'avvio della fotocamera, per i dispositivi la cui fotocamera si muove fisicamente quando si apre.';

  @override
  String get settingMotionSensitivityTitle => 'Sensibilità al movimento';

  @override
  String get settingMotionSensitivityDescription =>
      'Valori più alti fanno scattare il sensore con movimenti più piccoli. 1 richiede un grande cambiamento nell\'inquadratura; 100 reagisce al minimo movimento.';

  @override
  String get cameraMotionPage => 'Sensore di movimento';

  @override
  String get cameraMotionHint =>
      'Sensore di movimento di Home Assistant e impostazioni di rilevamento condivise';

  @override
  String get cameraNoCamera => 'Nessuna fotocamera rilevata';

  @override
  String get cameraNoCameraHelp =>
      'Questo dispositivo non segnala alcuna fotocamera utilizzabile.';

  @override
  String get cameraCameraPermission => 'Autorizzazione fotocamera mancante';

  @override
  String get cameraCameraPermissionHelp =>
      'Senza questa autorizzazione la fotocamera non può essere usata. La finestra di autorizzazione compare sullo schermo del tablet.';

  @override
  String get cameraGrantOnDevice => 'Concedi sul dispositivo';

  @override
  String get cameraCameraBlocked =>
      'Bloccata. Android non la chiederà più, quindi consentila nelle impostazioni dell\'app.';

  @override
  String get cameraCameraNeeded =>
      'Senza questa autorizzazione la fotocamera non può essere usata.';

  @override
  String get cameraAppSettings => 'Impostazioni dell\'app';

  @override
  String get settingPersonSensorTitle => 'Abilita il sensore di persone';

  @override
  String get settingPersonSensorDescription =>
      'Espone il sensore di persone del dispositivo a Home Assistant come sensore di occupazione. Richiede l\'autorizzazione Accesso ai registri qui sotto.';

  @override
  String get cameraPersonPage => 'Sensore di persone';

  @override
  String get cameraPersonHint =>
      'Sensore di occupazione di Home Assistant basato sul sensore di persone del dispositivo';

  @override
  String get cameraLatest => 'Ultima istantanea';

  @override
  String get cameraNoSnapshot => 'Ancora nessuna istantanea.';

  @override
  String get cameraImageAlt => 'Ultima istantanea della fotocamera';

  @override
  String get cameraTakeSnapshot => 'Scatta istantanea';

  @override
  String get cameraSnapshotFailed => 'Istantanea non riuscita.';

  @override
  String cameraSnapshotError(String error) {
    return 'Istantanea non riuscita: $error';
  }

  @override
  String get cameraCameraDisabled =>
      'La fotocamera è disabilitata nelle impostazioni Fotocamera.';

  @override
  String get cameraSnapshotBusy => 'Un\'istantanea è già in corso.';

  @override
  String get cameraPermissionDenied =>
      'Autorizzazione fotocamera non concessa.';

  @override
  String get cameraDetectionDisabled =>
      'Le istantanee al rilevamento sono disabilitate.';

  @override
  String get cameraNoImage =>
      'La fotocamera non ha restituito alcuna immagine.';

  @override
  String get cameraTimedOut => 'La fotocamera non ha risposto in tempo.';

  @override
  String get cameraBackground =>
      'La fotocamera non è disponibile mentre l\'app è in background.';

  @override
  String get cameraJustNow => 'poco fa';

  @override
  String cameraSecondsAgo(String count) {
    return '$count secondi fa';
  }

  @override
  String get cameraMinuteAgo => '1 minuto fa';

  @override
  String cameraMinutesAgo(String count) {
    return '$count minuti fa';
  }

  @override
  String get cameraHourAgo => '1 ora fa';

  @override
  String cameraHoursAgo(String count) {
    return '$count ore fa';
  }

  @override
  String get cameraDayAgo => '1 giorno fa';

  @override
  String cameraDaysAgo(String count) {
    return '$count giorni fa';
  }

  @override
  String get cameraStatusHeading => 'Stato del flusso';

  @override
  String get cameraClientsHeading => 'Client connessi';

  @override
  String get cameraUnavailable => 'Non disponibile';

  @override
  String get cameraStopped => 'Arrestato';

  @override
  String get cameraStreaming => 'In trasmissione';

  @override
  String get cameraIdle => 'In attesa';

  @override
  String get cameraConnected => 'Connesso';

  @override
  String get cameraChecking => 'Verifica in corso...';

  @override
  String get cameraCheckingStatus => 'Verifica dello stato del flusso...';

  @override
  String get cameraStatusUnavailable => 'Stato del flusso non disponibile.';

  @override
  String get cameraListenerStopped => 'Il server è arrestato.';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count spettatore connesso. Video effettivo: $resolution.';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return '$count spettatori connessi. Video effettivo: $resolution.';
  }

  @override
  String get cameraReady =>
      'Pronto. L\'encoder si avvia quando si connette uno spettatore.';

  @override
  String cameraFallback(String requested, String actual) {
    return 'Richiesto $requested, la fotocamera ha fornito $actual.';
  }

  @override
  String cameraAudioError(String error) {
    return 'Audio: $error';
  }

  @override
  String get cameraAudioPaused =>
      'Audio in pausa mentre il browser usa il microfono.';

  @override
  String get cameraAudioStreaming => 'Audio del microfono in trasmissione.';

  @override
  String get cameraAudioIdle => 'Audio del microfono inattivo.';

  @override
  String cameraDiscoveryError(String error) {
    return 'Rilevamento ONVIF: $error';
  }

  @override
  String get cameraOnvifUrl => 'URL ONVIF';

  @override
  String get cameraStreamUrl => 'URL del flusso';

  @override
  String get cameraWaitingAddress => 'In attesa di un indirizzo di rete';

  @override
  String get cameraClientsUnavailable =>
      'Informazioni sui client non disponibili.';

  @override
  String get cameraNoClients => 'Nessun client connesso.';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · Porta $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return 'Connesso da $duration';
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
      'Imposta un nome utente e una password per lo streaming per abilitare l\'autenticazione.';

  @override
  String get cameraPortWaiting => 'In attesa che la porta RTSP venga liberata.';

  @override
  String get cameraListenerFailed => 'Impossibile avviare il server RTSP.';

  @override
  String get settingCameraRtspEnabledTitle =>
      'Abilita lo streaming della fotocamera';

  @override
  String get settingCameraRtspEnabledDescription =>
      'Condivide video H.264 con client RTSP o ONVIF. La codifica video avviene solo mentre è connesso uno spettatore. Viene preferita la codifica hardware, con ripiego sul software quando serve. Usa la fotocamera selezionata nelle impostazioni Fotocamera.';

  @override
  String get settingCameraStreamingProtocolTitle => 'Protocollo di streaming';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF consente ai client compatibili di rilevare la fotocamera e connettersi al suo flusso.';

  @override
  String get settingCameraRtspPortTitle => 'Porta';

  @override
  String get settingCameraRtspPortDescription => 'Porta del server RTSP.';

  @override
  String get settingCameraOnvifPortTitle => 'Porta';

  @override
  String get settingCameraOnvifPortDescription => 'Porta del server ONVIF.';

  @override
  String get settingCameraRtspResolutionTitle => 'Risoluzione';

  @override
  String get settingCameraRtspResolutionDescription =>
      'Dimensioni di streaming supportate dalla fotocamera e dall\'encoder selezionati. Il video segue l\'orientamento del dispositivo.';

  @override
  String get settingCameraRtspAnalysisTitle =>
      'Analisi del movimento durante lo streaming';

  @override
  String get settingCameraRtspAnalysisDescription =>
      'Mantiene disponibili il rilevamento del movimento, il rilevamento dei volti e i gesti della mano mentre ci sono spettatori connessi. Disattivandola si possono ottenere risoluzioni più alte. In tal caso le istantanee usano fotogrammi video alla risoluzione dello streaming.';

  @override
  String get settingCameraRtspFpsTitle => 'Frequenza fotogrammi';

  @override
  String get settingCameraRtspFpsDescription =>
      'Fotogrammi video al secondo desiderati. Il movimento mantiene la sua frequenza di analisi separata. La frequenza effettiva dipende dalla fotocamera.';

  @override
  String get settingCameraRtspBitrateTitle => 'Bitrate';

  @override
  String get settingCameraRtspBitrateDescription =>
      'Bitrate video desiderato. Valori più alti migliorano il dettaglio e usano più larghezza di banda di rete.';

  @override
  String get settingCameraRtspAudioTitle => 'Includi l\'audio del microfono';

  @override
  String get settingCameraRtspAudioDescription =>
      'Include l\'audio del microfono nel flusso della fotocamera. Condivide le impostazioni del microfono. ATTENZIONE: aumenta l\'uso della CPU.';

  @override
  String get settingCameraRtspAuthTitle => 'Richiedi l\'autenticazione';

  @override
  String get settingCameraRtspAuthDescription =>
      'Richiede nome utente e password per vedere il flusso. L\'autenticazione non attiva la crittografia.';

  @override
  String get settingCameraRtspUsernameTitle => 'Nome utente';

  @override
  String get settingCameraRtspUsernameDescription =>
      'Nome utente per i client di streaming.';

  @override
  String get settingCameraRtspPasswordTitle => 'Password';

  @override
  String get settingCameraRtspPasswordDescription =>
      'Imposta una password per avviare il flusso autenticato.';

  @override
  String get cameraStreamingPage => 'Streaming RTSP e ONVIF';

  @override
  String get cameraStreamingHint =>
      'Condivide la fotocamera del dispositivo tramite RTSP o ONVIF';

  @override
  String get cameraPortError =>
      'Inserisci un numero di porta intero da 1024 a 65535.';

  @override
  String get cameraUsernameError =>
      'Usa da 1 a 64 caratteri senza spazi, virgolette, due punti o barre rovesciate.';

  @override
  String get cameraNoSizes => 'Nessuna dimensione supportata disponibile';

  @override
  String get cameraNoSizesHelp =>
      'Nessuna dimensione supportata disponibile. Controlla la connessione della fotocamera.';

  @override
  String get cameraResolutionSupport => 'Risoluzioni supportate';

  @override
  String get cameraCheckingSizes =>
      'Verifica del supporto della fotocamera e dell\'encoder H.264...';

  @override
  String get cameraSupportedSizes =>
      'Sono elencate solo le dimensioni supportate dalla fotocamera e dall\'encoder H.264 con le impostazioni di streaming attuali.';

  @override
  String cameraExtraSizes(String sizes) {
    return 'Disattiva Analisi del movimento durante lo streaming per usare anche $sizes.';
  }

  @override
  String get cameraAnalysisOff =>
      'Il rilevamento del movimento, il rilevamento dei volti e i gesti della mano vengono sospesi mentre ci sono spettatori connessi. Le istantanee usano fotogrammi video alla risoluzione dello streaming.';

  @override
  String cameraRejectedSizes(String sizes) {
    return 'L\'encoder non può usare $sizes con queste impostazioni.';
  }

  @override
  String cameraRejectedCount(String count) {
    return '$count dimensioni della fotocamera sono escluse perché l\'encoder non può usarle con queste impostazioni.';
  }

  @override
  String get cameraCaptureRejected =>
      'Altre dimensioni della fotocamera non sono disponibili con l\'attuale configurazione di acquisizione.';

  @override
  String get cameraMotionEventsHeading => 'Eventi di movimento';

  @override
  String get settingCameraOnvifEventsTitle => 'Invia eventi di movimento';

  @override
  String get settingCameraOnvifEventsDescription =>
      'Avvisa i client ONVIF, come gli NVR, quando viene rilevato un movimento.';

  @override
  String get settingCameraOnvifEventsSourceTitle => 'Origine del movimento';

  @override
  String get settingCameraOnvifEventsSourceDescription =>
      'Il sensore che invia gli eventi di movimento.';

  @override
  String get cameraOnvifEventsSourceCamera =>
      'Sensore di movimento della fotocamera';

  @override
  String get cameraOnvifEventsSourcePerson => 'Sensore di persone';

  @override
  String get cameraOnvifEventsSourceEntity => 'Sensore di Home Assistant';

  @override
  String get cameraOnvifEventsMotionSensorOff =>
      'Il sensore di movimento della fotocamera è disattivato. Attivalo in Fotocamera > Sensore di movimento.';

  @override
  String get cameraOnvifEventsAnalysisOff =>
      'L\'impostazione Analisi del movimento durante lo streaming è disattivata, quindi la fotocamera non può rilevare movimenti mentre è connesso uno spettatore.';

  @override
  String get cameraOnvifEventsPersonSensorOff =>
      'Il sensore di persone è disattivato. Attivalo in Fotocamera > Sensore di persone.';

  @override
  String get cameraOverlaysHeading => 'Sovrapposizioni';

  @override
  String get settingCameraRtspDateTimeTitle => 'Mostra data e ora';

  @override
  String get settingCameraRtspDateTimeDescription =>
      'Mostra la data e l\'ora del dispositivo nell\'angolo in alto a sinistra del video, con il suo formato della data e l\'impostazione 12/24 ore.';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => 'Sfondo nero';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      'Aggiunge uno sfondo nero dietro data e ora per migliorarne la leggibilità.';

  @override
  String get settingCameraRtspTlsTitle => 'Crittografa il flusso';

  @override
  String get settingCameraRtspTlsDescription =>
      'Usa TLS per crittografare video e audio. Richiede un visualizzatore compatibile.';

  @override
  String get cameraStreamsNameRequired => 'nome obbligatorio';

  @override
  String get cameraStreamsBaseUrlRequired =>
      'baseUrl HTTP o HTTPS valida obbligatoria';

  @override
  String get cameraStreamsServerNotFound => 'server non trovato';

  @override
  String get cameraStreamsInvalidStreamList =>
      'Go2RTC ha restituito un elenco di flussi non valido';

  @override
  String get cameraStreamsKindRequired => 'kind deve essere go2rtc, whep o ha';

  @override
  String get cameraStreamsProtocolRequired =>
      'preferredProtocol deve essere auto, webrtc, hls o mjpeg';

  @override
  String get cameraStreamsServerRequired => 'serverId valido obbligatorio';

  @override
  String get cameraStreamsStreamRequired => 'streamName obbligatorio';

  @override
  String get cameraStreamsEntityRequired =>
      'è obbligatorio un entityId camera.*';

  @override
  String get cameraStreamsWhepRequired => 'URL WHEP valida obbligatoria';

  @override
  String get cameraStreamsCameraNotFound => 'telecamera non trovata';

  @override
  String get cameraStreamsListRequired => 'cameraIds deve essere un elenco';

  @override
  String get cameraStreamsViewCount =>
      'una vista deve contenere da 1 a 12 telecamere';

  @override
  String get cameraStreamsRepeatedCamera =>
      'una telecamera può comparire una sola volta per vista';

  @override
  String get cameraStreamsUnknownViewCamera =>
      'la vista contiene una telecamera sconosciuta';

  @override
  String get cameraStreamsUniqueViewName =>
      'il nome della vista deve essere univoco';

  @override
  String get cameraStreamsGridRange =>
      'la griglia deve essere compresa tra 1 e 12';

  @override
  String get cameraStreamsGridTooSmall =>
      'la griglia è più piccola del numero di telecamere';

  @override
  String get cameraStreamsViewNotFound => 'vista non trovata';

  @override
  String get cameraStreamsDefaultViewDelete =>
      'la vista predefinita non può essere eliminata: svuotala';

  @override
  String get cameraStreamsViewEmpty => 'la vista non contiene telecamere';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return 'impossibile leggere Home Assistant: $error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return 'impossibile connettersi a $server: $error';
  }

  @override
  String get cameraStreamsHaUnavailable =>
      'Home Assistant non è configurato o non è raggiungibile';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC ha restituito HTTP $status';
  }

  @override
  String get cameraStreamsImportHa => 'Importa telecamere da Home Assistant';

  @override
  String get cameraStreamsImportHaHelp =>
      'Aggiunge tutte le telecamere dell\'istanza Home Assistant connessa, riprodotte tramite WebRTC, HLS o MJPEG. Una nuova importazione aggiunge le telecamere nuove.';

  @override
  String get cameraStreamsImportFailed => 'Importazione non riuscita';

  @override
  String get cameraStreamsImportComplete => 'Importazione completata';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return '$added aggiunte, $missing mancanti.';
  }

  @override
  String get settingCameraAllowH265Title => 'Consenti flussi H.265';

  @override
  String get settingCameraAllowH265Description =>
      'Riproduce i flussi H.265 delle telecamere così come sono. Un dispositivo che non può decodificare H.265 mostra invece un\'immagine vuota.';

  @override
  String get settingCameraPreferMseTitle => 'Preferisci MSE a WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      'Usa prima MSE per le telecamere Go2RTC. Per i dispositivi che non riproducono WebRTC; aggiunge uno o due secondi di ritardo.';

  @override
  String get settingCameraPreferHlsTitle => 'Preferisci HLS a WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      'Usa prima HLS per le telecamere di Home Assistant. Per i dispositivi che non riproducono WebRTC; aggiunge qualche secondo di ritardo.';

  @override
  String get settingCameraSingleAudioTitle =>
      'Riproduci l\'audio con una sola telecamera';

  @override
  String get settingCameraSingleAudioDescription =>
      'Riproduce l\'audio della telecamera quando sullo schermo c\'è una sola telecamera. Le griglie con più telecamere restano senza audio.';

  @override
  String get settingCameraPinchZoomTitle =>
      'Pizzica per ingrandire una sola telecamera';

  @override
  String get settingCameraPinchZoomDescription =>
      'Ingrandisce l\'immagine con due dita quando sullo schermo c\'è una sola telecamera. Trascina per spostarti, tocca due volte per ripristinare.';

  @override
  String get settingCameraAutoDismissSecondsTitle =>
      'Chiudi automaticamente dopo';

  @override
  String get settingCameraAutoDismissCompassDescription =>
      'Chiude una vista telecamere aperta dopo questo tempo. Con 0 resta aperta. Non influisce sul salvaschermo delle telecamere. Nella disposizione Compass si applica invece Torna al centro.';

  @override
  String get cameraStreamsPlayback => 'Riproduzione';

  @override
  String get cameraStreamsOff => 'Disattivato';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get cameraStreamsGridHelp =>
      'Le griglie con più telecamere mostrano solo il video. Sui dispositivi poco potenti, usa nelle viste flussi Go2RTC a risoluzione più bassa e, se vuoi, imposta un flusso separato per lo schermo intero.';

  @override
  String get cameraStreamsServers => 'Server Go2RTC';

  @override
  String get cameraStreamsImportStreams => 'Importa flussi';

  @override
  String get cameraStreamsDeleteServer => 'Elimina server';

  @override
  String get cameraStreamsAddServer => 'Aggiungi server Go2RTC';

  @override
  String get cameraStreamsAddServerHelp =>
      'Connettiti a un server e importa i suoi flussi.';

  @override
  String get cameraStreamsEditServer => 'Modifica server';

  @override
  String get cameraStreamsName => 'Nome';

  @override
  String get cameraStreamsBaseUrl => 'URL di base';

  @override
  String get cameraStreamsUsername => 'Nome utente (facoltativo)';

  @override
  String get cameraStreamsNewPassword =>
      'Nuova password (lascia vuoto per mantenerla)';

  @override
  String get cameraStreamsPassword => 'Password (facoltativa)';

  @override
  String get cameraStreamsInvalidCertificate =>
      'Consenti certificato TLS non valido';

  @override
  String get cameraStreamsSaveServerFailed => 'Impossibile salvare il server';

  @override
  String get cameraStreamsDeleteServerHelp =>
      'Le sue telecamere verranno rimosse da tutte le viste.';

  @override
  String get cameraStreamsCameras => 'Telecamere';

  @override
  String get cameraStreamsNoCameras => 'Nessuna telecamera configurata';

  @override
  String get cameraStreamsNoCamerasHelp =>
      'Importa le telecamere da Home Assistant o Go2RTC, oppure aggiungine una manualmente.';

  @override
  String get cameraStreamsDeleteCamera => 'Elimina telecamera';

  @override
  String get cameraStreamsAddManually => 'Aggiungi telecamera manualmente';

  @override
  String get cameraStreamsAddManuallyHelp =>
      'Usa il nome di un flusso Go2RTC, un\'URL WHEP o un\'entità telecamera di Home Assistant.';

  @override
  String get cameraStreamsUnknownCamera => 'Telecamera sconosciuta';

  @override
  String get cameraStreamsUnknownServer => 'Server sconosciuto';

  @override
  String get cameraStreamsMissing => ' (mancante)';

  @override
  String get cameraStreamsAddCamera => 'Aggiungi telecamera';

  @override
  String get cameraStreamsEditCamera => 'Modifica telecamera';

  @override
  String get cameraStreamsType => 'Tipo';

  @override
  String get cameraStreamsGo2RtcStream => 'Flusso Go2RTC';

  @override
  String get cameraStreamsDirectWhep => 'URL WHEP diretta';

  @override
  String get cameraStreamsHaCamera => 'Telecamera di Home Assistant';

  @override
  String get cameraStreamsEntity => 'Entità telecamera';

  @override
  String get cameraStreamsProtocol => 'Protocollo preferito';

  @override
  String get cameraStreamsAuto => 'Automatico';

  @override
  String get cameraStreamsServer => 'Server';

  @override
  String get cameraStreamsStreamName => 'Nome del flusso';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Nome del flusso Go2RTC';

  @override
  String get cameraStreamsFullscreen => 'Flusso a schermo intero (facoltativo)';

  @override
  String get cameraStreamsWhep => 'URL WHEP';

  @override
  String get cameraStreamsSaveCameraFailed =>
      'Impossibile salvare la telecamera';

  @override
  String get cameraStreamsDeleteCameraHelp =>
      'Verrà rimossa da tutte le viste.';

  @override
  String get cameraStreamsLoadFailed => 'Impossibile caricare le telecamere.';

  @override
  String get cameraStreamsDeleteUnused => 'Elimina telecamere inutilizzate';

  @override
  String get cameraStreamsDeleteUnusedConfirm =>
      'Eliminare le telecamere inutilizzate?';

  @override
  String cameraStreamsOneUnusedCamera(String count) {
    return '$count telecamera non è in nessuna vista.';
  }

  @override
  String cameraStreamsManyUnusedCameras(String count) {
    return '$count telecamere non sono in nessuna vista.';
  }

  @override
  String get cameraStreamsViews => 'Viste';

  @override
  String get cameraStreamsEmptyView => 'Ancora nessuna telecamera';

  @override
  String get cameraStreamsNamesShown => 'Nomi visibili';

  @override
  String get cameraStreamsNamesHidden => 'Nomi nascosti';

  @override
  String get cameraStreamsShowView => 'Mostra vista';

  @override
  String get cameraStreamsDeleteView => 'Elimina vista';

  @override
  String get cameraStreamsCreateView => 'Crea vista telecamere';

  @override
  String get cameraStreamsAddFirst => 'Prima aggiungi una telecamera.';

  @override
  String get cameraStreamsChooseCameras =>
      'Scegli e ordina fino a 12 telecamere.';

  @override
  String get cameraStreamsShowFailed => 'Impossibile mostrare la vista';

  @override
  String get cameraStreamsShowFailedRemote => 'Impossibile mostrare la vista';

  @override
  String get cameraStreamsEditView => 'Modifica vista';

  @override
  String get cameraStreamsViewId => 'ID vista';

  @override
  String get cameraStreamsShowNames => 'Mostra i nomi delle telecamere';

  @override
  String get cameraStreamsShowNamesHelp =>
      'Mostra un\'etichetta sopra ogni telecamera.';

  @override
  String get cameraStreamsGrid => 'Griglia';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count telecamera';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return '$count telecamere';
  }

  @override
  String get cameraStreamsInView => 'In questa vista';

  @override
  String get cameraStreamsAvailable => 'Disponibili';

  @override
  String cameraStreamsPosition(String position) {
    return 'Posizione $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'Non presente in Go2RTC';

  @override
  String get cameraStreamsSaveViewFailed => 'Impossibile salvare la vista';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get cameraStreamsCannotUndo =>
      'L\'operazione non può essere annullata.';

  @override
  String get cameraStreamsShow => 'Mostra';

  @override
  String get cameraStreamsStop => 'Interrompi';

  @override
  String get settingAnalyticsBasicTitle => 'Statistiche di base';

  @override
  String get settingAnalyticsBasicDescription =>
      'Informazioni sul dispositivo, come modello, versione di Android, versione dell\'app, dimensioni dello schermo e lingua.';

  @override
  String get settingAnalyticsUsageTitle => 'Utilizzo';

  @override
  String get settingAnalyticsUsageDescription =>
      'Dettagli su ciò che usi con Kiosk Satellite.';

  @override
  String get settingAnalyticsDiagnosticsTitle => 'Diagnostica';

  @override
  String get settingAnalyticsDiagnosticsDescription =>
      'Condivide i rapporti sugli arresti anomali quando si verificano errori imprevisti.';

  @override
  String get deviceAnalyticsPage => 'Statistiche di Kiosk Satellite';

  @override
  String get deviceAnalyticsIntro =>
      'Condividi informazioni anonimizzate sulla tua installazione per aiutare a migliorare Kiosk Satellite e a decidere a quali dispositivi e funzionalità dedicare attenzione.';

  @override
  String get deviceAnalyticsLearn => 'Scopri come trattiamo i tuoi dati';

  @override
  String get deviceAnalyticsLearnHelp =>
      'Cosa inviano le Statistiche di Kiosk Satellite e cosa non inviano mai.';

  @override
  String get deviceExportConfig => 'Esporta configurazione';

  @override
  String get deviceExportConfigHelp =>
      'Salva in un file tutte le impostazioni e l\'archiviazione locale della pagina.';

  @override
  String get deviceExportConfigRemoteHelp =>
      'Scarica tutte le impostazioni e l\'archiviazione locale della pagina.';

  @override
  String get deviceImportConfig => 'Importa configurazione';

  @override
  String get deviceImportConfigHelp =>
      'Sostituisce le impostazioni di questo dispositivo con quelle di un file esportato.';

  @override
  String get deviceExportFailed => 'Esportazione non riuscita';

  @override
  String get deviceExported => 'Configurazione esportata';

  @override
  String get deviceImportFailed => 'Importazione non riuscita';

  @override
  String get deviceInvalidJson => 'Il file non contiene un JSON valido.';

  @override
  String get deviceImportComplete => 'Importazione completata';

  @override
  String deviceAppliedSettings(String count) {
    return '$count impostazioni applicate.';
  }

  @override
  String deviceAppliedReload(String count) {
    return '$count impostazioni applicate. La pagina potrebbe ricaricarsi.';
  }

  @override
  String get deviceReplaceOriginal => 'Sostituisci il dispositivo originale';

  @override
  String get deviceReplaceQuestion =>
      'Sostituire le impostazioni di questo dispositivo con quelle del file? La pagina potrebbe ricaricarsi.';

  @override
  String get deviceNewDevice => 'Configura come nuovo dispositivo';

  @override
  String get deviceReplaceIdentity =>
      'Mantiene il nome e l\'identità ESPHome del backup; il dispositivo originale deve restare offline.';

  @override
  String get deviceNewIdentity =>
      'Assegna un nome e un\'identità ESPHome propri, così entrambi i dispositivi restano univoci.';

  @override
  String get deviceRestoreStorage =>
      'Ripristina l\'archiviazione locale di WebView';

  @override
  String get deviceRestoreStorageHelp =>
      'Include la sessione di Home Assistant con l\'accesso effettuato e la selezione assist_satellite di Voice Satellite: due dispositivi non devono condividere lo stesso satellite.';

  @override
  String get deviceDownload => 'Scarica';

  @override
  String get deviceChooseFile => 'Scegli file…';

  @override
  String get deviceImportFailedSentence => 'Importazione non riuscita.';

  @override
  String deviceReplaceNamed(String name) {
    return 'Sostituisci \"$name\"';
  }

  @override
  String get settingDeviceNameTitle => 'Nome del dispositivo';

  @override
  String get settingDeviceNameDescription =>
      'Nome descrittivo mostrato nell\'amministrazione remota e usato come nome del dispositivo pubblicato in Home Assistant.';

  @override
  String get settingDeviceHostnameTitle => 'Nome mDNS';

  @override
  String get settingDeviceHostnameDescription =>
      'Permette di raggiungere l\'amministrazione remota sulla rete locale con questo nome e la porta configurata. Cancellalo per usare di nuovo il nome del dispositivo.';

  @override
  String get settingDisableImpellerTitle => 'Renderer precedente';

  @override
  String get settingDisableImpellerDescription =>
      'Usa il vecchio renderer Skia, per le GPU datate che si arrestano in modo anomalo all\'avvio. Si attiva da solo dopo due arresti di questo tipo; ha effetto al prossimo avvio dell\'app.';

  @override
  String get settingLegacyWebViewTitle => 'Renderer WebView precedente';

  @override
  String get settingLegacyWebViewDescription =>
      'Disegna la plancia in una texture, per le GPU datate che si arrestano in modo anomalo quando compare. Si attiva da solo quando il dispositivo ne ha bisogno; ha effetto al prossimo avvio dell\'app.';

  @override
  String get deviceHostnamePlaceholder => 'Ricavato dal nome del dispositivo';

  @override
  String get deviceConfiguration => 'Configurazione';

  @override
  String get devicePermissionsManager => 'Gestione autorizzazioni';

  @override
  String get deviceOptions => 'Opzioni';

  @override
  String get deviceStatus => 'Stato';

  @override
  String get deviceConnection => 'Connessione';

  @override
  String get devicePermissions => 'Autorizzazioni';

  @override
  String get deviceHelp => 'Guida';

  @override
  String get deviceAccess => 'Accesso';

  @override
  String get deviceReading => 'Lettura…';

  @override
  String get deviceChecking => 'Verifica in corso...';

  @override
  String get deviceUnavailable => 'Stato non disponibile.';

  @override
  String get deviceGrantOnDevice => 'Concedi sul dispositivo';

  @override
  String get deviceAppSettings => 'Impostazioni dell\'app';

  @override
  String get deviceCopyCommand => 'Copia comando';

  @override
  String get deviceOpenGuide => 'Apri guida';

  @override
  String get deviceNotSet => 'Non impostato';

  @override
  String get deviceGranted => 'Concessa';

  @override
  String get deviceNotGranted => 'Non concessa';

  @override
  String get deviceMissing => 'Mancante';

  @override
  String get deviceNotOffered => 'Non disponibile';

  @override
  String get deviceOn => 'attivo';

  @override
  String get deviceOff => 'non attivo';

  @override
  String get deviceServiceHint =>
      'Stato, cosa lo mantiene attivo, autorizzazioni richieste';

  @override
  String get deviceRemoteHintActual =>
      'Gestisci questo kiosk da un browser della tua rete';

  @override
  String get deviceUpdatesHint => 'Dove l\'app cerca le nuove versioni';

  @override
  String get deviceShizukuHint =>
      'Connessione, autorizzazioni Android e configurazione';

  @override
  String get deviceHelperHint =>
      'Stato degli aggiornamenti silenziosi, configurazione ADB e istruzioni';

  @override
  String get deviceAnalyticsHint =>
      'Condividi informazioni anonimizzate per aiutare a migliorare Kiosk Satellite';

  @override
  String get deviceHardwareHint =>
      'Modello, versione di Android, indirizzi, memoria, tempo di attività';

  @override
  String get deviceHaHint => 'Connessione, versione e cosa mostra il kiosk';

  @override
  String get deviceWebViewHint => 'Versione del motore, renderer e user agent';

  @override
  String get devicePasswordSet => '•••••• (impostata)';

  @override
  String get deviceSaveFailed =>
      'Impossibile salvare questa impostazione. Riprova.';

  @override
  String get deviceOpenSettingsDevice => 'Apri le impostazioni sul dispositivo';

  @override
  String get deviceHardwareButtons => 'Tasti fisici';

  @override
  String get deviceHardwareButtonsHeld =>
      'Le pressioni dei tasti del dispositivo arrivano ai gesti e a Voice Satellite.';

  @override
  String get deviceHardwareButtonsMissing =>
      'I tasti del dispositivo non fanno nulla finché il servizio dei tasti non viene attivato.';

  @override
  String get deviceHeadlessAdbMicrophone =>
      'Questo dispositivo non ha uno schermo. Concedila tramite adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO';

  @override
  String get deviceHeadlessAdbNotifications =>
      'Questo dispositivo non ha uno schermo. Concedila tramite adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS';

  @override
  String get deviceHeadlessAdbLocation =>
      'Questo dispositivo non ha uno schermo. Concedila tramite adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION';

  @override
  String get deviceHeadlessAdbBluetooth =>
      'Questo dispositivo non ha uno schermo. Concedila tramite adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN, poi fai lo stesso per BLUETOOTH_CONNECT';

  @override
  String get deviceHeadlessAdbBattery =>
      'Questo dispositivo non ha uno schermo. Concedila tramite adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceHeadlessAdbStorage =>
      'Questo dispositivo non ha uno schermo. Concedila tramite adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE, poi fai lo stesso per WRITE_EXTERNAL_STORAGE';

  @override
  String get deviceHeadlessAdbButtons =>
      'Questo dispositivo non ha uno schermo. Attivalo tramite adb: adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/.HeadlessKeyService, poi adb shell settings put secure accessibility_enabled 1';

  @override
  String get deviceHeadlessAdbButtonsRestart =>
      'Il servizio dei tasti è attivato ma non è stato avviato. Riavvia il dispositivo per avviarlo: adb reboot';

  @override
  String get deviceHardwarePage => 'Hardware';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => 'Modello del dispositivo';

  @override
  String get deviceAndroidVersion => 'Versione di Android';

  @override
  String get deviceAndroidBuild => 'Build di Android';

  @override
  String get deviceIpv4 => 'Indirizzo IPv4';

  @override
  String get deviceIpv6 => 'Indirizzi IPv6';

  @override
  String get deviceAppUptime => 'Tempo di attività dell\'app';

  @override
  String get deviceNetworkUptime => 'Tempo di attività della rete';

  @override
  String get deviceCpuUsage => 'Utilizzo della CPU';

  @override
  String get deviceCpuClock => 'Frequenza della CPU';

  @override
  String get deviceCpuTemp => 'Temperatura della CPU';

  @override
  String get deviceBatteryLevel => 'Livello della batteria';

  @override
  String get deviceBatteryTemp => 'Temperatura della batteria';

  @override
  String get deviceScreenBrightness => 'Luminosità dello schermo';

  @override
  String get deviceScreenStatus => 'Stato dello schermo';

  @override
  String get deviceScreenSize => 'Dimensioni dello schermo';

  @override
  String get deviceRam => 'RAM (libera/totale)';

  @override
  String get deviceStorage => 'Memoria interna (libera/totale)';

  @override
  String get deviceHaUrl => 'URL di Home Assistant';

  @override
  String get deviceWakeDetection => 'Rilevamento della parola di attivazione';

  @override
  String get deviceWakeStatus => 'Stato della parola di attivazione';

  @override
  String get deviceEngine => 'Motore';

  @override
  String get deviceWakeWords => 'Parole di attivazione';

  @override
  String get deviceStopWord => 'Parola di arresto';

  @override
  String get deviceMotionDetection => 'Rilevamento del movimento';

  @override
  String get deviceFaceDetection => 'Rilevamento dei volti';

  @override
  String get deviceProvider => 'Fornitore';

  @override
  String get deviceVersion => 'Versione';

  @override
  String get deviceUserAgent => 'User agent';

  @override
  String get devicePlugged => 'collegato';

  @override
  String get deviceLowMemory => 'scarsa';

  @override
  String get deviceRequiredPermissions => 'Autorizzazioni di sistema richieste';

  @override
  String get devicePermissionIntro =>
      'Le autorizzazioni si concedono su questo dispositivo, quindi ogni pulsante apre qui una finestra di dialogo o una schermata delle impostazioni di Android. Alcuni produttori aggiungono un proprio gestore della batteria o dell\'avvio automatico, che Android non è in grado di segnalare.';

  @override
  String get devicePermissionIntroRemote =>
      'Le autorizzazioni si concedono sul dispositivo, quindi ogni pulsante apre lì una finestra di dialogo o una schermata delle impostazioni di Android. Alcuni produttori aggiungono un proprio gestore della batteria o dell\'avvio automatico, che Android non è in grado di segnalare.';

  @override
  String get deviceMicrophone => 'Microfono';

  @override
  String get deviceMicrophoneHeld =>
      'Consente di usare il microfono per il rilevamento della parola di attivazione, la trascrizione vocale e le chiamate dell\'interfono.';

  @override
  String get deviceBattery => 'Batteria senza restrizioni';

  @override
  String get deviceBatteryHeld =>
      'Consente al processo di funzionare in background senza essere sospeso o chiuso.';

  @override
  String get deviceCamera => 'Fotocamera';

  @override
  String get deviceCameraHeld =>
      'Il rilevamento del movimento e le istantanee possono usare la fotocamera.';

  @override
  String get deviceBluetooth => 'Dispositivi nelle vicinanze';

  @override
  String get deviceBluetoothHeld =>
      'Il proxy Bluetooth può cercare dispositivi nelle vicinanze.';

  @override
  String get deviceNotifications => 'Notifiche';

  @override
  String get deviceNotificationsHeld =>
      'Consente la notifica permanente del Servizio Kiosk Satellite, che indica cosa mantiene attivo.';

  @override
  String get deviceOverlay => 'Mostra sopra altre app';

  @override
  String get deviceOverlayHeld =>
      'Kiosk Satellite può tornare da solo in primo piano.';

  @override
  String get deviceWriteSettings => 'Modifica impostazioni di sistema';

  @override
  String get deviceWriteSettingsHeld =>
      'Le modifiche alla luminosità agiscono sulla luminosità reale dello schermo.';

  @override
  String get deviceUiGuard => 'Protezione dell\'interfaccia di sistema';

  @override
  String get deviceUiGuardHeld =>
      'L\'area notifiche e la schermata delle app recenti si chiudono da sole mentre lo schermo è protetto.';

  @override
  String get deviceDeviceAdmin => 'Amministratore del dispositivo';

  @override
  String get deviceDeviceAdminHeld =>
      'Consente all\'app di spegnere lo schermo.';

  @override
  String get deviceAllFiles => 'Accesso a tutti i file';

  @override
  String get deviceAllFilesHeld =>
      'Gestione file può esplorare la memoria condivisa.';

  @override
  String get deviceUsageAccess => 'Accesso ai dati di utilizzo';

  @override
  String get deviceUsageAccessHeld =>
      'Il sensore dell\'app in primo piano può indicare qualsiasi app presente sullo schermo.';

  @override
  String get deviceLocation => 'Posizione';

  @override
  String get deviceLocationHeld =>
      'Le pagine, la scansione Bluetooth e i sensori di posizione possono usare la posizione del dispositivo.';

  @override
  String get deviceMicBlocked =>
      'Bloccata. Android non la chiederà più, quindi consentila nelle impostazioni dell\'app.';

  @override
  String get deviceMicMissing =>
      'Il rilevamento della parola di attivazione è attivo, ma niente è in ascolto.';

  @override
  String get deviceMicIdle =>
      'Necessaria per il rilevamento della parola di attivazione, l\'interfono e le pagine che richiedono il microfono.';

  @override
  String get deviceBatteryMissing =>
      'Android può sospendere l\'app quando lo schermo è spento, interrompendo la connessione a Home Assistant e, con essa, le entità ESPHome.';

  @override
  String get deviceCameraMissing =>
      'La fotocamera è attivata, ma non può essere aperta.';

  @override
  String get deviceCameraIdle =>
      'Necessaria per il rilevamento del movimento, le istantanee della fotocamera e le pagine che richiedono la fotocamera.';

  @override
  String get deviceBluetoothMissing =>
      'Il proxy Bluetooth è attivato, ma non può eseguire la ricerca.';

  @override
  String get deviceBluetoothLocation =>
      'La scansione Bluetooth richiede l\'autorizzazione Posizione.';

  @override
  String get deviceBluetoothLocationOff =>
      'La posizione è disattivata nelle impostazioni del dispositivo, quindi la scansione Bluetooth non trova nulla.';

  @override
  String get deviceBluetoothIdle =>
      'Necessaria al proxy Bluetooth per cercare dispositivi.';

  @override
  String get deviceNotificationMissing =>
      'Necessaria per mostrare la notifica permanente del Servizio Kiosk Satellite.';

  @override
  String get deviceOverlayMissing =>
      'Senza questa autorizzazione l\'app non può riaprirsi dopo un arresto anomalo, un aggiornamento o una parola di attivazione rilevata mentre è in primo piano un\'altra app.';

  @override
  String get deviceOverlayIdle =>
      'Consente all\'app di riportarsi in primo piano e alla protezione della modalità blocco di coprire l\'intero schermo.';

  @override
  String get deviceBrightnessMissing =>
      'La luminosità oscura solo la finestra dell\'app, quindi lo schermo e Home Assistant non vedono mai la modifica.';

  @override
  String get deviceBrightnessIdle =>
      'Necessaria per impostare la luminosità reale dello schermo invece di oscurare la finestra dell\'app.';

  @override
  String get deviceGuardMissing =>
      'L\'area notifiche e la schermata delle app recenti restano accessibili. Abilita Kiosk Satellite in Accessibilità.';

  @override
  String get deviceGuardIdle =>
      'Chiude l\'area notifiche e la schermata delle app recenti mentre la modalità kiosk protegge lo schermo.';

  @override
  String get deviceAdminIdle =>
      'Consente a Spegni schermo di spegnere davvero lo schermo invece di limitarsi a oscurarlo.';

  @override
  String get deviceFilesIdle =>
      'Consente a Gestione file di esplorare la memoria condivisa e non solo la cartella dell\'app.';

  @override
  String get deviceUsageIdle =>
      'Consente al sensore dell\'app in primo piano di indicare anche app diverse da Kiosk Satellite.';

  @override
  String get deviceLocationMissing =>
      'Senza Posizione, Android non fornisce i risultati della scansione Bluetooth e i sensori di posizione non possono leggere il ricevitore GPS.';

  @override
  String get deviceLocationIdle =>
      'Usata dalle pagine che chiedono la tua posizione, dalla scansione Bluetooth e dai sensori di posizione ESPHome.';

  @override
  String get deviceServiceOverlayMissing =>
      'Senza questa autorizzazione il servizio non può riavviare il kiosk dopo un arresto anomalo o una chiusura dalla schermata delle app recenti.';

  @override
  String get deviceServiceOverlayIdle =>
      'Necessaria per riavviare il kiosk dopo un arresto anomalo.';

  @override
  String get deviceListeningMissing =>
      'L\'ascolto in background è attivo, ma niente è in ascolto.';

  @override
  String get deviceListeningIdle => 'Necessaria per l\'ascolto in background.';

  @override
  String get deviceMotionIdle => 'Necessaria per il rilevamento del movimento.';

  @override
  String get deviceBatteryAdb =>
      'Questo dispositivo non ha una schermata delle impostazioni per questa autorizzazione. Concedila tramite adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      'Questo dispositivo non ha una schermata delle impostazioni per questa autorizzazione. Concedila tramite adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get deviceNotificationAccess => 'Accesso alle notifiche';

  @override
  String get deviceNotificationAccessHeld =>
      'In riproduzione può seguire le app che riproducono contenuti su questo dispositivo.';

  @override
  String get deviceNotificationAccessMissing =>
      'Senza questa autorizzazione Android non elenca alcuna sessione multimediale, quindi In riproduzione non può seguire le app che riproducono contenuti su questo dispositivo.';

  @override
  String get deviceNotificationAccessIdle =>
      'Consente a In riproduzione di seguire le app che riproducono contenuti su questo dispositivo.';

  @override
  String get settingRemoteEnabledTitle => 'Amministrazione remota';

  @override
  String get settingRemoteEnabledDescription =>
      'Esegue il server web di amministrazione integrato.';

  @override
  String get settingRemotePortTitle => 'Porta del server';

  @override
  String get settingRemotePortDescription =>
      'Porta dell\'interfaccia di amministrazione remota.';

  @override
  String get settingRemotePasswordTitle => 'Password di amministrazione';

  @override
  String get settingRemotePasswordDescription =>
      'Necessaria per accedere all\'interfaccia remota.';

  @override
  String get settingRemoteFleetDiscoveryTitle => 'Trova altri kiosk';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      'Annuncia questo dispositivo sulla rete ed elenca gli altri kiosk nell\'amministrazione remota, per passare dall\'uno all\'altro.';

  @override
  String get settingRemoteAdminUrlTitle => 'URL di amministrazione';

  @override
  String get settingRemoteAdminUrlDescription =>
      'Indirizzo che gli altri kiosk aprono in Cambia kiosk per raggiungere questo, ad esempio il nome di un reverse proxy. Lascia vuoto per usare il suo indirizzo di rete.';

  @override
  String get deviceAdminUrlInvalid =>
      'Inserisci un indirizzo valido, ad esempio https://kiosk.example.com';

  @override
  String get deviceAdminUrlPath =>
      'Inserisci solo l\'indirizzo, senza percorso. Esempio: https://kiosk.example.com';

  @override
  String get deviceRemotePage => 'Amministrazione remota';

  @override
  String get deviceAdminAddress => 'Indirizzo di amministrazione';

  @override
  String get deviceAdminAddressHelp =>
      'Apri questo indirizzo in un browser sul tuo computer.';

  @override
  String get deviceByName => 'Per nome';

  @override
  String get deviceByNameHelp =>
      'Lo stesso indirizzo tramite nome host, sulle reti che risolvono i nomi .local.';

  @override
  String get deviceByCertificateNameHelp =>
      'Lo stesso indirizzo tramite il nome riportato nel suo certificato.';

  @override
  String get devicePasswordNeeded =>
      'Imposta una password di amministrazione qui sotto per avviare il server.';

  @override
  String get deviceServerStopped => 'Il server non è in esecuzione.';

  @override
  String devicePortError(String port, String error) {
    return 'Impossibile restare in ascolto sulla porta $port: $error';
  }

  @override
  String get settingRemoteTlsTitle => 'Usa HTTPS';

  @override
  String get settingRemoteTlsDescription =>
      'Crittografa l\'amministrazione remota, l\'API e il WebSocket. Il browser potrebbe chiederti di accettare il certificato del dispositivo.';

  @override
  String get settingServiceCpuAwakeTitle =>
      'Mantieni attiva la CPU a schermo spento';

  @override
  String get settingServiceCpuAwakeDescription =>
      'Mantiene un wake lock nei periodi a schermo spento, così connessioni e timer continuano a funzionare puntuali. Consuma batteria se il tablet non è collegato alla corrente.';

  @override
  String get deviceServicePage => 'Servizio Kiosk Satellite';

  @override
  String get deviceKeepingRunning => 'Cosa lo mantiene attivo';

  @override
  String get deviceService => 'Servizio';

  @override
  String get deviceStopped => 'Arrestato';

  @override
  String get deviceStoppedSentence => 'Arrestato.';

  @override
  String get deviceRunning => 'In esecuzione';

  @override
  String get deviceRunningSentence => 'In esecuzione.';

  @override
  String get deviceRunningBackground =>
      'In esecuzione senza l\'esenzione di servizio in primo piano.';

  @override
  String get deviceServiceTypes => 'Tipi di servizio in primo piano';

  @override
  String get deviceServiceTypesHelp =>
      'Ciò che il servizio dichiara ad Android per le funzionalità che mantiene attive.';

  @override
  String get deviceNoneDeclared => 'Nessuno dichiarato.';

  @override
  String get deviceNone => 'nessuno';

  @override
  String get deviceCpuLock => 'Wake lock della CPU';

  @override
  String get deviceCpuOff =>
      'Disattivato: l\'impostazione qui sotto è disattivata.';

  @override
  String get deviceCpuHeld => 'Attivo: lo schermo è spento.';

  @override
  String get deviceCpuReleased => 'Rilasciato mentre lo schermo è acceso.';

  @override
  String get deviceNotHeld => 'Non attivo.';

  @override
  String get deviceHeld => 'Attivo';

  @override
  String get deviceReleased => 'Rilasciato';

  @override
  String get deviceWifiLock => 'Blocco Wi-Fi';

  @override
  String get deviceWifiHeld =>
      'Attivo: il modulo radio non entra in risparmio energetico.';

  @override
  String get deviceWifiHelp =>
      'Impedisce al modulo radio di entrare in risparmio energetico a schermo spento.';

  @override
  String get deviceNotification => 'Notifica';

  @override
  String get deviceNotificationHidden =>
      'Nascosta: le notifiche dell\'app sono disattivate. Il servizio funziona comunque.';

  @override
  String get deviceNotificationShown =>
      'Mostrata nell\'area notifiche mentre il servizio è in esecuzione.';

  @override
  String get deviceHidden => 'Nascosta';

  @override
  String get deviceShown => 'Visibile';

  @override
  String get deviceReasonHa => 'Connessione a Home Assistant';

  @override
  String get deviceReasonHaHelp =>
      'Mantiene aperte la sessione della plancia e la relativa connessione WebSocket a schermo spento.';

  @override
  String get deviceReasonListening => 'Ascolto in background';

  @override
  String get deviceReasonListeningHelp =>
      'Mantiene attivi il motore della parola di attivazione e il relativo microfono anche dietro le altre app.';

  @override
  String get deviceReasonRtsp => 'Audio del microfono RTSP';

  @override
  String get deviceReasonRtspHelp =>
      'Mantiene lo streaming del microfono disponibile per i client RTSP connessi.';

  @override
  String get deviceReasonEspHome => 'Server ESPHome';

  @override
  String get deviceReasonEspHomeHelp =>
      'Mantiene il server API ESPHome in grado di rispondere a Home Assistant.';

  @override
  String get deviceReasonRemote => 'Amministrazione remota';

  @override
  String get deviceReasonRemoteHelp =>
      'Mantiene attivo il server web di amministrazione.';

  @override
  String get deviceReasonProtections => 'Protezioni del kiosk';

  @override
  String get deviceReasonProtectionsHelp =>
      'Riapre il kiosk quando viene chiuso dalla schermata delle app recenti o si arresta in modo anomalo.';

  @override
  String get deviceReasonBluetooth => 'Proxy Bluetooth';

  @override
  String get deviceReasonBluetoothHelp =>
      'Mantiene attiva la scansione Bluetooth quando l\'app non è sullo schermo.';

  @override
  String get deviceReasonLocation => 'Sensori di posizione';

  @override
  String get deviceReasonLocationHelp =>
      'Continua a ricevere le posizioni GPS a schermo spento o quando è in primo piano un\'altra app.';

  @override
  String get deviceReasonPerson => 'Rilevamento delle persone';

  @override
  String get deviceReasonPersonHelp =>
      'Continua a leggere il sensore di persone del dispositivo quando è in primo piano un\'altra app.';

  @override
  String get deviceReasonCameraHelp =>
      'Mantiene utilizzabile la fotocamera dopo lo spegnimento dello schermo, per il rilevamento del movimento e dei volti.';

  @override
  String deviceServiceStopped(String error) {
    return 'Arrestato: $error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return 'In esecuzione da $uptime.';
  }

  @override
  String get settingShizukuInstallUpdatesTitle =>
      'Installa gli aggiornamenti tramite Shizuku';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      'Installa gli aggiornamenti di Kiosk Satellite senza conferma sul dispositivo. Shizuku deve essere in esecuzione e autorizzato.';

  @override
  String get deviceShizukuAccess => 'Accesso Shizuku';

  @override
  String get deviceShizukuCheck => 'Verifica della disponibilità';

  @override
  String get deviceShizukuRoot => 'Connesso con accesso root';

  @override
  String get deviceShizukuShell => 'Connesso con accesso shell';

  @override
  String get deviceShizukuGrant =>
      'Tocca per concedere l\'accesso. Approva la richiesta su questo kiosk.';

  @override
  String get deviceShizukuGrantRemote =>
      'Concedi l\'accesso e approva la richiesta su questo kiosk.';

  @override
  String get deviceShizukuDenied =>
      'Autorizza Kiosk Satellite nell\'app Shizuku.';

  @override
  String get deviceShizukuUnsupported =>
      'È richiesto Shizuku 13 o versione successiva.';

  @override
  String get deviceShizukuStart => 'Avvia Shizuku su questo dispositivo.';

  @override
  String get deviceShizukuTest => 'Prova connessione';

  @override
  String get deviceShizukuTestHelp =>
      'Legge l\'identità del processo senza modificare il dispositivo.';

  @override
  String get deviceShizukuTestTitle => 'Prova di connessione';

  @override
  String get deviceShizukuTestFailed =>
      'Shizuku non è riuscito a completare la prova di connessione.';

  @override
  String get deviceShizukuAlreadyGranted =>
      'Tutte le autorizzazioni sono già concesse.';

  @override
  String get deviceShizukuConfirmed =>
      'Android ha confermato le autorizzazioni richieste.';

  @override
  String get deviceShizukuResults => 'Risultati delle autorizzazioni';

  @override
  String get deviceShizukuGrantAll => 'Concedi tutte le autorizzazioni';

  @override
  String get deviceShizukuGrantAllHelp =>
      'Concede tutte le autorizzazioni usate da KS, comprese quelle delle funzionalità attualmente disattivate.';

  @override
  String get deviceShizukuSetup => 'Configura Shizuku';

  @override
  String get deviceShizukuSetupHelp =>
      'Leggi le istruzioni di installazione e avvio.';

  @override
  String get deviceShizukuLifetime =>
      'Se avviato tramite ADB, Shizuku va avviato di nuovo dopo ogni riavvio del dispositivo. L\'accesso shell non fornisce autorizzazioni root.';

  @override
  String get deviceShizukuFailed => 'Richiesta Shizuku non riuscita';

  @override
  String get deviceShizukuApprove => 'Approva la richiesta sul kiosk.';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku ha eseguito correttamente un comando con accesso $access.';
  }

  @override
  String get shizukuPermissionUnconfirmed =>
      'Android non ha confermato questa autorizzazione. Controlla Gestione autorizzazioni sul dispositivo.';

  @override
  String get shizukuPermissionReadFailed =>
      'Impossibile leggere le autorizzazioni attuali. Riprova.';

  @override
  String get shizukuRestartTimedOut =>
      'Tempo scaduto per il comando di riavvio';

  @override
  String get shizukuRestartRefused => 'Android ha rifiutato il riavvio';

  @override
  String get shizukuCommandTimedOut => 'Tempo scaduto per il comando';

  @override
  String get shizukuRequestRejected => 'Android ha rifiutato la richiesta';

  @override
  String get deviceDisconnectedError => 'Dispositivo disconnesso';

  @override
  String get deviceResponseTimedOut =>
      'Tempo scaduto per la risposta del dispositivo';

  @override
  String get deviceRequestAborted => 'Richiesta interrotta';

  @override
  String get shizukuActionBusy =>
      'Un\'azione Shizuku è già in esecuzione sul dispositivo';

  @override
  String get shizukuGrantFirst => 'Concedi prima l\'accesso a Shizuku';

  @override
  String get shizukuNoResponse => 'Il comando Shizuku non ha risposto';

  @override
  String get shizukuCommandFailed => 'Comando Shizuku non riuscito';

  @override
  String get shizukuStartRequired =>
      'Avvia Shizuku 13 o versione successiva e autorizza Kiosk Satellite in Shizuku';

  @override
  String get shizukuConnectionFailed => 'Connessione a Shizuku non riuscita';

  @override
  String get shizukuHelperNotConnected =>
      'L\'assistente Shizuku non si è connesso';

  @override
  String get shizukuHelperUnavailable =>
      'L\'assistente Shizuku non è disponibile';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates =>
      'Crittografia della connessione e certificati';

  @override
  String get tlsCertificateType => 'Tipo di certificato';

  @override
  String get tlsImported => 'Importato';

  @override
  String get tlsSelfSigned => 'Autofirmato';

  @override
  String get tlsExpires => 'Scadenza';

  @override
  String get tlsSHA256Fingerprint => 'Impronta SHA-256';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      'Certificato scaduto. Rinnovalo o importane uno sostitutivo.';

  @override
  String get tlsCopyPublicCertificate => 'Copia certificato pubblico';

  @override
  String get tlsDownloadPublicCertificate => 'Scarica certificato pubblico';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      'Usa questo certificato nei browser e nei client di streaming.';

  @override
  String get tlsRenewCertificate => 'Rinnova certificato';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      'Mantiene la chiave privata attuale e aggiorna le date del certificato.';

  @override
  String get tlsImportCertificate => 'Importa certificato';

  @override
  String get tlsUseACertificateIssuedForThisDevice =>
      'Usa un certificato emesso per questo dispositivo.';

  @override
  String get tlsReplaceCertificate => 'Sostituisci certificato';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      'Genera una nuova chiave privata e un certificato autofirmato.';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      'Generare una nuova chiave privata e un nuovo certificato? Le connessioni crittografate attive verranno chiuse. I browser potrebbero chiederti di accettare il nuovo certificato.';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      'Incolla la catena di certificati PEM e la relativa chiave privata non crittografata. Vengono convalidate prima di sostituire il certificato attuale.';

  @override
  String get tlsCertificateChainPEM => 'Catena di certificati (PEM)';

  @override
  String get tlsPrivateKeyPEM => 'Chiave privata (PEM)';

  @override
  String get tlsThisFieldIsRequired => 'Questo campo è obbligatorio.';

  @override
  String get tlsReplace => 'Sostituisci';

  @override
  String get tlsRenew => 'Rinnova';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      'Abilita HTTPS prima di importare una chiave privata da remoto.';

  @override
  String get tlsCertificateOperationFailed =>
      'Operazione sul certificato non riuscita.';

  @override
  String get tlsChangeConnectionProtocol => 'Cambia protocollo di connessione';

  @override
  String get tlsConnectionProtocolHelp =>
      'La connessione remota attuale verrà chiusa. Riconnettiti usando l\'indirizzo qui sotto. Potrebbe essere necessario accedere di nuovo.';

  @override
  String get tlsConfirm => 'Conferma';

  @override
  String get tlsCertificateManagement => 'Gestione certificati';

  @override
  String get tlsServerCertificateRequired =>
      'Usa un certificato del server, non un certificato CA.';

  @override
  String get tlsServerAuthenticationRequired =>
      'Il certificato non consente l\'autenticazione del server.';

  @override
  String get tlsKeyAlgorithmRequired => 'Usa una chiave privata EC o RSA.';

  @override
  String get tlsKeyMismatch =>
      'Il certificato e la chiave privata non corrispondono.';

  @override
  String get tlsMaterialTooLarge =>
      'Il certificato o la chiave sono troppo grandi.';

  @override
  String get tlsPemCertificatesRequired => 'Erano previsti certificati PEM.';

  @override
  String get tlsCertificateMissing => 'Nessun certificato trovato.';

  @override
  String get tlsUnencryptedKeyRequired =>
      'Usa una chiave privata PEM non crittografata.';

  @override
  String get tlsHostnameRequired =>
      'È richiesto un nome host o un indirizzo IP.';

  @override
  String get tlsIssuerRenewalRequired =>
      'Importa un certificato rinnovato dal suo emittente.';

  @override
  String get tlsStoredIdentityDamaged =>
      'L\'identità TLS memorizzata è danneggiata.';

  @override
  String get tlsExpiredCertificate =>
      'Il certificato TLS è scaduto. Rinnovalo o importa quello sostitutivo.';

  @override
  String get deviceHelperPage => 'Assistente aggiornamenti facoltativo';

  @override
  String get deviceHelperStatus => 'Stato dell\'assistente';

  @override
  String get deviceHelperError =>
      'Impossibile verificare l\'assistente aggiornamenti.';

  @override
  String get deviceHelperUnneeded =>
      'Android ora può installare gli aggiornamenti in modo silenzioso. L\'assistente non è necessario.';

  @override
  String get deviceHelperIntro =>
      'Al momento questo dispositivo richiede una conferma sullo schermo per installare gli aggiornamenti tramite Android. L\'assistente facoltativo consente a Kiosk Satellite di installare gli aggiornamenti senza alcun tocco.';

  @override
  String get deviceHelperBusy => 'Installazione di un aggiornamento in corso.';

  @override
  String get deviceHelperReady =>
      'Pronto. Gli aggiornamenti si installano senza conferma.';

  @override
  String get deviceHelperUnavailable =>
      'Non disponibile. Avvia l\'assistente tramite ADB per abilitare gli aggiornamenti senza conferma.';

  @override
  String get deviceHelperLifetime =>
      'L\'assistente resta attivo dopo i riavvii e gli aggiornamenti dell\'app, ma si arresta al riavvio del dispositivo. Esegui il comando da un computer con ADB per avviarlo di nuovo. Dopodiché puoi scollegare il computer.';

  @override
  String get deviceHelperStart => 'Avvia tramite ADB';

  @override
  String get deviceHelperGuide => 'Guida alla configurazione';

  @override
  String get deviceHelperGuideHelp =>
      'Leggi le istruzioni e i requisiti dell\'assistente aggiornamenti.';

  @override
  String get settingUpdateSourceTitle => 'Origine degli aggiornamenti';

  @override
  String get settingUpdateSourceDescription =>
      'Dove l\'app cerca le nuove versioni.';

  @override
  String get settingUpdateSourceUrlTitle => 'URL del repository';

  @override
  String get settingUpdateSourceUrlDescription =>
      'Una cartella su un server web raggiungibile dal kiosk, che contiene releases.json e gli APK delle versioni.';

  @override
  String get deviceUpdatesPage => 'Aggiornamenti';

  @override
  String get deviceUpdateGithub => 'Repository GitHub';

  @override
  String get deviceUpdateCustom => 'Repository personalizzato';

  @override
  String get deviceUpdateGuide => 'Guida al repository personalizzato';

  @override
  String get deviceUpdateGuideHelp =>
      'Come ospitare il file delle versioni e gli APK sulla tua rete.';

  @override
  String get deviceInstallFile => 'Installa da file';

  @override
  String get deviceInstallFileHelp =>
      'Carica un APK di Kiosk Satellite da un computer tramite l\'amministrazione remota, in questa stessa pagina. Per un kiosk che non riesce a raggiungere GitHub o un repository personalizzato.';

  @override
  String get deviceInstallFileRemoteHelp =>
      'Carica un APK di Kiosk Satellite da questo computer e installalo. Per un kiosk che non riesce a raggiungere GitHub o un repository personalizzato.';

  @override
  String get deviceUploadedApk => 'APK caricato';

  @override
  String get deviceInstalling => 'Installazione…';

  @override
  String get deviceDeviceNoAnswer => 'Il dispositivo non ha risposto.';

  @override
  String get deviceInstallFailed =>
      'Aggiornamento non riuscito. Controlla i registri del dispositivo.';

  @override
  String get deviceConfirmTablet => 'Conferma sullo schermo del tablet';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return 'La versione $version (build $build, $size MB) è sul dispositivo, in attesa di installazione.';
  }

  @override
  String deviceInstallVersion(String version) {
    return 'Installa la versione $version';
  }

  @override
  String deviceHttpError(String code) {
    return 'Il dispositivo ha risposto HTTP $code.';
  }

  @override
  String get deviceUploadFailed => 'Caricamento non riuscito.';

  @override
  String get deviceInstallFleet => 'Installa sulla flotta';

  @override
  String get deviceSendingFleet => 'Invio alla flotta…';

  @override
  String get deviceSameBuild => 'Il kiosk esegue già questa build.';

  @override
  String get deviceInstallConfirmation =>
      'L\'installazione va confermata sullo schermo del tablet, a meno che il kiosk non installi in modo silenzioso.';

  @override
  String get deviceSelfLast => 'Questo kiosk viene aggiornato per ultimo.';

  @override
  String get deviceUpdatingFleet => 'Aggiornamento della flotta';

  @override
  String deviceUploading(String percent) {
    return 'Caricamento… $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return 'L\'APK caricato è la versione $version (build $build, $size MB).';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'Il kiosk esegue la versione $version (build $build).';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return 'Invio a $name… $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return 'Installazione su $name…';
  }

  @override
  String deviceInstallingNames(String names) {
    return 'Installazione in corso su $names.';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      'Inserisci l\'URL della cartella, ad esempio http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      'Inserisci solo l\'URL della cartella, senza nulla dopo il percorso. Esempio: http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy =>
      'È in corso un download. Attendi che finisca.';

  @override
  String get updateInstallBusy =>
      'È in corso un\'installazione. Attendi che finisca.';

  @override
  String get updateNoAvailable => 'Nessun aggiornamento disponibile.';

  @override
  String get updateNoUploaded => 'Nessun APK caricato in attesa.';

  @override
  String get updateUploadEmpty => 'Il file caricato era vuoto.';

  @override
  String get updateInvalidApk => 'Il file non è un APK Android.';

  @override
  String get updateUploadedGone =>
      'L\'APK caricato non è più disponibile. Caricalo di nuovo.';

  @override
  String get updateShizukuInstallerFailed =>
      'Shizuku non è riuscito a installare l\'aggiornamento. Non è stato aperto alcun programma di installazione con conferma.';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return 'Spazio libero insufficiente: l\'APK occupa $size MB e l\'installazione richiede circa $required MB, ma il dispositivo ha $free MB liberi.';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return 'Il caricamento si è interrotto dopo $size MB: $error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return 'Il caricamento è terminato in anticipo: sono arrivati $received MB su $expected.';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return 'L\'APK è $package, non Kiosk Satellite ($expected).';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'L\'APK è la versione $version (build $build), precedente alla versione in esecuzione $currentVersion (build $currentBuild). Il downgrade non è consentito: neanche Android lo installerebbe.';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return 'Download non riuscito (HTTP $status).';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return 'Il download si è bloccato: nessun dato ricevuto per $seconds secondi.';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return 'Aggiornamento non riuscito: $error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return 'Installazione non riuscita: $error';
  }

  @override
  String get updateAnotherPackage => 'un altro pacchetto';

  @override
  String get deviceKioskSatelliteUpdates => 'Aggiornamenti di Kiosk Satellite';

  @override
  String get deviceAndroidSystemUpdates => 'Aggiornamenti di sistema Android';

  @override
  String get settingAndroidUpdatePolicyTitle =>
      'Installa gli aggiornamenti Android';

  @override
  String get settingAndroidUpdatePolicyDescription =>
      'Aggiornamenti di Android stesso forniti dal produttore del dispositivo, come Google o Samsung. La modalità kiosk nasconde la richiesta di riavviare per installarli.';

  @override
  String get deviceAndroidUpdateAsk => 'Chiedi sul dispositivo';

  @override
  String get deviceAndroidUpdateAutomatic => 'Subito';

  @override
  String get deviceAndroidUpdateWindowed => 'In una fascia oraria';

  @override
  String get settingAndroidUpdateWindowStartTitle => 'Installa dalle';

  @override
  String get settingAndroidUpdateWindowStartDescription =>
      'Ora locale di inizio della fascia giornaliera per installare e riavviare.';

  @override
  String get settingAndroidUpdateWindowEndTitle => 'Installa fino alle';

  @override
  String get settingAndroidUpdateWindowEndDescription =>
      'Ora locale di fine della fascia. Una fascia che supera la mezzanotte termina il giorno dopo.';

  @override
  String get settingUiLanguageTitle => 'Lingua';

  @override
  String get settingUiLanguageDescription =>
      'Lingua di Kiosk Satellite e dell\'amministrazione remota. Home Assistant mantiene la propria lingua.';

  @override
  String get settingUiThemeTitle => 'Tema dell\'app';

  @override
  String get settingUiThemeDescription =>
      'Chiaro o scuro per le schermate dell\'app: menu, impostazioni, finestre di dialogo. Sistema segue l\'impostazione di Android.';

  @override
  String get settingUiScaleTitle => 'Scala dell\'interfaccia';

  @override
  String get settingUiScaleDescription =>
      'Dimensione delle schermate dell\'app: menu, impostazioni, finestre di dialogo. Per schermi ad alta densità. I contenuti web mantengono la loro dimensione.';

  @override
  String get deviceUserInterface => 'Interfaccia utente';

  @override
  String get deviceThemeDark => 'Scuro';

  @override
  String get deviceThemeLight => 'Chiaro';

  @override
  String get deviceThemeSystem => 'Sistema';

  @override
  String get settingUiToastsHiddenTitle =>
      'Mostra i messaggi a comparsa di sistema';

  @override
  String get settingUiToastsHiddenDescription =>
      'Scegli i messaggi a comparsa mostrati sopra la plancia. I messaggi nelle Impostazioni vengono sempre mostrati.';

  @override
  String get deviceToastsAll => 'Tutti';

  @override
  String get deviceToastsNone => 'Nessuno';

  @override
  String get deviceToastBack => 'Suggerimenti del tasto Indietro';

  @override
  String get deviceToastGestures => 'Azioni dei gesti';

  @override
  String get deviceToastHoldMode => 'Modalità pausa';

  @override
  String get deviceToastLinks => 'Link della plancia';

  @override
  String get deviceToastDownloads => 'Download';

  @override
  String get deviceToastNetwork => 'Stato della rete';

  @override
  String get deviceToastUpdates => 'Controllo aggiornamenti';

  @override
  String get deviceToastVoice => 'Avvisi di Voice Satellite';

  @override
  String get deviceToastTimers => 'Timer';

  @override
  String get deviceToastAlarms => 'Sveglie';

  @override
  String get deviceToastMusicLibrary => 'Libreria musicale';

  @override
  String get deviceToastIntercom => 'Interfono';

  @override
  String get deviceToastAppLauncher => 'Launcher app';

  @override
  String get deviceToastPlugins => 'Azioni dei plugin';

  @override
  String get settingUiDrawerItemsTitle => 'Voci del menu del kiosk';

  @override
  String get settingUiDrawerItemsDescription =>
      'Scegli le voci mostrate nel menu del kiosk e il loro ordine.';

  @override
  String get settingShowInKioskMenuTitle => 'Mostra nel menu del kiosk';

  @override
  String get settingDlnaEnabledTitle => 'Abilita il ricevitore DLNA';

  @override
  String get settingDlnaEnabledDescription =>
      'Mostra immagini e riproduce contenuti inviati da Home Assistant o da qualsiasi app DLNA. Il dispositivo compare come lettore multimediale con il nome del dispositivo.';

  @override
  String get settingDlnaAudioBackgroundTitle =>
      'Mantieni l\'audio in background';

  @override
  String get settingDlnaAudioBackgroundDescription =>
      'L\'audio ricevuto viene riprodotto senza occupare lo schermo.';

  @override
  String get settingDlnaPortTitle => 'Porta del server';

  @override
  String get settingDlnaPortDescription =>
      'La porta usata dal ricevitore, compilata al suo avvio. Modificala per spostare il ricevitore, oppure cancellala per fargliene scegliere un\'altra.';

  @override
  String get settingDlnaPortPlaceholder =>
      'Impostata all\'avvio del ricevitore';

  @override
  String get settingEsphomeRealMacTitle => 'Usa l\'indirizzo MAC Wi-Fi reale';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant collega questo kiosk allo stesso dispositivo già rilevato dalle tue integrazioni di rete. Modificare questa opzione crea un nuovo dispositivo ESPHome in Home Assistant.';

  @override
  String get settingEsphomeMacOverrideTitle =>
      'Indirizzo MAC Wi-Fi personalizzato';

  @override
  String get settingEsphomeMacOverrideDescription =>
      'Poiché non è possibile ricavare l\'indirizzo MAC, puoi inserirne uno tuo in questo campo. Modificarlo crea un nuovo dispositivo ESPHome in Home Assistant.';

  @override
  String get esphomeAdvanced => 'Impostazioni avanzate';

  @override
  String get esphomeAdvancedHelp =>
      'Indirizzo MAC Wi-Fi reale o personalizzato';

  @override
  String get esphomeMacInvalid => 'Inserisci un indirizzo MAC valido.';

  @override
  String esphomeMacHardware(String mac) {
    return 'Indirizzo comunicato: $mac.';
  }

  @override
  String esphomeMacManual(String mac) {
    return 'Indirizzo comunicato: $mac, inserito qui sotto.';
  }

  @override
  String get esphomeMacUnavailable =>
      'Android non rivela l\'indirizzo hardware di questo dispositivo.';

  @override
  String get settingAnnouncementsEnabledTitle => 'Abilita gli annunci';

  @override
  String get settingAnnouncementsEnabledDescription =>
      'Riproduce gli annunci che Home Assistant invia con l\'azione announce.';

  @override
  String get esphomeTtsSection => 'Sintesi vocale';

  @override
  String get settingAnnouncementsTtsEngineTitle => 'Motore di sintesi vocale';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'L\'entità di sintesi vocale di Home Assistant che pronuncia gli annunci.';

  @override
  String get settingAnnouncementsTtsLanguageTitle => 'Lingua';

  @override
  String get settingAnnouncementsTtsLanguageDescription =>
      'La lingua in cui vengono pronunciati gli annunci.';

  @override
  String get settingAnnouncementsTtsVoiceTitle => 'Voce';

  @override
  String get settingAnnouncementsTtsVoiceDescription =>
      'La voce che pronuncia gli annunci.';

  @override
  String get esphomeTtsFirst => 'Primo disponibile';

  @override
  String get esphomeTtsDefault => 'Predefinita';

  @override
  String get settingAnnouncementsChimeTitle =>
      'Segnale acustico prima dell\'annuncio';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Riproduce un segnale acustico prima dell\'annuncio.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Suono del segnale acustico';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Viene riprodotto allo stesso volume dell\'annuncio.';

  @override
  String get esphomeAnnouncements => 'Annunci';

  @override
  String get esphomeAnnouncementsHelp => 'Annunci vocali da Home Assistant';

  @override
  String get esphomeChime => 'Segnale acustico';

  @override
  String get esphomeTtsUnavailable => 'Impossibile raggiungere Home Assistant';

  @override
  String get esphomeTtsNoVoices => 'Nessuna voce da scegliere';

  @override
  String get settingBtproxyEnabledTitle => 'Abilita il proxy Bluetooth';

  @override
  String get settingBtproxyEnabledDescription =>
      'Inoltra a Home Assistant i dispositivi Bluetooth nelle vicinanze.';

  @override
  String get settingBtproxyScanDutyTitle => 'Intensità della scansione';

  @override
  String get settingBtproxyScanDutyDescription =>
      'Per quanto tempo la radio resta in ascolto. Un valore più basso riduce l\'uso della CPU; i dispositivi che trasmettono di rado impiegano più tempo a comparire.';

  @override
  String get settingBtproxyScreenOffScanTitle =>
      'Continua la scansione a schermo spento';

  @override
  String get settingBtproxyScreenOffScanDescription =>
      'Attiva questa opzione se il proxy smette di inoltrare quando lo schermo è spento. Usa più CPU.';

  @override
  String get settingBtproxyDeviceMacTitle =>
      'Usa l\'indirizzo MAC del dispositivo per il Bluetooth';

  @override
  String get settingBtproxyDeviceMacDescription =>
      'Consente a integrazioni come Bermuda di collegare questo proxy al suo dispositivo. Cambia l\'indirizzo del proxy in Home Assistant.';

  @override
  String get settingBtproxyConnectionsTitle =>
      'Consenti le connessioni ai dispositivi';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant può connettersi ai dispositivi Bluetooth tramite questo proxy.';

  @override
  String get settingBtproxyMacLookupTitle =>
      'Cerca online i produttori dei dispositivi';

  @override
  String get settingBtproxyMacLookupDescription =>
      'Assegna un nome ai dispositivi sconosciuti nelle vicinanze in base al prefisso del loro indirizzo hardware, tramite api.macvendors.com. Viene inviato solo il prefisso di 3 byte del produttore, una volta per produttore; nient\'altro esce dal dispositivo.';

  @override
  String get settingBtproxyNearbySortTitle => 'Ordina per';

  @override
  String get settingBtproxyNearbySortDescription =>
      'L\'ordine dell\'elenco dei dispositivi nelle vicinanze qui sotto.';

  @override
  String get settingBtproxyMinConnectRssiTitle =>
      'Segnale minimo per le connessioni';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      'Rifiuta le connessioni ai dispositivi ricevuti con un segnale più debole di questo valore, così se ne occupa un proxy più vicino.';

  @override
  String get esphomeOptionContinuous => 'Continua';

  @override
  String get esphomeOptionBalanced => 'Bilanciata';

  @override
  String get esphomeOptionLowPower => 'Basso consumo';

  @override
  String get esphomeOptionLastSeen => 'Ultimo rilevamento';

  @override
  String get esphomeOptionName => 'Nome';

  @override
  String get esphomeOptionMacAddress => 'Indirizzo MAC';

  @override
  String get esphomeOptionSignalStrength => 'Intensità del segnale';

  @override
  String get esphomeOptionNoLimit => 'Nessun limite';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm (stessa stanza)';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm (limite della portata)';

  @override
  String get esphomeBluetooth => 'Proxy Bluetooth';

  @override
  String get esphomeBluetoothHelp =>
      'Inoltra a Home Assistant i dispositivi Bluetooth nelle vicinanze';

  @override
  String get esphomeBluetoothOff =>
      'Il Bluetooth è disattivato. Attivalo per usare il proxy.';

  @override
  String get esphomeBluetoothUnsupported =>
      'Non disponibile su questo dispositivo: non ha il Bluetooth.';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      'Non disponibile su questo dispositivo: la sua build di Android non supporta il Bluetooth LE.';

  @override
  String get esphomeIdentityBthome => 'Sensore BTHome';

  @override
  String get esphomeIdentityXiaomi => 'Sensore Xiaomi';

  @override
  String get esphomeIdentityQingping => 'Sensore Qingping';

  @override
  String get esphomeIdentityGoogleNest => 'Dispositivo Google/Nest';

  @override
  String get esphomeIdentityEddystone => 'Beacon Eddystone';

  @override
  String get esphomeIdentityGoogleFastPair => 'Dispositivo Google Fast Pair';

  @override
  String get esphomeIdentityAppleFindMy => 'Dispositivo Apple Dov\'è';

  @override
  String get esphomeIdentityExposure => 'Notifica di esposizione (telefono)';

  @override
  String get esphomeIdentityAugustYale => 'Serratura August/Yale';

  @override
  String get esphomeIdentityAmazon => 'Dispositivo Amazon';

  @override
  String get esphomeIdentityTile => 'Localizzatore Tile';

  @override
  String get esphomeIdentityInput =>
      'Dispositivo di input (telecomando/tastiera)';

  @override
  String get esphomeIdentityHeartRate => 'Sensore di frequenza cardiaca';

  @override
  String get esphomeIdentityEnvironmental => 'Sensore ambientale';

  @override
  String get esphomeIdentityApple => 'Dispositivo Apple';

  @override
  String get esphomeIdentityWindows => 'PC Windows';

  @override
  String get esphomeIdentitySamsung => 'Dispositivo Samsung';

  @override
  String get esphomeIdentityGoogle => 'Dispositivo Google';

  @override
  String get esphomeIdentityUnknown => 'Dispositivo sconosciuto';

  @override
  String esphomeIdentityVendor(String vendor) {
    return 'Dispositivo $vendor';
  }

  @override
  String get esphomeNearby => 'Dispositivi nelle vicinanze';

  @override
  String get esphomeNearbySearch =>
      'I dispositivi Bluetooth rilevati da questo kiosk, con il nome quando è noto.';

  @override
  String get esphomeNearbyEmpty => 'Ancora nessun dispositivo rilevato.';

  @override
  String get esphomeNearbyWaiting =>
      'Ancora nessun dispositivo rilevato. I dispositivi compaiono qui quando il proxy inizia la scansione.';

  @override
  String get esphomeRotating => '(indirizzo variabile)';

  @override
  String esphomeNearbyCount(String count, String total) {
    return 'Mostrati i primi $count di $total.';
  }

  @override
  String esphomeSlots(String count) {
    return 'Tramite questo proxy si possono connettere fino a $count dispositivi contemporaneamente. Home Assistant instrada gli altri dispositivi tramite altri proxy.';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return '$count s fa';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return '$count min fa';
  }

  @override
  String esphomeHoursAgo(String count) {
    return '$count h fa';
  }

  @override
  String get settingLocationEnabledTitle => 'Comunica la posizione';

  @override
  String get settingLocationEnabledDescription =>
      'Legge la posizione GPS e la fornisce a Home Assistant come sensori di latitudine, longitudine, precisione, altitudine e velocità. Attivare o disattivare questa opzione registra di nuovo il dispositivo ESPHome.';

  @override
  String get settingLocationIntervalTitle => 'Intervallo di aggiornamento';

  @override
  String get settingLocationIntervalDescription =>
      'Secondi tra una lettura della posizione e la successiva.';

  @override
  String get esphomeGps => 'Sensore GPS';

  @override
  String get esphomeGpsHelp => 'Espone a Home Assistant i dati del sensore GPS';

  @override
  String get esphomeLocationOff => 'Disattivato.';

  @override
  String get esphomeLocationWaiting =>
      'In attesa del primo rilevamento della posizione. Un avvio a freddo a cielo aperto può richiedere alcuni minuti.';

  @override
  String get esphomeCoordinates => 'Ultime coordinate';

  @override
  String get esphomeLocationDenied =>
      'Autorizzazione alla posizione non concessa.';

  @override
  String get esphomeLocationAbsent => 'Nessun ricevitore GPS.';

  @override
  String esphomeLocationError(String error) {
    return 'GPS non disponibile: $error';
  }

  @override
  String get esphomeLocationUnsupported =>
      'Non disponibile su questo dispositivo: non ha un ricevitore GPS.';

  @override
  String get settingNotificationsTransparencyTitle => 'Trasparenza';

  @override
  String get settingNotificationsTransparencyDescription =>
      'Lascia intravedere lo schermo sottostante attraverso le schede delle notifiche. Testo e icone restano opachi.';

  @override
  String get settingNotificationsBlurTitle => 'Sfocatura dello sfondo';

  @override
  String get settingNotificationsBlurDescription =>
      'Sfoca ciò che si vede attraverso una scheda di notifica trasparente. Nota: la sfocatura non può essere applicata sopra la superficie della plancia di Home Assistant.';

  @override
  String get settingNotificationsChimeFileTitle => 'Suono di notifica';

  @override
  String get settingNotificationsChimeFileDescription =>
      'I file audio vengono letti da Android/data/me.jxl.kiosk_satellite/files/sounds sul dispositivo, cartella raggiungibile anche da Gestione file.';

  @override
  String get settingNotificationsVolumeTitle => 'Volume delle notifiche';

  @override
  String get settingNotificationsVolumeDescription =>
      'Il volume del suono di notifica, separato dal volume dei contenuti multimediali e da quello dell\'assistente.';

  @override
  String get esphomeNotifications => 'Notifiche';

  @override
  String get esphomeNotificationsHelp =>
      'Trasparenza, sfocatura, suono di notifica, notifica di prova';

  @override
  String get esphomeAppearance => 'Aspetto';

  @override
  String get esphomeSound => 'Suono';

  @override
  String get esphomeNotificationTest => 'Notifica di prova';

  @override
  String esphomeNotificationHelp(String action) {
    return 'Le notifiche vengono inviate da Home Assistant con l\'azione $action. Prova ne mostra una sopra la plancia.';
  }

  @override
  String get esphomeNotificationBody =>
      'Ecco come appare e come suona una notifica di Home Assistant.';

  @override
  String get esphomeNotificationSearch =>
      'L\'azione di Home Assistant che invia le notifiche e un pulsante per mostrarne una.';

  @override
  String get esphomeLocation => 'Posizione';

  @override
  String get esphomeLocationSearch =>
      'L\'autorizzazione Posizione necessaria ai sensori di posizione.';

  @override
  String get esphomeBluetoothSearch =>
      'L\'autorizzazione Dispositivi nelle vicinanze necessaria al proxy Bluetooth per la scansione.';

  @override
  String get esphomeLocationMissing =>
      'Senza questa autorizzazione il ricevitore GPS non può essere letto e i sensori di posizione restano sconosciuti.';

  @override
  String get esphomeLocationServicesOff =>
      'La posizione è disattivata nelle impostazioni del dispositivo, quindi il ricevitore non fornisce nulla.';

  @override
  String get esphomeLocationApproximate =>
      'È consentita solo la posizione approssimativa, ma il ricevitore GPS richiede la posizione precisa.';

  @override
  String get esphomeLocationGranted =>
      'I sensori di posizione possono leggere il ricevitore GPS.';

  @override
  String get esphomeBluetoothGranted =>
      'Il proxy può cercare i dispositivi Bluetooth nelle vicinanze.';

  @override
  String get esphomeBluetoothMissing =>
      'Senza questa autorizzazione il proxy non può cercare dispositivi.';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android fornisce i risultati della scansione Bluetooth, beacon inclusi, solo se l\'autorizzazione Posizione è concessa. Il proxy non legge mai la posizione del dispositivo.';

  @override
  String get esphomeBluetoothLocationOff =>
      'La posizione è disattivata nelle impostazioni del dispositivo, quindi la scansione Bluetooth non trova nulla.';

  @override
  String get esphomeBluetoothBeacons =>
      'La scansione Bluetooth può rilevare i beacon.';

  @override
  String get esphomeSent => 'Inviato';

  @override
  String get esphomeNotsaved => 'Non salvato';

  @override
  String get settingEsphomeEnabledTitle => 'Abilita ESPHome';

  @override
  String get settingEsphomeEnabledDescription =>
      'Presenta questo kiosk a Home Assistant come dispositivo ESPHome, con i suoi sensori e controlli come entità native. Viene rilevato automaticamente.';

  @override
  String get settingEsphomeEntitiesTitle => 'Esponi le entità del kiosk';

  @override
  String get settingEsphomeEntitiesDescription =>
      'Espone i sensori e i controlli di questo dispositivo come entità ESPHome.';

  @override
  String get settingEsphomeExcludedEntitiesTitle => 'Entità escluse';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      'Scegli le entità da escludere da Home Assistant. Tutte le altre entità disponibili vengono esposte. Il salvataggio riconnette ESPHome.';

  @override
  String get settingEsphomeNodeNameTitle => 'Nome del nodo';

  @override
  String get settingEsphomeNodeNameDescription =>
      'Identifica questo kiosk sulla rete, e Home Assistant ne ricava i nomi delle sue azioni. Rinominarlo rinomina anche quelle azioni.';

  @override
  String get settingEsphomeNodeNamePlaceholder => 'Impostato al primo avvio';

  @override
  String get settingBtproxyKeyTitle => 'Chiave di crittografia';

  @override
  String get settingBtproxyKeyDescription =>
      'Incolla questa chiave in Home Assistant quando ti chiede la chiave di crittografia. Viene generata automaticamente al primo avvio.';

  @override
  String get settingBtproxyKeyPlaceholder => 'Generata al primo avvio';

  @override
  String get settingBtproxyPortTitle => 'Porta dell\'API';

  @override
  String get settingBtproxyPortDescription =>
      'La porta a cui si connette Home Assistant. Lascia vuoto per usare la porta standard di ESPHome, 6053.';

  @override
  String esphomeStartFailed(String error) {
    return 'Avvio del server ESPHome non riuscito: $error';
  }

  @override
  String get esphomeExcludedInvalid => 'Scegli un elenco di ID di entità.';

  @override
  String settingsMadeBy(String heart, String author) {
    return 'Fatto con $heart da $author';
  }

  @override
  String get settingsBuyCoffee => 'Offrimi un caffè';

  @override
  String get settingClapStrictnessTitle => 'Rilevamento dei battiti di mani';

  @override
  String get settingClapDetectionDescription =>
      'Rigoroso richiede battiti di mani più forti e regolari. Stanza grande lascia ai battiti il tempo di svanire in una stanza con eco.';

  @override
  String get gestureStrictnessStandard => 'Standard';

  @override
  String get gestureStrictnessStrict => 'Rigoroso';

  @override
  String get gestureStrictnessLargeRoom => 'Stanza grande';

  @override
  String get gestureOff => 'I gesti sono disattivati';

  @override
  String get gestureOffHelp =>
      'Disabilita i gesti è attivo nelle impostazioni della modalità kiosk.';

  @override
  String get gestureEmpty => 'Nessun gesto configurato';

  @override
  String get gestureEmptyHelp =>
      'Un gesto attiva la sua azione senza alcun controllo visibile.';

  @override
  String get gestureDeleteTooltip => 'Elimina gesto';

  @override
  String get gestureDeleteTitle => 'Eliminare il gesto?';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return 'Rimuovere questo gesto? Attivatore: $trigger. Azione: $action.';
  }

  @override
  String get gestureAdd => 'Aggiungi gesto';

  @override
  String get gestureAddHelp => 'Scegli un gesto e l\'azione che attiva.';

  @override
  String get gestureTouchHelp =>
      'I gesti vengono osservati, non bloccati: i tocchi arrivano anche alla plancia, quindi gli angoli e le forme a più dita evitano di attivare lì qualcosa.';

  @override
  String get gestureClapper => 'Comando a battito di mani';

  @override
  String get gestureReadFailed => 'Impossibile leggere le impostazioni.';

  @override
  String get gestureHandGestures => 'Gesti della mano';

  @override
  String get settingHandGestureHoldSecondsTitle => 'Durata del mantenimento';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      'Mantieni lo stesso gesto delle dita per questo tempo prima che venga eseguita la sua azione. Aumentalo per ridurre le attivazioni accidentali.';

  @override
  String get gestureHoldInstant => 'Immediato';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get settingGroundControlEnabledTitle => 'Abilita Ground Control';

  @override
  String get settingGroundControlEnabledDescriptionVisionMatch =>
      'Si connette a Kiosk Satellite Ground Control, che esegue Voice Match e Vision Match su un computer sufficientemente potente.';

  @override
  String get settingGroundControlAddressTitle => 'Indirizzo';

  @override
  String get settingGroundControlAddressDescription =>
      'Lascia vuoto per trovare Ground Control sulla rete. Inseriscine uno se Ground Control è su un\'altra rete.';

  @override
  String get groundControlLooking => 'Ricerca di Ground Control sulla rete.';

  @override
  String get groundControlWaitingApproval => 'In attesa di approvazione';

  @override
  String get groundControlApproveHint =>
      'Approva questo kiosk nella pagina Kiosks dell\'app Ground Control.';

  @override
  String get groundControlDeclined => 'Rifiutato';

  @override
  String get groundControlDeclinedHint =>
      'Questo kiosk è stato rifiutato nell\'app Ground Control. Approvalo nella pagina Kiosks.';

  @override
  String get groundControlNotAccepted => 'Non accettato';

  @override
  String get groundControlUnsignedBuild =>
      'Questa build di Kiosk Satellite non può connettersi a Ground Control.';

  @override
  String get groundControlApp => 'App Ground Control';

  @override
  String get groundControlArchitecture => 'Architettura';

  @override
  String get groundControlRunsOn => 'Eseguito su';

  @override
  String get groundControlFeatures => 'Funzionalità';

  @override
  String get settingGroundControlVoiceMatchTitle => 'Voice Match';

  @override
  String get settingVisionMatchEnabledTitle => 'Vision Match';

  @override
  String get settingVisionMatchEnableTitle => 'Abilita Vision Match';

  @override
  String get settingVisionMatchFaceDetectionTitle =>
      'Abilita il rilevamento dei volti';

  @override
  String get settingVisionMatchHandGesturesTitle =>
      'Abilita i gesti della mano';

  @override
  String get visionMatchFeaturesHint =>
      'Riconoscimento e rilevamento dei volti, gesti della mano e rilevamento della presenza';

  @override
  String get settingVisionMatchEnabledDescriptionGroundControl =>
      'Riconoscimento e rilevamento dei volti, gesti della mano e rilevamento della presenza. Richiede Ground Control.';

  @override
  String get settingVisionMatchFaceDetectionDescriptionGroundControl =>
      'Esegue il rilevamento dei volti su Ground Control. Se disattivato, viene eseguito sul dispositivo.';

  @override
  String get settingVisionMatchHandGesturesDescriptionGroundControl =>
      'Esegue il rilevamento dei gesti del palmo e delle dita su Ground Control. Se disattivato, viene eseguito sul dispositivo.';

  @override
  String get settingVisionMatchFaceRecognitionTitle =>
      'Abilita il riconoscimento facciale';

  @override
  String get settingVisionMatchFaceRecognitionDescriptionGroundControl =>
      'Riconosce chi sta guardando il kiosk e lo mostra nel sensore Face. Richiede il rilevamento dei volti su Ground Control.';

  @override
  String get groundControlFaceRecognition => 'Riconoscimento facciale';

  @override
  String get faceEnrollRowTitle => 'Registra un volto';

  @override
  String get faceEnrollRowDescription =>
      'Scegli una persona, poi segui i passaggi sullo schermo. Richiede circa mezzo minuto.';

  @override
  String get faceEnrollPickTitle => 'Di chi è il volto?';

  @override
  String get faceEnrollNewPerson => 'Nuova persona';

  @override
  String get faceEnrollEnrolled => 'Volto registrato';

  @override
  String get faceEnrollNameLabel => 'Nome';

  @override
  String get faceEnrollStart => 'Inizia';

  @override
  String get settingVisionMatchFaceConfirmsVoiceTitle =>
      'Conferma le voci con i volti';

  @override
  String get settingVisionMatchFaceConfirmsVoiceDescription =>
      'Accetta una voce molto simile quando al kiosk viene riconosciuto il volto della stessa persona. In questo modo può essere riconosciuta solo la persona con l\'impronta vocale più simile.';

  @override
  String get groundControlUsedElsewhere => 'Usato in altre impostazioni';

  @override
  String get settingVisionMatchLinkFaceWhoDescription =>
      'Salvaschermo > Rilevamento dei volti > Ground Control Vision Match';

  @override
  String get groundControlValueOn => 'Attivo';

  @override
  String get groundControlValueOff => 'Non attivo';

  @override
  String groundControlValuePeople(String option, String names) {
    return '$option: $names';
  }

  @override
  String get groundControlTagHint =>
      'Un\'impostazione di Ground Control. Scopri di più';

  @override
  String get groundControlTagTitle => 'Un\'impostazione di Ground Control';

  @override
  String get groundControlTagVision =>
      'Questa impostazione richiede Kiosk Satellite Ground Control. Ground Control è un\'app separata che viene eseguita su un computer di casa tua. L\'impostazione usa il riconoscimento facciale e viene mostrata solo quando il riconoscimento facciale è attivo in Impostazioni > Ground Control > Vision Match.';

  @override
  String get groundControlTagVoice =>
      'Questa impostazione richiede Kiosk Satellite Ground Control. Ground Control è un\'app separata che viene eseguita su un computer di casa tua. L\'impostazione usa Voice Match e viene mostrata solo quando Voice Match è attivo in Impostazioni > Ground Control > Voice Match.';

  @override
  String get settingVisionMatchLinkKioskPinDescription =>
      'Modalità kiosk > Ground Control Vision Match';

  @override
  String get settingVisionMatchLinkLockdownDescription =>
      'Modalità blocco > Ground Control Vision Match';

  @override
  String get groundControlRecognitionCards => 'Schede di riconoscimento';

  @override
  String get settingVisionMatchShowArrivalsTitle => 'Mostra gli arrivi';

  @override
  String get settingVisionMatchShowArrivalsDescription =>
      'Mostra una scheda con la foto e il nome della persona quando qualcuno viene riconosciuto al kiosk. Per la stessa persona ricompare dopo che si è allontanata per un minuto.';

  @override
  String get settingVisionMatchShowActionsTitle =>
      'Mostra le azioni tramite volto';

  @override
  String get settingVisionMatchShowActionsDescription =>
      'Mostra una piccola scheda ogni volta che il PIN viene saltato, la modalità blocco viene disattivata o una voce viene confermata perché è stato riconosciuto un volto.';

  @override
  String get settingVisionMatchCardPositionTitle => 'Posizione delle schede';

  @override
  String get settingVisionMatchCardPositionDescription =>
      'L\'angolo dello schermo in cui compaiono entrambe le schede. Mentre è visibile l\'anteprima della fotocamera, compaiono accanto a essa.';

  @override
  String get recognitionCardPinSkipped => 'PIN saltato';

  @override
  String get recognitionCardLockdownOff => 'Modalità blocco disattivata';

  @override
  String get recognitionCardVoiceConfirmed => 'Voce confermata';

  @override
  String get haCustomPages => 'Pagine personalizzate';

  @override
  String get haCustomPagesHintDashboard =>
      'Le tue pagine HTML personalizzate mostrate come plancia';

  @override
  String get settingHaCustomPagesSocketTitle =>
      'Condividi la connessione a Home Assistant';

  @override
  String get settingHaCustomPagesSocketDescription =>
      'Le pagine personalizzate comunicano con Home Assistant tramite la connessione del kiosk, senza alcun token nella pagina.';

  @override
  String get haCustomPagesAdd => 'Aggiungi pagina';

  @override
  String get haCustomPagesEmptyAnyServer =>
      'Aggiungi pagine HTML dalla cartella www di Home Assistant o da un altro server per sceglierle come una plancia.';

  @override
  String get haCustomPagesGuide => 'Guida alle pagine personalizzate';

  @override
  String get haCustomPagesGuideHint =>
      'Come creare una pagina che comunica con Home Assistant.';

  @override
  String get haCustomPageAddTitle => 'Aggiungi pagina personalizzata';

  @override
  String get haCustomPageEditTitle => 'Modifica pagina personalizzata';

  @override
  String get haCustomPageName => 'Nome';

  @override
  String get haCustomPageLocation => 'Percorso o URL';

  @override
  String get haCustomPageLocationHint =>
      'Un file nella cartella www di Home Assistant, come /local/dashboard.html, oppure l\'URL di una pagina su un altro server.';

  @override
  String get haCustomPageNameMissing => 'Inserisci un nome.';

  @override
  String get haCustomPageLocationInvalid =>
      'Inserisci un percorso sotto /local/ o un\'URL http o https.';

  @override
  String get haCustomPageDuplicate =>
      'Un\'altra pagina usa già questo percorso.';

  @override
  String get haCustomPageNotFound =>
      'Home Assistant non ha alcun file in questo percorso.';

  @override
  String get haCustomPageUrlNotFound =>
      'Il server non ha alcuna pagina a questa URL.';

  @override
  String get haCustomPageUnreachable =>
      'Impossibile raggiungere Home Assistant.';

  @override
  String get haCustomPageUrlUnreachable => 'Impossibile raggiungere il server.';

  @override
  String haCustomPageStatus(String code) {
    return 'Home Assistant ha risposto con HTTP $code.';
  }

  @override
  String haCustomPageUrlStatus(String code) {
    return 'Il server ha risposto con HTTP $code.';
  }

  @override
  String get settingHaHoldModeTitle => 'Modalità pausa';

  @override
  String get settingHaHoldModeDescription =>
      'Mantiene la vista attuale sullo schermo: il salvaschermo, la rotazione delle viste della plancia e il timer di ritorno alla vista iniziale restano in pausa finché non viene disattivata.';

  @override
  String get settingHaHoldReleaseMinutesTitle =>
      'Termina la pausa automaticamente dopo';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      'Disattiva da sola la modalità pausa dopo il tempo impostato. Imposta 0 per mantenerla finché non la disattivi manualmente.';

  @override
  String get haHoldHint =>
      'Blocca la vista attuale, fine automatica, voce di menu';

  @override
  String get haNever => 'Mai';

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
      'Mantieni la connessione in background';

  @override
  String get settingDisableSuspendDescription =>
      'Disattiva l\'impostazione \"Sospendi le connessioni in background\" di Home Assistant, che altrimenti interromperebbe la connessione pochi minuti dopo lo spegnimento dello schermo.';

  @override
  String get settingFreezeOnScreensaverTitle =>
      'Metti in pausa la plancia durante il salvaschermo';

  @override
  String get settingFreezeOnScreensaverDescription =>
      'Smette di disegnare la plancia mentre il salvaschermo la copre, riducendo l\'uso di CPU e GPU; la connessione resta attiva. Non vale per il salvaschermo Attenuato.';

  @override
  String get settingWsFilterTitle => 'Filtra gli aggiornamenti della plancia';

  @override
  String get settingWsFilterDescription =>
      'Elabora solo gli aggiornamenti delle entità della vista attuale, riducendo gli scatti sui tablet poco potenti. Le viste che non è possibile analizzare restano senza filtro.';

  @override
  String get settingPauseDashboardCamerasTitle =>
      'Metti in pausa i flussi delle telecamere della plancia HA durante il salvaschermo';

  @override
  String get settingPauseDashboardCamerasDescription =>
      'Mette in pausa i flussi delle telecamere supportati e senza audio sulla plancia di Home Assistant mentre il salvaschermo la copre. I flussi si riconnettono quando si chiude. Non influisce sulla fotocamera del dispositivo né sulla funzionalità Flussi delle telecamere.';

  @override
  String get haOptimizations => 'Ottimizzazioni';

  @override
  String get haOptimizationsHint =>
      'Connessione in background, pausa della plancia e delle telecamere, filtro degli aggiornamenti';

  @override
  String get haScanUnavailable =>
      'I dettagli dell\'analisi non sono disponibili per la vista attuale.';

  @override
  String get haScanDetails => 'Dettagli dell\'analisi della plancia';

  @override
  String haWatchedTitle(String count) {
    return 'Entità monitorate ($count)';
  }

  @override
  String get haWatched => 'Entità monitorate';

  @override
  String get haEntityListUnavailable =>
      'L\'elenco delle entità non è disponibile al momento.';

  @override
  String haWatching(String count) {
    return '$count entità monitorate in questa vista.';
  }

  @override
  String get haNoUpdates => 'Nessun aggiornamento nell\'ultimo minuto.';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return 'Filtrato il $percent% degli aggiornamenti nell\'ultimo minuto ($dropped su $total).';
  }

  @override
  String get haRawUpdates =>
      'Un elemento di questa pagina riceve comunque tutti gli aggiornamenti delle entità, quindi qui il filtro fa risparmiare meno.';

  @override
  String get haAllStates =>
      'Questa vista legge gli stati di tutte le entità, quindi i suoi aggiornamenti non vengono filtrati.';

  @override
  String get haUnknownEntities =>
      'Non è possibile determinare le entità di questa vista, quindi i suoi aggiornamenti non vengono filtrati.';

  @override
  String get haWaiting => 'In attesa del caricamento della plancia…';

  @override
  String get haShowScan => 'Mostra i dettagli dell\'analisi.';

  @override
  String haThreshold(String count) {
    return 'Questa vista usa $count entità, superando la soglia di filtraggio. Il filtro è disattivato.';
  }

  @override
  String get haCustomPageFilter => 'Non usato nelle pagine personalizzate.';

  @override
  String get settingHaReturnHomeEnabledTitle =>
      'Torna alla vista iniziale della plancia';

  @override
  String get settingHaReturnHomeEnabledDescription =>
      'Torna alla plancia configurata sopra dopo un periodo di inattività.';

  @override
  String get settingHaReturnHomeSecondsTitle => 'Torna dopo (secondi)';

  @override
  String get settingHaReturnHomeSecondsDescription =>
      'Periodo di inattività prima che il kiosk torni indietro.';

  @override
  String get haReturnHint =>
      'Torna alla vista iniziale dopo un periodo di inattività';

  @override
  String get haReturnDisabled =>
      'Disattivato mentre la rotazione delle viste della plancia è attiva.';

  @override
  String get haReturnNoPath =>
      'La plancia configurata non ha un percorso di vista a cui tornare.';

  @override
  String haReturnPath(String path) {
    return 'Torna a \"$path\" allo scadere del tempo.';
  }

  @override
  String get haReturnCompass =>
      'Con la navigazione Compass, ogni vista della plancia nel layout torna, allo scadere del tempo, alla vista scelta per essa.';

  @override
  String get settingHaRotationEnabledTitle =>
      'Abilita la rotazione delle viste della plancia';

  @override
  String get settingHaRotationEnabledDescription =>
      'Scorre le viste selezionate della plancia in un ciclo continuo, mostrando ciascuna per il numero di secondi scelto.';

  @override
  String get settingHaRotationSecondsTitle => 'Secondi per vista';

  @override
  String get settingHaRotationSecondsDescription =>
      'Per quanto tempo ogni vista resta sullo schermo.';

  @override
  String get settingHaRotationPauseSecondsTitle =>
      'Pausa della rotazione dopo un\'interazione (secondi)';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      'Toccare lo schermo mette in pausa la rotazione per questo tempo, e ogni tocco fa ripartire il conto alla rovescia. Le interazioni vocali la mettono in pausa fino al loro termine. Con 0 la rotazione continua anche durante i tocchi.';

  @override
  String get settingHaRotationCrossfadeTitle => 'Dissolvenza tra le viste';

  @override
  String get settingHaRotationCrossfadeDescription =>
      'Dissolve verso lo sfondo e poi nella vista successiva invece di cambiare all\'istante. Il passaggio a un\'altra plancia o a una pagina esterna resta istantaneo.';

  @override
  String get settingHaRotationFadeSecondsTitle =>
      'Durata della dissolvenza (secondi)';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      'Durata complessiva della dissolvenza in uscita e in entrata. Il caricamento della vista successiva può richiedere più tempo, soprattutto la prima volta che viene aperta.';

  @override
  String get haRotation => 'Rotazione delle viste della plancia';

  @override
  String get haRotationHint =>
      'Ciclo tra le viste, tempo di permanenza, dissolvenza';

  @override
  String get haExternalPages => 'Pagine esterne';

  @override
  String get haFadeError =>
      'Scegli una durata della dissolvenza tra 0,2 e 5 secondi.';

  @override
  String get haPauseRemoteHelp =>
      'Un tocco mette in pausa la rotazione per questo tempo; ogni tocco fa ripartire il conteggio. Le interazioni vocali mettono sempre in pausa fino al loro termine. Con 0 la rotazione continua.';

  @override
  String get settingHaUrlTitle => 'URL di base di Home Assistant';

  @override
  String get settingHaUrlDescription =>
      'Ad esempio https://homeassistant.local:8123, senza il percorso di una plancia.';

  @override
  String get settingHaTokenTitle => 'Token di accesso di lunga durata';

  @override
  String get settingHaTokenDescription =>
      'Si crea nel tuo profilo HA → Sicurezza.';

  @override
  String get settingHaAutoLoginTitle => 'Accedi automaticamente';

  @override
  String get settingHaAutoLoginDescription =>
      'Accede alla plancia con il token di accesso indicato sopra invece di mostrare la pagina di accesso di Home Assistant.';

  @override
  String get haValidate => 'Verifica';

  @override
  String get haValidateConnection => 'Verifica la connessione';

  @override
  String get haChecking => 'Verifica…';

  @override
  String get haConnected => 'Connesso';

  @override
  String get haConnectedRemote => 'Connesso.';

  @override
  String get haNotValidated =>
      'Non ancora verificato. Le impostazioni qui sotto si sbloccano quando la connessione risulta funzionante.';

  @override
  String get haConnectFailed => 'Impossibile connettersi.';

  @override
  String get haNotConfigured => 'URL e token di Home Assistant non configurati';

  @override
  String get haInvalidToken => 'token non valido';

  @override
  String haUnreachable(String error) {
    return 'Impossibile raggiungere Home Assistant: $error';
  }

  @override
  String get haProxy => 'Proxy per contesto sicuro';

  @override
  String get haProxyHelp =>
      'Instrada un Home Assistant in semplice http attraverso un proxy interno all\'app, così il browser sblocca il microfono e le altre funzionalità disponibili solo con https. Solo per URL http.';

  @override
  String get haProxyRemoteHelp =>
      'Instrada un Home Assistant in semplice http attraverso un proxy interno all\'app, così il browser sblocca il microfono e le altre funzionalità disponibili solo con https. Disponibile solo per URL http.';

  @override
  String get haProxyNotice =>
      'Questa URL di Home Assistant usa il semplice http, e i browser bloccano il microfono e altre funzionalità nelle pagine http. Kiosk Satellite instraderà la plancia attraverso un proxy sicuro interno all\'app perché tutto funzioni. Potrebbe essere necessario accedere di nuovo a Home Assistant.';

  @override
  String get haProxyRemoteNotice =>
      'Questa URL di Home Assistant usa il semplice http, e i browser bloccano il microfono e altre funzionalità nelle pagine http. Kiosk Satellite instraderà la plancia attraverso un proxy sicuro interno all\'app perché tutto funzioni. Potrebbe essere necessario accedere di nuovo a Home Assistant sul tablet.';

  @override
  String get haDashboard => 'Plancia';

  @override
  String get haChooseView => 'Scegli una vista';

  @override
  String get settingHaThemeTitle => 'Tema';

  @override
  String get settingHaThemeDescription =>
      'Chiaro o scuro per la plancia di Home Assistant, impostabile anche dall\'entità Tema in Home Assistant. Automatico segue le impostazioni qui sotto.';

  @override
  String get settingThemeMatchAppTitle =>
      'Sincronizza i temi di Home Assistant con Kiosk Satellite';

  @override
  String get settingThemeMatchAppDescription =>
      'Adatta automaticamente il tema di Home Assistant all\'interfaccia di Kiosk Satellite.';

  @override
  String get settingThemeAutoTitle => 'Adatta il tema all\'ora del giorno';

  @override
  String get settingThemeAutoDescription =>
      'Alterna Home Assistant tra chiaro e scuro secondo una programmazione. Mantiene il tema selezionato, cambiandone solo la variante chiara o scura.';

  @override
  String get settingThemeDarkAtTitle => 'Tema scuro alle';

  @override
  String get settingThemeDarkAtDescription =>
      'Ora locale in cui passare al tema scuro.';

  @override
  String get settingThemeLightAtTitle => 'Tema chiaro alle';

  @override
  String get settingThemeLightAtDescription =>
      'Ora locale in cui tornare al tema chiaro.';

  @override
  String get settingThemeAutoAppTitle => 'Cambia anche il tema dell\'app';

  @override
  String get settingThemeAutoAppDescription =>
      'Cambia il tema di Kiosk Satellite (menu, impostazioni) insieme al cambio programmato di Home Assistant.';

  @override
  String get haThemeHint =>
      'Segue l\'app o alterna chiaro e scuro secondo una programmazione';

  @override
  String get haThemeAuto => 'Automatico';

  @override
  String get settingHaKioskModeTitle => 'Modalità kiosk di HA';

  @override
  String get settingHaKioskModeDescription =>
      'Nasconde l\'intestazione e la barra laterale di Home Assistant. Si applica subito.';

  @override
  String get settingHaKioskHideHeaderTitle => 'Nascondi l\'intestazione';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'Nasconde la barra degli strumenti della plancia e le schede delle viste mentre la modalità kiosk di HA è attiva. Lascia disattivato se cambi vista dall\'intestazione.';

  @override
  String get settingHaKioskHideSidebarTitle => 'Nascondi la barra laterale';

  @override
  String get settingHaKioskHideSidebarDescription =>
      'Nasconde la barra laterale di navigazione mentre la modalità kiosk di HA è attiva.';

  @override
  String get settingHaDashboardCarouselTitle =>
      'Abilita il carosello della plancia';

  @override
  String get settingHaDashboardCarouselDescription =>
      'Scorri a sinistra o a destra sulla plancia per passare da una vista all\'altra. Gli scorrimenti su cursori, mappe e schede scorrevoli non vengono intercettati.';

  @override
  String get settingHaCarouselOverCardsTitle =>
      'Intercetta gli scorrimenti sulle schede';

  @override
  String get settingHaCarouselOverCardsDescription =>
      'Cambia vista anche quando lo scorrimento inizia su una scheda che reagisce agli scorrimenti. I cursori continuano a funzionare normalmente.';

  @override
  String get settingHaHapticsTitle => 'Abilita la vibrazione';

  @override
  String get settingHaHapticsDescription =>
      'Vibra quando si usano pulsanti, interruttori, schede, cursori e manopole del termostato. Richiede un motore di vibrazione.';

  @override
  String get settingHaHapticsStrengthTitle => 'Intensità della vibrazione';

  @override
  String get settingHaHapticsStrengthDescription =>
      'Quanto è forte la vibrazione.';

  @override
  String get settingHaTapSoundTitle => 'Riproduci i suoni al tocco';

  @override
  String get settingHaTapSoundDescription =>
      'Riproduce il suono di tocco standard quando si usano pulsanti, interruttori, schede, cursori e manopole del termostato.';

  @override
  String get settingHaTapSoundVolumeTitle => 'Volume del suono al tocco';

  @override
  String get settingHaTapSoundVolumeDescription =>
      'Quanto è forte il suono al tocco.';

  @override
  String get haUserInterface => 'Interfaccia utente';

  @override
  String get haInterfaceHint =>
      'Modalità kiosk, carosello della plancia, vibrazione, suoni al tocco';

  @override
  String get haHaptics => 'Vibrazione e suoni';

  @override
  String get haVibrationLight => 'Leggera';

  @override
  String get haVibrationMedium => 'Media';

  @override
  String get haVibrationStrong => 'Forte';

  @override
  String get settingHomeLauncherEnabledTitle => 'Usa come schermata Home';

  @override
  String get settingHomeLauncherEnabledDescription =>
      'Registra Kiosk Satellite come schermata Home del dispositivo: il kiosk si avvia all\'accensione e ogni pressione del tasto Home riporta al kiosk. Si disattiva da solo e ripristina il launcher precedente se l\'app non riesce ad avviarsi più volte di seguito.';

  @override
  String get settingHomeKeepPinningTitle =>
      'Mantieni il blocco app sullo schermo';

  @override
  String get settingHomeKeepPinningDescription =>
      'Mantiene il blocco app sullo schermo anche quando Kiosk Satellite è la schermata Home. Disattiva i tasti App recenti e Indietro a livello di sistema, ma fa ricomparire la finestra di conferma del blocco sui dispositivi in cui l\'app non è proprietaria del dispositivo.';

  @override
  String get kioskHomeScreen => 'Schermata Home';

  @override
  String get kioskCheckingDevice => 'Controllo del dispositivo...';

  @override
  String get kioskFireOs =>
      'Fire OS non consente di sostituire il proprio launcher.';

  @override
  String get kioskUnsupported =>
      'Questo dispositivo non consente di cambiare la schermata Home.';

  @override
  String get kioskRecovered =>
      'Disattivato automaticamente dopo ripetuti avvii non riusciti; è stato ripristinato il launcher precedente. Riattiva l\'interruttore per riprovare.';

  @override
  String get kioskHeld =>
      'Kiosk Satellite è la schermata Home. Il kiosk si avvia all\'accensione e ogni pressione del tasto Home riporta al kiosk.';

  @override
  String get kioskDisabled =>
      'Non è la schermata Home. Attiva Usa come schermata Home qui sopra.';

  @override
  String get kioskWaiting =>
      'Non è ancora la schermata Home attuale: il dispositivo attende una conferma.';

  @override
  String get kioskOpenHomeSettings => 'Apri le impostazioni Home';

  @override
  String get kioskSetDefault => 'Imposta come predefinita';

  @override
  String get kioskActive => 'Attivo';

  @override
  String get kioskNotHome => 'Non è la schermata Home.';

  @override
  String get kioskWaitingRemote =>
      'In attesa di una conferma sul dispositivo: lì si aprono la finestra di sistema o le impostazioni Home.';

  @override
  String get kioskSetDevice => 'Imposta sul dispositivo';

  @override
  String get settingIntercomAnswerModeTitle => 'Modalità di risposta';

  @override
  String get settingIntercomAnswerModeDescription =>
      'Squilla chiede di rispondere sullo schermo. Rispondi automaticamente apre la chiamata dopo un segnale acustico.';

  @override
  String get settingIntercomRingSecondsTitle => 'Durata dello squillo';

  @override
  String get settingIntercomRingSecondsDescription =>
      'Per quanto tempo squilla una chiamata prima di essere considerata persa.';

  @override
  String get settingIntercomRingSoundTitle => 'Suoneria';

  @override
  String get settingIntercomRingSoundVolumeDescription =>
      'Viene riprodotta al volume della suoneria.';

  @override
  String get settingIntercomRingVolumeTitle => 'Volume della suoneria';

  @override
  String get settingIntercomRingVolumeDescription =>
      'Quanto è forte lo squillo di una chiamata, indipendentemente dal volume multimediale.';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => 'Accetta gli annunci';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      'Riproduce gli annunci inviati a tutti dagli altri kiosk.';

  @override
  String get intercomOptionAnswerRing => 'Squilla';

  @override
  String get intercomOptionAnswerAuto => 'Rispondi automaticamente';

  @override
  String get intercomOptionAnswerDnd => 'Non disturbare';

  @override
  String get intercomOptionAnswer15 => '15 secondi';

  @override
  String get intercomOptionAnswer30 => '30 secondi';

  @override
  String get intercomOptionAnswer45 => '45 secondi';

  @override
  String get intercomOptionAnswer60 => '60 secondi';

  @override
  String get intercomAnswerSection => 'Risposta';

  @override
  String get settingIntercomEnabledTitle => 'Abilita l\'interfono';

  @override
  String get settingIntercomEnabledDescription =>
      'Permette di chiamare gli altri kiosk di questa rete e di riceverne le chiamate.';

  @override
  String get settingIntercomKeyTitle => 'Chiave dell\'interfono';

  @override
  String get settingIntercomKeyDescription =>
      'I kiosk con la stessa chiave possono chiamarsi tra loro. Gestione flotta può sincronizzarla.';

  @override
  String get settingIntercomKeyPlaceholder =>
      'Creata quando abiliti l\'interfono';

  @override
  String get intercomNeedsAdmin =>
      'L\'interfono richiede l\'amministrazione remota';

  @override
  String get intercomAdminHelp =>
      'I kiosk la usano per trovarsi e raggiungersi. Attiva Amministrazione remota e Trova altri kiosk in Dispositivo, poi torna qui.';

  @override
  String get intercomChangeKey => 'Cambia chiave';

  @override
  String get intercomChangeKeyHelp =>
      'Incolla la chiave di un altro kiosk o creane una nuova.';

  @override
  String get intercomChange => 'Cambia';

  @override
  String get intercomKeyWarning =>
      'I kiosk con questa chiave possono chiamarsi tra loro. Una nuova chiave isola questo kiosk dagli altri finché non la ricevono anche loro.';

  @override
  String get intercomRegenerate => 'Rigenera';

  @override
  String get intercomKeyChanged => 'Chiave cambiata';

  @override
  String get intercomNotSet => 'Non impostata';

  @override
  String get intercomOpen => 'Apri';

  @override
  String get settingIntercomTlsTitle => 'Crittografa le comunicazioni';

  @override
  String get settingIntercomTlsDescription =>
      'Usa TLS per crittografare le chiamate dell\'interfono tra i kiosk. Tutti i kiosk della chiamata devono avere questa opzione abilitata.';

  @override
  String get intercomKiosks => 'Kiosk';

  @override
  String get intercomRosterHelp =>
      'Kiosk rilevati e membri della flotta salvati. Un kiosk è pronto quando è raggiungibile, ha l\'interfono attivo, la stessa chiave e le stesse impostazioni di crittografia.';

  @override
  String get intercomNoOther => 'Nessun altro kiosk trovato';

  @override
  String get intercomRosterDeviceHelp =>
      'Qui compaiono i kiosk con Amministrazione remota e Trova altri kiosk attivi.';

  @override
  String get intercomNoneHeard => 'Nessun kiosk trovato';

  @override
  String get intercomRosterRemoteHelp =>
      'I kiosk compaiono tramite il rilevamento in rete o perché salvati come membri della flotta. Amministrazione remota e Trova altri kiosk devono essere attivi.';

  @override
  String get intercomReady => 'Pronto';

  @override
  String get intercomOff => 'Interfono disattivato';

  @override
  String get intercomDifferentKey => 'Chiave diversa';

  @override
  String get intercomUnreachable => 'Non raggiungibile';

  @override
  String get intercomOffline => 'Offline';

  @override
  String get intercomChecking => 'Controllo…';

  @override
  String get settingIntercomTalkModeTitle => 'Modalità di conversazione';

  @override
  String get settingIntercomTalkModeDescription =>
      'Premi per parlare trasmette mentre tieni premuto il pulsante. Vivavoce mantiene il microfono aperto per tutta la chiamata.';

  @override
  String get intercomOptionTalkPtt => 'Premi per parlare';

  @override
  String get intercomOptionTalkHandsfree => 'Vivavoce';

  @override
  String get settingIntercomMaxCallMinutesTitle =>
      'Durata massima della chiamata';

  @override
  String get settingIntercomMaxCallMinutesDescription =>
      'Le chiamate terminano da sole dopo questo tempo.';

  @override
  String get intercomOptionCallUnlimited => 'Illimitata';

  @override
  String get intercomOptionCall1 => '1 minuto';

  @override
  String get intercomOptionCall2 => '2 minuti';

  @override
  String get intercomOptionCall5 => '5 minuti';

  @override
  String get intercomOptionCall10 => '10 minuti';

  @override
  String get intercomOptionCall15 => '15 minuti';

  @override
  String get intercomOptionCall20 => '20 minuti';

  @override
  String get intercomOptionCall30 => '30 minuti';

  @override
  String get intercomOptionCall45 => '45 minuti';

  @override
  String get intercomOptionCall60 => '60 minuti';

  @override
  String get settingIntercomHangupKeyTitle =>
      'Termina la chiamata premendo questo tasto';

  @override
  String get settingIntercomHangupKeyDescription =>
      'Durante una chiamata il tasto la termina invece di svolgere la sua azione abituale.';

  @override
  String get intercomOptionHangupOff => 'Disabilitato';

  @override
  String get intercomOptionHangupVolumeUp => 'Volume su';

  @override
  String get intercomOptionHangupVolumeDown => 'Volume giù';

  @override
  String get intercomOptionHangupMute => 'Muto';

  @override
  String get intercomOptionHangupHelp => 'Aiuto';

  @override
  String get settingIntercomHangupKeyRingingTitle =>
      'Tasto per riagganciare durante lo squillo';

  @override
  String get settingIntercomHangupKeyRingingDescription =>
      'Cosa fa il tasto quando una chiamata squilla su questo kiosk.';

  @override
  String get intercomOptionHangupRingingAnswer => 'Rispondi';

  @override
  String get intercomOptionHangupRingingDecline => 'Rifiuta';

  @override
  String get intercomOptionHangupRingingIgnore => 'Ignora';

  @override
  String get settingIntercomCallButtonsTitle => 'Pulsanti di chiamata';

  @override
  String get settingIntercomCallButtonsDescription =>
      'Pulsanti sullo schermo del kiosk che chiami. Un tocco esegue l\'azione su questo kiosk.';

  @override
  String get intercomCallButtonsAdd => 'Aggiungi un pulsante';

  @override
  String get intercomCallButtonIcon => 'Icona';

  @override
  String get intercomTalkSection => 'Conversazione';

  @override
  String get settingIntercomVideoTitle => 'Videochiamate';

  @override
  String get settingIntercomVideoDescription =>
      'Invia e mostra il video nelle chiamate.';

  @override
  String get settingIntercomVideoQualityTitle => 'Qualità video';

  @override
  String get settingIntercomVideoQualityDescription =>
      'Una qualità più alta usa più CPU.';

  @override
  String get intercomOptionVideoLow => 'Bassa';

  @override
  String get intercomOptionVideoMedium => 'Media';

  @override
  String get intercomOptionVideoHigh => 'Alta';

  @override
  String get intercomVideoSection => 'Video';

  @override
  String get settingIntercomAutoAnswerCameraTitle =>
      'Rispondi con la fotocamera attiva';

  @override
  String get settingIntercomAutoAnswerCameraDescription =>
      'Le videochiamate con risposta automatica si aprono con la fotocamera attiva.';

  @override
  String get settingKioskAllowDrawerTitle =>
      'Consenti il menu con azioni rapide';

  @override
  String get settingKioskAllowQuickControlsDescription =>
      'Mostra il menu senza gesto di uscita né PIN, limitato alle azioni selezionate qui sotto. Nella navigazione Classica si apre con uno scorrimento dal bordo. In Compass è la vista Controlli rapidi.';

  @override
  String get settingKioskAllowDashboardTitle => 'Plancia';

  @override
  String get settingKioskAllowDashboardDescription =>
      'Ricarica la pagina iniziale.';

  @override
  String get settingKioskAllowHaKioskTitle => 'Modalità kiosk di HA';

  @override
  String get settingKioskAllowHaKioskDescription =>
      'Mostra o nasconde l\'intestazione e la barra laterale di Home Assistant.';

  @override
  String get settingKioskAllowCameraTitle => 'Vista telecamere';

  @override
  String get settingKioskAllowCameraDescription =>
      'Apre la vista telecamere predefinita.';

  @override
  String get settingKioskAllowIntercomTitle => 'Interfono';

  @override
  String get settingKioskAllowIntercomDescription =>
      'Chiama altri kiosk dal menu del kiosk.';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription =>
      'Apre l\'interfaccia web di Music Assistant.';

  @override
  String get settingKioskAllowSendspinPlayerTitle => 'Lettore mobile';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      'Mostra o nasconde il lettore mobile e apre In riproduzione.';

  @override
  String get settingKioskAllowScreensaverTitle => 'Avvia salvaschermo';

  @override
  String get settingKioskAllowScreensaverDescription =>
      'Avvia subito il salvaschermo.';

  @override
  String get settingKioskAllowHoldTitle => 'Modalità pausa';

  @override
  String get settingKioskAllowHoldDescription =>
      'Attiva o disattiva la modalità pausa.';

  @override
  String get settingKioskAllowLockdownTitle => 'Modalità blocco';

  @override
  String get settingKioskAllowLockdownDescription =>
      'Blocca lo schermo fino al gesto di uscita o a uno sblocco remoto.';

  @override
  String get settingKioskAllowThemeTitle => 'Selettore del tema';

  @override
  String get settingKioskAllowThemeDescription =>
      'Passa dal tema chiaro a quello scuro e viceversa.';

  @override
  String get settingKioskAllowAppsTitle => 'App';

  @override
  String get settingKioskAllowAppsDescription =>
      'Apre il launcher delle app. Con Disabilita il tasto Home attivo, aprire un\'app rimuove il blocco del kiosk sullo schermo finché non si torna al kiosk.';

  @override
  String get kioskAllowedActions => 'Azioni consentite';

  @override
  String get kioskAllowedHelp => 'Quali azioni rapide offre il menu del kiosk';

  @override
  String get settingKioskAllowedAppsTitle => 'App consentite';

  @override
  String get settingKioskAllowedAppsDescription =>
      'Le app del launcher offerte mentre la modalità kiosk è attiva.';

  @override
  String get kioskAllowedAppsEmpty =>
      'Aggiungi prima le app in Impostazioni > Launcher app.';

  @override
  String get settingKioskEnabledTitle => 'Abilita la modalità kiosk';

  @override
  String get settingKioskEnabledDescription =>
      'Blocca il tablet su Kiosk Satellite. Il gesto di uscita sostituisce lo scorrimento che apre il menu, il tasto Indietro resta all\'interno del kiosk e si attivano le protezioni qui sotto.';

  @override
  String get settingKioskStartOnBootTitle => 'Avvia all\'accensione';

  @override
  String get settingKioskStartOnBootDescription =>
      'Avvia Kiosk Satellite all\'accensione del dispositivo. Su Android 10+ richiede l\'autorizzazione Mostra sopra altre app; Android la chiede alla prima attivazione.';

  @override
  String get settingKioskExitGestureTitle => 'Gesto di uscita dal kiosk';

  @override
  String get settingKioskExitGestureDescription =>
      'Una serie di tocchi rapidi in qualsiasi punto apre il menu, dopo il PIN se impostato. Le varianti con pressione prolungata richiedono di tenere premuto l\'ultimo tocco. Se disabilitato, solo l\'amministrazione remota può accedere alle impostazioni.';

  @override
  String get settingKioskPinTitle => 'PIN della modalità kiosk';

  @override
  String get settingKioskPinDescription =>
      'Richiesto dopo il gesto di uscita, prima che si apra il menu. Lascia vuoto per non usare un PIN.';

  @override
  String get settingKioskDisableStatusBarTitle =>
      'Disabilita la barra di stato';

  @override
  String get settingKioskDisableStatusBarDescription =>
      'Impedisce di aprire la barra di stato con una protezione sul bordo superiore. Richiede l\'autorizzazione Mostra sopra altre app; Android la chiede alla prima attivazione.';

  @override
  String get settingKioskDisableVolumeTitle => 'Disabilita i tasti del volume';

  @override
  String get settingKioskDisableVolumeDescription =>
      'Ignora i tasti fisici del volume.';

  @override
  String get settingKioskDisablePowerTitle =>
      'Disabilita il tasto di accensione';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android non può bloccare il tasto di accensione, quindi lo schermo si riaccende subito quando viene premuto. Lo spegnimento remoto dello schermo funziona comunque.';

  @override
  String get settingKioskDisableHomeTitle => 'Disabilita il tasto Home';

  @override
  String get settingKioskDisableHomeDescription =>
      'Fissa l\'app con il blocco app sullo schermo di Android, che disattiva i tasti Home e App recenti. Android chiede conferma la prima volta.';

  @override
  String get settingKioskDisableContextMenusTitle =>
      'Disabilita i menu contestuali';

  @override
  String get settingKioskDisableContextMenusDescription =>
      'Impedisce i menu a pressione prolungata e la selezione del testo nella vista web.';

  @override
  String get settingKioskDisablePullRefreshTitle =>
      'Disabilita trascina per aggiornare';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Ignora il gesto trascina per aggiornare mentre la modalità kiosk è attiva.';

  @override
  String get settingKioskDisableGesturesTitle => 'Disabilita i gesti';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Ignora i gesti della pagina Gesti mentre la modalità kiosk è attiva.';

  @override
  String get kioskGestureTaps5 => '5 tocchi rapidi';

  @override
  String get kioskGestureTaps7 => '7 tocchi rapidi';

  @override
  String get kioskGestureTaps5Hold =>
      '5 tocchi rapidi, tenendo premuto l\'ultimo';

  @override
  String get kioskGestureTaps7Hold =>
      '7 tocchi rapidi, tenendo premuto l\'ultimo';

  @override
  String get kioskGestureNone => 'Disabilitato (solo amministrazione remota)';

  @override
  String get kioskGroundControlVisionMatch => 'Ground Control Vision Match';

  @override
  String get settingKioskFaceSkipPinTitle => 'Salta il PIN per';

  @override
  String get settingKioskFaceSkipPinDescription =>
      'Con Persone scelte, dopo il gesto di uscita il menu si apre senza PIN mentre una delle persone scelte qui sotto viene riconosciuta davanti al kiosk.';

  @override
  String get kioskFaceSkipPinNobody => 'Nessuno';

  @override
  String get kioskFaceSkipPinPeople => 'Persone scelte';

  @override
  String get settingKioskFacePeopleTitle => 'Persone';

  @override
  String get settingKioskFacePeopleDescription =>
      'Scegli chi può saltare il PIN. Se non scegli nessuno, può farlo chiunque venga riconosciuto.';

  @override
  String get kioskForeground =>
      'Kiosk Satellite può tornare da solo in primo piano.';

  @override
  String get kioskOverlayMissing =>
      'Senza questa autorizzazione il kiosk non può tornare in primo piano e la protezione della modalità blocco copre solo l\'app.';

  @override
  String get kioskGuardHeld =>
      'L\'area notifiche e la schermata delle app recenti si chiudono da sole mentre lo schermo è protetto.';

  @override
  String get kioskGuardMissing =>
      'Senza questa autorizzazione l\'area notifiche e le app recenti restano accessibili. Abilita Kiosk Satellite in Accessibilità.';

  @override
  String get kioskOverlayRemote =>
      'Senza questa autorizzazione il kiosk non può tornare in primo piano. La schermata per concederla compare sul tablet.';

  @override
  String get kioskGuardRemote =>
      'Senza questa autorizzazione l\'area notifiche e le app recenti restano accessibili. Abilita Kiosk Satellite in Accessibilità sul tablet.';

  @override
  String get kioskGrantDevice => 'Concedi sul dispositivo';

  @override
  String get kioskOpenSettingsDevice => 'Apri le impostazioni sul dispositivo';

  @override
  String get settingLedEnabledTitle => 'Abilita il controllo LED';

  @override
  String get settingLedEnabledDescription =>
      'Consente a Kiosk Satellite di controllare le luci.';

  @override
  String get settingLedAnimationsTitle => 'Anima gli effetti';

  @override
  String get settingLedAnimationsDescription =>
      'Fa muovere gli archi e sfumare gli impulsi. Disattivalo per rendere statici tutti gli effetti.';

  @override
  String get settingLedIdleEnabledTitle => 'Accendi a riposo';

  @override
  String get settingLedIdleEnabledDescription =>
      'Le luci restano accese quando non viene mostrato nient\'altro.';

  @override
  String get settingLedIdleBrightnessTitle => 'Luminosità';

  @override
  String get settingLedIdleBrightnessDescription =>
      'Quanto sono luminose le luci in questo caso.';

  @override
  String get settingLedIdleLightColorTitle => 'Colore';

  @override
  String get settingLedIdleLightColorDescription =>
      'Il colore delle luci in questo caso.';

  @override
  String get settingLedIdleStyleTitle => 'Effetto';

  @override
  String get settingLedIdleStyleDescription =>
      'Come appaiono le luci a riposo.';

  @override
  String get settingLedIdleStyleOptionSolid => 'Fisso';

  @override
  String get settingLedIdleStyleOptionBreathe => 'Respiro';

  @override
  String get settingLedVoiceEnabledTitle => 'Mostra l\'attività vocale';

  @override
  String get settingLedVoiceEnabledDescription =>
      'Le luci si accendono mentre Voice Satellite ascolta, pensa e risponde.';

  @override
  String get settingLedVoiceBrightnessTitle => 'Luminosità';

  @override
  String get settingLedVoiceBrightnessDescription =>
      'Quanto sono luminose le luci in questo caso.';

  @override
  String get settingLedVoiceLightColorTitle => 'Colore';

  @override
  String get settingLedVoiceLightColorDescription =>
      'Sotto un arco che ruota durante l\'ascolto, alternato mentre pensa e in dissolvenza durante la risposta.';

  @override
  String get settingLedVoiceAccentColorTitle => 'Colore di accento';

  @override
  String get settingLedVoiceAccentColorDescription =>
      'L\'arco che si muove intorno alle luci.';

  @override
  String get settingLedVoiceMutedTitle => 'Mostra quando è silenziato';

  @override
  String get settingLedVoiceMutedDescription =>
      'Le luci restano accese mentre Voice Satellite è silenziato.';

  @override
  String get settingLedVoiceMutedColorTitle => 'Colore quando silenziato';

  @override
  String get settingLedVoiceMutedColorDescription =>
      'Il colore delle luci quando è silenziato.';

  @override
  String get settingLedTimersEnabledTitle => 'Mostra i timer';

  @override
  String get settingLedTimersEnabledDescription =>
      'Le luci pulsano mentre suona un timer.';

  @override
  String get settingLedTimersBrightnessTitle => 'Luminosità';

  @override
  String get settingLedTimersBrightnessDescription =>
      'Quanto sono luminose le luci in questo caso.';

  @override
  String get settingLedTimersLightColorTitle => 'Colore';

  @override
  String get settingLedTimersLightColorDescription =>
      'Il colore delle luci in questo caso.';

  @override
  String get settingLedTimersCountdownTitle => 'Mostra il conto alla rovescia';

  @override
  String get settingLedTimersCountdownDescription =>
      'Le luci si spengono una alla volta man mano che scade il prossimo timer.';

  @override
  String get settingLedAlarmsEnabledTitle => 'Mostra le sveglie';

  @override
  String get settingLedAlarmsEnabledDescription =>
      'Le luci pulsano mentre suona una sveglia.';

  @override
  String get settingLedAlarmsBrightnessTitle => 'Luminosità';

  @override
  String get settingLedAlarmsBrightnessDescription =>
      'Quanto sono luminose le luci in questo caso.';

  @override
  String get settingLedAlarmsLightColorTitle => 'Colore';

  @override
  String get settingLedAlarmsLightColorDescription =>
      'Il colore delle luci in questo caso.';

  @override
  String get settingLedIntercomEnabledTitle =>
      'Mostra le chiamate dell\'interfono';

  @override
  String get settingLedIntercomEnabledDescription =>
      'Le luci pulsano mentre una chiamata squilla e ruotano mentre è in corso.';

  @override
  String get settingLedIntercomBrightnessTitle => 'Luminosità';

  @override
  String get settingLedIntercomBrightnessDescription =>
      'Quanto sono luminose le luci in questo caso.';

  @override
  String get settingLedIntercomLightColorTitle => 'Colore';

  @override
  String get settingLedIntercomLightColorDescription =>
      'Il colore delle luci in questo caso.';

  @override
  String get settingLedNotificationsEnabledTitle => 'Mostra le notifiche';

  @override
  String get settingLedNotificationsEnabledDescription =>
      'Le luci pulsano lentamente mentre c\'è una notifica in attesa.';

  @override
  String get settingLedNotificationsBrightnessTitle => 'Luminosità';

  @override
  String get settingLedNotificationsBrightnessDescription =>
      'Quanto sono luminose le luci in questo caso.';

  @override
  String get settingLedNotificationsLightColorTitle => 'Colore';

  @override
  String get settingLedNotificationsLightColorDescription =>
      'Il colore delle luci in questo caso.';

  @override
  String get settingLedMediaEnabledTitle => 'Mostra la musica';

  @override
  String get settingLedMediaEnabledDescription =>
      'Le luci si accendono mentre viene riprodotta musica su questo dispositivo.';

  @override
  String get settingLedMediaBrightnessTitle => 'Luminosità';

  @override
  String get settingLedMediaBrightnessDescription =>
      'Quanto sono luminose le luci in questo caso.';

  @override
  String get settingLedMediaLightColorTitle => 'Colore';

  @override
  String get settingLedMediaLightColorDescription =>
      'Il colore delle luci in questo caso.';

  @override
  String get settingLedMediaStyleTitle => 'Effetto';

  @override
  String get settingLedMediaStyleDescription =>
      'Come le luci rappresentano la musica.';

  @override
  String get settingLedMediaStyleOptionSolid => 'Fisso';

  @override
  String get settingLedMediaStyleOptionBreathe => 'Respiro';

  @override
  String get settingLockdownEnabledTitle => 'Abilita la modalità blocco';

  @override
  String get settingLockdownEnabledDescription =>
      'Disabilita le interazioni con lo schermo finché non viene disattivata da Home Assistant o con il gesto di uscita.';

  @override
  String get settingLockdownAutoUnlockMinutesTitle =>
      'Sblocca automaticamente dopo';

  @override
  String get settingLockdownAutoUnlockMinutesDescription =>
      'Disattiva la modalità blocco dopo questo tempo quando viene avviata dal menu del kiosk. Imposta 0 per restare bloccato.';

  @override
  String get settingLockdownBlackoutTitle => 'Schermo nero';

  @override
  String get settingLockdownBlackoutDescription =>
      'Rende nero lo schermo durante il blocco.';

  @override
  String get settingLockdownAllowScreensaverTitle => 'Consenti il salvaschermo';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      'Consente al salvaschermo di funzionare durante il blocco. L\'impostazione Chiudi al rilevamento del movimento resta disattivata finché il blocco non viene rimosso.';

  @override
  String get settingLockdownExitGestureTitle =>
      'Gesto di uscita dalla modalità blocco';

  @override
  String get settingLockdownExitGestureDescription =>
      'Una serie di tocchi rapidi in qualsiasi punto disattiva la modalità blocco, dopo il PIN del kiosk se impostato. Le varianti con pressione prolungata richiedono di tenere premuto l\'ultimo tocco. Se disabilitato, solo l\'amministrazione remota o Home Assistant possono disattivarla.';

  @override
  String get lockdownGestureNone => 'Disabilitato (solo da remoto)';

  @override
  String get lockdownExplanation =>
      'La modalità blocco rende la plancia non interattiva, attiva tutte le protezioni della modalità kiosk senza modificarne le impostazioni e silenzia il rilevamento della parola di attivazione finché è attiva. Con la protezione dell\'interfaccia di sistema abilitata (sopra), vengono bloccate anche l\'area notifiche e le app recenti. Home Assistant riceve un interruttore Modalità blocco tramite ESPHome.';

  @override
  String get lockdownSearch =>
      'Protezione tattile configurabile solo da remoto. Si configura dall\'interfaccia di amministrazione remota; le sue autorizzazioni sono in Autorizzazioni di sistema richieste.';

  @override
  String get settingLockdownFaceDisableTitle =>
      'Disattiva la modalità blocco per';

  @override
  String get settingLockdownFaceDisableDescription =>
      'Con Persone scelte, la modalità blocco viene disattivata quando una delle persone scelte qui sotto viene riconosciuta davanti al kiosk. Lascia su Nessuno se blocchi lo schermo per pulirlo.';

  @override
  String get settingLockdownFacePeopleDescription =>
      'Scegli per chi viene disattivata la modalità blocco. Se non scegli nessuno, viene disattivata per chiunque venga riconosciuto.';

  @override
  String get settingLockdownFaceRelockTitle => 'Riattiva la modalità blocco';

  @override
  String get settingLockdownFaceRelockDescription =>
      'Riattiva la modalità blocco 10 secondi dopo che nessuna delle persone scelte è più inquadrata.';

  @override
  String get lockdownOverlayHeld =>
      'La protezione della modalità blocco può coprire l\'intero schermo.';

  @override
  String get lockdownOverlayMissing =>
      'Senza questa autorizzazione la protezione copre solo l\'app. La schermata per concederla compare sul tablet.';

  @override
  String get lockdownPermissionsSearch =>
      'Le autorizzazioni su cui si basano le protezioni della modalità blocco.';

  @override
  String get settingAirplayEnabledTitle => 'Abilita il ricevitore AirPlay';

  @override
  String get settingAirplayEnabledDescription =>
      'Il dispositivo compare come altoparlante AirPlay nel menu AirPlay di un iPhone, iPad o Mac.';

  @override
  String get settingAirplayNameTitle => 'Nome dell\'altoparlante';

  @override
  String get settingAirplayNameDescription =>
      'Il nome nel menu AirPlay. Se vuoto, viene usato il nome del dispositivo.';

  @override
  String get settingAirplaySenderVolumeTitle => 'Segui il volume del mittente';

  @override
  String get settingAirplaySenderVolumeDescription =>
      'Il controllo del volume su iPhone, iPad o Mac cambia il volume di questo dispositivo. Se disattivato, conta solo il volume di questo dispositivo.';

  @override
  String get settingAirplaySyncOffsetDescription =>
      'Un valore negativo fa suonare prima questo dispositivo, per allineare l\'audio al video sul mittente. Si applica in tempo reale.';

  @override
  String get settingAirplayTakeoverTitle =>
      'Consenti a un altro mittente di subentrare';

  @override
  String get settingAirplayTakeoverDescription =>
      'Un secondo iPhone, iPad o Mac può subentrare mentre un altro è in riproduzione. Se disattivato, deve attendere che il primo si disconnetta.';

  @override
  String get mediaAirplayHint => 'Riproduci l\'audio da un iPhone, iPad o Mac';

  @override
  String get mediaCacheTitle => 'Cache delle copertine';

  @override
  String get mediaCacheReadFailed =>
      'Impossibile leggere la dimensione della cache.';

  @override
  String get mediaCacheClearFailed => 'Impossibile svuotare la cache.';

  @override
  String get mediaCacheChecking => 'Controllo della dimensione della cache...';

  @override
  String get mediaCacheClearing => 'Svuotamento...';

  @override
  String mediaCacheUsage(String used, String limit) {
    return '$used usati su $limit. Le miniature della coda vengono salvate automaticamente nella cache.';
  }

  @override
  String get settingSendspinShowPlayerTitle => 'Mostra il lettore mobile';

  @override
  String get settingSendspinShowPlayerDescription =>
      'Durante la riproduzione di musica, mostra sopra la plancia una piccola finestra con copertina, informazioni sul brano e avanzamento. Trascinala dove vuoi: la posizione viene ricordata.';

  @override
  String get settingSendspinPlayerSizeTitle => 'Dimensione del lettore';

  @override
  String get settingSendspinPlayerSizeDescription =>
      'Compatto è una piccola finestra poco invadente con il brano in riproduzione. Grande aggiunge i pulsanti precedente, riproduci/pausa e successivo, dimensionati per il tocco, che controllano l\'intero gruppo di riproduzione.';

  @override
  String get settingSendspinPausedHideMinutesTitle =>
      'Nascondi il lettore in pausa dopo';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      'Per quanto tempo un lettore in pausa resta sullo schermo. Vale sia per il lettore mobile sia per la vista In riproduzione.';

  @override
  String get settingSendspinDismissKeepsPlayingTitle =>
      'Continua la riproduzione alla chiusura';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      'Scorrere via il lettore mobile lo nasconde senza fermare la musica.';

  @override
  String get mediaFloatingPage => 'Lettore mobile';

  @override
  String get mediaFloatingHint => 'La piccola finestra sopra la plancia';

  @override
  String get mediaCompact => 'Compatto';

  @override
  String get mediaLargeControls => 'Grande con controlli';

  @override
  String get settingSendspinPlayerSourceTitle => 'Sorgente del lettore';

  @override
  String get settingSendspinPlayerSourceDescription =>
      'Cosa mostrano e controllano il lettore mobile e In riproduzione: questo dispositivo o un lettore altrove.';

  @override
  String get settingSendspinPlayerTitle => 'Lettore';

  @override
  String get settingSendspinPlayerDescription =>
      'Il lettore di quella sorgente da mostrare e controllare.';

  @override
  String get settingSendspinDuckPercentTitle =>
      'Abbassa il volume durante le interazioni vocali';

  @override
  String get settingSendspinDuckPercentDescription =>
      'Durante le interazioni vocali e le chiamate dell\'interfono la musica scende a questa percentuale del suo volume, poi torna al livello precedente.';

  @override
  String get settingSendspinEsphomeEntitiesTitle => 'Esponi le entità ESPHome';

  @override
  String get settingSendspinEsphomeEntitiesDescription =>
      'Pulsanti riproduci, pausa, successivo e precedente per il lettore seguito in Home Assistant, con stato, titolo, artista e sorgente come sensori.';

  @override
  String get settingSendspinVolumeKeysTitle =>
      'I tasti del volume controllano il lettore';

  @override
  String get settingSendspinVolumeKeysGroupDescription =>
      'I tasti del volume di questo dispositivo cambiano il volume del lettore seguito invece del proprio. Quando questo dispositivo riproduce in un gruppo, cambiano il volume del gruppo. Solo mentre la vista In riproduzione è sullo schermo o ogni volta che il lettore è in riproduzione.';

  @override
  String get settingSendspinVolumeKeyStepTitle =>
      'Incremento dei tasti del volume';

  @override
  String get settingSendspinVolumeKeyStepDescription =>
      'Di quanto cambia il volume del lettore a ogni pressione di un tasto del volume.';

  @override
  String get mediaIntro =>
      'Il lettore mobile e In riproduzione compaiono solo quando il lettore scelto ha un brano in riproduzione o una coda caricata. Se non c\'è nulla in riproduzione o in coda, non compare nessuno dei due.';

  @override
  String get mediaThisDevice => 'Questo dispositivo';

  @override
  String get mediaOff => 'Disattivato';

  @override
  String get mediaKeysNowPlaying => 'Mentre è visibile In riproduzione';

  @override
  String get mediaKeysPlaying => 'Mentre il lettore è in riproduzione';

  @override
  String get mediaAnotherPlayer => 'un altro lettore';

  @override
  String mediaOfflineSendspin(String player) {
    return 'Il lettore Sendspin resta offline mentre è selezionato $player.';
  }

  @override
  String mediaOfflineAirplay(String player) {
    return 'Il ricevitore AirPlay resta disattivato mentre è selezionato $player.';
  }

  @override
  String mediaOfflineBoth(String player) {
    return 'Il lettore Sendspin e il ricevitore AirPlay restano offline mentre è selezionato $player.';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => 'Abilita i testi';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      'Testi sincronizzati nella vista In riproduzione, per ogni sorgente del lettore.';

  @override
  String get settingSendspinLyricsSourceTitle => 'Sorgente dei testi';

  @override
  String get settingSendspinLyricsSourceDescription =>
      'Da dove provengono i testi. Music Assistant richiede l\'indirizzo del server e il token nella sua pagina.';

  @override
  String get settingSendspinLyricsFallbackTitle =>
      'Usa Music Assistant come riserva';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      'Se LRCLIB non è raggiungibile, i testi vengono chiesti a Music Assistant. Richiede la connessione a Music Assistant.';

  @override
  String get settingSendspinLyricsOffsetTitle => 'Sincronizzazione dei testi';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      'Sposta i testi rispetto alla musica. Un valore positivo mostra ogni riga prima, uno negativo dopo. Utile per i brani in cui i testi risultano sempre sfasati.';

  @override
  String get mediaLyricsPage => 'Testi';

  @override
  String get mediaLyricsHint =>
      'Testi sincronizzati, sorgente e sincronizzazione';

  @override
  String get settingSendspinMaUrlTitle => 'Indirizzo del server';

  @override
  String get settingSendspinMaUrlDescription =>
      'L\'indirizzo del server Music Assistant, come lo mostra la sua interfaccia web. Di solito https e porta 8095.';

  @override
  String get settingSendspinMaTokenTitle => 'Token di autenticazione';

  @override
  String get settingSendspinMaTokenDescription =>
      'Un token di lunga durata di Music Assistant (Impostazioni, Utenti). L\'accesso in lettura basta per i testi; la scorciatoia nel menu del kiosk apre l\'interfaccia web con l\'utente a cui appartiene il token.';

  @override
  String get settingSendspinMaOpenFullscreenTitle =>
      'Apri direttamente In riproduzione';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      'Apre il lettore a schermo intero di Music Assistant dal menu del kiosk o con il gesto Apri Music Assistant.';

  @override
  String get settingSendspinMaAutoCloseTitle => 'Chiudi per inattività';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Torna alla plancia quando nessuno tocca la pagina di Music Assistant per questo tempo. Con zero resta aperta finché non viene chiusa.';

  @override
  String get settingSendspinMaHideCloseTitle =>
      'Nascondi il pulsante di chiusura';

  @override
  String get settingSendspinMaHideCloseDescription =>
      'Il pulsante di chiusura mobile può coprire i controlli di Music Assistant, come il menu In riproduzione. Senza di esso, chiudi la pagina con il tasto Indietro o con il menu del kiosk.';

  @override
  String get settingSendspinMaZoomDescription =>
      'Ridimensiona l\'intera pagina di Music Assistant.';

  @override
  String get mediaMaHint => 'Server, token, scorciatoia nel menu del kiosk';

  @override
  String get mediaKioskMenu => 'Menu del kiosk';

  @override
  String get mediaValidateConnection => 'Verifica la connessione';

  @override
  String get mediaValidate => 'Verifica';

  @override
  String get mediaChecking => 'Controllo…';

  @override
  String get mediaConnected => 'Connesso';

  @override
  String mediaConnectedVersion(String version) {
    return 'Connesso a Music Assistant $version';
  }

  @override
  String get mediaValidateHint =>
      'Controlla l\'indirizzo e il token prima di attivare la scorciatoia o i testi.';

  @override
  String get mediaDeviceNoAnswer => 'Il dispositivo non ha risposto.';

  @override
  String get mediaValidationFailed => 'Verifica non riuscita.';

  @override
  String get mediaNoAddress => 'Nessun indirizzo del server impostato.';

  @override
  String get mediaNoToken => 'Nessun token di autenticazione impostato.';

  @override
  String get mediaTimeout => 'Music Assistant non ha risposto in tempo.';

  @override
  String mediaUnreachable(String host, String error) {
    return 'Impossibile raggiungere $host: $error';
  }

  @override
  String get mediaServerClosed => 'il server ha chiuso la connessione';

  @override
  String get settingSendspinFullscreenControlsTitle =>
      'Mostra i controlli multimediali';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      'Pulsanti precedente, riproduci/pausa e successivo e una barra di avanzamento nella vista In riproduzione. Con i controlli attivi, la vista si chiude con un pulsante di chiusura invece che con un tocco in qualsiasi punto.';

  @override
  String get settingSendspinFullscreenTextScaleTitle => 'Dimensione del testo';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      'Dimensione del titolo del brano, dell\'artista, dell\'album, dei testi e della coda. Si applica in entrambi i layout e accanto al salvaschermo. La copertina si adatta per lasciare spazio al testo.';

  @override
  String get settingSendspinFullscreenButtonScaleTitle => 'Scala dei pulsanti';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      'Dimensione dei pulsanti di riproduzione e della barra di avanzamento, indipendente da quella del testo. Si applica in entrambi i layout e accanto al salvaschermo. I controlli si adattano allo spazio disponibile nel lettore.';

  @override
  String get settingSendspinFullscreenLayoutTitle => 'Modalità di layout';

  @override
  String get settingSendspinFullscreenLayoutDescription =>
      'Come In riproduzione dispone copertina, dettagli del brano e controlli. Orizzontale li divide in una metà sinistra e una destra. Solo copertina riempie lo schermo con la copertina e mostra dettagli del brano e controlli per alcuni secondi dopo un tocco, passando a Verticale mentre sono aperti i testi o la coda. Non si applica quando In riproduzione è affiancata a un salvaschermo.';

  @override
  String get mediaLayoutVertical => 'Verticale';

  @override
  String get mediaLayoutHorizontal => 'Orizzontale';

  @override
  String get mediaLayoutArtOnly => 'Solo copertina';

  @override
  String get settingSendspinFullscreenDoubleTapTitle =>
      'Doppio tocco per chiudere';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'Un doppio tocco in qualsiasi punto della vista In riproduzione la chiude. Il pulsante di chiusura non viene mostrato. Non si applica quando In riproduzione è affiancata a un salvaschermo.';

  @override
  String get settingSendspinFullscreenCloseButtonTitle =>
      'Mostra sempre il pulsante di chiusura';

  @override
  String get settingSendspinFullscreenCloseButtonDescription =>
      'Mostra il pulsante di chiusura anche quando Doppio tocco per chiudere è attivo.';

  @override
  String get settingSendspinFullscreenOnPlayTitle =>
      'Apri In riproduzione quando inizia la musica';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      'Apre la vista In riproduzione appena inizia la riproduzione, invece di attendere il tempo di inattività del salvaschermo.';

  @override
  String get settingSendspinFullscreenMotionTitle =>
      'Chiudi \"In riproduzione\" al movimento';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      'Consente al movimento di chiudere In riproduzione come un normale salvaschermo. Se disattivato, la chiude solo il tocco, così chi passa non interrompe la visualizzazione della musica. Non si applica quando In riproduzione è affiancata a un salvaschermo.';

  @override
  String get settingSendspinFullscreenReturnTitle => 'Dopo la chiusura';

  @override
  String get settingSendspinFullscreenReturnDescription =>
      'La vista della plancia da mostrare dopo la chiusura di In riproduzione. Predefinito segue Torna alla vista iniziale della plancia.';

  @override
  String get mediaReturnLastView => 'Ultima vista';

  @override
  String get mediaReturnChosenView => 'Vista scelta';

  @override
  String get settingSendspinFullscreenReturnViewTitle => 'Vista della plancia';

  @override
  String get settingSendspinFullscreenReturnViewDescription =>
      'La vista da mostrare dopo la chiusura di In riproduzione.';

  @override
  String get settingSendspinSpeakerPillTitle =>
      'Mostra il selettore degli altoparlanti';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Mostra il selettore degli altoparlanti per 5 secondi dopo un\'interazione con lo schermo. Permette di aggiungere o rimuovere altoparlanti dal gruppo attuale.';

  @override
  String get settingSendspinSpeakerPillPlayersTitle =>
      'Filtra il selettore degli altoparlanti';

  @override
  String get settingSendspinSpeakerPillPlayersDescription =>
      'Nel selettore compaiono solo questi altoparlanti. Quelli già nel gruppo compaiono sempre.';

  @override
  String get settingSendspinAudioQualityTitle => 'Mostra la qualità audio';

  @override
  String get settingSendspinAudioQualityDescription =>
      'Mostra formato, profondità di bit, frequenza di campionamento, bitrate e sorgente del brano attuale nella parte inferiore di In riproduzione. Richiede Music Assistant.';

  @override
  String get mediaAllSpeakers => 'Tutti gli altoparlanti';

  @override
  String get settingSendspinQueueArtTitle => 'Mostra le copertine nella coda';

  @override
  String get settingSendspinQueueArtDescription =>
      'Una copertina su ogni riga del pannello della coda.';

  @override
  String get mediaNowPlayingHint =>
      'Vista a schermo intero durante la riproduzione di musica';

  @override
  String get mediaInterfaceHeading => 'Interfaccia utente';

  @override
  String get settingSendspinFullscreenTitle =>
      '\"In riproduzione\" al posto del salvaschermo';

  @override
  String get settingSendspinFullscreenDescription =>
      'Durante la riproduzione di musica, il salvaschermo diventa una vista In riproduzione a schermo intero con la copertina. Se non c\'è nulla in riproduzione, viene eseguito il salvaschermo normale.';

  @override
  String get settingSendspinFullscreenSplitTitle =>
      'Mostra accanto al salvaschermo';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      'Mantiene il salvaschermo visibile accanto a In riproduzione. Sugli schermi verticali il salvaschermo viene messo sopra il lettore. Sugli schermi piccoli resta il lettore a schermo intero.';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => 'Riempi lo schermo';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      'Sostituisce l\'impostazione di riempimento delle foto mentre il salvaschermo condivide lo schermo con In riproduzione. Predefinito usa l\'impostazione di ciascun salvaschermo. Disattivato mantiene l\'intera foto tra bande nere. Intelligente ingrandisce le foto con proporzioni vicine a quelle dello schermo e inquadra le altre su uno sfondo sfocato. Sempre ingrandisce ogni foto, tagliando ciò che non entra.';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle =>
      'Sostituisci la luminosità del salvaschermo';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      'Usa la luminosità normale dello schermo invece di quella del salvaschermo mentre In riproduzione è affiancata a un salvaschermo. Sostituisce anche la luminosità dei salvaschermo programmati.';

  @override
  String get mediaScreensaverHeading => 'Salvaschermo';

  @override
  String get mediaDefaultFill => 'Predefinito';

  @override
  String get mediaFillOff => 'Disattivato';

  @override
  String get mediaFillSmart => 'Intelligente';

  @override
  String get mediaFillAlways => 'Sempre';

  @override
  String get mediaPickPlayer => 'Scegli un lettore';

  @override
  String get mediaMaPlayer => 'Lettore di Music Assistant';

  @override
  String get mediaHaPlayer => 'Lettore multimediale di Home Assistant';

  @override
  String get mediaSonosRoom => 'Stanza Sonos';

  @override
  String get mediaSearchPlayers => 'Cerca lettori';

  @override
  String get mediaOffline => 'Offline';

  @override
  String mediaOfflineName(String name) {
    return '$name (offline)';
  }

  @override
  String get mediaSetUpMa =>
      'Configura Music Assistant per elencarne i lettori.';

  @override
  String get mediaSetUpHa =>
      'Connetti Home Assistant per elencarne i lettori multimediali.';

  @override
  String get mediaSetUpSonos =>
      'Nessun altoparlante Sonos ancora noto. Cercane o aggiungine uno nella pagina Sonos.';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant non ha risposto: $error';
  }

  @override
  String get mediaSaveFailed => 'Impossibile salvare il lettore.';

  @override
  String get mediaSelectFailed => 'Impossibile selezionare il lettore';

  @override
  String get mediaNotificationAccessRemote =>
      'Senza questa autorizzazione Android non elenca alcuna sessione multimediale, quindi In riproduzione non può seguire le app in riproduzione su questo dispositivo. La schermata per concederla compare sul tablet.';

  @override
  String get mediaLocalMediaSession => 'Sessione multimediale locale';

  @override
  String get settingSendspinEnabledTitle => 'Abilita il lettore Sendspin';

  @override
  String get settingSendspinEnabledDescription =>
      'Trasforma questo dispositivo in un lettore Sendspin sincronizzato. Compare in Music Assistant con il nome del dispositivo, in sincronia con tutti gli altri altoparlanti Sendspin.';

  @override
  String get settingSendspinServerTitle => 'Server';

  @override
  String get settingSendspinServerDescription =>
      'Indirizzo del server Sendspin, ad esempio 192.168.1.10:8927. Lascia vuoto per trovare automaticamente il server in rete.';

  @override
  String get settingSendspinCodecTitle => 'Codec audio preferito';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC è senza perdita ed è ideale su Wi-Fi o Ethernet. Il server fa la scelta finale tra quelli offerti da questo dispositivo.';

  @override
  String get settingSendspinSyncOffsetTitle =>
      'Regolazione della sincronizzazione audio (ms)';

  @override
  String get settingSendspinSyncOffsetDescription =>
      'Un valore negativo fa suonare prima questo dispositivo, per gli altoparlanti in ritardo rispetto al gruppo (Bluetooth). Regola a orecchio; si applica in tempo reale.';

  @override
  String get settingSendspinGroupVolumeDescription =>
      'Quando questo dispositivo riproduce in un gruppo, il cursore del volume imposta il volume dell\'intero gruppo. Se disattivato, solo quello di questo dispositivo. Richiede la connessione a Music Assistant.';

  @override
  String get settingSendspinMasterVolumeTitle =>
      'Controlla il volume del dispositivo';

  @override
  String get settingSendspinMasterVolumeDescription =>
      'Music Assistant imposta il volume regolato dai tasti del volume, anziché il volume multimediale. Anche i suoni dell\'assistente vocale lo seguono.';

  @override
  String get mediaSendspinPage => 'Lettore Sendspin';

  @override
  String get mediaSendspinHint =>
      'Rendi questo dispositivo un lettore Music Assistant sincronizzato';

  @override
  String get mediaFlac => 'FLAC (senza perdita)';

  @override
  String get mediaOpus => 'Opus (efficiente)';

  @override
  String get mediaPcm => 'PCM (non compresso)';

  @override
  String get settingSendspinSonosGroupVolumeTitle =>
      'Regola il volume del gruppo';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      'Quando la stanza seguita riproduce in un gruppo, il cursore del volume regola il volume dell\'intero gruppo. Se disattivata, regola solo quello della stanza.';

  @override
  String get settingSendspinSonosInputsTitle => 'Mostra TV e ingresso di linea';

  @override
  String get settingSendspinSonosInputsDescription =>
      'Mostra l\'attività nel lettore multimediale quando gli ingressi eARC o di linea sono attivi.';

  @override
  String get mediaSonosHint =>
      'Altoparlanti in rete, aggiungine uno tramite indirizzo';

  @override
  String get mediaSonosSpeakers => 'Altoparlanti';

  @override
  String get mediaSonosNoneFound => 'Nessun Sonos trovato';

  @override
  String get mediaSonosDiscoveryEmpty =>
      'Nessun altoparlante ha risposto su questa rete. Aggiungine uno tramite indirizzo.';

  @override
  String get mediaSonosAddTitle => 'Aggiungi un Sonos tramite indirizzo';

  @override
  String get mediaSonosLooking => 'Ricerca…';

  @override
  String get mediaSonosEmpty => 'Ancora nessun altoparlante';

  @override
  String get mediaSonosEmptyHelp =>
      'Cerca in questa rete o aggiungi un altoparlante tramite il suo indirizzo.';

  @override
  String get mediaSonosForget => 'Dimentica';

  @override
  String get mediaSonosSearchTitle => 'Cerca nella rete';

  @override
  String get mediaSonosSearchHelp =>
      'Trova gli altoparlanti Sonos su questa rete. Per essere rilevati automaticamente, gli altoparlanti devono trovarsi sulla stessa VLAN di questo dispositivo.';

  @override
  String get mediaSonosSearch => 'Cerca';

  @override
  String get mediaSonosSearching => 'Ricerca in corso…';

  @override
  String get mediaSonosAddAddress => 'Aggiungi tramite indirizzo';

  @override
  String get mediaSonosAddressHelp =>
      'L\'indirizzo dell\'altoparlante in rete. A partire da questo viene aggiunto l\'intero sistema Sonos.';

  @override
  String get mediaSonosPickRoom =>
      'Scegli una stanza in Sorgente del lettore, Sonos.';

  @override
  String get mediaSonosAdded => 'Sonos aggiunto';

  @override
  String get mediaSonosNoRooms =>
      'L\'altoparlante non ha restituito alcuna stanza.';

  @override
  String get mediaSonosNoAddress => 'nessun indirizzo';

  @override
  String mediaSonosUnreachable(String host) {
    return 'Nessun Sonos ha risposto all\'indirizzo $host.';
  }

  @override
  String get settingsMenuHomeAssistant => 'Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary =>
      'Connessione, plancia, modalità kiosk';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary =>
      'Parola di attivazione, ascolto in background';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary => 'Entità native e proxy Bluetooth';

  @override
  String get settingsMenuScreenAudio => 'Schermo e audio';

  @override
  String get settingsMenuScreenAudioSummary => 'Luminosità, volume, microfono';

  @override
  String get settingsMenuScreensaver => 'Salvaschermo';

  @override
  String get settingsMenuScreensaverSummary =>
      'Tempo di inattività, modalità, riattivazione al movimento';

  @override
  String get settingsMenuBrowser => 'Navigazione web';

  @override
  String get settingsMenuBrowserSummary => 'Cache, SSL, livello di zoom';

  @override
  String get settingsMenuMediaPlayer => 'Lettore multimediale';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant, Sendspin, Sonos';

  @override
  String get settingsMenuDlna => 'Ricevitore DLNA';

  @override
  String get settingsMenuDlnaSummary =>
      'Riproduce immagini, video e audio da remoto';

  @override
  String get settingsMenuIntercom => 'Interfono';

  @override
  String get settingsMenuIntercomSummary => 'Comunicazione tra kiosk';

  @override
  String get settingsMenuCamera => 'Fotocamera';

  @override
  String get settingsMenuCameraSummary =>
      'Fotocamera del dispositivo, movimento, streaming';

  @override
  String get settingsMenuCameraStreams => 'Flussi delle telecamere';

  @override
  String get settingsMenuCameraStreamsSummary =>
      'Telecamere di Go2RTC e Home Assistant';

  @override
  String get settingsMenuKiosk => 'Modalità kiosk';

  @override
  String get settingsMenuKioskSummary => 'Gesto di uscita, PIN, tasti fisici';

  @override
  String get settingsMenuHomeLauncher => 'Launcher Home';

  @override
  String get settingsMenuHomeLauncherSummary =>
      'Sostituisce la schermata Home del dispositivo';

  @override
  String get settingsMenuAppLauncher => 'Launcher app';

  @override
  String get settingsMenuAppLauncherSummary => 'Apre altre app dal kiosk';

  @override
  String get settingsMenuGestures => 'Gesti';

  @override
  String get settingsMenuGesturesSummary =>
      'Gesti con tocco, palmo e battito di mani';

  @override
  String get settingsMenuDevice => 'Dispositivo';

  @override
  String get settingsMenuDeviceSummary =>
      'Nome, tema dell\'app, accesso remoto';

  @override
  String get settingsMenuFleet => 'Gestione flotta';

  @override
  String get settingsMenuFleetSummary => 'Guida o segue altri kiosk';

  @override
  String get settingsMenuPlugins => 'Gestione plugin';

  @override
  String get settingsMenuPluginsSummary => 'Installa e gestisce i plugin';

  @override
  String get settingsMenuLogs => 'Registri';

  @override
  String get settingsMenuLogsSummary => 'Registro dell\'app e console web';

  @override
  String get settingsMenuAbout => 'Informazioni';

  @override
  String get settingsMenuAboutSummary => 'Versione, autore, licenza';

  @override
  String get settingsMenuOverview => 'Panoramica';

  @override
  String get settingsMenuOverviewSummary => 'Schermo e controlli rapidi';

  @override
  String get settingsMenuLockdown => 'Modalità blocco';

  @override
  String get settingsMenuLockdownSummary =>
      'Disattiva le interazioni con lo schermo';

  @override
  String get settingsMenuFiles => 'Gestione file';

  @override
  String get settingsMenuFilesSummary => 'Sfoglia, scarica e carica file';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => 'Schermo';

  @override
  String get settingsGroupMediaCameras => 'Contenuti multimediali e telecamere';

  @override
  String get settingsGroupHousehold => 'Casa';

  @override
  String get settingsGroupKiosk => 'Kiosk';

  @override
  String get settingsGroupSystem => 'Sistema';

  @override
  String get settingsMenuMenu => 'Menu';

  @override
  String get settingsMenuTheme => 'Tema';

  @override
  String get settingsMenuLogout => 'Esci';

  @override
  String get settingsMenuSwitchKiosk => 'Cambia kiosk';

  @override
  String settingsMenuThemeState(String theme) {
    return 'Tema: $theme';
  }

  @override
  String get settingsMenuThemeAuto => 'Automatico';

  @override
  String get settingsMenuOverviewHeadlessSummary => 'Stato e controlli rapidi';

  @override
  String get settingsMenuHomeAssistantHeadlessSummary => 'Connessione';

  @override
  String get settingsMenuAudio => 'Audio';

  @override
  String get settingsMenuAudioSummary => 'Volume, microfono';

  @override
  String get settingsGroupMedia => 'Contenuti multimediali';

  @override
  String get settingsMenuDlnaHeadlessSummary => 'Riproduce audio da remoto';

  @override
  String get settingsMenuGesturesHeadlessSummary =>
      'Gesti con tasti e battito di mani';

  @override
  String get settingsMenuLeds => 'Controllo LED';

  @override
  String get settingsMenuLedsSummary => 'Colori ed effetti delle luci di stato';

  @override
  String get settingsLedTimers => 'Timer';

  @override
  String get settingsLedNotifications => 'Notifiche';

  @override
  String get settingsLedIdle => 'A riposo';

  @override
  String get settingsLedEffects => 'Effetti';

  @override
  String get settingsGroupKioskSatellite => 'Kiosk Satellite';

  @override
  String get settingsMenuNavigation => 'Navigazione';

  @override
  String get settingsMenuNavigationSummary => 'Classica o Compass';

  @override
  String get navigationStyleSection => 'Stile di navigazione';

  @override
  String get navigationLayoutSection => 'Disposizione Compass';

  @override
  String get navigationOptionsSection => 'Opzioni di Compass';

  @override
  String get settingNavStyleTitle => 'Stile di navigazione';

  @override
  String get settingNavStyleDescription =>
      'Classica mantiene il menu del kiosk, la funzione trascina per aggiornare e il carosello della plancia. Con Compass scorri tra viste disposte a croce.';

  @override
  String get settingNavCompassLayoutTitle => 'Disposizione Compass';

  @override
  String get settingNavCompassLayoutViewsDescription =>
      'Fino a due viste per lato. Aggiungi più viste delle plance di Home Assistant e una per ciascun altro tipo.';

  @override
  String get settingNavCompassAnimationTitle => 'Animazione di scorrimento';

  @override
  String get settingNavCompassAnimationDescription =>
      'Riduce lo zoom per mostrare le viste circostanti, oppure scorre direttamente.';

  @override
  String get settingNavCompassPositionTitle =>
      'Mostra la posizione durante lo scorrimento';

  @override
  String get settingNavCompassPositionDescription =>
      'Una piccola mappa che indica dove ti trovi.';

  @override
  String get settingNavCompassReturnMinutesTitle => 'Torna al centro';

  @override
  String get settingNavCompassReturnMinutesDescription =>
      'Torna alla vista centrale dopo questo tempo senza tocchi. Imposta 0 per restare sulla vista.';

  @override
  String get settingNavCompassMenuItemsTitle => 'Elementi del menu';

  @override
  String get settingNavQuickControlsItemsDescription =>
      'Ciò che mostra la vista Controlli rapidi. In comune con il menu del kiosk.';

  @override
  String get navigationClassic => 'Classica';

  @override
  String get navigationCompass => 'Compass';

  @override
  String get navigationZoom => 'Zoom';

  @override
  String get navigationSlide => 'Scorrimento';

  @override
  String get compassClassicViewHint =>
      'Vista di Home Assistant con il menu del kiosk.';

  @override
  String get compassCompassHint => 'Scorri tra viste disposte a croce.';

  @override
  String get compassLayoutViewsHint =>
      'Fino a due viste per lato. Aggiungi più viste delle plance di Home Assistant e una per ciascun altro tipo. Tocca una vista per cambiarla, anche quella centrale.';

  @override
  String get compassOffNote =>
      'Trascina per aggiornare, il carosello della plancia e lo scorrimento dal bordo che apre il menu del kiosk sono disattivati mentre Compass è attivo.';

  @override
  String get settingOffUnderCompass =>
      'Disattivato mentre la navigazione Compass è attiva.';

  @override
  String get compassQuickControlsView => 'Controlli rapidi';

  @override
  String get compassHomeDashboard => 'Home Assistant';

  @override
  String get compassAppLauncher => 'Launcher app';

  @override
  String get compassCenter => 'Centro';

  @override
  String get compassAddTile => 'Aggiungi';

  @override
  String get compassAddView => 'Aggiungi vista';

  @override
  String get compassMoveIn => 'Avvicina';

  @override
  String get compassMoveOut => 'Allontana';

  @override
  String get compassReplace => 'Sostituisci';

  @override
  String get compassRemove => 'Rimuovi';

  @override
  String get compassChange => 'Cambia';

  @override
  String get compassSideUp => 'In alto';

  @override
  String get compassSideRight => 'A destra';

  @override
  String get compassSideDown => 'In basso';

  @override
  String get compassSideLeft => 'A sinistra';

  @override
  String compassFirstView(String side) {
    return '$side, prima vista';
  }

  @override
  String compassSecondView(String side) {
    return '$side, seconda vista';
  }

  @override
  String get compassAddAbove => 'Aggiungi una vista sopra';

  @override
  String get compassAddBelow => 'Aggiungi una vista sotto';

  @override
  String get compassAddLeft => 'Aggiungi una vista a sinistra';

  @override
  String get compassAddRight => 'Aggiungi una vista a destra';

  @override
  String get compassChangeCenter => 'Cambia la vista centrale';

  @override
  String compassReplaceTitle(String name) {
    return 'Sostituisci $name';
  }

  @override
  String get compassKindDashboard => 'Plancia di Home Assistant';

  @override
  String get compassKindDashboardHint =>
      'Qualsiasi vista, Pagine personalizzate e pagine delle app';

  @override
  String get compassKindTaken => 'Già presente';

  @override
  String get compassKindUnavailable => 'Non configurato su questo kiosk';

  @override
  String get compassKioskLocked => 'Kiosk bloccato';

  @override
  String get compassQuickControls => 'Controlli rapidi';

  @override
  String get compassOpen => 'Apri';

  @override
  String get compassStateOn => 'Attivo';

  @override
  String get compassStateOff => 'Non attivo';

  @override
  String get compassHoldMode => 'Modalità pausa';

  @override
  String get settingsMenuGroundControl => 'Ground Control';

  @override
  String get settingsMenuGroundControlFeatures => 'Voice Match e Vision Match';

  @override
  String get settingAdaptiveBrightnessTitle => 'Luminosità adattiva';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Riduce la luminosità dello schermo man mano che la stanza si fa più buia, usando il sensore di luce ambientale.';

  @override
  String get settingAdaptiveUseEntityTitle =>
      'Usa un\'entità di Home Assistant';

  @override
  String get settingAdaptiveUseEntityDescription =>
      'Legge il livello di luce della stanza da un sensore di Home Assistant.';

  @override
  String get settingAdaptiveLightEntityTitle => 'Entità del sensore di luce';

  @override
  String get settingAdaptiveLightEntityDescription =>
      'Il sensore di Home Assistant che rileva il livello di luce in lux.';

  @override
  String get settingAdaptiveMinBrightnessTitle => 'Luminosità minima';

  @override
  String get settingAdaptiveMinBrightnessDescription =>
      'Luminosità dello schermo in una stanza buia.';

  @override
  String get settingAdaptiveMaxBrightnessTitle => 'Luminosità massima';

  @override
  String get settingAdaptiveMaxBrightnessDescription =>
      'Luminosità dello schermo in una stanza luminosa.';

  @override
  String get settingAdaptiveDarkLuxTitle => 'Stanza buia (lx)';

  @override
  String get settingAdaptiveDarkLuxDescription =>
      'Con questo livello di luce o meno, lo schermo resta alla Luminosità minima.';

  @override
  String get settingAdaptiveBrightLuxTitle => 'Stanza luminosa (lx)';

  @override
  String get settingAdaptiveBrightLuxDescription =>
      'Con questo livello di luce o più, lo schermo resta alla Luminosità massima.';

  @override
  String get screenAudioAdaptiveHint =>
      'Segue la luce della stanza con il sensore di luce ambientale';

  @override
  String get screenAudioAdaptiveNote =>
      'Livello in una stanza luminosa. La luminosità adattiva lo riduce a partire da qui.';

  @override
  String get screenAudioAdaptiveOwns => 'La luminosità adattiva è attiva.';

  @override
  String get screenAudioNoSensor =>
      'Questo dispositivo non ha un sensore di luce ambientale.';

  @override
  String get screenAudioAmbientLight => 'Luce ambientale';

  @override
  String get screenAudioAmbientHelp =>
      'Il valore letto in questo momento dal sensore di luce ambientale.';

  @override
  String get screenAudioNoReading => 'Ancora nessuna lettura';

  @override
  String screenAudioLux(String lux) {
    return '$lux lx';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux lx (ultimo valore noto)';
  }

  @override
  String get screenAudioSetsMaximum =>
      'Imposta la Luminosità massima: la luminosità adattiva è attiva.';

  @override
  String get screenAudioSetsDefault => 'Imposta la Luminosità predefinita.';

  @override
  String get screenAudioBrightnessCurve => 'Curva di luminosità';

  @override
  String get screenAudioCurveHint =>
      'Trascina un punto, oppure toccalo per inserire valori esatti. La luce Screen in Home Assistant sposta il punto più alto e la curva lo segue.';

  @override
  String screenAudioCurvePoint(String number) {
    return 'Punto $number';
  }

  @override
  String get screenAudioCurveLightLevel => 'Livello di luce (lx)';

  @override
  String get screenAudioCurveBrightness => 'Luminosità (%)';

  @override
  String screenAudioCurveLuxRange(String low, String high) {
    return 'Inserisci un livello di luce tra $low e $high lx';
  }

  @override
  String screenAudioCurveLevelRange(String low, String high) {
    return 'Inserisci una luminosità da $low% a $high%';
  }

  @override
  String get settingAdaptiveVolumeTitle => 'Abilita il volume adattivo';

  @override
  String get settingAdaptiveVolumeDescription =>
      'Abbassa il volume man mano che la stanza diventa più silenziosa, usando il microfono.';

  @override
  String get settingAdaptiveVolumeAssistantTitle => 'Assistente';

  @override
  String get settingAdaptiveVolumeAssistantDescription =>
      'Risposte vocali e segnali acustici.';

  @override
  String get settingAdaptiveVolumeMediaTitle => 'Contenuti multimediali';

  @override
  String get settingAdaptiveVolumeMediaDescription =>
      'Musica e video. Impostato all\'avvio della riproduzione.';

  @override
  String get settingAdaptiveVolumeIntercomTitle => 'Interfono';

  @override
  String get settingAdaptiveVolumeIntercomDescription =>
      'Chiamate. Impostato all\'inizio di una chiamata.';

  @override
  String get settingAdaptiveVolumeCurveTitle => 'Curva del volume';

  @override
  String get settingAdaptiveVolumeCurveSliderDescription =>
      'Il volume per ogni livello di rumore della stanza, come percentuale del cursore di quel volume in Schermo e audio.';

  @override
  String get screenAudioAdaptiveVolume => 'Volume adattivo';

  @override
  String get screenAudioAdaptiveVolumeHint =>
      'Segue il rumore della stanza con il microfono';

  @override
  String get screenAudioAdaptiveVolumes => 'Volumi';

  @override
  String get screenAudioRoomNoise => 'Rumore della stanza';

  @override
  String get screenAudioRoomNoiseNote =>
      'Ciò che rileva il microfono mentre questo dispositivo è in silenzio.';

  @override
  String get screenAudioRoomNoiseHolds =>
      'La lettura resta ferma mentre questo dispositivo riproduce audio. Le variazioni nella stanza durante la riproduzione non vengono usate.';

  @override
  String get screenAudioRoomNoiseNoReading =>
      'Se non c\'è alcuna lettura, attiva il volume adattivo o il rilevamento della parola di attivazione e verifica che il microfono non sia silenziato.';

  @override
  String screenAudioDbfs(String level) {
    return '$level dBFS';
  }

  @override
  String get screenAudioVolumeCurveSliderHint =>
      'Trascina un punto, oppure toccalo per inserire valori esatti. Le percentuali si applicano ai cursori del volume dell\'assistente, dei contenuti multimediali e dell\'interfono in Schermo e audio: al 100% il suono è al livello del cursore, al 50% è come con il cursore a metà.';

  @override
  String get screenAudioVolumeCurveNoise => 'Rumore della stanza (dBFS)';

  @override
  String get screenAudioVolumeCurveAssistant => 'Assistente (%)';

  @override
  String get screenAudioVolumeCurveMedia => 'Contenuti multimediali (%)';

  @override
  String get screenAudioVolumeCurveIntercom => 'Interfono (%)';

  @override
  String screenAudioVolumeCurveNoiseRange(String low, String high) {
    return 'Inserisci un livello di rumore tra $low e $high dBFS';
  }

  @override
  String screenAudioVolumeCurveLevelRange(String low, String high) {
    return 'Inserisci un volume da $low% a $high%';
  }

  @override
  String get screenAudioVolumeTest => 'Prova del volume';

  @override
  String get screenAudioVolumeTestAssistant =>
      'Prova il volume dell\'assistente';

  @override
  String get screenAudioVolumeTestAssistantHint =>
      'Riproduce un annuncio di Voice Satellite al volume dell\'assistente. Richiede l\'integrazione Voice Satellite configurata in Home Assistant.';

  @override
  String get screenAudioVolumeTestMedia =>
      'Prova il volume dei contenuti multimediali';

  @override
  String get screenAudioVolumeTestMediaHint =>
      'Riproduce un annuncio ESPHome al volume dei contenuti multimediali. Richiede che Annunci sia attivo in ESPHome.';

  @override
  String get screenAudioVolumeTestMessage =>
      'Ecco il volume attuale di un annuncio.';

  @override
  String get settingAudioMicDeviceTitle => 'Microfono';

  @override
  String get settingAudioMicDeviceDescription =>
      'Il microfono usato dal rilevamento della parola di attivazione e dalle interazioni vocali.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Altoparlante';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Uscita per i suoni di Voice Satellite; la riproduzione multimediale segue l\'uscita audio di sistema.';

  @override
  String get screenAudioDevices => 'Dispositivi audio';

  @override
  String get screenAudioSelectedDevice => 'Dispositivo selezionato';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (non connesso)';
  }

  @override
  String get settingEqualizerEnabledTitle => 'Abilita l\'equalizzatore';

  @override
  String get settingEqualizerEnabledDescription =>
      'Modella il suono di musica, assistente, segnali acustici e interfono. I suoni dei video e della plancia non vengono equalizzati.';

  @override
  String get settingEqualizerBand1Title => '100 Hz';

  @override
  String get settingEqualizerBand1Description =>
      'Bassi. Se li aumenti, gli altoparlanti piccoli distorcono presto.';

  @override
  String get settingEqualizerBand2Title => '300 Hz';

  @override
  String get settingEqualizerBand2Description =>
      'Medio-bassi. Attenuandoli si elimina un suono inscatolato o rimbombante.';

  @override
  String get settingEqualizerBand3Title => '1 kHz';

  @override
  String get settingEqualizerBand3Description =>
      'Medi, dove si concentra gran parte della voce.';

  @override
  String get settingEqualizerBand4Title => '3 kHz';

  @override
  String get settingEqualizerBand4Description =>
      'Medio-alti. Aumentandoli il parlato diventa più chiaro.';

  @override
  String get settingEqualizerBand5Title => '10 kHz';

  @override
  String get settingEqualizerBand5Description => 'Alti.';

  @override
  String get settingEqualizerPreampTitle => 'Preamplificatore automatico';

  @override
  String get settingEqualizerPreampDescription =>
      'Abbassa il livello in base all\'aumento più alto, così l\'altoparlante non distorce e la cancellazione dell\'eco continua a funzionare.';

  @override
  String get screenAudioEqualizer => 'Equalizzatore';

  @override
  String get screenAudioEqualizerHint => 'Bassi, medi, alti, preamplificatore';

  @override
  String get settingMicCaptureModeTitle => 'Modalità di acquisizione';

  @override
  String get settingMicCaptureModeDescription =>
      'Scegli Comunicazione vocale se qui il microfono resta muto o si interrompe dopo che il kiosk ha riprodotto un suono. Alcuni dispositivi registrano correttamente solo tramite il percorso audio delle chiamate.';

  @override
  String get settingMicSoftwareEchoCancellationTitle =>
      'Cancellazione dell\'eco';

  @override
  String get settingMicSoftwareEchoCancellationDescription =>
      'Rimuove dal microfono i suoni emessi dal kiosk, così né il rilevamento della parola di attivazione né l\'assistente li sentono. Lasciala attiva, a meno che un microfono con cancellazione dell\'eco integrata non suoni peggio con questa opzione.';

  @override
  String get settingMicEchoCancellationMethodTitle =>
      'Metodo di cancellazione dell\'eco';

  @override
  String get settingMicEchoCancellationMethodDescription =>
      'Automatico prova GTCRN mentre il kiosk riproduce suoni e passa ad AEC3 se rimane troppo eco. Scegli Automatico per ripetere la prova.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Riduzione del rumore';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Elimina il fruscio del microfono. Modifica ciò che sente il rilevamento della parola di attivazione, quindi attivala per un microfono che produce fruscio.';

  @override
  String get settingMicChannelTitle => 'Canale del microfono';

  @override
  String get settingMicChannelDescription =>
      'I microfoni multicanale spesso riservano un canale al riconoscimento vocale; sceglierlo può migliorare il rilevamento.';

  @override
  String get settingMicGainDbTitle => 'Guadagno del microfono';

  @override
  String get settingMicGainDbDescription =>
      'Amplifica o attenua il segnale del microfono prima di qualsiasi elaborazione. Punta a un livello vicino a 0,05 nel test della parola di attivazione; un guadagno eccessivo distorce la voce e peggiora il rilevamento.';

  @override
  String get settingMicCaptureFormatTitle => 'Formato di acquisizione';

  @override
  String get settingMicCaptureFormatDescription =>
      'Scegli Stereo 48 kHz se il microfono funziona in altre app ma non qui: alcune schede audio registrano solo in quel formato e l\'app lo converte da sé.';

  @override
  String get screenAudioMicrophoneSettings => 'Impostazioni del microfono';

  @override
  String get screenAudioMicrophoneHint =>
      'Cancellazione dell\'eco, rumore, guadagno, formato, livello in tempo reale';

  @override
  String get screenAudioMicrophoneNote =>
      'Regola l\'acquisizione in base al microfono e alla stanza. Dopo aver modificato queste impostazioni, prova le parole di attivazione e le interazioni vocali.';

  @override
  String get screenAudioAutomaticDefault => 'Automatico (predefinito)';

  @override
  String get screenAudioStereo => 'Stereo 48 kHz';

  @override
  String get screenAudioCaptureRawMicrophone =>
      'Microfono non elaborato (predefinito)';

  @override
  String get screenAudioCaptureVoiceCommunication => 'Comunicazione vocale';

  @override
  String get screenAudioEchoMethodGtcrnDetected => 'GTCRN (rilevato)';

  @override
  String get screenAudioEchoMethodAec3Detected => 'AEC3 (rilevato)';

  @override
  String get screenAudioDownmix => 'Mix dei canali (predefinito)';

  @override
  String screenAudioChannel(String channel) {
    return 'Canale $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return 'Canale $channel (non presente su questo microfono)';
  }

  @override
  String get screenAudioMicrophoneLevel => 'Livello del microfono';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      'Parla dal punto in cui usi il dispositivo; regola il guadagno finché i picchi della voce normale non arrivano circa alla fine della zona verde.';

  @override
  String get settingBrowserCutoutModeTitle => 'Ritaglio della fotocamera';

  @override
  String get settingBrowserCutoutModeDescription =>
      'Cosa fare con l\'area dello schermo intorno al ritaglio o al foro della fotocamera. Scegli Evita il ritaglio se la fotocamera copre i pulsanti nella parte superiore della plancia.';

  @override
  String get settingScreenOrientationTitle => 'Orientamento dello schermo';

  @override
  String get settingScreenOrientationDescription =>
      'Forza lo schermo in un unico orientamento. Usalo su un dispositivo senza sensore di rotazione o montato in un modo che il sensore interpreta male.';

  @override
  String get settingScreenHideStatusBarTitle => 'Nascondi la barra di stato';

  @override
  String get settingScreenHideStatusBarDescription =>
      'Disattiva per mantenere l\'orologio e le icone di notifica nella parte superiore dello schermo. La modalità kiosk la nasconde sempre.';

  @override
  String get settingScreenHideNavigationBarTitle =>
      'Nascondi la barra di navigazione';

  @override
  String get settingScreenHideNavigationBarDescription =>
      'Disattiva per mantenere sullo schermo i pulsanti di navigazione e, sui tablet, la barra delle applicazioni. La modalità kiosk la nasconde sempre.';

  @override
  String get settingScreenShowOnLockScreenTitle =>
      'Mostra sopra la schermata di blocco';

  @override
  String get settingScreenShowOnLockScreenDescription =>
      'Mostra la plancia sopra una schermata di blocco con PIN, sequenza o password. Il resto del dispositivo rimane bloccato.';

  @override
  String get settingKeepScreenOnTitle => 'Mantieni lo schermo acceso';

  @override
  String get settingKeepScreenOnDescription =>
      'Impedisce al sistema operativo di spegnere lo schermo.';

  @override
  String get settingSetBrightnessOnLaunchTitle =>
      'Imposta la luminosità all\'avvio';

  @override
  String get settingSetBrightnessOnLaunchDescription =>
      'Applica la luminosità predefinita a ogni avvio dell\'app.';

  @override
  String get settingDefaultBrightnessTitle => 'Luminosità predefinita';

  @override
  String get settingDefaultBrightnessDescription =>
      'Luminosità dello schermo applicata all\'avvio dell\'app. Spostando il cursore viene applicata subito.';

  @override
  String get screenAudioScreen => 'Schermo';

  @override
  String get screenAudioCutoutAlways => 'Usa l\'area del ritaglio';

  @override
  String get screenAudioCutoutShort => 'Solo bordi corti';

  @override
  String get screenAudioCutoutDefault => 'Predefinito di sistema';

  @override
  String get screenAudioCutoutNever => 'Evita il ritaglio';

  @override
  String get screenAudioAutomatic => 'Automatico';

  @override
  String get screenAudioLandscape => 'Orizzontale';

  @override
  String get screenAudioReverseLandscape => 'Orizzontale capovolto';

  @override
  String get screenAudioPortrait => 'Verticale';

  @override
  String get screenAudioReversePortrait => 'Verticale capovolto';

  @override
  String get screenAudioPermission => 'Autorizzazione';

  @override
  String get screenAudioBrightnessFallback =>
      'La luminosità usa un metodo alternativo';

  @override
  String get screenAudioBrightnessPermission =>
      'Senza l\'autorizzazione \"Modifica impostazioni di sistema\", le modifiche alla luminosità oscurano solo questa app invece di impostare la luminosità effettiva dello schermo.';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      'Senza l\'autorizzazione \"Modifica impostazioni di sistema\", le modifiche alla luminosità oscurano solo l\'app invece di impostare la luminosità effettiva dello schermo.';

  @override
  String get screenAudioAlwaysOn => 'Schermo sempre attivo';

  @override
  String get screenAudioAlwaysOnClock =>
      'Questo dispositivo mantiene acceso un orologio attenuato';

  @override
  String get screenAudioAlwaysOnHelp =>
      'Spegnere lo schermo mette il dispositivo in sospensione, ma la funzione Schermo sempre attivo riaccende la schermata di blocco e nessuna app può impedirlo. Disattiva \"Mostra sempre ora e informazioni\" nelle impostazioni di Android, in Display, vicino alle opzioni della schermata di blocco; alcune ROM la chiamano always-on display. L\'entità schermo di Home Assistant resta non disponibile finché non lo fai.';

  @override
  String get settingMediaVolumeTitle => 'Volume dei contenuti multimediali';

  @override
  String get settingMediaVolumeDescription =>
      'Musica e video vengono riprodotti a questa percentuale del volume principale. Il volume del lettore Sendspin in Music Assistant sposta questo cursore.';

  @override
  String get settingAssistantVolumeTitle => 'Volume dell\'assistente';

  @override
  String get settingAssistantVolumeDescription =>
      'Risposte vocali e segnali acustici vengono riprodotti a questa percentuale del volume principale, indipendentemente dal volume dei contenuti multimediali.';

  @override
  String get settingIntercomVolumeTitle => 'Volume dell\'interfono';

  @override
  String get settingIntercomVolumeDescription =>
      'La voce e gli annunci dell\'altro kiosk vengono riprodotti a questa percentuale del volume principale.';

  @override
  String get screenAudioVolume => 'Volume audio';

  @override
  String get screenAudioMasterVolume => 'Volume principale';

  @override
  String get screenAudioMasterHelp =>
      'Il volume del dispositivo. I volumi di contenuti multimediali, interfono e assistente si regolano in proporzione a questo.';

  @override
  String get settingScreensaverBlackHideExtrasTitle =>
      'Nascondi tutti gli elementi aggiuntivi';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      'Mantiene lo schermo completamente nero: niente orologio piccolo, entità di A colpo d\'occhio o altri elementi sovrapposti.';

  @override
  String get screensaverBlackSection => 'Salvaschermo nero';

  @override
  String get settingScreensaverCelestialLocationTitle => 'Posizione';

  @override
  String get settingScreensaverCelestialLocationDescription =>
      'Il punto da cui si osserva il cielo.';

  @override
  String get settingScreensaverCelestialEntityTitle => 'Entità';

  @override
  String get settingScreensaverCelestialEntityDescription =>
      'Una persona, un localizzatore di dispositivi o una zona con una posizione.';

  @override
  String get settingScreensaverCelestialCoordinatesTitle => 'Coordinate';

  @override
  String get settingScreensaverCelestialCoordinatesDescription =>
      'Latitudine e longitudine, ad esempio 40.71, -74.01.';

  @override
  String get settingScreensaverCelestialTerrainTitle => 'Paesaggio';

  @override
  String get settingScreensaverCelestialTerrainDescription =>
      'Il terreno lungo l\'orizzonte.';

  @override
  String get settingScreensaverCelestialFollowDeviceTitle =>
      'Punta verso il cielo';

  @override
  String get settingScreensaverCelestialFollowDeviceDescription =>
      'Solleva il dispositivo e il cielo sullo schermo ruota di conseguenza, così puoi riconoscere ciò che stai guardando. Richiede un sensore bussola.';

  @override
  String get settingScreensaverCelestialDaytimeTitle => 'Cielo diurno';

  @override
  String get settingScreensaverCelestialDaytimeDescription =>
      'Schiarisce il cielo e attenua le stelle mentre il Sole è sopra l\'orizzonte. Disattiva per mostrare il cielo notturno tutto il giorno.';

  @override
  String get settingScreensaverCelestialMilkyWayTitle => 'Via Lattea';

  @override
  String get settingScreensaverCelestialMilkyWayDescription =>
      'Mostra il bagliore della nostra galassia nel cielo notturno.';

  @override
  String get settingScreensaverCelestialPlanetsTitle => 'Pianeti';

  @override
  String get settingScreensaverCelestialPlanetsDescription =>
      'Mostra i pianeti nella posizione in cui si trovano stanotte.';

  @override
  String get settingScreensaverCelestialDeepSkyTitle => 'Galassie e nebulose';

  @override
  String get settingScreensaverCelestialDeepSkyDescription =>
      'Mostra la Galassia di Andromeda, la Nebulosa di Orione e altri oggetti visibili senza telescopio.';

  @override
  String get settingScreensaverCelestialLightPollutionTitle =>
      'Inquinamento luminoso';

  @override
  String get settingScreensaverCelestialLightPollutionDescription =>
      'Simula il bagliore delle luci cittadine. Valori più alti nascondono le stelle più deboli e la Via Lattea.';

  @override
  String get settingScreensaverCelestialTwinkleTitle => 'Stelle scintillanti';

  @override
  String get settingScreensaverCelestialTwinkleDescription =>
      'Fa scintillare le stelle, soprattutto vicino all\'orizzonte. Disattiva per risparmiare energia.';

  @override
  String get settingScreensaverCelestialLargeMoonTitle => 'Luna più grande';

  @override
  String get settingScreensaverCelestialLargeMoonDescription =>
      'Disegna la Luna al triplo delle sue dimensioni reali e il Sole al doppio, così la fase si vede facilmente.';

  @override
  String get settingScreensaverCelestialLinesTitle =>
      'Linee delle costellazioni';

  @override
  String get settingScreensaverCelestialLinesDescription =>
      'Collega le stelle di ogni costellazione.';

  @override
  String get settingScreensaverCelestialConstellationNamesTitle =>
      'Nomi delle costellazioni';

  @override
  String get settingScreensaverCelestialConstellationNamesDescription =>
      'Mostra i nomi delle costellazioni. Ingrandendo ne compaiono altri.';

  @override
  String get settingScreensaverCelestialNamesTitle =>
      'Nomi di stelle e pianeti';

  @override
  String get settingScreensaverCelestialNamesDescription =>
      'Mostra i nomi del Sole, della Luna, dei pianeti, delle stelle più luminose e delle galassie. Ingrandendo, più stelle ricevono un nome.';

  @override
  String get settingScreensaverCelestialCompassTitle => 'Punti cardinali';

  @override
  String get settingScreensaverCelestialCompassDescription =>
      'Segna nord, est, sud e ovest sull\'orizzonte.';

  @override
  String get settingScreensaverCelestialLabelScaleTitle =>
      'Dimensione delle etichette';

  @override
  String get settingScreensaverCelestialLabelScaleDescription =>
      'Ridimensiona le etichette nel cielo dal 50 al 200 percento.';

  @override
  String get settingScreensaverCelestialControlCoordinatesTitle => 'Posizione';

  @override
  String get settingScreensaverCelestialControlCoordinatesDescription =>
      'Mostra la latitudine e la longitudine da cui si osserva il cielo.';

  @override
  String get settingScreensaverCelestialControlAzimuthTitle => 'Azimut';

  @override
  String get settingScreensaverCelestialControlAzimuthDescription =>
      'Mostra la direzione della bussola verso cui è rivolto il centro dello schermo.';

  @override
  String get settingScreensaverCelestialControlAltitudeTitle => 'Altezza';

  @override
  String get settingScreensaverCelestialControlAltitudeDescription =>
      'Mostra quanto è alto sopra l\'orizzonte il centro dello schermo.';

  @override
  String get settingScreensaverCelestialControlFovTitle => 'Campo visivo';

  @override
  String get settingScreensaverCelestialControlFovDescription =>
      'Mostra quanta parte del cielo copre lo schermo, in gradi.';

  @override
  String get settingScreensaverCelestialControlTimeTitle => 'Ora';

  @override
  String get settingScreensaverCelestialControlTimeDescription =>
      'Mostra l\'ora del cielo, con un pulsante Adesso dopo un timelapse.';

  @override
  String get settingScreensaverCelestialControlTimelapseTitle => 'Timelapse';

  @override
  String get settingScreensaverCelestialControlTimelapseDescription =>
      'Accelera il tempo per vedere il cielo ruotare. Tocca per cambiare la velocità.';

  @override
  String get settingScreensaverCelestialControlPointAtSkyTitle =>
      'Interruttore Punta verso il cielo';

  @override
  String get settingScreensaverCelestialControlPointAtSkyDescription =>
      'Attiva e disattiva Punta verso il cielo. Compare solo sui dispositivi con bussola.';

  @override
  String get settingScreensaverCelestialControlMoonPhaseTitle => 'Fase lunare';

  @override
  String get settingScreensaverCelestialControlMoonPhaseDescription =>
      'Mostra la fase della Luna e quanta parte ne è illuminata.';

  @override
  String get settingScreensaverCelestialControlScaleTitle =>
      'Dimensione dei controlli';

  @override
  String get settingScreensaverCelestialControlScaleDescription =>
      'Ridimensiona i controlli dal 50 al 200 percento.';

  @override
  String get screensaverModeCelestial => 'Celeste';

  @override
  String get screensaverCelestialTerrainHills => 'Colline';

  @override
  String get screensaverCelestialTerrainMountains => 'Montagne';

  @override
  String get screensaverCelestialTerrainPlains => 'Pianura';

  @override
  String get screensaverCelestialTerrainNone => 'Nessuno';

  @override
  String get screensaverCelestialLocationGps => 'GPS';

  @override
  String get screensaverCelestialLocationHaHome => 'Casa di Home Assistant';

  @override
  String get screensaverCelestialLocationHaEntity => 'Entità di Home Assistant';

  @override
  String get screensaverCelestialLocationManual => 'Manuale';

  @override
  String get screensaverCelestialCurrentLocation => 'Posizione attuale';

  @override
  String get screensaverCelestialNoGpsReceiver =>
      'Questo dispositivo non ha un ricevitore GPS.';

  @override
  String get screensaverCelestialLocationPermission =>
      'Autorizzazione alla posizione non concessa.';

  @override
  String get screensaverCelestialNoGpsFix => 'Ancora nessuna posizione GPS.';

  @override
  String get screensaverCelestialNoHomeZone =>
      'Home Assistant non ha una zona casa.';

  @override
  String get screensaverCelestialHaNotConnected =>
      'Home Assistant non è connesso.';

  @override
  String get screensaverCelestialPickEntity =>
      'Scegli un\'entità con una posizione.';

  @override
  String get screensaverCelestialEntityNoLocation =>
      'Questa entità non ha una posizione.';

  @override
  String get screensaverCelestialPage => 'Salvaschermo celeste';

  @override
  String get screensaverCelestialSummary =>
      'Posizione, paesaggio, cielo, etichette, controlli';

  @override
  String get screensaverCelestialSkyGroup => 'Cielo';

  @override
  String get screensaverCelestialLabelsGroup => 'Etichette';

  @override
  String get screensaverCelestialControlsGroup => 'Controlli';

  @override
  String get screensaverCelestialLocationGrantMissing =>
      'Senza questa autorizzazione non è possibile leggere il ricevitore GPS e il cielo non ha una posizione.';

  @override
  String get screensaverCelestialLocationGrantReady =>
      'Il cielo può seguire il ricevitore GPS.';

  @override
  String get screensaverCelestialCoordinatesInvalid =>
      'Inserisci latitudine e longitudine, ad esempio 40.71, -74.01';

  @override
  String get screensaverCelestialNoLocation =>
      'Scegli una posizione in Impostazioni > Salvaschermo > Celeste.';

  @override
  String get screensaverCelestialWaitingForGps =>
      'In attesa della posizione GPS...';

  @override
  String get screensaverCelestialDoubleTapHint =>
      'Tocca due volte per chiudere';

  @override
  String get screensaverCelestialCalibrate =>
      'Muovi il dispositivo disegnando un otto per calibrare la bussola.';

  @override
  String get celestialSun => 'Sole';

  @override
  String get celestialMoon => 'Luna';

  @override
  String get celestialMercury => 'Mercurio';

  @override
  String get celestialVenus => 'Venere';

  @override
  String get celestialMars => 'Marte';

  @override
  String get celestialJupiter => 'Giove';

  @override
  String get celestialSaturn => 'Saturno';

  @override
  String get celestialUranus => 'Urano';

  @override
  String get celestialNeptune => 'Nettuno';

  @override
  String get celestialAndromedaGalaxy => 'Galassia di Andromeda';

  @override
  String get celestialTriangulumGalaxy => 'Galassia del Triangolo';

  @override
  String get celestialLargeMagellanicCloud => 'Grande Nube di Magellano';

  @override
  String get celestialSmallMagellanicCloud => 'Piccola Nube di Magellano';

  @override
  String get celestialOrionNebula => 'Nebulosa di Orione';

  @override
  String get celestialLagoonNebula => 'Nebulosa Laguna';

  @override
  String get celestialCarinaNebula => 'Nebulosa della Carena';

  @override
  String get celestialPleiades => 'Pleiadi';

  @override
  String get celestialBeehiveCluster => 'Ammasso del Presepe';

  @override
  String get celestialDoubleCluster => 'Doppio Ammasso di Perseo';

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
  String get celestialCompassWest => 'O';

  @override
  String get celestialCompassNorthEast => 'NE';

  @override
  String get celestialCompassSouthEast => 'SE';

  @override
  String get celestialCompassSouthWest => 'SO';

  @override
  String get celestialCompassNorthWest => 'NO';

  @override
  String get celestialAzimuthShort => 'Az';

  @override
  String get celestialAltitudeShort => 'Alt';

  @override
  String get celestialFovShort => 'FOV';

  @override
  String get celestialNow => 'Adesso';

  @override
  String get celestialMoonNew => 'Luna nuova';

  @override
  String get celestialMoonWaxingCrescent => 'Luna crescente';

  @override
  String get celestialMoonFirstQuarter => 'Primo quarto';

  @override
  String get celestialMoonWaxingGibbous => 'Gibbosa crescente';

  @override
  String get celestialMoonFull => 'Luna piena';

  @override
  String get celestialMoonWaningGibbous => 'Gibbosa calante';

  @override
  String get celestialMoonLastQuarter => 'Ultimo quarto';

  @override
  String get celestialMoonWaningCrescent => 'Luna calante';

  @override
  String get settingScreensaverClockStyleTitle => 'Stile';

  @override
  String get settingScreensaverClockStyleDescription =>
      'Come viene disegnato l\'orologio.';

  @override
  String get settingScreensaverClockVerticalTitle => 'Modalità verticale';

  @override
  String get settingScreensaverClockVerticalDescription =>
      'Dispone le ore sopra i minuti, per gli schermi in verticale.';

  @override
  String get settingScreensaverClockFontTitle => 'Famiglia di caratteri';

  @override
  String get settingScreensaverClockFontDescription =>
      'Il carattere con cui viene disegnato l\'orologio.';

  @override
  String get settingScreensaverClockFontWeightTitle => 'Spessore del carattere';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      'Lo spessore con cui vengono disegnate le cifre dell\'orologio. Predefinito usa lo spessore proprio di ogni carattere.';

  @override
  String get settingScreensaverClock24hTitle => 'Formato 24 ore';

  @override
  String get settingScreensaverClock24hDescription =>
      'Mostra l\'ora nel formato 24 ore invece di AM/PM.';

  @override
  String get settingScreensaverClockSecondsTitle => 'Mostra i secondi';

  @override
  String get settingScreensaverClockSecondsDescription =>
      'Include i secondi nell\'orologio.';

  @override
  String get settingScreensaverClockDateTitle => 'Mostra la data';

  @override
  String get settingScreensaverClockDateDescription =>
      'Mostra il giorno della settimana e la data sotto l\'orologio.';

  @override
  String get settingScreensaverClockScaleTitle => 'Dimensione dell\'orologio';

  @override
  String get settingScreensaverClockScaleDescription =>
      'Ridimensiona l\'orologio dal 50 al 300 percento per questo schermo.';

  @override
  String get settingScreensaverClockColorTitle => 'Colore dell\'orologio';

  @override
  String get settingScreensaverClockColorDescription =>
      'Il colore del testo dell\'orologio.';

  @override
  String get settingScreensaverClockBgColorTitle => 'Colore di sfondo';

  @override
  String get settingScreensaverClockBgColorDescription =>
      'Il colore dietro l\'orologio.';

  @override
  String get settingScreensaverClockBackgroundTitle => 'Foto di sfondo';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      'Mostra una foto dietro l\'orologio invece del colore pieno. Il percorso di un\'immagine sul dispositivo o l\'URL di un\'immagine che il dispositivo scarica.';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle =>
      'Aggiorna lo sfondo da URL';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      'Minuti tra un download e l\'altro di uno sfondo da URL. Con 0 viene scaricato solo quando l\'impostazione viene salvata.';

  @override
  String get settingScreensaverFlipDigitColorTitle => 'Colore delle cifre';

  @override
  String get settingScreensaverFlipDigitColorDescription =>
      'Il colore delle cifre a palette.';

  @override
  String get settingScreensaverFlipBgColorTitle => 'Colore delle palette';

  @override
  String get settingScreensaverFlipBgColorDescription =>
      'Il colore delle palette.';

  @override
  String get settingScreensaverFlipBackdropColorTitle => 'Colore di sfondo';

  @override
  String get settingScreensaverFlipBackdropColorDescription =>
      'Il colore dietro le palette.';

  @override
  String get settingScreensaverRollerDigitColorTitle => 'Colore delle cifre';

  @override
  String get settingScreensaverRollerDigitColorDescription =>
      'Il colore delle cifre a rullo.';

  @override
  String get settingScreensaverRollerBgColorTitle => 'Colore di sfondo';

  @override
  String get settingScreensaverRollerBgColorDescription =>
      'Il colore dietro le cifre.';

  @override
  String get settingScreensaverHandNumbersTitle => 'Numeri';

  @override
  String get settingScreensaverHandNumbersDescription =>
      'Quali ore il quadrante mostra come numeri.';

  @override
  String get settingScreensaverHandSecondsTitle =>
      'Mostra la lancetta dei secondi';

  @override
  String get settingScreensaverHandSecondsDescription =>
      'Disegna la lancetta dei secondi sul quadrante.';

  @override
  String get settingScreensaverHandColorTitle => 'Colore dell\'orologio';

  @override
  String get settingScreensaverHandColorDescription =>
      'Il colore di lancette, numeri e tacche.';

  @override
  String get settingScreensaverHandBgColorTitle => 'Colore di sfondo';

  @override
  String get settingScreensaverHandBgColorDescription =>
      'Il colore dietro l\'orologio.';

  @override
  String get settingScreensaverClockNightTitle => 'Modalità notturna';

  @override
  String get settingScreensaverClockNightDescription =>
      'Cambia il colore dell\'orologio quando la stanza è buia.';

  @override
  String get settingScreensaverClockNightLuxTitle => 'Livello di luce';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      'Con questo livello di luce o meno, l\'orologio assume il colore notturno.';

  @override
  String get settingScreensaverClockNightColorTitle => 'Colore notturno';

  @override
  String get settingScreensaverClockNightColorDescription =>
      'Il colore dell\'orologio e dei widget al buio.';

  @override
  String get settingScreensaverClockNightBgColorTitle => 'Sfondo notturno';

  @override
  String get settingScreensaverClockNightBgColorDescription =>
      'Il colore dietro l\'orologio al buio.';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle =>
      'Nascondi la foto di sfondo';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      'Usa il colore di sfondo notturno invece della foto mentre la modalità notturna è attiva.';

  @override
  String get settingScreensaverClockNightHideWidgetsTitle =>
      'Nascondi widget e A colpo d\'occhio';

  @override
  String get settingScreensaverClockNightHideWidgetsDescription =>
      'Mostra solo l\'orologio mentre la modalità notturna è attiva.';

  @override
  String get settingScreensaverClockNightCardColorTitle =>
      'Colore notturno delle palette';

  @override
  String get settingScreensaverClockNightCardColorDescription =>
      'Il colore delle palette al buio.';

  @override
  String get screensaverClockSection => 'Salvaschermo orologio';

  @override
  String get screensaverClockHint =>
      'Stile, carattere, dimensione, colori, modalità notturna, foto di sfondo';

  @override
  String get screensaverStyleDigital => 'Orologio digitale';

  @override
  String get screensaverStyleFlip => 'Orologio a palette';

  @override
  String get screensaverStyleRoller => 'Orologio a rulli';

  @override
  String get screensaverStyleHand => 'Orologio a lancette';

  @override
  String get screensaverHandNumbersQuarters => '12, 3, 6 e 9';

  @override
  String get screensaverHandNumbersAll => 'Tutte le ore';

  @override
  String get screensaverFontDefault => 'Predefinito';

  @override
  String get screensaverFontLight => 'Sottile';

  @override
  String get screensaverFontRegular => 'Normale';

  @override
  String get screensaverFontMedium => 'Medio';

  @override
  String get screensaverFontBold => 'Grassetto';

  @override
  String get screensaverFontBlack => 'Extra grassetto';

  @override
  String get screensaverNoPhoto => 'Nessuna foto selezionata';

  @override
  String get screensaverBackgroundHint =>
      'Percorso di un\'immagine sul dispositivo o URL di un\'immagine';

  @override
  String get screensaverImageUrlError =>
      'Inserisci l\'URL completa di un\'immagine';

  @override
  String get screensaverRefreshError =>
      'Inserisci un numero intero di minuti da 0 a 1440';

  @override
  String screensaverMaxCharacters(String count) {
    return 'Usa al massimo $count caratteri';
  }

  @override
  String get settingScreensaverClockAmPmTitle => 'Mostra AM/PM';

  @override
  String get settingScreensaverClockAmPmDescription =>
      'Aggiunge AM o PM dopo l\'ora.';

  @override
  String get settingScreensaverClockNightTurnOffMinutesTitle =>
      'Spegni lo schermo di notte dopo';

  @override
  String get settingScreensaverClockNightTurnOffMinutesDescription =>
      'Spegne lo schermo quando la modalità notturna è rimasta attiva per il tempo impostato e lo riaccende quando la stanza si illumina. Imposta 0 per tenere lo schermo acceso. Richiede l\'autorizzazione Amministratore del dispositivo.';

  @override
  String get screensaverNightTurnOffWarning =>
      'Quando lo schermo si spegne davvero, subentra la gestione energetica del tablet. Molti modelli Android si comportano male in questo stato: il Wi-Fi va in sospensione o si disconnette, le entità di Home Assistant diventano non disponibili, l\'accesso alla fotocamera può essere revocato e alcuni modelli chiudono le app in background. Alcuni sensori di luce smettono anche di inviare letture a schermo spento, quindi lo schermo potrebbe non riaccendersi da solo quando la stanza si illumina. Il comportamento dipende dal produttore.\n\nL\'alternativa affidabile è Usa invece uno schermo nero. Il pannello appare altrettanto scuro e l\'app mantiene il pieno controllo.';

  @override
  String get screensaverOverlayEntity => 'Entità';

  @override
  String get screensaverOverlayNotSet => 'Non impostata';

  @override
  String get screensaverOverlayName => 'Nome';

  @override
  String get screensaverOverlayNameHelp =>
      'Lascia vuoto per usare il nome di Home Assistant.';

  @override
  String get screensaverOverlayValue => 'Valore mostrato';

  @override
  String get screensaverOverlayState => 'Stato';

  @override
  String get screensaverOverlayEntityRequired => 'Scegli un\'entità.';

  @override
  String get screensaverOverlaySearching => 'Ricerca in corso…';

  @override
  String get screensaverOverlayUnreachable =>
      'Impossibile raggiungere Home Assistant';

  @override
  String get screensaverOverlayNoAnswer => 'Il dispositivo non ha risposto.';

  @override
  String get settingScreensaverDismissOnFaceTitle =>
      'Chiudi al rilevamento di un volto';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      'Riattiva lo schermo quando qualcuno guarda il kiosk, non con il solo movimento. La fotocamera funziona solo durante il salvaschermo. ATTENZIONE: serve un volto illuminato; al buio, programma invece il rilevamento del movimento.';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle =>
      'Solo a schermo spento';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      'Mantiene visibile il salvaschermo quando viene rilevato un volto a schermo acceso. Quando lo schermo è spento, il rilevamento riattiva la plancia. Il tocco chiude comunque il salvaschermo.';

  @override
  String get settingScreensaverPostponeOnFaceTitle =>
      'Posticipa il salvaschermo al rilevamento di un volto';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      'Ritarda l\'attivazione del salvaschermo finché qualcuno guarda il kiosk. ATTENZIONE: mantiene la fotocamera sempre attiva, con in più il rilevamento dei volti e il relativo carico sulla CPU.';

  @override
  String get settingFaceSensitivityTitle => 'Sensibilità ai volti';

  @override
  String get settingFaceSensitivityDescription =>
      'Valori più alti riattivano lo schermo anche con volti più piccoli e lontani. Con 1 serve un volto vicino allo schermo; con 100 reagisce a qualsiasi volto che la fotocamera riesce a distinguere.';

  @override
  String get screensaverDetectionFacePage => 'Rilevamento dei volti';

  @override
  String get screensaverDetectionFaceHint =>
      'Chiude il salvaschermo quando qualcuno lo guarda';

  @override
  String get screensaverDetectionMotionPrecedence =>
      'Chiudi al rilevamento del movimento è attivo e ha la precedenza, quindi il rilevamento dei volti resta inattivo finché non lo disattivi.';

  @override
  String get screensaverDetectionFaceTuning =>
      'Frequenza dei fotogrammi, scelta della fotocamera e ritardo di avvio si regolano nelle impostazioni della Fotocamera.';

  @override
  String get screensaverDetectionAndroidUnsupported =>
      'Non disponibile su questa versione di Android.';

  @override
  String get screensaverDetectionX86Unsupported =>
      'Non disponibile sui dispositivi x86.';

  @override
  String get settingScreensaverFaceWhoTitle => 'Rileva i volti';

  @override
  String get settingScreensaverFaceWhoDescription =>
      'Con Persone scelte, solo le persone selezionate qui sotto chiudono o posticipano il salvaschermo.';

  @override
  String get screensaverFaceWhoOptionAnyone => 'Chiunque';

  @override
  String get screensaverFaceWhoOptionPeople => 'Persone scelte';

  @override
  String get settingScreensaverFacePeopleTitle => 'Persone';

  @override
  String get settingScreensaverFacePeopleDescription =>
      'Scegli chi può chiudere o posticipare il salvaschermo guardando il kiosk. Se non scegli nessuno, può farlo chiunque venga riconosciuto.';

  @override
  String get screensaverFacePeopleNone => 'Chiunque venga riconosciuto';

  @override
  String get screensaverGroundControlVisionMatch =>
      'Ground Control Vision Match';

  @override
  String get settingFacePreviewTitle => 'Mostra l\'anteprima della fotocamera';

  @override
  String get settingFacePreviewDescription =>
      'Mostra per qualche secondo una piccola vista rotonda in diretta della fotocamera in un angolo dello schermo quando un volto riattiva il kiosk.';

  @override
  String get settingFacePreviewSecondsTitle => 'Durata dell\'anteprima';

  @override
  String get settingFacePreviewSecondsDescription =>
      'Per quanto tempo l\'anteprima resta sullo schermo.';

  @override
  String get settingFacePreviewScaleTitle => 'Dimensione dell\'anteprima';

  @override
  String get settingFacePreviewScaleDescription =>
      'Adatta la dimensione dell\'anteprima a quella dello schermo.';

  @override
  String get settingFacePreviewPositionTitle => 'Posizione dell\'anteprima';

  @override
  String get settingFacePreviewPositionDescription =>
      'L\'angolo in cui compare l\'anteprima.';

  @override
  String get screensaverDetectionPreviewSection => 'Anteprima della fotocamera';

  @override
  String get facePreviewRecognized => 'Riconosciuto';

  @override
  String get settingScreensaverEnabledTitle => 'Salvaschermo';

  @override
  String get settingScreensaverEnabledDescription =>
      'Attenua o oscura lo schermo dopo un periodo di inattività.';

  @override
  String get settingScreensaverTimeoutSecondsTitle =>
      'Tempo di inattività (secondi)';

  @override
  String get settingScreensaverTimeoutSecondsDescription =>
      'Periodo di inattività prima che si avvii il salvaschermo.';

  @override
  String get settingScreensaverFadeTitle =>
      'Dissolvenza in entrata e in uscita';

  @override
  String get settingScreensaverFadeDescription =>
      'Il salvaschermo compare in dissolvenza sopra la plancia e scompare in dissolvenza quando viene chiuso. Non vale per i salvaschermo Contenuti multimediali di Home Assistant, Sito web e Flussi delle telecamere.';

  @override
  String get settingScreensaverModeTitle => 'Modalità del salvaschermo';

  @override
  String get settingScreensaverModeDescription =>
      'Cosa mostra il salvaschermo dopo il tempo di inattività. Attenuato abbassa solo la retroilluminazione e lascia la plancia sullo schermo.';

  @override
  String get settingScreensaverPixelShiftTitle => 'Spostamento dei pixel';

  @override
  String get settingScreensaverPixelShiftDescription =>
      'Sposta leggermente l\'immagine ogni minuto per proteggere i pannelli OLED. Non vale per il salvaschermo nero, i cui pixel sono già spenti.';

  @override
  String get settingScreensaverFollowAnimationScaleTitle =>
      'Segui le impostazioni di animazione di Android';

  @override
  String get settingScreensaverFollowAnimationScaleDescription =>
      'Mette in pausa i salvaschermo animati quando le animazioni di Android sono disattivate.';

  @override
  String get settingScreensaverDimLevelTitle => 'Livello di attenuazione';

  @override
  String get settingScreensaverDimLevelDescription =>
      'Luminosità dello schermo mentre il salvaschermo lo attenua.';

  @override
  String get settingScreensaverBrightnessEnabledTitle =>
      'Luminosità del salvaschermo';

  @override
  String get settingScreensaverBrightnessEnabledDescription =>
      'Usa una luminosità diversa mentre è visibile il salvaschermo.';

  @override
  String get settingScreensaverBrightnessLevelTitle => 'Livello di luminosità';

  @override
  String get settingScreensaverBrightnessLevelDescription =>
      'Vale per tutte le modalità tranne Attenuato e Nero.';

  @override
  String get settingScreensaverNotificationBrightnessTitle =>
      'Aumenta la luminosità per le notifiche';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      'Sospende l\'attenuazione del salvaschermo mentre è visibile una notifica.';

  @override
  String get settingScreensaverTouchBrightnessSecondsTitle =>
      'Aumenta la luminosità al tocco';

  @override
  String get settingScreensaverTouchBrightnessSecondsDescription =>
      'Sospende l\'attenuazione del salvaschermo per questo tempo dopo un tocco che non lo chiude. Imposta 0 per disattivare.';

  @override
  String get settingScreensaverScreenOffMinutesTitle =>
      'Spegni lo schermo dopo';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Spegne il pannello dello schermo quando il salvaschermo è rimasto attivo per il tempo impostato. Imposta 0 per tenere lo schermo sempre acceso. Richiede l\'autorizzazione Amministratore del dispositivo.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Riattiva sul salvaschermo';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescriptionSources =>
      'Scegli cosa riporta il salvaschermo, invece della plancia, dopo lo spegnimento dello schermo. Il conto alla rovescia di Spegni lo schermo dopo riparte da capo.';

  @override
  String get screensaverWakeSourcesAll => 'Tutti';

  @override
  String get screensaverWakeSourceMotion => 'Movimento';

  @override
  String get screensaverWakeSourceFace => 'Volto';

  @override
  String get screensaverWakeSourceProximity => 'Prossimità';

  @override
  String get screensaverWakeSourcePerson => 'Persona';

  @override
  String get screensaverWakeSourcePower => 'Tasto di accensione';

  @override
  String get screensaverWakeSourceTouch => 'Tocco';

  @override
  String get screensaverWakeSourceTouchRequires =>
      'Richiede sia \"Spegni lo schermo dopo\" sia \"Usa invece uno schermo nero\".';

  @override
  String get screensaverModeDim => 'Attenuato';

  @override
  String get screensaverModeBlack => 'Nero';

  @override
  String get screensaverModeClock => 'Orologio';

  @override
  String get screensaverModeMedia => 'Contenuti multimediali di Home Assistant';

  @override
  String get screensaverModeLocal => 'Contenuti multimediali locali';

  @override
  String get screensaverModeGallery => 'Galleria foto';

  @override
  String get screensaverModeImmich => 'Contenuti multimediali Immich';

  @override
  String get screensaverModeWebsite => 'Sito web';

  @override
  String get screensaverModeCamera => 'Flussi delle telecamere';

  @override
  String get screensaverDimSection => 'Salvaschermo attenuato';

  @override
  String get screensaverWarningTitle =>
      'ATTENZIONE: leggi prima di continuare!';

  @override
  String get screensaverScreenOffProceed => 'Spegni comunque lo schermo';

  @override
  String get screensaverAdminMissing =>
      'Non concessa, quindi lo schermo non può spegnersi.';

  @override
  String get screensaverAdminMissingRemote =>
      'Manca l\'autorizzazione Amministratore del dispositivo';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      'Senza di essa lo schermo non può essere spento. La finestra per concederla compare sullo schermo del tablet.';

  @override
  String get screensaverDimWarning =>
      'ATTENZIONE: Attenuato lascia visibile la plancia, quindi l\'ottimizzazione \"Metti in pausa la plancia durante il salvaschermo\" non verrà applicata e la plancia continuerà a usare CPU, GPU e batteria.';

  @override
  String get screensaverUnavailablePlugin =>
      'Salvaschermo del plugin non disponibile';

  @override
  String get screensaverScreenOffWarning =>
      'Quando lo schermo si spegne davvero, subentra la gestione energetica del tablet, e molti modelli Android in quello stato si comportano male: il Wi-Fi va in sospensione o si disconnette, le entità di Home Assistant diventano non disponibili, l\'accesso alla fotocamera può essere revocato e alcuni modelli chiudono senza preavviso le app in background. Cosa succede dipende dal produttore.\n\nL\'alternativa affidabile è il salvaschermo Nero con questa impostazione lasciata a 0: il pannello appare altrettanto scuro e l\'app mantiene il pieno controllo.';

  @override
  String get settingScreensaverScreenOffBlackTitle =>
      'Usa invece uno schermo nero';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      'Mostra uno schermo completamente nero con luminosità a zero invece di spegnere lo schermo. Nasconde i widget e In riproduzione. Non serve l\'autorizzazione Amministratore del dispositivo.';

  @override
  String get screensaverModeDashboard => 'Plancia di Home Assistant';

  @override
  String get settingScreensaverDashboardViewTitle => 'Vista della plancia';

  @override
  String get settingScreensaverDashboardViewDescription =>
      'La vista della plancia di Home Assistant mostrata dal salvaschermo.';

  @override
  String get settingScreensaverDashboardDoubleTapTitle =>
      'Doppio tocco per chiudere';

  @override
  String get settingScreensaverDashboardDoubleTapDescription =>
      'Il tocco singolo interagisce con la plancia invece di chiudere il salvaschermo.';

  @override
  String get settingScreensaverDashboardKioskTitle =>
      'Sostituisci la modalità kiosk di HA';

  @override
  String get settingScreensaverDashboardKioskDescription =>
      'Scegli cosa nasconde il salvaschermo, indipendentemente dalla modalità kiosk di HA.';

  @override
  String get settingScreensaverDashboardHideHeaderTitle =>
      'Nascondi l\'intestazione';

  @override
  String get settingScreensaverDashboardHideHeaderDescription =>
      'Nasconde la barra degli strumenti della plancia e le schede delle viste nel salvaschermo.';

  @override
  String get settingScreensaverDashboardHideSidebarTitle =>
      'Nascondi la barra laterale';

  @override
  String get settingScreensaverDashboardHideSidebarDescription =>
      'Nasconde la barra laterale di navigazione nel salvaschermo.';

  @override
  String get screensaverDashboardSection =>
      'Salvaschermo Plancia di Home Assistant';

  @override
  String get screensaverModeUrl => 'URL dell\'immagine';

  @override
  String get screensaverCalendarSection => 'Salvaschermo calendario';

  @override
  String get settingScreensaverCalendarViewTitle => 'Vista del calendario';

  @override
  String get settingScreensaverCalendarViewDescription =>
      'La vista del calendario con cui si apre il salvaschermo.';

  @override
  String get settingScreensaverGlanceScaleTitle => 'Dimensione della riga';

  @override
  String get settingScreensaverGlanceScaleDescription =>
      'Adatta la dimensione della riga a quella dello schermo.';

  @override
  String get settingScreensaverGlanceFontTitle => 'Tipo di carattere';

  @override
  String get settingScreensaverGlanceFontDescription =>
      'Il carattere usato per il testo della riga.';

  @override
  String get settingScreensaverGlanceFontWeightTitle =>
      'Spessore del carattere';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      'Lo spessore del testo della riga. Predefinito usa lo spessore proprio di ogni riga: normale per i nomi, semigrassetto per i valori.';

  @override
  String get settingScreensaverGlanceHideNamesTitle => 'Nascondi i nomi';

  @override
  String get settingScreensaverGlanceHideNamesDescription =>
      'Mostra solo l\'icona e il valore, con il valore più grande.';

  @override
  String get settingScreensaverGlanceBwIconsTitle => 'Icone monocromatiche';

  @override
  String get settingScreensaverGlanceBwIconsDescription =>
      'Mostra tutte le icone in grigio neutro invece che nel colore del loro stato.';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => 'Stile testo fluttuante';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      'Mostra le entità come testo fluttuante invece che in riquadri.';

  @override
  String get screensaverOverlayAppearance => 'Aspetto';

  @override
  String get settingScreensaverGlanceEnabledTitle => 'A colpo d\'occhio';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      'Mostra sul salvaschermo una riga con gli stati delle entità di Home Assistant.';

  @override
  String get settingScreensaverGlanceEntitiesTitle => 'Entità';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      'Fino a quattro entità da mostrare, ognuna con un nome personalizzato facoltativo.';

  @override
  String get settingScreensaverGlanceNowPlayingTitle =>
      'Mostra nella schermata In riproduzione';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      'Mostra la riga nella vista a schermo intero In riproduzione. Resta nascosta mentre sono visibili i testi.';

  @override
  String get screensaverOverlayShowing => 'Visibili';

  @override
  String get screensaverOverlayNone => 'Ancora nessuna';

  @override
  String get screensaverOverlayGlancePage => 'A colpo d\'occhio';

  @override
  String get screensaverOverlayGlanceHint =>
      'Entità mostrate sopra il salvaschermo';

  @override
  String get glanceUnavailable => 'Non disponibile';

  @override
  String get glanceUnknown => 'Sconosciuto';

  @override
  String get settingScreensaverImmichUrlTitle => 'Indirizzo del server';

  @override
  String get settingScreensaverImmichUrlDescription =>
      'L\'indirizzo del tuo server Immich, con la porta.';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'Chiave API';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      'Si crea in Immich in Impostazioni account → Chiavi API.';

  @override
  String get screensaverMediaImmichPage =>
      'Salvaschermo Contenuti multimediali Immich';

  @override
  String get screensaverMediaImmichHint =>
      'Server, contenuti multimediali, presentazione, metadati, filtri';

  @override
  String get screensaverMediaServerConnection => 'Connessione al server';

  @override
  String get screensaverMediaValidateFailedLog =>
      'Verifica non riuscita. Controlla nel registro dell\'app quale chiamata non è riuscita.';

  @override
  String get screensaverMediaValidateFailed => 'Verifica non riuscita.';

  @override
  String get screensaverMediaNoAnswer => 'Il dispositivo non ha risposto.';

  @override
  String get screensaverMediaAddressFirst =>
      'Inserisci prima l\'indirizzo del server.';

  @override
  String get screensaverMediaKeyFirst => 'Inserisci prima una chiave API.';

  @override
  String get screensaverMediaBadAddress =>
      'L\'indirizzo del server non è un URL valido.';

  @override
  String get screensaverMediaKeyRejected => 'La chiave API è stata rifiutata.';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'Alla chiave API manca l\'autorizzazione $scope.';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'Alla chiave API manca un\'autorizzazione: $error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return 'Il server ha risposto $status: $error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return 'Impossibile raggiungere $url.';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return 'Impossibile comunicare con il server: $error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => 'Persone';

  @override
  String get settingScreensaverImmichPeopleDescription =>
      'Mostra solo i contenuti in cui compare almeno una di queste persone.';

  @override
  String get settingScreensaverImmichExcludePeopleTitle => 'Escludi persone';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      'Salta i contenuti in cui compare almeno una di queste persone.';

  @override
  String get settingScreensaverImmichTagsTitle => 'Tag';

  @override
  String get settingScreensaverImmichTagsDescription =>
      'Mostra solo i contenuti con almeno uno di questi tag.';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => 'Escludi tag';

  @override
  String get settingScreensaverImmichExcludeTagsDescription =>
      'Salta i contenuti con almeno uno di questi tag.';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => 'Solo preferiti';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      'Mostra solo i contenuti contrassegnati come preferiti.';

  @override
  String get settingScreensaverImmichTakenWithinTitle => 'Periodo di scatto';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      'Mostra solo i contenuti scattati in questo periodo.';

  @override
  String get settingScreensaverImmichTakenFromTitle => 'Dal';

  @override
  String get settingScreensaverImmichTakenFromDescription =>
      'Salta i contenuti scattati prima di questa data.';

  @override
  String get settingScreensaverImmichTakenToTitle => 'Al';

  @override
  String get settingScreensaverImmichTakenToDescription =>
      'Salta i contenuti scattati dopo questa data. Il giorno stesso è incluso.';

  @override
  String get screensaverMediaFilters => 'Filtri';

  @override
  String get screensaverMediaAnyone => 'Chiunque';

  @override
  String get screensaverMediaAnyoneDevice => 'Chiunque.';

  @override
  String get screensaverMediaNoOne => 'Nessuno';

  @override
  String get screensaverMediaNoOneDevice => 'Nessuno.';

  @override
  String get screensaverMediaAny => 'Qualsiasi';

  @override
  String get screensaverMediaAnyDevice => 'Qualsiasi.';

  @override
  String get screensaverMediaNoTagsChosen => 'Nessun tag';

  @override
  String get screensaverMediaNoTagsChosenDevice => 'Nessun tag.';

  @override
  String get screensaverMediaNoPeople =>
      'Ancora nessuna persona con un nome. Assegna prima i nomi in Immich.';

  @override
  String get screensaverMediaNoTags =>
      'Ancora nessun tag. Creali prima in Immich.';

  @override
  String get screensaverMediaPeopleFailed => 'Impossibile elencare le persone';

  @override
  String get screensaverMediaTagsFailed => 'Impossibile elencare i tag';

  @override
  String get screensaverMediaHidden => 'Nascosto';

  @override
  String get screensaverMediaAnyTime => 'Qualsiasi data';

  @override
  String get screensaverMediaPastMonth => 'Ultimo mese';

  @override
  String get screensaverMediaPast3Months => 'Ultimi 3 mesi';

  @override
  String get screensaverMediaPastYear => 'Ultimo anno';

  @override
  String get screensaverMediaPast2Years => 'Ultimi 2 anni';

  @override
  String get screensaverMediaPast5Years => 'Ultimi 5 anni';

  @override
  String get screensaverMediaPast10Years => 'Ultimi 10 anni';

  @override
  String get screensaverMediaSince => 'Da una data';

  @override
  String get screensaverMediaTimeframe => 'Periodo';

  @override
  String get screensaverMediaToday => 'Oggi';

  @override
  String get screensaverMediaDateFormat => 'Usa il formato YYYY-MM-DD.';

  @override
  String get screensaverMediaNotDate => 'Non è una data valida.';

  @override
  String get settingScreensaverImmichMetadataTitle => 'Mostra i metadati';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      'Album, data, fotocamera e luogo sopra i contenuti.';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => 'Nome dell\'album';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription =>
      'Mostra da quale album proviene la foto.';

  @override
  String get settingScreensaverImmichMetadataDateTitle => 'Data di scatto';

  @override
  String get settingScreensaverImmichMetadataDateDescription =>
      'Mostra quando è stata scattata la foto.';

  @override
  String get settingScreensaverImmichMetadataCameraTitle =>
      'Dettagli della fotocamera';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      'Mostra lunghezza focale, apertura e ISO.';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => 'Luogo';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      'Mostra il luogo in cui è stata scattata la foto.';

  @override
  String get settingScreensaverImmichMetadataDescriptionTitle => 'Descrizione';

  @override
  String get settingScreensaverImmichMetadataDescriptionDescription =>
      'Mostra la descrizione della foto nella parte inferiore dello schermo.';

  @override
  String get settingScreensaverImmichMetadataPositionTitle =>
      'Posizione dei metadati';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      'L\'angolo in cui compaiono i dettagli.';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle =>
      'Ombra del testo';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      'Aggiunge un\'ombra al testo dei metadati per renderlo leggibile sulle foto.';

  @override
  String get settingScreensaverImmichMetadataScaleTitle =>
      'Dimensione del testo';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      'Adatta la dimensione dei dettagli della foto a quella dello schermo.';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle =>
      'Intensità della vignettatura';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      'Quanto è scura l\'ombreggiatura dietro i dettagli, per renderli leggibili sulle foto chiare. 0 la disattiva.';

  @override
  String get screensaverMediaMetadata => 'Metadati';

  @override
  String get screensaverMediaTopLeft => 'In alto a sinistra';

  @override
  String get screensaverMediaTopRight => 'In alto a destra';

  @override
  String get screensaverMediaBottomLeft => 'In basso a sinistra';

  @override
  String get screensaverMediaBottomRight => 'In basso a destra';

  @override
  String get settingScreensaverImmichIntervalTitle => 'Secondi per immagine';

  @override
  String get settingScreensaverImmichShuffleTitle => 'Ordine casuale';

  @override
  String get settingScreensaverImmichShuffleDescription =>
      'Mostra i contenuti in ordine casuale.';

  @override
  String get settingScreensaverImmichTransitionTitle => 'Transizione';

  @override
  String get settingScreensaverImmichTransitionDescription =>
      'Come si passa da un elemento al successivo.';

  @override
  String get settingScreensaverImmichFillTitle => 'Riempi lo schermo';

  @override
  String get settingScreensaverImmichFillDescription =>
      'Disattivato mantiene la foto intera tra bande nere. Intelligente ingrandisce le foto con proporzioni vicine a quelle dello schermo e mostra le altre su uno sfondo sfocato. Sempre ingrandisce ogni foto, tagliando ciò che non entra.';

  @override
  String get settingScreensaverImmichCropFacesTitle =>
      'Ritaglia intorno ai volti';

  @override
  String get settingScreensaverImmichCropFacesDescription =>
      'Le foto ritagliate per riempire lo schermo mantengono visibili i volti trovati da Immich. Richiede l\'autorizzazione face.read.';

  @override
  String get settingScreensaverImmichCropVideosTitle => 'Ritaglia i video';

  @override
  String get settingScreensaverImmichCropVideosDescription =>
      'I video vengono ritagliati per riempire lo schermo come le foto. Disattiva per mostrare ogni video per intero.';

  @override
  String get settingScreensaverImmichPairPortraitTitle =>
      'Abbina le foto verticali';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      'Mostra due foto verticali affiancate in modo che riempiano lo schermo.';

  @override
  String get settingScreensaverImmichPairLandscapeTitle =>
      'Abbina le foto orizzontali';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      'Mostra due foto orizzontali una sopra l\'altra in modo che riempiano uno schermo verticale.';

  @override
  String get settingScreensaverImmichEdgeTapsTitle =>
      'Tocca i bordi per cambiare immagine';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      'Un tocco sul quinto sinistro o destro dello schermo mostra l\'immagine precedente o successiva invece di chiudere il salvaschermo.';

  @override
  String get settingScreensaverImmichProgressBarTitle =>
      'Mostra la barra di avanzamento';

  @override
  String get settingScreensaverImmichProgressBarDescription =>
      'Una barra sottile mostra il tempo che manca all\'immagine successiva.';

  @override
  String get settingScreensaverImmichProgressBarPositionTitle =>
      'Posizione della barra di avanzamento';

  @override
  String get settingScreensaverImmichProgressBarPositionDescription =>
      'Il bordo dello schermo lungo cui scorre la barra di avanzamento.';

  @override
  String get screensaverImmichProgressBarTop => 'In alto';

  @override
  String get screensaverImmichProgressBarBottom => 'In basso';

  @override
  String get settingScreensaverImmichProgressBarColorTitle =>
      'Colore della barra di avanzamento';

  @override
  String get settingScreensaverImmichProgressBarColorDescription =>
      'Il colore della barra di avanzamento.';

  @override
  String get settingScreensaverImmichProgressBarTransparencyTitle =>
      'Trasparenza della barra di avanzamento';

  @override
  String get settingScreensaverImmichProgressBarTransparencyDescription =>
      'Quanto della foto si vede attraverso la barra di avanzamento.';

  @override
  String get screensaverMediaSlideshow => 'Presentazione';

  @override
  String get settingScreensaverImmichAlbumTitle => 'Origine dei contenuti';

  @override
  String get settingScreensaverImmichAlbumDescription =>
      'L\'intera libreria o gli album che scegli.';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => 'Solo foto';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription =>
      'Salta i video nella presentazione.';

  @override
  String get settingScreensaverImmichCacheTitle =>
      'Salva i contenuti in cache locale';

  @override
  String get settingScreensaverImmichCacheDescription =>
      'Conserva delle copie sul dispositivo per caricare le immagini all\'istante.';

  @override
  String get settingScreensaverImmichCacheMaxTitle =>
      'Dimensione della cache (elementi)';

  @override
  String get settingScreensaverImmichCacheMaxDescription =>
      'Gli elementi più vecchi vengono eliminati quando la cache è piena.';

  @override
  String get screensaverMediaAll => 'Tutti i contenuti';

  @override
  String get screensaverMediaAllDevice => 'Tutti i contenuti.';

  @override
  String get screensaverMediaNoAlbums =>
      'Ancora nessun album. Creane prima uno in Immich.';

  @override
  String get screensaverMediaAlbumsFailed => 'Impossibile elencare gli album';

  @override
  String screensaverMediaListError(String error) {
    return 'Impossibile elencarli: $error';
  }

  @override
  String get screensaverMediaListingFailed => 'elenco non riuscito';

  @override
  String screensaverMediaItems(String count) {
    return '$count elementi';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return '$count in cache, $size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => 'Viste telecamere';

  @override
  String get settingScreensaverCameraViewsDescription =>
      'Le viste telecamere mostrate dal salvaschermo, in questo ordine.';

  @override
  String get settingScreensaverCameraViewSecondsTitle =>
      'Secondi per vista telecamere';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      'Per quanto tempo ogni vista resta sullo schermo prima della successiva. Con una sola vista selezionata non c\'è rotazione.';

  @override
  String get settingScreensaverCameraMuteTitle =>
      'Disattiva l\'audio di tutte le viste';

  @override
  String get settingScreensaverCameraMuteDescription =>
      'Mantiene ogni vista senza audio, anche con una sola telecamera.';

  @override
  String get screensaverMediaCameraPage =>
      'Salvaschermo Flussi delle telecamere';

  @override
  String get screensaverMediaCameraHint =>
      'Viste da mostrare, secondi per vista, audio';

  @override
  String get screensaverMediaNoCameras =>
      'Nessuna vista telecamere contiene ancora telecamere. Aggiungine una in Flussi delle telecamere.';

  @override
  String get screensaverMediaNoCamerasRemote =>
      'Nessuna vista telecamere contiene ancora telecamere';

  @override
  String get screensaverMediaAddCameras =>
      'Aggiungine una in Flussi delle telecamere.';

  @override
  String get screensaverMediaNoViews =>
      'Ancora nessuna. Scegli le viste che il salvaschermo mostra a rotazione.';

  @override
  String get screensaverMediaRotation =>
      'In rotazione (trascina per riordinare)';

  @override
  String get screensaverMediaAvailable => 'Disponibili';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count telecamera';
  }

  @override
  String screensaverMediaCameras(String count) {
    return '$count telecamere';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return 'Posizione $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => 'Nessuna';

  @override
  String get screensaverMediaTransitionFade => 'Dissolvenza incrociata';

  @override
  String get screensaverMediaTransitionSlide => 'Scorrimento';

  @override
  String get screensaverMediaTransitionZoom => 'Zoom';

  @override
  String get screensaverMediaTransitionKenBurns => 'Effetto Ken Burns';

  @override
  String get screensaverMediaTransitionRandom => 'Casuale';

  @override
  String get screensaverMediaFillOff => 'Disattivato';

  @override
  String get screensaverMediaFillSmart => 'Intelligente';

  @override
  String get screensaverMediaFillAlways => 'Sempre';

  @override
  String get settingScreensaverVideoLengthTitle => 'Durata dei video';

  @override
  String get settingScreensaverVideoLengthDescription =>
      'Per quanto tempo viene riprodotto ogni video prima del successivo.';

  @override
  String get screensaverMediaVideoLengthFull => 'Video intero';

  @override
  String get screensaverMediaVideoLengthInterval => 'Come le foto';

  @override
  String get settingScreensaverImageIntervalDescription =>
      'Per quanto tempo viene mostrata ogni immagine prima della successiva.';

  @override
  String get settingScreensaverPhotoIntervalDescription =>
      'Per quanto tempo viene mostrata ogni foto prima della successiva.';

  @override
  String get settingScreensaverGalleryItemsTitle => 'Foto';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'Le foto e i video che questo salvaschermo mostra a rotazione. Si scelgono dalla galleria del dispositivo; una nuova scelta sostituisce la selezione.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Secondi per foto';

  @override
  String get settingScreensaverGalleryShuffleTitle => 'Ordine casuale';

  @override
  String get settingScreensaverGalleryShuffleDescription =>
      'Mostra la selezione in ordine casuale.';

  @override
  String get settingScreensaverGalleryTransitionTitle => 'Transizione';

  @override
  String get settingScreensaverGalleryTransitionDescription =>
      'Come si passa da una foto alla successiva.';

  @override
  String get settingScreensaverGalleryFillTitle => 'Riempi lo schermo';

  @override
  String get settingScreensaverGalleryFillDescription =>
      'Disattivato mantiene la foto intera tra bande nere. Intelligente ingrandisce le foto con proporzioni vicine a quelle dello schermo e mostra le altre su uno sfondo sfocato. Sempre ingrandisce ogni foto, tagliando ciò che non entra.';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle =>
      'Tocca i bordi per cambiare immagine';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      'Un tocco sul quinto sinistro o destro dello schermo mostra l\'immagine precedente o successiva invece di chiudere il salvaschermo.';

  @override
  String get screensaverMediaGalleryPage => 'Salvaschermo Galleria foto';

  @override
  String get screensaverMediaGalleryHint =>
      'Foto, durata, ordine casuale, transizione';

  @override
  String get screensaverMediaLoadingPhotos => 'Caricamento delle foto...';

  @override
  String screensaverMediaCopying(String index, String total) {
    return 'Copia della foto $index di $total...';
  }

  @override
  String get screensaverMediaCopyFailed => 'Impossibile copiare le foto';

  @override
  String get screensaverMediaSmallerSelection =>
      'Prova con una selezione più piccola.';

  @override
  String get screensaverMediaNoPhotos => 'Nessuna foto selezionata';

  @override
  String screensaverMediaSelected(String count) {
    return '$count selezionati';
  }

  @override
  String get screensaverMediaPickOnDevice =>
      'Nessuna selezione. Scegli sul dispositivo.';

  @override
  String get settingScreensaverMediaIdTitle => 'Origine dei contenuti';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Un elemento multimediale, una cartella o una telecamera di Home Assistant. Usa Sfoglia per sceglierne uno.';

  @override
  String get settingScreensaverMediaIntervalTitle => 'Secondi per immagine';

  @override
  String get settingScreensaverMediaShuffleTitle => 'Ordine casuale';

  @override
  String get settingScreensaverMediaShuffleDescription =>
      'Riproduce una cartella in ordine casuale.';

  @override
  String get settingScreensaverMediaRecursiveTitle =>
      'Includi le sottocartelle';

  @override
  String get settingScreensaverMediaRecursiveDescription =>
      'Include le sottocartelle quando si sceglie una cartella.';

  @override
  String get settingScreensaverMediaTransitionTitle => 'Transizione';

  @override
  String get settingScreensaverMediaTransitionDescription =>
      'Come si passa da un elemento al successivo.';

  @override
  String get settingScreensaverMediaFillTitle => 'Riempi lo schermo';

  @override
  String get settingScreensaverMediaFillDescription =>
      'Disattivato mantiene la foto intera tra bande nere. Intelligente ingrandisce le foto con proporzioni vicine a quelle dello schermo e mostra le altre su uno sfondo sfocato. Sempre ingrandisce ogni foto, tagliando ciò che non entra.';

  @override
  String get settingScreensaverMediaEdgeTapsTitle =>
      'Tocca i bordi per cambiare immagine';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      'Un tocco sul quinto sinistro o destro dello schermo mostra l\'immagine precedente o successiva invece di chiudere il salvaschermo.';

  @override
  String get settingScreensaverMediaMetadataTitle => 'Mostra i metadati';

  @override
  String get settingScreensaverMediaMetadataDescription =>
      'Data e dettagli della fotocamera sopra la foto.';

  @override
  String get settingScreensaverMediaMetadataDateTitle => 'Data di scatto';

  @override
  String get settingScreensaverMediaMetadataDateDescription =>
      'Mostra quando è stata scattata la foto.';

  @override
  String get settingScreensaverMediaMetadataCameraTitle =>
      'Dettagli della fotocamera';

  @override
  String get settingScreensaverMediaMetadataCameraDescription =>
      'Mostra lunghezza focale, apertura e ISO.';

  @override
  String get settingScreensaverMediaMetadataPositionTitle =>
      'Posizione dei metadati';

  @override
  String get settingScreensaverMediaMetadataPositionDescription =>
      'L\'angolo in cui compaiono i dettagli.';

  @override
  String get settingScreensaverMediaMetadataTextShadowTitle =>
      'Ombra del testo';

  @override
  String get settingScreensaverMediaMetadataTextShadowDescription =>
      'Aggiunge un\'ombra al testo dei metadati per renderlo leggibile sulle foto.';

  @override
  String get settingScreensaverMediaMetadataScaleTitle =>
      'Dimensione del testo';

  @override
  String get settingScreensaverMediaMetadataScaleDescription =>
      'Adatta la dimensione dei dettagli della foto a quella dello schermo.';

  @override
  String get settingScreensaverMediaVignetteStrengthTitle =>
      'Intensità della vignettatura';

  @override
  String get settingScreensaverMediaVignetteStrengthDescription =>
      'Quanto è scura l\'ombreggiatura dietro i dettagli, per renderli leggibili sulle foto chiare. 0 la disattiva.';

  @override
  String get screensaverMediaHaMetadata =>
      'Metadati dei contenuti multimediali di Home Assistant';

  @override
  String get screensaverMediaHaPage =>
      'Salvaschermo Contenuti multimediali di Home Assistant';

  @override
  String get screensaverMediaHaPageHint =>
      'Origine dei contenuti, durata, ordine casuale, riempimento, metadati';

  @override
  String get screensaverMediaChoose => 'Scegli i contenuti';

  @override
  String get screensaverMediaRoot => 'Contenuti multimediali';

  @override
  String get screensaverMediaHaUnavailable =>
      'Impossibile raggiungere Home Assistant, oppure manca il token.';

  @override
  String get screensaverMediaEmpty => 'Nessun elemento qui.';

  @override
  String get screensaverMediaUseFolder => 'Usa questa cartella';

  @override
  String get screensaverMediaFolder => 'cartella';

  @override
  String get screensaverMediaCamera => 'telecamera';

  @override
  String get screensaverMediaItem => 'elemento';

  @override
  String get screensaverMediaBrowseFailed => 'navigazione non riuscita';

  @override
  String screensaverMediaBrowseError(String error) {
    return 'Impossibile sfogliare: $error';
  }

  @override
  String get screensaverMediaNotSet => 'Non impostata';

  @override
  String get settingScreensaverLocalFolderTitle => 'Cartella locale';

  @override
  String get settingScreensaverLocalFolderDescription =>
      'Cartella di questo dispositivo con le foto e i video che il salvaschermo mostra a rotazione. Si sceglie sul dispositivo; da remoto puoi anche digitare qui il percorso.';

  @override
  String get settingScreensaverLocalIntervalTitle => 'Secondi per foto';

  @override
  String get settingScreensaverLocalShuffleTitle => 'Ordine casuale';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      'Mostra la cartella in ordine casuale invece che per nome.';

  @override
  String get settingScreensaverLocalRecursiveTitle =>
      'Includi le sottocartelle';

  @override
  String get settingScreensaverLocalRecursiveDescription =>
      'Mostra anche le foto e i video delle sottocartelle.';

  @override
  String get settingScreensaverLocalTransitionTitle => 'Transizione';

  @override
  String get settingScreensaverLocalTransitionDescription =>
      'Come si passa da una foto alla successiva.';

  @override
  String get settingScreensaverLocalFillTitle => 'Riempi lo schermo';

  @override
  String get settingScreensaverLocalFillDescription =>
      'Disattivato mantiene la foto intera tra bande nere. Intelligente ingrandisce le foto con proporzioni vicine a quelle dello schermo e mostra le altre su uno sfondo sfocato. Sempre ingrandisce ogni foto, tagliando ciò che non entra.';

  @override
  String get settingScreensaverLocalEdgeTapsTitle =>
      'Tocca i bordi per cambiare immagine';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      'Un tocco sul quinto sinistro o destro dello schermo mostra l\'immagine precedente o successiva invece di chiudere il salvaschermo.';

  @override
  String get settingScreensaverLocalMetadataTitle => 'Mostra i metadati';

  @override
  String get settingScreensaverLocalMetadataDescription =>
      'Data e dettagli della fotocamera sopra la foto.';

  @override
  String get settingScreensaverLocalMetadataDateTitle => 'Data di scatto';

  @override
  String get settingScreensaverLocalMetadataDateDescription =>
      'Mostra quando è stata scattata la foto.';

  @override
  String get settingScreensaverLocalMetadataCameraTitle =>
      'Dettagli della fotocamera';

  @override
  String get settingScreensaverLocalMetadataCameraDescription =>
      'Mostra lunghezza focale, apertura e ISO.';

  @override
  String get settingScreensaverLocalMetadataPositionTitle =>
      'Posizione dei metadati';

  @override
  String get settingScreensaverLocalMetadataPositionDescription =>
      'L\'angolo in cui compaiono i dettagli.';

  @override
  String get settingScreensaverLocalMetadataTextShadowTitle =>
      'Ombra del testo';

  @override
  String get settingScreensaverLocalMetadataTextShadowDescription =>
      'Aggiunge un\'ombra al testo dei metadati per renderlo leggibile sulle foto.';

  @override
  String get settingScreensaverLocalMetadataScaleTitle =>
      'Dimensione del testo';

  @override
  String get settingScreensaverLocalMetadataScaleDescription =>
      'Adatta la dimensione dei dettagli della foto a quella dello schermo.';

  @override
  String get settingScreensaverLocalVignetteStrengthTitle =>
      'Intensità della vignettatura';

  @override
  String get settingScreensaverLocalVignetteStrengthDescription =>
      'Quanto è scura l\'ombreggiatura dietro i dettagli, per renderli leggibili sulle foto chiare. 0 la disattiva.';

  @override
  String get screensaverMediaLocalMetadata =>
      'Metadati dei contenuti multimediali locali';

  @override
  String get screensaverMediaLocalPage =>
      'Salvaschermo Contenuti multimediali locali';

  @override
  String get screensaverMediaLocalPageHint =>
      'Cartella, durata, ordine casuale, transizione, metadati';

  @override
  String get settingScreensaverUrlImageDescription =>
      'L\'indirizzo di un\'immagine, che il dispositivo scarica di nuovo a ogni cambio di immagine.';

  @override
  String get settingScreensaverUrlIntervalDescription =>
      'Per quanto tempo viene mostrata ogni foto prima del download successivo.';

  @override
  String get screensaverMediaUrlPage => 'Salvaschermo URL dell\'immagine';

  @override
  String get screensaverMediaUrlPageHint =>
      'URL, durata, transizione, metadati';

  @override
  String get screensaverMediaUrlMetadata => 'Metadati dell\'URL dell\'immagine';

  @override
  String get settingScreensaverDismissOnMotionTitle =>
      'Chiudi al rilevamento del movimento';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      'Osserva la fotocamera mentre è attivo il salvaschermo e riattiva lo schermo quando qualcuno si avvicina. La fotocamera funziona solo durante il salvaschermo.';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle =>
      'Solo a schermo spento';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      'Mantiene visibile il salvaschermo quando viene rilevato un movimento a schermo acceso. Quando lo schermo è spento, il rilevamento riattiva la plancia. Il tocco chiude comunque il salvaschermo.';

  @override
  String get settingScreensaverPostponeOnMotionTitle =>
      'Posticipa il salvaschermo al rilevamento del movimento';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      'Ritarda l\'attivazione del salvaschermo quando viene rilevato un movimento. ATTENZIONE: mantiene la fotocamera sempre attiva.';

  @override
  String get screensaverDetectionMotionPage => 'Rilevamento del movimento';

  @override
  String get screensaverDetectionMotionHint =>
      'Chiude o posticipa il salvaschermo al rilevamento del movimento';

  @override
  String get screensaverDetectionMotionTuning =>
      'Il rilevamento del movimento si regola nelle impostazioni della Fotocamera.';

  @override
  String get settingMotionUseEntityTitle => 'Usa un\'entità di Home Assistant';

  @override
  String get settingMotionUseEntityDescription =>
      'Rileva il movimento con un sensore di Home Assistant invece che con la fotocamera.';

  @override
  String get settingMotionEntityTitle => 'Entità del sensore di movimento';

  @override
  String get settingMotionEntityDescription =>
      'Il sensore di occupazione, movimento o presenza di Home Assistant da seguire.';

  @override
  String get screensaverDetectionExternalMotionHeading =>
      'Sensore di movimento esterno';

  @override
  String get settingScreensaverDismissOnPersonTitle =>
      'Chiudi al rilevamento di una persona';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      'Legge il sensore di persone del dispositivo mentre è attivo il salvaschermo e riattiva lo schermo quando qualcuno si trova davanti. Richiede l\'autorizzazione Accesso ai registri qui sotto.';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle =>
      'Solo a schermo spento';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      'Mantiene visibile il salvaschermo quando arriva qualcuno a schermo acceso. Quando lo schermo è spento, il rilevamento riattiva la plancia. Il tocco chiude comunque il salvaschermo.';

  @override
  String get settingScreensaverPostponeOnPersonTitle =>
      'Posticipa il salvaschermo al rilevamento di una persona';

  @override
  String get settingScreensaverPostponeOnPersonDescription =>
      'Ritarda l\'attivazione del salvaschermo finché qualcuno si trova davanti al dispositivo.';

  @override
  String get screensaverDetectionPersonPage => 'Rilevamento delle persone';

  @override
  String get screensaverDetectionPersonHint =>
      'Chiude o posticipa il salvaschermo tramite il sensore di persone del dispositivo';

  @override
  String get screensaverDetectionOccupancy => 'Presenza';

  @override
  String get screensaverDetectionStatusUnavailable => 'Stato non disponibile.';

  @override
  String get screensaverDetectionOff => 'Disattivato.';

  @override
  String get screensaverDetectionStarting => 'Avvio...';

  @override
  String get screensaverDetectionWaiting =>
      'In attesa del primo segnale. Il sensore invia un segnale ogni 30 secondi mentre c\'è qualcuno davanti.';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return 'Ultimo segnale $ago.';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return '$count s fa';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return '$count min fa';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return '$count h fa';
  }

  @override
  String get screensaverDetectionDetected => 'Persona rilevata';

  @override
  String get screensaverDetectionClear => 'Nessuna persona';

  @override
  String get screensaverDetectionPermissions =>
      'Autorizzazioni di sistema richieste';

  @override
  String get screensaverDetectionLogAccess => 'Accesso ai registri';

  @override
  String get screensaverDetectionChecking => 'Verifica in corso...';

  @override
  String get screensaverDetectionReadable =>
      'Il sensore di persone del dispositivo è leggibile.';

  @override
  String get screensaverDetectionRestartRequired =>
      'Concessa. Riavvia Kiosk Satellite per applicarla.';

  @override
  String get screensaverDetectionGrantHelp =>
      'Questa autorizzazione si può concedere solo tramite ADB. La documentazione di Meta Portal riporta il comando completo. Poi riavvia Kiosk Satellite.';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      'Questa autorizzazione si può concedere solo tramite ADB. Qui sotto trovi il comando completo, pronto da copiare. Poi riavvia Kiosk Satellite.';

  @override
  String get screensaverDetectionGranted => 'Concessa';

  @override
  String get screensaverDetectionMissing => 'Mancante';

  @override
  String get screensaverDetectionRestart => 'Riavvia';

  @override
  String get screensaverDetectionRestartRemote => 'Riavvia sul dispositivo';

  @override
  String get screensaverDetectionLogRestart =>
      'L\'accesso ai registri è concesso, ma avrà effetto al riavvio di Kiosk Satellite.';

  @override
  String get screensaverDetectionLogMissing =>
      'Accesso ai registri non concesso.';

  @override
  String get settingScreensaverDismissOnProximityTitle =>
      'Chiudi al rilevamento di prossimità';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      'Osserva il sensore di prossimità mentre è attivo il salvaschermo e riattiva lo schermo quando qualcosa si avvicina al dispositivo. Un dispositivo che ha solo sensori pensati per le chiamate (\"palm\", \"touch\") non funzionerà.';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle =>
      'Solo a schermo spento';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      'Mantiene visibile il salvaschermo quando qualcosa si avvicina a schermo acceso. Quando lo schermo è spento, il rilevamento riattiva la plancia. Il tocco chiude comunque il salvaschermo.';

  @override
  String get settingScreensaverPostponeOnProximityTitle =>
      'Posticipa il salvaschermo al rilevamento di prossimità';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      'Ritarda l\'attivazione del salvaschermo finché qualcosa è vicino al sensore.';

  @override
  String get screensaverDetectionProximityPage => 'Rilevamento di prossimità';

  @override
  String get screensaverDetectionProximityHint =>
      'Chiude o posticipa il salvaschermo tramite il sensore di prossimità';

  @override
  String get screensaverDetectionNoProximity =>
      'Non disponibile su questo dispositivo: non ha un sensore di prossimità.';

  @override
  String get screensaverDetectionSensor => 'Sensore';

  @override
  String get screensaverDetectionSensorHelp =>
      'Ciò che il dispositivo indica come sensore di prossimità. Un sensore pensato per le chiamate chiamato \"palm\" o \"touch\" non funzionerà.';

  @override
  String get settingScreensaverScheduleEnabledTitle =>
      'Abilita i salvaschermo programmati';

  @override
  String get settingScreensaverScheduleEnabledDescription =>
      'Passa a un altro salvaschermo in orari prestabiliti della giornata.';

  @override
  String get settingScreensaverScheduleTitle => 'Orari';

  @override
  String get settingScreensaverScheduleDescription =>
      'Ogni orario cambia il salvaschermo da quel momento in poi.';

  @override
  String get screensaverScheduleSection => 'Salvaschermo programmati';

  @override
  String get screensaverTime => 'Orario';

  @override
  String get screensaverAddTime => 'Aggiungi orario';

  @override
  String get screensaverRemoveTime => 'Rimuovi orario';

  @override
  String get screensaverNoTimes => 'Ancora nessun orario';

  @override
  String get screensaverTimeHelp => 'Un salvaschermo da quell\'orario in poi.';

  @override
  String get screensaverPickTime => 'Scegli un orario.';

  @override
  String get screensaverDefault => 'Predefinito';

  @override
  String get screensaverOn => 'Attivato';

  @override
  String get screensaverOff => 'Disattivato';

  @override
  String get screensaverBrightness => 'Luminosità';

  @override
  String get screensaverBrightnessFollow =>
      'Segue l\'impostazione Luminosità del salvaschermo.';

  @override
  String get screensaverBrightnessExceptBlack =>
      'Vale per tutte le modalità tranne Nero.';

  @override
  String get screensaverScreenOffFollow =>
      'Segue l\'impostazione Spegni lo schermo dopo.';

  @override
  String get screensaverScreenOnHours =>
      'Mantiene lo schermo acceso in queste ore.';

  @override
  String get screensaverScreenOffHelp =>
      'Spegne lo schermo quando il salvaschermo è rimasto attivo per questo tempo. Richiede l\'autorizzazione Amministratore del dispositivo.';

  @override
  String get screensaverScreenOffNever => 'Schermo mai spento';

  @override
  String get screensaverMotion => 'Chiudi al rilevamento del movimento';

  @override
  String get screensaverFace => 'Chiudi al rilevamento di un volto';

  @override
  String get screensaverProximity => 'Chiudi al rilevamento di prossimità';

  @override
  String get screensaverPerson => 'Chiudi al rilevamento di una persona';

  @override
  String get screensaverWidgets => 'Widget';

  @override
  String get screensaverGlance => 'A colpo d\'occhio';

  @override
  String get screensaverNowPlaying =>
      'Mostra In riproduzione accanto al salvaschermo';

  @override
  String get screensaverNowPlayingHelp =>
      'Predefinito segue la disposizione generale. Attivato usa una disposizione condivisa quando In riproduzione è abilitato. Disattivato nasconde In riproduzione in queste ore.';

  @override
  String get screensaverCameraRequired =>
      'Richiede la fotocamera. Attivala prima nelle impostazioni della Fotocamera.';

  @override
  String get screensaverNotAvailable =>
      'Non disponibile su questo dispositivo.';

  @override
  String get screensaverSummaryMotionOn => 'Movimento: attivato';

  @override
  String get screensaverSummaryMotionOff => 'Movimento: disattivato';

  @override
  String get screensaverSummaryFaceOn => 'Volti: attivati';

  @override
  String get screensaverSummaryFaceOff => 'Volti: disattivati';

  @override
  String get screensaverSummaryProximityOn => 'Prossimità: attivata';

  @override
  String get screensaverSummaryProximityOff => 'Prossimità: disattivata';

  @override
  String get screensaverSummaryPersonOn => 'Persone: attivate';

  @override
  String get screensaverSummaryPersonOff => 'Persone: disattivate';

  @override
  String get screensaverSummaryWidgetsOn => 'Widget: attivati';

  @override
  String get screensaverSummaryWidgetsOff => 'Widget: disattivati';

  @override
  String get screensaverSummaryGlanceOn => 'A colpo d\'occhio: attivato';

  @override
  String get screensaverSummaryGlanceOff => 'A colpo d\'occhio: disattivato';

  @override
  String get screensaverSummaryNowPlayingOn => 'In riproduzione: attivato';

  @override
  String get screensaverSummaryNowPlayingOff => 'In riproduzione: disattivato';

  @override
  String screensaverBrightnessPercent(String percent) {
    return 'Luminosità al $percent%';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return 'Schermo spento dopo $minutes min';
  }

  @override
  String get screensaverWeatherMood => 'Atmosfera meteo';

  @override
  String get screensaverWeatherMoodPage => 'Salvaschermo atmosfera meteo';

  @override
  String get screensaverWeatherMoodSummary =>
      'Entità meteo, fulmini, anteprima';

  @override
  String get settingScreensaverWeatherEntityTitle => 'Entità meteo';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      'L\'entità meteo di Home Assistant che controlla la scena animata. Giorno, alba/tramonto e notte seguono sun.sun, con l\'ora locale come riserva.';

  @override
  String get settingScreensaverWeatherLightningTitle => 'Lampi';

  @override
  String get settingScreensaverWeatherLightningDescription =>
      'Mostra fulmini e lampi tra le nuvole durante i temporali.';

  @override
  String get screensaverWeatherMoodSelectEntity =>
      'Seleziona un\'entità meteo in Impostazioni > Salvaschermo > Atmosfera meteo.';

  @override
  String get screensaverWeatherPreviewGroup => 'Anteprima meteo';

  @override
  String get settingScreensaverWeatherPreviewTitle =>
      'Abilita l\'anteprima meteo';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      'Mostra la scena selezionata invece del meteo reale. Disattivala per tornare a seguire Home Assistant.';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => 'Tipo di meteo';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      'La scena meteo animata da mostrare in anteprima.';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle =>
      'Momento della giornata';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      'Sceglie la versione diurna, all\'alba/al tramonto o notturna della scena.';

  @override
  String get screensaverWeatherPreviewSunny => 'Sereno';

  @override
  String get screensaverWeatherPreviewPartlycloudy => 'Parzialmente nuvoloso';

  @override
  String get screensaverWeatherPreviewCloudy => 'Nuvoloso';

  @override
  String get screensaverWeatherPreviewRainy => 'Pioggia';

  @override
  String get screensaverWeatherPreviewPouring => 'Pioggia intensa';

  @override
  String get screensaverWeatherPreviewSnowy => 'Neve';

  @override
  String get screensaverWeatherPreviewSnowyRainy => 'Neve e pioggia';

  @override
  String get screensaverWeatherPreviewFog => 'Nebbia';

  @override
  String get screensaverWeatherPreviewHail => 'Grandine';

  @override
  String get screensaverWeatherPreviewLightning => 'Fulmini';

  @override
  String get screensaverWeatherPreviewLightningRainy => 'Fulmini e pioggia';

  @override
  String get screensaverWeatherPreviewWindy => 'Vento';

  @override
  String get screensaverWeatherPreviewWindyVariant => 'Vento e nuvole';

  @override
  String get screensaverWeatherPreviewExceptional => 'Meteo eccezionale';

  @override
  String get screensaverWeatherPreviewDay => 'Giorno';

  @override
  String get screensaverWeatherPreviewNight => 'Notte';

  @override
  String get settingScreensaverWeatherClockTitle => 'Abilita l\'orologio';

  @override
  String get settingScreensaverWeatherClockDescription =>
      'Mostra un orologio digitale sopra la scena meteo.';

  @override
  String get screensaverWeatherTextShadowDescription =>
      'Aggiunge un\'ombra al testo per renderlo leggibile sopra la scena meteo.';

  @override
  String get screensaverWeatherBarGroup => 'Informazioni meteo';

  @override
  String get settingScreensaverWeatherBarTitle => 'Abilita la barra meteo';

  @override
  String get settingScreensaverWeatherBarDescription =>
      'Mostra le informazioni meteo in tempo reale nella parte inferiore dello schermo.';

  @override
  String get settingScreensaverWeatherBarScaleTitle => 'Dimensione del testo';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      'Ridimensiona le informazioni meteo dal 50 al 200 percento.';

  @override
  String get settingScreensaverWeatherBarColorTitle => 'Colore del testo';

  @override
  String get settingScreensaverWeatherBarColorDescription =>
      'Il colore delle informazioni meteo.';

  @override
  String get settingScreensaverWeatherBarOpacityTitle => 'Opacità dello sfondo';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      'Scurisce la barra inferiore per mantenere leggibili le informazioni meteo.';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => 'Mostra i titoli';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      'Mostra il nome di ogni lettura sopra il suo valore. Senza titoli, i valori hanno la stessa dimensione della temperatura.';

  @override
  String get screensaverWeatherBarHighLowDescription =>
      'Mostra la massima e la minima di oggi quando l\'entità meteo ha una previsione giornaliera.';

  @override
  String get screensaverWeatherBarHumidityDescription =>
      'Mostra l\'umidità quando l\'entità meteo la fornisce.';

  @override
  String get screensaverWeatherBarWindDescription =>
      'Mostra la velocità del vento quando l\'entità meteo la fornisce.';

  @override
  String get screensaverWeatherBarVisibilityDescription =>
      'Mostra la visibilità quando l\'entità meteo la fornisce.';

  @override
  String get settingScreensaverWeatherBlurTitle => 'Sfocatura della scena';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      'Ammorbidisce la scena meteo animata mantenendo nitidi l\'orologio, la barra meteo e i widget.';

  @override
  String get screensaverWeatherPreviewTwilight => 'Alba/tramonto';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      'Mostra la temperatura percepita invece di quella reale, quando disponibile.';

  @override
  String get settingScreensaverWebsiteUrlTitle => 'URL del sito web';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      'Una pagina da mostrare a schermo intero. Deve consentire l\'incorporamento.';

  @override
  String get settingScreensaverWebsiteZoomTitle => 'Livello di zoom';

  @override
  String get settingScreensaverWebsiteZoomDescription =>
      'Ridimensiona l\'intera WebView del salvaschermo esterno.';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle =>
      'Doppio tocco per chiudere';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription =>
      'Un tocco singolo interagisce con il sito web invece di chiudere il salvaschermo.';

  @override
  String get screensaverWebsiteSection => 'Salvaschermo sito web';

  @override
  String get screensaverOverlaySmallClock => 'Orologio piccolo';

  @override
  String get screensaverOverlayWeather => 'Meteo';

  @override
  String get screensaverOverlayBattery => 'Batteria';

  @override
  String get screensaverOverlayClockNote =>
      'Nascosto nelle modalità del salvaschermo Orologio digitale e Flussi delle telecamere.';

  @override
  String get screensaverOverlayCameraNote =>
      'Nascosto nella modalità del salvaschermo Flussi delle telecamere.';

  @override
  String get screensaverOverlayScale => 'Scala';

  @override
  String get screensaverOverlayScaleHelp =>
      'Ridimensiona questo widget per adattarlo meglio allo schermo.';

  @override
  String get screensaverOverlayFont => 'Tipo di carattere';

  @override
  String get screensaverOverlayCorner => 'Angolo';

  @override
  String get screensaverOverlayWidget => 'Widget';

  @override
  String get screensaverOverlayClock24 => 'Orologio 24 ore';

  @override
  String get screensaverOverlayClock24Help =>
      'Mostra l\'ora nel formato 24 ore invece di AM/PM.';

  @override
  String get screensaverOverlayShowDate => 'Mostra la data';

  @override
  String get screensaverOverlayShowDateHelp =>
      'Aggiunge una data breve sotto l\'orologio.';

  @override
  String get screensaverOverlayPercentage => 'Mostra la percentuale';

  @override
  String get screensaverOverlayPercentageHelp =>
      'La carica accanto all\'icona.';

  @override
  String get screensaverOverlayLow => 'Solo con batteria scarica';

  @override
  String get screensaverOverlayLowHelp =>
      'Resta nascosto finché la carica non scende al 20 percento.';

  @override
  String get screensaverOverlayShowName => 'Mostra il nome';

  @override
  String get screensaverOverlayShowNameHelp => 'Il nome sotto il valore.';

  @override
  String get screensaverOverlayShowIcon => 'Mostra l\'icona';

  @override
  String get screensaverOverlayShowIconHelp => 'L\'icona accanto al valore.';

  @override
  String get screensaverOverlayVisibleStates => 'Stati visibili';

  @override
  String get screensaverOverlayVisibleStatesHelp =>
      'Mostra il widget solo quando il suo valore è uno di questi, separati da virgole. Lascia vuoto per mostrarlo sempre.';

  @override
  String get screensaverOverlayFontSystem => 'Sistema';

  @override
  String get screensaverOverlayFontSerif => 'Con grazie';

  @override
  String get screensaverOverlayFontCondensed => 'Condensato';

  @override
  String get screensaverOverlayFontMonospace => 'Monospaziato';

  @override
  String get screensaverOverlayFontCasual => 'Informale';

  @override
  String get screensaverOverlayFontCursive => 'Corsivo';

  @override
  String get screensaverOverlayColor => 'Colore';

  @override
  String get screensaverOverlayWeatherEntity => 'Entità meteo';

  @override
  String get screensaverOverlayWeatherRequired => 'Scegli un\'entità meteo.';

  @override
  String get screensaverOverlayLocationName => 'Nome della località';

  @override
  String get screensaverOverlayLocationHelp =>
      'Lascia vuoto per nascondere la riga della località.';

  @override
  String get screensaverOverlayLocation => 'Località';

  @override
  String get screensaverOverlayLocationDetail =>
      'Il nome del luogo sopra la temperatura.';

  @override
  String get screensaverOverlayFeelsLike => 'Temperatura percepita';

  @override
  String get screensaverOverlayFeelsLikeHelp =>
      'Mostra la temperatura percepita in una riga con etichetta sotto la temperatura reale.';

  @override
  String get screensaverOverlayFeelsLikeOnly => 'Solo temperatura percepita';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp =>
      'Mostra la temperatura percepita, con l\'etichetta Percepita, invece della temperatura reale.';

  @override
  String get screensaverOverlayForecast => 'Condizioni meteo';

  @override
  String get screensaverOverlayForecastHelp =>
      'Le condizioni meteo, con l\'icona corrispondente.';

  @override
  String get screensaverOverlayHighLow => 'Massima e minima';

  @override
  String get screensaverOverlayHighLowHelp =>
      'Le temperature massima e minima di oggi.';

  @override
  String get screensaverOverlayForecastWidget => 'Previsioni meteo';

  @override
  String get screensaverOverlayForecastDays => 'Giorni mostrati';

  @override
  String get screensaverOverlayForecastToday => 'Includi oggi';

  @override
  String get screensaverOverlayForecastTodayHelp =>
      'Inizia l\'elenco con la previsione di oggi.';

  @override
  String get screensaverOverlayForecastColored => 'Icone colorate';

  @override
  String get screensaverOverlayForecastColoredHelp =>
      'Mostra le icone meteo nei loro colori.';

  @override
  String get screensaverOverlayHumidity => 'Umidità';

  @override
  String get screensaverOverlayWind => 'Velocità del vento';

  @override
  String get screensaverOverlayVisibility => 'Visibilità';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return 'Percepita $temperature';
  }

  @override
  String get settingScreensaverWidgetsEnabledTitle =>
      'Abilita i widget del salvaschermo';

  @override
  String get settingScreensaverWidgetsEnabledDescription =>
      'Piccoli elementi sovrapposti negli angoli del salvaschermo.';

  @override
  String get settingScreensaverWidgetsTitle => 'Widget';

  @override
  String get settingScreensaverWidgetsDescription =>
      'Piccoli elementi sovrapposti negli angoli del salvaschermo.';

  @override
  String get settingScreensaverWidgetScaleTitle => 'Scala globale dei widget';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      'Ridimensiona tutti i widget insieme per adattarli meglio allo schermo. Ogni widget mantiene la propria scala rispetto agli altri.';

  @override
  String get settingScreensaverWidgetFontTitle => 'Tipo di carattere globale';

  @override
  String get settingScreensaverWidgetFontDescription =>
      'Il carattere usato da tutti i widget. Ogni widget può sceglierne uno proprio.';

  @override
  String get settingScreensaverWidgetFontWeightTitle =>
      'Spessore globale del carattere';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      'Lo spessore del testo di tutti i widget. Predefinito usa lo spessore proprio di ogni riga. Ogni widget può sceglierne uno proprio.';

  @override
  String get settingScreensaverWidgetTextShadowTitle => 'Ombra del testo';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      'Aggiunge un\'ombra al testo dei widget per renderlo leggibile sulle foto.';

  @override
  String get settingScreensaverVignetteStrengthTitle =>
      'Intensità della vignettatura';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      'L\'intensità dell\'ombreggiatura dietro i widget, per renderli leggibili sulle foto chiare. 0 la disattiva.';

  @override
  String get screensaverOverlayWidgetsEmpty => 'Ancora nessun widget';

  @override
  String get screensaverOverlayShow => 'Mostra questo widget';

  @override
  String get screensaverOverlayRemove => 'Rimuovi il widget';

  @override
  String get screensaverOverlayAdd => 'Aggiungi widget';

  @override
  String get screensaverOverlayAddHelp =>
      'Un piccolo orologio, il meteo, la batteria o un\'entità in un angolo.';

  @override
  String get screensaverOverlayWidgetsHint =>
      'Elementi negli angoli e loro scala';

  @override
  String get settingsSearchHint => 'Cerca nelle impostazioni';

  @override
  String get settingsSearchClear => 'Cancella la ricerca';

  @override
  String get settingsSearchResults => 'Risultati della ricerca';

  @override
  String settingsSearchEmpty(String query) {
    return 'Nessuna impostazione corrisponde a \"$query\".';
  }

  @override
  String get searchInstallApk =>
      'Carica un APK di Kiosk Satellite tramite l\'amministrazione remota e installalo.';

  @override
  String get searchPermissionsHelp =>
      'Tutte le autorizzazioni Android che l\'app può usare, con il loro stato: microfono, fotocamera, notifiche, batteria senza restrizioni, mostra sopra altre app, modifica delle impostazioni di sistema, protezione dell\'interfaccia di sistema, amministratore del dispositivo, accesso a tutti i file, accesso ai dati di utilizzo e posizione.';

  @override
  String get searchServiceStatus => 'Stato del servizio';

  @override
  String get searchServiceHelp =>
      'Indica se il Servizio Kiosk Satellite è in esecuzione e cosa mantiene attivo.';

  @override
  String get searchServicePermissions =>
      'Le autorizzazioni di cui ha bisogno il Servizio Kiosk Satellite.';

  @override
  String get searchIntercomKiosks =>
      'I kiosk conosciuti e se ognuno può ricevere una chiamata.';

  @override
  String get searchHaValidate =>
      'Verifica l\'URL e il token con il tuo Home Assistant.';

  @override
  String get searchHaProxy =>
      'Rende disponibile un Home Assistant in semplice HTTP tramite un proxy sicuro all\'interno dell\'app.';

  @override
  String get searchHaDashboard =>
      'Scegli la plancia e la vista mostrate dal kiosk.';

  @override
  String get searchKioskPermissions =>
      'Le autorizzazioni su cui si basano le protezioni del kiosk e della modalità blocco.';

  @override
  String get searchHomeStatus => 'Stato della schermata Home';

  @override
  String get searchHomeHelp =>
      'Indica se Kiosk Satellite è la schermata Home del dispositivo e dove completare l\'impostazione come predefinita.';

  @override
  String get searchMasterVolume =>
      'Il volume del dispositivo su cui si basano i cursori del volume multimediale e dell\'assistente.';

  @override
  String get searchSmallClock =>
      'Un widget orologio in un angolo del salvaschermo.';

  @override
  String get searchBattery =>
      'Un widget batteria in un angolo del salvaschermo: la carica di questo dispositivo.';

  @override
  String get searchWeatherForecast =>
      'Un widget delle previsioni in un angolo del salvaschermo: i prossimi giorni, con massime e minime.';

  @override
  String get searchPersonPermission =>
      'L\'autorizzazione di accesso ai registri richiesta dal sensore di persone del dispositivo.';

  @override
  String get searchSonosSpeakers =>
      'Gli altoparlanti Sonos noti a questo dispositivo, una ricerca nella rete e un campo per l\'indirizzo.';

  @override
  String get voiceAppearanceHint =>
      'Stile della sovrapposizione, tema, barra di attività, dimensione del testo';

  @override
  String get voiceSkin => 'Stile';

  @override
  String get voiceSkinHelp =>
      'L\'aspetto della sovrapposizione dell\'assistente vocale.';

  @override
  String get voiceSkin1 => 'Stile dell\'assistente 1';

  @override
  String get voiceSkin1Help =>
      'L\'aspetto della sovrapposizione quando risponde l\'assistente 1.';

  @override
  String get voiceSkin2 => 'Stile dell\'assistente 2';

  @override
  String get voiceSkin2Help =>
      'L\'aspetto della sovrapposizione quando risponde l\'assistente 2.';

  @override
  String get voiceTheme => 'Modalità del tema';

  @override
  String get voiceThemeHelp =>
      'Visualizzazione chiara o scura della sovrapposizione.';

  @override
  String get voiceReactive => 'Barra di attività reattiva';

  @override
  String get voiceReactiveHelp =>
      'La barra di attività reagisce all\'audio. SCONSIGLIATO sui dispositivi poco potenti come l\'Echo Show.';

  @override
  String get voiceRate => 'Frequenza di aggiornamento della barra reattiva';

  @override
  String get voiceRateHelp =>
      'Quanto spesso viene ridisegnata la barra di attività. Un valore più alto è più fluido e usa più CPU.';

  @override
  String get voiceScaleHelp => 'La dimensione del testo della sovrapposizione.';

  @override
  String get voiceUpdateIntegration =>
      'Aggiorna l\'integrazione Voice Satellite in Home Assistant per controllare queste impostazioni dal kiosk.';

  @override
  String get voiceDashboardRequired =>
      'Disponibile mentre il kiosk mostra la tua plancia di Home Assistant.';

  @override
  String get voiceSkinUnavailablePlugin => 'Stile di un plugin non disponibile';

  @override
  String get voiceSkinDefault => 'Predefinito dello stile';

  @override
  String get voiceBackground => 'Sfondo';

  @override
  String get voiceBackgroundHelp => 'Quanto traspare la plancia.';

  @override
  String get voicePreview => 'Anteprima';

  @override
  String get voicePreviewHelp =>
      'Mostra la sovrapposizione su questo schermo per cinque secondi.';

  @override
  String get voicePreviewRemoteHelp =>
      'Mostra la sovrapposizione sullo schermo del kiosk per cinque secondi.';

  @override
  String get settingVoiceThemeTitle => 'Tema';

  @override
  String get settingVoiceThemeDescription =>
      'Automatico segue il tema di Home Assistant.';

  @override
  String get settingVoiceBackgroundDescription =>
      'Quanto traspare la plancia. Con -1 usa il predefinito dello stile.';

  @override
  String get settingVoiceTextScaleTitle => 'Dimensione del testo';

  @override
  String get settingVoiceReactiveBarTitle => 'Barra di attività reattiva';

  @override
  String get settingVoiceReactiveBarDescription =>
      'La barra segue la tua voce e la risposta.';

  @override
  String get voicePreviewCommand => 'Che tempo fa?';

  @override
  String get voicePreviewAnswer =>
      'Al momento c\'è il sole e 22°, con una leggera brezza.';

  @override
  String get settingVoiceOverlayModeTitle => 'Modalità della sovrapposizione';

  @override
  String get settingVoiceOverlayModeDescription =>
      'Ancorata mostra una piccola nuvoletta sopra la plancia. Non mostra risultati avanzati come immagini, meteo o video.';

  @override
  String get voiceOverlayFullScreen => 'Schermo intero';

  @override
  String get voiceOverlayDocked => 'Ancorata';

  @override
  String get voiceListeningEllipsis => 'In ascolto…';

  @override
  String get voiceSkinVoiceOnly => 'Solo voce';

  @override
  String get voiceAssistant1 => 'Assistente 1';

  @override
  String get voiceAssistant1Help => 'Risponde alla parola di attivazione 1.';

  @override
  String get voiceAssistant2 => 'Assistente 2';

  @override
  String get voiceAssistant2Help => 'Risponde alla parola di attivazione 2.';

  @override
  String get voicePipelines => 'Pipeline';

  @override
  String get voicePreferred => 'Preferita';

  @override
  String get voiceNone => 'Nessuna';

  @override
  String get voiceThisKiosk => 'Questo kiosk';

  @override
  String get voiceSelectFailed => 'Impossibile modificarlo in Home Assistant.';

  @override
  String get settingVoiceSeamlessWakeTitle =>
      'Parla subito dopo la parola di attivazione';

  @override
  String get settingVoiceSeamlessWakeAssistDescription =>
      'Salta il suono di attivazione e mantiene ciò che dici subito dopo la parola di attivazione. Solo per le pipeline di Assist, non per le conversazioni in tempo reale.';

  @override
  String get settingVoiceFollowupDelayTitle => 'Ritardo prima di riascoltare';

  @override
  String get settingVoiceFollowupDelayDescription =>
      'Una pausa prima di ascoltare la risposta a una domanda.';

  @override
  String get settingVoiceFollowupChimeTitle =>
      'Segnale acustico prima di riascoltare';

  @override
  String get settingVoiceFollowupChimeDescription =>
      'Riproduce il suono di attivazione quando torna in ascolto.';

  @override
  String get settingVoiceTtsOutputTitle => 'Riproduci i suoni su';

  @override
  String get settingVoiceTtsOutputDescription =>
      'Segnali acustici, risposte, annunci e avvisi dei timer vengono riprodotti su questo altoparlante.';

  @override
  String get settingVoiceTtsOutputModeTitle => 'Riproduci come';

  @override
  String get settingVoiceTtsOutputModeDescription =>
      'Un annuncio consente all\'altoparlante di mettere in pausa la musica e poi riprenderla. La riproduzione normale fa ripartire la musica al termine, per gli altoparlanti che ignorano gli annunci.';

  @override
  String get voiceOptionAnnouncement => 'Annuncio';

  @override
  String get voiceOptionNormalPlayback => 'Riproduzione normale';

  @override
  String get voiceChimesPage => 'Segnali acustici';

  @override
  String get voiceChimesPreview => 'Anteprima sul kiosk';

  @override
  String get voiceChimesPreviewFailed => 'Impossibile riprodurre il suono.';

  @override
  String get voiceChimesHelp =>
      'Scegli i suoni per questo kiosk. Carica qui i file personalizzati. I suoni salvati in Home Assistant non vengono usati per i segnali acustici locali.';

  @override
  String get voiceChimeWakeTitle => 'Suono di attivazione';

  @override
  String get voiceChimeWakeDescription =>
      'Viene riprodotto quando Voice Satellite inizia ad ascoltare.';

  @override
  String get voiceChimeDoneTitle => 'Suono di fine';

  @override
  String get voiceChimeDoneDescription =>
      'Viene riprodotto al termine di un\'interazione vocale.';

  @override
  String get voiceChimeErrorTitle => 'Suono di errore';

  @override
  String get voiceChimeErrorDescription =>
      'Viene riprodotto quando un\'interazione vocale non riesce.';

  @override
  String get voiceChimeTimerTitle => 'Suono del timer';

  @override
  String get voiceChimeTimerDescription =>
      'Si ripete quando un timer termina, finché non lo chiudi.';

  @override
  String get voiceChimeAnnounceTitle => 'Suono degli annunci';

  @override
  String get voiceChimeAnnounceDescription =>
      'Viene riprodotto prima di un annuncio di Voice Satellite, a meno che l\'annuncio non abbia un suono proprio.';

  @override
  String get settingVoiceWakeSoundTitle => 'Riproduci i segnali acustici';

  @override
  String get settingVoiceWakeSoundDescription =>
      'I suoni di attivazione, di fine e di errore.';

  @override
  String get voiceChimeWakeVolumeTitle => 'Volume del suono di attivazione';

  @override
  String get voiceChimeDoneVolumeTitle => 'Volume del suono di fine';

  @override
  String get voiceChimeErrorVolumeTitle => 'Volume del suono di errore';

  @override
  String get voiceChimeTimerVolumeTitle => 'Volume del suono del timer';

  @override
  String get voiceChimeAnnounceVolumeTitle => 'Volume del suono degli annunci';

  @override
  String get voiceChimeVolumeDescription =>
      'Una percentuale del volume dell\'assistente.';

  @override
  String get voiceChimesSoundsHint =>
      'Suoni di attivazione, di fine, di errore e degli annunci';

  @override
  String get settingVoiceShowCommandTitle => 'Mostra ciò che hai detto';

  @override
  String get settingVoiceShowCommandDescription =>
      'Il tuo comando sopra la risposta.';

  @override
  String get settingVoiceShowAnswerTitle => 'Mostra la risposta';

  @override
  String get settingVoiceShowAnswerDescription =>
      'La risposta mentre viene pronunciata.';

  @override
  String get settingVoiceShowToolsTitle => 'Mostra l\'uso degli strumenti';

  @override
  String get settingVoiceShowToolsDescription =>
      'Una riga per ogni azione compiuta dall\'assistente.';

  @override
  String get settingVoiceHideSentimentTagsTitle =>
      'Nascondi i tag delle emozioni';

  @override
  String get settingVoiceHideSentimentTagsDescription =>
      'Omette i tag come [happy] che alcuni assistenti aggiungono.';

  @override
  String get settingVoiceAnswerLingerTitle =>
      'Mantieni la risposta sullo schermo';

  @override
  String get settingVoiceAnswerLingerDescription =>
      'Dopo che la risposta è stata pronunciata.';

  @override
  String get settingVoiceResultsLingerTitle =>
      'Mantieni i risultati sullo schermo';

  @override
  String get settingVoiceResultsLingerDescription =>
      'Immagini, meteo e altri risultati. Con 0 restano finché non li chiudi.';

  @override
  String get settingVoiceAnnouncementLingerTitle => 'Durata degli annunci';

  @override
  String get settingVoiceAnnouncementLingerDescription =>
      'Dopo che un annuncio è stato pronunciato.';

  @override
  String get voiceEngine => 'Motore';

  @override
  String get voiceEngineHelp => 'Avvia o arresta il motore di Voice Satellite.';

  @override
  String get voiceAssigned => 'Satellite assegnato';

  @override
  String get voiceAssignedHelp =>
      'L\'entità assist_satellite con cui questo kiosk si identifica in Home Assistant. Se la cambi, la plancia viene ricaricata.';

  @override
  String get voiceAssignedSearch =>
      'L\'entità assist_satellite con cui questo kiosk si identifica in Home Assistant.';

  @override
  String get voiceNoneAssigned => 'Nessuno assegnato';

  @override
  String get voiceAutoStart => 'Avvio automatico';

  @override
  String get voiceAutoStartHelp =>
      'Avvia automaticamente Voice Satellite al caricamento della plancia.';

  @override
  String get voiceMuteHelp => 'Smette di ascoltare le parole di attivazione.';

  @override
  String get voicePipeline1 => 'Pipeline di Assist 1';

  @override
  String get voicePipeline1Help =>
      'La pipeline di Assist che elabora i comandi vocali.';

  @override
  String get voicePipeline2 => 'Pipeline di Assist 2';

  @override
  String get voicePipeline2Help =>
      'La pipeline usata quando viene rilevata la seconda parola di attivazione.';

  @override
  String get voiceVad => 'Rilevamento della fine del parlato';

  @override
  String get voiceVadHelp =>
      'Quanto deve durare una pausa per concludere un comando vocale.';

  @override
  String get voiceMutedWarning =>
      'Disabilita l\'avviso di microfono disattivato';

  @override
  String get voiceMutedWarningHelp =>
      'Nasconde l\'avviso di microfono disattivato all\'avvio e ogni volta che il microfono del satellite viene disattivato.';

  @override
  String get voiceDebug => 'Registro di debug';

  @override
  String get voiceDebugHelp =>
      'Mostra le informazioni di debug di Voice Satellite nella console del browser.';

  @override
  String get voiceVersion => 'Versione di Voice Satellite';

  @override
  String get voiceVersionHelp =>
      'La versione dell\'integrazione installata in Home Assistant.';

  @override
  String get voiceVadDefault => 'Predefinito';

  @override
  String get voiceVadRelaxed => 'Tollerante';

  @override
  String get voiceVadAggressive => 'Aggressivo';

  @override
  String get voiceGeneral => 'Generale';

  @override
  String get voiceStart => 'Avvia';

  @override
  String get voiceNotavailable => 'Non disponibile';

  @override
  String get voiceDisabled => 'Disabilitato';

  @override
  String get settingWakeWordBackgroundTitle =>
      'Continua ad ascoltare in background';

  @override
  String get settingWakeWordBackgroundDescription =>
      'Continua a sentire la parola di attivazione mentre un\'altra app è in primo piano e torna in primo piano quando la rileva. Richiede una notifica permanente e l\'autorizzazione Mostra sopra altre app.';

  @override
  String get settingWakeWordReturnToBackgroundTitle =>
      'Torna all\'app precedente';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      'Torna all\'app precedente o alla schermata Home quando termina un\'interazione vocale che ha portato Kiosk Satellite in primo piano.';

  @override
  String get voiceAssistant => 'Assistente';

  @override
  String get voiceConversation => 'Conversazione';

  @override
  String get voiceTimers => 'Timer';

  @override
  String get voiceAssistantHint => 'Pipeline, riascolto';

  @override
  String get voiceConversationHint =>
      'Cosa mostra la sovrapposizione e per quanto tempo';

  @override
  String get voiceSectionFollowUp => 'Riascolto';

  @override
  String get voiceSectionLinger => 'Durata sullo schermo';

  @override
  String get voiceSectionOnScreen => 'Sullo schermo';

  @override
  String get voiceSectionPills => 'Indicatori';

  @override
  String get voiceSectionSpeaker => 'Altoparlante';

  @override
  String get voiceSectionRecognition => 'Recognition';

  @override
  String get voiceSectionTrimming => 'Trimming';

  @override
  String get voiceSectionIsolation => 'Isolation';

  @override
  String get voiceSectionWakeCommand => 'Parola di attivazione e comando';

  @override
  String get voiceSectionTimerEnds => 'Quando un timer termina';

  @override
  String get voiceSectionSharedTimers => 'Timer condivisi';

  @override
  String get voiceStatusEsphomeOff => 'Il server ESPHome è disattivato.';

  @override
  String get voiceStatusNotAdded =>
      'Questo kiosk non è ancora stato aggiunto a Home Assistant.';

  @override
  String get voiceStatusMuted => 'Il microfono è disattivato.';

  @override
  String get voiceStatusNotListening =>
      'La parola di attivazione non è in ascolto.';

  @override
  String get voiceStatusListening => 'In ascolto della parola di attivazione.';

  @override
  String get voiceWordNotAdded => 'Non aggiunto';

  @override
  String get voiceWordMuted => 'Silenziato';

  @override
  String get voiceWordBusy => 'Occupato';

  @override
  String get voiceWordListening => 'In ascolto';

  @override
  String get voiceWordNotListening => 'Non in ascolto';

  @override
  String get voiceWordAdded => 'Aggiunto';

  @override
  String get voiceHaAddAgainHint =>
      'Aggiungi questo kiosk in Impostazioni, Dispositivi e servizi di Home Assistant, dove appare come rilevato. Se Home Assistant lo aveva già, lì ti chiede la nuova chiave di crittografia dalla pagina ESPHome.';

  @override
  String get voiceHaEsphomeOff =>
      'Attiva il server ESPHome affinché Home Assistant possa aggiungere questo kiosk come satellite.';

  @override
  String get voiceWordReloadNeeded => 'Ricaricamento necessario';

  @override
  String get voiceHaSelectsReloadHint =>
      'Home Assistant non ha caricato i selettori Assistente e Parola di attivazione. Ricarica la voce ESPHome di questo kiosk in Impostazioni, Dispositivi e servizi. Funziona anche riavviare Home Assistant.';

  @override
  String get voiceTurnOn => 'Attiva';

  @override
  String get voiceRollbackTitle => 'Torna a eseguire dalla plancia';

  @override
  String get voiceRollbackDescription =>
      'Torna all\'integrazione Voice Satellite. Nulla di ciò che hai impostato qui va perso.';

  @override
  String get voiceRollbackConfirm => 'Tornare a eseguire dalla plancia?';

  @override
  String get voiceRollbackBody =>
      'La plancia esegue di nuovo Voice Satellite tramite l\'integrazione, con le impostazioni che aveva prima. Ciò che imposti qui resta per la prossima volta.';

  @override
  String get voiceRollbackSwitch => 'Torna indietro';

  @override
  String get voiceMigrateNotice =>
      'Voice Satellite è attualmente installato come integrazione in Home Assistant. Passa a un\'esperienza nativa all\'interno di Kiosk Satellite.';

  @override
  String get voiceMigrate => 'Migra';

  @override
  String get settingVoiceEnabledTitle => 'Abilita Voice Satellite';

  @override
  String get settingVoiceEnabledDescription =>
      'Trasforma questo kiosk in un assistente vocale per Home Assistant tramite il suo server ESPHome.';

  @override
  String get settingVoiceMuteTitle => 'Disattiva il microfono';

  @override
  String get settingVoiceMuteDescription =>
      'Smette di ascoltare la parola di attivazione.';

  @override
  String get voiceMigrationTitle => 'Migra Voice Satellite';

  @override
  String get voiceMigrationPick =>
      'Scegli il satellite dell\'integrazione Voice Satellite che questo kiosk sostituisce. Le sue impostazioni vengono trasferite a questo kiosk.';

  @override
  String get voiceMigrationNoSatellites =>
      'L\'integrazione Voice Satellite non ha satelliti.';

  @override
  String get voiceMigrationIntro =>
      'Questo kiosk diventa esso stesso il satellite vocale. Dopo questa operazione l\'integrazione Voice Satellite non serve più.';

  @override
  String get voiceMigrationCheckAgain => 'Verifica di nuovo';

  @override
  String get voiceCheckHaBad =>
      'Non connesso. Controlla in Configurazione di Home Assistant.';

  @override
  String get voiceCheckEsphome => 'Questo kiosk in Home Assistant';

  @override
  String get voiceCheckEsphomeOk => 'Aggiunto tramite ESPHome.';

  @override
  String get voiceCheckEsphomeBad =>
      'Non ancora aggiunto. Home Assistant mostra questo kiosk come rilevato in Impostazioni, Dispositivi e servizi. Aggiungilo lì, poi torna qui.';

  @override
  String get voiceCheckEsphomeOff =>
      'Il server ESPHome è disattivato. Attivalo, poi aggiungi questo kiosk in Home Assistant.';

  @override
  String get voiceCheckAdmin => 'Token di amministratore';

  @override
  String get voiceCheckAdminOk =>
      'L\'uso degli strumenti e i risultati verranno mostrati.';

  @override
  String get voiceCheckAdminBad =>
      'Il token appartiene a un utente normale. Voice Satellite funziona, ma l\'uso degli strumenti e i risultati non verranno mostrati.';

  @override
  String get voiceCheckAdminUnknown =>
      'Impossibile verificare il token. L\'uso degli strumenti e i risultati richiedono quello di un amministratore.';

  @override
  String get voiceCheckMicOk => 'Consentito.';

  @override
  String get voiceCheckMicBad =>
      'Non consentito. Concedilo in Autorizzazioni di sistema richieste.';

  @override
  String get voiceTurnOnEsphome => 'Attiva ESPHome';

  @override
  String get voiceMigrationPlan => 'Impostazioni da trasferire';

  @override
  String get voiceGroupVoice => 'Voce';

  @override
  String get voiceMigrationNotCarried =>
      'Non trasferiti: il CSS personalizzato, l\'elaborazione del microfono del browser e la durata della memoria della conversazione. I modelli microWakeWord personalizzati funzionano da config/custom_wake_words in Home Assistant.';

  @override
  String get voiceMigrationAutomations => 'Automazioni e script';

  @override
  String get voiceMigrationNoAutomations =>
      'Nulla in Home Assistant fa riferimento al vecchio satellite.';

  @override
  String get voiceKindAutomation => 'Automazione';

  @override
  String get voiceKindScript => 'Script';

  @override
  String get voiceMigrationReady => 'Pronto per il passaggio';

  @override
  String get voiceMigrationReady1 =>
      'Questo kiosk ascolta, risponde e disegna la sovrapposizione.';

  @override
  String get voiceMigrationReadyOnboarding =>
      'Il suo assistente e le parole di attivazione vengono impostati quando Home Assistant aggiunge questo kiosk.';

  @override
  String get voiceMigrationReady2 =>
      'La plancia smette di eseguire Voice Satellite su questo kiosk.';

  @override
  String get voiceMigrationReady3 =>
      'Il vecchio satellite resta in Home Assistant, inutilizzato.';

  @override
  String get voiceMigrationSwitch => 'Passa ora';

  @override
  String get voiceMigrationSwitching => 'Passaggio in corso…';

  @override
  String get voiceMigrationDone => 'Voice Satellite ora funziona qui';

  @override
  String get voiceCouldNotSwitch => 'Impossibile effettuare il passaggio';

  @override
  String get voiceMigrationDoneOnboarding =>
      'Completa la configurazione, poi aggiungi questo kiosk in Home Assistant. Quando nessun altro dispositivo usa più l\'integrazione Voice Satellite, disinstallala da HACS.';

  @override
  String get voiceMigrationDoneHelp =>
      'Pronuncia la parola di attivazione per provarlo. Quando nessun altro dispositivo usa più l\'integrazione Voice Satellite, disinstallala da HACS.';

  @override
  String get voiceMigrationRolledBack =>
      'Voice Satellite viene di nuovo eseguito dalla plancia.';

  @override
  String get voiceDone => 'Fine';

  @override
  String get voiceTryAgain => 'Riprova';

  @override
  String get voiceStepSave => 'Salva le impostazioni';

  @override
  String get voiceStepStop => 'Arresta il motore della plancia';

  @override
  String get voiceStepStart => 'Inizia ad ascoltare qui';

  @override
  String get voiceStepTurnOn => 'Attiva Voice Satellite su questo kiosk';

  @override
  String get voiceStepEntities =>
      'Imposta le entità del kiosk in Home Assistant';

  @override
  String get voiceStepCheck => 'Verifica il satellite in Home Assistant';

  @override
  String voiceMigrationStep(String n, String total) {
    return 'Passaggio $n di $total';
  }

  @override
  String voiceMigrationStillPoint(String satellite) {
    return 'Queste fanno ancora riferimento a $satellite. Modificale in Home Assistant per usare il satellite di questo kiosk. La procedura guidata non le modifica.';
  }

  @override
  String get voiceMigrationNotUp => 'Il satellite non si è avviato in tempo.';

  @override
  String get voiceMigrationNotReported =>
      'Home Assistant non ha segnalato il satellite.';

  @override
  String get voiceMigrationBusy => 'Una migrazione è già in corso.';

  @override
  String get voiceMicHeld =>
      'Il rilevamento della parola di attivazione può sentirti.';

  @override
  String get voiceMicBlocked =>
      'Bloccata. Android non la chiederà più, quindi consentila nelle impostazioni dell\'app.';

  @override
  String get voiceMicMissing =>
      'Senza questa autorizzazione, niente ascolta la parola di attivazione.';

  @override
  String get voiceForegroundHeld =>
      'Kiosk Satellite può passare in primo piano quando ti sente.';

  @override
  String get voiceForegroundMissing =>
      'Senza questa autorizzazione, la parola di attivazione viene sentita ma non succede nulla.';

  @override
  String get voiceNotificationHeld =>
      'La notifica permanente che consente l\'ascolto in background.';

  @override
  String get voiceNotificationMissing =>
      'Necessaria perché l\'ascolto in background funzioni in modo affidabile.';

  @override
  String get voiceBatteryHeld => 'Android lascerà in esecuzione l\'ascolto.';

  @override
  String get voiceBatteryMissing =>
      'Senza questa autorizzazione, l\'ascolto viene interrotto dopo alcune ore.';

  @override
  String get voicePermissionDirections =>
      'Concedile sul dispositivo stesso: scorri dal bordo sinistro → Impostazioni → Voice Satellite → Autorizzazioni di sistema richieste.';

  @override
  String get voicePermissionsSearch =>
      'Il microfono e le altre autorizzazioni necessarie per il rilevamento della parola di attivazione.';

  @override
  String get voiceRealtime => 'Tempo reale';

  @override
  String get voiceRealtimeProvidersHint =>
      'OpenAI, xAI Grok, Gemini, strumenti, interruzione delle risposte';

  @override
  String get voiceRealtimeToolsSection => 'Strumenti di Home Assistant';

  @override
  String get voiceRealtimeProviderDefault => 'Predefinito del fornitore';

  @override
  String get voiceRealtimeToolsCustom => 'Server MCP personalizzato';

  @override
  String get settingVoiceRealtimeEndpointTitle => 'Endpoint';

  @override
  String get settingVoiceRealtimeEndpointDescription =>
      'Lascia vuoto per usare il fornitore. Usa un relay nella tua rete per mantenere questo kiosk offline.';

  @override
  String get settingVoiceRealtimeApiKeyTitle => 'Chiave API';

  @override
  String get settingVoiceRealtimeApiKeyDescription =>
      'Lascia vuoto se la aggiunge un relay.';

  @override
  String get settingVoiceRealtimeModelTitle => 'Modello';

  @override
  String get settingVoiceRealtimeVoiceTitle => 'Voce';

  @override
  String get settingVoiceRealtimeInstructionsTitle => 'Istruzioni';

  @override
  String get settingVoiceRealtimeInstructionsDescription =>
      'Come si comporta l\'assistente. Lascia vuoto per usare un breve testo predefinito.';

  @override
  String get settingVoiceRealtimeIdleSecondsTitle => 'Termina dopo il silenzio';

  @override
  String get settingVoiceRealtimeIdleSecondsDescription =>
      'La conversazione termina dopo questo tempo senza che nessuno parli.';

  @override
  String get settingVoiceRealtimeReasoningTitle => 'Livello di ragionamento';

  @override
  String get settingVoiceRealtimeReasoningDescription =>
      'Un livello più alto risponde meglio alle domande difficili. Richiede un modello gpt-realtime-2.';

  @override
  String get settingVoiceRealtimeGeminiReasoningDescription =>
      'Un livello più alto risponde meglio alle domande difficili. Richiede un modello che ragiona, come gemini-3.8-live-extended-thinking.';

  @override
  String get settingVoiceRealtimeGeminiSearchTitle => 'Ricerca Google';

  @override
  String get settingVoiceRealtimeGeminiSearchBillingDescription =>
      'Consente al modello di cercare informazioni sul web. Richiede la fatturazione attiva per la chiave API.';

  @override
  String get settingVoiceRealtimeGeminiProactiveTitle =>
      'Ignora ciò che non gli è rivolto';

  @override
  String get settingVoiceRealtimeGeminiProactiveDescription =>
      'Il modello resta in silenzio quando ciò che sente non gli è rivolto. Funzione sperimentale di Google.';

  @override
  String get settingVoiceRealtimeXaiWebSearchTitle => 'Ricerca web';

  @override
  String get settingVoiceRealtimeXaiWebSearchDescription =>
      'Consente al modello di cercare informazioni sul web.';

  @override
  String get settingVoiceRealtimeXaiXSearchTitle => 'Ricerca su X';

  @override
  String get settingVoiceRealtimeXaiXSearchDescription =>
      'Consente al modello di cercare post su X.';

  @override
  String get voiceRealtimeReasoningDefault => 'Predefinito del modello';

  @override
  String get voiceRealtimeReasoningMinimal => 'Minimo';

  @override
  String get voiceRealtimeReasoningLow => 'Basso';

  @override
  String get voiceRealtimeReasoningMedium => 'Medio';

  @override
  String get voiceRealtimeReasoningHigh => 'Alto';

  @override
  String get voiceRealtimeReasoningExtraHigh => 'Molto alto';

  @override
  String get settingVoiceRealtimeSpeedTitle => 'Velocità del parlato';

  @override
  String get settingVoiceRealtimeSpeedDescription =>
      'Quanto velocemente parla l\'assistente.';

  @override
  String get settingVoiceRealtimeHistoryHoursTitle => 'Durata della sessione';

  @override
  String get settingVoiceRealtimeHistoryHoursDescription =>
      'Ciò che è stato detto entro questo tempo viene riportato nella conversazione successiva.';

  @override
  String get settingVoiceRealtimeTalkOverTitle => 'Interrompi le risposte';

  @override
  String get settingVoiceRealtimeTalkOverDescription =>
      'Permette di interrompere una risposta parlando. Disattivala se l\'assistente si interrompe da solo.';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityTitle =>
      'Sensibilità dell\'interruzione';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityDescription =>
      'Quanto facilmente la voce interrompe una risposta. Aumentala se l\'interruzione non funziona con un microfono poco sensibile. Valori più alti possono far sì che l\'assistente si interrompa da solo.';

  @override
  String get settingVoiceRealtimeToolsTitle => 'Strumenti';

  @override
  String get settingVoiceRealtimeToolsDescription =>
      'Cosa può controllare l\'assistente. Home Assistant usa la sua integrazione MCP Server e le entità esposte ad Assist.';

  @override
  String get settingVoiceRealtimeMcpUrlTitle => 'URL del server MCP';

  @override
  String get settingVoiceRealtimeMcpUrlDescription =>
      'L\'indirizzo Streamable HTTP del server.';

  @override
  String get settingVoiceRealtimeMcpTokenTitle => 'Token MCP';

  @override
  String get settingVoiceRealtimeMcpTokenDescription =>
      'Inviato come token bearer. Lascia vuoto se il server non lo richiede.';

  @override
  String get voiceRealtimeMcpMissing =>
      'Aggiungi l\'integrazione MCP Server in Home Assistant per controllare la tua casa.';

  @override
  String get voiceRealtimeNotValidated => 'Non verificato';

  @override
  String voiceRealtimeOption(String provider) {
    return '$provider in tempo reale';
  }

  @override
  String voiceRealtimeConnectFailed(String error) {
    return 'Impossibile connettersi: $error';
  }

  @override
  String voiceRealtimeToolsUnavailable(String problem) {
    return 'Connesso, ma gli strumenti di Home Assistant non sono disponibili: $problem';
  }

  @override
  String get settingVoiceRealtimeModelDescription =>
      'Il modello da voce a voce che risponde.';

  @override
  String get settingVoiceRealtimeVoiceDescription =>
      'Come suona la voce dell\'assistente.';

  @override
  String get voiceRealtimeProviders => 'Fornitori';

  @override
  String get voiceRealtimeConfigure => 'Configura';

  @override
  String get voiceRealtimeSaveValidate => 'Salva e verifica';

  @override
  String get voiceRealtimeNotConfigured => 'Non configurato';

  @override
  String get voiceRealtimeValidated => 'Connessione verificata';

  @override
  String get voiceDisconnected => 'Home Assistant non connesso';

  @override
  String get voiceValidate =>
      'Verifica prima la connessione in Configurazione di Home Assistant.';

  @override
  String get voiceChecking => 'Ricerca di Voice Satellite…';

  @override
  String get voiceMissing =>
      'Voice Satellite non è installato in Home Assistant';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite trasforma questo kiosk in un assistente vocale completo e a mani libere per Home Assistant: rilevamento della parola di attivazione, conversazioni, timer e annunci, direttamente sulla plancia.\n\nÈ disponibile nel repository predefinito di HACS. Installalo nella tua istanza di Home Assistant, poi torna qui.';

  @override
  String get voiceLearnMore => 'Scopri di più su ';

  @override
  String get voiceGithub => 'Voice Satellite su GitHub';

  @override
  String get voiceHacs => 'Apri il repository HACS';

  @override
  String get voiceLoading => 'Caricamento dei controlli di Voice Satellite…';

  @override
  String get voiceTester => 'Test della parola di attivazione';

  @override
  String get voiceTesterHelp =>
      'Osserva in tempo reale cosa sente il motore e che punteggio assegna, per capire perché la parola di attivazione si attiva o no.';

  @override
  String get voiceTesterSearch =>
      'Una vista in tempo reale di cosa sente il motore e del punteggio che assegna.';

  @override
  String get voiceTesterWaiting => 'In attesa di Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word (parola di arresto)';
  }

  @override
  String get voiceScore => 'Punteggio';

  @override
  String get voiceThreshold => 'Soglia';

  @override
  String get voiceHits => 'Rilevamenti';

  @override
  String get voiceNearMisses => 'Quasi rilevamenti';

  @override
  String get voicePeak => 'Picco';

  @override
  String get voiceMicLevel => 'Livello del microfono';

  @override
  String get voiceChunkProcessing =>
      'Elaborazione dei blocchi (min / media / max)';

  @override
  String get voiceLog => 'Registro';

  @override
  String get voiceLogEmpty =>
      'Qui verranno mostrati i rilevamenti e i quasi rilevamenti.';

  @override
  String get voiceLogHit => 'RILEVATO';

  @override
  String get voiceLogNear => 'quasi';

  @override
  String get voiceLogScore => 'punteggio';

  @override
  String get voiceLogDecoded => 'decodificato';

  @override
  String get voiceLogDistance => 'dist.';

  @override
  String get voiceLogConfidence => 'conf.';

  @override
  String get voiceTesterPlayRecent => 'Riproduci gli ultimi 10 secondi';

  @override
  String get settingVoiceTimerPillsViewTitle =>
      'Mostra i timer come indicatori';

  @override
  String get settingVoiceTimerPillsViewDescription =>
      'I timer fluttuano sopra lo schermo invece di aprire la vista a schermo intero.';

  @override
  String get settingVoiceTimerNameInPillTitle => 'Mostra il nome del timer';

  @override
  String get settingVoiceTimerNameInPillDescription =>
      'Il nome accanto al tempo in un indicatore.';

  @override
  String get settingVoiceTimerPillScaleTitle =>
      'Scala degli indicatori dei timer';

  @override
  String get settingVoiceTimerPillScaleDescription =>
      'La dimensione degli indicatori dei timer.';

  @override
  String get settingVoiceTimerAlertPillTitle =>
      'Mostra gli indicatori dei timer terminati';

  @override
  String get settingVoiceTimerAlertPillDescription =>
      'Tocca l\'indicatore per interrompere l\'avviso.';

  @override
  String get settingVoiceMuteTimersTitle => 'Silenzia gli avvisi dei timer';

  @override
  String get settingVoiceMuteTimersDescription =>
      'Mostra l\'avviso senza il suono.';

  @override
  String get settingVoiceTimerNameOnAlertTitle => 'Mostra il nome nell\'avviso';

  @override
  String get settingVoiceTimerNameOnAlertDescription =>
      'Il nome del timer sotto l\'avviso.';

  @override
  String get settingVoiceTimerSpeakTitle => 'Parla quando un timer termina';

  @override
  String get settingVoiceTimerSpeakDescription =>
      'Pronuncia una frase tra i suoni dell\'avviso.';

  @override
  String get settingVoiceTimerPhraseTitle => 'Frase';

  @override
  String get settingVoiceTimerPhraseDescription =>
      'Pronunciata per un timer senza nome.';

  @override
  String get settingVoiceTimerNamedPhraseTitle => 'Frase per i timer con nome';

  @override
  String settingVoiceTimerNamedPhraseDescription(String name) {
    return '$name viene sostituito con il nome del timer.';
  }

  @override
  String get settingVoiceTimersShareTitle => 'Condividi i timer';

  @override
  String get settingVoiceTimersShareDescription =>
      'I timer avviati su questo kiosk vengono eseguiti anche sui kiosk che scegli.';

  @override
  String get settingVoiceTimersShareWithTitle => 'Condividi con';

  @override
  String get settingVoiceTimersShareWithDescription =>
      'I kiosk che mostrano e fanno suonare i timer di questo.';

  @override
  String get settingVoiceTimersReceiveTitle => 'Mostra i timer condivisi';

  @override
  String get settingVoiceTimersReceiveDescription =>
      'I timer condivisi da altri kiosk vengono mostrati e suonano qui.';

  @override
  String get settingKioskAllowTimersTitle => 'Timer';

  @override
  String get settingKioskAllowTimersDescription =>
      'Apre la vista Timer dal menu del kiosk.';

  @override
  String get settingsMenuTimersSummary =>
      'Vista a schermo intero, indicatori, timer condivisi';

  @override
  String get fleetTheKiosksPickedInShareWithTheTimerSound =>
      'i kiosk scelti in Condividi con, il suono del timer';

  @override
  String get settingTimersTtsEngineDescription =>
      'L\'entità di sintesi vocale di Home Assistant che annuncia i timer.';

  @override
  String get settingTimersTtsLanguageDescription =>
      'La lingua in cui vengono annunciati i timer.';

  @override
  String get settingTimersTtsVoiceDescription =>
      'La voce che annuncia i timer.';

  @override
  String get settingTimersShowBeforeEndTitle =>
      'Mostra la vista Timer quando un timer sta per finire';

  @override
  String get settingTimersShowBeforeEndDescription =>
      'Quanto tempo prima della fine di un timer si apre la vista Timer.';

  @override
  String get settingTimersEnabledTitle => 'Abilita i timer';

  @override
  String get settingTimersEnabledDescription =>
      'Imposta i timer su questo kiosk con la voce e a mano.';

  @override
  String get settingTimersShowOnStartTitle =>
      'Mostra la vista Timer all\'avvio di un timer';

  @override
  String get settingTimersShowOnStartDescription =>
      'Apre la vista Timer ogni volta che viene avviato un timer.';

  @override
  String get settingTimersPauseScreensaverTitle =>
      'Sospendi il salvaschermo mentre un timer è attivo';

  @override
  String get settingTimersPauseScreensaverDescription =>
      'Impedisce l\'avvio del salvaschermo mentre la vista Timer mostra un timer attivo.';

  @override
  String get settingTimersViewScaleTitle => 'Scala della vista Timer';

  @override
  String get settingTimersViewScaleDescription =>
      'La dimensione dei nomi dei timer e dei pulsanti nella vista Timer.';

  @override
  String get settingTimersSilenceAfterTitle => 'Silenzia dopo';

  @override
  String get settingTimersSilenceAfterDescription =>
      'Il timer terminato resta sullo schermo finché non viene chiuso.';

  @override
  String get settingTimersDismissAfterTitle => 'Chiudi dopo';

  @override
  String get settingTimersDismissAfterDescription =>
      'Cancella un timer terminato come se fosse stato toccato Chiudi.';

  @override
  String get settingVoiceMatchPolicyDescriptionChosen =>
      'Con Persone scelte vengono ignorati la TV, gli ospiti e tutti gli altri.';

  @override
  String get voiceMatchOptionPeople => 'Persone scelte';

  @override
  String get settingVoiceMatchPeopleTitle => 'Persone';

  @override
  String get settingVoiceMatchPeopleDescription =>
      'A chi risponde questo kiosk. Se non scegli nessuno, risponde a chiunque sia registrato.';

  @override
  String get voiceMatchPeopleNone => 'Chiunque sia registrato';

  @override
  String get voiceMatchPeopleSearch => 'Cerca persone';

  @override
  String get voiceMatchPeopleEmpty =>
      'Nessuno è ancora registrato in Ground Control.';

  @override
  String get voiceMatchPeopleGone => 'Non è più in Ground Control';

  @override
  String voiceMatchPeopleMissing(String names) {
    return 'Non presenti in questo Ground Control: $names. Scegli di nuovo.';
  }

  @override
  String get settingVoiceMatchRejectedTitleChosen => 'Voce non scelta';

  @override
  String get voiceMatchFeaturesHint => 'Recognition, Trimming e Isolation';

  @override
  String get settingVoiceMatchEnabledTitle => 'Abilita Voice Match';

  @override
  String get settingVoiceMatchPolicyTitle => 'Rispondi a';

  @override
  String get settingVoiceMatchRejectedDescription =>
      'Cosa succede quando qualcun altro pronuncia la parola di attivazione.';

  @override
  String get settingVoiceMatchSpeakerSensorTitle => 'Sensore Speaker';

  @override
  String get settingVoiceMatchSpeakerSensorDescription =>
      'Aggiunge a questo kiosk un sensore Speaker in Home Assistant, per automazioni e istruzioni dell\'agente.';

  @override
  String get voiceMatchOptionAnyone => 'Chiunque';

  @override
  String get voiceMatchOptionQuiet => 'Resta in silenzio';

  @override
  String get voiceMatchOptionChime => 'Riproduci il segnale acustico di errore';

  @override
  String get voiceMatchConnecting => 'Connessione in corso';

  @override
  String get voiceMatchSearching => 'Ricerca in corso';

  @override
  String get voiceMatchNotReachable => 'Non raggiungibile';

  @override
  String get voiceMatchSignInRefused => 'Accesso rifiutato';

  @override
  String get voiceMatchNobodyEnrolled => 'Nessuno è ancora registrato.';

  @override
  String get voiceMatchTokenRefused =>
      'Home Assistant ha rifiutato il token di questo kiosk.';

  @override
  String get settingVoiceMatchShowSpeakerTitle => 'Mostra chi sta parlando';

  @override
  String get settingVoiceMatchShowSpeakerDescription =>
      'Il nome di chi parla prima del comando nella sovrapposizione vocale, nel suo colore. Su un dispositivo con anello luminoso, l\'arco di ascolto assume quel colore.';

  @override
  String get settingVoiceMatchAllowEnrollTitle =>
      'Consenti la registrazione qui';

  @override
  String get voiceMatchAppHint =>
      'Persone, registrazione, sessioni e impostazioni.';

  @override
  String get voiceMatchOpen => 'Apri';

  @override
  String get settingVoiceMatchEnabledDescriptionCommand =>
      'Chi sta parlando, e solo la sua voce nel comando. Richiede Ground Control.';

  @override
  String get settingVoiceMatchAllowEnrollDescriptionGroundControl =>
      'Consente all\'app Ground Control di registrare la voce di una persona con il microfono di questo kiosk. Il kiosk mostra il testo da leggere, oppure l\'anello luminoso mostra l\'avanzamento.';

  @override
  String get settingVoiceMatchTrimmingTitle => 'Abilita Trimming';

  @override
  String get settingVoiceMatchTrimmingDescription =>
      'Le altre voci, come una TV o altre persone, vengono tagliate tra le parole di chi ha pronunciato la parola di attivazione, e il comando termina quando smette di parlare.';

  @override
  String get settingVoiceMatchIsolationTitle => 'Abilita Isolation';

  @override
  String get settingVoiceMatchIsolationDescription =>
      'Vengono rimosse anche le altre voci che si sovrappongono alle parole di chi ha pronunciato la parola di attivazione. Quando smette di parlare, il comando attende che l\'elaborazione finisca. Richiede Isolation attivo in Ground Control.';

  @override
  String get voiceWakePage => 'Parola di attivazione';

  @override
  String get voiceWakeHint =>
      'Motore, parole di attivazione, sensibilità, modelli in cache';

  @override
  String get voiceWakeLabel => 'Parola di attivazione';

  @override
  String get voiceWakeEngine => 'Motore della parola di attivazione';

  @override
  String get voiceWakeEngineHelp =>
      'Dove viene eseguito il rilevamento e quale motore ascolta.';

  @override
  String get voiceWake1 => 'Parola di attivazione 1';

  @override
  String get voiceWake1Help => 'La parola che avvia un comando vocale.';

  @override
  String get voiceWake2 => 'Parola di attivazione 2';

  @override
  String get voiceWake2Help =>
      'Una seconda parola di attivazione, gestita dalla pipeline di Assist 2.';

  @override
  String get voiceSensitivity => 'Sensibilità della parola di attivazione';

  @override
  String get voiceSensitivityHelp =>
      'Quanto facilmente si attiva la parola di attivazione.';

  @override
  String get voiceNoiseGate => 'Soglia di rumore della parola di attivazione';

  @override
  String get voiceNoiseGateHelp =>
      'Salta l\'inferenza locale della parola di attivazione quando la stanza è silenziosa, risparmiando CPU.';

  @override
  String get voiceStopInterruption => 'Interruzione con parola di arresto';

  @override
  String get voiceStopInterruptionHelp =>
      'Pronuncia la parola di arresto per interrompere le risposte.';

  @override
  String get voiceAssignFirst =>
      'Assegna un satellite per controllare queste impostazioni.';

  @override
  String get voiceCachedModels => 'Modelli in cache';

  @override
  String get voiceCachedModelsHelp =>
      'Scarica di nuovo i modelli da Home Assistant. Da usare dopo aver ripubblicato un modello.';

  @override
  String get voiceClearCache => 'Svuota cache';

  @override
  String get voiceClearing => 'Svuotamento…';

  @override
  String voiceCacheCleared(String count) {
    return 'File eliminati: $count. Nuovo download in corso.';
  }

  @override
  String voiceCacheCount(String count) {
    return 'File eliminati: $count';
  }

  @override
  String get voiceVerySensitive => 'Molto sensibile';

  @override
  String get voiceWakeWordPreferFp32Title =>
      'Preferisci i modelli vsWakeWord fp32';

  @override
  String get voiceWakeWordPreferFp32Description =>
      'Usa i modelli fp32 invece delle versioni int8 più piccole. Aumenta l\'uso della CPU del 10-30% durante l\'ascolto per evitare una deriva di confidenza di circa il 2%.';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle =>
      'Timeout di ripresa (secondi)';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      'Ripristino automatico: riprende l\'ascolto se la pagina non chiama mai setWakeWordActive(true) dopo un passaggio di controllo. Attende finché un turno vocale sta ancora trasmettendo audio, così un turno lungo non viene mai interrotto.';

  @override
  String get voiceSlightlySensitive => 'Poco sensibile';

  @override
  String get voiceModeratelySensitive => 'Mediamente sensibile';

  @override
  String get voiceOnDevice => 'Sul dispositivo';

  @override
  String voiceOnDeviceEngine(String engine) {
    return 'Sul dispositivo ($engine)';
  }

  @override
  String get voiceDiagnosticsPage => 'Diagnostica della parola di attivazione';

  @override
  String get voiceDiagnosticsHint =>
      'Attivazioni recenti e quasi attivazioni con clip audio';

  @override
  String get voiceDiagnosticsTitle =>
      'Abilita la diagnostica della parola di attivazione';

  @override
  String get voiceDiagnosticsDescription =>
      'Registra le ultime 10 attivazioni e quasi attivazioni della parola di attivazione con i relativi punteggi e una clip audio di 3 secondi per ciascuna. Disattivandola vengono eliminate.';

  @override
  String get voiceDiagnosticsEmpty =>
      'Nessuna attivazione della parola di attivazione ancora registrata.';

  @override
  String get voiceDiagnosticsActivations => 'Attivazioni';

  @override
  String get voiceDiagnosticsNoNearMisses =>
      'Nessuna quasi attivazione ancora registrata.';

  @override
  String get voiceDiagnosticsPeakLevel => 'Livello di picco';

  @override
  String get voiceDiagnosticsAverageLevel => 'Livello medio';

  @override
  String get voiceDiagnosticsClipped => 'Saturato';

  @override
  String get voiceDiagnosticsHeard => 'Sentito';

  @override
  String get voiceWake2HelpNative =>
      'Una seconda parola di attivazione, a cui risponde l\'Assistente 2.';

  @override
  String get voiceCustomModels => 'Modelli personalizzati';

  @override
  String get voiceCustomNone => 'Ancora nessun modello personalizzato.';

  @override
  String get voiceCustomManaged =>
      'Il leader della flotta gestisce i modelli personalizzati su questo kiosk.';

  @override
  String get voiceCustomAdd => 'Aggiungi modelli';

  @override
  String get voiceCustomAddHelp =>
      'Scegli i file di uno o più modelli. Compaiono qui sopra in Parola di attivazione 1 e 2.';

  @override
  String get voiceCustomDocs => 'Come aggiungere modelli personalizzati';

  @override
  String get voiceCustomDocsHelp =>
      'I file che servono a ciascun motore e da dove provengono i modelli.';

  @override
  String get voiceCustomNotAdded => 'I modelli non sono stati aggiunti.';

  @override
  String get voiceCustomSomeNotAdded => 'Alcuni file non sono stati aggiunti.';

  @override
  String get voiceCustomAdded => 'Modelli aggiunti.';

  @override
  String get voiceCustomDeleteConfirm => 'Eliminare questo modello?';

  @override
  String get voiceCustomNotDeleted => 'Il modello non è stato eliminato.';

  @override
  String get voiceCustomOtherEngine => 'non è il motore in uso';

  @override
  String get settingVoiceWakeWordEngineDescription =>
      'Quale motore ascolta. Tutti i modelli sono inclusi nell\'app.';

  @override
  String get settingVoiceWakeWordSensitivityTitle =>
      'Sensibilità della parola di attivazione';

  @override
  String get settingVoiceWakeWordSensitivityDescription =>
      'Quanto facilmente si attiva la parola di attivazione.';

  @override
  String get settingVoiceWakeWordFineTuneTitle =>
      'Regolazione fine della sensibilità';

  @override
  String get settingVoiceWakeWordFineTuneDescription =>
      'Regola la sensibilità della parola di attivazione a passi più piccoli. Aumentala se devi ripetere spesso la parola di attivazione, abbassala se si attiva per errore.';

  @override
  String get settingVoiceNoiseGateTitle =>
      'Soglia di rumore della parola di attivazione';

  @override
  String get settingVoiceNoiseGateDescription =>
      'Salta l\'inferenza della parola di attivazione quando la stanza è silenziosa, risparmiando CPU.';

  @override
  String get settingVoiceStopWordTitle => 'Interruzione con parola di arresto';

  @override
  String get settingVoiceStopWordDescription =>
      'Di\' \"stop\" per interrompere una risposta, un avviso del timer o un annuncio.';

  @override
  String get settingVoiceStopWordFineTuneTitle =>
      'Regolazione fine della sensibilità della parola di arresto';

  @override
  String get settingVoiceStopWordFineTuneDescription =>
      'Regola la sensibilità della parola di arresto a passi più piccoli. Aumentala se devi ripetere spesso \"stop\", abbassala se le risposte si interrompono per errore.';

  @override
  String get settingVoiceWakeArbitrationTitle =>
      'Abilita l\'arbitraggio della parola di attivazione';

  @override
  String get settingVoiceWakeArbitrationDescription =>
      'Quando più kiosk sentono la parola di attivazione, risponde quello più vicino. Aumenta la latenza di rilevamento.';

  @override
  String get settingVoiceWakeArbitrationWindowTitle =>
      'Finestra di arbitraggio';

  @override
  String get settingVoiceWakeArbitrationWindowDescription =>
      'Quanto attendere gli altri kiosk. Aumentala se un kiosk più lento perde anche quando è più vicino.';

  @override
  String get settingVoiceWakeArbitrationOffsetTitle =>
      'Compensazione dell\'arbitraggio';

  @override
  String get settingVoiceWakeArbitrationOffsetDescription =>
      'Si somma all\'intensità con cui questo kiosk ha sentito la parola di attivazione. Aumentala se questo kiosk perde anche quando è più vicino, abbassala se risponde da troppo lontano.';

  @override
  String get voiceSectionWakeArbitration =>
      'Arbitraggio della parola di attivazione';

  @override
  String get voiceOptionSlightly => 'Poco sensibile';

  @override
  String get voiceOptionModerately => 'Mediamente sensibile';

  @override
  String get voiceOptionVery => 'Molto sensibile';

  @override
  String get voiceModelNotFileName => 'Non è un nome di file.';

  @override
  String get voiceModelBadExtension =>
      'Solo i file .json, .tflite e .onnx sono modelli.';

  @override
  String voiceModelTooLarge(String name) {
    return '$name supera i 64 MB.';
  }

  @override
  String voiceModelIncomplete(String name) {
    return '$name è arrivato incompleto.';
  }

  @override
  String voiceModelBadJson(String file) {
    return '$file non è un JSON valido.';
  }

  @override
  String voiceModelNotManifest(String file) {
    return '$file non è un manifest.';
  }

  @override
  String voiceModelMwwNeedsTflite(String file) {
    return 'Un modello microWakeWord richiede anche $file.';
  }

  @override
  String voiceModelMwwBadManifest(String file) {
    return '$file non è un manifest microWakeWord valido.';
  }

  @override
  String voiceModelVswwNeedsOnnx(String file) {
    return 'Un modello vsWakeWord richiede anche $file.';
  }

  @override
  String voiceModelVswwBadManifest(String file) {
    return '$file non è un manifest vsWakeWord valido.';
  }

  @override
  String voiceModelUnknownManifest(String file) {
    return '$file non è un manifest né microWakeWord né vsWakeWord.';
  }

  @override
  String voiceModelNoModelFile(String name) {
    return 'Nessun file di modello per $name.';
  }

  @override
  String voiceModelBothFormats(String onnx, String tflite) {
    return 'Aggiungi $onnx oppure $tflite, non entrambi.';
  }

  @override
  String voiceModelNotOwwTflite(String file, String json) {
    return '$file non è un modello openWakeWord. Un modello microWakeWord richiede anche il relativo $json.';
  }

  @override
  String get voiceModelNotTflite => 'Non è un modello TFLite.';

  @override
  String get voiceModelNotOnnx => 'Non è un modello ONNX.';

  @override
  String get voiceModelNotOww => 'Non è un modello openWakeWord.';

  @override
  String get voiceModelOwwWindow =>
      'Non è un modello openWakeWord: non accetta la finestra di embedding 16 x 96.';

  @override
  String voiceModelNoLoad(String error) {
    return 'Il modello non si carica: $error';
  }

  @override
  String get settingVoiceAmazonLocaleTitle =>
      'Lingua della parola di attivazione';

  @override
  String get settingVoiceAmazonLocaleDescription =>
      'La lingua dei modelli di parola di attivazione di Amazon. I selettori della parola di attivazione offrono le parole di attivazione disponibili in quella lingua.';

  @override
  String get settingDisableCacheTitle => 'Disabilita la cache';

  @override
  String get settingDisableCacheDescription =>
      'Carica sempre dalla rete e scarta i dati della pagina in cache al caricamento, così una plancia ripubblicata è sempre aggiornata. Rallenta: consideralo uno strumento di sviluppo.';

  @override
  String get settingAllowMixedContentTitle => 'Consenti contenuti misti';

  @override
  String get settingAllowMixedContentDescription =>
      'Consente alle pagine HTTPS di caricare risorse HTTP non sicure. Utile quando in una plancia https:// Home Assistant inserisce anche contenuti http:// non sicuri.';

  @override
  String get settingIgnoreSslErrorsTitle => 'Ignora errori SSL';

  @override
  String get settingIgnoreSslErrorsDescription =>
      'Accetta certificati non attendibili o autofirmati. Da usare solo sulla tua rete, perché disattiva la verifica dei certificati.';

  @override
  String get settingBrowserUserAgentTitle => 'User agent personalizzato';

  @override
  String get settingBrowserUserAgentDescription =>
      'Inviato ai siti web al posto dello user agent predefinito. Lascia vuoto per usare quello predefinito.';

  @override
  String get webGeolocationSection => 'Geolocalizzazione HTML5';

  @override
  String get settingWebGeolocationTitle =>
      'Abilita l\'accesso alla geolocalizzazione';

  @override
  String get settingWebGeolocationDescription =>
      'Consente alle pagine di leggere la posizione del dispositivo, ad esempio per un radar meteo o una mappa. Solo le pagine caricate tramite HTTPS possono richiederla.';

  @override
  String get webGeolocationPermissionHeld =>
      'Le pagine possono leggere la posizione del dispositivo.';

  @override
  String get webGeolocationPermissionMissing =>
      'Senza questa autorizzazione le pagine non possono leggere la posizione del dispositivo.';

  @override
  String get settingAutoReloadOnErrorTitle =>
      'Ricarica automatica in caso di errore';

  @override
  String get settingAutoReloadOnErrorDescription =>
      'Ripristina automaticamente dopo errori della pagina e arresti anomali dell\'app.';

  @override
  String get settingPullToRefreshTitle => 'Abilita trascina per aggiornare';

  @override
  String get settingPullToRefreshDescription =>
      'Trascina verso il basso dalla parte superiore della pagina per ricaricarla. Disattivato per impostazione predefinita: su una plancia che scorre è facile trascinare per errore.';

  @override
  String get settingPullToRefreshClearCacheTitle =>
      'Svuota la cache quando trascini per aggiornare';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      'Il trascinamento svuota anche la cache web e i modelli della parola di attivazione prima di ricaricare, così tutto torna aggiornato. L\'accesso e i dati salvati delle pagine vengono conservati.';

  @override
  String get settingBrowserZoomTitle => 'Livello di zoom';

  @override
  String get settingBrowserZoomDescription =>
      'Ridimensiona l\'intera pagina. Sopra 1x per tablet a parete visti da lontano; sotto 1x per far stare più plancia su uno schermo piccolo.';

  @override
  String get settingPinchToZoomTitle => 'Abilita pizzica per ingrandire';

  @override
  String get settingPinchToZoomDescription =>
      'Ingrandisce la pagina con un pizzico a due dita. Disattivato per impostazione predefinita, così la plancia del kiosk resta ferma in caso di tocchi accidentali.';

  @override
  String get settingDisableScrollingTitle => 'Disabilita lo scorrimento';

  @override
  String get settingDisableScrollingDescription =>
      'Blocca la pagina in posizione, così non può scorrere in nessuna direzione. Tocchi e pulsanti continuano a funzionare.';

  @override
  String get browserCrashPermissionHelp =>
      'Senza questa autorizzazione il kiosk non può riaprirsi dopo un arresto anomalo.';

  @override
  String get browserCrashPermissionMissing =>
      'Autorizzazione \"Mostra sopra altre app\" mancante';

  @override
  String get browserCrashPermissionRemoteHelp =>
      'Senza questa autorizzazione il kiosk non può riaprirsi da solo dopo un arresto anomalo. La schermata per concederla compare sul tablet.';

  @override
  String get settingBrowserInjectJsTitle =>
      'Inserisci JavaScript nella plancia di HA';

  @override
  String get settingBrowserInjectJsDescription =>
      'Esegue questo codice JavaScript dopo ogni caricamento della pagina della plancia. Utile per nascondere elementi che distraggono o modificare una plancia che non controlli.';

  @override
  String get settingBrowserInjectJsExternalTitle =>
      'Inserisci JavaScript nelle pagine esterne';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      'Esegue questo codice JavaScript dopo il caricamento di ogni pagina esterna: pagine aperte da un link della plancia, pagine della rotazione della plancia e salvaschermo sito web. La pagina di Music Assistant non viene toccata.';

  @override
  String get browserInjectJsPlaceholder =>
      '// Esempio: nascondi un elemento che distrae\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// Esempio: ingrandisci un sito che ignora il livello di zoom della plancia\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get urlFilterTitle => 'Filtro URL';

  @override
  String get urlFilterHint =>
      'Blocca o consenti le pagine in base a un modello di indirizzo o a un\'espressione regolare';

  @override
  String get urlFilterIntroTitle => 'Controlla quali pagine si aprono';

  @override
  String get urlFilterIntroSub =>
      'I link o le pagine che corrispondono a una regola Blocca non vengono caricati. Aggiungi una regola Consenti solo per caricare solo le pagine che corrispondono.';

  @override
  String get urlFilterAdd => 'Aggiungi regola';

  @override
  String get urlFilterAddTitle => 'Aggiungi regola di filtro';

  @override
  String get urlFilterEditTitle => 'Modifica regola di filtro';

  @override
  String get urlFilterName => 'Nome';

  @override
  String get urlFilterPattern => 'Modello';

  @override
  String get urlFilterPatternWildcardHint =>
      'Usa * per indicare qualsiasi cosa. Un modello che inizia con / corrisponde al percorso su qualsiasi server, ad esempio /history*.';

  @override
  String get urlFilterPatternRegexHint =>
      'Un\'espressione regolare cercata in qualsiasi punto dell\'indirizzo, senza distinguere maiuscole e minuscole.';

  @override
  String get urlFilterType => 'Tipo di modello';

  @override
  String get urlFilterTypeWildcard => 'Carattere jolly';

  @override
  String get urlFilterTypeRegex => 'Espressione regolare';

  @override
  String get urlFilterAction => 'Azione';

  @override
  String get urlFilterActionBlock => 'Blocca';

  @override
  String get urlFilterActionAllow => 'Consenti solo';

  @override
  String get urlFilterActionAllowHint =>
      'Dove si applica questa regola, vengono caricate solo le pagine che corrispondono a una regola Consenti solo. L\'accesso a Home Assistant e la plancia iniziale vengono sempre caricati.';

  @override
  String get urlFilterScope => 'Si applica a';

  @override
  String get urlFilterScopeAll => 'Plancia e pagine esterne';

  @override
  String get urlFilterScopeDashboard => 'Plancia';

  @override
  String get urlFilterScopeExternal => 'Pagine esterne';

  @override
  String get urlFilterScopeHint =>
      'Le pagine esterne sono i link aperti dalla plancia e le pagine della rotazione della plancia.';

  @override
  String get urlFilterErrorName => 'Inserisci un nome.';

  @override
  String get urlFilterErrorPattern => 'Inserisci un modello.';

  @override
  String get urlFilterErrorRegex => 'Questa espressione regolare non è valida.';

  @override
  String get urlFilterBlocked => 'Pagina bloccata';

  @override
  String get urlFilterNotAllowed => 'Non è tra le pagine consentite';

  @override
  String get settingBrowserUrlFilterNoticeTitle =>
      'Mostra avviso di pagina bloccata';

  @override
  String get settingBrowserUrlFilterNoticeDescription =>
      'Mostra un breve avviso con il nome della regola quando una pagina viene bloccata.';

  @override
  String get setupConnectHeading => 'Connettiti a Home Assistant';

  @override
  String get setupConnectLead =>
      'L\'URL di base della tua istanza e un token di accesso di lunga durata, creato nel tuo profilo di HA → Sicurezza → Token di accesso di lunga durata.';

  @override
  String get setupBaseUrl => 'URL di base di Home Assistant';

  @override
  String get setupToken => 'Token di accesso di lunga durata';

  @override
  String get setupScanQr => 'Scansiona il codice QR';

  @override
  String get setupInvalidToken => 'Token di accesso non valido';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant ha rifiutato questo token. In Home Assistant, apri il tuo profilo → Sicurezza → Token di accesso di lunga durata, crea un nuovo token e copia il valore completo.';

  @override
  String get setupUnreachable => 'Impossibile raggiungere Home Assistant';

  @override
  String get setupUnreachableHelp =>
      'Nessuna risposta da questo indirizzo. Verifica che l\'URL sia corretta e che questo dispositivo sia sulla stessa rete del tuo server Home Assistant.';

  @override
  String get setupUnexpectedResponseHelp =>
      'Ha risposto un server, ma non sembra essere Home Assistant. Verifica che l\'URL sia l\'indirizzo di base di Home Assistant, ad esempio https://homeassistant.local:8123.';

  @override
  String get setupCannotConnect => 'Impossibile connettersi';

  @override
  String get setupCameraPermission =>
      'Serve l\'autorizzazione per la fotocamera';

  @override
  String get setupCameraBlocked =>
      'Consenti la fotocamera per Kiosk Satellite nelle impostazioni di Android per scansionare il codice QR.';

  @override
  String get setupCameraAllow =>
      'Consenti la fotocamera per scansionare il codice QR.';

  @override
  String get setupEnterBaseUrl => 'Inserisci l\'URL di base di Home Assistant';

  @override
  String get setupInvalidBaseUrl => 'URL di base non valida';

  @override
  String get setupBaseUrlHelp =>
      'È l\'indirizzo che usi per aprire Home Assistant, ad esempio https://homeassistant.local:8123.';

  @override
  String get setupEnterToken => 'Inserisci un token di accesso di lunga durata';

  @override
  String get setupEnterTokenHelp =>
      'In Home Assistant, apri il tuo profilo → Sicurezza → Token di accesso di lunga durata per crearne uno.';

  @override
  String get setupValidateContinue => 'Verifica e continua';

  @override
  String setupUnexpectedResponse(String error) {
    return 'Risposta inattesa ($error)';
  }

  @override
  String get baseUrlInvalid =>
      'Inserisci un\'URL valida, ad esempio https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      'Inserisci solo l\'URL di base, senza il percorso di una plancia. Esempio: https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      'Inserisci solo l\'URL di base, senza nulla dopo la porta. Esempio: https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => 'Scegli una plancia';

  @override
  String get setupDashboardHelp => 'È ciò che il kiosk mostrerà all\'avvio.';

  @override
  String get setupSelectDashboard => 'Seleziona una plancia';

  @override
  String get setupSelectDashboardHelp =>
      'Scegli la plancia che il kiosk mostrerà. Puoi cambiarla in seguito in Impostazioni.';

  @override
  String get setupHeadlessGrants =>
      'Questo dispositivo non ha uno schermo, quindi Android non può richiederle sul dispositivo stesso. Concedile una per una tramite adb, poi termina qui.';

  @override
  String get setupWelcome => 'Benvenuto';

  @override
  String get setupConnect => 'Connessione';

  @override
  String get setupConnectSummary => 'URL e token di Home Assistant';

  @override
  String get setupDashboard => 'Plancia';

  @override
  String get setupDashboardSummary => 'Cosa mostra il kiosk';

  @override
  String get setupRecommendedSummary => 'Impostazioni consigliate';

  @override
  String get setupPermissions => 'Autorizzazioni';

  @override
  String get setupPermissionsSummary => 'Cosa serve alla configurazione';

  @override
  String get setupPermissionLead =>
      'Android chiederà queste autorizzazioni. Vengono richieste tutte subito, così il kiosk non ti interromperà più in seguito.';

  @override
  String get setupRemotePermissionLead =>
      'Android le chiede direttamente sul tablet. Avvicinati, accetta le richieste e poi termina qui.';

  @override
  String get setupMicrophoneHelp =>
      'Voice Satellite e l\'interfono richiedono l\'accesso al microfono';

  @override
  String get setupNotificationListening =>
      'Consente la notifica permanente del Servizio Kiosk Satellite, che indica cosa mantiene attivo e quando il kiosk è in ascolto.';

  @override
  String get setupBatteryService =>
      'Consente al Servizio Kiosk Satellite di funzionare in background senza essere sospeso o chiuso.';

  @override
  String get setupOverlayBoot =>
      'Consente a Kiosk Satellite di riaprirsi dopo un arresto anomalo e di avviarsi all\'accensione del dispositivo.';

  @override
  String get setupOverlayCrash =>
      'Consente a Kiosk Satellite di tornare sullo schermo dopo un arresto anomalo.';

  @override
  String get setupBrightnessHelp =>
      'Consente a Kiosk Satellite di impostare la luminosità effettiva dello schermo (modifica delle impostazioni di sistema).';

  @override
  String get setupScreenControl => 'Controllo dello schermo';

  @override
  String get setupScreenControlHelp =>
      'Consente a Kiosk Satellite di spegnere lo schermo su richiesta (amministratore del dispositivo).';

  @override
  String get setupGrantPermissions =>
      'Concedi le autorizzazioni sul dispositivo';

  @override
  String get setupRequestingPermissions => 'Richiesta sul dispositivo…';

  @override
  String get setupPermissionsRequested =>
      'Autorizzazioni richieste sul dispositivo';

  @override
  String get setupQrFlipCamera => 'Cambia fotocamera';

  @override
  String get setupQrCameraFailed => 'Impossibile avviare la fotocamera.';

  @override
  String get setupQrTitle => 'Scansiona il codice QR del token';

  @override
  String get setupQrHelp =>
      'Compare accanto a un token appena creato nel tuo profilo di Home Assistant.';

  @override
  String get setupQrFlashOff => 'Spegni la torcia';

  @override
  String get setupQrFlashOn => 'Accendi la torcia';

  @override
  String get setupQrScreenLightOff => 'Spegni la luce dello schermo';

  @override
  String get setupQrScreenLightOn => 'Accendi la luce dello schermo';

  @override
  String get setupPasswordFirst =>
      'Imposta prima la password di amministrazione';

  @override
  String get setupPasswordBeforeImport =>
      'Digita una password di amministrazione qui sopra (almeno 4 caratteri), poi importa il backup.';

  @override
  String get setupPasswordFailed => 'Impossibile impostare la password';

  @override
  String get setupPasswordExists => 'È già impostata una password';

  @override
  String get setupPasswordExistsHelp =>
      'Accedi con la password impostata sul tablet per continuare qui. Ricaricamento…';

  @override
  String get setupNotBackup => 'Non è un file di backup';

  @override
  String get setupInvalidBackupHelp =>
      'Questo file non è un JSON valido. Esporta una configurazione da Impostazioni su un Kiosk Satellite già configurato, oppure dalla sua amministrazione remota.';

  @override
  String get setupWrongBackupKind =>
      'Esporta una configurazione dalla scheda Impostazioni di un Kiosk Satellite già configurato.';

  @override
  String get setupImportFailedHelp => 'Impossibile applicare il file.';

  @override
  String get setupBackupNoDashboard => 'Il backup non contiene una plancia';

  @override
  String get setupBackupNoDashboardHelp =>
      'Le impostazioni sono state applicate, ma questo backup è stato creato prima che il suo dispositivo fosse configurato, quindi non c\'è una plancia da mostrare. Prosegui con la procedura guidata per sceglierne una.';

  @override
  String get setupImporting => 'Importazione…';

  @override
  String get setupRemoteRestoreHelp =>
      'Importa una configurazione esportata da Kiosk Satellite e salta il resto di questa procedura guidata.';

  @override
  String get setupFinishOnDevice => 'Termina sul dispositivo';

  @override
  String get setupFinishOnDeviceHelp =>
      'La configurazione è stata importata. Rispondi alle richieste di autorizzazione sullo schermo del tablet. Questa pagina prosegue automaticamente quando la plancia viene caricata.';

  @override
  String get setupBackupObject => 'Il backup deve contenere un oggetto JSON.';

  @override
  String get setupBackupKind =>
      'Questo non è un file di configurazione di Kiosk Satellite.';

  @override
  String get setupBackupSettings => 'Il backup non contiene impostazioni.';

  @override
  String get setupServiceHelp =>
      'Mantiene attiva l\'app quando lo schermo è spento o un\'altra app è in primo piano, così la connessione a Home Assistant e altre funzionalità come il rilevamento del movimento e il proxy Bluetooth restano attive. Le autorizzazioni qui sotto sono facoltative ma consigliate: ognuna aiuta l\'app a restare attiva a schermo spento.';

  @override
  String get setupBatteryMissing =>
      'Android potrebbe sospendere l\'app quando lo schermo è spento, interrompendo anche la connessione a Home Assistant.';

  @override
  String get setupOverlayMissing =>
      'Senza questa autorizzazione il servizio non può riavviare il kiosk dopo un arresto anomalo.';

  @override
  String get setupVoiceDetected => 'Integrazione Voice Satellite rilevata';

  @override
  String get setupVoiceHelp =>
      'Questa istanza di Home Assistant esegue l\'integrazione Voice Satellite. Scegli quale satellite è questo kiosk, poi controlla le sue impostazioni. Puoi cambiare tutto in seguito.';

  @override
  String get setupNoSatellites => 'Nessun satellite trovato';

  @override
  String get setupNoSatellitesHelp =>
      'Aggiungi un satellite di Assist nell\'integrazione Voice Satellite, oppure continua senza e sceglilo in seguito dalla plancia.';

  @override
  String get setupNewSatelliteHelp =>
      'Se questo è un nuovo dispositivo, crea prima una nuova entità satellite in Home Assistant. Impostazioni → Dispositivi e servizi → Voice Satellite → Aggiungi voce. IMPORTANTE: due dispositivi non possono condividere la stessa entità.';

  @override
  String get setupApplyRecommended =>
      'Applica tutte le impostazioni consigliate';

  @override
  String get setupRecommendedHelp =>
      'Le impostazioni ottimali per sfruttare appieno l\'integrazione Voice Satellite e le sue funzionalità.';

  @override
  String get setupVoiceRequired => 'Richiesto da Voice Satellite';

  @override
  String get setupMicrophoneAccess => 'Accesso al microfono';

  @override
  String get setupNativeWakeWord =>
      'Rilevamento nativo della parola di attivazione';

  @override
  String get setupPullRefresh => 'Trascina per aggiornare';

  @override
  String get setupAutoplay => 'Riproduzione automatica di audio e video';

  @override
  String get setupVoiceSkipped => 'Non installata, saltata';

  @override
  String get setupVoiceLead =>
      'Trasforma questo kiosk in un assistente vocale per Home Assistant. Puoi cambiare tutto in seguito.';

  @override
  String get setupVoiceAddAgainHint =>
      'Dopo la configurazione, aggiungi questo kiosk in Home Assistant in Impostazioni, Dispositivi e servizi, dove compare come rilevato. Se Home Assistant lo aveva già, lì ti chiede la nuova Chiave di crittografia dalla pagina ESPHome.';

  @override
  String get setupRecommendedWall =>
      'Le impostazioni adatte a un kiosk a parete.';

  @override
  String get setupVoiceFound => 'Integrazione Voice Satellite trovata';

  @override
  String get setupVoiceFoundHelp =>
      'Voice Satellite ora funziona all\'interno di Kiosk Satellite. Esegui la migrazione per mantenere le parole di attivazione, l\'assistente e l\'aspetto di uno dei satelliti dell\'integrazione invece di ricominciare da zero.';

  @override
  String get setupVoiceMigrated => 'Migrato dall\'integrazione Voice Satellite';

  @override
  String get setupVoiceMigratedHelp =>
      'Questo kiosk riprende le impostazioni del suo satellite.';

  @override
  String get setupVoicePipelineHelp =>
      'La pipeline di Assist che risponde alla parola di attivazione.';

  @override
  String get setupVoiceEngineHelp =>
      'Il motore che ascolta la parola di attivazione.';

  @override
  String get setupRemoteHeading => 'Amministrazione remota';

  @override
  String get setupTitle => 'Configura\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      'Trasforma questo tablet in un kiosk per Home Assistant. La configurazione richiede un paio di minuti e questa procedura guidata ti accompagna passo passo.';

  @override
  String get setupDeviceName => 'Nome del dispositivo';

  @override
  String get setupDeviceNameHelp =>
      'Il nome di questo kiosk in Home Assistant, nell\'amministrazione remota e sulla rete. Puoi cambiarlo quando vuoi in Impostazioni, Dispositivo.';

  @override
  String get setupEnableRemote => 'Abilita l\'amministrazione remota';

  @override
  String get setupEnableRemoteHelp =>
      'Continua a gestire questo kiosk da un browser web dopo la configurazione: da lì incollare il token di accesso di Home Assistant è molto più facile.';

  @override
  String get setupRemotePassword => 'Password di amministrazione remota';

  @override
  String get setupRestoreHeading => 'Ripristina backup';

  @override
  String get setupRestore => 'Ripristina da file di configurazione';

  @override
  String get setupRestoreHelp =>
      'Importa una configurazione esportata da Kiosk Satellite e salta il resto di questa procedura guidata. Vengono importati impostazioni, plancia e accesso.';

  @override
  String get setupServicePermissions =>
      'Autorizzazioni consigliate per il servizio';

  @override
  String get setupPasswordShort => 'Password troppo corta';

  @override
  String get setupPasswordMinimum => 'Usa almeno 4 caratteri.';

  @override
  String setupRemoteAddress(String address) {
    return 'Puoi continuare questa configurazione da remoto con un browser web all\'indirizzo $address, che l\'interruttore qui sopra sia attivo o no.';
  }

  @override
  String get remoteWelcomeTitle => 'Benvenuto in Kiosk Satellite';

  @override
  String get remoteWelcomePassword =>
      'Questo tablet è in attesa di configurazione. Per prima cosa, proteggi questa amministrazione remota con una password.';

  @override
  String get remoteWelcomeReady =>
      'Questo tablet è in attesa di configurazione. La password di amministrazione remota è già impostata; per cambiarla, digitane una nuova qui.';

  @override
  String get remoteInitialPassword =>
      'Password di amministrazione (min. 4 caratteri)';

  @override
  String get remoteNewPassword =>
      'Nuova password di amministrazione (lascia vuoto per mantenere quella attuale)';

  @override
  String get intercomBuiltinRing => 'Suoneria integrata';

  @override
  String get intercomBuiltinChime => 'Segnale acustico integrato';

  @override
  String intercomMissingFile(String file) {
    return '$file (mancante)';
  }

  @override
  String get intercomAddSound => 'Aggiungi un suono';

  @override
  String get intercomCopySoundHelp =>
      'Copia un file audio da questo dispositivo nella cartella dei suoni.';

  @override
  String get intercomUploadSoundHelp =>
      'Carica un file audio da questo computer nella cartella dei suoni.';

  @override
  String get intercomUpload => 'Carica';

  @override
  String get intercomUploading => 'Caricamento…';

  @override
  String get intercomUnsupportedSound => 'Suono non supportato';

  @override
  String get intercomChooseSound =>
      'Suono non supportato: scegli un file MP3, OGG, WAV, FLAC, M4A o AAC.';

  @override
  String get intercomCopyFailed => 'Impossibile copiare il file';

  @override
  String intercomUploadFailed(String error) {
    return 'Caricamento non riuscito: $error';
  }

  @override
  String intercomSaveFailed(String error) {
    return 'Non salvato: $error';
  }

  @override
  String get intercomSoundFilename =>
      'Inserisci un nome di file, non un percorso.';

  @override
  String get intercomSoundFormats =>
      'Scegli un file MP3, OGG, WAV, FLAC, M4A o AAC.';

  @override
  String voiceMatchEnrollTitle(String name) {
    return 'Registrazione di $name';
  }

  @override
  String get voiceMatchEnrollStarting => 'Preparazione…';

  @override
  String get voiceMatchEnrollReading => 'Leggi questo ad alta voce';

  @override
  String voiceMatchEnrollSeconds(String seconds, String target) {
    return '$seconds di $target s';
  }

  @override
  String get voiceMatchEnrollOtherVoice =>
      'Sta parlando un\'altra voce. Quella parte viene scartata.';

  @override
  String get voiceMatchEnrollSaving => 'Salvataggio…';

  @override
  String get voiceMatchEnrollStop => 'Interrompi';

  @override
  String get voiceMatchEnrollTipWalk => 'Cammina lentamente per la stanza';

  @override
  String get voiceMatchEnrollTipTurn =>
      'Ogni tanto voltati dando le spalle al kiosk';

  @override
  String get voiceMatchEnrollTipTalk => 'Parla come quando dai i comandi';

  @override
  String voiceMatchEnrollDone(String name) {
    return 'Voce di $name registrata';
  }

  @override
  String voiceMatchEnrollDoneDetail(String seconds) {
    return '$seconds s di parlato aggiunti.';
  }

  @override
  String get voiceMatchEnrollFailed => 'Non è stato salvato nulla';

  @override
  String get voiceMatchEnrollTooShort =>
      'Troppo poco parlato da salvare. Leggi per almeno 10 secondi.';

  @override
  String get voiceMatchEnrollLost =>
      'La connessione a Voice Match si è interrotta.';

  @override
  String get voiceMatchEnrollNoMic => 'Il microfono non è disponibile.';

  @override
  String get voiceMatchEnrollStopped =>
      'Interrotto prima che venisse registrato qualcosa.';

  @override
  String get voiceMatchEnrollPassage1 => 'Accendi le luci della cucina.';

  @override
  String get voiceMatchEnrollPassage2 => 'Imposta un timer di dieci minuti.';

  @override
  String get voiceMatchEnrollPassage3 => 'Che tempo farà domani?';

  @override
  String get voiceMatchEnrollPassage4 =>
      'Aggiungi latte e uova alla lista della spesa.';

  @override
  String get voiceMatchEnrollPassage5 =>
      'Metti un po\' di musica tranquilla in soggiorno.';

  @override
  String get voiceMatchEnrollPassage6 =>
      'La mattina faceva freddo, così siamo rimasti in casa a preparare i pancake.';

  @override
  String get voiceMatchEnrollPassage7 =>
      'Più tardi siamo andati a piedi al parco e abbiamo guardato i cani rincorrersi sull\'erba.';

  @override
  String get voiceMatchEnrollPassage8 =>
      'La sera si è alzato il vento e abbiamo acceso il camino.';

  @override
  String get voiceMatchEnrollPassage9 =>
      'Spegni tutte le luci al piano di sotto.';

  @override
  String get voiceMatchEnrollPassage10 => 'Che ore sono a Tokyo?';

  @override
  String get voiceMatchEnrollPassage11 =>
      'Ricordami di chiamare il dentista lunedì.';

  @override
  String get voiceMatchEnrollPassage12 =>
      'Quanto ci vuole in auto per arrivare all\'aeroporto?';

  @override
  String get voiceMatchEnrollPassage13 => 'Metti in pausa la musica.';

  @override
  String get voiceMatchEnrollPassage14 => 'Buonanotte.';

  @override
  String get voiceNoticeError => 'Errore di Voice Satellite';

  @override
  String get voiceNoticeWarning => 'Avviso di Voice Satellite';

  @override
  String get voiceNoticeNotice => 'Notifica di Voice Satellite';

  @override
  String get voiceNoticeTts => 'Sintesi vocale';

  @override
  String get voiceNoticeAssistPipeline => 'Pipeline di Assist';

  @override
  String voiceNoticePipeline(String name) {
    return 'Pipeline \"$name\"';
  }

  @override
  String get voiceNoticeMicUnavailable => 'Il microfono non è disponibile.';

  @override
  String get voiceNoticeNotConnected =>
      'Home Assistant non è connesso a questo kiosk.';

  @override
  String get voiceNoticeConnectionLost =>
      'Connessione a Home Assistant persa. Riconnessione automatica in corso.';

  @override
  String get voiceNoticePlayback =>
      'Impossibile riprodurre l\'audio sul dispositivo.';

  @override
  String get voiceNoticeWatchdog =>
      'Nessuna risposta da Home Assistant dopo che hai finito di parlare. La pipeline potrebbe essere bloccata.';

  @override
  String get voiceNoticeRefused =>
      'Home Assistant non è riuscito ad avviare l\'assistente.';

  @override
  String get voiceNoticeUnexpected =>
      'Si è verificato un errore imprevisto della pipeline.';

  @override
  String get voiceNoticeMicBlocked =>
      'L\'accesso al microfono è bloccato. Consentilo per Kiosk Satellite nelle impostazioni di Android.';

  @override
  String get voiceNoticeMicDeclined =>
      'L\'accesso al microfono è stato negato, quindi la parola di attivazione non può essere sentita.';

  @override
  String get voiceNoticeMicLost => 'Il microfono ha smesso di funzionare.';

  @override
  String get voiceNoticeModels =>
      'Impossibile caricare i modelli della parola di attivazione.';

  @override
  String get voiceNoticeCrashed =>
      'Il rilevatore della parola di attivazione continuava ad arrestarsi in modo anomalo su questo dispositivo, quindi è stato fermato.';

  @override
  String voiceFinancialOpen(String value) {
    return 'Apertura: $value';
  }

  @override
  String voiceFinancialHigh(String value) {
    return 'Massimo: $value';
  }

  @override
  String voiceFinancialLow(String value) {
    return 'Minimo: $value';
  }

  @override
  String voiceFinancialHigh24h(String value) {
    return 'Massimo 24h: $value';
  }

  @override
  String voiceFinancialLow24h(String value) {
    return 'Minimo 24h: $value';
  }

  @override
  String voiceFinancialMarketCap(String value) {
    return 'Cap. di mercato: $value';
  }

  @override
  String get voiceTimerDefaultName => 'Timer';

  @override
  String get voiceTimerDrag => 'Trascina per spostare i timer';

  @override
  String get voiceTimerPauseHint =>
      'Tocca per mettere in pausa. Doppio tocco per annullare. Trascina per spostare.';

  @override
  String get voiceTimerResumeHint =>
      'Tocca per riprendere. Doppio tocco per annullare. Trascina per spostare.';

  @override
  String get voiceTimerCancel => 'Annulla timer';

  @override
  String get voiceTimerActionError =>
      'Impossibile modificare il timer. Controlla la connessione e, se necessario, aggiorna Voice Satellite.';

  @override
  String get voiceTimerFinished => 'Timer terminato';

  @override
  String get voiceTimerDismissHint => 'Tocca per chiudere l\'avviso del timer.';

  @override
  String get voiceTimersViewTitle => 'Timer';

  @override
  String get voiceTimersEmpty => 'Nessun timer';

  @override
  String get voiceTimerPause => 'Pausa';

  @override
  String get voiceTimerResume => 'Riprendi';

  @override
  String get voiceTimerDismiss => 'Chiudi';

  @override
  String get voiceTimerTimesUp => 'Tempo scaduto';

  @override
  String get voiceTimerPaused => 'In pausa';

  @override
  String get voiceTimersShareNone => 'Nessun kiosk scelto';

  @override
  String get voiceTimersShareEmpty =>
      'Nessun altro kiosk trovato. Attiva l\'amministrazione remota e Trova altri kiosk su ciascuno.';

  @override
  String get voiceTimersShareOffline => 'Offline';

  @override
  String get timersVoiceSection => 'Timer vocali';

  @override
  String get timersVoiceManage => 'Gestisci i timer con Voice Satellite';

  @override
  String get timersVoiceHint =>
      'Funziona senza un blueprint né un agente di conversazione LLM.';

  @override
  String get voiceTimersShareSearch => 'Cerca kiosk';

  @override
  String get voiceTimerSetATimer => 'Imposta un timer';

  @override
  String get voiceTimerEditTimer => 'Modifica timer';

  @override
  String get voiceTimerName => 'Nome';

  @override
  String get voiceTimerHours => 'Ore';

  @override
  String get voiceTimerMinutes => 'Minuti';

  @override
  String get voiceTimerSeconds => 'Secondi';

  @override
  String get voiceTimerStartFailed => 'Impossibile avviare il timer.';

  @override
  String get timersManage => 'Gestisci i timer';

  @override
  String get voiceTimerStartUnavailable =>
      'Attiva Voice Satellite su questo kiosk per impostare i timer qui.';
}
