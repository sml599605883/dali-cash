import 'dart:async';

import 'package:dali_cash/app/app.dart';
import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/home/home_page.dart';
import 'package:dali_cash/features/mine/mine_page.dart';
import 'package:dali_cash/features/orders/mine_order_list_page.dart';
import 'package:dali_cash/features/progress/progress_page.dart';
import 'package:dali_cash/features/progress/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/test_main_binding.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  Widget testApp() => DaliCashApp(initialBinding: testMainBinding());

  Future<void> openMine(
    WidgetTester tester, {
    Size size = const Size(375, 812),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(testApp());
    await tester.tap(find.byKey(const Key('tab-mine')));
    await tester.pump();
  }

  Future<void> openAccountDialog(WidgetTester tester) async {
    await openMine(tester);
    await tester.ensureVisible(find.byKey(const Key('mine-account')));
    await tester.tap(find.byKey(const Key('mine-account')));
    await tester.pumpAndSettle();
  }

  Future<void> openRetentionDialog(WidgetTester tester, Key actionKey) async {
    await openAccountDialog(tester);
    await tester.tap(find.byKey(actionKey));
    await tester.pumpAndSettle();
  }

  Future<void> pumpMineWithVersion(
    WidgetTester tester,
    Future<String> Function() loadVersion,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ScreenAdapter.init(context);
            return MinePage(loadAppVersion: loadVersion);
          },
        ),
      ),
    );
  }

  testWidgets('starts on Home with Home selected', (tester) async {
    await tester.pumpWidget(testApp());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(const Key('tab-home-selected')), findsOneWidget);
    expect(find.text('Dali Cash'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('home-loan-offer-card')),
        matching: find.text('₱60,000'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-loan-offer-card')),
        matching: find.text('180 Days'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-loan-offer-card')),
        matching: find.text('≤ 0.5% Day'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-apply-now')), findsOneWidget);
  });

  testWidgets('switches between progress and Mine tabs', (tester) async {
    await tester.pumpWidget(testApp());

    await tester.tap(find.byKey(const Key('tab-progress')));
    await tester.pump();
    expect(find.byType(ProgressPage), findsOneWidget);
    expect(find.byKey(const Key('tab-progress-selected')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tab-mine')));
    await tester.pump();
    expect(find.byType(MinePage), findsOneWidget);
    expect(find.byKey(const Key('tab-mine-selected')), findsOneWidget);
  });

  testWidgets('renders the empty progress state', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ScreenAdapter.init(context);
            return const ProgressPage(items: <ProgressItem>[]);
          },
        ),
      ),
    );

    expect(find.text('No progress yet'), findsOneWidget);
    expect(find.byKey(const Key('progress-empty-image')), findsOneWidget);
    expect(find.byKey(const Key('progress-card')), findsNothing);
  });

  testWidgets('maps emblemize states to their card presentation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const items = [
      ProgressItem(emblemize: ProgressEmblemize.disbursementFailed),
      ProgressItem(emblemize: ProgressEmblemize.disbursing),
      ProgressItem(emblemize: ProgressEmblemize.activeLoan),
      ProgressItem(emblemize: ProgressEmblemize.inReview),
      ProgressItem(emblemize: ProgressEmblemize.overdue),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ScreenAdapter.init(context);
            return const ProgressPage(items: items);
          },
        ),
      ),
    );

    expect(find.text('Disbursement Failed'), findsOneWidget);
    expect(find.text('Disbursing'), findsOneWidget);
    expect(find.text('Active Loan'), findsOneWidget);
    expect(find.text('In Review'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.byKey(const Key('progress-retry')), findsOneWidget);
    expect(find.byKey(const Key('progress-change')), findsNWidgets(3));
    expect(find.byKey(const Key('progress-blue-card')), findsNWidgets(3));
    expect(find.byKey(const Key('progress-red-card')), findsNWidgets(2));
  });

  testWidgets('does not overflow on a compact screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('keeps the customer service button clear of the title', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());

    final titleRect = tester.getRect(find.text('Dali Cash'));
    final customerServiceRect = tester.getRect(
      find.byKey(const Key('home-customer-service')),
    );

    expect(titleRect.overlaps(customerServiceRect), isFalse);
  });

  testWidgets('renders the product name on its Lanhu gradient', (tester) async {
    await tester.pumpWidget(testApp());

    final gradientFinder = find.byKey(const Key('home-product-gradient'));
    expect(gradientFinder, findsOneWidget);

    final decoratedBox = tester.widget<DecoratedBox>(gradientFinder);
    final decoration = decoratedBox.decoration as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;

    expect(gradient.colors, [
      const Color.fromRGBO(255, 252, 209, 1),
      AppColors.surface,
    ]);
  });

  testWidgets('sizes the loan card from available width and image ratio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());

    final cardFinder = find.byKey(const Key('home-loan-offer-card'));
    expect(cardFinder, findsOneWidget);

    final cardRect = tester.getRect(cardFinder);
    expect(cardRect.width, 343);
    expect(cardRect.width / cardRect.height, closeTo(343 / 355, 0.0001));

    final card = tester.widget<Container>(cardFinder);
    final decoration = card.decoration as BoxDecoration;
    final background = decoration.image!.image as AssetImage;
    expect(background.assetName, AppAssets.homeLoanCardBackground);
  });

  testWidgets('logs one card tap from content and Apply Now', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await tester.pumpWidget(testApp());

      await tester.tap(find.byKey(const Key('home-loan-offer-card')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('home-apply-now')));
      await tester.pump();

      expect(messages, [
        '[HomePage] Loan offer card tapped',
        '[HomePage] Loan offer card tapped',
      ]);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('renders one highlighted default recommendation', (tester) async {
    tester.view.physicalSize = const Size(375, 1098);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());

    expect(find.text('Recommendation'), findsOneWidget);
    expect(find.byKey(const Key('home-recommendation-card-1')), findsOneWidget);
    expect(find.byKey(const Key('home-recommendation-card-0')), findsNothing);
    expect(find.text('₱60,000'), findsNWidgets(2));

    final cardWidget = tester.widget<Widget>(
      find.byKey(const Key('home-recommendation-card-1')),
    );
    expect(cardWidget, isA<Container>());
    final applyBackgroundFinder = find.byKey(
      const Key('home-recommendation-apply-background-1'),
    );
    expect(applyBackgroundFinder, findsOneWidget);
    final applyBackground = tester.widget<DecoratedBox>(applyBackgroundFinder);
    final decoration = applyBackground.decoration as BoxDecoration;
    expect(
      (decoration.image!.image as AssetImage).assetName,
      'assets/home/recommendation_apply_highlight.png',
    );

    final termsPanelFinder = find.byKey(
      const Key('home-recommendation-terms-panel'),
    );
    expect(termsPanelFinder, findsOneWidget);
    final termsPanel = tester.widget<Container>(termsPanelFinder);
    final termsDecoration = termsPanel.decoration as BoxDecoration;
    expect(termsDecoration.color, AppColors.divider);
    expect(termsDecoration.borderRadius, BorderRadius.circular(8));
    expect(termsPanel.padding, const EdgeInsets.fromLTRB(8, 8, 20, 8));
    expect(tester.getSize(termsPanelFinder), const Size(144, 48));

    final productLogoFinder = find.byKey(
      const Key('home-recommendation-product-logo'),
    );
    expect(tester.getSize(productLogoFinder), const Size(12, 12));

    final cardFinder = find.byKey(const Key('home-recommendation-card-1'));
    final productName = tester.widget<Text>(
      find.descendant(of: cardFinder, matching: find.text('PG Finance')),
    );
    expect(productName.style!.fontSize, 10);

    final recommendationAmount = tester.widget<Text>(
      find.descendant(of: cardFinder, matching: find.text('₱60,000')),
    );
    expect(recommendationAmount.style!.fontSize, 24);
    expect(
      recommendationAmount.style!.color,
      const Color.fromRGBO(7, 16, 40, 1),
    );

    final amountCaption = tester.widget<Text>(
      find.descendant(of: cardFinder, matching: find.text('Available up to')),
    );
    expect(amountCaption.style!.fontSize, 12);
    expect(amountCaption.style!.color, const Color.fromRGBO(153, 153, 153, 1));

    final footer = tester.widget<Text>(
      find.descendant(
        of: cardFinder,
        matching: find.text(
          'Low interest rates / Ages 17 years and over can borrow',
        ),
      ),
    );
    expect(footer.style!.fontSize, 8);

    final applyLabel = tester.widget<Text>(
      find.descendant(of: cardFinder, matching: find.text('Apply\nNow')),
    );
    expect(applyLabel.style!.fontSize, 18);
    expect(applyLabel.style!.height, 30 / 18);
  });

  testWidgets('renders the Lanhu Mine content with semantic assets', (
    tester,
  ) async {
    await openMine(tester);

    expect(find.text('Mine'), findsNWidgets(2));
    for (final label in <String>[
      '962 **** 1300',
      'View All',
      'Unpaid',
      'Late',
      'Paid',
      'Smart customer service',
      'Website',
      'xxxxx.com',
      'APP Version',
      'Privacy Agreement',
      'Account',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    expect(find.byKey(const Key('mine-order-all')), findsOneWidget);
    expect(find.byKey(const Key('mine-customer-service')), findsOneWidget);
    expect(find.byKey(const Key('mine-copy-website')), findsOneWidget);
    expect(find.byKey(const Key('mine-app-version')), findsOneWidget);
  });

  test('formats the stored phone with the Mine masking style', () {
    expect(formatMinePhone('9123456789'), '912 **** 6789');
    expect(formatMinePhone('1234567'), '1234567');
    expect(formatMinePhone('   '), '');
  });

  testWidgets('logs one message for each actionable Mine entry', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await openMine(tester, size: const Size(375, 1200));

      final expectations = <Key, String>{
        const Key('mine-website'): '[MinePage] Website tapped',
        const Key('mine-copy-website'): '[MinePage] Copy Website tapped',
        const Key('mine-account'): '[MinePage] Account tapped',
      };

      for (final entry in expectations.entries) {
        messages.clear();
        await tester.ensureVisible(find.byKey(entry.key));
        await tester.tap(find.byKey(entry.key));
        await tester.pump();
        expect(messages, <String>[entry.value]);
      }
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('opens the dedicated order list from all Mine shortcuts', (
    tester,
  ) async {
    await openMine(tester, size: const Size(375, 1200));

    final expectations = <Key, String>{
      const Key('mine-order-all'): '4',
      const Key('mine-order-unpaid'): '7',
      const Key('mine-order-late'): '6',
      const Key('mine-order-paid'): '5',
    };
    for (final entry in expectations.entries) {
      await tester.ensureVisible(find.byKey(entry.key));
      await tester.tap(find.byKey(entry.key));
      await tester.pumpAndSettle();

      expect(find.byType(MineOrderListPage), findsOneWidget);
      expect(
        find.byKey(ValueKey('orderTabSelected-${entry.value}')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('mineOrderBack')));
      await tester.pumpAndSettle();
      expect(find.byType(MinePage), findsOneWidget);
    }
  });

  testWidgets('keeps APP Version display-only', (tester) async {
    await openMine(tester);
    expect(find.byKey(const Key('mine-app-version-action')), findsNothing);
  });

  testWidgets('renders the installed app version without the build number', (
    tester,
  ) async {
    await pumpMineWithVersion(tester, () async => '1.0.0');
    await tester.pump();

    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.textContaining('(1)'), findsNothing);
  });

  testWidgets('shows the app version fallback while loading', (tester) async {
    final completer = Completer<String>();

    await pumpMineWithVersion(tester, () => completer.future);

    expect(find.text('v--'), findsOneWidget);
  });

  testWidgets('shows the app version fallback when loading fails', (
    tester,
  ) async {
    await pumpMineWithVersion(
      tester,
      () async => throw StateError('package metadata unavailable'),
    );
    await tester.pumpAndSettle();

    expect(find.text('v--'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loads the app version only once across rebuilds', (
    tester,
  ) async {
    var calls = 0;
    await pumpMineWithVersion(tester, () async {
      calls += 1;
      return '2.3.4';
    });
    await tester.pump();
    await tester.pump();

    expect(find.text('v2.3.4'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('opens the Lanhu account action dialog from Account', (
    tester,
  ) async {
    await openAccountDialog(tester);

    expect(find.byKey(const Key('account-actions-dialog')), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('account-actions-sheet'))),
      const Size(375, 170),
    );

    final material = tester.widget<Material>(
      find.byKey(const Key('account-actions-sheet')),
    );
    expect(
      material.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(24)),
    );
  });

  testWidgets('logs Log out and closes the account action dialog', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await openAccountDialog(tester);
      messages.clear();

      await tester.tap(find.byKey(const Key('account-action-log-out')));
      await tester.pumpAndSettle();

      expect(messages, <String>['[MinePage] Log out tapped']);
      expect(find.byKey(const Key('account-actions-dialog')), findsNothing);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('logs Delete Account and closes the account action dialog', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await openAccountDialog(tester);
      messages.clear();

      await tester.tap(find.byKey(const Key('account-action-delete')));
      await tester.pumpAndSettle();

      expect(messages, <String>['[MinePage] Delete Account tapped']);
      expect(find.byKey(const Key('account-actions-dialog')), findsNothing);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('closes the account action dialog from Quit without logging', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await openAccountDialog(tester);
      messages.clear();

      await tester.tap(find.byKey(const Key('account-action-quit')));
      await tester.pumpAndSettle();

      expect(messages, isEmpty);
      expect(find.byKey(const Key('account-actions-dialog')), findsNothing);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('dismisses the account action dialog from the barrier', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await openAccountDialog(tester);
      messages.clear();

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(messages, isEmpty);
      expect(find.byKey(const Key('account-actions-dialog')), findsNothing);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('replaces Account actions with the logout retention dialog', (
    tester,
  ) async {
    await openRetentionDialog(tester, const Key('account-action-log-out'));

    expect(find.byKey(const Key('account-actions-sheet')), findsNothing);
    expect(find.byKey(const Key('account-retention-dialog')), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Keep Me In'), findsOneWidget);
    expect(
      find.text(
        'Stay logged in to receive instant alerts on your limit and payments.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('replaces Account actions with the deletion retention dialog', (
    tester,
  ) async {
    await openRetentionDialog(tester, const Key('account-action-delete'));

    expect(find.byKey(const Key('account-actions-sheet')), findsNothing);
    expect(find.byKey(const Key('account-retention-dialog')), findsOneWidget);
    expect(find.text('Keep Account'), findsOneWidget);
    expect(
      find.text(
        'Once deleted, all your credit history and limit disappear. Stay with us?',
      ),
      findsOneWidget,
    );
  });

  testWidgets('scales retention card from screen width', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final width in <double>[320, 375, 414]) {
      tester.view.physicalSize = Size(width, 812);
      await tester.pumpWidget(testApp());
      await tester.tap(find.byKey(const Key('tab-mine')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('mine-account')));
      await tester.tap(find.byKey(const Key('mine-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-action-log-out')));
      await tester.pumpAndSettle();

      final cardSize = tester.getSize(
        find.byKey(const Key('account-retention-card')),
      );
      final cardWidth = width - 32;
      expect(cardSize.width, closeTo(cardWidth, 0.1), reason: 'width=$width');
      expect(
        cardSize.height,
        closeTo(cardWidth * 332 / 343, 0.1),
        reason: 'width=$width',
      );

      await tester.tap(find.byKey(const Key('account-retention-close')));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('logs Keep Me In and closes the logout retention dialog', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await openRetentionDialog(tester, const Key('account-action-log-out'));
      messages.clear();
      await tester.tap(find.byKey(const Key('account-retention-keep')));
      await tester.pumpAndSettle();

      expect(messages, <String>['[MinePage] Keep Me In tapped']);
      expect(find.byKey(const Key('account-retention-dialog')), findsNothing);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('logs Keep Account and closes the deletion retention dialog', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await openRetentionDialog(tester, const Key('account-action-delete'));
      messages.clear();
      await tester.tap(find.byKey(const Key('account-retention-keep')));
      await tester.pumpAndSettle();

      expect(messages, <String>['[MinePage] Keep Account tapped']);
      expect(find.byKey(const Key('account-retention-dialog')), findsNothing);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('logs Close Anyway and closes both retention dialogs', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    final messages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      for (final actionKey in <Key>[
        const Key('account-action-log-out'),
        const Key('account-action-delete'),
      ]) {
        await openRetentionDialog(tester, actionKey);
        messages.clear();
        await tester.tap(find.byKey(const Key('account-retention-close')));
        await tester.pumpAndSettle();

        expect(messages, <String>['[MinePage] Close Anyway tapped']);
        expect(find.byKey(const Key('account-retention-dialog')), findsNothing);
      }
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('rounds the customer service card to the Lanhu radius', (
    tester,
  ) async {
    await openMine(tester);

    final clip = tester.widget<ClipRRect>(
      find.byKey(const Key('mine-customer-service-card')),
    );
    expect(clip.borderRadius, BorderRadius.circular(12));
  });

  testWidgets('keeps the order shortcuts inside the card at common widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final width in <double>[375, 390, 393, 414, 430]) {
      tester.view.physicalSize = Size(width, 812);
      await tester.pumpWidget(testApp());
      await tester.tap(find.byKey(const Key('tab-mine')));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'width=$width');
    }
  });

  testWidgets('lets the order card grow past its design minimum when needed', (
    tester,
  ) async {
    await openMine(tester);

    final card = tester.widget<Container>(
      find.byKey(const Key('mine-order-card')),
    );
    expect(card.constraints!.minHeight, 95);
    expect(card.constraints!.maxHeight, double.infinity);
  });

  testWidgets('renders Mine without overflow on a compact screen', (
    tester,
  ) async {
    await openMine(tester, size: const Size(320, 568));
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Account'), findsOneWidget);
  });
}
