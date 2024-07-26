import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin/department_service.dart';
import '../services/admin/designation_service.dart';

class RegisteredEmployeesPage extends StatefulWidget {
  const RegisteredEmployeesPage({super.key});

  @override
  _RegisteredEmployeesPageState createState() =>
      _RegisteredEmployeesPageState();
}

class _RegisteredEmployeesPageState extends State<RegisteredEmployeesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Employees'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Regemp').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No registered employees found'));
          }

          final employees = snapshot.data!.docs;
          final filteredEmployees = employees.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['role'] != 'HR';
          }).toList();

          if (filteredEmployees.isEmpty) {
            return const Center(child: Text('No registered employees found'));
          }

          return ListView.builder(
            itemCount: filteredEmployees.length,
            itemBuilder: (context, index) {
              final data =
                  filteredEmployees[index].data() as Map<String, dynamic>;
              return EmployeeCard(data: data);
            },
          );
        },
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const EmployeeCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30.0,
                  backgroundColor: Colors.purple[100],
                  backgroundImage: data['dpImageUrl'] != null &&
                          data['dpImageUrl'].isNotEmpty
                      ? NetworkImage(data['dpImageUrl'])
                      : null,
                  child:
                      data['dpImageUrl'] == null || data['dpImageUrl'].isEmpty
                          ? Text(
                              '${data['firstName'][0]}${data['lastName'][0]}',
                              style: const TextStyle(
                                fontSize: 24.0,
                                color: Colors.white,
                              ),
                            )
                          : null,
                ),
                //   radius: 30.0,
                //   backgroundColor: Colors.purple[100],
                //   child: Text(
                //     '${data['firstName'][0]}${data['lastName'][0]}',
                //     style: TextStyle(
                //       fontSize: 24.0,
                //       color: Colors.white,
                //     ),
                //   ),
                // ),
                const SizedBox(width: 16.0),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${data['firstName']} ${data['lastName']}',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text('Phone: ${data['phoneNo']}'),
                      Text('Email: ${data['email']}'),
                      Text('Employee Type: ${data['employeeType']}'),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return EmployeeDetailsDialog(data: data);
                      },
                    );
                  },
                  child: const Text(
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
}

class EmployeeDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const EmployeeDetailsDialog({super.key, required this.data});

  @override
  _EmployeeDetailsDialogState createState() => _EmployeeDetailsDialogState();
}

class _EmployeeDetailsDialogState extends State<EmployeeDetailsDialog> {
  bool _isEditing = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _panController;
  late TextEditingController _passwordController;
  late TextEditingController _permanentAddressController;
  late TextEditingController _residentialAddressController;
  late TextEditingController _dobController;
  late TextEditingController _dpImageUrlController;
  late TextEditingController _supportUrlController;
  late TextEditingController _aadharNoController;
  late TextEditingController _aadharImageUrlController;
  late TextEditingController _joiningDateController;
  late TextEditingController _employeeIdController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;

  String _selectedDepartment = '';
  String _selectedDesignation = '';
  String _selectedLocation = '';
  String _selectedStatus = '';
  String _selectedRole = '';
  String _selectedEmployeeType = '';

  final Map<String, String> _validationErrors = {};
  final DesignationService _designationService = DesignationService();
  final DepartmentService _departmentService = DepartmentService();

  List<String> _departments = [];
  List<String> _designations = [];

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.data['firstName']);
    _lastNameController = TextEditingController(text: widget.data['lastName']);
    _phoneController = TextEditingController(text: widget.data['phoneNo']);
    _emailController = TextEditingController(text: widget.data['email']);
    _panController = TextEditingController(text: widget.data['panNo']);
    _passwordController = TextEditingController(text: widget.data['password']);
    _permanentAddressController =
        TextEditingController(text: widget.data['permanentAddress']);
    _residentialAddressController =
        TextEditingController(text: widget.data['residentialAddress']);
    _dobController = TextEditingController(text: widget.data['dob']);
    _dpImageUrlController =
        TextEditingController(text: widget.data['dpImageUrl']);
    _supportUrlController =
        TextEditingController(text: widget.data['supportUrl']);
    _aadharNoController =
        TextEditingController(text: widget.data['aadharNo'] ?? '');
    _aadharImageUrlController =
        TextEditingController(text: widget.data['aadharImageUrl'] ?? '');
    _joiningDateController =
        TextEditingController(text: widget.data['joiningDate']);
    _employeeIdController =
        TextEditingController(text: widget.data['employeeId']);
    _bankNameController = TextEditingController(text: widget.data['bankName']);
    _accountNumberController =
        TextEditingController(text: widget.data['accountNumber']);
    _ifscCodeController = TextEditingController(text: widget.data['ifscCode']);
    _selectedDepartment = widget.data['department'] ?? '';
    _selectedDesignation = widget.data['designation'] ?? '';
    _selectedLocation = widget.data['location'] ?? '';
    _selectedStatus = widget.data['status'] ?? '';
    _selectedRole = widget.data['role'] ?? '';
    _selectedEmployeeType = widget.data['employeeType'] ?? '';

    _fetchData();
  }

  Future<void> _fetchData() async {
    final departments = await _departmentService.getDepartments();
    final designations = await _designationService.getDesignations();
    setState(() {
      _departments = departments;
      _designations = designations;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _panController.dispose();
    _passwordController.dispose();
    _permanentAddressController.dispose();
    _residentialAddressController.dispose();
    _dobController.dispose();
    _dpImageUrlController.dispose();
    _supportUrlController.dispose();
    _aadharNoController.dispose();
    _aadharImageUrlController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final pan = _panController.text.trim();
    final password = _passwordController.text.trim();
    final permanentAddress = _permanentAddressController.text.trim();
    final residentialAddress = _residentialAddressController.text.trim();
    final dob = _dobController.text.trim();
    final aadharNo = _aadharNoController.text.trim();

    _validationErrors.clear();

    if (firstName.isEmpty || lastName.isEmpty) {
      _validationErrors['name'] =
          'First name and last name should not be empty.';
    } else if (firstName.length > 50 || lastName.length > 50) {
      _validationErrors['name'] =
          'First name and last name should not exceed 50 characters.';
    } else if (!RegExp(r'^[a-zA-Z.]+$').hasMatch(firstName) ||
        !RegExp(r'^[a-zA-Z.]+$').hasMatch(lastName)) {
      _validationErrors['name'] =
          'First name and last name should contain only alphabets and dot (.)';
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _validationErrors['phone'] = 'Phone number should be 10 digits.';
    }

    if (email.isEmpty ||
        !RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
            .hasMatch(email)) {
      _validationErrors['email'] = 'Please enter a valid email address.';
    }

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) {
      _validationErrors['pan'] = 'PAN number should be valid.';
    }

    if (password.isEmpty) {
      _validationErrors['password'] = 'Password must not be empty.';
    } else if (password.length < 8) {
      _validationErrors['password'] =
          'Password must be at least 8 characters long.';
    } else if (!RegExp(
            r'^(?=.[a-z])(?=.[A-Z])(?=.\d)(?=.[@$!%?&])[A-Za-z\d@$!%?&]')
        .hasMatch(password)) {
      _validationErrors['password'] =
          'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.';
    }

    if (permanentAddress.isEmpty ||
        permanentAddress.length < 10 ||
        permanentAddress.length > 100) {
      _validationErrors['permanentAddress'] =
          'Permanent address should be between 10 and 100 characters.';
    }

    if (residentialAddress.isEmpty ||
        residentialAddress.length < 10 ||
        residentialAddress.length > 100) {
      _validationErrors['residentialAddress'] =
          'Residential address should be between 10 and 100 characters.';
    }

    if (dob.isEmpty) {
      _validationErrors['dob'] = 'Date of birth should not be empty.';
    } else {
      try {
        final dobDate = DateTime.parse(dob);
        final today = DateTime.now();
        final eighteenYearsAgo =
            DateTime(today.year - 18, today.month, today.day);

        if (dobDate.isAfter(eighteenYearsAgo)) {
          _validationErrors['dob'] = 'Employee must be at least 18 years old.';
        }
      } catch (e) {
        _validationErrors['dob'] = 'Invalid date format.';
      }
    }

    if (aadharNo.isNotEmpty && !RegExp(r'^[0-9]{12}$').hasMatch(aadharNo)) {
      _validationErrors['aadharNo'] = 'Aadhar number should be 12 digits.';
    }

    return _validationErrors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildRow('First Name', _firstNameController),
              _buildRow('Last Name', _lastNameController),
              _buildRow('Phone Number', _phoneController),
              _buildRow('Email', _emailController),
              _buildRow('PAN Number', _panController),
              _buildRow('Password', _passwordController, obscureText: true),
              _buildRow('Permanent Address', _permanentAddressController),
              _buildRow('Residential Address', _residentialAddressController),
              _buildRow('Date of Birth', _dobController),
              _buildRow('Profile Picture', _dpImageUrlController),
              _buildRow('Supporting Document', _supportUrlController),
              _buildRow('Aadhar Number', _aadharNoController),
              _buildRow('Aadhaar Document', _aadharImageUrlController),
              _buildRow('Joining Date', _joiningDateController),
              _buildRow('employeeId', _employeeIdController),
              _buildRow('Bank Name', _bankNameController),
              _buildRow('Account Number', _accountNumberController),
              _buildRow('IFSC Code', _ifscCodeController),
              _buildDropdown('Department', _selectedDepartment, [
                'Sales',
                'Services',
                'Spares',
                'Administration',
                'Board of Directors'
              ]),
              _buildDropdown('Designation', _selectedDesignation, [
                'Manager',
                'Senior Engineer',
                'Junior Engineer',
                'Technician',
                'Executive'
              ]),
              _buildDropdown('Location', _selectedLocation,
                  ['Jeypore', 'Berhampur', 'Rayagada']),
              _buildDropdown('Status', _selectedStatus, ['Active', 'Inactive']),
              _buildDropdown('Role', _selectedRole, ['Standard', 'HR']),
              _buildDropdown('Employee Type', _selectedEmployeeType,
                  ['On-site', 'Off-site']),
              if (_validationErrors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _validationErrors.entries.map((entry) {
                      return Text(
                        entry.value,
                        style: const TextStyle(color: Colors.red),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      if (_isEditing) {
                        if (_validateInputs()) {
                          // Save the updated data to Firestore
                          FirebaseFirestore.instance
                              .collection('Regemp')
                              .doc(widget.data['id'])
                              .update({
                            'firstName': _firstNameController.text.trim(),
                            'lastName': _lastNameController.text.trim(),
                            'phoneNo': _phoneController.text.trim(),
                            'email': _emailController.text.trim(),
                            'panNo': _panController.text.trim(),
                            'password': _passwordController.text.trim(),
                            'permanentAddress':
                                _permanentAddressController.text.trim(),
                            'residentialAddress':
                                _residentialAddressController.text.trim(),
                            'dob': _dobController.text.trim(),
                            'dpImageUrl': _dpImageUrlController.text.trim(),
                            'supportUrl': _supportUrlController.text.trim(),
                            'aadharNo': _aadharNoController.text.trim(),
                            'aadharImageUrl':
                                _aadharImageUrlController.text.trim(),
                            'joiningDate': _joiningDateController.text.trim(),
                            'employeeId': _employeeIdController.text.trim(),
                            'bankName': _bankNameController.text.trim(),
                            'accountNumber':
                                _accountNumberController.text.trim(),
                            'ifscCode': _ifscCodeController.text.trim(),
                            'department': _selectedDepartment,
                            'designation': _selectedDesignation,
                            'location': _selectedLocation,
                            'status': _selectedStatus,
                            'role': _selectedRole,
                            'employeeType': _selectedEmployeeType,
                          }).then((_) {
                            setState(() {
                              _isEditing = false;
                            });
                          }).catchError((error) {
                            // Handle error
                            print('Failed to update employee: $error');
                          });
                        }
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
                    child: Text(
                      _isEditing ? 'Save' : 'Edit',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        readOnly: !_isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label, String selectedValue, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue.isNotEmpty ? selectedValue : null,
            onChanged: _isEditing
                ? (newValue) {
                    setState(() {
                      switch (label) {
                        case 'Department':
                          _selectedDepartment = newValue!;
                          break;
                        case 'Designation':
                          _selectedDesignation = newValue!;
                          break;
                        case 'Location':
                          _selectedLocation = newValue!;
                          break;
                        case 'Status':
                          _selectedStatus = newValue!;
                          break;
                        case 'Role':
                          _selectedRole = newValue!;
                          break;
                        case 'Employee Type':
                          _selectedEmployeeType = newValue!;
                          break;
                      }
                    });
                  }
                : null,
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: RegisteredEmployeesPage(),
  ));
}