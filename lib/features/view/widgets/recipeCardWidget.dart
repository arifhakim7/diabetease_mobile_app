import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeCardWidget extends StatelessWidget {
  final QueryDocumentSnapshot recipe;

  const RecipeCardWidget({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipeData = recipe.data() as Map<String, dynamic>;
    String recipeName = recipeData['recipeName'] ?? 'No Recipe Name';
    String imageUrl = recipeData['imageUrl'] ?? '';
    double averageRating = recipeData['averageRating'] ?? 0.0;
    int servings = recipeData['servings'] ?? 0;
    int prepTime = recipeData['prepTime'] ?? 0;
    int cookTime = recipeData['cookTime'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl,
                  height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              recipeName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(averageRating.toStringAsFixed(1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Servings: $servings',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Prep Time: $prepTime mins',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Cook Time: $cookTime mins',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
