import 'package:cv_apps/src/modules/my_portofolio/views/my_portofolio_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(const MaterialApp(home: MyPortofolioView()));
  await tester.pump(const Duration(milliseconds: 500));
}

void _resize(WidgetTester tester, Size size, {double dpr = 1}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size;
}

Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(SingleChildScrollView).first, Offset(0, dy));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

// The window changes size in the middle of a session, as a browser's device
// mode or a resize does. The page must keep working without errors.
void main() {
  testWidgets('desktop to phone after scrolling raises no errors', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(1280, 900));
    await _scroll(tester, -900);
    await _scroll(tester, -900);
    expect(tester.takeException(), isNull);

    _resize(tester, const Size(375, 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone to desktop after scrolling raises no errors', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(375, 800));
    await _scroll(tester, -700);
    await _scroll(tester, -700);
    expect(tester.takeException(), isNull);

    _resize(tester, const Size(1280, 900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('resizing back and forth raises no errors', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(1280, 900));
    for (final size in const [
      Size(375, 800),
      Size(1280, 900),
      Size(390, 844),
      Size(1024, 768),
    ]) {
      _resize(tester, size);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: 'at $size');
    }
  });

  testWidgets('jump to a page, then switch to phone while it animates', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(1280, 900));
    await tester.tap(find.text('Lifeline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    _resize(tester, const Size(375, 800));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('jump to a page, then switch to phone once it has settled', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(1280, 900));
    await tester.tap(find.text('HadIR'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    _resize(tester, const Size(375, 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone to desktop in the middle of a fling raises no errors', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(375, 800));
    await tester.fling(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -900),
      3000,
    );
    await tester.pump(const Duration(milliseconds: 150));
    _resize(tester, const Size(1280, 900));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop to phone in the middle of a fling raises no errors', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(1280, 900));
    await tester.fling(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -900),
      3000,
    );
    await tester.pump(const Duration(milliseconds: 150));
    _resize(tester, const Size(375, 800));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('device emulation: a phone at pixel ratio 3, then desktop', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(1280, 900));
    await _scroll(tester, -900);
    _resize(tester, const Size(1125, 2436), dpr: 3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'phone at DPR 3');

    _resize(tester, const Size(1280, 900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'back to desktop');
  });
}
