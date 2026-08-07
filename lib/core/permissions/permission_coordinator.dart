import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../client/client_bridge.dart';

typedef NativePermissionRequester = Future<Object?> Function();
typedef PermissionAction = Future<void> Function();
typedef PermissionDelay = Future<void> Function(Duration duration);
typedef LocationServiceStatusProvider = Future<ServiceStatus> Function();
typedef LocationPermissionStatusProvider = Future<PermissionStatus> Function();
typedef LocationPermissionRequester = Future<PermissionStatus> Function();

enum CertificationLocationDecision {
  granted,
  denied,
  settingsRequired,
  serviceDisabled,
}

class PermissionCoordinator {
  PermissionCoordinator({
    required NativePermissionRequester requestNotificationPermission,
    required NativePermissionRequester requestTrackingPermission,
    PermissionAction? registerForRemoteNotifications,
    this.requestDelay = const Duration(milliseconds: 400),
    PermissionDelay? delay,
    LocationServiceStatusProvider? locationServiceStatusProvider,
    LocationPermissionStatusProvider? locationPermissionStatusProvider,
    LocationPermissionRequester? locationPermissionRequester,
  }) : _requestNotificationPermission = requestNotificationPermission,
       _requestTrackingPermission = requestTrackingPermission,
       _registerForRemoteNotifications =
           registerForRemoteNotifications ?? _noopPermissionAction,
       _delay = delay ?? Future<void>.delayed,
       _locationServiceStatusProvider =
           locationServiceStatusProvider ?? _defaultLocationServiceStatus,
       _locationPermissionStatusProvider =
           locationPermissionStatusProvider ?? _defaultLocationStatus,
       _locationPermissionRequester =
           locationPermissionRequester ?? _defaultLocationRequest;

  factory PermissionCoordinator.defaultInstance() {
    return PermissionCoordinator(
      requestNotificationPermission: Permission.notification.request,
      registerForRemoteNotifications: () async {
        if (Platform.isIOS) {
          await ClientBridge.shared.registerForRemoteNotifications();
        }
      },
      requestTrackingPermission: () {
        if (!Platform.isIOS) {
          return Future<Object?>.value(PermissionStatus.granted);
        }
        return Permission.appTrackingTransparency.request();
      },
    );
  }

  static final PermissionCoordinator instance =
      PermissionCoordinator.defaultInstance();

  final NativePermissionRequester _requestNotificationPermission;
  final NativePermissionRequester _requestTrackingPermission;
  final PermissionAction _registerForRemoteNotifications;
  final PermissionDelay _delay;
  final LocationServiceStatusProvider _locationServiceStatusProvider;
  final LocationPermissionStatusProvider _locationPermissionStatusProvider;
  final LocationPermissionRequester _locationPermissionRequester;
  final Duration requestDelay;

  Future<void>? _startupRequest;
  Future<void>? _resumeRequest;
  Future<CertificationLocationDecision>? _locationRequest;
  bool _startupPermissionsRequested = false;

  Future<void> requestStartupPermissions() {
    if (_startupPermissionsRequested) {
      return Future<void>.value();
    }
    return _startupRequest ??= _requestStartupPermissions();
  }

  Future<void> _requestStartupPermissions() async {
    try {
      await _delay(requestDelay);
      await _requestNotificationPermission();
      await _registerForRemoteNotifications();
      await _delay(requestDelay);
      await _requestTrackingPermission();
    } catch (_) {
      // Permission failures must not interrupt application startup.
    } finally {
      _startupPermissionsRequested = true;
      _startupRequest = null;
    }
  }

  Future<void> requestResumeTrackingPermission() {
    return _resumeRequest ??= _requestResumeTrackingPermission().whenComplete(
      () => _resumeRequest = null,
    );
  }

  Future<void> _requestResumeTrackingPermission() async {
    try {
      await _delay(requestDelay);
      await _requestTrackingPermission();
    } catch (_) {
      // Permission failures must not interrupt application resume.
    }
  }

  Future<CertificationLocationDecision> requestCertificationLocation() {
    return _locationRequest ??= _requestCertificationLocation().whenComplete(
      () => _locationRequest = null,
    );
  }

  Future<CertificationLocationDecision> _requestCertificationLocation() async {
    try {
      final serviceStatus = await _locationServiceStatusProvider();
      if (serviceStatus != ServiceStatus.enabled) {
        return CertificationLocationDecision.serviceDisabled;
      }

      final status = await _locationPermissionStatusProvider();
      if (_isGranted(status)) {
        return CertificationLocationDecision.granted;
      }
      if (_requiresSettings(status)) {
        return CertificationLocationDecision.settingsRequired;
      }

      final requestedStatus =
          await _requestLocationPermissionUntilInterrupted();
      if (requestedStatus == null) {
        return CertificationLocationDecision.denied;
      }
      if (_isGranted(requestedStatus)) {
        return CertificationLocationDecision.granted;
      }
      if (_requiresSettings(requestedStatus)) {
        return CertificationLocationDecision.settingsRequired;
      }
      return CertificationLocationDecision.settingsRequired;
    } catch (_) {
      return CertificationLocationDecision.denied;
    }
  }

  bool _isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  bool _requiresSettings(PermissionStatus status) {
    return status.isPermanentlyDenied || status.isRestricted;
  }

  Future<PermissionStatus?> _requestLocationPermissionUntilInterrupted() async {
    final interrupted = Completer<PermissionStatus?>();
    final observer = _LocationPermissionLifecycleObserver(() {
      if (!interrupted.isCompleted) {
        interrupted.complete();
      }
    });
    WidgetsBinding.instance.addObserver(observer);
    try {
      return await Future.any<PermissionStatus?>([
        _locationPermissionRequester().then<PermissionStatus?>((status) {
          return status;
        }),
        interrupted.future,
      ]);
    } finally {
      WidgetsBinding.instance.removeObserver(observer);
    }
  }
}

class _LocationPermissionLifecycleObserver extends WidgetsBindingObserver {
  _LocationPermissionLifecycleObserver(this.onInterrupted);

  final VoidCallback onInterrupted;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onInterrupted();
    }
  }
}

Future<ServiceStatus> _defaultLocationServiceStatus() {
  return Permission.locationWhenInUse.serviceStatus;
}

Future<PermissionStatus> _defaultLocationStatus() {
  return Permission.locationWhenInUse.status;
}

Future<PermissionStatus> _defaultLocationRequest() {
  if (Platform.isIOS) {
    return ClientBridge.shared.requestLocationPermission().then((status) {
      return switch (status) {
        'authorized' ||
        'authorized_always' ||
        'authorized_when_in_use' => PermissionStatus.granted,
        'limited' => PermissionStatus.limited,
        'restricted' => PermissionStatus.restricted,
        'permanently_denied' => PermissionStatus.permanentlyDenied,
        _ => PermissionStatus.denied,
      };
    });
  }
  return Permission.locationWhenInUse.request();
}

Future<void> _noopPermissionAction() async {}
