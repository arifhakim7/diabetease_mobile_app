import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_diabetease/firebase/firebase_service.dart';
import 'package:fyp_diabetease/features/view/widgets/comment_tab_widget.dart';
import 'package:fyp_diabetease/features/view/widgets/recipe_tab_widget.dart';
import 'package:fyp_diabetease/features/view/widgets/nutritional_info_widget.dart';
import 'package:fyp_diabetease/features/view/widgets/risk_level_indicator_widget.dart';

class SavedRecipeDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot recipe;

  const SavedRecipeDetailPage({super.key, required this.recipe});

  @override
  _SavedRecipeDetailPageState createState() => _SavedRecipeDetailPageState();
}

class _SavedRecipeDetailPageState extends State<SavedRecipeDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isBookmarked = false;
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0.0; // Rating as double
  double averageRating = 0.0;
  String? userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      _checkIfBookmarked();
      _calculateAverageRating();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Update _setRating to accept a double
  void _setRating(double rating) {
    setState(() {
      _rating = rating;
    });
  }

  Future<void> _checkIfBookmarked() async {
    if (userId == null) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId!)
          .get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      List<dynamic> savedRecipes = userData?['savedRecipes'] ?? [];

      setState(() {
        isBookmarked = savedRecipes.contains(widget.recipe.id);
      });
    } catch (e) {
      print("Error checking if recipe is bookmarked: $e");
    }
  }

  Future<void> _toggleBookmark() async {
    await _firebaseService.toggleBookmark(widget.recipe.id);
    setState(() {
      isBookmarked = !isBookmarked;
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a comment and rating")),
      );
      return;
    }

    try {
      await _firebaseService.addComment(
        widget.recipe.id,
        _commentController.text,
        _rating.toInt(), // Send as int since Firebase accepts int for rating
      );

      // Clear input fields and reset rating
      _commentController.clear();
      setState(() {
        _rating = 0.0;
      });

      // Update the average rating
      _calculateAverageRating();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comment submitted successfully!")),
      );
    } catch (e) {
      print("Error submitting comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit comment")),
      );
    }
  }

  Future<void> _calculateAverageRating() async {
    List<QueryDocumentSnapshot> comments =
        await _firebaseService.getComments(widget.recipe.id);
    if (comments.isNotEmpty) {
      double totalRating = comments.fold(
        0,
        (sum, comment) =>
            sum + (comment.data() as Map<String, dynamic>)['rating'],
      );
      setState(() {
        averageRating = totalRating / comments.length;
      });
    } else {
      setState(() {
        averageRating = 0.0;
      });
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchComments() async {
    return await _firebaseService.getComments(widget.recipe.id);
  }

  @override
  Widget build(BuildContext context) {
    final recipeData = widget.recipe.data() as Map<String, dynamic>;

    String recipeName = recipeData['recipeName'] ?? 'No Recipe Name';
    String description =
        recipeData['description'] ?? 'No description available';
    String instructions =
        recipeData['instructions'] ?? 'No instructions available';
    String imageUrl = recipeData['imageUrl'] ?? '';
    String ingredientsString = recipeData['ingredients'] ?? '';
    List<String> ingredientsList =
        ingredientsString.isNotEmpty ? ingredientsString.split(',') : [];

    double calories = recipeData['calories'] ?? 0.0;
    double fat = recipeData['fat'] ?? 0.0;
    double addedsugar = recipeData['addedSugars'] ?? 0.0;
    double protein = recipeData['protein'] ?? 0.0;
    double carbs = recipeData['carbohydrateContent'] ?? 0.0;
    double fiber = recipeData['fiberContent'] ?? 0.0;
    double sodium = recipeData['sodiumContent'] ?? 0.0;
    double riskLevel = recipeData['riskLevel'] ?? 0;
    String advice = recipeData['advice'] ?? '';

    List<dynamic> tags = recipeData['tags'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe Details"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pink,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Recipe'),
            Tab(text: 'Comments & Rating'),
            Tab(text: 'Nutritional Info'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      recipeName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RiskLevelIndicatorWidget(riskLevel: riskLevel),
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.pink,
                      ),
                      onPressed: _toggleBookmark,
                    ),
                  ],
                ),
              ),
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Colors.blue,
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecipeTab(ingredientsList, instructions),
                    FutureBuilder<List<QueryDocumentSnapshot>>(
                      future: _fetchComments(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        }

                        return CommentTabWidget(
                          fetchComments: _fetchComments,
                          commentController: _commentController,
                          rating: _rating, // No need to call .toInt() here
                          setRating: _setRating,
                          submitComment: _submitComment,
                        );
                      },
                    ),
                    _buildNutritionalInfoTab(calories, fat, addedsugar, protein,
                        carbs, fiber, sodium, riskLevel, advice),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeTab(List<String> ingredients, String instructions) {
    return RecipeTabWidget(
      ingredientsList: ingredients,
      instructions: instructions,
    );
  }

  Widget _buildNutritionalInfoTab(
      double calories,
      double fat,
      double addedsugar,
      double protein,
      double carbs,
      double fiber,
      double sodium,
      double riskLevel,
      String advice) {
    return NutritionalInfoWidget(
      calories: calories,
      fat: fat,
      sugar: addedsugar,
      protein: protein,
      carbs: carbs,
      fiber: fiber,
      sodium: sodium,
      riskLevel: riskLevel,
      advice: advice,
    );
  }
}
