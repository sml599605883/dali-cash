import 'package:flutter_test/flutter_test.dart';

import 'test_main_binding.dart';

void main() {
  test('blocks dialog transport locally with the sentinel error', () async {
    final client = NoNetworkApiClient();

    await expectLater(
      client.dialog(scene: 1),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          'Unexpected network transport in widget test',
        ),
      ),
    );
  });
}
