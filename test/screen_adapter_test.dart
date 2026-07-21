import 'package:dali_cash/app/app.dart';
import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_main_binding.dart';

void main() {
  test('converts design dimensions from a 375 by 812 baseline', () {
    ScreenAdapter.initForSize(const Size(750, 1624));

    expect(ScreenAdapter.width(16), 32);
    expect(ScreenAdapter.height(16), 32);
    expect(ScreenAdapter.font(16), 32);
  });

  test('keeps design proportions when screen height changes', () {
    ScreenAdapter.initForSize(const Size(375, 667));

    expect(ScreenAdapter.width(100), 100);
    expect(ScreenAdapter.height(100), 100);
  });

  testWidgets('initializes when the app starts', (tester) async {
    ScreenAdapter.resetForTest();

    await tester.pumpWidget(DaliCashApp(initialBinding: testMainBinding()));

    expect(ScreenAdapter.isInitialized, isTrue);
  });
}
