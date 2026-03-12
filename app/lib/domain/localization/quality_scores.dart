class SensorQualityScores {
  const SensorQualityScores({
    required this.gps,
    required this.imu,
    required this.compass,
    required this.ble,
    required this.camera,
  });

  final double gps;
  final double imu;
  final double compass;
  final double ble;
  final double camera;

  Map<String, double> toMap() {
    return <String, double>{
      'gps': gps,
      'imu': imu,
      'compass': compass,
      'ble': ble,
      'camera': camera,
    };
  }
}
