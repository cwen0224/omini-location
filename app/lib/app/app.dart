import 'package:flutter/material.dart';

import '../features/home/home_page.dart';

class HumanRightsMuseumApp extends StatelessWidget {
  const HumanRightsMuseumApp({super.key});

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
      home: const HomePage(),
    );
  }
}
