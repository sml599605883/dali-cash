import 'package:dali_cash/features/certification/widgets/certification_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns the tapped option and marks the current value', (
    tester,
  ) async {
    CertificationSelectionSheetOption<String>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showCertificationSelectionSheet<String>(
                context: context,
                title: 'Education',
                options: const [
                  CertificationSelectionSheetOption(
                    label: 'High School',
                    value: '2',
                    logoUrl: 'https://example.com/high-school.png',
                    hint: 'Under maintenance. Loans may be delayed',
                  ),
                  CertificationSelectionSheetOption(
                    label: 'Undergraduate',
                    value: '4',
                  ),
                ],
                selectedValue: '2',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('certificationSelectionSheet')),
      findsOneWidget,
    );
    expect(find.text('Education'), findsNothing);
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const Key('certificationSelectionSurface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(
      decoration.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(24)),
    );
    expect(
      tester.getSize(find.byKey(const Key('certificationOption_2'))).height,
      58,
    );
    expect(find.byKey(const Key('certificationOptionLogo_2')), findsOneWidget);
    expect(
      find.text('Under maintenance. Loans may be delayed'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('certificationOptionSelected_2')), findsOne);
    final selectedImage = tester.widget<Image>(
      find.byKey(const Key('certificationOptionSelected_2')),
    );
    expect(
      (selectedImage.image as AssetImage).assetName,
      'assets/certification/certification_option_selected.png',
    );
    expect(selectedImage.width, 12);
    expect(selectedImage.height, 8);

    await tester.tap(find.text('Undergraduate'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(
      find.byKey(const Key('certificationOptionSelected_2')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('certificationOptionSelected_4')),
      findsOneWidget,
    );

    expect(find.byKey(const Key('certificationSelectionDone')), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.byKey(const Key('certificationSelectionDone')));
    await tester.pumpAndSettle();

    expect(result?.value, '4');
    expect(result?.label, 'Undergraduate');
  });

  testWidgets('caps the visible option viewport at five rows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCertificationSelectionSheet<int>(
              context: context,
              title: 'Options',
              options: List.generate(
                7,
                (index) => CertificationSelectionSheetOption(
                  label: 'Option $index',
                  value: index,
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final viewport = tester.widget<SizedBox>(
      find.byKey(const Key('certificationSelectionViewport')),
    );
    expect(viewport.height, 290);
    expect(find.byType(Scrollable), findsWidgets);
  });
}
