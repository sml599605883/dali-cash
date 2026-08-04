import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/core/client/client_bridge.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/features/certification/bind_card/bind_card_data.dart';
import 'package:dali_cash/features/certification/bind_card/bind_card_page.dart';
import 'package:dali_cash/features/certification/widgets/identity_prompt_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads and renders dynamic Lanhu bind-card groups', (
    tester,
  ) async {
    final load = Completer<BindCardData>();
    await _pumpPage(tester, load: (_) => load.future);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    load.complete(_bindCardData());
    await tester.pumpAndSettle();

    expect(find.text('Account management'), findsOneWidget);
    expect(find.text('Choose where to receive your money.'), findsOneWidget);
    expect(find.text('E-wallet'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('Select your recipient E-wallet'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    final progress = tester.widget<Image>(
      find.byKey(const Key('bindCardProgress')),
    );
    expect(
      (progress.image as AssetImage).assetName,
      AppAssets.bindCardProgress,
    );
  });

  testWidgets('uses shared banner with server prompt and footer copy', (
    tester,
  ) async {
    await _pumpPage(tester, load: (_) async => _bindCardData());
    await tester.pumpAndSettle();

    expect(find.byType(IdentityPromptBanner), findsOneWidget);
    expect(find.text('Choose where to receive your money.'), findsOneWidget);
    expect(find.text('Double-check your account details.'), findsOneWidget);
  });

  testWidgets('preserves field state across account tabs', (tester) async {
    await _pumpPage(tester, load: (_) async => _bindCardData());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('bindCardInput_whops')),
      '09171234567',
    );
    await tester.tap(find.byKey(const Key('bindCardTab_2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('bindCardInput_whops')),
      '1234567890',
    );
    await tester.tap(find.byKey(const Key('bindCardTab_1')));
    await tester.pumpAndSettle();

    expect(find.text('09171234567'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bindCardTab_2')));
    await tester.pumpAndSettle();
    expect(find.text('1234567890'), findsOneWidget);
  });

  testWidgets('tapping page space dismisses the focused keyboard', (
    tester,
  ) async {
    await _pumpPage(tester, load: (_) async => _bindCardData());
    await tester.pumpAndSettle();

    final input = find.byKey(const Key('bindCardInput_whops'));
    await tester.tap(input);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    final page = tester.getRect(
      find.byKey(const Key('bindCardDismissKeyboard')),
    );
    await tester.tapAt(page.topRight + const Offset(-8, 8));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('suggestion follows focus and empty text state', (tester) async {
    await _pumpPage(
      tester,
      load: (_) async => _bindCardData(includeSuggestions: true),
    );
    await tester.pumpAndSettle();

    final input = find.byKey(const Key('bindCardInput_rattlesnakes'));
    expect(
      find.byKey(const Key('bindCardSuggestion_rattlesnakes')),
      findsNothing,
    );

    await tester.tap(input);
    await tester.pump();
    expect(find.text('Anna'), findsOneWidget);
    final background = tester.widget<DecoratedBox>(
      find.byKey(const Key('bindCardSuggestionBackground_rattlesnakes')),
    );
    expect(
      (background.decoration as BoxDecoration).color,
      AppColors.bindCardSuggestionBackground,
    );

    await tester.enterText(input, 'A');
    await tester.pump();
    expect(
      find.byKey(const Key('bindCardSuggestion_rattlesnakes')),
      findsNothing,
    );

    await tester.enterText(input, '');
    await tester.pump();
    expect(
      find.byKey(const Key('bindCardSuggestion_rattlesnakes')),
      findsOneWidget,
    );
  });

  testWidgets('closing suggestion leaves the field empty and dismissed', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      load: (_) async => _bindCardData(includeSuggestions: true),
    );
    await tester.pumpAndSettle();

    final input = find.byKey(const Key('bindCardInput_rattlesnakes'));
    await tester.tap(input);
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('bindCardSuggestionClose_rattlesnakes')),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('bindCardSuggestion_rattlesnakes')),
      findsNothing,
    );
    expect(tester.widget<TextField>(input).controller?.text, isEmpty);
  });

  testWidgets('tapping suggestion fills only empty suggested text fields', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      load: (_) async => _bindCardData(includeSuggestions: true),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('bindCardInput_sloid')),
      'User Value',
    );
    final firstName = find.byKey(const Key('bindCardInput_rattlesnakes'));
    await tester.ensureVisible(firstName);
    await tester.pump();
    await tester.tap(firstName);
    await tester.pump();
    await tester.tap(find.byKey(const Key('bindCardSuggestion_rattlesnakes')));
    await tester.pump();

    expect(tester.widget<TextField>(firstName).controller?.text, 'Anna');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('bindCardInput_monerans')))
          .controller
          ?.text,
      'Marie',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('bindCardInput_sloid')))
          .controller
          ?.text,
      'User Value',
    );
  });

  testWidgets('switching account group clears the active suggestion', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      load: (_) async => _bindCardData(includeSuggestions: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardInput_rattlesnakes')));
    await tester.pump();
    expect(
      find.byKey(const Key('bindCardSuggestion_rattlesnakes')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('bindCardTab_2')));
    await tester.pump();
    expect(
      find.byKey(const Key('bindCardSuggestion_rattlesnakes')),
      findsNothing,
    );
  });

  testWidgets('selection displays label and submits normalized value', (
    tester,
  ) async {
    Map<String, String>? savedFields;
    await _pumpPage(
      tester,
      load: (_) async => _bindCardData(),
      save: (productId, cardType, fields, liveness) async {
        savedFields = fields;
        return _response(0);
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardPicker_global')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('COINS e-wallet'));
    await tester.tap(find.byKey(const Key('certificationSelectionDone')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('bindCardInput_whops')),
      '09171234567',
    );
    await tester.enterText(
      find.byKey(const Key('bindCardInput_shallowly')),
      '09171234567',
    );
    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pumpAndSettle();

    expect(find.text('COINS e-wallet'), findsOneWidget);
    expect(savedFields?['global'], '100');
  });

  testWidgets('submits values under server-provided obfuscated field keys', (
    tester,
  ) async {
    Map<String, String>? savedFields;
    await _pumpPage(
      tester,
      load: (_) async => _obfuscatedBindCardData(),
      save: (productId, cardType, fields, liveness) async {
        savedFields = fields;
        return _response(0);
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pumpAndSettle();

    expect(savedFields, {
      'global': '100',
      'rattlesnakes': 'Ana',
      'monerans': 'M',
      'sloid': 'Santos',
      'whops': '09171234567',
      'shallowly': '09171234567',
    });
  });

  testWidgets('blocks mismatched obfuscated account fields', (tester) async {
    final errors = <String>[];
    var saveCount = 0;
    await _pumpPage(
      tester,
      load: (_) async => _obfuscatedBindCardData(
        accountValue: '09171234567',
        confirmationValue: '09999999999',
      ),
      showError: (message) async => errors.add(message),
      save: (productId, cardType, fields, liveness) async {
        saveCount++;
        return _response(0);
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pump();

    expect(saveCount, 0);
    expect(errors, ['Account numbers do not match']);
  });

  testWidgets('blocks mismatched account confirmation', (tester) async {
    final errors = <String>[];
    var saveCount = 0;
    await _pumpPage(
      tester,
      load: (_) async => _bindCardData(channelValue: '100'),
      showError: (message) async => errors.add(message),
      save: (productId, cardType, fields, liveness) async {
        saveCount++;
        return _response(0);
      },
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('bindCardInput_whops')),
      '09171234567',
    );
    await tester.enterText(
      find.byKey(const Key('bindCardInput_shallowly')),
      '09999999999',
    );
    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pump();

    expect(saveCount, 0);
    expect(errors, ['Account numbers do not match']);
  });

  testWidgets('normal success reports scene 8 and continues', (tester) async {
    final reports = <String>[];
    final continuations = <String>[];
    await _pumpPage(
      tester,
      load: (_) async =>
          _bindCardData(channelValue: '100', accountValue: '09171234567'),
      save: (productId, cardType, fields, liveness) async => _response(0),
      reportRisk: (productId, startedAtSeconds) async {
        reports.add('$productId:$startedAtSeconds');
      },
      continueFlow: (productId) async => continuations.add(productId),
      nowSeconds: () => 123,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pumpAndSettle();

    expect(reports, ['product-42:123']);
    expect(continuations, ['product-42']);
  });

  testWidgets(
    'account-change success replaces bind flow with a fresh WebView',
    (tester) async {
      final changes = <String>[];
      final replacements = <String>[];
      final continuations = <String>[];
      final reports = <String>[];
      await _pumpPage(
        tester,
        orderNo: 'ORDER-3',
        isAccountChange: true,
        load: (_) async =>
            _bindCardData(channelValue: '100', accountValue: '09171234567'),
        save: (productId, cardType, fields, liveness) async =>
            ApiResponse(code: 0, message: '', states: Json({'hoover': '5326'})),
        changeAccount: ({required orderNo, required bindId}) async {
          changes.add('$orderNo:$bindId');
          return ApiResponse(
            code: 0,
            message: '',
            states: Json({'misericorde': 'https://h5.example/changed'}),
          );
        },
        replaceWithWebView: ({required url}) async {
          replacements.add(url);
        },
        continueFlow: (productId) async => continuations.add(productId),
        reportRisk: (productId, startedAtSeconds) async {
          reports.add('$productId:$startedAtSeconds');
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bindCardUpload')));
      await tester.pumpAndSettle();

      expect(changes, ['ORDER-3:5326']);
      expect(replacements, ['https://h5.example/changed']);
      expect(continuations, isEmpty);
      expect(reports, isEmpty);
    },
  );

  for (final missing in <String>['order', 'bind', 'redirect']) {
    testWidgets('account-change rejects missing $missing data', (tester) async {
      final errors = <String>[];
      var changeCount = 0;
      var replacementCount = 0;
      await _pumpPage(
        tester,
        orderNo: missing == 'order' ? '' : 'ORDER-3',
        isAccountChange: true,
        load: (_) async =>
            _bindCardData(channelValue: '100', accountValue: '09171234567'),
        save: (productId, cardType, fields, liveness) async => ApiResponse(
          code: 0,
          message: '',
          states: Json({'hoover': missing == 'bind' ? '' : '5326'}),
        ),
        changeAccount: ({required orderNo, required bindId}) async {
          changeCount++;
          return ApiResponse(
            code: 0,
            message: '',
            states: Json({
              'misericorde': missing == 'redirect'
                  ? ''
                  : 'https://h5.example/changed',
            }),
          );
        },
        replaceWithWebView: ({required url}) async {
          replacementCount++;
        },
        showError: (message) async => errors.add(message),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bindCardUpload')));
      await tester.pumpAndSettle();

      expect(errors, hasLength(1));
      expect(replacementCount, 0);
      expect(changeCount, missing == 'order' || missing == 'bind' ? 0 : 1);
    });
  }

  testWidgets('account-change rejects an invalid redirect url', (tester) async {
    final errors = <String>[];
    var replacementCount = 0;
    await _pumpPage(
      tester,
      orderNo: 'ORDER-3',
      isAccountChange: true,
      load: (_) async =>
          _bindCardData(channelValue: '100', accountValue: '09171234567'),
      save: (productId, cardType, fields, liveness) async =>
          ApiResponse(code: 0, message: '', states: Json({'hoover': '5326'})),
      changeAccount: ({required orderNo, required bindId}) async => ApiResponse(
        code: 0,
        message: '',
        states: Json({'misericorde': 'dali-cash://account-changed'}),
      ),
      replaceWithWebView: ({required url}) async => replacementCount++,
      showError: (message) async => errors.add(message),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pumpAndSettle();

    expect(replacementCount, 0);
    expect(errors, ['Invalid account change result url']);
  });

  testWidgets('code 20000 completes TrustDecision and resubmits once', (
    tester,
  ) async {
    final payloads = <BindCardLivenessPayload>[];
    final reports = <TrustDecisionLivenessResult>[];
    await _pumpPage(
      tester,
      load: (_) async =>
          _bindCardData(channelValue: '100', accountValue: '09171234567'),
      save: (productId, cardType, fields, liveness) async {
        payloads.add(liveness);
        return _response(payloads.length == 1 ? 20000 : 0);
      },
      requestCameraPermission: () async => PermissionStatus.granted,
      loadLivenessToken: () async => const BindCardLivenessToken(
        code: '200',
        license: 'license-42',
        faceType: 7,
        message: '',
      ),
      showTrustDecisionLiveness: (_) async => const TrustDecisionLivenessResult(
        success: true,
        code: 0,
        message: '',
        image: '',
        sequenceId: 'sequence-42',
        livenessId: 'liveness-42',
        raw: <String, dynamic>{},
      ),
      reportTrustDecisionResult: (result) async => reports.add(result),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pumpAndSettle();

    expect(payloads, hasLength(2));
    expect(payloads.first.isEmpty, isTrue);
    expect(payloads.last.type, '7');
    expect(payloads.last.livenessId, 'liveness-42');
    expect(payloads.last.license, 'license-42');
    expect(reports, hasLength(1));
    expect(reports.single.livenessId, 'liveness-42');
  });

  testWidgets('TrustDecision cancellation is reported without resubmitting', (
    tester,
  ) async {
    final errors = <String>[];
    final reports = <TrustDecisionLivenessResult>[];
    var saveCount = 0;
    const cancelled = TrustDecisionLivenessResult(
      success: false,
      code: 3001,
      message: 'Liveness cancelled',
      image: '',
      sequenceId: '',
      livenessId: '',
      raw: <String, dynamic>{},
    );
    await _pumpPage(
      tester,
      load: (_) async =>
          _bindCardData(channelValue: '100', accountValue: '09171234567'),
      save: (productId, cardType, fields, liveness) async {
        saveCount++;
        return _response(20000);
      },
      showError: (message) async => errors.add(message),
      requestCameraPermission: () async => PermissionStatus.granted,
      loadLivenessToken: () async => const BindCardLivenessToken(
        code: '200',
        license: 'license-42',
        faceType: 7,
        message: '',
      ),
      showTrustDecisionLiveness: (_) async => cancelled,
      reportTrustDecisionResult: (result) async => reports.add(result),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pumpAndSettle();

    expect(saveCount, 1);
    expect(errors, ['Liveness cancelled']);
    expect(reports, [cancelled]);
  });

  testWidgets('locks duplicate uploads while save is pending', (tester) async {
    final pending = Completer<ApiResponse>();
    var saveCount = 0;
    await _pumpPage(
      tester,
      load: (_) async =>
          _bindCardData(channelValue: '100', accountValue: '09171234567'),
      save: (productId, cardType, fields, liveness) {
        saveCount++;
        return pending.future;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pump();
    expect(saveCount, 1);

    pending.complete(_response(0));
    await tester.pumpAndSettle();
  });

  testWidgets('shows initialization error and retries to empty state', (
    tester,
  ) async {
    var attempts = 0;
    await _pumpPage(
      tester,
      load: (_) async {
        attempts++;
        if (attempts == 1) throw StateError('Network unavailable');
        return const BindCardData(groups: [], topPrompt: '', bottomPrompt: '');
      },
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Network unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('No payment methods available'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('camera denial does not launch TrustDecision', (tester) async {
    var livenessCalls = 0;
    await _pumpPage(
      tester,
      load: (_) async =>
          _bindCardData(channelValue: '100', accountValue: '09171234567'),
      save: (productId, cardType, fields, liveness) async => _response(20000),
      requestCameraPermission: () async => PermissionStatus.denied,
      showTrustDecisionLiveness: (_) async {
        livenessCalls++;
        return _successfulLiveness;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Camera permission required'), findsOneWidget);
    expect(livenessCalls, 0);
  });

  testWidgets('second code 20000 stops without a liveness loop', (
    tester,
  ) async {
    final errors = <String>[];
    var saveCount = 0;
    await _pumpPage(
      tester,
      load: (_) async =>
          _bindCardData(channelValue: '100', accountValue: '09171234567'),
      save: (productId, cardType, fields, liveness) async {
        saveCount++;
        return _response(20000);
      },
      showError: (message) async => errors.add(message),
      requestCameraPermission: () async => PermissionStatus.granted,
      loadLivenessToken: () async => const BindCardLivenessToken(
        code: '200',
        license: 'license-42',
        faceType: 7,
        message: '',
      ),
      showTrustDecisionLiveness: (_) async => _successfulLiveness,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardUpload')));
    await tester.pumpAndSettle();

    expect(saveCount, 2);
    expect(errors, ['Liveness verification was not accepted']);
  });

  test('parses the existing Dali liveness token contract', () {
    final token = BindCardLivenessToken.fromResponse(
      ApiResponse(
        code: 0,
        message: '',
        states: Json({
          'trihedral': '200',
          'squeezer': 'license-42',
          'pileated': 7,
          'amputating': '',
        }),
      ),
    );

    expect(token.code, '200');
    expect(token.license, 'license-42');
    expect(token.faceType, 7);
  });

  testWidgets('matches the Lanhu bind-card layout', (tester) async {
    await _pumpPage(
      tester,
      load: (_) async => _bindCardData(includeSuggestions: true),
    );
    await tester.pumpAndSettle();
    await _waitForAsset(
      tester,
      const Key('bindCardProgress'),
      AppAssets.bindCardProgress,
    );
    final firstName = find.byKey(const Key('bindCardInput_rattlesnakes'));
    await tester.ensureVisible(firstName);
    await tester.tap(firstName);
    await tester.pump();
    await _waitForAsset(
      tester,
      const Key('bindCardSuggestionClose_rattlesnakes'),
      AppAssets.bindCardSuggestionClose,
    );

    await expectLater(
      find.byType(BindCardPage),
      matchesGoldenFile('goldens/bind_card_page.png'),
    );
    await _clearAssetImageState(tester);
  });

  test('golden paints the blue progress asset above the form panel', () async {
    final bytes = await File(
      'test/features/certification/bind_card/goldens/bind_card_page.png',
    ).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    var primaryPixels = 0;
    for (var y = 108; y < 176; y++) {
      for (var x = 8; x < 145; x++) {
        final offset = (y * image.width + x) * 4;
        if (data!.getUint8(offset) == 60 &&
            data.getUint8(offset + 1) == 108 &&
            data.getUint8(offset + 2) == 243) {
          primaryPixels++;
        }
      }
    }
    image.dispose();
    codec.dispose();

    expect(primaryPixels, greaterThan(100));
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required BindCardLoad load,
  String orderNo = '',
  bool isAccountChange = false,
  BindCardSave? save,
  BindCardMessage? showError,
  BindCardContinue? continueFlow,
  BindCardChangeAccount? changeAccount,
  BindCardWebViewReplacement? replaceWithWebView,
  BindCardRiskReport? reportRisk,
  int Function()? nowSeconds,
  BindCardCameraPermissionRequester? requestCameraPermission,
  BindCardTokenLoad? loadLivenessToken,
  BindCardLivenessLauncher? showTrustDecisionLiveness,
  Future<void> Function(TrustDecisionLivenessResult result)?
  reportTrustDecisionResult,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(375, 812);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  return tester.pumpWidget(
    MaterialApp(
      home: BindCardPage(
        productId: 'product-42',
        orderNo: orderNo,
        isAccountChange: isAccountChange,
        load: load,
        save: save,
        showError: showError ?? (_) async {},
        continueFlow: continueFlow ?? (_) async {},
        changeAccount: changeAccount,
        replaceWithWebView: replaceWithWebView,
        reportRisk: reportRisk ?? (_, _) async {},
        nowSeconds: nowSeconds,
        requestCameraPermission: requestCameraPermission,
        loadLivenessToken: loadLivenessToken,
        showTrustDecisionLiveness: showTrustDecisionLiveness,
        reportTrustDecisionResult: reportTrustDecisionResult,
      ),
    ),
  );
}

BindCardData _bindCardData({
  String channelValue = '',
  String accountValue = '',
  bool includeSuggestions = false,
}) {
  return BindCardData.fromJson(
    Json({
      'choired': [
        {
          'enterostomy': 'E-wallet',
          'sociologeses': 1,
          'choired': [
            {
              'enterostomy': 'Select your recipient E-wallet',
              'felicitous': 'global',
              'laggings': 'Please select',
              'solferino': 'KrimmersOpinioned',
              'muscats': 0,
              'fyke': channelValue,
              'poolsides': [
                {
                  'sociologeses': 100,
                  'crocidolites': 'COINS e-wallet',
                  'leachate': '',
                  'precolonial': 1,
                },
              ],
            },
            {
              'enterostomy': 'E-wallet Account',
              'felicitous': 'whops',
              'laggings': 'Please enter your E-wallet account',
              'solferino': 'Haphtaras',
              'muscats': 0,
              'omegas': 1,
              'fyke': accountValue,
            },
            if (includeSuggestions) ...[
              {
                'enterostomy': 'First Name',
                'felicitous': 'rattlesnakes',
                'laggings': 'Please enter your first name',
                'solferino': 'Haphtaras',
                'muscats': 0,
                'fyke': '',
                'degringolade': 'Anna',
              },
              {
                'enterostomy': 'Middle Name',
                'felicitous': 'monerans',
                'laggings': 'Please enter your middle name',
                'solferino': 'Haphtaras',
                'muscats': 1,
                'fyke': '',
                'degringolade': 'Marie',
              },
              {
                'enterostomy': 'Last Name',
                'felicitous': 'sloid',
                'laggings': 'Please enter your last name',
                'solferino': 'Haphtaras',
                'muscats': 0,
                'fyke': '',
                'degringolade': 'Cruz',
              },
            ],
            {
              'enterostomy': 'Repeat E-wallet Account',
              'felicitous': 'shallowly',
              'laggings': 'Ensure the account number is correct',
              'solferino': 'Haphtaras',
              'muscats': 0,
              'omegas': 1,
              'fyke': accountValue,
            },
          ],
        },
        {
          'enterostomy': 'Bank',
          'sociologeses': 2,
          'choired': [
            {
              'enterostomy': 'Bank Account',
              'felicitous': 'whops',
              'laggings': 'Please enter your bank account',
              'solferino': 'Haphtaras',
              'muscats': 0,
              'fyke': '',
            },
          ],
        },
      ],
      'dextrorse': 'Choose where to receive your money.',
      'brabble': 'Double-check your account details.',
    }),
  );
}

BindCardData _obfuscatedBindCardData({
  String accountValue = '09171234567',
  String confirmationValue = '09171234567',
}) {
  final values = {
    'global': '100',
    'rattlesnakes': 'Ana',
    'monerans': 'M',
    'sloid': 'Santos',
    'whops': accountValue,
    'shallowly': confirmationValue,
  };
  return BindCardData.fromJson(
    Json({
      'choired': [
        {
          'enterostomy': 'E-wallet',
          'sociologeses': 1,
          'choired': [
            for (final entry in values.entries)
              {
                'enterostomy': entry.key,
                'felicitous': entry.key,
                'solferino': 'Haphtaras',
                'muscats': entry.key == 'monerans' ? 1 : 0,
                'fyke': entry.value,
              },
          ],
        },
      ],
    }),
  );
}

ApiResponse _response(int code) {
  return ApiResponse(code: code, message: '', states: Json({}));
}

const _successfulLiveness = TrustDecisionLivenessResult(
  success: true,
  code: 0,
  message: '',
  image: '',
  sequenceId: 'sequence-42',
  livenessId: 'liveness-42',
  raw: <String, dynamic>{},
);

Future<void> _waitForAsset(
  WidgetTester tester,
  Key key,
  String assetName,
) async {
  final context = tester.element(find.byKey(key));
  await tester.runAsync(() => precacheImage(AssetImage(assetName), context));
  await tester.pump();
  final rawImageFinder = find.descendant(
    of: find.byKey(key),
    matching: find.byType(RawImage),
  );
  for (var attempt = 0; attempt < 20; attempt++) {
    final renderImage = tester.renderObject<RenderImage>(rawImageFinder);
    if (renderImage.image != null) return;
    await tester.pump(const Duration(milliseconds: 16));
  }
  fail('Asset $key did not decode');
}

Future<void> _clearAssetImageState(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
}
