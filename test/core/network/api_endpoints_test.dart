import 'package:dali_cash/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes representative semantic endpoints', () {
    expect(ApiEndpoints.homePage, '/lutes/unsphered');
    expect(ApiEndpoints.sendSmsCode, '/lutes/diachronies');
    expect(ApiEndpoints.uploadImage, '/lutes/pertinencies');
    expect(ApiEndpoints.uploadDeviceInfo, '/lutes/outgnaws');
    expect(ApiEndpoints.orderList, '/lutes/telfered');
    expect(ApiEndpoints.personalInfo, '/lutes/allanites');
    expect(ApiEndpoints.savePersonalInfo, '/lutes/movables');
  });
}
