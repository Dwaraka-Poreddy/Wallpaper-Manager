import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/constants.dart';
import '../global.dart';
import '../services/wallpaper_auto_refresh_service.dart';
import '../services/wallpaper_provider.dart';

class WallpaperDisplay extends StatefulWidget {
  final bool isInPublic;
  const WallpaperDisplay({super.key, required this.isInPublic});

  @override
  State<WallpaperDisplay> createState() => _WallpaperDisplayState();
}

class _WallpaperDisplayState extends State<WallpaperDisplay> {
  @override
  Widget build(BuildContext context) {
    getSelectedImage() async {
      if (sharedPreferences!
          .containsKey(SharedPreferenceKeys.selectedImagePath)) {
        return sharedPreferences!
            .getString(SharedPreferenceKeys.selectedImagePath)!;
      } else {
        return await WallpaperProvider.getWallpaperUrl(widget.isInPublic);
      }
    }

    return StreamBuilder<void>(
      stream: Provider.of<WallpaperAutoRefreshService>(context).updates,
      builder: (context, snapshot) {
        print("Updating wallpaper... IN WIDGET");
        return FutureBuilder<String>(
          future: getSelectedImage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Placeholder while loading
            } else if (snapshot.hasError) {
              return const Icon(Icons.error); // Display an error widget
            } else if (snapshot.hasData) {
              final imageUrlOrPath = snapshot.data!;
              if (imageUrlOrPath.startsWith('http')) {
                // Use CachedNetworkImage for network URLs
                return SizedBox(
                  height: 200,
                  child: CachedNetworkImage(
                    imageUrl: imageUrlOrPath,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                    fit: BoxFit.contain,
                  ),
                );
              } else {
                // Use a FileImage for local paths
                return Image.file(
                  File(imageUrlOrPath),
                  fit: BoxFit.cover,
                );
              }
            } else {
              return const Icon(Icons.error);
            }
          },
        );
      },
    );
  }
}
