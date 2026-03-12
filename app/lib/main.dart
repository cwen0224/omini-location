import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/error_reporter.dart';
import 'core/remote_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RemoteSyncService.instance.initialize();
  ErrorReporter.install();
  ErrorReporter.recordInfo('Widgets binding ready');
  runApp(const HumanRightsMuseumApp());
  ErrorReporter.recordInfo('runApp completed');
}
