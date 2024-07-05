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

    bool isValid = true;
    _validationErrors.clear();

    if (firstName.isEmpty) {
      _validationErrors['firstName'] = 'First name is required';
      isValid = false;
    }

    if (lastName.isEmpty) {
      _validationErrors['lastName'] = 'Last name is required';
      isValid = false;
    }

    if (phone.isEmpty) {
      _validationErrors['phone'] = 'Phone number is required';
      isValid = false;
    }

    if (email.isEmpty) {
      _validationErrors['email'] = 'Email is required';
      isValid = false;
    }

    if (panNo.isEmpty) {
      _validationErrors['panNo'] = 'PAN number is required';
      isValid = false;
    }

    if (password.isEmpty) {
      _validationErrors['password'] = 'Password is required';
      isValid = false;
    }

    if (permanentAddress.isEmpty) {
      _validationErrors['permanentAddress'] = 'Permanent address is required';
      isValid = false;
    }

    if (residentialAddress.isEmpty) {
      _validationErrors['residentialAddress'] = 'Residential address is required';
      isValid = false;
    }

    if (dob.isEmpty) {
      _validationErrors['dob'] = 'Date of birth is required';
      isValid = false;
    }

    if (dpImageUrl.isEmpty) {
      _validationErrors['dpImageUrl'] = 'Display picture URL is required';
      isValid = false;
    }

    if (supportUrl.isEmpty) {
      _validationErrors['supportUrl'] = 'Support URL is required';
      isValid = false;
    }

    if (aadharNo.isEmpty) {
      _validationErrors['aadharNo'] = 'Aadhar number is required';
      isValid = false;
    }

    if (aadharImageUrl.isEmpty) {
      _validationErrors['aadharImageUrl'] = 'Aadhar image URL is required';
      isValid = false;
    }

    if (joiningDate.isEmpty) {
      _validationErrors['joiningDate'] = 'Joining date is required';
      isValid = false;
    }

    if (employeeId.isEmpty) {
      _validationErrors['employeeId'] = 'Employee ID is required';
      isValid = false;
    }

    if (bankName.isEmpty) {
      _validationErrors['bankName'] = 'Bank name is required';
      isValid = false;
    }

    if (accountNumber.isEmpty) {
      _validationErrors['accountNumber'] = 'Account number is required';
      isValid = false;
    }

    if (ifscCode.isEmpty) {
      _validationErrors['ifscCode'] = 'IFSC code is required';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Employee Details',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              _buildTextField(
                labelText: 'First Name',
                controller: _firstNameController,
                errorText: _validationErrors['firstName'],
              ),
              _buildTextField(
                labelText: 'Last Name',
                controller: _lastNameController,
                errorText: _validationErrors['lastName'],
              ),
              _buildTextField(
                labelText: 'Phone',
                controller: _phoneController,
                errorText: _validationErrors['phone'],
              ),
              _buildTextField(
                labelText: 'Email',
                controller: _emailController,
                errorText: _validationErrors['email'],
              ),
              _buildTextField(
                labelText: 'PAN No',
                controller: _panController,
                errorText: _validationErrors['panNo'],
              ),
              _buildTextField(
                labelText: 'Password',
                controller: _passwordController,
                errorText: _validationErrors['password'],
              ),
              _buildTextField(
                labelText: 'Permanent Address',
                controller: _permanentAddressController,
                errorText: _validationErrors['permanentAddress'],
              ),
              _buildTextField(
                labelText: 'Residential Address',
                controller: _residentialAddressController,
                errorText: _validationErrors['residentialAddress'],
              ),
              _buildTextField(
                labelText: 'Date of Birth',
                controller: _dobController,
                errorText: _validationErrors['dob'],
              ),
              _buildTextField(
                labelText: 'Display Picture URL',
                controller: _dpImageUrlController,
                errorText: _validationErrors['dpImageUrl'],
              ),
              _buildTextField(
                labelText: 'Support URL',
                controller: _supportUrlController,
                errorText: _validationErrors['supportUrl'],
              ),
              _buildTextField(
                labelText: 'Aadhar No',
                controller: _aadharNoController,
                errorText: _validationErrors['aadharNo'],
              ),
              _buildTextField(
                labelText: 'Aadhar Image URL',
                controller: _aadharImageUrlController,
                errorText: _validationErrors['aadharImageUrl'],
              ),
              _buildTextField(
                labelText: 'Joining Date',
                controller: _joiningDateController,
                errorText: _validationErrors['joiningDate'],
              ),
              _buildTextField(
                labelText: 'Employee ID',
                controller: _employeeIdController,
                errorText: _validationErrors['employeeId'],
              ),
              _buildTextField(
                labelText: 'Bank Name',
                controller: _bankNameController,
                errorText: _validationErrors['bankName'],
              ),
              _buildTextField(
                labelText: 'Account Number',
                controller: _accountNumberController,
                errorText: _validationErrors['accountNumber'],
              ),
              _buildTextField(
                labelText: 'IFSC Code',
                controller: _ifscCodeController,
                errorText: _validationErrors['ifscCode'],
              ),
              SizedBox(height: 16.0),
              _isEditing
                  ? Column(
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            if (_validateInputs()) {
                              // Save data to Firestore here
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text('Save'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                            });
                          },
                          child: Text('Cancel'),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: Text('Edit'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required TextEditingController controller,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          errorText: errorText,
        ),
      ),
    );
  }
}
