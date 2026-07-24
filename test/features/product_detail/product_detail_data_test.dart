import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/product_detail/product_detail_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the required product detail fields from response states', () {
    final detail = ProductDetailData.fromJson(
      Json({
        'tucking': 200,
        'shoepac': {
          'injective': 60000,
          'underfeeding': '2',
          'preslaughter': 'Dali Cash',
          'saggards': '1542026072118595573841296',
          'filers': 1,
          'resmooth': '120',
          'mispatch': 1,
          'friendlinesses':
              'http://8.220.184.117/#/SlinkierDesulfured?thunderstruck=2',
        },
        'spirochaete': {
          'entrecote': 'LancerPredacities',
          'millipede': '',
          'sociologeses': 0,
          'enterostomy': 'Identifying information',
        },
        'poolsides': {
          'distention': 'Identity upload copy',
          'hoddens': 'Identity confirmation copy',
          'variety': 'Face verification copy',
          'sizars': 'Personal information copy',
          'ultracasual': 'Work information copy',
          'blueberries': 'Emergency contact copy',
          'disorganization': 'Bind card top copy',
          'brabble': 'Bind card bottom copy',
        },
      }),
    );

    expect(detail.statusCode, 200);
    expect(detail.product.amount, '60000');
    expect(detail.product.productId, '2');
    expect(detail.product.productName, 'Dali Cash');
    expect(detail.product.orderNo, '1542026072118595573841296');
    expect(detail.product.orderId, 1);
    expect(detail.product.term, '120');
    expect(detail.product.termType, 1);
    expect(
      detail.product.customerServiceUrl,
      'http://8.220.184.117/#/SlinkierDesulfured?thunderstruck=2',
    );
    expect(detail.nextStep.type, 'LancerPredacities');
    expect(detail.nextStep.title, 'Identifying information');
    expect(detail.pageCopy.identityUpload, 'Identity upload copy');
    expect(detail.pageCopy.identityConfirmation, 'Identity confirmation copy');
    expect(detail.pageCopy.faceVerification, 'Face verification copy');
    expect(detail.pageCopy.personalInformation, 'Personal information copy');
    expect(detail.pageCopy.workInformation, 'Work information copy');
    expect(detail.pageCopy.emergencyContact, 'Emergency contact copy');
    expect(detail.pageCopy.bindCardTop, 'Bind card top copy');
    expect(detail.pageCopy.bindCardBottom, 'Bind card bottom copy');
  });

  test('uses safe values for missing data and tolerant scalar types', () {
    final empty = ProductDetailData.fromJson(Json(null));
    final converted = ProductDetailData.fromJson(
      Json({
        'tucking': '200',
        'shoepac': {'underfeeding': 2, 'saggards': 1542, 'resmooth': 120},
        'spirochaete': {'entrecote': 7, 'enterostomy': true},
      }),
    );

    expect(empty.statusCode, 0);
    expect(empty.product.productId, '');
    expect(empty.nextStep.type, '');
    expect(empty.pageCopy.identityUpload, '');
    expect(converted.statusCode, 200);
    expect(converted.product.productId, '2');
    expect(converted.product.orderNo, '1542');
    expect(converted.product.term, '120');
    expect(converted.nextStep.type, '7');
    expect(converted.nextStep.title, 'true');
  });
}
