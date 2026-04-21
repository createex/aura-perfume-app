import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';
import '../controller/utils/app_text_styles.dart';

class AuraPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool expanded;
  final bool loading;

  const AuraPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.expanded = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !loading && onTap != null;
    final borderRadius = BorderRadius.circular(28);
    final child = SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient:
                enabled ? AppColors.primaryGradient : null,
            color: enabled
                ? null
                : AppColors.primary.withValues(alpha: 0.35),
            borderRadius: borderRadius,
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: borderRadius,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label.toUpperCase(),
                          style: AppTextStyles.buttonPrimary,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class AuraSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool expanded;

  const AuraSecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          foregroundColor: AppColors.textPrimary,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.buttonSecondary,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

