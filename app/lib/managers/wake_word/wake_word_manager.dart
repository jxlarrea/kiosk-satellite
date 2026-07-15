import 'dart:async';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'engine.dart';

/// Native wake-word detection and the mic-ownership handoff with the
/// Voice Satellite card (docs/js-api.md, "Wake-word handoff protocol").
///
/// State:
///   enabled   — the `wake_word.enabled` setting
///   active    — page-controlled via setWakeWordActive(); suspended (false)
///               while the VS card owns the mic for STT
///   listening — mic actually open and inference running
///
/// Ordering contract: on detection the engine is stopped *before*
/// WakeWordDetected is published, so the page may open getUserMedia the
/// moment its event listener fires.
class WakeWordManager extends Manager {
  WakeWordManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'wake_word';

  // TODO(milestone-2): replace with the TFLite microWakeWord engine running
  // the same .tflite streaming models Voice Satellite ships.
  late final WakeWordEngine _engine = StubWakeWordEngine();

  bool _active = true;
  Timer? _resumeTimer;

  bool get enabled => _settings.get(defs.wakeWordEnabled);
  bool get listening => _engine.running;

  @override
  Future<void> init() async {
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.wakeWordEnabled.key ||
          e.key == defs.wakeWordModel.key) {
        _sync();
      }
    });

    commands
      ..register(Command(
        name: 'setWakeWordActive',
        description:
            'Resume (active=true) or suspend native wake-word listening. '
            'Pages must resume after their voice session returns to idle.',
        params: const {'active': 'true to resume, false to suspend'},
        handler: (p) async {
          setActive(p['active'] == true);
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'getWakeWordState',
        description: 'Current wake-word engine state',
        handler: (_) async => CommandResult.ok({
          'available': _engine.available,
          'active': _active,
          'listening': listening,
          'model': _settings.get(defs.wakeWordModel),
        }),
      ))
      ..register(Command(
        name: 'getWakeWordModels',
        description: 'Installed wake-word models',
        handler: (_) async => CommandResult.ok([
          for (final m in _engine.models)
            {'id': m.id, 'wakeWord': m.wakeWord, 'engine': m.engine},
        ]),
      ))
      ..register(Command(
        name: 'simulateWakeWord',
        description:
            'Fire a wake-word detection without the engine — for testing the '
            'Voice Satellite handoff end-to-end',
        handler: (_) async {
          await _onDetection(_settings.get(defs.wakeWordModel));
          return const CommandResult.ok();
        },
      ));

    await _sync();
  }

  /// Page-driven resume/suspend (setWakeWordActive).
  void setActive(bool active) {
    _active = active;
    log.info(name, active ? 'resumed by page' : 'suspended by page');
    if (active) _resumeTimer?.cancel();
    _sync();
  }

  Future<void> _sync() async {
    final shouldListen = enabled && _active;
    if (shouldListen && !_engine.running) {
      await _engine.start(
        model: _settings.get(defs.wakeWordModel),
        onDetection: _onDetection,
      );
      log.info(name, 'listening (${_settings.get(defs.wakeWordModel)})');
    } else if (!shouldListen && _engine.running) {
      await _engine.stop();
      log.info(name, 'stopped');
    }
    bus.publish(WakeWordStateChanged(active: _active, listening: listening));
  }

  Future<void> _onDetection(String model) async {
    // Stop capture FIRST — the page opens the mic as soon as the event fires.
    await _engine.stop();
    _active = false;
    log.info(name, 'detected "$model", mic released');
    bus.publish(WakeWordDetected(
      model: model,
      phrase: _engine.phraseFor(model),
    ));

    // Self-heal: if the page never resumes us (crash, navigation), re-arm.
    _resumeTimer?.cancel();
    final timeout =
        _settings.get(defs.wakeWordResumeTimeoutSeconds).toInt();
    if (timeout > 0) {
      _resumeTimer = Timer(Duration(seconds: timeout), () {
        if (!_active) {
          log.warn(name, 'page never resumed listening; self-healing');
          setActive(true);
        }
      });
    }
  }

  @override
  Future<void> dispose() async {
    _resumeTimer?.cancel();
    await _engine.stop();
  }
}
