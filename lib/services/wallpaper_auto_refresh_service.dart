import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wallpaper_manager/services/wallpaper_provider.dart';
import 'package:wallpaper_manager/services/wallpaper_service.dart';
import 'package:workmanager/workmanager.dart';

import '../common/constants.dart';
import '../global.dart';
import 'logger_service.dart';

class WallpaperAutoRefreshService extends ChangeNotifier {
  Timer? _timer;
  bool isInPublic = false;
  bool isLoading = false;
  bool _autoRefresh = true;
  double _refreshInterval = 5.0;
  final StreamController<void> _updateController =
      StreamController<void>.broadcast();
  late LoggerService _logger;

  WallpaperAutoRefreshService() {
    _initializeService();
  }

  static const String taskName = 'wallpaperRefreshTask';

  Future<void> _initializeService() async {
    _logger = await LoggerService.getInstance();
    await _initializePublicMode();
    await _loadPreferences();
    await _setupBackgroundTask();
  }

  Future<void> _initializePublicMode() async {
    isInPublic = await WallpaperProvider.isInPublic();
  }

  Future<void> _loadPreferences() async {
    _autoRefresh = sharedPreferences!
            .getBool(SharedPreferenceKeys.shouldAutoRefreshWallpaper) ??
        true;
    _refreshInterval =
        sharedPreferences!.getDouble(SharedPreferenceKeys.refreshInterval) ??
            5.0;

    await _logger.info(
        "Auto-refresh service loaded - Enabled: $_autoRefresh, Interval: $_refreshInterval minutes",
        source: 'AUTO_REFRESH');

    if (_autoRefresh) {
      startForegroundTimer();
    }
  }

  /// Setup WorkManager background task
  Future<void> _setupBackgroundTask() async {
    try {
      // Cancel any existing tasks
      await Workmanager().cancelByUniqueName(taskName);

      if (_autoRefresh && _refreshInterval > 0) {
        // Register periodic background task
        await Workmanager().registerPeriodicTask(
          taskName,
          taskName,
          frequency: Duration(
              minutes: _refreshInterval
                  .toInt()
                  .clamp(15, 1440)), // Min 15 mins, max 24 hours
          initialDelay: Duration(minutes: 1), // Start after 1 minute
          constraints: Constraints(
            networkType: NetworkType.not_required,
            requiresBatteryNotLow: false, // Allow on low battery
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
          inputData: {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'interval': _refreshInterval,
            'task_id': taskName,
          },
        );
        await _logger.info(
            "Background task registered successfully with ${_refreshInterval.toInt()} minute interval",
            source: 'AUTO_REFRESH');
      } else {
        await _logger.warning(
            "Background task not registered - auto-refresh disabled or invalid interval",
            source: 'AUTO_REFRESH');
      }
    } catch (e) {
      await _logger.error("Error setting up background task: $e",
          source: 'AUTO_REFRESH');
    }
  }

  /// Start foreground timer for when app is active
  void startForegroundTimer() {
    _timer?.cancel();
    if (_autoRefresh && _refreshInterval > 0) {
      _timer = Timer.periodic(
        Duration(minutes: _refreshInterval.toInt()),
        (timer) async {
          await _logger.debug("Foreground timer triggered wallpaper update",
              source: 'AUTO_REFRESH');
          await _performWallpaperUpdate();
        },
      );
      _logger.info(
          "Foreground timer started with ${_refreshInterval.toInt()} minute interval",
          source: 'AUTO_REFRESH');
    }
  }

  /// Stop foreground timer
  void stopForegroundTimer() {
    _timer?.cancel();
    _timer = null;
    _logger.debug("Foreground timer stopped", source: 'AUTO_REFRESH');
  }

  /// Update auto-refresh settings
  Future<void> updateAutoRefreshSettings(bool enabled, double interval) async {
    _autoRefresh = enabled;
    _refreshInterval = interval;

    // Save to preferences
    await sharedPreferences!.setBool(
      SharedPreferenceKeys.shouldAutoRefreshWallpaper,
      enabled,
    );
    await sharedPreferences!.setDouble(
      SharedPreferenceKeys.refreshInterval,
      interval,
    );

    await _logger.info(
        "Auto-refresh settings updated - Enabled: $enabled, Interval: $interval minutes",
        source: 'AUTO_REFRESH');

    // Update foreground timer
    if (enabled) {
      startForegroundTimer();
    } else {
      stopForegroundTimer();
    }

    // Update background task
    await _setupBackgroundTask();

    notifyListeners();
  }

  /// Perform the actual wallpaper update
  Future<void> _performWallpaperUpdate() async {
    try {
      if (!_autoRefresh) {
        await _logger.warning("Auto-refresh disabled, skipping update",
            source: 'AUTO_REFRESH');
        return;
      }

      await _logger.info("Starting wallpaper update...",
          source: 'AUTO_REFRESH');
      isLoading = true;
      notifyListeners();

      // Get current mode
      isInPublic = await WallpaperProvider.isInPublic();
      await _logger.debug("Current mode: ${isInPublic ? 'Public' : 'Private'}",
          source: 'AUTO_REFRESH');

      // Set new wallpaper
      bool success =
          await WallpaperService.setWallpaper(isInPublic: isInPublic);
      if (success) {
        // Get new wallpaper URL/path for next update
        await WallpaperProvider.getWallpaperUrl(isInPublic);
        await _logger.info("Wallpaper updated successfully",
            source: 'AUTO_REFRESH');

        // Update last wallpaper update time
        await sharedPreferences!.setInt(
            'last_wallpaper_update', DateTime.now().millisecondsSinceEpoch);
      } else {
        await _logger.error("Failed to set wallpaper", source: 'AUTO_REFRESH');
      }

      _updateController.add(null); // Notify UI listeners
    } catch (e) {
      await _logger.error("Error during wallpaper update: $e",
          source: 'AUTO_REFRESH');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Execute background task (called by WorkManager)
  Future<void> executeTask() async {
    final logger = await LoggerService.getInstance();
    await logger.info("Background task executing...", source: 'BACKGROUND');
    await _performWallpaperUpdate();
  }

  /// Manual wallpaper refresh
  Future<void> refreshWallpaperNow() async {
    await _logger.info("Manual wallpaper refresh triggered",
        source: 'AUTO_REFRESH');
    await _performWallpaperUpdate();
  }

  /// Cancel all background tasks
  Future<void> cancelBackgroundTasks() async {
    try {
      await Workmanager().cancelByUniqueName(taskName);
      await _logger.info("Background tasks cancelled", source: 'AUTO_REFRESH');
    } catch (e) {
      await _logger.error("Error cancelling background tasks: $e",
          source: 'AUTO_REFRESH');
    }
  }

  Stream<void> get updates => _updateController.stream;

  bool get autoRefresh => _autoRefresh;
  double get refreshInterval => _refreshInterval;

  @override
  void dispose() {
    _timer?.cancel();
    _updateController.close();
    super.dispose();
  }
}
