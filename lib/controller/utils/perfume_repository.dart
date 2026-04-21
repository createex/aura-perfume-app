import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/perfume/perfume.dart';
import 'app_log.dart';
import 'perfume_store.dart';
import 'perfume_xlsx_exporter.dart';

class PerfumeRepository {
  final PerfumeStore _store;
  final _uuid = const Uuid();

  PerfumeRepository(this._store);

  Future<List<Perfume>> getAll() async {
    AppLog.catalog('PerfumeRepository.getAll: start');
    final list = await _store.load();
    AppLog.catalog('PerfumeRepository.getAll: done', {'count': list.length});
    return list;
  }

  /// Writes the full catalog in one SQLite transaction (used for bulk import).
  Future<void> saveFullCatalog(List<Perfume> perfumes) async {
    AppLog.catalog(
      'PerfumeRepository.saveFullCatalog: start',
      {'count': perfumes.length},
    );
    await _store.save(perfumes);
    AppLog.catalog('PerfumeRepository.saveFullCatalog: committed');
  }

  Future<void> upsert(Perfume perfume) async {
    AppLog.catalog(
      'PerfumeRepository.upsert: start',
      AppLog.perfumeSummaryDetailed(perfume),
    );
    final all = await _store.load();
    final idx = all.indexWhere((p) => p.id == perfume.id);
    final next = [...all];
    final isUpdate = idx >= 0;
    if (isUpdate) {
      next[idx] = perfume;
    } else {
      next.add(perfume);
    }
    await _store.save(next);
    AppLog.catalog(
      'PerfumeRepository.upsert: done',
      {
        'totalAfter': next.length,
        'operation': isUpdate ? 'update' : 'insert',
      },
    );
  }

  Future<Perfume> create({
    required String brand,
    required String name,
    double rating = 0,
    String? imagePath,
  }) async {
    AppLog.catalog(
      'PerfumeRepository.create: start',
      {'brand': brand, 'name': name, 'rating': rating},
    );
    final perfume = Perfume(
      id: _uuid.v4(),
      brand: brand,
      name: name,
      rating: rating,
      imagePath: imagePath,
    );
    await upsert(perfume);
    AppLog.catalog(
      'PerfumeRepository.create: done',
      AppLog.perfumeSummary(perfume),
    );
    return perfume;
  }

  Future<void> deleteById(String id) async {
    AppLog.catalog('PerfumeRepository.deleteById: start', {'id': id});
    final all = await _store.load();
    final before = all.length;
    final filtered = all.where((p) => p.id != id).toList(growable: false);
    await _store.save(filtered);
    AppLog.catalog(
      'PerfumeRepository.deleteById: done',
      {'id': id, 'before': before, 'after': filtered.length},
    );
  }

  /// Writes the full catalog to app documents as `.xlsx` (sheet **VITRINA**).
  /// Returns the absolute file path.
  Future<String> exportToDocumentsDirectory() async {
    AppLog.io('PerfumeRepository.exportToDocumentsDirectory: start');
    final all = await _store.load();
    final bytes = PerfumeXlsxExporter.buildBytes(all);
    if (bytes == null) {
      AppLog.warning('PerfumeRepository.export: encoder returned no bytes');
      throw StateError('Could not build Excel file.');
    }
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'perfumes_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final path = p.join(dir.path, fileName);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    AppLog.io(
      'PerfumeRepository.exportToDocumentsDirectory: wrote file',
      {
        'path': path,
        'bytes': bytes.length,
        'rows': all.length,
      },
    );
    return path;
  }
}
