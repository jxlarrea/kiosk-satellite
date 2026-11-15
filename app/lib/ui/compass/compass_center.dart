import 'package:flutter/widgets.dart';

import '../../app_container.dart';

/// A view's close button, left out while the view is the Compass center.
///
/// Closing a view lands on the center. For the center itself that opens
/// the view again, so the button would do nothing. [kind] is the view's
/// kind in the layout (compass_layout.dart). Opened anywhere else, on a
/// side of the layout or in Classic, the view keeps its button. So does a
/// copy of the view the layout does not hold, such as the screensaver's
/// calendar, which passes no [kind].
class CompassCenterHides extends StatelessWidget {
  const CompassCenterHides({
    super.key,
    required this.container,
    required this.kind,
    required this.child,
  });

  final AppContainer container;
  final String? kind;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: container.compassCenter,
    builder: (context, center, child) =>
        kind != null && center == kind ? const SizedBox.shrink() : child!,
    child: child,
  );
}

/// What a Compass view's close button does. On a side of the layout it
/// goes to the center as back does: the center opens first and the view
/// closes under it. Closing the view first would leave the screen with
/// nothing over the dashboard until Compass caught up, a flash of the
/// page, or of black where the view had the page out of the frame.
/// Anywhere else, or with no [kind], it runs [close].
void compassClose(AppContainer c, String? kind, VoidCallback close) {
  if (kind != null && (c.compassCloseToCenter?.call(kind) ?? false)) return;
  close();
}
