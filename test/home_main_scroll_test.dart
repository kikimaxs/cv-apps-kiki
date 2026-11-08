import 'package:cv_apps/src/modules/home/home_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('page changes only after its content reaches an edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(852, 524);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeMain()));
    await tester.pump(const Duration(milliseconds: 900));

    final pageController = tester
        .widget<PageView>(find.byType(PageView).first)
        .controller!;
    final pageContent = find.byType(SingleChildScrollView).first;

    await tester.drag(pageContent, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 100));
    expect(pageController.page, closeTo(0, 0.01));

    await tester.fling(pageContent, const Offset(0, -3000), 10000);
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(pageController.page, closeTo(1, 0.01));
  });
}
