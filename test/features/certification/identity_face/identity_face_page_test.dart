import 'dart:async';

import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/core/client/client_bridge.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/certification/identity_face/identity_face_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

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

  testWidgets('camera denial shows the iOS settings dialog', (tester) async {
    final store = SessionStore.memory();
    await store.saveProductDetailOrderNo('ORDER-42');
    final client = _FakeFaceApiClient(store);
    var settingsOpens = 0;

    await _pumpFacePage(
      tester,
      client: client,
      requestCameraPermission: () async => PermissionStatus.denied,
      openAppSettingsPage: () async {
        settingsOpens++;
        return true;
      },
    );

    await tester.tap(find.byKey(const Key('identityFaceUploadButton')));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(client.tokenOrders, isEmpty);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(settingsOpens, 1);
  });

  testWidgets('token code 400 asks the user to upload the ID again', (
    tester,
  ) async {
    final store = SessionStore.memory();
    await store.saveProductDetailOrderNo('ORDER-42');
    final client = _FakeFaceApiClient(store)
      ..tokenResponse = _tokenResponse(
        code: '400',
        message: 'Please upload your ID again.',
      );
    final errors = <String>[];
    var livenessCalls = 0;

    await _pumpFacePage(
      tester,
      client: client,
      errors: errors,
      showTrustDecisionLiveness: (_) async {
        livenessCalls++;
        return _successfulLiveness;
      },
    );

    await tester.tap(find.byKey(const Key('identityFaceUploadButton')));
    await tester.pumpAndSettle();

    expect(errors, ['Please upload your ID again.']);
    expect(livenessCalls, 0);
    expect(client.uploads, isEmpty);
  });

  testWidgets('unsupported liveness type does not open TrustDecision', (
    tester,
  ) async {
    final store = SessionStore.memory();
    await store.saveProductDetailOrderNo('ORDER-42');
    final client = _FakeFaceApiClient(store)
      ..tokenResponse = _tokenResponse(faceType: 6);
    final errors = <String>[];
    var livenessCalls = 0;

    await _pumpFacePage(
      tester,
      client: client,
      errors: errors,
      showTrustDecisionLiveness: (_) async {
        livenessCalls++;
        return _successfulLiveness;
      },
    );

    await tester.tap(find.byKey(const Key('identityFaceUploadButton')));
    await tester.pumpAndSettle();

    expect(errors, ['Unsupported liveness verification type']);
    expect(livenessCalls, 0);
  });

  testWidgets('TrustDecision failure remains on the face page', (tester) async {
    final store = SessionStore.memory();
    await store.saveProductDetailOrderNo('ORDER-42');
    final client = _FakeFaceApiClient(store);
    final errors = <String>[];
    final reports = <TrustDecisionLivenessResult>[];
    const cancelled = TrustDecisionLivenessResult(
      success: false,
      code: 3001,
      message: 'Liveness cancelled',
      image: '',
      sequenceId: '',
      livenessId: '',
      raw: <String, dynamic>{},
    );

    await _pumpFacePage(
      tester,
      client: client,
      errors: errors,
      showTrustDecisionLiveness: (_) async => cancelled,
      reportTrustDecisionResult: (result) async => reports.add(result),
    );

    await tester.tap(find.byKey(const Key('identityFaceUploadButton')));
    await tester.pumpAndSettle();

    expect(errors, ['Liveness cancelled']);
    expect(client.uploads, isEmpty);
    expect(reports, [cancelled]);
  });

  testWidgets('uploads documented TrustDecision fields and continues', (
    tester,
  ) async {
    final store = SessionStore.memory();
    await store.saveProductDetailOrderNo('ORDER-42');
    final client = _FakeFaceApiClient(store);
    final continuedProducts = <String>[];
    final builtImages = <String>[];
    final riskStarts = <int>[];
    final reports = <TrustDecisionLivenessResult>[];

    await _pumpFacePage(
      tester,
      client: client,
      showTrustDecisionLiveness: (_) async => _successfulLiveness,
      faceImageFilePathBuilder: (image) async {
        builtImages.add(image);
        return '/tmp/trustdecision-face.jpg';
      },
      continueProductDetailFlow: (productId) async {
        continuedProducts.add(productId);
      },
      nowSeconds: () => 100,
      reportRiskScene: (startTimeSeconds) async {
        riskStarts.add(startTimeSeconds);
      },
      reportTrustDecisionResult: (result) async => reports.add(result),
    );

    await tester.tap(find.byKey(const Key('identityFaceUploadButton')));
    await tester.pumpAndSettle();

    expect(client.tokenOrders, ['ORDER-42']);
    expect(client.tokenTypes, ['0']);
    expect(builtImages, ['base64-image']);
    expect(client.uploads.single, {
      'sociologeses': '10',
      'scabble': '1',
      'filePath': '/tmp/trustdecision-face.jpg',
      'fileField': 'attach',
      'rapscallion': 'PRC',
      'feoffed': 'liveness-42',
      'miscasts': 'td-license',
      'pileated': '7',
      'infantilisms': null,
    });
    expect(continuedProducts, ['product-42']);
    expect(riskStarts, [100]);
    expect(reports, [_successfulLiveness]);
  });

  testWidgets('ignores a second upload tap while permission is pending', (
    tester,
  ) async {
    final store = SessionStore.memory();
    await store.saveProductDetailOrderNo('ORDER-42');
    final client = _FakeFaceApiClient(store);
    final permission = Completer<PermissionStatus>();
    var permissionCalls = 0;

    await _pumpFacePage(
      tester,
      client: client,
      requestCameraPermission: () {
        permissionCalls++;
        return permission.future;
      },
    );

    final button = find.byKey(const Key('identityFaceUploadButton'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();

    expect(permissionCalls, 1);
    permission.complete(PermissionStatus.denied);
    await tester.pumpAndSettle();
  });
}

const _successfulLiveness = TrustDecisionLivenessResult(
  success: true,
  code: 0,
  message: 'success',
  image: 'base64-image',
  sequenceId: 'sequence-42',
  livenessId: 'liveness-42',
  raw: <String, dynamic>{},
);

ApiResponse _tokenResponse({
  String code = '200',
  String message = '',
  int faceType = 7,
}) {
  return ApiResponse(
    code: 0,
    message: 'success',
    states: Json({
      'trihedral': code,
      'squeezer': 'td-license',
      'amputating': message,
      'pileated': faceType,
    }),
  );
}

Future<void> _pumpFacePage(
  WidgetTester tester, {
  required _FakeFaceApiClient client,
  Future<PermissionStatus> Function()? requestCameraPermission,
  Future<bool> Function()? openAppSettingsPage,
  Future<TrustDecisionLivenessResult> Function(String license)?
  showTrustDecisionLiveness,
  Future<String> Function(String imageBase64)? faceImageFilePathBuilder,
  Future<void> Function(String productId)? continueProductDetailFlow,
  List<String>? errors,
  int Function()? nowSeconds,
  Future<void> Function(int startTimeSeconds)? reportRiskScene,
  Future<void> Function(TrustDecisionLivenessResult result)?
  reportTrustDecisionResult,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(Get.reset);
  ScreenAdapter.initForSize(const Size(375, 812));

  await tester.pumpWidget(
    GetMaterialApp(
      home: IdentityFacePage(
        productId: 'product-42',
        cardType: 'PRC',
        apiClient: client,
        requestCameraPermission:
            requestCameraPermission ?? (() async => PermissionStatus.granted),
        openAppSettingsPage: openAppSettingsPage ?? (() async => true),
        showTrustDecisionLiveness:
            showTrustDecisionLiveness ?? ((_) async => _successfulLiveness),
        faceImageFilePathBuilder:
            faceImageFilePathBuilder ?? ((_) async => '/tmp/face.jpg'),
        showLoading: () async {},
        dismissLoading: () async {},
        showError: (message) async => errors?.add(message),
        continueProductDetailFlow: continueProductDetailFlow ?? ((_) async {}),
        nowSeconds: nowSeconds,
        reportRiskScene: reportRiskScene,
        reportTrustDecisionResult: reportTrustDecisionResult,
      ),
    ),
  );
}

class _FakeFaceApiClient extends ApiClient {
  _FakeFaceApiClient(SessionStore store)
    : super(ApiConfig(sessionStore: store));

  ApiResponse tokenResponse = _tokenResponse();
  final List<String> tokenOrders = <String>[];
  final List<String> tokenTypes = <String>[];
  final List<Map<String, Object?>> uploads = <Map<String, Object?>>[];

  @override
  Future<ApiResponse> getFaceIdToken({
    required String orderNo,
    String type = '0',
  }) async {
    tokenOrders.add(orderNo);
    tokenTypes.add(type);
    return tokenResponse;
  }

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
    uploads.add(<String, Object?>{
      'sociologeses': sociologeses,
      'scabble': scabble,
      'filePath': filePath,
      'fileField': fileField,
      'rapscallion': rapscallion,
      'feoffed': feoffed,
      'miscasts': miscasts,
      'pileated': pileated,
      'infantilisms': infantilisms,
    });
    return ApiResponse(code: 0, message: 'success', states: Json({}));
  }
}
