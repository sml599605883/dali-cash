import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/navigation/navigation_helper.dart';
import '../../../app/resources/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/client/client_bridge.dart';
import '../../../core/json/json.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/report/dali_report_service.dart';
import '../widgets/identity_prompt_banner.dart';
import '../widgets/certification_selection_sheet.dart';
import 'bind_card_data.dart';

typedef BindCardLoad = Future<BindCardData> Function(String productId);
typedef BindCardSave =
    Future<ApiResponse> Function(
      String productId,
      String cardType,
      Map<String, String> fields,
      BindCardLivenessPayload liveness,
    );
typedef BindCardMessage = Future<void> Function(String message);
typedef BindCardContinue = Future<void> Function(String productId);
typedef BindCardChangeAccount =
    Future<ApiResponse> Function({
      required String orderNo,
      required String bindId,
    });
typedef BindCardWebViewReplacement =
    Future<void> Function({required String url});
typedef BindCardRiskReport =
    Future<void> Function(String productId, int startedAtSeconds);
typedef BindCardCameraPermissionRequester = Future<PermissionStatus> Function();
typedef BindCardTokenLoad = Future<BindCardLivenessToken> Function();
typedef BindCardLivenessLauncher =
    Future<TrustDecisionLivenessResult> Function(String license);
typedef BindCardTrustDecisionReporter =
    Future<void> Function(TrustDecisionLivenessResult result);
typedef BindCardAppSettingsOpener = Future<bool> Function();

class BindCardLivenessPayload {
  const BindCardLivenessPayload({
    this.type = '',
    this.livenessId = '',
    this.image = '',
    this.businessId = '',
    this.license = '',
  });

  final String type;
  final String livenessId;
  final String image;
  final String businessId;
  final String license;

  bool get isEmpty => type.isEmpty;
}

class BindCardLivenessToken {
  const BindCardLivenessToken({
    required this.code,
    required this.license,
    required this.faceType,
    required this.message,
  });

  factory BindCardLivenessToken.fromResponse(ApiResponse response) {
    return BindCardLivenessToken(
      code: response.states['trihedral'].stringValue.trim(),
      license: response.states['squeezer'].stringValue.trim(),
      faceType: response.states['pileated'].intValue,
      message: response.states['amputating'].stringValue.trim(),
    );
  }

  final String code;
  final String license;
  final int faceType;
  final String message;
}

class BindCardPage extends StatefulWidget {
  const BindCardPage({
    super.key,
    this.productId = '',
    this.orderNo = '',
    this.isAccountChange = false,
    this.load,
    this.save,
    this.showError,
    this.continueFlow,
    this.changeAccount,
    this.replaceWithWebView,
    this.reportRisk,
    this.nowSeconds,
    this.requestCameraPermission,
    this.loadLivenessToken,
    this.showTrustDecisionLiveness,
    this.reportTrustDecisionResult,
    this.openAppSettingsPage,
  });

  final String productId;
  final String orderNo;
  final bool isAccountChange;
  final BindCardLoad? load;
  final BindCardSave? save;
  final BindCardMessage? showError;
  final BindCardContinue? continueFlow;
  final BindCardChangeAccount? changeAccount;
  final BindCardWebViewReplacement? replaceWithWebView;
  final BindCardRiskReport? reportRisk;
  final int Function()? nowSeconds;
  final BindCardCameraPermissionRequester? requestCameraPermission;
  final BindCardTokenLoad? loadLivenessToken;
  final BindCardLivenessLauncher? showTrustDecisionLiveness;
  final BindCardTrustDecisionReporter? reportTrustDecisionResult;
  final BindCardAppSettingsOpener? openAppSettingsPage;

  @override
  State<BindCardPage> createState() => _BindCardPageState();
}

class _BindCardPageState extends State<BindCardPage> {
  final Map<String, _BindCardFieldState> _fieldStates = {};
  final Set<String> _dismissedSuggestionKeys = {};
  late final int _startedAtSeconds;
  BindCardData? _data;
  String _selectedGroupType = '';
  String? _activeSuggestionKey;
  String _loadError = '';
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startedAtSeconds = (widget.nowSeconds ?? DaliReportService.nowSeconds)();
    unawaited(_load());
  }

  @override
  void dispose() {
    _disposeFieldStates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    final busy = _loading || _submitting;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) Navigator.of(context).pop();
      },
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: busy,
            child: Scaffold(
              backgroundColor: AppColors.pageBackground,
              body: GestureDetector(
                key: const Key('bindCardDismissKeyboard'),
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _BindCardHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                      SizedBox(height: ScreenAdapter.height(11)),
                      IdentityPromptBanner(message: _data?.topPrompt ?? ''),
                      SizedBox(height: ScreenAdapter.height(8)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: ScreenAdapter.width(16),
                          ),
                          child: Image.asset(
                            AppAssets.bindCardProgress,
                            key: const Key('bindCardProgress'),
                            width: ScreenAdapter.width(108),
                            height: ScreenAdapter.height(48),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _BindCardFooter(
                hint: _data?.bottomPrompt ?? '',
                submitting: _submitting,
                onUpload: _loading || _data?.groups.isEmpty != false
                    ? null
                    : _submit,
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
          if (_submitting) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError, key: const Key('bindCardLoadError')),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final data = _data;
    if (data == null || data.groups.isEmpty) {
      return const Center(child: Text('No payment methods available'));
    }
    final group = _selectedGroup(data);
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: ScreenAdapter.width(343),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildTabs(data.groups, group.type),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  ScreenAdapter.width(12),
                  ScreenAdapter.height(13),
                  ScreenAdapter.width(12),
                  ScreenAdapter.height(12),
                ),
                child: Column(
                  children: [
                    for (final field in group.fields) ...[
                      _buildField(group, field),
                      SizedBox(height: ScreenAdapter.height(12)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(List<BindCardGroup> groups, String selectedType) {
    return SizedBox(
      height: ScreenAdapter.height(48),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = groups.length <= 3
              ? constraints.maxWidth / groups.length
              : ScreenAdapter.width(110);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final group in groups)
                  GestureDetector(
                    key: Key('bindCardTab_${group.type}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectGroup(group.type),
                    child: SizedBox(
                      width: tabWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                group.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: group.type == selectedType
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: ScreenAdapter.font(
                                    group.type == selectedType ? 16 : 14,
                                  ),
                                  fontWeight: group.type == selectedType
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: ScreenAdapter.width(51),
                            height: ScreenAdapter.height(4),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: group.type == selectedType
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(BindCardGroup group, BindCardField field) {
    final state = _fieldStates[_fieldKey(group, field)]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: ScreenAdapter.font(16),
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: ScreenAdapter.height(8)),
        SizedBox(
          height: ScreenAdapter.height(48),
          child: field.control == BindCardControl.selection
              ? Material(
                  color: AppColors.personalInformationFieldBackground,
                  borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
                  child: InkWell(
                    key: Key('bindCardPicker_${field.saveKey}'),
                    borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
                    onTap: () => _selectOption(state, field),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenAdapter.width(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.controller.text.isEmpty
                                  ? field.placeholder
                                  : state.controller.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: state.controller.text.isEmpty
                                    ? AppColors.personalInformationPlaceholder
                                    : AppColors.textPrimary,
                                fontSize: ScreenAdapter.font(14),
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      key: Key('bindCardInput_${field.saveKey}'),
                      controller: state.controller,
                      focusNode: state.focusNode,
                      keyboardType: field.numericKeyboard
                          ? TextInputType.number
                          : TextInputType.text,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: ScreenAdapter.font(14),
                        letterSpacing: 0,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.personalInformationFieldBackground,
                        hintText: field.placeholder,
                        hintStyle: TextStyle(
                          color: AppColors.personalInformationPlaceholder,
                          fontSize: ScreenAdapter.font(14),
                          letterSpacing: 0,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: ScreenAdapter.width(12),
                        ),
                        border: _inputBorder(),
                        enabledBorder: _inputBorder(),
                        focusedBorder: _inputBorder(),
                      ),
                    ),
                    if (_activeSuggestionKey == _fieldKey(group, field))
                      Positioned(
                        right: ScreenAdapter.width(8),
                        child: _BindCardSuggestion(
                          field: field,
                          onApply: () => _applySuggestions(group),
                          onClose: () => _dismissSuggestion(group, field),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  InputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
      borderSide: BorderSide.none,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = '';
    });
    try {
      final data = await (widget.load ?? _defaultLoad)(_productId);
      if (!mounted) return;
      _disposeFieldStates();
      for (final group in data.groups) {
        for (final field in group.fields) {
          final state = _BindCardFieldState(field);
          if (field.control == BindCardControl.text) {
            state.controller.addListener(_updateActiveSuggestion);
            state.focusNode.addListener(_updateActiveSuggestion);
          }
          _fieldStates[_fieldKey(group, field)] = state;
        }
      }
      setState(() {
        _data = data;
        _selectedGroupType = data.groups.isEmpty ? '' : data.groups.first.type;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message = ApiErrorMessage.resolve(error);
      setState(() {
        _loadError = message;
        _loading = false;
      });
      await _showError(message);
    }
  }

  Future<void> _selectOption(
    _BindCardFieldState state,
    BindCardField field,
  ) async {
    final selected = await showCertificationSelectionSheet<String>(
      context: context,
      title: field.title,
      selectedValue: state.submitValue,
      options: field.options
          .map(
            (option) => CertificationSelectionSheetOption<String>(
              label: option.label,
              value: option.value,
              logoUrl: option.logoUrl,
              hint: option.available ? '' : option.maintenanceText,
            ),
          )
          .toList(growable: false),
    );
    if (selected == null || !mounted) return;
    setState(() {
      state.submitValue = selected.value;
      state.controller.text = selected.label;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final data = _data;
    if (data == null || data.groups.isEmpty) return;
    final group = _selectedGroup(data);
    final fields = <String, String>{};
    for (final field in group.fields) {
      final state = _fieldStates[_fieldKey(group, field)]!;
      final value = field.control == BindCardControl.selection
          ? state.submitValue.trim()
          : state.controller.text.trim();
      fields[field.saveKey] = value;
      if (field.required && value.isEmpty) {
        await _showError(
          '${field.control == BindCardControl.selection ? 'Please select' : 'Please enter'} ${field.title.toLowerCase()}',
        );
        return;
      }
    }
    final account = fields['whops'];
    final confirmation = fields['shallowly'];
    if (account != null && confirmation != null && account != confirmation) {
      await _showError('Account numbers do not match');
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await _save(
        group.type,
        fields,
        const BindCardLivenessPayload(),
      );
      if (!mounted) return;
      if (response.code == 20000) {
        await _completeLiveness(group.type, fields);
      } else {
        await _completeSuccess(response);
      }
    } catch (error) {
      if (mounted) await _showError(ApiErrorMessage.resolve(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _completeLiveness(
    String groupType,
    Map<String, String> fields,
  ) async {
    final permission =
        await (widget.requestCameraPermission ??
            _defaultRequestCameraPermission)();
    if (!mounted) return;
    if (!permission.isGranted) {
      await _showCameraPermissionDialog();
      return;
    }
    final token = await (widget.loadLivenessToken ?? _defaultLoadToken)();
    if (token.code != '200' || token.license.isEmpty) {
      await _showError(
        token.message.isEmpty ? 'Failed to get face token' : token.message,
      );
      return;
    }
    if (token.faceType != 7) {
      await _showError('Unsupported liveness verification type');
      return;
    }
    final result =
        await (widget.showTrustDecisionLiveness ??
            _defaultShowTrustDecisionLiveness)(token.license);
    unawaited(
      (widget.reportTrustDecisionResult ??
          (value) =>
              DaliReportService.current?.reportTrustDecisionResult(value) ??
              Future<void>.value())(result),
    );
    if (!mounted) return;
    if (!result.success || result.livenessId.trim().isEmpty) {
      await _showError(
        result.message.trim().isEmpty
            ? 'Liveness verification failed'
            : result.message.trim(),
      );
      return;
    }
    final response = await _save(
      groupType,
      fields,
      BindCardLivenessPayload(
        type: '7',
        livenessId: result.livenessId.trim(),
        license: token.license,
      ),
    );
    if (!mounted) return;
    if (response.code == 20000) {
      await _showError('Liveness verification was not accepted');
      return;
    }
    await _completeSuccess(response);
  }

  Future<void> _completeSuccess(ApiResponse response) async {
    if (_isAccountChange) {
      final orderNo = _orderNo;
      if (orderNo.isEmpty) {
        await _showError('Missing order information');
        return;
      }
      final bindId = response.states['hoover'].stringValue.trim();
      if (bindId.isEmpty) {
        await _showError('Missing binding information');
        return;
      }
      final changed = await (widget.changeAccount ?? _defaultChangeAccount)(
        orderNo: orderNo,
        bindId: bindId,
      );
      final url = changed
          .ensureSuccess()
          .states['misericorde']
          .stringValue
          .trim();
      if (url.isEmpty) {
        await _showError('Missing account change result url');
        return;
      }
      if (NavigationHelper.webViewUri(url) == null) {
        await _showError('Invalid account change result url');
        return;
      }
      await (widget.replaceWithWebView ?? _defaultReplaceWithWebView)(url: url);
      return;
    }
    unawaited(
      (widget.reportRisk ?? _defaultReportRisk)(_productId, _startedAtSeconds),
    );
    await (widget.continueFlow ?? NavigationHelper.continueProductDetailFlow)(
      _productId,
    );
  }

  Future<void> _showCameraPermissionDialog() {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Allow Camera Access'),
        content: const Text(
          "We can't complete identity verification without camera access. Enable the permission to continue your application securely.",
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await (widget.openAppSettingsPage ?? openAppSettings)();
            },
            isDefaultAction: true,
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  BindCardGroup _selectedGroup(BindCardData data) {
    for (final group in data.groups) {
      if (group.type == _selectedGroupType) return group;
    }
    return data.groups.first;
  }

  void _updateActiveSuggestion() {
    if (!mounted) return;
    final data = _data;
    if (data == null || data.groups.isEmpty) return;

    for (final group in data.groups) {
      for (final field in group.fields) {
        if (field.control != BindCardControl.text) continue;
        final key = _fieldKey(group, field);
        if (_fieldStates[key]?.controller.text.trim().isNotEmpty == true) {
          _dismissedSuggestionKeys.remove(key);
        }
      }
    }

    String? nextKey;
    final group = _selectedGroup(data);
    for (final field in group.fields) {
      if (field.control != BindCardControl.text) continue;
      final key = _fieldKey(group, field);
      final state = _fieldStates[key];
      if (state?.focusNode.hasFocus != true ||
          state!.controller.text.trim().isNotEmpty ||
          field.suggestedValue.isEmpty ||
          _dismissedSuggestionKeys.contains(key)) {
        continue;
      }
      nextKey = key;
      break;
    }
    if (_activeSuggestionKey != nextKey) {
      setState(() => _activeSuggestionKey = nextKey);
    }
  }

  void _dismissSuggestion(BindCardGroup group, BindCardField field) {
    final key = _fieldKey(group, field);
    setState(() {
      _dismissedSuggestionKeys.add(key);
      _activeSuggestionKey = null;
    });
  }

  void _applySuggestions(BindCardGroup group) {
    FocusManager.instance.primaryFocus?.unfocus();
    for (final field in group.fields) {
      if (field.control != BindCardControl.text) continue;
      final state = _fieldStates[_fieldKey(group, field)]!;
      final suggestion = field.suggestedValue.trim();
      if (state.controller.text.trim().isEmpty && suggestion.isNotEmpty) {
        state.controller.text = suggestion;
      }
    }
    if (mounted) setState(() => _activeSuggestionKey = null);
  }

  void _selectGroup(String groupType) {
    if (_selectedGroupType == groupType) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedGroupType = groupType;
      _activeSuggestionKey = null;
    });
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

  bool get _isAccountChange {
    if (widget.isAccountChange) return true;
    return Json(Get.arguments)['isAccountChange'].boolValue;
  }

  String _fieldKey(BindCardGroup group, BindCardField field) {
    return '${group.type}:${field.saveKey}';
  }

  Future<BindCardData> _defaultLoad(String productId) async {
    final response = await Get.find<ApiClient>().cardInit(productId: productId);
    return BindCardData.fromJson(response.states);
  }

  Future<ApiResponse> _save(
    String groupType,
    Map<String, String> fields,
    BindCardLivenessPayload liveness,
  ) {
    if (widget.save != null) {
      return widget.save!(_productId, groupType, fields, liveness);
    }
    return Get.find<ApiClient>().bindCard(
      productId: _productId,
      cardType: groupType,
      fields: fields,
      livenessType: liveness.type,
      livenessId: liveness.livenessId,
      image: liveness.image,
      businessId: liveness.businessId,
      license: liveness.license,
    );
  }

  Future<ApiResponse> _defaultChangeAccount({
    required String orderNo,
    required String bindId,
  }) {
    return Get.find<ApiClient>().changeOrderAccount(
      orderNo: orderNo,
      bindId: bindId,
    );
  }

  Future<void> _defaultReplaceWithWebView({required String url}) {
    NavigationHelper.replaceAccountChangeFlowWithWebView<void>(url: url);
    return Future<void>.value();
  }

  Future<BindCardLivenessToken> _defaultLoadToken() async {
    final client = Get.find<ApiClient>();
    final orderNo = client.config.sessionStore.productDetailOrderNo().trim();
    if (orderNo.isEmpty) {
      throw ApiBusinessException(
        'Missing order information for liveness verification',
      );
    }
    final response = await client.getFaceIdToken(orderNo: orderNo, type: '1');
    return BindCardLivenessToken.fromResponse(response);
  }

  Future<void> _showError(String message) {
    return (widget.showError ?? EasyLoading.showError)(message);
  }

  Future<void> _defaultReportRisk(String productId, int startedAtSeconds) {
    return DaliReportService.current?.reportRisk(
          productId: productId,
          scene: '8',
          startedAtSeconds: startedAtSeconds,
        ) ??
        Future<void>.value();
  }

  Future<PermissionStatus> _defaultRequestCameraPermission() {
    return Permission.camera.request();
  }

  Future<TrustDecisionLivenessResult> _defaultShowTrustDecisionLiveness(
    String license,
  ) {
    return ClientBridge().showTrustDecisionLiveness(license);
  }

  void _disposeFieldStates() {
    for (final state in _fieldStates.values) {
      state.controller.removeListener(_updateActiveSuggestion);
      state.focusNode.removeListener(_updateActiveSuggestion);
      state.dispose();
    }
    _fieldStates.clear();
    _dismissedSuggestionKeys.clear();
    _activeSuggestionKey = null;
  }
}

class _BindCardFieldState {
  _BindCardFieldState(BindCardField field)
    : controller = TextEditingController(text: field.initialDisplayValue),
      submitValue = field.initialSubmitValue;

  final TextEditingController controller;
  final FocusNode focusNode = FocusNode();
  String submitValue;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _BindCardSuggestion extends StatelessWidget {
  const _BindCardSuggestion({
    required this.field,
    required this.onApply,
    required this.onClose,
  });

  final BindCardField field;
  final VoidCallback onApply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ScreenAdapter.width(160)),
      child: GestureDetector(
        key: Key('bindCardSuggestion_${field.saveKey}'),
        behavior: HitTestBehavior.opaque,
        onTap: onApply,
        child: DecoratedBox(
          key: Key('bindCardSuggestionBackground_${field.saveKey}'),
          decoration: BoxDecoration(
            color: AppColors.bindCardSuggestionBackground,
            borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ScreenAdapter.width(3),
              ScreenAdapter.height(3),
              ScreenAdapter.width(4),
              ScreenAdapter.height(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    field.suggestedValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: ScreenAdapter.font(12),
                      height: 14 / 12,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                GestureDetector(
                  key: Key('bindCardSuggestionClose_${field.saveKey}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: SizedBox(
                    width: ScreenAdapter.width(18),
                    height: ScreenAdapter.height(18),
                    child: Center(
                      child: Image.asset(
                        AppAssets.bindCardSuggestionClose,
                        width: ScreenAdapter.width(10),
                        height: ScreenAdapter.height(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BindCardHeader extends StatelessWidget {
  const _BindCardHeader({required this.onBack});

  final VoidCallback onBack;

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
              key: const Key('bindCardBack'),
              onPressed: onBack,
              padding: EdgeInsets.only(left: ScreenAdapter.width(16)),
              alignment: Alignment.centerLeft,
              icon: Image.asset(
                AppAssets.identityBack,
                width: ScreenAdapter.width(24),
                height: ScreenAdapter.height(24),
              ),
            ),
          ),
          Text(
            'Account management',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: ScreenAdapter.font(17),
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _BindCardFooter extends StatelessWidget {
  const _BindCardFooter({
    required this.hint,
    required this.submitting,
    required this.onUpload,
  });

  final String hint;
  final bool submitting;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.all(ScreenAdapter.width(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hint.isNotEmpty) ...[
                Text(
                  hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: ScreenAdapter.font(12),
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: ScreenAdapter.height(8)),
              ],
              SizedBox(
                width: double.infinity,
                height: ScreenAdapter.height(46),
                child: ElevatedButton(
                  key: const Key('bindCardUpload'),
                  onPressed: submitting ? null : onUpload,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.primary,
                    disabledForegroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ScreenAdapter.width(8),
                      ),
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
                          'Upload',
                          style: TextStyle(
                            fontSize: ScreenAdapter.font(16),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
