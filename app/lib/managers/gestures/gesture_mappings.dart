/// The gestures.mappings model (issue #99): parsing, labels, and the
/// native trigger payload.
///
/// A mapping is one hidden gesture bound to one action:
///
/// ```json
/// {
///   "id": "g-1712345678",
///   "trigger": {"type": "corner_taps", "corner": "tl", "taps": 3},
///   "action": {"type": "navigate", "path": "lovelace/0"}
/// }
/// ```
///
/// Trigger types (detected in GestureEngine.kt, which never consumes a
/// touch; see that file for the timing rules):
///  - corner_taps:     corner (tl|tr|bl|br), taps (2..4)
///  - corner_hold:     corner, holdMs (500..3000)
///  - finger_taps:     fingers (2|3), taps (1|2)
///  - finger_hold:     fingers (2|3), holdMs
///  - corner_sequence: sequence (list of 2..8 corners)
///
/// One trigger is acoustic rather than touch (detected by ClapDetector on
/// the shared microphone stream, never sent to GestureEngine):
///  - claps:           claps (2..4)
///
/// One is visual (the motion camera's palm detector, PalmDetector.kt,
/// proposes hands; HandLandmarker.kt judges them and counts fingers):
///  - fingers:         fingers (1..5): a hand showing that many
///
/// Action types (run in GesturesManager):
///  - navigate:         path (a dashboard view, via haNavigate)
///  - url:              url (opened in the external link overlay)
///  - camera_view:      mode (show|hide), viewId (empty = default view);
///                      show toggles: the same gesture again closes the view
///  - sendspin_player:  show the floating player card (a fling hides it)
///  - app_launcher:     open the app launcher overlay (issue #318)
///  - screensaver:      start the screensaver
///  - screensaver_stop: stop it (redundant for touch, made for claps)
///  - hold_mode:        toggle hold mode (pin the current view, issue #266)
///  - ha_kiosk:         toggle HA kiosk mode (the header and sidebar, #422)
///  - launch_app:       package
///  - open_uri:         uri, an Android deep link (ACTION_VIEW)
///  - android_settings
///  - ha_service:       domain, service, entityId?, data? (JSON object)
///  - ha_script:        entityId (script.*, run via script.turn_on)
///  - ha_automation:    entityId (automation.*, run via automation.trigger)
///  - ha_event:         event, data? (JSON object)
library;

import 'dart:convert';

class GestureMapping {
  const GestureMapping({
    required this.id,
    required this.trigger,
    required this.action,
  });

  final String id;
  final Map<String, Object?> trigger;
  final Map<String, Object?> action;

  String get triggerType => '${trigger['type'] ?? ''}';
  String get actionType => '${action['type'] ?? ''}';

  Map<String, Object?> toJson() => {
    'id': id,
    'trigger': trigger,
    'action': action,
  };
}

/// Decode the gestures.mappings JSON, dropping anything malformed rather
/// than failing the lot: one bad import line should not disarm the rest.
List<GestureMapping> decodeGestureMappings(String json) {
  final out = <GestureMapping>[];
  try {
    final list = jsonDecode(json);
    if (list is! List) return out;
    for (final entry in list) {
      if (entry is! Map) continue;
      final id = entry['id'];
      final trigger = entry['trigger'];
      final action = entry['action'];
      if (id is! String || id.isEmpty) continue;
      if (trigger is! Map || action is! Map) continue;
      out.add(
        GestureMapping(
          id: id,
          trigger: trigger.map((k, v) => MapEntry('$k', v)),
          action: action.map((k, v) => MapEntry('$k', v)),
        ),
      );
    }
  } catch (_) {
    // Unparseable JSON reads as no mappings.
  }
  return out;
}

/// The flat trigger list KioskLock pushes to GestureEngine.configure.
/// Claps and hands are not touch: they never reach the native engine.
List<Map<String, Object?>> nativeGestureTriggers(
  List<GestureMapping> mappings,
) => [
  for (final m in mappings)
    if (m.triggerType != 'claps' && m.triggerType != 'fingers')
      {
        'id': m.id,
        'type': m.triggerType,
        if (m.trigger['corner'] != null) 'corner': '${m.trigger['corner']}',
        if (m.trigger['taps'] is num)
          'taps': (m.trigger['taps'] as num).toInt(),
        if (m.trigger['fingers'] is num)
          'fingers': (m.trigger['fingers'] as num).toInt(),
        if (m.trigger['holdMs'] is num)
          'holdMs': (m.trigger['holdMs'] as num).toInt(),
        if (m.trigger['sequence'] is List)
          'sequence': [for (final c in m.trigger['sequence'] as List) '$c'],
      },
];

const cornerNames = {
  'tl': 'top-left',
  'tr': 'top-right',
  'bl': 'bottom-left',
  'br': 'bottom-right',
};

/// "3 taps in the top-left corner": the row title in both UIs.
String describeGestureTrigger(Map<String, Object?> trigger) {
  final corner = cornerNames['${trigger['corner']}'] ?? '';
  String seconds(num fallback) {
    final s = ((trigger['holdMs'] as num? ?? fallback) / 1000);
    return s == s.roundToDouble() ? '${s.round()}' : s.toStringAsFixed(1);
  }

  switch ('${trigger['type']}') {
    case 'corner_taps':
      return '${trigger['taps']} taps in the $corner corner';
    case 'corner_hold':
      return 'Hold the $corner corner for ${seconds(1500)}s';
    case 'finger_taps':
      final taps = (trigger['taps'] as num? ?? 1).toInt();
      return taps == 2
          ? '${trigger['fingers']}-finger double tap'
          : '${trigger['fingers']}-finger tap';
    case 'finger_hold':
      return '${trigger['fingers']}-finger hold for ${seconds(1500)}s';
    case 'corner_sequence':
      final seq = trigger['sequence'];
      if (seq is List) {
        return 'Corner sequence: '
            '${seq.map((c) => '$c'.toUpperCase()).join(' > ')}';
      }
      return 'Corner sequence';
    case 'claps':
      return '${trigger['claps']} claps';
    case 'fingers':
      final n = (trigger['fingers'] as num? ?? 5).toInt();
      return n == 5
          ? 'Show an open hand'
          : 'Show $n finger${n == 1 ? '' : 's'}';
  }
  return 'Gesture';
}

/// The clap counts the configured mappings listen for: what ClapDetector is
/// armed with, and empty when no clap mapping exists (no microphone use).
Set<int> clapTargets(List<GestureMapping> mappings) => {
  for (final m in mappings)
    if (m.triggerType == 'claps' && m.trigger['claps'] is num)
      (m.trigger['claps'] as num).toInt(),
};

/// Whether any mapping wants a hand showing fingers: what puts the
/// camera's hand detectors to work (no camera use without one).
bool hasFingersTrigger(List<GestureMapping> mappings) =>
    mappings.any((m) => m.triggerType == 'fingers');

/// "Open camera view Front door": the row subtitle in both UIs.
String describeGestureAction(Map<String, Object?> action) {
  switch ('${action['type']}') {
    case 'navigate':
      return 'Go to ${action['path']}';
    case 'url':
      return 'Open ${action['url']}';
    case 'camera_view':
      if (action['mode'] == 'hide') return 'Close the camera view';
      final name = '${action['viewName'] ?? ''}';
      return name.isEmpty
          ? 'Toggle the camera view'
          : 'Toggle camera view $name';
    case 'sendspin_player':
      return 'Show the floating player';
    case 'app_launcher':
      return 'Open the app launcher';
    case 'screensaver':
      return 'Start the screensaver';
    case 'screensaver_stop':
      return 'Stop the screensaver';
    case 'hold_mode':
      return 'Toggle hold mode';
    case 'ha_kiosk':
      return 'Toggle HA kiosk mode';
    case 'launch_app':
      return 'Open app ${action['package']}';
    case 'open_uri':
      return 'Open ${action['uri']}';
    case 'android_settings':
      return 'Open Android Settings';
    case 'ha_service':
      return 'Call ${action['domain']}.${action['service']}';
    case 'ha_script':
      return 'Run ${action['entityId']}';
    case 'ha_automation':
      return 'Trigger ${action['entityId']}';
    case 'ha_event':
      return 'Fire event ${action['event']}';
  }
  return 'Action';
}

/// The toast title for a Home Assistant action: the kind of thing it is.
String gestureActionKindTitle(Map<String, Object?> action) =>
    switch ('${action['type']}') {
      'ha_service' => 'Home Assistant Service',
      'ha_script' => 'Home Assistant Script',
      'ha_automation' => 'Home Assistant Automation',
      'ha_event' => 'Home Assistant Event',
      _ => 'Home Assistant',
    };

/// The toast message for a Home Assistant action's outcome: what ran, in
/// the past tense, or what could not.
String describeGestureActionOutcome(
  Map<String, Object?> action, {
  required bool ok,
}) {
  switch ('${action['type']}') {
    case 'ha_service':
      final s = '${action['domain']}.${action['service']}';
      return ok ? 'Called $s' : 'Could not call $s';
    case 'ha_script':
      final e = '${action['entityId']}';
      return ok ? 'Ran $e' : 'Could not run $e';
    case 'ha_automation':
      final e = '${action['entityId']}';
      return ok ? 'Triggered $e' : 'Could not trigger $e';
    case 'ha_event':
      final e = '${action['event']}';
      return ok ? 'Fired event $e' : 'Could not fire event $e';
  }
  return ok ? 'Done' : 'Failed';
}
