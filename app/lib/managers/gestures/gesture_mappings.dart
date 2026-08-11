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
/// Action types (run in GesturesManager):
///  - navigate:         path (a dashboard view, via haNavigate)
///  - url:              url (opened in the external link overlay)
///  - camera_view:      mode (show|hide), viewId (empty = default view)
///  - sendspin_player:  show the floating player card (a fling hides it)
///  - screensaver:      start the screensaver (a tap already stops it)
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

  Map<String, Object?> toJson() =>
      {'id': id, 'trigger': trigger, 'action': action};
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
/// Claps are not touch: they never reach the native engine.
List<Map<String, Object?>> nativeGestureTriggers(
  List<GestureMapping> mappings,
) => [
  for (final m in mappings)
    if (m.triggerType != 'claps')
    {
      'id': m.id,
      'type': m.triggerType,
      if (m.trigger['corner'] != null) 'corner': '${m.trigger['corner']}',
      if (m.trigger['taps'] is num) 'taps': (m.trigger['taps'] as num).toInt(),
      if (m.trigger['fingers'] is num)
        'fingers': (m.trigger['fingers'] as num).toInt(),
      if (m.trigger['holdMs'] is num)
        'holdMs': (m.trigger['holdMs'] as num).toInt(),
      if (m.trigger['sequence'] is List)
        'sequence': [
          for (final c in m.trigger['sequence'] as List) '$c',
        ],
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
  switch ('${trigger['type']}') {
    case 'corner_taps':
      return '${trigger['taps']} taps in the $corner corner';
    case 'corner_hold':
      final s = ((trigger['holdMs'] as num? ?? 1500) / 1000);
      final label = s == s.roundToDouble() ? '${s.round()}' : s.toStringAsFixed(1);
      return 'Hold the $corner corner for ${label}s';
    case 'finger_taps':
      final taps = (trigger['taps'] as num? ?? 1).toInt();
      return taps == 2
          ? '${trigger['fingers']}-finger double tap'
          : '${trigger['fingers']}-finger tap';
    case 'finger_hold':
      final s = ((trigger['holdMs'] as num? ?? 1500) / 1000);
      final label = s == s.roundToDouble() ? '${s.round()}' : s.toStringAsFixed(1);
      return '${trigger['fingers']}-finger hold for ${label}s';
    case 'corner_sequence':
      final seq = trigger['sequence'];
      if (seq is List) {
        return 'Corner sequence: '
            '${seq.map((c) => '$c'.toUpperCase()).join(' > ')}';
      }
      return 'Corner sequence';
    case 'claps':
      return '${trigger['claps']} claps';
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
      return name.isEmpty ? 'Show the camera view' : 'Show camera view $name';
    case 'sendspin_player':
      return 'Show the Sendspin player';
    case 'screensaver':
      return 'Start the screensaver';
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
