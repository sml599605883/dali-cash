import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/features/certification/certification_information/certification_information_page.dart';
import 'package:dali_cash/features/certification/personal_information/personal_information_data.dart';
import 'package:dali_cash/features/certification/work_information/work_information_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders work metadata and submits nested payday value', (
    tester,
  ) async {
    Map<String, String>? submitted;
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: WorkInformationPage(
          productId: 'product-42',
          load: (_) async => const PersonalInformationData(
            prompt: 'Complete work details.',
            fields: [
              PersonalInformationField(
                title: 'Payday',
                placeholder: 'Please select payday',
                saveKey: 'opportunities',
                control: PersonalInformationControl.selection,
                numericKeyboard: false,
                isRequired: true,
                options: [
                  PersonalInformationOption(
                    label: 'Once a Month',
                    value: '4',
                    children: [
                      PersonalInformationOption(label: '1', value: '11'),
                    ],
                  ),
                ],
                initialDisplayValue: '',
                initialSubmitValue: '',
              ),
            ],
          ),
          save: (_, fields) async => submitted = fields,
          showError: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Job information'), findsOneWidget);
    expect(find.text('Complete work details.'), findsOneWidget);
    expect(
      tester
          .widget<CertificationInformationPage>(
            find.byType(CertificationInformationPage),
          )
          .riskScene,
      '6',
    );
    final progress = tester.widget<Image>(
      find.byKey(const Key('workInformationProgress')),
    );
    expect(
      (progress.image as AssetImage).assetName,
      AppAssets.workInformationProgress,
    );

    final picker = find.byKey(const Key('workInformationPicker_opportunities'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Once a Month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('certificationPaydayDone')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(submitted, {'opportunities': '11'});
  });
}
