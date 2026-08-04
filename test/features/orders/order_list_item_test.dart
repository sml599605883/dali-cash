import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/orders/order_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the documented Dali order-list item', () {
    final item = OrderListItem.fromJson(
      Json({
        'filers': 4,
        'saggards': 'ORDER-4',
        'thunderstruck': 31,
        'preslaughter': 'PG Finance',
        'creasing': 'https://cdn.test/logo.png',
        'fornices': 174,
        'proboscis': 'Outstanding',
        'injective': 'PHP 20,000.00',
        'planetological': 'Available up to',
        'weldor': 'Repay Now',
        'nauseant': '/repayment-detail?orderNo=ORDER-4',
        'prebiological': 'Due Date',
        'en': '29-11-2023',
        'reshippers': 0,
        'methodical': '/order/detail?orderId=4',
      }),
    );

    expect(item.orderId, '4');
    expect(item.orderNo, 'ORDER-4');
    expect(item.productId, '31');
    expect(item.productName, 'PG Finance');
    expect(item.productLogo, 'https://cdn.test/logo.png');
    expect(item.statusCode, 174);
    expect(item.statusText, 'Outstanding');
    expect(item.amountText, 'PHP 20,000.00');
    expect(item.amountLabel, 'Available up to');
    expect(item.actionText, 'Repay Now');
    expect(item.actionTarget, '/repayment-detail?orderNo=ORDER-4');
    expect(item.dateLabel, 'Due Date');
    expect(item.dateValue, '29-11-2023');
    expect(item.overdueDays, 0);
    expect(item.showAction, isTrue);
    expect(item.usesBlueAction, isTrue);
    expect(item.usesRedAction, isFalse);
  });

  test('shows actions only for status 174 and 180', () {
    OrderListItem item(int status) {
      return OrderListItem.fromJson(Json({'fornices': status}));
    }

    expect(item(174).showAction, isTrue);
    expect(item(174).usesBlueAction, isTrue);
    expect(item(180).showAction, isTrue);
    expect(item(180).usesRedAction, isTrue);
    expect(item(173).showAction, isFalse);
    expect(item(181).showAction, isFalse);
  });

  test('parses only map rows from clingiest', () {
    final items = parseOrderListItems(
      Json({
        'clingiest': [
          {'filers': 1, 'preslaughter': 'Valid'},
          null,
          'invalid',
        ],
      }),
    );

    expect(items, hasLength(1));
    expect(items.single.productName, 'Valid');
  });

  test('maps shortcut status codes and defaults unknown values to all', () {
    expect(MineOrderStatus.all.code, '4');
    expect(MineOrderStatus.unpaid.code, '7');
    expect(MineOrderStatus.late.code, '6');
    expect(MineOrderStatus.paid.code, '5');
    expect(MineOrderStatus.fromCode(' 7 '), MineOrderStatus.unpaid);
    expect(MineOrderStatus.fromCode('unknown'), MineOrderStatus.all);
  });
}
