import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/pdf_saver.dart';
import '../portfolio_pdf.dart';
import '../portfolio_slide_assets.dart';
import '../portfolio_slides_data.dart';
import '../portfolio_v2_id.dart';
import 'package:cv_apps/src/utils/app_language.dart';
import 'portfolio_v2_fx.dart';

// ---------------------------------------------------------------------------
// Portfolio v2 (/my_portofolio_v2): the same text and pictures as the
// portfolio PDF (portfolio_slides_data.dart), in a scrolling editorial layout
// modelled on 21st.dev's "Daytake" landing page:
//
//   hero      two-tone headline + a tilted 3D wall of app screens whose
//             columns drift in opposite directions and flatten as you scroll
//   cover     the cover photo expands from an inset card to full width, with
//             floating cards on parallax
//   projects  per app: opposing rows of screens moved by the scroll, the
//             "what is" text next to an expanding feature picture (or a fan
//             of phones) with floating tech chips, then the challenge
//   about     profile card, about text and contact cards joined by a wire
//             that draws itself
//
// Text is read from the slide data, so both versions stay in sync.
// ---------------------------------------------------------------------------

const _bg = Color(0xFFF6F5F1);
const _ink = Color(0xFF14161F);
const _ink2 = Color(0xFF3A3D48);
const _muted = Color(0xFF7A7E89);
const _line = Color(0xFFE3E1DA);
const _blue = Color(0xFF3B5BDB);
const _coral = Color(0xFFE0674B);

// Width / height of every picture used here.
const _ratio = <String, double>{
  'MAGkuS30vgU': 3177 / 735,
  'MAGkuY6kHqs': 16 / 9,
  'MAGkuavDWb0': 16 / 9,
  'MAGkufuQY6I': 1,
  'MAGkwgentno': 16 / 9,
  'MAGkwioR9GU': 16 / 9,
  'MAGkwtJEqHg': 16 / 9,
  'MAGkx0oBYgM': 1,
  'MAGkxeWv44o': 5824 / 3264,
  'MAGkxgRA6bY': 750 / 422,
  'MAGkxgws8Ew': 1,
  'MAGkxij3D6k': 1919 / 1079,
  'MAGkxucbHAg': 1,
  'MAGz-A6IFRQ': 792 / 1694,
  'MAGz-AibnvE': 782 / 1682,
  'MAGz-CliXE4': 710 / 1532,
  'MAGz-CmIfgc': 710 / 1214,
  'MAGz-IdgTsY': 710 / 1526,
  'MAGz-JzleAg': 704 / 1338,
  'MAGz-MPGUoc': 788 / 1688,
  'MAGz-Qd0gBY': 782 / 1686,
  'MAGz-Yp2arw': 788 / 1694,
  'MAGz-bTLFKQ': 770 / 1498,
  'MAHFcS2QjQI': 156 / 361,
  'MAHFcSQtOZA': 219 / 474,
  'MAHFcVRSgWc': 221 / 474,
  'MAHFcX2tLO8': 228 / 486,
  'MAHFcbDpQEE': 224 / 475,
  'MAHFfAL4vnI': 375 / 816,
  'MAHFfAlbF2U': 2784 / 512,
  'MAHFfIoN29c': 352 / 812,
  'MAHFfJwzp3I': 269 / 587,
  'MAHFfKpSOic': 96 / 33,
  'MAHFgTnAz5s': 1106 / 1421,
  'MAHFgUKDcG0': 226 / 488,
  'MAHFgXLXxQo': 227 / 482,
  'MAHFgXxCKuc': 226 / 486,
  'MAHFgY27r_s': 260 / 557,
  'MAHFgbLC9ho': 227 / 495,
  'MAHFgeuyVbA': 270 / 580,
  'MAHFiCH6vdQ': 1,
  'MAHFiLWkfvU': 1,
  'MAEzbtdaL9U': 1,
  'MAFi5nUvD3Q': 1,
  'MAElfbID1iE': 1,
};

/// Width / height of a picture; phone screenshots (9:16) by default.
double v2Ratio(String id) => _ratio[id] ?? 720 / 1280;

/// The file v2 shows for a media id. Raster pictures come from the
/// display-sized copies in portfolio_v2/, so decoding stays small enough for
/// Flutter's image cache to keep them.
String _v2Path(String id) {
  final original = kSlideAssets[id]!;
  return original.endsWith('.svg')
      ? original
      : 'assets/img/portfolio_v2/$id.${original.split('.').last}';
}

/// A picture from the slide assets, [w] x [h], with rounded corners.
Widget _pic(
  String id, {
  required double w,
  required double h,
  double radius = 0,
  BoxFit fit = BoxFit.cover,
  Alignment align = Alignment.center,
  Color placeholder = Colors.transparent,
  double? decodeW,
}) {
  final path = _v2Path(id);
  Widget child;
  if (path.endsWith('.svg')) {
    child = SvgPicture.asset(path, fit: BoxFit.contain);
  } else {
    // Cover-fitted pictures wider than the box are shown wider than it.
    final shown = fit == BoxFit.cover
        ? math.max(w, h * v2Ratio(id))
        : math.min(w, h * v2Ratio(id));
    child = LazyPic(
      path,
      fit: fit,
      alignment: align,
      logicalWidth: decodeW ?? shown,
      placeholder: placeholder,
      label: _picLabel(id),
    );
  }
  return SizedBox(
    width: w,
    height: h,
    child: radius > 0
        ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: child)
        : child,
  );
}

String? _picLabel(String id) {
  for (final p in _projects) {
    if (p.rowA.contains(id) || p.rowB.contains(id) || p.feature.contains(id)) {
      return '${p.name} screenshot';
    }
  }
  return null;
}

// --- Text from the slide data ------------------------------------------------

/// Whether the page shows Indonesian text. The page sets it in its build, so
/// every text helper below reads the language the page is showing.
bool _v2Id = false;

/// An interface label in the current language.
String _ui(String en) => _v2Id ? (kIdUi[en] ?? en) : en;

/// The text blocks of a slide: English, or Indonesian in ID mode.
List<SlideText> _texts(int page) {
  final items = kSlidePages[page].items.whereType<SlideText>().toList();
  if (!_v2Id) return items;
  return [
    for (var i = 0; i < items.length; i++)
      if (kIdLines[(page, i)] case final id?)
        SlideText(
          items[i].top,
          items[i].left,
          items[i].width,
          id,
          size: items[i].size,
          weight: items[i].weight,
          color: items[i].color,
          align: items[i].align,
          lh: items[i].lh,
          spacing: items[i].spacing,
        )
      else
        items[i],
  ];
}

/// The PDF's lines joined back into paragraphs: a line ending with a full
/// stop ends its paragraph.
List<String> _paras(String text) {
  final lines = text.split('\n');
  final out = <String>[];
  var cur = <String>[];
  for (var i = 0; i < lines.length; i++) {
    cur.add(lines[i].trim());
    if (lines[i].trimRight().endsWith('.') && i < lines.length - 1) {
      out.add(cur.join(' '));
      cur = [];
    }
  }
  if (cur.isNotEmpty) out.add(cur.join(' '));
  return out;
}

/// Terms the PDF sets in bold (**x**), e.g. the tech stack.
List<String> _boldTerms(String text) => [
  for (final m in RegExp(r'\*\*(.+?)\*\*').allMatches(text)) m.group(1)!,
];

/// Slide markup to spans: **x** bold italic, ++x++ bold, __x__ underline,
/// [[label|url]] link.
TextSpan _rich(String text, TextStyle style, {Color link = _blue}) {
  final pattern = RegExp(
    r'\[\[(.+?)\|(.+?)\]\]|\*\*(.+?)\*\*|\+\+(.+?)\+\+|__(.+?)__',
  );
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start)));
    }
    if (m.group(1) != null) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _Link(
            label: m.group(1)!,
            url: m.group(2)!,
            style: style,
            color: link,
          ),
        ),
      );
    } else if (m.group(3) != null) {
      spans.add(
        TextSpan(
          text: m.group(3),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: _ink,
          ),
        ),
      );
    } else if (m.group(4) != null) {
      spans.add(
        TextSpan(
          text: m.group(4),
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: m.group(5),
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
      );
    }
    cursor = m.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return TextSpan(style: style, children: spans);
}

/// (word, colour) pairs; words from index [accentFrom] on are [accent].
List<(String, Color)> _words(String text, int accentFrom, Color accent) {
  final ws = text.replaceAll('\n', ' ').split(RegExp(r'\s+'));
  return [
    for (var i = 0; i < ws.length; i++)
      (ws[i], i >= accentFrom ? accent : _ink),
  ];
}

// --- Projects ------------------------------------------------------------------

class _Project {
  const _Project({
    required this.key,
    required this.name,
    required this.grad,
    required this.gradAngle,
    required this.accent,
    required this.logo,
    required this.logoBox,
    required this.rowA,
    required this.rowB,
    required this.infoPage,
    required this.feature,
    this.challengePage,
    this.challengeShots = const [],
    this.icon,
    this.logoOnDark = false,
  });

  final String key;
  final String name;
  final List<Color> grad;
  final double gradAngle;
  final Color accent;

  /// Logo media id and the width / height of the box it is cropped into.
  final String logo;
  final double logoBox;

  /// Screens for the two opposing rows.
  final List<String> rowA;
  final List<String> rowB;

  /// Slide with the "What is" (and achievement) text.
  final int infoPage;

  /// One picture, or three phone screens shown as a fan.
  final List<String> feature;
  final int? challengePage;
  final List<String> challengeShots;
  final String? icon;
  final bool logoOnDark;
}

const _projects = <_Project>[
  _Project(
    key: 'mola',
    name: 'MOLA TV',
    grad: [Color(0xFF5DE0E6), Color(0xFF004AAD)],
    gradAngle: 90,
    accent: Color(0xFF1F5FC2),
    logo: 'MAGkuS30vgU',
    logoBox: 3177 / 735,
    rowA: [
      'MAGkuXFxHdU',
      'MAGkucVfCV0',
      'MAGkuY6kHqs',
      'MAGkufQz0PU',
      'MAGkxuh2CnY',
      'MAGkufxBG9U',
    ],
    rowB: [
      'MAGkufxBG9U',
      'MAGkwuSB9l0',
      'MAGkxuh2CnY',
      'MAGkuY6kHqs',
      'MAGkwgDV7WQ',
      'MAGkucVfCV0',
    ],
    infoPage: 2,
    feature: ['MAGkxucbHAg'],
    challengePage: 3,
    challengeShots: ['MAGkwuSB9l0', 'MAGkwgDV7WQ'],
  ),
  _Project(
    key: 'durioo',
    name: 'Durioo+',
    grad: [Color(0xFFFF7A3C), Color(0xFFFFCE81)],
    gradAngle: 45,
    accent: Color(0xFFE2581C),
    logo: 'MAGkufuQY6I',
    logoBox: 557.1 / 171.9,
    rowA: [
      'MAGkudJgBcs',
      'MAGkuT4jH1I',
      'MAGkuavDWb0',
      'MAGkub-DPzc',
      'MAGkuY8MdE8',
      'MAGkuZMkhn8',
    ],
    rowB: [
      'MAGkwgentno',
      'MAGkuZMkhn8',
      'MAGkwioR9GU',
      'MAGkudJgBcs',
      'MAGkwtJEqHg',
      'MAGkub-DPzc',
    ],
    infoPage: 5,
    feature: ['MAGkxgRA6bY'],
    challengePage: 6,
    challengeShots: ['MAGkwgentno', 'MAGkwioR9GU', 'MAGkwtJEqHg'],
    icon: 'MAGkxgws8Ew',
  ),
  _Project(
    key: 'hadir',
    name: 'HadIR',
    grad: [Color(0xFFEE7623), Color(0xFFFFCE81)],
    gradAngle: 45,
    accent: Color(0xFFD9640F),
    logo: 'MAHFfKpSOic',
    logoBox: 96 / 33,
    rowA: [
      'MAGz-CliXE4',
      'MAGz-CmIfgc',
      'MAGz-JzleAg',
      'MAGz-IdgTsY',
      'MAGz-A6IFRQ',
    ],
    rowB: [
      'MAGz-AibnvE',
      'MAGz-MPGUoc',
      'MAGz-bTLFKQ',
      'MAGz-Yp2arw',
      'MAGz-Qd0gBY',
    ],
    infoPage: 8,
    feature: ['MAGz-CmIfgc', 'MAGz-bTLFKQ', 'MAGz-JzleAg'],
    icon: 'MAHFiCH6vdQ',
  ),
  _Project(
    key: 'lifeline',
    name: 'LifelineConnect',
    grad: [Color(0xFF431043), Color(0xFFD34681)],
    gradAngle: 45,
    accent: Color(0xFFB8336D),
    logo: 'MAHFfAlbF2U',
    logoBox: 779.2 / 106.1,
    rowA: [
      'MAHFgY27r_s',
      'MAHFcSQtOZA',
      'MAHFcVRSgWc',
      'MAHFcbDpQEE',
      'MAHFgeuyVbA',
      'MAHFcX2tLO8',
      'MAHFfAL4vnI',
    ],
    rowB: [
      'MAHFfIoN29c',
      'MAHFfJwzp3I',
      'MAHFcS2QjQI',
      'MAHFgUKDcG0',
      'MAHFgXxCKuc',
      'MAHFgXLXxQo',
      'MAHFgbLC9ho',
    ],
    infoPage: 10,
    feature: ['MAHFgXxCKuc', 'MAHFgbLC9ho', 'MAHFgUKDcG0'],
    icon: 'MAHFiLWkfvU',
    logoOnDark: true,
  ),
];

/// Contact icons, in the order of the contact lines on the last slide.
const _contactIcons = [
  'MAHFh3mkuFE',
  'MAGzNvNA4A8',
  'MAElfbID1iE',
  'MAGkx0oBYgM',
  'MADnA61Y6l4',
  'MAGzZ0yqbBM',
];

LinearGradient _gradient(List<Color> colors, double angle) {
  // CSS-style angle: 90 runs left to right, 45 bottom-left to top-right.
  final r = (angle - 90) * math.pi / 180;
  final end = Alignment(math.cos(r), math.sin(r));
  return LinearGradient(colors: colors, begin: -end, end: end);
}

// --- Page ------------------------------------------------------------------------

class PortfolioV2View extends StatefulWidget {
  const PortfolioV2View({super.key});

  @override
  State<PortfolioV2View> createState() => _PortfolioV2ViewState();
}

class _PortfolioV2ViewState extends State<PortfolioV2View>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  // Holds the hero wall's drift, 0 to 1, set from the scroll (no timer).
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 70),
  );
  final ValueNotifier<bool> _exporting = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showTop = ValueNotifier<bool>(false);
  // The section the header marks as current, as in the PDF portfolio (v1).
  final ValueNotifier<String> _current = ValueNotifier<String>('top');
  final Map<String, BuildContext> _sections = {};
  bool _calm = false;
  double _vh = 800;
  // The page is held back until its pictures are decoded, then shown once.
  bool _revealed = false;
  // The page is built (behind the cover) before it is revealed.
  bool _built = false;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncLoop);
    WidgetsBinding.instance.addPostFrameCallback((_) => _decodeThenReveal());
  }

  /// Decodes every picture into the image cache, then reveals the page. A
  /// picture shown only after its decode would pop in on screen: a blink on
  /// every first open. A decode that takes longer than ten seconds does not
  /// hold the page any longer.
  void _decodeThenReveal() {
    _revealTimer = Timer(const Duration(seconds: 10), _reveal);
    unawaited(_decodeAll().then((_) => _warmThenReveal()));
  }

  /// Builds the page behind the cover and scrolls through it once, so every
  /// picture is drawn (and ready for the GPU) before the reader sees it. The
  /// first draw of a picture can flash; this does that first draw while the
  /// cover still covers the page.
  Future<void> _warmThenReveal() async {
    if (!mounted || _revealed) return;
    setState(() => _built = true);
    await WidgetsBinding.instance.endOfFrame;
    await _warmPass();
    _reveal();
  }

  Future<void> _warmPass() async {
    if (!mounted || !_scroll.hasClients) return;
    final extent = _scroll.position.maxScrollExtent;
    final step = _scroll.position.viewportDimension * 0.5;
    final steps = (extent / step).ceil().clamp(1, 120);
    for (var i = 1; i <= steps; i++) {
      if (!mounted || !_scroll.hasClients || _revealed) return;
      _scroll.jumpTo(extent * i / steps);
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    await WidgetsBinding.instance.endOfFrame;
  }

  void _reveal() {
    _revealTimer?.cancel();
    if (mounted && !_revealed) {
      setState(() {
        _built = true;
        _revealed = true;
      });
    }
  }

  /// Decodes the pictures six at a time: hero wall first, then the rest.
  Future<void> _decodeAll() async {
    final wall = {for (final column in _wallColumns) ...column};
    final ids = [
      ...wall,
      for (final id in kSlideAssets.keys)
        if (!wall.contains(id) && !kSlideAssets[id]!.endsWith('.svg')) id,
    ];
    for (var i = 0; i < ids.length; i += 6) {
      if (!mounted) return;
      await Future.wait([
        for (final id in ids.skip(i).take(6))
          precacheImage(
            AssetImage(_v2Path(id)),
            context,
          ).catchError((Object _) {}),
      ]);
    }
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _scroll.dispose();
    _loop.dispose();
    _exporting.dispose();
    _showTop.dispose();
    _current.dispose();
    super.dispose();
  }

  /// The hero wall drifts with the scroll, not on a timer. Nothing animates on
  /// its own while the page is at rest, so the wall is still and cannot blink
  /// or keep the browser busy; it moves only while the reader scrolls past it.
  void _syncLoop() {
    if (!_scroll.hasClients) return;
    _showTop.value = _scroll.offset > 600;
    _updateCurrent();
    if (_calm) return;
    final drift = (_scroll.offset / (_vh * 1.1)).clamp(0.0, 1.0);
    if (_loop.value != drift) _loop.value = drift;
  }

  /// The current section: the last one whose top has passed a line 40% down
  /// the screen, or the last section at the very end of the page.
  void _updateCurrent() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    var key = 'top';
    if (pos.pixels >= pos.maxScrollExtent - 4) {
      key = _sectionOrder.last;
    } else {
      final line = _vh * 0.4;
      for (final k in _sectionOrder) {
        final ctx = _sections[k];
        if (ctx == null || !ctx.mounted) continue;
        final box = ctx.findRenderObject();
        if (box is! RenderBox || !box.attached || !box.hasSize) continue;
        if (box.localToGlobal(Offset.zero).dy <= line) key = k;
      }
    }
    if (_current.value != key) _current.value = key;
  }

  void _go(String key) {
    final ctx = _sections[key];
    if (ctx == null || !ctx.mounted) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
    );
  }

  // Same as the PDF portfolio (v1): the round arrow shows after 600 px.
  void _toTop() => _scroll.animateTo(
    0,
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutCubic,
  );

  Future<void> _exportPdf() async {
    if (_exporting.value) return;
    _exporting.value = true;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final bytes = await buildPortfolioPdf();
      if (kIsWeb) {
        await savePdf(bytes, 'portofolio_kiki_triansyah.pdf');
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      }
      messenger?.showSnackBar(
        SnackBar(content: Text(_ui('The PDF is ready to download.'))),
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(_ui("Couldn't create the PDF. Please try again.")),
        ),
      );
    } finally {
      _exporting.value = false;
    }
  }

  Widget _mark(String key, Widget child) => Builder(
    builder: (context) {
      _sections[key] = context;
      return child;
    },
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _vh = size.height;
    _calm = MediaQuery.disableAnimationsOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncLoop();
    });
    final wide = size.width >= 900;
    _v2Id = AppLanguage.isId(context);
    // All text on the page scales with the width: 90% on a phone, 100% from
    // 1100 px up, in small steps, so the type never jumps between sizes.
    final textScale =
        0.9 + 0.1 * ((size.width - 390) / (1100 - 390)).clamp(0.0, 1.0);
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        backgroundColor: _bg,
        body: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'Carlito', color: _ink),
          child: V2Scope(
            scroll: _scroll,
            calm: _calm,
            child: Stack(
              children: [
                if (_built)
                  SingleChildScrollView(
                    controller: _scroll,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _mark(
                          'top',
                          _Hero(
                            wide: wide,
                            vh: size.height,
                            loop: _loop,
                            onJump: _go,
                          ),
                        ),
                        const _TechStrip(),
                        _CoverStage(wide: wide),
                        for (var i = 0; i < _projects.length; i++)
                          _mark(
                            _projects[i].key,
                            _Chapter(
                              project: _projects[i],
                              index: i,
                              wide: wide,
                            ),
                          ),
                        _mark('contact', _About(wide: wide)),
                      ],
                    ),
                  ),
                // Covers the page until its pictures are decoded, then fades
                // away. Only this solid layer fades: the pictures never change
                // opacity, so they cannot blink.
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _revealed,
                    child: AnimatedOpacity(
                      opacity: _revealed ? 0 : 1,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      child: const ColoredBox(
                        color: _bg,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_revealed)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _ProgressLine(scroll: _scroll),
                  ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _BackToTop(show: _showTop, onTap: _toTop),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopBar(
                    wide: wide,
                    current: _current,
                    id: _v2Id,
                    onLanguage: (id) => AppLanguage.set(id: id),
                    onJump: _go,
                    onBack: () => context.go('/'),
                    exporting: _exporting,
                    onPdf: _exportPdf,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centres [child] at most [max] wide, with the page's side gutter.
Widget _contain(Widget child, {double max = 1200, bool wide = true}) {
  return Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 18),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

// --- Chrome ----------------------------------------------------------------------

/// The round back-to-top arrow of the PDF portfolio (v1).
class _BackToTop extends StatelessWidget {
  const _BackToTop({required this.show, required this.onTap});

  final ValueListenable<bool> show;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: show,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();
        return Material(
          color: const Color(0xCC101928),
          shape: const CircleBorder(side: BorderSide(color: Color(0x33FFFFFF))),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.arrowUp,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: ListenableBuilder(
        listenable: scroll,
        builder: (context, _) {
          var p = 0.0;
          if (scroll.hasClients && scroll.position.hasContentDimensions) {
            final max = scroll.position.maxScrollExtent;
            if (max > 0) p = (scroll.position.pixels / max).clamp(0.0, 1.0);
          }
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: p,
              heightFactor: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_blue, _coral]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The header of the PDF portfolio (v1), in this page's light colours: no bar,
/// just a soft fade at the top, so the pages show through it.
const _topBarH = 56.0;

const _sectionOrder = ['top', 'mola', 'durioo', 'hadir', 'lifeline', 'contact'];

const _topChips = <(String, String)>[
  ('Cover', 'top'),
  ('MOLA TV', 'mola'),
  ('Durioo+', 'durioo'),
  ('HadIR', 'hadir'),
  ('Lifeline', 'lifeline'),
  ('Contact', 'contact'),
];

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.wide,
    required this.current,
    required this.id,
    required this.onLanguage,
    required this.onJump,
    required this.onBack,
    required this.exporting,
    required this.onPdf,
  });

  final bool wide;
  final ValueListenable<String> current;
  final bool id;
  final ValueChanged<bool> onLanguage;
  final ValueChanged<String> onJump;
  final VoidCallback onBack;
  final ValueNotifier<bool> exporting;
  final VoidCallback onPdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _topBarH,
      // Right edge: no padding, so the PDF icon sits at the screen's edge.
      padding: const EdgeInsets.only(left: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB3F6F5F1), Color(0x00F6F5F1)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: _ui('Back'),
            onPressed: onBack,
            icon: const FaIcon(
              FontAwesomeIcons.arrowLeft,
              color: _ink,
              size: 16,
            ),
          ),
          const SizedBox(width: 4),
          // Not Flexible: a flexible title would share the free space with the
          // spacer and push the PDF icon into the middle on a phone.
          Text(
            _ui('Portfolio'),
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (wide)
            ValueListenableBuilder<String>(
              valueListenable: current,
              builder: (context, now, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (label, key) in _topChips)
                    _TopChip(
                      label: _ui(label),
                      active: now == key,
                      onTap: () => onJump(key),
                    ),
                ],
              ),
            ),
          _LangSwitch(id: id, onChanged: onLanguage),
          ValueListenableBuilder<bool>(
            valueListenable: exporting,
            builder: (context, busy, _) => IconButton(
              tooltip: _ui('Download PDF'),
              onPressed: busy ? null : onPdf,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.filePdf,
                      color: _ink,
                      size: 16,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The language switch: ID or ENG, the one in use filled in blue.
class _LangSwitch extends StatelessWidget {
  const _LangSwitch({required this.id, required this.onChanged});

  final bool id;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangButton(label: 'ID', active: id, onTap: () => onChanged(true)),
            _LangButton(
              label: 'ENG',
              active: !id,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: active ? _blue : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : _ink2,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A header link, as in v1: text only, pill-shaped when hovered.
class _TopChip extends StatefulWidget {
  const _TopChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TopChip> createState() => _TopChipState();
}

class _TopChipState extends State<_TopChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.active
                  ? _blue
                  : (_hover
                        ? _ink.withValues(alpha: 0.06)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.active ? Colors.white : (_hover ? _blue : _ink2),
                fontSize: 13,
                fontWeight: widget.active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded button: outlined, or filled with [color].
class _Pill extends StatefulWidget {
  const _Pill({
    required this.label,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final FaIconData? icon;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final filled = widget.color != null;
    final fg = filled ? Colors.white : _ink;
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hover ? 1.04 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: filled
                    ? widget.color
                    : (_hover ? _ink.withValues(alpha: 0.05) : Colors.white),
                borderRadius: BorderRadius.circular(40),
                border: filled ? null : Border.all(color: _line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                      ),
                    ),
                  ),
                  if (widget.icon != null) ...[
                    const SizedBox(width: 10),
                    AnimatedSlide(
                      offset: Offset(_hover ? 0.25 : 0, 0),
                      duration: const Duration(milliseconds: 220),
                      child: FaIcon(widget.icon, size: 13, color: fg),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A link inside running text: pointer hand, colour on hover, opens [url].
class _Link extends StatefulWidget {
  const _Link({
    required this.label,
    required this.url,
    required this.style,
    required this.color,
  });

  final String label;
  final String url;
  final TextStyle style;
  final Color color;

  @override
  State<_Link> createState() => _LinkState();
}

class _LinkState extends State<_Link> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(widget.url),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            widget.label,
            style: widget.style.copyWith(
              color: widget.color,
              fontWeight: FontWeight.w700,
              decoration: _hover
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small rounded label above a heading.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label, {this.color = _blue});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: _ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Hero --------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({
    required this.wide,
    required this.vh,
    required this.loop,
    required this.onJump,
  });

  final bool wide;
  final double vh;
  final Animation<double> loop;
  final ValueChanged<String> onJump;

  @override
  Widget build(BuildContext context) {
    final cover = _texts(0);
    final title = cover.firstWhere((t) => t.size > 50).text;
    final name = cover.firstWhere((t) => t.size <= 50).text;
    final role = _texts(11)[1].text;
    final titleWords = title.split(' ');

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Reveal(child: _Eyebrow(role)),
        const SizedBox(height: 22),
        SplitWords(
          words: [
            for (var i = 0; i < titleWords.length; i++)
              // The first word is dark, the rest blue; a one-word title is blue.
              (titleWords[i], i == 0 && titleWords.length > 1 ? _ink : _blue),
          ],
          breaks: const {0},
          style: TextStyle(
            fontSize: wide ? 104 : 60,
            fontWeight: FontWeight.w700,
            height: 0.98,
            letterSpacing: wide ? -2 : -1,
          ),
        ),
        const SizedBox(height: 18),
        Reveal(
          delay: 380,
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              letterSpacing: 5,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Reveal(
          delay: 480,
          child: _Pill(
            label: _ui('View projects'),
            color: _coral,
            icon: FontAwesomeIcons.arrowRight,
            onTap: () => onJump('mola'),
          ),
        ),
        const SizedBox(height: 34),
        Reveal(
          delay: 580,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _projects.length; i++)
                _IndexChip(
                  number: '0${i + 1}',
                  label: _projects[i].name,
                  color: _projects[i].accent,
                  onTap: () => onJump(_projects[i].key),
                ),
            ],
          ),
        ),
      ],
    );

    if (wide) {
      final h = math.max(vh, 700.0);
      return SizedBox(
        height: h,
        child: _contain(
          max: 1320,
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: copy,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 6,
                child: _PhotoWall(height: h, loop: loop, columns: 4),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 108),
        _contain(copy, wide: false),
        const SizedBox(height: 28),
        _PhotoWall(height: 460, loop: loop, columns: 3),
      ],
    );
  }
}

class _IndexChip extends StatefulWidget {
  const _IndexChip({
    required this.number,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String number;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_IndexChip> createState() => _IndexChipState();
}

class _IndexChipState extends State<_IndexChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            decoration: BoxDecoration(
              color: _hover ? widget.color : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _hover ? widget.color : _line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hover
                        ? Colors.white.withValues(alpha: 0.2)
                        : widget.color.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    widget.number,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _hover ? Colors.white : widget.color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _hover ? Colors.white : _ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _wallColumns = <List<String>>[
  [
    'MAGkuXFxHdU',
    'MAGz-CmIfgc',
    'MAGkucVfCV0',
    'MAHFgY27r_s',
    'MAGkufQz0PU',
    'MAGz-A6IFRQ',
  ],
  [
    'MAGkudJgBcs',
    'MAHFfAL4vnI',
    'MAGkuT4jH1I',
    'MAGz-JzleAg',
    'MAGkub-DPzc',
    'MAHFfIoN29c',
  ],
  [
    'MAGz-bTLFKQ',
    'MAGkuY8MdE8',
    'MAHFgeuyVbA',
    'MAGkxuh2CnY',
    'MAGz-MPGUoc',
    'MAGkuZMkhn8',
  ],
  [
    'MAGkufxBG9U',
    'MAGz-IdgTsY',
    'MAHFcX2tLO8',
    'MAGkwuSB9l0',
    'MAGz-AibnvE',
    'MAGkwgDV7WQ',
  ],
];

/// The hero's 3D wall: columns of app screens on a tilted plane. Columns
/// drift up and down in turn on one shared loop, and the plane flattens and
/// grows as the hero scrolls away.
class _PhotoWall extends StatelessWidget {
  const _PhotoWall({
    required this.height,
    required this.loop,
    required this.columns,
  });

  final double height;
  final Animation<double> loop;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final tileW = columns > 3 ? 158.0 : 128.0;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: ScrollFx(
              fx: (t, size) {
                final k = v2Ease(v2Seg(t, 0.5, 1.0));
                return v2About(
                  size,
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.0009)
                    ..rotateX(v2Lerp(0.42, 0.08, k))
                    ..rotateZ(v2Lerp(-0.2, -0.05, k))
                    ..scaleByDouble(
                      v2Lerp(1.05, 1.18, k),
                      v2Lerp(1.05, 1.18, k),
                      1,
                      1,
                    ),
                );
              },
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < columns; c++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _DriftColumn(
                          ids: _wallColumns[c],
                          tileW: tileW,
                          up: c.isEven,
                          loop: loop,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Soft edges into the page.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bg, Color(0x00F6F5F1), Color(0x00F6F5F1), _bg],
                  stops: [0, 0.16, 0.8, 1],
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bg, Color(0x00F6F5F1), Color(0x00F6F5F1), _bg],
                  stops: [0, 0.08, 0.92, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriftColumn extends StatelessWidget {
  const _DriftColumn({
    required this.ids,
    required this.tileW,
    required this.up,
    required this.loop,
  });

  final List<String> ids;
  final double tileW;
  final bool up;
  final Animation<double> loop;

  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    final heights = [for (final id in ids) tileW / v2Ratio(id)];
    final period = heights.fold<double>(0, (a, h) => a + h + _gap);
    final tiles = <Widget>[
      for (var copy = 0; copy < 3; copy++)
        for (var i = 0; i < ids.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: _pic(ids[i], w: tileW, h: heights[i], radius: 20),
          ),
    ];
    return AnimatedBuilder(
      animation: loop,
      child: RepaintBoundary(
        child: Column(mainAxisSize: MainAxisSize.min, children: tiles),
      ),
      builder: (context, child) {
        final v = loop.value;
        final dy = -period + (up ? -v : v) * period;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

// --- Tech strip ------------------------------------------------------------------

/// The stack the PDF sets in bold, on a band that slides with the scroll.
class _TechStrip extends StatelessWidget {
  const _TechStrip();

  @override
  Widget build(BuildContext context) {
    final terms = <String>{
      for (final page in [2, 5, 11])
        for (final t in _texts(page)) ..._boldTerms(t.text),
    }.toList();
    final items = <Widget>[
      for (var r = 0; r < 4; r++)
        for (final term in terms) ...[
          Text(
            term,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: FaIcon(FontAwesomeIcons.asterisk, size: 14, color: _coral),
          ),
        ],
    ];
    return Container(
      height: 84,
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: _line)),
      ),
      child: ClipRect(
        child: ScrollFx(
          fx: (t, _) => Matrix4.translationValues(-60 - 520 * t, 0, 0),
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: Row(mainAxisSize: MainAxisSize.min, children: items),
          ),
        ),
      ),
    );
  }
}

// --- Cover stage -----------------------------------------------------------------

/// The cover photo, growing from an inset card to the full content width as
/// it scrolls in, with the cover's small pictures floating over it.
class _CoverStage extends StatelessWidget {
  const _CoverStage({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final cover = _texts(0);
    final title = cover.firstWhere((t) => t.size > 50).text;
    final role = _texts(11)[1].text;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: wide ? 72 : 40),
      child: _contain(
        max: 1320,
        wide: wide,
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            // Same proportions as the PDF cover (1366 x 768) on desktop.
            final h = wide ? w * kSlideH / kSlideW : w * 0.95;
            return SizedBox(
              width: w,
              height: h,
              child: ScrollFx(
                fx: (t, size) {
                  final k = v2Ease(v2Seg(t, 0.0, 0.45));
                  final s = v2Lerp(0.8, 1, k);
                  return v2About(
                    size,
                    Matrix4.identity()..scaleByDouble(s, s, 1, 1),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(wide ? 36 : 24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ScrollFx(
                        // The photo itself drifts slower: parallax.
                        fx: (t, size) => v2About(
                          size,
                          Matrix4.translationValues(0, (t - 0.5) * 70, 0)
                            ..scaleByDouble(1.12, 1.12, 1, 1),
                        ),
                        child: _CoverPhoto(w: w, h: h),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0xB0000000)],
                            stops: [0.45, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: wide ? 44 : 22,
                        right: wide ? 44 : 22,
                        bottom: wide ? 40 : 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Reveal(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: wide ? 64 : 34,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Reveal(
                              delay: 140,
                              child: Text(
                                role,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: wide ? 20 : 15,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The cover slide of the PDF, drawn at the PDF's own positions: the room
/// photo, the screenshot on the laptop screen and the name on the board. The
/// slide is scaled to cover the box, so on a phone its sides are cropped.
class _CoverPhoto extends StatelessWidget {
  const _CoverPhoto({required this.w, required this.h});

  final double w;
  final double h;

  @override
  Widget build(BuildContext context) {
    final page = kSlidePages[0].items;
    final room = page.whereType<SlideImage>().firstWhere(
      (i) => i.mediaId == 'MAGkxeWv44o',
    );
    final screen = page.whereType<SlideImage>().firstWhere(
      (i) => i.mediaId == 'MAGkxij3D6k',
    );
    final name = page.whereType<SlideText>().firstWhere(
      (t) => t.text == 'KIKI TRIANSYAH',
    );

    const ar = kSlideW / kSlideH;
    var fw = w;
    var fh = w / ar;
    if (fh < h) {
      fh = h;
      fw = h * ar;
    }
    final s = fw / kSlideW;
    final ox = (w - fw) / 2;
    final oy = (h - fh) / 2;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: ox + room.imgLeft * s,
          top: oy + room.imgTop * s,
          width: (room.imgWidth ?? room.width) * s,
          height: (room.imgHeight ?? room.height) * s,
          child: LazyPic(_v2Path(room.mediaId), fit: BoxFit.cover),
        ),
        Positioned(
          left: ox + screen.left * s,
          top: oy + screen.top * s,
          width: screen.width * s,
          height: screen.height * s,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: screen.imgLeft * s,
                  top: screen.imgTop * s,
                  width: (screen.imgWidth ?? screen.width) * s,
                  height: (screen.imgHeight ?? screen.height) * s,
                  child: LazyPic(_v2Path(screen.mediaId), fit: BoxFit.cover),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: ox + name.left * s,
          top: oy + name.top * s,
          width: name.width * s,
          child: Text(
            name.text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: const Color(0xFF000000),
              fontSize: name.size * s,
              height: name.lh,
            ),
          ),
        ),
      ],
    );
  }
}

/// Moves [child] against the scroll by up to [speed] px and eases its tilt
/// toward [rotate]: the "floating widget" layer.
class _Floating extends StatelessWidget {
  const _Floating({required this.child, this.speed = 80, this.rotate = 0});

  final Widget child;
  final double speed;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      dy: 40,
      scale: 0.9,
      motion: false,
      child: ScrollFx(
        fx: (t, size) => v2About(
          size,
          Matrix4.translationValues(0, (0.5 - t) * speed, 0)
            ..rotateZ(rotate * v2Lerp(1.6, 0.6, t.clamp(0.0, 1.0))),
        ),
        child: child,
      ),
    );
  }
}

// --- Project chapter ---------------------------------------------------------------

class _Chapter extends StatelessWidget {
  const _Chapter({
    required this.project,
    required this.index,
    required this.wide,
  });

  final _Project project;
  final int index;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = project;
    return Padding(
      padding: EdgeInsets.only(top: wide ? 110 : 76),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _contain(
            _ChapterHead(project: p, index: index, wide: wide),
            wide: wide,
          ),
          SizedBox(height: wide ? 36 : 24),
          _contain(
            _Stage(project: p, wide: wide),
            max: 1400,
            wide: wide,
          ),
          SizedBox(height: wide ? 80 : 52),
          _contain(
            _WhatIs(project: p, wide: wide),
            wide: wide,
          ),
          if (p.challengePage != null) ...[
            SizedBox(height: wide ? 90 : 60),
            _contain(
              _Challenge(project: p, wide: wide),
              wide: wide,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChapterHead extends StatelessWidget {
  const _ChapterHead({
    required this.project,
    required this.index,
    required this.wide,
  });

  final _Project project;
  final int index;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final logoH = wide ? 64.0 : 46.0;
    final number = Reveal(
      dx: -30,
      dy: 0,
      child: Text(
        '0${index + 1}',
        style: TextStyle(
          fontSize: wide ? 150 : 92,
          fontWeight: FontWeight.w700,
          height: 0.9,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = p.accent,
        ),
      ),
    );
    final logo = Reveal(
      delay: 120,
      motion: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          // Lifeline's wordmark is partly white: it sits on its brand colours.
          color: p.logoOnDark ? null : Colors.white,
          gradient: p.logoOnDark ? _gradient(p.grad, p.gradAngle) : null,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
        ),
        child: _pic(
          p.logo,
          w: logoH * p.logoBox,
          h: logoH,
          fit: BoxFit.cover,
          placeholder: Colors.transparent,
        ),
      ),
    );
    // One size for the whole title: the fitted size of its longest word.
    final title = SplitWords(
      words: [(_ui('Project'), _ink), (p.name, p.accent)],
      style: const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.5,
      ),
    );
    if (!wide) {
      // On a phone the number sits above the title, so the name has the full
      // width of the page.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          number,
          const SizedBox(height: 10),
          title,
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: math.min(c.maxWidth, logoH * p.logoBox + 38),
                child: logo,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        number,
        const SizedBox(width: 28),
        Expanded(child: title),
        logo,
      ],
    );
  }
}

/// The project's brand gradient with two rows of screens moving in
/// opposite directions as the page scrolls.
class _Stage extends StatelessWidget {
  const _Stage({required this.project, required this.wide});

  final _Project project;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final rowH = wide ? 300.0 : 190.0;
    return Reveal(
      dy: 50,
      scale: 0.96,
      ms: 1100,
      motion: false,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: wide ? 34 : 20),
        decoration: BoxDecoration(
          gradient: _gradient(p.grad, p.gradAngle),
          borderRadius: BorderRadius.circular(wide ? 40 : 26),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _OpposingRow(
              ids: wide
                  ? p.rowA
                  : [
                      for (final id in p.rowA)
                        if (v2Ratio(id) < 1) id,
                    ],
              height: rowH,
              reverse: false,
            ),
            SizedBox(height: wide ? 18 : 12),
            _OpposingRow(
              ids: wide
                  ? p.rowB
                  : [
                      for (final id in p.rowB)
                        if (v2Ratio(id) < 1) id,
                    ],
              height: rowH,
              reverse: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OpposingRow extends StatelessWidget {
  const _OpposingRow({
    required this.ids,
    required this.height,
    required this.reverse,
  });

  final List<String> ids;
  final double height;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          // Repeat the screens until the row is well wider than the stage.
          final tiles = <Widget>[];
          var rowW = 0.0;
          var i = 0;
          while (rowW < w + 600 || i < ids.length) {
            final id = ids[i % ids.length];
            final tw = height * v2Ratio(id);
            tiles.add(
              Padding(
                padding: const EdgeInsets.only(right: gap),
                child: _pic(
                  id,
                  w: tw,
                  h: height,
                  radius: 18,
                  placeholder: const Color(0x22FFFFFF),
                ),
              ),
            );
            rowW += tw + gap;
            i++;
          }
          final shift = math.min(rowW - w, 560.0);
          return ClipRect(
            child: ScrollFx(
              fx: (t, _) {
                final k = t.clamp(0.0, 1.0);
                final x = reverse ? -shift * (1 - k) : -shift * k;
                return Matrix4.translationValues(x + 24, 0, 0);
              },
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: Row(mainAxisSize: MainAxisSize.min, children: tiles),
              ),
            ),
          );
        },
      ),
    );
  }
}

const _bodySize = 18.5;

TextStyle _body(bool wide) => TextStyle(
  fontSize: wide ? _bodySize : 16.5,
  height: 1.62,
  color: _ink2,
  letterSpacing: 0.15,
);

TextStyle _heading(bool wide) => TextStyle(
  fontSize: wide ? 44 : 31,
  fontWeight: FontWeight.w700,
  height: 1.08,
  letterSpacing: -0.4,
);

/// Index of the first word after "the", for colouring the subject.
int _subjectFrom(String heading) {
  final ws = heading.replaceAll('\n', ' ').split(RegExp(r'\s+'));
  final i = ws.indexWhere((w) {
    final lower = w.toLowerCase();
    return lower == 'the' || lower == 'aplikasi';
  });
  return i < 0 ? ws.length : i + 1;
}

class _Paragraphs extends StatelessWidget {
  const _Paragraphs({
    required this.text,
    required this.style,
    required this.link,
    this.delay = 0,
  });

  final String text;
  final TextStyle style;
  final Color link;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final paras = _paras(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paras.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
            child: Reveal(
              delay: delay + 110 * i,
              dy: 22,
              child: Text.rich(_rich(paras[i], style, link: link)),
            ),
          ),
      ],
    );
  }
}

class _WhatIs extends StatelessWidget {
  const _WhatIs({required this.project, required this.wide});

  final _Project project;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final t = _texts(p.infoPage);
    final heading = t[0].text;
    final body = t[1].text;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(child: _Eyebrow(_ui('Overview'), color: p.accent)),
        const SizedBox(height: 18),
        SplitWords(
          words: _words(heading, _subjectFrom(heading), p.accent),
          style: _heading(wide),
        ),
        const SizedBox(height: 22),
        _Paragraphs(text: body, style: _body(wide), link: p.accent, delay: 150),
        if (t.length >= 4) ...[
          const SizedBox(height: 30),
          Reveal(
            delay: 120,
            child: _Callout(
              heading: t[2].text,
              body: t[3].text,
              accent: p.accent,
              wide: wide,
            ),
          ),
        ],
      ],
    );
    final feature = p.feature.length == 1
        ? _FeaturePicture(
            id: p.feature.first,
            terms: _boldTerms(body),
            icon: p.icon,
            accent: p.accent,
            wide: wide,
          )
        : _PhoneFan(ids: p.feature, icon: p.icon, wide: wide);
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [copy, const SizedBox(height: 44), feature],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 11, child: copy),
        const SizedBox(width: 64),
        Expanded(flex: 10, child: feature),
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.heading,
    required this.body,
    required this.accent,
    required this.wide,
  });

  final String heading;
  final String body;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(wide ? 26 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: FaIcon(FontAwesomeIcons.trophy, size: 18, color: accent),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: wide ? 23 : 19.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(_rich(_paras(body).join(' '), _body(wide))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A feature picture that grows into place as it scrolls in, with the
/// project's tech terms in a row over its top edge.
class _FeaturePicture extends StatelessWidget {
  const _FeaturePicture({
    required this.id,
    required this.terms,
    required this.icon,
    required this.accent,
    required this.wide,
  });

  final String id;
  final List<String> terms;
  final String? icon;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = w / v2Ratio(id);
        return SizedBox(
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ScrollFx(
                  fx: (t, size) {
                    final k = v2Ease(v2Seg(t, 0.05, 0.5));
                    final s = v2Lerp(0.82, 1, k);
                    return v2About(
                      size,
                      Matrix4.identity()
                        ..rotateZ(v2Lerp(-0.06, 0, k))
                        ..scaleByDouble(s, s, 1, 1),
                    );
                  },
                  child: _pic(id, w: w, h: h, radius: wide ? 32 : 22),
                ),
              ),
              // The terms sit in one neat row over the top edge: the first on
              // the left, the second on the right. Nothing moves with the
              // scroll, so they never drift onto the logo.
              for (var i = 0; i < math.min(terms.length, 2); i++)
                Positioned(
                  left: i == 0 ? 14 : null,
                  right: i == 1 ? 14 : null,
                  top: -18,
                  child: Reveal(
                    delay: 300 + 120 * i,
                    dy: 12,
                    child: _Chip(label: terms[i], accent: accent),
                  ),
                ),
              // The app logo sits in the bottom-right corner, away from the
              // terms.
              if (icon != null)
                Positioned(
                  right: wide ? -18 : -6,
                  bottom: wide ? -26 : -18,
                  child: _Badge(id: icon!, size: wide ? 88 : 64),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.code, size: 12, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.id, required this.size});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: _pic(
        id,
        w: size - 12,
        h: size - 12,
        radius: size * 0.22,
        fit: BoxFit.contain,
        placeholder: Colors.transparent,
      ),
    );
  }
}

/// Three phone screens that fan out from a stack as they scroll in.
class _PhoneFan extends StatelessWidget {
  const _PhoneFan({required this.ids, required this.icon, required this.wide});

  final List<String> ids;
  final String? icon;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final phoneW = math.min(wide ? 210.0 : 160.0, c.maxWidth * 0.42);
        final phoneH = phoneW / (9 / 19.5);
        final spread = math.min(phoneW * 0.66, (c.maxWidth - phoneW) / 2);
        // Back phones first, the middle one on top.
        const order = [-1, 1, 0];
        return SizedBox(
          height: phoneH + 70,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              for (final j in order)
                ScrollFx(
                  fx: (t, size) {
                    final k = v2Ease(v2Seg(t, 0.08, 0.5));
                    final m = Matrix4.translationValues(
                      j * spread * k,
                      j.abs() * 26.0 * k + (1 - k) * 30,
                      0,
                    )..rotateZ(j * 0.13 * k);
                    return v2About(size, m, ay: 1);
                  },
                  child: _Phone(id: ids[j + 1], width: phoneW, height: phoneH),
                ),
              if (icon != null)
                Positioned(
                  right: wide ? 0 : -4,
                  top: -10,
                  child: _Floating(
                    speed: 120,
                    rotate: 0.08,
                    child: _Badge(id: icon!, size: wide ? 92 : 66),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({required this.id, required this.width, required this.height});

  final String id;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(width * 0.16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: _pic(
        id,
        w: width - 12,
        h: height - 12,
        radius: width * 0.13,
        align: Alignment.topCenter,
        placeholder: const Color(0xFF2A2D38),
      ),
    );
  }
}

class _Challenge extends StatelessWidget {
  const _Challenge({required this.project, required this.wide});

  final _Project project;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final t = _texts(p.challengePage!);
    final heading = t[0].text;
    final ws = heading.replaceAll('\n', ' ').split(RegExp(r'\s+'));
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(child: _Eyebrow(_ui('Challenge'), color: p.accent)),
        const SizedBox(height: 18),
        SplitWords(
          words: _words(heading, ws.length - 2, p.accent),
          style: _heading(wide).copyWith(fontSize: wide ? 38 : 28),
        ),
        const SizedBox(height: 22),
        _Paragraphs(text: t[1].text, style: _body(wide), link: p.accent),
      ],
    );
    final media = p.challengeShots.length == 2
        ? _ParallaxPair(ids: p.challengeShots, wide: wide)
        : _StackedShots(ids: p.challengeShots, wide: wide);
    return Container(
      padding: EdgeInsets.all(wide ? 48 : 22),
      decoration: BoxDecoration(
        color: Color.lerp(_bg, p.accent, 0.07),
        borderRadius: BorderRadius.circular(wide ? 40 : 28),
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 9, child: media),
                const SizedBox(width: 56),
                Expanded(flex: 11, child: copy),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 32), media],
            ),
    );
  }
}

/// Two phone screens drifting in opposite directions.
class _ParallaxPair extends StatelessWidget {
  const _ParallaxPair({required this.ids, required this.wide});

  final List<String> ids;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pw = math.min((c.maxWidth - 20) / 2, wide ? 230.0 : 160.0);
        final ph = pw / v2Ratio(ids[0]);
        return SizedBox(
          height: ph + 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < ids.length; i++) ...[
                if (i > 0) const SizedBox(width: 20),
                ScrollFx(
                  fx: (t, _) => Matrix4.translationValues(
                    0,
                    (i.isEven ? 1 : -1) * (t - 0.5) * 90,
                    0,
                  ),
                  child: Reveal(
                    delay: 140 * i,
                    dy: 60,
                    motion: false,
                    child: _pic(ids[i], w: pw, h: ph, radius: 24),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Landscape shots sliding in from the side one after another, staggered.
class _StackedShots extends StatelessWidget {
  const _StackedShots({required this.ids, required this.wide});

  final List<String> ids;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth * 0.86;
        final h = w / v2Ratio(ids[0]);
        return Column(
          children: [
            for (var i = 0; i < ids.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                child: Align(
                  alignment: i.isOdd
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Reveal(
                    delay: 160 * i,
                    dx: i.isOdd ? 80 : -80,
                    dy: 0,
                    motion: false,
                    child: _pic(ids[i], w: w, h: h, radius: 20),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// --- About and contact -------------------------------------------------------------

class _About extends StatelessWidget {
  const _About({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = _texts(11);
    final name = t[0].text;
    final role = t[1].text;
    final aboutHead = t[2].text;
    final contactHead = t[5].text;
    final contacts = t.sublist(6);

    final profile = _Floating(
      speed: 60,
      rotate: -0.03,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pic(
                  'MAHFgTnAz5s',
                  w: w,
                  h: w / v2Ratio('MAHFgTnAz5s'),
                  radius: 22,
                  align: Alignment.topCenter,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15.5, color: _muted),
                ),
                const SizedBox(height: 6),
              ],
            );
          },
        ),
      ),
    );

    final about = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SplitWords(
          words: _words(aboutHead, 1, _blue),
          style: _heading(wide).copyWith(fontSize: wide ? 64 : 44),
        ),
        const SizedBox(height: 22),
        _Paragraphs(text: t[3].text, style: _body(wide), link: _blue),
        const SizedBox(height: 18),
        Reveal(
          delay: 100,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _blue.withValues(alpha: 0.18)),
            ),
            child: Text.rich(_rich(_paras(t[4].text).join(' '), _body(wide))),
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: wide ? 140 : 90, bottom: wide ? 120 : 80),
      child: _contain(
        wide: wide,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 360, child: profile),
                  const SizedBox(width: 72),
                  Expanded(child: about),
                ],
              )
            else ...[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: profile,
                ),
              ),
              const SizedBox(height: 44),
              about,
            ],
            SizedBox(height: wide ? 110 : 70),
            Center(
              child: SplitWords(
                words: _words(contactHead, 0, _ink),
                style: _heading(wide).copyWith(fontSize: wide ? 60 : 42),
              ),
            ),
            SizedBox(height: wide ? 48 : 30),
            _ContactWeb(lines: contacts, wide: wide),
          ],
        ),
      ),
    );
  }
}

/// Contact cards joined by a wire that draws itself as they come in.
class _ContactWeb extends StatelessWidget {
  const _ContactWeb({required this.lines, required this.wide});

  final List<SlideText> lines;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 900 ? 3 : (w >= 600 ? 2 : 1);
        const gap = 22.0;
        const cardH = 96.0;
        final rowGap = cols > 1 ? 70.0 : 18.0;
        final stagger = cols > 1 ? 34.0 : 0.0;
        final cardW = (w - gap * (cols - 1)) / cols;
        final n = lines.length;
        final rows = (n / cols).ceil();
        final rects = <Rect>[];
        for (var i = 0; i < n; i++) {
          final r = i ~/ cols;
          final col = i % cols;
          rects.add(
            Rect.fromLTWH(
              col * (cardW + gap),
              r * (cardH + rowGap) + (col.isOdd ? stagger : 0),
              cardW,
              cardH,
            ),
          );
        }
        final height = rows * cardH + (rows - 1) * rowGap + stagger;
        // The wire visits the cards row by row, snaking back on odd rows;
        // in one column it runs through the icons.
        final order = <int>[];
        for (var r = 0; r < rows; r++) {
          final row = [
            for (var col = 0; col < cols; col++)
              if (r * cols + col < n) r * cols + col,
          ];
          order.addAll(r.isOdd ? row.reversed : row);
        }
        final points = [
          for (final i in order)
            cols == 1
                ? Offset(rects[i].left + 40, rects[i].center.dy)
                : rects[i].center,
        ];
        return InView(
          duration: const Duration(milliseconds: 1800),
          at: 0.85,
          builder: (context, a, _) => SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WirePainter(points: points, progress: a),
                  ),
                ),
                for (var k = 0; k < order.length; k++)
                  Positioned.fromRect(
                    rect: rects[order[k]],
                    child: _CardIn(
                      progress: a,
                      start: k / (order.length + 1),
                      child: _ContactCard(
                        icon: _contactIcons[order[k]],
                        line: lines[order[k]],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardIn extends StatelessWidget {
  const _CardIn({
    required this.progress,
    required this.start,
    required this.child,
  });

  final Animation<double> progress;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final v = v2Ease(v2Seg(progress.value, start, start + 0.35));
        if (v >= 1) return child!;
        // Moves and grows into place; no fade, so nothing blinks.
        return Transform.translate(
          offset: Offset(0, 24 * (1 - v)),
          child: Transform.scale(scale: v2Lerp(0.92, 1, v), child: child),
        );
      },
    );
  }
}

class _WirePainter extends CustomPainter {
  _WirePainter({required this.points, required this.progress})
    : super(repaint: progress);

  final List<Offset> points;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final mx = (a.dx + b.dx) / 2;
      if ((a.dx - b.dx).abs() < 1) {
        // Same column: bow out sideways.
        final bow = 60.0;
        path.cubicTo(a.dx + bow, a.dy, b.dx + bow, b.dy, b.dx, b.dy);
      } else {
        path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
      }
    }
    final v = Curves.easeInOutCubic.transform(progress.value);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [_blue, _coral],
      ).createShader(Offset.zero & size);
    Offset? head;
    for (final metric in path.computeMetrics()) {
      final len = metric.length * v;
      canvas.drawPath(metric.extractPath(0, len), paint);
      head = metric.getTangentForOffset(len)?.position;
    }
    if (head != null && v > 0 && v < 1) {
      canvas.drawCircle(head, 5, Paint()..color = _coral);
    }
  }

  @override
  bool shouldRepaint(_WirePainter old) => old.points != points;
}

class _ContactCard extends StatefulWidget {
  const _ContactCard({required this.icon, required this.line});

  final String icon;
  final SlideText line;

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -5 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _hover ? _blue : _line, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: _pic(
                widget.icon,
                w: 28,
                h: 28,
                fit: BoxFit.contain,
                placeholder: Colors.transparent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text.rich(
                _rich(
                  widget.line.text,
                  const TextStyle(
                    fontSize: 16,
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
