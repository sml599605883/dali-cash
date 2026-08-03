import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/resources/app_assets.dart';
import '../../../core/network/api_client.dart';
import '../certification_information/certification_information_page.dart';
import 'personal_information_data.dart';

typedef PersonalInformationLoad =
    Future<PersonalInformationData> Function(String productId);
typedef PersonalInformationAddressLoad =
    Future<List<PersonalAddressNode>> Function();
typedef PersonalInformationSave =
    Future<void> Function(String productId, Map<String, String> fields);
typedef PersonalInformationMessage = Future<void> Function(String message);
typedef PersonalInformationContinue = Future<void> Function(String productId);
typedef PersonalInformationRiskReport =
    Future<void> Function(String productId, int startedAtSeconds);

class PersonalInformationPage extends StatelessWidget {
  const PersonalInformationPage({
    super.key,
    this.productId = '',
    this.load,
    this.loadAddresses,
    this.save,
    this.showError,
    this.continueFlow,
    this.reportRisk,
    this.nowSeconds,
  });

  final String productId;
  final PersonalInformationLoad? load;
  final PersonalInformationAddressLoad? loadAddresses;
  final PersonalInformationSave? save;
  final PersonalInformationMessage? showError;
  final PersonalInformationContinue? continueFlow;
  final PersonalInformationRiskReport? reportRisk;
  final int Function()? nowSeconds;

  @override
  Widget build(BuildContext context) {
    return CertificationInformationPage(
      productId: productId,
      title: 'Basic identity information',
      defaultPrompt:
          'Add your work details to help us assess your available credit limit.',
      progressAsset: AppAssets.personalInformationProgress,
      keyPrefix: 'personalInformation',
      riskScene: '5',
      load: load ?? _defaultLoad,
      loadAddresses: loadAddresses ?? _defaultLoadAddresses,
      save: save ?? _defaultSave,
      showError: showError,
      continueFlow: continueFlow,
      reportRisk: reportRisk,
      nowSeconds: nowSeconds,
    );
  }

  Future<PersonalInformationData> _defaultLoad(String productId) async {
    final response = await Get.find<ApiClient>().personalInfo(
      productId: productId,
    );
    return PersonalInformationData.fromJson(response.states);
  }

  Future<List<PersonalAddressNode>> _defaultLoadAddresses() async {
    final response = await Get.find<ApiClient>().addressInit();
    return PersonalAddressNode.parseList(response.states);
  }

  Future<void> _defaultSave(
    String productId,
    Map<String, String> fields,
  ) async {
    await Get.find<ApiClient>().savePersonalInfo(
      productId: productId,
      fields: fields,
    );
  }
}
