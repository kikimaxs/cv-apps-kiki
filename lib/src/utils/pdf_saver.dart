import 'dart:typed_data';
import 'package:cv_apps/src/utils/pdf_saver_stub.dart'
    if (dart.library.js_interop) 'package:cv_apps/src/utils/pdf_saver_web.dart'
    as impl;

Future<void> savePdf(Uint8List bytes, String filename) {
  return impl.savePdf(bytes, filename);
}
