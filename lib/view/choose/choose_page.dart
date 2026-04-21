import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/getx_controllers/home/home_nav_controller.dart';
import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_routes.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../widgets/aura_buttons.dart';
import '../../widgets/aura_choice_chip.dart';
import '../../widgets/aura_pill.dart';
import '../../widgets/perfume_card.dart';

class ChoosePage extends StatefulWidget {
  const ChoosePage({super.key});

  @override
  State<ChoosePage> createState() => _ChoosePageState();
}

class _ChoosePageState extends State<ChoosePage> {
  final _scroll = ScrollController();

  static double _gridHeight(BuildContext context, int count) {
    if (count == 0) return 120;
    const cols = 2;
    const spacing = 14.0;
    const aspect = 0.78;
    final w = MediaQuery.sizeOf(context).width - 36 - (cols - 1) * spacing;
    final cellW = w / cols;
    final cellH = cellW / aspect;
    final rows = (count / cols).ceil();
    return rows * cellH + (rows - 1) * spacing;
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fillChooseIfUnderscroll());
  }

  Future<void> _fillChooseIfUnderscroll() async {
    if (!mounted) return;
    final c = Get.find<PerfumeController>();
    for (var i = 0; i < 30 && mounted; i++) {
      if (!_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent > 80) return;
      if (!c.chooseCanLoadMore) return;
      await c.loadMoreChoose();
      await Future<void>.delayed(Duration.zero);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (!pos.hasViewportDimension) return;
    if (pos.pixels >= pos.maxScrollExtent - 160) {
      final c = Get.find<PerfumeController>();
      if (c.chooseCanLoadMore) {
        AppLog.action(
          'Choose tab scroll near end → load more grid rows',
          {
            'visibleAfter': (c.chooseVisibleCount.value +
                    PerfumeController.pageSize)
                .clamp(0, c.perfumes.length),
            'totalPerfumes': c.perfumes.length,
          },
        );
      }
      c.loadMoreChoose();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Recomendaciones\nPara ti', style: AppTextStyles.screenTitle),
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
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          AuraPill(
                              icon: Icons.wb_sunny_outlined, text: 'DÍA - 14:35'),
                          AuraPill(
                              icon: Icons.thermostat_outlined,
                              text: 'CALOR - 32°C'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('OCASIÓN', style: AppTextStyles.caption),
                      const SizedBox(height: 10),
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AuraChoiceChip(text: 'Oficina', selected: true),
                          AuraChoiceChip(text: 'Salidas'),
                          AuraChoiceChip(text: 'Playa'),
                          AuraChoiceChip(text: 'Familia'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('ESTILO', style: AppTextStyles.caption),
                      const SizedBox(height: 10),
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AuraChoiceChip(text: 'Casual', selected: true),
                          AuraChoiceChip(text: 'Formal'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AuraPrimaryButton(
                        label: 'Buscar',
                        onTap: () {
                          AppLog.tap(
                            'Choose',
                            'Recommendations card: Buscar (go to Library tab + snackbar)',
                          );
                          Get.find<HomeNavController>().setTab(0);
                          Get.snackbar(
                            'Biblioteca',
                            'Usa el buscador en Mi Biblioteca para filtrar tu catálogo.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Obx(() {
                  final n = Get.find<PerfumeController>().perfumes.length;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Recomendaciones\nPara ti',
                          style: AppTextStyles.perfumeName.copyWith(fontSize: 20),
                        ),
                      ),
                      Text(
                        '$n\nFRAGANCIAS ENCONTRADAS',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(() {
              final c = Get.find<PerfumeController>();
              final items = c.chooseSlice;
              final loadingMore = c.chooseLoadingMore.value;

              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'Sin perfumes en la biblioteca.',
                    style: AppTextStyles.bodyMuted,
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: _gridHeight(context, items.length),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final p = items[i];
                          return PerfumeCard(
                            perfume: p,
                            variant: PerfumeCardVariant.recommendationTile,
                            onTap: () {
                              final route = AppRoutes.perfumeDetail
                                  .replaceFirst(':id', p.id);
                              AppLog.navigate(
                                'OPEN full detail (from Choose grid)',
                                route,
                                AppLog.perfumeSummary(p),
                              );
                              Get.toNamed(route);
                            },
                          );
                        },
                      ),
                    ),
                    if (loadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            sliver: SliverToBoxAdapter(
              child: AuraSecondaryButton(
                label: 'Elección aleatoria',
                onTap: () {
                  AppLog.navigate(
                    'OPEN',
                    AppRoutes.recommendationSpotlight,
                    {'from': 'Choose tab → Elección aleatoria'},
                  );
                  Get.toNamed(AppRoutes.recommendationSpotlight);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
