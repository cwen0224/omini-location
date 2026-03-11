import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/error_reporter.dart';
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
  String _permissionState = '未檢查';
  String _adapterState = '未知';
  String _error = '';
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _listenAdapterState();
  }

  @override
  void dispose() {
    _resultsSubscription?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final first = _results.isNotEmpty ? _results.first : null;
    final status = _results.isNotEmpty
        ? SensorStatus.ready
        : (_error.isNotEmpty ? SensorStatus.blocked : SensorStatus.pending);

    return SensorPageScaffold(
      title: 'BLE Beacon 測試',
      summary: '驗證藍牙掃描、Beacon 裝置列舉與 RSSI 讀值。',
      status: status,
      actions: [
        FilledButton(
          onPressed: _scanning ? null : _startScan,
          child: Text(_scanning ? '掃描中...' : '開始掃描'),
        ),
      ],
      readings: [
        SensorReading(label: '權限', value: _permissionState),
        SensorReading(label: '藍牙狀態', value: _adapterState),
        SensorReading(label: '掃描數量', value: '${_results.length}'),
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
      ],
      footer: Column(
        children: [
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
                          subtitle: Text(result.device.remoteId.str),
                          trailing: Text('${result.rssi}'),
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
