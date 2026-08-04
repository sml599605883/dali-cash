import 'dart:async';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import 'certification_retention_popup.dart';

typedef CertificationRetentionPresenter =
    Future<bool> Function({
      required String type,
      required String productId,
      required VoidCallback onExit,
    });

class CertificationRetentionGuard {
  CertificationRetentionGuard._();

  static CertificationRetentionPresenter presenter = _defaultPresenter;

  static void resetPresenter() => presenter = _defaultPresenter;

  static VoidCallback backHandler({
    required String type,
    required String productId,
    required VoidCallback onDefaultBack,
  }) {
    return () {
      unawaited(
        handleBack(
          type: type,
          productId: productId,
          onDefaultBack: onDefaultBack,
        ),
      );
    };
  }

  static Future<void> handleBack({
    required String type,
    required String productId,
    required VoidCallback onDefaultBack,
    CertificationRetentionPresenter? show,
  }) async {
    final normalizedType = type.trim();
    final normalizedProductId = productId.trim();
    if (normalizedType.isEmpty || normalizedProductId.isEmpty) {
      onDefaultBack();
      return;
    }
    final shown = await (show ?? presenter)(
      type: normalizedType,
      productId: normalizedProductId,
      onExit: onDefaultBack,
    );
    if (!shown) onDefaultBack();
  }

  static Future<bool> _defaultPresenter({
    required String type,
    required String productId,
    required VoidCallback onExit,
  }) async {
    try {
      await EasyLoading.show(status: 'Loading...');
      final response = await Get.find<ApiClient>().retentionPopup(
        type: type,
        productId: productId,
      );
      final dialog = response.states['rheologists'];
      final imageUrl = dialog['scabble'].stringValue.trim();
      final continueText = dialog['toilfully'].stringValue.trim();
      final exitText = dialog['undauntable'].stringValue.trim();
      await EasyLoading.dismiss();
      if (imageUrl.isEmpty) return false;
      await Get.dialog<void>(
        CertificationRetentionPopup(
          imageUrl: imageUrl,
          continueText: continueText.isEmpty ? 'Continue' : continueText,
          exitText: exitText.isEmpty ? 'Exit' : exitText,
          onExit: onExit,
        ),
        barrierColor: AppColors.dialogBarrier,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
      );
      return true;
    } catch (_) {
      await EasyLoading.dismiss();
      return false;
    }
  }
}
