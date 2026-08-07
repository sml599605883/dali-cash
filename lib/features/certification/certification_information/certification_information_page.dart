import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/navigation/navigation_helper.dart';
import '../../../app/resources/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/json/json.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/report/dali_report_service.dart';
import '../widgets/certification_address_selection_sheet.dart';
import '../widgets/certification_payday_selection_sheet.dart';
import '../widgets/certification_selection_sheet.dart';
import '../widgets/certification_retention_guard.dart';
import '../widgets/identity_prompt_banner.dart';
import '../personal_information/personal_information_data.dart';

typedef CertificationInformationLoad =
    Future<PersonalInformationData> Function(String productId);
typedef CertificationInformationAddressLoad =
    Future<List<PersonalAddressNode>> Function();
typedef CertificationInformationSave =
    Future<void> Function(String productId, Map<String, String> fields);
typedef CertificationInformationMessage = Future<void> Function(String message);
typedef CertificationInformationContinue =
    Future<void> Function(String productId);
typedef CertificationInformationRiskReport =
    Future<void> Function(String productId, int startedAtSeconds);

class CertificationInformationPage extends StatefulWidget {
  const CertificationInformationPage({
    super.key,
    this.productId = '',
    this.title = 'Basic identity information',
    this.defaultPrompt =
        'Add your work details to help us assess your available credit limit.',
    this.progressAsset = AppAssets.personalInformationProgress,
    this.keyPrefix = 'personalInformation',
    this.riskScene = '5',
    this.emptyMessage = 'No personal information available',
    required this.load,
    required this.loadAddresses,
    required this.save,
    this.showError,
    this.continueFlow,
    this.reportRisk,
    this.nowSeconds,
  });

  final String productId;
  final String title;
  final String defaultPrompt;
  final String progressAsset;
  final String keyPrefix;
  final String riskScene;
  final String emptyMessage;
  final CertificationInformationLoad load;
  final CertificationInformationAddressLoad loadAddresses;
  final CertificationInformationSave save;
  final CertificationInformationMessage? showError;
  final CertificationInformationContinue? continueFlow;
  final CertificationInformationRiskReport? reportRisk;
  final int Function()? nowSeconds;

  @override
  State<CertificationInformationPage> createState() =>
      _CertificationInformationPageState();
}

enum _CertificationInformationLoadState { loading, content, empty, error }

class _CertificationInformationPageState
    extends State<CertificationInformationPage> {
  _CertificationInformationLoadState _loadState =
      _CertificationInformationLoadState.loading;
  List<_CertificationInformationFieldState> _fields = const [];
  List<PersonalAddressNode>? _addressNodes;
  String _prompt = '';
  String _loadError = '';
  bool _isSubmitting = false;
  String? _addressLoadingKey;
  late final int _startedAtSeconds;

  @override
  void initState() {
    super.initState();
    _startedAtSeconds = (widget.nowSeconds ?? _nowSeconds)();
    unawaited(_load());
  }

  @override
  void dispose() {
    _disposeFields(_fields);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    final busy =
        _loadState == _CertificationInformationLoadState.loading ||
        _isSubmitting ||
        _addressLoadingKey != null;
    final onBack = CertificationRetentionGuard.backHandler(
      type: widget.riskScene == '6' ? '3' : '2',
      productId: _productId(),
      onDefaultBack: Get.back<void>,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !busy) onBack();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            children: [
              AbsorbPointer(
                absorbing: busy,
                child: Scaffold(
                  backgroundColor: AppColors.pageBackground,
                  body: SafeArea(
                    child: Column(
                      children: [
                        _CertificationInformationHeader(
                          title: widget.title,
                          keyPrefix: widget.keyPrefix,
                          onBack: onBack,
                        ),
                        SizedBox(height: ScreenAdapter.height(10)),
                        IdentityPromptBanner(message: _prompt),
                        SizedBox(height: ScreenAdapter.height(12)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: ScreenAdapter.width(24),
                            ),
                            child: Image.asset(
                              widget.progressAsset,
                              key: Key('${widget.keyPrefix}Progress'),
                              width: ScreenAdapter.width(108),
                              height: ScreenAdapter.height(48),
                              alignment: Alignment.topCenter,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              ScreenAdapter.width(16),
                              0,
                              ScreenAdapter.width(16),
                              ScreenAdapter.height(8),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  ScreenAdapter.width(12),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  ScreenAdapter.width(12),
                                ),
                                child: _buildContent(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottomNavigationBar: _buildFooter(),
                ),
              ),
              if (busy)
                const Positioned.fill(
                  child: ModalBarrier(
                    dismissible: false,
                    color: Colors.transparent,
                  ),
                ),
              if (_isSubmitting || _addressLoadingKey != null)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_loadState) {
      _CertificationInformationLoadState.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      _CertificationInformationLoadState.empty =>
        _CertificationInformationStatus(
          message: widget.emptyMessage,
          onRetry: _load,
        ),
      _CertificationInformationLoadState.error =>
        _CertificationInformationStatus(message: _loadError, onRetry: _load),
      _CertificationInformationLoadState.content => ListView.separated(
        padding: EdgeInsets.fromLTRB(
          ScreenAdapter.width(12),
          ScreenAdapter.height(16),
          ScreenAdapter.width(12),
          ScreenAdapter.height(18),
        ),
        itemCount: _fields.length,
        separatorBuilder: (_, _) => SizedBox(height: ScreenAdapter.height(12)),
        itemBuilder: (context, index) {
          final field = _fields[index];
          return _CertificationInformationFieldView(
            field: field,
            onTap: () => _selectField(field),
            isLoadingAddress: _addressLoadingKey == field.data.saveKey,
            keyPrefix: widget.keyPrefix,
          );
        },
      ),
    };
  }

  Widget _buildFooter() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.personalInformationFooterShadow,
            offset: Offset(0, -5),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            ScreenAdapter.width(16),
            ScreenAdapter.height(14),
            ScreenAdapter.width(16),
            ScreenAdapter.height(14),
          ),
          child: SizedBox(
            height: ScreenAdapter.height(46),
            child: ElevatedButton(
              key: Key('${widget.keyPrefix}Upload'),
              onPressed:
                  _loadState == _CertificationInformationLoadState.content &&
                      !_isSubmitting
                  ? _submit
                  : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                disabledBackgroundColor: AppColors.primary,
                disabledForegroundColor: AppColors.surface,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: ScreenAdapter.width(20),
                      height: ScreenAdapter.height(20),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : Text(
                      'Upload',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: ScreenAdapter.font(16),
                        fontWeight: FontWeight.w500,
                        height: 22 / 16,
                        letterSpacing: 0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loadState = _CertificationInformationLoadState.loading;
        _loadError = '';
      });
    }
    try {
      final data = await widget.load(_productId());
      final fields = data.fields
          .map(_CertificationInformationFieldState.new)
          .toList(growable: false);
      if (!mounted) {
        _disposeFields(fields);
        return;
      }
      setState(() {
        _disposeFields(_fields);
        _fields = fields;
        _prompt = data.prompt.isEmpty ? widget.defaultPrompt : data.prompt;
        _loadState = fields.isEmpty
            ? _CertificationInformationLoadState.empty
            : _CertificationInformationLoadState.content;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _disposeFields(_fields);
        _fields = const [];
        _loadError = ApiErrorMessage.resolve(error);
        _loadState = _CertificationInformationLoadState.error;
      });
    }
  }

  Future<void> _selectField(_CertificationInformationFieldState field) async {
    switch (field.data.control) {
      case PersonalInformationControl.selection:
        if (field.data.options.any((option) => option.children.isNotEmpty)) {
          await _selectPayday(field);
        } else {
          await _selectOption(field);
        }
      case PersonalInformationControl.address:
        await _selectAddress(field);
      case PersonalInformationControl.text:
      case PersonalInformationControl.unsupported:
        return;
    }
  }

  Future<void> _selectOption(_CertificationInformationFieldState field) async {
    final result = await showCertificationSelectionSheet<String>(
      context: context,
      title: field.data.title,
      selectedValue: field.submitValue,
      options: field.data.options
          .map(
            (option) => CertificationSelectionSheetOption(
              label: option.label,
              value: option.value,
              logoUrl: option.logoUrl,
              hint: option.hint,
            ),
          )
          .toList(growable: false),
    );
    if (result == null || !mounted) return;
    setState(() {
      field.submitValue = result.value;
      field.controller.text = result.label;
    });
  }

  Future<void> _selectPayday(_CertificationInformationFieldState field) async {
    final result = await showCertificationPaydaySelectionSheet(
      context: context,
      options: field.data.options,
      initialValue: field.submitValue,
    );
    if (result == null || !mounted) return;
    setState(() {
      field.submitValue = result.submitValue;
      field.controller.text = result.displayText;
    });
  }

  Future<void> _selectAddress(_CertificationInformationFieldState field) async {
    if (_addressLoadingKey != null) return;
    try {
      var nodes = _addressNodes;
      if (nodes == null) {
        setState(() => _addressLoadingKey = field.data.saveKey);
        try {
          nodes = await widget.loadAddresses();
          _addressNodes = nodes;
        } finally {
          if (mounted) setState(() => _addressLoadingKey = null);
        }
      }
      if (!mounted) return;
      if (nodes.isEmpty) {
        await _presentError(field.data.placeholder);
        return;
      }
      final selection = await showCertificationAddressSelectionSheet(
        context: context,
        nodes: nodes,
        initialValue: field.submitValue,
      );
      if (selection == null || !mounted) return;
      setState(() {
        field.submitValue = selection.submitValue;
        field.controller.text = selection.submitValue;
      });
    } catch (error) {
      if (mounted) await _presentError(ApiErrorMessage.resolve(error));
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final productId = _productId();
    if (productId.isEmpty) {
      await _presentError('Product information is unavailable');
      return;
    }
    final payload = <String, String>{};
    for (final field in _fields) {
      final value = field.currentSubmitValue;
      if (field.data.isRequired && value.isEmpty) {
        await _presentError(field.data.placeholder);
        return;
      }
      if (value.isNotEmpty) payload[field.data.saveKey] = value;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.save(productId, payload);
      if (!mounted) return;
      unawaited(
        (widget.reportRisk ?? _defaultReportRisk)(productId, _startedAtSeconds),
      );
      await (widget.continueFlow ?? NavigationHelper.continueProductDetailFlow)(
        productId,
      );
    } catch (error) {
      if (mounted) await _presentError(ApiErrorMessage.resolve(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _productId() {
    final direct = widget.productId.trim();
    if (direct.isNotEmpty) return direct;
    return Json(Get.arguments)['highlands'].stringValue.trim();
  }

  Future<void> _presentError(String message) {
    return (widget.showError ?? EasyLoading.showError)(message);
  }

  Future<void> _defaultReportRisk(String productId, int startedAtSeconds) {
    return DaliReportService.current?.reportRisk(
          productId: productId,
          scene: widget.riskScene,
          startedAtSeconds: startedAtSeconds,
        ) ??
        Future<void>.value();
  }

  static int _nowSeconds() =>
      DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

  void _disposeFields(Iterable<_CertificationInformationFieldState> fields) {
    for (final field in fields) {
      field.controller.dispose();
    }
  }
}

class _CertificationInformationFieldState {
  _CertificationInformationFieldState(this.data)
    : controller = TextEditingController(text: data.initialDisplayValue),
      submitValue = data.initialSubmitValue;

  final PersonalInformationField data;
  final TextEditingController controller;
  String submitValue;

  String get currentSubmitValue =>
      (data.control == PersonalInformationControl.text
              ? controller.text
              : submitValue)
          .trim();
}

class _CertificationInformationHeader extends StatelessWidget {
  const _CertificationInformationHeader({
    required this.title,
    required this.keyPrefix,
    required this.onBack,
  });

  final String title;
  final String keyPrefix;
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
            child: IconButton(
              key: Key('${keyPrefix}Back'),
              onPressed: onBack,
              padding: EdgeInsets.only(left: ScreenAdapter.width(16)),
              alignment: Alignment.centerLeft,
              icon: Image.asset(
                AppAssets.identityBack,
                width: ScreenAdapter.width(18),
                height: ScreenAdapter.height(18),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: ScreenAdapter.font(17),
              fontWeight: FontWeight.w600,
              height: 24 / 17,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificationInformationFieldView extends StatelessWidget {
  const _CertificationInformationFieldView({
    required this.field,
    required this.onTap,
    required this.isLoadingAddress,
    required this.keyPrefix,
  });

  final _CertificationInformationFieldState field;
  final VoidCallback onTap;
  final bool isLoadingAddress;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: ScreenAdapter.font(16),
            fontWeight: FontWeight.w600,
            height: 22 / 16,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: ScreenAdapter.height(8)),
        if (field.data.control == PersonalInformationControl.text)
          SizedBox(
            height: ScreenAdapter.height(48),
            child: TextField(
              key: Key('${keyPrefix}Input_${field.data.saveKey}'),
              controller: field.controller,
              keyboardType: field.data.numericKeyboard
                  ? TextInputType.number
                  : TextInputType.text,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: ScreenAdapter.font(14),
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.personalInformationFieldBackground,
                hintText: field.data.placeholder,
                hintStyle: TextStyle(
                  color: AppColors.personalInformationPlaceholder,
                  fontSize: ScreenAdapter.font(14),
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                  letterSpacing: 0,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ScreenAdapter.width(12),
                  vertical: ScreenAdapter.height(14),
                ),
                border: _fieldBorder(),
                enabledBorder: _fieldBorder(),
                focusedBorder: _fieldBorder(),
              ),
            ),
          )
        else
          Material(
            color: AppColors.personalInformationFieldBackground,
            borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
            child: InkWell(
              key: Key('${keyPrefix}Picker_${field.data.saveKey}'),
              borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
              onTap: onTap,
              child: SizedBox(
                height: ScreenAdapter.height(48),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenAdapter.width(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.controller.text.isEmpty
                              ? field.data.placeholder
                              : field.controller.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: field.controller.text.isEmpty
                                ? AppColors.personalInformationPlaceholder
                                : AppColors.textPrimary,
                            fontSize: ScreenAdapter.font(14),
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      if (isLoadingAddress)
                        SizedBox(
                          key: Key('${keyPrefix}AddressLoading'),
                          width: ScreenAdapter.width(18),
                          height: ScreenAdapter.height(18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          size: ScreenAdapter.width(18),
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
      borderSide: BorderSide.none,
    );
  }
}

class _CertificationInformationStatus extends StatelessWidget {
  const _CertificationInformationStatus({
    required this.message,
    required this.onRetry,
  });

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
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: ScreenAdapter.font(14),
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: ScreenAdapter.height(16)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
