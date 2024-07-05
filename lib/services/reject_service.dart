import 'package:cloud_firestore/cloud_firestore.dart';

class RejectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> rejectEmployee(
      Map<String, dynamic> employeeData, String reason) async {
    try {
      // Add the reason to the employee data
      employeeData['reason'] = reason;

      // Save the employee data with the reason in the RejectedEmp collection
      await _firestore
          .collection('RejectedEmp')
          .doc(employeeData['email'])
          .set(employeeData);

      // Delete the employee from the Employee collection
      await _firestore
          .collection('Employee')
          .doc(employeeData['email'])
          .delete();
    } catch (e) {
      throw Exception('Failed to reject employee: $e');
    }
  }
}