import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager/services/wallpaper_provider.dart';

class ImageListScreen extends StatefulWidget {
  const ImageListScreen({super.key});

  @override
  _ImageListScreenState createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  File? _publicLocalImage;
  File? _privateLocalImage;

  Future<void> pickLocalImage(bool isPublic) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final localFile = File('${directory.path}/images/${pickedFile.name}');

      if (!localFile.parent.existsSync()) {
        localFile.parent.createSync(recursive: true);
      }
      if (!localFile.existsSync()) {
        await localFile.writeAsBytes(await File(pickedFile.path).readAsBytes());
      }
      setState(() {
        if (isPublic) {
          _publicLocalImage = File(pickedFile.path);
        } else {
          _privateLocalImage = File(pickedFile.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Lists'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Public Images',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: WallpaperProvider.publicUrls.length + 1,
                itemBuilder: (context, index) {
                  if (index == WallpaperProvider.publicUrls.length) {
                    return IconButton(
                      icon: const Icon(Icons.add_a_photo),
                      onPressed: () => pickLocalImage(true),
                    );
                  }
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.all(8.0),
                    child: CachedNetworkImage(
                      imageUrl: WallpaperProvider.publicUrls[index],
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  );
                },
              ),
            ),
            if (_publicLocalImage != null)
              Container(
                width: 150,
                margin: const EdgeInsets.all(8.0),
                child: Image.file(_publicLocalImage!),
              ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Private Images',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: WallpaperProvider.privateUrls.length + 1,
                itemBuilder: (context, index) {
                  if (index == WallpaperProvider.privateUrls.length) {
                    return IconButton(
                      icon: const Icon(Icons.add_a_photo),
                      onPressed: () => pickLocalImage(false),
                    );
                  }
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.all(8.0),
                    child: CachedNetworkImage(
                      imageUrl: WallpaperProvider.privateUrls[index],
                      placeholder: (context, url) => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  );
                },
              ),
            ),
            if (_privateLocalImage != null)
              Container(
                width: 150,
                margin: const EdgeInsets.all(8.0),
                child: Image.file(_privateLocalImage!),
              ),
          ],
        ),
      ),
    );
  }
}
