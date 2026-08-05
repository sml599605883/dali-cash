import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/permissions/permission_coordinator.dart';
import '../../core/report/dali_report_service.dart';
import '../../features/orders/order_list_item.dart';
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
typedef ProductRedirectReporter =
    void Function({required String productId, required String orderNo});
typedef ExternalUriLauncher = Future<bool> Function(Uri uri);

abstract final class NavigationHelper {
  static const _deepLinkParser = DaliDeepLinkParser();
  static const Map<String, String> _productDetailSteps = <String, String>{
    'public': 'identity',
    'LancerPredacities': 'identity',
    'face': 'face',
    'CilantroCountermemo': 'face',
    'personal': 'personal',
    'PermafrostsPalfreys': 'personal',
    'work': 'work',
    'DeviouslyTressours': 'work',
    'ext': 'ext',
    'TrotlineScootches': 'ext',
    'bank': 'bank',
    'MolehillSubconscious': 'bank',
  };
  static const Set<String> _certificationFlowRouteNames = <String>{
    AppRoutes.recredit,
    AppRoutes.identitySelection,
    AppRoutes.identityUpload,
    AppRoutes.identityConfirmation,
    AppRoutes.identityFace,
    AppRoutes.personalInformation,
    AppRoutes.workInformation,
    AppRoutes.emergencyContact,
    AppRoutes.bindCard,
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
  static ProductRedirectReporter productRedirectReporter =
      defaultProductRedirectReporter;
  static ExternalUriLauncher externalUriLauncher = defaultExternalUriLauncher;

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

  static Future<bool> defaultExternalUriLauncher(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openExternalUri(Uri uri) {
    return externalUriLauncher(uri);
  }

  static void defaultProductRedirectReporter({
    required String productId,
    required String orderNo,
  }) {
    final reporter = DaliReportService.current;
    if (reporter == null) return;
    unawaited(
      reporter.reportRisk(
        productId: productId,
        scene: '9',
        orderNo: orderNo,
        startedAtSeconds: DaliReportService.nowSeconds(),
      ),
    );
  }

  static void back<T extends Object?>({T? result}) {
    Get.back<T>(result: result);
  }

  static void backToRoot() {
    Get.until((route) => route.isFirst);
  }

  static Future<T?>? toNamed<T extends Object?>(String routeName) {
    return switch (routeName) {
      AppRoutes.recredit => toRecredit<T>(),
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

  static Future<T?>? toMineOrderList<T extends Object?>({
    MineOrderStatus initialStatus = MineOrderStatus.all,
  }) {
    return Get.toNamed<T>(
      AppRoutes.mineOrderList,
      arguments: {'initialStatus': initialStatus.code},
    );
  }

  static Future<T?>? toRecredit<T extends Object?>({Object? arguments}) {
    if (Get.currentRoute == AppRoutes.recredit) {
      return null;
    }
    return Get.toNamed<T>(AppRoutes.recredit, arguments: arguments);
  }

  static void _openTopLevelCertification(
    String routeName, {
    required Map<String, dynamic> arguments,
  }) {
    Get.offNamedUntil<void>(routeName, (route) {
      final name = route.settings.name;
      return name != null &&
          name.isNotEmpty &&
          !_certificationFlowRouteNames.contains(name);
    }, arguments: arguments);
  }

  static Future<T?>? toIdentitySelection<T extends Object?>({
    String productId = '',
  }) {
    if (Get.currentRoute == AppRoutes.identitySelection) {
      return null;
    }
    _openTopLevelCertification(
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
    _openTopLevelCertification(
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
    _openTopLevelCertification(
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
    _openTopLevelCertification(
      AppRoutes.workInformation,
      arguments: {'highlands': productId.trim()},
    );
    return Future<T?>.value();
  }

  static Future<T?>? toEmergencyContact<T extends Object?>({
    String productId = '',
  }) {
    if (Get.currentRoute == AppRoutes.emergencyContact) return null;
    _openTopLevelCertification(
      AppRoutes.emergencyContact,
      arguments: {'highlands': productId.trim()},
    );
    return Future<T?>.value();
  }

  static Future<T?>? toBindCard<T extends Object?>({
    String productId = '',
    String orderNo = '',
    bool isAccountChange = false,
  }) {
    if (Get.currentRoute == AppRoutes.bindCard) return null;
    final arguments = <String, dynamic>{'highlands': productId.trim()};
    if (isAccountChange) {
      arguments.addAll({'saggards': orderNo.trim(), 'isAccountChange': true});
      Get.toNamed<T>(AppRoutes.bindCard, arguments: arguments);
      return Future<T?>.value();
    }
    _openTopLevelCertification(AppRoutes.bindCard, arguments: arguments);
    return Future<T?>.value();
  }

  static Future<T?>? toAccountList<T extends Object?>({
    required String productId,
    required String orderNo,
  }) {
    if (Get.currentRoute == AppRoutes.accountList) return null;
    return Get.toNamed<T>(
      AppRoutes.accountList,
      arguments: {'highlands': productId.trim(), 'saggards': orderNo.trim()},
    );
  }

  static Future<T?>? toWebView<T extends Object?>({
    required String url,
    String? title,
  }) {
    final uri = webViewUri(url);
    if (uri == null) {
      logger('invalid WebView URL: $url');
      return null;
    }
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.webView,
      arguments: {'url': uri.toString(), 'title': title},
    );
  }

  static Future<T?>? toWebPath<T extends Object?>({
    required String path,
    String? title,
  }) {
    if (!Get.isRegistered<ApiClient>()) {
      logger('web base URL is unavailable: $path');
      return null;
    }
    final base = Get.find<ApiClient>().config.webBaseUrl.trim();
    final baseUri = Uri.tryParse(base);
    if (baseUri == null || baseUri.host.isEmpty) {
      logger('invalid web base URL: $base');
      return null;
    }
    final uri = baseUri.resolve(path.trim());
    return toWebView<T>(url: uri.toString(), title: title);
  }

  static Future<T?>? _toNamedAfterPruningCertificationFlow<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return Get.offNamedUntil<T>(routeName, (route) {
      final name = route.settings.name;
      return name != null &&
          name.isNotEmpty &&
          !_certificationFlowRouteNames.contains(name);
    }, arguments: arguments);
  }

  static Future<T?>? replaceWebView<T extends Object?>({
    required String url,
    String? title,
    bool removeBindCard = false,
  }) {
    final uri = webViewUri(url);
    if (uri == null) {
      logger('invalid WebView replacement URL: $url');
      return null;
    }
    var removedWebView = false;
    return Get.offNamedUntil<T>(AppRoutes.webView, (route) {
      final name = route.settings.name;
      if (removeBindCard && name == AppRoutes.bindCard) {
        return false;
      }
      if (!removedWebView && name == AppRoutes.webView) {
        removedWebView = true;
        return false;
      }
      return true;
    }, arguments: {'url': uri.toString(), 'title': title});
  }

  static Future<T?>? replaceAccountChangeFlowWithWebView<T extends Object?>({
    required String url,
    String? title,
  }) {
    final uri = webViewUri(url);
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

  static Uri? webViewUri(String value) => _webUri(value);

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
    await loadingPresenter();
    try {
      await _productFlow(
        Get.find<ApiClient>(),
      ).loadProductDetail(normalizedProductId);
      await loadingDismissor();
    } catch (error) {
      await errorPresenter(ApiErrorMessage.resolve(error));
    }
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
      case DaliDeepLinkKind.recredit:
        final mergedArguments = <String, dynamic>{
          ...?target.uri?.queryParameters,
        };
        if (target.arguments is Map) {
          for (final entry in (target.arguments as Map).entries) {
            mergedArguments[entry.key.toString()] = entry.value;
          }
        }
        final productId = target.productId;
        if (productId.isNotEmpty) {
          mergedArguments['highlands'] = productId;
        }
        toRecredit<void>(
          arguments: mergedArguments.isEmpty
              ? target.arguments
              : mergedArguments,
        );
        return;
      case DaliDeepLinkKind.unavailable:
        logger('raw target route not available: ${target.alias}');
        return;
      case DaliDeepLinkKind.webView:
        toWebView<void>(url: target.uri?.toString() ?? target.alias);
        return;
      case DaliDeepLinkKind.unsupportedDali:
        logger('unsupported Dali app target: ${target.alias}');
        return;
      case DaliDeepLinkKind.unsupported:
        logger('unsupported raw target: ${target.alias}');
        return;
    }
  }

  static Uri? _webUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
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
      logger: logger,
      reportProductRedirect: (productId, orderNo) {
        productRedirectReporter(productId: productId, orderNo: orderNo);
      },
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

  static Future<bool> _handleProductDetail(ProductDetailData detail) async {
    final type = detail.nextStep.type.trim();
    if (type.isEmpty) {
      return false;
    }
    final step = _productDetailSteps[type];
    if (step == null) {
      logger(
        'product detail next step not available: '
        'type=$type, title=${detail.nextStep.title.trim()}',
      );
      return true;
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
        return true;
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
      return true;
    }

    logger(
      'product detail step recognized but page not available: '
      'step=$step, type=$type, productId=$productId',
    );
    return true;
  }
}
