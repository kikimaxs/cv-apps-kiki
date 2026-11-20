import 'dart:io';

import 'package:cv_apps/src/modules/my_portofolio/portfolio_slide_assets.dart';
import 'package:cv_apps/src/modules/my_portofolio/views/portfolio_v2_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(const MaterialApp(home: PortfolioV2View()));
  // The page is shown once its pictures are decoded, or after ten seconds.
  await tester.pump(const Duration(seconds: 11));
}

/// Scrolls the page to its end in screen-sized steps, letting reveals run.
Future<void> _scrollThrough(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 60; i++) {
    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.pump(const Duration(seconds: 3));
}

bool _hasText(String text) => find
    .byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains(text),
    )
    .evaluate()
    .isNotEmpty;

void main() {
  for (final (label, size) in [
    ('desktop', const Size(1366, 820)),
    ('phone', const Size(390, 844)),
  ]) {
    testWidgets('$label layout scrolls end to end without errors', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, size);
      final e = tester.takeException();
      if (e is FlutterError) debugPrint(e.toStringDeep());
      expect(e, isNull);
      await _scrollThrough(tester);
      expect(tester.takeException(), isNull);

      // Text comes from the slide data, unchanged.
      expect(_hasText('Live streaming video entertainment'), isTrue);
      expect(_hasText('health and safety ecosystem'), isTrue);
      expect(find.bySemanticsLabel('What is the MOLA TV Apps ?'), findsOne);
      expect(_hasText('fallback to the highest quality MP4'), isTrue);
      expect(_hasText('@kikitriansyah'), isTrue);
      // Leave the page so its loop and listeners are disposed.
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('every picture v2 uses has an asset and a known ratio', () {
    for (final id in kSlideAssets.keys) {
      expect(v2Ratio(id), greaterThan(0));
    }
  });

  test('every raster picture has a display-sized copy for v2', () {
    for (final entry in kSlideAssets.entries) {
      if (entry.value.endsWith('.svg')) continue;
      final copy =
          'assets/img/portfolio_v2/${entry.key}.${entry.value.split('.').last}';
      expect(File(copy).existsSync(), isTrue, reason: 'missing $copy');
    }
  });
}
