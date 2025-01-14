import 'package:flutter/material.dart';
import 'package:wallpaper_manager/screens/cached_images_Page.dart';

import '../services/biometric_auth_service.dart';
import '../services/wallpaper_provider.dart';
import '../services/wallpaper_service.dart';
import '../widgets/wallpaper_widget.dart';

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
    bool result = await WallpaperService.setWallpaper(isInPublic);
    print(result);
    setState(() {
      isLoading = false;
    });
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
                  const Text("Selected Image"),
                  WallpaperDisplay(
                    isInPublic: isInPublic,
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
                        await WallpaperService.clearWallpaper();
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
                          builder: (context) => const CachedImagesPage(),
                        ),
                      );
                    },
                    child: const Text("View Cached Images"),
                  ),
                ],
              ),
            ),
    );
  }
}
