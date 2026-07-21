import 'dart:async';

import 'package:dali_cash/app/app.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_main_binding.dart';

void main() {
  testWidgets('shows and dismisses loading after app startup', (tester) async {
    await tester.pumpWidget(DaliCashApp(initialBinding: testMainBinding()));

    unawaited(EasyLoading.show(status: 'Loading...'));
    await tester.pump();
    await tester.pump(EasyLoading.instance.animationDuration);

    expect(EasyLoading.isShow, isTrue);
    expect(find.text('Loading...'), findsOneWidget);

    unawaited(EasyLoading.dismiss(animation: false));
    await tester.pump();

    expect(EasyLoading.isShow, isFalse);
  });
}
