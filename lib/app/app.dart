import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/routes/app_routes.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/login/login_binding.dart';
import 'package:dali_cash/features/login/login_page.dart';
import 'package:dali_cash/features/certification/identity_selection/identity_selection_binding.dart';
import 'package:dali_cash/features/certification/identity_selection/identity_selection_page.dart';
import 'package:dali_cash/features/certification/identity_upload/identity_upload_page.dart';
import 'package:dali_cash/features/certification/identity_confirmation/identity_confirmation_page.dart';
import 'package:dali_cash/features/certification/identity_face/identity_face_page.dart';
import 'package:dali_cash/features/main_shell/main_shell_page.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class DaliCashApp extends StatelessWidget {
  const DaliCashApp({super.key, this.initialBinding});

  final Bindings? initialBinding;
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Dali Cash',
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      initialBinding: initialBinding ?? MainBinding(),
      getPages: [
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginPage(),
          binding: LoginBinding(),
        ),
        GetPage(
          name: AppRoutes.identitySelection,
          page: () => const IdentitySelectionPage(),
          binding: IdentitySelectionBinding(),
        ),
        GetPage(
          name: AppRoutes.identityUpload,
          page: () => const IdentityUploadPage(),
        ),
        GetPage(
          name: AppRoutes.identityConfirmation,
          page: () => const IdentityConfirmationPage(),
        ),
        GetPage(
          name: AppRoutes.identityFace,
          page: () => const IdentityFacePage(),
        ),
      ],
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: Builder(
        builder: (context) {
          ScreenAdapter.init(context);
          return const MainShellPage();
        },
      ),
    );
  }
}
