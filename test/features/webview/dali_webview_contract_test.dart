import 'dart:convert';

import 'package:dali_cash/features/webview/dali_webview_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes the exact Dali H5 handler and actions', () {
    expect(DaliWebViewContract.handler, 'ph_dali_cash_ios');
    expect(DaliWebViewActions.uploadRisk, 'dali_cash_RbGtlAKg2Hsx7x5');
    expect(DaliWebViewActions.openGooglePlay, 'dali_cash_HjU4mCaWf9VcOI6');
    expect(DaliWebViewActions.openUrl, 'dali_cash_dudAaHWAtJmjS2T');
    expect(DaliWebViewActions.close, 'dali_cash_jWPoDsrg054lhUC');
    expect(DaliWebViewActions.home, 'dali_cash_Ax2ivGQo70e2KIR');
    expect(DaliWebViewActions.grade, 'dali_cash_L9ePULguB5v2O84');
    expect(DaliWebViewActions.retryOrder, 'dali_cash_U5sqmkouwbyYVRT');
    expect(DaliWebViewActions.changeAccount, 'dali_cash_dzaSV8NeJkdm0di');
    expect(DaliWebViewActions.publicParams, 'dali_cash_YDtfWHIcQnY8cfk');
  });

  test('decodes object messages and normalizes map keys', () {
    final request = DaliWebViewRequest.decode(<Object?, Object?>{
      'action': DaliWebViewActions.uploadRisk,
      'callbackId': 'callback-1',
      'data': <Object?, Object?>{
        'thunderstruck': 'product-1',
        7: 'numeric-key',
        'saggards': 42,
      },
    });

    expect(request.action, DaliWebViewActions.uploadRisk);
    expect(request.callbackId, 'callback-1');
    expect(request.expectsCallback, isTrue);
    expect(request.data['thunderstruck'], 'product-1');
    expect(request.data['7'], 'numeric-key');
    expect(request.data['saggards'], 42);
  });

  test('decodes JSON messages and object payload aliases', () {
    final request = DaliWebViewRequest.decode(
      jsonEncode(<String, Object?>{
        'name': DaliWebViewActions.changeAccount,
        'id': 'callback-2',
        'payload': jsonEncode(<String, String>{
          'thunderstruck': 'product-2',
          'saggards': 'ORDER-2',
        }),
      }),
    );

    expect(request.action, DaliWebViewActions.changeAccount);
    expect(request.callbackId, 'callback-2');
    expect(request.data, {'thunderstruck': 'product-2', 'saggards': 'ORDER-2'});
  });

  test('preserves raw string data for URL and public params actions', () {
    final request = DaliWebViewRequest.decode({
      'action': DaliWebViewActions.publicParams,
      'data': ' /lutes/pedants?thunderstruck=1 ',
    });

    expect(request.rawDataString, '/lutes/pedants?thunderstruck=1');
    expect(request.data, isEmpty);
    expect(request.expectsCallback, isFalse);
  });

  test('malformed messages return an empty request without throwing', () {
    expect(DaliWebViewRequest.decode('{invalid').action, isEmpty);
    expect(DaliWebViewRequest.decode(null).action, isEmpty);
    expect(DaliWebViewRequest.decode(<String, Object?>{}).action, isEmpty);
  });

  test('encodes stable success and failure result shapes', () {
    expect(const DaliWebViewResult.success({'signed': true}).toJson(), {
      'code': 0,
      'message': 'success',
      'data': {'signed': true},
    });
    expect(
      const DaliWebViewResult.failure('Invalid action', code: -2).toJson(),
      {'code': -2, 'message': 'Invalid action', 'data': <String, dynamic>{}},
    );
  });
}
