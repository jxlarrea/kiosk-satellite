import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/events.dart';
import '../core/markup.dart';
import '../managers/notifications/notification_manager.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/settings/settings_manager.dart';
import 'mdi_icon.dart';
import 'theme.dart';

/// Draws the notifications pushed from Home Assistant (see
/// NotificationManager) at the top of the screen, newest on top.
///
/// Deliberately not the app's toast: a toast answers something the user
/// just did here, sits low and small, lets taps through, and there is
/// only ever one. This is the house talking to whoever is in the room -
/// read at a distance, from the top edge, where nothing else of the kiosk
/// lives, and stacked, because the washing machine finishing does not
/// mean the front door opening can be forgotten. Cards read over a photo
/// screensaver (how much shows through them is the Appearance settings')
/// and the whole surface is tappable, so they can be waved away one at a
/// time.
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

  StreamSubscription<SettingChanged>? _appearanceSub;

  @override
  void initState() {
    super.initState();
    _drawn.addAll(widget.notifications.current.value);
    widget.notifications.current.addListener(_onChanged);
    // Cards already up follow the Appearance settings live: the way to
    // tune transparency is a test notification on the tablet and the
    // slider on the remote UI, and a card that only listened on arrival
    // would sit unchanged through the whole adjustment.
    _appearanceSub = widget.notifications.bus.on<SettingChanged>().listen((e) {
      if (e.key != defs.notificationsTransparency.key &&
          e.key != defs.notificationsBlur.key) {
        return;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _appearanceSub?.cancel();
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
      // place, gone or not, so nothing jumps as a card leaves. A card
      // already up takes the manager's newer version of itself, which is
      // how its picture arrives.
      for (final note in live.reversed) {
        final at = _drawn.indexWhere((drawn) => drawn.id == note.id);
        if (at < 0) {
          _drawn.insert(0, note);
          _leaving.remove(note.id);
        } else if (!identical(_drawn[at], note)) {
          _drawn[at] = note;
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

  /// A tap on a card. Ordinarily the manager drops it and the card slides
  /// out; a card the manager has already forgotten (its countdown ended
  /// and, for whatever reason, it is still here) would make that a no-op,
  /// so it comes straight down instead: a card that answers a tap with
  /// nothing is the one thing the overlay must never show.
  void _dismiss(int id) {
    if (_leaving.contains(id)) {
      _gone(id);
      return;
    }
    widget.notifications.dismiss(id: id);
  }

  @override
  Widget build(BuildContext context) {
    if (_drawn.isEmpty) return const SizedBox.shrink();
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Ks.inset, 16, Ks.inset, 0),
            // Scaled cards can outgrow the screen. Letting the column lay
            // out unbounded and clipping what falls off the bottom keeps
            // the newest ones, which are on top, whole; bounding it would
            // be a layout overflow and would squeeze nothing usefully.
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final note in _drawn)
                    _NotificationCard(
                      key: ValueKey(note.id),
                      note: note,
                      settings: widget.notifications.settings,
                      leaving: _leaving.contains(note.id),
                      onDismiss: () => _dismiss(note.id),
                      onGone: () => _gone(note.id),
                    ),
                ],
              ),
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
    required this.settings,
    required this.leaving,
    required this.onDismiss,
    required this.onGone,
  });

  final KioskNotification note;
  final SettingsManager settings;
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
  );

  @override
  void initState() {
    super.initState();
    if (widget.leaving) {
      // Gone before it was ever drawn: it arrived and its countdown ran
      // out with no frame in between, which is what a screen that is off
      // does to a Flutter app (issue #322). didUpdateWidget below never
      // sees the change, so without this the card would come up on the
      // first frame after the wake and stay, with nothing left in the
      // manager to answer a tap. Nobody saw it, so there is nothing to
      // slide out: it leaves as soon as this build is over.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onGone();
      });
      return;
    }
    _controller.forward();
  }

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
    final mdi = widget.note.icon;
    final image = widget.note.image;
    // One multiplier over every measurement on the card, so a scaled
    // notification grows as a whole instead of turning into big text in
    // a small box.
    final scale = widget.note.scale;
    double px(double value) => value * scale;
    // How much of the card still covers the screen (issue #390: a card
    // over a screensaver clock should not blot it out). The fill, the
    // hairline and the shadow fade together; the icon and the words stay
    // solid, because a notification that cannot be read defeats itself.
    final solidity =
        1 -
        widget.settings
            .get(defs.notificationsTransparency)
            .toDouble()
            .clamp(0.0, 1.0);
    final blur = widget.settings
        .get(defs.notificationsBlur)
        .toDouble()
        .clamp(0.0, 1.0);
    return ConstrainedBox(
      // Per card, not per stack: 720 is an ordinary notification's width
      // and a scaled one is wider in proportion, up to the screen. A small
      // card beside a big one must not be stretched to match it.
      constraints: BoxConstraints(maxWidth: px(720)),
      child: SizeTransition(
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
              padding: EdgeInsets.only(bottom: px(12)),
              // A notification lands over arbitrary content - a dashboard,
              // a photo - so it carries a shadow to lift it off same-tone
              // backgrounds. The shadow stays outside the clip below (which
              // would cut it off) and fades with the fill: it shows
              // *through* a translucent card, where at full strength it
              // read as a gray wash over the very thing the transparency
              // was set to reveal.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(px(Ks.radiusCard)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.26 * solidity),
                      blurRadius: px(16),
                      offset: Offset(0, px(4)),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(px(Ks.radiusCard)),
                  child: _surface(
                    scheme: scheme,
                    solidity: solidity,
                    blur: solidity < 1 && blur > 0,
                    // Full slider is a heavy frost read as shapes, not
                    // edges; the low end is a light diffusion.
                    sigma: px(40) * blur,
                    radius: BorderRadius.circular(px(Ks.radiusCard)),
                    child: Material(
                      type: MaterialType.transparency,
                      borderRadius: BorderRadius.circular(px(Ks.radiusCard)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(px(Ks.radiusCard)),
                        // Anywhere on the card dismisses that card: the whole
                        // surface is the target for someone reaching past a
                        // counter, and it is the only way out of a pinned one
                        // (duration 0) short of Home Assistant.
                        onTap: widget.onDismiss,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            px(20),
                            px(18),
                            px(12),
                            px(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: px(52),
                                height: px(52),
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  // A caller's own icon wins over the one the
                                  // kind picks, and falls back to it while the
                                  // path is read or when the name is not an
                                  // icon at all.
                                  child: mdi == null
                                      ? Icon(icon, size: px(30), color: iconFg)
                                      : MdiIcon(
                                          name: mdi,
                                          size: px(30),
                                          color: iconFg,
                                          fallback: icon,
                                        ),
                                ),
                              ),
                              SizedBox(width: px(16)),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (title != null)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: px(4)),
                                        child: Text.rich(
                                          _spans(
                                            widget.note.heading!,
                                            scheme,
                                            // Over an already semibold
                                            // line, bold has to go past it.
                                            bold: FontWeight.w800,
                                          ),
                                          style: TextStyle(
                                            fontFamily: Ks.displayFont,
                                            fontSize: px(24),
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    _body(
                                      widget.note.body,
                                      scheme,
                                      px,
                                      TextStyle(
                                        fontSize: px(20),
                                        height: 1.35,
                                        color: title == null
                                            ? scheme.onSurface
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    // The picture joins after the words, so
                                    // the card grows to it rather than jumping.
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeOut,
                                      alignment: Alignment.topCenter,
                                      child: image == null
                                          ? const SizedBox.shrink()
                                          : Padding(
                                              padding: EdgeInsets.only(
                                                top: px(12),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      px(Ks.radiusControl),
                                                    ),
                                                child: ConstrainedBox(
                                                  // As wide as the text, no
                                                  // taller than this: a
                                                  // portrait frame letterboxes
                                                  // rather than filling the
                                                  // screen.
                                                  constraints: BoxConstraints(
                                                    maxHeight: px(360),
                                                  ),
                                                  child: Image.memory(
                                                    image,
                                                    fit: BoxFit.contain,
                                                    width: double.infinity,
                                                    // Decoded no larger than
                                                    // it is drawn: a 4K
                                                    // snapshot must not cost a
                                                    // low-RAM tablet its
                                                    // dashboard.
                                                    cacheWidth:
                                                        (px(680) *
                                                                MediaQuery.devicePixelRatioOf(
                                                                  context,
                                                                ))
                                                            .round(),
                                                    gaplessPlayback: true,
                                                    errorBuilder: (_, _, _) =>
                                                        const SizedBox.shrink(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: px(8)),
                              IconButton(
                                iconSize: px(26),
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
          ),
        ),
      ),
    );
  }

  /// The message, block by block (issue #439). The common case, one
  /// paragraph, is one Text as before; lists and headings stack under
  /// each other, a bullet or number hanging in a gutter so a wrapped
  /// item keeps its left edge.
  Widget _body(
    List<MarkupBlock> blocks,
    ColorScheme scheme,
    double Function(double) px,
    TextStyle style,
  ) {
    if (blocks.isEmpty) return const SizedBox.shrink();
    if (blocks.length == 1 && blocks.single is MarkupParagraph) {
      return Text.rich(_spans(blocks.single.runs, scheme), style: style);
    }
    final children = <Widget>[];
    MarkupBlock? previous;
    for (final block in blocks) {
      // A paragraph or heading stands off from what came before it; list
      // items sit close together, as a list does.
      final gap = previous == null
          ? 0.0
          : block is MarkupListItem && previous is MarkupListItem
          ? px(2)
          : px(8);
      children.add(
        Padding(
          padding: EdgeInsets.only(top: gap),
          child: switch (block) {
            MarkupHeading() => Text.rich(
              _spans(block.runs, scheme),
              style: style.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            MarkupParagraph() => Text.rich(
              _spans(block.runs, scheme),
              style: style,
            ),
            MarkupListItem() => Padding(
              padding: EdgeInsets.only(left: px(20) * block.depth.clamp(0, 3)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: px(block.number == null ? 22 : 34),
                    child: Text(block.number ?? '\u2022', style: style),
                  ),
                  Expanded(
                    child: Text.rich(_spans(block.runs, scheme), style: style),
                  ),
                ],
              ),
            ),
          },
        ),
      );
      previous = block;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// One line's runs as spans over the Text's own style. Code keeps the
  /// platform's monospace face on a faint tint: the app bundles no such
  /// font, and the system one reads fine at card size.
  TextSpan _spans(
    List<MarkupRun> runs,
    ColorScheme scheme, {
    FontWeight bold = FontWeight.w700,
  }) => TextSpan(
    children: [
      for (final run in runs)
        run.plain
            ? TextSpan(text: run.text)
            : TextSpan(
                text: run.text,
                style: TextStyle(
                  fontWeight: run.bold ? bold : null,
                  fontStyle: run.italic ? FontStyle.italic : null,
                  decoration: run.strike ? TextDecoration.lineThrough : null,
                  fontFamily: run.code ? 'monospace' : null,
                  backgroundColor: run.code
                      ? scheme.onSurface.withValues(alpha: 0.08)
                      : null,
                ),
              ),
    ],
  );

  /// The card's surface: the fill and hairline that the transparency
  /// slider fades, behind everything solid, optionally over a backdrop
  /// blur. The blur layer only exists while it could show something - a
  /// BackdropFilter costs a saveLayer even when the card is opaque.
  Widget _surface({
    required ColorScheme scheme,
    required double solidity,
    required bool blur,
    required double sigma,
    required BorderRadius radius,
    required Widget child,
  }) {
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: solidity),
        borderRadius: radius,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: solidity),
        ),
      ),
      child: child,
    );
    if (!blur) return surface;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: surface,
    );
  }
}
