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
    var startupCompletions = 0;
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
      reportStartupPermissionsResolved: () async {
        startupCompletions++;
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
    expect(startupCompletions, 1);
    WidgetsBinding.instance.removeObserver(observer);
  });

  test('completes startup reporting only after permissions resolve', () async {
    final permissionCompleter = Completer<void>();
    final events = <String>[];
    final observer = PermissionLifecycleObserver(
      requestStartupPermissions: () => permissionCompleter.future,
      requestResumeTrackingPermission: () async {},
      reportAppStarted: () async {
        events.add('started');
      },
      reportStartupPermissionsResolved: () async {
        events.add('permissions-resolved');
      },
    );

    observer.start();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['started']);

    permissionCompleter.complete();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['started', 'permissions-resolved']);
    WidgetsBinding.instance.removeObserver(observer);
  });
}
