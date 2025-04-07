import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp_diabetease/features/view/pages/upload/nutritional_analysis_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../firebase/firebase_service.dart';
import '../../widgets/custom_textfield_widget.dart';

class UploadRecipe extends StatefulWidget {
  const UploadRecipe({Key? key}) : super(key: key);

  @override
  _UploadRecipeState createState() => _UploadRecipeState();
}

class _UploadRecipeState extends State<UploadRecipe> {
  final FirebaseService _firebaseService = FirebaseService();

  // Controllers for inputs
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  final TextEditingController _servingController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _currentStepController = TextEditingController();
  final List<String> _formattedIngredients = [];
  final List<String> _stepsList = [];

  final List<String> _tags = [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Snacks",
    "Desserts",
    "Kidney-Friendly",
    "Vegan & Vegetarian",
    "Veggie-Rich",
    "Budget-Friendly",
    "Quick & Easy"
  ];
  List<String> _selectedTags = [];

  XFile? _imageFile;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _recipeNameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<String> _fetchAdvice({
    required String recipeName,
    required String ingredients,
    required double calories,
    required double fat,
    required double sugar,
    required double protein,
    required double carbohydrateContent,
    required double fiberContent,
    required double sodiumContent,
  }) async {
    const String apiKey = '';
    final url = Uri.parse('');

    String contextMessage = """
Nutritional information for a recipe:
- Recipe name: ${recipeName}
- Ingredients: ${ingredients}
- Calories: ${calories.toStringAsFixed(2)} kcal
- Fat: ${fat.toStringAsFixed(2)} g
- Sugar: ${sugar.toStringAsFixed(2)} g
- Protein: ${protein.toStringAsFixed(2)} g
- Carbohydrates: ${carbohydrateContent.toStringAsFixed(2)} g
- Fiber: ${fiberContent.toStringAsFixed(2)} g
- Sodium: ${sodiumContent.toStringAsFixed(2)} mg

Based on the nutritional values, 
Provide advice on whether this recipe is healthy for diabetic person, 
and suggest improvements or considerations. 
If the carbohydrate content is high, suggest alternatives.
Make sure it is in simple one paragrapgh not more than 100 words.
The text alignment should be justified.
""";

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a health and nutrition advisor.'
            },
            {'role': 'user', 'content': contextMessage},
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final advice = json.decode(response.body);
        return advice['choices'][0]['message']['content']?.toString() ??
            'No advice available.';
      } else {
        print('Failed to fetch advice: ${response.body}');
        return 'Failed to fetch advice. Please try again.';
      }
    } catch (e) {
      print('An error occurred: $e');
      return 'An error occurred. Please try again.';
    }
  }

  // API function for nutritional info
  Future<Map<String, dynamic>> _getNutritionalInfo(String ingredients) async {
    const String appId = 'd1fb732f';
    const String appKey = '3f40152a27bade50b5e1c4144066352d';
    const String url = 'https://api.edamam.com/api/nutrition-data';

    Map<String, dynamic> totalNutrients = {};
    List<String> ingredientList =
        ingredients.split('\n').map((e) => e.trim()).toList();

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
        print("Error fetching nutritional data: $e");
      }
    }
    return totalNutrients;
  }

  // Function to upload the recipe
  Future<void> _uploadRecipe() async {
    if (_recipeNameController.text.isEmpty ||
        _ingredientsController.text.isEmpty ||
        _instructionsController.text.isEmpty ||
        _servingController.text.isEmpty ||
        _prepTimeController.text.isEmpty ||
        _cookTimeController.text.isEmpty ||
        _selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '''Please fill in all required fields and select at least one tag''')),
      );
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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
        carbohydrateContent: carbohydrateContent,
      );

      String? imageUrl =
          await _firebaseService.uploadImage(File(_imageFile!.path));
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed')),
        );
        return;
      }

      String advice = await _fetchAdvice(
        recipeName: _recipeNameController.text,
        ingredients: _ingredientsController.text,
        calories: calories,
        fat: fat,
        sugar: sugar,
        protein: protein,
        carbohydrateContent: carbohydrateContent,
        fiberContent: fiberContent,
        sodiumContent: sodiumContent,
      );

      await _firebaseService.uploadRecipe(
        recipeName: _recipeNameController.text,
        description: _descriptionController.text,
        ingredients: _ingredientsController.text,
        instructions: _instructionsController.text,
        imageUrl: imageUrl,
        calories: calories,
        fat: fat,
        sugar: sugar,
        protein: protein,
        glycemicIndex: glycemicIndex,
        carbohydrateContent: carbohydrateContent,
        fiberContent: fiberContent,
        sodiumContent: sodiumContent,
        addedSugars: addedSugars,
        riskLevel: riskLevel,
        tags: _selectedTags,
        prepTime: int.tryParse(_prepTimeController.text) ?? 0,
        cookTime: int.tryParse(_cookTimeController.text) ?? 0,
        serving: int.tryParse(_servingController.text) ?? 0,
        advice: advice,
      );

      _showSuccessDialog(
        recipeName: _recipeNameController.text,
        ingredients: _ingredientsController.text,
        calories: calories,
        fat: fat,
        sugar: sugar,
        protein: protein,
        glycemicIndex: glycemicIndex,
        carbohydrateContent: carbohydrateContent,
        fiberContent: fiberContent,
        sodiumContent: sodiumContent,
        addedSugars: addedSugars,
        riskLevel: riskLevel,
        advice: advice,
      );
    } catch (e) {
      print("An error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show success dialog
  void _showSuccessDialog({
    required String recipeName,
    required String ingredients,
    required double calories,
    required double fat,
    required double sugar,
    required double protein,
    required double glycemicIndex,
    required double carbohydrateContent,
    required double fiberContent,
    required double sodiumContent,
    required double addedSugars,
    required double riskLevel,
    required String advice,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Success',
            style: TextStyle(color: Colors.blue),
          ),
          content: const Text('Recipe uploaded successfully!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => NutritionalAnalysisPage(
                      recipeName: recipeName,
                      ingredients: ingredients,
                      calories: calories,
                      fat: fat,
                      sugar: sugar,
                      protein: protein,
                      glycemicIndex: glycemicIndex,
                      carbohydrateContent: carbohydrateContent,
                      fiberContent: fiberContent,
                      sodiumContent: sodiumContent,
                      addedSugars: addedSugars,
                      riskLevel: riskLevel,
                      advice: advice,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Set the button color to blue
                foregroundColor: Colors.white, // Set the text color to white
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8), // Optional: Rounded corners
                ),
              ),
              child: const Text('Show Analysis'),
            ),
          ],
        );
      },
    );
  }

  // Function to calculate the risk level
  double _calculateRiskLevel({
    required double carbohydrateContent,
  }) {
    if (carbohydrateContent <= 45) {
      return 1.0; // Low risk
    } else if (carbohydrateContent > 45 && carbohydrateContent <= 60) {
      return 2.0; // Medium risk
    } else {
      return 3.0; // High risk
    }
  }

  // Select image
  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() => _imageFile = pickedImage);
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
      "Image",
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        steps.length,
        (index) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor:
                    currentStep >= index ? Colors.blue : Colors.grey.shade300,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 2),
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
        const SizedBox(height: 10),
        if (_currentStep == 0) _buildStepOne(),
        if (_currentStep == 1) _buildStepTwo(),
        if (_currentStep == 2) _buildStepThree(),
        if (_currentStep == 3) _buildStepFour(),
        const SizedBox(height: 10),
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
                // Validation logic
                if (_currentStep == 0) {
                  if (_recipeNameController.text.isEmpty ||
                      _servingController.text.isEmpty ||
                      _prepTimeController.text.isEmpty ||
                      _cookTimeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
                      ),
                    );
                    return;
                  }
                }

                if (_currentStep == 2) {
                  if (_selectedTags.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select tags'),
                      ),
                    );
                    return;
                  }
                  if (_ingredientsController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please insert ingredients'),
                      ),
                    );
                    return;
                  }
                  if (_instructionsController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please insert instructions'),
                      ),
                    );
                    return;
                  }
                }

                // Navigation logic
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  // Submit logic
                  _uploadRecipe();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(_currentStep == 3 ? 'Submit' : 'Next'),
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
        SizedBox(height: 15),
        CustomTextField(
          controller: _descriptionController,
          labelText: 'Description',
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: 3,
        ),
        SizedBox(height: 15),
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
            SizedBox(width: 15), // Space between the two fields
            Expanded(
              child: CustomTextField(
                controller: _cookTimeController,
                labelText: 'Cook. Time (mins)',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        CustomTextField(
          controller: _servingController,
          labelText: 'Servings',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 15),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align label to the left
          children: [
            // Label for the tags section
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'Select Tags',
                style: TextStyle(
                  fontSize: 16, // Customize the font size
                  fontWeight: FontWeight.bold, // Make the label bold
                ),
              ),
            ),

            // Tags selection using Wrap widget
            Wrap(
              spacing: 8.0,
              children: _tags.map((tag) {
                return ChoiceChip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      color: _selectedTags.contains(tag)
                          ? Colors.white
                          : Colors
                              .black, // White text when selected, blue text when not
                    ),
                  ),
                  selected: _selectedTags.contains(tag),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: Colors.blue, // Background color when selected
                  backgroundColor:
                      Colors.white, // Background color when not selected
                  shape: StadiumBorder(), // Makes the chip rounder
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0), // Makes the chip smaller
                );
              }).toList(),
            )
          ],
        )
      ],
    );
  }

  // Step 2: Ingredients & Instructions
  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input fields for ingredient and quantity
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g., 1 cup',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        10), // Rounded corners for the border
                    borderSide: const BorderSide(
                      color:
                          Colors.grey, // Default border color when not focused
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
                    borderSide: BorderSide(
                      color: Colors
                          .grey, // Border color when the text field is enabled
                      width: 1.5, // Border width when enabled
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                flex: 5,
                child: TextField(
                  controller: _ingredientController,
                  decoration: InputDecoration(
                    labelText: 'Ingredient',
                    hintText: 'e.g., sugar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Rounded corners for the border
                      borderSide: BorderSide(
                        color: Colors
                            .grey, // Default border color when not focused
                        width: 1.5, // Border width
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Rounded corners for focused border
                      borderSide: BorderSide(
                        color: Colors.blueAccent, // Focused border color
                        width: 2.0, // Border width when focused
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Rounded corners for enabled border
                      borderSide: BorderSide(
                        color: Colors
                            .grey, // Border color when the text field is enabled
                        width: 1.5, // Border width when enabled
                      ),
                    ),
                  ),
                )),
          ],
        ),
        const SizedBox(height: 10),

        // Add Ingredient Button
        ElevatedButton.icon(
          onPressed: _addIngredient,
          icon: const Icon(Icons.add),
          label: const Text('Add Ingredient'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Display added ingredients in a list format
        const Text(
          'Added Ingredients:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        ..._formattedIngredients.map(
          (ingredient) => Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            elevation: 2,
            child: ListTile(
              title: Text(ingredient),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _formattedIngredients.remove(ingredient);
                  });
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Hidden field to store combined ingredients (for DB insertion)
        Visibility(
          visible: false, // Set to false to hide the TextField
          maintainState:
              true, // Maintain the state of the TextField while hidden
          child: TextField(
            controller: _ingredientsController
              ..text = _formattedIngredients.join('\n'),
            decoration: InputDecoration(
              labelText: 'Ingredients (Combined)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            maxLines: 5,
            readOnly: true,
          ),
        )
      ],
    );
  }

  Widget _buildStepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field for current step
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // Background color of the TextField
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
          ),
          child: TextField(
            controller: _currentStepController,
            decoration: InputDecoration(
              labelText: 'Step Description',
              hintText: 'e.g., Preheat the oven to 350°F.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    12.0), // Border radius for the outline
                borderSide: BorderSide(
                  color: Colors.blue, // Outline color
                  width: 2.0, // Border width
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12.0), // Border radius when focused
                borderSide: BorderSide(
                  color: Colors.blueAccent, // Focused outline color
                  width: 2.5, // Focused border width
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12.0), // Border radius when enabled
                borderSide: BorderSide(
                  color: Colors.grey, // Outline color when enabled
                  width: 1.5, // Border width
                ),
              ),
            ),
            keyboardType: TextInputType.multiline,
            maxLines: 3,
          ),
        ),

        const SizedBox(height: 10),

        // Add Step Button
        ElevatedButton(
          onPressed: _addStep,
          child: const Text('Add Step'),
        ),

        const SizedBox(height: 10),

        // Display the step-by-step instructions with numbering
        const Text(
          'Steps:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        ..._stepsList.asMap().entries.map(
          (entry) {
            int index = entry.key + 1;
            String step = entry.value;
            return ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blue,
                child: Text(
                  '$index',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(step),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _stepsList.removeAt(entry.key);
                  });
                },
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        // Hidden field to store combined steps (for DB insertion)
        Visibility(
          visible: false,
          maintainState: true,
          child: TextField(
            controller: _instructionsController
              ..text = _stepsList
                  .asMap()
                  .entries
                  .map((e) => '${e.key + 1}. ${e.value}')
                  .join('\n'),
            decoration:
                const InputDecoration(labelText: 'Instructions (Combined)'),
            maxLines: 5,
            readOnly: true,
          ),
        ),
      ],
    );
  }

  // Step 3: Image & Submit
  Widget _buildStepFour() {
    return Column(
      children: [
        if (_imageFile != null) Image.file(File(_imageFile!.path), height: 200),
        ElevatedButton(
          onPressed: _selectImage,
          child: const Text('Select Image'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Recipe')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(child: _buildStepper()),
            ),
    );
  }
}
