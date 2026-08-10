import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dali_cash/features/certification/emergency_contact/emergency_contact_data.dart';
import 'package:dali_cash/features/certification/emergency_contact/emergency_contact_page.dart';

void main() {
  testWidgets(
    'renders grouped contacts and fills one from the contact picker',
    (tester) async {
      tester.view.physicalSize = const Size(375, 1269);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      List<Map<String, String>>? saved;
      var pickerCalls = 0;
      var continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyContactPage(
            productId: 'product-42',
            load: (_) async => _data(),
            save: (_, contacts) async => saved = contacts,
            pickContact: () async {
              pickerCalls += 1;
              return const EmergencyPickedContact(
                name: 'Maria Santos',
                phone: '09175551234',
              );
            },
            continueFlow: (_) async => continued = true,
            reportRisk: (_, _) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Relationship with Emergency Contacts - 1'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('emergencyContactPicker_first')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('emergencyContactPicker_first')));
      await tester.pumpAndSettle();

      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('09175551234'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(const Key('emergencyContactPhone_first')));
      await tester.pumpAndSettle();
      expect(pickerCalls, 2);
      await tester.tap(find.byKey(const Key('emergencyContactUpload')));
      await tester.pumpAndSettle();

      expect(saved, [
        {
          'poet': '09175551234',
          'crocidolites': 'Maria Santos',
          'roebuck': '5',
          'attractances': 'first',
        },
      ]);
      expect(continued, isTrue);
    },
  );

  testWidgets(
    'keeps all five grouped contacts scrollable on a compact screen',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyContactPage(
            productId: 'product-42',
            load: (_) async => _fiveContacts(),
            save: (_, _) async {},
            reportRisk: (_, _) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('emergencyContactGroupTitle_fifth')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Relationship with Emergency Contacts - 5'),
        findsOneWidget,
      );
      final title = tester.widget<Text>(
        find.byKey(const Key('emergencyContactGroupTitle_fifth')),
      );
      expect(title.maxLines, 1);
      expect(title.softWrap, isFalse);
      expect(
        find.ancestor(
          of: find.byKey(const Key('emergencyContactGroupTitle_fifth')),
          matching: find.byType(FittedBox),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('submits incomplete contacts to the server', (tester) async {
    List<Map<String, String>>? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: EmergencyContactPage(
          productId: 'product-42',
          load: (_) async => const EmergencyContactData(
            prompt: '',
            contacts: [
              EmergencyContact(
                number: 'first',
                relationshipValue: '',
                relationshipLabel: '',
                name: '',
                phone: '',
                relationshipOptions: [],
              ),
            ],
          ),
          save: (_, contacts) async => saved = contacts,
          reportRisk: (_, _) async {},
          continueFlow: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('emergencyContactUpload')));
    await tester.pumpAndSettle();

    expect(saved, [
      {'poet': '', 'crocidolites': '', 'roebuck': '', 'attractances': 'first'},
    ]);
  });

  testWidgets('relationship opens only the relationship selection sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 1269);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var pickerCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: EmergencyContactPage(
          productId: 'product-42',
          load: (_) async => _data(),
          save: (_, _) async {},
          pickContact: () async {
            pickerCalls += 1;
            return null;
          },
          reportRisk: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('emergencyContactRelationship_first')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('certificationSelectionSheet')),
      findsOneWidget,
    );
    expect(pickerCalls, 0);
  });

  testWidgets('matches the grouped emergency contact layout', (tester) async {
    tester.view.physicalSize = const Size(375, 1269);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: EmergencyContactPage(
          productId: 'product-42',
          load: (_) async => _threeContacts(),
          save: (_, _) async {},
          reportRisk: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(EmergencyContactPage),
      matchesGoldenFile('goldens/emergency_contact_page.png'),
    );
  });
}

EmergencyContactData _data() {
  return const EmergencyContactData(
    prompt: 'Please provide your emergency contact information.',
    contacts: [
      EmergencyContact(
        number: 'first',
        relationshipValue: '5',
        relationshipLabel: 'Friend',
        name: 'Anna',
        phone: '09170000000',
        relationshipOptions: [
          EmergencyContactOption(label: 'Parent', value: '1'),
          EmergencyContactOption(label: 'Friend', value: '5'),
        ],
      ),
    ],
  );
}

EmergencyContactData _fiveContacts() {
  const option = EmergencyContactOption(label: 'Friend', value: '5');
  return const EmergencyContactData(
    prompt: 'Please provide your emergency contact information.',
    contacts: [
      EmergencyContact(
        number: 'first',
        relationshipValue: '5',
        relationshipLabel: 'Friend',
        name: 'Anna',
        phone: '09170000001',
        relationshipOptions: [option],
      ),
      EmergencyContact(
        number: 'second',
        relationshipValue: '5',
        relationshipLabel: 'Friend',
        name: 'Ben',
        phone: '09170000002',
        relationshipOptions: [option],
      ),
      EmergencyContact(
        number: 'third',
        relationshipValue: '5',
        relationshipLabel: 'Friend',
        name: 'Cara',
        phone: '09170000003',
        relationshipOptions: [option],
      ),
      EmergencyContact(
        number: 'fourth',
        relationshipValue: '5',
        relationshipLabel: 'Friend',
        name: 'Dan',
        phone: '09170000004',
        relationshipOptions: [option],
      ),
      EmergencyContact(
        number: 'fifth',
        relationshipValue: '5',
        relationshipLabel: 'Friend',
        name: 'Ella',
        phone: '09170000005',
        relationshipOptions: [option],
      ),
    ],
  );
}

EmergencyContactData _threeContacts() {
  final data = _fiveContacts();
  return EmergencyContactData(
    prompt: data.prompt,
    contacts: data.contacts.take(3).toList(growable: false),
  );
}
