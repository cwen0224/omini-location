import 'package:flutter/material.dart';

import '../features/home/home_page.dart';

class HumanRightsMuseumApp extends StatelessWidget {
  const HumanRightsMuseumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '人權博物館APP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF355C4D),
          primary: const Color(0xFF355C4D),
          secondary: const Color(0xFFD1A15B),
          surface: const Color(0xFFF6F1E8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F1E8),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

