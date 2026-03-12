class SessionReplayRecord {
  const SessionReplayRecord({
    required this.sessionId,
    required this.sessionName,
    required this.testType,
    required this.createdAt,
    required this.metadata,
  });

  factory SessionReplayRecord.fromJson(Map<String, dynamic> json) {
    return SessionReplayRecord(
      sessionId: json['id'] as String,
      sessionName: json['session_name'] as String? ?? '',
      testType: json['test_type'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      metadata: (json['metadata_json'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }

  final String sessionId;
  final String sessionName;
  final String testType;
  final String createdAt;
  final Map<String, dynamic> metadata;
}

class SensorSampleRecord {
  const SensorSampleRecord({
    required this.sampleTime,
    this.gpsLat,
    this.gpsLng,
    this.gpsAccuracy,
    this.gpsSpeed,
    this.accelX,
    this.accelY,
    this.accelZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
    this.magX,
    this.magY,
    this.magZ,
    this.heading,
    this.bleVisibleCount,
    this.bleTopBeacons = const <Map<String, dynamic>>[],
    this.cameraTrackingState,
    this.cameraFeatureScore,
    this.metadata = const <String, dynamic>{},
  });

  factory SensorSampleRecord.fromJson(Map<String, dynamic> json) {
    return SensorSampleRecord(
      sampleTime: json['sample_time'] as String? ?? '',
      gpsLat: (json['gps_lat'] as num?)?.toDouble(),
      gpsLng: (json['gps_lng'] as num?)?.toDouble(),
      gpsAccuracy: (json['gps_accuracy'] as num?)?.toDouble(),
      gpsSpeed: (json['gps_speed'] as num?)?.toDouble(),
      accelX: (json['accel_x'] as num?)?.toDouble(),
      accelY: (json['accel_y'] as num?)?.toDouble(),
      accelZ: (json['accel_z'] as num?)?.toDouble(),
      gyroX: (json['gyro_x'] as num?)?.toDouble(),
      gyroY: (json['gyro_y'] as num?)?.toDouble(),
      gyroZ: (json['gyro_z'] as num?)?.toDouble(),
      magX: (json['mag_x'] as num?)?.toDouble(),
      magY: (json['mag_y'] as num?)?.toDouble(),
      magZ: (json['mag_z'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      bleVisibleCount: json['ble_visible_count'] as int?,
      bleTopBeacons: (json['ble_top_beacons'] as List<dynamic>?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          const <Map<String, dynamic>>[],
      cameraTrackingState: json['camera_tracking_state'] as String?,
      cameraFeatureScore: (json['camera_feature_score'] as num?)?.toDouble(),
      metadata: (json['metadata_json'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }

  final String sampleTime;
  final double? gpsLat;
  final double? gpsLng;
  final double? gpsAccuracy;
  final double? gpsSpeed;
  final double? accelX;
  final double? accelY;
  final double? accelZ;
  final double? gyroX;
  final double? gyroY;
  final double? gyroZ;
  final double? magX;
  final double? magY;
  final double? magZ;
  final double? heading;
  final int? bleVisibleCount;
  final List<Map<String, dynamic>> bleTopBeacons;
  final String? cameraTrackingState;
  final double? cameraFeatureScore;
  final Map<String, dynamic> metadata;
}

class UserFeedbackRecord {
  const UserFeedbackRecord({
    required this.feedbackType,
    required this.value,
    this.comment,
  });

  factory UserFeedbackRecord.fromJson(Map<String, dynamic> json) {
    return UserFeedbackRecord(
      feedbackType: json['feedback_type'] as String? ?? '',
      value: json['value'] as String? ?? '',
      comment: json['comment'] as String?,
    );
  }

  final String feedbackType;
  final String value;
  final String? comment;
}

class ActionSegmentRecord {
  const ActionSegmentRecord({
    required this.segmentId,
    required this.actionType,
    required this.startedAt,
    this.endedAt,
    this.targetDistanceM,
    this.targetHeadingDeg,
    this.expectedBehavior,
    this.operatorConfirmed = false,
    this.metadata = const <String, dynamic>{},
  });

  factory ActionSegmentRecord.fromJson(Map<String, dynamic> json) {
    return ActionSegmentRecord(
      segmentId: json['id'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      startedAt: json['started_at'] as String? ?? '',
      endedAt: json['ended_at'] as String?,
      targetDistanceM: (json['target_distance_m'] as num?)?.toDouble(),
      targetHeadingDeg: (json['target_heading_deg'] as num?)?.toDouble(),
      expectedBehavior: json['expected_behavior'] as String?,
      operatorConfirmed: json['operator_confirmed'] as bool? ?? false,
      metadata: (json['metadata_json'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }

  final String segmentId;
  final String actionType;
  final String startedAt;
  final String? endedAt;
  final double? targetDistanceM;
  final double? targetHeadingDeg;
  final String? expectedBehavior;
  final bool operatorConfirmed;
  final Map<String, dynamic> metadata;
}

class GroundTruthPointRecord {
  const GroundTruthPointRecord({
    required this.pointLabel,
    required this.source,
    this.mapX,
    this.mapY,
    this.mapZ,
    this.headingDeg,
  });

  factory GroundTruthPointRecord.fromJson(Map<String, dynamic> json) {
    return GroundTruthPointRecord(
      pointLabel: json['point_label'] as String? ?? '',
      source: json['source'] as String? ?? '',
      mapX: (json['map_x'] as num?)?.toDouble(),
      mapY: (json['map_y'] as num?)?.toDouble(),
      mapZ: (json['map_z'] as num?)?.toDouble(),
      headingDeg: (json['heading_deg'] as num?)?.toDouble(),
    );
  }

  final String pointLabel;
  final String source;
  final double? mapX;
  final double? mapY;
  final double? mapZ;
  final double? headingDeg;
}

class DerivedMetricRecord {
  const DerivedMetricRecord({
    this.positionErrorM,
    this.headingErrorDeg,
    this.bleRssiVariance,
    this.imuDriftScore,
    this.compassInterferenceScore,
    this.cameraRelocalizationSuccessRate,
  });

  factory DerivedMetricRecord.fromJson(Map<String, dynamic> json) {
    return DerivedMetricRecord(
      positionErrorM: (json['position_error_m'] as num?)?.toDouble(),
      headingErrorDeg: (json['heading_error_deg'] as num?)?.toDouble(),
      bleRssiVariance: (json['ble_rssi_variance'] as num?)?.toDouble(),
      imuDriftScore: (json['imu_drift_score'] as num?)?.toDouble(),
      compassInterferenceScore: (json['compass_interference_score'] as num?)?.toDouble(),
      cameraRelocalizationSuccessRate:
          (json['camera_relocalization_success_rate'] as num?)?.toDouble(),
    );
  }

  final double? positionErrorM;
  final double? headingErrorDeg;
  final double? bleRssiVariance;
  final double? imuDriftScore;
  final double? compassInterferenceScore;
  final double? cameraRelocalizationSuccessRate;
}

class SessionReplayBundle {
  const SessionReplayBundle({
    required this.session,
    required this.samples,
    required this.feedback,
    required this.segments,
    required this.groundTruthPoints,
    required this.derivedMetrics,
  });

  final SessionReplayRecord session;
  final List<SensorSampleRecord> samples;
  final List<UserFeedbackRecord> feedback;
  final List<ActionSegmentRecord> segments;
  final List<GroundTruthPointRecord> groundTruthPoints;
  final List<DerivedMetricRecord> derivedMetrics;
}
