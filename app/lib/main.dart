import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/error_reporter.dart';
import 'core/remote_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorReporter.install();
  ErrorReporter.recordInfo('Widgets binding ready');
  try {
    await RemoteSyncService.instance.initialize();
    ErrorReporter.recordInfo('Supabase initialized', source: 'RemoteSync');
  } catch (error, stackTrace) {
    ErrorReporter.record(
      source: 'RemoteSync',
      message: 'Supabase initialize failed: $error',
      stackTrace: stackTrace,
    );
  }
  runApp(const HumanRightsMuseumApp());
  ErrorReporter.recordInfo('runApp completed');
}
