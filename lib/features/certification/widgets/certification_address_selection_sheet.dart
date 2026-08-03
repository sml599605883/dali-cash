import 'package:flutter/material.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/resources/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../personal_information/personal_information_data.dart';

enum AddressLevel { region, province, municipality }

class PersonalAddressSelection {
  const PersonalAddressSelection({
    required this.region,
    required this.province,
    required this.municipality,
  });

  final PersonalAddressNode region;
  final PersonalAddressNode province;
  final PersonalAddressNode municipality;

  String get submitValue =>
      '${region.label}-${province.label}-${municipality.label}';
}

Future<PersonalAddressSelection?> showCertificationAddressSelectionSheet({
  required BuildContext context,
  required List<PersonalAddressNode> nodes,
  String initialValue = '',
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<PersonalAddressSelection>(
    context: context,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.dialogBarrier,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ScreenAdapter.width(16)),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => CertificationAddressSelectionSheet(
      nodes: nodes,
      initialValue: initialValue,
    ),
  );
}

class CertificationAddressSelectionSheet extends StatefulWidget {
  const CertificationAddressSelectionSheet({
    super.key,
    required this.nodes,
    this.initialValue = '',
  });

  final List<PersonalAddressNode> nodes;
  final String initialValue;

  @override
  State<CertificationAddressSelectionSheet> createState() =>
      _CertificationAddressSelectionSheetState();
}

class _CertificationAddressSelectionSheetState
    extends State<CertificationAddressSelectionSheet> {
  PersonalAddressNode? _region;
  PersonalAddressNode? _province;
  PersonalAddressNode? _municipality;
  AddressLevel _activeLevel = AddressLevel.region;

  @override
  void initState() {
    super.initState();
    _restoreInitialValue();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('addressSelectionSheet'),
      width: double.infinity,
      height: ScreenAdapter.height(464),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned(
              top: ScreenAdapter.height(45),
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                AppAssets.addressPickerOptionsBackground,
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              top: ScreenAdapter.height(21),
              right: ScreenAdapter.width(15),
              child: GestureDetector(
                key: const Key('addressPickerClose'),
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Image.asset(
                  AppAssets.addressPickerClose,
                  width: ScreenAdapter.width(24),
                  height: ScreenAdapter.height(24),
                ),
              ),
            ),
            Positioned(
              top: ScreenAdapter.height(56),
              left: ScreenAdapter.width(12),
              right: ScreenAdapter.width(12),
              child: _AddressProgressPanel(
                activeLevel: _activeLevel,
                regionLabel: _region?.label ?? 'Region',
                provinceLabel: _province?.label ?? 'Province',
                municipalityLabel: _municipality?.label ?? 'Municipality',
                regionEnabled: true,
                provinceEnabled: _region != null,
                municipalityEnabled: _province != null,
                onLevelSelected: _selectLevel,
              ),
            ),
            Positioned(
              top: ScreenAdapter.height(201),
              left: 0,
              right: 0,
              bottom: 0,
              child: _AddressOptions(
                key: ValueKey('$_activeLevel-${_selectedNode?.id ?? ''}'),
                level: _activeLevel,
                options: _activeOptions,
                selectedNode: _selectedNode,
                onSelected: _selectNode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PersonalAddressNode> get _activeOptions {
    return switch (_activeLevel) {
      AddressLevel.region => widget.nodes,
      AddressLevel.province => _region?.children ?? const [],
      AddressLevel.municipality => _province?.children ?? const [],
    };
  }

  PersonalAddressNode? get _selectedNode {
    return switch (_activeLevel) {
      AddressLevel.region => _region,
      AddressLevel.province => _province,
      AddressLevel.municipality => _municipality,
    };
  }

  void _restoreInitialValue() {
    final labels = widget.initialValue
        .split('-')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (labels.isEmpty) return;

    _region = _findByLabel(widget.nodes, labels.first);
    if (_region == null || labels.length == 1) {
      _activeLevel = _region == null
          ? AddressLevel.region
          : AddressLevel.province;
      return;
    }
    _province = _findByLabel(_region!.children, labels[1]);
    if (_province == null || labels.length == 2) {
      _activeLevel = _province == null
          ? AddressLevel.province
          : AddressLevel.municipality;
      return;
    }
    _municipality = _findByLabel(_province!.children, labels[2]);
    _activeLevel = AddressLevel.municipality;
  }

  PersonalAddressNode? _findByLabel(
    List<PersonalAddressNode> nodes,
    String label,
  ) {
    for (final node in nodes) {
      if (node.label == label) return node;
    }
    return null;
  }

  void _selectLevel(AddressLevel level) {
    if (level == AddressLevel.province && _region == null) return;
    if (level == AddressLevel.municipality && _province == null) return;
    setState(() {
      _activeLevel = level;
      switch (level) {
        case AddressLevel.region:
          _province = null;
          _municipality = null;
        case AddressLevel.province:
          _municipality = null;
        case AddressLevel.municipality:
          break;
      }
    });
  }

  void _selectNode(PersonalAddressNode value) {
    switch (_activeLevel) {
      case AddressLevel.region:
        setState(() {
          _region = value;
          _province = null;
          _municipality = null;
          _activeLevel = AddressLevel.province;
        });
      case AddressLevel.province:
        setState(() {
          _province = value;
          _municipality = null;
          _activeLevel = AddressLevel.municipality;
        });
      case AddressLevel.municipality:
        final region = _region;
        final province = _province;
        if (region == null || province == null) return;
        Navigator.of(context).pop(
          PersonalAddressSelection(
            region: region,
            province: province,
            municipality: value,
          ),
        );
    }
  }
}

class _AddressProgressPanel extends StatelessWidget {
  const _AddressProgressPanel({
    required this.activeLevel,
    required this.regionLabel,
    required this.provinceLabel,
    required this.municipalityLabel,
    required this.regionEnabled,
    required this.provinceEnabled,
    required this.municipalityEnabled,
    required this.onLevelSelected,
  });

  final AddressLevel activeLevel;
  final String regionLabel;
  final String provinceLabel;
  final String municipalityLabel;
  final bool regionEnabled;
  final bool provinceEnabled;
  final bool municipalityEnabled;
  final ValueChanged<AddressLevel> onLevelSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(121),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.addressPickerPanel,
          borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
        ),
        child: Stack(
          children: [
            _connector(
              key: 'regionProvince',
              targetLevel: AddressLevel.province,
              top: 21,
              height: 39,
            ),
            _connector(
              key: 'provinceMunicipality',
              targetLevel: AddressLevel.municipality,
              top: 60,
              height: 41,
            ),
            _indicator(AddressLevel.region, 17),
            _indicator(AddressLevel.province, 56),
            _indicator(AddressLevel.municipality, 97),
            _step(
              level: AddressLevel.region,
              label: regionLabel,
              top: 9,
              enabled: regionEnabled,
            ),
            _step(
              level: AddressLevel.province,
              label: provinceLabel,
              top: 48,
              enabled: provinceEnabled,
            ),
            _step(
              level: AddressLevel.municipality,
              label: municipalityLabel,
              top: 89,
              enabled: municipalityEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _connector({
    required String key,
    required AddressLevel targetLevel,
    required double top,
    required double height,
  }) {
    final reached = targetLevel.index <= activeLevel.index;
    return Positioned(
      top: ScreenAdapter.height(top),
      left: ScreenAdapter.width(24),
      width: ScreenAdapter.width(2),
      height: ScreenAdapter.height(height),
      child: ColoredBox(
        key: Key('addressStepLine_$key'),
        color: reached ? AppColors.primary : AppColors.surface,
      ),
    );
  }

  Widget _indicator(AddressLevel level, double top) {
    final reached = level.index <= activeLevel.index;
    return Positioned(
      top: ScreenAdapter.height(top),
      left: ScreenAdapter.width(21),
      width: ScreenAdapter.width(8),
      height: ScreenAdapter.height(8),
      child: DecoratedBox(
        key: Key('addressStepIndicator_${level.name}'),
        decoration: BoxDecoration(
          color: reached ? AppColors.primary : AppColors.surface,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _step({
    required AddressLevel level,
    required String label,
    required double top,
    required bool enabled,
  }) {
    final selected = activeLevel == level;
    return Positioned(
      top: ScreenAdapter.height(top),
      left: ScreenAdapter.width(74),
      right: ScreenAdapter.width(20),
      height: ScreenAdapter.height(24),
      child: InkWell(
        key: Key('addressStep_${level.name}'),
        onTap: enabled ? () => onLevelSelected(level) : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                key: Key('addressStepLabel_${level.name}'),
                style: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.addressPickerLabel,
                  fontSize: ScreenAdapter.font(14),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  height: 18 / 14,
                  letterSpacing: 0,
                ),
              ),
            ),
            Image.asset(
              AppAssets.addressPickerChevron,
              width: ScreenAdapter.width(13),
              height: ScreenAdapter.height(13),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressOptions extends StatefulWidget {
  const _AddressOptions({
    super.key,
    required this.level,
    required this.options,
    required this.selectedNode,
    required this.onSelected,
  });

  final AddressLevel level;
  final List<PersonalAddressNode> options;
  final PersonalAddressNode? selectedNode;
  final ValueChanged<PersonalAddressNode> onSelected;

  @override
  State<_AddressOptions> createState() => _AddressOptionsState();
}

class _AddressOptionsState extends State<_AddressOptions> {
  late int _selectedIndex;
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _initialIndex();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) {
      return SizedBox(
        key: Key('addressOptions_${widget.level.name}'),
        child: Center(
          child: Text(
            'No ${_levelLabel(widget.level)} available',
            style: TextStyle(
              color: AppColors.identityPickerMuted,
              fontSize: ScreenAdapter.font(18),
              letterSpacing: 0,
            ),
          ),
        ),
      );
    }

    return ListWheelScrollView.useDelegate(
      key: Key('addressOptions_${widget.level.name}'),
      controller: _controller,
      itemExtent: ScreenAdapter.height(52),
      diameterRatio: 1000,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => setState(() => _selectedIndex = index),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.options.length,
        builder: (context, index) {
          final option = widget.options[index];
          final distance = (index - _selectedIndex).abs();
          final selected = distance == 0;
          return InkWell(
            key: selected ? Key('addressOptionSelected_${option.label}') : null,
            onTap: () => widget.onSelected(option),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: selected
                    ? const Border.symmetric(
                        horizontal: BorderSide(
                          color: AppColors.identityPickerDivider,
                        ),
                      )
                    : null,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenAdapter.width(24),
                  ),
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? AppColors.addressPickerSelected
                          : distance == 1
                          ? AppColors.identityPickerText
                          : AppColors.identityPickerMuted,
                      fontSize: ScreenAdapter.font(18),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      height: 20 / 18,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _initialIndex() {
    final selected = widget.selectedNode;
    if (selected == null) return 0;
    final index = widget.options.indexWhere((item) => item.id == selected.id);
    return index < 0 ? 0 : index;
  }

  String _levelLabel(AddressLevel level) {
    return switch (level) {
      AddressLevel.region => 'Region',
      AddressLevel.province => 'Province',
      AddressLevel.municipality => 'Municipality',
    };
  }
}
