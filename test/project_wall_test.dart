import 'package:cv_apps/src/modules/home/home_project_wall.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 3D project wall moves only with the page scroll or a drag/fling, and
/// every glide must come to a full stop (no ticker left running).
void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 400 && tester.binding.transientCallbackCount > 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('renders at phone and desktop widths and always comes to rest', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [360.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [ProjectWall(), SizedBox(height: 1200)]),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('PROJECTS & IMPACT'), findsOneWidget);
      expect(find.text('700K'), findsWidgets);

      // Short welcome glide, then it rests by itself.
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await settle(tester);
      expect(tester.binding.transientCallbackCount, 0);

      // A fling on the wall glides and stops.
      final wall = tester.getCenter(find.byType(ProjectWall));
      await tester.flingFrom(wall, const Offset(-200, 0), 1800);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await settle(tester);
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'a fling must glide to a complete stop',
      );

      // Scrolling the page moves the wall without starting any ticker of
      // its own, and nothing overflows while it moves.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await settle(tester);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    }
  });
}
