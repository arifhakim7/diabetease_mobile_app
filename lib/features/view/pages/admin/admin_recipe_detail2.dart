import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_diabetease/features/view/pages/admin/admin_edit_widget2.dart';
import 'package:fyp_diabetease/features/view/widgets/risk_level_indicator_widget.dart';

import '../../widgets/nutritional_info_widget.dart';
import '../../widgets/recipe_tab_widget.dart';

class AdminRecipeDetailPage2 extends StatefulWidget {
  final QueryDocumentSnapshot recipe;

  const AdminRecipeDetailPage2({Key? key, required this.recipe})
      : super(key: key);

  @override
  _AdminRecipeDetailPage2State createState() => _AdminRecipeDetailPage2State();
}

class _AdminRecipeDetailPage2State extends State<AdminRecipeDetailPage2>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> recipeData;
  bool _isLoading = false;
  late TabController _tabController;
  double averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    recipeData = widget.recipe.data() as Map<String, dynamic>;
    print('Recipe Data: $recipeData');
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _refreshRecipe() async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot refreshedRecipe = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .get();
      setState(() {
        recipeData = refreshedRecipe.data() as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh recipe data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeData = this.recipeData;

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
    int servings = int.parse(recipeData['serving'] ?? '0');
    int prepTime = int.parse(recipeData['prepTime'] ?? '0');
    int cookTime = int.parse(recipeData['cookTime'] ?? '0');
    double recipeRating = recipeData['averageRating'] ?? 0.0;
    String advice = recipeData['advice'] ?? 'No advice available';

    List<dynamic> tags = recipeData['tags'] ?? [];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable the default back button
        title: Text(
          recipeData['recipeName'] ?? 'No Recipe Name',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _navigateToEditRecipePage(context, widget.recipe),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, widget.recipe.id),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pink,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Recipe'),
            Tab(text: 'Nutritional Info'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRecipe,
        child: Padding(
          padding: const EdgeInsets.all(0.0),
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
                      Expanded(
                        child: Text(
                          recipeName,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                          overflow: TextOverflow
                              .ellipsis, // Optional: to handle overflow
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 25),
                          const SizedBox(width: 6),
                          Text(
                            recipeRating.toStringAsFixed(1),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 10, // Space between items
                    runSpacing: 5, // Space between lines
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Serving: $servings',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              'Prep: $prepTime min',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.kitchen,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              'Cook: $cookTime min',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecipeTab(ingredientsList, instructions),
                      _buildNutritionalInfoTab(calories, fat, addedsugar,
                          protein, carbs, fiber, sodium, riskLevel, advice),
                    ],
                  ),
                ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEditRecipePage(
      BuildContext context, QueryDocumentSnapshot recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditRecipeForm2(
          recipe: recipe,
          onRecipeUpdated: _refreshRecipe, // Pass the required callback
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String recipeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteRecipe(context, recipeId),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteRecipe(BuildContext context, String recipeId) {
    FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .delete()
        .then((_) {
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe deleted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting recipe: $error')),
      );
    });
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
