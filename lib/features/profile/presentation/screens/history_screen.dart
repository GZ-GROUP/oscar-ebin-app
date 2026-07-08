// lib/features/history/history_screen.dart
//
// Pantalla de historial de transacciones.
// Consume GET /history con filtros de categoría/tipo y paginación.
//
// Dependencias necesarias en pubspec.yaml (si no las tienes ya):
//   http: ^1.2.0
//   intl: ^0.19.0

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';

class HistoryItem {
  final int id;
  final int userId;
  final int? sessionId;
  final int? rewardClaimId;
  final int amount;
  final String type; // 'credit' | 'debit'
  final String? note;
  final DateTime createdAt;
  final String? rewardCode;
  final String? rewardName;
  final int? sessionOscarId;
  final String? oscarName;

  HistoryItem({
    required this.id,
    required this.userId,
    this.sessionId,
    this.rewardClaimId,
    required this.amount,
    required this.type,
    this.note,
    required this.createdAt,
    this.rewardCode,
    this.rewardName,
    this.sessionOscarId,
    this.oscarName,
  });

  bool get isCredit => type == 'credit';
  bool get isSessionEntry => sessionId != null;

  // Convierte a int sin importar si el backend manda num, String o null.
  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    return _asInt(value);
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      sessionId: _asIntOrNull(json['session_id']),
      rewardClaimId: _asIntOrNull(json['reward_claim_id']),
      amount: _asInt(json['amount']),
      type: json['type'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      rewardCode: json['reward_code'] as String?,
      rewardName: json['reward_name'] as String?,
      sessionOscarId: _asIntOrNull(json['session_oscar_id']),
      oscarName: json['oscar_name'] as String?,
    );
  }
}

class HistoryMeta {
  final int page;
  final int limit;
  final String? category;
  final String? type;

  HistoryMeta({
    required this.page,
    required this.limit,
    this.category,
    this.type,
  });

  factory HistoryMeta.fromJson(Map<String, dynamic> json) {
    return HistoryMeta(
      page: HistoryItem._asInt(json['page']),
      limit: HistoryItem._asInt(json['limit']),
      category: json['category'] as String?,
      type: json['type'] as String?,
    );
  }
}

class HistoryResponse {
  final List<HistoryItem> data;
  final HistoryMeta meta;

  HistoryResponse({required this.data, required this.meta});

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      data: (json['data'] as List)
          .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: HistoryMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class HistoryException implements Exception {
  final String message;
  final int statusCode;
  HistoryException(this.message, this.statusCode);

  @override
  String toString() => message;
}

// ════════════════════════════════════════════════════════════════════════
// SERVICIO
// ════════════════════════════════════════════════════════════════════════

class HistoryService {
  // Ya incluye '/api'; NO agregar '/api' de nuevo en las rutas de abajo.
  static const baseUrl = 'https://oscar.gzgroup.dev/api';

  final String token;

  HistoryService({required this.token});

  Future<HistoryResponse> fetchHistory({
    String? category, // 'session' | 'claim'
    String? type, // 'credit' | 'debit'
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (category != null) 'category': category,
      if (type != null) 'type': type,
    };

    final uri =
        Uri.parse('$baseUrl/history').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return HistoryResponse.fromJson(body);
    }

    String message = 'No se pudo cargar el historial';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['error'] != null) {
        message = body['error'] as String;
      }
    } catch (_) {
      // Si el cuerpo no es JSON válido, se usa el mensaje por defecto.
    }
    throw HistoryException(message, response.statusCode);
  }
}

// ════════════════════════════════════════════════════════════════════════
// PANTALLA
// ════════════════════════════════════════════════════════════════════════

class HistoryScreen extends StatefulWidget {
  /// Token JWT del usuario autenticado.
  final String authToken;

  const HistoryScreen({super.key, required this.authToken});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryService _service;

  final List<HistoryItem> _items = [];
  int _page = 1;
  final int _limit = 15;

  String? _category; // null = todos
  String? _type; // null = todos

  bool _isLoading = false; // carga inicial / cambio de filtro
  bool _isLoadingMore = false; // carga de "siguiente página"
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = HistoryService(token: widget.authToken);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final result = await _service.fetchHistory(
        category: _category,
        type: _type,
        page: 1,
        limit: _limit,
      );
      setState(() {
        _items
          ..clear()
          ..addAll(result.data);
        _hasMore = result.data.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error real en historial: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e is HistoryException ? e.message : 'Error de conexión';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _page + 1;
      final result = await _service.fetchHistory(
        category: _category,
        type: _type,
        page: nextPage,
        limit: _limit,
      );
      setState(() {
        _page = nextPage;
        _items.addAll(result.data);
        _hasMore = result.data.length == _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error real al cargar más: $e');
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is HistoryException ? e.message : 'Error al cargar más',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onCategoryChanged(String? value) {
    if (_category == value) return;
    setState(() => _category = value);
    _loadInitial();
  }

  void _onTypeChanged(String? value) {
    if (_type == value) return;
    setState(() => _type = value);
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: Column(
        children: [
          _FilterBar(
            selectedCategory: _category,
            selectedType: _type,
            onCategoryChanged: _onCategoryChanged,
            onTypeChanged: _onTypeChanged,
          ),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadInitial);
    }

    if (_items.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadInitial,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return _LoadMoreButton(
              isLoading: _isLoadingMore,
              onTap: _loadMore,
            );
          }
          return _HistoryCard(item: _items[index]);
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Barra de filtros
// ────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String? selectedCategory;
  final String? selectedType;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onTypeChanged;

  const _FilterBar({
    required this.selectedCategory,
    required this.selectedType,
    required this.onCategoryChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2ECE7), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FilterChip(
                label: 'Todos',
                selected: selectedCategory == null,
                onTap: () => onCategoryChanged(null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Sesiones',
                selected: selectedCategory == 'session',
                onTap: () => onCategoryChanged('session'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Canjes',
                selected: selectedCategory == 'claim',
                onTap: () => onCategoryChanged('claim'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FilterChip(
                label: 'Todo tipo',
                selected: selectedType == null,
                onTap: () => onTypeChanged(null),
                accent: AppColors.accentTeal,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Créditos',
                selected: selectedType == 'credit',
                onTap: () => onTypeChanged('credit'),
                accent: AppColors.accentTeal,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Débitos',
                selected: selectedType == 'debit',
                onTap: () => onTypeChanged('debit'),
                accent: AppColors.accentTeal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Tarjeta de un elemento del historial
// ────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;

  const _HistoryCard({required this.item});

  static final _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'es');

  @override
  Widget build(BuildContext context) {
    final isCredit = item.isCredit;
    final amountColor = isCredit ? AppColors.accentTeal : AppColors.error;
    final icon =
        isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline;

    final String subtitle = item.isSessionEntry
        ? (item.oscarName ?? 'Sesión')
        : (item.rewardName ?? 'Recompensa canjeada');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: amountColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.note ?? subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      item.isSessionEntry
                          ? Icons.timer_outlined
                          : Icons.card_giftcard,
                      size: 13,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDisabled,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _dateFormat.format(item.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '+' : '-'}${item.amount}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Estados: vacío, error y "cargar más"
// ────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes movimientos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuando completes sesiones o canjees recompensas,\nverás aquí tu historial.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _LoadMoreButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : OutlinedButton(
                onPressed: onTap,
                child: const Text('Cargar más'),
              ),
      ),
    );
  }
}
