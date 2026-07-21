import 'package:dali_cash/app/app.dart';
import 'package:dali_cash/core/network/api_bootstrap.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:flutter/widgets.dart';

typedef ApiBootstrapper = Future<ApiClient> Function();
typedef AppRunner = void Function(Widget app);

Future<void> main() => startDaliCashApp();

Future<void> startDaliCashApp({
  ApiBootstrapper bootstrapApi = bootstrapApiClient,
  AppRunner runApplication = runApp,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = await bootstrapApi();
  runApplication(
    DaliCashApp(initialBinding: MainBinding(apiClient: apiClient)),
  );
}
