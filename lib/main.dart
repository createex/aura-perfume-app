import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'controller/utils/app_colors.dart';
import 'controller/utils/app_log.dart';
import 'controller/utils/app_pages.dart';
import 'controller/utils/app_routes.dart';
import 'controller/utils/app_text_styles.dart';
import 'controller/utils/perfume_image_resolver.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.startup('Initializing app (bindings + asset manifest)');
  await PerfumeImageResolver.instance.ensureLoaded();
  AppLog.startup(
    'PerfumeImageResolver indexed raster files',
    {'count': PerfumeImageResolver.instance.indexedRasterAssetCount},
  );
  runApp(const AuraPerfumeApp());
}

class AuraPerfumeApp extends StatelessWidget {
  const AuraPerfumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          title: 'Aura Perfume App',
          debugShowCheckedModeBanner: false,
          routingCallback: (r) {
            if (r == null) return;
            AppLog.routing(
              current: r.current,
              previous: r.previous,
              isBack: r.isBack,
              args: r.args,
              isBottomSheet: r.isBottomSheet,
              isDialog: r.isDialog,
            );
          },
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              surface: AppColors.surface,
              brightness: Brightness.light,
            ),
            textTheme: AppTextStyles.toTextTheme(ThemeData.light().textTheme),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          initialRoute: AppRoutes.home,
          getPages: AppPages.pages,
          defaultTransition: Transition.cupertino,
        );
      },
    );
  }
}