import 'dart:io';

import 'package:cv_apps/src/modules/my_portofolio/portfolio_assets.dart';
import 'package:cv_apps/src/modules/my_portofolio/portfolio_slide_assets.dart';
import 'package:cv_apps/src/modules/my_portofolio/portfolio_slides_data.dart';
import 'package:cv_apps/src/modules/my_portofolio/views/my_portofolio_view.dart';
import 'package:flutter/gestures.dart';
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

  test('every media id on the 12 pages has a file that exists', () {
    final used = <String>{};
    for (final page in kSlidePages) {
      for (final item in page.items) {
        if (item is SlideImage) used.add(item.mediaId);
      }
    }
    expect(kSlidePages.length, 12);
    expect(used.difference(kSlideAssets.keys.toSet()), isEmpty);
    for (final path in kSlideAssets.values) {
      expect(File(path).existsSync(), isTrue, reason: 'missing $path');
    }
  });

  testWidgets('phone layout shows every page without layout errors', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, 390);

    expect(find.textContaining('MY PORTFOLIO'), findsOneWidget);
    expect(find.text('01 / 12'), findsNothing);
    expect(tester.takeException(), isNull);

    // Scroll the whole page in steps; pages build as they come near.
    final scroll = find.byType(SingleChildScrollView).first;
    for (var i = 0; i < 40; i++) {
      await tester.drag(scroll, const Offset(0, -700));
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('Contact :'), findsOneWidget);
    expect(find.text('12 / 12'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('desktop header jumps to a page and highlights it', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, 1280);

    expect(find.textContaining('MY PORTFOLIO'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Contact'));
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

  testWidgets(
    'landscape: every page fills exactly one screen, under the header',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, 1280);

      final pages = find.byType(AspectRatio);
      expect(pages, findsWidgets);
      // The header floats over the first page: the page is the whole screen.
      final h = tester.getSize(pages.first).height;
      expect(h, closeTo(900, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('landscape: scrolling snaps to the start of a page', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, 1280);

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    const pageH = 900.0;
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    final at = scrollable.position.pixels;
    expect(at % pageH, closeTo(0, 1), reason: 'settled at $at');
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait: pages reflow into a column without layout errors', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, 375);
    expect(find.textContaining('MY PORTFOLIO'), findsOneWidget);
    expect(find.textContaining('What is the MOLA TV Apps'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'portrait cover: the title sits over the photo, the name under it',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, 375);
      final title = tester.getTopLeft(find.textContaining('MY PORTFOLIO')).dy;
      final name = tester.getTopLeft(find.text('KIKI TRIANSYAH').first).dy;
      expect(title, lessThan(name));
      // Both sit in the upper part of the screen, clear of the laptop below.
      expect(name, lessThan(900 * 0.6));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('header is transparent and shows no page counter', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, 1280);

    expect(find.text('01 / 12'), findsNothing);
    expect(tester.getTopLeft(find.text('Portfolio')).dy, lessThan(56));
    final headers = tester.widgetList<Container>(
      find.ancestor(
        of: find.text('Portfolio'),
        matching: find.byType(Container),
      ),
    );
    final transparent = headers.any((c) {
      final d = c.decoration;
      return d is BoxDecoration && d.color == null && d.gradient != null;
    });
    expect(transparent, isTrue, reason: 'the header has no solid bar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('links: a contact turns blue on hover and shows a hand cursor', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, 1280);

    await tester.tap(find.text('Contact'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 300));

    final email = find.text('kiki.triansyah93@gmail.com');
    expect(email, findsOneWidget);
    final cursors = tester
        .widgetList<MouseRegion>(
          find.ancestor(of: email, matching: find.byType(MouseRegion)),
        )
        .map((r) => r.cursor);
    expect(cursors, contains(SystemMouseCursors.click));

    const blue = Color(0xFF004AAD);
    Color? colour() => tester.widget<Text>(email).style?.color;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(colour(), isNot(blue));

    await mouse.moveTo(tester.getCenter(email));
    await tester.pump();
    expect(colour(), blue);

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(colour(), isNot(blue));
    expect(tester.takeException(), isNull);
  });
}
