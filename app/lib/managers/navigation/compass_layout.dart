/// The Compass navigation layout: views laid out in a cross around a
/// center view, swiped between. Stored in nav.compass_layout as
///
/// ```json
/// {
///   "center": {"kind": "dashboard", "path": ""},
///   "up": [{"kind": "calendar"}],
///   "right": [{"kind": "music_library"}, {"kind": "now_playing"}],
///   "down": [{"kind": "camera", "id": "front"}],
///   "left": [{"kind": "menu"}]
/// }
/// ```
///
/// Each side holds up to [compassSideLimit] views. A layout holds as many
/// dashboard views as it has room for, each path once, and every other
/// kind of view once: one camera view, one Menu. An empty value is the
/// default layout: Home Assistant in the center and the Menu on its left.
library;

import 'dart:convert';

/// The most views one side holds.
const compassSideLimit = 2;

/// The kinds of view a layout can hold, in the order the add dialog lists
/// them.
const compassViewKinds = [
  'dashboard',
  'menu',
  'music_library',
  'calendar',
  'alarms',
  'now_playing',
  'camera',
  'app_launcher',
  'intercom',
];

/// One of the four sides, or the center.
enum CompassArm { center, up, right, down, left }

/// Where the finger sends the content: [right] shows the view to the right,
/// which a finger moving left brings in.
enum CompassMove { up, right, down, left }

/// One view of the layout. [path] is the navigation path of a dashboard
/// view ("dashboard/view", or "" for the dashboard the kiosk starts on),
/// [id] the camera view of a camera.
class CompassView {
  const CompassView(this.kind, {this.path = '', this.id = ''});

  static const menu = CompassView('menu');
  static const home = CompassView('dashboard');

  final String kind;
  final String path;
  final String id;

  bool get isMenu => kind == 'menu';
  bool get isDashboard => kind == 'dashboard';

  /// What makes two views the same view. A dashboard view is its path:
  /// they all show in the one WebView, so a layout holds several. Every
  /// other kind goes in once, so the kind alone tells them apart.
  String get key => isDashboard ? 'dashboard:$path' : kind;

  static CompassView? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = json['kind'];
    if (kind is! String || !compassViewKinds.contains(kind)) return null;
    final path = json['path'];
    final id = json['id'];
    if (kind == 'camera' && (id is! String || id.isEmpty)) return null;
    return CompassView(
      kind,
      path: kind == 'dashboard' && path is String ? path.trim() : '',
      id: kind == 'camera' && id is String ? id : '',
    );
  }

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (kind == 'dashboard') 'path': path,
    if (kind == 'camera') 'id': id,
  };

  @override
  bool operator ==(Object other) => other is CompassView && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

/// A place in the layout: the center, or the [index]th view out from it on
/// a side.
class CompassSlot {
  const CompassSlot(this.arm, [this.index = 0]);

  static const center = CompassSlot(CompassArm.center);

  final CompassArm arm;
  final int index;

  bool get isCenter => arm == CompassArm.center;

  /// The slot on the grid the position map draws: the center at (0, 0),
  /// x growing to the right and y growing down.
  ({int x, int y}) get grid => switch (arm) {
    CompassArm.center => (x: 0, y: 0),
    CompassArm.up => (x: 0, y: -(index + 1)),
    CompassArm.down => (x: 0, y: index + 1),
    CompassArm.right => (x: index + 1, y: 0),
    CompassArm.left => (x: -(index + 1), y: 0),
  };

  @override
  bool operator ==(Object other) =>
      other is CompassSlot && other.arm == arm && other.index == index;

  @override
  int get hashCode => Object.hash(arm, index);

  @override
  String toString() => isCenter ? 'center' : '${arm.name}[$index]';
}

const _sides = [
  CompassArm.up,
  CompassArm.right,
  CompassArm.down,
  CompassArm.left,
];

class CompassLayout {
  const CompassLayout({
    this.center = CompassView.home,
    this.up = const [],
    this.right = const [],
    this.down = const [],
    this.left = const [CompassView.menu],
  });

  final CompassView center;
  final List<CompassView> up;
  final List<CompassView> right;
  final List<CompassView> down;
  final List<CompassView> left;

  /// Anything unreadable is the default layout, which an empty value also
  /// is. A side past [compassSideLimit] keeps its first views. A kind
  /// placed twice, or the same dashboard view twice, keeps its first
  /// place, center first, then up, right, down and left.
  factory CompassLayout.decode(String raw) {
    if (raw.trim().isEmpty) return const CompassLayout();
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const CompassLayout();
      final seen = <String>{};
      final center = CompassView.fromJson(map['center']) ?? CompassView.home;
      seen.add(center.key);
      List<CompassView> side(Object? list) {
        final out = <CompassView>[];
        if (list is! List) return out;
        for (final item in list) {
          final view = CompassView.fromJson(item);
          if (view == null || !seen.add(view.key)) continue;
          if (out.length < compassSideLimit) out.add(view);
        }
        return out;
      }

      return CompassLayout(
        center: center,
        up: side(map['up']),
        right: side(map['right']),
        down: side(map['down']),
        left: side(map['left']),
      );
    } catch (_) {
      return const CompassLayout();
    }
  }

  String encode() => jsonEncode({
    'center': center.toJson(),
    'up': [for (final v in up) v.toJson()],
    'right': [for (final v in right) v.toJson()],
    'down': [for (final v in down) v.toJson()],
    'left': [for (final v in left) v.toJson()],
  });

  /// The views along [arm] out from the center, the center's one view for
  /// the center.
  List<CompassView> side(CompassArm arm) => switch (arm) {
    CompassArm.center => [center],
    CompassArm.up => up,
    CompassArm.right => right,
    CompassArm.down => down,
    CompassArm.left => left,
  };

  /// The view at [slot], or null for a slot past the end of its side.
  CompassView? viewAt(CompassSlot slot) {
    if (slot.isCenter) return center;
    final views = side(slot.arm);
    return slot.index >= 0 && slot.index < views.length
        ? views[slot.index]
        : null;
  }

  /// Where [view] sits, or null when the layout does not hold it.
  CompassSlot? slotOf(CompassView view) {
    if (view.key == center.key) return CompassSlot.center;
    for (final arm in _sides) {
      final at = side(arm).indexWhere((v) => v.key == view.key);
      if (at >= 0) return CompassSlot(arm, at);
    }
    return null;
  }

  /// Every slot that holds a view, the center first.
  List<CompassSlot> get slots => [
    CompassSlot.center,
    for (final arm in _sides)
      for (var i = 0; i < side(arm).length; i++) CompassSlot(arm, i),
  ];

  /// Whether [view] is placed somewhere: that dashboard view, or for any
  /// other kind a view of that kind, so the add dialog leaves it out.
  bool holds(CompassView view) =>
      center.key == view.key ||
      [...up, ...right, ...down, ...left].any((v) => v.key == view.key);

  /// Every dashboard view placed, the center first.
  List<CompassView> get dashboards => [
    for (final slot in slots)
      if (viewAt(slot) case final view? when view.isDashboard) view,
  ];

  /// The layout with a Menu somewhere, for a kiosk that would otherwise
  /// have no way back into Settings: at the end of the first side with
  /// room, left first. With every side full the left side's last view
  /// gives way to it.
  CompassLayout withMenu() {
    if (holds(CompassView.menu)) return this;
    for (final arm in const [
      CompassArm.left,
      CompassArm.right,
      CompassArm.up,
      CompassArm.down,
    ]) {
      final views = side(arm);
      if (views.length < compassSideLimit) {
        return withSide(arm, [...views, CompassView.menu]);
      }
    }
    return withSide(CompassArm.left, [left.first, CompassView.menu]);
  }

  /// The slot [move] leads to from [from], skipping views [available]
  /// says cannot show right now, or null when nothing lies that way. Out
  /// along a side the next view out, back toward the center the next view
  /// in, and from the center the first view of that side. A move across a
  /// side (up while on the right) leads nowhere.
  CompassSlot? step(
    CompassSlot from,
    CompassMove move, {
    bool Function(CompassView view)? available,
  }) {
    bool ok(CompassSlot slot) {
      final view = viewAt(slot);
      return view != null && (available?.call(view) ?? true);
    }

    final outArm = switch (move) {
      CompassMove.up => CompassArm.up,
      CompassMove.right => CompassArm.right,
      CompassMove.down => CompassArm.down,
      CompassMove.left => CompassArm.left,
    };
    final backArm = switch (move) {
      CompassMove.up => CompassArm.down,
      CompassMove.right => CompassArm.left,
      CompassMove.down => CompassArm.up,
      CompassMove.left => CompassArm.right,
    };
    if (from.isCenter || from.arm == outArm) {
      final start = from.isCenter ? 0 : from.index + 1;
      final views = side(outArm);
      for (var i = start; i < views.length; i++) {
        final slot = CompassSlot(outArm, i);
        if (ok(slot)) return slot;
      }
      return null;
    }
    if (from.arm == backArm) {
      for (var i = from.index - 1; i >= 0; i--) {
        final slot = CompassSlot(backArm, i);
        if (ok(slot)) return slot;
      }
      // The center always shows: it is the view the kiosk rests on.
      return CompassSlot.center;
    }
    return null;
  }

  CompassLayout copyWith({
    CompassView? center,
    List<CompassView>? up,
    List<CompassView>? right,
    List<CompassView>? down,
    List<CompassView>? left,
  }) => CompassLayout(
    center: center ?? this.center,
    up: up ?? this.up,
    right: right ?? this.right,
    down: down ?? this.down,
    left: left ?? this.left,
  );

  /// The layout with [arm]'s views replaced by [views].
  CompassLayout withSide(CompassArm arm, List<CompassView> views) =>
      switch (arm) {
        CompassArm.center => copyWith(center: views.first),
        CompassArm.up => copyWith(up: views),
        CompassArm.right => copyWith(right: views),
        CompassArm.down => copyWith(down: views),
        CompassArm.left => copyWith(left: views),
      };
}

/// The value check for nav.compass_layout: any readable layout passes,
/// and so does an empty one. Writes are normalized by
/// [normalizeCompassLayout], which drops what the layout cannot hold.
String? validateCompassLayout(Object? value) {
  if (value is! String) return 'must be a string';
  if (value.trim().isEmpty) return null;
  try {
    final map = jsonDecode(value);
    if (map is! Map) return 'must be a JSON object';
  } catch (_) {
    return 'must be JSON';
  }
  return null;
}

/// Stores the layout the way [CompassLayout.decode] reads it: sides over
/// the limit trimmed, repeats and unknown kinds dropped.
Object normalizeCompassLayout(Object value) {
  if (value is! String || value.trim().isEmpty) return value;
  return CompassLayout.decode(value).encode();
}
