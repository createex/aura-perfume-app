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
  final progress = 0.0.obs;
  final status = ''.obs;
  final error = RxnString();
  final successMessage = RxnString();

  Future<void> pickAndImportExcel() async {
    AppLog.action('InventoryImport: user tapped Select file (.xlsx)');
    error.value = null;
    successMessage.value = null;
    status.value = 'Selecciona el archivo Excel…';
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

  void dismissSuccess() {
    AppLog.tap('InventoryImport', 'Dismiss success message');
    successMessage.value = null;
  }

  Future<void> _refreshCatalog() async {
    if (Get.isRegistered<PerfumeController>()) {
      await Get.find<PerfumeController>().refreshPerfumes();
    }
  }

  Future<void> importFromXlsxBytes(Uint8List bytes) async {
    AppLog.catalog(
      'InventoryImport: importFromXlsxBytes started',
      {'byteLength': bytes.length},
    );
    importing.value = true;
    progress.value = 0;
    status.value = 'Leyendo archivo…';
    error.value = null;
    successMessage.value = null;

    try {
      final existing = await _repo.getAll();
      final existingKeys = existing
          .map((p) => _keyOf(p.brand, p.name))
          .where((k) => k.isNotEmpty)
          .toSet();

      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        throw Exception('El archivo no contiene hojas.');
      }

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
        var added = 0;
        for (final perfume in toInsert) {
          await _repo.upsert(perfume);
          added++;
          progress.value = totalFound == 0 ? 1 : added / totalFound;
          status.value = 'Importing perfumes…';
        }

        status.value = '';
        final msg =
            'Records found: $totalFound • Duplicates: $duplicates • New: $newFound • Added: $added';
        successMessage.value = msg;
        Get.snackbar('Import summary', msg, snackPosition: SnackPosition.BOTTOM);
        AppLog.catalog(
          'InventoryImport: VITRINA/CAJÓN parse path succeeded',
          {
            'recordsFound': totalFound,
            'duplicates': duplicates,
            'newFound': newFound,
            'added': added,
          },
        );
        await _refreshCatalog();
        return;
      }

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
      var added = 0;
      final seenInFile = <String>{};

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

        final perfume = Perfume(
          id: '${brand.toLowerCase()}-${name.toLowerCase()}'
              .replaceAll(' ', '-')
              .replaceAll(RegExp(r'[^a-z0-9\-]'), ''),
          brand: brand,
          name: name,
          rating: rating,
          imagePath: (imagePath?.isEmpty ?? true) ? null : imagePath,
        );
        await _repo.upsert(perfume);

        added++;
        progress.value = total == 0 ? 1 : added / total;
        status.value = 'Importing perfumes…';
      }

      status.value = '';
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
        },
      );
      await _refreshCatalog();
    } catch (e) {
      error.value =
          'Error al leer la hoja VITRINA o el formato del archivo. Intente de nuevo.';
      status.value = '';
      AppLog.warning('InventoryImport: import failed', e);
    } finally {
      importing.value = false;
      AppLog.action('InventoryImport: importFromXlsxBytes finished');
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
