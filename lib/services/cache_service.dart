import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CacheService {
  static Future<bool> imageExistsInCache(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheFile = File('${directory.path}/cached_images.json');

    if (!cacheFile.existsSync()) {
      return false;
    }

    final content = await cacheFile.readAsString();
    final cacheData = jsonDecode(content);

    return cacheData['public'].contains(imagePath) ||
        cacheData['private'].contains(imagePath);
  }

  static Future<void> addImageToCacheList(
    String imagePath,
    bool isInPublic,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheFile = File('${directory.path}/cached_images.json');

    Map<String, dynamic> cacheData = {'public': [], 'private': []};

    if (cacheFile.existsSync()) {
      final content = await cacheFile.readAsString();
      cacheData = jsonDecode(content);
    }

    if (isInPublic) {
      cacheData['public'].add(imagePath);
    } else {
      cacheData['private'].add(imagePath);
    }

    await cacheFile.writeAsString(jsonEncode(cacheData));
  }

  static Future<void> updateImagePrivacy(
      String imagePath, bool isPublic) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheFile = File('${directory.path}/cached_images.json');

    if (!cacheFile.existsSync()) {
      return;
    }

    final content = await cacheFile.readAsString();
    final cacheData = jsonDecode(content);

    if (isPublic) {
      cacheData['private'].remove(imagePath);
      cacheData['public'].add(imagePath);
    } else {
      cacheData['public'].remove(imagePath);
      cacheData['private'].add(imagePath);
    }

    await cacheFile.writeAsString(jsonEncode(cacheData));
  }

  static Future<void> removeImageFromCacheList(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheFile = File('${directory.path}/cached_images.json');

    if (!cacheFile.existsSync()) {
      return;
    }

    final content = await cacheFile.readAsString();
    final cacheData = jsonDecode(content);

    cacheData['public'].remove(imagePath);
    cacheData['private'].remove(imagePath);

    await cacheFile.writeAsString(jsonEncode(cacheData));
  }

  static Future<Map<String, List<String>>> getCachedImagesList() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheFile = File('${directory.path}/cached_images.json');

    if (!cacheFile.existsSync()) {
      return {'public': [], 'private': []};
    }

    final content = await cacheFile.readAsString();
    final cacheData = jsonDecode(content);

    return {
      'public': List<String>.from(cacheData['public']),
      'private': List<String>.from(cacheData['private']),
    };
  }

  static Future<List<File>> fetchCachedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${directory.path}/images');

    if (!imagesDirectory.existsSync()) {
      print('Images directory does not exist.');
      return []; // Return an empty list if the directory doesn't exist
    }

    final files = imagesDirectory.listSync();
    print('Files in images directory: ${files.map((f) => f.path).toList()}');

    final imageFiles = files.whereType<File>().toList();
    return imageFiles;
  }
}
