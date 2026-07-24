import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/theme/app_colors.dart';

enum IdentityUploadMethod { camera, album }

typedef IdentityUploadMethodLogger = void Function(IdentityUploadMethod method);

Future<IdentityUploadMethod?> showIdentityUploadMethodSheet(
  BuildContext context, {
  IdentityUploadMethodLogger? onSelected,
}) {
  return showGeneralDialog<IdentityUploadMethod>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss identity upload methods',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _IdentityUploadMethodDialog(onSelected: onSelected);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _IdentityUploadMethodDialog extends StatelessWidget {
  const _IdentityUploadMethodDialog({this.onSelected});

  final IdentityUploadMethodLogger? onSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const Key('identity-upload-method-dialog'),
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const ColoredBox(color: AppColors.dialogBarrier),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            key: const Key('identity-upload-method-sheet'),
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ScreenAdapter.width(24)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IdentityUploadMethodRow(
                    key: const Key('identity-upload-camera'),
                    label: 'Camera',
                    onTap: () => _select(context, IdentityUploadMethod.camera),
                  ),
                  _IdentityUploadMethodRow(
                    key: const Key('identity-upload-album'),
                    label: 'Album',
                    showTopDivider: true,
                    onTap: () => _select(context, IdentityUploadMethod.album),
                  ),
                  _IdentityUploadMethodRow(
                    key: const Key('identity-upload-quit'),
                    label: 'Quit',
                    height: 56,
                    showTopDivider: true,
                    isQuit: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  SafeArea(top: false, child: const SizedBox()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _select(BuildContext context, IdentityUploadMethod method) {
    onSelected?.call(method);
    Navigator.of(context).pop(method);
  }
}

class _IdentityUploadMethodRow extends StatelessWidget {
  const _IdentityUploadMethodRow({
    super.key,
    required this.label,
    this.height = 57,
    this.showTopDivider = false,
    this.isQuit = false,
    required this.onTap,
  });

  final String label;
  final double height;
  final bool showTopDivider;
  final bool isQuit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: ScreenAdapter.height(height),
        child: Column(
          children: [
            if (showTopDivider)
              SizedBox(
                height: ScreenAdapter.height(1),
                child: const ColoredBox(color: AppColors.dialogDivider),
              ),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isQuit ? AppColors.dialogQuit : AppColors.dialogText,
                    fontSize: ScreenAdapter.font(isQuit ? 16 : 14),
                    fontWeight: FontWeight.w400,
                    height: isQuit ? 19 / 16 : 17 / 14,
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
