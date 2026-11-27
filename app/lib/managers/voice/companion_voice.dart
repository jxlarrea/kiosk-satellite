import 'package:flutter/foundation.dart' show ValueListenable;

import 'assist_view.dart';

/// What companion screens need of Voice Satellite: on the active kiosk the
/// overlay it streams and the session a companion screen acts on, on the
/// companion screen the overlay it feeds. [VoiceManager] is the one.
abstract interface class CompanionVoice {
  bool get nativeRuntime;

  /// Voice Satellite on as a companion screen.
  bool get companionScreen;

  ValueListenable<AssistView> get view;
  ValueListenable<double> get level;
  ValueListenable<double> get dockCountdown;
  ({double elapsed, double duration})? get playback;

  void dismiss();
  void holdResults({bool silence = false});

  /// Draws the session of the kiosk this companion screen shows.
  void showCompanion(AssistView next);
  void companionTick({
    double? level,
    double? countdown,
    ({double elapsed, double duration})? playback,
  });

  /// How a dismissal or a result opened on the companion screen goes back.
  set companionDismiss(void Function()? value);
  set companionHold(void Function({bool silence})? value);
}
