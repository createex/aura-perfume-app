class AppRoutes {
  static const home = '/';

  // Tabs
  static const library = '/library';
  static const choose = '/choose';

  // Perfume
  static const perfumeDetail = '/perfume/:id';
  /// Vista plantilla desde Biblioteca (sin ficha completa).
  static const perfumeDetailPlantilla = '/perfume/:id/plantilla';
  static const perfumeEdit = '/perfume/:id/edit';
  static const perfumeCreate = '/perfume/create';

  /// Recomendación destacada (elección aleatoria).
  static const recommendationSpotlight = '/recommendation';

  // Inventory / import
  static const inventoryImport = '/inventory/import';
}
