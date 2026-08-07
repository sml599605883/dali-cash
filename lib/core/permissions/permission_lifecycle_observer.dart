import 'dart:async';

import 'package:flutter/widgets.dart';

import 'permission_coordinator.dart';
import '../report/dali_report_service.dart';

typedef PermissionRequest = Future<void> Function();

class PermissionLifecycleObserver extends WidgetsBindingObserver {
  PermissionLifecycleObserver({
    required PermissionRequest requestStartupPermissions,
    required PermissionRequest requestResumeTrackingPermission,
    PermissionRequest? reportAppStarted,
    PermissionRequest? reportAppResumed,
    PermissionRequest? reportPushToken,
  }) : _requestStartupPermissions = requestStartupPermissions,
       _requestResumeTrackingPermission = requestResumeTrackingPermission,
       _reportAppStarted = reportAppStarted ?? _noop,
       _reportAppResumed = reportAppResumed ?? _noop,
       _reportPushToken = reportPushToken ?? _noop;

  static final PermissionLifecycleObserver instance =
      PermissionLifecycleObserver(
        requestStartupPermissions:
            PermissionCoordinator.instance.requestStartupPermissions,
        requestResumeTrackingPermission:
            PermissionCoordinator.instance.requestResumeTrackingPermission,
        reportAppStarted: _reportStarted,
        reportAppResumed: _reportResumed,
        reportPushToken: _reportStartedPushToken,
      );

  final PermissionRequest _requestStartupPermissions;
  final PermissionRequest _requestResumeTrackingPermission;
  final PermissionRequest _reportAppStarted;
  final PermissionRequest _reportAppResumed;
  final PermissionRequest _reportPushToken;

  bool _started = false;

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_requestStartupPermissionsAndReportPushToken());
    unawaited(_reportAppStarted());
  }

  Future<void> _requestStartupPermissionsAndReportPushToken() async {
    try {
      await _requestStartupPermissions();
    } catch (_) {
      // Permission failures must not prevent the push report attempt.
    }
    try {
      await _reportPushToken();
    } catch (_) {
      // Reporting failures must not interrupt application lifecycle handling.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_requestResumeTrackingPermission());
      unawaited(_reportAppResumed());
    }
  }
}

Future<void> _noop() async {}

Future<void> _reportStarted() async {
  await DaliReportService.current?.start();
}

Future<void> _reportResumed() async {
  await DaliReportService.current?.resumed();
}

Future<void> _reportStartedPushToken() async {
  await DaliReportService.current?.reportAppleToken();
}
