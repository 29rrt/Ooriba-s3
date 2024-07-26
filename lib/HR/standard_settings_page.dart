import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/admin/company_name_service.dart';
import '../services/admin/department_service.dart';
import '../services/admin/leave_type_service.dart';
import '../services/admin/logo_service.dart';
import '../services/admin/retrieveLocation_service.dart';

// class StandardSettingsPage extends StatefulWidget {
//   @override
//   _StandardSettingsPageState createState() => _StandardSettingsPageState();
// }

// class _StandardSettingsPageState extends State<StandardSettingsPage> {
//   final TextEditingController _companyNameController = TextEditingController();
//   final TextEditingController _locationNameController = TextEditingController();
//   final TextEditingController _locationPrefixController = TextEditingController();
//   final TextEditingController _locationLatController = TextEditingController();
//   final TextEditingController _locationLngController = TextEditingController();
//   final TextEditingController _departmentController = TextEditingController();
//   final TextEditingController _leaveTypeController = TextEditingController();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> _locations = [];
//   List<String> _departments = [];
//   List<String> _leaveTypes = [];
//   late LocationService _locationService;
//   late DepartmentService _departmentService;
//   late LeaveTypeService _leaveTypeService;

//   @override
//   void initState() {
//     super.initState();
//     _locationService = LocationService();
//     _departmentService = DepartmentService();
//     _leaveTypeService = LeaveTypeService();
//     _loadCompanyName();
//     _loadLocations();
//     _loadDepartments();
//     _loadLeaveTypes();
//   }

//   Future<void> _loadCompanyName() async {
//     DocumentSnapshot documentSnapshot = await _firestore.collection('Config').doc('company_name').get();

//     if (documentSnapshot.exists) {
//       _companyNameController.text = documentSnapshot['name'];
//     }
//   }

//   Future<void> _loadLocations() async {
//     QuerySnapshot querySnapshot = await _firestore.collection('Locations').get();
//     setState(() {
//       _locations = querySnapshot.docs.map((doc) {
//         return {
//           'name': doc.id,
//           'prefix': doc['prefix'],
//           'coordinates': doc['coordinates'],
//         };
//       }).toList();
//     });
//   }

//   Future<void> _loadDepartments() async {
//     List<String> departments = await _departmentService.getDepartments();
//     setState(() {
//       _departments = departments;
//     });
//   }

//   Future<void> _loadLeaveTypes() async {
//     List<String> leaveTypes = await _leaveTypeService.getLeaveTypes();
//     setState(() {
//       _leaveTypes = leaveTypes;
//     });
//   }

//   Future<void> _saveCompanyName() async {
//     await _firestore.collection('Config').doc('company_name').set({
//       'name': _companyNameController.text,
//     });

//     final companyNameService = Provider.of<CompanyNameService>(context, listen: false);
//     companyNameService.setCompanyName(_companyNameController.text);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Company name updated')),
//     );
//   }

//   Future<void> _addLocation() async {
//     String locationName = _locationNameController.text;
//     String prefix = _locationPrefixController.text;
//     double latitude = double.parse(_locationLatController.text);
//     double longitude = double.parse(_locationLngController.text);

//     await _firestore.collection('Locations').doc(locationName).set({
//       'prefix': prefix,
//       'coordinates': GeoPoint(latitude, longitude),
//     });

//     setState(() {
//       _locations.add({
//         'name': locationName,
//         'prefix': prefix,
//         'coordinates': GeoPoint(latitude, longitude),
//       });
//       _locationNameController.clear();
//       _locationPrefixController.clear();
//       _locationLatController.clear();
//       _locationLngController.clear();
//     });
//   }

//   Future<void> _deleteLocation(String name) async {
//     if (_locations.indexWhere((location) => location['name'] == name) < 3) {
//       _showImportantElementAlert();
//       return;
//     }

//     await _firestore.collection('Locations').doc(name).delete();

//     setState(() {
//       _locations.removeWhere((location) => location['name'] == name);
//     });
//   }

//   Future<void> _addDepartment() async {
//     String departmentName = _departmentController.text;

//     await _departmentService.addDepartment(departmentName);

//     setState(() {
//       _departments.add(departmentName);
//       _departmentController.clear();
//     });
//   }

//   Future<void> _deleteDepartment(String name) async {
//     if (_departments.indexOf(name) < 3) {
//       _showImportantElementAlert();
//       return;
//     }

//     await _departmentService.deleteDepartment(name);

//     setState(() {
//       _departments.removeWhere((department) => department == name);
//     });
//   }

//   Future<void> _addLeaveType() async {
//     String leaveTypeName = _leaveTypeController.text;

//     await _leaveTypeService.addLeaveType(leaveTypeName);

//     setState(() {
//       _leaveTypes.add(leaveTypeName);
//       _leaveTypeController.clear();
//     });
//   }

//   Future<void> _deleteLeaveType(String name) async {
//     if (_leaveTypes.indexOf(name) < 3) {
//       _showImportantElementAlert();
//       return;
//     }

//     await _leaveTypeService.deleteLeaveType(name);

//     setState(() {
//       _leaveTypes.removeWhere((leaveType) => leaveType == name);
//     });
//   }

//   void _showImportantElementAlert() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Cannot Delete'),
//           content: const Text('This element is already in use.'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final logoService = Provider.of<LogoService>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Standard Settings'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               const Text(
//                 'Company Name',
//                 style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//               ),
//               TextField(
//                 controller: _companyNameController,
//                 decoration: const InputDecoration(labelText: 'Company Name'),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   await _saveCompanyName();
//                 },
//                 child: const Text('Save'),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'Company Logo',
//                 style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//               ),
//               logoService.logo != null
//                   ? Image.file(
//                       logoService.logo!,
//                       width: 200,
//                       height: 200,
//                     )
//                   : const Text('No logo selected'),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   await logoService.pickLogo();
//                 },
//                 child: const Text('Upload Logo'),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'Locations',
//                 style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//               ),
//               TextField(
//                 controller: _locationNameController,
//                 decoration: const InputDecoration(labelText: 'Location Name'),
//               ),
//               TextField(
//                 controller: _locationPrefixController,
//                 decoration: const InputDecoration(labelText: 'Location Prefix'),
//               ),
//               TextField(
//                 controller: _locationLatController,
//                 decoration: const InputDecoration(labelText: 'Latitude'),
//               ),
//               TextField(
//                 controller: _locationLngController,
//                 decoration: const InputDecoration(labelText: 'Longitude'),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   await _addLocation();
//                 },
//                 child: const Text('Add Location'),
//               ),
//               const SizedBox(height: 10),
//               _buildListView(_locations, 'Locations', _deleteLocation),
//               const SizedBox(height: 20),
//               const Text(
//                 'Departments',
//                 style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//               ),
//               TextField(
//                 controller: _departmentController,
//                 decoration: const InputDecoration(labelText: 'Department'),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   await _addDepartment();
//                 },
//                 child: const Text('Add Department'),
//               ),
//               const SizedBox(height: 10),
//               _buildListView(_departments, 'Departments', _deleteDepartment),
//               const SizedBox(height: 20),
//               const Text(
//                 'Leave Types',
//                 style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//               ),
//               TextField(
//                 controller: _leaveTypeController,
//                 decoration: const InputDecoration(labelText: 'Leave Type'),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   await _addLeaveType();
//                 },
//                 child: const Text('Add Leave Type'),
//               ),
//               const SizedBox(height: 10),
//               _buildListView(_leaveTypes, 'Leave Types', _deleteLeaveType),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildListView(List items, String label, Function(String) deleteFunction) {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       itemCount: items.length,
//       itemBuilder: (context, index) {
//         final item = items[index];
//         return ListTile(
//           title: item is String ? Text(item) : Text(item['name']),
//           subtitle: item is Map ? Text(
//             'Prefix: ${item['prefix']}\nCoordinates: ${item['coordinates'].latitude}, ${item['coordinates'].longitude}',
//           ) : null,
//           trailing: IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: () async {
//               await deleteFunction(item is String ? item : item['name']);
//             },
//           ),
//         );
//       },
//     );
//   }
// }

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
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _leaveTypeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _locations = [];
  List<String> _departments = [];
  List<String> _leaveTypes = [];
  late LocationService _locationService;
  late DepartmentService _departmentService;
  late LeaveTypeService _leaveTypeService;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _departmentService = DepartmentService();
    _leaveTypeService = LeaveTypeService();
    _loadCompanyName();
    _loadLocations();
    _loadDepartments();
    _loadLeaveTypes();
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
                controller: _locationPrefixController,
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _addLocation();
                },
                child: const Text('Add Location'),
              ),
              const SizedBox(height: 10),
              _buildListView(_locations, 'Locations', _deleteLocation),
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
              _buildListView(_departments, 'Departments', _deleteDepartment),
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
              _buildListView(_leaveTypes, 'Leave Types', _deleteLeaveType),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(
      List items, String label, Function(String) deleteFunction) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: item is String ? Text(item) : Text(item['name']),
          subtitle: item is Map
              ? Text(
                  'Prefix: ${item['prefix']}\nCoordinates: ${item['coordinates'].latitude}, ${item['coordinates'].longitude}',
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await deleteFunction(item is String ? item : item['name']);
            },
          ),
        );
      },
    );
  }
}