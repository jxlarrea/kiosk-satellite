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
    this.options,
    this.secret = false,
  });

  final String key;
  final SettingType type;
  final T defaultValue;
  final String title;
  final String description;
  final String category;

  /// Allowed values for [SettingType.select].
  final List<String>? options;

  /// Secrets are write-only over the remote API and masked in exports.
  final bool secret;
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
  defaultValue: 'dim',
  title: 'Screensaver mode',
  description: 'What the screensaver shows.',
  category: 'Screensaver',
  options: ['dim', 'black'],
);

const screensaverDimLevel = SettingDef<num>(
  key: 'screensaver.dim_level',
  type: SettingType.number,
  defaultValue: 0.1,
  title: 'Dim level',
  description: 'Brightness (0..1) while the screensaver is dimming.',
  category: 'Screensaver',
);

const screensaverDismissOnMotion = SettingDef<bool>(
  key: 'screensaver.dismiss_on_motion',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Dismiss on motion',
  description: 'Camera motion wakes the screen.',
  category: 'Screensaver',
);

// ── Motion ─────────────────────────────────────────────────────────────

const motionEnabled = SettingDef<bool>(
  key: 'motion.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Motion detection',
  description: 'Detect motion with the front camera.',
  category: 'Motion',
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

const wakeWordResumeTimeoutSeconds = SettingDef<num>(
  key: 'wake_word.resume_timeout_seconds',
  type: SettingType.number,
  defaultValue: 60,
  title: 'Resume timeout (seconds)',
  description:
      'Self-heal: resume listening if the page never calls '
      'setWakeWordActive(true) after a handoff.',
  category: 'Voice Satellite',
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
  defaultValue: 2323,
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

/// All settings, in display order.
const List<SettingDef<Object>> allSettings = [
  startUrl,
  autoReloadOnError,
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
  screensaverDismissOnMotion,
  motionEnabled,
  wakeWordEnabled,
  wakeWordResumeTimeoutSeconds,
  haUrl,
  haToken,
  haKioskMode,
  remoteEnabled,
  remotePort,
  remotePassword,
  deviceName,
];
