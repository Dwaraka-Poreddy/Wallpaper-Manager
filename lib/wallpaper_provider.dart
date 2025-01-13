import 'dart:math';

import 'package:intl/intl.dart';

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

  static bool isInPublic() {
    DateTime now = DateTime.now();
    String dayOfWeek = DateFormat('EEEE').format(now);
    int hour = now.hour;

    return (dayOfWeek == 'Monday' ||
            dayOfWeek == 'Tuesday' ||
            dayOfWeek == 'Wednesday') &&
        (hour >= 10 && hour <= 19);
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
