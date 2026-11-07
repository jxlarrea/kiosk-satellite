import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../core/app_locales.dart';
import '../managers/gestures/gesture_mappings.dart';
import 'messages.dart';

String localizedHandHoldDuration(BuildContext context, num seconds) {
  if (seconds == 0) return l10n(context).gestureHoldInstant;
  final number = NumberFormat('0.#', appLocaleName(context));
  return l10n(context).gestureHoldSeconds(number.format(seconds));
}

String localizedGestureCorner(BuildContext context, String corner) {
  final name = cornerNames[corner];
  return name == null
      ? corner
      : gestureText(
          context,
          '${name[0].toUpperCase()}${name.substring(1)} corner',
        );
}

String localizedGestureTrigger(
  BuildContext context,
  Map<String, Object?> trigger,
) {
  final s = l10n(context);
  final corner = gestureText(
    context,
    cornerNames['${trigger['corner']}'] ?? '',
  );
  String seconds() {
    final value = (trigger['holdMs'] as num? ?? 1500) / 1000;
    return value == value.roundToDouble()
        ? '${value.round()}'
        : value.toStringAsFixed(1);
  }

  switch (trigger['type']) {
    case 'corner_taps':
      return s.gestureDescribeCornerTaps('${trigger['taps']}', corner);
    case 'corner_hold':
      return s.gestureDescribeCornerHold(corner, seconds());
    case 'finger_taps':
      return trigger['taps'] == 2
          ? s.gestureDescribeFingerDouble('${trigger['fingers']}')
          : s.gestureDescribeFingerTap('${trigger['fingers']}');
    case 'finger_hold':
      return s.gestureDescribeFingerHold('${trigger['fingers']}', seconds());
    case 'corner_sequence':
      final sequence = trigger['sequence'];
      return sequence is List
          ? s.gestureDescribeSequence(
              sequence
                  .map((c) => localizedGestureCorner(context, '$c'))
                  .join(' > '),
            )
          : gestureText(context, 'Corner sequence');
    case 'claps':
      return s.gestureDescribeClaps('${trigger['claps']}');
    case 'fingers':
      final count = (trigger['fingers'] as num? ?? 5).toInt();
      return count == 5
          ? gestureText(context, 'Show an open hand')
          : count == 1
          ? s.gestureDescribeOneFinger('$count')
          : s.gestureDescribeFingers('$count');
    case 'plugin':
      return describePluginTrigger(trigger);
    case 'button':
      final button = gestureText(
        context,
        buttonNames['${trigger['button']}'] ?? 'Action',
      );
      return switch (buttonPress(trigger)) {
        'double' => s.gestureDescribeButtonDouble(button),
        'long' => s.gestureDescribeButtonHold(button),
        _ => s.gestureDescribeButtonPress(button),
      };
  }
  return gestureText(context, 'Gesture');
}

String localizedGestureAction(
  BuildContext context,
  Map<String, Object?> action,
) {
  final s = l10n(context);
  switch (action['type']) {
    case 'plugin_action':
      return describeGestureAction(action);
    case 'navigate':
      return s.gestureGoTo('${action['path']}');
    case 'url':
      return s.gestureOpen('${action['url']}');
    case 'camera_view':
      if (action['mode'] == 'hide') {
        return gestureText(context, 'Close the camera view');
      }
      final name = '${action['viewName'] ?? ''}';
      return name.isEmpty
          ? gestureText(context, 'Toggle the camera view')
          : s.gestureCameraToggleName(name);
    case 'intercom_call':
      return s.gestureCall('${action['kioskName'] ?? action['kioskId']}');
    case 'launch_app':
      return s.gestureOpenApp('${action['package']}');
    case 'open_uri':
      return s.gestureOpen('${action['uri']}');
    case 'ha_service':
      return s.gestureCall('${action['domain']}.${action['service']}');
    case 'ha_script':
      return s.gestureRun('${action['entityId']}');
    case 'ha_automation':
      return s.gestureTriggerAction('${action['entityId']}');
    case 'ha_event':
      return s.gestureFireEvent('${action['event']}');
  }
  return gestureText(context, describeGestureAction(action));
}

String localizedGestureOutcome(
  BuildContext context,
  Map<String, Object?> action, {
  required bool ok,
}) {
  final s = l10n(context);
  switch (action['type']) {
    case 'plugin_action':
      final value = describeGestureAction(action);
      return ok ? s.gestureRan(value) : s.gestureRunFailed(value);
    case 'ha_service':
      final value = '${action['domain']}.${action['service']}';
      return ok ? s.gestureCalled(value) : s.gestureCallFailed(value);
    case 'ha_script':
      final value = '${action['entityId']}';
      return ok ? s.gestureRan(value) : s.gestureRunFailed(value);
    case 'ha_automation':
      final value = '${action['entityId']}';
      return ok ? s.gestureTriggered(value) : s.gestureTriggerFailed(value);
    case 'ha_event':
      final value = '${action['event']}';
      return ok ? s.gestureFired(value) : s.gestureFireFailed(value);
  }
  return gestureText(context, ok ? 'Done' : 'Failed');
}

/// Translate editor validation at render time so an open error follows the locale.
String gestureError(BuildContext context, String error) {
  final s = l10n(context);
  for (final (prefix, format) in <(String, String Function(String))>[
    ('Domain ', s.gestureDomainMissing),
    ('Service ', s.gestureServiceMissing),
    ('Entity ', s.gestureEntityMissing),
  ]) {
    if (error.startsWith(prefix) && error.endsWith(' not found.')) {
      return format(
        error.substring(prefix.length, error.length - ' not found.'.length),
      );
    }
  }
  final entity = RegExp(r'^Enter a (.+)\.\* entity\.$').firstMatch(error);
  if (entity != null) return s.gestureEntityRequired(entity[1]!);
  return gestureText(context, error);
}
