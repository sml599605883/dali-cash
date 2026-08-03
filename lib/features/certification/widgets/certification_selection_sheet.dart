import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/resources/app_assets.dart';
import '../../../app/theme/app_colors.dart';

class CertificationSelectionSheetOption<T> {
  const CertificationSelectionSheetOption({
    required this.label,
    required this.value,
    this.logoUrl = '',
    this.hint = '',
  });

  final String label;
  final T value;
  final String logoUrl;
  final String hint;
}

Future<CertificationSelectionSheetOption<T>?>
showCertificationSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<CertificationSelectionSheetOption<T>> options,
  T? selectedValue,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<CertificationSelectionSheetOption<T>>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.dialogBarrier,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => _CertificationSelectionSheet<T>(
      title: title,
      options: options,
      selectedValue: selectedValue,
    ),
  );
}

class _CertificationSelectionSheet<T> extends StatefulWidget {
  const _CertificationSelectionSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final List<CertificationSelectionSheetOption<T>> options;
  final T? selectedValue;

  @override
  State<_CertificationSelectionSheet<T>> createState() =>
      _CertificationSelectionSheetState<T>();
}

class _CertificationSelectionSheetState<T>
    extends State<_CertificationSelectionSheet<T>> {
  static const _rowHeight = 58.0;
  static const _doneHeight = 58.0;

  late CertificationSelectionSheetOption<T>? _selectedOption =
      _initialSelectedOption();

  CertificationSelectionSheetOption<T>? _initialSelectedOption() {
    for (final option in widget.options) {
      if (option.value == widget.selectedValue) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final visibleRows = math.min(widget.options.length, 5);
    return DecoratedBox(
      key: const Key('certificationSelectionSurface'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Semantics(
          label: widget.title,
          container: true,
          child: SizedBox(
            key: const Key('certificationSelectionSheet'),
            height: visibleRows * _rowHeight + _doneHeight,
            child: Column(
              children: [
                SizedBox(
                  height: visibleRows * _rowHeight,
                  child: SizedBox(
                    key: const Key('certificationSelectionViewport'),
                    height: visibleRows * _rowHeight,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemExtent: _rowHeight,
                      itemCount: widget.options.length,
                      itemBuilder: (context, index) {
                        final option = widget.options[index];
                        return _CertificationSelectionOption<T>(
                          option: option,
                          selected: option == _selectedOption,
                          onTap: () => setState(() => _selectedOption = option),
                        );
                      },
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.dialogDivider),
                    ),
                  ),
                  child: SizedBox(
                    key: const Key('certificationSelectionDone'),
                    height: _doneHeight,
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_selectedOption),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.dialogQuit,
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Text(
                        'done',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CertificationSelectionOption<T> extends StatelessWidget {
  const _CertificationSelectionOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CertificationSelectionSheetOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('certificationOption_${option.value}'),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.dialogDivider)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMainContent(),
                  if (option.hint.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.hint,
                      key: Key('certificationOptionHint_${option.value}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 12 / 10,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Positioned(
                right: 28,
                child: Image.asset(
                  AppAssets.certificationOptionSelected,
                  key: Key('certificationOptionSelected_${option.value}'),
                  width: 12,
                  height: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (option.logoUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              option.logoUrl,
              key: Key('certificationOptionLogo_${option.value}'),
              width: 20,
              height: 20,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(width: 20, height: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.certificationSelectionText,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 19 / 16,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
