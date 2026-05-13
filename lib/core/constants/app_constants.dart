// lib/core/constants/app_constants.dart

import 'package:flutter/material.dart';

// ─────────────────────────────────────────
//  ROUTE NAMES
// ─────────────────────────────────────────
abstract class AppRoutes {
  // Auth / Onboarding
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // Main Shell
  static const String home = '/home';
  static const String localizador = '/localizador';
  static const String scanner = '/scanner';
  static const String leaderboard = '/leaderboard';
  static const String perfil = '/perfil';

  // Home sub-routes
  static const String recompensas = '/home/recompensas';

  // Localizador sub-routes
  static const String oscarDetail = '/localizador/detalle';

  // Scanner sub-routes
  static const String sesionActiva = '/scanner/sesion';
  static const String jackpot = '/scanner/jackpot';
  static const String resumenSesion = '/scanner/resumen';

  // Leaderboard sub-routes
  static const String badges = '/leaderboard/badges';

  // Perfil sub-routes
  static const String recompensasPerfil = '/perfil/recompensas';
  static const String historial = '/perfil/historial';
  static const String configuracion = '/perfil/configuracion';
  static const String metricas = '/perfil/metricas';
}

// ─────────────────────────────────────────
//  COLOR PALETTE
// ─────────────────────────────────────────
abstract class AppColors {
  // Brand Greens
  static const Color primary = Color(0xFF00C853);
  static const Color primaryDark = Color(0xFF009624);
  static const Color primaryLight = Color(0xFF5EFC82);
  static const Color primarySurface = Color(0xFFE8F5E9);

  // Neutrals
  static const Color backgroundLight = Color(0xFFF7FAF8);
  static const Color backgroundDark = Color(0xFF0D1B12);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A2E20);

  // Text
  static const Color textPrimary = Color(0xFF0D1B12);
  static const Color textSecondary = Color(0xFF4A6355);
  static const Color textDisabled = Color(0xFFA8BEB4);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Accents
  static const Color accentAmber = Color(0xFFFFC107);
  static const Color accentTeal = Color(0xFF00BCD4);
  static const Color accentPurple = Color(0xFF7C4DFF);

  // Semantic
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFD50000);
  static const Color info = Color(0xFF0091EA);

  // Nav Bar
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navSelected = Color(0xFF00C853);
  static const Color navUnselected = Color(0xFFA8BEB4);
  static const Color navFabGradientStart = Color(0xFF00C853);
  static const Color navFabGradientEnd = Color(0xFF009624);
  static const Color navNotch = Color(0xFFF7FAF8);
}

// ─────────────────────────────────────────
//  DIMENSIONS
// ─────────────────────────────────────────
abstract class AppDimens {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // Nav Bar
  static const double navBarHeight = 64.0;
  static const double navFabSize = 62.0;
  static const double navFabElevation = 6.0;
  static const double navNotchMargin = 8.0;
  static const double navIconSize = 24.0;
  static const double navLabelFontSize = 10.5;

  // Shadows
  static const double shadowBlurSm = 8.0;
  static const double shadowBlurMd = 16.0;
  static const double shadowBlurLg = 32.0;
}

// ─────────────────────────────────────────
//  DURATIONS
// ─────────────────────────────────────────
abstract class AppDurations {
  static const Duration xsFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration xsSlow = Duration(milliseconds: 800);
}

// ─────────────────────────────────────────
//  STRINGS
// ─────────────────────────────────────────
abstract class AppStrings {
  static const String appName = 'Oscar';
  static const String appTagline = 'Recicla. Gana. Impacta.';

  // Nav Labels
  static const String navHome = 'Inicio';
  static const String navLocalizador = 'Localizador';
  static const String navScanner = 'Escanear';
  static const String navLeaderboard = 'Ranking';
  static const String navPerfil = 'Perfil';
}
