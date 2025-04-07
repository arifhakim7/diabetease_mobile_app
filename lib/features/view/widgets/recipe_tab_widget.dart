import 'package:flutter/material.dart';

class RecipeTabWidget extends StatelessWidget {
  final List<String> ingredientsList;
  final String instructions;

  const RecipeTabWidget({
    Key? key,
    required this.ingredientsList,
    required this.instructions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(thickness: 1.5),
            const Text('Ingredients',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...ingredientsList.map((ingredient) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(ingredient, style: const TextStyle(fontSize: 16)),
                )),
            const SizedBox(height: 16),
            const Divider(thickness: 1.5),
            const Text('Instructions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(instructions,
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
