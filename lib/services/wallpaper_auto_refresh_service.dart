import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wallpaper_manager/services/wallpaper_provider.dart';
import 'package:wallpaper_manager/services/wallpaper_service.dart';

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
      _startAutoFetch();
    }
  }

  void _startAutoFetch() {
    _timer = Timer.periodic(Duration(minutes: _refreshInterval.toInt()),
        (timer) async {
      if (_autoRefresh) {
        print("Updating wallpaper...");
        isLoading = true;
        isInPublic = await WallpaperProvider.isInPublic();
        await WallpaperService.setWallpaper(isInPublic: isInPublic);
        await WallpaperProvider.getWallpaperUrl(isInPublic);
        _updateController.add(null); // Notify listeners
        isLoading = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _updateController.close();
    super.dispose();
  }
}
