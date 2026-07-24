import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/layout/screen_adapter.dart';
import '../../../app/theme/app_colors.dart';

final identityBirthdayMinimumDate = DateTime(1900);

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime parseIdentityBirthday(String value, {required DateTime maximumDate}) {
  final normalizedMaximumDate = _dateOnly(maximumDate);
  final dayDash = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(value);
  final daySlash = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
  final yearSlash = RegExp(r'^(\d{4})/(\d{2})/(\d{2})$').firstMatch(value);

  final int year;
  final int month;
  final int day;
  if (dayDash != null) {
    year = int.parse(dayDash.group(3)!);
    month = int.parse(dayDash.group(2)!);
    day = int.parse(dayDash.group(1)!);
  } else if (daySlash != null) {
    year = int.parse(daySlash.group(3)!);
    month = int.parse(daySlash.group(2)!);
    day = int.parse(daySlash.group(1)!);
  } else if (yearSlash != null) {
    year = int.parse(yearSlash.group(1)!);
    month = int.parse(yearSlash.group(2)!);
    day = int.parse(yearSlash.group(3)!);
  } else {
    return normalizedMaximumDate;
  }

  final parsed = DateTime(year, month, day);
  if (parsed.year != year ||
      parsed.month != month ||
      parsed.day != day ||
      parsed.isBefore(identityBirthdayMinimumDate) ||
      parsed.isAfter(normalizedMaximumDate)) {
    return normalizedMaximumDate;
  }
  return parsed;
}

String formatIdentityBirthday(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

String normalizeIdentityBirthday(String value, {DateTime? maximumDate}) {
  if (value.trim().isEmpty) return '';
  final maximum = _dateOnly(maximumDate ?? DateTime.now());
  final parsed = parseIdentityBirthday(value.trim(), maximumDate: maximum);
  return formatIdentityBirthday(parsed);
}

DateTime clampIdentityBirthday({
  required int year,
  required int month,
  required int day,
  required DateTime maximumDate,
}) {
  final maximum = _dateOnly(maximumDate);
  if (year < identityBirthdayMinimumDate.year) {
    return identityBirthdayMinimumDate;
  }
  if (year > maximum.year) return maximum;
  final maxMonth = year == maximum.year ? maximum.month : 12;
  final safeMonth = month.clamp(1, maxMonth);
  final daysInMonth = DateTime(year, safeMonth + 1, 0).day;
  final maxDay = year == maximum.year && safeMonth == maximum.month
      ? maximum.day
      : daysInMonth;
  return DateTime(year, safeMonth, day.clamp(1, maxDay));
}

Future<DateTime?> showIdentityBirthdayPicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? maximumDate,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss birthday picker',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, _, _) => _IdentityBirthdayDialog(
      initialDate: initialDate,
      maximumDate: maximumDate,
    ),
    transitionBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _IdentityBirthdayDialog extends StatelessWidget {
  const _IdentityBirthdayDialog({required this.initialDate, this.maximumDate});

  final DateTime initialDate;
  final DateTime? maximumDate;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ScreenAdapter.width(16)),
            ),
            clipBehavior: Clip.antiAlias,
            child: IdentityBirthdayPicker(
              initialDate: initialDate,
              maximumDate: maximumDate,
            ),
          ),
        ),
      ],
    );
  }
}

class IdentityBirthdayPicker extends StatefulWidget {
  const IdentityBirthdayPicker({
    super.key,
    required this.initialDate,
    this.maximumDate,
  });

  final DateTime initialDate;
  final DateTime? maximumDate;

  @override
  State<IdentityBirthdayPicker> createState() => _IdentityBirthdayPickerState();
}

class _IdentityBirthdayPickerState extends State<IdentityBirthdayPicker> {
  static const _minimumYear = 1900;
  late final DateTime _maximumDate = _dateOnly(
    widget.maximumDate ?? DateTime.now(),
  );
  late DateTime _selectedDate = clampIdentityBirthday(
    year: widget.initialDate.year,
    month: widget.initialDate.month,
    day: widget.initialDate.day,
    maximumDate: _maximumDate,
  );
  late final FixedExtentScrollController _dayController =
      FixedExtentScrollController(initialItem: _selectedDate.day - 1);
  late final FixedExtentScrollController _monthController =
      FixedExtentScrollController(initialItem: _selectedDate.month - 1);
  late final FixedExtentScrollController _yearController =
      FixedExtentScrollController(
        initialItem: _selectedDate.year - _minimumYear,
      );
  bool _syncing = false;

  int get _monthCount =>
      _selectedDate.year == _maximumDate.year ? _maximumDate.month : 12;

  int get _dayCount {
    final days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    if (_selectedDate.year == _maximumDate.year &&
        _selectedDate.month == _maximumDate.month) {
      return _maximumDate.day;
    }
    return days;
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('identityBirthdayPicker'),
      width: ScreenAdapter.width(375),
      height: ScreenAdapter.height(307),
      child: Column(
        children: [
          SizedBox(
            height: ScreenAdapter.height(47),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(_selectedDate),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenAdapter.width(16),
                    vertical: ScreenAdapter.height(10),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.identityPickerMuted,
                      fontSize: ScreenAdapter.font(16),
                      fontWeight: FontWeight.w400,
                      height: 19 / 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: ScreenAdapter.height(46),
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.identityPickerDivider,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _wheel(
                        key: const Key('identityBirthdayDayWheel'),
                        controller: _dayController,
                        count: _dayCount,
                        selectedIndex: _selectedDate.day - 1,
                        label: (index) => '${index + 1}',
                        onChanged: (index) => _select(
                          year: _selectedDate.year,
                          month: _selectedDate.month,
                          day: index + 1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _wheel(
                        key: const Key('identityBirthdayMonthWheel'),
                        controller: _monthController,
                        count: _monthCount,
                        selectedIndex: _selectedDate.month - 1,
                        label: (index) => '${index + 1}',
                        onChanged: (index) => _select(
                          year: _selectedDate.year,
                          month: index + 1,
                          day: _selectedDate.day,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _wheel(
                        key: const Key('identityBirthdayYearWheel'),
                        controller: _yearController,
                        count: _maximumDate.year - _minimumYear + 1,
                        selectedIndex: _selectedDate.year - _minimumYear,
                        label: (index) => '${_minimumYear + index}',
                        onChanged: (index) => _select(
                          year: _minimumYear + index,
                          month: _selectedDate.month,
                          day: _selectedDate.day,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required Key key,
    required FixedExtentScrollController controller,
    required int count,
    required int selectedIndex,
    required String Function(int index) label,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      key: key,
      controller: controller,
      itemExtent: ScreenAdapter.height(52),
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1000,
      perspective: 0.003,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (_, index) => Center(
          child: Text(
            label(index),
            style: TextStyle(
              color: index == selectedIndex
                  ? AppColors.identityPickerSelected
                  : AppColors.identityPickerText,
              fontSize: ScreenAdapter.font(20),
              fontWeight: index == selectedIndex
                  ? FontWeight.w700
                  : FontWeight.w400,
              height: 24 / 20,
            ),
          ),
        ),
      ),
    );
  }

  void _select({required int year, required int month, required int day}) {
    if (_syncing) return;
    final next = clampIdentityBirthday(
      year: year,
      month: month,
      day: day,
      maximumDate: _maximumDate,
    );
    _syncing = true;
    try {
      _sync(_yearController, next.year - _minimumYear);
      _sync(_monthController, next.month - 1);
      _sync(_dayController, next.day - 1);
    } finally {
      _syncing = false;
    }
    if (next != _selectedDate) setState(() => _selectedDate = next);
  }

  void _sync(FixedExtentScrollController controller, int index) {
    if (controller.hasClients && controller.selectedItem != index) {
      controller.jumpToItem(index);
    }
  }
}
