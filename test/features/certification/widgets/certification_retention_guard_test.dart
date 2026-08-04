import 'package:dali_cash/features/certification/widgets/certification_retention_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('failed popup falls back to default back', () async {
    var backCount = 0;
    await CertificationRetentionGuard.handleBack(
      type: ' 2 ',
      productId: ' product-1 ',
      onDefaultBack: () => backCount++,
      show: ({required type, required productId, required onExit}) async {
        expect(type, '2');
        expect(productId, 'product-1');
        return false;
      },
    );
    expect(backCount, 1);
  });

  test('shown popup keeps the current page until Exit', () async {
    var backCount = 0;
    await CertificationRetentionGuard.handleBack(
      type: '1',
      productId: 'product-1',
      onDefaultBack: () => backCount++,
      show: ({required type, required productId, required onExit}) async =>
          true,
    );
    expect(backCount, 0);
  });

  test('missing product id uses default back without presenting', () async {
    var backCount = 0;
    var presentCount = 0;
    await CertificationRetentionGuard.handleBack(
      type: '0',
      productId: ' ',
      onDefaultBack: () => backCount++,
      show: ({required type, required productId, required onExit}) async {
        presentCount++;
        return true;
      },
    );
    expect(backCount, 1);
    expect(presentCount, 0);
  });
}
