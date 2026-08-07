import 'package:dali_cash/app/routes/app_routes.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/certification/identity_confirmation/identity_confirmation_page.dart';
import 'package:dali_cash/features/certification/identity_upload/identity_upload_page.dart';
import 'package:dali_cash/features/certification/identity_upload/identity_upload_services.dart';
import 'package:dali_cash/features/certification/widgets/identity_upload_method_sheet.dart';
import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('matches the upload design and logs Upload taps', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ScreenAdapter.initForSize(const Size(375, 812));
    final logs = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: IdentityUploadPage(
          productId: 'product-42',
          cardType: 'PRC',
          promptMessage:
              'Security first. Complete ID verification to shield your funds.',
          logger: logs.add,
        ),
      ),
    );

    expect(find.text('ID Verification'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(
      find.text(
        'Security first. Complete ID verification to shield your funds.',
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('identityPromptBanner'))).height,
      40,
    );
    expect(find.text('Upload'), findsOneWidget);
    expect(find.byKey(const Key('identityUploadDemo')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('identityUploadDemo'))),
      const Size(343, 429),
    );

    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('identity-upload-method-dialog')),
      findsOneWidget,
    );
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Album'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('identity-upload-method-sheet'))),
      const Size(375, 170),
    );
    expect(logs, ['identity upload tapped: productId=product-42, type=PRC']);

    await tester.tap(find.byKey(const Key('identity-upload-camera')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('identity-upload-method-dialog')),
      findsNothing,
    );
    expect(logs, [
      'identity upload tapped: productId=product-42, type=PRC',
      'identity upload method tapped: Camera, '
          'productId=product-42, type=PRC',
    ]);
  });

  testWidgets(
    'falls back to the design prompt when product detail copy is empty',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ScreenAdapter.initForSize(const Size(375, 812));

      await tester.pumpWidget(
        MaterialApp(
          home: IdentityUploadPage(productId: 'product-42', cardType: 'PRC'),
        ),
      );

      expect(
        find.text(IdentityUploadPage.defaultPromptMessage),
        findsOneWidget,
      );
    },
  );

  testWidgets('camera denial shows iOS settings dialog', (tester) async {
    var settingsOpened = false;
    final selectedMethods = <IdentityUploadMethod>[];
    await _pumpPermissionPage(
      tester,
      requestCameraPermission: () async => false,
      openAppSettingsPage: () async {
        settingsOpened = true;
        return true;
      },
      onUploadMethodSelected: selectedMethods.add,
    );

    await tester.tap(find.byKey(const Key('identityUploadButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('identity-upload-camera')));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.text('Allow Camera Access'), findsOneWidget);
    expect(selectedMethods, isEmpty);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(settingsOpened, isTrue);
  });

  testWidgets('camera grant continues selected method', (tester) async {
    var cameraRequests = 0;
    final selectedMethods = <IdentityUploadMethod>[];
    await _pumpPermissionPage(
      tester,
      requestCameraPermission: () async {
        cameraRequests++;
        return true;
      },
      onUploadMethodSelected: selectedMethods.add,
    );

    await tester.tap(find.byKey(const Key('identityUploadButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('identity-upload-camera')));
    await tester.pumpAndSettle();

    expect(cameraRequests, 1);
    expect(selectedMethods, [IdentityUploadMethod.camera]);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('album continues without requesting camera', (tester) async {
    var cameraRequests = 0;
    final selectedMethods = <IdentityUploadMethod>[];
    await _pumpPermissionPage(
      tester,
      requestCameraPermission: () async {
        cameraRequests++;
        return true;
      },
      onUploadMethodSelected: selectedMethods.add,
    );

    await tester.tap(find.byKey(const Key('identityUploadButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('identity-upload-album')));
    await tester.pumpAndSettle();

    expect(cameraRequests, 0);
    expect(selectedMethods, [IdentityUploadMethod.album]);
  });

  testWidgets('upload success opens confirmation with recognized data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    ScreenAdapter.initForSize(const Size(375, 812));
    final client = _SuccessfulUploadApiClient();

    await tester.pumpWidget(
      GetMaterialApp(
        builder: EasyLoading.init(),
        home: IdentityUploadPage(
          productId: 'product-42',
          cardType: 'PRC',
          apiClient: client,
          imagePicker: _AlbumImagePicker(),
          imageCompressor: _PassThroughImageCompressor(),
          nowSeconds: () => 100,
        ),
        getPages: [
          GetPage(
            name: AppRoutes.identityConfirmation,
            page: () => const IdentityConfirmationPage(),
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('identityUploadButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('identity-upload-album')));
    await tester.pumpAndSettle();

    expect(find.byType(IdentityConfirmationPage), findsOneWidget);
    expect(find.text('SIMBAJON JR ROLANDO MAESTRE'), findsOneWidget);
    expect(find.text('0111-9695505-5'), findsOneWidget);
    expect(find.text('31-05-1995'), findsOneWidget);
    expect(client.lastCardType, 'PRC');
    expect(await client.config.sessionStore.identitySceneStartTime(), 100);
  });
}

Future<void> _pumpPermissionPage(
  WidgetTester tester, {
  required Future<bool> Function() requestCameraPermission,
  Future<bool> Function()? openAppSettingsPage,
  ValueChanged<IdentityUploadMethod>? onUploadMethodSelected,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  ScreenAdapter.initForSize(const Size(375, 812));
  await tester.pumpWidget(
    MaterialApp(
      home: IdentityUploadPage(
        productId: 'product-42',
        cardType: 'PRC',
        requestCameraPermission: requestCameraPermission,
        openAppSettingsPage: openAppSettingsPage ?? () async => false,
        onUploadMethodSelected: onUploadMethodSelected,
      ),
    ),
  );
}

class _SuccessfulUploadApiClient extends ApiClient {
  _SuccessfulUploadApiClient()
    : super(ApiConfig(sessionStore: SessionStore.memory()));

  String? lastCardType;

  @override
  Future<ApiResponse> uploadImage({
    required String sociologeses,
    required String scabble,
    required String filePath,
    required String fileField,
    String? rapscallion,
    String? feoffed,
    String? miscasts,
    String? pileated,
    String? infantilisms,
  }) async {
    lastCardType = rapscallion;
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json({
        'crocidolites': 'SIMBAJON JR ROLANDO MAESTRE',
        'imputes': '0111-9695505-5',
        'annealers': '1995/05/31',
        'millipede': '',
      }),
    );
  }
}

class _AlbumImagePicker implements IdentityUploadImagePicker {
  @override
  Future<String?> pickFromAlbum() async => '/tmp/id-card.jpg';

  @override
  Future<String?> pickFromCamera() async => '/tmp/id-card.jpg';
}

class _PassThroughImageCompressor implements IdentityUploadImageCompressor {
  @override
  Future<String?> compressToLimit(String filePath) async => filePath;
}
