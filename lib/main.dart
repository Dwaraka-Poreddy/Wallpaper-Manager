import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:wallpaper_manager/wallpaper_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = false;
  bool isInPublic = false;
  String _platformVersion = 'Unknown';
  String __heightWidth = "Unknown";

  @override
  void initState() {
    super.initState();
    initAppState();
    isInPublic = WallpaperProvider.isInPublic();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initAppState() async {
    String platformVersion;
    String heightWidth;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await WallpaperManager.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    try {
      int height = await WallpaperManager.getDesiredMinimumHeight();
      int width = await WallpaperManager.getDesiredMinimumWidth();
      heightWidth = "Width = $width Height = $height";
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
      heightWidth = "Failed to get Height and Width";
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      __heightWidth = heightWidth;
      _platformVersion = platformVersion;
    });
  }

  Future<void> setWallpaper() async {
    setState(() {
      isLoading = true;
    });
    try {
      // CachedNetworkImage will cache the image for you
      final cache = DefaultCacheManager();
      String url = WallpaperProvider.getWallpaperUrl(
          isInPublic); // Get URL based on isInPublic
      File? file = await cache.getSingleFile(url);

      int location = WallpaperManager
          .BOTH_SCREEN; // or location = WallpaperManager.LOCK_SCREEN;

      final bool result =
          await WallpaperManager.setWallpaperFromFile(file.path, location);
      print(result);
    } on PlatformException catch (e) {
      print("Failed to set wallpaper: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Wallpaper Manager'),
        ),
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: WallpaperProvider.getWallpaperUrl(isInPublic),
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                      Text('Running on: $_platformVersion\n'),
                      const SizedBox(
                        height: 10,
                      ),
                      Text('$__heightWidth\n'),
                      const SizedBox(
                        height: 10,
                      ),
                      SwitchListTile(
                        title: const Text('Is In Public'),
                        value: isInPublic,
                        onChanged: (bool value) {
                          setState(() {
                            isInPublic = value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextButton(
                          onPressed: () => {setWallpaper()},
                          child: const Text("Set Wallpaper")),
                      const SizedBox(
                        height: 10,
                      ),
                      TextButton(
                          onPressed: () async {
                            await WallpaperManager.clearWallpaper();
                          },
                          child: const Text("Clear Wallpaper"))
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
