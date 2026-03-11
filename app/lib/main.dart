import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/error_reporter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorReporter.install();
  runApp(const HumanRightsMuseumApp());
}
