import 'package:dali_cash/core/session/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores session and normalized device info', () async {
    final store = SessionStore.memory();

    await store.saveSessionId('session-id');
    await store.saveDeviceInfo(deviceName: 'iPhone 17', physicalSize: '6.3');

    expect(await store.sessionId(), 'session-id');
    expect(await store.deviceName(), 'iPhone 17');
    expect(await store.physicalSize(), '6.3');
  });

  test('clearPersistent removes session and device info', () async {
    final store = SessionStore.memory();
    await store.saveSessionId('session-id');
    await store.saveDeviceInfo(deviceName: 'iPhone 17', physicalSize: '6.3');

    await store.clearPersistent();

    expect(await store.sessionId(), '');
    expect(await store.deviceName(), '');
    expect(await store.physicalSize(), '');
  });

  test('stores phone and preserves it when clearing the session', () async {
    final store = SessionStore.memory();
    await store.saveSessionId('session-id');
    await store.savePhone('9123456789');

    await store.clearPersistent();

    expect(await store.sessionId(), '');
    expect(await store.phone(), '9123456789');
  });
}
