import 'dart:io';

import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Progress empty asset uses a semantic path and exists', () {
    expect(AppAssets.progressEmpty, 'assets/progress/progress_empty.png');
    expect(File(AppAssets.progressEmpty).existsSync(), isTrue);
  });

  test('order empty asset uses a semantic path and exists', () {
    expect(AppAssets.orderEmpty, 'assets/orders/order_empty.png');
    expect(File(AppAssets.orderEmpty).existsSync(), isTrue);
  });

  test('Credit Activation Progress assets use semantic paths and exist', () {
    final assets = <String>[
      AppAssets.activationProgressCoin,
      AppAssets.activationProgressArrowActive,
      AppAssets.activationProgressArrowInactive,
      AppAssets.activationProgressTrack,
    ];

    expect(assets, <String>[
      'assets/home/activation_progress_coin.png',
      'assets/home/activation_progress_arrow_active.png',
      'assets/home/activation_progress_arrow_inactive.png',
      'assets/home/activation_progress_track.png',
    ]);
    for (final asset in assets) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test(
    'account assets have semantic names and exactly match the directory',
    () {
      const accountAssets = <String>[
        AppAssets.accountBankLabel,
        AppAssets.accountWalletLabel,
        AppAssets.accountCashPickupLabel,
        AppAssets.accountOptionSelected,
        AppAssets.accountOptionUnselected,
        AppAssets.accountAddIcon,
        AppAssets.accountAddMethodBorder,
      ];
      final semanticFileName = RegExp(r'^account_[a-z0-9_]+\.png$');

      for (final path in accountAssets) {
        expect(path, startsWith('assets/account/'));
        expect(File(path).uri.pathSegments.last, matches(semanticFileName));
        expect(File(path).existsSync(), isTrue, reason: '$path must exist');
      }

      final expectedPaths = accountAssets.toList()..sort();
      final actualPaths = Directory(
        'assets/account',
      ).listSync().whereType<File>().map((file) => file.path).toList()..sort();

      expect(actualPaths, expectedPaths);
    },
  );
}
