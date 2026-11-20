import 'package:flutter/material.dart';
import 'package:cv_apps/src/routes/app_router.dart';
import 'package:cv_apps/src/utils/app_language.dart';
import 'package:cv_apps/src/utils/webview_setup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupWebView();
  setupRouterLocator();
  runApp(withRouterProvider(child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLanguage.scope(
      child: MaterialApp.router(routerConfig: AppRouter.router),
    );
  }
}
