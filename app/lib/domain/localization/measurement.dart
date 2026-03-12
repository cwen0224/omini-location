enum MeasurementType {
  gps,
  bleZone,
  bleRange,
  compass,
  cameraPose,
}

class LocalizationMeasurement {
  const LocalizationMeasurement({
    required this.type,
    required this.timestamp,
    required this.quality,
    this.positionX,
    this.positionY,
    this.positionZ,
    this.headingDeg,
    this.velocityX,
    this.velocityY,
    this.velocityZ,
    this.metadata = const <String, dynamic>{},
  });

  final MeasurementType type;
  final DateTime timestamp;
  final double quality;
  final double? positionX;
  final double? positionY;
  final double? positionZ;
  final double? headingDeg;
  final double? velocityX;
  final double? velocityY;
  final double? velocityZ;
  final Map<String, dynamic> metadata;
}
