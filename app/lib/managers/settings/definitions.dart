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
  dependsOn: 'kiosk.allow_drawer',
);

const kioskAllowApps = SettingDef<bool>(
  key: 'kiosk.allow_apps',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Apps',
  description: 'Open the app launcher.',
  category: 'Kiosk',
  section: 'Allowed Actions',
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

const launcherLayout = SettingDef<String>(
  key: 'launcher.layout',
  type: SettingType.select,
  defaultValue: 'grid',
  options: ['grid', 'list'],
  optionLabels: {'grid': 'Grid', 'list': 'List'},
  title: 'Layout',
  description: 'How the launcher arranges the apps.',
  category: 'Launcher',
  dependsOn: 'launcher.enabled',
);

const launcherShowIcons = SettingDef<bool>(
  key: 'launcher.show_icons',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Show icons',
  description: 'Show app icons in the launcher.',
  category: 'Launcher',
  dependsOn: 'launcher.enabled',
);

// The way back without a gesture or a hand: after an app opened through
// launchApp (the launcher, a gesture, MQTT), an idle clock brings the
// kiosk to the front again. Uses the same bringToFront as the wake word,
// so on Android 10+ it needs the draw-over-apps grant; enabling this
// fires the grant screen when it is missing (see AppLauncherManager).
const launcherAutoReturn = SettingDef<bool>(
  key: 'launcher.auto_return',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Return automatically',
  description: 'Come back to the kiosk after time spent in another app.',
  category: 'Launcher',
  dependsOn: 'launcher.enabled',
);

const launcherAutoReturnSeconds = SettingDef<num>(
  key: 'launcher.auto_return_seconds',
  type: SettingType.number,
  defaultValue: 300,
  min: 10,
  title: 'Return after (seconds)',
  description: 'Time in the other app before the kiosk comes back.',
  category: 'Launcher',
  dependsOn: 'launcher.auto_return',
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
  // Never 0: a kiosk that boots to a black panel looks dead.
  min: 0.05,
  max: 1,
  step: 0.05,
  unit: '%',
  dependsOn: 'screen.set_brightness_on_launch',
);

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

// The four corners an overlay can sit in, shared by the small clock and the
// Immich metadata panel — one vocabulary, and their dropdowns stay in step.
const _cornerOptions = ['top_left', 'top_right', 'bottom_left', 'bottom_right'];
const _cornerLabels = {
  'top_left': 'Top left',
  'top_right': 'Top right',
  'bottom_left': 'Bottom left',
  'bottom_right': 'Bottom right',
};

// ── Small clock (every mode except Clock, which is one already) ──

const screensaverMiniClock = SettingDef<bool>(
  key: 'screensaver.mini_clock',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Small clock',
  description:
      'Show a small clock in a corner of the screensaver. Not for the '
      'Clock and WebRTC Camera modes.',
  category: 'Screensaver',
);

const screensaverMiniClockPosition = SettingDef<String>(
  key: 'screensaver.mini_clock_position',
  type: SettingType.select,
  defaultValue: 'top_right',
  title: 'Clock position',
  description: 'Which corner the clock sits in.',
  category: 'Screensaver',
  options: _cornerOptions,
  optionLabels: _cornerLabels,
  dependsOn: 'screensaver.mini_clock',
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
);

// Its own switch, not the Clock mode's (issue #116): the mini clock used
// to read screensaver.clock_24h, whose settings row only shows while the
// mode is Clock — on every other mode the format was steered by a setting
// the person could not see.
const screensaverMiniClock24h = SettingDef<bool>(
  key: 'screensaver.mini_clock_24h',
  type: SettingType.boolean,
  defaultValue: false,
  title: '24-hour clock',
  description: 'Show a 24-hour time instead of AM/PM.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mini_clock',
);

const screensaverMiniClockDate = SettingDef<bool>(
  key: 'screensaver.mini_clock_date',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show date',
  description: 'Add a short date under the clock.',
  category: 'Screensaver',
  dependsOn: 'screensaver.mini_clock',
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
    'camera': 'WebRTC Camera',
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
  section: 'Black',
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
  section: 'Clock',
  options: ['digital', 'flip', 'roller'],
  optionLabels: {
    'digital': 'Digital Clock',
    'flip': 'Flip Clock',
    'roller': 'Roller Clock',
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
  section: 'Clock',
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
  // Stored as "r,g,b"; both UIs render a real color picker for it.
  defaultValue: '250,250,250',
  title: 'Clock color',
  description: 'The color of the clock text.',
  category: 'Screensaver',
  section: 'Clock',
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
  section: 'Clock',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'clock',
  placeholder: 'Path to an image on the device',
);

// One color pair per face rather than a shared one: visibility can only
// key off a single setting value, and the two faces want opposite defaults
// (dark digits on light cards for Flip, light digits on black for Roller).

const screensaverFlipDigitColor = SettingDef<String>(
  key: 'screensaver.flip_digit_color',
  type: SettingType.string,
  defaultValue: '33,33,33',
  title: 'Digit color',
  description: 'The color of the flip digits.',
  category: 'Screensaver',
  section: 'Clock',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'flip',
);

const screensaverFlipBgColor = SettingDef<String>(
  key: 'screensaver.flip_bg_color',
  type: SettingType.string,
  defaultValue: '245,245,245',
  title: 'Card color',
  description:
      'The color of the cards. The backdrop shades itself to '
      'match.',
  category: 'Screensaver',
  section: 'Clock',
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
  section: 'Clock',
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
  section: 'Clock',
  dependsOn: 'screensaver.clock_style',
  dependsOnValue: 'roller',
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

const screensaverGalleryFill = SettingDef<bool>(
  key: 'screensaver.gallery_fill',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Fill the screen',
  description:
      'Enlarge photos that match the screen shape to cover it fully. '
      'Others keep their full frame.',
  category: 'Screensaver',
  section: 'Photo Gallery',
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

const screensaverLocalFill = SettingDef<bool>(
  key: 'screensaver.local_fill',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Fill the screen',
  description:
      'Enlarge photos that match the screen shape to cover it fully. '
      'Others keep their full frame.',
  category: 'Screensaver',
  section: 'Local Media',
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
  section: 'Immich Media',
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
  section: 'Immich Media',
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
  section: 'Immich Media',
  hidden: true,
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'immich',
);

// The album id, or empty for the whole library. Rendered as a dropdown fed
// by the immichAlbums command in both UIs, never typed.
const screensaverImmichAlbum = SettingDef<String>(
  key: 'screensaver.immich_album',
  type: SettingType.string,
  defaultValue: '',
  title: 'Media source',
  description: 'The whole library, or a single album.',
  category: 'Screensaver',
  section: 'Immich Media',
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
  section: 'Immich Media',
  dependsOn: 'screensaver.immich_validated',
);

// The chosen album's name, for display when the server is unreachable.
const screensaverImmichAlbumName = SettingDef<String>(
  key: 'screensaver.immich_album_name',
  type: SettingType.string,
  defaultValue: '',
  title: 'Album name',
  description: '',
  category: 'Screensaver',
  section: 'Immich Media',
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
  section: 'Immich Media',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichShuffle = SettingDef<bool>(
  key: 'screensaver.immich_shuffle',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Shuffle',
  description: 'Cycle the media in random order.',
  category: 'Screensaver',
  section: 'Immich Media',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichTransition = SettingDef<String>(
  key: 'screensaver.immich_transition',
  type: SettingType.select,
  defaultValue: 'fade',
  title: 'Transition',
  description: 'How one item hands off to the next.',
  category: 'Screensaver',
  section: 'Immich Media',
  options: _transitionOptions,
  optionLabels: _transitionLabels,
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichFill = SettingDef<bool>(
  key: 'screensaver.immich_fill',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Fill the screen',
  description:
      'Enlarge photos that match the screen shape to cover it fully. '
      'Others keep their full frame.',
  category: 'Screensaver',
  section: 'Immich Media',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichCache = SettingDef<bool>(
  key: 'screensaver.immich_cache',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Cache media locally',
  description: 'Keep copies on the device so images load instantly.',
  category: 'Screensaver',
  section: 'Immich Media',
  dependsOn: 'screensaver.immich_validated',
);

const screensaverImmichCacheMax = SettingDef<num>(
  key: 'screensaver.immich_cache_max_items',
  type: SettingType.number,
  defaultValue: 500,
  title: 'Cache size (items)',
  description: 'The oldest items are deleted once the cache is full.',
  category: 'Screensaver',
  section: 'Immich Media',
  dependsOn: 'screensaver.immich_cache',
);

const screensaverImmichMetadata = SettingDef<bool>(
  key: 'screensaver.immich_metadata',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show metadata',
  description: 'Album, date, camera and location over the media.',
  category: 'Screensaver',
  section: 'Immich Media',
  dependsOn: 'screensaver.immich_validated',
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
  options: _cornerOptions,
  optionLabels: _cornerLabels,
  section: 'Immich Media',
  dependsOn: 'screensaver.immich_metadata',
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

// ── WebRTC Camera (mode: camera) ──
// The chosen view id, and its name alongside so both UIs can label the row
// without waiting on the camera configuration to load.
const screensaverCameraView = SettingDef<String>(
  key: 'screensaver.camera_view',
  type: SettingType.string,
  defaultValue: '',
  title: 'Camera view',
  description: 'Which camera view the screensaver shows.',
  category: 'Screensaver',
  section: 'WebRTC Camera',
  dependsOn: 'screensaver.mode',
  dependsOnValue: 'camera',
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
  section: 'Dim',
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
// ── At a Glance (modes: black, clock) ──
// A row of entity states under the clock, for the things people check in
// passing: is the garage still open, is the door locked (issue #37). Only the
// two plain modes carry it — the photo and camera modes have their own
// imagery, and a status row over a photo is neither subtle nor readable.
const screensaverGlanceEnabled = SettingDef<bool>(
  key: 'screensaver.glance_enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'At a glance',
  description:
      'Show a row of Home Assistant entity states on the Black and Clock '
      'screensavers.',
  category: 'Screensaver',
  section: 'At a Glance',
);

// The chosen entities as a JSON list of {entity_id, name}. Hand-built pickers
// on the device and in the remote admin write it; the generic settings
// renderer skips it (a raw JSON field is not something to type).
const screensaverGlanceEntities = SettingDef<String>(
  key: 'screensaver.glance_entities',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Entities',
  description:
      'Up to four entities to show. Their names come from Home '
      'Assistant.',
  category: 'Screensaver',
  section: 'At a Glance',
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
  options: ['front', 'back'],
  optionLabels: {'front': 'Front', 'back': 'Back'},
  hidden: true,
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
// and the brightness to hold while it is active. The entry list is custom
// UI in both settings surfaces (times, mode dropdowns and sliders per
// row), so only the JSON list is stored.

const screensaverScheduleEnabled = SettingDef<bool>(
  key: 'screensaver.schedule_enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Scheduled screensavers',
  description: 'Switch to a different screensaver at set times of day.',
  category: 'Screensaver',
  section: 'Schedule',
);

/// JSON list of `{"at": "HH:MM", "mode": "...", "brightness": 0..1}`
/// entries, kept sorted by time. Each entry applies from its
/// time until the next entry's; the latest entry of the day carries over
/// past midnight. The brightness overrides the global screensaver
/// brightness while the entry is active.
const screensaverSchedule = SettingDef<String>(
  key: 'screensaver.schedule',
  type: SettingType.string,
  defaultValue: '[]',
  title: 'Times',
  description: 'Each time switches the screensaver from then on.',
  category: 'Screensaver',
  section: 'Schedule',
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
  // Hidden while Android is doing the levelling: a fixed gain under an
  // adaptive one is two controls fighting over the same number.
  dependsOn: 'audio.mic_agc',
  dependsOnValue: false,
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

const vsSuppressScreensaver = SettingDef<bool>(
  key: 'vs.suppress_screensaver',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Turn off the Voice Satellite screensaver',
  description:
      'While this app\'s screensaver is enabled, the Voice Satellite '
      'screensaver stands down so the two never run at once.',
  category: 'Voice Satellite',
);

// ── Home Assistant ─────────────────────────────────────────────────────

const haUrl = SettingDef<String>(
  key: 'ha.url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Home Assistant Base URL',
  description:
      'e.g. https://homeassistant.local:8123, without a dashboard path.',
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
      'Hide the Home Assistant header and sidebar. Auto injects CSS and '
      'also uses the kiosk-mode plugin when detected. Applies '
      'immediately.',
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
  title: 'Sync Home Assistant Themes with Kiosk Satellite',
  description:
      'Automatically match your Home Assistant theme to your Kiosk '
      'Satellite interface.',
  category: 'Home Assistant',
  section: 'Theme',
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
  title: 'Return to Home Dashboard View',
  description:
      'Go back to the dashboard configured above after a period of '
      'inactivity.',
  category: 'Home Assistant',
  section: 'Return to Home Dashboard View',
);

const haReturnHomeSeconds = SettingDef<num>(
  key: 'ha.return_home_seconds',
  type: SettingType.number,
  defaultValue: 120,
  min: 10,
  title: 'Return after (seconds)',
  description: 'Inactivity period before the kiosk goes back.',
  category: 'Home Assistant',
  section: 'Return to Home Dashboard View',
  dependsOn: 'ha.return_home_enabled',
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

// ── Sendspin ───────────────────────────────────────────────────────────
// The device as a synchronized Sendspin audio player (the Music Assistant
// native protocol). The native client lives in Kotlin (sendspin/); these
// settings drive its lifecycle through SendspinManager.

const sendspinEnabled = SettingDef<bool>(
  key: 'sendspin.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Enable Sendspin player',
  description:
      'Turn this device into a synchronized Sendspin player. It appears '
      'in Music Assistant under the device name, in sync with every '
      'other Sendspin speaker.',
  category: 'Sendspin',
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
  options: ['flac', 'opus', 'pcm'],
  optionLabels: {
    'flac': 'FLAC (lossless)',
    'opus': 'Opus (efficient)',
    'pcm': 'PCM (uncompressed)',
  },
  dependsOn: 'sendspin.enabled',
);

const sendspinShowPlayer = SettingDef<bool>(
  key: 'sendspin.show_player',
  type: SettingType.boolean,
  defaultValue: true,
  title: 'Show the floating media player',
  description:
      'While music plays, show a small now-playing window over the '
      'dashboard with artwork, track info and progress. Drag it anywhere; '
      'the position is remembered.',
  category: 'Sendspin',
  dependsOn: 'sendspin.enabled',
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
      'How long a paused player card stays on screen before hiding '
      'itself. It returns the moment playback resumes.',
  category: 'Sendspin',
  min: 1,
  max: 10,
  step: 1,
  unit: 'min',
  dependsOn: 'sendspin.show_player',
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
  min: 0,
  max: 25,
  step: 5,
  unit: '%',
  dependsOn: 'sendspin.enabled',
);

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
  dependsOn: 'sendspin.enabled',
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
  dependsOn: 'sendspin.fullscreen',
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
  dependsOn: 'sendspin.enabled',
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

// ── Music Assistant (Sendspin section) ─────────────────────────────────
// The Sendspin player speaks Music Assistant's player protocol, which
// carries the track but nothing about it beyond title, artist and album.
// Anything richer — lyrics today — comes from Music Assistant's own API,
// which is a separate connection with its own address and token.

const sendspinMaUrl = SettingDef<String>(
  key: 'sendspin.ma_url',
  type: SettingType.string,
  defaultValue: '',
  title: 'Server address',
  description:
      "The Music Assistant server's address, as its web interface shows "
      'it. Usually https and port 8095.',
  category: 'Sendspin',
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
      'Read access is enough.',
  category: 'Sendspin',
  section: 'Music Assistant',
  // As with the Home Assistant token: masks the row on a wall-mounted
  // screen, and keeps the token out of a configuration export unless the
  // export was explicitly asked to carry secrets.
  secret: true,
);

const sendspinLyrics = SettingDef<bool>(
  key: 'sendspin.lyrics',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Show lyrics',
  description:
      'Show the current track\'s lyrics on the Now Playing screen, in time '
      'with the music. Music Assistant supplies them (local .lrc files '
      'included); tracks it cannot match are looked up on LRCLIB directly.',
  category: 'Sendspin',
  section: 'Music Assistant',
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
  section: 'Music Assistant',
  dependsOn: 'sendspin.lyrics',
  min: -3,
  max: 3,
  step: 0.1,
  unit: 's',
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

// ── Remote management ──────────────────────────────────────────────────

const remoteEnabled = SettingDef<bool>(
  key: 'remote.enabled',
  type: SettingType.boolean,
  defaultValue: false,
  title: 'Remote management',
  description: 'Run the embedded admin web server.',
  category: 'Device',
  section: 'Remote Administration',
);

const remotePort = SettingDef<num>(
  key: 'remote.port',
  type: SettingType.number,
  defaultValue: 2324,
  title: 'Server port',
  description: 'Port for the remote admin interface.',
  category: 'Device',
  section: 'Remote Administration',
);

const remotePassword = SettingDef<String>(
  key: 'remote.password',
  type: SettingType.password,
  defaultValue: '',
  title: 'Admin password',
  description: 'Required to log in to the remote interface.',
  category: 'Device',
  section: 'Remote Administration',
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
  kioskAllowDrawer,
  kioskAllowDashboard,
  kioskAllowCamera,
  kioskAllowScreensaver,
  kioskAllowTheme,
  kioskAllowApps,
  lockdownEnabled,
  lockdownBlackout,
  lockdownAllowScreensaver,
  lockdownExitGesture,
  launcherEnabled,
  launcherApps,
  launcherLayout,
  launcherShowIcons,
  launcherAutoReturn,
  launcherAutoReturnSeconds,
  // The Screen & Audio page: screen first, then the volume mixer, then the
  // hand-built device pickers, then capture tuning. Both UIs render this
  // category in this order.
  keepScreenOn,
  setBrightnessOnLaunch,
  defaultBrightness,
  browserCutoutMode,
  mediaVolume,
  assistantVolume,
  audioMicDevice,
  audioSpeakerDevice,
  micAudioSource,
  micAgc,
  micGainDb,
  screensaverEnabled,
  screensaverTimeoutSeconds,
  // The separate brightness applies to every content mode, so it lives with
  // the general controls rather than a per-mode panel.
  screensaverBrightnessEnabled,
  screensaverBrightnessLevel,
  // Pixel shift sits with the general controls: it applies to every mode.
  screensaverPixelShift,
  // The small clock too — it overlays every mode except Clock itself.
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
  screensaverClock24h,
  screensaverClockSeconds,
  screensaverClockDate,
  screensaverClockScale,
  screensaverClockBackground,
  screensaverClockColor,
  screensaverFlipDigitColor,
  screensaverFlipBgColor,
  screensaverRollerDigitColor,
  screensaverRollerBgColor,
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
  screensaverImmichInterval,
  screensaverImmichShuffle,
  screensaverImmichTransition,
  screensaverImmichFill,
  screensaverImmichCache,
  screensaverImmichCacheMax,
  screensaverImmichMetadata,
  screensaverImmichMetadataPosition,
  screensaverWebsiteUrl,
  screensaverCameraView,
  screensaverCameraViewName,
  screensaverGlanceEnabled,
  screensaverGlanceEntities,
  screensaverDismissOnMotion,
  screensaverPostponeOnMotion,
  motionCamera,
  cameraEnabled,
  cameraDevice,
  cameraSnapshotResolution,
  cameraSnapshots,
  cameraSnapshotInterval,
  motionSensor,
  motionSensorOffDelay,
  motionFps,
  motionSensitivity,
  screensaverScheduleEnabled,
  screensaverSchedule,
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
  themeMatchApp,
  themeAuto,
  themeDarkAt,
  themeLightAt,
  themeAutoApp,
  disableSuspend,
  freezeOnScreensaver,
  wsFilter,
  haRotationEnabled,
  haRotationDashboards,
  haRotationUrls,
  haRotationSeconds,
  haRotationPauseSeconds,
  haReturnHomeEnabled,
  haReturnHomeSeconds,
  mqttEnabled,
  mqttHost,
  mqttPort,
  mqttTls,
  mqttUsername,
  mqttPassword,
  mqttDiscoveryPrefix,
  mqttDeviceId,
  cameraConfig,
  sendspinEnabled,
  sendspinServer,
  sendspinCodec,
  sendspinSyncOffset,
  sendspinDuckPercent,
  sendspinShowPlayer,
  sendspinPlayerSize,
  sendspinPausedHideMinutes,
  sendspinDismissKeepsPlaying,
  sendspinFullscreen,
  sendspinFullscreenMotion,
  sendspinPlayerPos,
  sendspinClientId,
  sendspinMaUrl,
  sendspinMaToken,
  sendspinLyrics,
  sendspinLyricsOffset,
  dlnaEnabled,
  dlnaAudioBackground,
  dlnaPort,
  deviceName,
  uiTheme,
  disableImpeller,
  // The Remote Administration group closes the Device page.
  remoteEnabled,
  remotePort,
  remotePassword,
];
