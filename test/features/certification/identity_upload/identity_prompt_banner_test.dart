import 'package:dali_cash/features/certification/widgets/identity_prompt_banner.dart';
import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the reusable red prompt message', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ScreenAdapter.initForSize(const Size(375, 812));
    await tester.pumpWidget(
      const MaterialApp(home: IdentityPromptBanner(message: 'Security first.')),
    );

    expect(find.text('Security first.'), findsOneWidget);
    expect(find.byType(IdentityPromptBanner), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('identityPromptBanner'))).width,
      375,
    );
  });

  testWidgets('fills the available width on wider screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(750, 1624);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ScreenAdapter.initForSize(const Size(750, 1624));

    await tester.pumpWidget(
      const MaterialApp(home: IdentityPromptBanner(message: 'Security first.')),
    );

    expect(
      tester.getSize(find.byKey(const Key('identityPromptBanner'))).width,
      750,
    );
  });
}
