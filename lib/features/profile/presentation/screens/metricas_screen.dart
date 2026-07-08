//lib/features/profile/presentation/screens/metricas_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/profile_model.dart';
import '../../providers/profile_provider.dart';

class MetricasScreen extends ConsumerWidget {
  const MetricasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileStats = ref.watch(profileStatsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.perfil);
            }
          },
        ),
        title: const Text('Métricas personales'),
      ),
      body: profileStats.when(
        data: (stats) {
          if (stats == null) {
            return const Center(child: Text('No hay datos de métricas'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileStatsProvider);
              await ref.read(profileStatsProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppDimens.md,
                AppDimens.md,
                AppDimens.md,
                AppDimens.xl,
              ),
              children: [
                _StatsRow(theme: theme, stats: stats),
                const SizedBox(height: AppDimens.lg),
                _TrashDistributionCard(theme: theme, stats: stats),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// ─── Fila de 3 métricas (casillas del wireframe) ───────────────────────────
class _StatsRow extends StatelessWidget {
  final ThemeData theme;
  final ProfileStats stats;
  const _StatsRow({required this.theme, required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Color)>[
      (
        Icons.recycling_rounded,
        stats.sessionsCompleted.toString(),
        'Sesiones\ncompletadas',
        AppColors.primary,
      ),
      (
        Icons.stars_rounded,
        stats.pointsEarnedTotal.toStringAsFixed(2),
        'Puntos\ntotales',
        AppColors.accentAmber,
      ),
      (
        Icons.card_giftcard_rounded,
        stats.rewardsClaimed.toString(),
        'Recompensas\ncanjeadas',
        AppColors.accentPurple,
      ),
    ];

    return Row(
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isLast = i == items.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppDimens.sm),
            child: _StatCard(
              icon: item.$1,
              value: item.$2,
              label: item.$3,
              color: item.$4,
            ),
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.md,
        horizontal: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta con pie chart de distribución de residuos ─────────────────────
class _TrashDistributionCard extends StatelessWidget {
  final ThemeData theme;
  final ProfileStats stats;
  const _TrashDistributionCard({required this.theme, required this.stats});

  static const List<Color> _chartColors = [
    AppColors.primary,
    AppColors.accentTeal,
    AppColors.accentAmber,
    AppColors.accentPurple,
    AppColors.info,
    AppColors.warning,
    AppColors.error,
    AppColors.primaryDark,
  ];

  @override
  Widget build(BuildContext context) {
    final items = stats.trashItemsByType;
    final total = items.fold<int>(0, (sum, item) => sum + item.count);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de residuos',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimens.md),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.xl),
              child: Center(
                child: Text(
                  'Aún no hay residuos registrados',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    values: items.map((item) => item.count).toList(),
                    total: total,
                    colors: _chartColors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            ...List.generate(items.length, (i) {
              final item = items[i];
              final percentage = (item.count / total) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _chartColors[i % _chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<int> values;
  final int total;
  final List<Color> colors;

  _PieChartPainter({
    required this.values,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweepAngle = 2 * math.pi * (values[i] / total);
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // Borde blanco entre las porciones para separarlas visualmente
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweepAngle = 2 * math.pi * (values[i] / total);
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.total != total ||
        oldDelegate.colors != colors;
  }
}