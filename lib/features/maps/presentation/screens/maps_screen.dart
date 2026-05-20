// lib/features/maps/presentation/screens/maps_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';

class MapsScreen extends ConsumerStatefulWidget {
  const MapsScreen({super.key});

  @override
  ConsumerState<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends ConsumerState<MapsScreen> {
  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    setState(() {
      currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mientras obtiene ubicación
    if (currentLocation == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: currentLocation!,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.oscarebin.app',
                tileProvider: NetworkTileProvider(),
              ),

              // Marker usuario
              MarkerLayer(
                markers: [
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
                ],
              ),
            ],
          ),
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cercanos a ti',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: AppDimens.sm,
                  ),
                  ...List.generate(
                    2,
                    (i) => _OscarListTile(index: i),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OscarListTile extends StatelessWidget {
  final int index;

  const _OscarListTile({
    required this.index,
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
                  'Oscar #${100 + index}',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${(index + 1) * 120}m · Disponible',
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
