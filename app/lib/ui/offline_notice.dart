import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import 'theme.dart';

/// What the kiosk shows instead of Chromium's error page.
///
/// A main-frame load that fails leaves WebView's built-in error page on the
/// panel: a dark slab with a fallen Android robot and a net:: error string.
/// On a wall tablet that reads as a broken app, which is what sent the owner
/// restarting Kiosk Satellite when the real fault was an hour-old wifi drop.
/// This covers it with the app's own surface, says which of the two it is,
/// and offers the one action worth offering.
///
/// It only covers a failed load — a dashboard that is merely stale (the page
/// still there, the network gone) keeps showing; the toast reports that.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({required this.container, super.key});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: container.browser.loadFailed,
      builder: (context, failed, _) {
        if (!failed) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: container.device.networkUp,
          builder: (context, online, _) => _Card(
            online: online,
            detail: container.browser.lastErrorDescription,
            onRetry: () => container.browser.retryLoad(),
          ),
        );
      },
    );
  }
}

/// The outage toast: a pill over the bottom of the dashboard saying the
/// network is gone, for as long as it is gone.
///
/// Not a snackbar. ScaffoldMessenger shows one at a time and queues the
/// rest, so a notice that has to last all night would swallow every
/// download, update and launcher message behind it — and a kiosk's other
/// overlays could not be layered above it. This is an ordinary widget in
/// the kiosk's own stack, so the screensaver, the camera view and the
/// player cover it exactly as they cover everything else, and it never
/// takes a touch away from the page underneath.
class NetworkToast extends StatefulWidget {
  const NetworkToast({required this.container, super.key});

  final AppContainer container;

  @override
  State<NetworkToast> createState() => _NetworkToastState();
}

class _NetworkToastState extends State<NetworkToast> {
  bool _visible = false;
  bool _wasOffline = false;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    widget.container.device.networkUp.addListener(_onNetworkChanged);
    // An app that started during the outage was never told about it: the
    // state was already false before anything was listening.
    _wasOffline = !widget.container.device.networkUp.value;
    _visible = _wasOffline;
  }

  @override
  void dispose() {
    _hide?.cancel();
    widget.container.device.networkUp.removeListener(_onNetworkChanged);
    super.dispose();
  }

  void _onNetworkChanged() {
    if (!mounted) return;
    final up = widget.container.device.networkUp.value;
    _hide?.cancel();
    if (!up) {
      setState(() {
        _wasOffline = true;
        _visible = true;
      });
      return;
    }
    // Coming back is worth one line, but only to someone who was told it
    // had gone: an ordinary start on a healthy network announces nothing.
    if (!_wasOffline) return;
    setState(() => _visible = true);
    _hide = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _visible = false;
        _wasOffline = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final offline = !widget.container.device.networkUp.value;
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 1.6),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Padding(
              padding: const EdgeInsets.all(Ks.inset),
              child: Material(
                color: colors.inverseSurface,
                elevation: 6,
                borderRadius: BorderRadius.circular(Ks.radiusControl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        offline ? Icons.wifi_off : Icons.wifi,
                        size: 18,
                        color: colors.onInverseSurface,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        offline
                            ? 'Network connection lost'
                            : 'Network connection restored',
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.onInverseSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.online,
    required this.detail,
    required this.onRetry,
  });

  /// Whether the device has a network at all. The same failed load means
  /// two different things to whoever walks up: fix the wifi, or look at the
  /// server.
  final bool online;

  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: Center(
        child: Padding(
          padding: Ks.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                online ? Icons.cloud_off : Icons.wifi_off,
                size: 56,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              Text(
                online ? 'Dashboard unavailable' : 'No network connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Ks.displayFont,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                online
                    ? 'The page could not be loaded.'
                    : 'The dashboard will come back when the network does.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
              ),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.outline),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
