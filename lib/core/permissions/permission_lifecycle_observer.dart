import 'dart:async';

import 'package:flutter/widgets.dart';

import 'permission_coordinator.dart';

typedef PermissionRequest = Future<void> Function();

class PermissionLifecycleObserver extends WidgetsBindingObserver {
  PermissionLifecycleObserver({
    required PermissionRequest requestStartupPermissions,
    required PermissionRequest requestResumeTrackingPermission,
  }) : _requestStartupPermissions = requestStartupPermissions,
       _requestResumeTrackingPermission = requestResumeTrackingPermission;

  static final PermissionLifecycleObserver instance =
      PermissionLifecycleObserver(
        requestStartupPermissions:
            PermissionCoordinator.instance.requestStartupPermissions,
        requestResumeTrackingPermission:
            PermissionCoordinator.instance.requestResumeTrackingPermission,
      );

  final PermissionRequest _requestStartupPermissions;
  final PermissionRequest _requestResumeTrackingPermission;

  bool _started = false;

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_requestStartupPermissions());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_requestResumeTrackingPermission());
    }
  }
}
