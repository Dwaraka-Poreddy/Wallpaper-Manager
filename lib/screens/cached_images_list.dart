import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CachedImagesPage extends StatelessWidget {
  const CachedImagesPage({super.key});

  Future<List<File>> _fetchCachedImages() async {
    // Get the app's document directory
    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${directory.path}/images');

    if (!imagesDirectory.existsSync()) {
      print('Images directory does not exist.');
      return []; // Return an empty list if the directory doesn't exist
    }

    final files = imagesDirectory.listSync();

    print('Files in images directory: ${files.map((f) => f.path).toList()}');

    final imageFiles = files.whereType<File>().toList();

    return imageFiles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Images'),
      ),
      body: FutureBuilder<List<File>>(
        future: _fetchCachedImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Error fetching cached images'),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final images = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                children: images.map((imageFile) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200, // Set a fixed height for each image
                    ),
                  );
                }).toList(),
              ),
            );
          } else {
            return const Center(
              child: Text('No cached images found.'),
            );
          }
        },
      ),
    );
  }
}
