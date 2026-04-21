import 'package:flutter/material.dart';

import '../controller/utils/app_strings.dart';
import '../controller/utils/app_text_styles.dart';
import 'aura_icon_button.dart';

class AuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onMenu;
  final VoidCallback? onSearch;
  final bool showWordmark;

  const AuraAppBar({
    super.key,
    this.title,
    this.onMenu,
    this.onSearch,
    this.showWordmark = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            AuraIconButton(icon: Icons.menu_rounded, onTap: onMenu),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: showWordmark
                    ? Text(
                        AppStrings.brandWordmark,
                        style: AppTextStyles.appWordmark,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      )
                    : (title == null
                        ? const SizedBox.shrink()
                        : Text(title!, style: AppTextStyles.perfumeName)),
              ),
            ),
            const SizedBox(width: 12),
            if (onSearch != null)
              AuraIconButton(icon: Icons.search_rounded, onTap: onSearch)
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

