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
    PermissionRequest? reportStartupPermissionsResolved,
  }) : _requestStartupPermissions = requestStartupPermissions,
       _requestResumeTrackingPermission = requestResumeTrackingPermission,
       _reportAppStarted = reportAppStarted ?? _noop,
       _reportAppResumed = reportAppResumed ?? _noop,
       _reportStartupPermissionsResolved =
           reportStartupPermissionsResolved ?? _noop;

  static final PermissionLifecycleObserver instance =
      PermissionLifecycleObserver(
        requestStartupPermissions:
            PermissionCoordinator.instance.requestStartupPermissions,
        requestResumeTrackingPermission:
            PermissionCoordinator.instance.requestResumeTrackingPermission,
        reportAppStarted: _reportStarted,
        reportAppResumed: _reportResumed,
        reportStartupPermissionsResolved: _completeStartupReporting,
      );

  final PermissionRequest _requestStartupPermissions;
  final PermissionRequest _requestResumeTrackingPermission;
  final PermissionRequest _reportAppStarted;
  final PermissionRequest _reportAppResumed;
  final PermissionRequest _reportStartupPermissionsResolved;

  bool _started = false;

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_runStartup());
  }

  Future<void> _runStartup() async {
    try {
      await _reportAppStarted();
    } catch (_) {
      // Reporting setup failures must not prevent permission requests.
    }
    try {
      await _requestStartupPermissions();
    } catch (_) {
      // Permission failures must not prevent startup report completion.
    }
    try {
      await _reportStartupPermissionsResolved();
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

Future<void> _completeStartupReporting() async {
  await DaliReportService.current?.startupPermissionsResolved();
}
