import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'wallpaper_provider.dart';

class WallpaperService {
  static Future<bool> setWallpaper(bool isInPublic) async {
    try {
      final cache = DefaultCacheManager();
      String urlOrPath = await WallpaperProvider.getWallpaperUrl(isInPublic);

      File file;
      if (urlOrPath.startsWith('http')) {
        // Download file if it's a network URL
        file = await cache.getSingleFile(urlOrPath);

        // Save the downloaded file locally for future use
        final directory = await getApplicationDocumentsDirectory();
        final fileName = Uri.parse(urlOrPath).pathSegments.last;
        final localFile = File('${directory.path}/images/$fileName');
        if (!localFile.existsSync()) {
          await localFile.writeAsBytes(await file.readAsBytes());
        }
      } else {
        // Use local file directly
        file = File(urlOrPath);
      }

      int location = WallpaperManager.BOTH_SCREEN;

      final bool result =
          await WallpaperManager.setWallpaperFromFile(file.path, location);
      return result;
    } on PlatformException catch (e) {
      print("Failed to set wallpaper: $e");
      return false;
    }
  }

  static Future<void> clearWallpaper() async {
    await WallpaperManager.clearWallpaper();
  }
}
