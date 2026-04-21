import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';
import '../controller/utils/app_text_styles.dart';
import '../domain/perfume/perfume.dart';
import 'perfume_image.dart';
import 'rating_stars.dart';

class RecommendationTilePerfumeCard extends StatelessWidget {
  final Perfume perfume;
  final VoidCallback? onTap;

  const RecommendationTilePerfumeCard({
    super.key,
    required this.perfume,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Center(child: PerfumeImage(path: perfume.imagePath, size: 120)),
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              perfume.brand.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                letterSpacing: 2.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              perfume.name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${(perfume.rating / 2).toStringAsFixed(1)} / 5.0',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                RatingStars(rating10: perfume.rating, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

