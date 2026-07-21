import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/home/home_data.dart';
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
  });
}
