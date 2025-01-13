import 'package:intl/intl.dart';

class WallpaperProvider {
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
    if (isInPublic) {
      return "https://images.unsplash.com/photo-1593642634367-d91a135587b5"; // URL for public
    } else {
      return "https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0"; // URL for private
    }
  }
}
