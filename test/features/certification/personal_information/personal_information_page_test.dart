import 'dart:async';

import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/features/certification/personal_information/personal_information_data.dart';
import 'package:dali_cash/features/certification/personal_information/personal_information_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads, prefills, and renders the Lanhu form', (tester) async {
    final load = Completer<PersonalInformationData>();
    await _pumpPage(tester, load: (_) => load.future);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    load.complete(
      PersonalInformationData(
        prompt: 'Accurate details improve approval success.',
        fields: [
          _selectionField(),
          _textField(numericKeyboard: true, value: '9123456789'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Basic identity information'), findsOneWidget);
    expect(find.text('Accurate details improve approval success.'), findsOne);
    expect(find.text('Education'), findsOneWidget);
    expect(find.text('Undergraduate'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('9123456789'), findsOneWidget);
    final input = tester.widget<TextField>(
      find.byKey(const Key('personalInformationInput_phone')),
    );
    expect(input.keyboardType, TextInputType.number);
    final progress = tester.widget<Image>(
      find.byKey(const Key('personalInformationProgress')),
    );
    expect(
      (progress.image as AssetImage).assetName,
      AppAssets.personalInformationProgress,
    );
    expect(find.text('Upload'), findsOneWidget);
  });

  testWidgets('selects an enum and submits its server value', (tester) async {
    Map<String, String>? submitted;
    await _pumpPage(
      tester,
      load: (_) async => PersonalInformationData(
        prompt: '',
        fields: [_selectionField(value: '')],
      ),
      save: (productId, fields) async => submitted = fields,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('personalInformationPicker_phillis')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undergraduate'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('certificationSelectionDone')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(submitted, {'phillis': '4'});
  });

  testWidgets('loads and submits a three-level address selection', (
    tester,
  ) async {
    Map<String, String>? submitted;
    await _pumpPage(
      tester,
      load: (_) async =>
          PersonalInformationData(prompt: '', fields: [_addressField()]),
      loadAddresses: () async => const [
        PersonalAddressNode(
          id: '1',
          label: 'NCR',
          children: [
            PersonalAddressNode(
              id: '1',
              label: 'Metro Manila',
              children: [
                PersonalAddressNode(id: '1350', label: 'Manila', children: []),
              ],
            ),
          ],
        ),
      ],
      save: (productId, fields) async => submitted = fields,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('personalInformationPicker_residential_address')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('NCR').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metro Manila').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manila').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(submitted, {'residential_address': 'NCR-Metro Manila-Manila'});
  });

  testWidgets('shows address loading feedback and blocks duplicate requests', (
    tester,
  ) async {
    final addressLoad = Completer<List<PersonalAddressNode>>();
    var addressLoadCount = 0;
    await _pumpPage(
      tester,
      load: (_) async =>
          PersonalInformationData(prompt: '', fields: [_addressField()]),
      loadAddresses: () {
        addressLoadCount += 1;
        return addressLoad.future;
      },
    );
    await tester.pumpAndSettle();
    expect(addressLoadCount, 1);

    final picker = find.byKey(
      const Key('personalInformationPicker_residential_address'),
    );
    await tester.tap(picker);
    await tester.tap(picker);
    await tester.pump();

    expect(
      find.byKey(const Key('personalInformationAddressLoading')),
      findsOneWidget,
    );
    expect(addressLoadCount, 1);

    addressLoad.complete(const []);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('personalInformationAddressLoading')),
      findsNothing,
    );
    expect(addressLoadCount, 1);
  });

  testWidgets('submits incomplete fields to the server', (tester) async {
    Map<String, String>? submitted;
    await _pumpPage(
      tester,
      load: (_) async => PersonalInformationData(
        prompt: '',
        fields: [_textField(value: '')],
      ),
      save: (productId, fields) async => submitted = fields,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(submitted, {'phone': ''});
  });

  testWidgets('shows empty and error states with retry', (tester) async {
    var attempts = 0;
    await _pumpPage(
      tester,
      load: (_) async {
        attempts += 1;
        if (attempts == 1) {
          throw ApiBusinessException('Network unavailable');
        }
        return const PersonalInformationData(prompt: '', fields: []);
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Network unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('No personal information available'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('locks duplicate saves then reports and continues', (
    tester,
  ) async {
    final saveCompleter = Completer<void>();
    var saveCount = 0;
    final reports = <String>[];
    final continuations = <String>[];
    await _pumpPage(
      tester,
      load: (_) async =>
          PersonalInformationData(prompt: '', fields: [_textField()]),
      save: (productId, fields) {
        saveCount += 1;
        return saveCompleter.future;
      },
      reportRisk: (productId, startedAtSeconds) async {
        reports.add('$productId:$startedAtSeconds');
      },
      continueFlow: (productId) async => continuations.add(productId),
      nowSeconds: () => 123,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upload'));
    await tester.tap(find.text('Upload'));
    await tester.pump();
    expect(saveCount, 1);

    saveCompleter.complete();
    await tester.pumpAndSettle();

    expect(reports, ['product-42:123']);
    expect(continuations, ['product-42']);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required PersonalInformationLoad load,
  PersonalInformationAddressLoad? loadAddresses,
  PersonalInformationSave? save,
  PersonalInformationMessage? showError,
  PersonalInformationContinue? continueFlow,
  PersonalInformationRiskReport? reportRisk,
  int Function()? nowSeconds,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(375, 812);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  return tester.pumpWidget(
    MaterialApp(
      home: PersonalInformationPage(
        productId: 'product-42',
        load: load,
        loadAddresses: loadAddresses,
        save: save,
        showError: showError ?? (_) async {},
        continueFlow: continueFlow ?? (_) async {},
        reportRisk: reportRisk ?? (_, _) async {},
        nowSeconds: nowSeconds,
      ),
    ),
  );
}

PersonalInformationField _selectionField({String value = '4'}) {
  return PersonalInformationField(
    title: 'Education',
    placeholder: 'Please select education',
    saveKey: 'phillis',
    control: PersonalInformationControl.selection,
    numericKeyboard: false,
    isRequired: true,
    options: const [
      PersonalInformationOption(label: 'High School', value: '2'),
      PersonalInformationOption(label: 'Undergraduate', value: '4'),
    ],
    initialDisplayValue: value == '4' ? 'Undergraduate' : '',
    initialSubmitValue: value,
  );
}

PersonalInformationField _textField({
  bool numericKeyboard = false,
  String value = '9123456789',
}) {
  return PersonalInformationField(
    title: 'Phone',
    placeholder: 'Please enter phone',
    saveKey: 'phone',
    control: PersonalInformationControl.text,
    numericKeyboard: numericKeyboard,
    isRequired: true,
    options: const [],
    initialDisplayValue: value,
    initialSubmitValue: value,
  );
}

PersonalInformationField _addressField() {
  return const PersonalInformationField(
    title: 'Residential Address',
    placeholder: 'Please select address',
    saveKey: 'residential_address',
    control: PersonalInformationControl.address,
    numericKeyboard: false,
    isRequired: true,
    options: [],
    initialDisplayValue: '',
    initialSubmitValue: '',
  );
}
