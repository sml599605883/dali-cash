import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/resources/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../widgets/certification_retention_guard.dart';
import 'identity_selection_controller.dart';

class IdentitySelectionPage extends GetView<IdentitySelectionController> {
  const IdentitySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<IdentitySelectionController>(
      builder: (_) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    ScreenAdapter.init(context);
    final onBack = CertificationRetentionGuard.backHandler(
      type: '0',
      productId: controller.productId,
      onDefaultBack: Get.back<void>,
    );
    final busy = controller.state == IdentitySelectionState.loading;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !busy) onBack();
        },
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: busy,
              child: Scaffold(
                backgroundColor: AppColors.pageBackground,
                body: SafeArea(
                  child: Column(
                    children: [
                      _IdentityHeader(onBack: onBack),
                      Expanded(child: _buildContent(controller)),
                    ],
                  ),
                ),
              ),
            ),
            if (busy)
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(IdentitySelectionController controller) {
    return switch (controller.state) {
      IdentitySelectionState.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      IdentitySelectionState.empty => const _IdentityMessage(
        message: 'No ID types available',
      ),
      IdentitySelectionState.error => _IdentityMessage(
        message: controller.errorMessage,
        actionLabel: 'Retry',
        onAction: controller.load,
      ),
      IdentitySelectionState.ready => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          ScreenAdapter.width(16),
          ScreenAdapter.height(20),
          ScreenAdapter.width(16),
          ScreenAdapter.height(24),
        ),
        child: Column(
          children: [
            if (controller.recommendedTypes.isNotEmpty)
              _IdentitySection(
                key: const Key('recommendedIdentitySection'),
                labelAsset: AppAssets.identityRecommendedLabel,
                semanticLabel: 'Recommended ID Type',
                labelWidth: 206,
                types: controller.recommendedTypes,
                onSelected: controller.selectType,
              ),
            if (controller.recommendedTypes.isNotEmpty &&
                controller.otherTypes.isNotEmpty)
              SizedBox(height: ScreenAdapter.height(24)),
            if (controller.otherTypes.isNotEmpty)
              _IdentitySection(
                key: const Key('otherIdentitySection'),
                labelAsset: AppAssets.identityOtherLabel,
                semanticLabel: 'Other Options',
                labelWidth: 137,
                types: controller.otherTypes,
                onSelected: controller.selectType,
              ),
          ],
        ),
      ),
    };
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.onBack});

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

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({
    super.key,
    required this.labelAsset,
    required this.semanticLabel,
    required this.labelWidth,
    required this.types,
    required this.onSelected,
  });

  final String labelAsset;
  final String semanticLabel;
  final double labelWidth;
  final List<String> types;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: Image.asset(
            labelAsset,
            semanticLabel: semanticLabel,
            width: ScreenAdapter.width(labelWidth),
            height: ScreenAdapter.height(55),
            fit: BoxFit.fill,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: ScreenAdapter.height(48)),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < types.length; index++) ...[
                  _IdentityTypeRow(
                    type: types[index],
                    onTap: () => onSelected(types[index]),
                  ),
                  if (index != types.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenAdapter.width(8),
                      ),
                      child: const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.identityDivider,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityTypeRow extends StatelessWidget {
  const _IdentityTypeRow({required this.type, required this.onTap});

  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: ScreenAdapter.height(49),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenAdapter.width(8)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: ScreenAdapter.font(15),
                    fontWeight: FontWeight.w400,
                    height: 18 / 15,
                  ),
                ),
              ),
              Image.asset(
                AppAssets.mineChevronRight,
                width: ScreenAdapter.width(7),
                height: ScreenAdapter.height(11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityMessage extends StatelessWidget {
  const _IdentityMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ScreenAdapter.width(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: ScreenAdapter.font(14),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: ScreenAdapter.height(16)),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
