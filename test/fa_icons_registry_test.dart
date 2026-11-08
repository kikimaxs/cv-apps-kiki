import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `flutter build web --release` shrinks the Font Awesome fonts to the glyphs
/// its icon tree shaker finds. With font_awesome_flutter 11 it only finds
/// icons referenced from home_main.dart, so an icon used only in another file
/// renders as an empty box on the web (play, arrow-left, clock, ... did).
/// home_main.dart therefore lists every such icon in `kHomeFaIcons`; this test
/// fails when an icon is used somewhere without also appearing there.
void main() {
  test(
    'every FontAwesomeIcons.* used in lib/ is also named in home_main.dart',
    () {
      final reference = RegExp(r'FontAwesomeIcons\.(\w+)');
      final homeMain = File(
        'lib/src/modules/home/home_main.dart',
      ).readAsStringSync();
      final known = reference
          .allMatches(homeMain)
          .map((m) => m.group(1)!)
          .toSet();

      final missing = <String>{};
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in dartFiles) {
        for (final match in reference.allMatches(file.readAsStringSync())) {
          final name = match.group(1)!;
          if (!known.contains(name)) missing.add('$name (${file.path})');
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'Add these to kHomeFaIcons in home_main.dart so the web release font keeps them.',
      );
    },
  );
}
