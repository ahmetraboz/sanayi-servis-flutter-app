import 'package:flutter/material.dart';

class ReviewStars extends StatelessWidget {
  final double rating;

  const ReviewStars({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final filled = rating.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < filled ? Icons.star : Icons.star_border,
          color: i < filled ? const Color(0xFFFBBF24) : const Color(0xFFE5E7EB),
          size: 12,
        );
      }),
    );
  }
}
