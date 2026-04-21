import '../../domain/perfume/perfume.dart';
import 'app_log.dart';
import 'perfume_database.dart';

/// Persists the catalog in SQLite ([PerfumeDatabase]).
class PerfumeStore {
  final _db = PerfumeDatabase.instance;

  Future<List<Perfume>> load() async {
    AppLog.db('PerfumeStore.load → SQLite.queryAllOrderedByName');
    final list = await _db.queryAllOrderedByName();
    AppLog.db('PerfumeStore.load ← done', {'perfumeCount': list.length});
    return list;
  }

  Future<void> save(List<Perfume> perfumes) async {
    AppLog.db(
      'PerfumeStore.save → SQLite.replaceAll',
      {'perfumeCount': perfumes.length},
    );
    await _db.replaceAll(perfumes);
    AppLog.db('PerfumeStore.save ← committed');
  }
}
