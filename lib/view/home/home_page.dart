import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/getx_controllers/home/home_nav_controller.dart';
import '../../controller/utils/app_colors.dart';
import '../../controller/utils/app_log.dart';
import '../../controller/utils/app_routes.dart';
import '../../controller/utils/app_text_styles.dart';
import '../../view/choose/choose_page.dart';
import '../../view/library/library_page.dart';
import '../../widgets/aura_app_bar.dart';
import '../../widgets/aura_bottom_nav.dart';

class HomePage extends StatefulWidget {
  final int initialTab;
  const HomePage({super.key, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeNavController nav;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    nav = Get.find<HomeNavController>();
    AppLog.startup(
      'HomePage initState',
      {
        'initialTabIndex': widget.initialTab,
        'tabName': widget.initialTab == 0 ? 'Library' : 'Choose',
      },
    );
    nav.setTab(widget.initialTab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('AURA', style: AppTextStyles.screenTitle),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.local_library_outlined),
                title: Text('Mi biblioteca', style: AppTextStyles.body),
                onTap: () {
                  AppLog.tap('Home', 'Drawer: Mi biblioteca (switch to Library tab)');
                  Get.back();
                  nav.setTab(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: Text('Qué usar', style: AppTextStyles.body),
                onTap: () {
                  AppLog.tap('Home', 'Drawer: Qué usar (switch to Choose tab)');
                  Get.back();
                  nav.setTab(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text('Importar inventario', style: AppTextStyles.body),
                onTap: () {
                  AppLog.navigate(
                    'OPEN',
                    AppRoutes.inventoryImport,
                    {'from': 'Home drawer'},
                  );
                  Get.back();
                  Get.toNamed(AppRoutes.inventoryImport);
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AuraAppBar(
        onMenu: () {
          AppLog.tap('Home', 'App bar: open menu (drawer)');
          _scaffoldKey.currentState?.openDrawer();
        },
        onSearch: () {
          AppLog.tap(
            'Home',
            'App bar: search hint (switch to Library + snackbar)',
          );
          nav.setTab(0);
          Get.snackbar(
            'Buscar',
            'Escribe en el campo «Buscar fragancia» en Mi Biblioteca.',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
      body: Obx(() {
        final idx = nav.tabIndex.value;
        return IndexedStack(
          index: idx,
          children: const [
            LibraryPage(),
            ChoosePage(),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 10,
        shape: const CircleBorder(),
        onPressed: () {
          AppLog.navigate('OPEN', AppRoutes.perfumeCreate, {'from': 'Home FAB'});
          Get.toNamed(AppRoutes.perfumeCreate);
        },
        child: Ink(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      bottomNavigationBar: AuraBottomNav(
        onTap: (i) => nav.setTab(i),
      ),
    );
  }
}
