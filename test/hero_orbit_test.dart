import 'package:cv_apps/src/modules/home/home_fx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The hero orbit is a toy: it moves only when played with, and every motion
/// must come to a full stop (no ticker left running).
void main() {
  Future<void> pumpOrbit(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: HeroOrbit(size: 420))),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 300 && tester.binding.transientCallbackCount > 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('welcome spin, fling and taps all ease to a full stop', (
    tester,
  ) async {
    await pumpOrbit(tester);

    // Short welcome spin, then it rests on its own.
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await settle(tester);
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.text('Geser untuk memutar · ketuk logonya'), findsOneWidget);

    // Fling sideways across the bottom of the orbit.
    final center = tester.getCenter(find.byType(HeroOrbit));
    await tester.flingFrom(
      center + const Offset(-120, 150),
      const Offset(240, 0),
      2000,
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await settle(tester);
    expect(
      tester.binding.transientCallbackCount,
      0,
      reason: 'a fling must glide to a complete stop',
    );

    // Tapping the core spins it; it stops again.
    await tester.tap(find.text('K.'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await settle(tester);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a logo shows its name in the core', (tester) async {
    await pumpOrbit(tester);
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Kotlin'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Kotlin'), findsOneWidget);

    // The name goes back to "K." after a moment.
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('K.'), findsOneWidget);
    expect(find.text('Kotlin'), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
