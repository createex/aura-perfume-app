import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/getx_controllers/home/home_nav_controller.dart';
import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_strings.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../controller/utils/view_insets.dart';
import '../../widgets/aura_section.dart';
import '../../widgets/perfume_image.dart';
import '../../widgets/rating_stars.dart';

/// Ficha vacía / plantilla al abrir desde **Biblioteca** (lista).
class PerfumeDetailTemplatePage extends StatelessWidget {
  const PerfumeDetailTemplatePage({super.key});

  static const _dash = '—';

  @override
  Widget build(BuildContext context) {
    final id = (Get.parameters['id'] ?? '').toString();
    final c = Get.find<PerfumeController>();
    final perfume = c.byId(id);

    if (perfume == null) {
      AppLog.warning(
        'PerfumeDetailTemplate opened but perfume not found',
        {'routeId': id},
      );
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              AppLog.tap('PerfumeDetailTemplate', 'Back (not-found state)');
              Get.back();
            },
          ),
        ),
        body: Center(
          child: Text('Perfume no encontrado', style: AppTextStyles.bodyMuted),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            AppLog.tap(
              'PerfumeDetailTemplate',
              'Back',
              AppLog.perfumeSummary(perfume),
            );
            Get.back();
          },
        ),
        title: Text(
          AppStrings.brandWordmark,
          style: AppTextStyles.appWordmark,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          8,
          18,
          28 + ViewInsets.bottomOverlap(context),
        ),
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: PerfumeImage(path: perfume.imagePath, size: 220),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            perfume.brand.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(perfume.name, style: AppTextStyles.screenTitle),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  perfume.rating.toStringAsFixed(1),
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
                RatingStars(rating10: perfume.rating, size: 14),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vista plantilla desde Biblioteca. En la pestaña Qué usar, toca la tarjeta del mismo perfume para ver la ficha completa con todos los datos del Excel.',
                    style: AppTextStyles.bodyMuted.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AuraSection(
            title: 'INFORMACIÓN GENERAL',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Precio', _dash),
                _row('Proveedor', _dash),
                _row('Vitrina', _dash),
                _row('Disponible', _dash),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'USO / OCASIÓN',
            child: Text(_dash, style: AppTextStyles.bodyMuted),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'RENDIMIENTO',
            child: Text(_dash, style: AppTextStyles.bodyMuted),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'PERFIL OLFATIVO',
            child: Text(_dash, style: AppTextStyles.bodyMuted),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () {
              AppLog.tap(
                'PerfumeDetailTemplate',
                'Go to Qué usar (Choose tab)',
                AppLog.perfumeSummary(perfume),
              );
              Get.back();
              if (Get.isRegistered<HomeNavController>()) {
                Get.find<HomeNavController>().setTab(1);
              }
            },
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Ir a Qué usar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
          Text(
            v,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
