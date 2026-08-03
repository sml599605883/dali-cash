import '../../core/json/json.dart';

abstract final class DaliWebViewContract {
  static const handler = 'ph_dali_cash_ios';
}

abstract final class DaliWebViewActions {
  static const uploadRisk = 'dali_cash_RbGtlAKg2Hsx7x5';
  static const openGooglePlay = 'dali_cash_HjU4mCaWf9VcOI6';
  static const openUrl = 'dali_cash_dudAaHWAtJmjS2T';
  static const close = 'dali_cash_jWPoDsrg054lhUC';
  static const home = 'dali_cash_Ax2ivGQo70e2KIR';
  static const grade = 'dali_cash_L9ePULguB5v2O84';
  static const retryOrder = 'dali_cash_U5sqmkouwbyYVRT';
  static const changeAccount = 'dali_cash_dzaSV8NeJkdm0di';
  static const publicParams = 'dali_cash_YDtfWHIcQnY8cfk';
}

class DaliWebViewRequest {
  const DaliWebViewRequest({
    required this.action,
    required this.callbackId,
    required this.data,
    required this.rawData,
  });

  factory DaliWebViewRequest.decode(Object? message) {
    final decoded = message is String ? Json.parse(message).value : message;
    final source = Json(decoded).rawMapValue;
    final rawData = source['data'] ?? source['payload'] ?? source['params'];
    return DaliWebViewRequest(
      action: _firstString(source, const ['action', 'name']),
      callbackId: _firstString(source, const ['callbackId', 'callback', 'id']),
      data: _dataMap(rawData),
      rawData: rawData,
    );
  }

  final String action;
  final String callbackId;
  final Map<String, dynamic> data;
  final Object? rawData;

  bool get expectsCallback => callbackId.isNotEmpty;

  String get rawDataString {
    final value = rawData;
    return value is String ? value.trim() : Json(value).stringValue.trim();
  }

  static String _firstString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = Json(source[key]).stringValue.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static Map<String, dynamic> _dataMap(Object? rawData) {
    if (rawData is String) {
      return Json.parse(rawData).rawMapValue;
    }
    return Json(rawData).rawMapValue;
  }
}

class DaliWebViewResult {
  const DaliWebViewResult({
    required this.code,
    required this.message,
    this.data,
  });

  const DaliWebViewResult.success([Object? data])
    : this(code: 0, message: 'success', data: data);

  const DaliWebViewResult.failure(String message, {int code = -1})
    : this(code: code, message: message);

  final int code;
  final String message;
  final Object? data;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'message': message,
    'data': data ?? <String, dynamic>{},
  };
}
