import 'package:get/get.dart';

import '../../utils/app_log.dart';
import '../../utils/perfume_repository.dart';
import '../../../domain/library/library_catalog_filter.dart';
import '../../../domain/perfume/perfume.dart';

class PerfumeController extends GetxController {
  PerfumeController(this._repo);
  final PerfumeRepository _repo;

  final isLoading = false.obs;
  final query = ''.obs;
  final perfumes = <Perfume>[].obs;

  /// Library facet filters (Mi Biblioteca).
  final libraryFilter = LibraryCatalogFilter.initial(catalogMaxPrice: 0).obs;

  /// Qué usar — same field model as [libraryFilter], separate session.
  final chooseFilter = LibraryCatalogFilter.initial(catalogMaxPrice: 0).obs;

  /// Quick search on Qué usar (name / brand), does not switch tabs.
  final chooseQuery = ''.obs;

  double _catalogMaxPrice = 0;

  double get catalogMaxPrice => _catalogMaxPrice;

  List<Perfume> get libraryList {
    libraryFilter.value;
    query.value;
    final cap = _catalogMaxPrice;
    final f = libraryFilter.value;
    final q = query.value;
    return perfumes
        .where((p) => f.matches(p, searchQuery: q, catalogMaxPrice: cap))
        .toList(growable: false);
  }

  /// Qué usar: [chooseQuery] + [chooseFilter], sorted catalog order preserved.
  List<Perfume> get chooseList {
    chooseFilter.value;
    chooseQuery.value;
    final cap = _catalogMaxPrice;
    final f = chooseFilter.value;
    final q = chooseQuery.value;
    return perfumes
        .where((p) => f.matches(p, searchQuery: q, catalogMaxPrice: cap))
        .toList(growable: false);
  }

  static double _maxPriceOf(Iterable<Perfume> list) {
    var m = 0.0;
    for (final p in list) {
      final x = p.price;
      if (x != null && x > m) m = x;
    }
    return m;
  }

  List<String> _distinctStrings(Iterable<String?> raw) {
    final s = <String>{};
    for (final v in raw) {
      final t = (v ?? '').trim();
      if (t.isEmpty || t == '-') continue;
      s.add(t);
    }
    final out = s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  List<String> get distinctProfiles =>
      _distinctStrings(perfumes.map((p) => p.profile));

  List<String> get distinctSuppliers =>
      _distinctStrings(perfumes.map((p) => p.supplierOrOrigin));

  List<String> get distinctProjections =>
      _distinctStrings(perfumes.map((p) => p.proyeccion));

  List<String> get distinctDurations =>
      _distinctStrings(perfumes.map((p) => p.duracion));

  void setLibraryFilter(LibraryCatalogFilter next) {
    AppLog.catalog(
      'PerfumeController.setLibraryFilter',
      {'active': next.isActive(_catalogMaxPrice)},
    );
    libraryFilter.value = next;
  }

  void clearLibraryFilters() {
    AppLog.action('PerfumeController.clearLibraryFilters');
    final cap = LibraryCatalogFilter.catalogPriceCeiling(_catalogMaxPrice);
    libraryFilter.value = LibraryCatalogFilter.initial(catalogMaxPrice: cap);
  }

  void setChooseFilter(LibraryCatalogFilter next) {
    AppLog.catalog(
      'PerfumeController.setChooseFilter',
      {'active': next.isActive(_catalogMaxPrice)},
    );
    chooseFilter.value = next;
  }

  void clearChooseFilters() {
    AppLog.action('PerfumeController.clearChooseFilters');
    final cap = LibraryCatalogFilter.catalogPriceCeiling(_catalogMaxPrice);
    chooseFilter.value = LibraryCatalogFilter.initial(catalogMaxPrice: cap);
    chooseQuery.value = '';
  }

  void _syncPriceCeilingsAfterLoad() {
    final cap = _catalogMaxPrice;
    if (cap <= 0) return;
    for (final rx in [libraryFilter, chooseFilter]) {
      final f = rx.value;
      if (f.priceMax < cap - 0.01) {
        rx.value = f.copyWith(priceMax: cap);
      }
    }
  }

  /// Earlier builds used [LibraryCatalogFilter.ratingMin] = 1 by default, which hid
  /// perfumes with rating 0 (empty Excel → stored as 0).
  void _migrateLegacyRatingMinOne() {
    for (final rx in [libraryFilter, chooseFilter]) {
      final f = rx.value;
      if (f.ratingMin == 1) {
        rx.value = f.copyWith(ratingMin: 0);
      }
    }
  }

  /// Older sheet versions clamped [priceMax] to ~\$1 when [catalogMaxPrice] was still 0.
  void _repairBogusPriceFiltersAfterLoad() {
    final cap = _catalogMaxPrice;
    if (cap <= 50) return;
    for (final rx in [libraryFilter, chooseFilter]) {
      final f = rx.value;
      if (f.priceMin <= 0.01 && f.priceMax <= 1.01 && f.priceMax >= 0.99) {
        rx.value = f.copyWith(
          priceMin: 0,
          priceMax: LibraryCatalogFilter.catalogPriceCeiling(cap),
        );
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    refreshPerfumes();
  }

  Future<void> refreshPerfumes() async {
    final t0 = DateTime.now();
    AppLog.catalog('PerfumeController.refreshPerfumes started');
    isLoading.value = true;
    try {
      final raw = await _repo.getAll();
      perfumes.assignAll(raw);
      perfumes.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _catalogMaxPrice = _maxPriceOf(perfumes);
      _syncPriceCeilingsAfterLoad();
      _repairBogusPriceFiltersAfterLoad();
      _migrateLegacyRatingMinOne();
      AppLog.catalog(
        'PerfumeController.refreshPerfumes finished',
        {
          'perfumeCount': perfumes.length,
          'catalogMaxPrice': _catalogMaxPrice,
          'libraryFilteredCount': libraryList.length,
          'chooseFilteredCount': chooseList.length,
          'queryTrimmedLength': query.value.trim().length,
          'elapsedMs': DateTime.now().difference(t0).inMilliseconds,
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
