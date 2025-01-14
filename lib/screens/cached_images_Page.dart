import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/cache_service.dart';
import '../widgets/dialogs.dart';

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
        if (mounted) {
          await Dialogs.showImageExistsDialog(context, newImagePath);
        }
      } else {
        await File(imagePath).copy(newImagePath);
        if (mounted) {
          final isPrivate = await Dialogs.showPrivacyDialog(context);
          await CacheService.addImageToCacheList(newImagePath, !isPrivate);
          await _fetchAndSetCachedImagesList();
        }
      }
    }
  }

  Future<void> _togglePrivacy(String imagePath, bool isPublic) async {
    final confirm = await Dialogs.showConfirmationDialog(
      context,
      'Change Privacy',
      'Are you sure you want to make this image ${isPublic ? 'public' : 'private'}?',
    );
    if (confirm) {
      await CacheService.updateImagePrivacy(imagePath, isPublic);
      await _fetchAndSetCachedImagesList();
    }
  }

  Future<void> _removeImage(String imagePath) async {
    final confirm = await Dialogs.showConfirmationDialog(
      context,
      'Remove Image',
      'Are you sure you want to remove this image?',
    );
    if (confirm) {
      await CacheService.removeImageFromCacheList(imagePath);
      await _fetchAndSetCachedImagesList();
    }
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
          final isPublic =
              cachedImagesList['public']?.contains(imagePath) ?? false;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8.0)),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _togglePrivacy(imagePath, !isPublic),
                        child: Text(isPublic ? 'Make Private' : 'Make Public'),
                      ),
                      ElevatedButton(
                        onPressed: () => _removeImage(imagePath),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
