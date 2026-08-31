import 'package:flutter/widgets.dart';

/// Scales the app's own chrome (menu, settings, dialogs, overlays) by the
/// Scale UI setting, without touching the WebViews (see [UiScaleExempt]).
///
/// The mechanics: the subtree is laid out against a window shrunk or grown
/// by the factor (MediaQuery's size and insets are divided by it) and the
/// result is painted back onto the real window by a [FittedBox]. Every
/// absolute logical size in the chrome lands on screen multiplied by the
/// factor, while anything computed as size times devicePixelRatio (image
/// cache widths, the kiosk plane's one-physical-pixel overdraw) stays
/// physically correct, because devicePixelRatio is multiplied by the same
/// factor the size was divided by.
///
/// FittedBox, not Transform + OverflowBox: hit testing bounds-checks every
/// RenderBox against its own size, and a transform sitting between two
/// differently sized boxes leaves one of them too small for the mapped
/// pointer position, culling touches near the screen edges. FittedBox owns
/// the transform and the slot size together, so its hit test maps the full
/// slot onto the full child at any factor.
class UiScaler extends StatelessWidget {
  const UiScaler({super.key, required this.scale, required this.child});

  /// 1.0 is exactly today's layout; 1.5 paints the chrome half again as big.
  final double scale;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = Size(mq.size.width / scale, mq.size.height / scale);
    return UiScaleScope(
      scale: scale,
      child: MediaQuery(
        data: mq.copyWith(
          size: size,
          devicePixelRatio: mq.devicePixelRatio * scale,
          padding: mq.padding / scale,
          viewPadding: mq.viewPadding / scale,
          viewInsets: mq.viewInsets / scale,
          systemGestureInsets: mq.systemGestureInsets / scale,
        ),
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    );
  }
}

/// The ambient Scale UI factor, for [UiScaleExempt] to invert.
class UiScaleScope extends InheritedWidget {
  const UiScaleScope({super.key, required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UiScaleScope>()?.scale ?? 1.0;

  @override
  bool updateShouldNotify(UiScaleScope oldWidget) => oldWidget.scale != scale;
}

/// Carves a subtree back out of [UiScaler]'s scale: the child is laid out at
/// its slot's true on-screen size and painted with the inverse factor, a net
/// identity. Wrapped around every WebView, because web pages have their own
/// zoom settings and a scaled platform view would both relayout and resample,
/// reflowing the dashboard and blurring it, exactly what the Scale UI setting
/// promises not to do.
///
/// Always in the tree, even at 1.0, where every wrapper is an identity: a
/// wrapper that appeared only at other factors would change the tree shape
/// as the slider crosses 100% and recreate the WebView, a full page reload.
/// The child's layout size never varies with the factor either (the slot is
/// measured in the scaled space, so slot times factor is constant), which is
/// what keeps a live factor change from reflowing the page.
class UiScaleExempt extends StatelessWidget {
  const UiScaleExempt({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scale = UiScaleScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Every current slot is a bounded plane (StackFit.expand or
        // Positioned.fill); without bounds there is no slot size to invert,
        // so the child is left alone.
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return child;
        }
        return FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: constraints.maxWidth * scale,
            height: constraints.maxHeight * scale,
            child: child,
          ),
        );
      },
    );
  }
}
