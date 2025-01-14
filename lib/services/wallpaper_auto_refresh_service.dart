import 'dart:async';

import 'package:wallpaper_manager/services/wallpaper_provider.dart';
import 'package:wallpaper_manager/services/wallpaper_service.dart';

class WallpaperAutoRefreshService {
  Timer? _timer;
  bool isInPublic = false;
  bool isLoading = false;

  WallpaperAutoRefreshService() {
    _initializePublicMode();
    _startAutoFetch();
  }

  Future<void> _initializePublicMode() async {
    isInPublic = await WallpaperProvider.isInPublic();
  }

  Future<void> _fetchAnotherWallpaper() async {
    isLoading = true;
    await WallpaperProvider.getWallpaperUrl(isInPublic);
    isLoading = false;
  }

  Future<void> _setWallpaper() async {
    isLoading = true;
    await WallpaperService.setWallpaper(isInPublic);
    isLoading = false;
  }

  void _startAutoFetch() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _fetchAnotherWallpaper();
      await _setWallpaper();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
