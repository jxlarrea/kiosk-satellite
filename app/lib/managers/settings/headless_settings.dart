import 'dart:async';

import '../../core/event_bus.dart';
import '../../core/events.dart';
import '../../core/headless.dart';
import '../../core/logging.dart';
import 'definitions.dart' as defs;
import 'settings_manager.dart';

/// The settings side of a device without a screen (core/headless.dart).
///
/// Everything that draws, watches a camera or manages what is on screen is
/// left out of both settings UIs through [defs.deviceHiddenKeys], the same
/// way a person sensor's page is left off devices without one. A few
/// settings are pinned rather than only hidden, because a stored value
/// would start real work on a device that cannot use it (the camera, a
/// lockdown overlay, the home role) or because the device would lose its
/// only way in (the remote admin). Pinned values are corrected at boot,
/// so a configuration imported from a kiosk with a screen lands cleanly,
/// and again on any later change, whichever surface or Fleet sync made it.
class HeadlessSettings {
  HeadlessSettings(this._settings, this._bus, this._log);

  final SettingsManager _settings;
  final EventBus _bus;
  final Logger _log;
  StreamSubscription<SettingChanged>? _sub;

  /// Whole pages with nothing that works without a screen.
  static const _hiddenCategories = {
    // No screen to swipe across or menu to open.
    'Navigation',
    'Browser',
    'Web Content',
    'Screensaver',
    'Camera',
    'Cameras',
    'Kiosk',
    'Lockdown',
    'Home',
    'Launcher',
    'Calendar',
  };

  /// Single settings on pages that otherwise stay.
  static final _hiddenKeys = {
    // Home Assistant: everything but the connection drives the dashboard.
    defs.haAutoLogin.key,
    // Device: the on-device interface and the WebView renderer.
    defs.uiTheme.key,
    defs.uiScale.key,
    defs.uiToastsHidden.key,
    // No drawer menu: there is no screen to swipe it in on.
    defs.uiDrawerItems.key,
    defs.disableImpeller.key,
    defs.legacyWebView.key,
    defs.remoteEnabled.key,
    // Ground Control: Vision Match works on the camera's frames.
    defs.visionMatchEnabled.key,
    defs.visionMatchFaceDetection.key,
    defs.visionMatchPresenceSensors.key,
    defs.visionMatchFaceRecognition.key,
    defs.visionMatchFaceConfirmsVoice.key,
    defs.visionMatchLinkFaceWho.key,
    defs.visionMatchLinkScreensaverLock.key,
    defs.visionMatchShowArrivals.key,
    defs.visionMatchShowActions.key,
    defs.visionMatchCardPosition.key,
    defs.visionMatchLinkKioskPin.key,
    defs.visionMatchLinkLockdownDisable.key,
    defs.visionMatchLinkLockdownRelock.key,
    defs.visionMatchLinkGestureWho.key,
    defs.visionMatchLinkCalendarFocus.key,
    defs.visionMatchHandGestures.key,
    // Voice: listening never leaves the foreground, there is none.
    defs.wakeWordBackground.key,
    defs.wakeWordReturnToBackground.key,
    // Timers: no Timers view to open or screensaver to hold.
    defs.timersShowOnStart.key,
    defs.timersShowBeforeEnd.key,
    defs.timersPauseScreensaver.key,
    defs.timersViewScale.key,
    // Intercom: no talk button, and the buttons are gestures.
    defs.intercomTalkMode.key,
    defs.intercomHangupKey.key,
    defs.intercomHangupKeyRinging.key,
    defs.intercomVideo.key,
    defs.intercomAutoAnswerCamera.key,
    defs.intercomVideoQuality.key,
    // Alarms: no panel to light, and no screensaver to skip from.
    defs.alarmsSunriseMinutes.key,
    defs.alarmsSkipMinutes.key,
    // Gestures: the hand hold needs the camera.
    defs.handGestureHoldSeconds.key,
    defs.gesturesFaceWho.key,
    defs.gesturesFacePeople.key,
    // DLNA: everything is background audio here.
    defs.dlnaAudioBackground.key,
  };

  /// The volume buttons only reach the kiosk on a ROM that lets it claim
  /// them (BiscuitVolumeButtons.kt). There they work while the player
  /// plays: nothing is ever on screen.
  static void _volumeButtons() {
    if (Headless.volumeClaim) {
      defs.deviceHiddenOptions[defs.sendspinVolumeKeys.key] = {'now_playing'};
    } else {
      defs.deviceHiddenKeys
        ..add(defs.sendspinVolumeKeys.key)
        ..add(defs.sendspinVolumeKeyStep.key);
    }
  }

  /// Subpages and sections of pages that otherwise stay.
  static bool _hiddenPart(defs.SettingDef<Object> def) {
    switch (def.category) {
      case 'Screen & Audio':
        return def.section == 'Screen' || def.subpage == 'Adaptive brightness';
      case 'Home Assistant':
        return def.subpage != null;
      case 'Sendspin':
        return const {
              'Floating Player',
              'Now Playing',
              'Lyrics',
              'Music Library',
            }.contains(def.subpage) ||
            def.section == 'Kiosk menu';
      case 'ESPHome':
        return def.subpage == 'Notifications' && def.section == 'Appearance';
      case 'Voice Satellite':
        return const {'Appearance', 'Conversation'}.contains(def.subpage);
      case 'Timers':
        return def.section == 'Pills';
    }
    return false;
  }

  /// Settings that hold one value here, whatever was stored.
  static final Map<defs.SettingDef<Object>, Object> _pinned = {
    defs.remoteEnabled: true,
    defs.screensaverEnabled: false,
    defs.kioskEnabled: false,
    defs.lockdownEnabled: false,
    defs.launcherEnabled: false,
    defs.homeLauncherEnabled: false,
    defs.cameraEnabled: false,
    defs.cameraRtspEnabled: false,
    defs.adaptiveBrightness: false,
    defs.wakeWordBackground: true,
    defs.wakeWordReturnToBackground: false,
    defs.dlnaAudioBackground: true,
    // The pills would blank the timer names Home Assistant gets.
    defs.voiceTimerPills: false,
    defs.intercomTalkMode: 'handsfree',
    // The dashboard runtime runs inside the WebView.
    defs.voiceRuntime: 'native',
  };

  /// Before any manager reads its settings and any page renders.
  Future<void> init() async {
    for (final def in defs.allSettings) {
      // A link to Drawer menu items goes with the menu, which is not here.
      // Other links stay, like Voice Match under Ground Control's Features.
      if (_hiddenCategories.contains(def.category) ||
          _hiddenKeys.contains(def.key) ||
          def.linksTo == defs.uiDrawerItems.key ||
          _hiddenPart(def)) {
        defs.deviceHiddenKeys.add(def.key);
      }
    }
    _volumeButtons();
    for (final entry in _pinned.entries) {
      defs.devicePinnedKeys.add(entry.key.key);
      await _pin(entry.key, entry.value);
    }
    _sub = _bus.on<SettingChanged>().listen((e) {
      for (final entry in _pinned.entries) {
        if (entry.key.key == e.key) unawaited(_pin(entry.key, entry.value));
      }
    });
  }

  Future<void> _pin(defs.SettingDef<Object> def, Object value) async {
    if (_settings.get(def) == value) return;
    _log.info('headless', '${def.key} is $value on a device without a screen');
    await _settings.set(def, value);
  }

  Future<void> dispose() async => _sub?.cancel();
}
