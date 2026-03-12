import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/beacon_registry.dart';
import '../../core/error_reporter.dart';
import 'movement_map_card.dart';
import 'relative_motion_tracker.dart';
import 'sensor_models.dart';
import 'sensor_page_scaffold.dart';

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  StreamSubscription<List<ScanResult>>? _resultsSubscription;
  List<ScanResult> _results = const [];
  List<SavedBeacon> _savedBeacons = const [];
  String _permissionState = '未檢查';
  String _adapterState = '未知';
  String _error = '';
  bool _scanning = false;
  late final RelativeMotionTracker _motionTracker;

  @override
  void initState() {
    super.initState();
    _motionTracker = RelativeMotionTracker()
      ..start(() {
        if (mounted) {
          setState(() {});
        }
      });
    _loadSavedBeacons();
    _listenAdapterState();
  }

  @override
  void dispose() {
    _resultsSubscription?.cancel();
    _motionTracker.dispose();
    super.dispose();
  }

  Future<void> _loadSavedBeacons() async {
    await BeaconRegistry.instance.load();
    if (!mounted) return;
    setState(() {
      _savedBeacons = BeaconRegistry.instance.beacons;
    });
  }

  void _listenAdapterState() {
    FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      setState(() {
        _adapterState = state.name;
      });
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _error = '';
    });

    final scanPermission = await Permission.bluetoothScan.request();
    final connectPermission = await Permission.bluetoothConnect.request();
    final locationPermission = await Permission.locationWhenInUse.request();

    setState(() {
      _permissionState =
          'scan=${scanPermission.name}, connect=${connectPermission.name}, location=${locationPermission.name}';
    });

    if (!scanPermission.isGranted ||
        !connectPermission.isGranted ||
        !locationPermission.isGranted) {
      setState(() {
        _error = 'BLE 權限不足，請允許藍牙與定位權限';
      });
      ErrorReporter.record(source: 'BLE', message: _error);
      return;
    }

    _resultsSubscription?.cancel();
    _resultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _results = results;
      });
    });

    setState(() {
      _scanning = true;
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
      ErrorReporter.record(source: 'BLE', message: _error);
    } finally {
      if (!mounted) return;
      setState(() {
        _scanning = false;
      });
    }
  }

  Future<void> _tagBeacon(ScanResult result) async {
    final controller = TextEditingController(
      text: _existingNameFor(_beaconKey(result)),
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('標記 Beacon'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Beacon 名稱',
            hintText: '例如：入口左側 / 展區A / 測試1號',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) {
      return;
    }

    final saved = SavedBeacon(
      beaconKey: _beaconKey(result),
      displayName: name,
      remoteId: result.device.remoteId.str,
      deviceName: result.device.platformName,
      manufacturerHex: _manufacturerHex(result),
      serviceDataHex: _serviceDataHex(result),
      lastRssi: result.rssi,
      savedAt: DateTime.now().toIso8601String(),
    );

    await BeaconRegistry.instance.saveBeacon(saved);
    ErrorReporter.recordInfo(
      'Saved beacon tag: ${saved.displayName} (${saved.beaconKey})',
      source: 'BLE',
    );
    await _loadSavedBeacons();
  }

  Future<void> _removeSavedBeacon(String beaconKey) async {
    await BeaconRegistry.instance.removeBeacon(beaconKey);
    ErrorReporter.recordInfo(
      'Removed beacon tag: $beaconKey',
      source: 'BLE',
    );
    await _loadSavedBeacons();
  }

  String _existingNameFor(String beaconKey) {
    final existing = _savedBeacons.where((item) => item.beaconKey == beaconKey);
    if (existing.isEmpty) {
      return '';
    }
    return existing.first.displayName;
  }

  String _beaconKey(ScanResult result) {
    final manufacturer = _manufacturerHex(result);
    final serviceData = _serviceDataHex(result);
    if (manufacturer.isNotEmpty) {
      return manufacturer;
    }
    if (serviceData.isNotEmpty) {
      return serviceData;
    }
    return result.device.remoteId.str;
  }

  String _manufacturerHex(ScanResult result) {
    final manufacturerData = result.advertisementData.manufacturerData;
    if (manufacturerData.isEmpty) {
      return '';
    }
    return manufacturerData.entries
        .map(
          (entry) => '${entry.key.toRadixString(16)}:${_bytesToHex(entry.value)}',
        )
        .join('|');
  }

  String _serviceDataHex(ScanResult result) {
    final serviceData = result.advertisementData.serviceData;
    if (serviceData.isEmpty) {
      return '';
    }
    return serviceData.entries
        .map((entry) => '${entry.key}:${_bytesToHex(entry.value)}')
        .join('|');
  }

  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final first = _results.isNotEmpty ? _results.first : null;
    final status = _results.isNotEmpty
        ? SensorStatus.ready
        : (_error.isNotEmpty ? SensorStatus.blocked : SensorStatus.pending);

    return SensorPageScaffold(
      title: 'BLE Beacon 測試',
      summary: '驗證藍牙掃描、Beacon 廣播資料、命名標記與 RSSI 讀值。',
      status: status,
      actions: [
        FilledButton(
          onPressed: _scanning ? null : _startScan,
          child: Text(_scanning ? '掃描中...' : '開始掃描'),
        ),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _motionTracker.reset();
            });
          },
          child: const Text('重置地圖'),
        ),
      ],
      readings: [
        SensorReading(label: '權限', value: _permissionState),
        SensorReading(label: '藍牙狀態', value: _adapterState),
        SensorReading(label: '掃描數量', value: '${_results.length}'),
        SensorReading(label: '已標記 Beacon', value: '${_savedBeacons.length}'),
        SensorReading(
          label: '第一筆名稱',
          value: first?.device.platformName.isNotEmpty == true
              ? first!.device.platformName
              : '-',
        ),
        SensorReading(
          label: '第一筆 ID',
          value: first?.device.remoteId.str ?? '-',
        ),
        SensorReading(
          label: '第一筆 RSSI',
          value: first == null ? '-' : '${first.rssi} dBm',
        ),
        SensorReading(
          label: '第一筆 Beacon Key',
          value: first == null ? '-' : _beaconKey(first),
        ),
      ],
      footer: Column(
        children: [
          MovementMapCard(
            title: '人物移動地圖',
            description: '掃描期間以手機 IMU + 羅盤推估相對移動，方便對照 Beacon 訊號變化與面向角度。',
            points: _motionTracker.points,
          ),
          const SizedBox(height: 12),
          if (_savedBeacons.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已保存 Beacon',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._savedBeacons.map(
                      (beacon) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(beacon.displayName),
                        subtitle: Text(beacon.beaconKey),
                        trailing: IconButton(
                          onPressed: () => _removeSavedBeacon(beacon.beaconKey),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_error.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error),
              ),
            ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: _results
                      .take(8)
                      .map(
                        (result) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            result.device.platformName.isEmpty
                                ? '(unnamed)'
                                : result.device.platformName,
                          ),
                          subtitle: Text(
                            [
                              'id=${result.device.remoteId.str}',
                              'key=${_beaconKey(result)}',
                              if (_manufacturerHex(result).isNotEmpty)
                                'mfg=${_manufacturerHex(result)}',
                              if (_serviceDataHex(result).isNotEmpty)
                                'svc=${_serviceDataHex(result)}',
                            ].join('\n'),
                          ),
                          trailing: SizedBox(
                            width: 68,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${result.rssi}'),
                                IconButton(
                                  onPressed: () => _tagBeacon(result),
                                  icon: const Icon(Icons.bookmark_add_outlined),
                                  tooltip: '標記 Beacon',
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
