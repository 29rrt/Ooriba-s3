import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/admin/company_name_service.dart';
import '../services/admin/department_service.dart';
import '../services/admin/designation_service.dart';
import '../services/admin/leave_type_service.dart';
import '../services/admin/logo_service.dart';
import '../services/admin/retrieveLocation_service.dart';

class StandardSettingsPage extends StatefulWidget {
  @override
  _StandardSettingsPageState createState() => _StandardSettingsPageState();
}

class _StandardSettingsPageState extends State<StandardSettingsPage> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _locationPrefixController =
      TextEditingController();
  final TextEditingController _locationLatController = TextEditingController();
  final TextEditingController _locationLngController = TextEditingController();
  final TextEditingController _locationMaxLeaveController =
      TextEditingController();
  final TextEditingController _locationWorkingDaysController =
      TextEditingController();
  final TextEditingController _locationRestrictedAttendanceRadiusController =
      TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _leaveTypeController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _locations = [];
  List<String> _departments = [];
  List<String> _leaveTypes = [];
  List<String> _designations = [];
  late LocationService _locationService;
  late DepartmentService _departmentService;
  late LeaveTypeService _leaveTypeService;
  late DesignationService _designationService;

  String _selectedHoliday = 'Monday';
  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _departmentService = DepartmentService();
    _leaveTypeService = LeaveTypeService();
    _designationService = DesignationService();
    _loadCompanyName();
    _loadLocations();
    _loadDepartments();
    _loadLeaveTypes();
    _loadDesignations();
  }

  Future<void> _loadCompanyName() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection('Config').doc('company_name').get();

    if (documentSnapshot.exists) {
      _companyNameController.text = documentSnapshot['name'];
    }
  }

  Future<void> _loadLocations() async {
    QuerySnapshot querySnapshot =
        await _firestore.collection('Locations').get();
    setState(() {
      _locations = querySnapshot.docs.map((doc) {
        return {
          'name': doc.id,
          'prefix': doc['prefix'],
          'coordinates': doc['coordinates'],
          'max_leave': doc['max_leave'],
          'holiday': doc['holiday'],
          'working_days': doc['working_days'],
          'restricted_radius': doc['restricted_radius'],
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

    final companyNameService =
        Provider.of<CompanyNameService>(context, listen: false);
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
    int maxLeave = int.parse(_locationMaxLeaveController.text);
    int workingDays = int.parse(_locationWorkingDaysController.text);
    int restrictedRadius =
        int.parse(_locationRestrictedAttendanceRadiusController.text);

    await _firestore.collection('Locations').doc(locationName).set({
      'prefix': prefix,
      'coordinates': GeoPoint(latitude, longitude),
      'max_leave': maxLeave,
      'holiday': _selectedHoliday,
      'working_days': workingDays,
      'restricted_radius': restrictedRadius,
    });

    setState(() {
      _locations.add({
        'name': locationName,
        'prefix': prefix,
        'coordinates': GeoPoint(latitude, longitude),
        'max_leave': maxLeave,
        'holiday': _selectedHoliday,
        'working_days': workingDays,
        'restricted_radius': restrictedRadius,
      });
      _locationNameController.clear();
      _locationPrefixController.clear();
      _locationLatController.clear();
      _locationLngController.clear();
      _locationMaxLeaveController.clear();
      _locationWorkingDaysController.clear();
      _locationRestrictedAttendanceRadiusController.clear();
      _selectedHoliday = 'Monday';
    });
  }

  Future<void> _editLocation(Map<String, dynamic> location) async {
    _locationNameController.text = location['name'];
    _locationPrefixController.text = location['prefix'];
    _locationLatController.text = location['coordinates'].latitude.toString();
    _locationLngController.text = location['coordinates'].longitude.toString();
    _locationMaxLeaveController.text = location['max_leave'].toString();
    _locationWorkingDaysController.text = location['working_days'].toString();
    _locationRestrictedAttendanceRadiusController.text =
        location['restricted_radius'].toString();
    _selectedHoliday = location['holiday'];

    setState(() {
      _locations.remove(location);
    });
  }

  Future<void> _deleteLocation(String name) async {
    // if (_locations.indexWhere((location) => location['name'] == name) < 3) {
    //   _showImportantElementAlert();
    //   return;
    // }

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
    // if (_departments.indexOf(name) < 3) {
    //   _showImportantElementAlert();
    //   return;
    // }

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
    // if (_leaveTypes.indexOf(name) < 3) {
    //   _showImportantElementAlert();
    //   return;
    // }

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
    // if (_designations.indexOf(name) < 3) {
    //   _showImportantElementAlert();
    //   return;
    // }

    await _designationService.deleteDesignation(name);

    setState(() {
      _designations.removeWhere((designation) => designation == name);
    });
  }

  // void _showImportantElementAlert() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Cannot Delete'),
  //         content: const Text('This element is already in use.'),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('OK'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
                decoration: const InputDecoration(labelText: 'Company Name (re-open the app to see updates)'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _saveCompanyName();
                },
                child: const Text('Save'),
              ),
              const Divider(),
              const Text(
                'Locations',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              for (var location in _locations)
                ListTile(
                  title: Text(location['name']),
                  subtitle: Text(
                      // 'Code: ${location['code']}\nCoordinates: ${location['coordinates'].latitude}, ${location['coordinates'].longitude}\nMax Leave: ${location['max_leave']}\nHoliday: ${location['holiday']}\nWorking Days: ${location['working_days']}\nRestricted Attendance Radius: ${location['restricted_radius']}'),
                      'Code: ${location['prefix']}\nCoordinates: ${location['coordinates'].latitude}, ${location['coordinates'].longitude}\nMax Leave: ${location['max_leave']}\nHoliday: ${location['holiday']}\nWorking Days: ${location['working_days']}\nRestricted Attendance Radius: ${location['restricted_radius']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editLocation(location);
                        },
                        //),
                        //IconButton(
                        //  icon: const Icon(Icons.delete),
                        //  onPressed: () {
                        //    _deleteLocation(location['name']);
                        //  },
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _locationNameController,
                decoration: const InputDecoration(labelText: 'Location Name'),
              ),
              TextField(
                controller: _locationPrefixController,
                decoration: const InputDecoration(labelText: 'Location Code'),
              ),
              TextField(
                controller: _locationLatController,
                decoration:
                    const InputDecoration(labelText: 'Location Latitude'),
              ),
              TextField(
                controller: _locationLngController,
                decoration:
                    const InputDecoration(labelText: 'Location Longitude'),
              ),
              TextField(
                controller: _locationMaxLeaveController,
                decoration: const InputDecoration(labelText: 'Max sick Leave'),
              ),
              TextField(
                controller: _locationWorkingDaysController,
                decoration: const InputDecoration(labelText: 'Working Days'),
              ),
              TextField(
                controller: _locationRestrictedAttendanceRadiusController,
                decoration: const InputDecoration(
                    labelText: 'Restricted Attendance Radius (in meters only number)'),
              ),
              DropdownButtonFormField(
                value: _selectedHoliday,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHoliday = newValue!;
                  });
                },
                items: _weekDays.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _addLocation();
                },
                child: const Text('Add Location'),
              ),
              const Divider(),
              const Text(
                'Departments',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              for (var department in _departments)
                ListTile(
                  title: Text(department),
                  //trailing: IconButton(
                  //  icon: const Icon(Icons.delete),
                  //  onPressed: () {
                  //    _deleteDepartment(department);
                  //  },
                  //),
                ),
              TextField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department Name'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _addDepartment();
                },
                child: const Text('Add Department'),
              ),
              const Divider(),
              const Text(
                'Leave Types',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              for (var leaveType in _leaveTypes)
                ListTile(
                  title: Text(leaveType),
                  //trailing: IconButton(
                  //  icon: const Icon(Icons.delete),
                  //  onPressed: () {
                  //    _deleteLeaveType(leaveType);
                  //  },
                  //),
                ),
              TextField(
                controller: _leaveTypeController,
                decoration: const InputDecoration(labelText: 'Leave Type Name'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _addLeaveType();
                },
                child: const Text('Add Leave Type'),
              ),
              const Divider(),
              const Text(
                'Designations',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              for (var designation in _designations)
                ListTile(
                  title: Text(designation),
                  //trailing: IconButton(
                  //  icon: const Icon(Icons.delete),
                  //  onPressed: () {
                  //    _deleteDesignation(designation);
                  //  },
                  //),
                ),
              TextField(
                controller: _designationController,
                decoration:
                    const InputDecoration(labelText: 'Designation Name'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _addDesignation();
                },
                child: const Text('Add Designation'),
              ),
              const Divider(),
              const Text(
                'Company Logo',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    await logoService.pickLogo();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logo uploaded')),
                    );
                  },
                  child: logoService.logo != null
                      ? Image.file(
                          logoService.logo!,
                          height: 200,
                        )
                      : Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.add_a_photo,
                            size: 50,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}