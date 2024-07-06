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
import 'services/company_name_service.dart';
import 'upcoming_events_page.dart';
import 'standard_settings_page.dart'; // Import the Standard Settings page

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
