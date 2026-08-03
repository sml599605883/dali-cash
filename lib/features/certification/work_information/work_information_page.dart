import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/resources/app_assets.dart';
import '../../../core/network/api_client.dart';
import '../certification_information/certification_information_page.dart';
import '../personal_information/personal_information_data.dart';

class WorkInformationPage extends StatelessWidget {
  const WorkInformationPage({
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
  final CertificationInformationLoad? load;
  final CertificationInformationAddressLoad? loadAddresses;
  final CertificationInformationSave? save;
  final CertificationInformationMessage? showError;
  final CertificationInformationContinue? continueFlow;
  final CertificationInformationRiskReport? reportRisk;
  final int Function()? nowSeconds;

  @override
  Widget build(BuildContext context) {
    return CertificationInformationPage(
      productId: productId,
      title: 'Job information',
      defaultPrompt:
          'Add your work details to help us assess your available credit limit.',
      progressAsset: AppAssets.workInformationProgress,
      keyPrefix: 'workInformation',
      riskScene: '6',
      emptyMessage: 'No work information available',
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
    final response = await Get.find<ApiClient>().jobInfo(productId: productId);
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
    await Get.find<ApiClient>().saveJobInfo(
      productId: productId,
      fields: fields,
    );
  }
}
