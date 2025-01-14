import 'dart:io';

import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cached Images'),
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
