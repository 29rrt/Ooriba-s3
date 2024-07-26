import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveTypeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getLeaveTypes() async {
    QuerySnapshot querySnapshot = await _firestore.collection('LeaveTypes').get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> addLeaveType(String name) async {
    await _firestore.collection('LeaveTypes').doc(name).set({});
  }

  Future<void> deleteLeaveType(String name) async {
    await _firestore.collection('LeaveTypes').doc(name).delete();
  }
}
