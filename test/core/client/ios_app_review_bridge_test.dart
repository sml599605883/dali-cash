import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS bridge requests StoreKit review in the foreground scene', () {
    final registrar = File(
      'ios/Runner/ClientBridgeRegistrar.swift',
    ).readAsStringSync();

    expect(registrar, contains('import StoreKit'));
    expect(registrar, contains('case "requestAppReview"'));
    expect(registrar, contains('self.requestAppReview(result: result)'));
    expect(registrar, contains('activationState == .foregroundActive'));
    expect(
      registrar,
      contains('SKStoreReviewController.requestReview(in: scene)'),
    );
    expect(registrar, contains('SKStoreReviewController.requestReview()'));
  });
}
