import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

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

class GpsTrackProjector {
  GpsTrackProjector({
    required this.originLat,
    required this.originLng,
  });

  final double originLat;
  final double originLng;

  MovementPoint project({
    required double lat,
    required double lng,
    double? headingDegrees,
  }) {
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng =
        111320.0 * math.cos(originLat * math.pi / 180.0);

    return MovementPoint(
      x: (lng - originLng) * metersPerDegreeLng,
      y: (lat - originLat) * metersPerDegreeLat,
      headingDegrees: headingDegrees,
    );
  }
}

class GpsTrackAccumulator {
  GpsTrackProjector? _projector;
  final List<_GpsSample> _recentSamples = <_GpsSample>[];

  MovementPoint? add(Position position) {
    if (!position.latitude.isFinite || !position.longitude.isFinite) {
      return null;
    }
    if (!position.accuracy.isFinite || position.accuracy <= 0) {
      return null;
    }
    if (position.accuracy > 35) {
      return null;
    }

    _projector ??= GpsTrackProjector(
      originLat: position.latitude,
      originLng: position.longitude,
    );
    final projected = _projector!.project(
      lat: position.latitude,
      lng: position.longitude,
      headingDegrees: position.heading.isFinite ? position.heading : null,
    );

    if (_recentSamples.isNotEmpty) {
      final previous = _recentSamples.last.point;
      final jumpDistance = math.sqrt(
        math.pow(projected.x - previous.x, 2) +
            math.pow(projected.y - previous.y, 2),
      );
      if (jumpDistance > 18 && position.accuracy > 12) {
        return null;
      }
    }

    _recentSamples.add(_GpsSample(point: projected));
    if (_recentSamples.length > 5) {
      _recentSamples.removeAt(0);
    }

    final smoothX = _recentSamples
            .map((sample) => sample.point.x)
            .reduce((sum, value) => sum + value) /
        _recentSamples.length;
    final smoothY = _recentSamples
            .map((sample) => sample.point.y)
            .reduce((sum, value) => sum + value) /
        _recentSamples.length;

    final smoothedPoint = MovementPoint(
      x: smoothX,
      y: smoothY,
      headingDegrees: projected.headingDegrees,
    );

    if (_recentSamples.length > 1) {
      final previous = _recentSamples[_recentSamples.length - 2].point;
      final moveDistance = math.sqrt(
        math.pow(smoothedPoint.x - previous.x, 2) +
            math.pow(smoothedPoint.y - previous.y, 2),
      );
      if (moveDistance < 0.8 && position.speed < 0.6) {
        return null;
      }
    }

    return smoothedPoint;
  }

  void reset() {
    _projector = null;
    _recentSamples.clear();
  }
}

class _GpsSample {
  const _GpsSample({required this.point});

  final MovementPoint point;
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
