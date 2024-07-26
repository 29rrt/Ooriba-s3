import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getAllLocations() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Locations').get();

      List<String> locations = querySnapshot.docs.map((doc) => doc.id).toList();

      return locations;
    } catch (e) {
      print('Error fetching locations: $e');
      return [];
    }
  }
}
