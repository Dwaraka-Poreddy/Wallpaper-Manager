import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/cache_service.dart';

class CachedImagesPage extends StatefulWidget {
  const CachedImagesPage({super.key});

  @override
  _CachedImagesPageState createState() => _CachedImagesPageState();
}

class _CachedImagesPageState extends State<CachedImagesPage> {
  Map<String, List<String>> cachedImagesList = {'public': [], 'private': []};

  @override
  void initState() {
    super.initState();
    _fetchAndSetCachedImagesList();
  }

  Future<void> _fetchAndSetCachedImagesList() async {
    cachedImagesList = await CacheService.getCachedImagesList();
    setState(() {});
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imagePath = pickedFile.path;
      final imageBytes = await pickedFile.readAsBytes();
      final imageHash = md5.convert(imageBytes).toString();
      final directory = await getApplicationDocumentsDirectory();
      final newImagePath = '${directory.path}/$imageHash.jpg';

      if (await File(newImagePath).exists()) {
        await _showImageExistsDialog(newImagePath);
      } else {
        await File(imagePath).copy(newImagePath);
        final isPrivate = await _showPrivacyDialog();
        await CacheService.addImageToCacheList(newImagePath, !isPrivate);
        await _fetchAndSetCachedImagesList();
      }
    }
  }

  Future<void> _showImageExistsDialog(String imagePath) async {
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Image Already Exists'),
          content: const Text(
            'This image already exists in the cache. You can change its privacy settings if needed',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showPrivacyDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Image Privacy'),
              content: const Text('Is this image private?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cached Images'),
          actions: [
            IconButton(
              icon: Image.asset(
                'assets/images/add_image.png',
                fit: BoxFit.contain,
                height: 25,
              ),
              onPressed: _addImage,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Public'),
              Tab(text: 'Private'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildImageList(cachedImagesList['public'] ?? []),
            _buildImageList(cachedImagesList['private'] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildImageList(List<String> imagePaths) {
    if (imagePaths.isEmpty) {
      return const Center(
        child: Text('No cached images found.'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: imagePaths.map((imagePath) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          );
        }).toList(),
      ),
    );
  }
}
