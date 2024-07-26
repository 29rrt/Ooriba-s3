import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ooriba_s3/employee_id_generator.dart';
import 'package:ooriba_s3/services/accept_mail_service.dart';
import 'package:ooriba_s3/services/registered_service.dart';
import 'package:ooriba_s3/services/reject_service.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Dropdown options
  List<String> departmentOptions = [
    'Sales',
    'Services',
    'Spares',
    'Administration',
    'Board of Directors'
  ];
  List<String> designationOptions = [
    'Manager',
    'Senior Engineer',
    'Junior Engineer',
    'Technician',
    'Executive'
  ];
  List<String> employeeTypeOptions = ['On-site', 'Off-site'];
  List<String> locationOptions = ['Jeypore', 'Berhampur', 'Raigada'];
  List<String> statusOptions = ['Active', 'Inactive', 'On Hold'];
  List<String> roleOptions = ['Standard', 'HR'];

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
        // Ensure location is provided in employeeData
        String location = employeeData['location'];
        if (location == null || location.isEmpty) {
          throw Exception('Location is required to generate an employee ID');
        }

        // Generate a new employee ID
        final employeeId = await _idGenerator.generateEmployeeId(location);
        employeeData['employeeId'] = employeeId;

        print('Saving data: ${employeeData['email']} -> $employeeData');
        await FirebaseFirestore.instance
            .collection('Regemp')
            .doc(employeeData['phoneNo'])
            .set(employeeData);

        // Delete the employee from the "Employee" collection
        await FirebaseFirestore.instance
            .collection('Employee')
            .doc(employeeData['phoneNo'])
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
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
              ),
              child: Text('Reject'),
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
      return 'minimum length 6 characters';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        employeeData['dob'] =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _deleteEmployee() async {
    try {
      await FirebaseFirestore.instance
          .collection('Regemp')
          .doc(employeeData['email'])
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Employee deleted successfully')),
      );
      Navigator.pop(context); // Return to the previous screen after deletion
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete employee: $e')),
      );
    }
  }

  void _addDropdownOption(List<String> options, String newOption) {
    setState(() {
      if (newOption.isNotEmpty && !options.contains(newOption)) {
        options.add(newOption);
      }
    });
  }

  void _deleteDropdownOption(List<String> options, String optionToDelete) {
    setState(() {
      if (options.contains(optionToDelete)) {
        options.remove(optionToDelete);
      }
    });
  }

  Widget _buildDropdownRow(
      String labelText, String selectedValue, List<String> options) {
    return Row(
      children: [
        Expanded(
          flex: 8,
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            onChanged: isEditing
                ? (newValue) {
                    setState(() {
                      selectedValue = newValue!;
                      employeeData[labelText.toLowerCase()] = newValue;
                    });
                  }
                : null,
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            decoration: InputDecoration(
              labelText: labelText,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        if (isEditing)
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddOptionDialog(labelText, options);
            },
          ),
        if (isEditing)
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _showDeleteOptionDialog(labelText, options);
            },
          ),
      ],
    );
  }

  void _showAddOptionDialog(String labelText, List<String> options) {
    String newOption = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add $labelText Option'),
          content: TextField(
            onChanged: (value) {
              newOption = value;
            },
            decoration: InputDecoration(
              labelText: 'New $labelText Option',
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () {
                _addDropdownOption(options, newOption);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteOptionDialog(String labelText, List<String> options) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete $labelText Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return ListTile(
                title: Text(option),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteDropdownOption(options, option);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Details'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveDetails,
            ),
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _toggleEdit,
            ),
          if (isAccepted)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _acceptDetails,
            ),
          if (!isAccepted)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteEmployee,
            ),
          if (!isAccepted)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _rejectChanges,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: employeeData['email'],
                decoration: InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
                onSaved: (value) {
                  employeeData['email'] = value!;
                },
                enabled: isEditing,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                initialValue: employeeData['phoneNo'],
                decoration: InputDecoration(labelText: 'Phone Number'),
                validator: _validatePhoneNumber,
                onSaved: (value) {
                  employeeData['phoneNo'] = value!;
                },
                enabled: isEditing,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                initialValue: employeeData['aadharNo'],
                decoration: InputDecoration(labelText: 'Aadhar Number'),
                validator: _validateAadharNumber,
                onSaved: (value) {
                  employeeData['aadharNo'] = value!;
                },
                enabled: isEditing,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                initialValue: employeeData['panNo'],
                decoration: InputDecoration(labelText: 'PAN Number'),
                validator: _validatePanNumber,
                onSaved: (value) {
                  employeeData['panNo'] = value!;
                },
                enabled: isEditing,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                initialValue: employeeData['password'],
                decoration: InputDecoration(labelText: 'Password'),
                validator: _validatePassword,
                onSaved: (value) {
                  employeeData['password'] = value!;
                },
                enabled: isEditing,
                obscureText: true,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                initialValue: employeeData['dob'],
                decoration: InputDecoration(labelText: 'Date of Birth'),
                onTap: () {
                  _selectDate(context);
                },
                readOnly: true,
                enabled: isEditing,
              ),
              SizedBox(height: 16.0),
              _buildDropdownRow(
                'Department',
                employeeData['department'] ?? departmentOptions[0],
                departmentOptions,
              ),
              SizedBox(height: 16.0),
              _buildDropdownRow(
                'Designation',
                employeeData['designation'] ?? designationOptions[0],
                designationOptions,
              ),
              SizedBox(height: 16.0),
              _buildDropdownRow(
                'Employee Type',
                employeeData['employeeType'] ?? employeeTypeOptions[0],
                employeeTypeOptions,
              ),
              SizedBox(height: 16.0),
              _buildDropdownRow(
                'Location',
                employeeData['location'] ?? locationOptions[0],
                locationOptions,
              ),
              SizedBox(height: 16.0),
              _buildDropdownRow(
                'Status',
                employeeData['status'] ?? statusOptions[0],
                statusOptions,
              ),
              SizedBox(height: 16.0),
              _buildDropdownRow(
                'Role',
                employeeData['role'] ?? roleOptions[0],
                roleOptions,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _joiningDateController,
                decoration: InputDecoration(labelText: 'Joining Date'),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _joiningDateController.text =
                          '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                      employeeData['joiningDate'] = _joiningDateController.text;
                    });
                  }
                },
                readOnly: true,
                enabled: isEditing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
