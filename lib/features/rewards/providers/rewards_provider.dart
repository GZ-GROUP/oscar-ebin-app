// lib/features/rewards/providers/rewards_provider.dart
//
//  NOTA: el backend (https://oscar.gzgroup.dev/api) todavía no expone un
//  catálogo de recompensas (no existe un endpoint `/rewards`). Mientras tanto
//  usamos un catálogo local. El saldo de puntos que se muestra en la pantalla
//  SÍ es real y viene de `profileStatsProvider` (campo `pointsAvailable`).
//  Cuando el backend exponga el catálogo, reemplazar `kRewardCatalog` y
//  `RewardsNotifier` por llamadas a un `RewardsService` (mismo patrón que
//  `AuthService`/`profileStatsProvider`).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';

enum RewardStatus { disponible, canjeada, expirada }

class RewardItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double points;
  final RewardStatus status;
  final String? badge;

  const RewardItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.points,
    required this.status,
    this.badge,
  });

  RewardItem copyWith({RewardStatus? status, String? subtitle}) {
    return RewardItem(
      id: id,
      title: title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon,
      color: color,
      points: points,
      status: status ?? this.status,
      badge: badge,
    );
  }
}

const List<RewardItem> kRewardCatalog = [
  RewardItem(
    id: 'cafe-gratis',
    title: 'Café gratis',
    subtitle: 'Canjea en cualquier tienda participante',
    icon: Icons.coffee_rounded,
    color: AppColors.accentAmber,
    points: 2.00,
    status: RewardStatus.disponible,
  ),
  RewardItem(
    id: 'bolsa-ecologica',
    title: 'Bolsa ecológica',
    subtitle: 'Bolsa reutilizable de tela orgánica',
    icon: Icons.shopping_bag_rounded,
    color: AppColors.primary,
    points: 3.00,
    status: RewardStatus.disponible,
  ),
  RewardItem(
    id: 'bono-energia',
    title: 'Bono energía',
    subtitle: 'Descuento en tu próxima factura de luz',
    icon: Icons.bolt_rounded,
    color: AppColors.warning,
    points: 5.00,
    status: RewardStatus.disponible,
    badge: 'Casi tienes suficiente',
  ),
  RewardItem(
    id: 'paseo-bici',
    title: 'Paseo en bici',
    subtitle: '1 hora gratis en bicicleta compartida',
    icon: Icons.pedal_bike_rounded,
    color: AppColors.accentTeal,
    points: 1.50,
    status: RewardStatus.disponible,
  ),
  RewardItem(
    id: 'puntos-estrella',
    title: 'Puntos estrella',
    subtitle: 'Bonificación doble en tu próximo reciclaje',
    icon: Icons.stars_rounded,
    color: AppColors.accentPurple,
    points: 2.50,
    status: RewardStatus.disponible,
  ),
  RewardItem(
    id: 'entrada-cine',
    title: 'Entrada al cine',
    subtitle: 'Canjeada el 28 de junio',
    icon: Icons.local_movies_rounded,
    color: AppColors.accentPurple,
    points: 4.00,
    status: RewardStatus.canjeada,
  ),
  RewardItem(
    id: 'cafe-gratis-2',
    title: 'Café gratis',
    subtitle: 'Canjeada el 15 de junio',
    icon: Icons.coffee_rounded,
    color: AppColors.accentAmber,
    points: 2.00,
    status: RewardStatus.canjeada,
  ),
  RewardItem(
    id: 'gimnasio',
    title: 'Descuento en gimnasio',
    subtitle: 'Expiró el 30 de mayo',
    icon: Icons.fitness_center_rounded,
    color: AppColors.textDisabled,
    points: 3.50,
    status: RewardStatus.expirada,
  ),
];

class RewardsNotifier extends StateNotifier<List<RewardItem>> {
  RewardsNotifier() : super(kRewardCatalog);

  /// Marca una recompensa como canjeada localmente.
  /// TODO: cuando exista el endpoint de canje, llamar al backend aquí y
  /// refrescar `profileStatsProvider` para reflejar el nuevo saldo real.
  void redeem(String id) {
    final now = DateTime.now();
    final fecha = '${now.day}/${now.month}/${now.year}';
    state = [
      for (final r in state)
        if (r.id == id)
          r.copyWith(
            status: RewardStatus.canjeada,
            subtitle: 'Canjeada el $fecha',
          )
        else
          r,
    ];
  }
}

final rewardsProvider =
    StateNotifierProvider<RewardsNotifier, List<RewardItem>>(
  (ref) => RewardsNotifier(),
);