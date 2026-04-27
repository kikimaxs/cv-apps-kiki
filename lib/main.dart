import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cv_apps/src/routes/app_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }
  setupRouterLocator();
  runApp(withRouterProvider(child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: AppRouter.router);
  }
}
