import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../controller/utils/view_insets.dart';
import '../../domain/library/library_catalog_filter.dart';
import '../../widgets/aura_buttons.dart';
import '../../widgets/aura_section.dart';

enum CatalogFiltersTarget { library, choose }

/// Full facet filter sheet for **Mi Biblioteca** or **Qué usar** (same fields).
class CatalogFiltersSheet extends StatefulWidget {
  const CatalogFiltersSheet({super.key, required this.target});

  final CatalogFiltersTarget target;

  @override
  State<CatalogFiltersSheet> createState() => _CatalogFiltersSheetState();
}

class _CatalogFiltersSheetState extends State<CatalogFiltersSheet> {
  late LibraryCatalogFilter _d;
  late final TextEditingController _vitrina;
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _ratingMinC;
  late final TextEditingController _ratingMaxC;
  late final TextEditingController _priceMinC;
  late final TextEditingController _priceMaxC;

  PerfumeController get _c => Get.find<PerfumeController>();

  LibraryCatalogFilter get _sourceFilter => widget.target == CatalogFiltersTarget.library
      ? _c.libraryFilter.value
      : _c.chooseFilter.value;

  @override
  void initState() {
    super.initState();
    final cap = LibraryCatalogFilter.catalogPriceCeiling(_c.catalogMaxPrice);
    final src = _sourceFilter;
    _d = _normalizeRanges(
      src.copyWith(
        ratingMax: src.ratingMax.clamp(0, 10),
        priceMax: src.priceMax.clamp(0, cap),
      ),
      cap,
    );
    _vitrina = TextEditingController(text: _d.vitrinaContains);
    _name = TextEditingController(text: _d.nameContains);
    _brand = TextEditingController(text: _d.brandContains);
    _ratingMinC = TextEditingController(text: '${_d.ratingMin}');
    _ratingMaxC = TextEditingController(text: '${_d.ratingMax}');
    _priceMinC = TextEditingController(text: _fmtPrice(_d.priceMin));
    _priceMaxC = TextEditingController(text: _fmtPrice(_d.priceMax));
    AppLog.tap(
      'CatalogFiltersSheet',
      'opened',
      {
        'target': widget.target.name,
        'active': _d.isActive(_c.catalogMaxPrice),
      },
    );
  }

  @override
  void dispose() {
    _vitrina.dispose();
    _name.dispose();
    _brand.dispose();
    _ratingMinC.dispose();
    _ratingMaxC.dispose();
    _priceMinC.dispose();
    _priceMaxC.dispose();
    super.dispose();
  }

  static String _fmtPrice(double v) {
    if (v == v.roundToDouble()) return '${v.round()}';
    return v.toStringAsFixed(2);
  }

  static LibraryCatalogFilter _normalizeRanges(
    LibraryCatalogFilter d,
    double cap,
  ) {
    var rMin = d.ratingMin.clamp(0, 10);
    var rMax = d.ratingMax.clamp(0, 10);
    if (rMin > rMax) {
      final t = rMin;
      rMin = rMax;
      rMax = t;
    }
    var pMin = d.priceMin.clamp(0, cap);
    var pMax = d.priceMax.clamp(0, cap);
    if (pMin > pMax) {
      final t = pMin;
      pMin = pMax;
      pMax = t;
    }
    return d.copyWith(
      ratingMin: rMin,
      ratingMax: rMax,
      priceMin: pMin.toDouble(),
      priceMax: pMax.toDouble(),
    );
  }

  void _apply() {
    final cap = LibraryCatalogFilter.catalogPriceCeiling(_c.catalogMaxPrice);
    final rMin = int.tryParse(_ratingMinC.text.trim());
    final rMax = int.tryParse(_ratingMaxC.text.trim());
    final pMin = double.tryParse(
      _priceMinC.text.trim().replaceAll(',', '.'),
    );
    final pMax = double.tryParse(
      _priceMaxC.text.trim().replaceAll(',', '.'),
    );
    var next = _d.copyWith(
      vitrinaContains: _vitrina.text,
      nameContains: _name.text,
      brandContains: _brand.text,
      ratingMin: rMin ?? _d.ratingMin,
      ratingMax: rMax ?? _d.ratingMax,
      priceMin: pMin ?? _d.priceMin,
      priceMax: pMax ?? _d.priceMax,
    );
    next = _normalizeRanges(next, cap);
    if (widget.target == CatalogFiltersTarget.library) {
      _c.setLibraryFilter(next);
    } else {
      _c.setChooseFilter(next);
    }
    AppLog.action('CatalogFiltersSheet.apply', {'target': widget.target.name});
    Get.back();
  }

  void _clear() {
    if (widget.target == CatalogFiltersTarget.library) {
      _c.clearLibraryFilters();
    } else {
      _c.clearChooseFilters();
    }
    AppLog.action('CatalogFiltersSheet.clear', {'target': widget.target.name});
    Get.back();
  }

  Widget _tri(String label, TriStateFilter v, ValueChanged<TriStateFilter> onChanged) {
    Widget chip(String text, TriStateFilter val) {
      final sel = v == val;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(text, style: AppTextStyles.caption),
          selected: sel,
          onSelected: (_) => onChanged(val),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Wrap(
            children: [
              chip('Todo', TriStateFilter.any),
              chip('Sí', TriStateFilter.yes),
              chip('No', TriStateFilter.no),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipSet(
    String title,
    List<String> options,
    Set<String> selected,
    void Function(Set<String>) onChanged,
  ) {
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '$title: sin valores en el catálogo',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              final on = selected.contains(o);
              return FilterChip(
                label: Text(
                  o,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: on,
                onSelected: (v) {
                  final next = Set<String>.from(selected);
                  if (v) {
                    next.add(o);
                  } else {
                    next.remove(o);
                  }
                  onChanged(next);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final maxP = LibraryCatalogFilter.catalogPriceCeiling(c.catalogMaxPrice);
    final bottomPad = 14 + ViewInsets.bottomOverlap(context);

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filtros', style: AppTextStyles.screenTitle),
                ),
                IconButton(
                  onPressed: () {
                    AppLog.tap('CatalogFiltersSheet', 'Close');
                    Get.back();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Expanded(
              child: Obx(() {
                c.perfumes.length;
                if (widget.target == CatalogFiltersTarget.library) {
                  c.libraryFilter.value;
                } else {
                  c.chooseFilter.value;
                }
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuraSection(
                        title: 'TEXTO',
                        child: Column(
                          children: [
                            TextField(
                              controller: _vitrina,
                              decoration: const InputDecoration(
                                labelText: 'Vitrina (contiene)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Nombre (contiene)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _brand,
                              decoration: const InputDecoration(
                                labelText: 'Marca (contiene)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AuraSection(
                        title:
                            'Calificación (${_d.ratingMin.clamp(0, 10)}–${_d.ratingMax.clamp(0, 10)})',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Rango 0–10 (usa el control o escribe mín / máx)',
                              style: AppTextStyles.bodyMuted,
                            ),
                            const SizedBox(height: 8),
                            RangeSlider(
                              values: RangeValues(
                                _d.ratingMin.clamp(0, 10).toDouble(),
                                _d.ratingMax.clamp(0, 10).toDouble(),
                              ),
                              min: 0,
                              max: 10,
                              divisions: 10,
                              labels: RangeLabels(
                                '${_d.ratingMin}',
                                '${_d.ratingMax}',
                              ),
                              onChanged: (v) {
                                setState(() {
                                  final cap = LibraryCatalogFilter.catalogPriceCeiling(
                                      c.catalogMaxPrice);
                                  _d = _normalizeRanges(
                                    _d.copyWith(
                                      ratingMin: v.start.round(),
                                      ratingMax: v.end.round(),
                                    ),
                                    cap,
                                  );
                                  _ratingMinC.text = '${_d.ratingMin}';
                                  _ratingMaxC.text = '${_d.ratingMax}';
                                });
                              },
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _ratingMinC,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Mín',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _ratingMaxC,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Máx',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AuraSection(
                        title:
                            'Precio (\$${_fmtPrice(_d.priceMin.clamp(0, maxP))}–\$${_fmtPrice(_d.priceMax.clamp(0, maxP))} · catálogo hasta \$${maxP.round()})',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Rango en moneda del catálogo (control o texto mín / máx)',
                              style: AppTextStyles.bodyMuted,
                            ),
                            const SizedBox(height: 8),
                            RangeSlider(
                              values: RangeValues(
                                _d.priceMin.clamp(0, maxP),
                                _d.priceMax.clamp(0, maxP),
                              ),
                              min: 0,
                              max: maxP,
                              labels: RangeLabels(
                                '\$${_fmtPrice(_d.priceMin.clamp(0, maxP))}',
                                '\$${_fmtPrice(_d.priceMax.clamp(0, maxP))}',
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _d = _normalizeRanges(
                                    _d.copyWith(
                                      priceMin: v.start.clamp(0, maxP),
                                      priceMax: v.end.clamp(0, maxP),
                                    ),
                                    maxP,
                                  );
                                  _priceMinC.text = _fmtPrice(_d.priceMin);
                                  _priceMaxC.text = _fmtPrice(_d.priceMax);
                                });
                              },
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _priceMinC,
                                    keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Mín \$',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _priceMaxC,
                                    keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Máx \$',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _chipSet(
                        'Proyección',
                        c.distinctProjections,
                        _d.projections,
                        (s) => setState(() => _d = _d.copyWith(projections: s)),
                      ),
                      _chipSet(
                        'Duración',
                        c.distinctDurations,
                        _d.durations,
                        (s) => setState(() => _d = _d.copyWith(durations: s)),
                      ),
                      _chipSet(
                        'Perfil',
                        c.distinctProfiles,
                        _d.profiles,
                        (s) => setState(() => _d = _d.copyWith(profiles: s)),
                      ),
                      _chipSet(
                        'Proveedor',
                        c.distinctSuppliers,
                        _d.suppliers,
                        (s) => setState(() => _d = _d.copyWith(suppliers: s)),
                      ),
                      _chipSet(
                        'Ropa',
                        const ['Formal', 'Casual', 'Ambas'],
                        _d.clothing,
                        (s) => setState(() => _d = _d.copyWith(clothing: s)),
                      ),
                      _chipSet(
                        'Horario',
                        const ['Día', 'Noche', 'Ambas'],
                        _d.timeOfDay,
                        (s) => setState(() => _d = _d.copyWith(timeOfDay: s)),
                      ),
                      _chipSet(
                        'Clima',
                        const ['Frío', 'Calor', 'Ambas'],
                        _d.weather,
                        (s) => setState(() => _d = _d.copyWith(weather: s)),
                      ),
                      const SizedBox(height: 8),
                      _tri('Reponer', _d.refill,
                          (v) => setState(() => _d = _d.copyWith(refill: v))),
                      _tri('Top colección', _d.topCollection,
                          (v) => setState(() => _d = _d.copyWith(topCollection: v))),
                      _tri('Playa', _d.beach,
                          (v) => setState(() => _d = _d.copyWith(beach: v))),
                      _tri('Salidas', _d.outings,
                          (v) => setState(() => _d = _d.copyWith(outings: v))),
                      _tri('Oficina', _d.office,
                          (v) => setState(() => _d = _d.copyWith(office: v))),
                      _tri('Familiar', _d.family,
                          (v) => setState(() => _d = _d.copyWith(family: v))),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }),
            ),
            Row(
              children: [
                Expanded(
                  child: AuraSecondaryButton(
                    label: 'Quitar filtros',
                    onTap: _clear,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AuraPrimaryButton(
                    label: 'Aplicar',
                    onTap: _apply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _openCatalogFiltersSheet(CatalogFiltersTarget target) {
  final ctx = Get.context;
  final h = (ctx == null ? 640.0 : MediaQuery.sizeOf(ctx).height) * 0.88;
  AppLog.navigate('OPEN bottomSheet', 'CatalogFiltersSheet.${target.name}');
  Get.bottomSheet(
    SizedBox(
      height: h,
      child: CatalogFiltersSheet(target: target),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

void openLibraryFiltersSheet() =>
    _openCatalogFiltersSheet(CatalogFiltersTarget.library);

void openChooseFiltersSheet() =>
    _openCatalogFiltersSheet(CatalogFiltersTarget.choose);
