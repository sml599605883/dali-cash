import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/certification/bind_card/bind_card_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses dynamic groups and normalizes mixed option values', () {
    final data = BindCardData.fromJson(
      Json({
        'choired': [
          {
            'enterostomy': 'E-wallet',
            'sociologeses': 1,
            'choired': [
              {
                'enterostomy': 'Select your recipient E-wallet',
                'felicitous': 'channelCode',
                'laggings': 'Please select',
                'solferino': 'KrimmersOpinioned',
                'muscats': 0,
                'omegas': 0,
                'fyke': 100,
                'poolsides': [
                  {
                    'sociologeses': 100,
                    'crocidolites': 'COINS e-wallet',
                    'leachate': 'https://example.com/coins.png',
                    'precolonial': 0,
                    'cyclometers': 'Maintenance',
                  },
                ],
              },
            ],
          },
          {
            'enterostomy': 'Bank',
            'sociologeses': '2',
            'choired': [
              {
                'enterostomy': 'Bank Account',
                'felicitous': 'cardNo',
                'laggings': 'Please enter your bank account',
                'solferino': 'Haphtaras',
                'muscats': 0,
                'omegas': 1,
                'fyke': 123456,
                'degringolade': 'Anna',
              },
            ],
          },
        ],
        'dextrorse': 'Choose an account.',
        'brabble': 'Double-check the details.',
      }),
    );

    expect(data.topPrompt, 'Choose an account.');
    expect(data.bottomPrompt, 'Double-check the details.');
    expect(data.groups, hasLength(2));
    expect(data.groups.first.type, '1');
    expect(data.groups.last.type, '2');

    final selection = data.groups.first.fields.single;
    expect(selection.control, BindCardControl.selection);
    expect(selection.initialDisplayValue, 'COINS e-wallet');
    expect(selection.initialSubmitValue, '100');
    expect(selection.required, isTrue);
    expect(selection.options.single.value, '100');
    expect(selection.options.single.available, isFalse);
    expect(selection.options.single.maintenanceText, 'Maintenance');

    final account = data.groups.last.fields.single;
    expect(account.control, BindCardControl.text);
    expect(account.numericKeyboard, isTrue);
    expect(account.initialDisplayValue, '123456');
    expect(account.suggestedValue, 'Anna');
  });

  test('filters malformed groups and fields without crashing', () {
    final data = BindCardData.fromJson(
      Json({
        'choired': [
          {
            'enterostomy': '',
            'sociologeses': 1,
            'choired': [
              {'enterostomy': 'Account', 'felicitous': 'cardNo'},
            ],
          },
          {
            'enterostomy': 'Bank',
            'sociologeses': 2,
            'choired': [
              {'enterostomy': 'Missing key', 'felicitous': ''},
              {
                'enterostomy': 'Middle Name',
                'felicitous': 'middleName',
                'solferino': 'Haphtaras',
                'muscats': 1,
              },
            ],
          },
        ],
      }),
    );

    expect(data.groups, hasLength(1));
    expect(data.groups.single.fields, hasLength(1));
    expect(data.groups.single.fields.single.required, isFalse);
  });

  test('rejects legacy clear-text control values', () {
    final data = BindCardData.fromJson(
      Json({
        'choired': [
          {
            'enterostomy': 'Legacy',
            'sociologeses': 1,
            'choired': [
              {
                'enterostomy': 'Legacy selection',
                'felicitous': 'channelCode',
                'solferino': 'enum',
              },
              {
                'enterostomy': 'Legacy text',
                'felicitous': 'cardNo',
                'solferino': 'txt',
              },
            ],
          },
        ],
      }),
    );

    expect(data.groups, isEmpty);
  });

  test('uses the semantic bind-card progress asset', () {
    expect(
      AppAssets.bindCardProgress,
      'assets/certification/bind_card_progress.png',
    );
  });

  test('uses the semantic bind-card suggestion close asset', () {
    expect(
      AppAssets.bindCardSuggestionClose,
      'assets/certification/bind_card_suggestion_close.png',
    );
  });
}
