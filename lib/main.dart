import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:wallpaper_manager/image_list_screen.dart';
import 'package:wallpaper_manager/wallpaper_provider.dart';

import 'biometric_auth_service.dart';

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
  bool isSwitchDisabled = false;
  String _platformVersion = 'Unknown';
  String __heightWidth = "Unknown";
  final BiometricAuthService _authService = BiometricAuthService();

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
      home: Navigator(
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
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
                            SizedBox(
                              height: 200,
                              width: 200,
                              child: CachedNetworkImage(
                                imageUrl: WallpaperProvider.getWallpaperUrl(
                                    isInPublic),
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
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
                              title: const Text('Public Mode'),
                              value: isInPublic,
                              onChanged: isSwitchDisabled
                                  ? null
                                  : (bool value) async {
                                      setState(() {
                                        isSwitchDisabled = true;
                                      });
                                      if (!value) {
                                        bool isAuthenticated =
                                            await _authService
                                                .authenticateUser();
                                        if (!isAuthenticated) {
                                          setState(() {
                                            isSwitchDisabled = false;
                                          });
                                          return;
                                        }
                                      }
                                      setState(() {
                                        isInPublic = value;
                                        isSwitchDisabled = false;
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
                                child: const Text("Clear Wallpaper")),
                            const SizedBox(
                              height: 10,
                            ),
                            TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ImageListScreen()),
                                  );
                                },
                                child: const Text("View Image Lists")),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
