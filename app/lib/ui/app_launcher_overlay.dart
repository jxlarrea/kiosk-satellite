import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/launcher/app_launcher_manager.dart';
import 'theme.dart';
import 'toast.dart';

/// The app launcher (issue #114): the whitelisted apps as a full-screen
/// wall of tiles over the dashboard, the Meta Portal launcher's look. Each
/// app sits on a rounded surface washed with a soft diagonal gradient
/// pulled from its own icon's dominant color, the icon large and centered
/// on it, the label beneath; the set is centered on a ground that follows
/// the app's light or dark theme. Shown and hidden through the manager's
/// [visible] notifier so every surface — the menu, quick actions, the
/// remote admin, an automation — opens the same overlay.
class AppLauncherOverlay extends StatelessWidget {
  const AppLauncherOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: container.launcher.visible,
    builder: (context, visible, _) {
      if (!visible) return const SizedBox.shrink();
      return Positioned.fill(child: _LauncherScreen(container: container));
    },
  );
}

class _LauncherScreen extends StatelessWidget {
  const _LauncherScreen({required this.container});

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
    return GestureDetector(
      // The empty ground dismisses, same as the old modal's scrim; the
      // tiles swallow their own taps.
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _groundGradient(
            theme.colorScheme.surface,
            theme.brightness,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Centered both ways while the wall fits, an ordinary
              // vertical scroll once it does not.
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 56,
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 32,
                            runSpacing: 36,
                            children: [
                              for (var i = 0; i < apps.length; i++)
                                _AppTile(
                                  container: container,
                                  app: apps[i],
                                  // Dpad and keyboard land somewhere useful
                                  // the moment the wall opens (issue #377).
                                  autofocus: i == 0,
                                  onTap: () => _open(context, apps[i]),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 28,
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: _close,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One app on the wall: the gradient tile, the icon, the label.
class _AppTile extends StatefulWidget {
  const _AppTile({
    required this.container,
    required this.app,
    required this.autofocus,
    required this.onTap,
  });

  final AppContainer container;
  final LauncherApp app;
  final bool autofocus;
  final VoidCallback onTap;

  static const double side = 150;
  static const double iconSize = 88;

  @override
  State<_AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<_AppTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final launcher = widget.container.launcher;
    final package = widget.app.package;
    // The synchronous path: with the icon warmed by the manager and its
    // color already extracted, the tile paints its final face on the very
    // first frame. The async path exists only for the first-ever open on
    // a cold cache, and it holds a neutral surface rather than flashing a
    // wrong color and correcting itself.
    final iconReady = launcher.hasIcon(package);
    final bytes = iconReady ? launcher.cachedIcon(package) : null;
    final colorReady =
        iconReady && (bytes == null || _dominantCache.containsKey(package));
    Widget tile;
    if (colorReady) {
      tile = _body(theme, loading: false, bytes: bytes);
    } else {
      tile = FutureBuilder<(Uint8List?, Color?)>(
        future: _tileData(widget.container, package),
        builder: (context, snapshot) =>
            _body(theme, loading: !snapshot.hasData, bytes: snapshot.data?.$1),
      );
    }
    return SizedBox(
      width: _AppTile.side,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile,
          const SizedBox(height: 12),
          Text(
            widget.app.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme, {required bool loading, Uint8List? bytes}) {
    final scheme = theme.colorScheme;
    final tint = bytes == null ? null : _dominantCache[widget.app.package];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: _AppTile.side,
      height: _AppTile.side,
      decoration: BoxDecoration(
        // Loading holds a quiet neutral; the gradient arrives with the
        // icon in the same build, one soft cut instead of a color flash.
        gradient: loading
            ? null
            : _tileGradient(
                // Icon-less apps keep the brand's sage so the tile still
                // reads as a surface, not a hole.
                tint ?? scheme.primary,
                theme.brightness,
              ),
        color: loading ? scheme.surfaceContainerHighest : null,
        borderRadius: BorderRadius.circular(Ks.radiusCard),
        // The dpad's whereabouts: a firm ring, readable over any
        // gradient the icons produce.
        border: Border.all(
          color: _focused ? scheme.onSurface : Colors.transparent,
          width: 3,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(Ks.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          onFocusChange: (f) => setState(() => _focused = f),
          child: Center(
            child: loading
                ? const SizedBox.shrink()
                : bytes == null
                ? Icon(
                    Icons.apps_outlined,
                    size: _AppTile.iconSize,
                    color: Colors.white.withValues(alpha: 0.9),
                  )
                : Image.memory(
                    bytes,
                    width: _AppTile.iconSize,
                    height: _AppTile.iconSize,
                    gaplessPlayback: true,
                  ),
          ),
        ),
      ),
    );
  }
}

/// The icon bytes and the dominant color in one await, so a tile paints
/// its final face in a single build once both are cached.
Future<(Uint8List?, Color?)> _tileData(
  AppContainer container,
  String package,
) async {
  final bytes = await container.launcher.icon(package);
  if (bytes == null) return (null, null);
  return (bytes, await _dominantColor(package, bytes));
}

/// Dominant colors per package. Icons are immutable for the app's life
/// (the manager caches the bytes the same way) and the set is bounded by
/// the whitelist, so nothing here is ever evicted.
final _dominantCache = <String, Color?>{};

/// The color the tile's gradient is built from: the most present clearly
/// saturated color in the icon, found on a tiny decode. Saturation is
/// weighted over raw count so a colorful glyph beats its white or gray
/// backdrop, but never zeroed, so a genuinely monochrome icon still
/// yields its own tone rather than nothing.
Future<Color?> _dominantColor(String package, Uint8List bytes) async {
  if (_dominantCache.containsKey(package)) return _dominantCache[package];
  Color? result;
  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 24,
      targetHeight: 24,
    );
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data != null) {
      // Cluster the clearly colored pixels by hue (30-degree buckets) and
      // let the largest single hue win, averaged over its own pixels
      // only. Averaging across hues is what a multicolored icon (Chrome)
      // must never get: red plus green plus blue is mud. Gray pixels are
      // kept aside as the fallback for genuinely monochrome icons.
      const buckets = 12;
      final count = List<int>.filled(buckets, 0);
      final sum = List.generate(buckets, (_) => [0, 0, 0]);
      var grayCount = 0;
      final graySum = [0, 0, 0];
      for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
        final a = data.getUint8(i + 3);
        if (a < 200) continue;
        final r = data.getUint8(i);
        final g = data.getUint8(i + 1);
        final b = data.getUint8(i + 2);
        final hsv = HSVColor.fromColor(Color.fromARGB(255, r, g, b));
        if (hsv.saturation >= 0.28 && hsv.value >= 0.15) {
          final k = (hsv.hue ~/ (360 / buckets)) % buckets;
          count[k]++;
          sum[k]
            ..[0] += r
            ..[1] += g
            ..[2] += b;
        } else {
          grayCount++;
          graySum
            ..[0] += r
            ..[1] += g
            ..[2] += b;
        }
      }
      var best = 0;
      for (var k = 1; k < buckets; k++) {
        if (count[k] > count[best]) best = k;
      }
      // A hue needs to be more than a stray anti-aliased edge to speak
      // for the icon; below that the icon is effectively monochrome.
      final total = count.fold(0, (a, b) => a + b) + grayCount;
      if (total > 0 && count[best] >= total * 0.04) {
        result = Color.fromARGB(
          255,
          sum[best][0] ~/ count[best],
          sum[best][1] ~/ count[best],
          sum[best][2] ~/ count[best],
        );
      } else if (grayCount > 0) {
        result = Color.fromARGB(
          255,
          graySum[0] ~/ grayCount,
          graySum[1] ~/ grayCount,
          graySum[2] ~/ grayCount,
        );
      }
    }
  } catch (_) {
    // A broken icon just falls back to the brand tint.
  }
  _dominantCache[package] = result;
  return result;
}

/// The Portal look: one soft diagonal wash of the app's own color, deep
/// on the dark theme and only a shade lifted on the light one — a rich
/// surface either way, never a pastel (which also let dark edges baked
/// into some icons show through). Saturation is floored so near-gray
/// icons still produce a visible surface, and capped so neon glyphs do
/// not glow.
LinearGradient _tileGradient(Color tint, Brightness brightness) {
  final hsl = HSLColor.fromColor(tint);
  final sat = hsl.saturation.clamp(0.22, 0.68);
  final dark = brightness == Brightness.dark;
  HSLColor tone(double lightness) =>
      hsl.withSaturation(sat).withLightness(lightness);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: dark
        ? [tone(0.42).toColor(), tone(0.24).toColor()]
        : [tone(0.56).toColor(), tone(0.38).toColor()],
  );
}

/// The wall's ground: the theme surface as a quiet vertical gradient, a
/// touch of depth instead of a flat sheet, in both themes.
LinearGradient _groundGradient(Color surface, Brightness brightness) {
  final hsl = HSLColor.fromColor(surface);
  final dark = brightness == Brightness.dark;
  HSLColor tone(double delta) =>
      hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0));
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: dark
        ? [tone(0.05).toColor(), tone(-0.02).toColor()]
        : [tone(0.03).toColor(), tone(-0.06).toColor()],
  );
}
