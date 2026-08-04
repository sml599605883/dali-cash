import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';

typedef CertificationRetentionExit = VoidCallback;

class CertificationRetentionPopup extends StatelessWidget {
  const CertificationRetentionPopup({
    super.key,
    required this.imageUrl,
    required this.continueText,
    required this.exitText,
    required this.onExit,
    this.imageProvider,
  });

  static const continueButtonKey = Key('certificationRetentionContinue');
  static const exitButtonKey = Key('certificationRetentionExit');
  static const cardKey = Key('certificationRetentionCard');
  static const _designWidth = 343.0;
  static const _designHeight = 332.0;

  final String imageUrl;
  final String continueText;
  final String exitText;
  final CertificationRetentionExit onExit;
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) {
    final width = math.min(_designWidth, MediaQuery.sizeOf(context).width - 32);
    return Center(
      child: SizedBox(
        key: cardKey,
        width: width,
        height: width * (_designHeight / _designWidth),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: imageProvider ?? NetworkImage(imageUrl),
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            Positioned(
              left: width * 25 / _designWidth,
              right: width * 25 / _designWidth,
              bottom: width * 17 / _designWidth,
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      key: exitButtonKey,
                      label: exitText,
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.surface,
                      onTap: () {
                        Get.back<void>();
                        onExit();
                      },
                    ),
                  ),
                  SizedBox(width: width * 10 / _designWidth),
                  Expanded(
                    child: _ActionButton(
                      key: continueButtonKey,
                      label: continueText,
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.surface,
                      onTap: Get.back<void>,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
