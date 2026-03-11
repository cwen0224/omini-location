import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/error_reporter.dart';
import 'sensor_models.dart';
import 'sensor_page_scaffold.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  String _permissionState = '未檢查';
  String _error = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final permission = await Permission.camera.request();
    setState(() {
      _permissionState = permission.toString();
    });

    if (!permission.isGranted) {
      setState(() {
        _error = '相機權限未授權';
        _loading = false;
      });
      ErrorReporter.record(source: 'Camera', message: _error);
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = '找不到可用相機';
          _loading = false;
        });
        ErrorReporter.record(source: 'Camera', message: _error);
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameras = cameras;
        _controller = controller;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _loading = false;
      });
      ErrorReporter.record(source: 'Camera', message: _error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller?.value.isInitialized ?? false;

    return SensorPageScaffold(
      title: 'Camera 測試',
      summary: '驗證相機權限、預覽與後續視覺定位所需的影像資料入口。',
      status: ready
          ? SensorStatus.ready
          : (_error.isNotEmpty ? SensorStatus.blocked : SensorStatus.pending),
      actions: [
        FilledButton(
          onPressed: _loading ? null : _setupCamera,
          child: const Text('重新初始化'),
        ),
      ],
      readings: [
        SensorReading(label: '權限', value: _permissionState),
        SensorReading(label: '相機數量', value: '${_cameras.length}'),
        SensorReading(
          label: '預覽狀態',
          value: ready ? '已初始化' : (_loading ? '初始化中' : '未初始化'),
        ),
      ],
      footer: Column(
        children: [
          if (ready)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CameraPreview(_controller!),
              ),
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
    );
  }
}
