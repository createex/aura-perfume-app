import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../controller/getx_controllers/perfume/perfume_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_routes.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../domain/perfume/perfume.dart';
import '../../widgets/aura_search_field.dart';
import '../../widgets/perfume_card.dart';
import 'library_filters_sheet.dart';

String _catalogLetterKey(String name) {
  if (name.isEmpty) return '#';
  final c = name[0].toUpperCase();
  if (c.compareTo('A') >= 0 && c.compareTo('Z') <= 0) return c;
  return '#';
}

int? _indexForLetter(String letter, List<Perfume> items) {
  final want = letter == '#' ? '#' : letter.toUpperCase();
  for (var i = 0; i < items.length; i++) {
    final k = _catalogLetterKey(items[i].name);
    if (k == want) return i;
  }
  return null;
}

class _LetterRail extends StatelessWidget {
  const _LetterRail({
    required this.items,
    required this.onLetter,
  });

  final List<Perfume> items;
  final void Function(String letter) onLetter;

  @override
  Widget build(BuildContext context) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final hasHash = items.any((p) => _catalogLetterKey(p.name) == '#');
    return Container(
      width: 28,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: Border(
          left: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          for (final ch in letters.split(''))
            _LetterCell(
              label: ch,
              enabled: items.any((p) => _catalogLetterKey(p.name) == ch),
              onTap: () => onLetter(ch),
            ),
          if (hasHash)
            _LetterCell(
              label: '#',
              enabled: true,
              onTap: () => onLetter('#'),
            ),
        ],
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        height: 16,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? AppColors.primary
                  : AppColors.textTertiary.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _search = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    AppLog.startup('LibraryPage initState (Mi Biblioteca tab body)');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _jumpTo(String letter, List<Perfume> items) {
    final idx = _indexForLetter(letter, items);
    if (idx == null) return;
    AppLog.tap('Library', 'Alphabet rail → scroll', {'letter': letter, 'index': idx});
    _itemScrollController.scrollTo(
      index: idx,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
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
              child: Obx(() {
                final n = c.libraryList.length;
                return Text(
                  'Mi Biblioteca ($n)',
                  style: AppTextStyles.screenTitle,
                );
              }),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Obx(() {
                final active =
                    c.libraryFilter.value.isActive(c.catalogMaxPrice);
                return AuraSearchField(
                  controller: _search,
                  filterActive: active,
                  onChanged: (v) {
                    c.query.value = v;
                    AppLog.librarySearchQueryChanged(v);
                  },
                  onFilter: () {
                    AppLog.tap('Library', 'Open filter sheet (tune icon)');
                    openLibraryFiltersSheet();
                  },
                );
              }),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (c.perfumes.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay perfumes todavía.\nImporta desde Excel o añade uno con +',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                  );
                }
                final items = c.libraryList;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Ningún perfume coincide con los filtros.\nAjusta o quita filtros.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        padding: const EdgeInsets.fromLTRB(18, 14, 8, 0),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final p = items[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < items.length - 1 ? 14 : 0,
                            ),
                            child: PerfumeCard(
                              perfume: p,
                              variant: PerfumeCardVariant.libraryRow,
                              onTap: () {
                                final route = AppRoutes.perfumeDetail
                                    .replaceFirst(':id', p.id);
                                AppLog.navigate(
                                  'OPEN full detail (from Library list)',
                                  route,
                                  AppLog.perfumeSummary(p),
                                );
                                Get.toNamed(route);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    _LetterRail(
                      items: items,
                      onLetter: (L) => _jumpTo(L, items),
                    ),
                  ],
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
