import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'beacon_registry.dart';

class ErrorReporter {
  ErrorReporter._();

  static final ValueNotifier<List<ReportEntry>> entries =
      ValueNotifier<List<ReportEntry>>(<ReportEntry>[]);

  static void install() {
    recordInfo('App bootstrap started');

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      record(
        source: 'FlutterError',
        message: details.exceptionAsString(),
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      record(
        source: 'PlatformDispatcher',
        message: error.toString(),
        stackTrace: stackTrace,
      );
      return true;
    };
  }

  static void recordInfo(String message, {String source = 'Lifecycle'}) {
    _pushEntry(
      ReportEntry(
        timestamp: DateTime.now(),
        level: ReportLevel.info,
        source: source,
        message: message,
      ),
    );
  }

  static void record({
    required String source,
    required String message,
    StackTrace? stackTrace,
  }) {
    _pushEntry(
      ReportEntry(
        timestamp: DateTime.now(),
        level: ReportLevel.error,
        source: source,
        message: message,
        stackTrace: stackTrace?.toString(),
      ),
    );
  }

  static void _pushEntry(ReportEntry entry) {
    final next = List<ReportEntry>.from(entries.value)..insert(0, entry);
    if (next.length > 30) {
      next.removeRange(30, next.length);
    }
    entries.value = next;
  }

  static Future<String> buildReport() async {
    final packageInfo = await PackageInfo.fromPlatform();
    await BeaconRegistry.instance.load();
    final buffer = StringBuffer()
      ..writeln('人權博物館APP 問題回報')
      ..writeln('時間: ${DateTime.now().toIso8601String()}')
      ..writeln('平台: ${Platform.operatingSystem}')
      ..writeln('平台版本: ${Platform.operatingSystemVersion}')
      ..writeln('App: ${packageInfo.appName}')
      ..writeln('版本: ${packageInfo.version}+${packageInfo.buildNumber}')
      ..writeln('模式: ${kReleaseMode ? 'release' : 'debug'}')
      ..writeln('')
      ..writeln('最近事件:')
      ..writeln(_formatEntries(ReportLevel.info))
      ..writeln('')
      ..writeln('已保存 Beacon:')
      ..writeln(_formatSavedBeacons())
      ..writeln('')
      ..writeln('最近錯誤:');

    buffer.writeln(_formatEntries(ReportLevel.error));

    return buffer.toString();
  }

  static String _formatEntries(ReportLevel level) {
    final filtered = entries.value.where((entry) => entry.level == level).take(10);
    if (filtered.isEmpty) {
      return '- 無紀錄';
    }

    final buffer = StringBuffer();
    for (final entry in filtered) {
      buffer.writeln(
        '- [${entry.timestamp.toIso8601String()}] ${entry.source}: ${entry.message}',
      );
      if (entry.stackTrace != null && entry.stackTrace!.isNotEmpty) {
        buffer.writeln(entry.stackTrace);
      }
    }
    return buffer.toString().trimRight();
  }

  static String _formatSavedBeacons() {
    final beacons = BeaconRegistry.instance.beacons;
    if (beacons.isEmpty) {
      return '- 無紀錄';
    }

    final buffer = StringBuffer();
    for (final beacon in beacons) {
      buffer.writeln(
        '- ${beacon.displayName} | key=${beacon.beaconKey} | id=${beacon.remoteId} | rssi=${beacon.lastRssi}',
      );
      if (beacon.manufacturerHex.isNotEmpty) {
        buffer.writeln('  manufacturer=${beacon.manufacturerHex}');
      }
      if (beacon.serviceDataHex.isNotEmpty) {
        buffer.writeln('  serviceData=${beacon.serviceDataHex}');
      }
    }
    return buffer.toString().trimRight();
  }
}

enum ReportLevel {
  info,
  error,
}

class ReportEntry {
  const ReportEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
    this.stackTrace,
  });

  final DateTime timestamp;
  final ReportLevel level;
  final String source;
  final String message;
  final String? stackTrace;
}
