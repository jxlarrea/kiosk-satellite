from pathlib import Path
src=Path('lib/main.dart').read_text()
extra='''
  final perfFrames = <FrameTiming>[];
  final perfWatch = Stopwatch();
  WidgetsBinding.instance.addTimingsCallback((frames) {
    if (perfWatch.isRunning) perfFrames.addAll(frames);
  });
  container.commands.register(Command(
    name: 'nowPlayingPerf', description: 'Temporary frame timing capture',
    handler: (p) async {
      if (p['reset'] == true) {
        perfFrames.clear();
        perfWatch.reset();
        perfWatch.start();
        return const CommandResult.ok();
      }
      perfWatch.stop();
      Map<String, Object> stats(List<double> values) {
        values.sort();
        if (values.isEmpty) return {};
        return {'meanMs': values.reduce((a,b)=>a+b)/values.length,
          'p95Ms': values[((values.length-1)*.95).round()],
          'maxMs': values.last};
      }
      return CommandResult.ok({
        'elapsedMs': perfWatch.elapsedMilliseconds,
        'frames': perfFrames.length,
        'build': stats(perfFrames.map((f)=>f.buildDuration.inMicroseconds/1000).toList()),
        'raster': stats(perfFrames.map((f)=>f.rasterDuration.inMicroseconds/1000).toList()),
        'slowFrames16ms': perfFrames.where((f)=>f.buildDuration.inMicroseconds>16667||f.rasterDuration.inMicroseconds>16667).length,
        'imageCacheBytes': PaintingBinding.instance.imageCache.currentSizeBytes,
        'liveImages': PaintingBinding.instance.imageCache.liveImageCount,
        'rssBytes': ProcessInfo.currentRss,
      });
    },
  ));
'''
src="import 'dart:ui' show FrameTiming;\nimport 'core/command_registry.dart';\n"+src
src=src.replace('  await container.init();','  await container.init();\n'+extra,1)
Path('lib/main_now_playing_perf.dart').write_text(src)
