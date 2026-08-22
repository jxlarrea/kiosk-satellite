import 'package:flutter/material.dart';

import '../managers/notifications/notification_manager.dart';
import 'theme.dart';

/// Draws the notifications pushed from Home Assistant (see
/// NotificationManager) at the top of the screen, newest on top.
///
/// Deliberately not the app's toast: a toast answers something the user
/// just did here, sits low and small, lets taps through, and there is
/// only ever one. This is the house talking to whoever is in the room -
/// read at a distance, from the top edge, where nothing else of the kiosk
/// lives, and stacked, because the washing machine finishing does not
/// mean the front door opening can be forgotten. Cards are opaque and
/// tappable so they read over a photo screensaver and can be waved away
/// one at a time.
class NotificationOverlay extends StatefulWidget {
  const NotificationOverlay({required this.notifications, super.key});

  final NotificationManager notifications;

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  /// What is drawn, which lags the manager by one animation: a card the
  /// manager has already dropped stays here, in its place, until it has
  /// finished sliding out.
  final _drawn = <KioskNotification>[];

  /// Ids on their way out, so a rebuild does not resurrect them.
  final _leaving = <int>{};

  @override
  void initState() {
    super.initState();
    _drawn.addAll(widget.notifications.current.value);
    widget.notifications.current.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.notifications.current.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final live = widget.notifications.current.value;
    final liveIds = {for (final note in live) note.id};
    setState(() {
      for (final note in _drawn) {
        if (!liveIds.contains(note.id)) _leaving.add(note.id);
      }
      // New arrivals go in front; everything already drawn keeps its
      // place, gone or not, so nothing jumps as a card leaves.
      for (final note in live.reversed) {
        if (_drawn.every((drawn) => drawn.id != note.id)) {
          _drawn.insert(0, note);
          _leaving.remove(note.id);
        }
      }
    });
  }

  void _gone(int id) {
    if (!mounted) return;
    setState(() {
      _drawn.removeWhere((note) => note.id == id);
      _leaving.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_drawn.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Ks.inset, 16, Ks.inset, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final note in _drawn)
                  _NotificationCard(
                    key: ValueKey(note.id),
                    note: note,
                    leaving: _leaving.contains(note.id),
                    onDismiss: () =>
                        widget.notifications.dismiss(id: note.id),
                    onGone: () => _gone(note.id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  const _NotificationCard({
    super.key,
    required this.note,
    required this.leaving,
    required this.onDismiss,
    required this.onGone,
  });

  final KioskNotification note;
  final bool leaving;
  final VoidCallback onDismiss;
  final VoidCallback onGone;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  )..forward();

  @override
  void didUpdateWidget(_NotificationCard old) {
    super.didUpdateWidget(old);
    // The card animates itself out and only then leaves the tree, so the
    // cards below it slide up instead of snapping.
    if (widget.leaving && !old.leaving) {
      _controller.reverse().whenComplete(widget.onGone);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, iconBg, iconFg) = switch (widget.note.level) {
      NotificationLevel.info => (
        Icons.info_outline,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      NotificationLevel.success => (
        Icons.check_rounded,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      NotificationLevel.warning => (
        Icons.warning_amber_rounded,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      NotificationLevel.error => (
        Icons.error_outline,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
    final title = widget.note.title;
    return SizeTransition(
      sizeFactor: curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.35),
            end: Offset.zero,
          ).animate(curve),
          child: Padding(
            // Between cards only: the stack's own top edge is the
            // overlay's padding.
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(Ks.radiusCard),
                border: Border.all(color: scheme.outlineVariant),
                // A notification lands over arbitrary content - a
                // dashboard, a photo - so it carries a shadow to lift it
                // off same-tone backgrounds.
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(Ks.radiusCard),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Ks.radiusCard),
                  // Anywhere on the card dismisses that card: the whole
                  // surface is the target for someone reaching past a
                  // counter, and it is the only way out of a pinned one
                  // (duration 0) short of Home Assistant.
                  onTap: widget.onDismiss,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 30, color: iconFg),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontFamily: Ks.displayFont,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              Text(
                                widget.note.message,
                                style: TextStyle(
                                  fontSize: 20,
                                  height: 1.35,
                                  color: title == null
                                      ? scheme.onSurface
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          iconSize: 26,
                          color: scheme.onSurfaceVariant,
                          onPressed: widget.onDismiss,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
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
