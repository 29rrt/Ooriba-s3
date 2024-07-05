import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/registered_service.dart';
import 'services/reject_service.dart';
import 'employee_id_generator.dart';
import 'services/accept_mail_service.dart';
// import 'package:emailjs/emailjs.dart';
// import 'package:sms_advanced/sms_advanced.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final Map<String, dynamic> employeeData;

  EmployeeDetailsPage({required this.employeeData});

  @override
  _EmployeeDetailsPageState createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  late Map<String, dynamic> employeeData;
  bool isEditing = false;
  bool isAccepted = false;
  final RegisteredService _registeredService = RegisteredService();
  final RejectService _rejectService = RejectService();
  final _formKey = GlobalKey<FormState>();
  final EmployeeIdGenerator _idGenerator = EmployeeIdGenerator();
  TextEditingController _joiningDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    employeeData = Map<String, dynamic>.from(widget.employeeData);
    _joiningDateController.text = employeeData['joiningDate'] ?? '';

    // Format dob to dd/mm/yyyy if it exists
    if (employeeData['dob'] != null && employeeData['dob'].isNotEmpty) {
      final parts = employeeData['dob'].split('/');
      final formattedDob =
          '${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[2]}';
      employeeData['dob'] = formattedDob;
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Generate a new employee ID
        final employeeId = await _idGenerator.generateEmployeeId();
        employeeData['employeeId'] = employeeId;

        print('Saving data: ${employeeData['email']} -> $employeeData');
        await FirebaseFirestore.instance
            .collection('Regemp')
            .doc(employeeData['email'])
            .set(employeeData);

        // Delete the employee from the "Employee" collection
        await FirebaseFirestore.instance
            .collection('Employee')
            .doc(employeeData['email'])
            .delete();

        // Send SMS
        // SmsSender sender = SmsSender();
        // String phoneNumber = employeeData['phoneNo'];
        // String message =
        //     'Your employee details have been saved successfully. Your employee ID is $employeeId.';
        // SmsMessage smsMessage = SmsMessage(phoneNumber, message);
        // smsMessage.onStateChanged.listen((state) {
        //   if (state == SmsMessageState.Sent) {
        //     print("SMS is sent!");
        //   } else if (state == SmsMessageState.Delivered) {
        //     print("SMS is delivered!");
        //   } else if (state == SmsMessageState.Fail) {
        //     print("Failed to send SMS.");
        //   }
        // });
        // sender.sendSms(smsMessage);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Employee details updated, deleted from the Employee collection, and email sent successfully')),
        );
        setState(() {
          isEditing = false;
        });
      } catch (e) {
        print('Error saving employee data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update employee details: $e')),
        );
      }
    }
  }

  final AcceptMailService _acceptMailService = AcceptMailService();
  Future<void> _acceptDetails() async {
    setState(() {
      isAccepted = true;
      isEditing = true;
      employeeData['status'] = 'Active';
      employeeData['role'] = 'Standard';
    });

    try {
      // Save user to Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: employeeData['email'], password: employeeData['password']);
      User? user = userCredential.user;

      if (user != null) {
        user.updateProfile(displayName: employeeData['firstName']);
        // user.sendEmailVerification();
      }

      // Send acceptance email using EmailJS
      await _acceptMailService.sendAcceptanceEmail(employeeData['email']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Employee added to authentication and acceptance email sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to add employee to authentication or send acceptance email: $e')),
      );
    }
  }

  Future<void> _showRejectPopup() async {
    String? reason;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must fill the reason and press a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reject Reason'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                  'Please provide a reason for rejecting the employee details:'),
              TextField(
                onChanged: (value) {
                  reason = value;
                },
                decoration: InputDecoration(
                  labelText: 'Reason',
                  errorText: reason == null || reason!.isEmpty
                      ? 'Reason is required'
                      : null,
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () async {
                if (reason != null && reason!.isNotEmpty) {
                  try {
                    await _rejectService.rejectEmployee(employeeData, reason!);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Employee details rejected and saved successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Failed to reject employee details: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _rejectChanges() async {
    await _showRejectPopup();
    setState(() {
      isEditing = false;
      employeeData = Map<String, dynamic>.from(widget.employeeData);
    });
    print('Changes rejected');
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateAadharNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required';
    }
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return 'Enter a valid 12-digit Aadhar number';
    }
    return null;
  }

  String? _validatePanNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number is required';
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
      return 'Enter a valid PAN number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'minimum length 6';
    }
    if (!RegExp(
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
        .hasMatch(value)) {
      return 'uppercase,lowercase,num,special character.';
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }

    // Validate format dd/mm/yyyy
    final dateFormat = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateFormat.hasMatch(value)) {
      return 'Enter a valid date format (dd/mm/yyyy)';
    }

    try {
      // Convert to DateTime
      final parts = value.split('/');
      final dob = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      // Validate age
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }

      if (age < 18) {
        return 'Age must be at least 18 years';
      }
    } catch (e) {
      return 'Invalid date';
    }

    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = employeeData['joiningDate'] != null
        ? DateTime.parse(employeeData['joiningDate'])
        : DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        _joiningDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
        employeeData['joiningDate'] = _joiningDateController.text;
      });
    }
  }

  Widget _buildDetailRow(String label, String key,
      {bool isNumber = false,
      bool isEmail = false,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 150,
            child: Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isEditing
                ? TextFormField(
                    initialValue: employeeData[key] ?? '',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        isNumber ? TextInputType.number : TextInputType.text,
                    onChanged: (value) {
                      employeeData[key] = value;
                    },
                    validator: validator,
                  )
                : Text(employeeData[key] ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 150,
            child: Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isEditing
                ? GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _joiningDateController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: _validateDateOfBirth,
                      ),
                    ),
                  )
                : Text(employeeData[key] ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Password: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: isEditing
                ? TextFormField(
                    initialValue: employeeData['password'],
                    onChanged: (newValue) {
                      setState(() {
                        employeeData['password'] = newValue;
                      });
                    },
                    obscureText: true,
                    validator: _validatePassword,
                  )
                : Text(employeeData['password'] != null
                    ? '********'
                    : 'N/A'), // Mask the password
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 150,
            child: Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            width: 100, // Fixed width
            height: 100, // Fixed height
            child: employeeData[key] != null
                ? FadeInImage.assetNetwork(
                    placeholder:
                        'assets/placeholder_image.png', // Placeholder image asset path
                    image: employeeData[key], // Image URL from employeeData
                    fit: BoxFit.cover,
                  )
                : Text('N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 150,
            child: Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: employeeData[key] != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () async {
                        final url = employeeData[key];
                        await _launchURL(url);
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        minimumSize: Size(60, 40), // Adjust the size as needed
                      ),
                      child: Text('Download'),
                    ),
                  )
                : Text('N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, String key, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 150,
            child: Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isEditing
                ? DropdownButtonFormField<String>(
                    value: employeeData[key],
                    onChanged: (String? newValue) {
                      setState(() {
                        employeeData[key] = newValue!;
                      });
                    },
                    items:
                        options.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    validator: (value) {
                      // Remove mandatory validation for dropdowns
                      return null;
                    },
                  )
                : Text(employeeData[key] ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Column(children: children),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop(); // Close the details page
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            _buildCategory(
              'Personal Information',
              [
                _buildDetailRow('First Name', 'firstName', validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                }),
                _buildDetailRow('Middle Name', 'middleName'),
                _buildDetailRow('Last Name', 'lastName', validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                }),
                _buildDetailRow('Email', 'email',
                    isEmail: true, validator: _validateEmail),
                _buildDetailRow('Phone Number', 'phoneNo',
                    isNumber: true, validator: _validatePhoneNumber),
                _buildDetailRow('Date of Birth', 'dob',
                    validator: _validateDateOfBirth),
                _buildDetailRow('Permanent Address', 'permanentAddress',
                    validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Permanent address is required';
                  }
                  return null;
                }),
                _buildDetailRow('Residential Address', 'residentialAddress',
                    validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Residential address is required';
                  }
                  return null;
                }),
                _buildDetailRow('Aadhar Number', 'aadharNo',
                    validator: _validateAadharNumber),
                _buildDetailRow('PAN Number', 'panNo',
                    validator: _validatePanNumber),
                _buildImageRow('Profile Picture', 'dpImageUrl'),
                _buildAttachmentRow('Aadhar Doc', 'adhaarImageUrl'),
                _buildAttachmentRow('Support Doc', 'supportImageUrl'),
              ],
            ),
            _buildCategory('Job Description', [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 150,
                      child: Text(
                        'Joining Date*: ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                    Expanded(
                      child: isEditing
                          ? TextFormField(
                              controller: _joiningDateController,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Joining date is required';
                                }
                                return null;
                              },
                            )
                          : Text(
                              employeeData['joiningDate'] ?? 'N/A',
                              style: TextStyle(color: Colors.black87),
                            ),
                    ),
                  ],
                ),
              ),
              _buildDropdownRow('Department', 'department', [
                'Sales',
                'Services',
                'Spares',
                'Administration',
                'Board of Directors'
              ]),
              _buildDropdownRow('Designation', 'designation', [
                'Manager',
                'Senior Engineer',
                'Junior Engineer',
                'Technician',
                'Executive'
              ]),
              _buildDropdownRow(
                  'Employee Type', 'employeeType', ['On-site', 'Off-site']),
              _buildDropdownRow(
                  'Location', 'location', ['Jeypore', 'Berhampur', 'Raigada']),
            ]),
            _buildCategory('Bank Details', [
              _buildDetailRow('Bank Name', 'bankName'),
              _buildDetailRow('Account Number', 'accountNumber',
                  isNumber: true),
              _buildDetailRow('IFSC Code', 'ifscCode'),
            ]),
            _buildCategory('Employee Status', [
              _buildDropdownRow('Status', 'status', [
                'Active',
                'Inactive',
                'On Hold',
              ]),
              _buildDropdownRow('Role', 'role', ['Standard', 'HR']),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: _rejectChanges,
              child: Text('Reject'),
            ),
            SizedBox(width: 10.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: isAccepted
                  ? (isEditing ? _saveDetails : _toggleEdit)
                  : _acceptDetails,
              child:
                  Text(isAccepted ? (isEditing ? 'Save' : 'Edit') : 'Accept'),
            ),
          ],
        ),
      ),
    );
  }
}