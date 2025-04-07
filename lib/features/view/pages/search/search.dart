import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_diabetease/features/view/pages/search/search_recipe_details.dart';
import 'package:fyp_diabetease/features/view/pages/search/tag_recipe_details.dart';
import 'package:fyp_diabetease/features/view/pages/search/user_page.dart';
import 'package:fyp_diabetease/features/view/widgets/filterModal_widget.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final CollectionReference _recipesCollection =
      FirebaseFirestore.instance.collection('recipes');
  String _searchKeyword = '';
  int? _selectedRiskLevel;
  double? _selectedRating;
  List<String> _selectedTags = [];
  final List<String> defaultTagsValue = [];
  final double defaultRatingValue = 0.0;
  final int defaultRiskLevelValue = 1; // Define the default risk level value

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  Future<void> _fetchUsername() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userSnapshot.exists) {
      setState(() {});
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

  Future<void> _updateAverageRating(
      String recipeId, double averageRating) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({'averageRating': averageRating});
      debugPrint('Average rating updated for recipe: $recipeId');
    } catch (e) {
      debugPrint('Failed to update average rating: $e');
    }
  }

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
      double averageRating = totalRating / commentsSnapshot.docs.length;

      // Update the average rating in the recipes collection
      await _updateAverageRating(recipeId, averageRating);

      return averageRating;
    }

    // Update as 0.0 if no comments exist
    await _updateAverageRating(recipeId, 0.0);
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Search Recipes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color.fromARGB(255, 255, 255, 255), fontSize: 20),
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchKeyword = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for recipes...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchKeyword.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchKeyword = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Circle Filter Button with Icon
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        backgroundColor: Colors.white,
                        builder: (context) {
                          return FilterModalWidget(
                            onRiskLevelChanged: (value) {
                              setState(() {
                                _selectedRiskLevel = value;
                              });
                            },
                            onRatingChanged: (value) {
                              setState(() {
                                _selectedRating = value;
                              });
                            },
                            onTagsChanged: (value) {
                              setState(() {
                                _selectedTags = value;
                              });
                            },
                          );
                        },
                      );
                    },
                    child: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.filter_list,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _recipesCollection
                    .where('userId', isNotEqualTo: currentUserId)
                    .orderBy('userId') // Add this line
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ));
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading recipes"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No recipes available"));
                  }

                  final recipes = snapshot.data!.docs.where((doc) {
                    final recipeData = doc.data() as Map<String, dynamic>;
                    final recipeName = recipeData['recipeName'] ?? '';
                    final riskLevel = recipeData['riskLevel'] ?? 0;
                    final tags = List<String>.from(recipeData['tags'] ?? []);
                    final recipeRating = recipeData['averageRating'] ?? 0.0;

                    // Matching search keyword
                    bool matchesSearchKeyword = recipeName
                        .toLowerCase()
                        .contains(_searchKeyword.toLowerCase());

                    // Matching selected risk level
                    bool matchesRiskLevel = _selectedRiskLevel == null ||
                        riskLevel == _selectedRiskLevel;

                    // Matching selected rating
                    bool matchesRating = _selectedRating == null ||
                        recipeRating >= _selectedRating!;

                    // Matching selected tag
                    bool matchesTag = _selectedTags.isEmpty ||
                        tags.any((tag) => _selectedTags.contains(tag));

                    return matchesSearchKeyword &&
                        matchesRiskLevel &&
                        matchesRating &&
                        matchesTag;
                  }).toList();

                  return recipes.isEmpty
                      ? const Center(child: Text("No matching recipes found"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(10.0),
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            var recipe = recipes[index];
                            var recipeData =
                                recipe.data() as Map<String, dynamic>?;

                            var recipeName =
                                recipeData?['recipeName'] ?? 'No Recipe Name';
                            var imageUrl = recipeData?['imageUrl'] ?? '';
                            var userId = recipeData?['userId'] ?? '';
                            var riskLevel = recipeData?['riskLevel'] ?? 0;
                            var tags =
                                List<String>.from(recipeData?['tags'] ?? []);

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: _fetchUserDetails(userId),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey),
                                  );
                                }

                                if (userSnapshot.hasError ||
                                    !userSnapshot.hasData) {
                                  return const ListTile(
                                    title: Text("User data unavailable"),
                                  );
                                }

                                var userData = userSnapshot.data!;
                                var username =
                                    userData['username'] ?? 'Unknown';
                                var avatarUrl =
                                    userData['profileImageUrl'] ?? '';
                                String clickedUserId =
                                    recipeData?['userId'] ?? '';

                                return FutureBuilder<double>(
                                  future: _calculateAverageRating(recipe.id),
                                  builder: (context, ratingSnapshot) {
                                    double averageRating =
                                        ratingSnapshot.data ?? 0.0;

                                    // Risk level icons (Based on riskLevel)
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
                                          borderRadius:
                                              BorderRadius.circular(20),
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(riskIcon,
                                                        color: riskColor,
                                                        size: 20),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      riskLabel,
                                                      style: TextStyle(
                                                        color: riskColor,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                            color:
                                                                Colors.white),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
