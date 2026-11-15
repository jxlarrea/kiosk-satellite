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
