import 'package:get/get.dart';

import '../utils/perfume_repository.dart';
import '../utils/perfume_store.dart';
import '../getx_controllers/home/home_nav_controller.dart';
import '../getx_controllers/perfume/perfume_controller.dart';
import '../getx_controllers/inventory/inventory_import_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(PerfumeStore(), permanent: true);
    Get.put(PerfumeRepository(Get.find<PerfumeStore>()), permanent: true);

    Get.put(HomeNavController(), permanent: true);
    Get.put(PerfumeController(Get.find<PerfumeRepository>()), permanent: true);
    Get.put(InventoryImportController(Get.find<PerfumeRepository>()),
        permanent: true);
  }
}

