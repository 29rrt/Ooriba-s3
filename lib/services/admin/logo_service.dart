import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LogoService with ChangeNotifier {
  File? logo;
   String? logoUrl;
  final ImagePicker _picker = ImagePicker();

  LogoService() {
    fetchLogoUrlFromFirebase();
  }


  Future<void> pickLogo() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        logo = File(pickedFile.path);
        await uploadLogoToFirebase();
        notifyListeners();
      } else {
        print("No image selected");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> uploadLogoToFirebase() async {
    if (logo != null) {
      try {
        String fileName = 'company_logo.png';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        await storageRef.putFile(logo!);
        String downloadURL = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('Config').doc('logo').set({
          'url': downloadURL,
        });
        logoUrl = downloadURL;
        notifyListeners();
      } catch (e) {
        print("Error uploading logo: $e");
      }
    } else {
      print("No logo to upload");
    }
  }

  Future<void> fetchLogoUrlFromFirebase() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Config').doc('logo').get();
      if (doc.exists) {
        logoUrl = doc['url'];
        notifyListeners();
      } else {
        print("Logo URL document does not exist");
      }
    } catch (e) {
      print("Error fetching logo URL: $e");
    }
  }
}
