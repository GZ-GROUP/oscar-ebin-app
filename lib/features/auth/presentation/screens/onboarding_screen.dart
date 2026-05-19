import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('Bienvenido a ${AppStrings.appName}',
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: AppDimens.md),
              Text(
                'Recicla, gana y transforma tu comunidad. Te guiaremos en unos pasos rápidos para crear tu cuenta.',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.onboarding + '/start'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Comenzar'),
                ),
              ),
              const SizedBox(height: AppDimens.md),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Ya tengo cuenta — Iniciar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
