import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/error_reporter.dart';
import 'movement_map_card.dart';
import 'relative_motion_tracker.dart';
import 'sensor_models.dart';

class AllModuleTestPage extends StatefulWidget {
  const AllModuleTestPage({super.key});

  @override
  State<AllModuleTestPage> createState() => _AllModuleTestPageState();
}

class _AllModuleTestPageState extends State<AllModuleTestPage> {
  final RelativeMotionTracker _motionTracker = RelativeMotionTracker();
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  CameraController? _cameraController;
  Position? _position;
  AccelerometerEvent? _accelerometer;
  GyroscopeEvent? _gyroscope;
  MagnetometerEvent? _magnetometer;
  List<ScanResult> _scanResults = const [];
  final List<MovementPoint> _gpsTrack = <MovementPoint>[];
  final GpsTrackAccumulator _trackAccumulator = GpsTrackAccumulator();

  String _gpsPermission = '未檢查';
  String _cameraPermission = '未檢查';
  String _blePermission = '未檢查';
  String _serviceState = '未知';
  String _adapterState = '未知';
  String _error = '';
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    ErrorReporter.recordInfo('All module test page opened', source: 'Navigation');
    _motionTracker.start(() {
      if (mounted) {
        setState(() {});
      }
    });
    _watchAdapterState();
    _initializeAll();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scanSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _cameraController?.dispose();
    _motionTracker.dispose();
    super.dispose();
  }

  void _watchAdapterState() {
    FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _adapterState = state.name;
      });
    });
  }

  Future<void> _initializeAll() async {
    setState(() {
      _initializing = true;
      _error = '';
    });

    await Future.wait<void>([
      _startGps(),
      _startImu(),
      _startBle(),
      _startCamera(),
    ]);

    if (!mounted) {
      return;
    }
    setState(() {
      _initializing = false;
    });
  }

  Future<void> _startGps() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Permission.locationWhenInUse.request();

    if (!mounted) {
      return;
    }

    setState(() {
      _serviceState = serviceEnabled ? '已開啟' : '未開啟';
      _gpsPermission = permission.toString();
    });

    if (!serviceEnabled || !permission.isGranted) {
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen(
      (position) {
        if (!mounted) {
          return;
        }
        setState(() {
          _position = position;
        });
        final point = _trackAccumulator.add(position);
        if (point == null) {
          return;
        }
        _gpsTrack.add(point);
        if (_gpsTrack.length > 120) {
          _gpsTrack.removeAt(0);
        }
      },
      onError: (Object error) {
        ErrorReporter.record(source: 'AllModule/GPS', message: error.toString());
        if (!mounted) {
          return;
        }
        setState(() {
          _error = 'GPS 啟動失敗: $error';
        });
      },
    );
  }

  Future<void> _startImu() async {
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    await _magnetometerSubscription?.cancel();

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        _accelerometer = event;
      });
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        _gyroscope = event;
      });
    });

    _magnetometerSubscription = magnetometerEvents.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        _magnetometer = event;
      });
    });
  }

  Future<void> _startBle() async {
    final scanPermission = await Permission.bluetoothScan.request();
    final connectPermission = await Permission.bluetoothConnect.request();
    final locationPermission = await Permission.locationWhenInUse.request();

    if (!mounted) {
      return;
    }

    setState(() {
      _blePermission =
          'scan=${scanPermission.name}, connect=${connectPermission.name}, location=${locationPermission.name}';
    });

    if (!scanPermission.isGranted ||
        !connectPermission.isGranted ||
        !locationPermission.isGranted) {
      return;
    }

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) {
        return;
      }
      setState(() {
        _scanResults = results;
      });
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (error) {
      ErrorReporter.record(source: 'AllModule/BLE', message: error.toString());
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'BLE 啟動失敗: $error';
      });
    }
  }

  Future<void> _startCamera() async {
    final permission = await Permission.camera.request();
    if (!mounted) {
      return;
    }

    setState(() {
      _cameraPermission = permission.toString();
    });

    if (!permission.isGranted) {
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();

      await _cameraController?.dispose();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
      });
    } catch (error) {
      ErrorReporter.record(source: 'AllModule/Camera', message: error.toString());
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Camera 啟動失敗: $error';
      });
    }
  }

  String _headingText() {
    if (_magnetometer == null) {
      return '-';
    }

    final heading = math.atan2(_magnetometer!.y, _magnetometer!.x) * 180 / math.pi;
    final normalized = (heading + 360) % 360;
    return '${normalized.toStringAsFixed(1)}°';
  }

  List<MovementPoint> get _mapPoints =>
      _gpsTrack.length >= 2 ? _gpsTrack : _motionTracker.points;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 24;
    final primaryBeacon = _scanResults.isNotEmpty ? _scanResults.first : null;
    final cameraReady = _cameraController?.value.isInitialized ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('全模組定位測試')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '全部參數參考',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '同時啟動 GPS、IMU/羅盤、BLE、Camera，用一頁觀察所有定位相關參數與總移動地圖。',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: _initializing ? null : _initializeAll,
                          child: Text(_initializing ? '初始化中...' : '全部重啟'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _gpsTrack.clear();
                              _trackAccumulator.reset();
                              _motionTracker.reset();
                            });
                          },
                          child: const Text('重置地圖'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            MovementMapCard(
              title: '全模組人物移動地圖',
              description:
                  _gpsTrack.length >= 2
                      ? '目前優先使用 GPS 真實軌跡；若 GPS 樣本不足則退回 IMU + 羅盤相對移動。'
                      : 'GPS 樣本不足時，使用 IMU + 羅盤推估相對移動；若取得 GPS 後會自動切換為真實軌跡。',
              points: _mapPoints,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'GPS',
              rows: [
                _kv('權限', _gpsPermission),
                _kv('定位服務', _serviceState),
                _kv('緯度', _position?.latitude.toStringAsFixed(6) ?? '-'),
                _kv('經度', _position?.longitude.toStringAsFixed(6) ?? '-'),
                _kv(
                  '精度',
                  _position == null ? '-' : '${_position!.accuracy.toStringAsFixed(2)} m',
                ),
                _kv('速度', _position == null ? '-' : '${_position!.speed.toStringAsFixed(2)} m/s'),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'IMU / 羅盤',
              rows: [
                _kv(
                  '加速度',
                  _accelerometer == null
                      ? '-'
                      : '${_accelerometer!.x.toStringAsFixed(2)}, ${_accelerometer!.y.toStringAsFixed(2)}, ${_accelerometer!.z.toStringAsFixed(2)}',
                ),
                _kv(
                  '角速度',
                  _gyroscope == null
                      ? '-'
                      : '${_gyroscope!.x.toStringAsFixed(2)}, ${_gyroscope!.y.toStringAsFixed(2)}, ${_gyroscope!.z.toStringAsFixed(2)}',
                ),
                _kv(
                  '磁力計',
                  _magnetometer == null
                      ? '-'
                      : '${_magnetometer!.x.toStringAsFixed(2)}, ${_magnetometer!.y.toStringAsFixed(2)}, ${_magnetometer!.z.toStringAsFixed(2)}',
                ),
                _kv('方位角', _headingText()),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'BLE Beacon',
              rows: [
                _kv('權限', _blePermission),
                _kv('藍牙狀態', _adapterState),
                _kv('掃描數量', '${_scanResults.length}'),
                _kv(
                  '第一筆裝置',
                  primaryBeacon == null
                      ? '-'
                      : (primaryBeacon.device.platformName.isEmpty
                          ? primaryBeacon.device.remoteId.str
                          : primaryBeacon.device.platformName),
                ),
                _kv(
                  '第一筆 RSSI',
                  primaryBeacon == null ? '-' : '${primaryBeacon.rssi} dBm',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Camera',
              rows: [
                _kv('權限', _cameraPermission),
                _kv('預覽狀態', cameraReady ? '已初始化' : '未初始化'),
                _kv(
                  '解析度',
                  cameraReady
                      ? '${_cameraController!.value.previewSize?.width.toStringAsFixed(0) ?? '-'} x ${_cameraController!.value.previewSize?.height.toStringAsFixed(0) ?? '-'}'
                      : '-',
                ),
              ],
              child: cameraReady
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: _cameraController!.value.aspectRatio,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    )
                  : null,
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  MapEntry<String, String> _kv(String key, String value) => MapEntry(key, value);
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.rows,
    this.child,
  });

  final String title;
  final List<MapEntry<String, String>> rows;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 86,
                      child: Text(row.key),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
