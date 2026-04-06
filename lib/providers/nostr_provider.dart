import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:latlong2/latlong.dart';
import '../services/nostr_service.dart';
import '../models/manifestation.dart';

class CheckInEvent {
  final String id;
  final String pubkey;
  final double lat;
  final double lon;
  final DateTime timestamp;
  final String content;

  CheckInEvent({
    required this.id,
    required this.pubkey,
    required this.lat,
    required this.lon,
    required this.timestamp,
    required this.content,
  });

  factory CheckInEvent.fromNostrEvent(NostrEvent event) {
    double lat = 0;
    double lon = 0;
    
    final geoTag = event.tags?.firstWhere(
      (tag) => tag.isNotEmpty && tag[0] == 'geodata',
      orElse: () => [],
    );

    if (geoTag != null && geoTag.length > 1) {
      final parts = geoTag[1].split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0]) ?? 0;
        lon = double.tryParse(parts[1]) ?? 0;
      }
    }

    return CheckInEvent(
      id: event.id ?? "",
      pubkey: event.pubkey ?? "",
      lat: lat,
      lon: lon,
      timestamp: event.createdAt ?? DateTime.now(),
      content: event.content ?? "",
    );
  }
}

class NostrState {
  final List<Manifestation> manifestations;
  final List<CheckInEvent> checkIns;
  final bool isLoading;

  NostrState({
    this.manifestations = const [],
    this.checkIns = const [],
    this.isLoading = false,
  });

  NostrState copyWith({
    List<Manifestation>? manifestations,
    List<CheckInEvent>? checkIns,
    bool? isLoading,
  }) {
    return NostrState(
      manifestations: manifestations ?? this.manifestations,
      checkIns: checkIns ?? this.checkIns,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Calculate total voices part of clusters of 100+
  int get totalBrazilianVoices {
    if (checkIns.isEmpty) return 0;

    // Simple clustering logic:
    // 1. Group check-ins by a grid or proximity
    // For simplicity, we'll use a 5km radius logic
    final List<List<CheckInEvent>> clusters = [];
    final List<CheckInEvent> processed = [];

    for (var checkIn in checkIns) {
      if (processed.contains(checkIn)) continue;

      final List<CheckInEvent> currentCluster = [checkIn];
      processed.add(checkIn);

      // Find all check-ins within 5km
      for (var other in checkIns) {
        if (processed.contains(other)) continue;
        
        final distance = const Distance().as(
          LengthUnit.Meter,
          LatLng(checkIn.lat, checkIn.lon),
          LatLng(other.lat, other.lon),
        );

        if (distance <= 5000) { // 5km
          currentCluster.add(other);
          processed.add(other);
        }
      }
      clusters.add(currentCluster);
    }

    // Sum sizes of clusters >= 100
    int total = 0;
    for (var cluster in clusters) {
      if (cluster.length >= 100) {
        total += cluster.length;
      }
    }
    return total;
  }
}

class NostrNotifier extends Notifier<NostrState> {
  bool _isInitialized = false;

  @override
  NostrState build() {
    _init();
    return NostrState(isLoading: true);
  }

  NostrService get _nostrService => ref.read(nostrServiceProvider);

  Future<void> _init() async {
    if (_isInitialized) return;
    await _nostrService.init();
    _isInitialized = false; // Reset to allow multiple calls if needed, or keep true
    _isInitialized = true;
    
    state = state.copyWith(isLoading: false);

    _nostrService.subscribeToGlobalEvents().listen((event) {
      final tags = event.tags ?? [];
      final isAnnouncement = tags.any((t) => t.contains('anuncio'));
      final isDeletion = event.kind == 5;
      
      if (isDeletion) {
        final deletedIds = tags.where((t) => t[0] == 'e').map((t) => t[1]).toList();
        print('🗑️ Received Deletion Event (Kind 5) for: $deletedIds');
        state = state.copyWith(
          manifestations: state.manifestations.where((m) => !deletedIds.contains(m.id)).toList(),
          checkIns: state.checkIns.where((c) => !deletedIds.contains(c.id)).toList(),
        );
        return;
      }

      if (isAnnouncement) {
        // Legacy: we ignore manifestations now, but might keep for background
      } else {
        final checkIn = CheckInEvent.fromNostrEvent(event);
        if (checkIn.lat != 0 && checkIn.lon != 0) {
          if (!state.checkIns.any((e) => e.id == checkIn.id)) {
            state = state.copyWith(
              checkIns: [...state.checkIns, checkIn],
            );
          }
        }
      }
    });
  }

  Manifestation? _parseManifestation(NostrEvent event) {
    try {
      final tags = event.tags ?? [];
      final geoTag = tags.firstWhere((t) => t[0] == 'geodata');
      final cityTag = tags.firstWhere((t) => t[0] == 'city', orElse: () => ['city', 'Brasil']);
      final nameTag = tags.firstWhere((t) => t[0] == 'name', orElse: () => ['name', 'Manifestação']);
      
      final coords = geoTag[1].split(',');
      return Manifestation(
        id: event.id ?? "",
        name: nameTag[1],
        city: cityTag[1],
        location: LatLng(double.parse(coords[0]), double.parse(coords[1])),
        startTime: event.createdAt ?? DateTime.now(),
        organizerPubkey: event.pubkey ?? "",
      );
    } catch (_) {
      return null;
    }
  }

  Future<NostrEvent> publishCheckIn({
    required String privateKey,
    required double lat,
    required double lon,
  }) async {
    return await _nostrService.publishCheckIn(
      privateKey: privateKey,
      lat: lat,
      lon: lon,
    );
  }

  Future<NostrEvent> announceManifestation({
    required String privateKey,
    required double lat,
    required double lon,
    String? name,
  }) async {
    return await _nostrService.publishManifestationAnnouncement(
      privateKey: privateKey,
      lat: lat,
      lon: lon,
      customName: name,
    );
  }

  Future<NostrEvent> deleteManifestation({
    required String privateKey,
    required String eventId,
  }) async {
    return await _nostrService.deleteEvent(
      privateKey: privateKey,
      eventId: eventId,
    );
  }
}

final nostrServiceProvider = Provider((ref) => NostrService());

final nostrProvider = NotifierProvider<NostrNotifier, NostrState>(() {
  return NostrNotifier();
});
