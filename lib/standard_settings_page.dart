import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'services/company_name_service.dart';
import 'services/location_service.dart';
import 'services/department_service.dart';
import 'services/leave_type_service.dart';
import 'services/logo_service.dart';
import 'services/designation_service.dart'; // Import the designation service

class StandardSettingsPage extends StatefulWidget {
  @override
  _StandardSettingsPageState createState() => _StandardSettingsPageState();
}

class _StandardSettingsPageState extends State<StandardSettingsPage> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _locationCodeController = TextEditingController();
  final TextEditingController _locationLatController = TextEditingController();
  final TextEditingController _locationLngController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _leaveTypeController = TextEditingController();
  final TextEditingController _workingDaysController = TextEditingController();
  final TextEditingController _designationController = TextEditingController(); // Add designation controller

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _locations = [];
  List<String> _departments = [];
  List<String> _leaveTypes = [];
  List<String> _designations = []; // Add designation list
  late LocationService _locationService;
  late DepartmentService _departmentService;
  late LeaveTypeService _leaveTypeService;
  late DesignationService _designationService; // Add designation service

  String _selectedHoliday = 'Sunday';
  List<String> _daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  String? _editingLocationName;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _departmentService = DepartmentService();
    _leaveTypeService = LeaveTypeService();
    _designationService = DesignationService(); // Initialize designation service
    _loadCompanyName();
    _loadLocations();
    _loadDepartments();
    _loadLeaveTypes();
    _loadDesignations(); // Load designations
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
          'code': doc['code'],
          'coordinates': doc['coordinates'],
          'working_days': doc['working_days'],
          'holiday': doc['holiday'],
        };
      }).toList();
    });
  }

  Future<void> _loadDepartments() async {
    List<String> departments = await _departmentService.getDepartments();
    setState(() {
      _departments = departments;
    });
  }

  Future<void> _loadLeaveTypes() async {
    List<String> leaveTypes = await _leaveTypeService.getLeaveTypes();
    setState(() {
      _leaveTypes = leaveTypes;
    });
  }

  Future<void> _loadDesignations() async {
    List<String> designations = await _designationService.getDesignations();
    setState(() {
      _designations = designations;
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
    String code = _locationCodeController.text;
    double latitude = double.parse(_locationLatController.text);
    double longitude = double.parse(_locationLngController.text);
    int workingDays = int.parse(_workingDaysController.text);
    String holiday = _selectedHoliday;

    await _firestore.collection('Locations').doc(locationName).set({
      'code': code,
      'coordinates': GeoPoint(latitude, longitude),
      'working_days': workingDays,
      'holiday': holiday,
    });

    setState(() {
      _locations.add({
        'name': locationName,
        'code': code,
        'coordinates': GeoPoint(latitude, longitude),
        'working_days': workingDays,
        'holiday': holiday,
      });
      _locationNameController.clear();
      _locationCodeController.clear();
      _locationLatController.clear();
      _locationLngController.clear();
      _workingDaysController.clear();
      _selectedHoliday = 'Sunday';
    });
  }

  Future<void> _editLocation(String locationName) async {
    if (_editingLocationName == null) return;

    String code = _locationCodeController.text;
    double latitude = double.parse(_locationLatController.text);
    double longitude = double.parse(_locationLngController.text);
    int workingDays = int.parse(_workingDaysController.text);
    String holiday = _selectedHoliday;

    await _firestore.collection('Locations').doc(_editingLocationName).update({
      'code': code,
      'coordinates': GeoPoint(latitude, longitude),
      'working_days': workingDays,
      'holiday': holiday,
    });

    setState(() {
      int index = _locations.indexWhere((location) => location['name'] == _editingLocationName);
      _locations[index] = {
        'name': locationName,
        'code': code,
        'coordinates': GeoPoint(latitude, longitude),
        'working_days': workingDays,
        'holiday': holiday,
      };
      _locationNameController.clear();
      _locationCodeController.clear();
      _locationLatController.clear();
      _locationLngController.clear();
      _workingDaysController.clear();
      _selectedHoliday = 'Sunday';
      _editingLocationName = null;
    });
  }

  Future<void> _deleteLocation(String name) async {
    // Ensure the location is not used before deleting
    if (_locations.indexWhere((location) => location['name'] == name) < 3) {
      _showImportantElementAlert();
      return;
    }

    await _firestore.collection('Locations').doc(name).delete();

    setState(() {
      _locations.removeWhere((location) => location['name'] == name);
    });
  }

  Future<void> _addDepartment() async {
    String departmentName = _departmentController.text;

    await _departmentService.addDepartment(departmentName);

    setState(() {
      _departments.add(departmentName);
      _departmentController.clear();
    });
  }

  Future<void> _deleteDepartment(String name) async {
    if (_departments.indexOf(name) < 3) {
      _showImportantElementAlert();
      return;
    }

    await _departmentService.deleteDepartment(name);

    setState(() {
      _departments.removeWhere((department) => department == name);
    });
  }

  Future<void> _addLeaveType() async {
    String leaveTypeName = _leaveTypeController.text;

    await _leaveTypeService.addLeaveType(leaveTypeName);

    setState(() {
      _leaveTypes.add(leaveTypeName);
      _leaveTypeController.clear();
    });
  }

  Future<void> _deleteLeaveType(String name) async {
    if (_leaveTypes.indexOf(name) < 3) {
      _showImportantElementAlert();
      return;
    }

    await _leaveTypeService.deleteLeaveType(name);

    setState(() {
      _leaveTypes.removeWhere((leaveType) => leaveType == name);
    });
  }

  Future<void> _addDesignation() async {
    String designationName = _designationController.text;

    await _designationService.addDesignation(designationName);

    setState(() {
      _designations.add(designationName);
      _designationController.clear();
    });
  }

  Future<void> _deleteDesignation(String name) async {
    if (_designations.indexOf(name) < 3) {
      _showImportantElementAlert();
      return;
    }

    await _designationService.deleteDesignation(name);

    setState(() {
      _designations.removeWhere((designation) => designation == name);
    });
  }

  void _showImportantElementAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text('This element is already in use.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoService = Provider.of<LogoService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standard Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Company Name',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _saveCompanyName();
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Company Logo',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              logoService.logo != null
                  ? Image.file(
                      logoService.logo!,
                      width: 200,
                      height: 200,
                    )
                  : const Text('No logo selected'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await logoService.pickLogo();
                },
                child: const Text('Upload Logo'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Locations',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _locationNameController,
                decoration: const InputDecoration(labelText: 'Location Name'),
              ),
              TextField(
                controller: _locationCodeController,
                decoration: const InputDecoration(labelText: 'Location Code'),
              ),
              TextField(
                controller: _locationLatController,
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                controller: _locationLngController,
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
              TextField(
                controller: _workingDaysController,
                decoration: const InputDecoration(labelText: 'No. of Working Days'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedHoliday,
                decoration: const InputDecoration(labelText: 'Holiday of the Week'),
                items: _daysOfWeek.map((String day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHoliday = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (_locationNameController.text.isEmpty) {
                    // Handle empty location name error
                    return;
                  }

                  if (_editingLocationName != null) {
                    // Edit existing location
                    await _editLocation(_locationNameController.text);
                  } else {
                    // Add new location
                    await _addLocation();
                  }
                },
                child: const Text('Save Location'),
              ),
              const SizedBox(height: 10),
              _buildListView(_locations, 'Locations', _deleteLocation, _editLocation),
              const SizedBox(height: 20),
              const Text(
                'Departments',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _addDepartment();
                },
                child: const Text('Add Department'),
              ),
              const SizedBox(height: 10),
              _buildListView(_departments, 'Departments', _deleteDepartment, null),
              const SizedBox(height: 20),
              const Text(
                'Designations',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _designationController,
                decoration: const InputDecoration(labelText: 'Designation'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _addDesignation();
                },
                child: const Text('Add Designation'),
              ),
              const SizedBox(height: 10),
              _buildListView(_designations, 'Designations', _deleteDesignation, null),
              const SizedBox(height: 20),
              const Text(
                'Leave Types',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _leaveTypeController,
                decoration: const InputDecoration(labelText: 'Leave Type'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _addLeaveType();
                },
                child: const Text('Add Leave Type'),
              ),
              const SizedBox(height: 10),
              _buildListView(_leaveTypes, 'Leave Types', _deleteLeaveType, null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List items, String label, Function(String) deleteFunction, Function(String)? editFunction) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: item is String ? Text(item) : Text(item['name']),
          subtitle: item is Map ? Text(
            'Code: ${item['code']}\nCoordinates: ${item['coordinates'].latitude}, ${item['coordinates'].longitude}\nWorking Days: ${item['working_days']}\nHoliday: ${item['holiday']}',
          ) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (editFunction != null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _editingLocationName = item['name'];
                      _locationNameController.text = item['name'];
                      _locationCodeController.text = item['code'];
                      _locationLatController.text = item['coordinates'].latitude.toString();
                      _locationLngController.text = item['coordinates'].longitude.toString();
                      _workingDaysController.text = item['working_days'].toString();
                      _selectedHoliday = item['holiday'];
                    });
                  },
                ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await deleteFunction(item is String ? item : item['name']);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
