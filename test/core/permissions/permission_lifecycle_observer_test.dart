import 'package:dali_cash/core/permissions/permission_lifecycle_observer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts once and retries tracking only when the app resumes', () async {
    var startupRequests = 0;
    var resumeRequests = 0;
    final observer = PermissionLifecycleObserver(
      requestStartupPermissions: () async {
        startupRequests++;
      },
      requestResumeTrackingPermission: () async {
        resumeRequests++;
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
    WidgetsBinding.instance.removeObserver(observer);
  });
}
