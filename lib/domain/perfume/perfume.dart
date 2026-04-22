import 'dart:convert';

class Perfume {
  final String id;
  final String brand;
  final String name;
  final double rating;
  final String? description;
  final double? price;
  final String? origin;
  final String? year;
  final List<String> occasions;
  final List<String> styles;
  final List<String> notesTop;
  final List<String> notesHeart;
  final List<String> notesBase;

  /// Can be an asset path (`assets/...`) or a local file path.
  final String? imagePath;

  /// Display case number (Excel: Vitrina).
  final String? vitrina;

  /// Excel raw text (SI / -). Prefer [refillNeeded] when set.
  final String? reponer;

  final String? proyeccion;
  final String? duracion;
  final String? diaNoche;
  final String? frioCalor;

  /// Excel raw for beach column when needed for display.
  final String? playaRaw;

  final String? link;

  /// Olfactory / sheet profile (distinct from chip [styles] when populated).
  final String? profile;

  /// Clothing / formality: Formal, Casual, Ambas, etc.
  final String? clothing;

  /// Supplier / proveedor (preferred over [origin] for new data).
  final String? supplier;

  /// Top collection flag.
  final bool? topCollection;

  final bool? beach;
  final bool? outings;
  final bool? office;
  final bool? family;

  /// Structured refill: `true` = needs refill, `false` = no, `null` = unknown.
  final bool? refillNeeded;

  const Perfume({
    required this.id,
    required this.brand,
    required this.name,
    required this.rating,
    this.description,
    this.price,
    this.origin,
    this.year,
    this.occasions = const [],
    this.styles = const [],
    this.notesTop = const [],
    this.notesHeart = const [],
    this.notesBase = const [],
    this.imagePath,
    this.vitrina,
    this.reponer,
    this.proyeccion,
    this.duracion,
    this.diaNoche,
    this.frioCalor,
    this.playaRaw,
    this.link,
    this.profile,
    this.clothing,
    this.supplier,
    this.topCollection,
    this.beach,
    this.outings,
    this.office,
    this.family,
    this.refillNeeded,
  });

  /// Effective supplier for UI (legacy [origin] or [supplier]).
  String? get supplierOrOrigin =>
      (supplier != null && supplier!.trim().isNotEmpty)
          ? supplier
          : origin;

  /// Línea secundaria para tarjetas de lista (datos hoja).
  String? get catalogSubtitle {
    final parts = <String>[];
    if (proyeccion != null && proyeccion!.trim().isNotEmpty && proyeccion != '-') {
      parts.add('Proyección ${proyeccion!.trim()}');
    }
    if (duracion != null && duracion!.trim().isNotEmpty && duracion != '-') {
      parts.add('Duración ${duracion!.trim()}');
    }
    if (vitrina != null && vitrina!.trim().isNotEmpty && vitrina != '-') {
      parts.add('Vitrina ${vitrina!.trim()}');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  Perfume copyWith({
    String? id,
    String? brand,
    String? name,
    double? rating,
    String? description,
    double? price,
    String? origin,
    String? year,
    /// When true, [year] is stored as `null` (Excel / ficha no longer use año en edición).
    bool clearYear = false,
    List<String>? occasions,
    List<String>? styles,
    List<String>? notesTop,
    List<String>? notesHeart,
    List<String>? notesBase,
    String? imagePath,
    /// When true, [imagePath] becomes `null` regardless of [imagePath] argument.
    bool clearImagePath = false,
    String? vitrina,
    String? reponer,
    String? proyeccion,
    String? duracion,
    String? diaNoche,
    String? frioCalor,
    String? playaRaw,
    String? link,
    String? profile,
    String? clothing,
    String? supplier,
    bool? topCollection,
    bool? beach,
    bool? outings,
    bool? office,
    bool? family,
    bool? refillNeeded,
  }) {
    return Perfume(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      price: price ?? this.price,
      origin: origin ?? this.origin,
      year: clearYear ? null : (year ?? this.year),
      occasions: occasions ?? this.occasions,
      styles: styles ?? this.styles,
      notesTop: notesTop ?? this.notesTop,
      notesHeart: notesHeart ?? this.notesHeart,
      notesBase: notesBase ?? this.notesBase,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      vitrina: vitrina ?? this.vitrina,
      reponer: reponer ?? this.reponer,
      proyeccion: proyeccion ?? this.proyeccion,
      duracion: duracion ?? this.duracion,
      diaNoche: diaNoche ?? this.diaNoche,
      frioCalor: frioCalor ?? this.frioCalor,
      playaRaw: playaRaw ?? this.playaRaw,
      link: link ?? this.link,
      profile: profile ?? this.profile,
      clothing: clothing ?? this.clothing,
      supplier: supplier ?? this.supplier,
      topCollection: topCollection ?? this.topCollection,
      beach: beach ?? this.beach,
      outings: outings ?? this.outings,
      office: office ?? this.office,
      family: family ?? this.family,
      refillNeeded: refillNeeded ?? this.refillNeeded,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'brand': brand,
        'name': name,
        'rating': rating,
        'description': description,
        'price': price,
        'origin': origin,
        'year': year,
        'occasions': occasions,
        'styles': styles,
        'notesTop': notesTop,
        'notesHeart': notesHeart,
        'notesBase': notesBase,
        'imagePath': imagePath,
        'vitrina': vitrina,
        'reponer': reponer,
        'proyeccion': proyeccion,
        'duracion': duracion,
        'diaNoche': diaNoche,
        'frioCalor': frioCalor,
        'playaRaw': playaRaw,
        'link': link,
        'profile': profile,
        'clothing': clothing,
        'supplier': supplier,
        'topCollection': topCollection,
        'beach': beach,
        'outings': outings,
        'office': office,
        'family': family,
        'refillNeeded': refillNeeded,
      };

  static bool? _boolFromMap(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) {
      if (v == -1) return null;
      return v != 0;
    }
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1' || s == 'si' || s == 'sí' || s == 'yes') {
      return true;
    }
    if (s == 'false' || s == '0' || s == 'no' || s == '-') return false;
    return null;
  }

  static List<String> _stringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.map((e) => e.toString()).toList(growable: false);
    }
    if (v is String && v.trim().isNotEmpty) {
      try {
        final d = jsonDecode(v);
        if (d is List) {
          return d.map((e) => e.toString()).toList(growable: false);
        }
      } catch (_) {}
    }
    return const [];
  }

  factory Perfume.fromMap(Map<String, dynamic> map) {
    final occasions = _stringList(map['occasions']);
    final styles = _stringList(map['styles']);
    final reponer = map['reponer']?.toString();
    final playaRaw = map['playaRaw']?.toString();
    final supplier = map['supplier']?.toString();
    final origin = map['origin']?.toString();

    bool? refill = _boolFromMap(map['refillNeeded']);
    refill ??= _refillFromReponerText(reponer);

    bool? beach = _boolFromMap(map['beach']);
    beach ??= _beachFromPlaya(playaRaw);
    beach ??= _boolFromOccasion(occasions, 'Playa');

    bool? outings = _boolFromMap(map['outings']) ??
        _boolFromOccasion(occasions, 'Salidas');
    bool? office = _boolFromMap(map['office']) ??
        _boolFromOccasion(occasions, 'Oficina');
    bool? family = _boolFromMap(map['family']) ??
        _boolFromOccasion(occasions, 'Familiar');

    String? profile = map['profile']?.toString();
    if (profile == null || profile.isEmpty) {
      profile = _legacyProfileFromStyles(styles);
    }

    String? clothing = map['clothing']?.toString();
    if (clothing == null || clothing.isEmpty) {
      clothing = _legacyClothingFromStyles(styles);
    }

    return Perfume(
      id: (map['id'] ?? '').toString(),
      brand: (map['brand'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      rating: (map['rating'] is num)
          ? (map['rating'] as num).toDouble()
          : double.tryParse((map['rating'] ?? '0').toString()) ?? 0,
      description: map['description']?.toString(),
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse((map['price'] ?? '').toString()),
      origin: origin,
      year: map['year']?.toString(),
      occasions: occasions,
      styles: styles,
      notesTop: _stringList(map['notesTop']),
      notesHeart: _stringList(map['notesHeart']),
      notesBase: _stringList(map['notesBase']),
      imagePath: map['imagePath']?.toString(),
      vitrina: map['vitrina']?.toString(),
      reponer: reponer,
      proyeccion: map['proyeccion']?.toString(),
      duracion: map['duracion']?.toString(),
      diaNoche: map['diaNoche']?.toString(),
      frioCalor: map['frioCalor']?.toString(),
      playaRaw: playaRaw,
      link: map['link']?.toString(),
      profile: profile,
      clothing: clothing,
      supplier: (supplier != null && supplier.isNotEmpty)
          ? supplier
          : (origin != null && origin.isNotEmpty ? origin : null),
      topCollection: _boolFromMap(map['topCollection']),
      beach: beach,
      outings: outings,
      office: office,
      family: family,
      refillNeeded: refill,
    );
  }

  static bool? _refillFromReponerText(String? reponer) {
    if (reponer == null || reponer.trim().isEmpty || reponer.trim() == '-') {
      return null;
    }
    final u = reponer.trim().toUpperCase();
    if (u == 'SI' || u == 'SÍ' || u == 'YES') return true;
    return false;
  }

  static bool? _beachFromPlaya(String? playaRaw) {
    if (playaRaw == null || playaRaw.trim().isEmpty || playaRaw == '-') {
      return null;
    }
    final u = playaRaw.trim().toUpperCase();
    if (u == 'SI' || u == 'SÍ' || u == 'YES') return true;
    if (u == 'NO' || u == '-') return false;
    return null;
  }

  static bool? _boolFromOccasion(List<String> occasions, String label) {
    for (final o in occasions) {
      if (o.toLowerCase() == label.toLowerCase()) return true;
    }
    return null;
  }

  /// Older imports stored `[perfil, ropa]` inside [styles].
  static String? _legacyProfileFromStyles(List<String> styles) {
    if (styles.isEmpty) return null;
    if (styles.length >= 2) return styles[0].trim().isEmpty ? null : styles[0].trim();
    final only = styles[0].trim();
    if (only.isEmpty) return null;
    final u = only.toUpperCase();
    if (u == 'FORMAL' || u == 'CASUAL' || u == 'AMBAS') return null;
    return only;
  }

  static String? _legacyClothingFromStyles(List<String> styles) {
    if (styles.isEmpty) return null;
    if (styles.length >= 2) {
      final s = styles[1].trim();
      return s.isEmpty ? null : s;
    }
    final only = styles[0].trim();
    final u = only.toUpperCase();
    if (u == 'FORMAL' || u == 'CASUAL' || u == 'AMBAS') return only;
    return null;
  }

  String toJson() => jsonEncode(toMap());
  factory Perfume.fromJson(String source) =>
      Perfume.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
