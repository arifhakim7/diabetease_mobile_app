import 'package:flutter/material.dart';
import 'package:fyp_diabetease/features/view/pages/inbox/chatdetail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_diabetease/features/view/pages/search/search_recipe_details.dart';
import 'package:fyp_diabetease/firebase/firebase_service.dart';

class UserPage extends StatefulWidget {
  final String userId;

  const UserPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String? _username;
  String? _profileImageUrl;
  bool _isFollowing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _checkIfFollowing();
    _firebaseService = FirebaseService();
  }

  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(widget.userId).get();

      if (userSnapshot.exists) {
        var userData = userSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _username = userData['username'] ?? "Unknown User";
          _profileImageUrl = userData['profileImageUrl'] ?? "";
        });
      } else {
        print("User data not found for user ID: ${widget.userId}");
      }
    } catch (e) {
      print("Error retrieving user profile: $e");
    }
  }

  Future<Map<String, dynamic>?> _fetchUserDetails(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      return userSnapshot.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<int> getFollowingCount() async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(widget.userId).get();

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
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(widget.userId).get();

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

  Future<void> _checkIfFollowing() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot currentUserSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (currentUserSnapshot.exists) {
        List<dynamic> following = currentUserSnapshot['followingUser'] ?? [];
        setState(() {
          _isFollowing = following.contains(widget.userId);
        });
      } else {
        print("Current user document not found.");
        setState(() {
          _isFollowing = false;
        });
      }
    } catch (e) {
      print("Error checking following status: $e");
    }
  }

  Future<void> _toggleFollow() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No user is signed in.");
        return;
      }

      String currentUserId = currentUser.uid;
      String followedUserId = widget.userId;

      if (_isFollowing) {
        // Unfollow: Remove user from following and follower lists
        await _firestore.collection('users').doc(currentUserId).update({
          'followingUser': FieldValue.arrayRemove([followedUserId])
        });
        await _firestore.collection('users').doc(followedUserId).update({
          'followedByUser': FieldValue.arrayRemove([currentUserId])
        });
      } else {
        // Follow: Add user to following and follower lists
        await _firestore.collection('users').doc(currentUserId).update({
          'followingUser': FieldValue.arrayUnion([followedUserId])
        });
        await _firestore.collection('users').doc(followedUserId).update({
          'followedByUser': FieldValue.arrayUnion([currentUserId])
        });
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      print("Error toggling follow status: $e");
    }
  }

  Future<void> _updateFollowedByUser(
      String followedUserId, String currentUserId,
      {required bool remove}) async {
    try {
      DocumentReference followedUserDoc =
          _firestore.collection('users').doc(followedUserId);
      DocumentSnapshot followedUserSnapshot = await followedUserDoc.get();

      // Cast the snapshot data to a Map for key checking
      Map<String, dynamic>? followedUserData =
          followedUserSnapshot.data() as Map<String, dynamic>?;

      // Check if 'followedByUser' exists; if not, initialize it as an empty list
      List<dynamic> followedBy = [];
      if (followedUserData != null &&
          followedUserData.containsKey('followedByUser')) {
        followedBy = List.from(followedUserData['followedByUser']);
      }

      // Add or remove the current user from the followedBy list
      if (remove) {
        followedBy.remove(currentUserId);
      } else {
        followedBy.add(currentUserId);
      }

      // Update the followedBy list in Firestore
      await followedUserDoc.update({'followedByUser': followedBy});
    } catch (e) {
      print("Error updating followedByUser field: $e");
    }
  }

  Future<void> _refreshUserState() async {
    await _fetchUserProfile();
    await _checkIfFollowing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _username != null && _profileImageUrl != null
            ? Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(_profileImageUrl!),
                    radius: 20.0,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _username ?? 'Loading...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              )
            : const Text('Loading...'),
        centerTitle: false,
        /*leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainLayout(initialPage: 1),
              ),
              (route) => false,
            );
          },
        ),*/
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('recipes')
            .where('userId', isEqualTo: widget.userId)
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

                // Profile Stats Section
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
                      // Posts, Followers, and Following Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                              label: 'Posts', value: '${recipes.length}'),
                          FutureBuilder<int>(
                            future: getFollowersCount(),
                            builder: (context, snapshot) => _buildStatColumn(
                                label: 'Followers',
                                value: _resolveSnapshot(snapshot)),
                          ),
                          FutureBuilder<int>(
                            future: getFollowingCount(),
                            builder: (context, snapshot) => _buildStatColumn(
                                label: 'Following',
                                value: _resolveSnapshot(snapshot)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Follow and Message Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            icon: Icon(
                                _isFollowing ? Icons.check : Icons.person_add),
                            label: Text(_isFollowing ? 'Following' : 'Follow'),
                          ),
                          const SizedBox(width: 10), // Spacing between buttons
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                // Call the FirebaseService to get or create a chat
                                final chatId =
                                    await _firebaseService.getOrCreateChat(
                                  targetUserId: widget
                                      .userId, // Use the userId passed to UserPage
                                );

                                // Navigate to ChatDetailPage with the chatId and user details
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatDetailPage(
                                      chatId: chatId,
                                      name: _username!,
                                      profileImageUrl: _profileImageUrl!,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                // Handle errors (e.g., show a snackbar or dialog)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            icon: const Icon(Icons.chat),
                            label: const Text('Message'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Recipes Grid Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate childAspectRatio dynamically based on the screen width.
                      double itemWidth =
                          (constraints.maxWidth - 10) / 2; // Adjust for spacing
                      double itemHeight =
                          itemWidth / 0.75; // Adjust as needed for aspect ratio

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: itemWidth / itemHeight,
                        ),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
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
                                  builder: (context) => SearchRecipeDetailPage(
                                    recipe: recipe,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              elevation: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (imageUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16.0),
                                      ),
                                      child: Image.network(
                                        imageUrl,
                                        height: itemHeight *
                                            0.6, // Adjust for image height
                                        fit: BoxFit.cover,
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
    );
  }

  Widget _buildStatColumn({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  String _resolveSnapshot(AsyncSnapshot<int> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return '...';
    } else if (snapshot.hasError) {
      return '0';
    } else {
      return '${snapshot.data ?? 0}';
    }
  }
}
