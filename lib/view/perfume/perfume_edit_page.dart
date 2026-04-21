import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_routes.dart';
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
  final _lote = TextEditingController();

  final _picker = ImagePicker();
  String? _imagePath;

  Perfume? _existing;
  bool get _isCreate => _existing == null;

  int _momento = 0; // 0 día 1 noche
  int _clima = 0; // 0 cálido 1 frío
  int _duracionIdx = 1; // 0 baja 1 media 2 alta
  double _proyeccion = 0.45;
  bool _ubicacion = false;

  static List<String> _splitNotes(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    final id = Get.parameters['id'];
    if (id != null && id.isNotEmpty) {
      final c = Get.find<PerfumeController>();
      _existing = c.byId(id);
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
        _price.text = p.price?.toStringAsFixed(2) ?? '';
        _imagePath = p.imagePath;
        _notesTop.text = p.notesTop.join(', ');
        _notesHeart.text = p.notesHeart.join(', ');
        _notesBase.text = p.notesBase.join(', ');
        _compra.text = p.origin ?? '';
        _lote.text = p.year ?? '';
      } else {
        AppLog.warning(
          'PerfumeEdit opened with unknown id (no matching perfume)',
          id,
        );
      }
    } else {
      AppLog.catalog('PerfumeEdit opened (create new perfume)', {
        'route': Get.currentRoute,
      });
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
    _lote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PerfumeController>();
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
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          Text(
            'IDENTIDAD',
            style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          AuraSection(
            title: 'IMAGEN',
            child: Center(
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
                          'Cargar fotografía',
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
                        label: 'Precio',
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                    ButtonSegment(value: 0, label: Text('Cálido')),
                    ButtonSegment(value: 1, label: Text('Frío')),
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
          const SizedBox(height: 14),
          AuraSection(
            title: 'LOGÍSTICA',
            child: Column(
              children: [
                AuraField(
                  label: 'Dónde se compró',
                  controller: _compra,
                ),
                const SizedBox(height: 12),
                AuraField(
                  label: 'Número de lote',
                  controller: _lote,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Registrar mi ubicación',
                      style: AppTextStyles.body),
                  value: _ubicacion,
                  thumbColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.selected)
                        ? AppColors.primary
                        : null,
                  ),
                  onChanged: (v) => setState(() => _ubicacion = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: AuraSecondaryButton(
                  label: 'Cancelar',
                  onTap: () {
                    AppLog.tap('PerfumeEdit', 'Cancel (discard changes prompt none)');
                    Get.back();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
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
                    final price = double.tryParse(
                        _price.text.trim().replaceAll(',', '.'));

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
                      year: _lote.text.trim().isEmpty
                          ? null
                          : _lote.text.trim(),
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
          const SizedBox(height: 12),
          AuraSecondaryButton(
            label: 'Importar desde Excel',
            onTap: () {
              AppLog.navigate(
                'OPEN',
                AppRoutes.inventoryImport,
                {'from': 'PerfumeEdit footer'},
              );
              Get.toNamed(AppRoutes.inventoryImport);
            },
          ),
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
