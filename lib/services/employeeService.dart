import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class EmployeeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addEmployee(
    String firstName,
    String middleName,
    String lastName,
    String email,
    String password,
    String panNo,
    String resAdd,
    String perAdd,
    String phoneNo,
    String dob,
    String aadharNo,
    File dpImage,
    File adhaarImage,
    File supportImage, {
    required BuildContext context,
  }) async {
    try {
      // Remove spaces from Aadhaar number
      aadharNo = aadharNo.replaceAll(' ', '');
      // Convert PAN number to uppercase
      panNo = panNo.toUpperCase();

      // Upload images to Firebase Storage
      String dpImageUrl =
          await _uploadImage(dpImage, 'profile_pictures/$email');
      String adhaarImageUrl =
          await _uploadImage(adhaarImage, 'aadhaar_cards/$email');
      String supportImageUrl =
          await _uploadImage(supportImage, 'supporting_documents/$email');

      // Prepare employee data
      final employeeData = {
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'panNo': panNo,
        'residentialAddress': resAdd,
        'permanentAddress': perAdd,
        'phoneNo': phoneNo,
        'dob': dob,
        'aadharNo': aadharNo,
        'timestamp': FieldValue.serverTimestamp(),
        'dpImageUrl': dpImageUrl,
        'adhaarImageUrl': adhaarImageUrl,
        'supportImageUrl': supportImageUrl,
      };

      // Save employee data to Firestore with email as document ID
      await _db
          .collection('Employee')
          .doc(email)
          .set(employeeData, SetOptions(merge: true));
    } catch (e) {
      print('Error saving employee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign up: $e')),
      );
      throw e;
    }
  }

  Future<String> _uploadImage(File image, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }
}