import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

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

