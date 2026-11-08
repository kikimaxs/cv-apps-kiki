import 'package:cv_apps/src/modules/home/home_showreel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showreel carousel fits, switches videos and opens the player', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [320.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: HomeShowreel())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
      expect(find.text('Durioo+: Released App'), findsOneWidget);

      // Arrow button moves to the next video.
      final next = find.byKey(const ValueKey('showreel-next'));
      await tester.ensureVisible(next);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(next);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();
      expect(find.text('Production Showcase'), findsOneWidget);
      expect(find.text('Durioo+: Released App'), findsNothing);
      expect(tester.takeException(), isNull);

      // Watch button opens and closes the player.
      await tester.tap(find.byKey(const ValueKey('showreel-watch')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ShowreelPlayer), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('showreel-close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ShowreelPlayer), findsNothing);

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('carousel autoplay advances after 5 seconds', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: HomeShowreel())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Durioo+: Released App'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    expect(find.text('Production Showcase'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
