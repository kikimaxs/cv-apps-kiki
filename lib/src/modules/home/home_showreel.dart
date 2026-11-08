import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';

import 'home_fx.dart';

const _ink = Color(0xFF080D18);
const _muted = Color(0xFFB8C8DA);
const _accent = Color(0xFF67D4FF);

/// One promotional video shown in the showreel.
class ShowreelItem {
  final String title;
  final String tag;
  final String description;
  final String poster;
  final String video;
  final String duration;
  final Color accent;

  const ShowreelItem({
    required this.title,
    required this.tag,
    required this.description,
    required this.poster,
    required this.video,
    required this.duration,
    required this.accent,
  });
}

const showreelItems = [
  ShowreelItem(
    title: 'Durioo+: Released App',
    tag: 'MOBILE • PLAYSTORE • APPSTORE',
    description:
        'Project rilis yang saya kerjakan dari awal hingga tayang publik.',
    poster: 'assets/img/durioo_poster.jpg',
    video: 'assets/video/durioo+_memang_berbaloi!.mp4',
    duration: '0:45',
    accent: Color(0xFFFF9F43),
  ),
  ShowreelItem(
    title: 'Production Showcase',
    tag: 'PROMO • VIDEO • CAMPAIGN',
    description: 'Digital product berkualitas tinggi yang sudah rilis.',
    poster: 'assets/img/showcase_poster.jpg',
    video: 'assets/video/0411.mp4',
    duration: '0:19',
    accent: _accent,
  ),
];

/// "Showreel" section: poster cards that preview on hover and open a
/// cinematic player on tap.
class HomeShowreel extends StatelessWidget {
  final List<ShowreelItem> items;

  const HomeShowreel({super.key, this.items = showreelItems});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SHOWREEL',
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Karya yang sudah tayang.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 31 : 42,
                  fontWeight: FontWeight.w900,
                  height: 1.13,
                  letterSpacing: -1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Video promosi dari produk yang pernah saya bangun. Pilih dengan panah atau ketuk kartu samping, klik kartu tengah untuk menonton.',
                style: TextStyle(color: _muted, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 26),
              Reveal(child: ShowreelCarousel(items: items)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Port of the "Circular Testimonials" component: three stacked, tilted
/// posters (centre one active) next to copy that blurs in word by word, with
/// arrow buttons, 5s autoplay (stops on first manual action) and arrow keys.
class ShowreelCarousel extends StatefulWidget {
  final List<ShowreelItem> items;

  const ShowreelCarousel({super.key, required this.items});

  @override
  State<ShowreelCarousel> createState() => _ShowreelCarouselState();
}

class _ShowreelCarouselState extends State<ShowreelCarousel>
    with SingleTickerProviderStateMixin, AmbientAware<ShowreelCarousel> {
  static const _autoplayEvery = Duration(seconds: 5);

  final FocusNode _focus = FocusNode(debugLabel: 'showreel-carousel');
  late final Ticker _autoplay;
  Duration _lastSwitch = Duration.zero;
  int _active = 0;
  bool _autoplayConfigured = false;
  bool _autoplayEnabled = false;

  @override
  void initState() {
    super.initState();
    _autoplay = createTicker(_onAutoplayTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_autoplayConfigured) {
      _autoplayConfigured = true;
      _autoplayEnabled =
          !MediaQuery.disableAnimationsOf(context) && widget.items.length > 1;
    }
    _syncAutoplay();
  }

  @override
  void onActiveChanged(bool active) {
    _syncAutoplay();
    // The play badge pulse only runs while the page is active.
    if (mounted) setState(() {});
  }

  /// Autoplay (and its ticker) only runs while enabled and on screen.
  void _syncAutoplay() {
    final shouldRun = _autoplayEnabled && isActive;
    if (shouldRun && !_autoplay.isActive) {
      _lastSwitch = Duration.zero;
      _autoplay.start();
    } else if (!shouldRun && _autoplay.isActive) {
      _autoplay.stop();
    }
  }

  void _onAutoplayTick(Duration elapsed) {
    if (elapsed - _lastSwitch >= _autoplayEvery) {
      _lastSwitch = elapsed;
      _step(1, manual: false);
    }
  }

  void _stopAutoplay() {
    _autoplayEnabled = false;
    _syncAutoplay();
  }

  void _step(int delta, {bool manual = true}) {
    final n = widget.items.length;
    if (n == 0 || !mounted) return;
    if (manual) _stopAutoplay();
    setState(() => _active = (_active + delta + n) % n);
  }

  void _select(int index) {
    _stopAutoplay();
    _focus.requestFocus();
    setState(() => _active = index);
  }

  Future<void> _open(ShowreelItem item) async {
    _stopAutoplay();
    await showShowreelPlayer(context, item);
  }

  @override
  void dispose() {
    _autoplay.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items[_active];
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
      },
      child: Focus(
        focusNode: _focus,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final stage = _buildStage(
              wide ? (constraints.maxWidth - 72) / 2 : constraints.maxWidth,
            );
            final content = _buildContent(item, wide);
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [stage, const SizedBox(height: 34), content],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: stage),
                const SizedBox(width: 72),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStage(double width) {
    final items = widget.items;
    final n = items.length;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final gap = (width * 0.15).clamp(26.0, 84.0);
    final stick = gap * 0.8;
    final cardW = width - gap * 1.2;
    final cardH = cardW * 0.6;
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 800);

    // Draw order: hidden < sides < active, keeping each card's widget state.
    int depth(int i) => i == _active
        ? 3
        : (i == (_active - 1 + n) % n || i == (_active + 1) % n)
        ? 2
        : 1;
    final order = List<int>.generate(n, (i) => i)
      ..sort((a, b) => depth(a).compareTo(depth(b)));

    Matrix4 pose(double dx, double dy, double scale, double rotY) {
      return Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..multiply(Matrix4.translationValues(dx, dy, 0))
        ..multiply(Matrix4.diagonal3Values(scale, scale, 1))
        ..rotateY(rotY);
    }

    return SizedBox(
      width: double.infinity,
      height: cardH + stick + 8,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          for (final i in order)
            Builder(
              key: ValueKey('showreel-poster-$i'),
              builder: (context) {
                final isCentre = i == _active;
                final isLeft = i == (_active - 1 + n) % n;
                final isRight = i == (_active + 1) % n;
                final visible = isCentre || isLeft || isRight;
                final transform = isCentre
                    ? pose(0, 0, 1, 0)
                    : isLeft
                    ? pose(-gap, -stick, 0.85, 0.2618)
                    : isRight
                    ? pose(gap, -stick, 0.85, -0.2618)
                    : pose(0, 0, 0.85, 0);
                final data = items[i];
                return IgnorePointer(
                  ignoring: !visible,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: duration,
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      width: cardW,
                      height: cardH,
                      duration: duration,
                      curve: const Cubic(0.4, 2, 0.3, 1),
                      transform: transform,
                      transformAlignment: Alignment.center,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Semantics(
                          button: true,
                          label: isCentre
                              ? 'Putar video ${data.title}'
                              : 'Pilih video ${data.title}',
                          child: GestureDetector(
                            key: ValueKey('showreel-card-$i'),
                            onTap: () => isCentre ? _open(data) : _select(i),
                            child: RepaintBoundary(
                              child: _PosterCard(
                                item: data,
                                active: isCentre,
                                duration: duration,
                                pulse: isActive && !reduced,
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
        ],
      ),
    );
  }

  Widget _buildContent(ShowreelItem item, bool wide) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final words = item.description.split(' ');
    const quoteStyle = TextStyle(color: _muted, fontSize: 17, height: 1.7);
    final copy = KeyedSubtree(
      key: ValueKey('showreel-copy-$_active'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.tag,
            style: TextStyle(
              color: item.accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            children: [
              for (var i = 0; i < words.length; i++)
                reduced
                    ? Text('${words[i]} ', style: quoteStyle)
                    : Text('${words[i]} ', style: quoteStyle)
                          .animate(delay: (25 * i).ms)
                          .fadeIn(duration: 220.ms, curve: Curves.easeInOut)
                          .slideY(begin: 0.3, end: 0, duration: 220.ms),
            ],
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topLeft,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: copy,
        ),
        SizedBox(height: wide ? 34 : 26),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: const ValueKey('showreel-watch'),
              onPressed: () => _open(item),
              icon: const FaIcon(FontAwesomeIcons.play, size: 14),
              label: const Text('Tonton video'),
              style: FilledButton.styleFrom(
                backgroundColor: item.accent,
                foregroundColor: _ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _ArrowButton(
              key: const ValueKey('showreel-prev'),
              icon: FontAwesomeIcons.arrowLeft,
              label: 'Video sebelumnya',
              color: item.accent,
              onTap: () => _step(-1),
            ),
            _ArrowButton(
              key: const ValueKey('showreel-next'),
              icon: FontAwesomeIcons.arrowRight,
              label: 'Video berikutnya',
              color: item.accent,
              onTap: () => _step(1),
            ),
            Text(
              '${(_active + 1).toString().padLeft(2, '0')} / ${widget.items.length.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PosterCard extends StatelessWidget {
  final ShowreelItem item;
  final bool active;
  final Duration duration;
  final bool pulse;

  const _PosterCard({
    required this.item,
    required this.active,
    required this.duration,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              item.poster,
              fit: BoxFit.cover,
              cacheWidth: 800,
              filterQuality: FilterQuality.low,
            ),
            AnimatedContainer(
              duration: duration,
              color: active ? Colors.transparent : _ink.withValues(alpha: 0.38),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99080D18)],
                  stops: [0.55, 1],
                ),
              ),
            ),
            if (active)
              Center(
                child: _PlayBadge(color: item.accent, pulse: pulse),
              ),
            if (active)
              Positioned(
                left: 14,
                bottom: 14,
                child: _Chip(
                  icon: FontAwesomeIcons.clock,
                  label: item.duration,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatefulWidget {
  final FaIconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ArrowButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 300),
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovered ? Colors.white : widget.color,
            ),
            child: FaIcon(widget.icon, color: _ink, size: 18),
          ),
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  final Color color;
  final bool pulse;

  const _PlayBadge({required this.color, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final ring = Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
      ),
    );
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (pulse)
            ring
                .animate(onPlay: (c) => c.repeat())
                .scaleXY(begin: 0.85, end: 1.35, duration: 1600.ms)
                .fadeOut(begin: 1, duration: 1600.ms),
          Container(
            width: 70,
            height: 70,
            // FaIcon (unlike Icon) does not centre itself in a tight box.
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            ),
            child: const FaIcon(
              FontAwesomeIcons.play,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final FaIconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the full player in a blurred, scaled-in dialog. Esc or tapping
/// outside closes it.
Future<void> showShowreelPlayer(BuildContext context, ShowreelItem item) {
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup video',
    barrierColor: Colors.black.withValues(alpha: 0.86),
    transitionDuration: reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 380),
    pageBuilder: (context, _, _) => ShowreelPlayer(item: item),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class ShowreelPlayer extends StatefulWidget {
  final ShowreelItem item;

  const ShowreelPlayer({super.key, required this.item});

  @override
  State<ShowreelPlayer> createState() => _ShowreelPlayerState();
}

class _ShowreelPlayerState extends State<ShowreelPlayer> {
  late final VideoPlayerController _controller;
  bool _failed = false;
  bool _closing = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.item.video)
      ..addListener(_onTick);
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() {});
      await _controller.play();
      _scheduleHide();
    } catch (_) {
      // Some browsers block autoplay with sound; fall back to muted.
      if (_controller.value.isInitialized) {
        await _controller.setVolume(0);
        await _controller.play().catchError((_) {});
      } else if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _wake() {
    if (!_showControls) setState(() => _showControls = true);
    _scheduleHide();
  }

  void _togglePlay() {
    final value = _controller.value;
    if (!value.isInitialized) return;
    if (value.isPlaying) {
      _controller.pause();
      setState(() => _showControls = true);
    } else {
      if (value.position >= value.duration) _controller.seekTo(Duration.zero);
      _controller.play();
      _scheduleHide();
    }
  }

  void _toggleMute() {
    _controller.setVolume(_controller.value.volume == 0 ? 1 : 0);
    _wake();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  static String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final value = _controller.value;
    final size = MediaQuery.sizeOf(context);
    final maxWidth = (size.width - 32).clamp(0.0, 1100.0);
    final maxHeight = size.height - 140;
    final width = maxWidth / (16 / 9) > maxHeight
        ? maxHeight * 16 / 9
        : maxWidth;

    // On web the video is a platform view that renders blank (white) while
    // the dialog fades/scales out, so swap it for the poster as soon as the
    // route starts popping (Esc, barrier tap or the close button).
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && mounted && !_closing) {
          _controller.pause();
          setState(() => _closing = true);
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): _togglePlay,
          const SingleActivator(LogicalKeyboardKey.keyM): _toggleMute,
        },
        child: Focus(
          autofocus: true,
          child: Center(
            child: SizedBox(
              width: width,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.tag,
                                style: TextStyle(
                                  color: item.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('showreel-close'),
                          tooltip: 'Tutup (Esc)',
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    MouseRegion(
                      onHover: (_) => _wake(),
                      child: GestureDetector(
                        onTap: _togglePlay,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  item.poster,
                                  fit: BoxFit.cover,
                                  cacheWidth: 800,
                                  filterQuality: FilterQuality.low,
                                ),
                                if (value.isInitialized && !_closing)
                                  ColoredBox(
                                    color: Colors.black,
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: value.aspectRatio,
                                        child: VideoPlayer(_controller),
                                      ),
                                    ),
                                  ),
                                if (!value.isInitialized && !_failed)
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                if (_failed)
                                  const Center(
                                    child: _Chip(
                                      icon:
                                          FontAwesomeIcons.triangleExclamation,
                                      label: 'VIDEO GAGAL DIMUAT',
                                    ),
                                  ),
                                if (value.isInitialized && !_closing)
                                  AnimatedOpacity(
                                    opacity: _showControls ? 1 : 0,
                                    duration: const Duration(milliseconds: 250),
                                    child: _Controls(
                                      controller: _controller,
                                      accent: item.accent,
                                      position: _format(value.position),
                                      duration: _format(value.duration),
                                      onTogglePlay: _togglePlay,
                                      onToggleMute: _toggleMute,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Keyboard shortcuts are only useful with a keyboard.
                    if (size.width >= 700) ...const [
                      SizedBox(height: 10),
                      Text(
                        'Spasi: putar/jeda  •  M: suara  •  Esc: tutup',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final VideoPlayerController controller;
  final Color accent;
  final String position;
  final String duration;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;

  const _Controls({
    required this.controller,
    required this.accent,
    required this.position,
    required this.duration,
    required this.onTogglePlay,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xCC000000)],
          stops: [0.6, 1],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                colors: VideoProgressColors(
                  playedColor: accent,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 12, 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: value.isPlaying ? 'Jeda' : 'Putar',
                  onPressed: onTogglePlay,
                  color: Colors.white,
                  icon: FaIcon(
                    value.isPlaying
                        ? FontAwesomeIcons.pause
                        : FontAwesomeIcons.play,
                  ),
                ),
                IconButton(
                  tooltip: value.volume == 0 ? 'Nyalakan suara' : 'Bisukan',
                  onPressed: onToggleMute,
                  color: Colors.white,
                  icon: FaIcon(
                    value.volume == 0
                        ? FontAwesomeIcons.volumeXmark
                        : FontAwesomeIcons.volumeHigh,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$position / $duration',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
