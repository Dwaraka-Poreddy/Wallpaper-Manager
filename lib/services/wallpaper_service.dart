import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:wallpaper_manager/utils/string_extensions.dart';

import '../common/constants.dart';
import '../global.dart';
import 'logger_service.dart';
import 'wallpaper_provider.dart';

class WallpaperService {
  static Future<bool> setWallpaper({
    String? filePath,
    required bool isInPublic,
  }) async {
    final logger = await LoggerService.getInstance();
    try {
      await logger.info(
          "Setting wallpaper - Public: $isInPublic, Custom path: ${filePath != null}",
          source: 'WALLPAPER_SERVICE');

      late File file;
      if (filePath.isNotNullOrEmpty()) {
        file = File(filePath!);
        await logger.debug("Using custom file path: $filePath",
            source: 'WALLPAPER_SERVICE');
      } else {
        String urlOrPath = sharedPreferences!.getString(
              SharedPreferenceKeys.selectedImagePath,
            ) ??
            "";
        file = File(urlOrPath);
        await logger.debug("Using stored file path: $urlOrPath",
            source: 'WALLPAPER_SERVICE');
      }

      if (!await file.exists()) {
        await logger.error("Wallpaper file does not exist: ${file.path}",
            source: 'WALLPAPER_SERVICE');
        return false;
      }

      int location = WallpaperManager.BOTH_SCREEN;

      final bool result =
          await WallpaperManager.setWallpaperFromFile(file.path, location);
      await logger.info("Wallpaper set result: $result",
          source: 'WALLPAPER_SERVICE');

      if (result) {
        String newUrlOrPath =
            await WallpaperProvider.getWallpaperUrl(isInPublic);
        await sharedPreferences!.setString(
          SharedPreferenceKeys.selectedImagePath,
          newUrlOrPath,
        );
        await logger.debug("Updated selected image path to: $newUrlOrPath",
            source: 'WALLPAPER_SERVICE');
      }

      return result;
    } on PlatformException catch (e) {
      print("Failed to set wallpaper: $e");
      await logger.error("Platform exception setting wallpaper: $e",
          source: 'WALLPAPER_SERVICE');
      return false;
    } catch (e) {
      await logger.error("Unexpected error setting wallpaper: $e",
          source: 'WALLPAPER_SERVICE');
      return false;
    }
  }

  static Future<void> clearWallpaper() async {
    final logger = await LoggerService.getInstance();
    try {
      await logger.info("Clearing wallpaper", source: 'WALLPAPER_SERVICE');
      await WallpaperManager.clearWallpaper();
      await logger.info("Wallpaper cleared successfully",
          source: 'WALLPAPER_SERVICE');
    } catch (e) {
      await logger.error("Error clearing wallpaper: $e",
          source: 'WALLPAPER_SERVICE');
    }
  }
}
