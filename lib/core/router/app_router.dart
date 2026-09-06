import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/bottom_nav_shell.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/politics/presentation/screens/politics_screen.dart';
import '../../features/opinion/presentation/screens/opinion_screen.dart';
import '../../features/fineprint/presentation/screens/fineprint_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/article/presentation/screens/article_screen.dart';
import '../../features/article/presentation/screens/author_profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// App-wide router. A [StatefulShellRoute] keeps the 5 bottom-nav tabs
/// (Home / Politics / Opinion / Ground / Settings) alive with independent
/// navigation stacks — matching the persistent `<nav>` bar present on every
/// screen in the HTML mockups. Article detail is pushed full-screen on top
/// of the shell (it has its own back-arrow app bar, no bottom nav), just
/// like `article_view.html` stands apart from the tabbed screens.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BottomNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/politics',
                builder: (context, state) => const PoliticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/opinion',
                builder: (context, state) => const OpinionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ground-reports',
                builder: (context, state) => const FinePrintScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/article/:id',
        builder: (context, state) => ArticleScreen(
          articleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/author/:id',
        builder: (context, state) => AuthorProfileScreen(
          authorId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
});
