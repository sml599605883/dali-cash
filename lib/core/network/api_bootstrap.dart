import 'package:dio/dio.dart';

import '../client/client_bridge.dart';
import '../device/device_info_sync.dart';
import '../session/session_store.dart';
import 'api_client.dart';
import 'api_config.dart';

Future<ApiClient> bootstrapApiClient({
  ClientBridge? clientBridge,
  ApiConfig? apiConfig,
  SessionStore? sessionStore,
  Dio? dio,
  String? proxyHost,
  int? proxyPort,
}) async {
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
    client.setProxy(
      host: overrideHost,
      port: overridePort,
      allowBadCertificates: true,
    );
  } else {
    try {
      final settings = await bridge.getProxySettings();
      if (settings.canApply) {
        client.setProxy(
          host: settings.host,
          port: settings.port,
          allowBadCertificates: true,
        );
      }
    } catch (_) {
      // Proxy discovery is best-effort and must not block app startup.
    }
  }

  await DeviceInfoSync(
    apiClient: client,
    clientBridge: bridge,
    store: store,
  ).sync();
  return client;
}

bool _canApplyProxy(String host, int port) => host.isNotEmpty && port > 0;
