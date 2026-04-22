import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';
import '../controller/utils/app_text_styles.dart';
import '../controller/utils/rating_format.dart';
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
        clipBehavior: Clip.antiAlias,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full width, square (height == width) — leaves room for text below.
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, c) {
                  final d = c.maxWidth;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: PerfumeImage(
                          path: perfume.imagePath,
                          size: d,
                          layoutWidth: d,
                          layoutHeight: d,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
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
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        perfume.brand.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 2.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        perfume.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        RatingFormat.gridFraction(perfume.rating),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RatingStars(
                        rating10: perfume.rating,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
