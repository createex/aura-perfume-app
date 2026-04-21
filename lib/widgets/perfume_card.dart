import 'package:flutter/material.dart';
import '../domain/perfume/perfume.dart';
import 'library_row_perfume_card.dart';
import 'recommendation_tile_perfume_card.dart';

enum PerfumeCardVariant {
  libraryRow,
  recommendationTile,
}

class PerfumeCard extends StatelessWidget {
  final Perfume perfume;
  final PerfumeCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingTap;
  final Widget? trailing;

  const PerfumeCard({
    super.key,
    required this.perfume,
    this.variant = PerfumeCardVariant.libraryRow,
    this.onTap,
    this.onTrailingTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case PerfumeCardVariant.libraryRow:
        return LibraryRowPerfumeCard(
          perfume: perfume,
          onTap: onTap,
          onTrailingTap: onTrailingTap,
          trailing: trailing,
        );
      case PerfumeCardVariant.recommendationTile:
        return RecommendationTilePerfumeCard(perfume: perfume, onTap: onTap);
    }
  }
}
