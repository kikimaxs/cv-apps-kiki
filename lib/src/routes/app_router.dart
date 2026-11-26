import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:cv_apps/src/components/app_preload_gate.dart';
import 'package:cv_apps/src/modules/home/home_main.dart';
import 'package:cv_apps/src/utils/preload_assets.dart';
import 'package:cv_apps/src/modules/my_cv/views/my_cv_view.dart';
import 'package:cv_apps/src/modules/my_portofolio/views/my_portofolio_view.dart';
import 'package:cv_apps/src/modules/my_portofolio/views/portfolio_v2_view.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const AppPreloadGate(
          assets: kHomePreloadAssets,
          background: Color(0xFF080D18),
          child: HomeMain(),
        ),
      ),
      GoRoute(
        path: '/my_cv',
        name: 'my_cv',
        builder: (context, state) => const AppPreloadGate(
          assets: kCvPreloadAssets,
          background: Color(0xFF0F172A),
          child: MyCvView(),
        ),
      ),
      GoRoute(
        path: '/my_portofolio',
        name: 'my_portofolio',
        builder: (context, state) => AppPreloadGate(
          assets: portfolioPreloadAssets(),
          background: const Color(0xFF0B1220),
          child: const MyPortofolioView(),
        ),
      ),
      GoRoute(
        path: '/my_portofolio_v2',
        name: 'my_portofolio_v2',
        builder: (context, state) => const PortfolioV2View(),
      ),
    ],
  );
}

final GetIt _getIt = GetIt.instance;

void setupRouterLocator() {
  if (!_getIt.isRegistered<GoRouter>()) {
    _getIt.registerLazySingleton<GoRouter>(() => AppRouter.router);
  }
}

Widget withRouterProvider({required Widget child}) {
  return Provider<GoRouter>.value(value: AppRouter.router, child: child);
}
