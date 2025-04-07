import 'dart:async';
import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_diabetease/features/view/layout/mainLayout.dart';
import 'package:fyp_diabetease/features/view/pages/home/recipeGenerator.dart';
import 'package:fyp_diabetease/features/view/pages/search/search_recipe_details.dart';
import 'package:fyp_diabetease/features/view/pages/search/tag_recipe_details.dart';
import 'package:fyp_diabetease/features/view/pages/search/user_page.dart';
import 'package:http/http.dart' as http;

class home_page extends StatefulWidget {
  const home_page({super.key});

  @override
  State<home_page> createState() => _home_pageState();
}

class _home_pageState extends State<home_page> {
  String? _username;
  String? _profileImageUrl;
  String? _dailyTip1;
  String? _dailyTip2;
  String? _dailyTip3;

  final CollectionReference _recipesCollection =
      FirebaseFirestore.instance.collection('recipes');

  // To store the list of users the current user is following
  List<String> followingUsers = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _timer;
  List<Widget> get dailyTipWidgets {
    return [
      _dailyTip1 != null
          ? Text(_dailyTip1!)
          : const CircularProgressIndicator(),
      _dailyTip2 != null
          ? Text(_dailyTip2!)
          : const CircularProgressIndicator(),
      _dailyTip3 != null
          ? Text(_dailyTip3!)
          : const CircularProgressIndicator(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchFollowingUsers();
    _fetchDetails();
    _fetchDailyTip(1);
    _fetchDailyTip(2);
    _fetchDailyTip(3);
    _startDailyTipTimer(); // Start the timer to fetch tip every 24 hours
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Fetch user details from Firestore
  Future<void> _fetchDetails() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userSnapshot.exists) {
      setState(() {
        // Fetch and set username and profile image URL
        _username = (userSnapshot.data() as Map<String, dynamic>)['username'];
        _profileImageUrl =
            (userSnapshot.data() as Map<String, dynamic>)['profileImageUrl'];
      });
    } else {
      setState(() {
        // Set default values if user does not exist
        _username = "Guest";
        _profileImageUrl = ''; // No profile image for guest
      });
    }
  }

  // Fetch the username (you already have this, so just keeping it)
  Future<void> _fetchUsername() async {
    final currentUserId = FirebaseAuth
        .instance.currentUser!.uid; // Get current user ID directly here
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userSnapshot.exists) {
      setState(() {});
    }
  }

  // Fetch the list of users the current user is following
  Future<void> _fetchFollowingUsers() async {
    final currentUserId = FirebaseAuth
        .instance.currentUser!.uid; // Get current user ID directly here
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userSnapshot.exists) {
      final followingList =
          List<String>.from(userSnapshot['followingUser'] ?? []);
      setState(() {
        followingUsers = followingList;
      });
    }
  }

  // Fetch user details (same as before)
  Future<Map<String, dynamic>?> _fetchUserDetails(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      return userSnapshot.data() as Map<String, dynamic>;
    }
    return null;
  }

  // Fetch average rating for a recipe (same as before)
  Future<double> _calculateAverageRating(String recipeId) async {
    QuerySnapshot commentsSnapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('recipeId', isEqualTo: recipeId)
        .get();

    if (commentsSnapshot.docs.isNotEmpty) {
      double totalRating = commentsSnapshot.docs.fold(
        0,
        (sum, doc) => sum + (doc.data() as Map<String, dynamic>)['rating'],
      );
      return totalRating / commentsSnapshot.docs.length;
    }
    return 0.0;
  }

  Future<void> _fetchDailyTip(int tipIndex) async {
    const String apiKey = '';
    final url = Uri.parse('');

    String contextMessage;

    // Determine the context message based on the tipIndex
    switch (tipIndex) {
      case 1:
        contextMessage =
            'You are a doctor providing daily tips for maintaining blood sugar level.';
        break;
      case 2:
        contextMessage =
            'You are a doctor providing daily tips for balance diet for diabetes patient.';
        break;
      case 3:
        contextMessage =
            'You are a doctor providing daily tips for diabetes to stay hydrated.';
        break;
      default:
        contextMessage =
            'You are a doctor providing general tips for managing diabetes.';
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {
              'role': 'system',
              'content': contextMessage,
            },
            {
              'role': 'user',
              'content': 'Give a tip for diabetes management in one sentence.',
            }
          ],
          'max_tokens': 40,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          switch (tipIndex) {
            case 1:
              _dailyTip1 = data['choices'][0]['message']['content'].trim();
              break;
            case 2:
              _dailyTip2 = data['choices'][0]['message']['content'].trim();
              break;
            case 3:
              _dailyTip3 = data['choices'][0]['message']['content'].trim();
              break;
          }
        });
      } else {
        _setDailyTipError(tipIndex);
      }
    } catch (e) {
      _setDailyTipError(tipIndex);
    }
  }

  void _setDailyTipError(int tipIndex) {
    setState(() {
      final errorMessage = 'Sorry, we couldn\'t fetch the tip at the moment.';
      switch (tipIndex) {
        case 1:
          _dailyTip1 = errorMessage;
          break;
        case 2:
          _dailyTip2 = errorMessage;
          break;
        case 3:
          _dailyTip3 = errorMessage;
          break;
      }
    });
  }

  // Start the timer to fetch a new tip every 24 hours
  void _startDailyTipTimer() {
    _timer = Timer.periodic(const Duration(hours: 24), (timer) {
      _fetchDailyTip(1);
    });
  }

  // Sign out the user
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed(
        'login_page'); // Adjust the route to match your login page
  }

  // Navigate to profile page
  void _goToProfile() {
    Navigator.of(context).pushReplacementNamed('profile_page');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _username != null
                  ? 'Hi, $_username!'
                  : 'Hi, Guest!', // Use "Guest" as fallback
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'What are you cooking today?',
              style: TextStyle(
                  fontSize: 16, color: Color.fromARGB(215, 255, 255, 255)),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width - 100,
                  60,
                  0,
                  0,
                ),
                items: [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.account_circle),
                        SizedBox(width: 10),
                        Text('My Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'signOut',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 10),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
                elevation: 8.0,
              ).then((value) {
                if (value == 'profile') {
                  _goToProfile(); // Navigate to profile page
                } else if (value == 'signOut') {
                  _confirmLogout(context); // Sign out the user
                }
              });
            },
            child: CircleAvatar(
              radius: 24,
              backgroundImage:
                  _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/images/avatar.png')
                          as ImageProvider,
              child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                  ? const Icon(Icons.person) // Fallback icon if no avatar
                  : null,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 5),
          // Daily tip section wrapped in a rounded container
          CarouselSlider(
            options: CarouselOptions(
              height:
                  160.0, // Slightly increased height for a more spacious feel
              autoPlay: true,
              enlargeCenterPage: true,
              autoPlayInterval: const Duration(
                  seconds: 3), // Added auto-play interval for smoothness
              autoPlayAnimationDuration:
                  const Duration(milliseconds: 800), // Smooth animation effect
            ),
            items: dailyTipWidgets.map((tipWidget) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8), // Adjusted margins for consistency
                    padding: const EdgeInsets.all(
                        20), // Reduced padding for a sleek look
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue[100]!,
                          Colors.blue[300]!
                        ], // Gradient background for a modern touch
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                          20), // Increased border radius for modernity
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                              0.2), // Slightly darker shadow for depth
                          blurRadius: 8,
                          spreadRadius: 3,
                          offset: const Offset(
                              0, 4), // Subtle shadow offset for a lifted effect
                        ),
                      ],
                    ),
                    child: Center(
                      child: tipWidget,
                    ),
                  );
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 5),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Recipes from People You Follow:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          //const SizedBox(height: 10),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: followingUsers.isNotEmpty
                      ? _recipesCollection
                          .where('userId',
                              whereIn:
                                  followingUsers) // Only query if the user is following anyone
                          .orderBy('createdAt', descending: true)
                          .snapshots()
                      : const Stream
                          .empty(), // If no following users, return an empty stream
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                        //strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ));
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading recipes"));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Center(
                            child: Text("""You are not following anyone"""),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to the Search page in MainLayout
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainLayout(
                                      initialPage:
                                          1), // Set the initialPage to 1 for Search
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Button color
                            ),
                            child: const Text("Explore"),
                          ),
                        ],
                      );
                    }

                    final recipes = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(10.0),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        var recipe = recipes[index];
                        var recipeData = recipe.data() as Map<String, dynamic>?;

                        var recipeName =
                            recipeData?['recipeName'] ?? 'No Recipe Name';
                        var imageUrl = recipeData?['imageUrl'] ?? '';
                        var userId = recipeData?['userId'] ?? '';
                        var riskLevel = recipeData?['riskLevel'] ?? 0;
                        var tags = List<String>.from(recipeData?['tags'] ?? []);

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _fetchUserDetails(userId),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.grey),
                              );
                            }

                            if (userSnapshot.hasError ||
                                !userSnapshot.hasData) {
                              return const ListTile(
                                title: Text("User data unavailable"),
                              );
                            }

                            var userData = userSnapshot.data!;
                            var username = userData['username'] ?? 'Unknown';
                            var avatarUrl = userData['profileImageUrl'] ?? '';
                            String clickedUserId = recipeData?['userId'] ?? '';

                            return FutureBuilder<double>(
                              future: _calculateAverageRating(recipe.id),
                              builder: (context, ratingSnapshot) {
                                double averageRating =
                                    ratingSnapshot.data ?? 0.0;

                                // Risk level icons
                                IconData riskIcon;
                                Color riskColor;
                                String riskLabel;

                                switch (riskLevel) {
                                  case 1:
                                    riskIcon = Icons.check_circle;
                                    riskColor = Colors.green;
                                    riskLabel = 'Low Risk';
                                    break;
                                  case 2:
                                    riskIcon = Icons.warning;
                                    riskColor = Colors.orange;
                                    riskLabel = 'Medium Risk';
                                    break;
                                  case 3:
                                  default:
                                    riskIcon = Icons.error;
                                    riskColor = Colors.red;
                                    riskLabel = 'High Risk';
                                    break;
                                }

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SearchRecipeDetailPage(
                                          recipe: recipe,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Color.fromARGB(235, 190, 222, 251)
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.grey,
                                          blurRadius: 10,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (imageUrl.isNotEmpty) ...[
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            child: Image.network(
                                              imageUrl,
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        UserPage(
                                                      userId: clickedUserId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets
                                                    .zero, // Remove padding to fit the CircleAvatar size
                                                minimumSize: const Size(0,
                                                    0), // Ensure it doesn't affect layout
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: CircleAvatar(
                                                backgroundImage:
                                                    NetworkImage(avatarUrl),
                                                radius: 18.0,
                                                backgroundColor:
                                                    Colors.grey[200],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        UserPage(
                                                      userId: clickedUserId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets
                                                    .zero, // Remove padding for a clean text look
                                                minimumSize: const Size(0,
                                                    0), // Ensure it doesn't affect layout
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Text(
                                                username,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18.0,
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          recipeName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(riskIcon,
                                                    color: riskColor, size: 20),
                                                const SizedBox(width: 6),
                                                Text(
                                                  riskLabel,
                                                  style: TextStyle(
                                                    color: riskColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.star,
                                                    color: Colors.amber,
                                                    size: 25),
                                                const SizedBox(width: 6),
                                                Text(
                                                  averageRating
                                                      .toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (tags.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8.0,
                                            runSpacing: 4.0,
                                            children: tags.map((tag) {
                                              return GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          TagRecipesPage(
                                                              tag: tag),
                                                    ),
                                                  );
                                                },
                                                child: Chip(
                                                  label: Text(
                                                    tag,
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  }))
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.blue, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(30), // Rounded corners for the FAB
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeGeneratorPage(),
              ),
            );
          },
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white, // Icon color
          ),
          tooltip: 'Click to generate a recipe!',
          backgroundColor: Colors
              .transparent, // Make background transparent to show gradient
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
