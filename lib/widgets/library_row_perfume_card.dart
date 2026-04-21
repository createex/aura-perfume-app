import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';
import '../controller/utils/app_text_styles.dart';
import '../domain/perfume/perfume.dart';
import 'perfume_image.dart';
import 'rating_stars.dart';

class LibraryRowPerfumeCard extends StatelessWidget {
  final Perfume perfume;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingTap;
  final Widget? trailing;

  const LibraryRowPerfumeCard({
    super.key,
    required this.perfume,
    this.onTap,
    this.onTrailingTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            PerfumeImage(path: perfume.imagePath, size: 68),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 3),
                  Text(
                    perfume.name,
                    style: AppTextStyles.perfumeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          perfume.rating.toStringAsFixed(1),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      RatingStars(rating10: perfume.rating, size: 14),
                    ],
                  ),
                  if (perfume.catalogSubtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      perfume.catalogSubtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: onTrailingTap ?? onTap,
              borderRadius: BorderRadius.circular(18),
              child: trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                    size: 28,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

