import 'package:cv_apps/src/modules/my_cv/views/my_cv_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The CV must lay out at phone, tablet and desktop widths without a framework
// error, must never cut text with an ellipsis, and must keep every line of
// text inside the screen so a phone never needs to scroll sideways.
const List<Size> _sizes = [
  Size(320, 640),
  Size(357, 800),
  Size(390, 844),
  Size(430, 932),
  Size(600, 900),
  Size(899, 900),
  Size(900, 900),
  Size(1024, 768),
  Size(1280, 900),
];

Future<List<FlutterErrorDetails>> _collectErrors(
  Future<void> Function() body,
) async {
  final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void _expectTextInsideScreen(WidgetTester tester, Size size) {
  for (final Element element in find.byType(Text).evaluate()) {
    // Read each text's own render box: const texts such as bullets are shared
    // instances, so a finder by widget would match several of them at once.
    final RenderObject? render = element.renderObject;
    if (render is! RenderBox || !render.hasSize) continue;
    final Rect rect = render.localToGlobal(Offset.zero) & render.size;
    final String label = (element.widget as Text).data ?? '<rich text>';
    expect(
      rect.left,
      greaterThanOrEqualTo(-0.5),
      reason: '"$label" starts left of the screen at $size',
    );
    expect(
      rect.right,
      lessThanOrEqualTo(size.width + 0.5),
      reason: '"$label" runs past the right edge at $size',
    );
  }
}

void _expectNoEllipsis() {
  final truncated = find.byWidgetPredicate(
    (widget) => widget is Text && widget.overflow == TextOverflow.ellipsis,
  );
  expect(truncated, findsNothing);
}

Future<void> _scrollThroughPage(WidgetTester tester) async {
  final scroll = find.byType(SingleChildScrollView).first;
  for (var i = 0; i < 30; i++) {
    await tester.drag(scroll, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  for (final size in _sizes) {
    testWidgets('CV lays out cleanly at $size', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      final errors = await _collectErrors(() async {
        await tester.pumpWidget(const MaterialApp(home: MyCvView()));
        await tester.pump(const Duration(milliseconds: 300));
        await _scrollThroughPage(tester);
      });

      expect(errors, isEmpty, reason: 'framework errors at $size');
      expect(tester.takeException(), isNull);
      _expectTextInsideScreen(tester, size);
      _expectNoEllipsis();
    });
  }

  testWidgets('resizing between phone and desktop keeps the CV clean', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);

    final errors = await _collectErrors(() async {
      await tester.pumpWidget(const MaterialApp(home: MyCvView()));
      await tester.pump(const Duration(milliseconds: 300));
      await _scrollThroughPage(tester);
      for (final size in const [
        Size(357, 800),
        Size(1280, 900),
        Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
    });

    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
