import 'dart:async';

import 'package:flutter/material.dart';

import 'theme.dart';

/// The app's own toast: a compact themed card floated over the root overlay,
/// replacing the stock SnackBar everywhere. One toast at a time — showing a
/// new one swaps the old out. A toast without an action ignores pointers so
/// dashboard taps pass straight through it.

enum ToastKind { info, success, warning, error }

OverlayEntry? _entry;
Timer? _timer;
GlobalKey<_ToastCardState>? _cardKey;

/// Shows a toast in the root overlay above [context]. [sticky] keeps it up
/// until [dismissToast] or the next toast replaces it.
void showToast(
  BuildContext context, {
  required String title,
  String? message,
  ToastKind kind = ToastKind.info,
  Duration duration = const Duration(seconds: 4),
  bool sticky = false,
  String? actionLabel,
  VoidCallback? onAction,
}) => showToastIn(
  Overlay.of(context, rootOverlay: true),
  title: title,
  message: message,
  kind: kind,
  duration: duration,
  sticky: sticky,
  actionLabel: actionLabel,
  onAction: onAction,
);

/// [showToast] against a pre-captured [OverlayState], for callers that tear
/// down their own subtree before the toast fires.
void showToastIn(
  OverlayState overlay, {
  required String title,
  String? message,
  ToastKind kind = ToastKind.info,
  Duration duration = const Duration(seconds: 4),
  bool sticky = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  _timer?.cancel();
  _timer = null;
  _removeNow();
  final key = _cardKey = GlobalKey<_ToastCardState>();
  final entry = _entry = OverlayEntry(
    builder: (context) => _ToastCard(
      key: key,
      title: title,
      message: message,
      kind: kind,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
  overlay.insert(entry);
  if (!sticky) _timer = Timer(duration, dismissToast);
}

/// Animates the current toast out, if one is up.
void dismissToast() {
  _timer?.cancel();
  _timer = null;
  final state = _cardKey?.currentState;
  if (state == null) {
    _removeNow();
    return;
  }
  final entry = _entry;
  _entry = null;
  _cardKey = null;
  state.hide().whenComplete(entry!.remove);
}

void _removeNow() {
  _entry?.remove();
  _entry = null;
  _cardKey = null;
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    super.key,
    required this.title,
    this.message,
    required this.kind,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final ToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..forward();

  Future<void> hide() => _controller.reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, iconBg, iconFg) = switch (widget.kind) {
      ToastKind.info => (
        Icons.info_outline,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      ToastKind.success => (
        Icons.check_rounded,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      ToastKind.warning => (
        Icons.warning_amber_rounded,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      ToastKind.error => (
        Icons.error_outline,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    final message = widget.message;
    final actionLabel = widget.actionLabel;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: IgnorePointer(
          ignoring: actionLabel == null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Ks.inset, 0, Ks.inset, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position:
                      Tween(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: DecoratedBox(
                    // A toast floats over arbitrary dashboard content, so
                    // unlike the app's flat cards it carries a soft shadow
                    // beside the hairline to separate from same-tone pages.
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(Ks.radiusCard),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    // The entry sits outside any Scaffold, so the Material
                    // supplies the text style (and ink for the action).
                    child: Material(
                      type: MaterialType.transparency,
                      borderRadius: BorderRadius.circular(Ks.radiusCard),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 11, 18, 11),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: iconBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 19, color: iconFg),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  if (message != null && message.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        message,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          height: 1.35,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (actionLabel != null) ...[
                              const SizedBox(width: 10),
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                onPressed: () {
                                  dismissToast();
                                  widget.onAction?.call();
                                },
                                child: Text(actionLabel),
                              ),
                            ],
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
    );
  }
}
