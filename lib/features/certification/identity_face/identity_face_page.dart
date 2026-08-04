import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/navigation/navigation_helper.dart';
import '../../../app/resources/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/client/client_bridge.dart';
import '../../../core/json/json.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/report/dali_report_service.dart';
import '../widgets/identity_prompt_banner.dart';
import '../widgets/certification_retention_guard.dart';

typedef IdentityFaceLogger = void Function(String message);
typedef IdentityFaceCameraPermissionRequester =
    Future<PermissionStatus> Function();
typedef IdentityFaceAppSettingsOpener = Future<bool> Function();
typedef IdentityFaceLivenessLauncher =
    Future<TrustDecisionLivenessResult> Function(String license);
typedef IdentityFaceFilePathBuilder =
    Future<String> Function(String imageBase64);
typedef IdentityFaceAsyncPresenter = Future<void> Function();
typedef IdentityFaceErrorPresenter = Future<void> Function(String message);
typedef IdentityFaceContinuation = Future<void> Function(String productId);
typedef IdentityFaceRiskReporter = Future<void> Function(int startTimeSeconds);
typedef IdentityFaceTrustDecisionReporter =
    Future<void> Function(TrustDecisionLivenessResult result);
typedef IdentityFaceClock = int Function();

class IdentityFacePage extends StatefulWidget {
  static const defaultPromptMessage =
      'Verify your identity to help keep your account secure and complete the process faster.';

  const IdentityFacePage({
    super.key,
    this.productId = '',
    this.cardType = '',
    this.logger,
    this.apiClient,
    IdentityFaceCameraPermissionRequester? requestCameraPermission,
    IdentityFaceAppSettingsOpener? openAppSettingsPage,
    IdentityFaceLivenessLauncher? showTrustDecisionLiveness,
    IdentityFaceFilePathBuilder? faceImageFilePathBuilder,
    IdentityFaceAsyncPresenter? showLoading,
    IdentityFaceAsyncPresenter? dismissLoading,
    IdentityFaceErrorPresenter? showError,
    IdentityFaceContinuation? continueProductDetailFlow,
    IdentityFaceClock? nowSeconds,
    this.reportRiskScene,
    this.reportTrustDecisionResult,
  }) : requestCameraPermission =
           requestCameraPermission ?? _defaultRequestCameraPermission,
       openAppSettingsPage = openAppSettingsPage ?? openAppSettings,
       showTrustDecisionLiveness =
           showTrustDecisionLiveness ?? _defaultShowTrustDecisionLiveness,
       faceImageFilePathBuilder =
           faceImageFilePathBuilder ?? _defaultFaceImageFilePathBuilder,
       showLoading = showLoading ?? _defaultShowLoading,
       dismissLoading = dismissLoading ?? _defaultDismissLoading,
       showError = showError ?? _defaultShowError,
       continueProductDetailFlow =
           continueProductDetailFlow ?? _defaultContinueProductDetailFlow,
       nowSeconds = nowSeconds ?? DaliReportService.nowSeconds;

  final String productId;
  final String cardType;
  final IdentityFaceLogger? logger;
  final ApiClient? apiClient;
  final IdentityFaceCameraPermissionRequester requestCameraPermission;
  final IdentityFaceAppSettingsOpener openAppSettingsPage;
  final IdentityFaceLivenessLauncher showTrustDecisionLiveness;
  final IdentityFaceFilePathBuilder faceImageFilePathBuilder;
  final IdentityFaceAsyncPresenter showLoading;
  final IdentityFaceAsyncPresenter dismissLoading;
  final IdentityFaceErrorPresenter showError;
  final IdentityFaceContinuation continueProductDetailFlow;
  final IdentityFaceClock nowSeconds;
  final IdentityFaceRiskReporter? reportRiskScene;
  final IdentityFaceTrustDecisionReporter? reportTrustDecisionResult;

  @override
  State<IdentityFacePage> createState() => _IdentityFacePageState();

  static void _defaultLogger(String message) {
    log(message, name: 'IdentityFace');
  }
}

class _IdentityFacePageState extends State<IdentityFacePage> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    final arguments = Json(Get.arguments);
    final resolvedProductId = widget.productId.trim().isNotEmpty
        ? widget.productId.trim()
        : arguments['highlands'].stringValue.trim();
    final resolvedCardType = widget.cardType.trim().isNotEmpty
        ? widget.cardType.trim()
        : arguments['cardType'].stringValue.trim();
    final client =
        widget.apiClient ??
        (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null);
    final prompt = client?.config.sessionStore.productDetailFacePrompt() ?? '';
    final onBack = CertificationRetentionGuard.backHandler(
      type: '1',
      productId: resolvedProductId,
      onDefaultBack: Get.back<void>,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) onBack();
        },
        child: Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            child: Column(
              children: [
                _IdentityFaceHeader(onBack: onBack),
                SizedBox(height: ScreenAdapter.height(10)),
                IdentityPromptBanner(
                  message: prompt.isEmpty
                      ? IdentityFacePage.defaultPromptMessage
                      : prompt,
                ),
                SizedBox(height: ScreenAdapter.height(12)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenAdapter.width(16),
                    ),
                    child: Image.asset(
                      key: const Key('identityFaceDemo'),
                      AppAssets.identityFaceVerificationDemo,
                      width: ScreenAdapter.width(343),
                      height: ScreenAdapter.height(429),
                      fit: BoxFit.fill,
                      semanticLabel: 'Face verification demonstration examples',
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ScreenAdapter.width(16),
                0,
                ScreenAdapter.width(16),
                ScreenAdapter.height(20),
              ),
              child: SizedBox(
                height: ScreenAdapter.height(46),
                child: ElevatedButton(
                  key: const Key('identityFaceUploadButton'),
                  onPressed: _isSubmitting
                      ? null
                      : () => _submit(
                          productId: resolvedProductId,
                          cardType: resolvedCardType,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ScreenAdapter.width(8),
                      ),
                    ),
                  ),
                  child: Text(
                    'Upload',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: ScreenAdapter.font(16),
                      fontWeight: FontWeight.w700,
                      height: 19 / 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit({
    required String productId,
    required String cardType,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await widget.showLoading();
    try {
      final permission = await widget.requestCameraPermission();
      if (!permission.isGranted) {
        await widget.dismissLoading();
        if (mounted) await _showCameraPermissionDialog();
        return;
      }

      final client = widget.apiClient ?? Get.find<ApiClient>();
      final orderNo = client.config.sessionStore.productDetailOrderNo().trim();
      if (orderNo.isEmpty) {
        await _fail('Missing order information for face verification');
        return;
      }

      final response = await client.getFaceIdToken(orderNo: orderNo, type: '0');
      final token = _IdentityFaceToken.fromResponse(response);
      if (token.code == '400') {
        await _fail(
          token.errorMessage.isNotEmpty
              ? token.errorMessage
              : 'Please re-upload your ID photo.',
        );
        return;
      }
      if (token.code != '200') {
        await _fail(
          token.errorMessage.isNotEmpty
              ? token.errorMessage
              : response.message.isNotEmpty
              ? response.message
              : 'Failed to get face token',
        );
        return;
      }
      if (token.license.isEmpty) {
        await _fail('Failed to get face token');
        return;
      }
      if (token.faceType != 7) {
        await _fail('Unsupported liveness verification type');
        return;
      }

      final riskStartTime = widget.nowSeconds();
      final result = await widget.showTrustDecisionLiveness(token.license);
      unawaited(
        (widget.reportTrustDecisionResult ??
            (value) =>
                DaliReportService.current?.reportTrustDecisionResult(value) ??
                Future<void>.value())(result),
      );
      if (!result.success) {
        await _fail(
          result.message.isNotEmpty
              ? result.message
              : 'Liveness verification failed',
        );
        return;
      }
      if (result.image.trim().isEmpty || result.livenessId.trim().isEmpty) {
        await _fail('Liveness verification returned incomplete data');
        return;
      }

      await widget.dismissLoading();
      await widget.showLoading();
      final filePath = await widget.faceImageFilePathBuilder(
        result.image.trim(),
      );
      await client.uploadImage(
        sociologeses: '10',
        scabble: '1',
        filePath: filePath,
        fileField: 'attach',
        rapscallion: cardType,
        feoffed: result.livenessId.trim(),
        miscasts: token.license,
        pileated: '7',
      );
      unawaited(
        (widget.reportRiskScene ??
            (startTimeSeconds) =>
                DaliReportService.current?.reportRisk(
                  productId: productId,
                  scene: '4',
                  startedAtSeconds: startTimeSeconds,
                ) ??
                Future<void>.value())(riskStartTime),
      );
      await widget.dismissLoading();
      if (!mounted) return;
      (widget.logger ?? IdentityFacePage._defaultLogger)(
        'identity face upload completed: '
        'productId=$productId, type=$cardType',
      );
      await widget.continueProductDetailFlow(productId);
    } catch (error) {
      await _fail(ApiErrorMessage.resolve(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _fail(String message) async {
    await widget.dismissLoading();
    await widget.showError(message);
  }

  Future<void> _showCameraPermissionDialog() {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Camera permission required'),
          content: const Text(
            'Please enable camera access in Settings to continue.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await widget.openAppSettingsPage();
              },
              isDefaultAction: true,
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }
}

class _IdentityFaceToken {
  const _IdentityFaceToken({
    required this.code,
    required this.license,
    required this.errorMessage,
    required this.faceType,
  });

  factory _IdentityFaceToken.fromResponse(dynamic response) {
    final states = response.states;
    return _IdentityFaceToken(
      code: states['trihedral'].stringValue.trim(),
      license: states['squeezer'].stringValue.trim(),
      errorMessage: states['amputating'].stringValue.trim(),
      faceType: states['pileated'].intValue,
    );
  }

  final String code;
  final String license;
  final String errorMessage;
  final int faceType;
}

Future<PermissionStatus> _defaultRequestCameraPermission() {
  return Permission.camera.request();
}

Future<TrustDecisionLivenessResult> _defaultShowTrustDecisionLiveness(
  String license,
) {
  return ClientBridge().showTrustDecisionLiveness(license);
}

Future<String> _defaultFaceImageFilePathBuilder(String imageBase64) async {
  final normalized = imageBase64.contains(',')
      ? imageBase64.split(',').last
      : imageBase64;
  final bytes = base64Decode(normalized);
  final file = File(
    '${Directory.systemTemp.path}/identity_face_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> _defaultShowLoading() {
  return EasyLoading.show(status: 'Loading...');
}

Future<void> _defaultDismissLoading() {
  return EasyLoading.dismiss();
}

Future<void> _defaultShowError(String message) {
  return EasyLoading.showError(message);
}

Future<void> _defaultContinueProductDetailFlow(String productId) {
  return NavigationHelper.continueProductDetailFlow(productId);
}

class _IdentityFaceHeader extends StatelessWidget {
  const _IdentityFaceHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(44),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'Back',
              child: InkWell(
                onTap: onBack,
                child: Padding(
                  padding: EdgeInsets.all(ScreenAdapter.width(8)),
                  child: Image.asset(
                    AppAssets.identityBack,
                    width: ScreenAdapter.width(24),
                    height: ScreenAdapter.height(24),
                  ),
                ),
              ),
            ),
          ),
          Text(
            'ID Verification',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: ScreenAdapter.font(17),
              fontWeight: FontWeight.w600,
              height: 24 / 17,
            ),
          ),
        ],
      ),
    );
  }
}
