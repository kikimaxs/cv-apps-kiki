import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Hover/touch treatment shared by homepage surfaces, in the spirit of the
/// "Spotlight Card" and "Tilt Card" components: the card lifts, tilts towards
/// the pointer and a soft light follows it across the surface.
class HomeHoverLift extends StatefulWidget {
  final Widget child;
  final Color glow;
  final BorderRadius borderRadius;

  const HomeHoverLift({
    super.key,
    required this.child,
    required this.glow,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<HomeHoverLift> createState() => _HomeHoverLiftState();
}

class _HomeHoverLiftState extends State<HomeHoverLift> {
  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);
  bool _hovered = false;

  Size? _boxSize;

  void _update(PointerEvent event) {
    // Reading the size is only allowed outside build, i.e. in event handlers.
    _boxSize = context.size;
    _pointer.value = event.localPosition;
  }

  void _clear() => _pointer.value = null;

  @override
  void dispose() {
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() => _hovered = false);
        _clear();
      },
      child: Listener(
        onPointerHover: _update,
        onPointerMove: _update,
        onPointerDown: _update,
        onPointerUp: (event) {
          if (event.kind != PointerDeviceKind.mouse) _clear();
        },
        onPointerCancel: (_) => _clear(),
        child: AnimatedSlide(
          duration: duration,
          curve: Curves.easeOutCubic,
          offset: _hovered ? const Offset(0, -0.018) : Offset.zero,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.glow.withValues(alpha: 0.17),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : [],
            ),
            child: ValueListenableBuilder<Offset?>(
              valueListenable: _pointer,
              child: widget.child,
              builder: (context, pointer, child) {
                final size = _boxSize;
                var tilt = Offset.zero;
                if (!reduced &&
                    pointer != null &&
                    size != null &&
                    !size.isEmpty) {
                  tilt = Offset(
                    (pointer.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
                    (pointer.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
                  );
                }
                return TweenAnimationBuilder<Offset>(
                  tween: Tween<Offset>(end: tilt),
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: child,
                  builder: (context, t, child) => Transform(
                    alignment: Alignment.center,
                    // Identity at rest: no extra compositing layer per card.
                    transform: t == Offset.zero
                        ? Matrix4.identity()
                        : (Matrix4.identity()
                            ..setEntry(3, 2, 0.0011)
                            ..rotateX(-t.dy * 0.045)
                            ..rotateY(t.dx * 0.045)),
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        child!,
                        if (pointer != null && !reduced)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: widget.borderRadius,
                                child: CustomPaint(
                                  painter: _SpotlightPainter(
                                    pointer,
                                    widget.glow,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset position;
  final Color color;

  _SpotlightPainter(this.position, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 230.0;
    canvas.drawCircle(
      position,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: position, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.color != color;
}
