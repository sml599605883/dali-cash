import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/mine/account_session_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionStore store;
  late _AccountApiClient apiClient;
  late List<String> events;
  late AccountSessionCoordinator coordinator;

  setUp(() async {
    store = SessionStore.memory();
    await store.saveSessionId('session-id');
    await store.savePhone('9123456789');
    await store.saveDeviceInfo(deviceName: 'iPhone 17', physicalSize: '6.3');
    apiClient = _AccountApiClient(store);
    events = <String>[];
    coordinator = AccountSessionCoordinator(
      apiClient: apiClient,
      sessionStore: store,
      showLoading: () async => events.add('loading'),
      dismissLoading: () async => events.add('dismiss'),
      showError: (message) async => events.add('error:$message'),
      returnHome: () async => events.add('home'),
    );
  });

  test('logout clears session, preserves phone, and returns home', () async {
    final succeeded = await coordinator.execute(AccountSessionAction.logout);

    expect(succeeded, isTrue);
    expect(apiClient.logoutCalls, 1);
    expect(apiClient.deleteCalls, 0);
    expect(await store.sessionId(), isEmpty);
    expect(await store.phone(), '9123456789');
    expect(await store.deviceName(), 'iPhone 17');
    expect(events, <String>['loading', 'home', 'dismiss']);
  });

  test('delete account uses delete endpoint before clearing session', () async {
    final succeeded = await coordinator.execute(
      AccountSessionAction.deleteAccount,
    );

    expect(succeeded, isTrue);
    expect(apiClient.logoutCalls, 0);
    expect(apiClient.deleteCalls, 1);
    expect(await store.sessionId(), isEmpty);
    expect(events, <String>['loading', 'home', 'dismiss']);
  });

  test(
    'failure preserves session and leaves the current page visible',
    () async {
      apiClient.logoutError = ApiBusinessException('logout failed');

      final succeeded = await coordinator.execute(AccountSessionAction.logout);

      expect(succeeded, isFalse);
      expect(await store.sessionId(), 'session-id');
      expect(await store.phone(), '9123456789');
      expect(events, <String>['loading', 'error:logout failed']);
    },
  );
}

class _AccountApiClient extends ApiClient {
  _AccountApiClient(SessionStore store) : super(ApiConfig()) {
    config.sessionStore = store;
  }

  int logoutCalls = 0;
  int deleteCalls = 0;
  Object? logoutError;

  @override
  Future<ApiResponse> logout() async {
    logoutCalls++;
    if (logoutError case final error?) throw error;
    return ApiResponse(code: 0, message: '', states: Json(null));
  }

  @override
  Future<ApiResponse> userDelete() async {
    deleteCalls++;
    return ApiResponse(code: 0, message: '', states: Json(null));
  }
}
