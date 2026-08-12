import 'package:dali_cash/core/report/dali_report_data.dart';
import 'package:dali_cash/core/report/dali_report_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores only state needed by Dali reports', () async {
    final store = DaliReportStore.memory();
    const location = DaliLocationSnapshot(
      latitude: '14.5547',
      longitude: '121.0244',
      city: 'Makati',
    );

    await store.saveLoginAt(1234);
    await store.saveLocation(location);
    await store.markAdjustInitialized();

    expect(await store.loginAt(), 1234);
    expect((await store.cachedLocation())?.city, 'Makati');
    expect(await store.isAdjustInitialized(), isTrue);
  });

  test('marks only the first app launch as first', () async {
    final store = DaliReportStore.memory();

    expect(await store.markAppOpened(), isTrue);
    expect(await store.markAppOpened(), isFalse);
  });

  test('clears only location state from the previous app run', () async {
    final store = DaliReportStore.memory();
    await store.saveLoginAt(1234);
    await store.saveLocation(
      const DaliLocationSnapshot(latitude: '14.5547', longitude: '121.0244'),
    );
    await store.markAdjustInitialized();

    await store.clearSessionReportState();

    expect(await store.cachedLocation(), isNull);
    expect(await store.loginAt(), 1234);
    expect(await store.isAdjustInitialized(), isTrue);
  });

  test('does not restore an invalid cached location', () async {
    final store = DaliReportStore.memory();
    await store.saveLocation(DaliLocationSnapshot.empty);

    expect(await store.cachedLocation(), isNull);
  });
}
