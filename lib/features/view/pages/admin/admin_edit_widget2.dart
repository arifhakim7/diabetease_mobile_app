import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_diabetease/features/view/pages/admin/admin_recipe_detail2.dart';
import 'package:fyp_diabetease/features/view/widgets/custom_textfield_widget.dart';
import 'package:http/http.dart' as http;

class AdminEditRecipeForm2 extends StatefulWidget {
  final QueryDocumentSnapshot recipe;
  final Future<void> Function() onRecipeUpdated;

  const AdminEditRecipeForm2(
      {required this.recipe, required this.onRecipeUpdated});

  @override
  _AdminEditRecipeForm2State createState() => _AdminEditRecipeForm2State();
}

class _AdminEditRecipeForm2State extends State<AdminEditRecipeForm2> {
  late TextEditingController _recipeNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _servingController;
  late TextEditingController _ingredientsController;
  late TextEditingController _instructionsController;
  late TextEditingController _currentStepController;
  late TextEditingController _quantityController;
  late TextEditingController _ingredientController = TextEditingController();
  late List<String> _formattedIngredients = [];
  late List<String> _stepsList = [];

  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _recipeNameController =
        TextEditingController(text: widget.recipe['recipeName']);
    _descriptionController =
        TextEditingController(text: widget.recipe['description']);
    _prepTimeController =
        TextEditingController(text: widget.recipe['prepTime']);
    _cookTimeController =
        TextEditingController(text: widget.recipe['cookTime']);
    _servingController = TextEditingController(text: widget.recipe['serving']);
    _ingredientsController =
        TextEditingController(text: widget.recipe['ingredients']);
    _instructionsController =
        TextEditingController(text: widget.recipe['instructions']);

    // Initialize the missing controllers
    _quantityController = TextEditingController();
    _ingredientController = TextEditingController();
    _currentStepController = TextEditingController();
  }

  Future<void> _saveEditedRecipe() async {
    if (_recipeNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _ingredientsController.text.isEmpty ||
        _instructionsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get nutritional information and risk level
      String ingredients = _ingredientsController.text;
      print("Ingredients input before splitting: $ingredients");
      Map<String, dynamic> nutritionData =
          await _getNutritionalInfo(ingredients);

      int serving = int.tryParse(_servingController.text) ?? 1;
      if (serving <= 0) serving = 1; // Avoid division by zero

      double glycemicIndex = 0.0;
      double glucoseContent =
          (nutritionData['SUGAR']?['quantity']?.toDouble() ?? 0.0) / serving;
      double carbohydrateContent =
          (nutritionData['CHOCDF']?['quantity']?.toDouble() ?? 0.0) / serving;
      double fiberContent =
          (nutritionData['FIBTG']?['quantity']?.toDouble() ?? 0.0) / serving;
      double sodiumContent =
          (nutritionData['NA']?['quantity']?.toDouble() ?? 0.0) / serving;
      double addedSugars =
          (nutritionData['SUGAR.added']?['quantity']?.toDouble() ?? 0.0) /
              serving;
      double calories =
          (nutritionData['ENERC_KCAL']?['quantity']?.toDouble() ?? 0.0) /
              serving;
      double fat =
          (nutritionData['FAT']?['quantity']?.toDouble() ?? 0.0) / serving;
      double protein =
          (nutritionData['PROCNT']?['quantity']?.toDouble() ?? 0.0) / serving;
      double sugar = glucoseContent;

      double riskLevel = _calculateRiskLevel(
        fat: fat,
        carbohydrateContent: carbohydrateContent,
        fiberContent: fiberContent,
        sodiumContent: sodiumContent,
      );

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .update({
        'recipeName': _recipeNameController.text,
        'description': _descriptionController.text,
        'prepTime': _prepTimeController.text,
        'cookTime': _cookTimeController.text,
        'serving': _servingController.text,
        'ingredients': _ingredientsController.text,
        'instructions': _instructionsController.text,
        'calories': calories,
        'fat': fat,
        'sugar': sugar,
        'protein': protein,
        'glycemicIndex': glycemicIndex,
        'carbohydrateContent': carbohydrateContent,
        'fiberContent': fiberContent,
        'sodiumContent': sodiumContent,
        'addedSugars': addedSugars,
        'riskLevel': riskLevel,
      });
      _showSuccessDialog(); // Close the dialog
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update recipe')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Recipe edited successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                // Navigate to the new page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminRecipeDetailPage2(recipe: widget.recipe),
                  ),
                );
              },
              child: const Text('View Your Recipe'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getNutritionalInfo(String ingredients) async {
    const String appId = 'd1fb732f';
    const String appKey = '3f40152a27bade50b5e1c4144066352d';
    const String url = 'https://api.edamam.com/api/nutrition-data';

    List<String> ingredientList =
        ingredients.split('\n').map((ingredient) => ingredient.trim()).toList();
    Map<String, dynamic> totalNutrients = {};

    for (String ingredient in ingredientList) {
      try {
        final response = await http.get(
          Uri.parse('$url?app_id=$appId&app_key=$appKey&ingr=$ingredient'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.containsKey('totalNutrients')) {
            data['totalNutrients'].forEach((key, value) {
              if (totalNutrients.containsKey(key)) {
                totalNutrients[key]['quantity'] += value['quantity'];
              } else {
                totalNutrients[key] = value;
              }
            });
          }
        }
      } catch (e) {
        print("Error fetching nutritional info for $ingredient: $e");
      }
    }

    return totalNutrients;
  }

  double _calculateRiskLevel({
    required double fat,
    required double carbohydrateContent,
    required double fiberContent,
    required double sodiumContent,
  }) {
    double score = carbohydrateContent + fat;

    if (score <= 45) return 1.0;
    if (score > 45 && score <= 60) return 2.0;
    return 3.0;
  }

  void _addIngredient() {
    final String ingredient = _ingredientController.text.trim();
    final String quantity = _quantityController.text.trim();

    if (ingredient.isNotEmpty && quantity.isNotEmpty) {
      setState(() {
        _formattedIngredients.add('$quantity $ingredient');
        _ingredientController.clear();
        _quantityController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Both ingredient and quantity are required!')),
      );
    }
  }

  void _editIngredient(int index) {
    String ingredient = _formattedIngredients[index];
    var parts = ingredient.split(' ');

    // Fill the TextEditingController with the existing values for editing
    _quantityController.text = parts.first;
    _ingredientController.text = parts.sublist(1).join(' ');

    // Remove the ingredient temporarily from the list to allow editing
    setState(() {
      _formattedIngredients.removeAt(index);
    });
  }

  void _addStep() {
    final String step = _currentStepController.text.trim();

    if (step.isNotEmpty) {
      setState(() {
        _stepsList.add(step);
        _currentStepController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Step description cannot be empty!')),
      );
    }
  }

  Widget _customStepperWidget(int currentStep) {
    const steps = [
      "Details",
      "Ingredients",
      "Instructions",
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        steps.length,
        (index) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    currentStep >= index ? Colors.blue : Colors.grey.shade300,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: currentStep >= index ? Colors.blue : Colors.grey,
                ),
              ),
              if (index < steps.length)
                Container(
                  height: 2,
                  width: double.infinity,
                  color:
                      currentStep > index ? Colors.blue : Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
            ],
          ),
        ),
      ),
    );
  }

// Stepper widget
  Widget _buildStepper() {
    return Column(
      children: [
        _customStepperWidget(_currentStep),
        const SizedBox(height: 20),
        if (_currentStep == 0) _buildStepOne(),
        if (_currentStep == 1) _buildStepTwo(),
        if (_currentStep == 2) _buildStepThree(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
                child: const Text('Back'),
              ),
            ElevatedButton(
              onPressed: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _saveEditedRecipe();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(_currentStep == 2 ? 'Save' : 'Next'),
            ),
          ],
        )
      ],
    );
  }

  // Step 1: Recipe Details
  Widget _buildStepOne() {
    return Column(
      children: [
        CustomTextField(
          controller: _recipeNameController,
          labelText: 'Recipe Name',
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _descriptionController,
          labelText: 'Description',
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 15),
        // Row for Prep Time and Cooking Time
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _prepTimeController,
                labelText: 'Prep. Time (mins)',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 15), // Space between the two fields
            Expanded(
              child: CustomTextField(
                controller: _cookTimeController,
                labelText: 'Cook. Time (mins)',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _servingController,
          labelText: 'Servings',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // Step 2: Ingredients & Instructions
  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ingredientsController,
          decoration: InputDecoration(
            labelText: 'Ingredients',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(10), // Rounded corners for the border
              borderSide: const BorderSide(
                color: Colors.grey, // Default border color when not focused
                width: 1.5, // Border width
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  10), // Rounded corners for focused border
              borderSide: const BorderSide(
                color: Colors.blueAccent, // Focused border color
                width: 2.0, // Border width when focused
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  10), // Rounded corners for enabled border
              borderSide: const BorderSide(
                color:
                    Colors.grey, // Border color when the text field is enabled
                width: 1.5, // Border width when enabled
              ),
            ),
          ),
          minLines: 20,
          maxLines: null, // This allows the TextField to expand with new lines
          keyboardType: TextInputType.multiline, // This allows multiline input
        ),
      ],
    );
  }

  Widget _buildStepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _instructionsController,
          decoration: InputDecoration(
            labelText: 'Ingredients',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(10), // Rounded corners for the border
              borderSide: const BorderSide(
                color: Colors.grey, // Default border color when not focused
                width: 1.5, // Border width
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  10), // Rounded corners for focused border
              borderSide: const BorderSide(
                color: Colors.blueAccent, // Focused border color
                width: 2.0, // Border width when focused
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  10), // Rounded corners for enabled border
              borderSide: const BorderSide(
                color:
                    Colors.grey, // Border color when the text field is enabled
                width: 1.5, // Border width when enabled
              ),
            ),
          ),
          minLines: 20,
          maxLines: null, // This allows the TextField to expand with new lines
          keyboardType: TextInputType.multiline, // This allows multiline input
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Recipe')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(child: _buildStepper()),
            ),
    );
  }
}
