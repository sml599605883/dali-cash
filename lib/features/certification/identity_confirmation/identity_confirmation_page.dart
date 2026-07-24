import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/resources/app_assets.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/json/json.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../widgets/identity_prompt_banner.dart';
import 'identity_birthday_picker.dart';
import 'identity_recognition_result.dart';

typedef IdentityConfirmationLogger = void Function(String message);

class IdentityConfirmationPage extends StatefulWidget {
  static const defaultPromptMessage =
      'Check your info once more to keep everything on track.';

  const IdentityConfirmationPage({
    super.key,
    this.productId = '',
    this.cardType = '',
    this.recognizedInfo,
    this.logger,
    this.apiClient,
  });

  final String productId;
  final String cardType;
  final IdentityRecognitionResult? recognizedInfo;
  final IdentityConfirmationLogger? logger;
  final ApiClient? apiClient;

  @override
  State<IdentityConfirmationPage> createState() =>
      _IdentityConfirmationPageState();

  static void defaultLogger(String message) {
    log(message, name: 'IdentityConfirmation');
  }
}

class _IdentityConfirmationPageState extends State<IdentityConfirmationPage> {
  late final IdentityRecognitionResult _info;
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _birthdayController;
  bool _isSubmitting = false;
  bool _isSelectingBirthday = false;

  @override
  void initState() {
    super.initState();
    _info =
        widget.recognizedInfo ??
        IdentityRecognitionResult.fromMap(
          Json(Get.arguments)['recognizedInfo'].rawMapValue,
        );
    _nameController = TextEditingController(text: _info.fullName);
    _idController = TextEditingController(text: _info.idNumber);
    _birthdayController = TextEditingController(
      text: normalizeIdentityBirthday(_info.dateOfBirth),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    final prompt = _promptMessage();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            child: Column(
              children: [
                const _IdentityConfirmationHeader(),
                SizedBox(height: ScreenAdapter.height(10)),
                IdentityPromptBanner(
                  message: prompt.isEmpty
                      ? IdentityConfirmationPage.defaultPromptMessage
                      : prompt,
                ),
                SizedBox(height: ScreenAdapter.height(12)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenAdapter.width(16),
                    ),
                    child: _IdentityInformationCard(
                      info: _info,
                      nameController: _nameController,
                      idController: _idController,
                      birthdayController: _birthdayController,
                      onBirthdayTap: _selectBirthday,
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
                ScreenAdapter.height(16),
                ScreenAdapter.width(16),
                ScreenAdapter.height(20),
              ),
              child: SizedBox(
                height: ScreenAdapter.height(46),
                child: ElevatedButton(
                  key: const Key('identityConfirmationUploadButton'),
                  onPressed: _isSubmitting ? null : _submit,
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

  String _promptMessage() {
    final client =
        widget.apiClient ??
        (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null);
    return client?.config.sessionStore
            .productDetailIdentityConfirmationPrompt() ??
        '';
  }

  String _productId() => widget.productId.trim().isNotEmpty
      ? widget.productId.trim()
      : Json(Get.arguments)['highlands'].stringValue.trim();

  String _cardType() => widget.cardType.trim().isNotEmpty
      ? widget.cardType.trim()
      : Json(Get.arguments)['cardType'].stringValue.trim();

  Future<void> _selectBirthday() async {
    if (_isSelectingBirthday) return;
    _isSelectingBirthday = true;
    try {
      final selected = await showIdentityBirthdayPicker(
        context: context,
        initialDate: parseIdentityBirthday(
          _birthdayController.text.trim(),
          maximumDate: DateTime.now(),
        ),
      );
      if (selected != null && mounted) {
        _birthdayController.text = formatIdentityBirthday(selected);
      }
    } finally {
      _isSelectingBirthday = false;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await EasyLoading.show(status: 'Loading...');
    try {
      final client = widget.apiClient ?? Get.find<ApiClient>();
      await client.saveBasicInfo(
        annealers: _birthdayController.text.trim(),
        imputes: _idController.text.trim(),
        crocidolites: _nameController.text.trim(),
        sociologeses: '11',
        rapscallion: _cardType(),
      );
      await EasyLoading.dismiss();
      if (!mounted) return;
      (widget.logger ?? IdentityConfirmationPage.defaultLogger)(
        'identity confirmation submitted: '
        'productId=${_productId()}, type=${_cardType()}',
      );
      unawaited(
        Get.toNamed<void>(
          AppRoutes.identityFace,
          arguments: {'highlands': _productId(), 'cardType': _cardType()},
        ),
      );
    } catch (error) {
      await EasyLoading.showError(ApiErrorMessage.resolve(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _IdentityInformationCard extends StatelessWidget {
  const _IdentityInformationCard({
    required this.info,
    required this.nameController,
    required this.idController,
    required this.birthdayController,
    required this.onBirthdayTap,
  });

  final IdentityRecognitionResult info;
  final TextEditingController nameController;
  final TextEditingController idController;
  final TextEditingController birthdayController;
  final VoidCallback onBirthdayTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ScreenAdapter.width(343),
      padding: EdgeInsets.all(ScreenAdapter.width(12)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
            child: SizedBox(
              key: const Key('identityConfirmationImage'),
              width: ScreenAdapter.width(319),
              height: ScreenAdapter.height(200),
              child: info.imageUrl.trim().isEmpty
                  ? const _IdentityImageFallback()
                  : Image.network(
                      info.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _IdentityImageFallback(),
                    ),
            ),
          ),
          SizedBox(height: ScreenAdapter.height(8)),
          _IdentityInformationRow(
            label: 'Full Name',
            controller: nameController,
            fieldKey: const Key('identityConfirmationNameInput'),
            textInputAction: TextInputAction.next,
          ),
          _IdentityInformationRow(
            label: 'ID No.',
            controller: idController,
            fieldKey: const Key('identityConfirmationIdInput'),
            textInputAction: TextInputAction.next,
          ),
          _IdentityInformationRow(
            label: 'Date of Birth',
            controller: birthdayController,
            fieldKey: const Key('identityConfirmationBirthdayInput'),
            showDivider: false,
            readOnly: true,
            onTap: onBirthdayTap,
          ),
        ],
      ),
    );
  }
}

class _IdentityImageFallback extends StatelessWidget {
  const _IdentityImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.pageBackground,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textMuted,
          size: ScreenAdapter.width(40),
        ),
      ),
    );
  }
}

class _IdentityInformationRow extends StatelessWidget {
  const _IdentityInformationRow({
    required this.label,
    required this.controller,
    required this.fieldKey,
    this.showDivider = true,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final Key fieldKey;
  final bool showDivider;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ScreenAdapter.height(56),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: AppColors.identityDivider,
                  width: ScreenAdapter.height(1),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.recommendationCaption,
                fontSize: ScreenAdapter.font(14),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: TextField(
              key: fieldKey,
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              textAlign: TextAlign.right,
              textInputAction: textInputAction,
              maxLines: 1,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: ScreenAdapter.font(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityConfirmationHeader extends StatelessWidget {
  const _IdentityConfirmationHeader();

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
