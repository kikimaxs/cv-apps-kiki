import 'package:cv_apps/src/modules/home/home_experience_lab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('interactive capability tabs fit phone and desktop widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [320.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HomeExperienceLab()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('lab-tab-1')));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Informative, easy-to-use websites.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('lab-tab-2')));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('From idea to ready to use.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
