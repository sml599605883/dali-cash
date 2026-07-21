import 'dart:io' show Platform;

import 'package:flutter/services.dart';

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

class ClientBridge {
  ClientBridge({ClientPlatform? platform, MethodChannel? channel})
    : _platform = platform ?? _currentPlatform(),
      _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'dali_cash/client_bridge';

  final ClientPlatform _platform;
  final MethodChannel _channel;

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
