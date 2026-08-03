import 'package:flutter/material.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/theme/app_colors.dart';

class IdentityPromptBanner extends StatelessWidget {
  const IdentityPromptBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        key: const Key('identityPromptBanner'),
        width: ScreenAdapter.width(343),
        height: ScreenAdapter.height(40),
        child: ColoredBox(
          color: AppColors.identityPromptBackground,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ScreenAdapter.width(16),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: ScreenAdapter.font(12),
                  fontWeight: FontWeight.w400,
                  height: 14 / 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
