import 'package:flutter/material.dart';

import '../../core/remote_backend_config.dart';

class SyncOverviewPage extends StatelessWidget {
  const SyncOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('雲端同步規劃')),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
    );
  }
}
