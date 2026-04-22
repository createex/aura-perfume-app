import '../../domain/perfume/perfume.dart';

/// Normalizes values read from Excel before writing to the local SQLite DB.
/// Import never touches the network; this only guards the on-device catalog.
class PerfumeImportSanitize {
  PerfumeImportSanitize._();

  static const maxId = 128;
  static const maxBrandOrName = 200;
  static const maxSheetText = 500;
  static const maxDescription = 8000;
  static const maxPathOrUrl = 2048;
  static const maxListItems = 48;
  static const maxListItemLen = 120;

  static const maxFileBytes = 20 * 1024 * 1024;

  static String _trunc(String s, int max) {
    if (s.length <= max) return s;
    return s.substring(0, max);
  }

  static String? _opt(String? s, int max) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty || t == '-') return null;
    return _trunc(t, max);
  }

  static double clampRating0to10(double r) {
    if (r.isNaN || r.isInfinite) return 0;
    return r.clamp(0.0, 10.0);
  }

  static double? normalizePrice(double? p) {
    if (p == null || p.isNaN || p.isInfinite) return null;
    if (p < 0) return null;
    const cap = 1e7;
    return p > cap ? cap : p;
  }

  static List<String> _stringList(List<String> raw) {
    return raw
        .map((e) => _trunc(e.trim(), maxListItemLen))
        .where((e) => e.isNotEmpty)
        .take(maxListItems)
        .toList(growable: false);
  }

  /// Returns `null` if brand or name is empty after normalization (row should be skipped).
  static Perfume? apply(Perfume p) {
    final brand = _trunc(p.brand.trim(), maxBrandOrName);
    final name = _trunc(p.name.trim(), maxBrandOrName);
    if (brand.isEmpty || name.isEmpty) return null;

    final id = _trunc(p.id.trim(), maxId);
    final safeId = id.isEmpty ? 'imp_${Object.hash(brand, name)}' : id;

    return Perfume(
      id: safeId,
      brand: brand,
      name: name,
      rating: clampRating0to10(p.rating),
      description: _opt(p.description, maxDescription),
      price: normalizePrice(p.price),
      origin: _opt(p.origin, maxSheetText),
      year: _opt(p.year, maxSheetText),
      occasions: _stringList(p.occasions),
      styles: _stringList(p.styles),
      notesTop: _stringList(p.notesTop),
      notesHeart: _stringList(p.notesHeart),
      notesBase: _stringList(p.notesBase),
      imagePath: _opt(p.imagePath, maxPathOrUrl),
      vitrina: _opt(p.vitrina, maxSheetText),
      reponer: _opt(p.reponer, maxSheetText),
      proyeccion: _opt(p.proyeccion, maxSheetText),
      duracion: _opt(p.duracion, maxSheetText),
      diaNoche: _opt(p.diaNoche, maxSheetText),
      frioCalor: _opt(p.frioCalor, maxSheetText),
      playaRaw: _opt(p.playaRaw, maxSheetText),
      link: _opt(p.link, maxPathOrUrl),
      profile: _opt(p.profile, maxSheetText),
      clothing: _opt(p.clothing, maxSheetText),
      supplier: _opt(p.supplier, maxSheetText),
      topCollection: p.topCollection,
      beach: p.beach,
      outings: p.outings,
      office: p.office,
      family: p.family,
      refillNeeded: p.refillNeeded,
    );
  }
}
