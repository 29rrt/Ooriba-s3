import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'services/company_name_service.dart';
import 'services/location_service.dart';

class StandardSettingsPage extends StatefulWidget {
  @override
  _StandardSettingsPageState createState() => _StandardSettingsPageState();
}

class _StandardSettingsPageState extends State<StandardSettingsPage> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _locationPrefixController = TextEditingController();
  final TextEditingController _locationLatController = TextEditingController();
  final TextEditingController _locationLngController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _locations = [];
  late LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _loadCompanyName();
    _loadLocations();
  }

  Future<void> _loadCompanyName() async {
    DocumentSnapshot documentSnapshot = await _firestore.collection('Config').doc('company_name').get();

    if (documentSnapshot.exists) {
      _companyNameController.text = documentSnapshot['name'];
    }
  }

  Future<void> _loadLocations() async {
    QuerySnapshot querySnapshot = await _firestore.collection('Locations').get();
    setState(() {
      _locations = querySnapshot.docs.map((doc) {
        return {
          'name': doc.id,
          'prefix': doc['prefix'],
          'coordinates': doc['coordinates'],
        };
      }).toList();
    });
  }

  Future<void> _saveCompanyName() async {
    await _firestore.collection('Config').doc('company_name').set({
      'name': _companyNameController.text,
    });

    final companyNameService = Provider.of<CompanyNameService>(context, listen: false);
    companyNameService.setCompanyName(_companyNameController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company name updated')),
    );
  }

  Future<void> _addLocation() async {
    String locationName = _locationNameController.text;
    String prefix = _locationPrefixController.text;
    double latitude = double.parse(_locationLatController.text);
    double longitude = double.parse(_locationLngController.text);

    await _firestore.collection('Locations').doc(locationName).set({
      'prefix': prefix,
      'coordinates': GeoPoint(latitude, longitude),
    });

    setState(() {
      _locations.add({
        'name': locationName,
        'prefix': prefix,
        'coordinates': GeoPoint(latitude, longitude),
      });
      _locationNameController.clear();
      _locationPrefixController.clear();
      _locationLatController.clear();
      _locationLngController.clear();
    });
  }

  Future<void> _deleteLocation(String name) async {
    await _firestore.collection('Locations').doc(name).delete();

    setState(() {
      _locations.removeWhere((location) => location['name'] == name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Standard Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _companyNameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveCompanyName();
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _locationNameController,
              decoration: const InputDecoration(labelText: 'Location Name'),
            ),
            TextField(
              controller: _locationPrefixController,
              decoration: const InputDecoration(labelText: 'Location Prefix'),
            ),
            TextField(
              controller: _locationLatController,
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: _locationLngController,
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _addLocation();
              },
              child: const Text('Add Location'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final location = _locations[index];
                  return ListTile(
                    title: Text(location['name']),
                    subtitle: Text(
                      'Prefix: ${location['prefix']}\nCoordinates: ${location['coordinates'].latitude}, ${location['coordinates'].longitude}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _deleteLocation(location['name']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
