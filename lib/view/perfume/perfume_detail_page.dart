import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_routes.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../controller/utils/perfume_ui_helpers.dart';
import '../../widgets/aura_info_grid.dart';
import '../../widgets/aura_notes_row.dart';
import '../../widgets/aura_section.dart';
import '../../widgets/aura_tag.dart';
import '../../widgets/perfume_image.dart';
import '../../widgets/rating_stars.dart';

/// Ficha completa (desde **Qué usar** / rejilla).
class PerfumeDetailPage extends StatelessWidget {
  const PerfumeDetailPage({super.key});

  static String _money(double? p) {
    if (p == null) return '—';
    return '\$${p.toStringAsFixed(2)}';
  }

  static Future<void> _openLink(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) {
      AppLog.warning('Detail: invalid catalog link URL', url);
      return;
    }
    AppLog.tap('PerfumeDetail', 'Open external catalog link', {'uri': u.toString()});
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
      AppLog.action('Launched external browser', {'uri': u.toString()});
    } else {
      AppLog.warning('Cannot launch URL (canLaunchUrl false)', u.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = (Get.parameters['id'] ?? '').toString();
    final c = Get.find<PerfumeController>();
    final perfume = c.byId(id);

    if (perfume == null) {
      AppLog.warning(
        'PerfumeDetail opened but perfume not found',
        {'routeId': id},
      );
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              AppLog.tap('PerfumeDetail', 'Back (not-found state)');
              Get.back();
            },
          ),
        ),
        body: Center(
          child: Text('Perfume no encontrado', style: AppTextStyles.bodyMuted),
        ),
      );
    }

    final topPick = perfume.rating >= 8.5;
    final dur = excelBandToProgress(perfume.duracion);
    final proj = excelBandToProgress(perfume.proyeccion);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            AppLog.tap(
              'PerfumeDetail',
              'Back',
              AppLog.perfumeSummary(perfume),
            );
            Get.back();
          },
        ),
        title: Text('AURA', style: AppTextStyles.appWordmark),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              final editRoute =
                  AppRoutes.perfumeEdit.replaceFirst(':id', perfume.id);
              AppLog.navigate(
                'OPEN edit',
                editRoute,
                AppLog.perfumeSummary(perfume),
              );
              Get.toNamed(editRoute);
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
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
              const SizedBox(width: 10),
              if (topPick)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Top colección',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'CALIFICACIÓN PERSONAL',
            style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          AuraSection(
            title: 'INFORMACIÓN GENERAL',
            child: AuraInfoGrid(
              items: [
                AuraInfo('Precio', _money(perfume.price)),
                AuraInfo('Proveedor', perfume.origin ?? '—'),
                AuraInfo(
                  'Vitrina / ubicación',
                  perfume.vitrina ?? '—',
                ),
                AuraInfo('Reponer', perfume.reponer ?? '—'),
                AuraInfo('Día / Noche', perfume.diaNoche ?? '—'),
                AuraInfo('Frío / Calor', perfume.frioCalor ?? '—'),
                AuraInfo('Playa (Excel)', perfume.playaRaw ?? '—'),
                AuraInfo('Año', perfume.year ?? '—'),
              ],
            ),
          ),
          if (perfume.occasions.isNotEmpty) ...[
            const SizedBox(height: 14),
            AuraSection(
              title: 'USO / OCASIÓN',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: perfume.occasions
                    .map((t) => AuraTag(text: t))
                    .toList(growable: false),
              ),
            ),
          ],
          if (perfume.styles.isNotEmpty) ...[
            const SizedBox(height: 14),
            AuraSection(
              title: 'PERFIL / ESTILO (Excel)',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: perfume.styles
                    .map((t) => AuraTag(text: t))
                    .toList(growable: false),
              ),
            ),
          ],
          const SizedBox(height: 14),
          AuraSection(
            title: 'RENDIMIENTO (Excel)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duración · ${perfume.duracion ?? '—'}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: dur,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceMuted,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Proyección · ${perfume.proyeccion ?? '—'}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: proj,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceMuted,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          if (perfume.description != null &&
              perfume.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            AuraSection(
              title: 'NOTAS DEL CATÁLOGO',
              child: Text(
                perfume.description!,
                style: AppTextStyles.bodyMuted,
              ),
            ),
          ],
          if (perfume.link != null && perfume.link!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openLink(perfume.link!),
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: const Text('Abrir enlace del catálogo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
          if (perfume.notesTop.isNotEmpty ||
              perfume.notesHeart.isNotEmpty ||
              perfume.notesBase.isNotEmpty) ...[
            const SizedBox(height: 14),
            AuraSection(
              title: 'PERFIL OLFATIVO',
              child: Column(
                children: [
                  if (perfume.notesTop.isNotEmpty)
                    AuraNotesRow(title: 'SALIDA', notes: perfume.notesTop),
                  if (perfume.notesHeart.isNotEmpty)
                    AuraNotesRow(title: 'CORAZÓN', notes: perfume.notesHeart),
                  if (perfume.notesBase.isNotEmpty)
                    AuraNotesRow(title: 'BASE', notes: perfume.notesBase),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
