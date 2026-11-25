import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// What a recognized face made happen, for the action card.
enum FaceAction { pinSkipped, lockdownOff, voiceConfirmed }

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
/// Face Recognition was used.
///
/// An arrival card (Show arrivals) when someone is recognized at the kiosk,
/// again for them only after [defs.recognitionArrivalAway] out of view. A
/// small action card (Show face actions) each time a face skips the kiosk
/// PIN, turns Lockdown Mode off or confirms a voice. An action for the
/// person on an arrival card shows on that card instead of a second one.
///
/// The kiosk screen's RecognitionCardOverlay draws [card] in its corner,
/// and the camera preview draws it beside itself while it shows.
class RecognitionCards extends Manager {
  RecognitionCards(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SettingsManager _settings;
  final DateTime Function() _now;

  static const arrivalSpan = Duration(seconds: 4);
  static const actionSpan = Duration(seconds: 3);

  @override
  String get name => 'recognition';

  /// The card to show, or null.
  final card = ValueNotifier<RecognitionCard?>(null);

  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _hide;

  /// Everyone in view now, and when the others were last in view.
  Set<String> _present = const {};
  final _leftAt = <String, DateTime>{};

  /// People whose arrival card has shown since they last arrived.
  final _greeted = <String>{};

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
    final now = _now();
    _colors.addAll(e.colors);
    final color = e.color;
    if (e.id != null && color != null) _colors[e.id!] = color;
    final inView = {for (final p in e.people) p.id, ?e.id};
    for (final id in _present.difference(inView)) {
      _leftAt[id] = now;
    }
    for (final id in inView.difference(_present)) {
      final left = _leftAt[id];
      if (left != null && now.difference(left) >= defs.recognitionArrivalAway) {
        _greeted.remove(id);
      }
    }
    _present = inView;
    final id = e.id;
    if (id == null || _greeted.contains(id)) return;
    _greeted.add(id);
    if (!_on(defs.visionMatchShowArrivals)) return;
    log.info(name, 'arrival card for ${e.name}');
    _show(
      RecognitionCard(id: id, name: e.name, color: e.color, arrival: true),
      arrivalSpan,
    );
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
    for (final s in _subscriptions) {
      await s.cancel();
    }
    card.dispose();
  }
}
