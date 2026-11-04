import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../managers/plugins/plugin_manager.dart';
import '../l10n/messages.dart';
import 'theme.dart';
import 'ui_scale.dart' show UiScaleExempt, UiScaleScope;

/// Plugin overlays and floating windows stay below the kiosk drawer and
/// ambient overlays. Windows sit over the native overlays.
class PluginOverlay extends StatelessWidget {
  const PluginOverlay({super.key, required this.plugins, this.hybrid = false});
  final PluginManager plugins;

  /// Hosts the native overlays with hybrid composition (issue #1294).
  final bool hybrid;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      PluginNativeOverlays(plugins: plugins, hybrid: hybrid),
      ValueListenableBuilder<List<PluginWindow>>(
        valueListenable: plugins.windows,
        builder: (context, windows, _) => LayoutBuilder(
          builder: (context, bounds) => Stack(
            children: [
              for (var i = 0; i < windows.length; i++)
                _FloatingWindow(
                  key: ValueKey(windows[i].id),
                  window: windows[i],
                  plugins: plugins,
                  available: bounds.biggest,
                  index: i,
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// The theme native overlays draw with: the Material 3 color roles plus
/// success, as ARGB, and whether it is dark.
Map<String, Object?> pluginOverlayTheme(ThemeData theme) {
  final scheme = theme.colorScheme;
  final dark = theme.brightness == Brightness.dark;
  return {
    'dark': dark,
    'colors': {
      'primary': scheme.primary.toARGB32(),
      'onPrimary': scheme.onPrimary.toARGB32(),
      'primaryContainer': scheme.primaryContainer.toARGB32(),
      'onPrimaryContainer': scheme.onPrimaryContainer.toARGB32(),
      'secondary': scheme.secondary.toARGB32(),
      'onSecondary': scheme.onSecondary.toARGB32(),
      'secondaryContainer': scheme.secondaryContainer.toARGB32(),
      'onSecondaryContainer': scheme.onSecondaryContainer.toARGB32(),
      'tertiary': scheme.tertiary.toARGB32(),
      'onTertiary': scheme.onTertiary.toARGB32(),
      'tertiaryContainer': scheme.tertiaryContainer.toARGB32(),
      'onTertiaryContainer': scheme.onTertiaryContainer.toARGB32(),
      'error': scheme.error.toARGB32(),
      'onError': scheme.onError.toARGB32(),
      'errorContainer': scheme.errorContainer.toARGB32(),
      'onErrorContainer': scheme.onErrorContainer.toARGB32(),
      'surface': scheme.surface.toARGB32(),
      'onSurface': scheme.onSurface.toARGB32(),
      'onSurfaceVariant': scheme.onSurfaceVariant.toARGB32(),
      'surfaceContainerLowest': scheme.surfaceContainerLowest.toARGB32(),
      'surfaceContainerLow': scheme.surfaceContainerLow.toARGB32(),
      'surfaceContainer': scheme.surfaceContainer.toARGB32(),
      'surfaceContainerHigh': scheme.surfaceContainerHigh.toARGB32(),
      'surfaceContainerHighest': scheme.surfaceContainerHighest.toARGB32(),
      'inverseSurface': scheme.inverseSurface.toARGB32(),
      'onInverseSurface': scheme.onInverseSurface.toARGB32(),
      'inversePrimary': scheme.inversePrimary.toARGB32(),
      'outline': scheme.outline.toARGB32(),
      'outlineVariant': scheme.outlineVariant.toARGB32(),
      'shadow': scheme.shadow.toARGB32(),
      'scrim': scheme.scrim.toARGB32(),
      'success': (dark ? ksSage : ksSageOnLight).toARGB32(),
    },
  };
}

/// Native plugin overlays, bottom to top. The kiosk has two of these
/// layers: one in the kiosk plane under the menu and the screensaver, and
/// one in the voice overlay's slot for overlays that asked to be on top.
///
/// An overlay that leaves with an exit transition stays in its place until
/// the transition ends, with its view alive, so a hidden, replaced or
/// closed overlay can fade or slide away.
class PluginNativeOverlays extends StatefulWidget {
  const PluginNativeOverlays({
    super.key,
    required this.plugins,
    this.onTop = false,
    this.hybrid = false,
  });
  final PluginManager plugins;
  final bool onTop;

  /// Places each overlay's view in the Android view tree (hybrid
  /// composition) instead of drawing it into a texture. On Android 10 and
  /// up that texture is an ImageReader drained on the main thread, which
  /// a slow GPU can fill while the plugin animates, freezing the app
  /// (issue #1294). Off by default, set by render.hybrid_plugin_overlays.
  final bool hybrid;

  static const viewType = 'kiosk_satellite/plugin_overlay';

  @override
  State<PluginNativeOverlays> createState() => _PluginNativeOverlaysState();
}

class _PluginNativeOverlaysState extends State<PluginNativeOverlays> {
  /// What this layer draws, in stacking order: the live overlays and the
  /// ones playing their exit.
  var _shown = <PluginNativeOverlay>[];
  final _leaving = <String>{};
  late int _epoch = widget.plugins.overlayEpoch.value;

  @override
  void initState() {
    super.initState();
    _sync();
    widget.plugins.overlays.addListener(_changed);
    widget.plugins.overlayEpoch.addListener(_changed);
  }

  @override
  void dispose() {
    widget.plugins.overlays.removeListener(_changed);
    widget.plugins.overlayEpoch.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(_sync);

  void _sync() {
    final live = {
      for (final o in widget.plugins.overlays.value)
        if (o.onTop == widget.onTop) o.id: o,
    };
    // A re-created Activity re-keys every view, so nothing can stay to
    // play its exit.
    if (widget.plugins.overlayEpoch.value != _epoch) {
      _epoch = widget.plugins.overlayEpoch.value;
      _leaving.clear();
      _shown = live.values.toList();
      return;
    }
    final next = <PluginNativeOverlay>[];
    for (final overlay in _shown) {
      final current = live.remove(overlay.id);
      if (current != null) {
        next.add(current);
      } else if (_leaving.contains(overlay.id) ||
          (overlay.exit != 'none' &&
              widget.plugins.overlaySessionLive(overlay))) {
        _leaving.add(overlay.id);
        next.add(overlay);
      }
    }
    _shown = [...next, ...live.values];
  }

  void _left(String id) {
    if (!mounted) return;
    setState(() {
      _leaving.remove(id);
      _shown = _shown.where((o) => o.id != id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_shown.isEmpty) return const SizedBox.shrink();
    final theme = widget.plugins.overlayTheme(
      pluginOverlayTheme(Theme.of(context)),
    );
    // A scaled platform view would be stretched and blurred, so this layer
    // is exempt and each overlay applies the Scale UI factor itself.
    return UiScaleExempt(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final overlay in _shown) ...[
            // Under the overlay, so its own touches still reach it.
            if (overlay.closeOnOutsideTouch && !_leaving.contains(overlay.id))
              _OutsideTouch(
                key: ValueKey('outside:${overlay.id}@$_epoch'),
                passThrough: overlay.passOutsideTouch,
                onTouch: () => unawaited(widget.plugins.closeOverlay(overlay)),
              ),
            _NativeOverlay(
              key: ValueKey('${overlay.id}@$_epoch'),
              overlay: overlay,
              theme: theme,
              leaving: _leaving.contains(overlay.id),
              hybrid: widget.hybrid,
              onLeft: () => _left(overlay.id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Catches a touch anywhere outside one overlay and closes it. Opaque, so
/// the touch only closes, unless the plugin asked to pass it through to
/// what is under it.
class _OutsideTouch extends StatelessWidget {
  const _OutsideTouch({
    super.key,
    required this.passThrough,
    required this.onTouch,
  });
  final bool passThrough;
  final VoidCallback onTouch;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: passThrough
        ? HitTestBehavior.translucent
        : HitTestBehavior.opaque,
    onPointerDown: (_) => onTouch(),
    child: const SizedBox.expand(),
  );
}

class _NativeOverlay extends StatefulWidget {
  const _NativeOverlay({
    super.key,
    required this.overlay,
    required this.theme,
    required this.leaving,
    required this.hybrid,
    required this.onLeft,
  });
  final PluginNativeOverlay overlay;
  final Map<String, Object?> theme;
  final bool hybrid;

  /// Playing its exit transition. It no longer takes touches.
  final bool leaving;
  final VoidCallback onLeft;

  static Alignment alignment(String anchor) => switch (anchor) {
    'top-left' => Alignment.topLeft,
    'top' => Alignment.topCenter,
    'top-right' => Alignment.topRight,
    'left' => Alignment.centerLeft,
    'right' => Alignment.centerRight,
    'bottom-left' => Alignment.bottomLeft,
    'bottom' => Alignment.bottomCenter,
    'bottom-right' => Alignment.bottomRight,
    _ => Alignment.center,
  };

  /// Where a slide comes from, as a fraction of the overlay's own size:
  /// the edge it is anchored to. A centered overlay rises a little.
  static Offset slideFrom(String anchor) => switch (anchor) {
    'top-left' || 'top' || 'top-right' => const Offset(0, -1),
    'bottom-left' || 'bottom' || 'bottom-right' => const Offset(0, 1),
    'left' => const Offset(-1, 0),
    'right' => const Offset(1, 0),
    _ => const Offset(0, 0.12),
  };

  @override
  State<_NativeOverlay> createState() => _NativeOverlayState();
}

class _NativeOverlayState extends State<_NativeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: widget.overlay.duration,
    value: widget.overlay.enter == 'none' ? 1 : 0,
  );
  late final Animation<double> _eased = CurvedAnimation(
    parent: _motion,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  bool _entered = false;

  PluginNativeOverlay get overlay => widget.overlay;

  // Until Android has measured a wrapped view it is laid out at one pixel
  // and kept invisible, so it never flashes at the wrong size.
  bool get _ready => !overlay.wraps || overlay.measured != null;

  @override
  void initState() {
    super.initState();
    _enter();
  }

  @override
  void didUpdateWidget(covariant _NativeOverlay old) {
    super.didUpdateWidget(old);
    if (widget.leaving && !old.leaving) {
      _motion.duration = overlay.duration;
      _motion.reverse().whenCompleteOrCancel(widget.onLeft);
    } else if (!widget.leaving) {
      _enter();
    }
  }

  /// The enter transition starts once the view has its size.
  void _enter() {
    if (_entered || !_ready) return;
    _entered = true;
    if (overlay.enter != 'none') _motion.forward();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  /// The lowest opacity the overlay is painted at. Hybrid composition
  /// only puts a view in the Android view tree once Flutter paints it, and
  /// a view that is not there is never measured, so a wrapped overlay
  /// would wait for its size forever. One step of alpha paints it and
  /// still shows nothing.
  double get _hidden => widget.hybrid ? 1 / 255 : 0;

  Widget _transition(Widget child) => AnimatedBuilder(
    animation: _eased,
    child: child,
    builder: (context, child) {
      final t = math.max(_eased.value, _hidden);
      final kind = widget.leaving ? overlay.exit : overlay.enter;
      return switch (kind) {
        'fade' => Opacity(opacity: t, child: child),
        'slide' => FractionalTranslation(
          translation: _NativeOverlay.slideFrom(overlay.anchor) * (1 - t),
          child: Opacity(opacity: t, child: child),
        ),
        'scale' => Transform.scale(
          scale: 0.92 + 0.08 * t,
          child: Opacity(opacity: t, child: child),
        ),
        _ => child!,
      };
    },
  );

  // Every touch inside the overlay is the plugin's, even a drag the
  // kiosk's own detectors would otherwise win.
  static final _recognizers = <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  Widget _view({required Key key, required Map<String, Object?> params}) {
    if (!widget.hybrid) {
      return AndroidView(
        key: key,
        viewType: PluginNativeOverlays.viewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: _recognizers,
      );
    }
    return PlatformViewLink(
      key: key,
      viewType: PluginNativeOverlays.viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: _recognizers,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (link) =>
          PlatformViewsService.initExpensiveAndroidView(
              id: link.id,
              viewType: link.viewType,
              layoutDirection:
                  Directionality.maybeOf(context) ?? TextDirection.ltr,
              creationParams: params,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () => link.onFocusChanged(true),
            )
            ..addOnPlatformViewCreatedListener(link.onPlatformViewCreated)
            ..create(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Plugins follow the Scale UI factor like the rest of the kiosk. The
    // plugin's view gets a density that includes it, so every dp the
    // plugin passes is scaled here to match. This layer is exempt, so its
    // logical pixels and its pixel ratio are the unscaled ones.
    final scale = UiScaleScope.of(context);
    final ratio = MediaQuery.devicePixelRatioOf(context) / scale;
    return Padding(
      padding: overlay.insets * scale,
      child: LayoutBuilder(
        builder: (context, bounds) {
          double side(int value, double? measured, double available) =>
              math.max(1, switch (value) {
                PluginNativeOverlay.fill => available,
                PluginNativeOverlay.wrap =>
                  measured == null ? 1 : math.min(measured / ratio, available),
                _ => math.min(value * scale, available),
              });
          return CustomSingleChildLayout(
            delegate: _Placed(
              _NativeOverlay.alignment(overlay.anchor),
              overlay.offset * scale,
            ),
            child: SizedBox(
              width: side(
                overlay.width,
                overlay.measured?.width,
                bounds.maxWidth,
              ),
              height: side(
                overlay.height,
                overlay.measured?.height,
                bounds.maxHeight,
              ),
              child: _transition(
                Opacity(
                  opacity: _ready ? 1 : _hidden,
                  // A visual-only overlay lets every touch through, and a
                  // leaving one takes none.
                  child: IgnorePointer(
                    ignoring: !_ready || !overlay.touchable || widget.leaving,
                    child: _view(
                      // The density is fixed when the view is built, so a
                      // new Scale UI factor builds it again.
                      key: ValueKey(scale),
                      params: {
                        'id': overlay.pluginId,
                        'session': overlay.session,
                        'key': overlay.key,
                        'generation': overlay.generation,
                        'width': overlay.width,
                        'height': overlay.height,
                        'insets': [
                          overlay.insets.left.round(),
                          overlay.insets.top.round(),
                          overlay.insets.right.round(),
                          overlay.insets.bottom.round(),
                        ],
                        'scale': scale,
                        'theme': widget.theme,
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Places an overlay at its anchor, moved by its offset and kept inside
/// the area its insets leave.
class _Placed extends SingleChildLayoutDelegate {
  const _Placed(this.alignment, this.offset);
  final Alignment alignment;
  final Offset offset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    final at =
        alignment.alongOffset(
          Offset(size.width - child.width, size.height - child.height),
        ) +
        offset;
    return Offset(
      at.dx.clamp(0, math.max(0, size.width - child.width)),
      at.dy.clamp(0, math.max(0, size.height - child.height)),
    );
  }

  @override
  bool shouldRelayout(_Placed old) =>
      old.alignment != alignment || old.offset != offset;
}

class _FloatingWindow extends StatefulWidget {
  const _FloatingWindow({
    super.key,
    required this.window,
    required this.plugins,
    required this.available,
    required this.index,
  });
  final PluginWindow window;
  final PluginManager plugins;
  final Size available;
  final int index;

  @override
  State<_FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<_FloatingWindow> {
  Offset? _position;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final window = widget.window;
    final width = math.min(360.0, math.max(0.0, widget.available.width - 24));
    final height = math.min(260.0, math.max(0.0, widget.available.height - 24));
    final wanted =
        _position ??
        Offset(
          widget.available.width - width - 20 - widget.index * 24,
          24 + widget.index * 24,
        );
    final position = Offset(
      wanted.dx.clamp(
        12.0,
        math.max(12.0, widget.available.width - width - 12),
      ),
      wanted.dy.clamp(
        12.0,
        math.max(12.0, widget.available.height - height - 12),
      ),
    );
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: width,
      height: height,
      child: Material(
        elevation: 12,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) =>
                  setState(() => _position = position + details.delta),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.drag_indicator, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        window.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n(context).pluginCloseWindow(window.title),
                      icon: const Icon(Icons.close),
                      onPressed: () => unawaited(
                        widget.plugins.windowEvent(window.id, closed: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(window.message),
                ),
              ),
            ),
            if (window.buttonLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            await widget.plugins.windowEvent(
                              window.id,
                              closed: false,
                            );
                            if (mounted) setState(() => _busy = false);
                          },
                    child: Text(
                      window.buttonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
