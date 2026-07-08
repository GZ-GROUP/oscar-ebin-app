// lib/features/rewards/data/rewards_model.dart
//
//  Modelos para GET /api/rewards y GET /api/rewards/me.
//  (POST /api/redeem, POST /api/reward y PUT /api/reward no están
//  implementados todavía — ver rewards_service.dart)
// ─────────────────────────────────────────────────────────────────────────────

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is int) return v.toDouble();
  if (v is double) return v;
  return double.tryParse(v.toString()) ?? 0.0;
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v as String);
}

/// Recompensa completa del catálogo público (`GET /api/rewards`).
class Reward {
  final int id;
  final int companyId;
  final String name;
  final double price;
  final String? imageUrl;
  final int stock;
  final bool isActive;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Reward({
    required this.id,
    required this.companyId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.stock,
    required this.isActive,
    this.validUntil,
    this.createdAt,
    this.updatedAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as int,
      companyId: json['company_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: _asDouble(json['price']),
      imageUrl: json['image_url'] as String?,
      stock: json['stock'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      validUntil: _asDate(json['valid_until']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());
  bool get isOutOfStock => stock <= 0;
}

/// Versión reducida de una recompensa, tal como la devuelve
/// `GET /api/rewards/me` dentro de `available` y anidada en cada claim.
class RewardSummary {
  final int id;
  final String name;
  final double price;
  final bool isActive;
  final DateTime? validUntil;

  const RewardSummary({
    required this.id,
    required this.name,
    required this.price,
    required this.isActive,
    this.validUntil,
  });

  factory RewardSummary.fromJson(Map<String, dynamic> json) {
    return RewardSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      price: _asDouble(json['price']),
      isActive: json['is_active'] as bool? ?? true,
      validUntil: _asDate(json['valid_until']),
    );
  }
}

/// Un canje (`claim`) del usuario, presente en `purchased` y `expired`.
class ClaimedReward {
  final int claimId;
  final String status;
  final String? code;
  final DateTime? claimCreatedAt;
  final DateTime? redeemedAt;
  final RewardSummary reward;

  const ClaimedReward({
    required this.claimId,
    required this.status,
    this.code,
    this.claimCreatedAt,
    this.redeemedAt,
    required this.reward,
  });

  factory ClaimedReward.fromJson(Map<String, dynamic> json) {
    return ClaimedReward(
      claimId: json['claim_id'] as int,
      status: json['status'] as String? ?? '',
      code: json['code'] as String?,
      claimCreatedAt: _asDate(json['claim_created_at']),
      redeemedAt: _asDate(json['redeemed_at']),
      reward: RewardSummary.fromJson(json['reward'] as Map<String, dynamic>),
    );
  }
}

/// Respuesta completa de `GET /api/rewards/me`.
class MyRewards {
  final List<ClaimedReward> purchased;
  final List<RewardSummary> available;
  final List<ClaimedReward> expired;

  const MyRewards({
    required this.purchased,
    required this.available,
    required this.expired,
  });

  factory MyRewards.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return MyRewards(
      purchased: (data['purchased'] as List<dynamic>? ?? [])
          .map((e) => ClaimedReward.fromJson(e as Map<String, dynamic>))
          .toList(),
      available: (data['available'] as List<dynamic>? ?? [])
          .map((e) => RewardSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      expired: (data['expired'] as List<dynamic>? ?? [])
          .map((e) => ClaimedReward.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Respuesta de `POST /api/redeem`.
class RedeemResult {
  final int id;
  final int userId;
  final int rewardId;
  final String status;
  final String code;
  final DateTime? createdAt;
  final DateTime? redeemedAt;

  const RedeemResult({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.status,
    required this.code,
    this.createdAt,
    this.redeemedAt,
  });

  factory RedeemResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return RedeemResult(
      id: data['id'] as int,
      userId: data['user_id'] as int,
      rewardId: data['reward_id'] as int,
      status: data['status'] as String? ?? '',
      code: data['code'] as String? ?? '',
      createdAt: _asDate(data['created_at']),
      redeemedAt: _asDate(data['redeemed_at']),
    );
  }
}

/// Error de negocio devuelto por el backend al canjear
/// (saldo insuficiente, sin stock, ya reclamada, expirada, etc.).
class RewardsException implements Exception {
  final String message;
  const RewardsException(this.message);

  @override
  String toString() => message;
}