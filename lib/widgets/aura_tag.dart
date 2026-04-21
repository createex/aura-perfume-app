import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';
import '../controller/utils/app_text_styles.dart';

class AuraTag extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  const AuraTag({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.primarySoft,
    this.foregroundColor = AppColors.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: AppTextStyles.chip.copyWith(color: foregroundColor),
      ),
    );
  }
}

