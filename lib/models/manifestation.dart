import 'package:latlong2/latlong.dart';

class Manifestation {
  final String id;
  final String name;
  final String city;
  final LatLng location;
  final DateTime startTime;
  final String organizerPubkey;
  final int attendeeCount;

  Manifestation({
    required this.id,
    required this.name,
    required this.city,
    required this.location,
    required this.startTime,
    required this.organizerPubkey,
    this.attendeeCount = 0,
  });

  factory Manifestation.fromNostrEvent(Map<String, dynamic> event) {
    // Parsing logic for specific tags like geodata and city
    return Manifestation(
      id: event['id'],
      name: event['name'] ?? "Manifestação",
      city: event['city'] ?? "Brasil",
      location: LatLng(event['lat'], event['lon']),
      startTime: DateTime.fromMillisecondsSinceEpoch(event['created_at'] * 1000),
      organizerPubkey: event['pubkey'],
    );
  }

  double get lat => location.latitude;
  double get lon => location.longitude;
}
