import 'package:flutter/material.dart';

import '../core/app_capture_service.dart';
import '../core/error_reporter.dart';
import '../features/home/home_page.dart';
import '../features/support/report_issue_page.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class HumanRightsMuseumApp extends StatelessWidget {
  const HumanRightsMuseumApp({super.key});

  Future<void> _openReportFlow() async {
    try {
      await AppCaptureService.instance
          .captureVisibleApp()
          .timeout(const Duration(milliseconds: 800));
    } catch (error, stackTrace) {
      ErrorReporter.record(
        source: 'ReportFlow',
        message: 'Capture visible app failed: $error',
        stackTrace: stackTrace,
      );
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      ErrorReporter.record(
        source: 'ReportFlow',
        message: 'Navigator unavailable while opening report page.',
      );
      return;
    }

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const ReportIssuePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4D8B6E);
    final scheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: seed,
      primary: const Color(0xFF7DD3A7),
      secondary: const Color(0xFF5FB6FF),
      surface: const Color(0xFF172028),
    );

    return MaterialApp(
      title: '人權博物館APP',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0F1419),
        cardColor: const Color(0xFF172028),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1419),
          foregroundColor: Color(0xFFEEF3F7),
          surfaceTintColor: Colors.transparent,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF203128),
          contentTextStyle: TextStyle(color: Color(0xFFEEF3F7)),
        ),
        dividerColor: const Color(0x26FFFFFF),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Stack(
          children: [
            RepaintBoundary(
              key: AppCaptureService.instance.boundaryKey,
              child: child ?? const SizedBox.shrink(),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: _openReportFlow,
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('回報'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      home: const HomePage(),
    );
  }
}
