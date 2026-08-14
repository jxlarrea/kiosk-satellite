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
    this.customName,
    this.attribute,
    this.state,
    this.attributeValue,
    this.icon,
    this.deviceClass,
    this.unit,
    this.precision,
  });

  final String entityId;

  /// The attribute to display instead of the state (issue #132), or null for
  /// the state itself. Part of the configuration, not the live data: it is
  /// chosen in the picker and stored with the entity.
  final String? attribute;

  /// The last known value of [attribute], already flattened to display text.
  /// Null while nothing has reported it (or [attribute] is null).
  final String? attributeValue;

  /// A name chosen by hand in the picker (issue #206), or null to follow
  /// Home Assistant. Part of the configuration, not the live data.
  final String? customName;

  /// Home Assistant's friendly name once it has reported one; until then the
  /// name saved when the entity was picked, so the row reads correctly from
  /// the first frame.
  final String name;

  /// What the row shows: the hand-chosen name when there is one, the
  /// Home Assistant name otherwise.
  String get displayName => customName ?? name;

  /// Null while the state is not known yet (nothing has reported it).
  final String? state;
  final String? icon;
  final String? deviceClass;
  final String? unit;

  /// The entity's Display precision from Home Assistant's entity registry,
  /// so a numeric state rounds the way the entity's own card would (issue
  /// #74). Null means none is set and the raw state shows as-is.
  final int? precision;

  GlanceEntity merge({
    String? name,
    String? state,
    String? attributeValue,
    String? icon,
    String? deviceClass,
    String? unit,
    int? precision,
  }) => GlanceEntity(
    entityId: entityId,
    name: name ?? this.name,
    customName: customName,
    attribute: attribute,
    state: state ?? this.state,
    attributeValue: attributeValue ?? this.attributeValue,
    icon: icon ?? this.icon,
    deviceClass: deviceClass ?? this.deviceClass,
    unit: unit ?? this.unit,
    precision: precision ?? this.precision,
  );

  Map<String, Object?> toJson() => {
    'entity_id': entityId,
    'name': name,
    if (customName != null) 'custom_name': customName,
    if (attribute != null) 'attribute': attribute,
  };

  static GlanceEntity fromJson(Map<Object?, Object?> json) {
    final attribute = '${json['attribute'] ?? ''}';
    final customName = '${json['custom_name'] ?? ''}';
    return GlanceEntity(
      entityId: '${json['entity_id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      customName: customName.isEmpty ? null : customName,
      attribute: attribute.isEmpty ? null : attribute,
    );
  }
}


/// An attribute value as display text. Attributes are free-form JSON: a
/// whole number sheds the ".0" a double parse gives it, everything else
/// shows as it is. Deliberately no unit or precision — those belong to the
/// state, not to attributes.
String glanceAttributeText(Object? value) {
  if (value == null) return '';
  if (value is num) {
    final n = value.toDouble();
    return n == n.roundToDouble() ? '${n.round()}' : '$value';
  }
  return '$value';
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
  StreamSubscription<NetworkStateChanged>? _networkSub;
  StreamSubscription<SendspinNowPlayingChanged>? _sendspinSub;
  GlanceSubscription? _live;
  Timer? _retry;
  bool _screensaverActive = false;
  bool _nowPlayingActive = false;

  @override
  Future<void> init() async {
    _load();
    _settingsSub = bus.on<SettingChanged>().listen((event) {
      if (event.key != defs.screensaverGlanceEntities.key &&
          event.key != defs.screensaverGlanceEnabled.key &&
          event.key != defs.screensaverGlanceNowPlaying.key) {
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
    // The network returned: a subscription the outage killed (or left
    // half-open) should not wait out the 20s retry timer, or hold a dead
    // socket that never errors. Reopen fresh; _open tears down any
    // remnant first.
    _networkSub = bus.on<NetworkStateChanged>().listen((event) {
      if (!event.up || !_screensaverActive) return;
      if (_live == null || _live!.isClosed) unawaited(_open());
    });
    // The full-screen Now Playing view can carry the row too (issue #209),
    // and it stands in for ANY screensaver mode while music plays. Playback
    // starting or stopping mid-screensaver changes whether the row is on
    // screen, so the subscription follows it — but only when the configured
    // mode would not hold one open anyway.
    _sendspinSub = bus.on<SendspinNowPlayingChanged>().listen((event) {
      if (_nowPlayingActive == event.active) return;
      _nowPlayingActive = event.active;
      if (!_screensaverActive || _modeWantsRow) return;
      unawaited(_open());
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
                'name': entity.displayName,
                'state': entity.state,
                if (entity.attribute != null) ...{
                  'attribute': entity.attribute,
                  'attribute_value': entity.attributeValue,
                },
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
    await _networkSub?.cancel();
    await _sendspinSub?.cancel();
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
          // Live state carries over only while the configuration agrees: an
          // edit that changed the displayed attribute or the name must not
          // keep showing the old choice until the next update.
          final kept = previous[entity.entityId];
          next.add(kept != null &&
                  kept.attribute == entity.attribute &&
                  kept.customName == entity.customName
              ? kept
              : entity);
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

  /// Whether the configured screensaver mode draws the row. Black with
  /// "Hide all extras" never does (issue #151), so holding entity state
  /// live for it would be pure cost.
  bool get _modeWantsRow {
    final mode = _settings.get(defs.screensaverMode);
    if (!_rowModes.contains(mode)) return false;
    return mode != 'black' ||
        !_settings.get(defs.screensaverBlackHideExtras);
  }

  /// Whether the full-screen Now Playing view is standing in for the
  /// screensaver AND is configured to carry the row (issue #209).
  bool get _nowPlayingWantsRow =>
      _nowPlayingActive &&
      _settings.get(defs.sendspinFullscreen) &&
      _settings.get(defs.screensaverGlanceNowPlaying);

  Future<void> _open() async {
    _close();
    if (!_modeWantsRow && !_nowPlayingWantsRow) return;
    final ids = [for (final entity in entities.value) entity.entityId];
    if (ids.isEmpty) return;
    final live = await _ha.subscribeEntities(
      ids,
      _applyState,
      onPrecision: _applyPrecisions,
    );
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
    // A socket that dies after establishing (HA restart, network drop)
    // previously froze the row until the next screensaver session; reopen
    // after a beat instead. The delay keeps a flapping server from turning
    // this into a tight connect loop; a failed reopen falls back to the
    // 20s timer above.
    live.onClosed = () {
      if (!_screensaverActive || _live != live) return;
      log.debug(name, 'subscription dropped; reopening');
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 5), () {
        if (_screensaverActive) unawaited(_open());
      });
    };
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

  /// Display precisions from the entity registry, fetched over the
  /// subscription's own socket when it opens. Entities absent from the map
  /// keep whatever they had; a fetched precision survives later state
  /// updates the same way a known icon does.
  void _applyPrecisions(Map<String, int> precisions) {
    if (precisions.isEmpty) return;
    entities.value = [
      for (final entity in entities.value)
        entity.merge(precision: precisions[entity.entityId]),
    ];
  }

  /// One entity's state from the subscription. Attributes arrive only when
  /// they change, so a name or icon already known is kept rather than lost.
  void _applyState(String entityId, Map<String, Object?> state) {
    final index =
        entities.value.indexWhere((entity) => entity.entityId == entityId);
    if (index < 0) return;
    final attributes = (state['attributes'] as Map?) ?? const {};
    final entity = entities.value[index];
    final updated = entity.merge(
      state: state['state'] as String?,
      name: attributes['friendly_name'] as String?,
      icon: attributes['icon'] as String?,
      deviceClass: attributes['device_class'] as String?,
      unit: attributes['unit_of_measurement'] as String?,
      // Only when this update actually carries the watched attribute: the
      // subscription diffs attributes, so an update about something else
      // must not erase the value already known.
      attributeValue: entity.attribute != null &&
              attributes.containsKey(entity.attribute)
          ? glanceAttributeText(attributes[entity.attribute])
          : null,
    );
    entities.value = [
      for (final (i, entity) in entities.value.indexed)
        if (i == index) updated else entity,
    ];
  }
}
