import 'dart:async';

import 'package:dali_cash/app/app.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:dali_cash/main.dart' as app_main;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('waits for network bootstrap before running the app', () async {
    final client = ApiClient(ApiConfig());
    final completer = Completer<ApiClient>();
    Widget? launchedWidget;

    final startup = app_main.startDaliCashApp(
      bootstrapApi: () => completer.future,
      runApplication: (widget) => launchedWidget = widget,
    );

    await Future<void>.delayed(Duration.zero);
    expect(launchedWidget, isNull);

    completer.complete(client);
    await startup;

    final app = launchedWidget as DaliCashApp;
    final binding = app.initialBinding! as MainBinding;
    expect(binding.apiClient, same(client));
  });
}
