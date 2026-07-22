// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PitakaApp()));
}

class PitakaApp extends StatelessWidget {
  const PitakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pitaka',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const HomeShell(),
    );
  }
}
