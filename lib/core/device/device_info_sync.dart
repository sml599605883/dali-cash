import 'package:flutter/services.dart';

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
    final platformInfo = await _platformInfo();
    final identifier = platformInfo?.platform ?? '';
    if (identifier.isEmpty) {
      return;
    }

    try {
      final response = await apiClient.getDeviceName(
        deviceIdentifier: identifier,
      );
      await store.saveDeviceInfo(
        deviceName: response.states['extravagates'].stringValue,
        physicalSize: response.states['beachwear'].stringValue,
      );
    } catch (_) {
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
