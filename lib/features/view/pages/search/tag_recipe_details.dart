import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_diabetease/features/view/pages/search/search_recipe_details.dart';

class TagRecipesPage extends StatelessWidget {
  final String tag;

  TagRecipesPage({required this.tag});

  @override
  Widget build(BuildContext context) {
    // Query recipes where the tag is in the tags field (which is an array)
    return Scaffold(
      appBar: AppBar(
        title: Text("Recipes with #$tag"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('tags', arrayContains: tag) // Query for recipes with the tag
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No recipes found for this tag"));
          }

          var recipes = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              // Calculate childAspectRatio dynamically based on the screen width.
              double itemWidth = (constraints.maxWidth - 30) /
                  2; // Adjust for padding and spacing
              double itemHeight =
                  itemWidth / 0.75; // Adjust height for desired aspect ratio

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
                                    0.6, // Adjust height proportionally
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
    );
  }
}
