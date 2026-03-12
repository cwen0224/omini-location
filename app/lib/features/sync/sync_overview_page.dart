import 'package:flutter/material.dart';

import '../../core/remote_backend_config.dart';
import '../../core/remote_sync_service.dart';

class SyncOverviewPage extends StatefulWidget {
  const SyncOverviewPage({super.key});

  @override
  State<SyncOverviewPage> createState() => _SyncOverviewPageState();
}

class _SyncOverviewPageState extends State<SyncOverviewPage> {
  bool _uploading = false;
  String _status = '';

  Future<void> _createTestSession() async {
    setState(() {
      _uploading = true;
      _status = '';
    });

    try {
      final sessionId = await RemoteSyncService.instance.createTestSession(
        sessionName: 'manual-test-${DateTime.now().millisecondsSinceEpoch}',
        testType: 'all_module_manual',
        metadata: <String, dynamic>{
          'created_from': 'sync_overview_page',
          'content_version': '2026.03.12.6',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      setState(() {
        _status = '已建立測試 Session：$sessionId';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = '建立失敗：$error';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      appBar: AppBar(title: const Text('雲端同步規劃')),
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
                      RemoteBackendConfig.enabled ? '已配置遠端後端' : '尚未配置遠端後端',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      RemoteBackendConfig.enabled
                          ? '目前 provider: ${RemoteBackendConfig.provider}'
                          : '填入 Supabase URL 與 anon key 後，即可開始串接錯誤回報、Beacon 標記資料與 AR 錄影上傳。',
                    ),
                    if (RemoteBackendConfig.enabled) ...[
                      const SizedBox(height: 8),
                      Text('Project URL: ${RemoteBackendConfig.supabaseUrl}'),
                      const SizedBox(height: 8),
                      Text(
                        RemoteSyncService.instance.isReady
                            ? 'Supabase 已初始化，可開始讀寫'
                            : RemoteSyncService.instance.isConfigured
                                ? 'Supabase 設定已寫入，但初始化失敗'
                                : 'Supabase 尚未完成設定',
                      ),
                      if (RemoteSyncService.instance.initializationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '初始化錯誤: ${RemoteSyncService.instance.initializationError}',
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _uploading || !RemoteSyncService.instance.isReady
                            ? null
                            : _createTestSession,
                        child: Text(_uploading ? '建立中...' : '建立測試 Session'),
                      ),
                      if (_status.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(_status),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                title: Text('錯誤回報表'),
                subtitle: Text('app_errors: 儲存錯誤訊息、stack trace、版本與裝置資訊'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                title: Text('Beacon 標記表'),
                subtitle: Text('beacon_registry: 儲存 Beacon key、名稱、RSSI 與你手動標記資料'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                title: Text('測試 Session 表'),
                subtitle: Text('test_sessions: 儲存定位測試、備註、地點與關聯檔案'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                title: Text('AR 錄影儲存桶'),
                subtitle: Text('ar-media: 儲存錄影、截圖、附帶 metadata，再由資料表存 URL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
