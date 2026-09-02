/// Declarative setting definitions.
///
/// Every setting is declared exactly once here. The local settings UI, the
/// remote admin UI (via GET /api/settings), and import/export all render or
/// serialize from these definitions — never from ad-hoc keys.
library;

import 'dart:convert';

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
    this.subpage,
    this.options,
    this.secret = false,
    this.dependsOn,
    this.dependsOnValue = true,
    this.alsoDependsOn,
    this.alsoDependsOnValue = true,
    this.hidden = false,
    this.min,
    this.max,
    this.step,
    this.unit,
    this.optionLabels,
    this.validator,
    this.crossValidator,
    this.normalizer,
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

  /// An optional second-level page within [category], One UI style. Settings
  /// sharing a subpage disappear from the category page, which shows a single
  /// entry row in their place (titled with the subpage name, hinted by
  /// [subpageHints]); tapping it opens a page of its own where the settings
  /// render in their usual [section] cards. Both UIs honor it, like [section].
  final String? subpage;

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
  /// boolean-switch case; set to a string to gate on a mode select, or to a
  /// list of them for a row that belongs to more than one mode (the Immich
  /// From date, which both Since and Timeframe want).
  final Object dependsOnValue;

  /// Whether [value] satisfies [dependsOnValue], which is a list when the
  /// row belongs to several modes. Both UIs ask this same question, the
  /// remote's over the serialized definition.
  bool dependsSatisfiedBy(Object? value) => dependsOnValue is List
      ? (dependsOnValue as List).contains(value)
      : value == dependsOnValue;

  /// A second gate, for a row that only means anything under two settings
  /// at once (the flip clock's night card color: Night mode on AND the
  /// Flip style picked). Both must hold, each through its own chain, and
  /// both UIs read it beside [dependsOn]. Search and the subpage rules
  /// follow [dependsOn] alone, so that one is the row's parent.
  final String? alsoDependsOn;

  /// The value [alsoDependsOn] must hold, the shape of [dependsOnValue].
  final Object alsoDependsOnValue;

  bool alsoDependsSatisfiedBy(Object? value) => alsoDependsOnValue is List
      ? (alsoDependsOnValue as List).contains(value)
      : value == alsoDependsOnValue;

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

  /// Like [validator], with the other settings in view, for a value whose
  /// sense depends on a sibling (the two ends of a range). `read(key)` is
  /// what that sibling will hold once this write lands: the value in the
  /// same batch where the batch carries one, else the stored value, so a
  /// batch moving both ends past each other's old positions passes. Runs
  /// after [validator] and only when that accepted the value.
  final String? Function(Object? value, Object? Function(String key) read)?
  crossValidator;

  /// Optional canonicalization applied to every accepted write, after
  /// [validator]. The stored value is the normalized one, so consumers
  /// never have to defend against equivalent spellings — e.g. a base URL
  /// keeps or drops its trailing slash depending on how it was typed, and
  /// only one of those survives `'$base/api/websocket'`.
  ///
  /// Takes and returns [Object] rather than [T]: most callers hold a
  /// `SettingDef<Object>` (via defByKey), and reading a `T`-typed function
  /// field through that covariant view throws at runtime.
  final Object Function(Object value)? normalizer;
}

/// The hint line each subpage's entry row shows on its parent page, keyed by
/// [SettingDef.subpage] — a short list of what moved inside, so the row still
/// says what it holds. Curated rather than generated from the titles, which
/// read clumsily strung together. Served to the remote UI with the
/// definitions.
/// Definitions hidden on this particular device, on top of the static
/// [SettingDef.hidden]: a page that only means something on one kind of
/// hardware (Person Detection, a person sensor the device itself runs) is
/// left out everywhere else rather than shown disabled. Filled once at
/// boot by the manager that knows (before any settings page or remote
/// request renders), and read by the device pages, the search index and
/// the remote's `describe()` alike, so both UIs hide the same rows.
final Set<String> deviceHiddenKeys = {};

const Map<String, String> subpageHints = {
  'User Interface': 'Kiosk mode, dashboard carousel, haptics, tap sounds',
  'Theme': 'Match the app, or switch dark and light on a schedule',
  'Dashboard View Rotation': 'Cycle through views, dwell time, fade',
  'Return to home dashboard view': 'Go back to the home view when left idle',
  'Hold mode': 'Pin the current view, automatic release, menu entry',
  'Optimizations': 'Background connection, screensaver pause, update filter',
  // Voice Satellite. Both pages are mostly live rows from the
  // integration rather than settings, so the pages themselves are
  // placed by the Voice Satellite page; only their names live here.
  'Wake Word': 'Engine, wake words, sensitivity, cached models',
  'Appearance': 'Overlay skin, theme, activity bar, text size',
  // Screen & Audio.
  'Microphone settings': 'Capture mode, channel, gain, live level',
  'Adaptive brightness': 'Follow the room light with the ambient light sensor',
  // Screensaver. The six mode pages only exist while that mode is the
  // one selected, since every setting on them gates on it.
  'Clock screensaver':
      'Style, font, size, colors, night mode, background photo',
  'Home Assistant Media screensaver': 'Media source, timing, shuffle, fill',
  'Local Media screensaver': 'Folder, timing, shuffle, transition',
  'Photo Gallery screensaver': 'Photos, timing, shuffle, transition',
  'Immich Media screensaver': 'Server, media, slideshow, metadata, filters',
  'Camera Streams screensaver': 'Views to show, seconds per view, sound',
  'Widgets': 'Corner overlays and their scale',
  'At a Glance': 'Entities shown over the screensaver',
  'Motion Detection': 'Dismiss or postpone the screensaver on motion',
  'Face Detection': 'Dismiss the screensaver when someone looks at it',
  'Proximity Detection':
      'Dismiss or postpone the screensaver on the proximity sensor',
  'Person Detection':
      "Dismiss or postpone the screensaver on the device's person sensor",
  'Scheduled Screensavers':
      'Switch to a different screensaver at set times of day.',
  // Media Player.
  'Sendspin Player': 'Make this device a synchronized Music Assistant player',
  'Music Assistant': 'Server, token, kiosk menu shortcut',
  'Floating Player': 'The small card over the dashboard',
  'Now Playing': 'Full-screen view while music plays',
  // ESPHome.
  'Notifications': 'Transparency, blur, notification sound, test notification',
  'Bluetooth Proxy': 'Relay nearby Bluetooth devices to Home Assistant',
  'GPS Sensor': 'Expose GPS sensor data to Home Assistant',
  'Advanced settings': 'Real or spoofed Wi-Fi MAC address',
  // Kiosk.
  'Allowed Actions': 'Which quick actions the kiosk menu offers',
  // Device.
  'Kiosk Satellite Service':
      'Status, what keeps it running, required permissions',
  'Remote Administration': 'Manage this kiosk from a browser on your network',
  // Read-only reports the remote admin shows about the tablet; the
  // device's own settings page has no equivalent.
  'Hardware': 'Model, Android version, addresses, memory, uptime',
  'Home Assistant': 'Connection, version and what the kiosk shows',
  'WebView': 'Engine version, renderer and user agent',
};

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

/// Canonical stored form of a base URL: the origin alone. The validator
/// tolerates a bare trailing slash (an easy paste of the address bar), but
/// storing it breaks every consumer that appends a path — the pipeline
/// socket would dial `http://ha:8123//api/websocket`.
String normalizeBaseUrl(String value) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;
  return uri.hasPort
      ? '${uri.scheme}://${uri.host}:${uri.port}'
      : '${uri.scheme}://${uri.host}';
}

/// [SettingDef.normalizer] adapter for [normalizeBaseUrl].
Object normalizeBaseUrlSetting(Object value) =>
    value is String ? normalizeBaseUrl(value) : value;

/// The Immich album pick as the `[{id, name}]` list it is stored as. A
/// bare album id is the shape the setting had while it held one album; it
/// becomes a one-entry list, name left for the Immich manager to fill in
/// from the album name that shipped beside it. Blank means the library.
Object normalizeImmichAlbumsSetting(Object value) {
  if (value is! String) return value;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '[]';
  if (trimmed.startsWith('[')) return trimmed;
  return jsonEncode([
    {'id': trimmed, 'name': ''},
  ]);
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
      'Routes a plain http Home Assistant through an in-app proxy so '
      'the browser unlocks the microphone and other https-only '
      'features. Only for http URLs.',
  category: 'Home Assistant',
  hidden: true,
);

/// Optimizations group: injected scripts that keep the Home Assistant
/// connection healthy and light. Rendered under one heading in both UIs.

/// Auto-disables Home Assistant's "Suspend background connections" preference
/// so the kiosk's socket is not dropped after a few minutes off screen (see
/// disable_suspend_script.dart). On by default: a wall tablet should stay
/// connected.
const disableSuspend = SettingDef<bool>(
  key: 'browser.disable_suspend',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Keep connected in the background',
  description:
      'Turns off Home Assistant\'s "Suspend background connections" setting, '
      'which would otherwise drop the connection a few minutes after the '
      'screen goes off.',
  category: 'Home Assistant',
  section: 'Optimizations',
  subpage: 'Optimizations',
);

/// Stops the dashboard WebView's rendering while the screensaver covers it,
/// by hiding the native view (see WebViewFreeze.kt) so Chromium stops
/// compositing a page nobody can see. The page itself drops to ordinary
/// hidden-document behavior: timers throttled but running, events delivered,
/// websocket consumed — only drawing stops. Enabling it also enables
/// [disableSuspend]: a hidden page is exactly what Home Assistant's suspend
/// preference reacts to. On by default since 0.28: proven across
/// Snapdragon and MediaTek hardware, and the savings (a Tab S8 dropped
/// from 152% to 57% CPU under the screensaver) are what a wall tablet is
/// for.
const freezeOnScreensaver = SettingDef<bool>(
  key: 'browser.freeze_on_screensaver',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Pause dashboard during screensaver',
  description:
      'Stops drawing the dashboard while the screensaver covers it, '
      'cutting CPU and GPU use; the connection stays live. Not for the '
      'Dim screensaver.',
  category: 'Home Assistant',
  section: 'Optimizations',
  subpage: 'Optimizations',
);

/// Filters the HA entity-update stream to just the current view's entities, so
/// low-powered tablets stop processing the whole firehose (see
/// ws_filter_script.dart / issue #8). On by default since 0.28: views whose
/// entities cannot be determined pass through unfiltered, so the worst case
/// is the stock behavior.
const wsFilter = SettingDef<bool>(
  key: 'browser.ws_filter',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Filter dashboard updates',
  description:
      'Only process updates for entities on the current view, cutting '
      'stutter on low-powered tablets. Views that cannot be resolved '
      'stay unfiltered.',
  category: 'Home Assistant',
  section: 'Optimizations',
  subpage: 'Optimizations',
);

const autoReloadOnError = SettingDef<bool>(
  key: 'browser.auto_reload_on_error',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Auto-reload on error',
  description: 'Recover automatically from page failures and app crashes.',
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
      'A pull also clears the web cache and wake word models before '
      'reloading, so everything comes back fresh. Login and saved page '
      'data are kept.',
  category: 'Browser',
  dependsOn: 'browser.pull_to_refresh',
);

const browserZoom = SettingDef<num>(
  key: 'browser.zoom',
  type: SettingType.number,
  defaultValue: 1,
  title: 'Zoom level',
  description:
      'Scales the whole page. Above 1x for wall tablets viewed from a '
      'distance; below 1x fits more dashboard on a small screen.',
  category: 'Browser',
  min: 0.5,
  max: 4,
  step: 0.05,
  unit: 'x',
);

/// How the window treats a camera cutout (punch hole, notch). The kiosk
/// default is to claim the cutout row and withhold the safe-area inset from
/// the page (see CutoutLayout.kt), so Home Assistant never pads its header;
/// dashboards with controls at the very top can avoid the cutout instead
/// (discussion #102). Applied live through the kiosk_lock channel, and read
/// natively from SharedPreferences at Activity creation so the window is
/// right from the first frame. Lives on the Screen & Audio page: it shapes
/// the window, not the browser, even though the key predates the move.
const browserCutoutMode = SettingDef<String>(
  key: 'browser.cutout_mode',
  type: SettingType.select,
  defaultValue: 'always',
  title: 'Display cutout',
  description:
      'What to do with the screen area around a camera cutout or punch '
      'hole. Pick Avoid the cutout if the camera sits on top of buttons at '
      'the top of the dashboard.',
  category: 'Screen & Audio',
  section: 'Screen',
  options: ['always', 'short_edges', 'default', 'never'],
  optionLabels: {
    'always': 'Use the cutout area',
    'short_edges': 'Short edges only',
    'default': 'System default',
    'never': 'Avoid the cutout',
  },
);

const pinchToZoom = SettingDef<bool>(
  key: 'browser.pinch_to_zoom',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable pinch to zoom',
  description:
      'Zoom the page with a two-finger pinch. Off by default so a kiosk '
      'dashboard stays put under stray touches.',
  category: 'Browser',
);

const disableScrolling = SettingDef<bool>(
  key: 'browser.disable_scrolling',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable scrolling',
  description:
      'Lock the page in place so it cannot be scrolled in any direction. '
      'Taps and buttons keep working.',
  category: 'Browser',
);

const disableCache = SettingDef<bool>(
  key: 'browser.disable_cache',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable cache',
  description:
      'Always fetch from the network and drop cached page data on load, '
      'so a redeployed dashboard always comes back fresh. Slow; treat '
      'it as a development aid.',
  category: 'Browser',
);

const browserInjectJs = SettingDef<String>(
  key: 'browser.inject_js',
  type: SettingType.string,
  defaultValue: '',
  title: 'Inject JavaScript on the HA dashboard',
  description:
      'Run this JavaScript code after every load of the dashboard page. '
      'Useful to hide distracting elements or tweak a dashboard you do '
      'not control.',
  category: 'Browser',
  multiline: true,
  placeholder:
      "// Example: hide a distracting element\n"
      "document.querySelector('#banner').style.display = 'none';",
);

const browserInjectJsExternal = SettingDef<String>(
  key: 'browser.inject_js_external',
  type: SettingType.string,
  defaultValue: '',
  title: 'Inject JavaScript on external pages',
  description:
      'Run this JavaScript code after loading each external page: pages '
      'opened by a dashboard link, dashboard rotation pages and the '
      'website screensaver. The Music Assistant page is left alone.',
  category: 'Browser',
  multiline: true,
  placeholder:
      "// Example: zoom a site that ignores the dashboard zoom level\n"
      "document.documentElement.style.zoom = '1.25';",
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
      'Launch Kiosk Satellite when the device powers on. On Android 10+ '
      'this needs the display over other apps permission; Android asks '
      'on first enable.',
  category: 'Kiosk',
);

const kioskExitGesture = SettingDef<String>(
  key: 'kiosk.exit_gesture',
  type: SettingType.select,
  defaultValue: 'taps7',
  title: 'Kiosk exit gesture',
  description:
      'Fast taps anywhere open the menu, after the PIN if one is set. '
      'Hold variants need the last tap held down. When disabled, only '
      'the remote admin can reach settings.',
  category: 'Kiosk',
  options: ['taps5', 'taps7', 'taps5hold', 'taps7hold', 'none'],
  optionLabels: {
    'taps5': '5 fast taps',
    'taps7': '7 fast taps',
    'taps5hold': '5 fast taps, holding the last',
    'taps7hold': '7 fast taps, holding the last',
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
      'Needs the display over other apps permission; Android asks on '
      'first enable.',
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
      'Android cannot block the power button, so the screen turns right '
      'back on when it is pressed. Turning the screen off remotely '
      'still works.',
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

const kioskDisablePullRefresh = SettingDef<bool>(
  key: 'kiosk.disable_pull_to_refresh',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable pull to refresh',
  description: 'Ignore the pull-to-refresh gesture while kiosk mode is on.',
  category: 'Kiosk',
  dependsOn: 'kiosk.enabled',
);

// Gestures themselves are not a kiosk feature: anything configured on the
// Gestures page works whenever the app is running. This is the kiosk-time
// opt-out for the locked-down tablet whose owner wants nothing hidden
// armed while guests hold it.
const kioskDisableGestures = SettingDef<bool>(
  key: 'kiosk.disable_gestures',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Disable Gestures',
  description:
      'Ignore the gestures from the Gestures page while kiosk mode is on.',
  category: 'Kiosk',
  dependsOn: 'kiosk.enabled',
);

// ── Gestures (issue #99) ───────────────────────────────────────────────
//
// The configured mappings as a JSON list of
//   {"id": "...", "trigger": {"type": ..., ...}, "action": {"type": ..., ...}}
// entries. Hand-built editors on the device and in the remote admin write
// it; the generic settings renderer skips it. Trigger shapes and action
// types are documented in managers/gestures/gesture_mappings.dart.
const gestureMappings = SettingDef<String>(
  key: 'gestures.mappings',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Gestures',
  description: 'Gestures and the actions they trigger.',
  category: 'Gestures',
  hidden: true,
);

// Deliberateness thresholds for the clap detector (discussion #177: a child
// playing with toys near the device produced enough clap-shaped impulses to
// false-trigger). Standard already requires a quiet lead-in and consistent
// rhythm and loudness; Strict tightens all three and wants louder claps.
const clapStrictness = SettingDef<String>(
  key: 'gestures.clap_strictness',
  type: SettingType.select,
  defaultValue: 'standard',
  options: ['standard', 'strict'],
  optionLabels: {'standard': 'Standard', 'strict': 'Strict'},
  title: 'Clap detection',
  description:
      'Strict needs louder, evenly spaced claps; try it if household '
      'noise false-triggers.',
  category: 'Gestures',
);

// The quick-actions escape hatch (issue #64): a wall-mounted kiosk in
// lockdown still wants "back to the dashboard" and "show the camera" to
// be one swipe away. Off by default — kiosk mode keeps its full lock
// until the owner opts in — and the menu it opens is restricted to the
// harmless subset picked below; everything else stays behind the exit
// gesture and PIN.

const kioskAllowDrawer = SettingDef<bool>(
  key: 'kiosk.allow_drawer',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Allow menu with quick actions',
  description:
      'An edge swipe opens the menu without the exit gesture or PIN, '
      'limited to the actions selected below.',
  category: 'Kiosk',
  section: 'Allowed Actions',
  subpage: 'Allowed Actions',
  dependsOn: 'kiosk.enabled',
);

const kioskAllowDashboard = SettingDef<bool>(
  key: 'kiosk.allow_dashboard',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Dashboard',
  description: 'Reload the start page.',
  category: 'Kiosk',
  section: 'Allowed Actions',
  subpage: 'Allowed Actions',
  dependsOn: 'kiosk.allow_drawer',
);

const kioskAllowCamera = SettingDef<bool>(
  key: 'kiosk.allow_camera',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Camera View',
  description: 'Open the default camera view.',
  category: 'Kiosk',
  section: 'Allowed Actions',
  subpage: 'Allowed Actions',
  dependsOn: 'kiosk.allow_drawer',
);

const kioskAllowMusic = SettingDef<bool>(
  key: 'kiosk.allow_music',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Music Assistant',
  description: 'Open the Music Assistant web interface.',
  category: 'Kiosk',
  section: 'Allowed Actions',
  subpage: 'Allowed Actions',
  dependsOn: 'kiosk.allow_drawer',
);

const kioskAllowSendspinPlayer = SettingDef<bool>(
  key: 'kiosk.allow_sendspin_player',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Floating Player',
  description: 'Show or hide the floating player and open Now Playing.',
  category: 'Kiosk',
  section: 'Allowed Actions',
  subpage: 'Allowed Actions',
  dependsOn: 'kiosk.allow_drawer',
);

const kioskAllowScreensaver = SettingDef<bool>(
  key: 'kiosk.allow_screensaver',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Start Screensaver',
  description: 'Start the screensaver now.',
  category: 'Kiosk',
  section: 'Allowed Actions',
  subpage: 'Allowed Actions',
  dependsOn: 'kiosk.allow_drawer',
);

const kioskAllowHold = SettingDef<bool>(
  key: 'kiosk.allow_hold',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Hold Mode',
  description: 'Turn hold mode on or off.',
  category: 'Kiosk',
  section: 'Allowed Actions',
  subpage: 'Allowed Actions',
  dependsOn: 'kiosk.allow_drawer',
);

const kioskAllowTheme = SettingDef<bool>(
  key: 'kiosk.allow_theme',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Theme picker',
  description: 'Switch between the light and dark themes.',
  category: 'Kiosk',
  section: 'Allowed Actions',
  subpage: 'Allowed Actions',
  dependsOn: 'kiosk.allow_drawer',
);

const kioskAllowApps = SettingDef<bool>(
  key: 'kiosk.allow_apps',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Apps',
  description:
      'Open the app launcher. With Disable home button on, launching an '
      'app unpins the kiosk until it returns.',
  category: 'Kiosk',
  section: 'Allowed Actions',
  subpage: 'Allowed Actions',
  dependsOn: 'kiosk.allow_drawer',
);

// ── Lockdown Mode (discussion #143) ────────────────────────────────────
// The house-is-empty switch: one toggle that makes the tablet untouchable
// and unhearable without dismantling the owner's kiosk configuration.
// While it holds, every kiosk protection arms whatever its individual
// switch says, and wake word detection is muted; the PIN stays the kiosk
// PIN. Remote-only by design, so the category never appears in the device
// settings rail: the only person standing at a locked tablet is the one
// being locked out, and a device-side toggle would lock out its own
// operator one tap after enabling it. While lockdown is on, its own exit
// gesture below replaces the kiosk one, so the two can share a value
// without ever being armed together.

const lockdownEnabled = SettingDef<bool>(
  key: 'lockdown.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable Lockdown Mode',
  description:
      'Disables screen interactions until turned off either from Home '
      'Assistant or with the exit gesture.',
  category: 'Lockdown',
);

// The blackout variant: the same shield painted solid black. The panel
// stays lit (turning it off would freeze the app and the admin server
// with it, same reasoning as the screensaver's black mode) but the
// dashboard WebView stops compositing underneath via the covered-surface
// freeze, so a blacked-out lockdown costs less power than a visible one.
const lockdownBlackout = SettingDef<bool>(
  key: 'lockdown.blackout',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Blackout screen',
  description: 'Turns the screen black while locked.',
  category: 'Lockdown',
  dependsOn: 'lockdown.enabled',
);

const lockdownAllowScreensaver = SettingDef<bool>(
  key: 'lockdown.allow_screensaver',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Allow screensaver',
  description:
      'Lets the screensaver run while locked. Dismiss on motion stays '
      'deactivated until the lock lifts.',
  category: 'Lockdown',
  dependsOn: 'lockdown.enabled',
);

const lockdownExitGesture = SettingDef<String>(
  key: 'lockdown.exit_gesture',
  type: SettingType.select,
  defaultValue: 'taps7',
  title: 'Lockdown exit gesture',
  description:
      'Fast taps anywhere turn Lockdown Mode off, after the kiosk PIN if '
      'one is set. Hold variants need the last tap held down. When '
      'disabled, only the remote admin or Home Assistant can turn it off.',
  category: 'Lockdown',
  options: ['taps5', 'taps7', 'taps5hold', 'taps7hold', 'none'],
  optionLabels: {
    'taps5': '5 fast taps',
    'taps7': '7 fast taps',
    'taps5hold': '5 fast taps, holding the last',
    'taps7hold': '7 fast taps, holding the last',
    'none': 'Disabled (remote only)',
  },
  dependsOn: 'lockdown.enabled',
);

// ── App Launcher ───────────────────────────────────────────────────────
// The minimal app selector (issue #114): a dedicated kiosk that doubles as
// a media player or alarm clock needs a sanctioned way into a few other
// apps without leaving lockdown. The owner picks the apps; the launcher
// overlay offers exactly those and nothing else. Its own settings page:
// the launcher works with or without kiosk mode, so it does not live
// under the lockdown settings.

// Master switch, off by default. While off the launcher is genuinely
// gone, not just empty: no menu entry, showAppLauncher refuses (which
// covers the remote API), and the MQTT button is retracted from HA.
const launcherEnabled = SettingDef<bool>(
  key: 'launcher.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable App Launcher',
  description: 'Open a picked set of installed apps from the kiosk.',
  category: 'Launcher',
);

// The chosen apps as a JSON list of {package, label}. Hand-built pickers
// on the device and in the remote admin write it; the generic settings
// renderer skips it (a raw JSON field is not something to type). Labels
// are cached at pick time so both UIs can show names offline.
const launcherApps = SettingDef<String>(
  key: 'launcher.apps',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Apps',
  description: 'The apps the launcher offers.',
  category: 'Launcher',
  dependsOn: 'launcher.enabled',
);

// The way back without a gesture or a hand: after an app opened through
// launchApp (the launcher, a gesture, MQTT), an idle clock brings the
// kiosk to the front again. Idle, not elapsed (issue #317): a touch
// watch window restarts the clock on every touch in the other app, so
// someone using it is not pulled out mid-task. Uses the same bringToFront
// as the wake word, so on Android 10+ it needs the draw-over-apps grant,
// which the touch watch rides too; enabling this fires the grant screen
// when it is missing (see AppLauncherManager).
const launcherAutoReturn = SettingDef<bool>(
  key: 'launcher.auto_return',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Return automatically',
  description:
      'Come back to the kiosk once the other app has gone untouched for '
      'a while.',
  category: 'Launcher',
  dependsOn: 'launcher.enabled',
);

const launcherAutoReturnSeconds = SettingDef<num>(
  key: 'launcher.auto_return_seconds',
  type: SettingType.number,
  defaultValue: 300,
  min: 10,
  title: 'Return after (seconds)',
  description:
      'Time without a touch in the other app before the kiosk comes back.',
  category: 'Launcher',
  dependsOn: 'launcher.auto_return',
);

// ── Home Launcher ──────────────────────────────────────────────────────
// The HOME role (issue #219): the kiosk registers as the device's home
// app and replaces the OEM launcher outright. The system starts it at
// boot itself (no stock-launcher flash) and every HOME press lands on the
// kiosk with no pinning and no consent dialog. The safety net is native
// (HomeFuse): a kiosk that crash-loops while holding HOME hands the role
// back to the OEM launcher on its own, so nobody is ever stranded.

const homeLauncherEnabled = SettingDef<bool>(
  key: 'home.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Act as the home screen',
  description:
      'Register Kiosk Satellite as the device home screen: the kiosk starts '
      'at boot and every home press returns to it. Turns itself off and '
      'restores the previous launcher if the app fails to start '
      'repeatedly.',
  category: 'Home',
);

// The role already makes HOME land on the kiosk, so on devices without
// device ownership the consent-gated pin is skipped by default; this
// turns it back on for the native recents/back blocking it still buys.
// Device-owner installs pin silently either way and ignore this.
const homeKeepPinning = SettingDef<bool>(
  key: 'home.keep_pinning',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Keep screen pinning',
  description:
      'Pin the screen even while Kiosk Satellite is the home screen. Blocks '
      'recents and back natively, but brings back the pinning '
      'confirmation dialog on devices without device ownership.',
  category: 'Home',
  dependsOn: 'home.enabled',
);

// ── Screen & Audio ─────────────────────────────────────────────────────

// What the last screen-off actually did to the panel: on some devices the
// display never goes dark, because the ROM lights an always-on clock the
// moment lockNow puts the device to sleep (issue #51). Learned by looking
// rather than asked, because the setting behind it reads as "unset" while
// the ROM default has it on. Hidden: it reports the device, it does not
// configure it.
const screenAmbientDisplay = SettingDef<bool>(
  key: 'screen.ambient_display',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Device keeps the panel lit',
  description:
      'Whether turning the screen off leaves this device showing an ambient '
      'lock screen.',
  category: 'Screen & Audio',
  hidden: true,
);

const keepScreenOn = SettingDef<bool>(
  key: 'screen.keep_on',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Keep screen on',
  description: 'Prevent the OS from turning the screen off.',
  category: 'Screen & Audio',
  section: 'Screen',
);

// Off by default: a slider with no gate would override every device's
// OS-managed brightness the moment it upgrades.
const setBrightnessOnLaunch = SettingDef<bool>(
  key: 'screen.set_brightness_on_launch',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Set brightness on launch',
  description: 'Apply the default brightness whenever the app starts.',
  category: 'Screen & Audio',
  section: 'Screen',
);

const defaultBrightness = SettingDef<num>(
  key: 'screen.default_brightness',
  type: SettingType.number,
  defaultValue: 0.8,
  title: 'Default brightness',
  description:
      'Screen brightness applied when the app starts. Moving the slider '
      'applies it immediately.',
  category: 'Screen & Audio',
  section: 'Screen',
  min: 0,
  max: 1,
  step: 0.05,
  unit: '%',
  dependsOn: 'screen.set_brightness_on_launch',
);

// Adaptive brightness (issue #343): the room's light sets the screen
// brightness on the device itself, so the mapping keeps working with Home
// Assistant unreachable. Its own page: the switch, the live sensor reading,
// the two brightness ends and the two light-level ends of the curve. The
// screensaver and Dim sliders keep their meaning as the level in a bright
// room and scale with the curve; Default brightness stands down while the
// switch is on.
const adaptiveBrightness = SettingDef<bool>(
  key: 'screen.adaptive_brightness',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Adaptive brightness',
  description:
      'Dim the screen as the room gets darker, using the ambient light '
      'sensor.',
  category: 'Screen & Audio',
  subpage: 'Adaptive brightness',
  section: 'Adaptive brightness',
);

const adaptiveMinBrightness = SettingDef<num>(
  key: 'screen.adaptive_min_brightness',
  type: SettingType.number,
  defaultValue: 0.15,
  title: 'Minimum brightness',
  description: 'Screen brightness in a dark room.',
  category: 'Screen & Audio',
  subpage: 'Adaptive brightness',
  section: 'Adaptive brightness',
  min: 0,
  max: 1,
  step: 0.05,
  unit: '%',
  dependsOn: 'screen.adaptive_brightness',
  crossValidator: validateMinBelowMax,
);

const adaptiveMaxBrightness = SettingDef<num>(
  key: 'screen.adaptive_max_brightness',
  type: SettingType.number,
  defaultValue: 0.8,
  title: 'Maximum brightness',
  description: 'Screen brightness in a bright room.',
  category: 'Screen & Audio',
  subpage: 'Adaptive brightness',
  section: 'Adaptive brightness',
  min: 0,
  max: 1,
  step: 0.05,
  unit: '%',
  dependsOn: 'screen.adaptive_brightness',
  crossValidator: validateMaxAboveMin,
);

// Typed, not slid: light sensors disagree wildly about what a lit room
// reads (an Echo Show 8 reports about 50 lx with every light on, a tablet
// by a window thousands), so the ends are set against the live reading
// shown above them rather than against a fixed scale.
const adaptiveDarkLux = SettingDef<num>(
  key: 'screen.adaptive_dark_lux',
  type: SettingType.number,
  defaultValue: 5,
  title: 'Dark room (lx)',
  description:
      'Light level at or below which the screen sits at Minimum brightness.',
  category: 'Screen & Audio',
  subpage: 'Adaptive brightness',
  section: 'Adaptive brightness',
  dependsOn: 'screen.adaptive_brightness',
  validator: validateLux,
  crossValidator: validateDarkBelowBright,
);

const adaptiveBrightLux = SettingDef<num>(
  key: 'screen.adaptive_bright_lux',
  type: SettingType.number,
  defaultValue: 300,
  title: 'Bright room (lx)',
  description:
      'Light level at or above which the screen sits at Maximum brightness.',
  category: 'Screen & Audio',
  subpage: 'Adaptive brightness',
  section: 'Adaptive brightness',
  dependsOn: 'screen.adaptive_brightness',
  validator: validateLux,
  crossValidator: validateBrightAboveDark,
);

/// A light level the curve can take a log of: a positive number.
String? validateLux(Object? value) {
  final lux = value is num ? value : num.tryParse('${value ?? ''}'.trim());
  if (lux == null || lux <= 0 || lux > 200000) {
    return 'Enter a light level above 0 lx';
  }
  return null;
}

/// The curve's ends must not cross or meet: Dark room below Bright room.
String? validateDarkBelowBright(
  Object? value,
  Object? Function(String key) read,
) {
  final dark = _asNum(value);
  final bright = _asNum(read(adaptiveBrightLux.key));
  if (dark == null || bright == null || dark < bright) return null;
  return 'Dark room must be below Bright room (${_formatLux(bright)} lx)';
}

String? validateBrightAboveDark(
  Object? value,
  Object? Function(String key) read,
) {
  final bright = _asNum(value);
  final dark = _asNum(read(adaptiveDarkLux.key));
  if (dark == null || bright == null || bright > dark) return null;
  return 'Bright room must be above Dark room (${_formatLux(dark)} lx)';
}

/// The curve's brightness ends, the same way: Minimum below Maximum, or
/// the room's light has nothing to move between.
String? validateMinBelowMax(Object? value, Object? Function(String key) read) {
  final min = _asNum(value);
  final max = _asNum(read(adaptiveMaxBrightness.key));
  if (min == null || max == null || min < max) return null;
  return 'Minimum brightness must be below Maximum brightness '
      '(${(max * 100).round()}%)';
}

String? validateMaxAboveMin(Object? value, Object? Function(String key) read) {
  final max = _asNum(value);
  final min = _asNum(read(adaptiveMinBrightness.key));
  if (min == null || max == null || max > min) return null;
  return 'Maximum brightness must be above Minimum brightness '
      '(${(min * 100).round()}%)';
}

num? _asNum(Object? value) =>
    value is num ? value : num.tryParse('${value ?? ''}'.trim());

String _formatLux(num lux) =>
    lux == lux.roundToDouble() ? lux.toInt().toString() : lux.toString();

// ── Audio ──────────────────────────────────────────────────────────────
// The mixer model (issue #79): the master volume is the device's own (a
// live hardware level, not a setting - the Audio page hand-builds its
// slider), and these two faders scale under it, independent of each other.

const mediaVolume = SettingDef<num>(
  key: 'audio.media_volume',
  type: SettingType.number,
  defaultValue: 100,
  min: 0,
  max: 100,
  step: 5,
  unit: '%',
  title: 'Media volume',
  description:
      'Music and video play at this share of the master volume. The '
      'Sendspin player volume in Music Assistant moves this slider.',
  category: 'Screen & Audio',
  section: 'Audio Volume',
);

const assistantVolume = SettingDef<num>(
  key: 'audio.assistant_volume',
  type: SettingType.number,
  defaultValue: 100,
  min: 0,
  max: 100,
  step: 5,
  unit: '%',
  title: 'Assistant volume',
  description:
      'Voice responses and chimes play at this share of the master '
      'volume, independent of the media volume.',
  category: 'Screen & Audio',
  section: 'Audio Volume',
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

// The four corners an overlay can sit in, shared by the screensaver widgets
// and the Immich metadata panel — one vocabulary, and their dropdowns stay
// in step.
const cornerOptions = ['top_left', 'top_right', 'bottom_left', 'bottom_right'];
const cornerLabels = {
  'top_left': 'Top left',
  'top_right': 'Top right',
  'bottom_left': 'Bottom left',
  'bottom_right': 'Bottom right',
};

// ── Widgets (small corner overlays, over every mode their type allows) ──
//
// One JSON list drives the whole group; both UIs edit it in place (see
// screensaver_widgets.dart for the shape). Replaces the mini clock settings
// below, which migrate into a clock entry on startup.

const screensaverWidgets = SettingDef<String>(
  key: 'screensaver.widgets',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Widgets',
  description: 'Small overlays in the corners of the screensaver.',
  category: 'Screensaver',
  section: 'Widgets',
  subpage: 'Widgets',
);

// One knob for every widget rather than per-entry sizes: the corners all
// sit on the same panel, so they want the same correction.
const screensaverWidgetScale = SettingDef<num>(
  key: 'screensaver.widget_scale',
  type: SettingType.number,
  defaultValue: 100,
  title: 'Widget scaling',
  description: 'Scale all widgets to better fit your screen size.',
  category: 'Screensaver',
  section: 'Widgets',
  subpage: 'Widgets',
  min: 50,
  max: 150,
  step: 5,
  unit: '%',
);

// One knob for every widget's corner vignette: the corners all sit on the
// same panel, so they want the same darkness. The value is the darkness at
// the corner itself; 80 is the look every install had before the slider,
// and 0 paints nothing at all. The Immich metadata overlay has its own
// slider (screensaverImmichVignetteStrength): a photo frame may want the
// clock backed and the photo's details bare, or the other way around.
const screensaverVignetteStrength = SettingDef<num>(
  key: 'screensaver.vignette_strength',
  type: SettingType.number,
  defaultValue: 80,
  title: 'Vignette strength',
  description:
      'Darkness of the shading behind the widgets, for readability on '
      'bright photos. 0 turns it off.',
  category: 'Screensaver',
  section: 'Widgets',
  subpage: 'Widgets',
  min: 0,
  max: 100,
  step: 5,
  unit: '%',
);

// ── Small clock (legacy; now a Widgets entry) ──
//
// Hidden since the Widgets group replaced these rows: they stay registered
// so old backups still import, and the screensaver manager folds an enabled
// small clock into a clock widget on startup and after an import.

const screensaverMiniClock = SettingDef<bool>(
  key: 'screensaver.mini_clock',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Small clock',
  description:
      'Show a small clock in a corner of the screensaver. Not for the '
      'Clock and Camera Streams modes.',
  category: 'Screensaver',
  hidden: true,
);

const screensaverMiniClockPosition = SettingDef<String>(
  key: 'screensaver.mini_clock_position',
  type: SettingType.select,
  defaultValue: 'top_right',
  title: 'Clock position',
  description: 'Which corner the clock sits in.',
  category: 'Screensaver',
  options: cornerOptions,
  optionLabels: cornerLabels,
  dependsOn: 'screensaver.mini_clock',
  hidden: true,
);

const screensaverMiniClockColor = SettingDef<String>(
  key: 'screensaver.mini_clock_color',
  type: SettingType.string,
  // Stored as "r,g,b"; both UIs render a real color picker for it.
  defaultValue: '250,250,250',
  title: 'Clock color',
  description: 'The color of the clock text.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mini_clock',
  hidden: true,
);

const screensaverMiniClock24h = SettingDef<bool>(
  key: 'screensaver.mini_clock_24h',
  type: SettingType.boolean,
  defaultValue: false,
  title: '24-hour clock',
  description: 'Show a 24-hour time instead of AM/PM.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mini_clock',
  hidden: true,
);

const screensaverMiniClockDate = SettingDef<bool>(
  key: 'screensaver.mini_clock_date',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show date',
  description: 'Add a short date under the clock.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mini_clock',
  hidden: true,
);

const screensaverMode = SettingDef<String>(
  key: 'screensaver.mode',
  type: SettingType.select,
  defaultValue: 'black',
  title: 'Screensaver mode',
  description:
      'What the screensaver shows after the idle timeout. Dim only '
      'lowers the backlight and leaves the dashboard on screen.',
  category: 'Screensaver',
  options: [
    'dim',
    'black',
    'clock',
    'media',
    'local',
    'gallery',
    'immich',
    'website',
    'camera',
  ],
  optionLabels: {
    'dim': 'Dim',
    'black': 'Black',
    'clock': 'Clock',
    'media': 'Home Assistant Media',
    'local': 'Local Media',
    'gallery': 'Photo Gallery',
    'immich': 'Immich Media',
    'website': 'Website',
    'camera': 'Camera Streams',
  },
);

// ── Black (mode: black) ──

// The Black panel's one control (issue #151): people schedule Black
// overnight and expect a dark panel, but the small clock and the At a
// Glance row deliberately ride over Black. One switch blanks the overlays
// rather than making each of them schedule-aware.
const screensaverBlackHideExtras = SettingDef<bool>(
  key: 'screensaver.black_hide_extras',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Hide all extras',
  description:
      'Keeps the screen fully black: no small clock, At a Glance '
      'entities, or other overlays.',
  category: 'Screensaver',
  section: 'Black screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'black',
);

// ── Clock (mode: clock) ──

// The face the clock draws (issue #56). Digital is the original text clock;
// Flip is the split-flap card clock; Roller is the oversized cropped digits
// that roll upward as time advances (as on the Lenovo Smart Clock 2). The
// digital-only rows (seconds, date, color) key their visibility off this,
// and each of the other faces brings its own color pair.
const screensaverClockStyle = SettingDef<String>(
  key: 'screensaver.clock_style',
  type: SettingType.select,
  defaultValue: 'digital',
  title: 'Style',
  description: 'How the clock is drawn.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  options: ['digital', 'flip', 'roller'],
  optionLabels: {
    'digital': 'Digital Clock',
    'flip': 'Flip Clock',
    'roller': 'Roller Clock',
  },
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
);

// The typeface, any face (issue #391): the app's own Rubik plus Android's
// generic families, resolved through the platform font manager. What each
// generic maps to is the ROM's call (AOSP serves Noto Serif, Dancing
// Script, Coming Soon; Fire OS substitutes Amazon's faces), which is the
// point: the clock wears the device's own serif, not a specific one. Two
// bundled exceptions for looks no system font has: Nunito (the rounded
// Apple StandBy face the issue's screenshot shows) and LCD, DSEG14
// (28 KB), the LED alarm clock. clockFontFamily (clock_faces.dart) maps
// the stored value to the family name.
const screensaverClockFont = SettingDef<String>(
  key: 'screensaver.clock_font',
  type: SettingType.select,
  defaultValue: 'rubik',
  title: 'Font Family',
  description: 'The typeface the clock is drawn in.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  options: [
    'rubik',
    'nunito',
    'inter',
    'system',
    'serif',
    'condensed',
    'monospace',
    'casual',
    'cursive',
    'lcd',
  ],
  optionLabels: {
    'rubik': 'Rubik',
    'nunito': 'Nunito',
    'inter': 'Inter',
    'system': 'System',
    'serif': 'Serif',
    'condensed': 'Condensed',
    'monospace': 'Monospace',
    'casual': 'Casual',
    'cursive': 'Cursive',
    'lcd': 'LCD',
  },
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
);

/// How heavy the digits are drawn, on every face. Default is each face's
/// own weight (the digital face light, or heavy in Nunito; the flip cards
/// regular; the roller heavy), the rest a fixed weight. Rubik and Nunito
/// are variable fonts, so every step is real; the LCD segments have one
/// weight and ignore this.
const screensaverClockFontWeight = SettingDef<String>(
  key: 'screensaver.clock_font_weight',
  type: SettingType.select,
  defaultValue: 'default',
  title: 'Font weight',
  description:
      "How heavy the clock's digits are drawn. Default is each face's own "
      'weight.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  options: ['default', 'light', 'regular', 'medium', 'bold', 'black'],
  optionLabels: {
    'default': 'Default',
    'light': 'Light',
    'regular': 'Regular',
    'medium': 'Medium',
    'bold': 'Bold',
    'black': 'Black',
  },
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
);

const screensaverClock24h = SettingDef<bool>(
  key: 'screensaver.clock_24h',
  type: SettingType.boolean,
  defaultValue: false,
  title: '24-hour clock',
  description: 'Show a 24-hour time instead of AM/PM.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
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
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'digital',
);

const screensaverClockDate = SettingDef<bool>(
  key: 'screensaver.clock_show_date',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Show date',
  description: 'Show the weekday and date under the clock.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'digital',
);

const screensaverClockScale = SettingDef<num>(
  key: 'screensaver.clock_scale',
  type: SettingType.number,
  defaultValue: 100,
  title: 'Clock size',
  description: 'Scale the clock from 50 to 300 percent for this screen.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
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
  // Stored as "r,g,b"; both UIs render a real color picker for it.
  defaultValue: '250,250,250',
  title: 'Clock color',
  description: 'The color of the clock text.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'digital',
);

// The color behind the digital clock (issue #173): e-ink panels want the
// whole face inverted, black digits on white, and until this setting the
// backdrop was hardcoded black. Flip and Roller already have their own.
const screensaverClockBgColor = SettingDef<String>(
  key: 'screensaver.clock_bg_color',
  type: SettingType.string,
  defaultValue: '0,0,0',
  title: 'Background color',
  description: 'The color behind the clock.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'digital',
);

// A local photo behind the clock (issue #132), any face. The device picker
// stores the path of a copy in app documents, made when the photo is
// picked; the original may live in picker cache the OS purges. The remote
// admin and the MQTT Clock background entity (issue #150) write a raw
// device path into the same setting instead — the renderer fails soft on
// a missing file, so an unvalidated path costs nothing.
const screensaverClockBackground = SettingDef<String>(
  key: 'screensaver.clock_background',
  type: SettingType.string,
  defaultValue: '',
  title: 'Background photo',
  description: 'Show a photo behind the clock instead of the solid color.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
  placeholder: 'Path to an image on the device',
);

// One color set per face rather than a shared one: visibility can only
// key off a single setting value, and each face wants its own defaults.
// Flip defaults to the OLED-friendly look of the issue #391 reference,
// light digits on near-black cards over a pure black wall.

const screensaverFlipDigitColor = SettingDef<String>(
  key: 'screensaver.flip_digit_color',
  type: SettingType.string,
  defaultValue: '250,250,250',
  title: 'Digit color',
  description: 'The color of the flip digits.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'flip',
);

// Key says bg for historical reasons; this is the card face. The wall
// behind the cards is flip_backdrop_color below, its own picker since the
// derived shade the wall used to take read as an unwanted gradient on
// OLED panels (issue #391).
const screensaverFlipBgColor = SettingDef<String>(
  key: 'screensaver.flip_bg_color',
  type: SettingType.string,
  defaultValue: '20,20,20',
  title: 'Card color',
  description: 'The color of the cards.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'flip',
);

const screensaverFlipBackdropColor = SettingDef<String>(
  key: 'screensaver.flip_backdrop_color',
  type: SettingType.string,
  defaultValue: '0,0,0',
  title: 'Background color',
  description: 'The color behind the cards.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'flip',
);

const screensaverRollerDigitColor = SettingDef<String>(
  key: 'screensaver.roller_digit_color',
  type: SettingType.string,
  defaultValue: '250,250,250',
  title: 'Digit color',
  description: 'The color of the rolling digits.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'roller',
);

const screensaverRollerBgColor = SettingDef<String>(
  key: 'screensaver.roller_bg_color',
  type: SettingType.string,
  defaultValue: '0,0,0',
  title: 'Background color',
  description: 'The color behind the digits.',
  category: 'Screensaver',
  section: 'Clock screensaver',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'roller',
);

// ── Night mode (issue #391) ──
//
// In a dark room the digits take a color of their own, dim red by
// default, the way a bedside clock stays readable without lighting the
// room. Driven by the ambient light sensor: on a device without one the
// switch renders disabled with the reason (settings_screen.dart and
// notices.js both key off the same probe adaptive brightness uses).

const screensaverClockNight = SettingDef<bool>(
  key: 'screensaver.clock_night',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Night mode',
  description: 'Recolor the clock while the room is dark.',
  category: 'Screensaver',
  section: 'Night mode',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
);

// A slider, unlike the adaptive curve's typed ends: this threshold only
// has to mean "dark", and 1 to 100 lx covers what any sensor calls a dark
// room, where the curve's bright end has no usable fixed scale.
const screensaverClockNightLux = SettingDef<num>(
  key: 'screensaver.clock_night_lux',
  type: SettingType.number,
  defaultValue: 5,
  title: 'Light level',
  description: 'At or below this light level the clock takes the night color.',
  category: 'Screensaver',
  section: 'Night mode',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_night',
  min: 1,
  max: 100,
  step: 1,
  unit: ' lx',
);

const screensaverClockNightColor = SettingDef<String>(
  key: 'screensaver.clock_night_color',
  type: SettingType.string,
  defaultValue: '130,34,34',
  title: 'Night color',
  description: 'The color of the clock and the widgets in the dark.',
  category: 'Screensaver',
  section: 'Night mode',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_night',
);

// The backdrop in the dark, pure black by default: a face tuned for a lit
// room (an inverted e-ink pair, the flip clock's shaded wall) should not
// keep glowing at night. Takes the whole screen behind any face; the flip
// cards keep their own color on top of it.
const screensaverClockNightBgColor = SettingDef<String>(
  key: 'screensaver.clock_night_bg_color',
  type: SettingType.string,
  defaultValue: '0,0,0',
  title: 'Night background',
  description: 'The color behind the clock in the dark.',
  category: 'Screensaver',
  section: 'Night mode',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_night',
);

// The flip cards in the dark: the one part of a face the night background
// does not cover, and a card color tuned for daylight kept glowing on the
// night's black wall. Near-black by default, the day card default, so a
// stock flip clock looks the same at night with or without this row. Only
// with the Flip style picked, since no other face has cards.
const screensaverClockNightCardColor = SettingDef<String>(
  key: 'screensaver.clock_night_card_color',
  type: SettingType.string,
  defaultValue: '20,20,20',
  title: 'Night card color',
  description: 'The color of the flip cards in the dark.',
  category: 'Screensaver',
  section: 'Night mode',
  subpage: 'Clock screensaver',
  dependsOn: 'screensaver.clock_night',
  alsoDependsOn: 'screensaver.clock_style',
  alsoDependsOnValue: 'flip',
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
  section: 'Home Assistant Media screensaver',
  subpage: 'Home Assistant Media screensaver',
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
  section: 'Home Assistant Media screensaver',
  subpage: 'Home Assistant Media screensaver',
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
  section: 'Home Assistant Media screensaver',
  subpage: 'Home Assistant Media screensaver',
  dependsOn: 'screensaver.media_is_folder',
);

const screensaverMediaShuffle = SettingDef<bool>(
  key: 'screensaver.media_shuffle',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Shuffle',
  description: 'Play a folder in random order.',
  category: 'Screensaver',
  section: 'Home Assistant Media screensaver',
  subpage: 'Home Assistant Media screensaver',
  dependsOn: 'screensaver.media_is_folder',
);

const screensaverMediaRecursive = SettingDef<bool>(
  key: 'screensaver.media_recursive',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Include subfolders',
  description: 'Descend into subfolders when a folder is chosen.',
  category: 'Screensaver',
  section: 'Home Assistant Media screensaver',
  subpage: 'Home Assistant Media screensaver',
  dependsOn: 'screensaver.media_is_folder',
);

// One set of transitions shared by every slideshow mode — a person who
// switches modes should not have to relearn the vocabulary. 'Ken Burns'
// is the slow drifting zoom of documentary photo pans; stills only —
// motion on top of motion just looks broken, so videos fall back to a
// crossfade.
// 'random' rolls one of the real transitions per hand-off ('none' is
// excluded from the pool — a surprise hard cut just reads as a glitch).
const _transitionOptions = [
  'none',
  'fade',
  'slide',
  'zoom',
  'kenburns',
  'random',
];
const _transitionLabels = {
  'none': 'None',
  'fade': 'Crossfade',
  'slide': 'Slide',
  'zoom': 'Zoom',
  'kenburns': 'Ken Burns',
  'random': 'Random',
};

// How far a photo may be cropped to reach the edges of the panel, shared by
// every photo mode. 'smart' is the old "Fill the screen" switch on: crop
// only a photo already shaped close to the panel, and frame the rest over a
// blurred copy of themselves. 'always' takes the crop whatever it costs,
// which is what someone showing 4:3 camera shots on a 2:1 panel is asking
// for when they say the bars bother them more than the missing sky.
const _fillOptions = ['off', 'smart', 'always'];
const _fillLabels = {'off': 'Off', 'smart': 'Smart', 'always': 'Always'};
const _fillDescription =
    'Off keeps the whole photo between black bars. Smart enlarges photos '
    'shaped close to the screen, framing the rest over a blurred backdrop. '
    'Always enlarges every photo, cutting off what does not fit.';

const screensaverMediaTransition = SettingDef<String>(
  key: 'screensaver.media_transition',
  type: SettingType.select,
  defaultValue: 'fade',
  title: 'Transition',
  description: 'How one item hands off to the next.',
  category: 'Screensaver',
  section: 'Home Assistant Media screensaver',
  subpage: 'Home Assistant Media screensaver',
  options: _transitionOptions,
  optionLabels: _transitionLabels,
  dependsOn: 'screensaver.media_is_folder',
);

// Gates on the mode, not on the folder flag: a single image wants filling
// as much as a folder of them does. Videos and camera streams keep their
// frame, as in every other mode.
const screensaverMediaFill = SettingDef<String>(
  key: 'screensaver.media_fill',
  type: SettingType.select,
  defaultValue: 'smart',
  title: 'Fill the screen',
  description: _fillDescription,
  category: 'Screensaver',
  section: 'Home Assistant Media screensaver',
  subpage: 'Home Assistant Media screensaver',
  options: _fillOptions,
  optionLabels: _fillLabels,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'media',
);

// ── Website (mode: website) ──

const screensaverWebsiteUrl = SettingDef<String>(
  key: 'screensaver.website_url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Website URL',
  description: 'A page to show full-screen. It must allow being embedded.',
  category: 'Screensaver',
  section: 'Website screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'website',
);

// The website's own zoom level, since a page built for a monitor lands a
// little large on a wall tablet (a Magic Frame at 1x). The same viewport
// scale the Browser page's Zoom level uses, applied to this WebView only.
const screensaverWebsiteZoom = SettingDef<num>(
  key: 'screensaver.website_zoom',
  type: SettingType.number,
  defaultValue: 1,
  title: 'Zoom level',
  description: 'Scales the whole external screensaver webview.',
  category: 'Screensaver',
  section: 'Website screensaver',
  min: 0.5,
  max: 4,
  step: 0.05,
  unit: 'x',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'website',
);

const screensaverWebsiteDoubleTap = SettingDef<bool>(
  key: 'screensaver.website_double_tap',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Double tap to dismiss',
  description: 'Single taps interact with the website instead of dismissing.',
  category: 'Screensaver',
  section: 'Website screensaver',
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
  section: 'Photo Gallery screensaver',
  subpage: 'Photo Gallery screensaver',
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
  section: 'Photo Gallery screensaver',
  subpage: 'Photo Gallery screensaver',
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
  section: 'Photo Gallery screensaver',
  subpage: 'Photo Gallery screensaver',
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
  section: 'Photo Gallery screensaver',
  subpage: 'Photo Gallery screensaver',
  options: _transitionOptions,
  optionLabels: _transitionLabels,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'gallery',
);

const screensaverGalleryFill = SettingDef<String>(
  key: 'screensaver.gallery_fill',
  type: SettingType.select,
  defaultValue: 'smart',
  title: 'Fill the screen',
  description: _fillDescription,
  category: 'Screensaver',
  section: 'Photo Gallery screensaver',
  subpage: 'Photo Gallery screensaver',
  options: _fillOptions,
  optionLabels: _fillLabels,
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
  section: 'Local Media screensaver',
  subpage: 'Local Media screensaver',
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
  section: 'Local Media screensaver',
  subpage: 'Local Media screensaver',
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
  section: 'Local Media screensaver',
  subpage: 'Local Media screensaver',
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
  section: 'Local Media screensaver',
  subpage: 'Local Media screensaver',
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
  section: 'Local Media screensaver',
  subpage: 'Local Media screensaver',
  options: _transitionOptions,
  optionLabels: _transitionLabels,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'local',
);

const screensaverLocalFill = SettingDef<String>(
  key: 'screensaver.local_fill',
  type: SettingType.select,
  defaultValue: 'smart',
  title: 'Fill the screen',
  description: _fillDescription,
  category: 'Screensaver',
  section: 'Local Media screensaver',
  subpage: 'Local Media screensaver',
  options: _fillOptions,
  optionLabels: _fillLabels,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'local',
);

// ── Immich Media (mode: immich) ──
//
// Photos and videos straight from an Immich server over its HTTP API. The
// connection is validated explicitly (a URL typo should fail at the button,
// not silently at 2am): the source, playlist and cache settings all gate on
// immich_validated, which the manager clears whenever the URL or key change.

const screensaverImmichUrl = SettingDef<String>(
  key: 'screensaver.immich_url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Server address',
  description: 'The address of your Immich server, with its port.',
  placeholder: 'http://immich.local:2283',
  category: 'Screensaver',
  section: 'Server Connection',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'immich',
);

const screensaverImmichApiKey = SettingDef<String>(
  key: 'screensaver.immich_api_key',
  type: SettingType.password,
  defaultValue: '',
  title: 'API key',
  description: 'Created in Immich under Account Settings → API Keys.',
  category: 'Screensaver',
  section: 'Server Connection',
  subpage: 'Immich Media screensaver',
  secret: true,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'immich',
);

// Set by the immichValidate command, cleared by the manager when the URL or
// key change. Every row below gates on it, so the picker and playlist
// controls only exist once the server has actually answered.
const screensaverImmichValidated = SettingDef<bool>(
  key: 'screensaver.immich_validated',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Connection validated',
  description: '',
  category: 'Screensaver',
  section: 'Server Connection',
  subpage: 'Immich Media screensaver',
  hidden: true,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'immich',
);

// The albums as [{id, name}], or an empty list for the whole library.
// Ticked off the immichAlbums command's list in both UIs, never typed. Older
// installs stored one bare album id here; the normalizer folds that into
// the list and the manager fills in its name.
const screensaverImmichAlbum = SettingDef<String>(
  key: 'screensaver.immich_album',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Media source',
  description: 'The whole library, or the albums you pick.',
  normalizer: normalizeImmichAlbumsSetting,
  category: 'Screensaver',
  section: 'Media',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

// Motion/Live photos often land in Immich as short video assets, which make
// for a choppy slideshow next to stills (issue #32).
const screensaverImmichPhotosOnly = SettingDef<bool>(
  key: 'screensaver.immich_photos_only',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Photos only',
  description: 'Skip videos in the slideshow.',
  category: 'Screensaver',
  section: 'Media',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

// The name of the one album older installs stored in immich_album, kept so
// a migrated or imported pick keeps its name. Nothing writes it any more.
const screensaverImmichAlbumName = SettingDef<String>(
  key: 'screensaver.immich_album_name',
  type: SettingType.string,
  defaultValue: '',
  title: 'Album name',
  description: '',
  category: 'Screensaver',
  section: 'Media',
  subpage: 'Immich Media screensaver',
  hidden: true,
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichInterval = SettingDef<num>(
  key: 'screensaver.immich_interval_seconds',
  type: SettingType.number,
  defaultValue: 10,
  title: 'Seconds per image',
  description:
      'How long each image shows before the next. Videos play in full.',
  category: 'Screensaver',
  section: 'Slideshow',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichShuffle = SettingDef<bool>(
  key: 'screensaver.immich_shuffle',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Shuffle',
  description: 'Cycle the media in random order.',
  category: 'Screensaver',
  section: 'Slideshow',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichTransition = SettingDef<String>(
  key: 'screensaver.immich_transition',
  type: SettingType.select,
  defaultValue: 'fade',
  title: 'Transition',
  description: 'How one item hands off to the next.',
  category: 'Screensaver',
  section: 'Slideshow',
  subpage: 'Immich Media screensaver',
  options: _transitionOptions,
  optionLabels: _transitionLabels,
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichFill = SettingDef<String>(
  key: 'screensaver.immich_fill',
  type: SettingType.select,
  defaultValue: 'smart',
  title: 'Fill the screen',
  description: _fillDescription,
  category: 'Screensaver',
  section: 'Slideshow',
  subpage: 'Immich Media screensaver',
  options: _fillOptions,
  optionLabels: _fillLabels,
  dependsOn: 'screensaver.immich_validated',
);

// Two portrait photos side by side instead of one framed by empty screen:
// the pair fills a landscape panel the way a single portrait shot never
// can. On by default, like Fill the screen's Smart setting, since filling
// the panel is what people want from a photo frame.
const screensaverImmichPairPortrait = SettingDef<bool>(
  key: 'screensaver.immich_pair_portrait',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Pair portrait photos',
  description: 'Show two portrait photos side by side so they fill the screen.',
  category: 'Screensaver',
  section: 'Slideshow',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichCache = SettingDef<bool>(
  key: 'screensaver.immich_cache',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Cache media locally',
  description: 'Keep copies on the device so images load instantly.',
  category: 'Screensaver',
  section: 'Media',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichCacheMax = SettingDef<num>(
  key: 'screensaver.immich_cache_max_items',
  type: SettingType.number,
  defaultValue: 500,
  title: 'Cache size (items)',
  description: 'The oldest items are deleted once the cache is full.',
  category: 'Screensaver',
  section: 'Media',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_cache',
);

const screensaverImmichMetadata = SettingDef<bool>(
  key: 'screensaver.immich_metadata',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show metadata',
  description: 'Album, date, camera and location over the media.',
  category: 'Screensaver',
  section: 'Metadata',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

// Which lines the overlay carries (issue #268): people who point the
// screensaver at one album do not need its name on every photo, and the
// same goes for any other line. All on, so the overlay reads exactly as
// it always did until someone turns a line off.
const screensaverImmichMetadataAlbum = SettingDef<bool>(
  key: 'screensaver.immich_metadata_album',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Album name',
  description: 'Show which album the photo comes from.',
  category: 'Screensaver',
  section: 'Metadata',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_metadata',
);

const screensaverImmichMetadataDate = SettingDef<bool>(
  key: 'screensaver.immich_metadata_date',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Date taken',
  description: 'Show when the photo was taken.',
  category: 'Screensaver',
  section: 'Metadata',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_metadata',
);

const screensaverImmichMetadataCamera = SettingDef<bool>(
  key: 'screensaver.immich_metadata_camera',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Camera details',
  description: 'Show focal length, aperture and ISO.',
  category: 'Screensaver',
  section: 'Metadata',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_metadata',
);

const screensaverImmichMetadataLocation = SettingDef<bool>(
  key: 'screensaver.immich_metadata_location',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Location',
  description: 'Show the place the photo was taken.',
  category: 'Screensaver',
  section: 'Metadata',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_metadata',
);

const screensaverImmichMetadataPosition = SettingDef<String>(
  key: 'screensaver.immich_metadata_position',
  type: SettingType.select,
  // Opposite default corner to the small clock, so turning both on does not
  // stack them.
  defaultValue: 'bottom_left',
  title: 'Metadata position',
  description: 'Which corner the details sit in.',
  category: 'Screensaver',
  options: cornerOptions,
  optionLabels: cornerLabels,
  section: 'Metadata',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_metadata',
);

// The metadata overlay's own vignette, the widgets' slider's twin (same
// range, same default, same meaning) so the two can be set apart.
const screensaverImmichVignetteStrength = SettingDef<num>(
  key: 'screensaver.immich_vignette_strength',
  type: SettingType.number,
  defaultValue: 80,
  title: 'Vignette strength',
  description:
      'Darkness of the shading behind the details, for readability on '
      'bright photos. 0 turns it off.',
  category: 'Screensaver',
  section: 'Metadata',
  subpage: 'Immich Media screensaver',
  min: 0,
  max: 100,
  step: 5,
  unit: '%',
  dependsOn: 'screensaver.immich_metadata',
);

// ── Immich filters ──
//
// Narrow the source (the whole library or an album) to what a photo frame
// should actually show (issue #345). Each filter is one field of the same
// metadata search the playlist already runs, so they combine as AND with
// the source and with each other. The people and tag lists are picked by
// name from the server, stored as [{id, name}] like the launcher's apps so
// both UIs can show the names without asking the server again.

const screensaverImmichPeople = SettingDef<String>(
  key: 'screensaver.immich_people',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'People',
  description: 'Show only media with any of these people.',
  category: 'Screensaver',
  section: 'Filters',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichExcludePeople = SettingDef<String>(
  key: 'screensaver.immich_exclude_people',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Exclude people',
  description: 'Skip media with any of these people.',
  category: 'Screensaver',
  section: 'Filters',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichTags = SettingDef<String>(
  key: 'screensaver.immich_tags',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Tags',
  description: 'Show only media with any of these tags.',
  category: 'Screensaver',
  section: 'Filters',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichFavoritesOnly = SettingDef<bool>(
  key: 'screensaver.immich_favorites_only',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Favorites only',
  description: 'Show only media marked as favorite.',
  category: 'Screensaver',
  section: 'Filters',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

/// The "Taken within" choices: the value is the number of days back, as a
/// string, with the empty string for no limit. Days rather than calendar
/// months, so the cutoff is the same arithmetic on both UIs and the server.
///
/// The last two are the fixed windows (issue #383) and carry no days: a
/// rolling window moves forward every night, which is wrong for a frame
/// pinned to a wedding or to the year a scanned album starts. `since`
/// reads the From date, `range` reads From and To.
const immichTakenWithinOptions = [
  '',
  '30',
  '90',
  '365',
  '730',
  '1825',
  '3650',
  immichTakenSince,
  immichTakenRange,
];
const immichTakenSince = 'since';
const immichTakenRange = 'range';
const immichTakenWithinLabels = {
  '': 'Any time',
  '30': 'Past month',
  '90': 'Past 3 months',
  '365': 'Past year',
  '730': 'Past 2 years',
  '1825': 'Past 5 years',
  '3650': 'Past 10 years',
  immichTakenSince: 'Since',
  immichTakenRange: 'Timeframe',
};

/// A date filter's value: "YYYY-MM-DD", or empty for no bound. Both UIs
/// pick it from a calendar, so the format is never typed.
final _immichDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
String? immichDateValidator(Object? value) {
  final text = '${value ?? ''}';
  if (text.isEmpty) return null;
  if (!_immichDatePattern.hasMatch(text)) return 'Use YYYY-MM-DD.';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return 'That is not a date.';
  return null;
}

const screensaverImmichTakenWithin = SettingDef<String>(
  key: 'screensaver.immich_taken_within',
  type: SettingType.select,
  defaultValue: '',
  options: immichTakenWithinOptions,
  optionLabels: immichTakenWithinLabels,
  title: 'Taken within',
  description: 'Only show media taken in this window.',
  category: 'Screensaver',
  section: 'Filters',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichTakenFrom = SettingDef<String>(
  key: 'screensaver.immich_taken_from',
  type: SettingType.string,
  defaultValue: '',
  title: 'From',
  description: 'Skip media taken before this date.',
  placeholder: 'Any time',
  category: 'Screensaver',
  section: 'Filters',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_taken_within',
  dependsOnValue: [immichTakenSince, immichTakenRange],
  validator: immichDateValidator,
);

const screensaverImmichTakenTo = SettingDef<String>(
  key: 'screensaver.immich_taken_to',
  type: SettingType.string,
  defaultValue: '',
  title: 'To',
  description: 'Skip media taken after this date. The day itself counts.',
  placeholder: 'Today',
  category: 'Screensaver',
  section: 'Filters',
  subpage: 'Immich Media screensaver',
  dependsOn: 'screensaver.immich_taken_within',
  dependsOnValue: immichTakenRange,
  validator: immichDateValidator,
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

// ── Camera Streams (mode: camera) ──
// The views the screensaver cycles through, as a JSON array of view ids in
// rotation order. Picked from the views configured under Camera Streams in
// both UIs (see decodeCameraViewIds in camera/models.dart), never typed.
const screensaverCameraViews = SettingDef<String>(
  key: 'screensaver.camera_views',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Camera views',
  description: 'The camera views the screensaver shows, in this order.',
  category: 'Screensaver',
  section: 'Camera Streams screensaver',
  subpage: 'Camera Streams screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'camera',
);

// The dwell per view. Every change tears one grid's streams down and
// negotiates the next view's from scratch, so the floor keeps a rotation
// from turning into a permanent reconnect; it means nothing with one view.
const screensaverCameraViewSeconds = SettingDef<num>(
  key: 'screensaver.camera_view_seconds',
  type: SettingType.number,
  defaultValue: 30,
  title: 'Seconds per camera view',
  description:
      'How long each view stays on screen before the next one. With a '
      'single view selected nothing rotates.',
  category: 'Screensaver',
  section: 'Camera Streams screensaver',
  subpage: 'Camera Streams screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'camera',
  validator: validateCameraViewSeconds,
);

// The screensaver is scenery, and a single-camera view left on overnight
// with "Play sound for a single camera" on (issue #235) would talk to an
// empty room; the mute is the screensaver's own say over that switch. On
// by default, and it also drops the audio track from the streams it fetches.
const screensaverCameraMute = SettingDef<bool>(
  key: 'screensaver.camera_mute',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Mute all views',
  description: 'Keeps every view silent, even a single camera.',
  category: 'Screensaver',
  section: 'Camera Streams screensaver',
  subpage: 'Camera Streams screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'camera',
);

/// The shortest dwell a rotation may run at (see [screensaverCameraViewSeconds]).
const screensaverCameraViewSecondsMin = 5;

String? validateCameraViewSeconds(Object? value) {
  if (value is! num || value < screensaverCameraViewSecondsMin) {
    return 'Enter at least $screensaverCameraViewSecondsMin seconds.';
  }
  return null;
}

// The single view the mode showed before it rotated. Hidden: kept so old
// backups still import, and the screensaver manager folds a value here
// into the list above on startup and after an import, then clears it.
const screensaverCameraView = SettingDef<String>(
  key: 'screensaver.camera_view',
  type: SettingType.string,
  defaultValue: '',
  title: 'Camera view',
  description: 'Which camera view the screensaver shows.',
  category: 'Screensaver',
  hidden: true,
);

const screensaverCameraViewName = SettingDef<String>(
  key: 'screensaver.camera_view_name',
  type: SettingType.string,
  defaultValue: '',
  title: 'Camera view name',
  description: 'The name of the selected camera view.',
  category: 'Screensaver',
  hidden: true,
);

const screensaverDimLevel = SettingDef<num>(
  key: 'screensaver.dim_level',
  type: SettingType.number,
  defaultValue: 0.1,
  title: 'Dim level',
  description: 'Screen brightness while the screensaver is dimming.',
  category: 'Screensaver',
  section: 'Dim screensaver',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'dim',
  min: 0,
  max: 1,
  step: 0.05,
  unit: '%',
);

// Content modes (clock, photos, website) hold normal brightness by default:
// dimming a display someone reads is opt-in, unlike Dim/Black whose whole
// point is darkness (issue #31: a clock that glows all night).
const screensaverBrightnessEnabled = SettingDef<bool>(
  key: 'screensaver.brightness_enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Screensaver brightness',
  description: 'Use a separate brightness while the screensaver is showing.',
  category: 'Screensaver',
);

const screensaverBrightnessLevel = SettingDef<num>(
  key: 'screensaver.brightness_level',
  type: SettingType.number,
  defaultValue: 0.2,
  title: 'Brightness level',
  description: 'Applies to every mode except Dim and Black.',
  category: 'Screensaver',
  dependsOn: 'screensaver.brightness_enabled',
  min: 0,
  max: 1,
  step: 0.05,
  unit: '%',
);

/// A dimmed panel is unreadable at arm's length, which is exactly the
/// moment a notification arrives and asks to be read. On by default: the
/// dimming exists so a screensaver does not glow all night, not so that
/// messages sent to this kiosk go unseen. Off suits a bedroom, where a
/// notification lighting the room at 3am is worse than missing it.
const screensaverNotificationBrightness = SettingDef<bool>(
  key: 'screensaver.notification_brightness',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Brighten for notifications',
  description:
      'Lift the screensaver dimming while a notification is on screen.',
  category: 'Screensaver',
  // Shown under the switch it qualifies. Dim and Black dim without it, so
  // their lift is governed by a row that is out of sight there; on is the
  // right thing for both, and the two dark modes are where an unreadable
  // notification is most likely in the first place.
  dependsOn: 'screensaver.brightness_enabled',
);

// The screensaver deliberately holds the panel awake (see the manager's
// start()), so the OS idle timeout can never fire under it; this timer is
// the one sanctioned way a session ends in a truly dark panel. Wake paths
// exist for every dismiss source: motion, the MQTT dismiss button and the
// wake word all light the panel back up. Real power-off is device-admin
// lockNow, hence the permission note.
const screensaverScreenOffMinutes = SettingDef<num>(
  key: 'screensaver.screen_off_minutes',
  type: SettingType.number,
  defaultValue: 0,
  min: 0,
  max: 60,
  step: 5,
  unit: ' min',
  title: 'Turn screen off after',
  description:
      'Powers down the display panel once the screensaver has run for the '
      'set duration. Set to 0 to keep the screen on indefinitely. Requires '
      'Device Administrator permission.',
  category: 'Screensaver',
);

/// The brightness to restore when the screensaver ends, persisted so a
/// process death mid-screensaver cannot turn the dim level into the new
/// normal. -1 means no restore pending.
const screensaverSavedBrightness = SettingDef<num>(
  key: 'screensaver.saved_brightness',
  type: SettingType.number,
  defaultValue: -1,
  title: 'Saved screensaver brightness',
  description: 'Internal restore point for the screensaver brightness.',
  category: 'Screensaver',
  hidden: true,
);

// Motion detection exists only to wake the screensaver for now, so this one
// switch is its whole on/off — no separate "motion detection" toggle. Off by
// ── At a Glance (every mode but the camera grid) ──
// A row of entity states on the screensaver, for the things people check in
// passing: is the garage still open, is the door locked (issue #37). Every
// mode carries it except the camera grid, where a status row would sit over
// a live feed, the same line the corner widgets draw. The default card
// style brings its own backdrop, which is what lets the row ride the photo
// modes at all: bare text over a bright photo is unreadable.
const screensaverGlanceEnabled = SettingDef<bool>(
  key: 'screensaver.glance_enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'At a glance',
  description: 'Show a row of Home Assistant entity states on the screensaver.',
  category: 'Screensaver',
  section: 'At a Glance',
  subpage: 'At a Glance',
);

// The chosen entities as a JSON list of {entity_id, name} plus optional
// custom_name and attribute. Hand-built pickers
// on the device and in the remote admin write it; the generic settings
// renderer skips it (a raw JSON field is not something to type).
const screensaverGlanceEntities = SettingDef<String>(
  key: 'screensaver.glance_entities',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Entities',
  description:
      'Up to four entities to show, each with an optional custom '
      'name.',
  category: 'Screensaver',
  section: 'At a Glance',
  subpage: 'At a Glance',
  dependsOn: 'screensaver.glance_enabled',
);

// The Appearance group: how the row draws, as opposed to what it shows.
// Its rows sit at the end of the At a Glance subpage under their own
// heading, the User Interface / Haptics precedent.
//
// One knob for the whole row, the Widget scaling precedent: the chips all
// sit on the same panel, so they want the same correction. Applied inside
// GlanceRow, on top of each surface's own computed scale, so the clock,
// black, photo and Now Playing placements all follow it alike.
const screensaverGlanceScale = SettingDef<num>(
  key: 'screensaver.glance_scale',
  type: SettingType.number,
  defaultValue: 100,
  title: 'Row scaling',
  description: 'Scale the row to better fit your screen size.',
  category: 'Screensaver',
  section: 'Appearance',
  subpage: 'At a Glance',
  min: 50,
  max: 150,
  step: 5,
  unit: '%',
  dependsOn: 'screensaver.glance_enabled',
);

// Icon and value only. On a small panel read from across the room the
// name is the line that costs the most and says the least: an icon
// already names a temperature or a humidity. Without the name the value
// grows into the room the name took, so the reading gets bigger, not the
// chip smaller. The custom names are kept, only not drawn.
const screensaverGlanceHideNames = SettingDef<bool>(
  key: 'screensaver.glance_hide_names',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Hide names',
  description: 'Show only the icon and the value, with the value drawn larger.',
  category: 'Screensaver',
  section: 'Appearance',
  subpage: 'At a Glance',
  dependsOn: 'screensaver.glance_enabled',
);

// The chip circles follow the entity's state color by default (a lit light
// glows amber); this keeps them in the neutral grey for a quieter row.
const screensaverGlanceBwIcons = SettingDef<bool>(
  key: 'screensaver.glance_bw_icons',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Monochromatic icons',
  description:
      'Keep every icon in the neutral grey instead of its state '
      'color.',
  category: 'Screensaver',
  section: 'Appearance',
  subpage: 'At a Glance',
  dependsOn: 'screensaver.glance_enabled',
);

// The original floating-text look, kept for the people who chose the row
// when it was the only look. The cards became the default when the row
// started riding the photo modes, whose imagery no single text color can
// stay readable over.
const screensaverGlanceTextOnly = SettingDef<bool>(
  key: 'screensaver.glance_text_only',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Floating text style',
  description: 'Show the entities as floating text instead of chips.',
  category: 'Screensaver',
  section: 'Appearance',
  subpage: 'At a Glance',
  dependsOn: 'screensaver.glance_enabled',
);

// Opt-in (issue #209): the full-screen Now Playing view was designed as
// art alone, so the row only joins it for people who ask. It stays out of
// the lyrics layouts, which already spend every free pixel on the words.
const screensaverGlanceNowPlaying = SettingDef<bool>(
  key: 'screensaver.glance_now_playing',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show on Now Playing',
  description:
      'Show the row on the full-screen Now Playing view. It stays hidden '
      'while lyrics are showing.',
  category: 'Screensaver',
  section: 'At a Glance',
  subpage: 'At a Glance',
  dependsOn: 'screensaver.glance_enabled',
);

/// The most entities the row will hold: past four the labels stop being
/// readable across a room, which is the whole point of the row.
const screensaverGlanceMax = 4;

// default because turning it on asks for the camera. When on, the camera runs
// only while the screensaver is showing.
const screensaverDismissOnMotion = SettingDef<bool>(
  key: 'screensaver.dismiss_on_motion',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Dismiss on motion',
  description:
      'Watch the camera while the screensaver is up and wake the screen '
      'when someone approaches. The camera runs only during the '
      'screensaver.',
  category: 'Screensaver',
  section: 'Motion Detection',
  subpage: 'Motion Detection',
);

// Opt-in because it is the expensive direction (discussion #126): unlike
// dismiss_on_motion, the camera must run the whole time the screensaver is
// NOT showing, which is most of the day. An extension of Dismiss on
// motion, not a sibling: it only shows (and only acts) with that switch
// on, so motion detection has exactly one master toggle.
const screensaverPostponeOnMotion = SettingDef<bool>(
  key: 'screensaver.postpone_on_motion',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Postpone screensaver on motion',
  description:
      'Delay activating the screensaver when motion is detected. '
      'WARNING: Keeps the camera running permanently.',
  category: 'Screensaver',
  section: 'Motion Detection',
  subpage: 'Motion Detection',
  dependsOn: 'screensaver.dismiss_on_motion',
);

// Legacy: superseded by [cameraDevice] when the Camera category arrived —
// one camera choice for every camera feature, picked there. Kept hidden so
// old exports still import and the one-time migration can read the choice.
const motionCamera = SettingDef<String>(
  key: 'motion.camera',
  type: SettingType.select,
  defaultValue: 'front',
  title: 'Motion camera',
  description: 'Which camera watches for motion.',
  category: 'Screensaver',
  section: 'Motion Detection',
  subpage: 'Motion Detection',
  options: ['front', 'back'],
  optionLabels: {'front': 'Front', 'back': 'Back'},
  hidden: true,
);

// ── Screensaver: Face Detection ────────────────────────────────────────
// Fully Kiosk's "face detection" (issue #304): wake only when someone is
// looking at the kiosk, so a room full of movement leaves the screensaver
// up. Detection, not recognition: nothing is identified or stored. The
// detector rides the motion camera session (same camera, frame rate and
// startup delay, all tuned in the Camera settings) and runs only during
// the screensaver, like Dismiss on motion. Dismiss on motion takes
// precedence: with both on, the motion switch owns the wake-up and the
// face leg stays idle, which both settings UIs say under this switch. The
// schedule's per-entry override exists so a daytime entry can wake on
// faces while a night entry falls back to motion: faces need light,
// motion does not.
const screensaverDismissOnFace = SettingDef<bool>(
  key: 'screensaver.dismiss_on_face',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Dismiss on face',
  description:
      'Wake the screen when someone looks at the kiosk, not on movement '
      'alone. The camera runs only during the screensaver. WARNING: Needs '
      'a lit face; in the dark, schedule motion detection instead.',
  category: 'Screensaver',
  section: 'Face Detection',
  subpage: 'Face Detection',
);

// The face counterpart of Postpone screensaver on motion, with the same
// rules: an extension of Dismiss on face (hidden and inert without it),
// the camera runs the whole time the screensaver is NOT showing, and the
// face detector runs on top of it. The detector is gated on the motion
// grid natively (an empty room costs no inference), which is what makes
// this affordable at all on the low-powered devices most kiosks are.
const screensaverPostponeOnFace = SettingDef<bool>(
  key: 'screensaver.postpone_on_face',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Postpone screensaver on face',
  description:
      'Delay activating the screensaver while someone is looking at the '
      'kiosk. WARNING: Keeps the camera running permanently, with face '
      'detection and its CPU cost on top.',
  category: 'Screensaver',
  section: 'Face Detection',
  subpage: 'Face Detection',
  dependsOn: 'screensaver.dismiss_on_face',
);

// Mapped to a minimum face size by faceMinWidthFor (native_motion.dart):
// a face fills more of the frame the closer it is, so the slider is
// really a maximum distance.
const faceSensitivity = SettingDef<num>(
  key: 'face.sensitivity',
  type: SettingType.number,
  defaultValue: 50,
  title: 'Face sensitivity',
  description:
      'Higher wakes on smaller, more distant faces. 1 needs a face close '
      'to the screen; 100 reacts to any face the camera can make out.',
  category: 'Screensaver',
  section: 'Face Detection',
  subpage: 'Face Detection',
  dependsOn: 'screensaver.dismiss_on_face',
  min: 1,
  max: 100,
  step: 1,
);

// ── Screensaver: Face Detection: Camera Preview ────────────────────────
// A glimpse of what the camera saw (discussion #371): when a face
// dismisses the screensaver, a small circular live preview sits in a
// corner of the dashboard for a few seconds and goes away on its own. It
// shows the frames the detector itself is looking at, so someone tuning
// Face sensitivity, the camera pick or the placement of the device can see
// what the kiosk sees, and a person who did not expect the screen to wake
// can see why it did. Only on a dismissal: a face that postpones the next
// screensaver is a face every second or so, and a preview on each would
// never leave. The frames are drawn and dropped; nothing is stored or
// sent anywhere. The three knobs under the switch are hidden and inert
// without it.
const facePreview = SettingDef<bool>(
  key: 'face.preview',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show camera preview',
  description:
      'Show a small round live view of the camera in a corner of the screen '
      'for a few seconds when a face wakes the kiosk.',
  category: 'Screensaver',
  section: 'Camera Preview',
  subpage: 'Face Detection',
  dependsOn: 'screensaver.dismiss_on_face',
);

const facePreviewSeconds = SettingDef<num>(
  key: 'face.preview_seconds',
  type: SettingType.number,
  defaultValue: 5,
  title: 'Preview duration',
  description: 'How long the preview stays on screen.',
  category: 'Screensaver',
  section: 'Camera Preview',
  subpage: 'Face Detection',
  dependsOn: 'face.preview',
  min: 3,
  max: 10,
  step: 1,
  unit: 's',
);

// Widget scaling's shape (50..150 percent of the base size) rather than a
// bare factor, so the slider reads the same as the screensaver's other
// size knob on both surfaces.
const facePreviewScale = SettingDef<num>(
  key: 'face.preview_scale',
  type: SettingType.number,
  defaultValue: 100,
  title: 'Preview scaling',
  description: 'Scale the preview to better fit your screen size.',
  category: 'Screensaver',
  section: 'Camera Preview',
  subpage: 'Face Detection',
  dependsOn: 'face.preview',
  min: 50,
  max: 150,
  step: 10,
  unit: '%',
);

const facePreviewPosition = SettingDef<String>(
  key: 'face.preview_position',
  type: SettingType.select,
  defaultValue: 'top_right',
  title: 'Preview position',
  description: 'Which corner the preview sits in.',
  category: 'Screensaver',
  section: 'Camera Preview',
  subpage: 'Face Detection',
  dependsOn: 'face.preview',
  options: cornerOptions,
  optionLabels: cornerLabels,
);

// ── Screensaver: Proximity Detection ───────────────────────────────────
// Motion Detection's shape on the device's proximity sensor instead of
// the camera: dismiss while the screensaver shows, postpone between
// screensavers. No camera, no permission and next to no CPU, but only as
// good as the sensor. Kiosk-class tablets mostly have none, and modern
// phones tend to expose a virtual "palm" sensor that only reacts to a
// hand on the screen during a call and never to someone walking up.
// The switch is disabled where there is no sensor, and where there is
// one, a row under it names the sensor so a person can tell which kind
// they have (ProximityManager answers both).

const screensaverDismissOnProximity = SettingDef<bool>(
  key: 'screensaver.dismiss_on_proximity',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Dismiss on proximity',
  description:
      'Watch the proximity sensor while the screensaver is up and wake the '
      'screen when something comes close to the device. A device with only '
      'sensors made for calls ("palm", "touch") will not work.',
  category: 'Screensaver',
  section: 'Proximity Detection',
  subpage: 'Proximity Detection',
);

// An extension of Dismiss on proximity, like Postpone on motion is of
// Dismiss on motion: shown and acting only with that switch on, so
// proximity detection has exactly one master toggle. Cheap where the
// camera leg is not: the sensor runs between screensavers at no
// noticeable cost.
const screensaverPostponeOnProximity = SettingDef<bool>(
  key: 'screensaver.postpone_on_proximity',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Postpone screensaver on proximity',
  description:
      'Delay activating the screensaver while something is close to the '
      'sensor.',
  category: 'Screensaver',
  section: 'Proximity Detection',
  subpage: 'Proximity Detection',
  dependsOn: 'screensaver.dismiss_on_proximity',
);

// ── Screensaver: Person Detection ───────────────────────────────────────
// Motion Detection's shape on a person sensor the device itself runs:
// today the Meta Portal's, whose Smart Camera people tracker runs all the
// time on a virtual camera feed that never lights the camera LED and logs
// a heartbeat every 30 seconds while someone is in view (discussion
// #353). Bodies at any angle, not faces: someone reading at the kiosk
// with their back to it counts. No camera session of the app's, no face
// model, next to no CPU. The page exists only where the person sensor
// manager finds such a sensor (deviceHiddenKeys, filled at boot) and, on
// the Portal, needs the READ_LOGS grant, which only adb can give.
const screensaverDismissOnPerson = SettingDef<bool>(
  key: 'screensaver.dismiss_on_person',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Dismiss on person',
  description:
      "Read the device's person sensor while the screensaver is up and "
      'wake the screen when someone is in front of it. Needs the Log '
      'access grant below.',
  category: 'Screensaver',
  section: 'Person Detection',
  subpage: 'Person Detection',
);

// An extension of Dismiss on person, like Postpone on motion is of
// Dismiss on motion: shown and acting only with that switch on. The
// sensor reports every few seconds while someone stays, so the postpone
// leg holds the idle clock continuously.
const screensaverPostponeOnPerson = SettingDef<bool>(
  key: 'screensaver.postpone_on_person',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Postpone screensaver on person',
  description:
      'Delay activating the screensaver while someone is in front of the '
      'device.',
  category: 'Screensaver',
  section: 'Person Detection',
  subpage: 'Person Detection',
  dependsOn: 'screensaver.dismiss_on_person',
);

// ── Camera ─────────────────────────────────────────────────────────────
// The device's own camera as a Home Assistant feature (discussion #72):
// snapshots published over MQTT, and the sensor the screensaver's motion
// detection watches. One master switch so a kiosk that does not need the
// camera never spends a cycle (or a degree) on it; livestreaming will build
// on this same section.

const cameraEnabled = SettingDef<bool>(
  key: 'camera.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable camera',
  description:
      'Camera use adds CPU load and heat, which can shorten the battery '
      'and device lifespan.',
  category: 'Camera',
);

const cameraDevice = SettingDef<String>(
  key: 'camera.device',
  type: SettingType.select,
  defaultValue: 'front',
  title: 'Camera',
  description: 'Which camera to use.',
  category: 'Camera',
  options: ['front', 'back'],
  optionLabels: {'front': 'Front', 'back': 'Back'},
  dependsOn: 'camera.enabled',
);

// The tiers are the standard 4:3 ladder (640x480, 960x720, 1440x1080)
// that Android cameras virtually always offer, so the "p" labels match
// what actually comes out; CameraX still lands on the nearest size on
// hardware missing a rung. 480p by default, the lightest tier: ~30 KB a
// frame, and motion detection is unaffected either way (it has its own
// fixed low-resolution analysis stream).
const cameraSnapshotResolution = SettingDef<String>(
  key: 'camera.snapshot_resolution',
  type: SettingType.select,
  defaultValue: '480',
  title: 'Snapshot resolution',
  description: 'Higher looks sharper but costs more CPU and bandwidth.',
  category: 'Camera',
  options: ['480', '720', '1080'],
  optionLabels: {'480': '480p', '720': '720p', '1080': '1080p'},
  dependsOn: 'camera.enabled',
);

const cameraSnapshots = SettingDef<bool>(
  key: 'camera.snapshots',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Continuous snapshots',
  description:
      'Publish a fresh camera snapshot to Home Assistant over MQTT at a '
      'fixed interval.',
  category: 'Camera',
  dependsOn: 'camera.enabled',
);

const cameraSnapshotInterval = SettingDef<num>(
  key: 'camera.snapshot_interval',
  type: SettingType.number,
  defaultValue: 60,
  title: 'Snapshot interval',
  description: 'Seconds between snapshots.',
  category: 'Camera',
  dependsOn: 'camera.snapshots',
  min: 5,
  max: 300,
  step: 5,
  unit: 's',
);

// ── Camera: Motion Detection ───────────────────────────────────────────
// Motion detection's home: the standalone sensor and the shared tuning.
// The sensor is motion exposed as its own MQTT binary_sensor, independent
// of the screensaver's motion features. Users asked for the sensor without
// the screensaver strings attached, and its natural use (motion turns the
// panel on) needs the camera watching while the screen is dark, which no
// screensaver leg does. A third leg in MotionManager, deliberately NOT
// gated on the dismiss switch. The tuning rows (frame rate, sensitivity)
// moved here from the Screensaver section when the sensor arrived: they
// tune every motion leg, so they belong with the camera, not with one
// consumer of it.

const motionSensor = SettingDef<bool>(
  key: 'motion.sensor',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Motion sensor',
  description:
      'Expose motion as a Home Assistant sensor over MQTT. WARNING: '
      'Keeps the camera running permanently, even with the screen off.',
  category: 'Camera',
  section: 'Motion Detection',
  dependsOn: 'camera.enabled',
);

// The sensor clears itself in Home Assistant (off_delay in the discovery
// config): the app only ever reports motion, never its absence.
const motionSensorOffDelay = SettingDef<num>(
  key: 'motion.sensor_off_delay',
  type: SettingType.number,
  defaultValue: 5,
  title: 'Clear after',
  description: 'Seconds without motion before the sensor reads clear.',
  category: 'Camera',
  section: 'Motion Detection',
  dependsOn: 'motion.sensor',
  min: 1,
  max: 300,
  step: 1,
  unit: 's',
);

const motionFps = SettingDef<num>(
  key: 'motion.fps',
  type: SettingType.number,
  defaultValue: 2,
  title: 'Motion frame rate',
  description:
      'Frames per second the camera checks for motion. Lower is lighter '
      'on the CPU; 2 is plenty to notice someone approaching.',
  category: 'Camera',
  section: 'Motion Detection',
  dependsOn: 'camera.enabled',
);

/// Seconds of blindness after the camera stream starts, on top of the
/// analyzer's own auto-exposure warm-up (see CameraMotion.kt). For hardware
/// whose camera physically moves as it opens: a pop-up module rising on its
/// motor sweeps the lens through the scene, which is a real, both-signed
/// change no lighting veto can reject, so it reads as a body and dismisses
/// the screensaver that just started the camera (discussion #159). Anchored
/// to the stream start rather than the screensaver's, so every path that
/// binds the camera is covered: schedule boundaries, screen on/off and
/// tuning changes all deploy the same lens.
const motionStartDelay = SettingDef<num>(
  key: 'motion.start_delay',
  type: SettingType.number,
  defaultValue: 0,
  title: 'Startup delay',
  description:
      'Ignore motion for this long after the camera starts, for devices '
      'whose camera physically moves as it opens.',
  category: 'Camera',
  section: 'Motion Detection',
  dependsOn: 'camera.enabled',
  min: 0,
  max: 15,
  step: 1,
  unit: 's',
);

const motionSensitivity = SettingDef<num>(
  key: 'motion.sensitivity',
  type: SettingType.number,
  defaultValue: 70,
  title: 'Motion sensitivity',
  description:
      'Higher trips on smaller movements. 1 needs a large change across '
      'the frame; 100 reacts to the slightest motion.',
  category: 'Camera',
  section: 'Motion Detection',
  dependsOn: 'camera.enabled',
  min: 1,
  max: 100,
  step: 1,
);

// ── Schedule ───────────────────────────────────────────────────────────
// Time-of-day screensaver switching, the same idea as the Home Assistant
// theme schedule: each entry names a time, the mode to show from then on,
// and optionally the brightness to hold while it is active. The entry list
// is custom UI in both settings surfaces (times, mode dropdowns and sliders
// per row), so only the JSON list is stored.

const screensaverScheduleEnabled = SettingDef<bool>(
  key: 'screensaver.schedule_enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable scheduled screensavers',
  description: 'Switch to a different screensaver at set times of day.',
  category: 'Screensaver',
  section: 'Scheduled Screensavers',
  subpage: 'Scheduled Screensavers',
);

/// JSON list of `{"at": "HH:MM", "mode": "...", "brightness": 0..1}`
/// entries, kept sorted by time. Each entry applies from its
/// time until the next entry's; the latest entry of the day carries over
/// past midnight. The brightness, when present, overrides the global
/// screensaver brightness while the entry is active; absent (issue #411)
/// the entry follows the Screensaver brightness switch, which may leave
/// the panel to the device or adaptive brightness.
const screensaverSchedule = SettingDef<String>(
  key: 'screensaver.schedule',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Times',
  description: 'Each time switches the screensaver from then on.',
  category: 'Screensaver',
  section: 'Scheduled Screensavers',
  subpage: 'Scheduled Screensavers',
  dependsOn: 'screensaver.schedule_enabled',
);

// ── Microphone ─────────────────────────────────────────────────────────
//
// Escape hatches for devices whose audio stack does not behave: custom ROMs
// and cheap tablets where the mic reads far quieter through the app than it
// does through a recorder app. Every default here is what the app has always
// done, so an untouched install is bit-for-bit the old behaviour.

const micAudioSource = SettingDef<String>(
  key: 'audio.mic_source',
  type: SettingType.select,
  defaultValue: 'voice_communication',
  options: ['voice_communication', 'voice_recognition', 'mic'],
  optionLabels: {
    'voice_communication': 'Voice communication (default)',
    'voice_recognition': 'Voice recognition',
    'mic': 'Raw microphone',
  },
  title: 'Capture mode',
  description:
      'Voice communication is the only mode with echo cancellation, so '
      'leave it unless the microphone reads far quieter here than in a '
      'recorder app.',
  category: 'Screen & Audio',
  section: 'Microphone settings',
  subpage: 'Microphone settings',
);

// Hidden: rendered as a hand-built dropdown (device settings screen and the
// remote UI both) because its options depend on live hardware - the row only
// exists when the selected microphone reports more than one channel, and the
// option list runs to that count. Multichannel arrays put differently
// processed signals on each channel (the reSpeaker XVF3800 sends its
// call-tuned output on channel 1 and its raw ASR output on channel 2, the one
// its docs recommend for recognition engines), while Android's default mono
// capture averages them all together. 0 = that downmix (the app's historical
// behavior), 1..N = listen to that channel alone.
const micChannel = SettingDef<num>(
  key: 'audio.mic_channel',
  type: SettingType.number,
  defaultValue: 0,
  title: 'Microphone channel',
  description:
      'Multichannel microphones often reserve one channel for speech '
      'recognition; picking it can improve detection.',
  category: 'Screen & Audio',
  section: 'Microphone settings',
  subpage: 'Microphone settings',
  hidden: true,
);

const micAgc = SettingDef<bool>(
  key: 'audio.mic_agc',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Automatic gain control',
  description:
      'Let Android level the microphone instead of a fixed gain. It '
      'also lifts room noise, and on some devices it does nothing at '
      'all.',
  category: 'Screen & Audio',
  section: 'Microphone settings',
  subpage: 'Microphone settings',
);

const micGainDb = SettingDef<num>(
  key: 'audio.mic_gain_db',
  type: SettingType.number,
  defaultValue: 0,
  min: -24,
  max: 24,
  step: 1,
  unit: ' dB',
  title: 'Microphone gain',
  description:
      'Boost or cut the microphone before anything hears it. Aim for a '
      'level near 0.05 in the wake word tester; too much gain distorts '
      'speech and hurts detection.',
  category: 'Screen & Audio',
  section: 'Microphone settings',
  subpage: 'Microphone settings',
  // Hidden while Android is doing the levelling: a fixed gain under an
  // adaptive one is two controls fighting over the same number.
  dependsOn: 'audio.mic_agc',
  dependsOnValue: false,
);

// ── Wake word ──────────────────────────────────────────────────────────

/// [SettingDef.normalizer] for the retired master switch: any write lands
/// as on, so an import of an old config cannot strand a device off.
Object alwaysOnSetting(Object _) => true;

/// The old wake word master switch, retired: with Voice Satellite installed
/// the app always takes detection over (turning that down was never the
/// right call, and the Wake word engine select in Home Assistant is the
/// real off switch). Hidden and forced on; the key survives for old
/// configs and the readers that gate on it.
const wakeWordEnabled = SettingDef<bool>(
  key: 'wake_word.enabled',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Wake word detection',
  description: 'Always on. The Wake word engine select is the off switch.',
  category: 'Voice Satellite',
  hidden: true,
  normalizer: alwaysOnSetting,
);

/// Kiosk Satellite fetches the quantized `int8/` model siblings by default
/// (~35% faster inference, same manifest and thresholds). This opts back into
/// the original fp32 files for users who want zero quantization drift.
const wakeWordPreferFp32 = SettingDef<bool>(
  key: 'wake_word.prefer_fp32',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Prefer fp32 vsWakeWord models',
  description:
      'Uses fp32 models instead of smaller int8 versions. Adds 10-30% '
      'more CPU usage while listening to avoid about 2% confidence drift.',
  category: 'Voice Satellite',
  subpage: 'Wake Word',
  dependsOn: 'wake_word.enabled',
);

const wakeWordBackground = SettingDef<bool>(
  key: 'wake_word.background',
  type: SettingType.boolean,
  // Off: it costs a permanent notification and two more OS grants, which is a
  // poor trade for a kiosk that is never behind another app — the normal case.
  defaultValue: false,
  title: 'Keep listening in the background',
  description:
      'Keep hearing the wake word while another app is in front, and '
      'return on a detection. Needs a permanent notification and '
      'display over other apps.',
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
  subpage: 'Wake Word',
  dependsOn: 'wake_word.enabled',
);

// Hidden: rendered as hand-built dropdowns (device settings screen and the
// remote UI both) because the option lists are live hardware, not constants.
// Value is AudioRouting's stable selector "type|address|name"; empty means
// automatic (Android routes).
const audioMicDevice = SettingDef<String>(
  key: 'audio.mic_device',
  type: SettingType.string,
  defaultValue: '',
  title: 'Microphone',
  description:
      'The microphone wake word detection and voice turns capture from.',
  category: 'Screen & Audio',
  hidden: true,
);

const audioSpeakerDevice = SettingDef<String>(
  key: 'audio.speaker_device',
  type: SettingType.string,
  defaultValue: '',
  title: 'Speaker',
  description:
      'Output for Voice Satellite sounds; media playback follows the system '
      'route. Echo cancellation only works with the microphone and speaker '
      'on the same device.',
  category: 'Screen & Audio',
  hidden: true,
);

// Hidden: the pipeline delegation is negotiated transparently, exactly like
// the wake-word handoff — a Voice Satellite that knows the API uses it, any
// other keeps the page path, and every failure falls back at runtime. No
// user decision exists, so no row exists. The setting stays as a remote
// kill switch (/api/settings) so a field problem can isolate the native
// path without downgrading the app.
const vsNativePipeline = SettingDef<bool>(
  key: 'vs.native_pipeline',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Native voice pipeline',
  description:
      'Voice audio goes straight from the app to Home Assistant, which '
      'keeps speech recognition steady on slow devices.',
  category: 'Voice Satellite',
  hidden: true,
);

// ── Home Assistant ─────────────────────────────────────────────────────

const haUrl = SettingDef<String>(
  key: 'ha.url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Home Assistant base URL',
  description:
      'e.g. https://homeassistant.local:8123, without a dashboard path.',
  category: 'Home Assistant',
  validator: validateBaseUrl,
  normalizer: normalizeBaseUrlSetting,
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

/// Sign the dashboard in with the long-lived access token the app already
/// holds: the token is seeded as the frontend's session (localStorage
/// `hassTokens`, see ha_session_script.dart) at document start, so a fresh
/// kiosk never shows the Home Assistant login form. Seeded only where the
/// page has no session of its own — a login someone did by hand, or a
/// session the frontend refreshed, always wins — so turning this off stops
/// future seeding without logging anything out.
const haAutoLogin = SettingDef<bool>(
  key: 'ha.auto_login',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Log in automatically',
  description:
      'Sign in to the dashboard with the access token above instead of '
      'showing the Home Assistant login page.',
  category: 'Home Assistant',
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

const haKioskMode = SettingDef<bool>(
  key: 'ha.kiosk_mode',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'HA kiosk mode',
  description:
      'Hide the Home Assistant header and sidebar. Applies immediately.',
  category: 'Home Assistant',
  section: 'User Interface',
  subpage: 'User Interface',
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
  section: 'User Interface',
  subpage: 'User Interface',
);

const haKioskHideSidebar = SettingDef<bool>(
  key: 'ha.kiosk_hide_sidebar',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Hide the sidebar',
  description: 'Hide the navigation sidebar while HA kiosk mode is on.',
  category: 'Home Assistant',
  section: 'User Interface',
  subpage: 'User Interface',
);

/// Swipe navigation between the current dashboard's views (in-page script,
/// see carousel_script.dart). The natural companion to hiding the header:
/// on a small screen the view tabs are the last navigation left, and this
/// gives their job to the whole screen instead. Strategy dashboards without
/// listable views and single-view dashboards leave the script inert.
const haDashboardCarousel = SettingDef<bool>(
  key: 'ha.dashboard_carousel',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable dashboard carousel',
  description:
      'Swipe left or right on the dashboard to move between its views. '
      'Swipes on sliders, maps and scrolling cards are left alone.',
  category: 'Home Assistant',
  section: 'User Interface',
  subpage: 'User Interface',
);

/// Carousel priority over gesture-handling cards (#238). By default a
/// swipe that starts on a media element or a card that handles swipes
/// itself is never claimed, which makes a fullscreen camera card (a
/// fullscreen video under the finger) a dead zone for view navigation.
/// With this on, the carousel claims those swipes and eats the touch and
/// pointer streams once a drag locks, so the card cannot also react.
/// Sliders, dialogs, maps, form controls and natively scrolling cards
/// stay protected either way: a natively scrolling card cannot be
/// silenced (only preventDefault stops native scroll, and the carousel's
/// listeners are passive), and a slider swallowing a swipe is exactly
/// the regression the reporter warned about.
const haCarouselOverCards = SettingDef<bool>(
  key: 'ha.carousel_over_cards',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Capture swipe gestures over cards',
  description:
      'Switch views even when the swipe starts on a card that reacts '
      'to swipes. Sliders still work normally.',
  category: 'Home Assistant',
  section: 'User Interface',
  subpage: 'User Interface',
  dependsOn: 'ha.dashboard_carousel',
);

/// Haptic feedback for the dashboard (in-page script, see
/// haptics_script.dart): a short native click whenever a tap lands on
/// something button-shaped, and a lighter tick per step while a slider
/// or thermostat wheel drags, so a wall panel answers like a physical
/// switch. Uses the platform vibrator directly, so it works even where
/// the system's own touch-feedback setting is off; devices without a
/// vibrator (most Fire tablets, Echo Shows) leave the toggle a no-op.
const haHaptics = SettingDef<bool>(
  key: 'ha.haptics',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Enable haptics',
  description:
      'Vibrate when buttons, switches, cards, sliders and thermostat '
      'dials are used. Requires a vibration motor.',
  category: 'Home Assistant',
  section: 'Haptics',
  subpage: 'User Interface',
);

/// How hard the buzz hits. Read Dart-side per tap (never seeded into the
/// page), so a change applies to the very next touch with no reload and
/// no page contract. Buttons get the chosen level; slider ticks always
/// sit one level softer so a drag reads as texture, not as taps.
const haHapticsStrength = SettingDef<String>(
  key: 'ha.haptics_strength',
  type: SettingType.select,
  defaultValue: 'medium',
  title: 'Vibration strength',
  description: 'How strong the vibration feels.',
  category: 'Home Assistant',
  section: 'Haptics',
  subpage: 'User Interface',
  options: ['light', 'medium', 'strong'],
  optionLabels: {'light': 'Light', 'medium': 'Medium', 'strong': 'Strong'},
  dependsOn: 'ha.haptics',
);

/// The system tap sound for the dashboard, riding the same in-page
/// detector as the haptics above (see haptics_script.dart): the standard
/// Android click on every accepted button tap, and a quieter one per
/// slider step. TapSoundBridge.kt plays the platform's own click sample
/// from an app-owned SoundPool, so it matches the sound the app's Flutter
/// buttons make while the system's separate "touch sounds" setting cannot
/// silently veto it.
const haTapSound = SettingDef<bool>(
  key: 'ha.tap_sound',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Play tap sounds',
  description:
      'Play the standard tap sound when buttons, switches, cards, sliders '
      'and thermostat dials are used.',
  category: 'Home Assistant',
  section: 'Haptics',
  subpage: 'User Interface',
);

/// Gain applied to the click, read Dart-side per event like the
/// vibration strength, so the slider applies to the very next tap with no
/// reload. The platform never plays its own touch sounds at full scale;
/// it attenuates them by a per-device config value, so 100% here lands
/// startlingly loud next to the app's own Flutter clicks. 50% is the
/// default because it matched the Flutter interface's loudness by ear on
/// every device tried (Echo Show and Samsung tablet alike, -6 dB, the
/// AOSP default attenuation); slider ticks keep their fixed fraction of
/// whatever this says.
const haTapSoundVolume = SettingDef<num>(
  key: 'ha.tap_sound_volume',
  type: SettingType.number,
  defaultValue: 50,
  min: 0,
  max: 100,
  step: 5,
  unit: '%',
  title: 'Tap sound volume',
  description: 'How loud the tap sound plays.',
  category: 'Home Assistant',
  section: 'Haptics',
  subpage: 'User Interface',
  dependsOn: 'ha.tap_sound',
);

/// The theme pinned from Home Assistant: a select entity on the ESPHome
/// surface (and the first row of the Theme page), so an automation can
/// drive light and dark from a sun trigger and a person can override it by
/// hand across every kiosk. Light and Dark outrank the schedule and the
/// mirror below; Auto hands control back to them.
const haTheme = SettingDef<String>(
  key: 'ha.theme',
  type: SettingType.select,
  defaultValue: 'auto',
  title: 'Theme',
  description:
      'Light or dark for the Home Assistant dashboard, also set from the '
      'Theme entity in Home Assistant. Auto follows the settings below.',
  category: 'Home Assistant',
  section: 'Theme',
  subpage: 'Theme',
  options: ['auto', 'light', 'dark'],
  optionLabels: {'auto': 'Auto', 'light': 'Light', 'dark': 'Dark'},
);

/// Mirror the app's effective theme onto the Home Assistant dashboard
/// (issue #92): with the App theme on "System", Android flips dark mode on
/// its own schedule (typically sunset/sunrise), and the dashboard follows.
/// With this on, the time schedule below drives the APP theme and the
/// mirror carries it to the dashboard, so every source stays consistent:
/// schedule -> app -> dashboard. Supersedes "Also switch the app theme",
/// which hides while this holds.
const themeMatchApp = SettingDef<bool>(
  key: 'ha.theme_match_app',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Sync Home Assistant themes with Kiosk Satellite',
  description:
      'Automatically match your Home Assistant theme to your Kiosk '
      'Satellite interface.',
  category: 'Home Assistant',
  section: 'Theme',
  subpage: 'Theme',
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
  subpage: 'Theme',
);

const themeDarkAt = SettingDef<String>(
  key: 'ha.theme_dark_at',
  type: SettingType.string,
  defaultValue: '19:00',
  title: 'Dark theme at',
  description: 'Local time to switch to the dark theme.',
  category: 'Home Assistant',
  section: 'Theme',
  subpage: 'Theme',
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
  subpage: 'Theme',
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
  subpage: 'Theme',
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
  title: 'Enable dashboard view rotation',
  description:
      'Cycle through the selected dashboard views in an endless loop, '
      'showing each one for the chosen number of seconds.',
  category: 'Home Assistant',
  section: 'Dashboard View Rotation',
  subpage: 'Dashboard View Rotation',
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
  subpage: 'Dashboard View Rotation',
  hidden: true,
);

// Hidden: hand-built list UIs in both settings surfaces own this value —
// external pages shown in their own overlay WebView during rotation, so
// the dashboard (and Voice Satellite) stays loaded underneath.
const haRotationUrls = SettingDef<String>(
  key: 'ha.rotation_urls',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Rotation external pages',
  description: 'External pages included in the dashboard view rotation.',
  category: 'Home Assistant',
  subpage: 'Dashboard View Rotation',
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
  subpage: 'Dashboard View Rotation',
  dependsOn: 'ha.rotation_enabled',
);

const haRotationPauseSeconds = SettingDef<num>(
  key: 'ha.rotation_pause_seconds',
  type: SettingType.number,
  defaultValue: 30,
  title: 'Pause rotation on interaction (seconds)',
  description:
      'Touching the screen pauses rotation for this long, and each '
      'touch restarts the countdown. Voice interactions pause until '
      'they end. 0 keeps rotating through touches.',
  category: 'Home Assistant',
  section: 'Dashboard View Rotation',
  subpage: 'Dashboard View Rotation',
  dependsOn: 'ha.rotation_enabled',
);

/// Issue #189. In-page only: views of the same dashboard fade out to the
/// theme background and back in on the new view (see
/// rotation_fade_script.dart); a hop to a different dashboard, a
/// hard-loaded strategy dashboard or an external page still cuts. The key
/// keeps its original "crossfade" name from the first dissolve-based
/// implementation so existing configurations carry over.
const haRotationCrossfade = SettingDef<bool>(
  key: 'ha.rotation_crossfade',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Fade between views',
  description:
      'Fade out to the background and into the next view instead of '
      'switching instantly. Moving to a different dashboard or an '
      'external page still switches instantly.',
  category: 'Home Assistant',
  section: 'Dashboard View Rotation',
  subpage: 'Dashboard View Rotation',
  dependsOn: 'ha.rotation_enabled',
);

/// Return to the configured dashboard after inactivity (issue #83): the
/// Fully Kiosk "Return to Start URL" for people who wander to a lights
/// page and walk away. Runs its own idle clock, independent of the
/// screensaver's; when the screensaver fires first, the return happens
/// quietly behind it at start. Stands down entirely — and is forced off —
/// while dashboard view rotation is on: rotation owns navigation on an
/// idle kiosk.
const haReturnHomeEnabled = SettingDef<bool>(
  key: 'ha.return_home_enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Return to home dashboard view',
  description:
      'Go back to the dashboard configured above after a period of '
      'inactivity.',
  category: 'Home Assistant',
  section: 'Return to home dashboard view',
  subpage: 'Return to home dashboard view',
);

const haReturnHomeSeconds = SettingDef<num>(
  key: 'ha.return_home_seconds',
  type: SettingType.number,
  defaultValue: 120,
  min: 10,
  title: 'Return after (seconds)',
  description: 'Inactivity period before the kiosk goes back.',
  category: 'Home Assistant',
  section: 'Return to home dashboard view',
  subpage: 'Return to home dashboard view',
  dependsOn: 'ha.return_home_enabled',
);

/// Hold mode (issue #266): pin the current view until released. The toggle
/// IS the live state, not a feature gate: flipping it here, from the remote
/// admin, over MQTT/ESPHome or by gesture all drive the same setting, so
/// every surface stays in step and the state survives a restart. While on,
/// the screensaver will not start, dashboard view rotation freezes in
/// place, the return-home timer stands down and the display stays awake.
const haHoldMode = SettingDef<bool>(
  key: 'ha.hold_mode',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Hold mode',
  description:
      'Keep the current view on screen: the screensaver, dashboard view '
      'rotation and the return to home timer are paused until turned off.',
  category: 'Home Assistant',
  section: 'Hold mode',
  subpage: 'Hold mode',
);

/// The forgotten-hold guard: a kiosk left on hold overnight never sleeps
/// again, so an optional clock releases it. Not gated on the toggle: the
/// duration is configured ahead of time, before hold is ever engaged.
const haHoldReleaseMinutes = SettingDef<num>(
  key: 'ha.hold_release_minutes',
  type: SettingType.number,
  defaultValue: 0,
  min: 0,
  max: 360,
  step: 15,
  title: 'End hold automatically after',
  description:
      'Turns hold mode off by itself after the set time. Set to 0 to hold '
      'until turned off manually.',
  category: 'Home Assistant',
  section: 'Hold mode',
  subpage: 'Hold mode',
);

/// The on-device way in, opt-in like the Sendspin player's menu entry
/// (issue #257): the drawer entry reads "Turn On/Off Hold Mode" following
/// the live state. The active-hold notice shows regardless of this toggle;
/// this only adds the entry that can also engage a hold.
const haHoldMenu = SettingDef<bool>(
  key: 'ha.hold_menu',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show in the kiosk menu',
  description: 'Adds a menu entry that turns hold mode on and off.',
  category: 'Home Assistant',
  section: 'Hold mode',
  subpage: 'Hold mode',
);

// ── MQTT ───────────────────────────────────────────────────────────────
// Ready-made Home Assistant entities over MQTT discovery (issue #11). The
// broker settings live here; everything the entities do routes through the
// same CommandRegistry commands and bus events every other surface uses.

const mqttEnabled = SettingDef<bool>(
  key: 'mqtt.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Publish to MQTT',
  description:
      'Create ready-made Home Assistant entities for this device via MQTT '
      'discovery: screen, brightness, battery and more. No YAML needed.',
  category: 'MQTT',
);

const mqttHost = SettingDef<String>(
  key: 'mqtt.host',
  type: SettingType.string,
  defaultValue: '',
  title: 'Server',
  description:
      'Hostname or IP of the MQTT broker, for example homeassistant.local '
      'when using the Mosquitto add-on.',
  category: 'MQTT',
  dependsOn: 'mqtt.enabled',
);

const mqttPort = SettingDef<num>(
  key: 'mqtt.port',
  type: SettingType.number,
  defaultValue: 1883,
  title: 'Port',
  description: '1883 is the MQTT default; 8883 is the usual TLS port.',
  category: 'MQTT',
  dependsOn: 'mqtt.enabled',
);

const mqttTls = SettingDef<bool>(
  key: 'mqtt.tls',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Use TLS',
  description: 'Encrypt the broker connection.',
  category: 'MQTT',
  dependsOn: 'mqtt.enabled',
);

const mqttUsername = SettingDef<String>(
  key: 'mqtt.username',
  type: SettingType.string,
  defaultValue: '',
  title: 'Username',
  description: 'Leave empty when the broker allows anonymous access.',
  category: 'MQTT',
  dependsOn: 'mqtt.enabled',
);

const mqttPassword = SettingDef<String>(
  key: 'mqtt.password',
  type: SettingType.password,
  defaultValue: '',
  title: 'Password',
  description: 'Leave empty when the broker allows anonymous access.',
  category: 'MQTT',
  secret: true,
  dependsOn: 'mqtt.enabled',
);

const mqttDiscoveryPrefix = SettingDef<String>(
  key: 'mqtt.discovery_prefix',
  type: SettingType.string,
  defaultValue: 'homeassistant',
  title: 'Discovery prefix',
  description:
      "Home Assistant's MQTT discovery prefix. Leave at homeassistant "
      'unless yours was changed.',
  category: 'MQTT',
  dependsOn: 'mqtt.enabled',
);

/// Stable per-install identity behind every MQTT topic and unique_id, so
/// several tablets on one broker never collide and a reinstalled app gets a
/// fresh device rather than adopting a stale one. Generated on first MQTT
/// start; never shown.
const mqttDeviceId = SettingDef<String>(
  key: 'mqtt.device_id',
  type: SettingType.string,
  defaultValue: '',
  title: 'MQTT device id',
  description: 'Internal identity for MQTT topics.',
  category: 'MQTT',
  hidden: true,
);

// Android WebViews advertise H.265 receive support in the SDP offer whether
// or not anything on the device can decode it: the stream negotiates, packets
// arrive, and not a single frame is decoded, so the tile sits black with no
// error anywhere (issue #160). Off by default, which offers H.264 only and
// lets a Go2RTC server with ffmpeg transcode an H.265 camera instead.
const cameraAllowH265 = SettingDef<bool>(
  key: 'camera.allow_h265',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Allow H.265 streams',
  description:
      'Play H.265 camera streams as they are. A device that cannot decode '
      'H.265 shows a blank image instead.',
  category: 'Cameras',
);

// Off by default: WebRTC is near-realtime and stays the first choice, with
// MSE as the automatic fallback when a stream connects and decodes nothing
// (issue #160). On, the order flips — for devices whose browser cannot do
// WebRTC at all (Fire tablets), and for forcing MSE to test it.
const cameraPreferMse = SettingDef<bool>(
  key: 'camera.prefer_mse',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Prefer MSE over WebRTC',
  description:
      'Stream Go2RTC cameras over MSE first. For devices that cannot play '
      'WebRTC; adds a second or two of delay.',
  category: 'Cameras',
);

// The HLS twin of the toggle above, for Home Assistant cameras that offer
// both transports: WebRTC leads for latency, HLS is the automatic fallback.
// On, the order flips — for devices whose WebRTC cannot play these streams,
// and for forcing HLS to test it.
const cameraPreferHls = SettingDef<bool>(
  key: 'camera.prefer_hls',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Prefer HLS over WebRTC',
  description:
      'Stream Home Assistant cameras over HLS first. For devices that '
      'cannot play WebRTC; adds a few seconds of delay.',
  category: 'Cameras',
);

// Sound only ever makes sense for one camera at a time: a grid playing four
// microphones at once is noise, so the grid stays video-only and this toggle
// applies where exactly one camera fills the view — a one-camera view, or a
// focused tile. Off by default; the baby-monitor case turns it on (issue
// #235).
const cameraSingleAudio = SettingDef<bool>(
  key: 'camera.single_audio',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Play sound for a single camera',
  description:
      "Play the camera's sound when only one camera is on screen. Grids "
      'with several cameras stay silent.',
  category: 'Cameras',
);

// Wide-angle cameras put the thing worth looking at in a corner of the
// frame, and a kiosk has no other way to get closer to it (issue #286).
// Same rule as the sound above: only where one camera fills the view, since
// pinching a grid tile would zoom whatever the fingers happened to land on.
// On by default; turning it off leaves the view's taps and swipes alone.
const cameraPinchZoom = SettingDef<bool>(
  key: 'camera.pinch_zoom',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Pinch to zoom a single camera',
  description:
      'Zoom into the picture with two fingers when only one camera is on '
      'screen. Drag to move around, double-tap to reset.',
  category: 'Cameras',
);

// A glance at the cameras from a clap or a corner tap should not stay up
// forever on a wall panel. Applies to the camera view overlay however it was
// opened (gesture, MQTT, the drawer); the screensaver's camera mode is its
// own surface and never touched by this.
const cameraAutoDismissSeconds = SettingDef<num>(
  key: 'camera.auto_dismiss_seconds',
  type: SettingType.number,
  defaultValue: 0,
  min: 0,
  max: 300,
  step: 30,
  unit: ' s',
  title: 'Auto-dismiss after',
  description:
      'Close an opened camera view on its own; 0 keeps it up. The camera '
      'screensaver is unaffected.',
  category: 'Cameras',
);

// Hidden because Cameras has a purpose-built editor on the device and in the
// remote admin. Marking the versioned document secret keeps server credentials
// out of the generic settings API while still including them in full backups.
const cameraConfig = SettingDef<String>(
  key: 'camera.config',
  type: SettingType.string,
  defaultValue: '{"version":1,"servers":[],"cameras":[],"views":[]}',
  title: 'Camera configuration',
  description: 'Go2RTC servers, camera sources, and camera views.',
  category: 'Cameras',
  hidden: true,
  secret: true,
);

// ── Media Player ───────────────────────────────────────────────────────
// The Now Playing surfaces (the floating card, the full-screen view, the
// kiosk menu entries) and the players they can follow: this device as a
// synchronized Sendspin audio player (the Music Assistant native protocol,
// whose client lives in Kotlin under sendspin/), a Music Assistant player,
// a Home Assistant media player, or a Sonos speaker followed directly.
// The category keeps its Sendspin id and keys from when it was only the
// local player.

/// Which player the floating card, the full-screen view and the transport
/// controls follow: empty is this device's own Sendspin player, otherwise
/// `ma:<player id>` for a Music Assistant player, `ha:<entity id>` for a
/// Home Assistant media player or `sonos:<player id>` for a Sonos speaker
/// followed directly. Visible so both settings surfaces place it first,
/// but its row is hand-built on each: a grouped picker fed by the live
/// player lists, never a text field.
const sendspinPlayer = SettingDef<String>(
  key: 'sendspin.player',
  type: SettingType.string,
  defaultValue: '',
  title: 'Player',
  description:
      'What the floating player and Now Playing show and control: this '
      'device, or a player elsewhere.',
  category: 'Sendspin',
  section: 'Player',
);

/// The picked player's display name: what the settings rows show and what
/// the Now Playing view's chip says. Stored beside the id so neither
/// surface needs the player's system just to say what is selected.
const sendspinPlayerName = SettingDef<String>(
  key: 'sendspin.player_name',
  type: SettingType.string,
  defaultValue: '',
  title: 'Controlled player name',
  description: 'Internal display name of the controlled player.',
  category: 'Sendspin',
  hidden: true,
);

/// The Sonos speakers this device has met, as JSON: player id to host
/// and room name. Discovery only reaches the tablet's own VLAN, so a
/// speaker added by address (or found once) is remembered here and the
/// picker lists its whole household from it without a search.
const sendspinSonosHosts = SettingDef<String>(
  key: 'sendspin.sonos_hosts',
  type: SettingType.string,
  defaultValue: '{}',
  title: 'Known Sonos speakers',
  description: 'Internal: the Sonos speakers found or added by address.',
  category: 'Sendspin',
  hidden: true,
);

const sendspinEnabled = SettingDef<bool>(
  key: 'sendspin.enabled',
  // Gone while another player is followed (issue #265): the local player
  // never runs in that mode, so the switch could not do anything. The
  // local-audio rows below ride this dependsOn transitively, and the
  // page entry goes with them.
  dependsOn: 'sendspin.player',
  dependsOnValue: '',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable Sendspin player',
  description:
      'Turn this device into a synchronized Sendspin player. It appears '
      'in Music Assistant under the device name, in sync with every '
      'other Sendspin speaker.',
  category: 'Sendspin',
  subpage: 'Sendspin Player',
  section: 'Sendspin Player',
);

const sendspinServer = SettingDef<String>(
  key: 'sendspin.server',
  type: SettingType.string,
  defaultValue: '',
  title: 'Server',
  description:
      'Sendspin server address, for example 192.168.1.10:8927. Leave '
      'empty to find the server on the network automatically.',
  category: 'Sendspin',
  subpage: 'Sendspin Player',
  section: 'Sendspin Player',
  dependsOn: 'sendspin.enabled',
);

const sendspinCodec = SettingDef<String>(
  key: 'sendspin.codec',
  type: SettingType.select,
  defaultValue: 'flac',
  title: 'Preferred audio codec',
  description:
      'FLAC is lossless and ideal on WiFi or ethernet. The server makes '
      'the final choice from what this device offers.',
  category: 'Sendspin',
  subpage: 'Sendspin Player',
  section: 'Sendspin Player',
  options: ['flac', 'opus', 'pcm'],
  optionLabels: {
    'flac': 'FLAC (lossless)',
    'opus': 'Opus (efficient)',
    'pcm': 'PCM (uncompressed)',
  },
  dependsOn: 'sendspin.enabled',
);

/// Per-device playback offset (issue: Bluetooth speakers). The sync engine
/// can only align what it can measure, and a Bluetooth speaker's own buffer
/// sits past the DAC where Android's timestamps cannot see it — so that one
/// endpoint lags the group and the only remedy used to be delaying twenty
/// others. Negative plays this device earlier by the same amount instead.
const sendspinSyncOffset = SettingDef<num>(
  key: 'sendspin.sync_offset_ms',
  type: SettingType.number,
  defaultValue: 0,
  min: -1000,
  max: 1000,
  step: 10,
  unit: 'ms',
  title: 'Audio sync offset (ms)',
  description:
      'Negative plays this device earlier, for speakers that lag behind '
      'the group (Bluetooth). Tune by ear; applies live.',
  category: 'Sendspin',
  subpage: 'Sendspin Player',
  section: 'Sendspin Player',
  dependsOn: 'sendspin.enabled',
);

const sendspinDuckPercent = SettingDef<num>(
  key: 'sendspin.duck_percent',
  type: SettingType.number,
  defaultValue: 10,
  title: 'Duck volume during voice interactions',
  description:
      'While the assistant listens or speaks, music drops to this '
      'fraction of its volume so the microphone hears you. Capped at '
      '25% to keep detection reliable.',
  category: 'Sendspin',
  subpage: 'Sendspin Player',
  section: 'Sendspin Player',
  min: 0,
  max: 25,
  step: 5,
  unit: '%',
  dependsOn: 'sendspin.enabled',
);

// ── Music Assistant (Sendspin section) ─────────────────────────────────
// The Sendspin player speaks Music Assistant's player protocol, which
// carries the track but nothing about it beyond title, artist and album.
// Anything richer — lyrics, the queue, favorites — comes from Music
// Assistant's own API, which is a separate connection with its own
// address and token.

const sendspinMaUrl = SettingDef<String>(
  key: 'sendspin.ma_url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Server address',
  description:
      "The Music Assistant server's address, as its web interface shows "
      'it. Usually https and port 8095.',
  category: 'Sendspin',
  subpage: 'Music Assistant',
  section: 'Music Assistant',
  placeholder: 'https://192.168.1.10:8095',
);

const sendspinMaToken = SettingDef<String>(
  key: 'sendspin.ma_token',
  type: SettingType.password,
  defaultValue: '',
  title: 'Auth token',
  description:
      'A long-lived token from Music Assistant (Settings, then Users). '
      'Read access is enough for lyrics; the kiosk menu shortcut opens '
      'the web interface as whoever the token belongs to.',
  category: 'Sendspin',
  subpage: 'Music Assistant',
  section: 'Music Assistant',
  // As with the Home Assistant token: masks the row on a wall-mounted
  // screen, and keeps the token out of a configuration export unless the
  // export was explicitly asked to carry secrets.
  secret: true,
);

/// The name the local player last registered with in Music Assistant —
/// the device name, or the hardware model when none is set. Stored by
/// SendspinManager at every player start so the Music Assistant shortcut
/// can land the web interface on this device's own player without
/// re-deriving the name (issue #265).
const sendspinLocalPlayerName = SettingDef<String>(
  key: 'sendspin.local_player_name',
  type: SettingType.string,
  defaultValue: '',
  title: 'Local player name',
  description: 'Internal: the name the local player wears in Music Assistant.',
  category: 'Sendspin',
  hidden: true,
);

/// Whether the player surface (the card, the full-screen view, the menu
/// entries) has anything to show for: the local player is enabled, or
/// another player is followed. A bookkeeping flag maintained by
/// SendspinManager, existing so the card rows can gate on "either mode"
/// — dependsOn can express a chain of ANDs but not an OR.
const sendspinPlayerActive = SettingDef<bool>(
  key: 'sendspin.player_active',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Sendspin player surface active',
  description: 'Internal: the player card has a source in either mode.',
  category: 'Sendspin',
  hidden: true,
);

/// The kiosk menu's way into Music Assistant itself (browsing, queueing,
/// playlists). Deliberately not a player UI of our own: Music Assistant's
/// web interface is already complete, already maintained, and already the
/// one the household knows — the shortcut simply puts it a swipe away,
/// over the dashboard, on the surface a tapped link would get.
const sendspinMaShortcut = SettingDef<bool>(
  key: 'sendspin.ma_shortcut',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Show in the kiosk menu',
  description:
      "Add a Music Assistant entry to the kiosk menu, opening the server's "
      'web interface over the dashboard. Needs the server address above.',
  category: 'Sendspin',
  subpage: 'Music Assistant',
  section: 'Kiosk menu',
);

/// A wall tablet's way back to the dashboard when whoever queued a song
/// walked off: the dashboard is what the screen is for, and a Music
/// Assistant page left open is a screen doing nothing. Zero keeps it up
/// until someone closes it, which is right for a desk.
const sendspinMaAutoClose = SettingDef<num>(
  key: 'sendspin.ma_auto_close',
  type: SettingType.number,
  defaultValue: 0,
  title: 'Close after inactivity',
  description:
      'Return to the dashboard when nobody has touched the Music Assistant '
      'page for this long. Zero leaves it open until it is closed.',
  category: 'Sendspin',
  subpage: 'Music Assistant',
  section: 'Kiosk menu',
  dependsOn: 'sendspin.ma_shortcut',
  min: 0,
  max: 60,
  step: 5,
  unit: 's',
);

/// Music Assistant's full-screen "now playing" view puts its own
/// three-dot menu exactly where the overlay's floating close button sits,
/// so the button steals those taps (issue #264). Opt-in removal for the
/// people who use that menu: the back button, a wake word and the
/// inactivity timer still close the page.
const sendspinMaHideClose = SettingDef<bool>(
  key: 'sendspin.ma_hide_close',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Hide the close button',
  description:
      'The floating close button can sit on top of Music Assistant\'s own '
      'controls, like the Now Playing menu. Without it, dismiss with the '
      "back button or by using the kiosk's drawer menu.",
  category: 'Sendspin',
  subpage: 'Music Assistant',
  section: 'Kiosk menu',
  dependsOn: 'sendspin.ma_shortcut',
);

// ── Floating Player (Sendspin section) ─────────────────────────────────
// The small now-playing card over the dashboard, whichever player it
// follows.

const sendspinShowPlayer = SettingDef<bool>(
  key: 'sendspin.show_player',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Show the floating player',
  description:
      'While music plays, show a small now-playing window over the '
      'dashboard with artwork, track info and progress. Drag it anywhere; '
      'the position is remembered.',
  category: 'Sendspin',
  subpage: 'Floating Player',
  section: 'Floating Player',
  dependsOn: 'sendspin.player_active',
);

const sendspinPlayerSize = SettingDef<String>(
  key: 'sendspin.player_size',
  type: SettingType.select,
  defaultValue: 'compact',
  title: 'Player size',
  description:
      'Compact is a small, unobtrusive now-playing window. Large adds '
      'previous, play/pause and next buttons sized for touch, controlling '
      'the whole playback group.',
  category: 'Sendspin',
  subpage: 'Floating Player',
  section: 'Floating Player',
  options: ['compact', 'large'],
  optionLabels: {'compact': 'Compact', 'large': 'Large with controls'},
  dependsOn: 'sendspin.show_player',
);

const sendspinPausedHideMinutes = SettingDef<num>(
  key: 'sendspin.paused_hide_minutes',
  type: SettingType.number,
  defaultValue: 3,
  title: 'Hide the paused player after',
  description:
      'How long a paused player stays on screen. It applies to both the '
      'floating player and the Now Playing view.',
  category: 'Sendspin',
  subpage: 'Floating Player',
  section: 'Floating Player',
  min: 1,
  max: 10,
  step: 1,
  unit: 'min',
  dependsOn: 'sendspin.show_player',
);

const sendspinDismissKeepsPlaying = SettingDef<bool>(
  key: 'sendspin.dismiss_keeps_playing',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Keep playing when dismissed',
  description:
      'Flinging the floating player away hides it without stopping the '
      'music.',
  category: 'Sendspin',
  subpage: 'Floating Player',
  section: 'Floating Player',
  dependsOn: 'sendspin.player_active',
);

/// The floating player's own menu entry (issue #257): show or hide the
/// card without a gesture to configure or remember. Deliberately
/// independent of `sendspin.show_player` — a player configured not to pop
/// up on its own can still be summoned from the menu, for this session
/// only, without that setting changing underneath its owner.
const sendspinPlayerShortcut = SettingDef<bool>(
  key: 'sendspin.player_shortcut',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show in the kiosk menu',
  description:
      'Add an entry in the kiosk menu that shows or hides the floating '
      "player. WARNING: If nothing is playing or there is no queue for "
      "this player, it won't show up.",
  category: 'Sendspin',
  subpage: 'Floating Player',
  section: 'Floating Player',
  dependsOn: 'sendspin.player_active',
);

// ── Now Playing (Sendspin section) ─────────────────────────────────────
// The full-screen music display that stands in for the screensaver. Its
// own page: the rows decide what the screen does while music plays, not
// how the player plays it.

const sendspinFullscreen = SettingDef<bool>(
  key: 'sendspin.fullscreen',
  type: SettingType.boolean,
  defaultValue: false,
  title: '"Now Playing" instead of the screensaver',
  description:
      'While music plays, the screensaver becomes a full-screen Now '
      'Playing view with album art. With nothing playing, the regular '
      'screensaver runs.',
  category: 'Sendspin',
  subpage: 'Now Playing',
  section: 'Now Playing',
  dependsOn: 'sendspin.player_active',
);

/// The transport on the full-screen view: the same previous, play/pause
/// and next buttons the large floating card carries, plus a progress bar
/// that seeks where the server allows it. With controls on screen a tap
/// can no longer mean "dismiss", so the view grows a close button and the
/// screensaver's touch dismissal stands down for it (the back button and
/// the motion policy are unchanged).
const sendspinFullscreenControls = SettingDef<bool>(
  key: 'sendspin.fullscreen_controls',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Show media controls',
  description:
      'Previous, play/pause and next buttons and a progress bar on the '
      'Now Playing view. With controls on, a close button dismisses it '
      'instead of a tap anywhere.',
  category: 'Sendspin',
  subpage: 'Now Playing',
  section: 'Now Playing',
  dependsOn: 'sendspin.fullscreen',
);

/// Dismiss the view with a double tap anywhere on it instead of the close
/// button, which goes away (issue #409: hunting for the button on a
/// screen everyone is used to tapping). Taps on the transport, the
/// toggles and the queue rows never count, so a quick double press on
/// Next skips twice rather than closing the view.
const sendspinFullscreenDoubleTap = SettingDef<bool>(
  key: 'sendspin.fullscreen_double_tap',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Double tap to dismiss',
  description:
      'A double tap anywhere on the Now Playing view dismisses it. The '
      "close button won't be shown.",
  category: 'Sendspin',
  subpage: 'Now Playing',
  section: 'Now Playing',
  dependsOn: 'sendspin.fullscreen_controls',
);

/// Bring the view up the moment playback starts rather than waiting for
/// the idle timeout: the display is the point of the music, and someone
/// who queued a song from their phone expects the wall to show it now.
const sendspinFullscreenOnPlay = SettingDef<bool>(
  key: 'sendspin.fullscreen_on_play',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Launch Now Playing when music starts playing',
  description:
      'Open the Now Playing view as soon as playback starts instead of '
      'waiting for the screensaver timeout.',
  category: 'Sendspin',
  subpage: 'Now Playing',
  section: 'Now Playing',
  dependsOn: 'sendspin.fullscreen',
);

const sendspinFullscreenMotion = SettingDef<bool>(
  key: 'sendspin.fullscreen_motion',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Dismiss "Now Playing" on motion',
  description:
      'Let motion dismiss Now Playing like a regular screensaver. Off, '
      'only touch dismisses it, so a walk-past does not interrupt the '
      'music display.',
  category: 'Sendspin',
  subpage: 'Now Playing',
  section: 'Now Playing',
  dependsOn: 'sendspin.fullscreen',
);

/// The kiosk menu's way to the Now Playing view on demand, the twin of
/// the floating player's entry: the entry shows while a track is loaded
/// and brings the view up, paused with its play button if the music is.
const sendspinFullscreenShortcut = SettingDef<bool>(
  key: 'sendspin.fullscreen_shortcut',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show in the kiosk menu',
  description:
      'Add an entry in the kiosk menu that shows the Now Playing view. '
      "WARNING: If nothing is playing or there is no queue for this "
      "player, it won't show up.",
  category: 'Sendspin',
  subpage: 'Now Playing',
  section: 'Now Playing',
  dependsOn: 'sendspin.fullscreen',
);

const sendspinLyrics = SettingDef<bool>(
  key: 'sendspin.lyrics',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show lyrics',
  description:
      'Show the current track\'s lyrics on the Now Playing screen, in time '
      'with the music. Music Assistant supplies them when it is set up '
      '(local .lrc files included); other tracks are looked up on LRCLIB.',
  category: 'Sendspin',
  subpage: 'Now Playing',
  section: 'Now Playing',
  // The Now Playing view's own lyrics button flips this and the choice
  // sticks, so no settings row: two places to flip one thing only invite
  // confusion. The timing row rides this dependsOn, so it shows only
  // while lyrics are on.
  hidden: true,
);

const sendspinLyricsOffset = SettingDef<num>(
  key: 'sendspin.lyrics_offset',
  type: SettingType.number,
  defaultValue: 0.3,
  title: 'Lyrics timing',
  description:
      'Shift the lyrics against the music. Positive shows each line '
      'earlier, negative later. Worth a nudge on tracks that read '
      'consistently off.',
  category: 'Sendspin',
  subpage: 'Now Playing',
  section: 'Now Playing',
  dependsOn: 'sendspin.lyrics',
  min: -3,
  max: 3,
  step: 0.1,
  unit: 's',
);

/// The queue panel in the lyrics' slot, persisted like the lyrics are:
/// the view's queue button flips it and keeps the two exclusive. No
/// settings row, for the same reason the lyrics have none.
const sendspinFullscreenQueue = SettingDef<bool>(
  key: 'sendspin.fullscreen_queue',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show queue',
  description:
      'The queue from the playing track on, in place of the lyrics on the '
      'Now Playing view.',
  category: 'Sendspin',
  subpage: 'Now Playing',
  section: 'Now Playing',
  hidden: true,
);

/// The floating player's position as "x,y" fractions of the free area.
/// Hidden: owned by the drag gesture, not a settings row.
const sendspinPlayerPos = SettingDef<String>(
  key: 'sendspin.player_pos',
  type: SettingType.string,
  defaultValue: '0.98,0.98',
  title: 'Floating player position',
  description: 'Internal position of the floating media player.',
  category: 'Sendspin',
  hidden: true,
);

/// Stable per-install player identity, so Music Assistant sees the same
/// player across restarts. Generated on first start; never shown.
const sendspinClientId = SettingDef<String>(
  key: 'sendspin.client_id',
  type: SettingType.string,
  defaultValue: '',
  title: 'Sendspin client id',
  description: 'Internal identity for the Sendspin player.',
  category: 'Sendspin',
  hidden: true,
);

// ── DLNA renderer ──────────────────────────────────────────────────────

const dlnaEnabled = SettingDef<bool>(
  key: 'dlna.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable DLNA renderer',
  description:
      'Show images and play media pushed from Home Assistant or any DLNA '
      'app. The device appears as a media player named after the device '
      'name.',
  category: 'DLNA',
);

// Discussion #153: TTS and music pushed to the renderer took over the
// screen with the player card. Images, video and streams still do; only
// media announced as audio stays off screen.
const dlnaAudioBackground = SettingDef<bool>(
  key: 'dlna.audio_background',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Keep audio in the background',
  description: 'Pushed audio plays without taking over the screen.',
  category: 'DLNA',
  dependsOn: 'dlna.enabled',
);

// Still 2325, deliberately. It collides with the secure context proxy, which
// binds the same number on loopback and wins the race on every http instance
// (issue #49) — but the renderer now steps to the next free port instead of
// failing, and moving the default would take every working install with it:
// Home Assistant stores the renderer's URL in its config entry and does not
// follow a device that reappears on another port, so the media_player would
// go unavailable until the user re-added it by hand.
//
// The proxy is the one that cannot move: its port is baked into the page's
// origin, so changing it signs the user out of Home Assistant and loses the
// dashboard's saved data.
/// Empty until the renderer starts, which writes in the port it took and
/// keeps it true from then on. A field that names the port the renderer is
/// actually on is worth more than one that names the port it asked for: it
/// is the number a manually added Home Assistant entry needs, and without it
/// the only place that number appears is the log.
const dlnaPort = SettingDef<String>(
  key: 'dlna.port',
  type: SettingType.string,
  defaultValue: '',
  title: 'Server port',
  description:
      'The port the renderer is on, filled in when it starts. Change it to '
      'move the renderer, or clear it to let it pick again.',
  category: 'DLNA',
  placeholder: 'Set when the renderer starts',
  dependsOn: 'dlna.enabled',
  validator: validatePort,
);

/// A port a server can actually bind: below 1024 needs root, which no app on
/// Android has. Empty is valid and means "pick one".
String? validatePort(Object? value) {
  final text = '${value ?? ''}'.trim();
  if (text.isEmpty) return null;
  final port = int.tryParse(text);
  if (port == null || port < 1024 || port > 65535) {
    return 'Enter a port between 1024 and 65535, or leave it empty';
  }
  return null;
}

// ── ESPHome ────────────────────────────────────────────────────────────
// The kiosk as a native ESPHome device (issue: sunset the MQTT broker
// requirement): one master switch runs the API server and the kiosk's
// entity surface; the Bluetooth proxy is a subsystem on the same
// connection, in its own section below. The btproxy.* key names predate
// the page and stay for settings-export compatibility.

const esphomeEnabled = SettingDef<bool>(
  key: 'esphome.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable ESPHome',
  description:
      'Serve this kiosk to Home Assistant as an ESPHome device: its '
      'sensors and controls as native entities. Discovered automatically.',
  category: 'ESPHome',
);

/// Decoupled from the master switch, and off by default, on purpose: a
/// household with MQTT enabled that turns on ESPHome just for the
/// Bluetooth proxy must not wake up to a duplicate entity set; entities
/// are an explicit step, taken when the user is ready to migrate.
const esphomeEntities = SettingDef<bool>(
  key: 'esphome.entities',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Expose kiosk entities',
  description:
      'Serve the sensors and controls of this device as ESPHome entities.',
  category: 'ESPHome',
  dependsOn: 'esphome.enabled',
);

/// Empty until the first start, which fills it in: a fresh install takes
/// a slug of the device name, so Home Assistant's action names read like
/// the kiosk (`esphome.kitchen_tablet_notification`), and an install that
/// has already announced itself keeps the generated
/// `kiosk-satellite-<id>` name it was discovered under. The value is
/// slugified to a DNS label before it goes on the wire (see
/// node_name.dart): it is also the mDNS instance and hostname.
const esphomeNodeName = SettingDef<String>(
  key: 'esphome.node_name',
  type: SettingType.string,
  defaultValue: '',
  title: 'Node name',
  description:
      'Names this kiosk on the network, and Home Assistant builds its '
      'action names from it. Renaming it renames those actions.',
  category: 'ESPHome',
  placeholder: 'Set on first start',
  dependsOn: 'esphome.enabled',
);

/// Off by default because flipping it changes the identity Home Assistant
/// keys the ESPHome device entry on: existing installs have a device built
/// on the generated address, and adopting the real one creates a new entry.
/// The first successful read is stored (see adoptedWifiMac), so the identity
/// holds even if the address later becomes unreadable.
const esphomeRealMac = SettingDef<bool>(
  key: 'esphome.real_mac',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Use real Wi-Fi MAC address',
  description:
      'Home Assistant links this kiosk with the same device your network '
      'integrations already track. Changing this creates a new ESPHome '
      'device in Home Assistant.',
  category: 'ESPHome',
  subpage: 'Advanced settings',
  dependsOn: 'esphome.enabled',
);

/// The address typed in by hand (issue #300), for the devices where Android
/// will not reveal it: only read once the hardware read has come back
/// empty, so a working hardware read always wins (see wifiMacIdentity).
/// Hidden from the generic render: both UIs draw it under the real-MAC
/// switch's status row, and only while that row reports the hardware read
/// failed, since anywhere else it would invite overriding a good address.
const esphomeMacOverride = SettingDef<String>(
  key: 'esphome.mac_override',
  type: SettingType.string,
  defaultValue: '',
  title: 'Spoof Wi-Fi MAC address',
  description:
      'Since the MAC address cannot be resolved, you can use this field '
      'to enter your own. Changing this creates a new ESPHome device in '
      'Home Assistant.',
  category: 'ESPHome',
  subpage: 'Advanced settings',
  placeholder: 'AA:BB:CC:DD:EE:FF',
  dependsOn: 'esphome.real_mac',
  hidden: true,
  validator: validateMacAddress,
  normalizer: normalizeMacAddressSetting,
);

/// Canonical uppercase colon form of a hardware address typed any of the
/// usual ways (colons, dashes, dots, or twelve bare hex digits), or null
/// for anything that is not a usable interface address: wrong shape, all
/// zeros, Android's 02:00:00:00:00:00 privacy stub, multicast bit set.
/// Locally-administered addresses pass on purpose, the same rule the
/// native resolver applies: a randomized per-network MAC is locally
/// administered and is precisely the address the router sees.
String? normalizeMacAddress(String raw) {
  final hex = raw.trim().toUpperCase().replaceAll(RegExp(r'[:\-.\s]'), '');
  if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(hex)) return null;
  final mac = [
    for (var i = 0; i < 12; i += 2) hex.substring(i, i + 2),
  ].join(':');
  if (mac == '00:00:00:00:00:00' || mac == '02:00:00:00:00:00') return null;
  if (int.parse(mac.substring(0, 2), radix: 16) & 0x01 != 0) return null;
  return mac;
}

/// Empty clears the address; anything else must normalize.
String? validateMacAddress(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  if (normalizeMacAddress(value) == null) {
    return 'Enter a valid MAC address.';
  }
  return null;
}

/// [SettingDef.normalizer] adapter for [normalizeMacAddress]; an empty
/// value stays empty.
Object normalizeMacAddressSetting(Object value) =>
    value is String ? (normalizeMacAddress(value) ?? value.trim()) : value;

// ── Notifications ──────────────────────────────────────────────────────
// What a notification pushed from Home Assistant looks and sounds like
// (issues #320, #390). The sound rows are the device's defaults: the
// `notification` action can name a sound and a volume per call, and falls
// back to these when it does not.

/// How see-through the notification cards are (issue #390: a card over a
/// screensaver clock should not blot it out). Zero is the opaque card
/// there always was; the default lets a little of the screen through. The
/// slider fades the card's surface only - the words and the icon stay
/// solid, because a notification that cannot be read defeats itself.
const notificationsTransparency = SettingDef<num>(
  key: 'notifications.transparency',
  type: SettingType.number,
  defaultValue: 0.2,
  title: 'Transparency',
  description:
      'Lets the screen behind show through the notification cards. '
      'Text and icons stay solid.',
  category: 'ESPHome',
  section: 'Appearance',
  subpage: 'Notifications',
  min: 0,
  max: 1,
  step: 0.05,
  unit: '%',
  dependsOn: 'esphome.enabled',
);

/// Frosts what shows through a transparent card, so the message stays
/// readable over a busy photo. A slider rather than a switch: how much
/// frost a photo needs is taste, and one fixed strength read as broken on
/// some screens. Zero is no blur at all. Does nothing while the card is
/// opaque, which is why it lives beside the transparency slider rather
/// than gating on it.
const notificationsBlur = SettingDef<num>(
  key: 'notifications.blur',
  type: SettingType.number,
  defaultValue: 0.3,
  title: 'Background blur',
  description:
      'Blurs what shows through a transparent notification card. Note: '
      'Blur cannot be applied over the Home Assistant dashboard surface.',
  category: 'ESPHome',
  section: 'Appearance',
  subpage: 'Notifications',
  min: 0,
  max: 1,
  step: 0.05,
  unit: '%',
  dependsOn: 'esphome.enabled',
);

/// The name of a file in the sounds folder (see NotificationSounds), or
/// empty for the bundled chime. A name rather than a path so a backup
/// restored onto another kiosk still means the same file; both UIs draw
/// it as a dropdown over the folder's contents. A name whose file has
/// since gone plays the bundled chime, so a stale value costs nothing.
const notificationsChimeFile = SettingDef<String>(
  key: 'notifications.chime_file',
  type: SettingType.string,
  defaultValue: '',
  title: 'Notification sound',
  description:
      'Sound files are read from Android/data/me.jxl.kiosk_satellite/'
      'files/sounds on the device, also reachable from the File Manager.',
  category: 'ESPHome',
  section: 'Sound',
  subpage: 'Notifications',
  dependsOn: 'esphome.enabled',
  validator: validateNotificationSound,
);

/// What a notification sound may be: audio containers every Android the
/// app runs on (7.0 and up) decodes natively, so a pick that plays on the
/// tablet it was chosen on plays on every other kiosk it is restored to.
/// Deliberately no video containers (an .mp4 with an audio track would
/// play, and invites picking a movie) and no Opus, whose Ogg support was
/// patchy on the older releases.
const notificationSoundExtensions = [
  'mp3',
  'ogg',
  'oga',
  'wav',
  'flac',
  'm4a',
  'aac',
];

/// The extension of [path] in lower case, without the dot, or empty.
String fileExtension(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
}

/// Empty clears the sound; anything else has to be a bare file name (no
/// folders: the sounds folder is the only place looked in) with one of
/// [notificationSoundExtensions]. Also what the device picker, the remote
/// upload, the action's `chime_file` and a settings import are held to,
/// so a file of the wrong kind cannot reach the chime by any door.
String? validateNotificationSound(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  final name = value.trim();
  if (name.contains('/') || name.contains('\\') || name.startsWith('.')) {
    return 'Enter a file name, not a path.';
  }
  if (notificationSoundExtensions.contains(fileExtension(name))) return null;
  return 'Pick an MP3, OGG, WAV, FLAC, M4A or AAC file.';
}

/// Independent of the mixer's faders on purpose: a notification is not
/// assistant speech and not media, and its loudness should not move when
/// either of those sliders does. Only the device's own master volume
/// still scales it, as it scales every sound the tablet makes.
const notificationsVolume = SettingDef<num>(
  key: 'notifications.volume',
  type: SettingType.number,
  defaultValue: 0.7,
  title: 'Notification volume',
  description:
      'How loud the notification sound plays, apart from the media and '
      'assistant volumes.',
  category: 'ESPHome',
  section: 'Sound',
  subpage: 'Notifications',
  min: 0,
  max: 1,
  step: 0.05,
  unit: '%',
  dependsOn: 'esphome.enabled',
);

// ── Location ───────────────────────────────────────────────────────────
// The device's GPS position as ESPHome sensors (issue #363: a tablet in an
// RV is the one receiver that is always on and always in the vehicle).
// Opt-in, since a GPS receiver costs battery and the position is the most
// private thing a kiosk can report. The entities exist only while the
// switch is on: flipping it re-registers the device, which is a deliberate
// setup-time choice, not something an automation drives.

/// Kept off in the setting itself where the device has no GPS receiver (at
/// boot and whenever something turns it on: the remote API, a settings
/// import), so every reader of the switch agrees, and both settings pages
/// render it disabled with the reason.
const locationEnabled = SettingDef<bool>(
  key: 'location.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Report location',
  description:
      'Read the GPS position and serve it to Home Assistant as latitude, '
      'longitude, accuracy, altitude and speed sensors. Turning this on or '
      'off re-registers the ESPHome device.',
  category: 'ESPHome',
  section: 'GPS Sensor',
  subpage: 'GPS Sensor',
  dependsOn: 'esphome.entities',
);

/// How often the receiver is asked for a fix. Sixty seconds tracks a
/// moving vehicle closely enough for zones and border crossings while
/// keeping the recorder quiet; a fix is only pushed when one arrives, so a
/// parked device with a steady position costs Home Assistant nothing.
const locationInterval = SettingDef<num>(
  key: 'location.interval',
  type: SettingType.number,
  defaultValue: 60,
  title: 'Update interval',
  description: 'Seconds between position readings.',
  category: 'ESPHome',
  section: 'GPS Sensor',
  subpage: 'GPS Sensor',
  min: 10,
  max: 600,
  step: 10,
  unit: 's',
  dependsOn: 'location.enabled',
);

const btproxyEnabled = SettingDef<bool>(
  key: 'btproxy.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable Bluetooth proxy',
  description: 'Relay nearby Bluetooth devices to Home Assistant.',
  category: 'ESPHome',
  section: 'Bluetooth Proxy',
  subpage: 'Bluetooth Proxy',
  dependsOn: 'esphome.enabled',
);

/// How much of the time the radio listens. BALANCED (about a fifth of the
/// time) is the default: on some stacks every advertisement costs real CPU
/// (Meta's Bluetooth stack logs a verbose line per packet, 500 lines a
/// second in a busy home, a third of a core in the Bluetooth process plus
/// the log daemon behind it) and a fifth of the window cut that to a
/// twentieth on a Portal with the same devices heard. LOW_LATENCY (a 100%
/// window, what the proxy did before this setting existed) hears slow
/// beacons the moment they air, LOW_POWER listens a tenth of the time.
/// Applied live;
/// the scan session restarts, the server does not.
const btproxyScanDuty = SettingDef<String>(
  key: 'btproxy.scan_duty',
  type: SettingType.select,
  defaultValue: 'balanced',
  title: 'Scan intensity',
  description:
      'How much of the time the radio listens. Lower cuts CPU; devices that '
      'advertise rarely take longer to appear.',
  category: 'ESPHome',
  section: 'Bluetooth Proxy',
  subpage: 'Bluetooth Proxy',
  options: ['low_latency', 'balanced', 'low_power'],
  optionLabels: {
    'low_latency': 'Continuous',
    'balanced': 'Balanced',
    'low_power': 'Low power',
  },
  dependsOn: 'btproxy.enabled',
);

const btproxyConnections = SettingDef<bool>(
  key: 'btproxy.connections',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Allow device connections',
  description:
      'Home Assistant can connect to Bluetooth devices through this proxy.',
  category: 'ESPHome',
  section: 'Bluetooth Proxy',
  subpage: 'Bluetooth Proxy',
  dependsOn: 'btproxy.enabled',
);

/// Generated on first enable, then stable for the install's lifetime: Home
/// Assistant stores it in the config entry, so regenerating would take the
/// proxy offline until the user re-entered it. Deliberately NOT `secret`:
/// the whole point of this value is that the user reads it back and pastes
/// it into Home Assistant's encryption key prompt.
const btproxyKey = SettingDef<String>(
  key: 'btproxy.key',
  type: SettingType.string,
  defaultValue: '',
  title: 'Encryption key',
  description:
      'Paste this key into Home Assistant when it asks for the encryption '
      'key. Generated automatically on first start.',
  category: 'ESPHome',
  placeholder: 'Generated on first start',
  dependsOn: 'esphome.enabled',
);

/// Off by default, and the description names the exact host: Home Assistant
/// households run local-first on purpose, and a wall tablet quietly calling
/// an internet API is precisely what they de-install apps over. The lookup
/// sends hardware address prefixes only (never full addresses), one request
/// per manufacturer prefix ever, cached forever after.
const btproxyMacLookup = SettingDef<bool>(
  key: 'btproxy.mac_lookup',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Look up device manufacturers online',
  description:
      'Names unknown nearby devices by their hardware address prefix using '
      'api.macvendors.com. Only the 3-byte manufacturer prefix is sent, '
      'once per manufacturer; nothing else leaves the device.',
  category: 'ESPHome',
  section: 'Nearby devices',
  subpage: 'Bluetooth Proxy',
  dependsOn: 'btproxy.enabled',
);

const btproxyNearbySort = SettingDef<String>(
  key: 'btproxy.nearby_sort',
  type: SettingType.select,
  defaultValue: 'last_seen',
  title: 'Sort by',
  description: 'The order of the nearby devices list below.',
  category: 'ESPHome',
  section: 'Nearby devices',
  subpage: 'Bluetooth Proxy',
  options: ['last_seen', 'name', 'mac', 'rssi'],
  optionLabels: {
    'last_seen': 'Last seen',
    'name': 'Name',
    'mac': 'MAC address',
    'rssi': 'Signal strength',
  },
  dependsOn: 'btproxy.enabled',
);

const btproxyPort = SettingDef<String>(
  key: 'btproxy.port',
  type: SettingType.string,
  defaultValue: '',
  title: 'API port',
  description:
      'The port Home Assistant connects to. Leave empty for the ESPHome '
      'standard, 6053.',
  category: 'ESPHome',
  placeholder: '6053',
  dependsOn: 'esphome.enabled',
  validator: validatePort,
);

/// Born from a kiosk across the house that kept winning an EcoFlow's
/// connection, completing auth, then losing the link to distance seconds
/// later, all while its held slot blocked the proxy that could actually
/// hold it. Refusing weak connects makes Home Assistant fail over to a
/// closer proxy immediately. Last in its group by request.
const btproxyMinConnectRssi = SettingDef<String>(
  key: 'btproxy.min_connect_rssi',
  type: SettingType.select,
  defaultValue: '',
  title: 'Minimum signal for connections',
  description:
      'Refuse device connections heard weaker than this, so a closer '
      'proxy takes them instead.',
  category: 'ESPHome',
  section: 'Bluetooth Proxy',
  subpage: 'Bluetooth Proxy',
  options: ['', '-70', '-80', '-85', '-90'],
  optionLabels: {
    '': 'No limit',
    '-70': '-70 dBm (same room)',
    '-80': '-80 dBm',
    '-85': '-85 dBm',
    '-90': '-90 dBm (edge of range)',
  },
  dependsOn: 'btproxy.connections',
);

// ── Kiosk Satellite Service ────────────────────────────────────────────

// The one input the keep-alive service takes from the user. The service
// itself is not optional (ServiceManager, KioskSatelliteService.kt): it is
// what keeps the Home Assistant, MQTT and ESPHome sessions alive with the
// screen off on every install. The wake lock is a setting because it costs
// battery on an unplugged tablet, the one place a kiosk pays for it.
const serviceCpuAwake = SettingDef<bool>(
  key: 'service.cpu_awake',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Keep the CPU awake while the screen is off',
  description:
      'Holds a wake lock through dark spells so connections and timers '
      'keep running on time. Costs battery on an unplugged tablet.',
  category: 'Device',
  section: 'Options',
  subpage: 'Kiosk Satellite Service',
);

// ── Remote management ──────────────────────────────────────────────────

const remoteEnabled = SettingDef<bool>(
  key: 'remote.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Remote management',
  description: 'Run the embedded admin web server.',
  category: 'Device',
  section: 'Remote Administration',
  subpage: 'Remote Administration',
);

const remotePort = SettingDef<num>(
  key: 'remote.port',
  type: SettingType.number,
  defaultValue: 2324,
  title: 'Server port',
  description: 'Port for the remote admin interface.',
  category: 'Device',
  section: 'Remote Administration',
  subpage: 'Remote Administration',
);

const remotePassword = SettingDef<String>(
  key: 'remote.password',
  type: SettingType.password,
  defaultValue: '',
  title: 'Admin password',
  description: 'Required to log in to the remote interface.',
  category: 'Device',
  section: 'Remote Administration',
  subpage: 'Remote Administration',
  secret: true,
);

// ── Device ─────────────────────────────────────────────────────────────

const deviceName = SettingDef<String>(
  key: 'device.name',
  type: SettingType.string,
  defaultValue: '',
  title: 'Device name',
  description:
      'Friendly name shown in remote management and used as the device '
      'name published over MQTT.',
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
  section: 'User Interface',
  options: ['dark', 'light', 'system'],
  optionLabels: {'dark': 'Dark', 'light': 'Light', 'system': 'System'},
);

// The Impeller escape hatch (issue #127): some old GPU drivers (Adreno 330
// era) crash in the raster thread the moment Impeller draws, and Flutter
// does not fall back to Skia on its own. Read natively BEFORE the engine
// exists (RendererGuard.kt), which is also why a restart is needed — and
// why the crash net over there can flip this on by itself after two boots
// that died before their first frame.
const disableImpeller = SettingDef<bool>(
  key: 'render.disable_impeller',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Legacy renderer',
  description:
      'Use the older Skia renderer, for old GPUs that crash at startup. '
      'Turns itself on after two such crashes; takes effect on the next '
      'app start.',
  category: 'Device',
);

// The second half of the same escape hatch (issue #302). Hybrid composition
// draws the dashboard into the Android view hierarchy and hands Flutter its
// own frames back through an ImageReader; on Android 9 and older that reader
// asks for RGBA_8888 with no say in what the GPU produces, and a driver that
// answers in BGRA (the Mali T628 in the 2014 Galaxy Note 10.1) takes the
// process down the instant the dashboard appears. On means the WebView is
// drawn into a texture instead, which costs a copy per frame, so this stays
// off everywhere the native path works. Read natively as well
// (WebViewCompositingGuard.kt), which turns it on by itself where the GPU
// fails the probe.
const legacyWebView = SettingDef<bool>(
  key: 'render.legacy_webview',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Legacy WebView renderer',
  description:
      'Draw the dashboard into a texture, for old GPUs that crash when it '
      'appears. Turns itself on where the device needs it; takes effect on '
      'the next app start.',
  category: 'Device',
);

// Applied by UiScaler above the Navigator, so every route and overlay
// scales; the WebViews opt back out (UiScaleExempt), since web pages have
// their own zoom settings and are the reason a high density device needs
// this at all: the dashboard is sized right while the chrome reads tiny.
const uiScale = SettingDef<num>(
  key: 'ui.scale',
  type: SettingType.number,
  defaultValue: 100,
  title: 'Scale UI',
  description:
      "Size of the app's own screens: menu, settings, dialogs. "
      'For high density displays. Web content keeps its size.',
  category: 'Device',
  section: 'User Interface',
  min: 50,
  max: 150,
  step: 5,
  unit: '%',
);

/// All settings, in display order.
const List<SettingDef<Object>> allSettings = [
  startUrl,
  secureProxy,
  autoReloadOnError,
  pullToRefresh,
  pullToRefreshClearCache,
  browserZoom,
  pinchToZoom,
  disableScrolling,
  disableCache,
  browserInjectJs,
  browserInjectJsExternal,
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
  kioskDisablePullRefresh,
  kioskDisableGestures,
  gestureMappings,
  clapStrictness,
  kioskAllowDrawer,
  kioskAllowDashboard,
  kioskAllowCamera,
  kioskAllowMusic,
  kioskAllowSendspinPlayer,
  kioskAllowScreensaver,
  kioskAllowHold,
  kioskAllowTheme,
  kioskAllowApps,
  lockdownEnabled,
  lockdownBlackout,
  lockdownAllowScreensaver,
  lockdownExitGesture,
  homeLauncherEnabled,
  homeKeepPinning,
  launcherEnabled,
  launcherApps,
  launcherAutoReturn,
  launcherAutoReturnSeconds,
  // The Screen & Audio page: screen first, then the volume mixer, then the
  // hand-built device pickers, then capture tuning. Both UIs render this
  // category in this order.
  keepScreenOn,
  setBrightnessOnLaunch,
  defaultBrightness,
  browserCutoutMode,
  // After the whole Screen group: the remote places a page's entry row
  // where its first definition sits, and the device puts the entry card
  // under the Screen card.
  adaptiveBrightness,
  adaptiveMinBrightness,
  adaptiveMaxBrightness,
  adaptiveDarkLux,
  adaptiveBrightLux,
  mediaVolume,
  assistantVolume,
  audioMicDevice,
  audioSpeakerDevice,
  micAudioSource,
  micAgc,
  micGainDb,
  // Hand-built row: renders after the gain in both UIs, and only when the
  // selected microphone reports more than one channel.
  micChannel,
  screensaverEnabled,
  screensaverTimeoutSeconds,
  // The separate brightness applies to every content mode, so it lives with
  // the general controls rather than a per-mode panel.
  screensaverBrightnessEnabled,
  screensaverBrightnessLevel,
  screensaverNotificationBrightness,
  screensaverScreenOffMinutes,
  // Pixel shift sits with the general controls: it applies to every mode.
  screensaverPixelShift,
  // The legacy small clock rows, hidden since the Widgets group took over;
  // registered so old backups still import (then migrate on startup).
  screensaverMiniClock,
  screensaverMiniClockPosition,
  screensaverMiniClockColor,
  screensaverMiniClock24h,
  screensaverMiniClockDate,
  screensaverMode,
  // One titled panel per mode, in the dropdown's order; only the panel of
  // the selected mode is visible (each setting depends on the mode).
  screensaverDimLevel,
  screenAmbientDisplay,
  screensaverSavedBrightness,
  screensaverBlackHideExtras,
  screensaverClockStyle,
  screensaverClockFont,
  screensaverClockFontWeight,
  screensaverClock24h,
  screensaverClockSeconds,
  screensaverClockDate,
  screensaverClockScale,
  screensaverClockBackground,
  screensaverClockColor,
  screensaverClockBgColor,
  screensaverFlipDigitColor,
  screensaverFlipBgColor,
  screensaverFlipBackdropColor,
  screensaverRollerDigitColor,
  screensaverRollerBgColor,
  screensaverClockNight,
  screensaverClockNightLux,
  screensaverClockNightColor,
  screensaverClockNightBgColor,
  screensaverClockNightCardColor,
  screensaverMediaId,
  screensaverMediaIsFolder,
  screensaverMediaInterval,
  screensaverMediaShuffle,
  screensaverMediaRecursive,
  screensaverMediaTransition,
  screensaverMediaFill,
  screensaverLocalFolder,
  screensaverLocalInterval,
  screensaverLocalShuffle,
  screensaverLocalRecursive,
  screensaverLocalTransition,
  screensaverLocalFill,
  screensaverGalleryItems,
  screensaverGalleryInterval,
  screensaverGalleryShuffle,
  screensaverGalleryTransition,
  screensaverGalleryFill,
  screensaverImmichUrl,
  screensaverImmichApiKey,
  screensaverImmichValidated,
  screensaverImmichAlbum,
  screensaverImmichPhotosOnly,
  screensaverImmichAlbumName,
  screensaverImmichCache,
  screensaverImmichCacheMax,
  screensaverImmichInterval,
  screensaverImmichShuffle,
  screensaverImmichTransition,
  screensaverImmichFill,
  screensaverImmichPairPortrait,
  screensaverImmichMetadata,
  screensaverImmichMetadataAlbum,
  screensaverImmichMetadataDate,
  screensaverImmichMetadataCamera,
  screensaverImmichMetadataLocation,
  screensaverImmichMetadataPosition,
  screensaverImmichVignetteStrength,
  screensaverImmichPeople,
  screensaverImmichExcludePeople,
  screensaverImmichTags,
  screensaverImmichFavoritesOnly,
  screensaverImmichTakenWithin,
  screensaverImmichTakenFrom,
  screensaverImmichTakenTo,
  screensaverWebsiteUrl,
  screensaverWebsiteZoom,
  screensaverWebsiteDoubleTap,
  screensaverCameraViews,
  screensaverCameraViewSeconds,
  screensaverCameraMute,
  screensaverCameraView,
  screensaverCameraViewName,
  // The Widgets group: corner overlays riding over the mode panels above,
  // so it sits between them and the other overlay group, At a Glance.
  screensaverWidgets,
  screensaverWidgetScale,
  screensaverVignetteStrength,
  // The behavior rows first, then the Appearance group under its own
  // heading at the end of the subpage.
  screensaverGlanceEnabled,
  screensaverGlanceEntities,
  screensaverGlanceNowPlaying,
  screensaverGlanceScale,
  screensaverGlanceHideNames,
  screensaverGlanceBwIcons,
  screensaverGlanceTextOnly,
  screensaverDismissOnMotion,
  screensaverPostponeOnMotion,
  motionCamera,
  screensaverDismissOnFace,
  screensaverPostponeOnFace,
  faceSensitivity,
  facePreview,
  facePreviewSeconds,
  facePreviewScale,
  facePreviewPosition,
  screensaverDismissOnProximity,
  screensaverPostponeOnProximity,
  // The Person Detection page (Meta Portal only) sits under Proximity.
  screensaverDismissOnPerson,
  screensaverPostponeOnPerson,
  cameraEnabled,
  cameraDevice,
  cameraSnapshotResolution,
  cameraSnapshots,
  cameraSnapshotInterval,
  motionSensor,
  motionSensorOffDelay,
  motionFps,
  motionSensitivity,
  motionStartDelay,
  screensaverScheduleEnabled,
  screensaverSchedule,
  wakeWordEnabled,
  wakeWordPreferFp32,
  wakeWordBackground,
  wakeWordResumeTimeoutSeconds,
  vsNativePipeline,
  haUrl,
  haToken,
  haAutoLogin,
  haSatelliteEntity,
  haKioskMode,
  haKioskHideHeader,
  haKioskHideSidebar,
  haDashboardCarousel,
  haCarouselOverCards,
  haHaptics,
  haHapticsStrength,
  haTapSound,
  haTapSoundVolume,
  haTheme,
  themeMatchApp,
  themeAuto,
  themeDarkAt,
  themeLightAt,
  themeAutoApp,
  haRotationEnabled,
  haRotationDashboards,
  haRotationUrls,
  haRotationSeconds,
  haRotationPauseSeconds,
  haRotationCrossfade,
  haReturnHomeEnabled,
  haReturnHomeSeconds,
  haHoldMode,
  haHoldReleaseMinutes,
  haHoldMenu,
  disableSuspend,
  freezeOnScreensaver,
  wsFilter,
  mqttEnabled,
  mqttHost,
  mqttPort,
  mqttTls,
  mqttUsername,
  mqttPassword,
  mqttDiscoveryPrefix,
  mqttDeviceId,
  cameraAllowH265,
  cameraPreferMse,
  cameraPreferHls,
  cameraSingleAudio,
  cameraPinchZoom,
  cameraAutoDismissSeconds,
  cameraConfig,
  // Music Assistant leads the page it names: the server is what the kiosk
  // browses, asks for lyrics and hands people through the menu, and the
  // Sendspin player below is one of the things it drives.
  sendspinPlayer,
  sendspinPlayerName,
  sendspinSonosHosts,
  sendspinEnabled,
  sendspinServer,
  sendspinCodec,
  sendspinSyncOffset,
  sendspinDuckPercent,
  sendspinMaUrl,
  sendspinMaToken,
  sendspinMaShortcut,
  sendspinMaAutoClose,
  sendspinMaHideClose,
  sendspinShowPlayer,
  sendspinPlayerSize,
  sendspinPausedHideMinutes,
  sendspinDismissKeepsPlaying,
  sendspinPlayerShortcut,
  sendspinFullscreen,
  sendspinFullscreenControls,
  sendspinFullscreenDoubleTap,
  sendspinFullscreenOnPlay,
  sendspinFullscreenMotion,
  sendspinFullscreenShortcut,
  sendspinLyrics,
  sendspinLyricsOffset,
  sendspinFullscreenQueue,
  sendspinPlayerPos,
  sendspinClientId,
  sendspinPlayerActive,
  sendspinLocalPlayerName,
  dlnaEnabled,
  dlnaAudioBackground,
  dlnaPort,
  esphomeEnabled,
  esphomeEntities,
  btproxyKey,
  btproxyPort,
  esphomeNodeName,
  // The Notifications page sits above the Bluetooth Proxy one.
  notificationsTransparency,
  notificationsBlur,
  notificationsChimeFile,
  notificationsVolume,
  btproxyEnabled,
  btproxyScanDuty,
  btproxyConnections,
  btproxyMinConnectRssi,
  btproxyMacLookup,
  btproxyNearbySort,
  // The GPS Sensor page sits under the Bluetooth Proxy one.
  locationEnabled,
  locationInterval,
  // The Advanced settings page closes the ESPHome page.
  esphomeRealMac,
  esphomeMacOverride,
  deviceName,
  disableImpeller,
  legacyWebView,
  // The User Interface group: consecutive, or the heading would repeat.
  uiTheme,
  uiScale,
  // The two pages, service first, close the Device page.
  serviceCpuAwake,
  remoteEnabled,
  remotePort,
  remotePassword,
];
