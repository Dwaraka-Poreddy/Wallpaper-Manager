import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaper_manager/screens/home_screen.dart';
import 'package:wallpaper_manager/services/wallpaper_auto_refresh_service.dart';
import 'package:workmanager/workmanager.dart';

import 'global.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  runApp(
    ChangeNotifierProvider<WallpaperAutoRefreshService>(
      create: (context) => WallpaperAutoRefreshService(),
      child: const MyApp(),
    ),
  );
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Task executing :$task");
    // Define the tasks to be executed in the background
    switch (task) {
      case WallpaperAutoRefreshService.taskName:
        final service = WallpaperAutoRefreshService();
        await service.executeTask();
        break;
    }
    return Future.value(true);
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
