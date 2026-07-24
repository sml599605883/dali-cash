import 'dart:async';

import 'package:dali_cash/core/client/client_bridge.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/report/dali_report_service.dart';
import 'package:dali_cash/core/report/dali_report_store.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ClientBridge.channelName);
  late FakeDaliApi api;
  late StreamController<Json> events;
  late DaliReportService service;

  setUp(() {
    api = FakeDaliApi();
    events = StreamController<Json>.broadcast();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getReportDeviceSnapshot':
              return <String, Object?>{
                'idfv': 'idfv-1',
                'idfa': '',
                'riskDeviceId': 'risk-1',
                'systemVersion': '18.0',
                'packageName': 'com.dali.cash',
              };
            case 'getReportLocation':
              return <String, Object?>{
                'latitude': '14.5',
                'longitude': '121.0',
                'city': 'Makati',
              };
            case 'getPushToken':
              return 'push-token';
            default:
              return null;
          }
        });
    service = DaliReportService(
      api,
      store: DaliReportStore.memory(),
      nativeEvents: events.stream,
      nowMillis: () => 200000,
      initializeAdjust: (token) async => api.adjustTokens.add(token),
    );
  });

  tearDown(() async {
    await service.dispose();
    await events.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Google Market reports every trigger with empty IDFA', () async {
    await service.reportGoogleMarket();
    await service.reportGoogleMarket();

    expect(api.marketCalls, 2);
    expect(api.marketIdfas, ['', '']);
    expect(api.adjustTokens, ['adjust-token']);
  });

  test('startup token event uploads once', () async {
    await service.start();
    events.add(Json(const <String, dynamic>{'type': 'push_token'}));
    await Future<void>.delayed(Duration.zero);

    expect(api.pushCalls, 1);
  });

  test('login reports the current token every time', () async {
    await service.loginSucceeded();
    await service.loginSucceeded();
    await Future<void>.delayed(Duration.zero);

    expect(api.pushCalls, 2);
    expect(await service.store.loginAt(), 200000);
  });

  test('location and device reports require login', () async {
    await service.reportLocationAndDevice();
    expect(api.locationCalls, 0);
    expect(api.deviceCalls, 0);

    await api.config.sessionStore.saveSessionId('session-1');
    await service.reportLocationAndDevice();

    expect(api.locationCalls, 1);
    expect(api.deviceCalls, 1);
    expect(api.devicePayload, isNotEmpty);
  });

  test('risk report maps scene and resolves the stored order number', () async {
    await api.config.sessionStore.saveProductDetailOrderNo('order-1');
    await service.reportRisk(
      productId: 'product-1',
      scene: '4',
      startedAtSeconds: 100,
    );

    expect(api.riskScene, '4');
    expect(api.riskOrderNo, 'order-1');
    expect(api.riskStartTime, '100');
    expect(api.riskEndTime, '200');
  });
}

class FakeDaliApi extends ApiClient {
  FakeDaliApi()
    : super(
        ApiConfig(
          apiBaseUrl: 'http://api.test',
          commonParamsProvider: () async => const <String, dynamic>{},
          sessionStore: SessionStore.memory(),
          clientBridge: ClientBridge(platform: ClientPlatform.ios),
        ),
      );

  int marketCalls = 0;
  final List<String> marketIdfas = <String>[];
  final List<String> adjustTokens = <String>[];
  int pushCalls = 0;
  int locationCalls = 0;
  int deviceCalls = 0;
  String devicePayload = '';
  String riskScene = '';
  String riskOrderNo = '';
  String riskStartTime = '';
  String riskEndTime = '';
  @override
  Future<ApiResponse> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) async {
    marketCalls++;
    marketIdfas.add(idfa);
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(const <String, dynamic>{'musher': 'adjust-token'}),
    );
  }

  @override
  Future<ApiResponse> reportLocation({
    String? province,
    required String countryCode,
    required String country,
    required String street,
    required String latitude,
    required String longitude,
    required String city,
  }) async {
    locationCalls++;
    return _success();
  }

  @override
  Future<ApiResponse> reportDeviceInfo({required String encryptedPayload}) async {
    deviceCalls++;
    devicePayload = encryptedPayload;
    return _success();
  }

  @override
  Future<ApiResponse> reportApplePushToken({required String token}) async {
    pushCalls++;
    return _success();
  }

  @override
  Future<ApiResponse> reportRiskBehavior({
    required String productId,
    required String sceneType,
    required String orderNo,
    required String riskDeviceId,
    required String idfa,
    required String longitude,
    required String latitude,
    required String startTime,
    required String endTime,
  }) async {
    riskScene = sceneType;
    riskOrderNo = orderNo;
    riskStartTime = startTime;
    riskEndTime = endTime;
    return _success();
  }

  ApiResponse _success() => ApiResponse(
    code: 0,
    message: 'success',
    states: Json(const <String, dynamic>{}),
  );
}
