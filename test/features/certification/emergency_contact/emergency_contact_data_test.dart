import 'package:flutter_test/flutter_test.dart';

import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/certification/emergency_contact/emergency_contact_data.dart';

void main() {
  test('parses every contact returned by the server', () {
    final data = EmergencyContactData.fromJson(
      Json({
        'silentnesses': {
          'clingiest': [
            _contact('first', '2', 'Anna', '8254-000248'),
            _contact('second', '1', 'Ben', '80054 87521'),
            _contact('third', '5', 'Cara', '80000 00008'),
            _contact('fourth', '6', 'Dan', '80000 00009'),
            _contact('fifth', '1', 'Ella', '80000 00010'),
          ],
          'pharmacies': '',
        },
        'dextrorse': 'We will protect your personal information.',
      }),
    );

    expect(data.prompt, contains('protect'));
    expect(data.contacts, hasLength(5));
    expect(data.contacts[0].number, 'first');
    expect(data.contacts[0].relationshipValue, '2');
    expect(data.contacts[0].relationshipLabel, 'Spouse');
    expect(data.contacts[0].name, 'Anna');
    expect(data.contacts[0].phone, '8254-000248');
    expect(data.contacts[0].relationshipOptions, hasLength(2));

    final form = data.toFormData();
    expect(form.fields, hasLength(15));
    expect(form.fields.first.saveKey, 'first.roebuck');
    expect(
      EmergencyContactData.contactsFromFields({
        for (final field in form.fields)
          field.saveKey: field.initialSubmitValue,
      }),
      [
        {
          'poet': '8254-000248',
          'crocidolites': 'Anna',
          'roebuck': '2',
          'attractances': 'first',
        },
        {
          'poet': '80054 87521',
          'crocidolites': 'Ben',
          'roebuck': '1',
          'attractances': 'second',
        },
        {
          'poet': '80000 00008',
          'crocidolites': 'Cara',
          'roebuck': '5',
          'attractances': 'third',
        },
        {
          'poet': '80000 00009',
          'crocidolites': 'Dan',
          'roebuck': '6',
          'attractances': 'fourth',
        },
        {
          'poet': '80000 00010',
          'crocidolites': 'Ella',
          'roebuck': '1',
          'attractances': 'fifth',
        },
      ],
    );
  });
}

Map<String, Object> _contact(
  String number,
  String relationship,
  String name,
  String phone,
) {
  return {
    'roebuck': relationship,
    'crocidolites': name,
    'poet': phone,
    'attractances': number,
    'microbial': [
      {'crocidolites': 'Parent', 'sociologeses': '1'},
      {'crocidolites': 'Spouse', 'sociologeses': '2'},
    ],
  };
}
