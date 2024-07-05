import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' as io;
import 'package:universal_io/io.dart';
import 'employee_signup_success.dart';
import 'services/employeeService.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _dob;
  final _phoneNumber = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _panNo = TextEditingController();
  final _residentialAddress = TextEditingController();
  final _permanentAddress = TextEditingController();
  final _password = TextEditingController();
  final _aadharNo = TextEditingController();
  io.File? dpImage, supportImage, adhaarImage;
  String? dpImagePath, supportImagePath, adhaarImagePath;
  final EmployeeService _employeeService = EmployeeService();

  Future<void> _pickImage(int x) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (x == 2) {
          dpImage = io.File(pickedFile.path);
          dpImagePath = pickedFile.path;
        }
        if (x == 1) {
          adhaarImage = io.File(pickedFile.path);
          adhaarImagePath = pickedFile.path;
        }
        if (x == 3) {
          supportImage = io.File(pickedFile.path);
          supportImagePath = pickedFile.path;
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final firstName = _firstName.text;
      final middleName = _middleName.text;
      final lastName = _lastName.text;
      final email = _email.text;
      final password = _password.text;
      var panNo = _panNo.text;
      final resAdd = _residentialAddress.text;
      final perAdd = _permanentAddress.text;
      final phoneNo = _phoneNumber.text;
      final dob = DateFormat('dd/MM/yyyy').format(_dob!);
      var aadharNo = _aadharNo.text
          .replaceAll(' ', ''); // Remove spaces from Aadhaar number

      // Convert PAN number to uppercase
      panNo = panNo.toUpperCase();

      // Ensure all images are selected
      if (dpImage == null || adhaarImage == null || supportImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload all required images')),
        );
        return;
      }

      try {
        // Add employee data to Firestore
        await _employeeService.addEmployee(
          firstName,
          middleName,
          lastName,
          email,
          password,
          panNo,
          resAdd,
          perAdd,
          phoneNo,
          dob,
          aadharNo,
          dpImage!,
          adhaarImage!,
          supportImage!,
          context: context,
        );

        // Send sign up email
        // await SignUpEmailService().sendSignUpEmail(email);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed up successfully')),
        );
         Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ConfirmationPage()));
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign up: $e')),
        );
      }
    }
  }

  Widget _displayImage(io.File? imageFile, String? imagePath) {
    if (imageFile != null) {
      return Image.file(imageFile);
    } else if (imagePath != null && Uri.parse(imagePath).isAbsolute) {
      return Image.network(imagePath);
    } else {
      return const Text('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400, // Limit the width for larger screens
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Sign Up',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          if (value.length > 50) {
                            return 'First name cannot exceed 50 characters';
                          }
                          if (RegExp(r'[^a-zA-Z.\s]').hasMatch(value)) {
                            return 'First name can only contain letters and dot(.)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _middleName,
                        decoration: const InputDecoration(
                          labelText: 'Middle Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value!.length > 50) {
                            return 'Middle name cannot exceed 50 characters';
                          }
                          if (RegExp(r'[^a-zA-Z.\s]').hasMatch(value)) {
                            return 'Middle name can only contain letters and dot(.)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          if (value.length > 50) {
                            return 'Last name cannot exceed 50 characters';
                          }
                          if (RegExp(r'[^a-zA-Z.\s]').hasMatch(value)) {
                            return 'Last name can only contain letters and dot(.)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                                  r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _password,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!RegExp(
                                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$')
                              .hasMatch(value)) {
                            return 'should contain uppercase,number,special character';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _panNo,
                        decoration: const InputDecoration(
                          labelText: 'PAN Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your PAN number';
                          }
                          if (value.length != 10) {
                            return 'PAN number must be exactly 10 characters';
                          }
                          if (RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
                            return 'PAN number can only contain letters and digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _aadharNo,
                        decoration: const InputDecoration(
                          labelText: 'Aadhaar Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Aadhaar number';
                          }
                          if (value.length != 12 &&
                              value.replaceAll(' ', '').length != 12) {
                            return 'Aadhaar number must be exactly 12 digits';
                          }
                          if (RegExp(r'[^0-9\s]').hasMatch(value)) {
                            return 'Aadhaar number can only contain digits and spaces';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _dob = picked;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: _dob == null
                                  ? 'Date of Birth'
                                  : DateFormat('dd/MM/yyyy').format(_dob!),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_dob == null) {
                                return 'Please select your date of birth';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _residentialAddress,
                        decoration: const InputDecoration(
                          labelText: 'Residential Address',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your residential address';
                          }
                          if (value.length > 100) {
                            return 'Address cannot exceed 100 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _permanentAddress,
                        decoration: const InputDecoration(
                          labelText: 'Permanent Address',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your permanent address';
                          }
                          if (value.length > 100) {
                            return 'Address cannot exceed 100 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneNumber,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return 'Phone number must be exactly 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _pickImage(2),
                        child: const Text('Upload Profile Picture'),
                      ),
                      const SizedBox(height: 10),
                      _displayImage(dpImage, dpImagePath),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _pickImage(1),
                        child: const Text('Upload Aadhaar Doc'),
                      ),
                      const SizedBox(height: 10),
                      _displayImage(adhaarImage, adhaarImagePath),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _pickImage(3),
                        child: const Text('Upload Supporting Doc'),
                      ),
                      const SizedBox(height: 10),
                      _displayImage(supportImage, supportImagePath),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
