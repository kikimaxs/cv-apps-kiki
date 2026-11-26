import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Loading dots: three dots that pulse one after another. It is one
/// animation, cheap to paint, and it reads well on dark and light pages.
class AppLoader extends StatefulWidget {
  const AppLoader({
    super.key,
    this.color = const Color(0xFF67D4FF),
    this.size = 7,
  });

  final Color color;
  final double size;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.size * 0.45),
                  child: _Dot(
                    color: widget.color,
                    size: widget.size,
                    // Each dot is a little behind the one before it.
                    phase: (_controller.value - i * 0.16) % 1.0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, required this.phase});

  final Color color;
  final double size;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final wave = (math.sin(2 * math.pi * phase) + 1) / 2; // 0..1
    return Opacity(
      opacity: 0.25 + 0.75 * wave,
      child: Transform.scale(
        scale: 0.75 + 0.35 * wave,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
