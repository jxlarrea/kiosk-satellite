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
  String get fleetKiosksMemberOfTheFleetAFollowerMustConfirm =>
      'Add a discovered kiosk or enter its IP address. The follower must accept the invitation on its screen.';

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
  String get fleetConfirmOnTheKioskItselfTheInvitationIsWaiting =>
      'Confirm on the kiosk itself. The invitation is waiting on its screen and under Settings, Fleet Management.';

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
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'name, remote administration, renderer workarounds, scale';

  @override
  String get fleetHomeAssistantToken => 'Home Assistant token';

  @override
  String get fleetMusicAssistantToken => 'Music Assistant token';

  @override
  String get fleetImmichApiKey => 'Immich API key';

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
  String get gestureScreensaver => 'Start the screensaver';

  @override
  String get gestureScreensaverStop => 'Stop the screensaver';

  @override
  String get gestureHoldMode => 'Toggle hold mode';

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
  String get gestureNoDashboards => 'No dashboards';

  @override
  String get gestureDashboardsFailed => 'Could not list dashboards';

  @override
  String get gestureHaConnected => 'Is Home Assistant connected?';

  @override
  String get gestureDashboardsHelp =>
      'Could not list dashboards. Is Home Assistant connected?';

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
  String get gestureDomain => 'Domain';

  @override
  String get gestureEntityOptional => 'Entity (optional)';

  @override
  String get gestureServiceData => 'Service data (optional)';

  @override
  String get gestureServiceTitle => 'Call a Home Assistant service';

  @override
  String get gestureServiceRequired => 'Domain and service are required.';

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
  String get pluginSelectAnEntity => 'Select an entity';

  @override
  String pluginChooseName(String name) {
    return 'Choose $name';
  }

  @override
  String pluginConfigureName(String name) {
    return 'Configure $name';
  }

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
  String get pluginErrorTagRevision =>
      'GitHub did not return the release tag revision';

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
  String get pluginErrorPluginLimit => 'At most 8 plugins can be installed';

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
  String pluginErrorInvalidField(String field) {
    return 'Invalid $field';
  }

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
  String get overviewOpen => 'Open';

  @override
  String get overviewUpdate => 'Update';

  @override
  String overviewInvitation(String name) {
    return '$name wants to lead this kiosk';
  }

  @override
  String get overviewInvitationHelp =>
      'Confirm on the kiosk screen or under Fleet Management there.';

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
  String get overviewLoadingViews => 'Loading views…';

  @override
  String get overviewPickView => 'Pick a dashboard view…';

  @override
  String get overviewDefaultView => 'Default view';

  @override
  String get overviewNoDashboards => 'No dashboards found';

  @override
  String get overviewViewsUnavailable => 'Views unavailable';

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
  String get launcherPermissionsSearch =>
      'The grants Return automatically leans on.';

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
  String get settingCameraAutoDismissSecondsDescription =>
      'Close an opened camera view on its own; 0 keeps it up. The camera screensaver is unaffected.';

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
  String get deviceCpuTemp => 'CPU temperature';

  @override
  String get deviceBatteryLevel => 'Battery level';

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
  String get settingAnnouncementsTtsEngineTitle => 'Text to speech engine';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'The Home Assistant text to speech entity that speaks announcements.';

  @override
  String get esphomeTtsFirst => 'First available';

  @override
  String get settingAnnouncementsChimeTitle => 'Chime first';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Play a chime before the announcement.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Chime sound';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Plays at the notification volume.';

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
  String get settingClapStrictnessDescription =>
      'Strict needs louder, evenly spaced claps; try it if household noise false-triggers.';

  @override
  String get gestureStrictnessStandard => 'Standard';

  @override
  String get gestureStrictnessStrict => 'Strict';

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
  String get settingHaHoldMenuTitle => 'Show in the kiosk menu';

  @override
  String get settingHaHoldMenuDescription =>
      'Adds a menu entry that turns hold mode on and off.';

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
  String get haDefaultView => 'Default view';

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
  String get haLoadingDashboards => 'Loading dashboards…';

  @override
  String get haListFailed => 'Could not list dashboards';

  @override
  String get haRetryHint => 'Tap to retry.';

  @override
  String get haChangeView => 'Change view';

  @override
  String get haNoViews => 'No sub views';

  @override
  String get haNoViewsHelp => 'This dashboard has no selectable sub views.';

  @override
  String get haNoDashboards => 'No dashboards found';

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
  String get settingHaKioskMenuTitle => 'Show in the kiosk menu';

  @override
  String get settingHaKioskMenuDescription =>
      'Add an HA Kiosk Mode entry to the kiosk menu that turns it on and off.';

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
  String get settingIntercomRingSoundDescription =>
      'Plays at the notification volume.';

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
  String get settingIntercomMenuTitle => 'Show in the kiosk menu';

  @override
  String get settingIntercomMenuDescription =>
      'Add an Intercom entry to the kiosk menu.';

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
  String get intercomTalkSection => 'Talk';

  @override
  String get settingKioskAllowDrawerTitle => 'Allow menu with quick actions';

  @override
  String get settingKioskAllowDrawerDescription =>
      'An edge swipe opens the menu without the exit gesture or PIN, limited to the actions selected below.';

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
  String get settingLockdownEnabledTitle => 'Enable Lockdown Mode';

  @override
  String get settingLockdownEnabledDescription =>
      'Disables screen interactions until turned off either from Home Assistant or with the exit gesture.';

  @override
  String get settingLockdownMenuTitle => 'Show in the kiosk menu';

  @override
  String get settingLockdownMenuDescription =>
      'Add a Lockdown Mode entry to the kiosk menu that locks the screen. Use the exit gesture, Remote Admin or Home Assistant to unlock it.';

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
  String get settingSendspinPlayerShortcutTitle => 'Show in the kiosk menu';

  @override
  String get settingSendspinPlayerShortcutDescription =>
      'Add an entry in the kiosk menu that shows or hides the floating player. WARNING: If nothing is playing or there is no queue for this player, it won\'t show up.';

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
  String get settingSendspinVolumeKeysTitle =>
      'Volume buttons control the player';

  @override
  String get settingSendspinVolumeKeysDescription =>
      'This device\'s volume buttons change the followed player\'s volume instead of its own. Only while the Now Playing view is on screen, or whenever the player is playing.';

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
  String mediaLocalOffline(String player) {
    return 'This device\'s own Sendspin player stays offline while $player is controlled.';
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
  String get settingSendspinMaShortcutTitle => 'Show in the kiosk menu';

  @override
  String get settingSendspinMaShortcutDescription =>
      'Add a Music Assistant entry to the kiosk menu, opening the server\'s web interface over the dashboard. Needs the server address above.';

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
  String get settingSendspinFullscreenHorizontalTitle => 'Horizontal mode';

  @override
  String get settingSendspinFullscreenHorizontalDescription =>
      'Split artwork and controls into equal left and right halves. With lyrics or the queue open, track details move below the artwork. Ignored while Now Playing is shown alongside a screensaver.';

  @override
  String get settingSendspinFullscreenDoubleTapTitle => 'Double tap to dismiss';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'A double tap anywhere on the Now Playing view dismisses it. The close button won\'t be shown. Ignored while Now Playing is shown alongside a screensaver.';

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
  String get settingSendspinFullscreenShortcutTitle => 'Show in the kiosk menu';

  @override
  String get settingSendspinFullscreenShortcutDescription =>
      'Add an entry in the kiosk menu that shows the Now Playing view. WARNING: If nothing is playing or there is no queue for this player, it won\'t show up.';

  @override
  String get settingSendspinSpeakerPillTitle => 'Show speaker selection pill';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Shows speaker selection for 5 seconds after screen interaction. Add or remove speakers from the current group.';

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
  String get settingsMenuHomeAssistant => 'Home Assistant Setup';

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
  String get settingAdaptiveBrightnessTitle => 'Adaptive brightness';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Dim the screen as the room gets darker, using the ambient light sensor.';

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
  String get settingAudioMicDeviceTitle => 'Microphone';

  @override
  String get settingAudioMicDeviceDescription =>
      'The microphone wake word detection and voice turns capture from.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Speaker';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Output for Voice Satellite sounds; media playback follows the system route. Echo cancellation only works with the microphone and speaker on the same device.';

  @override
  String get screenAudioDevices => 'Audio Devices';

  @override
  String get screenAudioSelectedDevice => 'Selected device';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (not connected)';
  }

  @override
  String get settingMicAudioSourceTitle => 'Capture mode';

  @override
  String get settingMicAudioSourceDescription =>
      'Voice communication is the only mode with echo cancellation, so leave it unless the microphone reads far quieter here than in a recorder app.';

  @override
  String get settingMicEchoCancellationTitle => 'Echo cancellation';

  @override
  String get settingMicEchoCancellationDescription =>
      'Keeps the kiosk\'s own speaker out of the microphone so the stop word works during playback. Turn it off only if the microphone reads far quieter here than in a recorder app.';

  @override
  String get settingMicChannelTitle => 'Microphone channel';

  @override
  String get settingMicChannelDescription =>
      'Multichannel microphones often reserve one channel for speech recognition; picking it can improve detection.';

  @override
  String get settingMicAgcTitle => 'Automatic gain control';

  @override
  String get settingMicAgcDescription =>
      'Let Android level the microphone instead of a fixed gain. It also lifts room noise, and on some devices it does nothing at all.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Noise suppression';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Reduce microphone background noise using Android processing. It may help or hurt wake word detection depending on the device.';

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
      'Capture mode, channel, gain, live level';

  @override
  String get screenAudioMicrophoneNote =>
      'Adjust capture for your microphone and room. Test wake words and voice interactions after changing these settings.';

  @override
  String get screenAudioVoiceCommunication => 'Voice communication (default)';

  @override
  String get screenAudioVoiceRecognition => 'Voice recognition';

  @override
  String get screenAudioRawMicrophone => 'Raw microphone';

  @override
  String get screenAudioAutomaticDefault => 'Automatic (default)';

  @override
  String get screenAudioStereo => '48 kHz stereo';

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
  String get settingAssistantFullVolumeRangeTitle =>
      'Full assistant volume range';

  @override
  String get settingAssistantFullVolumeRangeDescription =>
      'Initialize the built-in speaker\'s call volume at 100% when assistant audio first starts. Master and assistant volume still apply. Other apps share this call volume, which is not restored afterward.';

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
  String get settingScreensaverClockStyleTitle => 'Style';

  @override
  String get settingScreensaverClockStyleDescription =>
      'How the clock is drawn.';

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
  String get screensaverOverlaySearchHint => 'Name or entity id';

  @override
  String get screensaverOverlaySearchHintRemote =>
      'Search by name or entity id';

  @override
  String get screensaverOverlaySearchEmpty => 'Type to search entities.';

  @override
  String get screensaverOverlayNoMatches => 'Nothing matched.';

  @override
  String get screensaverOverlaySearching => 'Searching…';

  @override
  String get screensaverOverlayUnreachable => 'Could not reach Home Assistant';

  @override
  String get screensaverOverlayNoAnswer => 'The device did not answer.';

  @override
  String screensaverOverlaySearchError(String error) {
    return 'Could not search entities: $error';
  }

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
  String get settingScreensaverMenuTitle => 'Show in the kiosk menu';

  @override
  String get settingScreensaverMenuDescription =>
      'Add a Start Screensaver entry to the kiosk menu.';

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
  String get settingScreensaverScreenOffMinutesTitle => 'Turn screen off after';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Powers down the display panel once the screensaver has run for the set duration. Set to 0 to keep the screen on indefinitely. Requires Device Administrator permission.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Wake to screensaver';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescription =>
      'Motion, face, proximity or person detection after the screen has turned off brings the screensaver back instead of the dashboard, with a fresh Turn screen off after countdown. Touch still opens the dashboard.';

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
  String get screensaverOverlayReorder => 'Showing (drag to reorder)';

  @override
  String get screensaverOverlayFull =>
      'That is the most the row can show. Remove one to add another.';

  @override
  String get screensaverOverlayPickerTitle => 'At a glance entities';

  @override
  String screensaverOverlayGlanceEmpty(String count) {
    return 'None yet. Up to $count entities.';
  }

  @override
  String get screensaverOverlayNone => 'None yet';

  @override
  String screensaverOverlayLimit(String count) {
    return 'Up to $count entities.';
  }

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
  String get settingScreensaverImmichIntervalDescription =>
      'How long each image shows before the next. Videos play in full.';

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
  String get settingScreensaverGalleryItemsTitle => 'Photos';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'The photos and videos this screensaver cycles. Picked from the gallery on the device; picking again replaces the selection.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Seconds per photo';

  @override
  String get settingScreensaverGalleryIntervalDescription =>
      'How long each photo shows before the next. Videos play in full.';

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
  String get settingScreensaverMediaIntervalDescription =>
      'How long each image shows before the next. Videos play in full.';

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
  String get screensaverMediaHaPage => 'Home Assistant Media screensaver';

  @override
  String get screensaverMediaHaHint => 'Media source, timing, shuffle, fill';

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
  String get settingScreensaverLocalIntervalDescription =>
      'How long each photo shows before the next. Videos play in full.';

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
  String get screensaverMediaLocalPage => 'Local Media screensaver';

  @override
  String get screensaverMediaLocalHint => 'Folder, timing, shuffle, transition';

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
  String get screensaverOverlayNoWeather => 'No weather entities';

  @override
  String get screensaverOverlayNoWeatherHelp => 'Home Assistant reported none.';

  @override
  String get screensaverOverlayPickWeather => 'Pick a weather entity…';

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
  String get voiceChimesPage => 'Chimes';

  @override
  String get voiceChimesHint =>
      'Wake, done, error, timer and announcement sounds';

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
}
