import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_diabetease/features/view/widgets/form_container_widget.dart';
import 'package:fyp_diabetease/features/view/widgets/dropdown_menu_widget.dart';
import 'package:intl/intl.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _selectedGender = "Male";
  String _selectedDiabetesType = "No Diabetes"; // Default diabetes type
  DateTime? _selectedDateOfBirth;
  bool _isUsernameTaken = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    try {
      QuerySnapshot existingUsers = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        throw Exception("Username already exists. Please choose another one.");
      }
    } catch (e) {
      // Handle any errors (like network issues)
      setState(() {
        _isUsernameTaken = true;
      });
      print("Error checking username: $e");
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Check if the username already exists in Firestore
        QuerySnapshot existingUsers = await _firestore
            .collection('users')
            .where('username', isEqualTo: _usernameController.text.trim())
            .get();

        if (existingUsers.docs.isNotEmpty) {
          // Show an error if the username is taken
          print("Username already exists. Please choose another one.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Username already exists. Please choose another one."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        QuerySnapshot existingEmails = await _firestore
            .collection('users')
            .where('email', isEqualTo: _emailController.text.trim())
            .get();

        if (existingEmails.docs.isNotEmpty) {
          // Show snackbar if the email is taken
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Email is already taken. Please use another one."),
              backgroundColor: Colors.red,
            ),
          );
          return; // Exit the function early
        }

        // If username is unique, create user
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        User? user = userCredential.user;

        if (user != null) {
          // Add user details to Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'dateOfBirth': _selectedDateOfBirth?.toIso8601String(),
            'height': double.parse(_heightController.text.trim()),
            'weight': double.parse(_weightController.text.trim()),
            'gender': _selectedGender,
            'diabetesType': _selectedDiabetesType,
          });

          // Navigate to main layout after successful sign-up
          Navigator.pushReplacementNamed(context, 'main_layout');
        }
      } catch (e) {
        print("An error occurred: $e");
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 30),
                  FormContainerWidget(
                    hintText: "Username",
                    isPasswordField: false,
                    controller: _usernameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a username.";
                      }
                      if (value.length < 3) {
                        return "Username must be at least 3 characters.";
                      }
                      if (_isUsernameTaken) {
                        return "Username already exists. Please choose another one.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  FormContainerWidget(
                    hintText: "Email",
                    isPasswordField: false,
                    inputType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter an email.";
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Please enter a valid email address.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  FormContainerWidget(
                    hintText: "Password",
                    isPasswordField: true,
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a password.";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Date of Birth",
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) {
                          if (_selectedDateOfBirth == null) {
                            return "Please select your date of birth.";
                          }
                          return null;
                        },
                        controller: TextEditingController(
                          text: _selectedDateOfBirth != null
                              ? DateFormat('yyyy-MM-dd')
                                  .format(_selectedDateOfBirth!)
                              : '',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  FormContainerWidget(
                    hintText: "Height (cm)",
                    isPasswordField: false,
                    inputType: TextInputType.number,
                    controller: _heightController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your height.";
                      }
                      if (double.tryParse(value) == null) {
                        return "Please enter a valid number.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  FormContainerWidget(
                    hintText: "Weight (kg)",
                    isPasswordField: false,
                    inputType: TextInputType.number,
                    controller: _weightController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your weight.";
                      }
                      if (double.tryParse(value) == null) {
                        return "Please enter a valid number.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownFormField(
                    hintText: "Gender",
                    value: _selectedGender,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue!;
                      });
                    },
                    items: ["Male", "Female"],
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Diabetes Type:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  DropdownFormField(
                    hintText: "Diabetes Type",
                    value: _selectedDiabetesType,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDiabetesType = newValue!;
                      });
                    },
                    items: [
                      "No Diabetes",
                      "Type 1",
                      "Type 2",
                      "Gestational",
                      "Other"
                    ],
                  ),
                  SizedBox(height: 30),
                  GestureDetector(
                    onTap: _signUp,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
