import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_recipe_detail2.dart';
import 'manage_recipe.dart';

class AdminUserPage extends StatefulWidget {
  final String userId;

  const AdminUserPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<AdminUserPage> createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  String? _username;
  String? _profileImageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to a specific page (e.g., HomePage or RecipeListPage)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ManageRecipesPage()), // Replace with your desired page
            );
          },
        ),
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

                // Recipes Grid Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate dynamic childAspectRatio based on screen size
                      double itemWidth =
                          (constraints.maxWidth - 20) / 2; // Adjust for spacing
                      double itemHeight = itemWidth / 0.75;

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
                                  builder: (context) =>
                                      AdminRecipeDetailPage2(recipe: recipe),
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
                                  // Display image if available; otherwise, show a placeholder
                                  if (imageUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16.0),
                                      ),
                                      child: Image.network(
                                        imageUrl,
                                        height: itemHeight * 0.6,
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
                                        size: 60,
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
                )
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
