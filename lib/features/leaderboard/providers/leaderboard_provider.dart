import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/ranking_model.dart';
import '../../auth/data/auth_service.dart';

final rankingServiceProvider = Provider((ref) => AuthService());

final rankingProvider = FutureProvider<RankingResponse?>((ref) async {
  final auth = ref.watch(authProvider);
  final service = ref.watch(rankingServiceProvider);

  if (!auth.isAuthenticated || auth.token == null) {
    return null;
  }

  return await service.ranking(auth.token!);
});
