import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;

  const RatingWidget({
    Key? key,
    required this.rating,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.star,
            color: rating >= 1 ? Colors.amber : Colors.grey,
            size: 24,
          ),
          onPressed: () => onRatingChanged(1),
        ),
        IconButton(
          icon: Icon(
            Icons.star,
            color: rating >= 2 ? Colors.amber : Colors.grey,
            size: 24,
          ),
          onPressed: () => onRatingChanged(2),
        ),
        IconButton(
          icon: Icon(
            Icons.star,
            color: rating >= 3 ? Colors.amber : Colors.grey,
            size: 24,
          ),
          onPressed: () => onRatingChanged(3),
        ),
        IconButton(
          icon: Icon(
            Icons.star,
            color: rating >= 4 ? Colors.amber : Colors.grey,
            size: 24,
          ),
          onPressed: () => onRatingChanged(4),
        ),
        IconButton(
          icon: Icon(
            Icons.star,
            color: rating >= 5 ? Colors.amber : Colors.grey,
            size: 24,
          ),
          onPressed: () => onRatingChanged(5),
        ),
      ],
    );
  }
}
