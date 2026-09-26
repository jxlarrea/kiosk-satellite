import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'ui_strings_de.dart';
import 'ui_strings_en.dart';
import 'ui_strings_es.dart';
import 'ui_strings_fr.dart';
import 'ui_strings_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of UiStrings
/// returned by `UiStrings.of(context)`.
///
/// Applications need to include `UiStrings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/ui_strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: UiStrings.localizationsDelegates,
///   supportedLocales: UiStrings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the UiStrings.supportedLocales
/// property.
abstract class UiStrings {
  UiStrings(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static UiStrings? of(BuildContext context) {
    return Localizations.of<UiStrings>(context, UiStrings);
  }

  static const LocalizationsDelegate<UiStrings> delegate = _UiStringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('uk'),
  ];

  /// App information group heading.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get aboutApp;

  /// Installed app version label.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get aboutVersion;

  /// Build mode label. The technical value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get aboutBuild;

  /// Android package identifier label.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get aboutPackage;

  /// Author and project links group heading.
  ///
  /// In en, this message translates to:
  /// **'Attribution'**
  String get aboutAttribution;

  /// App author label.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get aboutAuthor;

  /// Project website label.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutWebsite;

  /// Project repository link label.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutSourceCode;

  /// App license link label. Keep the license identifier unchanged.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutLicense;

  /// Plain-language summary below the links. The linked license remains the authoritative legal text.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite is free for personal, non-commercial use. It is licensed under CC BY-NC-ND 4.0: you may use and share it, but commercial use of the app and redistribution of modified app builds are not permitted. Independent plugins have additional permission under PLUGIN-EXCEPTION.md.'**
  String get aboutLicenseSummary;

  /// Title of the page listing translation contributors, and the About row that opens it.
  ///
  /// In en, this message translates to:
  /// **'Localization Credits'**
  String get aboutLocalizationCredits;

  /// Hint under the About row that opens the Localization Credits page.
  ///
  /// In en, this message translates to:
  /// **'Contributors by language'**
  String get aboutLocalizationCreditsHint;

  /// Tooltip on the clickable version number in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Check for updates now'**
  String get aboutCheckNow;

  /// Version link while checking for updates.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get aboutChecking;

  /// Failed update check notification.
  ///
  /// In en, this message translates to:
  /// **'Update check failed. Can the device reach GitHub?'**
  String get aboutCheckFailed;

  /// Missing Android permission label.
  ///
  /// In en, this message translates to:
  /// **'\"Display over other apps\" permission missing'**
  String get aboutOverlayMissing;

  /// Help for the missing overlay permission.
  ///
  /// In en, this message translates to:
  /// **'Without it the app cannot reopen itself after updating. The grant screen appears on the tablet.'**
  String get aboutOverlayHelp;

  /// Download progress on the installation button.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String aboutDownloadProgress(String percent);

  /// Failed update command with the original technical detail.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String aboutDownloadFailed(String error);

  /// The device checked again and no update was needed.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get aboutAlreadyCurrent;

  /// Guidance below release notes before installation.
  ///
  /// In en, this message translates to:
  /// **'The download runs on the tablet; the installation must be confirmed on the tablet screen.'**
  String get aboutInstallHelp;

  /// Service description displayed by Android in its own language.
  ///
  /// In en, this message translates to:
  /// **'Closes the notification shade and the recents screen whenever they open while Kiosk Mode or Lockdown Mode is protecting the screen. Kiosk Satellite does not read any screen content.'**
  String get androidAccessibilityHelp;

  /// Notification channel description in Android Settings.
  ///
  /// In en, this message translates to:
  /// **'Shown while the Kiosk Satellite Service keeps the app running with the screen off or behind another app.'**
  String get androidServiceChannelHelp;

  /// Wake word listening status.
  ///
  /// In en, this message translates to:
  /// **'listening for a wake word'**
  String get androidServiceListening;

  /// RTSP microphone status.
  ///
  /// In en, this message translates to:
  /// **'RTSP microphone audio enabled'**
  String get androidServiceRtspAudio;

  /// ESPHome server status.
  ///
  /// In en, this message translates to:
  /// **'serving ESPHome'**
  String get androidServiceEsphome;

  /// Bluetooth proxy status.
  ///
  /// In en, this message translates to:
  /// **'relaying Bluetooth devices'**
  String get androidServiceBluetooth;

  /// Camera monitoring status.
  ///
  /// In en, this message translates to:
  /// **'watching the camera'**
  String get androidServiceCamera;

  /// Location reporting status.
  ///
  /// In en, this message translates to:
  /// **'reporting the location'**
  String get androidServiceLocation;

  /// Remote admin server status.
  ///
  /// In en, this message translates to:
  /// **'serving the remote admin'**
  String get androidServiceRemote;

  /// Kiosk protection status.
  ///
  /// In en, this message translates to:
  /// **'guarding kiosk mode'**
  String get androidServiceKiosk;

  /// Home Assistant connection status, always present.
  ///
  /// In en, this message translates to:
  /// **'keeping Home Assistant connected'**
  String get androidServiceSessions;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'listing apps is Android-only'**
  String get launcherErrorAndroidOnly;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'could not list apps: {error}'**
  String launcherErrorListDetail(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not open {name}'**
  String launcherOpenFailed(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'It may have been uninstalled.'**
  String get launcherUninstalled;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'None yet. Pick the apps the launcher offers.'**
  String get launcherNoneHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get launcherNone;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not list the apps'**
  String get launcherListFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not list the apps: {error}'**
  String launcherListError(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'listing failed'**
  String get launcherListingFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No launchable apps found.'**
  String get launcherEmpty;

  /// Page title.
  ///
  /// In en, this message translates to:
  /// **'Camera view'**
  String get cameraViewerTitle;

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get cameraViewerConnecting;

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get cameraViewerReconnecting;

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'Trying {transport}...'**
  String cameraViewerTrying(String transport);

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'This device cannot decode {codec}'**
  String cameraViewerCannotDecode(String codec);

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'This device cannot play {transport} streams'**
  String cameraViewerCannotPlay(String transport);

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'This device cannot decode this stream'**
  String get cameraViewerCannotDecodeStream;

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach Home Assistant. Retrying in {seconds}s'**
  String cameraViewerHaRetry(String seconds);

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the camera server. Retrying in {seconds}s'**
  String cameraViewerServerRetry(String seconds);

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Retrying in {seconds}s'**
  String cameraViewerConnectionRetry(String seconds);

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'The camera server could not start this stream. Retrying...'**
  String get cameraViewerStartRetry;

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'The camera server could not start this stream. Retrying in {seconds}s'**
  String cameraViewerStartDelayedRetry(String seconds);

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'Stream not found on the camera server. Retrying in {seconds}s'**
  String cameraViewerMissingRetry(String seconds);

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'The camera server rejected the login. Retrying in {seconds}s'**
  String cameraViewerLoginRetry(String seconds);

  /// Status shown over a camera tile.
  ///
  /// In en, this message translates to:
  /// **'Stream missing from Go2RTC'**
  String get cameraViewerMissing;

  /// Button to import a configuration file.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get commonImport;

  /// Button to return to the previous step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Button to advance to the next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Button to complete setup.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get commonFinish;

  /// Button label while an operation is running.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get commonWorking;

  /// Heading for Settings and the drawer action that opens it.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// Button to dismiss a dialog without applying its action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Button to dismiss a message.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Button to grant an Android permission.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get commonGrant;

  /// Button to enable a feature.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get commonEnable;

  /// Button to refresh the displayed status.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// Button to test a connection.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get commonTest;

  /// Button to install an update.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get commonInstall;

  /// Button to save edited settings.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Button to retry a failed action.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Button to copy a value to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// Add action button.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// Remove action button.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// Close action button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get commonBrowse;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get commonSet;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get commonHour;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get commonMinute;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get commonUp;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get commonDown;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Could not save'**
  String get commonSaveFailed;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get commonColorWhite;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get commonColorWarm;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get commonColorAmber;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get commonColorRed;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get commonColorGreen;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get commonColorBlue;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get commonColorCyan;

  /// Shared dialog action, time picker label or color preset.
  ///
  /// In en, this message translates to:
  /// **'Dim'**
  String get commonColorDim;

  /// Shared picker action or loading state.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Shared picker action or loading state.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get commonMoveUp;

  /// Shared picker action or loading state.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get commonMoveDown;

  /// Shared picker action or loading state.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get commonPreviousMonth;

  /// Shared picker action or loading state.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get commonNextMonth;

  /// Shared picker action or loading state.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// Button to choose an item.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get commonChoose;

  /// Validation error for the server port.
  ///
  /// In en, this message translates to:
  /// **'Enter a port between 1024 and 65535, or leave it empty'**
  String get dlnaPortInvalid;

  /// Select every item in a multi-selection list.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get commonSelectAll;

  /// Playback failure caused by the device video decoder.
  ///
  /// In en, this message translates to:
  /// **'This device cannot decode this video.'**
  String get dlnaCannotDecode;

  /// Playback failure caused by an unreadable file.
  ///
  /// In en, this message translates to:
  /// **'This file could not be read.'**
  String get dlnaCannotRead;

  /// Playback failure or accessibility label for the failed media icon.
  ///
  /// In en, this message translates to:
  /// **'This media could not be played.'**
  String get dlnaCannotPlay;

  /// Help below a playback failure.
  ///
  /// In en, this message translates to:
  /// **'See the App Logs for details'**
  String get dlnaSeeLogs;

  /// Accessibility label for the loading spinner.
  ///
  /// In en, this message translates to:
  /// **'Loading media'**
  String get dlnaLoading;

  /// Accessibility label for the failed image icon.
  ///
  /// In en, this message translates to:
  /// **'This image could not be displayed.'**
  String get dlnaImageFailed;

  /// Accessibility label for tapping the overlay to stop playback.
  ///
  /// In en, this message translates to:
  /// **'Stop playback'**
  String get dlnaStop;

  /// Plugin action label. Both values come from the plugin and are kept as supplied.
  ///
  /// In en, this message translates to:
  /// **'{pluginName}: {actionTitle}'**
  String drawerPluginAction(String pluginName, String actionTitle);

  /// Error heading after a plugin action fails.
  ///
  /// In en, this message translates to:
  /// **'Plugin action'**
  String get drawerPluginActionErrorTitle;

  /// Fallback error when a plugin provides no error text.
  ///
  /// In en, this message translates to:
  /// **'Could not run this action.'**
  String get drawerPluginActionError;

  /// Opens the configured Home Assistant dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get drawerDashboard;

  /// Toggles the Home Assistant header and sidebar. Shown when the menu shortcut is enabled.
  ///
  /// In en, this message translates to:
  /// **'HA Kiosk Mode'**
  String get drawerHaKiosk;

  /// Opens the default camera view. Shown when that view contains cameras.
  ///
  /// In en, this message translates to:
  /// **'Camera View'**
  String get drawerCameraView;

  /// Opens the intercom when it is enabled and available.
  ///
  /// In en, this message translates to:
  /// **'Intercom'**
  String get drawerIntercom;

  /// Opens Music Assistant when its address and menu shortcut are configured. Keep the product name.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant'**
  String get drawerMusicAssistant;

  /// Shown while the floating player is visible.
  ///
  /// In en, this message translates to:
  /// **'Hide Floating Player'**
  String get drawerHidePlayer;

  /// Shown while the floating player is hidden.
  ///
  /// In en, this message translates to:
  /// **'Show Floating Player'**
  String get drawerShowPlayer;

  /// Opens the full-screen player when a track is available and the shortcut is enabled.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get drawerNowPlaying;

  /// Starts the screensaver when its menu shortcut is enabled.
  ///
  /// In en, this message translates to:
  /// **'Start Screensaver'**
  String get drawerScreensaver;

  /// Activates lockdown when its menu shortcut is enabled.
  ///
  /// In en, this message translates to:
  /// **'Lockdown Mode'**
  String get drawerLockdown;

  /// Releases a hold so screensaver and timers can resume.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Hold Mode'**
  String get drawerHoldOff;

  /// Pauses screensaver and timers to keep the current view on screen.
  ///
  /// In en, this message translates to:
  /// **'Turn On Hold Mode'**
  String get drawerHoldOn;

  /// Opens the app launcher when it is enabled and has allowed apps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get drawerApps;

  /// Clears the embedded browser cache.
  ///
  /// In en, this message translates to:
  /// **'Clear web cache'**
  String get drawerClearCache;

  /// Shown when device owner or Shizuku access allows a restart. Also the confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Restart Device'**
  String get drawerRestartDevice;

  /// Confirmation before restarting Android.
  ///
  /// In en, this message translates to:
  /// **'Restart this device? Kiosk Satellite comes back when it boots.'**
  String get drawerRestartConfirm;

  /// Button that confirms the device restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get drawerRestart;

  /// Hidden when Kiosk Satellite is the home screen. Also the confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Exit Application'**
  String get drawerExitApplication;

  /// Confirmation before closing the application.
  ///
  /// In en, this message translates to:
  /// **'Close Kiosk Satellite?'**
  String get drawerExitConfirm;

  /// Button that confirms closing the application.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get drawerExit;

  /// Notice below the menu while hold mode is active.
  ///
  /// In en, this message translates to:
  /// **'Hold mode is on'**
  String get drawerHoldActive;

  /// Tappable notice that releases hold mode.
  ///
  /// In en, this message translates to:
  /// **'Screensaver and timers are paused · tap to turn off'**
  String get drawerHoldHelp;

  /// Tooltip for the dark theme button at the bottom of the drawer.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get drawerThemeDark;

  /// Tooltip for the light theme button at the bottom of the drawer.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get drawerThemeLight;

  /// Tooltip for matching the Android theme. This controls appearance, not language.
  ///
  /// In en, this message translates to:
  /// **'Follow Android'**
  String get drawerThemeAndroid;

  /// Current version below the drawer actions. Tap to check for updates.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String drawerVersion(String version);

  /// Notice shown when a newer version is available.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get drawerUpdateAvailable;

  /// Tappable update notice below the drawer actions.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · tap to install'**
  String drawerUpdateInstall(String version);

  /// Progress notice during a manual update check.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get drawerUpdateChecking;

  /// Heading when the installed version is current.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get drawerUpdateCurrent;

  /// Result of a successful check with no update.
  ///
  /// In en, this message translates to:
  /// **'You are on the latest version.'**
  String get drawerUpdateCurrentHelp;

  /// Heading when the manual update check fails.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get drawerUpdateCheckFailed;

  /// Help after an update check fails.
  ///
  /// In en, this message translates to:
  /// **'Is the device online?'**
  String get drawerUpdateOffline;

  /// Title of the update confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Update to {version}'**
  String drawerUpdateTo(String version);

  /// Help below the release notes.
  ///
  /// In en, this message translates to:
  /// **'The download starts on Update. Android asks you to confirm the installation.'**
  String get drawerUpdateInstructions;

  /// Notice when the overlay permission is missing.
  ///
  /// In en, this message translates to:
  /// **'Without the \"Display over other apps\" permission the app cannot reopen itself after updating.'**
  String get drawerUpdateRelaunch;

  /// Button that starts downloading an update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get drawerUpdate;

  /// Title of the download progress dialog.
  ///
  /// In en, this message translates to:
  /// **'Downloading update'**
  String get drawerUpdateDownloading;

  /// Progress text before a download percentage is available.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get drawerUpdateStarting;

  /// Title when downloading or installing fails. Technical error details remain as supplied.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get drawerUpdateFailed;

  /// Dialog title when there is no longer an update to install.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get drawerUpdates;

  /// Placeholder when a release has no notes. Published release notes remain as supplied.
  ///
  /// In en, this message translates to:
  /// **'No release notes.'**
  String get drawerNoReleaseNotes;

  /// Summary when no entities are excluded.
  ///
  /// In en, this message translates to:
  /// **'All available entities exposed'**
  String get esphomeAllExposed;

  /// Number of excluded entities.
  ///
  /// In en, this message translates to:
  /// **'{count} excluded'**
  String esphomeExcludedCount(String count);

  /// Entity search hint and accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Search entities'**
  String get esphomeEntitySearch;

  /// Loading notice.
  ///
  /// In en, this message translates to:
  /// **'Loading entities…'**
  String get esphomeEntityLoading;

  /// An excluded entity that the server no longer reports.
  ///
  /// In en, this message translates to:
  /// **'Currently unavailable'**
  String get esphomeEntityUnavailable;

  /// No results for the search.
  ///
  /// In en, this message translates to:
  /// **'No matching entities'**
  String get esphomeEntityNoMatch;

  /// Entity loading failure.
  ///
  /// In en, this message translates to:
  /// **'Could not load entities. Close the picker and try again.'**
  String get esphomeEntityLoadFailed;

  /// Entity selection save failure.
  ///
  /// In en, this message translates to:
  /// **'Could not save exclusions. Try again.'**
  String get esphomeEntitySaveFailed;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get esphomeTypeConfig;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get esphomeTypeDiagnostics;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Sensor'**
  String get esphomeTypeSensorGroup;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get esphomeTypeControl;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'sensor'**
  String get esphomeTypeSensor;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'text sensor'**
  String get esphomeTypeTextSensor;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'binary sensor'**
  String get esphomeTypeBinarySensor;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'camera'**
  String get esphomeTypeCamera;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'switch'**
  String get esphomeTypeSwitch;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'button'**
  String get esphomeTypeButton;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'number'**
  String get esphomeTypeNumber;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'select'**
  String get esphomeTypeSelect;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'light'**
  String get esphomeTypeLight;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'update'**
  String get esphomeTypeUpdate;

  /// Entity category or type label. Entity names and identifiers remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get esphomeTypeText;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get filesUpload;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get filesUploading;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get filesUploadFailed;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get filesUploaded;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'\"All files access\" permission missing'**
  String get filesPermissionMissing;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Without it only the app folder can be browsed. The grant screen opens on the tablet.'**
  String get filesPermissionHelp;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Grant on device'**
  String get filesGrant;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Up one folder'**
  String get filesUp;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Shared storage'**
  String get filesShared;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'App folder'**
  String get filesApp;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Could not read the folder'**
  String get filesReadFailed;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get filesEmpty;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get filesEmptyHelp;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get filesFolder;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get filesDownload;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get filesDownloadFailed;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String filesDeleteTitle(String name);

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'The file is removed from the device.'**
  String get filesDeleteHelp;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid path'**
  String get filesInvalidPath;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'No such folder'**
  String get filesNoFolder;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'No such file'**
  String get filesNoFile;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot read folder: {error}'**
  String filesReadError(String error);

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Write failed: {error}'**
  String filesWriteError(String error);

  /// Shown if deleting the selected file fails.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the file'**
  String get filesDeleteFailed;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Fleet Management needs the remote admin'**
  String get fleetFleetManagementNeedsTheRemoteAdmin;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosks find each other through it. Turn on Remote management and Find other kiosks under Device, then come back.'**
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Lead this fleet'**
  String get fleetLeadThisFleet;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Sync this kiosk\'s settings to its followers. Requires all kiosks to run the same version.'**
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'A kiosk that follows a leader cannot lead.'**
  String get fleetAKioskThatFollowsALeaderCannotLead;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get fleetFollowers;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get fleetProfiles;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get fleetLeader;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Learn which settings sync and which do not in the '**
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Fleet Management documentation'**
  String get fleetFleetManagementDocumentation;

  /// Accessible label for the follower actions menu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get fleetMore;

  /// Search result description.
  ///
  /// In en, this message translates to:
  /// **'The kiosks this one leads, their state and a way to add one.'**
  String get fleetSearchFollowers;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Add a kiosk'**
  String get fleetAddAKiosk;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Add a discovered kiosk or enter its IP address. The follower must accept the invitation on its screen.'**
  String get fleetKiosksMemberOfTheFleetAFollowerMustConfirm;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get fleetSendInvitation;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Invite again'**
  String get fleetInviteAgain;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String fleetRemoveName(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'It stops following this kiosk and keeps its settings.'**
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to lead this kiosk'**
  String fleetNameWantsToLeadThisKiosk(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Its settings replace this kiosk\'s in the categories it syncs, from now on. This kiosk keeps its name and identity.'**
  String get fleetItsSettingsReplaceThisKioskSInTheCategories;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Its settings replace this kiosk\'s in the categories it syncs, from now on. This kiosk keeps its name, its Home Assistant, Music Assistant and ESPHome selves and its hardware picks. You can leave the fleet at any time under Settings, Fleet Management.'**
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Confirm on the kiosk itself. The invitation is waiting on its screen and under Settings, Fleet Management.'**
  String get fleetConfirmOnTheKioskItselfTheInvitationIsWaiting;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get fleetAccept;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Looking for other kiosks…'**
  String get fleetLookingForOtherKiosks;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No kiosks discovered. Use Add by IP to find one at a known address.'**
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Follows {name}'**
  String fleetFollowsName(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Leads a fleet'**
  String get fleetLeadsAFleet;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No Fleet Management'**
  String get fleetNoFleetManagement;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosks on this network that do not follow this one. Pick one to choose what it gets, then the invitation goes out. A kiosk on a build without Fleet Management joins once it runs one.'**
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Joined the fleet'**
  String get fleetJoinedTheFleet;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Settings from the leader arrive shortly.'**
  String get fleetSettingsFromTheLeaderArriveShortly;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'Add by IP'**
  String get fleetAddByIp;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'Find kiosk'**
  String get fleetFindKiosk;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'Finding kiosk…'**
  String get fleetFindingKiosk;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get fleetIpAddress;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'Remote admin port'**
  String get fleetRemoteAdminPort;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'Enter the kiosk IP address and remote admin port.'**
  String get fleetAddressHelp;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Add a profile'**
  String get fleetAddAProfile;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'The collection of settings, credentials and exclusions to sync.'**
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get fleetNewProfile;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get fleetProfile;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Updates only'**
  String get fleetUpdatesOnly;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Nothing syncs. Only updates are pushed.'**
  String get fleetNothingSyncsOnlyUpdatesArePushed;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Categories: {selected} of {total}. Credentials: {credentials} of {credentialTotal}. Excluded: {excluded}.'**
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  );

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'This profile is gone'**
  String get fleetThisProfileIsGone;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'It was deleted from another page.'**
  String get fleetItWasDeletedFromAnotherPage;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fleetName;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get fleetRename;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Rename profile'**
  String get fleetRenameProfile;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'What it syncs'**
  String get fleetWhatItSyncs;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get fleetNothing;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosks on this profile keep every setting of their own. The leader only pushes updates to them.'**
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get fleetCategories;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total}: {names}'**
  String fleetSelectedOfTotalNames(String selected, String total, String names);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get fleetCredentials;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'None travel'**
  String get fleetNoneTravel;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Include the dashboard'**
  String get fleetIncludeTheDashboard;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'The start page and the default dashboard.'**
  String get fleetTheStartPageAndTheDefaultDashboard;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Excluded settings'**
  String get fleetExcludedSettings;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'One setting left out'**
  String get fleetOneSettingLeftOut;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} settings left out'**
  String fleetCountSettingsLeftOut(String count);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No kiosks assigned'**
  String get fleetNoKiosksAssigned;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Assign this profile to a kiosk on the Fleet Management page.'**
  String get fleetAssignThisProfileToAKioskOnTheFleet;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get fleetDuplicate;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Clone this profile into a new one.'**
  String get fleetCloneThisProfileIntoANewOne;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Duplicate profile'**
  String get fleetDuplicateProfile;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String fleetNameCopy(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get fleetDeleteProfile;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No kiosk is on it.'**
  String get fleetNoKioskIsOnIt;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosks on it get the Default profile.'**
  String get fleetKiosksOnItGetTheDefaultProfile;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String fleetDeleteName(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Black screens'**
  String get fleetBlackScreens;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Sync to {name}'**
  String fleetSyncToName(String name);

  /// Name of the built-in default profile. Custom names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get fleetDefault;

  /// No categories or excluded settings are selected.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get fleetNone;

  /// Search result description.
  ///
  /// In en, this message translates to:
  /// **'The named lists a follower can be given: categories, credentials, the dashboard and the settings left out.'**
  String get fleetSearchProfiles;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get fleetSyncNow;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Changed here, waiting for the leader'**
  String get fleetChangedHereWaitingForTheLeader;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Synced {time}'**
  String fleetSyncedTime(String time);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the first sync'**
  String get fleetWaitingForTheFirstSync;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get fleetNothingYet;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No credentials'**
  String get fleetNoCredentials;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'With the {names}'**
  String fleetWithTheNames(String names);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'the dashboard'**
  String get fleetTheDashboard;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'no dashboard'**
  String get fleetNoDashboard;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'The dashboard'**
  String get fleetTheDashboardDetail;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No dashboard'**
  String get fleetNoDashboardDetail;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Synced from the leader'**
  String get fleetSyncedFromTheLeader;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Leave the fleet'**
  String get fleetLeaveTheFleet;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Stops the sync. Settings stay as they are.'**
  String get fleetStopsTheSyncSettingsStayAsTheyAre;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Leave the fleet?'**
  String get fleetLeaveTheFleetDetail;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{name} stops pushing settings here. Everything stays as it is now.'**
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get fleetLeave;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get fleetJustNow;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String fleetCountMinAgo(String count);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String fleetCountHAgo(String count);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String fleetCountDaysAgo(String count);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{name} leads these settings. A change here is replaced at the next sync.'**
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Declined on the kiosk'**
  String get fleetDeclinedOnTheKiosk;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Waiting for its OK'**
  String get fleetWaitingForItsOk;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Left the fleet'**
  String get fleetLeftTheFleet;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Sending {percent}%'**
  String fleetSendingPercent(String percent);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Installing'**
  String get fleetInstalling;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Runs {version}, this kiosk needs an update'**
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Needs {version}'**
  String fleetNeedsVersion(String version);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String fleetDownloadingPercent(String percent);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get fleetSyncing;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'Unreachable'**
  String get fleetErrorUnreachable;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'Bad answer'**
  String get fleetErrorBadAnswer;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'The push failed'**
  String get fleetErrorThePushFailed;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'Lead this fleet is off'**
  String get fleetErrorLeadThisFleetIsOff;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'The remote admin and Find other kiosks must be on'**
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'Pick another kiosk'**
  String get fleetErrorPickAnotherKiosk;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'That kiosk is not on the network right now'**
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'That kiosk did not answer'**
  String get fleetErrorThatKioskDidNotAnswer;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'That kiosk refused the invitation'**
  String get fleetErrorThatKioskRefusedTheInvitation;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'The Default profile stays'**
  String get fleetErrorTheDefaultProfileStays;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'The Updates only profile stays'**
  String get fleetErrorTheUpdatesOnlyProfileStays;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'No such profile'**
  String get fleetErrorNoSuchProfile;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'No such follower'**
  String get fleetErrorNoSuchFollower;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'No invitation is waiting'**
  String get fleetErrorNoInvitationIsWaiting;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'Malformed invitation'**
  String get fleetErrorMalformedInvitation;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'Could not mint a token'**
  String get fleetErrorCouldNotMintAToken;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'not a follower yet'**
  String get fleetErrorNotAFollowerYet;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get fleetErrorOffline;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'up to date'**
  String get fleetErrorUpToDate;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'already downloading'**
  String get fleetErrorAlreadyDownloading;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'did not answer'**
  String get fleetErrorDidNotAnswer;

  /// Reason a fleet action failed or a kiosk update was skipped.
  ///
  /// In en, this message translates to:
  /// **'did not take the upload'**
  String get fleetErrorDidNotTakeTheUpload;

  /// Accessible control guidance or action result.
  ///
  /// In en, this message translates to:
  /// **'A profile named {name} exists'**
  String fleetProfileNameExists(String name);

  /// Accessible control guidance or action result.
  ///
  /// In en, this message translates to:
  /// **'already on {version}'**
  String fleetAlreadyOnVersion(String version);

  /// Accessible control guidance or action result.
  ///
  /// In en, this message translates to:
  /// **'That kiosk runs a build without Fleet Management. It joins once it runs one.'**
  String get fleetUnsupportedBuild;

  /// The saved address answers as another kiosk or a member of another fleet.
  ///
  /// In en, this message translates to:
  /// **'The address belongs to a different kiosk or fleet'**
  String get fleetErrorAddressMismatch;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IP address.'**
  String get fleetErrorInvalidIp;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'Enter a port from 1 to 65535.'**
  String get fleetErrorInvalidPort;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'This kiosk identity is not ready yet. Try again.'**
  String get fleetErrorIdentityNotReady;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'That address did not return a valid kiosk identity.'**
  String get fleetErrorInvalidIdentity;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'This kiosk already belongs to this fleet.'**
  String get fleetErrorAlreadyMember;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'That kiosk leads a fleet.'**
  String get fleetErrorIsLeader;

  /// Address lookup label, guidance or validation result before sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'That kiosk already follows another leader.'**
  String get fleetErrorOtherLeader;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Switch kiosk'**
  String get fleetSwitchKiosk;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Discovered kiosks and saved fleet members. Picking one opens its remote admin here, on this same page.'**
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No other kiosks found. Kiosks appear through network discovery or saved fleet membership.'**
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Synced Credentials'**
  String get fleetSyncedCredentials;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'The settings on this list will not be synced to the followers.'**
  String get fleetTheSettingsOnThisListWillNotBeSynced;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Nothing left out'**
  String get fleetNothingLeftOut;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Sync it again'**
  String get fleetSyncItAgain;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Add a setting'**
  String get fleetAddASetting;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Exclude a setting'**
  String get fleetExcludeASetting;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get fleetSearchSettings;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} more. Type to narrow the list.'**
  String fleetCountMoreTypeToNarrowTheList(String count);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Not synced: {note}'**
  String fleetNotSyncedNote(String note);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'the assigned satellite'**
  String get fleetTheAssignedSatellite;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'microphone and speaker devices, mic gain'**
  String get fleetMicrophoneAndSpeakerDevicesMicGain;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'the device camera'**
  String get fleetTheDeviceCamera;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'the followed player, the Sendspin player id'**
  String get fleetTheFollowedPlayerTheSendspinPlayerId;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'node name, MAC, encryption key'**
  String get fleetNodeNameMacEncryptionKey;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'the PIN is also synced'**
  String get fleetThePinIsAlsoSynced;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'the key, unless synced as a credential'**
  String get fleetTheKeyUnlessSyncedAsACredential;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'name, remote administration, renderer workarounds, scale'**
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant token'**
  String get fleetHomeAssistantToken;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant token'**
  String get fleetMusicAssistantToken;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Immich API key'**
  String get fleetImmichApiKey;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Update the fleet'**
  String get fleetUpdateTheFleet;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Update the whole fleet to the Kiosk Satellite version running on the leader.'**
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Keep followers on this version'**
  String get fleetKeepFollowersOnThisVersion;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Automatically update all followers to the Kiosk Satellite version running on the leader.'**
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Nothing to update'**
  String get fleetNothingToUpdate;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get fleetUpdating;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'{names} installing.'**
  String fleetNamesInstalling(String names);

  /// Search result description.
  ///
  /// In en, this message translates to:
  /// **'Install the release offered to each follower, then here.'**
  String get fleetSearchUpdates;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get gestureAction;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Go to a dashboard view'**
  String get gestureNavigate;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open a web page'**
  String get gestureUrl;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show a camera view'**
  String get gestureCameraView;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open the app launcher'**
  String get gestureLauncher;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open Call a kiosk'**
  String get gestureIntercomOpen;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call a kiosk'**
  String get gestureIntercomCall;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Start the screensaver'**
  String get gestureScreensaver;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Stop the screensaver'**
  String get gestureScreensaverStop;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Toggle hold mode'**
  String get gestureHoldMode;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Toggle HA kiosk mode'**
  String get gestureHaKiosk;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Run a plugin action'**
  String get gesturePluginRun;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open another app'**
  String get gestureLaunchApp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open a deep link'**
  String get gestureDeepLink;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open Android Settings'**
  String get gestureAndroidSettings;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call a service'**
  String get gestureService;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Run a script'**
  String get gestureScript;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Trigger an automation'**
  String get gestureAutomation;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Fire an event'**
  String get gestureEvent;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Plugin action'**
  String get gesturePluginAction;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Plugin actions'**
  String get gesturePluginActions;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enable a plugin with actions in Plugin Manager first.'**
  String get gesturePluginHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not load plugin actions.'**
  String get gesturePluginFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enter a full http(s) URL.'**
  String get gestureUrlError;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Package name'**
  String get gesturePackage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enter a package name.'**
  String get gesturePackageError;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enter a full URI.'**
  String get gestureUriError;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No dashboards'**
  String get gestureNoDashboards;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not list dashboards'**
  String get gestureDashboardsFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Is Home Assistant connected?'**
  String get gestureHaConnected;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not list dashboards. Is Home Assistant connected?'**
  String get gestureDashboardsHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Camera view'**
  String get gestureCameraTitle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show {name}'**
  String gestureCameraShow(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Close the camera view'**
  String get gestureCameraClose;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No camera views configured yet.'**
  String get gestureCameraEmpty;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No kiosk found on the network yet.'**
  String get gestureIntercomEmpty;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} taps in the {corner} corner'**
  String gestureDescribeCornerTaps(String count, String corner);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Hold the {corner} corner for {seconds}s'**
  String gestureDescribeCornerHold(String corner, String seconds);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count}-finger double tap'**
  String gestureDescribeFingerDouble(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count}-finger tap'**
  String gestureDescribeFingerTap(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count}-finger hold for {seconds}s'**
  String gestureDescribeFingerHold(String count, String seconds);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Corner sequence: {sequence}'**
  String gestureDescribeSequence(String sequence);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} claps'**
  String gestureDescribeClaps(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show an open hand'**
  String get gestureDescribeOpenHand;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show {count} finger'**
  String gestureDescribeOneFinger(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show {count} fingers'**
  String gestureDescribeFingers(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'top-left'**
  String get gestureTopLeft;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'top-right'**
  String get gestureTopRight;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'bottom-left'**
  String get gestureBottomLeft;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'bottom-right'**
  String get gestureBottomRight;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Go to {value}'**
  String gestureGoTo(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open {value}'**
  String gestureOpen(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Toggle the camera view'**
  String get gestureCameraToggle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Toggle camera view {name}'**
  String gestureCameraToggleName(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call {value}'**
  String gestureCall(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open app {package}'**
  String gestureOpenApp(String package);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Run {value}'**
  String gestureRun(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Trigger {value}'**
  String gestureTriggerAction(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Fire event {value}'**
  String gestureFireEvent(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Looks good.'**
  String get gestureValid;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not validate.'**
  String get gestureValidationFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Domain {value} not found.'**
  String gestureDomainMissing(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Service {value} not found.'**
  String gestureServiceMissing(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Entity {value} not found.'**
  String gestureEntityMissing(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enter a {domain}.* entity.'**
  String gestureEntityRequired(String domain);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Script entity'**
  String get gestureScriptEntity;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Automation entity'**
  String get gestureAutomationEntity;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get gestureDomain;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Entity (optional)'**
  String get gestureEntityOptional;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Service data (optional)'**
  String get gestureServiceData;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call a Home Assistant service'**
  String get gestureServiceTitle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Domain and service are required.'**
  String get gestureServiceRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Service data must be a JSON object.'**
  String get gestureServiceJson;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get gestureEventType;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Event data (optional)'**
  String get gestureEventData;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Fire a Home Assistant event'**
  String get gestureEventTitle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Event type is required.'**
  String get gestureEventRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Event data must be a JSON object.'**
  String get gestureEventJson;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Hand Gesture Tester'**
  String get gestureTester;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open tester'**
  String get gestureOpenTester;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Turn on the camera in Camera settings first.'**
  String get gestureCameraFirst;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Watch which fingers the camera reads, to learn how to hold your hand.'**
  String get gestureTesterHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Hold your hand up at shoulder height, palm to the camera, fingers spread. Curl a finger all the way down to drop it from the count. Tuck the thumb across the palm to show four: the thumb only counts on an open hand.'**
  String get gestureHandHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Gestures do not fire while the tester is open.'**
  String get gestureTesterPaused;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show a hand to the camera.'**
  String get gestureShowHand;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Triggers: {action}'**
  String gestureTesterTrigger(String action);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No gesture uses this count.'**
  String get gestureNoCount;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No hand in view'**
  String get gestureNoHand;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Reading the hand'**
  String get gestureReadingHand;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No fingers up'**
  String get gestureNoFingers;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} hands in view, reading the larger one.'**
  String gestureHandsCount(String count);

  /// Description in settings search results.
  ///
  /// In en, this message translates to:
  /// **'A live look at the fingers the camera reads.'**
  String get gestureTesterSearch;

  /// Hand gesture hold setting or confirmation feedback.
  ///
  /// In en, this message translates to:
  /// **'Hold confirmed'**
  String get gestureHoldConfirmed;

  /// Hand gesture hold setting or confirmation feedback.
  ///
  /// In en, this message translates to:
  /// **'Hold progress: {progress}'**
  String gestureHoldProgress(String progress);

  /// Hand gesture hold setting or confirmation feedback.
  ///
  /// In en, this message translates to:
  /// **'Hold duration: {duration}'**
  String gestureTesterHoldDuration(String duration);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant Service'**
  String get gestureHaServiceKind;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant Script'**
  String get gestureHaScriptKind;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant Automation'**
  String get gestureHaAutomationKind;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant Event'**
  String get gestureHaEventKind;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Ran {value}'**
  String gestureRan(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not run {value}'**
  String gestureRunFailed(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Called {value}'**
  String gestureCalled(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not call {value}'**
  String gestureCallFailed(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Triggered {value}'**
  String gestureTriggered(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not trigger {value}'**
  String gestureTriggerFailed(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Fired event {value}'**
  String gestureFired(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not fire event {value}'**
  String gestureFireFailed(String value);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get gestureDone;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get gestureFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Edit gesture'**
  String get gestureEdit;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Gesture'**
  String get gestureTrigger;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Taps in a corner'**
  String get gestureCornerTaps;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Hold a corner'**
  String get gestureCornerHold;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Multi-finger tap'**
  String get gestureFingerTaps;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Multi-finger hold'**
  String get gestureFingerHold;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Corner sequence'**
  String get gestureSequence;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Claps'**
  String get gestureClaps;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show fingers'**
  String get gestureShowFingers;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Corner'**
  String get gestureCorner;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Top-left corner'**
  String get gestureCornerTl;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Top-right corner'**
  String get gestureCornerTr;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Bottom-left corner'**
  String get gestureCornerBl;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Bottom-right corner'**
  String get gestureCornerBr;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Taps'**
  String get gestureTaps;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'2 taps'**
  String get gestureTaps2;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'3 taps'**
  String get gestureTaps3;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'4 taps'**
  String get gestureTaps4;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Fingers'**
  String get gestureFingers;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'1 finger'**
  String get gestureFinger1;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'2 fingers'**
  String get gestureFinger2;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'3 fingers'**
  String get gestureFinger3;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'4 fingers'**
  String get gestureFinger4;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open hand (5)'**
  String get gestureOpenHand5;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Single tap'**
  String get gestureSingleTap;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Double tap'**
  String get gestureDoubleTap;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Hold for {seconds} s'**
  String gestureHoldDuration(String seconds);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Requires the camera enabled and a well lit environment.'**
  String get gestureCameraHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device.'**
  String get gestureUnavailable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'2 claps'**
  String get gestureClaps2;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'3 claps'**
  String get gestureClaps3;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'4 claps'**
  String get gestureClaps4;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Claps are heard through the microphone, with or without wake word detection.'**
  String get gestureClapHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Tap the corners in order (2 to 8 steps).'**
  String get gestureSequenceHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Remove last step'**
  String get gestureRemoveStep;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get gestureUndo;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Choose an action'**
  String get gestureChooseAction;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'What this gesture triggers.'**
  String get gestureActionHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Tap to change.'**
  String get gestureChangeHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Choose an action.'**
  String get gestureChooseError;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add at least two corners.'**
  String get gestureSequenceError;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get intercomCall;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No kiosk is ready.'**
  String get intercomNoReady;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'1 kiosk is ready.'**
  String get intercomOneReady;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} kiosks are ready.'**
  String intercomManyReady(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call a kiosk'**
  String get intercomCallKiosk;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Announce to all'**
  String get intercomAnnounceAll;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Talk to every kiosk. One way only.'**
  String get intercomAnnounceHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Missed call from {name}'**
  String intercomMissedFrom(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Rang for {seconds} seconds.'**
  String intercomRangFor(String seconds);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call back'**
  String get intercomCallBack;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get intercomDeclined;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get intercomBusy;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Its intercom is off'**
  String get intercomPeerOff;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Different intercom key'**
  String get intercomPeerKey;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get intercomNoAnswer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Did not answer'**
  String get intercomDidNotAnswer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The voice link failed'**
  String get intercomVoiceFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get intercomCancelled;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The page took the microphone'**
  String get intercomPageMic;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Nobody could take it'**
  String get intercomNobody;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get intercomDone;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get intercomEnded;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get intercomAnnouncement;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Announcing to 1 kiosk'**
  String get intercomAnnouncingOne;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Announcing to {count} kiosks'**
  String intercomAnnouncingMany(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'is calling'**
  String get intercomIsCalling;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'is announcing'**
  String get intercomIsAnnouncing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get intercomCalling;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Answers in {seconds} s'**
  String intercomAnswersIn(String seconds);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Ringing'**
  String get intercomRinging;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get intercomConnecting;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Done, {duration}'**
  String intercomDoneDuration(String duration);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call ended, {duration}'**
  String intercomEndedDuration(String duration);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get intercomDecline;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get intercomAnswer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Every kiosk'**
  String get intercomEveryKiosk;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get intercomStop;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{name} hears you'**
  String intercomHearsYou(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Every kiosk hears you'**
  String get intercomAllHearYou;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Hold to talk, let go to listen'**
  String get intercomHoldHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get intercomMuted;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get intercomMute;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get intercomEnd;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get intercomReply;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get intercomDismiss;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Call again'**
  String get intercomCallAgain;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The dashboard holds the microphone, listening only.'**
  String get intercomDashboardMic;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Microphone not granted, listening only.'**
  String get intercomMicDenied;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Hold to talk'**
  String get intercomHoldTalk;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get intercomPlaying;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'a kiosk'**
  String get intercomAKiosk;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}'**
  String intercomCallingName(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{name} is calling'**
  String intercomNameCalling(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'In a call with {name}'**
  String intercomInCallName(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{name} is announcing'**
  String intercomNameAnnouncing(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant: {message}'**
  String intercomHaMessage(String message);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get intercomEndCall;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not call'**
  String get intercomCallFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not change the key'**
  String get intercomKeyFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not talk to everyone'**
  String get intercomBroadcastFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The device did not answer.'**
  String get intercomDeviceNoAnswer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'unknown kiosk'**
  String get intercomUnknownKiosk;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'nothing is ringing'**
  String get intercomNothingRinging;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'no call'**
  String get intercomNoCall;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'intercom is off'**
  String get intercomDisabled;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'needs the remote admin'**
  String get intercomNeedsRemote;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'the intercom needs the remote admin and Find other kiosks'**
  String get intercomNeedsDiscovery;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'already in a call'**
  String get intercomAlreadyCalling;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'no kiosk is ready'**
  String get intercomNoReadyError;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'a key is at least 16 characters'**
  String get intercomKeyLength;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'the page holds the microphone'**
  String get intercomMicHeld;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'microphone not granted'**
  String get intercomMicPermission;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'the caller did not answer'**
  String get intercomCallerNoAnswer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get intercomMissedcall;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get intercomListening;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Announcements off'**
  String get intercomAnnouncementsoff;

  /// Shown when kiosks have different intercom encryption settings.
  ///
  /// In en, this message translates to:
  /// **'Encryption mismatch'**
  String get intercomEncryptionMismatch;

  /// Shown when kiosks have different intercom encryption settings.
  ///
  /// In en, this message translates to:
  /// **'Encryption mismatch. Enable Encrypt communications on all kiosks in the call.'**
  String get intercomEncryptionMismatchHelp;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Press back again to close the app'**
  String get kioskBackClose;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Press back again to go back'**
  String get kioskBackAgain;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Hold mode on'**
  String get kioskHoldOn;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Hold mode off'**
  String get kioskHoldOff;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'The current view stays until you turn it off.'**
  String get kioskHoldNotice;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get kioskDownloadComplete;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get kioskDownloadFailed;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get kioskDownload;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get kioskDownloading;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get kioskOpen;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get kioskTip;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Swipe from the left edge to open the menu.'**
  String get kioskMenuHint;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Unknown kiosk link'**
  String get kioskUnknownLink;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Could not open the app'**
  String get kioskOpenAppFailed;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Android System WebView is not installed'**
  String get kioskWebViewMissing;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'This device has no WebView provider, so Home Assistant cannot be shown. Install Android System WebView or Chrome, then restart Kiosk Satellite.'**
  String get kioskWebViewMissingHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosk PIN'**
  String get kioskPinTitle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get kioskPinHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get kioskWrongPin;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get kioskUnlock;

  /// Brief notice shown when touching the locked screen.
  ///
  /// In en, this message translates to:
  /// **'Screen is locked'**
  String get lockdownScreenLocked;

  /// Console tab and docked panel title.
  ///
  /// In en, this message translates to:
  /// **'Web Console'**
  String get logsWebConsole;

  /// Open the console over the kiosk page.
  ///
  /// In en, this message translates to:
  /// **'Dock over the live page'**
  String get logsDock;

  /// Empty console notice.
  ///
  /// In en, this message translates to:
  /// **'No console output yet'**
  String get logsNoOutput;

  /// Subject when sharing console output.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite console log'**
  String get logsShareSubject;

  /// Empty JavaScript command input hint.
  ///
  /// In en, this message translates to:
  /// **'Run JavaScript in the page'**
  String get logsInput;

  /// Remote JavaScript command input hint.
  ///
  /// In en, this message translates to:
  /// **'Run JavaScript in the page (Enter to run, Up/Down for history)'**
  String get logsInputHistory;

  /// Execute the JavaScript entered by the user.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get logsRun;

  /// Fallback when JavaScript evaluation fails without details.
  ///
  /// In en, this message translates to:
  /// **'evaluation failed'**
  String get logsEvaluationFailed;

  /// Console command connection failure.
  ///
  /// In en, this message translates to:
  /// **'device unreachable'**
  String get logsDeviceUnreachable;

  /// Number of stored log or console entries.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String logsEntries(String count);

  /// Copy button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy log'**
  String get logsCopyLog;

  /// Share button tooltip in the docked console.
  ///
  /// In en, this message translates to:
  /// **'Share log'**
  String get logsShareLog;

  /// Successful clipboard notification title.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get logsCopied;

  /// Failed clipboard notification title.
  ///
  /// In en, this message translates to:
  /// **'Could not copy'**
  String get logsCopyFailed;

  /// Successful copy notification.
  ///
  /// In en, this message translates to:
  /// **'The log is on the clipboard.'**
  String get logsOnClipboard;

  /// Successful console copy notification.
  ///
  /// In en, this message translates to:
  /// **'The console log is on the clipboard.'**
  String get logsConsoleOnClipboard;

  /// Explanation above the Android log.
  ///
  /// In en, this message translates to:
  /// **'Android system log for this app (crashes live here)'**
  String get logsSystemLog;

  /// Severity filter.
  ///
  /// In en, this message translates to:
  /// **'Errors & crashes'**
  String get logsErrors;

  /// Severity filter.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get logsWarnings;

  /// Severity filter.
  ///
  /// In en, this message translates to:
  /// **'Info & debug'**
  String get logsInfo;

  /// Empty filtered log notice.
  ///
  /// In en, this message translates to:
  /// **'No matching lines. Enable more types above to see the full log.'**
  String get logsNoMatches;

  /// Fallback when the device cannot return its system log.
  ///
  /// In en, this message translates to:
  /// **'logcat unavailable'**
  String get logsUnavailable;

  /// Failure notice with the original technical error.
  ///
  /// In en, this message translates to:
  /// **'Could not read logcat: {error}'**
  String logsReadFailed(String error);

  /// Fallback detail when a failure provides no error.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get logsUnknown;

  /// Heading when the device has a network but the dashboard failed to load.
  ///
  /// In en, this message translates to:
  /// **'Dashboard unavailable'**
  String get offlineDashboard;

  /// Heading when the dashboard load failed and the device is offline.
  ///
  /// In en, this message translates to:
  /// **'No network connection'**
  String get offlineNetwork;

  /// Explanation below Dashboard unavailable.
  ///
  /// In en, this message translates to:
  /// **'The page could not be loaded.'**
  String get offlinePageHelp;

  /// Explanation below No network connection.
  ///
  /// In en, this message translates to:
  /// **'The dashboard will come back when the network does.'**
  String get offlineNetworkHelp;

  /// Persistent notification over the dashboard during an outage.
  ///
  /// In en, this message translates to:
  /// **'Network connection lost'**
  String get offlineLost;

  /// Brief notification after the network returns.
  ///
  /// In en, this message translates to:
  /// **'Network connection restored'**
  String get offlineRestored;

  /// Playback button tooltip and accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get mediaPlay;

  /// Playback button tooltip and accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get mediaPause;

  /// Playback button tooltip and accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get mediaPreviousTrack;

  /// Playback button tooltip and accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get mediaNextTrack;

  /// Playback status or fallback text when a floating player track has no title.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get mediaPlaying;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get mediaPaused;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get mediaIdle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get mediaStatusUnavailable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Unknown track'**
  String get mediaUnknownTrack;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{status} - {source}'**
  String mediaStatusSource(String status, String source);

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Show volume'**
  String get mediaShowVolume;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Hide volume'**
  String get mediaHideVolume;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mediaMute;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get mediaUnmute;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get mediaFavoriteAdd;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get mediaFavoriteRemove;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Turn shuffle on'**
  String get mediaShuffleOn;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Turn shuffle off'**
  String get mediaShuffleOff;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get mediaRepeatAll;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get mediaRepeatOne;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Turn repeat off'**
  String get mediaRepeatOff;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Show lyrics'**
  String get mediaShowLyrics;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Hide lyrics'**
  String get mediaHideLyrics;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Show queue'**
  String get mediaShowQueue;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Hide queue'**
  String get mediaHideQueue;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get mediaVolume;

  /// Button tooltip or slider accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get mediaPlaybackPosition;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show Now Playing'**
  String get mediaShowNowPlaying;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show the floating player'**
  String get mediaShowFloatingPlayer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open Music Assistant'**
  String get mediaOpenMusicAssistant;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'command not supported or not sent'**
  String get mediaCannotControl;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Nothing queued'**
  String get mediaNothingQueued;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get mediaChapters;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get mediaNowPlaying;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get mediaUpNext;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String mediaUnnamedChapter(String number);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Leads the group'**
  String get mediaGroupLead;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The group could not be read.'**
  String get mediaGroupReadFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No other players to group with.'**
  String get mediaGroupEmpty;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Speaker selection'**
  String get mediaSpeakerSelection;

  /// Close button tooltip and accessibility label. The placeholder is the window title supplied by the plugin.
  ///
  /// In en, this message translates to:
  /// **'Close {name}'**
  String pluginCloseWindow(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get pluginActions;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosk drawer'**
  String get pluginKioskDrawer;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'To assign a gesture, open Gestures and choose Run a plugin action.'**
  String get pluginToAssignAGestureOpenGesturesAndChooseRun;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Show in kiosk drawer'**
  String get pluginShowInKioskDrawer;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Also available while locked if the kiosk drawer is allowed.'**
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Expose to Home Assistant'**
  String get pluginExposeToHomeAssistant;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Adds a button to the kiosk ESPHome device. Requires ESPHome and native entities.'**
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Select an entity'**
  String get pluginSelectAnEntity;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Choose {name}'**
  String pluginChooseName(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Configure {name}'**
  String pluginConfigureName(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Plugin'**
  String get pluginPlugin;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Enable Plugins'**
  String get pluginEnablePlugins;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Plugins add additional community developed features to Kiosk Satellite.'**
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Installed plugins'**
  String get pluginInstalledPlugins;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No plugins installed. Add a repository to get started.'**
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Developer Tools'**
  String get pluginDeveloperTools;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Create a plugin'**
  String get pluginCreateAPlugin;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Learn how to create plugins with the Hello World template and documentation.'**
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'This plugin is no longer installed.'**
  String get pluginThisPluginIsNoLongerInstalled;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Enable Plugins to run this plugin.'**
  String get pluginEnablePluginsToRunThisPlugin;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Enable this plugin from its entry row to run it.'**
  String get pluginEnableThisPluginFromItsEntryRowToRun;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Uninstall {name}?'**
  String pluginUninstallName(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Uninstall {name}'**
  String pluginUninstallNameDetail(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Check for updates for {name}'**
  String pluginCheckForUpdatesForName(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String pluginAboutName(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'This removes the plugin and its settings.'**
  String get pluginThisRemovesThePluginAndItsSettings;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get pluginUninstall;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No updates available.'**
  String get pluginNoUpdatesAvailable;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'This plugin was installed from ZIP and has no repository README.'**
  String get pluginThisPluginWasInstalledFromZipAndHasNo;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get pluginImageUnavailable;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link.'**
  String get pluginCouldNotOpenThisLink;

  /// Accessible control guidance or action result.
  ///
  /// In en, this message translates to:
  /// **'Enable {name}'**
  String pluginEnableName(String name);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Add plugin'**
  String get pluginAddPlugin;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Install from a GitHub repository'**
  String get pluginInstallFromAGithubRepository;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Make sure you trust the plugin\'s author and its code before installing it.'**
  String get pluginMakeSureYouTrustThePluginSAuthorAnd;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get pluginPreview;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Installed version'**
  String get pluginInstalledVersion;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get pluginAuthor;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get pluginLicense;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Plugins run code inside Kiosk Satellite and can access app data and granted Android permissions. A faulty or malicious plugin can expose private information or stop the app from working. Only install plugins from authors you trust.'**
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'New plugins start disabled. Updates preserve the enabled state and automatically restart running plugins.'**
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Trust and update'**
  String get pluginTrustAndUpdate;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Trust and install'**
  String get pluginTrustAndInstall;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Install from ZIP'**
  String get pluginInstallFromZip;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'For developers only: test a local build'**
  String get pluginForDevelopersOnlyTestALocalBuild;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Plugin ZIP'**
  String get pluginPluginZip;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Plugin ZIP must be at most 4 MB'**
  String get pluginPluginZipMustBeAtMost4Mb;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected ZIP'**
  String get pluginCouldNotReadTheSelectedZip;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get pluginCharts;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get pluginReadings;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Waiting for samples'**
  String get pluginWaitingForSamples;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get pluginLatest;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get pluginSelected;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get pluginNoDataYet;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Tap or drag to inspect samples. Double-tap to follow the latest.'**
  String get pluginTapOrDragToInspectSamplesDoubleTapTo;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get pluginNoData;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get pluginOn;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get pluginEmpty;

  /// Accessible control guidance or action result.
  ///
  /// In en, this message translates to:
  /// **'Use arrow keys to inspect samples and End for the latest.'**
  String get pluginChartKeyboardHelp;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid asset path'**
  String get pluginErrorAssetPath;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Asset is missing or outside its package'**
  String get pluginErrorAssetMissing;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Asset directory cannot be a symbolic link'**
  String get pluginErrorAssetSymlink;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Asset directories cannot be symbolic links'**
  String get pluginErrorAssetSymlinks;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Installed assets failed their integrity check'**
  String get pluginErrorAssetsIntegrity;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Installed asset failed its integrity check'**
  String get pluginErrorAssetIntegrity;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Package manifest does not match the reviewed release manifest'**
  String get pluginErrorManifestMismatch;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Staging directory already exists'**
  String get pluginErrorStagingExists;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot create plugin directory'**
  String get pluginErrorCreateDirectory;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'At most 512 package files are supported'**
  String get pluginErrorFileCount;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot protect plugin file'**
  String get pluginErrorProtectFile;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Expanded plugin exceeds 4 MB'**
  String get pluginErrorExpandedSize;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Manifest exceeds 32 KB'**
  String get pluginErrorManifestSize;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Package needs kiosk-satellite-plugin.json, plugin.jar and LICENSE'**
  String get pluginErrorRequiredFiles;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Native libraries require native capability'**
  String get pluginErrorNativeCapability;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid native ELF library'**
  String get pluginErrorNativeElf;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Native library ABI does not match its directory'**
  String get pluginErrorNativeAbi;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'plugin.jar must contain only DEX files'**
  String get pluginErrorDexOnly;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid DEX header'**
  String get pluginErrorDexHeader;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Expanded DEX exceeds 4 MB'**
  String get pluginErrorDexSize;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Empty DEX file'**
  String get pluginErrorDexEmpty;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'plugin.jar has no classes.dex'**
  String get pluginErrorDexMissing;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Unexpected or duplicate ZIP entry: {name}'**
  String pluginErrorZipEntry(String name);

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'The repository release belongs to a different plugin.'**
  String get pluginErrorRepositoryMismatch;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Enter a public https://github.com/owner/repository URL'**
  String get pluginErrorRepositoryUrl;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Use the repository URL without a file or branch path'**
  String get pluginErrorRepositoryPath;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Plugin download redirected outside GitHub'**
  String get pluginErrorDownloadOutsideGithub;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid GitHub redirect'**
  String get pluginErrorInvalidRedirect;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Public repository, stable release, kiosk-satellite-plugin.json, README.md or release asset was not found.'**
  String get pluginErrorRepositoryNotFound;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'GitHub denied the request or its request limit was reached. Try again later.'**
  String get pluginErrorGithubLimited;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Repository file exceeds the size limit'**
  String get pluginErrorRepositorySize;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Too many GitHub redirects'**
  String get pluginErrorTooManyRedirects;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'GitHub did not return a published stable release'**
  String get pluginErrorStableRelease;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid release tag'**
  String get pluginErrorReleaseTag;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid kiosk-satellite-plugin.json manifest'**
  String get pluginErrorManifestFile;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid plugin ID or version'**
  String get pluginErrorIdVersion;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid release checksum or package filename'**
  String get pluginErrorChecksumFilename;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'The release checksum must match GitHub asset SHA-256 digest'**
  String get pluginErrorGithubDigest;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'GitHub did not return the release tag revision'**
  String get pluginErrorTagRevision;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you trust the plugin author'**
  String get pluginErrorTrustAuthor;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'This preview expired. Preview the repository again before installing.'**
  String get pluginErrorPreviewExpired;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Package SHA-256 does not match the reviewed release'**
  String get pluginErrorReviewedChecksum;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Plugin is not installed'**
  String get pluginErrorNotInstalled;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'This plugin was installed from ZIP. Use Install from ZIP to update it.'**
  String get pluginErrorUpdateZip;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Plugins are available on Android.'**
  String get pluginErrorAndroidOnly;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'GitHub request failed ({status})'**
  String pluginErrorGithubRequest(String status);

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Release needs exactly one uploaded {name} asset'**
  String pluginErrorReleaseAsset(String name);

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Release asset {name} must be published by GitHub Actions. Manually uploaded files are not supported.'**
  String pluginErrorAssetPublisher(String name);

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Release asset {name} exceeds the size limit or is empty'**
  String pluginErrorAssetSize(String name);

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid release URL for {name}'**
  String pluginErrorAssetUrl(String name);

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Plugin has no native library for this device ABI'**
  String get pluginErrorNativeLibrary;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Plugin callback timed out. Restart Kiosk if the plugin left work running.'**
  String get pluginErrorCallbackTimeout;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Enable the plugin first'**
  String get pluginErrorEnableFirst;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot save plugin state'**
  String get pluginErrorSaveState;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid installed package hash'**
  String get pluginErrorPackageHash;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Package SHA-256 does not match'**
  String get pluginErrorChecksum;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'This plugin ID belongs to another repository. Uninstall it before changing sources.'**
  String get pluginErrorDifferentRepository;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'This plugin did not stop cleanly. Restart Kiosk Satellite before replacing it.'**
  String get pluginErrorRestartReplace;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'At most 8 plugins can be installed'**
  String get pluginErrorPluginLimit;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'This package is already installed'**
  String get pluginErrorAlreadyInstalled;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Previously loaded package failed its integrity check. Restart Kiosk Satellite before reinstalling it.'**
  String get pluginErrorLoadedIntegrity;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot remove unused package'**
  String get pluginErrorRemovePackage;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot install plugin package'**
  String get pluginErrorInstallPackage;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Update canceled because the plugin did not stop cleanly. Restart Kiosk Satellite before trying again.'**
  String get pluginErrorUpdateCanceled;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'The previous version was retained.'**
  String get pluginErrorVersionRetained;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'The previous version was retained but is disabled. Restart Kiosk Satellite before enabling it.'**
  String get pluginErrorRetainedDisabled;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'The previous version is running again.'**
  String get pluginErrorVersionRunning;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Enable Plugins first'**
  String get pluginErrorEnablePlugins;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'This plugin did not stop cleanly. Restart Kiosk Satellite before enabling it.'**
  String get pluginErrorRestartEnable;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Installed plugin failed its integrity check. Reinstall it.'**
  String get pluginErrorInstalledIntegrity;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Android version is too old'**
  String get pluginErrorAndroidOld;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Installed native libraries failed their integrity check'**
  String get pluginErrorNativeIntegrity;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Installed native library failed its integrity check'**
  String get pluginErrorNativeFileIntegrity;

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot read installed plugin: {error}'**
  String pluginErrorReadInstalled(String error);

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'The previous version could not restart: {error}'**
  String pluginErrorPreviousRestart(String error);

  /// Explain the failure and recovery action. Keep plugin identifiers and diagnostic details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Plugin update failed: {error}. {recovery}'**
  String pluginErrorUpdateFailed(String error, String recovery);

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Shizuku 13 or later is required. Tap for setup instructions.'**
  String get pluginShizuku13OrLaterIsRequiredTapForSetup;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Start Shizuku on this device. Tap for setup instructions.'**
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Shizuku grants Kiosk Satellite shell or root access. Installed plugins run inside KS, so only grant access if you trust them.'**
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get pluginSetUp;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get pluginGrantAccess;

  /// Visible label, help or status in this section.
  ///
  /// In en, this message translates to:
  /// **'Approve the permission request on the kiosk.'**
  String get pluginApproveThePermissionRequestOnTheKiosk;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid plugin ID'**
  String get pluginErrorInvalidId;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid version'**
  String get pluginErrorInvalidVersion;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid entry class'**
  String get pluginErrorEntryClass;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Unsupported manifest schema'**
  String get pluginErrorManifestSchema;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'This plugin needs a different SDK version'**
  String get pluginErrorSdkVersion;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Minimum Android SDK must be at least 24'**
  String get pluginErrorMinimumSdk;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Unsupported plugin capability'**
  String get pluginErrorCapability;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Too many settings or commands'**
  String get pluginErrorTooManySettings;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid or duplicate setting key'**
  String get pluginErrorSettingKey;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Display groups must be an array'**
  String get pluginErrorGroupsArray;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Too many display groups'**
  String get pluginErrorTooManyGroups;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Display groups must name unique settings groups'**
  String get pluginErrorUniqueGroups;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Too many group references'**
  String get pluginErrorGroupReferences;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid or duplicate group reference'**
  String get pluginErrorDuplicateReference;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid or duplicate command ID'**
  String get pluginErrorCommandId;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Unknown plugin setting'**
  String get pluginErrorUnknownSetting;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Text settings must be at most 512 characters'**
  String get pluginErrorTextLength;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Expected a Home Assistant entity ID'**
  String get pluginErrorEntityId;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Expected a boolean setting'**
  String get pluginErrorBoolean;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Expected an RGB hex color'**
  String get pluginErrorColor;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Expected a numeric setting'**
  String get pluginErrorNumber;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Numeric setting is outside its range'**
  String get pluginErrorRange;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Numeric setting does not match its step'**
  String get pluginErrorStep;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid selection setting'**
  String get pluginErrorSelection;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Unknown selection option'**
  String get pluginErrorSelectionOption;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Unsupported setting type'**
  String get pluginErrorSettingType;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid plugin manifest'**
  String get pluginErrorInvalidManifest;

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Plugin needs Android API {version}'**
  String pluginErrorAndroidApi(String version);

  /// Explain the failure. Keep technical identifiers, file names and product names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid {field}'**
  String pluginErrorInvalidField(String field);

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Turn off remote management?'**
  String get remoteDisableTitle;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'WARNING: You will no longer be able to access this page. To switch it back on, use the device or the Remote management switch in Home Assistant.'**
  String get remoteDisableHelp;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Turn it off'**
  String get remoteDisableConfirm;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Select the key and copy it by hand.'**
  String get remoteCopyHelp;

  /// Shown if the device rejects or cannot save a setting.
  ///
  /// In en, this message translates to:
  /// **'Could not save this setting. Try again.'**
  String get remoteSaveSettingFailed;

  /// Heading while reconnecting after losing an established connection.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get remoteReconnecting;

  /// Connection notice with the original device name.
  ///
  /// In en, this message translates to:
  /// **'The connection to {name} was lost. This page resumes on its own when it is back.'**
  String remoteConnectionLost(String name);

  /// Connection notice when the device has no name or model.
  ///
  /// In en, this message translates to:
  /// **'The connection to the kiosk was lost. This page resumes on its own when it is back.'**
  String get remoteConnectionLostUnnamed;

  /// Reloads remote administration in the browser.
  ///
  /// In en, this message translates to:
  /// **'Reload page'**
  String get remoteReloadPage;

  /// Heading when the connected device is running a newer build.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite was updated'**
  String get remoteUpdated;

  /// Automatic reload countdown after the device version changes.
  ///
  /// In en, this message translates to:
  /// **'The device is now running version {version}{build}. This page belongs to the previous version and will reload in {seconds} s.'**
  String remoteUpdatedHelp(String version, String build, String seconds);

  /// Optional build suffix after the app version. Keep the initial space.
  ///
  /// In en, this message translates to:
  /// **' (build {build})'**
  String remoteBuild(String build);

  /// Reloads remote administration immediately instead of waiting for the countdown.
  ///
  /// In en, this message translates to:
  /// **'Reload now'**
  String get remoteReloadNow;

  /// Login button.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get remoteLogin;

  /// Login error after a rejected password.
  ///
  /// In en, this message translates to:
  /// **'Invalid password'**
  String get remoteInvalidPassword;

  /// Login error while the existing rate limit is active.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait 5 minutes and try again.'**
  String get remoteLoginThrottled;

  /// Explain the failed action and any permission the user must grant on the device. Keep Android and Shizuku names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Turning the screen off needs a one-time permission. The tablet is now showing the \"device admin\" grant screen. Approve it there, then try again.'**
  String get deviceScreenOffPermission;

  /// Explain the failed action and any permission the user must grant on the device. Keep Android and Shizuku names unchanged.
  ///
  /// In en, this message translates to:
  /// **'The device admin permission is not active.'**
  String get deviceAdminInactive;

  /// Explain the failed action and any permission the user must grant on the device. Keep Android and Shizuku names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Restarting needs the \"Display over other apps\" permission or the app cannot bring itself back. The grant screen is opening on the device; allow it there and retry.'**
  String get deviceRestartOverlay;

  /// Explain the failed action and any permission the user must grant on the device. Keep Android and Shizuku names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Restarting the device needs Kiosk Satellite provisioned as the device owner or a granted Shizuku connection.'**
  String get deviceRebootPermission;

  /// Explain the failed action and any permission the user must grant on the device. Keep Android and Shizuku names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Restart is only available on Android.'**
  String get deviceRestartAndroidOnly;

  /// Explain the failed action and any permission the user must grant on the device. Keep Android and Shizuku names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Shizuku refused the restart'**
  String get deviceRestartShizukuRefused;

  /// Keep {error} unchanged. It contains the failure details.
  ///
  /// In en, this message translates to:
  /// **'Restart failed: {error}'**
  String deviceRestartFailed(String error);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get overviewAttention;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get overviewOpen;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get overviewUpdate;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to lead this kiosk'**
  String overviewInvitation(String name);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Confirm on the kiosk screen or under Fleet Management there.'**
  String get overviewInvitationHelp;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'1 follower runs another release'**
  String get overviewOutdatedOne;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'{count} followers run another release'**
  String overviewOutdatedMany(String count);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'{names}. Sync waits for version {version}.'**
  String overviewSyncWaiting(String names, String version);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'this release'**
  String get overviewThisRelease;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get overviewUpdateAvailable;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite {version} is ready to install. The installation is confirmed on the tablet screen.'**
  String overviewInstallHelp(String version);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant not set up'**
  String get overviewHaSetup;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Connect the kiosk to Home Assistant to load a dashboard.'**
  String get overviewHaSetupHelp;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get overviewSetUp;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant not validated'**
  String get overviewHaNotValidated;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'The URL and token have not passed a connection check this run. The kiosk retries every 30 seconds.'**
  String get overviewHaNotValidatedHelp;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Open setup'**
  String get overviewOpenSetup;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word detection stopped'**
  String get overviewWakeStopped;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'The engine was released.'**
  String get overviewWakeReleased;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Open Voice Satellite'**
  String get overviewOpenVoice;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Open service'**
  String get overviewOpenService;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Permission missing: {permission}'**
  String overviewPermissionMissing(String permission);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Quick controls'**
  String get overviewQuick;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Reload page'**
  String get overviewReload;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Screen on'**
  String get overviewScreenOn;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Screen off'**
  String get overviewScreenOff;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Start screensaver'**
  String get overviewSaverStart;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Dismiss screensaver'**
  String get overviewSaverStop;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Show camera view'**
  String get overviewCameraShow;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Dismiss camera view'**
  String get overviewCameraHide;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Postpone screensaver'**
  String get overviewSaverPostpone;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Do not disturb'**
  String get overviewDnd;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Do not disturb on'**
  String get overviewDndOn;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Take snapshot'**
  String get overviewSnapshot;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get overviewCheckUpdates;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Restart app'**
  String get overviewRestartApp;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Restart device'**
  String get overviewRestartDevice;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Exit app'**
  String get overviewExit;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get overviewBrightness;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Master Volume'**
  String get overviewVolume;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Brightness is using an app-level fallback. Grant \"Modify system settings\" so the slider controls the panel\'s actual brightness.'**
  String get overviewBrightnessGrant;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Restart this device? Kiosk Satellite comes back when it boots.'**
  String get overviewRestartQuestion;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get overviewRestart;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'No snapshot came back.'**
  String get overviewNoSnapshot;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Camera snapshot'**
  String get overviewSnapshotTitle;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Update check failed. Can the device reach GitHub?'**
  String get overviewUpdateCheckFailed;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'You are on the latest version.'**
  String get overviewLatest;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String overviewVersionAvailable(String version);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Install it from Needs attention.'**
  String get overviewInstallAttention;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'No camera view has any cameras yet. Add cameras to a view under Cameras first.'**
  String get overviewNoViewsWithCameras;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Could not show view'**
  String get overviewShowViewFailed;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get overviewAppVersion;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get overviewNotSetup;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Not validated'**
  String get overviewNotValidated;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Checking filter...'**
  String get overviewCheckingFilter;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Validated'**
  String get overviewValidated;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Filter status unavailable'**
  String get overviewFilterUnavailable;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Updates unfiltered'**
  String get overviewUnfiltered;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Watching 1 entity'**
  String get overviewWatchingOne;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Watching {count} entities'**
  String overviewWatchingMany(String count);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Filtering disabled, view uses {count} entities'**
  String overviewFilterDisabled(String count);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word detection off'**
  String get overviewWakeOff;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Listening for {words}'**
  String overviewListeningFor(String words);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get overviewListening;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Not listening'**
  String get overviewNotListening;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Entities and BT proxy'**
  String get overviewEntitiesProxy;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Entities only'**
  String get overviewEntitiesOnly;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'BT Proxy only'**
  String get overviewProxyOnly;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Home Assistant'**
  String get overviewWaitingHA;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Not running'**
  String get overviewNotRunning;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Running - 1 feature'**
  String get overviewRunningOne;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Running - {count} features'**
  String overviewRunningMany(String count);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Downloading: {version}'**
  String overviewDownloading(String version);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'New version: {version}'**
  String overviewNewVersion(String version);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Up to date: {version}'**
  String overviewCurrentVersion(String version);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get overviewCurrent;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'{name} plugin'**
  String overviewPluginAttribution(String name);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'muted'**
  String get overviewMuted;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'browser'**
  String get overviewBrowser;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Voice Satellite. The engine and wake words are configured by the integration once this device opens its dashboard.'**
  String get overviewWakeWaiting;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word detection is off. Turn it on to inherit models from Voice Satellite.'**
  String get overviewWakeDisabled;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Microphone blocked. Android will not ask again, so allow it in the app settings, then retry.'**
  String get overviewMicBlocked;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Microphone declined. Wake word detection needs it; retry to be asked again.'**
  String get overviewMicDeclined;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'The microphone stopped working. Retry, or reload the page.'**
  String get overviewMicLost;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Could not download the models from Home Assistant. Retry once it is reachable.'**
  String get overviewModelsUnavailable;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'The detector kept crashing on this device, so it was stopped. Voice Satellite is listening in the browser instead. Retry, or restart the app.'**
  String get overviewCrashed;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'The wake-word engine could not start. Retry, or reload the page.'**
  String get overviewWakeFailed;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'No native runner for {engine}. Voice Satellite keeps browser detection.'**
  String overviewNativeUnavailable(String engine);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Listening natively'**
  String get overviewNativeListening;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Ready (suspended during a voice session)'**
  String get overviewSuspended;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get overviewCpu;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'RAM'**
  String get overviewMemory;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get overviewTemperature;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'{amount} GB free'**
  String overviewMemoryFree(String amount);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String overviewMetricPercent(String value);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'{value}°C'**
  String overviewMetricDegrees(String value);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'No screenshot'**
  String get overviewNoScreenshot;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Still'**
  String get overviewStill;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get overviewLive;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Full size'**
  String get overviewFullSize;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Live, every 5 seconds'**
  String get overviewLiveInterval;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Taken {age}'**
  String overviewTaken(String age);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Camera view: {name}'**
  String overviewCameraViewNamed(String name);

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Camera view'**
  String get overviewCameraView;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Screen is off'**
  String get overviewScreenOffState;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Go to view'**
  String get overviewGoView;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Loading views…'**
  String get overviewLoadingViews;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Pick a dashboard view…'**
  String get overviewPickView;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Default view'**
  String get overviewDefaultView;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'No dashboards found'**
  String get overviewNoDashboards;

  /// Translate the interface text. Keep external names, versions and technical details unchanged.
  ///
  /// In en, this message translates to:
  /// **'Views unavailable'**
  String get overviewViewsUnavailable;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'No photos selected. Pick some in Settings.'**
  String get screensaverNoPhotos;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'No folder selected. Pick one in Settings.'**
  String get screensaverNoFolder;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'No photos or videos in {folder}'**
  String screensaverFolderEmpty(String folder);

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Could not read {folder}. Is the media permission granted?'**
  String screensaverFolderUnreadable(String folder);

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Could not read photos.'**
  String get screensaverReadPhotosFailed;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Immich is not connected. Validate it in Settings.'**
  String get screensaverImmichNotReady;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'No media matches the source and filters.'**
  String get screensaverNoMediaMatch;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'No media in the selected source.'**
  String get screensaverNoMediaSource;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the Immich server.'**
  String get screensaverImmichUnreachable;

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'{error} Retrying automatically.'**
  String screensaverRetryNotice(String error);

  /// Translate the visible message. Keep placeholders and any technical names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Every video in this playlist is too large for this device to play.'**
  String get screensaverVideosTooLarge;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable App Launcher'**
  String get settingLauncherEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Open a picked set of installed apps from the kiosk.'**
  String get settingLauncherEnabledDescription;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'The apps the launcher offers.'**
  String get settingLauncherAppsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Return automatically'**
  String get settingLauncherAutoReturnTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Come back to the kiosk once the other app has gone untouched for a while.'**
  String get settingLauncherAutoReturnDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Return after (seconds)'**
  String get settingLauncherAutoReturnSecondsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Time without a touch in the other app before the kiosk comes back.'**
  String get settingLauncherAutoReturnSecondsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite can bring itself back in the foreground and notice touches in the other app.'**
  String get launcherOverlayHeld;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Without this the kiosk cannot come back on its own, and touches in the other app go unseen.'**
  String get launcherOverlayMissing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Without this the kiosk cannot come back on its own, and touches in the other app go unseen. The grant screen appears on the tablet.'**
  String get launcherOverlayRemote;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Android may pause the app behind the other one, and a paused clock never brings the kiosk back.'**
  String get launcherBatteryMissing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Android may pause the app behind the other one, and a paused clock never brings the kiosk back. The grant dialog appears on the tablet.'**
  String get launcherBatteryRemote;

  /// Description in settings search results.
  ///
  /// In en, this message translates to:
  /// **'The grants Return automatically leans on.'**
  String get launcherPermissionsSearch;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable camera'**
  String get settingCameraEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Camera use adds CPU load and heat, which can shorten the battery and device lifespan.'**
  String get settingCameraEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get settingCameraDeviceTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Which camera to use.'**
  String get settingCameraDeviceDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Snapshot resolution'**
  String get settingCameraSnapshotResolutionTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Higher looks sharper but costs more CPU and bandwidth.'**
  String get settingCameraSnapshotResolutionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable snapshots on detection'**
  String get settingCameraDisableDetectionSnapshotsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Prevent automatic snapshots triggered by detection. Motion, face, presence and gesture detection keep working. Manual requests and Continuous snapshots can still capture images.'**
  String get settingCameraDisableDetectionSnapshotsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Continuous snapshots'**
  String get settingCameraSnapshotsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Publish a fresh camera snapshot to Home Assistant at a fixed interval.'**
  String get settingCameraSnapshotsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Snapshot interval'**
  String get settingCameraSnapshotIntervalTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Seconds between snapshots.'**
  String get settingCameraSnapshotIntervalDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get cameraFront;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cameraBack;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The only camera this device has.'**
  String get cameraOnlyCamera;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Motion sensor'**
  String get settingMotionSensorTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Expose motion as a Home Assistant sensor. WARNING: Keeps the camera running permanently, even with the screen off.'**
  String get settingMotionSensorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Clear after'**
  String get settingMotionSensorOffDelayTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Seconds without motion before the sensor reads clear.'**
  String get settingMotionSensorOffDelayDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Motion frame rate'**
  String get settingMotionFpsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Frames per second the camera checks for motion. Lower is lighter on the CPU; 2 is plenty to notice someone approaching.'**
  String get settingMotionFpsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Startup delay'**
  String get settingMotionStartDelayTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Ignore motion for this long after the camera starts, for devices whose camera physically moves as it opens.'**
  String get settingMotionStartDelayDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Motion sensitivity'**
  String get settingMotionSensitivityTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Higher trips on smaller movements. 1 needs a large change across the frame; 100 reacts to the slightest motion.'**
  String get settingMotionSensitivityDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Motion Sensor'**
  String get cameraMotionPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant motion sensor and shared detection settings'**
  String get cameraMotionHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No camera detected'**
  String get cameraNoCamera;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'This device does not report any usable camera.'**
  String get cameraNoCameraHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Camera permission missing'**
  String get cameraCameraPermission;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Without it the camera cannot be used. The grant dialog appears on the tablet screen.'**
  String get cameraCameraPermissionHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Grant on device'**
  String get cameraGrantOnDevice;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Blocked. Android will not ask again, so allow it in the app settings.'**
  String get cameraCameraBlocked;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Without this the camera cannot be used.'**
  String get cameraCameraNeeded;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get cameraAppSettings;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Latest snapshot'**
  String get cameraLatest;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No snapshot yet.'**
  String get cameraNoSnapshot;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Latest camera snapshot'**
  String get cameraImageAlt;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Take snapshot'**
  String get cameraTakeSnapshot;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Snapshot failed.'**
  String get cameraSnapshotFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Snapshot failed: {error}'**
  String cameraSnapshotError(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The camera is disabled in the Camera settings.'**
  String get cameraCameraDisabled;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'A snapshot is already in progress.'**
  String get cameraSnapshotBusy;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Camera permission not granted.'**
  String get cameraPermissionDenied;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Detection snapshots are disabled.'**
  String get cameraDetectionDisabled;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The camera returned no image.'**
  String get cameraNoImage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The camera did not answer in time.'**
  String get cameraTimedOut;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The camera is unavailable while the app is in the background.'**
  String get cameraBackground;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get cameraJustNow;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds ago'**
  String cameraSecondsAgo(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'1 minute ago'**
  String get cameraMinuteAgo;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String cameraMinutesAgo(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'1 hour ago'**
  String get cameraHourAgo;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String cameraHoursAgo(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get cameraDayAgo;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String cameraDaysAgo(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Stream Status'**
  String get cameraStatusHeading;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Connected Clients'**
  String get cameraClientsHeading;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get cameraUnavailable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get cameraStopped;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get cameraStreaming;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get cameraIdle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get cameraConnected;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get cameraChecking;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Checking stream status...'**
  String get cameraCheckingStatus;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Stream status unavailable.'**
  String get cameraStatusUnavailable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Listener is stopped.'**
  String get cameraListenerStopped;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} connected viewer. Actual video: {resolution}.'**
  String cameraViewer(String count, String resolution);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} connected viewers. Actual video: {resolution}.'**
  String cameraViewers(String count, String resolution);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Ready. The encoder starts when a viewer connects.'**
  String get cameraReady;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Requested {requested}, camera supplied {actual}.'**
  String cameraFallback(String requested, String actual);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Audio: {error}'**
  String cameraAudioError(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Audio paused while the browser uses the microphone.'**
  String get cameraAudioPaused;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Microphone audio streaming.'**
  String get cameraAudioStreaming;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Microphone audio idle.'**
  String get cameraAudioIdle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'ONVIF discovery: {error}'**
  String cameraDiscoveryError(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'ONVIF URL'**
  String get cameraOnvifUrl;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Stream URL'**
  String get cameraStreamUrl;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a network address'**
  String get cameraWaitingAddress;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Client information unavailable.'**
  String get cameraClientsUnavailable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No connected clients.'**
  String get cameraNoClients;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{status} · {transport} · Port {port}'**
  String cameraClientDetails(String status, String transport, String port);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Connected for {duration}'**
  String cameraConnectedFor(String duration);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String cameraDurationSeconds(String seconds);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String cameraDurationMinutes(String minutes, String seconds);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String cameraDurationHours(String hours, String minutes);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Set a streaming username and password to enable authentication.'**
  String get cameraCredentialsMissing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the RTSP port to be released.'**
  String get cameraPortWaiting;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not start the RTSP listener.'**
  String get cameraListenerFailed;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable camera streaming'**
  String get settingCameraRtspEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Share H.264 video with RTSP or ONVIF clients. Video encoding runs only while a viewer is connected. Hardware encoding is preferred with software fallback when needed. Uses the camera selected in Camera settings.'**
  String get settingCameraRtspEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Streaming protocol'**
  String get settingCameraStreamingProtocolTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'ONVIF lets compatible clients discover the camera and connect to its stream.'**
  String get settingCameraStreamingProtocolDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get settingCameraRtspPortTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'RTSP server port.'**
  String get settingCameraRtspPortDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get settingCameraOnvifPortTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'ONVIF server port.'**
  String get settingCameraOnvifPortDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get settingCameraRtspResolutionTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Supported streaming sizes for the selected camera and encoder. Video follows the device orientation.'**
  String get settingCameraRtspResolutionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Motion analysis while streaming'**
  String get settingCameraRtspAnalysisTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Keep motion detection, face detection and hand gestures available while viewers are connected. Turning this off can allow higher resolutions. Snapshots then use video frames at the streaming resolution.'**
  String get settingCameraRtspAnalysisDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Frame rate'**
  String get settingCameraRtspFpsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Target video frames per second. Motion keeps its separate analysis rate. Actual delivery depends on the camera.'**
  String get settingCameraRtspFpsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get settingCameraRtspBitrateTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Target video bitrate. Higher improves detail and uses more network bandwidth.'**
  String get settingCameraRtspBitrateDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Include microphone audio'**
  String get settingCameraRtspAudioTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Include microphone audio in the camera stream. Shares your microphone settings. WARNING: Increased CPU usage.'**
  String get settingCameraRtspAudioDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Require authentication'**
  String get settingCameraRtspAuthTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Require a username and password to view the stream. Authentication does not enable encryption.'**
  String get settingCameraRtspAuthDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get settingCameraRtspUsernameTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Username for streaming clients.'**
  String get settingCameraRtspUsernameDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingCameraRtspPasswordTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Set a password to start the authenticated stream.'**
  String get settingCameraRtspPasswordDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'RTSP & ONVIF Streaming'**
  String get cameraStreamingPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Share the device camera via RTSP or ONVIF'**
  String get cameraStreamingHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole port number from 1024 to 65535.'**
  String get cameraPortError;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 64 characters without spaces, quotes, colons or backslashes.'**
  String get cameraUsernameError;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No supported sizes available'**
  String get cameraNoSizes;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No supported sizes available. Check the camera connection.'**
  String get cameraNoSizesHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Resolution support'**
  String get cameraResolutionSupport;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Checking camera and H.264 encoder support...'**
  String get cameraCheckingSizes;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Only sizes supported by the camera and H.264 encoder at the current streaming settings are listed.'**
  String get cameraSupportedSizes;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Turn off Motion analysis while streaming to also use {sizes}.'**
  String cameraExtraSizes(String sizes);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Motion detection, face detection and hand gestures pause while viewers are connected. Snapshots use video frames at the streaming resolution.'**
  String get cameraAnalysisOff;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The encoder cannot use {sizes} at these settings.'**
  String cameraRejectedSizes(String sizes);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} camera sizes are excluded because the encoder cannot use them at these settings.'**
  String cameraRejectedCount(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Other camera sizes are unavailable in the current capture setup.'**
  String get cameraCaptureRejected;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Overlays'**
  String get cameraOverlaysHeading;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show date and time'**
  String get settingCameraRtspDateTimeTitle;

  /// Help for the setting.
  ///
  /// In en, this message translates to:
  /// **'Show the device date and time in the upper-left corner of the video using its date format and 12/24-hour setting.'**
  String get settingCameraRtspDateTimeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Black background'**
  String get settingCameraRtspDateTimeBackgroundTitle;

  /// Help for the setting.
  ///
  /// In en, this message translates to:
  /// **'Add a black background behind the date and time for visibility.'**
  String get settingCameraRtspDateTimeBackgroundDescription;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Encrypt stream'**
  String get settingCameraRtspTlsTitle;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Use TLS to encrypt video and audio. Requires a compatible viewer.'**
  String get settingCameraRtspTlsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'name required'**
  String get cameraStreamsNameRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'valid HTTP or HTTPS baseUrl required'**
  String get cameraStreamsBaseUrlRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'server not found'**
  String get cameraStreamsServerNotFound;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Go2RTC returned an invalid stream list'**
  String get cameraStreamsInvalidStreamList;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'kind must be go2rtc, whep or ha'**
  String get cameraStreamsKindRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'preferredProtocol must be auto, webrtc, hls or mjpeg'**
  String get cameraStreamsProtocolRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'valid serverId required'**
  String get cameraStreamsServerRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'streamName required'**
  String get cameraStreamsStreamRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'a camera.* entityId is required'**
  String get cameraStreamsEntityRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'valid WHEP URL required'**
  String get cameraStreamsWhepRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'camera not found'**
  String get cameraStreamsCameraNotFound;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'cameraIds must be a list'**
  String get cameraStreamsListRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'a view must contain 1 to 12 cameras'**
  String get cameraStreamsViewCount;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'a camera can appear only once per view'**
  String get cameraStreamsRepeatedCamera;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'view contains an unknown camera'**
  String get cameraStreamsUnknownViewCamera;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'view name must be unique'**
  String get cameraStreamsUniqueViewName;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'grid must be between 1 and 12'**
  String get cameraStreamsGridRange;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'grid is smaller than the camera count'**
  String get cameraStreamsGridTooSmall;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'view not found'**
  String get cameraStreamsViewNotFound;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'the default view cannot be deleted; empty it instead'**
  String get cameraStreamsDefaultViewDelete;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'view has no cameras'**
  String get cameraStreamsViewEmpty;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'could not read Home Assistant: {error}'**
  String cameraStreamsHaReadFailed(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'could not connect to {server}: {error}'**
  String cameraStreamsConnectFailed(String server, String error);

  /// Import error.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant is not configured or unreachable'**
  String get cameraStreamsHaUnavailable;

  /// Import error.
  ///
  /// In en, this message translates to:
  /// **'Go2RTC returned HTTP {status}'**
  String cameraStreamsHttpError(String status);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Import cameras from Home Assistant'**
  String get cameraStreamsImportHa;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add every camera of the connected Home Assistant, playing over WebRTC, HLS or MJPEG. Importing again merges new cameras.'**
  String get cameraStreamsImportHaHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get cameraStreamsImportFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get cameraStreamsImportComplete;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{added} added, {missing} missing.'**
  String cameraStreamsImportCounts(String added, String missing);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Allow H.265 streams'**
  String get settingCameraAllowH265Title;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Play H.265 camera streams as they are. A device that cannot decode H.265 shows a blank image instead.'**
  String get settingCameraAllowH265Description;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Prefer MSE over WebRTC'**
  String get settingCameraPreferMseTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Stream Go2RTC cameras over MSE first. For devices that cannot play WebRTC; adds a second or two of delay.'**
  String get settingCameraPreferMseDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Prefer HLS over WebRTC'**
  String get settingCameraPreferHlsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Stream Home Assistant cameras over HLS first. For devices that cannot play WebRTC; adds a few seconds of delay.'**
  String get settingCameraPreferHlsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Play sound for a single camera'**
  String get settingCameraSingleAudioTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Play the camera\'s sound when only one camera is on screen. Grids with several cameras stay silent.'**
  String get settingCameraSingleAudioDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom a single camera'**
  String get settingCameraPinchZoomTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Zoom into the picture with two fingers when only one camera is on screen. Drag to move around, double-tap to reset.'**
  String get settingCameraPinchZoomDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Auto-dismiss after'**
  String get settingCameraAutoDismissSecondsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Close an opened camera view on its own; 0 keeps it up. The camera screensaver is unaffected.'**
  String get settingCameraAutoDismissSecondsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get cameraStreamsPlayback;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get cameraStreamsOff;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String cameraStreamsSeconds(String seconds);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Grids with several cameras are video-only. For low-power devices, use lower resolution Go2RTC streams in views and optionally set a separate fullscreen stream.'**
  String get cameraStreamsGridHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Go2RTC servers'**
  String get cameraStreamsServers;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Import streams'**
  String get cameraStreamsImportStreams;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Delete server'**
  String get cameraStreamsDeleteServer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add Go2RTC server'**
  String get cameraStreamsAddServer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Connect to a server and import its streams.'**
  String get cameraStreamsAddServerHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Edit server'**
  String get cameraStreamsEditServer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get cameraStreamsName;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get cameraStreamsBaseUrl;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get cameraStreamsUsername;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'New password (leave blank to keep)'**
  String get cameraStreamsNewPassword;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Password (optional)'**
  String get cameraStreamsPassword;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Allow invalid TLS certificate'**
  String get cameraStreamsInvalidCertificate;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not save the server'**
  String get cameraStreamsSaveServerFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Its cameras will be removed from every view.'**
  String get cameraStreamsDeleteServerHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get cameraStreamsCameras;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No cameras configured'**
  String get cameraStreamsNoCameras;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Import cameras from Home Assistant or Go2RTC, or add one manually.'**
  String get cameraStreamsNoCamerasHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Delete camera'**
  String get cameraStreamsDeleteCamera;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add camera manually'**
  String get cameraStreamsAddManually;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Use a Go2RTC stream name, a WHEP URL or a Home Assistant camera entity.'**
  String get cameraStreamsAddManuallyHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Unknown camera'**
  String get cameraStreamsUnknownCamera;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Unknown server'**
  String get cameraStreamsUnknownServer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **' (missing)'**
  String get cameraStreamsMissing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add camera'**
  String get cameraStreamsAddCamera;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Edit camera'**
  String get cameraStreamsEditCamera;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get cameraStreamsType;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Go2RTC stream'**
  String get cameraStreamsGo2RtcStream;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Direct WHEP URL'**
  String get cameraStreamsDirectWhep;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant camera'**
  String get cameraStreamsHaCamera;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Camera entity'**
  String get cameraStreamsEntity;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Preferred protocol'**
  String get cameraStreamsProtocol;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get cameraStreamsAuto;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get cameraStreamsServer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Stream name'**
  String get cameraStreamsStreamName;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Go2RTC stream name'**
  String get cameraStreamsGo2RtcStreamName;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen stream (optional)'**
  String get cameraStreamsFullscreen;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'WHEP URL'**
  String get cameraStreamsWhep;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not save the camera'**
  String get cameraStreamsSaveCameraFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from every view.'**
  String get cameraStreamsDeleteCameraHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not load cameras.'**
  String get cameraStreamsLoadFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get cameraStreamsViews;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No cameras yet'**
  String get cameraStreamsEmptyView;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Names shown'**
  String get cameraStreamsNamesShown;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Names hidden'**
  String get cameraStreamsNamesHidden;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show view'**
  String get cameraStreamsShowView;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Delete view'**
  String get cameraStreamsDeleteView;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Create camera view'**
  String get cameraStreamsCreateView;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add a camera first.'**
  String get cameraStreamsAddFirst;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Choose and order up to 12 cameras.'**
  String get cameraStreamsChooseCameras;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not show the view'**
  String get cameraStreamsShowFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not show view'**
  String get cameraStreamsShowFailedRemote;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Edit view'**
  String get cameraStreamsEditView;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show camera names'**
  String get cameraStreamsShowNames;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Display a label over each camera.'**
  String get cameraStreamsShowNamesHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get cameraStreamsGrid;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} Camera'**
  String cameraStreamsOneCamera(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} Cameras'**
  String cameraStreamsManyCameras(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'In this view'**
  String get cameraStreamsInView;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get cameraStreamsAvailable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Position {position}'**
  String cameraStreamsPosition(String position);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Missing from Go2RTC'**
  String get cameraStreamsMissingGo2Rtc;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not save the view'**
  String get cameraStreamsSaveViewFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String cameraStreamsDeleteNamed(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cameraStreamsCannotUndo;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get cameraStreamsShow;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get cameraStreamsStop;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Basic analytics'**
  String get settingAnalyticsBasicTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Information about your device, such as model, Android version, app version, screen size and language.'**
  String get settingAnalyticsBasicDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get settingAnalyticsUsageTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Details of what you use with Kiosk Satellite.'**
  String get settingAnalyticsUsageDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingAnalyticsDiagnosticsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Share crash reports when unexpected errors occur.'**
  String get settingAnalyticsDiagnosticsDescription;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite Analytics'**
  String get deviceAnalyticsPage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Share anonymized information from your installation to help make Kiosk Satellite better and guide which devices and features get attention.'**
  String get deviceAnalyticsIntro;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Learn how we process your data'**
  String get deviceAnalyticsLearn;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'What Kiosk Satellite Analytics sends and what it never sends.'**
  String get deviceAnalyticsLearnHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Export configuration'**
  String get deviceExportConfig;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Save every setting and the page\'s local storage to a file.'**
  String get deviceExportConfigHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Download every setting and the page\'s local storage.'**
  String get deviceExportConfigRemoteHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Import configuration'**
  String get deviceImportConfig;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Replace this device\'s settings from an exported file.'**
  String get deviceImportConfigHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get deviceExportFailed;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Configuration exported'**
  String get deviceExported;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get deviceImportFailed;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'That file is not valid JSON.'**
  String get deviceInvalidJson;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get deviceImportComplete;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Applied {count} settings.'**
  String deviceAppliedSettings(String count);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Applied {count} settings. The page may reload.'**
  String deviceAppliedReload(String count);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Replace the original device'**
  String get deviceReplaceOriginal;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Replace this device\'s settings with the file\'s? The page may reload.'**
  String get deviceReplaceQuestion;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Set up as new device'**
  String get deviceNewDevice;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps the backup\'s name and ESPHome identity; the original device must stay offline.'**
  String get deviceReplaceIdentity;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Assign its own name and ESPHome identity, so both devices are unique.'**
  String get deviceNewIdentity;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Restore Webview\'s local storage'**
  String get deviceRestoreStorage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Includes the Home Assistant signed in session and the Voice Satellite assist_satellite selection - two devices must not share one satellite.'**
  String get deviceRestoreStorageHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get deviceDownload;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Choose file…'**
  String get deviceChooseFile;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Import failed.'**
  String get deviceImportFailedSentence;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Replace \"{name}\"'**
  String deviceReplaceNamed(String name);

  /// Device name field label.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get settingDeviceNameTitle;

  /// Help below the Device name field.
  ///
  /// In en, this message translates to:
  /// **'Friendly name shown in remote management and used as the device name published to Home Assistant.'**
  String get settingDeviceNameDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'mDNS name'**
  String get settingDeviceHostnameTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Reach the remote admin using this name and the configured port on the local network. Clear it to take the device name again.'**
  String get settingDeviceHostnameDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Legacy renderer'**
  String get settingDisableImpellerTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Use the older Skia renderer, for old GPUs that crash at startup. Turns itself on after two such crashes; takes effect on the next app start.'**
  String get settingDisableImpellerDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Legacy WebView renderer'**
  String get settingLegacyWebViewTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Draw the dashboard into a texture, for old GPUs that crash when it appears. Turns itself on where the device needs it; takes effect on the next app start.'**
  String get settingLegacyWebViewDescription;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Set from the device name'**
  String get deviceHostnamePlaceholder;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get deviceConfiguration;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Permissions Manager'**
  String get devicePermissionsManager;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get deviceOptions;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get deviceStatus;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get deviceConnection;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get devicePermissions;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get deviceHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get deviceAccess;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get deviceReading;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get deviceChecking;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable.'**
  String get deviceUnavailable;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Grant on device'**
  String get deviceGrantOnDevice;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get deviceAppSettings;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get deviceCopyCommand;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Open guide'**
  String get deviceOpenGuide;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get deviceNotSet;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get deviceGranted;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get deviceNotGranted;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get deviceMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Not offered'**
  String get deviceNotOffered;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get deviceOn;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get deviceOff;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Status, what keeps it running, required permissions'**
  String get deviceServiceHint;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Manage this kiosk from a browser on your network'**
  String get deviceRemoteHintActual;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Where the app looks for new releases'**
  String get deviceUpdatesHint;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Connection, Android permissions and setup'**
  String get deviceShizukuHint;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Silent update status, ADB setup and instructions'**
  String get deviceHelperHint;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Share anonymized information to help improve Kiosk Satellite'**
  String get deviceAnalyticsHint;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Model, Android version, addresses, memory, uptime'**
  String get deviceHardwareHint;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Connection, version and what the kiosk shows'**
  String get deviceHaHint;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Engine version, renderer and user agent'**
  String get deviceWebViewHint;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'•••••• (set)'**
  String get devicePasswordSet;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Could not save this setting. Try again.'**
  String get deviceSaveFailed;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Open settings on device'**
  String get deviceOpenSettingsDevice;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get deviceHardwarePage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'WebView'**
  String get deviceWebViewPage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Device model'**
  String get deviceModel;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Android version'**
  String get deviceAndroidVersion;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Android build'**
  String get deviceAndroidBuild;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'IPv4 address'**
  String get deviceIpv4;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'IPv6 addresses'**
  String get deviceIpv6;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'App uptime'**
  String get deviceAppUptime;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Network uptime'**
  String get deviceNetworkUptime;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'CPU usage'**
  String get deviceCpuUsage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'CPU temperature'**
  String get deviceCpuTemp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Battery level'**
  String get deviceBatteryLevel;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Screen brightness'**
  String get deviceScreenBrightness;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Screen status'**
  String get deviceScreenStatus;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Screen size'**
  String get deviceScreenSize;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'RAM (free/total)'**
  String get deviceRam;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Internal storage (free/total)'**
  String get deviceStorage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant URL'**
  String get deviceHaUrl;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Wake word detection'**
  String get deviceWakeDetection;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Wake word status'**
  String get deviceWakeStatus;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get deviceEngine;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Wake words'**
  String get deviceWakeWords;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Stop word'**
  String get deviceStopWord;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Motion detection'**
  String get deviceMotionDetection;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Face detection'**
  String get deviceFaceDetection;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get deviceProvider;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get deviceVersion;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'User agent'**
  String get deviceUserAgent;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'plugged'**
  String get devicePlugged;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get deviceLowMemory;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Required system permissions'**
  String get deviceRequiredPermissions;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Grants are given on this device, so each button opens an Android dialog or settings screen here. Some brands add their own battery or autostart manager on top, which Android cannot report.'**
  String get devicePermissionIntro;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Grants are given on the device, so each button opens an Android dialog or settings screen there. Some brands add their own battery or autostart manager on top, which Android cannot report.'**
  String get devicePermissionIntroRemote;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get deviceMicrophone;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Allows microphone usage for wake word detection, speech to text and intercom calls.'**
  String get deviceMicrophoneHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Unrestricted battery'**
  String get deviceBattery;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Allows the process to run in the background without being paused or killed.'**
  String get deviceBatteryHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get deviceCamera;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Motion detection and snapshots can use the camera.'**
  String get deviceCameraHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get deviceBluetooth;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The Bluetooth proxy can scan for nearby devices.'**
  String get deviceBluetoothHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get deviceNotifications;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Allows the Kiosk Satellite Service\'s ongoing notification, which says what it is keeping alive.'**
  String get deviceNotificationsHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Display over other apps'**
  String get deviceOverlay;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite can bring itself back in the foreground.'**
  String get deviceOverlayHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Modify system settings'**
  String get deviceWriteSettings;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Brightness changes set the panel\'s real brightness.'**
  String get deviceWriteSettingsHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'System UI guard'**
  String get deviceUiGuard;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The notification shade and recents close on their own while the screen is protected.'**
  String get deviceUiGuardHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Device admin'**
  String get deviceDeviceAdmin;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Allows the app to turn the screen off.'**
  String get deviceDeviceAdminHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'All files access'**
  String get deviceAllFiles;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The File Manager can browse the shared storage.'**
  String get deviceAllFilesHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Usage access'**
  String get deviceUsageAccess;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The Foreground app sensor can name whichever app is on screen.'**
  String get deviceUsageAccessHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get deviceLocation;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Pages, Bluetooth scanning and the location sensors can use the device position.'**
  String get deviceLocationHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Blocked. Android will not ask again, so allow it in the app settings.'**
  String get deviceMicBlocked;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Wake word detection is on and nothing is listening.'**
  String get deviceMicMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Needed by wake word detection, the intercom and pages that ask for the microphone.'**
  String get deviceMicIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Android may pause the app when the screen is off, dropping the Home Assistant connection and the ESPHome entities with it.'**
  String get deviceBatteryMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The camera is switched on and cannot be opened.'**
  String get deviceCameraMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Needed by motion detection, camera snapshots and pages that ask for the camera.'**
  String get deviceCameraIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The Bluetooth proxy is switched on and cannot scan.'**
  String get deviceBluetoothMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth scanning needs the Location permission.'**
  String get deviceBluetoothLocation;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Location is off in the device settings, so Bluetooth scanning finds nothing.'**
  String get deviceBluetoothLocationOff;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Needed by the Bluetooth proxy to scan for devices.'**
  String get deviceBluetoothIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Needed to show the Kiosk Satellite Service\'s ongoing notification.'**
  String get deviceNotificationMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Without this the app cannot reopen itself after a crash, an update or a wake word heard behind another app.'**
  String get deviceOverlayMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Lets the app bring itself back to the front, and the lockdown shield cover the whole screen.'**
  String get deviceOverlayIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Brightness only dims the app window, so the panel and Home Assistant never see the change.'**
  String get deviceBrightnessMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Needed to set the panel\'s real brightness rather than dimming the app window.'**
  String get deviceBrightnessIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The notification shade and recents stay reachable. Enable Kiosk Satellite under Accessibility.'**
  String get deviceGuardMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Closes the notification shade and recents while kiosk mode protects the screen.'**
  String get deviceGuardIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Lets Screen off power the panel down instead of only blacking it out.'**
  String get deviceAdminIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Lets the File Manager browse the shared storage instead of only the app folder.'**
  String get deviceFilesIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Lets the Foreground app sensor name apps other than Kiosk Satellite.'**
  String get deviceUsageIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Android will not deliver Bluetooth scan results without Location, and the location sensors cannot read the GPS receiver.'**
  String get deviceLocationMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Used by pages that ask for your location, by Bluetooth scanning and by the ESPHome location sensors.'**
  String get deviceLocationIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Without this the service cannot relaunch the kiosk after a crash or a close from recents.'**
  String get deviceServiceOverlayMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Needed to relaunch the kiosk after a crash.'**
  String get deviceServiceOverlayIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Background listening is on and nothing is listening.'**
  String get deviceListeningMissing;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Needed by background listening.'**
  String get deviceListeningIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Needed by motion detection.'**
  String get deviceMotionIdle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'This device has no settings screen for it. Grant it over adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite'**
  String get deviceBatteryAdb;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'This device has no settings screen for it. Grant it over adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow'**
  String get deviceOverlayAdb;

  /// Switch label.
  ///
  /// In en, this message translates to:
  /// **'Remote management'**
  String get settingRemoteEnabledTitle;

  /// Help below the switch.
  ///
  /// In en, this message translates to:
  /// **'Run the embedded admin web server.'**
  String get settingRemoteEnabledDescription;

  /// Server port field label.
  ///
  /// In en, this message translates to:
  /// **'Server port'**
  String get settingRemotePortTitle;

  /// Help below the Server port field.
  ///
  /// In en, this message translates to:
  /// **'Port for the remote admin interface.'**
  String get settingRemotePortDescription;

  /// Admin password field label.
  ///
  /// In en, this message translates to:
  /// **'Admin password'**
  String get settingRemotePasswordTitle;

  /// Help below the Admin password field.
  ///
  /// In en, this message translates to:
  /// **'Required to log in to the remote interface.'**
  String get settingRemotePasswordDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Find other kiosks'**
  String get settingRemoteFleetDiscoveryTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Announce this device on the network and list the other kiosks in the remote admin, to switch between them.'**
  String get settingRemoteFleetDiscoveryDescription;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Remote Administration'**
  String get deviceRemotePage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Admin address'**
  String get deviceAdminAddress;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Open this address in a browser on your computer.'**
  String get deviceAdminAddressHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get deviceByName;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The same address by hostname, on networks that resolve .local names.'**
  String get deviceByNameHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Set an admin password below to start the server.'**
  String get devicePasswordNeeded;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The server is not running.'**
  String get deviceServerStopped;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Could not listen on port {port}: {error}'**
  String devicePortError(String port, String error);

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Use HTTPS'**
  String get settingRemoteTlsTitle;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Encrypt the remote admin, API and WebSocket. Your browser may ask you to accept the device certificate.'**
  String get settingRemoteTlsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Keep the CPU awake while the screen is off'**
  String get settingServiceCpuAwakeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Holds a wake lock through dark spells so connections and timers keep running on time. Costs battery on an unplugged tablet.'**
  String get settingServiceCpuAwakeDescription;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite Service'**
  String get deviceServicePage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeping it running'**
  String get deviceKeepingRunning;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get deviceService;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get deviceStopped;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Stopped.'**
  String get deviceStoppedSentence;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get deviceRunning;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Running.'**
  String get deviceRunningSentence;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Running without the foreground exemption.'**
  String get deviceRunningBackground;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Foreground service types'**
  String get deviceServiceTypes;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'What the service declares to Android for the features it holds up.'**
  String get deviceServiceTypesHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'None declared.'**
  String get deviceNoneDeclared;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get deviceNone;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'CPU wake lock'**
  String get deviceCpuLock;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Off: the setting below is off.'**
  String get deviceCpuOff;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Held: the screen is off.'**
  String get deviceCpuHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Released while the screen is on.'**
  String get deviceCpuReleased;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Not held.'**
  String get deviceNotHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get deviceHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get deviceReleased;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi lock'**
  String get deviceWifiLock;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Held: the radio stays out of power saving.'**
  String get deviceWifiHeld;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps the radio out of power saving through screen-off.'**
  String get deviceWifiHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get deviceNotification;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Hidden: notifications are turned off for the app. The service runs regardless.'**
  String get deviceNotificationHidden;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Shown in the notification shade while the service runs.'**
  String get deviceNotificationShown;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get deviceHidden;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Shown'**
  String get deviceShown;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant connection'**
  String get deviceReasonHa;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps the dashboard session and its websocket open while the screen is off.'**
  String get deviceReasonHaHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Background listening'**
  String get deviceReasonListening;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps the wake word engine and its microphone running behind other apps.'**
  String get deviceReasonListeningHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'RTSP microphone audio'**
  String get deviceReasonRtsp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps microphone streaming available to connected RTSP viewers.'**
  String get deviceReasonRtspHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'ESPHome server'**
  String get deviceReasonEspHome;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps the ESPHome API server answering Home Assistant.'**
  String get deviceReasonEspHomeHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Remote administration'**
  String get deviceReasonRemote;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps the admin web server answering.'**
  String get deviceReasonRemoteHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Kiosk protections'**
  String get deviceReasonProtections;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Relaunches the kiosk when it is closed from recents or crashes.'**
  String get deviceReasonProtectionsHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth proxy'**
  String get deviceReasonBluetooth;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps Bluetooth scanning running while the app is not on screen.'**
  String get deviceReasonBluetoothHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Location sensors'**
  String get deviceReasonLocation;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps GPS fixes arriving while the screen is off or another app is in front.'**
  String get deviceReasonLocationHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Person detection'**
  String get deviceReasonPerson;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps reading the device\'s person sensor while another app is in front.'**
  String get deviceReasonPersonHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Keeps the camera usable after the panel powers off, for motion and face detection.'**
  String get deviceReasonCameraHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Stopped: {error}'**
  String deviceServiceStopped(String error);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Running for {uptime}.'**
  String deviceServiceRunning(String uptime);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Install updates through Shizuku'**
  String get settingShizukuInstallUpdatesTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Install Kiosk Satellite updates without on-device confirmation. Shizuku must be running and authorized.'**
  String get settingShizukuInstallUpdatesDescription;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Shizuku access'**
  String get deviceShizukuAccess;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Checking availability'**
  String get deviceShizukuCheck;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Connected with root access'**
  String get deviceShizukuRoot;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Connected with shell access'**
  String get deviceShizukuShell;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Tap to grant access. Approve the request on this kiosk.'**
  String get deviceShizukuGrant;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Grant access and approve the request on this kiosk.'**
  String get deviceShizukuGrantRemote;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Allow Kiosk Satellite in the Shizuku app.'**
  String get deviceShizukuDenied;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Shizuku 13 or later is required.'**
  String get deviceShizukuUnsupported;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Start Shizuku on this device.'**
  String get deviceShizukuStart;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get deviceShizukuTest;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Read the process identity without changing the device.'**
  String get deviceShizukuTestHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Connection test'**
  String get deviceShizukuTestTitle;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Shizuku could not complete the connection test.'**
  String get deviceShizukuTestFailed;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'All permissions are already granted.'**
  String get deviceShizukuAlreadyGranted;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Android confirmed the requested permissions.'**
  String get deviceShizukuConfirmed;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Permission results'**
  String get deviceShizukuResults;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Grant all permissions'**
  String get deviceShizukuGrantAll;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Grant all permissions used by KS, including features that are currently off.'**
  String get deviceShizukuGrantAllHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Set up Shizuku'**
  String get deviceShizukuSetup;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Read installation and startup instructions.'**
  String get deviceShizukuSetupHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Shizuku started through ADB must be started again after a device reboot. Shell access does not provide root permissions.'**
  String get deviceShizukuLifetime;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Shizuku request failed'**
  String get deviceShizukuFailed;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Approve the request on the kiosk.'**
  String get deviceShizukuApprove;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Shizuku successfully ran a command with {access} access.'**
  String deviceShizukuTestOk(String access);

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Android has not confirmed this permission. Check Permissions Manager on the device.'**
  String get shizukuPermissionUnconfirmed;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Could not read current permissions. Try again.'**
  String get shizukuPermissionReadFailed;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'The restart command timed out'**
  String get shizukuRestartTimedOut;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Android refused the restart'**
  String get shizukuRestartRefused;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Command timed out'**
  String get shizukuCommandTimedOut;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Android rejected the request'**
  String get shizukuRequestRejected;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected'**
  String get deviceDisconnectedError;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Device response timed out'**
  String get deviceResponseTimedOut;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Request aborted'**
  String get deviceRequestAborted;

  /// Explanation when a Shizuku device action fails.
  ///
  /// In en, this message translates to:
  /// **'A Shizuku device action is already running'**
  String get shizukuActionBusy;

  /// Explanation when a Shizuku device action fails.
  ///
  /// In en, this message translates to:
  /// **'Grant Shizuku access first'**
  String get shizukuGrantFirst;

  /// Explanation when a Shizuku device action fails.
  ///
  /// In en, this message translates to:
  /// **'Shizuku command did not respond'**
  String get shizukuNoResponse;

  /// Explanation when a Shizuku device action fails.
  ///
  /// In en, this message translates to:
  /// **'Shizuku command failed'**
  String get shizukuCommandFailed;

  /// Explanation when a Shizuku device action fails.
  ///
  /// In en, this message translates to:
  /// **'Start Shizuku 13 or later and allow Kiosk Satellite in Shizuku'**
  String get shizukuStartRequired;

  /// Explanation when a Shizuku device action fails.
  ///
  /// In en, this message translates to:
  /// **'Shizuku connection failed'**
  String get shizukuConnectionFailed;

  /// Explanation when a Shizuku device action fails.
  ///
  /// In en, this message translates to:
  /// **'Shizuku helper did not connect'**
  String get shizukuHelperNotConnected;

  /// Explanation when a Shizuku device action fails.
  ///
  /// In en, this message translates to:
  /// **'Shizuku helper is unavailable'**
  String get shizukuHelperUnavailable;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'TLS'**
  String get tlsTLS;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Connection encryption and certificates'**
  String get tlsConnectionEncryptionAndCertificates;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Certificate type'**
  String get tlsCertificateType;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get tlsImported;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Self-signed'**
  String get tlsSelfSigned;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get tlsExpires;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'SHA-256 fingerprint'**
  String get tlsSHA256Fingerprint;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Certificate expired. Renew or import a replacement.'**
  String get tlsCertificateExpiredRenewOrImportAReplacement;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Copy public certificate'**
  String get tlsCopyPublicCertificate;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Download public certificate'**
  String get tlsDownloadPublicCertificate;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Use this certificate in browsers and streaming clients.'**
  String get tlsUseThisCertificateInBrowsersAndStreamingClients;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Renew certificate'**
  String get tlsRenewCertificate;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Keep the current private key and update the certificate dates.'**
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Import certificate'**
  String get tlsImportCertificate;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Use a certificate issued for this device.'**
  String get tlsUseACertificateIssuedForThisDevice;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Replace certificate'**
  String get tlsReplaceCertificate;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Generate a new private key and self-signed certificate.'**
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Generate a new private key and certificate? Active encrypted connections will close. Browsers may ask you to accept the new certificate.'**
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Paste the PEM certificate chain and its unencrypted private key. They are validated before replacing the current certificate.'**
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Certificate chain (PEM)'**
  String get tlsCertificateChainPEM;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Private key (PEM)'**
  String get tlsPrivateKeyPEM;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get tlsThisFieldIsRequired;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get tlsReplace;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get tlsRenew;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Enable HTTPS before importing a private key remotely.'**
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Certificate operation failed.'**
  String get tlsCertificateOperationFailed;

  /// Confirmation before changing the remote administration protocol.
  ///
  /// In en, this message translates to:
  /// **'Change connection protocol'**
  String get tlsChangeConnectionProtocol;

  /// Confirmation before changing the remote administration protocol.
  ///
  /// In en, this message translates to:
  /// **'The current remote connection will close. Reconnect using the address below. You may need to sign in again.'**
  String get tlsConnectionProtocolHelp;

  /// Confirmation before changing the remote administration protocol.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get tlsConfirm;

  /// TLS encryption setting, certificate action or help text.
  ///
  /// In en, this message translates to:
  /// **'Certificate Management'**
  String get tlsCertificateManagement;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Use a server certificate, not a CA certificate.'**
  String get tlsServerCertificateRequired;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Certificate does not allow server authentication.'**
  String get tlsServerAuthenticationRequired;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Use an EC or RSA private key.'**
  String get tlsKeyAlgorithmRequired;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Certificate and private key do not match.'**
  String get tlsKeyMismatch;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Certificate or key is too large.'**
  String get tlsMaterialTooLarge;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Expected PEM certificates.'**
  String get tlsPemCertificatesRequired;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'No certificate found.'**
  String get tlsCertificateMissing;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Use an unencrypted PEM private key.'**
  String get tlsUnencryptedKeyRequired;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'A hostname or IP address is required.'**
  String get tlsHostnameRequired;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Import a renewed certificate from its issuer.'**
  String get tlsIssuerRenewalRequired;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'Stored TLS identity is damaged.'**
  String get tlsStoredIdentityDamaged;

  /// Certificate validation or management error shown on the device and in remote administration.
  ///
  /// In en, this message translates to:
  /// **'The TLS certificate has expired. Renew or import its replacement.'**
  String get tlsExpiredCertificate;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Optional update helper'**
  String get deviceHelperPage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Helper status'**
  String get deviceHelperStatus;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Could not check the update helper.'**
  String get deviceHelperError;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Android can now install updates silently. The helper is not needed.'**
  String get deviceHelperUnneeded;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'This device currently needs confirmation on the screen to install updates through Android. The optional helper lets Kiosk Satellite install updates without a tap.'**
  String get deviceHelperIntro;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Installing an update.'**
  String get deviceHelperBusy;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Ready. Updates install without confirmation.'**
  String get deviceHelperReady;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Unavailable. Start the helper through ADB to enable updates without confirmation.'**
  String get deviceHelperUnavailable;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The helper survives app restarts and updates but stops after a device reboot. Run the command from a computer with ADB to start it again. The computer can then disconnect.'**
  String get deviceHelperLifetime;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Start through ADB'**
  String get deviceHelperStart;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Setup guide'**
  String get deviceHelperGuide;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Read the update helper instructions and requirements.'**
  String get deviceHelperGuideHelp;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Update source'**
  String get settingUpdateSourceTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Where the app looks for new releases.'**
  String get settingUpdateSourceDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Repository URL'**
  String get settingUpdateSourceUrlTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'A folder on a web server the kiosk can reach, holding releases.json and the release APKs.'**
  String get settingUpdateSourceUrlDescription;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get deviceUpdatesPage;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get deviceUpdateGithub;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Custom Repository'**
  String get deviceUpdateCustom;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Custom repository guide'**
  String get deviceUpdateGuide;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'How to host the releases file and the APKs on your own network.'**
  String get deviceUpdateGuideHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Install from file'**
  String get deviceInstallFile;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Upload a Kiosk Satellite APK from a computer through the remote admin, on this same page. For a kiosk that cannot reach GitHub or a custom repository.'**
  String get deviceInstallFileHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Upload a Kiosk Satellite APK from this computer and install it. For a kiosk that cannot reach GitHub or a custom repository.'**
  String get deviceInstallFileRemoteHelp;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Uploaded APK'**
  String get deviceUploadedApk;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get deviceInstalling;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The device did not answer.'**
  String get deviceDeviceNoAnswer;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Check the device logs.'**
  String get deviceInstallFailed;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Confirm on the tablet screen'**
  String get deviceConfirmTablet;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (build {build}, {size} MB) is on the device, waiting to be installed.'**
  String deviceUploadedVersion(String version, String build, String size);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Install version {version}'**
  String deviceInstallVersion(String version);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The device answered HTTP {code}.'**
  String deviceHttpError(String code);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The upload failed.'**
  String get deviceUploadFailed;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Install on the fleet'**
  String get deviceInstallFleet;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Sending to the fleet…'**
  String get deviceSendingFleet;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The kiosk already runs this build.'**
  String get deviceSameBuild;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The install must be confirmed on the tablet screen unless the kiosk installs silently.'**
  String get deviceInstallConfirmation;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'This kiosk installs last.'**
  String get deviceSelfLast;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Updating the fleet'**
  String get deviceUpdatingFleet;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String deviceUploading(String percent);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The uploaded APK is version {version} (build {build}, {size} MB).'**
  String deviceUploadedDetails(String version, String build, String size);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'The kiosk runs {version} (build {build}).'**
  String deviceCurrentBuild(String version, String build);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Sending to {name}… {percent}%'**
  String deviceSendingTo(String name, String percent);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Installing on {name}…'**
  String deviceInstallingOn(String name);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'{names} installing.'**
  String deviceInstallingNames(String names);

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Enter the folder URL, for example http://nas.local/kiosk-satellite'**
  String get deviceUpdateUrlInvalid;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Enter only the folder URL, without anything after the path. Example: http://nas.local/kiosk-satellite'**
  String get deviceUpdateUrlPath;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'A download is running. Wait for it to finish.'**
  String get updateDownloadBusy;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'An install is running. Wait for it to finish.'**
  String get updateInstallBusy;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'No update is available.'**
  String get updateNoAvailable;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'No uploaded APK is waiting.'**
  String get updateNoUploaded;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'The upload was empty.'**
  String get updateUploadEmpty;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'The file is not an Android APK.'**
  String get updateInvalidApk;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'The uploaded APK is gone. Upload it again.'**
  String get updateUploadedGone;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Shizuku could not install the update. No confirmation installer was opened.'**
  String get updateShizukuInstallerFailed;

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Not enough free space: the APK is {size} MB and the install needs about {required} MB, but the device has {free} MB free.'**
  String updateUploadSpace(String size, String required, String free);

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'The upload was interrupted after {size} MB: {error}'**
  String updateUploadInterrupted(String size, String error);

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'The upload ended early: {received} of {expected} MB arrived.'**
  String updateUploadEarly(String received, String expected);

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'The APK is {package}, not Kiosk Satellite ({expected}).'**
  String updateWrongPackage(String package, String expected);

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'The APK is version {version} (build {build}), older than the running {currentVersion} (build {currentBuild}). Downgrades are refused: Android would not install one either.'**
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  );

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Download failed (HTTP {status}).'**
  String updateDownloadHttpFailed(String status);

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'The download stalled: no data arrived for {seconds} seconds.'**
  String updateDownloadStalled(String seconds);

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String deviceUpdateFailedDetail(String error);

  /// Explanation when a device operation fails.
  ///
  /// In en, this message translates to:
  /// **'Install failed: {error}'**
  String deviceInstallFailedDetail(String error);

  /// Replacement for an unknown package name in an APK rejection message.
  ///
  /// In en, this message translates to:
  /// **'another package'**
  String get updateAnotherPackage;

  /// Language selector label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingUiLanguageTitle;

  /// Help below the language selector.
  ///
  /// In en, this message translates to:
  /// **'Language for Kiosk Satellite and remote administration. Home Assistant keeps its own language.'**
  String get settingUiLanguageDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get settingUiThemeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Light or dark for the app\'s own screens: menu, settings, dialogs. System follows the Android setting.'**
  String get settingUiThemeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Scale UI'**
  String get settingUiScaleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Size of the app\'s own screens: menu, settings, dialogs. For high density displays. Web content keeps its size.'**
  String get settingUiScaleDescription;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'User Interface'**
  String get deviceUserInterface;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get deviceThemeDark;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get deviceThemeLight;

  /// Label or explanation on this Device settings page.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get deviceThemeSystem;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable DLNA renderer'**
  String get settingDlnaEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Show images and play media pushed from Home Assistant or any DLNA app. The device appears as a media player named after the device name.'**
  String get settingDlnaEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Keep audio in the background'**
  String get settingDlnaAudioBackgroundTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Pushed audio plays without taking over the screen.'**
  String get settingDlnaAudioBackgroundDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Server port'**
  String get settingDlnaPortTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'The port the renderer is on, filled in when it starts. Change it to move the renderer, or clear it to let it pick again.'**
  String get settingDlnaPortDescription;

  /// Placeholder in the empty server port field.
  ///
  /// In en, this message translates to:
  /// **'Set when the renderer starts'**
  String get settingDlnaPortPlaceholder;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Use real Wi-Fi MAC address'**
  String get settingEsphomeRealMacTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant links this kiosk with the same device your network integrations already track. Changing this creates a new ESPHome device in Home Assistant.'**
  String get settingEsphomeRealMacDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Spoof Wi-Fi MAC address'**
  String get settingEsphomeMacOverrideTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Since the MAC address cannot be resolved, you can use this field to enter your own. Changing this creates a new ESPHome device in Home Assistant.'**
  String get settingEsphomeMacOverrideDescription;

  /// Advanced identity page link and heading.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get esphomeAdvanced;

  /// Description below the Advanced settings link.
  ///
  /// In en, this message translates to:
  /// **'Real or spoofed Wi-Fi MAC address'**
  String get esphomeAdvancedHelp;

  /// Validation error for a manually entered address.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid MAC address.'**
  String get esphomeMacInvalid;

  /// Status when the hardware address is used.
  ///
  /// In en, this message translates to:
  /// **'Reporting {mac}.'**
  String esphomeMacHardware(String mac);

  /// Status when a manually entered address is used.
  ///
  /// In en, this message translates to:
  /// **'Reporting {mac}, entered below.'**
  String esphomeMacManual(String mac);

  /// Status when Android cannot provide the hardware address.
  ///
  /// In en, this message translates to:
  /// **'Android will not reveal this device\'s hardware address.'**
  String get esphomeMacUnavailable;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable announcements'**
  String get settingAnnouncementsEnabledTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Play the announcements Home Assistant sends with the announce action.'**
  String get settingAnnouncementsEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Text to speech engine'**
  String get settingAnnouncementsTtsEngineTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The Home Assistant text to speech entity that speaks announcements.'**
  String get settingAnnouncementsTtsEngineDescription;

  /// Default choice when no engine is selected.
  ///
  /// In en, this message translates to:
  /// **'First available'**
  String get esphomeTtsFirst;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Chime first'**
  String get settingAnnouncementsChimeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Play a chime before the announcement.'**
  String get settingAnnouncementsChimeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Chime sound'**
  String get settingAnnouncementsChimeFileTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Plays at the notification volume.'**
  String get settingAnnouncementsChimeFileDescription;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get esphomeAnnouncements;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Spoken announcements from Home Assistant'**
  String get esphomeAnnouncementsHelp;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Chime'**
  String get esphomeChime;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Home Assistant'**
  String get esphomeTtsUnavailable;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable Bluetooth proxy'**
  String get settingBtproxyEnabledTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Relay nearby Bluetooth devices to Home Assistant.'**
  String get settingBtproxyEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Scan intensity'**
  String get settingBtproxyScanDutyTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How much of the time the radio listens. Lower cuts CPU; devices that advertise rarely take longer to appear.'**
  String get settingBtproxyScanDutyDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Allow device connections'**
  String get settingBtproxyConnectionsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant can connect to Bluetooth devices through this proxy.'**
  String get settingBtproxyConnectionsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Look up device manufacturers online'**
  String get settingBtproxyMacLookupTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Names unknown nearby devices by their hardware address prefix using api.macvendors.com. Only the 3-byte manufacturer prefix is sent, once per manufacturer; nothing else leaves the device.'**
  String get settingBtproxyMacLookupDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get settingBtproxyNearbySortTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The order of the nearby devices list below.'**
  String get settingBtproxyNearbySortDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Minimum signal for connections'**
  String get settingBtproxyMinConnectRssiTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Refuse device connections heard weaker than this, so a closer proxy takes them instead.'**
  String get settingBtproxyMinConnectRssiDescription;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get esphomeOptionContinuous;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get esphomeOptionBalanced;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Low power'**
  String get esphomeOptionLowPower;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get esphomeOptionLastSeen;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get esphomeOptionName;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'MAC address'**
  String get esphomeOptionMacAddress;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Signal strength'**
  String get esphomeOptionSignalStrength;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get esphomeOptionNoLimit;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'-70 dBm (same room)'**
  String get esphomeOption70DbmSameRoom;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'-80 dBm'**
  String get esphomeOption80Dbm;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'-85 dBm'**
  String get esphomeOption85Dbm;

  /// Choice label. The saved value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'-90 dBm (edge of range)'**
  String get esphomeOption90DbmEdgeOfRange;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Proxy'**
  String get esphomeBluetooth;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Relay nearby Bluetooth devices to Home Assistant'**
  String get esphomeBluetoothHelp;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on to use the proxy.'**
  String get esphomeBluetoothOff;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device: it has no Bluetooth.'**
  String get esphomeBluetoothUnsupported;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device: its Android build has no Bluetooth LE support.'**
  String get esphomeBluetoothBuildUnsupported;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'BTHome sensor'**
  String get esphomeIdentityBthome;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Xiaomi sensor'**
  String get esphomeIdentityXiaomi;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Qingping sensor'**
  String get esphomeIdentityQingping;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Google/Nest device'**
  String get esphomeIdentityGoogleNest;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Eddystone beacon'**
  String get esphomeIdentityEddystone;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Google Fast Pair device'**
  String get esphomeIdentityGoogleFastPair;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Apple Find My device'**
  String get esphomeIdentityAppleFindMy;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Exposure notification (phone)'**
  String get esphomeIdentityExposure;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'August/Yale lock'**
  String get esphomeIdentityAugustYale;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Amazon device'**
  String get esphomeIdentityAmazon;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Tile tracker'**
  String get esphomeIdentityTile;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Input device (remote/keyboard)'**
  String get esphomeIdentityInput;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Heart rate sensor'**
  String get esphomeIdentityHeartRate;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Environmental sensor'**
  String get esphomeIdentityEnvironmental;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Apple device'**
  String get esphomeIdentityApple;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Windows PC'**
  String get esphomeIdentityWindows;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Samsung device'**
  String get esphomeIdentitySamsung;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Google device'**
  String get esphomeIdentityGoogle;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get esphomeIdentityUnknown;

  /// Inferred device class. Never translate an actual broadcast name or manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'{vendor} device'**
  String esphomeIdentityVendor(String vendor);

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get esphomeNearby;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'The Bluetooth devices this kiosk hears, with names where known.'**
  String get esphomeNearbySearch;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Nothing heard yet.'**
  String get esphomeNearbyEmpty;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Nothing heard yet. Devices appear here once the proxy is scanning.'**
  String get esphomeNearbyWaiting;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'(rotating address)'**
  String get esphomeRotating;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {count} of {total}.'**
  String esphomeNearbyCount(String count, String total);

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} devices can be connected at once through this proxy. Home Assistant routes further devices through other proxies.'**
  String esphomeSlots(String count);

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'{count}s ago'**
  String esphomeSecondsAgo(String count);

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String esphomeMinutesAgo(String count);

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String esphomeHoursAgo(String count);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Report location'**
  String get settingLocationEnabledTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Read the GPS position and serve it to Home Assistant as latitude, longitude, accuracy, altitude and speed sensors. Turning this on or off re-registers the ESPHome device.'**
  String get settingLocationEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Update interval'**
  String get settingLocationIntervalTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Seconds between position readings.'**
  String get settingLocationIntervalDescription;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'GPS Sensor'**
  String get esphomeGps;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Expose GPS sensor data to Home Assistant'**
  String get esphomeGpsHelp;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Off.'**
  String get esphomeLocationOff;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the first fix. A cold start under open sky can take a few minutes.'**
  String get esphomeLocationWaiting;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Last coordinates'**
  String get esphomeCoordinates;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Location permission not granted.'**
  String get esphomeLocationDenied;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'No GPS receiver.'**
  String get esphomeLocationAbsent;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'GPS unavailable: {error}'**
  String esphomeLocationError(String error);

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device: it has no GPS receiver.'**
  String get esphomeLocationUnsupported;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Transparency'**
  String get settingNotificationsTransparencyTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Lets the screen behind show through the notification cards. Text and icons stay solid.'**
  String get settingNotificationsTransparencyDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Background blur'**
  String get settingNotificationsBlurTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Blurs what shows through a transparent notification card. Note: Blur cannot be applied over the Home Assistant dashboard surface.'**
  String get settingNotificationsBlurDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get settingNotificationsChimeFileTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Sound files are read from Android/data/me.jxl.kiosk_satellite/files/sounds on the device, also reachable from the File Manager.'**
  String get settingNotificationsChimeFileDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Notification volume'**
  String get settingNotificationsVolumeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How loud the notification sound plays, apart from the media and assistant volumes.'**
  String get settingNotificationsVolumeDescription;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get esphomeNotifications;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Transparency, blur, notification sound, test notification'**
  String get esphomeNotificationsHelp;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get esphomeAppearance;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get esphomeSound;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Test notification'**
  String get esphomeNotificationTest;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Notifications are sent from Home Assistant with the {action} action. Test shows one over the dashboard.'**
  String esphomeNotificationHelp(String action);

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'This is what a notification from Home Assistant looks and sounds like.'**
  String get esphomeNotificationBody;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'The Home Assistant action that sends notifications, and a button to show one.'**
  String get esphomeNotificationSearch;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get esphomeLocation;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'The Location grant the location sensors need.'**
  String get esphomeLocationSearch;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'The Nearby devices grant the Bluetooth proxy needs to scan.'**
  String get esphomeBluetoothSearch;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Without this the GPS receiver cannot be read and the location sensors stay unknown.'**
  String get esphomeLocationMissing;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Location is off in the device settings, so the receiver delivers nothing.'**
  String get esphomeLocationServicesOff;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'The location sensors can read the GPS receiver.'**
  String get esphomeLocationGranted;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'The proxy can scan for nearby Bluetooth devices.'**
  String get esphomeBluetoothGranted;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Without this the proxy cannot scan for devices.'**
  String get esphomeBluetoothMissing;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Android only delivers Bluetooth scan results, beacons included, with Location granted. The proxy never reads the device position.'**
  String get esphomeBluetoothLocationMissing;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Location is off in the device settings, so Bluetooth scanning finds nothing.'**
  String get esphomeBluetoothLocationOff;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth scanning can hear beacons.'**
  String get esphomeBluetoothBeacons;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get esphomeSent;

  /// Interface label or status message.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get esphomeNotsaved;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable ESPHome'**
  String get settingEsphomeEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Serve this kiosk to Home Assistant as an ESPHome device: its sensors and controls as native entities. Discovered automatically.'**
  String get settingEsphomeEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Expose kiosk entities'**
  String get settingEsphomeEntitiesTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Serve the sensors and controls of this device as ESPHome entities.'**
  String get settingEsphomeEntitiesDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Excluded entities'**
  String get settingEsphomeExcludedEntitiesTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Pick entities to exclude from Home Assistant. All other available entities are exposed. Saving reconnects ESPHome.'**
  String get settingEsphomeExcludedEntitiesDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Node name'**
  String get settingEsphomeNodeNameTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Names this kiosk on the network, and Home Assistant builds its action names from it. Renaming it renames those actions.'**
  String get settingEsphomeNodeNameDescription;

  /// Placeholder before the server has started.
  ///
  /// In en, this message translates to:
  /// **'Set on first start'**
  String get settingEsphomeNodeNamePlaceholder;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Encryption key'**
  String get settingBtproxyKeyTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Paste this key into Home Assistant when it asks for the encryption key. Generated automatically on first start.'**
  String get settingBtproxyKeyDescription;

  /// Placeholder before the server has started.
  ///
  /// In en, this message translates to:
  /// **'Generated on first start'**
  String get settingBtproxyKeyPlaceholder;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'API port'**
  String get settingBtproxyPortTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'The port Home Assistant connects to. Leave empty for the ESPHome standard, 6053.'**
  String get settingBtproxyPortDescription;

  /// Server startup failure with the original technical detail.
  ///
  /// In en, this message translates to:
  /// **'The ESPHome server failed to start: {error}'**
  String esphomeStartFailed(String error);

  /// Invalid entity exclusion setting.
  ///
  /// In en, this message translates to:
  /// **'Choose a list of entity IDs.'**
  String get esphomeExcludedInvalid;

  /// Footer credit. Keep both placeholders. They become a heart icon and the linked author name. Reorder them as your language needs.
  ///
  /// In en, this message translates to:
  /// **'Made with {heart} by {author}'**
  String settingsMadeBy(String heart, String author);

  /// Link beside the footer credit that opens the author's support page.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get settingsBuyCoffee;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Clap detection'**
  String get settingClapStrictnessTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Strict needs louder, evenly spaced claps; try it if household noise false-triggers.'**
  String get settingClapStrictnessDescription;

  /// Clap detection option.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get gestureStrictnessStandard;

  /// Clap detection option.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get gestureStrictnessStrict;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Gestures are off'**
  String get gestureOff;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Disable Gestures is on in Kiosk Mode settings.'**
  String get gestureOffHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No gestures configured'**
  String get gestureEmpty;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'A gesture triggers its action without any visible control.'**
  String get gestureEmptyHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Delete gesture'**
  String get gestureDeleteTooltip;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Delete gesture?'**
  String get gestureDeleteTitle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Remove this gesture? Trigger: {trigger}. Action: {action}.'**
  String gestureDeleteMessage(String trigger, String action);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add gesture'**
  String get gestureAdd;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Pick a gesture and the action it triggers.'**
  String get gestureAddHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Gestures are observed, not blocked: the taps also reach the dashboard, so corners and multi-finger shapes keep them from firing anything there.'**
  String get gestureTouchHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Clapper'**
  String get gestureClapper;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not read the settings.'**
  String get gestureReadFailed;

  /// Hand gesture hold setting or confirmation feedback.
  ///
  /// In en, this message translates to:
  /// **'Hand Gestures'**
  String get gestureHandGestures;

  /// Hand gesture hold setting or confirmation feedback.
  ///
  /// In en, this message translates to:
  /// **'Hold duration'**
  String get settingHandGestureHoldSecondsTitle;

  /// Hand gesture hold setting or confirmation feedback.
  ///
  /// In en, this message translates to:
  /// **'Hold the same finger gesture for this long before its action runs. Increase this to reduce accidental triggers.'**
  String get settingHandGestureHoldSecondsDescription;

  /// Hand gesture hold setting or confirmation feedback.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get gestureHoldInstant;

  /// Hand gesture hold setting or confirmation feedback.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String gestureHoldSeconds(String seconds);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Hold mode'**
  String get settingHaHoldModeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Keep the current view on screen: the screensaver, dashboard view rotation and the return to home timer are paused until turned off.'**
  String get settingHaHoldModeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'End hold automatically after'**
  String get settingHaHoldReleaseMinutesTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Turns hold mode off by itself after the set time. Set to 0 to hold until turned off manually.'**
  String get settingHaHoldReleaseMinutesDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show in the kiosk menu'**
  String get settingHaHoldMenuTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Adds a menu entry that turns hold mode on and off.'**
  String get settingHaHoldMenuDescription;

  /// Hold subpage summary or duration displayed beside the automatic release slider.
  ///
  /// In en, this message translates to:
  /// **'Pin the current view, automatic release, menu entry'**
  String get haHoldHint;

  /// Hold subpage summary or duration displayed beside the automatic release slider.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get haNever;

  /// Hold subpage summary or duration displayed beside the automatic release slider.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String haMinutes(String minutes);

  /// Hold subpage summary or duration displayed beside the automatic release slider.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String haHours(String hours);

  /// Hold subpage summary or duration displayed beside the automatic release slider.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String haHoursMinutes(String hours, String minutes);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Keep connected in the background'**
  String get settingDisableSuspendTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Turns off Home Assistant\'s \"Suspend background connections\" setting, which would otherwise drop the connection a few minutes after the screen goes off.'**
  String get settingDisableSuspendDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Pause dashboard during screensaver'**
  String get settingFreezeOnScreensaverTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Stops drawing the dashboard while the screensaver covers it, cutting CPU and GPU use; the connection stays live. Not for the Dim screensaver.'**
  String get settingFreezeOnScreensaverDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Filter dashboard updates'**
  String get settingWsFilterTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Only process updates for entities on the current view, cutting stutter on low-powered tablets. Views that cannot be resolved stay unfiltered.'**
  String get settingWsFilterDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Pause HA dashboard camera streams during screensaver'**
  String get settingPauseDashboardCamerasTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Pauses supported muted camera streams on the Home Assistant dashboard while the screensaver covers it. Streams reconnect when it closes. Does not affect the device camera or the Camera Streams feature.'**
  String get settingPauseDashboardCamerasDescription;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Optimizations'**
  String get haOptimizations;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Background connection, dashboard and camera pause, update filter'**
  String get haOptimizationsHint;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Scan details are not available for the current view.'**
  String get haScanUnavailable;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Dashboard scan details'**
  String get haScanDetails;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Watched entities ({count})'**
  String haWatchedTitle(String count);

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Watched entities'**
  String get haWatched;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'The entity list is not available right now.'**
  String get haEntityListUnavailable;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Watching {count} entities on this view.'**
  String haWatching(String count);

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'No updates in the last minute.'**
  String get haNoUpdates;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Filtered {percent}% of updates in the last minute ({dropped} of {total}).'**
  String haFiltered(String percent, String dropped, String total);

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Something on this page receives every entity update anyway, so filtering saves less here.'**
  String get haRawUpdates;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'This view reads all entity states, so its updates are not filtered.'**
  String get haAllStates;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'This view\'s entities can\'t be determined, so its updates are not filtered.'**
  String get haUnknownEntities;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the dashboard to load…'**
  String get haWaiting;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'Show scan details.'**
  String get haShowScan;

  /// Live update-filter status, diagnostic dialog label or explanation. Technical scan output and entity names stay as supplied.
  ///
  /// In en, this message translates to:
  /// **'This view uses {count} entities, which crosses the filtering threshold. Filtering is disabled.'**
  String haThreshold(String count);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Return to home dashboard view'**
  String get settingHaReturnHomeEnabledTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Go back to the dashboard configured above after a period of inactivity.'**
  String get settingHaReturnHomeEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Return after (seconds)'**
  String get settingHaReturnHomeSecondsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Inactivity period before the kiosk goes back.'**
  String get settingHaReturnHomeSecondsDescription;

  /// Return-to-home subpage summary, disabled reason or destination.
  ///
  /// In en, this message translates to:
  /// **'Go back to the home view when left idle'**
  String get haReturnHint;

  /// Return-to-home subpage summary, disabled reason or destination.
  ///
  /// In en, this message translates to:
  /// **'Turned off while Dashboard view rotation is on.'**
  String get haReturnDisabled;

  /// Return-to-home subpage summary, disabled reason or destination.
  ///
  /// In en, this message translates to:
  /// **'The configured dashboard has no view path to return to.'**
  String get haReturnNoPath;

  /// Return-to-home subpage summary, disabled reason or destination.
  ///
  /// In en, this message translates to:
  /// **'Returns to \"{path}\" after the timeout.'**
  String haReturnPath(String path);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable dashboard view rotation'**
  String get settingHaRotationEnabledTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Cycle through the selected dashboard views in an endless loop, showing each one for the chosen number of seconds.'**
  String get settingHaRotationEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Seconds per view'**
  String get settingHaRotationSecondsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How long each view stays on screen.'**
  String get settingHaRotationSecondsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Pause rotation on interaction (seconds)'**
  String get settingHaRotationPauseSecondsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Touching the screen pauses rotation for this long, and each touch restarts the countdown. Voice interactions pause until they end. 0 keeps rotating through touches.'**
  String get settingHaRotationPauseSecondsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Fade between views'**
  String get settingHaRotationCrossfadeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Fade out to the background and into the next view instead of switching instantly. Moving to a different dashboard or an external page still switches instantly.'**
  String get settingHaRotationCrossfadeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Fade duration (seconds)'**
  String get settingHaRotationFadeSecondsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Combined fade-out and fade-in time. Loading the next view can add time, especially on its first visit.'**
  String get settingHaRotationFadeSecondsDescription;

  /// Rotation subpage label, guidance or validation error.
  ///
  /// In en, this message translates to:
  /// **'Dashboard View Rotation'**
  String get haRotation;

  /// Rotation subpage label, guidance or validation error.
  ///
  /// In en, this message translates to:
  /// **'Cycle through views, dwell time, fade'**
  String get haRotationHint;

  /// Rotation subpage label, guidance or validation error.
  ///
  /// In en, this message translates to:
  /// **'Default view'**
  String get haDefaultView;

  /// Rotation subpage label, guidance or validation error.
  ///
  /// In en, this message translates to:
  /// **'External pages'**
  String get haExternalPages;

  /// Rotation subpage label, guidance or validation error.
  ///
  /// In en, this message translates to:
  /// **'Choose a fade duration from 0.2 to 5 seconds.'**
  String get haFadeError;

  /// Rotation subpage label, guidance or validation error.
  ///
  /// In en, this message translates to:
  /// **'Touch pauses rotation for this long; each touch restarts it. Voice interactions always pause until they end. 0 keeps rotating.'**
  String get haPauseRemoteHelp;

  /// Home Assistant base URL field label.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant base URL'**
  String get settingHaUrlTitle;

  /// Help below the Home Assistant base URL field.
  ///
  /// In en, this message translates to:
  /// **'e.g. https://homeassistant.local:8123, without a dashboard path.'**
  String get settingHaUrlDescription;

  /// Long-lived access token field label.
  ///
  /// In en, this message translates to:
  /// **'Long-lived access token'**
  String get settingHaTokenTitle;

  /// Help below the Long-lived access token field.
  ///
  /// In en, this message translates to:
  /// **'Created under your HA profile → Security.'**
  String get settingHaTokenDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Log in automatically'**
  String get settingHaAutoLoginTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Sign in to the dashboard with the access token above instead of showing the Home Assistant login page.'**
  String get settingHaAutoLoginDescription;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get haValidate;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Validate connection'**
  String get haValidateConnection;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get haChecking;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get haConnected;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Connected.'**
  String get haConnectedRemote;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Not validated yet. The settings below unlock once the connection checks out.'**
  String get haNotValidated;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Could not connect.'**
  String get haConnectFailed;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant URL and token not configured'**
  String get haNotConfigured;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'invalid token'**
  String get haInvalidToken;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Home Assistant: {error}'**
  String haUnreachable(String error);

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Secure context proxy'**
  String get haProxy;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Routes a plain http Home Assistant through an in-app proxy so the browser unlocks the microphone and other https-only features. Only for http URLs.'**
  String get haProxyHelp;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Routes a plain http Home Assistant through a proxy inside the app so the browser unlocks the microphone and other https-only features. Available only for http URLs.'**
  String get haProxyRemoteHelp;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'This Home Assistant URL uses plain http, and browsers block the microphone and other features on http pages. Kiosk Satellite will route the dashboard through a secure proxy inside the app so everything works. You may need to sign in to Home Assistant again.'**
  String get haProxyNotice;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'This Home Assistant URL uses plain http, and browsers block the microphone and other features on http pages. Kiosk Satellite will route the dashboard through a secure proxy inside the app so everything works. You may need to sign in to Home Assistant again on the tablet.'**
  String get haProxyRemoteNotice;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get haDashboard;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Choose a view'**
  String get haChooseView;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboards…'**
  String get haLoadingDashboards;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Could not list dashboards'**
  String get haListFailed;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry.'**
  String get haRetryHint;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'Change view'**
  String get haChangeView;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'No sub views'**
  String get haNoViews;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'This dashboard has no selectable sub views.'**
  String get haNoViewsHelp;

  /// Connection status, action or dashboard picker text.
  ///
  /// In en, this message translates to:
  /// **'No dashboards found'**
  String get haNoDashboards;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingHaThemeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Light or dark for the Home Assistant dashboard, also set from the Theme entity in Home Assistant. Auto follows the settings below.'**
  String get settingHaThemeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Sync Home Assistant themes with Kiosk Satellite'**
  String get settingThemeMatchAppTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Automatically match your Home Assistant theme to your Kiosk Satellite interface.'**
  String get settingThemeMatchAppDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Match theme to time of day'**
  String get settingThemeAutoTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Switch Home Assistant between light and dark on a schedule. Keeps whatever theme is selected, flipping only its light/dark variant.'**
  String get settingThemeAutoDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Dark theme at'**
  String get settingThemeDarkAtTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Local time to switch to the dark theme.'**
  String get settingThemeDarkAtDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Light theme at'**
  String get settingThemeLightAtTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Local time to switch back to the light theme.'**
  String get settingThemeLightAtDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Also switch the app theme'**
  String get settingThemeAutoAppTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Flip Kiosk Satellite\'s own theme (menu, settings) together with the scheduled Home Assistant change.'**
  String get settingThemeAutoAppDescription;

  /// Theme subpage summary or automatic theme choice.
  ///
  /// In en, this message translates to:
  /// **'Match the app, or switch dark and light on a schedule'**
  String get haThemeHint;

  /// Theme subpage summary or automatic theme choice.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get haThemeAuto;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'HA kiosk mode'**
  String get settingHaKioskModeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Hide the Home Assistant header and sidebar. Applies immediately.'**
  String get settingHaKioskModeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Hide the header'**
  String get settingHaKioskHideHeaderTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Hide the dashboard toolbar and view tabs while HA kiosk mode is on. Leave off if you switch views from the header.'**
  String get settingHaKioskHideHeaderDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Hide the sidebar'**
  String get settingHaKioskHideSidebarTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Hide the navigation sidebar while HA kiosk mode is on.'**
  String get settingHaKioskHideSidebarDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show in the kiosk menu'**
  String get settingHaKioskMenuTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Add an HA Kiosk Mode entry to the kiosk menu that turns it on and off.'**
  String get settingHaKioskMenuDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable dashboard carousel'**
  String get settingHaDashboardCarouselTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Swipe left or right on the dashboard to move between its views. Swipes on sliders, maps and scrolling cards are left alone.'**
  String get settingHaDashboardCarouselDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Capture swipe gestures over cards'**
  String get settingHaCarouselOverCardsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Switch views even when the swipe starts on a card that reacts to swipes. Sliders still work normally.'**
  String get settingHaCarouselOverCardsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable haptics'**
  String get settingHaHapticsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when buttons, switches, cards, sliders and thermostat dials are used. Requires a vibration motor.'**
  String get settingHaHapticsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Vibration strength'**
  String get settingHaHapticsStrengthTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How strong the vibration feels.'**
  String get settingHaHapticsStrengthDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Play tap sounds'**
  String get settingHaTapSoundTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Play the standard tap sound when buttons, switches, cards, sliders and thermostat dials are used.'**
  String get settingHaTapSoundDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Tap sound volume'**
  String get settingHaTapSoundVolumeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How loud the tap sound plays.'**
  String get settingHaTapSoundVolumeDescription;

  /// Subpage heading, summary or vibration choice. Light means gentle vibration, not a color theme.
  ///
  /// In en, this message translates to:
  /// **'User Interface'**
  String get haUserInterface;

  /// Subpage heading, summary or vibration choice. Light means gentle vibration, not a color theme.
  ///
  /// In en, this message translates to:
  /// **'Kiosk mode, dashboard carousel, haptics, tap sounds'**
  String get haInterfaceHint;

  /// Subpage heading, summary or vibration choice. Light means gentle vibration, not a color theme.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haHaptics;

  /// Subpage heading, summary or vibration choice. Light means gentle vibration, not a color theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get haVibrationLight;

  /// Subpage heading, summary or vibration choice. Light means gentle vibration, not a color theme.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get haVibrationMedium;

  /// Subpage heading, summary or vibration choice. Light means gentle vibration, not a color theme.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get haVibrationStrong;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Act as the home screen'**
  String get settingHomeLauncherEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Register Kiosk Satellite as the device home screen: the kiosk starts at boot and every home press returns to it. Turns itself off and restores the previous launcher if the app fails to start repeatedly.'**
  String get settingHomeLauncherEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Keep screen pinning'**
  String get settingHomeKeepPinningTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Pin the screen even while Kiosk Satellite is the home screen. Blocks recents and back natively, but brings back the pinning confirmation dialog on devices without device ownership.'**
  String get settingHomeKeepPinningDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home screen'**
  String get kioskHomeScreen;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Checking the device...'**
  String get kioskCheckingDevice;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Fire OS does not allow replacing its launcher.'**
  String get kioskFireOs;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'This device does not allow changing the home screen.'**
  String get kioskUnsupported;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Turned off automatically after repeated failed starts; the previous launcher was restored. Turn the switch back on to try again.'**
  String get kioskRecovered;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite is the home screen. The kiosk starts at boot and every home press returns to it.'**
  String get kioskHeld;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not the home screen. Turn on Act as the home screen above.'**
  String get kioskDisabled;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not the current home screen yet: the device is waiting for a confirmation.'**
  String get kioskWaiting;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open home settings'**
  String get kioskOpenHomeSettings;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get kioskSetDefault;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get kioskActive;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not the home screen.'**
  String get kioskNotHome;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a confirmation on the device: the system dialog or home settings open there.'**
  String get kioskWaitingRemote;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Set on device'**
  String get kioskSetDevice;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Answer mode'**
  String get settingIntercomAnswerModeTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Ring asks on the screen. Answer automatically opens the call after a chime.'**
  String get settingIntercomAnswerModeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Ring for'**
  String get settingIntercomRingSecondsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'How long a call rings before it counts as missed.'**
  String get settingIntercomRingSecondsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Ring sound'**
  String get settingIntercomRingSoundTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Plays at the notification volume.'**
  String get settingIntercomRingSoundDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Accept announcements'**
  String get settingIntercomAcceptAnnouncementsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Play Announce to all from the other kiosks.'**
  String get settingIntercomAcceptAnnouncementsDescription;

  /// Visible option. Its stored value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get intercomOptionAnswerRing;

  /// Visible option. Its stored value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Answer automatically'**
  String get intercomOptionAnswerAuto;

  /// Visible option. Its stored value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Do not disturb'**
  String get intercomOptionAnswerDnd;

  /// Visible option. Its stored value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'15 seconds'**
  String get intercomOptionAnswer15;

  /// Visible option. Its stored value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get intercomOptionAnswer30;

  /// Visible option. Its stored value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'45 seconds'**
  String get intercomOptionAnswer45;

  /// Visible option. Its stored value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'60 seconds'**
  String get intercomOptionAnswer60;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get intercomAnswerSection;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable intercom'**
  String get settingIntercomEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Call the other kiosks on this network and take their calls.'**
  String get settingIntercomEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Intercom key'**
  String get settingIntercomKeyTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Kiosks with the same key can call each other. Fleet Management can sync it.'**
  String get settingIntercomKeyDescription;

  /// Placeholder for the key before the intercom is enabled.
  ///
  /// In en, this message translates to:
  /// **'Made when the intercom is enabled'**
  String get settingIntercomKeyPlaceholder;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show in the kiosk menu'**
  String get settingIntercomMenuTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Add an Intercom entry to the kiosk menu.'**
  String get settingIntercomMenuDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The intercom needs the remote admin'**
  String get intercomNeedsAdmin;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosks find and reach each other through it. Turn on Remote management and Find other kiosks under Device, then come back.'**
  String get intercomAdminHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Change key'**
  String get intercomChangeKey;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Paste the key from another kiosk, or make a new one.'**
  String get intercomChangeKeyHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get intercomChange;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosks with this key can call each other. A new key cuts this kiosk off from the others until they get it too.'**
  String get intercomKeyWarning;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get intercomRegenerate;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Key changed'**
  String get intercomKeyChanged;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get intercomNotSet;

  /// Action or validation message.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get intercomOpen;

  /// Intercom encryption setting.
  ///
  /// In en, this message translates to:
  /// **'Encrypt communications'**
  String get settingIntercomTlsTitle;

  /// Intercom encryption setting.
  ///
  /// In en, this message translates to:
  /// **'Use TLS to encrypt intercom calls between kiosks. All kiosks in the call need this enabled.'**
  String get settingIntercomTlsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosks'**
  String get intercomKiosks;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Discovered kiosks and saved fleet members. A kiosk is ready when it is reachable with intercom on, the same key and matching encryption settings.'**
  String get intercomRosterHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No other kiosks found'**
  String get intercomNoOther;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosks with Remote management and Find other kiosks on show up here.'**
  String get intercomRosterDeviceHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No kiosks found'**
  String get intercomNoneHeard;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosks appear through network discovery or saved fleet membership. Remote management and Find other kiosks must be on.'**
  String get intercomRosterRemoteHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get intercomReady;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Intercom off'**
  String get intercomOff;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Different key'**
  String get intercomDifferentKey;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Unreachable'**
  String get intercomUnreachable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get intercomOffline;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get intercomChecking;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Talk mode'**
  String get settingIntercomTalkModeTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Push to talk sends while the button is held. Hands free keeps the microphone open for the whole call.'**
  String get settingIntercomTalkModeDescription;

  /// Visible option. Its stored value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Push to talk'**
  String get intercomOptionTalkPtt;

  /// Visible option. Its stored value stays unchanged.
  ///
  /// In en, this message translates to:
  /// **'Hands free'**
  String get intercomOptionTalkHandsfree;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get intercomTalkSection;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Allow menu with quick actions'**
  String get settingKioskAllowDrawerTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'An edge swipe opens the menu without the exit gesture or PIN, limited to the actions selected below.'**
  String get settingKioskAllowDrawerDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get settingKioskAllowDashboardTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Reload the start page.'**
  String get settingKioskAllowDashboardDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'HA Kiosk Mode'**
  String get settingKioskAllowHaKioskTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the Home Assistant header and sidebar.'**
  String get settingKioskAllowHaKioskDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Camera View'**
  String get settingKioskAllowCameraTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Open the default camera view.'**
  String get settingKioskAllowCameraDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Intercom'**
  String get settingKioskAllowIntercomTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Call other kiosks from the kiosk menu.'**
  String get settingKioskAllowIntercomDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant'**
  String get settingKioskAllowMusicTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Open the Music Assistant web interface.'**
  String get settingKioskAllowMusicDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Floating Player'**
  String get settingKioskAllowSendspinPlayerTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the floating player and open Now Playing.'**
  String get settingKioskAllowSendspinPlayerDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Start Screensaver'**
  String get settingKioskAllowScreensaverTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Start the screensaver now.'**
  String get settingKioskAllowScreensaverDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Hold Mode'**
  String get settingKioskAllowHoldTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Turn hold mode on or off.'**
  String get settingKioskAllowHoldDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Lockdown Mode'**
  String get settingKioskAllowLockdownTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Lock the screen until the exit gesture or a remote unlock.'**
  String get settingKioskAllowLockdownDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Theme picker'**
  String get settingKioskAllowThemeTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Switch between the light and dark themes.'**
  String get settingKioskAllowThemeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get settingKioskAllowAppsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Open the app launcher. With Disable home button on, launching an app unpins the kiosk until it returns.'**
  String get settingKioskAllowAppsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Allowed Actions'**
  String get kioskAllowedActions;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Which quick actions the kiosk menu offers'**
  String get kioskAllowedHelp;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable kiosk mode'**
  String get settingKioskEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Lock the tablet into Kiosk Satellite. The menu swipe is replaced by the exit gesture, the back button stays inside the kiosk, and the protections below arm.'**
  String get settingKioskEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Start on boot'**
  String get settingKioskStartOnBootTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Launch Kiosk Satellite when the device powers on. On Android 10+ this needs the display over other apps permission; Android asks on first enable.'**
  String get settingKioskStartOnBootDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Kiosk exit gesture'**
  String get settingKioskExitGestureTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Fast taps anywhere open the menu, after the PIN if one is set. Hold variants need the last tap held down. When disabled, only the remote admin can reach settings.'**
  String get settingKioskExitGestureDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Kiosk mode PIN'**
  String get settingKioskPinTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Asked after the exit gesture before the menu opens. Leave empty for no PIN.'**
  String get settingKioskPinDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable status bar'**
  String get settingKioskDisableStatusBarTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Block the status bar pull-down with a shield over the top edge. Needs the display over other apps permission; Android asks on first enable.'**
  String get settingKioskDisableStatusBarDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable volume buttons'**
  String get settingKioskDisableVolumeTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Swallow the hardware volume keys.'**
  String get settingKioskDisableVolumeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable power button'**
  String get settingKioskDisablePowerTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Android cannot block the power button, so the screen turns right back on when it is pressed. Turning the screen off remotely still works.'**
  String get settingKioskDisablePowerDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable home button'**
  String get settingKioskDisableHomeTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Pin the app with Android screen pinning, which blocks the home and recents buttons. Android asks to confirm the first time.'**
  String get settingKioskDisableHomeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable context menus'**
  String get settingKioskDisableContextMenusTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Suppress long-press menus and text selection inside the web view.'**
  String get settingKioskDisableContextMenusDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable pull to refresh'**
  String get settingKioskDisablePullRefreshTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Ignore the pull-to-refresh gesture while kiosk mode is on.'**
  String get settingKioskDisablePullRefreshDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable Gestures'**
  String get settingKioskDisableGesturesTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Ignore the gestures from the Gestures page while kiosk mode is on.'**
  String get settingKioskDisableGesturesDescription;

  /// Exit gesture option. Keep the number of taps unchanged.
  ///
  /// In en, this message translates to:
  /// **'5 fast taps'**
  String get kioskGestureTaps5;

  /// Exit gesture option. Keep the number of taps unchanged.
  ///
  /// In en, this message translates to:
  /// **'7 fast taps'**
  String get kioskGestureTaps7;

  /// Exit gesture option. Keep the number of taps unchanged.
  ///
  /// In en, this message translates to:
  /// **'5 fast taps, holding the last'**
  String get kioskGestureTaps5Hold;

  /// Exit gesture option. Keep the number of taps unchanged.
  ///
  /// In en, this message translates to:
  /// **'7 fast taps, holding the last'**
  String get kioskGestureTaps7Hold;

  /// Exit gesture option. Keep the number of taps unchanged.
  ///
  /// In en, this message translates to:
  /// **'Disabled (remote admin only)'**
  String get kioskGestureNone;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite can bring itself back in the foreground.'**
  String get kioskForeground;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Without this the kiosk cannot bring itself back and the lockdown shield only covers the app.'**
  String get kioskOverlayMissing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The notification shade and recents close on their own while the screen is protected.'**
  String get kioskGuardHeld;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Without this the notification shade and recents stay reachable. Enable Kiosk Satellite under Accessibility.'**
  String get kioskGuardMissing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Without this the kiosk cannot bring itself back. The grant screen appears on the tablet.'**
  String get kioskOverlayRemote;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Without this the notification shade and recents stay reachable. Enable Kiosk Satellite under Accessibility on the tablet.'**
  String get kioskGuardRemote;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Grant on device'**
  String get kioskGrantDevice;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Open settings on device'**
  String get kioskOpenSettingsDevice;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable Lockdown Mode'**
  String get settingLockdownEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Disables screen interactions until turned off either from Home Assistant or with the exit gesture.'**
  String get settingLockdownEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show in the kiosk menu'**
  String get settingLockdownMenuTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Add a Lockdown Mode entry to the kiosk menu that locks the screen. Use the exit gesture, Remote Admin or Home Assistant to unlock it.'**
  String get settingLockdownMenuDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Blackout screen'**
  String get settingLockdownBlackoutTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Turns the screen black while locked.'**
  String get settingLockdownBlackoutDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Allow screensaver'**
  String get settingLockdownAllowScreensaverTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Lets the screensaver run while locked. Dismiss on motion stays deactivated until the lock lifts.'**
  String get settingLockdownAllowScreensaverDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Lockdown exit gesture'**
  String get settingLockdownExitGestureTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Fast taps anywhere turn Lockdown Mode off, after the kiosk PIN if one is set. Hold variants need the last tap held down. When disabled, only the remote admin or Home Assistant can turn it off.'**
  String get settingLockdownExitGestureDescription;

  /// Exit gesture option. Remote administration and Home Assistant can still unlock the device.
  ///
  /// In en, this message translates to:
  /// **'Disabled (remote only)'**
  String get lockdownGestureNone;

  /// Explanation below the permission group.
  ///
  /// In en, this message translates to:
  /// **'Lockdown Mode makes the dashboard non-interactive, arms every Kiosk Mode protection without changing your Kiosk Mode settings, and mutes wake word detection while it is on. With the System UI guard enabled (above), the notification shade and recents are blocked too. Home Assistant gets a Lockdown mode switch over ESPHome.'**
  String get lockdownExplanation;

  /// Device search guidance for the remote-only configuration page.
  ///
  /// In en, this message translates to:
  /// **'Remote-only touch shield. Set it up from the Remote Admin UI; its grants live under Required system permissions.'**
  String get lockdownSearch;

  /// Granted overlay permission status.
  ///
  /// In en, this message translates to:
  /// **'The lockdown shield can cover the whole screen.'**
  String get lockdownOverlayHeld;

  /// Missing overlay permission guidance.
  ///
  /// In en, this message translates to:
  /// **'Without this the shield only covers the app. The grant screen appears on the tablet.'**
  String get lockdownOverlayMissing;

  /// Search description for the permissions group.
  ///
  /// In en, this message translates to:
  /// **'The grants the lockdown protections lean on.'**
  String get lockdownPermissionsSearch;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Album art cache'**
  String get mediaCacheTitle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not read cache size.'**
  String get mediaCacheReadFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not clear the cache.'**
  String get mediaCacheClearFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Checking cache size...'**
  String get mediaCacheChecking;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Clearing...'**
  String get mediaCacheClearing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{used} used of {limit}. Queue thumbnails are cached automatically.'**
  String mediaCacheUsage(String used, String limit);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show the floating player'**
  String get settingSendspinShowPlayerTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'While music plays, show a small now-playing window over the dashboard with artwork, track info and progress. Drag it anywhere; the position is remembered.'**
  String get settingSendspinShowPlayerDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Player size'**
  String get settingSendspinPlayerSizeTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Compact is a small, unobtrusive now-playing window. Large adds previous, play/pause and next buttons sized for touch, controlling the whole playback group.'**
  String get settingSendspinPlayerSizeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Hide the paused player after'**
  String get settingSendspinPausedHideMinutesTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'How long a paused player stays on screen. It applies to both the floating player and the Now Playing view.'**
  String get settingSendspinPausedHideMinutesDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Keep playing when dismissed'**
  String get settingSendspinDismissKeepsPlayingTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Flinging the floating player away hides it without stopping the music.'**
  String get settingSendspinDismissKeepsPlayingDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show in the kiosk menu'**
  String get settingSendspinPlayerShortcutTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Add an entry in the kiosk menu that shows or hides the floating player. WARNING: If nothing is playing or there is no queue for this player, it won\'t show up.'**
  String get settingSendspinPlayerShortcutDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Floating Player'**
  String get mediaFloatingPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The small card over the dashboard'**
  String get mediaFloatingHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get mediaCompact;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Large with controls'**
  String get mediaLargeControls;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Player source'**
  String get settingSendspinPlayerSourceTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'What the floating player and Now Playing show and control: this device or a player elsewhere.'**
  String get settingSendspinPlayerSourceDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get settingSendspinPlayerTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'The player of that source to show and control.'**
  String get settingSendspinPlayerDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Duck volume during voice interactions'**
  String get settingSendspinDuckPercentTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Music drops to this share of its volume during voice interactions and intercom calls, then comes back.'**
  String get settingSendspinDuckPercentDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Volume buttons control the player'**
  String get settingSendspinVolumeKeysTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'This device\'s volume buttons change the followed player\'s volume instead of its own. Only while the Now Playing view is on screen, or whenever the player is playing.'**
  String get settingSendspinVolumeKeysDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Volume button step'**
  String get settingSendspinVolumeKeyStepTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'How far one press of a volume button moves the player.'**
  String get settingSendspinVolumeKeyStepDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The floating player and Now Playing show only while the picked player has a track playing or a queue loaded. With nothing playing or queued, neither appears.'**
  String get mediaIntro;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get mediaThisDevice;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get mediaOff;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'While Now Playing is shown'**
  String get mediaKeysNowPlaying;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'While the player is playing'**
  String get mediaKeysPlaying;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'another player'**
  String get mediaAnotherPlayer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'This device\'s own Sendspin player stays offline while {player} is controlled.'**
  String mediaLocalOffline(String player);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable lyrics'**
  String get settingSendspinLyricsEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Synchronized lyrics on the Now Playing view, for every player source.'**
  String get settingSendspinLyricsEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Lyrics source'**
  String get settingSendspinLyricsSourceTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Where the lyrics come from. Music Assistant needs the server address and token on its page.'**
  String get settingSendspinLyricsSourceDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Fallback to Music Assistant'**
  String get settingSendspinLyricsFallbackTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'If LRCLIB is unreachable, Music Assistant is asked instead. Needs the Music Assistant connection.'**
  String get settingSendspinLyricsFallbackDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Lyrics timing'**
  String get settingSendspinLyricsOffsetTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Shift the lyrics against the music. Positive shows each line earlier, negative later. Worth a nudge on tracks that read consistently off.'**
  String get settingSendspinLyricsOffsetDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get mediaLyricsPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Synchronized lyrics, their source and timing'**
  String get mediaLyricsHint;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get settingSendspinMaUrlTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'The Music Assistant server\'s address, as its web interface shows it. Usually https and port 8095.'**
  String get settingSendspinMaUrlDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Auth token'**
  String get settingSendspinMaTokenTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'A long-lived token from Music Assistant (Settings, then Users). Read access is enough for lyrics; the kiosk menu shortcut opens the web interface as whoever the token belongs to.'**
  String get settingSendspinMaTokenDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show in the kiosk menu'**
  String get settingSendspinMaShortcutTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Add a Music Assistant entry to the kiosk menu, opening the server\'s web interface over the dashboard. Needs the server address above.'**
  String get settingSendspinMaShortcutDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Open directly to Now Playing'**
  String get settingSendspinMaOpenFullscreenTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Open Music Assistant\'s full-screen player from the kiosk menu or the Open Music Assistant gesture.'**
  String get settingSendspinMaOpenFullscreenDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Close after inactivity'**
  String get settingSendspinMaAutoCloseTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Return to the dashboard when nobody has touched the Music Assistant page for this long. Zero leaves it open until it is closed.'**
  String get settingSendspinMaAutoCloseDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Hide the close button'**
  String get settingSendspinMaHideCloseTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'The floating close button can sit on top of Music Assistant\'s own controls, like the Now Playing menu. Without it, dismiss with the back button or by using the kiosk\'s drawer menu.'**
  String get settingSendspinMaHideCloseDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Server, token, kiosk menu shortcut'**
  String get mediaMaHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Kiosk menu'**
  String get mediaKioskMenu;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Validate connection'**
  String get mediaValidateConnection;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get mediaValidate;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get mediaChecking;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get mediaConnected;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Connected to Music Assistant {version}'**
  String mediaConnectedVersion(String version);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Check the address and token before turning on the shortcut or lyrics.'**
  String get mediaValidateHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The device did not answer.'**
  String get mediaDeviceNoAnswer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Validation failed.'**
  String get mediaValidationFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No server address set.'**
  String get mediaNoAddress;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No auth token set.'**
  String get mediaNoToken;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant did not answer in time.'**
  String get mediaTimeout;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not reach {host}: {error}'**
  String mediaUnreachable(String host, String error);

  /// Connection failure.
  ///
  /// In en, this message translates to:
  /// **'the server closed the connection'**
  String get mediaServerClosed;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show media controls'**
  String get settingSendspinFullscreenControlsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Previous, play/pause and next buttons and a progress bar on the Now Playing view. With controls on, a close button dismisses it instead of a tap anywhere.'**
  String get settingSendspinFullscreenControlsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Text scale'**
  String get settingSendspinFullscreenTextScaleTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Size of the track title, artist, album, lyrics and queue text. Applies in both layouts and alongside the screensaver. Artwork adjusts to leave room for the text.'**
  String get settingSendspinFullscreenTextScaleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Button scale'**
  String get settingSendspinFullscreenButtonScaleTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Size of the playback buttons and progress bar, independent of text size. Applies in both layouts and alongside the screensaver. Controls fit the space available in the player.'**
  String get settingSendspinFullscreenButtonScaleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Horizontal mode'**
  String get settingSendspinFullscreenHorizontalTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Split artwork and controls into equal left and right halves. With lyrics or the queue open, track details move below the artwork. Ignored while Now Playing is shown alongside a screensaver.'**
  String get settingSendspinFullscreenHorizontalDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Double tap to dismiss'**
  String get settingSendspinFullscreenDoubleTapTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'A double tap anywhere on the Now Playing view dismisses it. The close button won\'t be shown. Ignored while Now Playing is shown alongside a screensaver.'**
  String get settingSendspinFullscreenDoubleTapDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Launch Now Playing when music starts playing'**
  String get settingSendspinFullscreenOnPlayTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Open the Now Playing view as soon as playback starts instead of waiting for the screensaver timeout.'**
  String get settingSendspinFullscreenOnPlayDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Dismiss \"Now Playing\" on motion'**
  String get settingSendspinFullscreenMotionTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Let motion dismiss Now Playing like a regular screensaver. Off, only touch dismisses it, so a walk-past does not interrupt the music display. Ignored while Now Playing is shown alongside a screensaver.'**
  String get settingSendspinFullscreenMotionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show in the kiosk menu'**
  String get settingSendspinFullscreenShortcutTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Add an entry in the kiosk menu that shows the Now Playing view. WARNING: If nothing is playing or there is no queue for this player, it won\'t show up.'**
  String get settingSendspinFullscreenShortcutDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show speaker selection pill'**
  String get settingSendspinSpeakerPillTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Shows speaker selection for 5 seconds after screen interaction. Add or remove speakers from the current group.'**
  String get settingSendspinSpeakerPillDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show album art in the queue'**
  String get settingSendspinQueueArtTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'A cover on every row of the queue panel.'**
  String get settingSendspinQueueArtDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Full-screen view while music plays'**
  String get mediaNowPlayingHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'User Interface'**
  String get mediaInterfaceHeading;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'\"Now Playing\" instead of the screensaver'**
  String get settingSendspinFullscreenTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'While music plays, the screensaver becomes a full-screen Now Playing view with album art. With nothing playing, the regular screensaver runs.'**
  String get settingSendspinFullscreenDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show alongside screensaver'**
  String get settingSendspinFullscreenSplitTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Keep the screensaver visible beside Now Playing. Portrait screens stack the screensaver above the player. Small screens keep the full-screen player.'**
  String get settingSendspinFullscreenSplitDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Fill the screen'**
  String get settingSendspinFullscreenPhotoFillTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Override photo filling while the screensaver shares the display with Now Playing. Default uses each screensaver\'s own setting. Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.'**
  String get settingSendspinFullscreenPhotoFillDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Override screensaver brightness'**
  String get settingSendspinFullscreenOverrideBrightnessTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Use normal screen brightness instead of screensaver brightness while Now Playing is shown alongside a screensaver. This also overrides scheduled screensaver brightness.'**
  String get settingSendspinFullscreenOverrideBrightnessDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Screensaver'**
  String get mediaScreensaverHeading;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get mediaDefaultFill;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get mediaFillOff;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get mediaFillSmart;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get mediaFillAlways;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Pick a player'**
  String get mediaPickPlayer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant player'**
  String get mediaMaPlayer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant media player'**
  String get mediaHaPlayer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Sonos room'**
  String get mediaSonosRoom;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Search players'**
  String get mediaSearchPlayers;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get mediaOffline;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{name} (offline)'**
  String mediaOfflineName(String name);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Set up Music Assistant to list its players.'**
  String get mediaSetUpMa;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Connect Home Assistant to list its media players.'**
  String get mediaSetUpHa;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No Sonos speakers known yet. Find or add one on the Sonos page.'**
  String get mediaSetUpSonos;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant did not answer: {error}'**
  String mediaHaFailed(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not save the player.'**
  String get mediaSaveFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not select player'**
  String get mediaSelectFailed;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable Sendspin player'**
  String get settingSendspinEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Turn this device into a synchronized Sendspin player. It appears in Music Assistant under the device name, in sync with every other Sendspin speaker.'**
  String get settingSendspinEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingSendspinServerTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Sendspin server address, for example 192.168.1.10:8927. Leave empty to find the server on the network automatically.'**
  String get settingSendspinServerDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Preferred audio codec'**
  String get settingSendspinCodecTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'FLAC is lossless and ideal on WiFi or ethernet. The server makes the final choice from what this device offers.'**
  String get settingSendspinCodecDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Audio sync offset (ms)'**
  String get settingSendspinSyncOffsetTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Negative plays this device earlier, for speakers that lag behind the group (Bluetooth). Tune by ear; applies live.'**
  String get settingSendspinSyncOffsetDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Sendspin Player'**
  String get mediaSendspinPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Make this device a synchronized Music Assistant player'**
  String get mediaSendspinHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'FLAC (lossless)'**
  String get mediaFlac;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Opus (efficient)'**
  String get mediaOpus;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'PCM (uncompressed)'**
  String get mediaPcm;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Adjust the group volume'**
  String get settingSendspinSonosGroupVolumeTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'While the followed room plays in a group, the volume slider sets the whole group\'s volume. Off, only that room\'s.'**
  String get settingSendspinSonosGroupVolumeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show TV and line-in'**
  String get settingSendspinSonosInputsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Show activity in the media player when eARC or line-in inputs are active.'**
  String get settingSendspinSonosInputsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Speakers on the network, add one by address'**
  String get mediaSonosHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Speakers'**
  String get mediaSonosSpeakers;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No Sonos found'**
  String get mediaSonosNoneFound;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Nothing answered on this network. Add one by address.'**
  String get mediaSonosDiscoveryEmpty;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add a Sonos by address'**
  String get mediaSonosAddTitle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Looking…'**
  String get mediaSonosLooking;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No speakers yet'**
  String get mediaSonosEmpty;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Search this network or add a speaker by its address.'**
  String get mediaSonosEmptyHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get mediaSonosForget;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Search the network'**
  String get mediaSonosSearchTitle;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Finds Sonos speakers on this network. The speakers must be on the same VLAN as this device to be auto discovered.'**
  String get mediaSonosSearchHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get mediaSonosSearch;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get mediaSonosSearching;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add by address'**
  String get mediaSonosAddAddress;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The speaker\'s address on the network. The whole household is added from it.'**
  String get mediaSonosAddressHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Pick a room under Player source, Sonos.'**
  String get mediaSonosPickRoom;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Sonos added'**
  String get mediaSonosAdded;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The speaker listed no rooms.'**
  String get mediaSonosNoRooms;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'no address'**
  String get mediaSonosNoAddress;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No Sonos answered at {host}.'**
  String mediaSonosUnreachable(String host);

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant Setup'**
  String get settingsMenuHomeAssistant;

  /// Summary below Home Assistant Setup in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Connection, dashboard, kiosk mode'**
  String get settingsMenuHomeAssistantSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Voice Satellite'**
  String get settingsMenuVoiceSatellite;

  /// Summary below Voice Satellite in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Wake word, background listening'**
  String get settingsMenuVoiceSatelliteSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'ESPHome'**
  String get settingsMenuEsphome;

  /// Summary below ESPHome in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Native entities and Bluetooth proxy'**
  String get settingsMenuEsphomeSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Screen & Audio'**
  String get settingsMenuScreenAudio;

  /// Summary below Screen & Audio in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Brightness, volume, microphone'**
  String get settingsMenuScreenAudioSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Screensaver'**
  String get settingsMenuScreensaver;

  /// Summary below Screensaver in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Idle timeout, modes, motion wake'**
  String get settingsMenuScreensaverSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Web Browsing'**
  String get settingsMenuBrowser;

  /// Summary below Web Browsing in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Cache, SSL, Zoom level'**
  String get settingsMenuBrowserSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Media Player'**
  String get settingsMenuMediaPlayer;

  /// Summary below Media Player in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Music Assistant, Sendspin, Sonos'**
  String get settingsMenuMediaPlayerSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'DLNA Renderer'**
  String get settingsMenuDlna;

  /// Summary below DLNA Renderer in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Play images, videos and audio remotely'**
  String get settingsMenuDlnaSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Intercom'**
  String get settingsMenuIntercom;

  /// Summary below Intercom in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Talk between kiosks'**
  String get settingsMenuIntercomSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get settingsMenuCamera;

  /// Summary below Camera in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Device camera, motion, streaming'**
  String get settingsMenuCameraSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Camera Streams'**
  String get settingsMenuCameraStreams;

  /// Summary below Camera Streams in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Go2RTC and Home Assistant cameras'**
  String get settingsMenuCameraStreamsSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Mode'**
  String get settingsMenuKiosk;

  /// Summary below Kiosk Mode in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Exit gesture, PIN, hardware buttons'**
  String get settingsMenuKioskSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Home Launcher'**
  String get settingsMenuHomeLauncher;

  /// Summary below Home Launcher in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Replace the device home screen'**
  String get settingsMenuHomeLauncherSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'App Launcher'**
  String get settingsMenuAppLauncher;

  /// Summary below App Launcher in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Open other apps from the kiosk'**
  String get settingsMenuAppLauncherSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get settingsMenuGestures;

  /// Summary below Gestures in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Touch, palm and clap gestures'**
  String get settingsMenuGesturesSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get settingsMenuDevice;

  /// Summary below Device in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Name, app theme, remote access'**
  String get settingsMenuDeviceSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Fleet Management'**
  String get settingsMenuFleet;

  /// Summary below Fleet Management in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Lead or follow other kiosks'**
  String get settingsMenuFleetSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Plugin Manager'**
  String get settingsMenuPlugins;

  /// Summary below Plugin Manager in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Install and manage plugins'**
  String get settingsMenuPluginsSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get settingsMenuLogs;

  /// Summary below Logs in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'App log and web console'**
  String get settingsMenuLogsSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsMenuAbout;

  /// Summary below About in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Version, author, license'**
  String get settingsMenuAboutSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get settingsMenuOverview;

  /// Summary below Overview in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Screen and quick controls'**
  String get settingsMenuOverviewSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Lockdown Mode'**
  String get settingsMenuLockdown;

  /// Summary below Lockdown Mode in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Disable screen interactions'**
  String get settingsMenuLockdownSummary;

  /// Settings menu entry. Product names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'File Manager'**
  String get settingsMenuFiles;

  /// Summary below File Manager in the Settings menu.
  ///
  /// In en, this message translates to:
  /// **'Browse, download and upload files'**
  String get settingsMenuFilesSummary;

  /// Heading above a group of Settings menu entries.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant'**
  String get settingsGroupHomeAssistant;

  /// Heading above a group of Settings menu entries.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsGroupDisplay;

  /// Heading above a group of Settings menu entries.
  ///
  /// In en, this message translates to:
  /// **'Media & Cameras'**
  String get settingsGroupMediaCameras;

  /// Heading above a group of Settings menu entries.
  ///
  /// In en, this message translates to:
  /// **'Kiosk'**
  String get settingsGroupKiosk;

  /// Heading above a group of Settings menu entries.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsGroupSystem;

  /// Remote administration sidebar control or accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get settingsMenuMenu;

  /// Remote administration sidebar control or accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsMenuTheme;

  /// Remote administration sidebar control or accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsMenuLogout;

  /// Remote administration sidebar control or accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Switch kiosk'**
  String get settingsMenuSwitchKiosk;

  /// Tooltip on the remote sidebar theme button. The value is the localized theme name.
  ///
  /// In en, this message translates to:
  /// **'Theme: {theme}'**
  String settingsMenuThemeState(String theme);

  /// Theme choice that follows the browser color preference.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsMenuThemeAuto;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Adaptive brightness'**
  String get settingAdaptiveBrightnessTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Dim the screen as the room gets darker, using the ambient light sensor.'**
  String get settingAdaptiveBrightnessDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Minimum brightness'**
  String get settingAdaptiveMinBrightnessTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Screen brightness in a dark room.'**
  String get settingAdaptiveMinBrightnessDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Maximum brightness'**
  String get settingAdaptiveMaxBrightnessTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Screen brightness in a bright room.'**
  String get settingAdaptiveMaxBrightnessDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Dark room (lx)'**
  String get settingAdaptiveDarkLuxTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Light level at or below which the screen sits at Minimum brightness.'**
  String get settingAdaptiveDarkLuxDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Bright room (lx)'**
  String get settingAdaptiveBrightLuxTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Light level at or above which the screen sits at Maximum brightness.'**
  String get settingAdaptiveBrightLuxDescription;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Follow the room light with the ambient light sensor'**
  String get screenAudioAdaptiveHint;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Level in a bright room. Adaptive brightness dims it from there.'**
  String get screenAudioAdaptiveNote;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Adaptive brightness is on.'**
  String get screenAudioAdaptiveOwns;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'No ambient light sensor on this device.'**
  String get screenAudioNoSensor;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Ambient light'**
  String get screenAudioAmbientLight;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'What the ambient light sensor reads right now.'**
  String get screenAudioAmbientHelp;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'No reading yet'**
  String get screenAudioNoReading;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'{lux} lx'**
  String screenAudioLux(String lux);

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'{lux} lx (last known)'**
  String screenAudioLuxLast(String lux);

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Sets Maximum brightness: adaptive brightness is on.'**
  String get screenAudioSetsMaximum;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Sets Default brightness.'**
  String get screenAudioSetsDefault;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get settingAudioMicDeviceTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The microphone wake word detection and voice turns capture from.'**
  String get settingAudioMicDeviceDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get settingAudioSpeakerDeviceTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Output for Voice Satellite sounds; media playback follows the system route. Echo cancellation only works with the microphone and speaker on the same device.'**
  String get settingAudioSpeakerDeviceDescription;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Audio Devices'**
  String get screenAudioDevices;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Selected device'**
  String get screenAudioSelectedDevice;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'{name} (not connected)'**
  String screenAudioDisconnected(String name);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Capture mode'**
  String get settingMicAudioSourceTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Voice communication is the only mode with echo cancellation, so leave it unless the microphone reads far quieter here than in a recorder app.'**
  String get settingMicAudioSourceDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Echo cancellation'**
  String get settingMicEchoCancellationTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Keeps the kiosk\'s own speaker out of the microphone so the stop word works during playback. Turn it off only if the microphone reads far quieter here than in a recorder app.'**
  String get settingMicEchoCancellationDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Microphone channel'**
  String get settingMicChannelTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Multichannel microphones often reserve one channel for speech recognition; picking it can improve detection.'**
  String get settingMicChannelDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Automatic gain control'**
  String get settingMicAgcTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Let Android level the microphone instead of a fixed gain. It also lifts room noise, and on some devices it does nothing at all.'**
  String get settingMicAgcDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Noise suppression'**
  String get settingMicNoiseSuppressionTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Reduce microphone background noise using Android processing. It may help or hurt wake word detection depending on the device.'**
  String get settingMicNoiseSuppressionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Microphone gain'**
  String get settingMicGainDbTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Boost or cut the microphone before anything hears it. Aim for a level near 0.05 in the wake word tester; too much gain distorts speech and hurts detection.'**
  String get settingMicGainDbDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Capture format'**
  String get settingMicCaptureFormatTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Pick 48 kHz stereo when the microphone works in other apps but not here: some sound cards record in that format only and the app converts it itself.'**
  String get settingMicCaptureFormatDescription;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Microphone settings'**
  String get screenAudioMicrophoneSettings;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Capture mode, channel, gain, live level'**
  String get screenAudioMicrophoneHint;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Adjust capture for your microphone and room. Test wake words and voice interactions after changing these settings.'**
  String get screenAudioMicrophoneNote;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Voice communication (default)'**
  String get screenAudioVoiceCommunication;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition'**
  String get screenAudioVoiceRecognition;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Raw microphone'**
  String get screenAudioRawMicrophone;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Automatic (default)'**
  String get screenAudioAutomaticDefault;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'48 kHz stereo'**
  String get screenAudioStereo;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Downmix (default)'**
  String get screenAudioDownmix;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Channel {channel}'**
  String screenAudioChannel(String channel);

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Channel {channel} (not on this microphone)'**
  String screenAudioChannelMissing(String channel);

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Microphone level'**
  String get screenAudioMicrophoneLevel;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Speak from where you use the device; adjust the gain until normal speech tops out around the end of the green.'**
  String get screenAudioMicrophoneLevelHelp;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Display cutout'**
  String get settingBrowserCutoutModeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'What to do with the screen area around a camera cutout or punch hole. Pick Avoid the cutout if the camera sits on top of buttons at the top of the dashboard.'**
  String get settingBrowserCutoutModeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Screen orientation'**
  String get settingScreenOrientationTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Force the screen into one orientation. Use this on a device without a rotation sensor, or one mounted a way the sensor gets wrong.'**
  String get settingScreenOrientationDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get settingKeepScreenOnTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Prevent the OS from turning the screen off.'**
  String get settingKeepScreenOnDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Set brightness on launch'**
  String get settingSetBrightnessOnLaunchTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Apply the default brightness whenever the app starts.'**
  String get settingSetBrightnessOnLaunchDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Default brightness'**
  String get settingDefaultBrightnessTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Screen brightness applied when the app starts. Moving the slider applies it immediately.'**
  String get settingDefaultBrightnessDescription;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get screenAudioScreen;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Use the cutout area'**
  String get screenAudioCutoutAlways;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Short edges only'**
  String get screenAudioCutoutShort;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get screenAudioCutoutDefault;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Avoid the cutout'**
  String get screenAudioCutoutNever;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get screenAudioAutomatic;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get screenAudioLandscape;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Reverse landscape'**
  String get screenAudioReverseLandscape;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get screenAudioPortrait;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Reverse portrait'**
  String get screenAudioReversePortrait;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get screenAudioPermission;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Brightness is using a fallback'**
  String get screenAudioBrightnessFallback;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Without the \"Modify system settings\" permission, brightness changes only dim this app instead of setting the panel\'s actual brightness.'**
  String get screenAudioBrightnessPermission;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Without the \"Modify system settings\" permission, brightness changes only dim the app instead of setting the panel\'s actual brightness.'**
  String get screenAudioBrightnessPermissionRemote;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Always-on display'**
  String get screenAudioAlwaysOn;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'This device keeps a dim clock on'**
  String get screenAudioAlwaysOnClock;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Turning the screen off puts the device to sleep, but the always-on display lights the lock screen back up and no app can stop it. Turn off \"Always show time and info\" in Android settings under Display, near the lock screen options; some ROMs call it always-on display. The Home Assistant screen entity stays unavailable until you do.'**
  String get screenAudioAlwaysOnHelp;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Media volume'**
  String get settingMediaVolumeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Music and video play at this share of the master volume. The Sendspin player volume in Music Assistant moves this slider.'**
  String get settingMediaVolumeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Assistant volume'**
  String get settingAssistantVolumeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Voice responses and chimes play at this share of the master volume, independent of the media volume.'**
  String get settingAssistantVolumeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Full assistant volume range'**
  String get settingAssistantFullVolumeRangeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Initialize the built-in speaker\'s call volume at 100% when assistant audio first starts. Master and assistant volume still apply. Other apps share this call volume, which is not restored afterward.'**
  String get settingAssistantFullVolumeRangeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Intercom volume'**
  String get settingIntercomVolumeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The other kiosk\'s voice and announcements play at this share of the master volume.'**
  String get settingIntercomVolumeDescription;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Audio Volume'**
  String get screenAudioVolume;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'Master volume'**
  String get screenAudioMasterVolume;

  /// Heading, choice, status or guidance shown in this group.
  ///
  /// In en, this message translates to:
  /// **'The device volume. Media, intercom and assistant volumes scale under it.'**
  String get screenAudioMasterHelp;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Hide all extras'**
  String get settingScreensaverBlackHideExtrasTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Keeps the screen fully black: no small clock, At a Glance entities, or other overlays.'**
  String get settingScreensaverBlackHideExtrasDescription;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Black screensaver'**
  String get screensaverBlackSection;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get settingScreensaverClockStyleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How the clock is drawn.'**
  String get settingScreensaverClockStyleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get settingScreensaverClockFontTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The typeface the clock is drawn in.'**
  String get settingScreensaverClockFontDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Font weight'**
  String get settingScreensaverClockFontWeightTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How heavy the clock\'s digits are drawn. Default is each face\'s own weight.'**
  String get settingScreensaverClockFontWeightDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'24-hour clock'**
  String get settingScreensaverClock24hTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show a 24-hour time instead of AM/PM.'**
  String get settingScreensaverClock24hDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show seconds'**
  String get settingScreensaverClockSecondsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Include seconds in the clock.'**
  String get settingScreensaverClockSecondsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show date'**
  String get settingScreensaverClockDateTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show the weekday and date under the clock.'**
  String get settingScreensaverClockDateDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Clock size'**
  String get settingScreensaverClockScaleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Scale the clock from 50 to 300 percent for this screen.'**
  String get settingScreensaverClockScaleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Clock color'**
  String get settingScreensaverClockColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color of the clock text.'**
  String get settingScreensaverClockColorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get settingScreensaverClockBgColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color behind the clock.'**
  String get settingScreensaverClockBgColorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Background photo'**
  String get settingScreensaverClockBackgroundTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show a photo behind the clock instead of the solid color. A path to an image on the device, or an image URL the device fetches.'**
  String get settingScreensaverClockBackgroundDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Refresh URL background'**
  String get settingScreensaverClockBackgroundRefreshTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Minutes between fetches of a URL background. 0 fetches it only when the setting is written.'**
  String get settingScreensaverClockBackgroundRefreshDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Digit color'**
  String get settingScreensaverFlipDigitColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color of the flip digits.'**
  String get settingScreensaverFlipDigitColorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Card color'**
  String get settingScreensaverFlipBgColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color of the cards.'**
  String get settingScreensaverFlipBgColorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get settingScreensaverFlipBackdropColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color behind the cards.'**
  String get settingScreensaverFlipBackdropColorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Digit color'**
  String get settingScreensaverRollerDigitColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color of the rolling digits.'**
  String get settingScreensaverRollerDigitColorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get settingScreensaverRollerBgColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color behind the digits.'**
  String get settingScreensaverRollerBgColorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get settingScreensaverClockNightTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Recolor the clock while the room is dark.'**
  String get settingScreensaverClockNightDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Light level'**
  String get settingScreensaverClockNightLuxTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'At or below this light level the clock takes the night color.'**
  String get settingScreensaverClockNightLuxDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Night color'**
  String get settingScreensaverClockNightColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color of the clock and the widgets in the dark.'**
  String get settingScreensaverClockNightColorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Night background'**
  String get settingScreensaverClockNightBgColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color behind the clock in the dark.'**
  String get settingScreensaverClockNightBgColorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Hide background photo'**
  String get settingScreensaverClockNightHideBackgroundTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Use the night background color instead of the photo while Night mode is active.'**
  String get settingScreensaverClockNightHideBackgroundDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Night card color'**
  String get settingScreensaverClockNightCardColorTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The color of the flip cards in the dark.'**
  String get settingScreensaverClockNightCardColorDescription;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Clock screensaver'**
  String get screensaverClockSection;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Style, font, size, colors, night mode, background photo'**
  String get screensaverClockHint;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Digital Clock'**
  String get screensaverStyleDigital;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Flip Clock'**
  String get screensaverStyleFlip;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Roller Clock'**
  String get screensaverStyleRoller;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get screensaverFontDefault;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get screensaverFontLight;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get screensaverFontRegular;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get screensaverFontMedium;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get screensaverFontBold;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get screensaverFontBlack;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No photo selected'**
  String get screensaverNoPhoto;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Path to an image on the device, or an image URL'**
  String get screensaverBackgroundHint;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enter a full image URL'**
  String get screensaverImageUrlError;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enter whole minutes from 0 to 1440'**
  String get screensaverRefreshError;

  /// Maximum length validation error.
  ///
  /// In en, this message translates to:
  /// **'Use at most {count} characters'**
  String screensaverMaxCharacters(String count);

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get screensaverOverlayEntity;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get screensaverOverlayNotSet;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get screensaverOverlayName;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the Home Assistant name.'**
  String get screensaverOverlayNameHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Displayed value'**
  String get screensaverOverlayValue;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get screensaverOverlayState;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Pick an entity.'**
  String get screensaverOverlayEntityRequired;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Name or entity id'**
  String get screensaverOverlaySearchHint;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Search by name or entity id'**
  String get screensaverOverlaySearchHintRemote;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Type to search entities.'**
  String get screensaverOverlaySearchEmpty;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched.'**
  String get screensaverOverlayNoMatches;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get screensaverOverlaySearching;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Home Assistant'**
  String get screensaverOverlayUnreachable;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'The device did not answer.'**
  String get screensaverOverlayNoAnswer;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Could not search entities: {error}'**
  String screensaverOverlaySearchError(String error);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Dismiss on face'**
  String get settingScreensaverDismissOnFaceTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Wake the screen when someone looks at the kiosk, not on movement alone. The camera runs only during the screensaver. WARNING: Needs a lit face; in the dark, schedule motion detection instead.'**
  String get settingScreensaverDismissOnFaceDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Only when screen is off'**
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Keep the screensaver visible when a face is detected while the screen is on. Once the screen turns off, detection wakes the dashboard. Touch still dismisses the screensaver.'**
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Postpone screensaver on face'**
  String get settingScreensaverPostponeOnFaceTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Delay activating the screensaver while someone is looking at the kiosk. WARNING: Keeps the camera running permanently, with face detection and its CPU cost on top.'**
  String get settingScreensaverPostponeOnFaceDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Face sensitivity'**
  String get settingFaceSensitivityTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Higher wakes on smaller, more distant faces. 1 needs a face close to the screen; 100 reacts to any face the camera can make out.'**
  String get settingFaceSensitivityDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Face Detection'**
  String get screensaverDetectionFacePage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss the screensaver when someone looks at it'**
  String get screensaverDetectionFaceHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss on motion is on and takes precedence, so face detection stays idle until it is turned off.'**
  String get screensaverDetectionMotionPrecedence;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Frame rate, camera pick and startup delay are tuned in the Camera settings.'**
  String get screensaverDetectionFaceTuning;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not available on this Android version.'**
  String get screensaverDetectionAndroidUnsupported;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not available on x86 devices.'**
  String get screensaverDetectionX86Unsupported;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show camera preview'**
  String get settingFacePreviewTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Show a small round live view of the camera in a corner of the screen for a few seconds when a face wakes the kiosk.'**
  String get settingFacePreviewDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Preview duration'**
  String get settingFacePreviewSecondsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'How long the preview stays on screen.'**
  String get settingFacePreviewSecondsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Preview scaling'**
  String get settingFacePreviewScaleTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Scale the preview to better fit your screen size.'**
  String get settingFacePreviewScaleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Preview position'**
  String get settingFacePreviewPositionTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Which corner the preview sits in.'**
  String get settingFacePreviewPositionDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Camera Preview'**
  String get screensaverDetectionPreviewSection;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Screensaver'**
  String get settingScreensaverEnabledTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Dim or blank the screen after a period of inactivity.'**
  String get settingScreensaverEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Idle timeout (seconds)'**
  String get settingScreensaverTimeoutSecondsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Inactivity period before the screensaver starts.'**
  String get settingScreensaverTimeoutSecondsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Screensaver mode'**
  String get settingScreensaverModeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'What the screensaver shows after the idle timeout. Dim only lowers the backlight and leaves the dashboard on screen.'**
  String get settingScreensaverModeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Pixel shift'**
  String get settingScreensaverPixelShiftTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Nudge the image every minute to protect OLED panels. Not for the black screensaver, whose pixels are already off.'**
  String get settingScreensaverPixelShiftDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show in the kiosk menu'**
  String get settingScreensaverMenuTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Add a Start Screensaver entry to the kiosk menu.'**
  String get settingScreensaverMenuDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Dim level'**
  String get settingScreensaverDimLevelTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Screen brightness while the screensaver is dimming.'**
  String get settingScreensaverDimLevelDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Screensaver brightness'**
  String get settingScreensaverBrightnessEnabledTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Use a separate brightness while the screensaver is showing.'**
  String get settingScreensaverBrightnessEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Brightness level'**
  String get settingScreensaverBrightnessLevelTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Applies to every mode except Dim and Black.'**
  String get settingScreensaverBrightnessLevelDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Brighten for notifications'**
  String get settingScreensaverNotificationBrightnessTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Lift the screensaver dimming while a notification is on screen.'**
  String get settingScreensaverNotificationBrightnessDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Turn screen off after'**
  String get settingScreensaverScreenOffMinutesTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Powers down the display panel once the screensaver has run for the set duration. Set to 0 to keep the screen on indefinitely. Requires Device Administrator permission.'**
  String get settingScreensaverScreenOffMinutesDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Wake to screensaver'**
  String get settingScreensaverScreenOffWakeToScreensaverTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Motion, face, proximity or person detection after the screen has turned off brings the screensaver back instead of the dashboard, with a fresh Turn screen off after countdown. Touch still opens the dashboard.'**
  String get settingScreensaverScreenOffWakeToScreensaverDescription;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dim'**
  String get screensaverModeDim;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get screensaverModeBlack;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get screensaverModeClock;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant Media'**
  String get screensaverModeMedia;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Local Media'**
  String get screensaverModeLocal;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery'**
  String get screensaverModeGallery;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Immich Media'**
  String get screensaverModeImmich;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get screensaverModeWebsite;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Camera Streams'**
  String get screensaverModeCamera;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dim screensaver'**
  String get screensaverDimSection;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Please Read!'**
  String get screensaverWarningTitle;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Turn screen off anyway'**
  String get screensaverScreenOffProceed;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not granted, so the screen cannot turn off.'**
  String get screensaverAdminMissing;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Device admin permission missing'**
  String get screensaverAdminMissingRemote;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Without it the screen cannot be turned off. The grant dialog appears on the tablet screen.'**
  String get screensaverAdminMissingRemoteHelp;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Dim keeps the dashboard visible, so the \"Pause dashboard during screensaver\" optimization will not be applied and the dashboard keeps using CPU, GPU and battery.'**
  String get screensaverDimWarning;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Unavailable plugin screensaver'**
  String get screensaverUnavailablePlugin;

  /// Warning before enabling physical screen power-off.
  ///
  /// In en, this message translates to:
  /// **'Once the display truly powers off, the tablet\'s own power management takes over, and many Android models misbehave in that state: Wi-Fi naps or drops, the Home Assistant entities go unavailable, the camera can be revoked, and some models kill background apps outright. What happens depends on the manufacturer.\n\nThe reliable alternative is the Black screensaver with this setting left at 0: the panel looks just as dark, and the app keeps full control.'**
  String get screensaverScreenOffWarning;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Use a black screen instead'**
  String get settingScreensaverScreenOffBlackTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show a plain black screen at zero brightness instead of powering off the display. Hides widgets and Now Playing. No Device Administrator permission is needed.'**
  String get settingScreensaverScreenOffBlackDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Row scaling'**
  String get settingScreensaverGlanceScaleTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Scale the row to better fit your screen size.'**
  String get settingScreensaverGlanceScaleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Font family'**
  String get settingScreensaverGlanceFontTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'The typeface the row is drawn in.'**
  String get settingScreensaverGlanceFontDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Font weight'**
  String get settingScreensaverGlanceFontWeightTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'How heavy the row\'s text is drawn. Default is each line\'s own weight: regular names, semibold values.'**
  String get settingScreensaverGlanceFontWeightDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Hide names'**
  String get settingScreensaverGlanceHideNamesTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Show only the icon and the value, with the value drawn larger.'**
  String get settingScreensaverGlanceHideNamesDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Monochromatic icons'**
  String get settingScreensaverGlanceBwIconsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Keep every icon in the neutral grey instead of its state color.'**
  String get settingScreensaverGlanceBwIconsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Floating text style'**
  String get settingScreensaverGlanceTextOnlyTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Show the entities as floating text instead of chips.'**
  String get settingScreensaverGlanceTextOnlyDescription;

  /// Settings group heading.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get screensaverOverlayAppearance;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get settingScreensaverGlanceEnabledTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Show a row of Home Assistant entity states on the screensaver.'**
  String get settingScreensaverGlanceEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Entities'**
  String get settingScreensaverGlanceEntitiesTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Up to four entities to show, each with an optional custom name.'**
  String get settingScreensaverGlanceEntitiesDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show on Now Playing'**
  String get settingScreensaverGlanceNowPlayingTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Show the row on the full-screen Now Playing view. It stays hidden while lyrics are showing.'**
  String get settingScreensaverGlanceNowPlayingDescription;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Showing'**
  String get screensaverOverlayShowing;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Showing (drag to reorder)'**
  String get screensaverOverlayReorder;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'That is the most the row can show. Remove one to add another.'**
  String get screensaverOverlayFull;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'At a glance entities'**
  String get screensaverOverlayPickerTitle;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'None yet. Up to {count} entities.'**
  String screensaverOverlayGlanceEmpty(String count);

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get screensaverOverlayNone;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} entities.'**
  String screensaverOverlayLimit(String count);

  /// Subpage navigation title or summary.
  ///
  /// In en, this message translates to:
  /// **'At a Glance'**
  String get screensaverOverlayGlancePage;

  /// Subpage navigation title or summary.
  ///
  /// In en, this message translates to:
  /// **'Entities shown over the screensaver'**
  String get screensaverOverlayGlanceHint;

  /// Reserved entity state when Home Assistant cannot report a value.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get glanceUnavailable;

  /// Reserved entity state when Home Assistant cannot report a value.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get glanceUnknown;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get settingScreensaverImmichUrlTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The address of your Immich server, with its port.'**
  String get settingScreensaverImmichUrlDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingScreensaverImmichApiKeyTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Created in Immich under Account Settings → API Keys.'**
  String get settingScreensaverImmichApiKeyDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Immich Media screensaver'**
  String get screensaverMediaImmichPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Server, media, slideshow, metadata, filters'**
  String get screensaverMediaImmichHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Server Connection'**
  String get screensaverMediaServerConnection;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Validation failed. See the app log for the failing call.'**
  String get screensaverMediaValidateFailedLog;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Validation failed.'**
  String get screensaverMediaValidateFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The device did not answer.'**
  String get screensaverMediaNoAnswer;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enter the server address first.'**
  String get screensaverMediaAddressFirst;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Enter an API key first.'**
  String get screensaverMediaKeyFirst;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The server address is not a valid URL.'**
  String get screensaverMediaBadAddress;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The API key was rejected.'**
  String get screensaverMediaKeyRejected;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The API key is missing the {scope} permission.'**
  String screensaverMediaScopeMissing(String scope);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The API key is missing a permission: {error}'**
  String screensaverMediaPermissionMissing(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The server answered {status}: {error}'**
  String screensaverMediaServerError(String status, String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not reach {url}.'**
  String screensaverMediaUnreachable(String url);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not talk to the server: {error}'**
  String screensaverMediaTalkError(String error);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get settingScreensaverImmichPeopleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show only media with any of these people.'**
  String get settingScreensaverImmichPeopleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Exclude people'**
  String get settingScreensaverImmichExcludePeopleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Skip media with any of these people.'**
  String get settingScreensaverImmichExcludePeopleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get settingScreensaverImmichTagsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show only media with any of these tags.'**
  String get settingScreensaverImmichTagsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Exclude tags'**
  String get settingScreensaverImmichExcludeTagsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Skip media with any of these tags.'**
  String get settingScreensaverImmichExcludeTagsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get settingScreensaverImmichFavoritesOnlyTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show only media marked as favorite.'**
  String get settingScreensaverImmichFavoritesOnlyDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Taken within'**
  String get settingScreensaverImmichTakenWithinTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Only show media taken in this window.'**
  String get settingScreensaverImmichTakenWithinDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get settingScreensaverImmichTakenFromTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Skip media taken before this date.'**
  String get settingScreensaverImmichTakenFromDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get settingScreensaverImmichTakenToTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Skip media taken after this date. The day itself counts.'**
  String get settingScreensaverImmichTakenToDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get screensaverMediaFilters;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get screensaverMediaAnyone;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Anyone.'**
  String get screensaverMediaAnyoneDevice;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No one'**
  String get screensaverMediaNoOne;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No one.'**
  String get screensaverMediaNoOneDevice;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get screensaverMediaAny;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Any.'**
  String get screensaverMediaAnyDevice;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get screensaverMediaNoTagsChosen;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No tags.'**
  String get screensaverMediaNoTagsChosenDevice;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No named people yet. Name them in Immich first.'**
  String get screensaverMediaNoPeople;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Create them in Immich first.'**
  String get screensaverMediaNoTags;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not list the people'**
  String get screensaverMediaPeopleFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not list the tags'**
  String get screensaverMediaTagsFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get screensaverMediaHidden;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get screensaverMediaAnyTime;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Past month'**
  String get screensaverMediaPastMonth;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Past 3 months'**
  String get screensaverMediaPast3Months;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Past year'**
  String get screensaverMediaPastYear;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Past 2 years'**
  String get screensaverMediaPast2Years;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Past 5 years'**
  String get screensaverMediaPast5Years;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Past 10 years'**
  String get screensaverMediaPast10Years;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get screensaverMediaSince;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Timeframe'**
  String get screensaverMediaTimeframe;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get screensaverMediaToday;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Use YYYY-MM-DD.'**
  String get screensaverMediaDateFormat;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'That is not a date.'**
  String get screensaverMediaNotDate;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Show metadata'**
  String get settingScreensaverImmichMetadataTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Album, date, camera and location over the media.'**
  String get settingScreensaverImmichMetadataDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get settingScreensaverImmichMetadataAlbumTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show which album the photo comes from.'**
  String get settingScreensaverImmichMetadataAlbumDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Date taken'**
  String get settingScreensaverImmichMetadataDateTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show when the photo was taken.'**
  String get settingScreensaverImmichMetadataDateDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Camera details'**
  String get settingScreensaverImmichMetadataCameraTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show focal length, aperture and ISO.'**
  String get settingScreensaverImmichMetadataCameraDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingScreensaverImmichMetadataLocationTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show the place the photo was taken.'**
  String get settingScreensaverImmichMetadataLocationDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Metadata position'**
  String get settingScreensaverImmichMetadataPositionTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Which corner the details sit in.'**
  String get settingScreensaverImmichMetadataPositionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Text drop shadow'**
  String get settingScreensaverImmichMetadataTextShadowTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Add a drop shadow to metadata text for readability on photos.'**
  String get settingScreensaverImmichMetadataTextShadowDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Text scaling'**
  String get settingScreensaverImmichMetadataScaleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Scale the photo details to better fit your screen size.'**
  String get settingScreensaverImmichMetadataScaleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Vignette strength'**
  String get settingScreensaverImmichVignetteStrengthTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Darkness of the shading behind the details, for readability on bright photos. 0 turns it off.'**
  String get settingScreensaverImmichVignetteStrengthDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get screensaverMediaMetadata;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get screensaverMediaTopLeft;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get screensaverMediaTopRight;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get screensaverMediaBottomLeft;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Bottom right'**
  String get screensaverMediaBottomRight;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Seconds per image'**
  String get settingScreensaverImmichIntervalTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How long each image shows before the next. Videos play in full.'**
  String get settingScreensaverImmichIntervalDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get settingScreensaverImmichShuffleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Cycle the media in random order.'**
  String get settingScreensaverImmichShuffleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get settingScreensaverImmichTransitionTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How one item hands off to the next.'**
  String get settingScreensaverImmichTransitionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Fill the screen'**
  String get settingScreensaverImmichFillTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.'**
  String get settingScreensaverImmichFillDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Pair portrait photos'**
  String get settingScreensaverImmichPairPortraitTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show two portrait photos side by side so they fill the screen.'**
  String get settingScreensaverImmichPairPortraitDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Pair landscape photos'**
  String get settingScreensaverImmichPairLandscapeTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Show two landscape photos one above the other so they fill a portrait screen.'**
  String get settingScreensaverImmichPairLandscapeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Tap edges to change slides'**
  String get settingScreensaverImmichEdgeTapsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'A tap on the left or right fifth of the screen shows the previous or next slide instead of dismissing.'**
  String get settingScreensaverImmichEdgeTapsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Slideshow'**
  String get screensaverMediaSlideshow;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Media source'**
  String get settingScreensaverImmichAlbumTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The whole library, or the albums you pick.'**
  String get settingScreensaverImmichAlbumDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Photos only'**
  String get settingScreensaverImmichPhotosOnlyTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Skip videos in the slideshow.'**
  String get settingScreensaverImmichPhotosOnlyDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Cache media locally'**
  String get settingScreensaverImmichCacheTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Keep copies on the device so images load instantly.'**
  String get settingScreensaverImmichCacheDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Cache size (items)'**
  String get settingScreensaverImmichCacheMaxTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The oldest items are deleted once the cache is full.'**
  String get settingScreensaverImmichCacheMaxDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'All media'**
  String get screensaverMediaAll;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'All media.'**
  String get screensaverMediaAllDevice;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No albums yet. Create one in Immich first.'**
  String get screensaverMediaNoAlbums;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not list the albums'**
  String get screensaverMediaAlbumsFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not list them: {error}'**
  String screensaverMediaListError(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'listing failed'**
  String get screensaverMediaListingFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String screensaverMediaItems(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} cached, {size}'**
  String screensaverMediaCached(String count, String size);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Camera views'**
  String get settingScreensaverCameraViewsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The camera views the screensaver shows, in this order.'**
  String get settingScreensaverCameraViewsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Seconds per camera view'**
  String get settingScreensaverCameraViewSecondsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How long each view stays on screen before the next one. With a single view selected nothing rotates.'**
  String get settingScreensaverCameraViewSecondsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Mute all views'**
  String get settingScreensaverCameraMuteTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Keeps every view silent, even a single camera.'**
  String get settingScreensaverCameraMuteDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Camera Streams screensaver'**
  String get screensaverMediaCameraPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Views to show, seconds per view, sound'**
  String get screensaverMediaCameraHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No camera view has cameras yet. Add one under Camera Streams.'**
  String get screensaverMediaNoCameras;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No camera view has cameras yet'**
  String get screensaverMediaNoCamerasRemote;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add one under Camera Streams.'**
  String get screensaverMediaAddCameras;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'None yet. Pick the views the screensaver cycles through.'**
  String get screensaverMediaNoViews;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'In the rotation (drag to reorder)'**
  String get screensaverMediaRotation;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get screensaverMediaAvailable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} camera'**
  String screensaverMediaOneCamera(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} cameras'**
  String screensaverMediaCameras(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Position {index} · {cameras}'**
  String screensaverMediaPosition(String index, String cameras);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get screensaverMediaTransitionNone;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Crossfade'**
  String get screensaverMediaTransitionFade;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get screensaverMediaTransitionSlide;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get screensaverMediaTransitionZoom;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Ken Burns'**
  String get screensaverMediaTransitionKenBurns;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get screensaverMediaTransitionRandom;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get screensaverMediaFillOff;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get screensaverMediaFillSmart;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get screensaverMediaFillAlways;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get settingScreensaverGalleryItemsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'The photos and videos this screensaver cycles. Picked from the gallery on the device; picking again replaces the selection.'**
  String get settingScreensaverGalleryItemsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Seconds per photo'**
  String get settingScreensaverGalleryIntervalTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How long each photo shows before the next. Videos play in full.'**
  String get settingScreensaverGalleryIntervalDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get settingScreensaverGalleryShuffleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Cycle the selection in random order.'**
  String get settingScreensaverGalleryShuffleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get settingScreensaverGalleryTransitionTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How one photo hands off to the next.'**
  String get settingScreensaverGalleryTransitionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Fill the screen'**
  String get settingScreensaverGalleryFillTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.'**
  String get settingScreensaverGalleryFillDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Tap edges to change slides'**
  String get settingScreensaverGalleryEdgeTapsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'A tap on the left or right fifth of the screen shows the previous or next slide instead of dismissing.'**
  String get settingScreensaverGalleryEdgeTapsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery screensaver'**
  String get screensaverMediaGalleryPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Photos, timing, shuffle, transition'**
  String get screensaverMediaGalleryHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Loading photos...'**
  String get screensaverMediaLoadingPhotos;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Copying photo {index} of {total}...'**
  String screensaverMediaCopying(String index, String total);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the photos'**
  String get screensaverMediaCopyFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Try a smaller selection.'**
  String get screensaverMediaSmallerSelection;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No photos selected'**
  String get screensaverMediaNoPhotos;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String screensaverMediaSelected(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'None selected. Pick on the device.'**
  String get screensaverMediaPickOnDevice;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Media source'**
  String get settingScreensaverMediaIdTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'A Home Assistant media item, folder, or camera. Use Browse to pick one.'**
  String get settingScreensaverMediaIdDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Seconds per image'**
  String get settingScreensaverMediaIntervalTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How long each image shows before the next. Videos play in full.'**
  String get settingScreensaverMediaIntervalDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get settingScreensaverMediaShuffleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Play a folder in random order.'**
  String get settingScreensaverMediaShuffleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Include subfolders'**
  String get settingScreensaverMediaRecursiveTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Descend into subfolders when a folder is chosen.'**
  String get settingScreensaverMediaRecursiveDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get settingScreensaverMediaTransitionTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How one item hands off to the next.'**
  String get settingScreensaverMediaTransitionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Fill the screen'**
  String get settingScreensaverMediaFillTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.'**
  String get settingScreensaverMediaFillDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Tap edges to change slides'**
  String get settingScreensaverMediaEdgeTapsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'A tap on the left or right fifth of the screen shows the previous or next slide instead of dismissing.'**
  String get settingScreensaverMediaEdgeTapsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant Media screensaver'**
  String get screensaverMediaHaPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Media source, timing, shuffle, fill'**
  String get screensaverMediaHaHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Choose media'**
  String get screensaverMediaChoose;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get screensaverMediaRoot;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Home Assistant, or the token is missing.'**
  String get screensaverMediaHaUnavailable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Nothing here.'**
  String get screensaverMediaEmpty;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Use this folder'**
  String get screensaverMediaUseFolder;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'folder'**
  String get screensaverMediaFolder;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'camera'**
  String get screensaverMediaCamera;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get screensaverMediaItem;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'browse failed'**
  String get screensaverMediaBrowseFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not browse: {error}'**
  String screensaverMediaBrowseError(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get screensaverMediaNotSet;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Local folder'**
  String get settingScreensaverLocalFolderTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Folder on this device whose photos and videos the screensaver cycles through. Picked on the device; the path can also be typed here remotely.'**
  String get settingScreensaverLocalFolderDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Seconds per photo'**
  String get settingScreensaverLocalIntervalTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How long each photo shows before the next. Videos play in full.'**
  String get settingScreensaverLocalIntervalDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get settingScreensaverLocalShuffleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Cycle the folder in random order instead of by name.'**
  String get settingScreensaverLocalShuffleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Include subfolders'**
  String get settingScreensaverLocalRecursiveTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Also cycle photos and videos inside subfolders.'**
  String get settingScreensaverLocalRecursiveDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get settingScreensaverLocalTransitionTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'How one photo hands off to the next.'**
  String get settingScreensaverLocalTransitionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Fill the screen'**
  String get settingScreensaverLocalFillTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Off keeps the whole photo between black bars. Smart enlarges photos shaped close to the screen, framing the rest over a blurred backdrop. Always enlarges every photo, cutting off what does not fit.'**
  String get settingScreensaverLocalFillDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Tap edges to change slides'**
  String get settingScreensaverLocalEdgeTapsTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'A tap on the left or right fifth of the screen shows the previous or next slide instead of dismissing.'**
  String get settingScreensaverLocalEdgeTapsDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Local Media screensaver'**
  String get screensaverMediaLocalPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Folder, timing, shuffle, transition'**
  String get screensaverMediaLocalHint;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Dismiss on motion'**
  String get settingScreensaverDismissOnMotionTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Watch the camera while the screensaver is up and wake the screen when someone approaches. The camera runs only during the screensaver.'**
  String get settingScreensaverDismissOnMotionDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Only when screen is off'**
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Keep the screensaver visible when motion is detected while the screen is on. Once the screen turns off, detection wakes the dashboard. Touch still dismisses the screensaver.'**
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Postpone screensaver on motion'**
  String get settingScreensaverPostponeOnMotionTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Delay activating the screensaver when motion is detected. WARNING: Keeps the camera running permanently.'**
  String get settingScreensaverPostponeOnMotionDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Motion Detection'**
  String get screensaverDetectionMotionPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss or postpone the screensaver on motion'**
  String get screensaverDetectionMotionHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Motion detection is tuned in the Camera settings.'**
  String get screensaverDetectionMotionTuning;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Dismiss on person'**
  String get settingScreensaverDismissOnPersonTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Read the device\'s person sensor while the screensaver is up and wake the screen when someone is in front of it. Needs the Log access grant below.'**
  String get settingScreensaverDismissOnPersonDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Only when screen is off'**
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Keep the screensaver visible when someone arrives while the screen is on. Once the screen turns off, detection wakes the dashboard. Touch still dismisses the screensaver.'**
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Postpone screensaver on person'**
  String get settingScreensaverPostponeOnPersonTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Delay activating the screensaver while someone is in front of the device.'**
  String get settingScreensaverPostponeOnPersonDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Person Detection'**
  String get screensaverDetectionPersonPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss or postpone the screensaver on the device\'s person sensor'**
  String get screensaverDetectionPersonHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get screensaverDetectionOccupancy;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable.'**
  String get screensaverDetectionStatusUnavailable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Off.'**
  String get screensaverDetectionOff;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get screensaverDetectionStarting;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the first heartbeat. The sensor reports every 30 seconds while someone is in view.'**
  String get screensaverDetectionWaiting;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Last heartbeat {ago}.'**
  String screensaverDetectionLastHeartbeat(String ago);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count}s ago'**
  String screensaverDetectionSecondsAgo(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String screensaverDetectionMinutesAgo(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String screensaverDetectionHoursAgo(String count);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get screensaverDetectionDetected;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get screensaverDetectionClear;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Required system permissions'**
  String get screensaverDetectionPermissions;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Log access'**
  String get screensaverDetectionLogAccess;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get screensaverDetectionChecking;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'The device\'s person sensor can be read.'**
  String get screensaverDetectionReadable;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Granted. Restart Kiosk Satellite to apply it.'**
  String get screensaverDetectionRestartRequired;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'This permission can only be granted via ADB. The Meta Portal doc has the full command. Restart Kiosk Satellite afterwards.'**
  String get screensaverDetectionGrantHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'This permission can only be granted via ADB. Below is the full command, ready to be copied. Restart Kiosk Satellite afterwards.'**
  String get screensaverDetectionGrantRemoteHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get screensaverDetectionGranted;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get screensaverDetectionMissing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get screensaverDetectionRestart;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Restart on device'**
  String get screensaverDetectionRestartRemote;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Log access is granted but takes effect when Kiosk Satellite restarts.'**
  String get screensaverDetectionLogRestart;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Log access not granted.'**
  String get screensaverDetectionLogMissing;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Dismiss on proximity'**
  String get settingScreensaverDismissOnProximityTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Watch the proximity sensor while the screensaver is up and wake the screen when something comes close to the device. A device with only sensors made for calls (\"palm\", \"touch\") will not work.'**
  String get settingScreensaverDismissOnProximityDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Only when screen is off'**
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Keep the screensaver visible when something approaches while the screen is on. Once the screen turns off, detection wakes the dashboard. Touch still dismisses the screensaver.'**
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Postpone screensaver on proximity'**
  String get settingScreensaverPostponeOnProximityTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Delay activating the screensaver while something is close to the sensor.'**
  String get settingScreensaverPostponeOnProximityDescription;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Proximity Detection'**
  String get screensaverDetectionProximityPage;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss or postpone the screensaver on the proximity sensor'**
  String get screensaverDetectionProximityHint;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device: it has no proximity sensor.'**
  String get screensaverDetectionNoProximity;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Sensor'**
  String get screensaverDetectionSensor;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'What the device reports as the proximity sensor. A sensor made for calls named \"palm\" or \"touch\" will not work.'**
  String get screensaverDetectionSensorHelp;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable scheduled screensavers'**
  String get settingScreensaverScheduleEnabledTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Switch to a different screensaver at set times of day.'**
  String get settingScreensaverScheduleEnabledDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get settingScreensaverScheduleTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Each time switches the screensaver from then on.'**
  String get settingScreensaverScheduleDescription;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Screensavers'**
  String get screensaverScheduleSection;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get screensaverTime;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get screensaverAddTime;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Remove time'**
  String get screensaverRemoveTime;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'No times yet'**
  String get screensaverNoTimes;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'A screensaver from that time on.'**
  String get screensaverTimeHelp;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Pick a time.'**
  String get screensaverPickTime;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get screensaverDefault;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get screensaverOn;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get screensaverOff;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get screensaverBrightness;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Follows the Screensaver brightness setting.'**
  String get screensaverBrightnessFollow;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Applies to every mode except Black.'**
  String get screensaverBrightnessExceptBlack;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Follows the Turn screen off after setting.'**
  String get screensaverScreenOffFollow;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Keeps the screen on during these hours.'**
  String get screensaverScreenOnHours;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Powers down the display once the screensaver has run this long. Requires Device Administrator permission.'**
  String get screensaverScreenOffHelp;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Screen off never'**
  String get screensaverScreenOffNever;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss on motion'**
  String get screensaverMotion;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss on face'**
  String get screensaverFace;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss on proximity'**
  String get screensaverProximity;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Dismiss on person'**
  String get screensaverPerson;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get screensaverWidgets;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get screensaverGlance;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Show Now Playing next to the screensaver'**
  String get screensaverNowPlaying;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Default follows the global layout. On uses a shared layout when Now Playing is enabled. Off hides Now Playing during these hours.'**
  String get screensaverNowPlayingHelp;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Requires the camera. Turn it on in the Camera settings first.'**
  String get screensaverCameraRequired;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device.'**
  String get screensaverNotAvailable;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Motion on'**
  String get screensaverSummaryMotionOn;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Motion off'**
  String get screensaverSummaryMotionOff;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Face on'**
  String get screensaverSummaryFaceOn;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Face off'**
  String get screensaverSummaryFaceOff;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Proximity on'**
  String get screensaverSummaryProximityOn;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Proximity off'**
  String get screensaverSummaryProximityOff;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Person on'**
  String get screensaverSummaryPersonOn;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Person off'**
  String get screensaverSummaryPersonOff;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Widgets on'**
  String get screensaverSummaryWidgetsOn;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Widgets off'**
  String get screensaverSummaryWidgetsOff;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'At a glance on'**
  String get screensaverSummaryGlanceOn;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'At a glance off'**
  String get screensaverSummaryGlanceOff;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Now Playing on'**
  String get screensaverSummaryNowPlayingOn;

  /// Summary of an explicit schedule override.
  ///
  /// In en, this message translates to:
  /// **'Now Playing off'**
  String get screensaverSummaryNowPlayingOff;

  /// Schedule brightness summary.
  ///
  /// In en, this message translates to:
  /// **'{percent}% brightness'**
  String screensaverBrightnessPercent(String percent);

  /// Schedule screen-off summary.
  ///
  /// In en, this message translates to:
  /// **'Screen off after {minutes} min'**
  String screensaverScreenOffAfter(String minutes);

  /// Weather Mood setting, guidance or weather condition.
  ///
  /// In en, this message translates to:
  /// **'Weather Mood'**
  String get screensaverWeatherMood;

  /// Weather Mood setting, guidance or weather condition.
  ///
  /// In en, this message translates to:
  /// **'Weather Mood screensaver'**
  String get screensaverWeatherMoodPage;

  /// Weather Mood setting, guidance or weather condition.
  ///
  /// In en, this message translates to:
  /// **'Weather entity, lightning, preview'**
  String get screensaverWeatherMoodSummary;

  /// Weather Mood setting, guidance or weather condition.
  ///
  /// In en, this message translates to:
  /// **'Weather entity'**
  String get settingScreensaverWeatherEntityTitle;

  /// Weather Mood setting, guidance or weather condition.
  ///
  /// In en, this message translates to:
  /// **'The Home Assistant weather entity that controls the animated scene. Day, dawn/dusk and night follow sun.sun, with local time as a fallback.'**
  String get settingScreensaverWeatherEntityDescription;

  /// Weather Mood setting, guidance or weather condition.
  ///
  /// In en, this message translates to:
  /// **'Lightning flashes'**
  String get settingScreensaverWeatherLightningTitle;

  /// Weather Mood setting, guidance or weather condition.
  ///
  /// In en, this message translates to:
  /// **'Show lightning strikes and cloud flashes during thunderstorms.'**
  String get settingScreensaverWeatherLightningDescription;

  /// Prompt shown on a black screen until a weather entity is selected.
  ///
  /// In en, this message translates to:
  /// **'Select a weather entity in Settings > Screensaver > Weather Mood.'**
  String get screensaverWeatherMoodSelectEntity;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Weather Preview'**
  String get screensaverWeatherPreviewGroup;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Enable weather preview'**
  String get settingScreensaverWeatherPreviewTitle;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Show the selected scene instead of live weather. Turn off to follow Home Assistant again.'**
  String get settingScreensaverWeatherPreviewDescription;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Weather type'**
  String get settingScreensaverWeatherPreviewConditionTitle;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'The animated weather scene to preview.'**
  String get settingScreensaverWeatherPreviewConditionDescription;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get settingScreensaverWeatherPreviewPeriodTitle;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Choose the day, dawn/dusk or night version of the scene.'**
  String get settingScreensaverWeatherPreviewPeriodDescription;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get screensaverWeatherPreviewSunny;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get screensaverWeatherPreviewPartlycloudy;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get screensaverWeatherPreviewCloudy;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get screensaverWeatherPreviewRainy;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get screensaverWeatherPreviewPouring;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get screensaverWeatherPreviewSnowy;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Snow and rain'**
  String get screensaverWeatherPreviewSnowyRainy;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get screensaverWeatherPreviewFog;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Hail'**
  String get screensaverWeatherPreviewHail;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get screensaverWeatherPreviewLightning;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Lightning and rain'**
  String get screensaverWeatherPreviewLightningRainy;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get screensaverWeatherPreviewWindy;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Wind and clouds'**
  String get screensaverWeatherPreviewWindyVariant;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Exceptional weather'**
  String get screensaverWeatherPreviewExceptional;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get screensaverWeatherPreviewDay;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get screensaverWeatherPreviewNight;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Enable clock'**
  String get settingScreensaverWeatherClockTitle;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Show a digital clock over the weather scene.'**
  String get settingScreensaverWeatherClockDescription;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Add a drop shadow to text for readability over the weather scene.'**
  String get screensaverWeatherTextShadowDescription;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Weather information'**
  String get screensaverWeatherBarGroup;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Enable weather bar'**
  String get settingScreensaverWeatherBarTitle;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Show live weather information along the bottom of the screen.'**
  String get settingScreensaverWeatherBarDescription;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Text scale'**
  String get settingScreensaverWeatherBarScaleTitle;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Scale the weather information from 50 to 200 percent.'**
  String get settingScreensaverWeatherBarScaleDescription;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get settingScreensaverWeatherBarColorTitle;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'The color of the weather information.'**
  String get settingScreensaverWeatherBarColorDescription;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Background opacity'**
  String get settingScreensaverWeatherBarOpacityTitle;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Darken the bottom bar to keep weather information readable.'**
  String get settingScreensaverWeatherBarOpacityDescription;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Show titles'**
  String get settingScreensaverWeatherBarTitlesTitle;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Name each reading above its value. When off, values match the temperature size.'**
  String get settingScreensaverWeatherBarTitlesDescription;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Show humidity when the weather entity reports it.'**
  String get screensaverWeatherBarHumidityDescription;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Show wind speed when the weather entity reports it.'**
  String get screensaverWeatherBarWindDescription;

  /// Weather Mood clock or weather information bar control.
  ///
  /// In en, this message translates to:
  /// **'Show visibility when the weather entity reports it.'**
  String get screensaverWeatherBarVisibilityDescription;

  /// Weather Mood setting, guidance or weather condition.
  ///
  /// In en, this message translates to:
  /// **'Scene blur'**
  String get settingScreensaverWeatherBlurTitle;

  /// Weather Mood setting, guidance or weather condition.
  ///
  /// In en, this message translates to:
  /// **'Soften the animated weather scene while keeping the clock, weather bar and widgets sharp.'**
  String get settingScreensaverWeatherBlurDescription;

  /// Weather preview control, group heading or scene choice.
  ///
  /// In en, this message translates to:
  /// **'Dawn/Dusk'**
  String get screensaverWeatherPreviewTwilight;

  /// Help for the weather bar Feels like toggle. The bar shows one temperature without a separate label.
  ///
  /// In en, this message translates to:
  /// **'Show the apparent temperature instead of the actual temperature when available.'**
  String get screensaverWeatherBarFeelsLikeDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get settingScreensaverWebsiteUrlTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'A page to show full-screen. It must allow being embedded.'**
  String get settingScreensaverWebsiteUrlDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Zoom level'**
  String get settingScreensaverWebsiteZoomTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Scales the whole external screensaver webview.'**
  String get settingScreensaverWebsiteZoomDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Double tap to dismiss'**
  String get settingScreensaverWebsiteDoubleTapTitle;

  /// Help below the setting.
  ///
  /// In en, this message translates to:
  /// **'Single taps interact with the website instead of dismissing.'**
  String get settingScreensaverWebsiteDoubleTapDescription;

  /// Label, status or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Website screensaver'**
  String get screensaverWebsiteSection;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Small clock'**
  String get screensaverOverlaySmallClock;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get screensaverOverlayWeather;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get screensaverOverlayBattery;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Hidden in Digital Clock and Camera Streams screensaver modes.'**
  String get screensaverOverlayClockNote;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Hidden in the Camera Streams screensaver mode.'**
  String get screensaverOverlayCameraNote;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get screensaverOverlayScale;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Scale this widget size to better fit your screen.'**
  String get screensaverOverlayScaleHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Font family'**
  String get screensaverOverlayFont;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Corner'**
  String get screensaverOverlayCorner;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get screensaverOverlayWidget;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'24-hour clock'**
  String get screensaverOverlayClock24;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Show a 24-hour time instead of AM/PM.'**
  String get screensaverOverlayClock24Help;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Show date'**
  String get screensaverOverlayShowDate;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Add a short date under the clock.'**
  String get screensaverOverlayShowDateHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Show percentage'**
  String get screensaverOverlayPercentage;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'The charge beside the icon.'**
  String get screensaverOverlayPercentageHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Only when low'**
  String get screensaverOverlayLow;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Stay hidden until the charge drops to 20 percent.'**
  String get screensaverOverlayLowHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Show name'**
  String get screensaverOverlayShowName;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'The name under the value.'**
  String get screensaverOverlayShowNameHelp;

  /// Generic font family option. Font brand names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get screensaverOverlayFontSystem;

  /// Generic font family option. Font brand names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get screensaverOverlayFontSerif;

  /// Generic font family option. Font brand names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Condensed'**
  String get screensaverOverlayFontCondensed;

  /// Generic font family option. Font brand names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Monospace'**
  String get screensaverOverlayFontMonospace;

  /// Generic font family option. Font brand names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get screensaverOverlayFontCasual;

  /// Generic font family option. Font brand names stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cursive'**
  String get screensaverOverlayFontCursive;

  /// Text color picker label.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get screensaverOverlayColor;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Weather entity'**
  String get screensaverOverlayWeatherEntity;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'No weather entities'**
  String get screensaverOverlayNoWeather;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant reported none.'**
  String get screensaverOverlayNoWeatherHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Pick a weather entity…'**
  String get screensaverOverlayPickWeather;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Pick a weather entity.'**
  String get screensaverOverlayWeatherRequired;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Location name'**
  String get screensaverOverlayLocationName;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to hide the location line.'**
  String get screensaverOverlayLocationHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get screensaverOverlayLocation;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'The place\'s name over the temperature.'**
  String get screensaverOverlayLocationDetail;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get screensaverOverlayFeelsLike;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Show the apparent temperature on a labeled line below the actual temperature.'**
  String get screensaverOverlayFeelsLikeHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Feels like only'**
  String get screensaverOverlayFeelsLikeOnly;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Show the apparent temperature with a Feels like label instead of the actual temperature.'**
  String get screensaverOverlayFeelsLikeOnlyHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get screensaverOverlayForecast;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'The conditions, with a matching icon.'**
  String get screensaverOverlayForecastHelp;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get screensaverOverlayHumidity;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Wind speed'**
  String get screensaverOverlayWind;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get screensaverOverlayVisibility;

  /// Secondary line below the actual temperature. Includes the formatted apparent temperature and its unit.
  ///
  /// In en, this message translates to:
  /// **'Feels like {temperature}'**
  String screensaverWeatherFeelsLikeValue(String temperature);

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get settingScreensaverWidgetsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Small overlays in the corners of the screensaver.'**
  String get settingScreensaverWidgetsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Global widget scaling'**
  String get settingScreensaverWidgetScaleTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Scale all widgets together to better fit your screen size. Each widget keeps its own scale relative to the others.'**
  String get settingScreensaverWidgetScaleDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Global font family'**
  String get settingScreensaverWidgetFontTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'The typeface every widget is drawn in. A widget can pick its own.'**
  String get settingScreensaverWidgetFontDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Global font weight'**
  String get settingScreensaverWidgetFontWeightTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'How heavy every widget\'s text is drawn. Default is each line\'s own weight. A widget can pick its own.'**
  String get settingScreensaverWidgetFontWeightDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Text drop shadow'**
  String get settingScreensaverWidgetTextShadowTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Add a drop shadow to widget text for readability on photos.'**
  String get settingScreensaverWidgetTextShadowDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Vignette strength'**
  String get settingScreensaverVignetteStrengthTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Darkness of the shading behind the widgets, for readability on bright photos. 0 turns it off.'**
  String get settingScreensaverVignetteStrengthDescription;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'No widgets yet'**
  String get screensaverOverlayWidgetsEmpty;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Remove widget'**
  String get screensaverOverlayRemove;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'Add widget'**
  String get screensaverOverlayAdd;

  /// Label or guidance in this editor.
  ///
  /// In en, this message translates to:
  /// **'A small clock, the weather, the battery or an entity in a corner.'**
  String get screensaverOverlayAddHelp;

  /// Subpage navigation title or summary.
  ///
  /// In en, this message translates to:
  /// **'Corner overlays and their scale'**
  String get screensaverOverlayWidgetsHint;

  /// Placeholder in the Settings search box.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchHint;

  /// Tooltip and accessibility label for the clear button.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get settingsSearchClear;

  /// Heading above matching settings.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get settingsSearchResults;

  /// Empty result message. The query is the text entered by the user.
  ///
  /// In en, this message translates to:
  /// **'No settings match \"{query}\".'**
  String settingsSearchEmpty(String query);

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Upload a Kiosk Satellite APK through the remote admin and install it.'**
  String get searchInstallApk;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Every Android grant the app can use, with its status: microphone, camera, notifications, unrestricted battery, display over other apps, modify system settings, system UI guard, device admin, all files access, usage access and location.'**
  String get searchPermissionsHelp;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Service status'**
  String get searchServiceStatus;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Whether the Kiosk Satellite Service is running and what it is keeping alive.'**
  String get searchServiceHelp;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'The grants the Kiosk Satellite Service needs.'**
  String get searchServicePermissions;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Known kiosks and whether each can take a call.'**
  String get searchIntercomKiosks;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Check the URL and token against your Home Assistant.'**
  String get searchHaValidate;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Serve a plain-http Home Assistant through a secure proxy inside the app.'**
  String get searchHaProxy;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Pick the dashboard and view the kiosk shows.'**
  String get searchHaDashboard;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'The grants the kiosk and lockdown protections lean on.'**
  String get searchKioskPermissions;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Home screen status'**
  String get searchHomeStatus;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'Whether Kiosk Satellite is the device home screen, and where to finish setting it as the default.'**
  String get searchHomeHelp;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'The device volume the media and assistant faders scale under.'**
  String get searchMasterVolume;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'A clock widget in a corner of the screensaver.'**
  String get searchSmallClock;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'A battery widget in a corner of the screensaver: this device\'s own charge.'**
  String get searchBattery;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'The Log access grant the device\'s person sensor needs.'**
  String get searchPersonPermission;

  /// Search result title or summary for this section.
  ///
  /// In en, this message translates to:
  /// **'The Sonos speakers this device knows, a search of the network and an address field.'**
  String get searchSonosSpeakers;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Overlay skin, theme, activity bar, text size'**
  String get voiceAppearanceHint;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Skin'**
  String get voiceSkin;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'The look of the voice assistant overlay.'**
  String get voiceSkinHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get voiceTheme;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Light or dark rendering of the overlay.'**
  String get voiceThemeHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Reactive activity bar'**
  String get voiceReactive;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'The activity bar reacts to audio. NOT RECOMMENDED for low-power devices like the Echo Show.'**
  String get voiceReactiveHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Reactive bar update rate'**
  String get voiceRate;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'How often the activity bar redraws. Higher is smoother and uses more CPU.'**
  String get voiceRateHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'The size of the overlay text.'**
  String get voiceScaleHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Update the Voice Satellite integration in Home Assistant to control these settings from the kiosk.'**
  String get voiceUpdateIntegration;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Available while the kiosk is showing your Home Assistant dashboard.'**
  String get voiceDashboardRequired;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Chimes'**
  String get voiceChimesPage;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Wake, done, error, timer and announcement sounds'**
  String get voiceChimesHint;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Preview on kiosk'**
  String get voiceChimesPreview;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Could not play the sound.'**
  String get voiceChimesPreviewFailed;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Choose sounds for this kiosk. Upload custom files here. Sounds stored in Home Assistant are not used for local chimes.'**
  String get voiceChimesHelp;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Wake sound'**
  String get voiceChimeWakeTitle;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Plays when Voice Satellite starts listening.'**
  String get voiceChimeWakeDescription;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Done sound'**
  String get voiceChimeDoneTitle;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Plays when a voice interaction finishes.'**
  String get voiceChimeDoneDescription;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Error sound'**
  String get voiceChimeErrorTitle;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Plays when a voice interaction fails.'**
  String get voiceChimeErrorDescription;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Timer sound'**
  String get voiceChimeTimerTitle;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Repeats when a timer finishes until you dismiss it.'**
  String get voiceChimeTimerDescription;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Announcement sound'**
  String get voiceChimeAnnounceTitle;

  /// Chime selection, playback or help shown on the device and in Remote Admin.
  ///
  /// In en, this message translates to:
  /// **'Plays before a Voice Satellite announcement unless it supplies its own sound.'**
  String get voiceChimeAnnounceDescription;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get voiceEngine;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Start or Stop the Voice Satellite engine.'**
  String get voiceEngineHelp;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Assigned satellite'**
  String get voiceAssigned;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'The assist_satellite entity this kiosk identifies as in Home Assistant. Changing it reloads the dashboard.'**
  String get voiceAssignedHelp;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'The assist_satellite entity this kiosk identifies as in Home Assistant.'**
  String get voiceAssignedSearch;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'None assigned'**
  String get voiceNoneAssigned;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Auto start'**
  String get voiceAutoStart;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Auto start Voice Satellite on dashboard load.'**
  String get voiceAutoStartHelp;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Stop listening for wake words.'**
  String get voiceMuteHelp;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Assist pipeline 1'**
  String get voicePipeline1;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'The Assist pipeline voice commands run through.'**
  String get voicePipeline1Help;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Assist pipeline 2'**
  String get voicePipeline2;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'The pipeline used when the second wake word triggers.'**
  String get voicePipeline2Help;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Finished speaking detection'**
  String get voiceVad;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'How long a pause ends a voice command.'**
  String get voiceVadHelp;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Disable muted microphone warning'**
  String get voiceMutedWarning;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Hide the muted microphone warning at startup and whenever the satellite microphone is muted.'**
  String get voiceMutedWarningHelp;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Debug logging'**
  String get voiceDebug;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Show Voice Satellite debug info in the browser console.'**
  String get voiceDebugHelp;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Voice Satellite version'**
  String get voiceVersion;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'The integration version installed in Home Assistant.'**
  String get voiceVersionHelp;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get voiceVadDefault;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get voiceVadRelaxed;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get voiceVadAggressive;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get voiceGeneral;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get voiceStart;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get voiceNotavailable;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get voiceDisabled;

  /// Background listening setting on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Keep listening in the background'**
  String get settingWakeWordBackgroundTitle;

  /// Background listening setting on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Keep hearing the wake word while another app is in front, and return on a detection. Needs a permanent notification and display over other apps.'**
  String get settingWakeWordBackgroundDescription;

  /// Return to the previous app after a background voice interaction. Only shown while background listening is enabled.
  ///
  /// In en, this message translates to:
  /// **'Return to the previous app'**
  String get settingWakeWordReturnToBackgroundTitle;

  /// Return to the previous app after a background voice interaction. Only shown while background listening is enabled.
  ///
  /// In en, this message translates to:
  /// **'Return to the previous app or home screen after a voice interaction brings Kiosk Satellite forward and finishes.'**
  String get settingWakeWordReturnToBackgroundDescription;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Wake word detection can hear you.'**
  String get voiceMicHeld;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Blocked. Android will not ask again, so allow it in the app settings.'**
  String get voiceMicBlocked;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Without this nothing is listening for the wake word.'**
  String get voiceMicMissing;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Satellite can come forward when it hears you.'**
  String get voiceForegroundHeld;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Without this the wake word is heard and nothing happens.'**
  String get voiceForegroundMissing;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'The ongoing notification that enables background listening.'**
  String get voiceNotificationHeld;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Needed for background listening to work reliably.'**
  String get voiceNotificationMissing;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Android will leave the listener running.'**
  String get voiceBatteryHeld;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Without this the listener is stopped after a few hours.'**
  String get voiceBatteryMissing;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Grant these on the device itself: swipe in from the left edge → Settings → Voice Satellite → Required system permissions.'**
  String get voicePermissionDirections;

  /// Search-result description for the permission group.
  ///
  /// In en, this message translates to:
  /// **'Microphone and the other grants wake word detection needs.'**
  String get voicePermissionsSearch;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant not connected'**
  String get voiceDisconnected;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Validate the connection under Home Assistant Setup first.'**
  String get voiceValidate;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Checking for Voice Satellite…'**
  String get voiceChecking;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Voice Satellite is not installed in Home Assistant'**
  String get voiceMissing;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Voice Satellite turns this kiosk into a full hands-free voice assistant for Home Assistant: wake word detection, conversations, timers and announcements, right on the dashboard.\n\nIt is available in the default HACS repository. Install it on your Home Assistant instance, then come back here.'**
  String get voiceInstallHelp;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Learn more about '**
  String get voiceLearnMore;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Voice Satellite on Github'**
  String get voiceGithub;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Open HACS repository'**
  String get voiceHacs;

  /// Label or help shown on the Voice Satellite main page.
  ///
  /// In en, this message translates to:
  /// **'Loading Voice Satellite controls…'**
  String get voiceLoading;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake Word Tester'**
  String get voiceTester;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Watch what the engine hears and scores in real time, to see why the wake word is or is not triggering.'**
  String get voiceTesterHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'A live look at what the engine hears and scores.'**
  String get voiceTesterSearch;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Voice Satellite'**
  String get voiceTesterWaiting;

  /// Marks a spoken word as the stop word in the model picker. Keep {word} unchanged.
  ///
  /// In en, this message translates to:
  /// **'{word} (stop word)'**
  String voiceStopWordNamed(String word);

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get voiceScore;

  /// The score needed to trigger detection. Shown in the chart legend.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get voiceThreshold;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Hits'**
  String get voiceHits;

  /// Count of samples close to triggering that did not become detections.
  ///
  /// In en, this message translates to:
  /// **'Near misses'**
  String get voiceNearMisses;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get voicePeak;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Mic level'**
  String get voiceMicLevel;

  /// Time to process an audio chunk, summarized as minimum, average and maximum. Keep the three values in that order.
  ///
  /// In en, this message translates to:
  /// **'Chunk processing (min / avg / max)'**
  String get voiceChunkProcessing;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get voiceLog;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Detections and near misses will appear here.'**
  String get voiceLogEmpty;

  /// Log marker for a successful detection. May be uppercase in the translation.
  ///
  /// In en, this message translates to:
  /// **'HIT'**
  String get voiceLogHit;

  /// Short log marker for a near miss: the model heard something but did not trigger.
  ///
  /// In en, this message translates to:
  /// **'near'**
  String get voiceLogNear;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'score'**
  String get voiceLogScore;

  /// Label before the phonemes decoded by the model. The phonemes themselves must stay unchanged.
  ///
  /// In en, this message translates to:
  /// **'decoded'**
  String get voiceLogDecoded;

  /// Short label before the edit distance between decoded phonemes and the target word. This is a diagnostic label, not a language code.
  ///
  /// In en, this message translates to:
  /// **'ed'**
  String get voiceLogDistance;

  /// Short label before a matched-confidence measurement in the diagnostic log.
  ///
  /// In en, this message translates to:
  /// **'conf'**
  String get voiceLogConfidence;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Play last 10 seconds'**
  String get voiceTesterPlayRecent;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake Word'**
  String get voiceWakePage;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Engine, wake words, sensitivity, cached models'**
  String get voiceWakeHint;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word'**
  String get voiceWakeLabel;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word engine'**
  String get voiceWakeEngine;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Where detection runs and which engine listens.'**
  String get voiceWakeEngineHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word 1'**
  String get voiceWake1;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'The word that starts a voice command.'**
  String get voiceWake1Help;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word 2'**
  String get voiceWake2;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'A second wake word, answered by Assist pipeline 2.'**
  String get voiceWake2Help;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word sensitivity'**
  String get voiceSensitivity;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'How easily the wake word triggers.'**
  String get voiceSensitivityHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word noise gate'**
  String get voiceNoiseGate;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Skip local wake word inference while the room is quiet, saving CPU.'**
  String get voiceNoiseGateHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Stop word interruption'**
  String get voiceStopInterruption;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Say the stop word to interrupt responses.'**
  String get voiceStopInterruptionHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Assign a satellite to control these settings.'**
  String get voiceAssignFirst;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cached models'**
  String get voiceCachedModels;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Re-download from Home Assistant. Use after re-publishing a model.'**
  String get voiceCachedModelsHelp;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get voiceClearCache;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Clearing…'**
  String get voiceClearing;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Files cleared: {count}. Downloading again.'**
  String voiceCacheCleared(String count);

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count}'**
  String voiceCacheCount(String count);

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Very sensitive'**
  String get voiceVerySensitive;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Prefer fp32 vsWakeWord models'**
  String get voiceWakeWordPreferFp32Title;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Uses fp32 models instead of smaller int8 versions. Adds 10-30% more CPU usage while listening to avoid about 2% confidence drift.'**
  String get voiceWakeWordPreferFp32Description;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Resume timeout (seconds)'**
  String get voiceWakeWordResumeTimeoutSecondsTitle;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Self-heal: resume listening if the page never calls setWakeWordActive(true) after a handoff. Waits while a voice turn is still streaming audio, so a long turn is never cut short.'**
  String get voiceWakeWordResumeTimeoutSecondsDescription;

  /// Built-in option label. Keep engine names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Slightly sensitive'**
  String get voiceSlightlySensitive;

  /// Built-in option label. Keep engine names unchanged.
  ///
  /// In en, this message translates to:
  /// **'Moderately sensitive'**
  String get voiceModeratelySensitive;

  /// Built-in option label. Keep engine names unchanged.
  ///
  /// In en, this message translates to:
  /// **'On Device'**
  String get voiceOnDevice;

  /// Built-in option label. Keep engine names unchanged.
  ///
  /// In en, this message translates to:
  /// **'On device ({engine})'**
  String voiceOnDeviceEngine(String engine);

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Wake word diagnostics'**
  String get voiceDiagnosticsPage;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Recent activations and near misses with audio clips'**
  String get voiceDiagnosticsHint;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Enable wake word diagnostics'**
  String get voiceDiagnosticsTitle;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Records the last 10 wake word activations and near misses with their scores and a 3 second audio clip of each. Turning this off deletes them.'**
  String get voiceDiagnosticsDescription;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'No wake word activations recorded yet.'**
  String get voiceDiagnosticsEmpty;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Activations'**
  String get voiceDiagnosticsActivations;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'No near misses recorded yet.'**
  String get voiceDiagnosticsNoNearMisses;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Peak level'**
  String get voiceDiagnosticsPeakLevel;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Average level'**
  String get voiceDiagnosticsAverageLevel;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Clipped'**
  String get voiceDiagnosticsClipped;

  /// Translate the visible label or help. Keep model names and technical identifiers unchanged.
  ///
  /// In en, this message translates to:
  /// **'Heard'**
  String get voiceDiagnosticsHeard;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable cache'**
  String get settingDisableCacheTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Always fetch from the network and drop cached page data on load, so a redeployed dashboard always comes back fresh. Slow; treat it as a development aid.'**
  String get settingDisableCacheDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Allow mixed content'**
  String get settingAllowMixedContentTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Let HTTPS pages load insecure HTTP resources. Helps when Home Assistant mixes http:// content into an https:// dashboard.'**
  String get settingAllowMixedContentDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Ignore SSL errors'**
  String get settingIgnoreSslErrorsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Accept untrusted or self-signed certificates. Use only on your own network, since it disables certificate verification.'**
  String get settingIgnoreSslErrorsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Auto-reload on error'**
  String get settingAutoReloadOnErrorTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Recover automatically from page failures and app crashes.'**
  String get settingAutoReloadOnErrorDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable pull to refresh'**
  String get settingPullToRefreshTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Drag down from the top of the page to reload it. Off by default: on a scrolling dashboard an accidental pull is easy.'**
  String get settingPullToRefreshDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Clear cache when pulling to refresh'**
  String get settingPullToRefreshClearCacheTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'A pull also clears the web cache and wake word models before reloading, so everything comes back fresh. Login and saved page data are kept.'**
  String get settingPullToRefreshClearCacheDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Zoom level'**
  String get settingBrowserZoomTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Scales the whole page. Above 1x for wall tablets viewed from a distance; below 1x fits more dashboard on a small screen.'**
  String get settingBrowserZoomDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Enable pinch to zoom'**
  String get settingPinchToZoomTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Zoom the page with a two-finger pinch. Off by default so a kiosk dashboard stays put under stray touches.'**
  String get settingPinchToZoomDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Disable scrolling'**
  String get settingDisableScrollingTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Lock the page in place so it cannot be scrolled in any direction. Taps and buttons keep working.'**
  String get settingDisableScrollingDescription;

  /// Warning when the permission is missing.
  ///
  /// In en, this message translates to:
  /// **'Without this the kiosk cannot come back after a crash.'**
  String get browserCrashPermissionHelp;

  /// Remote crash recovery permission notice.
  ///
  /// In en, this message translates to:
  /// **'\"Display over other apps\" permission missing'**
  String get browserCrashPermissionMissing;

  /// Remote crash recovery permission notice.
  ///
  /// In en, this message translates to:
  /// **'Without it the kiosk cannot bring itself back after a crash. The grant screen appears on the tablet.'**
  String get browserCrashPermissionRemoteHelp;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Inject JavaScript on the HA dashboard'**
  String get settingBrowserInjectJsTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Run this JavaScript code after every load of the dashboard page. Useful to hide distracting elements or tweak a dashboard you do not control.'**
  String get settingBrowserInjectJsDescription;

  /// Setting label.
  ///
  /// In en, this message translates to:
  /// **'Inject JavaScript on external pages'**
  String get settingBrowserInjectJsExternalTitle;

  /// Help below this setting.
  ///
  /// In en, this message translates to:
  /// **'Run this JavaScript code after loading each external page: pages opened by a dashboard link, dashboard rotation pages and the website screensaver. The Music Assistant page is left alone.'**
  String get settingBrowserInjectJsExternalDescription;

  /// Example code shown in the empty editor.
  ///
  /// In en, this message translates to:
  /// **'// Example: hide a distracting element\ndocument.querySelector(\'#banner\').style.display = \'none\';'**
  String get browserInjectJsPlaceholder;

  /// Example code shown in the empty editor.
  ///
  /// In en, this message translates to:
  /// **'// Example: zoom a site that ignores the dashboard zoom level\ndocument.documentElement.style.zoom = \'1.25\';'**
  String get browserInjectJsExternalPlaceholder;

  /// Page heading.
  ///
  /// In en, this message translates to:
  /// **'Connect to Home Assistant'**
  String get setupConnectHeading;

  /// Introduction explaining the required credentials.
  ///
  /// In en, this message translates to:
  /// **'The base URL of your instance and a long-lived access token, created under your HA profile → Security → Long-lived access tokens.'**
  String get setupConnectLead;

  /// Home Assistant address field label.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant base URL'**
  String get setupBaseUrl;

  /// Access token field label.
  ///
  /// In en, this message translates to:
  /// **'Long-lived access token'**
  String get setupToken;

  /// Button to scan connection details from a QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code'**
  String get setupScanQr;

  /// Error heading when Home Assistant rejects the token.
  ///
  /// In en, this message translates to:
  /// **'Invalid access token'**
  String get setupInvalidToken;

  /// Instructions for replacing a rejected token.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant rejected this token. In Home Assistant, open your profile → Security → Long-lived access tokens, create a new token and copy the complete value.'**
  String get setupInvalidTokenHelp;

  /// Error heading when the server does not respond.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Home Assistant'**
  String get setupUnreachable;

  /// Troubleshooting advice for an unreachable server.
  ///
  /// In en, this message translates to:
  /// **'No response from this address. Check that the URL is correct and that this device is on the same network as your Home Assistant server.'**
  String get setupUnreachableHelp;

  /// Help when the address responds as a different service.
  ///
  /// In en, this message translates to:
  /// **'A server responded, but it doesn\'t appear to be Home Assistant. Check that the URL is your Home Assistant base address, for example https://homeassistant.local:8123.'**
  String get setupUnexpectedResponseHelp;

  /// Heading for other connection errors.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect'**
  String get setupCannotConnect;

  /// Error heading when QR scanning needs camera permission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission needed'**
  String get setupCameraPermission;

  /// Instructions when camera access must be enabled in Android.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera for Kiosk Satellite in the Android settings to scan the QR code.'**
  String get setupCameraBlocked;

  /// Instructions when camera access can be requested in the app.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera to scan the QR code.'**
  String get setupCameraAllow;

  /// Error heading when the address field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your Home Assistant base URL'**
  String get setupEnterBaseUrl;

  /// Error heading when the address format is invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid base URL'**
  String get setupInvalidBaseUrl;

  /// Example explaining the expected address.
  ///
  /// In en, this message translates to:
  /// **'This is the address you use to open Home Assistant, for example https://homeassistant.local:8123.'**
  String get setupBaseUrlHelp;

  /// Error heading when the access token field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a long-lived access token'**
  String get setupEnterToken;

  /// Instructions for creating an access token.
  ///
  /// In en, this message translates to:
  /// **'In Home Assistant, open your profile → Security → Long-lived access tokens to create one.'**
  String get setupEnterTokenHelp;

  /// Button to test credentials and advance.
  ///
  /// In en, this message translates to:
  /// **'Validate & continue'**
  String get setupValidateContinue;

  /// Error heading for an unexpected server response.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response ({error})'**
  String setupUnexpectedResponse(String error);

  /// Validation error for a malformed address.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL, for example https://homeassistant.local:8123'**
  String get baseUrlInvalid;

  /// Validation error for an address containing a dashboard path.
  ///
  /// In en, this message translates to:
  /// **'Enter only the base URL, without a dashboard path. Example: https://homeassistant.local:8123'**
  String get baseUrlPath;

  /// Validation error for an address containing a query or fragment.
  ///
  /// In en, this message translates to:
  /// **'Enter only the base URL, without anything after the port. Example: https://homeassistant.local:8123'**
  String get baseUrlQuery;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Choose a dashboard'**
  String get setupChooseDashboard;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'This is what the kiosk will show when it starts.'**
  String get setupDashboardHelp;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Select a dashboard'**
  String get setupSelectDashboard;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Choose the dashboard the kiosk will display. You can change it later in Settings.'**
  String get setupSelectDashboardHelp;

  /// Welcome step label.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get setupWelcome;

  /// Home Assistant connection step label.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get setupConnect;

  /// Summary below the connection step label.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant URL & token'**
  String get setupConnectSummary;

  /// Dashboard step label.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get setupDashboard;

  /// Summary below the dashboard step label.
  ///
  /// In en, this message translates to:
  /// **'What the kiosk shows'**
  String get setupDashboardSummary;

  /// Summary below the recommended settings step.
  ///
  /// In en, this message translates to:
  /// **'Recommended settings'**
  String get setupRecommendedSummary;

  /// Permissions step label and page heading.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get setupPermissions;

  /// Summary below the permissions step label.
  ///
  /// In en, this message translates to:
  /// **'What the setup needs'**
  String get setupPermissionsSummary;

  /// Introduction above the permission list on the device.
  ///
  /// In en, this message translates to:
  /// **'Android will ask for these permissions. Everything is requested up front so the kiosk never interrupts you later.'**
  String get setupPermissionLead;

  /// Introduction directing the remote user to the physical device.
  ///
  /// In en, this message translates to:
  /// **'Android asks for these on the tablet itself. Walk over and accept the prompts, then finish here.'**
  String get setupRemotePermissionLead;

  /// Explanation below Microphone. Keep Voice Satellite unchanged.
  ///
  /// In en, this message translates to:
  /// **'Voice Satellite and the intercom need microphone access'**
  String get setupMicrophoneHelp;

  /// Notifications explanation when background listening is selected.
  ///
  /// In en, this message translates to:
  /// **'Allows the Kiosk Satellite Service\'s ongoing notification, which says what it is keeping alive and when the kiosk is listening.'**
  String get setupNotificationListening;

  /// Explanation below Unrestricted battery.
  ///
  /// In en, this message translates to:
  /// **'Allows the Kiosk Satellite Service to run in the background without being paused or killed.'**
  String get setupBatteryService;

  /// Overlay explanation when starting at boot is selected.
  ///
  /// In en, this message translates to:
  /// **'Lets Kiosk Satellite come back after a crash and start when your device boots.'**
  String get setupOverlayBoot;

  /// Overlay explanation when starting at boot is not selected.
  ///
  /// In en, this message translates to:
  /// **'Lets Kiosk Satellite come back on screen after a crash.'**
  String get setupOverlayCrash;

  /// Explanation of Android permission to change screen brightness.
  ///
  /// In en, this message translates to:
  /// **'Allows Kiosk Satellite to set the panel\'s actual brightness (modify system settings).'**
  String get setupBrightnessHelp;

  /// Permission row title for turning the screen off.
  ///
  /// In en, this message translates to:
  /// **'Screen control'**
  String get setupScreenControl;

  /// Explanation of Android device admin permission.
  ///
  /// In en, this message translates to:
  /// **'Allows Kiosk Satellite to turn the screen off on request (device admin).'**
  String get setupScreenControlHelp;

  /// Button that opens permission prompts on the physical device.
  ///
  /// In en, this message translates to:
  /// **'Grant permissions on the device'**
  String get setupGrantPermissions;

  /// Disabled button label while permission prompts are being requested.
  ///
  /// In en, this message translates to:
  /// **'Requesting on the device…'**
  String get setupRequestingPermissions;

  /// Disabled button label after sending permission requests.
  ///
  /// In en, this message translates to:
  /// **'Permissions requested on the device'**
  String get setupPermissionsRequested;

  /// Button that switches between the front and back cameras.
  ///
  /// In en, this message translates to:
  /// **'Flip camera'**
  String get setupQrFlipCamera;

  /// Shown when the scanner cannot start its camera.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be started.'**
  String get setupQrCameraFailed;

  /// Scanner heading. Keep QR unchanged.
  ///
  /// In en, this message translates to:
  /// **'Scan the token QR code'**
  String get setupQrTitle;

  /// Explains where to find the QR code. Keep Home Assistant unchanged.
  ///
  /// In en, this message translates to:
  /// **'It appears next to a newly created token in your Home Assistant profile.'**
  String get setupQrHelp;

  /// Flashlight button label when the light is on.
  ///
  /// In en, this message translates to:
  /// **'Turn off the flashlight'**
  String get setupQrFlashOff;

  /// Flashlight button label when the light is off.
  ///
  /// In en, this message translates to:
  /// **'Turn on the flashlight'**
  String get setupQrFlashOn;

  /// Error heading when importing before setting an admin password.
  ///
  /// In en, this message translates to:
  /// **'Set the admin password first'**
  String get setupPasswordFirst;

  /// Recovery instructions referring to the password field above Restore backup.
  ///
  /// In en, this message translates to:
  /// **'Type an admin password above (at least 4 characters), then import the backup.'**
  String get setupPasswordBeforeImport;

  /// Error heading when saving the remote admin password fails.
  ///
  /// In en, this message translates to:
  /// **'Could not set the password'**
  String get setupPasswordFailed;

  /// Error heading when another session has already set the password.
  ///
  /// In en, this message translates to:
  /// **'A password is already set'**
  String get setupPasswordExists;

  /// Explains the automatic reload to login after a password was set elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Log in with the password set on the tablet to continue here. Reloading…'**
  String get setupPasswordExistsHelp;

  /// Error heading for a file that cannot be read as a backup.
  ///
  /// In en, this message translates to:
  /// **'Not a backup file'**
  String get setupNotBackup;

  /// Recovery instructions after JSON decoding fails. Keep JSON unchanged.
  ///
  /// In en, this message translates to:
  /// **'That file is not valid JSON. Export a configuration from Settings on a set-up Kiosk Satellite, or from its remote admin.'**
  String get setupInvalidBackupHelp;

  /// Recovery instructions when the remote user selects the wrong file format.
  ///
  /// In en, this message translates to:
  /// **'Export a configuration from the Settings tab of a set-up Kiosk Satellite.'**
  String get setupWrongBackupKind;

  /// Fallback explanation when the import fails without a specific error.
  ///
  /// In en, this message translates to:
  /// **'The file could not be applied.'**
  String get setupImportFailedHelp;

  /// Notice heading after applying a backup with no dashboard URL.
  ///
  /// In en, this message translates to:
  /// **'Backup has no dashboard'**
  String get setupBackupNoDashboard;

  /// Explains that settings were imported but setup must continue.
  ///
  /// In en, this message translates to:
  /// **'The settings were applied, but this backup was taken before its device was set up, so there is no dashboard to show. Continue the wizard to pick one.'**
  String get setupBackupNoDashboardHelp;

  /// Temporary Import button label during an upload.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get setupImporting;

  /// Description beside the backup import action.
  ///
  /// In en, this message translates to:
  /// **'Import a configuration exported from Kiosk Satellite and skip the rest of this wizard.'**
  String get setupRemoteRestoreHelp;

  /// Waiting-screen heading after a successful remote import.
  ///
  /// In en, this message translates to:
  /// **'Finish on the device'**
  String get setupFinishOnDevice;

  /// Waiting-screen instructions while Android permission prompts are open.
  ///
  /// In en, this message translates to:
  /// **'The configuration was imported. Answer the permission prompts on the tablet\'s screen - this page continues automatically when the dashboard loads.'**
  String get setupFinishOnDeviceHelp;

  /// Validation error for JSON that does not contain an object.
  ///
  /// In en, this message translates to:
  /// **'The backup must contain a JSON object.'**
  String get setupBackupObject;

  /// Validation error for a file from another application.
  ///
  /// In en, this message translates to:
  /// **'This is not a Kiosk Satellite configuration file.'**
  String get setupBackupKind;

  /// Validation error for a backup with no settings.
  ///
  /// In en, this message translates to:
  /// **'The backup contains no settings.'**
  String get setupBackupSettings;

  /// Introduction to the optional permissions that keep the service running.
  ///
  /// In en, this message translates to:
  /// **'Keeps the app alive while the screen is off or another app is in front, so the Home Assistant connection and other features like motion detection and the Bluetooth proxy stay alive. The permissions below are optional but recommended: each one helps it survive the screen being off.'**
  String get setupServiceHelp;

  /// Battery permission warning when a feature needs the missing permission.
  ///
  /// In en, this message translates to:
  /// **'Android may pause the app when the screen is off, dropping the Home Assistant connection with it.'**
  String get setupBatteryMissing;

  /// Overlay permission warning when crash recovery needs the missing permission.
  ///
  /// In en, this message translates to:
  /// **'Without this the service cannot relaunch the kiosk after a crash.'**
  String get setupOverlayMissing;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Voice Satellite detected'**
  String get setupVoiceDetected;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'This Home Assistant instance runs the Voice Satellite integration. Choose which satellite this kiosk is, then review its settings. Everything can be changed later.'**
  String get setupVoiceHelp;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'No satellites found'**
  String get setupNoSatellites;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Add an assist satellite in the Voice Satellite integration, or continue without one and pick it on the dashboard later.'**
  String get setupNoSatellitesHelp;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'If this is a new device, create a new satellite entity in Home Assistant first. Settings → Devices & Services → Voice Satellite → Add Entry. IMPORTANT: Two devices cannot share the same entity.'**
  String get setupNewSatelliteHelp;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Apply all recommended settings'**
  String get setupApplyRecommended;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'The optimal settings for full Voice Satellite integration and functionality.'**
  String get setupRecommendedHelp;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Required by Voice Satellite'**
  String get setupVoiceRequired;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Microphone access'**
  String get setupMicrophoneAccess;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Native wake word detection'**
  String get setupNativeWakeWord;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get setupPullRefresh;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Autoplay audio and video'**
  String get setupAutoplay;

  /// Translate the setup instruction or control label.
  ///
  /// In en, this message translates to:
  /// **'Not installed, skipped'**
  String get setupVoiceSkipped;

  /// Remote administration section heading and step summary.
  ///
  /// In en, this message translates to:
  /// **'Remote administration'**
  String get setupRemoteHeading;

  /// Setup heading on the device.
  ///
  /// In en, this message translates to:
  /// **'Set up\nKiosk Satellite'**
  String get setupTitle;

  /// Introduction on the device.
  ///
  /// In en, this message translates to:
  /// **'Turn this tablet into a Home Assistant kiosk. Setup takes a couple of minutes and this wizard walks you through it.'**
  String get setupWelcomeLead;

  /// Device name field label on the device.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get setupDeviceName;

  /// Help below the device name field.
  ///
  /// In en, this message translates to:
  /// **'How this kiosk is called in Home Assistant, in the remote admin and on the network. Change it any time under Settings, Device.'**
  String get setupDeviceNameHelp;

  /// Remote administration switch label on the device.
  ///
  /// In en, this message translates to:
  /// **'Enable remote administration'**
  String get setupEnableRemote;

  /// Help below the remote administration switch.
  ///
  /// In en, this message translates to:
  /// **'Keep managing this kiosk from a web browser after setup, where pasting the Home Assistant access token is much easier.'**
  String get setupEnableRemoteHelp;

  /// Remote password field label on the device.
  ///
  /// In en, this message translates to:
  /// **'Remote admin password'**
  String get setupRemotePassword;

  /// Configuration restore section heading.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get setupRestoreHeading;

  /// Action to select a configuration file.
  ///
  /// In en, this message translates to:
  /// **'Restore from configuration file'**
  String get setupRestore;

  /// Explanation of what restoring a configuration imports.
  ///
  /// In en, this message translates to:
  /// **'Import a configuration exported from Kiosk Satellite and skip the rest of this wizard. Settings, dashboard and login all come along.'**
  String get setupRestoreHelp;

  /// Heading above the recommended service permissions.
  ///
  /// In en, this message translates to:
  /// **'Recommended Service Permissions'**
  String get setupServicePermissions;

  /// Error heading for a password below the minimum length.
  ///
  /// In en, this message translates to:
  /// **'Password too short'**
  String get setupPasswordShort;

  /// Password length requirement below the error heading.
  ///
  /// In en, this message translates to:
  /// **'Use at least 4 characters.'**
  String get setupPasswordMinimum;

  /// Instructions for continuing setup in a browser.
  ///
  /// In en, this message translates to:
  /// **'You can continue this setup remotely from a web browser at {address}, whether the switch above is on or not.'**
  String setupRemoteAddress(String address);

  /// Welcome heading in the browser.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kiosk Satellite'**
  String get remoteWelcomeTitle;

  /// Browser introduction when no admin password is set.
  ///
  /// In en, this message translates to:
  /// **'This tablet is waiting to be set up. First, protect this remote admin with a password.'**
  String get remoteWelcomePassword;

  /// Browser introduction when an admin password is already set.
  ///
  /// In en, this message translates to:
  /// **'This tablet is waiting to be set up. The remote admin password is already set; type a new one here to change it.'**
  String get remoteWelcomeReady;

  /// Browser password field label for a new password.
  ///
  /// In en, this message translates to:
  /// **'Admin password (min 4 characters)'**
  String get remoteInitialPassword;

  /// Browser password field label for an optional replacement.
  ///
  /// In en, this message translates to:
  /// **'New admin password (leave empty to keep the current one)'**
  String get remoteNewPassword;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Built-in ring'**
  String get intercomBuiltinRing;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Built-in chime'**
  String get intercomBuiltinChime;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'{file} (missing)'**
  String intercomMissingFile(String file);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Add a sound'**
  String get intercomAddSound;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Copy a sound file from this device into the sounds folder.'**
  String get intercomCopySoundHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Upload a sound file from this computer into the sounds folder.'**
  String get intercomUploadSoundHelp;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get intercomUpload;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get intercomUploading;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not a supported sound'**
  String get intercomUnsupportedSound;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not a supported sound: pick an MP3, OGG, WAV, FLAC, M4A or AAC file.'**
  String get intercomChooseSound;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the file'**
  String get intercomCopyFailed;

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String intercomUploadFailed(String error);

  /// Label or guidance in this section.
  ///
  /// In en, this message translates to:
  /// **'Not saved: {error}'**
  String intercomSaveFailed(String error);

  /// Action or validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter a file name, not a path.'**
  String get intercomSoundFilename;

  /// Action or validation message.
  ///
  /// In en, this message translates to:
  /// **'Pick an MP3, OGG, WAV, FLAC, M4A or AAC file.'**
  String get intercomSoundFormats;

  /// Label for a timer that has no custom name.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get voiceTimerDefaultName;

  /// Tooltip on the handle that moves all timer pills together.
  ///
  /// In en, this message translates to:
  /// **'Drag to move timers'**
  String get voiceTimerDrag;

  /// Tooltip for a running countdown. One tap pauses it, two taps cancel it and dragging moves the group.
  ///
  /// In en, this message translates to:
  /// **'Tap to pause. Double tap to cancel. Drag to move.'**
  String get voiceTimerPauseHint;

  /// Tooltip for a paused countdown. One tap resumes it, two taps cancel it and dragging moves the group.
  ///
  /// In en, this message translates to:
  /// **'Tap to resume. Double tap to cancel. Drag to move.'**
  String get voiceTimerResumeHint;

  /// Accessible action that cancels a timer.
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get voiceTimerCancel;

  /// Error shown when pausing, resuming or canceling a timer fails.
  ///
  /// In en, this message translates to:
  /// **'Could not change the timer. Check the connection and update Voice Satellite if needed.'**
  String get voiceTimerActionError;

  /// Status shown in place of the countdown after a timer finishes.
  ///
  /// In en, this message translates to:
  /// **'Timer finished'**
  String get voiceTimerFinished;

  /// Tooltip for a finished timer. Tapping stops the local alert sound and dismisses its pills.
  ///
  /// In en, this message translates to:
  /// **'Tap to dismiss the timer alert.'**
  String get voiceTimerDismissHint;
}

class _UiStringsDelegate extends LocalizationsDelegate<UiStrings> {
  const _UiStringsDelegate();

  @override
  Future<UiStrings> load(Locale locale) {
    return SynchronousFuture<UiStrings>(lookupUiStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_UiStringsDelegate old) => false;
}

UiStrings lookupUiStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return UiStringsDe();
    case 'en':
      return UiStringsEn();
    case 'es':
      return UiStringsEs();
    case 'fr':
      return UiStringsFr();
    case 'uk':
      return UiStringsUk();
  }

  throw FlutterError(
    'UiStrings.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
