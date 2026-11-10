/// The `ks://<action>` scheme a dashboard uses to open one of the kiosk's own
/// features: `ks://apps` opens the app launcher, `ks://now-playing` the Now
/// Playing view, and so on. The sibling of `app://<package>` (app_link.dart).
///
/// A link resolves to the same action object a gesture mapping carries, so
/// GesturesManager.runGestureAction runs it with the gates every gesture
/// already has: a launcher that is off or empty refuses with a reason, an
/// intercom that is off likewise. The drawer's Allowed Action switches are
/// deliberately not consulted: the admin who writes the dashboard is the
/// admin who hides menu rows, and a link is how a hidden row stays reachable.
///
/// Exit, restart, opening another app and Android deep links are left out on
/// purpose: the first two the drawer confirms with a dialog, the third has
/// `app://` already, and the fourth is the reach the dashboard WebView refuses
/// for `intent://` too.
library;

/// How many arguments a `ks://plugin` link may pass after its action, and
/// how long each may be once decoded. The native side holds plugins to the
/// same limits.
const maxPluginLinkArgs = 8;
const maxPluginLinkArgLength = 256;

/// The action named by a `ks://` URL, or null when [url] is not one of ours
/// or names nothing the scheme offers.
///
/// The raw string is parsed rather than [Uri] so a view or kiosk id keeps its
/// case. Both `ks://apps` and the hostless `ks:apps` are accepted, with or
/// without a trailing slash, since both are natural things to type into a
/// dashboard's `url_path`. A query or fragment is refused: nothing here takes
/// one, and a link that carries one is more likely a typo than an intent.
Map<String, Object?>? kioskLinkAction(String url) {
  final trimmed = url.trim();
  if (!trimmed.toLowerCase().startsWith('ks:')) return null;
  var rest = trimmed.substring(3);
  if (rest.startsWith('//')) rest = rest.substring(2);
  if (rest.contains('?') || rest.contains('#')) return null;
  while (rest.endsWith('/')) {
    rest = rest.substring(0, rest.length - 1);
  }
  if (rest.isEmpty) return null;
  final parts = rest.split('/');
  final name = parts.first.toLowerCase();
  final args = parts.skip(1).map(_decode).toList();
  if (args.any((a) => a == null || a.isEmpty)) return null;
  final arg = args.isEmpty ? null : args.first;
  // ks://intercom/<kiosk id>/video is the only link with a second part
  // (issue #1350). It is its own action type, not a flag on intercom_call,
  // so a gesture mapping or a plugin's action setting can never carry it:
  // only the dashboard WebView runs it, and only for a tap.
  if (name == 'intercom' && args.length == 2) {
    return args[1]!.toLowerCase() == 'video'
        ? {'type': 'intercom_video_call', 'kioskId': arg}
        : null;
  }
  // ks://plugin/<plugin id>/<action id> runs a plugin's declared action,
  // like its kiosk menu entry (issue #1385). Action IDs are camelCase, so
  // both parts keep their case. Any parts after the action go to the
  // plugin as its arguments, such as the camera in
  // ks://plugin/doorbell/showCamera/front-door. Only a link carries them:
  // gestures, the menu entry and Home Assistant run an action without.
  if (name == 'plugin') {
    if (args.length < 2) return null;
    final extra = args.skip(2).cast<String>().toList();
    if (extra.length > maxPluginLinkArgs ||
        extra.any((a) => a.length > maxPluginLinkArgLength)) {
      return null;
    }
    return {
      'type': 'plugin_action',
      'pluginId': arg,
      'command': args[1],
      if (extra.isNotEmpty) 'args': extra,
    };
  }
  if (args.length > 1) return null;

  switch (name) {
    case 'apps':
    case 'launcher':
      return arg == null ? const {'type': 'app_launcher'} : null;
    case 'now-playing':
      return arg == null ? const {'type': 'now_playing'} : null;
    case 'player':
      return arg == null ? const {'type': 'sendspin_player'} : null;
    case 'music-assistant':
      return arg == null ? const {'type': 'music_assistant'} : null;
    case 'screensaver':
      return switch (arg) {
        null => const {'type': 'screensaver'},
        'stop' => const {'type': 'screensaver_stop'},
        _ => null,
      };
    case 'camera':
      return switch (arg) {
        null => const {'type': 'camera_view', 'mode': 'show', 'viewId': ''},
        'close' => const {'type': 'camera_view', 'mode': 'hide'},
        _ => {'type': 'camera_view', 'mode': 'show', 'viewId': arg},
      };
    case 'intercom':
      return arg == null
          ? const {'type': 'intercom_open'}
          : {'type': 'intercom_call', 'kioskId': arg};
    case 'hold':
      return arg == null ? const {'type': 'hold_mode'} : null;
    case 'ha-kiosk':
      return arg == null ? const {'type': 'ha_kiosk'} : null;
    case 'android-settings':
      return arg == null ? const {'type': 'android_settings'} : null;
    case 'alarms':
      return switch (arg) {
        null => const {'type': 'alarms'},
        'next' => const {'type': 'alarm_next'},
        _ => null,
      };
    case 'calendar':
      return switch (arg) {
        null => const {'type': 'calendar'},
        'day' ||
        'week' ||
        'month' ||
        'schedule' => {'type': 'calendar', 'view': arg},
        _ => null,
      };
    case 'music-library':
      return arg == null ? const {'type': 'music_library'} : null;
    case 'voice':
      // A dashboard's own push to talk and mute buttons (discussion
      // #1179), with no per-kiosk entity ids to write into the view.
      return switch (arg) {
        null => const {'type': 'voice_wake'},
        'stop' => const {'type': 'voice_stop'},
        'mute' => const {'type': 'voice_mute'},
        _ => null,
      };
  }
  return null;
}

String? _decode(String segment) {
  try {
    return Uri.decodeComponent(segment);
  } on ArgumentError {
    return null;
  }
}
