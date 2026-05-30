import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ranking_model.dart';
import '../../auth/data/auth_service.dart';

final rankingServiceProvider = Provider((ref) => AuthService());

final rankingProvider = FutureProvider<RankingResponse?>((ref) async {
  final service = ref.watch(rankingServiceProvider);
  return await service.ranking();
});
