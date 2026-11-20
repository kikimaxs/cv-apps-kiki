import 'dart:convert';

import 'package:cv_apps/src/modules/my_portofolio/views/portfolio_v2_fx.dart';
import 'package:cv_apps/src/modules/my_portofolio/views/portfolio_v2_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Frame-timing benchmark for portfolio v2. Run in profile mode:
///
///   flutter drive --no-dds --driver=test_driver/perf_driver.dart \
///     --target=integration_test/portfolio_v2_perf_test.dart --profile -d macos
///
/// Results are printed as `PERF <phase> {json}` lines (milliseconds).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  double percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    return sorted[((sorted.length - 1) * p).round()];
  }

  Map<String, num> stats(List<double> values) {
    final sorted = [...values]..sort();
    final avg = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
    return {
      'avg': double.parse(avg.toStringAsFixed(2)),
      'p90': double.parse(percentile(sorted, 0.90).toStringAsFixed(2)),
      'p99': double.parse(percentile(sorted, 0.99).toStringAsFixed(2)),
      'worst': double.parse(
        (sorted.isEmpty ? 0 : sorted.last).toStringAsFixed(2),
      ),
    };
  }

  Future<void> measure(String phase, Future<void> Function() body) async {
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> batch) => timings.addAll(batch);
    SchedulerBinding.instance.addTimingsCallback(collect);
    await body();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    SchedulerBinding.instance.removeTimingsCallback(collect);

    double ms(Duration d) => d.inMicroseconds / 1000;
    final build = [for (final t in timings) ms(t.buildDuration)];
    final raster = [for (final t in timings) ms(t.rasterDuration)];
    final total = [for (final t in timings) ms(t.totalSpan)];
    final missed = total.where((v) => v > 16.7).length;
    final cache = PaintingBinding.instance.imageCache;
    // ignore: avoid_print
    print(
      'CACHE $phase ${jsonEncode({'bytes_mb': (cache.currentSizeBytes / 1e6).toStringAsFixed(1), 'max_mb': (cache.maximumSizeBytes / 1e6).toStringAsFixed(0), 'images': cache.currentSize, 'live': cache.liveImageCount})}',
    );
    // ignore: avoid_print
    print(
      'PERF $phase ${jsonEncode({'frames': timings.length, 'build_ms': stats(build), 'raster_ms': stats(raster), 'total_ms': stats(total), 'frames_over_16_7ms': missed})}',
    );
  }

  testWidgets('portfolio v2 first open and frame timing', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1366 * 2, 820 * 2);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // First open: from the first frame until the hero title is on screen,
    // then six seconds of the page as the reader first sees it.
    final openWatch = Stopwatch()..start();
    final fadesAtStart = pictureFadeIns;
    await tester.pumpWidget(const MaterialApp(home: PortfolioV2View()));
    var revealedMs = -1;
    while (openWatch.elapsedMilliseconds < 6000) {
      await tester.pump(const Duration(milliseconds: 16));
      if (revealedMs < 0 && find.text('PORTOFOLIO').evaluate().isNotEmpty) {
        revealedMs = openWatch.elapsedMilliseconds;
      }
    }
    // ignore: avoid_print
    print(
      'OPEN ${jsonEncode({'title_visible_ms': revealedMs, 'pictures_faded_in_first_6s': pictureFadeIns - fadesAtStart})}',
    );

    final scrollable = find.byType(Scrollable).first;
    final state = tester.state<ScrollableState>(scrollable);

    // Steady scroll down through the whole page, one 16 ms frame per step.
    final fadesBeforeScroll = pictureFadeIns;
    await measure('scroll_down', () async {
      while (state.position.pixels < state.position.maxScrollExtent) {
        state.position.jumpTo(
          (state.position.pixels + 22).clamp(0, state.position.maxScrollExtent),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
    });
    // ignore: avoid_print
    print('FADE scroll_down ${pictureFadeIns - fadesBeforeScroll}');

    // Scroll back up the same way.
    final fadesBeforeUp = pictureFadeIns;
    await measure('scroll_up', () async {
      while (state.position.pixels > 0) {
        state.position.jumpTo(
          (state.position.pixels - 22).clamp(0, double.infinity),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
    });
    // ignore: avoid_print
    print('FADE scroll_up ${pictureFadeIns - fadesBeforeUp}');

    // Flick gestures, as on a phone.
    final fadesBeforeFling = pictureFadeIns;
    await measure('fling', () async {
      for (var i = 0; i < 5; i++) {
        await tester.fling(scrollable, const Offset(0, -500), 1500);
        await tester.pump(const Duration(milliseconds: 900));
      }
      for (var i = 0; i < 5; i++) {
        await tester.fling(scrollable, const Offset(0, 500), 1500);
        await tester.pump(const Duration(milliseconds: 900));
      }
    });
    // ignore: avoid_print
    print('FADE fling ${pictureFadeIns - fadesBeforeFling}');
  });
}
