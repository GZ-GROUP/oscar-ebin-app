// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final items1 = [
      _MenuItem(
          icon: Icons.card_giftcard_rounded,
          label: 'Recompensas',
          color: AppColors.accentAmber),
      _MenuItem(
          icon: Icons.history_rounded,
          label: 'Historial',
          color: AppColors.accentTeal),
      _MenuItem(
          icon: Icons.insights_rounded,
          label: 'Métricas personales',
          color: AppColors.accentPurple),
    ];

    final items2 = [
      _MenuItem(
          icon: Icons.person_outline_rounded,
          label: 'Información personal',
          color: AppColors.primary),
      _MenuItem(
          icon: Icons.settings_outlined,
          label: 'Configuración',
          color: AppColors.textSecondary),
      _MenuItem(
          icon: Icons.logout_rounded,
          label: 'Cerrar sesión',
          color: AppColors.error,
          onTap: () async {
            // Logout handled in tile via callback
          }),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppDimens.md,
          AppDimens.sm,
          AppDimens.md,
          AppDimens.navBarHeight + AppDimens.navFabSize / 2 + AppDimens.lg,
        ),
        children: [
          // ── Avatar + Name ───────────────────────────────────────────────
          _ProfileHeader(theme: theme),
          const SizedBox(height: AppDimens.lg),

          // ── Points Summary ───────────────────────────────────────────────
          _PointsSummary(theme: theme),
          const SizedBox(height: AppDimens.lg),

          // ── Menu Sections ────────────────────────────────────────────────
          _MenuSection(title: 'Mi actividad', items: items1),
          const SizedBox(height: AppDimens.md),
          _MenuSection(
              title: 'Cuenta',
              items: items2.map((it) {
                // attach logout callback to the logout item
                if (it.label == 'Cerrar sesión') {
                  return _MenuItem(
                      icon: it.icon,
                      label: it.label,
                      color: it.color,
                      onTap: () async {
                        final notifier = ref.read(authProvider.notifier);
                        await notifier.logout();
                        if (context.mounted) context.go(AppRoutes.onboarding);
                      });
                }
                return it;
              }).toList()),
        ],
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final ThemeData theme;
  const _ProfileHeader({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth.name?.trim();
    final displayName = (name?.isEmpty ?? true) ? 'Reciclador' : name!;
    String initials() {
      final parts = displayName
          .trim()
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) return 'R';
      if (parts.length == 1) return parts[0][0].toUpperCase();
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.accentAmber,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: theme.textTheme.headlineSmall),
              Text(
                'Reciclador Nivel 4 · Panamá',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Text(
                  '🌱 Eco Warrior',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PointsSummary extends StatelessWidget {
  final ThemeData theme;
  const _PointsSummary({required this.theme});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('1,240', 'Puntos\ntotales', Icons.stars_rounded),
      ('12', 'Sesiones\ncompletadas', Icons.recycling_rounded),
      ('3', 'Recompensas\ncanjeadas', Icons.card_giftcard_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Icon(s.$3, color: AppColors.primary, size: 22),
                const SizedBox(height: 4),
                Text(
                  s.$1,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  s.$2,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: const Color(0xFFE2ECE7)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _MenuTile(item: item),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: Icon(item.icon, color: item.color, size: 18),
      ),
      title: Text(item.label, style: theme.textTheme.titleSmall),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textDisabled,
        size: 20,
      ),
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: 2,
      ),
      minLeadingWidth: 0,
    );
  }
}
