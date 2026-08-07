import 'dart:ui' as ui;

import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/navigation/navigation_helper.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/features/main_shell/main_controller.dart';
import 'package:dali_cash/features/mine/account_session_coordinator.dart';
import 'package:dali_cash/features/orders/order_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MinePage extends StatefulWidget {
  const MinePage({
    super.key,
    this.loadAppVersion,
    this.accountSessionCoordinator,
  });

  final Future<String> Function()? loadAppVersion;
  final AccountSessionCoordinator? accountSessionCoordinator;

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  late final Future<String> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = _resolveAppVersion(
      widget.loadAppVersion ?? _loadInstalledAppVersion,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    ScreenAdapter.width(16),
                    ScreenAdapter.height(11),
                    ScreenAdapter.width(16),
                    ScreenAdapter.height(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _MineTitle(),
                      SizedBox(height: ScreenAdapter.height(26)),
                      const _MineAccountHeader(),
                      SizedBox(height: ScreenAdapter.height(24)),
                      const _OrderCard(),
                      SizedBox(height: ScreenAdapter.height(16)),
                      const _CustomerServiceSection(),
                      SizedBox(height: ScreenAdapter.height(16)),
                      _AboutUsSection(
                        versionFuture: _versionFuture,
                        accountSessionCoordinator:
                            widget.accountSessionCoordinator,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MineTitle extends StatelessWidget {
  const _MineTitle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(24),
      child: Center(
        child: Text(
          'Mine',
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

class _MineAccountHeader extends StatelessWidget {
  const _MineAccountHeader();

  @override
  Widget build(BuildContext context) {
    final phoneText = Get.isRegistered<MainController>()
        ? Obx(
            () => Text(
              formatMinePhone(Get.find<MainController>().phoneNumber.value),
              style: _phoneTextStyle(),
            ),
          )
        : Text('', style: _phoneTextStyle());
    return SizedBox(
      height: ScreenAdapter.height(40),
      child: Row(
        children: [
          Container(
            width: ScreenAdapter.width(40),
            height: ScreenAdapter.height(40),
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border.all(
                color: AppColors.surface,
                width: ScreenAdapter.width(1),
              ),
              borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
            ),
          ),
          SizedBox(width: ScreenAdapter.width(8)),
          phoneText,
        ],
      ),
    );
  }

  TextStyle _phoneTextStyle() {
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: ScreenAdapter.font(22),
      fontWeight: FontWeight.w700,
      height: 27 / 22,
    );
  }
}

String formatMinePhone(String rawPhone) {
  final phone = rawPhone.trim();
  if (phone.length <= 7) {
    return phone;
  }
  return '${phone.substring(0, 3)} **** ${phone.substring(phone.length - 4)}';
}

class _OrderCard extends StatelessWidget {
  const _OrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mine-order-card'),
      constraints: BoxConstraints(minHeight: ScreenAdapter.height(95)),
      padding: EdgeInsets.symmetric(
        horizontal: ScreenAdapter.width(18),
        vertical: ScreenAdapter.height(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _OrderShortcut(
            key: Key('mine-order-all'),
            label: 'View All',
            asset: AppAssets.mineOrderAll,
            status: MineOrderStatus.all,
          ),
          _OrderShortcut(
            key: Key('mine-order-unpaid'),
            label: 'Unpaid',
            asset: AppAssets.mineOrderUnpaid,
            status: MineOrderStatus.unpaid,
          ),
          _OrderShortcut(
            key: Key('mine-order-late'),
            label: 'Late',
            asset: AppAssets.mineOrderLate,
            status: MineOrderStatus.late,
          ),
          _OrderShortcut(
            key: Key('mine-order-paid'),
            label: 'Paid',
            asset: AppAssets.mineOrderPaid,
            status: MineOrderStatus.paid,
          ),
        ],
      ),
    );
  }
}

class _OrderShortcut extends StatelessWidget {
  const _OrderShortcut({
    super.key,
    required this.label,
    required this.asset,
    required this.status,
  });

  final String label;
  final String asset;
  final MineOrderStatus status;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => NavigationHelper.toMineOrderList(initialStatus: status),
      child: SizedBox(
        width: ScreenAdapter.width(58),
        child: Column(
          children: [
            Image.asset(
              asset,
              width: ScreenAdapter.width(40),
              height: ScreenAdapter.height(40),
            ),
            SizedBox(height: ScreenAdapter.height(5)),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: ScreenAdapter.font(12),
                fontWeight: FontWeight.w400,
                height: 18 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerServiceSection extends StatelessWidget {
  const _CustomerServiceSection();

  static const _customerServicePath = '/#/SlinkierDesulfured';

  @override
  Widget build(BuildContext context) {
    return _MineSection(
      headerAsset: AppAssets.mineCustomerServiceHeader,
      headerWidth: 162,
      child: ClipRRect(
        key: const Key('mine-customer-service-card'),
        borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
        child: _MineRow(
          key: const Key('mine-customer-service'),
          iconAsset: AppAssets.mineCustomerService,
          label: 'Smart customer service',
          onTap: () =>
              NavigationHelper.toWebPath<void>(path: _customerServicePath),
          showChevron: true,
        ),
      ),
    );
  }
}

class _AboutUsSection extends StatelessWidget {
  const _AboutUsSection({
    required this.versionFuture,
    required this.accountSessionCoordinator,
  });

  final Future<String> versionFuture;
  final AccountSessionCoordinator? accountSessionCoordinator;

  @override
  Widget build(BuildContext context) {
    return _MineSection(
      headerAsset: AppAssets.mineAboutUsHeader,
      headerWidth: 102,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
        child: Column(
          children: [
            _MineRow(
              key: const Key('mine-website'),
              iconAsset: AppAssets.mineWebsite,
              label: 'Website',
              trailing: _WebsiteTrailing(onCopy: () => _logTap('Copy Website')),
              onTap: () => _logTap('Website'),
            ),
            _MineRow(
              key: const Key('mine-app-version'),
              iconAsset: AppAssets.mineAppVersion,
              label: 'APP Version',
              trailing: FutureBuilder<String>(
                future: versionFuture,
                initialData: 'v--',
                builder: (context, snapshot) {
                  return _MineTrailingText(value: snapshot.data ?? 'v--');
                },
              ),
            ),
            _MineRow(
              key: const Key('mine-privacy-agreement'),
              iconAsset: AppAssets.minePrivacyAgreement,
              label: 'Privacy Agreement',
              onTap: () => NavigationHelper.toWebPath<void>(
                path: NavigationHelper.privacyAgreementPath,
              ),
              showChevron: true,
            ),
            _MineRow(
              key: const Key('mine-account'),
              iconAsset: AppAssets.mineAccount,
              label: 'Account',
              onTap: () => _showAccountActions(
                context,
                accountSessionCoordinator: accountSessionCoordinator,
              ),
              showChevron: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MineSection extends StatelessWidget {
  const _MineSection({
    required this.headerAsset,
    required this.headerWidth,
    required this.child,
  });

  final String headerAsset;
  final double headerWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          headerAsset,
          width: ScreenAdapter.width(headerWidth),
          height: ScreenAdapter.height(55),
          fit: BoxFit.fill,
        ),
        Transform.translate(
          offset: Offset(0, -ScreenAdapter.height(7)),
          child: child,
        ),
      ],
    );
  }
}

class _MineRow extends StatelessWidget {
  const _MineRow({
    super.key,
    required this.iconAsset,
    required this.label,
    this.trailing,
    this.onTap,
    this.showChevron = false,
  });

  final String iconAsset;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      height: ScreenAdapter.height(56),
      padding: EdgeInsets.symmetric(horizontal: ScreenAdapter.width(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: ScreenAdapter.height(1),
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            iconAsset,
            width: ScreenAdapter.width(24),
            height: ScreenAdapter.height(24),
          ),
          SizedBox(width: ScreenAdapter.width(14)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: ScreenAdapter.font(14),
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
          ),
          ?trailing,
          if (showChevron) ...[
            if (trailing != null) SizedBox(width: ScreenAdapter.width(12)),
            Image.asset(
              AppAssets.mineChevronRight,
              width: ScreenAdapter.width(7),
              height: ScreenAdapter.height(11),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}

class _MineTrailingText extends StatelessWidget {
  const _MineTrailingText({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        color: AppColors.textDetail,
        fontSize: ScreenAdapter.font(12),
        fontWeight: FontWeight.w400,
        height: 17 / 12,
      ),
    );
  }
}

class _WebsiteTrailing extends StatelessWidget {
  const _WebsiteTrailing({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'xxxxx.com',
          style: TextStyle(
            color: AppColors.textDetail,
            fontSize: ScreenAdapter.font(12),
            fontWeight: FontWeight.w400,
            height: 17 / 12,
          ),
        ),
        SizedBox(width: ScreenAdapter.width(8)),
        GestureDetector(
          key: const Key('mine-copy-website'),
          behavior: HitTestBehavior.opaque,
          onTap: onCopy,
          child: Icon(
            Icons.copy_rounded,
            color: AppColors.textDetail,
            size: ScreenAdapter.width(20),
          ),
        ),
      ],
    );
  }
}

class _AccountActionsDialog extends StatelessWidget {
  const _AccountActionsDialog();

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const Key('account-actions-dialog'),
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
            key: const Key('account-actions-sheet'),
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
                  _AccountActionRow(
                    key: Key('account-action-log-out'),
                    label: 'Log out',
                    height: 57,
                    onTap: () => _logAndReturnAccountAction(
                      context,
                      _AccountAction.logOut,
                    ),
                  ),
                  _AccountActionRow(
                    key: Key('account-action-delete'),
                    label: 'Delete Account',
                    height: 57,
                    showTopDivider: true,
                    onTap: () => _logAndReturnAccountAction(
                      context,
                      _AccountAction.deleteAccount,
                    ),
                  ),
                  _AccountActionRow(
                    key: Key('account-action-quit'),
                    label: 'Quit',
                    height: 56,
                    showTopDivider: true,
                    isQuit: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  SafeArea(top: false, child: SizedBox()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({
    super.key,
    required this.label,
    required this.height,
    this.showTopDivider = false,
    this.isQuit = false,
    this.onTap,
  });

  final String label;
  final double height;
  final bool showTopDivider;
  final bool isQuit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = SizedBox(
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
    );

    if (onTap == null) {
      return row;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}

enum _AccountAction { logOut, deleteAccount }

void _logAndReturnAccountAction(BuildContext context, _AccountAction action) {
  _logTap(action == _AccountAction.logOut ? 'Log out' : 'Delete Account');
  Navigator.of(context).pop(action);
}

Future<void> _showAccountActions(
  BuildContext context, {
  AccountSessionCoordinator? accountSessionCoordinator,
}) async {
  _logTap('Account');
  final action = await showGeneralDialog<_AccountAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss account actions',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _AccountActionsDialog();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
  if (action != null && context.mounted) {
    await _showRetentionDialog(
      context,
      action,
      accountSessionCoordinator: accountSessionCoordinator,
    );
  }
}

class _RetentionDialogData {
  const _RetentionDialogData({
    required this.body,
    required this.keepLabel,
    required this.keepLog,
  });

  final String body;
  final String keepLabel;
  final String keepLog;
}

Future<void> _showRetentionDialog(
  BuildContext context,
  _AccountAction action, {
  AccountSessionCoordinator? accountSessionCoordinator,
}) async {
  final data = action == _AccountAction.logOut
      ? const _RetentionDialogData(
          body:
              'Stay logged in to receive instant alerts on your limit and payments.',
          keepLabel: 'Keep Me In',
          keepLog: 'Keep Me In',
        )
      : const _RetentionDialogData(
          body:
              'Once deleted, all your credit history and limit disappear. Stay with us?',
          keepLabel: 'Keep Account',
          keepLog: 'Keep Account',
        );

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss account retention dialog',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AccountRetentionDialog(
        data: data,
        action: action,
        accountSessionCoordinator: accountSessionCoordinator,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _AccountRetentionDialog extends StatefulWidget {
  const _AccountRetentionDialog({
    required this.data,
    required this.action,
    required this.accountSessionCoordinator,
  });

  final _RetentionDialogData data;
  final _AccountAction action;
  final AccountSessionCoordinator? accountSessionCoordinator;

  @override
  State<_AccountRetentionDialog> createState() =>
      _AccountRetentionDialogState();
}

class _AccountRetentionDialogState extends State<_AccountRetentionDialog> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width - 32;
    final scale = cardWidth / 343;

    return Stack(
      key: const Key('account-retention-dialog'),
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const ColoredBox(color: AppColors.dialogBarrier),
            ),
          ),
        ),
        Center(
          child: Container(
            key: const Key('account-retention-card'),
            width: cardWidth,
            height: cardWidth * 332 / 343,
            padding: EdgeInsets.fromLTRB(
              12 * scale,
              58 * scale,
              12 * scale,
              20 * scale,
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.mineAccountRetentionBackground),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Confirm to exit?',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: AppColors.surface,
                    fontFamily: 'Georgia',
                    fontSize: 26 * scale,
                    fontWeight: FontWeight.w700,
                    height: 30 / 26,
                  ),
                ),
                SizedBox(height: 69 * scale),
                SizedBox(
                  width: 253 * scale,
                  height: 44 * scale,
                  child: Text(
                    widget.data.body,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: AppColors.retentionBody,
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w400,
                      height: 22 / 16,
                    ),
                  ),
                ),
                SizedBox(height: 36 * scale),
                SizedBox(
                  key: const Key('account-retention-keep'),
                  width: 319 * scale,
                  height: 40 * scale,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _logTap(widget.data.keepLog);
                      Navigator.of(context).pop();
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.retentionGradientStart,
                            AppColors.retentionGradientMiddle,
                            AppColors.retentionGradientEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                      child: Center(
                        child: Text(
                          widget.data.keepLabel,
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
                ),
                SizedBox(height: 16 * scale),
                GestureDetector(
                  key: const Key('account-retention-close'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _submitting ? null : _closeAnyway,
                  child: Text(
                    'Close Anyway',
                    style: TextStyle(
                      color: AppColors.retentionSecondary,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      height: 18 / 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _closeAnyway() async {
    _logTap('Close Anyway');
    setState(() => _submitting = true);
    final coordinator =
        widget.accountSessionCoordinator ?? _defaultAccountSessionCoordinator();
    final succeeded = await coordinator.execute(_sessionAction(widget.action));
    if (!mounted) return;
    if (succeeded) {
      Navigator.of(context).pop();
    } else {
      setState(() => _submitting = false);
    }
  }
}

Future<String> _loadInstalledAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

Future<String> _resolveAppVersion(Future<String> Function() loader) async {
  try {
    return 'v${await loader()}';
  } catch (_) {
    return 'v--';
  }
}

void _logTap(String entry) {
  debugPrint('[MinePage] $entry tapped');
}

AccountSessionAction _sessionAction(_AccountAction action) {
  return switch (action) {
    _AccountAction.logOut => AccountSessionAction.logout,
    _AccountAction.deleteAccount => AccountSessionAction.deleteAccount,
  };
}

AccountSessionCoordinator _defaultAccountSessionCoordinator() {
  final apiClient = Get.find<ApiClient>();
  return AccountSessionCoordinator(
    apiClient: apiClient,
    sessionStore: apiClient.config.sessionStore,
    showLoading: () => EasyLoading.show(status: 'Loading...'),
    dismissLoading: EasyLoading.dismiss,
    showError: EasyLoading.showError,
    returnHome: () async {
      if (Get.isRegistered<MainController>()) {
        Get.find<MainController>().returnToHomeTab();
      }
    },
  );
}
