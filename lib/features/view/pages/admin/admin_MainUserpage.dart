import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_diabetease/features/view/pages/admin/admin_recipe_detail2.dart';

class AdminMainUserPage extends StatelessWidget {
  final String userId;
  final String username;
  final String avatar;

  const AdminMainUserPage({
    Key? key,
    required this.userId,
    required this.username,
    required this.avatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(avatar),
              radius: 20.0,
            ),
            const SizedBox(width: 10),
            Text(
              username,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var recipes = snapshot.data!.docs;
          if (recipes.isEmpty) {
            return const Center(child: Text('No uploaded recipe'));
          }
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
}
