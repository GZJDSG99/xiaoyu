import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/local_storage.dart';
import '../features/diy/pages/diy_page.dart';
import '../features/display/pages/fullscreen_display_page.dart';
import '../features/expression/pages/expression_category_page.dart';
import '../features/expression/pages/expression_detail_page.dart';
import '../features/home/pages/home_page.dart';
import '../features/pet/pages/pet_select_page.dart';
import '../features/settings/pages/background_select_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(localStorageProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isFirstLaunch = storage.isFirstLaunch;
      final goingToPetSelect = state.matchedLocation == '/pet-select';

      if (isFirstLaunch && !goingToPetSelect) {
        return '/pet-select?first=1';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/pet-select',
        name: 'petSelect',
        builder: (context, state) {
          final isFirst = state.uri.queryParameters['first'] == '1';
          return PetSelectPage(isFirstLaunch: isFirst);
        },
      ),
      GoRoute(
        path: '/backgrounds',
        name: 'backgrounds',
        builder: (context, state) => const BackgroundSelectPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expressions',
                name: 'expressions',
                builder: (context, state) => const ExpressionCategoryPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'expressionDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ExpressionDetailPage(expressionId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/diy',
                name: 'diy',
                builder: (context, state) => const DiyPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mine',
                name: 'mine',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/display',
        name: 'display',
        builder: (context, state) {
          final expressionId = state.uri.queryParameters['id'];
          final customText = state.uri.queryParameters['text'];
          return FullscreenDisplayPage(
            expressionId: expressionId,
            customText: customText,
          );
        },
      ),
    ],
    debugLogDiagnostics: kDebugMode,
  );
});
