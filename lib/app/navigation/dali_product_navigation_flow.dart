import '../../core/network/api_client.dart';
import '../../features/product_detail/product_detail_data.dart';

typedef DaliAsyncAction = Future<void> Function();
typedef DaliMessageAction = Future<void> Function(String message);
typedef DaliRawTargetAction =
    Future<void> Function(String target, Object? arguments);
typedef DaliProductDetailAction =
    Future<bool> Function(ProductDetailData detail);
typedef DaliAccessChecker = Future<bool> Function();
typedef DaliLogger = void Function(String message);
typedef DaliProductRedirectReporter =
    void Function(String productId, String orderNo);

class DaliProductNavigationFlow {
  const DaliProductNavigationFlow({
    required this.apiClient,
    required this.openLogin,
    required this.showLoading,
    required this.dismissLoading,
    required this.showError,
    required this.showNotice,
    required this.resolveError,
    required this.ensureLocationAccess,
    required this.navigateRawTarget,
    required this.handleProductDetail,
    required this.logger,
    required this.reportProductRedirect,
  });

  final ApiClient apiClient;
  final void Function(String productId) openLogin;
  final DaliAsyncAction showLoading;
  final DaliAsyncAction dismissLoading;
  final DaliMessageAction showError;
  final DaliMessageAction showNotice;
  final String Function(Object error) resolveError;
  final DaliAccessChecker ensureLocationAccess;
  final DaliRawTargetAction navigateRawTarget;
  final DaliProductDetailAction handleProductDetail;
  final DaliLogger logger;
  final DaliProductRedirectReporter reportProductRedirect;

  Future<void> apply(String productId, {String source = '0'}) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }

    try {
      final sessionId = await apiClient.config.sessionStore.sessionId();
      if (sessionId.trim().isEmpty) {
        openLogin(normalizedProductId);
        return;
      }
    } catch (error) {
      await showError(resolveError(error));
      return;
    }

    if (!await ensureLocationAccess()) {
      return;
    }

    await showLoading();
    try {
      final response = await apiClient.productApply(
        productId: normalizedProductId,
        source: source,
      );
      final states = response.states;
      final rawTarget = states['millipede'].stringValue.trim();
      if (rawTarget.isNotEmpty) {
        await navigateRawTarget(rawTarget, states.rawMapValue);
        await dismissLoading();
        return;
      }
      if (states['tucking'].intValue != 200) {
        await dismissLoading();
        final message = states['detainment'].stringValue.trim();
        if (message.isNotEmpty) {
          await showNotice(message);
        }
        return;
      }
      await loadProductDetail(normalizedProductId);
      await dismissLoading();
    } catch (error) {
      await dismissLoading();
      await showError(resolveError(error));
    }
  }

  Future<void> loadProductDetail(String productId) async {
    final response = await apiClient.productDetail(productId: productId);
    final detail = ProductDetailData.fromJson(response.states);
    await apiClient.config.sessionStore.saveProductDetailPrompt(
      detail.pageCopy.identityUpload,
    );
    await apiClient.config.sessionStore
        .saveProductDetailIdentityConfirmationPrompt(
          detail.pageCopy.identityConfirmation,
        );
    await apiClient.config.sessionStore.saveProductDetailFacePrompt(
      detail.pageCopy.faceVerification,
    );
    await apiClient.config.sessionStore.saveProductDetailOrderNo(
      detail.product.orderNo,
    );
    if (await handleProductDetail(detail)) {
      return;
    }
    if (detail.statusCode != 200) {
      logger(
        'product detail continuation unavailable: '
        'status=${detail.statusCode}, productId=${detail.product.productId.trim()}',
      );
      return;
    }

    final orderNo = detail.product.orderNo.trim();
    if (orderNo.isEmpty) {
      logger(
        'product detail continuation is missing order number: '
        'productId=${detail.product.productId.trim()}',
      );
      return;
    }

    final redirect = await apiClient.productPush(
      orderNo: orderNo,
      amount: detail.product.amount.trim(),
      term: detail.product.term.trim(),
      termType: '${detail.product.termType}',
    );
    final resolvedProductId = detail.product.productId.trim().isNotEmpty
        ? detail.product.productId.trim()
        : productId.trim();
    reportProductRedirect(resolvedProductId, orderNo);

    final rawTarget = redirect.states['millipede'].stringValue.trim();
    if (rawTarget.isEmpty) {
      logger(
        'product detail order continuation returned an empty target: '
        'productId=$resolvedProductId, orderNo=$orderNo',
      );
      return;
    }
    await navigateRawTarget(rawTarget, redirect.states.rawMapValue);
  }
}
