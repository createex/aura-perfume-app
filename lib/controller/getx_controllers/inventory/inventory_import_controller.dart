import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../utils/app_log.dart';
import '../../utils/perfume_import_sanitize.dart';
import '../../utils/perfume_repository.dart';
import '../../utils/perfume_xlsx_parser.dart';
import '../perfume/perfume_controller.dart';
import '../../../domain/perfume/perfume.dart';

class InventoryImportController extends GetxController {
  InventoryImportController(this._repo);
  final PerfumeRepository _repo;

  final importing = false.obs;
  final exporting = false.obs;
  final resetting = false.obs;
  final progress = 0.0.obs;
  final status = ''.obs;
  final error = RxnString();
  final successMessage = RxnString();
  final exportSuccessPath = RxnString();

  Future<void> pickAndImportExcel() async {
    AppLog.tap('InventoryImport', 'Select file (.xlsx)');
    if (resetting.value) {
      AppLog.action('InventoryImport: pick ignored (reset in progress)');
      return;
    }
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
    if (resetting.value) {
      AppLog.action('InventoryExport: ignored (reset in progress)');
      return;
    }
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

  /// Clears every perfume row from local SQLite (same path as a full import of an empty file).
  Future<void> deleteAllCatalog() async {
    if (resetting.value || importing.value || exporting.value) return;
    AppLog.action('InventoryImport: deleteAllCatalog');
    resetting.value = true;
    error.value = null;
    try {
      await _repo.saveFullCatalog(const <Perfume>[]);
      successMessage.value = null;
      exportSuccessPath.value = null;
      await _refreshCatalog();
      Get.snackbar(
        'Catálogo',
        'Se eliminaron todos los registros.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, st) {
      AppLog.warning('InventoryImport: deleteAllCatalog failed', '$e\n$st');
      error.value = 'No se pudo vaciar el catálogo: $e';
    } finally {
      resetting.value = false;
    }
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
      if (bytes.length > PerfumeImportSanitize.maxFileBytes) {
        throw Exception('El archivo supera el límite de 20 MB.');
      }
      AppLog.catalog(
        'InventoryImport: merge into local SQLite only (no network)',
        {'bytes': bytes.length},
      );
      AppLog.catalog('InventoryImport: loading existing catalog from DB');
      final existing = await _repo.getAll();
      AppLog.catalog(
        'InventoryImport: existing catalog loaded',
        {'existingCount': existing.length},
      );
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
        var dupInFile = 0;
        var updated = 0;
        var added = 0;
        final seenInFile = <String>{};

        final out = List<Perfume>.from(existing);
        final keyToIndex = <String, int>{};
        for (var i = 0; i < out.length; i++) {
          final k = _keyOf(out[i].brand, out[i].name);
          if (k.isNotEmpty) keyToIndex[k] = i;
        }

        for (var i = 0; i < parsed.length; i++) {
          final incoming = parsed[i];
          final k = _keyOf(incoming.brand, incoming.name);
          if (k.isEmpty) continue;
          if (seenInFile.contains(k)) {
            dupInFile++;
            continue;
          }
          seenInFile.add(k);
          progress.value = totalFound == 0 ? 1 : (i + 1) / totalFound;

          final idx = keyToIndex[k];
          if (idx != null) {
            out[idx] = _mergeVitrinaRow(out[idx], incoming);
            updated++;
          } else {
            out.add(incoming);
            keyToIndex[k] = out.length - 1;
            added++;
          }
        }

        status.value = 'Guardando en base de datos…';
        progress.value = 0.35;
        AppLog.catalog(
          'InventoryImport: bulk saveFullCatalog (merge)',
          {
            'before': existing.length,
            'after': out.length,
            'dupInFile': dupInFile,
            'updated': updated,
            'added': added,
          },
        );
        await _repo.saveFullCatalog(out);
        progress.value = 1;

        status.value = '';
        final msg =
            'Records found: $totalFound • Duplicate rows in file: $dupInFile • Updated: $updated • Added: $added';
        successMessage.value = msg;
        Get.snackbar('Import summary', msg, snackPosition: SnackPosition.BOTTOM);
        AppLog.catalog(
          'InventoryImport: VITRINA/CAJÓN path succeeded',
          {
            'recordsFound': totalFound,
            'dupInFile': dupInFile,
            'updated': updated,
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
      var dupInFile = 0;
      var updated = 0;
      var added = 0;
      final seenInFile = <String>{};

      final out = List<Perfume>.from(existing);
      final keyToIndex = <String, int>{};
      for (var i = 0; i < out.length; i++) {
        final k = _keyOf(out[i].brand, out[i].name);
        if (k.isNotEmpty) keyToIndex[k] = i;
      }

      var rowIdx = 0;
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
        if (seenInFile.contains(k)) {
          dupInFile++;
          continue;
        }
        seenInFile.add(k);
        rowIdx++;
        progress.value = total == 0 ? 1 : rowIdx / total;

        final raw = Perfume(
          id: '${brand.toLowerCase()}-${name.toLowerCase()}'
              .replaceAll(' ', '-')
              .replaceAll(RegExp(r'[^a-z0-9\-]'), ''),
          brand: brand,
          name: name,
          rating: PerfumeImportSanitize.clampRating0to10(rating),
          imagePath: (imagePath?.isEmpty ?? true) ? null : imagePath,
        );
        final incoming = PerfumeImportSanitize.apply(raw);
        if (incoming == null) continue;

        final idx = keyToIndex[k];
        if (idx != null) {
          out[idx] = _mergeMinimalRow(out[idx], incoming);
          updated++;
        } else {
          out.add(incoming);
          keyToIndex[k] = out.length - 1;
          added++;
        }
      }

      status.value = 'Guardando en base de datos…';
      AppLog.catalog(
        'InventoryImport: fallback bulk saveFullCatalog (merge)',
        {
          'sheet': sheetName,
          'rowsAfter': out.length,
          'dupInFile': dupInFile,
          'updated': updated,
          'added': added,
        },
      );
      await _repo.saveFullCatalog(out);

      status.value = '';
      final msg =
          'Records found: $recordsFound • Duplicate rows in file: $dupInFile • Updated: $updated • Added: $added';
      successMessage.value = msg;
      Get.snackbar('Import summary', msg, snackPosition: SnackPosition.BOTTOM);
      AppLog.catalog(
        'InventoryImport: fallback sheet import finished',
        {
          'recordsFound': recordsFound,
          'dupInFile': dupInFile,
          'updated': updated,
          'added': added,
          'sheet': sheetName,
          'elapsedMs': DateTime.now().difference(t0).inMilliseconds,
        },
      );
      await _refreshCatalog();
    } catch (e, st) {
      var msg = '$e';
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring('Exception: '.length).trim();
      }
      error.value = msg.isEmpty
          ? 'Error al leer la hoja VITRINA o el formato del archivo. Intente de nuevo.'
          : msg;
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

  static String? _preferIncomingImage(String? oldPath, String? incoming) {
    if (incoming != null && incoming.trim().isNotEmpty) {
      return incoming.trim();
    }
    return oldPath;
  }

  static Perfume _mergeVitrinaRow(Perfume existing, Perfume incoming) {
    return incoming.copyWith(
      id: existing.id,
      imagePath: _preferIncomingImage(existing.imagePath, incoming.imagePath),
    );
  }

  static Perfume _mergeMinimalRow(Perfume existing, Perfume incoming) {
    return existing.copyWith(
      brand: incoming.brand,
      name: incoming.name,
      rating: incoming.rating,
      imagePath: _preferIncomingImage(existing.imagePath, incoming.imagePath),
    );
  }
}
