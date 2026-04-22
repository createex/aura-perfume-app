import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/catalog_text_links.dart';
import '../../controller/utils/launch_url_helper.dart';
import '../../controller/utils/app_routes.dart';
import '../../controller/utils/rating_format.dart';
import '../../controller/utils/app_strings.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../controller/utils/view_insets.dart';
import '../../controller/utils/perfume_ui_helpers.dart';
import '../../domain/perfume/perfume.dart';
import '../../widgets/aura_info_grid.dart';
import '../../widgets/aura_notes_row.dart';
import '../../widgets/aura_section.dart';
import '../../widgets/aura_linkable_text.dart';
import '../../widgets/aura_tag.dart';
import '../../widgets/perfume_image.dart';
import '../../widgets/rating_stars.dart';

/// Ficha completa (desde **Qué usar** / rejilla).
class PerfumeDetailPage extends StatelessWidget {
  const PerfumeDetailPage({super.key});

  static Future<void> _openLink(String url) async {
    AppLog.tap('PerfumeDetail', 'Open external catalog link', {'raw': url});
    final ok = await LaunchUrlHelper.openInExternalBrowser(url);
    if (!ok) {
      Get.snackbar(
        'Enlace',
        'No se pudo abrir el enlace. Revisa la URL o tu navegador.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  static void _openImageFullScreen(BuildContext context, String? path) {
    if (path == null || path.trim().isEmpty) return;
    AppLog.tap('PerfumeDetail', 'Open fullscreen image');
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.6,
                  maxScale: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: PerfumeImage(path: path, size: 360),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _triBool(bool? v) {
    if (v == true) return 'Sí';
    if (v == false) return 'No';
    return '—';
  }

  static String _playaLine(Perfume p) {
    if (p.beach != null) return _triBool(p.beach);
    final raw = (p.playaRaw ?? '').trim();
    if (raw.isEmpty || raw == '-') return '—';
    return raw;
  }

  /// Dedicated [Perfume.link], or first URL found inside [Perfume.description].
  static String? _catalogLinkToOpen(Perfume p) {
    final direct = p.link?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    return firstHttpUrlInText(p.description);
  }

  static List<Widget> _catalogNotesSection(Perfume perfume) {
    final notes = perfume.description?.trim();
    final hasNotes = notes != null && notes.isNotEmpty;
    final linkToOpen = _catalogLinkToOpen(perfume)?.trim();
    final hasLink = linkToOpen != null && linkToOpen.isNotEmpty;
    if (!hasNotes && !hasLink) return const [];
    return [
      const SizedBox(height: 14),
      AuraSection(
        title: 'NOTAS DEL CATÁLOGO',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasLink) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openLink(linkToOpen),
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  label: const Text('LINK'),
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
              const SizedBox(height: 10),
            ],
            if (hasNotes) ...[
              Text(
                'Los enlaces en azul se abren al tocarlos. También puedes usar LINK.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 8),
              AuraLinkableText(
                text: notes,
                style: AppTextStyles.bodyMuted,
              ),
            ] else if (hasLink)
              Text(
                'Este perfume incluye un enlace de catálogo. Usa el botón LINK.',
                style: AppTextStyles.bodyMuted,
              ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final id = (Get.parameters['id'] ?? '').toString();
    final c = Get.find<PerfumeController>();

    return Obx(() {
      final perfume = c.byId(id);

      if (perfume == null) {
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
          title: Text(
            AppStrings.brandWordmark,
            style: AppTextStyles.appWordmark,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
          padding: EdgeInsets.fromLTRB(
            18,
            8,
            18,
            28 + ViewInsets.bottomOverlap(context),
          ),
          children: [
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openImageFullScreen(context, perfume.imagePath),
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: PerfumeImage(path: perfume.imagePath, size: 220),
                  ),
                ),
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
                        RatingFormat.pill(perfume.rating),
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      RatingStars(rating10: perfume.rating, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Top colección',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Marca este perfume como destacado en tu catálogo.',
                style: AppTextStyles.caption,
              ),
              value: perfume.topCollection == true,
              onChanged: (v) async {
                final fresh = c.byId(id);
                if (fresh == null) return;
                AppLog.action('Detail: topCollection toggle', {'value': v});
                await c.upsert(fresh.copyWith(topCollection: v));
              },
            ),
            const SizedBox(height: 4),
            Text(
              'CALIFICACIÓN PERSONAL',
              style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            AuraSection(
              title: 'INFORMACIÓN GENERAL',
              child: AuraInfoGrid(
                items: [
                  AuraInfo('Precio', formatUsdWholeNoDecimals(perfume.price)),
                  AuraInfo('Proveedor', perfume.supplierOrOrigin ?? '—'),
                  AuraInfo('Vitrina', perfume.vitrina ?? '—'),
                  AuraInfo(
                    'Reponer',
                    refillDisplayLabel(
                      refillNeeded: perfume.refillNeeded,
                      reponer: perfume.reponer,
                    ),
                  ),
                  AuraInfo('Día / Noche', perfume.diaNoche ?? '—'),
                  AuraInfo('Frío / Calor', perfume.frioCalor ?? '—'),
                  AuraInfo('Playa', _playaLine(perfume)),
                  AuraInfo('Salidas', _triBool(perfume.outings)),
                  AuraInfo('Oficina', _triBool(perfume.office)),
                  AuraInfo('Familiar', _triBool(perfume.family)),
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
            ..._catalogNotesSection(perfume),
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
    });
  }
}
