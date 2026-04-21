import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/perfume/perfume.dart';
import 'app_log.dart';
import 'perfume_xlsx_parser.dart';

/// Local SQLite catalog. Migrates legacy `perfume_library.json` once, then seeds
/// from bundled Excel if the database is still empty.
class PerfumeDatabase {
  PerfumeDatabase._();

  static final PerfumeDatabase instance = PerfumeDatabase._();

  static const _dbName = 'perfumes.db';
  static const _dbVersion = 1;
  static const _legacyJson = 'perfume_library.json';
  static const _bundledXlsx = 'assets/perfumes_data/Perfumes.xlsx';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    AppLog.db('PerfumeDatabase.get database: opening SQLite…');
    _db = await _open();
    AppLog.db('PerfumeDatabase.get database: opened, running seed/migrate…');
    await _ensureSeeded(_db!);
    final n = await _countRows(_db!);
    AppLog.db('PerfumeDatabase.get database: ready', {'rowCount': n});
    return _db!;
  }

  Future<int> _countRows(Database db) async {
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM perfumes'),
        ) ??
        0;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    AppLog.db(
      'PerfumeDatabase._open',
      {'path': path, 'version': _dbVersion},
    );
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        AppLog.db('SQLite onCreate: executing CREATE TABLE perfumes', {
          'version': version,
        });
        await db.execute('''
CREATE TABLE perfumes (
  id TEXT PRIMARY KEY NOT NULL,
  brand TEXT NOT NULL,
  name TEXT NOT NULL,
  rating REAL NOT NULL DEFAULT 0,
  description TEXT,
  price REAL,
  year TEXT,
  origin TEXT,
  image_path TEXT,
  vitrina TEXT,
  reponer TEXT,
  proyeccion TEXT,
  duracion TEXT,
  dia_noche TEXT,
  frio_calor TEXT,
  playa_raw TEXT,
  link TEXT,
  profile TEXT,
  clothing TEXT,
  supplier TEXT,
  top_collection INTEGER,
  beach INTEGER,
  outings INTEGER,
  office INTEGER,
  family INTEGER,
  refill_needed INTEGER,
  notes_top TEXT NOT NULL DEFAULT '[]',
  notes_heart TEXT NOT NULL DEFAULT '[]',
  notes_base TEXT NOT NULL DEFAULT '[]',
  occasions_json TEXT NOT NULL DEFAULT '[]',
  styles_json TEXT NOT NULL DEFAULT '[]'
)
''');
        AppLog.db('SQLite onCreate: table perfumes created');
      },
    );
  }

  Future<void> _ensureSeeded(Database db) async {
    var count = await _countRows(db);
    AppLog.db('_ensureSeeded: initial COUNT(*)', {'count': count});
    if (count > 0) return;

    AppLog.db('_ensureSeeded: empty DB → try legacy JSON migration');
    await _migrateLegacyJsonIfPresent(db);
    count = await _countRows(db);
    AppLog.db('_ensureSeeded: after JSON migration', {'count': count});
    if (count > 0) return;

    AppLog.db('_ensureSeeded: still empty → seed bundled Excel', {
      'asset': _bundledXlsx,
    });
    await _seedBundledExcel(db);
    count = await _countRows(db);
    AppLog.db('_ensureSeeded: after bundled seed', {'count': count});
  }

  Future<void> _migrateLegacyJsonIfPresent(Database db) async {
    final dir = await getApplicationDocumentsDirectory();
    final legacyPath = p.join(dir.path, _legacyJson);
    final legacyFile = File(legacyPath);
    if (!await legacyFile.exists()) {
      AppLog.io('Legacy JSON migration: file not found', {'path': legacyPath});
      return;
    }

    AppLog.io('Legacy JSON migration: reading', {'path': legacyPath});
    try {
      final raw = await legacyFile.readAsString();
      if (raw.trim().isEmpty) {
        AppLog.warning('Legacy JSON migration: file empty, skipping');
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        AppLog.warning(
          'Legacy JSON migration: root is not a List, skipping',
          decoded.runtimeType,
        );
        return;
      }

      var inserted = 0;
      final batch = db.batch();
      for (final item in decoded.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final perfume = Perfume.fromMap(map);
        batch.insert(
          'perfumes',
          _toRow(perfume),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        inserted++;
      }
      await batch.commit(noResult: true);

      final migrated = File('${legacyFile.path}.migrated');
      if (await migrated.exists()) await migrated.delete();
      await legacyFile.rename(migrated.path);
      AppLog.io(
        'Legacy JSON migration: success',
        {'rowsInserted': inserted, 'renamedTo': migrated.path},
      );
    } catch (e, st) {
      AppLog.warning('Legacy JSON migration failed: $e\n$st');
    }
  }

  Future<void> _seedBundledExcel(Database db) async {
    try {
      AppLog.io('Bundled Excel seed: loading asset', {'asset': _bundledXlsx});
      final data = await rootBundle.load(_bundledXlsx);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final list = PerfumeXlsxParser.parseBytes(bytes);
      AppLog.io(
        'Bundled Excel seed: parsed rows',
        {'parsedCount': list.length, 'byteLength': bytes.length},
      );
      if (list.isEmpty) {
        AppLog.warning('Bundled Excel seed: parser returned zero rows');
        return;
      }
      final batch = db.batch();
      for (final perfume in list) {
        batch.insert(
          'perfumes',
          _toRow(perfume),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      AppLog.db('Bundled Excel seed: batch insert committed', {
        'inserted': list.length,
      });
    } catch (e, st) {
      AppLog.warning('Bundled Excel seed failed: $e\n$st');
    }
  }

  static int? _boolToSql(bool? v) {
    if (v == null) return null;
    return v ? 1 : 0;
  }

  static bool? _sqlToBool(Object? v) {
    if (v == null) return null;
    if (v is int) return v != 0;
    if (v is num) return v.toInt() != 0;
    return null;
  }

  static Map<String, Object?> _toRow(Perfume p) {
    return {
      'id': p.id,
      'brand': p.brand,
      'name': p.name,
      'rating': p.rating,
      'description': p.description,
      'price': p.price,
      'year': p.year,
      'origin': p.origin,
      'image_path': p.imagePath,
      'vitrina': p.vitrina,
      'reponer': p.reponer,
      'proyeccion': p.proyeccion,
      'duracion': p.duracion,
      'dia_noche': p.diaNoche,
      'frio_calor': p.frioCalor,
      'playa_raw': p.playaRaw,
      'link': p.link,
      'profile': p.profile,
      'clothing': p.clothing,
      'supplier': p.supplier ?? p.origin,
      'top_collection': _boolToSql(p.topCollection),
      'beach': _boolToSql(p.beach),
      'outings': _boolToSql(p.outings),
      'office': _boolToSql(p.office),
      'family': _boolToSql(p.family),
      'refill_needed': _boolToSql(p.refillNeeded),
      'notes_top': jsonEncode(p.notesTop),
      'notes_heart': jsonEncode(p.notesHeart),
      'notes_base': jsonEncode(p.notesBase),
      'occasions_json': jsonEncode(p.occasions),
      'styles_json': jsonEncode(p.styles),
    };
  }

  static bool? _refillFromReponerText(String? reponer) {
    if (reponer == null || reponer.trim().isEmpty || reponer.trim() == '-') {
      return null;
    }
    final u = reponer.trim().toUpperCase();
    if (u == 'SI' || u == 'SÍ' || u == 'YES') return true;
    return false;
  }

  static bool? _beachFromPlayaRaw(String? playaRaw) {
    if (playaRaw == null || playaRaw.trim().isEmpty || playaRaw == '-') {
      return null;
    }
    final u = playaRaw.trim().toUpperCase();
    if (u == 'SI' || u == 'SÍ' || u == 'YES') return true;
    if (u == 'NO' || u == '-') return false;
    return null;
  }

  /// When only legacy [occasions] tags exist: tag present => true, else false.
  static bool? _flagFromOccasionList(List<String> occasions, String label) {
    final has =
        occasions.any((o) => o.toLowerCase() == label.toLowerCase());
    if (has) return true;
    if (occasions.isEmpty) return null;
    return false;
  }

  static Perfume _fromRow(Map<String, Object?> m) {
    List<String> decodeList(String? raw) {
      if (raw == null || raw.isEmpty) return const [];
      try {
        final d = jsonDecode(raw);
        if (d is List) {
          return d.map((e) => e.toString()).toList(growable: false);
        }
      } catch (_) {}
      return const [];
    }

    final occasions = decodeList(m['occasions_json'] as String?);
    final styles = decodeList(m['styles_json'] as String?);
    final reponer = m['reponer'] as String?;
    final playaRaw = m['playa_raw'] as String?;

    var refillNeeded = _sqlToBool(m['refill_needed']);
    refillNeeded ??= _refillFromReponerText(reponer);

    var beach = _sqlToBool(m['beach']);
    beach ??= _beachFromPlayaRaw(playaRaw);
    beach ??= _flagFromOccasionList(occasions, 'Playa');

    var outings = _sqlToBool(m['outings']);
    outings ??= _flagFromOccasionList(occasions, 'Salidas');

    var office = _sqlToBool(m['office']);
    office ??= _flagFromOccasionList(occasions, 'Oficina');

    var family = _sqlToBool(m['family']);
    family ??= _flagFromOccasionList(occasions, 'Familiar');

    final supplier = m['supplier'] as String?;
    final origin = m['origin'] as String?;

    return Perfume(
      id: (m['id'] ?? '').toString(),
      brand: (m['brand'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      rating: (m['rating'] is num)
          ? (m['rating'] as num).toDouble()
          : double.tryParse('${m['rating'] ?? 0}') ?? 0,
      description: m['description'] as String?,
      price: (m['price'] is num)
          ? (m['price'] as num).toDouble()
          : double.tryParse(m['price']?.toString() ?? ''),
      origin: origin,
      year: m['year'] as String?,
      occasions: occasions,
      styles: styles,
      notesTop: decodeList(m['notes_top'] as String?),
      notesHeart: decodeList(m['notes_heart'] as String?),
      notesBase: decodeList(m['notes_base'] as String?),
      imagePath: m['image_path'] as String?,
      vitrina: m['vitrina'] as String?,
      reponer: reponer,
      proyeccion: m['proyeccion'] as String?,
      duracion: m['duracion'] as String?,
      diaNoche: m['dia_noche'] as String?,
      frioCalor: m['frio_calor'] as String?,
      playaRaw: playaRaw,
      link: m['link'] as String?,
      profile: m['profile'] as String?,
      clothing: m['clothing'] as String?,
      supplier: (supplier != null && supplier.isNotEmpty)
          ? supplier
          : (origin != null && origin.isNotEmpty ? origin : null),
      topCollection: _sqlToBool(m['top_collection']),
      beach: beach,
      outings: outings,
      office: office,
      family: family,
      refillNeeded: refillNeeded,
    );
  }

  Future<List<Perfume>> queryAllOrderedByName() async {
    final db = await database;
    AppLog.db('SQLite.query: SELECT * FROM perfumes ORDER BY LOWER(name)');
    final rows = await db.query(
      'perfumes',
      orderBy: 'LOWER(name) ASC',
    );
    AppLog.db('SQLite.query: result', {'rowCount': rows.length});
    return rows.map((e) => _fromRow(e)).toList(growable: false);
  }

  Future<void> replaceAll(List<Perfume> perfumes) async {
    final db = await database;
    AppLog.db(
      'SQLite.replaceAll: transaction start',
      {'incomingCount': perfumes.length},
    );
    await db.transaction((txn) async {
      final deleted = await txn.delete('perfumes');
      AppLog.db('SQLite.replaceAll: DELETE perfumes', {'deletedRows': deleted});
      final batch = txn.batch();
      for (final p in perfumes) {
        batch.insert(
          'perfumes',
          _toRow(p),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
    final after = await _countRows(db);
    AppLog.db('SQLite.replaceAll: transaction committed', {'rowCount': after});
  }
}
