import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class IdentityService {
  static const String _nsecKey = 'nostr_nsec';
  static const String _creationTimeKey = 'nostr_creation_timestamp';
  static const String _lastCheckInKey = 'nostr_last_checkin_timestamp';
  static const String _fixedSalt = "ManifestaCheck_2026_Salt_ProtestoReal";

  final _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Gets the existing private key or generates a new one based on Device ID
  Future<String?> getPrivateKey() async {
    return await _secureStorage.read(key: _nsecKey);
  }

  /// Gets the creation timestamp
  Future<DateTime?> getCreationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_creationTimeKey);
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }

  /// Logic to generate or recover identity
  Future<void> initializeIdentity() async {
    final existingKey = await getPrivateKey();
    if (existingKey != null) return;

    // Generate new identity
    final deviceId = await _getDeviceId();
    final seed = _generateSeed(deviceId);

    // Create Nostr KeyPair from seed
    final keyPair = NostrKeyPairs(private: seed);

    await _secureStorage.write(key: _nsecKey, value: keyPair.private);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_creationTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Reset identity (WARNING: potentially destructive)
  Future<void> resetIdentity() async {
    await _secureStorage.delete(key: _nsecKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_creationTimeKey);
    await initializeIdentity();
  }

  /// Check anti-spam rules (Initial 24h + 24h between check-ins)
  Future<bool> canPerformCheckIn() async {
    final creationTime = await getCreationTime();
    if (creationTime == null) return false;

    final initialWait = DateTime.now().difference(creationTime).inHours >= 24;
    
    final lastCheckIn = await getLastCheckInTime();
    bool cooldownPassed = true;
    if (lastCheckIn != null) {
      cooldownPassed = DateTime.now().difference(lastCheckIn).inHours >= 24;
    }

    // Both initial 24h AND last check-in 24h must have passed
    return initialWait && cooldownPassed;
  }

  Future<void> saveLastCheckInTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckInKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastCheckInTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_lastCheckInKey);
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }

  Future<String> _getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id; // ANDROID_ID
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    }
    return 'unknown_platform_device';
  }

  String _generateSeed(String deviceId) {
    final bytes = utf8.encode(deviceId + _fixedSalt);
    final digest = sha256.convert(bytes);
    return digest.toString(); // Hex string suitable for private key
  }
}
