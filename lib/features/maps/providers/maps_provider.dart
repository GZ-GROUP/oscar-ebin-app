import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maps_service.dart';
import '../domain/models/oscar.dart';

final mapsServiceProvider = Provider((ref) => MapsService());

final oscarLocationsProvider = FutureProvider<List<Oscar>>((ref) async {
  final service = ref.watch(mapsServiceProvider);
  return service.getOscarLocations();
});
