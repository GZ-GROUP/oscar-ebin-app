// lib/features/rewards/data/rewards_service.dart
//
//  Implementa:
//    - GET  /api/rewards      → catálogo público de recompensas
//    - GET  /api/rewards/me   → recompensas del usuario autenticado
//    - POST /api/redeem       → canjear una recompensa con puntos
//
//  NO implementado a propósito (rutas solo para empresas):
//    - POST /api/reward   (crear)
//    - PUT  /api/reward   (modificar)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'rewards_model.dart';

class RewardsService {
  static const _baseUrl = 'https://oscar.gzgroup.dev/api';

  final http.Client client;

  RewardsService({http.Client? client}) : client = client ?? http.Client();

  /// GET /api/rewards — catálogo público, no requiere autenticación.
  Future<List<Reward>?> getRewards() async {
    final url = Uri.parse('$_baseUrl/rewards');
    final resp = await client.get(url, headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
    });

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => Reward.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  /// GET /api/rewards/me — recompensas del usuario autenticado,
  /// agrupadas en purchased / available / expired.
  Future<MyRewards?> getMyRewards(String accessToken) async {
    final url = Uri.parse('$_baseUrl/rewards/me');
    final resp = await client.get(url, headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
      'authorization': 'Bearer $accessToken',
    });

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return MyRewards.fromJson(json);
    }
    return null;
  }

  /// POST /api/redeem — canjea una recompensa con puntos.
  ///
  /// Lanza [RewardsException] con el mensaje de negocio del backend si
  /// falla (saldo insuficiente, sin stock, expirada, ya reclamada, etc.).
  Future<RedeemResult> redeem({
    required String accessToken,
    required int rewardId,
  }) async {
    final url = Uri.parse('$_baseUrl/redeem');
    final resp = await client.post(
      url,
      headers: {
        'content-type': 'application/json',
        'accept': 'application/json',
        'authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'reward_id': rewardId}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return RedeemResult.fromJson(json);
    }

    String message = 'No se pudo canjear la recompensa.';
    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final err = json['error'];
      if (err is String && err.isNotEmpty) message = err;
    } catch (_) {
      // Cuerpo no era JSON válido; usamos el mensaje genérico de arriba.
    }
    throw RewardsException(message);
  }
}