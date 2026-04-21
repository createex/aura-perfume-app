import 'package:flutter/material.dart';

import '../controller/utils/app_colors.dart';
import '../controller/utils/app_text_styles.dart';

class AuraNotesRow extends StatelessWidget {
  final String title;
  final List<String> notes;

  const AuraNotesRow({
    super.key,
    required this.title,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              notes.join(', '),
              style: AppTextStyles.bodyMuted,
            ),
          ),
        ],
      ),
    );
  }
}

