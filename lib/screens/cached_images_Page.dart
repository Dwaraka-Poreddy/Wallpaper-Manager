import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/biometric_auth_service.dart';
import '../services/cache_service.dart';
import '../services/wallpaper_service.dart';
import '../widgets/dialogs.dart';

class CachedImagesPage extends StatefulWidget {
  const CachedImagesPage({super.key});

  @override
  _CachedImagesPageState createState() => _CachedImagesPageState();
}

class _CachedImagesPageState extends State<CachedImagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<String>> cachedImagesList = {'public': [], 'private': []};
  bool _isLoading = false;
  bool _isAuthenticated = false;
  final BiometricAuthService _authService = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchAndSetCachedImagesList();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() async {
    if (_tabController.index == 1 && !_isAuthenticated) {
      await _authenticateUser();
      if (!_isAuthenticated) {
        _tabController.animateTo(0);
      }
    }
  }

  Future<void> _fetchAndSetCachedImagesList() async {
    cachedImagesList = await CacheService.getCachedImagesList();
    setState(() {});
  }

  Future<void> _addImage() async {
    setState(() {
      _isLoading = true;
    });
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
        if (mounted) {
          final isPrivate = await Dialogs.showConfirmationDialog(
            context,
            "Image Privacy",
            "Is this image private?",
            false,
          );
          await File(imagePath).copy(newImagePath);
          await CacheService.addImageToCacheList(newImagePath, !isPrivate);
          await _fetchAndSetCachedImagesList();
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addImageUrl() async {
    final urlController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Enter Image URL'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(hintText: 'Image URL'),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  Navigator.of(context).pop(urlController.text);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && result.isNotEmpty) {
      final url = result;
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final imageBytes = response.bodyBytes;
          final imageHash = md5.convert(imageBytes).toString();
          final directory = await getApplicationDocumentsDirectory();
          final newImagePath = '${directory.path}/$imageHash.jpg';

          if (await File(newImagePath).exists()) {
            if (mounted) {
              await Dialogs.showImageExistsDialog(context, newImagePath);
              setState(() {
                _isLoading = false;
              });
            }
          } else {
            if (mounted) {
              final isPrivate = await Dialogs.showConfirmationDialog(
                context,
                "Image Privacy",
                "Is this image private?",
                false,
              );
              final file = File(newImagePath);
              await file.writeAsBytes(imageBytes);
              await CacheService.addImageToCacheList(newImagePath, !isPrivate);
              await _fetchAndSetCachedImagesList();
              setState(() {
                _isLoading = false;
              });
            }
          }
        } else {
          if (mounted) {
            await Dialogs.showErrorDialog(context, 'Invalid URL',
                'The URL provided is not valid or the image could not be fetched.');
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          await Dialogs.showErrorDialog(
              context, 'Error', 'An error occurred while fetching the image.');
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _togglePrivacy(String imagePath, bool isPublic) async {
    final confirm = await Dialogs.showConfirmationDialog(
      context,
      'Change Privacy',
      'Are you sure you want to make this image ${isPublic ? 'public' : 'private'}?',
      false,
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
      false,
    );
    if (confirm) {
      await CacheService.removeImageFromCacheList(imagePath);
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _fetchAndSetCachedImagesList();
    }
  }

  Future<void> _setAsWallPaper(String imagePath, bool isPublic) async {
    setState(() {
      _isLoading = true;
    });
    final confirm = await Dialogs.showConfirmationDialog(
      context,
      'Set as Wallpaper',
      'Are you sure to set this image as wallpaper?',
      false,
    );
    if (confirm) {
      await WallpaperService.setWallpaper(
        isInPublic: isPublic,
        filePath: imagePath,
      );
      setState(() {
        _isLoading = false;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _authenticateUser() async {
    final isAuthenticated = await _authService.authenticateUser();
    setState(() {
      _isAuthenticated = isAuthenticated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Images'),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/add_image_link.png',
              fit: BoxFit.contain,
              height: 25,
            ),
            onPressed: _addImageUrl,
          ),
          IconButton(
            icon: Image.asset(
              'assets/images/add_image.png',
              fit: BoxFit.contain,
              height: 25,
            ),
            onPressed: _addImage,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Public'),
            Tab(text: 'Private'),
          ],
          onTap: (index) async {
            if (index == 1 && !_isAuthenticated) {
              await _authenticateUser();
              if (!_isAuthenticated) {
                _tabController.animateTo(0);
              }
            }
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImageList(cachedImagesList['public'] ?? []),
          _isAuthenticated
              ? _buildImageList(cachedImagesList['private'] ?? [])
              : Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Please authenticate to view private images.'),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: 200,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _authenticateUser,
                        icon: const Icon(Icons.fingerprint, size: 30),
                        label: const Text('Authenticate',
                            style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                )),
        ],
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
                      IconButton(
                        color: Colors.red,
                        icon: Image.asset(
                          isPublic
                              ? 'assets/images/private.png'
                              : 'assets/images/public.png',
                          fit: BoxFit.contain,
                          height: 25,
                        ),
                        onPressed: () => _togglePrivacy(imagePath, !isPublic),
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/images/set_wallpaper.png',
                          fit: BoxFit.contain,
                          height: 25,
                        ),
                        onPressed: () => _setAsWallPaper(imagePath, isPublic),
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/images/delete.png',
                          fit: BoxFit.contain,
                          height: 25,
                        ),
                        onPressed: () => _removeImage(imagePath),
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
