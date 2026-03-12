import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'beacon_registry.dart';
import '../features/testing/guided_test_models.dart';
import '../features/testing/session_replay_models.dart';
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

  Future<String> createGuidedTestSession({
    required String sessionName,
    required String locationLabel,
    required Map<String, dynamic> metadata,
  }) async {
    return createTestSession(
      sessionName: sessionName,
      testType: 'guided_localization_test',
      metadata: <String, dynamic>{
        ...metadata,
        'location_label': locationLabel,
        'workflow': 'guided_localization_test',
      },
    );
  }

  Future<String> startActionSegment({
    required String sessionId,
    required GuidedTestStep step,
    required Map<String, dynamic> metadata,
  }) async {
    final inserted = await client
        .from('action_segments')
        .insert(<String, dynamic>{
          'session_id': sessionId,
          'action_type': step.actionType,
          'started_at': DateTime.now().toIso8601String(),
          'target_distance_m': step.targetDistanceM,
          'target_heading_deg': step.targetHeadingDeg,
          'expected_behavior': step.instruction,
          'metadata_json': <String, dynamic>{
            'title': step.title,
            ...metadata,
          },
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<void> completeActionSegment({
    required String segmentId,
    required bool operatorConfirmed,
    required Map<String, dynamic> metadata,
  }) async {
    await client.from('action_segments').update(<String, dynamic>{
      'ended_at': DateTime.now().toIso8601String(),
      'operator_confirmed': operatorConfirmed,
      'metadata_json': metadata,
    }).eq('id', segmentId);
  }

  Future<void> insertSensorSample({
    required String sessionId,
    String? segmentId,
    required SensorSamplePayload sample,
  }) async {
    await client.from('sensor_samples').insert(<String, dynamic>{
      'session_id': sessionId,
      'segment_id': segmentId,
      ...sample.toJson(),
    });
  }

  Future<void> insertUserFeedback({
    required String sessionId,
    String? segmentId,
    required String feedbackType,
    required String value,
    String? comment,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await client.from('user_feedback').insert(<String, dynamic>{
      'session_id': sessionId,
      'segment_id': segmentId,
      'feedback_type': feedbackType,
      'value': value,
      'comment': comment,
      'metadata_json': metadata,
    });
  }

  Future<void> insertGroundTruthPoint({
    required String sessionId,
    String? segmentId,
    required String pointLabel,
    required String source,
    double? mapX,
    double? mapY,
    double? mapZ,
    double? headingDeg,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await client.from('ground_truth_points').insert(<String, dynamic>{
      'session_id': sessionId,
      'segment_id': segmentId,
      'point_label': pointLabel,
      'map_x': mapX,
      'map_y': mapY,
      'map_z': mapZ,
      'heading_deg': headingDeg,
      'source': source,
      'metadata_json': metadata,
    });
  }

  Future<List<SessionReplayRecord>> fetchRecentSessions({
    int limit = 10,
  }) async {
    final rows = await client
        .from('test_sessions')
        .select('id, session_name, test_type, created_at, metadata_json')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>)
        .map((item) => SessionReplayRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SessionReplayBundle> fetchSessionReplayBundle(String sessionId) async {
    final sessionRow = await client
        .from('test_sessions')
        .select('id, session_name, test_type, created_at, metadata_json')
        .eq('id', sessionId)
        .single();
    final samplesRows = await client
        .from('sensor_samples')
        .select(
          'sample_time, gps_lat, gps_lng, gps_accuracy, gps_speed, accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z, mag_x, mag_y, mag_z, heading, ble_visible_count, ble_top_beacons, camera_tracking_state, camera_feature_score, metadata_json',
        )
        .eq('session_id', sessionId)
        .order('sample_time');
    final feedbackRows = await client
        .from('user_feedback')
        .select('feedback_type, value, comment')
        .eq('session_id', sessionId)
        .order('created_at');
    final segmentRows = await client
        .from('action_segments')
        .select(
          'id, action_type, started_at, ended_at, target_distance_m, target_heading_deg, expected_behavior, operator_confirmed, metadata_json',
        )
        .eq('session_id', sessionId)
        .order('started_at');
    final groundTruthRows = await client
        .from('ground_truth_points')
        .select('point_label, source, map_x, map_y, map_z, heading_deg')
        .eq('session_id', sessionId)
        .order('created_at');
    final derivedMetricRows = await client
        .from('derived_metrics')
        .select(
          'position_error_m, heading_error_deg, ble_rssi_variance, imu_drift_score, compass_interference_score, camera_relocalization_success_rate',
        )
        .eq('session_id', sessionId)
        .order('created_at');

    return SessionReplayBundle(
      session: SessionReplayRecord.fromJson(sessionRow),
      samples: (samplesRows as List<dynamic>)
          .map((item) => SensorSampleRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      feedback: (feedbackRows as List<dynamic>)
          .map((item) => UserFeedbackRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      segments: (segmentRows as List<dynamic>)
          .map((item) => ActionSegmentRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      groundTruthPoints: (groundTruthRows as List<dynamic>)
          .map((item) => GroundTruthPointRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      derivedMetrics: (derivedMetricRows as List<dynamic>)
          .map((item) => DerivedMetricRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
