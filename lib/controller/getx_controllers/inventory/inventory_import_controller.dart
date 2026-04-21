import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../utils/app_log.dart';
import '../../utils/perfume_repository.dart';
import '../../utils/perfume_xlsx_parser.dart';
import '../perfume/perfume_controller.dart';
import '../../../domain/perfume/perfume.dart';

class InventoryImportController extends GetxController {
  InventoryImportController(this._repo);
  final PerfumeRepository _repo;

  final importing = false.obs;
  final exporting = false.obs;
  final progress = 0.0.obs;
  final status = ''.obs;
  final error = RxnString();
  final successMessage = RxnString();
  final exportSuccessPath = RxnString();

  Future<void> pickAndImportExcel() async {
    AppLog.tap('InventoryImport', 'Select file (.xlsx)');
    error.value = null;
    successMessage.value = null;
    exportSuccessPath.value = null;
    status.value = 'Selecciona el archivo Excel…';
    AppLog.io('InventoryImport: opening file picker');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      AppLog.action('InventoryImport: file picker closed with no selection');
      return;
    }
    final picked = result.files.first;
    final bytes = picked.bytes;
    AppLog.catalog(
      'InventoryImport: file picked',
      {
        'name': picked.name,
        'sizeBytes': bytes?.length ?? -1,
        'path': picked.path ?? '(in-memory only)',
      },
    );
    if (bytes == null) {
      error.value = 'No pude leer el archivo seleccionado.';
      AppLog.warning(
        'InventoryImport: picked file has no in-memory bytes',
        picked.name,
      );
      return;
    }
    await importFromXlsxBytes(bytes);
  }

  Future<void> exportCatalogToExcel() async {
    AppLog.tap('InventoryImport', 'Export catalog to .xlsx (app documents)');
    if (exporting.value) {
      AppLog.action('InventoryExport: ignored (already running)');
      return;
    }
    error.value = null;
    exportSuccessPath.value = null;
    exporting.value = true;
    status.value = 'Generando Excel…';
    try {
      AppLog.io('InventoryExport: requesting repository export');
      final path = await _repo.exportToDocumentsDirectory();
      exportSuccessPath.value = path;
      status.value = '';
      AppLog.io('InventoryExport: success', {'path': path});
      Get.snackbar(
        'Exportación',
        'Archivo guardado en documentos de la app:\n$path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e, st) {
      AppLog.warning('InventoryExport failed', '$e\n$st');
      error.value = 'No se pudo exportar: $e';
      status.value = '';
    } finally {
      exporting.value = false;
      AppLog.action('InventoryExport: finished');
    }
  }

  void dismissSuccess() {
    AppLog.tap('InventoryImport', 'Dismiss success message');
    successMessage.value = null;
  }

  void dismissExportSuccess() {
    AppLog.tap('InventoryImport', 'Dismiss export path message');
    exportSuccessPath.value = null;
  }

  Future<void> _refreshCatalog() async {
    if (Get.isRegistered<PerfumeController>()) {
      AppLog.catalog('InventoryImport: refreshing PerfumeController catalog');
      await Get.find<PerfumeController>().refreshPerfumes();
    } else {
      AppLog.warning(
        'InventoryImport: PerfumeController not registered, skip refresh',
      );
    }
  }

  Future<void> importFromXlsxBytes(Uint8List bytes) async {
    final t0 = DateTime.now();
    AppLog.catalog(
      'InventoryImport: importFromXlsxBytes started',
      {'byteLength': bytes.length},
    );
    importing.value = true;
    progress.value = 0;
    status.value = 'Leyendo archivo…';
    error.value = null;
    successMessage.value = null;
    exportSuccessPath.value = null;

    try {
      AppLog.catalog('InventoryImport: loading existing catalog from DB');
      final existing = await _repo.getAll();
      AppLog.catalog(
        'InventoryImport: existing catalog loaded',
        {'existingCount': existing.length},
      );
      final existingKeys = existing
          .map((p) => _keyOf(p.brand, p.name))
          .where((k) => k.isNotEmpty)
          .toSet();

      AppLog.catalog('InventoryImport: decoding Excel with package:excel');
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        throw Exception('El archivo no contiene hojas.');
      }
      AppLog.catalog(
        'InventoryImport: workbook decoded',
        {
          'tableCount': excel.tables.length,
          'tableKeys': excel.tables.keys.join(', '),
        },
      );

      final parsed = PerfumeXlsxParser.parseWorkbook(excel);
      if (parsed.isNotEmpty) {
        final totalFound = parsed.length;
        var duplicates = 0;
        final toInsert = <Perfume>[];
        final seenInFile = <String>{};

        for (final perfume in parsed) {
          final k = _keyOf(perfume.brand, perfume.name);
          if (k.isEmpty) continue;
          if (existingKeys.contains(k) || seenInFile.contains(k)) {
            duplicates++;
            continue;
          }
          seenInFile.add(k);
          existingKeys.add(k);
          toInsert.add(perfume);
        }

        final newFound = toInsert.length;
        AppLog.catalog(
          'InventoryImport: VITRINA-style parse + duplicate filter',
          {
            'parsedRows': totalFound,
            'duplicates': duplicates,
            'newRows': newFound,
          },
        );

        if (toInsert.isEmpty) {
          status.value = '';
          final msg =
              'Records found: $totalFound • Duplicates: $duplicates • New: 0 • Added: 0';
          successMessage.value = msg;
          AppLog.catalog('InventoryImport: nothing to insert after dedupe');
          Get.snackbar('Import summary', msg, snackPosition: SnackPosition.BOTTOM);
          await _refreshCatalog();
          return;
        }

        status.value = 'Guardando en base de datos…';
        progress.value = 0.35;
        final merged = [...existing, ...toInsert];
        AppLog.catalog(
          'InventoryImport: bulk saveFullCatalog',
          {
            'before': existing.length,
            'inserting': toInsert.length,
            'after': merged.length,
          },
        );
        await _repo.saveFullCatalog(merged);
        progress.value = 1;

        status.value = '';
        final added = toInsert.length;
        final msg =
            'Records found: $totalFound • Duplicates: $duplicates • New: $newFound • Added: $added';
        successMessage.value = msg;
        Get.snackbar('Import summary', msg, snackPosition: SnackPosition.BOTTOM);
        AppLog.catalog(
          'InventoryImport: VITRINA/CAJÓN path succeeded',
          {
            'recordsFound': totalFound,
            'duplicates': duplicates,
            'newFound': newFound,
            'added': added,
            'elapsedMs': DateTime.now().difference(t0).inMilliseconds,
          },
        );
        await _refreshCatalog();
        return;
      }

      AppLog.catalog(
        'InventoryImport: VITRINA parser returned empty, trying minimal sheet import',
      );

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('La hoja está vacía.');
      }

      final header = sheet.rows.first
          .map((c) => (c?.value?.toString() ?? '').trim().toLowerCase())
          .toList();

      int colOf(String name) => header.indexWhere((h) => h == name);

      final idxBrand = colOf('brand') >= 0 ? colOf('brand') : colOf('marca');
      final idxName = colOf('name') >= 0 ? colOf('name') : colOf('nombre');
      final idxRating =
          colOf('rating') >= 0 ? colOf('rating') : colOf('puntuación');
      final idxImage = colOf('image') >= 0 ? colOf('image') : colOf('imagen');

      if (idxBrand < 0 || idxName < 0) {
        throw Exception(
            'Faltan columnas o no existe la hoja VITRINA con el formato esperado.');
      }

      final total = (sheet.rows.length - 1).clamp(0, 1 << 30);
      var recordsFound = 0;
      var duplicates = 0;
      var newFound = 0;
      final seenInFile = <String>{};
      final newPerfumes = <Perfume>[];

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        final brand = _cell(row, idxBrand);
        final name = _cell(row, idxName);
        if (brand.isEmpty || name.isEmpty) continue;
        recordsFound++;

        final ratingRaw = idxRating >= 0 ? _cell(row, idxRating) : '';
        final rating = double.tryParse(ratingRaw.replaceAll(',', '.')) ?? 0;
        final imagePath = idxImage >= 0 ? _cell(row, idxImage) : null;

        final k = _keyOf(brand, name);
        if (k.isEmpty) continue;
        if (existingKeys.contains(k) || seenInFile.contains(k)) {
          duplicates++;
          continue;
        }
        existingKeys.add(k);
        seenInFile.add(k);
        newFound++;

        newPerfumes.add(
          Perfume(
            id: '${brand.toLowerCase()}-${name.toLowerCase()}'
                .replaceAll(' ', '-')
                .replaceAll(RegExp(r'[^a-z0-9\-]'), ''),
            brand: brand,
            name: name,
            rating: rating,
            imagePath: (imagePath?.isEmpty ?? true) ? null : imagePath,
          ),
        );
        progress.value = total == 0 ? 1 : newPerfumes.length / total;
      }

      if (newPerfumes.isNotEmpty) {
        status.value = 'Guardando en base de datos…';
        final merged = [...existing, ...newPerfumes];
        AppLog.catalog(
          'InventoryImport: fallback bulk saveFullCatalog',
          {
            'sheet': sheetName,
            'newRows': newPerfumes.length,
            'totalAfter': merged.length,
          },
        );
        await _repo.saveFullCatalog(merged);
      }

      status.value = '';
      final added = newPerfumes.length;
      final msg =
          'Records found: $recordsFound • Duplicates: $duplicates • New: $newFound • Added: $added';
      successMessage.value = msg;
      Get.snackbar('Import summary', msg, snackPosition: SnackPosition.BOTTOM);
      AppLog.catalog(
        'InventoryImport: fallback sheet import finished',
        {
          'recordsFound': recordsFound,
          'duplicates': duplicates,
          'newFound': newFound,
          'added': added,
          'sheet': sheetName,
          'elapsedMs': DateTime.now().difference(t0).inMilliseconds,
        },
      );
      await _refreshCatalog();
    } catch (e, st) {
      error.value =
          'Error al leer la hoja VITRINA o el formato del archivo. Intente de nuevo.';
      status.value = '';
      AppLog.warning('InventoryImport: import failed', '$e\n$st');
    } finally {
      importing.value = false;
      AppLog.action(
        'InventoryImport: importFromXlsxBytes finished',
        {'elapsedMs': DateTime.now().difference(t0).inMilliseconds},
      );
    }
  }

  String _cell(List<Data?> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return (row[idx]?.value?.toString() ?? '').trim();
  }

  static String _keyOf(String brand, String name) {
    final b = brand.trim().toLowerCase();
    final n = name.trim().toLowerCase();
    if (b.isEmpty || n.isEmpty) return '';
    return '$b|$n';
  }
}
