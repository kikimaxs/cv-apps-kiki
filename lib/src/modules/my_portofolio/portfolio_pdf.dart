// Builds a standalone, print-friendly PDF of the portfolio: real selectable
// text (not a screenshot), so it stays small and crisp at any zoom. It is
// deliberately shorter than the 12-slide web page (one page per project
// instead of a collage/intro/challenge slide for each) since a document
// people print or attach to an email reads better tight than paced out.
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _assetDir = 'assets/img/portfolio/';
const _ink = PdfColor.fromInt(0xFF0F172A);

Future<Uint8List> buildPortfolioPdf() async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Carlito-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Carlito-Bold.ttf'),
  );
  final italic = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Carlito-Italic.ttf'),
  );
  final boldItalic = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Carlito-BoldItalic.ttf'),
  );

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
    ),
  );

  final cover = await _img('cover.jpg');
  final mola = (
    logo: await _img('mola_logo.png'),
    shot: await _img('mola_app.jpg'),
  );
  final durioo = (
    logo: await _img('durioo_logo.png'),
    shot: await _img('durioo_promo.jpg'),
  );
  final hadir = (
    icon: await _img('hadir_icon.png'),
    shot: await _img('hadir_2.jpg'),
  );
  final lifeline = (
    logo: await _img('lifeline_logo.png'),
    shot: await _img('lifeline_login.png'),
  );
  final profileData = await rootBundle.load('assets/img/photo_profile.jpg');
  final profile = pw.MemoryImage(profileData.buffer.asUint8List());

  doc.addPage(_coverPage(cover));
  doc.addPage(
    _projectPage(
      logo: mola.logo,
      logoWidth: 170,
      shot: mola.shot,
      gradient: const [0xFF63DFE7, 0xFF2F8FCF, 0xFF0A4DAA],
      blocks: [
        (
          'What is the MOLA TV Apps ?',
          'MOLA is a Live streaming video entertainment application, MOLA '
              'itself is cross-platform based including Android and iOS using '
              '**React Native** with **Javascript** programming language, MOLA '
              'has main content that is more about Sports such as Football, UFC '
              'and popular movie content for adults and children, besides mobile '
              'MOLA already has its own device using MOLA TV box, and the MOLA '
              'has been uploaded to Playstore and Appstore.',
        ),
        (
          'My Achievement at MOLA TV ?',
          'In Indonesia, The app reached 700K downloads (iOS & Android since '
              '2020) and 2.3 million viewers during the Euro 2022 England vs '
              'Spain match.',
        ),
        (
          'The most challenging job',
          'I worked on a live quiz feature at MOLA, handling quiz delivery and '
              'answer submission using WebSocket with temporary storage before '
              'sending data to the API to prevent data loss. A major issue '
              'occurred when the server went down during a live session, '
              'causing users to be unable to participate. The solution was to '
              'implement a temporary maintenance mode while coordinating with '
              'Mobile, Backend, and Infra teams.',
        ),
      ],
    ),
  );
  doc.addPage(
    _projectPage(
      logo: durioo.logo,
      logoWidth: 120,
      shot: durioo.shot,
      gradient: const [0xFFEE7C45, 0xFFF3A864, 0xFFF9CD88],
      blocks: [
        (
          'What is the Durioo+ Apps ?',
          'Durioo+ is a cross-platform video streaming app (Android & iOS) '
              'built with **React Native Expo** and **TypeScript**, featuring '
              'Muslim-friendly children’s content. It includes parental '
              'controls to manage kids’ viewing and is also available on '
              'Android TV and Samsung TV (published on Play Store and App '
              'Store).',
        ),
        (
          'My Achievement at Durioo+ ?',
          'Since March 2024, the app has reached 60K downloads (iOS & '
              'Android) in Malaysia, with over 3 million total video views '
              'based on backend tracking. It is now expanding internationally, '
              'with higher numbers across multiple countries.',
        ),
        (
          'The most challenging job',
          'I developed a video player using Expo AV for the Durioo App V1, '
              'featuring TV casting, offline download, subtitles, video '
              'quality selection, and next/previous playback. The main '
              'challenge was playback errors due to unsupported ASF video '
              'format; the solution was to fall back to the highest quality '
              'MP4 when ASF fails to load.',
        ),
      ],
    ),
  );
  doc.addPage(
    _projectPage(
      logo: hadir.icon,
      logoWidth: 70,
      logoRadius: 16,
      shot: hadir.shot,
      gradient: const [0xFFEE7C45, 0xFFF3A864, 0xFFF9CD88],
      blocks: [
        (
          'What is the HadIR Apps ?',
          'HadIR is an internal application designed to monitor employee '
              'productivity and daily activities. It allows employees to '
              'manage attendance (WFA/WFO), track activities like meetings or '
              'training, and ensures valid check-ins using map coordinates '
              '(with fake GPS detection). Managers and HRD can monitor '
              'performance, while features like meeting room booking, '
              'overtime tracking, and expense claims are also supported.',
        ),
      ],
    ),
  );
  doc.addPage(
    _projectPage(
      logo: lifeline.logo,
      logoWidth: 220,
      logoRadius: 0,
      shot: lifeline.shot,
      gradient: const [0xFF4A1140, 0xFF7E2A5F, 0xFFB04C7C],
      light: true,
      blocks: [
        (
          'What is the LifelineConnect Apps ?',
          'LifeLine is a health and safety ecosystem application built using '
              'Flutter, with state management using Bloc, Provider, and '
              'Cubit. It connects devices such as smartwatches, digital '
              'dispensers, AirPods, and smart locks to a smartphone, '
              'collecting health data, tracking location, and sharing it with '
              'doctors or family members (Care Circle).',
        ),
        (
          'A cross-border, ongoing project',
          'This cross-platform project (iOS & Android) was developed for a '
              'client in China (a state-owned enterprise), featuring its own '
              'branded IoT devices. The project is still ongoing and has not '
              'yet been released on the App Store or Play Store.',
        ),
      ],
    ),
  );
  doc.addPage(_aboutPage(profile));

  return doc.save();
}

Future<pw.MemoryImage> _img(String name) async {
  final data = await rootBundle.load('$_assetDir$name');
  return pw.MemoryImage(data.buffer.asUint8List());
}

pw.Page _coverPage(pw.MemoryImage cover) {
  final format = PdfPageFormat.a4.landscape;
  return pw.Page(
    pageFormat: format,
    margin: pw.EdgeInsets.zero,
    build: (context) => pw.SizedBox(
      width: format.width,
      height: format.height,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(child: pw.Image(cover, fit: pw.BoxFit.cover)),
          pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'MY PORTFOLIO',
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'KIKI TRIANSYAH',
                  style: pw.TextStyle(fontSize: 16, color: PdfColors.white),
                ),
                pw.Text(
                  'Software Developer Apps Mobile',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Page _projectPage({
  required pw.MemoryImage logo,
  required double logoWidth,
  required pw.MemoryImage shot,
  required List<int> gradient,
  required List<(String, String)> blocks,
  double logoRadius = 12,
  bool light = false,
}) {
  final color = light ? PdfColors.white : _ink;
  return pw.Page(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(28),
    build: (context) => pw.Container(
      padding: const pw.EdgeInsets.all(28),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(18),
        gradient: pw.LinearGradient(
          colors: [for (final c in gradient) PdfColor.fromInt(c)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.ClipRRect(
                  horizontalRadius: logoRadius,
                  verticalRadius: logoRadius,
                  child: pw.Image(logo, width: logoWidth),
                ),
                pw.SizedBox(height: 16),
                for (final b in blocks) ...[
                  pw.Text(
                    b.$1,
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.RichText(
                    text: pw.TextSpan(
                      style: pw.TextStyle(fontSize: 9.5, color: color),
                      children: _richSpans(
                        b.$2,
                        pw.TextStyle(fontSize: 9.5, color: color),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            flex: 2,
            child: pw.ClipRRect(
              horizontalRadius: 14,
              verticalRadius: 14,
              child: pw.Image(shot, fit: pw.BoxFit.cover),
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Page _aboutPage(pw.MemoryImage profile) {
  const contacts = [
    (
      'Email',
      'kiki.triansyah93@gmail.com',
      'mailto:kiki.triansyah93@gmail.com',
    ),
    (
      'LinkedIn',
      'linkedin.com/in/kiki-triansyah',
      'https://www.linkedin.com/in/kiki-triansyah/',
    ),
    ('WhatsApp', '+6287728020907', 'https://wa.me/6287728020907'),
    ('GitHub', '@kikimaxs', 'https://github.com/kikimaxs'),
    ('GitLab', '@kikitriansyah', 'https://gitlab.com/kikitriansyah'),
    ('Discord', '@kikimaxs', null),
  ];
  final body = pw.TextStyle(fontSize: 10.5, color: _ink);
  return pw.Page(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(32),
    build: (context) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 11,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.ClipRRect(
                horizontalRadius: 14,
                verticalRadius: 14,
                child: pw.Image(profile, width: 110),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'KIKI TRIANSYAH',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Software Developer Apps Mobile',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'About Me',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.RichText(
                text: pw.TextSpan(
                  style: body,
                  children: _richSpans(
                    'I am Kiki Triansyah, a Software Engineer | Mobile '
                    'Developer with 6 years of experience delivering '
                    'scalable, high-impact applications. I specialize in '
                    '**React Native**, **JavaScript**, and **TypeScript**, '
                    'with additional experience in **Swift (SwiftUI)** and '
                    '**Flutter**. I also have backend experience using '
                    '**Node.js**, **Express.js**, and databases such as '
                    '**MySQL** and **SQLite**.\n\n'
                    'Beyond development, I focus on building products that '
                    'drive user engagement and business value, collaborating '
                    'closely with teams to align technical solutions with '
                    'product and marketing goals.\n\n'
                    'I hold a Bachelor’s degree and am currently open to '
                    'new opportunities, ready to contribute ++Immediately++ '
                    'or ++ASAP++ going to ++Onsite++ or ++Remote++, in '
                    'Indonesia or globally.',
                    body,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Expanded(
          flex: 7,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Contact :',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              for (final c in contacts)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '${c.$1}: ',
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.TextSpan(
                          text: c.$2,
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            color: c.$3 == null ? _ink : PdfColors.blue800,
                            decoration: c.$3 == null
                                ? null
                                : pw.TextDecoration.underline,
                          ),
                          annotation: () {
                            final url = c.$3;
                            return url == null ? null : pw.AnnotationUrl(url);
                          }(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// `**text**` -> bold italic, `++text++` -> bold, `__text__` -> underline.
/// Mirrors `_rich()` in the web view so the PDF and the page agree.
List<pw.InlineSpan> _richSpans(String text, pw.TextStyle base) {
  final pattern = RegExp(r'\*\*(.+?)\*\*|\+\+(.+?)\+\+|__(.+?)__');
  final spans = <pw.InlineSpan>[];
  var cursor = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(pw.TextSpan(text: text.substring(cursor, m.start)));
    }
    if (m.group(1) != null) {
      spans.add(
        pw.TextSpan(
          text: m.group(1),
          style: base.copyWith(
            fontWeight: pw.FontWeight.bold,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    } else if (m.group(2) != null) {
      spans.add(
        pw.TextSpan(
          text: m.group(2),
          style: base.copyWith(fontWeight: pw.FontWeight.bold),
        ),
      );
    } else {
      spans.add(
        pw.TextSpan(
          text: m.group(3),
          style: base.copyWith(decoration: pw.TextDecoration.underline),
        ),
      );
    }
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(pw.TextSpan(text: text.substring(cursor)));
  }
  return spans;
}
