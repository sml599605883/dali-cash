import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/features/home/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ScreenAdapter.resetForTest);

  testWidgets('customer service icon invokes its navigation action', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ScreenAdapter.init(context);
            return Scaffold(
              body: HomeHeader(onCustomerServiceTap: () => taps++),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('home-customer-service')));

    expect(taps, 1);
  });
}
