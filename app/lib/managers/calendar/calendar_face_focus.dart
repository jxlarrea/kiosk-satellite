import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/events.dart';
import '../ground_control/mine.dart';
import '../settings/definitions.dart' as defs;
import 'calendar_model.dart';
import 'calendar_requests.dart';

/// The calendars Settings > Calendar > Focus on who is at the kiosk puts
/// forward: those of the people Face Recognition names at the kiosk.
@immutable
class CalendarFocus {
  const CalendarFocus({
    this.entities = const [],
    this.lead,
    this.leadId,
    this.leadName = '',
  });

  /// Nobody known is in view, or the setting is off.
  static const none = CalendarFocus();

  /// The calendars of everyone recognized, the person at the kiosk's first.
  final List<String> entities;

  /// The person at the kiosk's calendar, null when they have none or have
  /// left.
  final String? lead;

  /// The person at the kiosk's Ground Control id, with [lead].
  final String? leadId;

  /// The person at the kiosk's name, for Up next.
  final String leadName;

  bool get isEmpty => entities.isEmpty;

  bool has(String entity) => entities.contains(entity);

  @override
  bool operator ==(Object other) =>
      other is CalendarFocus &&
      other.lead == lead &&
      other.leadId == leadId &&
      other.leadName == leadName &&
      listEquals(other.entities, entities);

  @override
  int get hashCode =>
      Object.hash(lead, leadId, leadName, Object.hashAll(entities));
}

/// Who Face Recognition names at the kiosk, kept on the arrival card's
/// rule: someone counts until they have been out of view for
/// [defs.recognitionArrivalAway], so a face turned away for a moment does
/// not move the calendar. The person at the kiosk stays the lead until
/// someone else becomes the person at the kiosk or they leave.
class CalendarFaceFocus {
  CalendarFaceFocus({
    required this.calendars,
    required this.thingsOf,
    required this.on,
    this.away = defs.recognitionArrivalAway,
  });

  /// The enabled calendars, in the order of Settings.
  final List<CalendarSource> Function() calendars;

  /// What Ground Control keeps for a person, by their id: their calendar
  /// and Home Assistant person among them.
  final Map<String, String> Function(String id) thingsOf;

  /// Focus on who is at the kiosk is on and Face Recognition runs.
  final bool Function() on;
  final Duration away;

  final value = ValueNotifier<CalendarFocus>(CalendarFocus.none);

  /// Everyone who counts, by Ground Control id, with their name, in the
  /// order they were first seen.
  final _here = <String, String>{};
  final _leaving = <String, Timer>{};
  String? _lead;

  void inView(FaceInViewChanged e) {
    final seen = <String, String>{
      for (final p in e.people) p.id: p.name,
      if (e.id != null) e.id!: e.name,
    };
    for (final entry in seen.entries) {
      _leaving.remove(entry.key)?.cancel();
      if (entry.value.isNotEmpty || !_here.containsKey(entry.key)) {
        _here[entry.key] = entry.value;
      }
    }
    if (e.id != null) _lead = e.id;
    for (final id in _here.keys) {
      if (seen.containsKey(id) || _leaving.containsKey(id)) continue;
      _leaving[id] = Timer(away, () => _left(id));
    }
    refresh();
  }

  void _left(String id) {
    _leaving.remove(id);
    _here.remove(id);
    if (_lead == id) _lead = null;
    refresh();
  }

  /// Works the calendars out again: someone came or went, the setting or
  /// the calendars changed.
  void refresh() {
    if (!on() || _here.isEmpty) {
      value.value = CalendarFocus.none;
      return;
    }
    final enabled = calendars();
    String? calendarOf(String id) => CalendarRequests.calendarFor(
      Speaking(id: id, name: _here[id] ?? '', things: thingsOf(id)),
      enabled,
    )?.entity;
    final lead = _lead == null ? null : calendarOf(_lead!);
    final entities = <String>[?lead];
    for (final id in _here.keys) {
      final entity = calendarOf(id);
      if (entity != null && !entities.contains(entity)) entities.add(entity);
    }
    value.value = CalendarFocus(
      entities: entities,
      lead: lead,
      leadId: lead == null ? null : _lead,
      leadName: lead == null ? '' : _here[_lead] ?? '',
    );
  }

  void dispose() {
    for (final t in _leaving.values) {
      t.cancel();
    }
    _leaving.clear();
    value.dispose();
  }
}
