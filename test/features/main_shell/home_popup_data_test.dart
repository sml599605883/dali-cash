import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/main_shell/home_popup_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses upgrade response and normalizes version', () {
    final data = HomePopupData.fromResponse(
      Json({
        'sociologeses': 1,
        'rheologists': {
          'misapprehension': '1.1.4',
          'lowliness': 'Install the latest version.',
          'bloomeries': 'https://store.example.test/app',
        },
      }),
    );

    expect(data.type, HomePopupType.appUpgrade);
    expect(data.displayVersion, 'V1.1.4');
    expect(data.message, 'Install the latest version.');
    expect(data.shouldShow, isTrue);
  });

  test('parses marketing response and rejects incomplete image data', () {
    final data = HomePopupData.fromResponse(
      Json({
        'sociologeses': 3,
        'rheologists': {
          'mourningly': 'New product',
          'tanists': ' https://cdn.example.test/popup.png ',
          'bloomeries': 'https://h5.example.test/product',
        },
      }),
    );

    expect(data.type, HomePopupType.marketing);
    expect(data.imageUrl, 'https://cdn.example.test/popup.png');
    expect(data.shouldShow, isTrue);
    expect(
      HomePopupData.fromResponse(
        Json({
          'sociologeses': 3,
          'rheologists': {'tanists': ' '},
        }),
      ).shouldShow,
      isFalse,
    );
  });
}
