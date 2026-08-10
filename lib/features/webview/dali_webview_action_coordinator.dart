import 'dali_webview_contract.dart';

typedef DaliWebViewRiskReporter =
    Future<void> Function({
      required String productId,
      required String orderNo,
      required int startedAtSeconds,
    });
typedef DaliWebViewUrlAction = Future<void> Function(String url);
typedef DaliWebViewExternalAction = Future<bool> Function(Uri uri);
typedef DaliWebViewParamsBuilder =
    Future<Map<String, dynamic>> Function(String path);
typedef DaliWebViewRetryAction = Future<String> Function(String orderNo);
typedef DaliWebViewAccountAction =
    Future<void> Function({required String productId, required String orderNo});
typedef DaliWebViewAsyncAction = Future<void> Function();
typedef DaliWebViewMessageAction = Future<void> Function(String message);
typedef DaliWebViewLogger = void Function(String message);

class DaliWebViewActionCoordinator {
  const DaliWebViewActionCoordinator({
    this.reportRisk,
    this.openWebView,
    this.navigateInternal,
    this.openExternal,
    this.closePage,
    this.jumpHome,
    this.requestAppReview,
    this.buildPublicParams,
    this.retryOrder,
    this.reloadOrOpenWebView,
    @Deprecated('Use reloadOrOpenWebView to reuse the current WebView.')
    this.replaceWebView,
    this.changeAccount,
    this.showLoading,
    this.dismissLoading,
    this.showError,
    this.logger,
    this.nowSeconds,
  });

  final DaliWebViewRiskReporter? reportRisk;
  final DaliWebViewUrlAction? openWebView;
  final DaliWebViewUrlAction? navigateInternal;
  final DaliWebViewExternalAction? openExternal;
  final DaliWebViewAsyncAction? closePage;
  final DaliWebViewAsyncAction? jumpHome;
  final DaliWebViewAsyncAction? requestAppReview;
  final DaliWebViewParamsBuilder? buildPublicParams;
  final DaliWebViewRetryAction? retryOrder;
  final DaliWebViewUrlAction? reloadOrOpenWebView;
  @Deprecated('Use reloadOrOpenWebView to reuse the current WebView.')
  final DaliWebViewUrlAction? replaceWebView;
  final DaliWebViewAccountAction? changeAccount;
  final DaliWebViewAsyncAction? showLoading;
  final DaliWebViewAsyncAction? dismissLoading;
  final DaliWebViewMessageAction? showError;
  final DaliWebViewLogger? logger;
  final int Function()? nowSeconds;

  Future<DaliWebViewResult> dispatch(DaliWebViewRequest request) async {
    try {
      return switch (request.action) {
        DaliWebViewActions.uploadRisk => await _uploadRisk(request),
        DaliWebViewActions.openGooglePlay => _ignoreGooglePlay(request),
        DaliWebViewActions.openUrl => await _openUrl(request),
        DaliWebViewActions.close => await _run(closePage),
        DaliWebViewActions.home => await _run(jumpHome),
        DaliWebViewActions.grade => await _run(requestAppReview),
        DaliWebViewActions.retryOrder => await _retryOrder(request),
        DaliWebViewActions.changeAccount => await _changeAccount(request),
        DaliWebViewActions.publicParams => await _publicParams(request),
        _ => DaliWebViewResult.failure(
          'Unsupported action: ${request.action}',
          code: -2,
        ),
      };
    } catch (error) {
      final message = error.toString().trim();
      final resolved = message.isEmpty ? 'Unable to complete action' : message;
      await showError?.call(resolved);
      return DaliWebViewResult.failure(resolved);
    }
  }

  Future<DaliWebViewResult> _uploadRisk(DaliWebViewRequest request) async {
    final productId = _value(request, 'thunderstruck');
    if (productId.isEmpty) {
      return const DaliWebViewResult.failure('Missing productId');
    }
    await reportRisk?.call(
      productId: productId,
      orderNo: _value(request, 'saggards'),
      startedAtSeconds:
          nowSeconds?.call() ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    return const DaliWebViewResult.success();
  }

  DaliWebViewResult _ignoreGooglePlay(DaliWebViewRequest request) {
    final package = _value(request, 'appPkg', fallbackToRaw: true);
    logger?.call('Google Play action ignored on iOS: package=$package');
    return const DaliWebViewResult.success();
  }

  Future<DaliWebViewResult> _openUrl(DaliWebViewRequest request) async {
    final rawUrl = _value(request, 'url', fallbackToRaw: true);
    final uri = Uri.tryParse(rawUrl);
    if (rawUrl.isEmpty || uri == null || uri.scheme.isEmpty) {
      return const DaliWebViewResult.failure('Invalid url');
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (uri.host.isEmpty) {
        return const DaliWebViewResult.failure('Invalid url');
      }
      await openWebView?.call(rawUrl);
      return const DaliWebViewResult.success();
    }
    if (uri.scheme == 'ph') {
      await navigateInternal?.call(rawUrl);
      return const DaliWebViewResult.success();
    }
    final opened = await openExternal?.call(uri) ?? false;
    return opened
        ? const DaliWebViewResult.success()
        : const DaliWebViewResult.failure('Unable to open url');
  }

  Future<DaliWebViewResult> _publicParams(DaliWebViewRequest request) async {
    final path = request.rawDataString;
    if (path.isEmpty) {
      return const DaliWebViewResult.failure('Missing path');
    }
    final params = await buildPublicParams?.call(path);
    if (params == null) {
      return const DaliWebViewResult.failure('Public params are unavailable');
    }
    return DaliWebViewResult.success(params);
  }

  Future<DaliWebViewResult> _retryOrder(DaliWebViewRequest request) async {
    final orderNo = _value(request, 'saggards');
    if (orderNo.isEmpty) {
      return const DaliWebViewResult.failure('Missing orderNo');
    }
    await showLoading?.call();
    try {
      final url = (await retryOrder?.call(orderNo) ?? '').trim();
      if (url.isEmpty) {
        const message = 'Missing retry result url';
        await showError?.call(message);
        return const DaliWebViewResult.failure(message);
      }
      await (reloadOrOpenWebView ?? replaceWebView)?.call(url);
      return const DaliWebViewResult.success();
    } finally {
      await dismissLoading?.call();
    }
  }

  Future<DaliWebViewResult> _changeAccount(DaliWebViewRequest request) async {
    final productId = _value(request, 'thunderstruck');
    final orderNo = _value(request, 'saggards');
    if (productId.isEmpty || orderNo.isEmpty) {
      return const DaliWebViewResult.failure('Missing account information');
    }
    await showLoading?.call();
    await changeAccount?.call(productId: productId, orderNo: orderNo);
    await dismissLoading?.call();
    return const DaliWebViewResult.success();
  }

  Future<DaliWebViewResult> _run(DaliWebViewAsyncAction? action) async {
    await action?.call();
    return const DaliWebViewResult.success();
  }

  String _value(
    DaliWebViewRequest request,
    String key, {
    bool fallbackToRaw = false,
  }) {
    final mapped = request.data[key]?.toString().trim() ?? '';
    return mapped.isNotEmpty || !fallbackToRaw ? mapped : request.rawDataString;
  }
}
