import 'dart:io';
import 'dart:math';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../global.dart';

class WallpaperProvider {
  static final List<String> publicUrls = [
    "https://plus.unsplash.com/premium_photo-1722859221349-26353eae4744",
    "https://images.unsplash.com/photo-1503256207526-0d5d80fa2f47",
    "https://images.unsplash.com/photo-1530281700549-e82e7bf110d6",
    "https://images.unsplash.com/photo-1505628346881-b72b27e84530",
    "https://images.unsplash.com/photo-1491604612772-6853927639ef",
    "https://images.unsplash.com/photo-1510771463146-e89e6e86560e",
    "https://images.unsplash.com/photo-1560743641-3914f2c45636",
  ];

  static final List<String> privateUrls = [
    "https://plus.unsplash.com/premium_photo-1673967831980-1d377baaded2",
    "https://images.unsplash.com/photo-1516280030429-27679b3dc9cf",
    "https://images.unsplash.com/photo-1536590158209-e9d615d525e4",
    "https://plus.unsplash.com/premium_photo-1666612335748-d23dcba788e1",
    "https://images.unsplash.com/photo-1536589961747-e239b2abbec2",
    "https://images.unsplash.com/photo-1552933529-e359b2477252",
    "https://images.unsplash.com/photo-1548546738-8509cb246ed3",
  ];

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
    final url = isInPublic
        ? publicUrls[random.nextInt(publicUrls.length)]
        : privateUrls[random.nextInt(privateUrls.length)];

    // Check if file exists locally
    final directory = await getApplicationDocumentsDirectory();
    final fileName = Uri.parse(url).pathSegments.last;
    final localFile = File('${directory.path}/images/$fileName');

    if (!localFile.parent.existsSync()) {
      localFile.parent.createSync(recursive: true);
    }

    if (!localFile.existsSync()) {
      final cache = DefaultCacheManager();
      File file = await cache.getSingleFile(url);
      await localFile.writeAsBytes(await file.readAsBytes());
    }
    await sharedPreferences!.setString('selectedImagePath', localFile.path);

    return localFile.path;
  }
}
