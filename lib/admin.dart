import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'admin_employee_details.dart';
import 'registered_employees_page[1].dart';
import 'services/auth_service.dart';
import 'attendance.dart'; // Assuming this file contains DatePickerButton widget
import 'rejected_employees_page.dart';
import 'services/registered_service.dart';
import 'services/company_name_service.dart'; // Import the company name service
import 'upcoming_events_page.dart'; // Import the Upcoming Events page

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final RegisteredService _registeredService = RegisteredService();

  @override
  Widget build(BuildContext context) {
    final companyNameService = Provider.of<CompanyNameService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signout(context: context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Admin Dashboard Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Registered Employees'),
              onTap: () {
                Navigator.pop(context);
                _showRegisteredEmployees(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.time_to_leave),
              title: const Text('Leave'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Leave Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Attendance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DatePickerButton()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StandardSettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Upcoming Events'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UpcomingEventsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signout(context: context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              color: Colors.lightBlueAccent.withOpacity(0.1),
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Hello Admin !!\nWelcome to ${companyNameService.companyName}',
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: _buildDashboardBlock(
                      context,
                      'Registered Employees',
                      Icons.person,
                      Colors.blue,
                      _showRegisteredEmployees,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: _buildDashboardBlock(
                      context,
                      'Rejected Applications',
                      Icons.person_off,
                      Colors.red,
                      _showRejectedApplications,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: _buildDashboardBlock(
                      context,
                      'Employee Details',
                      Icons.list,
                      Colors.green,
                      _showEmployeeDetails,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardBlock(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Function(BuildContext) onTap,
  ) {
    return InkWell(
      onTap: () => onTap(context),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              size: 48.0,
              color: Colors.white,
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegisteredEmployees(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisteredEmployeesPage()),
    );
  }

  void _showRejectedApplications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RejectedEmployeesPage()),
    );
  }

  void _showEmployeeDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EmployeeDetailsPage(employeeData: {})),
    );
  }
}

class StandardSettingsPage extends StatefulWidget {
  @override
  _StandardSettingsPageState createState() => _StandardSettingsPageState();
}

class _StandardSettingsPageState extends State<StandardSettingsPage> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _locations = [];
  Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _loadCompanyName();
    _loadLocations();
  }

  Future<void> _loadCompanyName() async {
    DocumentSnapshot documentSnapshot = await _firestore
        .collection('Config')
        .doc('company_name')
        .get();

    if (documentSnapshot.exists) {
      _companyNameController.text = documentSnapshot['name'];
    }
  }

  Future<void> _loadLocations() async {
    QuerySnapshot querySnapshot = await _firestore.collection('Locations').get();
    setState(() {
      _locations = querySnapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'coordinates': doc['coordinates'],
          'employee_id': doc['employee_id']
        };
      }).toList();
    });
  }

  Future<bool> _checkDuplicateEmployeeId(String employeeId) async {
    QuerySnapshot querySnapshot = await _firestore.collection('Locations').where('employee_id', isEqualTo: employeeId).get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<String> _generateEmployeeId(String locationName) async {
    String baseId = 'OOR';
    String initials = locationName.replaceAll(RegExp(r'\s+'), '').substring(0, 3).toUpperCase();
    String employeeId = '$baseId$initials';

    int counter = 1;
    while (await _checkDuplicateEmployeeId(employeeId)) {
      employeeId = '$baseId${initials.substring(0, 3)}${counter.toString()}';
      counter++;
    }

    return employeeId;
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
    LocationData currentLocation = await _locationService.getLocation();
    String locationName = _locationController.text;
    String employeeId = await _generateEmployeeId(locationName);

    await _firestore.collection('Locations').add({
      'name': locationName,
      'coordinates': GeoPoint(currentLocation.latitude!, currentLocation.longitude!),
      'employee_id': employeeId,
    });

    setState(() {
      _locations.add({
        'name': locationName,
        'coordinates': GeoPoint(currentLocation.latitude!, currentLocation.longitude!),
        'employee_id': employeeId
      });
      _locationController.clear();
    });
  }

  Future<void> _deleteLocation(String name) async {
    QuerySnapshot querySnapshot = await _firestore.collection('Locations').where('name', isEqualTo: name).get();
    for (DocumentSnapshot doc in querySnapshot.docs) {
      await _firestore.collection('Locations').doc(doc.id).delete();
    }

    setState(() {
      _locations.removeWhere((location) => location['name'] == name);
    });
  }

  Future<void> _editEmployeeId(String name, String newEmployeeId) async {
    bool isDuplicate = await _checkDuplicateEmployeeId(newEmployeeId);
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee ID already exists')),
      );
      return;
    }

    QuerySnapshot querySnapshot = await _firestore.collection('Locations').where('name', isEqualTo: name).get();
    for (DocumentSnapshot doc in querySnapshot.docs) {
      await _firestore.collection('Locations').doc(doc.id).update({'employee_id': newEmployeeId});
    }

    setState(() {
      int index = _locations.indexWhere((location) => location['name'] == name);
      if (index != -1) {
        _locations[index]['employee_id'] = newEmployeeId;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee ID updated')),
    );
  }

  void _showEditEmployeeIdDialog(String name) {
    final TextEditingController _employeeIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Employee ID'),
          content: TextField(
            controller: _employeeIdController,
            decoration: const InputDecoration(labelText: 'New Employee ID'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _editEmployeeId(name, _employeeIdController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Add Location'),
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
                      'Coordinates: ${location['coordinates'].latitude}, ${location['coordinates'].longitude}\nEmployee ID: ${location['employee_id']}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditEmployeeIdDialog(location['name']);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _deleteLocation(location['name']);
                          },
                        ),
                      ],
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
