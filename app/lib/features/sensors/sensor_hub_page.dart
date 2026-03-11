import 'package:flutter/material.dart';

import '../../core/error_reporter.dart';
import 'ble_page.dart';
import 'camera_page.dart';
import 'gps_page.dart';
import 'imu_page.dart';
import 'sensor_models.dart';

class SensorHubPage extends StatefulWidget {
  const SensorHubPage({super.key});

  @override
  State<SensorHubPage> createState() => _SensorHubPageState();
}

class _SensorHubPageState extends State<SensorHubPage> {
  @override
  void initState() {
    super.initState();
    ErrorReporter.recordInfo('Sensor hub opened', source: 'Navigation');
  }

  @override
  Widget build(BuildContext context) {
    final sensors = <SensorCapability>[
      const SensorCapability(
        title: 'GPS 定位',
        description: '前景定位、精度、時間戳、可用性狀態',
        status: SensorStatus.pending,
        icon: 'GPS',
      ),
      const SensorCapability(
        title: 'IMU',
        description: '陀螺儀、加速度計、取樣頻率與基本濾波',
        status: SensorStatus.pending,
        icon: 'IMU',
      ),
      const SensorCapability(
        title: 'BLE Beacon',
        description: 'Beacon 掃描、UUID/Major/Minor/RSSI 顯示',
        status: SensorStatus.pending,
        icon: 'BLE',
      ),
      const SensorCapability(
        title: 'Camera',
        description: '相機預覽、權限、效能檢查與後續視覺定位入口',
        status: SensorStatus.pending,
        icon: 'CAM',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('感測器測試中心'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sensors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final sensor = sensors[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(sensor.icon),
              ),
              title: Text(sensor.title),
              subtitle: Text(sensor.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusChip(status: sensor.status),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                final page = switch (sensor.title) {
                  'GPS 定位' => const GpsPage(),
                  'IMU' => const ImuPage(),
                  'BLE Beacon' => const BlePage(),
                  _ => const CameraPage(),
                };
                ErrorReporter.recordInfo(
                  'Open ${sensor.title} page',
                  source: 'Navigation',
                );
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => page),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SensorStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SensorStatus.ready => ('ready', Colors.green),
      SensorStatus.pending => ('pending', Colors.orange),
      SensorStatus.blocked => ('blocked', Colors.red),
    };

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.35)),
      labelStyle: TextStyle(color: color),
    );
  }
}
