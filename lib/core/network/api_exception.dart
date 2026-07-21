import 'package:dio/dio.dart';

class ApiBusinessException implements Exception {
  ApiBusinessException(this.message, {this.code});

  final String message;
  final Object? code;

  @override
  String toString() => message;
}

abstract final class ApiErrorMessage {
  static String resolve(Object? error) {
    if (error == null) {
      return 'Network error';
    }
    if (error is ApiBusinessException) {
      return error.message;
    }
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'Request timed out',
        DioExceptionType.connectionError => 'Network connection failed',
        _ => error.message ?? 'Network error',
      };
    }
    return error.toString();
  }
}
