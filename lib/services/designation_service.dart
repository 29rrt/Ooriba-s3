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
    await _firestore.collection('Designations').doc(name).delete();
  }
}
