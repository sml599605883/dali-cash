import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:dali_cash/features/main_shell/main_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  test('creates a permanent default client and controller when absent', () {
    MainBinding().dependencies();

    expect(Get.find<ApiClient>(), isA<ApiClient>());
    expect(Get.find<MainController>(), isA<MainController>());
  });

  test(
    'creates a permanent injected client and controller when absent',
    () async {
      final client = ApiClient(ApiConfig());
      MainBinding(apiClient: client, showError: fail).dependencies();

      expect(Get.find<ApiClient>(), same(client));
      expect(Get.find<MainController>(), isA<MainController>());
      expect(await Get.delete<ApiClient>(), isFalse);
      expect(Get.isRegistered<ApiClient>(), isTrue);
    },
  );

  test('wires injected presenters into the registered controller', () async {
    final client = _PresenterApiClient();
    final errors = <String>[];
    final notices = <String>[];

    MainBinding(
      apiClient: client,
      showError: errors.add,
      showNotice: notices.add,
      showLoading: () async {},
      dismissLoading: () async {},
    ).dependencies();

    expect(Get.find<ApiClient>(), same(client));
    final controller = Get.find<MainController>();
    await controller.requestHomeDataIfVisible();
    await controller.requestHomeDataIfVisible();

    expect(errors, ['Home unavailable']);
    await pumpEventQueue();
    expect(notices, ['New information available', 'New information available']);
  });

  test('preserves a pre-registered client when creating controller', () {
    final registeredClient = ApiClient(ApiConfig());
    final injectedClient = ApiClient(ApiConfig());
    Get.put<ApiClient>(registeredClient);

    MainBinding(apiClient: injectedClient).dependencies();

    expect(Get.find<ApiClient>(), same(registeredClient));
    expect(Get.find<MainController>().apiClient, same(registeredClient));
  });

  test('preserves a pre-registered controller while registering client', () {
    final injectedClient = ApiClient(ApiConfig());
    final controllerClient = ApiClient(ApiConfig());
    final registeredController = MainController(
      apiClient: controllerClient,
      showError: (_) {},
      showNotice: (_) {},
    );
    Get.put<MainController>(registeredController);

    MainBinding(apiClient: injectedClient).dependencies();

    expect(Get.find<ApiClient>(), same(injectedClient));
    expect(Get.find<MainController>(), same(registeredController));
  });
}

class _PresenterApiClient extends ApiClient {
  _PresenterApiClient() : super(ApiConfig());

  int homeCalls = 0;

  @override
  Future<ApiResponse> homePage() async {
    homeCalls++;
    if (homeCalls == 1) {
      throw ApiBusinessException('Home unavailable');
    }
    return ApiResponse(
      code: 0,
      message: '',
      states: Json(const <String, dynamic>{}),
    );
  }

  @override
  Future<ApiResponse> dialog({required int scene}) async {
    return ApiResponse(code: 0, message: '', states: Json({'sociologeses': 1}));
  }
}
