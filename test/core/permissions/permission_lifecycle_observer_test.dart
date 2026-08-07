import 'dart:async';

import 'package:dali_cash/core/permissions/permission_lifecycle_observer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts once and retries tracking only when the app resumes', () async {
    var startupRequests = 0;
    var resumeRequests = 0;
    var reportStarts = 0;
    var reportResumes = 0;
    final observer = PermissionLifecycleObserver(
      requestStartupPermissions: () async {
        startupRequests++;
      },
      requestResumeTrackingPermission: () async {
        resumeRequests++;
      },
      reportAppStarted: () async {
        reportStarts++;
      },
      reportAppResumed: () async {
        reportResumes++;
      },
    );

    observer.start();
    observer.start();
    await Future<void>.delayed(Duration.zero);

    observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(startupRequests, 1);
    expect(resumeRequests, 1);
    expect(reportStarts, 1);
    expect(reportResumes, 1);
    WidgetsBinding.instance.removeObserver(observer);
  });

  test('reports push only after startup permissions resolve', () async {
    final permissionCompleter = Completer<void>();
    var pushReports = 0;
    final observer = PermissionLifecycleObserver(
      requestStartupPermissions: () => permissionCompleter.future,
      requestResumeTrackingPermission: () async {},
      reportPushToken: () async {
        pushReports++;
      },
    );

    observer.start();
    await Future<void>.delayed(Duration.zero);
    expect(pushReports, 0);

    permissionCompleter.complete();
    await Future<void>.delayed(Duration.zero);
    expect(pushReports, 1);
    WidgetsBinding.instance.removeObserver(observer);
  });
}
