import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_routes.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../domain/library/library_catalog_filter.dart';
import '../library/library_filters_sheet.dart';
import '../../widgets/aura_buttons.dart';
import '../../widgets/aura_choice_chip.dart';
import '../../widgets/perfume_card.dart';

class ChoosePage extends StatefulWidget {
  const ChoosePage({super.key});

  @override
  State<ChoosePage> createState() => _ChoosePageState();
}

class _ChoosePageState extends State<ChoosePage> {
  late final TextEditingController _searchQ;
  Worker? _chooseQueryWorker;

  @override
  void initState() {
    super.initState();
    AppLog.startup('ChoosePage initState (Qué usar tab body)');
    final c = Get.find<PerfumeController>();
    _searchQ = TextEditingController(text: c.chooseQuery.value);
    _searchQ.addListener(_onSearchChanged);
    _chooseQueryWorker = ever<String>(c.chooseQuery, (q) {
      if (_searchQ.text != q) {
        _searchQ.text = q;
        _searchQ.selection = TextSelection.collapsed(offset: q.length.clamp(0, q.length));
      }
    });
  }

  void _onSearchChanged() {
    final c = Get.find<PerfumeController>();
    final t = _searchQ.text;
    if (c.chooseQuery.value != t) {
      c.chooseQuery.value = t;
      AppLog.librarySearchQueryChanged('choose:$t');
    }
  }

  @override
  void dispose() {
    _chooseQueryWorker?.dispose();
    _searchQ.removeListener(_onSearchChanged);
    _searchQ.dispose();
    super.dispose();
  }

  static void _setTime(PerfumeController c, Set<String> next) {
    c.setChooseFilter(c.chooseFilter.value.copyWith(timeOfDay: next));
  }

  static void _setWeather(PerfumeController c, Set<String> next) {
    c.setChooseFilter(c.chooseFilter.value.copyWith(weather: next));
  }

  static void _toggleOffice(PerfumeController c) {
    final f = c.chooseFilter.value;
    final next = f.office == TriStateFilter.yes ? TriStateFilter.any : TriStateFilter.yes;
    c.setChooseFilter(f.copyWith(office: next));
  }

  static void _toggleOutings(PerfumeController c) {
    final f = c.chooseFilter.value;
    final next =
        f.outings == TriStateFilter.yes ? TriStateFilter.any : TriStateFilter.yes;
    c.setChooseFilter(f.copyWith(outings: next));
  }

  static void _toggleBeach(PerfumeController c) {
    final f = c.chooseFilter.value;
    final next = f.beach == TriStateFilter.yes ? TriStateFilter.any : TriStateFilter.yes;
    c.setChooseFilter(f.copyWith(beach: next));
  }

  static void _toggleFamily(PerfumeController c) {
    final f = c.chooseFilter.value;
    final next =
        f.family == TriStateFilter.yes ? TriStateFilter.any : TriStateFilter.yes;
    c.setChooseFilter(f.copyWith(family: next));
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PerfumeController>();
    return SafeArea(
      top: false,
      child: Obx(() {
        final items = c.chooseList;
        final f = c.chooseFilter.value;
        final filterActive = f.isActive(c.catalogMaxPrice) ||
            c.chooseQuery.value.trim().isNotEmpty;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Qué usar', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A0B1634),
                          blurRadius: 22,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HORARIO', style: AppTextStyles.caption),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AuraChoiceChip(
                              text: 'Cualquiera',
                              selected: f.timeOfDay.isEmpty,
                              onTap: () => _setTime(c, {}),
                            ),
                            AuraChoiceChip(
                              text: 'Día',
                              selected: f.timeOfDay.contains('Día'),
                              onTap: () => _setTime(c, {'Día'}),
                            ),
                            AuraChoiceChip(
                              text: 'Noche',
                              selected: f.timeOfDay.contains('Noche'),
                              onTap: () => _setTime(c, {'Noche'}),
                            ),
                            AuraChoiceChip(
                              text: 'Ambas',
                              selected: f.timeOfDay.contains('Ambas'),
                              onTap: () => _setTime(c, {'Ambas'}),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('CLIMA', style: AppTextStyles.caption),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AuraChoiceChip(
                              text: 'Cualquiera',
                              selected: f.weather.isEmpty,
                              onTap: () => _setWeather(c, {}),
                            ),
                            AuraChoiceChip(
                              text: 'Frío',
                              selected: f.weather.contains('Frío'),
                              onTap: () => _setWeather(c, {'Frío'}),
                            ),
                            AuraChoiceChip(
                              text: 'Calor',
                              selected: f.weather.contains('Calor'),
                              onTap: () => _setWeather(c, {'Calor'}),
                            ),
                            AuraChoiceChip(
                              text: 'Ambas',
                              selected: f.weather.contains('Ambas'),
                              onTap: () => _setWeather(c, {'Ambas'}),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('OCASIÓN', style: AppTextStyles.caption),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AuraChoiceChip(
                              text: 'Oficina',
                              selected: f.office == TriStateFilter.yes,
                              onTap: () => _toggleOffice(c),
                            ),
                            AuraChoiceChip(
                              text: 'Salidas',
                              selected: f.outings == TriStateFilter.yes,
                              onTap: () => _toggleOutings(c),
                            ),
                            AuraChoiceChip(
                              text: 'Playa',
                              selected: f.beach == TriStateFilter.yes,
                              onTap: () => _toggleBeach(c),
                            ),
                            AuraChoiceChip(
                              text: 'Familia',
                              selected: f.family == TriStateFilter.yes,
                              onTap: () => _toggleFamily(c),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('ESTILO (ropa)', style: AppTextStyles.caption),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AuraChoiceChip(
                              text: 'Cualquiera',
                              selected: f.clothing.isEmpty,
                              onTap: () => c.setChooseFilter(
                                c.chooseFilter.value.copyWith(clothing: {}),
                              ),
                            ),
                            AuraChoiceChip(
                              text: 'Casual',
                              selected: f.clothing.contains('Casual'),
                              onTap: () => c.setChooseFilter(
                                c.chooseFilter.value.copyWith(clothing: {'Casual'}),
                              ),
                            ),
                            AuraChoiceChip(
                              text: 'Formal',
                              selected: f.clothing.contains('Formal'),
                              onTap: () => c.setChooseFilter(
                                c.chooseFilter.value.copyWith(clothing: {'Formal'}),
                              ),
                            ),
                            AuraChoiceChip(
                              text: 'Ambas',
                              selected: f.clothing.contains('Ambas'),
                              onTap: () => c.setChooseFilter(
                                c.chooseFilter.value.copyWith(clothing: {'Ambas'}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('BUSCAR EN RESULTADOS', style: AppTextStyles.caption),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchQ,
                          decoration: InputDecoration(
                            hintText: 'Nombre o marca…',
                            hintStyle: AppTextStyles.bodyMuted,
                            filled: true,
                            fillColor: AppColors.surfaceMuted,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AuraSecondaryButton(
                          label: 'Filtros completos',
                          onTap: () {
                            AppLog.tap('Choose', 'Open full filter sheet');
                            openChooseFiltersSheet();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuraSecondaryButton(
                    label: 'Elección aleatoria',
                    onTap: () {
                      AppLog.navigate(
                        'OPEN',
                        AppRoutes.recommendationSpotlight,
                        {
                          'from':
                              'Choose tab → Elección aleatoria (pool=chooseList)',
                        },
                      );
                      Get.toNamed(AppRoutes.recommendationSpotlight);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Coincidencias',
                          style: AppTextStyles.perfumeName.copyWith(fontSize: 20),
                        ),
                      ),
                      Text(
                        '${items.length}\nFRAGANCIAS',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.caption.copyWith(
                          color: filterActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            if (c.perfumes.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'Sin perfumes en la biblioteca.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'Ninguna fragancia coincide. Afloja filtros o busca otra cosa.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = items[i];
                      return PerfumeCard(
                        perfume: p,
                        variant: PerfumeCardVariant.recommendationTile,
                        onTap: () {
                          final route =
                              AppRoutes.perfumeDetail.replaceFirst(':id', p.id);
                          AppLog.navigate(
                            'OPEN full detail (from Choose grid)',
                            route,
                            AppLog.perfumeSummary(p),
                          );
                          Get.toNamed(route);
                        },
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
