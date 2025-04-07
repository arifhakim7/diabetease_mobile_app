import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String? username;
  DateTime? _dateOfBirth;
  String? _height;
  String? _weight;
  String? _gender;
  String? _diabetesType;
  bool _isUsernameTaken = false;
  bool _isLoading = false;

  final List<String> _diabetesTypes = [
    'No Diabetes',
    'Type 1',
    'Type 2',
    'Gestational',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        var userData = userSnapshot.data() as Map<String, dynamic>;
        setState(() {
          username = userData['username'];
          _dateOfBirth = (userData['dateOfBirth'] as Timestamp).toDate();
          _height = userData['height'];
          _weight = userData['weight'];
          _gender = userData['gender'];
          _diabetesType = userData['diabetesType'];
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if the username is taken
      QuerySnapshot existingUsers = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        setState(() {
          _isUsernameTaken = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Username already exists. Please choose another one."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save user data if username is available
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      await _firestore.collection('users').doc(currentUser.uid).update({
        'username': username,
        'dateOfBirth': _dateOfBirth,
        'height': _height,
        'weight': _weight,
        'gender': _gender,
        'diabetesType': _diabetesType,
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: const Text('Your profile has been updated successfully.'),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('profile_page');
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error saving user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dateOfBirth = pickedDate;
      });
    }
  }

  Future<void> _checkUsernameAvailability(String value) async {
    try {
      QuerySnapshot existingUsers = await _firestore
          .collection('users')
          .where('username', isEqualTo: value)
          .get();

      setState(() {
        _isUsernameTaken = existingUsers.docs.isNotEmpty;
      });
    } catch (e) {
      print("Error checking username: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context)
            .unfocus(); // Dismiss keyboard when tapping outside
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
        ),
        body: username == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        initialValue: username,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          errorText: _isUsernameTaken
                              ? 'Username is already taken'
                              : null,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter username'
                            : null,
                        onChanged: (value) {
                          username = value;
                          if (value.isNotEmpty) {
                            _checkUsernameAvailability(value);
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text: _dateOfBirth != null
                                  ? DateFormat('yyyy-MM-dd')
                                      .format(_dateOfBirth!)
                                  : '',
                            ),
                          ),
                        ),
                      ),
                      TextFormField(
                        initialValue: _height,
                        decoration:
                            const InputDecoration(labelText: 'Height (cm)'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter height'
                            : null,
                        onSaved: (value) => _height = value,
                      ),
                      TextFormField(
                        initialValue: _weight,
                        decoration:
                            const InputDecoration(labelText: 'Weight (kg)'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter weight'
                            : null,
                        onSaved: (value) => _weight = value,
                      ),
                      TextFormField(
                        initialValue: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter gender'
                            : null,
                        onSaved: (value) => _gender = value,
                      ),
                      DropdownButtonFormField<String>(
                        value: _diabetesType,
                        decoration:
                            const InputDecoration(labelText: 'Diabetes Type'),
                        items: _diabetesTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _diabetesType = value;
                          });
                        },
                        onSaved: (value) => _diabetesType = value,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveUserData,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
