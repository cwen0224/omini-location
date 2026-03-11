import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/error_reporter.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String _report = '載入中...';
  bool _copying = false;

  @override
  void initState() {
    super.initState();
    ErrorReporter.recordInfo('Report issue page opened', source: 'Navigation');
    _loadReport();
    ErrorReporter.entries.addListener(_loadReport);
  }

  @override
  void dispose() {
    ErrorReporter.entries.removeListener(_loadReport);
    super.dispose();
  }

  Future<void> _loadReport() async {
    final report = await ErrorReporter.buildReport();
    if (!mounted) return;
    setState(() {
      _report = report;
    });
  }

  Future<void> _copyReport() async {
    setState(() {
      _copying = true;
    });
    await Clipboard.setData(ClipboardData(text: _report));
    if (!mounted) return;
    setState(() {
      _copying = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('除錯資訊已複製，可直接貼給我')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('回報問題')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '遇到錯誤時，先截圖，再按「複製除錯資訊」貼給我。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: _copying ? null : _copyReport,
                  child: Text(_copying ? '複製中...' : '複製除錯資訊'),
                ),
                OutlinedButton(
                  onPressed: _loadReport,
                  child: const Text('重新整理'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(_report),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
