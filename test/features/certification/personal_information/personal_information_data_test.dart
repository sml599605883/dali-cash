import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/certification/personal_information/personal_information_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses dynamic fields and resolves the current option value', () {
    final data = PersonalInformationData.fromJson(
      Json({
        'choired': [
          {
            'enterostomy': 'Education',
            'laggings': 'Please select education',
            'felicitous': 'phillis',
            'solferino': 'KrimmersOpinioned',
            'omegas': 0,
            'muscats': 0,
            'fyke': 'Undergraduate',
            'poolsides': [
              {'crocidolites': 'High School', 'sociologeses': 2},
              {'crocidolites': 'Undergraduate', 'sociologeses': 4},
            ],
          },
        ],
        'dextrorse': 'Accurate details improve approval success.',
      }),
    );

    expect(data.prompt, 'Accurate details improve approval success.');
    expect(data.fields, hasLength(1));
    final field = data.fields.single;
    expect(field.title, 'Education');
    expect(field.placeholder, 'Please select education');
    expect(field.saveKey, 'phillis');
    expect(field.control, PersonalInformationControl.selection);
    expect(field.isRequired, isTrue);
    expect(field.initialDisplayValue, 'Undergraduate');
    expect(field.initialSubmitValue, '4');
  });

  test('parses fields when passed the complete API response', () {
    final data = PersonalInformationData.fromJson(
      Json({
        'felicitous': '0',
        'cuckoo': 'success',
        'unsphered': {
          'choired': [
            {
              'enterostomy': 'Email',
              'laggings': 'Please input email',
              'felicitous': 'offer',
              'solferino': 'Haphtaras',
              'omegas': 0,
              'muscats': 0,
              'fyke': 'user@example.com',
            },
          ],
          'dextrorse': 'Complete your personal information.',
        },
      }),
    );

    expect(data.prompt, 'Complete your personal information.');
    expect(data.fields, hasLength(1));
    expect(data.fields.single.title, 'Email');
  });

  test('parses text and numeric keyboard fields', () {
    final data = PersonalInformationData.fromJson(
      Json({
        'choired': [
          {
            'enterostomy': 'Email',
            'laggings': 'Please input email',
            'felicitous': 'offer',
            'solferino': 'Haphtaras',
            'omegas': 0,
            'muscats': 1,
            'fyke': 'user@example.com',
          },
          {
            'enterostomy': 'Phone',
            'laggings': 'Please input phone',
            'felicitous': 'garnitures',
            'solferino': 'Haphtaras',
            'omegas': 1,
            'muscats': 0,
            'fyke': 9123456789,
          },
        ],
      }),
    );

    expect(data.fields, hasLength(2));
    expect(data.fields.first.control, PersonalInformationControl.text);
    expect(data.fields.first.isRequired, isFalse);
    expect(data.fields.first.initialSubmitValue, 'user@example.com');
    expect(data.fields.last.numericKeyboard, isTrue);
    expect(data.fields.last.initialDisplayValue, '9123456789');
  });

  test('keeps server fields without silently filtering them', () {
    final data = PersonalInformationData.fromJson(
      Json({
        'choired': [
          {
            'enterostomy': 'Unknown',
            'felicitous': 'unknown',
            'solferino': 'calendar',
          },
          {
            'enterostomy': 'Missing key',
            'felicitous': '',
            'solferino': 'Haphtaras',
          },
        ],
      }),
    );

    expect(data.fields, hasLength(2));
    expect(data.fields.first.control, PersonalInformationControl.unsupported);
    expect(data.fields.last.control, PersonalInformationControl.text);
    expect(data.fields.last.saveKey, isEmpty);
  });

  test('uses option values returned as strings or numbers', () {
    final data = PersonalInformationData.fromJson(
      Json({
        'choired': [
          {
            'enterostomy': 'Gender',
            'felicitous': 'copies',
            'solferino': 'KrimmersOpinioned',
            'fyke': '2',
            'poolsides': [
              {'crocidolites': 'male', 'sociologeses': '1'},
              {
                'crocidolites': 'female',
                'sociologeses': 2,
                'leachate': 'https://example.com/female.png',
              },
            ],
          },
        ],
      }),
    );

    expect(data.fields.single.initialDisplayValue, 'female');
    expect(data.fields.single.initialSubmitValue, '2');
    expect(
      data.fields.single.options.last.logoUrl,
      'https://example.com/female.png',
    );
    expect(data.fields.single.options.last.hint, isEmpty);
  });

  test('keeps stage fields for address selection without inline options', () {
    final data = PersonalInformationData.fromJson(
      Json({
        'choired': [
          {
            'enterostomy': 'Residential Address',
            'laggings': 'Please select address',
            'felicitous': 'residential_address',
            'solferino': 'Superpower',
            'muscats': 0,
            'fyke': 'Region I-Pangasinan',
            'poolsides': [],
          },
        ],
      }),
    );

    expect(data.fields.single.control, PersonalInformationControl.address);
    expect(data.fields.single.initialSubmitValue, 'Region I-Pangasinan');
  });

  test('parses recursive work options and resolves a nested payday value', () {
    final data = PersonalInformationData.fromJson(
      Json({
        'choired': [
          {
            'enterostomy': 'Payday',
            'felicitous': 'opportunities',
            'solferino': 'KrimmersOpinioned',
            'fyke': 'Once a Month|1',
            'poolsides': [
              {
                'crocidolites': 'Daily',
                'sociologeses': 1,
                'poolsides': [
                  {'crocidolites': 'Daily', 'sociologeses': 1},
                ],
              },
              {
                'crocidolites': 'Once a Month',
                'sociologeses': 4,
                'poolsides': [
                  {'crocidolites': 1, 'sociologeses': 11},
                ],
              },
            ],
          },
        ],
      }),
    );

    final field = data.fields.single;
    expect(field.control, PersonalInformationControl.selection);
    expect(field.initialDisplayValue, 'Once a Month|1');
    expect(field.initialSubmitValue, 'Once a Month|1');
    expect(field.options.last.children.single.label, '1');
    expect(field.options.last.children.single.value, '11');
  });

  test('parses the actual three-level clingiest address hierarchy', () {
    final nodes = PersonalAddressNode.parseList(
      Json({
        'clingiest': [
          {
            'underfeeding': 1,
            'crocidolites': 'NCR',
            'clingiest': [
              {
                'underfeeding': 1,
                'crocidolites': 'Metro Manila',
                'clingiest': [
                  {'underfeeding': 1350, 'crocidolites': 'Manila'},
                ],
              },
            ],
          },
        ],
      }),
    );

    expect(nodes.single.id, '1');
    expect(nodes.single.label, 'NCR');
    expect(nodes.single.children.single.id, '1');
    expect(nodes.single.children.single.label, 'Metro Manila');
    expect(nodes.single.children.single.children.single.id, '1350');
    expect(nodes.single.children.single.children.single.label, 'Manila');
  });
}
