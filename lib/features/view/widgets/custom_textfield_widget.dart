// custom_text_field.dart

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final bool isNumber;
  final int minLines;
  final int maxLines;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.isNumber = false,
    this.minLines = 1, // Default to 1 line
    this.maxLines = 1, // Default to 1 line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10), // Rounded corners for the border
          borderSide: BorderSide(
            color: Colors.grey, // Default border color when not focused
            width: 1.5, // Border width
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10), // Rounded corners for focused border
          borderSide: BorderSide(
            color: Colors.blueAccent, // Focused border color
            width: 2.0, // Border width when focused
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10), // Rounded corners for enabled border
          borderSide: BorderSide(
            color: Colors.grey, // Border color when the text field is enabled
            width: 1.5, // Border width when enabled
          ),
        ),
      ),
      keyboardType: isNumber ? TextInputType.number : keyboardType,
      minLines: minLines,
      maxLines: maxLines,
    );
  }
}
