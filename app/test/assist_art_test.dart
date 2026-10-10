import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/assist/art_jarvis.dart';
import 'package:kiosk_satellite/ui/assist/art_lens_flares.dart';
import 'package:kiosk_satellite/ui/assist/art_logo.dart';
import 'package:kiosk_satellite/ui/assist/art_waveform.dart';
import 'package:kiosk_satellite/ui/assist/assist_art.dart';
import 'package:kiosk_satellite/ui/assist/assist_skins.dart';

class _Host extends StatefulWidget {
  const _Host({required this.builder});
  final Widget Function(ArtClock clock) builder;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final ArtClock clock = ArtClock(this);

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(clock);
}

class _ClockHost extends StatefulWidget {
  const _ClockHost({required this.running});
  final bool running;

  @override
  State<_ClockHost> createState() => _ClockHostState();
}

class _ClockHostState extends State<_ClockHost>
    with SingleTickerProviderStateMixin {
  late final ArtClock clock;

  @override
  void initState() {
    super.initState();
    clock = ArtClock(this, running: widget.running);
  }

  @override
  void didUpdateWidget(_ClockHost old) {
    super.didUpdateWidget(old);
    clock.running = widget.running;
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  // A running clock asks for every frame, so the overlay's clock stops
  // while the overlay is hidden, or the kiosk would draw nonstop after the
  // first voice turn.
  testWidgets('a stopped clock asks for no frames', (tester) async {
    await tester.pumpWidget(const _ClockHost(running: true));
    expect(tester.binding.transientCallbackCount, 1);
    await tester.pumpWidget(const _ClockHost(running: false));
    expect(tester.binding.transientCallbackCount, 0);
  });

  // Every skin's bar, backdrop and bullets, and the canvas art of the
  // three animated ones, in every mode, light and dark, at rest and loud:
  // a painter that throws leaves a skin blank on the kiosk.
  for (final skin in assistSkins) {
    testWidgets('${skin.name} paints', (tester) async {
      final level = ValueNotifier<double>(0);
      for (final dark in [false, true]) {
        for (final mode in ArtMode.values) {
          for (final value in [0.0, 0.8]) {
            level.value = value;
            final palette = skin.palette(dark);
            await tester.pumpWidget(
              MaterialApp(
                home: SizedBox(
                  width: 1280,
                  height: 800,
                  child: _Host(
                    builder: (clock) => Stack(
                      children: [
                        Positioned.fill(
                          child: SkinBackdrop(
                            skin: skin,
                            color: palette.backdrop,
                          ),
                        ),
                        if (skin.art == SkinArt.waveform)
                          Positioned.fill(
                            child: WaveformArt(
                              dark: dark,
                              mode: mode,
                              reactive: true,
                              level: level,
                            ),
                          ),
                        if (skin.art == SkinArt.lensFlares)
                          Positioned.fill(
                            child: LensFlaresArt(
                              mode: mode,
                              reactive: true,
                              level: level,
                            ),
                          ),
                        if (skin.art == SkinArt.jarvis)
                          for (final compact in [false, true])
                            Positioned.fill(
                              child: JarvisArt(
                                mode: mode,
                                reactive: true,
                                level: level,
                                clock: clock,
                                compact: compact,
                                countdown: compact ? level : null,
                              ),
                            ),
                        if (skin.voiceOnly)
                          for (final reactive in [false, true])
                            Positioned.fill(
                              child: LogoArt(
                                mode: mode,
                                reactive: reactive,
                                level: level,
                                clock: clock,
                                fade: level,
                              ),
                            ),
                        for (final reactive in [false, true])
                          Positioned.fill(
                            child: SkinBarLayer(
                              skin: skin,
                              mode: mode,
                              reactive: reactive,
                              level: level,
                              clock: clock,
                            ),
                          ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final idle in [false, true])
                                ThinkingDots(
                                  skin: skin,
                                  colors: palette.dots,
                                  scale: 1,
                                  clock: clock,
                                  idle: idle,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 120));
            expect(tester.takeException(), isNull);
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
