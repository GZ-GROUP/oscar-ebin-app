// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/data/profile_model.dart';
import '../../../profile/providers/profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final profileStats = ref.watch(profileStatsProvider);
    final displayName = auth.name ?? 'Reciclador';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¡Hola, $displayName! 👋',
                style: theme.textTheme.headlineSmall),
            Text(
              'Resumen de hoy',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: profileStats.when(
        data: (stats) {
          if (stats == null) {
            return const Center(child: Text('No hay datos de perfil'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.md,
              AppDimens.sm,
              AppDimens.md,
              // Bottom padding to avoid content behind the nav bar
              AppDimens.navBarHeight + AppDimens.navFabSize / 2 + AppDimens.lg,
            ),
            children: [
              // ── Puntos Card ─────────────────────────────────────────────────
              _EcoSummaryCard(theme: theme, stats: stats),
              const SizedBox(height: AppDimens.md),

              // ── Quick Actions ────────────────────────────────────────────────
              Text('Acciones rápidas', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppDimens.sm),
              _QuickActionsRow(theme: theme),
              const SizedBox(height: AppDimens.lg),

              // ── Actividad Reciente ───────────────────────────────────────────
              Text('Actividad reciente', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppDimens.sm),
              _RecentActivityPlaceholder(theme: theme),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }
}

class _EcoSummaryCard extends StatelessWidget {
  final ThemeData theme;
  final ProfileStats stats;
  const _EcoSummaryCard({required this.theme, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Calculate total trash weight (assuming each item is ~0.35kg for demo)
    final totalTrashWeight = (stats.trashItemsByType
                .fold<int>(0, (int sum, TrashItem item) => sum + item.count) *
            0.35)
        .toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                'Tus puntos Oscar',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stats.pointsEarnedTotal.toStringAsFixed(2),
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Row(
            children: [
              _StatChip(
                  label: '${stats.sessionsCompleted} sesiones',
                  icon: Icons.recycling_rounded),
              const SizedBox(width: AppDimens.sm),
              _StatChip(
                  label: '${totalTrashWeight} kg', icon: Icons.scale_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final ThemeData theme;
  const _QuickActionsRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.card_giftcard_rounded, 'Recompensas', AppColors.accentAmber),
      (Icons.map_rounded, 'Oscarito\ncercano', AppColors.accentTeal),
      (Icons.insights_rounded, 'Métricas', AppColors.accentPurple),
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _QuickActionCard(icon: a.$1, label: a.$2, color: a.$3),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityPlaceholder extends StatelessWidget {
  final ThemeData theme;
  const _RecentActivityPlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Column(
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesión de reciclaje',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '+${(i + 1) * 30} pts · hace ${i + 1}h',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
