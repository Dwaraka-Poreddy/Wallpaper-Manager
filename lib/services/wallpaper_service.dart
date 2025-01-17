import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';

import '../global.dart';
import 'wallpaper_provider.dart';

class WallpaperService {
  static Future<bool> setWallpaper(bool isInPublic) async {
    try {
      String urlOrPath =
          sharedPreferences!.getString('selectedImagePath') ?? "";

      File file = File(urlOrPath);

      int location = WallpaperManager.BOTH_SCREEN;

      final bool result =
          await WallpaperManager.setWallpaperFromFile(file.path, location);
      String newUrlOrPath = await WallpaperProvider.getWallpaperUrl(isInPublic);
      await sharedPreferences!.setString('selectedImagePath', newUrlOrPath);
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
