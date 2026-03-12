import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'beacon_registry.dart';
import 'remote_backend_config.dart';

class RemoteSyncService {
  RemoteSyncService._();

  static final RemoteSyncService instance = RemoteSyncService._();

  bool get isConfigured =>
      RemoteBackendConfig.enabled &&
      RemoteBackendConfig.supabaseUrl.isNotEmpty &&
      RemoteBackendConfig.supabaseAnonKey.isNotEmpty;

  Future<void> initialize() async {
    if (!isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: RemoteBackendConfig.supabaseUrl,
      anonKey: RemoteBackendConfig.supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  Future<void> uploadIssueReport({
    required String report,
    String errorSource = 'manual_report',
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    await BeaconRegistry.instance.load();
    final beaconSnapshot =
        BeaconRegistry.instance.beacons.map((beacon) => beacon.toJson()).toList();

    await client.from('app_errors').insert(<String, dynamic>{
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'platform': Platform.operatingSystem,
      'device_model': Platform.operatingSystemVersion,
      'error_source': errorSource,
      'error_message': report,
      'stack_trace': null,
      'context_json': <String, dynamic>{
        'uploaded_at': DateTime.now().toIso8601String(),
        'mode': 'manual_report',
      },
      'beacon_snapshot_json': beaconSnapshot,
    });
  }

  Future<void> upsertBeacon(SavedBeacon beacon) async {
    await client.from('beacon_registry').upsert(<String, dynamic>{
      'beacon_key': beacon.beaconKey,
      'display_name': beacon.displayName,
      'remote_id': beacon.remoteId,
      'device_name': beacon.deviceName,
      'manufacturer_hex': beacon.manufacturerHex,
      'service_data_hex': beacon.serviceDataHex,
      'last_rssi': beacon.lastRssi,
      'extra_json': <String, dynamic>{
        'saved_at': beacon.savedAt,
      },
    });
  }

  Future<void> deleteBeacon(String beaconKey) async {
    await client.from('beacon_registry').delete().eq('beacon_key', beaconKey);
  }

  Future<String> createTestSession({
    required String sessionName,
    required String testType,
    required Map<String, dynamic> metadata,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    await BeaconRegistry.instance.load();
    final beaconKeys =
        BeaconRegistry.instance.beacons.map((beacon) => beacon.beaconKey).toList();

    final inserted = await client
        .from('test_sessions')
        .insert(<String, dynamic>{
          'session_name': sessionName,
          'test_type': testType,
          'app_version': '${packageInfo.version}+${packageInfo.buildNumber}',
          'content_version': metadata['content_version']?.toString(),
          'beacon_keys': beaconKeys,
          'metadata_json': metadata,
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }
}
