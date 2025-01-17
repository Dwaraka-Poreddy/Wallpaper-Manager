import 'dart:io';
import 'dart:math';

import '../common/constants.dart';
import '../global.dart';
import 'cache_service.dart';

class WallpaperProvider {
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

    String? lastImagePath = sharedPreferences!.getString(
      SharedPreferenceKeys.selectedImagePath,
    );
    String newImagePath;

    do {
      newImagePath = imagesList![random.nextInt(imagesList.length)];
    } while (newImagePath == lastImagePath && imagesList.length > 1);

    final localFile = File(newImagePath);

    if (!localFile.existsSync()) {
      throw Exception('Cached image file does not exist.');
    }

    await sharedPreferences!.setString(
      SharedPreferenceKeys.selectedImagePath,
      localFile.path,
    );

    return localFile.path;
  }
}
