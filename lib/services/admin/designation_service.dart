// import 'package:cloud_firestore/cloud_firestore.dart';

// class DesignationService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<List<String>> getDesignations() async {
//     QuerySnapshot querySnapshot = await _firestore.collection('Designations').get();
//     return querySnapshot.docs.map((doc) => doc['name'] as String).toList();
//   }

//   Future<void> addDesignation(String designation) async {
//     await _firestore.collection('Designations').add({'name': designation});
//   }

//   Future<void> deleteDesignation(String name) async {
//     QuerySnapshot querySnapshot = await _firestore.collection('Designations').where('name', isEqualTo: name).get();
//     for (var doc in querySnapshot.docs) {
//       await doc.reference.delete();
//     }
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

class DesignationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getDesignations() async {
    QuerySnapshot querySnapshot = await _firestore.collection('Designations').get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> addDesignation(String name) async {
    await _firestore.collection('Designations').doc(name).set({});
  }

  Future<void> deleteDesignation(String name) async {
    bool isInUse = await _isElementInUse(name, 'designation');

    if (isInUse) {
      throw Exception('Designation is already in use');
    } else {
      await _firestore.collection('Designations').doc(name).delete();
    }
  }

  Future<bool> _isElementInUse(String name, String field) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('Users')
        .where(field, isEqualTo: name)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}