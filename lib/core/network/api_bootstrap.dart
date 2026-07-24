import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../client/client_bridge.dart';
import '../device/device_info_sync.dart';
import '../session/session_store.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'api_exception.dart';

Future<ApiClient> bootstrapApiClient({
  ClientBridge? clientBridge,
  ApiConfig? apiConfig,
  SessionStore? sessionStore,
  Dio? dio,
  String? proxyHost,
  int? proxyPort,
}) async {
  debugPrint('[DaliNetworkDiag] bootstrap started');
  final bridge = clientBridge ?? apiConfig?.clientBridge ?? ClientBridge();
  final config = apiConfig ?? ApiConfig(clientBridge: bridge);
  final store = sessionStore ?? config.sessionStore;
  config
    ..clientBridge = bridge
    ..sessionStore = store;
  final client = ApiClient(config, dio: dio);
  final overrideHost = proxyHost ?? const String.fromEnvironment('PROXY_HOST');
  final overridePort =
      proxyPort ??
      int.tryParse(const String.fromEnvironment('PROXY_PORT')) ??
      0;

  if (_canApplyProxy(overrideHost, overridePort)) {
    debugPrint(
      '[DaliNetworkDiag] using override proxy $overrideHost:$overridePort',
    );
    client.setProxy(
      host: overrideHost,
      port: overridePort,
      allowBadCertificates: true,
    );
  } else {
    try {
      debugPrint('[DaliNetworkDiag] requesting system proxy settings');
      final settings = await bridge.getProxySettings();
      debugPrint(
        '[DaliNetworkDiag] system proxy enabled=${settings.enabled} '
        'host=${settings.host} port=${settings.port}',
      );
      if (settings.canApply) {
        client.setProxy(
          host: settings.host,
          port: settings.port,
          allowBadCertificates: true,
        );
      }
    } catch (error) {
      debugPrint(
        '[DaliNetworkDiag] proxy discovery failed: '
        '${error.runtimeType}: $error',
      );
      // Proxy discovery is best-effort and must not block app startup.
    }
  }

  debugPrint('[DaliNetworkDiag] base URL bootstrap started');
  final networkAvailable = await client.bootstrapBaseUrls();
  if (!networkAvailable) {
    throw ApiBusinessException('Network connection failed');
  }
  debugPrint('[DaliNetworkDiag] base URL bootstrap completed');

  debugPrint('[DaliNetworkDiag] device info sync started');
  await DeviceInfoSync(
    apiClient: client,
    clientBridge: bridge,
    store: store,
  ).sync();
  debugPrint('[DaliNetworkDiag] bootstrap completed');
  return client;
}

bool _canApplyProxy(String host, int port) => host.isNotEmpty && port > 0;
