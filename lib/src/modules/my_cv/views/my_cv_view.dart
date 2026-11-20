import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'package:cv_apps/src/utils/pdf_saver.dart';
import 'package:cv_apps/src/modules/my_cv/cv_copy.dart';
import 'package:cv_apps/src/components/app_language_switch.dart';
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

// One column for the whole CV. Every block starts and ends on the same edges
// at every width, and nothing sits beside another block, so no empty space is
// left next to a short panel.
const double _kWideBreakpoint = 900;
const double _kMaxCardWidth = 900;
const double _kCardRadius = 16;
const double _kWideInset = 24;
const double _kColumnGap = 24;
// Entry headings show the date on the title's line only when the text column
// is this wide; below it, every entry puts the date under the title.
const double _kSideBySideHeadingWidth = 760;
const double _kContactListWidth = 300;
const Color _kPanelColor = Color(0xFF1C3144);
const Color _kPillColor = Color(0xFF2E3E52);

/// Text and sizes shrink a little on narrow phones so that every line fits
/// without truncation. From 520px up the CV is shown at its full size.
double _cvScale(double width) {
  if (width < 360) return 0.9;
  if (width < 420) return 0.94;
  if (width < 520) return 0.97;
  return 1.0;
}

/// Space between the timeline rail and the text of an entry.
double _railGap(double scale) => 14 * scale;

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
        // The header floats over the page, as in the portfolio: the page
        // shows through it.
        extendBodyBehindAppBar: true,
        appBar: show
            ? AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                foregroundColor: Colors.white,
                flexibleSpace: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x80000000), Color(0x00000000)],
                    ),
                  ),
                ),
                leading: IconButton(
                  tooltip: cvText(context, 'Back'),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                ),
                title: Text(cvText(context, 'My CV')),
                actions: [
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: AppLanguageSwitch(),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isExporting,
                    builder: (context, exporting, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: exporting
                                ? cvText(context, 'Exporting...')
                                : cvText(
                                    context,
                                    'Quick Export (Single Long Page - Standard)',
                                  ),
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
                            tooltip: cvText(context, 'More Export Qualities'),
                            icon: const Icon(Icons.arrow_drop_down),
                            onSelected: (option) => _exportPdf(context, option),
                            itemBuilder: (context) => _exportOptions
                                .map(
                                  (opt) => PopupMenuItem<_PdfQuality>(
                                    value: opt,
                                    child: Text(
                                      '${cvText(context, "Export Single Long Page")} (${cvText(context, opt.label)})',
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
          builder: (context, exporting, _) =>
              NotificationListener<ScrollNotification>(
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
                          const Positioned(
                            right: -160,
                            top: -140,
                            child: _Glow(size: 420, alpha: 0.24),
                          ),
                          const Positioned(
                            left: -170,
                            bottom: -180,
                            child: _Glow(size: 440, alpha: 0.18),
                          ),
                          SafeArea(
                            child: Padding(
                              // Below the header while it is shown.
                              padding: EdgeInsets.only(
                                top: show ? kToolbarHeight : 0,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) =>
                                    _buildPage(context, constraints.maxWidth),
                              ),
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

  Widget _buildPage(BuildContext context, double w) {
    final bool isWide = w >= _kWideBreakpoint;
    final double scale = _cvScale(w);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxCardWidth),
          child: Padding(
            padding: EdgeInsets.all(isWide ? _kWideInset : 10.0),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(isWide: isWide, scale: scale),
                      SizedBox(height: 16 * scale),
                      _SkillsPanel(isWide: isWide, scale: scale),
                      SizedBox(height: 16 * scale),
                      _CvContent(isWide: isWide, scale: scale),
                    ],
                  ),
                ),
              ),
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
          SnackBar(
            content: Text(
              cvText(context, 'PDF export completed. Download started.'),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cvText(context, 'Failed to export PDF'))),
        );
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
                      cvText(context, 'Generating PDF'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${clamped.toStringAsFixed(0)}% ${cvText(context, "completed")}',
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
}

class _Glow extends StatelessWidget {
  final double size;
  final double alpha;
  const _Glow({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isWide;
  final double scale;
  const _Header({required this.isWide, required this.scale});

  static const List<(IconData, String)> _contacts = [
    (Icons.phone, '+6287728020907'),
    (Icons.email, 'kiki.triansyah93@gmail.com'),
    (Icons.link, 'linkedin.com/in/kiki-triansyah'),
    (Icons.location_on, 'Jakarta, Indonesia'),
  ];

  /// The photo tab sits flush with the top and left edges of the card.
  Widget _tab() {
    final Color topTab = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.08),
      _kPillColor,
    );
    final Color bottomTab = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.08),
      _kPillColor,
    );
    return Container(
      width: isWide ? 216.0 : 120.0 * scale,
      constraints: BoxConstraints(minHeight: isWide ? 200.0 : 0.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topTab, bottomTab],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular((isWide ? 48.0 : 32.0) * scale),
          bottomRight: Radius.circular((isWide ? 48.0 : 32.0) * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _Avatar(
        size: isWide ? 168.0 : 96.0 * scale,
        ring: (isWide ? 6.0 : 5.0) * scale,
      ),
    );
  }

  Widget _nameBlock(BuildContext context, double left) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(left: left),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KIKI TRIANSYAH',
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            Text(
              cvText(context, 'Software Developer Apps Mobile'),
              style: text.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '(React Native Developer & IOS Developer & Flutter)',
              style: text.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double inset = isWide ? _kWideInset : 16.0 * scale;
    final double nameGap = isWide ? 32.0 : 16.0 * scale;
    final BoxDecoration card = BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.94),
          Colors.white.withValues(alpha: 0.88),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(_kCardRadius),
    );

    if (isWide) {
      // Photo, name and contacts share one row, so the banner has no empty
      // space beside the name.
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: card,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tab(),
              Expanded(child: _nameBlock(context, nameGap)),
              Padding(
                padding: EdgeInsets.all(inset),
                child: Center(
                  child: SizedBox(
                    width: _kContactListWidth,
                    child: _ContactBar(
                      bg: _kPillColor,
                      scale: scale,
                      asList: true,
                      items: _contacts,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tab(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: inset),
                    child: _nameBlock(context, nameGap),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(inset, 12 * scale, inset, inset),
            child: LayoutBuilder(
              builder: (context, constraints) => _ContactBar(
                bg: _kPillColor,
                scale: scale,
                // Narrow cards list one contact per line, so no value is cut short.
                asList: constraints.maxWidth < 560,
                items: _contacts,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final double size;
  final double ring;
  const _Avatar({required this.size, required this.ring});

  @override
  Widget build(BuildContext context) {
    final double photo = size - ring * 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: ring),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/img/photo_profile.jpg',
          width: photo,
          height: photo,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade300,
            alignment: Alignment.center,
            child: Icon(
              Icons.person,
              size: photo / 2,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  final List<(IconData, String)> items;
  final Color bg;
  final double scale;
  // A list shows one contact per line; otherwise two contacts share a line.
  final bool asList;
  const _ContactBar({
    required this.items,
    required this.bg,
    required this.scale,
    required this.asList,
  });

  Widget _entry(BuildContext context, int index) {
    final (IconData, String) item = items[index];
    final Widget leading;
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
      leading = Icon(item.$1, color: Colors.white, size: 18 * scale);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22 * scale,
          child: Center(child: leading),
        ),
        SizedBox(width: 8 * scale),
        Flexible(
          child: Text(
            item.$2,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color topShade = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.06),
      bg,
    );
    final Color bottomShade = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.06),
      bg,
    );
    final List<Widget> rows = asList
        ? [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4 * scale),
                child: _entry(context, i),
              ),
          ]
        : [
            for (var i = 0; i < items.length; i += 2)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4 * scale),
                child: Row(
                  children: [
                    Expanded(child: _entry(context, i)),
                    SizedBox(width: 24 * scale),
                    Expanded(
                      child: i + 1 < items.length
                          ? _entry(context, i + 1)
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
          ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 18 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topShade, bottomShade],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular((asList ? 18.0 : 28.0) * scale),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0C1826).withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}

class _SkillsPanel extends StatelessWidget {
  final bool isWide;
  final double scale;
  const _SkillsPanel({required this.isWide, required this.scale});

  static const List<String> _tools = [
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
  ];

  static const List<String> _techStack = [
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
  ];

  static const List<String> _skills = [
    'Model-View-ViewModel',
    'Clean Architecture',
    'Unit & Integration Testing',
    'Scrum',
    'Agile',
    'RESTful APIs',
  ];

  static const List<String> _languages = ['English', 'Indonesian'];

  Widget _group(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(color: Colors.white, text: title),
        SizedBox(height: 12 * scale),
        _WrapChips(scale: scale, items: items),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color topShade = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.08),
      _kPanelColor,
    );
    final Color bottomShade = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.08),
      _kPanelColor,
    );
    final double pad = isWide ? _kWideInset : 16.0 * scale;
    final double rowGap = 20 * scale;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topShade, bottomShade],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0C1826).withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(pad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Two groups side by side when there is room, one under another on phones.
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _group(cvText(context, 'TOOLS'), _tools),
                SizedBox(height: rowGap),
                _group(cvText(context, 'TECH STACK'), _techStack),
                SizedBox(height: rowGap),
                _group(cvText(context, 'SKILLS'), _skills),
                SizedBox(height: rowGap),
                _group(cvText(context, 'LANGUAGES'), [
                  for (final l in _languages) cvText(context, l),
                ]),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _group(cvText(context, 'TOOLS'), _tools)),
                  const SizedBox(width: _kColumnGap),
                  Expanded(
                    child: _group(cvText(context, 'TECH STACK'), _techStack),
                  ),
                ],
              ),
              SizedBox(height: rowGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _group(cvText(context, 'SKILLS'), _skills)),
                  const SizedBox(width: _kColumnGap),
                  Expanded(
                    child: _group(cvText(context, 'LANGUAGES'), [
                      for (final l in _languages) cvText(context, l),
                    ]),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CvContent extends StatelessWidget {
  final bool isWide;
  final double scale;
  const _CvContent({required this.isWide, required this.scale});

  @override
  Widget build(BuildContext context) {
    final double pad = isWide ? _kWideInset : 14.0 * scale;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderRail(
            icon: Icons.person,
            scale: scale,
            lineHeight: 6 * scale + 2,
            header: _ContentHeader(
              color: Colors.black,
              text: cvText(context, 'PROFILE'),
            ),
          ),
          _TimelineItem(
            isLast: true,
            scale: scale,
            gap: 0,
            dotTop: 44 * scale,
            rightTopSpace: 4 * scale,
            child: Text(
              cvText(
                context,
                'A strategic Mobile Developer who transforms business objectives into high-impact mobile applications. I architect and deliver robust, scalable, and user-centric apps from concept to launch, leveraging deep expertise in Flutter, React Native, and native iOS/Android development. My end-to-end ownership—spanning from product discovery and system design to App Store and Play Store deployment—consistently accelerates development cycles and enhances user engagement. I thrive in collaborative environments, translating complex requirements into reliable, high-performance software that drives measurable business growth.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _RailGap(height: 24, scale: scale),
          _TimelineSection(
            icon: Icons.work,
            title: cvText(context, 'WORK EXPERIENCE'),
            scale: scale,
            lineHeight: 6 * scale + 2,
            color: Colors.black,
            itemGap: 16,
            dotTop: 8 * scale,
            rightTopSpace: 4 * scale,
            items: [
              _ExperienceItem(
                company: 'SEI ASIA',
                period: cvText(
                  context,
                  'Freelance Project : 2025 December – 2026 March',
                ),
                role: cvText(context, 'Mobile Developer • Flutter Developer'),
                points: [
                  cvText(
                    context,
                    'Develop LifelineConnect mobile application for Android & iOS platforms',
                  ),
                  cvText(
                    context,
                    'Build the application using Dart (Flutter) with Bloc state management and Clean Architecture principles',
                  ),
                  cvText(
                    context,
                    'Implement architecture patterns including MVVM, along with Go Router and Provider for navigation and state handling',
                  ),
                  cvText(
                    context,
                    'Develop core features such as member management, group management, chat, voice chat, and voice call',
                  ),
                  cvText(
                    context,
                    'Integrate IoT device connectivity (e.g., Smart Watch, Dispenser, AirPods, Smart Door Lock) with the mobile application',
                  ),
                  cvText(
                    context,
                    'Integrate backend services using RESTful APIs',
                  ),
                  cvText(
                    context,
                    'Manage source code and CI/CD pipelines using GitHub CI/CD',
                  ),
                ],
              ),
              _ExperienceItem(
                company: 'AKASIA',
                period: cvText(
                  context,
                  'Contract Base Project : 2025 Juli – 2025 September',
                ),
                role: cvText(
                  context,
                  'Mobile Developer • React Native Developer',
                ),
                points: [
                  cvText(
                    context,
                    'Develop Hadir application for client PT FWD Insurance Indonesia',
                  ),
                  cvText(
                    context,
                    'Build the project end-to-end, from development to deployment on internal company server',
                  ),
                  cvText(
                    context,
                    'Develop cross-platform mobile applications (Android & iOS) using React Native',
                  ),
                  cvText(
                    context,
                    'Utilize modern tech stack including TypeScript, Tailwind CSS, Redux Saga, and React Navigation',
                  ),
                  cvText(
                    context,
                    'Implement core features such as user attendance (clock in/out), room booking, and overtime management',
                  ),
                  cvText(
                    context,
                    'Apply geofencing validation (±300m radius) to ensure attendance can only be performed within office area',
                  ),
                  cvText(
                    context,
                    'Implement anti–fake GPS detection to prevent location spoofing',
                  ),
                  cvText(
                    context,
                    'Develop reporting and validation systems for user attendance',
                  ),
                  cvText(
                    context,
                    'Integrate backend services using RESTful APIs',
                  ),
                  cvText(
                    context,
                    'Manage source code and CI/CD pipelines using Azure CI/CD',
                  ),
                ],
              ),
              _ExperienceItem(
                company: 'Durioo+',
                period: cvText(
                  context,
                  'Contract : 2023 September – 2025 January',
                ),
                role: cvText(
                  context,
                  'Mobile Apps Developer • React Native Developer',
                ),
                points: [
                  cvText(
                    context,
                    'Develop cross-platform mobile applications (Android & iOS) using Expo React Native',
                  ),
                  cvText(
                    context,
                    'Build projects end-to-end, from development to deployment on App Store & Play Store',
                  ),
                  cvText(
                    context,
                    'Implement custom components, including Video Player and tailored UI/UX features',
                  ),
                  cvText(
                    context,
                    'Integrate backend services using RESTful APIs',
                  ),
                  cvText(
                    context,
                    'Manage Over-the-Air (OTA) updates for seamless app releases',
                  ),
                  cvText(
                    context,
                    'Implement push notifications and user tracking using Firebase',
                  ),
                  cvText(
                    context,
                    'Handle subscription and in-app purchase systems via Play Store and App Store',
                  ),
                  cvText(
                    context,
                    'Develop features such as offline video playback, TV casting, and video download for subscribed users',
                  ),
                  cvText(
                    context,
                    'Manage source code and CI/CD pipelines using GitLab CI/CD',
                  ),
                ],
              ),
              _ExperienceItem(
                company: 'MOLA',
                period: cvText(
                  context,
                  'Fulltime : 2020 January – 2023 January',
                ),
                role: cvText(
                  context,
                  'Mobile Engineer • React Native Developer & iOS Developer',
                ),
                points: [
                  cvText(
                    context,
                    'Develop cross-platform mobile applications (Android & iOS) using React Native, and native iOS applications using SwiftUI',
                  ),
                  cvText(
                    context,
                    'Build projects end-to-end, from development to deployment on App Store and Play Store',
                  ),
                  cvText(
                    context,
                    'Implement native module bridging (e.g., Video Player) for iOS and Android integration',
                  ),
                  cvText(
                    context,
                    'Develop key features such as Live Quiz, Inbox, Push Notifications, Social Media Sharing, and Subscription systems',
                  ),
                  cvText(
                    context,
                    'Integrate user analytics tracking and monitoring tools (e.g., Bugsnag, New Relic)',
                  ),
                  cvText(
                    context,
                    'Integrate backend services via RESTful APIs',
                  ),
                  cvText(
                    context,
                    'Manage source code and CI/CD pipelines using GitLab CI/CD',
                  ),
                ],
              ),
              _ExperienceItem(
                company: 'Binar Academy',
                period: cvText(context, 'Contract : 2019 July – 2020 January'),
                role: cvText(
                  context,
                  'Talent Frontend Developer • React Native Developer',
                ),
                points: [
                  cvText(
                    context,
                    'Develop and maintain MOLA application for client (MOLA TV)',
                  ),
                  cvText(
                    context,
                    'Develop mobile applications for Android & iOS platforms (MOLA & Super Soccer Apps)',
                  ),
                  cvText(
                    context,
                    'Build and maintain features such as Article and Podcast components in Super Soccer Apps',
                  ),
                  cvText(
                    context,
                    'Handle end-to-end mobile development and deployment to App Store & Play Store',
                  ),
                  cvText(
                    context,
                    'Manage source code and CI/CD pipelines using GitLab CI/CD',
                  ),
                ],
              ),
            ],
          ),
          _RailGap(height: 24, scale: scale),
          _TimelineSection(
            icon: Icons.folder_open,
            title: cvText(context, 'PROJECT'),
            scale: scale,
            lineHeight: 6 * scale + 2,
            color: Colors.black,
            itemGap: 16,
            dotTop: 8 * scale,
            rightTopSpace: 4 * scale,
            items: [
              _ProjectItem(
                name: 'LifelineConnect Apps',
                period: cvText(context, '2025 December – 2026 March'),
                summary: cvText(context, 'Social Media Apps'),
                details: [
                  cvText(
                    context,
                    'Member management, group management, chat, voice chat, and voice call',
                  ),
                  cvText(
                    context,
                    'IoT device connectivity (e.g., Smart Watch, Dispenser, AirPods, Smart Door Lock) with the mobile application',
                  ),
                ],
              ),
              _ProjectItem(
                name: 'Hadir Apps (Internal)',
                period: cvText(context, '2025 July – 2025 September'),
                summary: cvText(context, 'HR Apps'),
                details: [
                  cvText(
                    context,
                    'Absence Clock In and Out, Booking Room, Overtime, Report',
                  ),
                ],
              ),
              _ProjectItem(
                name: 'Durioo+ Apps',
                period: cvText(context, '2023 September – 2025 January'),
                summary: cvText(
                  context,
                  'Multi Platform Android Mobile and iOS Mobile, Android TV, TVOS',
                ),
                details: [
                  cvText(context, 'Watching Movies content for kids muslim'),
                ],
              ),
              _ProjectItem(
                name: 'MOLA Apps',
                period: cvText(context, '2019 July – 2023 January'),
                summary: cvText(
                  context,
                  'Multi Platform Android Mobile and iOS Mobile, Android TV, TVOS',
                ),
                details: [
                  cvText(context, 'Watching Movies content for kids & adult'),
                  cvText(context, 'Live Streaming sport football and many'),
                ],
              ),
            ],
          ),
          _RailGap(height: 24, scale: scale),
          _TimelineSection(
            icon: Icons.school,
            title: cvText(context, 'EDUCATION'),
            scale: scale,
            lineHeight: 6 * scale + 2,
            color: Colors.black,
            itemGap: 16,
            dotTop: 8 * scale,
            rightTopSpace: 4 * scale,
            items: [
              _EducationItem(
                degree: cvText(context, 'Bachelor of Information Technology'),
                period: '2012 - 2016',
                school: 'Universitas Muhammadiyah Yogyakarta',
                gpa: cvText(context, 'GPA: 3.47 / 4.00'),
              ),
              _EducationItem(
                degree: cvText(
                  context,
                  'Training Team Project Binar Academy Batch 8',
                ),
                period: cvText(context, '2018 July - 2018 Oct '),
                school: cvText(context, 'Binar Academy at Yogyakarta'),
                gpa: cvText(context, 'Frontend Developer As React JS'),
              ),
              _EducationItem(
                degree: cvText(context, 'Training Project Binar+ Batch 1'),
                period: cvText(context, '2018 Des - 2019 Mar'),
                school: cvText(context, 'Binar Academy at BSD City'),
                gpa: cvText(context, 'Mobile Developer As React Native'),
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

/// Title and date of an entry. Wide cards show the date on the title's line,
/// right aligned. Narrower cards always show it under the title, so every
/// entry looks the same and no text is squeezed beside the title.
class _ItemHeading extends StatelessWidget {
  final String title;
  final String meta;
  const _ItemHeading({required this.title, required this.meta});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Text titleText = Text(
      title,
      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
    final Text metaText = Text(
      meta,
      style: text.bodySmall?.copyWith(color: Colors.black54),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _kSideBySideHeadingWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleText, const SizedBox(height: 2), metaText],
          );
        }
        return Row(
          children: [
            Expanded(child: titleText),
            const SizedBox(width: 12),
            metaText,
          ],
        );
      },
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  const _Bullets({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 14, child: Text('•')),
                Expanded(child: Text(item)),
              ],
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
        _ItemHeading(title: company, meta: period),
        const SizedBox(height: 4),
        Text(
          role,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        _Bullets(items: points),
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
        _ItemHeading(title: name, meta: period),
        const SizedBox(height: 4),
        Text(
          summary,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        _Bullets(items: details),
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
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ItemHeading(title: degree, meta: period),
        const SizedBox(height: 6),
        Text(
          school,
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(gpa, style: text.bodyMedium),
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
  const _RailGap({required this.height, required this.scale});
  @override
  Widget build(BuildContext context) {
    const Color line = Colors.black;
    final double railWidth = 28 * scale;
    const double lineWidth = 2;
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
              ],
            ),
          ),
          SizedBox(width: _railGap(scale)),
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
    const Color line = Colors.black;
    final double railWidth = 28 * scale;
    const double lineWidth = 2;
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
        SizedBox(width: _railGap(scale)),
        Expanded(child: header),
      ],
    );
  }
}

/// One timeline entry. The rail is drawn by a Stack that is as tall as the
/// entry itself, so the line and the dot follow the text without measuring it.
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
    const Color line = Colors.black;
    const Color dot = Colors.black;
    final double railWidth = 28 * scale;
    const double lineWidth = 2;
    final double dotSize = 10 * scale;
    return Stack(
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
        Padding(
          padding: EdgeInsets.only(
            left: railWidth + _railGap(scale),
            top: rightTopSpace,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child,
              if (!isLast) SizedBox(height: gap),
            ],
          ),
        ),
      ],
    );
  }
}
