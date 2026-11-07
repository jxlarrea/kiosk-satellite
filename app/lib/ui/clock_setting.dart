import 'dart:async';

import 'package:flutter/widgets.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/settings/definitions.dart';

/// Points the times under [child] at a 24-hour clock [setting], such as
/// Settings > Calendar > 24-hour clock, instead of Android's clock. Each
/// screen wraps its root and every dialog it opens, since those sit on the
/// root navigator outside it. The times read
/// MediaQuery.alwaysUse24HourFormatOf as usual.
class ClockSetting extends StatefulWidget {
  const ClockSetting({
    super.key,
    required this.container,
    required this.setting,
    required this.child,
  });

  final AppContainer container;
  final SettingDef<bool> setting;
  final Widget child;

  @override
  State<ClockSetting> createState() => _ClockSettingState();
}

class _ClockSettingState extends State<ClockSetting> {
  StreamSubscription<SettingChanged>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.container.bus.on<SettingChanged>().listen((e) {
      if (e.key == widget.setting.key && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      alwaysUse24HourFormat: widget.container.settings.get(widget.setting),
    ),
    child: widget.child,
  );
}
