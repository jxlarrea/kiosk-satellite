import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/launcher/app_launcher_manager.dart';
import '../managers/settings/definitions.dart' as defs;
import 'toast.dart';

/// The app launcher (issue #114): the whitelisted apps as a grid or list
/// over the dashboard. Shown and hidden through the manager's [visible]
/// notifier so every surface — the menu, quick actions, MQTT, the remote
/// admin — opens the same overlay.
class AppLauncherOverlay extends StatelessWidget {
  const AppLauncherOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: container.launcher.visible,
    builder: (context, visible, _) {
      if (!visible) return const SizedBox.shrink();
      return Positioned.fill(child: _LauncherPanel(container: container));
    },
  );
}

class _LauncherPanel extends StatelessWidget {
  const _LauncherPanel({required this.container});

  final AppContainer container;

  void _close() => container.launcher.visible.value = false;

  Future<void> _open(BuildContext context, LauncherApp app) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    _close();
    final result = await container.commands.execute('launchApp', {
      'package': app.package,
    });
    // The one visible failure mode is an app uninstalled since it was
    // picked; silence would read as a dead button.
    if (!result.ok) {
      showToastIn(
        overlay,
        title: 'Could not open ${app.label}',
        message: 'It may have been uninstalled.',
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apps = container.launcher.apps;
    final grid = container.settings.get(defs.launcherLayout) == 'grid';
    final icons = container.settings.get(defs.launcherShowIcons);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            // Swallow taps on the panel so only the scrim closes.
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 8, 0),
                      child: Row(
                        children: [
                          Text('Apps', style: theme.textTheme.titleLarge),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _close,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: grid
                          ? GridView.extent(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(16),
                              maxCrossAxisExtent: 112,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              children: [
                                for (final app in apps)
                                  _GridTile(
                                    container: container,
                                    app: app,
                                    icons: icons,
                                    onTap: () => _open(context, app),
                                  ),
                              ],
                            )
                          : ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                              children: [
                                for (final app in apps)
                                  ListTile(
                                    leading: icons
                                        ? _AppIcon(
                                            container: container,
                                            package: app.package,
                                            size: 40,
                                          )
                                        : null,
                                    title: Text(
                                      app.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    onTap: () => _open(context, app),
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
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.container,
    required this.app,
    required this.icons,
    required this.onTap,
  });

  final AppContainer container;
  final LauncherApp app;
  final bool icons;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icons) ...[
            _AppIcon(container: container, package: app.package, size: 52),
            const SizedBox(height: 8),
          ],
          Text(
            app.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

/// One app's icon from the manager's cache, with a generic stand-in while
/// it loads or when the app cannot provide one.
class _AppIcon extends StatelessWidget {
  const _AppIcon({
    required this.container,
    required this.package,
    required this.size,
  });

  final AppContainer container;
  final String package;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: FutureBuilder<Uint8List?>(
      future: container.launcher.icon(package),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Icon(Icons.apps_outlined, size: size * 0.8);
        }
        return Image.memory(bytes, width: size, height: size);
      },
    ),
  );
}
