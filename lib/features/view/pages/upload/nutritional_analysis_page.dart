import 'package:flutter/material.dart';
import 'package:fyp_diabetease/features/view/widgets/risk_level_meter_widget.dart';
import 'package:intl/intl.dart';

class NutritionalAnalysisPage extends StatefulWidget {
  final String recipeName;
  final String ingredients;
  final double calories;
  final double fat;
  final double sugar;
  final double protein;
  final double glycemicIndex;
  final double carbohydrateContent;
  final double fiberContent;
  final double sodiumContent;
  final double addedSugars;
  final double riskLevel;
  final String advice;

  const NutritionalAnalysisPage({
    Key? key,
    required this.recipeName,
    required this.ingredients,
    required this.calories,
    required this.fat,
    required this.sugar,
    required this.protein,
    required this.glycemicIndex,
    required this.carbohydrateContent,
    required this.fiberContent,
    required this.sodiumContent,
    required this.addedSugars,
    required this.riskLevel,
    required this.advice,
  }) : super(key: key);

  @override
  State<NutritionalAnalysisPage> createState() =>
      _NutritionalAnalysisPageState();
}

class _NutritionalAnalysisPageState extends State<NutritionalAnalysisPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          toBeginningOfSentenceCase(widget.recipeName) ?? widget.recipeName,
        ),
      ),
      body: SingleChildScrollView(
        // Makes the content scrollable
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutritional Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildNutritionalInfo(),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Aligns button to the end
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, 'profile_page');
                      },
                      child: const Text('View Recipe'),
                    ),
                  ],
                ),
                const Text(
                  'What you should know',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.advice,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Container(
              alignment: Alignment.center,
              child: RiskLevelAnalogMeter(riskLevel: widget.riskLevel),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionalInfo() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNutritionalRow(
              'Calories', '${widget.calories.toStringAsFixed(2)} kcal'),
          const Divider(thickness: 3),
          _buildNutritionalRow('Carbohydrates',
              '${widget.carbohydrateContent.toStringAsFixed(2)} g'),
          _buildNutritionalRow(
              'Fiber', '${widget.fiberContent.toStringAsFixed(2)} g'),
          _buildNutritionalRow('Fat', '${widget.fat.toStringAsFixed(2)} g'),
          _buildNutritionalRow(
              'Protein', '${widget.protein.toStringAsFixed(2)} g'),
          _buildNutritionalRow(
              'Sodium', '${widget.sodiumContent.toStringAsFixed(2)} mg'),
          _buildNutritionalRow(
              'Added Sugar', '${widget.sugar.toStringAsFixed(2)} g'),
        ],
      ),
    );
  }

  Widget _buildNutritionalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
