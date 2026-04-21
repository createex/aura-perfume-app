import 'package:uuid/uuid.dart';

import '../../domain/perfume/perfume.dart';
import 'perfume_store.dart';

class PerfumeRepository {
  final PerfumeStore _store;
  final _uuid = const Uuid();

  PerfumeRepository(this._store);

  Future<List<Perfume>> getAll() => _store.load();

  Future<void> upsert(Perfume perfume) async {
    final all = await _store.load();
    final idx = all.indexWhere((p) => p.id == perfume.id);
    final next = [...all];
    if (idx >= 0) {
      next[idx] = perfume;
    } else {
      next.add(perfume);
    }
    await _store.save(next);
  }

  Future<Perfume> create({
    required String brand,
    required String name,
    double rating = 0,
    String? imagePath,
  }) async {
    final perfume = Perfume(
      id: _uuid.v4(),
      brand: brand,
      name: name,
      rating: rating,
      imagePath: imagePath,
    );
    await upsert(perfume);
    return perfume;
  }

  Future<void> deleteById(String id) async {
    final all = await _store.load();
    await _store.save(all.where((p) => p.id != id).toList(growable: false));
  }
}

