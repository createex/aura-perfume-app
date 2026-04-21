import 'package:get/get.dart';

import '../../utils/app_log.dart';
import '../../utils/perfume_image_resolver.dart';
import '../../utils/perfume_repository.dart';
import '../../../domain/perfume/perfume.dart';

class PerfumeController extends GetxController {
  PerfumeController(this._repo);
  final PerfumeRepository _repo;

  static const int pageSize = 15;

  final isLoading = false.obs;
  final query = ''.obs;
  final perfumes = <Perfume>[].obs;

  /// Cuántos ítems mostrar en Biblioteca (scroll infinito).
  final libraryVisibleCount = pageSize.obs;

  final libraryLoadingMore = false.obs;

  /// Cuántos ítems mostrar en Elegir (scroll infinito).
  final chooseVisibleCount = pageSize.obs;

  final chooseLoadingMore = false.obs;

  List<Perfume> get filtered {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return perfumes;
    return perfumes
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<Perfume> _orderedByRating(List<Perfume> list) {
    final out = List<Perfume>.from(list);
    out.sort((a, b) => b.rating.compareTo(a.rating));
    return out;
  }

  List<Perfume> get _orderedPerfumes => _orderedByRating(perfumes);

  List<Perfume> get librarySlice {
    libraryVisibleCount.value;
    libraryLoadingMore.value;
    final all = filtered;
    if (all.isEmpty) return const [];
    final cap = libraryVisibleCount.value.clamp(0, all.length);
    return all.take(cap).toList(growable: false);
  }

  bool get libraryCanLoadMore =>
      libraryVisibleCount.value < filtered.length;

  bool get chooseCanLoadMore =>
      chooseVisibleCount.value < _orderedPerfumes.length;

  List<Perfume> get chooseSlice {
    chooseVisibleCount.value;
    chooseLoadingMore.value;
    final all = _orderedPerfumes;
    if (all.isEmpty) return const [];
    final cap = chooseVisibleCount.value.clamp(0, all.length);
    return all.take(cap).toList(growable: false);
  }

  Future<void> loadMoreLibrary() async {
    final all = filtered;
    if (libraryVisibleCount.value >= all.length) return;
    if (libraryLoadingMore.value) return;
    libraryLoadingMore.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 220));
      final next = (libraryVisibleCount.value + pageSize).clamp(0, all.length);
      libraryVisibleCount.value = next;
      AppLog.action(
        'PerfumeController.loadMoreLibrary applied',
        {
          'libraryVisibleCount': next,
          'filteredTotal': all.length,
        },
      );
    } finally {
      libraryLoadingMore.value = false;
    }
  }

  Future<void> loadMoreChoose() async {
    final all = _orderedPerfumes;
    if (chooseVisibleCount.value >= all.length) return;
    if (chooseLoadingMore.value) return;
    chooseLoadingMore.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 220));
      final next = (chooseVisibleCount.value + pageSize).clamp(0, all.length);
      chooseVisibleCount.value = next;
      AppLog.action(
        'PerfumeController.loadMoreChoose applied',
        {
          'chooseVisibleCount': next,
          'orderedTotal': all.length,
        },
      );
    } finally {
      chooseLoadingMore.value = false;
    }
  }

  void _resetListWindows() {
    final all = filtered;
    libraryVisibleCount.value =
        all.length < pageSize ? all.length : pageSize;
    final ord = _orderedPerfumes;
    chooseVisibleCount.value =
        ord.length < pageSize ? ord.length : pageSize;
  }

  @override
  void onInit() {
    super.onInit();
    ever(query, (_) => _resetListWindows());
    refreshPerfumes();
  }

  List<Perfume> _withResolvedImages(List<Perfume> list) {
    final r = PerfumeImageResolver.instance;
    return list.map((p) {
      final hasAsset =
          p.imagePath != null && p.imagePath!.startsWith('assets/');
      if (hasAsset) return p;
      final m = r.matchFor(p);
      if (m == null) return p;
      return p.copyWith(imagePath: m);
    }).toList(growable: false);
  }

  Future<void> refreshPerfumes() async {
    AppLog.catalog('PerfumeController.refreshPerfumes started');
    isLoading.value = true;
    try {
      await PerfumeImageResolver.instance.ensureLoaded();
      final raw = await _repo.getAll();
      perfumes.assignAll(_withResolvedImages(raw));
      perfumes.sort((a, b) => b.rating.compareTo(a.rating));
      _resetListWindows();
      AppLog.catalog(
        'PerfumeController.refreshPerfumes finished',
        {
          'perfumeCount': perfumes.length,
          'resolverIndexedAssets':
              PerfumeImageResolver.instance.indexedRasterAssetCount,
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  Perfume? byId(String id) {
    try {
      return perfumes.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    AppLog.action('PerfumeController.delete', {'id': id});
    await _repo.deleteById(id);
    await refreshPerfumes();
  }

  Future<Perfume> createQuick({
    required String brand,
    required String name,
  }) async {
    final created = await _repo.create(brand: brand, name: name);
    await refreshPerfumes();
    return created;
  }

  Future<void> upsert(Perfume perfume) async {
    AppLog.catalog(
      'PerfumeController.upsert',
      AppLog.perfumeSummary(perfume),
    );
    await _repo.upsert(perfume);
    await refreshPerfumes();
  }
}
