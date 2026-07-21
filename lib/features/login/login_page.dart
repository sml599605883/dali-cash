import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/layout/screen_adapter.dart';
import '../../app/resources/app_assets.dart';
import '../../app/theme/app_colors.dart';
import 'login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key, this.onPrivacyPolicyTap});

  final VoidCallback? onPrivacyPolicyTap;

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.loginBackground),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasHeight = math.max(
                    constraints.maxHeight,
                    ScreenAdapter.height(731),
                  );
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: canvasHeight,
                      child: GetBuilder<LoginController>(
                        builder: (controller) => Stack(
                          children: [
                            const _Title(),
                            const _LoginBanner(),
                            _LoginPanel(controller: controller),
                            _AgreementRow(
                              accepted: controller.agreementAccepted,
                              onToggle: controller.toggleAgreement,
                              onPolicyTap:
                                  onPrivacyPolicyTap ?? _logPrivacyPolicyTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _logPrivacyPolicyTap() {
  log('Privacy Policy tapped');
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: ScreenAdapter.height(8),
      left: 0,
      right: 0,
      height: ScreenAdapter.height(24),
      child: Center(
        child: Text(
          'Dali Cash',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: ScreenAdapter.font(17),
            fontWeight: FontWeight.w600,
            height: 24 / 17,
          ),
        ),
      ),
    );
  }
}

class _LoginBanner extends StatelessWidget {
  const _LoginBanner();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const Key('login-banner'),
      top: ScreenAdapter.height(57),
      left: ScreenAdapter.width(16),
      width: ScreenAdapter.width(343),
      height: ScreenAdapter.height(126),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
        child: Image.asset(AppAssets.loginBanner, fit: BoxFit.fill),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const Key('login-panel'),
      top: ScreenAdapter.height(199),
      left: ScreenAdapter.width(16),
      width: ScreenAdapter.width(343),
      height: ScreenAdapter.height(264),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            ScreenAdapter.width(12),
            ScreenAdapter.height(12),
            ScreenAdapter.width(12),
            ScreenAdapter.height(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Please enter mobile number'),
              SizedBox(height: ScreenAdapter.height(8)),
              _PhoneField(controller: controller),
              SizedBox(height: ScreenAdapter.height(16)),
              const _FieldLabel('Verify with SMS Code'),
              SizedBox(height: ScreenAdapter.height(8)),
              _CodeField(controller: controller),
              SizedBox(height: ScreenAdapter.height(16)),
              _ApplyButton(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(22),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: ScreenAdapter.font(16),
          fontWeight: FontWeight.w600,
          height: 22 / 16,
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ScreenAdapter.height(48),
      padding: EdgeInsets.symmetric(horizontal: ScreenAdapter.width(12)),
      decoration: BoxDecoration(
        color: AppColors.loginFieldBackground,
        borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
      ),
      child: Row(
        children: [
          Text(
            '+63',
            style: TextStyle(
              color: AppColors.loginInputText,
              fontSize: ScreenAdapter.font(14),
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
          SizedBox(width: ScreenAdapter.width(8)),
          Container(
            width: ScreenAdapter.width(1),
            height: ScreenAdapter.height(12),
            color: AppColors.loginInputDivider,
          ),
          SizedBox(width: ScreenAdapter.width(8)),
          Expanded(
            child: TextField(
              key: const Key('login-phone-field'),
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: ScreenAdapter.font(14),
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'Mobile numbers starting with 9',
                hintStyle: TextStyle(
                  color: AppColors.loginPlaceholderText,
                  fontSize: ScreenAdapter.font(14),
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final countingDown = controller.countdownSeconds > 0;
    final actionText = countingDown
        ? '${controller.countdownSeconds} S'
        : 'Get it';
    return Container(
      height: ScreenAdapter.height(48),
      padding: EdgeInsets.symmetric(horizontal: ScreenAdapter.width(12)),
      decoration: BoxDecoration(
        color: AppColors.loginFieldBackground,
        borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('login-code-field'),
              controller: controller.codeController,
              focusNode: controller.codeFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: ScreenAdapter.font(14),
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'SMS code',
                hintStyle: TextStyle(
                  color: AppColors.loginPlaceholderText,
                  fontSize: ScreenAdapter.font(14),
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
          GestureDetector(
            key: const Key('login-get-code'),
            behavior: HitTestBehavior.opaque,
            onTap: controller.canRequestCode ? controller.requestSmsCode : null,
            child: Padding(
              padding: EdgeInsets.only(left: ScreenAdapter.width(12)),
              child: Text(
                actionText,
                style: TextStyle(
                  color: countingDown
                      ? AppColors.loginCountdownText
                      : AppColors.primary,
                  fontSize: ScreenAdapter.font(14),
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('login-apply-now'),
      behavior: HitTestBehavior.opaque,
      onTap: controller.canSubmit ? controller.submitSmsCode : null,
      child: Container(
        height: ScreenAdapter.height(46),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
        ),
        alignment: Alignment.center,
        child: Text(
          'Apply Now',
          style: TextStyle(
            color: AppColors.surface,
            fontSize: ScreenAdapter.font(16),
            fontWeight: FontWeight.w500,
            height: 22 / 16,
          ),
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.accepted,
    required this.onToggle,
    required this.onPolicyTap,
  });

  final bool accepted;
  final VoidCallback onToggle;
  final VoidCallback onPolicyTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: ScreenAdapter.width(16),
      right: ScreenAdapter.width(16),
      bottom: ScreenAdapter.height(39),
      height: ScreenAdapter.height(34),
      child: Row(
        children: [
          GestureDetector(
            key: const Key('login-agreement-toggle'),
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: ScreenAdapter.height(9)),
              child: Image.asset(
                accepted
                    ? AppAssets.loginAgreementChecked
                    : AppAssets.loginAgreementUnchecked,
                key: Key(
                  accepted
                      ? 'login-agreement-checked'
                      : 'login-agreement-unchecked',
                ),
                width: ScreenAdapter.width(16),
                height: ScreenAdapter.height(16),
              ),
            ),
          ),
          SizedBox(width: ScreenAdapter.width(12)),
          Expanded(child: _AgreementText(onPolicyTap: onPolicyTap)),
        ],
      ),
    );
  }
}

class _AgreementText extends StatefulWidget {
  const _AgreementText({required this.onPolicyTap});

  final VoidCallback onPolicyTap;

  @override
  State<_AgreementText> createState() => _AgreementTextState();
}

class _AgreementTextState extends State<_AgreementText> {
  late final TapGestureRecognizer _policyRecognizer;

  @override
  void initState() {
    super.initState();
    _policyRecognizer = TapGestureRecognizer()..onTap = widget.onPolicyTap;
  }

  @override
  void didUpdateWidget(covariant _AgreementText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _policyRecognizer.onTap = widget.onPolicyTap;
  }

  @override
  void dispose() {
    _policyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'I have read and agree to the '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: _policyRecognizer,
          ),
        ],
      ),
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: ScreenAdapter.font(12),
        fontWeight: FontWeight.w400,
        height: 17 / 12,
      ),
    );
  }
}
