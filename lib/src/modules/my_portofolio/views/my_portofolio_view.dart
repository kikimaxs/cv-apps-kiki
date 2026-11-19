import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show ValueListenable, kIsWeb, setEquals;
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

// ---------------------------------------------------------------------------
// Portfolio page: the 12 pages of the portfolio PDF.
//
// Landscape and desktop: each page fills one screen. The design covers the
// screen when all its content still fits that way, otherwise it is fitted below
// the header, and scrolling snaps from page to page.
//
// Portrait (phones and tablets): the cover is its photo, full screen, with the
// title and name over it. The other pages reflow into one column: text keeps
// its paragraphs, and pictures fill the width in rows of two to four.
//
// The header is transparent and floats over the pages. Links are the PDF's own:
// a link opens its address on tap, and turns blue while the pointer is over it.
//
// No GlobalKeys and no lookups of inherited widgets outside build: both break
// when the layout changes under hot reload. Landscape positions are computed
// from the page index; portrait pages are measured through their contexts.
// ---------------------------------------------------------------------------

const _barColor = Color(0xFF0B1220);
const _accent = Color(0xFF67D4FF);
const _linkBlue = Color(0xFF004AAD);

/// The header's height. It floats transparently over the pages, and each page
/// keeps this much room at its top for its own content.
const _headerH = 56.0;

/// Top-bar links and the first page each one opens.
const _chips = <(String, int)>[
  ('Cover', 0),
  ('MOLA TV', 1),
  ('Durioo+', 4),
  ('HadIR', 7),
  ('Lifeline', 9),
  ('Kontak', 11),
];

class MyPortofolioView extends StatefulWidget {
  const MyPortofolioView({super.key});

  @override
  State<MyPortofolioView> createState() => _MyPortofolioViewState();
}

class _MyPortofolioViewState extends State<MyPortofolioView> {
  final ScrollController _scroll = ScrollController();
  // The scroll offset, shared with the landscape pages so each one knows
  // whether it is near the screen. Updated every ~60px of scrolling.
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);
  final ValueNotifier<int> _current = ValueNotifier<int>(0);
  final ValueNotifier<bool> _exporting = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showTop = ValueNotifier<bool>(false);
  // Portrait pages whose pictures load now: those within a screen of the view.
  final ValueNotifier<Set<int>> _near = ValueNotifier<Set<int>>({0, 1});
  bool _nearPending = false;
  // Each portrait page's build context, to measure where it starts.
  final List<BuildContext?> _pageCtx = List<BuildContext?>.filled(
    kSlidePages.length,
    null,
  );
  double _viewportH = 0;
  double _lastOffset = -1000;
  bool _snapping = false;
  bool _portrait = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    _current.dispose();
    _exporting.dispose();
    _showTop.dispose();
    _near.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pixels = _scroll.position.pixels;
    _showTop.value = pixels > 600;
    _updateCurrent();
    _scheduleNear();
    // Lazy pages are checked every ~60px of scrolling, not on every frame.
    if ((pixels - _lastOffset).abs() < 60) return;
    _lastOffset = pixels;
    _offset.value = pixels;
  }

  /// Schedules the check of which portrait pages are near the screen. It runs
  /// after the frame is laid out, never inside build or layout.
  void _scheduleNear() {
    if (_nearPending || !_portrait) return;
    _nearPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nearPending = false;
      if (mounted) _updateNear();
    });
  }

  /// The portrait pages within a screen above or below the view. Their pictures
  /// load; the others wait, so a phone fetches what it shows.
  void _updateNear() {
    if (!_portrait || !_scroll.hasClients || _viewportH <= 0) return;
    final tops = _pageTops();
    if (tops.length != kSlidePages.length) return;
    final pos = _scroll.position;
    final lo = pos.pixels - _viewportH;
    final hi = pos.pixels + 2 * _viewportH;
    final near = <int>{};
    for (var i = 0; i < kSlidePages.length; i++) {
      final box = _pageCtx[i]?.findRenderObject();
      final h = box is RenderBox && box.hasSize ? box.size.height : 0.0;
      if (tops[i] + h > lo && tops[i] < hi) near.add(i);
    }
    if (!setEquals(near, _near.value)) _near.value = near;
  }

  void _scrollToTop() {
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _exportPdf() async {
    if (_exporting.value) return;
    _exporting.value = true;
    // Looked up before the wait, so no inherited widget is read after it.
    final messenger = context.findAncestorStateOfType<ScaffoldMessengerState>();
    try {
      final bytes = await buildPortfolioPdf();
      if (kIsWeb) {
        await savePdf(bytes, 'portofolio_kiki_triansyah.pdf');
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      }
      if (mounted) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('PDF portofolio siap diunduh.')),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Gagal membuat PDF portofolio.')),
        );
      }
    } finally {
      _exporting.value = false;
    }
  }

  /// The page the header's links mark as current, in landscape: the page that
  /// passes a probe line 40% down the screen, and the last page at the very end.
  void _updateCurrent() {
    if (_portrait || !_scroll.hasClients || _viewportH <= 0) return;
    final pos = _scroll.position;
    final last = kSlidePages.length - 1;
    final index = pos.pixels >= pos.maxScrollExtent - 4
        ? last
        : ((pos.pixels + _viewportH * 0.4) / _viewportH).floor().clamp(0, last);
    if (_current.value != index) _current.value = index;
  }

  void _jumpTo(int index) {
    if (!_scroll.hasClients) return;
    final tops = _pageTops();
    if (index >= tops.length) return;
    _scroll.animateTo(
      tops[index]
          .clamp(0.0, math.max(0.0, _scroll.position.maxScrollExtent))
          .toDouble(),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Scroll offsets where each page starts. In landscape every page is one
  /// screen tall; in portrait the pages are measured.
  List<double> _pageTops() {
    if (!_portrait) {
      return [for (var i = 0; i < kSlidePages.length; i++) i * _viewportH];
    }
    final first = _pageCtx.first?.findRenderObject();
    if (first is! RenderBox || !first.attached || !first.hasSize) {
      return const [];
    }
    final base = first.localToGlobal(Offset.zero).dy;
    final tops = <double>[];
    for (final ctx in _pageCtx) {
      final box = ctx?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        tops.add(box.localToGlobal(Offset.zero).dy - base);
      }
    }
    return tops;
  }

  /// Scroll-snap: once scrolling stops, settle on the nearest page start. A
  /// portrait page can be taller than the screen, so there we snap only when
  /// the reader stopped near a page start, and never skip past a long page.
  Future<void> _snapToPage() async {
    if (_snapping || !_scroll.hasClients) return;
    final pos = _scroll.position;
    final tops = _pageTops();
    if (tops.isEmpty) return;
    final cur = pos.pixels;
    var best = tops.first;
    var bestDist = double.infinity;
    for (final t in tops) {
      final d = (t - cur).abs();
      if (d < bestDist) {
        bestDist = d;
        best = t;
      }
    }
    final limit = _portrait
        ? pos.viewportDimension * 0.35
        : pos.viewportDimension;
    if (bestDist < 1 || bestDist > limit) return;
    final target = best
        .clamp(0.0, math.max(0.0, pos.maxScrollExtent))
        .toDouble();
    _snapping = true;
    try {
      await _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _snapping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: _barColor,
      body: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'Carlito'),
        child: LayoutBuilder(
          builder: (context, c) {
            final portrait = c.maxHeight > c.maxWidth || c.maxWidth < 700;
            _portrait = portrait;
            _viewportH = c.maxHeight;
            if (portrait) _scheduleNear();
            final width = c.maxWidth;
            final height = c.maxHeight;
            return Stack(
              children: [
                _ScrollTick(
                  offset: _offset,
                  child: NotificationListener<ScrollEndNotification>(
                    onNotification: (_) {
                      // After this frame: an animation started inside the end
                      // notification would be replaced at once.
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _snapToPage(),
                      );
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _scroll,
                      child: Column(
                        children: [
                          for (var i = 0; i < kSlidePages.length; i++)
                            portrait
                                ? Builder(
                                    builder: (context) {
                                      _pageCtx[i] = context;
                                      return _PictureGate(
                                        near: _near,
                                        index: i,
                                        child: _phonePage(
                                          i,
                                          kSlidePages[i],
                                          width,
                                          height,
                                        ),
                                      );
                                    },
                                  )
                                : _Lazy(
                                    index: i,
                                    height: height,
                                    aspect: height > 0 ? width / height : 1.0,
                                    builder: (_) => _SlidePageView(
                                      page: kSlidePages[i],
                                      width: width,
                                      height: height,
                                    ),
                                  ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopBar(
                    wide: wide,
                    current: _current,
                    onJump: _jumpTo,
                    onBack: () => context.go('/'),
                    exporting: _exporting,
                    onExportPdf: _exportPdf,
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _BackToTop(show: _showTop, onTap: _scrollToTop),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Landscape and desktop: one page per screen.
// ---------------------------------------------------------------------------

/// A page scaled to the screen. Its background runs over the whole screen,
/// under the transparent header. The design sits below the header, except the
/// cover, whose photo covers the whole screen.
class _SlidePageView extends StatelessWidget {
  const _SlidePageView({
    required this.page,
    required this.width,
    required this.height,
  });

  final SlidePage page;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final top = _fullBleed(page) != null ? 0.0 : _headerH;
    // A window shorter than the header leaves no area for the design: it is
    // drawn at zero size, never at a negative one.
    final areaH = math.max(0.0, height - top);
    final s = _pageScale(page, math.max(0.0, width), areaH);
    final dw = kSlideW * s;
    final dh = kSlideH * s;
    // Positioned, not Center: the design can be wider than the screen (cover
    // scale), and a centred SizedBox would be squeezed to the screen's width.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _gradient(page.bg),
        color: page.bg.colors.first,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: (width - dw) / 2,
            top: top + (areaH - dh) / 2,
            width: dw,
            height: dh,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [for (final item in page.items) _place(item, s)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The scale for one landscape page: cover when all its text and pictures
/// still fit that way (no bands at the edges), otherwise fit.
double _pageScale(SlidePage page, double width, double height) {
  if (width <= 0 || height <= 0) return 0;
  final cover = math.max(width / kSlideW, height / kSlideH);
  final contain = math.min(width / kSlideW, height / kSlideH);
  final photo = _fullBleed(page);
  var l = double.infinity;
  var t = double.infinity;
  var r = double.negativeInfinity;
  var b = double.negativeInfinity;
  for (final item in page.items) {
    if (identical(item, photo)) continue;
    l = math.min(l, _leftOf(item));
    t = math.min(t, _topOf(item));
    r = math.max(r, _leftOf(item) + _widthOf(item));
    b = math.max(b, _topOf(item) + _heightOf(item));
  }
  if (l > r) return contain;
  bool fits(double s) {
    final dx = (width - kSlideW * s) / 2;
    final dy = (height - kSlideH * s) / 2;
    return dx + l * s >= 0 &&
        dx + r * s <= width &&
        dy + t * s >= 0 &&
        dy + b * s <= height;
  }

  return fits(cover) ? cover : contain;
}

/// Canva's gradient angle: 90 runs left to right, 0 top to bottom, and 45
/// bottom-left to top-right. The first colour sits at the start of the line.
LinearGradient _gradient(SlideBg bg) {
  final rad = bg.angle * math.pi / 180;
  final dx = math.sin(rad);
  final dy = -math.cos(rad);
  return LinearGradient(
    begin: Alignment(-dx, -dy),
    end: Alignment(dx, dy),
    colors: bg.colors,
  );
}

Widget _place(SlideItem item, double s) {
  if (item is SlideImage) return _placeImage(item, s);
  return _placeText(item as SlideText, s);
}

/// A picture at its design place, scaled by [s]. [dx] and [dy] move the whole
/// design (the portrait cover uses them to centre its photo).
Widget _placeImage(SlideImage item, double s, {double dx = 0, double dy = 0}) {
  final w = item.width * s;
  final h = item.height * s;
  Widget content = SizedBox(
    width: w,
    height: h,
    child: _pictureBox(item, s, s),
  );
  if (item.rot != 0) {
    content = Transform.rotate(angle: item.rot * math.pi / 180, child: content);
  }
  return Positioned(
    left: dx + item.left * s,
    top: dy + item.top * s,
    width: w,
    height: h,
    child: content,
  );
}

Widget _placeText(SlideText item, double s) {
  return Positioned(
    left: item.left * s,
    top: item.top * s,
    width: item.width * s,
    child: _designText(item, s),
  );
}

/// Text at the design's own proportions, scaled by [s].
Widget _designText(SlideText item, double s) {
  final multi = item.text.contains('\n') || item.text.length > 60;
  return Text.rich(
    _rich(
      item.text,
      TextStyle(
        fontSize: item.size * s,
        height: item.lh,
        color: item.color,
        fontWeight: item.weight,
        letterSpacing: item.spacing * s,
      ),
    ),
    textAlign: item.align,
    softWrap: multi,
    overflow: TextOverflow.visible,
  );
}

/// A picture inside its frame. [sx] and [sy] scale design units to pixels; the
/// caller sizes the frame, and the picture is cropped to it as in the design.
Widget _pictureBox(SlideImage item, double sx, double sy) {
  final path = kSlideAssets[item.mediaId];
  if (path == null) return const SizedBox.shrink();
  final Widget picture = _LazyPicture(path: path);
  Widget content = ClipRect(
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: item.imgLeft * sx,
          top: item.imgTop * sy,
          width: (item.imgWidth ?? item.width) * sx,
          height: (item.imgHeight ?? item.height) * sy,
          child: picture,
        ),
      ],
    ),
  );
  if (item.opacity < 1) {
    content = Opacity(opacity: item.opacity, child: content);
  }
  return content;
}

/// Gives a portrait page the set of pages near the screen. A picture loads only
/// while its page is in that set, so a phone fetches what it shows, not all of
/// the portfolio's pictures at once.
class _PictureGate extends InheritedNotifier<ValueListenable<Set<int>>> {
  const _PictureGate({
    required ValueListenable<Set<int>> near,
    required this.index,
    required super.child,
  }) : super(notifier: near);

  final int index;

  @override
  bool updateShouldNotify(covariant _PictureGate oldWidget) =>
      oldWidget.index != index || super.updateShouldNotify(oldWidget);
}

/// A picture of the design. Outside its page's neighbourhood it is an empty box
/// of the same size, so nothing is fetched or decoded until the page is near.
/// Without a gate (landscape) it always loads.
class _LazyPicture extends StatelessWidget {
  const _LazyPicture({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final gate = context.dependOnInheritedWidgetOfExactType<_PictureGate>();
    final load =
        gate == null || (gate.notifier?.value.contains(gate.index) ?? true);
    if (!load) return const SizedBox.expand();
    return path.endsWith('.svg')
        ? SvgPicture.asset(path, fit: BoxFit.fill)
        : Image.asset(
            path,
            fit: BoxFit.fill,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          );
  }
}

// ---------------------------------------------------------------------------
// Shared geometry of the design's items.
// ---------------------------------------------------------------------------

/// The page's full-bleed photo (the cover's), when it has one.
SlideImage? _fullBleed(SlidePage page) {
  for (final item in page.items) {
    if (item is SlideImage && item.width >= 1300 && item.height >= 600) {
      return item;
    }
  }
  return null;
}

double _topOf(SlideItem item) =>
    item is SlideText ? item.top : (item as SlideImage).top;

double _leftOf(SlideItem item) =>
    item is SlideText ? item.left : (item as SlideImage).left;

double _widthOf(SlideItem item) =>
    item is SlideText ? item.width : (item as SlideImage).width;

/// A text's height on the design: its PDF lines times the line height.
double _textHeight(SlideText item) =>
    item.text.split('\n').length * item.size * item.lh;

double _heightOf(SlideItem item) =>
    item is SlideText ? _textHeight(item) : (item as SlideImage).height;

/// Whether an item sits in the design's left half (its centre decides).
bool _isLeft(SlideItem item) =>
    _leftOf(item) + _widthOf(item) / 2 < kSlideW / 2;

// ---------------------------------------------------------------------------
// Portrait: the cover, and the other pages reflowed into one column.
// ---------------------------------------------------------------------------

/// One portrait page: the cover (page 0) with its photo, or a reflowed column.
Widget _phonePage(int index, SlidePage page, double width, double height) {
  final photo = index == 0 ? _fullBleed(page) : null;
  if (photo == null) {
    return _FlowPage(page: page, width: width, minHeight: height);
  }
  return _PortraitCover(page: page, photo: photo, width: width, height: height);
}

/// The cover on a phone: the photo covers the whole screen, and the title and
/// the name sit over it. Every item of the cover shares one transform, so the
/// photo's composition holds.
class _PortraitCover extends StatelessWidget {
  const _PortraitCover({
    required this.page,
    required this.photo,
    required this.width,
    required this.height,
  });

  final SlidePage page;
  final SlideImage photo;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // The photo's frame is scaled to cover the screen and centred on it.
    final s = math.max(height / photo.height, width / photo.width);
    final ox = (width - photo.width * s) / 2 - photo.left * s;
    final oy = (height - photo.height * s) / 2 - photo.top * s;
    final texts = page.items.whereType<SlideText>().toList()
      ..sort((a, b) => a.top.compareTo(b.top));
    // The title stays where the design puts it, above the laptop on the wall,
    // and the name follows under it.
    // A window shorter than about 48px leaves no room for the title band; the
    // band's top limit then stays at 24px rather than asking clamp for an empty
    // range, which throws.
    final maxY = math.max(24.0, height * 0.5);
    final y0 = (oy + (texts.isEmpty ? 0.0 : texts.first.top) * s)
        .clamp(24.0, maxY)
        .toDouble();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _gradient(page.bg),
        color: page.bg.colors.first,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Pictures are painted in the design's own order: a picture the
            // design keeps behind the photo stays hidden, as on the desktop.
            for (final item in page.items)
              if (item is SlideImage) _placeImage(item, s, dx: ox, dy: oy),
            Positioned(
              top: y0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final text in texts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text.rich(
                            _rich(
                              _reflow(text.text),
                              TextStyle(
                                fontSize: _mobileSize(text.size),
                                height: 1.2,
                                color: text.color,
                                fontWeight: text.weight,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A portrait page at least one screen tall. The header floats over its top,
/// so the content starts below the header.
class _FlowPage extends StatelessWidget {
  const _FlowPage({
    required this.page,
    required this.width,
    required this.minHeight,
  });

  final SlidePage page;
  final double width;
  final double minHeight;

  static const _pad = 20.0;

  @override
  Widget build(BuildContext context) {
    final cw = math.max(0.0, width - _pad * 2);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _gradient(page.bg),
          color: page.bg.colors.first,
        ),
        child: Column(
          // Top-aligned: a short page starts at the top like a long one, so no
          // blank band opens above its content.
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_pad, _headerH + 24, _pad, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _phoneBlocks(page.items, cw),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One piece of a portrait page: a text (with its icon, when it has one), or a
/// row of pictures.
class _Block {
  _Block({
    required this.top,
    required this.left,
    this.text,
    this.icon,
    this.loose = false,
    List<SlideImage>? pictures,
  }) : pictures = pictures ?? <SlideImage>[];

  final double top;

  /// Whether the block sits in the design's left column.
  final bool left;
  final SlideText? text;
  final SlideImage? icon;
  final List<SlideImage> pictures;

  /// A narrow single picture: it may share a row with its neighbours.
  final bool loose;
}

/// The page's blocks in reading order, as widgets. With texts, the left column
/// reads first and then the right; a page of pictures alone reads as one grid.
List<Widget> _phoneBlocks(List<SlideItem> items, double cw) {
  final texts = items.whereType<SlideText>().toList();
  final images = items.whereType<SlideImage>().toList();

  // A small picture on the text's left, within the text's rows, is its icon.
  final icons = <SlideText, SlideImage>{};
  final used = <SlideImage>{};
  for (final text in texts) {
    final bottom = text.top + _textHeight(text);
    SlideImage? best;
    for (final image in images) {
      if (used.contains(image) ||
          image.width >= 100 ||
          image.left >= text.left) {
        continue;
      }
      if (image.top >= bottom || image.top + image.height <= text.top) {
        continue;
      }
      if (best == null ||
          (image.top - text.top).abs() < (best.top - text.top).abs()) {
        best = image;
      }
    }
    if (best != null) {
      icons[text] = best;
      used.add(best);
    }
  }

  final blocks = <_Block>[
    for (final text in texts)
      _Block(top: text.top, left: _isLeft(text), text: text, icon: icons[text]),
  ];

  // Pictures whose tops are within 60 of each other form one group, read from
  // left to right.
  final rest = [
    for (final image in images)
      if (!used.contains(image)) image,
  ]..sort((a, b) => a.top.compareTo(b.top));
  final groups = <List<SlideImage>>[];
  for (final image in rest) {
    if (groups.isNotEmpty && (image.top - groups.last.first.top).abs() < 60) {
      groups.last.add(image);
    } else {
      groups.add([image]);
    }
  }
  for (final group in groups) {
    group.sort((a, b) => a.left.compareTo(b.left));
    final centre =
        group.fold<double>(
          0,
          (sum, image) => sum + image.left + image.width / 2,
        ) /
        group.length;
    blocks.add(
      _Block(
        top: group.first.top,
        left: centre < kSlideW / 2,
        loose: group.length == 1 && group.first.width < 400,
        pictures: group,
      ),
    );
  }

  List<_Block> byTop(Iterable<_Block> list) =>
      [...list]..sort((a, b) => a.top.compareTo(b.top));
  final ordered = texts.isEmpty
      ? byTop(blocks)
      : [
          ...byTop(blocks.where((b) => b.left)),
          ...byTop(blocks.where((b) => !b.left)),
        ];

  // Narrow single pictures that follow each other, close in height, share one
  // row of up to four.
  final merged = <_Block>[];
  for (final block in ordered) {
    final last = merged.isEmpty ? null : merged.last;
    if (last != null &&
        last.loose &&
        block.loose &&
        (block.top - last.top).abs() <= 200 &&
        last.pictures.length + block.pictures.length <= 4) {
      last.pictures.addAll(block.pictures);
      continue;
    }
    merged.add(block);
  }

  final out = <Widget>[];
  for (final block in merged) {
    final text = block.text;
    if (text != null) {
      out.add(_textBlock(text, block.icon));
    } else {
      for (final row in _balanced(block.pictures)) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _imageRow(row, cw),
          ),
        );
      }
    }
  }
  return out;
}

/// A text, with its icon at the left when it has one.
Widget _textBlock(SlideText text, SlideImage? icon) {
  final body = _flowText(text);
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: icon == null
        ? body
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _rowCell(icon, 36),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: body),
            ],
          ),
  );
}

/// A group of pictures split into rows of two to four, as evenly as possible:
/// five become 3 and 2, six become 3 and 3, seven become 4 and 3.
List<List<SlideImage>> _balanced(List<SlideImage> images) {
  final n = images.length;
  if (n <= 4) return [images];
  final rows = (n / 4).ceil();
  final base = n ~/ rows;
  var extra = n % rows;
  final out = <List<SlideImage>>[];
  var k = 0;
  for (var r = 0; r < rows; r++) {
    final size = base + (extra > 0 ? 1 : 0);
    if (extra > 0) extra--;
    out.add(images.sublist(k, k + size));
    k += size;
  }
  return out;
}

/// One or more pictures side by side. Their heights match, the widths follow
/// the pictures' shapes, and the row fills the width with an even gap. A single
/// picture is sized for the phone, and a wide one takes the full width. An icon
/// stays at the left.
Widget _imageRow(List<SlideImage> row, double cw) {
  if (row.length == 1) {
    final image = row.first;
    final icon = image.width < 100;
    final double w;
    if (icon) {
      w = 32;
    } else if (image.width >= 400) {
      w = cw;
    } else {
      w = math.min(cw, math.max(cw * 0.45, image.width / kSlideW * cw * 2.2));
    }
    return Align(
      alignment: icon ? Alignment.centerLeft : Alignment.center,
      child: _rowCell(image, w),
    );
  }
  const gap = 8.0;
  final ratios = [for (final image in row) _aspect(image)];
  final total = ratios.fold<double>(0, (sum, r) => sum + r);
  final height = math.max(0.0, cw - gap * (row.length - 1)) / total;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var k = 0; k < row.length; k++) ...[
        if (k > 0) const SizedBox(width: gap),
        _rowCell(row[k], ratios[k] * height),
      ],
    ],
  );
}

/// The part of a picture that shows: its drawn box, cut to its frame. The design
/// can leave empty frame below or beside a picture; the phone shows none of it,
/// so it takes no room.
Rect _visibleBox(SlideImage image) {
  final left = math.max(0.0, image.imgLeft);
  final top = math.max(0.0, image.imgTop);
  final right = math.min(
    image.width,
    image.imgLeft + (image.imgWidth ?? image.width),
  );
  final bottom = math.min(
    image.height,
    image.imgTop + (image.imgHeight ?? image.height),
  );
  if (right <= left || bottom <= top) {
    return Rect.fromLTWH(0, 0, image.width, image.height);
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

/// Width over height of the part that shows.
double _aspect(SlideImage image) {
  final box = _visibleBox(image);
  return box.width / box.height;
}

/// A picture [w] wide, showing only its visible part.
Widget _rowCell(SlideImage image, double w) {
  final box = _visibleBox(image);
  final k = w / box.width;
  return SizedBox(
    width: w,
    height: box.height * k,
    child: ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -box.left * k,
            top: -box.top * k,
            width: image.width * k,
            height: image.height * k,
            child: _pictureBox(image, k, k),
          ),
        ],
      ),
    ),
  );
}

/// Phone sizes: the design's headings and body text, scaled to read well on a
/// narrow screen.
double _mobileSize(double size) {
  if (size >= 70) return 34; // the cover title
  if (size >= 50) return 30; // "About Me", "Contact :"
  if (size >= 35) return 24; // headings and the name
  if (size >= 26) return 16; // contact lines
  if (size >= 22) return 15.5; // body
  return 14.5; // smaller body text
}

Widget _flowText(SlideText item) {
  return Text.rich(
    _rich(
      _reflow(item.text),
      TextStyle(
        fontSize: _mobileSize(item.size),
        height: item.size >= 35 ? 1.2 : 1.5,
        color: item.color,
        fontWeight: item.weight,
      ),
    ),
    textAlign: item.align,
  );
}

/// The PDF breaks its lines for the design's width. On a phone the lines are
/// joined into paragraphs, and a new paragraph starts after a sentence that is
/// followed by a line starting with a capital letter.
String _reflow(String text) {
  final lines = [
    for (final line in text.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  final sentenceEnd = RegExp(r'[.!?:]$');
  final startsNew = RegExp(r'^[A-Z0-9(“"]');
  final buf = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    if (i > 0) {
      final ends = sentenceEnd.hasMatch(_plain(lines[i - 1]));
      final starts = startsNew.hasMatch(_plain(lines[i]));
      buf.write(ends && starts ? '\n\n' : ' ');
    }
    buf.write(lines[i]);
  }
  return buf.toString();
}

/// The text as it reads, without the markers.
String _plain(String s) => s
    .replaceAllMapped(RegExp(r'\[\[(.+?)\|.+?\]\]'), (m) => m.group(1)!)
    .replaceAll(RegExp(r'\*\*|\+\+'), '');

// ---------------------------------------------------------------------------
// Text and links.
// ---------------------------------------------------------------------------

/// `[[label|address]]` is a link: it opens the address on tap, and turns blue
/// while the pointer is over it. `**x**` becomes bold italic (the tech-stack
/// call-outs), and `++x++` bold only.
TextSpan _rich(String text, TextStyle style) {
  final pattern = RegExp(r'\[\[(.+?)\|(.+?)\]\]|\*\*(.+?)\*\*|\+\+(.+?)\+\+');
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
          child: _LinkText(label: m.group(1)!, url: m.group(2)!, style: style),
        ),
      );
    } else if (m.group(3) != null) {
      spans.add(
        TextSpan(
          text: m.group(3),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: m.group(4),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return TextSpan(style: style, children: spans);
}

/// A link in running text: the pointer shows a hand, the text turns blue while
/// the pointer is over it, and a tap opens the address.
class _LinkText extends StatefulWidget {
  const _LinkText({
    required this.label,
    required this.url,
    required this.style,
  });

  final String label;
  final String url;
  final TextStyle style;

  @override
  State<_LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<_LinkText> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
            color: _hover ? _linkBlue : widget.style.color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chrome: the header above the pages, and the back-to-top button.
// ---------------------------------------------------------------------------

/// The header: back, title, quick links and the PDF button. It is transparent,
/// with a soft shade at its top so the controls read on light and dark pages.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.wide,
    required this.current,
    required this.onJump,
    required this.onBack,
    required this.exporting,
    required this.onExportPdf,
  });

  final bool wide;
  final ValueListenable<int> current;
  final void Function(int index) onJump;
  final VoidCallback onBack;
  final ValueListenable<bool> exporting;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _headerH,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x80000000), Color(0x00000000)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: onBack,
            icon: const FaIcon(
              FontAwesomeIcons.arrowLeft,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 4),
          const Flexible(
            child: Text(
              'Portofolio',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Color(0x73000000), blurRadius: 6)],
              ),
            ),
          ),
          const Spacer(),
          if (wide)
            ValueListenableBuilder<int>(
              valueListenable: current,
              builder: (context, page, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _chips.length; i++)
                    _NavChip(
                      label: _chips[i].$1,
                      active:
                          page >= _chips[i].$2 &&
                          (i + 1 == _chips.length || page < _chips[i + 1].$2),
                      onTap: () => onJump(_chips[i].$2),
                    ),
                ],
              ),
            ),
          ValueListenableBuilder<bool>(
            valueListenable: exporting,
            builder: (context, busy, _) => IconButton(
              tooltip: 'Unduh PDF',
              onPressed: busy ? null : onExportPdf,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.filePdf,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF0B1220) : const Color(0xFFE2E8F0),
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

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

// ---------------------------------------------------------------------------
// Lazy landscape pages: a page is built only while it is within a screen of the
// viewport, so the twelve pages and their pictures are not all built at once.
// ---------------------------------------------------------------------------

/// Carries the scroll offset to the pages below; they rebuild as it moves.
class _ScrollTick extends InheritedNotifier<ValueListenable<double>> {
  const _ScrollTick({
    required ValueListenable<double> offset,
    required super.child,
  }) : super(notifier: offset);
}

/// A landscape page. Its place in the scroll is known from its index and the
/// screen height, so it needs no lookup of render objects: outside the window
/// around the screen it is a placeholder of the same height.
class _Lazy extends StatelessWidget {
  const _Lazy({
    required this.index,
    required this.height,
    required this.aspect,
    required this.builder,
  });

  final int index;
  final double height;

  /// Width over height of the page, so the placeholder keeps its height.
  final double aspect;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final tick = context.dependOnInheritedWidgetOfExactType<_ScrollTick>();
    final offset = tick?.notifier?.value ?? 0.0;
    final near = (index * height - offset).abs() < 2 * height;
    return AspectRatio(
      aspectRatio: aspect,
      child: near ? builder(context) : const ColoredBox(color: _barColor),
    );
  }
}
