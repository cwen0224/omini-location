import 'package:flutter/material.dart';

import '../../core/error_reporter.dart';
import '../sensors/sensor_hub_page.dart';
import '../support/report_issue_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    ErrorReporter.recordInfo('Home page opened', source: 'Navigation');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('人權博物館APP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
