import 'package:flutter/services.dart';

/// RTSP control and demand only. Compressed video never crosses into Dart.
class NativeRtsp {
  static const _channel = MethodChannel('kiosk_satellite/camera/rtsp');

  static void onDemand(
    void Function(bool)? callback, {
    void Function(bool)? onAudioDemand,
  }) {
    _channel.setMethodCallHandler(
      callback == null
          ? null
          : (call) async {
              if (call.method == 'demand') callback(call.arguments == true);
              if (call.method == 'audioDemand') {
                onAudioDemand?.call(call.arguments == true);
              }
            },
    );
  }

  static Future<Map<String, dynamic>> configure(
    Map<String, Object> config,
  ) async => Map<String, dynamic>.from(
    await _channel.invokeMethod<Map>('configure', config) ?? {},
  );

  static Future<Map<String, dynamic>> status() async =>
      Map<String, dynamic>.from(
        await _channel.invokeMethod<Map>('status') ?? {},
      );
}
