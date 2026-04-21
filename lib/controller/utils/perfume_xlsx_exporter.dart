import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/perfume/perfume.dart';
import 'app_log.dart';

/// Builds a `.xlsx` workbook with sheet **VITRINA** and headers compatible with
/// [PerfumeXlsxParser] (lowercase matching in the parser).
class PerfumeXlsxExporter {
  PerfumeXlsxExporter._();

  static TextCellValue _t(String v) => TextCellValue(v);

  static String _siDash(bool? v) {
    if (v == null) return '-';
    return v ? 'SI' : '-';
  }

  static String _price(Perfume p) {
    if (p.price == null) return '';
    if (p.price == p.price!.roundToDouble()) {
      return p.price!.round().toString();
    }
    return p.price!.toString();
  }

  /// Returns encoded `.xlsx` bytes, or `null` if the encoder fails.
  static Uint8List? buildBytes(List<Perfume> perfumes) {
    AppLog.io(
      'PerfumeXlsxExporter.buildBytes: start',
      {'rowCount': perfumes.length},
    );
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet() ?? 'Sheet1';
    if (defaultName.toUpperCase() != 'VITRINA') {
      excel.rename(defaultName, 'VITRINA');
    }
    final sheet = excel['VITRINA'];

    sheet.appendRow([
      _t('Nombre'),
      _t('Marca'),
      _t('Calificacion personal'),
      _t('Precio'),
      _t('Reponer'),
      _t('Proyeccion'),
      _t('Duracion'),
      _t('Perfil'),
      _t('Ropa'),
      _t('Dia/Noche'),
      _t('Frio/Calor'),
      _t('Playa'),
      _t('Salidas'),
      _t('Oficina'),
      _t('Familiar'),
      _t('Proveedor'),
      _t('Link'),
      _t('Vitrina'),
      _t('Top Coleccion'),
      _t('Salida'),
      _t('Corazon'),
      _t('Fondo'),
      _t('Descripcion'),
      _t('Imagen'),
    ]);

    for (final p in perfumes) {
      sheet.appendRow([
        _t(p.name),
        _t(p.brand),
        _t(p.rating.toString()),
        _t(_price(p)),
        _t(p.reponer ?? _siDash(p.refillNeeded)),
        _t(p.proyeccion ?? ''),
        _t(p.duracion ?? ''),
        _t(p.profile ?? ''),
        _t(p.clothing ?? ''),
        _t(p.diaNoche ?? ''),
        _t(p.frioCalor ?? ''),
        _t(p.playaRaw ?? _siDash(p.beach)),
        _t(_siDash(p.outings)),
        _t(_siDash(p.office)),
        _t(_siDash(p.family)),
        _t(p.supplierOrOrigin ?? ''),
        _t(p.link ?? ''),
        _t(p.vitrina ?? ''),
        _t(_siDash(p.topCollection)),
        _t(p.notesTop.join(', ')),
        _t(p.notesHeart.join(', ')),
        _t(p.notesBase.join(', ')),
        _t(p.description ?? ''),
        _t(p.imagePath ?? ''),
      ]);
    }

    final raw = excel.encode();
    if (raw == null) {
      AppLog.warning('PerfumeXlsxExporter.buildBytes: excel.encode() returned null');
      return null;
    }
    final out = Uint8List.fromList(raw);
    AppLog.io(
      'PerfumeXlsxExporter.buildBytes: done',
      {'byteLength': out.length, 'rowsWritten': perfumes.length + 1},
    );
    return out;
  }
}
