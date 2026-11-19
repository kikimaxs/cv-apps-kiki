import 'dart:ui' show PointerDeviceKind;

import 'package:cv_apps/src/modules/home/home_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for "the laptop fan spins up while the page just sits
/// there": an idle page must not keep any ticker (and so any frame) alive.
void main() {
  testWidgets('idle page stops all animation, input wakes it again', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [390.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(const MaterialApp(home: HomeMain()));
      await tester.pump(const Duration(seconds: 1));

      // Just opened: ambient animations (aurora, orbit, ...) run.
      expect(
        tester.binding.transientCallbackCount,
        greaterThan(0),
        reason: 'ambient animations should run right after opening',
      );

      // Nobody touches the page: it goes calm.
      await tester.pump(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'an idle page must not keep any ticker alive',
      );
      expect(tester.binding.hasScheduledFrame, isFalse);

      // A mouse move wakes it up.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(50, 50));
      await mouse.moveTo(const Offset(80, 90));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.binding.transientCallbackCount,
        greaterThan(0),
        reason: 'input should resume the ambient animations',
      );
      await mouse.removePointer();

      // ...and it settles again once the visitor leaves it alone. (The glow
      // eases out over a few real frames, so step through them first.)
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    }
  });
}
