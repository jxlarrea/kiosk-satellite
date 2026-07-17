/// Declarative setting definitions.
///
/// Every setting is declared exactly once here. The local settings UI, the
/// remote admin UI (via GET /api/settings), and import/export all render or
/// serialize from these definitions — never from ad-hoc keys.
library;

enum SettingType { string, boolean, number, select, password }

class SettingDef<T> {
  const SettingDef({
    required this.key,
    required this.type,
    required this.defaultValue,
    required this.title,
    required this.description,
    this.category = 'General',
    this.section,
    this.options,
    this.secret = false,
    this.dependsOn,
    this.dependsOnValue = true,
    this.hidden = false,
    this.min,
    this.max,
    this.step,
    this.unit,
  });

  final String key;
  final SettingType type;
  final T defaultValue;
  final String title;
  final String description;
  final String category;

  /// An optional subheading within [category]. Consecutive settings sharing a
  /// section render under one heading in both the on-device and remote UIs —
  /// e.g. the motion controls grouped under "Motion Detection" on the
  /// Screensaver page.
  final String? section;

  /// Allowed values for [SettingType.select].
  final List<String>? options;

  /// Secrets are write-only over the remote API and masked in exports.
  final bool secret;

  /// Key of another setting this one only makes sense under. Hidden — not
  /// disabled — unless that setting equals [dependsOnValue]: a control that
  /// cannot do anything is noise, and explaining why it is greyed out costs
  /// more words than it saves.
  ///
  /// Declared here rather than in a screen because there are two screens. The
  /// on-device settings and the remote admin both render from these
  /// definitions, and a rule that lives in one of them is a rule the other
  /// breaks.
  final String? dependsOn;

  /// The value [dependsOn] must hold. Defaults to `true` for the common
  /// boolean-switch case; set to a string to gate on a mode select.
  final Object dependsOnValue;

  /// Persisted and readable, but never shown as a settings row. For state the
  /// app tracks on the user's behalf — e.g. whether the chosen media is a
  /// folder — that other settings key their visibility off.
  final bool hidden;

  /// Range for [SettingType.number]. With both [min] and [max] set, the
  /// setting renders as a slider — in the on-device settings and the remote
  /// admin alike — instead of a free-typed number.
  final num? min;
  final num? max;

  /// Slider increment; null means continuous.
  final num? step;

  /// Display suffix for the slider's value ('%'). A '%' unit with max <= 1
  /// means the stored value is a 0..1 fraction shown as a percentage.
  final String? unit;
}

// ── Browser ────────────────────────────────────────────────────────────

const startUrl = SettingDef<String>(
  key: 'browser.start_url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Start URL',
  description: 'Page loaded on launch. Usually your Home Assistant dashboard.',
  category: 'Browser',
);

const autoReloadOnError = SettingDef<bool>(
  key: 'browser.auto_reload_on_error',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Auto-reload on error',
  description: 'Reload the page automatically after a load failure or crash.',
  category: 'Browser',
);

const pullToRefresh = SettingDef<bool>(
  key: 'browser.pull_to_refresh',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable pull to refresh',
  description:
      'Drag down from the top of the page to reload it. Off by '
      'default: on a scrolling dashboard an accidental pull is easy.',
  category: 'Browser',
);

const pullToRefreshClearCache = SettingDef<bool>(
  key: 'browser.pull_to_refresh_clear_cache',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Clear cache when pulling to refresh',
  description:
      'A pull also drops the HTTP cache, Cache Storage and any '
      'service worker before reloading — the same as Clear web cache. '
      'Login and saved page data are kept.',
  category: 'Browser',
  dependsOn: 'browser.pull_to_refresh',
);

const disableCache = SettingDef<bool>(
  key: 'browser.disable_cache',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable cache',
  description:
      'Always fetch from the network, ignoring the HTTP cache, and drop any '
      'service worker + Cache Storage on load (Home Assistant registers one, '
      'which otherwise keeps serving a stale dashboard or card after you '
      'redeploy). Saved page data (localStorage) is never touched. Slower on '
      'a normal kiosk — this is a development aid.',
  category: 'Browser',
);

const allowMixedContent = SettingDef<bool>(
  key: 'browser.allow_mixed_content',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Allow mixed content',
  description:
      'Let HTTPS pages load insecure HTTP resources. Helps when Home '
      'Assistant mixes http:// content into an https:// dashboard.',
  category: 'Browser',
);

const ignoreSslErrors = SettingDef<bool>(
  key: 'browser.ignore_ssl_errors',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Ignore SSL errors',
  description:
      'Accept untrusted or self-signed certificates. Use only on your own '
      'network — this disables certificate verification.',
  category: 'Browser',
);

// ── Web content (permissions, à la Fully Kiosk) ────────────────────────

const webMicrophone = SettingDef<bool>(
  key: 'web.microphone',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Enable microphone access',
  description:
      'Let web pages use the microphone (required for Voice Satellite).',
  category: 'Web Content',
);

const webCamera = SettingDef<bool>(
  key: 'web.camera',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable webcam access',
  description: 'Let web pages use the camera.',
  category: 'Web Content',
);

const webGeolocation = SettingDef<bool>(
  key: 'web.geolocation',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable geolocation access',
  description: 'Let web pages request the device location.',
  category: 'Web Content',
);

const webAutoplay = SettingDef<bool>(
  key: 'web.autoplay',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Autoplay audio and video',
  description: 'Allow media to play without a user gesture.',
  category: 'Web Content',
);

const webPopups = SettingDef<bool>(
  key: 'web.popups',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable pop-ups',
  description: 'Allow pages to open new windows via JavaScript.',
  category: 'Web Content',
);

// ── Screen ─────────────────────────────────────────────────────────────

const keepScreenOn = SettingDef<bool>(
  key: 'screen.keep_on',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Keep screen on',
  description: 'Prevent the OS from turning the screen off.',
  category: 'Screen',
);

// ── Screensaver ────────────────────────────────────────────────────────

const screensaverEnabled = SettingDef<bool>(
  key: 'screensaver.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Screensaver',
  description: 'Dim or blank the screen after a period of inactivity.',
  category: 'Screensaver',
);

const screensaverTimeoutSeconds = SettingDef<num>(
  key: 'screensaver.timeout_seconds',
  type: SettingType.number,
  defaultValue: 300,
  title: 'Idle timeout (seconds)',
  description: 'Inactivity period before the screensaver starts.',
  category: 'Screensaver',
);

const screensaverMode = SettingDef<String>(
  key: 'screensaver.mode',
  type: SettingType.select,
  defaultValue: 'black',
  title: 'Screensaver mode',
  description:
      'What the screensaver shows after the idle timeout. "dim" only '
      'lowers the backlight and is the lightest.',
  category: 'Screensaver',
  options: ['dim', 'black', 'clock', 'media', 'website'],
);

// ── Clock (mode: clock) ──

const screensaverClock24h = SettingDef<bool>(
  key: 'screensaver.clock_24h',
  type: SettingType.boolean,
  defaultValue: false,
  title: '24-hour clock',
  description: 'Show a 24-hour time instead of AM/PM.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
);

const screensaverClockSeconds = SettingDef<bool>(
  key: 'screensaver.clock_seconds',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show seconds',
  description: 'Include seconds in the clock.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
);

const screensaverClockDate = SettingDef<bool>(
  key: 'screensaver.clock_show_date',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Show date',
  description: 'Show the weekday and date under the clock.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
);

const screensaverClockScale = SettingDef<num>(
  key: 'screensaver.clock_scale',
  type: SettingType.number,
  defaultValue: 100,
  title: 'Clock size',
  description: 'Scale the clock from 50 to 300 percent for this screen.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
  min: 50,
  max: 300,
  step: 5,
  unit: '%',
);

const screensaverClockColor = SettingDef<String>(
  key: 'screensaver.clock_color',
  type: SettingType.string,
  // Stored as "r,g,b"; both UIs render a real colour picker for it.
  defaultValue: '250,250,250',
  title: 'Clock colour',
  description: 'The colour of the clock text.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
);

// ── Media (mode: media) ──

const screensaverMediaId = SettingDef<String>(
  key: 'screensaver.media_id',
  type: SettingType.string,
  defaultValue: '',
  title: 'Home Assistant Media',
  description:
      'A Home Assistant media item, folder, or camera. Use Browse to '
      'pick one.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'media',
);

// Set by the media picker: true when a folder was chosen, false for a single
// image, video, or camera. The playlist settings key their visibility off it —
// shuffle and subfolders mean nothing for one file.
const screensaverMediaIsFolder = SettingDef<bool>(
  key: 'screensaver.media_is_folder',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Media is a folder',
  description: '',
  category: 'Screensaver',
  hidden: true,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'media',
);

const screensaverMediaInterval = SettingDef<num>(
  key: 'screensaver.media_interval_seconds',
  type: SettingType.number,
  defaultValue: 10,
  title: 'Seconds per image',
  description:
      'How long each image shows before the next. Videos play in full.',
  category: 'Screensaver',
  dependsOn: 'screensaver.media_is_folder',
);

const screensaverMediaShuffle = SettingDef<bool>(
  key: 'screensaver.media_shuffle',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Shuffle',
  description: 'Play a folder in random order.',
  category: 'Screensaver',
  dependsOn: 'screensaver.media_is_folder',
);

const screensaverMediaRecursive = SettingDef<bool>(
  key: 'screensaver.media_recursive',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Include subfolders',
  description: 'Descend into subfolders when a folder is chosen.',
  category: 'Screensaver',
  dependsOn: 'screensaver.media_is_folder',
);

// ── Website (mode: website) ──

const screensaverWebsiteUrl = SettingDef<String>(
  key: 'screensaver.website_url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Website URL',
  description: 'A page to show full-screen. It must allow being embedded.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'website',
);

// ── Burn-in ──

const screensaverPixelShift = SettingDef<bool>(
  key: 'screensaver.pixel_shift',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Pixel shift',
  description:
      'Nudge the image every minute to protect OLED panels. Not for '
      'the black screensaver, whose pixels are already off.',
  category: 'Screensaver',
);

const screensaverDimLevel = SettingDef<num>(
  key: 'screensaver.dim_level',
  type: SettingType.number,
  defaultValue: 0.1,
  title: 'Dim level',
  description: 'Screen brightness while the screensaver is dimming.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'dim',
  min: 0,
  max: 1,
  step: 0.05,
  unit: '%',
);

// Motion detection exists only to wake the screensaver for now, so this one
// switch is its whole on/off — no separate "motion detection" toggle. Off by
// default because turning it on asks for the camera. When on, the camera runs
// only while the screensaver is showing.
const screensaverDismissOnMotion = SettingDef<bool>(
  key: 'screensaver.dismiss_on_motion',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Dismiss on motion',
  description:
      'Watch the camera while the screensaver is up and wake the screen '
      'when someone approaches. The camera runs only during the screensaver, so '
      'it costs nothing during normal use.',
  category: 'Screensaver',
  section: 'Motion Detection',
);

const motionFps = SettingDef<num>(
  key: 'motion.fps',
  type: SettingType.number,
  defaultValue: 2,
  title: 'Motion frame rate',
  description:
      'Frames per second the camera checks for motion. Lower is lighter '
      'on the CPU; 2 is plenty to notice someone approaching.',
  category: 'Screensaver',
  section: 'Motion Detection',
  dependsOn: 'screensaver.dismiss_on_motion',
);

const motionSensitivity = SettingDef<num>(
  key: 'motion.sensitivity',
  type: SettingType.number,
  defaultValue: 40,
  title: 'Motion sensitivity',
  description:
      'Higher trips on smaller movements. 1 needs a large change across '
      'the frame; 100 reacts to the slightest motion.',
  category: 'Screensaver',
  section: 'Motion Detection',
  dependsOn: 'screensaver.dismiss_on_motion',
  min: 1,
  max: 100,
  step: 1,
);

const motionCamera = SettingDef<String>(
  key: 'motion.camera',
  type: SettingType.select,
  defaultValue: 'front',
  title: 'Motion camera',
  description: 'Which camera watches for motion.',
  category: 'Screensaver',
  section: 'Motion Detection',
  options: ['front', 'back'],
  dependsOn: 'screensaver.dismiss_on_motion',
);

// ── Wake word ──────────────────────────────────────────────────────────

const wakeWordEnabled = SettingDef<bool>(
  key: 'wake_word.enabled',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Wake word detection',
  description:
      'Master switch. Engine and models are inherited from Voice Satellite '
      'in Home Assistant — there is nothing to configure here.',
  category: 'Voice Satellite',
);

const wakeWordBackground = SettingDef<bool>(
  key: 'wake_word.background',
  type: SettingType.boolean,
  // Off: it costs a permanent notification and two more OS grants, which is a
  // poor trade for a kiosk that is never behind another app — the normal case.
  defaultValue: false,
  title: 'Keep listening in the background',
  description:
      'Keep hearing the wake word while another app is in front, and come back '
      'to the front on a detection. Android freezes apps it cannot see, so this '
      'needs a permanent notification and permission to display over other apps.',
  category: 'Voice Satellite',
  dependsOn: 'wake_word.enabled',
);

const wakeWordResumeTimeoutSeconds = SettingDef<num>(
  key: 'wake_word.resume_timeout_seconds',
  type: SettingType.number,
  defaultValue: 60,
  title: 'Resume timeout (seconds)',
  description:
      'Self-heal: resume listening if the page never calls '
      'setWakeWordActive(true) after a handoff.',
  category: 'Voice Satellite',
  dependsOn: 'wake_word.enabled',
);

// ── Home Assistant ─────────────────────────────────────────────────────

const haUrl = SettingDef<String>(
  key: 'ha.url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Home Assistant URL',
  description: 'Base URL, e.g. http://homeassistant.local:8123',
  category: 'Home Assistant',
);

const haToken = SettingDef<String>(
  key: 'ha.token',
  type: SettingType.password,
  defaultValue: '',
  title: 'Long-lived access token',
  description: 'Created under your HA profile → Security.',
  category: 'Home Assistant',
  secret: true,
);

const haKioskMode = SettingDef<String>(
  key: 'ha.kiosk_mode',
  type: SettingType.select,
  defaultValue: 'off',
  title: 'HA kiosk mode',
  description:
      'Hide the Home Assistant header and sidebar. Off shows the normal HA '
      'UI. "auto" uses the kiosk-mode HACS plugin when detected, otherwise '
      'injects CSS. Applies immediately — no restart.',
  category: 'Home Assistant',
  options: ['off', 'auto', 'plugin', 'css'],
);

const themeAuto = SettingDef<bool>(
  key: 'ha.theme_auto',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Match theme to time of day',
  description:
      'Switch Home Assistant between light and dark on a schedule. '
      'Keeps whatever theme is selected, flipping only its light/dark variant.',
  category: 'Home Assistant',
  section: 'Theme',
);

const themeDarkAt = SettingDef<String>(
  key: 'ha.theme_dark_at',
  type: SettingType.string,
  defaultValue: '19:00',
  title: 'Dark theme at',
  description: 'Local time to switch to the dark theme.',
  category: 'Home Assistant',
  section: 'Theme',
  dependsOn: 'ha.theme_auto',
);

const themeLightAt = SettingDef<String>(
  key: 'ha.theme_light_at',
  type: SettingType.string,
  defaultValue: '07:00',
  title: 'Light theme at',
  description: 'Local time to switch back to the light theme.',
  category: 'Home Assistant',
  section: 'Theme',
  dependsOn: 'ha.theme_auto',
);

// ── Remote management ──────────────────────────────────────────────────

const remoteEnabled = SettingDef<bool>(
  key: 'remote.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Remote management',
  description: 'Run the embedded admin web server.',
  category: 'Remote',
);

const remotePort = SettingDef<num>(
  key: 'remote.port',
  type: SettingType.number,
  defaultValue: 2324,
  title: 'Server port',
  description: 'Port for the remote admin interface.',
  category: 'Remote',
);

const remotePassword = SettingDef<String>(
  key: 'remote.password',
  type: SettingType.password,
  defaultValue: '',
  title: 'Admin password',
  description: 'Required to log in to the remote interface.',
  category: 'Remote',
  secret: true,
);

// ── Device ─────────────────────────────────────────────────────────────

const deviceName = SettingDef<String>(
  key: 'device.name',
  type: SettingType.string,
  defaultValue: '',
  title: 'Device name',
  description: 'Friendly name shown in remote management and Home Assistant.',
  category: 'Device',
);

const uiTheme = SettingDef<String>(
  key: 'ui.theme',
  type: SettingType.select,
  defaultValue: 'dark',
  title: 'App theme',
  description:
      "Light or dark for the app's own screens — menu, settings, "
      'dialogs. System follows the Android setting. Dark by default: kiosks '
      'live on walls, mostly at night.',
  category: 'Device',
  options: ['dark', 'light', 'system'],
);

/// All settings, in display order.
const List<SettingDef<Object>> allSettings = [
  startUrl,
  autoReloadOnError,
  pullToRefresh,
  pullToRefreshClearCache,
  disableCache,
  allowMixedContent,
  ignoreSslErrors,
  webMicrophone,
  webCamera,
  webGeolocation,
  webAutoplay,
  webPopups,
  keepScreenOn,
  screensaverEnabled,
  screensaverTimeoutSeconds,
  screensaverMode,
  screensaverDimLevel,
  screensaverClock24h,
  screensaverClockSeconds,
  screensaverClockDate,
  screensaverClockScale,
  screensaverClockColor,
  screensaverMediaId,
  screensaverMediaIsFolder,
  screensaverMediaInterval,
  screensaverMediaShuffle,
  screensaverMediaRecursive,
  screensaverWebsiteUrl,
  screensaverPixelShift,
  screensaverDismissOnMotion,
  motionFps,
  motionSensitivity,
  motionCamera,
  wakeWordEnabled,
  wakeWordBackground,
  wakeWordResumeTimeoutSeconds,
  haUrl,
  haToken,
  haKioskMode,
  themeAuto,
  themeDarkAt,
  themeLightAt,
  remoteEnabled,
  remotePort,
  remotePassword,
  deviceName,
  uiTheme,
];
