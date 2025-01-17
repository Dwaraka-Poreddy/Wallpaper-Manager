import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:wallpaper_manager/utils/string_extensions.dart';

import '../common/constants.dart';
import '../global.dart';
import 'wallpaper_provider.dart';

class WallpaperService {
  static Future<bool> setWallpaper({
    String? filePath,
    required bool isInPublic,
  }) async {
    try {
      late File file;
      if (filePath.isNotNullOrEmpty()) {
        file = File(filePath!);
      } else {
        String urlOrPath = sharedPreferences!.getString(
              SharedPreferenceKeys.selectedImagePath,
            ) ??
            "";
        file = File(urlOrPath);
      }

      int location = WallpaperManager.BOTH_SCREEN;

      final bool result =
          await WallpaperManager.setWallpaperFromFile(file.path, location);
      String newUrlOrPath = await WallpaperProvider.getWallpaperUrl(isInPublic);
      await sharedPreferences!.setString(
        SharedPreferenceKeys.selectedImagePath,
        newUrlOrPath,
      );
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
