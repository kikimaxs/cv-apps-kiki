import 'dart:ui' show PointerDeviceKind;

import 'package:cv_apps/src/modules/home/home_fx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hero effects render at phone and desktop widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [320.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CursorGlow(
              background: const AuroraBackground(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const AnimatedHeadline(
                      text: 'Membangun produk digital yang terasa tepat.',
                      highlight: {4, 5},
                      style: TextStyle(fontSize: 32, color: Colors.white),
                    ),
                    HeroOrbit(size: width < 400 ? 280 : 420),
                    const Reveal(child: Text('revealed')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1200));
      expect(tester.takeException(), isNull);
      expect(find.text('revealed'), findsOneWidget);

      // Pointer move (mouse hover) drives the glow without errors.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(40, 40));
      await gesture.moveTo(const Offset(160, 200));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await gesture.removePointer();

      await tester.pumpWidget(const SizedBox());
    }
  });
}
