import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/navigation/compass_layout.dart';

void main() {
  group('CompassLayout.decode', () {
    test('an empty or unreadable value is Home Assistant with the Menu', () {
      for (final raw in ['', '  ', 'not json', '[1,2]']) {
        final layout = CompassLayout.decode(raw);
        expect(layout.center.isDashboard, isTrue, reason: raw);
        expect(layout.center.path, '');
        expect(layout.up, isEmpty);
        expect(layout.left, [CompassView.menu]);
      }
      // A stored layout without a Menu stays without one.
      expect(CompassLayout.decode('{"left":[]}').left, isEmpty);
    });

    test('a side keeps at most two views', () {
      final layout = CompassLayout.decode(
        '{"right":[{"kind":"calendar"},{"kind":"alarms"},'
        '{"kind":"music_library"}]}',
      );
      expect(layout.right.map((v) => v.kind), ['calendar', 'alarms']);
    });

    test('each kind shows once, the center first', () {
      final layout = CompassLayout.decode(
        '{"center":{"kind":"calendar"},'
        '"up":[{"kind":"calendar"},{"kind":"alarms"}],'
        '"down":[{"kind":"alarms"}],'
        '"left":[{"kind":"camera","id":"front"},{"kind":"camera","id":"back"}]}',
      );
      expect(layout.center.kind, 'calendar');
      expect(layout.up.map((v) => v.key), ['alarms']);
      expect(layout.down, isEmpty);
      expect(layout.left.single.id, 'front');
    });

    test('dashboard views repeat, each path once', () {
      final layout = CompassLayout.decode(
        '{"up":[{"kind":"dashboard","path":"a/b"},'
        '{"kind":"dashboard","path":"a/b"}],'
        '"down":[{"kind":"dashboard","path":"c/d"},{"kind":"dashboard"}],'
        '"right":[{"kind":"dashboard","path":" a/b "}]}',
      );
      expect(layout.center, CompassView.home);
      expect(layout.up.map((v) => v.path), ['a/b']);
      // The home dashboard is the center already.
      expect(layout.down.map((v) => v.path), ['c/d']);
      expect(layout.right, isEmpty);
      expect(layout.dashboards.map((v) => v.path), ['', 'a/b', 'c/d']);
      expect(
        layout.slotOf(const CompassView('dashboard', path: 'c/d')),
        const CompassSlot(CompassArm.down),
      );
      expect(CompassLayout.decode(layout.encode()).encode(), layout.encode());
    });

    test('unknown kinds and a camera without a view are dropped', () {
      final layout = CompassLayout.decode(
        '{"up":[{"kind":"weather"},{"kind":"camera"}]}',
      );
      expect(layout.up, isEmpty);
    });

    test('encode round trips', () {
      const layout = CompassLayout(
        center: CompassView('music_library'),
        up: [CompassView('calendar')],
        right: [CompassView('dashboard', path: 'home/kitchen')],
        down: [CompassView('camera', id: 'front')],
        left: [CompassView('alarms'), CompassView('intercom')],
      );
      final back = CompassLayout.decode(layout.encode());
      expect(back.encode(), layout.encode());
    });

    test('the normalizer stores what decode reads', () {
      final raw = '{"up":[{"kind":"calendar"},{"kind":"calendar"}]}';
      expect(normalizeCompassLayout(raw), CompassLayout.decode(raw).encode());
      expect(normalizeCompassLayout(''), '');
      expect(validateCompassLayout('nope'), isNotNull);
      expect(validateCompassLayout(''), isNull);
    });
  });

  group('the Menu view', () {
    test('goes anywhere, once', () {
      final layout = CompassLayout.decode(
        '{"left":[{"kind":"alarms"}],"up":[{"kind":"menu"}],'
        '"down":[{"kind":"menu"}]}',
      );
      expect(layout.up, [CompassView.menu]);
      expect(layout.down, isEmpty);
      expect(layout.slotOf(CompassView.menu), const CompassSlot(CompassArm.up));
    });

    test('withMenu adds one where there is room, left first', () {
      final none = CompassLayout.decode('{"left":[]}');
      expect(none.withMenu().left, [CompassView.menu]);
      final leftFull = CompassLayout.decode(
        '{"left":[{"kind":"alarms"},{"kind":"calendar"}]}',
      );
      expect(leftFull.withMenu().right, [CompassView.menu]);
      final placed = CompassLayout.decode('{"up":[{"kind":"menu"}]}');
      expect(identical(placed.withMenu(), placed), isTrue);
      final full = CompassLayout.decode(
        '{"up":[{"kind":"calendar"},{"kind":"alarms"}],'
        '"right":[{"kind":"music_library"},{"kind":"now_playing"}],'
        '"down":[{"kind":"intercom"},{"kind":"app_launcher"}],'
        '"left":[{"kind":"camera","id":"a"},{"kind":"dashboard","path":"x"}]}',
      );
      // Every side is full: the left side's last view gives way.
      expect(full.withMenu().left.last, CompassView.menu);
      expect(full.withMenu().holds(CompassView.menu), isTrue);
    });
  });

  group('step', () {
    final layout = CompassLayout.decode(
      '{"up":[{"kind":"calendar"}],'
      '"right":[{"kind":"music_library"},{"kind":"now_playing"}],'
      '"left":[{"kind":"alarms"},{"kind":"menu"}]}',
    );

    test('from the center each side starts with its first view', () {
      expect(
        layout.step(CompassSlot.center, CompassMove.right),
        const CompassSlot(CompassArm.right, 0),
      );
      expect(
        layout.step(CompassSlot.center, CompassMove.up),
        const CompassSlot(CompassArm.up, 0),
      );
      expect(
        layout.step(CompassSlot.center, CompassMove.left),
        const CompassSlot(CompassArm.left, 0),
      );
      // Nothing below the center.
      expect(layout.step(CompassSlot.center, CompassMove.down), isNull);
    });

    test('out along a side and back to the center', () {
      const first = CompassSlot(CompassArm.right, 0);
      const second = CompassSlot(CompassArm.right, 1);
      expect(layout.step(first, CompassMove.right), second);
      expect(layout.step(second, CompassMove.right), isNull);
      expect(layout.step(second, CompassMove.left), first);
      expect(layout.step(first, CompassMove.left), CompassSlot.center);
    });

    test('the left side runs on to the Menu', () {
      const alarms = CompassSlot(CompassArm.left, 0);
      const menu = CompassSlot(CompassArm.left, 1);
      expect(layout.step(alarms, CompassMove.left), menu);
      expect(layout.step(menu, CompassMove.right), alarms);
    });

    test('a move across a side leads nowhere', () {
      const right = CompassSlot(CompassArm.right, 0);
      expect(layout.step(right, CompassMove.up), isNull);
      expect(layout.step(right, CompassMove.down), isNull);
    });

    test('a view that cannot show is skipped', () {
      bool available(CompassView v) => v.kind != 'music_library';
      expect(
        layout.step(
          CompassSlot.center,
          CompassMove.right,
          available: available,
        ),
        const CompassSlot(CompassArm.right, 1),
      );
      expect(
        layout.step(
          const CompassSlot(CompassArm.right, 1),
          CompassMove.left,
          available: available,
        ),
        CompassSlot.center,
      );
      bool nothing(CompassView v) => v.kind == 'menu';
      expect(
        layout.step(CompassSlot.center, CompassMove.right, available: nothing),
        isNull,
      );
      // An empty left side still leads to the Menu.
      expect(
        layout.step(CompassSlot.center, CompassMove.left, available: nothing),
        const CompassSlot(CompassArm.left, 1),
      );
    });
  });

  test('slots map onto the position grid', () {
    expect(CompassSlot.center.grid, (x: 0, y: 0));
    expect(const CompassSlot(CompassArm.up, 1).grid, (x: 0, y: -2));
    expect(const CompassSlot(CompassArm.left, 2).grid, (x: -3, y: 0));
    expect(const CompassSlot(CompassArm.right, 0).grid, (x: 1, y: 0));
  });

  test('holds reports a kind anywhere in the layout', () {
    final layout = CompassLayout.decode(
      '{"down":[{"kind":"camera","id":"front"}]}',
    );
    expect(layout.holds(const CompassView('camera', id: 'other')), isTrue);
    expect(layout.holds(CompassView.home), isTrue);
    // A dashboard view is held by its path.
    expect(layout.holds(const CompassView('dashboard', path: 'a/b')), isFalse);
    expect(layout.holds(const CompassView('calendar')), isFalse);
  });
}
