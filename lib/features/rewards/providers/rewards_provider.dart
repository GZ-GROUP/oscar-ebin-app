// lib/features/rewards/providers/rewards_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/rewards_model.dart';
import '../data/rewards_service.dart';

final rewardsServiceProvider = Provider((ref) => RewardsService());

/// Catálogo público de recompensas (GET /api/rewards).
/// No requiere autenticación.
final rewardsCatalogProvider = FutureProvider<List<Reward>>((ref) async {
  final service = ref.watch(rewardsServiceProvider);
  return await service.getRewards() ?? [];
});

/// Recompensas del usuario autenticado, agrupadas en
/// purchased / available / expired (GET /api/rewards/me).
final myRewardsProvider = FutureProvider<MyRewards?>((ref) async {
  final auth = ref.watch(authProvider);
  final service = ref.watch(rewardsServiceProvider);

  if (!auth.isAuthenticated || auth.token == null) {
    return null;
  }

  return await service.getMyRewards(auth.token!);
});

// ─────────────────────────────────────────────────────────────────────────────
//  REDEEM ACTION (POST /api/redeem)
// ─────────────────────────────────────────────────────────────────────────────
class RewardsActionState {
  /// id de la recompensa que se está canjeando ahora mismo, o null.
  final int? redeemingRewardId;
  final String? error;

  const RewardsActionState({this.redeemingRewardId, this.error});

  bool isRedeemingId(int id) => redeemingRewardId == id;
}

class RewardsActionsNotifier extends StateNotifier<RewardsActionState> {
  final RewardsService _service;
  final Ref _ref;

  RewardsActionsNotifier(this._service, this._ref)
      : super(const RewardsActionState());

  /// Canjea una recompensa. Devuelve el [RedeemResult] si tiene éxito, o
  /// null si falla — en ese caso el mensaje del backend queda disponible
  /// en `state.error`.
  Future<RedeemResult?> redeem(int rewardId) async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated || auth.token == null) {
      state = const RewardsActionState(error: 'Debes iniciar sesión.');
      return null;
    }

    state = RewardsActionState(redeemingRewardId: rewardId);
    try {
      final result = await _service.redeem(
        accessToken: auth.token!,
        rewardId: rewardId,
      );
      state = const RewardsActionState();
      // El saldo y las listas de recompensas cambiaron en el backend.
      _ref.invalidate(profileStatsProvider);
      _ref.invalidate(myRewardsProvider);
      return result;
    } on RewardsException catch (e) {
      state = RewardsActionState(error: e.message);
      return null;
    } catch (_) {
      state =
          const RewardsActionState(error: 'No se pudo canjear la recompensa.');
      return null;
    }
  }
}

final rewardsActionsProvider =
    StateNotifierProvider<RewardsActionsNotifier, RewardsActionState>((ref) {
  final service = ref.read(rewardsServiceProvider);
  return RewardsActionsNotifier(service, ref);
});