import 'package:cv_apps/src/modules/my_portofolio/portfolio_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the portfolio PDF builds and looks like a real PDF', (
    tester,
  ) async {
    final bytes = await buildPortfolioPdf();
    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
