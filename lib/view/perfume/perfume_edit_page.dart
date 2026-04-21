import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_routes.dart';
import '../../controller/utils/perfume_ui_helpers.dart';
import '../../controller/utils/view_insets.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../domain/perfume/perfume.dart';
import '../../widgets/aura_buttons.dart';
import '../../widgets/aura_field.dart';
import '../../widgets/aura_section.dart';
import '../../widgets/perfume_image.dart';

class PerfumeEditPage extends StatefulWidget {
  const PerfumeEditPage({super.key});

  @override
  State<PerfumeEditPage> createState() => _PerfumeEditPageState();
}

class _PerfumeEditPageState extends State<PerfumeEditPage> {
  final _brand = TextEditingController();
  final _name = TextEditingController();
  final _rating = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _notesTop = TextEditingController();
  final _notesHeart = TextEditingController();
  final _notesBase = TextEditingController();
  final _compra = TextEditingController();
  final _vitrina = TextEditingController();

  final _picker = ImagePicker();
  String? _imagePath;

  Perfume? _existing;
  bool get _isCreate => _existing == null;

  /// 0 Día, 1 Noche, 2 Ambas
  int _momento = 0;
  /// 0 Calor, 1 Frío, 2 Ambas
  int _clima = 0;
  int _duracionIdx = 1;
  double _proyeccion = 0.45;

  bool _topCollection = false;
  bool _needsRefill = false;
  bool _beach = false;
  bool _outings = false;
  bool _office = false;
  bool _family = false;

  static List<String> _splitNotes(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static bool _occasionHas(Perfume p, String label) {
    final want = label.toLowerCase();
    for (final o in p.occasions) {
      if (o.trim().toLowerCase() == want) return true;
    }
    return false;
  }

  static bool _siPlayaRaw(String? raw) {
    final u = (raw ?? '').trim().toUpperCase();
    return u == 'SI' || u == 'SÍ' || u == 'YES';
  }

  static bool _inferRefillFromReponer(String? reponer) {
    final u = (reponer ?? '').trim().toUpperCase();
    return u == 'SI' || u == 'SÍ' || u == 'YES';
  }

  static int _momentoIndexFrom(String? s) {
    final u = (s ?? '').trim().toLowerCase();
    if (u.contains('ambas')) return 2;
    if (u.contains('noche')) return 1;
    return 0;
  }

  static int _climaIndexFrom(String? s) {
    final u = (s ?? '').trim().toLowerCase();
    if (u.contains('ambas')) return 2;
    if (u.contains('frío') || u.contains('frio')) return 1;
    return 0;
  }

  static int _duracionIdxFrom(String? d) {
    final u = (d ?? '').trim().toUpperCase();
    if (u.contains('ALTA') && !u.contains('MEDIA')) return 2;
    if (u.contains('BAJA')) return 0;
    return 1;
  }

  static double _projSliderFrom(String? p) {
    final u = (p ?? '').trim().toUpperCase();
    if (u.contains('ALTA')) return 0.92;
    if (u.contains('MEDIA') && u.contains('BAJA')) return 0.38;
    if (u.contains('MEDIA')) return 0.55;
    if (u.contains('BAJA')) return 0.22;
    return 0.45;
  }

  String _momentoLabel() {
    switch (_momento) {
      case 1:
        return 'Noche';
      case 2:
        return 'Ambas';
      default:
        return 'Día';
    }
  }

  String _climaLabel() {
    switch (_clima) {
      case 1:
        return 'Frío';
      case 2:
        return 'Ambas';
      default:
        return 'Calor';
    }
  }

  String _duracionLabel() {
    switch (_duracionIdx) {
      case 0:
        return 'Baja';
      case 2:
        return 'Alta';
      default:
        return 'Media';
    }
  }

  String _proyeccionFromSlider() {
    final t = _proyeccion;
    if (t < 0.32) return 'Baja';
    if (t < 0.44) return 'Media Baja';
    if (t < 0.68) return 'Media';
    return 'Alta';
  }

  List<String> _builtOccasions(Perfume base) {
    final out = <String>{};
    for (final o in base.occasions) {
      final l = o.trim();
      if (l.isEmpty) continue;
      final u = l.toLowerCase();
      if (u == 'playa' ||
          u == 'salidas' ||
          u == 'oficina' ||
          u == 'familiar') {
        continue;
      }
      out.add(l);
    }
    if (_beach) out.add('Playa');
    if (_outings) out.add('Salidas');
    if (_office) out.add('Oficina');
    if (_family) out.add('Familiar');
    return out.toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    final id = Get.parameters['id'];
    final isCreate =
        id == null || id.isEmpty || id == 'create';
    if (isCreate) {
      AppLog.catalog('PerfumeEdit opened (create new perfume)', {
        'route': Get.currentRoute,
        'paramId': id,
      });
      return;
    }
    final rid = id;
    final c = Get.find<PerfumeController>();
    _existing = c.byId(rid);
    final p = _existing;
    if (p != null) {
        AppLog.catalog(
          'PerfumeEdit opened (edit existing)',
          AppLog.perfumeSummary(p),
        );
        _brand.text = p.brand;
        _name.text = p.name;
        _rating.text = p.rating.toStringAsFixed(1);
        _description.text = p.description ?? '';
        _price.text = formatUsdWholeNoDecimals(p.price);
        if (_price.text == '—') _price.text = '';
        _imagePath = p.imagePath;
        _notesTop.text = p.notesTop.join(', ');
        _notesHeart.text = p.notesHeart.join(', ');
        _notesBase.text = p.notesBase.join(', ');
        _compra.text = p.supplierOrOrigin ?? '';
        _vitrina.text = p.vitrina ?? '';
        _momento = _momentoIndexFrom(p.diaNoche);
        _clima = _climaIndexFrom(p.frioCalor);
        _duracionIdx = _duracionIdxFrom(p.duracion);
        _proyeccion = _projSliderFrom(p.proyeccion);
        _topCollection = p.topCollection == true;
        _needsRefill = p.refillNeeded ?? _inferRefillFromReponer(p.reponer);
        _beach = p.beach ?? (_siPlayaRaw(p.playaRaw) || _occasionHas(p, 'Playa'));
        _outings = p.outings ?? _occasionHas(p, 'Salidas');
        _office = p.office ?? _occasionHas(p, 'Oficina');
        _family = p.family ?? _occasionHas(p, 'Familiar');
    } else {
      AppLog.warning(
        'PerfumeEdit opened with unknown id (no matching perfume)',
        rid,
      );
    }
  }

  @override
  void dispose() {
    _brand.dispose();
    _name.dispose();
    _rating.dispose();
    _description.dispose();
    _price.dispose();
    _notesTop.dispose();
    _notesHeart.dispose();
    _notesBase.dispose();
    _compra.dispose();
    _vitrina.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PerfumeController>();
    final bottomPad =
        ViewInsets.bottomOverlap(context) + MediaQuery.textScalerOf(context).scale(8);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            AppLog.tap(
              'PerfumeEdit',
              _isCreate ? 'Back from create' : 'Back from edit',
              _existing != null ? AppLog.perfumeSummary(_existing!) : null,
            );
            Get.back();
          },
        ),
        title: Text(
          _isCreate ? 'Nuevo perfume' : 'Editar perfume',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (!_isCreate)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final id = _existing!.id;
                AppLog.action(
                  'PerfumeEdit: delete confirmed',
                  AppLog.perfumeSummary(_existing!),
                );
                await c.delete(id);
                AppLog.navigate(
                  'POP_TO_HOME',
                  AppRoutes.home,
                  {'after': 'delete perfume', 'deletedId': id},
                );
                Get.until((r) => r.settings.name == AppRoutes.home);
              },
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, 10, 18, 32 + bottomPad),
        children: [
          Text(
            'IDENTIDAD',
            style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          AuraSection(
            title: 'IMAGEN',
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AppLog.tap('PerfumeEdit', 'Open image picker (tap image)');
                    _pickImageSheet();
                  },
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            PerfumeImage(path: _imagePath, size: 200),
                            const SizedBox(height: 10),
                            Text(
                              'Toca para cambiar la fotografía',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: InkWell(
                          onTap: () {
                            AppLog.tap('PerfumeEdit', 'Open image picker sheet');
                            _pickImageSheet();
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.photo_camera_rounded,
                                color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'DATOS BÁSICOS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuraField(
                  label: 'Nombre de la fragancia',
                  controller: _name,
                ),
                const SizedBox(height: 12),
                AuraField(
                  label: 'Casa / Marca',
                  controller: _brand,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AuraField(
                        label: 'Precio (USD, sin decimales)',
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                          signed: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuraField(
                        label: 'Calificación (0–10)',
                        controller: _rating,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'CATÁLOGO / VITRINA',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuraField(
                  label: 'Vitrina',
                  controller: _vitrina,
                ),
                const SizedBox(height: 12),
                AuraField(
                  label: 'Proveedor',
                  controller: _compra,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Top colección', style: AppTextStyles.body),
                  value: _topCollection,
                  onChanged: (v) => setState(() => _topCollection = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Reponer', style: AppTextStyles.body),
                  subtitle: Text('Sí = marcar para reabastecer',
                      style: AppTextStyles.caption),
                  value: _needsRefill,
                  onChanged: (v) => setState(() => _needsRefill = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'OCASIÓN (sí / no)',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Playa', style: AppTextStyles.body),
                  value: _beach,
                  onChanged: (v) => setState(() => _beach = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Salidas', style: AppTextStyles.body),
                  value: _outings,
                  onChanged: (v) => setState(() => _outings = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Oficina', style: AppTextStyles.body),
                  value: _office,
                  onChanged: (v) => setState(() => _office = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Familiar', style: AppTextStyles.body),
                  value: _family,
                  onChanged: (v) => setState(() => _family = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'PERFIL OLFATIVO',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuraField(
                  label: 'Salida (notas, separadas por coma)',
                  controller: _notesTop,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                AuraField(
                  label: 'Corazón',
                  controller: _notesHeart,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                AuraField(
                  label: 'Fondo / Base',
                  controller: _notesBase,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'DESCRIPCIÓN',
            child: AuraField(
              label: 'Texto libre',
              controller: _description,
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'FILTROS DE USO (vista previa)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Momento del día', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Día')),
                    ButtonSegment(value: 1, label: Text('Noche')),
                    ButtonSegment(value: 2, label: Text('Ambas')),
                  ],
                  selected: {_momento},
                  onSelectionChanged: (s) =>
                      setState(() => _momento = s.first),
                ),
                const SizedBox(height: 14),
                Text('Clima', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Calor')),
                    ButtonSegment(value: 1, label: Text('Frío')),
                    ButtonSegment(value: 2, label: Text('Ambas')),
                  ],
                  selected: {_clima},
                  onSelectionChanged: (s) => setState(() => _clima = s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AuraSection(
            title: 'RENDIMIENTO (vista previa)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Duración y longevidad', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Baja')),
                    ButtonSegment(value: 1, label: Text('Media')),
                    ButtonSegment(value: 2, label: Text('Alta')),
                  ],
                  selected: {_duracionIdx},
                  onSelectionChanged: (s) =>
                      setState(() => _duracionIdx = s.first),
                ),
                const SizedBox(height: 14),
                Text('Proyección y estela', style: AppTextStyles.caption),
                Slider(
                  value: _proyeccion,
                  onChanged: (v) => setState(() => _proyeccion = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Íntima', style: AppTextStyles.caption),
                    Text('Moderada', style: AppTextStyles.caption),
                    Text('Fuerte', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: EdgeInsets.only(bottom: 8 + bottomPad * 0.35),
            child: AuraSecondaryButton(
              label: 'Importar desde Excel',
              onTap: () {
                AppLog.navigate(
                  'OPEN',
                  AppRoutes.inventoryImport,
                  {'from': 'PerfumeEdit (above actions)'},
                );
                Get.toNamed(AppRoutes.inventoryImport);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AuraSecondaryButton(
                  label: 'Cancelar',
                  onTap: () {
                    AppLog.tap('PerfumeEdit', 'Cancel');
                    Get.back();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuraPrimaryButton(
                  label: 'Guardar perfume',
                  onTap: () async {
                    final brand = _brand.text.trim();
                    final name = _name.text.trim();
                    if (brand.isEmpty || name.isEmpty) {
                      AppLog.warning(
                        'PerfumeEdit save blocked: empty brand or name',
                        {'brandEmpty': brand.isEmpty, 'nameEmpty': name.isEmpty},
                      );
                      Get.snackbar(
                          'Faltan datos', 'Marca y nombre son obligatorios.');
                      return;
                    }
                    final rating = double.tryParse(
                            _rating.text.trim().replaceAll(',', '.')) ??
                        0;
                    final price = parseUsdWholeInput(_price.text);

                    final base = _existing ??
                        Perfume(
                          id: const Uuid().v4(),
                          brand: brand,
                          name: name,
                          rating: rating,
                        );
                    final next = base.copyWith(
                      brand: brand,
                      name: name,
                      rating: rating,
                      price: price,
                      description: _description.text.trim().isEmpty
                          ? null
                          : _description.text.trim(),
                      imagePath: _imagePath,
                      notesTop: _splitNotes(_notesTop.text),
                      notesHeart: _splitNotes(_notesHeart.text),
                      notesBase: _splitNotes(_notesBase.text),
                      origin: _compra.text.trim().isEmpty
                          ? null
                          : _compra.text.trim(),
                      supplier: _compra.text.trim().isEmpty
                          ? null
                          : _compra.text.trim(),
                      clearYear: true,
                      vitrina: _vitrina.text.trim().isEmpty
                          ? null
                          : _vitrina.text.trim(),
                      diaNoche: _momentoLabel(),
                      frioCalor: _climaLabel(),
                      duracion: _duracionLabel(),
                      proyeccion: _proyeccionFromSlider(),
                      topCollection: _topCollection,
                      refillNeeded: _needsRefill,
                      reponer: _needsRefill ? 'SI' : '-',
                      beach: _beach,
                      outings: _outings,
                      office: _office,
                      family: _family,
                      playaRaw: _beach ? 'SI' : '-',
                      occasions: _builtOccasions(base),
                    );
                    AppLog.catalog(
                      'PerfumeEdit saving perfume',
                      {
                        ...AppLog.perfumeSummary(next),
                        'isCreate': _isCreate,
                        'hasLocalImage':
                            next.imagePath != null &&
                            !next.imagePath!.startsWith('assets/'),
                      },
                    );
                    await c.upsert(next);
                    final detailRoute =
                        AppRoutes.perfumeDetail.replaceFirst(':id', next.id);
                    AppLog.navigate(
                      'REPLACE_WITH_DETAIL',
                      detailRoute,
                      AppLog.perfumeSummary(next),
                    );
                    Get.offNamed(detailRoute);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16 + bottomPad * 0.5),
        ],
      ),
    );
  }

  Future<void> _pickImageSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: Text('Cámara', style: AppTextStyles.body),
                  onTap: () async {
                    AppLog.tap('PerfumeEdit', 'Image picker: Camera');
                    Navigator.pop(context);
                    final file = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 88,
                    );
                    if (file != null) {
                      AppLog.action('Image picked (camera)', {'path': file.path});
                      setState(() => _imagePath = file.path);
                    } else {
                      AppLog.action('Image pick cancelled (camera)');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: Text('Galería', style: AppTextStyles.body),
                  onTap: () async {
                    AppLog.tap('PerfumeEdit', 'Image picker: Gallery');
                    Navigator.pop(context);
                    final file = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 88,
                    );
                    if (file != null) {
                      AppLog.action('Image picked (gallery)', {'path': file.path});
                      setState(() => _imagePath = file.path);
                    } else {
                      AppLog.action('Image pick cancelled (gallery)');
                    }
                  },
                ),
                if (_imagePath != null && _imagePath!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger),
                    title: Text('Quitar imagen',
                        style:
                            AppTextStyles.body.copyWith(color: AppColors.danger)),
                    onTap: () {
                      AppLog.tap('PerfumeEdit', 'Remove custom image path');
                      Navigator.pop(context);
                      setState(() => _imagePath = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
