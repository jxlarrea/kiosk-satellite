import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_container.dart';
import '../l10n/messages.dart';
import '../core/events.dart';
import '../managers/kiosk/drawer_items.dart';
import '../managers/sendspin/music_assistant_api.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/update/update_manager.dart';
import 'kit.dart';
import 'theme.dart';
import 'toast.dart';

/// Slide-out menu (swipe from the left edge), Fully Kiosk style: Home,
/// Settings, Clear web cache, Exit Application.
///
/// Not a Material [Drawer]: the kiosk pushes its content aside rather than
/// being covered (see KioskScreen), so this pane is square-cornered and
/// flush — the same plane as the WebView, not a sheet floating above it.
/// Only a hairline on its right edge marks the seam.
class KioskDrawer extends StatelessWidget {
  const KioskDrawer({
    super.key,
    required this.container,
    required this.onClose,
    required this.onSettings,
    this.restricted = false,
    this.tiles = false,
    this.onUnlock,
  });

  /// Compass navigation's Menu view: the same items as tiles across the
  /// screen instead of rows in a pane (see [_tilesView]).
  final bool tiles;

  /// The locked Menu view's Settings tile: the way in that the exit
  /// gesture is on the drawer.
  final VoidCallback? onUnlock;

  final AppContainer container;

  /// Quick-actions mode: the drawer was opened by an edge swipe while kiosk
  /// mode holds the door (kiosk.allow_drawer). Only the harmless actions the
  /// owner allowed are shown; everything that changes state or escapes the
  /// kiosk stays behind the exit gesture and PIN.
  final bool restricted;

  /// Slides the drawer (and the kiosk) back. Every action starts with this,
  /// mirroring how the old overlay drawer popped itself before acting.
  final VoidCallback onClose;

  /// Opens the settings screen (owned by the kiosk screen, which also holds
  /// the screensaver while it is up).
  final VoidCallback onSettings;

  AppContainer get c => container;

  /// The rows this menu draws, in order (issue #1194): Drawer menu items'
  /// pick and arrangement, less the rows with nothing to do here and, in
  /// the quick-actions menu, the ones Allowed Actions keeps out. The theme
  /// switcher is in the list when it shows, though it keeps the foot of
  /// the menu. The kiosk screen asks this too, so a locked kiosk with
  /// nothing to offer never mounts the edge swipe.
  static List<String> visibleItems(AppContainer c, {required bool restricted}) {
    bool allowed(defs.SettingDef<bool> action) =>
        !restricted || c.settings.get(action);
    bool can(String id) => switch (id) {
      'dashboard' => allowed(defs.kioskAllowDashboard),
      'settings' || 'clear_cache' => !restricted,
      'ha_kiosk' => allowed(defs.kioskAllowHaKiosk),
      // Only once the default view actually holds cameras: an empty one is
      // the placeholder every install starts with, and a menu entry that
      // can only fail is worse than no entry.
      'camera' =>
        allowed(defs.kioskAllowCamera) &&
            (c.camera.config.defaultView?.cameraIds.isNotEmpty ?? false),
      // Only while the intercom is on and the remote admin it rides is
      // serving, since the entry can do nothing without them.
      'intercom' =>
        allowed(defs.kioskAllowIntercom) &&
            c.intercom.enabled &&
            c.intercom.available,
      'alarms' => allowed(defs.kioskAllowAlarms),
      'calendar' => allowed(defs.kioskAllowCalendar),
      // Once some source is set up to browse.
      'music_library' =>
        allowed(defs.kioskAllowMusicLibrary) &&
            c.musicLibrary.available.isNotEmpty,
      // Shown only once its address is configured (the same one the
      // lyrics use).
      'music_assistant' =>
        allowed(defs.kioskAllowMusic) &&
            musicAssistantWebUrl(c.settings.get(defs.sendspinMaUrl)) != null,
      'player' =>
        allowed(defs.kioskAllowSendspinPlayer) &&
            c.settings.get(defs.sendspinPlayerActive),
      'now_playing' =>
        allowed(defs.kioskAllowSendspinPlayer) &&
            c.settings.get(defs.sendspinPlayerActive) &&
            c.settings.get(defs.sendspinFullscreen),
      'screensaver' => allowed(defs.kioskAllowScreensaver),
      'lockdown' => allowed(defs.kioskAllowLockdown),
      'hold' => allowed(defs.kioskAllowHold),
      // With the launcher enabled and apps actually whitelisted. The
      // restricted menu needs an app the locked kiosk allows.
      'apps' =>
        allowed(defs.kioskAllowApps) &&
            c.settings.get(defs.launcherEnabled) &&
            (restricted ? c.launcher.kioskApps : c.launcher.apps).isNotEmpty,
      // Restart Device (issue #528): only where the restart can land, as
      // device owner or over a granted Shizuku connection.
      'restart' => !restricted && c.kiosk.rebootSupported.value,
      // No exit while the kiosk IS the device's home screen: killing the
      // home only has the system relaunch it, so the entry could never
      // deliver what it promises (issue #219). Restart stays, it comes
      // back by design.
      'exit' => !restricted && !c.homeLauncher.roleHeld.value,
      'theme' => allowed(defs.kioskAllowTheme),
      _ => isDrawerPluginItem(id),
    };
    return DrawerItems.decode(c.settings.get(defs.uiDrawerItems))
        .arrange(
          [
            for (final action in c.plugins.drawerActions)
              drawerPluginItem('${action['pluginId']}', '${action['command']}'),
            ...drawerItemOrder,
          ],
          // Settings stays while the remote admin is off, or nothing would
          // lead back into it.
          forced: {if (!c.settings.get(defs.remoteEnabled)) 'settings'},
        )
        .where(can)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (tiles) return _tilesView(context);
    final items = visibleItems(c, restricted: restricted);
    final listed = items.where((id) => id != 'theme').toList();
    // The rows that leave or restart the app sit under a rule of their own
    // when they close the list, as they do by default.
    var power = listed.length;
    while (power > 0 && drawerPowerItems.contains(listed[power - 1])) {
      power--;
    }
    // Rows carry a hairline above them, all but the first of their group.
    final rows = <Widget>[
      for (final (i, id) in listed.indexed) ...[
        if (i == power && i > 0) const Divider(height: 1, thickness: 1),
        _row(context, id, divided: i > 0 && i != power),
      ],
    ];

    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Row(
                  children: [
                    // The mark, as vectors. Its teal keyline is what keeps
                    // the white house readable on the light theme.
                    SvgPicture.asset(
                      'assets/branding/mark.svg',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The title sits three down from the mark's
                          // center line, the name two under it: the
                          // title's cap height reads level with the mark
                          // that way.
                          const SizedBox(height: 3),
                          Text(
                            'Kiosk Satellite',
                            // The display face ties the header to the page
                            // titles and the screensaver clock.
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: Ks.displayFont,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // A step below the title, a point over the
                          // small body: the name reads as the header's
                          // second line rather than a caption on it.
                          const SizedBox(height: 2),
                          Text(
                            c.device.deviceName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize:
                                  (theme.textTheme.bodySmall?.fontSize ?? 12) +
                                  1,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // The actions, on one rounded section mask — the same card
              // language as the settings panes. The card hugs its content
              // and scrolls only if the screen is too short for it.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(Ks.radiusCard),
                        clipBehavior: Clip.antiAlias,
                        // Sideways inset only: each row already carries 16
                        // above and below its text, and the same 16 is
                        // what the first and last rows get to the card's
                        // edge, so the top and bottom rows sit like any
                        // other.
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [...rows],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Hold mode's lasting reminder (issue #266): the toast at the
              // flip is long gone when someone later wonders why the
              // screensaver never comes on. Shown in the restricted menu
              // too: releasing a hold is a harmless quick action, and the
              // person who pinned a recipe on a locked kiosk is the one who
              // needs to unpin it.
              StreamBuilder<SettingChanged>(
                stream: c.bus.on<SettingChanged>().where(
                  (e) => e.key == defs.haHoldMode.key,
                ),
                builder: (context, _) {
                  if (!c.settings.get(defs.haHoldMode)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Material(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(Ks.radiusRow),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () =>
                            unawaited(c.settings.set(defs.haHoldMode, false)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pause_circle_outline,
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n(context).drawerHoldActive,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme
                                                .colorScheme
                                                .onTertiaryContainer,
                                          ),
                                    ),
                                    Text(
                                      l10n(context).drawerHoldHelp,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onTertiaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Above the theme switcher: the update notice when GitHub has
              // a newer release, the running version otherwise — the wall is
              // where an update is noticed, not the repo page. Not in the
              // restricted menu: installing an update is not a quick action.
              if (!restricted)
                ValueListenableBuilder<UpdateInfo?>(
                  valueListenable: c.update.available,
                  builder: (context, info, _) => Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: info == null
                        // Tappable: a manual "check now" — the periodic check
                        // runs only twice a day, and the wall is where "did my
                        // update land?" gets asked.
                        ? InkWell(
                            borderRadius: BorderRadius.circular(
                              Ks.radiusControl,
                            ),
                            onTap: () => _checkNow(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                l10n(
                                  context,
                                ).drawerVersion(c.device.appVersion),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : Material(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(Ks.radiusRow),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _offerUpdate(context, info),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.system_update_outlined,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n(context).drawerUpdateAvailable,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                          Text(
                                            l10n(
                                              context,
                                            ).drawerUpdateInstall(info.version),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              // The theme switcher, docked at the foot of the menu. Icons
              // only — no label or separator: the card above already bounds
              // the actions, and the compact pill is the whole footer.
              // Flipping it is the kind of thing done at the wall, at night,
              // without a trip into Settings; it applies live (main.dart
              // listens for the setting) and the drawer stays open.
              if (items.contains('theme'))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Center(
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: 'dark',
                          icon: const Icon(Icons.dark_mode_outlined),
                          tooltip: l10n(context).drawerThemeDark,
                        ),
                        ButtonSegment(
                          value: 'light',
                          icon: const Icon(Icons.light_mode_outlined),
                          tooltip: l10n(context).drawerThemeLight,
                        ),
                        ButtonSegment(
                          value: 'system',
                          icon: const Icon(Icons.brightness_auto_outlined),
                          tooltip: l10n(context).drawerThemeAndroid,
                        ),
                      ],
                      selected: {c.settings.get(defs.uiTheme)},
                      onSelectionChanged: (selection) => c.settings.setFromJson(
                        defs.uiTheme.key,
                        selection.first,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The row for [id], one of [visibleItems].
  Widget _row(BuildContext context, String id, {required bool divided}) {
    void run(String command) {
      onClose();
      c.commands.execute(command, const {});
    }

    Widget item(Object icon, String label, VoidCallback onTap) =>
        _item(context, icon, label, onTap, divided: divided, id: id);
    final strings = l10n(context);
    switch (id) {
      case 'dashboard':
        return item(Icons.dashboard_outlined, strings.drawerDashboard, () {
          onClose();
          c.commands.execute('loadUrl', {'url': c.browser.startUrl});
        });
      case 'settings':
        return item(Icons.settings_outlined, strings.commonSettings, () {
          onClose();
          onSettings();
        });
      // One tap between hidden and shown: bringing the HA header and
      // sidebar back briefly is the kind of thing done at the wall,
      // without a trip into Settings. The kiosk screen reacts to the
      // setting change and restyles the page. Behind its own Allowed
      // Action in the restricted menu (issue #422): the owner who hid the
      // header and sidebar decides whether a visitor may bring them back.
      case 'ha_kiosk':
        return item(
          c.settings.get(defs.haKioskMode)
              ? Icons.fullscreen_exit
              : Icons.fullscreen,
          strings.drawerHaKiosk,
          () async {
            onClose();
            await c.settings.set(
              defs.haKioskMode,
              !c.settings.get(defs.haKioskMode),
            );
          },
        );
      case 'camera':
        return item(Icons.videocam_outlined, strings.drawerCameraView, () {
          onClose();
          if (c.camera.config.defaultView case final view?) {
            c.camera.showView(view.id);
          }
        });
      // The intercom's sheet: Everyone, then the kiosks that are ready.
      case 'intercom':
        return item(
          Icons.speaker_phone_outlined,
          strings.drawerIntercom,
          () => run('intercomOpen'),
        );
      // The kiosk's own alarms: the full screen list.
      case 'alarms':
        return item(Icons.alarm, strings.alarmsTitle, () => run('openAlarms'));
      // The family calendar, the same way.
      case 'calendar':
        return item(
          Icons.calendar_month_outlined,
          strings.calendarTitle,
          () => run('openCalendar'),
        );
      case 'music_library':
        return item(
          Icons.library_music_outlined,
          strings.libraryTitle,
          () => run('openMusicLibrary'),
        );
      // Music Assistant's own web interface, over the dashboard on the
      // same surface a tapped link gets: browsing, queueing and playlists
      // belong to the server that already does all of it well.
      case 'music_assistant':
        return item(
          'assets/svg/music-assistant.svg',
          strings.drawerMusicAssistant,
          () => run('showMusicAssistant'),
        );
      case 'player':
        return _sendspinItem(context, divided: divided);
      case 'now_playing':
        return _nowPlayingItem(context, divided: divided);
      case 'screensaver':
        return item(
          Icons.dark_mode_outlined,
          strings.drawerScreensaver,
          () => run('startScreensaver'),
        );
      case 'lockdown':
        return item(Icons.lock_outline, strings.drawerLockdown, () async {
          onClose();
          await c.kiosk.lockFromMenu();
        });
      case 'hold':
        return _holdItem(context, divided: divided);
      case 'apps':
        return item(Icons.apps_outlined, strings.drawerApps, () {
          onClose();
          c.launcher.open(unlocked: !restricted);
        });
      case 'clear_cache':
        return item(
          Icons.cleaning_services_outlined,
          strings.drawerClearCache,
          () => run('clearWebCache'),
        );
      case 'restart':
        return item(
          Icons.restart_alt_outlined,
          strings.drawerRestartDevice,
          () async {
            onClose();
            if (context.mounted &&
                await showConfirmDialog(
                  context,
                  title: l10n(context).drawerRestartDevice,
                  message: l10n(context).drawerRestartConfirm,
                  confirmLabel: l10n(context).drawerRestart,
                )) {
              await c.commands.execute('rebootDevice', const {});
            }
          },
        );
      case 'exit':
        return item(
          Icons.power_settings_new_outlined,
          strings.drawerExitApplication,
          () async {
            onClose();
            if (context.mounted &&
                await showConfirmDialog(
                  context,
                  title: l10n(context).drawerExitApplication,
                  message: l10n(context).drawerExitConfirm,
                  confirmLabel: l10n(context).drawerExit,
                )) {
              await c.commands.execute('exitApp', const {});
            }
          },
        );
    }
    final action = c.plugins.drawerActions.firstWhere(
      (a) => drawerPluginItem('${a['pluginId']}', '${a['command']}') == id,
    );
    return item(
      Icons.extension_outlined,
      strings.drawerPluginAction(
        '${action['pluginName']}',
        '${action['title']}',
      ),
      () async {
        onClose();
        final result = await c.commands.execute('runPluginCommand', {
          'id': action['pluginId'],
          'command': action['command'],
        });
        if (!result.ok && context.mounted) {
          showToast(
            context,
            source: 'plugins',
            title: l10n(context).drawerPluginActionErrorTitle,
            message: result.error ?? l10n(context).drawerPluginActionError,
            kind: ToastKind.error,
          );
        }
      },
    );
  }

  /// One action row, same weight language as the settings rail.
  /// The Sendspin player row: its label follows the player card, so it
  /// rebuilds on its own; [divided] is decided where the row sits in the
  /// list, like every other row's.
  Widget _sendspinItem(BuildContext context, {required bool divided}) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        c.sendspin.nowPlaying,
        c.sendspin.cardOverride,
      ]),
      builder: (context, _) {
        final shown = c.sendspin.cardShown;
        return _item(
          divided: divided,
          context,
          Icons.play_circle_outlined,
          shown
              ? l10n(context).drawerHidePlayer
              : l10n(context).drawerShowPlayer,
          id: 'player',
          () {
            onClose();
            if (shown) {
              c.sendspin.cardOverride.value = false;
            } else {
              c.bus.publish(const SendspinShowPlayerRequested());
            }
          },
        );
      },
    );
  }

  /// The Now Playing row: present while a track is loaded (playing or
  /// paused), gone otherwise, so it never leads to the regular
  /// screensaver by mistake.
  Widget _nowPlayingItem(BuildContext context, {required bool divided}) {
    return ValueListenableBuilder<Map<String, Object?>?>(
      valueListenable: c.sendspin.nowPlaying,
      builder: (context, now, _) {
        if (now == null) return const SizedBox.shrink();
        return _item(
          divided: divided,
          context,
          Icons.album_outlined,
          l10n(context).drawerNowPlaying,
          id: 'now_playing',
          () {
            onClose();
            unawaited(c.sendspin.showFullscreen());
          },
        );
      },
    );
  }

  /// The Hold mode row (issue #266). Unlike the notice below the list it
  /// can also ENGAGE a hold. The label follows the live state: the drawer
  /// widget stays mounted between opens, so it listens for the flip
  /// itself (a remote-admin flip shows too).
  Widget _holdItem(BuildContext context, {required bool divided}) {
    return StreamBuilder<SettingChanged>(
      stream: c.bus.on<SettingChanged>().where(
        (e) => e.key == defs.haHoldMode.key,
      ),
      builder: (context, _) {
        final on = c.settings.get(defs.haHoldMode);
        return _item(
          divided: divided,
          context,
          Icons.pause_circle_outline,
          on ? l10n(context).drawerHoldOff : l10n(context).drawerHoldOn,
          id: 'hold',
          () {
            onClose();
            unawaited(c.settings.set(defs.haHoldMode, !on));
          },
        );
      },
    );
  }

  /// One menu row. [icon] is a Material glyph, or the path of an SVG asset
  /// for the entries that answer to a product rather than a feature — the
  /// same rule the settings rail follows, drawn in the row's own color so a
  /// product mark does not become the one colored thing in the menu.
  Widget _item(
    BuildContext context,
    Object icon,
    String label,
    VoidCallback onTap, {
    bool divided = true,
    String id = '',
  }) {
    if (tiles) {
      return _menuPiece(
        context,
        id: id,
        icon: icon,
        label: label,
        onTap: onTap,
      );
    }
    final theme = Theme.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(Ks.radiusRow),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (icon is String)
                // Boxed to the glyph size so every label in the menu starts
                // on the same line, whatever the mark's own proportions.
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Center(
                    child: SvgPicture.asset(
                      icon,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                )
              else
                Icon(
                  icon as IconData,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  // The same style the settings rail titles use — titleMedium,
                  // not bodyLarge: both are 16px, but bodyLarge tracks looser
                  // (letter-spacing 0.5 vs 0.15) and the difference shows.
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!divided) return row;
    // A faint hairline over every row but the first of its group, the full
    // width of the row.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        row,
      ],
    );
  }

  /// Manual update check from the version line. An update found swaps the
  /// line for the notice via its ValueListenableBuilder on its own; the
  /// other two outcomes only exist as this feedback.
  Future<void> _checkNow(BuildContext context) async {
    final strings = l10n(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    // Tagged so a turned off Update checks never takes down another toast.
    showToastIn(
      overlay,
      source: 'updates',
      title: strings.drawerUpdateChecking,
      sticky: true,
      tag: 'update-check',
    );
    final reachable = await c.update.check();
    dismissToast(tag: 'update-check');
    if (c.update.available.value != null) return;
    if (reachable) {
      showToastIn(
        overlay,
        source: 'updates',
        title: strings.drawerUpdateCurrent,
        message: strings.drawerUpdateCurrentHelp,
        kind: ToastKind.success,
      );
    } else {
      showToastIn(
        overlay,
        source: 'updates',
        title: strings.drawerUpdateCheckFailed,
        message: strings.drawerUpdateOffline,
        kind: ToastKind.error,
      );
    }
  }

  /// Release notes → download (progress dialog) → hand off to the Android
  /// installer, which asks its own final confirmation. The drawer stays put
  /// underneath so a cancelled install lands somewhere sensible.
  Future<void> _offerUpdate(BuildContext context, UpdateInfo info) async {
    final theme = Theme.of(context);
    final canRelaunch = await c.update.canRelaunch();
    if (!context.mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n(context).drawerUpdateTo(info.version)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._releaseNotes(context, theme, info.notes),
                const SizedBox(height: 16),
                Text(
                  l10n(context).drawerUpdateInstructions,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!canRelaunch) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n(context).drawerUpdateRelaunch,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n(context).drawerUpdate),
          ),
        ],
      ),
    );
    if (go != true) return;
    if (!context.mounted) return;
    // Not awaited: the dialog is closed from below once the download
    // settles, whichever way it settles.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n(context).drawerUpdateDownloading),
          content: ValueListenableBuilder<double?>(
            valueListenable: c.update.progress,
            builder: (context, p, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: p),
                const SizedBox(height: 12),
                Text(
                  p == null
                      ? l10n(context).drawerUpdateStarting
                      : '${(p * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
          actions: [
            // No pop of its own: the cancel unwinds the download, whose
            // completion closes this dialog through the path below like
            // every other way a download ends (#272).
            TextButton(
              onPressed: c.update.cancelDownload,
              child: Text(l10n(context).commonCancel),
            ),
          ],
        ),
      ),
    );
    final error = await c.update.downloadAndInstall();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (error != null) {
      // The download re-checks GitHub before it starts, so it can also come
      // back with "nothing to install" (the offered release was pulled and
      // this build is the latest); that is not a failure. Nothing pending
      // afterwards is what tells the two apart.
      final pending = c.update.available.value != null;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            pending
                ? l10n(context).drawerUpdateFailed
                : l10n(context).drawerUpdates,
          ),
          content: Text(deviceOperationError(context, error)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n(context).commonOk),
            ),
          ],
        ),
      );
    }
  }

  /// The GitHub release body, markdown-lite: headings bold, list markers as
  /// bullets, emphasis/code/link syntax stripped. A real markdown renderer
  /// is a dependency this one dialog does not justify.
  List<Widget> _releaseNotes(
    BuildContext context,
    ThemeData theme,
    String notes,
  ) {
    String inline(String s) => s
        .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1] ?? '')
        .replaceAll(RegExp(r'\*\*|__|`'), '');
    if (notes.isEmpty) {
      return [
        Text(
          l10n(context).drawerNoReleaseNotes,
          style: theme.textTheme.bodyMedium,
        ),
      ];
    }
    final out = <Widget>[];
    for (final raw in notes.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        out.add(const SizedBox(height: 10));
      } else if (line.startsWith('#')) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              inline(line.replaceFirst(RegExp(r'^#+\s*'), '')),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else if (RegExp(r'^\s*[-*]\s+').hasMatch(line)) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '•  ${inline(line.replaceFirst(RegExp(r'^\s*[-*]\s+'), ''))}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      } else {
        out.add(Text(inline(line), style: theme.textTheme.bodyMedium));
      }
    }
    return out;
  }
}

extension _MenuView on KioskDrawer {
  /// Compass navigation's Quick Controls view: the switches and one-tap
  /// actions as pills that light up while on, Settings and the pages the
  /// menu opens as square cards, and Restart and Exit as quiet links at
  /// the foot with the version and build across from them. Every item is the drawer's own row ([_row]),
  /// drawn by [_menuPiece]. On a locked kiosk only the Allowed Actions
  /// show, and Settings is a locked card that asks for the exit gesture's
  /// PIN.
  Widget _tilesView(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = l10n(context);
    final items = KioskDrawer.visibleItems(c, restricted: restricted);
    final listed = [
      for (final id in items)
        if (id != 'theme' && id != 'settings' && id != 'dashboard')
          // Now Playing draws nothing while no track is loaded, which in a
          // grid would leave a hole.
          if (id != 'now_playing' || c.sendspin.nowPlaying.value != null) id,
    ];
    final quick = [
      for (final id in listed)
        if (!_menuOpens.contains(id) && !drawerPowerItems.contains(id))
          _row(context, id, divided: false),
    ];
    // Settings leads the pages: the first card, locked behind the PIN on a
    // locked kiosk.
    final Widget? settings = items.contains('settings')
        ? _MenuCard(
            icon: Icons.settings_outlined,
            label: strings.commonSettings,
            onTap: () {
              onClose();
              onSettings();
            },
          )
        : restricted && onUnlock != null
        ? _MenuCard(
            icon: Icons.lock_outline,
            label: strings.commonSettings,
            onTap: onUnlock!,
          )
        : null;
    final opens = [
      ?settings,
      for (final id in listed)
        if (_menuOpens.contains(id)) _row(context, id, divided: false),
    ];
    final power = [
      for (final id in listed)
        if (drawerPowerItems.contains(id)) _row(context, id, divided: false),
    ];
    final theming = items.contains('theme')
        ? SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'dark',
                icon: const Icon(Icons.dark_mode_outlined),
                tooltip: strings.drawerThemeDark,
              ),
              ButtonSegment(
                value: 'light',
                icon: const Icon(Icons.light_mode_outlined),
                tooltip: strings.drawerThemeLight,
              ),
              ButtonSegment(
                value: 'system',
                icon: const Icon(Icons.brightness_auto_outlined),
                tooltip: strings.drawerThemeAndroid,
              ),
            ],
            selected: {c.settings.get(defs.uiTheme)},
            onSelectionChanged: (selection) =>
                c.settings.setFromJson(defs.uiTheme.key, selection.first),
          )
        : null;
    // The foot's buttons drop their own padding, so the version sits on the
    // page's edge like everything above it.
    final footStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    final Widget? version = restricted
        ? null
        : ValueListenableBuilder<UpdateInfo?>(
            valueListenable: c.update.available,
            builder: (context, info, _) => info == null
                ? TextButton(
                    style: footStyle,
                    onPressed: () => _checkNow(context),
                    child: Text(
                      strings.drawerVersion(
                        c.device.buildNumber.isEmpty
                            ? c.device.appVersion
                            : '${c.device.appVersion} (${c.device.buildNumber})',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : FilledButton.tonalIcon(
                    onPressed: () => _offerUpdate(context, info),
                    icon: const Icon(Icons.system_update_outlined),
                    label: Text(strings.drawerUpdateAvailable),
                  ),
          );
    final locked = c.kiosk.locked && restricted
        ? Chip(
            avatar: Icon(
              Icons.lock_outline,
              size: 16,
              color: scheme.onTertiaryContainer,
            ),
            label: Text(strings.compassKioskLocked),
            backgroundColor: scheme.tertiaryContainer,
            labelStyle: TextStyle(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
          )
        : null;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 600;
            // An Echo Show 5 is 393 tall: everything tightens to fit
            // without scrolling.
            final compact = box.maxHeight < 560;
            final pad = wide ? (compact ? 16.0 : 28.0) : 16.0;
            final gap = compact ? 8.0 : 12.0;
            // The room between the header and the first section, and
            // between sections.
            final afterHeader = compact ? 18.0 : 32.0;
            final betweenSections = compact ? 16.0 : 28.0;
            const headingHeight = 28.0;
            const footHeight = 40.0;
            final headerHeight = wide ? (compact ? 48.0 : 64.0) : 56.0;
            final inner = box.maxWidth - pad * 2;

            Widget heading(String text) => SizedBox(
              height: headingHeight,
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  text.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            );
            Widget grid(List<Widget> children, double width, double height) =>
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final child in children)
                      SizedBox(width: width, height: height, child: child),
                  ],
                );

            // A short row of pills spreads out rather than leave empty
            // columns.
            final quickColumns = wide ? quick.length.clamp(3, 5) : 2;
            final pillWidth = (inner - gap * (quickColumns - 1)) / quickColumns;
            final pillHeight = compact ? 52.0 : 64.0;
            final quickRows = (quick.length / quickColumns).ceil();
            // Square cards, in one row while they stay big enough to read.
            final minCard = compact ? 76.0 : (wide ? 96.0 : 88.0);
            final maxCard = compact ? 112.0 : 136.0;
            var openColumns = math.max(1, opens.length);
            double cardSide() =>
                (inner - gap * (openColumns - 1)) / openColumns;
            while (openColumns > 1 && cardSide() < minCard) {
              openColumns--;
            }
            final card = math.min(cardSide(), maxCard);
            final openRows = (opens.length / openColumns).ceil();

            final used =
                pad * 2 +
                headerHeight +
                afterHeader +
                (quick.isEmpty
                    ? 0
                    : headingHeight +
                          quickRows * pillHeight +
                          (quickRows - 1) * gap +
                          betweenSections) +
                (opens.isEmpty
                    ? 0
                    : headingHeight + openRows * card + (openRows - 1) * gap) +
                footHeight;
            // Whatever is left goes above the foot, so the version and
            // Restart and Exit sit at the bottom of the screen.
            final footRoom = math.max(betweenSections, box.maxHeight - used);

            final title = Row(
              spacing: compact ? 12 : 16,
              children: [
                SvgPicture.asset(
                  'assets/branding/mark.svg',
                  width: compact ? 40 : 52,
                  height: compact ? 40 : 52,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kiosk Satellite',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (compact
                                    ? theme.textTheme.titleLarge
                                    : theme.textTheme.headlineSmall)
                                ?.copyWith(
                                  fontFamily: Ks.displayFont,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        c.device.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final footer = SizedBox(
              height: footHeight,
              child: Row(children: [...power, const Spacer(), ?version]),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: headerHeight,
                    child: Row(
                      spacing: 12,
                      children: [
                        Expanded(child: title),
                        ?locked,
                        ?theming,
                      ],
                    ),
                  ),
                  SizedBox(height: afterHeader),
                  if (quick.isNotEmpty) ...[
                    heading(strings.compassQuickControls),
                    grid(quick, pillWidth, pillHeight),
                    SizedBox(height: betweenSections),
                  ],
                  if (opens.isNotEmpty) ...[
                    heading(strings.compassOpen),
                    grid(opens, card, card),
                  ],
                  SizedBox(height: footRoom),
                  footer,
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// One item of the Quick Controls view: a quick control pill, a page
  /// card or a link at the foot, by what the item does. Toggles carry
  /// their state.
  Widget _menuPiece(
    BuildContext context, {
    required String id,
    required Object icon,
    required String label,
    required VoidCallback onTap,
  }) {
    if (drawerPowerItems.contains(id)) {
      return _MenuLink(icon: icon, label: label, onTap: onTap);
    }
    if (_menuOpens.contains(id)) {
      return _MenuCard(icon: icon, label: label, onTap: onTap);
    }
    final strings = l10n(context);
    bool? on;
    var name = label;
    switch (id) {
      case 'ha_kiosk':
        on = c.settings.get(defs.haKioskMode);
      case 'hold':
        on = c.settings.get(defs.haHoldMode);
        name = strings.compassHoldMode;
    }
    return _MenuPill(
      icon: icon,
      label: name,
      onTap: onTap,
      on: on,
      state: on == null
          ? null
          : on
          ? strings.compassStateOn
          : strings.compassStateOff,
    );
  }
}

/// The Quick Controls view's page items, which go in the square cards
/// after Settings. Everything else but Restart and Exit is a quick control.
const _menuOpens = [
  'camera',
  'intercom',
  'alarms',
  'calendar',
  'music_library',
  'music_assistant',
  'now_playing',
  'apps',
];

/// The app's circled icon, in one quiet color for every item: the
/// secondary container with its glyph on it.
class _MenuDisc extends StatelessWidget {
  const _MenuDisc({
    required this.icon,
    required this.size,
    this.color,
    this.glyph,
  });

  final Object icon;
  final double size;
  final Color? color;
  final Color? glyph;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? scheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: _menuGlyph(icon, size * 0.5, glyph ?? scheme.onSecondaryContainer),
    );
  }
}

/// An item's glyph: a Material icon, or a product mark drawn in [color].
Widget _menuGlyph(Object icon, double size, Color color) => icon is String
    ? SvgPicture.asset(
        icon,
        width: size * 0.92,
        height: size * 0.92,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      )
    : Icon(icon as IconData, size: size, color: color);

/// A quick control: a pill with the circled glyph, the name and, for a
/// switch, its state. A switch that is on fills with the primary color and
/// its disc turns light.
class _MenuPill extends StatelessWidget {
  const _MenuPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.on,
    this.state,
  });

  final Object icon;
  final String label;
  final VoidCallback onTap;
  final bool? on;
  final String? state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lit = on == true;
    final ink = lit ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      toggled: on,
      button: true,
      child: Material(
        color: lit ? scheme.primary : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              spacing: 12,
              children: [
                _MenuDisc(
                  icon: icon,
                  size: 36,
                  color: lit ? scheme.onPrimary : null,
                  glyph: lit ? scheme.primary : null,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      if (state != null)
                        Text(
                          state!,
                          maxLines: 1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: lit
                                ? scheme.onPrimary.withValues(alpha: 0.8)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A page the menu opens, or Settings: a square card with the circled
/// glyph over its name.
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Object icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, box) {
            final small = box.maxWidth < 100;
            final style =
                (small
                        ? theme.textTheme.labelMedium
                        : theme.textTheme.titleSmall)
                    ?.copyWith(fontWeight: FontWeight.w500, height: 1.2);
            // Room for two lines under every disc, so the discs line up
            // across the row whether a name wraps or not.
            final labelHeight = (style?.fontSize ?? 14) * 1.2 * 2;
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: small ? 6 : 10,
                children: [
                  _MenuDisc(
                    icon: icon,
                    size: (box.maxWidth * 0.4).clamp(32.0, 56.0),
                  ),
                  SizedBox(
                    height: labelHeight,
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Restart Device and Exit Application, quiet at the foot of the menu.
class _MenuLink extends StatelessWidget {
  const _MenuLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Object icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: _menuGlyph(icon, 20, color),
      label: Text(label),
    );
  }
}
