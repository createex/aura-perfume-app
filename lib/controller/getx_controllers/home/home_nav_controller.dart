import 'package:get/get.dart';

import '../../utils/app_log.dart';

class HomeNavController extends GetxController {
  final tabIndex = 0.obs;

  void setTab(int idx) {
    final label = idx == 0 ? 'Library (Mi Biblioteca)' : 'Choose (Qué usar)';
    AppLog.action(
      'Home bottom tab selected',
      {'tabIndex': idx, 'tab': label},
    );
    tabIndex.value = idx;
  }
}

