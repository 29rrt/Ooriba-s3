import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getDepartments() async {
    QuerySnapshot querySnapshot = await _firestore.collection('Departments').get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> addDepartment(String name) async {
    await _firestore.collection('Departments').doc(name).set({});
  }

  Future<void> deleteDepartment(String name) async {
    bool isInUse = await _isElementInUse(name, 'department');

    if (isInUse) {
      throw Exception('Department is already in use');
    } else {
      await _firestore.collection('Departments').doc(name).delete();
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