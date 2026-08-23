import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../ui/mdi_icon.dart';

/// What a notification is about: picks its icon and the color behind it.
enum NotificationLevel { info, success, warning, error }

/// One notification, as the overlay draws it.
@immutable
class KioskNotification {
  const KioskNotification({
    required this.id,
    required this.message,
    this.title,
    this.level = NotificationLevel.info,
    this.scale = 1,
    this.icon,
  });

  /// Rising per notification; the auto-dismiss timer carries the id it was
  /// started for, so a late timer never takes down another notification.
  final int id;
  final String message;
  final String? title;
  final NotificationLevel level;

  /// How much bigger than the ordinary card to draw this one, 1 to
  /// [NotificationManager.maxScale]. Everything grows with it - type,
  /// icon, padding, width - so a 3 is legible from across a room without
  /// taking the screen away from the dashboard the way a full-screen
  /// takeover would.
  final double scale;

  /// A Material Design Icon name to draw instead of the one the level
  /// picks ("washing-machine"), already stripped of the `mdi:` prefix, or
  /// null for the level's own icon.
  final String? icon;
}

/// Notifications pushed at the kiosk from outside: the ESPHome
/// `notification` action, the REST and JS APIs, all through one command.
///
/// A kiosk on a wall is a place to say something to whoever walks past -
/// the washing machine finished, the front door opened - which is not the
/// same job as the app's own toasts (see ui/toast.dart, the reply to
/// something the user just did here). These are read from across a room:
/// bigger type, at the top of the screen, over whatever is showing,
/// screensaver included, with a chime so an unwatched screen still gets
/// attention.
///
/// They stack: a second notification joins the first rather than
/// replacing it, newest on top, because two things happening in a house
/// at once is ordinary and the second one is not permission to forget the
/// first. Each carries its own countdown. Past [maxVisible] the oldest
/// makes way, so a stuck automation cannot paper over the screen.
/// Repeats are not collapsed: the same words twice are two notifications,
/// because a caller saying something again means it happened again.
///
/// The manager owns the text and the countdowns,
/// ui/notification_overlay.dart draws them.
class NotificationManager extends Manager {
  NotificationManager(super.bus, super.commands, super.log);

  /// How long a notification stays when the caller names no duration.
  /// Long by kiosk-toast standards on purpose: nobody is watching the
  /// screen when it arrives.
  static const defaultDuration = Duration(seconds: 30);

  /// Ceiling for an asked-for duration. Past this a notification is
  /// effectively pinned, which is what duration 0 is for; the cap only
  /// keeps a wild number from arithmetic-overflowing the timer.
  static const _maxDuration = Duration(hours: 6);

  /// The largest a caller may ask a notification to be drawn. Four is
  /// already a card read from the far side of a room, and about as much
  /// as a tablet screen holds; past it the notification simply outgrows
  /// the display.
  static const maxScale = 4.0;

  /// How many stay on screen at once. Four fills the top of a tablet
  /// without burying the dashboard behind it.
  static const maxVisible = 4;

  /// What is on screen now, newest first. The overlay watches this.
  final current = ValueNotifier<List<KioskNotification>>(const []);

  /// One countdown per notification, by id.
  final _timers = <int, Timer>{};
  int _nextId = 0;

  @override
  String get name => 'notifications';

  @override
  Future<void> init() async {
    // One announcement per change, however the stack changed: a new card,
    // a countdown ending, a tap, the cap pushing the oldest out. The
    // screensaver lifts its dimming while anything is up.
    current.addListener(
      () => bus.publish(NotificationsChanged(count: current.value.length)),
    );
    commands
      ..register(
        Command(
          name: 'showNotification',
          description:
              'Show a notification over whatever is on screen (the '
              'screensaver included) and chime',
          params: const {
            'message': 'the text to show',
            'title': 'optional heading above the message',
            'duration':
                'seconds on screen; 0 stays until dismissed, omitted or '
                'negative uses the default 30',
            'type': 'info (default), success, warning or error',
            'chime': 'play the notification chime (default true)',
            'scale':
                'how large to draw it, 1 (default) to 4, decimals allowed; '
                '0 or negative uses the default',
            'icon':
                'a Material Design Icon to draw instead of the one the '
                'type picks, named as Home Assistant names it '
                '(mdi:washing-machine); empty for the type icon',
          },
          handler: (p) async {
            final message = '${p['message'] ?? ''}'.trim();
            final title = '${p['title'] ?? ''}'.trim();
            if (message.isEmpty && title.isEmpty) {
              return const CommandResult.fail('message required');
            }
            final id = ++_nextId;
            final note = KioskNotification(
              id: id,
              // A title-only call still reads as a notification: the
              // single line it carries becomes the message.
              message: message.isEmpty ? title : message,
              title: message.isEmpty || title.isEmpty ? null : title,
              level: _level(p['type']),
              scale: _scale(p['scale']),
              icon: _icon(p['icon']),
            );
            final stack = [note, ...current.value];
            // Oldest out when the stack is full: the newest arrival is
            // the one someone is most likely still in the room for.
            for (final dropped in stack.skip(maxVisible)) {
              _timers.remove(dropped.id)?.cancel();
            }
            current.value = stack.take(maxVisible).toList(growable: false);
            final duration = _duration(p['duration']);
            if (duration > Duration.zero) {
              _timers[id] = Timer(duration, () => dismiss(id: id));
            }
            if (_flag(p['chime'], orElse: true)) {
              // Not awaited: a missing or busy audio path must never hold
              // up the thing the user actually sees.
              unawaited(commands.execute('playChime', const {}));
            }
            log.info(
              name,
              'notification #$id ${note.scale == 1 ? '' : 'x${note.scale} '}'
              '${duration == Duration.zero
                  ? '(until dismissed)'
                  : '(${duration.inSeconds}s)'}'
              '${current.value.length > 1
                  ? ', ${current.value.length} on screen'
                  : ''}',
            );
            return CommandResult.ok({'id': id});
          },
        ),
      )
      ..register(
        Command(
          name: 'dismissNotification',
          description:
              'Take a notification off the screen, or all of them when no '
              'id is given',
          params: const {'id': 'the id showNotification returned'},
          handler: (p) async {
            final id = p['id'] is num
                ? (p['id']! as num).toInt()
                : int.tryParse('${p['id']}');
            dismiss(id: id);
            return const CommandResult.ok();
          },
        ),
      );
  }

  /// Takes one notification down, or the whole stack when [id] is null.
  /// An id that is no longer showing is a no-op: an expiring countdown
  /// must never take something else with it.
  void dismiss({int? id}) {
    if (id == null) {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
      current.value = const [];
      return;
    }
    _timers.remove(id)?.cancel();
    final left = [
      for (final shown in current.value)
        if (shown.id != id) shown,
    ];
    if (left.length != current.value.length) {
      current.value = List.unmodifiable(left);
    }
  }

  @override
  Future<void> dispose() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    current.dispose();
  }

  /// The icon name to draw, or null for the level's own. A name that is
  /// not an icon at all is dropped here rather than drawn as a blank
  /// circle.
  String? _icon(Object? value) {
    if (value == null) return null;
    final name = MdiIcons.normalize('$value');
    return MdiIcons.looksLikeIcon(name) ? name : null;
  }

  /// The size multiplier, clamped to something drawable. As with the
  /// duration, the ESPHome action cannot leave a number out, so anything
  /// at or below zero means "the ordinary size".
  double _scale(Object? value) {
    final asked = value is num ? value.toDouble() : double.tryParse('$value');
    if (asked == null || asked <= 0) return 1;
    return asked.clamp(1, maxScale).toDouble();
  }

  /// Seconds to a duration, with the two sentinels the ESPHome action
  /// needs: its arguments are all required, so "leave it at the default"
  /// has to be sayable in an int (negative), and so does "keep it up"
  /// (zero).
  Duration _duration(Object? value) {
    final seconds = value is num ? value.toInt() : int.tryParse('$value');
    if (seconds == null || seconds < 0) return defaultDuration;
    if (seconds == 0) return Duration.zero;
    final asked = Duration(seconds: seconds);
    return asked > _maxDuration ? _maxDuration : asked;
  }

  NotificationLevel _level(Object? value) => switch ('$value'.toLowerCase()) {
    'success' || 'ok' => NotificationLevel.success,
    'warning' || 'warn' => NotificationLevel.warning,
    'error' || 'alert' => NotificationLevel.error,
    _ => NotificationLevel.info,
  };

  /// Tolerant of the string booleans the REST and MQTT-style callers send.
  bool _flag(Object? value, {required bool orElse}) => switch (value) {
    bool v => v,
    num v => v != 0,
    'true' || 'True' || 'on' || '1' => true,
    'false' || 'False' || 'off' || '0' => false,
    _ => orElse,
  };
}
