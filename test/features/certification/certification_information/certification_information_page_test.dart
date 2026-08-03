import 'package:dali_cash/features/certification/certification_information/certification_information_page.dart';
import 'package:dali_cash/features/certification/personal_information/personal_information_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders configurable certification page metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CertificationInformationPage(
          productId: 'product-42',
          title: 'Job information',
          defaultPrompt: 'Work details help us assess your credit limit.',
          progressAsset: 'assets/certification/work_information_progress.png',
          keyPrefix: 'workInformation',
          load: (_) async => PersonalInformationData(
            prompt: '',
            fields: [
              const PersonalInformationField(
                title: 'Company Name',
                placeholder: 'Please enter',
                saveKey: 'company_name',
                control: PersonalInformationControl.text,
                numericKeyboard: false,
                isRequired: true,
                options: [],
                initialDisplayValue: '',
                initialSubmitValue: '',
              ),
            ],
          ),
          loadAddresses: () async => const [],
          save: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Job information'), findsOneWidget);
    expect(
      find.text('Work details help us assess your credit limit.'),
      findsOneWidget,
    );
    final progress = tester.widget<Image>(
      find.byKey(const Key('workInformationProgress')),
    );
    expect(
      (progress.image as AssetImage).assetName,
      'assets/certification/work_information_progress.png',
    );
    expect(
      find.byKey(const Key('workInformationInput_company_name')),
      findsOneWidget,
    );
  });
}
