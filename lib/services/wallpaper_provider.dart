import 'dart:io';
import 'dart:math';

import '../global.dart';
import 'cache_service.dart';

class WallpaperProvider {
  // Remove static URL lists
  // static final List<String> publicUrls = [...];
  // static final List<String> privateUrls = [...];

  static Future<bool> isInPublic() async {
    return sharedPreferences!.getBool('isInPublic') ?? false;
  }

  static Future<void> setInPublic(bool value) async {
    await Future.wait([
      getWallpaperUrl(value), // Fetch or prepare the updated wallpaper URL
      sharedPreferences!
          .setBool('isInPublic', value), // Save the value in shared preferences
    ]);
  }

  static Future<String> getWallpaperUrl(bool isInPublic) async {
    final random = Random();
    final cachedImages = await CacheService.getCachedImagesList();
    final imagesList =
        isInPublic ? cachedImages['public'] : cachedImages['private'];

    if (imagesList?.isEmpty ?? true) {
      throw Exception('No images available in the cache.');
    }

    final imagePath = imagesList![random.nextInt(imagesList.length)];

    final localFile = File(imagePath);

    if (!localFile.existsSync()) {
      throw Exception('Cached image file does not exist.');
    }

    await sharedPreferences!.setString('selectedImagePath', localFile.path);

    return localFile.path;
  }
}
