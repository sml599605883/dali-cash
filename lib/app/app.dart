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
import 'package:dali_cash/features/certification/personal_information/personal_information_page.dart';
import 'package:dali_cash/features/certification/work_information/work_information_page.dart';
import 'package:dali_cash/features/certification/emergency_contact/emergency_contact_page.dart';
import 'package:dali_cash/features/certification/bind_card/bind_card_page.dart';
import 'package:dali_cash/features/account/account_list_page.dart';
import 'package:dali_cash/features/main_shell/main_shell_page.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:dali_cash/features/webview/dali_webview_page.dart';
import 'package:dali_cash/core/json/json.dart';
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
        GetPage(
          name: AppRoutes.personalInformation,
          page: () => const PersonalInformationPage(),
        ),
        GetPage(
          name: AppRoutes.workInformation,
          page: () => const WorkInformationPage(),
        ),
        GetPage(
          name: AppRoutes.emergencyContact,
          page: () => const EmergencyContactPage(),
        ),
        GetPage(name: AppRoutes.bindCard, page: () => const BindCardPage()),
        GetPage(
          name: AppRoutes.accountList,
          page: () => const AccountListPage(),
        ),
        GetPage(
          name: AppRoutes.webView,
          page: () {
            final arguments = Json(Get.arguments);
            return DaliWebViewPage(
              initialUrl: arguments['url'].stringValue,
              initialTitle: arguments['title'].stringOrNull,
            );
          },
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
