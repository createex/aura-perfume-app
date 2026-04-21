import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_routes.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../widgets/aura_search_field.dart';
import '../../widgets/perfume_collection_view.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fillLibraryIfUnderscroll());
  }

  /// Si todo cabe en pantalla, no habría scroll: carga más hasta poder desplazar o agotar datos.
  Future<void> _fillLibraryIfUnderscroll() async {
    if (!mounted) return;
    final c = Get.find<PerfumeController>();
    for (var i = 0; i < 30 && mounted; i++) {
      if (!_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent > 80) return;
      if (!c.libraryCanLoadMore) return;
      await c.loadMoreLibrary();
      await Future<void>.delayed(Duration.zero);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (!pos.hasViewportDimension) return;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      final c = Get.find<PerfumeController>();
      if (c.libraryCanLoadMore) {
        AppLog.action(
          'Library scroll near end → load more rows',
          {
            'visibleAfter': (c.libraryVisibleCount.value +
                    PerfumeController.pageSize)
                .clamp(0, c.filtered.length),
            'totalFiltered': c.filtered.length,
          },
        );
      }
      c.loadMoreLibrary();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PerfumeController>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text('Mi Biblioteca', style: AppTextStyles.screenTitle),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: AuraSearchField(
                controller: _search,
                onChanged: (v) {
                  c.query.value = v;
                  AppLog.librarySearchQueryChanged(v);
                },
                onFilter: () {
                  AppLog.navigate(
                    'OPEN',
                    AppRoutes.inventoryImport,
                    {'from': 'Library search filter button'},
                  );
                  Get.toNamed(AppRoutes.inventoryImport);
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final total = c.filtered.length;
                if (total == 0) {
                  return Center(
                    child: Text(
                      'No hay perfumes todavía.\nImporta desde Excel o añade uno con +',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                  );
                }
                final items = c.librarySlice;
                final loadingMore = c.libraryLoadingMore.value;
                return PerfumeCollectionView(
                  scrollController: _scroll,
                  items: items,
                  layout: PerfumeCollectionLayout.list,
                  listLoadingMore: loadingMore,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  onItemTap: (p) {
                    final route =
                        AppRoutes.perfumeDetail.replaceFirst(':id', p.id);
                    AppLog.navigate(
                      'OPEN full detail (from Library list)',
                      route,
                      AppLog.perfumeSummary(p),
                    );
                    Get.toNamed(route);
                  },
                );
              }),
            ),
            Container(height: 1, color: AppColors.background),
          ],
        ),
      ),
    );
  }
}
