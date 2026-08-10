import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/resources/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../personal_information/personal_information_data.dart';

class CertificationPaydaySelection {
  const CertificationPaydaySelection({
    required this.parent,
    required this.child,
  });

  final PersonalInformationOption parent;
  final PersonalInformationOption child;

  String get displayText => '${parent.label}|${child.label}';

  String get submitValue => child.value;
}

Future<CertificationPaydaySelection?> showCertificationPaydaySelectionSheet({
  required BuildContext context,
  required List<PersonalInformationOption> options,
  String initialValue = '',
}) {
  if (options.isEmpty) return Future.value(null);
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<CertificationPaydaySelection>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.dialogBarrier,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => _CertificationPaydaySelectionSheet(
      options: options,
      initialValue: initialValue,
    ),
  );
}

class _CertificationPaydaySelectionSheet extends StatefulWidget {
  const _CertificationPaydaySelectionSheet({
    required this.options,
    required this.initialValue,
  });

  final List<PersonalInformationOption> options;
  final String initialValue;

  @override
  State<_CertificationPaydaySelectionSheet> createState() =>
      _CertificationPaydaySelectionSheetState();
}

class _CertificationPaydaySelectionSheetState
    extends State<_CertificationPaydaySelectionSheet> {
  static const _rowHeight = 58.0;
  static const _doneHeight = 58.0;
  static const _maximumVisibleRows = 5;

  late int _parentIndex = _initialParentIndex();
  late PersonalInformationOption? _selectedChild = _initialSelectedChild();
  bool _showChildren = false;

  int _initialParentIndex() {
    final current = widget.initialValue.trim().toLowerCase();
    final index = widget.options.indexWhere((option) {
      final parentMatches =
          option.label.trim().toLowerCase() == current ||
          option.value.trim().toLowerCase() == current;
      final childMatches = option.children.any(
        (child) =>
            child.value.trim().toLowerCase() == current ||
            child.label.trim().toLowerCase() == current ||
            '${option.label}|${child.label}'.toLowerCase() == current ||
            '${option.value}|${child.value}'.toLowerCase() == current,
      );
      return parentMatches || childMatches;
    });
    return index < 0 ? 0 : index;
  }

  PersonalInformationOption? _initialSelectedChild() {
    final current = widget.initialValue.trim().toLowerCase();
    final parent = widget.options[_parentIndex];
    for (final child in widget.options[_parentIndex].children) {
      if (child.label.trim().toLowerCase() == current ||
          child.value.trim().toLowerCase() == current ||
          '${parent.label}|${child.label}'.toLowerCase() == current ||
          '${parent.value}|${child.value}'.toLowerCase() == current) {
        return child;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final options = _showChildren
        ? widget.options[_parentIndex].children
        : widget.options;
    final visibleRows = math.min(options.length, _maximumVisibleRows);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final height =
        visibleRows * _rowHeight +
        (_showChildren ? 48 : 0) +
        _doneHeight +
        bottomInset;
    return DecoratedBox(
      key: const Key('certificationPaydaySheet'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            if (_showChildren)
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const Key('certificationPaydayBack'),
                    onPressed: () => setState(() => _showChildren = false),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                key: Key(
                  _showChildren
                      ? 'certificationPaydayChildren'
                      : 'certificationPaydayParents',
                ),
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.dialogDivider,
                ),
                itemBuilder: (_, index) {
                  final option = options[index];
                  final selected = _showChildren
                      ? option == _selectedChild
                      : index == _parentIndex && _selectedChild != null;
                  return InkWell(
                    key: Key(
                      _showChildren
                          ? 'certificationPaydayChild_$index'
                          : 'certificationPaydayParent_$index',
                    ),
                    onTap: () {
                      if (_showChildren) {
                        setState(() => _selectedChild = option);
                      } else if (option.children.isNotEmpty) {
                        setState(() {
                          if (_parentIndex != index) _selectedChild = null;
                          _parentIndex = index;
                          _showChildren = true;
                        });
                      }
                    },
                    child: SizedBox(
                      height: _rowHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 56),
                            child: Text(
                              option.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.certificationSelectionText,
                                fontSize: 16,
                                height: 19 / 16,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          if (selected)
                            Positioned(
                              right: 28,
                              child: Image.asset(
                                AppAssets.certificationOptionSelected,
                                key: Key(
                                  'certificationPaydaySelected_${option.value}',
                                ),
                                width: 12,
                                height: 8,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.dialogDivider)),
              ),
              child: SizedBox(
                key: const Key('certificationPaydayDone'),
                height: _doneHeight + bottomInset,
                width: double.infinity,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: _doneHeight,
                    child: TextButton(
                      onPressed: _selectedChild == null
                          ? null
                          : () => Navigator.of(context).pop(
                              CertificationPaydaySelection(
                                parent: widget.options[_parentIndex],
                                child: _selectedChild!,
                              ),
                            ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.dialogQuit,
                        disabledForegroundColor: AppColors.dialogQuit,
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: AppColors.dialogQuit,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 19 / 16,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
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
