import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

// ---------------------------------------------------------------------------
// Motion building blocks for the portfolio v2 page, ported from the ideas in
// 21st.dev's "Daytake" landing (GSAP scroll scenes) without GSAP:
//
// - ScrollFx: a scroll-linked transform. It never rebuilds or relays out: the
//   render object listens to the page's scroll, repaints, and computes the
//   transform from where it sits on screen. Off screen it stops repainting.
// - InView: a one-shot animation that starts when its child scrolls into view
//   (slide reveals for text, split headlines, the contact wire).
// - LazyPic: an image that is only decoded once it is near the screen, at the
//   size it is shown. It is drawn at once, never faded.
//
// With "reduce motion" on, reveals show at once and nothing loops.
// ---------------------------------------------------------------------------

/// What every effect below reads: the page's scroll and whether to stay calm.
class V2Scope extends InheritedWidget {
  const V2Scope({
    super.key,
    required this.scroll,
    required this.calm,
    required super.child,
  });

  final ScrollController scroll;
  final bool calm;

  static V2Scope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<V2Scope>()!;

  @override
  bool updateShouldNotify(V2Scope old) =>
      old.scroll != scroll || old.calm != calm;
}

/// Progress of [t] between [a] and [b], clamped to 0..1.
double v2Seg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

double v2Ease(double x) => Curves.easeOutCubic.transform(x.clamp(0.0, 1.0));

double v2Lerp(double a, double b, double t) => a + (b - a) * t;

/// [m] applied around the point ([ax], [ay]) of a box of [size] (0..1 each).
Matrix4 v2About(Size size, Matrix4 m, {double ax = 0.5, double ay = 0.5}) {
  final x = size.width * ax;
  final y = size.height * ay;
  return Matrix4.translationValues(x, y, 0)
    ..multiply(m)
    ..multiply(Matrix4.translationValues(-x, -y, 0));
}

/// Builds the transform for scroll progress [t]: 0 when the box's top meets
/// the bottom of the screen, 1 when its bottom leaves the top.
typedef ScrollFxBuilder = Matrix4 Function(double t, Size size);

class ScrollFx extends SingleChildRenderObjectWidget {
  // The child is cached in its own layer. A scroll step then only moves that
  // layer; the pictures and shadows inside are not drawn again each frame.
  ScrollFx({super.key, required this.fx, Widget? child})
    : super(child: child == null ? null : RepaintBoundary(child: child));

  final ScrollFxBuilder fx;

  @override
  RenderScrollFx createRenderObject(BuildContext context) => RenderScrollFx(
    V2Scope.of(context).scroll,
    fx,
    MediaQuery.sizeOf(context).height,
  );

  @override
  void updateRenderObject(BuildContext context, RenderScrollFx renderObject) {
    renderObject
      ..listenable = V2Scope.of(context).scroll
      ..fx = fx
      ..viewportH = MediaQuery.sizeOf(context).height;
  }
}

class RenderScrollFx extends RenderProxyBox {
  RenderScrollFx(this._listenable, this._fx, this._vh);

  Listenable _listenable;
  set listenable(Listenable value) {
    if (identical(value, _listenable)) return;
    if (attached) {
      _listenable.removeListener(_onScroll);
      value.addListener(_onScroll);
    }
    _listenable = value;
    markNeedsPaint();
  }

  ScrollFxBuilder _fx;
  set fx(ScrollFxBuilder value) {
    _fx = value;
    markNeedsPaint();
  }

  double _vh;
  set viewportH(double value) {
    if (value == _vh) return;
    _vh = value;
    markNeedsPaint();
  }

  Matrix4 _m = Matrix4.identity();
  bool _onScreen = true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _listenable.addListener(_onScroll);
  }

  @override
  void detach() {
    _listenable.removeListener(_onScroll);
    super.detach();
  }

  double _progress() {
    final top = localToGlobal(Offset.zero).dy;
    return (_vh - top) / (_vh + size.height);
  }

  void _onScroll() {
    if (!attached || !hasSize) return;
    final t = _progress();
    final on = t > -0.1 && t < 1.1;
    // Repaint while on screen, and once more when it leaves.
    if (on || _onScreen) markNeedsPaint();
    _onScreen = on;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    _m = _fx(_progress().clamp(-0.2, 1.2), size);
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _m,
      super.paint,
      oldLayer: layer is TransformLayer ? layer as TransformLayer : null,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: _m,
      position: position,
      hitTest: (r, p) => super.hitTestChildren(r, position: p),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_m);
  }
}

/// Calls [onNear] on scroll (and after the first frame) with the widget's
/// top on screen and its height, until [onNear] returns true.
mixin _NearWatch<T extends StatefulWidget> on State<T> {
  ScrollController? _watched;
  bool _done = false;
  double vh = 800;

  bool onNear(double top, double height);

  void watch() {
    final scope = V2Scope.of(context);
    vh = MediaQuery.sizeOf(context).height;
    if (_done || identical(_watched, scope.scroll)) return;
    _watched?.removeListener(_check);
    _watched = scope.scroll..addListener(_check);
    SchedulerBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_done || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    if (onNear(box.localToGlobal(Offset.zero).dy, box.size.height)) {
      _done = true;
      _watched?.removeListener(_check);
    }
  }

  void unwatch() => _watched?.removeListener(_check);
}

/// A one-shot animation (0 to 1) that starts when the child's top passes
/// [at] of the screen height. [delay] is part of the same controller, so no
/// timers are left behind.
class InView extends StatefulWidget {
  const InView({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
    this.delay = Duration.zero,
    this.at = 0.9,
    this.child,
  });

  final Widget Function(
    BuildContext context,
    Animation<double> a,
    Widget? child,
  )
  builder;
  final Duration duration;
  final Duration delay;
  final double at;
  final Widget? child;

  @override
  State<InView> createState() => _InViewState();
}

class _InViewState extends State<InView>
    with SingleTickerProviderStateMixin, _NearWatch<InView> {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration + widget.delay,
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMicroseconds /
          (widget.duration + widget.delay).inMicroseconds,
      1,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (V2Scope.of(context).calm) {
      _c.value = 1;
      unwatch();
      return;
    }
    watch();
  }

  @override
  bool onNear(double top, double height) {
    if (top < vh * widget.at && top + height > 0) {
      _c.forward();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    unwatch();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _a, widget.child);
}

/// Slides the child in from ([dx], [dy]) and grows it from [scale] to full
/// size. No fade: an opacity change on a picture is what reads as a blink.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = 0,
    this.dx = 0,
    this.dy = 28,
    this.scale = 1,
    this.ms = 900,
    this.motion = true,
  });

  final Widget child;
  final int delay;
  final double dx;
  final double dy;
  final double scale;
  final int ms;

  /// False for pictures: they appear in place, with no entrance movement.
  final bool motion;

  @override
  Widget build(BuildContext context) {
    if (!motion) return child;
    return InView(
      delay: Duration(milliseconds: delay),
      duration: Duration(milliseconds: ms),
      child: child,
      builder: (context, a, child) => AnimatedBuilder(
        animation: a,
        child: child,
        builder: (context, child) {
          final v = Curves.easeOutQuart.transform(a.value);
          if (v >= 1) return child!;
          final s = v2Lerp(scale, 1, v);
          // Moves and grows into place; no fade, so pictures never change
          // opacity while they appear.
          return Transform(
            transform: Matrix4.translationValues(dx * (1 - v), dy * (1 - v), 0)
              ..scaleByDouble(s, s, 1, 1),
            alignment: Alignment.center,
            child: child,
          );
        },
      ),
    );
  }
}

/// A headline whose words rise out of a clip one after another.
/// [words] are (word, colour); a line break follows each index in [breaks].
/// The size a headline can use: [base], or smaller so that its widest word
/// fits [maxWidth] on one line. Every line of the headline shares that size,
/// so a long name never breaks in the middle and the type stays consistent.
double fitHeadlineSize(
  List<String> words,
  TextStyle style,
  double maxWidth,
  double base,
) {
  if (!maxWidth.isFinite || maxWidth <= 0 || words.isEmpty) return base;
  final room = maxWidth * 0.98;
  var widest = 0.0;
  for (final word in words) {
    final painter = TextPainter(
      text: TextSpan(
        text: word,
        style: style.copyWith(
          fontSize: base,
          fontFamily: style.fontFamily ?? 'Carlito',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    widest = math.max(widest, painter.width);
    painter.dispose();
  }
  if (widest <= room || widest == 0) return base;
  return base * room / widest;
}

class SplitWords extends StatelessWidget {
  const SplitWords({
    super.key,
    required this.words,
    required this.style,
    this.breaks = const {},
    this.align = WrapAlignment.start,
  });

  final List<(String, Color)> words;
  final TextStyle style;
  final Set<int> breaks;
  final WrapAlignment align;

  @override
  Widget build(BuildContext context) {
    final n = words.length;
    return LayoutBuilder(
      builder: (context, c) {
        final size = fitHeadlineSize(
          [for (final w in words) w.$1],
          style,
          c.maxWidth,
          style.fontSize ?? 32,
        );
        final fitted = style.copyWith(fontSize: size);
        return Semantics(
          header: true,
          label: words.map((w) => w.$1).join(' '),
          child: ExcludeSemantics(
            child: InView(
              duration: Duration(milliseconds: 700 + 70 * n),
              builder: (context, a, _) => AnimatedBuilder(
                animation: a,
                builder: (context, _) {
                  final children = <Widget>[];
                  for (var i = 0; i < n; i++) {
                    final start = n == 1 ? 0.0 : i / n * 0.45;
                    final v = v2Ease(v2Seg(a.value, start, start + 0.55));
                    children.add(
                      ClipRect(
                        child: Transform.translate(
                          offset: Offset(0, (1 - v) * size * 1.15),
                          child: Text(
                            words[i].$1,
                            maxLines: 1,
                            softWrap: false,
                            style: fitted.copyWith(color: words[i].$2),
                          ),
                        ),
                      ),
                    );
                    if (breaks.contains(i)) {
                      children.add(const SizedBox(width: double.infinity));
                    }
                  }
                  return Wrap(
                    alignment: align,
                    spacing: size * 0.24,
                    children: children,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// An asset image decoded only when it comes within about two screens of
/// view, at [logicalWidth] (if known), fading in over [placeholder].
class LazyPic extends StatefulWidget {
  const LazyPic(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.logicalWidth,
    this.placeholder = Colors.transparent,
    this.label,
  });

  final String path;
  final BoxFit fit;
  final Alignment alignment;
  final double? logicalWidth;
  final Color placeholder;
  final String? label;

  @override
  State<LazyPic> createState() => _LazyPicState();
}

/// Pictures that appeared after their first frame had to be decoded, so they
/// appeared after their first frame had to be decoded. Counted for the
/// performance test; it should stay at zero once the page shows its pictures
/// from the cache.
@visibleForTesting
int pictureFadeIns = 0;

class _LazyPicState extends State<LazyPic> with _NearWatch<LazyPic> {
  bool _show = false;
  bool _faded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    watch();
  }

  @override
  bool onNear(double top, double height) {
    if (top < vh * 2.2 && top + height > -vh * 1.5) {
      setState(() => _show = true);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    unwatch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.placeholder,
      child: !_show
          ? const SizedBox.expand()
          : Image.asset(
              widget.path,
              fit: widget.fit,
              alignment: widget.alignment,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.medium,
              // Keep showing the last frame while a new one loads: no blank
              // flash when the picture is decoded again.
              gaplessPlayback: true,
              semanticLabel: widget.label,
              excludeFromSemantics: widget.label == null,
              // Pictures are drawn at once, never faded. The page decodes and
              // draws them before it shows, so nothing appears on screen late.
              frameBuilder: (context, child, frame, sync) {
                // Counted only: a picture that was not decoded in time.
                if (!sync && frame != null && !_faded) {
                  _faded = true;
                  pictureFadeIns++;
                }
                return child;
              },
            ),
    );
  }
}
