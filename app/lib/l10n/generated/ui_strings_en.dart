// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class UiStringsEn extends UiStrings {
  UiStringsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutApp => 'App';

  @override
  String get aboutVersion => 'App version';

  @override
  String get aboutBuild => 'Build';

  @override
  String get aboutPackage => 'Package';

  @override
  String get aboutAttribution => 'Attribution';

  @override
  String get aboutAuthor => 'Author';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutSourceCode => 'Source code';

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite is free for personal, non-commercial use. It is licensed under CC BY-NC-ND 4.0: you may use and share it, but commercial use of the app and redistribution of modified app builds are not permitted. Independent plugins have additional permission under PLUGIN-EXCEPTION.md.';

  @override
  String get aboutLocalizationCredits => 'Localization Credits';

  @override
  String get aboutLocalizationCreditsHint => 'Contributors by language';

  @override
  String get aboutCheckNow => 'Check for updates now';

  @override
  String get aboutChecking => 'Checking…';

  @override
  String get aboutCheckFailed =>
      'Update check failed. Can the device reach GitHub?';

  @override
  String get aboutOverlayMissing =>
      '\"Display over other apps\" permission missing';

  @override
  String get aboutOverlayHelp =>
      'Without it the app cannot reopen itself after updating. The grant screen appears on the tablet.';

  @override
  String aboutDownloadProgress(String percent) {
    return 'Downloading… $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get aboutAlreadyCurrent => 'Already up to date';

  @override
  String get aboutInstallHelp =>
      'The download runs on the tablet; the installation must be confirmed on the tablet screen.';

  @override
  String get aboutSystem => 'System';

  @override
  String get aboutSystemVersion => 'ROM version';

  @override
  String get aboutSystemVerifying => 'Verifying…';

  @override
  String get aboutSystemInstalling => 'Installing…';

  @override
  String get aboutSystemRestartHelp =>
      'The device restarts twice to install the update and is offline for a few minutes.';

  @override
  String get aboutSystemManual => 'New image available';

  @override
  String aboutSystemManualHelp(String version) {
    return 'Version $version of the new Echo Dot image installs by hand, not as an update.';
  }

  @override
  String get alarmsTitle => 'Alarms';

  @override
  String get alarmsSetAnAlarm => 'Set an alarm';

  @override
  String get alarmsNone => 'No alarms';

  @override
  String get alarmsDone => 'Done';

  @override
  String get alarmsRepeat => 'Repeat';

  @override
  String get alarmsLabel => 'Label';

  @override
  String get alarmsAddLabel => 'Add label';

  @override
  String get alarmsTone => 'Alarm tone';

  @override
  String get alarmsSunrise => 'Sunrise';

  @override
  String get alarmsDefaultTone => 'Default';

  @override
  String get alarmsBuiltInTone => 'Built-in alarm';

  @override
  String get alarmsSoundsFolder => 'Sounds folder';

  @override
  String get alarmsToday => 'Today';

  @override
  String get alarmsTomorrow => 'Tomorrow';

  @override
  String get alarmsOnce => 'Once';

  @override
  String get alarmsEveryDay => 'Every day';

  @override
  String get alarmsWeekdays => 'Weekdays';

  @override
  String get alarmsWeekends => 'Weekends';

  @override
  String alarmsSnoozedUntil(String time) {
    return 'Snoozed until $time';
  }

  @override
  String get alarmsSnooze => 'Snooze';

  @override
  String get alarmsStop => 'Stop';

  @override
  String get alarmsDefaultLabel => 'Alarm';

  @override
  String get alarmsSetToast => 'Alarm set';

  @override
  String alarmsRingsIn(String duration) {
    return 'Rings in $duration';
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
    return 'Alarm at $time';
  }

  @override
  String get alarmsNextWidget => 'Next alarm';

  @override
  String get alarmsManage => 'Manage alarms';

  @override
  String alarmsNextAt(String day, String time) {
    return 'Next: $day at $time';
  }

  @override
  String get alarmsNoneSet => 'No alarms set';

  @override
  String get alarmsDefaultsSection => 'Defaults';

  @override
  String get alarmsTtsSection => 'Text to Speech';

  @override
  String get alarmsEditAlarm => 'Edit alarm';

  @override
  String get alarmsTime => 'Time';

  @override
  String get alarmsRinging => 'Alarm ringing';

  @override
  String get alarmsSnoozed => 'Alarm snoozed';

  @override
  String get alarmsSunriseRunning => 'Sunrise before an alarm';

  @override
  String alarmsSunriseHint(String minutes) {
    return 'The screen brightens over $minutes minutes before it rings.';
  }

  @override
  String get alarmsDeleteFailed => 'Could not delete the alarm.';

  @override
  String alarmsDuplicate(String time) {
    return 'You already have an alarm at $time';
  }

  @override
  String get alarmsEaseIn => 'Ease in the volume';

  @override
  String alarmsEaseHint(String seconds) {
    return 'Grows to the alarm volume over $seconds seconds.';
  }

  @override
  String get alarmsSpeak => 'Speak when it rings';

  @override
  String get alarmsPhrase => 'Phrase';

  @override
  String alarmsPhraseVariables(String variables) {
    return 'Available variables: $variables';
  }

  @override
  String get alarmsVoiceSection => 'Voice Alarms';

  @override
  String get alarmsVoiceManage => 'Manage alarms using Voice Satellite';

  @override
  String get alarmsVoiceHint =>
      'Needs the Kiosk Satellite alarms blueprint and an LLM conversation agent in Home Assistant.';

  @override
  String get alarmsMusic => 'Music';

  @override
  String get alarmsMusicNone => 'None';

  @override
  String get alarmsMusicRemove => 'Remove music';

  @override
  String get alarmsMusicHint =>
      'Rings instead of the tone. The tone rings if the music cannot play.';

  @override
  String get androidAccessibilityHelp =>
      'Closes the notification shade and the recents screen whenever they open while Kiosk Mode or Lockdown Mode is protecting the screen. Kiosk Satellite does not read any screen content.';

  @override
  String get androidServiceChannelHelp =>
      'Shown while the Kiosk Satellite Service keeps the app running with the screen off or behind another app.';

  @override
  String get androidServiceListening => 'listening for a wake word';

  @override
  String get androidServiceRtspAudio => 'RTSP microphone audio enabled';

  @override
  String get androidServiceEsphome => 'serving ESPHome';

  @override
  String get androidServiceBluetooth => 'relaying Bluetooth devices';

  @override
  String get androidServiceCamera => 'watching the camera';

  @override
  String get androidServiceLocation => 'reporting the location';

  @override
  String get androidServiceRemote => 'serving the remote admin';

  @override
  String get androidServiceKiosk => 'guarding kiosk mode';

  @override
  String get androidServiceSessions => 'keeping Home Assistant connected';

  @override
  String get launcherErrorAndroidOnly => 'listing apps is Android-only';

  @override
  String launcherErrorListDetail(String error) {
    return 'could not list apps: $error';
  }

  @override
  String launcherOpenFailed(String name) {
    return 'Could not open $name';
  }

  @override
  String get launcherUninstalled => 'It may have been uninstalled.';

  @override
  String get launcherNoneHelp => 'None yet. Pick the apps the launcher offers.';

  @override
  String get launcherNone => 'None yet';

  @override
  String get launcherListFailed => 'Could not list the apps';

  @override
  String launcherListError(String error) {
    return 'Could not list the apps: $error';
  }

  @override
  String get launcherListingFailed => 'listing failed';

  @override
  String get launcherEmpty => 'No launchable apps found.';

  @override
  String get launcherSearchApps => 'Search apps';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarViewDay => 'Day';

  @override
  String get calendarViewWeek => 'Week';

  @override
  String get calendarViewMonth => 'Month';

  @override
  String get calendarViewSchedule => 'Schedule';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarTomorrow => 'Tomorrow';

  @override
  String get calendarPrevious => 'Previous';

  @override
  String get calendarNext => 'Next';

  @override
  String get calendarAllDay => 'All day';

  @override
  String calendarMore(String count) {
    return '+$count more';
  }

  @override
  String get calendarUpNext => 'Up next';

  @override
  String calendarStartsIn(String duration) {
    return 'in $duration';
  }

  @override
  String get calendarHappeningNow => 'Now';

  @override
  String get calendarLaterToday => 'Later today';

  @override
  String get calendarNothingElseToday => 'Nothing else today';

  @override
  String get calendarNothingPlanned => 'Nothing planned';

  @override
  String get calendarNothingThisWeek => 'Nothing planned this week';

  @override
  String get calendarEmptyTitle => 'No calendars yet';

  @override
  String get calendarEmptyHint =>
      'Add the Home Assistant calendars to show in Settings > Calendar.';

  @override
  String calendarOffline(String time) {
    return 'Home Assistant is not reachable. Showing the events from $time.';
  }

  @override
  String calendarTimeRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String calendarPeopleTwo(String first, String second) {
    return '$first and $second';
  }

  @override
  String get calendarRepeatsDaily => 'Every day';

  @override
  String get calendarRepeatsWeekly => 'Every week';

  @override
  String get calendarRepeatsMonthly => 'Every month';

  @override
  String get calendarRepeatsYearly => 'Every year';

  @override
  String get calendarRepeats => 'Repeats';

  @override
  String get calendarDone => 'Done';

  @override
  String get calendarCalendarsSection => 'Calendars';

  @override
  String get calendarAdd => 'Add a calendar';

  @override
  String get calendarAlreadyAdded => 'That calendar is already on the list.';

  @override
  String get calendarOpen => 'Open calendar';

  @override
  String get calendarOpenHint => 'Show the calendar on this kiosk.';

  @override
  String get calendarEditName => 'Name';

  @override
  String get calendarEditColor => 'Color';

  @override
  String get calendarEditPerson => 'Person';

  @override
  String get calendarEditPersonHint =>
      'Shows their picture on the calendar chips.';

  @override
  String get calendarEditPersonNone => 'None';

  @override
  String get calendarPickCalendar => 'Choose a calendar';

  @override
  String get calendarPickPerson => 'Choose a person';

  @override
  String get calendarColorTeal => 'Teal';

  @override
  String get calendarColorRust => 'Rust';

  @override
  String get calendarColorBlue => 'Blue';

  @override
  String get calendarColorPlum => 'Plum';

  @override
  String get calendarColorOchre => 'Ochre';

  @override
  String get calendarColorSage => 'Sage';

  @override
  String get calendarColorRose => 'Rose';

  @override
  String get calendarColorSlate => 'Slate';

  @override
  String get calendarColorCustom => 'Custom';

  @override
  String get calendarWidgetEvents => 'Events shown';

  @override
  String get calendarWidgetDays => 'Days shown';

  @override
  String get calendarWidgetTomorrow => 'Today and tomorrow';

  @override
  String get calendarWidgetWeek => 'Next 7 days';

  @override
  String get calendarWidgetAllDay => 'Show all-day events';

  @override
  String get calendarWidgetDots => 'Colored dots';

  @override
  String get calendarWidgetDotsHint =>
      'Mark events with their calendar\'s color instead of the person\'s picture.';

  @override
  String get calendarVoiceSection => 'Voice Calendar';

  @override
  String get calendarVoiceManage => 'Manage the calendar using Voice Satellite';

  @override
  String get calendarVoiceHint =>
      'Needs the Kiosk Satellite calendar blueprint and an LLM conversation agent in Home Assistant.';

  @override
  String get calendarNewEvent => 'New event';

  @override
  String get calendarEditEvent => 'Edit event';

  @override
  String get calendarFieldTitle => 'Title';

  @override
  String get calendarFieldTitleHint => 'Add a title';

  @override
  String get calendarFieldCalendars => 'Calendars';

  @override
  String get calendarFieldSharedHint =>
      'Shows once, split between their colors.';

  @override
  String get calendarFieldStarts => 'Starts';

  @override
  String get calendarFieldEnds => 'Ends';

  @override
  String get calendarFieldStartTime => 'Start time';

  @override
  String get calendarFieldEndTime => 'End time';

  @override
  String get calendarFieldEndsBeforeStart => 'Ends before it starts.';

  @override
  String get calendarFieldRepeat => 'Repeat';

  @override
  String get calendarRepeatNever => 'Does not repeat';

  @override
  String get calendarRepeatWeekdays => 'Every weekday';

  @override
  String calendarRepeatWeeklyOn(String weekday) {
    return 'Every week on $weekday';
  }

  @override
  String calendarRepeatMonthlyOn(String day) {
    return 'Every month on day $day';
  }

  @override
  String calendarRepeatYearlyOn(String date) {
    return 'Every year on $date';
  }

  @override
  String get calendarFieldLocation => 'Location';

  @override
  String get calendarFieldLocationHint => 'Add a place';

  @override
  String get calendarFieldNotes => 'Notes';

  @override
  String get calendarFieldNotesHint => 'Add notes';

  @override
  String get calendarEventAdded => 'Event added';

  @override
  String get calendarEventSaved => 'Changes saved';

  @override
  String get calendarEventDeleted => 'Event deleted';

  @override
  String get calendarSaveFailed => 'Could not save the event';

  @override
  String get calendarDeleteFailed => 'Could not delete the event';

  @override
  String calendarEditReadOnly(String calendar) {
    return '$calendar is read only.';
  }

  @override
  String calendarEditGone(String calendar) {
    return 'The event is no longer on $calendar.';
  }

  @override
  String calendarEditNotAllowed(String calendar) {
    return 'The kiosk\'s Home Assistant user may not change $calendar.';
  }

  @override
  String calendarDeleteTitle(String title) {
    return 'Delete $title?';
  }

  @override
  String calendarDeleteShared(String names) {
    return 'It comes off every calendar it is on: $names.';
  }

  @override
  String calendarSaveRepeatTitle(String title) {
    return 'Save changes to $title?';
  }

  @override
  String get calendarSaveRepeatFollowing =>
      'The new repeat starts on this day.';

  @override
  String get calendarScopeThis => 'This event';

  @override
  String get calendarScopeFollowing => 'This and following events';

  @override
  String get calendarScopeAll => 'All events';

  @override
  String get calendarEditingSection => 'Editing';

  @override
  String get cameraViewerTitle => 'Camera view';

  @override
  String get cameraViewerConnecting => 'Connecting...';

  @override
  String get cameraViewerReconnecting => 'Reconnecting...';

  @override
  String cameraViewerTrying(String transport) {
    return 'Trying $transport...';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return 'This device cannot decode $codec';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return 'This device cannot play $transport streams';
  }

  @override
  String get cameraViewerCannotDecodeStream =>
      'This device cannot decode this stream';

  @override
  String cameraViewerHaRetry(String seconds) {
    return 'Cannot reach Home Assistant. Retrying in ${seconds}s';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return 'Cannot reach the camera server. Retrying in ${seconds}s';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return 'Connection failed. Retrying in ${seconds}s';
  }

  @override
  String get cameraViewerStartRetry =>
      'The camera server could not start this stream. Retrying...';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return 'The camera server could not start this stream. Retrying in ${seconds}s';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return 'Stream not found on the camera server. Retrying in ${seconds}s';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return 'The camera server rejected the login. Retrying in ${seconds}s';
  }

  @override
  String get cameraViewerMissing => 'Stream missing from Go2RTC';

  @override
  String get commonImport => 'Import';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonFinish => 'Finish';

  @override
  String get commonWorking => 'Working…';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonGrant => 'Grant';

  @override
  String get commonEnable => 'Enable';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonTest => 'Test';

  @override
  String get commonInstall => 'Install';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonClose => 'Close';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonBrowse => 'Browse';

  @override
  String get commonSet => 'Set';

  @override
  String get commonHour => 'Hour';

  @override
  String get commonMinute => 'Minute';

  @override
  String get commonUp => 'Up';

  @override
  String get commonDown => 'Down';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSaveFailed => 'Could not save';

  @override
  String get commonColorWhite => 'White';

  @override
  String get commonColorWarm => 'Warm';

  @override
  String get commonColorAmber => 'Amber';

  @override
  String get commonColorRed => 'Red';

  @override
  String get commonColorGreen => 'Green';

  @override
  String get commonColorBlue => 'Blue';

  @override
  String get commonColorCyan => 'Cyan';

  @override
  String get commonColorDim => 'Dim';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonMoveUp => 'Move up';

  @override
  String get commonMoveDown => 'Move down';

  @override
  String get commonPreviousMonth => 'Previous month';

  @override
  String get commonNextMonth => 'Next month';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonChoose => 'Choose';

  @override
  String get dlnaPortInvalid =>
      'Enter a port between 1024 and 65535, or leave it empty';

  @override
  String get commonSelectAll => 'Select all';

  @override
  String get dashboardPickerSearch => 'Search views';

  @override
  String get dashboardPickerSearchAll => 'Search dashboards and views';

  @override
  String get dashboardPickerCurrent => 'Current';

  @override
  String get dashboardPickerDashboards => 'Dashboards';

  @override
  String get dashboardPickerSubviews => 'Subviews';

  @override
  String get dashboardPickerSubview => 'Subview';

  @override
  String get dashboardPickerWhole => 'Whole dashboard';

  @override
  String get dashboardPickerBuildsOwn => 'Builds its own views';

  @override
  String get dashboardPickerIngressPage => 'Ingress page';

  @override
  String get dashboardPickerBuiltInPage => 'Home Assistant page';

  @override
  String get dashboardPickerWholeHelp =>
      'This dashboard builds its own views, so the kiosk opens it whole.';

  @override
  String dashboardPickerViewCount(String count) {
    return '$count views';
  }

  @override
  String get dashboardPickerOneView => '1 view';

  @override
  String get dashboardPickerOffline => 'Could not reach Home Assistant';

  @override
  String get dashboardPickerOfflineHelp =>
      'The dashboards load once the connection is back.';

  @override
  String get dashboardPickerTryAgain => 'Try again';

  @override
  String get dashboardPickerEmpty => 'No dashboards yet';

  @override
  String get dashboardPickerEmptyHelp =>
      'Dashboards you add in Home Assistant show up here.';

  @override
  String get dashboardPickerNoMatch => 'No views match';

  @override
  String dashboardPickerSelected(String count) {
    return '$count selected';
  }

  @override
  String get dashboardPickerDone => 'Done';

  @override
  String get dashboardPickerShowing => 'Showing';

  @override
  String get dashboardPickerMissing =>
      'This view is gone from Home Assistant. Choose another.';

  @override
  String get dashboardPickerAddViews => 'Add views';

  @override
  String get dashboardPickerDefault => 'Default dashboard';

  @override
  String get dashboardPickerDefaultHelp =>
      'The view the kiosk shows when it starts.';

  @override
  String get dashboardPickerOnePage => '1 page';

  @override
  String dashboardPickerPageCount(String count) {
    return '$count pages';
  }

  @override
  String get dlnaCannotDecode => 'This device cannot decode this video.';

  @override
  String get dlnaCannotRead => 'This file could not be read.';

  @override
  String get dlnaCannotPlay => 'This media could not be played.';

  @override
  String get dlnaSeeLogs => 'See the App Logs for details';

  @override
  String get dlnaLoading => 'Loading media';

  @override
  String get dlnaImageFailed => 'This image could not be displayed.';

  @override
  String get dlnaStop => 'Stop playback';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName: $actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => 'Plugin action';

  @override
  String get drawerPluginActionError => 'Could not run this action.';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerHaKiosk => 'HA Kiosk Mode';

  @override
  String get drawerCameraView => 'Camera View';

  @override
  String get drawerIntercom => 'Intercom';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => 'Hide Floating Player';

  @override
  String get drawerShowPlayer => 'Show Floating Player';

  @override
  String get drawerNowPlaying => 'Now Playing';

  @override
  String get drawerScreensaver => 'Start Screensaver';

  @override
  String get drawerLockdown => 'Lockdown Mode';

  @override
  String get drawerHoldOff => 'Turn Off Hold Mode';

  @override
  String get drawerHoldOn => 'Turn On Hold Mode';

  @override
  String get drawerApps => 'Apps';

  @override
  String get drawerClearCache => 'Clear web cache';

  @override
  String get drawerRestartDevice => 'Restart Device';

  @override
  String get drawerRestartConfirm =>
      'Restart this device? Kiosk Satellite comes back when it boots.';

  @override
  String get drawerRestart => 'Restart';

  @override
  String get drawerExitApplication => 'Exit Application';

  @override
  String get drawerExitConfirm => 'Close Kiosk Satellite?';

  @override
  String get drawerExit => 'Exit';

  @override
  String get drawerHoldActive => 'Hold mode is on';

  @override
  String get drawerHoldHelp =>
      'Screensaver and timers are paused · tap to turn off';

  @override
  String get drawerThemeDark => 'Dark';

  @override
  String get drawerThemeLight => 'Light';

  @override
  String get drawerThemeAndroid => 'Follow Android';

  @override
  String get drawerItemsSearch => 'Search menu items';

  @override
  String get drawerItemsSettingsKept =>
      'Always shown while remote admin is off.';

  @override
  String drawerVersion(String version) {
    return 'Version $version';
  }

  @override
  String get drawerUpdateAvailable => 'Update available';

  @override
  String drawerUpdateInstall(String version) {
    return 'Version $version · tap to install';
  }

  @override
  String get drawerUpdateChecking => 'Checking for updates…';

  @override
  String get drawerUpdateCurrent => 'Up to date';

  @override
  String get drawerUpdateCurrentHelp => 'You are on the latest version.';

  @override
  String get drawerUpdateCheckFailed => 'Update check failed';

  @override
  String get drawerUpdateOffline => 'Is the device online?';

  @override
  String drawerUpdateTo(String version) {
    return 'Update to $version';
  }

  @override
  String get drawerUpdateInstructions =>
      'The download starts on Update. Android asks you to confirm the installation.';

  @override
  String get drawerUpdateRelaunch =>
      'Without the \"Display over other apps\" permission the app cannot reopen itself after updating.';

  @override
  String get drawerUpdate => 'Update';

  @override
  String get drawerUpdateDownloading => 'Downloading update';

  @override
  String get drawerUpdateStarting => 'Starting…';

  @override
  String get drawerUpdateFailed => 'Update failed';

  @override
  String get drawerUpdates => 'Updates';

  @override
  String get drawerNoReleaseNotes => 'No release notes.';

  @override
  String get entityPickerNoArea => 'No area';

  @override
  String get entityPickerAll => 'All';

  @override
  String get entityPickerChoose => 'Choose an entity';

  @override
  String get entityPickerNoMatch => 'Nothing matches';

  @override
  String get entityPickerOfflineHelp =>
      'The entities load once the connection is back.';

  @override
  String get entityPickerMissing =>
      'This entity is gone from Home Assistant. Choose another.';

  @override
  String get entityPickerOrderHint =>
      'Drag or use the arrows to change the order.';

  @override
  String get entityPickerFull => 'Remove one to add another.';

  @override
  String get entityPickerAdd => 'Add entities';

  @override
  String entityPickerShowing(String count, String max) {
    return 'Showing $count of $max';
  }

  @override
  String get esphomeAllExposed => 'All available entities exposed';

  @override
  String esphomeExcludedCount(String count) {
    return '$count excluded';
  }

  @override
  String get esphomeEntitySearch => 'Search entities';

  @override
  String get esphomeEntityLoading => 'Loading entities…';

  @override
  String get esphomeEntityUnavailable => 'Currently unavailable';

  @override
  String get esphomeEntityNoMatch => 'No matching entities';

  @override
  String get esphomeEntityLoadFailed =>
      'Could not load entities. Close the picker and try again.';

  @override
  String get esphomeEntitySaveFailed => 'Could not save exclusions. Try again.';

  @override
  String get esphomeTypeConfig => 'Configuration';

  @override
  String get esphomeTypeDiagnostics => 'Diagnostics';

  @override
  String get esphomeTypeSensorGroup => 'Sensor';

  @override
  String get esphomeTypeControl => 'Control';

  @override
  String get esphomeTypeSensor => 'sensor';

  @override
  String get esphomeTypeTextSensor => 'text sensor';

  @override
  String get esphomeTypeBinarySensor => 'binary sensor';

  @override
  String get esphomeTypeCamera => 'camera';

  @override
  String get esphomeTypeSwitch => 'switch';

  @override
  String get esphomeTypeButton => 'button';

  @override
  String get esphomeTypeNumber => 'number';

  @override
  String get esphomeTypeSelect => 'select';

  @override
  String get esphomeTypeLight => 'light';

  @override
  String get esphomeTypeUpdate => 'update';

  @override
  String get esphomeTypeText => 'text';

  @override
  String get filesUpload => 'Upload file';

  @override
  String get filesUploading => 'Uploading…';

  @override
  String get filesUploadFailed => 'Upload failed';

  @override
  String get filesUploaded => 'Uploaded';

  @override
  String filesUploadingProgress(String current, String total) {
    return 'Uploading $current of $total…';
  }

  @override
  String filesUploadedCount(String count) {
    return '$count files uploaded';
  }

  @override
  String get filesPermissionMissing =>
      '\"All files access\" permission missing';

  @override
  String get filesPermissionHelp =>
      'Without it only the app folder can be browsed. The grant screen opens on the tablet.';

  @override
  String get filesGrant => 'Grant on device';

  @override
  String get filesUp => 'Up one folder';

  @override
  String get filesShared => 'Shared storage';

  @override
  String get filesApp => 'App folder';

  @override
  String get filesReadFailed => 'Could not read the folder';

  @override
  String get filesEmpty => 'Empty folder';

  @override
  String get filesEmptyHelp => 'Nothing here yet.';

  @override
  String get filesFolder => 'Folder';

  @override
  String get filesDownload => 'Download';

  @override
  String get filesDownloadFailed => 'Download failed';

  @override
  String filesDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get filesDeleteHelp => 'The file is removed from the device.';

  @override
  String get filesInvalidPath => 'Invalid path';

  @override
  String get filesNoFolder => 'No such folder';

  @override
  String get filesNoFile => 'No such file';

  @override
  String filesReadError(String error) {
    return 'Cannot read folder: $error';
  }

  @override
  String filesWriteError(String error) {
    return 'Write failed: $error';
  }

  @override
  String get filesDeleteFailed => 'Could not delete the file';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin =>
      'Fleet Management needs the remote admin';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Kiosks find each other through it. Turn on Remote management and Find other kiosks under Device, then come back.';

  @override
  String get fleetLeadThisFleet => 'Lead this fleet';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      'Sync this kiosk\'s settings to its followers. Requires all kiosks to run the same version.';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead =>
      'A kiosk that follows a leader cannot lead.';

  @override
  String get fleetFollowers => 'Followers';

  @override
  String get fleetProfiles => 'Profiles';

  @override
  String get fleetLeader => 'Leader';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      'Learn which settings sync and which do not in the ';

  @override
  String get fleetFleetManagementDocumentation =>
      'Fleet Management documentation';

  @override
  String get fleetMore => 'More';

  @override
  String get fleetSearchFollowers =>
      'The kiosks this one leads, their state and a way to add one.';

  @override
  String get fleetAddAKiosk => 'Add a kiosk';

  @override
  String get fleetAddAKioskFollowerAcceptsOnScreenOrRemoteAdmin =>
      'Add a discovered kiosk or enter its IP address. The follower accepts the invitation on its screen or in its remote admin.';

  @override
  String get fleetSendInvitation => 'Send invitation';

  @override
  String get fleetInviteAgain => 'Invite again';

  @override
  String fleetRemoveName(String name) {
    return 'Remove $name?';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      'It stops following this kiosk and keeps its settings.';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name wants to lead this kiosk';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      'Its settings replace this kiosk\'s in the categories it syncs, from now on. This kiosk keeps its name and identity.';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      'Its settings replace this kiosk\'s in the categories it syncs, from now on. This kiosk keeps its name, its Home Assistant, Music Assistant and ESPHome selves and its hardware picks. You can leave the fleet at any time under Settings, Fleet Management.';

  @override
  String get fleetAccept => 'Accept';

  @override
  String get fleetLookingForOtherKiosks => 'Looking for other kiosks…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      'No kiosks discovered. Use Add by IP to find one at a known address.';

  @override
  String fleetFollowsName(String name) {
    return 'Follows $name';
  }

  @override
  String get fleetLeadsAFleet => 'Leads a fleet';

  @override
  String get fleetNoFleetManagement => 'No Fleet Management';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      'Kiosks on this network that do not follow this one. Pick one to choose what it gets, then the invitation goes out. A kiosk on a build without Fleet Management joins once it runs one.';

  @override
  String get fleetJoinedTheFleet => 'Joined the fleet';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly =>
      'Settings from the leader arrive shortly.';

  @override
  String get fleetAddByIp => 'Add by IP';

  @override
  String get fleetFindKiosk => 'Find kiosk';

  @override
  String get fleetFindingKiosk => 'Finding kiosk…';

  @override
  String get fleetIpAddress => 'IP address';

  @override
  String get fleetRemoteAdminPort => 'Remote admin port';

  @override
  String get fleetAddressHelp =>
      'Enter the kiosk IP address and remote admin port.';

  @override
  String get fleetAddAProfile => 'Add a profile';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      'The collection of settings, credentials and exclusions to sync.';

  @override
  String get fleetNewProfile => 'New profile';

  @override
  String get fleetProfile => 'Profile';

  @override
  String get fleetUpdatesOnly => 'Updates only';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed =>
      'Nothing syncs. Only updates are pushed.';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return 'Categories: $selected of $total. Credentials: $credentials of $credentialTotal. Excluded: $excluded.';
  }

  @override
  String get fleetThisProfileIsGone => 'This profile is gone';

  @override
  String get fleetItWasDeletedFromAnotherPage =>
      'It was deleted from another page.';

  @override
  String get fleetName => 'Name';

  @override
  String get fleetRename => 'Rename';

  @override
  String get fleetRenameProfile => 'Rename profile';

  @override
  String get fleetWhatItSyncs => 'What it syncs';

  @override
  String get fleetNothing => 'Nothing';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      'Kiosks on this profile keep every setting of their own. The leader only pushes updates to them.';

  @override
  String get fleetCategories => 'Categories';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected of $total: $names';
  }

  @override
  String get fleetCredentials => 'Credentials';

  @override
  String get fleetNoneTravel => 'None travel';

  @override
  String get fleetIncludeTheDashboard => 'Include the dashboard';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard =>
      'The start page and the default dashboard.';

  @override
  String get fleetExcludedSettings => 'Excluded settings';

  @override
  String get fleetOneSettingLeftOut => 'One setting left out';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return '$count settings left out';
  }

  @override
  String get fleetNoKiosksAssigned => 'No kiosks assigned';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      'Assign this profile to a kiosk on the Fleet Management page.';

  @override
  String get fleetDuplicate => 'Duplicate';

  @override
  String get fleetCloneThisProfileIntoANewOne =>
      'Clone this profile into a new one.';

  @override
  String get fleetDuplicateProfile => 'Duplicate profile';

  @override
  String fleetNameCopy(String name) {
    return '$name copy';
  }

  @override
  String get fleetDeleteProfile => 'Delete profile';

  @override
  String get fleetNoKioskIsOnIt => 'No kiosk is on it.';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile =>
      'Kiosks on it get the Default profile.';

  @override
  String fleetDeleteName(String name) {
    return 'Delete $name?';
  }

  @override
  String get fleetBlackScreens => 'Black screens';

  @override
  String fleetSyncToName(String name) {
    return 'Sync to $name';
  }

  @override
  String get fleetDefault => 'Default';

  @override
  String get fleetNone => 'None';

  @override
  String get fleetSearchProfiles =>
      'The named lists a follower can be given: categories, credentials, the dashboard and the settings left out.';

  @override
  String get fleetSyncNow => 'Sync now';

  @override
  String get fleetChangedHereWaitingForTheLeader =>
      'Changed here, waiting for the leader';

  @override
  String fleetSyncedTime(String time) {
    return 'Synced $time';
  }

  @override
  String get fleetWaitingForTheFirstSync => 'Waiting for the first sync';

  @override
  String get fleetNothingYet => 'Nothing yet';

  @override
  String get fleetNoCredentials => 'No credentials';

  @override
  String fleetWithTheNames(String names) {
    return 'With the $names';
  }

  @override
  String get fleetTheDashboard => 'the dashboard';

  @override
  String get fleetNoDashboard => 'no dashboard';

  @override
  String get fleetTheDashboardDetail => 'The dashboard';

  @override
  String get fleetNoDashboardDetail => 'No dashboard';

  @override
  String get fleetSyncedFromTheLeader => 'Synced from the leader';

  @override
  String get fleetLeaveTheFleet => 'Leave the fleet';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre =>
      'Stops the sync. Settings stay as they are.';

  @override
  String get fleetLeaveTheFleetDetail => 'Leave the fleet?';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name stops pushing settings here. Everything stays as it is now.';
  }

  @override
  String get fleetLeave => 'Leave';

  @override
  String get fleetJustNow => 'just now';

  @override
  String fleetCountMinAgo(String count) {
    return '$count min ago';
  }

  @override
  String fleetCountHAgo(String count) {
    return '$count h ago';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return '$count days ago';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return '$name leads these settings. A change here is replaced at the next sync.';
  }

  @override
  String get fleetDeclinedOnTheKiosk => 'Declined on the kiosk';

  @override
  String get fleetWaitingForItsOk => 'Waiting for its OK';

  @override
  String get fleetLeftTheFleet => 'Left the fleet';

  @override
  String fleetSendingPercent(String percent) {
    return 'Sending $percent%';
  }

  @override
  String get fleetInstalling => 'Installing';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return 'Runs $version, this kiosk needs an update';
  }

  @override
  String fleetNeedsVersion(String version) {
    return 'Needs $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return 'Downloading $percent%';
  }

  @override
  String get fleetSyncing => 'Syncing…';

  @override
  String get fleetErrorUnreachable => 'Unreachable';

  @override
  String get fleetErrorBadAnswer => 'Bad answer';

  @override
  String get fleetErrorThePushFailed => 'The push failed';

  @override
  String get fleetErrorLeadThisFleetIsOff => 'Lead this fleet is off';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      'The remote admin and Find other kiosks must be on';

  @override
  String get fleetErrorPickAnotherKiosk => 'Pick another kiosk';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      'That kiosk is not on the network right now';

  @override
  String get fleetErrorThatKioskDidNotAnswer => 'That kiosk did not answer';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation =>
      'That kiosk refused the invitation';

  @override
  String get fleetErrorTheDefaultProfileStays => 'The Default profile stays';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays =>
      'The Updates only profile stays';

  @override
  String get fleetErrorNoSuchProfile => 'No such profile';

  @override
  String get fleetErrorNoSuchFollower => 'No such follower';

  @override
  String get fleetErrorNoInvitationIsWaiting => 'No invitation is waiting';

  @override
  String get fleetErrorMalformedInvitation => 'Malformed invitation';

  @override
  String get fleetErrorCouldNotMintAToken => 'Could not mint a token';

  @override
  String get fleetErrorNotAFollowerYet => 'not a follower yet';

  @override
  String get fleetErrorOffline => 'offline';

  @override
  String get fleetErrorUpToDate => 'up to date';

  @override
  String get fleetErrorAlreadyDownloading => 'already downloading';

  @override
  String get fleetErrorDidNotAnswer => 'did not answer';

  @override
  String get fleetErrorDidNotTakeTheUpload => 'did not take the upload';

  @override
  String fleetProfileNameExists(String name) {
    return 'A profile named $name exists';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return 'already on $version';
  }

  @override
  String get fleetUnsupportedBuild =>
      'That kiosk runs a build without Fleet Management. It joins once it runs one.';

  @override
  String get fleetErrorAddressMismatch =>
      'The address belongs to a different kiosk or fleet';

  @override
  String get fleetErrorInvalidIp => 'Enter a valid IP address.';

  @override
  String get fleetErrorInvalidPort => 'Enter a port from 1 to 65535.';

  @override
  String get fleetErrorIdentityNotReady =>
      'This kiosk identity is not ready yet. Try again.';

  @override
  String get fleetErrorInvalidIdentity =>
      'That address did not return a valid kiosk identity.';

  @override
  String get fleetErrorAlreadyMember =>
      'This kiosk already belongs to this fleet.';

  @override
  String get fleetErrorIsLeader => 'That kiosk leads a fleet.';

  @override
  String get fleetErrorOtherLeader =>
      'That kiosk already follows another leader.';

  @override
  String fleetPluginsNames(String names) {
    return 'Plugins: $names';
  }

  @override
  String fleetCouldNotInstallNameReason(String name, String reason) {
    return 'Could not install $name: $reason';
  }

  @override
  String fleetReinstallNameOnThisKioskToSyncIt(String name) {
    return 'Reinstall $name on this kiosk to sync it';
  }

  @override
  String get fleetSwitchKiosk => 'Switch kiosk';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      'Discovered kiosks and saved fleet members. Picking one opens its remote admin here, on this same page.';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      'No other kiosks found. Kiosks appear through network discovery or saved fleet membership.';

  @override
  String get fleetSyncedCredentials => 'Synced Credentials';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced =>
      'The settings on this list will not be synced to the followers.';

  @override
  String get fleetNothingLeftOut => 'Nothing left out';

  @override
  String get fleetSyncItAgain => 'Sync it again';

  @override
  String get fleetAddASetting => 'Add a setting';

  @override
  String get fleetExcludeASetting => 'Exclude a setting';

  @override
  String get fleetSearchSettings => 'Search settings';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return '$count more. Type to narrow the list.';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return 'Not synced: $note';
  }

  @override
  String get fleetTheAssignedSatellite => 'the assigned satellite';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain =>
      'microphone and speaker devices, mic gain';

  @override
  String get fleetTheDeviceCamera => 'the device camera';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      'the followed player, the Sendspin player id';

  @override
  String get fleetNodeNameMacEncryptionKey => 'node name, MAC, encryption key';

  @override
  String get fleetThePinIsAlsoSynced => 'the PIN is also synced';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential =>
      'the key, unless synced as a credential';

  @override
  String get fleetTheAlarmsThemselves => 'the alarms themselves';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'name, remote administration, renderer workarounds, scale';

  @override
  String get fleetHomeAssistantToken => 'Home Assistant token';

  @override
  String get fleetMusicAssistantToken => 'Music Assistant token';

  @override
  String get fleetImmichApiKey => 'Immich API key';

  @override
  String get fleetOpenAiApiKey => 'OpenAI API key';

  @override
  String get fleetXaiApiKey => 'xAI API key';

  @override
  String get fleetGeminiApiKey => 'Gemini API key';

  @override
  String get fleetMcpServerToken => 'MCP server token';

  @override
  String get fleetPlugins => 'Plugins';

  @override
  String get fleetPluginSecrets => 'Plugin secrets';

  @override
  String get fleetNoPluginsInstalledOnThisKiosk =>
      'No plugins installed on this kiosk';

  @override
  String get fleetKiosksOnThisProfileInstallTheseAndTakeTheir =>
      'Kiosks on this profile install these and take their settings from this kiosk.';

  @override
  String get fleetUpdateTheFleet => 'Update the fleet';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      'Update the whole fleet to the Kiosk Satellite version running on the leader.';

  @override
  String get fleetKeepFollowersOnThisVersion =>
      'Keep followers on this version';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      'Automatically update all followers to the Kiosk Satellite version running on the leader.';

  @override
  String get fleetNothingToUpdate => 'Nothing to update';

  @override
  String get fleetUpdating => 'Updating';

  @override
  String fleetNamesInstalling(String names) {
    return '$names installing.';
  }

  @override
  String get fleetSearchUpdates =>
      'Install the release offered to each follower, then here.';

  @override
  String get gestureAction => 'Action';

  @override
  String get gestureNavigate => 'Go to a dashboard view';

  @override
  String get gestureUrl => 'Open a web page';

  @override
  String get gestureCameraView => 'Show a camera view';

  @override
  String get gestureLauncher => 'Open the app launcher';

  @override
  String get gestureIntercomOpen => 'Open Call a kiosk';

  @override
  String get gestureIntercomCall => 'Call a kiosk';

  @override
  String get gestureIntercomHangup => 'End the intercom call';

  @override
  String get gestureIntercomAnswer => 'Accept intercom call';

  @override
  String get gestureIntercomDecline => 'Decline intercom call';

  @override
  String get gestureAlarmStop => 'Stop the alarm';

  @override
  String get gestureAlarmSnooze => 'Snooze the alarm';

  @override
  String get gestureScreensaver => 'Start the screensaver';

  @override
  String get gestureScreensaverStop => 'Stop the screensaver';

  @override
  String get gestureHoldMode => 'Toggle hold mode';

  @override
  String get gestureRefresh => 'Refresh the dashboard';

  @override
  String get gestureMediaPlayPause => 'Play or pause media';

  @override
  String get gestureHaKiosk => 'Toggle HA kiosk mode';

  @override
  String get gesturePluginRun => 'Run a plugin action';

  @override
  String get gestureLaunchApp => 'Open another app';

  @override
  String get gestureDeepLink => 'Open a deep link';

  @override
  String get gestureAndroidSettings => 'Open Android Settings';

  @override
  String get gestureOpenCalendar => 'Open the calendar';

  @override
  String get gestureOpenMusicLibrary => 'Open Music Library';

  @override
  String get gestureService => 'Call a service';

  @override
  String get gestureScript => 'Run a script';

  @override
  String get gestureAutomation => 'Trigger an automation';

  @override
  String get gestureEvent => 'Fire an event';

  @override
  String get gesturePluginAction => 'Plugin action';

  @override
  String get gesturePluginActions => 'Plugin actions';

  @override
  String get gesturePluginHelp =>
      'Enable a plugin with actions in Plugin Manager first.';

  @override
  String get gesturePluginFailed => 'Could not load plugin actions.';

  @override
  String get gestureUrlError => 'Enter a full http(s) URL.';

  @override
  String get gesturePackage => 'Package name';

  @override
  String get gesturePackageError => 'Enter a package name.';

  @override
  String get gestureUriError => 'Enter a full URI.';

  @override
  String get gestureCameraTitle => 'Camera view';

  @override
  String gestureCameraShow(String name) {
    return 'Show $name';
  }

  @override
  String get gestureCameraClose => 'Close the camera view';

  @override
  String get gestureCameraEmpty => 'No camera views configured yet.';

  @override
  String get gestureIntercomEmpty => 'No kiosk found on the network yet.';

  @override
  String get gestureVoiceWake => 'Start a voice command';

  @override
  String get gestureVoiceStop => 'Stop the voice assistant';

  @override
  String get gestureVoiceMute => 'Mute or unmute Voice Satellite';

  @override
  String get gestureOpenAlarmList => 'Open the alarm list';

  @override
  String get gestureOpenTimers => 'Open the timers';

  @override
  String get gestureOpenNextAlarm => 'Open the next alarm';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '$count taps in the $corner corner';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return 'Hold the $corner corner for ${seconds}s';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return '$count-finger double tap';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return '$count-finger tap';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return '$count-finger hold for ${seconds}s';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return 'Corner sequence: $sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '$count claps';
  }

  @override
  String get gestureDescribeOpenHand => 'Show an open hand';

  @override
  String gestureDescribeOneFinger(String count) {
    return 'Show $count finger';
  }

  @override
  String gestureDescribeFingers(String count) {
    return 'Show $count fingers';
  }

  @override
  String get gestureTopLeft => 'top-left';

  @override
  String get gestureTopRight => 'top-right';

  @override
  String get gestureBottomLeft => 'bottom-left';

  @override
  String get gestureBottomRight => 'bottom-right';

  @override
  String gestureGoTo(String value) {
    return 'Go to $value';
  }

  @override
  String gestureOpen(String value) {
    return 'Open $value';
  }

  @override
  String get gestureCameraToggle => 'Toggle the camera view';

  @override
  String gestureCameraToggleName(String name) {
    return 'Toggle camera view $name';
  }

  @override
  String gestureCall(String value) {
    return 'Call $value';
  }

  @override
  String gestureOpenApp(String package) {
    return 'Open app $package';
  }

  @override
  String gestureRun(String value) {
    return 'Run $value';
  }

  @override
  String gestureTriggerAction(String value) {
    return 'Trigger $value';
  }

  @override
  String gestureFireEvent(String value) {
    return 'Fire event $value';
  }

  @override
  String gestureDescribeButtonPress(String button) {
    return 'Press the $button button';
  }

  @override
  String gestureDescribeButtonDouble(String button) {
    return 'Double-press the $button button';
  }

  @override
  String gestureDescribeButtonHold(String button) {
    return 'Hold the $button button';
  }

  @override
  String get gestureValid => 'Looks good.';

  @override
  String get gestureValidationFailed => 'Could not validate.';

  @override
  String gestureDomainMissing(String value) {
    return 'Domain $value not found.';
  }

  @override
  String gestureServiceMissing(String value) {
    return 'Service $value not found.';
  }

  @override
  String gestureEntityMissing(String value) {
    return 'Entity $value not found.';
  }

  @override
  String gestureEntityRequired(String domain) {
    return 'Enter a $domain.* entity.';
  }

  @override
  String get gestureScriptEntity => 'Script entity';

  @override
  String get gestureAutomationEntity => 'Automation entity';

  @override
  String get gestureEntityOptional => 'Entity (optional)';

  @override
  String get gestureServiceData => 'Service data (optional)';

  @override
  String get gestureServiceTitle => 'Call a Home Assistant service';

  @override
  String get gestureServiceJson => 'Service data must be a JSON object.';

  @override
  String get gestureEventType => 'Event type';

  @override
  String get gestureEventData => 'Event data (optional)';

  @override
  String get gestureEventTitle => 'Fire a Home Assistant event';

  @override
  String get gestureEventRequired => 'Event type is required.';

  @override
  String get gestureEventJson => 'Event data must be a JSON object.';

  @override
  String get gestureServiceSearch => 'Search services';

  @override
  String get gestureServiceChoose => 'Choose a service';

  @override
  String get gestureServiceNoEntity => 'Not used by this service';

  @override
  String get gestureTester => 'Hand Gesture Tester';

  @override
  String get gestureOpenTester => 'Open tester';

  @override
  String get gestureCameraFirst =>
      'Turn on the camera in Camera settings first.';

  @override
  String get gestureTesterHelp =>
      'Watch which fingers the camera reads, to learn how to hold your hand.';

  @override
  String get gestureHandHelp =>
      'Hold your hand up at shoulder height, palm to the camera, fingers spread. Curl a finger all the way down to drop it from the count. Tuck the thumb across the palm to show four: the thumb only counts on an open hand.';

  @override
  String get gestureTesterPaused =>
      'Gestures do not fire while the tester is open.';

  @override
  String get gestureShowHand => 'Show a hand to the camera.';

  @override
  String gestureTesterTrigger(String action) {
    return 'Triggers: $action';
  }

  @override
  String get gestureNoCount => 'No gesture uses this count.';

  @override
  String get gestureNoHand => 'No hand in view';

  @override
  String get gestureReadingHand => 'Reading the hand';

  @override
  String get gestureNoFingers => 'No fingers up';

  @override
  String gestureHandsCount(String count) {
    return '$count hands in view, reading the larger one.';
  }

  @override
  String get gestureTesterSearch =>
      'A live look at the fingers the camera reads.';

  @override
  String get gestureHoldConfirmed => 'Hold confirmed';

  @override
  String gestureHoldProgress(String progress) {
    return 'Hold progress: $progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return 'Hold duration: $duration';
  }

  @override
  String get gestureHaServiceKind => 'Home Assistant Service';

  @override
  String get gestureHaScriptKind => 'Home Assistant Script';

  @override
  String get gestureHaAutomationKind => 'Home Assistant Automation';

  @override
  String get gestureHaEventKind => 'Home Assistant Event';

  @override
  String gestureRan(String value) {
    return 'Ran $value';
  }

  @override
  String gestureRunFailed(String value) {
    return 'Could not run $value';
  }

  @override
  String gestureCalled(String value) {
    return 'Called $value';
  }

  @override
  String gestureCallFailed(String value) {
    return 'Could not call $value';
  }

  @override
  String gestureTriggered(String value) {
    return 'Triggered $value';
  }

  @override
  String gestureTriggerFailed(String value) {
    return 'Could not trigger $value';
  }

  @override
  String gestureFired(String value) {
    return 'Fired event $value';
  }

  @override
  String gestureFireFailed(String value) {
    return 'Could not fire event $value';
  }

  @override
  String get gestureDone => 'Done';

  @override
  String get gestureFailed => 'Failed';

  @override
  String get gestureEdit => 'Edit gesture';

  @override
  String get gestureTrigger => 'Gesture';

  @override
  String get gestureCornerTaps => 'Taps in a corner';

  @override
  String get gestureCornerHold => 'Hold a corner';

  @override
  String get gestureFingerTaps => 'Multi-finger tap';

  @override
  String get gestureFingerHold => 'Multi-finger hold';

  @override
  String get gestureSequence => 'Corner sequence';

  @override
  String get gestureClaps => 'Claps';

  @override
  String get gestureShowFingers => 'Show fingers';

  @override
  String get gestureCorner => 'Corner';

  @override
  String get gestureCornerTl => 'Top-left corner';

  @override
  String get gestureCornerTr => 'Top-right corner';

  @override
  String get gestureCornerBl => 'Bottom-left corner';

  @override
  String get gestureCornerBr => 'Bottom-right corner';

  @override
  String get gestureTaps => 'Taps';

  @override
  String get gestureTaps2 => '2 taps';

  @override
  String get gestureTaps3 => '3 taps';

  @override
  String get gestureTaps4 => '4 taps';

  @override
  String get gestureFingers => 'Fingers';

  @override
  String get gestureFinger1 => '1 finger';

  @override
  String get gestureFinger2 => '2 fingers';

  @override
  String get gestureFinger3 => '3 fingers';

  @override
  String get gestureFinger4 => '4 fingers';

  @override
  String get gestureOpenHand5 => 'Open hand (5)';

  @override
  String get gestureSingleTap => 'Single tap';

  @override
  String get gestureDoubleTap => 'Double tap';

  @override
  String gestureHoldDuration(String seconds) {
    return 'Hold for $seconds s';
  }

  @override
  String get gestureCameraHelp =>
      'Requires the camera enabled and a well lit environment.';

  @override
  String get gestureUnavailable => 'Not available on this device.';

  @override
  String get gestureClaps2 => '2 claps';

  @override
  String get gestureClaps3 => '3 claps';

  @override
  String get gestureClaps4 => '4 claps';

  @override
  String get gestureClapHelp =>
      'Claps are heard through the microphone, with or without wake word detection.';

  @override
  String get gestureSequenceHelp => 'Tap the corners in order (2 to 8 steps).';

  @override
  String get gestureRemoveStep => 'Remove last step';

  @override
  String get gestureUndo => 'Undo';

  @override
  String get gestureChooseAction => 'Choose an action';

  @override
  String get gestureActionHelp => 'What this gesture triggers.';

  @override
  String get gestureChangeHelp => 'Tap to change.';

  @override
  String get gestureChooseError => 'Choose an action.';

  @override
  String get gestureSequenceError => 'Add at least two corners.';

  @override
  String get gesturePluginTrigger => 'Plugin trigger';

  @override
  String get gesturePluginTriggerField => 'Trigger';

  @override
  String get gesturePluginTriggerHelp =>
      'Enable a plugin with triggers in Plugin Manager first.';

  @override
  String get gestureButton => 'Button';

  @override
  String get gesturePress => 'Press';

  @override
  String get gestureDoublePress => 'Double press';

  @override
  String get gestureHoldPress => 'Hold';

  @override
  String get gestureButtonDefaults =>
      'A button press no gesture claims keeps its own job: Action answers, stops or dismisses what is ringing and otherwise starts a voice command, Microphone mutes Voice Satellite and the volume buttons change the volume.';

  @override
  String get intercomCall => 'Call';

  @override
  String get intercomNoReady => 'No kiosk is ready.';

  @override
  String get intercomOneReady => '1 kiosk is ready.';

  @override
  String intercomManyReady(String count) {
    return '$count kiosks are ready.';
  }

  @override
  String get intercomCallKiosk => 'Call a kiosk';

  @override
  String get intercomAnnounceAll => 'Announce to all';

  @override
  String get intercomAnnounceHelp => 'Talk to every kiosk. One way only.';

  @override
  String intercomMissedFrom(String name) {
    return 'Missed call from $name';
  }

  @override
  String intercomRangFor(String seconds) {
    return 'Rang for $seconds seconds.';
  }

  @override
  String get intercomCallBack => 'Call back';

  @override
  String get intercomDeclined => 'Declined';

  @override
  String get intercomBusy => 'Busy';

  @override
  String get intercomPeerOff => 'Its intercom is off';

  @override
  String get intercomPeerKey => 'Different intercom key';

  @override
  String get intercomNoAnswer => 'No answer';

  @override
  String get intercomDidNotAnswer => 'Did not answer';

  @override
  String get intercomVoiceFailed => 'The voice link failed';

  @override
  String get intercomCancelled => 'Cancelled';

  @override
  String get intercomPageMic => 'The page took the microphone';

  @override
  String get intercomNobody => 'Nobody could take it';

  @override
  String get intercomDone => 'Done';

  @override
  String get intercomEnded => 'Call ended';

  @override
  String get intercomMaxDurationReached => 'Maximum call duration reached';

  @override
  String get intercomAnnouncement => 'Announcement';

  @override
  String get intercomAnnouncingOne => 'Announcing to 1 kiosk';

  @override
  String intercomAnnouncingMany(String count) {
    return 'Announcing to $count kiosks';
  }

  @override
  String get intercomIsCalling => 'is calling';

  @override
  String get intercomIsAnnouncing => 'is announcing';

  @override
  String get intercomCalling => 'Calling…';

  @override
  String intercomAnswersWithCameraIn(String seconds) {
    return 'Camera on in $seconds s';
  }

  @override
  String intercomAnswersIn(String seconds) {
    return 'Answers in $seconds s';
  }

  @override
  String get intercomRinging => 'Ringing';

  @override
  String get intercomConnecting => 'Connecting…';

  @override
  String intercomDoneDuration(String duration) {
    return 'Done, $duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return 'Call ended, $duration';
  }

  @override
  String get intercomDecline => 'Decline';

  @override
  String get intercomAnswer => 'Answer';

  @override
  String get intercomEveryKiosk => 'Every kiosk';

  @override
  String get intercomStop => 'Stop';

  @override
  String intercomHearsYou(String name) {
    return '$name hears you';
  }

  @override
  String get intercomAllHearYou => 'Every kiosk hears you';

  @override
  String get intercomHoldHelp => 'Hold to talk, let go to listen';

  @override
  String get intercomMuted => 'Muted';

  @override
  String get intercomMute => 'Mute';

  @override
  String get intercomEnd => 'End';

  @override
  String get intercomReply => 'Reply';

  @override
  String get intercomDismiss => 'Dismiss';

  @override
  String get intercomCallAgain => 'Call again';

  @override
  String get intercomDashboardMic =>
      'The dashboard holds the microphone, listening only.';

  @override
  String get intercomMicDenied => 'Microphone not granted, listening only.';

  @override
  String get intercomHoldTalk => 'Hold to talk';

  @override
  String get intercomPlaying => 'Playing';

  @override
  String get intercomAKiosk => 'a kiosk';

  @override
  String intercomCallingName(String name) {
    return 'Calling $name';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name is calling';
  }

  @override
  String intercomInCallName(String name) {
    return 'In a call with $name';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name is announcing';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant: $message';
  }

  @override
  String get intercomEndCall => 'End call';

  @override
  String get intercomVoiceCall => 'Voice call';

  @override
  String get intercomVideoCall => 'Video call';

  @override
  String get intercomVoiceOnly => 'Voice only';

  @override
  String get intercomVideoAnswer => 'Video';

  @override
  String get intercomSwitchCamera => 'Switch camera';

  @override
  String get intercomCameraButton => 'Camera';

  @override
  String get intercomCameraOff => 'Camera off';

  @override
  String get intercomYourCameraOff => 'Your camera is off';

  @override
  String get intercomVideoReconnecting => 'Video reconnecting…';

  @override
  String get intercomCameraOffNotice =>
      'The camera is off. This kiosk can show video but not send it.';

  @override
  String get intercomCallFailed => 'Could not call';

  @override
  String get intercomKeyFailed => 'Could not change the key';

  @override
  String get intercomBroadcastFailed => 'Could not talk to everyone';

  @override
  String get intercomDeviceNoAnswer => 'The device did not answer.';

  @override
  String get intercomUnknownKiosk => 'unknown kiosk';

  @override
  String get intercomNothingRinging => 'nothing is ringing';

  @override
  String get intercomNoCall => 'no call';

  @override
  String get intercomDisabled => 'intercom is off';

  @override
  String get intercomNeedsRemote => 'needs the remote admin';

  @override
  String get intercomNeedsDiscovery =>
      'the intercom needs the remote admin and Find other kiosks';

  @override
  String get intercomAlreadyCalling => 'already in a call';

  @override
  String get intercomNoReadyError => 'no kiosk is ready';

  @override
  String get intercomKeyLength => 'a key is at least 16 characters';

  @override
  String get intercomMicHeld => 'the page holds the microphone';

  @override
  String get intercomMicPermission => 'microphone not granted';

  @override
  String get intercomCallerNoAnswer => 'the caller did not answer';

  @override
  String get intercomMissedcall => 'Missed call';

  @override
  String get intercomListening => 'Listening';

  @override
  String get intercomAnnouncementsoff => 'Announcements off';

  @override
  String get intercomEncryptionMismatch => 'Encryption mismatch';

  @override
  String get intercomEncryptionMismatchHelp =>
      'Encryption mismatch. Enable Encrypt communications on all kiosks in the call.';

  @override
  String get kioskBackClose => 'Press back again to close the app';

  @override
  String get kioskBackAgain => 'Press back again to go back';

  @override
  String get kioskHoldOn => 'Hold mode on';

  @override
  String get kioskHoldOff => 'Hold mode off';

  @override
  String get kioskHoldNotice => 'The current view stays until you turn it off.';

  @override
  String get kioskDownloadComplete => 'Download complete';

  @override
  String get kioskDownloadFailed => 'Download failed';

  @override
  String get kioskDownload => 'Download';

  @override
  String get kioskDownloading => 'Downloading';

  @override
  String get kioskOpen => 'Open';

  @override
  String get kioskTip => 'Tip';

  @override
  String get kioskMenuHint => 'Swipe from the left edge to open the menu.';

  @override
  String get kioskUnknownLink => 'Unknown kiosk link';

  @override
  String get kioskOpenAppFailed => 'Could not open the app';

  @override
  String get kioskWebViewMissing => 'Android System WebView is not installed';

  @override
  String get kioskWebViewMissingHelp =>
      'This device has no WebView provider, so Home Assistant cannot be shown. Install Android System WebView or Chrome, then restart Kiosk Satellite.';

  @override
  String get kioskDuraSpeedBlocking => 'DuraSpeed is blocking the dashboard';

  @override
  String get kioskDuraSpeedBlockingHelp =>
      'This tablet\'s DuraSpeed keeps the dashboard\'s renderer from starting, and some tablets give it no settings page. Turn it off once over adb, then restart Kiosk Satellite:';

  @override
  String get kioskPinTitle => 'Kiosk PIN';

  @override
  String get kioskPinHint => 'PIN';

  @override
  String get kioskWrongPin => 'Wrong PIN';

  @override
  String get kioskUnlock => 'Unlock';

  @override
  String get lockdownScreenLocked => 'Screen is locked';

  @override
  String get logsWebConsole => 'Web Console';

  @override
  String get logsDock => 'Dock over the live page';

  @override
  String get logsNoOutput => 'No console output yet';

  @override
  String get logsShareSubject => 'Kiosk Satellite console log';

  @override
  String get logsInput => 'Run JavaScript in the page';

  @override
  String get logsInputHistory =>
      'Run JavaScript in the page (Enter to run, Up/Down for history)';

  @override
  String get logsRun => 'Run';

  @override
  String get logsEvaluationFailed => 'evaluation failed';

  @override
  String get logsDeviceUnreachable => 'device unreachable';

  @override
  String logsEntries(String count) {
    return '$count entries';
  }

  @override
  String get logsCopyLog => 'Copy log';

  @override
  String get logsShareLog => 'Share log';

  @override
  String get logsCopied => 'Copied';

  @override
  String get logsCopyFailed => 'Could not copy';

  @override
  String get logsOnClipboard => 'The log is on the clipboard.';

  @override
  String get logsConsoleOnClipboard => 'The console log is on the clipboard.';

  @override
  String get logsSystemLog =>
      'Android system log for this app (crashes live here)';

  @override
  String get logsErrors => 'Errors & crashes';

  @override
  String get logsWarnings => 'Warnings';

  @override
  String get logsInfo => 'Info & debug';

  @override
  String get logsNoMatches =>
      'No matching lines. Enable more types above to see the full log.';

  @override
  String get logsUnavailable => 'logcat unavailable';

  @override
  String logsReadFailed(String error) {
    return 'Could not read logcat: $error';
  }

  @override
  String get logsUnknown => 'unknown';

  @override
  String get libraryTitle => 'Music Library';

  @override
  String get librarySource => 'Source';

  @override
  String get librarySourceMa => 'Music Assistant';

  @override
  String get librarySourceHa => 'Home Assistant';

  @override
  String get librarySourceSonos => 'Sonos';

  @override
  String get librarySourceMaHint => 'Library, search and radio';

  @override
  String get librarySourceHaHint => 'Media from each speaker';

  @override
  String get librarySourceSonosHint => 'Favorites and playlists';

  @override
  String get libraryDiscover => 'Discover';

  @override
  String get librarySearch => 'Search';

  @override
  String get libraryBrowse => 'Browse';

  @override
  String get libraryLibrary => 'Library';

  @override
  String get libraryArtists => 'Artists';

  @override
  String get libraryAlbums => 'Albums';

  @override
  String get libraryTracks => 'Tracks';

  @override
  String get libraryGenres => 'Genres';

  @override
  String get libraryPlaylists => 'Playlists';

  @override
  String get libraryRadio => 'Radio';

  @override
  String get libraryPodcasts => 'Podcasts';

  @override
  String get libraryAudiobooks => 'Audiobooks';

  @override
  String get libraryFavorites => 'Favorites';

  @override
  String get librarySonosPlaylists => 'Sonos playlists';

  @override
  String get libraryRecentlyPlayed => 'Recently played';

  @override
  String get libraryRecentlyAdded => 'Recently added';

  @override
  String get librarySort => 'Sort';

  @override
  String get librarySortAToZ => 'A to Z';

  @override
  String get librarySortZToA => 'Z to A';

  @override
  String get librarySortMostPlayed => 'Most played';

  @override
  String get libraryAlbumArtistsOnly => 'Album artists only';

  @override
  String get libraryKindGenre => 'Genre';

  @override
  String get libraryBrowseByGenre => 'Browse by genre';

  @override
  String get settingLibraryTextScaleDescription =>
      'Size of the titles, names and labels in the library.';

  @override
  String get settingLibrarySquareArtworkTitle => 'Square artwork';

  @override
  String get settingLibrarySquareArtworkDescription =>
      'Show artists in square tiles, like albums and playlists.';

  @override
  String get settingLibraryGridDensityTitle => 'Grid density';

  @override
  String get settingLibraryGridDensityDescription =>
      'Size of the tiles in the library. Compact fits more in a row.';

  @override
  String get settingLibrarySourcePickerTitle => 'Show source selection';

  @override
  String get settingLibrarySourcePickerDescription =>
      'Show the source picker in the library. Turn off to keep the library on the source set above.';

  @override
  String get settingLibrarySpeakerPillDescription =>
      'Show the speaker picker at the top of the library.';

  @override
  String get libraryDensityComfortable => 'Comfortable';

  @override
  String get libraryDensityStandard => 'Standard';

  @override
  String get libraryDensityCompact => 'Compact';

  @override
  String get libraryMoreResults => 'More results';

  @override
  String get libraryTopTracks => 'Top tracks';

  @override
  String get libraryKindArtist => 'Artist';

  @override
  String get libraryKindAlbum => 'Album';

  @override
  String get libraryKindTrack => 'Track';

  @override
  String get libraryKindPlaylist => 'Playlist';

  @override
  String get libraryKindRadio => 'Radio';

  @override
  String get libraryKindPodcast => 'Podcast';

  @override
  String get libraryKindEpisode => 'Episode';

  @override
  String get libraryKindAudiobook => 'Audiobook';

  @override
  String get libraryOneTrack => '1 track';

  @override
  String libraryTrackCount(String count) {
    return '$count tracks';
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
  String get librarySearchHint => 'Artists, albums, tracks';

  @override
  String get librarySearchClear => 'Clear search';

  @override
  String get librarySearchAll => 'All';

  @override
  String get librarySearchPrompt =>
      'Search for artists, albums, tracks and more.';

  @override
  String get libraryEmpty => 'Nothing here yet.';

  @override
  String get libraryLoadFailed => 'This could not be loaded.';

  @override
  String get libraryNoSource =>
      'Set up Music Assistant, Home Assistant or a Sonos speaker to browse music.';

  @override
  String get libraryHaPickSpeaker =>
      'Choose a speaker to see the media it can play.';

  @override
  String get libraryChooseSpeaker => 'Choose a speaker';

  @override
  String get libraryPickSpeakerHint => 'Choose the speaker to play on.';

  @override
  String get libraryPlay => 'Play';

  @override
  String get libraryOpenNowPlaying => 'Open Now Playing';

  @override
  String get libraryNothingPlaying => 'Nothing playing';

  @override
  String get libraryMore => 'More options';

  @override
  String get libraryPlayNow => 'Play now';

  @override
  String get libraryPlayNext => 'Play next';

  @override
  String get libraryAddToQueue => 'Add to queue';

  @override
  String get libraryStartRadio => 'Start radio';

  @override
  String get libraryGoToArtist => 'Go to artist';

  @override
  String get libraryAddFavorite => 'Add to favorites';

  @override
  String get libraryRemoveFavorite => 'Remove from favorites';

  @override
  String get libraryAddedFavorite => 'Added to favorites';

  @override
  String get libraryRemovedFavorite => 'Removed from favorites';

  @override
  String get libraryFavoriteFailed => 'Favorites could not be changed';

  @override
  String get libraryPlaysNext => 'Plays next';

  @override
  String get libraryAddedToQueue => 'Added to queue';

  @override
  String get libraryView => 'View';

  @override
  String get libraryPlayFailed => 'This could not be played';

  @override
  String get librarySpeakers => 'Speakers';

  @override
  String get libraryPlayingOn => 'Playing on';

  @override
  String get libraryOtherSpeakers => 'Other speakers';

  @override
  String get libraryNoOtherSpeakers => 'No other speakers.';

  @override
  String get libraryThisDevice => 'This device';

  @override
  String get libraryUnavailable => 'Unavailable';

  @override
  String get libraryGroup => 'Group';

  @override
  String get libraryGroupAll => 'Group';

  @override
  String libraryGroupWith(String speaker) {
    return 'Group with $speaker';
  }

  @override
  String get libraryGroupHint =>
      'Grouped speakers play the same music in sync.';

  @override
  String libraryGroupName(String speaker, String count) {
    return '$speaker + $count';
  }

  @override
  String get settingKioskAllowMusicLibraryDescription =>
      'Browse music and play it on a speaker.';

  @override
  String get libraryPageHint => 'Browse music and play it on a speaker';

  @override
  String get settingLibrarySourceDescription =>
      'Where the library lists music from. Automatic starts with the source of the speaker Now Playing follows.';

  @override
  String get settingLibraryNowPlayingButtonTitle => 'Show on Now Playing';

  @override
  String get settingLibraryNowPlayingButtonDescription =>
      'Add a Music Library button next to the close button.';

  @override
  String get libraryQueueTitle => 'Queue';

  @override
  String get libraryCloseQueue => 'Close queue';

  @override
  String get libraryClear => 'Clear';

  @override
  String get libraryClearQueueTitle => 'Clear the queue?';

  @override
  String get libraryClearQueueMessage =>
      'The music stops and every track leaves the queue.';

  @override
  String get libraryRemoveFromQueue => 'Remove from queue';

  @override
  String get libraryReorder => 'Drag to reorder';

  @override
  String get libraryQueueFailed => 'The queue could not be changed';

  @override
  String get libraryVoiceSection => 'Voice Control';

  @override
  String get libraryVoiceManage => 'Manage music using Voice Satellite';

  @override
  String get libraryVoiceHint =>
      'Needs the Kiosk Satellite music blueprint and an LLM conversation agent in Home Assistant.';

  @override
  String get musicPickerTitle => 'Choose music';

  @override
  String get musicPickerSearchHint => 'Search music';

  @override
  String get musicPickerMusicFrom => 'Music from';

  @override
  String get musicPickerPlaysOn => 'Plays on';

  @override
  String musicPickerSourceLabel(String name) {
    return 'Source: $name';
  }

  @override
  String musicPickerSpeakerLabel(String name) {
    return 'Plays on: $name';
  }

  @override
  String get musicPickerRandom => 'Random';

  @override
  String get musicPickerRandomHint => 'A new pick every time it plays';

  @override
  String get musicPickerAnyTrack => 'Any track';

  @override
  String get musicPickerAnyFavorite => 'Any favorite';

  @override
  String get musicPickerAnyPlaylist => 'Any playlist';

  @override
  String get musicPickerAnyAlbum => 'Any album';

  @override
  String get musicPickerAnyStation => 'Any radio station';

  @override
  String get musicPickerRandomEach => 'A different one each time';

  @override
  String get musicPickerWholeAlbum => 'Whole album';

  @override
  String get musicPickerWholePlaylist => 'Whole playlist';

  @override
  String musicPickerWholeArtist(String name) {
    return 'Everything by $name';
  }

  @override
  String get musicPickerWholeFolder => 'Whole folder';

  @override
  String get musicPickerAllTracks => 'All tracks';

  @override
  String get musicPickerShuffle => 'Shuffle';

  @override
  String get musicPickerPreview => 'Preview';

  @override
  String get musicPickerStopPreview => 'Stop preview';

  @override
  String get musicPickerPreviewFailed => 'The music could not play';

  @override
  String get musicPickerNothing => 'Nothing picked';

  @override
  String get musicPickerNothingHint =>
      'Pick a track, album, playlist, artist or station';

  @override
  String get musicPickerFollowsNote =>
      'Now Playing switches to this speaker while the music plays.';

  @override
  String get musicPickerSonosNote =>
      'Sonos music plays on Sonos speakers only.';

  @override
  String get musicPickerNoSpeakers => 'No speakers to play on';

  @override
  String musicPickerOpen(String title) {
    return 'Open $title';
  }

  @override
  String get musicPickerKindFolder => 'Folder';

  @override
  String get offlineDashboard => 'Dashboard unavailable';

  @override
  String get offlineNetwork => 'No network connection';

  @override
  String get offlinePageHelp => 'The page could not be loaded.';

  @override
  String get offlineNetworkHelp =>
      'The dashboard will come back when the network does.';

  @override
  String get offlineLost => 'Network connection lost';

  @override
  String get offlineRestored => 'Network connection restored';

  @override
  String get mediaPlay => 'Play';

  @override
  String get mediaPause => 'Pause';

  @override
  String get mediaPreviousTrack => 'Previous track';

  @override
  String get mediaNextTrack => 'Next track';

  @override
  String get mediaPlaying => 'Playing';

  @override
  String get mediaPaused => 'Paused';

  @override
  String get mediaIdle => 'Idle';

  @override
  String get mediaStatusUnavailable => 'Status unavailable';

  @override
  String get mediaUnknownTrack => 'Unknown track';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => 'Show volume';

  @override
  String get mediaHideVolume => 'Hide volume';

  @override
  String get mediaMute => 'Mute';

  @override
  String get mediaUnmute => 'Unmute';

  @override
  String get mediaFavoriteAdd => 'Add to favorites';

  @override
  String get mediaFavoriteRemove => 'Remove from favorites';

  @override
  String get mediaShuffleOn => 'Turn shuffle on';

  @override
  String get mediaShuffleOff => 'Turn shuffle off';

  @override
  String get mediaRepeatAll => 'Repeat all';

  @override
  String get mediaRepeatOne => 'Repeat one';

  @override
  String get mediaRepeatOff => 'Turn repeat off';

  @override
  String get mediaShowLyrics => 'Show lyrics';

  @override
  String get mediaHideLyrics => 'Hide lyrics';

  @override
  String get mediaShowQueue => 'Show queue';

  @override
  String get mediaHideQueue => 'Hide queue';

  @override
  String get mediaVolume => 'Volume';

  @override
  String get mediaPlaybackPosition => 'Playback position';

  @override
  String get mediaShowNowPlaying => 'Show Now Playing';

  @override
  String get mediaShowFloatingPlayer => 'Show the floating player';

  @override
  String get mediaOpenMusicAssistant => 'Open Music Assistant';

  @override
  String get mediaCannotControl => 'command not supported or not sent';

  @override
  String get mediaAudioHiRes => 'Hi-Res';

  @override
  String get mediaAudioCdQuality => 'CD quality';

  @override
  String get mediaAudioLossy => 'Lossy';

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
  String get mediaNothingQueued => 'Nothing queued';

  @override
  String get mediaChapters => 'Chapters';

  @override
  String get mediaNowPlaying => 'Now playing';

  @override
  String get mediaUpNext => 'Up next';

  @override
  String mediaUnnamedChapter(String number) {
    return 'Chapter $number';
  }

  @override
  String get mediaGroupLead => 'Leads the group';

  @override
  String get mediaGroupReadFailed => 'The group could not be read.';

  @override
  String get mediaGroupEmpty => 'No other players to group with.';

  @override
  String get mediaSpeakerSelection => 'Speaker selection';

  @override
  String pluginCloseWindow(String name) {
    return 'Close $name';
  }

  @override
  String get pluginScanTitle => 'Scan a code';

  @override
  String get pluginScanHelp => 'Hold the code inside the frame.';

  @override
  String pluginScanSource(String name) {
    return 'Requested by $name';
  }

  @override
  String get pluginActions => 'Actions';

  @override
  String get pluginKioskDrawer => 'Kiosk drawer';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      'To assign a gesture, open Gestures and choose Run a plugin action.';

  @override
  String get pluginShowInKioskDrawer => 'Show in kiosk drawer';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      'Also available while locked if the kiosk drawer is allowed.';

  @override
  String get pluginExposeToHomeAssistant => 'Expose to Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      'Adds a button to the kiosk ESPHome device. Requires ESPHome and native entities.';

  @override
  String pluginConfigureName(String name) {
    return 'Configure $name';
  }

  @override
  String get pluginThePluginDidNotAnswerInTime =>
      'The plugin did not answer in time.';

  @override
  String get pluginNoChoicesYetRefreshToLookForThem =>
      'No choices yet. Refresh to look for them.';

  @override
  String get pluginThisChoiceIsNoLongerListed =>
      'This choice is no longer listed.';

  @override
  String get pluginDashboardLink => 'Dashboard link';

  @override
  String get pluginDashboardLinkHint =>
      'Point a dashboard button\'s tap action at this link.';

  @override
  String get pluginPlugin => 'Plugin';

  @override
  String get pluginEnablePlugins => 'Enable Plugins';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      'Plugins add additional community developed features to Kiosk Satellite.';

  @override
  String get pluginInstalledPlugins => 'Installed plugins';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      'No plugins installed. Add a repository to get started.';

  @override
  String get pluginDeveloperTools => 'Developer Tools';

  @override
  String get pluginCreateAPlugin => 'Create a plugin';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      'Learn how to create plugins with the Hello World template and documentation.';

  @override
  String get pluginThisPluginIsNoLongerInstalled =>
      'This plugin is no longer installed.';

  @override
  String get pluginEnablePluginsToRunThisPlugin =>
      'Enable Plugins to run this plugin.';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      'Enable this plugin from its entry row to run it.';

  @override
  String pluginUninstallName(String name) {
    return 'Uninstall $name?';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return 'Uninstall $name';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return 'Check for updates for $name';
  }

  @override
  String pluginAboutName(String name) {
    return 'About $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings =>
      'This removes the plugin and its settings.';

  @override
  String get pluginUninstall => 'Uninstall';

  @override
  String get pluginNoUpdatesAvailable => 'No updates available.';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      'This plugin was installed from ZIP and has no repository README.';

  @override
  String get pluginImageUnavailable => 'Image unavailable';

  @override
  String get pluginCouldNotOpenThisLink => 'Could not open this link.';

  @override
  String pluginEnableName(String name) {
    return 'Enable $name';
  }

  @override
  String get pluginShowPassword => 'Show password';

  @override
  String get pluginHidePassword => 'Hide password';

  @override
  String get pluginUntitled => 'Untitled';

  @override
  String get pluginSearchIcons => 'Search icons';

  @override
  String get pluginChooseIcon => 'Choose an icon';

  @override
  String get pluginSearchCameraViews => 'Search camera views';

  @override
  String get pluginChooseCameraView => 'Choose a camera view';

  @override
  String get pluginCameraViewGone =>
      'This camera view is gone. Choose another.';

  @override
  String get pluginDragToReorder => 'Drag to reorder';

  @override
  String get pluginDuplicate => 'Duplicate';

  @override
  String get pluginDone => 'Done';

  @override
  String get pluginRequired => 'Required';

  @override
  String get pluginAddPlugin => 'Add plugin';

  @override
  String get pluginInstallFromAGithubRepository =>
      'Install from a GitHub repository';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd =>
      'Make sure you trust the plugin\'s author and its code before installing it.';

  @override
  String get pluginPreview => 'Preview';

  @override
  String get pluginInstalledVersion => 'Installed version';

  @override
  String get pluginAuthor => 'Author';

  @override
  String get pluginLicense => 'License';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      'Plugins run code inside Kiosk Satellite and can access app data and granted Android permissions. A faulty or malicious plugin can expose private information or stop the app from working. Only install plugins from authors you trust.';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      'New plugins start disabled. Updates preserve the enabled state and automatically restart running plugins.';

  @override
  String get pluginTrustAndUpdate => 'Trust and update';

  @override
  String get pluginTrustAndInstall => 'Trust and install';

  @override
  String get pluginInstallFromZip => 'Install from ZIP';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild =>
      'For developers only: test a local build';

  @override
  String get pluginPluginZip => 'Plugin ZIP';

  @override
  String get pluginPluginZipMustBeAtMost4Mb =>
      'Plugin ZIP must be at most 4 MB';

  @override
  String get pluginCouldNotReadTheSelectedZip =>
      'Could not read the selected ZIP';

  @override
  String get pluginBrowsePlugins => 'Browse plugins';

  @override
  String get pluginFindPluginsMadeByTheCommunity =>
      'Find plugins made by the community';

  @override
  String get pluginSearchPlugins => 'Search plugins';

  @override
  String get pluginUpdate => 'Update';

  @override
  String get pluginInstalled => 'Installed';

  @override
  String pluginNeedsAppVersion(String version) {
    return 'Needs Kiosk Satellite $version or newer';
  }

  @override
  String get pluginStars => 'Stars';

  @override
  String get pluginDownloads => 'Downloads';

  @override
  String get pluginActiveInstalls => 'Active installs';

  @override
  String get pluginNoPluginsMatchYourSearch => 'No plugins match your search.';

  @override
  String get pluginCommunityPluginsHasNoPluginsYet =>
      'Community Plugins has no plugins yet.';

  @override
  String get pluginSubmitYourPlugin => 'Submit your plugin';

  @override
  String get pluginListYourPluginInCommunityPlugins =>
      'List your plugin in Community Plugins.';

  @override
  String get pluginCouldNotReachCommunityPlugins =>
      'Could not reach Community Plugins. Check the internet connection.';

  @override
  String get pluginCouldNotLoadCommunityPlugins =>
      'Could not load Community Plugins. Try again later.';

  @override
  String get pluginTurnOn => 'Turn on';

  @override
  String get pluginTurnOnEnablePluginsToInstall =>
      'Turn on Enable Plugins to install this plugin.';

  @override
  String get pluginPreviousPage => 'Previous page';

  @override
  String get pluginNextPage => 'Next page';

  @override
  String pluginPageOfPages(String page, String pages) {
    return 'Page $page of $pages';
  }

  @override
  String get pluginSortBy => 'Sort by';

  @override
  String get pluginSortMostStars => 'Most stars';

  @override
  String get pluginSortRecentlyUpdated => 'Recently updated';

  @override
  String get pluginSortNewest => 'Newest';

  @override
  String get pluginSortName => 'Name';

  @override
  String get pluginSortMostDownloads => 'Most downloads';

  @override
  String get pluginPluginsPerPage => 'Plugins per page';

  @override
  String pluginCountPerPage(String count) {
    return '$count per page';
  }

  @override
  String pluginByAuthor(String author) {
    return 'by $author';
  }

  @override
  String get pluginListedChip => 'Listed in Community Plugins';

  @override
  String get pluginNotListedChip => 'Not listed in Community Plugins';

  @override
  String get pluginCharts => 'Charts';

  @override
  String get pluginReadings => 'Readings';

  @override
  String get pluginWaitingForSamples => 'Waiting for samples';

  @override
  String get pluginLatest => 'Latest';

  @override
  String get pluginSelected => 'Selected';

  @override
  String get pluginNoDataYet => 'No data yet';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      'Tap or drag to inspect samples. Double-tap to follow the latest.';

  @override
  String get pluginNoData => 'No data';

  @override
  String get pluginOn => 'On';

  @override
  String get pluginEmpty => 'Empty';

  @override
  String get pluginChartKeyboardHelp =>
      'Use arrow keys to inspect samples and End for the latest.';

  @override
  String get pluginErrorAssetPath => 'Invalid asset path';

  @override
  String get pluginErrorAssetMissing =>
      'Asset is missing or outside its package';

  @override
  String get pluginErrorAssetSymlink =>
      'Asset directory cannot be a symbolic link';

  @override
  String get pluginErrorAssetSymlinks =>
      'Asset directories cannot be symbolic links';

  @override
  String get pluginErrorAssetsIntegrity =>
      'Installed assets failed their integrity check';

  @override
  String get pluginErrorAssetIntegrity =>
      'Installed asset failed its integrity check';

  @override
  String get pluginErrorManifestMismatch =>
      'Package manifest does not match the reviewed release manifest';

  @override
  String get pluginErrorStagingExists => 'Staging directory already exists';

  @override
  String get pluginErrorCreateDirectory => 'Cannot create plugin directory';

  @override
  String get pluginErrorFileCount => 'At most 512 package files are supported';

  @override
  String get pluginErrorProtectFile => 'Cannot protect plugin file';

  @override
  String get pluginErrorExpandedSize => 'Expanded plugin exceeds 4 MB';

  @override
  String get pluginErrorManifestSize => 'Manifest exceeds 32 KB';

  @override
  String get pluginErrorRequiredFiles =>
      'Package needs kiosk-satellite-plugin.json, plugin.jar and LICENSE';

  @override
  String get pluginErrorNativeCapability =>
      'Native libraries require native capability';

  @override
  String get pluginErrorNativeElf => 'Invalid native ELF library';

  @override
  String get pluginErrorNativeAbi =>
      'Native library ABI does not match its directory';

  @override
  String get pluginErrorDexOnly => 'plugin.jar must contain only DEX files';

  @override
  String get pluginErrorDexHeader => 'Invalid DEX header';

  @override
  String get pluginErrorDexSize => 'Expanded DEX exceeds 4 MB';

  @override
  String get pluginErrorDexEmpty => 'Empty DEX file';

  @override
  String get pluginErrorDexMissing => 'plugin.jar has no classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'Unexpected or duplicate ZIP entry: $name';
  }

  @override
  String get pluginErrorRepositoryMismatch =>
      'The repository release belongs to a different plugin.';

  @override
  String get pluginErrorRepositoryUrl =>
      'Enter a public https://github.com/owner/repository URL';

  @override
  String get pluginErrorRepositoryPath =>
      'Use the repository URL without a file or branch path';

  @override
  String get pluginErrorDownloadOutsideGithub =>
      'Plugin download redirected outside GitHub';

  @override
  String get pluginErrorInvalidRedirect => 'Invalid GitHub redirect';

  @override
  String get pluginErrorRepositoryNotFound =>
      'Public repository, stable release, kiosk-satellite-plugin.json, README.md or release asset was not found.';

  @override
  String get pluginErrorGithubLimited =>
      'GitHub denied the request or its request limit was reached. Try again later.';

  @override
  String get pluginErrorRepositorySize =>
      'Repository file exceeds the size limit';

  @override
  String get pluginErrorTooManyRedirects => 'Too many GitHub redirects';

  @override
  String get pluginErrorStableRelease =>
      'GitHub did not return a published stable release';

  @override
  String get pluginErrorReleaseTag => 'Invalid release tag';

  @override
  String get pluginErrorManifestFile =>
      'Invalid kiosk-satellite-plugin.json manifest';

  @override
  String get pluginErrorIdVersion => 'Invalid plugin ID or version';

  @override
  String get pluginErrorChecksumFilename =>
      'Invalid release checksum or package filename';

  @override
  String get pluginErrorGithubDigest =>
      'The release checksum must match GitHub asset SHA-256 digest';

  @override
  String get pluginErrorTrustAuthor =>
      'Confirm that you trust the plugin author';

  @override
  String get pluginErrorPreviewExpired =>
      'This preview expired. Preview the repository again before installing.';

  @override
  String get pluginErrorReviewedChecksum =>
      'Package SHA-256 does not match the reviewed release';

  @override
  String get pluginErrorNotInstalled => 'Plugin is not installed';

  @override
  String get pluginErrorUpdateZip =>
      'This plugin was installed from ZIP. Use Install from ZIP to update it.';

  @override
  String get pluginErrorAndroidOnly => 'Plugins are available on Android.';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'GitHub request failed ($status)';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return 'Release needs exactly one uploaded $name asset';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return 'Release asset $name must be published by GitHub Actions. Manually uploaded files are not supported.';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return 'Release asset $name exceeds the size limit or is empty';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return 'Invalid release URL for $name';
  }

  @override
  String get pluginErrorNativeLibrary =>
      'Plugin has no native library for this device ABI';

  @override
  String get pluginErrorCallbackTimeout =>
      'Plugin callback timed out. Restart Kiosk if the plugin left work running.';

  @override
  String get pluginErrorEnableFirst => 'Enable the plugin first';

  @override
  String get pluginErrorSaveState => 'Cannot save plugin state';

  @override
  String get pluginErrorPackageHash => 'Invalid installed package hash';

  @override
  String get pluginErrorChecksum => 'Package SHA-256 does not match';

  @override
  String get pluginErrorDifferentRepository =>
      'This plugin ID belongs to another repository. Uninstall it before changing sources.';

  @override
  String get pluginErrorRestartReplace =>
      'This plugin did not stop cleanly. Restart Kiosk Satellite before replacing it.';

  @override
  String get pluginErrorAlreadyInstalled => 'This package is already installed';

  @override
  String get pluginErrorLoadedIntegrity =>
      'Previously loaded package failed its integrity check. Restart Kiosk Satellite before reinstalling it.';

  @override
  String get pluginErrorRemovePackage => 'Cannot remove unused package';

  @override
  String get pluginErrorInstallPackage => 'Cannot install plugin package';

  @override
  String get pluginErrorUpdateCanceled =>
      'Update canceled because the plugin did not stop cleanly. Restart Kiosk Satellite before trying again.';

  @override
  String get pluginErrorVersionRetained => 'The previous version was retained.';

  @override
  String get pluginErrorRetainedDisabled =>
      'The previous version was retained but is disabled. Restart Kiosk Satellite before enabling it.';

  @override
  String get pluginErrorVersionRunning =>
      'The previous version is running again.';

  @override
  String get pluginErrorEnablePlugins => 'Enable Plugins first';

  @override
  String get pluginErrorRestartEnable =>
      'This plugin did not stop cleanly. Restart Kiosk Satellite before enabling it.';

  @override
  String get pluginErrorInstalledIntegrity =>
      'Installed plugin failed its integrity check. Reinstall it.';

  @override
  String get pluginErrorAndroidOld => 'Android version is too old';

  @override
  String get pluginErrorNeedsScreen => 'This plugin needs a screen';

  @override
  String get pluginErrorNativeIntegrity =>
      'Installed native libraries failed their integrity check';

  @override
  String get pluginErrorNativeFileIntegrity =>
      'Installed native library failed its integrity check';

  @override
  String pluginErrorReadInstalled(String error) {
    return 'Cannot read installed plugin: $error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return 'The previous version could not restart: $error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return 'Plugin update failed: $error. $recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      'Shizuku 13 or later is required. Tap for setup instructions.';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      'Start Shizuku on this device. Tap for setup instructions.';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku grants Kiosk Satellite shell or root access. Installed plugins run inside KS, so only grant access if you trust them.';

  @override
  String get pluginSetUp => 'Set up';

  @override
  String get pluginGrantAccess => 'Grant access';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      'Approve the permission request on the kiosk.';

  @override
  String get pluginErrorInvalidId => 'Invalid plugin ID';

  @override
  String get pluginErrorInvalidVersion => 'Invalid version';

  @override
  String get pluginErrorEntryClass => 'Invalid entry class';

  @override
  String get pluginErrorManifestSchema => 'Unsupported manifest schema';

  @override
  String get pluginErrorSdkVersion =>
      'This plugin needs a different SDK version';

  @override
  String get pluginErrorMinimumSdk => 'Minimum Android SDK must be at least 24';

  @override
  String get pluginErrorCapability => 'Unsupported plugin capability';

  @override
  String get pluginErrorTooManySettings => 'Too many settings or commands';

  @override
  String get pluginErrorSettingKey => 'Invalid or duplicate setting key';

  @override
  String get pluginErrorGroupsArray => 'Display groups must be an array';

  @override
  String get pluginErrorTooManyGroups => 'Too many display groups';

  @override
  String get pluginErrorUniqueGroups =>
      'Display groups must name unique settings groups';

  @override
  String get pluginErrorGroupReferences => 'Too many group references';

  @override
  String get pluginErrorDuplicateReference =>
      'Invalid or duplicate group reference';

  @override
  String get pluginErrorCommandId => 'Invalid or duplicate command ID';

  @override
  String get pluginErrorUnknownSetting => 'Unknown plugin setting';

  @override
  String get pluginErrorTextLength =>
      'Text settings must be at most 512 characters';

  @override
  String get pluginErrorEntityId => 'Expected a Home Assistant entity ID';

  @override
  String get pluginErrorBoolean => 'Expected a boolean setting';

  @override
  String get pluginErrorColor => 'Expected an RGB hex color';

  @override
  String get pluginErrorNumber => 'Expected a numeric setting';

  @override
  String get pluginErrorRange => 'Numeric setting is outside its range';

  @override
  String get pluginErrorStep => 'Numeric setting does not match its step';

  @override
  String get pluginErrorSelection => 'Invalid selection setting';

  @override
  String get pluginErrorSelectionOption => 'Unknown selection option';

  @override
  String get pluginErrorSettingType => 'Unsupported setting type';

  @override
  String get pluginErrorInvalidManifest => 'Invalid plugin manifest';

  @override
  String pluginErrorAndroidApi(String version) {
    return 'Plugin needs Android API $version';
  }

  @override
  String pluginErrorAppVersion(String required, String current) {
    return 'Plugin needs Kiosk Satellite $required or newer. This kiosk runs $current.';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return 'Invalid $field';
  }

  @override
  String get pluginErrorTooManyTriggers => 'Too many triggers';

  @override
  String get pluginErrorTriggerId => 'Invalid or duplicate trigger ID';

  @override
  String get pluginErrorListSetting => 'Invalid list setting';

  @override
  String get pluginErrorSettingCondition => 'Invalid setting condition';

  @override
  String get pluginErrorIcon => 'Expected an MDI icon name';

  @override
  String get pluginErrorDashboard => 'Expected a dashboard path';

  @override
  String get pluginErrorCameraView => 'Expected a camera view ID';

  @override
  String get pluginErrorListValue => 'Expected a list setting';

  @override
  String get pluginErrorListCount => 'Too many or too few list items';

  @override
  String get pluginErrorRequiredField => 'Fill in every required field';

  @override
  String get pluginErrorListSize => 'List settings must be at most 32 KB';

  @override
  String get remoteDisableTitle => 'Turn off remote management?';

  @override
  String get remoteDisableHelp =>
      'WARNING: You will no longer be able to access this page. To switch it back on, use the device or the Remote management switch in Home Assistant.';

  @override
  String get remoteDisableConfirm => 'Turn it off';

  @override
  String get remoteCopyHelp => 'Select the key and copy it by hand.';

  @override
  String get remoteSaveSettingFailed =>
      'Could not save this setting. Try again.';

  @override
  String get remoteReconnecting => 'Reconnecting…';

  @override
  String remoteConnectionLost(String name) {
    return 'The connection to $name was lost. This page resumes on its own when it is back.';
  }

  @override
  String get remoteConnectionLostUnnamed =>
      'The connection to the kiosk was lost. This page resumes on its own when it is back.';

  @override
  String get remoteReloadPage => 'Reload page';

  @override
  String get remoteUpdated => 'Kiosk Satellite was updated';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return 'The device is now running version $version$build. This page belongs to the previous version and will reload in $seconds s.';
  }

  @override
  String remoteBuild(String build) {
    return ' (build $build)';
  }

  @override
  String get remoteReloadNow => 'Reload now';

  @override
  String get remoteLogin => 'Log in';

  @override
  String get remoteInvalidPassword => 'Invalid password';

  @override
  String get remoteLoginThrottled =>
      'Too many attempts. Wait 5 minutes and try again.';

  @override
  String get deviceScreenOffPermission =>
      'Turning the screen off needs a one-time permission. The tablet is now showing the \"device admin\" grant screen. Approve it there, then try again.';

  @override
  String get deviceAdminInactive =>
      'The device admin permission is not active.';

  @override
  String get deviceRestartOverlay =>
      'Restarting needs the \"Display over other apps\" permission or the app cannot bring itself back. The grant screen is opening on the device; allow it there and retry.';

  @override
  String get deviceRebootPermission =>
      'Restarting the device needs Kiosk Satellite provisioned as the device owner or a granted Shizuku connection.';

  @override
  String get deviceRestartAndroidOnly =>
      'Restart is only available on Android.';

  @override
  String get deviceRestartShizukuRefused => 'Shizuku refused the restart';

  @override
  String deviceRestartFailed(String error) {
    return 'Restart failed: $error';
  }

  @override
  String get overviewAttention => 'Needs attention';

  @override
  String get overviewUpdate => 'Update';

  @override
  String overviewInvitation(String name) {
    return '$name wants to lead this kiosk';
  }

  @override
  String get overviewOutdatedOne => '1 follower runs another release';

  @override
  String overviewOutdatedMany(String count) {
    return '$count followers run another release';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names. Sync waits for version $version.';
  }

  @override
  String get overviewThisRelease => 'this release';

  @override
  String get overviewUpdateAvailable => 'Update available';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version is ready to install. The installation is confirmed on the tablet screen.';
  }

  @override
  String overviewInstallSilentHelp(String version) {
    return 'Kiosk Satellite $version is ready to install. It installs without a confirmation on the device.';
  }

  @override
  String overviewInstallHeadlessHelp(String version) {
    return 'Kiosk Satellite $version is ready to install. This device has no screen to confirm it on, so make Kiosk Satellite the device owner, use Shizuku or install it over adb.';
  }

  @override
  String get overviewHaSetup => 'Home Assistant not set up';

  @override
  String get overviewHaSetupHelp =>
      'Connect the kiosk to Home Assistant to load a dashboard.';

  @override
  String get overviewSetUp => 'Set up';

  @override
  String get overviewHaNotValidated => 'Home Assistant not validated';

  @override
  String get overviewHaNotValidatedHelp =>
      'The URL and token have not passed a connection check this run. The kiosk retries every 30 seconds.';

  @override
  String get overviewOpenSetup => 'Open setup';

  @override
  String get overviewWakeStopped => 'Wake word detection stopped';

  @override
  String get overviewWakeReleased => 'The engine was released.';

  @override
  String get overviewOpenVoice => 'Open Voice Satellite';

  @override
  String get overviewOpenService => 'Open service';

  @override
  String overviewPermissionMissing(String permission) {
    return 'Permission missing: $permission';
  }

  @override
  String get overviewSystemUpdate => 'System update available';

  @override
  String overviewPluginUpdate(String name) {
    return '$name update available';
  }

  @override
  String overviewPluginUpdateHelp(String version) {
    return 'Version $version is ready to review and install.';
  }

  @override
  String overviewSystemImageUpdateHelp(String version) {
    return 'Version $version of the system image is ready to install. The device restarts twice to install it.';
  }

  @override
  String get overviewQuick => 'Quick controls';

  @override
  String get overviewReload => 'Reload page';

  @override
  String get overviewScreenOn => 'Screen on';

  @override
  String get overviewScreenOff => 'Screen off';

  @override
  String get overviewSaverStart => 'Start screensaver';

  @override
  String get overviewSaverStop => 'Dismiss screensaver';

  @override
  String get overviewCameraShow => 'Show camera view';

  @override
  String get overviewCameraHide => 'Dismiss camera view';

  @override
  String get overviewSaverPostpone => 'Postpone screensaver';

  @override
  String get overviewDnd => 'Do not disturb';

  @override
  String get overviewDndOn => 'Do not disturb on';

  @override
  String get overviewSnapshot => 'Take snapshot';

  @override
  String get overviewCheckUpdates => 'Check for updates';

  @override
  String get overviewRestartApp => 'Restart app';

  @override
  String get overviewRestartDevice => 'Restart device';

  @override
  String get overviewExit => 'Exit app';

  @override
  String get overviewBrightness => 'Brightness';

  @override
  String get overviewVolume => 'Master Volume';

  @override
  String get overviewBrightnessGrant =>
      'Brightness is using an app-level fallback. Grant \"Modify system settings\" so the slider controls the panel\'s actual brightness.';

  @override
  String get overviewRestartQuestion =>
      'Restart this device? Kiosk Satellite comes back when it boots.';

  @override
  String get overviewRestart => 'Restart';

  @override
  String get overviewNoSnapshot => 'No snapshot came back.';

  @override
  String get overviewSnapshotTitle => 'Camera snapshot';

  @override
  String get overviewUpdateCheckFailed =>
      'Update check failed. Can the device reach GitHub?';

  @override
  String get overviewLatest => 'You are on the latest version.';

  @override
  String overviewVersionAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get overviewInstallAttention => 'Install it from Needs attention.';

  @override
  String get overviewNoViewsWithCameras =>
      'No camera view has any cameras yet. Add cameras to a view under Cameras first.';

  @override
  String get overviewShowViewFailed => 'Could not show view';

  @override
  String get overviewAppVersion => 'App Version';

  @override
  String get overviewNotSetup => 'Not set up';

  @override
  String get overviewNotValidated => 'Not validated';

  @override
  String get overviewCheckingFilter => 'Checking filter...';

  @override
  String get overviewValidated => 'Validated';

  @override
  String get overviewFilterUnavailable => 'Filter status unavailable';

  @override
  String get overviewUnfiltered => 'Updates unfiltered';

  @override
  String get overviewWatchingOne => 'Watching 1 entity';

  @override
  String overviewWatchingMany(String count) {
    return 'Watching $count entities';
  }

  @override
  String overviewFilterDisabled(String count) {
    return 'Filtering disabled, view uses $count entities';
  }

  @override
  String get overviewWakeOff => 'Wake word detection off';

  @override
  String overviewListeningFor(String words) {
    return 'Listening for $words';
  }

  @override
  String get overviewListening => 'Listening';

  @override
  String get overviewNotListening => 'Not listening';

  @override
  String get overviewEntitiesProxy => 'Entities and BT proxy';

  @override
  String get overviewEntitiesOnly => 'Entities only';

  @override
  String get overviewProxyOnly => 'BT Proxy only';

  @override
  String get overviewWaitingHA => 'Waiting for Home Assistant';

  @override
  String get overviewNotRunning => 'Not running';

  @override
  String get overviewRunningOne => 'Running - 1 feature';

  @override
  String overviewRunningMany(String count) {
    return 'Running - $count features';
  }

  @override
  String overviewDownloading(String version) {
    return 'Downloading: $version';
  }

  @override
  String overviewNewVersion(String version) {
    return 'New version: $version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return 'Up to date: $version';
  }

  @override
  String get overviewCurrent => 'Up to date';

  @override
  String overviewPluginAttribution(String name) {
    return '$name plugin';
  }

  @override
  String get overviewMuted => 'muted';

  @override
  String get overviewBrowser => 'browser';

  @override
  String get overviewWakeWaiting =>
      'Waiting for Voice Satellite. The engine and wake words are configured by the integration once this device opens its dashboard.';

  @override
  String get overviewWakeDisabled =>
      'Wake word detection is off. Turn it on to inherit models from Voice Satellite.';

  @override
  String get overviewMicBlocked =>
      'Microphone blocked. Android will not ask again, so allow it in the app settings, then retry.';

  @override
  String get overviewMicDeclined =>
      'Microphone declined. Wake word detection needs it; retry to be asked again.';

  @override
  String get overviewMicLost =>
      'The microphone stopped working. Retry, or reload the page.';

  @override
  String get overviewModelsUnavailable =>
      'Could not download the models from Home Assistant. Retry once it is reachable.';

  @override
  String get overviewCrashed =>
      'The detector kept crashing on this device, so it was stopped. Voice Satellite is listening in the browser instead. Retry, or restart the app.';

  @override
  String get overviewWakeFailed =>
      'The wake-word engine could not start. Retry, or reload the page.';

  @override
  String overviewNativeUnavailable(String engine) {
    return 'No native runner for $engine. Voice Satellite keeps browser detection.';
  }

  @override
  String get overviewNativeListening => 'Listening natively';

  @override
  String get overviewSuspended => 'Ready (suspended during a voice session)';

  @override
  String get overviewCpu => 'CPU';

  @override
  String get overviewMemory => 'RAM';

  @override
  String get overviewTemperature => 'Temp';

  @override
  String overviewMemoryFree(String amount) {
    return '$amount GB free';
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
  String get overviewShowingCustomPages => 'Showing custom pages';

  @override
  String get overviewHeadlessMode => 'Headless mode';

  @override
  String get overviewNoScreenshot => 'No screenshot';

  @override
  String get overviewStill => 'Still';

  @override
  String get overviewLive => 'Live';

  @override
  String get overviewFullSize => 'Full size';

  @override
  String get overviewLiveInterval => 'Live, every 5 seconds';

  @override
  String overviewTaken(String age) {
    return 'Taken $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return 'Camera view: $name';
  }

  @override
  String get overviewCameraView => 'Camera view';

  @override
  String get overviewScreenOffState => 'Screen is off';

  @override
  String get overviewGoView => 'Go to view';

  @override
  String get screensaverNoPhotos =>
      'No photos selected. Pick some in Settings.';

  @override
  String get screensaverNoFolder => 'No folder selected. Pick one in Settings.';

  @override
  String screensaverFolderEmpty(String folder) {
    return 'No photos or videos in $folder';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return 'Could not read $folder. Is the media permission granted?';
  }

  @override
  String get screensaverReadPhotosFailed => 'Could not read photos.';

  @override
  String get screensaverImmichNotReady =>
      'Immich is not connected. Validate it in Settings.';

  @override
  String get screensaverNoMediaMatch =>
      'No media matches the source and filters.';

  @override
  String get screensaverNoMediaSource => 'No media in the selected source.';

  @override
  String get screensaverImmichUnreachable =>
      'Could not reach the Immich server.';

  @override
  String screensaverRetryNotice(String error) {
    return '$error Retrying automatically.';
  }

  @override
  String get screensaverVideosTooLarge =>
      'Every video in this playlist is too large for this device to play.';

  @override
  String get screensaverUrlNotSet => 'No image URL set. Add one in Settings.';

  @override
  String get screensaverUrlLoadFailed => 'Could not load the image.';

  @override
  String get settingKioskAllowAlarmsTitle => 'Alarms';

  @override
  String get settingKioskAllowAlarmsDescription =>
      'Set and manage alarms from the kiosk menu.';

  @override
  String get settingScreensaverClockAlarmTakeoverTitle =>
      'Let alarms take over';

  @override
  String get settingScreensaverClockAlarmTakeoverDescription =>
      'A ringing alarm shows on this screensaver, in its style, instead of on its own screen.';

  @override
  String get settingScreensaverWeatherAlarmTakeoverTitle =>
      'Let alarms take over';

  @override
  String get settingScreensaverWeatherAlarmTakeoverDescription =>
      'A ringing alarm shows on this screensaver, in its style, instead of on its own screen.';

  @override
  String get settingAlarmsVolumeTitle => 'Alarm volume';

  @override
  String get settingAlarmsVolumeDescription =>
      'How loud alarms ring, apart from the media volume.';

  @override
  String get settingAlarmsToneTitle => 'Alarm tone';

  @override
  String get settingAlarmsToneDescription => 'Plays at the alarm volume.';

  @override
  String get settingAlarmsMusicTitle => 'Alarm music';

  @override
  String get settingAlarmsMusicDescription =>
      'Rings instead of the tone. The tone rings if the music cannot play.';

  @override
  String get settingAlarmsSnoozeMinutesTitle => 'Snooze length';

  @override
  String get settingAlarmsSnoozeMinutesDescription =>
      'How long Snooze holds an alarm off.';

  @override
  String get settingAlarmsSilenceAfterMinutesTitle => 'Silence after';

  @override
  String get settingAlarmsSilenceAfterMinutesDescription =>
      'An alarm nobody stops goes quiet after this long.';

  @override
  String get settingAlarmsSunriseMinutesTitle => 'Sunrise length';

  @override
  String get settingAlarmsSunriseMinutesDescription =>
      'How long the screen takes to brighten before a sunrise alarm.';

  @override
  String get alarmsOption5Minutes => '5 minutes';

  @override
  String get alarmsOption10Minutes => '10 minutes';

  @override
  String get alarmsOption15Minutes => '15 minutes';

  @override
  String get alarmsOption20Minutes => '20 minutes';

  @override
  String get alarmsOption25Minutes => '25 minutes';

  @override
  String get alarmsOption30Minutes => '30 minutes';

  @override
  String get settingsMenuAlarms => 'Alarms';

  @override
  String get settingsMenuAlarmsSummary => 'Set alarms, tone, snooze, sunrise';

  @override
  String get settingAlarmsEaseInTitle => 'Ease in the volume';

  @override
  String get settingAlarmsEaseInDescription =>
      'Start quiet and grow to the alarm volume.';

  @override
  String get settingAlarmsEaseInSecondsTitle => 'Ease in over';

  @override
  String get settingAlarmsEaseInSecondsDescription =>
      'How long an alarm takes to reach its full volume.';

  @override
  String get settingAlarmsTtsEngineTitle => 'Text to speech engine';

  @override
  String get settingAlarmsTtsEngineDescription =>
      'The Home Assistant text to speech entity that speaks alarms.';

  @override
  String get settingAlarmsTtsLanguageTitle => 'Language';

  @override
  String get settingAlarmsTtsLanguageDescription =>
      'The language alarms are spoken in.';

  @override
  String get settingAlarmsTtsVoiceTitle => 'Voice';

  @override
  String get settingAlarmsTtsVoiceDescription =>
      'The voice that speaks alarms.';

  @override
  String get settingLauncherEnabledTitle => 'Enable App Launcher';

  @override
  String get settingLauncherEnabledDescription =>
      'Open a picked set of installed apps from the kiosk.';

  @override
  String get settingLauncherAppsDescription => 'The apps the launcher offers.';

  @override
  String get settingLauncherAutoReturnTitle => 'Return automatically';

  @override
  String get settingLauncherAutoReturnDescription =>
      'Come back to the kiosk once the other app has gone untouched for a while.';

  @override
  String get settingLauncherAutoReturnSecondsTitle => 'Return after (seconds)';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      'Time without a touch in the other app before the kiosk comes back.';

  @override
  String get settingLauncherAutoReturnHoldTitle =>
      'Wait during media and calls';

  @override
  String get settingLauncherAutoReturnHoldDescription =>
      'Do not come back during video, music or calls.';

  @override
  String get launcherOverlayHeld =>
      'Kiosk Satellite can bring itself back in the foreground and notice touches in the other app.';

  @override
  String get launcherOverlayMissing =>
      'Without this the kiosk cannot come back on its own, and touches in the other app go unseen.';

  @override
  String get launcherOverlayRemote =>
      'Without this the kiosk cannot come back on its own, and touches in the other app go unseen. The grant screen appears on the tablet.';

  @override
  String get launcherBatteryMissing =>
      'Android may pause the app behind the other one, and a paused clock never brings the kiosk back.';

  @override
  String get launcherBatteryRemote =>
      'Android may pause the app behind the other one, and a paused clock never brings the kiosk back. The grant dialog appears on the tablet.';

  @override
  String get launcherNotificationAccessHeld =>
      'The kiosk stays away while video or music plays in another app.';

  @override
  String get launcherNotificationAccessMissing =>
      'Without this the kiosk cannot tell when video or music is playing and comes back anyway.';

  @override
  String get launcherNotificationAccessRemote =>
      'Without this the kiosk cannot tell when video or music is playing and comes back anyway. The grant screen appears on the tablet.';

  @override
  String get launcherPermissionsSearch =>
      'The grants Return automatically leans on.';

  @override
  String get settingCalendarDefaultViewTitle => 'Default view';

  @override
  String get settingCalendarDefaultViewDescription =>
      'The view Calendar opens on.';

  @override
  String get settingCalendarWeekStartTitle => 'Week starts on';

  @override
  String get settingCalendarWeekStartAppLanguageDescription =>
      'Follows the app language unless set.';

  @override
  String get settingCalendarWeatherEntityTitle => 'Weather';

  @override
  String get settingCalendarWeatherEntityDescription =>
      'Adds the forecast to each day.';

  @override
  String get settingCalendarAllowEditTitle => 'Allow adding and editing events';

  @override
  String get settingCalendarAllowEditDescription =>
      'Adds New event and Edit to the calendar.';

  @override
  String get settingCalendarAllowDeleteTitle => 'Allow deleting events';

  @override
  String get settingCalendarAllowDeleteDescription =>
      'Adds Delete to each event.';

  @override
  String get settingCalendarIdleCloseMinutesTitle => 'Close when idle';

  @override
  String get settingIdleCloseCompassDescription =>
      'Returns to the dashboard after no touch for this long. In the Compass layout, Return to center applies instead.';

  @override
  String get settingKioskAllowCalendarTitle => 'Calendar';

  @override
  String get settingKioskAllowCalendarDescription =>
      'Open the family calendar from the kiosk menu.';

  @override
  String get calendarWeekStartLocale => 'Language default';

  @override
  String get calendarWeekStartSunday => 'Sunday';

  @override
  String get calendarWeekStartMonday => 'Monday';

  @override
  String get calendarWeekStartSaturday => 'Saturday';

  @override
  String get calendarIdleNever => 'Never';

  @override
  String get calendarIdle1Minute => '1 minute';

  @override
  String get calendarIdle2Minutes => '2 minutes';

  @override
  String get settingsMenuCalendar => 'Calendar';

  @override
  String get settingsMenuCalendarSummary =>
      'Family calendars from Home Assistant';

  @override
  String get fleetTheCalendarsHiddenWithTheirChips =>
      'the calendars hidden with their chips';

  @override
  String get settingCameraEnabledTitle => 'Enable camera';

  @override
  String get settingCameraEnabledDescription =>
      'Camera use adds CPU load and heat, which can shorten the battery and device lifespan.';

  @override
  String get settingCameraDeviceTitle => 'Camera';

  @override
  String get settingCameraDeviceDescription => 'Which camera to use.';

  @override
  String get settingCameraSnapshotResolutionTitle => 'Snapshot resolution';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      'Higher looks sharper but costs more CPU and bandwidth.';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle =>
      'Disable snapshots on detection';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      'Prevent automatic snapshots triggered by detection. Motion, face, presence and gesture detection keep working. Manual requests and Continuous snapshots can still capture images.';

  @override
  String get settingCameraSnapshotsTitle => 'Continuous snapshots';

  @override
  String get settingCameraSnapshotsDescription =>
      'Publish a fresh camera snapshot to Home Assistant at a fixed interval.';

  @override
  String get settingCameraSnapshotIntervalTitle => 'Snapshot interval';

  @override
  String get settingCameraSnapshotIntervalDescription =>
      'Seconds between snapshots.';

  @override
  String get cameraFront => 'Front';

  @override
  String get cameraBack => 'Back';

  @override
  String get cameraExternal => 'External';

  @override
  String get cameraOnlyCamera => 'The only camera this device has.';

  @override
  String get settingMotionSensorTitle => 'Motion sensor';

  @override
  String get settingMotionSensorDescription =>
      'Expose motion as a Home Assistant sensor. WARNING: Keeps the camera running permanently, even with the screen off.';

  @override
  String get settingMotionSensorOffDelayTitle => 'Clear after';

  @override
  String get settingMotionSensorOffDelayDescription =>
      'Seconds without motion before the sensor reads clear.';

  @override
  String get settingMotionFpsTitle => 'Motion frame rate';

  @override
  String get settingMotionFpsDescription =>
      'Frames per second the camera checks for motion. Lower is lighter on the CPU; 2 is plenty to notice someone approaching.';

  @override
  String get settingMotionStartDelayTitle => 'Startup delay';

  @override
  String get settingMotionStartDelayDescription =>
      'Ignore motion for this long after the camera starts, for devices whose camera physically moves as it opens.';

  @override
  String get settingMotionSensitivityTitle => 'Motion sensitivity';

  @override
  String get settingMotionSensitivityDescription =>
      'Higher trips on smaller movements. 1 needs a large change across the frame; 100 reacts to the slightest motion.';

  @override
  String get cameraMotionPage => 'Motion Sensor';

  @override
  String get cameraMotionHint =>
      'Home Assistant motion sensor and shared detection settings';

  @override
  String get cameraNoCamera => 'No camera detected';

  @override
  String get cameraNoCameraHelp =>
      'This device does not report any usable camera.';

  @override
  String get cameraCameraPermission => 'Camera permission missing';

  @override
  String get cameraCameraPermissionHelp =>
      'Without it the camera cannot be used. The grant dialog appears on the tablet screen.';

  @override
  String get cameraGrantOnDevice => 'Grant on device';

  @override
  String get cameraCameraBlocked =>
      'Blocked. Android will not ask again, so allow it in the app settings.';

  @override
  String get cameraCameraNeeded => 'Without this the camera cannot be used.';

  @override
  String get cameraAppSettings => 'App settings';

  @override
  String get settingPersonSensorTitle => 'Enable person sensor';

  @override
  String get settingPersonSensorDescription =>
      'Expose the device\'s person sensor to Home Assistant as an occupancy sensor. Needs the Log access grant below.';

  @override
  String get cameraPersonPage => 'Person Sensor';

  @override
  String get cameraPersonHint =>
      'Home Assistant occupancy sensor from the device\'s person sensor';

  @override
  String get cameraLatest => 'Latest snapshot';

  @override
  String get cameraNoSnapshot => 'No snapshot yet.';

  @override
  String get cameraImageAlt => 'Latest camera snapshot';

  @override
  String get cameraTakeSnapshot => 'Take snapshot';

  @override
  String get cameraSnapshotFailed => 'Snapshot failed.';

  @override
  String cameraSnapshotError(String error) {
    return 'Snapshot failed: $error';
  }

  @override
  String get cameraCameraDisabled =>
      'The camera is disabled in the Camera settings.';

  @override
  String get cameraSnapshotBusy => 'A snapshot is already in progress.';

  @override
  String get cameraPermissionDenied => 'Camera permission not granted.';

  @override
  String get cameraDetectionDisabled => 'Detection snapshots are disabled.';

  @override
  String get cameraNoImage => 'The camera returned no image.';

  @override
  String get cameraTimedOut => 'The camera did not answer in time.';

  @override
  String get cameraBackground =>
      'The camera is unavailable while the app is in the background.';

  @override
  String get cameraJustNow => 'just now';

  @override
  String cameraSecondsAgo(String count) {
    return '$count seconds ago';
  }

  @override
  String get cameraMinuteAgo => '1 minute ago';

  @override
  String cameraMinutesAgo(String count) {
    return '$count minutes ago';
  }

  @override
  String get cameraHourAgo => '1 hour ago';

  @override
  String cameraHoursAgo(String count) {
    return '$count hours ago';
  }

  @override
  String get cameraDayAgo => '1 day ago';

  @override
  String cameraDaysAgo(String count) {
    return '$count days ago';
  }

  @override
  String get cameraStatusHeading => 'Stream Status';

  @override
  String get cameraClientsHeading => 'Connected Clients';

  @override
  String get cameraUnavailable => 'Unavailable';

  @override
  String get cameraStopped => 'Stopped';

  @override
  String get cameraStreaming => 'Streaming';

  @override
  String get cameraIdle => 'Idle';

  @override
  String get cameraConnected => 'Connected';

  @override
  String get cameraChecking => 'Checking...';

  @override
  String get cameraCheckingStatus => 'Checking stream status...';

  @override
  String get cameraStatusUnavailable => 'Stream status unavailable.';

  @override
  String get cameraListenerStopped => 'Listener is stopped.';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count connected viewer. Actual video: $resolution.';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return '$count connected viewers. Actual video: $resolution.';
  }

  @override
  String get cameraReady => 'Ready. The encoder starts when a viewer connects.';

  @override
  String cameraFallback(String requested, String actual) {
    return 'Requested $requested, camera supplied $actual.';
  }

  @override
  String cameraAudioError(String error) {
    return 'Audio: $error';
  }

  @override
  String get cameraAudioPaused =>
      'Audio paused while the browser uses the microphone.';

  @override
  String get cameraAudioStreaming => 'Microphone audio streaming.';

  @override
  String get cameraAudioIdle => 'Microphone audio idle.';

  @override
  String cameraDiscoveryError(String error) {
    return 'ONVIF discovery: $error';
  }

  @override
  String get cameraOnvifUrl => 'ONVIF URL';

  @override
  String get cameraStreamUrl => 'Stream URL';

  @override
  String get cameraWaitingAddress => 'Waiting for a network address';

  @override
  String get cameraClientsUnavailable => 'Client information unavailable.';

  @override
  String get cameraNoClients => 'No connected clients.';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · Port $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return 'Connected for $duration';
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
      'Set a streaming username and password to enable authentication.';

  @override
  String get cameraPortWaiting => 'Waiting for the RTSP port to be released.';

  @override
  String get cameraListenerFailed => 'Could not start the RTSP listener.';

  @override
  String get settingCameraRtspEnabledTitle => 'Enable camera streaming';

  @override
  String get settingCameraRtspEnabledDescription =>
      'Share H.264 video with RTSP or ONVIF clients. Video encoding runs only while a viewer is connected. Hardware encoding is preferred with software fallback when needed. Uses the camera selected in Camera settings.';

  @override
  String get settingCameraStreamingProtocolTitle => 'Streaming protocol';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF lets compatible clients discover the camera and connect to its stream.';

  @override
  String get settingCameraRtspPortTitle => 'Port';

  @override
  String get settingCameraRtspPortDescription => 'RTSP server port.';

  @override
  String get settingCameraOnvifPortTitle => 'Port';

  @override
  String get settingCameraOnvifPortDescription => 'ONVIF server port.';

  @override
  String get settingCameraRtspResolutionTitle => 'Resolution';

  @override
  String get settingCameraRtspResolutionDescription =>
      'Supported streaming sizes for the selected camera and encoder. Video follows the device orientation.';

  @override
  String get settingCameraRtspAnalysisTitle =>
      'Motion analysis while streaming';

  @override
  String get settingCameraRtspAnalysisDescription =>
      'Keep motion detection, face detection and hand gestures available while viewers are connected. Turning this off can allow higher resolutions. Snapshots then use video frames at the streaming resolution.';

  @override
  String get settingCameraRtspFpsTitle => 'Frame rate';

  @override
  String get settingCameraRtspFpsDescription =>
      'Target video frames per second. Motion keeps its separate analysis rate. Actual delivery depends on the camera.';

  @override
  String get settingCameraRtspBitrateTitle => 'Bitrate';

  @override
  String get settingCameraRtspBitrateDescription =>
      'Target video bitrate. Higher improves detail and uses more network bandwidth.';

  @override
  String get settingCameraRtspAudioTitle => 'Include microphone audio';

  @override
  String get settingCameraRtspAudioDescription =>
      'Include microphone audio in the camera stream. Shares your microphone settings. WARNING: Increased CPU usage.';

  @override
  String get settingCameraRtspAuthTitle => 'Require authentication';

  @override
  String get settingCameraRtspAuthDescription =>
      'Require a username and password to view the stream. Authentication does not enable encryption.';

  @override
  String get settingCameraRtspUsernameTitle => 'Username';

  @override
  String get settingCameraRtspUsernameDescription =>
      'Username for streaming clients.';

  @override
  String get settingCameraRtspPasswordTitle => 'Password';

  @override
  String get settingCameraRtspPasswordDescription =>
      'Set a password to start the authenticated stream.';

  @override
  String get cameraStreamingPage => 'RTSP & ONVIF Streaming';

  @override
  String get cameraStreamingHint => 'Share the device camera via RTSP or ONVIF';

  @override
  String get cameraPortError => 'Enter a whole port number from 1024 to 65535.';

  @override
  String get cameraUsernameError =>
      'Use 1 to 64 characters without spaces, quotes, colons or backslashes.';

  @override
  String get cameraNoSizes => 'No supported sizes available';

  @override
  String get cameraNoSizesHelp =>
      'No supported sizes available. Check the camera connection.';

  @override
  String get cameraResolutionSupport => 'Resolution support';

  @override
  String get cameraCheckingSizes =>
      'Checking camera and H.264 encoder support...';

  @override
  String get cameraSupportedSizes =>
      'Only sizes supported by the camera and H.264 encoder at the current streaming settings are listed.';

  @override
  String cameraExtraSizes(String sizes) {
    return 'Turn off Motion analysis while streaming to also use $sizes.';
  }

  @override
  String get cameraAnalysisOff =>
      'Motion detection, face detection and hand gestures pause while viewers are connected. Snapshots use video frames at the streaming resolution.';

  @override
  String cameraRejectedSizes(String sizes) {
    return 'The encoder cannot use $sizes at these settings.';
  }

  @override
  String cameraRejectedCount(String count) {
    return '$count camera sizes are excluded because the encoder cannot use them at these settings.';
  }

  @override
  String get cameraCaptureRejected =>
      'Other camera sizes are unavailable in the current capture setup.';

  @override
  String get cameraMotionEventsHeading => 'Motion Events';

  @override
  String get settingCameraOnvifEventsTitle => 'Send motion events';

  @override
  String get settingCameraOnvifEventsDescription =>
      'Let ONVIF clients such as NVRs know when motion is detected.';

  @override
  String get settingCameraOnvifEventsSourceTitle => 'Motion source';

  @override
  String get settingCameraOnvifEventsSourceDescription =>
      'The sensor that sends motion events.';

  @override
  String get cameraOnvifEventsSourceCamera => 'Camera motion sensor';

  @override
  String get cameraOnvifEventsSourcePerson => 'Person sensor';

  @override
  String get cameraOnvifEventsSourceEntity => 'Home Assistant sensor';

  @override
  String get cameraOnvifEventsMotionSensorOff =>
      'The camera motion sensor is off. Turn it on in Camera > Motion Sensor.';

  @override
  String get cameraOnvifEventsAnalysisOff =>
      'Motion analysis while streaming is off, so the camera cannot detect motion while a viewer is connected.';

  @override
  String get cameraOnvifEventsPersonSensorOff =>
      'The person sensor is off. Turn it on in Camera > Person Sensor.';

  @override
  String get cameraOverlaysHeading => 'Overlays';

  @override
  String get settingCameraRtspDateTimeTitle => 'Show date and time';

  @override
  String get settingCameraRtspDateTimeDescription =>
      'Show the device date and time in the upper-left corner of the video using its date format and 12/24-hour setting.';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => 'Black background';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      'Add a black background behind the date and time for visibility.';

  @override
  String get settingCameraRtspTlsTitle => 'Encrypt stream';

  @override
  String get settingCameraRtspTlsDescription =>
      'Use TLS to encrypt video and audio. Requires a compatible viewer.';

  @override
  String get cameraStreamsNameRequired => 'name required';

  @override
  String get cameraStreamsBaseUrlRequired =>
      'valid HTTP or HTTPS baseUrl required';

  @override
  String get cameraStreamsServerNotFound => 'server not found';

  @override
  String get cameraStreamsInvalidStreamList =>
      'Go2RTC returned an invalid stream list';

  @override
  String get cameraStreamsKindRequired => 'kind must be go2rtc, whep or ha';

  @override
  String get cameraStreamsProtocolRequired =>
      'preferredProtocol must be auto, webrtc, hls or mjpeg';

  @override
  String get cameraStreamsServerRequired => 'valid serverId required';

  @override
  String get cameraStreamsStreamRequired => 'streamName required';

  @override
  String get cameraStreamsEntityRequired => 'a camera.* entityId is required';

  @override
  String get cameraStreamsWhepRequired => 'valid WHEP URL required';

  @override
  String get cameraStreamsCameraNotFound => 'camera not found';

  @override
  String get cameraStreamsListRequired => 'cameraIds must be a list';

  @override
  String get cameraStreamsViewCount => 'a view must contain 1 to 12 cameras';

  @override
  String get cameraStreamsRepeatedCamera =>
      'a camera can appear only once per view';

  @override
  String get cameraStreamsUnknownViewCamera =>
      'view contains an unknown camera';

  @override
  String get cameraStreamsUniqueViewName => 'view name must be unique';

  @override
  String get cameraStreamsGridRange => 'grid must be between 1 and 12';

  @override
  String get cameraStreamsGridTooSmall =>
      'grid is smaller than the camera count';

  @override
  String get cameraStreamsViewNotFound => 'view not found';

  @override
  String get cameraStreamsDefaultViewDelete =>
      'the default view cannot be deleted; empty it instead';

  @override
  String get cameraStreamsViewEmpty => 'view has no cameras';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return 'could not read Home Assistant: $error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return 'could not connect to $server: $error';
  }

  @override
  String get cameraStreamsHaUnavailable =>
      'Home Assistant is not configured or unreachable';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC returned HTTP $status';
  }

  @override
  String get cameraStreamsImportHa => 'Import cameras from Home Assistant';

  @override
  String get cameraStreamsImportHaHelp =>
      'Add every camera of the connected Home Assistant, playing over WebRTC, HLS or MJPEG. Importing again merges new cameras.';

  @override
  String get cameraStreamsImportFailed => 'Import failed';

  @override
  String get cameraStreamsImportComplete => 'Import complete';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return '$added added, $missing missing.';
  }

  @override
  String get settingCameraAllowH265Title => 'Allow H.265 streams';

  @override
  String get settingCameraAllowH265Description =>
      'Play H.265 camera streams as they are. A device that cannot decode H.265 shows a blank image instead.';

  @override
  String get settingCameraPreferMseTitle => 'Prefer MSE over WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      'Stream Go2RTC cameras over MSE first. For devices that cannot play WebRTC; adds a second or two of delay.';

  @override
  String get settingCameraPreferHlsTitle => 'Prefer HLS over WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      'Stream Home Assistant cameras over HLS first. For devices that cannot play WebRTC; adds a few seconds of delay.';

  @override
  String get settingCameraSingleAudioTitle => 'Play sound for a single camera';

  @override
  String get settingCameraSingleAudioDescription =>
      'Play the camera\'s sound when only one camera is on screen. Grids with several cameras stay silent.';

  @override
  String get settingCameraPinchZoomTitle => 'Pinch to zoom a single camera';

  @override
  String get settingCameraPinchZoomDescription =>
      'Zoom into the picture with two fingers when only one camera is on screen. Drag to move around, double-tap to reset.';

  @override
  String get settingCameraAutoDismissSecondsTitle => 'Auto-dismiss after';

  @override
  String get settingCameraAutoDismissCompassDescription =>
      'Closes an opened camera view after this long. 0 keeps it open. The camera screensaver is unaffected. In the Compass layout, Return to center applies instead.';

  @override
  String get cameraStreamsPlayback => 'Playback';

  @override
  String get cameraStreamsOff => 'Off';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get cameraStreamsGridHelp =>
      'Grids with several cameras are video-only. For low-power devices, use lower resolution Go2RTC streams in views and optionally set a separate fullscreen stream.';

  @override
  String get cameraStreamsServers => 'Go2RTC servers';

  @override
  String get cameraStreamsImportStreams => 'Import streams';

  @override
  String get cameraStreamsDeleteServer => 'Delete server';

  @override
  String get cameraStreamsAddServer => 'Add Go2RTC server';

  @override
  String get cameraStreamsAddServerHelp =>
      'Connect to a server and import its streams.';

  @override
  String get cameraStreamsEditServer => 'Edit server';

  @override
  String get cameraStreamsName => 'Name';

  @override
  String get cameraStreamsBaseUrl => 'Base URL';

  @override
  String get cameraStreamsUsername => 'Username (optional)';

  @override
  String get cameraStreamsNewPassword => 'New password (leave blank to keep)';

  @override
  String get cameraStreamsPassword => 'Password (optional)';

  @override
  String get cameraStreamsInvalidCertificate => 'Allow invalid TLS certificate';

  @override
  String get cameraStreamsSaveServerFailed => 'Could not save the server';

  @override
  String get cameraStreamsDeleteServerHelp =>
      'Its cameras will be removed from every view.';

  @override
  String get cameraStreamsCameras => 'Cameras';

  @override
  String get cameraStreamsNoCameras => 'No cameras configured';

  @override
  String get cameraStreamsNoCamerasHelp =>
      'Import cameras from Home Assistant or Go2RTC, or add one manually.';

  @override
  String get cameraStreamsDeleteCamera => 'Delete camera';

  @override
  String get cameraStreamsAddManually => 'Add camera manually';

  @override
  String get cameraStreamsAddManuallyHelp =>
      'Use a Go2RTC stream name, a WHEP URL or a Home Assistant camera entity.';

  @override
  String get cameraStreamsUnknownCamera => 'Unknown camera';

  @override
  String get cameraStreamsUnknownServer => 'Unknown server';

  @override
  String get cameraStreamsMissing => ' (missing)';

  @override
  String get cameraStreamsAddCamera => 'Add camera';

  @override
  String get cameraStreamsEditCamera => 'Edit camera';

  @override
  String get cameraStreamsType => 'Type';

  @override
  String get cameraStreamsGo2RtcStream => 'Go2RTC stream';

  @override
  String get cameraStreamsDirectWhep => 'Direct WHEP URL';

  @override
  String get cameraStreamsHaCamera => 'Home Assistant camera';

  @override
  String get cameraStreamsEntity => 'Camera entity';

  @override
  String get cameraStreamsProtocol => 'Preferred protocol';

  @override
  String get cameraStreamsAuto => 'Auto';

  @override
  String get cameraStreamsServer => 'Server';

  @override
  String get cameraStreamsStreamName => 'Stream name';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Go2RTC stream name';

  @override
  String get cameraStreamsFullscreen => 'Fullscreen stream (optional)';

  @override
  String get cameraStreamsWhep => 'WHEP URL';

  @override
  String get cameraStreamsSaveCameraFailed => 'Could not save the camera';

  @override
  String get cameraStreamsDeleteCameraHelp =>
      'It will be removed from every view.';

  @override
  String get cameraStreamsLoadFailed => 'Could not load cameras.';

  @override
  String get cameraStreamsViews => 'Views';

  @override
  String get cameraStreamsEmptyView => 'No cameras yet';

  @override
  String get cameraStreamsNamesShown => 'Names shown';

  @override
  String get cameraStreamsNamesHidden => 'Names hidden';

  @override
  String get cameraStreamsShowView => 'Show view';

  @override
  String get cameraStreamsDeleteView => 'Delete view';

  @override
  String get cameraStreamsCreateView => 'Create camera view';

  @override
  String get cameraStreamsAddFirst => 'Add a camera first.';

  @override
  String get cameraStreamsChooseCameras => 'Choose and order up to 12 cameras.';

  @override
  String get cameraStreamsShowFailed => 'Could not show the view';

  @override
  String get cameraStreamsShowFailedRemote => 'Could not show view';

  @override
  String get cameraStreamsEditView => 'Edit view';

  @override
  String get cameraStreamsViewId => 'View ID';

  @override
  String get cameraStreamsShowNames => 'Show camera names';

  @override
  String get cameraStreamsShowNamesHelp => 'Display a label over each camera.';

  @override
  String get cameraStreamsGrid => 'Grid';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count Camera';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return '$count Cameras';
  }

  @override
  String get cameraStreamsInView => 'In this view';

  @override
  String get cameraStreamsAvailable => 'Available';

  @override
  String cameraStreamsPosition(String position) {
    return 'Position $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'Missing from Go2RTC';

  @override
  String get cameraStreamsSaveViewFailed => 'Could not save the view';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return 'Delete $name?';
  }

  @override
  String get cameraStreamsCannotUndo => 'This cannot be undone.';

  @override
  String get cameraStreamsShow => 'Show';

  @override
  String get cameraStreamsStop => 'Stop';

  @override
  String get settingAnalyticsBasicTitle => 'Basic analytics';

  @override
  String get settingAnalyticsBasicDescription =>
      'Information about your device, such as model, Android version, app version, screen size and language.';

  @override
  String get settingAnalyticsUsageTitle => 'Usage';

  @override
  String get settingAnalyticsUsageDescription =>
      'Details of what you use with Kiosk Satellite.';

  @override
  String get settingAnalyticsDiagnosticsTitle => 'Diagnostics';

  @override
  String get settingAnalyticsDiagnosticsDescription =>
      'Share crash reports when unexpected errors occur.';

  @override
  String get deviceAnalyticsPage => 'Kiosk Satellite Analytics';

  @override
  String get deviceAnalyticsIntro =>
      'Share anonymized information from your installation to help make Kiosk Satellite better and guide which devices and features get attention.';

  @override
  String get deviceAnalyticsLearn => 'Learn how we process your data';

  @override
  String get deviceAnalyticsLearnHelp =>
      'What Kiosk Satellite Analytics sends and what it never sends.';

  @override
  String get deviceExportConfig => 'Export configuration';

  @override
  String get deviceExportConfigHelp =>
      'Save every setting and the page\'s local storage to a file.';

  @override
  String get deviceExportConfigRemoteHelp =>
      'Download every setting and the page\'s local storage.';

  @override
  String get deviceImportConfig => 'Import configuration';

  @override
  String get deviceImportConfigHelp =>
      'Replace this device\'s settings from an exported file.';

  @override
  String get deviceExportFailed => 'Export failed';

  @override
  String get deviceExported => 'Configuration exported';

  @override
  String get deviceImportFailed => 'Import failed';

  @override
  String get deviceInvalidJson => 'That file is not valid JSON.';

  @override
  String get deviceImportComplete => 'Import complete';

  @override
  String deviceAppliedSettings(String count) {
    return 'Applied $count settings.';
  }

  @override
  String deviceAppliedReload(String count) {
    return 'Applied $count settings. The page may reload.';
  }

  @override
  String get deviceReplaceOriginal => 'Replace the original device';

  @override
  String get deviceReplaceQuestion =>
      'Replace this device\'s settings with the file\'s? The page may reload.';

  @override
  String get deviceNewDevice => 'Set up as new device';

  @override
  String get deviceReplaceIdentity =>
      'Keeps the backup\'s name and ESPHome identity; the original device must stay offline.';

  @override
  String get deviceNewIdentity =>
      'Assign its own name and ESPHome identity, so both devices are unique.';

  @override
  String get deviceRestoreStorage => 'Restore Webview\'s local storage';

  @override
  String get deviceRestoreStorageHelp =>
      'Includes the Home Assistant signed in session and the Voice Satellite assist_satellite selection - two devices must not share one satellite.';

  @override
  String get deviceDownload => 'Download';

  @override
  String get deviceChooseFile => 'Choose file…';

  @override
  String get deviceImportFailedSentence => 'Import failed.';

  @override
  String deviceReplaceNamed(String name) {
    return 'Replace \"$name\"';
  }

  @override
  String get settingDeviceNameTitle => 'Device name';

  @override
  String get settingDeviceNameDescription =>
      'Friendly name shown in remote management and used as the device name published to Home Assistant.';

  @override
  String get settingDeviceHostnameTitle => 'mDNS name';

  @override
  String get settingDeviceHostnameDescription =>
      'Reach the remote admin using this name and the configured port on the local network. Clear it to take the device name again.';

  @override
  String get settingDisableImpellerTitle => 'Legacy renderer';

  @override
  String get settingDisableImpellerDescription =>
      'Use the older Skia renderer, for old GPUs that crash at startup. Turns itself on after two such crashes; takes effect on the next app start.';

  @override
  String get settingLegacyWebViewTitle => 'Legacy WebView renderer';

  @override
  String get settingLegacyWebViewDescription =>
      'Draw the dashboard into a texture, for old GPUs that crash when it appears. Turns itself on where the device needs it; takes effect on the next app start.';

  @override
  String get deviceHostnamePlaceholder => 'Set from the device name';

  @override
  String get deviceConfiguration => 'Configuration';

  @override
  String get devicePermissionsManager => 'Permissions Manager';

  @override
  String get deviceOptions => 'Options';

  @override
  String get deviceStatus => 'Status';

  @override
  String get deviceConnection => 'Connection';

  @override
  String get devicePermissions => 'Permissions';

  @override
  String get deviceHelp => 'Help';

  @override
  String get deviceAccess => 'Access';

  @override
  String get deviceReading => 'Reading…';

  @override
  String get deviceChecking => 'Checking...';

  @override
  String get deviceUnavailable => 'Status unavailable.';

  @override
  String get deviceGrantOnDevice => 'Grant on device';

  @override
  String get deviceAppSettings => 'App settings';

  @override
  String get deviceCopyCommand => 'Copy command';

  @override
  String get deviceOpenGuide => 'Open guide';

  @override
  String get deviceNotSet => 'Not set';

  @override
  String get deviceGranted => 'Granted';

  @override
  String get deviceNotGranted => 'Not granted';

  @override
  String get deviceMissing => 'Missing';

  @override
  String get deviceNotOffered => 'Not offered';

  @override
  String get deviceOn => 'on';

  @override
  String get deviceOff => 'off';

  @override
  String get deviceServiceHint =>
      'Status, what keeps it running, required permissions';

  @override
  String get deviceRemoteHintActual =>
      'Manage this kiosk from a browser on your network';

  @override
  String get deviceUpdatesHint => 'Where the app looks for new releases';

  @override
  String get deviceShizukuHint => 'Connection, Android permissions and setup';

  @override
  String get deviceHelperHint =>
      'Silent update status, ADB setup and instructions';

  @override
  String get deviceAnalyticsHint =>
      'Share anonymized information to help improve Kiosk Satellite';

  @override
  String get deviceHardwareHint =>
      'Model, Android version, addresses, memory, uptime';

  @override
  String get deviceHaHint => 'Connection, version and what the kiosk shows';

  @override
  String get deviceWebViewHint => 'Engine version, renderer and user agent';

  @override
  String get devicePasswordSet => '•••••• (set)';

  @override
  String get deviceSaveFailed => 'Could not save this setting. Try again.';

  @override
  String get deviceOpenSettingsDevice => 'Open settings on device';

  @override
  String get deviceHardwareButtons => 'Hardware buttons';

  @override
  String get deviceHardwareButtonsHeld =>
      'The device buttons reach gestures and Voice Satellite.';

  @override
  String get deviceHardwareButtonsMissing =>
      'The device buttons do nothing until the button service is switched on.';

  @override
  String get deviceHeadlessAdbMicrophone =>
      'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO';

  @override
  String get deviceHeadlessAdbNotifications =>
      'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS';

  @override
  String get deviceHeadlessAdbLocation =>
      'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION';

  @override
  String get deviceHeadlessAdbBluetooth =>
      'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN, then the same for BLUETOOTH_CONNECT';

  @override
  String get deviceHeadlessAdbBattery =>
      'This device has no screen. Grant it over adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceHeadlessAdbStorage =>
      'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE, then the same for WRITE_EXTERNAL_STORAGE';

  @override
  String get deviceHeadlessAdbButtons =>
      'This device has no screen. Switch it on over adb: adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/.HeadlessKeyService, then adb shell settings put secure accessibility_enabled 1';

  @override
  String get deviceHeadlessAdbButtonsRestart =>
      'The button service is switched on but has not started. Restart the device to start it: adb reboot';

  @override
  String get deviceHardwarePage => 'Hardware';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => 'Device model';

  @override
  String get deviceAndroidVersion => 'Android version';

  @override
  String get deviceAndroidBuild => 'Android build';

  @override
  String get deviceIpv4 => 'IPv4 address';

  @override
  String get deviceIpv6 => 'IPv6 addresses';

  @override
  String get deviceAppUptime => 'App uptime';

  @override
  String get deviceNetworkUptime => 'Network uptime';

  @override
  String get deviceCpuUsage => 'CPU usage';

  @override
  String get deviceCpuClock => 'CPU clock';

  @override
  String get deviceCpuTemp => 'CPU temperature';

  @override
  String get deviceBatteryLevel => 'Battery level';

  @override
  String get deviceBatteryTemp => 'Battery temperature';

  @override
  String get deviceScreenBrightness => 'Screen brightness';

  @override
  String get deviceScreenStatus => 'Screen status';

  @override
  String get deviceScreenSize => 'Screen size';

  @override
  String get deviceRam => 'RAM (free/total)';

  @override
  String get deviceStorage => 'Internal storage (free/total)';

  @override
  String get deviceHaUrl => 'Home Assistant URL';

  @override
  String get deviceWakeDetection => 'Wake word detection';

  @override
  String get deviceWakeStatus => 'Wake word status';

  @override
  String get deviceEngine => 'Engine';

  @override
  String get deviceWakeWords => 'Wake words';

  @override
  String get deviceStopWord => 'Stop word';

  @override
  String get deviceMotionDetection => 'Motion detection';

  @override
  String get deviceFaceDetection => 'Face detection';

  @override
  String get deviceProvider => 'Provider';

  @override
  String get deviceVersion => 'Version';

  @override
  String get deviceUserAgent => 'User agent';

  @override
  String get devicePlugged => 'plugged';

  @override
  String get deviceLowMemory => 'low';

  @override
  String get deviceRequiredPermissions => 'Required system permissions';

  @override
  String get devicePermissionIntro =>
      'Grants are given on this device, so each button opens an Android dialog or settings screen here. Some brands add their own battery or autostart manager on top, which Android cannot report.';

  @override
  String get devicePermissionIntroRemote =>
      'Grants are given on the device, so each button opens an Android dialog or settings screen there. Some brands add their own battery or autostart manager on top, which Android cannot report.';

  @override
  String get deviceMicrophone => 'Microphone';

  @override
  String get deviceMicrophoneHeld =>
      'Allows microphone usage for wake word detection, speech to text and intercom calls.';

  @override
  String get deviceBattery => 'Unrestricted battery';

  @override
  String get deviceBatteryHeld =>
      'Allows the process to run in the background without being paused or killed.';

  @override
  String get deviceCamera => 'Camera';

  @override
  String get deviceCameraHeld =>
      'Motion detection and snapshots can use the camera.';

  @override
  String get deviceBluetooth => 'Nearby devices';

  @override
  String get deviceBluetoothHeld =>
      'The Bluetooth proxy can scan for nearby devices.';

  @override
  String get deviceNotifications => 'Notifications';

  @override
  String get deviceNotificationsHeld =>
      'Allows the Kiosk Satellite Service\'s ongoing notification, which says what it is keeping alive.';

  @override
  String get deviceOverlay => 'Display over other apps';

  @override
  String get deviceOverlayHeld =>
      'Kiosk Satellite can bring itself back in the foreground.';

  @override
  String get deviceWriteSettings => 'Modify system settings';

  @override
  String get deviceWriteSettingsHeld =>
      'Brightness changes set the panel\'s real brightness.';

  @override
  String get deviceUiGuard => 'System UI guard';

  @override
  String get deviceUiGuardHeld =>
      'The notification shade and recents close on their own while the screen is protected.';

  @override
  String get deviceDeviceAdmin => 'Device admin';

  @override
  String get deviceDeviceAdminHeld => 'Allows the app to turn the screen off.';

  @override
  String get deviceAllFiles => 'All files access';

  @override
  String get deviceAllFilesHeld =>
      'The File Manager can browse the shared storage.';

  @override
  String get deviceUsageAccess => 'Usage access';

  @override
  String get deviceUsageAccessHeld =>
      'The Foreground app sensor can name whichever app is on screen.';

  @override
  String get deviceLocation => 'Location';

  @override
  String get deviceLocationHeld =>
      'Pages, Bluetooth scanning and the location sensors can use the device position.';

  @override
  String get deviceMicBlocked =>
      'Blocked. Android will not ask again, so allow it in the app settings.';

  @override
  String get deviceMicMissing =>
      'Wake word detection is on and nothing is listening.';

  @override
  String get deviceMicIdle =>
      'Needed by wake word detection, the intercom and pages that ask for the microphone.';

  @override
  String get deviceBatteryMissing =>
      'Android may pause the app when the screen is off, dropping the Home Assistant connection and the ESPHome entities with it.';

  @override
  String get deviceCameraMissing =>
      'The camera is switched on and cannot be opened.';

  @override
  String get deviceCameraIdle =>
      'Needed by motion detection, camera snapshots and pages that ask for the camera.';

  @override
  String get deviceBluetoothMissing =>
      'The Bluetooth proxy is switched on and cannot scan.';

  @override
  String get deviceBluetoothLocation =>
      'Bluetooth scanning needs the Location permission.';

  @override
  String get deviceBluetoothLocationOff =>
      'Location is off in the device settings, so Bluetooth scanning finds nothing.';

  @override
  String get deviceBluetoothIdle =>
      'Needed by the Bluetooth proxy to scan for devices.';

  @override
  String get deviceNotificationMissing =>
      'Needed to show the Kiosk Satellite Service\'s ongoing notification.';

  @override
  String get deviceOverlayMissing =>
      'Without this the app cannot reopen itself after a crash, an update or a wake word heard behind another app.';

  @override
  String get deviceOverlayIdle =>
      'Lets the app bring itself back to the front, and the lockdown shield cover the whole screen.';

  @override
  String get deviceBrightnessMissing =>
      'Brightness only dims the app window, so the panel and Home Assistant never see the change.';

  @override
  String get deviceBrightnessIdle =>
      'Needed to set the panel\'s real brightness rather than dimming the app window.';

  @override
  String get deviceGuardMissing =>
      'The notification shade and recents stay reachable. Enable Kiosk Satellite under Accessibility.';

  @override
  String get deviceGuardIdle =>
      'Closes the notification shade and recents while kiosk mode protects the screen.';

  @override
  String get deviceAdminIdle =>
      'Lets Screen off power the panel down instead of only blacking it out.';

  @override
  String get deviceFilesIdle =>
      'Lets the File Manager browse the shared storage instead of only the app folder.';

  @override
  String get deviceUsageIdle =>
      'Lets the Foreground app sensor name apps other than Kiosk Satellite.';

  @override
  String get deviceLocationMissing =>
      'Android will not deliver Bluetooth scan results without Location, and the location sensors cannot read the GPS receiver.';

  @override
  String get deviceLocationIdle =>
      'Used by pages that ask for your location, by Bluetooth scanning and by the ESPHome location sensors.';

  @override
  String get deviceServiceOverlayMissing =>
      'Without this the service cannot relaunch the kiosk after a crash or a close from recents.';

  @override
  String get deviceServiceOverlayIdle =>
      'Needed to relaunch the kiosk after a crash.';

  @override
  String get deviceListeningMissing =>
      'Background listening is on and nothing is listening.';

  @override
  String get deviceListeningIdle => 'Needed by background listening.';

  @override
  String get deviceMotionIdle => 'Needed by motion detection.';

  @override
  String get deviceBatteryAdb =>
      'This device has no settings screen for it. Grant it over adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      'This device has no settings screen for it. Grant it over adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get deviceNotificationAccess => 'Notification access';

  @override
  String get deviceNotificationAccessHeld =>
      'Now Playing can follow the apps playing on this device.';

  @override
  String get deviceNotificationAccessMissing =>
      'Without this Android lists no media sessions, so Now Playing cannot follow the apps playing on this device.';

  @override
  String get deviceNotificationAccessIdle =>
      'Lets Now Playing follow the apps playing on this device.';

  @override
  String get settingRemoteEnabledTitle => 'Remote management';

  @override
  String get settingRemoteEnabledDescription =>
      'Run the embedded admin web server.';

  @override
  String get settingRemotePortTitle => 'Server port';

  @override
  String get settingRemotePortDescription =>
      'Port for the remote admin interface.';

  @override
  String get settingRemotePasswordTitle => 'Admin password';

  @override
  String get settingRemotePasswordDescription =>
      'Required to log in to the remote interface.';

  @override
  String get settingRemoteFleetDiscoveryTitle => 'Find other kiosks';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      'Announce this device on the network and list the other kiosks in the remote admin, to switch between them.';

  @override
  String get settingRemoteAdminUrlTitle => 'Admin URL';

  @override
  String get settingRemoteAdminUrlDescription =>
      'Address other kiosks open in Switch kiosk to reach this one, such as a reverse proxy name. Leave blank to use its network address.';

  @override
  String get deviceAdminUrlInvalid =>
      'Enter a valid address, for example https://kiosk.example.com';

  @override
  String get deviceAdminUrlPath =>
      'Enter only the address, without a path. Example: https://kiosk.example.com';

  @override
  String get deviceRemotePage => 'Remote Administration';

  @override
  String get deviceAdminAddress => 'Admin address';

  @override
  String get deviceAdminAddressHelp =>
      'Open this address in a browser on your computer.';

  @override
  String get deviceByName => 'By name';

  @override
  String get deviceByNameHelp =>
      'The same address by hostname, on networks that resolve .local names.';

  @override
  String get deviceByCertificateNameHelp =>
      'The same address by the name on its certificate.';

  @override
  String get devicePasswordNeeded =>
      'Set an admin password below to start the server.';

  @override
  String get deviceServerStopped => 'The server is not running.';

  @override
  String devicePortError(String port, String error) {
    return 'Could not listen on port $port: $error';
  }

  @override
  String get settingRemoteTlsTitle => 'Use HTTPS';

  @override
  String get settingRemoteTlsDescription =>
      'Encrypt the remote admin, API and WebSocket. Your browser may ask you to accept the device certificate.';

  @override
  String get settingServiceCpuAwakeTitle =>
      'Keep the CPU awake while the screen is off';

  @override
  String get settingServiceCpuAwakeDescription =>
      'Holds a wake lock through dark spells so connections and timers keep running on time. Costs battery on an unplugged tablet.';

  @override
  String get deviceServicePage => 'Kiosk Satellite Service';

  @override
  String get deviceKeepingRunning => 'Keeping it running';

  @override
  String get deviceService => 'Service';

  @override
  String get deviceStopped => 'Stopped';

  @override
  String get deviceStoppedSentence => 'Stopped.';

  @override
  String get deviceRunning => 'Running';

  @override
  String get deviceRunningSentence => 'Running.';

  @override
  String get deviceRunningBackground =>
      'Running without the foreground exemption.';

  @override
  String get deviceServiceTypes => 'Foreground service types';

  @override
  String get deviceServiceTypesHelp =>
      'What the service declares to Android for the features it holds up.';

  @override
  String get deviceNoneDeclared => 'None declared.';

  @override
  String get deviceNone => 'none';

  @override
  String get deviceCpuLock => 'CPU wake lock';

  @override
  String get deviceCpuOff => 'Off: the setting below is off.';

  @override
  String get deviceCpuHeld => 'Held: the screen is off.';

  @override
  String get deviceCpuReleased => 'Released while the screen is on.';

  @override
  String get deviceNotHeld => 'Not held.';

  @override
  String get deviceHeld => 'Held';

  @override
  String get deviceReleased => 'Released';

  @override
  String get deviceWifiLock => 'Wi-Fi lock';

  @override
  String get deviceWifiHeld => 'Held: the radio stays out of power saving.';

  @override
  String get deviceWifiHelp =>
      'Keeps the radio out of power saving through screen-off.';

  @override
  String get deviceNotification => 'Notification';

  @override
  String get deviceNotificationHidden =>
      'Hidden: notifications are turned off for the app. The service runs regardless.';

  @override
  String get deviceNotificationShown =>
      'Shown in the notification shade while the service runs.';

  @override
  String get deviceHidden => 'Hidden';

  @override
  String get deviceShown => 'Shown';

  @override
  String get deviceReasonHa => 'Home Assistant connection';

  @override
  String get deviceReasonHaHelp =>
      'Keeps the dashboard session and its websocket open while the screen is off.';

  @override
  String get deviceReasonListening => 'Background listening';

  @override
  String get deviceReasonListeningHelp =>
      'Keeps the wake word engine and its microphone running behind other apps.';

  @override
  String get deviceReasonRtsp => 'RTSP microphone audio';

  @override
  String get deviceReasonRtspHelp =>
      'Keeps microphone streaming available to connected RTSP viewers.';

  @override
  String get deviceReasonEspHome => 'ESPHome server';

  @override
  String get deviceReasonEspHomeHelp =>
      'Keeps the ESPHome API server answering Home Assistant.';

  @override
  String get deviceReasonRemote => 'Remote administration';

  @override
  String get deviceReasonRemoteHelp => 'Keeps the admin web server answering.';

  @override
  String get deviceReasonProtections => 'Kiosk protections';

  @override
  String get deviceReasonProtectionsHelp =>
      'Relaunches the kiosk when it is closed from recents or crashes.';

  @override
  String get deviceReasonBluetooth => 'Bluetooth proxy';

  @override
  String get deviceReasonBluetoothHelp =>
      'Keeps Bluetooth scanning running while the app is not on screen.';

  @override
  String get deviceReasonLocation => 'Location sensors';

  @override
  String get deviceReasonLocationHelp =>
      'Keeps GPS fixes arriving while the screen is off or another app is in front.';

  @override
  String get deviceReasonPerson => 'Person detection';

  @override
  String get deviceReasonPersonHelp =>
      'Keeps reading the device\'s person sensor while another app is in front.';

  @override
  String get deviceReasonCameraHelp =>
      'Keeps the camera usable after the panel powers off, for motion and face detection.';

  @override
  String deviceServiceStopped(String error) {
    return 'Stopped: $error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return 'Running for $uptime.';
  }

  @override
  String get settingShizukuInstallUpdatesTitle =>
      'Install updates through Shizuku';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      'Install Kiosk Satellite updates without on-device confirmation. Shizuku must be running and authorized.';

  @override
  String get deviceShizukuAccess => 'Shizuku access';

  @override
  String get deviceShizukuCheck => 'Checking availability';

  @override
  String get deviceShizukuRoot => 'Connected with root access';

  @override
  String get deviceShizukuShell => 'Connected with shell access';

  @override
  String get deviceShizukuGrant =>
      'Tap to grant access. Approve the request on this kiosk.';

  @override
  String get deviceShizukuGrantRemote =>
      'Grant access and approve the request on this kiosk.';

  @override
  String get deviceShizukuDenied => 'Allow Kiosk Satellite in the Shizuku app.';

  @override
  String get deviceShizukuUnsupported => 'Shizuku 13 or later is required.';

  @override
  String get deviceShizukuStart => 'Start Shizuku on this device.';

  @override
  String get deviceShizukuTest => 'Test connection';

  @override
  String get deviceShizukuTestHelp =>
      'Read the process identity without changing the device.';

  @override
  String get deviceShizukuTestTitle => 'Connection test';

  @override
  String get deviceShizukuTestFailed =>
      'Shizuku could not complete the connection test.';

  @override
  String get deviceShizukuAlreadyGranted =>
      'All permissions are already granted.';

  @override
  String get deviceShizukuConfirmed =>
      'Android confirmed the requested permissions.';

  @override
  String get deviceShizukuResults => 'Permission results';

  @override
  String get deviceShizukuGrantAll => 'Grant all permissions';

  @override
  String get deviceShizukuGrantAllHelp =>
      'Grant all permissions used by KS, including features that are currently off.';

  @override
  String get deviceShizukuSetup => 'Set up Shizuku';

  @override
  String get deviceShizukuSetupHelp =>
      'Read installation and startup instructions.';

  @override
  String get deviceShizukuLifetime =>
      'Shizuku started through ADB must be started again after a device reboot. Shell access does not provide root permissions.';

  @override
  String get deviceShizukuFailed => 'Shizuku request failed';

  @override
  String get deviceShizukuApprove => 'Approve the request on the kiosk.';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku successfully ran a command with $access access.';
  }

  @override
  String get shizukuPermissionUnconfirmed =>
      'Android has not confirmed this permission. Check Permissions Manager on the device.';

  @override
  String get shizukuPermissionReadFailed =>
      'Could not read current permissions. Try again.';

  @override
  String get shizukuRestartTimedOut => 'The restart command timed out';

  @override
  String get shizukuRestartRefused => 'Android refused the restart';

  @override
  String get shizukuCommandTimedOut => 'Command timed out';

  @override
  String get shizukuRequestRejected => 'Android rejected the request';

  @override
  String get deviceDisconnectedError => 'Device disconnected';

  @override
  String get deviceResponseTimedOut => 'Device response timed out';

  @override
  String get deviceRequestAborted => 'Request aborted';

  @override
  String get shizukuActionBusy => 'A Shizuku device action is already running';

  @override
  String get shizukuGrantFirst => 'Grant Shizuku access first';

  @override
  String get shizukuNoResponse => 'Shizuku command did not respond';

  @override
  String get shizukuCommandFailed => 'Shizuku command failed';

  @override
  String get shizukuStartRequired =>
      'Start Shizuku 13 or later and allow Kiosk Satellite in Shizuku';

  @override
  String get shizukuConnectionFailed => 'Shizuku connection failed';

  @override
  String get shizukuHelperNotConnected => 'Shizuku helper did not connect';

  @override
  String get shizukuHelperUnavailable => 'Shizuku helper is unavailable';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates =>
      'Connection encryption and certificates';

  @override
  String get tlsCertificateType => 'Certificate type';

  @override
  String get tlsImported => 'Imported';

  @override
  String get tlsSelfSigned => 'Self-signed';

  @override
  String get tlsExpires => 'Expires';

  @override
  String get tlsSHA256Fingerprint => 'SHA-256 fingerprint';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      'Certificate expired. Renew or import a replacement.';

  @override
  String get tlsCopyPublicCertificate => 'Copy public certificate';

  @override
  String get tlsDownloadPublicCertificate => 'Download public certificate';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      'Use this certificate in browsers and streaming clients.';

  @override
  String get tlsRenewCertificate => 'Renew certificate';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      'Keep the current private key and update the certificate dates.';

  @override
  String get tlsImportCertificate => 'Import certificate';

  @override
  String get tlsUseACertificateIssuedForThisDevice =>
      'Use a certificate issued for this device.';

  @override
  String get tlsReplaceCertificate => 'Replace certificate';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      'Generate a new private key and self-signed certificate.';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      'Generate a new private key and certificate? Active encrypted connections will close. Browsers may ask you to accept the new certificate.';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      'Paste the PEM certificate chain and its unencrypted private key. They are validated before replacing the current certificate.';

  @override
  String get tlsCertificateChainPEM => 'Certificate chain (PEM)';

  @override
  String get tlsPrivateKeyPEM => 'Private key (PEM)';

  @override
  String get tlsThisFieldIsRequired => 'This field is required.';

  @override
  String get tlsReplace => 'Replace';

  @override
  String get tlsRenew => 'Renew';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      'Enable HTTPS before importing a private key remotely.';

  @override
  String get tlsCertificateOperationFailed => 'Certificate operation failed.';

  @override
  String get tlsChangeConnectionProtocol => 'Change connection protocol';

  @override
  String get tlsConnectionProtocolHelp =>
      'The current remote connection will close. Reconnect using the address below. You may need to sign in again.';

  @override
  String get tlsConfirm => 'Confirm';

  @override
  String get tlsCertificateManagement => 'Certificate Management';

  @override
  String get tlsServerCertificateRequired =>
      'Use a server certificate, not a CA certificate.';

  @override
  String get tlsServerAuthenticationRequired =>
      'Certificate does not allow server authentication.';

  @override
  String get tlsKeyAlgorithmRequired => 'Use an EC or RSA private key.';

  @override
  String get tlsKeyMismatch => 'Certificate and private key do not match.';

  @override
  String get tlsMaterialTooLarge => 'Certificate or key is too large.';

  @override
  String get tlsPemCertificatesRequired => 'Expected PEM certificates.';

  @override
  String get tlsCertificateMissing => 'No certificate found.';

  @override
  String get tlsUnencryptedKeyRequired => 'Use an unencrypted PEM private key.';

  @override
  String get tlsHostnameRequired => 'A hostname or IP address is required.';

  @override
  String get tlsIssuerRenewalRequired =>
      'Import a renewed certificate from its issuer.';

  @override
  String get tlsStoredIdentityDamaged => 'Stored TLS identity is damaged.';

  @override
  String get tlsExpiredCertificate =>
      'The TLS certificate has expired. Renew or import its replacement.';

  @override
  String get deviceHelperPage => 'Optional update helper';

  @override
  String get deviceHelperStatus => 'Helper status';

  @override
  String get deviceHelperError => 'Could not check the update helper.';

  @override
  String get deviceHelperUnneeded =>
      'Android can now install updates silently. The helper is not needed.';

  @override
  String get deviceHelperIntro =>
      'This device currently needs confirmation on the screen to install updates through Android. The optional helper lets Kiosk Satellite install updates without a tap.';

  @override
  String get deviceHelperBusy => 'Installing an update.';

  @override
  String get deviceHelperReady =>
      'Ready. Updates install without confirmation.';

  @override
  String get deviceHelperUnavailable =>
      'Unavailable. Start the helper through ADB to enable updates without confirmation.';

  @override
  String get deviceHelperLifetime =>
      'The helper survives app restarts and updates but stops after a device reboot. Run the command from a computer with ADB to start it again. The computer can then disconnect.';

  @override
  String get deviceHelperStart => 'Start through ADB';

  @override
  String get deviceHelperGuide => 'Setup guide';

  @override
  String get deviceHelperGuideHelp =>
      'Read the update helper instructions and requirements.';

  @override
  String get settingUpdateSourceTitle => 'Update source';

  @override
  String get settingUpdateSourceDescription =>
      'Where the app looks for new releases.';

  @override
  String get settingUpdateSourceUrlTitle => 'Repository URL';

  @override
  String get settingUpdateSourceUrlDescription =>
      'A folder on a web server the kiosk can reach, holding releases.json and the release APKs.';

  @override
  String get deviceUpdatesPage => 'Updates';

  @override
  String get deviceUpdateGithub => 'GitHub Repository';

  @override
  String get deviceUpdateCustom => 'Custom Repository';

  @override
  String get deviceUpdateGuide => 'Custom repository guide';

  @override
  String get deviceUpdateGuideHelp =>
      'How to host the releases file and the APKs on your own network.';

  @override
  String get deviceInstallFile => 'Install from file';

  @override
  String get deviceInstallFileHelp =>
      'Upload a Kiosk Satellite APK from a computer through the remote admin, on this same page. For a kiosk that cannot reach GitHub or a custom repository.';

  @override
  String get deviceInstallFileRemoteHelp =>
      'Upload a Kiosk Satellite APK from this computer and install it. For a kiosk that cannot reach GitHub or a custom repository.';

  @override
  String get deviceUploadedApk => 'Uploaded APK';

  @override
  String get deviceInstalling => 'Installing…';

  @override
  String get deviceDeviceNoAnswer => 'The device did not answer.';

  @override
  String get deviceInstallFailed => 'Update failed. Check the device logs.';

  @override
  String get deviceConfirmTablet => 'Confirm on the tablet screen';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return 'Version $version (build $build, $size MB) is on the device, waiting to be installed.';
  }

  @override
  String deviceInstallVersion(String version) {
    return 'Install version $version';
  }

  @override
  String deviceHttpError(String code) {
    return 'The device answered HTTP $code.';
  }

  @override
  String get deviceUploadFailed => 'The upload failed.';

  @override
  String get deviceInstallFleet => 'Install on the fleet';

  @override
  String get deviceSendingFleet => 'Sending to the fleet…';

  @override
  String get deviceSameBuild => 'The kiosk already runs this build.';

  @override
  String get deviceInstallConfirmation =>
      'The install must be confirmed on the tablet screen unless the kiosk installs silently.';

  @override
  String get deviceSelfLast => 'This kiosk installs last.';

  @override
  String get deviceUpdatingFleet => 'Updating the fleet';

  @override
  String deviceUploading(String percent) {
    return 'Uploading… $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return 'The uploaded APK is version $version (build $build, $size MB).';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'The kiosk runs $version (build $build).';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return 'Sending to $name… $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return 'Installing on $name…';
  }

  @override
  String deviceInstallingNames(String names) {
    return '$names installing.';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      'Enter the folder URL, for example http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      'Enter only the folder URL, without anything after the path. Example: http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy =>
      'A download is running. Wait for it to finish.';

  @override
  String get updateInstallBusy =>
      'An install is running. Wait for it to finish.';

  @override
  String get updateNoAvailable => 'No update is available.';

  @override
  String get updateNoUploaded => 'No uploaded APK is waiting.';

  @override
  String get updateUploadEmpty => 'The upload was empty.';

  @override
  String get updateInvalidApk => 'The file is not an Android APK.';

  @override
  String get updateUploadedGone => 'The uploaded APK is gone. Upload it again.';

  @override
  String get updateShizukuInstallerFailed =>
      'Shizuku could not install the update. No confirmation installer was opened.';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return 'Not enough free space: the APK is $size MB and the install needs about $required MB, but the device has $free MB free.';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return 'The upload was interrupted after $size MB: $error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return 'The upload ended early: $received of $expected MB arrived.';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return 'The APK is $package, not Kiosk Satellite ($expected).';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'The APK is version $version (build $build), older than the running $currentVersion (build $currentBuild). Downgrades are refused: Android would not install one either.';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return 'Download failed (HTTP $status).';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return 'The download stalled: no data arrived for $seconds seconds.';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return 'Update failed: $error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return 'Install failed: $error';
  }

  @override
  String get updateAnotherPackage => 'another package';

  @override
  String get deviceKioskSatelliteUpdates => 'Kiosk Satellite Updates';

  @override
  String get deviceAndroidSystemUpdates => 'Android System Updates';

  @override
  String get settingAndroidUpdatePolicyTitle => 'Install Android updates';

  @override
  String get settingAndroidUpdatePolicyDescription =>
      'Updates to Android itself from the device maker, such as Google or Samsung. Kiosk mode hides the prompt to restart and install them.';

  @override
  String get deviceAndroidUpdateAsk => 'Ask on the device';

  @override
  String get deviceAndroidUpdateAutomatic => 'Right away';

  @override
  String get deviceAndroidUpdateWindowed => 'In a time window';

  @override
  String get settingAndroidUpdateWindowStartTitle => 'Install from';

  @override
  String get settingAndroidUpdateWindowStartDescription =>
      'Local time the daily window for installing and restarting opens.';

  @override
  String get settingAndroidUpdateWindowEndTitle => 'Install until';

  @override
  String get settingAndroidUpdateWindowEndDescription =>
      'Local time the window closes. A window past midnight ends the next day.';

  @override
  String get settingUiLanguageTitle => 'Language';

  @override
  String get settingUiLanguageDescription =>
      'Language for Kiosk Satellite and remote administration. Home Assistant keeps its own language.';

  @override
  String get settingUiThemeTitle => 'App theme';

  @override
  String get settingUiThemeDescription =>
      'Light or dark for the app\'s own screens: menu, settings, dialogs. System follows the Android setting.';

  @override
  String get settingUiScaleTitle => 'Scale UI';

  @override
  String get settingUiScaleDescription =>
      'Size of the app\'s own screens: menu, settings, dialogs. For high density displays. Web content keeps its size.';

  @override
  String get deviceUserInterface => 'User Interface';

  @override
  String get deviceThemeDark => 'Dark';

  @override
  String get deviceThemeLight => 'Light';

  @override
  String get deviceThemeSystem => 'System';

  @override
  String get settingUiToastsHiddenTitle => 'Show system toast notifications';

  @override
  String get settingUiToastsHiddenDescription =>
      'Choose the pop-up messages shown over the dashboard. Messages in Settings always show.';

  @override
  String get deviceToastsAll => 'All';

  @override
  String get deviceToastsNone => 'None';

  @override
  String get deviceToastBack => 'Back button hints';

  @override
  String get deviceToastGestures => 'Gesture actions';

  @override
  String get deviceToastHoldMode => 'Hold mode';

  @override
  String get deviceToastLinks => 'Dashboard links';

  @override
  String get deviceToastDownloads => 'Downloads';

  @override
  String get deviceToastNetwork => 'Network status';

  @override
  String get deviceToastUpdates => 'Update checks';

  @override
  String get deviceToastVoice => 'Voice Satellite notices';

  @override
  String get deviceToastTimers => 'Timers';

  @override
  String get deviceToastAlarms => 'Alarms';

  @override
  String get deviceToastMusicLibrary => 'Music Library';

  @override
  String get deviceToastIntercom => 'Intercom';

  @override
  String get deviceToastAppLauncher => 'App Launcher';

  @override
  String get deviceToastPlugins => 'Plugin actions';

  @override
  String get settingUiDrawerItemsTitle => 'Drawer menu items';

  @override
  String get settingUiDrawerItemsDescription =>
      'Choose the items the drawer menu shows and their order.';

  @override
  String get settingShowInKioskMenuTitle => 'Show in the kiosk menu';

  @override
  String get settingDlnaEnabledTitle => 'Enable DLNA renderer';

  @override
  String get settingDlnaEnabledDescription =>
      'Show images and play media pushed from Home Assistant or any DLNA app. The device appears as a media player named after the device name.';

  @override
  String get settingDlnaAudioBackgroundTitle => 'Keep audio in the background';

  @override
  String get settingDlnaAudioBackgroundDescription =>
      'Pushed audio plays without taking over the screen.';

  @override
  String get settingDlnaPortTitle => 'Server port';

  @override
  String get settingDlnaPortDescription =>
      'The port the renderer is on, filled in when it starts. Change it to move the renderer, or clear it to let it pick again.';

  @override
  String get settingDlnaPortPlaceholder => 'Set when the renderer starts';

  @override
  String get settingEsphomeRealMacTitle => 'Use real Wi-Fi MAC address';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant links this kiosk with the same device your network integrations already track. Changing this creates a new ESPHome device in Home Assistant.';

  @override
  String get settingEsphomeMacOverrideTitle => 'Spoof Wi-Fi MAC address';

  @override
  String get settingEsphomeMacOverrideDescription =>
      'Since the MAC address cannot be resolved, you can use this field to enter your own. Changing this creates a new ESPHome device in Home Assistant.';

  @override
  String get esphomeAdvanced => 'Advanced settings';

  @override
  String get esphomeAdvancedHelp => 'Real or spoofed Wi-Fi MAC address';

  @override
  String get esphomeMacInvalid => 'Enter a valid MAC address.';

  @override
  String esphomeMacHardware(String mac) {
    return 'Reporting $mac.';
  }

  @override
  String esphomeMacManual(String mac) {
    return 'Reporting $mac, entered below.';
  }

  @override
  String get esphomeMacUnavailable =>
      'Android will not reveal this device\'s hardware address.';

  @override
  String get settingAnnouncementsEnabledTitle => 'Enable announcements';

  @override
  String get settingAnnouncementsEnabledDescription =>
      'Play the announcements Home Assistant sends with the announce action.';

  @override
  String get esphomeTtsSection => 'Text to Speech';

  @override
  String get settingAnnouncementsTtsEngineTitle => 'Text to speech engine';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'The Home Assistant text to speech entity that speaks announcements.';

  @override
  String get settingAnnouncementsTtsLanguageTitle => 'Language';

  @override
  String get settingAnnouncementsTtsLanguageDescription =>
      'The language announcements are spoken in.';

  @override
  String get settingAnnouncementsTtsVoiceTitle => 'Voice';

  @override
  String get settingAnnouncementsTtsVoiceDescription =>
      'The voice that speaks announcements.';

  @override
  String get esphomeTtsFirst => 'First available';

  @override
  String get esphomeTtsDefault => 'Default';

  @override
  String get settingAnnouncementsChimeTitle => 'Chime first';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Play a chime before the announcement.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Chime sound';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Plays as loud as the announcement.';

  @override
  String get esphomeAnnouncements => 'Announcements';

  @override
  String get esphomeAnnouncementsHelp =>
      'Spoken announcements from Home Assistant';

  @override
  String get esphomeChime => 'Chime';

  @override
  String get esphomeTtsUnavailable => 'Could not reach Home Assistant';

  @override
  String get esphomeTtsNoVoices => 'No voices to pick';

  @override
  String get settingBtproxyEnabledTitle => 'Enable Bluetooth proxy';

  @override
  String get settingBtproxyEnabledDescription =>
      'Relay nearby Bluetooth devices to Home Assistant.';

  @override
  String get settingBtproxyScanDutyTitle => 'Scan intensity';

  @override
  String get settingBtproxyScanDutyDescription =>
      'How much of the time the radio listens. Lower cuts CPU; devices that advertise rarely take longer to appear.';

  @override
  String get settingBtproxyScreenOffScanTitle =>
      'Keep scanning with the screen off';

  @override
  String get settingBtproxyScreenOffScanDescription =>
      'Turn on if the proxy stops relaying while the screen is off. Uses more CPU.';

  @override
  String get settingBtproxyConnectionsTitle => 'Allow device connections';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant can connect to Bluetooth devices through this proxy.';

  @override
  String get settingBtproxyMacLookupTitle =>
      'Look up device manufacturers online';

  @override
  String get settingBtproxyMacLookupDescription =>
      'Names unknown nearby devices by their hardware address prefix using api.macvendors.com. Only the 3-byte manufacturer prefix is sent, once per manufacturer; nothing else leaves the device.';

  @override
  String get settingBtproxyNearbySortTitle => 'Sort by';

  @override
  String get settingBtproxyNearbySortDescription =>
      'The order of the nearby devices list below.';

  @override
  String get settingBtproxyMinConnectRssiTitle =>
      'Minimum signal for connections';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      'Refuse device connections heard weaker than this, so a closer proxy takes them instead.';

  @override
  String get esphomeOptionContinuous => 'Continuous';

  @override
  String get esphomeOptionBalanced => 'Balanced';

  @override
  String get esphomeOptionLowPower => 'Low power';

  @override
  String get esphomeOptionLastSeen => 'Last seen';

  @override
  String get esphomeOptionName => 'Name';

  @override
  String get esphomeOptionMacAddress => 'MAC address';

  @override
  String get esphomeOptionSignalStrength => 'Signal strength';

  @override
  String get esphomeOptionNoLimit => 'No limit';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm (same room)';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm (edge of range)';

  @override
  String get esphomeBluetooth => 'Bluetooth Proxy';

  @override
  String get esphomeBluetoothHelp =>
      'Relay nearby Bluetooth devices to Home Assistant';

  @override
  String get esphomeBluetoothOff =>
      'Bluetooth is off. Turn it on to use the proxy.';

  @override
  String get esphomeBluetoothUnsupported =>
      'Not available on this device: it has no Bluetooth.';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      'Not available on this device: its Android build has no Bluetooth LE support.';

  @override
  String get esphomeIdentityBthome => 'BTHome sensor';

  @override
  String get esphomeIdentityXiaomi => 'Xiaomi sensor';

  @override
  String get esphomeIdentityQingping => 'Qingping sensor';

  @override
  String get esphomeIdentityGoogleNest => 'Google/Nest device';

  @override
  String get esphomeIdentityEddystone => 'Eddystone beacon';

  @override
  String get esphomeIdentityGoogleFastPair => 'Google Fast Pair device';

  @override
  String get esphomeIdentityAppleFindMy => 'Apple Find My device';

  @override
  String get esphomeIdentityExposure => 'Exposure notification (phone)';

  @override
  String get esphomeIdentityAugustYale => 'August/Yale lock';

  @override
  String get esphomeIdentityAmazon => 'Amazon device';

  @override
  String get esphomeIdentityTile => 'Tile tracker';

  @override
  String get esphomeIdentityInput => 'Input device (remote/keyboard)';

  @override
  String get esphomeIdentityHeartRate => 'Heart rate sensor';

  @override
  String get esphomeIdentityEnvironmental => 'Environmental sensor';

  @override
  String get esphomeIdentityApple => 'Apple device';

  @override
  String get esphomeIdentityWindows => 'Windows PC';

  @override
  String get esphomeIdentitySamsung => 'Samsung device';

  @override
  String get esphomeIdentityGoogle => 'Google device';

  @override
  String get esphomeIdentityUnknown => 'Unknown device';

  @override
  String esphomeIdentityVendor(String vendor) {
    return '$vendor device';
  }

  @override
  String get esphomeNearby => 'Nearby devices';

  @override
  String get esphomeNearbySearch =>
      'The Bluetooth devices this kiosk hears, with names where known.';

  @override
  String get esphomeNearbyEmpty => 'Nothing heard yet.';

  @override
  String get esphomeNearbyWaiting =>
      'Nothing heard yet. Devices appear here once the proxy is scanning.';

  @override
  String get esphomeRotating => '(rotating address)';

  @override
  String esphomeNearbyCount(String count, String total) {
    return 'Showing the first $count of $total.';
  }

  @override
  String esphomeSlots(String count) {
    return 'Up to $count devices can be connected at once through this proxy. Home Assistant routes further devices through other proxies.';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return '${count}s ago';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return '$count min ago';
  }

  @override
  String esphomeHoursAgo(String count) {
    return '$count h ago';
  }

  @override
  String get settingLocationEnabledTitle => 'Report location';

  @override
  String get settingLocationEnabledDescription =>
      'Read the GPS position and serve it to Home Assistant as latitude, longitude, accuracy, altitude and speed sensors. Turning this on or off re-registers the ESPHome device.';

  @override
  String get settingLocationIntervalTitle => 'Update interval';

  @override
  String get settingLocationIntervalDescription =>
      'Seconds between position readings.';

  @override
  String get esphomeGps => 'GPS Sensor';

  @override
  String get esphomeGpsHelp => 'Expose GPS sensor data to Home Assistant';

  @override
  String get esphomeLocationOff => 'Off.';

  @override
  String get esphomeLocationWaiting =>
      'Waiting for the first fix. A cold start under open sky can take a few minutes.';

  @override
  String get esphomeCoordinates => 'Last coordinates';

  @override
  String get esphomeLocationDenied => 'Location permission not granted.';

  @override
  String get esphomeLocationAbsent => 'No GPS receiver.';

  @override
  String esphomeLocationError(String error) {
    return 'GPS unavailable: $error';
  }

  @override
  String get esphomeLocationUnsupported =>
      'Not available on this device: it has no GPS receiver.';

  @override
  String get settingNotificationsTransparencyTitle => 'Transparency';

  @override
  String get settingNotificationsTransparencyDescription =>
      'Lets the screen behind show through the notification cards. Text and icons stay solid.';

  @override
  String get settingNotificationsBlurTitle => 'Background blur';

  @override
  String get settingNotificationsBlurDescription =>
      'Blurs what shows through a transparent notification card. Note: Blur cannot be applied over the Home Assistant dashboard surface.';

  @override
  String get settingNotificationsChimeFileTitle => 'Notification sound';

  @override
  String get settingNotificationsChimeFileDescription =>
      'Sound files are read from Android/data/me.jxl.kiosk_satellite/files/sounds on the device, also reachable from the File Manager.';

  @override
  String get settingNotificationsVolumeTitle => 'Notification volume';

  @override
  String get settingNotificationsVolumeDescription =>
      'How loud the notification sound plays, apart from the media and assistant volumes.';

  @override
  String get esphomeNotifications => 'Notifications';

  @override
  String get esphomeNotificationsHelp =>
      'Transparency, blur, notification sound, test notification';

  @override
  String get esphomeAppearance => 'Appearance';

  @override
  String get esphomeSound => 'Sound';

  @override
  String get esphomeNotificationTest => 'Test notification';

  @override
  String esphomeNotificationHelp(String action) {
    return 'Notifications are sent from Home Assistant with the $action action. Test shows one over the dashboard.';
  }

  @override
  String get esphomeNotificationBody =>
      'This is what a notification from Home Assistant looks and sounds like.';

  @override
  String get esphomeNotificationSearch =>
      'The Home Assistant action that sends notifications, and a button to show one.';

  @override
  String get esphomeLocation => 'Location';

  @override
  String get esphomeLocationSearch =>
      'The Location grant the location sensors need.';

  @override
  String get esphomeBluetoothSearch =>
      'The Nearby devices grant the Bluetooth proxy needs to scan.';

  @override
  String get esphomeLocationMissing =>
      'Without this the GPS receiver cannot be read and the location sensors stay unknown.';

  @override
  String get esphomeLocationServicesOff =>
      'Location is off in the device settings, so the receiver delivers nothing.';

  @override
  String get esphomeLocationApproximate =>
      'Only approximate location is allowed, and the GPS receiver needs precise location.';

  @override
  String get esphomeLocationGranted =>
      'The location sensors can read the GPS receiver.';

  @override
  String get esphomeBluetoothGranted =>
      'The proxy can scan for nearby Bluetooth devices.';

  @override
  String get esphomeBluetoothMissing =>
      'Without this the proxy cannot scan for devices.';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android only delivers Bluetooth scan results, beacons included, with Location granted. The proxy never reads the device position.';

  @override
  String get esphomeBluetoothLocationOff =>
      'Location is off in the device settings, so Bluetooth scanning finds nothing.';

  @override
  String get esphomeBluetoothBeacons => 'Bluetooth scanning can hear beacons.';

  @override
  String get esphomeSent => 'Sent';

  @override
  String get esphomeNotsaved => 'Not saved';

  @override
  String get settingEsphomeEnabledTitle => 'Enable ESPHome';

  @override
  String get settingEsphomeEnabledDescription =>
      'Serve this kiosk to Home Assistant as an ESPHome device: its sensors and controls as native entities. Discovered automatically.';

  @override
  String get settingEsphomeEntitiesTitle => 'Expose kiosk entities';

  @override
  String get settingEsphomeEntitiesDescription =>
      'Serve the sensors and controls of this device as ESPHome entities.';

  @override
  String get settingEsphomeExcludedEntitiesTitle => 'Excluded entities';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      'Pick entities to exclude from Home Assistant. All other available entities are exposed. Saving reconnects ESPHome.';

  @override
  String get settingEsphomeNodeNameTitle => 'Node name';

  @override
  String get settingEsphomeNodeNameDescription =>
      'Names this kiosk on the network, and Home Assistant builds its action names from it. Renaming it renames those actions.';

  @override
  String get settingEsphomeNodeNamePlaceholder => 'Set on first start';

  @override
  String get settingBtproxyKeyTitle => 'Encryption key';

  @override
  String get settingBtproxyKeyDescription =>
      'Paste this key into Home Assistant when it asks for the encryption key. Generated automatically on first start.';

  @override
  String get settingBtproxyKeyPlaceholder => 'Generated on first start';

  @override
  String get settingBtproxyPortTitle => 'API port';

  @override
  String get settingBtproxyPortDescription =>
      'The port Home Assistant connects to. Leave empty for the ESPHome standard, 6053.';

  @override
  String esphomeStartFailed(String error) {
    return 'The ESPHome server failed to start: $error';
  }

  @override
  String get esphomeExcludedInvalid => 'Choose a list of entity IDs.';

  @override
  String settingsMadeBy(String heart, String author) {
    return 'Made with $heart by $author';
  }

  @override
  String get settingsBuyCoffee => 'Buy me a coffee';

  @override
  String get settingClapStrictnessTitle => 'Clap detection';

  @override
  String get settingClapDetectionDescription =>
      'Strict needs louder, evenly spaced claps. Large room gives claps time to fade in an echoey room.';

  @override
  String get gestureStrictnessStandard => 'Standard';

  @override
  String get gestureStrictnessStrict => 'Strict';

  @override
  String get gestureStrictnessLargeRoom => 'Large room';

  @override
  String get gestureOff => 'Gestures are off';

  @override
  String get gestureOffHelp => 'Disable Gestures is on in Kiosk Mode settings.';

  @override
  String get gestureEmpty => 'No gestures configured';

  @override
  String get gestureEmptyHelp =>
      'A gesture triggers its action without any visible control.';

  @override
  String get gestureDeleteTooltip => 'Delete gesture';

  @override
  String get gestureDeleteTitle => 'Delete gesture?';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return 'Remove this gesture? Trigger: $trigger. Action: $action.';
  }

  @override
  String get gestureAdd => 'Add gesture';

  @override
  String get gestureAddHelp => 'Pick a gesture and the action it triggers.';

  @override
  String get gestureTouchHelp =>
      'Gestures are observed, not blocked: the taps also reach the dashboard, so corners and multi-finger shapes keep them from firing anything there.';

  @override
  String get gestureClapper => 'Clapper';

  @override
  String get gestureReadFailed => 'Could not read the settings.';

  @override
  String get gestureHandGestures => 'Hand Gestures';

  @override
  String get settingHandGestureHoldSecondsTitle => 'Hold duration';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      'Hold the same finger gesture for this long before its action runs. Increase this to reduce accidental triggers.';

  @override
  String get gestureHoldInstant => 'Instant';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get haCustomPages => 'Custom Pages';

  @override
  String get haCustomPagesHintDashboard =>
      'Your custom HTML pages served as a dashboard';

  @override
  String get settingHaCustomPagesSocketTitle =>
      'Share Home Assistant connection';

  @override
  String get settingHaCustomPagesSocketDescription =>
      'Custom pages talk to Home Assistant through the kiosk\'s connection, with no token in the page.';

  @override
  String get haCustomPagesAdd => 'Add page';

  @override
  String get haCustomPagesEmptyAnyServer =>
      'Add HTML pages from the Home Assistant www folder or another server to pick them like a dashboard.';

  @override
  String get haCustomPagesGuide => 'Custom page guide';

  @override
  String get haCustomPagesGuideHint =>
      'How to build a page that talks to Home Assistant.';

  @override
  String get haCustomPageAddTitle => 'Add custom page';

  @override
  String get haCustomPageEditTitle => 'Edit custom page';

  @override
  String get haCustomPageName => 'Name';

  @override
  String get haCustomPageLocation => 'Path or URL';

  @override
  String get haCustomPageLocationHint =>
      'A file in the Home Assistant www folder, such as /local/dashboard.html, or the URL of a page on another server.';

  @override
  String get haCustomPageNameMissing => 'Enter a name.';

  @override
  String get haCustomPageLocationInvalid =>
      'Enter a path under /local/ or an http or https URL.';

  @override
  String get haCustomPageDuplicate => 'Another page already uses this path.';

  @override
  String get haCustomPageNotFound => 'Home Assistant has no file at this path.';

  @override
  String get haCustomPageUrlNotFound => 'The server has no page at this URL.';

  @override
  String get haCustomPageUnreachable => 'Could not reach Home Assistant.';

  @override
  String get haCustomPageUrlUnreachable => 'Could not reach the server.';

  @override
  String haCustomPageStatus(String code) {
    return 'Home Assistant answered with HTTP $code.';
  }

  @override
  String haCustomPageUrlStatus(String code) {
    return 'The server answered with HTTP $code.';
  }

  @override
  String get settingHaHoldModeTitle => 'Hold mode';

  @override
  String get settingHaHoldModeDescription =>
      'Keep the current view on screen: the screensaver, dashboard view rotation and the return to home timer are paused until turned off.';

  @override
  String get settingHaHoldReleaseMinutesTitle => 'End hold automatically after';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      'Turns hold mode off by itself after the set time. Set to 0 to hold until turned off manually.';

  @override
  String get haHoldHint =>
      'Pin the current view, automatic release, menu entry';

  @override
  String get haNever => 'Never';

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
  String get settingDisableSuspendTitle => 'Keep connected in the background';

  @override
  String get settingDisableSuspendDescription =>
      'Turns off Home Assistant\'s \"Suspend background connections\" setting, which would otherwise drop the connection a few minutes after the screen goes off.';

  @override
  String get settingFreezeOnScreensaverTitle =>
      'Pause dashboard during screensaver';

  @override
  String get settingFreezeOnScreensaverDescription =>
      'Stops drawing the dashboard while the screensaver covers it, cutting CPU and GPU use; the connection stays live. Not for the Dim screensaver.';

  @override
  String get settingWsFilterTitle => 'Filter dashboard updates';

  @override
  String get settingWsFilterDescription =>
      'Only process updates for entities on the current view, cutting stutter on low-powered tablets. Views that cannot be resolved stay unfiltered.';

  @override
  String get settingPauseDashboardCamerasTitle =>
      'Pause HA dashboard camera streams during screensaver';

  @override
  String get settingPauseDashboardCamerasDescription =>
      'Pauses supported muted camera streams on the Home Assistant dashboard while the screensaver covers it. Streams reconnect when it closes. Does not affect the device camera or the Camera Streams feature.';

  @override
  String get haOptimizations => 'Optimizations';

  @override
  String get haOptimizationsHint =>
      'Background connection, dashboard and camera pause, update filter';

  @override
  String get haScanUnavailable =>
      'Scan details are not available for the current view.';

  @override
  String get haScanDetails => 'Dashboard scan details';

  @override
  String haWatchedTitle(String count) {
    return 'Watched entities ($count)';
  }

  @override
  String get haWatched => 'Watched entities';

  @override
  String get haEntityListUnavailable =>
      'The entity list is not available right now.';

  @override
  String haWatching(String count) {
    return 'Watching $count entities on this view.';
  }

  @override
  String get haNoUpdates => 'No updates in the last minute.';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return 'Filtered $percent% of updates in the last minute ($dropped of $total).';
  }

  @override
  String get haRawUpdates =>
      'Something on this page receives every entity update anyway, so filtering saves less here.';

  @override
  String get haAllStates =>
      'This view reads all entity states, so its updates are not filtered.';

  @override
  String get haUnknownEntities =>
      'This view\'s entities can\'t be determined, so its updates are not filtered.';

  @override
  String get haWaiting => 'Waiting for the dashboard to load…';

  @override
  String get haShowScan => 'Show scan details.';

  @override
  String haThreshold(String count) {
    return 'This view uses $count entities, which crosses the filtering threshold. Filtering is disabled.';
  }

  @override
  String get haCustomPageFilter => 'Not used on custom pages.';

  @override
  String get settingHaReturnHomeEnabledTitle => 'Return to home dashboard view';

  @override
  String get settingHaReturnHomeEnabledDescription =>
      'Go back to the dashboard configured above after a period of inactivity.';

  @override
  String get settingHaReturnHomeSecondsTitle => 'Return after (seconds)';

  @override
  String get settingHaReturnHomeSecondsDescription =>
      'Inactivity period before the kiosk goes back.';

  @override
  String get haReturnHint => 'Go back to the home view when left idle';

  @override
  String get haReturnDisabled =>
      'Turned off while Dashboard view rotation is on.';

  @override
  String get haReturnNoPath =>
      'The configured dashboard has no view path to return to.';

  @override
  String haReturnPath(String path) {
    return 'Returns to \"$path\" after the timeout.';
  }

  @override
  String get haReturnCompass =>
      'With Compass navigation, each dashboard view in the layout returns to the view picked for it after the timeout.';

  @override
  String get settingHaRotationEnabledTitle => 'Enable dashboard view rotation';

  @override
  String get settingHaRotationEnabledDescription =>
      'Cycle through the selected dashboard views in an endless loop, showing each one for the chosen number of seconds.';

  @override
  String get settingHaRotationSecondsTitle => 'Seconds per view';

  @override
  String get settingHaRotationSecondsDescription =>
      'How long each view stays on screen.';

  @override
  String get settingHaRotationPauseSecondsTitle =>
      'Pause rotation on interaction (seconds)';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      'Touching the screen pauses rotation for this long, and each touch restarts the countdown. Voice interactions pause until they end. 0 keeps rotating through touches.';

  @override
  String get settingHaRotationCrossfadeTitle => 'Fade between views';

  @override
  String get settingHaRotationCrossfadeDescription =>
      'Fade out to the background and into the next view instead of switching instantly. Moving to a different dashboard or an external page still switches instantly.';

  @override
  String get settingHaRotationFadeSecondsTitle => 'Fade duration (seconds)';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      'Combined fade-out and fade-in time. Loading the next view can add time, especially on its first visit.';

  @override
  String get haRotation => 'Dashboard View Rotation';

  @override
  String get haRotationHint => 'Cycle through views, dwell time, fade';

  @override
  String get haExternalPages => 'External pages';

  @override
  String get haFadeError => 'Choose a fade duration from 0.2 to 5 seconds.';

  @override
  String get haPauseRemoteHelp =>
      'Touch pauses rotation for this long; each touch restarts it. Voice interactions always pause until they end. 0 keeps rotating.';

  @override
  String get settingHaUrlTitle => 'Home Assistant base URL';

  @override
  String get settingHaUrlDescription =>
      'e.g. https://homeassistant.local:8123, without a dashboard path.';

  @override
  String get settingHaTokenTitle => 'Long-lived access token';

  @override
  String get settingHaTokenDescription =>
      'Created under your HA profile → Security.';

  @override
  String get settingHaAutoLoginTitle => 'Log in automatically';

  @override
  String get settingHaAutoLoginDescription =>
      'Sign in to the dashboard with the access token above instead of showing the Home Assistant login page.';

  @override
  String get haValidate => 'Validate';

  @override
  String get haValidateConnection => 'Validate connection';

  @override
  String get haChecking => 'Checking…';

  @override
  String get haConnected => 'Connected';

  @override
  String get haConnectedRemote => 'Connected.';

  @override
  String get haNotValidated =>
      'Not validated yet. The settings below unlock once the connection checks out.';

  @override
  String get haConnectFailed => 'Could not connect.';

  @override
  String get haNotConfigured => 'Home Assistant URL and token not configured';

  @override
  String get haInvalidToken => 'invalid token';

  @override
  String haUnreachable(String error) {
    return 'Could not reach Home Assistant: $error';
  }

  @override
  String get haProxy => 'Secure context proxy';

  @override
  String get haProxyHelp =>
      'Routes a plain http Home Assistant through an in-app proxy so the browser unlocks the microphone and other https-only features. Only for http URLs.';

  @override
  String get haProxyRemoteHelp =>
      'Routes a plain http Home Assistant through a proxy inside the app so the browser unlocks the microphone and other https-only features. Available only for http URLs.';

  @override
  String get haProxyNotice =>
      'This Home Assistant URL uses plain http, and browsers block the microphone and other features on http pages. Kiosk Satellite will route the dashboard through a secure proxy inside the app so everything works. You may need to sign in to Home Assistant again.';

  @override
  String get haProxyRemoteNotice =>
      'This Home Assistant URL uses plain http, and browsers block the microphone and other features on http pages. Kiosk Satellite will route the dashboard through a secure proxy inside the app so everything works. You may need to sign in to Home Assistant again on the tablet.';

  @override
  String get haDashboard => 'Dashboard';

  @override
  String get haChooseView => 'Choose a view';

  @override
  String get settingHaThemeTitle => 'Theme';

  @override
  String get settingHaThemeDescription =>
      'Light or dark for the Home Assistant dashboard, also set from the Theme entity in Home Assistant. Auto follows the settings below.';

  @override
  String get settingThemeMatchAppTitle =>
      'Sync Home Assistant themes with Kiosk Satellite';

  @override
  String get settingThemeMatchAppDescription =>
      'Automatically match your Home Assistant theme to your Kiosk Satellite interface.';

  @override
  String get settingThemeAutoTitle => 'Match theme to time of day';

  @override
  String get settingThemeAutoDescription =>
      'Switch Home Assistant between light and dark on a schedule. Keeps whatever theme is selected, flipping only its light/dark variant.';

  @override
  String get settingThemeDarkAtTitle => 'Dark theme at';

  @override
  String get settingThemeDarkAtDescription =>
      'Local time to switch to the dark theme.';

  @override
  String get settingThemeLightAtTitle => 'Light theme at';

  @override
  String get settingThemeLightAtDescription =>
      'Local time to switch back to the light theme.';

  @override
  String get settingThemeAutoAppTitle => 'Also switch the app theme';

  @override
  String get settingThemeAutoAppDescription =>
      'Flip Kiosk Satellite\'s own theme (menu, settings) together with the scheduled Home Assistant change.';

  @override
  String get haThemeHint =>
      'Match the app, or switch dark and light on a schedule';

  @override
  String get haThemeAuto => 'Auto';

  @override
  String get settingHaKioskModeTitle => 'HA kiosk mode';

  @override
  String get settingHaKioskModeDescription =>
      'Hide the Home Assistant header and sidebar. Applies immediately.';

  @override
  String get settingHaKioskHideHeaderTitle => 'Hide the header';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'Hide the dashboard toolbar and view tabs while HA kiosk mode is on. Leave off if you switch views from the header.';

  @override
  String get settingHaKioskHideSidebarTitle => 'Hide the sidebar';

  @override
  String get settingHaKioskHideSidebarDescription =>
      'Hide the navigation sidebar while HA kiosk mode is on.';

  @override
  String get settingHaDashboardCarouselTitle => 'Enable dashboard carousel';

  @override
  String get settingHaDashboardCarouselDescription =>
      'Swipe left or right on the dashboard to move between its views. Swipes on sliders, maps and scrolling cards are left alone.';

  @override
  String get settingHaCarouselOverCardsTitle =>
      'Capture swipe gestures over cards';

  @override
  String get settingHaCarouselOverCardsDescription =>
      'Switch views even when the swipe starts on a card that reacts to swipes. Sliders still work normally.';

  @override
  String get settingHaHapticsTitle => 'Enable haptics';

  @override
  String get settingHaHapticsDescription =>
      'Vibrate when buttons, switches, cards, sliders and thermostat dials are used. Requires a vibration motor.';

  @override
  String get settingHaHapticsStrengthTitle => 'Vibration strength';

  @override
  String get settingHaHapticsStrengthDescription =>
      'How strong the vibration feels.';

  @override
  String get settingHaTapSoundTitle => 'Play tap sounds';

  @override
  String get settingHaTapSoundDescription =>
      'Play the standard tap sound when buttons, switches, cards, sliders and thermostat dials are used.';

  @override
  String get settingHaTapSoundVolumeTitle => 'Tap sound volume';

  @override
  String get settingHaTapSoundVolumeDescription =>
      'How loud the tap sound plays.';

  @override
  String get haUserInterface => 'User Interface';

  @override
  String get haInterfaceHint =>
      'Kiosk mode, dashboard carousel, haptics, tap sounds';

  @override
  String get haHaptics => 'Haptics';

  @override
  String get haVibrationLight => 'Light';

  @override
  String get haVibrationMedium => 'Medium';

  @override
  String get haVibrationStrong => 'Strong';

  @override
  String get settingHomeLauncherEnabledTitle => 'Act as the home screen';

  @override
  String get settingHomeLauncherEnabledDescription =>
      'Register Kiosk Satellite as the device home screen: the kiosk starts at boot and every home press returns to it. Turns itself off and restores the previous launcher if the app fails to start repeatedly.';

  @override
  String get settingHomeKeepPinningTitle => 'Keep screen pinning';

  @override
  String get settingHomeKeepPinningDescription =>
      'Pin the screen even while Kiosk Satellite is the home screen. Blocks recents and back natively, but brings back the pinning confirmation dialog on devices without device ownership.';

  @override
  String get kioskHomeScreen => 'Home screen';

  @override
  String get kioskCheckingDevice => 'Checking the device...';

  @override
  String get kioskFireOs => 'Fire OS does not allow replacing its launcher.';

  @override
  String get kioskUnsupported =>
      'This device does not allow changing the home screen.';

  @override
  String get kioskRecovered =>
      'Turned off automatically after repeated failed starts; the previous launcher was restored. Turn the switch back on to try again.';

  @override
  String get kioskHeld =>
      'Kiosk Satellite is the home screen. The kiosk starts at boot and every home press returns to it.';

  @override
  String get kioskDisabled =>
      'Not the home screen. Turn on Act as the home screen above.';

  @override
  String get kioskWaiting =>
      'Not the current home screen yet: the device is waiting for a confirmation.';

  @override
  String get kioskOpenHomeSettings => 'Open home settings';

  @override
  String get kioskSetDefault => 'Set as default';

  @override
  String get kioskActive => 'Active';

  @override
  String get kioskNotHome => 'Not the home screen.';

  @override
  String get kioskWaitingRemote =>
      'Waiting for a confirmation on the device: the system dialog or home settings open there.';

  @override
  String get kioskSetDevice => 'Set on device';

  @override
  String get settingIntercomAnswerModeTitle => 'Answer mode';

  @override
  String get settingIntercomAnswerModeDescription =>
      'Ring asks on the screen. Answer automatically opens the call after a chime.';

  @override
  String get settingIntercomRingSecondsTitle => 'Ring for';

  @override
  String get settingIntercomRingSecondsDescription =>
      'How long a call rings before it counts as missed.';

  @override
  String get settingIntercomRingSoundTitle => 'Ring sound';

  @override
  String get settingIntercomRingSoundVolumeDescription =>
      'Plays at the ring volume.';

  @override
  String get settingIntercomRingVolumeTitle => 'Ring volume';

  @override
  String get settingIntercomRingVolumeDescription =>
      'How loud a call rings, apart from the media volume.';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => 'Accept announcements';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      'Play Announce to all from the other kiosks.';

  @override
  String get intercomOptionAnswerRing => 'Ring';

  @override
  String get intercomOptionAnswerAuto => 'Answer automatically';

  @override
  String get intercomOptionAnswerDnd => 'Do not disturb';

  @override
  String get intercomOptionAnswer15 => '15 seconds';

  @override
  String get intercomOptionAnswer30 => '30 seconds';

  @override
  String get intercomOptionAnswer45 => '45 seconds';

  @override
  String get intercomOptionAnswer60 => '60 seconds';

  @override
  String get intercomAnswerSection => 'Answer';

  @override
  String get settingIntercomEnabledTitle => 'Enable intercom';

  @override
  String get settingIntercomEnabledDescription =>
      'Call the other kiosks on this network and take their calls.';

  @override
  String get settingIntercomKeyTitle => 'Intercom key';

  @override
  String get settingIntercomKeyDescription =>
      'Kiosks with the same key can call each other. Fleet Management can sync it.';

  @override
  String get settingIntercomKeyPlaceholder =>
      'Made when the intercom is enabled';

  @override
  String get intercomNeedsAdmin => 'The intercom needs the remote admin';

  @override
  String get intercomAdminHelp =>
      'Kiosks find and reach each other through it. Turn on Remote management and Find other kiosks under Device, then come back.';

  @override
  String get intercomChangeKey => 'Change key';

  @override
  String get intercomChangeKeyHelp =>
      'Paste the key from another kiosk, or make a new one.';

  @override
  String get intercomChange => 'Change';

  @override
  String get intercomKeyWarning =>
      'Kiosks with this key can call each other. A new key cuts this kiosk off from the others until they get it too.';

  @override
  String get intercomRegenerate => 'Regenerate';

  @override
  String get intercomKeyChanged => 'Key changed';

  @override
  String get intercomNotSet => 'Not set';

  @override
  String get intercomOpen => 'Open';

  @override
  String get settingIntercomTlsTitle => 'Encrypt communications';

  @override
  String get settingIntercomTlsDescription =>
      'Use TLS to encrypt intercom calls between kiosks. All kiosks in the call need this enabled.';

  @override
  String get intercomKiosks => 'Kiosks';

  @override
  String get intercomRosterHelp =>
      'Discovered kiosks and saved fleet members. A kiosk is ready when it is reachable with intercom on, the same key and matching encryption settings.';

  @override
  String get intercomNoOther => 'No other kiosks found';

  @override
  String get intercomRosterDeviceHelp =>
      'Kiosks with Remote management and Find other kiosks on show up here.';

  @override
  String get intercomNoneHeard => 'No kiosks found';

  @override
  String get intercomRosterRemoteHelp =>
      'Kiosks appear through network discovery or saved fleet membership. Remote management and Find other kiosks must be on.';

  @override
  String get intercomReady => 'Ready';

  @override
  String get intercomOff => 'Intercom off';

  @override
  String get intercomDifferentKey => 'Different key';

  @override
  String get intercomUnreachable => 'Unreachable';

  @override
  String get intercomOffline => 'Offline';

  @override
  String get intercomChecking => 'Checking…';

  @override
  String get settingIntercomTalkModeTitle => 'Talk mode';

  @override
  String get settingIntercomTalkModeDescription =>
      'Push to talk sends while the button is held. Hands free keeps the microphone open for the whole call.';

  @override
  String get intercomOptionTalkPtt => 'Push to talk';

  @override
  String get intercomOptionTalkHandsfree => 'Hands free';

  @override
  String get settingIntercomMaxCallMinutesTitle => 'Maximum call duration';

  @override
  String get settingIntercomMaxCallMinutesDescription =>
      'Calls end on their own after this long.';

  @override
  String get intercomOptionCallUnlimited => 'Unlimited';

  @override
  String get intercomOptionCall1 => '1 minute';

  @override
  String get intercomOptionCall2 => '2 minutes';

  @override
  String get intercomOptionCall5 => '5 minutes';

  @override
  String get intercomOptionCall10 => '10 minutes';

  @override
  String get intercomOptionCall15 => '15 minutes';

  @override
  String get intercomOptionCall20 => '20 minutes';

  @override
  String get intercomOptionCall30 => '30 minutes';

  @override
  String get intercomOptionCall45 => '45 minutes';

  @override
  String get intercomOptionCall60 => '60 minutes';

  @override
  String get settingIntercomHangupKeyTitle =>
      'Hang up call when pressing this button';

  @override
  String get settingIntercomHangupKeyDescription =>
      'During a call the button ends it instead of its usual action.';

  @override
  String get intercomOptionHangupOff => 'Disabled';

  @override
  String get intercomOptionHangupVolumeUp => 'Volume up';

  @override
  String get intercomOptionHangupVolumeDown => 'Volume down';

  @override
  String get intercomOptionHangupMute => 'Mute';

  @override
  String get intercomOptionHangupHelp => 'Help';

  @override
  String get settingIntercomHangupKeyRingingTitle =>
      'Hang up button while ringing';

  @override
  String get settingIntercomHangupKeyRingingDescription =>
      'What the button does when a call rings here.';

  @override
  String get intercomOptionHangupRingingAnswer => 'Accept';

  @override
  String get intercomOptionHangupRingingDecline => 'Decline';

  @override
  String get intercomOptionHangupRingingIgnore => 'Ignore';

  @override
  String get intercomTalkSection => 'Talk';

  @override
  String get settingIntercomVideoTitle => 'Video calls';

  @override
  String get settingIntercomVideoDescription => 'Send and show video in calls.';

  @override
  String get settingIntercomVideoQualityTitle => 'Video quality';

  @override
  String get settingIntercomVideoQualityDescription =>
      'Higher quality uses more CPU.';

  @override
  String get intercomOptionVideoLow => 'Low';

  @override
  String get intercomOptionVideoMedium => 'Medium';

  @override
  String get intercomOptionVideoHigh => 'High';

  @override
  String get intercomVideoSection => 'Video';

  @override
  String get settingIntercomAutoAnswerCameraTitle => 'Answer with camera on';

  @override
  String get settingIntercomAutoAnswerCameraDescription =>
      'Video calls answered automatically open with the camera on.';

  @override
  String get settingKioskAllowDrawerTitle => 'Allow menu with quick actions';

  @override
  String get settingKioskAllowQuickControlsDescription =>
      'Shows the menu without the exit gesture or PIN, limited to the actions selected below. In Classic navigation an edge swipe opens it. In Compass it is the Quick Controls view.';

  @override
  String get settingKioskAllowDashboardTitle => 'Dashboard';

  @override
  String get settingKioskAllowDashboardDescription => 'Reload the start page.';

  @override
  String get settingKioskAllowHaKioskTitle => 'HA Kiosk Mode';

  @override
  String get settingKioskAllowHaKioskDescription =>
      'Show or hide the Home Assistant header and sidebar.';

  @override
  String get settingKioskAllowCameraTitle => 'Camera View';

  @override
  String get settingKioskAllowCameraDescription =>
      'Open the default camera view.';

  @override
  String get settingKioskAllowIntercomTitle => 'Intercom';

  @override
  String get settingKioskAllowIntercomDescription =>
      'Call other kiosks from the kiosk menu.';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription =>
      'Open the Music Assistant web interface.';

  @override
  String get settingKioskAllowSendspinPlayerTitle => 'Floating Player';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      'Show or hide the floating player and open Now Playing.';

  @override
  String get settingKioskAllowScreensaverTitle => 'Start Screensaver';

  @override
  String get settingKioskAllowScreensaverDescription =>
      'Start the screensaver now.';

  @override
  String get settingKioskAllowHoldTitle => 'Hold Mode';

  @override
  String get settingKioskAllowHoldDescription => 'Turn hold mode on or off.';

  @override
  String get settingKioskAllowLockdownTitle => 'Lockdown Mode';

  @override
  String get settingKioskAllowLockdownDescription =>
      'Lock the screen until the exit gesture or a remote unlock.';

  @override
  String get settingKioskAllowThemeTitle => 'Theme picker';

  @override
  String get settingKioskAllowThemeDescription =>
      'Switch between the light and dark themes.';

  @override
  String get settingKioskAllowAppsTitle => 'Apps';

  @override
  String get settingKioskAllowAppsDescription =>
      'Open the app launcher. With Disable home button on, launching an app unpins the kiosk until it returns.';

  @override
  String get kioskAllowedActions => 'Allowed Actions';

  @override
  String get kioskAllowedHelp => 'Which quick actions the kiosk menu offers';

  @override
  String get settingKioskAllowedAppsTitle => 'Allowed Apps';

  @override
  String get settingKioskAllowedAppsDescription =>
      'The launcher apps offered while kiosk mode is on.';

  @override
  String get kioskAllowedAppsEmpty =>
      'Add apps in Settings > App Launcher first.';

  @override
  String get settingKioskEnabledTitle => 'Enable kiosk mode';

  @override
  String get settingKioskEnabledDescription =>
      'Lock the tablet into Kiosk Satellite. The menu swipe is replaced by the exit gesture, the back button stays inside the kiosk, and the protections below arm.';

  @override
  String get settingKioskStartOnBootTitle => 'Start on boot';

  @override
  String get settingKioskStartOnBootDescription =>
      'Launch Kiosk Satellite when the device powers on. On Android 10+ this needs the display over other apps permission; Android asks on first enable.';

  @override
  String get settingKioskExitGestureTitle => 'Kiosk exit gesture';

  @override
  String get settingKioskExitGestureDescription =>
      'Fast taps anywhere open the menu, after the PIN if one is set. Hold variants need the last tap held down. When disabled, only the remote admin can reach settings.';

  @override
  String get settingKioskPinTitle => 'Kiosk mode PIN';

  @override
  String get settingKioskPinDescription =>
      'Asked after the exit gesture before the menu opens. Leave empty for no PIN.';

  @override
  String get settingKioskDisableStatusBarTitle => 'Disable status bar';

  @override
  String get settingKioskDisableStatusBarDescription =>
      'Block the status bar pull-down with a shield over the top edge. Needs the display over other apps permission; Android asks on first enable.';

  @override
  String get settingKioskDisableVolumeTitle => 'Disable volume buttons';

  @override
  String get settingKioskDisableVolumeDescription =>
      'Swallow the hardware volume keys.';

  @override
  String get settingKioskDisablePowerTitle => 'Disable power button';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android cannot block the power button, so the screen turns right back on when it is pressed. Turning the screen off remotely still works.';

  @override
  String get settingKioskDisableHomeTitle => 'Disable home button';

  @override
  String get settingKioskDisableHomeDescription =>
      'Pin the app with Android screen pinning, which blocks the home and recents buttons. Android asks to confirm the first time.';

  @override
  String get settingKioskDisableContextMenusTitle => 'Disable context menus';

  @override
  String get settingKioskDisableContextMenusDescription =>
      'Suppress long-press menus and text selection inside the web view.';

  @override
  String get settingKioskDisablePullRefreshTitle => 'Disable pull to refresh';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Ignore the pull-to-refresh gesture while kiosk mode is on.';

  @override
  String get settingKioskDisableGesturesTitle => 'Disable Gestures';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Ignore the gestures from the Gestures page while kiosk mode is on.';

  @override
  String get kioskGestureTaps5 => '5 fast taps';

  @override
  String get kioskGestureTaps7 => '7 fast taps';

  @override
  String get kioskGestureTaps5Hold => '5 fast taps, holding the last';

  @override
  String get kioskGestureTaps7Hold => '7 fast taps, holding the last';

  @override
  String get kioskGestureNone => 'Disabled (remote admin only)';

  @override
  String get kioskForeground =>
      'Kiosk Satellite can bring itself back in the foreground.';

  @override
  String get kioskOverlayMissing =>
      'Without this the kiosk cannot bring itself back and the lockdown shield only covers the app.';

  @override
  String get kioskGuardHeld =>
      'The notification shade and recents close on their own while the screen is protected.';

  @override
  String get kioskGuardMissing =>
      'Without this the notification shade and recents stay reachable. Enable Kiosk Satellite under Accessibility.';

  @override
  String get kioskOverlayRemote =>
      'Without this the kiosk cannot bring itself back. The grant screen appears on the tablet.';

  @override
  String get kioskGuardRemote =>
      'Without this the notification shade and recents stay reachable. Enable Kiosk Satellite under Accessibility on the tablet.';

  @override
  String get kioskGrantDevice => 'Grant on device';

  @override
  String get kioskOpenSettingsDevice => 'Open settings on device';

  @override
  String get settingLedEnabledTitle => 'Enable LED Control';

  @override
  String get settingLedEnabledDescription =>
      'Let Kiosk Satellite control the lights.';

  @override
  String get settingLedAnimationsTitle => 'Animate effects';

  @override
  String get settingLedAnimationsDescription =>
      'Move the arcs and fade the pulses. Turn off to make every effect static instead.';

  @override
  String get settingLedIdleEnabledTitle => 'Light up when idle';

  @override
  String get settingLedIdleEnabledDescription =>
      'Stay lit while nothing else is showing.';

  @override
  String get settingLedIdleBrightnessTitle => 'Brightness';

  @override
  String get settingLedIdleBrightnessDescription =>
      'How bright the lights shine for this.';

  @override
  String get settingLedIdleLightColorTitle => 'Color';

  @override
  String get settingLedIdleLightColorDescription =>
      'The color of the lights for this.';

  @override
  String get settingLedIdleStyleTitle => 'Effect';

  @override
  String get settingLedIdleStyleDescription =>
      'How the lights show while idle.';

  @override
  String get settingLedIdleStyleOptionSolid => 'Solid';

  @override
  String get settingLedIdleStyleOptionBreathe => 'Breathing';

  @override
  String get settingLedVoiceEnabledTitle => 'Show voice activity';

  @override
  String get settingLedVoiceEnabledDescription =>
      'Light up while Voice Satellite listens, thinks and answers.';

  @override
  String get settingLedVoiceBrightnessTitle => 'Brightness';

  @override
  String get settingLedVoiceBrightnessDescription =>
      'How bright the lights shine for this.';

  @override
  String get settingLedVoiceLightColorTitle => 'Color';

  @override
  String get settingLedVoiceLightColorDescription =>
      'Under an arc that turns while listening, alternating while thinking and fading while answering.';

  @override
  String get settingLedVoiceAccentColorTitle => 'Accent color';

  @override
  String get settingLedVoiceAccentColorDescription =>
      'The arc that moves around the lights.';

  @override
  String get settingLedVoiceMutedTitle => 'Show when muted';

  @override
  String get settingLedVoiceMutedDescription =>
      'Stay lit while Voice Satellite is muted.';

  @override
  String get settingLedVoiceMutedColorTitle => 'Muted color';

  @override
  String get settingLedVoiceMutedColorDescription =>
      'The color of the lights while muted.';

  @override
  String get settingLedTimersEnabledTitle => 'Show timers';

  @override
  String get settingLedTimersEnabledDescription => 'Pulse while a timer rings.';

  @override
  String get settingLedTimersBrightnessTitle => 'Brightness';

  @override
  String get settingLedTimersBrightnessDescription =>
      'How bright the lights shine for this.';

  @override
  String get settingLedTimersLightColorTitle => 'Color';

  @override
  String get settingLedTimersLightColorDescription =>
      'The color of the lights for this.';

  @override
  String get settingLedTimersCountdownTitle => 'Show the countdown';

  @override
  String get settingLedTimersCountdownDescription =>
      'The lights go out one by one as the next timer runs down.';

  @override
  String get settingLedAlarmsEnabledTitle => 'Show alarms';

  @override
  String get settingLedAlarmsEnabledDescription =>
      'Pulse while an alarm rings.';

  @override
  String get settingLedAlarmsBrightnessTitle => 'Brightness';

  @override
  String get settingLedAlarmsBrightnessDescription =>
      'How bright the lights shine for this.';

  @override
  String get settingLedAlarmsLightColorTitle => 'Color';

  @override
  String get settingLedAlarmsLightColorDescription =>
      'The color of the lights for this.';

  @override
  String get settingLedIntercomEnabledTitle => 'Show intercom calls';

  @override
  String get settingLedIntercomEnabledDescription =>
      'Pulse while a call rings and turn while it is live.';

  @override
  String get settingLedIntercomBrightnessTitle => 'Brightness';

  @override
  String get settingLedIntercomBrightnessDescription =>
      'How bright the lights shine for this.';

  @override
  String get settingLedIntercomLightColorTitle => 'Color';

  @override
  String get settingLedIntercomLightColorDescription =>
      'The color of the lights for this.';

  @override
  String get settingLedNotificationsEnabledTitle => 'Show notifications';

  @override
  String get settingLedNotificationsEnabledDescription =>
      'Pulse slowly while a notification is waiting.';

  @override
  String get settingLedNotificationsBrightnessTitle => 'Brightness';

  @override
  String get settingLedNotificationsBrightnessDescription =>
      'How bright the lights shine for this.';

  @override
  String get settingLedNotificationsLightColorTitle => 'Color';

  @override
  String get settingLedNotificationsLightColorDescription =>
      'The color of the lights for this.';

  @override
  String get settingLedMediaEnabledTitle => 'Show music';

  @override
  String get settingLedMediaEnabledDescription =>
      'Light up while music plays on this device.';

  @override
  String get settingLedMediaBrightnessTitle => 'Brightness';

  @override
  String get settingLedMediaBrightnessDescription =>
      'How bright the lights shine for this.';

  @override
  String get settingLedMediaLightColorTitle => 'Color';

  @override
  String get settingLedMediaLightColorDescription =>
      'The color of the lights for this.';

  @override
  String get settingLedMediaStyleTitle => 'Effect';

  @override
  String get settingLedMediaStyleDescription => 'How the lights show music.';

  @override
  String get settingLedMediaStyleOptionSolid => 'Solid';

  @override
  String get settingLedMediaStyleOptionBreathe => 'Breathing';

  @override
  String get settingLockdownEnabledTitle => 'Enable Lockdown Mode';

  @override
  String get settingLockdownEnabledDescription =>
      'Disables screen interactions until turned off either from Home Assistant or with the exit gesture.';

  @override
  String get settingLockdownAutoUnlockMinutesTitle =>
      'Unlock automatically after';

  @override
  String get settingLockdownAutoUnlockMinutesDescription =>
      'Turns Lockdown Mode off after this long when it is started from the kiosk menu. Set to 0 to stay locked.';

  @override
  String get settingLockdownBlackoutTitle => 'Blackout screen';

  @override
  String get settingLockdownBlackoutDescription =>
      'Turns the screen black while locked.';

  @override
  String get settingLockdownAllowScreensaverTitle => 'Allow screensaver';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      'Lets the screensaver run while locked. Dismiss on motion stays deactivated until the lock lifts.';

  @override
  String get settingLockdownExitGestureTitle => 'Lockdown exit gesture';

  @override
  String get settingLockdownExitGestureDescription =>
      'Fast taps anywhere turn Lockdown Mode off, after the kiosk PIN if one is set. Hold variants need the last tap held down. When disabled, only the remote admin or Home Assistant can turn it off.';

  @override
  String get lockdownGestureNone => 'Disabled (remote only)';

  @override
  String get lockdownExplanation =>
      'Lockdown Mode makes the dashboard non-interactive, arms every Kiosk Mode protection without changing your Kiosk Mode settings, and mutes wake word detection while it is on. With the System UI guard enabled (above), the notification shade and recents are blocked too. Home Assistant gets a Lockdown mode switch over ESPHome.';

  @override
  String get lockdownSearch =>
      'Remote-only touch shield. Set it up from the Remote Admin UI; its grants live under Required system permissions.';

  @override
  String get lockdownOverlayHeld =>
      'The lockdown shield can cover the whole screen.';

  @override
  String get lockdownOverlayMissing =>
      'Without this the shield only covers the app. The grant screen appears on the tablet.';

  @override
  String get lockdownPermissionsSearch =>
      'The grants the lockdown protections lean on.';

  @override
  String get settingAirplayEnabledTitle => 'Enable AirPlay receiver';

  @override
  String get settingAirplayEnabledDescription =>
      'The device shows up as an AirPlay speaker in the AirPlay menu of an iPhone, iPad or Mac.';

  @override
  String get settingAirplayNameTitle => 'Speaker name';

  @override
  String get settingAirplayNameDescription =>
      'The name in the AirPlay menu. Empty uses the device name.';

  @override
  String get settingAirplaySenderVolumeTitle => 'Follow the sender\'s volume';

  @override
  String get settingAirplaySenderVolumeDescription =>
      'The volume control on the iPhone, iPad or Mac changes how loud this device plays. Off, only this device\'s volume does.';

  @override
  String get settingAirplaySyncOffsetDescription =>
      'Negative plays this device earlier, to line the sound up with video on the sender. Applies live.';

  @override
  String get settingAirplayTakeoverTitle => 'Let another sender take over';

  @override
  String get settingAirplayTakeoverDescription =>
      'A second iPhone, iPad or Mac can take over while one plays. Off, it has to wait until the first one disconnects.';

  @override
  String get mediaAirplayHint => 'Play audio from an iPhone, iPad or Mac';

  @override
  String get mediaCacheTitle => 'Album art cache';

  @override
  String get mediaCacheReadFailed => 'Could not read cache size.';

  @override
  String get mediaCacheClearFailed => 'Could not clear the cache.';

  @override
  String get mediaCacheChecking => 'Checking cache size...';

  @override
  String get mediaCacheClearing => 'Clearing...';

  @override
  String mediaCacheUsage(String used, String limit) {
    return '$used used of $limit. Queue thumbnails are cached automatically.';
  }

  @override
  String get settingSendspinShowPlayerTitle => 'Show the floating player';

  @override
  String get settingSendspinShowPlayerDescription =>
      'While music plays, show a small now-playing window over the dashboard with artwork, track info and progress. Drag it anywhere; the position is remembered.';

  @override
  String get settingSendspinPlayerSizeTitle => 'Player size';

  @override
  String get settingSendspinPlayerSizeDescription =>
      'Compact is a small, unobtrusive now-playing window. Large adds previous, play/pause and next buttons sized for touch, controlling the whole playback group.';

  @override
  String get settingSendspinPausedHideMinutesTitle =>
      'Hide the paused player after';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      'How long a paused player stays on screen. It applies to both the floating player and the Now Playing view.';

  @override
  String get settingSendspinDismissKeepsPlayingTitle =>
      'Keep playing when dismissed';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      'Flinging the floating player away hides it without stopping the music.';

  @override
  String get mediaFloatingPage => 'Floating Player';

  @override
  String get mediaFloatingHint => 'The small card over the dashboard';

  @override
  String get mediaCompact => 'Compact';

  @override
  String get mediaLargeControls => 'Large with controls';

  @override
  String get settingSendspinPlayerSourceTitle => 'Player source';

  @override
  String get settingSendspinPlayerSourceDescription =>
      'What the floating player and Now Playing show and control: this device or a player elsewhere.';

  @override
  String get settingSendspinPlayerTitle => 'Player';

  @override
  String get settingSendspinPlayerDescription =>
      'The player of that source to show and control.';

  @override
  String get settingSendspinDuckPercentTitle =>
      'Duck volume during voice interactions';

  @override
  String get settingSendspinDuckPercentDescription =>
      'Music drops to this share of its volume during voice interactions and intercom calls, then comes back.';

  @override
  String get settingSendspinEsphomeEntitiesTitle => 'Expose ESPHome entities';

  @override
  String get settingSendspinEsphomeEntitiesDescription =>
      'Play, pause, next and previous buttons for the followed player in Home Assistant, with its state, title, artist and source as sensors.';

  @override
  String get settingSendspinVolumeKeysTitle =>
      'Volume buttons control the player';

  @override
  String get settingSendspinVolumeKeysGroupDescription =>
      'This device\'s volume buttons change the followed player\'s volume instead of its own. While this device plays in a group they change the group\'s volume. Only while the Now Playing view is on screen or whenever the player is playing.';

  @override
  String get settingSendspinVolumeKeyStepTitle => 'Volume button step';

  @override
  String get settingSendspinVolumeKeyStepDescription =>
      'How far one press of a volume button moves the player.';

  @override
  String get mediaIntro =>
      'The floating player and Now Playing show only while the picked player has a track playing or a queue loaded. With nothing playing or queued, neither appears.';

  @override
  String get mediaThisDevice => 'This device';

  @override
  String get mediaOff => 'Off';

  @override
  String get mediaKeysNowPlaying => 'While Now Playing is shown';

  @override
  String get mediaKeysPlaying => 'While the player is playing';

  @override
  String get mediaAnotherPlayer => 'another player';

  @override
  String mediaOfflineSendspin(String player) {
    return 'The Sendspin player stays offline while $player is picked.';
  }

  @override
  String mediaOfflineAirplay(String player) {
    return 'The AirPlay receiver stays off while $player is picked.';
  }

  @override
  String mediaOfflineBoth(String player) {
    return 'The Sendspin player and the AirPlay receiver stay offline while $player is picked.';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => 'Enable lyrics';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      'Synchronized lyrics on the Now Playing view, for every player source.';

  @override
  String get settingSendspinLyricsSourceTitle => 'Lyrics source';

  @override
  String get settingSendspinLyricsSourceDescription =>
      'Where the lyrics come from. Music Assistant needs the server address and token on its page.';

  @override
  String get settingSendspinLyricsFallbackTitle =>
      'Fallback to Music Assistant';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      'If LRCLIB is unreachable, Music Assistant is asked instead. Needs the Music Assistant connection.';

  @override
  String get settingSendspinLyricsOffsetTitle => 'Lyrics timing';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      'Shift the lyrics against the music. Positive shows each line earlier, negative later. Worth a nudge on tracks that read consistently off.';

  @override
  String get mediaLyricsPage => 'Lyrics';

  @override
  String get mediaLyricsHint => 'Synchronized lyrics, their source and timing';

  @override
  String get settingSendspinMaUrlTitle => 'Server address';

  @override
  String get settingSendspinMaUrlDescription =>
      'The Music Assistant server\'s address, as its web interface shows it. Usually https and port 8095.';

  @override
  String get settingSendspinMaTokenTitle => 'Auth token';

  @override
  String get settingSendspinMaTokenDescription =>
      'A long-lived token from Music Assistant (Settings, then Users). Read access is enough for lyrics; the kiosk menu shortcut opens the web interface as whoever the token belongs to.';

  @override
  String get settingSendspinMaOpenFullscreenTitle =>
      'Open directly to Now Playing';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      'Open Music Assistant\'s full-screen player from the kiosk menu or the Open Music Assistant gesture.';

  @override
  String get settingSendspinMaAutoCloseTitle => 'Close after inactivity';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Return to the dashboard when nobody has touched the Music Assistant page for this long. Zero leaves it open until it is closed.';

  @override
  String get settingSendspinMaHideCloseTitle => 'Hide the close button';

  @override
  String get settingSendspinMaHideCloseDescription =>
      'The floating close button can sit on top of Music Assistant\'s own controls, like the Now Playing menu. Without it, dismiss with the back button or by using the kiosk\'s drawer menu.';

  @override
  String get settingSendspinMaZoomDescription =>
      'Scales the whole Music Assistant page.';

  @override
  String get mediaMaHint => 'Server, token, kiosk menu shortcut';

  @override
  String get mediaKioskMenu => 'Kiosk menu';

  @override
  String get mediaValidateConnection => 'Validate connection';

  @override
  String get mediaValidate => 'Validate';

  @override
  String get mediaChecking => 'Checking…';

  @override
  String get mediaConnected => 'Connected';

  @override
  String mediaConnectedVersion(String version) {
    return 'Connected to Music Assistant $version';
  }

  @override
  String get mediaValidateHint =>
      'Check the address and token before turning on the shortcut or lyrics.';

  @override
  String get mediaDeviceNoAnswer => 'The device did not answer.';

  @override
  String get mediaValidationFailed => 'Validation failed.';

  @override
  String get mediaNoAddress => 'No server address set.';

  @override
  String get mediaNoToken => 'No auth token set.';

  @override
  String get mediaTimeout => 'Music Assistant did not answer in time.';

  @override
  String mediaUnreachable(String host, String error) {
    return 'Could not reach $host: $error';
  }

  @override
  String get mediaServerClosed => 'the server closed the connection';

  @override
  String get settingSendspinFullscreenControlsTitle => 'Show media controls';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      'Previous, play/pause and next buttons and a progress bar on the Now Playing view. With controls on, a close button dismisses it instead of a tap anywhere.';

  @override
  String get settingSendspinFullscreenTextScaleTitle => 'Text scale';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      'Size of the track title, artist, album, lyrics and queue text. Applies in both layouts and alongside the screensaver. Artwork adjusts to leave room for the text.';

  @override
  String get settingSendspinFullscreenButtonScaleTitle => 'Button scale';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      'Size of the playback buttons and progress bar, independent of text size. Applies in both layouts and alongside the screensaver. Controls fit the space available in the player.';

  @override
  String get settingSendspinFullscreenLayoutTitle => 'Layout mode';

  @override
  String get settingSendspinFullscreenLayoutDescription =>
      'How Now Playing arranges artwork, track details and controls. Horizontal splits them into left and right halves. Album art only fills the screen with artwork and shows track details and controls for a few seconds after a tap, switching to Vertical while lyrics or the queue are open. Ignored while Now Playing is shown alongside a screensaver.';

  @override
  String get mediaLayoutVertical => 'Vertical';

  @override
  String get mediaLayoutHorizontal => 'Horizontal';

  @override
  String get mediaLayoutArtOnly => 'Album art only';

  @override
  String get settingSendspinFullscreenDoubleTapTitle => 'Double tap to dismiss';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'A double tap anywhere on the Now Playing view dismisses it. The close button won\'t be shown. Ignored while Now Playing is shown alongside a screensaver.';

  @override
  String get settingSendspinFullscreenCloseButtonTitle =>
      'Always show close button';

  @override
  String get settingSendspinFullscreenCloseButtonDescription =>
      'Show the close button while Double tap to dismiss is on.';

  @override
  String get settingSendspinFullscreenOnPlayTitle =>
      'Launch Now Playing when music starts playing';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      'Open the Now Playing view as soon as playback starts instead of waiting for the screensaver timeout.';

  @override
  String get settingSendspinFullscreenMotionTitle =>
      'Dismiss \"Now Playing\" on motion';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      'Let motion dismiss Now Playing like a regular screensaver. Off, only touch dismisses it, so a walk-past does not interrupt the music display. Ignored while Now Playing is shown alongside a screensaver.';

  @override
  String get settingSendspinFullscreenReturnTitle => 'After dismissing';

  @override
  String get settingSendspinFullscreenReturnDescription =>
      'The dashboard view to show after Now Playing is dismissed. Default follows Return to home dashboard view.';

  @override
  String get mediaReturnLastView => 'Last view';

  @override
  String get mediaReturnChosenView => 'Chosen view';

  @override
  String get settingSendspinFullscreenReturnViewTitle => 'Dashboard view';

  @override
  String get settingSendspinFullscreenReturnViewDescription =>
      'The view to show after Now Playing is dismissed.';

  @override
  String get settingSendspinSpeakerPillTitle => 'Show speaker selection pill';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Shows speaker selection for 5 seconds after screen interaction. Add or remove speakers from the current group.';

  @override
  String get settingSendspinSpeakerPillPlayersTitle =>
      'Filter the speaker selection pill';

  @override
  String get settingSendspinSpeakerPillPlayersDescription =>
      'Only these speakers show in the pill. Speakers already in the group always show.';

  @override
  String get settingSendspinAudioQualityTitle => 'Show audio quality';

  @override
  String get settingSendspinAudioQualityDescription =>
      'Shows the format, bit depth, sample rate, bitrate and source of the current track at the bottom of Now Playing. Requires Music Assistant.';

  @override
  String get mediaAllSpeakers => 'All speakers';

  @override
  String get settingSendspinQueueArtTitle => 'Show album art in the queue';

  @override
  String get settingSendspinQueueArtDescription =>
      'A cover on every row of the queue panel.';

  @override
  String get mediaNowPlayingHint => 'Full-screen view while music plays';

  @override
  String get mediaInterfaceHeading => 'User Interface';

  @override
  String get settingSendspinFullscreenTitle =>
      '\"Now Playing\" instead of the screensaver';

  @override
  String get settingSendspinFullscreenDescription =>
      'While music plays, the screensaver becomes a full-screen Now Playing view with album art. With nothing playing, the regular screensaver runs.';

  @override
  String get settingSendspinFullscreenSplitTitle =>
      'Show alongside screensaver';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      'Keep the screensaver visible beside Now Playing. Portrait screens stack the screensaver above the player. Small screens keep the full-screen player.';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => 'Fill the screen';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      'Override photo filling while the screensaver shares the display with Now Playing. Default uses each screensaver\'s own setting. Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle =>
      'Override screensaver brightness';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      'Use normal screen brightness instead of screensaver brightness while Now Playing is shown alongside a screensaver. This also overrides scheduled screensaver brightness.';

  @override
  String get mediaScreensaverHeading => 'Screensaver';

  @override
  String get mediaDefaultFill => 'Default';

  @override
  String get mediaFillOff => 'Off';

  @override
  String get mediaFillSmart => 'Smart';

  @override
  String get mediaFillAlways => 'Always';

  @override
  String get mediaPickPlayer => 'Pick a player';

  @override
  String get mediaMaPlayer => 'Music Assistant player';

  @override
  String get mediaHaPlayer => 'Home Assistant media player';

  @override
  String get mediaSonosRoom => 'Sonos room';

  @override
  String get mediaSearchPlayers => 'Search players';

  @override
  String get mediaOffline => 'Offline';

  @override
  String mediaOfflineName(String name) {
    return '$name (offline)';
  }

  @override
  String get mediaSetUpMa => 'Set up Music Assistant to list its players.';

  @override
  String get mediaSetUpHa =>
      'Connect Home Assistant to list its media players.';

  @override
  String get mediaSetUpSonos =>
      'No Sonos speakers known yet. Find or add one on the Sonos page.';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant did not answer: $error';
  }

  @override
  String get mediaSaveFailed => 'Could not save the player.';

  @override
  String get mediaSelectFailed => 'Could not select player';

  @override
  String get mediaNotificationAccessRemote =>
      'Without this Android lists no media sessions, so Now Playing cannot follow the apps playing on this device. The grant screen appears on the tablet.';

  @override
  String get mediaLocalMediaSession => 'Local Media Session';

  @override
  String get settingSendspinEnabledTitle => 'Enable Sendspin player';

  @override
  String get settingSendspinEnabledDescription =>
      'Turn this device into a synchronized Sendspin player. It appears in Music Assistant under the device name, in sync with every other Sendspin speaker.';

  @override
  String get settingSendspinServerTitle => 'Server';

  @override
  String get settingSendspinServerDescription =>
      'Sendspin server address, for example 192.168.1.10:8927. Leave empty to find the server on the network automatically.';

  @override
  String get settingSendspinCodecTitle => 'Preferred audio codec';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC is lossless and ideal on WiFi or ethernet. The server makes the final choice from what this device offers.';

  @override
  String get settingSendspinSyncOffsetTitle => 'Audio sync offset (ms)';

  @override
  String get settingSendspinSyncOffsetDescription =>
      'Negative plays this device earlier, for speakers that lag behind the group (Bluetooth). Tune by ear; applies live.';

  @override
  String get settingSendspinGroupVolumeDescription =>
      'While this device plays in a group, the volume slider sets the whole group\'s volume. Off, only this device\'s. Needs the Music Assistant connection.';

  @override
  String get settingSendspinMasterVolumeTitle => 'Control the device volume';

  @override
  String get settingSendspinMasterVolumeDescription =>
      'Music Assistant sets the volume the volume buttons change, instead of the media volume. Assistant sounds follow it too.';

  @override
  String get mediaSendspinPage => 'Sendspin Player';

  @override
  String get mediaSendspinHint =>
      'Make this device a synchronized Music Assistant player';

  @override
  String get mediaFlac => 'FLAC (lossless)';

  @override
  String get mediaOpus => 'Opus (efficient)';

  @override
  String get mediaPcm => 'PCM (uncompressed)';

  @override
  String get settingSendspinSonosGroupVolumeTitle => 'Adjust the group volume';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      'While the followed room plays in a group, the volume slider sets the whole group\'s volume. Off, only that room\'s.';

  @override
  String get settingSendspinSonosInputsTitle => 'Show TV and line-in';

  @override
  String get settingSendspinSonosInputsDescription =>
      'Show activity in the media player when eARC or line-in inputs are active.';

  @override
  String get mediaSonosHint => 'Speakers on the network, add one by address';

  @override
  String get mediaSonosSpeakers => 'Speakers';

  @override
  String get mediaSonosNoneFound => 'No Sonos found';

  @override
  String get mediaSonosDiscoveryEmpty =>
      'Nothing answered on this network. Add one by address.';

  @override
  String get mediaSonosAddTitle => 'Add a Sonos by address';

  @override
  String get mediaSonosLooking => 'Looking…';

  @override
  String get mediaSonosEmpty => 'No speakers yet';

  @override
  String get mediaSonosEmptyHelp =>
      'Search this network or add a speaker by its address.';

  @override
  String get mediaSonosForget => 'Forget';

  @override
  String get mediaSonosSearchTitle => 'Search the network';

  @override
  String get mediaSonosSearchHelp =>
      'Finds Sonos speakers on this network. The speakers must be on the same VLAN as this device to be auto discovered.';

  @override
  String get mediaSonosSearch => 'Search';

  @override
  String get mediaSonosSearching => 'Searching…';

  @override
  String get mediaSonosAddAddress => 'Add by address';

  @override
  String get mediaSonosAddressHelp =>
      'The speaker\'s address on the network. The whole household is added from it.';

  @override
  String get mediaSonosPickRoom => 'Pick a room under Player source, Sonos.';

  @override
  String get mediaSonosAdded => 'Sonos added';

  @override
  String get mediaSonosNoRooms => 'The speaker listed no rooms.';

  @override
  String get mediaSonosNoAddress => 'no address';

  @override
  String mediaSonosUnreachable(String host) {
    return 'No Sonos answered at $host.';
  }

  @override
  String get settingsMenuHomeAssistant => 'Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary =>
      'Connection, dashboard, kiosk mode';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary =>
      'Wake word, background listening';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary =>
      'Native entities and Bluetooth proxy';

  @override
  String get settingsMenuScreenAudio => 'Screen & Audio';

  @override
  String get settingsMenuScreenAudioSummary => 'Brightness, volume, microphone';

  @override
  String get settingsMenuScreensaver => 'Screensaver';

  @override
  String get settingsMenuScreensaverSummary =>
      'Idle timeout, modes, motion wake';

  @override
  String get settingsMenuBrowser => 'Web Browsing';

  @override
  String get settingsMenuBrowserSummary => 'Cache, SSL, Zoom level';

  @override
  String get settingsMenuMediaPlayer => 'Media Player';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant, Sendspin, Sonos';

  @override
  String get settingsMenuDlna => 'DLNA Renderer';

  @override
  String get settingsMenuDlnaSummary =>
      'Play images, videos and audio remotely';

  @override
  String get settingsMenuIntercom => 'Intercom';

  @override
  String get settingsMenuIntercomSummary => 'Talk between kiosks';

  @override
  String get settingsMenuCamera => 'Camera';

  @override
  String get settingsMenuCameraSummary => 'Device camera, motion, streaming';

  @override
  String get settingsMenuCameraStreams => 'Camera Streams';

  @override
  String get settingsMenuCameraStreamsSummary =>
      'Go2RTC and Home Assistant cameras';

  @override
  String get settingsMenuKiosk => 'Kiosk Mode';

  @override
  String get settingsMenuKioskSummary => 'Exit gesture, PIN, hardware buttons';

  @override
  String get settingsMenuHomeLauncher => 'Home Launcher';

  @override
  String get settingsMenuHomeLauncherSummary =>
      'Replace the device home screen';

  @override
  String get settingsMenuAppLauncher => 'App Launcher';

  @override
  String get settingsMenuAppLauncherSummary => 'Open other apps from the kiosk';

  @override
  String get settingsMenuGestures => 'Gestures';

  @override
  String get settingsMenuGesturesSummary => 'Touch, palm and clap gestures';

  @override
  String get settingsMenuDevice => 'Device';

  @override
  String get settingsMenuDeviceSummary => 'Name, app theme, remote access';

  @override
  String get settingsMenuFleet => 'Fleet Management';

  @override
  String get settingsMenuFleetSummary => 'Lead or follow other kiosks';

  @override
  String get settingsMenuPlugins => 'Plugin Manager';

  @override
  String get settingsMenuPluginsSummary => 'Install and manage plugins';

  @override
  String get settingsMenuLogs => 'Logs';

  @override
  String get settingsMenuLogsSummary => 'App log and web console';

  @override
  String get settingsMenuAbout => 'About';

  @override
  String get settingsMenuAboutSummary => 'Version, author, license';

  @override
  String get settingsMenuOverview => 'Overview';

  @override
  String get settingsMenuOverviewSummary => 'Screen and quick controls';

  @override
  String get settingsMenuLockdown => 'Lockdown Mode';

  @override
  String get settingsMenuLockdownSummary => 'Disable screen interactions';

  @override
  String get settingsMenuFiles => 'File Manager';

  @override
  String get settingsMenuFilesSummary => 'Browse, download and upload files';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => 'Display';

  @override
  String get settingsGroupMediaCameras => 'Media & Cameras';

  @override
  String get settingsGroupHousehold => 'Household';

  @override
  String get settingsGroupKiosk => 'Kiosk';

  @override
  String get settingsGroupSystem => 'System';

  @override
  String get settingsMenuMenu => 'Menu';

  @override
  String get settingsMenuTheme => 'Theme';

  @override
  String get settingsMenuLogout => 'Log out';

  @override
  String get settingsMenuSwitchKiosk => 'Switch kiosk';

  @override
  String settingsMenuThemeState(String theme) {
    return 'Theme: $theme';
  }

  @override
  String get settingsMenuThemeAuto => 'Automatic';

  @override
  String get settingsMenuOverviewHeadlessSummary => 'Status and quick controls';

  @override
  String get settingsMenuHomeAssistantHeadlessSummary => 'Connection';

  @override
  String get settingsMenuAudio => 'Audio';

  @override
  String get settingsMenuAudioSummary => 'Volume, microphone';

  @override
  String get settingsGroupMedia => 'Media';

  @override
  String get settingsMenuDlnaHeadlessSummary => 'Play audio remotely';

  @override
  String get settingsMenuGesturesHeadlessSummary => 'Button and clap gestures';

  @override
  String get settingsMenuLeds => 'LED Control';

  @override
  String get settingsMenuLedsSummary => 'Status light colors and effects';

  @override
  String get settingsLedTimers => 'Timers';

  @override
  String get settingsLedNotifications => 'Notifications';

  @override
  String get settingsLedIdle => 'Idle';

  @override
  String get settingsLedEffects => 'Effects';

  @override
  String get settingsGroupKioskSatellite => 'Kiosk Satellite';

  @override
  String get settingsMenuNavigation => 'Navigation';

  @override
  String get settingsMenuNavigationSummary => 'Classic or Compass';

  @override
  String get navigationStyleSection => 'Navigation style';

  @override
  String get navigationLayoutSection => 'Compass layout';

  @override
  String get navigationOptionsSection => 'Compass options';

  @override
  String get settingNavStyleTitle => 'Navigation style';

  @override
  String get settingNavStyleDescription =>
      'Classic keeps the drawer menu, pull to refresh and the dashboard carousel. Compass swipes between views laid out in a cross.';

  @override
  String get settingNavCompassLayoutTitle => 'Compass layout';

  @override
  String get settingNavCompassLayoutViewsDescription =>
      'Up to two views on each side. Add several Home Assistant dashboard views and one of each other kind.';

  @override
  String get settingNavCompassAnimationTitle => 'Swipe animation';

  @override
  String get settingNavCompassAnimationDescription =>
      'Zoom out to show the views around, or slide straight across.';

  @override
  String get settingNavCompassPositionTitle => 'Show position while swiping';

  @override
  String get settingNavCompassPositionDescription =>
      'A small map of where you are.';

  @override
  String get settingNavCompassReturnMinutesTitle => 'Return to center';

  @override
  String get settingNavCompassReturnMinutesDescription =>
      'Go back to the center view after no touch for this long. Set to 0 to stay on the view.';

  @override
  String get settingNavCompassMenuItemsTitle => 'Menu items';

  @override
  String get settingNavQuickControlsItemsDescription =>
      'What the Quick Controls view shows. Shared with the drawer menu.';

  @override
  String get navigationClassic => 'Classic';

  @override
  String get navigationCompass => 'Compass';

  @override
  String get navigationZoom => 'Zoom';

  @override
  String get navigationSlide => 'Slide';

  @override
  String get compassClassicViewHint => 'Home Assistant view with drawer menu.';

  @override
  String get compassCompassHint => 'Swipe between views laid out in a cross.';

  @override
  String get compassLayoutViewsHint =>
      'Up to two views on each side. Add several Home Assistant dashboard views and one of each other kind. Tap a view to change it, the center one too.';

  @override
  String get compassOffNote =>
      'Pull to refresh, the dashboard carousel and the edge swipe that opens the drawer menu are off while Compass is on.';

  @override
  String get settingOffUnderCompass => 'Off while Compass navigation is on.';

  @override
  String get compassQuickControlsView => 'Quick Controls';

  @override
  String get compassHomeDashboard => 'Home Assistant';

  @override
  String get compassAppLauncher => 'App Launcher';

  @override
  String get compassCenter => 'Center';

  @override
  String get compassAddTile => 'Add';

  @override
  String get compassAddView => 'Add view';

  @override
  String get compassMoveIn => 'Move in';

  @override
  String get compassMoveOut => 'Move out';

  @override
  String get compassReplace => 'Replace';

  @override
  String get compassRemove => 'Remove';

  @override
  String get compassChange => 'Change';

  @override
  String get compassSideUp => 'Up';

  @override
  String get compassSideRight => 'Right';

  @override
  String get compassSideDown => 'Down';

  @override
  String get compassSideLeft => 'Left';

  @override
  String compassFirstView(String side) {
    return '$side, first view';
  }

  @override
  String compassSecondView(String side) {
    return '$side, second view';
  }

  @override
  String get compassAddAbove => 'Add a view above';

  @override
  String get compassAddBelow => 'Add a view below';

  @override
  String get compassAddLeft => 'Add a view on the left';

  @override
  String get compassAddRight => 'Add a view on the right';

  @override
  String get compassChangeCenter => 'Change the center view';

  @override
  String compassReplaceTitle(String name) {
    return 'Replace $name';
  }

  @override
  String get compassKindDashboard => 'Home Assistant dashboard';

  @override
  String get compassKindDashboardHint => 'Any view, Custom Pages and app pages';

  @override
  String get compassKindTaken => 'Already placed';

  @override
  String get compassKindUnavailable => 'Not set up on this kiosk';

  @override
  String get compassKioskLocked => 'Kiosk locked';

  @override
  String get compassQuickControls => 'Quick controls';

  @override
  String get compassOpen => 'Open';

  @override
  String get compassStateOn => 'On';

  @override
  String get compassStateOff => 'Off';

  @override
  String get compassHoldMode => 'Hold Mode';

  @override
  String get settingAdaptiveBrightnessTitle => 'Adaptive brightness';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Dim the screen as the room gets darker, using the ambient light sensor.';

  @override
  String get settingAdaptiveUseEntityTitle => 'Use Home Assistant entity';

  @override
  String get settingAdaptiveUseEntityDescription =>
      'Read the room\'s light level from a Home Assistant sensor.';

  @override
  String get settingAdaptiveLightEntityTitle => 'Light sensor entity';

  @override
  String get settingAdaptiveLightEntityDescription =>
      'The Home Assistant sensor that reports the light level in lux.';

  @override
  String get settingAdaptiveMinBrightnessTitle => 'Minimum brightness';

  @override
  String get settingAdaptiveMinBrightnessDescription =>
      'Screen brightness in a dark room.';

  @override
  String get settingAdaptiveMaxBrightnessTitle => 'Maximum brightness';

  @override
  String get settingAdaptiveMaxBrightnessDescription =>
      'Screen brightness in a bright room.';

  @override
  String get settingAdaptiveDarkLuxTitle => 'Dark room (lx)';

  @override
  String get settingAdaptiveDarkLuxDescription =>
      'Light level at or below which the screen sits at Minimum brightness.';

  @override
  String get settingAdaptiveBrightLuxTitle => 'Bright room (lx)';

  @override
  String get settingAdaptiveBrightLuxDescription =>
      'Light level at or above which the screen sits at Maximum brightness.';

  @override
  String get screenAudioAdaptiveHint =>
      'Follow the room light with the ambient light sensor';

  @override
  String get screenAudioAdaptiveNote =>
      'Level in a bright room. Adaptive brightness dims it from there.';

  @override
  String get screenAudioAdaptiveOwns => 'Adaptive brightness is on.';

  @override
  String get screenAudioNoSensor => 'No ambient light sensor on this device.';

  @override
  String get screenAudioAmbientLight => 'Ambient light';

  @override
  String get screenAudioAmbientHelp =>
      'What the ambient light sensor reads right now.';

  @override
  String get screenAudioNoReading => 'No reading yet';

  @override
  String screenAudioLux(String lux) {
    return '$lux lx';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux lx (last known)';
  }

  @override
  String get screenAudioSetsMaximum =>
      'Sets Maximum brightness: adaptive brightness is on.';

  @override
  String get screenAudioSetsDefault => 'Sets Default brightness.';

  @override
  String get screenAudioBrightnessCurve => 'Brightness curve';

  @override
  String get screenAudioCurveHint =>
      'Drag a point, or tap it to type exact values. The Screen light in Home Assistant moves the top point and the curve follows.';

  @override
  String screenAudioCurvePoint(String number) {
    return 'Point $number';
  }

  @override
  String get screenAudioCurveLightLevel => 'Light level (lx)';

  @override
  String get screenAudioCurveBrightness => 'Brightness (%)';

  @override
  String screenAudioCurveLuxRange(String low, String high) {
    return 'Enter a light level between $low and $high lx';
  }

  @override
  String screenAudioCurveLevelRange(String low, String high) {
    return 'Enter a brightness from $low% to $high%';
  }

  @override
  String get settingAudioMicDeviceTitle => 'Microphone';

  @override
  String get settingAudioMicDeviceDescription =>
      'The microphone wake word detection and voice turns capture from.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Speaker';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Output for Voice Satellite sounds; media playback follows the system route.';

  @override
  String get screenAudioDevices => 'Audio Devices';

  @override
  String get screenAudioSelectedDevice => 'Selected device';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (not connected)';
  }

  @override
  String get settingEqualizerEnabledTitle => 'Enable equalizer';

  @override
  String get settingEqualizerEnabledDescription =>
      'Shapes the sound of music, the assistant, chimes and the intercom. Video and dashboard sounds are not equalized.';

  @override
  String get settingEqualizerBand1Title => '100 Hz';

  @override
  String get settingEqualizerBand1Description =>
      'Bass. Small speakers distort early with a boost here.';

  @override
  String get settingEqualizerBand2Title => '300 Hz';

  @override
  String get settingEqualizerBand2Description =>
      'Low mids. A cut takes out a boxy or boomy sound.';

  @override
  String get settingEqualizerBand3Title => '1 kHz';

  @override
  String get settingEqualizerBand3Description =>
      'Mids, where most of a voice sits.';

  @override
  String get settingEqualizerBand4Title => '3 kHz';

  @override
  String get settingEqualizerBand4Description =>
      'High mids. A boost makes speech clearer.';

  @override
  String get settingEqualizerBand5Title => '10 kHz';

  @override
  String get settingEqualizerBand5Description => 'Treble.';

  @override
  String get settingEqualizerPreampTitle => 'Automatic preamp';

  @override
  String get settingEqualizerPreampDescription =>
      'Lowers the level by the largest boost so the speaker does not distort and echo cancellation keeps working.';

  @override
  String get screenAudioEqualizer => 'Equalizer';

  @override
  String get screenAudioEqualizerHint => 'Bass, mids, treble, preamp';

  @override
  String get settingMicCaptureModeTitle => 'Capture mode';

  @override
  String get settingMicCaptureModeDescription =>
      'Pick Voice communication when the microphone goes silent here, or stops after the kiosk plays a sound. Some devices only record properly on their call audio path.';

  @override
  String get settingMicSoftwareEchoCancellationTitle => 'Echo cancellation';

  @override
  String get settingMicSoftwareEchoCancellationDescription =>
      'Removes the kiosk\'s own sounds from the microphone so the wake word and the assistant do not hear them. Leave it on unless a microphone that cancels its own echo sounds worse with it.';

  @override
  String get settingMicEchoCancellationMethodTitle =>
      'Echo cancellation method';

  @override
  String get settingMicEchoCancellationMethodDescription =>
      'Automatic tests GTCRN while the kiosk plays sounds and switches to AEC3 if it leaves too much echo. Pick Automatic to test again.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Noise suppression';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Takes the hiss out of the microphone. It changes what the wake word hears, so turn it on for a microphone that hisses.';

  @override
  String get settingMicChannelTitle => 'Microphone channel';

  @override
  String get settingMicChannelDescription =>
      'Multichannel microphones often reserve one channel for speech recognition; picking it can improve detection.';

  @override
  String get settingMicGainDbTitle => 'Microphone gain';

  @override
  String get settingMicGainDbDescription =>
      'Boost or cut the microphone before anything hears it. Aim for a level near 0.05 in the wake word tester; too much gain distorts speech and hurts detection.';

  @override
  String get settingMicCaptureFormatTitle => 'Capture format';

  @override
  String get settingMicCaptureFormatDescription =>
      'Pick 48 kHz stereo when the microphone works in other apps but not here: some sound cards record in that format only and the app converts it itself.';

  @override
  String get screenAudioMicrophoneSettings => 'Microphone settings';

  @override
  String get screenAudioMicrophoneHint =>
      'Echo cancellation, noise, gain, format, live level';

  @override
  String get screenAudioMicrophoneNote =>
      'Adjust capture for your microphone and room. Test wake words and voice interactions after changing these settings.';

  @override
  String get screenAudioAutomaticDefault => 'Automatic (default)';

  @override
  String get screenAudioStereo => '48 kHz stereo';

  @override
  String get screenAudioCaptureRawMicrophone => 'Raw microphone (default)';

  @override
  String get screenAudioCaptureVoiceCommunication => 'Voice communication';

  @override
  String get screenAudioEchoMethodGtcrnDetected => 'GTCRN (detected)';

  @override
  String get screenAudioEchoMethodAec3Detected => 'AEC3 (detected)';

  @override
  String get screenAudioDownmix => 'Downmix (default)';

  @override
  String screenAudioChannel(String channel) {
    return 'Channel $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return 'Channel $channel (not on this microphone)';
  }

  @override
  String get screenAudioMicrophoneLevel => 'Microphone level';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      'Speak from where you use the device; adjust the gain until normal speech tops out around the end of the green.';

  @override
  String get settingBrowserCutoutModeTitle => 'Display cutout';

  @override
  String get settingBrowserCutoutModeDescription =>
      'What to do with the screen area around a camera cutout or punch hole. Pick Avoid the cutout if the camera sits on top of buttons at the top of the dashboard.';

  @override
  String get settingScreenOrientationTitle => 'Screen orientation';

  @override
  String get settingScreenOrientationDescription =>
      'Force the screen into one orientation. Use this on a device without a rotation sensor, or one mounted a way the sensor gets wrong.';

  @override
  String get settingScreenHideStatusBarTitle => 'Hide status bar';

  @override
  String get settingScreenHideStatusBarDescription =>
      'Turn off to keep the clock and notification icons at the top of the screen. Kiosk mode always hides it.';

  @override
  String get settingScreenHideNavigationBarTitle => 'Hide navigation bar';

  @override
  String get settingScreenHideNavigationBarDescription =>
      'Turn off to keep the navigation buttons on screen, along with the taskbar on tablets. Kiosk mode always hides it.';

  @override
  String get settingScreenShowOnLockScreenTitle => 'Show over lock screen';

  @override
  String get settingScreenShowOnLockScreenDescription =>
      'Show the dashboard on top of a PIN, pattern or password lock screen. The rest of the device stays locked.';

  @override
  String get settingKeepScreenOnTitle => 'Keep screen on';

  @override
  String get settingKeepScreenOnDescription =>
      'Prevent the OS from turning the screen off.';

  @override
  String get settingSetBrightnessOnLaunchTitle => 'Set brightness on launch';

  @override
  String get settingSetBrightnessOnLaunchDescription =>
      'Apply the default brightness whenever the app starts.';

  @override
  String get settingDefaultBrightnessTitle => 'Default brightness';

  @override
  String get settingDefaultBrightnessDescription =>
      'Screen brightness applied when the app starts. Moving the slider applies it immediately.';

  @override
  String get screenAudioScreen => 'Screen';

  @override
  String get screenAudioCutoutAlways => 'Use the cutout area';

  @override
  String get screenAudioCutoutShort => 'Short edges only';

  @override
  String get screenAudioCutoutDefault => 'System default';

  @override
  String get screenAudioCutoutNever => 'Avoid the cutout';

  @override
  String get screenAudioAutomatic => 'Automatic';

  @override
  String get screenAudioLandscape => 'Landscape';

  @override
  String get screenAudioReverseLandscape => 'Reverse landscape';

  @override
  String get screenAudioPortrait => 'Portrait';

  @override
  String get screenAudioReversePortrait => 'Reverse portrait';

  @override
  String get screenAudioPermission => 'Permission';

  @override
  String get screenAudioBrightnessFallback => 'Brightness is using a fallback';

  @override
  String get screenAudioBrightnessPermission =>
      'Without the \"Modify system settings\" permission, brightness changes only dim this app instead of setting the panel\'s actual brightness.';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      'Without the \"Modify system settings\" permission, brightness changes only dim the app instead of setting the panel\'s actual brightness.';

  @override
  String get screenAudioAlwaysOn => 'Always-on display';

  @override
  String get screenAudioAlwaysOnClock => 'This device keeps a dim clock on';

  @override
  String get screenAudioAlwaysOnHelp =>
      'Turning the screen off puts the device to sleep, but the always-on display lights the lock screen back up and no app can stop it. Turn off \"Always show time and info\" in Android settings under Display, near the lock screen options; some ROMs call it always-on display. The Home Assistant screen entity stays unavailable until you do.';

  @override
  String get settingMediaVolumeTitle => 'Media volume';

  @override
  String get settingMediaVolumeDescription =>
      'Music and video play at this share of the master volume. The Sendspin player volume in Music Assistant moves this slider.';

  @override
  String get settingAssistantVolumeTitle => 'Assistant volume';

  @override
  String get settingAssistantVolumeDescription =>
      'Voice responses and chimes play at this share of the master volume, independent of the media volume.';

  @override
  String get settingIntercomVolumeTitle => 'Intercom volume';

  @override
  String get settingIntercomVolumeDescription =>
      'The other kiosk\'s voice and announcements play at this share of the master volume.';

  @override
  String get screenAudioVolume => 'Audio Volume';

  @override
  String get screenAudioMasterVolume => 'Master volume';

  @override
  String get screenAudioMasterHelp =>
      'The device volume. Media, intercom and assistant volumes scale under it.';

  @override
  String get settingScreensaverBlackHideExtrasTitle => 'Hide all extras';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      'Keeps the screen fully black: no small clock, At a Glance entities, or other overlays.';

  @override
  String get screensaverBlackSection => 'Black screensaver';

  @override
  String get settingScreensaverCelestialLocationTitle => 'Location';

  @override
  String get settingScreensaverCelestialLocationDescription =>
      'Where the sky is seen from.';

  @override
  String get settingScreensaverCelestialEntityTitle => 'Entity';

  @override
  String get settingScreensaverCelestialEntityDescription =>
      'A person, device tracker or zone with a location.';

  @override
  String get settingScreensaverCelestialCoordinatesTitle => 'Coordinates';

  @override
  String get settingScreensaverCelestialCoordinatesDescription =>
      'Latitude and longitude, like 40.71, -74.01.';

  @override
  String get settingScreensaverCelestialTerrainTitle => 'Landscape';

  @override
  String get settingScreensaverCelestialTerrainDescription =>
      'The ground along the horizon.';

  @override
  String get settingScreensaverCelestialFollowDeviceTitle => 'Point at the sky';

  @override
  String get settingScreensaverCelestialFollowDeviceDescription =>
      'Hold the device up and the sky on screen turns with it, so you can name what you are looking at. Needs a compass sensor.';

  @override
  String get settingScreensaverCelestialDaytimeTitle => 'Daytime sky';

  @override
  String get settingScreensaverCelestialDaytimeDescription =>
      'Brighten the sky and fade the stars while the Sun is up. Turn off to show the night sky all day.';

  @override
  String get settingScreensaverCelestialMilkyWayTitle => 'Milky Way';

  @override
  String get settingScreensaverCelestialMilkyWayDescription =>
      'Show the glow of our galaxy across the night sky.';

  @override
  String get settingScreensaverCelestialPlanetsTitle => 'Planets';

  @override
  String get settingScreensaverCelestialPlanetsDescription =>
      'Show the planets where they are tonight.';

  @override
  String get settingScreensaverCelestialDeepSkyTitle => 'Galaxies and nebulae';

  @override
  String get settingScreensaverCelestialDeepSkyDescription =>
      'Show the Andromeda Galaxy, the Orion Nebula and other objects you can see without a telescope.';

  @override
  String get settingScreensaverCelestialLightPollutionTitle =>
      'Light pollution';

  @override
  String get settingScreensaverCelestialLightPollutionDescription =>
      'Simulate the glow of city lights. Higher values hide the fainter stars and the Milky Way.';

  @override
  String get settingScreensaverCelestialTwinkleTitle => 'Twinkling stars';

  @override
  String get settingScreensaverCelestialTwinkleDescription =>
      'Let the stars shimmer, most of all near the horizon. Turn off to save power.';

  @override
  String get settingScreensaverCelestialLargeMoonTitle => 'Larger Moon';

  @override
  String get settingScreensaverCelestialLargeMoonDescription =>
      'Draw the Moon at three times its real size and the Sun at twice, so the phase is easy to see.';

  @override
  String get settingScreensaverCelestialLinesTitle => 'Constellation lines';

  @override
  String get settingScreensaverCelestialLinesDescription =>
      'Connect the stars of each constellation.';

  @override
  String get settingScreensaverCelestialConstellationNamesTitle =>
      'Constellation names';

  @override
  String get settingScreensaverCelestialConstellationNamesDescription =>
      'Name the constellations. More appear as you zoom in.';

  @override
  String get settingScreensaverCelestialNamesTitle => 'Star and planet names';

  @override
  String get settingScreensaverCelestialNamesDescription =>
      'Name the Sun, the Moon, the planets, the brightest stars and the galaxies. More stars get names as you zoom in.';

  @override
  String get settingScreensaverCelestialCompassTitle => 'Compass points';

  @override
  String get settingScreensaverCelestialCompassDescription =>
      'Mark north, east, south and west on the horizon.';

  @override
  String get settingScreensaverCelestialLabelScaleTitle => 'Label size';

  @override
  String get settingScreensaverCelestialLabelScaleDescription =>
      'Scale the labels on the sky from 50 to 200 percent.';

  @override
  String get settingScreensaverCelestialControlCoordinatesTitle => 'Position';

  @override
  String get settingScreensaverCelestialControlCoordinatesDescription =>
      'Show the latitude and longitude the sky is seen from.';

  @override
  String get settingScreensaverCelestialControlAzimuthTitle => 'Azimuth';

  @override
  String get settingScreensaverCelestialControlAzimuthDescription =>
      'Show the compass direction the center of the screen faces.';

  @override
  String get settingScreensaverCelestialControlAltitudeTitle => 'Altitude';

  @override
  String get settingScreensaverCelestialControlAltitudeDescription =>
      'Show how high above the horizon the center of the screen is.';

  @override
  String get settingScreensaverCelestialControlFovTitle => 'Field of view';

  @override
  String get settingScreensaverCelestialControlFovDescription =>
      'Show how much of the sky the screen spans, in degrees.';

  @override
  String get settingScreensaverCelestialControlTimeTitle => 'Time';

  @override
  String get settingScreensaverCelestialControlTimeDescription =>
      'Show the time of the sky, with a Now button after a timelapse.';

  @override
  String get settingScreensaverCelestialControlTimelapseTitle => 'Timelapse';

  @override
  String get settingScreensaverCelestialControlTimelapseDescription =>
      'Speed up time to watch the sky turn. Tap to change the speed.';

  @override
  String get settingScreensaverCelestialControlPointAtSkyTitle =>
      'Point at the sky switch';

  @override
  String get settingScreensaverCelestialControlPointAtSkyDescription =>
      'Turn Point at the sky on and off. Shows only on devices with a compass.';

  @override
  String get settingScreensaverCelestialControlMoonPhaseTitle => 'Moon phase';

  @override
  String get settingScreensaverCelestialControlMoonPhaseDescription =>
      'Show the phase of the Moon and how much of it is lit.';

  @override
  String get settingScreensaverCelestialControlScaleTitle => 'Controls size';

  @override
  String get settingScreensaverCelestialControlScaleDescription =>
      'Scale the controls from 50 to 200 percent.';

  @override
  String get screensaverModeCelestial => 'Celestial';

  @override
  String get screensaverCelestialTerrainHills => 'Hills';

  @override
  String get screensaverCelestialTerrainMountains => 'Mountains';

  @override
  String get screensaverCelestialTerrainPlains => 'Plains';

  @override
  String get screensaverCelestialTerrainNone => 'None';

  @override
  String get screensaverCelestialLocationGps => 'GPS';

  @override
  String get screensaverCelestialLocationHaHome => 'Home Assistant home';

  @override
  String get screensaverCelestialLocationHaEntity => 'Home Assistant entity';

  @override
  String get screensaverCelestialLocationManual => 'Manual';

  @override
  String get screensaverCelestialCurrentLocation => 'Current location';

  @override
  String get screensaverCelestialNoGpsReceiver =>
      'This device has no GPS receiver.';

  @override
  String get screensaverCelestialLocationPermission =>
      'Location permission not granted.';

  @override
  String get screensaverCelestialNoGpsFix => 'No GPS fix yet.';

  @override
  String get screensaverCelestialNoHomeZone =>
      'Home Assistant has no home zone.';

  @override
  String get screensaverCelestialHaNotConnected =>
      'Home Assistant is not connected.';

  @override
  String get screensaverCelestialPickEntity =>
      'Pick an entity with a location.';

  @override
  String get screensaverCelestialEntityNoLocation =>
      'This entity has no location.';

  @override
  String get screensaverCelestialPage => 'Celestial screensaver';

  @override
  String get screensaverCelestialSummary =>
      'Location, landscape, sky, labels, controls';

  @override
  String get screensaverCelestialSkyGroup => 'Sky';

  @override
  String get screensaverCelestialLabelsGroup => 'Labels';

  @override
  String get screensaverCelestialControlsGroup => 'Controls';

  @override
  String get screensaverCelestialLocationGrantMissing =>
      'Without this the GPS receiver cannot be read and the sky has no location.';

  @override
  String get screensaverCelestialLocationGrantReady =>
      'The sky can follow the GPS receiver.';

  @override
  String get screensaverCelestialCoordinatesInvalid =>
      'Enter a latitude and longitude, like 40.71, -74.01';

  @override
  String get screensaverCelestialNoLocation =>
      'Choose a location in Settings > Screensaver > Celestial.';

  @override
  String get screensaverCelestialWaitingForGps => 'Waiting for a GPS fix...';

  @override
  String get screensaverCelestialDoubleTapHint => 'Double tap to close';

  @override
  String get screensaverCelestialCalibrate =>
      'Move the device in a figure eight to calibrate the compass.';

  @override
  String get celestialSun => 'Sun';

  @override
  String get celestialMoon => 'Moon';

  @override
  String get celestialMercury => 'Mercury';

  @override
  String get celestialVenus => 'Venus';

  @override
  String get celestialMars => 'Mars';

  @override
  String get celestialJupiter => 'Jupiter';

  @override
  String get celestialSaturn => 'Saturn';

  @override
  String get celestialUranus => 'Uranus';

  @override
  String get celestialNeptune => 'Neptune';

  @override
  String get celestialAndromedaGalaxy => 'Andromeda Galaxy';

  @override
  String get celestialTriangulumGalaxy => 'Triangulum Galaxy';

  @override
  String get celestialLargeMagellanicCloud => 'Large Magellanic Cloud';

  @override
  String get celestialSmallMagellanicCloud => 'Small Magellanic Cloud';

  @override
  String get celestialOrionNebula => 'Orion Nebula';

  @override
  String get celestialLagoonNebula => 'Lagoon Nebula';

  @override
  String get celestialCarinaNebula => 'Carina Nebula';

  @override
  String get celestialPleiades => 'Pleiades';

  @override
  String get celestialBeehiveCluster => 'Beehive Cluster';

  @override
  String get celestialDoubleCluster => 'Double Cluster';

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
  String get celestialAltitudeShort => 'Alt';

  @override
  String get celestialFovShort => 'FOV';

  @override
  String get celestialNow => 'Now';

  @override
  String get celestialMoonNew => 'New Moon';

  @override
  String get celestialMoonWaxingCrescent => 'Waxing crescent';

  @override
  String get celestialMoonFirstQuarter => 'First quarter';

  @override
  String get celestialMoonWaxingGibbous => 'Waxing gibbous';

  @override
  String get celestialMoonFull => 'Full Moon';

  @override
  String get celestialMoonWaningGibbous => 'Waning gibbous';

  @override
  String get celestialMoonLastQuarter => 'Last quarter';

  @override
  String get celestialMoonWaningCrescent => 'Waning crescent';

  @override
  String get settingScreensaverClockStyleTitle => 'Style';

  @override
  String get settingScreensaverClockStyleDescription =>
      'How the clock is drawn.';

  @override
  String get settingScreensaverClockVerticalTitle => 'Vertical mode';

  @override
  String get settingScreensaverClockVerticalDescription =>
      'Stack the hours above the minutes, for portrait screens.';

  @override
  String get settingScreensaverClockFontTitle => 'Font Family';

  @override
  String get settingScreensaverClockFontDescription =>
      'The typeface the clock is drawn in.';

  @override
  String get settingScreensaverClockFontWeightTitle => 'Font weight';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      'How heavy the clock\'s digits are drawn. Default is each face\'s own weight.';

  @override
  String get settingScreensaverClock24hTitle => '24-hour clock';

  @override
  String get settingScreensaverClock24hDescription =>
      'Show a 24-hour time instead of AM/PM.';

  @override
  String get settingScreensaverClockSecondsTitle => 'Show seconds';

  @override
  String get settingScreensaverClockSecondsDescription =>
      'Include seconds in the clock.';

  @override
  String get settingScreensaverClockDateTitle => 'Show date';

  @override
  String get settingScreensaverClockDateDescription =>
      'Show the weekday and date under the clock.';

  @override
  String get settingScreensaverClockScaleTitle => 'Clock size';

  @override
  String get settingScreensaverClockScaleDescription =>
      'Scale the clock from 50 to 300 percent for this screen.';

  @override
  String get settingScreensaverClockColorTitle => 'Clock color';

  @override
  String get settingScreensaverClockColorDescription =>
      'The color of the clock text.';

  @override
  String get settingScreensaverClockBgColorTitle => 'Background color';

  @override
  String get settingScreensaverClockBgColorDescription =>
      'The color behind the clock.';

  @override
  String get settingScreensaverClockBackgroundTitle => 'Background photo';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      'Show a photo behind the clock instead of the solid color. A path to an image on the device, or an image URL the device fetches.';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle =>
      'Refresh URL background';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      'Minutes between fetches of a URL background. 0 fetches it only when the setting is written.';

  @override
  String get settingScreensaverFlipDigitColorTitle => 'Digit color';

  @override
  String get settingScreensaverFlipDigitColorDescription =>
      'The color of the flip digits.';

  @override
  String get settingScreensaverFlipBgColorTitle => 'Card color';

  @override
  String get settingScreensaverFlipBgColorDescription =>
      'The color of the cards.';

  @override
  String get settingScreensaverFlipBackdropColorTitle => 'Background color';

  @override
  String get settingScreensaverFlipBackdropColorDescription =>
      'The color behind the cards.';

  @override
  String get settingScreensaverRollerDigitColorTitle => 'Digit color';

  @override
  String get settingScreensaverRollerDigitColorDescription =>
      'The color of the rolling digits.';

  @override
  String get settingScreensaverRollerBgColorTitle => 'Background color';

  @override
  String get settingScreensaverRollerBgColorDescription =>
      'The color behind the digits.';

  @override
  String get settingScreensaverHandNumbersTitle => 'Numbers';

  @override
  String get settingScreensaverHandNumbersDescription =>
      'Which hours the dial shows as numbers.';

  @override
  String get settingScreensaverHandSecondsTitle => 'Show seconds hand';

  @override
  String get settingScreensaverHandSecondsDescription =>
      'Draw a seconds hand on the dial.';

  @override
  String get settingScreensaverHandColorTitle => 'Clock color';

  @override
  String get settingScreensaverHandColorDescription =>
      'The color of the hands, numbers and ticks.';

  @override
  String get settingScreensaverHandBgColorTitle => 'Background color';

  @override
  String get settingScreensaverHandBgColorDescription =>
      'The color behind the clock.';

  @override
  String get settingScreensaverClockNightTitle => 'Night mode';

  @override
  String get settingScreensaverClockNightDescription =>
      'Recolor the clock while the room is dark.';

  @override
  String get settingScreensaverClockNightLuxTitle => 'Light level';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      'At or below this light level the clock takes the night color.';

  @override
  String get settingScreensaverClockNightColorTitle => 'Night color';

  @override
  String get settingScreensaverClockNightColorDescription =>
      'The color of the clock and the widgets in the dark.';

  @override
  String get settingScreensaverClockNightBgColorTitle => 'Night background';

  @override
  String get settingScreensaverClockNightBgColorDescription =>
      'The color behind the clock in the dark.';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle =>
      'Hide background photo';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      'Use the night background color instead of the photo while Night mode is active.';

  @override
  String get settingScreensaverClockNightHideWidgetsTitle =>
      'Hide widgets and At a Glance';

  @override
  String get settingScreensaverClockNightHideWidgetsDescription =>
      'Show only the clock while Night mode is active.';

  @override
  String get settingScreensaverClockNightCardColorTitle => 'Night card color';

  @override
  String get settingScreensaverClockNightCardColorDescription =>
      'The color of the flip cards in the dark.';

  @override
  String get screensaverClockSection => 'Clock screensaver';

  @override
  String get screensaverClockHint =>
      'Style, font, size, colors, night mode, background photo';

  @override
  String get screensaverStyleDigital => 'Digital Clock';

  @override
  String get screensaverStyleFlip => 'Flip Clock';

  @override
  String get screensaverStyleRoller => 'Roller Clock';

  @override
  String get screensaverStyleHand => 'Hand Clock';

  @override
  String get screensaverHandNumbersQuarters => '12, 3, 6 and 9';

  @override
  String get screensaverHandNumbersAll => 'All hours';

  @override
  String get screensaverFontDefault => 'Default';

  @override
  String get screensaverFontLight => 'Light';

  @override
  String get screensaverFontRegular => 'Regular';

  @override
  String get screensaverFontMedium => 'Medium';

  @override
  String get screensaverFontBold => 'Bold';

  @override
  String get screensaverFontBlack => 'Black';

  @override
  String get screensaverNoPhoto => 'No photo selected';

  @override
  String get screensaverBackgroundHint =>
      'Path to an image on the device, or an image URL';

  @override
  String get screensaverImageUrlError => 'Enter a full image URL';

  @override
  String get screensaverRefreshError => 'Enter whole minutes from 0 to 1440';

  @override
  String screensaverMaxCharacters(String count) {
    return 'Use at most $count characters';
  }

  @override
  String get settingScreensaverClockAmPmTitle => 'Show AM/PM';

  @override
  String get settingScreensaverClockAmPmDescription =>
      'Add AM or PM after the time.';

  @override
  String get settingScreensaverClockNightTurnOffMinutesTitle =>
      'Turn screen off at night after';

  @override
  String get settingScreensaverClockNightTurnOffMinutesDescription =>
      'Turns the screen off once Night mode has lasted the set time and back on when the room brightens. Set to 0 to keep the screen on. Requires Device Administrator permission.';

  @override
  String get screensaverNightTurnOffWarning =>
      'When the display really powers off, the tablet\'s own power management takes over. Many Android models misbehave in that state: Wi-Fi naps or drops, Home Assistant entities go unavailable, the camera can be revoked and some models kill background apps. Some light sensors also stop reporting with the display off, so the screen may not turn back on by itself when the room brightens. What happens depends on the manufacturer.\n\nThe reliable alternative is Use a black screen instead. The panel looks just as dark and the app keeps full control.';

  @override
  String get screensaverOverlayEntity => 'Entity';

  @override
  String get screensaverOverlayNotSet => 'Not set';

  @override
  String get screensaverOverlayName => 'Name';

  @override
  String get screensaverOverlayNameHelp =>
      'Leave empty to use the Home Assistant name.';

  @override
  String get screensaverOverlayValue => 'Displayed value';

  @override
  String get screensaverOverlayState => 'State';

  @override
  String get screensaverOverlayEntityRequired => 'Pick an entity.';

  @override
  String get screensaverOverlaySearching => 'Searching…';

  @override
  String get screensaverOverlayUnreachable => 'Could not reach Home Assistant';

  @override
  String get screensaverOverlayNoAnswer => 'The device did not answer.';

  @override
  String get settingScreensaverDismissOnFaceTitle => 'Dismiss on face';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      'Wake the screen when someone looks at the kiosk, not on movement alone. The camera runs only during the screensaver. WARNING: Needs a lit face; in the dark, schedule motion detection instead.';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle =>
      'Only when screen is off';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      'Keep the screensaver visible when a face is detected while the screen is on. Once the screen turns off, detection wakes the dashboard. Touch still dismisses the screensaver.';

  @override
  String get settingScreensaverPostponeOnFaceTitle =>
      'Postpone screensaver on face';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      'Delay activating the screensaver while someone is looking at the kiosk. WARNING: Keeps the camera running permanently, with face detection and its CPU cost on top.';

  @override
  String get settingFaceSensitivityTitle => 'Face sensitivity';

  @override
  String get settingFaceSensitivityDescription =>
      'Higher wakes on smaller, more distant faces. 1 needs a face close to the screen; 100 reacts to any face the camera can make out.';

  @override
  String get screensaverDetectionFacePage => 'Face Detection';

  @override
  String get screensaverDetectionFaceHint =>
      'Dismiss the screensaver when someone looks at it';

  @override
  String get screensaverDetectionMotionPrecedence =>
      'Dismiss on motion is on and takes precedence, so face detection stays idle until it is turned off.';

  @override
  String get screensaverDetectionFaceTuning =>
      'Frame rate, camera pick and startup delay are tuned in the Camera settings.';

  @override
  String get screensaverDetectionAndroidUnsupported =>
      'Not available on this Android version.';

  @override
  String get screensaverDetectionX86Unsupported =>
      'Not available on x86 devices.';

  @override
  String get settingFacePreviewTitle => 'Show camera preview';

  @override
  String get settingFacePreviewDescription =>
      'Show a small round live view of the camera in a corner of the screen for a few seconds when a face wakes the kiosk.';

  @override
  String get settingFacePreviewSecondsTitle => 'Preview duration';

  @override
  String get settingFacePreviewSecondsDescription =>
      'How long the preview stays on screen.';

  @override
  String get settingFacePreviewScaleTitle => 'Preview scaling';

  @override
  String get settingFacePreviewScaleDescription =>
      'Scale the preview to better fit your screen size.';

  @override
  String get settingFacePreviewPositionTitle => 'Preview position';

  @override
  String get settingFacePreviewPositionDescription =>
      'Which corner the preview sits in.';

  @override
  String get screensaverDetectionPreviewSection => 'Camera Preview';

  @override
  String get settingScreensaverEnabledTitle => 'Screensaver';

  @override
  String get settingScreensaverEnabledDescription =>
      'Dim or blank the screen after a period of inactivity.';

  @override
  String get settingScreensaverTimeoutSecondsTitle => 'Idle timeout (seconds)';

  @override
  String get settingScreensaverTimeoutSecondsDescription =>
      'Inactivity period before the screensaver starts.';

  @override
  String get settingScreensaverFadeTitle => 'Fade in and out';

  @override
  String get settingScreensaverFadeDescription =>
      'The screensaver fades in over the dashboard and fades out when dismissed. Not for the Home Assistant Media, Website or Camera Streams screensavers.';

  @override
  String get settingScreensaverModeTitle => 'Screensaver mode';

  @override
  String get settingScreensaverModeDescription =>
      'What the screensaver shows after the idle timeout. Dim only lowers the backlight and leaves the dashboard on screen.';

  @override
  String get settingScreensaverPixelShiftTitle => 'Pixel shift';

  @override
  String get settingScreensaverPixelShiftDescription =>
      'Nudge the image every minute to protect OLED panels. Not for the black screensaver, whose pixels are already off.';

  @override
  String get settingScreensaverFollowAnimationScaleTitle =>
      'Follow Android animation settings';

  @override
  String get settingScreensaverFollowAnimationScaleDescription =>
      'Pause animated screensavers when Android animations are off.';

  @override
  String get settingScreensaverDimLevelTitle => 'Dim level';

  @override
  String get settingScreensaverDimLevelDescription =>
      'Screen brightness while the screensaver is dimming.';

  @override
  String get settingScreensaverBrightnessEnabledTitle =>
      'Screensaver brightness';

  @override
  String get settingScreensaverBrightnessEnabledDescription =>
      'Use a separate brightness while the screensaver is showing.';

  @override
  String get settingScreensaverBrightnessLevelTitle => 'Brightness level';

  @override
  String get settingScreensaverBrightnessLevelDescription =>
      'Applies to every mode except Dim and Black.';

  @override
  String get settingScreensaverNotificationBrightnessTitle =>
      'Brighten for notifications';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      'Lift the screensaver dimming while a notification is on screen.';

  @override
  String get settingScreensaverTouchBrightnessSecondsTitle =>
      'Brighten for touch interactions';

  @override
  String get settingScreensaverTouchBrightnessSecondsDescription =>
      'Lift the screensaver dimming for this long after a touch that does not dismiss it. Set to 0 to turn it off.';

  @override
  String get settingScreensaverScreenOffMinutesTitle => 'Turn screen off after';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Powers down the display panel once the screensaver has run for the set duration. Set to 0 to keep the screen on indefinitely. Requires Device Administrator permission.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Wake to screensaver';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescriptionSources =>
      'Choose what brings the screensaver back instead of the dashboard after the screen has turned off. The Turn screen off after countdown starts over.';

  @override
  String get screensaverWakeSourcesAll => 'All';

  @override
  String get screensaverWakeSourceMotion => 'Motion';

  @override
  String get screensaverWakeSourceFace => 'Face';

  @override
  String get screensaverWakeSourceProximity => 'Proximity';

  @override
  String get screensaverWakeSourcePerson => 'Person';

  @override
  String get screensaverWakeSourcePower => 'Power button';

  @override
  String get screensaverWakeSourceTouch => 'Touch';

  @override
  String get screensaverWakeSourceTouchRequires =>
      'Requires both \"Turn screen off after\" and \"Use a black screen instead.\"';

  @override
  String get screensaverModeDim => 'Dim';

  @override
  String get screensaverModeBlack => 'Black';

  @override
  String get screensaverModeClock => 'Clock';

  @override
  String get screensaverModeMedia => 'Home Assistant Media';

  @override
  String get screensaverModeLocal => 'Local Media';

  @override
  String get screensaverModeGallery => 'Photo Gallery';

  @override
  String get screensaverModeImmich => 'Immich Media';

  @override
  String get screensaverModeWebsite => 'Website';

  @override
  String get screensaverModeCamera => 'Camera Streams';

  @override
  String get screensaverDimSection => 'Dim screensaver';

  @override
  String get screensaverWarningTitle => 'WARNING: Please Read!';

  @override
  String get screensaverScreenOffProceed => 'Turn screen off anyway';

  @override
  String get screensaverAdminMissing =>
      'Not granted, so the screen cannot turn off.';

  @override
  String get screensaverAdminMissingRemote => 'Device admin permission missing';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      'Without it the screen cannot be turned off. The grant dialog appears on the tablet screen.';

  @override
  String get screensaverDimWarning =>
      'WARNING: Dim keeps the dashboard visible, so the \"Pause dashboard during screensaver\" optimization will not be applied and the dashboard keeps using CPU, GPU and battery.';

  @override
  String get screensaverUnavailablePlugin => 'Unavailable plugin screensaver';

  @override
  String get screensaverScreenOffWarning =>
      'Once the display truly powers off, the tablet\'s own power management takes over, and many Android models misbehave in that state: Wi-Fi naps or drops, the Home Assistant entities go unavailable, the camera can be revoked, and some models kill background apps outright. What happens depends on the manufacturer.\n\nThe reliable alternative is the Black screensaver with this setting left at 0: the panel looks just as dark, and the app keeps full control.';

  @override
  String get settingScreensaverScreenOffBlackTitle =>
      'Use a black screen instead';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      'Show a plain black screen at zero brightness instead of powering off the display. Hides widgets and Now Playing. No Device Administrator permission is needed.';

  @override
  String get screensaverModeDashboard => 'Home Assistant Dashboard';

  @override
  String get settingScreensaverDashboardViewTitle => 'Dashboard view';

  @override
  String get settingScreensaverDashboardViewDescription =>
      'The Home Assistant dashboard view the screensaver shows.';

  @override
  String get settingScreensaverDashboardDoubleTapTitle =>
      'Double tap to dismiss';

  @override
  String get settingScreensaverDashboardDoubleTapDescription =>
      'Single taps interact with the dashboard instead of dismissing.';

  @override
  String get settingScreensaverDashboardKioskTitle => 'HA kiosk mode override';

  @override
  String get settingScreensaverDashboardKioskDescription =>
      'Choose what the screensaver hides, separate from HA kiosk mode.';

  @override
  String get settingScreensaverDashboardHideHeaderTitle => 'Hide the header';

  @override
  String get settingScreensaverDashboardHideHeaderDescription =>
      'Hide the dashboard toolbar and view tabs on the screensaver.';

  @override
  String get settingScreensaverDashboardHideSidebarTitle => 'Hide the sidebar';

  @override
  String get settingScreensaverDashboardHideSidebarDescription =>
      'Hide the navigation sidebar on the screensaver.';

  @override
  String get screensaverDashboardSection =>
      'Home Assistant Dashboard screensaver';

  @override
  String get screensaverModeUrl => 'Image URL';

  @override
  String get screensaverCalendarSection => 'Calendar screensaver';

  @override
  String get settingScreensaverCalendarViewTitle => 'Calendar view';

  @override
  String get settingScreensaverCalendarViewDescription =>
      'The calendar view the screensaver opens on.';

  @override
  String get settingScreensaverGlanceScaleTitle => 'Row scaling';

  @override
  String get settingScreensaverGlanceScaleDescription =>
      'Scale the row to better fit your screen size.';

  @override
  String get settingScreensaverGlanceFontTitle => 'Font family';

  @override
  String get settingScreensaverGlanceFontDescription =>
      'The typeface the row is drawn in.';

  @override
  String get settingScreensaverGlanceFontWeightTitle => 'Font weight';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      'How heavy the row\'s text is drawn. Default is each line\'s own weight: regular names, semibold values.';

  @override
  String get settingScreensaverGlanceHideNamesTitle => 'Hide names';

  @override
  String get settingScreensaverGlanceHideNamesDescription =>
      'Show only the icon and the value, with the value drawn larger.';

  @override
  String get settingScreensaverGlanceBwIconsTitle => 'Monochromatic icons';

  @override
  String get settingScreensaverGlanceBwIconsDescription =>
      'Keep every icon in the neutral grey instead of its state color.';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => 'Floating text style';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      'Show the entities as floating text instead of chips.';

  @override
  String get screensaverOverlayAppearance => 'Appearance';

  @override
  String get settingScreensaverGlanceEnabledTitle => 'At a glance';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      'Show a row of Home Assistant entity states on the screensaver.';

  @override
  String get settingScreensaverGlanceEntitiesTitle => 'Entities';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      'Up to four entities to show, each with an optional custom name.';

  @override
  String get settingScreensaverGlanceNowPlayingTitle => 'Show on Now Playing';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      'Show the row on the full-screen Now Playing view. It stays hidden while lyrics are showing.';

  @override
  String get screensaverOverlayShowing => 'Showing';

  @override
  String get screensaverOverlayNone => 'None yet';

  @override
  String get screensaverOverlayGlancePage => 'At a Glance';

  @override
  String get screensaverOverlayGlanceHint =>
      'Entities shown over the screensaver';

  @override
  String get glanceUnavailable => 'Unavailable';

  @override
  String get glanceUnknown => 'Unknown';

  @override
  String get settingScreensaverImmichUrlTitle => 'Server address';

  @override
  String get settingScreensaverImmichUrlDescription =>
      'The address of your Immich server, with its port.';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'API key';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      'Created in Immich under Account Settings → API Keys.';

  @override
  String get screensaverMediaImmichPage => 'Immich Media screensaver';

  @override
  String get screensaverMediaImmichHint =>
      'Server, media, slideshow, metadata, filters';

  @override
  String get screensaverMediaServerConnection => 'Server Connection';

  @override
  String get screensaverMediaValidateFailedLog =>
      'Validation failed. See the app log for the failing call.';

  @override
  String get screensaverMediaValidateFailed => 'Validation failed.';

  @override
  String get screensaverMediaNoAnswer => 'The device did not answer.';

  @override
  String get screensaverMediaAddressFirst => 'Enter the server address first.';

  @override
  String get screensaverMediaKeyFirst => 'Enter an API key first.';

  @override
  String get screensaverMediaBadAddress =>
      'The server address is not a valid URL.';

  @override
  String get screensaverMediaKeyRejected => 'The API key was rejected.';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'The API key is missing the $scope permission.';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'The API key is missing a permission: $error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return 'The server answered $status: $error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return 'Could not reach $url.';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return 'Could not talk to the server: $error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => 'People';

  @override
  String get settingScreensaverImmichPeopleDescription =>
      'Show only media with any of these people.';

  @override
  String get settingScreensaverImmichExcludePeopleTitle => 'Exclude people';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      'Skip media with any of these people.';

  @override
  String get settingScreensaverImmichTagsTitle => 'Tags';

  @override
  String get settingScreensaverImmichTagsDescription =>
      'Show only media with any of these tags.';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => 'Exclude tags';

  @override
  String get settingScreensaverImmichExcludeTagsDescription =>
      'Skip media with any of these tags.';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => 'Favorites only';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      'Show only media marked as favorite.';

  @override
  String get settingScreensaverImmichTakenWithinTitle => 'Taken within';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      'Only show media taken in this window.';

  @override
  String get settingScreensaverImmichTakenFromTitle => 'From';

  @override
  String get settingScreensaverImmichTakenFromDescription =>
      'Skip media taken before this date.';

  @override
  String get settingScreensaverImmichTakenToTitle => 'To';

  @override
  String get settingScreensaverImmichTakenToDescription =>
      'Skip media taken after this date. The day itself counts.';

  @override
  String get screensaverMediaFilters => 'Filters';

  @override
  String get screensaverMediaAnyone => 'Anyone';

  @override
  String get screensaverMediaAnyoneDevice => 'Anyone.';

  @override
  String get screensaverMediaNoOne => 'No one';

  @override
  String get screensaverMediaNoOneDevice => 'No one.';

  @override
  String get screensaverMediaAny => 'Any';

  @override
  String get screensaverMediaAnyDevice => 'Any.';

  @override
  String get screensaverMediaNoTagsChosen => 'No tags';

  @override
  String get screensaverMediaNoTagsChosenDevice => 'No tags.';

  @override
  String get screensaverMediaNoPeople =>
      'No named people yet. Name them in Immich first.';

  @override
  String get screensaverMediaNoTags =>
      'No tags yet. Create them in Immich first.';

  @override
  String get screensaverMediaPeopleFailed => 'Could not list the people';

  @override
  String get screensaverMediaTagsFailed => 'Could not list the tags';

  @override
  String get screensaverMediaHidden => 'Hidden';

  @override
  String get screensaverMediaAnyTime => 'Any time';

  @override
  String get screensaverMediaPastMonth => 'Past month';

  @override
  String get screensaverMediaPast3Months => 'Past 3 months';

  @override
  String get screensaverMediaPastYear => 'Past year';

  @override
  String get screensaverMediaPast2Years => 'Past 2 years';

  @override
  String get screensaverMediaPast5Years => 'Past 5 years';

  @override
  String get screensaverMediaPast10Years => 'Past 10 years';

  @override
  String get screensaverMediaSince => 'Since';

  @override
  String get screensaverMediaTimeframe => 'Timeframe';

  @override
  String get screensaverMediaToday => 'Today';

  @override
  String get screensaverMediaDateFormat => 'Use YYYY-MM-DD.';

  @override
  String get screensaverMediaNotDate => 'That is not a date.';

  @override
  String get settingScreensaverImmichMetadataTitle => 'Show metadata';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      'Album, date, camera and location over the media.';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => 'Album name';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription =>
      'Show which album the photo comes from.';

  @override
  String get settingScreensaverImmichMetadataDateTitle => 'Date taken';

  @override
  String get settingScreensaverImmichMetadataDateDescription =>
      'Show when the photo was taken.';

  @override
  String get settingScreensaverImmichMetadataCameraTitle => 'Camera details';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      'Show focal length, aperture and ISO.';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => 'Location';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      'Show the place the photo was taken.';

  @override
  String get settingScreensaverImmichMetadataDescriptionTitle => 'Description';

  @override
  String get settingScreensaverImmichMetadataDescriptionDescription =>
      'Show the photo\'s description at the bottom of the screen.';

  @override
  String get settingScreensaverImmichMetadataPositionTitle =>
      'Metadata position';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      'Which corner the details sit in.';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle =>
      'Text drop shadow';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      'Add a drop shadow to metadata text for readability on photos.';

  @override
  String get settingScreensaverImmichMetadataScaleTitle => 'Text scaling';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      'Scale the photo details to better fit your screen size.';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle =>
      'Vignette strength';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      'Darkness of the shading behind the details, for readability on bright photos. 0 turns it off.';

  @override
  String get screensaverMediaMetadata => 'Metadata';

  @override
  String get screensaverMediaTopLeft => 'Top left';

  @override
  String get screensaverMediaTopRight => 'Top right';

  @override
  String get screensaverMediaBottomLeft => 'Bottom left';

  @override
  String get screensaverMediaBottomRight => 'Bottom right';

  @override
  String get settingScreensaverImmichIntervalTitle => 'Seconds per image';

  @override
  String get settingScreensaverImmichShuffleTitle => 'Shuffle';

  @override
  String get settingScreensaverImmichShuffleDescription =>
      'Cycle the media in random order.';

  @override
  String get settingScreensaverImmichTransitionTitle => 'Transition';

  @override
  String get settingScreensaverImmichTransitionDescription =>
      'How one item hands off to the next.';

  @override
  String get settingScreensaverImmichFillTitle => 'Fill the screen';

  @override
  String get settingScreensaverImmichFillDescription =>
      'Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.';

  @override
  String get settingScreensaverImmichPairPortraitTitle =>
      'Pair portrait photos';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      'Show two portrait photos side by side so they fill the screen.';

  @override
  String get settingScreensaverImmichPairLandscapeTitle =>
      'Pair landscape photos';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      'Show two landscape photos one above the other so they fill a portrait screen.';

  @override
  String get settingScreensaverImmichEdgeTapsTitle =>
      'Tap edges to change slides';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      'A tap on the left or right fifth of the screen shows the previous or next slide instead of dismissing.';

  @override
  String get screensaverMediaSlideshow => 'Slideshow';

  @override
  String get settingScreensaverImmichAlbumTitle => 'Media source';

  @override
  String get settingScreensaverImmichAlbumDescription =>
      'The whole library, or the albums you pick.';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => 'Photos only';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription =>
      'Skip videos in the slideshow.';

  @override
  String get settingScreensaverImmichCacheTitle => 'Cache media locally';

  @override
  String get settingScreensaverImmichCacheDescription =>
      'Keep copies on the device so images load instantly.';

  @override
  String get settingScreensaverImmichCacheMaxTitle => 'Cache size (items)';

  @override
  String get settingScreensaverImmichCacheMaxDescription =>
      'The oldest items are deleted once the cache is full.';

  @override
  String get screensaverMediaAll => 'All media';

  @override
  String get screensaverMediaAllDevice => 'All media.';

  @override
  String get screensaverMediaNoAlbums =>
      'No albums yet. Create one in Immich first.';

  @override
  String get screensaverMediaAlbumsFailed => 'Could not list the albums';

  @override
  String screensaverMediaListError(String error) {
    return 'Could not list them: $error';
  }

  @override
  String get screensaverMediaListingFailed => 'listing failed';

  @override
  String screensaverMediaItems(String count) {
    return '$count items';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return '$count cached, $size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => 'Camera views';

  @override
  String get settingScreensaverCameraViewsDescription =>
      'The camera views the screensaver shows, in this order.';

  @override
  String get settingScreensaverCameraViewSecondsTitle =>
      'Seconds per camera view';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      'How long each view stays on screen before the next one. With a single view selected nothing rotates.';

  @override
  String get settingScreensaverCameraMuteTitle => 'Mute all views';

  @override
  String get settingScreensaverCameraMuteDescription =>
      'Keeps every view silent, even a single camera.';

  @override
  String get screensaverMediaCameraPage => 'Camera Streams screensaver';

  @override
  String get screensaverMediaCameraHint =>
      'Views to show, seconds per view, sound';

  @override
  String get screensaverMediaNoCameras =>
      'No camera view has cameras yet. Add one under Camera Streams.';

  @override
  String get screensaverMediaNoCamerasRemote =>
      'No camera view has cameras yet';

  @override
  String get screensaverMediaAddCameras => 'Add one under Camera Streams.';

  @override
  String get screensaverMediaNoViews =>
      'None yet. Pick the views the screensaver cycles through.';

  @override
  String get screensaverMediaRotation => 'In the rotation (drag to reorder)';

  @override
  String get screensaverMediaAvailable => 'Available';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count camera';
  }

  @override
  String screensaverMediaCameras(String count) {
    return '$count cameras';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return 'Position $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => 'None';

  @override
  String get screensaverMediaTransitionFade => 'Crossfade';

  @override
  String get screensaverMediaTransitionSlide => 'Slide';

  @override
  String get screensaverMediaTransitionZoom => 'Zoom';

  @override
  String get screensaverMediaTransitionKenBurns => 'Ken Burns';

  @override
  String get screensaverMediaTransitionRandom => 'Random';

  @override
  String get screensaverMediaFillOff => 'Off';

  @override
  String get screensaverMediaFillSmart => 'Smart';

  @override
  String get screensaverMediaFillAlways => 'Always';

  @override
  String get settingScreensaverVideoLengthTitle => 'Video length';

  @override
  String get settingScreensaverVideoLengthDescription =>
      'How long each video plays before the next.';

  @override
  String get screensaverMediaVideoLengthFull => 'Whole video';

  @override
  String get screensaverMediaVideoLengthInterval => 'Same as photos';

  @override
  String get settingScreensaverImageIntervalDescription =>
      'How long each image shows before the next.';

  @override
  String get settingScreensaverPhotoIntervalDescription =>
      'How long each photo shows before the next.';

  @override
  String get settingScreensaverGalleryItemsTitle => 'Photos';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'The photos and videos this screensaver cycles. Picked from the gallery on the device; picking again replaces the selection.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Seconds per photo';

  @override
  String get settingScreensaverGalleryShuffleTitle => 'Shuffle';

  @override
  String get settingScreensaverGalleryShuffleDescription =>
      'Cycle the selection in random order.';

  @override
  String get settingScreensaverGalleryTransitionTitle => 'Transition';

  @override
  String get settingScreensaverGalleryTransitionDescription =>
      'How one photo hands off to the next.';

  @override
  String get settingScreensaverGalleryFillTitle => 'Fill the screen';

  @override
  String get settingScreensaverGalleryFillDescription =>
      'Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle =>
      'Tap edges to change slides';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      'A tap on the left or right fifth of the screen shows the previous or next slide instead of dismissing.';

  @override
  String get screensaverMediaGalleryPage => 'Photo Gallery screensaver';

  @override
  String get screensaverMediaGalleryHint =>
      'Photos, timing, shuffle, transition';

  @override
  String get screensaverMediaLoadingPhotos => 'Loading photos...';

  @override
  String screensaverMediaCopying(String index, String total) {
    return 'Copying photo $index of $total...';
  }

  @override
  String get screensaverMediaCopyFailed => 'Could not copy the photos';

  @override
  String get screensaverMediaSmallerSelection => 'Try a smaller selection.';

  @override
  String get screensaverMediaNoPhotos => 'No photos selected';

  @override
  String screensaverMediaSelected(String count) {
    return '$count selected';
  }

  @override
  String get screensaverMediaPickOnDevice =>
      'None selected. Pick on the device.';

  @override
  String get settingScreensaverMediaIdTitle => 'Media source';

  @override
  String get settingScreensaverMediaIdDescription =>
      'A Home Assistant media item, folder, or camera. Use Browse to pick one.';

  @override
  String get settingScreensaverMediaIntervalTitle => 'Seconds per image';

  @override
  String get settingScreensaverMediaShuffleTitle => 'Shuffle';

  @override
  String get settingScreensaverMediaShuffleDescription =>
      'Play a folder in random order.';

  @override
  String get settingScreensaverMediaRecursiveTitle => 'Include subfolders';

  @override
  String get settingScreensaverMediaRecursiveDescription =>
      'Descend into subfolders when a folder is chosen.';

  @override
  String get settingScreensaverMediaTransitionTitle => 'Transition';

  @override
  String get settingScreensaverMediaTransitionDescription =>
      'How one item hands off to the next.';

  @override
  String get settingScreensaverMediaFillTitle => 'Fill the screen';

  @override
  String get settingScreensaverMediaFillDescription =>
      'Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.';

  @override
  String get settingScreensaverMediaEdgeTapsTitle =>
      'Tap edges to change slides';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      'A tap on the left or right fifth of the screen shows the previous or next slide instead of dismissing.';

  @override
  String get settingScreensaverMediaMetadataTitle => 'Show metadata';

  @override
  String get settingScreensaverMediaMetadataDescription =>
      'Date and camera details over the photo.';

  @override
  String get settingScreensaverMediaMetadataDateTitle => 'Date taken';

  @override
  String get settingScreensaverMediaMetadataDateDescription =>
      'Show when the photo was taken.';

  @override
  String get settingScreensaverMediaMetadataCameraTitle => 'Camera details';

  @override
  String get settingScreensaverMediaMetadataCameraDescription =>
      'Show focal length, aperture and ISO.';

  @override
  String get settingScreensaverMediaMetadataPositionTitle =>
      'Metadata position';

  @override
  String get settingScreensaverMediaMetadataPositionDescription =>
      'Which corner the details sit in.';

  @override
  String get settingScreensaverMediaMetadataTextShadowTitle =>
      'Text drop shadow';

  @override
  String get settingScreensaverMediaMetadataTextShadowDescription =>
      'Add a drop shadow to metadata text for readability on photos.';

  @override
  String get settingScreensaverMediaMetadataScaleTitle => 'Text scaling';

  @override
  String get settingScreensaverMediaMetadataScaleDescription =>
      'Scale the photo details to better fit your screen size.';

  @override
  String get settingScreensaverMediaVignetteStrengthTitle =>
      'Vignette strength';

  @override
  String get settingScreensaverMediaVignetteStrengthDescription =>
      'Darkness of the shading behind the details, for readability on bright photos. 0 turns it off.';

  @override
  String get screensaverMediaHaMetadata => 'Home Assistant Media metadata';

  @override
  String get screensaverMediaHaPage => 'Home Assistant Media screensaver';

  @override
  String get screensaverMediaHaPageHint =>
      'Media source, timing, shuffle, fill, metadata';

  @override
  String get screensaverMediaChoose => 'Choose media';

  @override
  String get screensaverMediaRoot => 'Media';

  @override
  String get screensaverMediaHaUnavailable =>
      'Could not reach Home Assistant, or the token is missing.';

  @override
  String get screensaverMediaEmpty => 'Nothing here.';

  @override
  String get screensaverMediaUseFolder => 'Use this folder';

  @override
  String get screensaverMediaFolder => 'folder';

  @override
  String get screensaverMediaCamera => 'camera';

  @override
  String get screensaverMediaItem => 'item';

  @override
  String get screensaverMediaBrowseFailed => 'browse failed';

  @override
  String screensaverMediaBrowseError(String error) {
    return 'Could not browse: $error';
  }

  @override
  String get screensaverMediaNotSet => 'Not set';

  @override
  String get settingScreensaverLocalFolderTitle => 'Local folder';

  @override
  String get settingScreensaverLocalFolderDescription =>
      'Folder on this device whose photos and videos the screensaver cycles through. Picked on the device; the path can also be typed here remotely.';

  @override
  String get settingScreensaverLocalIntervalTitle => 'Seconds per photo';

  @override
  String get settingScreensaverLocalShuffleTitle => 'Shuffle';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      'Cycle the folder in random order instead of by name.';

  @override
  String get settingScreensaverLocalRecursiveTitle => 'Include subfolders';

  @override
  String get settingScreensaverLocalRecursiveDescription =>
      'Also cycle photos and videos inside subfolders.';

  @override
  String get settingScreensaverLocalTransitionTitle => 'Transition';

  @override
  String get settingScreensaverLocalTransitionDescription =>
      'How one photo hands off to the next.';

  @override
  String get settingScreensaverLocalFillTitle => 'Fill the screen';

  @override
  String get settingScreensaverLocalFillDescription =>
      'Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.';

  @override
  String get settingScreensaverLocalEdgeTapsTitle =>
      'Tap edges to change slides';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      'A tap on the left or right fifth of the screen shows the previous or next slide instead of dismissing.';

  @override
  String get settingScreensaverLocalMetadataTitle => 'Show metadata';

  @override
  String get settingScreensaverLocalMetadataDescription =>
      'Date and camera details over the photo.';

  @override
  String get settingScreensaverLocalMetadataDateTitle => 'Date taken';

  @override
  String get settingScreensaverLocalMetadataDateDescription =>
      'Show when the photo was taken.';

  @override
  String get settingScreensaverLocalMetadataCameraTitle => 'Camera details';

  @override
  String get settingScreensaverLocalMetadataCameraDescription =>
      'Show focal length, aperture and ISO.';

  @override
  String get settingScreensaverLocalMetadataPositionTitle =>
      'Metadata position';

  @override
  String get settingScreensaverLocalMetadataPositionDescription =>
      'Which corner the details sit in.';

  @override
  String get settingScreensaverLocalMetadataTextShadowTitle =>
      'Text drop shadow';

  @override
  String get settingScreensaverLocalMetadataTextShadowDescription =>
      'Add a drop shadow to metadata text for readability on photos.';

  @override
  String get settingScreensaverLocalMetadataScaleTitle => 'Text scaling';

  @override
  String get settingScreensaverLocalMetadataScaleDescription =>
      'Scale the photo details to better fit your screen size.';

  @override
  String get settingScreensaverLocalVignetteStrengthTitle =>
      'Vignette strength';

  @override
  String get settingScreensaverLocalVignetteStrengthDescription =>
      'Darkness of the shading behind the details, for readability on bright photos. 0 turns it off.';

  @override
  String get screensaverMediaLocalMetadata => 'Local Media metadata';

  @override
  String get screensaverMediaLocalPage => 'Local Media screensaver';

  @override
  String get screensaverMediaLocalPageHint =>
      'Folder, timing, shuffle, transition, metadata';

  @override
  String get settingScreensaverUrlImageDescription =>
      'An image address the device fetches again for every slide.';

  @override
  String get settingScreensaverUrlIntervalDescription =>
      'How long each photo shows before the next fetch.';

  @override
  String get screensaverMediaUrlPage => 'Image URL screensaver';

  @override
  String get screensaverMediaUrlPageHint => 'URL, timing, transition, metadata';

  @override
  String get screensaverMediaUrlMetadata => 'Image URL metadata';

  @override
  String get settingScreensaverDismissOnMotionTitle => 'Dismiss on motion';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      'Watch the camera while the screensaver is up and wake the screen when someone approaches. The camera runs only during the screensaver.';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle =>
      'Only when screen is off';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      'Keep the screensaver visible when motion is detected while the screen is on. Once the screen turns off, detection wakes the dashboard. Touch still dismisses the screensaver.';

  @override
  String get settingScreensaverPostponeOnMotionTitle =>
      'Postpone screensaver on motion';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      'Delay activating the screensaver when motion is detected. WARNING: Keeps the camera running permanently.';

  @override
  String get screensaverDetectionMotionPage => 'Motion Detection';

  @override
  String get screensaverDetectionMotionHint =>
      'Dismiss or postpone the screensaver on motion';

  @override
  String get screensaverDetectionMotionTuning =>
      'Motion detection is tuned in the Camera settings.';

  @override
  String get settingMotionUseEntityTitle => 'Use Home Assistant entity';

  @override
  String get settingMotionUseEntityDescription =>
      'Detect motion with a Home Assistant sensor instead of the camera.';

  @override
  String get settingMotionEntityTitle => 'Motion sensor entity';

  @override
  String get settingMotionEntityDescription =>
      'The Home Assistant occupancy, motion or presence sensor to follow.';

  @override
  String get screensaverDetectionExternalMotionHeading =>
      'External Motion Sensor';

  @override
  String get settingScreensaverDismissOnPersonTitle => 'Dismiss on person';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      'Read the device\'s person sensor while the screensaver is up and wake the screen when someone is in front of it. Needs the Log access grant below.';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle =>
      'Only when screen is off';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      'Keep the screensaver visible when someone arrives while the screen is on. Once the screen turns off, detection wakes the dashboard. Touch still dismisses the screensaver.';

  @override
  String get settingScreensaverPostponeOnPersonTitle =>
      'Postpone screensaver on person';

  @override
  String get settingScreensaverPostponeOnPersonDescription =>
      'Delay activating the screensaver while someone is in front of the device.';

  @override
  String get screensaverDetectionPersonPage => 'Person Detection';

  @override
  String get screensaverDetectionPersonHint =>
      'Dismiss or postpone the screensaver on the device\'s person sensor';

  @override
  String get screensaverDetectionOccupancy => 'Occupancy';

  @override
  String get screensaverDetectionStatusUnavailable => 'Status unavailable.';

  @override
  String get screensaverDetectionOff => 'Off.';

  @override
  String get screensaverDetectionStarting => 'Starting...';

  @override
  String get screensaverDetectionWaiting =>
      'Waiting for the first heartbeat. The sensor reports every 30 seconds while someone is in view.';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return 'Last heartbeat $ago.';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return '${count}s ago';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return '$count min ago';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return '$count h ago';
  }

  @override
  String get screensaverDetectionDetected => 'Detected';

  @override
  String get screensaverDetectionClear => 'Clear';

  @override
  String get screensaverDetectionPermissions => 'Required system permissions';

  @override
  String get screensaverDetectionLogAccess => 'Log access';

  @override
  String get screensaverDetectionChecking => 'Checking...';

  @override
  String get screensaverDetectionReadable =>
      'The device\'s person sensor can be read.';

  @override
  String get screensaverDetectionRestartRequired =>
      'Granted. Restart Kiosk Satellite to apply it.';

  @override
  String get screensaverDetectionGrantHelp =>
      'This permission can only be granted via ADB. The Meta Portal doc has the full command. Restart Kiosk Satellite afterwards.';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      'This permission can only be granted via ADB. Below is the full command, ready to be copied. Restart Kiosk Satellite afterwards.';

  @override
  String get screensaverDetectionGranted => 'Granted';

  @override
  String get screensaverDetectionMissing => 'Missing';

  @override
  String get screensaverDetectionRestart => 'Restart';

  @override
  String get screensaverDetectionRestartRemote => 'Restart on device';

  @override
  String get screensaverDetectionLogRestart =>
      'Log access is granted but takes effect when Kiosk Satellite restarts.';

  @override
  String get screensaverDetectionLogMissing => 'Log access not granted.';

  @override
  String get settingScreensaverDismissOnProximityTitle =>
      'Dismiss on proximity';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      'Watch the proximity sensor while the screensaver is up and wake the screen when something comes close to the device. A device with only sensors made for calls (\"palm\", \"touch\") will not work.';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle =>
      'Only when screen is off';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      'Keep the screensaver visible when something approaches while the screen is on. Once the screen turns off, detection wakes the dashboard. Touch still dismisses the screensaver.';

  @override
  String get settingScreensaverPostponeOnProximityTitle =>
      'Postpone screensaver on proximity';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      'Delay activating the screensaver while something is close to the sensor.';

  @override
  String get screensaverDetectionProximityPage => 'Proximity Detection';

  @override
  String get screensaverDetectionProximityHint =>
      'Dismiss or postpone the screensaver on the proximity sensor';

  @override
  String get screensaverDetectionNoProximity =>
      'Not available on this device: it has no proximity sensor.';

  @override
  String get screensaverDetectionSensor => 'Sensor';

  @override
  String get screensaverDetectionSensorHelp =>
      'What the device reports as the proximity sensor. A sensor made for calls named \"palm\" or \"touch\" will not work.';

  @override
  String get settingScreensaverScheduleEnabledTitle =>
      'Enable scheduled screensavers';

  @override
  String get settingScreensaverScheduleEnabledDescription =>
      'Switch to a different screensaver at set times of day.';

  @override
  String get settingScreensaverScheduleTitle => 'Times';

  @override
  String get settingScreensaverScheduleDescription =>
      'Each time switches the screensaver from then on.';

  @override
  String get screensaverScheduleSection => 'Scheduled Screensavers';

  @override
  String get screensaverTime => 'Time';

  @override
  String get screensaverAddTime => 'Add time';

  @override
  String get screensaverRemoveTime => 'Remove time';

  @override
  String get screensaverNoTimes => 'No times yet';

  @override
  String get screensaverTimeHelp => 'A screensaver from that time on.';

  @override
  String get screensaverPickTime => 'Pick a time.';

  @override
  String get screensaverDefault => 'Default';

  @override
  String get screensaverOn => 'On';

  @override
  String get screensaverOff => 'Off';

  @override
  String get screensaverBrightness => 'Brightness';

  @override
  String get screensaverBrightnessFollow =>
      'Follows the Screensaver brightness setting.';

  @override
  String get screensaverBrightnessExceptBlack =>
      'Applies to every mode except Black.';

  @override
  String get screensaverScreenOffFollow =>
      'Follows the Turn screen off after setting.';

  @override
  String get screensaverScreenOnHours =>
      'Keeps the screen on during these hours.';

  @override
  String get screensaverScreenOffHelp =>
      'Powers down the display once the screensaver has run this long. Requires Device Administrator permission.';

  @override
  String get screensaverScreenOffNever => 'Screen off never';

  @override
  String get screensaverMotion => 'Dismiss on motion';

  @override
  String get screensaverFace => 'Dismiss on face';

  @override
  String get screensaverProximity => 'Dismiss on proximity';

  @override
  String get screensaverPerson => 'Dismiss on person';

  @override
  String get screensaverWidgets => 'Widgets';

  @override
  String get screensaverGlance => 'At a glance';

  @override
  String get screensaverNowPlaying =>
      'Show Now Playing next to the screensaver';

  @override
  String get screensaverNowPlayingHelp =>
      'Default follows the global layout. On uses a shared layout when Now Playing is enabled. Off hides Now Playing during these hours.';

  @override
  String get screensaverCameraRequired =>
      'Requires the camera. Turn it on in the Camera settings first.';

  @override
  String get screensaverNotAvailable => 'Not available on this device.';

  @override
  String get screensaverSummaryMotionOn => 'Motion on';

  @override
  String get screensaverSummaryMotionOff => 'Motion off';

  @override
  String get screensaverSummaryFaceOn => 'Face on';

  @override
  String get screensaverSummaryFaceOff => 'Face off';

  @override
  String get screensaverSummaryProximityOn => 'Proximity on';

  @override
  String get screensaverSummaryProximityOff => 'Proximity off';

  @override
  String get screensaverSummaryPersonOn => 'Person on';

  @override
  String get screensaverSummaryPersonOff => 'Person off';

  @override
  String get screensaverSummaryWidgetsOn => 'Widgets on';

  @override
  String get screensaverSummaryWidgetsOff => 'Widgets off';

  @override
  String get screensaverSummaryGlanceOn => 'At a glance on';

  @override
  String get screensaverSummaryGlanceOff => 'At a glance off';

  @override
  String get screensaverSummaryNowPlayingOn => 'Now Playing on';

  @override
  String get screensaverSummaryNowPlayingOff => 'Now Playing off';

  @override
  String screensaverBrightnessPercent(String percent) {
    return '$percent% brightness';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return 'Screen off after $minutes min';
  }

  @override
  String get screensaverWeatherMood => 'Weather Mood';

  @override
  String get screensaverWeatherMoodPage => 'Weather Mood screensaver';

  @override
  String get screensaverWeatherMoodSummary =>
      'Weather entity, lightning, preview';

  @override
  String get settingScreensaverWeatherEntityTitle => 'Weather entity';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      'The Home Assistant weather entity that controls the animated scene. Day, dawn/dusk and night follow sun.sun, with local time as a fallback.';

  @override
  String get settingScreensaverWeatherLightningTitle => 'Lightning flashes';

  @override
  String get settingScreensaverWeatherLightningDescription =>
      'Show lightning strikes and cloud flashes during thunderstorms.';

  @override
  String get screensaverWeatherMoodSelectEntity =>
      'Select a weather entity in Settings > Screensaver > Weather Mood.';

  @override
  String get screensaverWeatherPreviewGroup => 'Weather Preview';

  @override
  String get settingScreensaverWeatherPreviewTitle => 'Enable weather preview';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      'Show the selected scene instead of live weather. Turn off to follow Home Assistant again.';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => 'Weather type';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      'The animated weather scene to preview.';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle => 'Time of day';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      'Choose the day, dawn/dusk or night version of the scene.';

  @override
  String get screensaverWeatherPreviewSunny => 'Clear';

  @override
  String get screensaverWeatherPreviewPartlycloudy => 'Partly cloudy';

  @override
  String get screensaverWeatherPreviewCloudy => 'Cloudy';

  @override
  String get screensaverWeatherPreviewRainy => 'Rain';

  @override
  String get screensaverWeatherPreviewPouring => 'Heavy rain';

  @override
  String get screensaverWeatherPreviewSnowy => 'Snow';

  @override
  String get screensaverWeatherPreviewSnowyRainy => 'Snow and rain';

  @override
  String get screensaverWeatherPreviewFog => 'Fog';

  @override
  String get screensaverWeatherPreviewHail => 'Hail';

  @override
  String get screensaverWeatherPreviewLightning => 'Lightning';

  @override
  String get screensaverWeatherPreviewLightningRainy => 'Lightning and rain';

  @override
  String get screensaverWeatherPreviewWindy => 'Wind';

  @override
  String get screensaverWeatherPreviewWindyVariant => 'Wind and clouds';

  @override
  String get screensaverWeatherPreviewExceptional => 'Exceptional weather';

  @override
  String get screensaverWeatherPreviewDay => 'Day';

  @override
  String get screensaverWeatherPreviewNight => 'Night';

  @override
  String get settingScreensaverWeatherClockTitle => 'Enable clock';

  @override
  String get settingScreensaverWeatherClockDescription =>
      'Show a digital clock over the weather scene.';

  @override
  String get screensaverWeatherTextShadowDescription =>
      'Add a drop shadow to text for readability over the weather scene.';

  @override
  String get screensaverWeatherBarGroup => 'Weather information';

  @override
  String get settingScreensaverWeatherBarTitle => 'Enable weather bar';

  @override
  String get settingScreensaverWeatherBarDescription =>
      'Show live weather information along the bottom of the screen.';

  @override
  String get settingScreensaverWeatherBarScaleTitle => 'Text scale';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      'Scale the weather information from 50 to 200 percent.';

  @override
  String get settingScreensaverWeatherBarColorTitle => 'Text color';

  @override
  String get settingScreensaverWeatherBarColorDescription =>
      'The color of the weather information.';

  @override
  String get settingScreensaverWeatherBarOpacityTitle => 'Background opacity';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      'Darken the bottom bar to keep weather information readable.';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => 'Show titles';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      'Name each reading above its value. When off, values match the temperature size.';

  @override
  String get screensaverWeatherBarHighLowDescription =>
      'Show today\'s high and low when the weather entity has a daily forecast.';

  @override
  String get screensaverWeatherBarHumidityDescription =>
      'Show humidity when the weather entity reports it.';

  @override
  String get screensaverWeatherBarWindDescription =>
      'Show wind speed when the weather entity reports it.';

  @override
  String get screensaverWeatherBarVisibilityDescription =>
      'Show visibility when the weather entity reports it.';

  @override
  String get settingScreensaverWeatherBlurTitle => 'Scene blur';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      'Soften the animated weather scene while keeping the clock, weather bar and widgets sharp.';

  @override
  String get screensaverWeatherPreviewTwilight => 'Dawn/Dusk';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      'Show the apparent temperature instead of the actual temperature when available.';

  @override
  String get settingScreensaverWebsiteUrlTitle => 'Website URL';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      'A page to show full-screen. It must allow being embedded.';

  @override
  String get settingScreensaverWebsiteZoomTitle => 'Zoom level';

  @override
  String get settingScreensaverWebsiteZoomDescription =>
      'Scales the whole external screensaver webview.';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle => 'Double tap to dismiss';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription =>
      'Single taps interact with the website instead of dismissing.';

  @override
  String get screensaverWebsiteSection => 'Website screensaver';

  @override
  String get screensaverOverlaySmallClock => 'Small clock';

  @override
  String get screensaverOverlayWeather => 'Weather';

  @override
  String get screensaverOverlayBattery => 'Battery';

  @override
  String get screensaverOverlayClockNote =>
      'Hidden in Digital Clock and Camera Streams screensaver modes.';

  @override
  String get screensaverOverlayCameraNote =>
      'Hidden in the Camera Streams screensaver mode.';

  @override
  String get screensaverOverlayScale => 'Scale';

  @override
  String get screensaverOverlayScaleHelp =>
      'Scale this widget size to better fit your screen.';

  @override
  String get screensaverOverlayFont => 'Font family';

  @override
  String get screensaverOverlayCorner => 'Corner';

  @override
  String get screensaverOverlayWidget => 'Widget';

  @override
  String get screensaverOverlayClock24 => '24-hour clock';

  @override
  String get screensaverOverlayClock24Help =>
      'Show a 24-hour time instead of AM/PM.';

  @override
  String get screensaverOverlayShowDate => 'Show date';

  @override
  String get screensaverOverlayShowDateHelp =>
      'Add a short date under the clock.';

  @override
  String get screensaverOverlayPercentage => 'Show percentage';

  @override
  String get screensaverOverlayPercentageHelp => 'The charge beside the icon.';

  @override
  String get screensaverOverlayLow => 'Only when low';

  @override
  String get screensaverOverlayLowHelp =>
      'Stay hidden until the charge drops to 20 percent.';

  @override
  String get screensaverOverlayShowName => 'Show name';

  @override
  String get screensaverOverlayShowNameHelp => 'The name under the value.';

  @override
  String get screensaverOverlayShowIcon => 'Show icon';

  @override
  String get screensaverOverlayShowIconHelp => 'The icon beside the value.';

  @override
  String get screensaverOverlayVisibleStates => 'Visible states';

  @override
  String get screensaverOverlayVisibleStatesHelp =>
      'Show the widget only when its value is one of these, separated by commas. Leave empty to always show it.';

  @override
  String get screensaverOverlayFontSystem => 'System';

  @override
  String get screensaverOverlayFontSerif => 'Serif';

  @override
  String get screensaverOverlayFontCondensed => 'Condensed';

  @override
  String get screensaverOverlayFontMonospace => 'Monospace';

  @override
  String get screensaverOverlayFontCasual => 'Casual';

  @override
  String get screensaverOverlayFontCursive => 'Cursive';

  @override
  String get screensaverOverlayColor => 'Color';

  @override
  String get screensaverOverlayWeatherEntity => 'Weather entity';

  @override
  String get screensaverOverlayWeatherRequired => 'Pick a weather entity.';

  @override
  String get screensaverOverlayLocationName => 'Location name';

  @override
  String get screensaverOverlayLocationHelp =>
      'Leave empty to hide the location line.';

  @override
  String get screensaverOverlayLocation => 'Location';

  @override
  String get screensaverOverlayLocationDetail =>
      'The place\'s name over the temperature.';

  @override
  String get screensaverOverlayFeelsLike => 'Feels like';

  @override
  String get screensaverOverlayFeelsLikeHelp =>
      'Show the apparent temperature on a labeled line below the actual temperature.';

  @override
  String get screensaverOverlayFeelsLikeOnly => 'Feels like only';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp =>
      'Show the apparent temperature with a Feels like label instead of the actual temperature.';

  @override
  String get screensaverOverlayForecast => 'Forecast';

  @override
  String get screensaverOverlayForecastHelp =>
      'The conditions, with a matching icon.';

  @override
  String get screensaverOverlayHighLow => 'High and low';

  @override
  String get screensaverOverlayHighLowHelp =>
      'Today\'s high and low temperatures.';

  @override
  String get screensaverOverlayForecastWidget => 'Weather forecast';

  @override
  String get screensaverOverlayForecastDays => 'Days shown';

  @override
  String get screensaverOverlayForecastToday => 'Include today';

  @override
  String get screensaverOverlayForecastTodayHelp =>
      'Start the list with today\'s forecast.';

  @override
  String get screensaverOverlayForecastColored => 'Colored icons';

  @override
  String get screensaverOverlayForecastColoredHelp =>
      'Show the weather icons in their own colors.';

  @override
  String get screensaverOverlayHumidity => 'Humidity';

  @override
  String get screensaverOverlayWind => 'Wind speed';

  @override
  String get screensaverOverlayVisibility => 'Visibility';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return 'Feels like $temperature';
  }

  @override
  String get settingScreensaverWidgetsEnabledTitle =>
      'Enable screensaver widgets';

  @override
  String get settingScreensaverWidgetsEnabledDescription =>
      'Small overlays in the corners of the screensaver.';

  @override
  String get settingScreensaverWidgetsTitle => 'Widgets';

  @override
  String get settingScreensaverWidgetsDescription =>
      'Small overlays in the corners of the screensaver.';

  @override
  String get settingScreensaverWidgetScaleTitle => 'Global widget scaling';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      'Scale all widgets together to better fit your screen size. Each widget keeps its own scale relative to the others.';

  @override
  String get settingScreensaverWidgetFontTitle => 'Global font family';

  @override
  String get settingScreensaverWidgetFontDescription =>
      'The typeface every widget is drawn in. A widget can pick its own.';

  @override
  String get settingScreensaverWidgetFontWeightTitle => 'Global font weight';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      'How heavy every widget\'s text is drawn. Default is each line\'s own weight. A widget can pick its own.';

  @override
  String get settingScreensaverWidgetTextShadowTitle => 'Text drop shadow';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      'Add a drop shadow to widget text for readability on photos.';

  @override
  String get settingScreensaverVignetteStrengthTitle => 'Vignette strength';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      'Darkness of the shading behind the widgets, for readability on bright photos. 0 turns it off.';

  @override
  String get screensaverOverlayWidgetsEmpty => 'No widgets yet';

  @override
  String get screensaverOverlayShow => 'Show this widget';

  @override
  String get screensaverOverlayRemove => 'Remove widget';

  @override
  String get screensaverOverlayAdd => 'Add widget';

  @override
  String get screensaverOverlayAddHelp =>
      'A small clock, the weather, the battery or an entity in a corner.';

  @override
  String get screensaverOverlayWidgetsHint => 'Corner overlays and their scale';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String get settingsSearchClear => 'Clear search';

  @override
  String get settingsSearchResults => 'Search results';

  @override
  String settingsSearchEmpty(String query) {
    return 'No settings match \"$query\".';
  }

  @override
  String get searchInstallApk =>
      'Upload a Kiosk Satellite APK through the remote admin and install it.';

  @override
  String get searchPermissionsHelp =>
      'Every Android grant the app can use, with its status: microphone, camera, notifications, unrestricted battery, display over other apps, modify system settings, system UI guard, device admin, all files access, usage access and location.';

  @override
  String get searchServiceStatus => 'Service status';

  @override
  String get searchServiceHelp =>
      'Whether the Kiosk Satellite Service is running and what it is keeping alive.';

  @override
  String get searchServicePermissions =>
      'The grants the Kiosk Satellite Service needs.';

  @override
  String get searchIntercomKiosks =>
      'Known kiosks and whether each can take a call.';

  @override
  String get searchHaValidate =>
      'Check the URL and token against your Home Assistant.';

  @override
  String get searchHaProxy =>
      'Serve a plain-http Home Assistant through a secure proxy inside the app.';

  @override
  String get searchHaDashboard =>
      'Pick the dashboard and view the kiosk shows.';

  @override
  String get searchKioskPermissions =>
      'The grants the kiosk and lockdown protections lean on.';

  @override
  String get searchHomeStatus => 'Home screen status';

  @override
  String get searchHomeHelp =>
      'Whether Kiosk Satellite is the device home screen, and where to finish setting it as the default.';

  @override
  String get searchMasterVolume =>
      'The device volume the media and assistant faders scale under.';

  @override
  String get searchSmallClock =>
      'A clock widget in a corner of the screensaver.';

  @override
  String get searchBattery =>
      'A battery widget in a corner of the screensaver: this device\'s own charge.';

  @override
  String get searchWeatherForecast =>
      'A forecast widget in a corner of the screensaver: the coming days, with their highs and lows.';

  @override
  String get searchPersonPermission =>
      'The Log access grant the device\'s person sensor needs.';

  @override
  String get searchSonosSpeakers =>
      'The Sonos speakers this device knows, a search of the network and an address field.';

  @override
  String get voiceAppearanceHint =>
      'Overlay skin, theme, activity bar, text size';

  @override
  String get voiceSkin => 'Skin';

  @override
  String get voiceSkinHelp => 'The look of the voice assistant overlay.';

  @override
  String get voiceSkin1 => 'Assistant 1 skin';

  @override
  String get voiceSkin1Help =>
      'The look of the overlay when Assistant 1 answers.';

  @override
  String get voiceSkin2 => 'Assistant 2 skin';

  @override
  String get voiceSkin2Help =>
      'The look of the overlay when Assistant 2 answers.';

  @override
  String get voiceTheme => 'Theme mode';

  @override
  String get voiceThemeHelp => 'Light or dark rendering of the overlay.';

  @override
  String get voiceReactive => 'Reactive activity bar';

  @override
  String get voiceReactiveHelp =>
      'The activity bar reacts to audio. NOT RECOMMENDED for low-power devices like the Echo Show.';

  @override
  String get voiceRate => 'Reactive bar update rate';

  @override
  String get voiceRateHelp =>
      'How often the activity bar redraws. Higher is smoother and uses more CPU.';

  @override
  String get voiceScaleHelp => 'The size of the overlay text.';

  @override
  String get voiceUpdateIntegration =>
      'Update the Voice Satellite integration in Home Assistant to control these settings from the kiosk.';

  @override
  String get voiceDashboardRequired =>
      'Available while the kiosk is showing your Home Assistant dashboard.';

  @override
  String get voiceSkinUnavailablePlugin => 'Unavailable plugin skin';

  @override
  String get voiceSkinDefault => 'Skin default';

  @override
  String get voiceBackground => 'Background';

  @override
  String get voiceBackgroundHelp => 'How much of the dashboard shows through.';

  @override
  String get voicePreview => 'Preview';

  @override
  String get voicePreviewHelp =>
      'Show the overlay on this screen for five seconds.';

  @override
  String get voicePreviewRemoteHelp =>
      'Show the overlay on the kiosk screen for five seconds.';

  @override
  String get settingVoiceThemeTitle => 'Theme';

  @override
  String get settingVoiceThemeDescription =>
      'Auto follows the Home Assistant theme.';

  @override
  String get settingVoiceBackgroundDescription =>
      'How much of the dashboard shows through. Skin default at -1.';

  @override
  String get settingVoiceTextScaleTitle => 'Text size';

  @override
  String get settingVoiceReactiveBarTitle => 'Reactive activity bar';

  @override
  String get settingVoiceReactiveBarDescription =>
      'The bar follows your voice and the answer.';

  @override
  String get voicePreviewCommand => 'What is the weather?';

  @override
  String get voicePreviewAnswer =>
      'Sunny and 72° right now, with a light breeze.';

  @override
  String get settingVoiceOverlayModeTitle => 'Overlay mode';

  @override
  String get settingVoiceOverlayModeDescription =>
      'Docked shows a small bubble over the dashboard. It does not show rich results such as images, weather or videos.';

  @override
  String get voiceOverlayFullScreen => 'Full screen';

  @override
  String get voiceOverlayDocked => 'Docked';

  @override
  String get voiceListeningEllipsis => 'Listening…';

  @override
  String get voiceSkinVoiceOnly => 'Voice Only';

  @override
  String get voiceAssistant1 => 'Assistant 1';

  @override
  String get voiceAssistant1Help => 'Answers wake word 1.';

  @override
  String get voiceAssistant2 => 'Assistant 2';

  @override
  String get voiceAssistant2Help => 'Answers wake word 2.';

  @override
  String get voicePipelines => 'Pipelines';

  @override
  String get voicePreferred => 'Preferred';

  @override
  String get voiceNone => 'None';

  @override
  String get voiceThisKiosk => 'This kiosk';

  @override
  String get voiceSelectFailed => 'Could not change it in Home Assistant.';

  @override
  String get settingVoiceSeamlessWakeTitle => 'Talk right after the wake word';

  @override
  String get settingVoiceSeamlessWakeAssistDescription =>
      'Skip the wake sound and keep what you say right after the wake word. Only for Assist pipelines, not realtime conversations.';

  @override
  String get settingVoiceFollowupDelayTitle => 'Follow-up delay';

  @override
  String get settingVoiceFollowupDelayDescription =>
      'A pause before listening for the answer to a question.';

  @override
  String get settingVoiceFollowupChimeTitle => 'Chime before a follow-up';

  @override
  String get settingVoiceFollowupChimeDescription =>
      'Play the wake sound when it starts listening again.';

  @override
  String get settingVoiceTtsOutputTitle => 'Play sounds on';

  @override
  String get settingVoiceTtsOutputDescription =>
      'Chimes, answers, announcements and timer alerts play on this speaker.';

  @override
  String get settingVoiceTtsOutputModeTitle => 'Play as';

  @override
  String get settingVoiceTtsOutputModeDescription =>
      'An announcement lets the speaker pause its music and resume it. Normal playback starts the music again afterward, for speakers that ignore announcements.';

  @override
  String get voiceOptionAnnouncement => 'Announcement';

  @override
  String get voiceOptionNormalPlayback => 'Normal playback';

  @override
  String get voiceChimesPage => 'Chimes';

  @override
  String get voiceChimesPreview => 'Preview on kiosk';

  @override
  String get voiceChimesPreviewFailed => 'Could not play the sound.';

  @override
  String get voiceChimesHelp =>
      'Choose sounds for this kiosk. Upload custom files here. Sounds stored in Home Assistant are not used for local chimes.';

  @override
  String get voiceChimeWakeTitle => 'Wake sound';

  @override
  String get voiceChimeWakeDescription =>
      'Plays when Voice Satellite starts listening.';

  @override
  String get voiceChimeDoneTitle => 'Done sound';

  @override
  String get voiceChimeDoneDescription =>
      'Plays when a voice interaction finishes.';

  @override
  String get voiceChimeErrorTitle => 'Error sound';

  @override
  String get voiceChimeErrorDescription =>
      'Plays when a voice interaction fails.';

  @override
  String get voiceChimeTimerTitle => 'Timer sound';

  @override
  String get voiceChimeTimerDescription =>
      'Repeats when a timer finishes until you dismiss it.';

  @override
  String get voiceChimeAnnounceTitle => 'Announcement sound';

  @override
  String get voiceChimeAnnounceDescription =>
      'Plays before a Voice Satellite announcement unless it supplies its own sound.';

  @override
  String get settingVoiceWakeSoundTitle => 'Play chimes';

  @override
  String get settingVoiceWakeSoundDescription =>
      'The wake, done and error sounds.';

  @override
  String get voiceChimeWakeVolumeTitle => 'Wake sound volume';

  @override
  String get voiceChimeDoneVolumeTitle => 'Done sound volume';

  @override
  String get voiceChimeErrorVolumeTitle => 'Error sound volume';

  @override
  String get voiceChimeTimerVolumeTitle => 'Timer sound volume';

  @override
  String get voiceChimeAnnounceVolumeTitle => 'Announcement sound volume';

  @override
  String get voiceChimeVolumeDescription => 'A share of the assistant volume.';

  @override
  String get voiceChimesSoundsHint =>
      'Wake, done, error and announcement sounds';

  @override
  String get settingVoiceShowCommandTitle => 'Show what you said';

  @override
  String get settingVoiceShowCommandDescription =>
      'Your command above the answer.';

  @override
  String get settingVoiceShowAnswerTitle => 'Show the answer';

  @override
  String get settingVoiceShowAnswerDescription => 'The answer as it is spoken.';

  @override
  String get settingVoiceShowToolsTitle => 'Show tool use';

  @override
  String get settingVoiceShowToolsDescription =>
      'A line for each action the assistant takes.';

  @override
  String get settingVoiceHideSentimentTagsTitle => 'Hide sentiment tags';

  @override
  String get settingVoiceHideSentimentTagsDescription =>
      'Leave out tags like [happy] that some assistants add.';

  @override
  String get settingVoiceAnswerLingerTitle => 'Keep the answer on screen';

  @override
  String get settingVoiceAnswerLingerDescription =>
      'After the answer is spoken.';

  @override
  String get settingVoiceResultsLingerTitle => 'Keep results on screen';

  @override
  String get settingVoiceResultsLingerDescription =>
      'Images, weather and other results. 0 keeps them until you dismiss them.';

  @override
  String get settingVoiceAnnouncementLingerTitle => 'Announcement time';

  @override
  String get settingVoiceAnnouncementLingerDescription =>
      'After an announcement is spoken.';

  @override
  String get voiceEngine => 'Engine';

  @override
  String get voiceEngineHelp => 'Start or Stop the Voice Satellite engine.';

  @override
  String get voiceAssigned => 'Assigned satellite';

  @override
  String get voiceAssignedHelp =>
      'The assist_satellite entity this kiosk identifies as in Home Assistant. Changing it reloads the dashboard.';

  @override
  String get voiceAssignedSearch =>
      'The assist_satellite entity this kiosk identifies as in Home Assistant.';

  @override
  String get voiceNoneAssigned => 'None assigned';

  @override
  String get voiceAutoStart => 'Auto start';

  @override
  String get voiceAutoStartHelp =>
      'Auto start Voice Satellite on dashboard load.';

  @override
  String get voiceMuteHelp => 'Stop listening for wake words.';

  @override
  String get voicePipeline1 => 'Assist pipeline 1';

  @override
  String get voicePipeline1Help =>
      'The Assist pipeline voice commands run through.';

  @override
  String get voicePipeline2 => 'Assist pipeline 2';

  @override
  String get voicePipeline2Help =>
      'The pipeline used when the second wake word triggers.';

  @override
  String get voiceVad => 'Finished speaking detection';

  @override
  String get voiceVadHelp => 'How long a pause ends a voice command.';

  @override
  String get voiceMutedWarning => 'Disable muted microphone warning';

  @override
  String get voiceMutedWarningHelp =>
      'Hide the muted microphone warning at startup and whenever the satellite microphone is muted.';

  @override
  String get voiceDebug => 'Debug logging';

  @override
  String get voiceDebugHelp =>
      'Show Voice Satellite debug info in the browser console.';

  @override
  String get voiceVersion => 'Voice Satellite version';

  @override
  String get voiceVersionHelp =>
      'The integration version installed in Home Assistant.';

  @override
  String get voiceVadDefault => 'Default';

  @override
  String get voiceVadRelaxed => 'Relaxed';

  @override
  String get voiceVadAggressive => 'Aggressive';

  @override
  String get voiceGeneral => 'General';

  @override
  String get voiceStart => 'Start';

  @override
  String get voiceNotavailable => 'Not available';

  @override
  String get voiceDisabled => 'Disabled';

  @override
  String get settingWakeWordBackgroundTitle =>
      'Keep listening in the background';

  @override
  String get settingWakeWordBackgroundDescription =>
      'Keep hearing the wake word while another app is in front, and return on a detection. Needs a permanent notification and display over other apps.';

  @override
  String get settingWakeWordReturnToBackgroundTitle =>
      'Return to the previous app';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      'Return to the previous app or home screen after a voice interaction brings Kiosk Satellite forward and finishes.';

  @override
  String get voiceAssistant => 'Assistant';

  @override
  String get voiceConversation => 'Conversation';

  @override
  String get voiceTimers => 'Timers';

  @override
  String get voiceAssistantHint => 'Pipelines, follow-ups';

  @override
  String get voiceConversationHint => 'What the overlay shows and for how long';

  @override
  String get voiceSectionFollowUp => 'Follow-up';

  @override
  String get voiceSectionLinger => 'How long it stays';

  @override
  String get voiceSectionOnScreen => 'On screen';

  @override
  String get voiceSectionPills => 'Pills';

  @override
  String get voiceSectionSpeaker => 'Speaker';

  @override
  String get voiceSectionWakeCommand => 'Wake word and command';

  @override
  String get voiceSectionTimerEnds => 'When a timer ends';

  @override
  String get voiceSectionSharedTimers => 'Shared timers';

  @override
  String get voiceStatusEsphomeOff => 'The ESPHome server is off.';

  @override
  String get voiceStatusNotAdded =>
      'This kiosk is not added to Home Assistant yet.';

  @override
  String get voiceStatusMuted => 'The microphone is muted.';

  @override
  String get voiceStatusNotListening => 'The wake word is not listening.';

  @override
  String get voiceStatusListening => 'Listening for the wake word.';

  @override
  String get voiceWordNotAdded => 'Not added';

  @override
  String get voiceWordMuted => 'Muted';

  @override
  String get voiceWordBusy => 'Busy';

  @override
  String get voiceWordListening => 'Listening';

  @override
  String get voiceWordNotListening => 'Not listening';

  @override
  String get voiceWordAdded => 'Added';

  @override
  String get voiceHaAddAgainHint =>
      'Add this kiosk under Settings, Devices & services in Home Assistant, where it shows up as discovered. If Home Assistant had it before, it asks there for the new Encryption key from the ESPHome page.';

  @override
  String get voiceHaEsphomeOff =>
      'Turn on the ESPHome server so Home Assistant can add this kiosk as a satellite.';

  @override
  String get voiceWordReloadNeeded => 'Reload needed';

  @override
  String get voiceHaSelectsReloadHint =>
      'Home Assistant has not loaded the Assistant and Wake word selects. Reload this kiosk\'s ESPHome entry under Settings, Devices & services. Restarting Home Assistant also works.';

  @override
  String get voiceTurnOn => 'Turn on';

  @override
  String get voiceRollbackTitle => 'Run from the dashboard again';

  @override
  String get voiceRollbackDescription =>
      'Go back to the Voice Satellite integration. Nothing set here is lost.';

  @override
  String get voiceRollbackConfirm => 'Run from the dashboard again?';

  @override
  String get voiceRollbackBody =>
      'The dashboard runs Voice Satellite again through the integration, with the settings it had before. What you set here stays for next time.';

  @override
  String get voiceRollbackSwitch => 'Switch back';

  @override
  String get voiceMigrateNotice =>
      'Voice Satellite is currently installed as an integration in Home Assistant. Migrate to a native experience inside Kiosk Satellite.';

  @override
  String get voiceMigrate => 'Migrate';

  @override
  String get settingVoiceEnabledTitle => 'Enable Voice Satellite';

  @override
  String get settingVoiceEnabledDescription =>
      'Turns this kiosk into a voice assistant for Home Assistant through its ESPHome server.';

  @override
  String get settingVoiceMuteTitle => 'Mute microphone';

  @override
  String get settingVoiceMuteDescription => 'Stop listening for the wake word.';

  @override
  String get voiceMigrationTitle => 'Migrate Voice Satellite';

  @override
  String get voiceMigrationPick =>
      'Pick the Voice Satellite integration\'s satellite this kiosk takes over. Its settings come over to this kiosk.';

  @override
  String get voiceMigrationNoSatellites =>
      'The Voice Satellite integration has no satellites.';

  @override
  String get voiceMigrationIntro =>
      'This kiosk becomes the voice satellite itself. The Voice Satellite integration is not needed after this.';

  @override
  String get voiceMigrationCheckAgain => 'Check again';

  @override
  String get voiceCheckHaBad => 'Not connected. Check Home Assistant Setup.';

  @override
  String get voiceCheckEsphome => 'This kiosk in Home Assistant';

  @override
  String get voiceCheckEsphomeOk => 'Added through ESPHome.';

  @override
  String get voiceCheckEsphomeBad =>
      'Not added yet. Home Assistant lists this kiosk as discovered under Settings, Devices & services. Add it there, then come back.';

  @override
  String get voiceCheckEsphomeOff =>
      'The ESPHome server is off. Turn it on, then add this kiosk in Home Assistant.';

  @override
  String get voiceCheckAdmin => 'Administrator token';

  @override
  String get voiceCheckAdminOk => 'Tool use and results will show.';

  @override
  String get voiceCheckAdminBad =>
      'The token is a regular user\'s. Voice Satellite works, tool use and results will not show.';

  @override
  String get voiceCheckAdminUnknown =>
      'Could not check the token. Tool use and results need an administrator\'s.';

  @override
  String get voiceCheckMicOk => 'Allowed.';

  @override
  String get voiceCheckMicBad =>
      'Not allowed. Grant it under Required system permissions.';

  @override
  String get voiceTurnOnEsphome => 'Turn on ESPHome';

  @override
  String get voiceMigrationPlan => 'Settings to bring over';

  @override
  String get voiceGroupVoice => 'Voice';

  @override
  String get voiceMigrationNotCarried =>
      'Not carried over: custom CSS, the browser microphone processing and the conversation memory length. Custom microWakeWord models work from config/custom_wake_words in Home Assistant.';

  @override
  String get voiceMigrationAutomations => 'Automations and scripts';

  @override
  String get voiceMigrationNoAutomations =>
      'Nothing in Home Assistant points at the old satellite.';

  @override
  String get voiceKindAutomation => 'Automation';

  @override
  String get voiceKindScript => 'Script';

  @override
  String get voiceMigrationReady => 'Ready to switch';

  @override
  String get voiceMigrationReady1 =>
      'This kiosk listens, answers and draws the overlay.';

  @override
  String get voiceMigrationReadyOnboarding =>
      'Its Assistant and wake words are set once Home Assistant adds this kiosk.';

  @override
  String get voiceMigrationReady2 =>
      'The dashboard stops running Voice Satellite on this kiosk.';

  @override
  String get voiceMigrationReady3 =>
      'The old satellite stays in Home Assistant, unused.';

  @override
  String get voiceMigrationSwitch => 'Switch now';

  @override
  String get voiceMigrationSwitching => 'Switching…';

  @override
  String get voiceMigrationDone => 'Voice Satellite runs here now';

  @override
  String get voiceCouldNotSwitch => 'Could not switch';

  @override
  String get voiceMigrationDoneOnboarding =>
      'Finish the setup, then add this kiosk in Home Assistant. Once no other device uses the Voice Satellite integration, uninstall it from HACS.';

  @override
  String get voiceMigrationDoneHelp =>
      'Say the wake word to try it. Once no other device uses the Voice Satellite integration, uninstall it from HACS.';

  @override
  String get voiceMigrationRolledBack =>
      'Voice Satellite runs from the dashboard again.';

  @override
  String get voiceDone => 'Done';

  @override
  String get voiceTryAgain => 'Try again';

  @override
  String get voiceStepSave => 'Save the settings';

  @override
  String get voiceStepStop => 'Stop the dashboard engine';

  @override
  String get voiceStepStart => 'Start listening here';

  @override
  String get voiceStepTurnOn => 'Turn on Voice Satellite on this kiosk';

  @override
  String get voiceStepEntities => 'Set the kiosk\'s entities in Home Assistant';

  @override
  String get voiceStepCheck => 'Check the satellite in Home Assistant';

  @override
  String voiceMigrationStep(String n, String total) {
    return 'Step $n of $total';
  }

  @override
  String voiceMigrationStillPoint(String satellite) {
    return 'These still point at $satellite. Edit them in Home Assistant to use this kiosk\'s satellite. The wizard does not change them.';
  }

  @override
  String get voiceMigrationNotUp => 'The satellite did not come up in time.';

  @override
  String get voiceMigrationNotReported =>
      'Home Assistant did not report the satellite.';

  @override
  String get voiceMigrationBusy => 'A migration is already running.';

  @override
  String get voiceMicHeld => 'Wake word detection can hear you.';

  @override
  String get voiceMicBlocked =>
      'Blocked. Android will not ask again, so allow it in the app settings.';

  @override
  String get voiceMicMissing =>
      'Without this nothing is listening for the wake word.';

  @override
  String get voiceForegroundHeld =>
      'Kiosk Satellite can come forward when it hears you.';

  @override
  String get voiceForegroundMissing =>
      'Without this the wake word is heard and nothing happens.';

  @override
  String get voiceNotificationHeld =>
      'The ongoing notification that enables background listening.';

  @override
  String get voiceNotificationMissing =>
      'Needed for background listening to work reliably.';

  @override
  String get voiceBatteryHeld => 'Android will leave the listener running.';

  @override
  String get voiceBatteryMissing =>
      'Without this the listener is stopped after a few hours.';

  @override
  String get voicePermissionDirections =>
      'Grant these on the device itself: swipe in from the left edge → Settings → Voice Satellite → Required system permissions.';

  @override
  String get voicePermissionsSearch =>
      'Microphone and the other grants wake word detection needs.';

  @override
  String get voiceRealtime => 'Realtime';

  @override
  String get voiceRealtimeProvidersHint =>
      'OpenAI, xAI Grok, Gemini, tools, talk over answers';

  @override
  String get voiceRealtimeToolsSection => 'Home Assistant tools';

  @override
  String get voiceRealtimeProviderDefault => 'Provider default';

  @override
  String get voiceRealtimeToolsCustom => 'Custom MCP server';

  @override
  String get settingVoiceRealtimeEndpointTitle => 'Endpoint';

  @override
  String get settingVoiceRealtimeEndpointDescription =>
      'Leave empty to use the provider. Use a relay on your network to keep this kiosk offline.';

  @override
  String get settingVoiceRealtimeApiKeyTitle => 'API key';

  @override
  String get settingVoiceRealtimeApiKeyDescription =>
      'Leave empty when a relay adds it.';

  @override
  String get settingVoiceRealtimeModelTitle => 'Model';

  @override
  String get settingVoiceRealtimeVoiceTitle => 'Voice';

  @override
  String get settingVoiceRealtimeInstructionsTitle => 'Instructions';

  @override
  String get settingVoiceRealtimeInstructionsDescription =>
      'How the assistant behaves. Leave empty for a short default.';

  @override
  String get settingVoiceRealtimeIdleSecondsTitle => 'End after silence';

  @override
  String get settingVoiceRealtimeIdleSecondsDescription =>
      'The conversation ends after this long with nobody talking.';

  @override
  String get settingVoiceRealtimeReasoningTitle => 'Reasoning effort';

  @override
  String get settingVoiceRealtimeReasoningDescription =>
      'More effort answers harder questions better. Needs a gpt-realtime-2 model.';

  @override
  String get settingVoiceRealtimeGeminiReasoningDescription =>
      'More effort answers harder questions better. Needs a model that thinks, such as gemini-3.8-live-extended-thinking.';

  @override
  String get settingVoiceRealtimeGeminiSearchTitle => 'Google Search';

  @override
  String get settingVoiceRealtimeGeminiSearchBillingDescription =>
      'Lets the model look things up on the web. Needs billing turned on for the API key.';

  @override
  String get settingVoiceRealtimeGeminiProactiveTitle =>
      'Ignore talk not meant for it';

  @override
  String get settingVoiceRealtimeGeminiProactiveDescription =>
      'The model stays quiet when what it hears is not addressed to it. Experimental at Google.';

  @override
  String get settingVoiceRealtimeXaiWebSearchTitle => 'Web Search';

  @override
  String get settingVoiceRealtimeXaiWebSearchDescription =>
      'Lets the model look things up on the web.';

  @override
  String get settingVoiceRealtimeXaiXSearchTitle => 'X Search';

  @override
  String get settingVoiceRealtimeXaiXSearchDescription =>
      'Lets the model search posts on X.';

  @override
  String get voiceRealtimeReasoningDefault => 'Model default';

  @override
  String get voiceRealtimeReasoningMinimal => 'Minimal';

  @override
  String get voiceRealtimeReasoningLow => 'Low';

  @override
  String get voiceRealtimeReasoningMedium => 'Medium';

  @override
  String get voiceRealtimeReasoningHigh => 'High';

  @override
  String get voiceRealtimeReasoningExtraHigh => 'Extra high';

  @override
  String get settingVoiceRealtimeSpeedTitle => 'Speech speed';

  @override
  String get settingVoiceRealtimeSpeedDescription =>
      'How fast the assistant talks.';

  @override
  String get settingVoiceRealtimeHistoryHoursTitle => 'Session duration';

  @override
  String get settingVoiceRealtimeHistoryHoursDescription =>
      'What was said within this time carries into the next conversation.';

  @override
  String get settingVoiceRealtimeTalkOverTitle => 'Talk over answers';

  @override
  String get settingVoiceRealtimeTalkOverDescription =>
      'Interrupt an answer by speaking. Turn off if it interrupts itself.';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityTitle =>
      'Talk over sensitivity';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityDescription =>
      'How easily speaking interrupts an answer. Raise it if interrupting does not work on a quiet microphone. Higher values can make it interrupt itself.';

  @override
  String get settingVoiceRealtimeToolsTitle => 'Tools';

  @override
  String get settingVoiceRealtimeToolsDescription =>
      'What the assistant can control. Home Assistant uses its MCP Server integration and the entities exposed to Assist.';

  @override
  String get settingVoiceRealtimeMcpUrlTitle => 'MCP server URL';

  @override
  String get settingVoiceRealtimeMcpUrlDescription =>
      'The server\'s Streamable HTTP address.';

  @override
  String get settingVoiceRealtimeMcpTokenTitle => 'MCP token';

  @override
  String get settingVoiceRealtimeMcpTokenDescription =>
      'Sent as a bearer token. Leave empty when the server needs none.';

  @override
  String get voiceRealtimeMcpMissing =>
      'Add the MCP Server integration in Home Assistant to control your home.';

  @override
  String get voiceRealtimeNotValidated => 'Not validated';

  @override
  String voiceRealtimeOption(String provider) {
    return '$provider Realtime';
  }

  @override
  String voiceRealtimeConnectFailed(String error) {
    return 'Could not connect: $error';
  }

  @override
  String voiceRealtimeToolsUnavailable(String problem) {
    return 'Connected, but the Home Assistant tools are unavailable: $problem';
  }

  @override
  String get settingVoiceRealtimeModelDescription =>
      'The speech to speech model that answers.';

  @override
  String get settingVoiceRealtimeVoiceDescription =>
      'How the assistant sounds.';

  @override
  String get voiceRealtimeProviders => 'Providers';

  @override
  String get voiceRealtimeConfigure => 'Configure';

  @override
  String get voiceRealtimeSaveValidate => 'Save & Validate';

  @override
  String get voiceRealtimeNotConfigured => 'Not configured';

  @override
  String get voiceRealtimeValidated => 'Connection validated';

  @override
  String get voiceDisconnected => 'Home Assistant not connected';

  @override
  String get voiceValidate =>
      'Validate the connection under Home Assistant Setup first.';

  @override
  String get voiceChecking => 'Checking for Voice Satellite…';

  @override
  String get voiceMissing =>
      'Voice Satellite is not installed in Home Assistant';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite turns this kiosk into a full hands-free voice assistant for Home Assistant: wake word detection, conversations, timers and announcements, right on the dashboard.\n\nIt is available in the default HACS repository. Install it on your Home Assistant instance, then come back here.';

  @override
  String get voiceLearnMore => 'Learn more about ';

  @override
  String get voiceGithub => 'Voice Satellite on Github';

  @override
  String get voiceHacs => 'Open HACS repository';

  @override
  String get voiceLoading => 'Loading Voice Satellite controls…';

  @override
  String get voiceTester => 'Wake Word Tester';

  @override
  String get voiceTesterHelp =>
      'Watch what the engine hears and scores in real time, to see why the wake word is or is not triggering.';

  @override
  String get voiceTesterSearch =>
      'A live look at what the engine hears and scores.';

  @override
  String get voiceTesterWaiting => 'Waiting for Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word (stop word)';
  }

  @override
  String get voiceScore => 'Score';

  @override
  String get voiceThreshold => 'Threshold';

  @override
  String get voiceHits => 'Hits';

  @override
  String get voiceNearMisses => 'Near misses';

  @override
  String get voicePeak => 'Peak';

  @override
  String get voiceMicLevel => 'Mic level';

  @override
  String get voiceChunkProcessing => 'Chunk processing (min / avg / max)';

  @override
  String get voiceLog => 'Log';

  @override
  String get voiceLogEmpty => 'Detections and near misses will appear here.';

  @override
  String get voiceLogHit => 'HIT';

  @override
  String get voiceLogNear => 'near';

  @override
  String get voiceLogScore => 'score';

  @override
  String get voiceLogDecoded => 'decoded';

  @override
  String get voiceLogDistance => 'ed';

  @override
  String get voiceLogConfidence => 'conf';

  @override
  String get voiceTesterPlayRecent => 'Play last 10 seconds';

  @override
  String get settingVoiceTimerPillsViewTitle => 'Show timers as pills';

  @override
  String get settingVoiceTimerPillsViewDescription =>
      'Timers float over the screen instead of opening the full screen view.';

  @override
  String get settingVoiceTimerNameInPillTitle => 'Show the timer name';

  @override
  String get settingVoiceTimerNameInPillDescription =>
      'The name beside the time in a pill.';

  @override
  String get settingVoiceTimerPillScaleTitle => 'Timer pill scale';

  @override
  String get settingVoiceTimerPillScaleDescription =>
      'The size of the timer pills.';

  @override
  String get settingVoiceTimerAlertPillTitle => 'Show finished timer pills';

  @override
  String get settingVoiceTimerAlertPillDescription =>
      'Tap the pill to stop the alert.';

  @override
  String get settingVoiceMuteTimersTitle => 'Mute timer alerts';

  @override
  String get settingVoiceMuteTimersDescription =>
      'Show the alert without the sound.';

  @override
  String get settingVoiceTimerNameOnAlertTitle => 'Show the name on the alert';

  @override
  String get settingVoiceTimerNameOnAlertDescription =>
      'The timer name under the alert.';

  @override
  String get settingVoiceTimerSpeakTitle => 'Speak when a timer ends';

  @override
  String get settingVoiceTimerSpeakDescription =>
      'Say a phrase between the alert sounds.';

  @override
  String get settingVoiceTimerPhraseTitle => 'Phrase';

  @override
  String get settingVoiceTimerPhraseDescription =>
      'Spoken for a timer without a name.';

  @override
  String get settingVoiceTimerNamedPhraseTitle => 'Phrase for named timers';

  @override
  String settingVoiceTimerNamedPhraseDescription(String name) {
    return '$name is replaced with the timer name.';
  }

  @override
  String get settingVoiceTimersShareTitle => 'Share timers';

  @override
  String get settingVoiceTimersShareDescription =>
      'Timers started on this kiosk also run on the kiosks you pick.';

  @override
  String get settingVoiceTimersShareWithTitle => 'Share with';

  @override
  String get settingVoiceTimersShareWithDescription =>
      'The kiosks that show and ring the timers of this one.';

  @override
  String get settingVoiceTimersReceiveTitle => 'Show shared timers';

  @override
  String get settingVoiceTimersReceiveDescription =>
      'Timers shared by other kiosks show and ring here.';

  @override
  String get settingKioskAllowTimersTitle => 'Timers';

  @override
  String get settingKioskAllowTimersDescription =>
      'Open the timers view from the kiosk menu.';

  @override
  String get settingsMenuTimersSummary =>
      'Full screen view, pills, shared timers';

  @override
  String get fleetTheKiosksPickedInShareWithTheTimerSound =>
      'the kiosks picked in Share with, the timer sound';

  @override
  String get settingTimersTtsEngineDescription =>
      'The Home Assistant text to speech entity that speaks timers.';

  @override
  String get settingTimersTtsLanguageDescription =>
      'The language timers are spoken in.';

  @override
  String get settingTimersTtsVoiceDescription =>
      'The voice that speaks timers.';

  @override
  String get settingTimersShowBeforeEndTitle =>
      'Show Timers view when near completion';

  @override
  String get settingTimersShowBeforeEndDescription =>
      'How long before a timer ends the Timers view opens.';

  @override
  String get settingTimersShowOnStartTitle =>
      'Show Timers view when a timer starts';

  @override
  String get settingTimersShowOnStartDescription =>
      'Open the Timers view each time a timer is started.';

  @override
  String get settingTimersPauseScreensaverTitle =>
      'Pause screensaver while a timer runs';

  @override
  String get settingTimersPauseScreensaverDescription =>
      'Keep the screensaver from starting while the Timers view shows a running timer.';

  @override
  String get voiceWakePage => 'Wake Word';

  @override
  String get voiceWakeHint => 'Engine, wake words, sensitivity, cached models';

  @override
  String get voiceWakeLabel => 'Wake word';

  @override
  String get voiceWakeEngine => 'Wake word engine';

  @override
  String get voiceWakeEngineHelp =>
      'Where detection runs and which engine listens.';

  @override
  String get voiceWake1 => 'Wake word 1';

  @override
  String get voiceWake1Help => 'The word that starts a voice command.';

  @override
  String get voiceWake2 => 'Wake word 2';

  @override
  String get voiceWake2Help =>
      'A second wake word, answered by Assist pipeline 2.';

  @override
  String get voiceSensitivity => 'Wake word sensitivity';

  @override
  String get voiceSensitivityHelp => 'How easily the wake word triggers.';

  @override
  String get voiceNoiseGate => 'Wake word noise gate';

  @override
  String get voiceNoiseGateHelp =>
      'Skip local wake word inference while the room is quiet, saving CPU.';

  @override
  String get voiceStopInterruption => 'Stop word interruption';

  @override
  String get voiceStopInterruptionHelp =>
      'Say the stop word to interrupt responses.';

  @override
  String get voiceAssignFirst =>
      'Assign a satellite to control these settings.';

  @override
  String get voiceCachedModels => 'Cached models';

  @override
  String get voiceCachedModelsHelp =>
      'Re-download from Home Assistant. Use after re-publishing a model.';

  @override
  String get voiceClearCache => 'Clear cache';

  @override
  String get voiceClearing => 'Clearing…';

  @override
  String voiceCacheCleared(String count) {
    return 'Files cleared: $count. Downloading again.';
  }

  @override
  String voiceCacheCount(String count) {
    return 'Cleared $count';
  }

  @override
  String get voiceVerySensitive => 'Very sensitive';

  @override
  String get voiceWakeWordPreferFp32Title => 'Prefer fp32 vsWakeWord models';

  @override
  String get voiceWakeWordPreferFp32Description =>
      'Uses fp32 models instead of smaller int8 versions. Adds 10-30% more CPU usage while listening to avoid about 2% confidence drift.';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle =>
      'Resume timeout (seconds)';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      'Self-heal: resume listening if the page never calls setWakeWordActive(true) after a handoff. Waits while a voice turn is still streaming audio, so a long turn is never cut short.';

  @override
  String get voiceSlightlySensitive => 'Slightly sensitive';

  @override
  String get voiceModeratelySensitive => 'Moderately sensitive';

  @override
  String get voiceOnDevice => 'On Device';

  @override
  String voiceOnDeviceEngine(String engine) {
    return 'On device ($engine)';
  }

  @override
  String get voiceDiagnosticsPage => 'Wake word diagnostics';

  @override
  String get voiceDiagnosticsHint =>
      'Recent activations and near misses with audio clips';

  @override
  String get voiceDiagnosticsTitle => 'Enable wake word diagnostics';

  @override
  String get voiceDiagnosticsDescription =>
      'Records the last 10 wake word activations and near misses with their scores and a 3 second audio clip of each. Turning this off deletes them.';

  @override
  String get voiceDiagnosticsEmpty => 'No wake word activations recorded yet.';

  @override
  String get voiceDiagnosticsActivations => 'Activations';

  @override
  String get voiceDiagnosticsNoNearMisses => 'No near misses recorded yet.';

  @override
  String get voiceDiagnosticsPeakLevel => 'Peak level';

  @override
  String get voiceDiagnosticsAverageLevel => 'Average level';

  @override
  String get voiceDiagnosticsClipped => 'Clipped';

  @override
  String get voiceDiagnosticsHeard => 'Heard';

  @override
  String get voiceWake2HelpNative =>
      'A second wake word, answered by Assistant 2.';

  @override
  String get voiceCustomModels => 'Custom Models';

  @override
  String get voiceCustomNone => 'No custom models yet.';

  @override
  String get voiceCustomManaged =>
      'The fleet leader manages the custom models on this kiosk.';

  @override
  String get voiceCustomAdd => 'Add models';

  @override
  String get voiceCustomAddHelp =>
      'Pick the files of one or more models. They show up in Wake word 1 and 2 above.';

  @override
  String get voiceCustomDocs => 'How to add custom models';

  @override
  String get voiceCustomDocsHelp =>
      'The files each engine needs and where the models come from.';

  @override
  String get voiceCustomNotAdded => 'The models were not added.';

  @override
  String get voiceCustomSomeNotAdded => 'Some files were not added.';

  @override
  String get voiceCustomAdded => 'Models added.';

  @override
  String get voiceCustomDeleteConfirm => 'Delete this model?';

  @override
  String get voiceCustomNotDeleted => 'The model was not deleted.';

  @override
  String get voiceCustomOtherEngine => 'not the engine in use';

  @override
  String get settingVoiceWakeWordEngineDescription =>
      'Which engine listens. All models ship with the app.';

  @override
  String get settingVoiceWakeWordSensitivityTitle => 'Wake word sensitivity';

  @override
  String get settingVoiceWakeWordSensitivityDescription =>
      'How easily the wake word triggers.';

  @override
  String get settingVoiceWakeWordFineTuneTitle => 'Fine-tune sensitivity';

  @override
  String get settingVoiceWakeWordFineTuneDescription =>
      'Adjusts the wake word sensitivity in smaller steps. Raise it if you often have to repeat the wake word, lower it if it wakes by mistake.';

  @override
  String get settingVoiceNoiseGateTitle => 'Wake word noise gate';

  @override
  String get settingVoiceNoiseGateDescription =>
      'Skip wake word inference while the room is quiet, saving CPU.';

  @override
  String get settingVoiceStopWordTitle => 'Stop word interruption';

  @override
  String get settingVoiceStopWordDescription =>
      'Say \"stop\" to cut off an answer, a timer alert or an announcement.';

  @override
  String get settingVoiceStopWordFineTuneTitle =>
      'Fine-tune stop word sensitivity';

  @override
  String get settingVoiceStopWordFineTuneDescription =>
      'Adjusts the stop word sensitivity in smaller steps. Raise it if you often have to repeat \"stop\", lower it if answers stop by mistake.';

  @override
  String get settingVoiceWakeArbitrationTitle => 'Enable wake word arbitration';

  @override
  String get settingVoiceWakeArbitrationDescription =>
      'When several kiosks hear the wake word, the closest one answers. Increases detection latency.';

  @override
  String get settingVoiceWakeArbitrationWindowTitle => 'Arbitration window';

  @override
  String get settingVoiceWakeArbitrationWindowDescription =>
      'How long to wait for the other kiosks. Raise it if a slower kiosk loses when it is closer.';

  @override
  String get settingVoiceWakeArbitrationOffsetTitle => 'Arbitration offset';

  @override
  String get settingVoiceWakeArbitrationOffsetDescription =>
      'Added to how loud this kiosk heard the wake word. Raise it if this kiosk loses when it is closer, lower it if it answers from too far away.';

  @override
  String get voiceSectionWakeArbitration => 'Wake Word Arbitration';

  @override
  String get voiceOptionSlightly => 'Slightly sensitive';

  @override
  String get voiceOptionModerately => 'Moderately sensitive';

  @override
  String get voiceOptionVery => 'Very sensitive';

  @override
  String get voiceModelNotFileName => 'Not a file name.';

  @override
  String get voiceModelBadExtension =>
      'Only .json, .tflite and .onnx files are models.';

  @override
  String voiceModelTooLarge(String name) {
    return '$name is larger than 64 MB.';
  }

  @override
  String voiceModelIncomplete(String name) {
    return '$name arrived incomplete.';
  }

  @override
  String voiceModelBadJson(String file) {
    return '$file is not valid JSON.';
  }

  @override
  String voiceModelNotManifest(String file) {
    return '$file is not a manifest.';
  }

  @override
  String voiceModelMwwNeedsTflite(String file) {
    return 'A microWakeWord model needs $file too.';
  }

  @override
  String voiceModelMwwBadManifest(String file) {
    return '$file is not a valid microWakeWord manifest.';
  }

  @override
  String voiceModelVswwNeedsOnnx(String file) {
    return 'A vsWakeWord model needs $file too.';
  }

  @override
  String voiceModelVswwBadManifest(String file) {
    return '$file is not a valid vsWakeWord manifest.';
  }

  @override
  String voiceModelUnknownManifest(String file) {
    return '$file is neither a microWakeWord nor a vsWakeWord manifest.';
  }

  @override
  String voiceModelNoModelFile(String name) {
    return 'No model file for $name.';
  }

  @override
  String voiceModelBothFormats(String onnx, String tflite) {
    return 'Add either $onnx or $tflite, not both.';
  }

  @override
  String voiceModelNotOwwTflite(String file, String json) {
    return '$file is not an openWakeWord model. A microWakeWord model needs its $json too.';
  }

  @override
  String get voiceModelNotTflite => 'Not a TFLite model.';

  @override
  String get voiceModelNotOnnx => 'Not an ONNX model.';

  @override
  String get voiceModelNotOww => 'Not an openWakeWord model.';

  @override
  String get voiceModelOwwWindow =>
      'Not an openWakeWord model: it does not take the 16 x 96 embedding window.';

  @override
  String voiceModelNoLoad(String error) {
    return 'The model does not load: $error';
  }

  @override
  String get settingVoiceAmazonLocaleTitle => 'Wake word language';

  @override
  String get settingVoiceAmazonLocaleDescription =>
      'The language of Amazon\'s wake word models. The wake word selects offer the wake words it has.';

  @override
  String get settingDisableCacheTitle => 'Disable cache';

  @override
  String get settingDisableCacheDescription =>
      'Always fetch from the network and drop cached page data on load, so a redeployed dashboard always comes back fresh. Slow; treat it as a development aid.';

  @override
  String get settingAllowMixedContentTitle => 'Allow mixed content';

  @override
  String get settingAllowMixedContentDescription =>
      'Let HTTPS pages load insecure HTTP resources. Helps when Home Assistant mixes http:// content into an https:// dashboard.';

  @override
  String get settingIgnoreSslErrorsTitle => 'Ignore SSL errors';

  @override
  String get settingIgnoreSslErrorsDescription =>
      'Accept untrusted or self-signed certificates. Use only on your own network, since it disables certificate verification.';

  @override
  String get webGeolocationSection => 'HTML5 Geolocation';

  @override
  String get settingWebGeolocationTitle => 'Enable geolocation access';

  @override
  String get settingWebGeolocationDescription =>
      'Lets pages read the device location, such as a weather radar or a map. Only pages loaded over HTTPS can ask for it.';

  @override
  String get webGeolocationPermissionHeld =>
      'Pages can read the device location.';

  @override
  String get webGeolocationPermissionMissing =>
      'Without this pages cannot read the device location.';

  @override
  String get settingAutoReloadOnErrorTitle => 'Auto-reload on error';

  @override
  String get settingAutoReloadOnErrorDescription =>
      'Recover automatically from page failures and app crashes.';

  @override
  String get settingPullToRefreshTitle => 'Enable pull to refresh';

  @override
  String get settingPullToRefreshDescription =>
      'Drag down from the top of the page to reload it. Off by default: on a scrolling dashboard an accidental pull is easy.';

  @override
  String get settingPullToRefreshClearCacheTitle =>
      'Clear cache when pulling to refresh';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      'A pull also clears the web cache and wake word models before reloading, so everything comes back fresh. Login and saved page data are kept.';

  @override
  String get settingBrowserZoomTitle => 'Zoom level';

  @override
  String get settingBrowserZoomDescription =>
      'Scales the whole page. Above 1x for wall tablets viewed from a distance; below 1x fits more dashboard on a small screen.';

  @override
  String get settingPinchToZoomTitle => 'Enable pinch to zoom';

  @override
  String get settingPinchToZoomDescription =>
      'Zoom the page with a two-finger pinch. Off by default so a kiosk dashboard stays put under stray touches.';

  @override
  String get settingDisableScrollingTitle => 'Disable scrolling';

  @override
  String get settingDisableScrollingDescription =>
      'Lock the page in place so it cannot be scrolled in any direction. Taps and buttons keep working.';

  @override
  String get browserCrashPermissionHelp =>
      'Without this the kiosk cannot come back after a crash.';

  @override
  String get browserCrashPermissionMissing =>
      '\"Display over other apps\" permission missing';

  @override
  String get browserCrashPermissionRemoteHelp =>
      'Without it the kiosk cannot bring itself back after a crash. The grant screen appears on the tablet.';

  @override
  String get settingBrowserInjectJsTitle =>
      'Inject JavaScript on the HA dashboard';

  @override
  String get settingBrowserInjectJsDescription =>
      'Run this JavaScript code after every load of the dashboard page. Useful to hide distracting elements or tweak a dashboard you do not control.';

  @override
  String get settingBrowserInjectJsExternalTitle =>
      'Inject JavaScript on external pages';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      'Run this JavaScript code after loading each external page: pages opened by a dashboard link, dashboard rotation pages and the website screensaver. The Music Assistant page is left alone.';

  @override
  String get browserInjectJsPlaceholder =>
      '// Example: hide a distracting element\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// Example: zoom a site that ignores the dashboard zoom level\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get urlFilterTitle => 'URL Filter';

  @override
  String get urlFilterHint =>
      'Block or allow pages by address pattern or regular expression';

  @override
  String get urlFilterIntroTitle => 'Control which pages open';

  @override
  String get urlFilterIntroSub =>
      'Links or pages that match a Block rule don\'t load. Add an Allow only rule to load only the pages it matches.';

  @override
  String get urlFilterAdd => 'Add rule';

  @override
  String get urlFilterAddTitle => 'Add filter rule';

  @override
  String get urlFilterEditTitle => 'Edit filter rule';

  @override
  String get urlFilterName => 'Name';

  @override
  String get urlFilterPattern => 'Pattern';

  @override
  String get urlFilterPatternWildcardHint =>
      'Use * to match anything. A pattern starting with / matches the path on any server, such as /history*.';

  @override
  String get urlFilterPatternRegexHint =>
      'A regular expression matched anywhere in the address, ignoring case.';

  @override
  String get urlFilterType => 'Pattern type';

  @override
  String get urlFilterTypeWildcard => 'Wildcard';

  @override
  String get urlFilterTypeRegex => 'Regular expression';

  @override
  String get urlFilterAction => 'Action';

  @override
  String get urlFilterActionBlock => 'Block';

  @override
  String get urlFilterActionAllow => 'Allow only';

  @override
  String get urlFilterActionAllowHint =>
      'Where this rule applies, only pages that match an Allow only rule load. Home Assistant sign-in and the start dashboard always load.';

  @override
  String get urlFilterScope => 'Applies to';

  @override
  String get urlFilterScopeAll => 'Dashboard and external pages';

  @override
  String get urlFilterScopeDashboard => 'Dashboard';

  @override
  String get urlFilterScopeExternal => 'External pages';

  @override
  String get urlFilterScopeHint =>
      'External pages are links opened from the dashboard and dashboard rotation pages.';

  @override
  String get urlFilterErrorName => 'Enter a name.';

  @override
  String get urlFilterErrorPattern => 'Enter a pattern.';

  @override
  String get urlFilterErrorRegex => 'This regular expression is not valid.';

  @override
  String get urlFilterBlocked => 'Page blocked';

  @override
  String get urlFilterNotAllowed => 'Not on the allowed pages';

  @override
  String get settingBrowserUrlFilterNoticeTitle => 'Show blocked page notice';

  @override
  String get settingBrowserUrlFilterNoticeDescription =>
      'Show a short notice with the rule\'s name when a page is blocked.';

  @override
  String get setupConnectHeading => 'Connect to Home Assistant';

  @override
  String get setupConnectLead =>
      'The base URL of your instance and a long-lived access token, created under your HA profile → Security → Long-lived access tokens.';

  @override
  String get setupBaseUrl => 'Home Assistant base URL';

  @override
  String get setupToken => 'Long-lived access token';

  @override
  String get setupScanQr => 'Scan the QR code';

  @override
  String get setupInvalidToken => 'Invalid access token';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant rejected this token. In Home Assistant, open your profile → Security → Long-lived access tokens, create a new token and copy the complete value.';

  @override
  String get setupUnreachable => 'Can\'t reach Home Assistant';

  @override
  String get setupUnreachableHelp =>
      'No response from this address. Check that the URL is correct and that this device is on the same network as your Home Assistant server.';

  @override
  String get setupUnexpectedResponseHelp =>
      'A server responded, but it doesn\'t appear to be Home Assistant. Check that the URL is your Home Assistant base address, for example https://homeassistant.local:8123.';

  @override
  String get setupCannotConnect => 'Can\'t connect';

  @override
  String get setupCameraPermission => 'Camera permission needed';

  @override
  String get setupCameraBlocked =>
      'Allow the camera for Kiosk Satellite in the Android settings to scan the QR code.';

  @override
  String get setupCameraAllow => 'Allow the camera to scan the QR code.';

  @override
  String get setupEnterBaseUrl => 'Enter your Home Assistant base URL';

  @override
  String get setupInvalidBaseUrl => 'Invalid base URL';

  @override
  String get setupBaseUrlHelp =>
      'This is the address you use to open Home Assistant, for example https://homeassistant.local:8123.';

  @override
  String get setupEnterToken => 'Enter a long-lived access token';

  @override
  String get setupEnterTokenHelp =>
      'In Home Assistant, open your profile → Security → Long-lived access tokens to create one.';

  @override
  String get setupValidateContinue => 'Validate & continue';

  @override
  String setupUnexpectedResponse(String error) {
    return 'Unexpected response ($error)';
  }

  @override
  String get baseUrlInvalid =>
      'Enter a valid URL, for example https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      'Enter only the base URL, without a dashboard path. Example: https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      'Enter only the base URL, without anything after the port. Example: https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => 'Choose a dashboard';

  @override
  String get setupDashboardHelp =>
      'This is what the kiosk will show when it starts.';

  @override
  String get setupSelectDashboard => 'Select a dashboard';

  @override
  String get setupSelectDashboardHelp =>
      'Choose the dashboard the kiosk will display. You can change it later in Settings.';

  @override
  String get setupHeadlessGrants =>
      'This device has no screen, so Android cannot ask for these on it. Give each one over adb, then finish here.';

  @override
  String get setupWelcome => 'Welcome';

  @override
  String get setupConnect => 'Connect';

  @override
  String get setupConnectSummary => 'Home Assistant URL & token';

  @override
  String get setupDashboard => 'Dashboard';

  @override
  String get setupDashboardSummary => 'What the kiosk shows';

  @override
  String get setupRecommendedSummary => 'Recommended settings';

  @override
  String get setupPermissions => 'Permissions';

  @override
  String get setupPermissionsSummary => 'What the setup needs';

  @override
  String get setupPermissionLead =>
      'Android will ask for these permissions. Everything is requested up front so the kiosk never interrupts you later.';

  @override
  String get setupRemotePermissionLead =>
      'Android asks for these on the tablet itself. Walk over and accept the prompts, then finish here.';

  @override
  String get setupMicrophoneHelp =>
      'Voice Satellite and the intercom need microphone access';

  @override
  String get setupNotificationListening =>
      'Allows the Kiosk Satellite Service\'s ongoing notification, which says what it is keeping alive and when the kiosk is listening.';

  @override
  String get setupBatteryService =>
      'Allows the Kiosk Satellite Service to run in the background without being paused or killed.';

  @override
  String get setupOverlayBoot =>
      'Lets Kiosk Satellite come back after a crash and start when your device boots.';

  @override
  String get setupOverlayCrash =>
      'Lets Kiosk Satellite come back on screen after a crash.';

  @override
  String get setupBrightnessHelp =>
      'Allows Kiosk Satellite to set the panel\'s actual brightness (modify system settings).';

  @override
  String get setupScreenControl => 'Screen control';

  @override
  String get setupScreenControlHelp =>
      'Allows Kiosk Satellite to turn the screen off on request (device admin).';

  @override
  String get setupGrantPermissions => 'Grant permissions on the device';

  @override
  String get setupRequestingPermissions => 'Requesting on the device…';

  @override
  String get setupPermissionsRequested => 'Permissions requested on the device';

  @override
  String get setupQrFlipCamera => 'Flip camera';

  @override
  String get setupQrCameraFailed => 'The camera could not be started.';

  @override
  String get setupQrTitle => 'Scan the token QR code';

  @override
  String get setupQrHelp =>
      'It appears next to a newly created token in your Home Assistant profile.';

  @override
  String get setupQrFlashOff => 'Turn off the flashlight';

  @override
  String get setupQrFlashOn => 'Turn on the flashlight';

  @override
  String get setupQrScreenLightOff => 'Turn off the screen light';

  @override
  String get setupQrScreenLightOn => 'Turn on the screen light';

  @override
  String get setupPasswordFirst => 'Set the admin password first';

  @override
  String get setupPasswordBeforeImport =>
      'Type an admin password above (at least 4 characters), then import the backup.';

  @override
  String get setupPasswordFailed => 'Could not set the password';

  @override
  String get setupPasswordExists => 'A password is already set';

  @override
  String get setupPasswordExistsHelp =>
      'Log in with the password set on the tablet to continue here. Reloading…';

  @override
  String get setupNotBackup => 'Not a backup file';

  @override
  String get setupInvalidBackupHelp =>
      'That file is not valid JSON. Export a configuration from Settings on a set-up Kiosk Satellite, or from its remote admin.';

  @override
  String get setupWrongBackupKind =>
      'Export a configuration from the Settings tab of a set-up Kiosk Satellite.';

  @override
  String get setupImportFailedHelp => 'The file could not be applied.';

  @override
  String get setupBackupNoDashboard => 'Backup has no dashboard';

  @override
  String get setupBackupNoDashboardHelp =>
      'The settings were applied, but this backup was taken before its device was set up, so there is no dashboard to show. Continue the wizard to pick one.';

  @override
  String get setupImporting => 'Importing…';

  @override
  String get setupRemoteRestoreHelp =>
      'Import a configuration exported from Kiosk Satellite and skip the rest of this wizard.';

  @override
  String get setupFinishOnDevice => 'Finish on the device';

  @override
  String get setupFinishOnDeviceHelp =>
      'The configuration was imported. Answer the permission prompts on the tablet\'s screen - this page continues automatically when the dashboard loads.';

  @override
  String get setupBackupObject => 'The backup must contain a JSON object.';

  @override
  String get setupBackupKind =>
      'This is not a Kiosk Satellite configuration file.';

  @override
  String get setupBackupSettings => 'The backup contains no settings.';

  @override
  String get setupServiceHelp =>
      'Keeps the app alive while the screen is off or another app is in front, so the Home Assistant connection and other features like motion detection and the Bluetooth proxy stay alive. The permissions below are optional but recommended: each one helps it survive the screen being off.';

  @override
  String get setupBatteryMissing =>
      'Android may pause the app when the screen is off, dropping the Home Assistant connection with it.';

  @override
  String get setupOverlayMissing =>
      'Without this the service cannot relaunch the kiosk after a crash.';

  @override
  String get setupVoiceDetected => 'Voice Satellite detected';

  @override
  String get setupVoiceHelp =>
      'This Home Assistant instance runs the Voice Satellite integration. Choose which satellite this kiosk is, then review its settings. Everything can be changed later.';

  @override
  String get setupNoSatellites => 'No satellites found';

  @override
  String get setupNoSatellitesHelp =>
      'Add an assist satellite in the Voice Satellite integration, or continue without one and pick it on the dashboard later.';

  @override
  String get setupNewSatelliteHelp =>
      'If this is a new device, create a new satellite entity in Home Assistant first. Settings → Devices & Services → Voice Satellite → Add Entry. IMPORTANT: Two devices cannot share the same entity.';

  @override
  String get setupApplyRecommended => 'Apply all recommended settings';

  @override
  String get setupRecommendedHelp =>
      'The optimal settings for full Voice Satellite integration and functionality.';

  @override
  String get setupVoiceRequired => 'Required by Voice Satellite';

  @override
  String get setupMicrophoneAccess => 'Microphone access';

  @override
  String get setupNativeWakeWord => 'Native wake word detection';

  @override
  String get setupPullRefresh => 'Pull to refresh';

  @override
  String get setupAutoplay => 'Autoplay audio and video';

  @override
  String get setupVoiceSkipped => 'Not installed, skipped';

  @override
  String get setupVoiceLead =>
      'Turn this kiosk into a voice assistant for Home Assistant. Everything can be changed later.';

  @override
  String get setupVoiceAddAgainHint =>
      'After setup, add this kiosk in Home Assistant under Settings, Devices & services, where it shows up as discovered. If Home Assistant had it before, it asks there for the new Encryption key from the ESPHome page.';

  @override
  String get setupRecommendedWall =>
      'The settings that suit a kiosk on the wall.';

  @override
  String get setupVoiceFound => 'Voice Satellite integration found';

  @override
  String get setupVoiceFoundHelp =>
      'Voice Satellite now runs inside Kiosk Satellite. Migrate to keep the wake words, assistant and look of one of the integration\'s satellites instead of starting fresh.';

  @override
  String get setupVoiceMigrated =>
      'Migrated from the Voice Satellite integration';

  @override
  String get setupVoiceMigratedHelp =>
      'This kiosk takes over its satellite\'s settings.';

  @override
  String get setupVoicePipelineHelp =>
      'The Assist pipeline that answers the wake word.';

  @override
  String get setupVoiceEngineHelp =>
      'The engine that listens for the wake word.';

  @override
  String get setupRemoteHeading => 'Remote administration';

  @override
  String get setupTitle => 'Set up\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      'Turn this tablet into a Home Assistant kiosk. Setup takes a couple of minutes and this wizard walks you through it.';

  @override
  String get setupDeviceName => 'Device name';

  @override
  String get setupDeviceNameHelp =>
      'How this kiosk is called in Home Assistant, in the remote admin and on the network. Change it any time under Settings, Device.';

  @override
  String get setupEnableRemote => 'Enable remote administration';

  @override
  String get setupEnableRemoteHelp =>
      'Keep managing this kiosk from a web browser after setup, where pasting the Home Assistant access token is much easier.';

  @override
  String get setupRemotePassword => 'Remote admin password';

  @override
  String get setupRestoreHeading => 'Restore backup';

  @override
  String get setupRestore => 'Restore from configuration file';

  @override
  String get setupRestoreHelp =>
      'Import a configuration exported from Kiosk Satellite and skip the rest of this wizard. Settings, dashboard and login all come along.';

  @override
  String get setupServicePermissions => 'Recommended Service Permissions';

  @override
  String get setupPasswordShort => 'Password too short';

  @override
  String get setupPasswordMinimum => 'Use at least 4 characters.';

  @override
  String setupRemoteAddress(String address) {
    return 'You can continue this setup remotely from a web browser at $address, whether the switch above is on or not.';
  }

  @override
  String get remoteWelcomeTitle => 'Welcome to Kiosk Satellite';

  @override
  String get remoteWelcomePassword =>
      'This tablet is waiting to be set up. First, protect this remote admin with a password.';

  @override
  String get remoteWelcomeReady =>
      'This tablet is waiting to be set up. The remote admin password is already set; type a new one here to change it.';

  @override
  String get remoteInitialPassword => 'Admin password (min 4 characters)';

  @override
  String get remoteNewPassword =>
      'New admin password (leave empty to keep the current one)';

  @override
  String get intercomBuiltinRing => 'Built-in ring';

  @override
  String get intercomBuiltinChime => 'Built-in chime';

  @override
  String intercomMissingFile(String file) {
    return '$file (missing)';
  }

  @override
  String get intercomAddSound => 'Add a sound';

  @override
  String get intercomCopySoundHelp =>
      'Copy a sound file from this device into the sounds folder.';

  @override
  String get intercomUploadSoundHelp =>
      'Upload a sound file from this computer into the sounds folder.';

  @override
  String get intercomUpload => 'Upload';

  @override
  String get intercomUploading => 'Uploading…';

  @override
  String get intercomUnsupportedSound => 'Not a supported sound';

  @override
  String get intercomChooseSound =>
      'Not a supported sound: pick an MP3, OGG, WAV, FLAC, M4A or AAC file.';

  @override
  String get intercomCopyFailed => 'Could not copy the file';

  @override
  String intercomUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String intercomSaveFailed(String error) {
    return 'Not saved: $error';
  }

  @override
  String get intercomSoundFilename => 'Enter a file name, not a path.';

  @override
  String get intercomSoundFormats =>
      'Pick an MP3, OGG, WAV, FLAC, M4A or AAC file.';

  @override
  String get voiceNoticeError => 'Voice Satellite error';

  @override
  String get voiceNoticeWarning => 'Voice Satellite warning';

  @override
  String get voiceNoticeNotice => 'Voice Satellite notice';

  @override
  String get voiceNoticeTts => 'Text-to-speech';

  @override
  String get voiceNoticeAssistPipeline => 'Assist pipeline';

  @override
  String voiceNoticePipeline(String name) {
    return 'Pipeline \"$name\"';
  }

  @override
  String get voiceNoticeMicUnavailable => 'The microphone is not available.';

  @override
  String get voiceNoticeNotConnected =>
      'Home Assistant is not connected to this kiosk.';

  @override
  String get voiceNoticeConnectionLost =>
      'Lost connection to Home Assistant. Reconnecting automatically.';

  @override
  String get voiceNoticePlayback => 'Audio could not be played on the device.';

  @override
  String get voiceNoticeWatchdog =>
      'No response from Home Assistant after you finished speaking. The pipeline may be stuck.';

  @override
  String get voiceNoticeRefused =>
      'Home Assistant could not start the assistant.';

  @override
  String get voiceNoticeUnexpected => 'An unexpected pipeline error occurred.';

  @override
  String get voiceNoticeMicBlocked =>
      'Microphone access is blocked. Allow it for Kiosk Satellite in the Android settings.';

  @override
  String get voiceNoticeMicDeclined =>
      'Microphone access was declined, so the wake word cannot be heard.';

  @override
  String get voiceNoticeMicLost => 'The microphone stopped working.';

  @override
  String get voiceNoticeModels => 'The wake word models could not be loaded.';

  @override
  String get voiceNoticeCrashed =>
      'The wake word detector kept crashing on this device, so it was stopped.';

  @override
  String voiceFinancialOpen(String value) {
    return 'Open: $value';
  }

  @override
  String voiceFinancialHigh(String value) {
    return 'High: $value';
  }

  @override
  String voiceFinancialLow(String value) {
    return 'Low: $value';
  }

  @override
  String voiceFinancialHigh24h(String value) {
    return '24h High: $value';
  }

  @override
  String voiceFinancialLow24h(String value) {
    return '24h Low: $value';
  }

  @override
  String voiceFinancialMarketCap(String value) {
    return 'MCap: $value';
  }

  @override
  String get voiceTimerDefaultName => 'Timer';

  @override
  String get voiceTimerDrag => 'Drag to move timers';

  @override
  String get voiceTimerPauseHint =>
      'Tap to pause. Double tap to cancel. Drag to move.';

  @override
  String get voiceTimerResumeHint =>
      'Tap to resume. Double tap to cancel. Drag to move.';

  @override
  String get voiceTimerCancel => 'Cancel timer';

  @override
  String get voiceTimerActionError =>
      'Could not change the timer. Check the connection and update Voice Satellite if needed.';

  @override
  String get voiceTimerFinished => 'Timer finished';

  @override
  String get voiceTimerDismissHint => 'Tap to dismiss the timer alert.';

  @override
  String get voiceTimersViewTitle => 'Timers';

  @override
  String get voiceTimersEmpty => 'No timers';

  @override
  String get voiceTimerPause => 'Pause';

  @override
  String get voiceTimerResume => 'Resume';

  @override
  String get voiceTimerDismiss => 'Dismiss';

  @override
  String get voiceTimerTimesUp => 'Time\'s up';

  @override
  String get voiceTimerPaused => 'Paused';

  @override
  String get voiceTimersShareNone => 'No kiosks picked';

  @override
  String get voiceTimersShareEmpty =>
      'No other kiosks found. Turn on the remote admin and Find other kiosks on each one.';

  @override
  String get voiceTimersShareOffline => 'Offline';

  @override
  String get timersVoiceSection => 'Voice timers';

  @override
  String get timersVoiceManage => 'Manage timers using Voice Satellite';

  @override
  String get timersVoiceHint =>
      'Works without a blueprint or an LLM conversation agent.';

  @override
  String get voiceTimersShareSearch => 'Search kiosks';

  @override
  String get voiceTimerSetATimer => 'Set a timer';

  @override
  String get voiceTimerEditTimer => 'Edit timer';

  @override
  String get voiceTimerName => 'Name';

  @override
  String get voiceTimerHours => 'Hours';

  @override
  String get voiceTimerMinutes => 'Minutes';

  @override
  String get voiceTimerSeconds => 'Seconds';

  @override
  String get voiceTimerStartFailed => 'Could not start the timer.';

  @override
  String get timersManage => 'Manage timers';

  @override
  String get voiceTimerStartUnavailable =>
      'Turn on Voice Satellite on this kiosk to set timers here.';
}
