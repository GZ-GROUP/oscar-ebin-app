// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/loading_overlay.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: auth.isLoading,
          message: 'Iniciando sesión...',
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // ── Logo / Brand ─────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.recycling_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // ── Email Sign In ───────────────────────────────────────────
                _EmailLoginForm(auth: auth, authNotifier: authNotifier),
                const SizedBox(height: AppDimens.md),
                TextButton(
                  onPressed: () => context.go(AppRoutes.onboarding),
                  child: const Text('Crear cuenta / Registrarme'),
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  'Al continuar, aceptas nuestros Términos y Política de Privacidad',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailLoginForm extends StatefulWidget {
  final dynamic auth;
  final dynamic authNotifier;
  const _EmailLoginForm({required this.auth, required this.authNotifier});

  @override
  State<_EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends State<_EmailLoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
        ),
        const SizedBox(height: AppDimens.sm),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Contraseña'),
        ),
        const SizedBox(height: AppDimens.md),
        ElevatedButton(
          onPressed: widget.auth.isLoading
              ? null
              : () async {
                  final ok = await widget.authNotifier
                      .login(_emailCtrl.text.trim(), _passCtrl.text);
                  if (ok) {
                    if (mounted) context.go(AppRoutes.home);
                  } else {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(widget.auth.error ??
                                'Error al iniciar sesión')),
                      );
                  }
                },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Iniciar sesión'),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text('Olvidé mi contraseña', style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
