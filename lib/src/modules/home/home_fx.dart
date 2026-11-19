import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
/// Endless "ambient" animations (aurora, orbit, autoplay, pulses) only
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
// * Static layers (grid, rings) sit in their own RepaintBoundary
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
// Hero orbit: a toy the visitor plays with. Nothing moves on its own except
// a short welcome spin; every other motion comes from a drag, fling or tap,
// then eases to a full stop and the ticker switches off.
// ---------------------------------------------------------------------------

class _Tech {
  final String name;
  final String asset;

  const _Tech(this.name, this.asset);
}

const _innerTech = [
  _Tech('Flutter', 'flutter-svgrepo-com.svg'),
  _Tech('React', 'react-svgrepo-com.svg'),
  _Tech('Kotlin', 'kotlin-1-logo-svgrepo-com.svg'),
];

const _outerTech = [
  _Tech('Android', 'android-svgrepo-com.svg'),
  _Tech('Swift', 'swift-svgrepo-com.svg'),
  _Tech('JavaScript', 'js-svgrepo-com.svg'),
  _Tech('Tailwind', 'tailwind-svgrepo-com.svg'),
  _Tech('Figma', 'figma-svgrepo-com.svg'),
  _Tech('Next.js', 'next-js-svgrepo-com.svg'),
];

class _Ripple {
  final Offset center;
  final double startRadius;
  final Color color;
  double progress = 0;

  _Ripple(this.center, this.startRadius, this.color);
}

/// Everything that moves in the orbit. Advanced by one ticker that only runs
/// while something is still moving ([settled] is false).
class _OrbitMotion extends ChangeNotifier {
  /// Exponential spin-down per second: a hard fling glides ~2s, then stops.
  static const friction = 1.8;
  static const maxSpeed = 16.0; // rad/s
  static const restSpeed = 0.04; // rad/s, imperceptible, so stopping is smooth
  static const popSeconds = 0.6;
  static const rippleSeconds = 0.85;

  double angle = 0;
  double velocity = 0;
  bool dragging = false;

  double corePop = 1; // 0..1, 1 = at rest
  int? poppedLogo;
  double logoPop = 1;
  final ripples = <_Ripple>[];

  /// 0..1 of the top speed; drives the rings' glow.
  double get speed => (velocity.abs() / maxSpeed).clamp(0.0, 1.0);

  bool get settled =>
      velocity == 0 && corePop >= 1 && logoPop >= 1 && ripples.isEmpty;

  double get spinDirection => velocity < 0 ? -1 : 1;

  void addSpin(double radPerSecond) {
    velocity = (velocity + radPerSecond).clamp(-maxSpeed, maxSpeed);
  }

  void step(double dt) {
    if (!dragging && velocity != 0) {
      // Exact solution of v' = -friction * v, so any frame length (even a
      // dropped frame) lands exactly where a smooth 120 Hz run would.
      final decay = math.exp(-friction * dt);
      angle += velocity * (1 - decay) / friction;
      velocity *= decay;
      if (velocity.abs() < restSpeed) velocity = 0;
    }
    if (corePop < 1) corePop = math.min(1, corePop + dt / popSeconds);
    if (logoPop < 1) logoPop = math.min(1, logoPop + dt / popSeconds);
    for (var i = ripples.length - 1; i >= 0; i--) {
      final r = ripples[i];
      r.progress += dt / rippleSeconds;
      if (r.progress >= 1) ripples.removeAt(i);
    }
    notifyListeners();
  }

  void changed() => notifyListeners();

  /// Squash-and-bounce: a quick press-in, overshoot, then rest at exactly 1.
  static double bounce(double p, double amount) =>
      p >= 1 ? 1 : 1 + amount * math.sin(p * 2.4 * math.pi) * (1 - p) * (1 - p);
}

class _Orbiter {
  final double radius;
  final double diameter;
  final double speedFactor;
  final double phase;

  const _Orbiter(this.radius, this.diameter, this.speedFactor, this.phase);

  Offset centerAt(double size, double angle) {
    final a = 2 * math.pi * phase + angle * speedFactor;
    return Offset(
      size / 2 + radius * math.cos(a),
      size / 2 + radius * math.sin(a),
    );
  }
}

/// Positions each logo on its ring. Only [paintChildren] runs per frame, so
/// spinning never rebuilds or relayouts. Flow also hit-tests children with
/// these transforms, so the moving logos stay tappable.
class _OrbitDelegate extends FlowDelegate {
  final _OrbitMotion motion;
  final double size;
  final List<_Orbiter> orbiters;

  _OrbitDelegate({
    required this.motion,
    required this.size,
    required this.orbiters,
  }) : super(repaint: motion);

  @override
  Size getSize(BoxConstraints constraints) => Size.square(size);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(Size.square(orbiters[i].diameter));

  @override
  void paintChildren(FlowPaintingContext context) {
    for (var i = 0; i < orbiters.length; i++) {
      final o = orbiters[i];
      final c = o.centerAt(size, motion.angle);
      final scale = i == motion.poppedLogo
          ? _OrbitMotion.bounce(motion.logoPop, 0.42)
          : 1.0;
      final half = o.diameter * scale / 2;
      context.paintChild(
        i,
        transform: Matrix4.translationValues(c.dx - half, c.dy - half, 0)
          ..scaleByDouble(scale, scale, 1, 1),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitDelegate oldDelegate) => oldDelegate.size != size;
}

/// Technology logos around a "K." core that the visitor can play with:
/// * drag (any direction with a mouse, sideways on touch) to turn it, and
///   let go to fling it; it glides and eases to a stop,
/// * tap the core or empty space to give it a spin (taps add up),
/// * tap a logo to make it pop and show its name in the core.
class HeroOrbit extends StatefulWidget {
  final double size;

  const HeroOrbit({super.key, required this.size});

  @override
  State<HeroOrbit> createState() => _HeroOrbitState();
}

class _HeroOrbitState extends State<HeroOrbit>
    with SingleTickerProviderStateMixin {
  static const _welcomeSpin = 4.5; // rad/s
  static const _tapSpin = 5.5; // rad/s per tap
  static const _logoNudge = 2.2;
  static const _nameShownFor = Duration(milliseconds: 1600);

  final _motion = _OrbitMotion();
  final _picked = ValueNotifier<_Tech?>(null);
  final _played = ValueNotifier<bool>(false);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  Timer? _nameTimer;
  bool _welcomed = false;

  bool get _reducedMotion => _reduced(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_welcomed) {
      _welcomed = true;
      // A short welcome spin hints that the orbit can move, then it rests.
      if (!_reducedMotion) {
        _motion.addSpin(_welcomeSpin);
        _wake();
      }
    }
  }

  @override
  void dispose() {
    _nameTimer?.cancel();
    _ticker.dispose();
    _motion.dispose();
    _picked.dispose();
    _played.dispose();
    super.dispose();
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
    // While dragging, velocity is 0 and the finger moves the orbit directly,
    // so this also stops the ticker mid-drag once pops/ripples are done.
    if (_motion.settled) _ticker.stop();
  }

  void _markPlayed() {
    if (!_played.value) _played.value = true;
  }

  Offset get _center => Offset(widget.size / 2, widget.size / 2);

  void _onPanStart(DragStartDetails details) {
    _markPlayed();
    _motion
      ..dragging = true
      ..velocity = 0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final now = details.localPosition - _center;
    final before = now - details.delta;
    // Too close to the centre the angle is unstable: ignore.
    final minR = widget.size * 0.1;
    if (now.distance < minR || before.distance < minR) return;
    var d = now.direction - before.direction;
    if (d > math.pi) d -= 2 * math.pi;
    if (d < -math.pi) d += 2 * math.pi;
    _motion
      ..angle += d
      ..changed();
  }

  void _onPanEnd(DragEndDetails details) {
    _motion.dragging = false;
    if (_reducedMotion) {
      _motion.velocity = 0;
      return;
    }
    // Angular velocity = tangential finger speed / radius.
    final r = details.localPosition - _center;
    final v = details.velocity.pixelsPerSecond;
    final r2 = math.max(r.distanceSquared, math.pow(widget.size * 0.2, 2));
    _motion.velocity = ((r.dx * v.dy - r.dy * v.dx) / r2).clamp(
      -_OrbitMotion.maxSpeed,
      _OrbitMotion.maxSpeed,
    );
    if (_motion.velocity.abs() < _OrbitMotion.restSpeed) _motion.velocity = 0;
    _wake();
  }

  void _onSpinTap() {
    _markPlayed();
    if (_reducedMotion) return;
    HapticFeedback.lightImpact();
    _motion
      ..addSpin(_tapSpin * _motion.spinDirection)
      ..corePop = 0
      ..ripples.add(_Ripple(_center, widget.size * 0.125, _cyan));
    if (_motion.ripples.length > 4) _motion.ripples.removeAt(0);
    _wake();
  }

  void _onLogoTap(int index, _Orbiter orbiter, _Tech tech, Color accent) {
    _markPlayed();
    HapticFeedback.selectionClick();
    _picked.value = tech;
    _nameTimer?.cancel();
    _nameTimer = Timer(_nameShownFor, () => _picked.value = null);
    if (_reducedMotion) return;
    _motion
      ..addSpin(_logoNudge * _motion.spinDirection)
      ..poppedLogo = index
      ..logoPop = 0
      ..corePop = 0
      ..ripples.add(
        _Ripple(
          orbiter.centerAt(widget.size, _motion.angle),
          orbiter.diameter / 2,
          accent,
        ),
      );
    if (_motion.ripples.length > 4) _motion.ripples.removeAt(0);
    _wake();
  }

  Widget _bubble(int index, _Orbiter orbiter, _Tech tech, Color accent) {
    return Semantics(
      button: true,
      label: tech.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onLogoTap(index, orbiter, tech, accent),
          child: RepaintBoundary(
            child: Container(
              padding: EdgeInsets.all(orbiter.diameter * 0.24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2F6FC),
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: SvgPicture.asset('assets/svg/skill/${tech.asset}'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _coreLabel(double s, double coreD) {
    return ValueListenableBuilder<_Tech?>(
      valueListenable: _picked,
      builder: (context, tech, _) {
        final label = tech == null
            ? Text(
                'K.',
                key: const ValueKey('K.'),
                style: TextStyle(
                  color: _base,
                  fontSize: s * 0.095,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              )
            : Padding(
                key: ValueKey(tech.name),
                padding: EdgeInsets.symmetric(horizontal: coreD * 0.12),
                child: FittedBox(
                  child: Text(
                    tech.name,
                    maxLines: 1,
                    style: TextStyle(
                      color: _base,
                      fontSize: s * 0.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
        if (_reducedMotion) return label;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: label,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final innerD = s * 0.15;
    final outerD = s * 0.13;
    final coreD = s * 0.25;

    // Outer ring follows the finger 1:1; the inner ring turns faster for a
    // bit of parallax.
    final orbiters = <_Orbiter>[
      for (var i = 0; i < _innerTech.length; i++)
        _Orbiter(s * 0.30, innerD, 1.5, i / _innerTech.length),
      for (var i = 0; i < _outerTech.length; i++)
        _Orbiter(s * 0.42, outerD, 1, i / _outerTech.length),
    ];

    final core = Semantics(
      button: true,
      label: 'Putar orbit',
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
        child: _coreLabel(s, coreD),
      ),
    );

    final toy = MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onSpinTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: () => _motion.dragging = false,
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(s),
                  painter: _RingsPainter(_motion, const [0.30, 0.42]),
                ),
              ),
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _motion,
                  child: core,
                  builder: (context, child) => Transform.scale(
                    scale: _OrbitMotion.bounce(_motion.corePop, -0.14),
                    child: child,
                  ),
                ),
              ),
              Flow(
                delegate: _OrbitDelegate(
                  motion: _motion,
                  size: s,
                  orbiters: orbiters,
                ),
                children: [
                  for (var i = 0; i < orbiters.length; i++)
                    _bubble(
                      i,
                      orbiters[i],
                      i < _innerTech.length
                          ? _innerTech[i]
                          : _outerTech[i - _innerTech.length],
                      i < _innerTech.length ? _cyan : _violet,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Hint under the toy; it fades out once the visitor has played (the
    // space stays reserved so nothing jumps).
    final hint = ValueListenableBuilder<bool>(
      valueListenable: _played,
      builder: (context, played, child) => AnimatedOpacity(
        opacity: played ? 0 : 1,
        duration: const Duration(milliseconds: 400),
        child: child,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.handPointer, size: 12, color: _cyan),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Geser untuk memutar · ketuk logonya',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF9FB3C8),
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [toy, const SizedBox(height: 12), hint],
      ),
    );
  }
}

/// Soft halo, the two rings and tap ripples in one pass. Repaints only while
/// the orbit is moving; the rings brighten with spin speed.
class _RingsPainter extends CustomPainter {
  final _OrbitMotion motion;
  final List<double> radii;

  _RingsPainter(this.motion, this.radii) : super(repaint: motion);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final speed = motion.speed;
    canvas.drawCircle(
      c,
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _cyan.withValues(alpha: 0.07 + 0.10 * speed),
            _cyan.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.5)),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 + speed
      ..color = Color.lerp(
        Colors.white.withValues(alpha: 0.11),
        _cyan.withValues(alpha: 0.55),
        speed,
      )!;
    for (final r in radii) {
      canvas.drawCircle(c, size.width * r, stroke);
    }
    for (final ripple in motion.ripples) {
      final p = Curves.easeOutCubic.transform(ripple.progress);
      canvas.drawCircle(
        ripple.center,
        ripple.startRadius * (1 + 1.6 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - p) + 0.5
          ..color = ripple.color.withValues(alpha: 0.6 * (1 - ripple.progress)),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) => false;
}
