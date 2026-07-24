import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../json/json.dart';
import '../report/dali_report_data.dart';

enum ClientPlatform { ios, android, other }

class ClientPlatformInfo {
  const ClientPlatformInfo({
    required this.platform,
    required this.systemVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.deviceId,
  });

  factory ClientPlatformInfo.fromMap(Map<Object?, Object?> map) {
    return ClientPlatformInfo(
      platform: map['platform']?.toString() ?? '',
      systemVersion: map['systemVersion']?.toString() ?? '',
      appVersion: map['appVersion']?.toString() ?? '',
      buildNumber: map['buildNumber']?.toString() ?? '',
      deviceId: map['deviceId']?.toString() ?? '',
    );
  }

  final String platform;
  final String systemVersion;
  final String appVersion;
  final String buildNumber;
  final String deviceId;
}

class ClientProxySettings {
  const ClientProxySettings({
    required this.enabled,
    required this.host,
    required this.port,
  });

  factory ClientProxySettings.fromMap(Map<Object?, Object?> map) {
    final host = map['host']?.toString() ?? '';
    return ClientProxySettings(
      enabled: map['enabled'] == true && host.isNotEmpty,
      host: host,
      port: _intValue(map['port']),
    );
  }

  final bool enabled;
  final String host;
  final int port;

  bool get canApply => enabled && host.isNotEmpty && port > 0;

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }
}

class TrustDecisionLivenessResult {
  const TrustDecisionLivenessResult({
    required this.success,
    required this.code,
    required this.message,
    required this.image,
    required this.sequenceId,
    required this.livenessId,
    required this.raw,
  });

  final bool success;
  final int code;
  final String message;
  final String image;
  final String sequenceId;
  final String livenessId;
  final Map<String, dynamic> raw;
}

class ClientBridge {
  ClientBridge({
    ClientPlatform? platform,
    MethodChannel? channel,
    EventChannel? eventChannel,
  }) : _platform = platform ?? _currentPlatform(),
       _channel = channel ?? const MethodChannel(channelName),
       _eventChannel = eventChannel ?? const EventChannel(eventChannelName);

  static const channelName = 'dali_cash/client_bridge';
  static const eventChannelName = 'dali_cash/client_events';

  final ClientPlatform _platform;
  final MethodChannel _channel;
  final EventChannel _eventChannel;

  bool get supportsNativeBridge => _platform == ClientPlatform.ios;

  Future<ClientPlatformInfo> getPlatformInfo() async {
    if (!supportsNativeBridge) {
      throw UnsupportedError('Client bridge is currently implemented for iOS.');
    }
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getPlatformInfo',
    );
    return ClientPlatformInfo.fromMap(result ?? const <Object?, Object?>{});
  }

  Future<ClientProxySettings> getProxySettings() async {
    if (!supportsNativeBridge) {
      throw UnsupportedError('Proxy bridge is currently implemented for iOS.');
    }
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getProxySettings',
    );
    return ClientProxySettings.fromMap(result ?? const <Object?, Object?>{});
  }

  Future<TrustDecisionLivenessResult> showTrustDecisionLiveness(
    String license,
  ) async {
    if (!supportsNativeBridge) {
      return const TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: 'Liveness verification is only available on iOS.',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{},
      );
    }

    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'showTrustDecisionLiveness',
        license,
      );
      if (result == null) {
        return const TrustDecisionLivenessResult(
          success: false,
          code: -1,
          message: 'Liveness returned no result',
          image: '',
          sequenceId: '',
          livenessId: '',
          raw: <String, dynamic>{},
        );
      }
      final json = Json(result);
      return TrustDecisionLivenessResult(
        success: json['success'].boolOrNull ?? false,
        code: json['code'].intOrNull ?? -1,
        message: json['message'].stringValue,
        image: json['image'].stringValue,
        sequenceId: json['sequence_id'].stringValue,
        livenessId: json['liveness_id'].stringValue,
        raw: json['raw'].rawMapValue,
      );
    } on PlatformException catch (error) {
      return TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: error.message ?? 'Failed to start liveness verification',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{
          'code': error.code,
          if (error.details != null) 'details': error.details,
        },
      );
    } on MissingPluginException {
      return const TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: 'Liveness verification is unavailable.',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{},
      );
    }
  }

  Future<DaliLocationSnapshot?> getReportLocation() async {
    final result = await _safeInvokeMap('getReportLocation');
    if (result == null) return null;
    final location = DaliLocationSnapshot.fromMap(result);
    return location.isValid ? location : null;
  }

  Future<DaliDeviceSnapshot> getReportDeviceSnapshot() async {
    final result = await _safeInvokeMap('getReportDeviceSnapshot');
    return DaliDeviceSnapshot.fromMap(result ?? const <Object?, Object?>{});
  }

  Future<String> getPushToken() => _safeInvokeString('getPushToken');

  Future<String> getTrackingStatus() => _safeInvokeString('getTrackingStatus');

  Future<void> initializeAdjust(String token) async {
    if (!supportsNativeBridge || token.trim().isEmpty) return;
    try {
      await _channel.invokeMethod<void>('initializeAdjust', {
        'token': token.trim(),
      });
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Stream<Json> reportEvents() {
    if (!supportsNativeBridge) return const Stream<Json>.empty();
    return _eventChannel
        .receiveBroadcastStream()
        .map(Json.new)
        .handleError((_) {});
  }

  Future<Map<Object?, Object?>?> _safeInvokeMap(String method) async {
    if (!supportsNativeBridge) return null;
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<String> _safeInvokeString(String method) async {
    if (!supportsNativeBridge) return '';
    try {
      final value = await _channel.invokeMethod<Object?>(method);
      return value?.toString().trim() ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }

  static ClientPlatform _currentPlatform() {
    if (Platform.isIOS) {
      return ClientPlatform.ios;
    }
    if (Platform.isAndroid) {
      return ClientPlatform.android;
    }
    return ClientPlatform.other;
  }
}
