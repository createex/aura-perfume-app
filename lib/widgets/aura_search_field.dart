import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';
import '../controller/utils/app_text_styles.dart';

class AuraSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final VoidCallback? onFilter;

  const AuraSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Buscar fragancia…',
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle:
                    AppTextStyles.bodyMuted.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textTertiary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onFilter,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

