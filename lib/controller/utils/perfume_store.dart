import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/perfume/perfume.dart';
import 'perfume_xlsx_parser.dart';

class PerfumeStore {
  /// New filename so installs that used the old JSON seed pick up bundled Excel.
  static const _fileName = 'perfume_library.json';
  static const _bundledXlsx = 'assets/perfumes_data/Perfumes.xlsx';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<List<Perfume>> load() async {
    final f = await _file();
    if (!await f.exists()) {
      final fromExcel = await _loadBundledExcel();
      await save(fromExcel);
      return fromExcel;
    }

    final raw = await f.readAsString();
    if (raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Perfume.fromMap)
        .toList(growable: false);
  }

  Future<void> save(List<Perfume> perfumes) async {
    final f = await _file();
    final raw = jsonEncode(perfumes.map((e) => e.toMap()).toList());
    await f.writeAsString(raw);
  }

  Future<List<Perfume>> _loadBundledExcel() async {
    try {
      final data = await rootBundle.load(_bundledXlsx);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      return PerfumeXlsxParser.parseBytes(bytes);
    } catch (_) {
      return const [];
    }
  }
}

