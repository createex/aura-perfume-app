import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/perfume/perfume.dart';
import 'app_log.dart';
import 'perfume_import_sanitize.dart';

/// Reads the bundled inventory layout (sheets [VITRINA], [CAJON]) and optional
/// English-header imports used by [InventoryImportController].
class PerfumeXlsxParser {
  PerfumeXlsxParser._();

  static List<Perfume> parseBytes(Uint8List bytes) {
    AppLog.catalog(
      'PerfumeXlsxParser.parseBytes: decoding workbook',
      {'byteLength': bytes.length},
    );
    final excel = Excel.decodeBytes(bytes);
    return parseWorkbook(excel);
  }

  static List<Perfume> parseWorkbook(Excel excel) {
    final keys = excel.tables.keys.toList(growable: false)
      ..sort(_sheetRank);
    AppLog.catalog(
      'PerfumeXlsxParser.parseWorkbook: sheets discovered',
      {
        'sheetCount': keys.length,
        'sheetNames': keys.join(', '),
      },
    );
    final byKey = <String, Perfume>{};

    for (final sheetName in keys) {
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) continue;
      final headerRow = sheet.rows.first;
      final header = _headerMap(headerRow);
      if (!_has(header, 'nombre') && !_has(header, 'name')) continue;
      if (!_has(header, 'marca') && !_has(header, 'brand')) continue;

      final full = _isVitrinaStyle(header);
      for (var r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        final p = full
            ? _fromVitrinaRow(sheetName, r, row, header)
            : _fromMinimalRow(sheetName, r, row, header);
        if (p == null) continue;
        final sanitized = PerfumeImportSanitize.apply(p);
        if (sanitized == null) continue;
        final k =
            '${sanitized.brand.toLowerCase()}|${sanitized.name.toLowerCase()}';
        if (byKey.containsKey(k)) continue;
        byKey[k] = sanitized;
      }
    }

    AppLog.catalog(
      'PerfumeXlsxParser.parseWorkbook: complete',
      {
        'uniquePerfumeCount': byKey.length,
        'sheetCount': keys.length,
      },
    );
    return byKey.values.toList(growable: false);
  }

  static int _sheetRank(String a, String b) {
    int rank(String s) {
      final u = s.toUpperCase();
      if (u == 'VITRINA') return 0;
      if (u == 'CAJON') return 1;
      return 2;
    }

    final c = rank(a).compareTo(rank(b));
    if (c != 0) return c;
    return a.compareTo(b);
  }

  static Map<String, int> _headerMap(List<Data?> row) {
    final m = <String, int>{};
    for (var i = 0; i < row.length; i++) {
      final k = (row[i]?.value?.toString() ?? '').trim().toLowerCase();
      if (k.isNotEmpty) m[k] = i;
    }
    return m;
  }

  static bool _has(Map<String, int> h, String k) => h.containsKey(k);

  static bool _isVitrinaStyle(Map<String, int> h) {
    if (_has(h, 'calificacion personal')) return true;
    return _has(h, 'salidas') && _has(h, 'proyeccion');
  }

  static int _col(
    Map<String, int> h,
    List<String> names,
  ) {
    for (final n in names) {
      final i = h[n];
      if (i != null) return i;
    }
    return -1;
  }

  static String _cell(List<Data?> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return (row[idx]?.value?.toString() ?? '').trim();
  }

  static double? _parseDouble(String s) {
    if (s.isEmpty) return null;
    final t = s.replaceAll(',', '.').replaceAll(RegExp(r'[\s\$MXNmxn]'), '');
    return double.tryParse(t);
  }

  static bool _isSi(String v) {
    final u = v.toUpperCase();
    return u == 'SI' || u == 'SÍ' || u == 'YES';
  }

  static String? _field(String v) {
    if (v.isEmpty || v == '-') return null;
    return v;
  }

  static List<String> _splitCommaList(String raw) {
    if (raw.isEmpty || raw == '-') return const [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static String _stableId(String sheet, int row, String brand, String name) {
    final h = Object.hash(sheet, row, brand, name);
    return 'xlsx_${sheet}_${row}_$h';
  }

  static Perfume? _fromVitrinaRow(
    String sheetName,
    int rowIndex,
    List<Data?> row,
    Map<String, int> h,
  ) {
    final name = _cell(row, _col(h, ['nombre', 'name']));
    final brand = _cell(row, _col(h, ['marca', 'brand']));
    if (name.isEmpty || brand.isEmpty) return null;

    final ratingRaw =
        _cell(row, _col(h, ['calificacion personal', 'rating', 'puntuación']));
    final rating = _parseDouble(ratingRaw) ?? 0;

    final price = _parseDouble(_cell(row, _col(h, ['precio', 'price'])));

    final reponer = _cell(row, _col(h, ['reponer']));
    final proyeccion = _cell(row, _col(h, ['proyeccion']));
    final duracion = _cell(row, _col(h, ['duracion']));
    final perfil = _cell(row, _col(h, ['perfil']));
    final ropa = _cell(row, _col(h, ['ropa']));
    final diaNoche = _cell(row, _col(h, ['dia/noche']));
    final frioCalor = _cell(row, _col(h, ['frio/calor']));
    final playa = _cell(row, _col(h, ['playa']));
    final salidas = _cell(row, _col(h, ['salidas']));
    final oficina = _cell(row, _col(h, ['oficina']));
    final familiar = _cell(row, _col(h, ['familiar']));
    final proveedor = _cell(row, _col(h, ['proveedor']));
    final link = _cell(row, _col(h, ['link']));
    final vitrina = _cell(row, _col(h, ['vitrina']));
    final topRaw = _cell(
      row,
      _col(h, [
        'top coleccion',
        'top colección',
        'top collection',
        'top',
      ]),
    );

    final salidaNotes = _cell(row, _col(h, ['salida']));
    final corazonNotes = _cell(row, _col(h, ['corazon', 'corazón']));
    final fondoNotes = _cell(row, _col(h, ['fondo']));
    final descCell = _cell(row, _col(h, ['descripcion', 'description']));
    final imageRaw = _cell(row, _col(h, ['imagen', 'image']));

    final String? description;
    if (descCell.isNotEmpty && descCell != '-') {
      description = descCell.trim();
    } else {
      description = null;
    }

    final occasions = <String>[
      if (_isSi(salidas)) 'Salidas',
      if (_isSi(oficina)) 'Oficina',
      if (_isSi(playa)) 'Playa',
      if (_isSi(familiar)) 'Familiar',
    ];

    final styles = <String>[
      if (perfil.isNotEmpty && perfil != '-') perfil,
      if (ropa.isNotEmpty && ropa != '-') ropa,
    ];

    bool? tri(String v) {
      if (v.isEmpty || v == '-') return null;
      return _isSi(v);
    }

    return Perfume(
      id: _stableId(sheetName, rowIndex, brand, name),
      brand: brand,
      name: name,
      rating: rating,
      description: description,
      price: price,
      origin: proveedor.isEmpty ? null : proveedor,
      supplier: proveedor.isEmpty ? null : proveedor,
      profile: _field(perfil),
      clothing: _field(ropa),
      occasions: occasions,
      styles: styles,
      notesTop: _splitCommaList(salidaNotes),
      notesHeart: _splitCommaList(corazonNotes),
      notesBase: _splitCommaList(fondoNotes),
      vitrina: _field(vitrina),
      reponer: _field(reponer),
      proyeccion: _field(proyeccion),
      duracion: _field(duracion),
      diaNoche: _field(diaNoche),
      frioCalor: _field(frioCalor),
      playaRaw: _field(playa),
      link: link.isEmpty ? null : link,
      imagePath: imageRaw.isEmpty ? null : imageRaw,
      topCollection: topRaw.isEmpty ? null : _isSi(topRaw),
      beach: tri(playa),
      outings: tri(salidas),
      office: tri(oficina),
      family: tri(familiar),
      refillNeeded: tri(reponer),
    );
  }

  static Perfume? _fromMinimalRow(
    String sheetName,
    int rowIndex,
    List<Data?> row,
    Map<String, int> h,
  ) {
    final name = _cell(row, _col(h, ['nombre', 'name']));
    final brand = _cell(row, _col(h, ['marca', 'brand']));
    if (name.isEmpty || brand.isEmpty) return null;

    final ratingRaw =
        _cell(row, _col(h, ['calificacion personal', 'rating', 'puntuación']));
    final rating = _parseDouble(ratingRaw) ?? 0;
    final price = _parseDouble(_cell(row, _col(h, ['precio', 'price'])));
    final vitrina = _cell(row, _col(h, ['vitrina']));
    final imageRaw = _cell(row, _col(h, ['image', 'imagen']));
    final descCell = _cell(row, _col(h, ['descripcion', 'description']));
    final String? description;
    if (descCell.isNotEmpty && descCell != '-') {
      description = descCell.trim();
    } else if (vitrina.isNotEmpty && vitrina != '-') {
      description = 'Ubicación: $vitrina';
    } else {
      description = null;
    }

    return Perfume(
      id: _stableId(sheetName, rowIndex, brand, name),
      brand: brand,
      name: name,
      rating: rating,
      description: description,
      price: price,
      origin: null,
      imagePath: imageRaw.isEmpty ? null : imageRaw,
      vitrina: _field(vitrina),
    );
  }
}
