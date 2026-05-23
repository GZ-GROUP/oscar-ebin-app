// lib/features/maps/presentation/screens/maps_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../maps/providers/maps_provider.dart';

class MapsScreen extends ConsumerStatefulWidget {
  const MapsScreen({super.key});

  @override
  ConsumerState<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends ConsumerState<MapsScreen> {
  LatLng? currentLocation;
  String? locationError;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _getCurrentLocation() async {
    _safeSetState(() {
      isLoading = true;
      locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _safeSetState(() {
          locationError =
              'El servicio de ubicación está desactivado en tu sistema.';
          isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _safeSetState(() {
          locationError =
              'Permiso de ubicación denegado. Activa el permiso para continuar.';
          isLoading = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _safeSetState(() {
          locationError =
              'Permiso de ubicación denegado permanentemente. Habilítalo desde la configuración.';
          isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      _safeSetState(() {
        currentLocation = LatLng(
          position.latitude,
          position.longitude,
        );
        isLoading = false;
      });
    } catch (error) {
      _safeSetState(() {
        locationError =
            'No se pudo obtener la ubicación. Instala GeoClue2 y verifica permisos: ${error.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (locationError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Localizador de Oscars'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locationError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _getCurrentLocation,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (currentLocation == null) {
      return const Scaffold(
        body: Center(
          child: Text('No se encontró ubicación.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Localizador de Oscars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final oscarLocations = ref.watch(oscarLocationsProvider);

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: currentLocation!,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.oscarebin.app',
                    tileProvider: NetworkTileProvider(),
                  ),
                  // Markers de los Oscars obtenidos de la API
                  MarkerLayer(
                    markers: [
                      // Marcador del usuario
                      Marker(
                        point: currentLocation!,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.my_location_rounded,
                          size: 40,
                          color: Colors.blue,
                        ),
                      ),
                      // Marcadores de los Oscars
                      ...oscarLocations.when(
                        data: (oscars) {
                          return oscars
                              .map(
                                (oscar) => Marker(
                                  point: LatLng(oscar.lat, oscar.lng),
                                  width: 80,
                                  height: 80,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList();
                        },
                        loading: () => [],
                        error: (err, stack) => [],
                      ),
                    ],
                  ),
                ],
              ),
              // Panel con lista de Oscars cercanos
              Positioned(
                bottom: AppDimens.navBarHeight + AppDimens.navFabSize / 2,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(AppDimens.md),
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppDimens.radiusXl,
                    ),
                    boxShadow: [
                      const BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: oscarLocations.when(
                    data: (oscars) {
                      if (oscars.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Oscars cercanos',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppDimens.sm),
                            Text(
                              'No hay oscars disponibles',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Oscars cercanos',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDimens.sm),
                          ...oscars
                              .take(3)
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (entry) => _OscarListTile(
                                  oscar: entry.value,
                                  distance: '${(entry.key + 1) * 120}m',
                                ),
                              )
                              .toList(),
                        ],
                      );
                    },
                    loading: () {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Oscars cercanos',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDimens.sm),
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ],
                      );
                    },
                    error: (err, stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Oscars cercanos',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDimens.sm),
                          Text(
                            'Error al cargar oscars',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OscarListTile extends StatelessWidget {
  final dynamic oscar;
  final String distance;

  const _OscarListTile({
    required this.oscar,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(
                AppDimens.radiusMd,
              ),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  oscar.code,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '$distance · ${oscar.status}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.navigation_rounded,
              size: 14,
            ),
            label: const Text('IR'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
