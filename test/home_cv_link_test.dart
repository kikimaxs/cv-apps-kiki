import 'package:cv_apps/src/modules/home/home_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeMain()),
    GoRoute(path: '/my_cv', builder: (_, _) => const Text('CV PAGE')),
  ],
);

void main() {
  Future<void> pumpHome(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pump(const Duration(milliseconds: 900));
  }

  testWidgets('hero CV button opens the CV page on phone width', (
    tester,
  ) async {
    await pumpHome(tester, 375);
    final button = find.byKey(const ValueKey('hero-cv-button'));
    // Bring the button to mid-screen so the floating navbar can't cover it.
    final scrollable = find.byType(SingleChildScrollView).first;
    final dy = 450 - tester.getCenter(button).dy;
    await tester.drag(scrollable, Offset(0, dy));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getCenter(button).dy, inInclusiveRange(150, 750));
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('CV PAGE'), findsOneWidget);
  });

  testWidgets('navbar CV link opens the CV page on desktop width', (
    tester,
  ) async {
    await pumpHome(tester, 1280);
    await tester.tap(find.byKey(const ValueKey('nav-cv-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('CV PAGE'), findsOneWidget);
  });
}
