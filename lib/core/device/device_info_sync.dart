import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../client/client_bridge.dart';
import '../network/api_client.dart';
import '../session/session_store.dart';

class DeviceInfoSync {
  const DeviceInfoSync({
    required this.apiClient,
    required this.clientBridge,
    required this.store,
  });

  final ApiClient apiClient;
  final ClientBridge clientBridge;
  final SessionStore store;

  Future<void> sync() async {
    ClientPlatformInfo? platformInfo;
    try {
      debugPrint('[DaliNetworkDiag] requesting platform info');
      platformInfo = await _platformInfo();
      debugPrint(
        '[DaliNetworkDiag] platform info identifier=${platformInfo?.platform}',
      );
    } catch (error) {
      debugPrint(
        '[DaliNetworkDiag] platform info failed: '
        '${error.runtimeType}: $error',
      );
      rethrow;
    }
    final identifier = platformInfo?.platform ?? '';
    if (identifier.isEmpty) {
      return;
    }

    try {
      debugPrint('[DaliNetworkDiag] device API request started');
      final response = await apiClient.getDeviceName(
        deviceIdentifier: identifier,
      );
      await store.saveDeviceInfo(
        deviceName: response.states['extravagates'].stringValue,
        physicalSize: response.states['beachwear'].stringValue,
      );
      debugPrint('[DaliNetworkDiag] device API request completed');
    } catch (error) {
      debugPrint(
        '[DaliNetworkDiag] device API request failed: '
        '${error.runtimeType}: $error',
      );
      // Device metadata is best-effort and must not block app startup.
    }
  }

  Future<ClientPlatformInfo?> _platformInfo() async {
    if (!clientBridge.supportsNativeBridge) {
      return null;
    }
    try {
      return await clientBridge.getPlatformInfo();
    } on PlatformException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }
}
