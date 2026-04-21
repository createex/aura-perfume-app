import 'package:flutter/material.dart';

import '../controller/utils/app_text_styles.dart';

class AuraPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  const AuraPill({
    super.key,
    required this.icon,
    required this.text,
    this.backgroundColor = const Color(0xFFF0F2F7),
    this.foregroundColor = const Color(0xFF0B2D8F),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 10),
          Text(text, style: AppTextStyles.chip),
        ],
      ),
    );
  }
}

