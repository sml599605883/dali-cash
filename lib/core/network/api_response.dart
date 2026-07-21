import '../json/json.dart';
import 'api_exception.dart';
import 'api_protocol.dart';

class ApiResponse {
  const ApiResponse({
    required this.code,
    required this.message,
    required this.states,
  });

  static const invalidFormatCode = -900001;

  final int code;
  final String message;
  final Json states;

  bool get isSuccess => ApiProtocol.successCodes.contains(code);

  bool get isAuthExpired => code == ApiProtocol.authExpiredCode;

  static ApiResponse fromRaw(Json json) {
    final map = json.rawMapOrNull;
    if (map == null) {
      return ApiResponse(
        code: invalidFormatCode,
        message: 'Invalid response format',
        states: Json(null),
      );
    }
    return ApiResponse(
      code: _parseCode(map[ApiProtocol.code]),
      message: json[ApiProtocol.message].stringValue,
      states: json[ApiProtocol.data],
    );
  }

  ApiResponse ensureSuccess() {
    if (isSuccess) {
      return this;
    }
    throw ApiBusinessException(
      message.isEmpty ? 'Request failed' : message,
      code: code,
    );
  }

  static int _parseCode(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? invalidFormatCode;
    }
    return invalidFormatCode;
  }
}
