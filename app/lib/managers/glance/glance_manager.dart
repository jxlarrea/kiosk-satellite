import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../home_assistant/home_assistant_manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// One entity on the At a Glance row.
class GlanceEntity {
  const GlanceEntity({
    required this.entityId,
    required this.name,
    this.state,
    this.icon,
    this.deviceClass,
    this.unit,
  });

  final String entityId;

  /// The name to show. Home Assistant's friendly name once it has reported
  /// one; until then the name saved when the entity was picked, so the row
  /// reads correctly from the first frame.
  final String name;

  /// Null while the state is not known yet (nothing has reported it).
  final String? state;
  final String? icon;
  final String? deviceClass;
  final String? unit;

  GlanceEntity merge({
    String? name,
    String? state,
    String? icon,
    String? deviceClass,
    String? unit,
  }) => GlanceEntity(
    entityId: entityId,
    name: name ?? this.name,
    state: state ?? this.state,
    icon: icon ?? this.icon,
    deviceClass: deviceClass ?? this.deviceClass,
    unit: unit ?? this.unit,
  );

  Map<String, Object?> toJson() => {'entity_id': entityId, 'name': name};

  static GlanceEntity fromJson(Map<Object?, Object?> json) => GlanceEntity(
    entityId: '${json['entity_id'] ?? ''}',
    name: '${json['name'] ?? ''}',
  );
}


/// The screensaver's At a Glance row: which entities it shows and what they
/// currently read (issue #37).
///
/// State comes from a Home Assistant subscription of this app's own, opened
/// while the screensaver is up and closed when it goes away. Deliberately not
/// read off the dashboard page: the page's update filter (issue #8) exists to
/// stop weak tablets processing entities they do not display, and forcing
/// these back through it would give back the very work it saves — a pinned
/// power meter would have cost a full `hass.states` rebuild every second.
/// `subscribe_entities` takes an entity list, so this socket carries these
/// entities and nothing else.
class GlanceManager extends Manager {
  GlanceManager(super.bus, super.commands, super.log, this._settings, this._ha);

  final SettingsManager _settings;
  final HomeAssistantManager _ha;

  @override
  String get name => 'glance';

  /// The row as it should currently render. Empty when the feature is off or
  /// nothing is configured.
  final entities = ValueNotifier<List<GlanceEntity>>(const []);

  StreamSubscription<SettingChanged>? _settingsSub;
  StreamSubscription<ScreensaverStateChanged>? _screensaverSub;
  GlanceSubscription? _live;
  Timer? _retry;
  bool _screensaverActive = false;

  @override
  Future<void> init() async {
    _load();
    _settingsSub = bus.on<SettingChanged>().listen((event) {
      if (event.key != defs.screensaverGlanceEntities.key &&
          event.key != defs.screensaverGlanceEnabled.key) {
        return;
      }
      _load();
      // A changed list means a different subscription; rebuild it if the
      // screensaver is up, so an edit shows without waiting for the next one.
      if (_screensaverActive) unawaited(_open());
    });
    _screensaverSub = bus.on<ScreensaverStateChanged>().listen((event) {
      _screensaverActive = event.active;
      if (event.active) {
        unawaited(_open());
      } else {
        _close();
      }
    });

    commands.register(
      Command(
        name: 'glanceStatus',
        description: 'The At a Glance entities and their last known states.',
        handler: (_) async => CommandResult.ok({
          'enabled': _settings.get(defs.screensaverGlanceEnabled),
          'live': _live != null && !_live!.isClosed,
          'entities': [
            for (final entity in entities.value)
              {
                'entity_id': entity.entityId,
                'name': entity.name,
                'state': entity.state,
              },
          ],
        }),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _settingsSub?.cancel();
    await _screensaverSub?.cancel();
    _retry?.cancel();
    _close();
    entities.dispose();
  }

  /// The configured entities, keeping any live state already collected for
  /// ids that survived the edit.
  void _load() {
    if (!_settings.get(defs.screensaverGlanceEnabled)) {
      entities.value = const [];
      return;
    }
    final previous = {
      for (final entity in entities.value) entity.entityId: entity,
    };
    final next = <GlanceEntity>[];
    try {
      final decoded = jsonDecode(_settings.get(defs.screensaverGlanceEntities));
      if (decoded is List) {
        for (final item in decoded.take(defs.screensaverGlanceMax)) {
          if (item is! Map) continue;
          final entity = GlanceEntity.fromJson(item);
          if (entity.entityId.isEmpty) continue;
          next.add(previous[entity.entityId] ?? entity);
        }
      }
    } catch (error) {
      log.warn(name, 'invalid entity list: $error');
    }
    entities.value = next;
  }

  /// The row only renders on these, so nothing else has any reason to hold
  /// a subscription open.
  static const _rowModes = {'black', 'clock'};

  Future<void> _open() async {
    _close();
    if (!_rowModes.contains(_settings.get(defs.screensaverMode))) return;
    final ids = [for (final entity in entities.value) entity.entityId];
    if (ids.isEmpty) return;
    final live = await _ha.subscribeEntities(ids, _applyState);
    if (live == null) {
      // Home Assistant unreachable, mid-restart, whatever: the row keeps
      // showing what it last knew and tries again shortly, for as long as
      // the screensaver is still up.
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 20), () {
        if (_screensaverActive) unawaited(_open());
      });
      return;
    }
    // The screensaver may have gone away while the socket was opening.
    if (!_screensaverActive) {
      await live.close();
      return;
    }
    _live = live;
    log.debug(name, 'watching ${ids.length} entities');
  }

  void _close() {
    _retry?.cancel();
    _retry = null;
    final live = _live;
    _live = null;
    if (live != null) unawaited(live.close());
  }

  /// One entity's state from the subscription. Attributes arrive only when
  /// they change, so a name or icon already known is kept rather than lost.
  void _applyState(String entityId, Map<String, Object?> state) {
    final index =
        entities.value.indexWhere((entity) => entity.entityId == entityId);
    if (index < 0) return;
    final attributes = (state['attributes'] as Map?) ?? const {};
    final updated = entities.value[index].merge(
      state: state['state'] as String?,
      name: attributes['friendly_name'] as String?,
      icon: attributes['icon'] as String?,
      deviceClass: attributes['device_class'] as String?,
      unit: attributes['unit_of_measurement'] as String?,
    );
    entities.value = [
      for (final (i, entity) in entities.value.indexed)
        if (i == index) updated else entity,
    ];
  }
}
