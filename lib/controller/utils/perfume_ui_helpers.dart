import 'package:intl/intl.dart';

/// Precio en ficha: entero en USD, miles con coma, sin decimales (ej. $1,000).
String formatUsdWholeNoDecimals(double? price) {
  if (price == null) return '—';
  final n = price.round();
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 0,
  ).format(n);
}

/// Parseo de campo de precio (acepta $, comas, espacios).
double? parseUsdWholeInput(String raw) {
  final t = raw.trim().replaceAll(r'$', '').replaceAll(',', '').replaceAll(' ', '');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

/// Reponer / refill para UI (prioriza [Perfume.refillNeeded]).
String refillDisplayLabel({required bool? refillNeeded, String? reponer}) {
  if (refillNeeded == true) return 'Sí';
  if (refillNeeded == false) return 'No';
  final r = (reponer ?? '').trim().toUpperCase();
  if (r == 'SI' || r == 'SÍ' || r == 'YES') return 'Sí';
  if (r == 'NO' || r == '-') return 'No';
  if (r.isEmpty) return '—';
  return reponer!.trim();
}

/// Mapea etiquetas ALTA / MEDIA / BAJA del Excel a 0..1 para barras.
double excelBandToProgress(String? raw) {
  if (raw == null) return 0.35;
  final u = raw.trim().toUpperCase();
  if (u.contains('ALTA')) return 0.92;
  if (u.contains('MEDIA')) return 0.55;
  if (u.contains('BAJA')) return 0.22;
  return 0.4;
}
