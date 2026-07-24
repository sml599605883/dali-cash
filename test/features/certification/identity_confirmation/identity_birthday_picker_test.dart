import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/features/certification/identity_confirmation/identity_birthday_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes supported OCR birthday formats to dd-MM-yyyy', () {
    final maximumDate = DateTime(2026, 7, 24);

    expect(
      formatIdentityBirthday(
        parseIdentityBirthday('1995/05/31', maximumDate: maximumDate),
      ),
      '31-05-1995',
    );
    expect(
      formatIdentityBirthday(
        parseIdentityBirthday('31/05/1995', maximumDate: maximumDate),
      ),
      '31-05-1995',
    );
    expect(
      formatIdentityBirthday(
        parseIdentityBirthday('31-05-1995', maximumDate: maximumDate),
      ),
      '31-05-1995',
    );
    expect(parseIdentityBirthday('', maximumDate: maximumDate), maximumDate);
  });

  testWidgets('matches the Lanhu date sheet with blurred account backdrop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ScreenAdapter.initForSize(const Size(375, 812));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showIdentityBirthdayPicker(
              context: context,
              initialDate: DateTime(2003, 4, 18),
              maximumDate: DateTime(2026, 7, 24),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('identityBirthdayPicker'))),
      const Size(375, 307),
    );
    expect(find.byKey(const Key('identityBirthdayDayWheel')), findsOneWidget);
    expect(find.byKey(const Key('identityBirthdayMonthWheel')), findsOneWidget);
    expect(find.byKey(const Key('identityBirthdayYearWheel')), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
