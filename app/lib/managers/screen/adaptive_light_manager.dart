import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../home_assistant/home_assistant_manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// The light level adaptive brightness follows (issue #911): the device's
/// own ambient light sensor, or a Home Assistant entity picked in its
/// place, for a tablet without a sensor or a room where a better placed
/// one exists. The screen manager and both settings UIs read this one
/// source through `getAdaptiveLight` and [AdaptiveLightChanged]; the
/// device sensor's own consumers (the illuminance entity, Night mode,
/// plugins) keep reading the sensor.
///
/// The entity is watched over a subscription of this app's own, open only
/// while adaptive brightness is on, so Home Assistant sends this one
/// entity and nothing else. Its last reading is kept across restarts the
/// way the device manager keeps the sensor's: a restart in a dark room
/// should not start at Maximum while the socket connects.
class AdaptiveLightManager extends Manager {
  AdaptiveLightManager(
    super.bus,
    super.commands,
    super.log,
    this._settings,
    this._ha,
  );

  final SettingsManager _settings;
  final HomeAssistantManager _ha;

  @override
  String get name => 'adaptive-light';

  /// Where the entity's last reading is kept, with the entity it came
  /// from: another entity's number means nothing for this one.
  static const _lastEntityLuxKey = 'adaptive_entity_last_lux';
  static const _entityLuxSaveGap = Duration(minutes: 10);
  DateTime? _entityLuxSavedAt;
  String? _entityLuxSavedFor;

  bool _sensorPresent = false;
  double? _sensorLux;
  bool _sensorLive = false;

  double? _entityLux;
  bool _entityLive = false;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  GlanceSubscription? _live;
  String? _liveEntity;
  Timer? _retry;
  bool _opening = false;

  /// Bumped on every close, so a subscription that finishes connecting
  /// after its owner moved on closes itself instead of taking over.
  int _generation = 0;

  /// Whether the last state the entity sent was not a number, so the
  /// warning is logged once per run of bad states, not on every update.
  bool _warnedState = false;

  /// The entity picked, or empty while the device sensor is the source.
  String get _entity => _settings.get(defs.adaptiveUseEntity)
      ? _settings.get(defs.adaptiveLightEntity).trim()
      : '';

  /// `entity` with the switch on, else `sensor`, or `none` on a device
  /// without one.
  String get source => _settings.get(defs.adaptiveUseEntity)
      ? 'entity'
      : (_sensorPresent ? 'sensor' : 'none');

  double? get lux => switch (source) {
    'entity' => _entityLux,
    'sensor' => _sensorLux,
    _ => null,
  };

  bool get live => switch (source) {
    'entity' => _entityLive,
    'sensor' => _sensorLive,
    _ => false,
  };

  @override
  Future<void> init() async {
    try {
      final res = await commands.execute('getLightLevel', const {});
      if (res.ok && res.data is Map) {
        final data = res.data as Map;
        _sensorPresent = data['present'] == true;
        _sensorLux = (data['lux'] as num?)?.toDouble();
        _sensorLive = data['live'] == true;
      }
    } catch (_) {}
    _loadEntityLux();

    _subscriptions.add(
      bus.on<LightLevelChanged>().listen((e) {
        _sensorLux = e.lux;
        _sensorLive = true;
        if (source == 'sensor') _publish();
      }),
    );
    _subscriptions.add(
      bus.on<SettingChanged>().listen((e) {
        if (e.key == defs.adaptiveLightEntity.key) {
          // A different entity: the old one's reading is not this one's.
          _entityLux = null;
          _entityLive = false;
          unawaited(_settings.setInternal(_lastEntityLuxKey, ''));
        }
        if (e.key == defs.adaptiveUseEntity.key ||
            e.key == defs.adaptiveLightEntity.key) {
          log.info(
            name,
            source == 'entity'
                ? 'following ${_entity.isEmpty ? 'no entity yet' : _entity}'
                : 'following the device sensor',
          );
          _publish();
        }
        // Another server or token: the open socket is the old one's.
        if (e.key == defs.haUrl.key || e.key == defs.haToken.key) _close();
        if (e.key == defs.adaptiveBrightness.key ||
            e.key == defs.adaptiveUseEntity.key ||
            e.key == defs.adaptiveLightEntity.key ||
            e.key == defs.haUrl.key ||
            e.key == defs.haToken.key) {
          unawaited(_sync());
        }
      }),
    );

    commands.register(
      Command(
        name: 'getAdaptiveLight',
        description:
            'The light level adaptive brightness follows: its source '
            '(sensor, entity or none), the entity, and the latest reading '
            'in lux',
        handler: (_) async => CommandResult.ok({
          'source': source,
          'entity': _settings.get(defs.adaptiveLightEntity),
          'lux': lux,
          'live': live,
        }),
      ),
    );

    // Not awaited: Home Assistant may take a while to answer, and the
    // screen manager after this one starts from the last reading.
    unawaited(_sync());
  }

  /// The device sensor as [init] would find it, for widget tests that
  /// never run it.
  @visibleForTesting
  void seedSensor({required bool present, double? lux, bool live = false}) {
    _sensorPresent = present;
    _sensorLux = lux;
    _sensorLive = live;
  }

  /// The entity's reading as the subscription would deliver it, for
  /// widget tests that never open one.
  @visibleForTesting
  void seedEntity({double? lux, bool live = false}) {
    _entityLux = lux;
    _entityLive = live;
  }

  void _loadEntityLux() {
    final saved = _settings.internal(_lastEntityLuxKey);
    final split = saved.lastIndexOf('|');
    if (split < 0) return;
    if (saved.substring(0, split) != _settings.get(defs.adaptiveLightEntity)) {
      return;
    }
    _entityLux = double.tryParse(saved.substring(split + 1));
  }

  void _publish() =>
      bus.publish(AdaptiveLightChanged(source: source, lux: lux, live: live));

  /// Open the entity's subscription when adaptive brightness wants it,
  /// close it when not.
  Future<void> _sync() async {
    final entity = _entity;
    final wanted = _settings.get(defs.adaptiveBrightness) && entity.isNotEmpty;
    if (!wanted) {
      _close();
      return;
    }
    if (_liveEntity == entity) {
      // Opening already, or open and alive.
      final current = _live;
      if (current == null ? _opening : !current.isClosed) return;
    }
    await _open(entity);
  }

  Future<void> _open(String entity) async {
    _close();
    final generation = _generation;
    _liveEntity = entity;
    _opening = true;
    final live = await _ha.subscribeEntities([entity], _onState);
    if (generation != _generation) {
      // Closed or reopened for another entity while this one connected.
      await live?.close();
      return;
    }
    _opening = false;
    if (live == null) {
      // Home Assistant not set up yet, unreachable or restarting: the last
      // reading holds and the subscription tries again shortly.
      _retryIn(const Duration(seconds: 20));
      return;
    }
    live.onClosed = () {
      if (_live != live) return;
      log.debug(name, 'subscription dropped; reopening');
      _live = null;
      _retryIn(const Duration(seconds: 5));
    };
    _live = live;
    log.debug(name, 'watching $entity');
  }

  void _retryIn(Duration delay) {
    _retry?.cancel();
    _retry = Timer(delay, () {
      _retry = null;
      _liveEntity = null;
      unawaited(_sync());
    });
  }

  void _close() {
    _generation++;
    _opening = false;
    _retry?.cancel();
    _retry = null;
    final live = _live;
    _live = null;
    _liveEntity = null;
    if (live != null) unawaited(live.close());
    if (_entityLive) {
      // A reading nobody keeps current is the last known one again.
      _entityLive = false;
      if (source == 'entity') _publish();
    }
  }

  void _onState(String entityId, Map<String, Object?> state) =>
      applyEntityState(entityId, state['state']);

  /// One state from the subscription. Anything that is not a number
  /// (unavailable, unknown) leaves the last reading in place.
  @visibleForTesting
  void applyEntityState(String entityId, Object? state) {
    if (entityId != _entity) return;
    if (state == null) return;
    final lux = double.tryParse('$state');
    if (lux == null || !lux.isFinite || lux < 0) {
      if (!_warnedState) {
        _warnedState = true;
        log.warn(name, '$entityId reads "$state", not a light level');
      }
      return;
    }
    _warnedState = false;
    if (_entityLux == lux && _entityLive) return;
    _entityLux = lux;
    _entityLive = true;
    // Only what the next session starts from: saved every ten minutes at
    // most, since each save rewrites the settings file on flash.
    final now = DateTime.now();
    final savedAt = _entityLuxSavedAt;
    if (savedAt == null ||
        _entityLuxSavedFor != entityId ||
        now.difference(savedAt) >= _entityLuxSaveGap) {
      _entityLuxSavedAt = now;
      _entityLuxSavedFor = entityId;
      unawaited(_settings.setInternal(_lastEntityLuxKey, '$entityId|$lux'));
    }
    _publish();
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _retry?.cancel();
    _retry = null;
    final live = _live;
    _live = null;
    await live?.close();
  }
}
