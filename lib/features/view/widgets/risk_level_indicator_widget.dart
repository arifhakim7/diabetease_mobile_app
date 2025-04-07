import 'package:flutter/material.dart';

class RiskLevelIndicatorWidget extends StatelessWidget {
  final double riskLevel;

  const RiskLevelIndicatorWidget({Key? key, required this.riskLevel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    if (riskLevel == 1.0) {
      icon = Icons.check_circle;
      color = Colors.green;
      label = 'Low Risk';
    } else if (riskLevel == 2.0) {
      icon = Icons.warning;
      color = Colors.orange;
      label = 'Medium Risk';
    } else {
      icon = Icons.error;
      color = Colors.red;
      label = 'High Risk';
    }

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
