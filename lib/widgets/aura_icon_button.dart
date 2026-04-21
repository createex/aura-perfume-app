import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';

class AuraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const AuraIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

