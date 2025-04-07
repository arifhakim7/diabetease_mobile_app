import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_diabetease/firebase/firebase_service.dart';
import '../search/search_recipe_details.dart';

class SavedRecipe extends StatefulWidget {
  const SavedRecipe({super.key});

  @override
  State<SavedRecipe> createState() => _SavedRecipeState();
}

class _SavedRecipeState extends State<SavedRecipe> {
  final FirebaseService _firebaseService = FirebaseService();

  Future<List<QueryDocumentSnapshot>> _fetchBookmarkedRecipes() async {
    return await _firebaseService.getBookmarkedRecipes();
  }

  // Handle the refresh logic
  Future<void> _refresh() async {
    setState(() {
      // Trigger the FutureBuilder to fetch the data again
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Saved Recipes'),
        centerTitle: false,
        titleTextStyle: const TextStyle(fontSize: 20),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh, // Trigger the refresh when user pulls down
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _fetchBookmarkedRecipes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No saved recipes yet!',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              );
            }

            List<QueryDocumentSnapshot> recipes = snapshot.data!;

            return LayoutBuilder(
              builder: (context, constraints) {
                // Calculate the dynamic childAspectRatio based on screen width
                double itemWidth = (constraints.maxWidth - 30) /
                    2; // Adjust for padding and spacing
                double itemHeight =
                    itemWidth / 0.75; // Adjust height based on desired ratio

                return GridView.builder(
                  padding: const EdgeInsets.all(10.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: itemWidth / itemHeight,
                  ),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    final recipeData = recipe.data() as Map<String, dynamic>;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 4,
                      child: InkWell(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (recipeData['imageUrl'] != null &&
                                recipeData['imageUrl'].isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20.0),
                                ), // Consistent border radius
                                child: Image.network(
                                  recipeData['imageUrl'],
                                  height: itemHeight *
                                      0.6, // Adjust image height proportionally
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ] else
                              Container(
                                height: itemHeight * 0.6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20.0),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        recipeData['recipeName'] ??
                                            'No Recipe Name',
                                        style: const TextStyle(
                                          fontSize: 18,
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
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
