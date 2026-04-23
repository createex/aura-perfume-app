import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';

void main(List<String> args) async {
  final path = args.isEmpty ? r'C:\Users\muham\Downloads\Perfumes.xlsx' : args[0];
  final f = File(path);
  if (!await f.exists()) {
    stderr.writeln('File not found: $path');
    exitCode = 2;
    return;
  }
  final bytes = Uint8List.fromList(await f.readAsBytes());
  final excel = Excel.decodeBytes(bytes);
  final sheets = excel.tables.keys.toList()..sort();
  stdout.writeln('Workbook sheets (${sheets.length}): ${sheets.join(', ')}');

  int countNonEmptyRowPairs(Sheet sheet) {
    if (sheet.rows.isEmpty) return 0;
    final header = sheet.rows.first
        .map((c) => (c?.value?.toString() ?? '').trim().toLowerCase())
        .toList(growable: false);
    int colOf(List<String> names) {
      for (final n in names) {
        final i = header.indexWhere((h) => h == n);
        if (i >= 0) return i;
      }
      return -1;
    }

    final idxName = colOf(['nombre', 'name']);
    final idxBrand = colOf(['marca', 'brand']);
    if (idxName < 0 || idxBrand < 0) return 0;

    String cell(List<Data?> row, int idx) {
      if (idx < 0 || idx >= row.length) return '';
      return (row[idx]?.value?.toString() ?? '').trim();
    }

    var n = 0;
    for (var r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      final name = cell(row, idxName);
      final brand = cell(row, idxBrand);
      if (name.isNotEmpty && brand.isNotEmpty) n++;
    }
    return n;
  }

  for (final name in sheets) {
    final sheet = excel.tables[name];
    if (sheet == null) continue;
    final headerPreview = sheet.rows.isEmpty
        ? const <String>[]
        : sheet.rows.first
            .take(8)
            .map((c) => (c?.value?.toString() ?? '').trim())
            .toList(growable: false);
    final nonEmptyPairs = countNonEmptyRowPairs(sheet);
    stdout.writeln(
      '[$name] rows=${sheet.rows.length} nonEmpty(brand+name)=$nonEmptyPairs headerPreview=$headerPreview',
    );
  }
}

