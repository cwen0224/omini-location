import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:sensors_plus/sensors_plus.dart';

import 'sensor_models.dart';

class RelativeMotionTracker {
  final List<MovementPoint> _points = <MovementPoint>[
    const MovementPoint(x: 0, y: 0),
  ];
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  DateTime? _lastSampleAt;
  DateTime? _lastPointAt;
  double? _headingDegrees;
  Offset _position = Offset.zero;
  Offset _velocity = Offset.zero;
  bool _started = false;

  List<MovementPoint> get points => List<MovementPoint>.unmodifiable(_points);

  void start(void Function() onUpdate) {
    if (_started) {
      return;
    }
    _started = true;

    _magnetometerSubscription = magnetometerEvents.listen((event) {
      final heading = (math.atan2(event.y, event.x) * 180 / math.pi + 360) % 360;
      _headingDegrees = _headingDegrees == null
          ? heading
          : _blendAngle(_headingDegrees!, heading, 0.14);
      onUpdate();
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      final now = DateTime.now();
      if (_headingDegrees == null || _lastSampleAt == null) {
        return;
      }

      final dtSeconds = now.difference(_lastSampleAt!).inMilliseconds / 1000;
      if (dtSeconds <= 0 || dtSeconds > 0.25) {
        return;
      }

      _headingDegrees = (_headingDegrees! + event.z * 180 / math.pi * dtSeconds) % 360;
    });

    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      final now = DateTime.now();
      final dtSeconds = _lastSampleAt == null
          ? 0.05
          : now.difference(_lastSampleAt!).inMilliseconds / 1000;
      _lastSampleAt = now;

      if (_headingDegrees == null || dtSeconds <= 0 || dtSeconds > 0.25) {
        return;
      }

      final radians = _headingDegrees! * math.pi / 180;
      final forwardAcceleration =
          event.y * math.cos(radians) + event.x * math.sin(radians);
      final lateralAcceleration =
          event.y * math.sin(radians) - event.x * math.cos(radians);

      final ax = forwardAcceleration.abs() < 0.08 ? 0.0 : forwardAcceleration;
      final ay = lateralAcceleration.abs() < 0.08 ? 0.0 : lateralAcceleration;

      final nextVelocity = Offset(
        (_velocity.dx + ax * dtSeconds) * 0.92,
        (_velocity.dy + ay * dtSeconds) * 0.92,
      );
      final displacement = nextVelocity * dtSeconds;
      if (displacement.distance < 0.002) {
        _velocity = nextVelocity;
        return;
      }

      _velocity = nextVelocity;
      _position = Offset(
        _position.dx + displacement.dx,
        _position.dy + displacement.dy,
      );

      final shouldAppend =
          _lastPointAt == null ||
          now.difference(_lastPointAt!).inMilliseconds >= 220 ||
          (_points.isNotEmpty &&
              (_points.last.x - _position.dx).abs() +
                      (_points.last.y - _position.dy).abs() >=
                  0.06);
      if (!shouldAppend) {
        onUpdate();
        return;
      }

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
      _lastPointAt = now;
      onUpdate();
    });
  }

  void reset() {
    _position = Offset.zero;
    _points
      ..clear()
      ..add(const MovementPoint(x: 0, y: 0));
    _velocity = Offset.zero;
    _lastSampleAt = null;
    _lastPointAt = null;
  }

  Future<void> dispose() async {
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
  }

  double _blendAngle(double current, double target, double weight) {
    final delta = ((target - current + 540) % 360) - 180;
    return (current + delta * weight + 360) % 360;
  }
}
