import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/resources/app_assets.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/json/json.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../widgets/identity_prompt_banner.dart';
import '../widgets/identity_upload_method_sheet.dart';
import 'identity_upload_services.dart';

typedef IdentityUploadLogger = void Function(String message);
typedef CameraPermissionRequester = Future<bool> Function();
typedef IdentityUploadAppSettingsOpener = Future<bool> Function();

class IdentityUploadPage extends StatefulWidget {
  static const defaultPromptMessage =
      'Security first. Complete ID verification to shield your funds.';

  const IdentityUploadPage({
    super.key,
    this.productId = '',
    this.cardType = '',
    this.promptMessage,
    this.logger,
    this.requestCameraPermission = _requestCameraPermission,
    this.openAppSettingsPage = openAppSettings,
    this.onUploadMethodSelected,
    this.apiClient,
    this.imagePicker,
    this.imageCompressor,
  });

  final String productId;
  final String cardType;
  final String? promptMessage;
  final IdentityUploadLogger? logger;
  final CameraPermissionRequester requestCameraPermission;
  final IdentityUploadAppSettingsOpener openAppSettingsPage;
  final ValueChanged<IdentityUploadMethod>? onUploadMethodSelected;
  final ApiClient? apiClient;
  final IdentityUploadImagePicker? imagePicker;
  final IdentityUploadImageCompressor? imageCompressor;

  @override
  State<IdentityUploadPage> createState() => _IdentityUploadPageState();

  static void _defaultLogger(String message) {
    log(message, name: 'IdentityUpload');
  }
}

class _IdentityUploadPageState extends State<IdentityUploadPage> {
  late final IdentityUploadImagePicker _imagePicker =
      widget.imagePicker ?? DefaultIdentityUploadImagePicker();
  late final IdentityUploadImageCompressor _imageCompressor =
      widget.imageCompressor ?? DefaultIdentityUploadImageCompressor();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    final productId = _productIdFromArguments();
    final cardType = _cardTypeFromArguments();
    final prompt = widget.promptMessage?.trim().isNotEmpty == true
        ? widget.promptMessage!.trim()
        : (Get.isRegistered<ApiClient>()
              ? Get.find<ApiClient>().config.sessionStore.productDetailPrompt()
              : '');
    final writeLog = widget.logger ?? IdentityUploadPage._defaultLogger;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              const _IdentityUploadHeader(),
              SizedBox(height: ScreenAdapter.height(10)),
              IdentityPromptBanner(
                message: prompt.isEmpty
                    ? IdentityUploadPage.defaultPromptMessage
                    : prompt,
              ),
              SizedBox(height: ScreenAdapter.height(12)),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: ScreenAdapter.width(16),
                    right: ScreenAdapter.width(16),
                    bottom: ScreenAdapter.height(16),
                  ),
                  child: Image.asset(
                    key: const Key('identityUploadDemo'),
                    AppAssets.identityUploadDemo,
                    width: ScreenAdapter.width(343),
                    height: ScreenAdapter.height(429),
                    fit: BoxFit.fill,
                    semanticLabel: 'ID upload demonstration examples',
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
              height: ScreenAdapter.height(48),
              child: ElevatedButton(
                key: const Key('identityUploadButton'),
                onPressed: _isUploading
                    ? null
                    : () => _showUploadMethodSheet(
                        context,
                        productId,
                        cardType,
                        writeLog,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
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
    );
  }

  Future<void> _showUploadMethodSheet(
    BuildContext context,
    String productId,
    String cardType,
    IdentityUploadLogger writeLog,
  ) async {
    writeLog('identity upload tapped: productId=$productId, type=$cardType');
    final selectedMethod = await showIdentityUploadMethodSheet(
      context,
      onSelected: (method) => writeLog(
        'identity upload method tapped: '
        '${method == IdentityUploadMethod.camera ? 'Camera' : 'Album'}, '
        'productId=$productId, type=$cardType',
      ),
    );
    if (selectedMethod == null || !mounted) return;
    if (selectedMethod == IdentityUploadMethod.camera &&
        !await widget.requestCameraPermission()) {
      if (mounted) await _showCameraPermissionDialog();
      return;
    }
    widget.onUploadMethodSelected?.call(selectedMethod);
    if (widget.onUploadMethodSelected != null ||
        (widget.apiClient == null && !Get.isRegistered<ApiClient>())) {
      return;
    }
    await _pickCompressAndUpload(selectedMethod);
  }

  Future<void> _showCameraPermissionDialog() {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
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
      ),
    );
  }

  Future<void> _pickCompressAndUpload(IdentityUploadMethod method) async {
    await EasyLoading.show(status: 'Loading...');
    final String? filePath;
    try {
      filePath = method == IdentityUploadMethod.camera
          ? await _imagePicker.pickFromCamera()
          : await _imagePicker.pickFromAlbum();
    } catch (error) {
      await EasyLoading.dismiss();
      if (mounted) {
        await EasyLoading.showError(ApiErrorMessage.resolve(error));
      }
      return;
    }
    if (filePath == null || filePath.isEmpty) {
      await EasyLoading.dismiss();
      return;
    }
    try {
      final compressedPath = await _imageCompressor.compressToLimit(filePath);
      if (compressedPath == null || compressedPath.isEmpty) {
        await EasyLoading.showError('Image compression failed');
        return;
      }
      await _uploadSelectedFile(compressedPath, method);
    } catch (error) {
      await EasyLoading.showError(ApiErrorMessage.resolve(error));
    }
  }

  Future<void> _uploadSelectedFile(
    String filePath,
    IdentityUploadMethod method,
  ) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final client = widget.apiClient ?? Get.find<ApiClient>();
      final response = await client.uploadImage(
        sociologeses: '11',
        scabble: method == IdentityUploadMethod.album ? '1' : '2',
        filePath: filePath,
        fileField: 'attach',
        rapscallion: _cardTypeFromArguments(),
        feoffed: null,
        miscasts: null,
        pileated: null,
        infantilisms: null,
      );
      await EasyLoading.dismiss();
      if (!mounted) return;
      unawaited(
        Get.toNamed<void>(
          AppRoutes.identityConfirmation,
          arguments: {
            'highlands': _productIdFromArguments(),
            'cardType': _cardTypeFromArguments(),
            'recognizedInfo': response.states.rawMapValue,
          },
        ),
      );
      _writeLog(
        'identity upload completed: '
        'productId=${_productIdFromArguments()}, '
        'type=${_cardTypeFromArguments()}',
      );
    } catch (error) {
      await EasyLoading.showError(ApiErrorMessage.resolve(error));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _productIdFromArguments() {
    return widget.productId.trim().isNotEmpty
        ? widget.productId.trim()
        : Json(Get.arguments)['highlands'].stringValue.trim();
  }

  String _cardTypeFromArguments() {
    return widget.cardType.trim().isNotEmpty
        ? widget.cardType.trim()
        : Json(Get.arguments)['cardType'].stringValue.trim();
  }

  void _writeLog(String message) {
    (widget.logger ?? IdentityUploadPage._defaultLogger)(message);
  }
}

Future<bool> _requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}

class _IdentityUploadHeader extends StatelessWidget {
  const _IdentityUploadHeader();

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
                onTap: Get.back<void>,
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
