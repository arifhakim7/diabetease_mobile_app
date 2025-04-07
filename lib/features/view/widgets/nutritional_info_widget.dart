import 'package:flutter/material.dart';

import 'risk_level_meter_widget.dart';

// Your NutritionalInfoWidget code
class NutritionalInfoWidget extends StatelessWidget {
  final double calories;
  final double fat;
  final double sugar;
  final double protein;
  final double fiber;
  final double sodium;
  final double carbs;
  final double riskLevel;
  final String advice;

  const NutritionalInfoWidget({
    Key? key,
    required this.calories,
    required this.fat,
    required this.sugar,
    required this.protein,
    required this.carbs,
    required this.fiber,
    required this.sodium,
    required this.riskLevel,
    required this.advice,
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
            const Text(
              'Nutritional Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Calories',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('${calories.toStringAsFixed(2)} kcal',
                          style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                  const Divider(thickness: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Carbohydrates',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text('${carbs.toStringAsFixed(2)} g',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fiber', style: TextStyle(fontSize: 16)),
                      Text('${fiber.toStringAsFixed(2)} g',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fat', style: TextStyle(fontSize: 16)),
                      Text('${fat.toStringAsFixed(2)} g',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Protein', style: TextStyle(fontSize: 16)),
                      Text('${protein.toStringAsFixed(2)} g',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sodium', style: TextStyle(fontSize: 16)),
                      Text('${sodium.toStringAsFixed(2)} mg',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Added Sugar', style: TextStyle(fontSize: 16)),
                      Text('${sugar.toStringAsFixed(2)} g',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            const Text(
              'What you should know',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              advice,
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 20),
            // Risk level gauge widget
            Container(
              alignment: Alignment.center,
              child: RiskLevelAnalogMeter(riskLevel: riskLevel),
            ),
          ],
        ),
      ),
    );
  }
}
