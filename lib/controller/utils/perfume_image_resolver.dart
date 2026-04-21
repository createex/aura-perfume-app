import 'package:flutter/services.dart';

import '../../domain/perfume/perfume.dart';
import 'app_log.dart';

/// Resuelve `assets/pngs/...` comparando nombre de archivo con marca + nombre del perfume.
///
/// Usa [AssetManifest.loadFromAssetBundle] (compatible con `AssetManifest.bin`; el antiguo
/// `AssetManifest.json` ya no se genera en builds recientes de Flutter).
class PerfumeImageResolver {
  PerfumeImageResolver._();
  static final PerfumeImageResolver instance = PerfumeImageResolver._();

  List<String>? _paths;
  Future<void>? _loading;

  /// Raster asset paths under `assets/pngs/` used for filename matching (diagnostics).
  int get indexedRasterAssetCount => _paths?.length ?? 0;

  Future<void> ensureLoaded() {
    _loading ??= _load();
    return _loading!;
  }

  Future<void> _load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _paths = manifest
          .listAssets()
          .where((k) => k.startsWith('assets/pngs/'))
          .where((k) {
            final l = k.toLowerCase();
            return l.endsWith('.png') ||
                l.endsWith('.jpg') ||
                l.endsWith('.jpeg') ||
                l.endsWith('.webp');
          })
          .where((k) => !k.toLowerCase().contains('placeholder'))
          .toList(growable: false);
      AppLog.catalog(
        'PerfumeImageResolver ready',
        {'indexedRasterAssets': _paths!.length},
      );
    } catch (e, _) {
      _paths = const [];
      AppLog.warning('PerfumeImageResolver could not load asset manifest', e);
    }
  }

  /// Mejor coincidencia para mostrar en UI; no persiste en disco por sí solo.
  String? matchFor(Perfume p) {
    final paths = _paths;
    if (paths == null || paths.isEmpty) return null;

    String? bestPath;
    var best = 0;
    for (final path in paths) {
      final stem = _stemForMatch(path);
      if (stem.length < 4) continue;
      final s = _score(stem, p.brand, p.name);
      if (s > best) {
        best = s;
        bestPath = path;
      }
    }
    // Umbral: evita asignar un PNG equivocado por una sola palabra corta.
    if (best < 14) return null;
    return bestPath;
  }

  static String _norm(String s) {
    return s
        .toLowerCase()
        .replaceAll("'", '')
        .replaceAll('\u2019', '')
        .replaceAll(RegExp(r'[^a-z0-9áéíóúüñ]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _stemForMatch(String assetPath) {
    var name = assetPath.split('/').last;
    name = name.replaceAll(
        RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false), '');
    // Sufijos típicos de tarjetas Fragrantica / catálogos
    name = name.replaceAll(
      RegExp(
        r'-(for-women-and-men|for-women|for-men|unisex)(-perfume-card.*)?$',
        caseSensitive: false,
      ),
      '',
    );
    name = name.replaceAll(
        RegExp(r'-perfume(-card)?.*$', caseSensitive: false), '');
    name = name.replaceAll('_', ' ').replaceAll('-', ' ');
    return _norm(name);
  }

  static int _score(String stem, String brand, String name) {
    final b = _norm(brand);
    final n = _norm(name);
    if (b.isEmpty && n.isEmpty) return 0;

    final stemCompact = stem.replaceAll(' ', '');
    var s = 0;

    final nCompact = n.replaceAll(' ', '');
    if (nCompact.length > 5 && stemCompact.contains(nCompact)) {
      s += 48;
    }
    if (n.length > 5 && stem.contains(n)) {
      s += 40;
    }

    for (final w in n.split(' ').where((x) => x.length > 2)) {
      if (stem.contains(w)) s += 14;
      if (stemCompact.contains(w.replaceAll(' ', ''))) s += 10;
    }

    for (final w in b.split(' ').where((x) => x.length > 2)) {
      if (stem.contains(w)) s += 10;
    }

    // Marca pegada al nombre en muchos archivos (ej. ...-CREED-...)
    final merged = _norm('$brand$name').replaceAll(' ', '');
    if (merged.length > 8 && stemCompact.contains(merged)) {
      s += 25;
    }

    return s;
  }
}
