import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employee_details_page[2].dart';
import 'registered_employees_page[1].dart';
import 'services/auth_service.dart'; // Replace with your auth service file path
import 'attendance.dart'; // Assuming this file contains DatePickerButton widget
import 'rejected_employees_page.dart';
import 'services/registered_service.dart';

class HRDashboardPage extends StatefulWidget {
  const HRDashboardPage({Key? key}) : super(key: key);

  @override
  _HRDashboardPageState createState() => _HRDashboardPageState();
}

class _HRDashboardPageState extends State<HRDashboardPage> {
  final RegisteredService _registeredService = RegisteredService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
                'HR Dashboard Menu',
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  // SizedBox(width: 16.0),
                  // Expanded(
                  //   child: _buildDashboardBlock(
                  //     context,
                  //     'New Applicants',
                  //     Icons.person_add,
                  //     Colors.green,
                  //     _showNewApplicants,
                  //   ),
                  // ),
                  SizedBox(width: 16.0),
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
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Applicant Details',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('Employee').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No employees found'));
                }

                final employees = snapshot.data!.docs;
                return Column(
                  children: employees.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildEmployeeCard(context, data, doc.reference);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardBlock(BuildContext context, String title, IconData icon,
      Color color, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: 200.0,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              color: Colors.white,
              size: 36.0,
            ),
            SizedBox(height: 8.0),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, Map<String, dynamic> data,
      DocumentReference docRef) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30.0,
                  backgroundImage: data['profilePictureUrl'] != null
                      ? NetworkImage(data['profilePictureUrl'])
                      : AssetImage('assets/placeholder.png') as ImageProvider,
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${data['firstName']} ${data['lastName']}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text('Phone: ${data['phoneNo']}'),
                    Text('Email: ${data['email']}'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EmployeeDetailsPage(employeeData: data),
                      ),
                    );
                  },
                  child: Text(
                    'View More',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
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

  // void _showNewApplicants(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('New Applicants'),
  //         content: const Text('List of new applicants...'),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Close'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showRejectedApplications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RejectedEmployeesPage(),
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailsPage(employeeData: data),
      ),
    );
  }
}

class EditEmployeePage extends StatefulWidget {
  final Map<String, dynamic> employeeData;

  EditEmployeePage({required this.employeeData});

  @override
  _EditEmployeePageState createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends State<EditEmployeePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNoController;
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.employeeData['firstName']);
    _lastNameController =
        TextEditingController(text: widget.employeeData['lastName']);
    _emailController =
        TextEditingController(text: widget.employeeData['email']);
    _phoneNoController =
        TextEditingController(text: widget.employeeData['phoneNo']);
    _ageController =
        TextEditingController(text: widget.employeeData['age'].toString());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNoController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Employee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _phoneNoController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic> updatedEmployee = {
                  'firstName': _firstNameController.text,
                  'lastName': _lastNameController.text,
                  'email': _emailController.text,
                  'phoneNo': _phoneNoController.text,
                  'age': int.parse(_ageController.text),
                };
                Navigator.pop(context, updatedEmployee);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}