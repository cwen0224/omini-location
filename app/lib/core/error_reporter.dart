import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ErrorReporter {
  ErrorReporter._();

  static final ValueNotifier<List<ErrorEntry>> entries =
      ValueNotifier<List<ErrorEntry>>(<ErrorEntry>[]);

  static void install() {
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

  static void record({
    required String source,
    required String message,
    StackTrace? stackTrace,
  }) {
    final next = List<ErrorEntry>.from(entries.value)
      ..insert(
        0,
        ErrorEntry(
          timestamp: DateTime.now(),
          source: source,
          message: message,
          stackTrace: stackTrace?.toString(),
        ),
      );

    if (next.length > 30) {
      next.removeRange(30, next.length);
    }
    entries.value = next;
  }

  static Future<String> buildReport() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final buffer = StringBuffer()
      ..writeln('人權博物館APP 問題回報')
      ..writeln('時間: ${DateTime.now().toIso8601String()}')
      ..writeln('平台: ${Platform.operatingSystem}')
      ..writeln('平台版本: ${Platform.operatingSystemVersion}')
      ..writeln('App: ${packageInfo.appName}')
      ..writeln('版本: ${packageInfo.version}+${packageInfo.buildNumber}')
      ..writeln('模式: ${kReleaseMode ? 'release' : 'debug'}')
      ..writeln('')
      ..writeln('最近錯誤:');

    if (entries.value.isEmpty) {
      buffer.writeln('- 無紀錄');
    } else {
      for (final entry in entries.value.take(10)) {
        buffer.writeln(
          '- [${entry.timestamp.toIso8601String()}] ${entry.source}: ${entry.message}',
        );
        if (entry.stackTrace != null && entry.stackTrace!.isNotEmpty) {
          buffer.writeln(entry.stackTrace);
        }
      }
    }

    return buffer.toString();
  }
}

class ErrorEntry {
  const ErrorEntry({
    required this.timestamp,
    required this.source,
    required this.message,
    this.stackTrace,
  });

  final DateTime timestamp;
  final String source;
  final String message;
  final String? stackTrace;
}

