import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../managers/plugins/plugin_manager.dart';

/// Floating plugin windows stay below the kiosk drawer and ambient overlays.
class PluginOverlay extends StatelessWidget {
  const PluginOverlay({super.key, required this.plugins});
  final PluginManager plugins;

  @override
  Widget build(BuildContext context) =>
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
      );
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
                      tooltip: 'Close ${window.title}',
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
