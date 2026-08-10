import 'dart:async';
import 'dart:convert';

import 'package:dali_cash/core/client/client_bridge.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_crypto.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/report/dali_report_data.dart';
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
  late String pushToken;
  late String trackingStatus;

  setUp(() {
    api = FakeDaliApi();
    events = StreamController<Json>.broadcast();
    pushToken = 'push-token';
    trackingStatus = 'authorized';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getReportDeviceSnapshot':
              return <String, Object?>{
                'idfv': 'idfv-1',
                'idfa': '',
                'riskDeviceId': 'risk-1',
                'model': 'iPhone17,1',
                'screenSize': '',
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
              return pushToken;
            case 'getTrackingStatus':
              return trackingStatus;
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
    trackingStatus = 'denied';

    await service.reportGoogleMarket();
    await service.reportGoogleMarket();

    expect(api.marketCalls, 2);
    expect(api.marketIdfas, ['', '']);
    expect(api.adjustTokens, ['adjust-token']);
  });

  test('startup clears location cached by the previous app run', () async {
    await service.store.saveLocation(
      const DaliLocationSnapshot(
        latitude: '10',
        longitude: '20',
        city: 'Previous city',
      ),
    );

    await service.start();
    await service.start();

    expect(await service.store.cachedLocation(), isNull);
  });

  test(
    'startup waits for a final tracking status before Market report',
    () async {
      trackingStatus = 'not_determined';

      await service.start();
      events.add(
        Json(const <String, dynamic>{
          'type': 'tracking_status_changed',
          'status': 'not_determined',
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(api.marketCalls, 0);

      trackingStatus = 'authorized';
      events.add(
        Json(const <String, dynamic>{
          'type': 'tracking_status_changed',
          'status': 'authorized',
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(api.marketCalls, 1);

      events.add(
        Json(const <String, dynamic>{
          'type': 'tracking_status_changed',
          'status': 'denied',
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(api.marketCalls, 1);
    },
  );

  test('permission completion reports once and closes event waiting', () async {
    trackingStatus = 'not_determined';
    await service.start();
    expect(api.marketCalls, 0);

    trackingStatus = 'denied';
    await service.reportGoogleMarket();
    expect(api.marketCalls, 1);

    events.add(
      Json(const <String, dynamic>{
        'type': 'tracking_status_changed',
        'status': 'authorized',
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(api.marketCalls, 1);
  });

  test('resume does not trigger another Google Market report', () async {
    await service.start();
    await Future<void>.delayed(Duration.zero);
    expect(api.marketCalls, 1);

    await service.resumed();
    events.add(
      Json(const <String, dynamic>{
        'type': 'tracking_status_changed',
        'status': 'authorized',
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(api.marketCalls, 1);
  });

  test('startup token event uploads once', () async {
    await service.start();
    events.add(Json(const <String, dynamic>{'type': 'push_token'}));
    await Future<void>.delayed(Duration.zero);

    expect(api.pushCalls, 1);
  });

  test('empty push token is still reported after permission denial', () async {
    pushToken = '';

    await service.reportAppleToken();

    expect(api.pushTokens, ['']);
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
    await api.config.sessionStore.saveDeviceInfo(
      deviceName: 'iPhone 16 Pro',
      physicalSize: '6.3',
    );
    await service.reportLocationAndDevice();

    expect(api.locationCalls, 1);
    expect(api.deviceCalls, 1);
    expect(api.devicePayload, isNotEmpty);
    final payload =
        jsonDecode(
              ApiCrypto(
                key: api.config.encryptKey,
                iv: api.config.encryptIv,
              ).decryptText(api.devicePayload),
            )
            as Map<String, dynamic>;
    expect(payload['hesitate'].containsKey('droplet'), isFalse);
    expect(payload['hesitate']['bellow'], 'iPhone 16 Pro');
    expect(payload['hesitate']['beachwear'], '6.3');
  });

  test('location upload failure does not block device details', () async {
    await api.config.sessionStore.saveSessionId('session-1');
    api.failLocationReport = true;

    await service.reportLocationAndDevice();

    expect(api.locationCalls, 1);
    expect(api.deviceCalls, 1);
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

  test('TrustDecision report serializes the complete native result', () async {
    await service.reportTrustDecisionResult(_cancelledLiveness);

    expect(api.trustDecisionLivenessId, '');
    expect(api.trustDecisionRequestId, 'sequence-42');
    expect(api.trustDecisionResultCode, '3001');
    expect(jsonDecode(api.trustDecisionResult), {
      'livenessId': '',
      'requestId': 'sequence-42',
      'resultCode': '3001',
      'resultMessage': 'Liveness cancelled',
    });
  });

  test('TrustDecision endpoint failure does not escape the service', () async {
    api.failTrustDecisionReport = true;

    await service.reportTrustDecisionResult(_cancelledLiveness);

    expect(api.trustDecisionCalls, 1);
  });
}

const _cancelledLiveness = TrustDecisionLivenessResult(
  success: false,
  code: 3001,
  message: 'Liveness cancelled',
  image: '',
  sequenceId: 'sequence-42',
  livenessId: '',
  raw: <String, dynamic>{},
);

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
  final List<String> pushTokens = [];
  int locationCalls = 0;
  bool failLocationReport = false;
  int deviceCalls = 0;
  String devicePayload = '';
  String riskScene = '';
  String riskOrderNo = '';
  String riskStartTime = '';
  String riskEndTime = '';
  int trustDecisionCalls = 0;
  bool failTrustDecisionReport = false;
  String trustDecisionLivenessId = '';
  String trustDecisionRequestId = '';
  String trustDecisionResultCode = '';
  String trustDecisionResult = '';
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
    if (failLocationReport) throw StateError('location report failed');
    return _success();
  }

  @override
  Future<ApiResponse> reportDeviceInfo({
    required String encryptedPayload,
  }) async {
    deviceCalls++;
    devicePayload = encryptedPayload;
    return _success();
  }

  @override
  Future<ApiResponse> reportApplePushToken({required String token}) async {
    pushCalls++;
    pushTokens.add(token);
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

  @override
  Future<ApiResponse> reportTrustDecisionResult({
    required String livenessId,
    required String requestId,
    required String resultCode,
    required String result,
  }) async {
    trustDecisionCalls++;
    trustDecisionLivenessId = livenessId;
    trustDecisionRequestId = requestId;
    trustDecisionResultCode = resultCode;
    trustDecisionResult = result;
    if (failTrustDecisionReport) throw StateError('report failed');
    return _success();
  }

  ApiResponse _success() => ApiResponse(
    code: 0,
    message: 'success',
    states: Json(const <String, dynamic>{}),
  );
}
