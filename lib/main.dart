import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaper_manager/screens/home_screen.dart';
import 'package:wallpaper_manager/services/wallpaper_auto_refresh_service.dart';
import 'package:workmanager/workmanager.dart';

import 'global.dart';
import 'services/logger_service.dart';
import 'services/wallpaper_provider.dart';
import 'services/wallpaper_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();

  final logger = await LoggerService.getInstance();
  await logger.info("App starting - initializing WorkManager", source: 'MAIN');

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  await logger.info("WorkManager initialized successfully", source: 'MAIN');

  runApp(
    ChangeNotifierProvider<WallpaperAutoRefreshService>(
      create: (context) => WallpaperAutoRefreshService(),
      child: const MyApp(),
    ),
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize LoggerService for background task
      final logger = await LoggerService.getInstance();
      await logger.info("Task started: $task with data: $inputData",
          source: 'BACKGROUND');

      // Initialize SharedPreferences for background task
      final prefs = await SharedPreferences.getInstance();
      await logger.debug("SharedPreferences initialized in background",
          source: 'BACKGROUND');

      // Check if auto-refresh is enabled
      final autoRefresh =
          prefs.getBool('should_auto_refresh_wallpaper') ?? true;
      await logger.info("Auto-refresh setting: $autoRefresh",
          source: 'BACKGROUND');

      if (!autoRefresh) {
        await logger.warning(
            "Auto-refresh is disabled, skipping wallpaper update",
            source: 'BACKGROUND');
        return Future.value(true);
      }

      // Get current mode (public/private)
      final isInPublic = prefs.getBool('isInPublic') ?? false;
      await logger.info("Current mode - Public: $isInPublic",
          source: 'BACKGROUND');

      // Update wallpaper
      await logger.info(
          "Starting wallpaper update in background (app in killed state)",
          source: 'BACKGROUND');

      final startTime = DateTime.now();
      bool success =
          await WallpaperService.setWallpaper(isInPublic: isInPublic);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (success) {
        await logger.info(
            "✅ WALLPAPER UPDATE SUCCESS - Duration: ${duration.inMilliseconds}ms, Mode: ${isInPublic ? 'Public' : 'Private'}",
            source: 'BACKGROUND');

        try {
          await WallpaperProvider.getWallpaperUrl(isInPublic);
          await logger.info("New wallpaper URL/path cached successfully",
              source: 'BACKGROUND');
        } catch (urlError) {
          await logger.warning("Failed to cache new wallpaper URL: $urlError",
              source: 'BACKGROUND');
        }

        // Save the successful update time
        await prefs.setInt(
            'last_wallpaper_update', DateTime.now().millisecondsSinceEpoch);

        // Log next scheduled update time
        final nextUpdate = DateTime.now().add(Duration(
            minutes: (prefs.getDouble('refreshInterval') ?? 5.0).toInt()));
        await logger.info(
            "Next background update scheduled for: ${nextUpdate.toString()}",
            source: 'BACKGROUND');
      } else {
        await logger.error(
            "❌ WALLPAPER UPDATE FAILED - Duration: ${duration.inMilliseconds}ms, Mode: ${isInPublic ? 'Public' : 'Private'}",
            source: 'BACKGROUND');
      }

      await logger.info(
          "Background wallpaper task completed - Success: $success",
          source: 'BACKGROUND');
      return Future.value(true);
    } catch (e, stackTrace) {
      try {
        final logger = await LoggerService.getInstance();
        await logger.error("❌ CRITICAL BACKGROUND TASK FAILURE",
            source: 'BACKGROUND');
        await logger.error("Error Type: ${e.runtimeType}",
            source: 'BACKGROUND');
        await logger.error("Error Details: $e", source: 'BACKGROUND');
        await logger.error(
            "Stack Trace: ${stackTrace.toString().split('\n').take(5).join('\n')}",
            source: 'BACKGROUND');

        // Log system state for debugging
        final prefs = await SharedPreferences.getInstance();
        final autoRefresh =
            prefs.getBool('should_auto_refresh_wallpaper') ?? true;
        final isInPublic = prefs.getBool('isInPublic') ?? false;
        final interval = prefs.getDouble('refreshInterval') ?? 5.0;

        await logger.error(
            "System state - AutoRefresh: $autoRefresh, Mode: ${isInPublic ? 'Public' : 'Private'}, Interval: ${interval}min",
            source: 'BACKGROUND');
      } catch (logError) {
        // Fallback if LoggerService fails - this should rarely happen
        // Note: Avoiding print in production, but this is a critical fallback
      }
      return Future.value(false);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}
