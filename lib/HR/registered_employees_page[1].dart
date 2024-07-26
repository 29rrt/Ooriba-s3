import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisteredEmployeesPage extends StatefulWidget {
  @override
  _RegisteredEmployeesPageState createState() => _RegisteredEmployeesPageState();
}

class _RegisteredEmployeesPageState extends State<RegisteredEmployeesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registered Employees'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Regemp').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No registered employees found'));
          }

          final employees = snapshot.data!.docs;
          final filteredEmployees = employees.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data != null && data['role'] != 'HR';
          }).toList();

          if (filteredEmployees.isEmpty) {
            return Center(child: Text('No registered employees found'));
          }

          return ListView.builder(
            itemCount: filteredEmployees.length,
            itemBuilder: (context, index) {
              final data = filteredEmployees[index].data() as Map<String, dynamic>?;
              if (data == null) {
                return Container();
              }
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

  const EmployeeCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: Colors.purple[100],
                  backgroundImage: data['dpImageUrl'] != null && data['dpImageUrl'].isNotEmpty
                      ? NetworkImage(data['dpImageUrl'])
                      : null,
                  child: (data['dpImageUrl'] == null || data['dpImageUrl'].isEmpty) && data['firstName'] != null && data['lastName'] != null
                      ? Text(
                          '${data['firstName']?[0] ?? ''}${data['lastName']?[0] ?? ''}',
                          style: TextStyle(
                            fontSize: 24.0,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${data['firstName'] ?? 'N/A'} ${data['lastName'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text('Phone: ${data['phoneNo'] ?? 'N/A'}'),
                    Text('Email: ${data['email'] ?? 'N/A'}'),
                    Text('Employee Type: ${data['employeeType'] ?? 'N/A'}'),
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
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return EmployeeDetailsDialog(data: data);
                      },
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
}

class EmployeeDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const EmployeeDetailsDialog({Key? key, required this.data}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.data['firstName']);
    _lastNameController = TextEditingController(text: widget.data['lastName']);
    _phoneController = TextEditingController(text: widget.data['phoneNo']);
    _emailController = TextEditingController(text: widget.data['email']);
    _panController = TextEditingController(text: widget.data['panNo']);
    _passwordController = TextEditingController(text: widget.data['password']);
    _permanentAddressController = TextEditingController(text: widget.data['permanentAddress']);
    _residentialAddressController = TextEditingController(text: widget.data['residentialAddress']);
    _dobController = TextEditingController(text: widget.data['dob']);
    _dpImageUrlController = TextEditingController(text: widget.data['dpImageUrl']);
    _supportUrlController = TextEditingController(text: widget.data['supportUrl']);
    _aadharNoController = TextEditingController(text: widget.data['aadharNo'] ?? '');
    _aadharImageUrlController = TextEditingController(text: widget.data['aadharImageUrl'] ?? '');
    _joiningDateController = TextEditingController(text: widget.data['joiningDate']);
    _employeeIdController = TextEditingController(text: widget.data['employeeId']);
    _bankNameController = TextEditingController(text: widget.data['bankName']);
    _accountNumberController = TextEditingController(text: widget.data['accountNumber']);
    _ifscCodeController = TextEditingController(text: widget.data['ifscCode']);
    _selectedDepartment = widget.data['department'] ?? '';
    _selectedDesignation = widget.data['designation'] ?? '';
    _selectedLocation = widget.data['location'] ?? '';
    _selectedStatus = widget.data['status'] ?? '';
    _selectedRole = widget.data['role'] ?? '';
    _selectedEmployeeType = widget.data['employeeType'] ?? '';
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
    final panNo = _panController.text.trim();
    final password = _passwordController.text.trim();
    final permanentAddress = _permanentAddressController.text.trim();
    final residentialAddress = _residentialAddressController.text.trim();
    final dob = _dobController.text.trim();
    final dpImageUrl = _dpImageUrlController.text.trim();
    final supportUrl = _supportUrlController.text.trim();
    final aadharNo = _aadharNoController.text.trim();
    final aadharImageUrl = _aadharImageUrlController.text.trim();
    final joiningDate = _joiningDateController.text.trim();
    final employeeId = _employeeIdController.text.trim();
    final bankName = _bankNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final ifscCode = _ifscCodeController.text.trim();

    _validationErrors.clear();

    if (firstName.isEmpty) {
      _validationErrors['firstName'] = 'First name is required';
    }

    if (lastName.isEmpty) {
      _validationErrors['lastName'] = 'Last name is required';
    }

    if (phone.isEmpty) {
      _validationErrors['phoneNo'] = 'Phone number is required';
    }

    if (email.isEmpty) {
      _validationErrors['email'] = 'Email is required';
    }

    if (permanentAddress.isEmpty) {
      _validationErrors['permanentAddress'] = 'Permanent address is required';
    }

    if (residentialAddress.isEmpty) {
      _validationErrors['residentialAddress'] = 'Residential address is required';
    }

    if (dob.isEmpty) {
      _validationErrors['dob'] = 'Date of birth is required';
    }

    if (joiningDate.isEmpty) {
      _validationErrors['joiningDate'] = 'Joining date is required';
    }

    if (employeeId.isEmpty) {
      _validationErrors['employeeId'] = 'Employee ID is required';
    }

    if (bankName.isEmpty) {
      _validationErrors['bankName'] = 'Bank name is required';
    }

    if (accountNumber.isEmpty) {
      _validationErrors['accountNumber'] = 'Account number is required';
    }

    if (ifscCode.isEmpty) {
      _validationErrors['ifscCode'] = 'IFSC code is required';
    }

    setState(() {});
    return _validationErrors.isEmpty;
  }

  Future<void> _updateEmployeeData() async {
    if (!_validateInputs()) {
      return;
    }

    final data = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phoneNo': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'panNo': _panController.text.trim(),
      'password': _passwordController.text.trim(),
      'permanentAddress': _permanentAddressController.text.trim(),
      'residentialAddress': _residentialAddressController.text.trim(),
      'dob': _dobController.text.trim(),
      'dpImageUrl': _dpImageUrlController.text.trim(),
      'supportUrl': _supportUrlController.text.trim(),
      'aadharNo': _aadharNoController.text.trim(),
      'aadharImageUrl': _aadharImageUrlController.text.trim(),
      'joiningDate': _joiningDateController.text.trim(),
      'employeeId': _employeeIdController.text.trim(),
      'bankName': _bankNameController.text.trim(),
      'accountNumber': _accountNumberController.text.trim(),
      'ifscCode': _ifscCodeController.text.trim(),
      'department': _selectedDepartment,
      'designation': _selectedDesignation,
      'location': _selectedLocation,
      'status': _selectedStatus,
      'role': _selectedRole,
      'employeeType': _selectedEmployeeType,
    };

    try {
      await FirebaseFirestore.instance
          .collection('Regemp')
          .doc(widget.data['employeeId'])
          .update(data);
      Navigator.of(context).pop();
    } catch (e) {
      print('Error updating employee data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Employee Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _firstNameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'First Name',
                errorText: _validationErrors['firstName'],
              ),
            ),
            TextField(
              controller: _lastNameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Last Name',
                errorText: _validationErrors['lastName'],
              ),
            ),
            TextField(
              controller: _phoneController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                errorText: _validationErrors['phoneNo'],
              ),
            ),
            TextField(
              controller: _emailController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _validationErrors['email'],
              ),
            ),
            TextField(
              controller: _panController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'PAN Number',
                errorText: _validationErrors['panNo'],
              ),
            ),
            TextField(
              controller: _passwordController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            TextField(
              controller: _permanentAddressController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Permanent Address',
                errorText: _validationErrors['permanentAddress'],
              ),
            ),
            TextField(
              controller: _residentialAddressController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Residential Address',
                errorText: _validationErrors['residentialAddress'],
              ),
            ),
            TextField(
              controller: _dobController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                errorText: _validationErrors['dob'],
              ),
            ),
            TextField(
              controller: _dpImageUrlController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'DP Image URL',
              ),
            ),
            TextField(
              controller: _supportUrlController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Support URL',
              ),
            ),
            TextField(
              controller: _aadharNoController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Aadhar Number',
              ),
            ),
            TextField(
              controller: _aadharImageUrlController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Aadhar Image URL',
              ),
            ),
            TextField(
              controller: _joiningDateController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Joining Date',
                errorText: _validationErrors['joiningDate'],
              ),
            ),
            TextField(
              controller: _employeeIdController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Employee ID',
                errorText: _validationErrors['employeeId'],
              ),
            ),
            TextField(
              controller: _bankNameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Bank Name',
                errorText: _validationErrors['bankName'],
              ),
            ),
            TextField(
              controller: _accountNumberController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Account Number',
                errorText: _validationErrors['accountNumber'],
              ),
            ),
            TextField(
              controller: _ifscCodeController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'IFSC Code',
                errorText: _validationErrors['ifscCode'],
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              onChanged: _isEditing ? (value) => setState(() => _selectedDepartment = value!) : null,
              items: <String>['Department 1', 'Department 2', 'Department 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Department',
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedDesignation,
              onChanged: _isEditing ? (value) => setState(() => _selectedDesignation = value!) : null,
              items: <String>['Designation 1', 'Designation 2', 'Designation 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Designation',
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              onChanged: _isEditing ? (value) => setState(() => _selectedLocation = value!) : null,
              items: <String>['Location 1', 'Location 2', 'Location 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Location',
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              onChanged: _isEditing ? (value) => setState(() => _selectedStatus = value!) : null,
              items: <String>['Status 1', 'Status 2', 'Status 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Status',
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              onChanged: _isEditing ? (value) => setState(() => _selectedRole = value!) : null,
              items: <String>['Role 1', 'Role 2', 'Role 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Role',
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedEmployeeType,
              onChanged: _isEditing ? (value) => setState(() => _selectedEmployeeType = value!) : null,
              items: <String>['Employee Type 1', 'Employee Type 2', 'Employee Type 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Employee Type',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        if (_isEditing)
          TextButton(
            onPressed: _updateEmployeeData,
            child: Text('Save'),
          ),
        if (!_isEditing)
          TextButton(
            onPressed: () => setState(() => _isEditing = true),
            child: Text('Edit'),
          ),
      ],
    );
  }
}
