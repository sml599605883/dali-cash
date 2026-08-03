import 'dart:convert';
import 'dart:io';

import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/webview/dali_webview_contract.dart';
import 'package:dali_cash/features/webview/dali_webview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows only document schemes inside Dali WebView', () {
    expect(isInlineDaliWebViewScheme('https'), isTrue);
    expect(isInlineDaliWebViewScheme('about'), isTrue);
    expect(isInlineDaliWebViewScheme('tel'), isFalse);
    expect(isInlineDaliWebViewScheme('ph'), isFalse);
  });

  test('closes the Flutter route only without WebView history', () {
    expect(shouldCloseDaliWebView(canGoBack: true), isFalse);
    expect(shouldCloseDaliWebView(canGoBack: false), isTrue);
  });

  test('recognizes only Florescences confirm URLs and Dali product field', () {
    expect(
      daliConfirmProductId(
        'https://h5.example/#/Florescences?thunderstruck=product-9',
      ),
      'product-9',
    );
    expect(
      daliConfirmProductId(
        'https://h5.example/Florescences?thunderstruck=product-10',
      ),
      'product-10',
    );
    expect(
      daliConfirmProductId(
        'https://h5.example/#/SlinkierDesulfured?thunderstruck=product-9',
      ),
      isEmpty,
    );
  });

  test('uses controller only while it is still active', () {
    final controller = Object();
    expect(
      canUseDaliWebViewController(
        mounted: false,
        activeController: controller,
        controller: controller,
      ),
      isFalse,
    );
    expect(
      canUseDaliWebViewController(
        mounted: true,
        activeController: Object(),
        controller: controller,
      ),
      isFalse,
    );
    expect(
      canUseDaliWebViewController(
        mounted: true,
        activeController: controller,
        controller: controller,
      ),
      isTrue,
    );
  });

  test('bridge gate registers only while resumed and removes on pause', () {
    final events = <String>[];
    final controller = Object();
    final gate = DaliWebViewBridgeGate(
      addHandler: (value) => events.add('add:${identical(value, controller)}'),
      removeHandler: (value) =>
          events.add('remove:${identical(value, controller)}'),
    );

    gate.attach(controller);
    gate.setForeground(false);
    gate.setForeground(true);
    gate.detach();

    expect(events, ['add:true', 'remove:true', 'add:true', 'remove:true']);
  });

  test('callback JavaScript forwards callbackId and result data only', () {
    final request = DaliWebViewRequest.decode({
      'action': DaliWebViewActions.publicParams,
      'callbackId': 'cb-7',
    });
    final script = daliWebViewCallbackScript(
      request,
      const DaliWebViewResult.success({'signed': true}),
    );
    final json = script!
        .split('handleMessage(')
        .last
        .substring(0, script.split('handleMessage(').last.length - 2);

    expect(jsonDecode(json), {
      'callbackId': 'cb-7',
      'data': {'signed': true},
    });
    expect(
      daliWebViewCallbackScript(
        DaliWebViewRequest.decode({'action': DaliWebViewActions.close}),
        const DaliWebViewResult.success(),
      ),
      isNull,
    );
  });

  test('only main-frame failures replace the whole page', () {
    expect(shouldShowDaliWebViewLoadError(isForMainFrame: true), isTrue);
    expect(shouldShowDaliWebViewLoadError(isForMainFrame: false), isFalse);
    expect(shouldShowDaliWebViewLoadError(isForMainFrame: null), isFalse);
  });

  test('account availability follows Dali clingiest rows', () {
    expect(
      hasDaliWebViewAccounts(
        Json({
          'clingiest': [
            {'hoover': '1'},
          ],
        }),
      ),
      isTrue,
    );
    expect(hasDaliWebViewAccounts(Json({'clingiest': []})), isFalse);
  });

  test('account destination follows existing Dali account rows', () {
    expect(
      daliAccountDestination(
        Json({
          'clingiest': [
            {'hoover': 'bind-1'},
          ],
        }),
      ),
      DaliAccountDestination.accountList,
    );
    expect(
      daliAccountDestination(Json({'clingiest': []})),
      DaliAccountDestination.bindCard,
    );
    expect(
      daliAccountDestination(Json({'clingiest': 'malformed'})),
      DaliAccountDestination.bindCard,
    );
  });

  testWidgets(
    'invalid initial URL shows a stable error without platform view',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DaliWebViewPage(initialUrl: 'not-a-url')),
      );

      expect(find.text('Invalid page address'), findsOneWidget);
    },
  );

  test('wires Dali capabilities, security settings, and exact API fields', () {
    final source = File(
      '${Directory.current.path}/lib/features/webview/dali_webview_page.dart',
    ).readAsStringSync();

    expect(source, contains("scene: '10'"));
    expect(
      source,
      contains('requestAppReview: ClientBridge().requestAppReview'),
    );
    expect(source, contains("states['misericorde']"));
    expect(source, contains("states['clingiest']"));
    expect(source, contains('toAccountList'));
    expect(source, contains('isAccountChange: true'));
    expect(source, contains('PermissionResponseAction.DENY'));
    expect(source, contains('MixedContentMode.MIXED_CONTENT_NEVER_ALLOW'));
    expect(source, contains('confirm retention popup is not available'));
  });
}
