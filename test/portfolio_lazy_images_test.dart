import 'package:cv_apps/src/modules/my_portofolio/portfolio_slide_assets.dart';
import 'package:cv_apps/src/modules/my_portofolio/portfolio_slides_data.dart';
import 'package:cv_apps/src/modules/my_portofolio/views/my_portofolio_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(const MaterialApp(home: MyPortofolioView()));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Future<void> _scroll(WidgetTester tester, double dy, int steps) async {
  for (var i = 0; i < steps; i++) {
    await tester.drag(find.byType(SingleChildScrollView).first, Offset(0, dy));
    await tester.pump(const Duration(milliseconds: 60));
  }
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

int _pictures(WidgetTester tester) => find.byType(Image).evaluate().length;

void main() {
  testWidgets('phone: only the pages near the screen load their pictures', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Every raster picture of the 12 pages, which a phone would load in full.
    final total = [
      for (final page in kSlidePages)
        for (final item in page.items)
          if (item is SlideImage &&
              !(kSlideAssets[item.mediaId] ?? '').endsWith('.svg'))
            item,
    ].length;

    await _pump(tester, const Size(375, 812));
    final atTop = _pictures(tester);
    expect(atTop, greaterThan(0));
    expect(
      atTop,
      lessThan(total ~/ 3),
      reason: 'the far pages must not load their pictures ($atTop of $total)',
    );

    await _scroll(tester, -700, 60);
    final atEnd = _pictures(tester);
    expect(
      atEnd,
      lessThan(total ~/ 3),
      reason: 'at the end only the last pages load ($atEnd of $total)',
    );

    await _scroll(tester, 700, 60);
    expect(
      _pictures(tester),
      atTop,
      reason: 'back at the top, the same pictures are loaded',
    );
    expect(tester.takeException(), isNull);
  });
}
