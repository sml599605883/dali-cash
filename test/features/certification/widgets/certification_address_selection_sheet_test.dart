import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/certification/personal_information/personal_information_data.dart';
import 'package:dali_cash/features/certification/widgets/certification_address_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selects all three address levels in one fixed-height sheet', (
    tester,
  ) async {
    PersonalAddressSelection? result;
    await _pumpLauncher(tester, onResult: (value) => result = value);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addressSelectionSheet')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('addressSelectionSheet'))),
      const Size(375, 464),
    );
    expect(find.byKey(const Key('addressStep_region')), findsOneWidget);
    expect(find.byKey(const Key('addressStep_province')), findsOneWidget);
    expect(find.byKey(const Key('addressStep_municipality')), findsOneWidget);
    for (final level in AddressLevel.values) {
      final chevron = tester.widget<Image>(
        find.descendant(
          of: find.byKey(Key('addressStep_${level.name}')),
          matching: find.byType(Image),
        ),
      );
      expect(
        (chevron.image as AssetImage).assetName,
        'assets/certification/address_picker/address_picker_chevron.png',
      );
      expect(chevron.width, 13);
      expect(chevron.height, 13);
    }

    await tester.tap(find.text('NCR').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metro Manila').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manila').last);
    await tester.pumpAndSettle();

    expect(result?.submitValue, 'NCR-Metro Manila-Manila');
    expect(find.byKey(const Key('addressSelectionSheet')), findsNothing);
  });

  testWidgets('restores a complete value and can reset to Region', (
    tester,
  ) async {
    await _pumpLauncher(tester, initialValue: 'NCR-Metro Manila-Quezon City');

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('addressOptionSelected_Quezon City')),
      findsOneWidget,
    );
    expect(_stepLabel(tester, AddressLevel.region), 'NCR');
    expect(_stepLabel(tester, AddressLevel.province), 'Metro Manila');
    expect(_stepLabel(tester, AddressLevel.municipality), 'Quezon City');
    expect(_indicatorColor(tester, AddressLevel.region), AppColors.primary);
    expect(_indicatorColor(tester, AddressLevel.province), AppColors.primary);
    expect(
      _indicatorColor(tester, AddressLevel.municipality),
      AppColors.primary,
    );
    await tester.tap(find.byKey(const Key('addressStep_region')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addressOptions_region')), findsOneWidget);
    expect(find.text('Metro Manila'), findsNothing);
    expect(find.text('Quezon City'), findsNothing);
  });

  testWidgets('updates completed indicators and selected step labels', (
    tester,
  ) async {
    await _pumpLauncher(tester);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(_stepLabel(tester, AddressLevel.region), 'Region');
    expect(_stepLabel(tester, AddressLevel.province), 'Province');
    expect(_stepLabel(tester, AddressLevel.municipality), 'Municipality');
    expect(_indicatorColor(tester, AddressLevel.region), AppColors.primary);
    expect(_indicatorColor(tester, AddressLevel.province), AppColors.surface);
    expect(
      _indicatorColor(tester, AddressLevel.municipality),
      AppColors.surface,
    );
    expect(_connectorColor(tester, 'regionProvince'), AppColors.surface);
    expect(_connectorColor(tester, 'provinceMunicipality'), AppColors.surface);

    await tester.tap(find.text('NCR').last);
    await tester.pumpAndSettle();

    expect(_stepLabel(tester, AddressLevel.region), 'NCR');
    expect(_stepLabel(tester, AddressLevel.province), 'Province');
    expect(_indicatorColor(tester, AddressLevel.region), AppColors.primary);
    expect(_indicatorColor(tester, AddressLevel.province), AppColors.primary);
    expect(
      _indicatorColor(tester, AddressLevel.municipality),
      AppColors.surface,
    );
    expect(_connectorColor(tester, 'regionProvince'), AppColors.primary);
    expect(_connectorColor(tester, 'provinceMunicipality'), AppColors.surface);

    await tester.tap(find.text('Metro Manila').last);
    await tester.pumpAndSettle();

    expect(_stepLabel(tester, AddressLevel.province), 'Metro Manila');
    expect(_stepLabel(tester, AddressLevel.municipality), 'Municipality');
    expect(_indicatorColor(tester, AddressLevel.region), AppColors.primary);
    expect(_indicatorColor(tester, AddressLevel.province), AppColors.primary);
    expect(
      _indicatorColor(tester, AddressLevel.municipality),
      AppColors.primary,
    );
    expect(_connectorColor(tester, 'regionProvince'), AppColors.primary);
    expect(_connectorColor(tester, 'provinceMunicipality'), AppColors.primary);
  });

  testWidgets('close returns null without changing the value', (tester) async {
    PersonalAddressSelection? result;
    await _pumpLauncher(tester, onResult: (value) => result = value);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addressPickerClose')));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byKey(const Key('addressSelectionSheet')), findsNothing);
  });

  testWidgets('does not return an incomplete address when children are empty', (
    tester,
  ) async {
    PersonalAddressSelection? result;
    await _pumpLauncher(
      tester,
      nodes: const [
        PersonalAddressNode(id: '2', label: 'Empty Region', children: []),
      ],
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empty Region').last);
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byKey(const Key('addressSelectionSheet')), findsOneWidget);
    expect(find.byKey(const Key('addressOptions_province')), findsOneWidget);
  });
}

String? _stepLabel(WidgetTester tester, AddressLevel level) {
  return tester
      .widget<Text>(find.byKey(Key('addressStepLabel_${level.name}')))
      .data;
}

Color? _indicatorColor(WidgetTester tester, AddressLevel level) {
  final box = tester.widget<DecoratedBox>(
    find.byKey(Key('addressStepIndicator_${level.name}')),
  );
  return (box.decoration as BoxDecoration).color;
}

Color _connectorColor(WidgetTester tester, String connector) {
  return tester
      .widget<ColoredBox>(find.byKey(Key('addressStepLine_$connector')))
      .color;
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  List<PersonalAddressNode> nodes = _addressNodes,
  String initialValue = '',
  ValueChanged<PersonalAddressSelection?>? onResult,
}) {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  ScreenAdapter.initForSize(const Size(375, 812));
  return tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final result = await showCertificationAddressSelectionSheet(
              context: context,
              nodes: nodes,
              initialValue: initialValue,
            );
            onResult?.call(result);
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

const _addressNodes = [
  PersonalAddressNode(
    id: '1',
    label: 'NCR',
    children: [
      PersonalAddressNode(
        id: '1',
        label: 'Metro Manila',
        children: [
          PersonalAddressNode(id: '1350', label: 'Manila', children: []),
          PersonalAddressNode(id: '1354', label: 'Quezon City', children: []),
        ],
      ),
    ],
  ),
];
