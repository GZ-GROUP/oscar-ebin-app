import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maps_service.dart';
import '../domain/models/oscar.dart';
import '../../auth/providers/auth_provider.dart';

final mapsServiceProvider = Provider((ref) => MapsService());

final oscarLocationsProvider = FutureProvider<List<Oscar>>((ref) async {
  final auth = ref.watch(authProvider);
  final service = ref.read(mapsServiceProvider);

  // Si no está autenticado o no tiene token, retorna lista vacía
  if (!auth.isAuthenticated || auth.token == null) {
    return [];
  }

  return service.getOscarLocations(auth.token!);
});
