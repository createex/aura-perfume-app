import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating10; // 0..10
  final int maxStars; // typically 5
  final double size;
  const RatingStars({
    super.key,
    required this.rating10,
    this.maxStars = 5,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final filled = ((rating10 / 10) * maxStars).clamp(0, maxStars).toDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        final v = i + 1;
        final isFull = v <= filled;
        final isHalf = !isFull && (v - filled).abs() < 1 && filled > i;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            isHalf ? Icons.star_half_rounded : Icons.star_rounded,
            size: size,
            color: isFull || isHalf ? AppColors.starActive : AppColors.starInactive,
          ),
        );
      }),
    );
  }
}

