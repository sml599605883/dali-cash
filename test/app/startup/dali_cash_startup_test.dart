import 'dart:async';

import 'package:dali_cash/app/startup/dali_cash_startup.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bootstraps after the first frame before building the app', (
    tester,
  ) async {
    final completer = Completer<ApiClient>();
    var bootstrapCalls = 0;
    var permissionStarts = 0;
    ApiClient? configuredClient;

    await tester.pumpWidget(
      DaliCashStartup(
        bootstrapApi: () {
          bootstrapCalls++;
          return completer.future;
        },
        startPermissionLifecycle: () => permissionStarts++,
        configureReporting: (client) => configuredClient = client,
        readyAppBuilder: (_) => const SizedBox(key: Key('startup-ready-app')),
      ),
    );

    expect(bootstrapCalls, 1);
    expect(find.byKey(const Key('startup-network-loading')), findsOneWidget);
    expect(find.byKey(const Key('startup-ready-app')), findsNothing);
    expect(permissionStarts, 0);

    completer.complete(ApiClient(ApiConfig()));
    await tester.pump();

    expect(find.byKey(const Key('startup-ready-app')), findsOneWidget);
    expect(permissionStarts, 1);
    expect(configuredClient, isNotNull);
  });

  testWidgets('keeps startup blocked and retries after network failure', (
    tester,
  ) async {
    var bootstrapCalls = 0;
    var permissionStarts = 0;
    var reportConfigurations = 0;

    await tester.pumpWidget(
      DaliCashStartup(
        bootstrapApi: () async {
          bootstrapCalls++;
          if (bootstrapCalls == 1) {
            throw StateError('offline');
          }
          return ApiClient(ApiConfig());
        },
        startPermissionLifecycle: () => permissionStarts++,
        configureReporting: (_) => reportConfigurations++,
        readyAppBuilder: (_) => const SizedBox(key: Key('startup-ready-app')),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('startup-network-retry')), findsOneWidget);
    expect(find.byKey(const Key('startup-ready-app')), findsNothing);
    expect(permissionStarts, 0);

    await tester.tap(find.byKey(const Key('startup-network-retry')));
    await tester.pump();
    await tester.pump();

    expect(bootstrapCalls, 2);
    expect(find.byKey(const Key('startup-ready-app')), findsOneWidget);
    expect(permissionStarts, 1);
    expect(reportConfigurations, 1);
  });
}
