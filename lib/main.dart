// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/routes/app_router.dart';
import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializa los datos de formato de fecha en español
  // (requerido por DateFormat(..., 'es') en pantallas como Historial).
  await initializeDateFormatting('es', null);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    // ProviderScope is required for Riverpod — must wrap the entire app
    const ProviderScope(child: OscarApp()),
  );
}

class OscarApp extends ConsumerWidget {
  const OscarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // ── Themes ───────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light, // TODO: connect to settings provider
      // ── Router ───────────────────────────────────────────────────────────
      routerConfig: router,

      // ── Builder: MediaQuery text scaling clamp ───────────────────────────
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
