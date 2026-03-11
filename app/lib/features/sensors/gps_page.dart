import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/error_reporter.dart';
import 'sensor_models.dart';
import 'sensor_page_scaffold.dart';

class GpsPage extends StatefulWidget {
  const GpsPage({super.key});

  @override
  State<GpsPage> createState() => _GpsPageState();
}

class _GpsPageState extends State<GpsPage> {
  StreamSubscription<Position>? _positionSubscription;
  Position? _position;
  String _permissionState = '未檢查';
  String _serviceState = '未知';
  String _error = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Permission.locationWhenInUse.status;

    setState(() {
      _serviceState = serviceEnabled ? '已開啟' : '未開啟';
      _permissionState = permission.toString();
      _loading = false;
    });
  }

  Future<void> _startTracking() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _serviceState = '未開啟';
        _error = '請先開啟手機定位服務';
        _loading = false;
      });
      ErrorReporter.record(source: 'GPS', message: _error);
      return;
    }

    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) {
      setState(() {
        _permissionState = permission.toString();
        _error = '定位權限未授權';
        _loading = false;
      });
      ErrorReporter.record(source: 'GPS', message: _error);
      return;
    }

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen(
      (position) {
        if (!mounted) return;
        setState(() {
          _position = position;
          _permissionState = permission.toString();
          _serviceState = '已開啟';
          _loading = false;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _error = error.toString();
          _loading = false;
        });
        ErrorReporter.record(source: 'GPS', message: _error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _position != null
        ? SensorStatus.ready
        : (_error.isNotEmpty ? SensorStatus.blocked : SensorStatus.pending);

    return SensorPageScaffold(
      title: 'GPS 定位測試',
      summary: '驗證前景定位、精度與時間戳，作為室外主定位來源。',
      status: status,
      actions: [
        FilledButton(
          onPressed: _loading ? null : _startTracking,
          child: const Text('開始定位'),
        ),
        OutlinedButton(
          onPressed: _loading ? null : _refresh,
          child: const Text('刷新狀態'),
        ),
      ],
      readings: [
        SensorReading(label: '權限', value: _permissionState),
        SensorReading(label: '定位服務', value: _serviceState),
        SensorReading(
          label: '緯度',
          value: _position?.latitude.toStringAsFixed(6) ?? '-',
        ),
        SensorReading(
          label: '經度',
          value: _position?.longitude.toStringAsFixed(6) ?? '-',
        ),
        SensorReading(
          label: '精度',
          value: _position == null
              ? '-'
              : '${_position!.accuracy.toStringAsFixed(2)} m',
        ),
        SensorReading(
          label: '時間',
          value: _position?.timestamp?.toIso8601String() ?? '-',
        ),
      ],
      footer: _error.isEmpty
          ? null
          : Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error),
              ),
            ),
    );
  }
}
