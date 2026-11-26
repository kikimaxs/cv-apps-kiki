import 'package:cv_apps/src/components/app_loader.dart';
import 'package:cv_apps/src/components/app_loader_overlay.dart';
import 'package:cv_apps/src/components/app_preload_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Stack(children: [const Text('page'), child]));

/// Whether the overlay still covers the page (it lets taps through once done).
bool _covers(WidgetTester tester) => !tester
    .widget<IgnorePointer>(
      find.descendant(
        of: find.byType(AppLoaderOverlay),
        matching: find.byType(IgnorePointer),
      ),
    )
    .ignoring;

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('a page that is ready at once shows no loader', (tester) async {
    await tester.pumpWidget(
      _host(const AppLoaderOverlay(done: true, background: Colors.black)),
    );
    await _frames(tester, 30);
    expect(find.byType(AppLoader), findsNothing);
    expect(_covers(tester), isFalse);
  });

  testWidgets('a slow page shows the loader only after the short delay', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AppLoaderOverlay(done: false, background: Colors.black)),
    );
    await _frames(tester, 5); // about 80 ms
    expect(find.byType(AppLoader), findsNothing);
    await _frames(tester, 20); // past 250 ms
    expect(find.byType(AppLoader), findsOneWidget);
    expect(_covers(tester), isTrue);
  });

  testWidgets('the page is released as soon as it is done', (tester) async {
    final done = ValueNotifier<bool>(false);
    addTearDown(done.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: done,
        builder: (context, value, _) =>
            _host(AppLoaderOverlay(done: value, background: Colors.black)),
      ),
    );
    await _frames(tester, 30);
    expect(find.byType(AppLoader), findsOneWidget);
    done.value = true;
    await _frames(tester, 40); // the fade takes 320 ms
    expect(_covers(tester), isFalse);
  });

  testWidgets('the gate releases the page once its assets are ready', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppPreloadGate(
          assets: const [],
          background: Colors.black,
          child: const Text('page'),
        ),
      ),
    );
    await _frames(tester, 20);
    expect(_covers(tester), isFalse);
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('the gate releases the page at the time limit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppPreloadGate(
          assets: const ['assets/img/photo_profile.jpg'],
          background: Colors.black,
          timeout: const Duration(milliseconds: 300),
          child: const Text('page'),
        ),
      ),
    );
    await _frames(tester, 40); // about 640 ms
    expect(_covers(tester), isFalse);
    expect(find.text('page'), findsOneWidget);
  });
}
