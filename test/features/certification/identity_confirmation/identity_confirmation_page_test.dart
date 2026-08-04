import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/certification/identity_confirmation/identity_confirmation_page.dart';
import 'package:dali_cash/features/certification/identity_confirmation/identity_recognition_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('shows uploaded ID image and recognized identity fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ScreenAdapter.initForSize(const Size(375, 812));

    await tester.pumpWidget(
      MaterialApp(
        home: IdentityConfirmationPage(
          productId: 'product-42',
          cardType: 'PRC',
          recognizedInfo: IdentityRecognitionResult.fromMap({
            'crocidolites': 'SIMBAJON JR ROLANDO MAESTRE',
            'imputes': '0111-9695505-5',
            'annealers': '1995/05/31',
            'millipede': 'https://example.com/id-card.jpg',
          }),
        ),
      ),
    );

    expect(find.text('ID Verification'), findsOneWidget);
    expect(
      find.text('Check your info once more to keep everything on track.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('identityConfirmationImage')), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('SIMBAJON JR ROLANDO MAESTRE'), findsOneWidget);
    expect(find.text('ID No.'), findsOneWidget);
    expect(find.text('0111-9695505-5'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('31-05-1995'), findsOneWidget);
    expect(
      find.byKey(const Key('identityConfirmationUploadButton')),
      findsOneWidget,
    );
  });

  testWidgets(
    'edits recognized fields and reloads the server-controlled next step',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(Get.reset);
      ScreenAdapter.initForSize(const Size(375, 812));
      final client = _IdentitySubmitApiClient();
      await client.config.sessionStore.saveIdentitySceneStartTime(100);
      final riskStarts = <int>[];
      final continuedProducts = <String>[];
      Get.put<ApiClient>(client);

      await tester.pumpWidget(
        GetMaterialApp(
          builder: EasyLoading.init(),
          home: IdentityConfirmationPage(
            productId: 'product-42',
            cardType: 'PRC',
            apiClient: client,
            recognizedInfo: IdentityRecognitionResult.fromMap({
              'crocidolites': 'OLD NAME',
              'imputes': 'OLD-ID',
              'annealers': '1995/05/31',
            }),
            reportRiskScene: (startTimeSeconds) async {
              riskStarts.add(startTimeSeconds);
            },
            continueProductDetailFlow: (productId) async {
              continuedProducts.add(productId);
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('identityConfirmationNameInput')),
        'JUAN DELA CRUZ',
      );
      await tester.enterText(
        find.byKey(const Key('identityConfirmationIdInput')),
        'ID-9988',
      );
      await tester.tap(
        find.byKey(const Key('identityConfirmationUploadButton')),
      );
      await tester.pumpAndSettle();

      expect(client.name, 'JUAN DELA CRUZ');
      expect(client.idNumber, 'ID-9988');
      expect(client.birthday, '31-05-1995');
      expect(client.cardType, 'PRC');
      expect(continuedProducts, ['product-42']);
      expect(Get.currentRoute, '/');
      expect(riskStarts, [100]);
    },
  );

  testWidgets('shows cached hoddens copy from product detail', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    ScreenAdapter.initForSize(const Size(375, 812));
    final store = SessionStore.memory();
    await store.saveProductDetailIdentityConfirmationPrompt(
      'Please confirm the recognized ID details.',
    );
    Get.put<ApiClient>(ApiClient(ApiConfig(sessionStore: store)));

    await tester.pumpWidget(
      const GetMaterialApp(home: IdentityConfirmationPage()),
    );

    expect(
      find.text('Please confirm the recognized ID details.'),
      findsOneWidget,
    );
    expect(
      find.text(IdentityConfirmationPage.defaultPromptMessage),
      findsNothing,
    );
  });

  testWidgets('dismisses the keyboard when tapping a blank area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ScreenAdapter.initForSize(const Size(375, 812));

    await tester.pumpWidget(
      MaterialApp(
        home: IdentityConfirmationPage(
          recognizedInfo: IdentityRecognitionResult.fromMap({
            'crocidolites': 'JUAN DELA CRUZ',
          }),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('identityConfirmationNameInput')));
    await tester.pump();
    final editableText = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('identityConfirmationNameInput')),
        matching: find.byType(EditableText),
      ),
    );
    expect(editableText.focusNode.hasPrimaryFocus, isTrue);

    await tester.tapAt(const Offset(4, 400));
    await tester.pump();

    expect(editableText.focusNode.hasPrimaryFocus, isFalse);
  });
}

class _IdentitySubmitApiClient extends ApiClient {
  _IdentitySubmitApiClient()
    : super(ApiConfig(sessionStore: SessionStore.memory()));

  String? name;
  String? idNumber;
  String? birthday;
  String? cardType;

  @override
  Future<ApiResponse> saveBasicInfo({
    required String annealers,
    required String imputes,
    required String crocidolites,
    required String sociologeses,
    required String rapscallion,
  }) async {
    birthday = annealers;
    idNumber = imputes;
    name = crocidolites;
    cardType = rapscallion;
    return ApiResponse(code: 0, message: 'success', states: Json({}));
  }
}
