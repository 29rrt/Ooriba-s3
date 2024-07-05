import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyNameService with ChangeNotifier {
  String _companyName = 'OORIBA-S3';

  CompanyNameService() {
    _loadCompanyName();
  }

  String get companyName => _companyName;

  Future<void> _loadCompanyName() async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('Config')
        .doc('company_name')
        .get();

    if (documentSnapshot.exists) {
      _companyName = documentSnapshot['name'];
      notifyListeners();
    }
  }

  void setCompanyName(String name) {
    _companyName = name;
    notifyListeners();
  }
}
