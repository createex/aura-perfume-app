import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/getx_controllers/inventory/inventory_import_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_strings.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../controller/utils/view_insets.dart';
import '../../widgets/aura_buttons.dart';

Future<void> _confirmResetCatalog(
  BuildContext context,
  InventoryImportController c,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        '¿Vaciar catálogo?',
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Se eliminarán todos los perfumes guardados en este dispositivo. Esta acción no se puede deshacer.',
        style: AppTextStyles.bodyMuted,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Cancel', style: AppTextStyles.body),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'Delete',
            style: AppTextStyles.body.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  if (!context.mounted || confirmed != true) return;
  await c.deleteAllCatalog();
}

class InventoryImportPage extends StatelessWidget {
  const InventoryImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<InventoryImportController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            AppLog.tap('InventoryImport', 'Back');
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
          Obx(() {
            final busy = c.importing.value ||
                c.exporting.value ||
                c.resetting.value;
            return TextButton(
              onPressed: busy
                  ? null
                  : () {
                      AppLog.tap('InventoryImport', 'Reset (show dialog)');
                      _confirmResetCatalog(context, c);
                    },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: Text(
                'Reset',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          8,
          18,
          24 + ViewInsets.bottomOverlap(context),
        ),
        children: [
          Text('Importación de\nInventario', style: AppTextStyles.screenTitle),
          const SizedBox(height: 8),
          Text(
            'Gestión masiva para el taller olfativo',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Instrucciones de\nArchivo',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Asegúrese de que su archivo Excel contenga una hoja denominada exactamente VITRINA con las columnas del catálogo (NOMBRE, MARCA, PRECIO, etc.). El sistema lee VITRINA y CAJÓN cuando existen.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'La app no incluye un catálogo de muestra: al instalarla, su inventario empieza vacío. La importación solo actualiza la base de datos en este dispositivo; no envía el archivo a Internet.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Columnas (hoja VITRINA o CAJÓN)',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _excelFieldGuide,
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 16),
                CustomPaint(
                  painter: _DashedBorderPainter(
                    color: AppColors.border,
                    strokeWidth: 2,
                    radius: 22,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Arrastre su archivo\nExcel',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Soporta formato .xlsx\nhasta 20MB',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMuted,
                        ),
                        const SizedBox(height: 14),
                        Obx(() {
                          final busy = c.importing.value ||
                              c.exporting.value ||
                              c.resetting.value;
                          return AuraPrimaryButton(
                            label: 'Seleccionar archivo',
                            loading: busy,
                            onTap: busy ? null : c.pickAndImportExcel,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  if (!c.importing.value && c.status.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (c.importing.value)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              c.status.value.isEmpty
                                  ? 'Importando perfumes…'
                                  : c.status.value,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (c.importing.value)
                            Text(
                              '${(c.progress.value * 100).round()}%',
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: c.importing.value ? c.progress.value : 1,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                Obx(() {
                  final msg = c.error.value;
                  if (msg == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border(
                        left: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.65),
                          width: 4,
                        ),
                        top: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.15)),
                        right: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.15)),
                        bottom: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(msg, style: AppTextStyles.bodyMuted),
                        ),
                      ],
                    ),
                  );
                }),
                Obx(() {
                  final ok = c.successMessage.value;
                  if (ok == null || ok.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            width: 4,
                          ),
                          top: BorderSide(color: AppColors.border),
                          right: BorderSide(color: AppColors.border),
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Éxito!',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(ok, style: AppTextStyles.bodyMuted),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: c.dismissSuccess,
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 22),
                Text('Exportar catálogo', style: AppTextStyles.screenTitle),
                const SizedBox(height: 8),
                Text(
                  'Genera un archivo .xlsx con todos los perfumes de la base local (hoja VITRINA). Se guarda en el directorio de documentos de la app.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 14),
                Obx(() {
                  final busy = c.importing.value ||
                      c.exporting.value ||
                      c.resetting.value;
                  return AuraSecondaryButton(
                    label: busy ? 'EXPORTANDO…' : 'EXPORTAR A EXCEL (.XLSX)',
                    onTap: busy
                        ? () {
                            AppLog.tap(
                              'InventoryImport',
                              'Export button ignored (busy)',
                            );
                          }
                        : c.exportCatalogToExcel,
                  );
                }),
                Obx(() {
                  final path = c.exportSuccessPath.value;
                  if (path == null || path.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.folder_zip_outlined,
                              color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SelectableText(
                              path,
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                          IconButton(
                            onPressed: c.dismissExportSuccess,
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Headers accepted by [PerfumeXlsxParser] / export template (Spanish or English aliases).
const String _excelFieldGuide = '''
Requerido
• Nombre o Name
• Marca o Brand

Opcional (hoja completa “estilo Vitrina”: columnas Salidas y Proyección, o bien Calificacion personal)
• Calificacion personal, Rating o Puntuación (0 a 10; se ajusta si viene fuera de rango)
• Precio o Price
• Reponer (SI / -)
• Proyeccion
• Duracion
• Perfil
• Ropa
• Dia/Noche
• Frio/Calor
• Playa
• Salidas, Oficina, Familiar (SI / -)
• Proveedor
• Link
• Vitrina
• Top Coleccion / Top collection
• Salida, Corazon, Fondo (notas; varias separadas por comas)
• Descripcion o Description
• Imagen o Image (ruta en el dispositivo)

Si la hoja solo tiene columnas mínimas: además de Nombre y Marca puede usar Precio, Vitrina, Imagen y Descripcion.

Validación al importar: nota 0–10, precios negativos ignorados, textos y listas acotados en longitud/cantidad, archivos mayores a 20 MB rechazados.
''';

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    const dash = 6.0;
    const gap = 4.0;
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = d + dash;
        canvas.drawPath(
          metric.extractPath(d, next.clamp(0, metric.length)),
          paint,
        );
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
