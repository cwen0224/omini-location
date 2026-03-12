import 'package:flutter/material.dart';

import '../../core/error_reporter.dart';
import '../sensors/sensor_hub_page.dart';
import '../support/report_issue_page.dart';
import '../sync/sync_overview_page.dart';
import '../update/update_service.dart';
import '../update/update_status_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UpdateService _updateService = UpdateService();
  UpdateCheckResult? _updateResult;
  String _updateError = '';
  bool _checkingUpdate = false;
  bool _installingUpdate = false;
  double? _installProgress;
  String _installStatusMessage = '';

  @override
  void initState() {
    super.initState();
    ErrorReporter.recordInfo('Home page opened', source: 'Navigation');
    _prepareUpdateWorkspace();
    _checkForUpdates();
  }

  Future<void> _prepareUpdateWorkspace() async {
    try {
      await _updateService.cleanupStagedApks();
    } catch (error, stackTrace) {
      ErrorReporter.record(
        source: 'Update',
        message: 'Failed to prepare update workspace: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingUpdate = true;
      _updateError = '';
    });

    try {
      final result = await _updateService.checkForUpdate();
      if (!mounted) return;
      setState(() {
        _updateResult = result;
        _checkingUpdate = false;
      });
    } catch (error, stackTrace) {
      ErrorReporter.record(
        source: 'Update',
        message: error.toString(),
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _updateError = '無法取得更新資訊';
        _checkingUpdate = false;
      });
    }
  }

  Future<void> _installUpdate() async {
    final result = _updateResult;
    if (result == null || !result.hasUpdate) {
      return;
    }

    setState(() {
      _installingUpdate = true;
      _installProgress = null;
      _installStatusMessage = '正在清理舊更新檔...';
      _updateError = '';
    });

    try {
      final downloaded = await _updateService.downloadUpdate(
        result.manifest,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            _installProgress = progress;
            _installStatusMessage =
                '下載更新中 ${(progress * 100).toStringAsFixed(0)}%';
          });
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _installStatusMessage = '正在開啟 Android 安裝器...';
      });

      final launchResult = await _updateService.launchInstaller(downloaded.file);
      if (!mounted) {
        return;
      }

      setState(() {
        _installingUpdate = false;
        _installProgress = launchResult.status == InstallLaunchStatus.launched
            ? 1
            : null;
        _installStatusMessage = launchResult.message;
      });
    } catch (error, stackTrace) {
      ErrorReporter.record(
        source: 'Update',
        message: 'In-app update failed: $error',
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _installingUpdate = false;
        _installProgress = null;
        _installStatusMessage = '';
        _updateError = 'App 內更新失敗，請改用下載頁更新。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 24;
    final hasUpdate = _updateResult?.hasUpdate ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('人權博物館APP'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset),
          children: [
            UpdateStatusCard(
              result: _updateResult,
              loading: _checkingUpdate,
              error: _updateError,
              onRetry: _checkForUpdates,
              onInstallUpdate: hasUpdate ? _installUpdate : null,
              installing: _installingUpdate,
              installProgress: _installProgress,
              installStatusMessage: _installStatusMessage,
            ),
            const SizedBox(height: 20),
            Text(
              'MVP 骨架',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              '第一階段先驗證 Android 裝置上的 GPS、IMU、BLE Beacon 與 Camera 權限與資料流。',
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                title: const Text('感測器測試中心'),
                subtitle: const Text('檢查裝置能力、權限狀態與感測器資料流'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ErrorReporter.recordInfo(
                    'Open sensor hub',
                    source: 'Navigation',
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SensorHubPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('回報問題'),
                subtitle: const Text('複製除錯資訊，快速貼給 AI 排查'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ErrorReporter.recordInfo(
                    'Open report issue page',
                    source: 'Navigation',
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportIssuePage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('雲端同步規劃'),
                subtitle: const Text('檢查錯誤回報、Beacon、測試資料與 AR 媒體的雲端結構'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ErrorReporter.recordInfo(
                    'Open sync overview page',
                    source: 'Navigation',
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SyncOverviewPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                title: Text('開發狀態'),
                subtitle: Text('目前為 Flutter 骨架與感測器頁面占位版本'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

