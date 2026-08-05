import 'dart:async';

import 'package:dali_cash/app/routes/app_routes.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/features/recredit/recredit_polling_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'polls until tucking is 1, then admits the product on recredit',
    () async {
      var calls = 0;
      final admitted = <String>[];
      final coordinator = RecreditPollingCoordinator(
        request: () async {
          calls += 1;
          return _response(calls == 1 ? 2 : 1);
        },
        currentRoute: () => AppRoutes.recredit,
        admissionRunner: (productId) async => admitted.add(productId),
        interval: Duration.zero,
      );
      addTearDown(coordinator.stop);

      coordinator.start(' product-1 ');
      await _waitUntil(() => calls == 2 && admitted.isNotEmpty);

      expect(admitted, ['product-1']);
      expect(coordinator.isRunning, isFalse);
    },
  );

  test('stopped in-flight request cannot trigger stale completion', () async {
    final response = Completer<ApiResponse>();
    var admitted = 0;
    final coordinator = RecreditPollingCoordinator(
      request: () => response.future,
      currentRoute: () => AppRoutes.recredit,
      admissionRunner: (_) async => admitted += 1,
    );
    coordinator.start('product-2');
    await _waitUntil(() => coordinator.isRunning);
    coordinator.stop();
    response.complete(_response(1));
    await Future<void>.delayed(Duration.zero);

    expect(admitted, 0);
  });
}

ApiResponse _response(int tucking) {
  return ApiResponse(
    code: 0,
    message: 'success',
    states: Json({'tucking': tucking}),
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var i = 0; i < 100; i += 1) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('condition was not met');
}
