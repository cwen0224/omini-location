import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedBeacon {
  const SavedBeacon({
    required this.beaconKey,
    required this.displayName,
    required this.remoteId,
    required this.deviceName,
    required this.manufacturerHex,
    required this.serviceDataHex,
    required this.lastRssi,
    required this.savedAt,
  });

  factory SavedBeacon.fromJson(Map<String, dynamic> json) {
    return SavedBeacon(
      beaconKey: json['beacon_key'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      remoteId: json['remote_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      manufacturerHex: json['manufacturer_hex'] as String? ?? '',
      serviceDataHex: json['service_data_hex'] as String? ?? '',
      lastRssi: json['last_rssi'] as int? ?? 0,
      savedAt: json['saved_at'] as String? ?? '',
    );
  }

  final String beaconKey;
  final String displayName;
  final String remoteId;
  final String deviceName;
  final String manufacturerHex;
  final String serviceDataHex;
  final int lastRssi;
  final String savedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'beacon_key': beaconKey,
      'display_name': displayName,
      'remote_id': remoteId,
      'device_name': deviceName,
      'manufacturer_hex': manufacturerHex,
      'service_data_hex': serviceDataHex,
      'last_rssi': lastRssi,
      'saved_at': savedAt,
    };
  }
}

class BeaconRegistry {
  BeaconRegistry._();

  static const String _storageKey = 'saved_beacons_v1';
  static final BeaconRegistry instance = BeaconRegistry._();

  List<SavedBeacon> _beacons = const <SavedBeacon>[];

  List<SavedBeacon> get beacons => List<SavedBeacon>.unmodifiable(_beacons);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _beacons = const <SavedBeacon>[];
      return;
    }

    final data = jsonDecode(raw) as List<dynamic>;
    _beacons = data
        .map((item) => SavedBeacon.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBeacon(SavedBeacon beacon) async {
    final next = List<SavedBeacon>.from(_beacons);
    final index = next.indexWhere((item) => item.beaconKey == beacon.beaconKey);
    if (index >= 0) {
      next[index] = beacon;
    } else {
      next.add(beacon);
    }
    _beacons = next;
    await _persist();
  }

  Future<void> removeBeacon(String beaconKey) async {
    _beacons = _beacons.where((item) => item.beaconKey != beaconKey).toList();
    await _persist();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = jsonEncode(_beacons.map((item) => item.toJson()).toList());
    await preferences.setString(_storageKey, raw);
  }
}
