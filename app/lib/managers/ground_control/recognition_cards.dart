import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// What a recognized face made happen, for the action card.
enum FaceAction { pinSkipped, lockdownOff, voiceConfirmed, calendarFocused }

/// The card showing now: the person, and [action] when a face made
/// something happen (null on an arrival). [arrival] is the large card, and
/// an action that comes while it is up shows on it.
@immutable
class RecognitionCard {
  const RecognitionCard({
    required this.id,
    required this.name,
    this.color,
    this.action,
    this.arrival = false,
  });

  final String id;
  final String name;

  /// The person's color, as Ground Control keeps it (#RRGGBB).
  final String? color;
  final FaceAction? action;
  final bool arrival;
}

/// Vision Match > Recognition cards: the standard way the kiosk shows that
/// Face Recognition was used. Also says who arrives and leaves
/// ([FaceArrived], [FaceLeft]) on the same rule as the arrival card.
///
/// An arrival card (Show arrivals) when someone is recognized at the kiosk,
/// again for them only after [defs.recognitionArrivalAway] out of view. A
/// small action card (Show face actions) each time a face skips the kiosk
/// PIN, turns Lockdown Mode off, confirms a voice or puts the person's
/// calendar forward. An action for the
/// person on an arrival card shows on that card instead of a second one.
///
/// The kiosk screen's RecognitionCardOverlay draws [card] in its corner,
/// and the camera preview draws it beside itself while it shows.
class RecognitionCards extends Manager {
  RecognitionCards(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const arrivalSpan = Duration(seconds: 4);
  static const actionSpan = Duration(seconds: 3);

  @override
  String get name => 'recognition';

  /// The card to show, or null.
  final card = ValueNotifier<RecognitionCard?>(null);

  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _hide;

  /// Everyone in view now.
  Set<String> _present = const {};

  /// People who arrived and haven't left yet, with their names. Someone
  /// leaves after [defs.recognitionArrivalAway] out of view.
  final _arrived = <String, String>{};
  final _leaving = <String, Timer>{};
  final _names = <String, String>{};

  /// Names and colors seen, by id, for an action whose event only names
  /// the person.
  final _colors = <String, String>{};

  @override
  Future<void> init() async {
    _subscriptions
      ..add(bus.on<FaceInViewChanged>().listen(_onInView))
      ..add(
        bus.on<FacePinSkipped>().listen(
          (e) => _act(e.id, e.name, FaceAction.pinSkipped),
        ),
      )
      ..add(
        bus.on<FaceCalendarFocused>().listen(
          (e) => _act(e.id, e.name, FaceAction.calendarFocused),
        ),
      )
      ..add(
        bus.on<FaceLockdownChanged>().listen((e) {
          if (!e.locked) _act(e.id, e.name ?? '', FaceAction.lockdownOff);
        }),
      )
      ..add(
        bus.on<VoiceSpeakerChanged>().listen((e) {
          final color = e.color;
          if (e.id != null && color != null) _colors[e.id!] = color;
          if (e.by == 'face') {
            _act(e.id, e.name, FaceAction.voiceConfirmed);
          }
        }),
      );
  }

  bool _on(defs.SettingDef<bool> def) =>
      _settings.visible(def) && _settings.get(def);

  void _onInView(FaceInViewChanged e) {
    _colors.addAll(e.colors);
    final color = e.color;
    if (e.id != null && color != null) _colors[e.id!] = color;
    for (final p in e.people) {
      if (p.name.isNotEmpty) _names[p.id] = p.name;
    }
    if (e.id != null && e.name.isNotEmpty) _names[e.id!] = e.name;
    final inView = {for (final p in e.people) p.id, ?e.id};
    for (final id in _present.difference(inView)) {
      if (_arrived.containsKey(id)) {
        _leaving[id]?.cancel();
        _leaving[id] = Timer(defs.recognitionArrivalAway, () => _left(id));
      }
    }
    for (final id in inView) {
      _leaving.remove(id)?.cancel();
    }
    _present = inView;
    final id = e.id;
    if (id == null || _arrived.containsKey(id)) return;
    _arrived[id] = e.name;
    log.info(name, '${e.name} arrived');
    bus.publish(FaceArrived(id: id, name: e.name));
    if (!_on(defs.visionMatchShowArrivals)) return;
    log.info(name, 'arrival card for ${e.name}');
    _show(
      RecognitionCard(id: id, name: e.name, color: e.color, arrival: true),
      arrivalSpan,
    );
  }

  void _left(String id) {
    _leaving.remove(id);
    if (_present.contains(id)) return;
    final who = _arrived.remove(id);
    if (who == null) return;
    log.info(name, '$who left');
    bus.publish(FaceLeft(id: id, name: _names[id] ?? who));
  }

  void _act(String? id, String who, FaceAction action) {
    if (id == null || !_on(defs.visionMatchShowActions)) return;
    final up = card.value;
    final onArrival = up != null && up.arrival && up.id == id;
    log.info(name, '${action.name} card for $who');
    _show(
      RecognitionCard(
        id: id,
        name: who.isEmpty ? (up?.id == id ? up!.name : who) : who,
        color: _colors[id] ?? (up?.id == id ? up!.color : null),
        action: action,
        arrival: onArrival,
      ),
      actionSpan,
    );
  }

  void _show(RecognitionCard next, Duration span) {
    card.value = next;
    _hide?.cancel();
    _hide = Timer(span, () {
      _hide = null;
      card.value = null;
    });
  }

  @override
  Future<void> dispose() async {
    _hide?.cancel();
    for (final t in _leaving.values) {
      t.cancel();
    }
    for (final s in _subscriptions) {
      await s.cancel();
    }
    card.dispose();
  }
}
