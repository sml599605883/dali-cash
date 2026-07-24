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
}
