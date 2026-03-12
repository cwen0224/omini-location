class GuidedTestStep {
  const GuidedTestStep({
    required this.title,
    required this.instruction,
    required this.actionType,
    this.targetDistanceM,
    this.targetHeadingDeg,
  });

  final String title;
  final String instruction;
  final String actionType;
  final double? targetDistanceM;
  final double? targetHeadingDeg;
}

class SensorSamplePayload {
  const SensorSamplePayload({
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sample_time': sampleTime,
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'gps_accuracy': gpsAccuracy,
      'gps_speed': gpsSpeed,
      'accel_x': accelX,
      'accel_y': accelY,
      'accel_z': accelZ,
      'gyro_x': gyroX,
      'gyro_y': gyroY,
      'gyro_z': gyroZ,
      'mag_x': magX,
      'mag_y': magY,
      'mag_z': magZ,
      'heading': heading,
      'ble_visible_count': bleVisibleCount,
      'ble_top_beacons': bleTopBeacons,
      'camera_tracking_state': cameraTrackingState,
      'camera_feature_score': cameraFeatureScore,
      'metadata_json': metadata,
    };
  }
}
