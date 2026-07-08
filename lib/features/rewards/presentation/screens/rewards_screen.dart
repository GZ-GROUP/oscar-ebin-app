// lib/features/rewards/presentation/screens/rewards_screen.dart
//
//  RewardsScreen — "Pantalla de reclamo de recompensas"
//  ─────────────────────────────────────────────────────────────────────────────
//  Implementado a partir del diseño de Figma:
//  https://www.figma.com/design/y0PqEYisffLsnNNoNXX4zi/rewards
//
//  Datos reales:
//   - Saldo de puntos → profileStatsProvider (GET /api/profile)
//   - Catálogo público → rewardsCatalogProvider (GET /api/rewards)
//   - Recompensas del usuario → myRewardsProvider (GET /api/rewards/me)
//   - Canjear → rewardsActionsProvider (POST /api/redeem)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../profile/data/profile_model.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../data/rewards_model.dart';
import '../../providers/rewards_provider.dart';

enum _RewardTab { disponibles, canjeadas, expiradas }

/// Datos ya normalizados que necesita una `_RewardCard`, sin importar si
/// vienen de `Reward`, `RewardSummary` o `ClaimedReward`.
class _CardVM {
  final String title;
  final String subtitle;
  final double price;
  final Widget trailing;

  const _CardVM({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.trailing,
  });
}

String _fmtDate(DateTime? d) {
  if (d == null) return '';
  return '${d.day}/${d.month}/${d.year}';
}

/// No tenemos un campo de ícono en el backend, así que lo inferimos del
/// nombre para que la tarjeta no se vea genérica.
(IconData, Color) _iconFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('café') || n.contains('cafe') || n.contains('coffee')) {
    return (Icons.coffee_rounded, AppColors.accentAmber);
  }
  if (n.contains('bolsa') || n.contains('bag')) {
    return (Icons.shopping_bag_rounded, AppColors.primary);
  }
  if (n.contains('energ') || n.contains('bono') || n.contains('luz')) {
    return (Icons.bolt_rounded, AppColors.warning);
  }
  if (n.contains('bici') || n.contains('bike')) {
    return (Icons.pedal_bike_rounded, AppColors.accentTeal);
  }
  if (n.contains('estrella') || n.contains('star')) {
    return (Icons.stars_rounded, AppColors.accentPurple);
  }
  if (n.contains('cine') || n.contains('movie') || n.contains('película')) {
    return (Icons.local_movies_rounded, AppColors.accentPurple);
  }
  if (n.contains('gimnasio') || n.contains('gym') || n.contains('fitness')) {
    return (Icons.fitness_center_rounded, AppColors.accentTeal);
  }
  if (n.contains('descuento') || n.contains('discount')) {
    return (Icons.percent_rounded, AppColors.primary);
  }
  return (Icons.card_giftcard_rounded, AppColors.primary);
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pendiente';
    case 'redeemed':
      return 'Canjeada';
    case 'expired':
      return 'Expirada';
    default:
      return status.isEmpty ? 'Canjeada' : status;
  }
}

/// Formatea el código real que devuelve el backend como "XXX-XXX":
/// se queda con los primeros 6 caracteres alfanuméricos, en mayúsculas,
/// separados en dos grupos de 3.
String _formatRedeemCode(String raw) {
  final clean = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  final six = clean.length >= 6
      ? clean.substring(0, 6)
      : clean.padRight(6, '0');
  return '${six.substring(0, 3)}-${six.substring(3, 6)}';
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  _RewardTab _selected = _RewardTab.disponibles;

  @override
  Widget build(BuildContext context) {
    final profileStats = ref.watch(profileStatsProvider);

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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileStatsProvider);
          ref.invalidate(rewardsCatalogProvider);
          ref.invalidate(myRewardsProvider);
          await Future.wait([
            ref.read(profileStatsProvider.future),
            ref.read(rewardsCatalogProvider.future),
            ref.read(myRewardsProvider.future),
          ]);
        },
        child: profileStats.when(
          data: (stats) => _RewardsBody(
            stats: stats,
            selected: _selected,
            onSelect: (s) => setState(() => _selected = s),
          ),
          loading: () => const _LoadingState(),
          error: (err, stack) => _ErrorState(message: '$err'),
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
  final _RewardTab selected;
  final ValueChanged<_RewardTab> onSelect;

  const _RewardsBody({
    required this.stats,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stats == null) {
      return const _ErrorState(message: 'No hay datos de perfil');
    }

    final catalogAsync = ref.watch(rewardsCatalogProvider);
    final myRewardsAsync = ref.watch(myRewardsProvider);
    final actionState = ref.watch(rewardsActionsProvider);

    return catalogAsync.when(
      data: (catalog) => myRewardsAsync.when(
        data: (myRewards) =>
            _buildContent(context, ref, catalog, myRewards, actionState),
        loading: () => const _LoadingState(),
        error: (err, stack) => _ErrorState(message: '$err'),
      ),
      loading: () => const _LoadingState(),
      error: (err, stack) => _ErrorState(message: '$err'),
    );
  }

  Future<void> _handleRedeem(
    BuildContext context,
    WidgetRef ref,
    RewardSummary reward,
  ) async {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(rewardsActionsProvider.notifier);
    final result = await notifier.redeem(reward.id);
    if (!context.mounted) return;

    if (result != null) {
      _showRedeemSuccess(context, reward.name, _formatRedeemCode(result.code));
    } else {
      final message =
          ref.read(rewardsActionsProvider).error ?? 'No se pudo canjear la recompensa.';
      _showRedeemError(context, message);
    }
  }

  void _showRedeemSuccess(BuildContext context, String title, String code) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        content: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¡Canjeaste "$title"!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu código: $code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Reward> catalog,
    MyRewards? myRewards,
    RewardsActionState actionState,
  ) {
    final available = myRewards?.available ?? const <RewardSummary>[];
    final purchased = myRewards?.purchased ?? const <ClaimedReward>[];
    final expired = myRewards?.expired ?? const <ClaimedReward>[];
    final userPoints = stats!.pointsAvailable;

    final disponiblesVM = available.map((r) {
      final canAfford = userPoints >= r.price;
      final isRedeemingThis = actionState.isRedeemingId(r.id);
      final anyRedeemInFlight = actionState.redeemingRewardId != null;
      return _CardVM(
        title: r.name,
        subtitle: r.validUntil != null
            ? 'Válido hasta ${_fmtDate(r.validUntil)}'
            : 'Disponible para canjear',
        price: r.price,
        trailing: _RedeemButton(
          enabled: canAfford && !anyRedeemInFlight,
          loading: isRedeemingThis,
          onTap: () => _handleRedeem(context, ref, r),
        ),
      );
    }).toList();

    final canjeadasVM = purchased.map((c) {
      final subtitleParts = <String>[
        if (c.code != null) 'Código: ${c.code}',
        if (c.claimCreatedAt != null) 'el ${_fmtDate(c.claimCreatedAt)}',
      ];
      return _CardVM(
        title: c.reward.name,
        subtitle: subtitleParts.isEmpty
            ? _statusLabel(c.status)
            : subtitleParts.join(' · '),
        price: c.reward.price,
        trailing: _StatusChip(
          label: _statusLabel(c.status),
          tone: _ChipTone.success,
        ),
      );
    }).toList();

    final expiradasVM = expired.map((c) {
      return _CardVM(
        title: c.reward.name,
        subtitle: c.claimCreatedAt != null
            ? 'Expiró el ${_fmtDate(c.claimCreatedAt)}'
            : 'Expirada',
        price: c.reward.price,
        trailing: const _StatusChip(label: 'Expirada', tone: _ChipTone.muted),
      );
    }).toList();

    final visible = switch (selected) {
      _RewardTab.disponibles => disponiblesVM,
      _RewardTab.canjeadas => canjeadasVM,
      _RewardTab.expiradas => expiradasVM,
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.md,
        AppDimens.md,
        AppDimens.md,
        AppDimens.navBarHeight + AppDimens.navFabSize / 2 + AppDimens.lg,
      ),
      children: [
        _PointsHeroCard(
          points: userPoints,
          totalRewards: catalog.length,
          availableToday: disponiblesVM.length,
        ),
        const SizedBox(height: AppDimens.md),
        if (disponiblesVM.isNotEmpty) ...[
          _NoticeBanner(count: disponiblesVM.length),
          const SizedBox(height: AppDimens.md),
        ],
        _StatusTabs(
          selected: selected,
          counts: {
            _RewardTab.disponibles: disponiblesVM.length,
            _RewardTab.canjeadas: canjeadasVM.length,
            _RewardTab.expiradas: expiradasVM.length,
          },
          onChanged: onSelect,
        ),
        const SizedBox(height: AppDimens.md),
        if (visible.isEmpty)
          const _EmptyState()
        else
          ...visible.map(
            (vm) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RewardCard(vm: vm),
            ),
          ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.cloud_off_rounded,
          size: 40,
          color: AppColors.textDisabled,
        ),
        const SizedBox(height: 12),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No se pudieron cargar las recompensas.\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
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
  final _RewardTab selected;
  final Map<_RewardTab, int> counts;
  final ValueChanged<_RewardTab> onChanged;

  const _StatusTabs({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  static const _labels = {
    _RewardTab.disponibles: 'Disponibles',
    _RewardTab.canjeadas: 'Canjeadas',
    _RewardTab.expiradas: 'Expiradas',
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
        children: _RewardTab.values.map((tab) {
          final isSelected = tab == selected;
          final isLast = tab == _RewardTab.values.last;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 4),
              child: InkWell(
                onTap: () => onChanged(tab),
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
                        _labels[tab]!,
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
                          '${counts[tab] ?? 0}',
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
  final _CardVM vm;

  const _RewardCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconFor(vm.title);

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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vm.subtitle,
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
                    const Icon(
                      Icons.eco_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${vm.price.toStringAsFixed(2)} pts',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    vm.trailing,
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
  final bool loading;
  final VoidCallback onTap;

  const _RedeemButton({
    required this.enabled,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = enabled || loading;
    return InkWell(
      onTap: (enabled && !loading) ? onTap : null,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                enabled ? 'Canjear' : 'Puntos insuficientes',
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

enum _ChipTone { success, muted }

class _StatusChip extends StatelessWidget {
  final String label;
  final _ChipTone tone;

  const _StatusChip({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final isSuccess = tone == _ChipTone.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.primarySurface : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 13,
            color: isSuccess ? AppColors.primary : AppColors.textDisabled,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSuccess ? AppColors.primary : AppColors.textDisabled,
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