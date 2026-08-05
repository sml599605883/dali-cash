import 'package:dali_cash/app/app.dart';
import 'package:dali_cash/app/startup/dali_cash_startup.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:dali_cash/main.dart' as app_main;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test('runs the startup gate before beginning network bootstrap', () async {
    final events = <String>[];
    Widget? launchedWidget;
    var bootstrapCalls = 0;
    var permissionStarts = 0;
    var notificationStarts = 0;

    await app_main.startDaliCashApp(
      setPortraitOrientation: () async {
        events.add('orientation');
      },
      bootstrapApi: () async {
        bootstrapCalls++;
        return ApiClient(ApiConfig());
      },
      startPermissionLifecycle: () {
        permissionStarts++;
      },
      startNotificationRouting: () {
        notificationStarts++;
        events.add('notification');
      },
      runApplication: (widget) {
        events.add('runApp');
        launchedWidget = widget;
      },
    );

    expect(events, ['orientation', 'notification', 'runApp']);
    expect(bootstrapCalls, 0);
    expect(permissionStarts, 0);
    expect(notificationStarts, 1);
    expect(launchedWidget, isA<DaliCashStartup>());
  });

  test('keeps startup side effects outside the root app widget', () {
    final app = DaliCashApp(
      initialBinding: MainBinding(apiClient: ApiClient(ApiConfig())),
    );

    expect(app, isA<StatelessWidget>());
  });
}
