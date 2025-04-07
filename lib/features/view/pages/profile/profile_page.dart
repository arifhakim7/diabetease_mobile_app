import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fyp_diabetease/features/view/pages/profile/recipe_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? username;
  File? _imageFile;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        var userData = userSnapshot.data() as Map<String, dynamic>;
        var userName = userData['username'];
        var profileImageUrl = userData['profileImageUrl'];
        setState(() {
          username = userName;
          _profileImageUrl = profileImageUrl;
        });
      } else {
        print("User data not found for the current user.");
      }
    } catch (e) {
      print("Error retrieving user profile: $e");
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile =
          await imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // Upload image to Firebase Storage
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageReference =
            _storage.ref().child('profile_pictures/$fileName');
        UploadTask uploadTask = storageReference.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore with the new profile image URL
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          await _firestore.collection('users').doc(currentUser.uid).update({
            'profileImageUrl': downloadUrl,
          });

          setState(() {
            _profileImageUrl = downloadUrl;
          });
        }
      }
    } catch (e) {
      print("Error uploading profile picture: $e");
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('login_page');
  }

  Future<int> getFollowingCount() async {
    try {
      DocumentSnapshot userSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userSnapshot.exists) {
        List<dynamic> followingList = userSnapshot['followingUser'] ?? [];
        return followingList.length;
      } else {
        print("User document does not exist.");
        return 0;
      }
    } catch (e) {
      print("Error fetching following count: $e");
      return 0;
    }
  }

  Future<int> getFollowersCount() async {
    try {
      DocumentSnapshot userSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userSnapshot.exists) {
        List<dynamic> followersList = userSnapshot['followedByUser'] ?? [];
        return followersList.length;
      } else {
        print("User document does not exist.");
        return 0;
      }
    } catch (e) {
      print("Error fetching followers count: $e");
      return 0;
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _logout(); // Call the logout function
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshProfile() async {
    await _fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile Page'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: false,
        titleTextStyle: const TextStyle(fontSize: 20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('main_layout');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile, // Method to refresh the profile
        child: StreamBuilder(
          stream: _firestore
              .collection('recipes')
              .where('userId', isEqualTo: currentUser.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var recipes = snapshot.data!.docs;

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile card with Edit Profile and Logout buttons
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _uploadProfilePicture,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: _profileImageUrl == null
                                ? const Icon(
                                    Icons
                                        .person, // Use the profile icon from Material Icons
                                    size:
                                        50, // Adjust the size to fit within the CircleAvatar
                                    color: Colors
                                        .grey, // Optional: Set a color for the icon
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            username ?? 'Username',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Row for posts, following, and followers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${recipes.length}', // Number of posts
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Posts'),
                              ],
                            ),
                            Column(
                              children: [
                                FutureBuilder<int>(
                                  future: getFollowersCount(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.grey),
                                      );
                                    }
                                    return Text(
                                      '${snapshot.data ?? 0}', // Number of followers
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const Text('Followers'),
                              ],
                            ),
                            Column(
                              children: [
                                FutureBuilder<int>(
                                  future: getFollowingCount(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.grey),
                                      );
                                    }
                                    return Text(
                                      '${snapshot.data ?? 0}', // Number of following
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const Text('Following'),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, 'edit_profile_page');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate dynamic childAspectRatio based on screen size
                        double itemWidth = (constraints.maxWidth - 20) /
                            2; // Adjust for spacing
                        double itemHeight =
                            itemWidth / 0.75; // Maintain 0.75 aspect ratio
                        double childAspectRatio = itemWidth / itemHeight;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              recipes.length + 1, // Add 1 for the '+' card
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            if (index == recipes.length) {
                              // The '+' button card
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                      context, 'upload_recipe_page');
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  elevation: 4,
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }

                            var recipe = recipes[index];
                            var recipeData =
                                recipe.data() as Map<String, dynamic>?;

                            var recipeName =
                                recipeData?['recipeName'] ?? 'No Recipe Name';
                            var imageUrl = recipeData?['imageUrl'] ?? '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RecipeDetailPage(recipe: recipe),
                                  ),
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                elevation: 4,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Display recipe image or placeholder
                                    if (imageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(16.0)),
                                        child: Image.network(
                                          imageUrl,
                                          height: itemHeight *
                                              0.6, // Adjust height dynamically
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Container(
                                        height: itemHeight * 0.6,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(16.0),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        recipeName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
