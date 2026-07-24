import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS re-signs the objective_c native asset for device installs', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(project, contains('NATIVE_ASSET_FRAMEWORK'));
    expect(project, contains('CODE_SIGNING_ALLOWED'));
    expect(project, contains('EXPANDED_CODE_SIGN_IDENTITY'));
    expect(
      project,
      contains(
        r'/usr/bin/codesign --force --sign \"$EXPANDED_CODE_SIGN_IDENTITY\"',
      ),
    );
  });
}
