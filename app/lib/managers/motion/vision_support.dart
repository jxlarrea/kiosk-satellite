import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the on-device vision runtimes can run on this device: LiteRT
/// behind the screensaver's face detection and MediaPipe Tasks behind the
/// Show fingers gesture. Both need Android 8 (`VisionRuntime.kt` has the
/// why: their native libraries import a libc call Android 7 lacks, and
/// issue #331 was that surfacing as a crash). The motion manager keeps
/// the face and hand legs off where a runtime cannot load, and both
/// settings surfaces render the rows disabled with [hint].
///
/// Unknown counts as supported: a missing answer (no bridge, as in tests)
/// must never switch a feature off on a device that has it.
class VisionSupport {
  const VisionSupport({required this.faces, required this.hands, this.hint});

  static const unknown = VisionSupport(faces: true, hands: true);

  /// Face detection can load.
  final bool faces;

  /// The hand landmarker can load.
  final bool hands;

  /// Why a flag is false, in a sentence fit for a settings row.
  final String? hint;

  Map<String, Object?> toJson() => {
    'faces': faces,
    'hands': hands,
    if (hint != null) 'hint': hint,
  };

  static const _channel = MethodChannel('kiosk_satellite/background');
  static Future<VisionSupport>? _probe;

  /// The native answer, asked once per process. A failed ask is not
  /// cached, so a bridge that was not ready gets asked again.
  static Future<VisionSupport> probe() => _probe ??= _ask();

  static Future<VisionSupport> _ask() async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'visionSupport',
      );
      if (raw == null) {
        _probe = null;
        return unknown;
      }
      return VisionSupport(
        faces: raw['faces'] != false,
        hands: raw['hands'] != false,
        hint: raw['hint'] as String?,
      );
    } catch (_) {
      _probe = null;
      return unknown;
    }
  }

  /// Forget the cached answer (tests swap the mock between cases).
  @visibleForTesting
  static void reset() => _probe = null;
}
