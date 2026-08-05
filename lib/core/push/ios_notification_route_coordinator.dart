import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app/navigation/navigation_helper.dart';
import '../client/client_bridge.dart';
import '../json/json.dart';

typedef NativeNotificationEvents = Stream<Json> Function();
typedef NotificationNavigationReady = bool Function();
typedef NotificationRouteOpener = Future<void> Function(String route);
typedef NotificationRouteDeferrer = void Function(VoidCallback callback);

class IosNotificationRouteCoordinator {
  IosNotificationRouteCoordinator({
    NativeNotificationEvents? events,
    NotificationNavigationReady? navigationReady,
    NotificationRouteOpener? openRoute,
    NotificationRouteDeferrer? defer,
  }) : _events = events ?? ClientBridge.shared.reportEvents,
       _navigationReady = navigationReady ?? _isNavigationReady,
       _openRoute = openRoute ?? NavigationHelper.navigateRawTarget,
       _defer = defer ?? _deferUntilNextFrame;

  static final instance = IosNotificationRouteCoordinator();

  final NativeNotificationEvents _events;
  final NotificationNavigationReady _navigationReady;
  final NotificationRouteOpener _openRoute;
  final NotificationRouteDeferrer _defer;

  StreamSubscription<Json>? _subscription;
  Future<void> _deliveryChain = Future<void>.value();
  int _lifecycle = 0;

  void start() {
    if (_subscription != null) return;
    final lifecycle = ++_lifecycle;
    _subscription = _events().listen((event) => _accept(event, lifecycle));
  }

  Future<void> stop() async {
    _lifecycle++;
    await _subscription?.cancel();
    _subscription = null;
    _deliveryChain = Future<void>.value();
  }

  void _accept(Json event, int lifecycle) {
    if (event['type'].stringValue != 'push_route') return;
    final route = event['url'].stringValue.trim();
    if (route.isEmpty) return;
    _deliveryChain = _deliveryChain.then((_) => _deliver(route, lifecycle));
  }

  Future<void> _deliver(String route, int lifecycle) async {
    try {
      while (lifecycle == _lifecycle && !_navigationReady()) {
        await _nextFrame();
      }
      if (lifecycle == _lifecycle) await _openRoute(route);
    } catch (_) {}
  }

  static bool _isNavigationReady() => Get.context?.mounted ?? false;

  Future<void> _nextFrame() {
    final frame = Completer<void>();
    _defer(frame.complete);
    return frame.future;
  }

  static void _deferUntilNextFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }
}
