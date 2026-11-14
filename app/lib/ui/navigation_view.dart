import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/settings/definitions.dart' as defs;
import 'compass/compass_controller.dart';

/// Which page or view the kiosk shows, in both navigation styles, and
/// whether the plugin overlays of the views layer may draw over it.
///
/// The view is the topmost surface in the kiosk's stack, the screensaver
/// left out (plugins hear it through screensaver.state) except Now
/// Playing, which reports itself while it is on screen. Each change is
/// published as [NavigationViewChanged].
class NavigationViewTracker {
  NavigationViewTracker(this.c, this.compass, this.drawer);

  final AppContainer c;
  final CompassController compass;

  /// The Classic drawer: the menu while it is anywhere but closed.
  final Animation<double> drawer;

  final view = ValueNotifier<NavigationViewChanged>(
    const NavigationViewChanged(mode: 'classic', view: 'dashboard'),
  );

  /// The views layer stands down under the screensaver, the menu and a
  /// Compass swipe in motion, whose snapshots already show it. Now Playing
  /// as the Compass view on screen is a view, not a screensaver.
  final viewsLayerHidden = ValueNotifier<bool>(false);

  late final Listenable _inputs = Listenable.merge([
    c.camera.activeViewId,
    c.musicLibrary.visible,
    c.calendar.visible,
    c.alarms.visible,
    c.voiceTimers.visible,
    c.intercom.rosterVisible,
    c.launcher.visible,
    c.browser.overlayUrl,
    c.screensaver.activeView,
    c.screensaver.nowPlayingCovers,
    compass.menuVisible,
    compass.current,
    compass.overlaysHidden,
  ]);
  StreamSubscription<AppEvent>? _sub;

  void start() {
    _inputs.addListener(_sync);
    drawer.addStatusListener(_onDrawer);
    _sub = c.bus.stream.listen((e) {
      if (e is ScreensaverStateChanged ||
          e is FullscreenViewChanged ||
          (e is SettingChanged && e.key == defs.navStyle.key)) {
        _sync();
      }
    });
    _sync();
  }

  void dispose() {
    _inputs.removeListener(_sync);
    drawer.removeStatusListener(_onDrawer);
    unawaited(_sub?.cancel());
    view.dispose();
    viewsLayerHidden.dispose();
  }

  void _onDrawer(AnimationStatus _) => _sync();

  bool get _nowPlayingUp =>
      c.screensaver.isActive && c.screensaver.nowPlayingShown;

  @visibleForTesting
  NavigationViewChanged resolve() {
    final mode = compass.enabled ? 'compass' : 'classic';
    NavigationViewChanged at(String view, [String? id]) =>
        NavigationViewChanged(mode: mode, view: view, id: id);
    // Top to bottom, as kiosk_screen.dart stacks them.
    final camera = c.camera.activeViewId.value;
    if (camera != null) return at('camera', camera);
    if (_nowPlayingUp) return at('now_playing');
    if (c.musicLibrary.visible.value) return at('music_library');
    if (c.calendar.visible.value) return at('calendar');
    if (c.voiceTimers.visible.value) return at('timers');
    if (c.alarms.visible.value) return at('alarms');
    if (c.intercom.rosterVisible.value) return at('intercom');
    if (c.launcher.visible.value) return at('app_launcher');
    if (compass.enabled && compass.menuVisible.value) return at('menu');
    if (drawer.status != AnimationStatus.dismissed) return at('menu');
    if (c.browser.overlayUrl.value != null) return at('overlay_page');
    return at('dashboard');
  }

  @visibleForTesting
  bool layerHidden(NavigationViewChanged now) {
    if (compass.overlaysHidden.value) return true;
    if (now.view == 'menu') return true;
    if (drawer.status != AnimationStatus.dismissed) return true;
    if (!c.screensaver.isActive) return false;
    return !(compass.enabled &&
        now.view == 'now_playing' &&
        compass.currentView.kind == 'now_playing');
  }

  void _sync() {
    final next = resolve();
    viewsLayerHidden.value = layerHidden(next);
    if (next == view.value) return;
    view.value = next;
    c.bus.publish(next);
  }
}
