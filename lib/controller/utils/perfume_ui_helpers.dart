/// Mapea etiquetas ALTA / MEDIA / BAJA del Excel a 0..1 para barras.
double excelBandToProgress(String? raw) {
  if (raw == null) return 0.35;
  final u = raw.trim().toUpperCase();
  if (u.contains('ALTA')) return 0.92;
  if (u.contains('MEDIA')) return 0.55;
  if (u.contains('BAJA')) return 0.22;
  return 0.4;
}
