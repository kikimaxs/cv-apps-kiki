import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cv_apps/src/components/app_loader.dart';

/// Covers a page until [done] is true, then lets it through.
///
/// The loader appears only if the wait is longer than [showAfter], so a fast
/// connection never shows it: the page is simply there when it is ready. A
/// loader that did appear fades away; a page that never showed one is
/// released at once.
class AppLoaderOverlay extends StatefulWidget {
  const AppLoaderOverlay({
    super.key,
    required this.done,
    required this.background,
    this.color = const Color(0xFF67D4FF),
    this.showAfter = const Duration(milliseconds: 250),
    this.fade = const Duration(milliseconds: 320),
  });

  final bool done;
  final Color background;
  final Color color;
  final Duration showAfter;
  final Duration fade;

  @override
  State<AppLoaderOverlay> createState() => _AppLoaderOverlayState();
}

class _AppLoaderOverlayState extends State<AppLoaderOverlay> {
  Timer? _timer;
  bool _showLoader = false;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(AppLoaderOverlay old) {
    super.didUpdateWidget(old);
    if (widget.done) _timer?.cancel();
  }

  void _arm() {
    if (widget.done) return;
    _timer = Timer(widget.showAfter, () {
      if (mounted && !widget.done) setState(() => _showLoader = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final released = widget.done;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: released,
        child: AnimatedOpacity(
          opacity: released ? 0 : 1,
          duration: released && !_showLoader ? Duration.zero : widget.fade,
          curve: Curves.easeOut,
          child: ColoredBox(
            color: widget.background,
            // The loader is built only once it is due, so a fast page never
            // starts its animation at all.
            child: Center(
              child: _showLoader
                  ? AppLoader(color: widget.color)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
