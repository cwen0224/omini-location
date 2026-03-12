import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/error_reporter.dart';
import 'update_service.dart';

class UpdateStatusCard extends StatelessWidget {
  const UpdateStatusCard({
    super.key,
    required this.result,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onInstallUpdate,
    required this.installing,
    required this.installProgress,
    required this.installStatusMessage,
  });

  final UpdateCheckResult? result;
  final bool loading;
  final String error;
  final VoidCallback onRetry;
  final VoidCallback? onInstallUpdate;
  final bool installing;
  final double? installProgress;
  final String installStatusMessage;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: ListTile(
          title: Text('更新檢查中'),
          subtitle: Text('正在確認最新 APK 與內容版本'),
          trailing: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (error.isNotEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          title: const Text('更新檢查失敗'),
          subtitle: Text(error),
          trailing: IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }

    if (result == null) {
      return const SizedBox.shrink();
    }

    final manifest = result!.manifest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result!.hasUpdate ? Icons.system_update : Icons.verified,
                  color: result!.hasUpdate ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 10),
                Text(
                  result!.hasUpdate ? '發現新版本' : '已是最新版本',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '目前版本 ${result!.currentVersion}+${result!.currentBuildNumber}\n'
              '最新版本 ${manifest.appVersion}+${manifest.buildNumber}\n'
              '內容版本 ${manifest.contentVersion}',
            ),
            if (manifest.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '更新內容',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ...manifest.releaseNotes.map((item) => Text('• $item')),
            ],
            if (installStatusMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                installStatusMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (installing) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: installProgress != null && installProgress! > 0 && installProgress! < 1
                    ? installProgress
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (result!.hasUpdate)
                  FilledButton(
                    onPressed: installing ? null : onInstallUpdate,
                    child: Text(
                      installing
                          ? '更新中...'
                          : manifest.forceUpdate
                              ? '立即更新'
                              : '下載並安裝',
                    ),
                  ),
                if (result!.hasUpdate)
                  OutlinedButton(
                    onPressed: installing ? null : () => _openUrl(manifest.downloadPageUrl),
                    child: const Text('前往下載頁'),
                  ),
                OutlinedButton(
                  onPressed: installing ? null : onRetry,
                  child: const Text('重新檢查'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ErrorReporter.record(source: 'Update', message: 'Invalid update URL: $url');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      ErrorReporter.record(source: 'Update', message: 'Failed to open update URL: $url');
    }
  }
}
