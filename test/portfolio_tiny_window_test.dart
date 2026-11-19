import 'package:cv_apps/src/modules/my_portofolio/views/my_portofolio_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A window can be very short while it is resized or while DevTools switches
// device mode. The portfolio must lay out at any size without throwing.
void main() {
  for (final size in const [
    Size(375, 0),
    Size(375, 1),
    Size(375, 24),
    Size(375, 40),
    Size(1280, 0),
    Size(1280, 8),
    Size(1280, 40),
    Size(0, 800),
  ]) {
    testWidgets('portfolio lays out at $size without errors', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(const MaterialApp(home: MyPortofolioView()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'at $size');

      // Growing back to a phone and to a desktop window must be clean too.
      tester.view.physicalSize = const Size(375, 812);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'phone after $size');
      tester.view.physicalSize = const Size(1280, 900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'desktop after $size');
    });
  }
}
