import 'dart:io';

import 'package:cv_apps/src/modules/my_portofolio/portfolio_assets.dart';
import 'package:cv_apps/src/modules/my_portofolio/views/my_portofolio_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  await tester.pumpWidget(const MaterialApp(home: MyPortofolioView()));
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  test('every image in the aspect table exists, and every image is listed', () {
    final onDisk = Directory(
      'assets/img/portfolio',
    ).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
    expect(kPortfolioAspects.keys.toSet(), onDisk);
  });

  testWidgets('phone layout shows every slide without layout errors', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, 390);

    expect(find.text('MY PORTOFOLIO'), findsOneWidget);
    expect(find.text('01 / 12'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Scroll the whole page in steps; images load as they come near.
    final scroll = find.byType(SingleChildScrollView);
    for (var i = 0; i < 40; i++) {
      await tester.drag(scroll, const Offset(0, -700));
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('Contact :'), findsOneWidget);
    expect(find.text('12 / 12'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('desktop top bar jumps to a slide and highlights it', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, 1280);

    expect(find.text('What is the MOLA TV Apps ?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Kontak'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 300));

    final top = tester.getTopLeft(find.text('Contact :')).dy;
    expect(top, inInclusiveRange(0, 900));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Durioo+'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
