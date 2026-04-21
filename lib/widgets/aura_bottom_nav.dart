import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/getx_controllers/home/home_nav_controller.dart';
import '../controller/utils/app_colors.dart';
import '../controller/utils/app_text_styles.dart';

class AuraBottomNav extends StatelessWidget {
  final void Function(int index) onTap;
  const AuraBottomNav({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<HomeNavController>();
    return Obx(() {
      final idx = nav.tabIndex.value;
      return Container(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                label: 'Biblioteca',
                icon: Icons.local_library_outlined,
                activeIcon: Icons.local_library_rounded,
                active: idx == 0,
                onTap: () => onTap(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Qué usar',
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                active: idx == 1,
                onTap: () => onTap(1),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textTertiary;
    final style = active ? AppTextStyles.navLabelActive : AppTextStyles.navLabel;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: style),
          ],
        ),
      ),
    );
  }
}

