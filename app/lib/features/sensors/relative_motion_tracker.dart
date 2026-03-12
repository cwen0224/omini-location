import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:sensors_plus/sensors_plus.dart';

import 'sensor_models.dart';

class RelativeMotionTracker {
  final List<MovementPoint> _points = <MovementPoint>[
    const MovementPoint(x: 0, y: 0),
  ];
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  DateTime? _lastMotionAt;
  double? _headingDegrees;
  Offset _position = Offset.zero;
  bool _started = false;

  List<MovementPoint> get points => List<MovementPoint>.unmodifiable(_points);

  void start(void Function() onUpdate) {
    if (_started) {
      return;
    }
    _started = true;

    _magnetometerSubscription = magnetometerEvents.listen((event) {
      final heading = math.atan2(event.y, event.x) * 180 / math.pi;
      _headingDegrees = (heading + 360) % 360;
      onUpdate();
    });

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final movementStrength = (magnitude - 9.81).abs();
      final now = DateTime.now();
      final elapsedMs = _lastMotionAt == null
          ? 999
          : now.difference(_lastMotionAt!).inMilliseconds;

      if (_headingDegrees == null || movementStrength < 1.1 || elapsedMs < 180) {
        return;
      }

      final radians = _headingDegrees! * math.pi / 180;
      final step = (movementStrength * 0.055).clamp(0.08, 0.35);
      _position = Offset(
        _position.dx + math.cos(radians) * step,
        _position.dy + math.sin(radians) * step,
      );
      _points.add(
        MovementPoint(
          x: _position.dx,
          y: _position.dy,
          headingDegrees: _headingDegrees,
        ),
      );
      if (_points.length > 120) {
        _points.removeAt(0);
      }
      _lastMotionAt = now;
      onUpdate();
    });
  }

  void reset() {
    _position = Offset.zero;
    _points
      ..clear()
      ..add(const MovementPoint(x: 0, y: 0));
    _lastMotionAt = null;
  }

  Future<void> dispose() async {
    await _accelerometerSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
  }
}
