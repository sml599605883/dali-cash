import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../../app/navigation/navigation_helper.dart';
import '../../app/theme/app_colors.dart';
import '../../core/client/client_bridge.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_signature.dart';
import '../../core/report/dali_report_service.dart';
import 'dali_webview_action_coordinator.dart';
import 'dali_webview_contract.dart';

bool isInlineDaliWebViewScheme(String scheme) => switch (scheme.toLowerCase()) {
  'http' || 'https' || 'about' || 'data' || 'javascript' || 'file' => true,
  _ => false,
};

bool shouldCloseDaliWebView({required bool canGoBack}) => !canGoBack;

bool shouldShowDaliWebViewLoadError({required bool? isForMainFrame}) =>
    isForMainFrame == true;

bool canUseDaliWebViewController({
  required bool mounted,
  required Object? activeController,
  required Object? controller,
}) =>
    mounted &&
    activeController != null &&
    identical(activeController, controller);

String daliConfirmProductId(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return '';
  final fragmentUri = Uri.tryParse(uri.fragment);
  final directConfirm = uri.pathSegments.contains('Florescences');
  final fragmentConfirm =
      fragmentUri?.pathSegments.contains('Florescences') == true;
  if (!directConfirm && !fragmentConfirm) return '';
  final direct = uri.queryParameters['thunderstruck']?.trim() ?? '';
  if (direct.isNotEmpty) return direct;
  return fragmentUri?.queryParameters['thunderstruck']?.trim() ?? '';
}

bool hasDaliWebViewAccounts(Json states) =>
    states['clingiest'].listValue.isNotEmpty;

enum DaliAccountDestination { accountList, bindCard }

DaliAccountDestination daliAccountDestination(Json states) =>
    hasDaliWebViewAccounts(states)
    ? DaliAccountDestination.accountList
    : DaliAccountDestination.bindCard;

String? daliWebViewCallbackScript(
  DaliWebViewRequest request,
  DaliWebViewResult result,
) {
  if (!request.expectsCallback) return null;
  final payload = jsonEncode(<String, Object?>{
    'callbackId': request.callbackId,
    'data': result.data,
  });
  return 'window.${DaliWebViewContract.handler}.handleMessage($payload);';
}

class DaliWebViewBridgeGate {
  DaliWebViewBridgeGate({
    required this.addHandler,
    required this.removeHandler,
  });

  final void Function(Object controller) addHandler;
  final void Function(Object controller) removeHandler;
  Object? _controller;
  bool _foreground = true;
  bool _registered = false;

  void attach(Object controller) {
    detach();
    _controller = controller;
    _sync();
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _sync();
  }

  void detach() {
    final controller = _controller;
    if (controller != null && _registered) {
      removeHandler(controller);
    }
    _registered = false;
    _controller = null;
  }

  void _sync() {
    final controller = _controller;
    if (controller == null || _foreground == _registered) return;
    if (_foreground) {
      addHandler(controller);
      _registered = true;
    } else {
      removeHandler(controller);
      _registered = false;
    }
  }
}

class DaliWebViewPage extends StatefulWidget {
  const DaliWebViewPage({
    super.key,
    required this.initialUrl,
    this.initialTitle,
  });

  final String initialUrl;
  final String? initialTitle;

  @override
  State<DaliWebViewPage> createState() => _DaliWebViewPageState();
}

class _DaliWebViewPageState extends State<DaliWebViewPage>
    with WidgetsBindingObserver {
  InAppWebViewController? _controller;
  late final DaliWebViewActionCoordinator _coordinator;
  late final DaliWebViewBridgeGate _bridgeGate;
  late String _title;
  bool _loading = true;
  bool _loadFailed = false;

  Uri? get _initialUri {
    final uri = Uri.tryParse(widget.initialUrl.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _title = widget.initialTitle?.trim().isNotEmpty == true
        ? widget.initialTitle!.trim()
        : 'Details';
    _bridgeGate = DaliWebViewBridgeGate(
      addHandler: (value) {
        (value as InAppWebViewController).addJavaScriptHandler(
          handlerName: DaliWebViewContract.handler,
          callback: _handleBridgeCall,
        );
      },
      removeHandler: (value) {
        (value as InAppWebViewController).removeJavaScriptHandler(
          handlerName: DaliWebViewContract.handler,
        );
      },
    );
    _coordinator = _buildCoordinator();
  }

  DaliWebViewActionCoordinator _buildCoordinator() {
    return DaliWebViewActionCoordinator(
      reportRisk:
          ({required productId, required orderNo, required startedAtSeconds}) {
            return DaliReportService.current?.reportRisk(
                  productId: productId,
                  scene: '10',
                  orderNo: orderNo,
                  startedAtSeconds: startedAtSeconds,
                ) ??
                Future<void>.value();
          },
      openWebView: (url) async {
        NavigationHelper.toWebView<void>(url: url);
      },
      navigateInternal: NavigationHelper.navigateRawTarget,
      openExternal: NavigationHelper.openExternalUri,
      closePage: () async => NavigationHelper.back<void>(),
      jumpHome: () {
        return NavigationHelper.navigateRawTarget(
          'ph://dali-cash/ios/Personation',
        );
      },
      requestAppReview: ClientBridge().requestAppReview,
      buildPublicParams: (path) {
        return ApiSignature(
          Get.find<ApiClient>().config,
        ).buildSignedQuery(path: path);
      },
      retryOrder: (orderNo) async {
        final response = await Get.find<ApiClient>().retryOriginalAccount(
          orderNo: orderNo,
        );
        return response
            .ensureSuccess()
            .states['misericorde']
            .stringValue
            .trim();
      },
      replaceWebView: (url) async {
        NavigationHelper.replaceWebView<void>(url: url);
      },
      changeAccount: ({required productId, required orderNo}) async {
        final response = await Get.find<ApiClient>().userAccountList(
          productId: productId,
        );
        final states = response.ensureSuccess().states;
        if (daliAccountDestination(states) ==
            DaliAccountDestination.accountList) {
          NavigationHelper.toAccountList<void>(
            productId: productId,
            orderNo: orderNo,
          );
          return;
        }
        NavigationHelper.toBindCard<void>(
          productId: productId,
          orderNo: orderNo,
          isAccountChange: true,
        );
      },
      showLoading: NavigationHelper.loadingPresenter,
      dismissLoading: NavigationHelper.loadingDismissor,
      showError: NavigationHelper.errorPresenter,
      logger: NavigationHelper.logger,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _bridgeGate.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    _bridgeGate.detach();
    _controller = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<dynamic> _handleBridgeCall(List<dynamic> arguments) async {
    final controller = _controller;
    if (!canUseDaliWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return const DaliWebViewResult.failure('WebView is inactive').toJson();
    }
    final request = DaliWebViewRequest.decode(
      arguments.isEmpty ? null : arguments.first,
    );
    final result = await _coordinator.dispatch(request);
    final script = daliWebViewCallbackScript(request, result);
    if (script != null &&
        canUseDaliWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      await controller!.evaluateJavascript(source: script);
    }
    return result.toJson();
  }

  Future<void> _handleBack() async {
    final controller = _controller;
    var canGoBack = false;
    var currentUrl = widget.initialUrl;
    if (controller != null &&
        canUseDaliWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      canGoBack = await controller.canGoBack();
      if (!canUseDaliWebViewController(
        mounted: mounted,
        activeController: _controller,
        controller: controller,
      )) {
        return;
      }
      currentUrl = (await controller.getUrl())?.toString() ?? currentUrl;
      if (!canUseDaliWebViewController(
        mounted: mounted,
        activeController: _controller,
        controller: controller,
      )) {
        return;
      }
    }

    final confirmProductId = daliConfirmProductId(currentUrl);
    if (confirmProductId.isNotEmpty) {
      NavigationHelper.logger(
        'WebView confirm retention popup is not available: '
        'productId=$confirmProductId',
      );
    }
    if (!shouldCloseDaliWebView(canGoBack: canGoBack) && controller != null) {
      await controller.goBack();
      return;
    }
    if (mounted) NavigationHelper.back<void>();
  }

  Future<NavigationActionPolicy> _handleNavigation(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final uri = action.request.url;
    if (uri == null) return NavigationActionPolicy.CANCEL;
    if (isInlineDaliWebViewScheme(uri.scheme)) {
      return NavigationActionPolicy.ALLOW;
    }
    if (uri.scheme == 'ph') {
      await NavigationHelper.navigateRawTarget(uri.toString());
    } else {
      await NavigationHelper.openExternalUri(uri);
    }
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _retry() async {
    final uri = _initialUri;
    final controller = _controller;
    if (uri == null || controller == null) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }

  @override
  Widget build(BuildContext context) {
    final uri = _initialUri;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          title: Text(_title),
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: uri == null
            ? const _DaliWebViewFailure(message: 'Invalid page address')
            : _loadFailed
            ? _DaliWebViewFailure(onRetry: _retry)
            : Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      useShouldOverrideUrlLoading: true,
                      useHybridComposition: true,
                      isInspectable: kDebugMode,
                      mixedContentMode:
                          MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                      _bridgeGate.attach(controller);
                    },
                    shouldOverrideUrlLoading: _handleNavigation,
                    onPermissionRequest: (controller, request) async {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.DENY,
                      );
                    },
                    onLoadStart: (controller, url) {
                      if (mounted && identical(_controller, controller)) {
                        setState(() {
                          _loading = true;
                          _loadFailed = false;
                        });
                      }
                    },
                    onLoadStop: (controller, url) {
                      if (mounted && identical(_controller, controller)) {
                        setState(() => _loading = false);
                      }
                    },
                    onReceivedError: (controller, request, error) {
                      if (mounted &&
                          identical(_controller, controller) &&
                          shouldShowDaliWebViewLoadError(
                            isForMainFrame: request.isForMainFrame,
                          )) {
                        setState(() {
                          _loading = false;
                          _loadFailed = true;
                        });
                      }
                    },
                    onTitleChanged: (controller, title) {
                      final value = title?.trim() ?? '';
                      if (mounted &&
                          identical(_controller, controller) &&
                          value.isNotEmpty) {
                        setState(() => _title = value);
                      }
                    },
                  ),
                  if (_loading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _DaliWebViewFailure extends StatelessWidget {
  const _DaliWebViewFailure({
    this.message = 'Page failed to load',
    this.onRetry,
  });

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.alert),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: AppColors.textPrimary)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => unawaited(onRetry!()),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
