import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wallpaper_manager/services/wallpaper_provider.dart';
import 'package:wallpaper_manager/services/wallpaper_service.dart';
import 'package:workmanager/workmanager.dart'
    show Constraints, Workmanager, NetworkType;

import '../common/constants.dart';
import '../global.dart';

class WallpaperAutoRefreshService extends ChangeNotifier {
  Timer? _timer;
  bool isInPublic = false;
  bool isLoading = false;
  bool _autoRefresh = true;
  double _refreshInterval = 5.0;
  final StreamController<void> _updateController =
      StreamController<void>.broadcast();

  WallpaperAutoRefreshService() {
    _initializePublicMode();
    _loadPreferences();
    startBackgroundUpdates();
  }

  static const String taskName = 'wallpaperRefreshTask';

  Future<void> executeTask() async {
    await _checkAndUpdateWallpaperIfNeeded();
  }

  void startBackgroundUpdates() async {
    print("Called startBackgroundUpdates");
    double refreshInterval =
        sharedPreferences!.getDouble(SharedPreferenceKeys.refreshInterval) ??
            5.0;
    Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: Duration(minutes: refreshInterval.toInt()),
      constraints: Constraints(
        requiresBatteryNotLow: true,
        requiresCharging: false,
        networkType: NetworkType.not_required,
      ),
    );
  }

  Stream<void> get updates => _updateController.stream;

  Future<void> _initializePublicMode() async {
    isInPublic = await WallpaperProvider.isInPublic();
  }

  Future<void> _loadPreferences() async {
    _autoRefresh = sharedPreferences!
            .getBool(SharedPreferenceKeys.shouldAutoRefreshWallpaper) ??
        true;
    _refreshInterval =
        sharedPreferences!.getDouble(SharedPreferenceKeys.refreshInterval) ??
            5.0;
    if (_autoRefresh) {
      startAutoSetWallpaper();
    }
  }

  void startAutoSetWallpaper() {
    _timer = Timer.periodic(Duration(minutes: _refreshInterval.toInt()),
        (timer) async {
      await _checkAndUpdateWallpaperIfNeeded();
    });
  }

  Future<void> _checkAndUpdateWallpaperIfNeeded() async {
    if (_autoRefresh) {
      print("Updating wallpaper...");
      isLoading = true;
      isInPublic = await WallpaperProvider.isInPublic();
      await WallpaperService.setWallpaper(isInPublic: isInPublic);
      await WallpaperProvider.getWallpaperUrl(isInPublic);
      _updateController.add(null); // Notify listeners
      isLoading = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _updateController.close();
    super.dispose();
  }
}
