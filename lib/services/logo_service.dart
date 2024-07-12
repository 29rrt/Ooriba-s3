// logo_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LogoService with ChangeNotifier {
  File? _logo;

  File? get logo => _logo;

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _logo = File(pickedFile.path);
      notifyListeners();
    }
  }
}
