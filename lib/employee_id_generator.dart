// employee_id_generator.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeIdGenerator {
  static const String _prefix = 'OOB';
  static const int _idLength = 3;

  Future<String> generateEmployeeId() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Regemp')
        .orderBy('employeeId', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return '$_prefix${_formatId(1)}';
    } else {
      final lastId = querySnapshot.docs.first.get('employeeId') as String;
      final numericPart = int.tryParse(lastId.replaceFirst(_prefix, '')) ?? 0;
      return '$_prefix${_formatId(numericPart + 1)}';
    }
  }

  String _formatId(int id) {
    return id.toString().padLeft(_idLength, '0');
  }
}