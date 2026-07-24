import 'package:shared_preferences/shared_preferences.dart';

import '../client/client_bridge.dart';
import '../session/session_store.dart';

typedef CommonParamsProvider = Future<Map<String, dynamic>> Function();
typedef AuthExpiredHandler = Future<void> Function();
typedef TimestampProvider = int Function();
typedef RandomDigitsProvider = String Function(int length);

class ApiConfig {
  ApiConfig({
    this.apiBaseUrl = 'http://8.220.184.117/manlikely',
    this.webBaseUrl = 'http://8.220.184.117',
    this.remoteConfigUrl = '',
    this.signatureSecret = '56307ac78c816ee671dfe506c17eddc7',
    this.encryptKey = 'ba927fc9e96f9676',
    this.encryptIv = '16f7ddfc7aef7a2e',
    this.commonParamsProvider,
    ClientBridge? clientBridge,
    SessionStore? sessionStore,
    this.authExpiredHandler,
    this.timestampProvider,
    this.randomDigitsProvider,
  }) : clientBridge = clientBridge ?? ClientBridge(),
       _sessionStore = sessionStore;

  String apiBaseUrl;
  String webBaseUrl;
  String remoteConfigUrl;
  String signatureSecret;
  String encryptKey;
  String encryptIv;
  CommonParamsProvider? commonParamsProvider;
  ClientBridge clientBridge;
  SessionStore? _sessionStore;
  AuthExpiredHandler? authExpiredHandler;
  TimestampProvider? timestampProvider;
  RandomDigitsProvider? randomDigitsProvider;

  SessionStore get sessionStore {
    return _sessionStore ??= SessionStore(SharedPreferencesAsync());
  }

  set sessionStore(SessionStore value) {
    _sessionStore = value;
  }
}
