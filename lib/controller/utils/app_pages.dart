import 'package:get/get.dart';

import 'app_routes.dart';
import '../../view/home/home_page.dart';
import '../../view/perfume/perfume_detail_page.dart';
import '../../view/perfume/perfume_detail_template_page.dart';
import '../../view/perfume/perfume_edit_page.dart';
import '../../view/recommendation/recommendation_spotlight_page.dart';
import '../../view/inventory/inventory_import_page.dart';
import '../bindings/app_bindings.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: AppBindings(),
    ),
    GetPage(name: AppRoutes.library, page: () => const HomePage(initialTab: 0)),
    GetPage(name: AppRoutes.choose, page: () => const HomePage(initialTab: 1)),
    GetPage(name: AppRoutes.perfumeDetail, page: () => const PerfumeDetailPage()),
    GetPage(
      name: AppRoutes.perfumeDetailPlantilla,
      page: () => const PerfumeDetailTemplatePage(),
    ),
    GetPage(
      name: AppRoutes.recommendationSpotlight,
      page: () => const RecommendationSpotlightPage(),
    ),
    GetPage(name: AppRoutes.perfumeEdit, page: () => const PerfumeEditPage()),
    GetPage(name: AppRoutes.perfumeCreate, page: () => const PerfumeEditPage()),
    GetPage(name: AppRoutes.inventoryImport, page: () => const InventoryImportPage()),
  ];
}
