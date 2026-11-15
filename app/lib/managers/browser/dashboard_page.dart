import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/event_bus.dart';
import '../../core/events.dart';
import '../navigation/compass_layout.dart';
import '../screensaver/screensaver_manager.dart' show parseScreensaverSchedule;
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// The settings [dashboardPageNeeded] reads.
final dashboardPageKeys = {
  defs.navStyle.key,
  defs.navCompassLayout.key,
  defs.screensaverMode.key,
  defs.screensaverScheduleEnabled.key,
  defs.screensaverSchedule.key,
  defs.voiceRuntime.key,
};

/// Whether the kiosk has a use for the dashboard page. Classic always
/// shows it. Compass needs it only for a dashboard view in its layout, the
/// Home Assistant Dashboard screensaver (set, or on the schedule) and
/// Voice Satellite running in the dashboard. Without any of them the page
/// is never loaded.
bool dashboardPageNeeded(SettingsManager settings) {
  if (settings.get(defs.navStyle) != 'compass') return true;
  final layout = CompassLayout.decode(settings.get(defs.navCompassLayout));
  if (layout.dashboards.isNotEmpty) return true;
  if (settings.get(defs.voiceRuntime) == 'dashboard') return true;
  if (settings.get(defs.screensaverMode) == 'dashboard') return true;
  if (!settings.get(defs.screensaverScheduleEnabled)) return false;
  return parseScreensaverSchedule(
    settings.get(defs.screensaverSchedule),
  ).any((entry) => entry['mode'] == 'dashboard');
}

/// Keeps [needed] on [dashboardPageNeeded] as the settings change.
StreamSubscription<SettingChanged> followDashboardPage(
  SettingsManager settings,
  EventBus bus,
  ValueNotifier<bool> needed,
) {
  needed.value = dashboardPageNeeded(settings);
  return bus.on<SettingChanged>().listen((e) {
    if (dashboardPageKeys.contains(e.key)) {
      needed.value = dashboardPageNeeded(settings);
    }
  });
}
