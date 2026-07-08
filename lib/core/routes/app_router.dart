// lib/core/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../navigation/app_navigation.dart';

// Feature Screens
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/maps/presentation/screens/maps_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/metricas_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NAVIGATOR KEYS
// ─────────────────────────────────────────────────────────────────────────────
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// ─────────────────────────────────────────────────────────────────────────────
//  ROUTER PROVIDER
//  Exposed as a Riverpod provider so the router can access other providers
//  (e.g., auth state) for redirect logic.
// ─────────────────────────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  // TODO: Watch auth provider here for redirect logic
  // final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    // ── Redirect Logic ─────────────────────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == AppRoutes.login;
      final isGoingToOnboarding =
          state.matchedLocation == AppRoutes.onboarding ||
              state.matchedLocation?.startsWith(AppRoutes.onboarding) == true;

      if (authState.isLoading) return null; // wait until known

      if (!isLoggedIn && !isGoingToLogin && !isGoingToOnboarding) {
        return AppRoutes.onboarding;
      }
      if (isLoggedIn && (isGoingToLogin || isGoingToOnboarding))
        return AppRoutes.home;
      return null;
    },

    routes: [
      // ── Outside Shell (no nav bar) ───────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),

      GoRoute(
        path: '/onboarding/start',
        name: 'signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignupScreen(),
      ),

      // ── Métricas personales (full-screen, sin bottom nav) ────────────────
      GoRoute(
        path: AppRoutes.metricas,
        name: 'metricas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MetricasScreen(),
      ),

      // ── Main Shell (with nav bar) ────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationShell(child: child);
        },
        routes: [
          // ── HOME ──────────────────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) =>
                _fadeTransition(state: state, child: const HomeScreen()),
          ),

          // ── RECOMPENSAS (sub-ruta de Home) ───────────────────────────────
          GoRoute(
            path: AppRoutes.recompensas,
            name: 'recompensas',
            pageBuilder: (context, state) =>
                _fadeTransition(state: state, child: const RewardsScreen()),
          ),

          // ── LOCALIZADOR ───────────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.localizador,
            name: 'localizador',
            pageBuilder: (context, state) =>
                _fadeTransition(state: state, child: const MapsScreen()),
          ),

          // ── SCANNER ───────────────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.scanner,
            name: 'scanner',
            pageBuilder: (context, state) =>
                _slideUpTransition(state: state, child: const ScannerScreen()),
          ),

          // ── LEADERBOARD ───────────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.leaderboard,
            name: 'leaderboard',
            pageBuilder: (context, state) =>
                _fadeTransition(state: state, child: const LeaderboardScreen()),
          ),

          // ── PERFIL ────────────────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.perfil,
            name: 'perfil',
            pageBuilder: (context, state) =>
                _fadeTransition(state: state, child: const ProfileScreen()),
          ),
        ],
      ),
    ],

    // ── Error Handler ─────────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Ruta desconocida'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOM PAGE TRANSITIONS
// ─────────────────────────────────────────────────────────────────────────────
CustomTransitionPage<void> _fadeTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.normal,
    reverseTransitionDuration: AppDurations.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _slideUpTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.slow,
    reverseTransitionDuration: AppDurations.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}