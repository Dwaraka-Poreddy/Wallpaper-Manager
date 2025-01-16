import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wallpaper_manager/services/wallpaper_provider.dart';
import 'package:wallpaper_manager/services/wallpaper_service.dart';

class WallpaperAutoRefreshService extends ChangeNotifier {
  Timer? _timer;
  bool isInPublic = false;
  bool isLoading = false;
  final StreamController<void> _updateController =
      StreamController<void>.broadcast();

  WallpaperAutoRefreshService() {
    _initializePublicMode();
    _startAutoFetch();
  }

  Stream<void> get updates => _updateController.stream;

  Future<void> _initializePublicMode() async {
    isInPublic = await WallpaperProvider.isInPublic();
  }

  void _startAutoFetch() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      print("Updating wallpaper...");
      isLoading = true;
      isInPublic = await WallpaperProvider.isInPublic();
      await WallpaperService.setWallpaper(isInPublic);
      await WallpaperProvider.getWallpaperUrl(isInPublic);
      _updateController.add(null); // Notify listeners
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _updateController.close();
    super.dispose();
  }
}
