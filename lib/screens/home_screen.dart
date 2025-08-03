import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/constants.dart';
import '../global.dart';
import '../services/biometric_auth_service.dart';
import '../services/logger_service.dart';
import '../services/wallpaper_auto_refresh_service.dart';
import '../services/wallpaper_provider.dart';
import '../services/wallpaper_service.dart';
import '../widgets/dialogs.dart';
import '../widgets/wallpaper_widget.dart';
import 'cached_images_Page.dart';
import 'logs_page.dart';

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
  Timer? _countdownTimer;
  final ValueNotifier<Duration> _timeUntilNextUpdate =
      ValueNotifier(Duration.zero);
  DateTime? _lastUpdateTime;

  final TextEditingController _intervalController = TextEditingController();
  final BiometricAuthService _authService = BiometricAuthService();
  late LoggerService _logger;

  @override
  void initState() {
    super.initState();
    _initializeLogger();
    _initializePublicMode();
    _loadPreferences();
    _startCountdownTimer();
  }

  Future<void> _initializeLogger() async {
    _logger = await LoggerService.getInstance();
    await _logger.info("Home screen initialized", source: 'UI');
  }

  void _startCountdownTimer() {
    _updateLastUpdateTime();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_autoRefresh && _refreshInterval > 0) {
        _updateTimeUntilNextUpdate();
      }
    });
  }

  void _updateLastUpdateTime() {
    // Get the last update time from SharedPreferences or use current time as fallback
    final lastUpdateMillis = sharedPreferences?.getInt('last_wallpaper_update');
    if (lastUpdateMillis != null) {
      _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
    } else {
      _lastUpdateTime = DateTime.now();
      // Save current time as last update time
      sharedPreferences?.setInt(
          'last_wallpaper_update', DateTime.now().millisecondsSinceEpoch);
    }
  }

  void _updateTimeUntilNextUpdate() {
    if (_lastUpdateTime != null && _autoRefresh && _refreshInterval > 0) {
      final nextUpdateTime =
          _lastUpdateTime!.add(Duration(minutes: _refreshInterval.toInt()));
      final now = DateTime.now();

      if (nextUpdateTime.isAfter(now)) {
        _timeUntilNextUpdate.value = nextUpdateTime.difference(now);
      } else {
        _timeUntilNextUpdate.value = Duration.zero;
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) {
      return "Updating soon...";
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
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

    // Update the auto-refresh service
    final service =
        Provider.of<WallpaperAutoRefreshService>(context, listen: false);
    await service.updateAutoRefreshSettings(value, _refreshInterval);

    // Restart the countdown timer
    _startCountdownTimer();
  }

  Future<void> _updateRefreshInterval(String value) async {
    setState(() {
      _refreshInterval = double.tryParse(value) ?? 5.0;
      _intervalController.text = _refreshInterval.toString();
      if (!_intervalController.text.contains('.')) {
        _intervalController.text += '.0';
      }
    });

    // Update the auto-refresh service
    final service =
        Provider.of<WallpaperAutoRefreshService>(context, listen: false);
    await service.updateAutoRefreshSettings(_autoRefresh, _refreshInterval);

    // Restart the countdown timer with new interval
    _startCountdownTimer();
  }

  Future<void> setWallpaper() async {
    await _logger.info("User requested to set wallpaper", source: 'UI');
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
      await _logger.info(
          "Setting wallpaper manually - Public mode: $isInPublic",
          source: 'UI');
      bool success =
          await WallpaperService.setWallpaper(isInPublic: isInPublic);
      await _logger.info("Manual wallpaper set result: $success", source: 'UI');

      if (success) {
        // Update last update time for manual wallpaper set
        _lastUpdateTime = DateTime.now();
        await sharedPreferences?.setInt(
            'last_wallpaper_update', _lastUpdateTime!.millisecondsSinceEpoch);
        _startCountdownTimer(); // Restart countdown from now
      }

      setState(() {
        isLoading = false;
      });
    } else {
      await _logger.debug("User cancelled wallpaper setting", source: 'UI');
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

  Future<void> manualRefreshWallpaper() async {
    setState(() {
      isLoading = true;
    });
    final service =
        Provider.of<WallpaperAutoRefreshService>(context, listen: false);
    await service.refreshWallpaperNow();

    // Update last update time for manual refresh
    _lastUpdateTime = DateTime.now();
    await sharedPreferences?.setInt(
        'last_wallpaper_update', _lastUpdateTime!.millisecondsSinceEpoch);
    _startCountdownTimer(); // Restart countdown from now

    setState(() {
      isLoading = false;
    });
  }

  void _showDebugLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LogsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Wallpaper Manager'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugLogs(),
          ),
        ],
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
                                label: const Text("Fetch Another"),
                              ),
                              TextButton.icon(
                                onPressed: manualRefreshWallpaper,
                                icon: const Icon(Icons.autorenew),
                                label: const Text("Auto Refresh"),
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
                  if (_autoRefresh)
                    Consumer<WallpaperAutoRefreshService>(
                      builder: (context, service, child) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border:
                                Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                service.isLoading
                                    ? Icons.autorenew
                                    : Icons.schedule,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ValueListenableBuilder<Duration>(
                                  valueListenable: _timeUntilNextUpdate,
                                  builder:
                                      (context, timeUntilNextUpdate, child) {
                                    return Text(
                                      service.isLoading
                                          ? "Background service is updating wallpaper..."
                                          : _autoRefresh
                                              ? "Next update in: ${_formatDuration(timeUntilNextUpdate)}"
                                              : "Auto-refresh disabled",
                                      style: TextStyle(
                                        color: service.isLoading
                                            ? Colors.orange.shade700
                                            : _autoRefresh
                                                ? Colors.blue.shade700
                                                : Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: service.isLoading
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timeUntilNextUpdate.dispose();
    _intervalController.dispose();
    super.dispose();
  }
}
