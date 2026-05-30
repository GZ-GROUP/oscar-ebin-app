import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/history_model.dart';
import '../data/history_service.dart';

final historyServiceProvider = Provider((ref) => HistoryService());

final historyProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final auth = ref.watch(authProvider);
  final service = ref.watch(historyServiceProvider);

  if (!auth.isAuthenticated || auth.token == null) {
    return [];
  }

  return service.getRecentHistory(auth.token!);
});
