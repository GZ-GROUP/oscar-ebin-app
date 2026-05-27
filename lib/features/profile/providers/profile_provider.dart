import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_model.dart';
import '../../auth/data/auth_service.dart';

final profileServiceProvider = Provider((ref) => AuthService());

final profileStatsProvider = FutureProvider<ProfileStats?>((ref) async {
  final auth = ref.watch(authProvider);
  final service = ref.watch(profileServiceProvider);

  if (!auth.isAuthenticated || auth.token == null) {
    return null;
  }

  return await service.profileStats(auth.token!);
});
