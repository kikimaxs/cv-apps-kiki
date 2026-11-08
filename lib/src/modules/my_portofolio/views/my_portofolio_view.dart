import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../home/home_fx.dart' show Reveal;
import '../portfolio_assets.dart';

// ---------------------------------------------------------------------------
// Portfolio page: the 12 slides of the Canva design ("MY PORTOFOLIO") as one
// scrolling page. Text is native Flutter text, images are optimised copies of
// the design's own artwork (assets/img/portfolio) loaded lazily as they come
// into view, and nothing animates forever, so the page costs nothing at rest.
// ---------------------------------------------------------------------------

const _ink = Color(0xFF0F172A);
const _bar = Color(0xF2101928);
const _accent = Color(0xFF67D4FF);
const _assetDir = 'assets/img/portfolio/';

const _molaGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF63DFE7), Color(0xFF2F8FCF), Color(0xFF0A4DAA)],
);
const _orangeGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFFEE7C45), Color(0xFFF3A864), Color(0xFFF9CD88)],
);
const _lifelineGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFF4A1140), Color(0xFF7E2A5F), Color(0xFFB04C7C)],
);
const _aboutGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Colors.white, Color(0xFFDADDE2)],
);

const _slideCount = 12;

/// Quick links in the top bar: label and the slide each one jumps to.
const _chips = <(String, int)>[
  ('Cover', 0),
  ('MOLA TV', 1),
  ('Durioo+', 4),
  ('HadIR', 7),
  ('Lifeline', 9),
  ('Kontak', 11),
];

/// Sizes derived from the viewport. The wide-mode numbers are the Canva
/// design's own point sizes (41.44/23.99 on its native 1366-wide canvas)
/// rescaled to our ~1200 content width, so headings and body copy keep the
/// same proportions as the source PDF.
class _L {
  const _L(this.w, this.h);

  final double w;
  final double h;

  bool get wide => w >= 900;
  double get pad => wide ? 56 : 20;
  double get phoneH => wide ? 340 : 190;
  double get heading => wide ? 36 : 28;
  double get body => wide ? 21 : 16;
}

class MyPortofolioView extends StatefulWidget {
  const MyPortofolioView({super.key});

  @override
  State<MyPortofolioView> createState() => _MyPortofolioViewState();
}

class _MyPortofolioViewState extends State<MyPortofolioView> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  final ValueNotifier<int> _current = ValueNotifier<int>(0);
  final List<GlobalKey> _keys = List.generate(_slideCount, (_) => GlobalKey());
  double _lastTickPixels = -1000;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final pixels = _scroll.position.pixels;
    // Throttled: lazy images and the current-slide marker only need to know
    // about every ~80px of scrolling, not about every frame.
    if ((pixels - _lastTickPixels).abs() < 80) return;
    _lastTickPixels = pixels;
    _tick.value++;
    _updateCurrent();
  }

  void _updateCurrent() {
    final probe = MediaQuery.sizeOf(context).height * 0.4;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final bottom = box.localToGlobal(Offset.zero).dy + box.size.height;
      if (bottom > probe) {
        if (_current.value != i) _current.value = i;
        return;
      }
    }
  }

  void _jumpTo(int index) {
    final context = _keys[index].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _tick.dispose();
    _current.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final l = _L(size.width, size.height);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'Carlito'),
        child: Stack(
        children: [
          _ScrollTick(
            tick: _tick,
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                children: [
                  for (var i = 0; i < _slideCount; i++)
                    KeyedSubtree(key: _keys[i], child: _slide(i, l)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              wide: l.wide,
              current: _current,
              onJump: _jumpTo,
              onBack: () => context.go('/'),
            ),
          ),
          if (l.wide)
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: _Dots(current: _current, onJump: _jumpTo),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _slide(int i, _L l) {
    switch (i) {
      case 0:
        return _Cover(l: l);
      case 1:
        return _CollageSlide(
          l: l,
          gradient: _molaGradient,
          logo: 'mola_logo.png',
          logoWidth: l.wide ? 320 : 220,
          shots: const [
            'mola_s2.jpg',
            'mola_s1.jpg',
            'mola_s3.jpg',
            'mola_s4.jpg',
            'mola_s5.jpg',
          ],
          wideShot: 'mola_video.jpg',
        );
      case 2:
        return _InfoSlide(
          l: l,
          gradient: _molaGradient,
          textWeight: 0.47,
          blocks: const [
            _Block('What is the MOLA TV Apps ?', [
              'MOLA is a Live streaming video entertainment application, MOLA '
                  'itself is cross-platform based including Android and iOS using '
                  '**React Native** with **Javascript** programming language, MOLA '
                  'has main content that is more about Sports such as Football, UFC '
                  'and popular movie content for adults and children, besides mobile '
                  'MOLA already has its own device using MOLA TV box, and the MOLA '
                  'has been uploaded to __Playstore__ and Appstore.',
            ]),
            _Block('My Achievement at MOLA TV ?', [
              'In Indonesia, The app reached 700K downloads (iOS & Android since '
                  '2020) and 2.3 million viewers during the Euro 2022 England vs '
                  'Spain match.',
            ]),
          ],
          media: _Media(
            l: l,
            maxWidth: 440,
            children: const [_Shot('mola_app.jpg', cache: 900)],
          ),
        );
      case 3:
        return _InfoSlide(
          l: l,
          gradient: _molaGradient,
          textWeight: 0.44,
          blocks: const [
            _Block('What is the most challenging job during work in MOLA ?', [
              'I worked on a live quiz feature at MOLA, handling quiz delivery and '
                  'answer submission using WebSocket with temporary storage before '
                  'sending data to the API to prevent data loss. A major issue '
                  'occurred when the server went down during a live session, causing '
                  'users to be unable to participate. The solution was to implement '
                  'a temporary maintenance mode while coordinating with Mobile, '
                  'Backend, and Infra teams, and reschedule the affected quiz once '
                  'the system was restored.',
            ]),
          ],
          media: _Phones(
            l: l,
            names: const ['mola_quiz1.jpg', 'mola_quiz2.jpg'],
            height: l.wide ? 420 : 240,
          ),
        );
      case 4:
        return _CollageSlide(
          l: l,
          gradient: _orangeGradient,
          logo: 'durioo_logo.png',
          logoWidth: l.wide ? 150 : 110,
          logoRadius: 20,
          shots: const [
            'durioo_s1.jpg',
            'durioo_s2.jpg',
            'durioo_s3.jpg',
            'durioo_s4.jpg',
            'durioo_s5.jpg',
          ],
          wideShot: 'durioo_video.jpg',
        );
      case 5:
        return _InfoSlide(
          l: l,
          gradient: _orangeGradient,
          textWeight: 0.44,
          blocks: const [
            _Block('What is the Durioo+ Apps ?', [
              'Durioo+ is a cross-platform video streaming app (Android & iOS) '
                  'built with **React Native Expo** and **TypeScript**, featuring '
                  'Muslim-friendly children’s content. It includes parental '
                  'controls to manage kids’ viewing and is also available on '
                  'Android TV and Samsung TV (published on __Play Store__ and '
                  '__App Store__).',
            ]),
            _Block('My Achievement at Durioo+ ?', [
              'Since March 2024, the app has reached 60K downloads (iOS & '
                  'Android) in Malaysia, with over 3 million total video views '
                  'based on backend tracking. It is now expanding internationally, '
                  'with higher numbers across multiple countries.',
            ]),
          ],
          media: _Media(
            l: l,
            maxWidth: 560,
            children: const [_Shot('durioo_promo.jpg', cache: 1000)],
          ),
        );
      case 6:
        return _InfoSlide(
          l: l,
          gradient: _orangeGradient,
          textWeight: 0.64,
          blocks: const [
            _Block('What is the most challenging job during work in Durioo+ ?', [
              'I developed a video player using Expo AV for the Durioo App V1, '
                  'featuring TV casting, offline download, subtitles, video quality '
                  'selection, and next/previous playback. The main challenge was '
                  'playback errors due to unsupported ASF video format (used for '
                  'adaptive streaming). The solution was to fallback to the highest '
                  'quality MP4 when ASF fails to load.',
            ]),
          ],
          media: _Media(
            l: l,
            maxWidth: 400,
            spacing: 12,
            children: const [
              _Shot('durioo_player.jpg', cache: 800),
              _Shot('durioo_downloads.jpg', cache: 800),
              _Shot('durioo_warning.jpg', cache: 800),
            ],
          ),
        );
      case 7:
        return _CollageSlide(
          l: l,
          gradient: _orangeGradient,
          title: 'FWD HadIR',
          titleColor: const Color(0xFF16352B),
          shots: const [
            'hadir_2.jpg',
            'hadir_3.jpg',
            'hadir_4.jpg',
            'hadir_5.jpg',
            'hadir_6.jpg',
            'hadir_7.jpg',
            'hadir_8.png',
            'hadir_9.png',
            'hadir_10.png',
          ],
          shotHeight: l.wide ? 300 : 170,
        );
      case 8:
        return _InfoSlide(
          l: l,
          gradient: _orangeGradient,
          textWeight: 0.59,
          blocks: const [
            _Block('What is the HadIR Apps ?', [
              'HadIR is an internal application designed to monitor employee '
                  'productivity and daily activities. It allows employees to '
                  'manage attendance (WFA/WFO), track activities like meetings or '
                  'training, and ensures valid check-ins using map coordinates '
                  '(with fake GPS detection). Managers and HRD can monitor '
                  'performance, while features like meeting room booking, overtime '
                  'tracking, and expense claims (meals and transport) are also '
                  'supported. If employees forget to check in/out, they can submit '
                  'a report for supervisor validation.',
            ]),
          ],
          media: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: l.wide ? 16 : 10,
            runSpacing: l.wide ? 16 : 10,
            children: [
              for (final n in ['hadir_2.jpg', 'hadir_3.jpg', 'hadir_8.png'])
                _Shot(n, height: l.wide ? 400 : 230),
              // The app's own icon badge, sized like a badge next to the
              // phone mockups instead of stretched to their height.
              _Shot(
                'hadir_icon.png',
                width: l.wide ? 90 : 64,
                radius: 20,
                shadow: false,
              ),
            ],
          ),
        );
      case 9:
        return _CollageSlide(
          l: l,
          gradient: _lifelineGradient,
          logo: 'lifeline_logo.png',
          logoWidth: l.wide ? 420 : 260,
          logoRadius: 0,
          shots: const [
            'lifeline_home.png',
            'lifeline_chat.png',
            'lifeline_voice.png',
            'lifeline_keyboard.png',
            'lifeline_score.png',
            'lifeline_status.png',
            'lifeline_devices.png',
            'lifeline_select.png',
            'lifeline_watch.png',
            'lifeline_call.png',
          ],
          shotHeight: l.wide ? 300 : 170,
        );
      case 10:
        return _InfoSlide(
          l: l,
          gradient: _lifelineGradient,
          textWeight: 0.56,
          ink: Colors.white,
          blocks: const [
            _Block('What is the LifelineConnect Apps ?', [
              'LifeLine is a health and safety ecosystem application built using '
                  'Flutter, with state management using Bloc, Provider, and Cubit. '
                  'It connects devices such as smartwatches, digital dispensers, '
                  'AirPods, and smart locks to a smartphone, collecting health '
                  'data, tracking location, and sharing it with doctors or family '
                  'members (Care Circle). The app also includes chat, calling, and '
                  'reminder alarms.',
              'This cross-platform project (iOS & Android) was developed for a '
                  'client in China (a state-owned enterprise), featuring its own '
                  'branded IoT devices (similar to Xiaomi and Huawei). It aims to '
                  'provide a complete ecosystem for senior users within a single '
                  'Care Circle group. The project is still ongoing and has not yet '
                  'been released on the App Store or Play Store.',
            ]),
          ],
          media: _LifelineMedia(l: l),
        );
      default:
        return _About(l: l);
    }
  }
}

// ---------------------------------------------------------------------------
// Chrome: top bar and side dots
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.wide,
    required this.current,
    required this.onJump,
    required this.onBack,
  });

  final bool wide;
  final ValueNotifier<int> current;
  final ValueChanged<int> onJump;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bar,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Kembali',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Portofolio',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: current,
                  builder: (context, now, _) {
                    if (!wide) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${(now + 1).toString().padLeft(2, '0')} / $_slideCount',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    }
                    return Row(
                      children: [
                        for (var i = 0; i < _chips.length; i++)
                          _Chip(
                            label: _chips[i].$1,
                            selected:
                                now >= _chips[i].$2 &&
                                (i == _chips.length - 1 ||
                                    now < _chips[i + 1].$2),
                            onTap: () => onJump(_chips[i].$2),
                          ),
                        const SizedBox(width: 30),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? _ink : Colors.white70,
          backgroundColor: selected ? _accent : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.current, required this.onJump});

  final ValueNotifier<int> current;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: current,
      builder: (context, now, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _slideCount; i++)
            Semantics(
              button: true,
              label: 'Slide ${i + 1}',
              child: GestureDetector(
                onTap: () => onJump(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 6,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == now ? 12 : 8,
                    height: i == now ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == now ? _accent : Colors.white,
                      border: Border.all(color: const Color(0x66000000)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide building blocks
// ---------------------------------------------------------------------------

class _Slide extends StatelessWidget {
  const _Slide({required this.l, required this.child, this.gradient});

  final _L l;
  final Gradient? gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: l.h),
      decoration: BoxDecoration(gradient: gradient),
      padding: EdgeInsets.fromLTRB(l.pad, 96, l.pad, 56),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Reveal(child: child),
      ),
    );
  }
}

class _Block {
  const _Block(this.heading, this.paragraphs);

  final String heading;
  final List<String> paragraphs;
}

/// `**text**` becomes bold italic (the design's tech-stack call-outs),
/// `++text++` becomes bold only (its plain emphasis, e.g. "Immediately"),
/// and `__text__` becomes underlined.
TextSpan _rich(String text, TextStyle style) {
  final pattern = RegExp(r'\*\*(.+?)\*\*|\+\+(.+?)\+\+|__(.+?)__');
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start)));
    }
    if (m.group(1) != null) {
      spans.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else if (m.group(2) != null) {
      spans.add(
        TextSpan(
          text: m.group(2),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: m.group(3),
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
      );
    }
    cursor = m.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return TextSpan(style: style, children: spans);
}

class _Blocks extends StatelessWidget {
  const _Blocks({required this.l, required this.blocks, required this.ink});

  final _L l;
  final List<_Block> blocks;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final heading = TextStyle(
      color: ink,
      fontSize: l.heading,
      fontWeight: FontWeight.w700,
      height: 1.05,
    );
    final body = TextStyle(color: ink, fontSize: l.body, height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var b = 0; b < blocks.length; b++) ...[
          if (b > 0) const SizedBox(height: 30),
          Text(blocks[b].heading, style: heading),
          const SizedBox(height: 12),
          for (final p in blocks[b].paragraphs) ...[
            Text.rich(_rich(p, body)),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

/// Text on one side, artwork on the other (stacked on narrow screens).
class _InfoSlide extends StatelessWidget {
  const _InfoSlide({
    required this.l,
    required this.gradient,
    required this.blocks,
    required this.media,
    this.ink = _ink,
    this.textWeight = 0.524,
  });

  final _L l;
  final Gradient gradient;
  final List<_Block> blocks;
  final Widget media;
  final Color ink;

  /// Share of the row's width given to the text column on wide screens,
  /// taken from this slide's actual text/media column widths in the Canva
  /// design (it is not an even split on every slide).
  final double textWeight;

  @override
  Widget build(BuildContext context) {
    final text = _Blocks(l: l, blocks: blocks, ink: ink);
    final textFlex = (textWeight.clamp(0.2, 0.8) * 1000).round();
    return _Slide(
      l: l,
      gradient: gradient,
      child: l.wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: textFlex, child: text),
                const SizedBox(width: 56),
                Expanded(flex: 1000 - textFlex, child: Center(child: media)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: 28),
                Center(child: media),
              ],
            ),
    );
  }
}

/// Artwork stacked vertically, capped to [maxWidth].
class _Media extends StatelessWidget {
  const _Media({
    required this.l,
    required this.children,
    required this.maxWidth,
    this.spacing = 14,
  });

  final _L l;
  final List<Widget> children;
  final double maxWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A row of phone screenshots of equal height that wraps when narrow.
class _Phones extends StatelessWidget {
  const _Phones({required this.l, required this.names, required this.height});

  final _L l;
  final List<String> names;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: l.wide ? 16 : 10,
      runSpacing: l.wide ? 16 : 10,
      children: [for (final n in names) _Shot(n, height: height)],
    );
  }
}

/// A collage slide: optional logo or title, then a wrapping gallery of
/// screenshots and optionally one landscape image.
class _CollageSlide extends StatelessWidget {
  const _CollageSlide({
    required this.l,
    required this.gradient,
    required this.shots,
    this.logo,
    this.logoWidth = 260,
    this.logoRadius = 0,
    this.title,
    this.titleColor = Colors.white,
    this.wideShot,
    this.shotHeight,
  });

  final _L l;
  final Gradient gradient;
  final List<String> shots;
  final String? logo;
  final double logoWidth;
  final double logoRadius;
  final String? title;
  final Color titleColor;
  final String? wideShot;
  final double? shotHeight;

  @override
  Widget build(BuildContext context) {
    final h = shotHeight ?? l.phoneH;
    return _Slide(
      l: l,
      gradient: gradient,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logo != null)
            _Shot(
              logo!,
              width: logoWidth,
              radius: logoRadius,
              shadow: false,
              cache: 900,
            ),
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: l.wide ? 72 : 44,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1,
              ),
            ),
          if (logo != null || title != null) SizedBox(height: l.wide ? 36 : 24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: l.wide ? 16 : 10,
            runSpacing: l.wide ? 16 : 10,
            children: [
              for (final n in shots) _Shot(n, height: h),
              if (wideShot != null)
                _Shot(wideShot!, height: h * 0.62, cache: 700),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slide 11: app icon, login screen and the four independence-score screens.
class _LifelineMedia extends StatelessWidget {
  const _LifelineMedia({required this.l});

  final _L l;

  @override
  Widget build(BuildContext context) {
    final h = l.wide ? 300.0 : 190.0;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: l.wide ? 16 : 10,
      runSpacing: l.wide ? 16 : 10,
      children: [
        _Shot(
          'lifeline_icon.png',
          width: l.wide ? 110 : 84,
          radius: 24,
          shadow: false,
        ),
        _Shot('lifeline_login.png', height: h),
        _Shot('lifeline_strong.png', height: h),
        _Shot('lifeline_fair.png', height: h),
        _Shot('lifeline_weak.png', height: h),
        _Shot('lifeline_good.png', height: h),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 1: cover, and slide 12: about + contact
// ---------------------------------------------------------------------------

class _Cover extends StatelessWidget {
  const _Cover({required this.l});

  final _L l;

  // Where the picture frame sits in the photo (fraction of the image),
  // read off the Canva page's own element coordinates (1366x768 canvas).
  static const _frameX = 0.833;
  static const _frameY = 0.6405;
  static const _titleY = 0.33;

  // Laptop screen inside the photo (fractions of the image).
  static const _screenLeft = 0.3865;
  static const _screenTop = 0.5084;
  static const _screenWidth = 0.2333;
  static const _screenHeight = 0.2397;

  @override
  Widget build(BuildContext context) {
    final aspect = kPortfolioAspects['cover.jpg']!;
    final height = math.max(l.h, l.wide ? l.w / aspect : 560.0);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: LayoutBuilder(
        builder: (context, c) {
          // The photo is drawn with BoxFit.cover, aligned to the bottom.
          final scale =
              math.max(c.maxWidth, c.maxHeight * aspect) /
              (c.maxHeight * aspect);
          final imgH = c.maxHeight * scale;
          final imgW = imgH * aspect;
          final dx = (c.maxWidth - imgW) / 2;
          final dy = c.maxHeight - imgH;
          final frameX = dx + _frameX * imgW;
          final frameY = dy + _frameY * imgH;
          final titleY = math.max(dy + _titleY * imgH, 130.0);
          final frameVisible =
              frameX > c.maxWidth * 0.1 && frameX < c.maxWidth * 0.93;
          final titleSize = (imgW * 0.0547).clamp(30.0, 80.0);
          final nameSize = (imgW * 0.0176).clamp(12.0, 26.0);
          const style = TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            height: 1,
          );
          return Stack(
            children: [
              Positioned.fill(
                child: _Lazy(
                  aspect: aspect,
                  fill: true,
                  builder: (_) => Image.asset(
                    '${_assetDir}cover.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    cacheWidth: 1600,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
              // The laptop in the photo shows the LinkedIn profile, as in the
              // Canva design (a separate image laid over the black screen).
              Positioned(
                left: dx + _screenLeft * imgW,
                top: dy + _screenTop * imgH,
                width: _screenWidth * imgW,
                height: _screenHeight * imgH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: _Lazy(
                    aspect: kPortfolioAspects['cover_screen.jpg']!,
                    fill: true,
                    builder: (_) => Image.asset(
                      '${_assetDir}cover_screen.jpg',
                      fit: BoxFit.cover,
                      cacheWidth: 960,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: titleY - titleSize / 2,
                child: Column(
                  children: [
                    // One line always: scale down instead of wrapping on phones.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'MY PORTOFOLIO',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                            fontSize: titleSize,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                    if (!frameVisible) ...[
                      const SizedBox(height: 14),
                      Text(
                        'KIKI TRIANSYAH',
                        style: style.copyWith(
                          fontSize: 18,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (frameVisible)
                Positioned(
                  left: frameX - 80,
                  width: 160,
                  top: frameY - nameSize / 2,
                  child: Text(
                    'KIKI TRIANSYAH',
                    textAlign: TextAlign.center,
                    style: style.copyWith(
                      fontSize: nameSize,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.l});

  final _L l;

  static const _contacts = <(FaIconData, Color, String, String?)>[
    (
      FontAwesomeIcons.envelope,
      Color(0xFFEA4335),
      'kiki.triansyah93@gmail.com',
      'mailto:kiki.triansyah93@gmail.com',
    ),
    (
      FontAwesomeIcons.linkedin,
      Color(0xFF0A66C2),
      'linkedin.com/in/kiki-triansyah',
      'https://www.linkedin.com/in/kiki-triansyah/',
    ),
    (
      FontAwesomeIcons.whatsapp,
      Color(0xFF25D366),
      '+6287728020907',
      'https://wa.me/6287728020907',
    ),
    (
      FontAwesomeIcons.github,
      Color(0xFF181717),
      '@kikimaxs',
      'https://github.com/kikimaxs',
    ),
    (
      FontAwesomeIcons.gitlab,
      Color(0xFFFC6D26),
      '@kikitriansyah',
      'https://gitlab.com/kikitriansyah',
    ),
    (FontAwesomeIcons.discord, Color(0xFF5865F2), '@kikimaxs', null),
  ];

  @override
  Widget build(BuildContext context) {
    final heading = TextStyle(
      color: const Color(0xFF2E2E2E),
      fontSize: l.wide ? 48 : 34,
      fontWeight: FontWeight.w700,
    );
    final body = TextStyle(
      color: const Color(0xFF2E2E2E),
      fontSize: l.wide ? 17 : 15,
      height: 1.5,
    );

    final profile = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              SizedBox(
                width: l.wide ? 200 : 150,
                child: const _Shot.asset(
                  'assets/img/photo_profile.jpg',
                  aspect: 0.7782,
                  radius: 24,
                  cache: 500,
                  semanticLabel: 'Foto profil Kiki Triansyah',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'KIKI TRIANSYAH',
                style: TextStyle(
                  fontSize: l.wide ? 33 : 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Software Engineer | Mobile Developer',
                style: TextStyle(
                  fontSize: l.wide ? 21 : 15,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF3A444F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text('About Me', style: heading),
        const SizedBox(height: 12),
        Text.rich(
          _rich(
            'I am Kiki Triansyah, a Software Engineer | Mobile Developer with 6 years '
            'of experience delivering scalable, high-impact applications. I specialize '
            'in **React Native**, **JavaScript**, and **TypeScript**, with additional '
            'experience in **Swift (SwiftUI)** and **Flutter**. I also have backend '
            'experience using **Node.js**, **Express.js**, and databases such as '
            '**MySQL** and **SQLite**.',
            body,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          _rich(
            'Beyond development, I focus on building products that drive user '
            'engagement and business value, collaborating closely with teams to align '
            'technical solutions with product and marketing goals.',
            body,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          _rich(
            'I hold a Bachelor’s degree and am currently open to new opportunities, '
            'ready to contribute ++Immediately++ or ++ASAP++ going to ++Onsite++ or '
            '++Remote++, in Indonesia or globally.',
            body,
          ),
        ),
      ],
    );

    final contact = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact :', style: heading),
        const SizedBox(height: 22),
        for (final c in _contacts)
          _ContactRow(icon: c.$1, color: c.$2, label: c.$3, url: c.$4),
      ],
    );

    return _Slide(
      l: l,
      gradient: _aboutGradient,
      child: l.wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 11, child: profile),
                const SizedBox(width: 64),
                Expanded(flex: 9, child: contact),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [profile, const SizedBox(height: 36), contact],
            ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.color,
    required this.label,
    this.url,
  });

  final FaIconData icon;
  final Color color;
  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: FaIcon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                color: const Color(0xFF111827),
                decoration: url == null ? null : TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
    if (url == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
      child: row,
    );
  }
}

// ---------------------------------------------------------------------------
// Images, loaded only when they come near the viewport
// ---------------------------------------------------------------------------

/// Lets lazy images know the page has scrolled (throttled by the page).
class _ScrollTick extends InheritedNotifier<ValueNotifier<int>> {
  const _ScrollTick({required ValueNotifier<int> tick, required super.child})
    : super(notifier: tick);

  static ValueNotifier<int>? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ScrollTick>()?.notifier;
}

class _Lazy extends StatefulWidget {
  const _Lazy({required this.aspect, required this.builder, this.fill = false});

  final double aspect;
  final WidgetBuilder builder;
  final bool fill;

  @override
  State<_Lazy> createState() => _LazyState();
}

class _LazyState extends State<_Lazy> {
  bool _show = false;
  bool _active = true;
  double _viewport = 0;
  ValueNotifier<int>? _tick;

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewport = MediaQuery.sizeOf(context).height;
    final tick = _ScrollTick.of(context);
    if (!identical(tick, _tick)) {
      _tick?.removeListener(_check);
      _tick = tick;
      if (!_show) _tick?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_show || !mounted || !_active || _viewport <= 0) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < _viewport + 700 && top + box.size.height > -700) {
      _tick?.removeListener(_check);
      setState(() => _show = true);
    }
  }

  @override
  void dispose() {
    _tick?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _show
        ? widget.builder(context)
        : const ColoredBox(color: Color(0x1FFFFFFF));
    if (widget.fill) return content;
    return AspectRatio(aspectRatio: widget.aspect, child: content);
  }
}

/// One image from assets/img/portfolio with rounded corners and a hairline
/// border (no blurred shadows: they are costly while scrolling).
class _Shot extends StatelessWidget {
  const _Shot(
    this.name, {
    this.height,
    this.width,
    this.radius = 14,
    this.shadow = true,
    this.cache = 420,
  }) : _path = null,
       _aspect = null,
       semanticLabel = null;

  /// An image outside the portfolio folder, with its own aspect ratio.
  const _Shot.asset(
    String path, {
    required double aspect,
    this.radius = 14,
    this.cache = 420,
    this.semanticLabel,
  }) : name = path,
       _path = path,
       _aspect = aspect,
       height = null,
       width = null,
       shadow = true;

  final String name;
  final String? _path;
  final double? _aspect;
  final double? height;
  final double? width;
  final double radius;
  final bool shadow;
  final int cache;

  /// Screen-reader description. Defaults to one derived from the file name
  /// (e.g. every `mola_*` shot reads as "app MOLA TV") so every image in
  /// the portfolio is announced as *something*, without having to label
  /// each of the ~50 call sites by hand.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect ?? kPortfolioAspects[name] ?? 1;
    final path = _path ?? '$_assetDir$name';
    Widget image = _Lazy(
      aspect: aspect,
      builder: (_) => Image.asset(
        path,
        fit: BoxFit.cover,
        cacheWidth: cache,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => const ColoredBox(color: Color(0x33000000)),
      ),
    );
    image = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: shadow ? Border.all(color: const Color(0x26000000)) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: image,
      ),
    );
    image = Semantics(
      label: semanticLabel ?? _autoShotLabel(name),
      image: true,
      child: image,
    );
    if (height != null) return SizedBox(height: height, child: image);
    if (width != null) return SizedBox(width: width, child: image);
    return image;
  }
}

/// A reasonable screen-reader label guessed from a portfolio image's file
/// name, so a gallery shot still reads as "screenshot of the X app" instead
/// of being announced as an unlabelled image.
String _autoShotLabel(String name) {
  if (name.startsWith('cover_screen')) {
    return 'Tangkapan layar profil LinkedIn di laptop';
  }
  if (name.startsWith('cover')) {
    return 'Foto meja kerja dengan laptop, latar sampul portofolio';
  }
  const apps = {
    'mola': 'MOLA TV',
    'durioo': 'Durioo+',
    'hadir': 'FWD HadIR',
    'lifeline': 'LifelineConnect',
  };
  for (final entry in apps.entries) {
    if (!name.startsWith('${entry.key}_')) continue;
    if (name.contains('logo')) return 'Logo ${entry.value}';
    if (name.contains('icon')) return 'Ikon aplikasi ${entry.value}';
    return 'Cuplikan layar aplikasi ${entry.value}';
  }
  return 'Gambar portofolio';
}
