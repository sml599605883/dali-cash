import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/permissions/permission_coordinator.dart';
import '../../features/product_detail/product_detail_data.dart';
import '../routes/app_routes.dart';
import 'dali_deep_link.dart';
import 'dali_product_navigation_flow.dart';

typedef NavigationAsyncPresenter = Future<void> Function();
typedef NavigationErrorPresenter = Future<void> Function(String message);
typedef NavigationLogger = void Function(String message);
typedef MainTabNavigator = Future<void> Function(int index);
typedef CertificationLocationRequester =
    Future<CertificationLocationDecision> Function();
typedef AppSettingsOpener = Future<bool> Function();
typedef PermissionPromptPresenter =
    Future<bool> Function({
      required String title,
      required String content,
      required String cancelText,
      required String confirmText,
    });

abstract final class NavigationHelper {
  static const _deepLinkParser = DaliDeepLinkParser();
  static const Map<String, String> _productDetailSteps = <String, String>{
    'LancerPredacities': 'identity',
    'CilantroCountermemo': 'face',
    'PermafrostsPalfreys': 'personal',
    'DeviouslyTressours': 'work',
    'TrotlineScootches': 'ext',
    'MolehillSubconscious': 'bank',
  };

  static NavigationAsyncPresenter loadingPresenter = defaultLoadingPresenter;
  static NavigationAsyncPresenter loadingDismissor = defaultLoadingDismissor;
  static NavigationErrorPresenter errorPresenter = defaultErrorPresenter;
  static NavigationErrorPresenter noticePresenter = defaultNoticePresenter;
  static NavigationLogger logger = defaultLogger;
  static MainTabNavigator mainTabNavigator = defaultMainTabNavigator;
  static CertificationLocationRequester certificationLocationRequester =
      defaultCertificationLocationRequester;
  static PermissionPromptPresenter permissionPromptPresenter =
      defaultPermissionPromptPresenter;
  static AppSettingsOpener appSettingsOpener = defaultAppSettingsOpener;

  static Future<void> defaultLoadingPresenter() {
    return EasyLoading.show(status: 'Loading...');
  }

  static Future<void> defaultLoadingDismissor() {
    return EasyLoading.dismiss();
  }

  static Future<void> defaultErrorPresenter(String message) {
    return EasyLoading.showError(message);
  }

  static Future<void> defaultNoticePresenter(String message) {
    return EasyLoading.showToast(message);
  }

  static void defaultLogger(String message) {
    log(message, name: 'NavigationHelper');
  }

  static Future<void> defaultMainTabNavigator(int index) async {
    logger('main tab navigation is not configured: index=$index');
  }

  static Future<CertificationLocationDecision>
  defaultCertificationLocationRequester() {
    return PermissionCoordinator.instance.requestCertificationLocation();
  }

  static Future<bool> defaultPermissionPromptPresenter({
    required String title,
    required String content,
    required String cancelText,
    required String confirmText,
  }) async {
    final context = Get.context;
    if (context == null || !context.mounted) {
      return false;
    }
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return CupertinoAlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(cancelText),
                ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  isDefaultAction: true,
                  child: Text(confirmText),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<bool> defaultAppSettingsOpener() {
    return openAppSettings();
  }

  static void back<T extends Object?>({T? result}) {
    Get.back<T>(result: result);
  }

  static void backToRoot() {
    Get.until((route) => route.isFirst);
  }

  static Future<T?>? toNamed<T extends Object?>(String routeName) {
    return switch (routeName) {
      AppRoutes.login => toLogin<T>(),
      AppRoutes.identitySelection => toIdentitySelection<T>(),
      AppRoutes.identityFace => toIdentityFace<T>(),
      AppRoutes.personalInformation => toPersonalInformation<T>(),
      AppRoutes.workInformation => toWorkInformation<T>(),
      AppRoutes.emergencyContact => toEmergencyContact<T>(),
      AppRoutes.bindCard => toBindCard<T>(),
      _ => null,
    };
  }

  static Future<T?>? toLogin<T extends Object?>({String productId = ''}) {
    if (Get.currentRoute == AppRoutes.login) {
      return null;
    }
    return Get.toNamed<T>(
      AppRoutes.login,
      arguments: {'highlands': productId.trim()},
    );
  }

  static Future<T?>? toIdentitySelection<T extends Object?>({
    String productId = '',
  }) {
    if (Get.currentRoute == AppRoutes.identitySelection) {
      return null;
    }
    Get.toNamed<T>(
      AppRoutes.identitySelection,
      arguments: {'highlands': productId.trim()},
    );
    return Future<T?>.value();
  }

  static Future<T?>? toIdentityFace<T extends Object?>({
    String productId = '',
  }) {
    if (Get.currentRoute == AppRoutes.identityFace) {
      return null;
    }
    Get.toNamed<T>(
      AppRoutes.identityFace,
      arguments: {'highlands': productId.trim()},
    );
    return Future<T?>.value();
  }

  static Future<T?>? toPersonalInformation<T extends Object?>({
    String productId = '',
  }) {
    if (Get.currentRoute == AppRoutes.personalInformation) {
      return null;
    }
    Get.toNamed<T>(
      AppRoutes.personalInformation,
      arguments: {'highlands': productId.trim()},
    );
    return Future<T?>.value();
  }

  static Future<T?>? toWorkInformation<T extends Object?>({
    String productId = '',
  }) {
    if (Get.currentRoute == AppRoutes.workInformation) {
      return null;
    }
    Get.toNamed<T>(
      AppRoutes.workInformation,
      arguments: {'highlands': productId.trim()},
    );
    return Future<T?>.value();
  }

  static Future<T?>? toEmergencyContact<T extends Object?>({
    String productId = '',
  }) {
    if (Get.currentRoute == AppRoutes.emergencyContact) return null;
    Get.toNamed<T>(
      AppRoutes.emergencyContact,
      arguments: {'highlands': productId.trim()},
    );
    return Future<T?>.value();
  }

  static Future<T?>? toBindCard<T extends Object?>({String productId = ''}) {
    if (Get.currentRoute == AppRoutes.bindCard) return null;
    Get.toNamed<T>(
      AppRoutes.bindCard,
      arguments: {'highlands': productId.trim()},
    );
    return Future<T?>.value();
  }

  static Future<T?>? replaceAccountChangeFlowWithWebView<T extends Object?>({
    required String url,
    String? title,
  }) {
    final uri = _webUri(url);
    if (uri == null) {
      logger('invalid WebView replacement URL: $url');
      return null;
    }
    var removedWebView = false;
    return Get.offNamedUntil<T>(AppRoutes.webView, (route) {
      final name = route.settings.name;
      if (name == AppRoutes.accountList || name == AppRoutes.bindCard) {
        return false;
      }
      if (!removedWebView && name == AppRoutes.webView) {
        removedWebView = true;
        return false;
      }
      return true;
    }, arguments: {'url': uri.toString(), 'title': title});
  }

  static Future<void> navigateRawTarget(
    String rawTarget, {
    Object? arguments,
  }) async {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return;
    }
    await _dispatchDeepLink(
      _deepLinkParser.parse(target, arguments: arguments),
    );
  }

  static Future<void> applyProduct(
    String productId, {
    String source = '0',
  }) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }

    try {
      final apiClient = Get.find<ApiClient>();
      await _productFlow(apiClient).apply(normalizedProductId, source: source);
    } catch (error) {
      await errorPresenter(ApiErrorMessage.resolve(error));
    }
  }

  static Future<void> continueProductDetailFlow(String productId) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) return;
    await _productFlow(
      Get.find<ApiClient>(),
    ).loadProductDetail(normalizedProductId);
  }

  static Future<void> _dispatchDeepLink(DaliDeepLink target) async {
    switch (target.kind) {
      case DaliDeepLinkKind.home:
        backToRoot();
        await mainTabNavigator(0);
        return;
      case DaliDeepLinkKind.mine:
        backToRoot();
        await mainTabNavigator(2);
        return;
      case DaliDeepLinkKind.login:
        toLogin<void>();
        return;
      case DaliDeepLinkKind.productDetail:
        final productId = target.productId;
        if (productId.isEmpty) {
          logger('product detail target is missing highlands: ${target.alias}');
          return;
        }
        await _productFlow(Get.find<ApiClient>()).loadProductDetail(productId);
        return;
      case DaliDeepLinkKind.unavailable:
        logger('raw target route not available: ${target.alias}');
        return;
      case DaliDeepLinkKind.webView:
        logger('WebView deferred for raw target: ${target.alias}');
        return;
      case DaliDeepLinkKind.unsupportedDali:
        logger('unsupported Dali app target: ${target.alias}');
        return;
      case DaliDeepLinkKind.unsupported:
        logger('unsupported raw target: ${target.alias}');
        return;
    }
  }

  static DaliProductNavigationFlow _productFlow(ApiClient apiClient) {
    return DaliProductNavigationFlow(
      apiClient: apiClient,
      openLogin: (productId) => toLogin<void>(productId: productId),
      showLoading: loadingPresenter,
      dismissLoading: loadingDismissor,
      showError: errorPresenter,
      showNotice: noticePresenter,
      resolveError: ApiErrorMessage.resolve,
      ensureLocationAccess: _ensureLocationAccess,
      navigateRawTarget: (target, arguments) {
        return navigateRawTarget(target, arguments: arguments);
      },
      handleProductDetail: _handleProductDetail,
    );
  }

  static Future<bool> _ensureLocationAccess() async {
    final decision = await certificationLocationRequester();
    if (decision == CertificationLocationDecision.granted) {
      return true;
    }
    if (decision == CertificationLocationDecision.denied) {
      return false;
    }

    final serviceDisabled =
        decision == CertificationLocationDecision.serviceDisabled;
    final openSettings = await permissionPromptPresenter(
      title: serviceDisabled ? 'GPS is Off' : 'Location Required',
      content: serviceDisabled
          ? 'It looks like your GPS is off. Please enable location services to complete the verification process.'
          : 'Identity verification cannot be completed without your location. Please allow access in settings.',
      cancelText: 'Cancel',
      confirmText: serviceDisabled ? 'Settings' : 'Enable',
    );
    if (openSettings) {
      await appSettingsOpener();
    }
    return false;
  }

  static Future<void> _handleProductDetail(ProductDetailData detail) async {
    final type = detail.nextStep.type.trim();
    if (type.isEmpty) {
      return;
    }
    final step = _productDetailSteps[type];
    if (step == null) {
      logger(
        'product detail next step not available: '
        'type=$type, title=${detail.nextStep.title.trim()}',
      );
      return;
    }

    final productId = detail.product.productId.trim();
    if (step == 'identity' ||
        step == 'face' ||
        step == 'personal' ||
        step == 'work' ||
        step == 'ext' ||
        step == 'bank') {
      if (productId.isEmpty) {
        logger('product detail $step target is missing highlands');
        return;
      }
      switch (step) {
        case 'identity':
          await toIdentitySelection<void>(productId: productId);
        case 'face':
          await toIdentityFace<void>(productId: productId);
        case 'personal':
          await toPersonalInformation<void>(productId: productId);
        case 'work':
          await toWorkInformation<void>(productId: productId);
        case 'ext':
          await toEmergencyContact<void>(productId: productId);
        case 'bank':
          await toBindCard<void>(productId: productId);
      }
      return;
    }

    logger(
      'product detail step recognized but page not available: '
      'step=$step, type=$type, productId=$productId',
    );
  }
}
