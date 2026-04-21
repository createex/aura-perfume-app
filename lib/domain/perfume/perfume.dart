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

  /// Campos adicionales del Excel (hoja VITRINA).
  final String? vitrina;
  final String? reponer;
  final String? proyeccion;
  final String? duracion;
  final String? diaNoche;
  final String? frioCalor;
  final String? playaRaw;
  final String? link;

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
  });

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
    List<String>? occasions,
    List<String>? styles,
    List<String>? notesTop,
    List<String>? notesHeart,
    List<String>? notesBase,
    String? imagePath,
    String? vitrina,
    String? reponer,
    String? proyeccion,
    String? duracion,
    String? diaNoche,
    String? frioCalor,
    String? playaRaw,
    String? link,
  }) {
    return Perfume(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      price: price ?? this.price,
      origin: origin ?? this.origin,
      year: year ?? this.year,
      occasions: occasions ?? this.occasions,
      styles: styles ?? this.styles,
      notesTop: notesTop ?? this.notesTop,
      notesHeart: notesHeart ?? this.notesHeart,
      notesBase: notesBase ?? this.notesBase,
      imagePath: imagePath ?? this.imagePath,
      vitrina: vitrina ?? this.vitrina,
      reponer: reponer ?? this.reponer,
      proyeccion: proyeccion ?? this.proyeccion,
      duracion: duracion ?? this.duracion,
      diaNoche: diaNoche ?? this.diaNoche,
      frioCalor: frioCalor ?? this.frioCalor,
      playaRaw: playaRaw ?? this.playaRaw,
      link: link ?? this.link,
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
      };

  factory Perfume.fromMap(Map<String, dynamic> map) => Perfume(
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
        origin: map['origin']?.toString(),
        year: map['year']?.toString(),
        occasions: ((map['occasions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        styles: ((map['styles'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        notesTop: ((map['notesTop'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        notesHeart: ((map['notesHeart'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        notesBase: ((map['notesBase'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        imagePath: map['imagePath']?.toString(),
        vitrina: map['vitrina']?.toString(),
        reponer: map['reponer']?.toString(),
        proyeccion: map['proyeccion']?.toString(),
        duracion: map['duracion']?.toString(),
        diaNoche: map['diaNoche']?.toString(),
        frioCalor: map['frioCalor']?.toString(),
        playaRaw: map['playaRaw']?.toString(),
        link: map['link']?.toString(),
      );

  String toJson() => jsonEncode(toMap());
  factory Perfume.fromJson(String source) =>
      Perfume.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
