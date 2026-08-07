import 'dart:async';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Lockdown Mode's touch shield (discussion #143).
///
/// A transparent, opaque-to-hit-testing layer mounted topmost on the kiosk
/// stack: the dashboard stays fully glanceable underneath, it just stops
/// answering. A tap is acknowledged with a transient "Screen is locked"
/// pill, so a locked tablet reads as locked instead of broken.
///
/// The shield deliberately swallows pointers at the Flutter layer only.
/// The lockdown exit gesture is counted natively at the Activity
/// (KioskLock.kt sees every pointer before Flutter does), so the taps
/// that end the mode land regardless of what is mounted here.
///
/// With [blackout] the same shield paints solid black instead: nothing to
/// see and nothing to touch. The kiosk screen reports the covered surface
/// to the browser so the dashboard stops compositing underneath.
class LockdownShield extends StatefulWidget {
  const LockdownShield({super.key, this.blackout = false});

  final bool blackout;

  @override
  State<LockdownShield> createState() => _LockdownShieldState();
}

class _LockdownShieldState extends State<LockdownShield> {
  bool _pillVisible = false;
  Timer? _hide;

  void _onPointerDown(PointerDownEvent _) {
    _hide?.cancel();
    if (!_pillVisible) setState(() => _pillVisible = true);
    _hide = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _pillVisible = false);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        child: ColoredBox(
          color: widget.blackout ? Colors.black : Colors.transparent,
          child: Align(
            // Low on the screen, clear of dashboard headers and the
            // screensaver clock positions alike.
            alignment: const Alignment(0, 0.82),
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _pillVisible ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(Ks.radiusCard),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Screen is locked',
                        style: TextStyle(color: Colors.white, fontSize: 14.5),
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
