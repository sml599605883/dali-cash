import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/resources/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/json/json.dart';
import '../../../core/network/api_client.dart';
import '../widgets/identity_prompt_banner.dart';

typedef IdentityFaceLogger = void Function(String message);

class IdentityFacePage extends StatelessWidget {
  static const defaultPromptMessage =
      'Verify your identity to help keep your account secure and complete the process faster.';

  const IdentityFacePage({
    super.key,
    this.productId = '',
    this.cardType = '',
    this.logger,
  });

  final String productId;
  final String cardType;
  final IdentityFaceLogger? logger;

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    final arguments = Json(Get.arguments);
    final resolvedProductId = productId.trim().isNotEmpty
        ? productId.trim()
        : arguments['highlands'].stringValue.trim();
    final resolvedCardType = cardType.trim().isNotEmpty
        ? cardType.trim()
        : arguments['cardType'].stringValue.trim();
    final prompt = Get.isRegistered<ApiClient>()
        ? Get.find<ApiClient>().config.sessionStore.productDetailFacePrompt()
        : '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              const _IdentityFaceHeader(),
              SizedBox(height: ScreenAdapter.height(10)),
              IdentityPromptBanner(
                message: prompt.isEmpty ? defaultPromptMessage : prompt,
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
                onPressed: () => (logger ?? _defaultLogger)(
                  'identity face upload tapped: '
                  'productId=$resolvedProductId, type=$resolvedCardType',
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

  static void _defaultLogger(String message) {
    log(message, name: 'IdentityFace');
  }
}

class _IdentityFaceHeader extends StatelessWidget {
  const _IdentityFaceHeader();

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
