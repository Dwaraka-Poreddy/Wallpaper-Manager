import 'package:flutter/material.dart';

import '../common/constants.dart';
import '../global.dart';
import '../services/biometric_auth_service.dart';
import '../services/wallpaper_provider.dart';
import '../services/wallpaper_service.dart';
import '../widgets/dialogs.dart';
import '../widgets/wallpaper_widget.dart';
import 'cached_images_Page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  bool isInPublic = false;
  bool isSwitchDisabled = false;
  bool _autoRefresh = true;
  double _refreshInterval = 5.0;
  bool _isEditing = false;

  final TextEditingController _intervalController = TextEditingController();
  final BiometricAuthService _authService = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _initializePublicMode();
    _loadPreferences();
  }

  Future<void> _initializePublicMode() async {
    bool publicMode = await WallpaperProvider.isInPublic();
    setState(() {
      isInPublic = publicMode;
    });
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _autoRefresh = sharedPreferences!
              .getBool(SharedPreferenceKeys.shouldAutoRefreshWallpaper) ??
          true;
      _refreshInterval =
          sharedPreferences!.getDouble(SharedPreferenceKeys.refreshInterval) ??
              5.0;
      _intervalController.text = _refreshInterval.toString();
    });
  }

  Future<void> _toggleAutoRefresh(bool value) async {
    setState(() {
      _autoRefresh = value;
    });
    await sharedPreferences!.setBool(
      SharedPreferenceKeys.shouldAutoRefreshWallpaper,
      value,
    );
  }

  Future<void> _updateRefreshInterval(String value) async {
    setState(() {
      _refreshInterval = double.tryParse(value) ?? 5.0;
      _intervalController.text = _refreshInterval.toString();
      if (!_intervalController.text.contains('.')) {
        _intervalController.text += '.0';
      }
    });
    await sharedPreferences!.setDouble(
      SharedPreferenceKeys.refreshInterval,
      _refreshInterval,
    );
  }

  Future<void> setWallpaper() async {
    final confirm = await Dialogs.showConfirmationDialog(
      context,
      'Set as Wallpaper',
      'Are you sure to set this image as wallpaper?',
      false,
    );
    if (confirm) {
      setState(() {
        isLoading = true;
      });
      await WallpaperService.setWallpaper(isInPublic: isInPublic);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAnotherWallpaper() async {
    setState(() {
      isLoading = true;
    });
    await WallpaperProvider.getWallpaperUrl(isInPublic);
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
                  SwitchListTile(
                    title: Row(
                      children: [
                        Image.asset(
                          'assets/images/refresh.png',
                          fit: BoxFit.contain,
                          height: 25,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text('Auto Refresh Wallpaper'),
                      ],
                    ),
                    value: _autoRefresh,
                    onChanged: _toggleAutoRefresh,
                  ),
                  if (_autoRefresh)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/hourglass.png',
                            fit: BoxFit.contain,
                            height: 25,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Interval (mins)',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          if (_isEditing)
                            SizedBox(
                              width: 50,
                              child: TextField(
                                controller: _intervalController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                                textAlign: TextAlign.center,
                                onSubmitted: _updateRefreshInterval,
                              ),
                            )
                          else
                            Text(
                              _intervalController.text,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          IconButton(
                            icon: Icon(_isEditing ? Icons.check : Icons.edit),
                            onPressed: () {
                              if (_isEditing) {
                                _updateRefreshInterval(
                                    _intervalController.text);
                              }
                              setState(() {
                                _isEditing = !_isEditing;
                              });
                            },
                          ),
                          if (_isEditing)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _intervalController.text =
                                      _refreshInterval.toString();
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  SwitchListTile(
                    title: Row(
                      children: [
                        Image.asset(
                          'assets/images/public.png',
                          fit: BoxFit.contain,
                          height: 25,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        const Text('Public Mode'),
                      ],
                    ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CachedImagesPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/gallery.png',
                                  fit: BoxFit.contain,
                                  height: 25,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "View Cached Images",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8.0)),
                            child: WallpaperDisplay(
                              isInPublic: isInPublic,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: fetchAnotherWallpaper,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Fetch Another Image"),
                              ),
                              IconButton(
                                icon: Image.asset(
                                  'assets/images/set_wallpaper.png',
                                  fit: BoxFit.contain,
                                  height: 25,
                                ),
                                onPressed: () => setWallpaper(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                ],
              ),
            ),
    );
  }
}
