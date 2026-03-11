import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  AccelerometerEvent? _accelerometer;
  GyroscopeEvent? _gyroscope;
  int _samples = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
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
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _accelerometer != null || _gyroscope != null;

    return SensorPageScaffold(
      title: 'IMU 測試',
      summary: '檢查陀螺儀與加速度計資料流，供後續姿態估計與 PDR 使用。',
      status: hasData ? SensorStatus.ready : SensorStatus.pending,
      actions: [
        FilledButton(
          onPressed: () {
            setState(() {
              _samples = 0;
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
      ],
    );
  }
}

