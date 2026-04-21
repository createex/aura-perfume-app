import 'package:flutter/material.dart';

import '../controller/utils/app_text_styles.dart';

class AuraChoiceChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const AuraChoiceChip({
    super.key,
    required this.text,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFDDE6FF) : const Color(0xFFF0F2F7);
    final fg = selected ? const Color(0xFF0B2D8F) : const Color(0xFF6B7280);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: AppTextStyles.chip.copyWith(color: fg),
        ),
      ),
    );
  }
}

