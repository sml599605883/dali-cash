import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:dali_cash/features/progress/progress_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatHomeAmount', () {
    test('groups only strictly unformatted ASCII numeric amounts', () {
      expect(formatHomeAmount('88888'), '88,888');
      expect(formatHomeAmount('88888.00'), '88,888.00');
    });

    test('groups known Philippine currency prefixes and preserves spacing', () {
      expect(formatHomeAmount('₱88888'), '₱88,888');
      expect(formatHomeAmount('PHP88888'), 'PHP88,888');
      expect(formatHomeAmount('PHP 88888.00'), 'PHP 88,888.00');
      expect(formatHomeAmount('PHP   88888.00'), 'PHP   88,888.00');
    });

    test('preserves existing separators and unsupported currency text', () {
      for (final value in <String>[
        '₱60,000',
        'PHP 1.234,56',
        'USD 88888.00',
        'Amount 88888',
        ' 88888.00 ',
      ]) {
        expect(formatHomeAmount(value), value, reason: value);
      }
    });
  });

  group('HomeData.fromJson', () {
    test('maps the complete documented home payload', () {
      final data = HomeData.fromJson(
        Json({
          'clingiest': [
            {
              'sociologeses': 'Coleseeds',
              'jambes': [
                {
                  'underfeeding': 'banner-1',
                  'ephemeras': 'https://example.com/banner.png',
                  'millipede': 'https://example.com/promo',
                },
              ],
            },
            {
              'sociologeses': 'QuininaSpeculation',
              'jambes': [
                {
                  'underfeeding': 'loan-1',
                  'preslaughter': 'Dali Cash',
                  'creasing': 'https://example.com/logo.png',
                  'adapting': 'PHP 1,234.56',
                  'hotel': 'Loan amount',
                  'telfered': '90 days',
                  'typefounder': 'Loan term',
                  'counterfeiters': '1.5% per month',
                  'euphonically': 'Interest rate',
                  'succumbs': [
                    {
                      'hypoblast': '2',
                      'redictates': 'Period',
                      'counterfeiters': '≤ 0.5% / Day',
                    },
                    {
                      'hypoblast': '3',
                      'redictates': 'Period',
                      'counterfeiters': '≤ 0.4% / Day',
                    },
                    {
                      'hypoblast': '4',
                      'redictates': 'Period',
                      'counterfeiters': '≤ 0.3% / Day',
                    },
                    {
                      'hypoblast': '5',
                      'redictates': 'Period',
                      'counterfeiters': '≤ 0.2% / Day',
                    },
                  ],
                  'weldor': 'Apply now',
                  'outgnaws': 'Complete authentication and unlock your loan',
                },
              ],
            },
            {
              'sociologeses': 'Apocalypse',
              'jambes': [
                {
                  'underfeeding': 'product-1',
                  'preslaughter': 'Quick Peso',
                  'creasing': 'https://example.com/product.png',
                  'adapting': 'PHP 5,000.00',
                  'hotel': 'Maximum amount',
                  'fishtailing': '2.0%',
                  'telfered': '120 days',
                  'finos': ['Fast approval', 'No collateral'],
                  'upscales': 42,
                },
              ],
            },
            {
              'sociologeses': 'PROCESS_LIST',
              'jambes': [
                {
                  'titled': 'order-1',
                  'highlands': 9,
                  'studdies': 'Server Cash',
                  'tricky': 'https://example.com/progress-logo.png',
                  'injective': 2000,
                  'betattered': 'Loan Amount',
                  'totalist': '28-12-2022',
                  'relativize': 'Application date',
                  'emblemize': 5,
                  'alternation': 'PHP 2,000.00',
                  'interterm': 'Disbursement Failed',
                  'millipede': 'dali://order/order-1',
                  'psychographs': [
                    {
                      'sociologeses': 'retry',
                      'deloused': 1,
                      'barbeque': 'Retry Original Account',
                      'rowboat': '',
                      'ailing': '',
                    },
                    {
                      'sociologeses': 'change',
                      'deloused': 0,
                      'barbeque': 'Change Account',
                      'rowboat': '',
                      'ailing': '',
                    },
                  ],
                },
              ],
            },
          ],
        }),
      );

      expect(data.banners, hasLength(1));
      expect(data.banners.single.id, 'banner-1');
      expect(data.banners.single.imageUrl, 'https://example.com/banner.png');
      expect(data.banners.single.targetUrl, 'https://example.com/promo');

      final loan = data.loanOffer!;
      expect(loan.productId, 'loan-1');
      expect(loan.productName, 'Dali Cash');
      expect(loan.productLogo, 'https://example.com/logo.png');
      expect(loan.amount, 'PHP 1,234.56');
      expect(loan.amountCaption, 'Loan amount');
      expect(loan.loanTerm, '90 days');
      expect(loan.loanTermCaption, 'Loan term');
      expect(loan.interestRate, '1.5% per month');
      expect(loan.interestRateCaption, 'Interest rate');
      expect(loan.loanTermRows, hasLength(3));
      expect(loan.loanTermRows.first.leftText, '2Period');
      expect(loan.loanTermRows.last.rightText, '≤ 0.3% / Day');
      expect(loan.buttonText, 'Apply now');
      expect(
        loan.loanProcessText,
        'Complete authentication and unlock your loan',
      );

      final recommendation = data.recommendations.single;
      expect(recommendation.productId, 'product-1');
      expect(recommendation.productName, 'Quick Peso');
      expect(recommendation.productLogo, 'https://example.com/product.png');
      expect(recommendation.amount, 'PHP 5,000.00');
      expect(recommendation.amountCaption, 'Maximum amount');
      expect(recommendation.interestRate, '2.0%');
      expect(recommendation.loanTerm, '120 days');
      expect(recommendation.footer, 'Fast approval / No collateral');
      expect(recommendation.upscales, 42);

      final progress = data.progressItems.single;
      expect(progress.orderNumber, 'order-1');
      expect(progress.productId, '9');
      expect(progress.productName, 'Server Cash');
      expect(progress.productLogo, 'https://example.com/progress-logo.png');
      expect(progress.amount, 'PHP 2,000.00');
      expect(progress.amountLabel, 'Loan Amount');
      expect(progress.date, '28-12-2022');
      expect(progress.dateLabel, 'Application date');
      expect(progress.emblemize, ProgressEmblemize.disbursementFailed);
      expect(progress.statusLabel, 'Disbursement Failed');
      expect(progress.detailRoute, 'dali://order/order-1');
      expect(progress.actions, hasLength(1));
      expect(progress.actions.single.type, 'retry');
      expect(progress.actions.single.label, 'Retry Original Account');
    });

    test('converts numeric string fields through Json.stringValue', () {
      final data = HomeData.fromJson(
        Json({
          'clingiest': [
            {
              'sociologeses': 'QuininaSpeculation',
              'jambes': [
                {'underfeeding': 42, 'preslaughter': 7, 'adapting': 5000},
              ],
            },
          ],
        }),
      );

      expect(data.loanOffer?.productId, '42');
      expect(data.loanOffer?.productName, '7');
      expect(data.loanOffer?.amount, '5000');
    });

    test('shows Credit Activation Progress only for non-empty lyings', () {
      for (final value in <dynamic>[
        'identity',
        <dynamic>['identity'],
        <String, dynamic>{'step': 'identity'},
        1,
      ]) {
        final data = HomeData.fromJson(Json({'lyings': value}));
        expect(data.showCreditActivationProgress, isTrue, reason: '$value');
      }

      for (final value in <dynamic>[
        null,
        '',
        '   ',
        <dynamic>[],
        <String, dynamic>{},
      ]) {
        final data = HomeData.fromJson(Json({'lyings': value}));
        expect(data.showCreditActivationProgress, isFalse, reason: '$value');
      }
    });

    test('prioritizes the first LARGE_CARD over SMALL_CARD', () {
      final data = HomeData.fromJson(
        Json({
          'clingiest': [
            {
              'sociologeses': 'Rattons',
              'jambes': [
                {'underfeeding': 'small-first'},
              ],
            },
            {
              'sociologeses': 'QuininaSpeculation',
              'jambes': [
                {'underfeeding': 'large-first'},
                {'underfeeding': 'large-second'},
              ],
            },
          ],
        }),
      );

      expect(data.loanOffer?.productId, 'large-first');
    });

    test('falls back to the first SMALL_CARD when LARGE_CARD has no items', () {
      final data = HomeData.fromJson(
        Json({
          'clingiest': [
            {'sociologeses': 'QuininaSpeculation', 'jambes': <dynamic>[]},
            {
              'sociologeses': 'Rattons',
              'jambes': [
                {'underfeeding': 'small-first'},
              ],
            },
          ],
        }),
      );

      expect(data.loanOffer?.productId, 'small-first');
    });

    test('returns safe empty values for malformed and unknown sections', () {
      final inputs = <dynamic>[
        null,
        'not-a-map',
        {'clingiest': 'not-a-list'},
        {
          'clingiest': [
            null,
            'not-a-section',
            {'sociologeses': 123, 'jambes': 'not-a-list'},
            {
              'sociologeses': 'UNKNOWN',
              'jambes': [
                {'underfeeding': 'ignored'},
              ],
            },
          ],
        },
      ];

      for (final input in inputs) {
        expect(
          () => HomeData.fromJson(Json(input)),
          returnsNormally,
          reason: 'input: $input',
        );
        final data = HomeData.fromJson(Json(input));
        expect(data.loanOffer, isNull);
        expect(data.banners, isEmpty);
        expect(data.recommendations, isEmpty);
      }
    });

    test('joins only non-empty trimmed recommendation tags', () {
      final data = HomeData.fromJson(
        Json({
          'clingiest': [
            {
              'sociologeses': 'Apocalypse',
              'jambes': [
                {
                  'finos': ['  Fast approval  ', '', '   ', 7, null, 'Secure'],
                },
              ],
            },
          ],
        }),
      );

      expect(data.recommendations.single.footer, 'Fast approval / Secure');
    });

    test(
      'ignores malformed progress items and falls back to numeric amount',
      () {
        final data = HomeData.fromJson(
          Json({
            'clingiest': [
              {
                'sociologeses': 'PROCESS_LIST',
                'jambes': [
                  null,
                  'not-a-map',
                  {'injective': 1234, 'emblemize': 2},
                ],
              },
            ],
          }),
        );

        expect(data.progressItems, hasLength(1));
        expect(data.progressItems.single.amount, '1234');
        expect(
          data.progressItems.single.emblemize,
          ProgressEmblemize.activeLoan,
        );
      },
    );
  });
}
