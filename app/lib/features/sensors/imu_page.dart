import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/error_reporter.dart';
import 'movement_map_card.dart';
import 'relative_motion_tracker.dart';
import 'sensor_models.dart';
import 'sensor_page_scaffold.dart';

class ImuPage extends StatefulWidget {
  const ImuPage({super.key});

  @override
  State<ImuPage> createState() => _ImuPageState();
}

class _ImuPageState extends State<ImuPage> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  AccelerometerEvent? _accelerometer;
  GyroscopeEvent? _gyroscope;
  MagnetometerEvent? _magnetometer;
  int _samples = 0;
  late final RelativeMotionTracker _motionTracker;

  @override
  void initState() {
    super.initState();
    ErrorReporter.recordInfo('IMU page opened', source: 'Navigation');
    _motionTracker = RelativeMotionTracker()
      ..start(() {
        if (mounted) {
          setState(() {});
        }
      });
    _start();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _motionTracker.dispose();
    super.dispose();
  }

  void _start() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        _accelerometer = event;
        _samples += 1;
      });
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        _gyroscope = event;
      });
    });

    _magnetometerSubscription = magnetometerEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        _magnetometer = event;
      });
    });
  }

  String _headingText() {
    if (_magnetometer == null) {
      return '-';
    }

    final heading = math.atan2(_magnetometer!.y, _magnetometer!.x) * 180 / math.pi;
    final normalized = (heading + 360) % 360;
    return '${normalized.toStringAsFixed(1)}°';
  }

  @override
  Widget build(BuildContext context) {
    final hasData =
        _accelerometer != null || _gyroscope != null || _magnetometer != null;

    return SensorPageScaffold(
      title: 'IMU / 羅盤測試',
      summary: '檢查加速度計、陀螺儀、磁力計與基本方位角，供後續姿態估計、PDR 與朝向判定使用。',
      status: hasData ? SensorStatus.ready : SensorStatus.pending,
      actions: [
        FilledButton(
          onPressed: () {
            setState(() {
              _samples = 0;
              _motionTracker.reset();
            });
          },
          child: const Text('重置計數'),
        ),
      ],
      readings: [
        SensorReading(label: '樣本數', value: '$_samples'),
        SensorReading(
          label: '加速度 X/Y/Z',
          value: _accelerometer == null
              ? '-'
              : '${_accelerometer!.x.toStringAsFixed(2)}, ${_accelerometer!.y.toStringAsFixed(2)}, ${_accelerometer!.z.toStringAsFixed(2)}',
        ),
        SensorReading(
          label: '角速度 X/Y/Z',
          value: _gyroscope == null
              ? '-'
              : '${_gyroscope!.x.toStringAsFixed(2)}, ${_gyroscope!.y.toStringAsFixed(2)}, ${_gyroscope!.z.toStringAsFixed(2)}',
        ),
        SensorReading(
          label: '磁力計 X/Y/Z',
          value: _magnetometer == null
              ? '-'
              : '${_magnetometer!.x.toStringAsFixed(2)}, ${_magnetometer!.y.toStringAsFixed(2)}, ${_magnetometer!.z.toStringAsFixed(2)}',
        ),
        SensorReading(label: '方位角', value: _headingText()),
      ],
      footer: MovementMapCard(
        title: '人物移動地圖',
        description: '以 IMU + 羅盤估計相對移動軌跡，屬於測試用 dead-reckoning 視覺化，不代表絕對座標。',
        points: _motionTracker.points,
      ),
    );
  }
}
