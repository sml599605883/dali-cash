import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Info.plist declares every iOS permission purpose', () {
    final content = File('ios/Runner/Info.plist').readAsStringSync();

    expect(content, contains('NSCameraUsageDescription'));
    expect(content, contains('NSPhotoLibraryUsageDescription'));
    expect(content, contains('NSLocationWhenInUseUsageDescription'));
    expect(content, contains('NSUserTrackingUsageDescription'));
  });

  test('Podfile compiles permission handler features used by the app', () {
    final content = File('ios/Podfile').readAsStringSync();

    expect(content, contains('PERMISSION_CAMERA=1'));
    expect(content, contains('PERMISSION_LOCATION_WHENINUSE=1'));
    expect(content, contains('PERMISSION_NOTIFICATIONS=1'));
    expect(content, contains('PERMISSION_APP_TRACKING_TRANSPARENCY=1'));
  });

  test(
    'iOS bridge registers for APNs after notification permission resolves',
    () {
      final registrar = File(
        'ios/Runner/ClientBridgeRegistrar.swift',
      ).readAsStringSync();

      expect(registrar, contains('case "registerForRemoteNotifications":'));
      expect(
        registrar,
        contains('UIApplication.shared.registerForRemoteNotifications()'),
      );
    },
  );

  test(
    'iOS interrupts an older location permission callback before retrying',
    () {
      final registrar = File(
        'ios/Runner/ClientBridgeRegistrar.swift',
      ).readAsStringSync();

      expect(registrar, contains('previousResult("interrupted")'));
    },
  );

  test('iOS report location matches KL address field sources', () {
    final registrar = File(
      'ios/Runner/ClientBridgeRegistrar.swift',
    ).readAsStringSync();

    expect(registrar, contains('import Contacts'));
    expect(
      registrar,
      contains('"locality": placemark?.subAdministrativeArea ?? ""'),
    );
    expect(registrar, contains('"fullAddress": fullAddress(from: placemark)'));
    expect(registrar, contains('"street": street(from: placemark)'));
    expect(
      registrar,
      contains(
        '"city": placemark?.locality ?? placemark?.subAdministrativeArea ?? ""',
      ),
    );
    expect(registrar, contains('placemark.postalAddress?.street'));
    expect(registrar, contains('private func uniqueAddressParts('));
    expect(
      registrar,
      isNot(contains('"locality": placemark?.subLocality ?? ""')),
    );
  });
}
