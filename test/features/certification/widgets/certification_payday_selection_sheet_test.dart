import 'package:dali_cash/features/certification/personal_information/personal_information_data.dart';
import 'package:dali_cash/features/certification/widgets/certification_payday_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selects a child and returns the parent-child display value', (
    tester,
  ) async {
    CertificationPaydaySelection? result;
    await _pumpLauncher(tester, onResult: (value) => result = value);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('certificationPaydayParents')), findsOneWidget);
    expect(find.text('Once a Month'), findsOneWidget);

    await tester.tap(find.text('Once a Month'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('certificationPaydayChildren')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('certificationPaydayBack')), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byKey(const Key('certificationPaydaySheet')), findsOneWidget);
    expect(
      find.byKey(const Key('certificationPaydaySelected_11')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('certificationPaydayDone')), findsOneWidget);

    await tester.tap(find.byKey(const Key('certificationPaydayDone')));
    await tester.pumpAndSettle();
    expect(result?.displayText, 'Once a Month|1');
    expect(result?.submitValue, 'Once a Month|1');
    expect(find.byKey(const Key('certificationPaydaySheet')), findsNothing);
  });

  testWidgets('returns to parent list without closing the sheet', (
    tester,
  ) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Once a Month'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('certificationPaydayBack')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('certificationPaydayParents')), findsOneWidget);
    expect(find.byKey(const Key('certificationPaydaySheet')), findsOneWidget);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  ValueChanged<CertificationPaydaySelection?>? onResult,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final result = await showCertificationPaydaySelectionSheet(
              context: context,
              options: const [
                PersonalInformationOption(
                  label: 'Daily',
                  value: '1',
                  children: [
                    PersonalInformationOption(label: 'Daily', value: '1'),
                  ],
                ),
                PersonalInformationOption(
                  label: 'Once a Month',
                  value: '4',
                  children: [
                    PersonalInformationOption(label: '1', value: '11'),
                    PersonalInformationOption(label: '2', value: '12'),
                  ],
                ),
              ],
            );
            onResult?.call(result);
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
}
