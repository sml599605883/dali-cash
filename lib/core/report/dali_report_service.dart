import 'dart:async';
import 'dart:convert';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:flutter/foundation.dart';

import '../client/client_bridge.dart';
import '../json/json.dart';
import '../network/api_client.dart';
import 'dali_report_data.dart';
import 'dali_report_store.dart';

class DaliReportService {
  DaliReportService(
    this.client, {
    DaliReportStore? store,
    Stream<Json>? nativeEvents,
    int Function()? nowMillis,
    Future<void> Function(String token)? initializeAdjust,
  }) : store = store ?? DaliReportStore(),
       _events = nativeEvents,
       _nowMillis = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch),
       _initializeAdjust = initializeAdjust ?? _startAdjust;

  static DaliReportService? current;

  static DaliReportService configure(ApiClient client) {
    return current ??= DaliReportService(client);
  }

  static int nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final ApiClient client;
  final DaliReportStore store;
  final Stream<Json>? _events;
  final int Function() _nowMillis;
  final Future<void> Function(String token) _initializeAdjust;

  bool _started = false;
  bool _starting = false;
  bool _marketReporting = false;
  bool _waitingForTrackingDecision = false;
  bool _startupGoogleReportTriggered = false;
  bool _adjustInitializing = false;
  final Set<String> _reportingAppleTokens = <String>{};
  final Set<String> _reportedAppleTokens = <String>{};
  Future<DaliLocationSnapshot?>? _pendingLocation;
  StreamSubscription<Json>? _eventSubscription;

  Future<void> start() async {
    if (_started || _starting) return;
    _starting = true;
    try {
      await store.clearSessionReportState();
      final isFirstLaunch = await store.markAppOpened();
      _listenToNativeEvents();
      _waitingForTrackingDecision = isFirstLaunch;
      _started = true;
      if (!isFirstLaunch) unawaited(_reportStartupGoogleMarket());
      unawaited(reportLocationAndDevice());
    } catch (error) {
      _log(error);
    } finally {
      _starting = false;
    }
  }

  Future<void> resumed() async {}

  Future<void> startupPermissionsResolved() async {
    await _reportStartupGoogleMarket();
    await reportAppleToken();
  }

  Future<void> loginSucceeded() async {
    await store.saveLoginAt(_nowMillis());
    unawaited(reportGoogleMarket());
    unawaited(reportLocationAndDevice());
    unawaited(_reportAppleToken(force: true));
  }

  Future<DaliLocationSnapshot?> currentLocation() {
    final pending = _pendingLocation;
    if (pending != null) return pending;
    final request = _loadLocation();
    _pendingLocation = request;
    return request.whenComplete(() => _pendingLocation = null);
  }

  Future<DaliLocationSnapshot?> _loadLocation() async {
    try {
      final location = await client.config.clientBridge.getReportLocation();
      if (location == null || !location.isValid) return null;
      await store.saveLocation(location);
      return location;
    } catch (error) {
      _log(error);
      return null;
    }
  }

  Future<DaliLocationSnapshot?> _locationWithFallback() async {
    try {
      final location = await currentLocation().timeout(
        const Duration(seconds: 3),
      );
      if (location != null && location.isValid) return location;
    } catch (_) {}
    return store.cachedLocation();
  }

  Future<bool> _hasSession() async =>
      (await client.config.sessionStore.sessionId()).trim().isNotEmpty;

  Future<void> reportLocationAndDevice() async {
    try {
      if (!await _hasSession()) return;
      final location = await _locationWithFallback();
      if (location != null && location.isValid) {
        try {
          await client.reportLocation(
            province: location.province,
            countryCode: location.countryCode,
            country: location.country,
            street: location.street,
            latitude: location.latitude,
            longitude: location.longitude,
            city: location.city,
          );
        } catch (error) {
          _log(error);
        }
      }
      await reportDevice();
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportGoogleMarket() async {
    final trackingStatus = await client.config.clientBridge.getTrackingStatus();
    if (!_isResolvedTrackingStatus(trackingStatus)) return;
    _waitingForTrackingDecision = false;
    await _reportResolvedGoogleMarket();
  }

  Future<void> _reportStartupGoogleMarket() async {
    if (_startupGoogleReportTriggered) return;
    final trackingStatus = await client.config.clientBridge.getTrackingStatus();
    if (!_isResolvedTrackingStatus(trackingStatus)) return;
    _startupGoogleReportTriggered = true;
    _waitingForTrackingDecision = false;
    await _reportResolvedGoogleMarket();
  }

  Future<void> _reportResolvedGoogleMarket() async {
    if (_marketReporting) return;
    _marketReporting = true;
    try {
      final snapshot = await client.config.clientBridge
          .getReportDeviceSnapshot();
      if (daliReportText(snapshot.idfv).isEmpty) return;
      final response = await client.reportGoogleMarket(
        idfv: snapshot.idfv,
        idfa: snapshot.idfa,
      );
      final token = daliReportText(response.states['musher'].stringOrNull);
      if (token.isEmpty ||
          _adjustInitializing ||
          await store.isAdjustInitialized()) {
        return;
      }
      _adjustInitializing = true;
      try {
        await _initializeAdjust(token);
        await store.markAdjustInitialized();
      } finally {
        _adjustInitializing = false;
      }
    } catch (error) {
      _log(error);
    } finally {
      _marketReporting = false;
    }
  }

  Future<void> reportDevice() async {
    try {
      if (!await _hasSession()) return;
      final snapshot = await client.config.clientBridge
          .getReportDeviceSnapshot();
      final encrypted = encryptDaliDeviceReport(
        snapshot: snapshot,
        deviceModel: await client.config.sessionStore.deviceName(),
        physicalSize: await client.config.sessionStore.physicalSize(),
        location: await _locationWithFallback(),
        lastLoginAtMillis: await store.loginAt(),
        nowMillis: _nowMillis(),
        key: client.config.encryptKey,
        iv: client.config.encryptIv,
      );
      await client.reportDeviceInfo(encryptedPayload: encrypted);
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportAppleToken() async {
    await _reportAppleToken(force: false);
  }

  Future<void> _reportAppleToken({required bool force}) async {
    String? token;
    try {
      token = (await client.config.clientBridge.getPushToken()).trim();
      if ((!force && _reportedAppleTokens.contains(token)) ||
          !_reportingAppleTokens.add(token)) {
        return;
      }
      await client.reportApplePushToken(token: token);
      _reportedAppleTokens.add(token);
    } catch (error) {
      _log(error);
    } finally {
      if (token != null) _reportingAppleTokens.remove(token);
    }
  }

  Future<void> reportRisk({
    required String productId,
    required String scene,
    String orderNo = '',
    required int startedAtSeconds,
  }) async {
    try {
      final snapshot = await client.config.clientBridge
          .getReportDeviceSnapshot();
      final location = await _locationWithFallback();
      final resolvedOrderNo = orderNo.trim().isNotEmpty
          ? orderNo.trim()
          : client.config.sessionStore.productDetailOrderNo().trim();
      await client.reportRiskBehavior(
        productId: productId.trim(),
        sceneType: scene.trim(),
        orderNo: resolvedOrderNo,
        riskDeviceId: daliReportText(snapshot.riskDeviceId),
        idfa: daliReportText(snapshot.idfa),
        longitude: daliReportText(location?.longitude),
        latitude: daliReportText(location?.latitude),
        startTime: '$startedAtSeconds',
        endTime: '${_nowMillis() ~/ 1000}',
      );
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportTrustDecisionResult(
    TrustDecisionLivenessResult result,
  ) async {
    try {
      final resultCode = '${result.code}';
      await client.reportTrustDecisionResult(
        livenessId: result.livenessId,
        requestId: result.sequenceId,
        resultCode: resultCode,
        result: jsonEncode({
          'livenessId': result.livenessId,
          'requestId': result.sequenceId,
          'resultCode': resultCode,
          'resultMessage': result.message,
        }),
      );
    } catch (error) {
      _log(error);
    }
  }

  void _listenToNativeEvents() {
    final events = _events ?? client.config.clientBridge.reportEvents();
    _eventSubscription ??= events.listen((event) {
      final type = event['type'].stringValue;
      if (type == 'push_token') unawaited(reportAppleToken());
      if (type == 'tracking_status_changed' && _waitingForTrackingDecision) {
        final status = event['status'].stringValue;
        if (!_isResolvedTrackingStatus(status)) return;
        _waitingForTrackingDecision = false;
        if (_startupGoogleReportTriggered) return;
        _startupGoogleReportTriggered = true;
        unawaited(_reportResolvedGoogleMarket());
      }
    }, onError: _log);
  }

  bool _isResolvedTrackingStatus(String status) {
    final normalized = status.trim();
    return normalized.isNotEmpty && normalized != 'not_determined';
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  static Future<void> _startAdjust(String token) async {
    final config = AdjustConfig(token, AdjustEnvironment.production)
      ..logLevel = AdjustLogLevel.info;
    Adjust.initSdk(config);
  }

  static void _log(Object error) {
    debugPrint('[DaliReport] ${error.runtimeType}: $error');
  }
}
