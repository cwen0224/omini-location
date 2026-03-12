import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import '../../core/error_reporter.dart';
import 'update_manifest.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.manifest,
    required this.hasUpdate,
  });

  final String currentVersion;
  final int currentBuildNumber;
  final UpdateManifest manifest;
  final bool hasUpdate;
}

class UpdateService {
  UpdateService();

  static const String manifestUrl =
      'https://cwen0224.github.io/omini-location/version.json';
  static const MethodChannel _installerChannel =
      MethodChannel('human_rights_museum_app/update_installer');

  Future<UpdateCheckResult> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    final response = await http.get(Uri.parse(manifestUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Update manifest request failed: ${response.statusCode}');
    }

    final manifest = UpdateManifest.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    final hasUpdate = _compareVersions(
              manifest.appVersion,
              currentVersion,
            ) >
            0 ||
        manifest.buildNumber > currentBuildNumber;

    ErrorReporter.recordInfo(
      'Update check completed: current=$currentVersion+$currentBuildNumber latest=${manifest.appVersion}+${manifest.buildNumber} update=$hasUpdate',
      source: 'Update',
    );

    return UpdateCheckResult(
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      manifest: manifest,
      hasUpdate: hasUpdate,
    );
  }

  Future<void> cleanupStagedApks() async {
    if (!Platform.isAndroid) {
      return;
    }

    final directory = await _stagingDirectory();
    if (!await directory.exists()) {
      return;
    }

    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.apk')) {
        continue;
      }
      try {
        await entity.delete();
      } catch (error, stackTrace) {
        ErrorReporter.record(
          source: 'Update',
          message: 'Failed to delete staged APK: ${entity.path} ($error)',
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<DownloadedUpdate> downloadUpdate(
    UpdateManifest manifest, {
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('In-app APK updates are only supported on Android.');
    }

    await cleanupStagedApks();

    final uri = Uri.tryParse(manifest.apkUrl);
    if (uri == null) {
      throw Exception('Invalid APK URL: ${manifest.apkUrl}');
    }

    final request = http.Request('GET', uri);
    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('APK download failed: ${response.statusCode}');
    }

    final directory = await _stagingDirectory();
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}app-update-${manifest.appVersion}+${manifest.buildNumber}.apk',
    );
    final sink = file.openWrite();

    final expectedBytes = response.contentLength ?? 0;
    var downloadedBytes = 0;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (expectedBytes > 0) {
          onProgress?.call(downloadedBytes / expectedBytes);
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    onProgress?.call(1);
    ErrorReporter.recordInfo(
      'APK downloaded to ${file.path}',
      source: 'Update',
    );

    return DownloadedUpdate(
      file: file,
      appVersion: manifest.appVersion,
      buildNumber: manifest.buildNumber,
    );
  }

  Future<InstallLaunchResult> launchInstaller(File file) async {
    if (!Platform.isAndroid) {
      return const InstallLaunchResult(
        status: InstallLaunchStatus.unsupported,
        message: 'Only Android supports APK installation.',
      );
    }

    final canInstall =
        await _installerChannel.invokeMethod<bool>('canInstallPackages') ?? false;
    if (!canInstall) {
      await _installerChannel.invokeMethod<void>('openInstallPermissionSettings');
      return const InstallLaunchResult(
        status: InstallLaunchStatus.permissionRequired,
        message: '請允許此 App 安裝未知來源應用程式，返回後再按一次更新。',
      );
    }

    final launched = await _installerChannel.invokeMethod<bool>(
          'installApk',
          <String, dynamic>{'path': file.path},
        ) ??
        false;

    if (!launched) {
      return const InstallLaunchResult(
        status: InstallLaunchStatus.failed,
        message: '無法開啟 Android 安裝器。',
      );
    }

    ErrorReporter.recordInfo(
      'Android installer launched for ${file.path}',
      source: 'Update',
    );

    return const InstallLaunchResult(
      status: InstallLaunchStatus.launched,
      message: '已開啟 Android 安裝器。安裝完成後，舊 APK 暫存會在下次更新前自動清理。',
    );
  }

  Future<Directory> _stagingDirectory() async {
    final cacheDirectory = await getTemporaryDirectory();
    return Directory(
      '${cacheDirectory.path}${Platform.pathSeparator}apk_updates',
    );
  }

  int _compareVersions(String left, String right) {
    final leftParts = left.split('.').map(int.tryParse).map((e) => e ?? 0);
    final rightParts = right.split('.').map(int.tryParse).map((e) => e ?? 0);
    final maxLength =
        left.split('.').length > right.split('.').length
            ? left.split('.').length
            : right.split('.').length;
    final l = leftParts.toList();
    final r = rightParts.toList();

    for (var i = 0; i < maxLength; i += 1) {
      final lv = i < l.length ? l[i] : 0;
      final rv = i < r.length ? r[i] : 0;
      if (lv != rv) {
        return lv.compareTo(rv);
      }
    }
    return 0;
  }
}

class DownloadedUpdate {
  const DownloadedUpdate({
    required this.file,
    required this.appVersion,
    required this.buildNumber,
  });

  final File file;
  final String appVersion;
  final int buildNumber;
}

enum InstallLaunchStatus {
  launched,
  permissionRequired,
  failed,
  unsupported,
}

class InstallLaunchResult {
  const InstallLaunchResult({
    required this.status,
    required this.message,
  });

  final InstallLaunchStatus status;
  final String message;
}
