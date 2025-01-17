import 'package:flutter/material.dart';

class Dialogs {
  static Future<void> showImageExistsDialog(
      BuildContext context, String imagePath) async {
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

  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    bool? barrierDismissible,
  ) async {
    return await showDialog<bool>(
          barrierDismissible: barrierDismissible ?? true,
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
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

  static Future<void> showErrorDialog(
      BuildContext context, String title, String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
