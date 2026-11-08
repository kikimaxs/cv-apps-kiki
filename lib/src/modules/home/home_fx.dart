import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _cyan = Color(0xFF67D4FF);
const _violet = Color(0xFFB49BFF);
const _mint = Color(0xFF79E4BA);
const _base = Color(0xFF080D18);

bool _reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);

/// Cheap per-tick filter for scroll listeners: only calls [onMoved] once the
/// offset has moved [threshold] logical pixels since the previous call, so
/// geometry checks do not run on every frame of a scroll.
class _ScrollGate {
  _ScrollGate(this.onMoved);

  static const double threshold = 40;

  final VoidCallback onMoved;
  ScrollPosition? _position;
  double? _lastPixels;

  void attach(ScrollPosition? position) {
    if (identical(position, _position)) return;
    _position?.removeListener(_onScroll);
    _position = position;
    _lastPixels = null;
    _position?.addListener(_onScroll);
  }

  void detach() {
    _position?.removeListener(_onScroll);
    _position = null;
  }

  void _onScroll() {
    final position = _position;
    if (position == null || !position.hasPixels) return;
    final pixels = position.pixels;
    final last = _lastPixels;
    if (last != null && (pixels - last).abs() < threshold) return;
    _lastPixels = pixels;
    onMoved();
  }
}

/// Debug switch for A/B measurements: build with
/// `--dart-define=CALM_MODE=false` to keep ambient animations running forever.
const bool kCalmMode = bool.fromEnvironment('CALM_MODE', defaultValue: true);

/// Tracks whether the visitor is interacting with the page.
///
/// Endless "ambient" animations (aurora, orbit, marquee, autoplay, pulses) only
/// run while it is [awake]. After [idleAfter] without any pointer/touch/scroll
/// input the page goes calm: every ticker stops, Flutter stops producing
/// frames and CPU/GPU drop to ~0 (no fan noise, no battery drain). Any input
/// wakes it again.
///
/// Uses a counter + periodic timer (no wall clock) so it behaves under fake
/// time in tests, and the timer only exists while awake.
class AmbientActivity extends ChangeNotifier {
  AmbientActivity({this.idleAfter = const Duration(seconds: 8)});

  static const _checkEvery = Duration(seconds: 2);

  final Duration idleAfter;
  bool _awake = true;
  int _pokes = 0;
  int _seenPokes = 0;
  int _quietChecks = 0;
  Timer? _timer;

  bool get awake => _awake;

  /// Starts watching for idleness (the page begins awake).
  void start() => _timer ??= Timer.periodic(_checkEvery, _check);

  /// Records user input. Cheap enough to call on every pointer event.
  void poke() {
    _pokes++;
    if (_awake) return;
    _awake = true;
    _quietChecks = 0;
    start();
    notifyListeners();
  }

  void _check(Timer timer) {
    if (!kCalmMode) return;
    if (_pokes != _seenPokes) {
      _seenPokes = _pokes;
      _quietChecks = 0;
      return;
    }
    _quietChecks++;
    if (_checkEvery * _quietChecks >= idleAfter) {
      _awake = false;
      timer.cancel();
      _timer = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

/// Provides the page's [AmbientActivity] to descendants.
class AmbientScope extends InheritedNotifier<AmbientActivity> {
  const AmbientScope({
    super.key,
    required AmbientActivity activity,
    required super.child,
  }) : super(notifier: activity);

  /// The nearest activity, or null when there is no scope (e.g. in tests that
  /// pump a widget alone): consumers then simply stay active.
  static AmbientActivity? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AmbientScope>()?.notifier;
}

/// Tells a [State] whether its endless animation should run: the widget must
/// be on screen (with a margin) AND the visitor must have been active
/// recently (see [AmbientActivity]). Start/stop your controllers in
/// [onActiveChanged] and read [isActive] when (re)syncing.
mixin AmbientAware<T extends StatefulWidget> on State<T> {
  late final _ScrollGate _visibilityGate = _ScrollGate(_checkVisibility);
  AmbientActivity? _ambient;
  double _viewportHeight = 0;
  bool _visibilityActive = true;
  bool _onScreen = true;
  bool _wasActive = true;

  /// True while the widget is visible and the page is not calm.
  bool get isActive => _onScreen && (_ambient?.awake ?? true);

  /// Called whenever [isActive] flips.
  void onActiveChanged(bool active);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read once here (not per scroll tick) so scrolling stays cheap.
    _viewportHeight = MediaQuery.sizeOf(context).height;
    _visibilityGate.attach(Scrollable.maybeOf(context)?.position);
    final ambient = AmbientScope.maybeOf(context);
    if (!identical(ambient, _ambient)) {
      _ambient?.removeListener(_ambientChanged);
      _ambient = ambient;
      _ambient?.addListener(_ambientChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void activate() {
    super.activate();
    _visibilityActive = true;
  }

  @override
  void deactivate() {
    _visibilityActive = false;
    super.deactivate();
  }

  @override
  void dispose() {
    _visibilityGate.detach();
    _ambient?.removeListener(_ambientChanged);
    super.dispose();
  }

  void _ambientChanged() => _notifyIfFlipped();

  void _checkVisibility() {
    if (!mounted || !_visibilityActive || _viewportHeight <= 0) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    _onScreen = bottom > -120 && top < _viewportHeight + 120;
    _notifyIfFlipped();
  }

  void _notifyIfFlipped() {
    if (!mounted) return;
    final active = isActive;
    if (active == _wasActive) return;
    _wasActive = active;
    onActiveChanged(active);
  }
}

// Performance notes
// -----------------
// * Everything that animates forever is driven by ONE controller/ticker and
//   paints through a CustomPainter or a Flow/Transform, so frames only
//   repaint: no widget rebuilds and no relayout.
// * Static layers (grid, rings, marquee row) sit in their own RepaintBoundary
//   and are rasterised once.
// * No BackdropFilter, ImageFiltered blur, ShaderMask or BoxShadow that
//   animates: those force expensive offscreen passes on low-end GPUs.

// ---------------------------------------------------------------------------
// Aurora background
// ---------------------------------------------------------------------------

/// Slowly drifting colour blobs (repainted at ~30fps) over a static grid.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin, AmbientAware<AuroraBackground> {
  static const _cycleMs = 40000;
  static const _frameGap = Duration(milliseconds: 33);

  final ValueNotifier<double> _phase = ValueNotifier<double>(0.2);
  late final Ticker _ticker;
  Duration _lastFrame = Duration.zero;
  double _phaseAtStart = 0.2;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void onActiveChanged(bool active) => _sync();

  void _sync() {
    if (_reduced(context) || !isActive) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      // The ticker restarts at elapsed == 0; continue from where we paused.
      _phaseAtStart = _phase.value;
      _lastFrame = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    if (elapsed - _lastFrame < _frameGap) return;
    _lastFrame = elapsed;
    _phase.value = (_phaseAtStart + elapsed.inMilliseconds / _cycleMs) % 1.0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: CustomPaint(painter: _BlobPainter(_phase))),
          const RepaintBoundary(child: CustomPaint(painter: _GridPainter())),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final ValueListenable<double> phase;

  _BlobPainter(this.phase) : super(repaint: phase);

  @override
  void paint(Canvas canvas, Size size) {
    final a = phase.value * math.pi * 2;
    final reach = math.max(size.shortestSide, 420);

    void blob(Color color, double fx, double fy, double offset, double radius) {
      final center = Offset(
        size.width * (fx + 0.16 * math.sin(a + offset)),
        size.height * (fy + 0.12 * math.cos(a + offset * 1.7)),
      );
      final r = radius * reach;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    blob(_cyan, 0.82, 0.10, 0, 0.78);
    blob(_violet, 0.10, 0.45, 2.1, 0.7);
    blob(_mint, 0.60, 0.95, 4.2, 0.62);
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 56.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Fade the grid (and the blobs) towards the edges.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [_base.withValues(alpha: 0), _base.withValues(alpha: 0.9)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Cursor / touch following glow
// ---------------------------------------------------------------------------

class _GlowModel extends ChangeNotifier {
  Offset fast = Offset.zero;
  Offset slow = Offset.zero;
  double opacity = 0;

  void changed() => notifyListeners();
}

/// Paints a soft glow that eases towards the pointer (mouse hover or a finger
/// dragging) and fades out when it leaves. Events pass through untouched, and
/// the ticker only runs while the glow is still moving or fading.
class CursorGlow extends StatefulWidget {
  final Widget background;
  final Widget child;
  final Color color;

  const CursorGlow({
    super.key,
    required this.background,
    required this.child,
    this.color = _cyan,
  });

  @override
  State<CursorGlow> createState() => _CursorGlowState();
}

class _CursorGlowState extends State<CursorGlow>
    with SingleTickerProviderStateMixin {
  final _model = _GlowModel();
  final _activity = AmbientActivity();
  late final Ticker _ticker;
  Offset _target = Offset.zero;
  bool _active = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _activity.start();
  }

  void _onPointer(PointerEvent event) {
    _activity.poke();
    _target = event.localPosition;
    if (!_seeded) {
      _model.fast = _target;
      _model.slow = _target;
      _seeded = true;
    }
    _active = true;
    if (!_ticker.isActive) _ticker.start();
  }

  void _release(PointerEvent event) {
    _activity.poke();
    if (event.kind == PointerDeviceKind.mouse) return;
    _leave();
  }

  void _leave() {
    _active = false;
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration _) {
    final goal = _active ? 1.0 : 0.0;
    _model.fast = Offset.lerp(_model.fast, _target, 0.22)!;
    _model.slow = Offset.lerp(_model.slow, _target, 0.07)!;
    _model.opacity += (goal - _model.opacity) * 0.12;
    final settled =
        (_model.fast - _target).distance < 0.3 &&
        (_model.slow - _target).distance < 0.3 &&
        (_model.opacity - goal).abs() < 0.01;
    if (settled) _model.opacity = goal;
    _model.changed();
    if (settled) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _model.dispose();
    _activity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced(context)) {
      return AmbientScope(
        activity: _activity,
        child: Stack(
          children: [
            Positioned.fill(child: widget.background),
            widget.child,
          ],
        ),
      );
    }
    return AmbientScope(
      activity: _activity,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: _onPointer,
        onPointerMove: _onPointer,
        onPointerDown: _onPointer,
        onPointerUp: _release,
        onPointerCancel: _release,
        // Mouse wheel / trackpad scrolling counts as activity too.
        onPointerSignal: (_) => _activity.poke(),
        child: MouseRegion(
          onExit: (_) => _leave(),
          child: Stack(
            children: [
              Positioned.fill(child: widget.background),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _GlowPainter(_model, widget.color),
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final _GlowModel model;
  final Color color;

  _GlowPainter(this.model, this.color) : super(repaint: model);

  void _glow(Canvas canvas, Offset center, double radius, double alpha) {
    if (alpha <= 0.002) return;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final o = model.opacity;
    if (o <= 0.002) return;
    _glow(canvas, model.slow, 300, 0.10 * o);
    _glow(canvas, model.fast, 150, 0.17 * o);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scroll reveal
// ---------------------------------------------------------------------------

/// Fades and lifts [child] in once, the first time it scrolls into view.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double dy;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.dy = 0.07,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  late final _ScrollGate _gate = _ScrollGate(_check);
  double _viewportHeight = 0;
  bool _triggered = false;
  bool _shown = false;
  bool _active = true;

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
    _viewportHeight = MediaQuery.sizeOf(context).height;
    if (!_triggered) _gate.attach(Scrollable.maybeOf(context)?.position);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_triggered || !mounted || !_active || _viewportHeight <= 0) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top >= _viewportHeight * 0.93) return;
    _triggered = true;
    _gate.detach();
    if (widget.delay == Duration.zero) {
      setState(() => _shown = true);
    } else {
      Future.delayed(widget.delay, () {
        if (mounted && _active) setState(() => _shown = true);
      });
    }
  }

  @override
  void dispose() {
    _gate.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced(context)) return widget.child;
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : Offset(0, widget.dy),
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Headline
// ---------------------------------------------------------------------------

/// Headline whose words rise and fade in one after another. Words in
/// [highlight] get an accent gradient.
class AnimatedHeadline extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Set<int> highlight;

  const AnimatedHeadline({
    super.key,
    required this.text,
    required this.style,
    this.highlight = const {},
  });

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    final reduced = _reduced(context);
    final gap = (style.fontSize ?? 40) * 0.27;
    return Semantics(
      header: true,
      label: text,
      excludeSemantics: true,
      child: Wrap(
        spacing: gap,
        children: [
          for (var i = 0; i < words.length; i++) _word(words[i], i, reduced),
        ],
      ),
    );
  }

  Widget _word(String word, int i, bool reduced) {
    Widget w = Text(word, style: style);
    if (highlight.contains(i)) {
      w = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) =>
            const LinearGradient(colors: [_cyan, _violet]).createShader(rect),
        child: w,
      );
    }
    if (reduced) return w;
    return w
        .animate(delay: (160 + i * 75).ms)
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.4,
          end: 0,
          duration: 750.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ---------------------------------------------------------------------------
// Hero orbit (replaces the portrait)
// ---------------------------------------------------------------------------

class _Orbiter {
  final double radius;
  final double diameter;
  final double turns;
  final double phase;

  const _Orbiter(this.radius, this.diameter, this.turns, this.phase);
}

/// Positions each child on a circle. Only [paintChildren] runs per frame, so
/// there is no rebuild and no relayout while the logos orbit.
class _OrbitDelegate extends FlowDelegate {
  final Animation<double> animation;
  final double size;
  final List<_Orbiter> orbiters;

  _OrbitDelegate({
    required this.animation,
    required this.size,
    required this.orbiters,
  }) : super(repaint: animation);

  @override
  Size getSize(BoxConstraints constraints) => Size.square(size);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(Size.square(orbiters[i].diameter));

  @override
  void paintChildren(FlowPaintingContext context) {
    final c = size / 2;
    final t = animation.value;
    for (var i = 0; i < orbiters.length; i++) {
      final o = orbiters[i];
      final angle = 2 * math.pi * (o.phase + t * o.turns);
      context.paintChild(
        i,
        transform: Matrix4.translationValues(
          c + o.radius * math.cos(angle) - o.diameter / 2,
          c + o.radius * math.sin(angle) - o.diameter / 2,
          0,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitDelegate oldDelegate) => oldDelegate.size != size;
}

/// Technology logos orbiting a glowing core.
class HeroOrbit extends StatefulWidget {
  final double size;

  const HeroOrbit({super.key, required this.size});

  @override
  State<HeroOrbit> createState() => _HeroOrbitState();
}

class _HeroOrbitState extends State<HeroOrbit>
    with SingleTickerProviderStateMixin, AmbientAware<HeroOrbit> {
  // One 60s controller drives every orbiting element. All cycles below are
  // whole numbers per 60s so the loop is seamless.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  static const _inner = [
    'flutter-svgrepo-com.svg',
    'react-svgrepo-com.svg',
    'kotlin-1-logo-svgrepo-com.svg',
  ];
  static const _outer = [
    'android-svgrepo-com.svg',
    'swift-svgrepo-com.svg',
    'js-svgrepo-com.svg',
    'tailwind-svgrepo-com.svg',
    'figma-svgrepo-com.svg',
    'next-js-svgrepo-com.svg',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void onActiveChanged(bool active) => _syncAnimation();

  void _syncAnimation() {
    if (_reduced(context) || !isActive) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bubble(String asset, double diameter, Color accent) {
    return RepaintBoundary(
      child: Container(
        width: diameter,
        height: diameter,
        padding: EdgeInsets.all(diameter * 0.24),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF2F6FC),
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
        ),
        child: SvgPicture.asset('assets/svg/skill/$asset'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final reduced = _reduced(context);
    final innerD = s * 0.15;
    final outerD = s * 0.13;
    final coreD = s * 0.25;

    final orbiters = <_Orbiter>[
      for (var i = 0; i < _inner.length; i++)
        _Orbiter(s * 0.30, innerD, 3, i / _inner.length),
      for (var i = 0; i < _outer.length; i++)
        _Orbiter(s * 0.42, outerD, -2, i / _outer.length),
    ];

    final core = RepaintBoundary(
      child: Container(
        width: coreD,
        height: coreD,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_cyan, _violet],
          ),
          boxShadow: [
            BoxShadow(color: _cyan.withValues(alpha: 0.4), blurRadius: 36),
          ],
        ),
        child: Text(
          'K.',
          style: TextStyle(
            color: _base,
            fontSize: s * 0.095,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                size: Size.square(s),
                painter: const _RingsPainter([0.30, 0.42]),
              ),
            ),
            if (!reduced)
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(s),
                  painter: _RipplePainter(_controller, coreD / 2),
                ),
              ),
            reduced
                ? core
                : AnimatedBuilder(
                    animation: _controller,
                    child: core,
                    builder: (context, child) {
                      // 15 pulses per 60s => one every 4s.
                      final pulse =
                          1 +
                          0.035 *
                              (1 + math.sin(_controller.value * 30 * math.pi));
                      return Transform.scale(scale: pulse, child: child);
                    },
                  ),
            Flow(
              delegate: _OrbitDelegate(
                animation: _controller,
                size: s,
                orbiters: orbiters,
              ),
              children: [
                for (var i = 0; i < _inner.length; i++)
                  _bubble(_inner[i], innerD, _cyan),
                for (var i = 0; i < _outer.length; i++)
                  _bubble(_outer[i], outerD, _violet),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final List<double> radii;

  const _RingsPainter(this.radii);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [_cyan.withValues(alpha: 0.07), _cyan.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.5)),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.11);
    for (final r in radii) {
      canvas.drawCircle(c, size.width * r, stroke);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) => false;
}

/// Two rings expanding from the core, drawn in a single painter pass.
class _RipplePainter extends CustomPainter {
  final Animation<double> t;
  final double coreRadius;

  _RipplePainter(this.t, this.coreRadius) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (final offset in const [0.0, 0.5]) {
      final p = (t.value * 15 + offset) % 1.0;
      canvas.drawCircle(
        c,
        coreRadius * (1 + 2.6 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _cyan.withValues(alpha: 0.5 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Tech marquee
// ---------------------------------------------------------------------------

/// Endlessly scrolling strip of technology pills. The row is built once and
/// only translated each frame (no list layout, no shader mask).
class TechMarquee extends StatefulWidget {
  const TechMarquee({super.key});

  @override
  State<TechMarquee> createState() => _TechMarqueeState();
}

class _TechMarqueeState extends State<TechMarquee>
    with SingleTickerProviderStateMixin, AmbientAware<TechMarquee> {
  static const _items = [
    ('Flutter', 'flutter-svgrepo-com.svg'),
    ('Android', 'android-svgrepo-com.svg'),
    ('iOS', 'ios-svgrepo-com.svg'),
    ('React', 'react-svgrepo-com.svg'),
    ('Next.js', 'next-js-svgrepo-com.svg'),
    ('JavaScript', 'js-svgrepo-com.svg'),
    ('Kotlin', 'kotlin-1-logo-svgrepo-com.svg'),
    ('Swift', 'swift-svgrepo-com.svg'),
    ('Tailwind', 'tailwind-svgrepo-com.svg'),
    ('Figma', 'figma-svgrepo-com.svg'),
    ('MySQL', 'mysql-logo-svgrepo-com.svg'),
    ('Sentry', 'sentry-svgrepo-com.svg'),
  ];

  static const _pillWidth = 150.0;
  static const _gap = 12.0;
  static const _stride = _pillWidth + _gap;
  static const _setWidth = _stride * 12;
  static const _pxPerSecond = 42.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_setWidth / _pxPerSecond * 1000).round()),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void onActiveChanged(bool active) => _syncAnimation();

  void _syncAnimation() {
    if (_reduced(context) || !isActive) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _pill((String, String) item) {
    return Padding(
      padding: const EdgeInsets.only(right: _gap),
      child: Container(
        width: _pillWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF2F6FC),
              ),
              child: SvgPicture.asset('assets/svg/skill/${item.$2}'),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                item.$1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _edge({required bool left}) {
    return Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: 0,
      bottom: 0,
      width: 56,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: left ? Alignment.centerLeft : Alignment.centerRight,
              end: left ? Alignment.centerRight : Alignment.centerLeft,
              colors: [_base, _base.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final row = RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var copy = 0; copy < 2; copy++)
            for (final item in _items) _pill(item),
        ],
      ),
    );
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: AnimatedBuilder(
                  animation: _controller,
                  child: row,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(-_controller.value * _setWidth, 0),
                    child: child,
                  ),
                ),
              ),
            ),
            _edge(left: true),
            _edge(left: false),
          ],
        ),
      ),
    );
  }
}
