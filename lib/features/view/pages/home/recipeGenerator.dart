import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class RecipeGeneratorPage extends StatefulWidget {
  const RecipeGeneratorPage({Key? key}) : super(key: key);

  @override
  _RecipeGeneratorPageState createState() => _RecipeGeneratorPageState();
}

class _RecipeGeneratorPageState extends State<RecipeGeneratorPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedRecipe;
  String? _recipeImageUrl;

  // Method to generate recipe from OpenAI API
  Future<void> _generateRecipe(String prompt) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final recipe = await _callOpenAIRecipeAPI(prompt);
      final imageUrl = await _generateRecipeImage(prompt);

      setState(() {
        _generatedRecipe = recipe;
        _recipeImageUrl = imageUrl;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate recipe or image: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Method to call OpenAI API for recipe generation
  Future<String> _callOpenAIRecipeAPI(String prompt) async {
    const String apiKey = '';
    final url = Uri.parse('');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a recipe generator for food that suitable for diabetic person."
          },
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 1000,
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception('Failed to load recipe: ${response.body}');
    }
  }

  Future<String> _generateRecipeImage(String prompt) async {
    const String apiKey = '';
    final url = Uri.parse('');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "prompt": prompt,
        "n": 1, // Number of images to generate
        "size":
            "1024x1024", // Image size (e.g., 256x256, 512x512, or 1024x1024)
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'][0]
          ['url']; // Returns the URL of the first generated image
    } else {
      throw Exception('Failed to generate image: ${response.body}');
    }
  }

  // Method to clean the generated recipe text
  String decodeText(String input) {
    // Decode the input text
    String decodedText = Utf8Decoder().convert(input.runes.toList());

    // Clean unwanted markdown characters
    return decodedText.replaceAll(RegExp(r'(\*\*|###|####|#####)'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe Generator',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue, // Set the app bar color to blue
        elevation: 4,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: 'Enter what you want to eat...',
                labelStyle: TextStyle(
                  color: Colors.blue.shade700, // Blue color for the label
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.blue, // Blue color when focused
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
              ),
              style: const TextStyle(fontSize: 18),
              maxLines: 4,
              minLines: 1,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isGenerating
                  ? null
                  : () {
                      if (_promptController.text.trim().isNotEmpty) {
                        _generateRecipe(_promptController.text.trim());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please enter a prompt!'),
                            backgroundColor:
                                Colors.blue.shade700, // Blue error color
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Blue color for the button
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              icon: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.fastfood),
              label: _isGenerating
                  ? const Text(
                      'Generating...',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    )
                  : const Text(
                      'Generate Recipe',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            if (_isGenerating) ...[
              // Using Lottie animation for auto_awesome effect
              Center(
                child: Lottie.asset(
                  'asset/generator.json', // Path to your Lottie file
                  width: 100, // Customize the size
                  height: 100, // Customize the size
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Generating your recipe...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ] else if (_generatedRecipe != null) ...[
              const SizedBox(height: 20),
              if (_recipeImageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    _recipeImageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        // Image has finished loading
                        return child;
                      }
                      // Display progress indicator while loading
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                decodeText(_generatedRecipe!),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'Roboto',
                ),
              )
            ] else ...[
              const Text(
                'Enter a prompt and press the button to generate a recipe!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
