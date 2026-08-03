import 'dart:io';

import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account asset paths are scoped and exist', () {
    const accountAssets = <String>[
      AppAssets.accountBankLabel,
      AppAssets.accountWalletLabel,
      AppAssets.accountCashPickupLabel,
      AppAssets.accountOptionSelected,
      AppAssets.accountOptionUnselected,
      AppAssets.accountAddIcon,
      AppAssets.accountAddMethodBorder,
    ];

    for (final path in accountAssets) {
      expect(path, startsWith('assets/account/'));
      expect(File(path).existsSync(), isTrue, reason: '$path must exist');
    }
  });
}
