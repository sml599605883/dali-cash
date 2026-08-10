import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../app/layout/screen_adapter.dart';
import '../../app/navigation/navigation_helper.dart';
import '../../app/resources/app_assets.dart';
import '../../app/theme/app_colors.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'account_list_data.dart';

typedef AccountListLoad = Future<Json> Function(String productId);
typedef AccountListSubmit =
    Future<String> Function({required String orderNo, required String bindId});
typedef AccountListAddMethod =
    Future<void> Function({required String productId, required String orderNo});
typedef AccountListReplace = Future<void> Function(String url);
typedef AccountListMessage = Future<void> Function(String message);
typedef AccountListAsyncAction = Future<void> Function();

class AccountListPage extends StatefulWidget {
  const AccountListPage({
    super.key,
    this.productId = '',
    this.orderNo = '',
    this.load,
    this.submit,
    this.addMethod,
    this.replace,
    this.showError,
    this.showLoading,
    this.dismissLoading,
  });

  final String productId;
  final String orderNo;
  final AccountListLoad? load;
  final AccountListSubmit? submit;
  final AccountListAddMethod? addMethod;
  final AccountListReplace? replace;
  final AccountListMessage? showError;
  final AccountListAsyncAction? showLoading;
  final AccountListAsyncAction? dismissLoading;

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  bool _loading = true;
  bool _submitting = false;
  String _loadError = '';
  List<AccountListSection> _sections = const [];
  AccountListItem? _selected;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _AccountListHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: _AccountListFooter(
        enabled: _selected != null && !_submitting,
        submitting: _submitting,
        onConfirm: _confirm,
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('accountListLoading'),
          color: AppColors.primary,
        ),
      );
    }
    if (_loadError.isNotEmpty) {
      return _AccountListStatus(message: _loadError, onRetry: _load);
    }
    if (_sections.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenAdapter.width(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No payment methods available',
                style: TextStyle(color: AppColors.recommendationCaption),
              ),
              SizedBox(height: ScreenAdapter.height(16)),
              _AddPaymentMethod(onTap: _addPaymentMethod),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        ScreenAdapter.width(16),
        ScreenAdapter.height(8),
        ScreenAdapter.width(16),
        ScreenAdapter.height(24),
      ),
      child: Center(
        child: SizedBox(
          key: const Key('accountListContent'),
          width: ScreenAdapter.width(343),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in _sections) ...[
                _SectionLabel(section: section),
                for (final account in section.accounts) ...[
                  _AccountCard(
                    section: section,
                    account: account,
                    selected: _selected?.bindId == account.bindId,
                    onTap: () => setState(() => _selected = account),
                  ),
                  SizedBox(height: ScreenAdapter.height(8)),
                ],
                SizedBox(height: ScreenAdapter.height(8)),
              ],
              _AddPaymentMethod(onTap: _addPaymentMethod),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    final productId = _productId;
    final orderNo = _orderNo;
    if (productId.isEmpty || orderNo.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = productId.isEmpty
            ? 'Missing product information'
            : 'Missing order information';
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadError = '';
    });
    try {
      final states = await (widget.load ?? _defaultLoad)(productId);
      final sections = parseAccountSections(states);
      AccountListItem? main;
      for (final section in sections) {
        for (final account in section.accounts) {
          if (account.isMain) {
            main = account;
            break;
          }
        }
        if (main != null) break;
      }
      if (!mounted) return;
      setState(() {
        _sections = sections;
        _selected = main;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sections = const [];
        _selected = null;
        _loading = false;
        _loadError = ApiErrorMessage.resolve(error);
      });
    }
  }

  Future<void> _confirm() async {
    final selected = _selected;
    if (_submitting || selected == null) return;
    setState(() => _submitting = true);
    await (widget.showLoading ?? EasyLoading.show)();
    try {
      final url = await (widget.submit ?? _defaultSubmit)(
        orderNo: _orderNo,
        bindId: selected.bindId,
      );
      if (url.trim().isEmpty) {
        throw ApiBusinessException('Missing account change result url');
      }
      if (NavigationHelper.webViewUri(url) == null) {
        throw ApiBusinessException('Invalid account change result url');
      }
      await (widget.dismissLoading ?? EasyLoading.dismiss)();
      await (widget.replace ?? _defaultReplace)(url.trim());
    } catch (error) {
      if (mounted) {
        await (widget.showError ?? EasyLoading.showError)(
          ApiErrorMessage.resolve(error),
        );
      } else {
        await (widget.dismissLoading ?? EasyLoading.dismiss)();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addPaymentMethod() {
    return (widget.addMethod ?? _defaultAddMethod)(
      productId: _productId,
      orderNo: _orderNo,
    );
  }

  String get _productId {
    final direct = widget.productId.trim();
    if (direct.isNotEmpty) return direct;
    return Json(Get.arguments)['highlands'].stringValue.trim();
  }

  String get _orderNo {
    final direct = widget.orderNo.trim();
    if (direct.isNotEmpty) return direct;
    return Json(Get.arguments)['saggards'].stringValue.trim();
  }

  Future<Json> _defaultLoad(String productId) async {
    final response = await Get.find<ApiClient>().userAccountList(
      productId: productId,
    );
    return response.ensureSuccess().states;
  }

  Future<String> _defaultSubmit({
    required String orderNo,
    required String bindId,
  }) async {
    final response = await Get.find<ApiClient>().changeOrderAccount(
      orderNo: orderNo,
      bindId: bindId,
    );
    return response.ensureSuccess().states['misericorde'].stringValue.trim();
  }

  Future<void> _defaultAddMethod({
    required String productId,
    required String orderNo,
  }) async {
    final route = NavigationHelper.toBindCard<void>(
      productId: productId,
      orderNo: orderNo,
      isAccountChange: true,
    );
    if (route != null) await route;
  }

  Future<void> _defaultReplace(String url) async {
    NavigationHelper.replaceAccountChangeFlowWithWebView<void>(url: url);
  }
}

class _AccountListHeader extends StatelessWidget {
  const _AccountListHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(45),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          Text(
            'Loan Confirmation',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: ScreenAdapter.font(17),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.section});

  final AccountListSection section;

  @override
  Widget build(BuildContext context) {
    final normalized = section.title.toLowerCase();
    final (asset, width) = switch (normalized) {
      'bank' => (AppAssets.accountBankLabel, 72.0),
      'e-wallet' => (AppAssets.accountWalletLabel, 92.0),
      'cash pickup' => (AppAssets.accountCashPickupLabel, 132.0),
      _ => ('', 0.0),
    };
    if (asset.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: ScreenAdapter.height(8)),
        child: Text(
          section.title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: ScreenAdapter.font(16),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Semantics(
      label: section.title,
      image: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(
          asset,
          height: ScreenAdapter.height(48),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.section,
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final AccountListSection section;
  final AccountListItem account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cashPickup =
        section.title.toLowerCase() == 'cash pickup' ||
        account.type.toLowerCase() == 'cash pickup';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('accountListItem-${account.bindId}'),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(ScreenAdapter.width(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _AccountLogo(
                    accountUrl: account.logoUrl,
                    typeUrl: section.typeIconUrl,
                  ),
                  SizedBox(width: ScreenAdapter.width(8)),
                  Expanded(
                    child: Text(
                      account.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: ScreenAdapter.font(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Image.asset(
                    selected
                        ? AppAssets.accountOptionSelected
                        : AppAssets.accountOptionUnselected,
                    key: Key('accountListSelection-${account.bindId}'),
                    width: ScreenAdapter.width(24),
                    height: ScreenAdapter.height(24),
                  ),
                ],
              ),
              SizedBox(height: ScreenAdapter.height(8)),
              Container(
                padding: EdgeInsets.all(ScreenAdapter.width(12)),
                decoration: BoxDecoration(
                  color: AppColors.personalInformationFieldBackground,
                  borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
                ),
                child: cashPickup
                    ? _CashPickupDetails(account: account)
                    : _ReceiptAccount(value: account.accountValue),
              ),
              if (account.isUnderMaintenance) ...[
                SizedBox(height: ScreenAdapter.height(8)),
                Text(
                  account.maintenanceText.isEmpty
                      ? 'Maintenance'
                      : account.maintenanceText,
                  style: TextStyle(
                    color: AppColors.alert,
                    fontSize: ScreenAdapter.font(12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountLogo extends StatelessWidget {
  const _AccountLogo({required this.accountUrl, required this.typeUrl});

  final String accountUrl;
  final String typeUrl;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => typeUrl.isEmpty
        ? SizedBox(
            width: ScreenAdapter.width(32),
            height: ScreenAdapter.height(32),
          )
        : Image.network(
            typeUrl,
            width: ScreenAdapter.width(32),
            height: ScreenAdapter.height(32),
            errorBuilder: (_, _, _) => SizedBox(
              width: ScreenAdapter.width(32),
              height: ScreenAdapter.height(32),
            ),
          );
    if (accountUrl.isEmpty) return fallback();
    return Image.network(
      accountUrl,
      width: ScreenAdapter.width(32),
      height: ScreenAdapter.height(32),
      errorBuilder: (_, _, _) => fallback(),
    );
  }
}

class _ReceiptAccount extends StatelessWidget {
  const _ReceiptAccount({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailLabel('Receipt Account'),
        SizedBox(height: ScreenAdapter.height(8)),
        _DetailValue(value),
      ],
    );
  }
}

class _CashPickupDetails extends StatelessWidget {
  const _CashPickupDetails({required this.account});

  final AccountListItem account;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NameLine(label: 'First Name', value: account.firstName),
        SizedBox(height: ScreenAdapter.height(8)),
        _NameLine(label: 'Middle Name', value: account.middleName),
        SizedBox(height: ScreenAdapter.height(8)),
        _NameLine(label: 'Last Name', value: account.lastName),
      ],
    );
  }
}

class _NameLine extends StatelessWidget {
  const _NameLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DetailLabel(label)),
        SizedBox(width: ScreenAdapter.width(8)),
        Flexible(child: _DetailValue(value)),
      ],
    );
  }
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: TextStyle(
      color: AppColors.recommendationCaption,
      fontSize: ScreenAdapter.font(12),
    ),
  );
}

class _DetailValue extends StatelessWidget {
  const _DetailValue(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontSize: ScreenAdapter.font(16),
      fontWeight: FontWeight.w700,
    ),
  );
}

class _AddPaymentMethod extends StatelessWidget {
  const _AddPaymentMethod({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('accountAddPaymentMethod'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
      child: SizedBox(
        height: ScreenAdapter.height(48),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppAssets.accountAddMethodBorder, fit: BoxFit.fill),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppAssets.accountAddIcon,
                  width: ScreenAdapter.width(16),
                  height: ScreenAdapter.height(16),
                ),
                SizedBox(width: ScreenAdapter.width(8)),
                Flexible(
                  child: Text(
                    'Add other payment methods',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: ScreenAdapter.font(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountListFooter extends StatelessWidget {
  const _AccountListFooter({
    required this.enabled,
    required this.submitting,
    required this.onConfirm,
  });

  final bool enabled;
  final bool submitting;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ScreenAdapter.width(16)),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.personalInformationFooterShadow,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: ScreenAdapter.height(48),
          child: ElevatedButton(
            key: const Key('accountListConfirm'),
            onPressed: enabled ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.recommendationCaption,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
              ),
            ),
            child: submitting
                ? SizedBox(
                    width: ScreenAdapter.width(20),
                    height: ScreenAdapter.height(20),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: ScreenAdapter.font(16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AccountListStatus extends StatelessWidget {
  const _AccountListStatus({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

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
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            SizedBox(height: ScreenAdapter.height(16)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
