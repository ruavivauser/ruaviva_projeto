import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import '../providers/nostr_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  late final _animatedMapController = AnimatedMapController(vsync: this);

  @override
  Widget build(BuildContext context) {
    final nostrState = ref.watch(nostrProvider);
    final checkIns = nostrState.checkIns;
    
    // Default center: Brasília
    final centerLatLng = const LatLng(-15.7801, -47.9292); 
    
    final colorScheme = Theme.of(context).colorScheme;

    final List<Marker> markers = checkIns.map((e) {
      return Marker(
        point: LatLng(e.lat, e.lon),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary, width: 1),
          ),
          child: Icon(Icons.circle, color: colorScheme.primary, size: 12),
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("MAPA DE APOIO"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.my_location, size: 28),
              onPressed: () => _animatedMapController.animateTo(dest: centerLatLng),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _animatedMapController.mapController,
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: 4.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.rua_viva',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (nostrState.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: Text("${checkIns.length} APOIOS REGISTRADOS", style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        icon: const Icon(Icons.hub, size: 28),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 12,
      ),
    );
  }
}
