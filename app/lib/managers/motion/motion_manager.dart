import '../../core/command_registry.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Camera-based motion detection.
///
/// Skeleton: the setting, JS API query, and event contract exist; the actual
/// camera frame-diff engine lands in a later milestone (see docs/js-api.md —
/// motion is reported via MotionDetected on the bus, which the screensaver
/// and JS API already consume).
class MotionManager extends Manager {
  MotionManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'motion';

  bool get enabled => _settings.get(defs.motionEnabled);

  @override
  Future<void> init() async {
    commands.register(Command(
      name: 'getMotionEnabled',
      description: 'Whether camera motion detection is enabled',
      handler: (_) async => CommandResult.ok(enabled),
    ));

    // TODO(milestone-2): camera frame-diff engine. Capture low-res frames
    // from the front camera, compare luminance deltas against a sensitivity
    // threshold, publish MotionDetected (rate-limited to 1/s).
    if (enabled) {
      log.warn(name, 'motion detection enabled but engine not yet implemented');
    }
  }
}
