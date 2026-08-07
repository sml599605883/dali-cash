import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/session/session_store.dart';

typedef LoginAsyncAction = Future<void> Function();
typedef LoginMessagePresenter = Future<void> Function(String message);

class LoginController extends GetxController {
  LoginController({
    required this.apiClient,
    required this.sessionStore,
    required this.showLoading,
    required this.dismissLoading,
    required this.showMessage,
    required this.onLoginSuccess,
    this.dismissKeyboard = _dismissKeyboard,
    this.countdownInterval = const Duration(seconds: 1),
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final LoginAsyncAction showLoading;
  final LoginAsyncAction dismissLoading;
  final LoginMessagePresenter showMessage;
  final LoginAsyncAction onLoginSuccess;
  final VoidCallback dismissKeyboard;
  final Duration countdownInterval;

  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final codeFocusNode = FocusNode();

  Timer? _countdownTimer;
  bool agreementAccepted = true;
  bool requestingCode = false;
  bool loggingIn = false;
  int countdownSeconds = 0;

  bool get canSubmit {
    return phoneController.text.trim().isNotEmpty &&
        codeController.text.trim().length == 6 &&
        agreementAccepted &&
        !loggingIn;
  }

  bool get canRequestCode {
    return phoneController.text.trim().isNotEmpty &&
        countdownSeconds == 0 &&
        !requestingCode;
  }

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(_refresh);
    codeController.addListener(_onCodeChanged);
    unawaited(loadRememberedPhone());
  }

  Future<void> loadRememberedPhone() async {
    final phone = await sessionStore.phone();
    if (isClosed || phone.isEmpty || phoneController.text.isNotEmpty) {
      return;
    }
    phoneController.value = TextEditingValue(
      text: phone,
      selection: TextSelection.collapsed(offset: phone.length),
    );
  }

  void toggleAgreement() {
    agreementAccepted = !agreementAccepted;
    update();
  }

  Future<void> requestSmsCode() async {
    if (!canRequestCode) {
      return;
    }
    requestingCode = true;
    update();
    try {
      await showLoading();
      final response = await apiClient.sendSmsCode(
        phone: phoneController.text.trim(),
      );
      await dismissLoading();
      await showMessage(response.message);
      if (isClosed) {
        return;
      }
      codeFocusNode.requestFocus();
      _startCountdown();
    } catch (error) {
      await dismissLoading();
      await showMessage(ApiErrorMessage.resolve(error));
    } finally {
      requestingCode = false;
      if (!isClosed) {
        update();
      }
    }
  }

  Future<void> submitSmsCode() async {
    if (loggingIn ||
        phoneController.text.trim().isEmpty ||
        codeController.text.trim().length != 6) {
      return;
    }
    dismissKeyboard();
    if (!agreementAccepted) {
      await showMessage('Please agree to the Privacy Policy');
      return;
    }
    loggingIn = true;
    update();
    try {
      await showLoading();
      final phone = phoneController.text.trim();
      final response = await apiClient.smsCodeLogin(
        phone: phone,
        code: codeController.text.trim(),
      );
      final sessionId = response.states['crestfallen'].stringValue;
      if (sessionId.isEmpty) {
        throw ApiBusinessException('Invalid login response');
      }
      await sessionStore.saveSessionId(sessionId);
      await sessionStore.savePhone(phone);
      await dismissLoading();
      await onLoginSuccess();
    } catch (error) {
      await dismissLoading();
      codeController.clear();
      if (!isClosed) {
        codeFocusNode.requestFocus();
      }
      await showMessage(ApiErrorMessage.resolve(error));
    } finally {
      loggingIn = false;
      if (!isClosed) {
        update();
      }
    }
  }

  void _onCodeChanged() {
    _refresh();
    if (codeController.text.trim().length == 6) {
      unawaited(submitSmsCode());
    }
  }

  void _refresh() {
    if (!isClosed) {
      update();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    countdownSeconds = 60;
    update();
    _countdownTimer = Timer.periodic(countdownInterval, (timer) {
      if (isClosed || countdownSeconds <= 1) {
        timer.cancel();
        countdownSeconds = 0;
      } else {
        countdownSeconds--;
      }
      if (!isClosed) {
        update();
      }
    });
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    phoneController
      ..removeListener(_refresh)
      ..dispose();
    codeController
      ..removeListener(_onCodeChanged)
      ..dispose();
    codeFocusNode.dispose();
    super.onClose();
  }
}

void _dismissKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
}
