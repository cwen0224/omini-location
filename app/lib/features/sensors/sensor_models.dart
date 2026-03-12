enum SensorStatus {
  ready,
  pending,
  blocked,
}

class MovementPoint {
  const MovementPoint({
    required this.x,
    required this.y,
    this.headingDegrees,
  });

  final double x;
  final double y;
  final double? headingDegrees;
}

class SensorCapability {
  const SensorCapability({
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
  });

  final String title;
  final String description;
  final SensorStatus status;
  final String icon;
}

class SensorReading {
  const SensorReading({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
