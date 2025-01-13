import 'dart:math';

import '../global.dart';

class WallpaperProvider {
  static final List<String> publicUrls = [
    "https://images.unsplash.com/photo-1593642634367-d91a135587b5",
    "https://images.unsplash.com/photo-1519125323398-675f0ddb6308",
    "https://images.unsplash.com/photo-1521747116042-5a810fda9664"
  ];

  static final List<String> privateUrls = [
    "https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0",
    "https://images.unsplash.com/photo-1495567720989-cebdbdd97913",
    "https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0"
  ];

  static Future<bool> isInPublic() async {
    return sharedPreferences!.getBool('isInPublic') ?? false;
  }

  static Future<void> setInPublic(bool value) async {
    await sharedPreferences!.setBool('isInPublic', value);
  }

  static String getWallpaperUrl(bool isInPublic) {
    final random = Random();
    if (isInPublic) {
      return publicUrls[random.nextInt(publicUrls.length)];
    } else {
      return privateUrls[random.nextInt(privateUrls.length)];
    }
  }
}
