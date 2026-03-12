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
    this.heading,
    this.bleVisibleCount,
    this.cameraTrackingState,
    this.metadata = const <String, dynamic>{},
  });

  factory SensorSampleRecord.fromJson(Map<String, dynamic> json) {
    return SensorSampleRecord(
      sampleTime: json['sample_time'] as String? ?? '',
      gpsLat: (json['gps_lat'] as num?)?.toDouble(),
      gpsLng: (json['gps_lng'] as num?)?.toDouble(),
      gpsAccuracy: (json['gps_accuracy'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      bleVisibleCount: json['ble_visible_count'] as int?,
      cameraTrackingState: json['camera_tracking_state'] as String?,
      metadata: (json['metadata_json'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }

  final String sampleTime;
  final double? gpsLat;
  final double? gpsLng;
  final double? gpsAccuracy;
  final double? heading;
  final int? bleVisibleCount;
  final String? cameraTrackingState;
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

class SessionReplayBundle {
  const SessionReplayBundle({
    required this.session,
    required this.samples,
    required this.feedback,
  });

  final SessionReplayRecord session;
  final List<SensorSampleRecord> samples;
  final List<UserFeedbackRecord> feedback;
}
