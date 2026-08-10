import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:get/get.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/navigation/navigation_helper.dart';
import '../../../app/resources/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/json/json.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/report/dali_report_service.dart';
import '../widgets/certification_selection_sheet.dart';
import '../widgets/identity_prompt_banner.dart';
import '../widgets/certification_retention_guard.dart';
import 'emergency_contact_data.dart';

typedef EmergencyContactLoad =
    Future<EmergencyContactData> Function(String productId);
typedef EmergencyContactSave =
    Future<void> Function(String productId, List<Map<String, String>> contacts);
typedef EmergencyContactMessage = Future<void> Function(String message);
typedef EmergencyContactContinue = Future<void> Function(String productId);
typedef EmergencyContactRiskReport =
    Future<void> Function(String productId, int startedAtSeconds);
typedef EmergencyContactPick = Future<EmergencyPickedContact?> Function();

class EmergencyPickedContact {
  const EmergencyPickedContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

class EmergencyContactPage extends StatefulWidget {
  const EmergencyContactPage({
    super.key,
    this.productId = '',
    this.load,
    this.save,
    this.pickContact,
    this.showError,
    this.continueFlow,
    this.reportRisk,
    this.nowSeconds,
  });

  final String productId;
  final EmergencyContactLoad? load;
  final EmergencyContactSave? save;
  final EmergencyContactPick? pickContact;
  final EmergencyContactMessage? showError;
  final EmergencyContactContinue? continueFlow;
  final EmergencyContactRiskReport? reportRisk;
  final int Function()? nowSeconds;

  @override
  State<EmergencyContactPage> createState() => _EmergencyContactPageState();
}

enum _LoadState { loading, content, empty, error }

class _EmergencyContactPageState extends State<EmergencyContactPage> {
  static const _defaultPrompt =
      'Please provide your emergency contact information for identity verification.';

  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  _LoadState _loadState = _LoadState.loading;
  List<_ContactEntry> _contacts = const [];
  String _prompt = _defaultPrompt;
  String _loadError = '';
  bool _isSubmitting = false;
  late final int _startedAtSeconds;

  @override
  void initState() {
    super.initState();
    _startedAtSeconds = (widget.nowSeconds ?? _nowSeconds)();
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    final busy = _loadState == _LoadState.loading || _isSubmitting;
    final onBack = CertificationRetentionGuard.backHandler(
      type: '4',
      productId: _productId(),
      onDefaultBack: NavigationHelper.back,
    );
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
                      _Header(onBack: onBack),
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
                            AppAssets.emergencyContactProgress,
                            key: const Key('emergencyContactProgress'),
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
            if (_isSubmitting) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ScreenAdapter.width(16),
        0,
        ScreenAdapter.width(16),
        ScreenAdapter.height(8),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
          child: switch (_loadState) {
            _LoadState.loading => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            _LoadState.empty => _Status(
              message: 'No emergency contacts available',
              onRetry: _load,
            ),
            _LoadState.error => _Status(message: _loadError, onRetry: _load),
            _LoadState.content => ListView.separated(
              padding: EdgeInsets.fromLTRB(
                ScreenAdapter.width(12),
                ScreenAdapter.height(16),
                ScreenAdapter.width(12),
                ScreenAdapter.height(18),
              ),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return _ContactGroupView(
                  index: index,
                  contact: contact,
                  onRelationshipTap: () => _selectRelationship(contact),
                  onContactTap: () => _selectContact(contact),
                );
              },
              separatorBuilder: (_, _) =>
                  SizedBox(height: ScreenAdapter.height(16)),
            ),
          },
        ),
      ),
    );
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
          padding: EdgeInsets.all(ScreenAdapter.width(16)),
          child: SizedBox(
            height: ScreenAdapter.height(46),
            child: ElevatedButton(
              key: const Key('emergencyContactUpload'),
              onPressed: _loadState == _LoadState.content && !_isSubmitting
                  ? _submit
                  : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                disabledBackgroundColor: AppColors.primary,
                disabledForegroundColor: AppColors.surface,
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
                        fontSize: ScreenAdapter.font(16),
                        fontWeight: FontWeight.w500,
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
    setState(() {
      _loadState = _LoadState.loading;
      _loadError = '';
    });
    try {
      final data = await (widget.load ?? _defaultLoad)(_productId());
      final contacts = data.contacts.map(_ContactEntry.new).toList();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _prompt = data.prompt.isEmpty ? _defaultPrompt : data.prompt;
        _loadState = contacts.isEmpty ? _LoadState.empty : _LoadState.content;
      });
    } catch (error) {
      if (!mounted) return;
      final message = ApiErrorMessage.resolve(error);
      setState(() {
        _contacts = const [];
        _loadError = message;
        _loadState = _LoadState.error;
      });
      await _showError(message);
    }
  }

  Future<void> _selectRelationship(_ContactEntry contact) async {
    final selected = await showCertificationSelectionSheet<String>(
      context: context,
      title: 'Relationship',
      selectedValue: contact.relationshipValue,
      options: contact.data.relationshipOptions
          .map(
            (option) => CertificationSelectionSheetOption(
              label: option.label,
              value: option.value,
            ),
          )
          .toList(growable: false),
    );
    if (selected == null || !mounted) return;
    setState(() {
      contact.relationshipValue = selected.value;
      contact.relationshipLabel = selected.label;
    });
  }

  Future<void> _selectContact(_ContactEntry contact) async {
    try {
      final selected = await (widget.pickContact ?? _pickNativeContact)();
      if (selected == null || !mounted) return;
      setState(() {
        contact.name = selected.name.trim();
        contact.phone = selected.phone.trim();
      });
    } catch (error) {
      if (mounted) await _showError(ApiErrorMessage.resolve(error));
    }
  }

  Future<EmergencyPickedContact?> _pickNativeContact() async {
    final contact = await _contactPicker.selectContact();
    if (contact == null) return null;
    return EmergencyPickedContact(
      name: (contact.fullName ?? '').trim(),
      phone: _primaryPhone(contact),
    );
  }

  String _primaryPhone(Contact contact) {
    final selected = (contact.selectedPhoneNumber ?? '').trim();
    if (selected.isNotEmpty) return selected;
    for (final phone in contact.phoneNumbers ?? const <String>[]) {
      if (phone.trim().isNotEmpty) return phone.trim();
    }
    return '';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final productId = _productId();
    if (productId.isEmpty) {
      await _showError('Product information is unavailable');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await (widget.save ?? _defaultSave)(
        productId,
        _contacts.map((contact) => contact.toJson()).toList(growable: false),
      );
      if (!mounted) return;
      unawaited(
        (widget.reportRisk ?? _defaultReportRisk)(productId, _startedAtSeconds),
      );
      await (widget.continueFlow ?? NavigationHelper.continueProductDetailFlow)(
        productId,
      );
    } catch (error) {
      if (mounted) await _showError(ApiErrorMessage.resolve(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _productId() {
    final direct = widget.productId.trim();
    if (direct.isNotEmpty) return direct;
    return Json(Get.arguments)['highlands'].stringValue.trim();
  }

  Future<EmergencyContactData> _defaultLoad(String productId) async {
    final response = await Get.find<ApiClient>().extInfoV2(
      productId: productId,
    );
    return EmergencyContactData.fromJson(response.states);
  }

  Future<void> _defaultSave(
    String productId,
    List<Map<String, String>> contacts,
  ) async {
    await Get.find<ApiClient>().saveExtInfoV2(
      productId: productId,
      contacts: contacts,
    );
  }

  Future<void> _showError(String message) {
    return (widget.showError ?? EasyLoading.showError)(message);
  }

  Future<void> _defaultReportRisk(String productId, int startedAtSeconds) {
    return DaliReportService.current?.reportRisk(
          productId: productId,
          scene: '7',
          startedAtSeconds: startedAtSeconds,
        ) ??
        Future<void>.value();
  }

  static int _nowSeconds() =>
      DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
}

class _ContactEntry {
  _ContactEntry(this.data)
    : relationshipValue = data.relationshipValue,
      relationshipLabel = data.relationshipLabel,
      name = data.name,
      phone = data.phone;

  final EmergencyContact data;
  String relationshipValue;
  String relationshipLabel;
  String name;
  String phone;

  Map<String, String> toJson() {
    return {
      'poet': phone.trim(),
      'crocidolites': name.trim(),
      'roebuck': relationshipValue.trim(),
      'attractances': data.number,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

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
              key: const Key('emergencyContactBack'),
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
            'Urgent contact person',
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

class _ContactGroupView extends StatelessWidget {
  const _ContactGroupView({
    required this.index,
    required this.contact,
    required this.onRelationshipTap,
    required this.onContactTap,
  });

  final int index;
  final _ContactEntry contact;
  final VoidCallback onRelationshipTap;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Relationship with Emergency Contacts - ${index + 1}',
              key: Key('emergencyContactGroupTitle_${contact.data.number}'),
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: AppColors.dialogText,
                fontSize: ScreenAdapter.font(16),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        SizedBox(height: ScreenAdapter.height(index == 0 ? 16 : 24)),
        _Label('Relationship'),
        SizedBox(height: ScreenAdapter.height(8)),
        _FieldBox(
          key: Key('emergencyContactRelationship_${contact.data.number}'),
          onTap: onRelationshipTap,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  contact.relationshipLabel.isEmpty
                      ? 'Please select'
                      : contact.relationshipLabel,
                  style: _valueStyle(
                    placeholder: contact.relationshipLabel.isEmpty,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: ScreenAdapter.width(18),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        SizedBox(height: ScreenAdapter.height(12)),
        _Label('Contact Information'),
        SizedBox(height: ScreenAdapter.height(8)),
        _FieldBox(
          key: Key('emergencyContactPicker_${contact.data.number}'),
          onTap: onContactTap,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  contact.name.isEmpty ? 'Please select contact' : contact.name,
                  style: _valueStyle(placeholder: contact.name.isEmpty),
                ),
              ),
              Image.asset(
                AppAssets.emergencyContactPicker,
                width: ScreenAdapter.width(20),
                height: ScreenAdapter.height(20),
              ),
            ],
          ),
        ),
        SizedBox(height: ScreenAdapter.height(12)),
        _Label('telephone number'),
        SizedBox(height: ScreenAdapter.height(8)),
        _FieldBox(
          key: Key('emergencyContactPhone_${contact.data.number}'),
          onTap: onContactTap,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              contact.phone.isEmpty ? 'Please select contact' : contact.phone,
              style: _valueStyle(placeholder: contact.phone.isEmpty),
            ),
          ),
        ),
      ],
    );
  }

  static TextStyle _valueStyle({bool placeholder = false}) {
    return TextStyle(
      color: placeholder
          ? AppColors.personalInformationPlaceholder
          : AppColors.textPrimary,
      fontSize: ScreenAdapter.font(14),
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: ScreenAdapter.font(16),
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.personalInformationFieldBackground,
      borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
        child: SizedBox(
          height: ScreenAdapter.height(48),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ScreenAdapter.width(12)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: ScreenAdapter.font(14),
            ),
          ),
          SizedBox(height: ScreenAdapter.height(12)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
