import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/wake_word/pcm16.dart';

/// Plays wake word audio on the kiosk's speaker: the tester's last 10
/// seconds and the diagnostics clips.
///
/// The microphone is still open while it plays, and a clip of a wake word
/// is exactly what the detector is listening for. So real detection is held
/// off for the length of the playback and a moment after, the same way an
/// open tester holds it off. Without that, playing an activation back would
/// start a voice turn and save itself as a new activation.
class WakeAudioPlayer extends ChangeNotifier {
  WakeAudioPlayer(this.container);

  final AppContainer container;

  /// The speaker's tail still reaching the mic after the player says done.
  static const _holdTail = Duration(milliseconds: 1500);

  static int _next = 0;

  String? _playing;
  String? _soundId;
  File? _temp;
  bool _holding = false;
  Timer? _release;
  StreamSubscription<SoundEnded>? _ended;
  bool _disposed = false;

  /// The key passed to [play] for what is playing now, or null.
  String? get playing => _playing;

  /// Play [file], or [pcm] (16 kHz mono PCM16) written to a temporary WAV.
  /// [key] names it for [playing]. False when the player refused it.
  Future<bool> play(String key, {File? file, Uint8List? pcm}) async {
    await stop();
    _hold();
    final id = 'wake-audio-${++_next}';
    _soundId = id;
    _playing = key;
    notifyListeners();
    _ended ??= container.bus.on<SoundEnded>().listen((e) {
      if (e.id == _soundId) _finish();
    });
    var path = file?.path;
    if (path == null && pcm != null) {
      final temp = File(
        '${(await getTemporaryDirectory()).path}/ks_wake_audio_$_next.wav',
      );
      await temp.writeAsBytes(pcm16Wav(pcm), flush: true);
      _temp = temp;
      path = temp.path;
    }
    // Stopped or replaced while the file was being written.
    if (_soundId != id) return false;
    final ok = path != null && await container.sound.playFile(id, path);
    if (!ok && _soundId == id) _finish();
    return ok;
  }

  Future<void> stop() async {
    final id = _soundId;
    if (id == null) return;
    _finish();
    await container.sound.stopFile(id);
  }

  void _hold() {
    _release?.cancel();
    _release = null;
    if (_holding) return;
    _holding = true;
    container.wakeWord.startTest();
  }

  void _unhold() {
    _release?.cancel();
    _release = null;
    if (!_holding) return;
    _holding = false;
    container.wakeWord.stopTest();
  }

  void _finish() {
    if (_soundId == null) return;
    _soundId = null;
    _playing = null;
    final temp = _temp;
    _temp = null;
    if (temp != null) unawaited(temp.delete().then((_) {}, onError: (_) {}));
    _release?.cancel();
    _release = Timer(_holdTail, _unhold);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(stop());
    _unhold();
    _ended?.cancel();
    super.dispose();
  }
}
