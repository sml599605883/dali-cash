import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Dali response shell', () {
    final response = ApiResponse.fromRaw(
      Json({
        'felicitous': '00',
        'cuckoo': 'success',
        'unsphered': {'value': 1},
      }),
    );

    expect(response.code, 0);
    expect(response.message, 'success');
    expect(response.states['value'].intValue, 1);
    expect(response.isSuccess, isTrue);
  });

  test('accepts numeric and legacy success codes', () {
    expect(
      ApiResponse.fromRaw(
        Json({'felicitous': 0, 'cuckoo': '', 'unsphered': null}),
      ).isSuccess,
      isTrue,
    );
    expect(
      ApiResponse.fromRaw(
        Json({'felicitous': '20000', 'cuckoo': '', 'unsphered': null}),
      ).isSuccess,
      isTrue,
    );
  });

  test('detects auth expired response', () {
    final response = ApiResponse.fromRaw(
      Json({'felicitous': -2, 'cuckoo': 'Login expired', 'unsphered': null}),
    );

    expect(response.isAuthExpired, isTrue);
  });

  test('malformed payload becomes invalid response', () {
    final response = ApiResponse.fromRaw(Json('not a response map'));

    expect(response.code, ApiResponse.invalidFormatCode);
    expect(response.message, 'Invalid response format');
    expect(response.isSuccess, isFalse);
  });

  test('ensureSuccess throws server message', () {
    final response = ApiResponse.fromRaw(
      Json({
        'felicitous': 400,
        'cuckoo': 'Signature invalid',
        'unsphered': null,
      }),
    );

    expect(
      response.ensureSuccess,
      throwsA(
        isA<ApiBusinessException>()
            .having((error) => error.code, 'code', 400)
            .having((error) => error.message, 'message', 'Signature invalid'),
      ),
    );
  });
}
