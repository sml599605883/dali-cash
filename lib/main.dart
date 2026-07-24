import 'package:dali_cash/app/app.dart';
import 'package:dali_cash/app/startup/dali_cash_startup.dart';
import 'package:dali_cash/core/network/api_bootstrap.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/permissions/permission_lifecycle_observer.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef AppRunner = void Function(Widget app);
typedef ApiBootstrapper = Future<ApiClient> Function();
typedef PreferredOrientationSetter = Future<void> Function();
typedef PermissionLifecycleStarter = void Function();

Future<void> main() => startDaliCashApp();

Future<void> startDaliCashApp({
  ApiBootstrapper bootstrapApi = bootstrapApiClient,
  AppRunner runApplication = runApp,
  PreferredOrientationSetter setPortraitOrientation = _setPortraitOrientation,
  PermissionLifecycleStarter startPermissionLifecycle =
      _startPermissionLifecycle,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await setPortraitOrientation();
  runApplication(
    DaliCashStartup(
      bootstrapApi: bootstrapApi,
      startPermissionLifecycle: startPermissionLifecycle,
      readyAppBuilder: (apiClient) {
        return DaliCashApp(initialBinding: MainBinding(apiClient: apiClient));
      },
    ),
  );
}

Future<void> _setPortraitOrientation() {
  return SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
}

void _startPermissionLifecycle() {
  PermissionLifecycleObserver.instance.start();
}
