import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_routes.dart';
import '../../controller/utils/app_strings.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../controller/utils/view_insets.dart';
import '../../domain/perfume/perfume.dart';
import '../../widgets/aura_buttons.dart';
import '../../widgets/perfume_image.dart';

/// Pantalla tipo diseño «Tu elección aleatoria»: hero, texto, CTA a ficha completa.
class RecommendationSpotlightPage extends StatefulWidget {
  const RecommendationSpotlightPage({super.key});

  @override
  State<RecommendationSpotlightPage> createState() =>
      _RecommendationSpotlightPageState();
}

class _RecommendationSpotlightPageState
    extends State<RecommendationSpotlightPage> {
  Perfume? _p;

  @override
  void initState() {
    super.initState();
    AppLog.startup('RecommendationSpotlightPage initState');
    _pick();
  }

  void _pick() {
    final c = Get.find<PerfumeController>();
    final list = c.chooseList;
    if (list.isEmpty) {
      AppLog.catalog(
        'RecommendationSpotlight: random pick skipped (empty chooseList)',
        {'poolSize': 0},
      );
      setState(() => _p = null);
      return;
    }
    final idx = Random().nextInt(list.length);
    final next = list[idx];
    AppLog.catalog(
      'RecommendationSpotlight: random perfume selected',
      {
        ...AppLog.perfumeSummary(next),
        'poolSize': list.length,
        'randomIndex': idx,
      },
    );
    setState(() => _p = next);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            AppLog.tap('RecommendationSpotlight', 'Back');
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
      body: p == null
          ? Center(
              child: Text(
                'No hay coincidencias con los filtros actuales en Qué usar.',
                style: AppTextStyles.bodyMuted,
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                28 + ViewInsets.bottomOverlap(context),
              ),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ColoredBox(
                          color: AppColors.surfaceMuted,
                          child: Center(
                            child: PerfumeImage(path: p.imagePath, size: 200),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.rating.toStringAsFixed(1),
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.star_rounded,
                                  color: AppColors.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'RECOMENDACIÓN PERSONAL',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(p.name, style: AppTextStyles.screenTitle),
                const SizedBox(height: 10),
                Text(
                  p.description ??
                      'Explora la ficha completa para ver proyección, duración, ocasiones y enlace del catálogo.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 20),
                _noteCard('SALIDA', p.notesTop),
                const SizedBox(height: 10),
                _noteCard('CORAZÓN', p.notesHeart),
                const SizedBox(height: 10),
                _noteCard('BASE', p.notesBase),
                const SizedBox(height: 22),
                AuraPrimaryButton(
                  label: 'Ver detalles',
                  onTap: () {
                    final route =
                        AppRoutes.perfumeDetail.replaceFirst(':id', p.id);
                    AppLog.navigate(
                      'REPLACE_WITH_DETAIL',
                      route,
                      AppLog.perfumeSummary(p),
                    );
                    Get.offNamed(route);
                  },
                ),
                const SizedBox(height: 12),
                AuraSecondaryButton(
                  label: 'Otra opción',
                  onTap: () {
                    AppLog.tap(
                      'RecommendationSpotlight',
                      'Pick another random option',
                      AppLog.perfumeSummary(p),
                    );
                    _pick();
                  },
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Por qué esta elección?',
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Basado en tu biblioteca y en las notas del catálogo importado.',
                              style: AppTextStyles.bodyMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          'AI',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _noteCard(String title, List<String> notes) {
    final text = notes.isEmpty ? '—' : notes.join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text(text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
