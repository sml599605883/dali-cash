import '../../core/json/json.dart';

class ProductDetailData {
  const ProductDetailData({
    required this.statusCode,
    required this.product,
    required this.nextStep,
    required this.pageCopy,
  });

  factory ProductDetailData.fromJson(Json states) {
    return ProductDetailData(
      statusCode: states['tucking'].intValue,
      product: ProductDetailProductData.fromJson(states['shoepac']),
      nextStep: ProductDetailNextStepData.fromJson(states['spirochaete']),
      pageCopy: ProductDetailPageCopy.fromJson(states['poolsides']),
    );
  }

  final int statusCode;
  final ProductDetailProductData product;
  final ProductDetailNextStepData nextStep;
  final ProductDetailPageCopy pageCopy;
}

class ProductDetailProductData {
  const ProductDetailProductData({
    required this.amount,
    required this.productId,
    required this.productName,
    required this.orderNo,
    required this.orderId,
    required this.term,
    required this.termType,
    required this.customerServiceUrl,
  });

  factory ProductDetailProductData.fromJson(Json json) {
    return ProductDetailProductData(
      amount: json['injective'].stringValue,
      productId: json['underfeeding'].stringValue,
      productName: json['preslaughter'].stringValue,
      orderNo: json['saggards'].stringValue,
      orderId: json['filers'].intValue,
      term: json['resmooth'].stringValue,
      termType: json['mispatch'].intValue,
      customerServiceUrl: json['friendlinesses'].stringValue,
    );
  }

  final String amount;
  final String productId;
  final String productName;
  final String orderNo;
  final int orderId;
  final String term;
  final int termType;
  final String customerServiceUrl;
}

class ProductDetailNextStepData {
  const ProductDetailNextStepData({required this.type, required this.title});

  factory ProductDetailNextStepData.fromJson(Json json) {
    return ProductDetailNextStepData(
      type: json['entrecote'].stringValue,
      title: json['enterostomy'].stringValue,
    );
  }

  final String type;
  final String title;
}

class ProductDetailPageCopy {
  const ProductDetailPageCopy({
    required this.identityUpload,
    required this.identityConfirmation,
    required this.faceVerification,
    required this.personalInformation,
    required this.workInformation,
    required this.emergencyContact,
    required this.bindCardTop,
    required this.bindCardBottom,
  });

  factory ProductDetailPageCopy.fromJson(Json json) {
    return ProductDetailPageCopy(
      identityUpload: json['distention'].stringValue,
      identityConfirmation: json['hoddens'].stringValue,
      faceVerification: json['variety'].stringValue,
      personalInformation: json['sizars'].stringValue,
      workInformation: json['ultracasual'].stringValue,
      emergencyContact: json['blueberries'].stringValue,
      bindCardTop: json['disorganization'].stringValue,
      bindCardBottom: json['brabble'].stringValue,
    );
  }

  final String identityUpload;
  final String identityConfirmation;
  final String faceVerification;
  final String personalInformation;
  final String workInformation;
  final String emergencyContact;
  final String bindCardTop;
  final String bindCardBottom;
}
