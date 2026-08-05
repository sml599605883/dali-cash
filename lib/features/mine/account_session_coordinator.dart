import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/session/session_store.dart';

enum AccountSessionAction { logout, deleteAccount }

typedef AccountSessionAsyncAction = Future<void> Function();
typedef AccountSessionMessage = Future<void> Function(String message);

class AccountSessionCoordinator {
  const AccountSessionCoordinator({
    required this.apiClient,
    required this.sessionStore,
    required this.showLoading,
    required this.dismissLoading,
    required this.showError,
    required this.returnHome,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final AccountSessionAsyncAction showLoading;
  final AccountSessionAsyncAction dismissLoading;
  final AccountSessionMessage showError;
  final AccountSessionAsyncAction returnHome;

  Future<bool> execute(AccountSessionAction action) async {
    await showLoading();
    try {
      await switch (action) {
        AccountSessionAction.logout => apiClient.logout(),
        AccountSessionAction.deleteAccount => apiClient.userDelete(),
      };
      await sessionStore.clearPersistent();
      await returnHome();
      await dismissLoading();
      return true;
    } catch (error) {
      await showError(ApiErrorMessage.resolve(error));
      return false;
    }
  }
}
