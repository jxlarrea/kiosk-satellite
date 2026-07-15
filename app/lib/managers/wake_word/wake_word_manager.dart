import 'dart:async';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'engine.dart';
import 'vsww/vsww_engine.dart';

/// Native wake-word detection and the mic-ownership handoff with the
/// Voice Satellite card (docs/js-api.md, "Wake-word handoff protocol").
///
/// Configuration is inherited from Voice Satellite: the card pushes the
/// engine + model list via `setWakeWordConfig` (JS API); nothing is chosen
/// locally except the master enable switch. The app answers with
/// `available` so the card can fall back to browser detection when the
/// configured engine has no native runner here.
///
/// State:
///   enabled   — the `wake_word.enabled` local master switch
///   config    — pushed by the VS card; null until the page configures us
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

  // vsWakeWord runs natively (ONNX). microWakeWord/openWakeWord fall through
  // to unavailable (VS keeps browser detection) until ported.
  late final WakeWordEngine _engine = VswwEngine(log);

  WakeWordConfig? _config;
  bool _active = true;
  Timer? _resumeTimer;

  bool get enabled => _settings.get(defs.wakeWordEnabled);
  bool get listening => _engine.running;

  /// The wake-word config inherited from Voice Satellite (null until the VS
  /// card pushes it via setWakeWordConfig).
  WakeWordConfig? get config => _config;

  /// Whether we can natively run the engine Voice Satellite configured.
  bool get available =>
      _config != null && _engine.supportedEngines.contains(_config!.engine);

  @override
  Future<void> init() async {
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.wakeWordEnabled.key) _sync();
    });

    commands
      ..register(Command(
        name: 'setWakeWordConfig',
        description:
            'Inherit wake-word config from Voice Satellite: engine '
            '(microWakeWord | openWakeWord | vsWakeWord) and models with '
            'manifest URLs on the HA instance',
        params: const {
          'engine': 'microWakeWord | openWakeWord | vsWakeWord',
          'models': '[{id, wakeWord, manifestUrl}]',
        },
        handler: (p) async {
          final config = WakeWordConfig.fromJson(p);
          if (config == null) {
            return const CommandResult.fail('invalid wake word config');
          }
          _config = config;
          log.info(
              name,
              'configured by page: ${config.engine.name} '
              '[${config.models.map((m) => m.id).join(', ')}]'
              '${available ? '' : ' (no native runner — reporting unavailable)'}');
          await _sync();
          return CommandResult.ok({'available': available});
        },
      ))
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
          'available': available,
          'enabled': enabled,
          'active': _active,
          'listening': listening,
          'engine': _config?.engine.name,
          'models': [
            for (final m in _config?.models ?? const <WakeWordModelRef>[])
              m.toJson(),
          ],
        }),
      ))
      ..register(Command(
        name: 'simulateWakeWord',
        description:
            'Fire a wake-word detection without the engine — for testing the '
            'Voice Satellite handoff end-to-end',
        handler: (_) async {
          final model = _config?.models.firstOrNull ??
              const WakeWordModelRef(
                  id: 'test', wakeWord: 'Test', manifestUrl: '');
          await _onDetection(model);
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
    final shouldListen = enabled && _active && available;
    if (shouldListen && !_engine.running) {
      await _engine.start(config: _config!, onDetection: _onDetection);
      log.info(name, 'listening (${_config!.engine.name})');
    } else if (!shouldListen && _engine.running) {
      await _engine.stop();
      log.info(name, 'stopped');
    }
    bus.publish(WakeWordStateChanged(active: _active, listening: listening));
  }

  Future<void> _onDetection(WakeWordModelRef model) async {
    // Stop capture FIRST — the page opens the mic as soon as the event fires.
    await _engine.stop();
    _active = false;
    log.info(name, 'detected "${model.id}", mic released');
    bus.publish(WakeWordDetected(model: model.id, phrase: model.wakeWord));

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
