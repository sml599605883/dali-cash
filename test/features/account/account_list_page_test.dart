import 'dart:async';

import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/account/account_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads all account layouts and selects the main account', (
    tester,
  ) async {
    final pending = Completer<Json>();
    await _pumpPage(tester, load: (_) => pending.future);

    expect(find.byKey(const Key('accountListLoading')), findsOneWidget);
    pending.complete(_accounts());
    await tester.pumpAndSettle();

    expect(find.text('Loan Confirmation'), findsOneWidget);
    expect(find.byKey(const Key('accountListItem-bind-bank')), findsOneWidget);
    expect(
      find.byKey(const Key('accountListItem-bind-wallet')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('accountListItem-bind-cash')), findsOneWidget);
    expect(find.text('Receipt Account'), findsNWidgets(2));
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Middle Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('accountListContent'))).width,
      343,
    );
    expect(
      _selectionAsset(tester, 'bind-bank'),
      'assets/account/account_option_selected.png',
    );
  });

  testWidgets('maintenance account remains selectable and submits once', (
    tester,
  ) async {
    final submissions = <String>[];
    final replacements = <String>[];
    final pending = Completer<String>();
    await _pumpPage(
      tester,
      load: (_) async => _accounts(mainBindId: 'bind-wallet'),
      submit: ({required orderNo, required bindId}) {
        submissions.add('$orderNo:$bindId');
        return pending.future;
      },
      replace: (url) async => replacements.add(url),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accountListItem-bind-bank')));
    await tester.tap(find.byKey(const Key('accountListConfirm')));
    await tester.tap(find.byKey(const Key('accountListConfirm')));
    expect(submissions, ['ORDER-1:bind-bank']);

    pending.complete(' https://h5.test/changed ');
    await tester.pumpAndSettle();
    expect(replacements, ['https://h5.test/changed']);
  });

  testWidgets('shows load error and retries', (tester) async {
    var attempts = 0;
    await _pumpPage(
      tester,
      load: (_) async {
        attempts++;
        if (attempts == 1) throw StateError('load failed');
        return _accounts();
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Bad state: load failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byKey(const Key('accountListItem-bind-bank')), findsOneWidget);
  });

  testWidgets('empty state can add a method and cannot confirm', (
    tester,
  ) async {
    final additions = <String>[];
    await _pumpPage(
      tester,
      load: (_) async => Json({'clingiest': <dynamic>[]}),
      addMethod: ({required productId, required orderNo}) async {
        additions.add('$productId:$orderNo');
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('No payment methods available'), findsOneWidget);
    final confirm = tester.widget<ElevatedButton>(
      find.byKey(const Key('accountListConfirm')),
    );
    expect(confirm.onPressed, isNull);
    await tester.tap(find.byKey(const Key('accountAddPaymentMethod')));
    expect(additions, ['product-1:ORDER-1']);
  });

  for (final missingProduct in <bool>[true, false]) {
    testWidgets(
      'missing ${missingProduct ? 'product' : 'order'} does not load',
      (tester) async {
        var loads = 0;
        await _pumpPage(
          tester,
          productId: missingProduct ? '' : 'product-1',
          orderNo: missingProduct ? 'ORDER-1' : '',
          load: (_) async {
            loads++;
            return _accounts();
          },
        );
        await tester.pumpAndSettle();

        expect(loads, 0);
        expect(
          find.text(
            missingProduct
                ? 'Missing product information'
                : 'Missing order information',
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('submit failure keeps selection and re-enables Confirm', (
    tester,
  ) async {
    final errors = <String>[];
    await _pumpPage(
      tester,
      load: (_) async => _accounts(),
      submit: ({required orderNo, required bindId}) async => '',
      showError: (message) async => errors.add(message),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accountListConfirm')));
    await tester.pumpAndSettle();

    expect(errors, ['Missing account change result url']);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('accountListConfirm')))
          .onPressed,
      isNotNull,
    );
    expect(
      _selectionAsset(tester, 'bind-bank'),
      'assets/account/account_option_selected.png',
    );
  });

  testWidgets('375x896 layout remains scrollable without overflow', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      size: const Size(375, 896),
      load: (_) async => _accounts(),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('accountListContent'))).width,
      343,
    );
  });

  testWidgets('disposed submit completion does not update stale state', (
    tester,
  ) async {
    final pending = Completer<String>();
    await _pumpPage(
      tester,
      load: (_) async => _accounts(),
      submit: ({required orderNo, required bindId}) => pending.future,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accountListConfirm')));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    pending.completeError(StateError('late failure'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  String productId = 'product-1',
  String orderNo = 'ORDER-1',
  Size size = const Size(375, 812),
  required AccountListLoad load,
  AccountListSubmit? submit,
  AccountListAddMethod? addMethod,
  AccountListReplace? replace,
  AccountListMessage? showError,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: AccountListPage(
        productId: productId,
        orderNo: orderNo,
        load: load,
        submit:
            submit ??
            ({required orderNo, required bindId}) async =>
                'https://h5.test/changed',
        addMethod:
            addMethod ?? ({required productId, required orderNo}) async {},
        replace: replace ?? (_) async {},
        showError: showError ?? (_) async {},
      ),
    ),
  );
}

Json _accounts({String mainBindId = 'bind-bank'}) => Json({
  'clingiest': [
    {
      'rapscallion': 'bank',
      'pater': 'Bank',
      'alodia': '',
      'jambes': [
        {
          'hoover': 'bind-bank',
          'filmcards': 'BDO',
          'emptiable': '**** 1234',
          'precolonial': 0,
          'exploitable': mainBindId == 'bind-bank' ? 1 : 0,
        },
      ],
    },
    {
      'rapscallion': 'wallet',
      'pater': 'E-wallet',
      'jambes': [
        {
          'hoover': 'bind-wallet',
          'filmcards': 'GCash',
          'emptiable': '0917 000 0000',
          'precolonial': 1,
          'exploitable': mainBindId == 'bind-wallet' ? 1 : 0,
        },
      ],
    },
    {
      'rapscallion': 'cash',
      'pater': 'Cash Pickup',
      'jambes': [
        {
          'hoover': 'bind-cash',
          'filmcards': 'Cebuana',
          'nonbehavioral': {
            'rattlesnakes': 'Ana',
            'monerans': 'M',
            'sloid': 'Santos',
          },
          'precolonial': 1,
          'exploitable': mainBindId == 'bind-cash' ? 1 : 0,
        },
      ],
    },
  ],
});

String _selectionAsset(WidgetTester tester, String bindId) {
  final image = tester.widget<Image>(
    find.descendant(
      of: find.byKey(Key('accountListItem-$bindId')),
      matching: find.byKey(Key('accountListSelection-$bindId')),
    ),
  );
  return (image.image as AssetImage).assetName;
}
