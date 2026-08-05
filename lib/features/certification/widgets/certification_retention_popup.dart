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
    final scale = width / _designWidth;
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
              left: 12 * scale,
              right: 12 * scale,
              top: 237 * scale,
              height: 40 * scale,
              child: GestureDetector(
                key: continueButtonKey,
                behavior: HitTestBehavior.opaque,
                onTap: Get.back<void>,
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.retentionGradientStart,
                        AppColors.retentionGradientMiddle,
                        AppColors.retentionGradientEnd,
                      ],
                      stops: [0, 0.47929414, 1],
                    ),
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Text(
                    continueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      height: 18 / 15,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12 * scale,
              right: 12 * scale,
              top: 293 * scale,
              height: 18 * scale,
              child: GestureDetector(
                key: exitButtonKey,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Get.back<void>();
                  onExit();
                },
                child: Center(
                  child: Text(
                    exitText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.retentionSecondary,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      height: 18 / 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
