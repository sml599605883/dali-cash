import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/account/account_list_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAccountSections', () {
    test('maps complete account fields using tolerant Json conversions', () {
      final sections = parseAccountSections(
        Json({
          'clingiest': [
            {
              'rapscallion': 7,
              'pater': '  Cash Pickup  ',
              'alodia': '  https://example.com/type.png  ',
              'jambes': [
                {
                  'hoover': 42,
                  'leachate': '  https://example.com/logo.png  ',
                  'precolonial': '0',
                  'chalones': 'Bank temporarily unavailable',
                  'filmcards': true,
                  'emptiable': 123456,
                  'nonbehavioral': {
                    'rattlesnakes': '  Ana  ',
                    'monerans': 8,
                    'sloid': '  Cruz  ',
                  },
                  'exploitable': 'yes',
                  'sociologeses': 3,
                },
              ],
            },
          ],
        }),
      );

      final section = sections.single;
      expect(section.cardType, '7');
      expect(section.title, 'Cash Pickup');
      expect(section.typeIconUrl, 'https://example.com/type.png');

      final account = section.accounts.single;
      expect(account.bindId, '42');
      expect(account.type, '3');
      expect(account.logoUrl, 'https://example.com/logo.png');
      expect(account.providerName, 'true');
      expect(account.accountValue, '123456');
      expect(account.firstName, 'Ana');
      expect(account.middleName, '8');
      expect(account.lastName, 'Cruz');
      expect(account.isMain, isTrue);
      expect(account.isUnderMaintenance, isTrue);
      expect(account.maintenanceText, 'Bank temporarily unavailable');
    });

    test('filters invalid data while preserving section and account order', () {
      final sections = parseAccountSections(
        Json({
          'clingiest': [
            {
              'rapscallion': 'ignored-empty-title',
              'pater': '   ',
              'jambes': [
                {'hoover': 'ignored'},
              ],
            },
            {
              'rapscallion': 'unknown-a',
              'pater': 'First unknown',
              'jambes': [
                {'hoover': '  first  ', 'emptiable': 'A'},
                {'hoover': '   ', 'emptiable': 'ignored'},
                {'hoover': 'second', 'emptiable': 'B'},
              ],
            },
            {
              'rapscallion': 'known-or-unknown-b',
              'pater': 'Second group',
              'jambes': [
                {'hoover': 'third'},
              ],
            },
            {
              'rapscallion': 'empty-accounts',
              'pater': 'No valid accounts',
              'jambes': [
                {'hoover': null},
              ],
            },
          ],
        }),
      );

      expect(sections.map((section) => section.title), [
        'First unknown',
        'Second group',
      ]);
      expect(sections.first.accounts.map((account) => account.bindId), [
        'first',
        'second',
      ]);
      expect(sections.last.accounts.single.bindId, 'third');
    });

    test('returns an empty list for malformed null and non-list payloads', () {
      for (final input in <dynamic>[
        null,
        'malformed',
        123,
        <dynamic>[],
        {'clingiest': null},
        {'clingiest': 'not-a-list'},
        {
          'clingiest': [null, 'not-a-group', 1],
        },
      ]) {
        expect(
          () => parseAccountSections(Json(input)),
          returnsNormally,
          reason: 'input: $input',
        );
        expect(parseAccountSections(Json(input)), isEmpty, reason: '$input');
      }
    });

    test('does not treat a missing status as maintenance', () {
      final account = parseAccountSections(
        Json({
          'clingiest': [
            {
              'pater': 'Bank',
              'jambes': [
                {'hoover': 'bind-1'},
              ],
            },
          ],
        }),
      ).single.accounts.single;

      expect(account.isUnderMaintenance, isFalse);
    });

    test('treats only exact numeric zero statuses as maintenance', () {
      final expectations = <dynamic, bool>{
        0: true,
        '0': true,
        '0.0': true,
        false: false,
        0.5: false,
        -0.5: false,
        1: false,
      };

      for (final entry in expectations.entries) {
        final account = parseAccountSections(
          Json({
            'clingiest': [
              {
                'pater': 'Bank',
                'jambes': [
                  {'hoover': 'bind-1', 'precolonial': entry.key},
                ],
              },
            ],
          }),
        ).single.accounts.single;

        expect(
          account.isUnderMaintenance,
          entry.value,
          reason: 'status: ${entry.key}',
        );
      }
    });

    test('returns unmodifiable section and account lists', () {
      final sections = parseAccountSections(
        Json({
          'clingiest': [
            {
              'pater': 'Bank',
              'jambes': [
                {'hoover': 'bind-1'},
              ],
            },
          ],
        }),
      );

      expect(
        () => sections.add(sections.single),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => sections.single.accounts.clear(),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
