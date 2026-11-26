import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cv_apps/src/components/app_loader_overlay.dart';

/// Shows a page once its images are in the cache and its first frames have
/// painted. [assets] are decoded before the page is released, so the first
/// view already has its pictures. Each asset that cannot be loaded is simply
/// skipped, and [timeout] releases the page even on a very slow connection.
class AppPreloadGate extends StatefulWidget {
  const AppPreloadGate({
    super.key,
    required this.assets,
    required this.background,
    required this.child,
    this.timeout = const Duration(seconds: 8),
  });

  final List<String> assets;
  final Color background;
  final Widget child;
  final Duration timeout;

  @override
  State<AppPreloadGate> createState() => _AppPreloadGateState();
}

class _AppPreloadGateState extends State<AppPreloadGate> {
  bool _done = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(widget.timeout, _finish);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final loads = [for (final path in widget.assets) _warm(path)];
    await Future.wait(loads);
    if (!mounted) return;
    // Two frames: the page is laid out, and its first animations have painted.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    _finish();
  }

  /// Decodes an image into the image cache, or fetches an SVG into the asset
  /// cache. A failure is ignored: that asset loads later, when it is shown.
  Future<void> _warm(String path) {
    if (path.endsWith('.svg')) {
      return rootBundle.load(path).then<void>((_) {}, onError: (Object _) {});
    }
    return precacheImage(AssetImage(path), context).catchError((Object _) {});
  }

  void _finish() {
    _timeout?.cancel();
    if (_done || !mounted) return;
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AppLoaderOverlay(done: _done, background: widget.background),
      ],
    );
  }
}
