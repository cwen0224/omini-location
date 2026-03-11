enum SensorStatus {
  ready,
  pending,
  blocked,
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
