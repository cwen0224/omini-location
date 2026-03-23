import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_capture_service.dart';
import '../../core/error_reporter.dart';
import '../../core/remote_sync_service.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String _report = '載入中...';
  bool _copying = false;
  bool _uploading = false;

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

  Future<void> _uploadReport() async {
    setState(() {
      _uploading = true;
    });
    try {
      final latestError = ErrorReporter.latestErrorEntry;
      final capture = AppCaptureService.instance.latestCapture;
      final fileName = capture == null
          ? 'issue-screenshot.png'
          : 'issue-${capture.capturedAt.toIso8601String().replaceAll(':', '-')}.png';
      await RemoteSyncService.instance.uploadIssueReport(
        report: _report,
        errorSource: latestError?.source ?? 'manual_report',
        stackTrace: latestError?.stackTrace,
        contextJson: <String, dynamic>{
          'report_length': _report.length,
          'report_captured_at': DateTime.now().toIso8601String(),
          if (latestError != null) ...<String, dynamic>{
            'latest_error_source': latestError.source,
            'latest_error_level': latestError.level.name,
            'latest_error_message': latestError.message,
          },
        },
        screenshotBytes: capture?.bytes,
        screenshotFileName: fileName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            capture == null
                ? '問題回報已上傳到 Supabase'
                : '問題回報與截圖已上傳到 Supabase',
          ),
        ),
      );
    } catch (error, stackTrace) {
      ErrorReporter.record(
        source: 'RemoteSync',
        message: 'Upload issue report failed: $error',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上傳失敗：$error')),
      );
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
      appBar: AppBar(title: const Text('回報問題')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            padding: EdgeInsets.only(top: 20, bottom: bottomInset),
            children: [
              Text(
                '遇到錯誤時，可先按右下角「回報」保留目前畫面，再把除錯資訊和截圖一起上傳。',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              if (AppCaptureService.instance.latestCapture != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('將隨回報上傳目前畫面截圖'),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          AppCaptureService.instance.latestCapture!.bytes,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: _copying ? null : _copyReport,
                    child: Text(_copying ? '複製中...' : '複製除錯資訊'),
                  ),
                  FilledButton.tonal(
                    onPressed: _uploading ? null : _uploadReport,
                    child: Text(_uploading ? '上傳中...' : '上傳到雲端'),
                  ),
                  OutlinedButton(
                    onPressed: _loadReport,
                    child: const Text('重新整理'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 360),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: SelectableText(_report),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
