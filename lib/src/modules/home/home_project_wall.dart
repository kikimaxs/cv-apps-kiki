import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cv_apps/src/modules/home/home_copy.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// "Proyek & dampak": a tilted 3D wall of cards about shipped apps (port of
/// the 21st.dev "3D Testimonials" layout, filled with real project facts
/// instead of testimonials).
///
/// Unlike the original it never scrolls on its own: the columns move with
/// the page scroll and with a drag/fling on the wall, glide, ease to a full
/// stop and the ticker switches off. A short glide on first show hints that
/// it can move.
class ProjectWall extends StatefulWidget {
  const ProjectWall({super.key});

  @override
  State<ProjectWall> createState() => _ProjectWallState();
}

const _accent = Color(0xFF67D4FF);
const _violet = Color(0xFFB49BFF);
const _orange = Color(0xFFFF9F5A);
const _green = Color(0xFF79E4BA);
const _muted = Color(0xFF9FB3C8);
const _shade = Color(0xFF080D18);

enum _Kind { project, metric, highlight, shot }

class _WallCard {
  final _Kind kind;
  final String project;
  final Color color;
  final String title;
  final String text;
  final String? asset;
  final List<String> tags;

  const _WallCard(
    this.kind,
    this.project,
    this.color, {
    this.title = '',
    this.text = '',
    this.asset,
    this.tags = const [],
  });

  /// Fixed heights (at the 210px reference width) so the wall's wrap length
  /// is known without layout.
  double get baseHeight => switch (kind) {
    _Kind.project => 150,
    _Kind.metric => 124,
    _Kind.highlight => 150,
    _Kind.shot => 290,
  };
}

const _p = 'assets/img/portfolio';

List<_WallCard> _cardsFor(BuildContext context) => <_WallCard>[
  _WallCard(
    _Kind.project,
    'MOLA TV',
    _accent,
    title: homeText(context, 'Streaming olahraga & film'),
    text: 'React Native · JavaScript',
    asset: '$_p/mola_logo.png',
    tags: ['Android', 'iOS', 'ID'],
  ),
  _WallCard(
    _Kind.metric,
    'MOLA TV',
    _accent,
    title: '700K',
    text: homeText(context, 'unduhan iOS & Android sejak 2020'),
  ),
  _WallCard(_Kind.shot, 'MOLA TV', _accent, asset: '$_p/mola_s1.jpg'),
  _WallCard(
    _Kind.highlight,
    'MOLA TV',
    _accent,
    text: homeText(
      context,
      'Live quiz real-time lewat WebSocket, jawaban disimpan dulu agar tidak hilang saat server down.',
    ),
  ),
  _WallCard(
    _Kind.metric,
    'MOLA TV',
    _accent,
    title: '2,3 jt',
    text: homeText(context, 'penonton laga Inggris vs Spanyol'),
  ),
  _WallCard(
    _Kind.project,
    'Durioo+',
    _orange,
    title: homeText(context, 'Konten anak ramah Muslim'),
    text: 'React Native Expo · TypeScript',
    asset: '$_p/durioo_logo.png',
    tags: ['Android', 'iOS', 'TV', 'MY'],
  ),
  _WallCard(
    _Kind.metric,
    'Durioo+',
    _orange,
    title: '60K',
    text: homeText(context, 'unduhan di Malaysia sejak Maret 2024'),
  ),
  _WallCard(_Kind.shot, 'Durioo+', _orange, asset: '$_p/durioo_s1.jpg'),
  _WallCard(
    _Kind.highlight,
    'Durioo+',
    _orange,
    text: homeText(
      context,
      'Video player dengan casting ke TV, unduh offline, subtitle dan pilihan kualitas.',
    ),
  ),
  _WallCard(
    _Kind.metric,
    'Durioo+',
    _orange,
    title: '3 jt+',
    text: homeText(context, 'total tayangan video'),
  ),
  _WallCard(
    _Kind.project,
    'FWD HadIR',
    _green,
    title: homeText(context, 'Absensi & produktivitas karyawan'),
    text: homeText(context, 'Untuk PT FWD Insurance Indonesia'),
    asset: '$_p/hadir_icon.png',
    tags: ['Android', 'iOS', 'ID'],
  ),
  _WallCard(
    _Kind.highlight,
    'FWD HadIR',
    _green,
    text: homeText(
      context,
      'Absen hanya sah di radius ±300 m dari kantor, lengkap dengan deteksi fake GPS.',
    ),
  ),
  _WallCard(_Kind.shot, 'FWD HadIR', _green, asset: '$_p/hadir_2.jpg'),
  _WallCard(
    _Kind.project,
    'LifeLine',
    _violet,
    title: homeText(context, 'Ekosistem kesehatan lansia'),
    text: 'Flutter · Bloc · IoT',
    asset: '$_p/lifeline_icon.png',
    tags: ['Android', 'iOS', 'CN'],
  ),
  _WallCard(
    _Kind.highlight,
    'LifeLine',
    _violet,
    text: homeText(
      context,
      'Smartwatch, smart lock dan dispenser digital terhubung ke satu Care Circle keluarga.',
    ),
  ),
  _WallCard(_Kind.shot, 'LifeLine', _violet, asset: '$_p/lifeline_home.png'),
];

/// Spin-down physics shared by drag flings and the welcome glide.
class _WallMotion extends ChangeNotifier {
  static const friction = 2.4; // 1/s
  static const maxSpeed = 2600.0; // px/s
  static const restSpeed = 6.0; // px/s

  double offset = 0;
  double velocity = 0;

  bool get settled => velocity == 0;

  void moveBy(double px) {
    offset += px;
    notifyListeners();
  }

  void step(double dt) {
    if (velocity == 0) return;
    // Exact solution of v' = -friction * v: frame-rate independent.
    final decay = math.exp(-friction * dt);
    offset += velocity * (1 - decay) / friction;
    velocity *= decay;
    if (velocity.abs() < restSpeed) velocity = 0;
    notifyListeners();
  }
}

class _ProjectWallState extends State<ProjectWall>
    with SingleTickerProviderStateMixin {
  static const _gap = 14.0;
  static const _refWidth = 210.0;
  // Neighbouring columns run in opposite directions at slightly different
  // speeds, like the original.
  static const _columnSpeeds = [1.0, -0.82, 1.14, -0.94, 1.06, -0.88, 0.98];

  final _motion = _WallMotion();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  ScrollPosition? _scroll;
  double? _lastScrollPixels;
  bool _welcomed = false;

  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (!identical(scroll, _scroll)) {
      _scroll?.removeListener(_onPageScroll);
      _scroll = scroll;
      _lastScrollPixels = null;
      _scroll?.addListener(_onPageScroll);
    }
    if (!_welcomed) {
      _welcomed = true;
      if (!_reducedMotion) {
        _motion.velocity = 620;
        _wake();
      }
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_onPageScroll);
    _ticker.dispose();
    _motion.dispose();
    super.dispose();
  }

  /// Page scroll moves the wall directly: no ticker involved.
  void _onPageScroll() {
    final position = _scroll;
    if (position == null || !position.hasPixels) return;
    final pixels = position.pixels;
    final last = _lastScrollPixels;
    _lastScrollPixels = pixels;
    if (last != null && pixels != last) _motion.moveBy((pixels - last) * 0.7);
  }

  void _wake() {
    if (_ticker.isActive) return;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _motion.step(dt);
    if (_motion.settled) _ticker.stop();
  }

  void _onPanStart(DragStartDetails _) {
    _motion.velocity = 0;
    if (_ticker.isActive) _ticker.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Sideways drags also move the wall (natural on touch, where vertical
    // drags scroll the page and move it through the scroll link).
    _motion.moveBy(-(details.delta.dy + details.delta.dx * 0.7));
  }

  void _onPanEnd(DragEndDetails details) {
    if (_reducedMotion) return;
    final v = details.velocity.pixelsPerSecond;
    _motion.velocity = (-(v.dy + v.dx * 0.7)).clamp(
      -_WallMotion.maxSpeed,
      _WallMotion.maxSpeed,
    );
    if (_motion.velocity.abs() < _WallMotion.restSpeed) _motion.velocity = 0;
    if (!_motion.settled) _wake();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final mobile = width < 700;
        final cardWidth = mobile ? 168.0 : _refWidth;
        final k = cardWidth / _refWidth;
        final wallHeight = mobile ? 430.0 : 540.0;

        // The tilted plane must be larger than the window onto it.
        final innerW = width * 1.7;
        final innerH = wallHeight * 2.1;
        final columns = math.min(
          _columnSpeeds.length,
          (innerW / (cardWidth + _gap)).ceil() + 1,
        );

        final columnCards = <List<_WallCard>>[
          for (var c = 0; c < columns; c++)
            [
              for (var i = 0; i < 8; i++)
                _cardsFor(context)[(c * 5 + i) % _cardsFor(context).length],
            ],
        ];
        final loopHeights = [
          for (final cards in columnCards)
            cards.fold<double>(
              0,
              (sum, card) => sum + card.baseHeight * k + _gap,
            ),
        ];

        final plane = Flow(
          delegate: _WallDelegate(
            motion: _motion,
            size: Size(innerW, innerH),
            columnWidth: cardWidth,
            gap: _gap,
            loopHeights: loopHeights,
            speeds: _columnSpeeds,
          ),
          children: [
            for (final cards in columnCards)
              RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Two copies so the loop wraps seamlessly.
                    for (var copy = 0; copy < 2; copy++)
                      for (final card in cards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: _gap),
                          child: _WallTile(
                            card: card,
                            width: cardWidth,
                            height: card.baseHeight * k,
                            scale: k,
                          ),
                        ),
                  ],
                ),
              ),
          ],
        );

        final tilt = Matrix4.identity()
          ..setEntry(3, 2, 0.0008)
          ..rotateX(0.62)
          ..rotateZ(-0.36);

        final wall = SizedBox(
          height: wallHeight,
          width: double.infinity,
          child: ClipRect(
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OverflowBox(
                      maxWidth: innerW,
                      maxHeight: innerH,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: tilt,
                        child: RepaintBoundary(child: plane),
                      ),
                    ),
                    // Static edge fades (cheaper than a ShaderMask).
                    const _EdgeFade(
                      Alignment.topCenter,
                      Alignment.bottomCenter,
                      0.32,
                    ),
                    const _EdgeFade(
                      Alignment.bottomCenter,
                      Alignment.topCenter,
                      0.32,
                    ),
                    const _EdgeFade(
                      Alignment.centerLeft,
                      Alignment.centerRight,
                      0.12,
                    ),
                    const _EdgeFade(
                      Alignment.centerRight,
                      Alignment.centerLeft,
                      0.12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: _Header(mobile: mobile),
                ),
              ),
            ),
            const SizedBox(height: 8),
            wall,
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 18,
                runSpacing: 14,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.handPointer,
                        size: 12,
                        color: _accent,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          homeText(
                            context,
                            'Geser dindingnya atau scroll untuk menjelajah',
                          ),
                          style: TextStyle(color: _muted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/my_portofolio_v2'),
                    style: TextButton.styleFrom(
                      foregroundColor: _accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.arrowRight, size: 13),
                    label: Text(
                      homeText(context, 'Lihat portofolio lengkap'),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final bool mobile;

  const _Header({required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          homeText(context, 'PROYEK & DAMPAK'),
          style: TextStyle(
            color: _accent,
            letterSpacing: 2,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          homeText(context, 'Aplikasi yang sudah dipakai banyak orang.'),
          style: TextStyle(
            color: Colors.white,
            fontSize: mobile ? 30 : 42,
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          homeText(
            context,
            'Streaming, HR dan kesehatan: dari Indonesia, Malaysia sampai Tiongkok.',
          ),
          style: TextStyle(color: _muted, fontSize: 15, height: 1.5),
        ),
      ],
    );
  }
}

/// Lays the columns side by side and slides each one along its own loop.
/// Only [paintChildren] runs while the wall moves.
class _WallDelegate extends FlowDelegate {
  final _WallMotion motion;
  final Size size;
  final double columnWidth;
  final double gap;
  final List<double> loopHeights;
  final List<double> speeds;

  _WallDelegate({
    required this.motion,
    required this.size,
    required this.columnWidth,
    required this.gap,
    required this.loopHeights,
    required this.speeds,
  }) : super(repaint: motion);

  @override
  Size getSize(BoxConstraints constraints) => size;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tightFor(width: columnWidth);

  @override
  void paintChildren(FlowPaintingContext context) {
    final count = loopHeights.length;
    final total = count * columnWidth + (count - 1) * gap;
    final left = (size.width - total) / 2;
    for (var i = 0; i < count; i++) {
      final loop = loopHeights[i];
      // Stagger columns so cards do not line up in rows. Each column holds
      // two copies of its loop (and loop > plane height), so sliding its top
      // anywhere in (-loop, 0] always covers the plane with no gap.
      final shift = (motion.offset * speeds[i] + i * 97) % loop;
      context.paintChild(
        i,
        transform: Matrix4.translationValues(
          left + i * (columnWidth + gap),
          -shift,
          0,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_WallDelegate oldDelegate) =>
      oldDelegate.size != size ||
      oldDelegate.columnWidth != columnWidth ||
      oldDelegate.loopHeights.length != loopHeights.length;
}

class _EdgeFade extends StatelessWidget {
  final Alignment from;
  final Alignment to;
  final double fraction;

  const _EdgeFade(this.from, this.to, this.fraction);

  @override
  Widget build(BuildContext context) {
    final vertical = from.x == 0;
    return Align(
      alignment: from,
      child: IgnorePointer(
        child: FractionallySizedBox(
          widthFactor: vertical ? 1 : fraction,
          heightFactor: vertical ? fraction : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: from,
                end: to,
                colors: [
                  _shade.withValues(alpha: 0.78),
                  _shade.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One card. Lifts and lights up its border on hover or press.
class _WallTile extends StatefulWidget {
  final _WallCard card;
  final double width;
  final double height;
  final double scale;

  const _WallTile({
    required this.card,
    required this.width,
    required this.height,
    required this.scale,
  });

  @override
  State<_WallTile> createState() => _WallTileState();
}

class _WallTileState extends State<_WallTile> {
  bool _lit = false;

  void _set(bool lit) {
    if (lit != _lit) setState(() => _lit = lit);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final k = widget.scale;
    final radius = BorderRadius.circular(18 * k);

    final Widget content = switch (card.kind) {
      _Kind.project => _project(card, k),
      _Kind.metric => _metric(card, k),
      _Kind.highlight => _highlight(card, k),
      _Kind.shot => _shot(card, k, radius),
    };

    return MouseRegion(
      onEnter: (_) => _set(true),
      onExit: (_) => _set(false),
      child: Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _lit ? 1.05 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: widget.width,
            height: widget.height,
            padding: card.kind == _Kind.shot
                ? EdgeInsets.zero
                : EdgeInsets.all(14 * k),
            decoration: BoxDecoration(
              color: const Color(0xFF111B2C).withValues(alpha: 0.94),
              borderRadius: radius,
              border: Border.all(
                color: _lit
                    ? card.color.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.08),
                width: _lit ? 1.5 : 1,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _footer(_WallCard card, double k) {
    return Row(
      children: [
        Container(
          width: 7 * k,
          height: 7 * k,
          decoration: BoxDecoration(color: card.color, shape: BoxShape.circle),
        ),
        SizedBox(width: 7 * k),
        Flexible(
          child: Text(
            card.project,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _muted,
              fontSize: 12 * k,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _project(_WallCard card, double k) {
    final icon = 38 * k;
    final wordmark = card.asset!.endsWith('mola_logo.png');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: icon,
              height: icon,
              padding: EdgeInsets.all(wordmark ? 5 * k : 0),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: wordmark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10 * k),
              ),
              child: Image.asset(
                card.asset!,
                fit: wordmark ? BoxFit.contain : BoxFit.cover,
                cacheWidth: 120,
                excludeFromSemantics: true,
              ),
            ),
            SizedBox(width: 10 * k),
            Expanded(
              child: Text(
                card.project,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * k,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * k),
        Text(
          card.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: 13.5 * k),
        ),
        SizedBox(height: 3 * k),
        Text(
          card.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: _muted, fontSize: 12 * k),
        ),
        const Spacer(),
        // One line of tags; extra tags are clipped instead of overflowing.
        SizedBox(
          height: 20 * k,
          child: ClipRect(
            child: Wrap(
              clipBehavior: Clip.hardEdge,
              spacing: 5 * k,
              runSpacing: 4 * k,
              children: [
                for (final tag in card.tags)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7 * k,
                      vertical: 2.5 * k,
                    ),
                    decoration: BoxDecoration(
                      color: card.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: card.color,
                        fontSize: 10.5 * k,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(_WallCard card, double k) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: card.color,
            fontSize: 32 * k,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6 * k),
        Text(
          card.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: 13 * k, height: 1.3),
        ),
        const Spacer(),
        _footer(card, k),
      ],
    );
  }

  Widget _highlight(_WallCard card, double k) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(
          FontAwesomeIcons.quoteLeft,
          size: 14 * k,
          color: card.color.withValues(alpha: 0.8),
        ),
        SizedBox(height: 8 * k),
        Text(
          card.text,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5 * k,
            height: 1.35,
          ),
        ),
        const Spacer(),
        _footer(card, k),
      ],
    );
  }

  Widget _shot(_WallCard card, double k, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            card.asset!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: 360,
            filterQuality: FilterQuality.low,
            semanticLabel:
                '${homeText(context, 'Tampilan aplikasi')} ${card.project}',
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(12 * k, 28 * k, 12 * k, 12 * k),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _shade.withValues(alpha: 0),
                    _shade.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: _footer(card, k),
            ),
          ),
        ],
      ),
    );
  }
}
