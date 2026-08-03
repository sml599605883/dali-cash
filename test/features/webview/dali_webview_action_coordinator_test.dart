import 'package:dali_cash/features/webview/dali_webview_action_coordinator.dart';
import 'package:dali_cash/features/webview/dali_webview_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> events;
  late DaliWebViewActionCoordinator coordinator;

  setUp(() {
    events = <String>[];
    coordinator = DaliWebViewActionCoordinator(
      reportRisk:
          ({
            required productId,
            required orderNo,
            required startedAtSeconds,
          }) async {
            events.add('risk:$productId:$orderNo:$startedAtSeconds');
          },
      openWebView: (url) async => events.add('webview:$url'),
      navigateInternal: (url) async => events.add('internal:$url'),
      openExternal: (uri) async {
        events.add('external:$uri');
        return true;
      },
      closePage: () async => events.add('close'),
      jumpHome: () async => events.add('home'),
      requestAppReview: () async => events.add('grade'),
      buildPublicParams: (path) async => <String, dynamic>{'path': path},
      retryOrder: (orderNo) async {
        events.add('retry:$orderNo');
        return 'https://h5.example/retry';
      },
      replaceWebView: (url) async => events.add('replace:$url'),
      changeAccount: ({required productId, required orderNo}) async {
        events.add('change:$productId:$orderNo');
      },
      showLoading: () async => events.add('loading'),
      dismissLoading: () async => events.add('dismiss'),
      showError: (message) async => events.add('error:$message'),
      logger: events.add,
      nowSeconds: () => 123,
    );
  });

  test('uploads scene-10 risk using Dali product and order fields', () async {
    final result = await coordinator.dispatch(
      DaliWebViewRequest.decode({
        'action': DaliWebViewActions.uploadRisk,
        'data': {'thunderstruck': 'product-1', 'saggards': 42},
      }),
    );

    expect(events, ['risk:product-1:42:123']);
    expect(result.code, 0);
  });

  test('routes HTTP, Dali ph, and external schemes by capability', () async {
    for (final url in <String>[
      'https://h5.example/details',
      'ph://dali-cash/ios/Personation',
      'tel:+639171234567',
    ]) {
      final result = await coordinator.dispatch(
        DaliWebViewRequest.decode({
          'action': DaliWebViewActions.openUrl,
          'data': url,
        }),
      );
      expect(result.code, 0);
    }

    expect(events, [
      'webview:https://h5.example/details',
      'internal:ph://dali-cash/ios/Personation',
      'external:tel:+639171234567',
    ]);
  });

  test('Google Play is log-only on iOS and succeeds', () async {
    final result = await coordinator.dispatch(
      DaliWebViewRequest.decode({
        'action': DaliWebViewActions.openGooglePlay,
        'data': 'com.example.loan',
      }),
    );

    expect(events, [
      'Google Play action ignored on iOS: package=com.example.loan',
    ]);
    expect(result.code, 0);
  });

  test('close, home, and grade invoke their actions once', () async {
    for (final action in <String>[
      DaliWebViewActions.close,
      DaliWebViewActions.home,
      DaliWebViewActions.grade,
    ]) {
      expect(
        (await coordinator.dispatch(
          DaliWebViewRequest.decode({'action': action}),
        )).code,
        0,
      );
    }

    expect(events, ['close', 'home', 'grade']);
  });

  test('returns signed public params as callback data', () async {
    final result = await coordinator.dispatch(
      DaliWebViewRequest.decode({
        'action': DaliWebViewActions.publicParams,
        'data': '/lutes/pedants?thunderstruck=1',
      }),
    );

    expect(result.code, 0);
    expect(result.data, {'path': '/lutes/pedants?thunderstruck=1'});
  });

  test('retry always dismisses loading and opens a fresh WebView', () async {
    final result = await coordinator.dispatch(
      DaliWebViewRequest.decode({
        'action': DaliWebViewActions.retryOrder,
        'data': {'saggards': 'ORDER-2'},
      }),
    );

    expect(events, [
      'loading',
      'retry:ORDER-2',
      'replace:https://h5.example/retry',
      'dismiss',
    ]);
    expect(result.code, 0);
  });

  test(
    'validates and delegates account change without replacing here',
    () async {
      final success = await coordinator.dispatch(
        DaliWebViewRequest.decode({
          'action': DaliWebViewActions.changeAccount,
          'data': {'thunderstruck': 'product-3', 'saggards': 'ORDER-3'},
        }),
      );
      final failure = await coordinator.dispatch(
        DaliWebViewRequest.decode({
          'action': DaliWebViewActions.changeAccount,
          'data': {'thunderstruck': 'product-3'},
        }),
      );

      expect(events, ['change:product-3:ORDER-3']);
      expect(success.code, 0);
      expect(failure.code, -1);
      expect(failure.message, 'Missing account information');
    },
  );

  test(
    'invalid actions and callback exceptions return stable failures',
    () async {
      final unsupported = await coordinator.dispatch(
        DaliWebViewRequest.decode({'action': 'unknown'}),
      );
      coordinator = DaliWebViewActionCoordinator(
        requestAppReview: () async => throw StateError('review failed'),
        showError: (message) async => events.add('error:$message'),
      );
      final failed = await coordinator.dispatch(
        DaliWebViewRequest.decode({'action': DaliWebViewActions.grade}),
      );

      expect(unsupported.code, -2);
      expect(failed.code, -1);
      expect(failed.message, contains('review failed'));
      expect(events.single, contains('review failed'));
    },
  );
}
