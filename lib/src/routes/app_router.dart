import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:cv_apps/src/modules/home/home_main.dart';
import 'package:cv_apps/src/modules/my_cv/views/my_cv_view.dart';
import 'package:cv_apps/src/modules/my_portofolio/views/my_portofolio_view.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeMain(),
      ),
      GoRoute(
        path: '/my_cv',
        name: 'my_cv',
        builder: (context, state) => const MyCvView(),
      ),
      GoRoute(
        path: '/my_portofolio',
        name: 'my_portofolio',
        builder: (context, state) => const MyPortofolioView(),
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
