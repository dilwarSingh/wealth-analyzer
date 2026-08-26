import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'core/constants/app_strings.dart';
import 'core/theme/glassmorphism_theme.dart';
import 'features/portfolio/presentation/views/wealth_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage engine with explicit directory creation for Windows & Desktop
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    try {
      Directory baseDir;
      try {
        baseDir = await getApplicationSupportDirectory();
      } catch (_) {
        baseDir = await getApplicationDocumentsDirectory();
      }

      final storageDir = Directory(p.join(baseDir.path, 'wealth_analyzer_storage'));
      if (!await storageDir.exists()) {
        await storageDir.create(recursive: true);
      }
      Hive.init(storageDir.path);
    } catch (e) {
      // Fallback in case of sandboxing or restricted system documents
      await Hive.initFlutter();
    }
  }

  runApp(
    const ProviderScope(
      child: WealthAnalyzerApp(),
    ),
  );
}

class WealthAnalyzerApp extends StatelessWidget {
  const WealthAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: GlassmorphismTheme.darkTheme,
      home: const WealthDashboardScreen(),
    );
  }
}
