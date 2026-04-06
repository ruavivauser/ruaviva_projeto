import 'package:dart_nostr/dart_nostr.dart';
import 'package:geocoding/geocoding.dart';

class NostrService {
  static const List<String> defaultRelays = [
    'wss://nos.lol',
    'wss://relay.damus.io',
    'wss://relay.snort.social',
    'wss://eden.nostr.land',
  ];

  /// Initialize and connect to relays
  Future<void> init() async {
    await Nostr.instance.services.relays.init(
      relaysUrl: defaultRelays,
      onRelayConnectionError: (url, error, relay) => print('❌ Relay error: $url - $error'),
      onRelayListening: (url, data, relay) => print('✅ Connected/Listening to: $url'),
    );
    print('ℹ️ Nostr Services initialized with ${defaultRelays.length} relays.');
  }

  /// Announce a new manifestation location
  Future<NostrEvent> publishManifestationAnnouncement({
    required String privateKey,
    required double lat,
    required double lon,
    String? customName,
  }) async {
    final keyPairs = NostrKeyPairs(private: privateKey);
    
    // Reverse geocode to get city
    String city = "Local Desconhecido";
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        city = placemarks.first.subAdministrativeArea ?? placemarks.first.locality ?? "Brasil";
      }
    } catch (_) {}

    final name = customName ?? "Manifestação em $city";

    final event = NostrEvent.fromPartialData(
      kind: 1,
      content: "📢 ANÚNCIO: #$name #RuaViva em $city. Participe anonimamente!",
      tags: [
        ['t', 'ruaviva'],
        ['t', 'anuncio'],
        ['t', 'manifestacao'],
        ['geodata', '$lat,$lon'],
        ['city', city],
        ['name', name],
      ],
      keyPairs: keyPairs,
    );

    Nostr.instance.services.relays.sendEventToRelays(event);
    return event;
  }

  /// Create and publish a universal check-in note (Kind 1)
  Future<NostrEvent> publishCheckIn({
    required String privateKey,
    required double lat,
    required double lon,
  }) async {
    final keyPairs = NostrKeyPairs(private: privateKey);
    
    // Create the unsigned event
    final event = NostrEvent.fromPartialData(
      kind: 1, // Kind 1: Short Text Note
      content: "Registro de Apoio #RuaViva #Brasil - Lat: $lat, Lon: $lon",
      tags: [
        ['t', 'ruaviva'],
        ['t', 'brasil'],
        ['t', 'manifestacao'],
        ['geodata', '$lat,$lon'], // Required for clustering
      ],
      keyPairs: keyPairs,
    );

    // Sign and publish
    Nostr.instance.services.relays.sendEventToRelays(event);
    return event;
  }

  /// Delete an event (Kind 5)
  Future<NostrEvent> deleteEvent({
    required String privateKey,
    required String eventId,
    String reason = "Erro de localização",
  }) async {
    final keyPairs = NostrKeyPairs(private: privateKey);
    
    final event = NostrEvent.fromPartialData(
      kind: 5, // Kind 5: Event Deletion
      content: reason,
      tags: [
        ['e', eventId],
      ],
      keyPairs: keyPairs,
    );

    Nostr.instance.services.relays.sendEventToRelays(event);
    return event;
  }

  /// Subscribe to all Rua Viva events (Announcements and Check-ins)
  Stream<NostrEvent> subscribeToGlobalEvents() {
    final filter = [
      NostrFilter(
        kinds: const [1, 5],
        t: const ['ruaviva', 'brasil', 'manifestacao'],
        limit: 1000,
      )
    ];

    final request = Nostr.instance.services.relays.startEventsSubscription(
      request: NostrRequest(filters: filter),
    );

    print('ℹ️ Started GLOBAL subscription with filter: $filter');
    return request.stream;
  }
}
