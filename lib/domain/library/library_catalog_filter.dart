import '../perfume/perfume.dart';

/// Ternary yes/no filter: [any] ignores the field.
enum TriStateFilter {
  any,
  yes,
  no,
}

/// All library facet filters (AND logic). Text fields are case-insensitive contains.
class LibraryCatalogFilter {
  final String vitrinaContains;
  final String nameContains;
  final String brandContains;
  final TriStateFilter refill;
  final TriStateFilter topCollection;
  final TriStateFilter beach;
  final TriStateFilter outings;
  final TriStateFilter office;
  final TriStateFilter family;
  /// 0 = include perfumes with rating 0 (empty Excel / sin calificar).
  final int ratingMin;
  final int ratingMax;
  final double priceMin;
  final double priceMax;
  final Set<String> projections;
  final Set<String> durations;
  final Set<String> profiles;
  final Set<String> suppliers;
  final Set<String> clothing;
  final Set<String> timeOfDay;
  final Set<String> weather;

  const LibraryCatalogFilter({
    this.vitrinaContains = '',
    this.nameContains = '',
    this.brandContains = '',
    this.refill = TriStateFilter.any,
    this.topCollection = TriStateFilter.any,
    this.beach = TriStateFilter.any,
    this.outings = TriStateFilter.any,
    this.office = TriStateFilter.any,
    this.family = TriStateFilter.any,
    this.ratingMin = 0,
    this.ratingMax = 10,
    this.priceMin = 0,
    this.priceMax = _sentinelMaxPrice,
    this.projections = const {},
    this.durations = const {},
    this.profiles = const {},
    this.suppliers = const {},
    this.clothing = const {},
    this.timeOfDay = const {},
    this.weather = const {},
  });

  /// Use when catalog max price is unknown yet.
  static const double _sentinelMaxPrice = 1e12;

  /// Slider / “open” price range when the catalog is empty or max is unknown.
  /// Must match [LibraryCatalogFilter.initial] so opening Filtros never clamps
  /// [priceMax] to \$1 by mistake.
  static double catalogPriceCeiling(double catalogMaxPrice) =>
      catalogMaxPrice > 0 ? catalogMaxPrice : 1000000.0;

  factory LibraryCatalogFilter.initial({required double catalogMaxPrice}) {
    return LibraryCatalogFilter(priceMax: catalogPriceCeiling(catalogMaxPrice));
  }

  bool isActive(double catalogMaxPrice) {
    if (vitrinaContains.trim().isNotEmpty ||
        nameContains.trim().isNotEmpty ||
        brandContains.trim().isNotEmpty) {
      return true;
    }
    if (refill != TriStateFilter.any ||
        topCollection != TriStateFilter.any ||
        beach != TriStateFilter.any ||
        outings != TriStateFilter.any ||
        office != TriStateFilter.any ||
        family != TriStateFilter.any) {
      return true;
    }
    if (ratingMin > 0 || ratingMax < 10) return true;
    final cap = catalogMaxPrice > 0 ? catalogMaxPrice : 1.0;
    if (priceMin > 0.01 || priceMax < cap - 0.01) return true;
    if (projections.isNotEmpty ||
        durations.isNotEmpty ||
        profiles.isNotEmpty ||
        suppliers.isNotEmpty ||
        clothing.isNotEmpty ||
        timeOfDay.isNotEmpty ||
        weather.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// Price facet inactive (full range for current catalog ceiling).
  bool isPriceOpen(double catalogMaxPrice) {
    final cap = catalogMaxPrice > 0 ? catalogMaxPrice : 1.0;
    return priceMin <= 0 && priceMax >= cap - 0.01;
  }

  LibraryCatalogFilter copyWith({
    String? vitrinaContains,
    String? nameContains,
    String? brandContains,
    TriStateFilter? refill,
    TriStateFilter? topCollection,
    TriStateFilter? beach,
    TriStateFilter? outings,
    TriStateFilter? office,
    TriStateFilter? family,
    int? ratingMin,
    int? ratingMax,
    double? priceMin,
    double? priceMax,
    Set<String>? projections,
    Set<String>? durations,
    Set<String>? profiles,
    Set<String>? suppliers,
    Set<String>? clothing,
    Set<String>? timeOfDay,
    Set<String>? weather,
  }) {
    return LibraryCatalogFilter(
      vitrinaContains: vitrinaContains ?? this.vitrinaContains,
      nameContains: nameContains ?? this.nameContains,
      brandContains: brandContains ?? this.brandContains,
      refill: refill ?? this.refill,
      topCollection: topCollection ?? this.topCollection,
      beach: beach ?? this.beach,
      outings: outings ?? this.outings,
      office: office ?? this.office,
      family: family ?? this.family,
      ratingMin: ratingMin ?? this.ratingMin,
      ratingMax: ratingMax ?? this.ratingMax,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      projections: projections ?? this.projections,
      durations: durations ?? this.durations,
      profiles: profiles ?? this.profiles,
      suppliers: suppliers ?? this.suppliers,
      clothing: clothing ?? this.clothing,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      weather: weather ?? this.weather,
    );
  }

  static String _s(String? v) => (v ?? '').trim().toLowerCase();

  static bool _contains(String? hay, String needle) {
    final n = needle.trim().toLowerCase();
    if (n.isEmpty) return true;
    final h = _s(hay);
    if (h.isEmpty) return false;
    return h.contains(n);
  }

  static bool _tri(TriStateFilter rule, bool? v, {bool Function()? stringFallback}) {
    switch (rule) {
      case TriStateFilter.any:
        return true;
      case TriStateFilter.yes:
        if (v != null) return v == true;
        return stringFallback?.call() ?? false;
      case TriStateFilter.no:
        if (v != null) return v == false;
        return !(stringFallback?.call() ?? false);
    }
  }

  static bool _siString(String? raw) {
    final u = _s(raw);
    return u == 'si' || u == 'sí' || u == 'yes';
  }

  bool _refillMatches(Perfume p) {
    return _tri(
      refill,
      p.refillNeeded,
      stringFallback: () => _siString(p.reponer),
    );
  }

  bool _topMatches(Perfume p) {
    return _tri(topCollection, p.topCollection);
  }

  bool _beachMatches(Perfume p) {
    return _tri(
      beach,
      p.beach,
      stringFallback: () => _siString(p.playaRaw),
    );
  }

  bool _outingsMatches(Perfume p) => _tri(outings, p.outings);
  bool _officeMatches(Perfume p) => _tri(office, p.office);
  bool _familyMatches(Perfume p) => _tri(family, p.family);

  bool _ratingMatches(Perfume p) {
    final r = p.rating;
    return r >= ratingMin && r <= ratingMax;
  }

  bool _priceMatches(Perfume p, double catalogMaxPrice) {
    if (isPriceOpen(catalogMaxPrice)) return true;
    final price = p.price;
    if (price == null) return false;
    return price >= priceMin && price <= priceMax;
  }

  bool _setMatchesField(Set<String> selected, String? field) {
    if (selected.isEmpty) return true;
    final f = _s(field);
    if (f.isEmpty) return false;
    for (final s in selected) {
      if (f.contains(_s(s)) || _s(s).contains(f)) return true;
    }
    return false;
  }

  /// `dia` | `noche` | `ambas` | null if unknown
  static String? _bucketTime(String? raw) {
    final v = _s(raw);
    if (v.isEmpty || v == '-') return null;
    if (v.contains('ambas') || v.contains('both')) return 'ambas';
    if (v.contains('noche')) return 'noche';
    if (v.contains('día') || v.contains('dia')) return 'dia';
    return null;
  }

  /// `frio` | `calor` | `ambas` | null
  static String? _bucketWeather(String? raw) {
    final v = _s(raw);
    if (v.isEmpty || v == '-') return null;
    if (v.contains('ambas') || v.contains('both')) return 'ambas';
    if (v.contains('frío') || v.contains('frio') || v.contains('cold')) {
      return 'frio';
    }
    if (v.contains('calor') ||
        v.contains('cálido') ||
        v.contains('calido') ||
        v.contains('caliente')) {
      return 'calor';
    }
    return null;
  }

  bool _timeMatches(Perfume p) {
    if (timeOfDay.isEmpty) return true;
    final b = _bucketTime(p.diaNoche);
    if (b == null) return false;
    for (final t in timeOfDay) {
      final f = _s(t);
      if (f == 'ambas' || f == 'both') {
        if (b == 'ambas') return true;
      } else if (f == 'noche') {
        if (b == 'noche' || b == 'ambas') return true;
      } else if (f == 'día' || f == 'dia' || f == 'day') {
        if (b == 'dia' || b == 'ambas') return true;
      }
    }
    return false;
  }

  bool _weatherMatches(Perfume p) {
    if (weather.isEmpty) return true;
    final b = _bucketWeather(p.frioCalor);
    if (b == null) return false;
    for (final t in weather) {
      final f = _s(t);
      if (f == 'ambas' || f == 'both') {
        if (b == 'ambas') return true;
      } else if (f == 'frío' || f == 'frio' || f == 'cold') {
        if (b == 'frio' || b == 'ambas') return true;
      } else if (f == 'calor' ||
          f == 'cálido' ||
          f == 'calido' ||
          f == 'hot' ||
          f == 'warm') {
        if (b == 'calor' || b == 'ambas') return true;
      }
    }
    return false;
  }

  bool _clothingMatches(Perfume p) {
    if (clothing.isEmpty) return true;
    final v = _s(p.clothing);
    if (v.isEmpty) return false;
    for (final t in clothing) {
      if (v.contains(_s(t))) return true;
    }
    return false;
  }

  /// [searchQuery] is the quick search bar (name OR brand).
  bool matches(
    Perfume p, {
    required String searchQuery,
    required double catalogMaxPrice,
  }) {
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hit = p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q);
      if (!hit) return false;
    }
    if (!_contains(p.vitrina, vitrinaContains)) return false;
    if (!_contains(p.name, nameContains)) return false;
    if (!_contains(p.brand, brandContains)) return false;
    if (!_refillMatches(p)) return false;
    if (!_topMatches(p)) return false;
    if (!_beachMatches(p)) return false;
    if (!_outingsMatches(p)) return false;
    if (!_officeMatches(p)) return false;
    if (!_familyMatches(p)) return false;
    if (!_ratingMatches(p)) return false;
    if (!_priceMatches(p, catalogMaxPrice)) return false;
    if (!_setMatchesField(projections, p.proyeccion)) return false;
    if (!_setMatchesField(durations, p.duracion)) return false;
    if (!_setMatchesField(profiles, p.profile)) return false;
    final sup = p.supplierOrOrigin;
    if (suppliers.isNotEmpty) {
      final s = _s(sup);
      if (s.isEmpty) return false;
      if (!suppliers.any((x) => s == _s(x))) return false;
    }
    if (!_timeMatches(p)) return false;
    if (!_weatherMatches(p)) return false;
    if (!_clothingMatches(p)) return false;
    return true;
  }
}
