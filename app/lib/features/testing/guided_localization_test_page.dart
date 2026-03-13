import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/error_reporter.dart';
import '../../core/remote_sync_service.dart';
import '../sensors/movement_map_card.dart';
import '../sensors/relative_motion_tracker.dart';
import '../sensors/sensor_models.dart';
import 'guided_test_models.dart';

class GuidedLocalizationTestPage extends StatefulWidget {
  const GuidedLocalizationTestPage({super.key});

  @override
  State<GuidedLocalizationTestPage> createState() =>
      _GuidedLocalizationTestPageState();
}

class _GuidedLocalizationTestPageState extends State<GuidedLocalizationTestPage> {
  final RelativeMotionTracker _motionTracker = RelativeMotionTracker();
  final TextEditingController _locationController =
      TextEditingController(text: '未命名場域');
  final List<GuidedTestStep> _steps = const <GuidedTestStep>[
    GuidedTestStep(
      title: '靜止基線',
      instruction: '原地站立 10 秒，保持手機自然持握。',
      actionType: 'stand_still',
    ),
    GuidedTestStep(
      title: '直線步行',
      instruction: '沿直線前進約 5 公尺，到點後按完成。',
      actionType: 'walk_forward',
      targetDistanceM: 5,
    ),
    GuidedTestStep(
      title: '原地左轉',
      instruction: '原地左轉 90 度，面向新方向後按完成。',
      actionType: 'turn_left',
      targetHeadingDeg: -90,
    ),
    GuidedTestStep(
      title: 'Beacon 區域掃描',
      instruction: '走進 Beacon 區域，停留 5 秒，確認掃描結果穩定。',
      actionType: 'scan_beacon_zone',
    ),
    GuidedTestStep(
      title: 'Camera 重定位',
      instruction: '用相機對準目標牆面或標記，確認畫面穩定。',
      actionType: 'camera_relocalize',
    ),
  ];

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
  List<ScanResult> _scanResults = const <ScanResult>[];
  final List<MovementPoint> _gpsTrack = <MovementPoint>[];
  final GpsTrackAccumulator _trackAccumulator = GpsTrackAccumulator();

  String? _sessionId;
  String? _segmentId;
  int _stepIndex = 0;
  Timer? _sampleTimer;
  Timer? _zeroingTimer;
  bool _preparing = false;
  bool _recording = false;
  bool _zeroing = false;
  bool _beaconRemovalConfirmed = false;
  int _zeroingRemainingSeconds = 0;
  String _status = '尚未開始';
  String _error = '';
  final List<_ZeroingSample> _zeroingSamples = <_ZeroingSample>[];
  _ZeroingSummary? _zeroingSummary;

  @override
  void initState() {
    super.initState();
    ErrorReporter.recordInfo(
      'Guided localization test page opened',
      source: 'Navigation',
    );
    _motionTracker.start(() {
      if (mounted) {
        setState(() {});
      }
    });
    _prepareSensors();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scanSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _sampleTimer?.cancel();
    _zeroingTimer?.cancel();
    _cameraController?.dispose();
    _motionTracker.dispose();
    _locationController.dispose();
    super.dispose();
  }

  GuidedTestStep get _currentStep => _steps[_stepIndex];

  Future<void> _prepareSensors() async {
    setState(() {
      _preparing = true;
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
      _preparing = false;
      _status = '感測器已準備，可開始 session';
    });
  }

  Future<void> _startGps() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Permission.locationWhenInUse.request();
    if (!serviceEnabled || !permission.isGranted) {
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((position) {
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
    });
  }

  Future<void> _startImu() async {
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    await _magnetometerSubscription?.cancel();

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (mounted) {
        setState(() {
          _accelerometer = event;
        });
      }
    });
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      if (mounted) {
        setState(() {
          _gyroscope = event;
        });
      }
    });
    _magnetometerSubscription = magnetometerEvents.listen((event) {
      if (mounted) {
        setState(() {
          _magnetometer = event;
        });
      }
    });
  }

  Future<void> _startBle() async {
    final scanPermission = await Permission.bluetoothScan.request();
    final connectPermission = await Permission.bluetoothConnect.request();
    final locationPermission = await Permission.locationWhenInUse.request();
    if (!scanPermission.isGranted ||
        !connectPermission.isGranted ||
        !locationPermission.isGranted) {
      return;
    }

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<void> _startCamera() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      return;
    }

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
  }

  Future<void> _startSession() async {
    if (!_beaconRemovalConfirmed) {
      setState(() {
        _error = '開始測試前，請先確認已移除自己身上的所有 Beacon 或藍牙追蹤器。';
      });
      return;
    }
    if (_zeroingSummary == null) {
      setState(() {
        _error = '開始測試前，請先執行 10 秒歸零。';
      });
      return;
    }

    setState(() {
      _recording = true;
      _status = '建立 session 中...';
      _error = '';
      _gpsTrack.clear();
      _trackAccumulator.reset();
      _motionTracker.reset();
    });

    try {
      final sessionId = await RemoteSyncService.instance.createGuidedTestSession(
        sessionName: 'guided-${DateTime.now().millisecondsSinceEpoch}',
        locationLabel: _locationController.text.trim(),
        metadata: <String, dynamic>{
          'step_count': _steps.length,
          'created_from': 'guided_localization_test_page',
          'beacon_removal_confirmed': _beaconRemovalConfirmed,
          'zeroing_summary': _zeroingSummary!.toJson(),
        },
      );

      final segmentId = await RemoteSyncService.instance.startActionSegment(
        sessionId: sessionId,
        step: _currentStep,
        metadata: <String, dynamic>{'step_index': _stepIndex},
      );

      _sampleTimer?.cancel();
      _sampleTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _uploadCurrentSample(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sessionId = sessionId;
        _segmentId = segmentId;
        _status = '測試進行中：${_currentStep.title}';
      });
    } catch (error, stackTrace) {
      ErrorReporter.record(
        source: 'GuidedTest',
        message: 'Start session failed: $error',
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _recording = false;
        _error = '無法建立測試 session：$error';
      });
    }
  }

  Future<void> _uploadCurrentSample() async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }

    final payload = SensorSamplePayload(
      sampleTime: DateTime.now().toIso8601String(),
      gpsLat: _position?.latitude,
      gpsLng: _position?.longitude,
      gpsAccuracy: _position?.accuracy,
      gpsSpeed: _position?.speed,
      accelX: _accelerometer?.x,
      accelY: _accelerometer?.y,
      accelZ: _accelerometer?.z,
      gyroX: _gyroscope?.x,
      gyroY: _gyroscope?.y,
      gyroZ: _gyroscope?.z,
      magX: _magnetometer?.x,
      magY: _magnetometer?.y,
      magZ: _magnetometer?.z,
      heading: _headingDegrees(),
      bleVisibleCount: _scanResults.length,
      bleTopBeacons: _scanResults
          .take(3)
          .map(
            (result) => <String, dynamic>{
              'id': result.device.remoteId.str,
              'name': result.device.platformName,
              'rssi': result.rssi,
            },
          )
          .toList(),
      cameraTrackingState:
          (_cameraController?.value.isInitialized ?? false) ? 'ready' : 'idle',
      cameraFeatureScore:
          (_cameraController?.value.isInitialized ?? false) ? 1 : 0,
      metadata: <String, dynamic>{
        'step_index': _stepIndex,
        'step_title': _currentStep.title,
      },
    );

    try {
      await RemoteSyncService.instance.insertSensorSample(
        sessionId: sessionId,
        segmentId: _segmentId,
        sample: payload,
      );
    } catch (error, stackTrace) {
      ErrorReporter.record(
        source: 'GuidedTest',
        message: 'Upload sensor sample failed: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _completeCurrentStep() async {
    final sessionId = _sessionId;
    final segmentId = _segmentId;
    if (sessionId == null || segmentId == null) {
      return;
    }

    try {
      await RemoteSyncService.instance.completeActionSegment(
        segmentId: segmentId,
        operatorConfirmed: true,
        metadata: <String, dynamic>{
          'completed_step_index': _stepIndex,
          'completed_step_title': _currentStep.title,
        },
      );

      if (_stepIndex >= _steps.length - 1) {
        _sampleTimer?.cancel();
        if (!mounted) {
          return;
        }
        setState(() {
          _recording = false;
          _status = '全部測試步驟完成';
        });
        return;
      }

      final nextIndex = _stepIndex + 1;
      final nextSegmentId = await RemoteSyncService.instance.startActionSegment(
        sessionId: sessionId,
        step: _steps[nextIndex],
        metadata: <String, dynamic>{'step_index': nextIndex},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stepIndex = nextIndex;
        _segmentId = nextSegmentId;
        _status = '測試進行中：${_steps[nextIndex].title}';
      });
    } catch (error, stackTrace) {
      ErrorReporter.record(
        source: 'GuidedTest',
        message: 'Complete step failed: $error',
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '無法完成目前步驟：$error';
      });
    }
  }

  Future<void> _recordFeedback(String value) async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }

    await RemoteSyncService.instance.insertUserFeedback(
      sessionId: sessionId,
      segmentId: _segmentId,
      feedbackType: 'estimated_position_correct',
      value: value,
      metadata: <String, dynamic>{
        'step_index': _stepIndex,
        'step_title': _currentStep.title,
      },
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已記錄回饋：$value')),
    );
  }

  Future<void> _markGroundTruthPoint() async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }

    await RemoteSyncService.instance.insertGroundTruthPoint(
      sessionId: sessionId,
      segmentId: _segmentId,
      pointLabel: 'step-${_stepIndex + 1}-${_currentStep.title}',
      source: 'manual_confirm',
      mapX: _gpsTrack.isNotEmpty ? _gpsTrack.last.x : null,
      mapY: _gpsTrack.isNotEmpty ? _gpsTrack.last.y : null,
      headingDeg: _headingDegrees(),
      metadata: <String, dynamic>{
        'step_index': _stepIndex,
        'instruction': _currentStep.instruction,
      },
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已記錄 ground truth 點位')),
    );
  }

  double? _headingDegrees() {
    if (_magnetometer == null) {
      return null;
    }
    final heading = math.atan2(_magnetometer!.y, _magnetometer!.x) * 180 / math.pi;
    return (heading + 360) % 360;
  }

  List<MovementPoint> get _mapPoints =>
      _gpsTrack.length >= 2 ? _gpsTrack : _motionTracker.points;

  Future<void> _startZeroing() async {
    if (_zeroing || _recording) {
      return;
    }

    setState(() {
      _error = '';
      _zeroing = true;
      _zeroingRemainingSeconds = 10;
      _zeroingSummary = null;
      _zeroingSamples.clear();
      _gpsTrack.clear();
      _trackAccumulator.reset();
      _motionTracker.reset();
      _status = '歸零中：請將手機靜置 10 秒';
    });

    _captureZeroingSample();
    _zeroingTimer?.cancel();
    _zeroingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _captureZeroingSample();
      final nextRemaining = 10 - timer.tick;
      if (nextRemaining <= 0) {
        timer.cancel();
        _finishZeroing();
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _zeroingRemainingSeconds = nextRemaining;
      });
    });
  }

  void _captureZeroingSample() {
    _zeroingSamples.add(
      _ZeroingSample(
        gpsAccuracy: _position?.accuracy,
        headingDeg: _headingDegrees(),
        accelMagnitude: _accelerometer == null
            ? null
            : math.sqrt(
                _accelerometer!.x * _accelerometer!.x +
                    _accelerometer!.y * _accelerometer!.y +
                    _accelerometer!.z * _accelerometer!.z,
              ),
        gyroMagnitude: _gyroscope == null
            ? null
            : math.sqrt(
                _gyroscope!.x * _gyroscope!.x +
                    _gyroscope!.y * _gyroscope!.y +
                    _gyroscope!.z * _gyroscope!.z,
              ),
        bleVisibleCount: _scanResults.length,
      ),
    );
  }

  void _finishZeroing() {
    final samples = List<_ZeroingSample>.from(_zeroingSamples);
    final summary = _ZeroingSummary.fromSamples(samples);
    if (!mounted) {
      return;
    }
    setState(() {
      _zeroing = false;
      _zeroingRemainingSeconds = 0;
      _zeroingSummary = summary;
      _status = '歸零完成，可開始 session';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 24;
    final cameraReady = _cameraController?.value.isInitialized ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('引導式定位建檔')),
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
                    Text('測試場域', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'location_label',
                        hintText: '例如：入口大廳 / 展區A / 牢房走廊',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '前置檢查',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '開始前請移除自己身上的所有 Beacon、藍牙追蹤器或測試吊牌，避免把人體攜帶訊號誤判成環境定位基準。接著將手機平放或自然持握靜置 10 秒，建立歸零參考。',
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _beaconRemovalConfirmed,
                              onChanged: _recording || _zeroing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _beaconRemovalConfirmed = value ?? false;
                                      });
                                    },
                              title: const Text('我已移除自己身上的所有 Beacon / 藍牙追蹤器'),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.tonal(
                                  onPressed: _preparing || _recording || _zeroing
                                      ? null
                                      : _startZeroing,
                                  child: Text(
                                    _zeroing
                                        ? '歸零中 ${_zeroingRemainingSeconds}s'
                                        : '開始 10 秒歸零',
                                  ),
                                ),
                                if (_zeroingSummary != null)
                                  Chip(
                                    label: Text(
                                      'GPS ±${_zeroingSummary!.averageGpsAccuracyM.toStringAsFixed(1)}m / BLE ${_zeroingSummary!.averageBleVisibleCount.toStringAsFixed(1)} / Heading ${_zeroingSummary!.averageHeadingDeg.toStringAsFixed(1)}°',
                                    ),
                                  ),
                              ],
                            ),
                            if (_zeroing) ...[
                              const SizedBox(height: 12),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '歸零進行中',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '請保持手機靜止，剩餘 ${_zeroingRemainingSeconds} 秒',
                                        style: Theme.of(context).textTheme.headlineSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('倒數結束前不要移動手機，也不要靠近自己身上的 Beacon。'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: _preparing || _recording || _zeroing ? null : _startSession,
                          child: Text(_recording ? '錄製中...' : '開始測試 Session'),
                        ),
                        OutlinedButton(
                          onPressed: _preparing ? null : _prepareSensors,
                          child: Text(_preparing ? '準備中...' : '重整感測器'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Session: ${_sessionId ?? '-'}'),
                    Text('狀態: $_status'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '目前步驟 ${_stepIndex + 1}/${_steps.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_currentStep.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_currentStep.instruction),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: _recording ? _completeCurrentStep : null,
                          child: const Text('完成此步驟'),
                        ),
                        OutlinedButton(
                          onPressed: _recording ? _markGroundTruthPoint : null,
                          child: const Text('記錄真實點位'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            MovementMapCard(
              title: 'Session 移動地圖',
              description:
                  '優先使用 GPS 真實軌跡，GPS 不足時退回 IMU + 羅盤相對移動。這張圖會隨測試步驟持續累積。',
              points: _mapPoints,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('即時參數', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text('GPS: ${_position?.latitude.toStringAsFixed(6) ?? '-'}, ${_position?.longitude.toStringAsFixed(6) ?? '-'}'),
                    Text('GPS 精度: ${_position == null ? '-' : '${_position!.accuracy.toStringAsFixed(2)} m'}'),
                    Text('Heading: ${_headingDegrees()?.toStringAsFixed(1) ?? '-'}°'),
                    Text('BLE 可見數: ${_scanResults.length}'),
                    Text('Camera: ${cameraReady ? 'ready' : 'idle'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('使用者回饋', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.tonal(
                          onPressed: _recording ? () => _recordFeedback('correct') : null,
                          child: const Text('位置正確'),
                        ),
                        FilledButton.tonal(
                          onPressed: _recording ? () => _recordFeedback('offset_left') : null,
                          child: const Text('偏左'),
                        ),
                        FilledButton.tonal(
                          onPressed: _recording ? () => _recordFeedback('offset_right') : null,
                          child: const Text('偏右'),
                        ),
                        FilledButton.tonal(
                          onPressed: _recording ? () => _recordFeedback('unstable') : null,
                          child: const Text('不穩定'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
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
}

class _ZeroingSample {
  const _ZeroingSample({
    this.gpsAccuracy,
    this.headingDeg,
    this.accelMagnitude,
    this.gyroMagnitude,
    required this.bleVisibleCount,
  });

  final double? gpsAccuracy;
  final double? headingDeg;
  final double? accelMagnitude;
  final double? gyroMagnitude;
  final int bleVisibleCount;
}

class _ZeroingSummary {
  const _ZeroingSummary({
    required this.averageGpsAccuracyM,
    required this.averageHeadingDeg,
    required this.averageAccelMagnitude,
    required this.averageGyroMagnitude,
    required this.averageBleVisibleCount,
    required this.sampleCount,
  });

  factory _ZeroingSummary.fromSamples(List<_ZeroingSample> samples) {
    double averageNullable(Iterable<double?> values) {
      final nonNull = values.whereType<double>().toList();
      if (nonNull.isEmpty) {
        return 0;
      }
      return nonNull.reduce((left, right) => left + right) / nonNull.length;
    }

    final averageBle = samples.isEmpty
        ? 0.0
        : samples.map((sample) => sample.bleVisibleCount).reduce((left, right) => left + right) /
            samples.length;

    return _ZeroingSummary(
      averageGpsAccuracyM: averageNullable(
        samples.map((sample) => sample.gpsAccuracy),
      ),
      averageHeadingDeg: averageNullable(
        samples.map((sample) => sample.headingDeg),
      ),
      averageAccelMagnitude: averageNullable(
        samples.map((sample) => sample.accelMagnitude),
      ),
      averageGyroMagnitude: averageNullable(
        samples.map((sample) => sample.gyroMagnitude),
      ),
      averageBleVisibleCount: averageBle,
      sampleCount: samples.length,
    );
  }

  final double averageGpsAccuracyM;
  final double averageHeadingDeg;
  final double averageAccelMagnitude;
  final double averageGyroMagnitude;
  final double averageBleVisibleCount;
  final int sampleCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'average_gps_accuracy_m': averageGpsAccuracyM,
      'average_heading_deg': averageHeadingDeg,
      'average_accel_magnitude': averageAccelMagnitude,
      'average_gyro_magnitude': averageGyroMagnitude,
      'average_ble_visible_count': averageBleVisibleCount,
      'sample_count': sampleCount,
    };
  }
}
