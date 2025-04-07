import 'package:flutter/material.dart';
import 'dart:math';

class RiskLevelAnalogMeter extends StatelessWidget {
  final double riskLevel; // 1.0 = Low, 2.0 = Medium, 3.0 = High

  const RiskLevelAnalogMeter({Key? key, required this.riskLevel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    String label;

    if (riskLevel == 1.0) {
      gaugeColor = Colors.green;
      label = 'Low Risk';
    } else if (riskLevel == 2.0) {
      gaugeColor = Colors.orange;
      label = 'Medium Risk';
    } else {
      gaugeColor = Colors.red;
      label = 'High Risk';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: gaugeColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        CustomPaint(
          size: const Size(200, 200),
          painter: _AnalogMeterPainter(riskLevel),
        ),
      ],
    );
  }
}

class _AnalogMeterPainter extends CustomPainter {
  final double riskLevel;

  _AnalogMeterPainter(this.riskLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the colored arcs for Low, Medium, and High risk
    final paintLow = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    final paintMedium = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    final paintHigh = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    // Define sections
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      pi, // Start angle (180 degrees)
      pi / 3, // Sweep angle for Low Risk
      false,
      paintLow,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      pi + pi / 3, // Start angle for Medium Risk
      pi / 3, // Sweep angle for Medium Risk
      false,
      paintMedium,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      pi + 2 * pi / 3, // Start angle for High Risk
      pi / 3, // Sweep angle for High Risk
      false,
      paintHigh,
    );

    // Draw the needle centered in each section
    final needlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4;

    // Adjust the needle to point to the center of each section
    final needleAngle = pi + ((riskLevel - 1.0) * pi / 3) + (pi / 6);
    final needleLength = radius - 20;
    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    // Draw the center circle
    final centerCirclePaint = Paint()..color = Colors.black;
    canvas.drawCircle(center, 8, centerCirclePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
