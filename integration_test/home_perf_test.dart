import 'dart:convert';

import 'package:cv_apps/main.dart' as app;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Frame-timing benchmark for the home page. Run in profile mode:
///
///   flutter drive --no-dds --driver=test_driver/perf_driver.dart \
///     --target=integration_test/home_perf_test.dart --profile -d DEVICE_ID
///
/// Results are printed as `PERF <phase> {json}` lines (milliseconds).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  double percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    final index = ((sorted.length - 1) * p).round();
    return sorted[index];
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
    // Timings are delivered in batches; give the last batch time to arrive.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    SchedulerBinding.instance.removeTimingsCallback(collect);

    double ms(Duration d) => d.inMicroseconds / 1000;
    final build = [for (final t in timings) ms(t.buildDuration)];
    final raster = [for (final t in timings) ms(t.rasterDuration)];
    final total = [for (final t in timings) ms(t.totalSpan)];
    final missed = total.where((v) => v > 16.7).length;
    // ignore: avoid_print
    print(
      'PERF $phase ${jsonEncode({'frames': timings.length, 'build_ms': stats(build), 'raster_ms': stats(raster), 'total_ms': stats(total), 'frames_over_16_7ms': missed})}',
    );
  }

  testWidgets('home page frame timing', (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 4));

    // Ambient animations only (aurora, orbit, marquee, carousel, ...).
    await measure('idle', () async {
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    // Scrolling page 1 down and back with a pointer moving over it.
    final scrollable = find.byType(SingleChildScrollView).first;
    await measure('scroll', () async {
      for (var i = 0; i < 5; i++) {
        await tester.fling(scrollable, const Offset(0, -500), 1200);
        await tester.pump(const Duration(milliseconds: 900));
      }
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(100, 300));
      for (var i = 0; i < 25; i++) {
        await mouse.moveTo(Offset(100.0 + i * 12, 300.0 + i * 8));
        await tester.pump(const Duration(milliseconds: 32));
      }
      await mouse.removePointer();
      for (var i = 0; i < 5; i++) {
        await tester.fling(scrollable, const Offset(0, 500), 1200);
        await tester.pump(const Duration(milliseconds: 900));
      }
    });
  });
}
