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
    this.optionLabels,
    this.validator,
    this.multiline = false,
    this.placeholder,
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

  /// A [SettingType.string] holding free-form multi-line text (pasted
  /// JavaScript). Both UIs swap the one-line field for a code-friendly
  /// multi-line editor, and the row shows its description, not the blob.
  final bool multiline;

  /// Example text shown in the empty editor instead of [description] —
  /// a code sample reads better than prose where code is expected.
  final String? placeholder;

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

  /// Display names for [options], keyed by stored value — 'media' can read
  /// "Home Assistant Media" without changing what is persisted. Both UIs
  /// fall back to capitalising the raw value when a label is missing.
  final Map<String, String>? optionLabels;

  /// Optional value check applied on every write (device UI, remote API,
  /// import all funnel through setFromJson). Returns an error message, or
  /// null for a valid value.
  final String? Function(Object? value)? validator;
}

/// A Home Assistant *base* URL: scheme + host (+ port), nothing after.
/// Dashboard paths belong to the dashboard picker, not here.
String? validateBaseUrl(Object? value) {
  if (value is! String || value.trim().isEmpty) return null; // empty = unset
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return 'Enter a valid URL, for example '
        'https://homeassistant.local:8123';
  }
  if (uri.path.isNotEmpty && uri.path != '/') {
    return 'Enter only the base URL, without a dashboard path. Example: '
        'https://homeassistant.local:8123';
  }
  if (uri.hasQuery || uri.hasFragment) {
    return 'Enter only the base URL, without anything after the port. '
        'Example: https://homeassistant.local:8123';
  }
  return null;
}

// ── Browser ────────────────────────────────────────────────────────────

// Hidden: the dashboard picker (Home Assistant → Dashboard) owns this
// value now — the app is Home Assistant-oriented, and a free-typed URL is
// the setup wizard's job to avoid, not offer.
const startUrl = SettingDef<String>(
  key: 'browser.start_url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Start URL',
  description: 'Page loaded on launch.',
  category: 'Browser',
  hidden: true,
);

// Hidden from the generic renderers: both UIs hand-build this row inside
// the Home Assistant connection card (below Validate connection), because
// its enabled/disabled state derives from the HA URL's scheme — a plain
// http URL enables it, https keeps it disabled and off.
const secureProxy = SettingDef<bool>(
  key: 'browser.secure_proxy',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Secure context proxy',
  description:
      'Routes a plain http Home Assistant through a proxy inside the app '
      'so the browser unlocks the microphone and other https-only '
      'features. Available only for http URLs.',
  category: 'Home Assistant',
  hidden: true,
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
      'A pull also empties the HTTP cache, Cache Storage and the cached '
      'wake word models before reloading, so the page and its models come '
      'back fresh. Login and saved page data are kept.',
  category: 'Browser',
  dependsOn: 'browser.pull_to_refresh',
);

const pinchToZoom = SettingDef<bool>(
  key: 'browser.pinch_to_zoom',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable pinch to zoom',
  description:
      'Zoom the page with a two-finger pinch. Off by default: a '
      'kiosk dashboard should stay put under stray touches. Pages that '
      'forbid zooming in their viewport settings still win.',
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
      'a normal kiosk, so treat it as a development aid.',
  category: 'Browser',
);

const browserInjectJs = SettingDef<String>(
  key: 'browser.inject_js',
  type: SettingType.string,
  defaultValue: '',
  title: 'Inject JavaScript',
  description:
      'Run this JavaScript code after loading each page. Useful to hide '
      'distracting elements or tweak sites you do not control.',
  category: 'Browser',
  multiline: true,
  placeholder:
      "// Example: hide a distracting element\n"
      "document.querySelector('#banner').style.display = 'none';",
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
      'network, since it disables certificate verification.',
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
  hidden: true,
);

const webCamera = SettingDef<bool>(
  key: 'web.camera',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Enable webcam access',
  description: 'Let web pages use the camera.',
  category: 'Web Content',
  hidden: true,
);

const webGeolocation = SettingDef<bool>(
  key: 'web.geolocation',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Enable geolocation access',
  description: 'Let web pages request the device location.',
  category: 'Web Content',
  hidden: true,
);

const webAutoplay = SettingDef<bool>(
  key: 'web.autoplay',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Autoplay audio and video',
  description: 'Allow media to play without a user gesture.',
  category: 'Web Content',
  hidden: true,
);

const webPopups = SettingDef<bool>(
  key: 'web.popups',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Enable pop-ups',
  description: 'Allow pages to open new windows via JavaScript.',
  category: 'Web Content',
  hidden: true,
);

// ── Kiosk Mode ─────────────────────────────────────────────────────────
//
// Fully-style device lockdown. What Android lets an ordinary app do, it
// does; what it does not, the descriptions say honestly: the power button
// cannot be intercepted (the screen is re-woken instead), and the home
// button is only blocked through OS screen pinning.

const kioskEnabled = SettingDef<bool>(
  key: 'kiosk.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable kiosk mode',
  description:
      'Lock the tablet into Kiosk Satellite. The menu swipe is replaced '
      'by the exit gesture, the back button stays inside the kiosk, and '
      'the protections below arm.',
  category: 'Kiosk',
);

const kioskStartOnBoot = SettingDef<bool>(
  key: 'kiosk.start_on_boot',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Start on boot',
  description:
      'Launch Kiosk Satellite when the device powers on. Reliable '
      'background launch on Android 10+ needs the "display over other '
      'apps" permission. Android asks when this is first enabled on '
      'the device.',
  category: 'Kiosk',
);

const kioskExitGesture = SettingDef<String>(
  key: 'kiosk.exit_gesture',
  type: SettingType.select,
  defaultValue: 'taps7',
  title: 'Kiosk exit gesture',
  description:
      'Fast taps anywhere on the screen open the menu, after the PIN '
      'if one is set. With the gesture disabled, only the remote admin '
      'can reach the settings.',
  category: 'Kiosk',
  options: ['taps5', 'taps7', 'none'],
  optionLabels: {
    'taps5': '5 fast taps',
    'taps7': '7 fast taps',
    'none': 'Disabled (remote admin only)',
  },
  dependsOn: 'kiosk.enabled',
);

const kioskPin = SettingDef<String>(
  key: 'kiosk.pin',
  type: SettingType.password,
  defaultValue: '',
  title: 'Kiosk mode PIN',
  description:
      'Asked after the exit gesture before the menu opens. Leave empty '
      'for no PIN.',
  category: 'Kiosk',
  secret: true,
  dependsOn: 'kiosk.enabled',
);

const kioskDisableStatusBar = SettingDef<bool>(
  key: 'kiosk.disable_status_bar',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable status bar',
  description:
      'Block the status bar pull-down with a shield over the top edge. '
      'Needs the "display over other apps" permission. Android asks for '
      'it when this is first enabled on the device.',
  category: 'Kiosk',
  dependsOn: 'kiosk.enabled',
);

const kioskDisableVolume = SettingDef<bool>(
  key: 'kiosk.disable_volume',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable volume buttons',
  description: 'Swallow the hardware volume keys.',
  category: 'Kiosk',
  dependsOn: 'kiosk.enabled',
);

const kioskDisablePower = SettingDef<bool>(
  key: 'kiosk.disable_power',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable power button',
  description:
      'Android does not let apps block the power button; when it switches '
      'the screen off, Kiosk Satellite turns it right back on.',
  category: 'Kiosk',
  dependsOn: 'kiosk.enabled',
);

const kioskDisableHome = SettingDef<bool>(
  key: 'kiosk.disable_home',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable home button',
  description:
      'Pin the app with Android screen pinning, which blocks the home and '
      'recents buttons. Android asks to confirm the first time.',
  category: 'Kiosk',
  dependsOn: 'kiosk.enabled',
);

const kioskDisableContextMenus = SettingDef<bool>(
  key: 'kiosk.disable_context_menus',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable context menus',
  description:
      'Suppress long-press menus and text selection inside the web view.',
  category: 'Kiosk',
  dependsOn: 'kiosk.enabled',
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

// Off by default: a slider with no gate would override every device's
// OS-managed brightness the moment it upgrades.
const setBrightnessOnLaunch = SettingDef<bool>(
  key: 'screen.set_brightness_on_launch',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Set brightness on launch',
  description: 'Apply the default brightness whenever the app starts.',
  category: 'Screen',
);

const defaultBrightness = SettingDef<num>(
  key: 'screen.default_brightness',
  type: SettingType.number,
  defaultValue: 0.8,
  title: 'Default brightness',
  description:
      'Screen brightness applied when the app starts. Moving the slider '
      'applies it immediately.',
  category: 'Screen',
  // Never 0: a kiosk that boots to a black panel looks dead.
  min: 0.05,
  max: 1,
  step: 0.05,
  unit: '%',
  dependsOn: 'screen.set_brightness_on_launch',
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
      'What the screensaver shows after the idle timeout. Dim only '
      'lowers the backlight and is the lightest.',
  category: 'Screensaver',
  options: ['dim', 'black', 'clock', 'media', 'local', 'gallery', 'website'],
  optionLabels: {
    'dim': 'Dim',
    'black': 'Black',
    'clock': 'Clock',
    'media': 'Home Assistant Media',
    'local': 'Local Media',
    'gallery': 'Photo Gallery',
    'website': 'Website',
  },
);

// ── Clock (mode: clock) ──

const screensaverClock24h = SettingDef<bool>(
  key: 'screensaver.clock_24h',
  type: SettingType.boolean,
  defaultValue: false,
  title: '24-hour clock',
  description: 'Show a 24-hour time instead of AM/PM.',
  category: 'Screensaver',
  section: 'Clock',
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
  section: 'Clock',
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
  section: 'Clock',
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
  section: 'Clock',
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
  section: 'Clock',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
);

// ── Media (mode: media) ──

const screensaverMediaId = SettingDef<String>(
  key: 'screensaver.media_id',
  type: SettingType.string,
  defaultValue: '',
  // 'Media source', not 'Home Assistant Media': the row now sits under a
  // panel already titled with the mode name.
  title: 'Media source',
  description:
      'A Home Assistant media item, folder, or camera. Use Browse to '
      'pick one.',
  category: 'Screensaver',
  section: 'Home Assistant Media',
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
  section: 'Home Assistant Media',
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
  section: 'Home Assistant Media',
  dependsOn: 'screensaver.media_is_folder',
);

const screensaverMediaShuffle = SettingDef<bool>(
  key: 'screensaver.media_shuffle',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Shuffle',
  description: 'Play a folder in random order.',
  category: 'Screensaver',
  section: 'Home Assistant Media',
  dependsOn: 'screensaver.media_is_folder',
);

const screensaverMediaRecursive = SettingDef<bool>(
  key: 'screensaver.media_recursive',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Include subfolders',
  description: 'Descend into subfolders when a folder is chosen.',
  category: 'Screensaver',
  section: 'Home Assistant Media',
  dependsOn: 'screensaver.media_is_folder',
);

// One set of transitions shared by every slideshow mode — a person who
// switches modes should not have to relearn the vocabulary. 'Ken Burns'
// is the slow drifting zoom of documentary photo pans; stills only —
// motion on top of motion just looks broken, so videos fall back to a
// crossfade.
// 'random' rolls one of the real transitions per hand-off ('none' is
// excluded from the pool — a surprise hard cut just reads as a glitch).
const _transitionOptions = ['none', 'fade', 'slide', 'zoom', 'kenburns', 'random'];
const _transitionLabels = {
  'none': 'None',
  'fade': 'Crossfade',
  'slide': 'Slide',
  'zoom': 'Zoom',
  'kenburns': 'Ken Burns',
  'random': 'Random',
};

const screensaverMediaTransition = SettingDef<String>(
  key: 'screensaver.media_transition',
  type: SettingType.select,
  defaultValue: 'fade',
  title: 'Transition',
  description: 'How one item hands off to the next.',
  category: 'Screensaver',
  section: 'Home Assistant Media',
  options: _transitionOptions,
  optionLabels: _transitionLabels,
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
  section: 'Website',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'website',
);

// ── Burn-in ──

// ── Photo gallery (mode: gallery) ──
//
// Hand-picked photos and videos, chosen with the system gallery picker on
// the device (permissionless — the picker grants access per item) and
// copied into app storage so the selection survives reboots and permission
// changes. The value is a JSON array of those copies' paths: not a thing a
// person edits, but not hidden either — both UIs special-case the row to
// show the count.

const screensaverGalleryItems = SettingDef<String>(
  key: 'screensaver.gallery_items',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Photos',
  description:
      'The photos and videos this screensaver cycles. Picked from the '
      'gallery on the device; picking again replaces the selection.',
  category: 'Screensaver',
  section: 'Photo Gallery',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'gallery',
);

const screensaverGalleryInterval = SettingDef<num>(
  key: 'screensaver.gallery_interval_seconds',
  type: SettingType.number,
  defaultValue: 10,
  title: 'Seconds per photo',
  description:
      'How long each photo shows before the next. Videos play in full.',
  category: 'Screensaver',
  section: 'Photo Gallery',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'gallery',
);

const screensaverGalleryShuffle = SettingDef<bool>(
  key: 'screensaver.gallery_shuffle',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Shuffle',
  description: 'Cycle the selection in random order.',
  category: 'Screensaver',
  section: 'Photo Gallery',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'gallery',
);

const screensaverGalleryTransition = SettingDef<String>(
  key: 'screensaver.gallery_transition',
  type: SettingType.select,
  defaultValue: 'fade',
  title: 'Transition',
  description: 'How one photo hands off to the next.',
  category: 'Screensaver',
  section: 'Photo Gallery',
  options: _transitionOptions,
  optionLabels: _transitionLabels,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'gallery',
);

// ── Local media (mode: local) ──

const screensaverLocalFolder = SettingDef<String>(
  key: 'screensaver.local_folder',
  type: SettingType.string,
  defaultValue: '',
  title: 'Local folder',
  description:
      'Folder on this device whose photos and videos the screensaver '
      'cycles through. Picked on the device; the path can also be typed '
      'here remotely.',
  category: 'Screensaver',
  section: 'Local Media',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'local',
);

const screensaverLocalInterval = SettingDef<num>(
  key: 'screensaver.local_interval_seconds',
  type: SettingType.number,
  defaultValue: 10,
  title: 'Seconds per photo',
  description:
      'How long each photo shows before the next. Videos play in full.',
  category: 'Screensaver',
  section: 'Local Media',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'local',
);

const screensaverLocalShuffle = SettingDef<bool>(
  key: 'screensaver.local_shuffle',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Shuffle',
  description: 'Cycle the folder in random order instead of by name.',
  category: 'Screensaver',
  section: 'Local Media',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'local',
);

const screensaverLocalRecursive = SettingDef<bool>(
  key: 'screensaver.local_recursive',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Include subfolders',
  description: 'Also cycle photos and videos inside subfolders.',
  category: 'Screensaver',
  section: 'Local Media',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'local',
);

const screensaverLocalTransition = SettingDef<String>(
  key: 'screensaver.local_transition',
  type: SettingType.select,
  defaultValue: 'fade',
  title: 'Transition',
  description: 'How one photo hands off to the next.',
  category: 'Screensaver',
  section: 'Local Media',
  options: _transitionOptions,
  optionLabels: _transitionLabels,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'local',
);

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
  section: 'Dim',
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
  defaultValue: 70,
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
  optionLabels: {'front': 'Front', 'back': 'Back'},
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
      'in Home Assistant, so there is nothing to configure here.',
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

const vsSuppressScreensaver = SettingDef<bool>(
  key: 'vs.suppress_screensaver',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Turn off the Voice Satellite screensaver',
  description:
      'While the Kiosk Satellite screensaver is enabled, the Voice Satellite '
      'screensaver on the dashboard stands down so the two never run at '
      'once. Voice Satellite shows a notice next to its own screensaver '
      'setting while this is in effect.',
  category: 'Voice Satellite',
);

// ── Home Assistant ─────────────────────────────────────────────────────

const haUrl = SettingDef<String>(
  key: 'ha.url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Home Assistant Base URL',
  description: 'e.g. https://homeassistant.local:8123, without a dashboard path.',
  category: 'Home Assistant',
  validator: validateBaseUrl,
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

// Hidden: written by the setup wizard's satellite picker. Seeded into the
// dashboard page's localStorage (vs-satellite-entity) at document start so
// Voice Satellite selects its assist_satellite, hydrates its server-side
// profile and starts without any in-page setup.
const haSatelliteEntity = SettingDef<String>(
  key: 'ha.satellite_entity',
  type: SettingType.string,
  defaultValue: '',
  title: 'Voice Satellite entity',
  description: 'The assist_satellite this kiosk announces itself as.',
  category: 'Home Assistant',
  hidden: true,
);

/// What the drawer's kiosk-mode toggle returns to: flipping off remembers
/// the strategy here, flipping back on restores it. Hidden bookkeeping.
const haKioskModeLast = SettingDef<String>(
  key: 'ha.kiosk_mode_last',
  type: SettingType.string,
  defaultValue: 'auto',
  title: 'HA kiosk mode to restore',
  description: 'The strategy the drawer toggle returns to.',
  category: 'Home Assistant',
  hidden: true,
);

const haKioskMode = SettingDef<String>(
  key: 'ha.kiosk_mode',
  type: SettingType.select,
  defaultValue: 'off',
  title: 'HA kiosk mode',
  description:
      'Hide the Home Assistant header and sidebar. Off shows the normal HA '
      'UI. "auto" injects CSS and also uses the kiosk-mode HACS plugin when '
      'detected. Applies immediately, with no restart.',
  category: 'Home Assistant',
  options: ['off', 'auto', 'plugin', 'css'],
  optionLabels: {
    'off': 'Off',
    'auto': 'Auto',
    'plugin': 'Plugin',
    'css': 'CSS',
  },
);

// What kiosk mode actually hides. Both default on (the classic full
// kiosk), but they are separate choices: plenty of dashboards use the
// header tabs as their only navigation.
const haKioskHideHeader = SettingDef<bool>(
  key: 'ha.kiosk_hide_header',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Hide the header',
  description:
      'Hide the dashboard toolbar and view tabs while HA kiosk mode is '
      'on. Leave off if you switch views from the header.',
  category: 'Home Assistant',
);

const haKioskHideSidebar = SettingDef<bool>(
  key: 'ha.kiosk_hide_sidebar',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Hide the sidebar',
  description: 'Hide the navigation sidebar while HA kiosk mode is on.',
  category: 'Home Assistant',
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

const themeAutoApp = SettingDef<bool>(
  key: 'ha.theme_auto_app',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Also switch the app theme',
  description:
      "Flip Kiosk Satellite's own theme (menu, settings) together with "
      'the scheduled Home Assistant change.',
  category: 'Home Assistant',
  section: 'Theme',
  dependsOn: 'ha.theme_auto',
);

// ── Dashboard view rotation ────────────────────────────────────────────
// Cycle through a chosen set of dashboard views forever, each on screen
// for a fixed dwell. Requested for camera-wall / energy-map style setups.
// The view list is custom UI in both settings surfaces (it needs the live
// dashboards + views from HA), so only the JSON selection is stored.

const haRotationEnabled = SettingDef<bool>(
  key: 'ha.rotation_enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable Dashboard view rotation',
  description:
      'Cycle through the selected dashboard views in an endless loop, '
      'showing each one for the chosen number of seconds.',
  category: 'Home Assistant',
  section: 'Dashboard View Rotation',
);

/// JSON array of navigation paths ("url_path/view-route"), in rotation
/// order.
const haRotationDashboards = SettingDef<String>(
  key: 'ha.rotation_dashboards',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Views to rotate',
  description: 'The dashboard views included in the rotation.',
  category: 'Home Assistant',
  hidden: true,
);

const haRotationSeconds = SettingDef<num>(
  key: 'ha.rotation_seconds',
  type: SettingType.number,
  defaultValue: 30,
  title: 'Seconds per view',
  description: 'How long each view stays on screen.',
  category: 'Home Assistant',
  section: 'Dashboard View Rotation',
  dependsOn: 'ha.rotation_enabled',
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
  defaultValue: 'light',
  title: 'App theme',
  description:
      "Light or dark for the app's own screens: menu, settings, "
      'dialogs. System follows the Android setting.',
  category: 'Device',
  options: ['dark', 'light', 'system'],
  optionLabels: {'dark': 'Dark', 'light': 'Light', 'system': 'System'},
);

/// All settings, in display order.
const List<SettingDef<Object>> allSettings = [
  startUrl,
  secureProxy,
  autoReloadOnError,
  pullToRefresh,
  pullToRefreshClearCache,
  pinchToZoom,
  disableCache,
  browserInjectJs,
  allowMixedContent,
  ignoreSslErrors,
  webMicrophone,
  webCamera,
  webGeolocation,
  webAutoplay,
  webPopups,
  kioskEnabled,
  kioskStartOnBoot,
  kioskExitGesture,
  kioskPin,
  kioskDisableStatusBar,
  kioskDisableVolume,
  kioskDisablePower,
  kioskDisableHome,
  kioskDisableContextMenus,
  keepScreenOn,
  setBrightnessOnLaunch,
  defaultBrightness,
  screensaverEnabled,
  screensaverTimeoutSeconds,
  // Pixel shift sits with the general controls: it applies to every mode.
  screensaverPixelShift,
  screensaverMode,
  // One titled panel per mode, in the dropdown's order; only the panel of
  // the selected mode is visible (each setting depends on the mode).
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
  screensaverMediaTransition,
  screensaverLocalFolder,
  screensaverLocalInterval,
  screensaverLocalShuffle,
  screensaverLocalRecursive,
  screensaverLocalTransition,
  screensaverGalleryItems,
  screensaverGalleryInterval,
  screensaverGalleryShuffle,
  screensaverGalleryTransition,
  screensaverWebsiteUrl,
  screensaverDismissOnMotion,
  motionFps,
  motionSensitivity,
  motionCamera,
  wakeWordEnabled,
  wakeWordBackground,
  wakeWordResumeTimeoutSeconds,
  vsSuppressScreensaver,
  haUrl,
  haToken,
  haSatelliteEntity,
  haKioskMode,
  haKioskModeLast,
  haKioskHideHeader,
  haKioskHideSidebar,
  themeAuto,
  themeDarkAt,
  themeLightAt,
  themeAutoApp,
  haRotationEnabled,
  haRotationDashboards,
  haRotationSeconds,
  remoteEnabled,
  remotePort,
  remotePassword,
  deviceName,
  uiTheme,
];
