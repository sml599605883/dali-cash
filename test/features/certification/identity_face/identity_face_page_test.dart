import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/certification/identity_face/identity_face_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('renders face guide and cached variety prompt', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    ScreenAdapter.initForSize(const Size(375, 812));
    final store = SessionStore.memory();
    await store.saveProductDetailFacePrompt(
      'Use a clear face image to continue verification.',
    );
    Get.put<ApiClient>(ApiClient(ApiConfig(sessionStore: store)));

    await tester.pumpWidget(const GetMaterialApp(home: IdentityFacePage()));

    expect(find.text('ID Verification'), findsOneWidget);
    expect(
      find.text('Use a clear face image to continue verification.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('identityFaceDemo')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Face verification demonstration examples'),
      findsOneWidget,
    );
    expect(find.text('Upload'), findsOneWidget);
  });
}
