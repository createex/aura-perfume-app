import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';
import '../controller/utils/app_text_styles.dart';

class AuraInfo {
  final String label;
  final String value;
  const AuraInfo(this.label, this.value);
}

class AuraInfoGrid extends StatelessWidget {
  final List<AuraInfo> items;
  const AuraInfoGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      i.label,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      i.value,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

