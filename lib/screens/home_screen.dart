import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';

import '../services/biometric_auth_service.dart';
import '../services/wallpaper_provider.dart';
import 'image_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  bool isInPublic = false;
  bool isSwitchDisabled = false;

  final BiometricAuthService _authService = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _initializePublicMode();
  }

  Future<void> _initializePublicMode() async {
    bool publicMode = await WallpaperProvider.isInPublic();
    setState(() {
      isInPublic = publicMode;
    });
  }

  Future<void> setWallpaper() async {
    setState(() {
      isLoading = true;
    });
    try {
      final cache = DefaultCacheManager();
      String url = WallpaperProvider.getWallpaperUrl(isInPublic);
      File? file = await cache.getSingleFile(url);

      int location = WallpaperManager.BOTH_SCREEN;

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
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Wallpaper Manager'),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const Text("Current Wallpaper"),
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: CachedNetworkImage(
                      imageUrl: WallpaperProvider.getWallpaperUrl(isInPublic),
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
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
                                  await _authService.authenticateUser();
                              if (!isAuthenticated) {
                                setState(() {
                                  isSwitchDisabled = false;
                                });
                                return;
                              }
                            }
                            await WallpaperProvider.setInPublic(value);
                            setState(() {
                              isInPublic = value;
                              isSwitchDisabled = false;
                            });
                          },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () => {setWallpaper()},
                      child: const Text("Set this Wallpaper")),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        await WallpaperManager.clearWallpaper();
                      },
                      child: const Text("Clear this Wallpaper")),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImageListScreen(),
                        ),
                      );
                    },
                    child: const Text("View Image Lists"),
                  ),
                ],
              ),
            ),
    );
  }
}
