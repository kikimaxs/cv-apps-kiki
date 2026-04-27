import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cv_apps/src/utils/pdf_saver.dart';
import 'package:cv_apps/src/components/icon_svg.dart';
import 'package:go_router/go_router.dart';

enum _PdfQuality {
  standard(2.0, 'Standard'),
  high(2.5, 'High'),
  ultra(3.0, 'Ultra');

  final double pixelRatio;
  final String label;
  const _PdfQuality(this.pixelRatio, this.label);
}

class MyCvView extends StatelessWidget {
  const MyCvView({super.key});
  static final GlobalKey _cvBoundaryKey = GlobalKey();
  static final ValueNotifier<bool> _isExporting = ValueNotifier<bool>(false);
  static final ValueNotifier<double> _exportProgress = ValueNotifier<double>(0);
  static final List<_PdfQuality> _exportOptions = _PdfQuality.values;
  static final ValueNotifier<bool> _showHeader = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showHeader,
      builder: (context, show, _) => Scaffold(
        backgroundColor: Colors.white,
        appBar: show
            ? AppBar(
                leading: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                ),
                title: const Text('My CV'),
                actions: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _isExporting,
                    builder: (context, exporting, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: exporting
                                ? 'Exporting...'
                                : 'Quick Export (Single Long Page - Standard)',
                            onPressed: exporting
                                ? null
                                : () =>
                                      _exportPdf(context, _PdfQuality.standard),
                            icon: exporting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf),
                          ),
                          PopupMenuButton<_PdfQuality>(
                            enabled: !exporting,
                            tooltip: 'More Export Qualities',
                            icon: const Icon(Icons.arrow_drop_down),
                            onSelected: (option) => _exportPdf(context, option),
                            itemBuilder: (context) => _exportOptions
                                .map(
                                  (opt) => PopupMenuItem<_PdfQuality>(
                                    value: opt,
                                    child: Text(
                                      'Export Single Long Page (${opt.label})',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              )
            : null,
        body: ValueListenableBuilder<bool>(
          valueListenable: _isExporting,
          builder: (context, exporting, _) => NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _showHeader.value = n.metrics.pixels <= 0;
              return false;
            },
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1A2F43),
                        Color(0xFF203A53),
                        Color(0xFF16283A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -160,
                        top: -140,
                        child: Container(
                          width: 420,
                          height: 420,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.24),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -170,
                        bottom: -180,
                        child: Container(
                          width: 440,
                          height: 440,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.18),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 900;
                            final double w = constraints.maxWidth;
                            final double scale = w <= 320
                                ? 0.75
                                : w < 360
                                ? 0.80
                                : w < 420
                                ? 0.85
                                : w < 480
                                ? 0.88
                                : w < 540
                                ? 0.90
                                : w < 640
                                ? 0.93
                                : w < 700
                                ? 0.95
                                : 1.0;
                            return SingleChildScrollView(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1100,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      top: 0,
                                      bottom: 16,
                                    ),
                                    child: MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                        textScaler: TextScaler.linear(scale),
                                      ),
                                      child: RepaintBoundary(
                                        key: _cvBoundaryKey,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF1A2F43),
                                                Color(0xFF203A53),
                                                Color(0xFF16283A),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Positioned(
                                                right: -160,
                                                top: -140,
                                                child: Container(
                                                  width: 420,
                                                  height: 420,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        Colors.white
                                                            .withOpacity(0.24),
                                                        Colors.white
                                                            .withOpacity(0.0),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                left: -170,
                                                bottom: -180,
                                                child: Container(
                                                  width: 440,
                                                  height: 440,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        Colors.white
                                                            .withOpacity(0.18),
                                                        Colors.white
                                                            .withOpacity(0.0),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _Header(scale: scale),
                                                  const SizedBox(height: 16),
                                                  isWide
                                                      ? Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Transform.translate(
                                                              offset:
                                                                  const Offset(
                                                                    -16,
                                                                    0,
                                                                  ),
                                                              child: SizedBox(
                                                                width: 320,
                                                                child:
                                                                    _CvSidebar(
                                                                      scale:
                                                                          scale,
                                                                    ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 24,
                                                            ),
                                                            Expanded(
                                                              child: _CvContent(
                                                                isWide: isWide,
                                                                scale: scale,
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Transform.translate(
                                                              offset:
                                                                  const Offset(
                                                                    -16,
                                                                    0,
                                                                  ),
                                                              child: _CvSidebar(
                                                                scale: scale,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 16,
                                                            ),
                                                            _CvContent(
                                                              isWide: isWide,
                                                              scale: scale,
                                                            ),
                                                          ],
                                                        ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (exporting) _buildExportProgressOverlay(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, _PdfQuality option) async {
    if (_isExporting.value) return;
    _isExporting.value = true;
    _exportProgress.value = 0;
    _exportProgress.value = 10;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await WidgetsBinding.instance.endOfFrame;
    _exportProgress.value = 20;
    try {
      final boundary =
          _cvBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(
        pixelRatio: option.pixelRatio,
      );
      _exportProgress.value = 55;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      _exportProgress.value = 70;
      final pngBytes = byteData.buffer.asUint8List();
      final memImg = pw.MemoryImage(pngBytes);

      final format = PdfPageFormat.a4;
      final pageW = format.width;
      final imgW = image.width.toDouble();
      final imgH = image.height.toDouble();
      final displayedH = pageW * imgH / imgW;
      final longFormat = PdfPageFormat(pageW, displayedH);
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: longFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.SizedBox(
            width: pageW,
            height: displayedH,
            child: pw.Image(memImg, width: pageW, height: displayedH),
          ),
        ),
      );
      _exportProgress.value = 82;
      final bytes = await doc.save();
      _exportProgress.value = 94;
      if (kIsWeb) {
        await savePdf(bytes, 'my_cv.pdf');
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      }
      _exportProgress.value = 100;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF export completed. Download started.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to export PDF')));
      }
    } finally {
      _isExporting.value = false;
      _exportProgress.value = 0;
    }
  }

  Widget _buildExportProgressOverlay(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ValueListenableBuilder<double>(
              valueListenable: _exportProgress,
              builder: (context, progress, _) {
                final clamped = progress.clamp(0, 100);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generating PDF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${clamped.toStringAsFixed(0)}% completed',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: clamped / 100,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  pw.Widget _pdfExperience({
    required String company,
    required String period,
    required String role,
    required List<String> points,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                company,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(period, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          role,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: points
              .map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: const pw.TextStyle(fontSize: 11)),
                      pw.Expanded(
                        child: pw.Text(
                          e,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _pdfProject({
    required String name,
    required String period,
    required String summary,
    required List<String> details,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(period, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(summary, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: details
              .map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(fontSize: 11)),
                      pw.Expanded(
                        child: pw.Text(
                          e,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _pdfEducation({
    required String degree,
    required String period,
    required String school,
    required String gpa,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                degree,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(period, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          school,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(gpa, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _CvSidebar extends StatelessWidget {
  final double scale;
  const _CvSidebar({required this.scale});

  Color get _bg => const Color(0xFF1C3144);

  @override
  Widget build(BuildContext context) {
    final topShade = Color.alphaBlend(Colors.white.withOpacity(0.08), _bg);
    final bottomShade = Color.alphaBlend(Colors.black.withOpacity(0.08), _bg);
    return Container(
      margin: EdgeInsets.only(right: 8 * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topShade, bottomShade],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.zero,
          bottomLeft: Radius.zero,
          topRight: Radius.circular(56 * scale),
          bottomRight: Radius.circular(56 * scale),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0C1826).withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20 * scale,
        right: 2 * scale,
        top: 24 * scale,
        bottom: 24 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _SectionTitle(color: Colors.white, text: 'TOOLS'),
          SizedBox(height: 16 * scale),
          _WrapChips(
            scale: scale,
            items: [
              'Expo',
              'EAS',
              'Prettier',
              'TestFlight',
              'Figma',
              'Adobe XD',
              'VS Code',
              'Postman',
              'My SQL',
              'Xcode',
              'Android Studio',
              'Reactotron',
              'Flutter Dev Tools',
              'GIT',
              'CI/CD',
              'Node JS',
              'JIRA',
              'Trello',
              'Bash',
              'Firebase',
              'Bugsnag',
              'Google Cloud Monitoring',
              'New Relic',
              'Sentry',
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(color: Colors.white, text: 'TECH STACK'),
          SizedBox(height: 12 * scale),
          _WrapChips(
            scale: scale,
            items: const [
              'Dart',
              'Flutter',
              'Bloc',
              'Provider',
              'React Native',
              'React JS',
              'Javascript',
              'Typescript',
              'Redux Saga',
              'Redux Thunk',
              'Redux Toolkit',
              'Express JS',
              'Next JS',
              'Node JS',
              'SQL Query',
              'Swift',
              'SwiftUI',
              'UIKit',
              'Kotlin',
              'Objective-C',
              'C#',
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(color: Colors.white, text: 'SKILLS'),
          SizedBox(height: 12 * scale),
          _WrapChips(
            scale: scale,
            items: const [
              'Model-View-ViewModel',
              'Clean Architecture',
              'Unit & Integration Testing',
              'Scrum',
              'Agile',
              'RESTful APIs',
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(color: Colors.white, text: 'LANGUAGES'),
          SizedBox(height: 12 * scale),
          _WrapChips(scale: scale, items: const ['English', 'Indonesian']),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double scale;
  const _Header({required this.scale});
  Color get _start => Colors.white.withOpacity(0.94);
  Color get _end => Colors.white.withOpacity(0.88);
  Color get _pillBg => const Color(0xFF2E3E52);
  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    final bool isWide = w >= 900;
    final double baseSize = 150 * scale;
    final double blockWidth = isWide ? 320 : baseSize;
    final double blockHeight = isWide ? 220 * scale : baseSize;
    final double circleSize = blockHeight * 0.82;
    final double ringThickness = isWide ? 6 * scale : 5 * scale;
    final double avatarRadius = circleSize / 2 - ringThickness;
    final double rightRadius = 56 * scale;
    final topPill = Color.alphaBlend(Colors.white.withOpacity(0.08), _pillBg);
    final bottomPill = Color.alphaBlend(
      Colors.black.withOpacity(0.08),
      _pillBg,
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_start, _end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.only(left: 0, right: 16 * scale, bottom: 16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.translate(
                offset: const Offset(-16, 0),
                child: SizedBox(
                  width: blockWidth,
                  height: blockHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [topPill, bottomPill],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.zero,
                              bottomLeft: Radius.zero,
                              topRight: Radius.circular(rightRadius),
                              bottomRight: Radius.circular(rightRadius),
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.24),
                                blurRadius: 16,
                                spreadRadius: 0,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: const Color(0xFF0C1826).withOpacity(0.1),
                                blurRadius: 6,
                                spreadRadius: 0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: ringThickness,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/img/photo_profile.jpg',
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey.shade300,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.person,
                                      size: avatarRadius,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KIKI TRIANSYAH',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                    ),
                    Text(
                      'Software Developer Apps Mobile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '(React Native Developer & IOS Developer & Flutter)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          _ContactBar(
            bg: _pillBg,
            scale: scale,
            items: const [
              (Icons.phone, '+6287728020907'),
              (Icons.email, 'kiki.triansyah93@gmail.com'),
              (Icons.link, 'linkedin.com/in/kiki-triansyah'),
              (Icons.location_on, 'Jakarta, Indonesia'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bg;
  final double scale;
  const _ContactPill({
    required this.icon,
    required this.text,
    required this.bg,
    required this.scale,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18 * scale),
          SizedBox(width: 8 * scale),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  final List<(IconData, String)> items;
  final Color bg;
  final double scale;
  const _ContactBar({
    required this.items,
    required this.bg,
    required this.scale,
  });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 768;
        final topShade = Color.alphaBlend(Colors.white.withOpacity(0.06), bg);
        final bottomShade = Color.alphaBlend(
          Colors.black.withOpacity(0.06),
          bg,
        );

        Widget buildItem((IconData, String) it, int index) {
          Widget leading;
          if (index == 0) {
            leading = SvgIcon(
              name: 'whatsapp',
              size: 18 * scale,
              color: Colors.white,
            );
          } else if (index == 2) {
            leading = SvgIcon(
              name: 'linkedin',
              size: 18 * scale,
              color: Colors.white,
            );
          } else {
            leading = Icon(it.$1, color: Colors.white, size: 18 * scale);
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              SizedBox(width: 8 * scale),
              Flexible(
                child: Text(
                  it.$2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          );
        }

        if (isDesktop) {
          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 2 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: 28 * scale,
              vertical: 14 * scale,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [topShade, bottomShade],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.26),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF0C1826).withOpacity(0.12),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Wrap(
              spacing: 24 * scale,
              runSpacing: 8 * scale,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: List.generate(
                items.length,
                (i) => buildItem(items[i], i),
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(vertical: 2 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 13 * scale,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [topShade, bottomShade],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.26),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF0C1826).withOpacity(0.12),
                blurRadius: 6,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: buildItem(items[0], 0)),
                  SizedBox(width: 24 * scale),
                  Expanded(child: buildItem(items[1], 1)),
                ],
              ),
              SizedBox(height: 8 * scale),
              Row(
                children: [
                  Expanded(child: buildItem(items[2], 2)),
                  SizedBox(width: 24 * scale),
                  Expanded(child: buildItem(items[3], 3)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CvContent extends StatelessWidget {
  final bool isWide;
  final double scale;
  const _CvContent({required this.isWide, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(isWide ? 12 : 10),
      ),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderRail(
            icon: Icons.person,
            scale: scale,
            lineHeight: 6 * scale + 2,
            header: _ContentHeader(color: Colors.black, text: 'PROFILE'),
          ),
          _TimelineItem(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text(
                'A strategic Mobile Developer who transforms business objectives into high-impact mobile applications. I architect and deliver robust, scalable, and user-centric apps from concept to launch, leveraging deep expertise in Flutter, React Native, and native iOS/Android development. My end-to-end ownership—spanning from product discovery and system design to App Store and Play Store deployment—consistently accelerates development cycles and enhances user engagement. I thrive in collaborative environments, translating complex requirements into reliable, high-performance software that drives measurable business growth.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            isLast: true,
            scale: scale,
            gap: 0,
            dotTop: 44 * scale,
            rightTopSpace: 4 * scale,
          ),
          _RailGap(height: 24, scale: scale),
          _TimelineSection(
            icon: Icons.work,
            title: 'WORK EXPERIENCE',
            scale: scale,
            lineHeight: 6 * scale + 2,
            color: Colors.black,
            itemGap: 16,
            dotTop: 8 * scale,
            rightTopSpace: 4 * scale,
            items: [
              _ExperienceItem(
                company: 'SEI ASIA',
                period: 'Freelance Project : 2025 December – 2025 March',
                role: 'Mobile Developer • Flutter Developer',
                points: [
                  'Develop LifelineConnect mobile application for Android & iOS platforms',
                  'Build the application using Dart (Flutter) with Bloc state management and Clean Architecture principles',
                  'Implement architecture patterns including MVVM, along with Go Router and Provider for navigation and state handling',
                  'Develop core features such as member management, group management, chat, voice chat, and voice call',
                  'Integrate IoT device connectivity (e.g., Smart Watch, Dispenser, AirPods, Smart Door Lock) with the mobile application',
                  'Integrate backend services using RESTful APIs',
                  'Manage source code and CI/CD pipelines using GitHub CI/CD',
                ],
              ),
              _ExperienceItem(
                company: 'AKASIA',
                period: 'Contract Base Project : 2025 Juli – 2025 September',
                role: 'Mobile Developer • React Native Developer',
                points: [
                  'Develop Hadir application for client PT FWD Insurance Indonesia',
                  'Build the project end-to-end, from development to deployment on internal company server',
                  'Develop cross-platform mobile applications (Android & iOS) using React Native',
                  'Utilize modern tech stack including TypeScript, Tailwind CSS, Redux Saga, and React Navigation',
                  'Implement core features such as user attendance (clock in/out), room booking, and overtime management',
                  'Apply geofencing validation (±300m radius) to ensure attendance can only be performed within office area',
                  'Implement anti–fake GPS detection to prevent location spoofing',
                  'Develop reporting and validation systems for user attendance',
                  'Integrate backend services using RESTful APIs',
                  'Manage source code and CI/CD pipelines using Azure CI/CD',
                ],
              ),
              _ExperienceItem(
                company: 'Durioo+',
                period: 'Contract : 2023 September – 2025 January',
                role: 'Mobile Apps Developer • React Native Developer',
                points: [
                  'Develop cross-platform mobile applications (Android & iOS) using Expo React Native',
                  'Build projects end-to-end, from development to deployment on App Store & Play Store',
                  'Implement custom components, including Video Player and tailored UI/UX features',
                  'Integrate backend services using RESTful APIs',
                  'Manage Over-the-Air (OTA) updates for seamless app releases',
                  'Implement push notifications and user tracking using Firebase',
                  'Handle subscription and in-app purchase systems via Play Store and App Store',
                  'Develop features such as offline video playback, TV casting, and video download for subscribed users',
                  'Manage source code and CI/CD pipelines using GitLab CI/CD',
                ],
              ),
              _ExperienceItem(
                company: 'MOLA',
                period: 'Fulltime : 2020 January – 2023 January',
                role:
                    'Mobile Engineer • React Native Developer & iOS Developer',
                points: [
                  'Develop cross-platform mobile applications (Android & iOS) using React Native, and native iOS applications using SwiftUI',
                  'Build projects end-to-end, from development to deployment on App Store and Play Store',
                  'Implement native module bridging (e.g., Video Player) for iOS and Android integration',
                  'Develop key features such as Live Quiz, Inbox, Push Notifications, Social Media Sharing, and Subscription systems',
                  'Integrate user analytics tracking and monitoring tools (e.g., Bugsnag, New Relic)',
                  'Integrate backend services via RESTful APIs',
                  'Manage source code and CI/CD pipelines using GitLab CI/CD',
                ],
              ),
              _ExperienceItem(
                company: 'Binar Academy',
                period: 'Contract : 2019 July – 2020 January',
                role: 'Talent Frontend Developer • React Native Developer',
                points: [
                  'Develop and maintain MOLA application for client (MOLA TV)',
                  'Develop mobile applications for Android & iOS platforms (MOLA & Super Soccer Apps)',
                  'Build and maintain features such as Article and Podcast components in Super Soccer Apps',
                  'Handle end-to-end mobile development and deployment to App Store & Play Store',
                  'Manage source code and CI/CD pipelines using GitLab CI/CD',
                ],
              ),
            ],
          ),
          _RailGap(height: 24, scale: scale),
          _TimelineSection(
            icon: Icons.folder_open,
            title: 'PROJECT',
            scale: scale,
            lineHeight: 6 * scale + 2,
            color: Colors.black,
            itemGap: 16,
            dotTop: 8 * scale,
            rightTopSpace: 4 * scale,
            items: [
              _ProjectItem(
                name: 'LifelineConnect Apps',
                period: '2025 December – 2026 March',
                summary: 'Social Media Apps',
                details: [
                  'Member management, group management, chat, voice chat, and voice call',
                  'IoT device connectivity (e.g., Smart Watch, Dispenser, AirPods, Smart Door Lock) with the mobile application',
                ],
              ),
              _ProjectItem(
                name: 'Hadir Apps (Internal)',
                period: '2025 July – 2025 September',
                summary: 'HR Apps',
                details: [
                  'Absence Clock In and Out, Booking Room, Overtime, Report',
                ],
              ),
              _ProjectItem(
                name: 'Durioo+ Apps',
                period: '2023 September – 2025 January',
                summary:
                    'Multi Platform Android Mobile and iOS Mobile, Android TV, TVOS',
                details: ['Watching Movies content for kids muslim'],
              ),
              _ProjectItem(
                name: 'MOLA Apps',
                period: '2019 July – 2023 January',
                summary:
                    'Multi Platform Android Mobile and iOS Mobile, Android TV, TVOS',
                details: [
                  'Watching Movies content for kids & adult',
                  'Live Streaming sport football and many',
                ],
              ),
            ],
          ),
          _RailGap(height: 24, scale: scale),
          _TimelineSection(
            icon: Icons.school,
            title: 'EDUCATION',
            scale: scale,
            lineHeight: 6 * scale + 2,
            color: Colors.black,
            itemGap: 16,
            dotTop: 8 * scale,
            rightTopSpace: 4 * scale,
            items: const [
              _EducationItem(
                degree: 'Bachelor of Information Technology',
                period: '2012 - 2016',
                school: 'Universitas Muhammadiyah Yogyakarta',
                gpa: 'GPA: 3.47 / 4.00',
              ),
              _EducationItem(
                degree: 'Training Team Project Binar Academy Batch 8',
                period: '2018 July - 2018 Oct ',
                school: 'Binar Academy at Yogyakarta',
                gpa: 'Frontend Developer As React JS',
              ),
              _EducationItem(
                degree: 'Training Project Binar+ Batch 1',
                period: '2018 Des - 2019 Mar',
                school: 'Binar Academy at BSD City',
                gpa: 'Mobile Developer As React Native',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final double scale;
  final double lineHeight;
  final Color color;
  final double itemGap;
  final double dotTop;
  final double rightTopSpace;
  final List<Widget> items;

  const _TimelineSection({
    required this.icon,
    required this.title,
    required this.scale,
    required this.lineHeight,
    required this.color,
    required this.itemGap,
    required this.dotTop,
    required this.rightTopSpace,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderRail(
          icon: icon,
          scale: scale,
          lineHeight: lineHeight,
          header: _ContentHeader(color: color, text: title),
        ),
        ...List.generate(items.length, (index) {
          final bool isLast = index == items.length - 1;
          return _TimelineItem(
            scale: scale,
            gap: isLast ? 0 : itemGap,
            dotTop: dotTop,
            rightTopSpace: rightTopSpace,
            isLast: isLast,
            child: items[index],
          );
        }),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final Color color;
  final String text;
  const _SectionTitle({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, width: double.infinity, color: color),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final double scale;
  const _IconText({
    required this.icon,
    required this.text,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20 * scale),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _WrapChips extends StatelessWidget {
  final List<String> items;
  final double scale;
  const _WrapChips({required this.items, required this.scale});

  @override
  Widget build(BuildContext context) {
    final double sp = 8 * scale;
    return Wrap(
      spacing: sp,
      runSpacing: sp,
      children: items
          .map(
            (e) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 6 * scale,
              ),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                e,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  final Color color;
  final String text;
  const _ContentHeader({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: color, width: 2)),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExperienceItem extends StatelessWidget {
  final String company;
  final String period;
  final String role;
  final List<String> points;
  const _ExperienceItem({
    required this.company,
    required this.period,
    required this.role,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                company,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              period,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          role,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: points
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(e)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ProjectItem extends StatelessWidget {
  final String name;
  final String period;
  final String summary;
  final List<String> details;
  const _ProjectItem({
    required this.name,
    required this.period,
    required this.summary,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              period,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          summary,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(e)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _EducationItem extends StatelessWidget {
  final String degree;
  final String period;
  final String school;
  final String gpa;

  const _EducationItem({
    required this.degree,
    required this.period,
    required this.school,
    required this.gpa,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                degree,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              period,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          school,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(gpa, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final double scale;
  const _SectionIcon({required this.icon, required this.scale});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28 * scale,
      height: 28 * scale,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, color: Colors.white, size: 16 * scale),
    );
  }
}

class _RailGap extends StatelessWidget {
  final double height;
  final double scale;
  final bool showDot;
  const _RailGap({
    required this.height,
    required this.scale,
    this.showDot = false,
  });
  @override
  Widget build(BuildContext context) {
    final Color line = Colors.black;
    final Color dot = Colors.black;
    final double railWidth = 28 * scale;
    final double lineWidth = 2;
    final double dotSize = 10 * scale;
    final double dotTop = (height - dotSize) / 2;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: railWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: (railWidth - lineWidth) / 2,
                  top: -3,
                  bottom: -3,
                  child: Container(width: lineWidth, color: line),
                ),
                if (showDot)
                  Positioned(
                    left: (railWidth - dotSize) / 2,
                    top: dotTop < 0 ? 0 : dotTop,
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: dot, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _SectionHeaderRail extends StatelessWidget {
  final IconData icon;
  final double scale;
  final double lineHeight;
  final Widget header;
  const _SectionHeaderRail({
    required this.icon,
    required this.scale,
    required this.lineHeight,
    required this.header,
  });
  @override
  Widget build(BuildContext context) {
    final Color line = Colors.black;
    final double railWidth = 28 * scale;
    final double lineWidth = 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: railWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionIcon(icon: icon, scale: scale),
              SizedBox(
                height: lineHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: (railWidth - lineWidth) / 2,
                      top: 0,
                      bottom: -3,
                      child: Container(width: lineWidth, color: line),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: header),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Widget child;
  final bool isLast;
  final double scale;
  final double gap;
  final double dotTop;
  final double rightTopSpace;
  const _TimelineItem({
    required this.child,
    required this.isLast,
    required this.scale,
    required this.gap,
    required this.dotTop,
    this.rightTopSpace = 0,
  });
  @override
  Widget build(BuildContext context) {
    final Color line = Colors.black;
    final Color dot = Colors.black;
    final double railWidth = 28 * scale;
    final double lineWidth = 2;
    final double dotSize = 10 * scale;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: railWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: (railWidth - lineWidth) / 2,
                  top: -3,
                  bottom: -3,
                  child: Container(width: lineWidth, color: line),
                ),
                Positioned(
                  left: (railWidth - dotSize) / 2,
                  top: dotTop,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: dot, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: rightTopSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  child,
                  if (!isLast) SizedBox(height: gap),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
