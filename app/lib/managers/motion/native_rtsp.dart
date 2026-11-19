import 'package:flutter/services.dart';

/// RTSP control and demand only. Compressed video never crosses into Dart.
class NativeRtsp {
  static const _channel = MethodChannel('kiosk_satellite/camera/rtsp');

  /// [onSnapshot] answers the ONVIF snapshot URI while no viewer is
  /// streaming. A thrown error reaches the ONVIF client as a 503.
  static void onDemand(
    void Function(bool)? callback, {
    void Function(bool)? onAudioDemand,
    Future<Uint8List> Function()? onSnapshot,
  }) {
    _channel.setMethodCallHandler(
      callback == null
          ? null
          : (call) async {
              if (call.method == 'demand') callback(call.arguments == true);
              if (call.method == 'audioDemand') {
                onAudioDemand?.call(call.arguments == true);
              }
              if (call.method == 'snapshot') {
                if (onSnapshot == null) {
                  throw PlatformException(
                    code: 'camera',
                    message: 'Snapshots are unavailable.',
                  );
                }
                try {
                  return await onSnapshot();
                } catch (e) {
                  throw PlatformException(
                    code: 'camera',
                    message: e is StateError ? e.message : '$e',
                  );
                }
              }
              return null;
            },
    );
  }

  static Future<Map<String, dynamic>> configure(
    Map<String, Object> config,
  ) async => Map<String, dynamic>.from(
    await _channel.invokeMethod<Map>('configure', config) ?? {},
  );

  /// Whether ONVIF clients get motion events, and whether there is motion.
  static Future<void> onvifEvents({
    required bool enabled,
    required bool motion,
  }) => _channel.invokeMethod('onvifEvents', {
    'enabled': enabled,
    'motion': motion,
  });

  static Future<Map<String, dynamic>> status() async =>
      Map<String, dynamic>.from(
        await _channel.invokeMethod<Map>('status') ?? {},
      );
}
