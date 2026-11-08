import 'package:cv_apps/src/modules/home/home_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('skills and contact sections fit compact and wide screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [320.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(const MaterialApp(home: HomeMain()));
      await tester.pump(const Duration(milliseconds: 900));

      final controller = tester
          .widget<PageView>(find.byType(PageView).first)
          .controller!;
      controller.jumpToPage(1);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);

      controller.jumpToPage(2);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
