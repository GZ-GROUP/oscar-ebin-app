// lib/features/rewards/presentation/screens/rewards_screen.dart
//
//  RewardsScreen — "Pantalla de reclamo de recompensas"
//  ─────────────────────────────────────────────────────────────────────────────
//  Implementado a partir del diseño de Figma:
//  https://www.figma.com/design/y0PqEYisffLsnNNoNXX4zi/rewards
//
//  El saldo de puntos (`pointsAvailable`) viene del backend real vía
//  `profileStatsProvider`. El catálogo de recompensas es local por ahora
//  (ver rewards_provider.dart) porque el backend aún no expone ese endpoint.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../profile/data/profile_model.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../providers/rewards_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  RewardStatus _selected = RewardStatus.disponible;

  @override
  Widget build(BuildContext context) {
    final profileStats = ref.watch(profileStatsProvider);
    final rewards = ref.watch(rewardsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _RewardsAppBar(
        pointsAsync: profileStats,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
      body: profileStats.when(
        data: (stats) => _RewardsBody(
          stats: stats,
          rewards: rewards,
          selected: _selected,
          onSelect: (s) => setState(() => _selected = s),
          onRedeem: (r) => _handleRedeem(context, ref, r),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _handleRedeem(BuildContext context, WidgetRef ref, RewardItem reward) {
    HapticFeedback.mediumImpact();
    ref.read(rewardsProvider.notifier).redeem(reward.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Canjeaste "${reward.title}" 🎉'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BODY
// ─────────────────────────────────────────────────────────────────────────────
class _RewardsBody extends ConsumerWidget {
  final ProfileStats? stats;
  final List<RewardItem> rewards;
  final RewardStatus selected;
  final ValueChanged<RewardStatus> onSelect;
  final ValueChanged<RewardItem> onRedeem;

  const _RewardsBody({
    required this.stats,
    required this.rewards,
    required this.selected,
    required this.onSelect,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stats == null) {
      return const Center(child: Text('No hay datos de perfil'));
    }

    final disponibles =
        rewards.where((r) => r.status == RewardStatus.disponible).toList();
    final canjeadas =
        rewards.where((r) => r.status == RewardStatus.canjeada).toList();
    final expiradas =
        rewards.where((r) => r.status == RewardStatus.expirada).toList();

    final visible = switch (selected) {
      RewardStatus.disponible => disponibles,
      RewardStatus.canjeada => canjeadas,
      RewardStatus.expirada => expiradas,
    };

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
          AppDimens.navBarHeight + AppDimens.navFabSize / 2 + AppDimens.lg,
        ),
        children: [
          _PointsHeroCard(
            points: stats!.pointsAvailable,
            totalRewards: rewards.length,
            availableToday: disponibles.length,
          ),
          const SizedBox(height: AppDimens.md),
          if (disponibles.isNotEmpty) ...[
            _NoticeBanner(count: disponibles.length),
            const SizedBox(height: AppDimens.md),
          ],
          _StatusTabs(
            selected: selected,
            counts: {
              RewardStatus.disponible: disponibles.length,
              RewardStatus.canjeada: canjeadas.length,
              RewardStatus.expirada: expiradas.length,
            },
            onChanged: onSelect,
          ),
          const SizedBox(height: AppDimens.md),
          if (visible.isEmpty)
            const _EmptyState()
          else
            ...visible.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RewardCard(
                  reward: r,
                  userPoints: stats!.pointsAvailable,
                  onRedeem: () => onRedeem(r),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _RewardsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AsyncValue<ProfileStats?> pointsAsync;
  final VoidCallback onBack;

  const _RewardsAppBar({required this.pointsAsync, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final points = pointsAsync.asData?.value?.pointsAvailable;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      titleSpacing: 12,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDimens.md),
        child: _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Recompensas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Canjea tus puntos Oscar',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: AppDimens.md),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                points == null ? '—' : '${points.toStringAsFixed(2)} pts',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  POINTS HERO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PointsHeroCard extends StatelessWidget {
  final double points;
  final int totalRewards;
  final int availableToday;

  const _PointsHeroCard({
    required this.points,
    required this.totalRewards,
    required this.availableToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -20,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    color: Colors.white70,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tus puntos Oscar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                points.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _HeroChip(
                    icon: Icons.card_giftcard_rounded,
                    label: '$totalRewards recompensas',
                  ),
                  const SizedBox(width: 8),
                  _HeroChip(
                    icon: Icons.bolt_rounded,
                    label: '$availableToday disponibles hoy',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
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

// ─────────────────────────────────────────────────────────────────────────────
//  NOTICE BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _NoticeBanner extends StatelessWidget {
  final int count;

  const _NoticeBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFEF3C6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 16,
            color: Color(0xFFBB4D00),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tienes $count recompensas que puedes canjear ahora mismo.',
              style: const TextStyle(
                color: Color(0xFFBB4D00),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATUS TABS (Disponibles / Canjeadas / Expiradas)
// ─────────────────────────────────────────────────────────────────────────────
class _StatusTabs extends StatelessWidget {
  final RewardStatus selected;
  final Map<RewardStatus, int> counts;
  final ValueChanged<RewardStatus> onChanged;

  const _StatusTabs({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  static const _labels = {
    RewardStatus.disponible: 'Disponibles',
    RewardStatus.canjeada: 'Canjeadas',
    RewardStatus.expirada: 'Expiradas',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: RewardStatus.values.map((status) {
          final isSelected = status == selected;
          final isLast = status == RewardStatus.values.last;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 4),
              child: InkWell(
                onTap: () => onChanged(status),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 1.5,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _labels[status]!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.25)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusFull,
                          ),
                        ),
                        child: Text(
                          '${counts[status] ?? 0}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REWARD CARD
// ─────────────────────────────────────────────────────────────────────────────
class _RewardCard extends StatelessWidget {
  final RewardItem reward;
  final double userPoints;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.reward,
    required this.userPoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = reward.status == RewardStatus.disponible;
    final canAfford = userPoints >= reward.points;
    final showRedeemEnabled = isAvailable && canAfford;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAvailable
                  ? reward.color.withOpacity(0.12)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              reward.icon,
              size: 26,
              color: isAvailable ? reward.color : AppColors.textDisabled,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      size: 13,
                      color: isAvailable
                          ? AppColors.primary
                          : AppColors.textDisabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.points.toStringAsFixed(2)} pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isAvailable
                            ? AppColors.primary
                            : AppColors.textDisabled,
                      ),
                    ),
                    if (reward.badge != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          reward.badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFFE9A00),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (isAvailable)
                      _RedeemButton(
                        enabled: showRedeemEnabled,
                        onTap: showRedeemEnabled ? onRedeem : null,
                      )
                    else
                      _StatusPill(status: reward.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RedeemButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _RedeemButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          'Canjear',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.white : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RewardStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isRedeemed = status == RewardStatus.canjeada;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRedeemed ? AppColors.primarySurface : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRedeemed ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 13,
            color: isRedeemed ? AppColors.primary : AppColors.textDisabled,
          ),
          const SizedBox(width: 4),
          Text(
            isRedeemed ? 'Canjeada' : 'Expirada',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isRedeemed ? AppColors.primary : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 40, color: AppColors.textDisabled),
          SizedBox(height: 12),
          Text(
            'No tienes recompensas aquí todavía',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}