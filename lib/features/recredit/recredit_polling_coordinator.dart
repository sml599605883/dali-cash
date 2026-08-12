import 'dart:async';

import 'package:get/get.dart';

import '../../app/navigation/navigation_helper.dart';
import '../../app/routes/app_routes.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../main_shell/main_controller.dart';

typedef RecreditRequest = Future<ApiResponse> Function();
typedef RecreditRouteProvider = String Function();
typedef RecreditHomeRefresher = Future<void> Function();
typedef RecreditAdmissionRunner = Future<void> Function(String productId);
typedef RecreditLogger = void Function(String message);

class RecreditPollingCoordinator {
  RecreditPollingCoordinator({
    RecreditRequest? request,
    RecreditRouteProvider? currentRoute,
    RecreditHomeRefresher? homeRefresher,
    RecreditAdmissionRunner? admissionRunner,
    RecreditLogger? logger,
    this.interval = const Duration(seconds: 10),
  }) : _request = request ?? _defaultRequest,
       _currentRoute = currentRoute ?? _defaultCurrentRoute,
       _homeRefresher = homeRefresher ?? _defaultHomeRefresher,
       _admissionRunner = admissionRunner ?? _defaultAdmissionRunner,
       _logger = logger ?? NavigationHelper.defaultLogger;

  final RecreditRequest _request;
  final RecreditRouteProvider _currentRoute;
  final RecreditHomeRefresher _homeRefresher;
  final RecreditAdmissionRunner _admissionRunner;
  final RecreditLogger _logger;
  final Duration interval;

  Timer? _timer;
  String _productId = '';
  bool _isRequesting = false;
  bool _isRunning = false;
  int _generation = 0;

  bool get isRunning => _isRunning;

  void start(String productId) {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }
    _generation += 1;
    final generation = _generation;
    _productId = normalizedProductId;
    _isRunning = true;
    _isRequesting = false;
    _timer?.cancel();
    _timer = Timer(Duration.zero, () => _poll(generation));
  }

  void stop() {
    _generation += 1;
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isRequesting = false;
  }

  Future<void> _poll(int generation) async {
    if (!_isActive(generation) || _isRequesting) {
      return;
    }
    _isRequesting = true;
    late final ApiResponse response;
    try {
      response = await _request();
    } catch (_) {
      _scheduleRetry(generation);
      return;
    }
    if (!_isActive(generation)) {
      return;
    }
    if (response.states['tucking'].intValue == 1) {
      await _complete(generation);
      return;
    }
    _scheduleRetry(generation);
  }

  Future<void> _complete(int generation) async {
    if (!_isActive(generation)) {
      return;
    }
    late final String route;
    late final String productId;
    try {
      route = _currentRoute();
      productId = _productId;
    } catch (error) {
      stop();
      _logger('recredit completion failed: $error');
      return;
    }
    stop();
    try {
      if (route == AppRoutes.home) {
        await _homeRefresher();
      } else if (route == AppRoutes.recredit) {
        await _admissionRunner(productId);
      }
    } catch (error) {
      _logger('recredit completion failed: $error');
    }
  }

  void _scheduleRetry(int generation) {
    if (!_isActive(generation)) {
      return;
    }
    _isRequesting = false;
    _timer?.cancel();
    _timer = Timer(interval, () => _poll(generation));
  }

  bool _isActive(int generation) {
    return _isRunning && generation == _generation;
  }

  static Future<ApiResponse> _defaultRequest() {
    return Get.find<ApiClient>().reCredit();
  }

  static String _defaultCurrentRoute() => Get.currentRoute;

  static Future<void> _defaultHomeRefresher() async {
    if (Get.isRegistered<MainController>()) {
      await Get.find<MainController>().requestHomeDataIfVisible();
    }
  }

  static Future<void> _defaultAdmissionRunner(String productId) {
    return NavigationHelper.applyProductAfterRecredit(productId);
  }
}
